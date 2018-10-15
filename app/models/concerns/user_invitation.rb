require 'active_support/concern'

module UserInvitation
  extend ActiveSupport::Concern

  included do
  	attr_accessor :invitation_role, :invitation_text
  	devise :invitable
  	after_invitation_created :create_team_user_invitation

	  def self.send_user_invitation(members, text=nil)
	    msg = {}
	    members.each do |role, emails|
	      emails.split(',').each do |email|
	        email.strip!
	        u = User.where(email: email).last
	        # begin
	          if u.nil?
	            user = User.invite!({:email => email, :name => email.split("@").first, :invitation_role => role, :invitation_text => text}, User.current) do |iu|
	              iu.skip_invitation = true
	            end
	            user.update_column(:raw_invitation_token, user.raw_invitation_token)
	            msg[email] = 'success'
	          else
	            u.invitation_role = role
	            u.invitation_text = text
	            msg.merge!(u.invite_existing_user)
	          end
	        # rescue StandardError => e
	        #   msg[email] = e.message
	        # end
	      end
	    end
	    msg
	  end

	  def invite_existing_user
	    msg = {}
	    unless Team.current.nil?
	      tu = TeamUser.where(team_id: Team.current.id, user_id: self.id).last
	      if tu.nil?
	        options = {}
	        unless self.is_invited?
	          raw, enc = Devise.token_generator.generate(User, :invitation_token)
	          options = {:enc => enc, :raw => raw}
	        end
	        create_team_user_invitation(options)
	        msg[self.email] = 'success'
	      elsif tu.status == 'invited'
	        msg[self.email] = 'This email already invited to this team'
	      else
	        msg[self.email] = 'This email already a team member'
	      end
	    end
	    msg
	  end

	  def self.accept_team_invitation(token, slug, options={})
	    # TODO: localize and review error messages copy.
	    t = Team.where(slug: slug).last
	    if t.nil?
	      raise 'Team not exists.'
	    else
	      invitation_token = Devise.token_generator.digest(self, :invitation_token, token)
	      tu = TeamUser.where(team_id: t.id, status: 'invited', invitation_token: invitation_token).last
	      if tu.nil?
	        raise "No invitation exists for team #{t.name}"
	      elsif tu.invitation_period_valid?
	        tu.invitation_accepted_at = Time.now.utc
	        tu.invitation_token = nil
	        tu.status = 'member'
	        tu.save!
	        # options should have password & username keys
	        user = User.find_by_invitation_token(token, true)
	        password = options[:password] || 'dummypassword'
	        User.accept_invitation!(:invitation_token => token, :password => password) unless user.nil?
	      else
	        raise 'Invitation token is invalid'
	      end
	    end
	  end

	  def send_invitation_mail(tu)
	    token = tu.raw_invitation_token
	    self.invited_by = User.current
	    opts = {due_at: tu.invitation_due_at, invitation_text: self.invitation_text, invitation_team: Team.current}
	    DeviseMailer.delay.invitation_instructions(self, token, opts)
	  end

	  def self.cancel_user_invitation(user)
	    tu = user.team_users.where(team_id: Team.current.id).last
	    unless tu.nil?
	      tu.skip_check_ability = true
	      tu.destroy if tu.status == 'invited' && !tu.invitation_token.nil?
	    end
	    # Check if user invited to another team(s)
	    user.skip_check_ability = true
	    user.destroy if user.is_invited? && user.team_users.count == 0
	  end

	  def is_invited?(team=nil)
	    team = Team.current if team.nil?
	    return true if self.invited_to_sign_up?
	    tu = self.team_users.where(status: 'invited', team_id: team.id).where.not(invitation_token: nil).last
	    !tu.nil?
	  end

  	private

  	def create_team_user_invitation(options = {})
	    tu = TeamUser.new
	    tu.user_id = self.id
	    tu.team_id = Team.current.id
	    tu.role = self.invitation_role
	    tu.status = 'invited'
	    tu.invited_by_id = self.invited_by_id
	    tu.invited_by_id ||= User.current.id unless User.current.nil?
	    tu.invitation_token = self.invitation_token || options[:enc]
	    tu.raw_invitation_token = self.read_attribute(:raw_invitation_token) || self.raw_invitation_token || options[:raw]
	    tu.save!
  	end
  end
end