require_relative '../test_helper'

class GraphqlController9Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    TestDynamicAnnotationTables.load!
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
    Sidekiq::Testing.inline! do
      pm = create_project_media team: @t
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
      # Verify item tasks order
      pm_tm2 = pm.annotations('task').select{|t| t.team_task_id == @tm2.id}.last
      assert_equal 1, pm_tm2.order
      pm_tm1 = pm.annotations('task').select{|t| t.team_task_id == @tm1.id}.last
      assert_equal 2, pm_tm1.order
      pm_tm3 = pm.annotations('task').select{|t| t.team_task_id == @tm3.id}.last
      assert_equal 3, pm_tm3.order
    end
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
    p1 = random_complex_password
    u = create_user password: p1
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
    query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{u.id}, otp_required: #{true}, password: \"#{p1}\", qrcode: \"#{u.current_otp}\" }) { success }}"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert u.reload.otp_required_for_login?
    query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{u.id}, otp_required: #{false}, password: \"#{p1}\" }) { success }}"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not u.reload.otp_required_for_login?
    # Disable with invalid uid
    query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{invalid_uid}, otp_required: #{false}, password: \"#{p1}\" }) { success }}"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
  end

  test "should create tipline newsletter" do
    query = 'mutation create { createTiplineNewsletter(input: { clientMutationId: "1", content_type: "rss", rss_feed_url: "https://meedan.com/feed.xml", introduction: "Test", language: "en", time: "10:00", send_every: ["monday"], timezone: "America/Los_Angeles" }) { tipline_newsletter { id, time, send_on, enabled } } }'
    assert_difference 'TiplineNewsletter.count' do
      post :create, params: { query: query, team: @t.slug }
    end
    assert_response :success
  end

  test "should update tipline newsletter" do
    tn = create_tipline_newsletter team: @t
    query = 'mutation update { updateTiplineNewsletter(input: { clientMutationId: "1", introduction: "Updated", id: "' + tn.graphql_id + '" }) { tipline_newsletter { id, time, send_on, enabled } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal 'Updated', tn.reload.introduction
  end

  test "should return tipline newsletter errors as an array" do
    query = 'mutation create { createTiplineNewsletter(input: { clientMutationId: "1", enabled: true, content_type: "rss", language: "en", time: "10:00", send_every: ["holiday"], timezone: "America/Los_Angeles" }) { tipline_newsletter { id, time, send_on, enabled } } }'
    assert_no_difference 'TiplineNewsletter.count' do
      post :create, params: { query: query, team: @t.slug }
    end
    assert_response 400
    assert_equal ['introduction', 'rss_feed_url', 'send_every'], JSON.parse(@response.body)['errors'][0]['data'].keys.sort
  end

  test "should update team link management settings" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", shorten_outgoing_urls: true, outgoing_urls_utm_code: "test" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert t.reload.get_shorten_outgoing_urls
    assert_equal 'test', t.reload.get_outgoing_urls_utm_code
  end

  test "should get tipline messages by uid" do
    t = create_team slug: 'test', private: true
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    uid = random_string
    uid2 = random_string
    uid3 = random_string
    tp1_uid = create_tipline_message team_id: t.id, uid: uid, state: 'sent'
    tp2_uid = create_tipline_message team_id: t.id, uid: uid, state: 'delivered'
    tp1_uid2 = create_tipline_message team_id: t.id, uid: uid2, state: 'sent'
    tp2_uid2 = create_tipline_message team_id: t.id, uid: uid2, state: 'delivered'

    query = 'query read { team(slug: "test") { tipline_messages(uid:"'+ uid +'") { edges { node { dbid, event, direction, language, platform, uid, external_id, payload, team_id, state, team { dbid}, sent_at } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['tipline_messages']['edges']
    assert_equal [tp1_uid.id, tp2_uid.id], edges.collect{ |e| e['node']['dbid'] }.sort

    query = 'query read { team(slug: "test") { tipline_messages(uid:"'+ uid2 +'") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['tipline_messages']['edges']
    assert_equal [tp1_uid2.id, tp2_uid2.id], edges.collect{ |e| e['node']['dbid'] }.sort

    query = 'query read { team(slug: "test") { tipline_messages(uid:"'+ uid3 +'") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['tipline_messages']['edges']
    assert_empty edges
  end

  test "non members should not read tipline messages" do
    t = create_team slug: 'test', private: true
    uid = random_string
    tp1_uid = create_tipline_message team_id: t.id, uid: uid, state: 'sent'
    authenticate_with_user
    create_team slug: 'team', name: 'Team', private: true
    query = 'query read { team(slug: "test") { name, tipline_messages(uid:"'+ uid +'") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response 200
    assert_equal "Not Found", JSON.parse(@response.body)['errors'][0]['message']
  end

  test "should get latest tipline messages" do
    t = create_team slug: 'test', private: true
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    uid = random_string

    tm1 = create_tipline_message team_id: t.id, uid: uid, sent_at: Time.now.ago(2.hours)
    tm2 = create_tipline_message team_id: t.id, uid: uid, sent_at: Time.now.ago(1.hour)

    authenticate_with_user(u)

    query = 'query latest { team(slug: "test") { tipline_messages(first: 1, uid:"' + uid + '") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tm2.id, results[0]
  end

  test "should paginate tipline messages" do
    skip 'Pagination disabled in this commit'
    t = create_team slug: 'test', private: true
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    uid = random_string

    tp1_uid = create_tipline_message team_id: t.id, uid: uid
    tp2_uid = create_tipline_message team_id: t.id, uid: uid
    tp3_uid = create_tipline_message team_id: t.id, uid: uid

    authenticate_with_user(u)

    # Paginating one item per page

    # Page 1
    query = 'query read { team(slug: "test") { tipline_messages(first: 1, uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tp1_uid.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasNextPage']

    # Page 2
    query = 'query read { team(slug: "test") { tipline_messages(first: 1, after: "' + page_info['endCursor'] + '", uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tp2_uid.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasNextPage']
    id_cursor_2 = page_info['endCursor']
    # Page 3
    query = 'query read { team(slug: "test") { tipline_messages(first: 1, after: "' + page_info['endCursor'] + '", uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tp3_uid.id, results[0]
    page_info = data['pageInfo']
    assert !page_info['hasNextPage']
    # paginate using specific message id
    tp4_uid = create_tipline_message team_id: t.id, uid: uid
    tp5_uid = create_tipline_message team_id: t.id, uid: uid
    tp6_uid = create_tipline_message team_id: t.id, uid: uid
    query = 'query read { tipline_message(id: "' + tp4_uid.id.to_s + '") { cursor } }'
    post :create, params: { query: query }
    assert_response :success
    id_cursor_4 = JSON.parse(@response.body)['data']['tipline_message']['cursor']
    # Start with tp4_uid message and use after
    query = 'query read { team(slug: "test") { tipline_messages(first: 1, after: "' + id_cursor_4 + '", uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tp5_uid.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasNextPage']
    # Next page
    query = 'query read { team(slug: "test") { tipline_messages(first: 1, after: "' + page_info['endCursor'] + '", uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tp6_uid.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasPreviousPage']
    assert !page_info['hasNextPage']
    # Start with tp4_uid message and use before
    query = 'query read { team(slug: "test") { tipline_messages(last: 1, before: "' + id_cursor_4 + '", uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 1, results.size
    assert_equal tp3_uid.id, results[0]
    page_info = data['pageInfo']
    assert page_info['hasNextPage']
    # User after and before
    query = 'query read { team(slug: "test") { tipline_messages(after: "' + id_cursor_2 + '", before: "' + id_cursor_4 + '", uid:"'+ uid +'") { pageInfo { endCursor, startCursor, hasPreviousPage, hasNextPage } edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['tipline_messages']
    results = data['edges'].to_a.collect{ |e| e['node']['dbid'] }
    assert_equal 3, results.size
    assert_equal [tp2_uid.id, tp3_uid.id, tp4_uid.id], results.sort
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end
end
