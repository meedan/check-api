QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The query root of the schema.'

  field :node, field: NodeIdentification.field

  field :root, RootLevelType do
    resolve -> (_obj, _args, _ctx) { RootLevel::STATIC }
  end

  field :about, AboutType, 'Information about the application' do
    resolve -> (_obj, _args, _ctx) do
      OpenStruct.new({
        type: 'About',
        id: 1,
        name: Rails.application.class.parent_name,
        version: VERSION,
        languages_supported: CheckCldr.localized_languages.to_json,
        terms_last_updated_at: User.terms_last_updated_at,
        image_max_size: UploadedImage.max_size_readable,
        image_extensions: ImageUploader.upload_extensions.join(', '),
        image_min_dimensions: "#{SizeValidator.config('min_width')}x#{SizeValidator.config('min_height')}",
        image_max_dimensions: "#{SizeValidator.config('max_width')}x#{SizeValidator.config('max_height')}",
        video_max_size: UploadedVideo.max_size_readable,
        video_extensions: VideoUploader.upload_extensions.join(', ')
      })
    end
  end

  field :me, UserType, 'Information about the current user' do
    resolve -> (_obj, _args, _ctx) do
      User.current
    end
  end

  # TODO Can we have this field ONLY return the current team?
  field :team, TeamType, 'Information about the current team' do
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

  # TODO Can we have this field ONLY return the current team?
  field :public_team, PublicTeamType, 'Public information about the current team' do
    argument :slug, types.String

    resolve -> (_obj, args, _ctx) do
      team = args['slug'].blank? ? Team.current : Team.where(slug: args['slug']).last
      id = team.blank? ? 0 : team.id
      Team.find(id)
    end
  end

  # TODO "find_X" means this is not a field
  field :find_public_team, PublicTeamType, 'Public information about a team' do
    argument :slug, !types.String

    resolve -> (_obj, args, _ctx) do
      Team.where(slug: args['slug']).last
    end
  end

  field :project_media, ProjectMediaType, 'Information about a media, given its team ids. The argument has the following format: "project_media_id,project_id,team_id"' do
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

  connection :project_medias, ProjectMediaType.connection_type, 'Information about a media, given its URL' do
    argument :url, !types.String

    resolve -> (_obj, args, _ctx) {
      return [] if User.current.nil?
      m = Link.where(url: args['url']).last
      m = Link.where(url: Link.normalized(args['url'])).last if m.nil?
      return [] if m.nil?
      tids = User.current.team_ids
      ProjectMedia.joins(:project).where('project_medias.media_id' => m.id, 'projects.team_id' => tids)
    }
  end

  field :project, ProjectType, 'Information about a project, given its team ids' do
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

  # TODO Include actual search keys in description
  field :search, CheckSearchType, 'A search query. The argument has the following format: {"keyword":"search keyword"}}' do
    argument :query, !types.String

    resolve -> (_obj, args, ctx) do
      Team.find_if_can(Team.current&.id.to_i, ctx[:ability])
      CheckSearch.new(args['query'])
    end
  end

  field :dynamic_annotation_field, DynamicAnnotationFieldType, 'TODO' do
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
    field type, "#{type.to_s.camelize}Type".constantize, 'Information about a #{type} given its id' do
      argument :id, !types.ID

      resolve -> (_obj, args, ctx) do
        GraphqlCrudOperations.load_if_can(type.to_s.camelize.constantize, args['id'], ctx)
      end
    end
  end
end
