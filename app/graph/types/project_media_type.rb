ProjectMediaType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMedia'
  description 'ProjectMedia type'

  interfaces [NodeIdentification.interface]

  field :media_id, types.Int
  field :user_id, types.Int
  field :url, types.String
  field :quote, types.String
  field :oembed_metadata, types.String
  field :dbid, types.Int
  field :archived, types.Boolean
  field :author_role, types.String
  field :report_type, types.String
  field :title, types.String
  field :description, types.String
  field :picture, types.String
  field :virality, types.Int
  field :requests_count, types.Int
  field :demand, types.Int
  field :linked_items_count, types.Int
  field :last_seen, types.String
  field :status, types.String
  field :share_count, types.Int

  field :type, types.String  do
    resolve -> (project_media, _args, _ctx) {
      project_media.media.type
    }
  end

  field :permissions, types.String do
    resolve -> (project_media, _args, ctx) {
      PermissionsLoader.for(ctx[:ability]).load(project_media.id).then do |pm|
        pm.cached_permissions || pm.permissions
      end
    }
  end

  field :tasks_count, JsonStringType do
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

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id).then do |media|
        media.respond_to?(:domain) ? media.domain : ''
      end
    }
  end

  field :pusher_channel do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id).then do |media|
        media.pusher_channel
      end
    }
  end

  # field :account do
  #   type -> { AccountType }
  #
  #   resolve -> (project_media, _args, _ctx) {
  #     RecordLoader.for(Media).load(project_media.media_id).then do |media|
  #       RecordLoader.for(Account).load(media.account_id)
  #     end
  #   }
  # end
  #
  # field :team do
  #   type -> { TeamType }
  #
  #   resolve ->(project_media, _args, _ctx) {
  #     RecordLoader.for(Project).load(project_media.project_id).then do |project|
  #       RecordLoader.for(Team).load(project.team_id)
  #     end
  #   }
  # end
  { media: :account }.each do |key, value|
    type = "#{value.to_s.capitalize}Type".constantize
    field value do
      type -> { type }

      resolve -> (project_media, _args, _ctx) {
        RecordLoader.for(key.to_s.capitalize.constantize).load(project_media.send("#{key}_id")).then do |obj|
          RecordLoader.for(value.to_s.capitalize.constantize).load(obj.send("#{value}_id"))
        end
      }
    end
  end

  field :team do
    type -> { TeamType }

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Team).load(project_media.team_id)
    }
  end

  field :project_id do
    type types.Int

    resolve -> (project_media, _args, _ctx) {
      Project.current ? Project.current.reload.id : project_media.reload.project_id
    }
  end

  field :project do
    type -> { ProjectType }

    resolve -> (project_media, _args, _ctx) {
      Project.current || RecordLoader.for(Project).load(project_media.project_id)
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id).then do |media|
        media.projects
      end
    }
  end

  field :media do
    type -> { MediaType }

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Media).load(project_media.media_id)
    }
  end

  field :user do
    type -> { UserType }

    resolve -> (project_media, _args, ctx) {
      RecordLoader.for(User).load(project_media.user_id).then do |user|
        ability = ctx[:ability] || Ability.new
        user if ability.can?(:read, user)
      end
    }
  end

  field :project_source do
    type -> { ProjectSourceType }

    resolve ->(project_media, _args, _ctx) {
      project_media.project_source
    }
  end

  instance_exec :project_media, &GraphqlCrudOperations.field_log

  instance_exec :project_media, &GraphqlCrudOperations.field_log_count

  connection :tags, -> { TagType.connection_type } do
    resolve ->(project_media, _args, _ctx) {
      project_media.get_annotations('tag').map(&:load)
    }
  end

  connection :tasks, -> { TaskType.connection_type } do
    resolve ->(project_media, _args, _ctx) {
      Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: project_media.id)
    }
  end

  field :metadata do
    type JsonStringType

    resolve ->(project_media, _args, _ctx) {
      project_media.metadata
    }
  end

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

  field :overridden do
    type JsonStringType

    resolve ->(project_media, _args, _ctx) {
      project_media.overridden
    }
  end

  instance_exec :project_media, &GraphqlCrudOperations.field_published

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

  field :relationship do
    type RelationshipType

    resolve ->(project_media, _args, _ctx) {
      Relationship.where(target_id: project_media.id).first || Relationship.where(source_id: project_media.id).first
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

  connection :targets_by_users, -> { ProjectMediaType.connection_type }

  DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
    connection "dynamic_annotations_#{type}".to_sym, -> { DynamicType.connection_type } do
      resolve ->(project_media, _args, _ctx) { project_media.get_annotations(type) }
    end

    field "dynamic_annotation_#{type}".to_sym do
      type -> { DynamicType }
      resolve -> (project_media, _args, _ctx) { project_media.get_dynamic_annotation(type) }
    end
  end

  field :project_ids, JsonStringType

  connection :secondary_items, -> { ProjectMediaType.connection_type } do
    argument :source_type, types.String
    argument :target_type, types.String

    resolve -> (project_media, args, _ctx) {
      related_items = ProjectMedia.joins('INNER JOIN relationships ON relationships.target_id = project_medias.id').where('relationships.source_id' => project_media.id)
      related_items = related_items.where('relationships.relationship_type = ?', { source: args['source_type'], target: args['target_type'] }.to_yaml) if args['source_type'] && args['target_type']
      related_items
    }
  end

  # End of fields
end
