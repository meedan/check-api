require_relative '../test_helper'

class RelevantResultsItemTest < ActiveSupport::TestCase
  test "should record user selection for relevant articles" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    pm1 = create_project_media quote: 'Foo Bar', team: t
    pm2 = create_project_media quote: 'Foo Bar Test', team: t
    pm3 = create_project_media quote: 'Foo Bar Test Testing', team: t
    ex1 = create_explainer language: 'en', team: t, title: 'Foo Bar'
    ex2 = create_explainer language: 'en', team: t, title: 'Foo Bar Test'
    ex3 = create_explainer language: 'en', team: t, title: 'Foo Bar Test Testing'
    pm1.explainers << ex1
    pm2.explainers << ex2
    pm3.explainers << ex3
    ex_ids = [ex1.id, ex2.id, ex3.id]
    Bot::Smooch.stubs(:search_for_explainers).returns(Explainer.where(id: ex_ids))
    fact_checks = []
    [pm1, pm2, pm3].each do |pm|
      cd = create_claim_description description: pm.title, project_media: pm
      fc = create_fact_check claim_description: cd, title: pm.title
      fact_checks << fc.id
    end
    [pm1, pm2].each { |pm| publish_report(pm) }
    sleep 1
    fact_checks.delete(pm1.fact_check_id)
    expected_result = fact_checks.concat([ex2.id, ex3.id]).sort
    assert_equal expected_result, pm1.get_similar_articles.map(&:id).sort
    with_current_user_and_team(u, t) do
      # Assign explainer to item
      assert_not_nil Rails.cache.read("relevant-items-#{pm1.id}")
      create_explainer_item explainer: ex2, project_media: pm1
      assert_equal 2, RelevantResultsItem.where(query_media_parent_id: pm1.id, article_type: 'Explainer').count
      assert_nil Rails.cache.read("relevant-items-#{pm1.id}")
      pm1.get_similar_articles.map(&:id).sort
      assert_not_nil Rails.cache.read("relevant-items-#{pm1.id}")
      cd = ClaimDescription.where(project_media_id: pm1.id).last
      cd.project_media = create_project_media team: t
      cd.save!
      cd = ClaimDescription.where.not(project_media_id: pm1.id).last
      cd.project_media_id = pm1.id
      cd.save!
      assert_equal 2, RelevantResultsItem.where(query_media_parent_id: pm1.id, article_type: 'FactCheck').count
      # Verify selected item
      fc = cd.fact_check
      selected_item = RelevantResultsItem.where(query_media_parent_id: pm1.id, article_type: 'FactCheck', article_id: fc.id).last
      assert_equal fc, selected_item.article
      assert_nil Rails.cache.read("relevant-items-#{pm1.id}")
    end
    Bot::Smooch.unstub(:search_for_explainers)
  end
end
