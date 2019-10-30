class Api::V1::InvitationsController < Devise::InvitationsController
  skip_before_action :resource_from_invitation_token, :only => [:edit]

  def edit
    invitation_token = params[:invitation_token]
    slug = params[:slug]
    resource = User.accept_team_invitation(invitation_token, slug)
    path = if resource.errors.empty?
             token = User.generate_password_token(resource.id)
             if token.nil?
               url = "/?invitation_response=success&msg=no"
             else
               url = "/check/user/password-change?reset_password_token=#{token}"
             end
             url
           else
             error_key = resource.errors.messages.keys[0].to_s
             error_key == 'invitation_accepted' ? "/#{slug}" : "/?invitation_response=#{error_key}"
           end
    redirect_to CONFIG['checkdesk_client'] + path
  end
end
