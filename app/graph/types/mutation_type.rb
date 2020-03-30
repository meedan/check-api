require File.join(Rails.root, 'app', 'graph', 'mutations', 'dynamic_annotation_types')

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

  # field :createAccount, field: AccountMutations::Create.field
  field :updateAccount, field: AccountMutations::Update.field
  # field :destroyAccount, field: AccountMutations::Destroy.field

  field :createAccountSource, field: AccountSourceMutations::Create.field
  field :updateAccountSource, field: AccountSourceMutations::Update.field
  field :destroyAccountSource, field: AccountSourceMutations::Destroy.field

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

  field :createAnnotation, field: AnnotationMutations::Create.field
  # field :updateAnnotation, field: AnnotationMutations::Update.field
  field :destroyAnnotation, field: AnnotationMutations::Destroy.field

  field :destroyVersion, field: VersionMutations::Destroy.field

  field :createContact, field: ContactMutations::Create.field
  field :updateContact, field: ContactMutations::Update.field
  field :destroyContact, field: ContactMutations::Destroy.field

  field :createDynamic, field: DynamicMutations::Create.field
  field :updateDynamic, field: DynamicMutations::Update.field
  field :destroyDynamic, field: DynamicMutations::Destroy.field

  field :createTask, field: TaskMutations::Create.field
  field :updateTask, field: TaskMutations::Update.field
  field :destroyTask, field: TaskMutations::Destroy.field

  field :resetPassword, field: ResetPasswordMutation.field
  field :changePassword, field: ChangePasswordMutation.field
  field :resendConfirmation, field: ResendConfirmationMutation.field
  field :userInvitation, field: UserInvitationMutation.field
  field :resendCancelInvitation, field: ResendCancelInvitationMutation.field
  field :deleteCheckUser, field: DeleteCheckUserMutation.field
  field :userDisconnectLoginAccount, field: UserDisconnectLoginAccountMutation.field
  field :userTwoFactorAuthentication, field: UserTwoFactorAuthenticationMutation.field
  field :generateTwoFactorBackupCodes, field: GenerateTwoFactorBackupCodesMutation.field

  field :createTeamBotInstallation, field: TeamBotInstallationMutations::Create.field
  field :updateTeamBotInstallation, field: TeamBotInstallationMutations::Update.field
  field :destroyTeamBotInstallation, field: TeamBotInstallationMutations::Destroy.field

  field :smoochBotAddSlackChannelUrl, field: SmoochBotAddSlackChannelUrlMutation.field

  field :createTagText, field: TagTextMutations::Create.field
  field :updateTagText, field: TagTextMutations::Update.field
  field :destroyTagText, field: TagTextMutations::Destroy.field

  field :createTeamTask, field: TeamTaskMutations::Create.field
  field :updateTeamTask, field: TeamTaskMutations::Update.field
  field :destroyTeamTask, field: TeamTaskMutations::Destroy.field

  field :createRelationship, field: RelationshipMutations::Create.field
  field :updateRelationship, field: RelationshipMutations::Update.field
  field :destroyRelationship, field: RelationshipMutations::Destroy.field

  DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
    klass = type.camelize
    field "createDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Create".constantize.field
    field "updateDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Update".constantize.field
    field "destroyDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Destroy".constantize.field
  end

  field :importSpreadsheet, field: ImportSpreadsheetMutation.field

  field :createProjectMediaProject, field: ProjectMediaProjectMutations::Create.field
  field :destroyProjectMediaProject, field: ProjectMediaProjectMutations::Destroy.field
end
