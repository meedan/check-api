class Api::V1::ConfirmationsController < Devise::ConfirmationsController
  def show
    if params[:client_host].to_s.match(Regexp.new(CONFIG['checkdesk_client'])).nil?
      render_error('Unrecognized client', 'INVALID_VALUE')
    else
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?
      path = resource.errors.empty? ? '/user/confirmed' : '/user/unconfirmed'
      redirect_to params[:client_host] + path
    end
  end
end
