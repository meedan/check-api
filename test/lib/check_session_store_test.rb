require 'test_helper'

class SessionStoreTest < ActiveSupport::TestCase
  def with_environment(env)
    original_env = Rails.env
    Rails.singleton_class.class_eval do
      define_method(:env) { ActiveSupport::StringInquirer.new(env) }
    end
    yield
  ensure
    Rails.singleton_class.class_eval do
      define_method(:env) { original_env }
    end
  end

  test "session store configuration in production" do
    with_environment('production') do
      load Rails.root.join('config/initializers/session_store.rb')
      assert_equal ActionDispatch::Session::CookieStore, Rails.application.config.session_store
      assert_equal '_checkdesk_session', Rails.application.config.session_options[:key]
      assert_equal '.checkmedia.org', Rails.application.config.session_options[:domain]
    end
  end

  test "session store configuration in development" do
    with_environment('development') do
      load Rails.root.join('config/initializers/session_store.rb')
      assert_equal ActionDispatch::Session::CookieStore, Rails.application.config.session_store
      assert_equal '_checkdesk_session', Rails.application.config.session_options[:key]
      assert_equal 'localhost', Rails.application.config.session_options[:domain]
    end
  end

  test "session store configuration in test" do
    with_environment('test') do
      load Rails.root.join('config/initializers/session_store.rb')
      assert_equal ActionDispatch::Session::CookieStore, Rails.application.config.session_store
      assert_equal '_checkdesk_session', Rails.application.config.session_options[:key]
      assert_nil Rails.application.config.session_options[:domain]
    end
  end
end
