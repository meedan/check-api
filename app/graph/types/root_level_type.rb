RootLevelType = GraphQL::ObjectType.define do
  name 'RootLevel'
  description 'Unassociated root object queries'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('RootLevel')
  connection :comments, CommentType.connection_type do
    resolve ->(_object, _args, _ctx){
      Comment.all.to_a.sort{ |a, b| a.created_at <=> b.created_at }
    }
  end
  connection :project_sources, ProjectSourceType.connection_type do
    resolve ->(_object, _args, _ctx){
      ProjectSource.all
    }
  end
  connection :sources, SourceType.connection_type do
    resolve ->(_object, _args, _ctx){
      Source.all
    }
  end
  connection :team_users, TeamUserType.connection_type do
    resolve ->(_object, _args, _ctx){
      TeamUser.all
    }
  end
  connection :teams, TeamType.connection_type do
    resolve ->(_object, _args, _ctx){
      Team.all
    }
  end
  connection :accounts, AccountType.connection_type do
    resolve ->(_object, _args, _ctx){
      Account.all
    }
  end
  connection :medias, MediaType.connection_type do
    resolve ->(_object, _args, _ctx){
      Media.all
    }
  end
  connection :projects, ProjectType.connection_type do
    resolve ->(_object, _args, _ctx){
      Project.all
    }
  end
  connection :users, UserType.connection_type do
    resolve ->(_object, _args, _ctx){
      User.all
    }
  end
  connection :api_keys, ApiKeyType.connection_type do
    resolve ->(_object, _args, _ctx){
      ApiKey.all
    }
  end
end
