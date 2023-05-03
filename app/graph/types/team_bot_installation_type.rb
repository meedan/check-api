TeamBotInstallationType = GraphqlCrudOperations.define_default_type do
  name 'TeamBotInstallation'
  description 'Team Bot Installation type'

  interfaces [NodeIdentification.interface]

  field :json_settings, types.String

  field :lock_version, types.Int do
    resolve -> (team_bot_installation, _args, _ctx) {
      team_bot_installation.reload.lock_version
    }
  end

  field :bot_user do
    type -> { BotUserType }

    resolve -> (team_bot_installation, _args, _ctx) {
      RecordLoader.for(BotUser).load(team_bot_installation.user_id)
    }
  end

  field :team do
    type -> { TeamType }

    resolve -> (team_bot_installation, _args, _ctx) {
      RecordLoader.for(Team).load(team_bot_installation.team_id)
    }
  end

  field :alegre_settings, JsonStringType

  # Only for Smooch Bot

  field :smooch_enabled_integrations do
    type JsonStringType
    argument :force, types.Boolean
    resolve -> (obj, args, _ctx) do
      obj.smooch_enabled_integrations(args['force'])
    end
  end

  field :smooch_bot_preview_rss_feed do
    type types.String

    argument :rss_feed_url, !types.String
    argument :number_of_articles, !types.Int

    resolve -> (obj, args, ctx) do
      return nil unless obj.bot_user.login == 'smooch'
      ability = ctx[:ability] || Ability.new
      if ability.can?(:preview_rss_feed, Team.current)
        Bot::Smooch.render_articles_from_rss_feed(args[:rss_feed_url], args[:number_of_articles])
      else
        I18n.t(:cant_preview_rss_feed)
      end
    end
  end

  field :smooch_newsletter_information, JsonStringType
end
