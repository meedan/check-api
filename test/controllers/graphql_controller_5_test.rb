require_relative '../test_helper'

class GraphqlController5Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    @controller = Api::V1::GraphqlController.new
    create_annotation_type annotation_type: 'task_response'
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
    @f1 = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.png'), 'image/png')
    @f2 = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails2.png'), 'image/png')
    @f3 = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.mp4'), 'video/mp4')
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
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should not move team task down" do
    t = create_team private: true
    tt = create_team_task team_id: t.id
    query = 'mutation { moveTeamTaskDown(input: { clientMutationId: "1", id: "' + tt.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should move team task up" do
    query = 'mutation { moveTeamTaskUp(input: { clientMutationId: "1", id: "' + @tt2.graphql_id + '" }) { team_task { order }, team { team_tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should not move task down" do
    t = create_team private: true
    pm = create_project_media team: t
    tk = create_task annotated: pm
    query = 'mutation { moveTaskDown(input: { clientMutationId: "1", id: "' + tk.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_error_message "Not Found"
  end

  test "should move task up" do
    query = 'mutation { moveTaskUp(input: { clientMutationId: "1", id: "' + @t2.graphql_id + '" }) { task { order }, project_media { tasks(fieldset: "tasks", first: 10) { edges { node { dbid, order } } } } } }'
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: @t.slug }
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
    post :create, params: { query: query, team: @t.slug }
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

  test "should add files to task and remove files from task" do
    t0 = create_task annotated: @pm, fieldset: 'tasks', task_type: 'file_upload' ; sleep 1
    t0.response = { annotation_type: 'task_response' }.to_json
    t0.save!
    assert_equal 0, t0.reload.first_response_obj.file_data.size

    query = 'mutation { addFilesToTask(input: { clientMutationId: "1", id: "' + t0.graphql_id + '" }) { task { id } } }'
    post :create, params: { query: query, file: { '0' => @f1 }, team: @t.slug }
    assert_response :success
    assert_equal 1, t0.reload.first_response_obj.file_data[:file_urls].size
    assert_equal ['rails.png'], t0.reload.first_response_obj.file_data[:file_urls].collect{ |f| f.split('/').last }

    query = 'mutation { addFilesToTask(input: { clientMutationId: "1", id: "' + t0.graphql_id + '" }) { task { id } } }'
    post :create, params: { query: query, file: { '0' => @f2, '1' => @f3 }, team: @t.slug }
    assert_response :success
    assert_equal 3, t0.reload.first_response_obj.file_data[:file_urls].size
    assert_equal ['rails.png', 'rails2.png', 'rails.mp4'].sort, t0.reload.first_response_obj.file_data[:file_urls].collect{ |f| f.split('/').last }.sort

    query = 'mutation { removeFilesFromTask(input: { clientMutationId: "1", id: "' + t0.graphql_id + '", filenames: ["rails.mp4", "rails.png"] }) { task { id } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal 1, t0.reload.first_response_obj.file_data[:file_urls].size
    assert_equal ['rails2.png'], t0.reload.first_response_obj.file_data[:file_urls].collect{ |f| f.split('/').last }
  end

  test "should transcribe audio" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    Sidekiq::Testing.inline! do
      t = create_team
      pm = create_project_media team: t, media: create_uploaded_audio(file: 'rails.mp3')
      url = Bot::Alegre.media_file_url(pm)
      s3_url = url.gsub(/^https?:\/\/[^\/]+/, "s3://#{CheckConfig.get('storage_bucket')}")

      Bot::Alegre.unstub(:request_api)
      Bot::Alegre.stubs(:request_api).returns({ success: true })
      Bot::Alegre.stubs(:request_api).with('post', '/audio/transcription/', { url: s3_url, job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }).returns({ 'job_status' => 'IN_PROGRESS' })
      Bot::Alegre.stubs(:request_api).with('get', '/audio/transcription/', { job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }).returns({ 'job_status' => 'COMPLETED', 'transcription' => 'Foo bar' })
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)

      json_schema = {
        type: 'object',
        required: ['job_name'],
        properties: {
          text: { type: 'string' },
          job_name: { type: 'string' },
          last_response: { type: 'object' }
        }
      }
      create_annotation_type_and_fields('Transcription', {}, json_schema)
      b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
      b.install_to!(t)
      WebMock.stub_request(:get, Bot::Alegre.media_file_url(pm)).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))

      query = 'mutation { transcribeAudio(input: { clientMutationId: "1", id: "' + pm.graphql_id + '" }) { project_media { id }, annotation { data } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal 'Foo bar', JSON.parse(@response.body)['data']['transcribeAudio']['annotation']['data']['text']

      Bot::Alegre.unstub(:request_api)
    end
  end

  test "should find similar items to media item" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, media: create_uploaded_audio(file: 'rails.mp3')
    pm2 = create_project_media project: p
    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ pm2.id => 0.9, pm.id => 0.8 })

    query = 'query { project_media(ids: "' + [pm.id, p.id, t.id].join(',') + '") { similar_items(first: 10000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal pm2.id, JSON.parse(@response.body)['data']['project_media']['similar_items']['edges'][0]['node']['dbid']

    Bot::Alegre.unstub(:get_items_with_similar_media)
  end

  test "should find similar items to text item" do
    t = create_team
    p = create_project team: t
    m = create_claim_media quote: 'This is a test'
    m2 = create_claim_media quote: 'Foo bar'
    pm = create_project_media project: p, media: m
    pm2 = create_project_media project: p, media: m2
    Bot::Alegre.stubs(:get_similar_texts).returns({ pm2.id => 0.9, pm.id => 0.8 })

    query = 'query { project_media(ids: "' + [pm.id, p.id, t.id].join(',') + '") { similar_items(first: 10000) { edges { node { dbid, claim_description { id } } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal pm2.id, JSON.parse(@response.body)['data']['project_media']['similar_items']['edges'][0]['node']['dbid']

    Bot::Alegre.unstub(:get_similar_texts)
  end

  test "should create and update flags and content warning" do
    create_flag_annotation_type
    t = create_team
    u = create_user is_admin: true
    pm = create_project_media team: t
    authenticate_with_user(u)
    # verify create
    query = 'mutation create { createDynamicAnnotationFlag(input: { clientMutationId: "1", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", set_fields: "{\"flags\":{\"adult\":3,\"spoof\":2,\"medical\":1,\"violence\":3,\"racy\":4,\"spam\":0},\"show_cover\":false}" }) { dynamic { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    d = Dynamic.find(JSON.parse(@response.body)['data']['createDynamicAnnotationFlag']['dynamic']['dbid'])
    data = d.data.with_indifferent_access
    assert_equal ['flags', 'show_cover'].sort, data.keys.sort
    assert_equal ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam'].sort, data['flags'].keys.sort
    assert !data['show_cover']
    # verify update
    query = 'mutation update { updateDynamicAnnotationFlag(input: { clientMutationId: "1", id: "' + d.graphql_id + '", set_fields: "{\"show_cover\":true}" }) { dynamic { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    d = Dynamic.find(d.id)
    data = d.data.with_indifferent_access
    assert_equal ['flags', 'show_cover'].sort, data.keys.sort
    assert_equal ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam'].sort, data['flags'].keys.sort
    assert data['show_cover']
  end

  test "should return number of tasks related to a team task" do
    t = create_team
    tt = create_team_task team_id: t.id
    p = create_project team: t
    pm = create_project_media project: p
    pm2 = create_project_media project: p
    pm3 = create_project_media project: p
    # add response to task for pm
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
    pm_tt.save!

    query = 'query { team { team_tasks(fieldset: "tasks") { edges { node { dbid tasks_count tasks_with_answers_count } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body)['data']['team']['team_tasks']['edges'][0]['node']
    assert_equal tt.id, response['dbid']
    assert_equal 3, response['tasks_count']
    assert_equal 1, response['tasks_with_answers_count']
  end

  test "should not raise error that user can't be updated" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user user: u, team: t1
    create_team_user user: u, team: t2
    u.current_team_id = t1.id
    u.save!
    authenticate_with_user(u)
    query = 'query { search(query: "{}") { number_of_results } }'
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
  end

  test "should get version related to status change" do
    create_verification_status_stuff
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    p = create_project team: t
    pm = nil
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p
      s = pm.last_status_obj
      s.status = 'in_progress'
      s.save!
    end
    authenticate_with_user(u)
    query = 'query { project_media(ids: "' + [pm.id, p.id, t.id].join(',') + '") {  log(annotation_types: ["verification_status"]) { edges { node { annotation { annotation_type } } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    log = JSON.parse(@response.body)['data']['project_media']['log']['edges'].collect{ |e| e['node'] }
    assert_equal 1, log.size
    assert_equal 'verification_status', log[0]['annotation']['annotation_type']
  end

  test "should get cluster information" do
    u = create_user is_admin: true
    f = create_feed
    t = create_team
    f.teams << t
    p = create_project team: t
    pm = create_project_media project: p
    c = create_cluster project_media: pm
    c.project_medias << pm
    c.project_medias << create_project_media
    authenticate_with_user(u)
    query = 'query { project_media(ids: "' + [pm.id, p.id, t.id].join(',') + '") {  cluster { first_item_at, last_item_at, claim_descriptions(feed_id: ' + f.id.to_s + ') { edges { node { id } } }, items(feed_id: ' + f.id.to_s + ') { edges { node { dbid } } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['project_media']['cluster']['items']['edges'].size
  end

  test "should paginate folder items" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    pm3 = create_project_media project: p
    authenticate_with_user(u)

    # Paginating one item per page

    # Page 1
    query = 'query { project(id: "' + p.id.to_s + '") { project_medias(first: 1) { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project']['project_medias']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal pm3.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasNextPage']

    # Page 2
    query = 'query { project(id: "' + p.id.to_s + '") { project_medias(first: 1, after: "' + page_info['endCursor'] + '") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project']['project_medias']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal pm2.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasNextPage']

    # Page 3
    query = 'query { project(id: "' + p.id.to_s + '") { project_medias(first: 1, after: "' + page_info['endCursor'] + '") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project']['project_medias']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal pm1.id, results[0]
    page_info = data['pageInfo']
    assert !page_info['hasNextPage']
  end

  test "should not create more items than what the rate limit allows" do
    t = create_team
    a = ApiKey.create!
    a.rate_limits = { created_items_per_minute: 1 }
    a.save!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    p = create_project team: t
    authenticate_with_token(a)

    query = 'mutation { createProjectMedia(input: { project_id: ' + p.id.to_s + ', quote: "Foo" }) { project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success

    query = 'mutation { createProjectMedia(input: { project_id: ' + p.id.to_s + ', quote: "Bar" }) { project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response 429
  end

  test "should get feed" do
    t = create_team
    u = create_user is_admin: true
    authenticate_with_user(u)

    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)

    r1 = create_request feed: f
    r2 = create_request feed: f
    r2.similar_to_request = r1
    r2.save!

    query = "query { team { feed(dbid: #{f.id}) { requests_count, requests(request_id: null, first: 100, offset: 0, sort: \"requests\", sort_type: \"asc\") { edges { node { dbid, media { id } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'team', 'feed', 'requests', 'edges')
    assert_equal 1, response.size
    assert_equal r1.id, response.dig(0, 'node', 'dbid')

    query = "query { team { feed(dbid: #{f.id}) { requests_count, requests(request_id: #{r1.id}, first: 100, offset: 0, sort: \"requests\", sort_type: \"asc\") { edges { node { dbid, media { id } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'team', 'feed', 'requests', 'edges')
    assert_equal 2, response.size
  end

  test "should get feed directly by id" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    authenticate_with_user(u)

    f1 = create_feed
    f1.teams << t
    f2 = create_feed
    FeedTeam.update_all(shared: true)

    query = "query { feed(id: \"#{f1.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal f1.id, JSON.parse(@response.body).dig('data', 'feed', 'dbid')

    query = "query { feed(id: \"#{f2.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed', 'dbid')
  end

  test "should get request directly by id" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    authenticate_with_user(u)

    f1 = create_feed
    f1.teams << t
    f2 = create_feed
    FeedTeam.update_all(shared: true)

    r1 = create_request feed: f1
    r2 = create_request feed: f2

    query = "query { request(id: \"#{r1.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal r1.id, JSON.parse(@response.body).dig('data', 'request', 'dbid')

    query = "query { request(id: \"#{r2.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'request', 'dbid')
  end

  test "should filter similar requests by media" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    authenticate_with_user(u)

    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)

    r1 = create_request feed: f
    r2 = create_request feed: f
    r2.similar_to_request = r1
    r2.save!
    m = create_uploaded_image
    r3 = create_request feed: f, media: m
    r3.similar_to_request = r1
    r3.save!

    query = "query { request(id: \"#{r1.id}\") { similar_requests(first: 10) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body).dig('data', 'request', 'similar_requests', 'edges').size

    query = "query { request(id: \"#{r1.id}\") { similar_requests(first: 10, media_id: #{m.id}) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body).dig('data', 'request', 'similar_requests', 'edges').size
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end
end
