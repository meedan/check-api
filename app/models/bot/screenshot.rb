class Bot::Screenshot
  def self.take_screenshot(url, output)
    screenshoter = File.join(Rails.root, 'bin', 'take-screenshot.js')
    system 'nodejs', screenshoter, "--url=#{url}", "--output=#{output}", "--delay=3"
    system 'convert', Shellwords.escape(output), '-trim', '-strip', '-quality', '90', Shellwords.escape(output)
  end
end
