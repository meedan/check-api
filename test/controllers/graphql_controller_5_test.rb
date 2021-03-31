require_relative '../test_helper'

class GraphqlController5Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    @controller = Api::V1::GraphqlController.new
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    @t = create_team private: true
    @tt1 = create_team_task team_id: @t.id, fieldset: 'tasks' ; sleep 1
    @tt2 = create_team_task team_id: @t.id, fieldset: 'tasks' ; sleep 1
    @tt3 = create_team_task team_id: @t.id, fieldset: 'tasks' ; sleep 1
    @tm1 = create_team_task team_id: @t.id, fieldset: 'metadata' ; sleep 1
    @tm2 = create_team_task team_id: @t.id, fieldset: 'metadata' ; sleep 1
    @tm3 = create_team_task team_id: @t.id, fieldset: 'metadata' ; sleep 1
    TeamTask.update_all(order: nil)
    @pm = create_project_media team: @t
    Task.delete_all
    @t1 = create_task annotated: @pm, fieldset: 'tasks' ; sleep 1
    @t2 = create_task annotated: @pm, fieldset: 'tasks' ; sleep 1
    @t3 = create_task annotated: @pm, fieldset: 'tasks' ; sleep 1
    @m1 = create_task annotated: @pm, fieldset: 'metadata' ; sleep 1
    @m2 = create_task annotated: @pm, fieldset: 'metadata' ; sleep 1
    @m3 = create_task annotated: @pm, fieldset: 'metadata' ; sleep 1
    [@t1, @t2, @t3, @m1, @m2, @m3].each { |t| t.order = nil ; t.save! }
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    authenticate_with_user(@u)
  end

  # Make sure that testing data is ordered by creation date since all values for the "order" attribute are null
  test "should return ordered data" do
    assert_equal [@tt1, @tt2, @tt3].map(&:id), @t.ordered_team_tasks('tasks').map(&:id)
    assert_equal [@tm1, @tm2, @tm3].map(&:id), @t.ordered_team_tasks('metadata').map(&:id)
    [@tt1, @tt2, @tt3, @tm1, @tm2, @tm3].each { |t| assert_nil t.reload.order }
    assert_equal [@t1, @t2, @t3].map(&:id), @pm.ordered_tasks('tasks').map(&:id)
    assert_equal [@m1, @m2, @m3].map(&:id), @pm.ordered_tasks('metadata').map(&:id)
    [@t1, @t2, @t3, @m1, @m2, @m3].each { |t| assert_nil t.reload.order }
  end

  test "should not move team task up" do
    t = create_team private: true
    tt = create_team_task team_id: t.id
    query = 'mutation { moveTeamTaskUp(input: { clientMutationId: "1", id: "' + tt.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should not move team task down" do
    t = create_team private: true
    tt = create_team_task team_id: t.id
    query = 'mutation { moveTeamTaskDown(input: { clientMutationId: "1", id: "' + tt.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should move team task up" do
    query = 'mutation { moveTeamTaskUp(input: { clientMutationId: "1", id: "' + @tt2.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 1, @tt2.reload.order
    assert_equal 2, @tt1.reload.order
    data = JSON.parse(@response.body)['data']['moveTeamTaskUp']
    assert_equal 1, data['team_task']['order']
    tasks = data['team']['team_tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @tt2.id, tasks[0]['node']['dbid']
    assert_equal @tt1.id, tasks[1]['node']['dbid']
    assert_equal @tt3.id, tasks[2]['node']['dbid']
  end

  test "should move team task down" do
    query = 'mutation { moveTeamTaskDown(input: { clientMutationId: "1", id: "' + @tt2.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 3, @tt2.reload.order
    assert_equal 2, @tt3.reload.order
    data = JSON.parse(@response.body)['data']['moveTeamTaskDown']
    assert_equal 3, data['team_task']['order']
    tasks = data['team']['team_tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @tt1.id, tasks[0]['node']['dbid']
    assert_equal @tt3.id, tasks[1]['node']['dbid']
    assert_equal @tt2.id, tasks[2]['node']['dbid']
  end

  test "should move team metadata up" do
    query = 'mutation { moveTeamTaskUp(input: { clientMutationId: "1", id: "' + @tm2.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "metadata", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 1, @tm2.reload.order
    assert_equal 2, @tm1.reload.order
    data = JSON.parse(@response.body)['data']['moveTeamTaskUp']
    assert_equal 1, data['team_task']['order']
    tasks = data['team']['team_tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @tm2.id, tasks[0]['node']['dbid']
    assert_equal @tm1.id, tasks[1]['node']['dbid']
    assert_equal @tm3.id, tasks[2]['node']['dbid']
  end

  test "should move team metadata down" do
    query = 'mutation { moveTeamTaskDown(input: { clientMutationId: "1", id: "' + @tm2.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "metadata", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 3, @tm2.reload.order
    assert_equal 2, @tm3.reload.order
    data = JSON.parse(@response.body)['data']['moveTeamTaskDown']
    assert_equal 3, data['team_task']['order']
    tasks = data['team']['team_tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @tm1.id, tasks[0]['node']['dbid']
    assert_equal @tm3.id, tasks[1]['node']['dbid']
    assert_equal @tm2.id, tasks[2]['node']['dbid']
  end

  test "should not move task up" do
    t = create_team private: true
    pm = create_project_media team: t
    tk = create_task annotated: pm
    query = 'mutation { moveTaskUp(input: { clientMutationId: "1", id: "' + tk.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should not move task down" do
    t = create_team private: true
    pm = create_project_media team: t
    tk = create_task annotated: pm
    query = 'mutation { moveTaskDown(input: { clientMutationId: "1", id: "' + tk.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should move task up" do
    query = 'mutation { moveTaskUp(input: { clientMutationId: "1", id: "' + @t2.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 1, @t2.reload.order
    assert_equal 2, @t1.reload.order
    data = JSON.parse(@response.body)['data']['moveTaskUp']
    assert_equal 1, data['task']['order']
    tasks = data['project_media']['tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @t2.id.to_s, tasks[0]['node']['dbid']
    assert_equal @t1.id.to_s, tasks[1]['node']['dbid']
    assert_equal @t3.id.to_s, tasks[2]['node']['dbid']
  end

  test "should move task down" do
    query = 'mutation { moveTaskDown(input: { clientMutationId: "1", id: "' + @t2.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 3, @t2.reload.order
    assert_equal 2, @t3.reload.order
    data = JSON.parse(@response.body)['data']['moveTaskDown']
    assert_equal 3, data['task']['order']
    tasks = data['project_media']['tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @t1.id.to_s, tasks[0]['node']['dbid']
    assert_equal @t3.id.to_s, tasks[1]['node']['dbid']
    assert_equal @t2.id.to_s, tasks[2]['node']['dbid']
  end

  test "should move metadata up" do
    query = 'mutation { moveTaskUp(input: { clientMutationId: "1", id: "' + @m2.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "metadata", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 1, @m2.reload.order
    assert_equal 2, @m1.reload.order
    data = JSON.parse(@response.body)['data']['moveTaskUp']
    assert_equal 1, data['task']['order']
    tasks = data['project_media']['tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @m2.id.to_s, tasks[0]['node']['dbid']
    assert_equal @m1.id.to_s, tasks[1]['node']['dbid']
    assert_equal @m3.id.to_s, tasks[2]['node']['dbid']
  end

  test "should move metadata down" do
    query = 'mutation { moveTaskDown(input: { clientMutationId: "1", id: "' + @m2.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "metadata", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, query: query, team: @t.slug
    assert_response :success
    assert_equal 3, @m2.reload.order
    assert_equal 2, @m3.reload.order
    data = JSON.parse(@response.body)['data']['moveTaskDown']
    assert_equal 3, data['task']['order']
    tasks = data['project_media']['tasks']['edges']
    assert_equal 1, tasks[0]['node']['order']
    assert_equal 2, tasks[1]['node']['order']
    assert_equal 3, tasks[2]['node']['order']
    assert_equal @m1.id.to_s, tasks[0]['node']['dbid']
    assert_equal @m3.id.to_s, tasks[1]['node']['dbid']
    assert_equal @m2.id.to_s, tasks[2]['node']['dbid']
  end

  test "should update project media source" do
    s = create_source team: @t
    s2 = create_source team: @t
    pm = create_project_media team: @t, source_id: s.id, skip_autocreate_source: false
    pm2 = create_project_media team: @t, source_id: s2.id, skip_autocreate_source: false
    assert_equal s.id, pm.source_id
    query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm.graphql_id}\", source_id: #{s2.id}}) { project_media { source { dbid, medias_count, medias(first: 10) { edges { node { dbid } } } } } } }"
    post :create, query: query, team: @t.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']
    assert_equal s2.id, data['source']['dbid']
    assert_equal 2, data['source']['medias_count']
    assert_equal 2, data['source']['medias']['edges'].size
  end

  test "should create related project media for source" do
    t = create_team
    pm = create_project_media team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation create { createSource(input: { name: "new source", slogan: "new source", clientMutationId: "1", add_to_project_media_id: ' + pm.id.to_s + ' }) { source { dbid } } }'
    post :create, query: query, team: t
    assert_response :success
    source = JSON.parse(@response.body)['data']['createSource']['source']
    assert_equal pm.reload.source_id, source['dbid']
  end

  test "should search team sources by keyword" do
    t = create_team slug: 'sawy'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_source team: t, name: 'keyword begining'
    create_source team: t, name: 'ending keyword'
    create_source team: t, name: 'in the KEYWORD middle'
    create_source team: t
    authenticate_with_user(u)
    query = 'query read { team(slug: "sawy") { sources(first: 1000) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['sources']['edges']
    assert_equal 4, edges.length
    query = 'query read { team(slug: "sawy") { sources(first: 1000, keyword: "keyword") { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['sources']['edges']
    assert_equal 3, edges.length
  end

  test "should update last_active_at from users before a graphql request" do
    assert_nil @u.last_active_at
    query = "query { user(id: #{@u.id}) { last_active_at } }"
    post :create, query: query
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['user']['last_active_at']
    assert_not_nil @u.reload.last_active_at
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end
end
