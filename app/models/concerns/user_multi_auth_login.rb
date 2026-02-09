require 'active_support/concern'

module UserMultiAuthLogin
  extend ActiveSupport::Concern

  included do
    LOGINPROVIDERS = %w[slack google_oauth2]

    def self.from_omniauth(auth, current_user=nil)
      self.update_facebook_uuid(auth)
      u = User.find_with_omniauth(auth.uid, auth.provider)
      ids = User.excluded_uids(u, current_user)
      duplicate_user = User.get_duplicate_user(auth.info.email, ids)[:user]
      # check if user is invited to check
      duplicate_user.accept_invitation_or_confirm unless duplicate_user.nil?
      u = self.check_merge_users(u, current_user, duplicate_user)
      u ||= current_user
      raise I18n.t('errors.messages.restrict_registration_to_invited_users_only') if u.nil?
      user = self.update_omniauth_user(u, auth)
      User.create_omniauth_account(auth, user) unless auth.url.blank? || auth.provider.blank?
      user.reload
    end

    def self.excluded_uids(u, current_user)
      ids = []
      ids << current_user.id unless current_user.nil?
      ids << u.id unless u.nil?
      ids
    end

    def self.check_merge_users(u, current_user, duplicate_user)
      unless current_user.nil?
        current_user.merge_with(duplicate_user) unless duplicate_user.nil?
        current_user.merge_with(u) unless u.nil?
        u = current_user
      else
        u.merge_with(duplicate_user) unless duplicate_user.nil? || u.nil?
      end
      u ||= duplicate_user
      u
    end

    def self.update_omniauth_user(u, auth)
      user = u
      user.email = user.email.presence || auth.info.email
      user.name = user.name.presence || auth.info.name
      user.login = auth.info.nickname.blank? ? auth.info.name.tr(' ', '-').downcase : auth.info.nickname
      user.from_omniauth_login = true
      user.skip_confirmation!
      user.last_accepted_terms_at = Time.now if user.last_accepted_terms_at.nil?
      User.current = user
      user.save!
      user.confirm unless user.is_confirmed?
      user.reload
    end

    def self.create_omniauth_account(auth, user)
      token = User.token(auth.provider, auth.uid, auth.credentials.token, auth.credentials.secret)
      a = Account.where(provider: auth.provider, uid: auth.uid).last
      # check if there is an account with URL
      a = Account.where(url: auth.url).last if a.nil?
      account = a.nil? ? Account.new(created_on_registration: true) : a
      begin
        source = user.source
        account.user = user
        account.source = source
        account.url = auth.url
        account.uid = auth.uid
        account.provider = auth.provider
        account.omniauth_info = auth.as_json
        account.token = token
        account.email = auth.info.email
        if account.save
          account.update_columns(url: auth.url)
          account.sources << source if account.account_sources.where(source_id: source.id).blank?
          user.set_source_image
        end
      rescue StandardError => e
        CheckSentry.notify(e, user_id: user.id)
        Rails.logger.info "Could not create account for user ##{user.id}: #{e.message}"
      end
    end

    def self.update_facebook_uuid(auth)
      # Update uid for facebook account if match email and provider
      if !auth.info.email.blank? && auth.provider == 'facebook'
        fb_account = Account.where(email: auth.info.email, provider: 'facebook').first
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
      return nil if token.blank?
      uid = Rails.cache.fetch("user_id_from_token_#{token}") do
        account = Account.where(token: token).last
        account.nil? ? User.where(token: token).last&.id : account.user&.id
      end
      uid ? User.find_by_id(uid) : nil
    end

    def accept_invitation_or_confirm
      if self.invited_to_sign_up?
        self.accept_invitation!
        token = self.read_attribute(:raw_invitation_token)
        self.team_users.where(status: 'invited').each do |tu|
          User.accept_team_user_invitation(tu, token, {password: "", skip_notification: true}) if tu.invitation_period_valid?
        end
        self.update_column(:raw_invitation_token, nil)
      end
      self.confirm unless self.reload.is_confirmed?
    end

    def get_social_accounts_for_login(conditions = {})
      s = self.source
      if conditions.blank?
        a = s.accounts.where("uid IS NOT NULL AND user_id = ?", self.id)
      else
        conditions[:user_id] = self.id
        a = s.accounts.where(conditions)
      end
      a
    end

    def providers
      providers = []
      accounts = self.get_social_accounts_for_login
      allow_disconnect =  (accounts.count == 1 && !self.encrypted_password?) ? false : true
      LOGINPROVIDERS.each do |p|
        provider_label = p == 'google_oauth2' ? 'Google' : p.capitalize
        provider_accounts = accounts.select{|i| i.provider == p}
        if provider_accounts.blank?
          providers << { key: p, add_another: false, values: [{ connected: false, info: provider_label }] }
        else
          values = []
          provider_accounts.each do |a|
            info = a.omniauth_info.dig('info')
            if a.provider == 'slack'
              name = "#{info['nickname']} at #{info['team']}"
            else
              name = info['name']
            end
            values << { connected: true, uid: "#{a.uid}", allow_disconnect: allow_disconnect, info: "#{provider_label}: #{name}" }
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
          a.update_columns(provider: nil, token: nil, omniauth_info: nil, uid: nil, email: nil)
          # delete account source
          as = a.account_sources.where(source_id: self.source_id).last
          as.skip_check_ability = true
          as.destroy unless as.nil?
        end
      end
    end
  end
end
