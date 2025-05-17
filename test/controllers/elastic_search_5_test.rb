require_relative '../test_helper'

class ElasticSearch5Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should create media search" do
    m = nil
    assert_difference 'MediaSearch.length' do
      m = create_media_search
    end
  end

  test "should match secondary items and show items based on show_similar option" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    parent = create_project_media team: t, disable_es_callbacks: false
    child_1 = create_project_media team: t, quote: 'child_media a', disable_es_callbacks: false
    child_2 = create_project_media team: t, quote: 'child_media b', disable_es_callbacks: false
    create_relationship source_id: parent.id, target_id: child_1.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: parent.id, target_id: child_2.id, relationship_type: Relationship.confirmed_type
    sleep 2
    result = CheckSearch.new({}.to_json, nil, t.id)
    assert_equal [parent.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ show_similar: true }.to_json, nil, t.id)
    assert_equal [parent.id, child_1.id, child_2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ keyword: 'child_media' }.to_json, nil, t.id)
    assert_equal [], result.medias.map(&:id)
    result = CheckSearch.new({ keyword: 'child_media', show_similar: true }.to_json, nil, t.id)
    assert_equal [child_1.id, child_2.id], result.medias.map(&:id).sort
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
    t = create_team
    t2 = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t2, disable_es_callbacks: false
    url = "http://#{CheckConfig.get('elasticsearch_host')}:#{CheckConfig.get('elasticsearch_port')}"
    client = Elasticsearch::Client.new(url: url)
    repository = MediaSearch.new(client: client, index_name: source_index)
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 2, results.size
    repository2 = MediaSearch.new(client: client, index_name: target_index)
    results = repository2.search(query: { match_all: { } }, size: 10000)
    assert_equal 0, results.size
    MediaSearch.migrate_es_data(source_index, target_index)
    sleep 1
    results = repository2.search(query: { match_all: { } }, size: 10000)
    assert_equal 2, results.size
    # test re-index
    CheckElasticSearchModel.reindex_es_data
    sleep 1
    assert_equal 2, MediaSearch.length
    results = repository2.search(query: { term: { team_id: { value: t.id } } }, size: 10000)
    assert_equal 1, results.size
    results = repository2.search(query: { term: { team_id: { value: t2.id } } }, size: 10000)
    assert_equal 1, results.size
  end

  test "should destroy related items" do
    t = create_team
    m = create_claim_media
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t, media: m, disable_es_callbacks: false
      t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
      id = pm.id
      m.destroy
      assert_equal 0, ProjectMedia.where(media_id: id).count
      assert_equal 0, Annotation.where(annotated_id: pm.id, annotated_type: 'ProjectMedia').count
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        $repository.find(get_es_id(pm))
      end
    end
  end

  test "should create update destroy elasticsearch tag" do
    team = create_team
    pm = create_project_media team: team, disable_es_callbacks: false
    t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_equal [t.id], result['tags'].collect{|i| i["id"]}
    # update tag
    t.tag = 'sports-news'; t.save!
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_equal ['sports-news'], result['tags'].collect{|i| i["tag"]}
    # destroy tag
    t.destroy
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_empty result['tags']
  end

  test "should create update elasticsearch status" do
    m = create_valid_media
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, disable_es_callbacks: false
      sleep 2
      ms = $repository.find(get_es_id(pm))
      assert_equal 'undetermined', ms['verification_status']
      # update status
      s = pm.get_annotations('verification_status').last.load
      s.status = 'verified'
      s.save!
      sleep 2
      ms = $repository.find(get_es_id(pm))
      assert_equal 'verified', ms['verification_status']
    end
  end

  test "should create parent if not exists" do
    t = create_team
    pm = create_project_media team: t
    t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_not_nil result
  end

  test "should search with reserved characters" do
    # The reserved characters are: + - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /
    t = create_team
    m = create_claim_media quote: 'search quote'
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: "search / quote"}.to_json, nil, t.id)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search by custom status with hyphens" do
    value = {
      label: 'Status',
      default: 'foo-bar',
      active: 'foo-bar',
      statuses: [
        { id: 'foo-bar', style: { color: 'blue' }, locales: { en: { label: 'Foo Bar', description: '' } } }
      ]
    }
    t = create_team
    t.set_media_verification_statuses(value)
    t.save!
    m = create_valid_media
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    assert_equal 'foo-bar', pm.last_verification_status
    sleep 2
    result = CheckSearch.new({verification_status: ['foo']}.to_json, nil, t.id)
    assert_empty result.medias
    result = CheckSearch.new({verification_status: ['bar']}.to_json, nil, t.id)
    assert_empty result.medias
    result = CheckSearch.new({verification_status: ['foo-bar']}.to_json, nil, t.id)
    assert_equal [pm.id], result.medias.map(&:id)
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

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
