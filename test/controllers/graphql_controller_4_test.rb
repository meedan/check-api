require_relative '../test_helper'

class GraphqlController4Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    TestDynamicAnnotationTables.load!
    @controller = Api::V1::GraphqlController.new
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    @t = create_team
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    @pm1 = create_project_media team: @t, disable_es_callbacks: false
    @pm2 = create_project_media team: @t, disable_es_callbacks: false
    @pm3 = create_project_media team: @t, disable_es_callbacks: false
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
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "archived", params: "{\"archived:\": 1}" }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_error_message 'allowed'
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
  end

  test "should bulk-send project medias to trash" do
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::NONE ; pm.save! }
    Sidekiq::Worker.drain_all
    sleep 1
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "archived", params: "{\"archived\": 1}" }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
  end

  test "should not bulk-restore project medias from trash if not allowed" do
    u = create_user
    authenticate_with_user(u)
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "archived", params: "{\"archived:\": 0}" }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_error_message 'allowed'
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
  end

  test "should not bulk-restore project medias from trash if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', action: "archived", params: "{\"archived:\": 0}" }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-restore project medias from trash" do
    RequestStore.store[:skip_delete_for_ever] = true
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    Sidekiq::Worker.drain_all
    sleep 1
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "archived", params: "{\"archived\": 0}" }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
  end

  test "should not bulk-create tags if not allowed" do
    @tu.update_column(:role, 'collaborator')
    inputs = '{ tag: "test", annotated_type: "ProjectMedia", annotated_id: "0" }'
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [' + inputs + '] }) { team { dbid } } }'
    assert_no_difference 'TagText.count' do
      assert_no_difference 'Tag.length' do
        post :create, params: { query: query, team: @t.slug }
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
        post :create, params: { query: query, team: @t.slug }
        assert_response 400
        assert_error_message 'maximum'
      end
    end
  end

  test "should bulk-create tags" do
    TagText.create! text: 'foo', team_id: @t.id
    d = create_dynamic_annotation annotated: @pm1
    pm4 = create_project_media
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [{ tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm1.id.to_s + '" }, { tag: "bar", annotated_type: "ProjectMedia", annotated_id: "' + @pm2.id.to_s + '" }, { tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm3.id.to_s + '" }, { tag: "test", annotated_type: "ProjectMedia", annotated_id: "' + pm4.id.to_s + '" }, { tag: "bar", annotated_type: "Dynamic", annotated_id: "' + d.id.to_s + '" }]}) { team { dbid } } }'
    assert_difference 'TagText.count', 1 do
      assert_difference 'Tag.length', 3 do
        post :create, params: { query: query, team: @t.slug }
        assert_response :success
      end
    end
    assert_equal @t.id, JSON.parse(@response.body)['data']['createTags']['team']['dbid']
    assert_equal ['foo'], @pm1.reload.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['bar'], @pm2.reload.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_nothing_raised do
      Sidekiq::Worker.drain_all
    end
    # should not duplicate tag
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [{ tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm1.id.to_s + '" }, { tag: "bar", annotated_type: "ProjectMedia", annotated_id: "' + @pm2.id.to_s + '" }, { tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm3.id.to_s + '" }, { tag: "test", annotated_type: "ProjectMedia", annotated_id: "' + pm4.id.to_s + '" }, { tag: "bar", annotated_type: "Dynamic", annotated_id: "' + d.id.to_s + '" }]}) { team { dbid } } }'
    assert_no_difference 'TagText.count' do
      assert_no_difference 'Tag.length' do
        post :create, params: { query: query, team: @t.slug }
        assert_response :success
      end
    end
  end

  test "should bulk-assign project medias" do
    with_versioning do
      u = create_user
      create_team_user team: @t, user: u
      u1 = create_user
      create_team_user team: @t, user: u1
      u2 = create_user
      create_team_user team: @t, user: u2
      u3 = create_user
      status = @pm1.last_status_obj
      with_current_user_and_team(u, @t) do
          Assignment.create!(assigned_type: 'Annotation', assigned_id: status.id, user_id: u.id)
      end
      pm1_assignments = Annotation.joins(:assignments).where(
          'annotations.annotated_type' => 'ProjectMedia',
          'annotations.annotated_id' => @pm1.id,
          'annotations.annotation_type' => 'verification_status'
          ).count
      assert_equal 1, pm1_assignments
      assigned_to_ids = [u1.id, u2.id, u3.id].join(', ')
      assert_equal 1, @pm1.get_versions_log(['create_assignment']).size
      Sidekiq::Testing.inline! do
        query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "assigned_to_ids", params: "{\"assignment_message\":\"add custom message\",\"assigned_to_ids\":\"' + assigned_to_ids + '\"}"}) { ids, team { dbid } } }'
        assert_difference 'Assignment.count', 6 do
          post :create, params: { query: query, team: @t.slug }
          assert_response :success
        end
        pm1_assignments = Annotation.joins(:assignments).where(
            'annotations.annotated_type' => 'ProjectMedia',
            'annotations.annotated_id' => @pm1.id,
            'annotations.annotation_type' => 'verification_status'
            ).count
        assert_equal 3, pm1_assignments
        assert_equal 3, @pm1.get_versions_log(['create_assignment']).size
      end
    end
  end

  test "should bulk-update project medias status" do
    with_versioning do
      u = create_user
      create_team_user team: @t, user: u, role: 'admin'
      authenticate_with_user(u)
      assert_equal 0, @pm1.get_versions_log(['update_dynamicannotationfield']).size
      Sidekiq::Testing.inline! do
        query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "update_status", params: "{\"status\":\"in_progress\"}"}) { ids, team { dbid } } }'
        post :create, params: { query: query, team: @t.slug }
        assert_response :success
        assert_equal 'in_progress', @pm1.last_status
        assert_equal 1, @pm1.get_versions_log(['update_dynamicannotationfield']).size
      end
    end
  end

  test "should bulk-update project medias tags" do
    u = create_user
    create_team_user team: @t, user: u, role: 'admin'
    authenticate_with_user(u)
    sports = create_tag_text team_id: @t.id, text: 'sports'
    news = create_tag_text team_id: @t.id, text: 'news'
    pm1_t = create_tag annotated: @pm1, tag: sports.id
    pm2_t = create_tag annotated: @pm2, tag: news.id
    assert_equal [pm1_t], sports.reload.tags.to_a
    assert_equal [pm2_t], news.reload.tags.to_a
    tag_text_ids = [sports.id, news.id].join(', ')
    Sidekiq::Testing.inline! do
      query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', action: "remove_tags", params: "{\"tags_text\":\"' + tag_text_ids + '\"}"}) { ids, team { dbid } } }'
      post :create, params: { query: query, team: @t.slug }
      assert_response :success
      assert_empty sports.reload.tags.to_a
      assert_empty news.reload.tags.to_a
    end
  end

  test "should bulk-mark-read project medias" do
    u = create_user
    create_team_user team: @t, user: u, role: 'admin'
    authenticate_with_user(u)
    @pms.each { |pm| assert_not pm.read }
    assert_search_finds_all({ read: 0 })
    assert_search_finds_none({ read: 1 })
    query = 'mutation { bulkProjectMediaMarkRead(input: { clientMutationId: "1", ids: ' + @ids + ', read: true }) { updated_objects { id, is_read, dbid }, ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    updated_objects = JSON.parse(@response.body)['data']['bulkProjectMediaMarkRead']['updated_objects']
    assert_equal @pms.map(&:id).sort, updated_objects.collect{|obj| obj['dbid']}.sort
    @pms.each { |pm| assert pm.reload.read }
    assert_search_finds_all({ read: 1 })
    assert_search_finds_none({ read: 0 })
  end

  test "should not bulk-mark-read project medias if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { bulkProjectMediaMarkRead(input: { clientMutationId: "1", ids: ' + ids.to_json + ', read: true }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response 400
    assert_error_message 'maximum'
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
