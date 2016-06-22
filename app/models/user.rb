class User < ActiveRecord::Base
  attr_accessible
  has_one :source

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:twitter, :facebook]

  def self.from_omniauth(auth)
    token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
    user = User.where(provider: auth.provider, uuid: auth.uid).first || User.new
    user.email = auth.info.email
    user.password ||= Devise.friendly_token[0,20]
    user.name = auth.info.name
    user.profile_image = auth.info.image
    user.uuid = auth.uid
    user.provider = auth.provider
    user.token = token
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
      profile_image: self.profile_image,
      uuid: self.uuid,
      provider: self.provider,
      token: self.token
    }
  end

  def email_required?
    false
  end

  def password_required?
    super && self.provider.blank?
  end
end
