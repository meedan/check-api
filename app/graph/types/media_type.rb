module Types
  class MediaType < DefaultObject
    description "Media type"

    implements GraphQL::Types::Relay::NodeField

    field :url, String, null: true
    field :quote, String, null: true
    field :account_id, Integer, null: true
    field :dbid, Integer, null: true
    field :domain, String, null: true
    field :pusher_channel, String, null: true
    field :embed_path, String, null: true
    field :thumbnail_path, String, null: true
    field :picture, String, null: true
    field :type, String, null: true
    field :file_path, String, null: true
    field :metadata, JsonString, null: true

    field :account, AccountType, null: true

    def account
      object.account
    end
  end
end
