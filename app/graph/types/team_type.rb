class TeamType < DefaultObject
  description "Team type"

  implements GraphQL::Types::Relay::Node

  field :archived, GraphQL::Types::Int, null: true
  field :private, GraphQL::Types::Boolean, null: true
  field :avatar, GraphQL::Types::String, null: true
  field :name, GraphQL::Types::String, null: false
  field :slug, GraphQL::Types::String, null: false
  field :description, GraphQL::Types::String, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :members_count, GraphQL::Types::Int, null: true
  field :projects_count, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :get_slack_webhook, GraphQL::Types::String, null: true
  field :get_embed_whitelist, GraphQL::Types::String, null: true
  field :get_report_design_image_template, GraphQL::Types::String, null: true
  field :get_status_target_turnaround, GraphQL::Types::String, null: true
  field :pusher_channel, GraphQL::Types::String, null: true
  field :search_id, GraphQL::Types::String, null: true
  field :search, CheckSearchType, null: true
  field :check_search_trash, CheckSearchType, null: true
  field :check_search_unconfirmed, CheckSearchType, null: true
  field :check_search_spam, CheckSearchType, null: true
  field :trash_size, JsonStringType, null: true
  field :public_team_id, GraphQL::Types::String, null: true
  field :permissions_info, JsonStringType, null: true
  field :dynamic_search_fields_json_schema, JsonStringType, null: true
  field :get_slack_notifications, JsonStringType, null: true
  field :get_rules, JsonStringType, null: true
  field :rules_json_schema, GraphQL::Types::String, null: true
  field :slack_notifications_json_schema, GraphQL::Types::String, null: true
  field :rules_search_fields_json_schema, JsonStringType, null: true
  field :medias_count, GraphQL::Types::Int, null: true
  field :spam_count, GraphQL::Types::Int, null: true
  field :trash_count, GraphQL::Types::Int, null: true
  field :unconfirmed_count, GraphQL::Types::Int, null: true
  field :get_language_detection, GraphQL::Types::Boolean, null: true
  field :get_report, JsonStringType, null: true
  field :get_fieldsets, JsonStringType, null: true
  field :list_columns, JsonStringType, null: true
  field :url, GraphQL::Types::String, null: true
  field :data_report, JsonStringType, null: true
  field :available_newsletter_header_types, JsonStringType, null: true # List of header type strings

  field :get_slack_notifications_enabled, GraphQL::Types::String, null: true

  def get_slack_notifications_enabled
    object.get_slack_notifications_enabled
  end

  field :get_slack_webhook, GraphQL::Types::String, null: true

  def get_slack_webhook
    object.get_slack_webhook
  end

  field :get_embed_whitelist, GraphQL::Types::String, null: true

  def get_embed_whitelist
    object.get_embed_whitelist
  end

  field :get_report_design_image_template, GraphQL::Types::String, null: true

  def get_report_design_image_template
    object.get_report_design_image_template
  end

  field :get_status_target_turnaround, GraphQL::Types::String, null: true

  def get_status_target_turnaround
    object.get_status_target_turnaround
  end

  field :get_slack_notifications, JsonStringType, null: true

  def get_slack_notifications
    object.get_slack_notifications
  end

  field :get_rules, JsonStringType, null: true

  def get_rules
    object.get_rules
  end

  field :get_languages, GraphQL::Types::String, null: true

  def get_languages
    object.get_languages
  end

  field :get_language, GraphQL::Types::String, null: true

  def get_language
    object.get_language
  end

  field :get_report, JsonStringType, null: true

  def get_report
    placeholders = {}
    object.get_languages.to_a.each { |language| placeholders[language] = { 'placeholders' => { 'query_date' => Dynamic.new.report_design_date(Time.now, language) } } }
    object.get_report.to_h.deep_merge(placeholders)
  end

  field :get_fieldsets, JsonStringType, null: true

  def get_fieldsets
    object.get_fieldsets
  end

  field :list_columns, JsonStringType, null: true
  field :get_data_report_url, GraphQL::Types::String, null: true

  def get_data_report_url
    object.get_data_report_url
  end

  field :url, GraphQL::Types::String, null: true
  field :get_tipline_inbox_filters, JsonStringType, null: true

  def get_tipline_inbox_filters
    object.get_tipline_inbox_filters
  end

  field :get_suggested_matches_filters, JsonStringType, null: true

  def get_suggested_matches_filters
    object.get_suggested_matches_filters
  end

  field :get_outgoing_urls_utm_code, GraphQL::Types::String, null: true

  def get_outgoing_urls_utm_code
    object.get_outgoing_urls_utm_code
  end

  field :get_shorten_outgoing_urls, GraphQL::Types::Boolean, null: true

  def get_shorten_outgoing_urls
    object.get_shorten_outgoing_urls
  end

  field :public_team, PublicTeamType, null: true

  def public_team
    object
  end

  field :verification_statuses, JsonStringType, null: true do
    argument :items_count_for_status, GraphQL::Types::String, required: false, camelize: false
    argument :published_reports_count_for_status, GraphQL::Types::String, required: false, camelize: false
  end

  def verification_statuses(items_count_for_status: nil, published_reports_count_for_status: nil)
    # We sometimes call this method and somehow object is nil despite self.object being available
    object ||= self.object
    object = object.reload if items_count_for_status || published_reports_count_for_status
    object.verification_statuses("media", nil, items_count_for_status, published_reports_count_for_status)
  end

  field :team_bot_installation, TeamBotInstallationType, null: true do
    argument :bot_identifier, GraphQL::Types::String, required: true, camelize: false
  end

  def team_bot_installation(bot_identifier:)
    TeamBotInstallation.where(
      user_id: BotUser.get_user(bot_identifier)&.id,
      team_id: object.id
    ).first
  end

  field :team_users, TeamUserType.connection_type, null: true do
    argument :status, [GraphQL::Types::String, null: true], required: false
  end

  def team_users(status: nil)
    object.team_users.where({ status: (status || "member") }).order("id ASC")
  end

  field :join_requests, TeamUserType.connection_type, null: true

  def join_requests
    object.team_users.where({ status: "requested" })
  end

  field :users, UserType.connection_type, null: true

  field :projects, ProjectType.connection_type, null: true

  def projects
    object.recent_projects
  end

  field :sources_count, GraphQL::Types::Int, null: true do
    argument :keyword, GraphQL::Types::String, required: false
  end

  def sources_count(keyword: nil)
    object.sources_by_keyword(keyword).count
  end

  field :sources, SourceType.connection_type, null: true do
    argument :keyword, GraphQL::Types::String, required: false
  end

  def sources(keyword: nil)
    object.sources_by_keyword(keyword)
  end

  field :team_bots, BotUserType.connection_type, null: true

  field :team_bot_installations, TeamBotInstallationType.connection_type, null: true

  field :tag_texts, TagTextType.connection_type, null: true do
    argument :keyword, GraphQL::Types::String, required: false
  end

  def tag_texts(keyword: nil)
    object.tag_texts_by_keyword(keyword)
  end

  field :tag_texts_count, GraphQL::Types::Int, null: true do
    argument :keyword, GraphQL::Types::String, required: false
  end

  def tag_texts_count(keyword: nil)
    object.tag_texts_by_keyword(keyword).count
  end

  field :team_tasks, TeamTaskType.connection_type, null: true do
    argument :fieldset, GraphQL::Types::String, required: false
  end

  def team_tasks(fieldset: nil)
    tasks = object.team_tasks.order(order: :asc, id: :asc)
    tasks = tasks.where(fieldset: fieldset) unless fieldset.blank?
    tasks
  end

  field :team_task, TeamTaskType, null: true do
    argument :dbid, GraphQL::Types::Int, required: true
  end

  def team_task(dbid:)
    object.team_tasks.where(id: dbid.to_i).last
  end

  field :default_folder, ProjectType, null: true

  field :feed, FeedType, null: true do
    argument :dbid, GraphQL::Types::Int, required: true
  end

  def feed(dbid:)
    object.get_feed(dbid)
  end

  field :shared_teams, JsonStringType, null: true

  def shared_teams
    data = {}
    object.shared_teams.each { |t| data[t.id] = t.name }
    data
  end

  field :saved_searches, SavedSearchType.connection_type, null: true
  field :project_groups, ProjectGroupType.connection_type, null: true
  field :feeds, FeedType.connection_type, null: true
  field :feed_teams, FeedTeamType.connection_type, null: false
  field :tipline_newsletters, TiplineNewsletterType.connection_type, null: true
  field :tipline_resources, TiplineResourceType.connection_type, null: true

  field :tipline_messages, TiplineMessageType.connection_type, null: true do
    argument :uid, GraphQL::Types::String, required: true
  end

  def tipline_messages(uid:)
    TiplineMessagesPagination.new(object.tipline_messages.where(uid: uid).order('sent_at DESC'))
  end

  field :articles, ::ArticleUnion.connection_type, null: true do
    argument :article_type, GraphQL::Types::String, required: true
  end

  def articles(article_type:)
    object.explainers if article_type == 'explainer'
  end
end
