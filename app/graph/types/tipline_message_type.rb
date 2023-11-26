class TiplineMessageType < DefaultObject
  description "TiplineMessage type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :event, GraphQL::Types::String, null: true
  field :direction, GraphQL::Types::String, null: true
  field :language, GraphQL::Types::String, null: true
  field :platform, GraphQL::Types::String, null: true
  field :uid, GraphQL::Types::String, null: true
  field :external_id, GraphQL::Types::String, null: true
  field :payload, JsonStringType, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :state, GraphQL::Types::String, null: true
  field :team, TeamType, null: true
  field :sent_at, GraphQL::Types::String, null: true, camelize: false
  field :media_url, GraphQL::Types::String, null: true
  field :cursor, GraphQL::Types::String, null: true

  def sent_at
    object.sent_at.to_i.to_s
  end

  # def cursor
  #   GraphQL::Schema::Base64Encoder.encode(object.id.to_i.to_s)
  # end
end
