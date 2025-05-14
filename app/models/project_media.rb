class ProjectMedia < ApplicationRecord
  attr_accessor :quote, :quote_attributions, :file, :media_type, :set_annotation, :set_tasks_responses, :previous_project_id, :cached_permissions, :is_being_created, :related_to_id, :skip_rules, :set_claim_description, :set_claim_context, :set_fact_check, :set_tags, :set_title, :set_status, :set_original_claim

  belongs_to :media
  has_one :claim_description

  accepts_nested_attributes_for :media, :claim_description

  has_paper_trail on: [:create, :update, :destroy], only: [:source_id, :archived], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

  include ProjectAssociation
  include ProjectMediaAssociations
  include ProjectMediaCreators
  include ProjectMediaEmbed
  include ValidationsHelper
  include ProjectMediaPrivate
  include ProjectMediaCachedFields
  include ProjectMediaBulk
  include ProjectMediaSourceAssociations
  include ProjectMediaGetters

  validates_presence_of :media, :team

  validates :media_id, uniqueness: { scope: :team_id }, unless: proc { |pm| pm.is_being_copied  }, on: :create
  validate :source_belong_to_team, unless: proc { |pm| pm.source_id.blank? || pm.is_being_copied }
  validate :custom_channel_format, :archived_in_allowed_values
  validate :channel_in_allowed_values, on: :create
  validate :channel_not_changed, on: :update
  validate :rate_limit_not_exceeded, on: :create
  validates_inclusion_of :title_field, in: ['custom_title', 'pinned_media_id', 'claim_title', 'fact_check_title'], allow_nil: true, allow_blank: true
  validates_presence_of :custom_title, if: proc { |pm| pm.title_field == 'custom_title' }

  before_validation :set_team_id, :set_channel, on: :create
  after_create :create_annotation, :create_metrics_annotation, :send_slack_notification, :create_relationship, :create_team_tasks, :create_claim_description_and_fact_check, :create_tags_in_background
  after_create :add_source_creation_log, unless: proc { |pm| pm.source_id.blank? }
  after_commit :apply_rules_and_actions_on_create, :set_quote_metadata, :notify_team_bots_create, on: [:create]
  after_commit :create_relationship, on: [:update]
  after_update :archive_or_restore_related_medias_if_needed, :notify_team_bots_update, :move_similar_item, :send_move_to_slack_notification
  after_update :apply_rules_and_actions_on_update, if: proc { |pm| pm.saved_changes.keys.include?('read') }
  after_update :apply_delete_for_ever, if: proc { |pm| pm.saved_change_to_archived? && pm.archived == CheckArchivedFlags::FlagCodes::TRASHED }
  after_destroy :destroy_related_medias

  notifies_pusher on: [:save, :destroy],
                  event: 'media_updated',
                  targets: proc { |pm| [pm.media, pm.team, pm.project] },
                  if: proc { |pm| !pm.skip_notifications },
                  data: proc { |pm| pm.media.as_json.merge(class_name: pm.report_type).to_json }

  def related_to_team?(team)
    self.team == team
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def slack_params
    statuses = Workflow::Workflow.options(self, self.default_project_media_status_type)[:statuses]
    current_status = statuses.select { |st| st['id'] == self.last_status }
    user = User.current || self.user
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      role: I18n.t('role_' + user.role(self.team).to_s),
      team: Bot::Slack.to_slack(self.team.name),
      type: I18n.t("activerecord.models.#{self.media.class.name.underscore}"),
      title: Bot::Slack.to_slack(self.title),
      related_to: self.related_to ? Bot::Slack.to_slack_url(self.related_to.full_url, self.related_to.title) : nil,
      description: Bot::Slack.to_slack(self.description, false),
      url: self.full_url,
      status: Bot::Slack.to_slack(current_status[0]['label']),
      button: I18n.t("slack.fields.view_button", **{
        type: I18n.t("activerecord.models.#{self.class_name.underscore}"), app: CheckConfig.get('app_name')
      })
    }
  end

  def should_send_slack_notification_message_for_card?
    # Should always render a card if there is no slack_message annotation
    return true if Annotation.where(annotation_type: 'slack_message', annotated_type: 'ProjectMedia', annotated_id: self.id).last.nil?
    Time.now.to_i - Rails.cache.read("slack_card_rendered_for_project_media:#{self.id}").to_i > 48.hours.to_i
  end

  def slack_notification_message_for_card(text)
    Rails.cache.write("slack_card_rendered_for_project_media:#{self.id}", Time.now.to_i)
    return "<#{self.full_url}|#{text}>"
  end

  def slack_notification_message(event = nil)
    params = self.slack_params
    event ||= 'create'
    related = params[:related_to].blank? ? '' : '_related'
    pretext = I18n.t("slack.messages.project_media_#{event}#{related}", **params)
    # Either render a card or update an existing one
    self.should_send_slack_notification_message_for_card? ? self.slack_notification_message_for_card(pretext) : nil
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def analysis
    begin
      data = {}.with_indifferent_access
      self.get_annotations('verification_status').last.get_fields.each do |f|
        data[f.field_name] = f.value
      end
      data
    rescue
      {}
    end
  end

  def analysis=(info)
    unless info.blank?
      m = self.get_annotations('verification_status').last
      m = m.load unless m.nil?
      return if m.nil?
      m.client_mutation_id = self.client_mutation_id
      m.skip_check_ability = true
      m.set_fields = info.to_json
      m.save!
    end
  end

  def refresh_media=(_refresh)
    if self.media.type == 'Link'
      Bot::Keep.archiver_annotation_types.each do |type|
        a = self.annotations.where(annotation_type: 'archiver').last
        a.nil? ? self.create_archive_annotation(type) : self.reset_archive_response(a, type)
      end
      team = self.team
      pender_key = team.get_pender_key if team
      self.media.pender_key = pender_key
      self.media.refresh_pender_data
      self.updated_at = Time.now
      # update account if we have a new author_url
      update_media_account
    end
  end

  def get_dynamic_annotation(type)
    Dynamic.where(annotation_type: type, annotated_type: 'ProjectMedia', annotated_id: self.id).last
  end

  def custom_permissions(ability = nil)
    perms = {}
    perms["embed ProjectMedia"] = self.archived == CheckArchivedFlags::FlagCodes::NONE
    ability ||= Ability.new
    temp = Source.new(team_id: self.team_id)
    perms["not_spam ProjectMedia"] = ability.can?(:not_spam, self)
    perms["restore ProjectMedia"] = ability.can?(:restore, self)
    perms["confirm ProjectMedia"] = ability.can?(:confirm, self)
    perms["lock Annotation"] = ability.can?(:lock_annotation, self)
    perms["administer Content"] = ability.can?(:administer_content, self)
    perms["create Source"] = ability.can?(:create, temp)
    perms["update Source"] = ability.can?(:create, temp)
    perms
  end

  def related_to
    ProjectMedia.where(id: self.related_to_id).last unless self.related_to_id.nil?
  end

  def related_items_ids
    parent = Relationship.confirmed.where(target_id: self.id).last&.source || self
    ids = [parent.id]
    ids.concat(Relationship.confirmed.where(source_id: parent.id).select(:target_id).map(&:target_id))
    ids.uniq.sort
  end

  def encode_with(coder)
    extra = { 'related_to_id' => self.related_to_id }
    coder['extra'] = extra
    coder['raw_attributes'] = attributes_before_type_cast
    coder['attributes'] = @attributes
    coder['new_record'] = new_record?
    coder['active_record_yaml_version'] = 0
  end

  def relationship_source(relationship_type = Relationship.default_type)
    Relationship.where(target_id: self.id).where('relationship_type = ?', relationship_type.to_yaml).last&.source || self
  end

  def self.get_similar_items(project_media, relationship_type)
    related_items = ProjectMedia.joins('INNER JOIN relationships ON relationships.target_id = project_medias.id').where('relationships.source_id' => project_media.relationship_source(relationship_type).id).order('relationships.weight DESC')
    related_items.where('relationships.relationship_type = ?', relationship_type.to_yaml)
  end

  def self.get_similar_relationships(project_media, relationship_type)
    Relationship.where(source_id: project_media.relationship_source(relationship_type).id).where('relationship_type = ?', relationship_type.to_yaml).order('created_at DESC')
  end

  def get_default_relationships
    self.relationships.where('relationship_type = ?', Relationship.default_type.to_yaml)
  end

  def relationships
    Relationship.where('source_id = ? OR target_id = ?', self.id, self.id)
  end

  def is_parent
    Relationship.where('source_id = ?', self.id).exists?
  end

  def self.archive_or_restore_related_medias(archived, project_media_id, team)
    items = Relationship.where(source_id: project_media_id)
    if archived == CheckArchivedFlags::FlagCodes::TRASHED || archived == CheckArchivedFlags::FlagCodes::SPAM
      # Trash action should archive confirmed items only
      items = items.where('relationship_type IN (?)', [Relationship.default_type.to_yaml, Relationship.confirmed_type.to_yaml])
      # Move similar items to default folder
      Relationship.where(source_id: project_media_id, relationship_type: Relationship.suggested_type).destroy_all
    end
    ids = items.map(&:target_id)
    # should bulk archive
    ProjectMedia.bulk_update(ids, { action: 'archived', params: { archived: archived }.to_json }, team)
    # should enqueue spam children for delete forever
    if archived == CheckArchivedFlags::FlagCodes::SPAM && !RequestStore.store[:skip_delete_for_ever]
      interval = CheckConfig.get('empty_trash_interval', 30).to_i
      options = { type: 'spam', updated_at: Time.now.to_i, extra: { parent_id: project_media_id }}
      ids.each{ |pm_id| ProjectMediaTrashWorker.perform_in(interval.days, pm_id, YAML.dump(options)) }
    end
  end

  def self.destroy_related_medias(project_media, user_id = nil)
    project_media = YAML::load(project_media)
    project_media_id = project_media.id
    relationships = Relationship.where(source_id: project_media_id)
    targets = relationships.map(&:target)
    relationships.destroy_all
    targets.reject(&:nil?).map(&:destroy)
    user = User.where(id: user_id).last
    previous_user = User.current
    Relationship.where(target_id: project_media_id).each do |r|
      User.current = user
      r.skip_check_ability = true
      r.target = project_media
      r.destroy
      User.current = nil
      v = r.versions.from_partition(project_media.team_id).where(event_type: 'destroy_relationship').last
      unless v.nil?
        v.meta = r.version_metadata
        v.save!
      end
    end
    User.current = previous_user
  end

  def replace_by(new_pm, skip_send_report = false)
    return if new_pm.nil? || self.id == new_pm.id
    if self.team_id != new_pm.team_id
      raise I18n.t(:replace_by_media_in_the_same_team)
    elsif self.media.media_type != 'blank'
      raise I18n.t(:replace_blank_media_only)
    else
      assignments_ids = []
      ProjectMedia.transaction do
        # Save the new item
        RequestStore.store[:skip_check_ability] = true
        new_pm.updated_at = Time.now
        new_pm.skip_check_ability = true
        new_pm.channel = { main: CheckChannels::ChannelCodes::FETCH }
        # Point the claim and consequently the fact-check
        cd = self.claim_description
        if cd
          cd.disable_replace_media = true
          new_pm.claim_description = cd
        end
        new_pm.save(validate: false) # To skip channel validation
        RequestStore.store[:skip_check_ability] = false

        # Get assignment for new items
        assignments_ids = begin new_pm.last_status_obj.assignments.map(&:id) rescue [] end
        # Remove any status and report from the new item
        Annotation.where(annotation_type: ['verification_status', 'report_design'], annotated_type: 'ProjectMedia', annotated_id: new_pm.id).delete_all
        # All annotations from the old item should point to the new item
        Annotation.where(annotated_type: 'ProjectMedia', annotated_id: self.id).where.not(annotation_type: ['tag', 'task']).update_all(annotated_id: new_pm.id)

        # All versions from the old item should point to the new item
        Version.from_partition(self.team_id).where(associated_type: 'ProjectMedia', associated_id: self.id).update_all(associated_id: new_pm.id)
        Version.from_partition(self.team_id).where(item_type: 'ProjectMedia', item_id: self.id).update_all(item_id: new_pm.id)

        # All relationships from the old item should point to the new item
        Relationship.where(source_id: self.id).update_all(source_id: new_pm.id)
      end

      # Clear cached fields
      new_pm.clear_cached_fields

      # Update creator_name cached field
      Rails.cache.write("check_cached_field:ProjectMedia:#{new_pm.id}:creator_name", 'Import')

      # Apply other stuff in background
      options = {
        author_id: User.current&.id,
        assignments_ids: assignments_ids,
        skip_send_report: skip_send_report
      }
      self.class.delay_for(1.second).apply_replace_by(self.id, new_pm.id, options.to_json)
    end
  end

  def self.apply_replace_by(old_pm_id, new_pm_id, options_json)
    old_pm = ProjectMedia.find_by_id(old_pm_id)
    new_pm = ProjectMedia.find_by_id(new_pm_id)
    options = begin JSON.parse(options_json) rescue {} end
    unless new_pm.nil?
      # Merge assignment
      new_pm.replace_merge_assignments(options['assignments_ids'])
      # Merge tags
      new_item_tags = new_pm.annotations('tag').map(&:tag)
      unless new_item_tags.blank? || old_pm.nil?
        deleted_tags = []
        old_pm.annotations('tag').find_each do |tag|
          deleted_tags << tag.id if new_item_tags.include?(tag.tag)
        end
        Annotation.where(id: deleted_tags).delete_all
      end
      Annotation.where(annotation_type: 'tag', annotated_type: 'ProjectMedia', annotated_id: old_pm_id).update_all(annotated_id: new_pm.id)
      # Log a version for replace_by action
      replace_v = Version.new({
        item_type: 'ProjectMedia',
        item_id: new_pm.id.to_s,
        event: 'replace',
        whodunnit: options['author_id'].to_s,
        object_changes: { pm_id: [old_pm_id, new_pm.id] }.to_json,
        associated_id: new_pm.id,
        associated_type: 'ProjectMedia',
        team_id: new_pm.team_id,
      })
      replace_v.save!
      # Re-index new items in ElasticSearch
      new_pm.create_elasticsearch_doc_bg({ force_creation: true })
    end
    # Destroy old item
    old_pm.destroy! unless old_pm.nil?
    # Send a published report if any
    ::Bot::Smooch.send_report_from_parent_to_child(new_pm.id, new_pm.id) unless options['skip_send_report']
  end

  def replace_merge_assignments(assignments_ids)
    unless assignments_ids.blank?
      status = self.last_status_obj
      unless status.nil?
        assignments_uids = status.assignments.map(&:user_id)
        Assignment.where(id: assignments_ids).find_each do |as|
          if assignments_uids.include?(as.user_id)
            as.skip_check_ability = true
            as.delete
          else
            as.update_columns(assigned_id: status.id)
            as.send(:increase_assignments_count)
          end
        end
      end
    end
  end

  def method_missing(method, *args, &block)
    match = /^task_value_([0-9]+)$/.match(method)
    if match.nil?
      super
    else
      self.task_value(match[1].to_i)
    end
  end

  def feed_columns_values
    values = {}
    columns = [
      'fact_check_title',
      'fact_check_summary',
      'fact_check_url',
      'tags_as_sentence',
      'team_name',
      'updated_at_timestamp',
      'status',
      'team_avatar'
    ]
    columns.each do |column|
      values[column] = self.send(column)
    end
    values
  end

  # FIXME: Required by GraphQL API
  def claim_descriptions
    self.claim_description ? [self.claim_description] : []
  end

  def get_project_media_sources
    ids = ProjectMedia.get_similar_items(self, Relationship.confirmed_type).map(&:id)
    ids << self.id
    sources = {}
    Source.joins('INNER JOIN project_medias pm ON pm.source_id = sources.id').where('pm.id IN (?)', ids).find_each do |s|
      sources[s.id] = s.name
    end
    # make the main source as the begging of the list
    unless self.source_id.blank?
      main_s = sources.slice(self.source_id)
      sources.delete(self.source_id)
      sources = main_s.merge(sources)
    end
    sources.to_json
  end

  def version_metadata(changes)
    changes = begin JSON.parse(changes) rescue {} end
    meta = changes.keys.include?('source_id') ? { source_name: self.source&.name } : {}
    meta.to_json
  end

  def get_requests(include_children = false)
    # Get related items for parent item
    pm_ids = (Relationship.confirmed_parent(self).id == self.id && include_children) ? self.related_items_ids : [self.id]
    TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: pm_ids).order('created_at ASC')
  end

  def apply_rules_and_actions_on_update
    rule_ids = self.team.get_rules_that_match_condition { |condition, _value| condition == 'item_is_read' && self.read }
    self.team.apply_rules_and_actions(self, rule_ids)
  end

  def self.handle_fact_check_for_existing_claim(existing_pm, new_pm)
    if existing_pm.fact_check.blank?
      existing_pm.append_fact_check_from(new_pm)
      return existing_pm
    elsif existing_pm.fact_check.present?
      if existing_pm.fact_check.language != new_pm.set_fact_check['language']
        new_pm.replace_with_blank_media
        return new_pm
      end
    end
    new_pm.save!
  end

  def append_fact_check_from(new_pm)
    self.set_claim_description = new_pm.set_claim_description
    self.set_fact_check = new_pm.set_fact_check
    self.create_claim_description_and_fact_check
  end

  def replace_with_blank_media
    m = Blank.create!
    self.set_original_claim = nil
    self.media_id = m.id
    self.save!
  end

  def get_similar_articles
    # Get search query based on Media type
    # Quote for Claim
    # Transcription for UploadedVideo , UploadedAudio and UploadedImage
    # Title and/or description for Link
    results = []
    items = Rails.cache.fetch("relevant-items-#{self.id}", expires_in: 2.hours) do
      media = self.media
      search_query = case media.type
                     when 'Claim'
                       media.quote
                     when 'UploadedVideo', 'UploadedAudio'
                       self.transcription
                     when 'UploadedImage'
                       self.extracted_text
                     end
      search_query ||= self.title
      results = self.team.search_for_similar_articles(search_query, self)
      fact_check_ids = results.select{|article| article.is_a?(FactCheck)}.map(&:id)
      fc_pm = {}
      unless fact_check_ids.blank?
        # Get ProjectMedia for FactCheck for RelevantResultsItem logs and should use sort_by to keep existing order
        FactCheck.select('fact_checks.id AS fc_id, claim_descriptions.project_media_id AS pm_id')
        .where(id: fact_check_ids).joins(:claim_description).each do |raw|
          fc_pm[raw.fc_id] = raw.pm_id
        end
      end
      explainer_ids = results.select{|article| article.is_a?(Explainer)}.map(&:id)
      ex_pm = {}
      unless explainer_ids.blank?
        # Intiate the ex_pm with nil values as some Explainer not assinged to existing items
        default_pm = nil
        ex_pm = explainer_ids.each_with_object(default_pm).to_h
        # Get ProjectMedia for Explainer for RelevantResultsItem logs and should use sort_by to keep existing order
        ExplainerItem.where(explainer_id: explainer_ids).find_each do |raw|
          ex_pm[raw.explainer_id] = raw.project_media_id
        end
      end
      {
        fact_check: fc_pm.sort_by { |k, _v| fact_check_ids.index(k) }.to_h,
        explainer: ex_pm.sort_by { |k, _v| explainer_ids.index(k) }.to_h
      }.to_json
    end
    if results.blank?
      # This indicates a cache hit, so we should retrieve the items according to the cached values while maintaining the same sort order.
      items = JSON.parse(items)
      items.each do |klass, data|
        ids = data.keys
        results += klass.camelize.constantize.where(id: ids).sort_by { |result| ids.index(result.id) }
      end
    end
    results
  end

  def log_relevant_results(klass, id, author_id, actor_session_id)
    actor_session_id = Digest::MD5.hexdigest("#{actor_session_id}-#{Time.now.to_i}")
    article = klass.constantize.find_by_id id
    return if article.nil?
    data = begin JSON.parse(Rails.cache.read("relevant-items-#{self.id}")) rescue {} end
    type = klass.underscore
    unless data[type].blank?
      user_action = data[type].keys.map(&:to_i).include?(article.id) ? 'relevant_articles' : 'article_search'
      tbi = Bot::Alegre.get_alegre_tbi(self.team_id)
      similarity_settings = tbi&.settings&.to_h || {}
      # Retrieve the user's selection, which can be either FactCheck or Explainer,
      # as this type encompasses the user's choice, and then define the shared field based on this type.
      # i.e selected_count either 0/1
      items = data[type]
      items.keys.each_with_index do |value, index|
        selected_count = (value.to_i == article.id).to_i
        fields = {
          article_id: value,
          article_type: article.class.name,
          matched_media_id: items[value],
          selected_count: selected_count,
          display_rank: index + 1,
        }
        self.create_relevant_results_item(user_action, similarity_settings, author_id, actor_session_id, fields)
      end
      # Retrieve the alternative type (the non-selected type) since all items in this category are marked as non-selected items
      # i.e selected_count = 0
      other_type = (['fact_check', 'explainer'] - [type]).first
      items = data[other_type]
      items.keys.each_with_index do |value, index|
        fields = {
          article_id: value,
          article_type: other_type.camelize,
          matched_media_id: items[value],
          selected_count: 0,
          display_rank: index + 1,
        }
        self.create_relevant_results_item(user_action, similarity_settings, author_id, actor_session_id, fields)
      end
    end
    Rails.cache.delete("relevant-items-#{self.id}")
  end

  def has_tipline_requests_that_never_received_articles
    ids = ProjectMedia.where(id: self.related_items_ids).pluck(:id) # Including child items
    # As we check against the range with 1, 7 and 30 days so I check the exists with the max range (30 days)
    TiplineRequest.no_articles_sent(ids).where(created_at: Time.now.ago(30.days)..Time.now).exists?
  end

  def number_of_tipline_requests_that_never_received_articles_by_time
    data = {}
    ids = ProjectMedia.where(id: self.related_items_ids).pluck(:id) # Including child items
    [1, 7, 30].each do |number_of_days|
      data[number_of_days] = TiplineRequest.no_articles_sent(ids).where(created_at: Time.now.ago(number_of_days.days)..Time.now).count
    end
    data
  end

  protected

  def create_relevant_results_item(user_action, similarity_settings, author_id, actor_session_id, fields)
    rr = RelevantResultsItem.new
    rr.team_id = self.team_id
    rr.user_id = author_id
    rr.relevant_results_render_id = actor_session_id
    rr.query_media_parent_id = self.id
    rr.query_media_ids = [self.id]
    rr.user_action = user_action
    rr.similarity_settings = similarity_settings
    rr.skip_check_ability = true
    fields.each do |k, v|
      rr.send("#{k}=", v) if rr.respond_to?("#{k}=")
    end
    rr.save!
  end

  def add_extra_elasticsearch_data(ms)
    analysis = self.analysis
    analysis_title = analysis['title'].blank? ? nil : analysis['title']
    file_title = analysis['file_title'].blank? ? nil : analysis['file_title']
    m = self.media
    associated_type = m.type
    if m.type == 'Link'
      provider = m.metadata['provider']
      associated_type = ['instagram', 'twitter', 'youtube', 'facebook', 'tiktok', 'telegram'].include?(provider) ? provider : 'weblink'
    end
    ms.attributes[:associated_type] = associated_type
    ms.attributes[:url] = m.url
    ms.attributes[:title] = self.original_title
    # initiate title_index with same title value for sorting by title purpose
    ms.attributes[:title_index] = self.title
    ms.attributes[:description] = self.original_description
    ms.attributes[:analysis_title] = analysis_title || file_title
    ms.attributes[:analysis_description] = self.analysis_description
    ms.attributes[:verification_status] = self.last_status
    ms.attributes[:channel] = self.channel.values.flatten.map(&:to_i)
    ms.attributes[:language] = self.get_dynamic_annotation('language')&.get_field_value('language')
    # set fields with integer value including cached fields
    fields_i = [
      'archived', 'sources_count', 'linked_items_count', 'share_count','last_seen', 'demand', 'user_id',
      'read', 'suggestions_count','related_count', 'reaction_count', 'media_published_at',
      'unmatched', 'fact_check_published_on'
    ]
    fields_i.each{ |f| ms.attributes[f] = self.send(f).to_i }
    # add more cached fields
    ms.attributes[:creator_name] = self.creator_name
    ms.attributes[:tags_as_sentence] = self.tags_as_sentence.split(', ').size
    ms.attributes[:report_status] = ['unpublished', 'paused', 'published'].index(self.report_status)
    ms.attributes[:published_by] = self.published_by.keys.first || 0
    ms.attributes[:type_of_media] = Media.types.index(self.type_of_media)
    ms.attributes[:status_index] = self.status_ids.index(self.status)
    ms.attributes[:fact_check_title] = self.fact_check_title
    ms.attributes[:fact_check_summary] = self.fact_check_summary
    ms.attributes[:fact_check_url] = self.fact_check_url
    ms.attributes[:claim_description_content] = self.claim_description&.description
    ms.attributes[:claim_description_context] = self.claim_description&.context
    ms.attributes[:source_name] = self.source&.name
  end

  def add_nested_objects(ms)
    # tags
    tags = self.get_annotations('tag').map(&:load)
    ms.attributes[:tags] = tags.collect{|t| {id: t.id, tag: t.tag_text}}
    # 'task_responses'
    tasks = self.annotations('task')
    tasks_ids = tasks.map(&:id)
    team_task_ids = TeamTask.where(team_id: self.team_id).map(&:id)
    responses = Task.where('annotations.id' => tasks_ids)
    .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', team_task_ids)
    .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
      AND responses.annotated_type = 'Task'
      AND responses.annotated_id = annotations.id"
      )
    ms.attributes[:task_responses] = responses.collect{ |tr| {
        id: tr.id,
        fieldset: tr.fieldset,
        field_type: tr.type,
        team_task_id: tr.team_task_id,
        value: tr.first_response
      }
    }
    # add TeamTask of type choice with no answer
    no_response_ids = tasks_ids - responses.map(&:id)
    Task.where(id: no_response_ids)
    .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', team_task_ids).find_each do |item|
      if item.type =~ /choice/
        ms.attributes[:task_responses] << { id: item.id, team_task_id: item.team_task_id, fieldset: item.fieldset }
      end
    end
    # 'assigned_user_ids'
    assignments_uids = Assignment.where(assigned_type: ['Annotation', 'Dynamic'])
    .joins('INNER JOIN annotations a ON a.id = assignments.assigned_id')
    .where('a.annotated_type = ? AND a.annotated_id = ?', 'ProjectMedia', self.id).map(&:user_id)
    ms.attributes[:assigned_user_ids] = assignments_uids.uniq
    # 'requests'
    requests = []
    TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: self.id).each do |tr|
      identifier = begin tr.smooch_user_external_identifier&.value rescue tr.smooch_user_external_identifier end
      requests << {
        id: tr.id,
        username: tr.smooch_data['name'],
        identifier: identifier&.gsub(/[[:space:]|-]/, ''),
        content: tr.smooch_data['text'],
        language: tr.language,
      }
    end
    ms.attributes[:requests] = requests
  end

  # private
  #
  # Please add private methods to app/models/concerns/project_media_private.rb
end
