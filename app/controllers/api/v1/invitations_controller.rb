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
               user = User.find(resource.id)
               sign_in user
               # url = "/check/user/password-change?reset_password_token=#{token}"
               url = "/check/signup/#{slug}"
             end
             url
           else
             error_key = resource.errors.messages.keys[0].to_s
             error_key == 'invitation_accepted' ? "/check/signup/#{slug}" : "/?invitation_response=#{error_key}"
           end
    redirect_to CheckConfig.get('checkdesk_client') + path
  end
end
