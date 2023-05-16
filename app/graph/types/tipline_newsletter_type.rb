TiplineNewsletterType = GraphqlCrudOperations.define_default_type do
  name 'TiplineNewsletter'
  description 'TiplineNewsletter type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :introduction, types.String
  field :header_type, types.String
  field :header_file_url, types.String
  field :header_overlay_text, types.String
  field :content_type, types.String
  field :rss_feed_url, types.String
  field :first_article, types.String
  field :second_article, types.String
  field :third_article, types.String
  field :number_of_articles, types.Int
  field :send_every, JsonStringType
  field :send_on, types.String do
    resolve -> (newsletter, _args, _ctx) {
      newsletter.send_on ? newsletter.send_on.strftime("%Y-%m-%d") : nil
    }
  end
  field :timezone, types.String
  field :time, types.String do
    resolve -> (newsletter, _args, _ctx) {
      newsletter.time.strftime("%H:%M")
    }
  end
  field :subscribers_count, types.Int
  field :footer, types.String
  field :language, types.String
  field :enabled, types.Boolean
  field :team, TeamType
  field :last_scheduled_at, types.Int
  field :last_scheduled_by, UserType
  field :last_sent_at, types.Int
  field :last_error, types.String
end
