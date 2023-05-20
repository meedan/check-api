require "inclusions/task_and_annotation_fields"

module Types
  class SourceType < DefaultObject
    include ::TaskAndAnnotationFields

    description "Source type"

    implements GraphQL::Types::Relay::NodeField

    field :image, String, null: true
    field :description, String, null: false
    field :name, String, null: false
    field :dbid, Integer, null: true
    field :user_id, Integer, null: true
    field :permissions, String, null: true
    field :pusher_channel, String, null: true
    field :lock_version, Integer, null: true
    field :medias_count, Integer, null: true
    field :accounts_count, Integer, null: true
    field :overridden, Types::JsonString, null: true
    field :archived, Integer, null: true

    field :accounts, AccountType.connection_type, null: true, connection: true

    def accounts
      object.accounts
    end

    field :account_sources,
          AccountSourceType.connection_type,
          null: true,
          connection: true

    def account_sources
      object.account_sources.order(id: :asc)
    end

    field :medias, ProjectMediaType.connection_type, null: true, connection: true

    def medias
      object.media
    end

    field :medias_count, Integer, null: true, resolve: ->(source, _args, _ctx) { source.medias_count }

    field :collaborators, UserType.connection_type, null: true, connection: true

    def collaborators
      object.collaborators
    end
  end
end
