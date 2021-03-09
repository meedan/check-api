class Api::V1::InvitationsController < Devise::InvitationsController
  skip_before_action :resource_from_invitation_token, :only => [:edit]

  def edit
    invitation_token = params[:invitation_token]
    slug = params[:slug]
    resource = User.accept_team_invitation(invitation_token, slug)
    path = if resource.errors.empty?
             user = User.find_by_id(resource.id)
             if user.nil?
               url = "/?invitation_response=success&msg=no"
             else
               sign_in user
               url = "/#{slug}"
             end
             url
           else
             error_key = resource.errors.messages.keys[0].to_s
             error_key == 'invitation_accepted' ? "/#{slug}" : "/?invitation_response=#{error_key}"
           end
    redirect_to CheckConfig.get('checkdesk_client') + path
  end
end
