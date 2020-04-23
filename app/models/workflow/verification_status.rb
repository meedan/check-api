class Workflow::VerificationStatus < Workflow::Base

  check_default_project_media_workflow if CONFIG['app_name'] == 'Check'

  check_workflow from: :any, to: :any, actions: [:check_if_item_is_published, :apply_rules, :update_report_design_if_needed]
  check_workflow from: :any, to: :terminal, actions: [:send_terminal_notification_if_can_complete_media, :reset_deadline]
  check_workflow on: :commit, actions: :index_on_es, events: [:create, :update]
  check_workflow on: :commit, actions: :save_deadline, events: [:create, :update]

  def self.core_default_value
    'undetermined'
  end

  def self.core_active_value
    'in_progress'
  end

  Task.class_eval do
    after_create :back_status_to_active, unless: :is_being_copied

    private

    def back_status_to_active
      return if self.skip_update_media_status
      if self.required == true && self.annotated_type == 'ProjectMedia'
        vs = self.annotated.get_annotations('verification_status').last
        if !vs.nil? && !vs.locked
          vs = vs.load
          completed = ::Workflow::Workflow.options(self.annotated, 'verification_status')[:statuses].select{ |s| s[:completed].to_i == 1 }.collect{ |s| s[:id] }
          self.annotated.set_active_status(vs) if completed.include?(vs.get_field('verification_status_status').value)
        end
      end
    end
  end

  ProjectMedia.class_eval do
    def set_active_status(s)
      active = ::Workflow::Workflow.options(self, 'verification_status')[:active]
      f = s.get_field('verification_status_status')
      unless active.nil?
        f.previous_status = f.value
        f.value = active
        f.skip_check_ability = true
        f.save!
      end
    end

    alias_method :custom_permissions_original, :custom_permissions

    def custom_permissions(ability = nil)
      perms = self.custom_permissions_original
      ability ||= Ability.new
      perms["update Status"] = ability.can?(:update, Dynamic.new(annotation_type: 'verification_status', annotated: self))
      perms
    end

    def status_i18n(key = nil, options = {})
      key ||= self.last_status
      core_status_ids = YAML.load(ERB.new(File.read("#{Rails.root}/config/core_statuses.yml")).result)['MEDIA_CORE_VERIFICATION_STATUSES'].collect{ |st| st[:id] }
      custom_statuses = self.team.settings.to_h.with_indifferent_access['media_verification_statuses'].to_h.with_indifferent_access['statuses'].to_a
      if core_status_ids.include?(key.to_s) && custom_statuses.blank?
        I18n.t('statuses.media.' + key.to_s.gsub(/^false$/, 'not_true') + '.label', options)
      else
        fallback = nil
        custom_statuses.each { |s| fallback = s['label'] if s['id'] == key }
        CheckI18n.i18n_t(self.team, 'status_' + key.to_s, fallback, options)
      end
    end
  end

  DynamicAnnotation::Field.class_eval do
    protected

    def send_terminal_notification_if_can_complete_media
      if self.annotation.annotated_type == 'ProjectMedia'
        if self.annotation.annotated.is_completed?
          return if self.annotation.is_being_copied
          options = {
            annotated: self.annotation.annotated,
            author: self.annotation.annotator,
            status: self.to_s
          }
          MailWorker.perform_in(1.second, 'TerminalStatusMailer', YAML::dump(options))
        else
          errors.add(:base, I18n.t('errors.messages.must_resolve_required_tasks_first'))
          raise ActiveRecord::RecordInvalid.new(self)
        end
      end
    end

    def save_deadline
      status = self.annotation&.load
      field = status.get_field('verification_status_status')
      turnaround = Team.where(id: status.get_team.last.to_i).last&.get_status_target_turnaround.to_i
      if turnaround > 0 && !field.workflow_completed_options.include?(field.value)
        # Round down deadline to nearest 5 minutes (300 sec)
        deadline = (status.created_at + turnaround.hours).to_i
        deadline -= deadline % 300
        status.set_fields = { deadline: deadline }.to_json
        status.save!
      end
    end

    def reset_deadline
      status = self.annotation&.load.becomes(Dynamic)
      deadline = status.get_field('deadline')
      deadline.delete unless deadline.blank?
      status.save!
    end

    def apply_rules
      status = self.annotation&.load
      team = Team.where(id: status.get_team.last.to_i).last
      team.apply_rules_and_actions(status.annotated, self) if !team.nil? && status.annotated_type == 'ProjectMedia'
    end

    def check_if_item_is_published
      published = begin (self.annotation.annotated.get_annotations('report_design').last.load.get_field_value('state') == 'published') rescue false end
      raise(I18n.t(:cant_change_status_if_item_is_published)) if published
    end

    def update_report_design_if_needed
      pm = self.annotation.annotated
      report = pm.get_annotations('report_design').last
      unless report.nil?
        report = report.load
        report.set_fields = report.data.merge({
          theme_color: pm.last_status_color,
          status_label: pm.status_i18n(pm.last_verification_status)
        }).to_json
        report.save!
      end
    end
  end

  Team.class_eval do
    def get_media_verification_statuses
      settings = self.settings || {}
      custom_statuses = settings.with_indifferent_access[:media_verification_statuses]
      return custom_statuses unless custom_statuses.is_a?(Hash)
      if custom_statuses
        custom_statuses.with_indifferent_access['statuses'].to_a.each do |s|
          s[:label] = CheckI18n.i18n_t(self, 'status_' + s[:id], s[:label])
        end
      end
      custom_statuses
    end
  end
end
