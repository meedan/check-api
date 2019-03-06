Redis::Objects.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(host: SIDEKIQ_CONFIG[:redis_host], port: SIDEKIQ_CONFIG[:redis_port], db: SIDEKIQ_CONFIG[:redis_database]) } if defined?(SIDEKIQ_CONFIG)

class CheckStateMachine
  include Redis::Objects
  include AASM

  value :state
  value :message

  def initialize(uid)
    @uid = uid
    super()
  end

  def id
    @uid
  end

  aasm column: 'state' do
    state :waiting_for_message, :initial => true
    state :waiting_for_confirmation

    event :send_message do
      transitions :from => :waiting_for_message, :to => :waiting_for_confirmation
    end

    event :confirm do
      transitions :from => :waiting_for_confirmation, :to => :waiting_for_message
    end
  end
end
