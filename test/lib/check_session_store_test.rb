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

  test "session store configuration with default key and domain when config values are not set" do
    with_environment('production') do
      stub_configs({ 'session_store_key' => nil, 'session_store_domain' => nil }) do
        load Rails.root.join('config/initializers/session_store.rb')
        assert_equal ActionDispatch::Session::CookieStore, Rails.application.config.session_store
        assert_equal '_checkdesk_session', Rails.application.config.session_options[:key]
        assert_equal '.checkmedia.org', Rails.application.config.session_options[:domain]
      end
    end
  end

  test "session store configuration with overriding key and domain in config" do
    with_environment('production') do
      stub_configs({ 'session_store_key' => '_checkdesk_session_qa', 'session_store_domain' => 'qa.checkmedia.org' }) do
        load Rails.root.join('config/initializers/session_store.rb')
        assert_equal ActionDispatch::Session::CookieStore, Rails.application.config.session_store
        assert_equal '_checkdesk_session_qa', Rails.application.config.session_options[:key]
        assert_equal 'qa.checkmedia.org', Rails.application.config.session_options[:domain]
      end
    end
  end
end
