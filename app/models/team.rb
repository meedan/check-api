class Team < ApplicationRecord
  # These two callbacks must be in the top
  after_create :create_team_partition
  before_destroy :delete_created_bots, :remove_is_default_project_flag

  include ValidationsHelper
  include DestroyLater
  include TeamValidations
  include TeamAssociations
  include TeamPrivate
  include TeamDuplication
  include TeamRules
  include TeamSlackNotifications
  include CheckArchivedFlags

  attr_accessor :affected_ids, :is_being_copied, :is_being_created

  mount_uploader :logo, ImageUploader

  after_find do |team|
    if User.current
      Team.current ||= team
      Ability.new(User.current, team)
    end
  end
  before_validation :normalize_slug, on: :create
  before_validation :set_default_language, on: :create
  before_validation :set_default_fieldsets, on: :create
  after_create :add_user_to_team, :add_default_bots_to_team, :create_default_folder
  after_update :archive_or_restore_projects_if_needed
  after_update :update_reports_if_labels_changed
  after_update :update_reports_if_languages_changed
  before_destroy :anonymize_sources_and_accounts
  after_destroy :reset_current_team

  check_settings

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    custom = begin self.logo.file.public_url rescue nil end
    default = CheckConfig.get('checkdesk_base_url') + self.logo.url
    custom || default
  end

  def url
    CheckConfig.get('checkdesk_client') + '/' + self.slug
  end

  def members_count
    self.team_users.where(status: 'member').permissioned(self).count
  end

  def projects_count
    self.projects.allowed(self).permissioned.count
  end

  def as_json(_options = {})
    {
      dbid: self.id,
      id: self.team_graphql_id,
      avatar: self.avatar,
      name: self.name,
      projects: self.recent_projects.allowed(team),
      slug: self.slug
    }
  end

  def owners(role, statuses = TeamUser.status_types)
    self.users.where({ 'team_users.role': role, 'team_users.status': statuses })
  end

  def team_graphql_id
    Base64.encode64("Team/#{self.id}")
  end

  def destroy_partition_and_team!
    RequestStore.store[:skip_cached_field_update] = true
    # Destroy the whole partition first, in a separate transaction
    # Re-create an empty partition before destroying the rest, to avoid errors
    self.send :delete_team_partition
    self.send :create_team_partition
    ApplicationRecord.connection_pool.with_connection { self.destroy! }
    RequestStore.store[:skip_cached_field_update] = false
  end

  # FIXME Source should be using concern HasImage
  # which automatically adds a member attribute `file`
  # which is used by GraphqlCrudOperations
  def file=(file)
    self.logo = file if file.respond_to?(:content_type)
  end

  # FIXME should be using concern HasImage
  # which already include this method
  def should_generate_thumbnail?
    true
  end

  def recipients(requestor, role='admin')
    owners = self.owners(role, ['member'])
    recipients = []
    if !owners.empty? && !owners.include?(requestor)
      recipients = owners.map(&:email).reject{ |m| m.blank? }
    end
    recipients
  end

  def report=(report_settings)
    settings = report_settings.is_a?(String) ? JSON.parse(report_settings) : report_settings
    self.send(:set_report, settings)
  end

  def team_user
    self.team_users.where(user_id: User.current.id).last unless User.current.nil?
  end

  def auto_tasks(associated_type = 'ProjectMedia')
    self.team_tasks.where(associated_type: associated_type).order(order: :asc, id: :asc)
  end

  def add_auto_task=(task)
    TeamTask.create! task.merge({ team_id: self.id })
  end

  def remove_auto_task=(task_label)
    TeamTask.where({ team_id: self.id, label: task_label }).map(&:destroy!)
  end

  def set_team_tasks=(list)
    list.each do |task|
      self.add_auto_task = task
    end
  end

  def tipline_inbox_filters=(tipline_inbox_filters)
    self.send(:set_tipline_inbox_filters, JSON.parse(tipline_inbox_filters))
  end

  def suggested_matches_filters=(suggested_matches_filters)
    self.send(:set_suggested_matches_filters, JSON.parse(suggested_matches_filters))
  end

  def languages=(languages)
    languages = languages.is_a?(String) ? JSON.parse(languages) : languages
    self.send(:set_languages, languages.uniq)
  end

  def language=(language)
    self.send(:set_language, language)
  end

  def language_detection=(language_detection)
    self.send(:set_language_detection, language_detection)
  end

  def get_language_detection
    settings = self.settings.to_h.with_indifferent_access
    settings.has_key?(:language_detection) ? settings[:language_detection] : true
  end

  def outgoing_urls_utm_code=(code)
    self.set_outgoing_urls_utm_code = code
  end

  def shorten_outgoing_urls=(bool)
    self.set_shorten_outgoing_urls = bool
  end

  def clear_list_columns_cache
    languages = self.get_languages.to_a + I18n.available_locales.map(&:to_s)
    languages.uniq.each { |l| Rails.cache.delete("list_columns:team:#{l}:#{self.id}") }
  end

  def list_columns=(columns)
    self.clear_list_columns_cache
    columns = columns.is_a?(String) ? JSON.parse(columns) : columns
    self.send(:set_list_columns, columns)
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'team', 'slug' => self.slug } })
  end

  def default_folder
    self.projects.where(is_default: true).last
  end

  def self.archive_or_restore_projects_if_needed(archived, team_id)
    Project.where({ team_id: team_id }).update_all({ archived: archived })
    Source.where({ team_id: team_id }).update_all({ archived: archived })
    ProjectMedia.where(team_id:team_id).update_all({ archived: archived })
  end

  def self.empty_trash(team_id)
    Team.find(team_id).trash.destroy_all
  end

  def empty_trash=(confirm)
    if confirm
      ability = Ability.new
      if ability.can?(:destroy, :trash)
        self.affected_ids = self.trash.all.map(&:graphql_id)
        Team.delay_for(5.seconds).empty_trash(self.id)
      else
        raise I18n.t(:permission_error, default: "Sorry, you are not allowed to do this")
      end
    end
  end

  def public_team
    self
  end

  def public_team_id
    Base64.encode64("PublicTeam/#{self.id}")
  end

  def self.slug_from_name(name)
    name.parameterize.underscore.dasherize.ljust(4, '-')
  end

  def self.current
    RequestStore.store[:team]
  end

  def self.current=(team)
    RequestStore.store[:team] = team
  end

  def self.slug_from_url(url)
    # Use extract to solve cases that URL inside [] {} () ...
    url = URI.extract(url)[0]
    URI(url).path.split('/')[1]
  end

  def custom_permissions(ability = nil)
    perms = {}
    ability ||= Ability.new
    tmp = ProjectMedia.new(team_id: self.id, archived: CheckArchivedFlags::FlagCodes::NONE)
    tag_text = TagText.new(team_id: self.id)
    team_task = TeamTask.new(team_id: self.id)
    project = Project.new(team_id: self.id)
    relationship = Relationship.new(source: tmp, target: tmp)
    perms["empty Trash"] = ability.can?(:destroy, :trash)
    perms["invite Members"] = ability.can?(:invite_members, self)
    perms["not_spam ProjectMedia"] = ability.can?(:not_spam, tmp)
    perms["restore ProjectMedia"] = ability.can?(:restore, tmp)
    perms["confirm ProjectMedia"] = ability.can?(:confirm, tmp)
    perms["update ProjectMedia"] = ability.can?(:update, ProjectMedia.new(team_id: self.id))
    perms["bulk_update ProjectMedia"] = ability.can?(:bulk_update, ProjectMedia.new(team_id: self.id))
    perms["bulk_create Tag"] = ability.can?(:bulk_create, Tag.new(team: self))
    perms["duplicate Team"] = ability.can?(:duplicate, self)
    perms["set_privacy Project"] = ability.can?(:set_privacy, project)
    perms["update Relationship"] = ability.can?(:update, relationship)
    perms["destroy Relationship"] = ability.can?(:destroy, relationship)
    perms["manage TagText"] = ability.can?(:manage, tag_text)
    perms["manage TeamTask"] = ability.can?(:manage, team_task)
    perms
  end

  def permissions_info
    YAML.load(ERB.new(File.read("#{Rails.root}/config/permission_info.yml")).result)
  end

  def dynamic_search_fields_json_schema
    annotation_types = Annotation
                       .group('annotations.annotation_type')
                       .joins("INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia' AND pm.id = annotations.annotated_id")
                       .where('pm.team_id' => self.id).count.keys
    properties = {
      sort: { type: 'object', properties: {} }
    }
    annotation_types.each do |type|
      method = "field_search_json_schema_type_#{type}"
      if Dynamic.respond_to?(method)
        schema = Dynamic.send(method, self)
        [schema].flatten.each { |subschema| properties[subschema[:id] || type] = subschema }
      end
      # Uncomment to allow sorting by a dynamic field (was used by deadline field)
      # method = "field_sort_json_schema_type_#{type}"
      # if Dynamic.respond_to?(method)
      #   sort = Dynamic.send(method, self)
      #   properties[:sort][:properties][sort[:id]] = { type: 'array', title: sort[:label], items: { type: 'string', enum: [sort[:asc_label], sort[:desc_label]] } } if sort
      # end
    end
    { type: 'object', properties: properties }
  end

  def get_report_design_image_template
    self.settings[:report_design_image_template] || self.settings['report_design_image_template'] || File.read(File.join(Rails.root, 'public', 'report-design-default-image-template.html'))
  end

  def delete_custom_media_verification_status(status_id, fallback_status_id)
    unless status_id.blank?
      data = DynamicAnnotation::Field
        .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia'")
        .where('dynamic_annotation_fields.field_name' =>  'verification_status_status', 'pm.team_id' => self.id)
        .where('dynamic_annotation_fields_value(field_name, value) = ?', status_id.to_json)
        .select('pm.id AS pmid, dynamic_annotation_fields.id AS fid').to_a
      pmids = data.map(&:pmid)

      # Validations
      raise I18n.t(:must_provide_fallback_when_deleting_status_in_use) if fallback_status_id.blank? && data.size > 0

      unless fallback_status_id.blank?
        # Update all statuses in the database
        DynamicAnnotation::Field.where(id: data.map(&:fid)).update_all(value: fallback_status_id)

        # Update status cache
        pmids.each { |id| Rails.cache.write("check_cached_field:ProjectMedia:#{id}:status", fallback_status_id) }

        # Update ElasticSearch in background
        Team.delay.reindex_statuses_after_deleting_status(pmids.to_json, fallback_status_id)

        # Update reports in background
        Team.delay.update_reports_after_changing_statuses(pmids.to_json, fallback_status_id)
      end

      # Update team statuses after deleting one of them
      settings = self.settings || {}
      statuses = settings.with_indifferent_access[:media_verification_statuses]
      statuses ||= team.send('verification_statuses', 'media')
      statuses[:statuses] = statuses[:statuses].reject{ |s| s[:id] == status_id }
      self.set_media_verification_statuses = statuses
      self.save!
    end
  end

  def list_columns
    Rails.cache.fetch("list_columns:team:#{I18n.locale}:#{self.id}") do
      show_columns = self.get_list_columns || Team.default_list_columns.select{ |c| c[:show] }.collect{ |c| c[:key] }
      columns = []
      Team.default_list_columns.each do |column|
        columns << column.merge({ show: show_columns.include?(column[:key]) })
      end
      TeamTask.where(team_id: self.id, fieldset: 'metadata', associated_type: 'ProjectMedia').each do |tt|
        key = "task_value_#{tt.id}"
        columns << {
          key: key,
          label: tt.label,
          show: show_columns.include?(key),
          type: tt.task_type
        }
      end
      columns.sort_by! do |column|
        index = show_columns.index(column[:key])
        index.nil? ? show_columns.size : index
      end
      columns
    end
  end

  def self.reindex_statuses_after_deleting_status(ids_json, fallback_status_id)
    script = { source: "ctx._source.verification_status = params.status", params: { status: fallback_status_id } }
    ProjectMedia.bulk_reindex(ids_json, script)
  end

  def self.update_reports_after_changing_statuses(ids_json, fallback_status_id)
    ids = JSON.parse(ids_json)
    ids.each do |id|
      report = Annotation.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: id).last
      unless report.nil?
        report = report.load
        pm = ProjectMedia.find(id)
        data = report.data.clone.with_indifferent_access
        data[:state] = 'paused'
        data[:options].merge!({
          theme_color: pm.status_color(fallback_status_id),
          status_label: pm.status_i18n(fallback_status_id, { locale: data[:options][:language] })
        })
        report.data = data
        report.save!
      end
    end
  end

  def self.update_reports_if_labels_changed(team_id, statuses_were, statuses)
    ids_that_changed_labels = []

    # Find the status IDs that changed label
    if statuses && statuses_were && statuses != statuses_were
      statuses_were['statuses'].each do |status|
        status['locales'].each do |locale, value|
          new_label = statuses['statuses'].find{ |s| s['id'] == status['id'] }&.dig('locales', locale, 'label')
          if new_label && value['label'] != new_label
            ids_that_changed_labels << status['id']
          end
        end
      end
    end

    return if ids_that_changed_labels.empty?

    ids_that_changed_labels.uniq.each do |status_id|
      # Find reports with that status
      data = DynamicAnnotation::Field
        .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON pm.id = a.annotated_id AND a.annotated_type = 'ProjectMedia'")
        .where('dynamic_annotation_fields.field_name' =>  'verification_status_status', 'pm.team_id' => team_id)
        .where('dynamic_annotation_fields_value(field_name, value) = ?', status_id.to_json)
        .select('pm.id AS pmid, dynamic_annotation_fields.id AS fid').to_a
      pmids = data.map(&:pmid)

      # Update reports
      self.update_reports_after_changing_statuses(pmids.to_json, status_id)
    end
  end

  def self.update_reports_if_languages_changed(team_id, languages)
    result = FactCheck.select('pm.id as pm_id, fact_checks.id as fc_id').where(language: languages)
    .joins(:claim_description).joins("INNER JOIN project_medias pm ON pm.id = claim_descriptions.project_media_id")
    .where('pm.team_id = ?', team_id)
    unless result.blank?
      team = Team.find_by_id(team_id)
      team_languages = team&.get_languages || ['en']
      report_language = team_languages.length == 1 ? team_languages.first : 'und'
      fc_ids = result.map(&:fc_id)
      pm_ids = result.map(&:pm_id)
      # Update fact-check
      FactCheck.where(id: fc_ids).update_all(language: report_language)
      Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: pm_ids)
      .find_in_batches(:batch_size => 1000) do |items|
        rows = []
        items.each do |report|
          data = report.data.with_indifferent_access
          unless data.blank?
            data[:options][:language] = report_language
            report.data = data
            rows << report
          end
        end
        # Import items with existing ids to make update
        Dynamic.import(items, recursive: false, validate: false, on_duplicate_key_update: [:data])
        # Update ES
        annotated_ids = items.map(&:annotated_id)
        options = {
          index: CheckElasticSearchModel.get_index_alias,
          conflicts: 'proceed',
          body: {
            script: { source: "ctx._source.fact_check_languages = params.lang", params: { lang: [report_language] } },
            query: { terms: { annotated_id: annotated_ids } }
          }
        }
        $repository.client.update_by_query options
      end
    end
  end

  # This is a method and not a constant because we need the localizations to be evaluated in runtime
  def self.default_list_columns
    [
      {
        key: 'demand',
        label: I18n.t(:list_column_demand),
        show: true
      },
      {
        key: 'share_count',
        label: I18n.t(:list_column_share_count),
        show: true
      },
      {
        key: 'linked_items_count',
        label: I18n.t(:list_column_linked_items_count),
        show: true
      },
      {
        key: 'type_of_media',
        label: I18n.t(:list_column_type),
        show: true
      },
      {
        key: 'status',
        label: I18n.t(:list_column_status),
        show: true
      },
      {
        key: 'created_at_timestamp',
        label: I18n.t(:list_column_created_at),
        show: true
      },
      {
        key: 'last_seen',
        label: I18n.t(:list_column_last_seen),
        show: true
      },
      {
        key: 'updated_at_timestamp',
        label: I18n.t(:list_column_updated_at),
        show: true
      },
      {
        key: 'report_status',
        label: I18n.t(:list_column_report_status),
        show: false
      },
      {
        key: 'tags_as_sentence',
        label: I18n.t(:list_column_tags_as_sentence),
        show: false
      },
      {
        key: 'media_published_at',
        label: I18n.t(:list_column_media_published_at),
        show: false
      },
      {
        key: 'published_by',
        label: I18n.t(:list_column_published_by),
        show: false
      },
      {
        key: 'fact_check_published_on',
        label: I18n.t(:list_column_fact_check_published_on),
        show: false
      },
      {
        key: 'comment_count',
        label: I18n.t(:list_column_comment_count),
        show: false
      },
      {
        key: 'reaction_count',
        label: I18n.t(:list_column_reaction_count),
        show: false
      },
      {
        key: 'related_count',
        label: I18n.t(:list_column_related_count),
        show: false
      },
      {
        key: 'suggestions_count',
        label: I18n.t(:list_column_suggestions_count),
        show: false
      },
      {
        key: 'folder',
        label: I18n.t(:list_column_folder),
        show: false
      },
      {
        key: 'creator_name',
        label: I18n.t(:list_column_creator_name),
        show: false
      },
      {
        key: 'team_name',
        label: I18n.t(:list_column_team_name),
        show: false
      },
      {
        key: 'sources_as_sentence',
        label: I18n.t(:list_column_sources_as_sentence),
        show: false
      },
      {
        key: 'fact_check_title',
        label: I18n.t(:list_column_fact_check_title),
        show: false
      }
    ]
  end

  def default_language
    self.get_language || 'en'
  end

  def sources_by_keyword(keyword = nil)
    sources = self.sources
    sources = sources.where('name ILIKE ?', "%#{keyword}%") unless keyword.blank?
    sources
  end

  def tag_texts_by_keyword(keyword = nil)
    keyword.blank? ? self.tag_texts : self.tag_texts.where('text ILIKE ?', "%#{keyword}%")
  end

  def data_report
    monthly_statistics = MonthlyTeamStatistic.where(team_id: self.id).order('start_date ASC')
    if monthly_statistics.present?
      index = 1
      monthly_statistics.map do |stat|
        hash = stat.formatted_hash
        hash['Org'] = self.name
        hash['Month'] = "#{index}. #{hash['Month']}"
        index += 1
        hash
      end
    else
      data = Rails.cache.read("data:report:#{self.id}")
      return nil if data.blank?

      data.map.with_index do |row, i|
        row['Month'] = "#{i + 1}. #{row['Month']}"
        row.reject { |key, _value| key =~ /[sS]earch/ || ['Average number of conversations per day', 'Number of messages sent'].include?(key) }
      end
    end
  end

  def is_part_of_feed?(feed_id)
    FeedTeam.where(team_id: self.id, feed_id: feed_id).exists?
  end

  def get_feed(feed_id)
    self.feeds.where(id: feed_id.to_i).last
  end

  # A newsletter header type is available only if there are WhatsApp templates for it
  def available_newsletter_header_types
    available = []
    tbi = TeamBotInstallation.where(team_id: self.id, user_id: BotUser.smooch_user&.id.to_i).last
    unless tbi.nil?
      ['none', 'image', 'video', 'audio', 'link_preview'].each do |header_type|
        mapped_header_type = TiplineNewsletter::HEADER_TYPE_MAPPING[header_type]
        if !tbi.send("get_smooch_template_name_for_newsletter_#{mapped_header_type}_no_articles").blank? &&
           !tbi.send("get_smooch_template_name_for_newsletter_#{mapped_header_type}_one_articles").blank? &&
           !tbi.send("get_smooch_template_name_for_newsletter_#{mapped_header_type}_two_articles").blank? &&
           !tbi.send("get_smooch_template_name_for_newsletter_#{mapped_header_type}_three_articles").blank?
          available << header_type
        end
      end
    end
    available
  end

  # private
  #
  # Please add private methods to app/models/concerns/team_private.rb
end
