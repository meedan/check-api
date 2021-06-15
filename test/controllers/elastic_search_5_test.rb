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

  test "should search for parent items only" do
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media disable_es_callbacks: false, project: p
    pm2 = create_project_media disable_es_callbacks: false, project: p
    sleep 2
    result = CheckSearch.new({}.to_json)
    assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    sleep 2
    result = CheckSearch.new({ projects: [p.id] }.to_json)
    assert_equal [pm1.id], result.medias.map(&:id)
    result = CheckSearch.new({}.to_json)
    assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
    # detach and assign to specific list
    r.add_to_project_id = p2.id
    r.destroy
    sleep 2
    result = $repository.find(get_es_id(pm2))
    assert_equal p2.id, result['project_id']
  end

  test "should match secondary items but surface the main ones" do
    # This case only happen when browsing a list and seach by keyword
    t = create_team
    p = create_project team: t
    pm = create_project_media disable_es_callbacks: false, project: p
    pm1 = create_project_media disable_es_callbacks: false, project: p
    pm2 = create_project_media quote: 'target_media', disable_es_callbacks: false, project: p
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    sleep 2
    result = CheckSearch.new({ projects: [p.id] }.to_json)
    assert_equal [pm.id, pm1.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ projects: [p.id], keyword: 'target_media' }.to_json)
    assert_equal [pm1.id], result.medias.map(&:id)
    result = CheckSearch.new({ projects: [p.id], keyword: 'target_media', tags: ['test'] }.to_json)
    assert_empty result.medias.map(&:id)
    # detach and assign to specific list
    r.add_to_project_id = p.id
    r.destroy
    sleep 2
    result = CheckSearch.new({ projects: [p.id] }.to_json)
    assert_equal [pm.id, pm1.id, pm2.id], result.medias.map(&:id).sort
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
    p = create_project team: t
    m = create_claim_media
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      c = create_comment annotated: pm, disable_es_callbacks: false
      sleep 1
      result = $repository.find(get_es_id(pm))
      assert_equal 1, result['comments'].count
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

  test "should destroy related items 2" do
    t = create_team
    p = create_project team: t
    id = p.id
    p.title = 'Change title'; p.save!
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, disable_es_callbacks: false
      c = create_comment annotated: pm, disable_es_callbacks: false
      sleep 1
      result = $repository.find(get_es_id(pm))
      p.destroy
      assert_equal 0, ProjectMedia.where(project_id: id).count
      assert_equal 1, ProjectMedia.where(id: pm.id).count
      assert_equal 2, Annotation.where(annotated_id: pm.id, annotated_type: 'ProjectMedia').count
      assert_equal 0, PaperTrail::Version.where(item_id: id, item_type: 'Project').count
    end
  end

  test "should create update destroy elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    s = create_source
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_equal [c.id], result['comments'].collect{|i| i["id"]}
    # update es comment
    c.text = 'test-mod'; c.save!
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_equal ['test-mod'], result['comments'].collect{|i| i["text"]}
    # destroy es comment
    c.destroy
    sleep 1
    result = $repository.find(get_es_id(pm))
    assert_empty result['comments']
  end

  test "should create update destroy elasticsearch tag" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
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
      sleep 5
      ms = $repository.find(get_es_id(pm))
      assert_equal 'undetermined', ms['verification_status']
      # update status
      s = pm.get_annotations('verification_status').last.load
      s.status = 'verified'
      s.save!
      sleep 5
      ms = $repository.find(get_es_id(pm))
      assert_equal 'verified', ms['verification_status']
    end
  end

  test "should create parent if not exists" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, disable_es_callbacks: false
    sleep 1
    result = $repository.find(get_es_id(pm))
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

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
