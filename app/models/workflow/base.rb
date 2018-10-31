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
          id = Digest::MD5.hexdigest([field_name, callback, settings].join)
          unless @@workflow_callbacks.include?(id)
            send "after_#{callback}", ->(obj) { obj.call_workflow_action(field_name, params) }, on: settings[:events]
            @@workflow_callbacks << id
          end
        end
      end
    end

    def self.check_default_project_media_workflow
      CONFIG['default_project_media_workflow'] = self.id
    end

    def self.check_default_task_workflow
      CONFIG['default_task_workflow'] = self.id
    end

    def self.workflow_permissions
      klass = self
      proc do
        if @user.role?(:owner)
          instance_exec(&klass.workflow_permissions_for_owner)
        elsif @user.role?(:journalist)
          instance_exec(&klass.workflow_permissions_for_journalist)
        elsif @user.role?(:contributor) || @user.role?(:annotator)
          instance_exec(&klass.workflow_permissions_for_contributor)
        end
      end
    end

    def self.workflow_permissions_for_owner
      id = self.id
      proc do
        can [:destroy, :update], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.get_team.include?(@context_team.id) && obj.annotation_type == id
        end
      end
    end

    def self.workflow_permissions_for_journalist
      id = self.id
      proc do
        can [:create, :update], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.get_team.include?(@context_team.id) && !obj.annotated_is_archived? && obj.annotation_type == id && (@user.role?(:editor) || !obj.locked?)
        end
        cannot [:destroy], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.annotation_type == id
        end
      end
    end

    def self.workflow_permissions_for_contributor
      id = self.id
      proc do
        cannot [:destroy, :update, :create], Dynamic, ['annotation_type = ?', id] do |obj|
          obj.annotation_type == id
        end
      end
    end

    def self.workflow_admin_permissions
      id = self.id
      proc do
        can :destroy, Dynamic do |obj|
          !(obj.get_team & @teams).empty?
        end
        can :update, Dynamic, ['annotation_type = ?', id] do |obj|
          !(obj.get_team & @teams).empty? && obj.annotation_type == id
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
