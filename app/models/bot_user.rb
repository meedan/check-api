class BotUser < User
  before_validation :set_fields
  validates :api_key_id, presence: true, uniqueness: true

  belongs_to :api_key

  devise

  def email_required?
    false
  end

  def password_required?
    false
  end

  def active_for_authentication?
    false
  end

  protected

  def confirmation_required?
    false
  end

  private

  def set_uuid
    self.uuid = ('check_bot_user_' + SecureRandom.hex(10))
  end

  def set_fields
    self.provider = ''
    self.email = self.password = self.password_confirmation = nil
    self.is_admin = false
    true
  end
end
