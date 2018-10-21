class Api::V1::InvitationsController < Devise::InvitationsController
  def edit
    invitation_token = params[:invitation_token]
    slug = params[:slug]
    User.accept_team_invitation(invitation_token, slug)
    redirect_to "#{CONFIG['checkdesk_client']}/#{slug}"
  end
end