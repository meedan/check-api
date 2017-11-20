CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/config.yml")).result)[Rails.env]
WebMock.allow_net_connect!
