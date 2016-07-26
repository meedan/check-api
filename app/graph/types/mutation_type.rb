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

  field :createMedia, field: MediaMutations::Create.field
  field :updateMedia, field: MediaMutations::Update.field
  field :destroyMedia, field: MediaMutations::Destroy.field

  field :createProject, field: ProjectMutations::Create.field
  field :updateProject, field: ProjectMutations::Update.field
  field :destroyProject, field: ProjectMutations::Destroy.field

  field :createUser, field: UserMutations::Create.field
  field :updateUser, field: UserMutations::Update.field
  field :destroyUser, field: UserMutations::Destroy.field

  field :createApiKey, field: ApiKeyMutations::Create.field
  field :updateApiKey, field: ApiKeyMutations::Update.field
  field :destroyApiKey, field: ApiKeyMutations::Destroy.field

  field :createTag, field: TagMutations::Create.field
  field :updateTag, field: TagMutations::Update.field
  field :destroyTag, field: TagMutations::Destroy.field

  field :createStatus, field: StatusMutations::Create.field
  field :updateStatus, field: StatusMutations::Update.field
  field :destroyStatus, field: StatusMutations::Destroy.field
end
