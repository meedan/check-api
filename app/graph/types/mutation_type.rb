require File.join(Rails.root,"app","graph","mutations","dynamic_annotation_types")

class MutationType < BaseObject
  # Override snakecase by default in BaseObject, so that mutations are in camelcase
  field_class GraphQL::Schema::Field

  graphql_name "MutationType"

  field :createSource, mutation: SourceMutations::Create
  field :updateSource, mutation: SourceMutations::Update

  field :updateTeamUser, mutation: TeamUserMutations::Update
  field :destroyTeamUser, mutation: TeamUserMutations::Destroy

  field :createTeam, mutation: TeamMutations::Create
  field :updateTeam, mutation: TeamMutations::Update
  field :destroyTeam, mutation: TeamMutations::Destroy

  field :deleteTeamStatus, mutation: DeleteTeamStatusMutation

  field :duplicateTeam, mutation: DuplicateTeamMutation

  field :updateAccount, mutation: AccountMutations::Update

  field :createAccountSource, mutation: AccountSourceMutations::Create
  field :destroyAccountSource, mutation: AccountSourceMutations::Destroy

  field :createProjectMedia, mutation: ProjectMediaMutations::Create, deprecation_reason: "If you're creating an item of type 'blank' with an attached fact-check, please use the createFactCheck mutation instead. This mutation will not support that case in the near future."
  field :updateProjectMedia, mutation: ProjectMediaMutations::Update
  field :updateProjectMedias, mutation: ProjectMediaMutations::Bulk::Update
  field :replaceProjectMedia, mutation: ProjectMediaMutations::Replace
  field :bulkProjectMediaMarkRead, mutation: ProjectMediaMutations::Bulk::MarkRead

  field :updateUser, mutation: UserMutations::Update

  field :createTag, mutation: TagMutations::Create
  field :updateTag, mutation: TagMutations::Update
  field :destroyTag, mutation: TagMutations::Destroy
  field :createTags, mutation: TagMutations::Bulk::Create

  field :destroyAnnotation, mutation: AnnotationMutations::Destroy

  field :extractText, mutation: OcrMutations::ExtractText

  field :transcribeAudio, mutation: TranscriptionMutations::TranscribeAudio

  field :destroyVersion, mutation: VersionMutations::Destroy

  field :createDynamic, mutation: DynamicMutations::Create
  field :updateDynamic, mutation: DynamicMutations::Update
  field :destroyDynamic, mutation: DynamicMutations::Destroy

  field :updateTask, mutation: TaskMutations::Update

  field :resetPassword, mutation: ResetPasswordMutation
  field :changePassword, mutation: ChangePasswordMutation
  field :resendConfirmation, mutation: ResendConfirmationMutation
  field :userInvitation, mutation: UserInvitationMutation
  field :resendCancelInvitation, mutation: ResendCancelInvitationMutation
  field :deleteCheckUser, mutation: DeleteCheckUserMutation
  field :userDisconnectLoginAccount, mutation: UserDisconnectLoginAccountMutation
  field :userTwoFactorAuthentication, mutation: UserTwoFactorAuthenticationMutation
  field :generateTwoFactorBackupCodes, mutation: GenerateTwoFactorBackupCodesMutation

  field :createTeamBotInstallation, mutation: TeamBotInstallationMutations::Create
  field :updateTeamBotInstallation, mutation: TeamBotInstallationMutations::Update
  field :destroyTeamBotInstallation, mutation: TeamBotInstallationMutations::Destroy

  field :smoochBotAddSlackChannelUrl, mutation: SmoochBotMutations::AddSlackChannelUrl
  field :smoochBotAddIntegration, mutation: SmoochBotMutations::AddIntegration
  field :smoochBotRemoveIntegration, mutation: SmoochBotMutations::RemoveIntegration

  field :createTagText, mutation: TagTextMutations::Create
  field :updateTagText, mutation: TagTextMutations::Update
  field :destroyTagText, mutation: TagTextMutations::Destroy

  field :createTeamTask, mutation: TeamTaskMutations::Create
  field :updateTeamTask, mutation: TeamTaskMutations::Update
  field :destroyTeamTask, mutation: TeamTaskMutations::Destroy
  field :moveTeamTaskUp, mutation: TasksOrderMutations::MoveTeamTaskUp
  field :moveTeamTaskDown, mutation: TasksOrderMutations::MoveTeamTaskDown

  field :createRelationship, mutation: RelationshipMutations::Create
  field :updateRelationship, mutation: RelationshipMutations::Update
  field :destroyRelationship, mutation: RelationshipMutations::Destroy
  field :updateRelationships, mutation: RelationshipMutations::Bulk::Update
  field :destroyRelationships, mutation: RelationshipMutations::Bulk::Destroy

  DynamicAnnotation::AnnotationType.pluck(:annotation_type).each do |type|
    DynamicAnnotation::AnnotationTypeManager.generate_mutation_classes_for_annotation_type(type)

    klass = type.camelize
    field "createDynamicAnnotation#{klass}".to_sym, mutation: "DynamicAnnotation#{klass}Mutations::Create".constantize
    field "updateDynamicAnnotation#{klass}".to_sym, mutation: "DynamicAnnotation#{klass}Mutations::Update".constantize
    field "destroyDynamicAnnotation#{klass}".to_sym, mutation: "DynamicAnnotation#{klass}Mutations::Destroy".constantize
  end

  field :createProjectMediaUser, mutation: ProjectMediaUserMutations::Create

  field :createSavedSearch, mutation: SavedSearchMutations::Create
  field :updateSavedSearch, mutation: SavedSearchMutations::Update
  field :destroySavedSearch, mutation: SavedSearchMutations::Destroy

  field :searchUpload, mutation: SearchUploadMutations::SearchUpload

  field :createClaimDescription, mutation: ClaimDescriptionMutations::Create
  field :updateClaimDescription, mutation: ClaimDescriptionMutations::Update

  field :createFactCheck, mutation: FactCheckMutations::Create
  field :updateFactCheck, mutation: FactCheckMutations::Update
  field :destroyFactCheck, mutation: FactCheckMutations::Destroy


  field :createFeed, mutation: FeedMutations::Create
  field :updateFeed, mutation: FeedMutations::Update
  field :destroyFeed, mutation: FeedMutations::Destroy
  field :feedImportMedia, mutation: FeedMutations::ImportMedia

  field :updateFeedTeam, mutation: FeedTeamMutations::Update
  field :destroyFeedTeam, mutation: FeedTeamMutations::Destroy

  field :createFeedInvitation, mutation: FeedInvitationMutations::Create
  field :destroyFeedInvitation, mutation: FeedInvitationMutations::Destroy
  field :acceptFeedInvitation, mutation: FeedInvitationMutations::Accept
  field :rejectFeedInvitation, mutation: FeedInvitationMutations::Reject

  field :createTiplineNewsletter, mutation: TiplineNewsletterMutations::Create
  field :updateTiplineNewsletter, mutation: TiplineNewsletterMutations::Update

  field :createTiplineResource, mutation: TiplineResourceMutations::Create
  field :updateTiplineResource, mutation: TiplineResourceMutations::Update
  field :destroyTiplineResource, mutation: TiplineResourceMutations::Destroy

  field :sendTiplineMessage, mutation: TiplineMessageMutations::Send

  field :addNluKeywordToTiplineMenu, mutation: NluMutations::AddKeywordToTiplineMenu
  field :removeNluKeywordFromTiplineMenu, mutation: NluMutations::RemoveKeywordFromTiplineMenu

  field :createExplainer, mutation: ExplainerMutations::Create
  field :updateExplainer, mutation: ExplainerMutations::Update
  field :destroyExplainer, mutation: ExplainerMutations::Destroy

  field :createApiKey, mutation: ApiKeyMutations::Create
  field :destroyApiKey, mutation: ApiKeyMutations::Destroy

  field :createExplainerItem, mutation: ExplainerItemMutations::Create
  field :destroyExplainerItem, mutation: ExplainerItemMutations::Destroy
  field :sendExplainersToPreviousRequests, mutation: ExplainerItemMutations::SendExplainersToPreviousRequests

  field :exportList, mutation: ExportMutations::ExportList

  field :destroyWebhook, mutation: WebhookMutations::Destroy
  field :createWebhook, mutation: WebhookMutations::Create
  field :updateWebhook, mutation: WebhookMutations::Update
end
