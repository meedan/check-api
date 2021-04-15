require_relative '../test_helper'

class GraphqlController4Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    @controller = Api::V1::GraphqlController.new
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    create_verification_status_stuff
    @t = create_team
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    @p1 = create_project team: @t
    @p2 = create_project team: @t
    @p3 = create_project team: @t
    @ps = [@p1, @p2, @p3]
    @pm1 = create_project_media team: @t, disable_es_callbacks: false, project: @p1
    @pm2 = create_project_media team: @t, disable_es_callbacks: false, project: @p2
    @pm3 = create_project_media team: @t, disable_es_callbacks: false, project: @p3
    Sidekiq::Worker.drain_all
    sleep 1
    @pms = [@pm1, @pm2, @pm3]
    @ids = @pms.map(&:graphql_id).to_json
    authenticate_with_user(@u)
  end

  def teardown
    super
    Sidekiq::Worker.drain_all
  end

  test "should not bulk-send project medias to trash if not allowed" do
    u = create_user
    authenticate_with_user(u)
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 1 }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_error_message 'allowed'
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
  end

  test "should not bulk-send project medias to trash if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', archived: 1 }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-send project medias to trash" do
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived }
    @ps.each { |p| assert_equal 1, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_equal 0, CheckPusher::Worker.jobs.size
    
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 1 }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_equal 1, CheckPusher::Worker.jobs.size
  end

  test "should not bulk-restore project medias from trash if not allowed" do
    u = create_user
    authenticate_with_user(u)
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 0 }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_error_message 'allowed'
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
  end

  test "should not bulk-restore project medias from trash if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', archived: 0 }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-restore project medias from trash" do
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    Sidekiq::Worker.drain_all
    sleep 1
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_equal 0, CheckPusher::Worker.jobs.size
    
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 0 }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
    @ps.each { |p| assert_equal 1, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_equal 1, CheckPusher::Worker.jobs.size
  end

  test "should bulk-restore project medias from trash and assign to list" do
    add_to = create_project team: @t
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    Sidekiq::Worker.drain_all
    sleep 1
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_equal 0, CheckPusher::Worker.jobs.size

    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 0, project_id: ' + add_to.id.to_s + ' }) { ids, team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response :success

    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_equal @pms.length, add_to.reload.medias_count
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_equal 2, CheckPusher::Worker.jobs.size
  end

  test "should not bulk-create tags if not allowed" do
    @tu.update_column(:role, 'collaborator')
    inputs = '{ tag: "test", annotated_type: "ProjectMedia", annotated_id: "0" }'
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [' + inputs + '] }) { team { dbid } } }'
    assert_no_difference 'TagText.count' do
      assert_no_difference 'Tag.length' do
        post :create, query: query, team: @t.slug
        assert_response :success
        assert_error_message 'allowed'
      end
    end
  end

  test "should not bulk-create tags if there are more than 10.000 inputs" do
    inputs = '{ tag: "test", annotated_type: "ProjectMedia", annotated_id: "0" }, ' * 10001
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [' + inputs.gsub(/, $/, '') + '] }) { team { dbid } } }'
    assert_no_difference 'TagText.count' do
      assert_no_difference 'Tag.length' do
        post :create, query: query, team: @t.slug
        assert_response 400
        assert_error_message 'maximum'
      end
    end
  end

  test "should bulk-create tags" do
    TagText.create! text: 'foo', team_id: @t.id
    c = create_comment annotated: @pm1
    pm4 = create_project_media
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [{ tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm1.id.to_s + '" }, { tag: "bar", annotated_type: "ProjectMedia", annotated_id: "' + @pm2.id.to_s + '" }, { tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm3.id.to_s + '" }, { tag: "test", annotated_type: "ProjectMedia", annotated_id: "' + pm4.id.to_s + '" }, { tag: "bar", annotated_type: "Comment", annotated_id: "' + c.id.to_s + '" }]}) { team { dbid } } }'
    assert_difference 'TagText.count', 1 do
      assert_difference 'Tag.length', 3 do
        post :create, query: query, team: @t.slug
        assert_response :success
      end
    end
    assert_equal @t.id, JSON.parse(@response.body)['data']['createTags']['team']['dbid']
    assert_equal ['foo'], @pm1.reload.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['bar'], @pm2.reload.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_nothing_raised do
      Sidekiq::Worker.drain_all
    end
  end

  test "should not bulk-move project medias from a list to another if not allowed" do
    u = create_user
    authenticate_with_user(u)
    p4 = create_project team: @t
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', move_to: ' + p4.id.to_s + ' }) { team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_error_message 'allowed'
  end

  test "should not bulk-move project medias from a list to another if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    p4 = create_project team: @t
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', move_to: ' + p4.id.to_s + ' }) { team { dbid } } }'
    post :create, query: query, team: @t.slug
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-move project medias from a list to another" do
    inputs = []
    p4 = create_project team: @t
    pm1 = create_project_media project: create_project
    pm2 = create_project_media project: @p1
    invalid_id_1 = Base64.encode64("ProjectMediaProject/0")
    invalid_id_2 = Base64.encode64("Project/#{pm1.id}")
    invalid_id_3 = random_string
    assert_equal 2, @p1.reload.medias_count
    assert_equal 1, @p2.reload.medias_count
    assert_equal 0, p4.reload.medias_count
    ids = []
    [@pm1.graphql_id, @pm2.graphql_id, pm1.graphql_id, pm2.graphql_id, invalid_id_1, invalid_id_2, invalid_id_3].each { |id| ids << id }
    query = "mutation { updateProjectMedias(input: { clientMutationId: \"1\", ids: #{ids.to_json}, move_to: #{p4.id} }) { team { dbid } } }"
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 0, @p1.reload.medias_count
    assert_equal 0, @p2.reload.medias_count
    assert_equal 3, p4.reload.medias_count
  end

  test "should update archived media by owner" do
    pm = create_project_media team: @t, archived: CheckArchivedFlags::FlagCodes::TRASHED
    query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm.graphql_id}\"}) { project_media { permissions } } }"
    post :create, query: query, team: @t.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']
    permissions = JSON.parse(data['permissions'])
    assert_equal true, permissions['update ProjectMedia']
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end

  def search_results(filters)
    sleep 1
    $repository.search(query: { bool: { must: [{ term: filters }, { term: { team_id: @t.id } }] } }).results.collect{|i| i['annotated_id']}.sort
  end

  def assert_search_finds_all(filters)
    assert_equal @pms.map(&:id).sort, search_results(filters)
  end

  def assert_search_finds_none(filters)
    assert_equal [], search_results(filters)
  end
end
