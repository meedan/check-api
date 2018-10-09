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
      tu = user.team_users.where(team_id: Team.current.id).last
      if action == 'cancel'
        tu.destroy if tu.status == 'invited' && tu.invitation_token.nil?
        user.destroy if user.invited_to_sign_up?
      elsif action == 'resend'
        if user.invited_to_sign_up?
          user.invite!
        else
          raw, enc = Devise.token_generator.generate(User, :invitation_token)
          tu.invitation_token = enc; tu.save!
          user.send_invitation_mail(raw)
        end
      end
      { success: true }
    end
  }
end
