RootLevelType = GraphQL::ObjectType.define do
  name 'RootLevel'
  description 'Unassociated root object queries'

  interfaces [NodeIdentification.interface]

  global_id_field :id
  connection :comments, CommentType.connection_type do
    resolve ->(_object, _args, _ctx){
      Comment.all_sorted
    }
  end
  connection :project_medias, ProjectMediaType.connection_type do
    resolve ->(_object, _args, _ctx){
      ProjectMedia.all
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
  connection :account_sources, AccountSourceType.connection_type do
    resolve ->(_object, _args, _ctx){
      AccountSource.all
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
  connection :contacts, ContactType.connection_type do
    resolve ->(_object, _args, _ctx){
      Contact.all
    }
  end
  connection :team_bots_approved, BotUserType.connection_type do
    resolve ->(_object, _args, _ctx){
      BotUser.all.select{ |b| b.get_approved }
    }
  end
end
