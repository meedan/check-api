RootLevelType = GraphQL::ObjectType.define do
  name 'RootLevel'
  description 'Unassociated root object queries'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('RootLevel')
  connection :comments, CommentType.connection_type do
    resolve ->(_object, _args, _ctx){
      Comment.all_sorted
    }
  end
  connection :project_sources, ProjectSourceType.connection_type do
    resolve ->(_object, _args, _ctx){
      ProjectSource.all
    }
  end
  connection :sources, SourceType.connection_type do
    resolve ->(_object, _args, _ctx){
      Source.order('created_at DESC').all
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
  connection :annotations, AnnotationType.connection_type do
    resolve ->(_object, _args, _ctx){
      Annotation.all_sorted
    }
  end
  connection :tags, TagType.connection_type do
    resolve ->(_object, _args, _ctx){
      Tag.all_sorted
    }
  end
  connection :statuses, StatusType.connection_type do
    resolve ->(_object, _args, _ctx){
      Status.all_sorted
    }
  end
end
