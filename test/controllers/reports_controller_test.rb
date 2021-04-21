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
    create_report_design_annotation_type
    authenticate_with_token @a
    create_dynamic_annotation annotation_type: 'report_design', set_fields: { state: 'published', options: [{ language: 'en', image: '' }] }.to_json, action: 'save', annotated: @pm
    pm = create_project_media team: @t, archived: 1
    pm2 = create_project_media team: @t, quote: random_string, media: nil
    pm3 = create_project_media team: @t
    create_dynamic_annotation annotation_type: 'report_design', set_fields: { state: 'paused', options: [{ language: 'en', image: '' }] }.to_json, action: 'save', annotated: pm3
    create_project_media team: @t

    Bot::Alegre.stubs(:request_api).returns({ 'result' => [from_alegre(@pm), from_alegre(pm), from_alegre(pm2), from_alegre(pm3)] })

    get :index
    assert_response :success
    assert_equal 5, json_response['data'].size
    assert_equal 5, json_response['meta']['record-count']

    get :index, filter: { similar_to_text: 'Test', similarity_threshold: 0.7, similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'], archived: 0, media_type: 'Link', report_state: 'published' }
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
