module FeedMutations
  MUTATION_TARGET = 'feed'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, GraphQL::Types::String, required: false
      argument :tags, [GraphQL::Types::String, null: true], required: false
      argument :media_saved_search_id, GraphQL::Types::Int, required: false, camelize: false
      argument :article_saved_search_id, GraphQL::Types::Int, required: false, camelize: false
      argument :published, GraphQL::Types::Boolean, required: false, camelize: false
      argument :discoverable, GraphQL::Types::Boolean, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :name, GraphQL::Types::String, required: true
    argument :licenses, [GraphQL::Types::Int, null: true], required: true
    argument :data_points, [GraphQL::Types::Int, null: true], required: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :name, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end

  class ImportMedia < Mutations::BaseMutation
    argument :feed_id, GraphQL::Types::Int, required: true
    argument :project_media_id, GraphQL::Types::Int, required: true
    argument :parent_id, GraphQL::Types::Int, required: false
    argument :claim_title, GraphQL::Types::String, required: false
    argument :claim_context, GraphQL::Types::String, required: false

    field :project_media, ProjectMediaType, null: false

    def resolve(feed_id:, project_media_id:, parent_id: nil, claim_title: nil, claim_context: nil)
      ability = context[:ability] || Ability.new
      feed = Feed.find(feed_id)
      pm = nil
      if Team.current&.id && User.current&.id && ability.can?(:import_media, feed)
        cluster = Cluster.where(feed_id: feed_id, project_media_id: project_media_id).last
        pm = cluster.import_medias_to_team(Team.current, claim_title, claim_context, parent_id)
      end
      { project_media: pm }
    end
  end
end
