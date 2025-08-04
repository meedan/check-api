module CheckPusher
  def self.included(base)
    base.send :extend, ClassMethods
  end

  def pusher_channel
    'check-channel-' + Digest::MD5.hexdigest(self.class_name + ':' + self.id.to_s + ':pusher_channel')
  end

  module ClassMethods
    def send_to_pusher(channels, event, data, actor_session_id)
      ::Pusher.trigger(channels, event, { message: data, actor_session_id: actor_session_id }) unless CheckConfig.get('pusher_key').blank?
    end

    def actor_session_id
      RequestStore[:actor_session_id] ||= RequestStore[:request].blank? ? '' : RequestStore[:request].headers['X-Check-Client'].to_s
    end
  end

  class Worker
    include ::Sidekiq::Worker
    include CheckPusher::ClassMethods

    sidekiq_options queue: 'pusher', retry: 0

    def perform(channels, event, data, actor_session_id)
      send_to_pusher(channels, event, data, actor_session_id)
    end
  end
end
