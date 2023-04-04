TiplineNewsletterType = GraphqlCrudOperations.define_default_type do
  name 'TiplineNewsletter'
  description 'TiplineNewsletter type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :introduction, types.String
  field :rss_feed_url, types.String
  field :first_article, types.String
  field :second_article, types.String
  field :third_article, types.String
  field :number_of_articles, types.Int
  field :send_every, types.String
  field :timezone, types.String
  field :time, types.String
  field :language, types.String
  field :enabled, types.Boolean
  field :team, TeamType
end
