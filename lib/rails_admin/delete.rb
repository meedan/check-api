module RailsAdmin
  module Config
    module Actions
      class Delete < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :route_fragment do
          'delete'
        end

        register_instance_option :http_methods do
          [:get, :delete]
        end

        register_instance_option :authorization_key do
          :destroy
        end

        register_instance_option :controller do
          proc do
            RailsAdmin::MainController.class_eval { respond_to :html, :js }
            if (@object.is_a?(Dynamic) && @object.annotation_type == 'smooch_user') || request.delete? # DESTROY
              RequestStore.store[:ability] = :admin

              redirect_path = nil
              @auditing_adapter && @auditing_adapter.delete_object(@object, @abstract_model, _current_user)
              if @object.is_a?(Team)
                @object.update_column(:inactive, true)
                TeamDeletionWorker.perform_async(@object.id, current_api_user.id)
                flash[:info] = t('admin.flash.delete_team_scheduled', team: @object.name)
                redirect_path = index_path
              else
                if @object.destroy
                  flash[:success] = t('admin.flash.successful', name: @model_config.label, action: t('admin.actions.delete.done'))
                  redirect_path = index_path
                else
                  flash[:error] = t('admin.flash.error', name: @model_config.label, action: t('admin.actions.delete.done'))
                  redirect_path = back_or_index
                end
              end

              redirect_to redirect_path
            elsif request.get? # DELETE
              respond_with(@object)
            end
          end
        end

        register_instance_option :link_icon do
          'icon-remove'
        end
      end
    end
  end
end
