require_relative '../test_helper'

class ProjectMedia6Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should get creator name based on channel" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      u = create_user
      pm = create_project_media user: u
      assert_equal pm.creator_name, u.name
      pm2 = create_project_media user: u, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }
      assert_equal pm2.creator_name, 'Tipline'
      pm3 = create_project_media user: u, channel: { main: CheckChannels::ChannelCodes::FETCH }
      assert_equal pm3.creator_name, 'Import'
      # update cache based on user update
      u.name = 'update name'
      u.save!
      assert_equal pm.creator_name, 'update name'
      assert_equal pm.creator_name(true), 'update name'
      assert_equal pm2.creator_name, 'Tipline'
      assert_equal pm2.creator_name(true), 'Tipline'
      assert_equal pm3.creator_name, 'Import'
      assert_equal pm3.creator_name(true), 'Import'
      User.delete_check_user(u)
      assert_equal pm.creator_name, 'Anonymous'
      assert_equal pm.reload.creator_name(true), 'Anonymous'
      assert_equal pm2.creator_name, 'Tipline'
      assert_equal pm2.creator_name(true), 'Tipline'
      assert_equal pm3.creator_name, 'Import'
      assert_equal pm3.creator_name(true), 'Import'
    end
  end

  test "should convert old hash" do
    t = create_team
    pm = create_project_media team: t
    Team.any_instance.stubs(:settings).returns(ActionController::Parameters.new({ media_verification_statuses: { statuses: [] } }))
    assert_nothing_raised do
      pm.custom_statuses
    end
    Team.any_instance.unstub(:settings)
  end

  test "should detach similar items when trash parent item" do
    setup_elasticsearch
    RequestStore.store[:skip_delete_for_ever] = true
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm1_c = create_project_media team: t, disable_es_callbacks: false
    pm1_s = create_project_media team: t, disable_es_callbacks: false
    pm2_s = create_project_media team: t, disable_es_callbacks: false
    r = create_relationship source: pm, target: pm1_c, relationship_type: Relationship.confirmed_type
    r2 = create_relationship source: pm, target: pm1_s, relationship_type: Relationship.suggested_type
    r3 = create_relationship source: pm, target: pm2_s, relationship_type: Relationship.suggested_type
    assert_difference 'Relationship.count', -2 do
      pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm.save!
    end
    assert_raises ActiveRecord::RecordNotFound do
      r2.reload
    end
    assert_raises ActiveRecord::RecordNotFound do
      r3.reload
    end
    pm1_s = pm1_s.reload; pm2_s.reload
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm1_c.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1_s.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm2_s.archived
    # Verify ES
    result = $repository.find(get_es_id(pm1_c))
    assert_equal CheckArchivedFlags::FlagCodes::TRASHED, result['archived']
    result = $repository.find(get_es_id(pm1_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
    result = $repository.find(get_es_id(pm2_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
  end

  test "should detach similar items when spam parent item" do
    setup_elasticsearch
    RequestStore.store[:skip_delete_for_ever] = true
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm1_c = create_project_media team: t, disable_es_callbacks: false
    pm1_s = create_project_media team: t, disable_es_callbacks: false
    pm2_s = create_project_media team: t, disable_es_callbacks: false
    r = create_relationship source: pm, target: pm1_c, relationship_type: Relationship.confirmed_type
    r2 = create_relationship source: pm, target: pm1_s, relationship_type: Relationship.suggested_type
    r3 = create_relationship source: pm, target: pm2_s, relationship_type: Relationship.suggested_type
    assert_difference 'Relationship.count', -2 do
      pm.archived = CheckArchivedFlags::FlagCodes::SPAM
      pm.save!
    end
    assert_raises ActiveRecord::RecordNotFound do
      r2.reload
    end
    assert_raises ActiveRecord::RecordNotFound do
      r3.reload
    end
    pm1_s = pm1_s.reload; pm2_s.reload
    assert_equal CheckArchivedFlags::FlagCodes::SPAM, pm1_c.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1_s.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm2_s.archived
    # Verify ES
    result = $repository.find(get_es_id(pm1_c))
    assert_equal CheckArchivedFlags::FlagCodes::SPAM, result['archived']
    result = $repository.find(get_es_id(pm1_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
    result = $repository.find(get_es_id(pm2_s))
    assert_equal CheckArchivedFlags::FlagCodes::NONE, result['archived']
  end

  test "should complete media if there are pending tasks" do
    pm = create_project_media
    s = pm.last_verification_status_obj
    create_task annotated: pm, required: true
    assert_equal 'undetermined', s.reload.get_field('verification_status_status').status
    assert_nothing_raised do
      s.status = 'verified'
      s.save!
    end
  end

  test "should get account from author URL" do
    s = create_source
    pm = create_project_media
    assert_nothing_raised do
      pm.send :account_from_author_url, @url, s
    end
  end

  test "should not move media to active status if status is locked" do
    pm = create_project_media
    assert_equal 'undetermined', pm.last_verification_status
    s = pm.last_verification_status_obj
    s.locked = true
    s.save!
    create_task annotated: pm, disable_update_status: false
    assert_equal 'undetermined', pm.reload.last_verification_status
  end

  test "should have status permission" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      permissions = JSON.parse(pm.permissions)
      assert permissions.has_key?('update Status')
    end
  end

  test "should not crash if media does not have status" do
    pm = create_project_media
    Annotation.delete_all
    assert_nothing_raised do
      assert_nil pm.last_verification_status_obj
    end
  end

  test "should have relationships and parent and children reports" do
    t = create_team
    s1 = create_project_media team: t
    s2 = create_project_media team: t
    t1 = create_project_media team: t
    t2 = create_project_media team: t
    create_project_media team: t
    create_relationship source_id: s1.id, target_id: t1.id
    create_relationship source_id: s2.id, target_id: t2.id
    assert_equal [t1], s1.targets
    assert_equal [t2], s2.targets
    assert_equal [s1], t1.sources
    assert_equal [s2], t2.sources
  end

  test "should return related" do
    pm = create_project_media
    pm2 = create_project_media
    assert_nil pm.related_to
    pm.related_to_id = pm2.id
    assert_equal pm2, pm.related_to
  end

  test "should include extra attributes in serialized object" do
    pm = create_project_media
    pm.related_to_id = 1
    dump = YAML::dump(pm)
    assert_match /related_to_id/, dump
  end

  test "should skip screenshot archiver" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = false
    tbi.save!
    pm = create_project_media team: t, media: l
    assert pm.should_skip_create_archive_annotation?('pender_archive')
  end

  test "should destroy project media when associated_id on version is not valid" do
    with_versioning do
      m = create_valid_media
      t = create_team
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      pm = nil
      with_current_user_and_team(u, t) do
        pm = create_project_media team: t, media: m, user: u
        pm.source_id = create_source(team_id: t.id).id
        pm.save
        assert_equal 3, pm.versions.count
      end
      version = pm.versions.last
      version.update_attribute('associated_id', 100)

      assert_nothing_raised do
        pm.destroy
      end
    end
  end

  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5ca644ecf023ba001260e71d
  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5ca4faa1f023ba001260dbae
  test "should create claim with Indian characters" do
    str1 = "_Buy Redmi Note 5 Pro Mobile at *2999 Rs* (95�\u0000off) in Flash Sale._\r\n\r\n*Grab this offer now, Deal valid only for First 1,000 Customers. Visit here to Buy-* http://sndeals.win/"
    str2 = "*प्रधानमंत्री छात्रवृति योजना 2019*\n\n*Scholarship Form for 10th or 12th Open Now*\n\n*Scholarship Amount*\n1.50-60�\u0000- Rs. 5000/-\n2.60-80�\u0000- Rs. 10000/-\n3.Above 80�\u0000- Rs. 25000/-\n\n*सभी 10th और 12th के बच्चो व उनके अभिभावकों को ये SMS भेजे ताकि सभी बच्चे इस योजना का लाभ ले सके*\n\n*Click Here for Apply:*\nhttps://bit.ly/2l71tWl"
    [str1, str2].each do |str|
      assert_difference 'ProjectMedia.count' do
        m = create_claim_media quote: str
        create_project_media media: m
      end
    end
  end

  test "should not create project media with unsafe URL" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    url = 'http://unsafe.com/'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"error","data":{"code":12}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    assert_raises RuntimeError do
      pm = create_project_media media: nil, url: url
      assert_equal 12, pm.media.pender_error_code
    end
  end

  test "should get metadata" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'title' => 'Media Title', 'description' => 'Media Description' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal 'Media Title', l.metadata['title']
    assert_equal 'Media Description', l.metadata['description']
    assert_equal 'Media Title', pm.media.metadata['title']
    assert_equal 'Media Description', pm.media.metadata['description']
    pm.analysis = { title: 'Project Media Title', content: 'Project Media Description' }
    pm.save!
    l = Media.find(l.id)
    pm = ProjectMedia.find(pm.id)
    assert_equal 'Media Title', l.metadata['title']
    assert_equal 'Media Description', l.metadata['description']
    assert_equal 'Project Media Title', pm.analysis['title']
    assert_equal 'Project Media Description', pm.analysis['content']
  end

  test "should cache and sort by demand" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    team = create_team
    pm = create_project_media team: team, disable_es_callbacks: false
    ms_pm = get_es_id(pm)
    assert_queries(0, '=') { assert_equal(0, pm.demand) }
    create_tipline_request team: team.id, associated: pm
    assert_queries(0, '=') { assert_equal(1, pm.demand) }
    pm2 = create_project_media team: team, disable_es_callbacks: false
    ms_pm2 = get_es_id(pm2)
    assert_queries(0, '=') { assert_equal(0, pm2.demand) }
    2.times { create_tipline_request(team_id: team.id, associated: pm2) }
    assert_queries(0, '=') { assert_equal(2, pm2.demand) }
    # test sorting
    result = $repository.find(ms_pm)
    assert_equal result['demand'], 1
    result = $repository.find(ms_pm2)
    assert_equal result['demand'], 2
    result = CheckSearch.new({sort: 'demand'}.to_json, nil, team.id)
    assert_equal [pm2.id, pm.id], result.medias.map(&:id)
    result = CheckSearch.new({sort: 'demand', sort_type: 'asc'}.to_json, nil, team.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id)
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    assert_equal 1, pm.reload.requests_count
    assert_equal 2, pm2.reload.requests_count
    assert_queries(0, '=') { assert_equal(3, pm.demand) }
    assert_queries(0, '=') { assert_equal(3, pm2.demand) }
    pm3 = create_project_media team: team
    ms_pm3 = get_es_id(pm3)
    assert_queries(0, '=') { assert_equal(0, pm3.demand) }
    2.times { create_tipline_request(team_id: team.id, associated: pm3) }
    assert_queries(0, '=') { assert_equal(2, pm3.demand) }
    create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    assert_queries(0, '=') { assert_equal(5, pm.demand) }
    assert_queries(0, '=') { assert_equal(5, pm2.demand) }
    assert_queries(0, '=') { assert_equal(5, pm3.demand) }
    create_tipline_request team_id: team.id, associated: pm3
    assert_queries(0, '=') { assert_equal(6, pm.demand) }
    assert_queries(0, '=') { assert_equal(6, pm2.demand) }
    assert_queries(0, '=') { assert_equal(6, pm3.demand) }
    r.destroy!
    assert_queries(0, '=') { assert_equal(4, pm.demand) }
    assert_queries(0, '=') { assert_equal(2, pm2.demand) }
    assert_queries(0, '=') { assert_equal(4, pm3.demand) }
    assert_queries(0, '>') { assert_equal(4, pm.demand(true)) }
    assert_queries(0, '>') { assert_equal(2, pm2.demand(true)) }
    assert_queries(0, '>') { assert_equal(4, pm3.demand(true)) }
  end

  test "should create status and fact-check when creating an item" do
    u = create_user is_admin: true
    t = create_team
    assert_difference 'FactCheck.count' do
      assert_difference "Annotation.where(annotation_type: 'verification_status').count" do
        with_current_user_and_team(u, t) do
          create_project_media set_status: 'false', set_fact_check: { title: 'Foo', summary: 'Bar', url: random_url, language: 'en' }, set_claim_description: 'Test', team: t
        end
      end
    end
  end

  test "should not create duplicated fact-check when creating an item" do
    u = create_user is_admin: true
    t = create_team
    params = { title: 'Foo', summary: 'Bar', url: random_url, language: 'en' }
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        create_project_media set_fact_check: params, set_claim_description: 'Test', team: t
        create_project_media set_fact_check: params, set_claim_description: 'Test'
      end
      assert_raises ActiveRecord::RecordNotUnique do
        create_project_media set_fact_check: params, set_claim_description: 'Test', team: t
      end
    end
  end

  test "should have longer expiration date for tags cached field" do
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media
    Rails.cache.clear
    Sidekiq::Testing.inline! do
      # First call should query the database and cache the field
      assert_queries 0, '>' do
        pm.tags_as_sentence
      end
      # If not expired yet, should not query the database
      travel_to Time.now.since(2.years)
      assert_queries 0, '=' do
        pm.tags_as_sentence
      end
      travel_to Time.now.since(6.years)
      # After expiration date has passed, should query the database again
      assert_queries 0, '>' do
        pm.tags_as_sentence
      end
    end
  end

  test "should get media slug" do
    m = create_uploaded_image file: 'rails.png'
    # Youtube
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "youtube", "title":"youtube"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_youtube = create_link url: url
    u = create_user
    team = create_team slug: 'workspace-slug'
    create_team_user team: team, user: u, role: 'admin'
    # File type
    pm_image = create_project_media team: team, media: m
    assert_equal "image-#{team.slug}-#{pm_image.id}", pm_image.media_slug
    # Link type
    pm_youtube = create_project_media team: team, media: l_youtube
    assert_equal "youtube-#{team.slug}-#{pm_youtube.id}", pm_youtube.media_slug
    # Claim type
    pm = create_project_media team: team, quote: random_string
    assert_equal "text-#{team.slug}-#{pm.id}", pm.media_slug
  end

  test "should validate the title" do
    pm = create_project_media
    pm.title_field = nil
    assert pm.valid?
    pm.title_field = ''
    assert pm.valid?
    ['fact_check_title', 'claim_title', 'pinned_media_id'].each do |value|
      pm.title_field = value
      assert pm.valid?
    end
    pm.title_field = 'foo_bar'
    assert pm.invalid?
    pm.title_field = 'custom_title'
    assert pm.invalid?
    pm.custom_title = 'Foo Bar'
    assert pm.valid?
  end

  test "should return title based on title field" do
    RequestStore.store[:skip_cached_field_update] = false
    User.current = create_user is_admin: true
    pm = create_project_media quote: 'Some text', set_claim_description: 'The Claim', set_fact_check: { 'title' => 'The Fact-Check' }, custom_title: 'Custom Title', title_field: nil
    assert_equal 'The Claim', pm.get_title
    assert_equal 'The Claim', pm.title

    pm.title_field = 'custom_title'
    pm.custom_title = 'Custom Title'
    pm.save!
    assert_equal 'Custom Title', pm.get_title # Uncached
    assert_equal 'Custom Title', pm.title # Cached
    pm.custom_title = 'Custom Title Updated'
    pm.save!
    assert_equal 'Custom Title Updated', pm.get_title # Uncached
    assert_equal 'Custom Title Updated', pm.title # Cached

    pm.title_field = 'claim_title'
    pm.save!
    assert_equal 'The Claim', pm.get_title # Uncached
    assert_equal 'The Claim', pm.title # Cached

    pm.title_field = 'fact_check_title'
    pm.save!
    assert_equal 'The Fact-Check', pm.get_title # Uncached
    assert_equal 'The Fact-Check', pm.title # Cached

    pm.title_field = 'pinned_media_id'
    pm.save!
    assert_match /^text-/, pm.get_title # Uncached
    assert_match /^text-/, pm.title # Cached
    # Verify save the title as a custom title
    ProjectMedia.stubs(:get_title).returns(nil)
    pm = create_project_media custom_title: 'Custom Title'
    assert_equal 'Custom Title', pm.title
    assert_equal 'custom_title', pm.reload.title_field
    ProjectMedia.unstub(:get_title)
  end

  test "should avoid N + 1 queries problem when loading the team avatar of many items at once" do
    t = create_team
    create_project_media team: t
    create_project_media team: t
    pms = ProjectMedia.where(team: t).to_a
    assert_queries(1, '=') { pms.map(&:team_avatar) }
  end

  test "should return fact-check" do
    pm = create_project_media
    assert_nil pm.fact_check
    cd = create_claim_description project_media: pm
    assert_nil pm.fact_check
    fc = create_fact_check claim_description: cd
    assert_equal fc, pm.fact_check
  end
end
