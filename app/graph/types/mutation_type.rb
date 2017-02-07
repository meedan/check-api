MutationType = GraphQL::ObjectType.define do
  name 'MutationType'
  field :createComment, field: CommentMutations::Create.field
  field :updateComment, field: CommentMutations::Update.field
  field :destroyComment, field: CommentMutations::Destroy.field

  field :createProjectSource, field: ProjectSourceMutations::Create.field
  field :updateProjectSource, field: ProjectSourceMutations::Update.field
  field :destroyProjectSource, field: ProjectSourceMutations::Destroy.field

  field :createSource, field: SourceMutations::Create.field
  field :updateSource, field: SourceMutations::Update.field
  field :destroySource, field: SourceMutations::Destroy.field

  field :createTeamUser, field: TeamUserMutations::Create.field
  field :updateTeamUser, field: TeamUserMutations::Update.field
  field :destroyTeamUser, field: TeamUserMutations::Destroy.field

  field :createTeam, field: TeamMutations::Create.field
  field :updateTeam, field: TeamMutations::Update.field
  field :destroyTeam, field: TeamMutations::Destroy.field

  field :createAccount, field: AccountMutations::Create.field
  field :updateAccount, field: AccountMutations::Update.field
  field :destroyAccount, field: AccountMutations::Destroy.field

  field :createProject, field: ProjectMutations::Create.field
  field :updateProject, field: ProjectMutations::Update.field
  field :destroyProject, field: ProjectMutations::Destroy.field

  field :createProjectMedia, field: ProjectMediaMutations::Create.field
  field :updateProjectMedia, field: ProjectMediaMutations::Update.field
  field :destroyProjectMedia, field: ProjectMediaMutations::Destroy.field

  field :createUser, field: UserMutations::Create.field
  field :updateUser, field: UserMutations::Update.field
  field :destroyUser, field: UserMutations::Destroy.field

  field :createTag, field: TagMutations::Create.field
  field :updateTag, field: TagMutations::Update.field
  field :destroyTag, field: TagMutations::Destroy.field

  field :createStatus, field: StatusMutations::Create.field
  field :updateStatus, field: StatusMutations::Update.field
  field :destroyStatus, field: StatusMutations::Destroy.field

  field :createFlag, field: FlagMutations::Create.field
  field :updateFlag, field: FlagMutations::Update.field
  field :destroyFlag, field: FlagMutations::Destroy.field

  # field :createAnnotation, field: AnnotationMutations::Create.field
  # field :updateAnnotation, field: AnnotationMutations::Update.field
  field :destroyAnnotation, field: AnnotationMutations::Destroy.field

  field :destroyVersion, field: VersionMutations::Destroy.field

  field :createContact, field: ContactMutations::Create.field
  field :updateContact, field: ContactMutations::Update.field
  field :destroyContact, field: ContactMutations::Destroy.field
end
