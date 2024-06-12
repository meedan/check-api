require 'active_support/concern'

module UserPrivate
  extend ActiveSupport::Concern

  private

  def create_source_and_account
    source_name = self.name
    unless Team.current.nil?
      s = Source.get_duplicate(source_name, Team.current)
      source_name += "-#{Time.now.to_i}" unless s.nil?
    end
    source = Source.new
    source.user = self
    source.name = source_name
    source.slogan = source_name
    source.skip_check_ability = true
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
    config_value = JSON.parse(CheckConfig.get('send_welcome_email_on_registration').to_s)
    RegistrationMailer.delay.welcome_email(self) if self.encrypted_password? && config_value && !self.is_invited?
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
    duplicate = User.get_duplicate_user(self.email, self.id)
    unless duplicate[:user].nil?
      errors.add(:email, I18n.t(:email_exists)) if duplicate[:type] == 'Account'
      handle_duplicate_email(duplicate[:user])
      return false
    end
  end

  def password_complexity
    return if password.blank? || password =~ /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,70}$/
    errors.add :password, I18n.t(:error_password_not_strong)
  end

  def handle_duplicate_email(u)
    if u.is_active?
      provider = u.get_user_provider(self.email)
      RegistrationMailer.delay.duplicate_email_detection(self, provider) if self.new_record?
    else
      self.errors.clear
      errors.add(:base, I18n.t(:banned_user, app_name: CheckConfig.get('app_name'), support_email: CheckConfig.get('support_email')))
    end
  end

  def skip_confirmation_for_non_email_provider
    self.skip_confirmation! if self.from_omniauth_login && self.skip_confirmation_mail.nil?
  end

  def set_last_received_terms_email_at
    self.last_received_terms_email_at = Time.now if self.respond_to?(:last_received_terms_email_at) && self.last_received_terms_email_at.nil?
  end

  def set_blank_email_for_unconfirmed_user
    self.update_columns(email: '') unless self.unconfirmed_email.blank?
  end

  def can_destroy_user
    count = ProjectMedia.where(user_id: self.id).count
    throw :abort if count > 0
  end

  def set_user_notification_settings(type, enabled)
    enabled = enabled == "1" ? true : false if enabled.class.name == "String"
    self.send(:"set_#{type}", enabled)
  end

  def freeze_account_ids_and_source_id
    self.frozen_source_id = self.source.id
    self.frozen_account_ids = (self.account_ids + [self.source.account_ids]).flatten
  end
end
