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
    state :human_mode

    event :send_message_new do
      transitions :from => :waiting_for_message, :to => :waiting_for_confirmation
    end

    event :confirm_message do
      transitions :from => :waiting_for_confirmation, :to => :waiting_for_message
    end

    event :send_message_existing do
      transitions :from => :waiting_for_message, :to => :waiting_for_message
    end

    event :enter_human_mode do
      transitions :from => [:human_mode, :waiting_for_message, :waiting_for_confirmation, :waiting_for_tos], :to => :human_mode
    end

    event :leave_human_mode do
      transitions :from => :human_mode, :to => :waiting_for_message
    end
  end
end
