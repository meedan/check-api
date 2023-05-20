module Types
  class QueryType < BaseObject
    description "The query root of this schema"

    add_field GraphQL::Types::Relay::NodeField

    field :root, RootLevelType, null: true

    def root
      RootLevel::STATIC
    end

    field :about,
          AboutType,
          description: "Information about the application",
          null: true

    def about
      OpenStruct.new(
        {
          name: Rails.application.class.module_parent_name,
          version: VERSION,
          id: 1,
          type: "About",
          upload_max_size: UploadedImage.max_size_readable,
          upload_max_in_bytes: UploadedImage.max_size,
          upload_extensions: ImageUploader.upload_extensions,
          video_max_size: UploadedVideo.max_size_readable,
          video_max_size_in_bytes: UploadedVideo.max_size,
          video_extensions: VideoUploader.upload_extensions,
          audio_max_size: UploadedAudio.max_size_readable,
          audio_max_size_in_bytes: UploadedAudio.max_size,
          audio_extensions: AudioUploader.upload_extensions,
          file_max_size: UploadedFile.max_size_readable,
          file_max_size_in_bytes: UploadedFile.max_size,
          file_extensions: GenericFileUploader.upload_extensions,
          upload_min_dimensions:
            "#{SizeValidator.config("min_width")}x#{SizeValidator.config("min_height")}",
          upload_max_dimensions:
            "#{SizeValidator.config("max_width")}x#{SizeValidator.config("max_height")}",
          languages_supported: CheckCldr.localized_languages.to_json,
          terms_last_updated_at: User.terms_last_updated_at,
          channels: CheckChannels::ChannelCodes.all_channels
        }
      )
    end

    field :me,
          UserType,
          description: "Information about the current user",
          null: true

    def me
      User.current
    end

    # Get team by id or slug

    field :team,
          TeamType,
          description:
            "Information about the context team or the team from given id",
          null: true do
      argument :id, ID, required: false
      argument :slug, String, required: false
      # random argument is for bypassing Relay cache. This is a temporary fix
      # while we don't have our Relay code 100% up to date, which we expect will
      # make this unnecessary. Fixes issue reported in CHECK-2331
      argument :random, String, required: false
    end

    def team(**args)
      tid = args[:id].to_i
      if !args[:slug].blank?
        team = Team.where(slug: args[:slug]).first
        tid = team.id unless team.nil?
      end
      tid = Team.current&.id || User.current&.teams&.first&.id if tid === 0
      GraphqlCrudOperations.load_if_can(Team, tid.to_i, context)
    end

    # Get public team

    field :public_team,
          PublicTeamType,
          description: "Public information about a team",
          null: true do
      argument :slug, String, required: false
    end

    def public_team(**args)
      team =
        args[:slug].blank? ? Team.current : Team.where(slug: args[:slug]).last
      id = team.blank? ? 0 : team.id
      Team.find(id)
    end

    field :find_public_team,
          PublicTeamType,
          description: "Find whether a team exists",
          null: true do
      argument :slug, String, required: true
    end

    def find_public_team(**args)
      Team.where(slug: args[:slug]).last
    end

    field :project_media,
          ProjectMediaType,
          description:
            'Information about a project media, The argument should be given like this: "project_media_id,project_id,team_id"',
          null: true do
      argument :ids, String, required: true
    end

    def project_media(**args)
      objid, pid, tid = args[:ids].split(",").map(&:to_i)
      tid = (Team.current.blank? && tid.nil?) ? 0 : (tid || Team.current.id)
      project = Project.where(id: pid, team_id: tid).last
      pid = project.nil? ? 0 : project.id
      Project.current = project
      objid = ProjectMedia.belonged_to_project(objid, pid, tid) || 0
      GraphqlCrudOperations.load_if_can(ProjectMedia, objid, context)
    end

    field :project_medias,
          ProjectMediaType.connection_type,
          null: true,
          connection: true do
      argument :url, String, required: true
    end

    def project_medias(**args)
      return [] if User.current.nil?
      m = Link.where(url: args[:url]).last
      m = Link.where(url: Link.normalized(args[:url])).last if m.nil?
      return [] if m.nil?
      tids = Team.current ? [Team.current.id] : User.current.team_ids
      ProjectMedia.where(media_id: m.id, team_id: tids)
    end

    field :project,
          ProjectType,
          description:
            "Information about a project, given its id and its team id",
          null: true do
      argument :id, String, required: false
      argument :ids, String, required: false
    end

    def project(**args)
      pid = args[:id].to_i unless args[:id].blank?
      pid, tid = args[:ids].split(",").map(&:to_i) unless args[:ids].blank?
      tid = (Team.current.blank? && tid.nil?) ? 0 : (tid || Team.current.id)
      project = Project.where(id: pid, team_id: tid).last
      id = project.nil? ? 0 : project.id
      GraphqlCrudOperations.load_if_can(Project, id, context)
    end

    field :search,
          CheckSearchType,
          description:
            'Search medias, The argument should be given like this: "{\"keyword\":\"search keyword\"}"',
          null: true do
      argument :query, String, required: true
    end

    def search(**args)
      team = Team.find_if_can(Team.current&.id.to_i, context[:ability])
      CheckSearch.new(args[:query], context[:file], team&.id)
    end

    field :dynamic_annotation_field, DynamicAnnotationFieldType, null: true do
      argument :query, String, required: true
      argument :only_cache, Boolean, required: false
    end

    def dynamic_annotation_field(**args)
      ability = context[:ability] || Ability.new
      if ability.can?(:find_by_json_fields, DynamicAnnotation::Field.new)
        cache_key =
          "dynamic-annotation-field-" + Digest::MD5.hexdigest(args[:query])
        obj = nil
        if Rails.cache.read(cache_key) || args[:only_cache]
          obj =
            DynamicAnnotation::Field.where(
              id: Rails.cache.read(cache_key).to_i
            ).last
        else
          query = JSON.parse(args[:query])
          json = query.delete("json")
          obj = DynamicAnnotation::Field.where(query)
          obj = obj.find_in_json(json) unless json.blank?
          obj = obj.last
          Rails.cache.write(cache_key, obj&.id)
        end
        obj
      end
    end

    # Getters by ID
    [:source, :user, :task, :tag_text, :bot_user, :project_group, :saved_search, :cluster, :feed, :request].each do |type|
      field type,
        "Types::#{type.to_s.camelize}Type".constantize,
        null: true,
        description: "Information about the #{type} with given id",
        resolve: -> (_obj, args, ctx) { GraphqlCrudOperations.load_if_can(type.to_s.camelize.constantize, args['id'], ctx) } do
          argument :id, ID, required: true
        end
    end
  end
end
