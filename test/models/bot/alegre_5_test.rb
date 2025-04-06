require_relative '../../test_helper'

class Bot::Alegre5Test < ActiveSupport::TestCase
  def setup
    @team = create_team
    @pm1 = create_project_media team: @team
    @pm2 = create_project_media team: @team
    @ex1 = create_explainer team: @team
    @ex2 = create_explainer team: @team
  end

  def teardown
  end

  test "should rank results based on vector models rank when prioritizing matches" do
    pm_id_scores_array = [
      { score: 0.75, context: { 'team_id' => @team.id, 'project_media_id' => @pm1.id, 'has_custom_id' => true, 'field' => 'original_title', 'temporary_media' => false }, model: Bot::Alegre::FILIPINO_MODEL },
      { score: 0.85, context: { 'team_id' => @team.id, 'project_media_id' => @pm2.id, 'has_custom_id' => true, 'field' => 'original_title', 'temporary_media' => false }, model: Bot::Alegre::MEAN_TOKENS_MODEL }
    ]
    pm_id_scores_hash = {
      @pm1.id => {
        score: 0.75,
        context: { 'has_custom_id' => true, 'field' => 'original_description', 'project_media_id' => @pm1.id, 'temporary_media' => false, 'team_id' => @team.id },
        model: Bot::Alegre::FILIPINO_MODEL,
        source_field: 'original_description',
        target_field: 'original_description',
        relationship_type: { source: 'confirmed_sibling', target: 'confirmed_sibling' }
      },
      @pm2.id => {
        score: 0.85,
        context: { 'has_custom_id' => true, 'field' => 'original_description', 'project_media_id' => @pm2.id, 'temporary_media' => false, 'team_id' => @team.id },
        model: Bot::Alegre::MEAN_TOKENS_MODEL,
        source_field: 'original_description',
        target_field: 'original_description',
        relationship_type: { source: 'confirmed_sibling', target: 'confirmed_sibling' }
      }
    }

    assert_equal @pm1.id, Bot::Alegre.return_prioritized_matches(pm_id_scores_hash).first.first
    assert_equal @pm1.id, Bot::Alegre.return_prioritized_matches(pm_id_scores_array).first.dig(:context, 'project_media_id')
    assert_equal @pm1.id, Bot::Alegre.return_prioritized_matches(pm_id_scores_array.reverse).first.dig(:context, 'project_media_id')

    pm_id_scores_hash[@pm2.id][:model] = Bot::Alegre::OPENAI_ADA_MODEL
    pm_id_scores_array[1][:model] = Bot::Alegre::OPENAI_ADA_MODEL

    assert_equal @pm2.id, Bot::Alegre.return_prioritized_matches(pm_id_scores_hash).first.first
    assert_equal @pm2.id, Bot::Alegre.return_prioritized_matches(pm_id_scores_array).first.dig(:context, 'project_media_id')
    assert_equal @pm2.id, Bot::Alegre.return_prioritized_matches(pm_id_scores_array.reverse).first.dig(:context, 'project_media_id')
  end

  test "should rank results based on vector models rank when parsing fact-check search results" do
    results = {
      @pm1.id => {
        score: 0.75,
        context: { 'team_id' => @team.id, 'project_media_id' => @pm1.id, 'has_custom_id' => true, 'field' => 'claim_description_content|report_visual_card_title', 'temporary_media' => false, 'contexts_count' => 14 },
        model: Bot::Alegre::FILIPINO_MODEL
      },
      @pm2.id => {
        score: 0.85,
        context: { 'team_id' => @team.id, 'project_media_id' => @pm2.id, 'has_custom_id' => true, 'field' => 'claim_description_content|report_visual_card_title', 'temporary_media' => false, 'contexts_count' => 4 },
        model: Bot::Alegre::MEAN_TOKENS_MODEL
      }
    }

    assert_equal @pm1.id, Bot::Smooch.parse_search_results_from_alegre(results, 10, false).first.id

    results[@pm2.id][:model] = Bot::Alegre::OPENAI_ADA_MODEL

    assert_equal @pm2.id, Bot::Smooch.parse_search_results_from_alegre(results, 10, false).first.id
  end

  test "should rank results based on vector models rank when parsing explainer search results" do
    response = {
      'result' => [
        {
          'content_hash' => 'abc123',
          'doc_id' => 'xyz321',
          'context' => { 'type' => 'explainer', 'team_id' => @team.id, 'language' => 'en', 'explainer_id' => @ex1.id, 'paragraph' => 1 },
          'models' => [Bot::Alegre::FILIPINO_MODEL],
          'suppress_search_response' => true,
          'content' => 'Foo',
          'created_at' => '2025-04-05T01:59:08.010665',
          'language' => nil,
          'suppress_response' => false,
          'contexts' => [{ 'type' => 'explainer', 'team_id' => @team.id, 'language' => 'en', 'explainer_id' => @ex1.id, 'paragraph' => 1 }],
          'model' => Bot::Alegre::FILIPINO_MODEL,
          '_id' => 'qwe789',
          'id' => 'qwe789',
          'index' => 'alegre_similarity',
          '_score' => 0.75,
          'score' => 0.75
        },
        {
          'content_hash' => 'abc456',
          'doc_id' => 'xyz654',
          'context' => { 'type' => 'explainer', 'team_id' => @team.id, 'language' => 'en', 'explainer_id' => @ex2.id, 'paragraph' => 1 },
          'models' => [Bot::Alegre::MEAN_TOKENS_MODEL],
          'suppress_search_response' => true,
          'content' => 'Foo',
          'created_at' => '2025-04-04T01:59:08.010665',
          'language' => nil,
          'suppress_response' => false,
          'contexts' => [{ 'type' => 'explainer', 'team_id' => @team.id, 'language' => 'en', 'explainer_id' => @ex2.id, 'paragraph' => 1 }],
          'model' => Bot::Alegre::MEAN_TOKENS_MODEL,
          '_id' => 'qwe987',
          'id' => 'qwe987',
          'index' => 'alegre_similarity',
          '_score' => 0.85,
          'score' => 0.85
        }
      ]
    }

    assert_equal @ex1.id, Explainer.sort_similarity_search_results(response).first.dig('context', 'explainer_id')

    response['result'][1]['model'] = Bot::Alegre::OPENAI_ADA_MODEL
    response['result'][1]['models'] = [Bot::Alegre::OPENAI_ADA_MODEL]

    assert_equal @ex2.id, Explainer.sort_similarity_search_results(response).first.dig('context', 'explainer_id')
  end
end
