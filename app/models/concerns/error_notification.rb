require 'active_support/concern'

module ErrorNotification
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_error(error, params = {}, request = nil)
      Rails.logger.error error
      return unless Airbrake.configured?
      notice = Airbrake.build_notice(error, params)
      notice.stash[:rack_request] = request
      Airbrake.notify(notice)
    end
  end
end
