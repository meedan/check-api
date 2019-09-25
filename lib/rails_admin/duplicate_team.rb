require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class DuplicateTeam < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :link_icon do
          'icon-copy'
        end
        register_instance_option :member? do
          true
        end
        register_instance_option :http_methods do
          [:get, :post]
        end
        register_instance_option :pjax? do
          false
        end
        register_instance_option :controller do
          proc do
            RailsAdmin::MainController.class_eval { respond_to :html, :js }
            if request.get?
              respond_with(@object)
            elsif request.post?
              RequestStore.store[:ability] = :admin
              RequestStore[:request] = request
              Team.delay_for(1.second).duplicate(@object, User.current)
            end
          end
        end
      end
    end
  end
end
