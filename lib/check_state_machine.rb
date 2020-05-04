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
    state :waiting_for_message, initial: true
    state :main
    state :secondary
    state :query
    state :human_mode

    event :start do
      transitions :from => [:waiting_for_message, :main], :to => :main
    end

    event :reset do
      transitions :from => [:human_mode, :main, :secondary, :query, :waiting_for_message], :to => :waiting_for_message
    end

    event :enter_human_mode do
      transitions :from => [:human_mode, :main, :secondary, :query, :waiting_for_message], :to => :human_mode
    end

    event :leave_human_mode do
      transitions :from => :human_mode, :to => :waiting_for_message
    end

    event :go_to_secondary do
      transitions :from => [:human_mode, :main, :secondary, :query, :waiting_for_message], :to => :secondary
    end

    event :go_to_main do
      transitions :from => [:human_mode, :main, :secondary, :query, :waiting_for_message], :to => :main
    end

    event :go_to_query do
      transitions :from => [:human_mode, :main, :secondary, :query, :waiting_for_message], :to => :query
    end
  end
end
