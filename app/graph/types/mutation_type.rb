require File.join(Rails.root,"app","graph","mutations","dynamic_annotation_types")

class MutationType < BaseObject
  graphql_name "MutationType"

  # Override snakecase by default in BaseObject, so that mutations are in camelcase
  field_class GraphQL::Schema::Field

  field :create_comment, mutation: CommentMutations::Create
  field :update_comment, mutation: CommentMutations::Update
  field :destroy_comment, mutation: CommentMutations::Destroy

  field :create_source, mutation: SourceMutations::Create
  field :update_source, mutation: SourceMutations::Update
  field :destroy_source, mutation: SourceMutations::Destroy

  field :create_team_user, mutation: TeamUserMutations::Create
  field :update_team_user, mutation: TeamUserMutations::Update
  field :destroy_team_user, mutation: TeamUserMutations::Destroy

  field :create_team, mutation: TeamMutations::Create
  field :update_team, mutation: TeamMutations::Update
  field :destroy_team, mutation: TeamMutations::Destroy

  field :delete_team_status, mutation: DeleteTeamStatusMutation
  field :duplicate_team, mutation: DuplicateTeamMutation

  field :update_account, mutation: AccountMutations::Update

  field :create_account_source, mutation: AccountSourceMutations::Create
  field :update_account_source, mutation: AccountSourceMutations::Update
  field :destroy_account_source, mutation: AccountSourceMutations::Destroy

  field :create_project, mutation: ProjectMutations::Create
  field :update_project, mutation: ProjectMutations::Update
  field :destroy_project, mutation: ProjectMutations::Destroy

  field :create_project_media, mutation: ProjectMediaMutations::Create
  field :update_project_media, mutation: ProjectMediaMutations::Update
  field :update_project_medias, mutation: ProjectMediaMutations::BulkUpdate
  field :destroy_project_media, mutation: ProjectMediaMutations::Destroy
  field :replace_project_media, mutation: ProjectMediaMutations::Replace

  field :create_user, mutation: UserMutations::Create
  field :update_user, mutation: UserMutations::Update
  field :destroy_user, mutation: UserMutations::Destroy

  field :create_tag, mutation: TagMutations::Create
  field :update_tag, mutation: TagMutations::Update
  field :destroy_tag, mutation: TagMutations::Destroy
  field :create_tags, mutation: TagMutations::BulkCreate

  field :create_annotation, mutation: AnnotationMutations::Create
  field :destroy_annotation, mutation: AnnotationMutations::Destroy
  field :extract_text, mutation: OcrMutations::ExtractText
  field :transcribe_audio, mutation: TranscriptionMutations::TranscribeAudio

  field :destroy_version, mutation: VersionMutations::Destroy

  field :create_dynamic, mutation: DynamicMutations::Create
  field :update_dynamic, mutation: DynamicMutations::Update
  field :destroy_dynamic, mutation: DynamicMutations::Destroy

  field :create_task, mutation: TaskMutations::Create
  field :update_task, mutation: TaskMutations::Update
  field :destroy_task, mutation: TaskMutations::Destroy
  field :move_task_up, mutation: TasksOrderMutations::MoveTaskUp
  field :move_task_down, mutation: TasksOrderMutations::MoveTaskDown
#   field :add_files_to_task, field: TasksFileMutations::AddFilesToTask.field
#   field :remove_files_from_task,
#         field: TasksFileMutations::RemoveFilesFromTask.field

#   field :reset_password, field: ResetPasswordMutation.field
#   field :change_password, field: ChangePasswordMutation.field
#   field :resend_confirmation, field: ResendConfirmationMutation.field
#   field :user_invitation, field: UserInvitationMutation.field
#   field :resend_cancel_invitation, field: ResendCancelInvitationMutation.field
#   field :delete_check_user, field: DeleteCheckUserMutation.field
#   field :user_disconnect_login_account,
#         field: UserDisconnectLoginAccountMutation.field
#   field :user_two_factor_authentication,
#         field: UserTwoFactorAuthenticationMutation.field
#   field :generate_two_factor_backup_codes,
#         field: GenerateTwoFactorBackupCodesMutation.field

  field :create_team_bot_installation, mutation: TeamBotInstallationMutations::Create
  field :update_team_bot_installation, mutation: TeamBotInstallationMutations::Update
  field :destroy_team_bot_installation, mutation: TeamBotInstallationMutations::Destroy

#   field :smooch_bot_add_slack_channel_url,
#         field: SmoochBotMutations::AddSlackChannelUrl.field
#   field :smooch_bot_add_integration,
#         field: SmoochBotMutations::AddIntegration.field
#   field :smooch_bot_remove_integration,
#         field: SmoochBotMutations::RemoveIntegration.field

  field :create_tag_text, mutation: TagTextMutations::Create
  field :update_tag_text, mutation: TagTextMutations::Update
  field :destroy_tag_text, mutation: TagTextMutations::Destroy

  field :create_team_task, mutation: TeamTaskMutations::Create
  field :update_team_task, mutation: TeamTaskMutations::Update
  field :destroy_team_task, mutation: TeamTaskMutations::Destroy
  field :move_team_task_up, mutation: TasksOrderMutations::MoveTeamTaskUp
  field :move_team_task_down, mutation: TasksOrderMutations::MoveTeamTaskDown

#   field :create_relationship, field: RelationshipMutations::Create.field
#   field :update_relationship, field: RelationshipMutations::Update.field
#   field :destroy_relationship, field: RelationshipMutations::Destroy.field
#   field :update_relationships, field: RelationshipMutations::BulkUpdate.field
#   field :destroy_relationships, field: RelationshipMutations::BulkDestroy.field

  DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
    DynamicAnnotation::AnnotationTypeManager.generate_mutation_classes_for_annotation_type(type)

    klass = type.camelize
    field "createDynamicAnnotation#{klass}".to_sym, mutation: "DynamicAnnotation#{klass}Mutations::Create".constantize
    field "updateDynamicAnnotation#{klass}".to_sym, mutation: "DynamicAnnotation#{klass}Mutations::Update".constantize
    field "destroyDynamicAnnotation#{klass}".to_sym, mutation: "DynamicAnnotation#{klass}Mutations::Destroy".constantize
  end

  field :create_project_media_user, mutation: ProjectMediaUserMutations::Create
  field :update_project_media_user, mutation: ProjectMediaUserMutations::Update
  field :destroy_project_media_user, mutation: ProjectMediaUserMutations::Destroy

  field :create_saved_search, mutation: SavedSearchMutations::Create
  field :update_saved_search, mutation: SavedSearchMutations::Update
  field :destroy_saved_search, mutation: SavedSearchMutations::Destroy

  field :create_project_group, mutation: ProjectGroupMutations::Create
  field :update_project_group, mutation: ProjectGroupMutations::Update
  field :destroy_project_group, mutation: ProjectGroupMutations::Destroy

#   field :search_upload, field: SearchUploadMutations::SearchUpload.field

  field :create_claim_description, mutation: ClaimDescriptionMutations::Create
  field :update_claim_description, mutation: ClaimDescriptionMutations::Update

  field :create_fact_check, mutation: FactCheckMutations::Create
  field :update_fact_check, mutation: FactCheckMutations::Update
  field :destroy_fact_check, mutation: FactCheckMutations::Destroy

#   field :update_feed_team, field: FeedTeamMutations::Update.field

#   field :create_tipline_newsletter,
#         field: TiplineNewsletterMutations::Create.field
#   field :update_tipline_newsletter,
#         field: TiplineNewsletterMutations::Update.field
end
