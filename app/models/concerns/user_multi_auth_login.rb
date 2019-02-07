require 'active_support/concern'

module UserMultiAuthLogin
  extend ActiveSupport::Concern

  included do
  	LOGINPROVIDERS = %w[slack twitter facebook]

	  def self.from_omniauth(auth, current_user=nil)
	    self.update_facebook_uuid(auth)
	    u = User.find_with_omniauth(auth.uid, auth.provider)
	    # raise error if user try to connect with existing account related to another user.
	    raise RuntimeError, I18n.t(:error_login_with_exists_account) if User.check_user_exists(u, current_user)
	    u ||= current_user
	    user = self.create_omniauth_user(u, auth)
	    User.create_omniauth_account(auth, user) unless auth.url.blank? || auth.provider.blank?
	    user.reload
	  end

	  def self.check_user_exists(user, current_user)
	  	exists = false
	  	unless current_user.nil?
	  		exists = true if !user.nil? && user.id != current_user.id
	  	end
	  	exists
	  end

	  def self.create_omniauth_user(u, auth)
	  	user = u.nil? ? User.new : u
	    user.email = user.email.presence || auth.info.email
	    user.name = user.name.presence || auth.info.name
	    user.login = auth.info.nickname || auth.info.name.tr(' ', '-').downcase
	    user.from_omniauth_login = true
	    User.current = user
	    user.save!
	    user.reload
	  end

	  def self.create_omniauth_account(auth, user)
	    token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
	    a = Account.where(provider: auth.provider, uid: auth.uid).last
	    # check if there is an account with URL
	    a = Account.where(url: auth.url).last if a.nil?
	    account = a.nil? ? Account.new(created_on_registration: true) : a
	    begin
	      account.user = user
	      account.source = user.source
	      account.url = auth.url
	      account.uid = auth.uid
	      account.provider = auth.provider
	      account.omniauth_info = auth.as_json
	      account.token = token
	      account.email = auth.info.email
	      if account.save
	        account.update_columns(url: auth.url)
	        user.set_source_image
	      end
	    rescue Errno::ECONNREFUSED => e
	      Rails.logger.info "Could not create account for user ##{user.id}: #{e.message}"
	    end
	  end

	  def self.update_facebook_uuid(auth)
	  	# Update uid for facebook account if match email and provider
	  	if !auth.info.email.blank? && auth.provider == 'facebook'
	  		fb_user = User.where(email: auth.info.email).first
	  		fb_accounts = fb_user.get_social_accounts_for_login({provider: auth.provider}) unless fb_user.nil?
	  		fb_accounts ||= []
	  		fb_account = fb_accounts.select{|a| a.omniauth_info.dig('info', 'email') == auth.info.email}.first
	      if !fb_account.nil? && fb_account.uid != auth.uid
	        fb_account.uid = auth.uid
	        fb_account.skip_check_ability = true
	        fb_account.url = auth.url
	        fb_account.save!
	      end
	  	end
	  end

	  def self.find_with_omniauth(uid, provider)
	  	a = Account.where(uid: uid, provider: provider).first
	  	a.nil? ? nil : a.user
	  end

	  def self.find_with_token(token)
	    account = Account.where(token: token).last
	    account.nil? ?  User.where(token: token).last : account.user
	  end

	  def get_social_accounts_for_login(conditions = {})
	    s = self.source
	    return nil if s.nil? || !ActiveRecord::Base.connection.column_exists?(:accounts, :uid)
	    if conditions.blank?
	      a = s.accounts.where('uid IS NOT NULL')
	    else
	      a = s.accounts.where(conditions)
	    end
	    a
	  end

	  def providers
	    providers = []
	    accounts = self.get_social_accounts_for_login
	    allow_disconnect =  (accounts.count == 1 && !self.encrypted_password?) ? false : true
	    LOGINPROVIDERS.each do |p|
	      provider_accounts = accounts.select{|i| i.provider == p}
	      if provider_accounts.blank?
	        providers << { key: p, add_another: false, values: [{ connected: false, info: p.capitalize }] }
	      else
	      	values = []
	      	provider_accounts.each do |a|
	      		info = a.omniauth_info.dig('info')
	      		if a.provider == 'slack'
	      			name = "#{info['nickname']} at #{info['team']}"
	      		elsif a.provider == 'twitter'
	      			name = "@#{info['nickname']}"
	      		else
	      			name = info['name']
	      		end
	      		values << { connected: true, uid: "#{a.uid}", allow_disconnect: allow_disconnect, info: "#{p.capitalize}: #{name}" }
	      	end
	        providers << { key: p, add_another: true, values: values }
	      end
	    end
	    providers
	  end

	  def disconnect_login_account(provider, uid)
	    a = self.get_social_accounts_for_login({provider: provider, uid: uid})
	    unless a.nil?
	    	a = a.first
	      if a.sources.count == 1
	        a.skip_check_ability = true
	        a.destroy
	      else
	        # clean account from omniauth info
	        a.update_columns(provider: nil, token: nil, omniauth_info: nil, uid: nil)
	        # delete account source
	        as = a.account_sources.where(source_id: self.source_id).last
	        as.skip_check_ability = true
	        as.destroy unless as.nil?
	      end
	    end
	  end

	  def get_user_provider(email)
	    account = self.get_social_accounts_for_login({email: email})
	    account = account.first unless account.nil?
	    account.nil? ? '' : account.provider
  	end

  end
end