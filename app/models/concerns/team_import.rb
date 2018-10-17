require 'active_support/concern'
require 'google_drive'

module TeamImport
  extend ActiveSupport::Concern

  module ClassMethods

    def spreadsheet_id(url)
      pattern = /https:\/\/docs\.google\.com\/spreadsheets\/d\/([a-zA-Z0-9\-\_]+)/
      match = url.match(pattern)
      match ? match[1] : nil
    end

    def import_spreadsheet_in_background(spreadsheet_url, user_id = nil)
      team = Team.current
      raise_error(I18n.t('team_import.team_not_present'), 'INVALID_VALUE') unless team
      spreadsheet_id = self.spreadsheet_id(spreadsheet_url)
      raise_error(I18n.t('team_import.invalid_google_spreadsheet_url', spreadsheet_url: spreadsheet_url), 'INVALID_VALUE') unless spreadsheet_id
      TeamImportWorker.perform_async(team.id, spreadsheet_id, user_id)
    end

    def raise_error(message, code, args={})
      error = {
        message: message,
        code: code,
        data: args
      }
      raise error.to_json
    end

  end

  included do
    notifies_pusher on: :touch,
                    event: proc { |t| t.import_status },
                    targets: proc { |t| [t] },
                    if: proc { |t| !t.import_status.blank? },
                    data: proc { |t| {message: t.import_status}.to_json }

    attr_accessor :spreadsheet, :import_status

    def import_spreadsheet(spreadsheet_id, email)
      @result = {}
      self.spreadsheet = get_spreadsheet(spreadsheet_id)
      worksheet = self.spreadsheet.worksheets[0]
      # self.update_import_status('start')
      for row in 2..worksheet.num_rows
        @result[row] = []
        import_row(worksheet, row)
        # self.update_import_status('row')
        update_worksheet(worksheet, row)
      end
      # self.update_import_status('complete')
      @result
    end

    def get_spreadsheet(id = '')
      begin
        @session = GoogleDrive::Session.from_service_account_key(CONFIG['google_credentials_path'])
        @session.spreadsheet_by_key(id)
      rescue Signet::AuthorizationError => e
        Team.raise_error(I18n.t('team_import.cannot_authenticate_with_the_credentials'), 'UNAUTHORIZED')
      rescue Google::Apis::ClientError => e
        Team.raise_error(I18n.t('team_import.not_found_google_spreadsheet_url'), 'INVALID_VALUE', {error_message: e.message}) unless self.spreadsheet
      rescue Exception => e
        Team.raise_error(e.message, 'UNKNOWN', {error_message: e.message})
      end
    end

    def import_row(worksheet, row)
      data = {
        item: worksheet[row, 2],
        user: worksheet[row, 3],
        projects: worksheet[row, 4],
        note: worksheet[row, 5],
        annotator: worksheet[row, 6],
        assigned_to: worksheet[row, 7],
        tags: worksheet[row, 8],
      }

      user_id = get_user(data[:user], row)
      projects = get_projects(data[:projects], row)
      return if user_id.nil?
      projects.each do |project|
        begin
          pm = create_item(project, data[:item], user_id, row)
          @result[row] << pm.full_url
          add_note(pm, data[:note], data[:annotator], row)
          assign_to_user(pm, data[:assigned_to], row)
          add_tags(pm, data[:tags], row)
          add_tasks_answers(pm, worksheet, row)
        rescue Exception => e
          @result[row] << e.message
        end
      end
    end

    def create_item(project, item, user_id, row)
      media = get_item(item, project, row)
      pm = media[:project_media]
      if pm.nil?
        pm = ProjectMedia.create!({project_id: project, user_id: user_id}.merge(media[:params]))
      end
      pm
    end

    def update_worksheet(worksheet, row)
      worksheet[row, 1] = @result[row].join(', ')
      worksheet.save if row == worksheet.num_rows
    end

    protected

    def get_user(user, row, column = 'user')
      @result[row] << I18n.t("team_import.blank_#{column}") and return if user.blank?
      pattern = Regexp.new(CONFIG['checkdesk_client'] + "/check\/user\/([0-9]+)")
      if match = pattern.match(user)
        id = match[1].to_i
      else
        @result[row] << I18n.t("team_import.invalid_#{column}", user: user)
      end
      id
    end

    def get_projects(projects, row = nil)
      projects = projects.split(',').map { |p| p.strip }
      @result[row] << I18n.t("team_import.blank_project") and return projects if projects.empty?
      pattern = Regexp.new(CONFIG['checkdesk_client'] + "/#{self.slug}\/project\/([0-9]+)")
      ids = []
      projects.each do |p|
        if match = pattern.match(p)
          ids << match[1].to_i
        else
          @result[row] << I18n.t('team_import.invalid_project', project: p) if @result
        end
      end
      ids
    end

    def get_item(item, project, row)
      uri = URI.parse(URI.encode(item))
      params = uri.host.nil? ? {quote: item} : {url: item}
      media = Media.where(params).first
      pm = ProjectMedia.where(project_id: project, media_id: media.id).first if media
      {params: params, project_media: pm}
    end

    def add_note(pm, note, annotator, row)
      return if note.blank? && annotator.blank?
      annotator_id = get_user(annotator, row, 'annotator')
      if annotator_id
        Comment.create!(annotator_id: annotator_id, text: note, annotated: pm)
      end
    end

    def assign_to_user(pm, assigned_to, row)
      return if assigned_to.blank?
      user_id = get_user(assigned_to, row, 'assignee')
      if user_id
        status = pm.last_status_obj
        status.assigned_to_id = user_id
        status.save!
      end
    end

    def add_tags(pm, tags, row)
      return if tags.blank?
      tags = tags.split(',').map { |t| t.strip }
      tags.each do |tag|
        Tag.create!(tag: tag, annotator: pm.user, annotated: pm) # team tags already created
      end
    end

    def add_tasks_answers(pm, worksheet, row)
      # "where_was_the_video_recorded": worksheet[row, 11],
      pm.set_tasks_responses = {
        "timestamp": worksheet[row, 9],
        "what_does_the_video_document": worksheet[row, 10],
        "when_was_the_video_recorded": worksheet[row, 12],
        "what_human_rights_issue_s_does_this_video_document": worksheet[row, 13],
        "if_the_video_includes_chants_or_protest_signs_what_do_they_say": worksheet[row, 14],
        "if_the_video_includes_testimony_who_is_on_camera_and_what_do_they_say": worksheet[row, 15],
        "if_there_is_additional_footage_of_the_same_event_please_copy_links_to_other_videos_or_photographs_below": worksheet[row, 16],
        "if_there_online_reports_with_more_information_about_the_event_or_issue_please_copy_links_below": worksheet[row, 17],
        "do_you_have_any_questions_uncertainties_or_anything_more_to_add_about_the_video": worksheet[row, 18],
        "can_watching_western_sahara_can_contact_you_with_further_questions_if_so_please_enter_your_email_address_below": worksheet[row, 19],
        "has_the_video_been_verified_and_contextualized": worksheet[row, 20]
      }.with_indifferent_access
      notes = { "has_the_video_been_verified_and_contextualized": [worksheet[row, 21],worksheet[row, 22]] }.with_indifferent_access

      User.current = pm.user
      pm.send(:respond_to_auto_tasks, pm.annotations('task'))

      notes.each_pair do |slug, note|
        task = pm.annotations('task').find {|t| t.slug == slug }
        note.each do |text|
          comment = Comment.new
          comment.text = text
          comment.annotated = task
          comment.annotator = pm.user
          comment.save
        end
      end
      User.current = nil
    end

    def update_import_status(status)
      self.import_status = "spreadsheet_import_#{status}"
      self.touch
    end
  end

end
