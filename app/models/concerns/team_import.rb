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

    def import_spreadsheet_in_background(spreadsheet_url, team_id, user_id)
      spreadsheet_id = self.spreadsheet_id(spreadsheet_url)
      raise_error(I18n.t('team_import.invalid_google_spreadsheet_url', spreadsheet_url: spreadsheet_url), 'INVALID_VALUE') unless spreadsheet_id
      TeamImportWorker.perform_async(team_id, spreadsheet_id, user_id)
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
    FLEXIBLE_COLS = 9

    notifies_pusher on: :touch,
                    event: proc { |t| t.import_status },
                    targets: proc { |t| [t] },
                    if: proc { |t| !t.import_status.blank? },
                    data: proc { |t| {message: t.import_status}.to_json }

    attr_accessor :spreadsheet, :import_status

    def import_spreadsheet(spreadsheet_id, user_id)
      @result = {}
      user = User.find(user_id)
      self.spreadsheet = get_spreadsheet(spreadsheet_id)
      worksheet = self.spreadsheet.worksheets[0]
      Rails.logger.info "[Team Import] Importing spreadsheet #{spreadsheet_id} to team #{self.slug} (requested by user #{user.login})"
      RequestStore.store[:skip_notifications] = true
      self.update_import_status('start')
      get_flexible_columns(worksheet)
      for row in 2..worksheet.num_rows
        @result[row] = []
        import_row(worksheet, row)
        # self.update_import_status('row')
        update_worksheet(worksheet, row)
      end
      self.update_import_status('complete')
      Rails.logger.info "[Team Import] Finished import of spreadsheet #{spreadsheet_id} to team #{self.slug}"
      RequestStore.store[:skip_notifications] = false
      @result
    end

    def get_spreadsheet(id = '')
      begin
        @session = GoogleDrive::Session.from_service_account_key(CONFIG['google_credentials_path'])
        @session.spreadsheet_by_key(id)
      rescue Signet::AuthorizationError
        Team.raise_error(I18n.t('team_import.cannot_authenticate_with_the_credentials'), 'UNAUTHORIZED')
      rescue Google::Apis::ClientError => e
        Team.raise_error(I18n.t('team_import.not_found_google_spreadsheet_url'), 'INVALID_VALUE', {error_message: e.message}) unless self.spreadsheet
      rescue StandardError => e
        Team.raise_error(e.message, 'UNKNOWN', {error_message: e.message})
      end
    end

    def import_row(worksheet, row)
      data = {
        item: worksheet[row, 2],
        user: worksheet[row, 3],
        projects: worksheet[row, 4],
        assigned_to: worksheet[row, 5],
        tags: worksheet[row, 6],
        status: worksheet[row, 7]
      }

      user_id = get_user(data[:user], row)
      projects = get_projects(data[:projects], row)
      return if user_id.nil?
      projects.each do |project|
        begin
          pm = create_item(project, data[:item], user_id)
          @result[row] << pm.full_url
          assign_to_user(pm, data[:assigned_to], row)
          add_tags(pm, data[:tags])
          add_notes(pm, worksheet, row)
          add_tasks_answers(pm, worksheet, row)
          add_status(pm, data[:status], row)
        rescue StandardError => e
          @result[row] << e.message
        end
      end
    end

    def create_item(project, item, user_id)
      media = get_item(item, project)
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
      if (match = pattern.match(user))
        id = match[1].to_i
      else
        id = get_user_by_email(user)
      end
      @result[row] << I18n.t("team_import.invalid_#{column}", user: user) if id.nil?
      id
    end

    def get_user_by_email(user)
      u = User.find_by_email(user) || self.owners('owner').first
      return u.id if u
    end

    def get_projects(projects, row = nil)
      projects = projects.split(',').map { |p| p.strip }
      @result[row] << I18n.t("team_import.blank_project") and return projects if projects.empty?
      pattern = Regexp.new(CONFIG['checkdesk_client'] + "/#{self.slug}\/project\/([0-9]+)")
      ids = []
      projects.each do |p|
        if (match = pattern.match(p))
          ids << match[1].to_i
        else
          @result[row] << I18n.t('team_import.invalid_project', project: p) if @result
        end
      end
      ids
    end

    def get_item(item, project)
      uri = URI.parse(URI.encode(item))
      params = uri.host.nil? ? {quote: item} : {url: item}
      media = Media.where(params).first
      pm = ProjectMedia.where(project_id: project, media_id: media.id).first if media
      {params: params, project_media: pm}
    end

    def assign_to_user(pm, assigned_to, row)
      return if assigned_to.blank?
      user_id = get_user(assigned_to, row, 'assignee')
      if user_id
        status = pm.last_status_obj
        status.assigned_to_ids = user_id
        status.save!
      end
    end

    def add_tags(pm, tags)
      return if tags.blank?
      tags = tags.split(',').map { |t| t.strip }
      tags.each do |tag|
        unless pm.annotations('tag').map(&:tag_text).include?(tag)
          Tag.create!(tag: tag, annotator: pm.user, annotated: pm)
        end
      end
    end

    def get_flexible_columns(worksheet)
       @notes = []
       @tasks = {}
       for col in FLEXIBLE_COLS..worksheet.num_cols
         col_title = worksheet[1, col]
         if col_title == 'Item note'
           @notes << col
         else
           @tasks[col] = Task.slug(col_title)
         end
      end
    end

    def add_notes(pm, worksheet, row)
      annotator = worksheet[row, 8]
      @notes.each do |col|
        note = worksheet[row, col]
        next if note.blank?
        annotator_id = annotator.blank? ? pm.user.id : get_user(annotator, row, 'annotator')
        if annotator_id
          User.current = pm.user
          Comment.create!(annotator_id: annotator_id, text: note, annotated: pm)
          User.current = nil
        end
      end
    end

    def add_tasks_answers(pm, worksheet, row)
      tasks_responses = {}
      @tasks.each_pair do |col, slug|
        answer = worksheet[row, col]
        tasks_responses[slug] = answer unless answer.blank?
      end
      pm.set_tasks_responses = tasks_responses.with_indifferent_access

      User.current = pm.user
      pm.send(:respond_to_auto_tasks, pm.annotations('task'))
      User.current = nil
    end

    def add_status(pm, status, row)
      return if status.blank?
      begin
        s = pm.last_status_obj
        s.status = status
        s.save!
      rescue
        @result[row] << I18n.t('team_import.invalid_status', status: status) if @result
      end
    end

    def update_import_status(status)
      self.import_status = "spreadsheet_import_#{status}"
      self.touch
    end
  end

end
