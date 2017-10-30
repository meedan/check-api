require 'chromeshot'

puts "Starting Chromeshot on port #{CONFIG['chrome_debug_port']}"

Chromeshot::Screenshot.setup_chromeshot(CONFIG['chrome_debug_port'])

