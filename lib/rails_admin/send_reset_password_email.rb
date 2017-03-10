require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class SendResetPasswordEmail < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :visible? do
          authorized? && bindings[:object].class == User && bindings[:object].provider == ''
        end
        register_instance_option :link_icon do
          'icon-envelope'
        end
        register_instance_option :member? do
          true
        end
        register_instance_option :pjax? do
          false
        end
        register_instance_option :controller do
          Proc.new do
            @object.send_reset_password_instructions
            flash[:notice] = "Reset password instructions have been sent to #{@object.email}."
            redirect_to back_or_index
          end
        end
      end
    end
  end
end
