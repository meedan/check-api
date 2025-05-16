class QueryType < BaseObject
  description "The query root of this schema"

  graphql_name "Query"

  add_field GraphQL::Types::Relay::NodeField

  field :root, RootLevelType, null: true

  # Throwaway field because Relay Modern queries on the
  # front end were adding a top-level ID field we couldn't
  # locate to remove
  field :id, GraphQL::Types::String, null: true

  def id
    nil
  end

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
        channels: CheckChannels::ChannelCodes.all_channels,
        media_cluster_origins: CheckMediaClusterOrigins::OriginCodes.all_origins
      }
    )
  end

  field :me,
        MeType,
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
    argument :id, GraphQL::Types::ID, required: false
    argument :slug, GraphQL::Types::String, required: false
    # random argument is for bypassing Relay cache. This is a temporary fix
    # while we don't have our Relay code 100% up to date, which we expect will
    # make this unnecessary. Fixes issue reported in CHECK-2331
    argument :random, GraphQL::Types::String, required: false
  end

  def team(id: nil, slug: nil, random: nil)
    tid = id.to_i
    team = nil
    unless slug.blank?
      team = Team.where(slug: slug).first
      tid = team.id unless team.nil?
    end
    team.reload if team && random
    tid = Team.current&.id || User.current&.teams&.first&.id if tid === 0
    GraphqlCrudOperations.load_if_can(Team, tid.to_i, context)
  end

  # Get public team

  field :public_team, PublicTeamType, description: "Public information about a team", null: true do
    argument :slug, GraphQL::Types::String, required: false
  end

  def public_team(slug: nil)
    team = slug.blank? ? Team.current : Team.where(slug: slug).last
    id = team.blank? ? 0 : team.id
    Team.find(id)
  end

  field :find_public_team, PublicTeamType, description: "Find whether a team exists", null: true do
    argument :slug, GraphQL::Types::String, required: true
  end

  def find_public_team(slug:)
    Team.where(slug: slug).last
  end

  field :project_media,
        ProjectMediaType,
        description:
          'Information about a project media, The argument should be given like this: "project_media_id,team_id"',
        null: true do
    argument :ids, GraphQL::Types::String, required: true
  end

  def project_media(ids:)
    objid, tid = ids.split(",").map(&:to_i)
    tid = (Team.current.blank? && tid.nil?) ? 0 : (tid || Team.current.id)
    GraphqlCrudOperations.load_if_can(ProjectMedia, objid, context)
  end

  field :project_medias, ProjectMediaType.connection_type, null: true do
    argument :url, GraphQL::Types::String, required: true
  end

  def project_medias(url:)
    return [] if User.current.nil?

    m = Link.where(url: url).last
    m = Link.where(url: Link.normalized(url)).last if m.nil?
    return [] if m.nil?

    tids = Team.current ? [Team.current.id] : User.current.team_ids
    ProjectMedia.where(media_id: m.id, team_id: tids)
  end

  field :search,
        CheckSearchType,
        description:
          'Search medias, The argument should be given like this: "{\"keyword\":\"search keyword\"}"',
        null: true do
    argument :query, GraphQL::Types::String, required: true
  end

  def search(query:)
    team = Team.find_if_can(Team.current&.id.to_i, context[:ability])
    CheckSearch.new(query, context[:file], team&.id)
  end

  field :dynamic_annotation_field, DynamicAnnotationFieldType, null: true do
    argument :query, GraphQL::Types::String, required: true
    argument :only_cache, GraphQL::Types::Boolean, required: false, camelize: false
  end

  def dynamic_annotation_field(query:, only_cache: nil)
    ability = context[:ability] || Ability.new
    if ability.can?(:find_by_json_fields, DynamicAnnotation::Field.new)
      cache_key =
        "dynamic-annotation-field-" + Digest::MD5.hexdigest(query)
      obj = nil
      if Rails.cache.read(cache_key) || only_cache
        obj =
          DynamicAnnotation::Field.where(
            id: Rails.cache.read(cache_key).to_i
          ).last
      else
        query = JSON.parse(query)
        json = query.delete("json")
        obj = DynamicAnnotation::Field.where(query)
        obj = obj.find_in_json(json) unless json.blank?
        obj = obj.last
        Rails.cache.write(cache_key, obj&.id)
      end
      obj
    end
  end

  field :feed_invitation, FeedInvitationType, description: 'Information about a feed invitation, given its database ID or feed database ID (and then the current user email is used)', null: true do
    argument :id, GraphQL::Types::Int, required: false
    argument :feed_id, GraphQL::Types::Int, required: false
  end

  def feed_invitation(id: nil, feed_id: nil)
    feed_invitation_id = id || FeedInvitation.where(feed_id: feed_id, email: User.current.email).last&.id
    GraphqlCrudOperations.load_if_can(FeedInvitation, feed_invitation_id, context)
  end

  field :feed_team, FeedTeamType, description: 'Information about a feed team, given its database ID or the combo feed database ID plus team slug', null: true do
    argument :id, GraphQL::Types::Int, required: false
    argument :feed_id, GraphQL::Types::Int, required: false
    argument :team_slug, GraphQL::Types::String, required: false
  end

  def feed_team(id: nil, feed_id: nil, team_slug: nil)
    feed_team_id = id || FeedTeam.where(feed_id: feed_id, team_id: Team.find_by_slug(team_slug).id).last&.id
    GraphqlCrudOperations.load_if_can(FeedTeam, feed_team_id, context)
  end

  # Getters by ID
  %i[
    source
    user
    task
    tag_text
    bot_user
    saved_search
    feed
    request
    tipline_message
    fact_check
    explainer
  ].each do |type|
    field type,
          "#{type.to_s.camelize}Type",
          null: true,
          description: "Information about the #{type} with given id" do
      argument :id, GraphQL::Types::ID, required: true
    end

    define_method(type) do |**inputs|
      GraphqlCrudOperations.load_if_can(
              type.to_s.camelize.constantize,
              inputs[:id],
              context
            )
    end
  end
end
