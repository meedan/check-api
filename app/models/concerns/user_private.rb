require 'active_support/concern'

module UserPrivate
  extend ActiveSupport::Concern

  private
  
  def create_source_and_account
    source = Source.new
    source.user = self
    source.name = self.name
    source.slogan = self.name
    source.save!
    self.update_columns(source_id: source.id)
  end

  def set_token
    self.token = User.token('checkdesk', self.id, Devise.friendly_token[0, 8], Devise.friendly_token[0, 8]) if self.token.blank?
  end

  def set_login
    if self.login.blank?
      if self.email.blank?
        self.login = self.name.tr(' ', '-').downcase
      else
        self.login = self.email.split('@')[0]
      end
    end
  end

  def send_welcome_email
    RegistrationMailer.delay.welcome_email(self) if self.encrypted_password? && CONFIG['send_welcome_email_on_registration'] && !self.is_invited?
  end

  def user_is_member_in_current_team
    unless self.current_team_id.blank?
      tu = TeamUser.where(user_id: self.id, team_id: self.current_team_id, status: 'member').last
      if tu.nil?
        self.current_team_id = nil
        self.save(validate: false)
      end
    end
  end

  def validate_duplicate_email
    u = User.where(email: self.email).where.not(id: self.id).last unless self.email.blank?
    unless u.nil?
      if u.is_active?
        RegistrationMailer.delay.duplicate_email_detection(self, u) if self.new_record?
      else
        self.errors.messages.clear
        errors.add(:base, I18n.t(:banned_user, app_name: CONFIG['app_name'], support_email: CONFIG['support_email']))
      end
      return false
    end
  end

  def skip_confirmation_for_non_email_provider
    self.skip_confirmation! if self.from_omniauth_login && self.skip_confirmation_mail.nil?
  end

  def set_blank_email_for_unconfirmed_user
    self.update_columns(email: '') unless self.unconfirmed_email.blank?
  end

  def can_destroy_user
    count = ProjectMedia.where(user_id: self.id).count
    count += ProjectSource.where(user_id: self.id).count
    return false if count > 0
  end
  
end
