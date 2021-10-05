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
    assert_equal 1, t0.reload.first_response_obj.file_data.size
    assert_equal ['rails.png'], t0.reload.first_response_obj.file_data.collect{ |f| f.split('/').last }

    query = 'mutation { addFilesToTask(input: { clientMutationId: "1", id: "' + t0.graphql_id + '" }) { task { id } } }'
    post :create, params: { query: query, file: { '0' => @f2, '1' => @f3 }, team: @t.slug }
    assert_response :success
    assert_equal 3, t0.reload.first_response_obj.file_data.size
    assert_equal ['rails.png', 'rails2.png', 'rails.mp4'].sort, t0.reload.first_response_obj.file_data.collect{ |f| f.split('/').last }.sort

    query = 'mutation { removeFilesFromTask(input: { clientMutationId: "1", id: "' + t0.graphql_id + '", filenames: ["rails.mp4", "rails.png"] }) { task { id } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal 1, t0.reload.first_response_obj.file_data.size
    assert_equal ['rails2.png'], t0.reload.first_response_obj.file_data.collect{ |f| f.split('/').last }
  end

  test "should transcribe audio" do
    Sidekiq::Testing.inline! do
      t = create_team
      pm = create_project_media team: t, media: create_uploaded_audio(file: 'rails.mp3')
      url = Bot::Alegre.media_file_url(pm)
      s3_url = url.gsub(/^https?:\/\/[^\/]+/, "s3://#{CheckConfig.get('storage_bucket')}")

      Bot::Alegre.unstub(:request_api)
      Bot::Alegre.stubs(:request_api).with('post', '/audio/transcription/', { url: s3_url, job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }).returns({ 'job_status' => 'IN_PROGRESS' })
      Bot::Alegre.stubs(:request_api).with('get', '/audio/transcription/', { job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }).returns({ 'job_status' => 'COMPLETED', 'transcription' => 'Foo bar' })

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

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end
end
