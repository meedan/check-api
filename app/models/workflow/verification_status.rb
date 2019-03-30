class Workflow::VerificationStatus < Workflow::Base

  check_default_project_media_workflow if CONFIG['app_name'] == 'Check'

  check_workflow from: :any, to: :terminal, actions: [:send_terminal_notification_if_can_complete_media, :reset_deadline]
  check_workflow on: :commit, actions: :index_on_es, events: [:create, :update]
  check_workflow on: :commit, actions: :save_deadline, events: [:create, :update]

  def self.core_default_value
    'undetermined'
  end

  def self.core_active_value
    'in_progress'
  end

  [Comment, Tag, Flag, Dynamic].each do |annotation_class|
    annotation_class.class_eval do
      attr_accessor :disable_update_status

      after_create :update_annotated_status, if: :should_update_annotated_status?

      protected

      def author_is_not_annotator
        self.annotator.nil? || !self.annotator.is_a?(User) || !self.annotator.role?(:annotator)
      end

      private

      def should_update_annotated_status?
        !self.disable_update_status &&
        !self.is_being_copied &&
        ['ProjectMedia', 'Task'].include?(self.annotated_type) &&
        (self.class.name != 'Dynamic' || self.annotation_type =~ /^task_response/) &&
        self.author_is_not_annotator
      end

      def update_annotated_status
        target = self.annotated_type == 'ProjectMedia' ? self.annotated : self.annotated.annotated
        target.move_media_to_active_status unless self.annotated.nil?
      end
    end
  end

  Task.class_eval do
    after_create :back_status_to_active, unless: :is_being_copied

    private

    def back_status_to_active
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
    def move_media_to_active_status
      return unless CONFIG['app_name'] == 'Check'
      s = self.get_annotations('verification_status').last
      s = s.load unless s.nil?
      self.set_active_status(s) if !s.nil? && s.get_field('verification_status_status').value == ::Workflow::Workflow.options(self, 'verification_status')[:default] && !s.locked
    end

    def set_active_status(s)
      active = ::Workflow::Workflow.options(self, 'verification_status')[:active]
      f = s.get_field('verification_status_status')
      unless active.nil?
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
  end

  DynamicAnnotation::Field.class_eval do
    protected

    def send_terminal_notification_if_can_complete_media
      if self.annotation.annotated_type == 'ProjectMedia'
        if self.annotation.annotated.is_completed?
          return if self.annotation.is_being_copied
          TerminalStatusMailer.delay.notify(self.annotation.annotated, self.annotation.annotator, self.to_s)
        else
          errors.add(:base, I18n.t(:must_resolve_required_tasks_first))
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
  end
end
