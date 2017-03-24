require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class ExportProject < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :link_icon do
          'icon-share'
        end
        register_instance_option :member? do
          true
        end
        register_instance_option :pjax? do
          false
        end
        register_instance_option :controller do
          proc do
            filename = @object.csv_filename + '.csv'
            send_data @object.export_to_csv, type: 'text/csv', disposition: "attachment", filename: filename
          end
        end
      end
    end
  end
end
