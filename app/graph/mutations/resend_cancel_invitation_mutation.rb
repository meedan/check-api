ResendCancelInvitationMutation = GraphQL::Relay::Mutation.define do
  name 'ResendCancelInvitation'

  input_field :email, !types.String

  input_field :action, !types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.where(email: inputs[:email]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      case inputs[:action]
      when 'cancel'
        User.cancel_user_invitation(user)
      when 'resend'
        tu = user.team_users.where(team_id: Team.current.id).last
        user.send_invitation_mail(tu.raw_invitation_token)
      end
      { success: true }
    end
  }
end

