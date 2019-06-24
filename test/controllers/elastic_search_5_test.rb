require_relative '../test_helper'

class ElasticSearch5Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
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

  test "should search in target reports and return parents and children" do
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
    assert_equal [t1.id, t2.id, o.id].sort, result.medias.map(&:id).sort
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

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
