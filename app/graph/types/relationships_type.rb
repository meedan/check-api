RelationshipsType = GraphQL::ObjectType.define do
  name 'Relationships'
  description 'The sources and targets relationships of the project media'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :target_id, types.String
  field :source_id, types.String
  field :targets_count, types.Int
  field :sources_count, types.Int

  connection :sources, -> { RelationshipsSourceType.connection_type } do
    resolve ->(obj, _args, _ctx) {
      project_media = ProjectMedia.find(obj.project_media_id)
      project_media.target_relationships.includes(:source).collect do |relationship|
        type = relationship.relationship_type.to_json
        source = relationship.source
        source.relationship = relationship
        OpenStruct.new({
          id: [relationship.source_id, type].join('/'),
          relationship_id: relationship.id,
          source: source,
          type: type,
          siblings: relationship.siblings(true)
        })
      end
    }
  end

  connection :targets, -> { RelationshipsTargetType.connection_type } do
    argument :filters, types.String

    resolve ->(obj, args, _ctx) {
      project_media = ProjectMedia.find(obj.project_media_id)
      filters = args['filters'].blank? ? nil : JSON.parse(args['filters'])
      Relationship.targets_grouped_by_type(project_media, filters).collect{ |x| OpenStruct.new(x) }
    }
  end
end
