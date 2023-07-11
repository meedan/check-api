class TiplineNewsletterType < DefaultObject
  description "TiplineNewsletter type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :introduction, GraphQL::Types::String, null: true
  field :header_type, GraphQL::Types::String, null: true
  field :header_file_url, GraphQL::Types::String, null: true
  field :header_overlay_text, GraphQL::Types::String, null: true
  field :content_type, GraphQL::Types::String, null: true
  field :rss_feed_url, GraphQL::Types::String, null: true
  field :first_article, GraphQL::Types::String, null: true
  field :second_article, GraphQL::Types::String, null: true
  field :third_article, GraphQL::Types::String, null: true
  field :number_of_articles, GraphQL::Types::Int, null: true
  field :send_every, JsonStringType, null: true
  field :send_on, GraphQL::Types::String, null: true

  def send_on
    object.send_on ? object.send_on.strftime("%Y-%m-%d") : nil
  end
  field :timezone, GraphQL::Types::String, null: true
  field :time, GraphQL::Types::String, null: true

  def time
    object.time.strftime("%H:%M")
  end
  field :subscribers_count, GraphQL::Types::Int, null: true
  field :footer, GraphQL::Types::String, null: true
  field :language, GraphQL::Types::String, null: true
  field :enabled, GraphQL::Types::Boolean, null: true
  field :team, TeamType, null: true
  field :last_scheduled_at, GraphQL::Types::Int, null: true
  field :last_scheduled_by, UserType, null: true
  field :last_sent_at, GraphQL::Types::Int, null: true
  field :last_delivery_error, GraphQL::Types::String, null: true
end
