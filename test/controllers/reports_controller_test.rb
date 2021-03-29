require_relative '../test_helper'

class ReportsControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::ReportsController.new
    super
    @a = create_api_key
    @t = create_team
    @pm = create_project_media team: @t
  end

  test "should return similar items" do
    authenticate_with_token @a

    Bot::Alegre.stubs(:request_api).returns({ 'result' => [{
      '_index' => 'alegre_similarity',
      '_type' => '_doc',
      '_id' => 'tMXj53UB36CYclMPXp14',
      '_score' => 0.9,
      '_source' => {
        'content' => 'Test',
        'context' => {
          'team_id' => @t.id.to_s,
          'field' => 'original_title',
          'project_media_id' => @pm.id.to_s
        }
      }
    }]})

    get :index, filter: { similar_to_text: 'Test', similarity_threshold: 0.7, similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'] }
    assert_response :success
    assert_equal 1, json_response['data'].size
    Bot::Alegre.unstub(:request_api)
  end

  test "should return empty set if error happens" do
    authenticate_with_token @a

    Bot::Alegre.stubs(:request_api).returns({ 'result' => [{
      '_index' => 'alegre_similarity',
      '_type' => '_doc',
      '_id' => 'tMXj53UB36CYclMPXp14',
      '_score' => 0.9,
      '_source' => {
        'content' => 'Test',
        'context' => {
          'team_id' => @t.id.to_s,
          'field' => 'original_title',
          'project_media_id' => @pm.id.to_s
        }
      }
    }]})

    get :index, filter: { similar_to_text: 'Test', similarity_threshold: [0.7], similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'] }
    assert_response :success
    assert_equal 0, json_response['data'].size
    Bot::Alegre.unstub(:request_api)
  end
end
