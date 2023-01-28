require_relative '../test_helper'

class GraphqlController9Test < ActionController::TestCase
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

    test "should update project media source" do
      s = create_source team: @t
      s2 = create_source team: @t
      pm = create_project_media team: @t, source_id: s.id, skip_autocreate_source: false
      pm2 = create_project_media team: @t, source_id: s2.id, skip_autocreate_source: false
      assert_equal s.id, pm.source_id
      query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm.graphql_id}\", source_id: #{s2.id}}) { project_media { source { dbid, medias_count, medias(first: 10) { edges { node { dbid } } } } } } }"
      post :create, params: { query: query, team: @t.slug }
      assert_response :success
      data = JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']
      assert_equal s2.id, data['source']['dbid']
      assert_equal 2, data['source']['medias_count']
      assert_equal 2, data['source']['medias']['edges'].size
    end

    test "should not get Smooch Bot RSS feed preview if not owner" do
      u = create_user
      t = create_team
      b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
      tbi = create_team_bot_installation team_id: t.id, user_id: b.id
      tu = create_team_user team: t, user: u, role: 'collaborator'
      authenticate_with_user(u)
      url = random_url
      output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
      query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
      post :create, params: { query: query, team: t.slug }
      assert_match /Sorry/, @response.body
    end
  
    test "should not get Smooch Bot RSS feed preview if not member of the team" do
      u = create_user
      t = create_team
      b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
      tbi = create_team_bot_installation team_id: t.id, user_id: b.id
      tu = create_team_user team: t, user: u, role: 'admin'
      authenticate_with_user(create_user)
      url = random_url
      output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
      query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
      post :create, params: { query: query, team: t.slug }
      assert_match /Sorry/, @response.body
    end

    test "should get timezone from header" do
      authenticate_with_user
      @request.headers['X-Timezone'] = 'America/Bahia'
      t = create_team slug: 'context'
      post :create, params: { query: 'query Query { me { name } }' }
      assert_equal 'America/Bahia', assigns(:context_timezone)
    end
  
    test "should get dynamic annotation field" do
      create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
      name = random_string
      phone = random_string
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'editor'
      p = create_project team: t
      pm = create_project_media project: p
      d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
      authenticate_with_token
      query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + name + '\" } }") { annotation { dbid } } }'
      post :create, params: { query: query }
      assert_response :success
      assert_equal d.id.to_s, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid']
    end
  
    test "should not get dynamic annotation field if does not have permission" do
      create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
      name = random_string
      phone = random_string
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'editor'
      p = create_project team: t
      pm = create_project_media project: p
      d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
      authenticate_with_user(u)
      query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + name + '\" } }") { annotation { dbid } } }'
      post :create, params: { query: query }
      assert_response :success
      assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']
    end

    test "should not get dynamic annotation field if parameters do not match" do
      create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
      name = random_string
      phone = random_string
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'editor'
      p = create_project team: t
      pm = create_project_media project: p
      d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
      authenticate_with_user(u)
      query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + random_string + '\" } }") { annotation { dbid } } }'
      post :create, params: { query: query }
      assert_response :success
      assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']
    end

    test "should handle nested error" do
      u = create_user
      t = create_team
      create_team_user team: t, user: u
      authenticate_with_user(u)
      p = create_project team: t
      pm = create_project_media project: p
      RelayOnRailsSchema.stubs(:execute).raises(GraphQL::Batch::NestedError)
      query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
      post :create, params: { query: query, team: t.slug }
      assert_response 400
      RelayOnRailsSchema.unstub(:execute)
    end

    test "should change role of bot" do
      u = create_user is_admin: true
      i = create_team_bot_installation
      authenticate_with_user(u)
  
      id = Base64.encode64("TeamUser/#{i.id}")
      query = 'mutation update { updateTeamUser(input: { clientMutationId: "1", id: "' + id + '", role: "editor" }) { team_user { id } } }'
      post :create, params: { query: query, team: i.team.slug }
      assert_response :success
    end

    test "should handle user 2FA" do
      u = create_user password: 'test1234'
      t = create_team
      create_team_user team: t, user: u
      authenticate_with_user(u)
      u.two_factor
      # generate backup codes with valid uid
      query = "mutation generateTwoFactorBackupCodes { generateTwoFactorBackupCodes(input: { clientMutationId: \"1\", id: #{u.id} }) { success, codes } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal 5, JSON.parse(@response.body)['data']['generateTwoFactorBackupCodes']['codes'].size
      # generate backup codes with invalid uid
      invalid_uid = u.id + rand(10..100)
      query = "mutation generateTwoFactorBackupCodes { generateTwoFactorBackupCodes(input: { clientMutationId: \"1\", id: #{invalid_uid} }) { success, codes } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      # Enable/Disable 2FA
      query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{u.id}, otp_required: #{true}, password: \"test1234\", qrcode: \"#{u.current_otp}\" }) { success }}"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert u.reload.otp_required_for_login?
      query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{u.id}, otp_required: #{false}, password: \"test1234\" }) { success }}"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_not u.reload.otp_required_for_login?
      # Disable with invalid uid
      query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{invalid_uid}, otp_required: #{false}, password: \"test1234\" }) { success }}"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
    end

    test "should return project medias with provided URL that user has access to" do
      l = create_valid_media
      u = create_user
      t = create_team
      t2 = create_team
      create_team_user team: t, user: u
      create_team_user team: t2, user: u
      authenticate_with_user(u)
      p1 = create_project team: t
      p2 = create_project team: t2
      pm1 = create_project_media project: p1, media: l
      pm2 = create_project_media project: p2, media: l
      pm3 = create_project_media media: l
      query = "query GetById { project_medias(url: \"#{l.url}\", first: 10000) { edges { node { dbid } } } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal [pm1.id], JSON.parse(@response.body)['data']['project_medias']['edges'].collect{ |x| x['node']['dbid'] }
    end
  
    test "should return project medias when provided URL is not normalized and it exists on db" do
      url = 'http://www.atarde.uol.com.br/bahia/salvador/noticias/2089363-comunidades-recebem-caminhao-da-biometria-para-regularizacao-eleitoral'
      url_normalized = 'http://www.atarde.com.br/bahia/salvador/noticias/2089363-comunidades-recebem-caminhao-da-biometria-para-regularizacao-eleitoral'
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url_normalized + '","type":"item"}}')
      m = create_media url: url
      u = create_user
      t = create_team
      create_team_user team: t, user: u
      authenticate_with_user(u)
      p = create_project team: t
      pm = create_project_media project: p, media: m
      query = "query GetById { project_medias(url: \"#{url}\", first: 10000) { edges { node { dbid } } } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal [pm.id], JSON.parse(@response.body)['data']['project_medias']['edges'].collect{ |x| x['node']['dbid'] }
    end



    protected

    def assert_error_message(expected)
      assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
    end

end