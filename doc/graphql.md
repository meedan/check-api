# Schema Types

<details>
  <summary><strong>Table of Contents</strong></summary>

  * [Query](#query)
  * [Mutation](#mutation)
  * [Objects](#objects)
    * [About](#about)
    * [Account](#account)
    * [AccountConnection](#accountconnection)
    * [AccountEdge](#accountedge)
    * [AccountSource](#accountsource)
    * [AccountSourceConnection](#accountsourceconnection)
    * [AccountSourceEdge](#accountsourceedge)
    * [Annotation](#annotation)
    * [AnnotationConnection](#annotationconnection)
    * [AnnotationEdge](#annotationedge)
    * [Annotator](#annotator)
    * [BotUser](#botuser)
    * [BotUserConnection](#botuserconnection)
    * [BotUserEdge](#botuseredge)
    * [ChangePasswordPayload](#changepasswordpayload)
    * [CheckSearch](#checksearch)
    * [Comment](#comment)
    * [CommentConnection](#commentconnection)
    * [CommentEdge](#commentedge)
    * [Contact](#contact)
    * [ContactConnection](#contactconnection)
    * [ContactEdge](#contactedge)
    * [CreateAccountSourcePayload](#createaccountsourcepayload)
    * [CreateAnnotationPayload](#createannotationpayload)
    * [CreateCommentPayload](#createcommentpayload)
    * [CreateContactPayload](#createcontactpayload)
    * [CreateDynamicAnnotationAnalysisPayload](#createdynamicannotationanalysispayload)
    * [CreateDynamicAnnotationArchiveIsPayload](#createdynamicannotationarchiveispayload)
    * [CreateDynamicAnnotationArchiveOrgPayload](#createdynamicannotationarchiveorgpayload)
    * [CreateDynamicAnnotationArchiverPayload](#createdynamicannotationarchiverpayload)
    * [CreateDynamicAnnotationEmbedCodePayload](#createdynamicannotationembedcodepayload)
    * [CreateDynamicAnnotationFlagPayload](#createdynamicannotationflagpayload)
    * [CreateDynamicAnnotationGeolocationPayload](#createdynamicannotationgeolocationpayload)
    * [CreateDynamicAnnotationKeepBackupPayload](#createdynamicannotationkeepbackuppayload)
    * [CreateDynamicAnnotationLanguagePayload](#createdynamicannotationlanguagepayload)
    * [CreateDynamicAnnotationMetadataPayload](#createdynamicannotationmetadatapayload)
    * [CreateDynamicAnnotationMetricsPayload](#createdynamicannotationmetricspayload)
    * [CreateDynamicAnnotationPenderArchivePayload](#createdynamicannotationpenderarchivepayload)
    * [CreateDynamicAnnotationReportDesignPayload](#createdynamicannotationreportdesignpayload)
    * [CreateDynamicAnnotationReverseImagePayload](#createdynamicannotationreverseimagepayload)
    * [CreateDynamicAnnotationSlackMessagePayload](#createdynamicannotationslackmessagepayload)
    * [CreateDynamicAnnotationSmoochPayload](#createdynamicannotationsmoochpayload)
    * [CreateDynamicAnnotationSmoochResponsePayload](#createdynamicannotationsmoochresponsepayload)
    * [CreateDynamicAnnotationSmoochUserPayload](#createdynamicannotationsmoochuserpayload)
    * [CreateDynamicAnnotationSyrianArchiveDataPayload](#createdynamicannotationsyrianarchivedatapayload)
    * [CreateDynamicAnnotationTaskResponseDatetimePayload](#createdynamicannotationtaskresponsedatetimepayload)
    * [CreateDynamicAnnotationTaskResponseFreeTextPayload](#createdynamicannotationtaskresponsefreetextpayload)
    * [CreateDynamicAnnotationTaskResponseGeolocationPayload](#createdynamicannotationtaskresponsegeolocationpayload)
    * [CreateDynamicAnnotationTaskResponseImageUploadPayload](#createdynamicannotationtaskresponseimageuploadpayload)
    * [CreateDynamicAnnotationTaskResponseMultipleChoicePayload](#createdynamicannotationtaskresponsemultiplechoicepayload)
    * [CreateDynamicAnnotationTaskResponseSingleChoicePayload](#createdynamicannotationtaskresponsesinglechoicepayload)
    * [CreateDynamicAnnotationTaskResponseYesNoPayload](#createdynamicannotationtaskresponseyesnopayload)
    * [CreateDynamicAnnotationTaskStatusPayload](#createdynamicannotationtaskstatuspayload)
    * [CreateDynamicAnnotationTattlePayload](#createdynamicannotationtattlepayload)
    * [CreateDynamicAnnotationTeamBotResponsePayload](#createdynamicannotationteambotresponsepayload)
    * [CreateDynamicAnnotationTranscriptPayload](#createdynamicannotationtranscriptpayload)
    * [CreateDynamicAnnotationVerificationStatusPayload](#createdynamicannotationverificationstatuspayload)
    * [CreateDynamicPayload](#createdynamicpayload)
    * [CreateProjectMediaPayload](#createprojectmediapayload)
    * [CreateProjectMediaProjectPayload](#createprojectmediaprojectpayload)
    * [CreateProjectPayload](#createprojectpayload)
    * [CreateProjectSourcePayload](#createprojectsourcepayload)
    * [CreateRelationshipPayload](#createrelationshippayload)
    * [CreateSourcePayload](#createsourcepayload)
    * [CreateTagPayload](#createtagpayload)
    * [CreateTagTextPayload](#createtagtextpayload)
    * [CreateTagsMutationPayload](#createtagsmutationpayload)
    * [CreateTaskPayload](#createtaskpayload)
    * [CreateTeamBotInstallationPayload](#createteambotinstallationpayload)
    * [CreateTeamPayload](#createteampayload)
    * [CreateTeamTaskPayload](#createteamtaskpayload)
    * [CreateTeamUserPayload](#createteamuserpayload)
    * [CreateUserPayload](#createuserpayload)
    * [DeleteCheckUserPayload](#deletecheckuserpayload)
    * [DestroyAccountSourcePayload](#destroyaccountsourcepayload)
    * [DestroyAnnotationPayload](#destroyannotationpayload)
    * [DestroyCommentPayload](#destroycommentpayload)
    * [DestroyContactPayload](#destroycontactpayload)
    * [DestroyDynamicAnnotationAnalysisPayload](#destroydynamicannotationanalysispayload)
    * [DestroyDynamicAnnotationArchiveIsPayload](#destroydynamicannotationarchiveispayload)
    * [DestroyDynamicAnnotationArchiveOrgPayload](#destroydynamicannotationarchiveorgpayload)
    * [DestroyDynamicAnnotationArchiverPayload](#destroydynamicannotationarchiverpayload)
    * [DestroyDynamicAnnotationEmbedCodePayload](#destroydynamicannotationembedcodepayload)
    * [DestroyDynamicAnnotationFlagPayload](#destroydynamicannotationflagpayload)
    * [DestroyDynamicAnnotationGeolocationPayload](#destroydynamicannotationgeolocationpayload)
    * [DestroyDynamicAnnotationKeepBackupPayload](#destroydynamicannotationkeepbackuppayload)
    * [DestroyDynamicAnnotationLanguagePayload](#destroydynamicannotationlanguagepayload)
    * [DestroyDynamicAnnotationMetadataPayload](#destroydynamicannotationmetadatapayload)
    * [DestroyDynamicAnnotationMetricsPayload](#destroydynamicannotationmetricspayload)
    * [DestroyDynamicAnnotationPenderArchivePayload](#destroydynamicannotationpenderarchivepayload)
    * [DestroyDynamicAnnotationReportDesignPayload](#destroydynamicannotationreportdesignpayload)
    * [DestroyDynamicAnnotationReverseImagePayload](#destroydynamicannotationreverseimagepayload)
    * [DestroyDynamicAnnotationSlackMessagePayload](#destroydynamicannotationslackmessagepayload)
    * [DestroyDynamicAnnotationSmoochPayload](#destroydynamicannotationsmoochpayload)
    * [DestroyDynamicAnnotationSmoochResponsePayload](#destroydynamicannotationsmoochresponsepayload)
    * [DestroyDynamicAnnotationSmoochUserPayload](#destroydynamicannotationsmoochuserpayload)
    * [DestroyDynamicAnnotationSyrianArchiveDataPayload](#destroydynamicannotationsyrianarchivedatapayload)
    * [DestroyDynamicAnnotationTaskResponseDatetimePayload](#destroydynamicannotationtaskresponsedatetimepayload)
    * [DestroyDynamicAnnotationTaskResponseFreeTextPayload](#destroydynamicannotationtaskresponsefreetextpayload)
    * [DestroyDynamicAnnotationTaskResponseGeolocationPayload](#destroydynamicannotationtaskresponsegeolocationpayload)
    * [DestroyDynamicAnnotationTaskResponseImageUploadPayload](#destroydynamicannotationtaskresponseimageuploadpayload)
    * [DestroyDynamicAnnotationTaskResponseMultipleChoicePayload](#destroydynamicannotationtaskresponsemultiplechoicepayload)
    * [DestroyDynamicAnnotationTaskResponseSingleChoicePayload](#destroydynamicannotationtaskresponsesinglechoicepayload)
    * [DestroyDynamicAnnotationTaskResponseYesNoPayload](#destroydynamicannotationtaskresponseyesnopayload)
    * [DestroyDynamicAnnotationTaskStatusPayload](#destroydynamicannotationtaskstatuspayload)
    * [DestroyDynamicAnnotationTattlePayload](#destroydynamicannotationtattlepayload)
    * [DestroyDynamicAnnotationTeamBotResponsePayload](#destroydynamicannotationteambotresponsepayload)
    * [DestroyDynamicAnnotationTranscriptPayload](#destroydynamicannotationtranscriptpayload)
    * [DestroyDynamicAnnotationVerificationStatusPayload](#destroydynamicannotationverificationstatuspayload)
    * [DestroyDynamicPayload](#destroydynamicpayload)
    * [DestroyProjectMediaPayload](#destroyprojectmediapayload)
    * [DestroyProjectMediaProjectPayload](#destroyprojectmediaprojectpayload)
    * [DestroyProjectPayload](#destroyprojectpayload)
    * [DestroyProjectSourcePayload](#destroyprojectsourcepayload)
    * [DestroyRelationshipPayload](#destroyrelationshippayload)
    * [DestroySourcePayload](#destroysourcepayload)
    * [DestroyTagPayload](#destroytagpayload)
    * [DestroyTagTextPayload](#destroytagtextpayload)
    * [DestroyTaskPayload](#destroytaskpayload)
    * [DestroyTeamBotInstallationPayload](#destroyteambotinstallationpayload)
    * [DestroyTeamPayload](#destroyteampayload)
    * [DestroyTeamTaskPayload](#destroyteamtaskpayload)
    * [DestroyTeamUserPayload](#destroyteamuserpayload)
    * [DestroyUserPayload](#destroyuserpayload)
    * [DestroyVersionPayload](#destroyversionpayload)
    * [Dynamic](#dynamic)
    * [DynamicAnnotationField](#dynamicannotationfield)
    * [DynamicConnection](#dynamicconnection)
    * [DynamicEdge](#dynamicedge)
    * [Dynamic_annotation_analysis](#dynamic_annotation_analysis)
    * [Dynamic_annotation_analysisEdge](#dynamic_annotation_analysisedge)
    * [Dynamic_annotation_archive_is](#dynamic_annotation_archive_is)
    * [Dynamic_annotation_archive_isEdge](#dynamic_annotation_archive_isedge)
    * [Dynamic_annotation_archive_org](#dynamic_annotation_archive_org)
    * [Dynamic_annotation_archive_orgEdge](#dynamic_annotation_archive_orgedge)
    * [Dynamic_annotation_archiver](#dynamic_annotation_archiver)
    * [Dynamic_annotation_archiverEdge](#dynamic_annotation_archiveredge)
    * [Dynamic_annotation_embed_code](#dynamic_annotation_embed_code)
    * [Dynamic_annotation_embed_codeEdge](#dynamic_annotation_embed_codeedge)
    * [Dynamic_annotation_flag](#dynamic_annotation_flag)
    * [Dynamic_annotation_flagEdge](#dynamic_annotation_flagedge)
    * [Dynamic_annotation_geolocation](#dynamic_annotation_geolocation)
    * [Dynamic_annotation_geolocationEdge](#dynamic_annotation_geolocationedge)
    * [Dynamic_annotation_keep_backup](#dynamic_annotation_keep_backup)
    * [Dynamic_annotation_keep_backupEdge](#dynamic_annotation_keep_backupedge)
    * [Dynamic_annotation_language](#dynamic_annotation_language)
    * [Dynamic_annotation_languageEdge](#dynamic_annotation_languageedge)
    * [Dynamic_annotation_metadata](#dynamic_annotation_metadata)
    * [Dynamic_annotation_metadataEdge](#dynamic_annotation_metadataedge)
    * [Dynamic_annotation_metrics](#dynamic_annotation_metrics)
    * [Dynamic_annotation_metricsEdge](#dynamic_annotation_metricsedge)
    * [Dynamic_annotation_pender_archive](#dynamic_annotation_pender_archive)
    * [Dynamic_annotation_pender_archiveEdge](#dynamic_annotation_pender_archiveedge)
    * [Dynamic_annotation_report_design](#dynamic_annotation_report_design)
    * [Dynamic_annotation_report_designEdge](#dynamic_annotation_report_designedge)
    * [Dynamic_annotation_reverse_image](#dynamic_annotation_reverse_image)
    * [Dynamic_annotation_reverse_imageEdge](#dynamic_annotation_reverse_imageedge)
    * [Dynamic_annotation_slack_message](#dynamic_annotation_slack_message)
    * [Dynamic_annotation_slack_messageEdge](#dynamic_annotation_slack_messageedge)
    * [Dynamic_annotation_smooch](#dynamic_annotation_smooch)
    * [Dynamic_annotation_smoochEdge](#dynamic_annotation_smoochedge)
    * [Dynamic_annotation_smooch_response](#dynamic_annotation_smooch_response)
    * [Dynamic_annotation_smooch_responseEdge](#dynamic_annotation_smooch_responseedge)
    * [Dynamic_annotation_smooch_user](#dynamic_annotation_smooch_user)
    * [Dynamic_annotation_smooch_userEdge](#dynamic_annotation_smooch_useredge)
    * [Dynamic_annotation_syrian_archive_data](#dynamic_annotation_syrian_archive_data)
    * [Dynamic_annotation_syrian_archive_dataEdge](#dynamic_annotation_syrian_archive_dataedge)
    * [Dynamic_annotation_task_response_datetime](#dynamic_annotation_task_response_datetime)
    * [Dynamic_annotation_task_response_datetimeEdge](#dynamic_annotation_task_response_datetimeedge)
    * [Dynamic_annotation_task_response_free_text](#dynamic_annotation_task_response_free_text)
    * [Dynamic_annotation_task_response_free_textEdge](#dynamic_annotation_task_response_free_textedge)
    * [Dynamic_annotation_task_response_geolocation](#dynamic_annotation_task_response_geolocation)
    * [Dynamic_annotation_task_response_geolocationEdge](#dynamic_annotation_task_response_geolocationedge)
    * [Dynamic_annotation_task_response_image_upload](#dynamic_annotation_task_response_image_upload)
    * [Dynamic_annotation_task_response_image_uploadEdge](#dynamic_annotation_task_response_image_uploadedge)
    * [Dynamic_annotation_task_response_multiple_choice](#dynamic_annotation_task_response_multiple_choice)
    * [Dynamic_annotation_task_response_multiple_choiceEdge](#dynamic_annotation_task_response_multiple_choiceedge)
    * [Dynamic_annotation_task_response_single_choice](#dynamic_annotation_task_response_single_choice)
    * [Dynamic_annotation_task_response_single_choiceEdge](#dynamic_annotation_task_response_single_choiceedge)
    * [Dynamic_annotation_task_response_yes_no](#dynamic_annotation_task_response_yes_no)
    * [Dynamic_annotation_task_response_yes_noEdge](#dynamic_annotation_task_response_yes_noedge)
    * [Dynamic_annotation_task_status](#dynamic_annotation_task_status)
    * [Dynamic_annotation_task_statusEdge](#dynamic_annotation_task_statusedge)
    * [Dynamic_annotation_tattle](#dynamic_annotation_tattle)
    * [Dynamic_annotation_tattleEdge](#dynamic_annotation_tattleedge)
    * [Dynamic_annotation_team_bot_response](#dynamic_annotation_team_bot_response)
    * [Dynamic_annotation_team_bot_responseEdge](#dynamic_annotation_team_bot_responseedge)
    * [Dynamic_annotation_transcript](#dynamic_annotation_transcript)
    * [Dynamic_annotation_transcriptEdge](#dynamic_annotation_transcriptedge)
    * [Dynamic_annotation_verification_status](#dynamic_annotation_verification_status)
    * [Dynamic_annotation_verification_statusEdge](#dynamic_annotation_verification_statusedge)
    * [GenerateTwoFactorBackupCodesPayload](#generatetwofactorbackupcodespayload)
    * [ImportSpreadsheetPayload](#importspreadsheetpayload)
    * [Media](#media)
    * [MediaConnection](#mediaconnection)
    * [MediaEdge](#mediaedge)
    * [PageInfo](#pageinfo)
    * [Project](#project)
    * [ProjectConnection](#projectconnection)
    * [ProjectEdge](#projectedge)
    * [ProjectMedia](#projectmedia)
    * [ProjectMediaConnection](#projectmediaconnection)
    * [ProjectMediaEdge](#projectmediaedge)
    * [ProjectMediaProject](#projectmediaproject)
    * [ProjectMediaProjectEdge](#projectmediaprojectedge)
    * [ProjectSource](#projectsource)
    * [ProjectSourceConnection](#projectsourceconnection)
    * [ProjectSourceEdge](#projectsourceedge)
    * [PublicTeam](#publicteam)
    * [Relationship](#relationship)
    * [RelationshipEdge](#relationshipedge)
    * [Relationships](#relationships)
    * [RelationshipsSource](#relationshipssource)
    * [RelationshipsSourceConnection](#relationshipssourceconnection)
    * [RelationshipsSourceEdge](#relationshipssourceedge)
    * [RelationshipsTarget](#relationshipstarget)
    * [RelationshipsTargetConnection](#relationshipstargetconnection)
    * [RelationshipsTargetEdge](#relationshipstargetedge)
    * [ResendCancelInvitationPayload](#resendcancelinvitationpayload)
    * [ResendConfirmationPayload](#resendconfirmationpayload)
    * [ResetPasswordPayload](#resetpasswordpayload)
    * [RootLevel](#rootlevel)
    * [SmoochBotAddSlackChannelUrlPayload](#smoochbotaddslackchannelurlpayload)
    * [Source](#source)
    * [SourceConnection](#sourceconnection)
    * [SourceEdge](#sourceedge)
    * [Tag](#tag)
    * [TagConnection](#tagconnection)
    * [TagEdge](#tagedge)
    * [TagText](#tagtext)
    * [TagTextConnection](#tagtextconnection)
    * [TagTextEdge](#tagtextedge)
    * [Task](#task)
    * [TaskConnection](#taskconnection)
    * [TaskEdge](#taskedge)
    * [Team](#team)
    * [TeamBotInstallation](#teambotinstallation)
    * [TeamBotInstallationConnection](#teambotinstallationconnection)
    * [TeamBotInstallationEdge](#teambotinstallationedge)
    * [TeamConnection](#teamconnection)
    * [TeamEdge](#teamedge)
    * [TeamTask](#teamtask)
    * [TeamTaskConnection](#teamtaskconnection)
    * [TeamTaskEdge](#teamtaskedge)
    * [TeamUser](#teamuser)
    * [TeamUserConnection](#teamuserconnection)
    * [TeamUserEdge](#teamuseredge)
    * [UpdateAccountPayload](#updateaccountpayload)
    * [UpdateAccountSourcePayload](#updateaccountsourcepayload)
    * [UpdateCommentPayload](#updatecommentpayload)
    * [UpdateContactPayload](#updatecontactpayload)
    * [UpdateDynamicAnnotationAnalysisPayload](#updatedynamicannotationanalysispayload)
    * [UpdateDynamicAnnotationArchiveIsPayload](#updatedynamicannotationarchiveispayload)
    * [UpdateDynamicAnnotationArchiveOrgPayload](#updatedynamicannotationarchiveorgpayload)
    * [UpdateDynamicAnnotationArchiverPayload](#updatedynamicannotationarchiverpayload)
    * [UpdateDynamicAnnotationEmbedCodePayload](#updatedynamicannotationembedcodepayload)
    * [UpdateDynamicAnnotationFlagPayload](#updatedynamicannotationflagpayload)
    * [UpdateDynamicAnnotationGeolocationPayload](#updatedynamicannotationgeolocationpayload)
    * [UpdateDynamicAnnotationKeepBackupPayload](#updatedynamicannotationkeepbackuppayload)
    * [UpdateDynamicAnnotationLanguagePayload](#updatedynamicannotationlanguagepayload)
    * [UpdateDynamicAnnotationMetadataPayload](#updatedynamicannotationmetadatapayload)
    * [UpdateDynamicAnnotationMetricsPayload](#updatedynamicannotationmetricspayload)
    * [UpdateDynamicAnnotationPenderArchivePayload](#updatedynamicannotationpenderarchivepayload)
    * [UpdateDynamicAnnotationReportDesignPayload](#updatedynamicannotationreportdesignpayload)
    * [UpdateDynamicAnnotationReverseImagePayload](#updatedynamicannotationreverseimagepayload)
    * [UpdateDynamicAnnotationSlackMessagePayload](#updatedynamicannotationslackmessagepayload)
    * [UpdateDynamicAnnotationSmoochPayload](#updatedynamicannotationsmoochpayload)
    * [UpdateDynamicAnnotationSmoochResponsePayload](#updatedynamicannotationsmoochresponsepayload)
    * [UpdateDynamicAnnotationSmoochUserPayload](#updatedynamicannotationsmoochuserpayload)
    * [UpdateDynamicAnnotationSyrianArchiveDataPayload](#updatedynamicannotationsyrianarchivedatapayload)
    * [UpdateDynamicAnnotationTaskResponseDatetimePayload](#updatedynamicannotationtaskresponsedatetimepayload)
    * [UpdateDynamicAnnotationTaskResponseFreeTextPayload](#updatedynamicannotationtaskresponsefreetextpayload)
    * [UpdateDynamicAnnotationTaskResponseGeolocationPayload](#updatedynamicannotationtaskresponsegeolocationpayload)
    * [UpdateDynamicAnnotationTaskResponseImageUploadPayload](#updatedynamicannotationtaskresponseimageuploadpayload)
    * [UpdateDynamicAnnotationTaskResponseMultipleChoicePayload](#updatedynamicannotationtaskresponsemultiplechoicepayload)
    * [UpdateDynamicAnnotationTaskResponseSingleChoicePayload](#updatedynamicannotationtaskresponsesinglechoicepayload)
    * [UpdateDynamicAnnotationTaskResponseYesNoPayload](#updatedynamicannotationtaskresponseyesnopayload)
    * [UpdateDynamicAnnotationTaskStatusPayload](#updatedynamicannotationtaskstatuspayload)
    * [UpdateDynamicAnnotationTattlePayload](#updatedynamicannotationtattlepayload)
    * [UpdateDynamicAnnotationTeamBotResponsePayload](#updatedynamicannotationteambotresponsepayload)
    * [UpdateDynamicAnnotationTranscriptPayload](#updatedynamicannotationtranscriptpayload)
    * [UpdateDynamicAnnotationVerificationStatusPayload](#updatedynamicannotationverificationstatuspayload)
    * [UpdateDynamicPayload](#updatedynamicpayload)
    * [UpdateProjectMediaPayload](#updateprojectmediapayload)
    * [UpdateProjectPayload](#updateprojectpayload)
    * [UpdateProjectSourcePayload](#updateprojectsourcepayload)
    * [UpdateRelationshipPayload](#updaterelationshippayload)
    * [UpdateSourcePayload](#updatesourcepayload)
    * [UpdateTagPayload](#updatetagpayload)
    * [UpdateTagTextPayload](#updatetagtextpayload)
    * [UpdateTaskPayload](#updatetaskpayload)
    * [UpdateTeamBotInstallationPayload](#updateteambotinstallationpayload)
    * [UpdateTeamPayload](#updateteampayload)
    * [UpdateTeamTaskPayload](#updateteamtaskpayload)
    * [UpdateTeamUserPayload](#updateteamuserpayload)
    * [UpdateUserPayload](#updateuserpayload)
    * [User](#user)
    * [UserConnection](#userconnection)
    * [UserDisconnectLoginAccountPayload](#userdisconnectloginaccountpayload)
    * [UserEdge](#useredge)
    * [UserInvitationPayload](#userinvitationpayload)
    * [UserTwoFactorAuthenticationPayload](#usertwofactorauthenticationpayload)
    * [Version](#version)
    * [VersionConnection](#versionconnection)
    * [VersionEdge](#versionedge)
  * [Inputs](#inputs)
    * [ChangePasswordInput](#changepasswordinput)
    * [CreateAccountSourceInput](#createaccountsourceinput)
    * [CreateAnnotationInput](#createannotationinput)
    * [CreateCommentInput](#createcommentinput)
    * [CreateContactInput](#createcontactinput)
    * [CreateDynamicAnnotationAnalysisInput](#createdynamicannotationanalysisinput)
    * [CreateDynamicAnnotationArchiveIsInput](#createdynamicannotationarchiveisinput)
    * [CreateDynamicAnnotationArchiveOrgInput](#createdynamicannotationarchiveorginput)
    * [CreateDynamicAnnotationArchiverInput](#createdynamicannotationarchiverinput)
    * [CreateDynamicAnnotationEmbedCodeInput](#createdynamicannotationembedcodeinput)
    * [CreateDynamicAnnotationFlagInput](#createdynamicannotationflaginput)
    * [CreateDynamicAnnotationGeolocationInput](#createdynamicannotationgeolocationinput)
    * [CreateDynamicAnnotationKeepBackupInput](#createdynamicannotationkeepbackupinput)
    * [CreateDynamicAnnotationLanguageInput](#createdynamicannotationlanguageinput)
    * [CreateDynamicAnnotationMetadataInput](#createdynamicannotationmetadatainput)
    * [CreateDynamicAnnotationMetricsInput](#createdynamicannotationmetricsinput)
    * [CreateDynamicAnnotationPenderArchiveInput](#createdynamicannotationpenderarchiveinput)
    * [CreateDynamicAnnotationReportDesignInput](#createdynamicannotationreportdesigninput)
    * [CreateDynamicAnnotationReverseImageInput](#createdynamicannotationreverseimageinput)
    * [CreateDynamicAnnotationSlackMessageInput](#createdynamicannotationslackmessageinput)
    * [CreateDynamicAnnotationSmoochInput](#createdynamicannotationsmoochinput)
    * [CreateDynamicAnnotationSmoochResponseInput](#createdynamicannotationsmoochresponseinput)
    * [CreateDynamicAnnotationSmoochUserInput](#createdynamicannotationsmoochuserinput)
    * [CreateDynamicAnnotationSyrianArchiveDataInput](#createdynamicannotationsyrianarchivedatainput)
    * [CreateDynamicAnnotationTaskResponseDatetimeInput](#createdynamicannotationtaskresponsedatetimeinput)
    * [CreateDynamicAnnotationTaskResponseFreeTextInput](#createdynamicannotationtaskresponsefreetextinput)
    * [CreateDynamicAnnotationTaskResponseGeolocationInput](#createdynamicannotationtaskresponsegeolocationinput)
    * [CreateDynamicAnnotationTaskResponseImageUploadInput](#createdynamicannotationtaskresponseimageuploadinput)
    * [CreateDynamicAnnotationTaskResponseMultipleChoiceInput](#createdynamicannotationtaskresponsemultiplechoiceinput)
    * [CreateDynamicAnnotationTaskResponseSingleChoiceInput](#createdynamicannotationtaskresponsesinglechoiceinput)
    * [CreateDynamicAnnotationTaskResponseYesNoInput](#createdynamicannotationtaskresponseyesnoinput)
    * [CreateDynamicAnnotationTaskStatusInput](#createdynamicannotationtaskstatusinput)
    * [CreateDynamicAnnotationTattleInput](#createdynamicannotationtattleinput)
    * [CreateDynamicAnnotationTeamBotResponseInput](#createdynamicannotationteambotresponseinput)
    * [CreateDynamicAnnotationTranscriptInput](#createdynamicannotationtranscriptinput)
    * [CreateDynamicAnnotationVerificationStatusInput](#createdynamicannotationverificationstatusinput)
    * [CreateDynamicInput](#createdynamicinput)
    * [CreateProjectInput](#createprojectinput)
    * [CreateProjectMediaInput](#createprojectmediainput)
    * [CreateProjectMediaProjectInput](#createprojectmediaprojectinput)
    * [CreateProjectSourceInput](#createprojectsourceinput)
    * [CreateRelationshipInput](#createrelationshipinput)
    * [CreateSourceInput](#createsourceinput)
    * [CreateTagInput](#createtaginput)
    * [CreateTagTextInput](#createtagtextinput)
    * [CreateTagsInput](#createtagsinput)
    * [CreateTaskInput](#createtaskinput)
    * [CreateTeamBotInstallationInput](#createteambotinstallationinput)
    * [CreateTeamInput](#createteaminput)
    * [CreateTeamTaskInput](#createteamtaskinput)
    * [CreateTeamUserInput](#createteamuserinput)
    * [CreateUserInput](#createuserinput)
    * [DeleteCheckUserInput](#deletecheckuserinput)
    * [DestroyAccountSourceInput](#destroyaccountsourceinput)
    * [DestroyAnnotationInput](#destroyannotationinput)
    * [DestroyCommentInput](#destroycommentinput)
    * [DestroyContactInput](#destroycontactinput)
    * [DestroyDynamicAnnotationAnalysisInput](#destroydynamicannotationanalysisinput)
    * [DestroyDynamicAnnotationArchiveIsInput](#destroydynamicannotationarchiveisinput)
    * [DestroyDynamicAnnotationArchiveOrgInput](#destroydynamicannotationarchiveorginput)
    * [DestroyDynamicAnnotationArchiverInput](#destroydynamicannotationarchiverinput)
    * [DestroyDynamicAnnotationEmbedCodeInput](#destroydynamicannotationembedcodeinput)
    * [DestroyDynamicAnnotationFlagInput](#destroydynamicannotationflaginput)
    * [DestroyDynamicAnnotationGeolocationInput](#destroydynamicannotationgeolocationinput)
    * [DestroyDynamicAnnotationKeepBackupInput](#destroydynamicannotationkeepbackupinput)
    * [DestroyDynamicAnnotationLanguageInput](#destroydynamicannotationlanguageinput)
    * [DestroyDynamicAnnotationMetadataInput](#destroydynamicannotationmetadatainput)
    * [DestroyDynamicAnnotationMetricsInput](#destroydynamicannotationmetricsinput)
    * [DestroyDynamicAnnotationPenderArchiveInput](#destroydynamicannotationpenderarchiveinput)
    * [DestroyDynamicAnnotationReportDesignInput](#destroydynamicannotationreportdesigninput)
    * [DestroyDynamicAnnotationReverseImageInput](#destroydynamicannotationreverseimageinput)
    * [DestroyDynamicAnnotationSlackMessageInput](#destroydynamicannotationslackmessageinput)
    * [DestroyDynamicAnnotationSmoochInput](#destroydynamicannotationsmoochinput)
    * [DestroyDynamicAnnotationSmoochResponseInput](#destroydynamicannotationsmoochresponseinput)
    * [DestroyDynamicAnnotationSmoochUserInput](#destroydynamicannotationsmoochuserinput)
    * [DestroyDynamicAnnotationSyrianArchiveDataInput](#destroydynamicannotationsyrianarchivedatainput)
    * [DestroyDynamicAnnotationTaskResponseDatetimeInput](#destroydynamicannotationtaskresponsedatetimeinput)
    * [DestroyDynamicAnnotationTaskResponseFreeTextInput](#destroydynamicannotationtaskresponsefreetextinput)
    * [DestroyDynamicAnnotationTaskResponseGeolocationInput](#destroydynamicannotationtaskresponsegeolocationinput)
    * [DestroyDynamicAnnotationTaskResponseImageUploadInput](#destroydynamicannotationtaskresponseimageuploadinput)
    * [DestroyDynamicAnnotationTaskResponseMultipleChoiceInput](#destroydynamicannotationtaskresponsemultiplechoiceinput)
    * [DestroyDynamicAnnotationTaskResponseSingleChoiceInput](#destroydynamicannotationtaskresponsesinglechoiceinput)
    * [DestroyDynamicAnnotationTaskResponseYesNoInput](#destroydynamicannotationtaskresponseyesnoinput)
    * [DestroyDynamicAnnotationTaskStatusInput](#destroydynamicannotationtaskstatusinput)
    * [DestroyDynamicAnnotationTattleInput](#destroydynamicannotationtattleinput)
    * [DestroyDynamicAnnotationTeamBotResponseInput](#destroydynamicannotationteambotresponseinput)
    * [DestroyDynamicAnnotationTranscriptInput](#destroydynamicannotationtranscriptinput)
    * [DestroyDynamicAnnotationVerificationStatusInput](#destroydynamicannotationverificationstatusinput)
    * [DestroyDynamicInput](#destroydynamicinput)
    * [DestroyProjectInput](#destroyprojectinput)
    * [DestroyProjectMediaInput](#destroyprojectmediainput)
    * [DestroyProjectMediaProjectInput](#destroyprojectmediaprojectinput)
    * [DestroyProjectSourceInput](#destroyprojectsourceinput)
    * [DestroyRelationshipInput](#destroyrelationshipinput)
    * [DestroySourceInput](#destroysourceinput)
    * [DestroyTagInput](#destroytaginput)
    * [DestroyTagTextInput](#destroytagtextinput)
    * [DestroyTaskInput](#destroytaskinput)
    * [DestroyTeamBotInstallationInput](#destroyteambotinstallationinput)
    * [DestroyTeamInput](#destroyteaminput)
    * [DestroyTeamTaskInput](#destroyteamtaskinput)
    * [DestroyTeamUserInput](#destroyteamuserinput)
    * [DestroyUserInput](#destroyuserinput)
    * [DestroyVersionInput](#destroyversioninput)
    * [GenerateTwoFactorBackupCodesInput](#generatetwofactorbackupcodesinput)
    * [ImportSpreadsheetInput](#importspreadsheetinput)
    * [ResendCancelInvitationInput](#resendcancelinvitationinput)
    * [ResendConfirmationInput](#resendconfirmationinput)
    * [ResetPasswordInput](#resetpasswordinput)
    * [SmoochBotAddSlackChannelUrlInput](#smoochbotaddslackchannelurlinput)
    * [UpdateAccountInput](#updateaccountinput)
    * [UpdateAccountSourceInput](#updateaccountsourceinput)
    * [UpdateCommentInput](#updatecommentinput)
    * [UpdateContactInput](#updatecontactinput)
    * [UpdateDynamicAnnotationAnalysisInput](#updatedynamicannotationanalysisinput)
    * [UpdateDynamicAnnotationArchiveIsInput](#updatedynamicannotationarchiveisinput)
    * [UpdateDynamicAnnotationArchiveOrgInput](#updatedynamicannotationarchiveorginput)
    * [UpdateDynamicAnnotationArchiverInput](#updatedynamicannotationarchiverinput)
    * [UpdateDynamicAnnotationEmbedCodeInput](#updatedynamicannotationembedcodeinput)
    * [UpdateDynamicAnnotationFlagInput](#updatedynamicannotationflaginput)
    * [UpdateDynamicAnnotationGeolocationInput](#updatedynamicannotationgeolocationinput)
    * [UpdateDynamicAnnotationKeepBackupInput](#updatedynamicannotationkeepbackupinput)
    * [UpdateDynamicAnnotationLanguageInput](#updatedynamicannotationlanguageinput)
    * [UpdateDynamicAnnotationMetadataInput](#updatedynamicannotationmetadatainput)
    * [UpdateDynamicAnnotationMetricsInput](#updatedynamicannotationmetricsinput)
    * [UpdateDynamicAnnotationPenderArchiveInput](#updatedynamicannotationpenderarchiveinput)
    * [UpdateDynamicAnnotationReportDesignInput](#updatedynamicannotationreportdesigninput)
    * [UpdateDynamicAnnotationReverseImageInput](#updatedynamicannotationreverseimageinput)
    * [UpdateDynamicAnnotationSlackMessageInput](#updatedynamicannotationslackmessageinput)
    * [UpdateDynamicAnnotationSmoochInput](#updatedynamicannotationsmoochinput)
    * [UpdateDynamicAnnotationSmoochResponseInput](#updatedynamicannotationsmoochresponseinput)
    * [UpdateDynamicAnnotationSmoochUserInput](#updatedynamicannotationsmoochuserinput)
    * [UpdateDynamicAnnotationSyrianArchiveDataInput](#updatedynamicannotationsyrianarchivedatainput)
    * [UpdateDynamicAnnotationTaskResponseDatetimeInput](#updatedynamicannotationtaskresponsedatetimeinput)
    * [UpdateDynamicAnnotationTaskResponseFreeTextInput](#updatedynamicannotationtaskresponsefreetextinput)
    * [UpdateDynamicAnnotationTaskResponseGeolocationInput](#updatedynamicannotationtaskresponsegeolocationinput)
    * [UpdateDynamicAnnotationTaskResponseImageUploadInput](#updatedynamicannotationtaskresponseimageuploadinput)
    * [UpdateDynamicAnnotationTaskResponseMultipleChoiceInput](#updatedynamicannotationtaskresponsemultiplechoiceinput)
    * [UpdateDynamicAnnotationTaskResponseSingleChoiceInput](#updatedynamicannotationtaskresponsesinglechoiceinput)
    * [UpdateDynamicAnnotationTaskResponseYesNoInput](#updatedynamicannotationtaskresponseyesnoinput)
    * [UpdateDynamicAnnotationTaskStatusInput](#updatedynamicannotationtaskstatusinput)
    * [UpdateDynamicAnnotationTattleInput](#updatedynamicannotationtattleinput)
    * [UpdateDynamicAnnotationTeamBotResponseInput](#updatedynamicannotationteambotresponseinput)
    * [UpdateDynamicAnnotationTranscriptInput](#updatedynamicannotationtranscriptinput)
    * [UpdateDynamicAnnotationVerificationStatusInput](#updatedynamicannotationverificationstatusinput)
    * [UpdateDynamicInput](#updatedynamicinput)
    * [UpdateProjectInput](#updateprojectinput)
    * [UpdateProjectMediaInput](#updateprojectmediainput)
    * [UpdateProjectSourceInput](#updateprojectsourceinput)
    * [UpdateRelationshipInput](#updaterelationshipinput)
    * [UpdateSourceInput](#updatesourceinput)
    * [UpdateTagInput](#updatetaginput)
    * [UpdateTagTextInput](#updatetagtextinput)
    * [UpdateTaskInput](#updatetaskinput)
    * [UpdateTeamBotInstallationInput](#updateteambotinstallationinput)
    * [UpdateTeamInput](#updateteaminput)
    * [UpdateTeamTaskInput](#updateteamtaskinput)
    * [UpdateTeamUserInput](#updateteamuserinput)
    * [UpdateUserInput](#updateuserinput)
    * [UserDisconnectLoginAccountInput](#userdisconnectloginaccountinput)
    * [UserInvitationInput](#userinvitationinput)
    * [UserTwoFactorAuthenticationInput](#usertwofactorauthenticationinput)
  * [Scalars](#scalars)
    * [Boolean](#boolean)
    * [ID](#id)
    * [Int](#int)
    * [JsonStringType](#jsonstringtype)
    * [String](#string)
  * [Interfaces](#interfaces)
    * [Node](#node)

</details>

## Query
The query root of this schema

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>about</strong></td>
<td valign="top"><a href="#about">About</a></td>
<td>

Information about the application

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>bot_user</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td>

Information about the bot_user with given id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_field</strong></td>
<td valign="top"><a href="#dynamicannotationfield">DynamicAnnotationField</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">query</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">only_cache</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>find_public_team</strong></td>
<td valign="top"><a href="#publicteam">PublicTeam</a></td>
<td>

Find whether a team exists

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">slug</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>me</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td>

Information about the current user

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#node">Node</a></td>
<td>

Fetches an object given its ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td>

ID of the object.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td>

Information about a project, given its id and its team id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">ids</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td>

Information about a project association, The argument should be given like this: "project_association_id,project_id,team_id"

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">ids</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">url</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td>

Information about a project association, The argument should be given like this: "project_association_id,project_id,team_id"

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">ids</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public_team</strong></td>
<td valign="top"><a href="#publicteam">PublicTeam</a></td>
<td>

Public information about a team

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">slug</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>root</strong></td>
<td valign="top"><a href="#rootlevel">RootLevel</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>search</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td>

Search medias, The argument should be given like this: "{\"keyword\":\"search keyword\"}"

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">query</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td>

Information about the source with given id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td>

Information about the tag_text with given id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td>

Information about the task with given id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td>

Information about the context team or the team from given id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">slug</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td>

Information about the user with given id

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">id</td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
</tbody>
</table>

## Mutation (MutationType)
<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>changePassword</strong></td>
<td valign="top"><a href="#changepasswordpayload">ChangePasswordPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#changepasswordinput">ChangePasswordInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createAccountSource</strong></td>
<td valign="top"><a href="#createaccountsourcepayload">CreateAccountSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createaccountsourceinput">CreateAccountSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createAnnotation</strong></td>
<td valign="top"><a href="#createannotationpayload">CreateAnnotationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createannotationinput">CreateAnnotationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createComment</strong></td>
<td valign="top"><a href="#createcommentpayload">CreateCommentPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createcommentinput">CreateCommentInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createContact</strong></td>
<td valign="top"><a href="#createcontactpayload">CreateContactPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createcontactinput">CreateContactInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamic</strong></td>
<td valign="top"><a href="#createdynamicpayload">CreateDynamicPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicinput">CreateDynamicInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationAnalysis</strong></td>
<td valign="top"><a href="#createdynamicannotationanalysispayload">CreateDynamicAnnotationAnalysisPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationanalysisinput">CreateDynamicAnnotationAnalysisInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationArchiveIs</strong></td>
<td valign="top"><a href="#createdynamicannotationarchiveispayload">CreateDynamicAnnotationArchiveIsPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationarchiveisinput">CreateDynamicAnnotationArchiveIsInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationArchiveOrg</strong></td>
<td valign="top"><a href="#createdynamicannotationarchiveorgpayload">CreateDynamicAnnotationArchiveOrgPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationarchiveorginput">CreateDynamicAnnotationArchiveOrgInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationArchiver</strong></td>
<td valign="top"><a href="#createdynamicannotationarchiverpayload">CreateDynamicAnnotationArchiverPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationarchiverinput">CreateDynamicAnnotationArchiverInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationEmbedCode</strong></td>
<td valign="top"><a href="#createdynamicannotationembedcodepayload">CreateDynamicAnnotationEmbedCodePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationembedcodeinput">CreateDynamicAnnotationEmbedCodeInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationFlag</strong></td>
<td valign="top"><a href="#createdynamicannotationflagpayload">CreateDynamicAnnotationFlagPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationflaginput">CreateDynamicAnnotationFlagInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationGeolocation</strong></td>
<td valign="top"><a href="#createdynamicannotationgeolocationpayload">CreateDynamicAnnotationGeolocationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationgeolocationinput">CreateDynamicAnnotationGeolocationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationKeepBackup</strong></td>
<td valign="top"><a href="#createdynamicannotationkeepbackuppayload">CreateDynamicAnnotationKeepBackupPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationkeepbackupinput">CreateDynamicAnnotationKeepBackupInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationLanguage</strong></td>
<td valign="top"><a href="#createdynamicannotationlanguagepayload">CreateDynamicAnnotationLanguagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationlanguageinput">CreateDynamicAnnotationLanguageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationMetadata</strong></td>
<td valign="top"><a href="#createdynamicannotationmetadatapayload">CreateDynamicAnnotationMetadataPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationmetadatainput">CreateDynamicAnnotationMetadataInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationMetrics</strong></td>
<td valign="top"><a href="#createdynamicannotationmetricspayload">CreateDynamicAnnotationMetricsPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationmetricsinput">CreateDynamicAnnotationMetricsInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationPenderArchive</strong></td>
<td valign="top"><a href="#createdynamicannotationpenderarchivepayload">CreateDynamicAnnotationPenderArchivePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationpenderarchiveinput">CreateDynamicAnnotationPenderArchiveInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationReportDesign</strong></td>
<td valign="top"><a href="#createdynamicannotationreportdesignpayload">CreateDynamicAnnotationReportDesignPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationreportdesigninput">CreateDynamicAnnotationReportDesignInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationReverseImage</strong></td>
<td valign="top"><a href="#createdynamicannotationreverseimagepayload">CreateDynamicAnnotationReverseImagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationreverseimageinput">CreateDynamicAnnotationReverseImageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationSlackMessage</strong></td>
<td valign="top"><a href="#createdynamicannotationslackmessagepayload">CreateDynamicAnnotationSlackMessagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationslackmessageinput">CreateDynamicAnnotationSlackMessageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationSmooch</strong></td>
<td valign="top"><a href="#createdynamicannotationsmoochpayload">CreateDynamicAnnotationSmoochPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationsmoochinput">CreateDynamicAnnotationSmoochInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationSmoochResponse</strong></td>
<td valign="top"><a href="#createdynamicannotationsmoochresponsepayload">CreateDynamicAnnotationSmoochResponsePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationsmoochresponseinput">CreateDynamicAnnotationSmoochResponseInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationSmoochUser</strong></td>
<td valign="top"><a href="#createdynamicannotationsmoochuserpayload">CreateDynamicAnnotationSmoochUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationsmoochuserinput">CreateDynamicAnnotationSmoochUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationSyrianArchiveData</strong></td>
<td valign="top"><a href="#createdynamicannotationsyrianarchivedatapayload">CreateDynamicAnnotationSyrianArchiveDataPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationsyrianarchivedatainput">CreateDynamicAnnotationSyrianArchiveDataInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseDatetime</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponsedatetimepayload">CreateDynamicAnnotationTaskResponseDatetimePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponsedatetimeinput">CreateDynamicAnnotationTaskResponseDatetimeInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseFreeText</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponsefreetextpayload">CreateDynamicAnnotationTaskResponseFreeTextPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponsefreetextinput">CreateDynamicAnnotationTaskResponseFreeTextInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseGeolocation</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponsegeolocationpayload">CreateDynamicAnnotationTaskResponseGeolocationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponsegeolocationinput">CreateDynamicAnnotationTaskResponseGeolocationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseImageUpload</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponseimageuploadpayload">CreateDynamicAnnotationTaskResponseImageUploadPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponseimageuploadinput">CreateDynamicAnnotationTaskResponseImageUploadInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseMultipleChoice</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponsemultiplechoicepayload">CreateDynamicAnnotationTaskResponseMultipleChoicePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponsemultiplechoiceinput">CreateDynamicAnnotationTaskResponseMultipleChoiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseSingleChoice</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponsesinglechoicepayload">CreateDynamicAnnotationTaskResponseSingleChoicePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponsesinglechoiceinput">CreateDynamicAnnotationTaskResponseSingleChoiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskResponseYesNo</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskresponseyesnopayload">CreateDynamicAnnotationTaskResponseYesNoPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskresponseyesnoinput">CreateDynamicAnnotationTaskResponseYesNoInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTaskStatus</strong></td>
<td valign="top"><a href="#createdynamicannotationtaskstatuspayload">CreateDynamicAnnotationTaskStatusPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtaskstatusinput">CreateDynamicAnnotationTaskStatusInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTattle</strong></td>
<td valign="top"><a href="#createdynamicannotationtattlepayload">CreateDynamicAnnotationTattlePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtattleinput">CreateDynamicAnnotationTattleInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTeamBotResponse</strong></td>
<td valign="top"><a href="#createdynamicannotationteambotresponsepayload">CreateDynamicAnnotationTeamBotResponsePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationteambotresponseinput">CreateDynamicAnnotationTeamBotResponseInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationTranscript</strong></td>
<td valign="top"><a href="#createdynamicannotationtranscriptpayload">CreateDynamicAnnotationTranscriptPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationtranscriptinput">CreateDynamicAnnotationTranscriptInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createDynamicAnnotationVerificationStatus</strong></td>
<td valign="top"><a href="#createdynamicannotationverificationstatuspayload">CreateDynamicAnnotationVerificationStatusPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createdynamicannotationverificationstatusinput">CreateDynamicAnnotationVerificationStatusInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createProject</strong></td>
<td valign="top"><a href="#createprojectpayload">CreateProjectPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createprojectinput">CreateProjectInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createProjectMedia</strong></td>
<td valign="top"><a href="#createprojectmediapayload">CreateProjectMediaPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createprojectmediainput">CreateProjectMediaInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createProjectMediaProject</strong></td>
<td valign="top"><a href="#createprojectmediaprojectpayload">CreateProjectMediaProjectPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createprojectmediaprojectinput">CreateProjectMediaProjectInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createProjectSource</strong></td>
<td valign="top"><a href="#createprojectsourcepayload">CreateProjectSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createprojectsourceinput">CreateProjectSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createRelationship</strong></td>
<td valign="top"><a href="#createrelationshippayload">CreateRelationshipPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createrelationshipinput">CreateRelationshipInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createSource</strong></td>
<td valign="top"><a href="#createsourcepayload">CreateSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createsourceinput">CreateSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTag</strong></td>
<td valign="top"><a href="#createtagpayload">CreateTagPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createtaginput">CreateTagInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTagText</strong></td>
<td valign="top"><a href="#createtagtextpayload">CreateTagTextPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createtagtextinput">CreateTagTextInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTags</strong></td>
<td valign="top"><a href="#createtagsmutationpayload">CreateTagsMutationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">inputs</td>
<td valign="top">[<a href="#createtagsinput">CreateTagsInput</a>!]!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTask</strong></td>
<td valign="top"><a href="#createtaskpayload">CreateTaskPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createtaskinput">CreateTaskInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTeam</strong></td>
<td valign="top"><a href="#createteampayload">CreateTeamPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createteaminput">CreateTeamInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTeamBotInstallation</strong></td>
<td valign="top"><a href="#createteambotinstallationpayload">CreateTeamBotInstallationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createteambotinstallationinput">CreateTeamBotInstallationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTeamTask</strong></td>
<td valign="top"><a href="#createteamtaskpayload">CreateTeamTaskPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createteamtaskinput">CreateTeamTaskInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createTeamUser</strong></td>
<td valign="top"><a href="#createteamuserpayload">CreateTeamUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createteamuserinput">CreateTeamUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>createUser</strong></td>
<td valign="top"><a href="#createuserpayload">CreateUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#createuserinput">CreateUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deleteCheckUser</strong></td>
<td valign="top"><a href="#deletecheckuserpayload">DeleteCheckUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#deletecheckuserinput">DeleteCheckUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyAccountSource</strong></td>
<td valign="top"><a href="#destroyaccountsourcepayload">DestroyAccountSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyaccountsourceinput">DestroyAccountSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyAnnotation</strong></td>
<td valign="top"><a href="#destroyannotationpayload">DestroyAnnotationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyannotationinput">DestroyAnnotationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyComment</strong></td>
<td valign="top"><a href="#destroycommentpayload">DestroyCommentPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroycommentinput">DestroyCommentInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyContact</strong></td>
<td valign="top"><a href="#destroycontactpayload">DestroyContactPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroycontactinput">DestroyContactInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamic</strong></td>
<td valign="top"><a href="#destroydynamicpayload">DestroyDynamicPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicinput">DestroyDynamicInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationAnalysis</strong></td>
<td valign="top"><a href="#destroydynamicannotationanalysispayload">DestroyDynamicAnnotationAnalysisPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationanalysisinput">DestroyDynamicAnnotationAnalysisInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationArchiveIs</strong></td>
<td valign="top"><a href="#destroydynamicannotationarchiveispayload">DestroyDynamicAnnotationArchiveIsPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationarchiveisinput">DestroyDynamicAnnotationArchiveIsInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationArchiveOrg</strong></td>
<td valign="top"><a href="#destroydynamicannotationarchiveorgpayload">DestroyDynamicAnnotationArchiveOrgPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationarchiveorginput">DestroyDynamicAnnotationArchiveOrgInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationArchiver</strong></td>
<td valign="top"><a href="#destroydynamicannotationarchiverpayload">DestroyDynamicAnnotationArchiverPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationarchiverinput">DestroyDynamicAnnotationArchiverInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationEmbedCode</strong></td>
<td valign="top"><a href="#destroydynamicannotationembedcodepayload">DestroyDynamicAnnotationEmbedCodePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationembedcodeinput">DestroyDynamicAnnotationEmbedCodeInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationFlag</strong></td>
<td valign="top"><a href="#destroydynamicannotationflagpayload">DestroyDynamicAnnotationFlagPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationflaginput">DestroyDynamicAnnotationFlagInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationGeolocation</strong></td>
<td valign="top"><a href="#destroydynamicannotationgeolocationpayload">DestroyDynamicAnnotationGeolocationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationgeolocationinput">DestroyDynamicAnnotationGeolocationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationKeepBackup</strong></td>
<td valign="top"><a href="#destroydynamicannotationkeepbackuppayload">DestroyDynamicAnnotationKeepBackupPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationkeepbackupinput">DestroyDynamicAnnotationKeepBackupInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationLanguage</strong></td>
<td valign="top"><a href="#destroydynamicannotationlanguagepayload">DestroyDynamicAnnotationLanguagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationlanguageinput">DestroyDynamicAnnotationLanguageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationMetadata</strong></td>
<td valign="top"><a href="#destroydynamicannotationmetadatapayload">DestroyDynamicAnnotationMetadataPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationmetadatainput">DestroyDynamicAnnotationMetadataInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationMetrics</strong></td>
<td valign="top"><a href="#destroydynamicannotationmetricspayload">DestroyDynamicAnnotationMetricsPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationmetricsinput">DestroyDynamicAnnotationMetricsInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationPenderArchive</strong></td>
<td valign="top"><a href="#destroydynamicannotationpenderarchivepayload">DestroyDynamicAnnotationPenderArchivePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationpenderarchiveinput">DestroyDynamicAnnotationPenderArchiveInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationReportDesign</strong></td>
<td valign="top"><a href="#destroydynamicannotationreportdesignpayload">DestroyDynamicAnnotationReportDesignPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationreportdesigninput">DestroyDynamicAnnotationReportDesignInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationReverseImage</strong></td>
<td valign="top"><a href="#destroydynamicannotationreverseimagepayload">DestroyDynamicAnnotationReverseImagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationreverseimageinput">DestroyDynamicAnnotationReverseImageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationSlackMessage</strong></td>
<td valign="top"><a href="#destroydynamicannotationslackmessagepayload">DestroyDynamicAnnotationSlackMessagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationslackmessageinput">DestroyDynamicAnnotationSlackMessageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationSmooch</strong></td>
<td valign="top"><a href="#destroydynamicannotationsmoochpayload">DestroyDynamicAnnotationSmoochPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationsmoochinput">DestroyDynamicAnnotationSmoochInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationSmoochResponse</strong></td>
<td valign="top"><a href="#destroydynamicannotationsmoochresponsepayload">DestroyDynamicAnnotationSmoochResponsePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationsmoochresponseinput">DestroyDynamicAnnotationSmoochResponseInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationSmoochUser</strong></td>
<td valign="top"><a href="#destroydynamicannotationsmoochuserpayload">DestroyDynamicAnnotationSmoochUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationsmoochuserinput">DestroyDynamicAnnotationSmoochUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationSyrianArchiveData</strong></td>
<td valign="top"><a href="#destroydynamicannotationsyrianarchivedatapayload">DestroyDynamicAnnotationSyrianArchiveDataPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationsyrianarchivedatainput">DestroyDynamicAnnotationSyrianArchiveDataInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseDatetime</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsedatetimepayload">DestroyDynamicAnnotationTaskResponseDatetimePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsedatetimeinput">DestroyDynamicAnnotationTaskResponseDatetimeInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseFreeText</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsefreetextpayload">DestroyDynamicAnnotationTaskResponseFreeTextPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsefreetextinput">DestroyDynamicAnnotationTaskResponseFreeTextInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseGeolocation</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsegeolocationpayload">DestroyDynamicAnnotationTaskResponseGeolocationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsegeolocationinput">DestroyDynamicAnnotationTaskResponseGeolocationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseImageUpload</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponseimageuploadpayload">DestroyDynamicAnnotationTaskResponseImageUploadPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponseimageuploadinput">DestroyDynamicAnnotationTaskResponseImageUploadInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseMultipleChoice</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsemultiplechoicepayload">DestroyDynamicAnnotationTaskResponseMultipleChoicePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsemultiplechoiceinput">DestroyDynamicAnnotationTaskResponseMultipleChoiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseSingleChoice</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsesinglechoicepayload">DestroyDynamicAnnotationTaskResponseSingleChoicePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponsesinglechoiceinput">DestroyDynamicAnnotationTaskResponseSingleChoiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskResponseYesNo</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskresponseyesnopayload">DestroyDynamicAnnotationTaskResponseYesNoPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskresponseyesnoinput">DestroyDynamicAnnotationTaskResponseYesNoInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTaskStatus</strong></td>
<td valign="top"><a href="#destroydynamicannotationtaskstatuspayload">DestroyDynamicAnnotationTaskStatusPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtaskstatusinput">DestroyDynamicAnnotationTaskStatusInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTattle</strong></td>
<td valign="top"><a href="#destroydynamicannotationtattlepayload">DestroyDynamicAnnotationTattlePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtattleinput">DestroyDynamicAnnotationTattleInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTeamBotResponse</strong></td>
<td valign="top"><a href="#destroydynamicannotationteambotresponsepayload">DestroyDynamicAnnotationTeamBotResponsePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationteambotresponseinput">DestroyDynamicAnnotationTeamBotResponseInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationTranscript</strong></td>
<td valign="top"><a href="#destroydynamicannotationtranscriptpayload">DestroyDynamicAnnotationTranscriptPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationtranscriptinput">DestroyDynamicAnnotationTranscriptInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyDynamicAnnotationVerificationStatus</strong></td>
<td valign="top"><a href="#destroydynamicannotationverificationstatuspayload">DestroyDynamicAnnotationVerificationStatusPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroydynamicannotationverificationstatusinput">DestroyDynamicAnnotationVerificationStatusInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyProject</strong></td>
<td valign="top"><a href="#destroyprojectpayload">DestroyProjectPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyprojectinput">DestroyProjectInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyProjectMedia</strong></td>
<td valign="top"><a href="#destroyprojectmediapayload">DestroyProjectMediaPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyprojectmediainput">DestroyProjectMediaInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyProjectMediaProject</strong></td>
<td valign="top"><a href="#destroyprojectmediaprojectpayload">DestroyProjectMediaProjectPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyprojectmediaprojectinput">DestroyProjectMediaProjectInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyProjectSource</strong></td>
<td valign="top"><a href="#destroyprojectsourcepayload">DestroyProjectSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyprojectsourceinput">DestroyProjectSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyRelationship</strong></td>
<td valign="top"><a href="#destroyrelationshippayload">DestroyRelationshipPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyrelationshipinput">DestroyRelationshipInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroySource</strong></td>
<td valign="top"><a href="#destroysourcepayload">DestroySourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroysourceinput">DestroySourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTag</strong></td>
<td valign="top"><a href="#destroytagpayload">DestroyTagPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroytaginput">DestroyTagInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTagText</strong></td>
<td valign="top"><a href="#destroytagtextpayload">DestroyTagTextPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroytagtextinput">DestroyTagTextInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTask</strong></td>
<td valign="top"><a href="#destroytaskpayload">DestroyTaskPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroytaskinput">DestroyTaskInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTeam</strong></td>
<td valign="top"><a href="#destroyteampayload">DestroyTeamPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyteaminput">DestroyTeamInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTeamBotInstallation</strong></td>
<td valign="top"><a href="#destroyteambotinstallationpayload">DestroyTeamBotInstallationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyteambotinstallationinput">DestroyTeamBotInstallationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTeamTask</strong></td>
<td valign="top"><a href="#destroyteamtaskpayload">DestroyTeamTaskPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyteamtaskinput">DestroyTeamTaskInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyTeamUser</strong></td>
<td valign="top"><a href="#destroyteamuserpayload">DestroyTeamUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyteamuserinput">DestroyTeamUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyUser</strong></td>
<td valign="top"><a href="#destroyuserpayload">DestroyUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyuserinput">DestroyUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>destroyVersion</strong></td>
<td valign="top"><a href="#destroyversionpayload">DestroyVersionPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#destroyversioninput">DestroyVersionInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>generateTwoFactorBackupCodes</strong></td>
<td valign="top"><a href="#generatetwofactorbackupcodespayload">GenerateTwoFactorBackupCodesPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#generatetwofactorbackupcodesinput">GenerateTwoFactorBackupCodesInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>importSpreadsheet</strong></td>
<td valign="top"><a href="#importspreadsheetpayload">ImportSpreadsheetPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#importspreadsheetinput">ImportSpreadsheetInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>resendCancelInvitation</strong></td>
<td valign="top"><a href="#resendcancelinvitationpayload">ResendCancelInvitationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#resendcancelinvitationinput">ResendCancelInvitationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>resendConfirmation</strong></td>
<td valign="top"><a href="#resendconfirmationpayload">ResendConfirmationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#resendconfirmationinput">ResendConfirmationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>resetPassword</strong></td>
<td valign="top"><a href="#resetpasswordpayload">ResetPasswordPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#resetpasswordinput">ResetPasswordInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>smoochBotAddSlackChannelUrl</strong></td>
<td valign="top"><a href="#smoochbotaddslackchannelurlpayload">SmoochBotAddSlackChannelUrlPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#smoochbotaddslackchannelurlinput">SmoochBotAddSlackChannelUrlInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateAccount</strong></td>
<td valign="top"><a href="#updateaccountpayload">UpdateAccountPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateaccountinput">UpdateAccountInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateAccountSource</strong></td>
<td valign="top"><a href="#updateaccountsourcepayload">UpdateAccountSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateaccountsourceinput">UpdateAccountSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateComment</strong></td>
<td valign="top"><a href="#updatecommentpayload">UpdateCommentPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatecommentinput">UpdateCommentInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateContact</strong></td>
<td valign="top"><a href="#updatecontactpayload">UpdateContactPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatecontactinput">UpdateContactInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamic</strong></td>
<td valign="top"><a href="#updatedynamicpayload">UpdateDynamicPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicinput">UpdateDynamicInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationAnalysis</strong></td>
<td valign="top"><a href="#updatedynamicannotationanalysispayload">UpdateDynamicAnnotationAnalysisPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationanalysisinput">UpdateDynamicAnnotationAnalysisInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationArchiveIs</strong></td>
<td valign="top"><a href="#updatedynamicannotationarchiveispayload">UpdateDynamicAnnotationArchiveIsPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationarchiveisinput">UpdateDynamicAnnotationArchiveIsInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationArchiveOrg</strong></td>
<td valign="top"><a href="#updatedynamicannotationarchiveorgpayload">UpdateDynamicAnnotationArchiveOrgPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationarchiveorginput">UpdateDynamicAnnotationArchiveOrgInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationArchiver</strong></td>
<td valign="top"><a href="#updatedynamicannotationarchiverpayload">UpdateDynamicAnnotationArchiverPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationarchiverinput">UpdateDynamicAnnotationArchiverInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationEmbedCode</strong></td>
<td valign="top"><a href="#updatedynamicannotationembedcodepayload">UpdateDynamicAnnotationEmbedCodePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationembedcodeinput">UpdateDynamicAnnotationEmbedCodeInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationFlag</strong></td>
<td valign="top"><a href="#updatedynamicannotationflagpayload">UpdateDynamicAnnotationFlagPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationflaginput">UpdateDynamicAnnotationFlagInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationGeolocation</strong></td>
<td valign="top"><a href="#updatedynamicannotationgeolocationpayload">UpdateDynamicAnnotationGeolocationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationgeolocationinput">UpdateDynamicAnnotationGeolocationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationKeepBackup</strong></td>
<td valign="top"><a href="#updatedynamicannotationkeepbackuppayload">UpdateDynamicAnnotationKeepBackupPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationkeepbackupinput">UpdateDynamicAnnotationKeepBackupInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationLanguage</strong></td>
<td valign="top"><a href="#updatedynamicannotationlanguagepayload">UpdateDynamicAnnotationLanguagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationlanguageinput">UpdateDynamicAnnotationLanguageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationMetadata</strong></td>
<td valign="top"><a href="#updatedynamicannotationmetadatapayload">UpdateDynamicAnnotationMetadataPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationmetadatainput">UpdateDynamicAnnotationMetadataInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationMetrics</strong></td>
<td valign="top"><a href="#updatedynamicannotationmetricspayload">UpdateDynamicAnnotationMetricsPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationmetricsinput">UpdateDynamicAnnotationMetricsInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationPenderArchive</strong></td>
<td valign="top"><a href="#updatedynamicannotationpenderarchivepayload">UpdateDynamicAnnotationPenderArchivePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationpenderarchiveinput">UpdateDynamicAnnotationPenderArchiveInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationReportDesign</strong></td>
<td valign="top"><a href="#updatedynamicannotationreportdesignpayload">UpdateDynamicAnnotationReportDesignPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationreportdesigninput">UpdateDynamicAnnotationReportDesignInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationReverseImage</strong></td>
<td valign="top"><a href="#updatedynamicannotationreverseimagepayload">UpdateDynamicAnnotationReverseImagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationreverseimageinput">UpdateDynamicAnnotationReverseImageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationSlackMessage</strong></td>
<td valign="top"><a href="#updatedynamicannotationslackmessagepayload">UpdateDynamicAnnotationSlackMessagePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationslackmessageinput">UpdateDynamicAnnotationSlackMessageInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationSmooch</strong></td>
<td valign="top"><a href="#updatedynamicannotationsmoochpayload">UpdateDynamicAnnotationSmoochPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationsmoochinput">UpdateDynamicAnnotationSmoochInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationSmoochResponse</strong></td>
<td valign="top"><a href="#updatedynamicannotationsmoochresponsepayload">UpdateDynamicAnnotationSmoochResponsePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationsmoochresponseinput">UpdateDynamicAnnotationSmoochResponseInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationSmoochUser</strong></td>
<td valign="top"><a href="#updatedynamicannotationsmoochuserpayload">UpdateDynamicAnnotationSmoochUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationsmoochuserinput">UpdateDynamicAnnotationSmoochUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationSyrianArchiveData</strong></td>
<td valign="top"><a href="#updatedynamicannotationsyrianarchivedatapayload">UpdateDynamicAnnotationSyrianArchiveDataPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationsyrianarchivedatainput">UpdateDynamicAnnotationSyrianArchiveDataInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseDatetime</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsedatetimepayload">UpdateDynamicAnnotationTaskResponseDatetimePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsedatetimeinput">UpdateDynamicAnnotationTaskResponseDatetimeInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseFreeText</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsefreetextpayload">UpdateDynamicAnnotationTaskResponseFreeTextPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsefreetextinput">UpdateDynamicAnnotationTaskResponseFreeTextInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseGeolocation</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsegeolocationpayload">UpdateDynamicAnnotationTaskResponseGeolocationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsegeolocationinput">UpdateDynamicAnnotationTaskResponseGeolocationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseImageUpload</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponseimageuploadpayload">UpdateDynamicAnnotationTaskResponseImageUploadPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponseimageuploadinput">UpdateDynamicAnnotationTaskResponseImageUploadInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseMultipleChoice</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsemultiplechoicepayload">UpdateDynamicAnnotationTaskResponseMultipleChoicePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsemultiplechoiceinput">UpdateDynamicAnnotationTaskResponseMultipleChoiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseSingleChoice</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsesinglechoicepayload">UpdateDynamicAnnotationTaskResponseSingleChoicePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponsesinglechoiceinput">UpdateDynamicAnnotationTaskResponseSingleChoiceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskResponseYesNo</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskresponseyesnopayload">UpdateDynamicAnnotationTaskResponseYesNoPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskresponseyesnoinput">UpdateDynamicAnnotationTaskResponseYesNoInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTaskStatus</strong></td>
<td valign="top"><a href="#updatedynamicannotationtaskstatuspayload">UpdateDynamicAnnotationTaskStatusPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtaskstatusinput">UpdateDynamicAnnotationTaskStatusInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTattle</strong></td>
<td valign="top"><a href="#updatedynamicannotationtattlepayload">UpdateDynamicAnnotationTattlePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtattleinput">UpdateDynamicAnnotationTattleInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTeamBotResponse</strong></td>
<td valign="top"><a href="#updatedynamicannotationteambotresponsepayload">UpdateDynamicAnnotationTeamBotResponsePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationteambotresponseinput">UpdateDynamicAnnotationTeamBotResponseInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationTranscript</strong></td>
<td valign="top"><a href="#updatedynamicannotationtranscriptpayload">UpdateDynamicAnnotationTranscriptPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationtranscriptinput">UpdateDynamicAnnotationTranscriptInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateDynamicAnnotationVerificationStatus</strong></td>
<td valign="top"><a href="#updatedynamicannotationverificationstatuspayload">UpdateDynamicAnnotationVerificationStatusPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatedynamicannotationverificationstatusinput">UpdateDynamicAnnotationVerificationStatusInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateProject</strong></td>
<td valign="top"><a href="#updateprojectpayload">UpdateProjectPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateprojectinput">UpdateProjectInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateProjectMedia</strong></td>
<td valign="top"><a href="#updateprojectmediapayload">UpdateProjectMediaPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateprojectmediainput">UpdateProjectMediaInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateProjectSource</strong></td>
<td valign="top"><a href="#updateprojectsourcepayload">UpdateProjectSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateprojectsourceinput">UpdateProjectSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateRelationship</strong></td>
<td valign="top"><a href="#updaterelationshippayload">UpdateRelationshipPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updaterelationshipinput">UpdateRelationshipInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateSource</strong></td>
<td valign="top"><a href="#updatesourcepayload">UpdateSourcePayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatesourceinput">UpdateSourceInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTag</strong></td>
<td valign="top"><a href="#updatetagpayload">UpdateTagPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatetaginput">UpdateTagInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTagText</strong></td>
<td valign="top"><a href="#updatetagtextpayload">UpdateTagTextPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatetagtextinput">UpdateTagTextInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTask</strong></td>
<td valign="top"><a href="#updatetaskpayload">UpdateTaskPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updatetaskinput">UpdateTaskInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTeam</strong></td>
<td valign="top"><a href="#updateteampayload">UpdateTeamPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateteaminput">UpdateTeamInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTeamBotInstallation</strong></td>
<td valign="top"><a href="#updateteambotinstallationpayload">UpdateTeamBotInstallationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateteambotinstallationinput">UpdateTeamBotInstallationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTeamTask</strong></td>
<td valign="top"><a href="#updateteamtaskpayload">UpdateTeamTaskPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateteamtaskinput">UpdateTeamTaskInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateTeamUser</strong></td>
<td valign="top"><a href="#updateteamuserpayload">UpdateTeamUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateteamuserinput">UpdateTeamUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updateUser</strong></td>
<td valign="top"><a href="#updateuserpayload">UpdateUserPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#updateuserinput">UpdateUserInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>userDisconnectLoginAccount</strong></td>
<td valign="top"><a href="#userdisconnectloginaccountpayload">UserDisconnectLoginAccountPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#userdisconnectloginaccountinput">UserDisconnectLoginAccountInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>userInvitation</strong></td>
<td valign="top"><a href="#userinvitationpayload">UserInvitationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#userinvitationinput">UserInvitationInput</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>userTwoFactorAuthentication</strong></td>
<td valign="top"><a href="#usertwofactorauthenticationpayload">UserTwoFactorAuthenticationPayload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">input</td>
<td valign="top"><a href="#usertwofactorauthenticationinput">UserTwoFactorAuthenticationInput</a>!</td>
<td></td>
</tr>
</tbody>
</table>

## Objects

### About

Information about the application

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>languages_supported</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Supported languages

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Application name

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>terms_last_updated_at</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Terms last update date

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upload_extensions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Allowed upload types

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upload_max_dimensions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Maximum image dimensions

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upload_max_size</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Maximum upload size

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>upload_min_dimensions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Minimum image dimensions

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Application version

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>video_extensions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Allowed video types

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>video_max_size</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

Maximum video upload size

</td>
</tr>
</tbody>
</table>

### Account

Account type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#mediaconnection">MediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>metadata</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>provider</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>uid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### AccountConnection

The connection type for Account.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#accountedge">AccountEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### AccountEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#account">Account</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### AccountSource

AccountSource type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account</strong></td>
<td valign="top"><a href="#account">Account</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>account_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### AccountSourceConnection

The connection type for AccountSource.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#accountsourceedge">AccountSourceEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### AccountSourceEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#accountsource">AccountSource</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Annotation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>attribution</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### AnnotationConnection

The connection type for Annotation.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#annotationedge">AnnotationEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### AnnotationEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Annotator

Information about an annotator

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>profile_image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### BotUser

Bot User type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>avatar</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_role</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_source_code_url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_version</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>identifier</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>installation</strong></td>
<td valign="top"><a href="#teambotinstallation">TeamBotInstallation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>installations_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>installed</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>login</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>settings_as_json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>settings_ui_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_author</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### BotUserConnection

The connection type for BotUser.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#botuseredge">BotUserEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### BotUserEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### ChangePasswordPayload

Autogenerated return type of ChangePassword

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### CheckSearch

CheckSearch type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>item_navigation_offset</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>number_of_results</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sources</strong></td>
<td valign="top"><a href="#projectsourceconnection">ProjectSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### Comment

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### CommentConnection

The connection type for Comment.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#commentedge">CommentEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### CommentEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#comment">Comment</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Contact

Contact type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>location</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>phone</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>web</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### ContactConnection

The connection type for Contact.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#contactedge">ContactEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### ContactEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#contact">Contact</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### CreateAccountSourcePayload

Autogenerated return type of CreateAccountSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account_source</strong></td>
<td valign="top"><a href="#accountsource">AccountSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>account_sourceEdge</strong></td>
<td valign="top"><a href="#accountsourceedge">AccountSourceEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateAnnotationPayload

Autogenerated return type of CreateAnnotation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotationEdge</strong></td>
<td valign="top"><a href="#annotationedge">AnnotationEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateCommentPayload

Autogenerated return type of CreateComment

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment</strong></td>
<td valign="top"><a href="#comment">Comment</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>commentEdge</strong></td>
<td valign="top"><a href="#commentedge">CommentEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment_version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment_versionEdge</strong></td>
<td valign="top"><a href="#versionedge">VersionEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateContactPayload

Autogenerated return type of CreateContact

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contact</strong></td>
<td valign="top"><a href="#contact">Contact</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactEdge</strong></td>
<td valign="top"><a href="#contactedge">ContactEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationAnalysisPayload

Autogenerated return type of CreateDynamicAnnotationAnalysis

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_analysis</strong></td>
<td valign="top"><a href="#dynamic_annotation_analysis">Dynamic_annotation_analysis</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_analysisEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_analysisedge">Dynamic_annotation_analysisEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationArchiveIsPayload

Autogenerated return type of CreateDynamicAnnotationArchiveIs

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_is</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_is">Dynamic_annotation_archive_is</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_isEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_isedge">Dynamic_annotation_archive_isEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationArchiveOrgPayload

Autogenerated return type of CreateDynamicAnnotationArchiveOrg

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_org</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_org">Dynamic_annotation_archive_org</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_orgEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_orgedge">Dynamic_annotation_archive_orgEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationArchiverPayload

Autogenerated return type of CreateDynamicAnnotationArchiver

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archiver</strong></td>
<td valign="top"><a href="#dynamic_annotation_archiver">Dynamic_annotation_archiver</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archiverEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_archiveredge">Dynamic_annotation_archiverEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationEmbedCodePayload

Autogenerated return type of CreateDynamicAnnotationEmbedCode

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_embed_code</strong></td>
<td valign="top"><a href="#dynamic_annotation_embed_code">Dynamic_annotation_embed_code</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_embed_codeEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_embed_codeedge">Dynamic_annotation_embed_codeEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationFlagPayload

Autogenerated return type of CreateDynamicAnnotationFlag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_flag</strong></td>
<td valign="top"><a href="#dynamic_annotation_flag">Dynamic_annotation_flag</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_flagEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_flagedge">Dynamic_annotation_flagEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationGeolocationPayload

Autogenerated return type of CreateDynamicAnnotationGeolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_geolocation</strong></td>
<td valign="top"><a href="#dynamic_annotation_geolocation">Dynamic_annotation_geolocation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_geolocationEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_geolocationedge">Dynamic_annotation_geolocationEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationKeepBackupPayload

Autogenerated return type of CreateDynamicAnnotationKeepBackup

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_keep_backup</strong></td>
<td valign="top"><a href="#dynamic_annotation_keep_backup">Dynamic_annotation_keep_backup</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_keep_backupEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_keep_backupedge">Dynamic_annotation_keep_backupEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationLanguagePayload

Autogenerated return type of CreateDynamicAnnotationLanguage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_language</strong></td>
<td valign="top"><a href="#dynamic_annotation_language">Dynamic_annotation_language</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_languageEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_languageedge">Dynamic_annotation_languageEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationMetadataPayload

Autogenerated return type of CreateDynamicAnnotationMetadata

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metadata</strong></td>
<td valign="top"><a href="#dynamic_annotation_metadata">Dynamic_annotation_metadata</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metadataEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_metadataedge">Dynamic_annotation_metadataEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationMetricsPayload

Autogenerated return type of CreateDynamicAnnotationMetrics

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metrics</strong></td>
<td valign="top"><a href="#dynamic_annotation_metrics">Dynamic_annotation_metrics</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metricsEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_metricsedge">Dynamic_annotation_metricsEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationPenderArchivePayload

Autogenerated return type of CreateDynamicAnnotationPenderArchive

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_pender_archive</strong></td>
<td valign="top"><a href="#dynamic_annotation_pender_archive">Dynamic_annotation_pender_archive</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_pender_archiveEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_pender_archiveedge">Dynamic_annotation_pender_archiveEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationReportDesignPayload

Autogenerated return type of CreateDynamicAnnotationReportDesign

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_report_design</strong></td>
<td valign="top"><a href="#dynamic_annotation_report_design">Dynamic_annotation_report_design</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_report_designEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_report_designedge">Dynamic_annotation_report_designEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationReverseImagePayload

Autogenerated return type of CreateDynamicAnnotationReverseImage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_reverse_image</strong></td>
<td valign="top"><a href="#dynamic_annotation_reverse_image">Dynamic_annotation_reverse_image</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_reverse_imageEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_reverse_imageedge">Dynamic_annotation_reverse_imageEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSlackMessagePayload

Autogenerated return type of CreateDynamicAnnotationSlackMessage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_slack_message</strong></td>
<td valign="top"><a href="#dynamic_annotation_slack_message">Dynamic_annotation_slack_message</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_slack_messageEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_slack_messageedge">Dynamic_annotation_slack_messageEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSmoochPayload

Autogenerated return type of CreateDynamicAnnotationSmooch

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch">Dynamic_annotation_smooch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smoochEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_smoochedge">Dynamic_annotation_smoochEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSmoochResponsePayload

Autogenerated return type of CreateDynamicAnnotationSmoochResponse

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_response</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_response">Dynamic_annotation_smooch_response</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_responseEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_responseedge">Dynamic_annotation_smooch_responseEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSmoochUserPayload

Autogenerated return type of CreateDynamicAnnotationSmoochUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_user</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_user">Dynamic_annotation_smooch_user</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_userEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_useredge">Dynamic_annotation_smooch_userEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSyrianArchiveDataPayload

Autogenerated return type of CreateDynamicAnnotationSyrianArchiveData

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_syrian_archive_data</strong></td>
<td valign="top"><a href="#dynamic_annotation_syrian_archive_data">Dynamic_annotation_syrian_archive_data</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_syrian_archive_dataEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_syrian_archive_dataedge">Dynamic_annotation_syrian_archive_dataEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseDatetimePayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseDatetime

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_datetime</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_datetime">Dynamic_annotation_task_response_datetime</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_datetimeEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_datetimeedge">Dynamic_annotation_task_response_datetimeEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseFreeTextPayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseFreeText

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_free_text</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_free_text">Dynamic_annotation_task_response_free_text</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_free_textEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_free_textedge">Dynamic_annotation_task_response_free_textEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseGeolocationPayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseGeolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_geolocation</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_geolocation">Dynamic_annotation_task_response_geolocation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_geolocationEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_geolocationedge">Dynamic_annotation_task_response_geolocationEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseImageUploadPayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseImageUpload

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_image_upload</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_image_upload">Dynamic_annotation_task_response_image_upload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_image_uploadEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_image_uploadedge">Dynamic_annotation_task_response_image_uploadEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseMultipleChoicePayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseMultipleChoice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_multiple_choice</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_multiple_choice">Dynamic_annotation_task_response_multiple_choice</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_multiple_choiceEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_multiple_choiceedge">Dynamic_annotation_task_response_multiple_choiceEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseSingleChoicePayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseSingleChoice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_single_choice</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_single_choice">Dynamic_annotation_task_response_single_choice</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_single_choiceEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_single_choiceedge">Dynamic_annotation_task_response_single_choiceEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseYesNoPayload

Autogenerated return type of CreateDynamicAnnotationTaskResponseYesNo

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_yes_no</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_yes_no">Dynamic_annotation_task_response_yes_no</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_yes_noEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_yes_noedge">Dynamic_annotation_task_response_yes_noEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskStatusPayload

Autogenerated return type of CreateDynamicAnnotationTaskStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_status</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_status">Dynamic_annotation_task_status</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_statusEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_statusedge">Dynamic_annotation_task_statusEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTattlePayload

Autogenerated return type of CreateDynamicAnnotationTattle

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_tattle</strong></td>
<td valign="top"><a href="#dynamic_annotation_tattle">Dynamic_annotation_tattle</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_tattleEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_tattleedge">Dynamic_annotation_tattleEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTeamBotResponsePayload

Autogenerated return type of CreateDynamicAnnotationTeamBotResponse

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_team_bot_response</strong></td>
<td valign="top"><a href="#dynamic_annotation_team_bot_response">Dynamic_annotation_team_bot_response</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_team_bot_responseEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_team_bot_responseedge">Dynamic_annotation_team_bot_responseEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTranscriptPayload

Autogenerated return type of CreateDynamicAnnotationTranscript

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_transcript</strong></td>
<td valign="top"><a href="#dynamic_annotation_transcript">Dynamic_annotation_transcript</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_transcriptEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_transcriptedge">Dynamic_annotation_transcriptEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationVerificationStatusPayload

Autogenerated return type of CreateDynamicAnnotationVerificationStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_verification_status</strong></td>
<td valign="top"><a href="#dynamic_annotation_verification_status">Dynamic_annotation_verification_status</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_verification_statusEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_verification_statusedge">Dynamic_annotation_verification_statusEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicPayload

Autogenerated return type of CreateDynamic

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectMediaPayload

Autogenerated return type of CreateProjectMedia

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project_was</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_mediaEdge</strong></td>
<td valign="top"><a href="#projectmediaedge">ProjectMediaEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_was</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>related_to</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_source</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_target</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectMediaProjectPayload

Autogenerated return type of CreateProjectMediaProject

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media_project</strong></td>
<td valign="top"><a href="#projectmediaproject">ProjectMediaProject</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media_projectEdge</strong></td>
<td valign="top"><a href="#projectmediaprojectedge">ProjectMediaProjectEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectPayload

Autogenerated return type of CreateProject

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projectEdge</strong></td>
<td valign="top"><a href="#projectedge">ProjectEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectSourcePayload

Autogenerated return type of CreateProjectSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_sourceEdge</strong></td>
<td valign="top"><a href="#projectsourceedge">ProjectSourceEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateRelationshipPayload

Autogenerated return type of CreateRelationship

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationship</strong></td>
<td valign="top"><a href="#relationship">Relationship</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationshipEdge</strong></td>
<td valign="top"><a href="#relationshipedge">RelationshipEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_source</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_target</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateSourcePayload

Autogenerated return type of CreateSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sourceEdge</strong></td>
<td valign="top"><a href="#sourceedge">SourceEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTagPayload

Autogenerated return type of CreateTag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#tag">Tag</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tagEdge</strong></td>
<td valign="top"><a href="#tagedge">TagEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text_object</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTagTextPayload

Autogenerated return type of CreateTagText

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_textEdge</strong></td>
<td valign="top"><a href="#tagtextedge">TagTextEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTagsMutationPayload

Autogenerated return type of CreateTagsMutation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>enqueued</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateTaskPayload

Autogenerated return type of CreateTask

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response_version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response_versionEdge</strong></td>
<td valign="top"><a href="#versionedge">VersionEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>taskEdge</strong></td>
<td valign="top"><a href="#taskedge">TaskEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamBotInstallationPayload

Autogenerated return type of CreateTeamBotInstallation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>bot_user</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bot_installation</strong></td>
<td valign="top"><a href="#teambotinstallation">TeamBotInstallation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bot_installationEdge</strong></td>
<td valign="top"><a href="#teambotinstallationedge">TeamBotInstallationEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamPayload

Autogenerated return type of CreateTeam

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public_team</strong></td>
<td valign="top"><a href="#publicteam">PublicTeam</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teamEdge</strong></td>
<td valign="top"><a href="#teamedge">TeamEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_userEdge</strong></td>
<td valign="top"><a href="#teamuseredge">TeamUserEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamTaskPayload

Autogenerated return type of CreateTeamTask

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_task</strong></td>
<td valign="top"><a href="#teamtask">TeamTask</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_taskEdge</strong></td>
<td valign="top"><a href="#teamtaskedge">TeamTaskEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamUserPayload

Autogenerated return type of CreateTeamUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_user</strong></td>
<td valign="top"><a href="#teamuser">TeamUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_userEdge</strong></td>
<td valign="top"><a href="#teamuseredge">TeamUserEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateUserPayload

Autogenerated return type of CreateUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>userEdge</strong></td>
<td valign="top"><a href="#useredge">UserEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### DeleteCheckUserPayload

Autogenerated return type of DeleteCheckUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyAccountSourcePayload

Autogenerated return type of DestroyAccountSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyAnnotationPayload

Autogenerated return type of DestroyAnnotation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyCommentPayload

Autogenerated return type of DestroyComment

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment_version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyContactPayload

Autogenerated return type of DestroyContact

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationAnalysisPayload

Autogenerated return type of DestroyDynamicAnnotationAnalysis

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationArchiveIsPayload

Autogenerated return type of DestroyDynamicAnnotationArchiveIs

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationArchiveOrgPayload

Autogenerated return type of DestroyDynamicAnnotationArchiveOrg

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationArchiverPayload

Autogenerated return type of DestroyDynamicAnnotationArchiver

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationEmbedCodePayload

Autogenerated return type of DestroyDynamicAnnotationEmbedCode

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationFlagPayload

Autogenerated return type of DestroyDynamicAnnotationFlag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationGeolocationPayload

Autogenerated return type of DestroyDynamicAnnotationGeolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationKeepBackupPayload

Autogenerated return type of DestroyDynamicAnnotationKeepBackup

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationLanguagePayload

Autogenerated return type of DestroyDynamicAnnotationLanguage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationMetadataPayload

Autogenerated return type of DestroyDynamicAnnotationMetadata

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationMetricsPayload

Autogenerated return type of DestroyDynamicAnnotationMetrics

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationPenderArchivePayload

Autogenerated return type of DestroyDynamicAnnotationPenderArchive

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationReportDesignPayload

Autogenerated return type of DestroyDynamicAnnotationReportDesign

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationReverseImagePayload

Autogenerated return type of DestroyDynamicAnnotationReverseImage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSlackMessagePayload

Autogenerated return type of DestroyDynamicAnnotationSlackMessage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSmoochPayload

Autogenerated return type of DestroyDynamicAnnotationSmooch

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSmoochResponsePayload

Autogenerated return type of DestroyDynamicAnnotationSmoochResponse

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSmoochUserPayload

Autogenerated return type of DestroyDynamicAnnotationSmoochUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSyrianArchiveDataPayload

Autogenerated return type of DestroyDynamicAnnotationSyrianArchiveData

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseDatetimePayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseDatetime

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseFreeTextPayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseFreeText

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseGeolocationPayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseGeolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseImageUploadPayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseImageUpload

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseMultipleChoicePayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseMultipleChoice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseSingleChoicePayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseSingleChoice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseYesNoPayload

Autogenerated return type of DestroyDynamicAnnotationTaskResponseYesNo

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskStatusPayload

Autogenerated return type of DestroyDynamicAnnotationTaskStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTattlePayload

Autogenerated return type of DestroyDynamicAnnotationTattle

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTeamBotResponsePayload

Autogenerated return type of DestroyDynamicAnnotationTeamBotResponse

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTranscriptPayload

Autogenerated return type of DestroyDynamicAnnotationTranscript

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationVerificationStatusPayload

Autogenerated return type of DestroyDynamicAnnotationVerificationStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicPayload

Autogenerated return type of DestroyDynamic

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectMediaPayload

Autogenerated return type of DestroyProjectMedia

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project_was</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_was</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>related_to</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_source</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_target</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectMediaProjectPayload

Autogenerated return type of DestroyProjectMediaProject

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectPayload

Autogenerated return type of DestroyProject

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectSourcePayload

Autogenerated return type of DestroyProjectSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyRelationshipPayload

Autogenerated return type of DestroyRelationship

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_source</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_target</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroySourcePayload

Autogenerated return type of DestroySource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTagPayload

Autogenerated return type of DestroyTag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text_object</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTagTextPayload

Autogenerated return type of DestroyTagText

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTaskPayload

Autogenerated return type of DestroyTask

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response_version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamBotInstallationPayload

Autogenerated return type of DestroyTeamBotInstallation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>bot_user</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamPayload

Autogenerated return type of DestroyTeam

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public_team</strong></td>
<td valign="top"><a href="#publicteam">PublicTeam</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamTaskPayload

Autogenerated return type of DestroyTeamTask

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamUserPayload

Autogenerated return type of DestroyTeamUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyUserPayload

Autogenerated return type of DestroyUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyVersionPayload

Autogenerated return type of DestroyVersion

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>deletedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### DynamicAnnotationField

DynamicAnnotation::Field type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotation</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### DynamicConnection

The connection type for Dynamic.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#dynamicedge">DynamicEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### DynamicEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_analysis

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_analysisEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_analysis">Dynamic_annotation_analysis</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_archive_is

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_archive_isEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_is">Dynamic_annotation_archive_is</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_archive_org

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_archive_orgEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_org">Dynamic_annotation_archive_org</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_archiver

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_archiverEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_archiver">Dynamic_annotation_archiver</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_embed_code

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_embed_codeEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_embed_code">Dynamic_annotation_embed_code</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_flag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_flagEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_flag">Dynamic_annotation_flag</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_geolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_geolocationEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_geolocation">Dynamic_annotation_geolocation</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_keep_backup

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_keep_backupEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_keep_backup">Dynamic_annotation_keep_backup</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_language

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_languageEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_language">Dynamic_annotation_language</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_metadata

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_metadataEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_metadata">Dynamic_annotation_metadata</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_metrics

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_metricsEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_metrics">Dynamic_annotation_metrics</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_pender_archive

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_pender_archiveEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_pender_archive">Dynamic_annotation_pender_archive</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_report_design

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_report_designEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_report_design">Dynamic_annotation_report_design</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_reverse_image

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_reverse_imageEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_reverse_image">Dynamic_annotation_reverse_image</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_slack_message

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_slack_messageEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_slack_message">Dynamic_annotation_slack_message</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_smooch

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_smoochEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch">Dynamic_annotation_smooch</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_smooch_response

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_smooch_responseEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_response">Dynamic_annotation_smooch_response</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_smooch_user

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_smooch_userEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_user">Dynamic_annotation_smooch_user</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_syrian_archive_data

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_syrian_archive_dataEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_syrian_archive_data">Dynamic_annotation_syrian_archive_data</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_datetime

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_datetimeEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_datetime">Dynamic_annotation_task_response_datetime</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_free_text

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_free_textEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_free_text">Dynamic_annotation_task_response_free_text</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_geolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_geolocationEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_geolocation">Dynamic_annotation_task_response_geolocation</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_image_upload

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_image_uploadEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_image_upload">Dynamic_annotation_task_response_image_upload</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_multiple_choice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_multiple_choiceEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_multiple_choice">Dynamic_annotation_task_response_multiple_choice</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_single_choice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_single_choiceEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_single_choice">Dynamic_annotation_task_response_single_choice</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_yes_no

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_response_yes_noEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_yes_no">Dynamic_annotation_task_response_yes_no</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_status

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_task_statusEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_status">Dynamic_annotation_task_status</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_tattle

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_tattleEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_tattle">Dynamic_annotation_tattle</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_team_bot_response

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_team_bot_responseEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_team_bot_response">Dynamic_annotation_team_bot_response</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_transcript

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_transcriptEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_transcript">Dynamic_annotation_transcript</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Dynamic_annotation_verification_status

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### Dynamic_annotation_verification_statusEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#dynamic_annotation_verification_status">Dynamic_annotation_verification_status</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### GenerateTwoFactorBackupCodesPayload

Autogenerated return type of GenerateTwoFactorBackupCodes

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>codes</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### ImportSpreadsheetPayload

Autogenerated return type of ImportSpreadsheet

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### Media

Media type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account</strong></td>
<td valign="top"><a href="#account">Account</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>account_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>domain</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>embed_path</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>file_path</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>metadata</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>picture</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>quote</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>thumbnail_path</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### MediaConnection

The connection type for Media.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#mediaedge">MediaEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### MediaEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#media">Media</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### PageInfo

Information about pagination in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>endCursor</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

When paginating forwards, the cursor to continue.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>hasNextPage</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

When paginating forwards, are there more items?

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>hasPreviousPage</strong></td>
<td valign="top"><a href="#boolean">Boolean</a>!</td>
<td>

When paginating backwards, are there more items?

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>startCursor</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

When paginating backwards, the cursor to continue.

</td>
</tr>
</tbody>
</table>

### Project

Project type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>assigned_users</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>auto_tasks</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>avatar</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_slack_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_sources</strong></td>
<td valign="top"><a href="#projectsourceconnection">ProjectSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>search</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>search_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sources</strong></td>
<td valign="top"><a href="#sourceconnection">SourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### ProjectConnection

The connection type for Project.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#projectedge">ProjectEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### ProjectEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### ProjectMedia

ProjectMedia type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account</strong></td>
<td valign="top"><a href="#account">Account</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>archived</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">user_id</td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>author_role</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comments</strong></td>
<td valign="top"><a href="#commentconnection">CommentConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>demand</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>domain</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_analysis</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_is</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_org</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archiver</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_embed_code</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_flag</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_geolocation</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_keep_backup</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_language</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metadata</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metrics</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_pender_archive</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_report_design</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_reverse_image</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_slack_message</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_response</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_user</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_syrian_archive_data</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_datetime</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_free_text</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_geolocation</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_image_upload</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_multiple_choice</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_single_choice</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_yes_no</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_status</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_tattle</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_team_bot_response</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_transcript</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_verification_status</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_analysis</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_archive_is</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_archive_org</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_archiver</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_embed_code</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_flag</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_geolocation</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_keep_backup</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_language</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_metadata</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_metrics</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_pender_archive</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_report_design</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_reverse_image</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_slack_message</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_smooch</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_smooch_response</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_smooch_user</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_syrian_archive_data</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_datetime</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_free_text</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_geolocation</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_image_upload</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_multiple_choice</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_single_choice</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_response_yes_no</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_task_status</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_tattle</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_team_bot_response</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_transcript</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotations_verification_status</strong></td>
<td valign="top"><a href="#dynamicconnection">DynamicConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>field_value</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type_field_name</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>language</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>language_code</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>last_seen</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>last_status</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>last_status_obj</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>linked_items_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>log</strong></td>
<td valign="top"><a href="#versionconnection">VersionConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">event_types</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">field_names</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_types</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">who_dunnit</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">include_related</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>log_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>media</strong></td>
<td valign="top"><a href="#media">Media</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>media_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>metadata</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>oembed_metadata</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>overridden</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>picture</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_ids</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projects</strong></td>
<td valign="top"><a href="#projectconnection">ProjectConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>published</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>quote</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationship</strong></td>
<td valign="top"><a href="#relationship">Relationship</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships</strong></td>
<td valign="top"><a href="#relationships">Relationships</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>report_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>requests_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>secondary_items</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">source_type</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">target_type</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>share_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tags</strong></td>
<td valign="top"><a href="#tagconnection">TagConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets_by_users</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tasks</strong></td>
<td valign="top"><a href="#taskconnection">TaskConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tasks_count</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>verification_statuses</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>virality</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### ProjectMediaConnection

The connection type for ProjectMedia.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#projectmediaedge">ProjectMediaEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### ProjectMediaEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### ProjectMediaProject

ProjectMediaProject type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### ProjectMediaProjectEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#projectmediaproject">ProjectMediaProject</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### ProjectSource

ProjectSource type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>published</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### ProjectSourceConnection

The connection type for ProjectSource.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#projectsourceedge">ProjectSourceEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### ProjectSourceEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### PublicTeam

Public team type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>avatar</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>private</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slug</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_graphql_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>trash_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>verification_statuses</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
</tbody>
</table>

### Relationship

A relationship between two items

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationship_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### RelationshipEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#relationship">Relationship</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Relationships

The sources and targets relationships of the project media

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sources</strong></td>
<td valign="top"><a href="#relationshipssourceconnection">RelationshipsSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sources_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets</strong></td>
<td valign="top"><a href="#relationshipstargetconnection">RelationshipsTargetConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">filters</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### RelationshipsSource

The source of a relationship

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationship_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>siblings</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### RelationshipsSourceConnection

The connection type for RelationshipsSource.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#relationshipssourceedge">RelationshipsSourceEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### RelationshipsSourceEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### RelationshipsTarget

The targets of a relationship

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>targets</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### RelationshipsTargetConnection

The connection type for RelationshipsTarget.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#relationshipstargetedge">RelationshipsTargetEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### RelationshipsTargetEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### ResendCancelInvitationPayload

Autogenerated return type of ResendCancelInvitation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### ResendConfirmationPayload

Autogenerated return type of ResendConfirmation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### ResetPasswordPayload

Autogenerated return type of ResetPassword

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>expiry</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### RootLevel

Unassociated root object queries

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account_sources</strong></td>
<td valign="top"><a href="#accountsourceconnection">AccountSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>accounts</strong></td>
<td valign="top"><a href="#accountconnection">AccountConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comments</strong></td>
<td valign="top"><a href="#commentconnection">CommentConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contacts</strong></td>
<td valign="top"><a href="#contactconnection">ContactConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#mediaconnection">MediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_sources</strong></td>
<td valign="top"><a href="#projectsourceconnection">ProjectSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projects</strong></td>
<td valign="top"><a href="#projectconnection">ProjectConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sources</strong></td>
<td valign="top"><a href="#sourceconnection">SourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tags</strong></td>
<td valign="top"><a href="#tagconnection">TagConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bots_approved</strong></td>
<td valign="top"><a href="#botuserconnection">BotUserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_users</strong></td>
<td valign="top"><a href="#teamuserconnection">TeamUserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teams</strong></td>
<td valign="top"><a href="#teamconnection">TeamConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>users</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
</tbody>
</table>

### SmoochBotAddSlackChannelUrlPayload

Autogenerated return type of SmoochBotAddSlackChannelUrl

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotation</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### Source

Source type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account_sources</strong></td>
<td valign="top"><a href="#accountsourceconnection">AccountSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>accounts</strong></td>
<td valign="top"><a href="#accountconnection">AccountConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>accounts_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_type</td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>collaborators</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>log</strong></td>
<td valign="top"><a href="#versionconnection">VersionConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">event_types</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">field_names</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">annotation_types</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">who_dunnit</td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">include_related</td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>log_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>overridden</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_sources</strong></td>
<td valign="top"><a href="#projectsourceconnection">ProjectSourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projects</strong></td>
<td valign="top"><a href="#projectconnection">ProjectConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tags</strong></td>
<td valign="top"><a href="#tagconnection">TagConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### SourceConnection

The connection type for Source.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#sourceedge">SourceEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### SourceEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Tag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text_object</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### TagConnection

The connection type for Tag.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#tagedge">TagEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TagEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#tag">Tag</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### TagText

Tag text type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tags_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teamwide</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### TagTextConnection

The connection type for TagText.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#tagtextedge">TagTextEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TagTextEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Task

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotator</strong></td>
<td valign="top"><a href="#annotator">Annotator</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response_value</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>image_data</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>jsonoptions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>label</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>log</strong></td>
<td valign="top"><a href="#versionconnection">VersionConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>log_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>options</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>parsed_fragment</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pending_suggestions_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>responses</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>suggestions_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_task_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
</tbody>
</table>

### TaskConnection

The connection type for Task.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#taskedge">TaskEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TaskEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### Team

Team type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>archived</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>avatar</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contacts</strong></td>
<td valign="top"><a href="#contactconnection">ContactConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>custom_tags</strong></td>
<td valign="top"><a href="#tagtextconnection">TagTextConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_search_fields_json_schema</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_disclaimer</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_embed_whitelist</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_introduction</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_languages</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_max_number_of_members</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_report_design_image_template</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_rules</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_slack_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_slack_notifications_enabled</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_slack_webhook</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_status_target_turnaround</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_suggested_tags</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_use_disclaimer</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_use_introduction</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>invited_mails</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>join_requests</strong></td>
<td valign="top"><a href="#teamuserconnection">TeamUserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>medias_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>members_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions_info</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>private</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projects</strong></td>
<td valign="top"><a href="#projectconnection">ProjectConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projects_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public_team</strong></td>
<td valign="top"><a href="#publicteam">PublicTeam</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public_team_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pusher_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>rules_json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>rules_search_fields_json_schema</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>search</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>search_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slug</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sources</strong></td>
<td valign="top"><a href="#sourceconnection">SourceConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bot_installations</strong></td>
<td valign="top"><a href="#teambotinstallationconnection">TeamBotInstallationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bots</strong></td>
<td valign="top"><a href="#botuserconnection">BotUserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_tasks</strong></td>
<td valign="top"><a href="#teamtaskconnection">TeamTaskConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_users</strong></td>
<td valign="top"><a href="#teamuserconnection">TeamUserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teamwide_tags</strong></td>
<td valign="top"><a href="#tagtextconnection">TagTextConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>trash_count</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>trash_size</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>used_tags</strong></td>
<td valign="top">[<a href="#string">String</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>users</strong></td>
<td valign="top"><a href="#userconnection">UserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>verification_statuses</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
</tbody>
</table>

### TeamBotInstallation

Team Bot Installation type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>bot_user</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_settings</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### TeamBotInstallationConnection

The connection type for TeamBotInstallation.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#teambotinstallationedge">TeamBotInstallationEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TeamBotInstallationEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#teambotinstallation">TeamBotInstallation</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### TeamConnection

The connection type for Team.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#teamedge">TeamEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TeamEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### TeamTask

Team task type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>label</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>options</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_ids</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>required</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### TeamTaskConnection

The connection type for TeamTask.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#teamtaskedge">TeamTaskEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TeamTaskEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#teamtask">TeamTask</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### TeamUser

TeamUser type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>role</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### TeamUserConnection

The connection type for TeamUser.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#teamuseredge">TeamUserEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### TeamUserEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#teamuser">TeamUser</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### UpdateAccountPayload

Autogenerated return type of UpdateAccount

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account</strong></td>
<td valign="top"><a href="#account">Account</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>accountEdge</strong></td>
<td valign="top"><a href="#accountedge">AccountEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
</tbody>
</table>

### UpdateAccountSourcePayload

Autogenerated return type of UpdateAccountSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>account_source</strong></td>
<td valign="top"><a href="#accountsource">AccountSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>account_sourceEdge</strong></td>
<td valign="top"><a href="#accountsourceedge">AccountSourceEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateCommentPayload

Autogenerated return type of UpdateComment

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment</strong></td>
<td valign="top"><a href="#comment">Comment</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>commentEdge</strong></td>
<td valign="top"><a href="#commentedge">CommentEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment_version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>comment_versionEdge</strong></td>
<td valign="top"><a href="#versionedge">VersionEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateContactPayload

Autogenerated return type of UpdateContact

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contact</strong></td>
<td valign="top"><a href="#contact">Contact</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contactEdge</strong></td>
<td valign="top"><a href="#contactedge">ContactEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationAnalysisPayload

Autogenerated return type of UpdateDynamicAnnotationAnalysis

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_analysis</strong></td>
<td valign="top"><a href="#dynamic_annotation_analysis">Dynamic_annotation_analysis</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_analysisEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_analysisedge">Dynamic_annotation_analysisEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationArchiveIsPayload

Autogenerated return type of UpdateDynamicAnnotationArchiveIs

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_is</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_is">Dynamic_annotation_archive_is</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_isEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_isedge">Dynamic_annotation_archive_isEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationArchiveOrgPayload

Autogenerated return type of UpdateDynamicAnnotationArchiveOrg

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_org</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_org">Dynamic_annotation_archive_org</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archive_orgEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_archive_orgedge">Dynamic_annotation_archive_orgEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationArchiverPayload

Autogenerated return type of UpdateDynamicAnnotationArchiver

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archiver</strong></td>
<td valign="top"><a href="#dynamic_annotation_archiver">Dynamic_annotation_archiver</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_archiverEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_archiveredge">Dynamic_annotation_archiverEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationEmbedCodePayload

Autogenerated return type of UpdateDynamicAnnotationEmbedCode

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_embed_code</strong></td>
<td valign="top"><a href="#dynamic_annotation_embed_code">Dynamic_annotation_embed_code</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_embed_codeEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_embed_codeedge">Dynamic_annotation_embed_codeEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationFlagPayload

Autogenerated return type of UpdateDynamicAnnotationFlag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_flag</strong></td>
<td valign="top"><a href="#dynamic_annotation_flag">Dynamic_annotation_flag</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_flagEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_flagedge">Dynamic_annotation_flagEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationGeolocationPayload

Autogenerated return type of UpdateDynamicAnnotationGeolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_geolocation</strong></td>
<td valign="top"><a href="#dynamic_annotation_geolocation">Dynamic_annotation_geolocation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_geolocationEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_geolocationedge">Dynamic_annotation_geolocationEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationKeepBackupPayload

Autogenerated return type of UpdateDynamicAnnotationKeepBackup

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_keep_backup</strong></td>
<td valign="top"><a href="#dynamic_annotation_keep_backup">Dynamic_annotation_keep_backup</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_keep_backupEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_keep_backupedge">Dynamic_annotation_keep_backupEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationLanguagePayload

Autogenerated return type of UpdateDynamicAnnotationLanguage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_language</strong></td>
<td valign="top"><a href="#dynamic_annotation_language">Dynamic_annotation_language</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_languageEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_languageedge">Dynamic_annotation_languageEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationMetadataPayload

Autogenerated return type of UpdateDynamicAnnotationMetadata

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metadata</strong></td>
<td valign="top"><a href="#dynamic_annotation_metadata">Dynamic_annotation_metadata</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metadataEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_metadataedge">Dynamic_annotation_metadataEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationMetricsPayload

Autogenerated return type of UpdateDynamicAnnotationMetrics

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metrics</strong></td>
<td valign="top"><a href="#dynamic_annotation_metrics">Dynamic_annotation_metrics</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_metricsEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_metricsedge">Dynamic_annotation_metricsEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationPenderArchivePayload

Autogenerated return type of UpdateDynamicAnnotationPenderArchive

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_pender_archive</strong></td>
<td valign="top"><a href="#dynamic_annotation_pender_archive">Dynamic_annotation_pender_archive</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_pender_archiveEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_pender_archiveedge">Dynamic_annotation_pender_archiveEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationReportDesignPayload

Autogenerated return type of UpdateDynamicAnnotationReportDesign

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_report_design</strong></td>
<td valign="top"><a href="#dynamic_annotation_report_design">Dynamic_annotation_report_design</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_report_designEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_report_designedge">Dynamic_annotation_report_designEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationReverseImagePayload

Autogenerated return type of UpdateDynamicAnnotationReverseImage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_reverse_image</strong></td>
<td valign="top"><a href="#dynamic_annotation_reverse_image">Dynamic_annotation_reverse_image</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_reverse_imageEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_reverse_imageedge">Dynamic_annotation_reverse_imageEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSlackMessagePayload

Autogenerated return type of UpdateDynamicAnnotationSlackMessage

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_slack_message</strong></td>
<td valign="top"><a href="#dynamic_annotation_slack_message">Dynamic_annotation_slack_message</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_slack_messageEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_slack_messageedge">Dynamic_annotation_slack_messageEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSmoochPayload

Autogenerated return type of UpdateDynamicAnnotationSmooch

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch">Dynamic_annotation_smooch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smoochEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_smoochedge">Dynamic_annotation_smoochEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSmoochResponsePayload

Autogenerated return type of UpdateDynamicAnnotationSmoochResponse

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_response</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_response">Dynamic_annotation_smooch_response</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_responseEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_responseedge">Dynamic_annotation_smooch_responseEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSmoochUserPayload

Autogenerated return type of UpdateDynamicAnnotationSmoochUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_user</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_user">Dynamic_annotation_smooch_user</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_smooch_userEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_smooch_useredge">Dynamic_annotation_smooch_userEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSyrianArchiveDataPayload

Autogenerated return type of UpdateDynamicAnnotationSyrianArchiveData

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_syrian_archive_data</strong></td>
<td valign="top"><a href="#dynamic_annotation_syrian_archive_data">Dynamic_annotation_syrian_archive_data</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_syrian_archive_dataEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_syrian_archive_dataedge">Dynamic_annotation_syrian_archive_dataEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseDatetimePayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseDatetime

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_datetime</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_datetime">Dynamic_annotation_task_response_datetime</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_datetimeEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_datetimeedge">Dynamic_annotation_task_response_datetimeEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseFreeTextPayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseFreeText

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_free_text</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_free_text">Dynamic_annotation_task_response_free_text</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_free_textEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_free_textedge">Dynamic_annotation_task_response_free_textEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseGeolocationPayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseGeolocation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_geolocation</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_geolocation">Dynamic_annotation_task_response_geolocation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_geolocationEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_geolocationedge">Dynamic_annotation_task_response_geolocationEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseImageUploadPayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseImageUpload

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_image_upload</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_image_upload">Dynamic_annotation_task_response_image_upload</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_image_uploadEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_image_uploadedge">Dynamic_annotation_task_response_image_uploadEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseMultipleChoicePayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseMultipleChoice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_multiple_choice</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_multiple_choice">Dynamic_annotation_task_response_multiple_choice</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_multiple_choiceEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_multiple_choiceedge">Dynamic_annotation_task_response_multiple_choiceEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseSingleChoicePayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseSingleChoice

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_single_choice</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_single_choice">Dynamic_annotation_task_response_single_choice</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_single_choiceEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_single_choiceedge">Dynamic_annotation_task_response_single_choiceEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseYesNoPayload

Autogenerated return type of UpdateDynamicAnnotationTaskResponseYesNo

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_yes_no</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_yes_no">Dynamic_annotation_task_response_yes_no</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_response_yes_noEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_response_yes_noedge">Dynamic_annotation_task_response_yes_noEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskStatusPayload

Autogenerated return type of UpdateDynamicAnnotationTaskStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_status</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_status">Dynamic_annotation_task_status</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_task_statusEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_task_statusedge">Dynamic_annotation_task_statusEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTattlePayload

Autogenerated return type of UpdateDynamicAnnotationTattle

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_tattle</strong></td>
<td valign="top"><a href="#dynamic_annotation_tattle">Dynamic_annotation_tattle</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_tattleEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_tattleedge">Dynamic_annotation_tattleEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTeamBotResponsePayload

Autogenerated return type of UpdateDynamicAnnotationTeamBotResponse

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_team_bot_response</strong></td>
<td valign="top"><a href="#dynamic_annotation_team_bot_response">Dynamic_annotation_team_bot_response</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_team_bot_responseEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_team_bot_responseedge">Dynamic_annotation_team_bot_responseEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTranscriptPayload

Autogenerated return type of UpdateDynamicAnnotationTranscript

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_transcript</strong></td>
<td valign="top"><a href="#dynamic_annotation_transcript">Dynamic_annotation_transcript</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_transcriptEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_transcriptedge">Dynamic_annotation_transcriptEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationVerificationStatusPayload

Autogenerated return type of UpdateDynamicAnnotationVerificationStatus

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_verification_status</strong></td>
<td valign="top"><a href="#dynamic_annotation_verification_status">Dynamic_annotation_verification_status</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic_annotation_verification_statusEdge</strong></td>
<td valign="top"><a href="#dynamic_annotation_verification_statusedge">Dynamic_annotation_verification_statusEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicPayload

Autogenerated return type of UpdateDynamic

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamic</strong></td>
<td valign="top"><a href="#dynamic">Dynamic</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dynamicEdge</strong></td>
<td valign="top"><a href="#dynamicedge">DynamicEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateProjectMediaPayload

Autogenerated return type of UpdateProjectMedia

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedId</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project_was</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_mediaEdge</strong></td>
<td valign="top"><a href="#projectmediaedge">ProjectMediaEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_was</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>related_to</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_source</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_target</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateProjectPayload

Autogenerated return type of UpdateProject

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projectEdge</strong></td>
<td valign="top"><a href="#projectedge">ProjectEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateProjectSourcePayload

Autogenerated return type of UpdateProjectSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_project</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_sourceEdge</strong></td>
<td valign="top"><a href="#projectsourceedge">ProjectSourceEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateRelationshipPayload

Autogenerated return type of UpdateRelationship

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationship</strong></td>
<td valign="top"><a href="#relationship">Relationship</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationshipEdge</strong></td>
<td valign="top"><a href="#relationshipedge">RelationshipEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_source</strong></td>
<td valign="top"><a href="#relationshipssource">RelationshipsSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationships_target</strong></td>
<td valign="top"><a href="#relationshipstarget">RelationshipsTarget</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateSourcePayload

Autogenerated return type of UpdateSource

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>sourceEdge</strong></td>
<td valign="top"><a href="#sourceedge">SourceEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTagPayload

Autogenerated return type of UpdateTag

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_source</strong></td>
<td valign="top"><a href="#projectsource">ProjectSource</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#tag">Tag</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tagEdge</strong></td>
<td valign="top"><a href="#tagedge">TagEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text_object</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTagTextPayload

Autogenerated return type of UpdateTagText

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_text</strong></td>
<td valign="top"><a href="#tagtext">TagText</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag_textEdge</strong></td>
<td valign="top"><a href="#tagtextedge">TagTextEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTaskPayload

Autogenerated return type of UpdateTask

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response_version</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>first_response_versionEdge</strong></td>
<td valign="top"><a href="#versionedge">VersionEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media</strong></td>
<td valign="top"><a href="#projectmedia">ProjectMedia</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>taskEdge</strong></td>
<td valign="top"><a href="#taskedge">TaskEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamBotInstallationPayload

Autogenerated return type of UpdateTeamBotInstallation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>bot_user</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bot_installation</strong></td>
<td valign="top"><a href="#teambotinstallation">TeamBotInstallation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_bot_installationEdge</strong></td>
<td valign="top"><a href="#teambotinstallationedge">TeamBotInstallationEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamPayload

Autogenerated return type of UpdateTeam

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_team</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>check_search_trash</strong></td>
<td valign="top"><a href="#checksearch">CheckSearch</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>public_team</strong></td>
<td valign="top"><a href="#publicteam">PublicTeam</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teamEdge</strong></td>
<td valign="top"><a href="#teamedge">TeamEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_userEdge</strong></td>
<td valign="top"><a href="#teamuseredge">TeamUserEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamTaskPayload

Autogenerated return type of UpdateTeamTask

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_task</strong></td>
<td valign="top"><a href="#teamtask">TeamTask</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_taskEdge</strong></td>
<td valign="top"><a href="#teamtaskedge">TeamTaskEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamUserPayload

Autogenerated return type of UpdateTeamUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_user</strong></td>
<td valign="top"><a href="#teamuser">TeamUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_userEdge</strong></td>
<td valign="top"><a href="#teamuseredge">TeamUserEdge</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateUserPayload

Autogenerated return type of UpdateUser

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>affectedIds</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>userEdge</strong></td>
<td valign="top"><a href="#useredge">UserEdge</a></td>
<td></td>
</tr>
</tbody>
</table>

### User

User type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>accepted_terms</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotations</strong></td>
<td valign="top"><a href="#annotationconnection">AnnotationConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">type</td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assignments</strong></td>
<td valign="top"><a href="#projectmediaconnection">ProjectMediaConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">team_id</td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>bot</strong></td>
<td valign="top"><a href="#botuser">BotUser</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>bot_events</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>confirmed</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_project</strong></td>
<td valign="top"><a href="#project">Project</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_send_email_notifications</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_send_failed_login_notifications</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>get_send_successful_login_notifications</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>is_active</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>is_admin</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>is_bot</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>jsonsettings</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>last_accepted_terms_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>login</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>number_of_teams</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>profile_image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>providers</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>settings</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source</strong></td>
<td valign="top"><a href="#source">Source</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_ids</strong></td>
<td valign="top">[<a href="#int">Int</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_users</strong></td>
<td valign="top"><a href="#teamuserconnection">TeamUserConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teams</strong></td>
<td valign="top"><a href="#teamconnection">TeamConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>token</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>two_factor</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>unconfirmed_email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_teams</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>uuid</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UserConnection

The connection type for User.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#useredge">UserEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### UserDisconnectLoginAccountPayload

Autogenerated return type of UserDisconnectLoginAccount

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### UserEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

### UserInvitationPayload

Autogenerated return type of UserInvitation

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team</strong></td>
<td valign="top"><a href="#team">Team</a></td>
<td></td>
</tr>
</tbody>
</table>

### UserTwoFactorAuthenticationPayload

Autogenerated return type of UserTwoFactorAuthentication

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>success</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### Version

Version type

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>annotation</strong></td>
<td valign="top"><a href="#annotation">Annotation</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>associated_graphql_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>created_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>dbid</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>event</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>event_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>item_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>item_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>meta</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>object_after</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>object_changes_json</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>permissions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>projects</strong></td>
<td valign="top"><a href="#projectconnection">ProjectConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>smooch_user_slack_channel_url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#tag">Tag</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task</strong></td>
<td valign="top"><a href="#task">Task</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teams</strong></td>
<td valign="top"><a href="#teamconnection">TeamConnection</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">first</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the first _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">after</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come after the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">last</td>
<td valign="top"><a href="#int">Int</a></td>
<td>

Returns the last _n_ elements from the list.

</td>
</tr>
<tr>
<td colspan="2" align="right" valign="top">before</td>
<td valign="top"><a href="#string">String</a></td>
<td>

Returns the elements in the list that come before the specified global ID.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>updated_at</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user</strong></td>
<td valign="top"><a href="#user">User</a></td>
<td></td>
</tr>
</tbody>
</table>

### VersionConnection

The connection type for Version.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>edges</strong></td>
<td valign="top">[<a href="#versionedge">VersionEdge</a>]</td>
<td>

A list of edges.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>pageInfo</strong></td>
<td valign="top"><a href="#pageinfo">PageInfo</a>!</td>
<td>

Information to aid in pagination.

</td>
</tr>
</tbody>
</table>

### VersionEdge

An edge in a connection.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>cursor</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td>

A cursor for use in pagination.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>node</strong></td>
<td valign="top"><a href="#version">Version</a></td>
<td>

The item at the end of the edge.

</td>
</tr>
</tbody>
</table>

## Inputs

### ChangePasswordInput

Autogenerated input type of ChangePassword

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password_confirmation</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>reset_password_token</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_password</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateAccountSourceInput

Autogenerated input type of CreateAccountSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>account_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateAnnotationInput

Autogenerated input type of CreateAnnotation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>content</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateCommentInput

Autogenerated input type of CreateComment

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateContactInput

Autogenerated input type of CreateContact

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>location</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>phone</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>web</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationAnalysisInput

Autogenerated input type of CreateDynamicAnnotationAnalysis

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationArchiveIsInput

Autogenerated input type of CreateDynamicAnnotationArchiveIs

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationArchiveOrgInput

Autogenerated input type of CreateDynamicAnnotationArchiveOrg

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationArchiverInput

Autogenerated input type of CreateDynamicAnnotationArchiver

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationEmbedCodeInput

Autogenerated input type of CreateDynamicAnnotationEmbedCode

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationFlagInput

Autogenerated input type of CreateDynamicAnnotationFlag

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationGeolocationInput

Autogenerated input type of CreateDynamicAnnotationGeolocation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationKeepBackupInput

Autogenerated input type of CreateDynamicAnnotationKeepBackup

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationLanguageInput

Autogenerated input type of CreateDynamicAnnotationLanguage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationMetadataInput

Autogenerated input type of CreateDynamicAnnotationMetadata

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationMetricsInput

Autogenerated input type of CreateDynamicAnnotationMetrics

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationPenderArchiveInput

Autogenerated input type of CreateDynamicAnnotationPenderArchive

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationReportDesignInput

Autogenerated input type of CreateDynamicAnnotationReportDesign

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationReverseImageInput

Autogenerated input type of CreateDynamicAnnotationReverseImage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSlackMessageInput

Autogenerated input type of CreateDynamicAnnotationSlackMessage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSmoochInput

Autogenerated input type of CreateDynamicAnnotationSmooch

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSmoochResponseInput

Autogenerated input type of CreateDynamicAnnotationSmoochResponse

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSmoochUserInput

Autogenerated input type of CreateDynamicAnnotationSmoochUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationSyrianArchiveDataInput

Autogenerated input type of CreateDynamicAnnotationSyrianArchiveData

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseDatetimeInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseDatetime

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseFreeTextInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseFreeText

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseGeolocationInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseGeolocation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseImageUploadInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseImageUpload

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseMultipleChoiceInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseMultipleChoice

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseSingleChoiceInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseSingleChoice

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskResponseYesNoInput

Autogenerated input type of CreateDynamicAnnotationTaskResponseYesNo

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTaskStatusInput

Autogenerated input type of CreateDynamicAnnotationTaskStatus

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTattleInput

Autogenerated input type of CreateDynamicAnnotationTattle

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTeamBotResponseInput

Autogenerated input type of CreateDynamicAnnotationTeamBotResponse

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationTranscriptInput

Autogenerated input type of CreateDynamicAnnotationTranscript

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicAnnotationVerificationStatusInput

Autogenerated input type of CreateDynamicAnnotationVerificationStatus

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateDynamicInput

Autogenerated input type of CreateDynamic

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectInput

Autogenerated input type of CreateProject

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lead_image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectMediaInput

Autogenerated input type of CreateProjectMedia

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>media_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>related_to_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>quote</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>quote_attributions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_annotation</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_tasks_responses</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>media_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectMediaProjectInput

Autogenerated input type of CreateProjectMediaProject

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateProjectSourceInput

Autogenerated input type of CreateProjectSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>url</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateRelationshipInput

Autogenerated input type of CreateRelationship

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>relationship_type</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateSourceInput

Autogenerated input type of CreateSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>avatar</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slogan</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTagInput

Autogenerated input type of CreateTag

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateTagTextInput

Autogenerated input type of CreateTagText

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teamwide</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateTagsInput

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateTaskInput

Autogenerated input type of CreateTask

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>label</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>type</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>jsonoptions</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamBotInstallationInput

Autogenerated input type of CreateTeamBotInstallation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamInput

Autogenerated input type of CreateTeam

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>archived</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>private</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slug</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contact</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamTaskInput

Autogenerated input type of CreateTeamTask

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>label</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_options</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_project_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>keep_completed_tasks</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### CreateTeamUserInput

Autogenerated input type of CreateTeamUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>role</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### CreateUserInput

Autogenerated input type of CreateUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>profile_image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>login</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password_confirmation</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### DeleteCheckUserInput

Autogenerated input type of DeleteCheckUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyAccountSourceInput

Autogenerated input type of DestroyAccountSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyAnnotationInput

Autogenerated input type of DestroyAnnotation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyCommentInput

Autogenerated input type of DestroyComment

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyContactInput

Autogenerated input type of DestroyContact

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationAnalysisInput

Autogenerated input type of DestroyDynamicAnnotationAnalysis

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationArchiveIsInput

Autogenerated input type of DestroyDynamicAnnotationArchiveIs

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationArchiveOrgInput

Autogenerated input type of DestroyDynamicAnnotationArchiveOrg

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationArchiverInput

Autogenerated input type of DestroyDynamicAnnotationArchiver

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationEmbedCodeInput

Autogenerated input type of DestroyDynamicAnnotationEmbedCode

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationFlagInput

Autogenerated input type of DestroyDynamicAnnotationFlag

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationGeolocationInput

Autogenerated input type of DestroyDynamicAnnotationGeolocation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationKeepBackupInput

Autogenerated input type of DestroyDynamicAnnotationKeepBackup

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationLanguageInput

Autogenerated input type of DestroyDynamicAnnotationLanguage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationMetadataInput

Autogenerated input type of DestroyDynamicAnnotationMetadata

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationMetricsInput

Autogenerated input type of DestroyDynamicAnnotationMetrics

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationPenderArchiveInput

Autogenerated input type of DestroyDynamicAnnotationPenderArchive

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationReportDesignInput

Autogenerated input type of DestroyDynamicAnnotationReportDesign

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationReverseImageInput

Autogenerated input type of DestroyDynamicAnnotationReverseImage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSlackMessageInput

Autogenerated input type of DestroyDynamicAnnotationSlackMessage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSmoochInput

Autogenerated input type of DestroyDynamicAnnotationSmooch

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSmoochResponseInput

Autogenerated input type of DestroyDynamicAnnotationSmoochResponse

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSmoochUserInput

Autogenerated input type of DestroyDynamicAnnotationSmoochUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationSyrianArchiveDataInput

Autogenerated input type of DestroyDynamicAnnotationSyrianArchiveData

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseDatetimeInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseDatetime

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseFreeTextInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseFreeText

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseGeolocationInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseGeolocation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseImageUploadInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseImageUpload

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseMultipleChoiceInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseMultipleChoice

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseSingleChoiceInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseSingleChoice

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskResponseYesNoInput

Autogenerated input type of DestroyDynamicAnnotationTaskResponseYesNo

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTaskStatusInput

Autogenerated input type of DestroyDynamicAnnotationTaskStatus

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTattleInput

Autogenerated input type of DestroyDynamicAnnotationTattle

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTeamBotResponseInput

Autogenerated input type of DestroyDynamicAnnotationTeamBotResponse

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationTranscriptInput

Autogenerated input type of DestroyDynamicAnnotationTranscript

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicAnnotationVerificationStatusInput

Autogenerated input type of DestroyDynamicAnnotationVerificationStatus

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyDynamicInput

Autogenerated input type of DestroyDynamic

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectInput

Autogenerated input type of DestroyProject

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectMediaInput

Autogenerated input type of DestroyProjectMedia

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectMediaProjectInput

Autogenerated input type of DestroyProjectMediaProject

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_media_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyProjectSourceInput

Autogenerated input type of DestroyProjectSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyRelationshipInput

Autogenerated input type of DestroyRelationship

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroySourceInput

Autogenerated input type of DestroySource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTagInput

Autogenerated input type of DestroyTag

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTagTextInput

Autogenerated input type of DestroyTagText

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTaskInput

Autogenerated input type of DestroyTask

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamBotInstallationInput

Autogenerated input type of DestroyTeamBotInstallation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamInput

Autogenerated input type of DestroyTeam

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamTaskInput

Autogenerated input type of DestroyTeamTask

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>keep_completed_tasks</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### DestroyTeamUserInput

Autogenerated input type of DestroyTeamUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyUserInput

Autogenerated input type of DestroyUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### DestroyVersionInput

Autogenerated input type of DestroyVersion

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
</tbody>
</table>

### GenerateTwoFactorBackupCodesInput

Autogenerated input type of GenerateTwoFactorBackupCodes

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### ImportSpreadsheetInput

Autogenerated input type of ImportSpreadsheet

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>spreadsheet_url</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### ResendCancelInvitationInput

Autogenerated input type of ResendCancelInvitation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### ResendConfirmationInput

Autogenerated input type of ResendConfirmation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### ResetPasswordInput

Autogenerated input type of ResetPassword

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### SmoochBotAddSlackChannelUrlInput

Autogenerated input type of SmoochBotAddSlackChannelUrl

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### UpdateAccountInput

Autogenerated input type of UpdateAccount

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>refresh_account</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateAccountSourceInput

Autogenerated input type of UpdateAccountSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>account_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateCommentInput

Autogenerated input type of UpdateComment

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateContactInput

Autogenerated input type of UpdateContact

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>location</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>phone</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>web</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationAnalysisInput

Autogenerated input type of UpdateDynamicAnnotationAnalysis

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationArchiveIsInput

Autogenerated input type of UpdateDynamicAnnotationArchiveIs

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationArchiveOrgInput

Autogenerated input type of UpdateDynamicAnnotationArchiveOrg

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationArchiverInput

Autogenerated input type of UpdateDynamicAnnotationArchiver

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationEmbedCodeInput

Autogenerated input type of UpdateDynamicAnnotationEmbedCode

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationFlagInput

Autogenerated input type of UpdateDynamicAnnotationFlag

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationGeolocationInput

Autogenerated input type of UpdateDynamicAnnotationGeolocation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationKeepBackupInput

Autogenerated input type of UpdateDynamicAnnotationKeepBackup

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationLanguageInput

Autogenerated input type of UpdateDynamicAnnotationLanguage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationMetadataInput

Autogenerated input type of UpdateDynamicAnnotationMetadata

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationMetricsInput

Autogenerated input type of UpdateDynamicAnnotationMetrics

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationPenderArchiveInput

Autogenerated input type of UpdateDynamicAnnotationPenderArchive

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationReportDesignInput

Autogenerated input type of UpdateDynamicAnnotationReportDesign

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationReverseImageInput

Autogenerated input type of UpdateDynamicAnnotationReverseImage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSlackMessageInput

Autogenerated input type of UpdateDynamicAnnotationSlackMessage

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSmoochInput

Autogenerated input type of UpdateDynamicAnnotationSmooch

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSmoochResponseInput

Autogenerated input type of UpdateDynamicAnnotationSmoochResponse

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSmoochUserInput

Autogenerated input type of UpdateDynamicAnnotationSmoochUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationSyrianArchiveDataInput

Autogenerated input type of UpdateDynamicAnnotationSyrianArchiveData

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseDatetimeInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseDatetime

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseFreeTextInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseFreeText

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseGeolocationInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseGeolocation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseImageUploadInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseImageUpload

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseMultipleChoiceInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseMultipleChoice

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseSingleChoiceInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseSingleChoice

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskResponseYesNoInput

Autogenerated input type of UpdateDynamicAnnotationTaskResponseYesNo

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTaskStatusInput

Autogenerated input type of UpdateDynamicAnnotationTaskStatus

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTattleInput

Autogenerated input type of UpdateDynamicAnnotationTattle

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTeamBotResponseInput

Autogenerated input type of UpdateDynamicAnnotationTeamBotResponse

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationTranscriptInput

Autogenerated input type of UpdateDynamicAnnotationTranscript

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicAnnotationVerificationStatusInput

Autogenerated input type of UpdateDynamicAnnotationVerificationStatus

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>action_data</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateDynamicInput

Autogenerated input type of UpdateDynamic

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_attribution</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_fields</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotation_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>locked</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateProjectInput

Autogenerated input type of UpdateProject

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lead_image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>title</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_slack_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>information</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateProjectMediaInput

Autogenerated input type of UpdateProjectMedia

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>media_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>related_to_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>previous_project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>copy_to_project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>add_to_project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>remove_from_project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>refresh_media</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>archived</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>metadata</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateProjectSourceInput

Autogenerated input type of UpdateProjectSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateRelationshipInput

Autogenerated input type of UpdateRelationship

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>source_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>target_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateSourceInput

Autogenerated input type of UpdateSource

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>avatar</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slogan</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>refresh_accounts</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>lock_version</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTagInput

Autogenerated input type of UpdateTag

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>fragment</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_id</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>annotated_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>tag</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTagTextInput

Autogenerated input type of UpdateTagText

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>teamwide</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>text</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTaskInput

Autogenerated input type of UpdateTask

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>label</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>response</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>accept_suggestion</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>reject_suggestion</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>assigned_to_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamBotInstallationInput

Autogenerated input type of UpdateTeamBotInstallation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_settings</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamInput

Autogenerated input type of UpdateTeam

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>archived</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>private</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slack_notifications_enabled</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slack_webhook</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>slack_channel</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>add_auto_task</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>add_media_verification_statuses</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>set_team_tasks</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>rules</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>disclaimer</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>introduction</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>use_disclaimer</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>use_introduction</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>remove_auto_task</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>contact</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>empty_trash</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamTaskInput

Autogenerated input type of UpdateTeamTask

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>label</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>task_type</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>description</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_options</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_project_ids</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>json_schema</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>keep_completed_tasks</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateTeamUserInput

Autogenerated input type of UpdateTeamUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>user_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>status</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>role</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
</tbody>
</table>

### UpdateUserInput

Autogenerated input type of UpdateUser

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>ids</strong></td>
<td valign="top">[<a href="#id">ID</a>]</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>no_freeze</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>email</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>profile_image</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>name</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_team_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>current_project_id</strong></td>
<td valign="top"><a href="#int">Int</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password_confirmation</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>send_email_notifications</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>send_successful_login_notifications</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>send_failed_login_notifications</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>accept_terms</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

### UserDisconnectLoginAccountInput

Autogenerated input type of UserDisconnectLoginAccount

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>provider</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>uid</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### UserInvitationInput

Autogenerated input type of UserInvitation

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>invitation</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>members</strong></td>
<td valign="top"><a href="#jsonstringtype">JsonStringType</a>!</td>
<td></td>
</tr>
</tbody>
</table>

### UserTwoFactorAuthenticationInput

Autogenerated input type of UserTwoFactorAuthentication

<table>
<thead>
<tr>
<th colspan="2" align="left">Field</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>clientMutationId</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td>

A unique identifier for the client performing the mutation.

</td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#int">Int</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>password</strong></td>
<td valign="top"><a href="#string">String</a>!</td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>qrcode</strong></td>
<td valign="top"><a href="#string">String</a></td>
<td></td>
</tr>
<tr>
<td colspan="2" valign="top"><strong>otp_required</strong></td>
<td valign="top"><a href="#boolean">Boolean</a></td>
<td></td>
</tr>
</tbody>
</table>

## Scalars

### Boolean

Represents `true` or `false` values.

### ID

Represents a unique identifier that is Base64 obfuscated. It is often used to refetch an object or as key for a cache. The ID type appears in a JSON response as a String; however, it is not intended to be human-readable. When expected as an input type, any string (such as `"VXNlci0xMA=="`) or integer (such as `4`) input value will be accepted as an ID.

### Int

Represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1.

### JsonStringType

### String

Represents textual data as UTF-8 character sequences. This type is most often used by GraphQL to represent free-form human-readable text.


## Interfaces


### Node

An object with an ID.

<table>
<thead>
<tr>
<th align="left">Field</th>
<th align="right">Argument</th>
<th align="left">Type</th>
<th align="left">Description</th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2" valign="top"><strong>id</strong></td>
<td valign="top"><a href="#id">ID</a>!</td>
<td>

ID of the object.

</td>
</tr>
</tbody>
</table>
