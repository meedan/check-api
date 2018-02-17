require 'active_support/concern'

module ViberBotScreenshot
  extend ActiveSupport::Concern

  def text_to_image(m)
    require 'open-uri'

    # Prepare HTML
    av = ActionView::Base.new(Rails.root.join('app', 'views'))
    av.assign(m)
    content = av.render(template: 'viber/screenshot.html.erb', layout: nil)
    filename = 'screenshot-' + Digest::MD5.hexdigest(m.inspect)
    html_path = File.join(Rails.root, 'public', 'viber', filename + '.html')
    File.atomic_write(html_path) { |file| file.write(content) }

    # Request screenshot from Pender
    url = CONFIG['checkdesk_base_url'] + '/viber/' + filename + '.html'
    output = File.join(Rails.root, 'public', 'viber', filename)
    params = { url: url }
    result = PenderClient::Request.get_medias(CONFIG['pender_url_private'], params, CONFIG['pender_key'])
    attempts = 0
    while attempts < 20 && result['data']['screenshot_taken'].to_i == 0
      sleep 15
      attempts += 1
      result = PenderClient::Request.get_medias(CONFIG['pender_url_private'], params, CONFIG['pender_key'])
    end

    # Save screenshot and remove HTML
    screenshot = result['data']['screenshot'].gsub(CONFIG['pender_url'], CONFIG['pender_url_private'])
    open(screenshot) do |f|
      File.atomic_write("#{output}.png") { |file| file.write(f.read) }
    end
    system 'convert', "#{output}.png", "#{output}.jpg"
    FileUtils.rm_f html_path
    FileUtils.rm_f "#{output}.png"
    filename
  end
end
