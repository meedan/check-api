QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :node, field: NodeIdentification.field

  field :root, RootLevelType do
    resolve -> (_obj, _args, _ctx) { RootLevel::STATIC }
  end

  field :about do
    type AboutType
    description 'Information about the application'
    resolve -> (_obj, _args, _ctx) do
      OpenStruct.new({
        name: Rails.application.class.parent_name,
        version: VERSION,
        id: 1,
        type: 'About',
        upload_max_size: UploadedImage.max_size_readable,
        upload_extensions: ImageUploader.upload_extensions.join(', '),
        video_max_size: UploadedVideo.max_size_readable,
        video_extensions: VideoUploader.upload_extensions.join(', '),
        audio_max_size: UploadedAudio.max_size_readable,
        audio_extensions: AudioUploader.upload_extensions.join(', '),
        upload_min_dimensions: "#{SizeValidator.config('min_width')}x#{SizeValidator.config('min_height')}",
        upload_max_dimensions: "#{SizeValidator.config('max_width')}x#{SizeValidator.config('max_height')}",
        languages_supported: CheckCldr.localized_languages.to_json,
        terms_last_updated_at: User.terms_last_updated_at
      })
    end
  end

  field :me do
    type UserType
    description 'Information about the current user'
    resolve -> (_obj, _args, _ctx) do
      User.current
    end
  end

  # Get team by id or slug

  field :team do
    type TeamType
    description 'Information about the context team or the team from given id'
    argument :id, types.ID
    argument :slug, types.String
    resolve -> (_obj, args, ctx) do
      tid = args['id'].to_i
      if !args['slug'].blank?
        team = Team.where(slug: args['slug']).first
        tid = team.id unless team.nil?
      end
      if tid === 0 && !Team.current.blank?
        tid = Team.current.id
      end
      GraphqlCrudOperations.load_if_can(Team, tid, ctx)
    end
  end

  # Get public team

  field :public_team do
    type PublicTeamType
    description 'Public information about a team'
    argument :slug, types.String

    resolve -> (_obj, args, _ctx) do
      team = args['slug'].blank? ? Team.current : Team.where(slug: args['slug']).last
      id = team.blank? ? 0 : team.id
      Team.find(id)
    end
  end

  field :find_public_team do
    type PublicTeamType
    description 'Find whether a team exists'
    argument :slug, !types.String

    resolve -> (_obj, args, _ctx) do
      Team.where(slug: args['slug']).last
    end
  end

  field :project_media do
    type ProjectMediaType
    description 'Information about a project media, The argument should be given like this: "project_media_id,project_id,team_id"'
    argument :ids, !types.String
    resolve -> (_obj, args, ctx) do
      objid, pid, tid = args['ids'].split(',').map(&:to_i)
      tid = (Team.current.blank? && tid.nil?) ? 0 : (tid || Team.current.id)
      project = Project.where(id: pid, team_id: tid).last
      pid = project.nil? ? 0 : project.id
      Project.current = project
      objid = ProjectMedia.belonged_to_project(objid, pid, tid) || 0
      GraphqlCrudOperations.load_if_can(ProjectMedia, objid, ctx)
    end
  end

  connection :project_medias do
    type ProjectMediaType.connection_type
    argument :url, !types.String
    resolve -> (_obj, args, _ctx) {
      return [] if User.current.nil?
      m = Link.where(url: args['url']).last
      m = Link.where(url: Link.normalized(args['url'])).last if m.nil?
      return [] if m.nil?
      tids = User.current.team_ids
      ProjectMedia.where(media_id: m.id, team_id: tids)
    }
  end

  field :project do
    type ProjectType
    description 'Information about a project, given its id and its team id'

    argument :id, types.String
    argument :ids, types.String

    resolve -> (_obj, args, ctx) do
      pid = args['id'].to_i unless args['id'].blank?
      pid, tid = args['ids'].split(',').map(&:to_i) unless args['ids'].blank?
      tid = (Team.current.blank? && tid.nil?) ? 0 : (tid || Team.current.id)
      project = Project.where(id: pid, team_id: tid).last
      id = project.nil? ? 0 : project.id
      GraphqlCrudOperations.load_if_can(Project, id, ctx)
    end
  end

  field :search do
    type CheckSearchType
    description 'Search medias, The argument should be given like this: "{\"keyword\":\"search keyword\"}"'

    argument :query, !types.String

    resolve -> (_obj, args, ctx) do
      Team.find_if_can(Team.current&.id.to_i, ctx[:ability])
      CheckSearch.new(args['query'])
    end
  end

  field :dynamic_annotation_field do
    type DynamicAnnotationFieldType

    argument :query, !types.String
    argument :only_cache, types.Boolean

    resolve -> (_obj, args, ctx) do
      ability = ctx[:ability] || Ability.new
      if ability.can?(:find_by_json_fields, DynamicAnnotation::Field.new)
        cache_key = 'dynamic-annotation-field-' + Digest::MD5.hexdigest(args['query'])
        obj = nil
        if Rails.cache.read(cache_key) || args['only_cache']
          obj = DynamicAnnotation::Field.where(id: Rails.cache.read(cache_key).to_i).last
        else
          query = JSON.parse(args['query'])
          json = query.delete('json')
          obj = DynamicAnnotation::Field.where(query)
          obj = obj.find_in_json(json) unless json.blank?
          obj = obj.last
        end
        obj
      end
    end
  end

  # Getters by ID

  [:source, :user, :task, :tag_text, :bot_user].each do |type|
    field type do
      type "#{type.to_s.camelize}Type".constantize
      description "Information about the #{type} with given id"
      argument :id, !types.ID
      resolve -> (_obj, args, ctx) do
        GraphqlCrudOperations.load_if_can(type.to_s.camelize.constantize, args['id'], ctx)
      end
    end
  end
end
