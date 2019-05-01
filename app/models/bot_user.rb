class BotUser < User
  before_validation :set_fields
  validates :api_key_id, presence: true, uniqueness: true

  belongs_to :api_key, dependent: :destroy
  belongs_to :source, dependent: :destroy
  has_one :team_bot

  devise

  check_settings

  def email_required?
    false
  end

  def password_required?
    false
  end

  def active_for_authentication?
    false
  end

  def bot_events
    self.team_bot ? self.team_bot.events.collect{ |e| e['event'] || e[:event] }.join(',') : ''
  end

  def is_bot
    true
  end

  protected

  def confirmation_required?
    false
  end

  private

  def set_fields
    self.email = self.password = self.password_confirmation = nil
    self.is_admin = false
    true
  end
end
