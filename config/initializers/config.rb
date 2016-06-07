CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
WebMock.allow_net_connect!
