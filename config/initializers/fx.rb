# To make functions available for indexes and default values migrations
Fx.configure do |config|
  config.dump_functions_at_beginning_of_schema = true
end
