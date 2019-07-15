require 'active_support/concern'

module UserTwoFactorAuth
  extend ActiveSupport::Concern

  included do
  	attr_accessor :two_factor
  	devise :two_factor_authenticatable, :two_factor_backupable,
         :otp_secret_encryption_key => ENV['TWO_FACTOR_KEY']

		def two_factor
			data = { has_otp: false, otp_required: false, qrcode_svg: '' }
			if self.encrypted_password?
		    issuer = "Meedan-#{CONFIG['app_name']}"
		    uri = self.otp_provisioning_uri(self.email, issuer: issuer)
		    qrcode = RQRCode::QRCode.new(uri)
		    data = {
		    	has_otp: true,
		      otp_required: self.otp_required_for_login,
		      qrcode_svg: qrcode.as_svg(module_size: 4)
		    }
	  	end
	  	data
	  end

	  def two_factor=(options)
	  	errors = validate_two_factor(options)
	  	if errors.blank?
	    	self.otp_required_for_login = options[:opt_required]
	    	self.otp_secret = User.generate_otp_secret if options[:opt_required] == true
	    	self.skip_check_ability = true
	    	self.save!
	  	end
	  	errors
	  end

	  def generate_otp_codes
	  	codes = self.generate_otp_backup_codes!
	  	self.skip_check_ability = true
	  	self.save!
	  	codes
	  end

	  private

	  def validate_two_factor(options)
	  	errors = []
	  	errors << {key: 'password', error: 'invalid'} unless self.valid_password?(options[:password])
	  	if options[:opt_required] == true
	  		errors << {key: 'otp', error: 'invalid'} if self.current_otp != options[:qrcode]
	  	end
	  	errors
	  end

  end
end
