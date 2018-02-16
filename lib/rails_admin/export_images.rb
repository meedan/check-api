require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class ExportImages < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :link_icon do
          'icon-images'
        end
        register_instance_option :member? do
          true
        end
        register_instance_option :pjax? do
          false
        end
        register_instance_option :controller do
          proc do
            @object.export_images_in_background(current_api_user)
          end
        end
      end
    end
  end
end
