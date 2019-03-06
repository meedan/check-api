class Api::V1::InvitationsController < Devise::InvitationsController
  skip_before_action :resource_from_invitation_token, :only => [:edit]

  def edit
    invitation_token = params[:invitation_token]
    slug = params[:slug]
    resource = User.accept_team_invitation(invitation_token, slug)
    path = if resource.errors.empty?
             msg = resource.id.nil? ? 'no' : 'yes'
             "/?invitation_response=success&msg=#{msg}"
           else
             error_key = resource.errors.messages.keys[0].to_s
             "/?invitation_response=#{error_key}"
           end
    redirect_to CONFIG['checkdesk_client'] + path
  end
end
