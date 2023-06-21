class ResendCancelInvitationMutation < Mutations::BaseMutation
  graphql_name "ResendCancelInvitation"

  argument :email, String, required: true

  argument :action, String, required: true

  field :success, Boolean, null: true

  field :team, TeamType, null: true

  def resolve(**inputs)
    user = User.find_user_by_email(inputs[:email])
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      case inputs[:action]
      when "cancel"
        User.cancel_user_invitation(user)
      when "resend"
        tu = user.team_users.where(team_id: Team.current.id).last
        tu.update_columns(created_at: Time.now)
        user.send_invitation_mail(tu.reload)
      end
      { success: true, team: Team.current }
    end
  end
end
