# http://www.rubydoc.info/github/plataformatec/devise/Devise%2FModels%2FAuthenticatable%3Asend_devise_notification
module DeviseAsync
  #######################################################################
  # Override Devise email logic for sending asynchronously with Sidekiq #
  #######################################################################

  def self.included(clazz)
    clazz.class_eval do
      after_commit :send_pending_notifications

      protected

      # If the resource has been changed, wait until the after_commit flag is fired before sending the notification
      def send_devise_notification(notification, *args)
        if self.changed?
          pending_notifications << [notification, args]
        else
          devise_mailer.delay.send(notification, self, *args)
        end
      end

      def send_pending_notifications
        pending_notifications.each do |notification, args|
          devise_mailer.delay.send(notification, self, *args)
        end
      end

      def pending_notifications
        @pending_notifications ||= []
      end

    end
  end

end
