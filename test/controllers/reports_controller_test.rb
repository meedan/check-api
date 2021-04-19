require_relative '../test_helper'

class ReportsControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::ReportsController.new
    super
    @a = create_api_key
    @t = create_team
    @pm = create_project_media team: @t
  end

  def from_alegre(pm)
    {
      '_index' => 'alegre_similarity',
      '_type' => '_doc',
      '_id' => 'tMXj53UB36CYclMPXp14',
      '_score' => 0.9,
      '_source' => {
        'content' => 'Test',
        'context' => {
          'team_id' => pm.team_id.to_s,
          'field' => 'original_title',
          'project_media_id' => pm.id.to_s
        }
      }
    }
  end

  test "should return similar items" do
    authenticate_with_token @a
    pm = create_project_media team: @t, archived: 1
    pm2 = create_project_media team: @t, quote: random_string, media: nil
    create_project_media team: @t

    Bot::Alegre.stubs(:request_api).returns({ 'result' => [from_alegre(@pm), from_alegre(pm), from_alegre(pm2)] })

    get :index
    assert_response :success
    assert_equal 4, json_response['data'].size
    assert_equal 4, json_response['meta']['record-count']

    get :index, filter: { similar_to_text: 'Test', similarity_threshold: 0.7, similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'], archived: 0, media_type: 'Link' }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 1, json_response['meta']['record-count']
    
    Bot::Alegre.unstub(:request_api)
  end

  test "should return empty set if error happens" do
    authenticate_with_token @a

    Bot::Alegre.stubs(:request_api).returns({ 'result' => [from_alegre(@pm)]})

    get :index, filter: { similar_to_text: 'Test', similarity_threshold: [0.7], similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'] }
    assert_response :success
    assert_equal 0, json_response['data'].size
    Bot::Alegre.unstub(:request_api)
  end
end
