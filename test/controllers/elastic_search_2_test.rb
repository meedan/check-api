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
    assert_equal 1, ms.project_id.size
    assert_equal ms.project_id.last.to_i, p.id
    assert_equal ms.team_id.to_i, t.id
    pm.project = p2; pm.save!
    # confirm annotations log
    sleep 1
    ms = MediaSearch.find(id)
    assert_equal 1, ms.project_id.size
    assert_equal ms.project_id.last.to_i, p2.id
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
    RequestStore.store[:skip_cached_field_update] = false
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal 'org_title', pm.title
    assert_equal ms.title, 'org_title'
    ms2 = MediaSearch.find(get_es_id(pm2))
    assert_equal 'org_title', pm2.title
    assert_equal ms2.title, 'org_title'
    Sidekiq::Testing.inline! do
      # Update title
      pm2.reload; pm2.disable_es_callbacks = false
      info = {title: 'override_title'}.to_json
      pm2.metadata = info
      pm.reload; pm.disable_es_callbacks = false
      pm.refresh_media = true
      pm.save!
      pm2.reload; pm2.disable_es_callbacks = false
      pm2.refresh_media = true
      pm2.save!
    end
    sleep 10
    ms2 = MediaSearch.find(get_es_id(pm2))
    assert_equal ms2.title.sort, ["org_title", "override_title"].sort
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal 'new_title', pm.title
    assert_equal 'new_title', ms.title
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
    pm.metadata = { title: 'title', description: 'description' }.to_json
    assert_equal 2, ElasticSearchWorker.jobs.size
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
    assert_equal 2, ElasticSearchWorker.jobs.size
    # add tag
    ElasticSearchWorker.clear
    t = create_tag annotated: pm, disable_es_callbacks: false
    assert_equal 3, ElasticSearchWorker.jobs.size
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

  test "should filter by others and unidentified language" do
    p = create_project
    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language

    languages = ['pt', 'en', 'es']
    ids = {}
    languages.each do |code|
      pm = create_project_media project: p, disable_es_callbacks: false
      create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: { language: code }.to_json, disable_es_callbacks: false
      ids[code] = pm.id
    end

    ids['unidentified'] = []
    n = 3
    n.times do
      pm = create_project_media project: p, disable_es_callbacks: false
      ids['unidentified'] << pm.id
    end
    pm = create_project_media project: p, disable_es_callbacks: false
    create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: { language: 'und' }.to_json, disable_es_callbacks: false
    ids['unidentified'] << pm.id

    sleep languages.size * 2

    unidentified_query = {
      dynamic: {
        language: ["und"]
      },
      projects: [p.id]
    }
    result = CheckSearch.new(unidentified_query.to_json)
    assert_equal 4, result.medias.size
    assert_equal ids['unidentified'].sort, result.medias.map(&:id).sort

    other_query = {
      dynamic: {
        language: ["not:en,pt"]
      },
      projects: [p.id]
    }
    result = CheckSearch.new(other_query.to_json)
    assert_equal 1, result.medias.size
    assert_equal ids['es'], result.medias.first.id
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
