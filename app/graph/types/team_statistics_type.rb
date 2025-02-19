class TeamStatisticsType < DefaultObject
  description 'Workspace statistics.'

  implements GraphQL::Types::Relay::Node

  # For articles

  field :number_of_articles_created_by_date, JsonStringType, null: true
  field :number_of_articles_updated_by_date, JsonStringType, null: true
  field :number_of_explainers_created, GraphQL::Types::Int, null: true
  field :number_of_fact_checks_created, GraphQL::Types::Int, null: true
  field :number_of_published_fact_checks, GraphQL::Types::Int, null: true
  field :number_of_fact_checks_by_rating, JsonStringType, null: true
  field :top_articles_sent, JsonStringType, null: true
  field :top_articles_tags, JsonStringType, null: true

  # For tiplines

  field :number_of_messages, GraphQL::Types::Int, null: true
  field :number_of_incoming_messages, GraphQL::Types::Int, null: true
  field :number_of_outgoing_messages, GraphQL::Types::Int, null: true
  field :number_of_conversations, GraphQL::Types::Int, null: true
  field :number_of_messages_by_date, JsonStringType, null: true
  field :number_of_incoming_messages_by_date, JsonStringType, null: true
  field :number_of_outgoing_messages_by_date, JsonStringType, null: true
  field :number_of_conversations_by_date, JsonStringType, null: true
  field :number_of_search_results_by_feedback_type, JsonStringType, null: true
  field :average_response_time, GraphQL::Types::Int, null: true
  field :number_of_unique_users, GraphQL::Types::Int, null: true
  field :number_of_total_users, GraphQL::Types::Int, null: true
  field :number_of_returning_users, GraphQL::Types::Int, null: true
  field :number_of_subscribers, GraphQL::Types::Int, null: true
  field :number_of_new_subscribers, GraphQL::Types::Int, null: true
  field :number_of_newsletters_sent, GraphQL::Types::Int, null: true
  field :number_of_newsletters_delivered, GraphQL::Types::Int, null: true
  field :top_media_tags, JsonStringType, null: true
  field :top_requested_media_clusters, JsonStringType, null: true
  field :number_of_media_received_by_media_type, JsonStringType, null: true

  # For both articles and tiplines

  field :number_of_articles_sent, GraphQL::Types::Int, null: true
  field :number_of_matched_results_by_article_type, JsonStringType, null: true
end
