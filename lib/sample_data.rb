module SampleData
  
  # Methods to generate random data

  def random_string(length = 10)
    (0...length).map{ (65 + rand(26)).chr }.join
  end

  def random_number(max = 50)
    rand(max) + 1
  end

  def random_url
    'http://' + random_string + '.com'
  end

  def random_email
    random_string + '@' + random_string + '.com'
  end

  def create_api_key(options = {})
    ApiKey.create! options
  end

  def create_user(options = {})
    u = User.new
    u.name = options[:name] || random_string
    u.login = options[:login] || random_string
    u.profile_image = options[:profile_image] || random_url
    u.uuid = options[:uuid] || random_string
    u.provider = options[:provider] || %w(twitter facebook).sample
    u.token = options[:token] || random_string(50)
    u.email = options[:email] || "#{random_string}@#{random_string}.com"
    u.password = options[:password] || random_string
    u.save!
    u.reload
  end

  def create_comment(options = {})
    c = Comment.create({ text: random_string(50) }.merge(options))
    sleep 1 if Rails.env.test?
    c.reload
  end
end
