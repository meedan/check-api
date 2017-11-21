require 'chromeshot'

port = CONFIG['chrome_debug_port'] || 9555
unless system("lsof -i:#{port}", out: '/dev/null')
  puts "Starting Chromeshot on port #{port}"
  Chromeshot::Screenshot.setup_chromeshot(port)
end
