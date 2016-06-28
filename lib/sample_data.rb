module SampleData

  # Methods to generate random data

  def random_string(length = 10)
    (0...length).map{ (65 + rand(26)).chr }.join
  end

  def random_number(max = 50)
    rand(max) + 1
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
    account.url = options[:url]
    account.data = options[:data] || {}
    account.user = options[:user] || create_user
    account.source = options[:source] || create_source
    account.save!
    account.reload
  end

  def create_project(options = {})
    project = Project.new
    project.title = options[:title] || random_string
    project.description = options[:description] || random_string(40)
    project.user = options[:user] || create_user
    project.lead_image = options[:lead_image]
    project.save!
    project.reload
  end

  def create_team(options = {})
    team = Team.new
    team.name = options[:name] || random_string
    team.logo = options[:logo]
    team.archived = options[:archived] || false
    team.save!
    team.reload
  end

  def create_media(options = {})
    account = options[:account] || create_account
    project = options[:project] || create_project
    user = options[:user] || create_user
    m = Media.new
    m.url = options[:url]
    m.project_id = project.id
    m.account_id = account.id
    m.user_id = user.id
    m.save!
    m.reload
  end

  def create_source(options = {})
    source = Source.new
    source.name = options[:name] || random_string
    source.slogan = options[:slogan] || random_string(20)
    source.user = options[:user] || create_user
    source.avatar = options[:avatar]
    source.save!
    source.reload
  end

  def create_project_source(options = {})
    ps = ProjectSource.new
    ps.project = options[:project] || create_project
    ps.source = options[:source] || create_source
    ps.save!
    ps.reload
  end

  def create_team_user(options = {})
    tu = TeamUser.new
    tu.team = options[:team] || create_team
    tu.user = options[:user] || create_user
    tu.save!
    tu.reload
  end

  def create_valid_media(options = {})
    m = nil
    url = 'https://www.youtube.com/user/MeedanTube'
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      a = create_account(url: url)
      m = create_media({ url: url, account: a }.merge(options))
    end
    m
  end

  def create_valid_account(options = {})
    a = nil
    url = 'https://www.youtube.com/user/MeedanTube'
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      a = create_account({ url: url }.merge(options))
    end
    a
  end
end
