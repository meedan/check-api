ProjectMediaType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMedia'
  description 'ProjectMedia type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('ProjectMedia')
  field :updated_at, types.String
  field :media_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
  field :url, types.String
  field :quote, types.String
  field :metadata, types.String
  field :dbid, types.Int

  field :domain do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      media = project_media.media
      media.respond_to?(:domain) ? media.domain : ''
    }
  end

  field :pusher_channel do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      project_media.media.pusher_channel
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
      project_media.project
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve -> (project_media, _args, _ctx) {
      project_media.media.projects
    }
  end

  field :media do
    type -> { MediaType }

    resolve -> (project_media, _args, _ctx) {
      project_media.media
    }
  end

  field :user do
    type -> { UserType }

    resolve -> (project_media, _args, _ctx) {
      project_media.user
    }
  end

  field :team do
    type -> { TeamType }

    resolve ->(project_media, _args, _ctx) {
      project_media.project.team
    }
  end

  connection :log, -> { VersionType.connection_type } do
    resolve ->(project_media, _args, _ctx) {
      project_media.get_versions_log
    }
  end

  field :log_count do
    type types.Int

    resolve ->(project_media, _args, _ctx) {
      project_media.get_versions_log_count
    }
  end

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
    type types.String

    resolve ->(project_media, _args, _ctx) {
      project_media.embed.to_json
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
      project_media.get_annotations('status').last
    }
  end

  field :overridden do
    type types.String

    resolve ->(project_media, _args, _ctx) {
      project_media.overridden.to_json
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

# End of fields
end
