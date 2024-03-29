module Workflow
  class Base
    def self.id
      self.name.gsub('Workflow::', '').underscore
    end

    def self.check_workflow(settings)
      field_name = self.id + '_status'
      condition = settings[:if] || proc { true }

      DynamicAnnotation::Field.class_eval do
        @@workflow_callbacks ||= []

        [settings[:actions]].flatten.each do |action|
          params = settings.merge({ action: action, if: condition })
          callback = settings[:on] || :update
          id = Digest::MD5.hexdigest([action.to_s, field_name, callback, settings].join)
          unless @@workflow_callbacks.include?(id)
            send "after_#{callback}", ->(obj) { obj.call_workflow_action(field_name, params) }
            @@workflow_callbacks << id
          end
        end
      end
    end

    def self.check_default_project_media_workflow
      CheckConfig.set('default_project_media_workflow', self.id)
    end

    def self.workflow_permissions
      klass = self
      proc do
        if @user.role?(:admin)
          instance_exec(&klass.workflow_permissions_for_admin)
        elsif @user.role?(:editor) || @user.role?(:collaborator)
          instance_exec(&klass.workflow_permissions_for_editor)
        end
      end
    end

    def self.workflow_permissions_for_admin
      id = self.id
      proc do
        can [:destroy, :update], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.team&.id == @context_team.id && obj.annotation_type == id
        end
      end
    end

    def self.workflow_permissions_for_editor
      id = self.id
      proc do
        can [:create, :update], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.team&.id == @context_team.id && !obj.annotated_is_trashed? && obj.annotation_type == id && (@user.role?(:editor) || !obj.locked?)
        end
        cannot [:destroy], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.annotation_type == id
        end
      end
    end

    def self.target
      ProjectMedia
    end

    def self.notify_slack?
      true
    end
  end
end
