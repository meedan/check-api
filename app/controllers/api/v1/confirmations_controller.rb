class Api::V1::ConfirmationsController < Devise::ConfirmationsController
  def show
    valid_host = params[:client_host].to_s.match(Regexp.new(CONFIG['checkdesk_client']))
    if valid_host.nil?
      render_error('Unrecognized client', 'INVALID_VALUE')
    else
      User.current = nil
      User.current = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?
      path = resource.errors.empty? ? '/user/confirmed' : '/user/unconfirmed'
      redirect_to valid_host[0] + path
    end
  end
end
