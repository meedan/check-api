class ProjectMedia < ApplicationRecord
  attr_accessor :quote, :quote_attributions, :file, :media_type, :set_annotation, :set_tasks_responses, :previous_project_id, :cached_permissions, :is_being_created, :related_to_id, :skip_rules

  include ProjectAssociation
  include ProjectMediaAssociations
  include ProjectMediaCreators
  include ProjectMediaEmbed
  include Versioned
  include ValidationsHelper
  include ProjectMediaPrivate
  include ProjectMediaCachedFields
  include ProjectMediaBulk
  include ProjectMediaSourceAssociations
  include ProjectMediaGetters

  validates_presence_of :media, :team

  validates :media_id, uniqueness: { scope: :team_id }, unless: proc { |pm| pm.is_being_copied  }, on: :create
  validate :source_belong_to_team, unless: proc { |pm| pm.source_id.blank? || pm.is_being_copied }
  validate :project_is_not_archived, unless: proc { |pm| pm.is_being_copied  }
  validates :channel, included: { values: CheckChannels::ChannelCodes::ALL }, on: :create
  validates :channel, inclusion: { in: ->(pm) { [pm.channel_was] }, message: :channel_update }, on: :update

  before_validation :set_team_id, :set_channel, on: :create
  after_create :create_annotation, :create_metrics_annotation, :send_slack_notification, :create_relationship, :create_team_tasks
  after_commit :apply_rules_and_actions_on_create, :set_quote_metadata, :notify_team_bots_create, on: [:create]
  after_commit :create_relationship, on: [:update]
  after_update :archive_or_restore_related_medias_if_needed, :notify_team_bots_update, :add_remove_team_tasks, :move_similar_item, :send_move_to_slack_notification
  after_update :apply_rules_and_actions_on_update, if: proc { |pm| pm.saved_changes.keys.include?('read') }
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

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def project_group
    self.project&.project_group
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
      project: Bot::Slack.to_slack(self.project&.title),
      button: I18n.t("slack.fields.view_button", {
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
    pretext = I18n.t("slack.messages.project_media_#{event}#{related}", params)
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
    update_media_account if self.media.type == 'Link'
  end

  def get_dynamic_annotation(type)
    Dynamic.where(annotation_type: type, annotated_type: 'ProjectMedia', annotated_id: self.id).last
  end

  def custom_permissions(ability = nil)
    perms = {}
    perms["embed ProjectMedia"] = self.archived == CheckArchivedFlags::FlagCodes::NONE
    ability ||= Ability.new
    temp = Source.new(team_id: self.team_id)
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
    Relationship.where(source_id: project_media.relationship_source(relationship_type).id).where('relationship_type = ?', relationship_type.to_yaml).order('weight DESC')
  end

  def get_default_relationships
    self.relationships.where('relationship_type = ?', Relationship.default_type.to_yaml)
  end

  def relationships
    Relationship.where('source_id = ? OR target_id = ?', self.id, self.id)
  end

  def self.archive_or_restore_related_medias(archived, project_media_id)
    ids = Relationship.where(source_id: project_media_id).map(&:target_id)
    ProjectMedia.where(id: ids).update_all(archived: archived)
  end

  def self.destroy_related_medias(project_media, user_id = nil)
    project_media = YAML::load(project_media)
    project_media_id = project_media.id
    relationships = Relationship.where(source_id: project_media_id)
    targets = relationships.map(&:target)
    relationships.destroy_all
    targets.map(&:destroy)
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

  def add_destination_team_tasks(project_id)
    tasks = self.team.auto_tasks(project_id)
    existing_tasks = Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: self.id)
      .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tasks.map(&:id)) unless tasks.blank?
    unless existing_tasks.blank?
      tt_ids = existing_tasks.collect{|i| i.data['team_task_id']}
      tasks.delete_if {|t| tt_ids.include?(t.id)}
    end
    self.create_auto_tasks(project_id, tasks) unless tasks.blank?
  end

  def replace_by(new_project_media)
    if self.team_id != new_project_media.team_id
      raise I18n.t(:replace_by_media_in_the_same_team)
    elsif self.media.media_type != 'blank'
      raise I18n.t(:replace_blank_media_only)
    else
      id = new_project_media.id
      ProjectMedia.transaction do
        current_user = User.current
        current_team = Team.current
        User.current = Team.current = nil
        # Remove any status and report from the new item
        Annotation.where(
          annotation_type: ['verification_status', 'report_design'],
          annotated_type: 'ProjectMedia', annotated_id: new_project_media.id
        ).find_each do |a|
          a.skip_check_ability = true
          a.destroy!
        end
        # All annotations from the old item should point to the new item
        Annotation.where(annotated_type: 'ProjectMedia', annotated_id: self.id).update_all(annotated_id: id)
        # Destroy the old item
        self.skip_check_ability = true
        self.destroy!
        # Save the new item
        new_project_media.updated_at = Time.now
        new_project_media.skip_check_ability = true
        new_project_media.save!
        User.current = current_user
        Team.current = current_team
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

  def list_columns_values
    values = {}
    columns = self.team.list_columns || Team.default_list_columns
    columns.each do |column|
      c = column.with_indifferent_access
      if c[:show]
        key = c[:key]
        values[key] = self.send(key)
      end
    end
    values
  end

  def remove_related_team_tasks_bg(pid)
    # Get team tasks that assigned to target list (pid)
    tasks = TeamTask.where("project_ids like ?", "% #{pid}\n%")
    # Get team tasks that assigned to current list
    unless self.project_id.blank?
      current_tasks = TeamTask.where("project_ids like ?", "% #{self.project_id}\n%")
      tasks = tasks - current_tasks
    end
    # Get tasks with zero answer (should keep completed tasks)
    Task.where('annotations.annotation_type' => 'task', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => self.id)
    .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tasks.map(&:id))
    .joins("LEFT JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
      AND responses.annotated_type = 'Task'
      AND responses.annotated_id = annotations.id"
      )
    .where('responses.id' => nil).find_each do |t|
      t.skip_check_ability = true
      t.destroy
    end
  end

  def user_can_see_project?(user = User.current)
    project = self.project
    project.nil? || project.privacy <= Project.privacy_for_role(project.team, user)
  end

  protected

  def set_es_account_data
    data = {}
    a = self.media.account
    metadata = a.metadata
    ['title', 'description'].each{ |k| data[k] = metadata[k] unless metadata[k].blank? } unless metadata.nil?
    data['id'] = a.id unless data.blank?
    [data]
  end

  def add_extra_elasticsearch_data(ms)
    m = self.media
    ms.attributes[:associated_type] = m.type
    ms.attributes[:url] = m.url
    ms.attributes[:accounts] = self.set_es_account_data unless m.account.nil?
    ms.attributes[:title] = self.original_title
    # initiate sort_title with same title value for sorting by title purpose
    ms.attributes[:sort_title] = self.title&.downcase
    ms.attributes[:description] = self.original_description
    ms.attributes[:analysis_title] = self.analysis_title
    ms.attributes[:analysis_description] = self.analysis_description
    ms.attributes[:quote] = m.quote
    ms.attributes[:verification_status] = self.last_status
    # set fields with integer value
    fields_i = [
      'archived', 'channel', 'sources_count', 'linked_items_count', 'share_count',
      'last_seen', 'demand', 'user_id', 'read'
    ]
    fields_i.each{ |f| ms.attributes[f] = self.send(f).to_i }
  end

  # private
  #
  # Please add private methods to app/models/concerns/project_media_private.rb
end
