require_relative '../test_helper'

class ElasticSearch7Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
    create_task_stuff
  end

  test "should search by task responses" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    tt2 = create_team_task team_id: t.id, type: 'multiple_choice', options: ['ans_a', 'ans_b', 'ans_c']
    tt3 = create_team_task team_id: t.id, type: 'free_text'
    authenticate_with_user(u)
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm_tt.save!
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_b' }.to_json }.to_json
      pm2_tt.save!
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm3_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'ans_a' }]}.to_json)
      assert_equal [pm, pm3], results.medias.sort
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_b', id: tt.id }]}.to_json)
      assert_equal [pm2], results.medias
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_c', id: tt.id }]}.to_json)
      assert_empty results.medias
      # Test with multiple choices
      pm4 = create_project_media team: t, disable_es_callbacks: false
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm4_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['ans_a', 'ans_c'], other: nil }.to_json }.to_json }.to_json
      pm4_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ response: 'ans_a', id: tt2.id }]}.to_json)
      assert_equal [pm4.id], results.medias.map(&:id)
      # Test with free text
      pm5 = create_project_media team: t, disable_es_callbacks: false
      pm6 = create_project_media team: t, disable_es_callbacks: false
      pm5_tt = pm5.annotations('task').select{|t| t.team_task_id == tt3.id}.last
      pm5_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Foo by Sawy' }.to_json }.to_json
      pm5_tt.save!
      pm6_tt = pm6.annotations('task').select{|t| t.team_task_id == tt3.id}.last
      pm6_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Bar by Sawy' }.to_json }.to_json
      pm6_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{response: 'Foo', response_type: 'free_text', id: tt3.id}]}.to_json)
      assert_equal [pm5.id], results.medias.map(&:id)
      results = CheckSearch.new({ team_tasks: [{response: 'Sawy', response_type: 'free_text', id: tt3.id}]}.to_json)
      assert_equal [pm5.id, pm6.id], results.medias.map(&:id).sort
      # Search with different cases
      # A) Test with choice (single/multiple) (exact match)
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":\"ans_a\",\"response_type\":\"choice\",\"id\":' +  tt.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm3.id], ids.sort
      # B) Test with free text (partial match)
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":\"sawy\",\"response_type\":\"free_text\",\"id\":' +  tt3.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm5.id, pm6.id], ids.sort
      # Search in multiple team tasks
      results = CheckSearch.new({team_tasks: [{id: tt.id, response: 'ans_a'}, {id: tt2.id, response: 'ans_a'}]}.to_json)
      assert_empty results.medias
      # "AND" for muliple filters
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['ans_a', 'ans_c'], other: nil }.to_json }.to_json }.to_json
      pm_tt.save!
      sleep 2
      results = CheckSearch.new({team_tasks: [{id: tt.id, response: 'ans_a'}, {id: tt2.id, response: 'ans_c'}]}.to_json)
      assert_equal [pm], results.medias
      # C) "OR" for multiple responses
      query = 'query Search { search(query: "{\"team_tasks\":[{\"response\":[\"ans_a\",\"ans_b\",\"ans_c\"],\"response_type\":\"choice\",\"id\":' +  tt.id.to_s + '}]}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query }
      assert_response :success
      ids = []
      JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
        ids << id["node"]["dbid"]
      end
      assert_equal [pm.id, pm2.id, pm3.id], ids.sort
    end
  end

  test "should update and destroy responses in es" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    tt2 = create_team_task team_id: t.id, type: 'multiple_choice', options: ['choice_a', 'choice_b', 'choice_c']
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      es_id = get_es_id(pm)
      # answer single choice
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_a' }.to_json }.to_json
      pm_tt.save!
      # answer multiple choice
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm_tt2.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['choice_a', 'choice_b'], other: nil }.to_json }.to_json }.to_json
      pm_tt2.save!
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_equal ['ans_a'], sc['value']
      assert_equal ['choice_a', 'choice_b'], mc['value']
      # update answers for single and multiple
      pm_tt = Task.find(pm_tt.id)
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'ans_b' }.to_json }.to_json
      pm_tt.save!
      pm_tt2 = Task.find(pm_tt2.id)
      pm_tt2.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['choice_c'], other: nil }.to_json }.to_json }.to_json
      pm_tt2.save!
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_equal ['ans_b'], sc['value']
      assert_equal ['choice_c'], mc['value']
      # destroy responses
      pm_tt = Task.find(pm_tt.id)
      sc_response = pm_tt.first_response_obj
      sc_response.destroy
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      # destroy should remove answer value
      assert_nil sc['value']
      assert_equal ['choice_c'], mc['value']
      # destroy mmultiple choice answer
      pm_tt2 = Task.find(pm_tt2.id)
      mc_response = pm_tt2.first_response_obj
      mc_response.destroy
      sleep 2
      result = $repository.find(es_id)['task_responses']
      sc = result.select{|r| r['team_task_id'] == tt.id}.first
      mc = result.select{|r| r['team_task_id'] == tt2.id}.first
      assert_nil sc['value']
      assert_nil mc['value']
    end
  end

  test "should parse search options" do
    t = create_team
    pm = create_project_media team: t, archived: 0, disable_es_callbacks: false
    pm2 = create_project_media team: t, archived: 2, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({archived: [0]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # pass wrong format should map to all items
    result = CheckSearch.new({archived: [0]})
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
  end

  test "should filter by keyword and field settings(tite description tags)" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff(false)
    t = create_team
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    url2 = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url2 + '/normalized","type":"item", "title": "search_title", "description":"another_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    m1 = create_media(account: create_valid_account, url: url2)
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    pm2 = create_project_media team: t, media: m1, disable_es_callbacks: false
    # add analysis to pm2
    pm2.analysis = { title: 'override_title', content: 'override_description' }
    # add tags to pm3
    pm3 = create_project_media team: t, disable_es_callbacks: false
    create_tag tag: 'search_title', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'another_desc', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'newtag', annotated: pm3, disable_es_callbacks: false
    sleep 1
    assert_equal 'override_title', pm2.analysis_title
    result = CheckSearch.new({keyword: 'search_title'}.to_json, nil, t.id)
    assert_equal [pm.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['title']}}.to_json, nil, t.id)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_desc', keyword_fields: {fields: ['description']}}.to_json, nil, t.id)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'override_title', keyword_fields: {fields: ['title']}}.to_json, nil, t.id)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'override_description', keyword_fields: {fields: ['description']}}.to_json, nil, t.id)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', keyword_fields: {fields: ['tags']}}.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'another_desc', keyword_fields: {fields:['description', 'tags']}}.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
  end

  test "should search by media url" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","title": "media_title"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, url: url, disable_es_callbacks: false
      sleep 2
      result = $repository.find(get_es_id(pm))['url']
      assert_equal result, url
      results = CheckSearch.new({ keyword: 'test.com' }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ keyword: 'test2.com' }.to_json)
      assert_empty results.medias.map(&:id)
      results = CheckSearch.new({keyword: 'test.com', keyword_fields: {fields: ['url']}}.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({keyword: 'test.com', keyword_fields: {fields: ['title']}}.to_json)
      assert_empty results.medias.map(&:id)
    end
  end

  test "should filter items by channel" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, quote: 'claim a', channel: { main: CheckChannels::ChannelCodes::MANUAL }, disable_es_callbacks: false
      pm2 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::FETCH }, disable_es_callbacks: false
      pm3 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::API }, disable_es_callbacks: false
      pm4 = create_project_media team: t, quote: 'claim b', channel: { main: CheckChannels::ChannelCodes::ZAPIER }, disable_es_callbacks: false
      # tipline items
      pm5 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }, disable_es_callbacks: false
      pm6 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::MESSENGER }, disable_es_callbacks: false
      pm7 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::TWITTER }, disable_es_callbacks: false
      pm8 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::TELEGRAM }, disable_es_callbacks: false
      pm9 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::VIBER }, disable_es_callbacks: false
      pm10 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::LINE }, disable_es_callbacks: false
      tipline_ids = [pm5.id, pm6.id, pm7.id, pm8.id, pm9.id, pm10.id]
      sleep 2
      # Hit PG
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MANUAL] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::API] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
      # Hit ES
      results = CheckSearch.new({ keyword: 'claim', channels: [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::API] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      # filter by any tipline
      results = CheckSearch.new({ channels: ['any_tipline'] }.to_json)
      assert_equal tipline_ids, results.medias.map(&:id).sort
      results = CheckSearch.new({ channels: ['any_tipline', CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::TWITTER] }.to_json)
      assert_equal tipline_ids.concat([pm.id]).sort, results.medias.map(&:id).sort
    end
  end

  test "should filter items by channel in main and others" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, quote: 'claim a', channel: { main: CheckChannels::ChannelCodes::MANUAL }, disable_es_callbacks: false
      pm2 = create_project_media team: t, quote: 'claim b', channel: { main: CheckChannels::ChannelCodes::ZAPIER }, disable_es_callbacks: false
      # tipline items
      pm3 = create_project_media team: t, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }, disable_es_callbacks: false
      pm.channel = { main: CheckChannels::ChannelCodes::MANUAL, others: [CheckChannels::ChannelCodes::WHATSAPP, CheckChannels::ChannelCodes::MESSENGER] }
      pm.save!
      sleep 2
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MANUAL] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::WHATSAPP] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::WHATSAPP, CheckChannels::ChannelCodes::ZAPIER] }.to_json)
      assert_equal [pm.id, pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ channels: [CheckChannels::ChannelCodes::MESSENGER] }.to_json)
      assert_equal [pm.id], results.medias.map(&:id)
      # filter by any tipline
      results = CheckSearch.new({ channels: ['any_tipline'] }.to_json)
      assert_equal [pm.id, pm3.id], results.medias.map(&:id).sort
    end
  end

  # Please add new tests to test/controllers/elastic_search_8_test.rb
end
