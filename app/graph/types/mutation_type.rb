require File.join(
          Rails.root,
          "app",
          "graph",
          "mutations",
          "dynamic_annotation_types"
        )

class MutationType < BaseObject
  graphql_name "MutationType"

  field :create_comment, mutation: CommentMutations::Create
  field :update_comment, mutation: CommentMutations::Update
  field :destroy_comment, mutation: CommentMutations::Destroy

  field :create_source, mutation: SourceMutations::Create
  field :update_source, mutation: SourceMutations::Update
  field :destroy_source, mutation: SourceMutations::Destroy

#   field :create_team_user, field: TeamUserMutations::Create.field
#   field :update_team_user, field: TeamUserMutations::Update.field
#   field :destroy_team_user, field: TeamUserMutations::Destroy.field

#   field :create_team, field: TeamMutations::Create.field
#   field :update_team, field: TeamMutations::Update.field
#   field :destroy_team, field: TeamMutations::Destroy.field
#   field :delete_team_status, field: DeleteTeamStatusMutation.field
#   field :duplicate_team, field: DuplicateTeamMutation.field

#   field :update_account, field: AccountMutations::Update.field

#   field :create_account_source, field: AccountSourceMutations::Create.field
#   field :update_account_source, field: AccountSourceMutations::Update.field
#   field :destroy_account_source, field: AccountSourceMutations::Destroy.field

#   field :create_project, field: ProjectMutations::Create.field
#   field :update_project, field: ProjectMutations::Update.field
#   field :destroy_project, field: ProjectMutations::Destroy.field

#   field :create_project_media, field: ProjectMediaMutations::Create.field
#   field :update_project_media, field: ProjectMediaMutations::Update.field
#   field :update_project_medias, field: ProjectMediaMutations::BulkUpdate.field
#   field :destroy_project_media, field: ProjectMediaMutations::Destroy.field
#   field :replace_project_media, field: ProjectMediaMutations::Replace.field

#   field :create_user, field: UserMutations::Create.field
#   field :update_user, field: UserMutations::Update.field
#   field :destroy_user, field: UserMutations::Destroy.field

#   field :create_tag, field: TagMutations::Create.field
#   field :update_tag, field: TagMutations::Update.field
#   field :destroy_tag, field: TagMutations::Destroy.field
#   field :create_tags, field: TagMutations::BulkCreate.field

#   field :create_annotation, field: AnnotationMutations::Create.field
#   field :destroy_annotation, field: AnnotationMutations::Destroy.field
#   field :extract_text, field: OcrMutations::ExtractText.field
#   field :transcribe_audio, field: TranscriptionMutations::TranscribeAudio.field

#   field :destroy_version, field: VersionMutations::Destroy.field

#   field :create_dynamic, field: DynamicMutations::Create.field
#   field :update_dynamic, field: DynamicMutations::Update.field
#   field :destroy_dynamic, field: DynamicMutations::Destroy.field

#   field :create_task, field: TaskMutations::Create.field
#   field :update_task, field: TaskMutations::Update.field
#   field :destroy_task, field: TaskMutations::Destroy.field
#   field :move_task_up, field: TasksOrderMutations::MoveTaskUp.field
#   field :move_task_down, field: TasksOrderMutations::MoveTaskDown.field
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

#   field :create_team_bot_installation,
#         field: TeamBotInstallationMutations::Create.field
#   field :update_team_bot_installation,
#         field: TeamBotInstallationMutations::Update.field
#   field :destroy_team_bot_installation,
#         field: TeamBotInstallationMutations::Destroy.field

#   field :smooch_bot_add_slack_channel_url,
#         field: SmoochBotMutations::AddSlackChannelUrl.field
#   field :smooch_bot_add_integration,
#         field: SmoochBotMutations::AddIntegration.field
#   field :smooch_bot_remove_integration,
#         field: SmoochBotMutations::RemoveIntegration.field

#   field :create_tag_text, field: TagTextMutations::Create.field
#   field :update_tag_text, field: TagTextMutations::Update.field
#   field :destroy_tag_text, field: TagTextMutations::Destroy.field

#   field :create_team_task, field: TeamTaskMutations::Create.field
#   field :update_team_task, field: TeamTaskMutations::Update.field
#   field :destroy_team_task, field: TeamTaskMutations::Destroy.field
#   field :move_team_task_up, field: TasksOrderMutations::MoveTeamTaskUp.field
#   field :move_team_task_down, field: TasksOrderMutations::MoveTeamTaskDown.field

#   field :create_relationship, field: RelationshipMutations::Create.field
#   field :update_relationship, field: RelationshipMutations::Update.field
#   field :destroy_relationship, field: RelationshipMutations::Destroy.field
#   field :update_relationships, field: RelationshipMutations::BulkUpdate.field
#   field :destroy_relationships, field: RelationshipMutations::BulkDestroy.field

#   DynamicAnnotation::AnnotationType.select('annotation_type').map(&:annotation_type).each do |type|
#     DynamicAnnotation::AnnotationTypeManager.define_type(type)

#     klass = type.camelize
#     field "createDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Create".constantize.field
#     field "updateDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Update".constantize.field
#     field "destroyDynamicAnnotation#{klass}".to_sym, field: "DynamicAnnotation#{klass}Mutations::Destroy".constantize.field
#   end

#   field :create_project_media_user,
#         field: ProjectMediaUserMutations::Create.field
#   field :update_project_media_user,
#         field: ProjectMediaUserMutations::Update.field
#   field :destroy_project_media_user,
#         field: ProjectMediaUserMutations::Destroy.field

#   field :create_saved_search, field: SavedSearchMutations::Create.field
#   field :update_saved_search, field: SavedSearchMutations::Update.field
#   field :destroy_saved_search, field: SavedSearchMutations::Destroy.field

#   field :create_project_group, field: ProjectGroupMutations::Create.field
#   field :update_project_group, field: ProjectGroupMutations::Update.field
#   field :destroy_project_group, field: ProjectGroupMutations::Destroy.field

#   field :search_upload, field: SearchUploadMutations::SearchUpload.field

#   field :create_claim_description,
#         field: ClaimDescriptionMutations::Create.field
#   field :update_claim_description,
#         field: ClaimDescriptionMutations::Update.field

#   field :create_fact_check, field: FactCheckMutations::Create.field
#   field :update_fact_check, field: FactCheckMutations::Update.field
#   field :destroy_fact_check, field: FactCheckMutations::Destroy.field

#   field :update_feed_team, field: FeedTeamMutations::Update.field

#   field :create_tipline_newsletter,
#         field: TiplineNewsletterMutations::Create.field
#   field :update_tipline_newsletter,
#         field: TiplineNewsletterMutations::Update.field
end
