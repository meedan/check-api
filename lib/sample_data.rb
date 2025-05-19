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
    name = random_string(5) + '_' + random_string(5) + '_' + random_string(5)
    name.downcase
  end

  def random_complex_password(length = 10)
    length -= 4
    low = random_string(1).downcase
    up  = random_string(1).upcase
    num = ('0'..'9').to_a
    u = ['@', '#', '$', '%', '&'].to_a
    complex = (num.sample(1) + u.sample(1)).join
    random_string(length).concat(low, up, complex)
  end

  def random_ip
    "%d.%d.%d.%d" % [rand(256), rand(256), rand(256), rand(256)]
  end

  def create_api_key(options = {})
    a = ApiKey.new
    options.each do |key, value|
      a.send("#{key}=", value) if a.respond_to?("#{key}=")
    end
    a.title = options[:title] || random_string
    a.description = options[:description] || random_string
    a.save!
    a.reload
  end

  def create_saved_search(options = {})
    ss = SavedSearch.new
    ss.team = options[:team] || create_team
    ss.title = random_string
    ss.filters = {}
    options.each do |key, value|
      ss.send("#{key}=", value) if ss.respond_to?("#{key}=")
    end
    ss.save!
    ss.reload
  end

  def create_bot_user(options = {})
    u = BotUser.new
    u.name = options[:name] || random_string
    u.login = options.has_key?(:login) ? options[:login] : random_string
    u.email = options[:email] || "#{random_string}@#{random_string}.com"
    u.password = options[:password] || random_complex_password
    u.password_confirmation = options[:password_confirmation] || u.password
    u.is_admin = options[:is_admin] if options.has_key?(:is_admin)
    u.api_key_id = options.has_key?(:api_key_id) ? options[:api_key_id] : create_api_key.id
    u.default = options.has_key?(:default) ? options[:default] : false
    u.set_approved true if options.has_key?(:approved) && options[:approved]

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
    u.source.set_avatar(options[:profile_image]) if options.has_key?(:profile_image) && u.source

    if options[:team]
      create_team_user team: options[:team], user: u
    end

    u.reload
  end

  def create_user(options = {})
    return create_omniauth_user(options) if options.has_key?(:provider) && !options[:provider].blank?
    u = User.new
    u.name = options.has_key?(:name) ? options[:name] : random_string
    u.login = options.has_key?(:login) ? options[:login] : random_string
    u.token = options.has_key?(:token) ? options[:token] : random_string(50)
    u.email = options[:email] || "#{random_string}@#{random_string}.com"
    u.password = options.has_key?(:password) ? options[:password] : random_complex_password
    u.password_confirmation = options[:password_confirmation] || u.password
    u.current_team_id = options[:current_team_id] if options.has_key?(:current_team_id)
    u.is_admin = options[:is_admin] if options.has_key?(:is_admin)
    u.is_active = options[:is_active] if options.has_key?(:is_active)
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

    u.skip_confirmation! if options.has_key?(:skip_confirmation) && options[:skip_confirmation] == true

    u.save!
    u.source.set_avatar(options[:profile_image]) if options.has_key?(:profile_image) && u.source

    if options[:team]
      create_team_user team: options[:team], user: u
    end

    confirm = options.has_key?(:confirm) ? options[:confirm] : true
    if confirm
      u.skip_check_ability = true
      u.confirm
    end

    u.reload
  end

  def create_omniauth_user(options = {})
    u_current = User.current
    url = if options.has_key?(:url)
            options[:url]
    else
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      url = random_url
      options[:data] ||= {}
      options[:data] = options[:data].permit(options[:data].keys) if options[:data].respond_to?(:permit)
      data = { url: url, provider: 'twitter', author_picture: 'http://provider/picture.png', title: 'Foo Bar', description: 'Just a test', type: 'profile', author_name: 'Foo Bar' }.merge(options[:data])
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":' + data.to_json + '}')
      url
    end
    options[:uid] = options[:uuid] if options.has_key?(:uuid)
    auth = {}
    provider = options.has_key?(:provider) ? options[:provider] : %w(twitter facebook).sample
    email = options.has_key?(:email) ? options[:email] : "#{random_string}@#{random_string}.com"
    auth[:uid] = options.has_key?(:uid) ? options[:uid] : random_string
    auth[:url] = url
    auth[:info] = options.has_key?(:info) ? options[:info] : {name: random_string, email: email}
    auth[:credentials] = options.has_key?(:credentials) ? options[:credentials] : {token: random_string, secret: random_string}
    auth[:extra] = options.has_key?(:extra) ? options[:extra] : {}
    current_user = options.has_key?(:current_user) ? options[:current_user] : nil
    omniauth = OmniAuth.config.add_mock(provider, auth)
    u = User.from_omniauth(omniauth, current_user)
    # reset User.current as `User.from_omniauth`  set User.current with recent created user
    User.current = u_current
    OmniAuth.config.mock_auth[provider] = nil

    if options.has_key?(:is_admin) && options[:is_admin]
      u.is_admin = options[:is_admin]
      u.skip_check_ability = true
      u.save!
    end
    if options.has_key?(:token)
      a = u.get_social_accounts_for_login({provider: provider, uid: auth[:uid]}).last
      a.update_columns(token: options[:token]) unless a.nil?
    end
    if options[:team]
      create_team_user team: options[:team], user: u
    end
    u.reload
  end

  def create_tag(options = {})
    options = {
      tag: random_string(50),
      annotator: options[:annotator] || create_user,
      disable_es_callbacks: true
    }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      options[:annotated] = create_project_media team: t
    end
    t = Tag.new
    options.each do |key, value|
      t.send("#{key}=", value) if t.respond_to?("#{key}=")
    end
    t.save!
    t
  end

  # Verification status
  def create_status(options = {})
    create_verification_status_stuff if User.current.nil?
    options = {
      status: 'in_progress',
      annotator: options[:annotator] || create_user,
      disable_es_callbacks: true
    }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      pm = create_project_media team: t
      remove_default_status(pm)
      options[:annotated] = pm
    end
    s = Dynamic.new
    s.annotation_type = 'verification_status'
    s.set_fields = { verification_status_status: options[:status] }.to_json
    options.except(:status).each do |key, value|
      s.send("#{key}=", value) if s.respond_to?("#{key}=")
    end
    s.annotated.reload if s.annotated
    s.save!
    s
  end

  def remove_default_status(obj)
    return unless obj.class.name == 'ProjectMedia'
    s = obj.last_status_obj
    s.destroy
  end

  def create_flag(options = {})
    create_flag_annotation_type if DynamicAnnotation::AnnotationType.where(annotation_type: 'flag').last.nil?
    flags = {
      'adult': 0,
      'spoof': 1,
      'medical': 2,
      'violence': 3,
      'racy': 4,
      'spam': 5
    }
    options = {
      set_fields: { flags: flags }.to_json,
      annotator: options[:annotator] || create_user 
    }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      options[:annotated] = create_project_media team: t
    end
    f = Dynamic.new
    f.annotation_type = 'flag'
    options.each do |key, value|
      f.send("#{key}=", value)
    end
    f.save!
    f
  end

  def create_metadata(options = {})
    annotator = options[:annotator] || create_user
    options = { annotator: annotator, disable_es_callbacks: true }.merge(options)
    options[:annotated] = create_media unless options.has_key?(:annotated)
    m = Dynamic.new
    m.annotation_type = 'metadata'
    data = {}
    options.each do |key, value|
      if m.respond_to?("#{key}=")
        m.send("#{key}=", value)
      else
        data[key] = value
      end
    end
    m.set_fields = { metadata_value: data.to_json }.to_json
    m.save!
    m
  end

  def create_annotation(options = {})
    if options.has_key?(:annotation_type) && options[:annotation_type].blank?
      Annotation.create!(options)
    else
      create_tag(options)
    end
  end

  def create_account(options = {})
    options = { disable_es_callbacks: true }.merge(options)
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
    account.disable_es_callbacks = options[:disable_es_callbacks]
    account.skip_pender = options[:skip_pender] if options.has_key?(:skip_pender)
    account.source = options.has_key?(:source) ? options[:source] : create_source(team: options[:team], skip_check_ability: options[:skip_check_ability])
    account.provider = options[:provider]
    account.uid = options[:uid]
    account.email = options[:email]
    account.omniauth_info = options[:omniauth_info]
    account.skip_check_ability = options[:skip_check_ability]
    account.save!
    account.reload
  end

  def create_recent_project(options = {})
    create_project(options)
  end

  def create_team(options = {})
    team = Team.new
    options.each { |k, v| team.send("#{k}=", v) if team.respond_to?("#{k}=") || k.to_s =~ /^set_/ }
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
    team.archived = options[:archived] || 0
    team.private = options.has_key?(:private) ? options[:private] : false
    team.description = options[:description] || random_string
    team.country = options[:country]
    team.save!
    team.disable_es_callbacks = options.has_key?(:disable_es_callbacks) ? options[:disable_es_callbacks] : true
    team.reload
  end

  def create_media(options = {})
    return create_valid_media(options) if options[:url].blank?
    account = options.has_key?(:account) ? options[:account] : create_account({team: options[:team]})
    user = options.has_key?(:user) ? options[:user] : create_user
    type = options.has_key?(:type) ? options[:type] : :link
    m = type.to_s.camelize.constantize.new
    m.url = options[:url]
    m.quote = options[:quote] if options.has_key?(:quote)
    m.account_id = options.has_key?(:account_id) ? options[:account_id] : account.id
    m.user_id = options.has_key?(:user_id) ? options[:user_id] : user.id
    m.disable_es_callbacks = options.has_key?(:disable_es_callbacks) ? options[:disable_es_callbacks] : true

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
    m.reload
  end

  def create_link(options = {})
    create_media(options.merge({ type: 'link' }))
  end

  def create_uploaded_image(options = { file: 'rails.png' })
    create_media(options.merge({ type: 'UploadedImage' }))
  end

  def create_uploaded_file(options = { file: 'test.csv' })
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

  def create_uploaded_video(options = { file: 'rails.mp4' })
    create_media(options.merge({ type: 'UploadedVideo' }))
  end

  def create_uploaded_audio(options = { file: 'rails.mp3' })
    create_media(options.merge({ type: 'UploadedAudio' }))
  end

  def create_source(options = {})
    source = Source.new
    source.name = options[:name] || random_string
    source.slogan = options[:slogan] || random_string(20)
    source.user = options[:user]
    source.avatar = options[:avatar]
    source.team = options[:team] if options.has_key?(:team)
    source.disable_es_callbacks = options.has_key?(:disable_es_callbacks) ? options[:disable_es_callbacks] : true
    source.add_to_project_media_id = options[:add_to_project_media_id] if options.has_key?(:add_to_project_media_id)
    source.urls = options[:urls] if options.has_key?(:urls)
    source.validate_primary_link_exist = options[:validate_primary_link_exist] || false
    file = nil
    if options.has_key?(:file)
      file = options[:file]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        source.file = f
      end
    end
    source.skip_check_ability = options[:skip_check_ability]
    source.save!
    source.reload
  end

  def create_account_source(options = {})
    as = AccountSource.new
    options[:source_id] = create_source.id if !options.has_key?(:source_id) && !options.has_key?(:source)
    options[:account_id] = create_valid_account.id if !options.has_key?(:account_id) && !options.has_key?(:account) && !options.has_key?(:url)
    options.each do |key, value|
      as.send("#{key}=", value) if as.respond_to?("#{key}=")
    end
    as.save!
    as.reload
  end

  def create_project_media(options = {})
    u = options[:user] || create_user
    options = { disable_es_callbacks: true, user: u }.merge(options)
    options[:media_type] = 'Link' unless options[:url].blank?
    options[:media_type] = 'Claim' unless options[:quote].blank?
    options[:media_type] = 'UploadedImage' if options[:is_image]
    pm = ProjectMedia.new
    if options.has_key?(:project) && !options[:project].nil?
      options[:team] = options[:project].team
    end
    options[:team] = create_team unless options.has_key?(:team)
    options[:media] = create_valid_media({team: options[:team]}) unless options.has_key?(:media)
    options.each do |key, value|
      pm.send("#{key}=", value) if pm.respond_to?("#{key}=")
    end
    options[:skip_autocreate_source] = true unless options.has_key?(:skip_autocreate_source)
    pm.source = create_source({ team: options[:team], skip_check_ability: true }) if options[:skip_autocreate_source]
    pm.set_tags = options[:tags] if options[:tags]
    pm.save!
    create_cluster_project_media({ cluster: options[:cluster], project_media: pm}) if options[:cluster]
    pm.reload
  end

  def create_version(options = {})
    v = nil
    with_versioning do
      t = create_team
      claim = create_claim_media skip_check_ability: true
      User.current = options[:user] || create_user
      pm = create_project_media team: t, media: claim, skip_check_ability: true
      v = pm.versions.from_partition(t.id).where(item_type: 'ProjectMedia').last
      User.current = nil
    end
    v
  end

  def create_team_user(options = {})
    tu = TeamUser.new
    team = options[:team] || create_team
    user = options[:user] || create_user
    tu.team = Team.find_by_id(options[:team_id]) || team
    tu.user = User.find_by_id(options[:user_id]) || user
    tu.role = options[:role]
    tu.status = options[:status] || 'member'
    tu.save!
    tu.reload
  end

  def create_valid_media(options = {})
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = random_url
    params = { url: url }
    params[:archivers] = Team.current.enabled_archivers if !Team.current&.enabled_archivers.blank?
    WebMock.stub_request(:get, pender_url).with({ query: params }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","archives":{}}}')
    create_media({ account: create_valid_account({team: options[:team], skip_check_ability: true}) }.merge(options).merge({ url: url }))
  end

  def create_valid_account(options = {})
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = random_url
    options[:data] ||= {}
    data = { url: url, provider: 'twitter', author_picture: 'http://provider/picture.png', title: 'Foo Bar', description: 'Just a test', type: 'profile', author_name: 'Foo Bar' }.merge(options[:data])
    params = { url: Addressable::URI.escape(url) }
    params[:archivers] = Team.current.enabled_archivers if !Team.current&.enabled_archivers.blank?
    WebMock.stub_request(:get, pender_url).with({ query: params }).to_return(body: '{"type":"media","data":' + data.to_json + '}')
    options.merge!({ url: Addressable::URI.escape(url) })
    create_account(options)
  end

  def create_bot(options = {})
    bot = BotUser.new
    bot.name = options[:name] || random_string
    file = 'rails.png'
    if options.has_key?(:avatar)
      file = options[:avatar]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        bot.image = f
      end
    end
    bot.save!
    bot.reload
  end

  def create_alegre_bot(_options = {})
    Bot::Alegre.new(_options)
  end

  def create_slack_bot(_options = {})
    b = create_team_bot(type: 'Bot::Slack')
    Bot::Slack.find(b.id)
  end

  def create_bounce(options = {})
    b = Bounce.new
    b.email = options.has_key?(:email) ? options[:email] : random_email
    b.save!
    b.reload
  end

  def get_es_id(obj)
    Base64.encode64("#{obj.class.name}/#{obj.id}")
  end

  def create_media_search(options = {})
    ms = ElasticItem.new
    pm = options[:project_media] || create_project_media
    options[:id] = get_es_id(pm)
    options[:annotated_id] = pm.id
    options[:annotated_type] = pm.class.name
    options.each do |key, value|
      ms.attributes[key] = value
    end
    $repository.save(ms)
    sleep 1
    $repository.find(options[:id])
  end

  def create_annotation_type(options = {})
    at = DynamicAnnotation::AnnotationType.new
    at.annotation_type = options.has_key?(:annotation_type) ? options[:annotation_type] : random_machine_name
    at.label = options.has_key?(:label) ? options[:label] : random_string(10)
    at.description = options.has_key?(:description) ? options[:description] : ''
    at.singleton = options[:singleton] if options.has_key?(:singleton)
    at.json_schema = options[:json_schema] if at.respond_to?('json_schema=') && options.has_key?(:json_schema)
    at.skip_check_ability = true
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
    fi.default_value = options[:default_value] || ''
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
    if options[:annotated_id] && options[:annotated_type]
      a.annotated_id = options[:annotated_id]
      a.annotated_type = options[:annotated_type]
    else
      a.annotated = options[:annotated] || create_project_media
    end
    a.set_fields = options[:set_fields]
    a.disable_es_callbacks = options.has_key?(:disable_es_callbacks) ? options[:disable_es_callbacks] : true
    file = nil
    if options.has_key?(:file)
      file = options[:file]
    end
    unless file.nil?
      File.open(File.join(Rails.root, 'test', 'data', file)) do |f|
        a.file = [f]
      end
    end
    a.action = options[:action]
    a.save!
    a
  end

  def create_task(options = {})
    options = {
      label: '5 + 5 = ?',
      type: 'single_choice',
      description: 'Please solve this math puzzle',
      options: ['10', '20', '30'],
      status: 'unresolved',
      annotator: options[:user] || create_user,
      fieldset: 'tasks',
      disable_es_callbacks: true,
    }.merge(options)
    unless options.has_key?(:annotated)
      t = options[:team] || create_team
      options[:annotated] = create_project_media team: t
    end
    t = Task.new
    options.each do |key, value|
      t.send("#{key}=", value) if t.respond_to?("#{key}=")
    end
    t.save!
    t
  end

  def create_relationship(options = {})
    t = create_team
    source_id = options[:source_id] || options[:source]&.id || create_project_media(team: t).id
    target_id = options[:target_id] || options[:target]&.id || create_project_media(team: t).id
    options = {
      source_id: source_id,
      target_id: target_id,
      relationship_type: options[:relationship_type]||Relationship.default_type
    }.merge(options)
    r = Relationship.new
    options.each do |key, value|
      r.send("#{key}=", value) if r.respond_to?("#{key}=")
    end
    r.save!
    r
  end

  def create_team_bot(options = {})
    options = {
      name: random_string,
      set_description: random_string,
      set_request_url: random_url,
      team_author_id: options[:team_author_id] || create_team.id,
      set_events: [{ event: 'create_project_media', graphql: nil }]
    }.merge(options)

    tb = BotUser.new
    options.each do |key, value|
      if key.to_s =~ /^set_/
        tb.send(key, value)
      elsif tb.respond_to?("#{key}=")
        tb.send("#{key}=", value)
      end
    end

    File.open(File.join(Rails.root, 'test', 'data', 'rails.png')) do |f|
      tb.image = f
    end

    tb.save!
    tb
  end

  def create_team_bot_installation(options = {})
    options[:team_id] = create_team.id unless options.has_key?(:team_id)
    options[:user_id] = create_team_bot(set_approved: true).id unless options.has_key?(:user_id)
    tbi = TeamBotInstallation.new
    options.each do |key, value|
      tbi.send("#{key}=", value) if tbi.respond_to?("#{key}=")
    end
    tbi.save!
    tbi.reload
  end

  def create_tag_text(options = {})
    tt = TagText.new
    options = {
      text: random_string,
      team_id: options[:team_id] || create_team.id
    }.merge(options)
    options.each do |key, value|
      tt.send("#{key}=", value) if tt.respond_to?("#{key}=")
    end
    tt.save!
    tt
  end

  def create_team_task(options = {})
    tt = TeamTask.new
    options = {
      label: random_string,
      team_id: options[:team_id] || create_team.id,
      task_type: 'free_text',
      fieldset: 'tasks'
    }.merge(options)
    options.each do |key, value|
      tt.send("#{key}=", value) if tt.respond_to?("#{key}=")
    end
    tt.save!
    tt
  end

  def create_login_activity(options = {})
    la = LoginActivity.new
    la.user = options.has_key?(:user) ? options[:user] : create_user
    user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"
    options = { identity: random_email, context: "api/v1/sessions#create", ip: random_ip, user_agent: user_agent }.merge(options)
    options.each do |key, value|
      la.send("#{key}=", value) if la.respond_to?("#{key}=")
    end
    la.save!
    la.reload
  end

  def create_blank_media
    Blank.create!
  end

  def create_tipline_resource(options = {})
    tr = TiplineResource.new
    tr.title = random_string
    tr.content = random_string
    tr.uuid = random_string
    tr.rss_feed_url = random_url
    tr.content_type = 'rss'
    tr.language = 'en'
    tr.number_of_articles = random_number
    tr.team = options[:team] || create_team
    options.each do |key, value|
      tr.send("#{key}=", value) if tr.respond_to?("#{key}=")
    end
    tr.save!
    tr.reload
  end

  def create_tipline_message(options = {})
    TiplineMessage.create!({
      uid: random_string,
      team_id: options[:team_id] || create_team.id,
      language: 'en',
      platform: 'WhatsApp',
      direction: :incoming,
      external_id: random_string,
      sent_at: DateTime.now,
      payload: {'foo' => 'bar'},
      state: 'sent',
    }.merge(options))
  end

  def create_tipline_subscription(options = {})
    TiplineSubscription.create!({
      uid: random_string,
      team_id: options[:team_id] || create_team.id,
      language: 'en',
      platform: 'WhatsApp'
    }.merge(options))
  end

  def create_tipline_request(options = {})
    tr = TiplineRequest.new
    tr.smooch_data = { language: 'en', authorId: random_string, source: { type: 'whatsapp' } } unless options.has_key?(:smooch_data)
    tr.team_id = options[:team_id] || create_team.id unless options.has_key?(:team_id)
    tr.associated = options[:associated] || create_project_media
    tr.smooch_request_type = 'default_requests' unless options.has_key?(:smooch_request_type)
    tr.platform = 'whatsapp' unless options.has_key?(:platform)
    tr.language = 'en' unless options.has_key?(:language)
    options.each do |key, value|
      tr.send("#{key}=", value) if tr.respond_to?("#{key}=")
    end
    tr.save!
    tr.reload
  end

  def create_cluster(options = {})
    options[:project_media] = create_project_media if options[:project_media].blank?
    team = options[:project_media]&.team || create_team
    options[:feed] = options[:feed] || create_feed({ team: team })
    c = Cluster.new
    options.each do |key, value|
      c.send("#{key}=", value) if c.respond_to?("#{key}=")
    end
    c.save!
    # Add item to cluster
    create_cluster_project_media({ cluster: c, project_media: options[:project_media] }) if options[:project_media]
    c.reload
  end

  def create_cluster_project_media(options = {})
    ClusterProjectMedia.create!({
      cluster: options[:cluster] || create_cluster,
      project_media: options[:project_media] || create_project_media
    }.merge(options))
  end

  def create_claim_description(options = {})
    ClaimDescription.create!({
      description: random_string,
      context: random_string,
      user: options[:user] || create_user,
      project_media: options.has_key?(:project_media) ? options[:project_media] : create_project_media,
      enable_create_blank_media: options[:enable_create_blank_media]
    }.merge(options))
  end

  def create_fact_check(options = {})
    FactCheck.create!({
      summary: random_string,
      url: random_url,
      title: random_string,
      user: options[:user] || create_user,
      claim_description: options[:claim_description] || create_claim_description
    }.merge(options))
  end

  def create_explainer(options = {})
    Explainer.create!({
      title: random_string,
      url: random_url,
      description: random_string,
      user: options[:user] || create_user,
      team: options[:team] || create_team,
    }.merge(options))
  end

  def create_explainer_item(options = {})
    ExplainerItem.create!({
      explainer: options[:explainer] || create_explainer,
      project_media: options[:project_media] || create_project_media
    }.merge(options))
  end

  def create_feed(options = {})
    Feed.create!({
      name: random_string,
      team: options[:team] || create_team,
      licenses: [1],
    }.merge(options))
  end

  def create_feed_team(options = {})
    FeedTeam.create!({
      feed: options[:feed] || create_feed,
      team: options[:team] || create_team
    }.merge(options))
  end

  def create_request(options = {})
    Request.create!({
      content: random_string,
      request_type: 'text',
      feed: options[:feed] || create_feed,
      media: options[:media] || create_valid_media
    }.merge(options))
  end

  def create_project_media_request(options = {})
    project_media_id = options[:project_media_id] || create_project_media.id
    request_id = options[:request_id] || create_request.id
    options = {
      project_media_id: project_media_id,
      request_id: request_id,
    }.merge(options)
    pmr = ProjectMediaRequest.new
    options.each do |key, value|
      pmr.send("#{key}=", value) if pmr.respond_to?("#{key}=")
    end
    pmr.save!
    pmr
  end

  def create_monthly_team_statistic(options = {})
    attributes = {
      team: options[:team] || create_team,
      platform: 'WhatsApp',
      language: 'en',
      start_date: DateTime.new(2022,1,1),
      end_date: DateTime.new(2022,1,31)
    }.merge(options)

    MonthlyTeamStatistic.create!(attributes)
  end

  def create_tipline_newsletter(options = {})
    newsletter = TiplineNewsletter.new({
      send_every: ['monday'],
      send_on: Date.parse('3000-12-25'),
      introduction: 'Test',
      time: Time.parse('10:00'),
      timezone: 'BRT',
      content_type: 'static',
      first_article: 'Foo',
      second_article: 'Bar',
      number_of_articles: 2,
      footer: 'Test',
      language: 'en',
      enabled: true,
      team: options[:team] || create_team
    }.merge(options))
    unless options[:header_file].blank?
      File.open(File.join(Rails.root, 'test', 'data', options[:header_file])) do |f|
        newsletter.file = f
      end
    end
    newsletter.save!
    newsletter
  end

  def create_tipline_newsletter_delivery(options = {})
    newsletter_delivery = TiplineNewsletterDelivery.new({
      recipients_count: 100,
      content: 'Test',
      started_sending_at: Time.now.ago(1.minute),
      finished_sending_at: Time.now,
      tipline_newsletter: options[:tipline_newsletter] || create_tipline_newsletter
    }.merge(options))
    newsletter_delivery.save!
    newsletter_delivery
  end

  def create_rss_feed(custom_url = nil)
    url = custom_url || random_url
    rss = %{
      <rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
        <channel>
          <title>Test</title>
          <link>http://test.com/rss.xml</link>
          <description>Test</description>
          <language>en</language>
          <lastBuildDate>Fri, 09 Oct 2020 18:00:48 GMT</lastBuildDate>
          <managingEditor>test@test.com (editors)</managingEditor>
          <item>
            <title>Foo</title>
            <description>This is the description.</description>
            <pubDate>Wed, 11 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://foo</link>
          </item>
          <item>
            <title>Bar</title>
            <description>This is the description.</description>
            <pubDate>Wed, 10 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://bar</link>
          </item>
        </channel>
      </rss>
    }
    WebMock.stub_request(:get, url).to_return(status: 200, body: rss)
    RssFeed.new(url)
  end

  # Methods below should be deleted when we remove dynamic annotations
  # Right now they are used in migrations to build up our existing data for
  # development environment.

  # They should no longer be used in GraphQL controller tests, as we load in the schema via
  # TestDynamicAnnotationTables.load! before every test run.

  # Because of our non-controller / GraphQL tests modify the existing annotations, the methods
  # below will still need to be used there until we update our code.

  def create_annotation_type_and_fields(annotation_type_label, fields, json_schema = nil)
    # annotation_type_label = 'Annotation Type'
    # fields = {
    #   Name => [Type Label, optional = true, settings (optional)],
    #   ...
    # }
    annotation_type_name = annotation_type_label.parameterize.tr('-', '_')
    if Bot::Keep.archiver_annotation_types.include?(annotation_type_name)
      field_name_prefix = annotation_type_name
      annotation_type_name = 'archiver'
      annotation_type_label = 'Archiver'
    end
    at = DynamicAnnotation::AnnotationType.where(annotation_type: annotation_type_name).last || create_annotation_type(annotation_type: annotation_type_name, label: annotation_type_label, json_schema: json_schema)
    if json_schema.nil?
      fts = fields.values.collect{ |v| v.first }
      fts.each do |label|
        type = label.parameterize.tr('-', '_')
        DynamicAnnotation::FieldType.where(field_type: type).last || create_field_type(field_type: type, label: label)
      end
      fields.each do |label, type|
        field_label = annotation_type_label + ' ' + label
        field_name = (field_name_prefix || annotation_type_name) + '_' + label.parameterize.tr('-', '_')
        optional = type[1].nil? ? true : type[1]
        settings = type[2] || {}
        field_type = type[0].parameterize.tr('-', '_')
        type_object = DynamicAnnotation::FieldType.where(field_type: field_type).last
        DynamicAnnotation::FieldInstance.where(name: field_name).last || create_field_instance(annotation_type_object: at, name: field_name, label: field_label, field_type_object: type_object, optional: optional, settings: settings)
      end
    end
  end

  def create_verification_status_stuff(delete_existing = true)
    if delete_existing
      [DynamicAnnotation::FieldType, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldInstance].each { |klass| klass.delete_all }
      create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
    end
    ft1 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'select').last || create_field_type(field_type: 'select', label: 'Select')
    at = create_annotation_type annotation_type: 'verification_status', label: 'Verification Status'
    create_field_instance annotation_type_object: at, name: 'verification_status_status', label: 'Verification Status', default_value: 'undetermined', field_type_object: ft2, optional: false
    create_field_instance annotation_type_object: at, name: 'title', label: 'Title', field_type_object: ft1, optional: true
    create_field_instance annotation_type_object: at, name: 'file_title', label: 'File Title', field_type_object: ft1, optional: true
    create_field_instance annotation_type_object: at, name: 'content', label: 'Content', field_type_object: ft1, optional: true
    create_field_instance annotation_type_object: at, name: 'published_article_url', label: 'Published Article URL', field_type_object: ft1, optional: true
    create_field_instance annotation_type_object: at, name: 'date_published', label: 'Date Published', field_type_object: ft1, optional: true
    create_field_instance annotation_type_object: at, name: 'raw', label: 'Raw', field_type_object: ft1, optional: true
    create_field_instance annotation_type_object: at, name: 'external_id', label: 'External ID', field_type_object: ft1, optional: true
  end

  def create_metadata_stuff
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'metadata').last || create_annotation_type(annotation_type: 'metadata', label: 'Metadata')
    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    DynamicAnnotation::FieldInstance.where(name: 'metadata_value').last || create_field_instance(annotation_type_object: at, name: 'metadata_value', label: 'Metadata Value', field_type_object: ft, optional: false, settings: {})
    create_verification_status_stuff(false) unless DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').exists?
  end

  def create_flag_annotation_type
    json_schema = {
      type: 'object',
      required: ['flags'],
      properties: {
        flags: {
          type: 'object',
          required: ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam'],
          properties: {
            adult: { type: 'integer', minimum: 0, maximum: 5 },
            spoof: { type: 'integer', minimum: 0, maximum: 5 },
            medical: { type: 'integer', minimum: 0, maximum: 5 },
            violence: { type: 'integer', minimum: 0, maximum: 5 },
            racy: { type: 'integer', minimum: 0, maximum: 5 },
            spam: { type: 'integer', minimum: 0, maximum: 5 }
          }
        }
      }
    }
    create_annotation_type_and_fields('Flag', {}, json_schema)
  end

  def create_extracted_text_annotation_type
    json_schema = {
      type: 'object',
      required: ['text'],
      properties: {
        text: { type: 'string' }
      }
    }
    create_annotation_type_and_fields('Extracted Text', {}, json_schema)
  end

  def create_report_design_annotation_type
    json_schema = {
      type: 'object',
      properties: {
        state: { type: 'string', default: 'paused' },
        last_error: { type: 'string', default: '' },
        last_published: { type: 'string', default: '' },
        options: {
          type: 'object',
          properties: {
            use_introduction: { type: 'boolean', default: false },
            introduction: { type: 'string', default: '' },
            use_visual_card: { type: 'boolean', default: false },
            visual_card_url: { type: 'string', default: '' },
            image: { type: 'string', default: '' },
            headline: { type: 'string', default: '' },
            description: { type: 'string', default: '' },
            status_label: { type: 'string', default: '' },
            previous_published_status_label: { type: 'string', default: '' },
            theme_color: { type: 'string', default: '' },
            url: { type: 'string', default: '' },
            use_text_message: { type: 'boolean', default: false },
            title: { type: 'string', default: '' },
            language: { type: 'string', default: '' },
            text: { type: 'string', default: '' },
            date: { type: 'string', default: '' }
          }
        }
      }
    }
    create_annotation_type_and_fields('Report Design', {}, json_schema)
  end

  def create_task_stuff(delete_existing = true)
    if delete_existing
      [DynamicAnnotation::FieldType, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldInstance].each { |klass| klass.delete_all }
      create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
    end
    sel = create_field_type field_type: 'select', label: 'Select'
    text = create_field_type field_type: 'text', label: 'Text'
    at = create_annotation_type annotation_type: 'task_response_single_choice', label: 'Task Response Single Choice'
    create_field_instance annotation_type_object: at, name: 'response_single_choice', label: 'Response', field_type_object: sel, optional: false, settings: { multiple: false }
    at = create_annotation_type annotation_type: 'task_response_multiple_choice', label: 'Task Response Multiple Choice'
    create_field_instance annotation_type_object: at, name: 'response_multiple_choice', label: 'Response', field_type_object: sel, optional: false, settings: { multiple: true }
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text'
    create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: text, optional: false
  end

  def create_blocked_tipline_user(options = {})
    BlockedTiplineUser.create!({ uid: random_string }.merge(options))
  end

  def create_feed_invitation(options = {})
    FeedInvitation.create!({
      email: random_email,
      feed: options[:feed] || create_feed,
      user: options[:user] || create_user,
      state: :invited 
    }.merge(options))
  end

  def create_relevant_results_item(options = {})
    options[:team] = create_team unless options.has_key?(:team)
    options[:user] = create_user unless options.has_key?(:user)
    options[:article] = create_explainer unless options.has_key?(:article)
    options[:user_action] ||= 'relevant_articles'
    options[:query_media_parent_id] = create_project_media(team: options[:team]).id unless options.has_key?(:query_media_parent_id)
    options[:relevant_results_render_id] ||= Digest::MD5.hexdigest("#{RequestStore[:actor_session_id]}-#{Time.now.to_i}")
    rr = RelevantResultsItem.new
    options.each do |k, v|
      rr.send("#{k}=", v) if rr.respond_to?("#{k}=")
    end
    rr.skip_check_ability = true
    rr.save!
    rr.reload
  end
end
