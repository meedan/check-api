require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class DeleteTasks < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :link_icon do
          'icon-tasks'
        end
        register_instance_option :member? do
          true
        end
        register_instance_option :http_methods do
          [:get, :put]
        end
        register_instance_option :pjax? do
          false
        end
        register_instance_option :controller do
          proc do
            RailsAdmin::MainController.class_eval { respond_to :html, :js }
            if request.get? # EDIT
              respond_with(@object)
            elsif request.put? # UPDATE
              RequestStore.store[:ability] = :admin
              if @object.save
                respond_to do |format|
                  format.html { redirect_to_on_success }
                end
              else
                handle_save_error :edit
              end
            end
          end
        end
      end
    end
  end
end
