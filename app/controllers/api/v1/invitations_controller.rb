class Api::V1::InvitationsController < Devise::InvitationsController
  skip_before_action :resource_from_invitation_token, :only => [:edit]

  def edit
    invitation_token = params[:invitation_token]
    slug = params[:slug]
    resource = User.accept_team_invitation(invitation_token, slug)
    path = resource.errors.empty? ? "/#{slug}" : '/check/user/invalid-invitation'
    redirect_to CONFIG['checkdesk_client'] + path
  end
end
