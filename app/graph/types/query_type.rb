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
      OpenStruct.new({ name: Rails.application.class.parent_name, version: VERSION, id: 1, type: 'About', tos: CONFIG['terms_of_service'], privacy_policy: CONFIG['privacy_policy'] })
    end
  end

  field :me do
    type UserType
    description 'Information about the current user'
    resolve -> (_obj, _args, ctx) do
      ctx[:current_user]
    end
  end

  # Get team by id or subdomain

  field :team do
    type TeamType
    description 'Information about the context team or the team from given id'
    argument :id, types.ID
    resolve -> (_obj, args, ctx) do
      tid = args['id'].to_i
      if tid === 0 && !ctx[:context_team].blank?
        tid = ctx[:context_team].id
      end
      GraphqlCrudOperations.load_if_can(Team, tid, ctx)
    end
  end

  # Get public team
  
  field :public_team do
    type PublicTeamType
    description 'Public information about the current team'
    
    resolve -> (_obj, _args, ctx) do
      id = ctx[:context_team].blank? ? 0 : ctx[:context_team].id
      Team.find(id)
    end
  end

  field :project do
    type ProjectType
    description 'Information about a project, given its id and its team id'

    argument :id, !types.ID

    resolve -> (_obj, args, ctx) do
      tid = ctx[:context_team].blank? ? 0 : ctx[:context_team].id
      project = Project.where(id: args['id'], team_id: tid).last
      id = project.nil? ? 0 : project.id
      GraphqlCrudOperations.load_if_can(Project, id, ctx)
    end
  end

  field :media do
    type MediaType
    description 'Information about a media item. The argument should be given like this: "media_id,project_id"'

    argument :ids, !types.String

    resolve -> (_obj, args, ctx) do
      mid, pid = args['ids'].split(',').map(&:to_i)
      tid = ctx[:context_team].blank? ? 0 : ctx[:context_team].id
      project = Project.where(id: pid, team_id: tid).last
      pid = project.nil? ? 0 : project.id
      project_media = ProjectMedia.where(project_id: pid, media_id: mid).last
      mid = project_media.nil? ? 0 : project_media.media_id
      media = GraphqlCrudOperations.load_if_can(Media, mid, ctx)
      media.project_id = pid if media
      media
    end
  end

  field :search do
    type CheckSearchType
    description 'Search medias, The argument should be given like this: "{\"keyword\":\"search keyword\"}"'

    argument :query, !types.String

    resolve -> (_obj, args, ctx) do
      CheckSearch.new(args['query'], ctx[:context_team])
    end
  end

  # Getters by ID

  [:source, :user].each do |type|
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
