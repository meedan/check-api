class Bot::Screenshoter
  def initialize
    path = File.join(Rails.root, 'bin', 'phantomjs-' + (1.size * 8).to_s)
    version = `#{path} --version`
    if (version.chomp =~ /^[0-9.]+/).nil?
      path = `which phantomjs`
      version = `#{path.chomp} --version`
    end

    raise 'PhantomJS not found!' if (version.chomp =~ /^[0-9.]+/).nil?

    options = { phantomjs: path.chomp, timeout: 40 }

    if Rails.env.test?
      options.merge! run_server: true
    end

    @smartshot = Smartshot::Screenshot.new(options)
  end

  def take_screenshot(url, element, output)
    @smartshot.take_screenshot!({ url: url, output: output, wait_for_element: element, sleep: 30, full: false, selector: element })
  end
end
