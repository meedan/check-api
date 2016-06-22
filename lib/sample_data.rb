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

  def create_annotation(options = {})
    Annotation.create(options)
  end

  def create_account(options = {})
    account = Account.new
    account.url = options[:url] || random_url
    account.save
    account.reload
  end

  def create_project(options = {})
    project = Project.new
    project.title = options[:title] || random_string
    project.description = options[:description] || random_string(40)
    project.save
    project.reload
  end

  def create_team(options = {})
    team = Team.new
    team.name = options[:name] || random_string
    team.archived = options[:archived] || false
    team.save
    team.reload
  end

  def create_media(options = {})
    account = create_account
    project = create_project
    m = Media.new
    m.url = options[:url] || random_url
    m.project_id = project.id
    m.account_id = account.id
    m.save
    m.reload
  end

  def create_source(options = {})
    source = Source.new
    source.name = options[:name] || random_string
    source.slogan = options[:slogan] || random_string(20)
    source.save
    source.reload
  end

end
