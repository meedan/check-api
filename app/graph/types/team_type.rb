class TeamType < DefaultObject
  description "Team type"

  implements NodeIdentification.interface

  field :archived, Integer, null: true
  field :private, Boolean, null: true
  field :avatar, String, null: true
  field :name, String, null: false
  field :slug, String, null: false
  field :description, String, null: true
  field :dbid, Integer, null: true
  field :members_count, Integer, null: true
  field :projects_count, Integer, null: true
  field :permissions, String, null: true
  field :get_slack_notifications_enabled, String, null: true
  field :get_slack_webhook, String, null: true
  field :get_embed_whitelist, String, null: true
  field :get_report_design_image_template, String, null: true
  field :get_status_target_turnaround, String, null: true
  field :pusher_channel, String, null: true
  field :search_id, String, null: true
  field :search, CheckSearchType, null: true
  field :check_search_trash, CheckSearchType, null: true
  field :check_search_unconfirmed, CheckSearchType, null: true
  field :check_search_spam, CheckSearchType, null: true
  field :trash_size, JsonString, null: true
  field :public_team_id, String, null: true
  field :permissions_info, JsonString, null: true
  field :dynamic_search_fields_json_schema, JsonString, null: true
  field :get_slack_notifications, JsonString, null: true
  field :get_rules, JsonString, null: true
  field :rules_json_schema, String, null: true
  field :slack_notifications_json_schema, String, null: true
  field :rules_search_fields_json_schema, JsonString, null: true
  field :medias_count, Integer, null: true
  field :spam_count, Integer, null: true
  field :trash_count, Integer, null: true
  field :unconfirmed_count, Integer, null: true
  field :get_languages, String, null: true
  field :get_language, String, null: true
  field :get_language_detection, Boolean, null: true
  field :get_report, JsonString, null: true
  field :get_fieldsets, JsonString, null: true
  field :list_columns, JsonString, null: true
  field :get_data_report_url, String, null: true
  field :url, String, null: true
  field :get_tipline_inbox_filters, JsonString, null: true
  field :get_suggested_matches_filters, JsonString, null: true
  field :data_report, JsonString, null: true
  field :available_newsletter_header_types, JsonString, null: true # List of header type strings
  field :get_outgoing_urls_utm_code, String, null: true
  field :get_shorten_outgoing_urls, Boolean, null: true

  def get_slack_notifications_enabled
    object.get_slack_notifications_enabled
  end

  field :get_slack_webhook, String, null: true

  def get_slack_webhook
    object.get_slack_webhook
  end

  field :get_embed_whitelist, String, null: true

  def get_embed_whitelist
    object.get_embed_whitelist
  end

  field :get_report_design_image_template, String, null: true

  def get_report_design_image_template
    object.get_report_design_image_template
  end

  field :get_status_target_turnaround, String, null: true

  def get_status_target_turnaround
    object.get_status_target_turnaround
  end

  field :pusher_channel, String, null: true
  field :search_id, String, null: true
  field :search, CheckSearchType, null: true
  field :check_search_trash, CheckSearchType, null: true
  field :check_search_unconfirmed, CheckSearchType, null: true
  field :check_search_spam, CheckSearchType, null: true
  field :trash_size, JsonString, null: true
  field :public_team_id, String, null: true
  field :permissions_info, JsonString, null: true
  field :dynamic_search_fields_json_schema, JsonString, null: true
  field :get_slack_notifications, JsonString, null: true

  def get_slack_notifications
    object.get_slack_notifications
  end

  field :get_rules, JsonString, null: true

  def get_rules
    object.get_rules
  end

  field :rules_json_schema, String, null: true
  field :slack_notifications_json_schema, String, null: true
  field :rules_search_fields_json_schema, JsonString, null: true
  field :medias_count, Integer, null: true
  field :spam_count, Integer, null: true
  field :trash_count, Integer, null: true
  field :unconfirmed_count, Integer, null: true
  field :get_languages, String, null: true

  def get_languages
    object.get_languages
  end

  field :get_language, String, null: true

  def get_language
    object.get_language
  end

  field :get_report, JsonString, null: true

  def get_report
    object.get_report
  end

  field :get_fieldsets, JsonString, null: true

  def get_fieldsets
    object.get_fieldsets
  end

  field :list_columns, JsonString, null: true
  field :get_data_report_url, String, null: true

  def get_data_report_url
    object.get_data_report_url
  end

  field :url, String, null: true
  field :get_tipline_inbox_filters, JsonString, null: true

  def get_tipline_inbox_filters
    object.get_tipline_inbox_filters
  end

  field :get_suggested_matches_filters, JsonString, null: true

  def get_suggested_matches_filters
    object.get_suggested_matches_filters
  end

  field :data_report, JsonString, null: true
  field :available_newsletter_header_types, JsonString, null: true # List of header type strings
  field :get_outgoing_urls_utm_code, String, null: true

  def get_outgoing_urls_utm_code
    object.get_outgoing_urls_utm_code
  end

  field :get_shorten_outgoing_urls, Boolean, null: true

  def get_shorten_outgoing_urls
    object.get_shorten_outgoing_urls
  end

  field :public_team, PublicTeamType, null: true

  def public_team
    object
  end

  field :verification_statuses, JsonString, null: true do
    argument :items_count_for_status, String, required: false
    argument :published_reports_count_for_status, String, required: false
  end

  def verification_statuses(**args)
    object = object.reload if args[:items_count_for_status] ||
      args[:published_reports_count_for_status]
    object.send(
      "verification_statuses",
      "media",
      nil,
      args[:items_count_for_status],
      args[:published_reports_count_for_status]
    )
  end

  field :team_bot_installation, TeamBotInstallationType, null: true do
    argument :bot_identifier, String, required: true
  end

  def team_bot_installation(**args)
    TeamBotInstallation.where(
      user_id: BotUser.get_user(args[:bot_identifier])&.id,
      team_id: object.id
    ).first
  end

  field :team_users,
        TeamUserType.connection_type,
        null: true do
    argument :status, [String, null: true], required: false
  end

  def team_users(**args)
    status = args[:status] || "member"
    object.team_users.where({ status: status }).order("id ASC")
  end

  field :join_requests,
        TeamUserType.connection_type,
        null: true

  def join_requests
    object.team_users.where({ status: "requested" })
  end

  field :users, UserType.connection_type, null: true

  def users
    object.users
  end

  field :projects, ProjectType.connection_type, null: true

  def projects
    object.recent_projects.allowed(object)
  end

  field :sources_count, Integer, null: true do
    argument :keyword, String, required: false
  end

  def sources_count(**args)
    object.sources_by_keyword(args[:keyword]).count
  end

  field :sources,
        SourceType.connection_type,
        null: true do
    argument :keyword, String, required: false
  end

  def sources(**args)
    object.sources_by_keyword(args[:keyword])
  end

  field :team_bots,
        BotUserType.connection_type,
        null: true

  def team_bots
    object.team_bots
  end

  field :team_bot_installations,
        TeamBotInstallationType.connection_type,
        null: true

  def team_bot_installations
    object.team_bot_installations
  end

  field :tag_texts,
        TagTextType.connection_type,
        null: true

  def tag_texts
    object.tag_texts
  end

  field :team_tasks,
        TeamTaskType.connection_type,
        null: true do
    argument :fieldset, String, required: false
  end

  def team_tasks(**args)
    tasks = object.team_tasks.order(order: :asc, id: :asc)
    tasks = tasks.where(fieldset: args[:fieldset]) unless args[
      :fieldset
    ].blank?
    tasks
  end

  field :team_task, TeamTaskType, null: true do
    argument :dbid, Integer, required: true
  end

  def team_task(**args)
    object.team_tasks.where(id: args[:dbid].to_i).last
  end

  field :default_folder, ProjectType, null: true

  def default_folder
    object.default_folder
  end

  field :feed, FeedType, null: true do
    argument :dbid, Integer, required: true
  end

  def feed(**args)
    object.get_feed(args[:dbid])
  end

  field :shared_teams, JsonString, null: true

  def shared_teams
    data = {}
    object.shared_teams.each { |t| data[t.id] = t.name }
    data
  end

  field :saved_searches,
        SavedSearchType.connection_type,
        null: true
  field :project_groups,
        ProjectGroupType.connection_type,
        null: true
  field :feeds, FeedType.connection_type, null: true
  field :tipline_newsletters,
        TiplineNewsletterType.connection_type,
        null: true
end
