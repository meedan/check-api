TeamBotInstallationType = GraphqlCrudOperations.define_default_type do
  name 'TeamBotInstallation'
  description 'Team Bot Installation type'

  implements NodeIdentification.interface

  field :json_settings, String, null: true

  field :bot_user, BotUserType, null: true

  def bot_user
    RecordLoader.for(BotUser).load(object.user_id)
  end

  field :team, TeamType, null: true

  def team
    RecordLoader.for(Team).load(object.team_id)
  end

  # Only for Smooch Bot

  field :smooch_enabled_integrations, JsonStringType, null: true do
    argument :force, Boolean, required: false
  end

  def smooch_enabled_integrations(**args)
    object.smooch_enabled_integrations(args[:force])
  end

  field :smooch_bot_preview_rss_feed, String, null: true do
    argument :rss_feed_url, String, required: true
    argument :number_of_articles, Integer, required: true
  end

  def smooch_bot_preview_rss_feed(**args)
    return nil unless object.bot_user.login == 'smooch'
    ability = context[:ability] || Ability.new
    if ability.can?(:preview_rss_feed, Team.current)
      Bot::Smooch.render_articles_from_rss_feed(args[:rss_feed_url], args[:number_of_articles])
    else
      I18n.t(:cant_preview_rss_feed)
    end
  end
end
