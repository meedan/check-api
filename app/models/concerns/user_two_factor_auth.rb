require 'active_support/concern'

module UserTwoFactorAuth
  extend ActiveSupport::Concern

  included do
    attr_accessor :two_factor
    devise :two_factor_authenticatable, :two_factor_backupable,
         :otp_secret_encryption_key => CONFIG['two_factor_key']

    def two_factor
      data = {}
      # enable otp for email based only
      data[:can_enable_otp] = self.encrypted_password?
      data[:otp_required] = self.otp_required_for_login?
      data[:qrcode_svg] = ''
      if data[:can_enable_otp] && !data[:otp_required]
        self.otp_secret = User.generate_otp_secret
        self.save!
        # render qrcode if otp is disabled
        issuer = "Meedan-#{CONFIG['app_name']}"
        uri = self.reload.otp_provisioning_uri(self.email, issuer: issuer)
        qrcode = RQRCode::QRCode.new(uri)
        data[:qrcode_svg] = qrcode.as_svg(module_size: 4)
      end
      data
    end

    def two_factor=(options)
      errors = validate_two_factor(options)
      raise errors.to_json unless errors.blank?
      self.otp_required_for_login = options[:otp_required]
      self.skip_check_ability = true
      self.save!
    end

    def generate_otp_codes
      codes = self.generate_otp_backup_codes!
      self.skip_check_ability = true
      self.save!
      codes
    end

    private

    def validate_two_factor(options)
      return { user: false } unless self.encrypted_password?
      errors = []
      errors << { field: 'password', valid: false } unless self.valid_password?(options[:password])
      if options[:otp_required] == true
        errors << { field: 'qrcode', valid: false } if self.current_otp != options[:qrcode]
      end
      errors
    end

  end
end
