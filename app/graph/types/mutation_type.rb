require File.join(Rails.root, 'app', 'graph', 'mutations', 'dynamic_annotation_types')

MutationType = GraphQL::ObjectType.define do
  name 'MutationType'
  field :createComment, field: CommentMutations::Create.field
  field :updateComment, field: CommentMutations::Update.field
  field :destroyComment, field: CommentMutations::Destroy.field

  field :createSource, field: SourceMutations::Create.field
  field :updateSource, field: SourceMutations::Update.field
  field :destroySource, field: SourceMutations::Destroy.field

  field :createTeamUser, field: TeamUserMutations::Create.field
  field :updateTeamUser, field: TeamUserMutations::Update.field
  field :destroyTeamUser, field: TeamUserMutations::Destroy.field

  field :createTeam, field: TeamMutations::Create.field
  field :updateTeam, field: TeamMutations::Update.field
  field :destroyTeam, field: TeamMutations::Destroy.field
  field :deleteTeamStatus, field: DeleteTeamStatusMutation.field
  field :duplicateTeam, field: DuplicateTeamMutation.field

  field :updateAccount, field: AccountMutations::Update.field

  field :createAccountSource, field: AccountSourceMutations::Create.field
  field :updateAccountSource, field: AccountSourceMutations::Update.field
  field :destroyAccountSource, field: AccountSourceMutations::Destroy.field

  field :createProject, field: ProjectMutations::Create.field
  field :updateProject, field: ProjectMutations::Update.field
  field :destroyProject, field: ProjectMutations::Destroy.field

  field :createProjectMedia, field: ProjectMediaMutations::Create.field
  field :updateProjectMedia, field: ProjectMediaMutations::Update.field
  field :updateProjectMedias, field: ProjectMediaMutations::BulkUpdate.field
  field :destroyProjectMedia, field: ProjectMediaMutations::Destroy.field
  field :replaceProjectMedia, field: ProjectMediaMutations::Replace.field

  field :createUser, field: UserMutations::Create.field
  field :updateUser, field: UserMutations::Update.field
  field :destroyUser, field: UserMutations::Destroy.field

  field :createTag, field: TagMutations::Create.field
  field :updateTag, field: TagMutations::Update.field
  field :destroyTag, field: TagMutations::Destroy.field
  field :createTags, field: TagMutations::BulkCreate.field

  field :createAnnotation, field: AnnotationMutations::Create.field
  field :destroyAnnotation, field: AnnotationMutations::Destroy.field
  field :extractText, field: OcrMutations::ExtractText.field

  field :destroyVersion, field: VersionMutations::Destroy.field

  field :createDynamic, field: DynamicMutations::Create.field
  field :updateDynamic, field: DynamicMutations::Update.field
  field :destroyDynamic, field: DynamicMutations::Destroy.field

  field :createTask, field: TaskMutations::Create.field
  field :updateTask, field: TaskMutations::Update.field
  field :destroyTask, field: TaskMutations::Destroy.field
  field :moveTaskUp, field: TasksOrderMutations::MoveTaskUp.field
  field :moveTaskDown, field: TasksOrderMutations::MoveTaskDown.field
  field :addFilesToTask, field: TasksFileMutations::AddFilesToTask.field
  field :removeFilesFromTask, field: TasksFileMutations::RemoveFilesFromTask.field

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

  field :smoochBotAddSlackChannelUrl, field: SmoochBotMutations::AddSlackChannelUrl.field
  field :smoochBotAddIntegration, field: SmoochBotMutations::AddIntegration.field
  field :smoochBotRemoveIntegration, field: SmoochBotMutations::RemoveIntegration.field

  field :createTagText, field: TagTextMutations::Create.field
  field :updateTagText, field: TagTextMutations::Update.field
  field :destroyTagText, field: TagTextMutations::Destroy.field

  field :createTeamTask, field: TeamTaskMutations::Create.field
  field :updateTeamTask, field: TeamTaskMutations::Update.field
  field :destroyTeamTask, field: TeamTaskMutations::Destroy.field
  field :moveTeamTaskUp, field: TasksOrderMutations::MoveTeamTaskUp.field
  field :moveTeamTaskDown, field: TasksOrderMutations::MoveTeamTaskDown.field

  field :createRelationship, field: RelationshipMutations::Create.field
  field :updateRelationship, field: RelationshipMutations::Update.field
  field :destroyRelationship, field: RelationshipMutations::Destroy.field

  DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
    klass = type.camelize
    field "createDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Create".constantize.field
    field "updateDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Update".constantize.field
    field "destroyDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Destroy".constantize.field
  end

  field :createProjectMediaUser, field: ProjectMediaUserMutations::Create.field
  field :updateProjectMediaUser, field: ProjectMediaUserMutations::Update.field
  field :destroyProjectMediaUser, field: ProjectMediaUserMutations::Destroy.field

  field :createSavedSearch, field: SavedSearchMutations::Create.field
  field :updateSavedSearch, field: SavedSearchMutations::Update.field
  field :destroySavedSearch, field: SavedSearchMutations::Destroy.field

  field :createProjectGroup, field: ProjectGroupMutations::Create.field
  field :updateProjectGroup, field: ProjectGroupMutations::Update.field
  field :destroyProjectGroup, field: ProjectGroupMutations::Destroy.field
end
