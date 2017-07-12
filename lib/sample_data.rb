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

  def random_machine_name
    8.times.map { [*'a'..'z'].sample }.join
  end

  def create_api_key(options = {})
    a = ApiKey.new
    options.each do |key, value|
      a.send("#{key}=", value)
    end
    a.save!
    a.reload
  end

  def create_bot_user(options = {})
    u = BotUser.new
    u.name = options[:name] || random_string
    u.login = options.has_key?(:login) ? options[:login] : random_string
    u.profile_image = options.has_key?(:profile_image) ? options[:profile_image] : random_url
    u.provider = options.has_key?(:provider) ? options[:provider] : %w(twitter facebook).sample
    u.email = options[:email] || "#{random_string}@#{random_string}.com"
    u.password = options[:password] || random_string
    u.password_confirmation = options[:password_confirmation] || u.password
    u.is_admin = options[:is_admin] if options.has_key?(:is_admin)
    u.api_key_id = options.has_key?(:api_key_id) ? options[:api_key_id] : create_api_key.id

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
    u.omniauth_info = options[:omniauth_info]
    u.is_admin = options[:is_admin] if options.has_key?(:is_admin)
    u.type = options[:type] if options.has_key?(:type)
    u.api_key_id = options[:api_key_id]

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
    user = options[:user] || create_user
    options = { text: random_string(50), annotator: user, disable_es_callbacks: true }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      p = create_project team: t
      options[:annotated] = create_project_source project: p
    end
    c = Comment.new
    options.each do |key, value|
      c.send("#{key}=", value) if c.respond_to?("#{key}=")
    end

    file = nil
    if options.has_key?(:file)
      file = options[:file]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        c.file = f
      end
    end

    c.save!
    c
  end

  def create_comment_search(options = {})
    c = CommentSearch.new
    pm = options[:parent] || create_media_search
    { id: random_number, text: random_string(50) }.merge(options).each do |key, value|
      c.send("#{key}=", value) if c.respond_to?("#{key}=")
    end
    c.save!(parent: pm.id)
    sleep 1
    c
  end

  def create_tag(options = {})
    options = { tag: random_string(50), annotator: create_user, disable_es_callbacks: true }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      p = create_project team: t
      options[:annotated] = create_project_source project: p
    end
    t = Tag.new
    options.each do |key, value|
      t.send("#{key}=", value) if t.respond_to?("#{key}=")
    end
    t.save!
    t
  end

  def create_tag_search(options = {})
    t = TagSearch.new
    pm = options[:parent] || create_media_search
    { id: random_number, tag: random_string(50) }.merge(options).each do |key, value|
      t.send("#{key}=", value)
    end
    t.save!(parent: pm.id)
    sleep 1
    t
  end

  def create_status(options = {})
    options = { status: 'credible', annotator: create_user, disable_es_callbacks: true }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      p = create_project team: t
      options[:annotated] = create_project_source project: p
    end
    s = Status.new
    options.each do |key, value|
      s.send("#{key}=", value) if s.respond_to?("#{key}=")
    end
    s.annotated.reload if s.annotated
    s.save!
    s
  end

  def create_flag(options = {})
    options = { flag: 'Spam', annotator: create_user }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      p = create_project team: t
      options[:annotated] = create_project_media project: p
    end
    f = Flag.new
    options.each do |key, value|
      f.send("#{key}=", value)
    end
    f.save!
    f
  end

  def create_embed(options = {})
    options = { embed: random_string, annotator: create_user, disable_es_callbacks: true }.merge(options)
    options[:annotated] = create_project_media unless options.has_key?(:annotated)
    em = Embed.new
    options.each do |key, value|
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
    account.skip_pender = options[:skip_pender] if options.has_key?(:skip_pender)
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
    team.slug = options[:slug] || Team.slug_from_name(team.name)
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
    team.private = options.has_key?(:private) ? options[:private] : false
    team.description = options[:description] || random_string
    team.save!
    team.reload
  end

  def create_media(options = {})
    return create_valid_media(options) if options[:url].blank?
    account = options.has_key?(:account) ? options[:account] : create_account
    user = options.has_key?(:user) ? options[:user] : create_user
    type = options.has_key?(:type) ? options[:type] : :link
    m = type.to_s.camelize.constantize.new
    m.url = options[:url]
    m.quote = options[:quote] if options.has_key?(:quote)
    m.account_id = options.has_key?(:account_id) ? options[:account_id] : account.id
    m.user_id = options.has_key?(:user_id) ? options[:user_id] : user.id
    if options.has_key?(:team)
      options[:project_id] = create_project(team: options[:team]).id
    end

    file = nil
    if options.has_key?(:file)
      file = options[:file]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        m.file = f
      end
    end

    m.save!
    unless options[:project_id].blank?
      p = Project.where(id: options[:project_id]).last
      create_project_media media: m, project: p unless p.nil?
    end
    m.reload
  end

  def create_link(options = {})
    create_media(options.merge({ type: 'link' }))
  end

  def create_uploaded_image(options = { file: 'rails.png' })
    create_media(options.merge({ type: 'UploadedImage' }))
  end

  def create_uploaded_file(options = { file: 'test.txt' })
    create_media(options.merge({ type: 'UploadedFile' }))
  end

  def create_claim_media(options = {})
    options = { quote: random_string }.merge(options)
    c = Claim.new
    options.each do |key, value|
      c.send("#{key}=", value) if c.respond_to?("#{key}=")
    end
    c.save!
    c.reload
  end

  def create_source(options = {})
    source = Source.new
    source.name = options[:name] || random_string
    source.slogan = options[:slogan] || random_string(20)
    source.user = options[:user]
    source.avatar = options[:avatar]
    source.team = options[:team] if options.has_key?(:team)
    source.save!

    if options[:team]
      create_project_source(project: create_project(team: options[:team], user: nil), source: source)
    end

    source.reload
  end

  def create_project_source(options = {})
    u = options[:user] || create_user
    options = { disable_es_callbacks: true, user: u }.merge(options)
    ps = ProjectSource.new
    options[:project] = create_project(team: options[:team]) unless options.has_key?(:project)
    options[:source] = create_source unless options.has_key?(:source)
    options.each do |key, value|
      ps.send("#{key}=", value) if ps.respond_to?("#{key}=")
    end
    ps.save!
    ps.reload
  end

  def create_project_media(options = {})
    u = options[:user] || create_user
    options = { disable_es_callbacks: true, user: u }.merge(options)
    pm = ProjectMedia.new
    options[:project] = create_project unless options.has_key?(:project)
    options[:media] = create_valid_media unless options.has_key?(:media)
    options.each do |key, value|
      pm.send("#{key}=", value) if pm.respond_to?("#{key}=")
    end
    pm.save!
    pm.reload
  end

  def create_version(options = {})
    User.current = options[:user] || create_user
    t = create_team
    v = t.versions.last
    User.current = nil
    v
  end

  def create_team_user(options = {})
    tu = TeamUser.new
    team = options[:team] || create_team
    user = options[:user] || create_user
    tu.team_id = options[:team_id] || team.id
    tu.user_id = options[:user_id] || user.id
    tu.role = options[:role]
    tu.status = options[:status] || 'member'
    tu.save!
    tu.reload
  end

  def create_valid_media(options = {})
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item"}}')
    create_media({ account: create_valid_account }.merge(options).merge({ url: url }))
  end

  def create_valid_account(options = {})
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    contact.save!
    contact.reload
  end

  def create_bot(options = {})
    bot = Bot::Bot.new
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
    bot.save!
    bot.reload
  end

  def create_alegre_bot(options = {})
    bot = Bot::Alegre.new
    bot.name = options[:name] || 'Alegre Bot'
    file = 'rails.png'
    if options.has_key?(:avatar)
      file = options[:avatar]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        bot.avatar = f
      end
    end
    bot.save!
    bot.reload
  end

  def create_viber_bot(options = {})
    bot = Bot::Viber.new
    bot.name = options[:name] || 'Viber Bot'
    bot.save!
    bot.reload
  end

  def create_twitter_bot(options = {})
    bot = Bot::Twitter.new
    bot.name = options[:name] || 'Twitter Bot'
    bot.save!
    bot.reload
  end

  def create_facebook_bot(options = {})
    bot = Bot::Facebook.new
    bot.name = options[:name] || 'Facebook Bot'
    bot.save!
    bot.reload
  end

  def create_slack_bot(options = {})
    bot = Bot::Slack.new
    bot.name = options[:name] || 'Slack Bot'
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

  def create_annotation_type(options = {})
    at = DynamicAnnotation::AnnotationType.new
    at.annotation_type = options.has_key?(:annotation_type) ? options[:annotation_type] : random_machine_name
    at.label = options.has_key?(:label) ? options[:label] : random_string(10)
    at.description = options.has_key?(:description) ? options[:description] : ''
    at.singleton = options[:singleton] if options.has_key?(:singleton)
    at.save!
    at
  end

  def create_field_type(options = {})
    ft = DynamicAnnotation::FieldType.new
    ft.field_type = options.has_key?(:field_type) ? options[:field_type] : random_machine_name
    ft.label = options.has_key?(:label) ? options[:label] : random_string(10)
    ft.description = options.has_key?(:description) ? options[:description] : ''
    ft.save!
    ft
  end

  def create_field_instance(options = {})
    fi = DynamicAnnotation::FieldInstance.new
    fi.name = options.has_key?(:name) ? options[:name] : random_machine_name
    fi.field_type_object = options.has_key?(:field_type_object) ? options[:field_type_object] : create_field_type
    fi.annotation_type_object = options.has_key?(:annotation_type_object) ? options[:annotation_type_object] : create_annotation_type
    fi.label = options.has_key?(:label) ? options[:label] : random_string
    fi.description = options[:description]
    fi.optional = options[:optional] if options.has_key?(:optional)
    fi.settings = options[:settings] if options.has_key?(:settings)
    fi.save!
    fi
  end

  def create_field(options = {})
    f = DynamicAnnotation::Field.new
    f.annotation_id = options.has_key?(:annotation_id) ? options[:annotation_id] : create_dynamic_annotation.id
    f.annotation_type = options[:annotation_type] if options.has_key?(:annotation_type)
    f.field_type = options[:field_type] if options.has_key?(:field_type)
    f.field_name = options.has_key?(:field_name) ? options[:field_name] : create_field_instance.name
    f.value = options.has_key?(:value) ? options[:value] : random_string
    if options[:skip_validation]
      f.save(validate: false)
    else
      f.save!
    end
    f.reload
  end

  def create_dynamic_annotation(options = {})
    t = options[:annotation_type]
    create_annotation_type(annotation_type: t) if !options[:skip_create_annotation_type] && !t.blank? && !DynamicAnnotation::AnnotationType.where(annotation_type: t).exists?
    a = Dynamic.new
    a.annotation_type = t
    a.annotator = options.has_key?(:annotator) ? options[:annotator] : create_user
    a.annotated = options[:annotated] || create_project_media
    a.set_fields = options[:set_fields]
    a.disable_es_callbacks = options.has_key?(:disable_es_callbacks) ? options[:disable_es_callbacks] : true
    a.save!
    a
  end

  def create_task(options = {})
    options = {
      label: '5 + 5 = ?',
      type: 'single_choice',
      description: 'Please solve this math puzzle',
      options: ['10', '20', '30'],
      status: 'Unresolved',
      annotator: options[:user] || create_user,
      disable_es_callbacks: true
    }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      p = create_project team: t
      options[:annotated] = create_project_media project: p
    end
    t = Task.new
    options.each do |key, value|
      t.send("#{key}=", value) if t.respond_to?("#{key}=")
    end
    t.save!
    t
  end

  def create_annotation_type_and_fields(annotation_type_label, fields)
    # annotation_type_label = 'Annotation Type'
    # fields = {
    #   Name => [Type Label, optional = true, settings (optional)],
    #   ...
    # }
    annotation_type_name = annotation_type_label.parameterize.gsub('-', '_')
    at = create_annotation_type annotation_type: annotation_type_name, label: annotation_type_label
    fts = fields.values.collect{ |v| v.first }
    fts.each do |label|
      type = label.parameterize.gsub('-', '_')
      DynamicAnnotation::FieldType.where(field_type: type).last || create_field_type(field_type: type, label: label)
    end
    fields.each do |label, type|
      field_label = annotation_type_label + ' ' + label
      field_name = annotation_type_name + '_' + label.parameterize.gsub('-', '_')
      optional = type[1].nil? ? true : type[1]
      settings = type[2] || {}
      field_type = type[0].parameterize.gsub('-', '_')
      type_object = DynamicAnnotation::FieldType.where(field_type: field_type).last
      create_field_instance annotation_type_object: at, name: field_name, label: field_label, field_type_object: type_object, optional: optional, settings: settings
    end
  end
end
