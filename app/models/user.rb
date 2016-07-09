class User < ActiveRecord::Base
  attr_accessible :email, :login, :name, :profile_image, :password, :password_confirmation
  attr_accessor :url

  has_one :source

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:twitter, :facebook]

  after_create :create_source_and_account
  before_save :set_token, :set_login, :set_uuid

  def self.from_omniauth(auth)
    token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
    user = User.where(provider: auth.provider, uuid: auth.uid).first || User.new
    user.email = auth.info.email
    user.password ||= Devise.friendly_token[0,20]
    user.name = auth.info.name
    user.uuid = auth.uid
    user.provider = auth.provider
    user.profile_image = auth.info.image
    user.token = token
    user.url = auth.url
    user.save!
    user.reload
  end

  def self.token(provider, id, token, secret)
    Base64.encode64({
      provider: provider.to_s,
      id: id.to_s,
      token: token.to_s,
      secret: secret.to_s
    }.to_json).gsub("\n", '++n')
  end

  def self.from_token(token)
    JSON.parse(Base64.decode64(token.gsub('++n', "\n")))
  end

  def as_json(_options = {})
    {
      name: self.name,
      email: self.email,
      login: self.login,
      uuid: self.uuid,
      provider: self.provider,
      token: self.token
    }
  end

  def email_required?
    self.provider.blank?
  end

  def password_required?
    super && self.provider.blank?
  end

  private

  def create_source_and_account
    source = Source.new
    source.user = self
    source.name = self.name
    source.avatar = self.profile_image
    source.save!

    if !self.provider.blank? && !self.url.blank?
      account = Account.new
      account.user = self
      account.source = source
      account.url = self.url
      account.save!
    end
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

  def set_uuid
    self.uuid = ('checkdesk_' + Digest::MD5.hexdigest(self.email)) if self.uuid.blank?
  end
end
