class Api::V1::PasswordsController < Devise::PasswordsController

  def edit
    User.current = self.resource = resource_class.reset_password_by_token(reset_password_token: params[:reset_password_token])
    render template: 'devise/passwords/edit.html.erb'
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?
    if resource.errors.empty?
      redirect_to CONFIG['checkdesk_client'] + '/check/login/email'
    else
      set_minimum_password_length
      render template: 'devise/passwords/edit.html.erb'
    end
  end
end
