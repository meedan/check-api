require 'active_support/concern'

module UserInvitation
  extend ActiveSupport::Concern

  included do
    attr_accessor :invitation_role, :invitation_text
    devise :invitable
    after_invitation_created :create_team_user_invitation

    def self.send_user_invitation(members, text=nil)
      msg = []
      members.each do |member|
        member.symbolize_keys!
        role = member[:role]
        member[:email].split(',').each do |email|
          email = email.downcase.strip
          u = User.find_user_by_email(email)
          begin
            if u.nil?
              user = User.invite!({:email => email, :name => email.split("@").first, :invitation_role => role, :invitation_text => text}, User.current) do |iu|
                iu.skip_invitation = true
              end
              user.update_columns(raw_invitation_token: user.raw_invitation_token, encrypted_password: nil)
            else
              u.invitation_role = role
              u.invitation_text = text
              msg.concat(u.invite_existing_user(email))
            end
          rescue StandardError => e
            msg << { email: email, error: e.message }
          end
        end
      end
      msg
    end

    def invite_existing_user(email)
      msg = []
      unless Team.current.nil?
        tu = get_team_user
        if tu.nil?
          options = {}
          unless self.is_invited?
            raw, enc = Devise.token_generator.generate(User, :invitation_token)
            options = {:enc => enc, :raw => raw}
          end
          options[:email] = email
          create_team_user_invitation(options)
        elsif tu.status == 'invited'
          msg << { email: email, error: I18n.t(:"user_invitation.invited", email: email) }
        else
          msg << { email: email, error: I18n.t(:"user_invitation.member", email: email) }
        end
      end
      msg
    end

    def self.accept_team_invitation(token, slug, options={})
      invitable = new
      t = Team.where(slug: slug).last
      if t.nil?
        invitable.errors.add(:invalid_team, I18n.t(:"user_invitation.team_found"))
      else
        invitation_token = Devise.token_generator.digest(self, :invitation_token, token)
        tu = TeamUser.where(team_id: t.id, status: ['invited', 'member'], invitation_token: invitation_token).last
        if tu.nil?
          invitable.errors.add(:no_invitation, I18n.t(:"user_invitation.no_invitation", name: t.name))
        elsif tu.status == 'member'
          invitable.errors.add(:invitation_accepted, I18n.t(:"user_invitation.invitation_accepted"))
        elsif tu.invitation_period_valid?
          inv_user = self.accept_team_user_invitation(tu, token, options)
          invitable.id = inv_user.id unless inv_user.nil?
        else
          invitable.errors.add(:invitation_expired, I18n.t(:"user_invitation.invalid"))
        end
      end
      invitable
    end

    def send_invitation_mail(tu)
      token = tu.raw_invitation_token
      self.invited_by = User.current
      opts = {
        due_at: tu.invitation_due_at, invitation_text: self.invitation_text, invitation_team: tu.team,
        role: I18n.t("role_#{tu.role}")
      }
      # update invitations date if user still inivted (not a check user).
      self.update_columns(invitation_created_at: tu.created_at, invitation_sent_at: tu.created_at) if self.invited_to_sign_up?
      DeviseMailer.delay.invitation_instructions(self, token, opts)
    end

    def self.cancel_user_invitation(user)
      tu = user.team_users.where(team_id: Team.current.id).last
      unless tu.nil?
        tu.skip_check_ability = true
        tu.destroy if tu.status == 'invited' && !tu.invitation_token.nil?
      end
      # Check if user invited to another team(s)
      self.destroy_invited_user(user) if user.is_invited? && user.team_users.count == 0
    end

    def is_invited?(team = nil)
      team ||= Team.current
      return true if self.invited_to_sign_up?
      tu = self.team_users.where(status: 'invited', team_id: team.id).where.not(invitation_token: nil).last unless team.nil?
      !tu.nil?
    end

    private

    def create_team_user_invitation(options = {})
      team_id = Team.current&.id
      unless team_id.nil?
        tu = TeamUser.new
        tu.user_id = self.id
        tu.team_id = team_id
        tu.role = self.invitation_role
        tu.status = 'invited'
        tu.invited_by_id = self.invited_by_id
        tu.invited_by_id ||= User.current.id unless User.current.nil?
        tu.invitation_token = self.invitation_token || options[:enc]
        tu.raw_invitation_token = self.read_attribute(:raw_invitation_token) || self.raw_invitation_token || options[:raw]
        tu.invitation_email = options[:email] || self.email
        self.send_invitation_mail(tu) if tu.save!
      end
    end

    def self.accept_team_user_invitation(tu, token, options)
      tu.invitation_accepted_at = Time.now.utc
      # tu.invitation_token = nil
      tu.raw_invitation_token = nil
      tu.status = 'member'
      tu.skip_check_ability = true
      tu.save!
      # options should have password & username keys
      user = User.find_by_invitation_token(token, true)
      password = options[:password]
      if password.blank?
        # Generate random passsword that match password_complexity validation
        samples = [('a'..'z'), ('A'..'Z'), (0..9), ['@', '#', '$', '%', '&']].map(&:to_a)
        password = Devise.friendly_token.first(8).concat(samples.map(&:sample).shuffle.join)
      end
      unless user.nil?
        invitable = User.accept_invitation!(:invitation_token => token, :password => password)
        user.update_columns(raw_invitation_token: nil, completed_signup: false)
      end
      invitable
    end

    def get_team_user
      tu = TeamUser.where(team_id: Team.current.id, user_id: self.id).last
      if !tu.nil? && tu.status == 'banned'
        tu.skip_check_ability = true
        tu.destroy
        tu = nil
      end
      tu
    end

    def self.destroy_invited_user(user)
      user.skip_check_ability = true
      user.destroy
      s = user.source
      s.skip_check_ability = true
      s.destroy unless s.nil?
    end
  end
end
