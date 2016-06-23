RootLevelType = GraphQL::ObjectType.define do
  name 'RootLevel'
  description 'Unassociated root object queries'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('RootLevel')
  connection :comments, CommentType.connection_type do
    resolve ->(object, args, ctx){
      Comment.all
    }
  end
  connection :project_sources, ProjectSourceType.connection_type do
    resolve ->(object, args, ctx){
      ProjectSource.all
    }
  end
  connection :sources, SourceType.connection_type do
    resolve ->(object, args, ctx){
      Source.all
    }
  end
  connection :team_users, TeamUserType.connection_type do
    resolve ->(object, args, ctx){
      TeamUser.all
    }
  end
  connection :teams, TeamType.connection_type do
    resolve ->(object, args, ctx){
      Team.all
    }
  end
  connection :accounts, AccountType.connection_type do
    resolve ->(object, args, ctx){
      Account.all
    }
  end
  connection :medias, MediaType.connection_type do
    resolve ->(object, args, ctx){
      Media.all
    }
  end
  connection :projects, ProjectType.connection_type do
    resolve ->(object, args, ctx){
      Project.all
    }
  end
  connection :users, UserType.connection_type do
    resolve ->(object, args, ctx){
      User.all
    }
  end
  connection :api_keys, ApiKeyType.connection_type do
    resolve ->(object, args, ctx){
      ApiKey.all
    }
  end
end
