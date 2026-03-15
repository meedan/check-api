# config/initializers/sql_debug.rb

if Rails.env.development?
  ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
    next unless payload[:sql]&.start_with?('SELECT "annotations"')

    Rails.logger.warn "=== ANNOTATION SELECT ==="
    Rails.logger.warn payload[:sql]
    Rails.logger.warn caller.grep(/app\//).first
    Rails.logger.warn "========================"
  end
end
