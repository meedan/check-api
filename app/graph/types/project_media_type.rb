ProjectMediaType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMedia'
  description 'ProjectMedia type'

  interfaces [NodeIdentification.interface]

  field :media_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
  field :url, types.String
  field :quote, types.String
  field :metadata, types.String
  field :dbid, types.Int
  field :archived, types.Boolean
  field :author_role, types.String
  field :report_type, types.String

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

  field :account do
    type -> { AccountType }

    resolve -> (project_media, _args, _ctx) {
      project_media.media.account
    }
  end

  field :project do
    type -> { ProjectType }

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(Project).load(project_media.project_id)
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

    resolve -> (project_media, _args, _ctx) {
      RecordLoader.for(User).load(project_media.user_id)
    }
  end

  field :team do
    type -> { TeamType }

    resolve ->(project_media, _args, _ctx) {
      RecordLoader.for(Project).load(project_media.project_id).then do |project|
        RecordLoader.for(Team).load(project.team_id)
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
      project_media.get_annotations('tag')
    }
  end

  connection :tasks, -> { TaskType.connection_type } do
    resolve ->(project_media, _args, _ctx) {
      project_media.get_annotations('task')
    }
  end

  field :embed do
    type JsonStringType

    resolve ->(project_media, _args, _ctx) {
      project_media.embed
    }
  end

  field :last_status do
    type types.String

    resolve ->(project_media, _args, _ctx) {
      project_media.last_status
    }
  end

  field :last_status_obj do
    type -> { StatusType }

    resolve -> (project_media, _args, _ctx) {
      project_media.last_status_obj.load
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
      Bot::Alegre.default.language_object(project_media, :to_s)
    }
  end

  field :language_code do
    type types.String

    resolve ->(project_media, _args, _ctx) {
      Bot::Alegre.default.language_object(project_media, :value)
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

  instance_exec :media, &GraphqlCrudOperations.field_verification_statuses

  connection :assignments, -> { AnnotationType.connection_type } do
    argument :user_id, !types.Int
    argument :annotation_type, !types.String

    resolve ->(project_media, args, _ctx) {
      Annotation.where(annotated_type: 'ProjectMedia', annotated_id: project_media.id, assigned_to_id: args['user_id'], annotation_type: args['annotation_type'])
    }
  end

  # End of fields
end
