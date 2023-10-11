require_relative '../test_helper'
require 'error_codes'
require 'sidekiq/testing'

class GraphqlController11Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    TestDynamicAnnotationTables.load!
  end

  def teardown
  end

  test "should set Smooch user Slack channel URL in background" do
    Sidekiq::Worker.clear_all
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    author_id = random_string
    set_fields = { smooch_user_data: { id: author_id }.to_json, smooch_user_app_id: 'fake', smooch_user_id: 'fake' }.to_json
    d = create_dynamic_annotation annotated: p, annotation_type: 'smooch_user', set_fields: set_fields
    authenticate_with_token
    url = random_url
    query = 'mutation { updateDynamicAnnotationSmoochUser(input: { clientMutationId: "1", id: "' + d.graphql_id + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url + '\"}" }) { project { dbid } } }'

    Sidekiq::Testing.fake! do
      post :create, params: { query: query }
      assert_response :success
    end
    Sidekiq::Worker.drain_all
    assert_equal url, Dynamic.find(d.id).get_field_value('smooch_user_slack_channel_url')

    # Check that cache key exists
    key = "SmoochUserSlackChannelUrl:Team:#{d.team_id}:#{author_id}"
    assert_equal url, Rails.cache.read(key)

    # Test using a new mutation `smoochBotAddSlackChannelUrl`
    url2 = random_url
    query = 'mutation { smoochBotAddSlackChannelUrl(input: { clientMutationId: "1", id: "' + d.id.to_s + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url2 + '\"}" }) { annotation { dbid } } }'
    Sidekiq::Testing.fake! do
      post :create, params: { query: query }
      assert_response :success
    end
    assert Sidekiq::Worker.jobs.size > 0
    assert_equal url, d.reload.get_field_value('smooch_user_slack_channel_url')

    # Execute job and check that URL was set
    Sidekiq::Worker.drain_all
    assert_equal url2, d.get_field_value('smooch_user_slack_channel_url')

    # Check that cache key exists
    assert_equal url2, Rails.cache.read(key)

    # Call mutation with non existing ID
    query = 'mutation { smoochBotAddSlackChannelUrl(input: { clientMutationId: "1", id: "99999", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url2 + '\"}" }) { annotation { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
  end
end
