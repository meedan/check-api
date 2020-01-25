ResendCancelInvitationMutation = GraphQL::Relay::Mutation.define do
  name 'ResendCancelInvitation'

  input_field :email, !types.String

  input_field :action, !types.String

  return_field :success, types.Boolean

  return_field :team, TeamType

  resolve -> (_root, inputs, _ctx) {
    user = User.find_user_by_email(inputs[:email])
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      case inputs[:action]
      when 'cancel'
        User.cancel_user_invitation(user)
      when 'resend'
        tu = user.team_users.where(team_id: Team.current.id).last
        tu.update_columns(created_at: Time.now)
        user.send_invitation_mail(tu.reload)
      end
      { success: true, team: Team.current }
    end
  }
end
