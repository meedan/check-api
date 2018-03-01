require File.join(Rails.root, 'lib', 'rails_admin', 'export_project.rb')

class RailsAdmin::Config::Actions::ExportImages < RailsAdmin::Config::Actions::ExportProject
  register_instance_option :link_icon do
    'icon-images'
  end
  register_instance_option :controller do
    proc do
      @object.export_images_in_background(current_api_user)
    end
  end
end
