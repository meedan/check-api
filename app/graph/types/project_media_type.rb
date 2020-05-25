# TODO Rename to 'TeamMediaType'
ProjectMediaType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMedia'
  description 'Association between a Team and a Media.'

  interfaces [NodeIdentification.interface]

  field :media_id, types.Int, 'Media this item is associated with (id only)'
  field :user_id, types.Int, 'Item creator (id only)'
  field :url, types.String, 'Media URL' # TODO Remove and access via Media.url
  field :quote, types.String, 'Text claim' # TODO Remove and access via Media.quote
  field :oembed_metadata, types.String # TODO Merge with 'metadata'?
  field :dbid, types.Int, 'Database id of this record'
  field :archived, types.Boolean, 'Is this item in trash?' # TODO Rename to 'is_archived'
  field :author_role, types.String # TODO Merge with 'user'?
  field :report_type, types.String # TODO Merge with 'type'?
  field :title, types.String, 'Title'
  field :description, types.String, 'Description'
  field :picture, types.String, 'Picture'
  field :virality, types.Int, 'Virality, social reach as measured by item host'
  field :requests_count, types.Int, 'Count of requests made for this item'
  field :demand, types.Int # TODO What's the diff with requests_count?
  field :linked_items_count, types.Int, 'Count of related items' # TODO Rename to 'related_items_count'
  field :last_seen, types.String, 'when was this item last requested' # TODO Convert to date and rename to 'last_requested'
  field :status, types.String, 'Workflow status'
  field :share_count, types.Int # TODO What's the diff with virality?

  field :type, types.String  do # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types
    description 'Type' # TODO List all possible types

    resolve -> (project_media, _args, _ctx) {
      project_media.media.type
    }
  end

  field :permissions, types.String do
    description 'CRUD permissions for current user'

    resolve -> (project_media, _args, ctx) {
      PermissionsLoader.for(ctx[:ability]).load(project_media.id).then do |pm|
        pm.cached_permissions || pm.permissions
      end
    }
  end

  field :tasks_count, JsonStringType do
    description 'Counts of tasks: all, open, completed'

    resolve -> (project_media, _args, _ctx) {
      {
        all: project_media.all_tasks.size,
        open: project_media.open_tasks.size,
        completed: project_media.completed_tasks.size
      }
    }
  end

  field :domain do
    type types.String
    description 'TODO'

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id).then do |media|
        media.respond_to?(:domain) ? media.domain : ''
      end
    }
  end

  field :pusher_channel do
    type types.String
    description 'Channel for push notifications'

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id).then do |media|
        media.pusher_channel
      end
    }
  end

  { media: :account }.each do |key, value|
    type = "#{value.to_s.capitalize}Type".constantize
    field value do
      type -> { type }
      Description "#{type} this item is associated with"

      resolve -> (project_media, _args, _ctx) {
        RecordLoader.for(key.to_s.capitalize.constantize).load(project_media.send("#{key}_id")).then do |obj|
          RecordLoader.for(value.to_s.capitalize.constantize).load(obj.send("#{value}_id"))
        end
      }
    end
  end

  field :team do
    type -> { TeamType }
    Description 'Team this item is associated with'

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Team).load(project_media.team_id)
    }
  end

  # TODO Remove
  field :project_id do
    type types.Int

    resolve -> (project_media, _args, _ctx) {
      Project.current ? Project.current.reload.id : project_media.reload.project_id
    }
  end

  # TODO Remove
  field :project do
    type -> { ProjectType }

    resolve -> (project_media, _args, _ctx) {
      Project.current || RecordLoader.for(Project).load(project_media.project_id)
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    description 'Projects associated with this item'
    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id).then do |media|
        media.projects
      end
    }
  end

  field :media do
    type -> { MediaType }
    description 'Media this item is associated with'

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id)
    }
  end

  field :user do
    type -> { UserType }
    description 'Item creator'

    resolve -> (project_media, _args, ctx) {
      RecordLoader.for(User).load(project_media.user_id).then do |user|
        ability = ctx[:ability] || Ability.new
        user if ability.can?(:read, user)
      end
    }
  end

  # TODO Remove
  field :project_source do
    type -> { ProjectSourceType }

    resolve ->(project_media, _args, _ctx) {
      project_media.project_source
    }
  end

  # TODO What's this and how to add description?
  instance_exec :project_media, &GraphqlCrudOperations.field_log

  # TODO What's this and how to add description?
  instance_exec :project_media, &GraphqlCrudOperations.field_log_count

  connection :tags, -> { TagType.connection_type } do
    description 'Item tags'

    resolve ->(project_media, _args, _ctx) {
      project_media.get_annotations('tag').map(&:load)
    }
  end

  connection :tasks, -> { TaskType.connection_type } do
    description 'Item tasks'

    resolve ->(project_media, _args, _ctx) {
      Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: project_media.id)
    }
  end

  field :metadata do
    type JsonStringType
    description 'Item metadata'

    resolve ->(project_media, _args, _ctx) {
      project_media.metadata
    }
  end

  # TODO Merge this and 'last_status_obj' into 'status'
  field :last_status do
    type types.String

    resolve ->(project_media, _args, _ctx) {
      project_media.last_status
    }
  end

  field :last_status_obj do
    type -> { DynamicType }

    resolve -> (project_media, _args, _ctx) {
      obj = project_media.last_status_obj
      obj.is_a?(Dynamic) ? obj : obj.load
    }
  end

  # TODO What's this for?
  field :overridden do
    type JsonStringType

    resolve ->(project_media, _args, _ctx) {
      project_media.overridden
    }
  end

  instance_exec :project_media, &GraphqlCrudOperations.field_published

  # TODO Merge this and 'language_code'
  field :language do
    type types.String

    resolve ->(project_media, _args, _ctx) {
      project_media.get_dynamic_annotation('language')&.get_field('language')&.send(:to_s)
    }
  end

  field :language_code do
    type types.String

    resolve ->(project_media, _args, _ctx) {
      project_media.get_dynamic_annotation('language')&.get_field_value('language')
    }
  end

  field :annotation do
    type -> { AnnotationType }
    argument :annotation_type, !types.String

    resolve ->(project_media, args, _ctx) {
      project_media.get_dynamic_annotation(args['annotation_type'])
    }
  end

  instance_exec :project_media, &GraphqlCrudOperations.field_annotations

  instance_exec :project_media, &GraphqlCrudOperations.field_annotations_count

  field :field_value do
    type types.String
    argument :annotation_type_field_name, !types.String

    resolve ->(project_media, args, _ctx) {
      annotation_type, field_name = args['annotation_type_field_name'].to_s.split(':')
      if !annotation_type.blank? && !field_name.blank?
        annotation = project_media.get_dynamic_annotation(annotation_type)
        annotation.nil? ? nil : annotation.get_field_value(field_name)
      end
    }
  end

  connection :assignments, -> { AnnotationType.connection_type } do
    argument :user_id, !types.Int
    argument :annotation_type, !types.String

    resolve ->(project_media, args, _ctx) {
      Annotation.joins(:assignments).where('annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => project_media.id, 'assignments.user_id' => args['user_id'], 'annotations.annotation_type' => args['annotation_type'])
    }
  end

  # TODO Merge this and 'relationships' and 'secondary_items' and 'targets_by_users'
  field :relationship do
    type RelationshipType

    resolve ->(project_media, _args, _ctx) {
      Relationship.where(target_id: project_media.id).first || Relationship.where(source_id: project_media.id).first
    }
  end

  field :relationships do
    type -> { RelationshipsType }

    resolve -> (project_media, _args, _ctx) do
      OpenStruct.new({
        id: project_media.id,
        target_id: Relationship.target_id(project_media),
        source_id: Relationship.source_id(project_media),
        project_media_id: project_media.id,
        targets_count: project_media.targets_count,
        sources_count: project_media.sources_count
      })
    end
  end

  connection :secondary_items, -> { ProjectMediaType.connection_type } do
    argument :source_type, types.String
    argument :target_type, types.String

    resolve -> (project_media, args, _ctx) {
      related_items = ProjectMedia.joins('INNER JOIN relationships ON relationships.target_id = project_medias.id').where('relationships.source_id' => project_media.id)
      related_items = related_items.where('relationships.relationship_type = ?', { source: args['source_type'], target: args['target_type'] }.to_yaml) if args['source_type'] && args['target_type']
      related_items
    }
  end

  connection :targets_by_users, -> { ProjectMediaType.connection_type }

  # TODO Rename to 'annotations' and remove 'tasks' and 'tags'?
  DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
    connection "dynamic_annotations_#{type}".to_sym, -> { DynamicType.connection_type } do
      description "Item annotations of type #{type}"

      resolve ->(project_media, _args, _ctx) { project_media.get_annotations(type) }
    end

    # TODO What's the diff with above?
    field "dynamic_annotation_#{type}".to_sym do
      type -> { DynamicType }
      resolve -> (project_media, _args, _ctx) { project_media.get_dynamic_annotation(type) }
    end
  end

  field :project_ids, JsonStringType, 'Projects associated with this item (ids only)'
end
