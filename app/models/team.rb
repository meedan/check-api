class Team < ApplicationRecord
  class RelevantArticlesError < StandardError; end

  # These two callbacks must be in the top
  after_create :create_team_partition
  before_destroy :delete_created_bots, :remove_is_default_project_flag

  include SearchHelper
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
    self.projects.permissioned.count
  end

  def as_json(_options = {})
    {
      dbid: self.id,
      id: self.team_graphql_id,
      avatar: self.avatar,
      name: self.name,
      projects: self.recent_projects,
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
    perms["destroy FeedInvitation"] = ability.can?(:destroy, FeedInvitation.new(feed: Feed.new(team: self)))
    perms["destroy FeedTeam"] = ability.can?(:destroy, FeedTeam.new(team: self, feed: Feed.new(team: self)))
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

      if data.blank?
        empty_data_structure
      else
        data.map.with_index do |row, i|
          row['Month'] = "#{i + 1}. #{row['Month']}"
          row.reject { |key, _value| ['Average number of conversations per day', 'Number of messages sent'].include?(key) }
        end
      end
    end
  end

  def is_part_of_feed?(feed_id)
    FeedTeam.where(team_id: self.id, feed_id: feed_id).exists?
  end

  def get_feed(feed_id)
    self.feeds.where(id: feed_id.to_i).last
  end

  def get_api_key(api_key_id)
    self.api_keys.where(id: api_key_id.to_i).last
  end

  # A newsletter header type is available only if there are WhatsApp templates for it
  def available_newsletter_header_types
    available = []
    tbi = TeamBotInstallation.where(team_id: self.id, user_id: BotUser.smooch_user&.id.to_i).last
    unless tbi.nil?
      ['none', 'image', 'video', 'audio', 'link_preview'].each do |header_type|
        mapped_header_type = TiplineNewsletter::WHATSAPP_HEADER_TYPE_MAPPING[header_type]
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

  def filtered_articles(filters = {}, limit = 10, offset = 0, order = 'created_at', order_type = 'DESC')
    columns = [:id, :title, :language, :created_at, :updated_at]
    fact_checks = self.filtered_fact_checks(filters, false).select(["'FactCheck' AS type"] + columns.collect{ |column| "fact_checks.#{column}" })
    explainers = self.filtered_explainers(filters).select(["'Explainer' AS type"] + columns.collect{ |column| "explainers.#{column}" })

    query = <<~SQL
      SELECT type, id FROM ( #{fact_checks.to_sql} UNION #{explainers.to_sql} ) AS articles
      ORDER BY #{order} #{order_type} LIMIT ? OFFSET ?
    SQL

    results = ActiveRecord::Base.connection.exec_query(ActiveRecord::Base.sanitize_sql([query, limit, offset]))

    # FIXME: Avoid N + 1 queries problem here
    results.map{ |row| OpenStruct.new(row) }.collect{ |object| object.type.constantize.find(object.id) }
  end

  def filtered_explainers(filters = {})
    query = self.explainers

    # Filter by tags
    query = query.where('ARRAY[?]::varchar[] && tags', filters[:tags].to_a.map(&:to_s)) unless filters[:tags].blank?

    # Filter by user
    query = query.where(user_id: filters[:user_ids].to_a.map(&:to_i)) unless filters[:user_ids].blank?

    # Filter by date
    query = query.where('explainers.created_at != explainers.updated_at').where(updated_at: Range.new(*format_times_search_range_filter(JSON.parse(filters[:updated_at]), nil))) unless filters[:updated_at].blank?
    query = query.where(created_at: Range.new(*format_times_search_range_filter(JSON.parse(filters[:created_at]), nil))) unless filters[:created_at].blank?

    # Filter by trashed
    query = query.where(trashed: !!filters[:trashed])

    # Filter by text
    query = self.filter_by_keywords(query, filters, 'Explainer') if filters[:text].to_s.size > 2

    # Exclude the ones already applied to a target item
    target = ProjectMedia.find_by_id(filters[:target_id].to_i)
    query = query.where.not(id: target.explainer_ids) unless target.nil?

    query
  end

  def filtered_fact_checks(filters = {}, include_claim_descriptions = true)
    query = (include_claim_descriptions ? FactCheck.includes(:claim_description) : FactCheck.joins(:claim_description))
    query = query.where('claim_descriptions.team_id' => self.id)

    # Filter by standalone
    query = query.left_joins(claim_description: { project_media: :media }).where('claim_descriptions.project_media_id IS NULL OR medias.type = ?', 'Blank') if filters[:standalone]

    # Filter by language
    query = query.where('fact_checks.language' => filters[:language].to_a) unless filters[:language].blank?

    # Filter by tags
    query = query.where('ARRAY[?]::varchar[] && fact_checks.tags', filters[:tags].to_a.map(&:to_s)) unless filters[:tags].blank?

    # Filter by user
    query = query.where('fact_checks.user_id' => filters[:user_ids].to_a.map(&:to_i)) unless filters[:user_ids].blank?

    # Filter by date
    query = query.where('fact_checks.created_at != fact_checks.updated_at').where('fact_checks.updated_at' => Range.new(*format_times_search_range_filter(JSON.parse(filters[:updated_at]), nil))) unless filters[:updated_at].blank?
    query = query.where('fact_checks.created_at' => Range.new(*format_times_search_range_filter(JSON.parse(filters[:created_at]), nil))) unless filters[:created_at].blank?

    # Filter by publisher
    query = query.where('fact_checks.publisher_id' => filters[:publisher_ids].to_a.map(&:to_i)) unless filters[:publisher_ids].blank?

    # Filter by rating
    query = query.where('fact_checks.rating' => filters[:rating].to_a.map(&:to_s)) unless filters[:rating].blank?

    # Filter by imported
    query = query.where('fact_checks.imported' => !!filters[:imported]) unless filters[:imported].nil?

    # Filter by report status
    query = query.where('fact_checks.report_status' => [filters[:report_status]].flatten.map(&:to_s)) unless filters[:report_status].blank?

    # Filter by trashed
    query = query.where('fact_checks.trashed' => !!filters[:trashed])

    # Filter by text
    query = self.filter_by_keywords(query, filters) if filters[:text].to_s.size > 2

    # Exclude the ones already applied to a target item
    target = ProjectMedia.find_by_id(filters[:target_id].to_i)
    query = query.where.not('fact_checks.id' => target.fact_check_id) unless target.nil?

    query
  end

  def filter_by_keywords(query, filters, type = 'FactCheck')
    tsquery = Team.sanitize_sql_array(["websearch_to_tsquery(?)", filters[:text]])
    if type == 'FactCheck'
      tsvector = "to_tsvector('simple', coalesce(fact_checks.title, '') || ' ' || coalesce(fact_checks.summary, '') || ' ' || coalesce(fact_checks.url, '') || ' ' || coalesce(claim_descriptions.description, '') || ' ' || coalesce(claim_descriptions.context, ''))"
    elsif type == 'Explainer'
      tsvector = "to_tsvector('simple', coalesce(explainers.title, '') || ' ' || coalesce(explainers.description, '') || ' ' || coalesce(explainers.url, ''))"
    end
    query.where(Arel.sql("#{tsvector} @@ #{tsquery}"))
  end

  def similar_articles_search_limit(pm = nil)
    pm.nil? ? CheckConfig.get('most_relevant_team_limit', 3, :integer) : CheckConfig.get('most_relevant_item_limit', 10, :integer)
  end

  def search_for_similar_articles(query, pm = nil, language = nil, settings = nil)
    # query:  expected to be text
    # pm: to request a most relevant to specific item and also include both FactCheck & Explainer
    limit = self.similar_articles_search_limit(pm)
    threads = []
    fc_items = []
    ex_items = []
    threads << Thread.new {
      result_ids = Bot::Smooch.search_for_similar_published_fact_checks_no_cache('text', query, [self.id], limit, nil, nil, language, pm.nil?, settings).map(&:id)
      unless result_ids.blank?
        fc_items = FactCheck.joins(claim_description: :project_media).where('project_medias.id': result_ids)
        if !pm&.fact_check_id.nil?
          # Exclude the ones already applied to a target item if exists.
          fc_items = fc_items.where.not('fact_checks.id' => pm.fact_check_id) unless pm&.fact_check_id.nil?
        end
      end
    }
    threads << Thread.new {
      ex_items = Bot::Smooch.search_for_explainers(nil, query, self.id, limit, language, settings).distinct
      # Exclude the ones already applied to a target item
      ex_items = ex_items.where.not(id: pm.explainer_ids) unless pm&.explainer_ids.blank?
    }
    threads.map(&:join)
    items = fc_items
    # Get Explainers if no fact-check returned or get similar_articles for a ProjectMedia
    items += ex_items if items.blank? || !pm.nil?
    Rails.logger.info("Relevant articles found for team slug #{self.slug}, project media with ID #{pm&.id} and query #{query}: #{items.map(&:graphql_id)}")
    items
  rescue StandardError => e
    Rails.logger.warn("Error when trying to retrieve relevant articles for team slug #{self.slug}, project media with ID #{pm&.id} and query #{query}.")
    CheckSentry.notify(RelevantArticlesError.new('Error when trying to retrieve relevant articles'), team_slug: self.slug, project_media_id: pm&.id, query: query, exception_message: e.message, exception: e)
    []
  end

  def get_shorten_outgoing_urls
    self.settings.to_h.with_indifferent_access[:shorten_outgoing_urls] || self.tipline_newsletters.where(content_type: 'rss', enabled: true).exists?
  end

  def get_dashboard_exported_data(filters, dashboard_type)
    filters = filters.with_indifferent_access
    ts = TeamStatistics.new(self, filters[:period], filters[:language], filters[:platform])
    headers = get_dashboard_export_headers(ts, dashboard_type)
    data = []
    # Add header labels
    data << headers.keys
    header_methods = headers.values.delete_if{|v| v.blank?}
    # Merging multiple hashes as single hash
    header_methods = Hash[*header_methods.map{|v|v.to_a}.flatten]
    raw = []
    header_methods.each do |method, type|
      unless type.blank?
        output = ts.send(method) if ts.respond_to?(method)
        if type.is_a?(Proc)
          output = type.call(output)
        else
          output = output.send(type)
        end
        raw << output
      end
    end
    data << raw.flatten
    data
  end

  # private
  #
  # Please add private methods to app/models/concerns/team_private.rb
end
