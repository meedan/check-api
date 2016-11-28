module SampleData

  # Methods to generate random data

  def random_string(length = 10)
    (0...length).map{ (65 + rand(26)).chr }.join
  end

  def random_url
    'http://' + random_string + '.com'
  end

  def random_number(max = 50)
    rand(max) + 1
  end

  def random_email
    random_string + '@' + random_string + '.com'
  end

  def random_valid_phone
    "00201".to_s + random_number(2).to_s +  8.times.map{rand(9)}.join
  end

  def create_api_key(options = {})
    a = ApiKey.new
    options.each do |key, value|
      a.send("#{key}=", value)
    end
    a.save!
    a.reload
  end

  def create_user(options = {})
    u = User.new
    u.name = options[:name] || random_string
    u.login = options.has_key?(:login) ? options[:login] : random_string
    u.profile_image = options.has_key?(:profile_image) ? options[:profile_image] : random_url
    u.uuid = options.has_key?(:uuid) ? options[:uuid] : random_string
    u.provider = options.has_key?(:provider) ? options[:provider] : %w(twitter facebook).sample
    u.token = options.has_key?(:token) ? options[:token] : random_string(50)
    u.email = options[:email] || "#{random_string}@#{random_string}.com"
    u.password = options[:password] || random_string
    u.password_confirmation = options[:password_confirmation] || u.password
    u.url = options[:url] if options.has_key?(:url)
    u.current_team_id = options[:current_team_id] if options.has_key?(:current_team_id)
    u.current_user = options[:current_user] if options.has_key?(:current_user)
    u.omniauth_info = options[:omniauth_info]

    file = nil
    if options.has_key?(:image)
      file = options[:image]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        u.image = f
      end
    end

    u.save!

    if options[:team]
      create_team_user team: options[:team], user: u
    end

    u.reload
  end

  def create_comment(options = {})
    options = { text: random_string(50), annotator: create_user, annotated: create_source }.merge(options)
    c = Comment.new
    if options.has_key?(:team)
      options[:context] = create_project(team: options[:team])
    end
    options.each do |key, value|
      c.send("#{key}=", value) if c.respond_to?("#{key}=")
    end
    c.save!
    c
  end

  def create_comment_search(options = {})
    c = CommentSearch.new
    { text: random_string(50) }.merge(options).each do |key, value|
      c.send("#{key}=", value) if c.respond_to?("#{key}=")
    end
    c.save!
    sleep 1
    c
  end

  def create_tag(options = {})
    if options[:team]
      options[:context] = create_project(team: options.delete(:team))
    end
    t = Tag.new
    { tag: random_string(50), annotator: create_user, annotated: create_source }.merge(options).each do |key, value|
      t.send("#{key}=", value)
    end
    t.save!
    t
  end

  def create_tag_search(options = {})
    t = TagSearch.new
    { tag: random_string(50) }.merge(options).each do |key, value|
      t.send("#{key}=", value)
    end
    t.save!
    sleep 1
    t
  end

  def create_status(options = {})
    type = id = nil
    unless options.has_key?(:annotated) && options[:annotated].nil?
      a = options.delete(:annotated) || create_source
      type, id = a.class.name, a.id.to_s
    end
    options = { status: 'credible', annotator: create_user, annotated_type: type, annotated_id: id }.merge(options)
    if options[:team]
      options[:context] = create_project(team: options[:team])
    end
    s = Status.new
    options.each do |key, value|
      s.send("#{key}=", value) if s.respond_to?("#{key}=")
    end
    s.save!
    s
  end

  def create_flag(options = {})
    type = id = nil
    unless options.has_key?(:annotated) && options[:annotated].nil?
      m = options.delete(:annotated) || create_valid_media
      type, id = m.class.name, m.id.to_s
    end
    f = Flag.new
    { flag: 'Spam', annotator: create_user, annotated_type: type, annotated_id: id }.merge(options).each do |key, value|
      f.send("#{key}=", value)
    end
    f.save!
    f
  end

  def create_embed(options = {})
    type = id = nil
    unless options.has_key?(:annotated) && options[:annotated].nil?
      p = options.delete(:annotated) || create_project
      type, id = p.class.name, p.id.to_s
    end
    em = Embed.new
    { embed: random_string, annotator: create_user, annotated_type: type, annotated_id: id }.merge(options).each do |key, value|
      em.send("#{key}=", value)
    end
    em.save!
    em
  end

  def create_annotation(options = {})
    if options.has_key?(:annotation_type) && options[:annotation_type].blank?
      Annotation.create!(options)
    else
      create_comment(options)
    end
  end

  def create_account(options = {})
    return create_valid_account(options) unless options.has_key?(:url)
    account = Account.new
    account.url = options[:url]
    if options.has_key?(:user_id)
      account.user_id = options[:user_id]
    else
      account.user = options[:user] || create_user
    end
    if options.has_key?(:team_id)
      account.team_id = options[:team_id]
    elsif options.has_key?(:team)
      account.team = options[:team]
    end
    account.source = options.has_key?(:source) ? options[:source] : create_source(team: options[:team])
    account.save!
    account.reload
  end

  def create_project(options = {})
    project = Project.new
    project.title = options[:title] || random_string
    project.description = options[:description] || random_string(40)
    project.user = options.has_key?(:user) ? options[:user] : create_user
    file = 'rails.png'
    if options.has_key?(:lead_image)
      file = options[:lead_image]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        project.lead_image = f
      end
    end
    project.archived = options[:archived] || false
    project.current_user = options[:current_user] if options.has_key?(:current_user)
    project.context_team = options[:context_team] if options.has_key?(:context_team)
    team = options[:team] || create_team
    project.team_id = options[:team_id] || team.id
    project.save!
    project.reload
  end

  def create_recent_project(options = {})
    create_project(options)
  end

  def create_team(options = {})
    team = Team.new
    team.name = options[:name] || random_string
    team.subdomain = options[:subdomain] || Team.subdomain_from_name(team.name)
    file = 'rails.png'
    if options.has_key?(:logo)
      file = options[:logo]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        team.logo = f
      end
    end
    team.archived = options[:archived] || false
    team.private = options[:private] || false
    team.description = options[:description] || random_string
    team.current_user = options[:current_user] if options.has_key?(:current_user)
    team.origin = options[:origin] if options.has_key?(:origin)
    team.save!
    team.reload
  end

  def create_media(options = {})
    return create_valid_media(options) if options[:url].blank?
    account = options.has_key?(:account) ? options[:account] : create_account
    user = options.has_key?(:user) ? options[:user] : create_user
    m = Media.new
    m.url = options[:url]
    m.account_id = options.has_key?(:account_id) ? options[:account_id] : account.id
    m.current_user = options[:current_user] if options.has_key?(:current_user)
    m.user_id = options.has_key?(:user_id) ? options[:user_id] : user.id
    if options.has_key?(:team)
      options[:project_id] = create_project(team: options[:team]).id
    end
    m.project_id = options[:project_id]
    m.information = options[:information] if options.has_key?(:information)
    m.save!
    m.reload
  end

  def create_claim_media(options = {})
    options = { information: {quote: random_string}.to_json }.merge(options)
    m = Media.new
    options.each do |key, value|
      m.send("#{key}=", value) if m.respond_to?("#{key}=")
    end
    m.save!
    m.reload
  end

  def create_source(options = {})
    source = Source.new
    source.name = options[:name] || random_string
    source.slogan = options[:slogan] || random_string(20)
    source.user = options[:user]
    source.avatar = options[:avatar]
    source.save!

    if options[:team]
      create_project_source(project: create_project(team: options[:team], user: nil), source: source)
    end

    source.reload
  end

  def create_project_source(options = {})
    ps = ProjectSource.new
    project = options[:project] || create_project(team: options[:team])
    source = options[:source] || create_source
    ps.project_id = options[:project_id] || project.id
    ps.source_id = options[:source_id] || source.id
    ps.save!
    ps.reload
  end

  def create_project_media(options = {})
    pm = ProjectMedia.new
    project = options[:project] || create_project
    media = options[:media] || create_valid_media
    pm.project_id = options[:project_id] || project.id
    pm.media_id = options[:media_id] || media.id
    pm.media = media if media
    pm.current_user = options[:current_user] if options.has_key?(:current_user)
    pm.save!
    pm
  end

  def create_team_user(options = {})
    tu = TeamUser.new
    team = options[:team] || create_team
    user = options[:user] || create_user
    tu.team_id = options[:team_id] || team.id
    tu.user_id = options[:user_id] || user.id
    tu.role = options[:role]
    tu.status  = options[:status]  || "member"
    tu.current_user = options[:current_user] if options.has_key?(:current_user)
    tu.origin = options[:origin] if options.has_key?(:origin)
    tu.save!
    tu.reload
  end

  def create_valid_media(options = {})
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item"}}')
    create_media({ account: create_valid_account }.merge(options).merge({ url: url }))
  end

  def create_valid_account(options = {})
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = random_url
    options[:data] ||= {}
    data = { url: url, provider: 'twitter', picture: 'http://provider/picture.png', title: 'Foo Bar', description: 'Just a test', type: 'profile' }.merge(options[:data])
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":' + data.to_json + '}')
    options.merge!({ url: url })
    create_account(options)
  end

  def create_contact(options = {})
    contact = Contact.new
    contact.location = options[:location] || random_string
    contact.phone = options[:phone] || random_valid_phone
    contact.web = options[:web] || random_url
    if options.has_key?(:team_id)
      contact.team_id = options[:team_id]
    else
      contact.team = options[:team] || create_team
    end
    contact.current_user = options[:current_user] if options.has_key?(:current_user)
    contact.save!
    contact.reload
  end

  def create_bot(options = {})
    bot = Bot.new
    bot.name = options[:name] || random_string
    file = 'rails.png'
    if options.has_key?(:avatar)
      file = options[:avatar]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        bot.avatar = f
      end
    end
    bot.current_user = options[:current_user] if options.has_key?(:current_user)
    bot.save!
    bot.reload
  end

  def create_bounce(options = {})
    b = Bounce.new
    b.email = options.has_key?(:email) ? options[:email] : random_email
    b.save!
    b.reload
  end

  def create_media_search(options = {})
    m = MediaSearch.new
    { annotated: create_valid_media, context: create_project }.merge(options).each do |key, value|
      m.send("#{key}=", value) if m.respond_to?("#{key}=")
    end
    m.save!
    sleep 1
    m
  end

end
