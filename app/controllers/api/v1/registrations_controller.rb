class Api::V1::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  respond_to :json

  include RegistrationsDoc

  # POST /resource
  def create
    # super
    build_resource(sign_up_params)

    begin
      duplicate_user = User.get_duplicate_user(resource.email, [])[:user]
      user = resource
      error = [
        {
          message: I18n.t(:email_exists)
        }
      ]
      if !duplicate_user.nil? && duplicate_user.invited_to_sign_up?
        duplicate_user.last_accepted_terms_at = Time.now
        duplicate_user.save!
      else
        resource.last_accepted_terms_at = Time.now
        resource.save!
      end

      User.current = user
      sign_up(resource_name, user)
      render_success user, 'user', 401, error
    rescue ActiveRecord::RecordInvalid => e
      # Check if the error is specifically related to the email being taken
      if resource.errors.details[:email].any? { |email_error| email_error[:error] == :taken } && resource.errors.details.except(:email).empty?
        User.current = user
        sign_up(resource_name, user)
        render_success nil, 'user', 401, error
      else
        # For other errors, show the error message in the form
        clean_up_passwords resource
        set_minimum_password_length
        render_error e.message.gsub("Email #{I18n.t(:email_exists)}<br />", '').strip, 'INVALID_VALUE', 401
      end
    end
  end

  # PUT /resource
  def update
    # super
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    resource_updated = update_resource(resource, account_update_params)
    User.current = resource

    if resource_updated
      sign_in resource, scope: resource_name, bypass_sign_in: true
      render_success 'user', resource
    else
      clean_up_passwords resource
      render_error 'Could not update user: ' + resource.errors.full_messages.join(', '), 'INVALID_VALUE'
    end
  end

  # DELETE /resource
  def destroy
    # super
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    render_success
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :login, :password, :password_confirmation, :image])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :password, :password_confirmation, :current_password])
  end
end
