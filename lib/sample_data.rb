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

  def randon_valid_phone
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
    u.profile_image = options[:profile_image] || random_url
    u.uuid = options.has_key?(:uuid) ? options[:uuid] : random_string
    u.provider = options.has_key?(:provider) ? options[:provider] : %w(twitter facebook).sample
    u.token = options.has_key?(:token) ? options[:token] : random_string(50)
    u.email = options[:email] || "#{random_string}@#{random_string}.com"
    u.password = options[:password] || random_string
    u.password_confirmation = options[:password_confirmation] || u.password
    u.url = options[:url] if options.has_key?(:url)
    u.save!
    u.reload
  end

  def create_comment(options = {})
    c = Comment.create({ text: random_string(50), annotator: create_user, annotated: create_source }.merge(options))
    sleep 1 if Rails.env.test?
    c.reload
  end

  def create_tag(options = {})
    t = Tag.create({ tag: random_string(50), annotator: create_user, annotated: create_source }.merge(options))
    sleep 1 if Rails.env.test?
    t.reload
  end

  def create_status(options = {})
    type = id = nil
    unless options.has_key?(:annotated) && options[:annotated].nil?
      a = options.delete(:annotated) || create_source
      type, id = a.class.name, a.id.to_s
    end
    s = Status.create({ status: 'Credible', annotator: create_user, annotated_type: type, annotated_id: id }.merge(options))
    sleep 1 if Rails.env.test?
    s.reload
  end

  def create_flag(options = {})
    type = id = nil
    unless options.has_key?(:annotated) && options[:annotated].nil?
      m = options.delete(:annotated) || create_valid_media
      type, id = m.class.name, m.id.to_s
    end
    f = Flag.create({ flag: 'Spam', annotator: create_user, annotated_type: type, annotated_id: id }.merge(options))
    sleep 1 if Rails.env.test?
    f.reload
  end

  def create_annotation(options = {})
    if options.has_key?(:annotation_type) && options[:annotation_type].blank?
      Annotation.create(options)
    else
      create_comment(options)
    end
  end

  def create_account(options = {})
    return create_valid_account(options) unless options.has_key?(:url)
    account = Account.new
    account.url = options[:url]
    account.data = options[:data] || {}
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
    account.source = options.has_key?(:source) ? options[:source] : create_source
    account.save!
    account.reload
  end

  def create_project(options = {})
    project = Project.new
    project.title = options[:title] || random_string
    project.description = options[:description] || random_string(40)
    project.user = options[:user] || create_user
    project.lead_image = options[:lead_image]
    project.archived = options[:archived] || false
    project.save!
    project.reload
  end

  def create_team(options = {})
    team = Team.new
    team.name = options[:name] || random_string
    if options.has_key?(:logo)
      team.logo = options[:logo]
    else
      File.open(File.join(Rails.root, 'test', 'data', 'rails.png')) do |f|
        team.logo = f
      end
    end
    team.archived = options[:archived] || false
    team.description = options[:description] || random_string
    team.current_user = options[:current_user]
    team.save!
    team.reload
  end

  def create_media(options = {})
    return create_valid_media(options) if options[:url].blank?
    account = options[:account] || create_account
    user = options[:user] || create_user
    m = Media.new
    m.url = options[:url]
    m.account_id = options[:account_id] || account.id
    m.user_id = options[:user_id] || user.id
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
    source.reload
  end

  def create_project_source(options = {})
    ps = ProjectSource.new
    project = options[:project] || create_project
    source = options[:source] || create_source
    ps.project_id = options[:project_id] || project.id
    ps.source_id = options[:source_id] || source.id
    ps.save!
    ps.reload
  end

  def create_project_media(options = {})
    pm = ProjectMedia.new
    project = options[:project] || create_project
    media = options[:source] || create_valid_media
    pm.project_id = options[:project_id] || project.id
    pm.media_id = options[:media_id] || media.id
    pm.save!
    pm.reload
  end

  def create_team_user(options = {})
    tu = TeamUser.new
    team = options[:team] || create_team
    user = options[:user] || create_user
    tu.team_id = options[:team_id] || team.id
    tu.user_id = options[:user_id] || user.id
    tu.save!
    tu.reload
  end

  def create_valid_media(options = {})
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '"}}')
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
    contact.phone = options[:phone] || randon_valid_phone
    contact.web = options[:web] || random_url
    if options.has_key?(:team_id)
      contact.team_id = options[:team_id]
    else
      contact.team = options[:team] || create_team
    end
    contact.save!
    contact.reload
  end

end
