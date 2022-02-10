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
    state :subscription
    state :search
    state :search_result
    state :add_more_details
    state :ask_if_ready

    ALL_STATES = [:human_mode, :main, :secondary, :query, :waiting_for_message, :subscription, :search, :search_result, :add_more_details, :ask_if_ready]

    event :start do
      transitions :from => [:waiting_for_message, :main], :to => :main
    end

    event :reset do
      transitions :from => ALL_STATES, :to => :waiting_for_message
    end

    event :enter_human_mode do
      transitions :from => ALL_STATES, :to => :human_mode
    end

    event :leave_human_mode do
      transitions :from => :human_mode, :to => :waiting_for_message
    end

    event :go_to_secondary do
      transitions :from => ALL_STATES, :to => :secondary
    end

    event :go_to_main do
      transitions :from => ALL_STATES, :to => :main
    end

    event :go_to_query do
      transitions :from => ALL_STATES, :to => :query
    end

    event :go_to_subscription do
      transitions :from => ALL_STATES, :to => :subscription
    end

    event :go_to_search do
      transitions :from => ALL_STATES, :to => :search
    end

    event :go_to_search_result do
      transitions :from => ALL_STATES, :to => :search_result
    end

    event :go_to_ask_if_ready do
      transitions :from => ALL_STATES, :to => :ask_if_ready
    end

    event :go_to_add_more_details do
      transitions :from => ALL_STATES, :to => :add_more_details
    end
  end
end
