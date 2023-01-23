require_relative '../test_helper'

class ElasticSearch2Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end
  
  test "should get teams" do
    u = create_user
    t = create_team
    with_current_user_and_team(u, t) do
      s = CheckSearch.new({}.to_json)
      assert_equal [], s.teams
      assert_equal t.id, s.team.id
    end
  end

  test "should update elasticsearch after move project to other team" do
    u = create_user
    t = create_team
    t2 = create_team
    u.is_admin = true; u.save!
    p = create_project team: t
    m = create_valid_media
    User.stubs(:current).returns(u)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      pm2 = create_project_media project: p, quote: 'Claim', disable_es_callbacks: false
      sleep 2
      results = $repository.search(query: { match: { team_id: t.id } }).results
      assert_equal [pm.id, pm2.id], results.collect{|i| i['annotated_id']}.sort
      p.team_id = t2.id; p.save!
      sleep 2
      results = $repository.search(query: { match: { team_id: t.id } }).results
      assert_equal [], results.collect{|i| i['annotated_id']}
      results = $repository.search(query: { match: { team_id: t2.id } }).results
      assert_equal [pm.id, pm2.id], results.collect{|i| i['annotated_id']}.sort
    end
  end

  test "should update elasticsearch after move media to other projects" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    p2 = create_project team: t
    m = create_valid_media
    User.stubs(:current).returns(u)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_comment annotated: pm
    create_tag annotated: pm
    sleep 1
    id = get_es_id(pm)
    ms = $repository.find(id)
    assert_equal ms['project_id'].to_i, p.id
    assert_equal ms['team_id'].to_i, t.id
    pm = ProjectMedia.find pm.id
    pm.project_id = p2.id
    pm.save!
    # confirm annotations log
    sleep 1
    ms = $repository.find(id)
    assert_equal ms['project_id'].to_i, p2.id
    assert_equal ms['team_id'].to_i, t.id
  end

  test "should destroy elasticseach project media" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    id = get_es_id(pm)
    assert_not_nil $repository.find(id)
    Sidekiq::Testing.inline! do
      pm.destroy
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        result = $repository.find(id)
      end
    end
  end

  test "should update elasticsearch after refresh pender data" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"org_title"}}')
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"new_title"}}')
    t = create_team
    t2 = create_team
    p = create_project team: t
    p2 = create_project team: t2
    m = create_media url: url
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm2 = create_project_media project: p2, media: m, disable_es_callbacks: false
    sleep 1
    ms = $repository.find(get_es_id(pm))
    assert_equal 'org_title', pm.title
    assert_equal 'org_title', ms['title']
    ms2 = $repository.find(get_es_id(pm2))
    assert_equal pm2.title, 'org_title'
    assert_equal ms2['title'], 'org_title'
    Sidekiq::Testing.inline! do
      # Update title
      pm2.reload; pm2.disable_es_callbacks = false
      create_claim_description project_media: pm2, description: 'overridden_title'
      pm.reload; pm.disable_es_callbacks = false
      pm.refresh_media = true
      pm.save!
      pm2.reload; pm2.disable_es_callbacks = false
      pm2.refresh_media = true
      pm2.save!
    end
    sleep 3
    ms2 = $repository.find(get_es_id(pm2))
    assert_equal 'overridden_title', ms2['title']
    ms = $repository.find(get_es_id(pm))
    assert_equal 'new_title', ms['title']
    assert_equal 'new_title', pm.reload.title
  end

  test "should set elasticsearch data for media account" do
    t = create_team
    p = create_project team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    media_url = 'http://www.facebook.com/meedan/posts/123456'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'

    data = { url: media_url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', username: 'username', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    m = create_media url: media_url, account_id: nil, user_id: nil, account: nil, user: nil
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    ms = $repository.find(get_es_id(pm))
    assert_equal ms['accounts'][0].sort, {"id"=> m.account.id, "title"=>"Foo", "description"=>"Bar"}.sort
  end

  test "should update or destroy media search in background" do
    Sidekiq::Testing.fake!
    t = create_team
    p = create_project team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    # update title or description
    ElasticSearchWorker.clear
    pm.analysis = { title: 'title', content: 'description' }
    assert_equal 3, ElasticSearchWorker.jobs.size
    # destroy media
    ElasticSearchWorker.clear
    assert_equal 0, ElasticSearchWorker.jobs.size
    pm.destroy
    assert ElasticSearchWorker.jobs.size > 0
  end

  test "should update analysis data in foreground" do
    pm = create_project_media disable_es_callbacks: false
    sleep 1
    pm.analysis = { title: 'analysis_title', content: 'analysis_description' }
    ms = $repository.find(get_es_id(pm))
    assert_equal 'analysis_title', ms['analysis_title']
    assert_equal 'analysis_description', ms['analysis_description']
  end

  test "should add or destroy es for annotations in background" do
    Sidekiq::Testing.fake!
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    # add tag
    ElasticSearchWorker.clear
    t = create_tag annotated: pm, disable_es_callbacks: false
    assert_equal 2, ElasticSearchWorker.jobs.size
    # destroy tag
    ElasticSearchWorker.clear
    t.destroy
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should update status in background" do
    m = create_valid_media
    Sidekiq::Testing.fake! do
      Sidekiq::Worker.clear_all
      ElasticSearchWorker.clear
      assert_equal 0, ElasticSearchWorker.jobs.size
      pm = create_project_media media: m, disable_es_callbacks: false
      assert ElasticSearchWorker.jobs.size > 0
    end
  end

  test "should index and search by language" do
    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language

    languages = ['pt', 'en', 'ar', 'es', 'pt-BR', 'pt-PT']
    ids = {}

    languages.each do |code|
      pm = create_project_media disable_es_callbacks: false
      d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: { language: code }.to_json, disable_es_callbacks: false
      ids[code] = pm.id
    end

    sleep languages.size * 2

    languages.each do |code|
      search = {
        query: {
          terms: {
            language: [code]
          }
        }
      }

      results = $repository.search(search).results
      assert_equal 1, results.size
      assert_equal ids[code], results.first['annotated_id']
    end
  end

  [:asc, :desc].each do |order|
    test "should sort by item title #{order}" do
      RequestStore.store[:skip_cached_field_update] = false
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      url = 'http://test.com'
      response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "b-item"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      l = create_media(account: create_valid_account, url: url)
      i = create_uploaded_image file: 'c-item.png'
      v = create_uploaded_video file: 'd-item.mp4'
      a = create_uploaded_audio file: 'e-item.mp3'
      t = create_team
      p = create_project team: t
      pm1 = create_project_media project: p, quote: 'a-item', disable_es_callbacks: false
      pm2 = create_project_media project: p, media: l, disable_es_callbacks: false
      pm3 = create_project_media project: p, media: i, disable_es_callbacks: false
      pm3.analysis = { file_title: 'c-item' }; pm3.save
      pm4 = create_project_media project: p, media: v, disable_es_callbacks: false
      pm4.analysis = { file_title: 'd-item' }; pm4.save
      pm5 = create_project_media project: p, media: a, disable_es_callbacks: false
      pm5.analysis = { file_title: 'e-item' }; pm5.save
      sleep 2
      orders = {asc: [pm1, pm2, pm3, pm4, pm5], desc: [pm5, pm4, pm3, pm2, pm1]}
      query = { projects: [p.id], keyword: 'item', sort: 'title', sort_type: order.to_s }
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 5, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
      query = { projects: [p.id], sort: 'title', sort_type: order.to_s }
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 5, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
      # update analysis
      pm3.analysis = { file_title: 'f-item' }
      pm6 = create_project_media project: p, quote: 'DUPPER-item', disable_es_callbacks: false
      sleep 2
      orders = {asc: [pm1, pm2, pm4, pm6, pm5, pm3], desc: [pm3, pm5, pm6, pm4, pm2, pm1]}
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 6, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
    end
  end

  test "should search by source" do
    t = create_team
    s = create_source team: t
    s2 = create_source team: t
    s3 = create_source team: t
    pm = create_project_media team: t, source: s, disable_es_callbacks: false, skip_autocreate_source: false
    pm2 = create_project_media team: t, source: s, disable_es_callbacks: false, skip_autocreate_source: false
    pm3 = create_project_media team: t, source: s2, disable_es_callbacks: false, skip_autocreate_source: false
    sleep 2
    result = CheckSearch.new({ sources: [s.id] }.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s2.id] }.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({ sources: [s.id, s2.id] }.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s3.id] }.to_json, nil, t.id)
    assert_empty result.medias
    result = CheckSearch.new({ sources: [s2.id], show: ['links'] }.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
  end

  test "should search trash and unconfirmed items" do
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm3 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm4 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED, disable_es_callbacks: false
    sleep 2
    assert_equal [pm2, pm3], pm.check_search_trash.medias.sort
    assert_equal [pm, pm4], t.check_search_team.medias.sort
  end

  test "should adjust ES window size" do
    t = create_team
    u = create_user
    pm = create_project_media quote: 'claim a', disable_es_callbacks: false
    sleep 2
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      assert_nothing_raised do
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":20000,\"esoffset\":0}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, params: { query: query }
        assert_response :success
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":10000,\"esoffset\":20}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, params: { query: query }
        assert_response :success
      end
    end
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
