class Api::V1::ConfirmationsController < Devise::ConfirmationsController
  def show
    valid_host = params[:client_host].to_s == CONFIG['checkdesk_client']
    if valid_host
      User.current = nil
      User.current = self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?
      path = if resource.errors.empty?
               '/check/user/confirmed'
             else
               resource.valid? ? '/check/user/already-confirmed' : '/check/user/unconfirmed'
             end
      redirect_to CONFIG['checkdesk_client'] + path
    else
      render_error('Unrecognized client', 'INVALID_VALUE')
    end
  end
end
