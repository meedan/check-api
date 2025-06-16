require_relative '../test_helper'

class ReportsControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::ReportsController.new
    super
    @a = create_api_key
    @t = create_team
    @pm = create_project_media team: @t
    @f = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.png'), 'image/png')
    @m = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.mp4'), 'video/mp4')
  end

  def from_alegre(pm)
    {
      'index' => 'alegre_similarity',
      '_id' => 'tMXj53UB36CYclMPXp14',
      'id' => 'tMXj53UB36CYclMPXp14',
      'score' => 0.9,
      'content' => 'Test',
      'context' => {
        'team_id' => pm.team_id.to_s,
        'field' => 'original_title',
        'project_media_id' => pm.id.to_s
      }
    }
  end

  test "should return similar items" do
    create_report_design_annotation_type
    authenticate_with_token @a
    create_dynamic_annotation annotation_type: 'report_design', set_fields: { state: 'published', options: { language: 'en', image: '' } }.to_json, action: 'save', annotated: @pm
    pm = create_project_media team: @t, archived: 1
    pm2 = create_project_media team: @t, quote: random_string
    pm3 = create_project_media team: @t
    create_dynamic_annotation annotation_type: 'report_design', set_fields: { state: 'paused', options: { language: 'en', image: '' } }.to_json, action: 'save', annotated: pm3
    pm4 = create_project_media team: @t
    pm5 = create_project_media team: @t, media: create_uploaded_video
    create_project_media team: @t

    Bot::Alegre.stubs(:get_items_with_similar_media_v2).returns({
      @pm.id => {
        score: 1.0,
        context: {"team_id" => @pm.team_id, "project_media_id" => @pm.id, "temporary_media" => false},
        model: Bot::Alegre.get_type(@pm),
        source_field: Bot::Alegre.get_type(@pm),
        target_field: Bot::Alegre.get_type(@pm),
        relationship_type: {:source=>"confirmed_sibling", :target=>"confirmed_sibling"}
      },
      pm.id => {
        score: 1.0,
        context: {"team_id" => pm.team_id, "project_media_id" => pm.id, "temporary_media" => false},
        model: Bot::Alegre.get_type(pm),
        source_field: Bot::Alegre.get_type(pm),
        target_field: Bot::Alegre.get_type(pm),
        relationship_type: {:source=>"confirmed_sibling", :target=>"confirmed_sibling"}
      },
      pm2.id => {
        score: 1.0,
        context: {"team_id" => pm2.team_id, "project_media_id" => pm2.id, "temporary_media" => false},
        model: Bot::Alegre.get_type(pm2),
        source_field: Bot::Alegre.get_type(pm2),
        target_field: Bot::Alegre.get_type(pm2),
        relationship_type: {:source=>"confirmed_sibling", :target=>"confirmed_sibling"}
      },
      pm3.id => {
        score: 1.0,
        context: {"team_id" => pm3.team_id, "project_media_id" => pm3.id, "temporary_media" => false},
        model: Bot::Alegre.get_type(pm3),
        source_field: Bot::Alegre.get_type(pm3),
        target_field: Bot::Alegre.get_type(pm3),
        relationship_type: {:source=>"confirmed_sibling", :target=>"confirmed_sibling"}
      },
      pm4.id => {
        score: 1.0,
        context: {"team_id" => pm4.team_id, "project_media_id" => pm4.id, "temporary_media" => false},
        model: Bot::Alegre.get_type(pm4),
        source_field: Bot::Alegre.get_type(pm4),
        target_field: Bot::Alegre.get_type(pm4),
        relationship_type: {:source=>"confirmed_sibling", :target=>"confirmed_sibling"}
      },
      pm5.id => {
        score: 1.0,
        context: {"team_id" => pm5.team_id, "project_media_id" => pm5.id, "temporary_media" => false},
        model: Bot::Alegre.get_type(pm5),
        source_field: Bot::Alegre.get_type(pm5),
        target_field: Bot::Alegre.get_type(pm5),
        relationship_type: {:source=>"confirmed_sibling", :target=>"confirmed_sibling"}
      },
    })
    post :index, params: {}
    assert_response :success
    assert_equal 7, json_response['data'].size
    assert_equal 7, json_response['meta']['record-count']

    post :index, params: { filter: { similar_to_text: 'Test', similar_to_image: @f, similar_to_video: @m, similarity_threshold: 0.7, similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'], archived: 0, media_type: 'Link', report_state: 'published' } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 1, json_response['meta']['record-count']

    post :index, params: { filter: { similar_to_text: 'Test', similar_to_image: @f, similar_to_video: @m, similarity_threshold: 0.7, similarity_organization_ids: [@t.id], similarity_fields: ['original_title', 'analysis_title'], archived: 0, media_type: 'Link', report_state: 'unpublished' } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 1, json_response['meta']['record-count']
    
    Bot::Alegre.unstub(:request)
  end

  test "should return empty set if Alegre doesn't return anything" do
    create_report_design_annotation_type
    authenticate_with_token @a
    3.times { create_project_media(team: @t) }

    Bot::Alegre.stubs(:request).returns({ 'result' => [] })

    get :index, params: { filter: { similar_to_text: 'Test' } }
    assert_response :success
    assert_equal 0, json_response['data'].size
    assert_equal 0, json_response['meta']['record-count']

    Bot::Alegre.unstub(:request)
  end

  test "should return empty set if Alegre Bot is not installed" do
    create_report_design_annotation_type
    authenticate_with_token create_api_key
    3.times { create_project_media }
    TeamBotInstallation.delete_all
    BotUser.delete_all
    Bot::Alegre.stubs(:request).returns({ 'result' => [] })

    get :index, params: { filter: { similar_to_text: 'Test' } }
    assert_response :success
    assert_equal 0, json_response['data'].size
    assert_equal 0, json_response['meta']['record-count']

    Bot::Alegre.unstub(:request)
  end
end
