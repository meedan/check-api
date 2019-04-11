require_relative '../test_helper'

class ElasticSearch2Test < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    User.unstub(:current)
    Team.current = nil
    User.current = nil
    MediaSearch.delete_index
    MediaSearch.create_index
    Rails.stubs(:env).returns('development')
    RequestStore.store[:disable_es_callbacks] = false
    create_translation_status_stuff
    create_verification_status_stuff(false)
    sleep 2
  end

  def teardown
    super
    Rails.unstub(:env)
  end

  test "should filter by archived" do
    create_project_media
    pm = create_project_media
    pm.archived = true
    pm.save!
    create_project_media
    result = CheckSearch.new({}.to_json)
    assert_equal 2, result.medias.count
    result = CheckSearch.new({ archived: 1 }.to_json)
    assert_equal 1, result.medias.count
    result = CheckSearch.new({ archived: 0 }.to_json)
    assert_equal 2, result.medias.count
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
      pids = ProjectMedia.where(project_id: p.id).map(&:id)
      pids.concat ProjectSource.where(project_id: p.id).map(&:id)
      sleep 5
      results = MediaSearch.search(query: { match: { team_id: t.id } }).results
      assert_equal pids.sort, results.map(&:annotated_id).sort
      p.team_id = t2.id; p.save!
      sleep 5
      results = MediaSearch.search(query: { match: { team_id: t.id } }).results
      assert_equal [], results.map(&:annotated_id)
      results = MediaSearch.search(query: { match: { team_id: t2.id } }).results
      assert_equal pids.sort, results.map(&:annotated_id).sort
    end
  end

  test "should update elasticsearch after move media to other projects" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    p2 = create_project team: t
    m = create_valid_media
    User.stubs(:current).returns(u)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_comment annotated: pm
    create_tag annotated: pm
    sleep 1
    id = get_es_id(pm)
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p.id
    assert_equal ms.team_id.to_i, t.id
    pm.project = p2; pm.save!
    # confirm annotations log
    sleep 1
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p2.id
    assert_equal ms.team_id.to_i, t.id
  end

  test "should destroy elasticseach project media" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    id = get_es_id(pm)
    assert_not_nil MediaSearch.find(id)
    Sidekiq::Testing.inline! do
      pm.destroy
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        result = MediaSearch.find(id)
      end
    end
  end

  test "should update elasticsearch after refresh pender data" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"org_title"}}')
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"new_title"}}')
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    m = create_media url: url
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm2 = create_project_media project: p2, media: m, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal ms.title, 'org_title'
    ms2 = MediaSearch.find(get_es_id(pm2))
    assert_equal ms2.title, 'org_title'
    Sidekiq::Testing.inline! do
      # Update title
      pm2.reload; pm2.disable_es_callbacks = false
      info = {title: 'override_title'}.to_json
      pm2.embed= info
      pm.reload; pm.disable_es_callbacks = false
      pm.refresh_media = true
      pm.save!
      pm2.reload; pm2.disable_es_callbacks = false
      pm2.refresh_media = true
      pm2.save!
    end
    sleep 1
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal ms.title, 'new_title'
    ms2 = MediaSearch.find(get_es_id(pm2))
    assert_equal ms2.title.sort, ["org_title", "override_title"].sort
  end

  test "should set elasticsearch data for media account" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal ms['accounts'][0].sort, {"id"=> m.account.id, "title"=>"Foo", "description"=>"Bar", "username"=>"username"}.sort
  end

  test "should update or destroy media search in background" do
    Sidekiq::Testing.fake!
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    # update title or description
    ElasticSearchWorker.clear
    pm.embed= {title: 'title', description: 'description'}.to_json
    assert_equal 1, ElasticSearchWorker.jobs.size
    # destroy media
    ElasticSearchWorker.clear
    assert_equal 0, ElasticSearchWorker.jobs.size
    pm.destroy
    assert ElasticSearchWorker.jobs.size > 0
  end

  test "should add or destroy es for annotations in background" do
    Sidekiq::Testing.fake!
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    # add comment
    ElasticSearchWorker.clear
    c = create_comment annotated: pm, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    # add tag
    ElasticSearchWorker.clear
    t = create_tag annotated: pm, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    # destroy comment
    ElasticSearchWorker.clear
    c.destroy
    assert_equal 1, ElasticSearchWorker.jobs.size
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

  test "should index and search by location" do
    att = 'task_response_geolocation'
    at = create_annotation_type annotation_type: att, label: 'Task Response Geolocation'
    geotype = create_field_type field_type: 'geojson', label: 'GeoJSON'
    create_field_instance annotation_type_object: at, name: 'response_geolocation', field_type_object: geotype
    pm = create_project_media disable_es_callbacks: false
    geo = {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [-12.9015866, -38.560239]
      },
      properties: {
        name: 'Salvador, BA, Brazil'
      }
    }.to_json

    fields = { response_geolocation: geo }.to_json
    d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: fields, disable_es_callbacks: false

    search = {
      query: {
        nested: {
          path: 'dynamics',
          query: {
            bool: {
              filter: {
                geo_distance: {
                  distance: '1000mi',
                  "dynamics.location": {
                    lat: -12.900,
                    lon: -38.560
                  }
                }
              }
            }
          }
        }
      }
    }

    sleep 3

    assert_equal 1, MediaSearch.search(search).results.size
  end

  test "should index and search by datetime" do
    att = 'task_response_datetime'
    at = create_annotation_type annotation_type: att, label: 'Task Response Date Time'
    datetime = create_field_type field_type: 'datetime', label: 'Date Time'
    create_field_instance annotation_type_object: at, name: 'response_datetime', field_type_object: datetime
    pm = create_project_media disable_es_callbacks: false
    fields = { response_datetime: '2017-08-21 14:13:42' }.to_json
    d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: fields, disable_es_callbacks: false

    search = {
      query: {
        nested: {
          path: 'dynamics',
          query: {
            bool: {
              filter: {
                range: {
                  "dynamics.datetime": {
                    lte: Time.parse('2017-08-22').to_i,
                    gte: Time.parse('2017-08-20').to_i
                  }
                }
              }
            }
          }
        }
      }
    }

    sleep 5

    assert_equal 1, MediaSearch.search(search).results.size
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
          nested: {
            path: 'dynamics',
            query: {
              term: {
                "dynamics.language": code
              }
            }
          }
        }
      }

      results = MediaSearch.search(search).results
      assert_equal 1, results.size
      assert_equal ids[code], results.first.annotated_id
    end
  end

  test "should create media search" do
    assert_difference 'MediaSearch.length' do
      create_media_search
    end
  end

  test "should set type automatically for media" do
    m = create_media_search
    assert_equal 'mediasearch', m.annotation_type
  end

  test "should reindex data" do
    # Test raising error for re-index
    MediaSearch.stubs(:migrate_es_data).raises(StandardError)
    CheckElasticSearchModel.reindex_es_data
    MediaSearch.unstub(:migrate_es_data)

    source_index = CheckElasticSearchModel.get_index_name
    target_index = "#{source_index}_reindex"
    MediaSearch.delete_index target_index
    MediaSearch.create_index(target_index, false)
    m = create_media_search
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    repository = Elasticsearch::Persistence::Repository.new url: url
    repository.type = 'media_search'
    repository.index = source_index
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 1, results.size
    repository.index = target_index
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 0, results.size
    MediaSearch.migrate_es_data(source_index, target_index)
    sleep 1
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 1, results.size
    # test re-index
    CheckElasticSearchModel.reindex_es_data
    sleep 1
    assert_equal 1, MediaSearch.length
  end

  test "should update elasticsearch after source update" do
    s = create_source name: 'source_a', slogan: 'desc_a'
    ps = create_project_source project: create_project, source: s, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(ps))
    assert_equal ms.title, s.name
    assert_equal ms.description, s.description
    s.name = 'new_source'; s.slogan = 'new_desc'; s.disable_es_callbacks = false; s.save!
    s.reload
    sleep 1
    ms = MediaSearch.find(get_es_id(ps))
    assert_equal ms.title, s.name
    assert_equal ms.description, s.description
    # test multiple project sources
    ps2 = create_project_source project: create_project, source: s, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(ps2))
    assert_equal ms.title, s.name
    assert_equal ms.description, s.description
    # update source should update all related project_sources
    s.name = 'source_b'; s.slogan = 'desc_b'; s.save!
    s.reload
    sleep 1
    ms1 = MediaSearch.find(get_es_id(ps))
    ms2 = MediaSearch.find(get_es_id(ps2))
    assert_equal ms1.title, ms2.title, s.name
    assert_equal ms1.description, ms2.description, s.description
  end

  test "should destroy related items" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      c = create_comment annotated: pm, disable_es_callbacks: false
      sleep 1
      result = MediaSearch.find(get_es_id(pm))
      assert_equal 1, result['comments'].count
      id = pm.id
      m.destroy
      assert_equal 0, ProjectMedia.where(media_id: id).count
      assert_equal 0, Annotation.where(annotated_id: pm.id, annotated_type: 'ProjectMedia').count
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        MediaSearch.find(get_es_id(pm))
      end
    end
  end

  test "should destroy related items 2" do
    t = create_team
    p = create_project team: t
    id = p.id
    p.title = 'Change title'; p.save!
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, disable_es_callbacks: false
      c = create_comment annotated: pm, disable_es_callbacks: false
      sleep 1
      result = MediaSearch.find(get_es_id(pm))
      p.destroy
      assert_equal 0, ProjectMedia.where(project_id: id).count
      assert_equal 0, Annotation.where(annotated_id: pm.id, annotated_type: 'ProjectMedia').count
      assert_equal 0, PaperTrail::Version.where(item_id: id, item_type: 'Project').count
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        MediaSearch.find(get_es_id(pm))
      end
    end
  end

  test "should destroy elasticseach project source" do
    t = create_team
    p = create_project team: t
    s = create_source
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    sleep 1
    assert_not_nil MediaSearch.find(get_es_id(ps))
    ps.destroy
    sleep 1
    assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
      result = MediaSearch.find(get_es_id(ps))
    end
  end

  test "should index project source" do
    ps = create_project_source disable_es_callbacks: false
    sleep 1
    assert_not_nil MediaSearch.find(get_es_id(ps))
  end

  test "should index related accounts" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    ps = create_project_source name: 'New source', url: url, disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(ps))
    assert_equal ps.source.accounts.map(&:id).sort, result['accounts'].collect{|i| i["id"]}.sort
  end

  test "should update elasticsearch after move source to other projects" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    p2 = create_project team: t
    s = create_source
    User.stubs(:current).returns(u)
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    sleep 1
    id = get_es_id(ps)
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p.id
    assert_equal ms.team_id.to_i, t.id
    ps.project = p2; ps.save!
    sleep 1
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p2.id
    assert_equal ms.team_id.to_i, t.id
  end

  test "should create elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    s = create_source
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [c.id], result['comments'].collect{|i| i["id"]}
    c2 = create_comment annotated: ps, text: 'test', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(ps))
    assert_equal [c2.id], result['comments'].collect{|i| i["id"]}
  end

  test "should update elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    c.text = 'test-mod'; c.save!
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal ['test-mod'], result['comments'].collect{|i| i["text"]}
  end

  test "should destroy elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    s = create_source
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    c2 = create_comment annotated: ps, text: 'test', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [c.id], result['comments'].collect{|i| i["id"]}
    c.destroy
    c2.destroy
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_empty result['comments']
    result = MediaSearch.find(get_es_id(ps))
    assert_empty result['comments']
  end

  test "should create elasticsearch tag" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [t.id], result['tags'].collect{|i| i["id"]}
  end

  test "should update elasticsearch tag" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
    t.tag = 'sports-news'; t.save!
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal ['sports-news'], result['tags'].collect{|i| i["tag"]}
  end

  test "should create elasticsearch status" do
    m = create_valid_media
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, disable_es_callbacks: false
      sleep 5
      ms = MediaSearch.find(get_es_id(pm))
      assert_equal 'undetermined', ms.verification_status
      assert_equal 'pending', ms.translation_status
    end
  end

  test "should update elasticsearch status" do
    m = create_valid_media
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, disable_es_callbacks: false
      s = pm.get_annotations('translation_status').last.load
      s.status = 'translated'
      s.save!
      s = pm.get_annotations('verification_status').last.load
      s.status = 'verified'
      s.save!
      sleep 5
      ms = MediaSearch.find(get_es_id(pm))
      assert_equal 'verified', ms.verification_status
      assert_equal 'translated', ms.translation_status
    end
  end

  test "should create parent if not exists" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_not_nil result
  end

  test "should search with reserved characters" do
    # The reserved characters are: + - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /
    t = create_team
    p = create_project team: t
    m = create_claim_media quote: 'search quote'
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: "search / quote"}.to_json)
    # TODO: fix test
    # assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search by custom status with hyphens" do
    stub_config('app_name', 'Check') do
      value = {
        label: 'Status',
        default: 'foo-bar',
        active: 'foo-bar',
        statuses: [
          { id: 'foo-bar', label: 'Foo Bar', completed: '', description: '', style: 'blue' }
        ]
      }
      t = create_team
      t.set_media_verification_statuses(value)
      t.save!
      p = create_project team: t
      m = create_valid_media
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      assert_equal 'foo-bar', pm.last_verification_status
      sleep 5
      result = CheckSearch.new({verification_status: ['foo']}.to_json)
      assert_empty result.medias
      result = CheckSearch.new({verification_status: ['bar']}.to_json)
      assert_empty result.medias
      result = CheckSearch.new({verification_status: ['foo-bar']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
    end
  end

  test "should search in target reports and return parent instead" do
    t = create_team
    p = create_project team: t
    sm = create_claim_media quote: 'source'
    tm1 = create_claim_media quote: 'target 1'
    tm2 = create_claim_media quote: 'target 2'
    om = create_claim_media quote: 'unrelated target'
    s = create_project_media project: p, media: sm, disable_es_callbacks: false
    t1 = create_project_media project: p, media: tm1, disable_es_callbacks: false
    t2 = create_project_media project: p, media: tm2, disable_es_callbacks: false
    o = create_project_media project: p, media: om, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({ keyword: 'target' }.to_json)
    assert_equal [t1.id, t2.id, o.id].sort, result.medias.map(&:id).sort
    r1 = create_relationship source_id: s.id, target_id: t1.id
    r2 = create_relationship source_id: s.id, target_id: t2.id
    sleep 1
    result = CheckSearch.new({ keyword: 'target' }.to_json)
    assert_equal [s.id, o.id].sort, result.medias.map(&:id).sort
    r1.destroy
    r2.destroy
    sleep 1
    result = CheckSearch.new({ keyword: 'target' }.to_json)
    assert_equal [t1.id, t2.id, o.id].sort, result.medias.map(&:id).sort
  end

  test "should filter target reports" do
    t = create_team
    p = create_project team: t
    m = create_claim_media quote: 'test'
    s = create_project_media project: p, disable_es_callbacks: false

    t1 = create_project_media project: p, media: m, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t1.id

    t2 = create_project_media project: p, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t2.id

    t3 = create_project_media project: p, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t3.id
    vs = t3.last_verification_status_obj
    vs.status = 'verified'
    vs.save!

    t4 = create_project_media project: p, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t4.id
    ts = t4.last_translation_status_obj
    ts.status = 'ready'
    ts.save!

    sleep 2

    assert_equal [t1, t2, t3, t4].sort, Relationship.targets_grouped_by_type(s).first['targets'].sort
    assert_equal [t1].sort, Relationship.targets_grouped_by_type(s, { keyword: 'test' }).first['targets'].sort
    assert_equal [t3].sort, Relationship.targets_grouped_by_type(s, { verification_status: ['verified'] }).first['targets'].sort
    assert_equal [t4].sort, Relationship.targets_grouped_by_type(s, { translation_status: ['ready'] }).first['targets'].sort
  end

  test "should search case-insensitive tags" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_tag tag: 'test', annotated: pm, disable_es_callbacks: false
    create_tag tag: 'Test', annotated: pm2, disable_es_callbacks: false
    sleep 5
    # search by tags
    result = CheckSearch.new({tags: ['test']}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({tags: ['Test']}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    # search by tags as keyword
    result = CheckSearch.new({keyword: 'test'}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'Test'}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
  end

  test "should index and sort by deadline" do
    create_verification_status_stuff
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    create_field_instance annotation_type_object: at, name: 'deadline', label: 'Deadline', field_type_object: ft, optional: true
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    t.set_status_target_turnaround = 10.hours ; t.save!
    pm1 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 5.hours ; t.save!
    pm2 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 15.hours ; t.save!
    pm3 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    search = {
      sort: [
        {
          'dynamics.deadline': {
            order: 'asc',
            nested: {
              path: 'dynamics',
            }
          }
        }
      ],
      query: {
        match_all: {}
      }
    }

    pms = []
    MediaSearch.search(search).results.each do |r|
      pms << r.annotated_id if r.annotated_type == 'ProjectMedia'
    end
    assert_equal [pm2.id, pm1.id, pm3.id], pms
  end

  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5c920b8bf023ba001b5fffbb
  test "should filter by custom sort and other parameters" do
    create_verification_status_stuff
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    create_field_instance annotation_type_object: at, name: 'deadline', label: 'Deadline', field_type_object: ft, optional: true
    query = { sort: 'deadline', sort_type: 'asc' }

    result = CheckSearch.new(query.to_json)
    assert_equal 0, result.medias.count

    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    t.set_status_target_turnaround = 10.hours ; t.save!
    pm1 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 5.hours ; t.save!
    pm2 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 15.hours ; t.save!
    pm3 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    result = CheckSearch.new(query.to_json)
    assert_equal 3, result.medias.count
    assert_equal [pm2.id, pm1.id, pm3.id], result.medias.map(&:id)
  end

  test "should index and sort by most requested" do
#    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false]})

    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    pm1 = create_project_media project: p, disable_es_callbacks: false
    3.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm1, disable_es_callbacks: false }
    sleep 5

    pm2 = create_project_media project: p, disable_es_callbacks: false
    5.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, disable_es_callbacks: false }
    sleep 5

    pm3 = create_project_media project: p, disable_es_callbacks: false
    2.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm3, disable_es_callbacks: false }
    sleep 5

    pm4 = create_project_media project: p, disable_es_callbacks: false
    4.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm4, disable_es_callbacks: false }
    sleep 5

    orders = {asc: [pm3, pm1, pm4, pm2], desc: [pm2, pm4, pm1, pm3]}
    orders.keys.each do |order|
      search = {
        from: 0,
        query: {
          match_all: {}
        },
        aggregations: {
          annotated: {
            terms: {
              field: 'dynamics.smooch.annotated_id',
              order: { "_count": "asc" }
            },
          }
        }
      }

      pms = []
      MediaSearch.search(search).results.each do |r|
        pms << r.annotated_id if r.annotated_type == 'ProjectMedia'
      end
      assert_equal orders[order.to_sym].map(&:id), pms
    end
  end

end
