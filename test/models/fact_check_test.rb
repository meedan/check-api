require_relative '../test_helper'

class FactCheckTest < ActiveSupport::TestCase
  def setup
    super
    FactCheck.delete_all
  end

  test "should create fact check" do
    assert_difference 'FactCheck.count' do
      create_fact_check
    end
  end

  test "should have versions" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm, user: u
    with_current_user_and_team(u, t) do
      fc = nil
      assert_difference 'PaperTrail::Version.count', 1 do
        fc = create_fact_check claim_description: cd, user: u
      end
      assert_equal 1, fc.versions.count
    end
  end

  test "should create fact check without optional fields" do
    assert_difference 'FactCheck.count' do
      create_fact_check url: nil, title: nil, summary: nil
    end
  end

  test "should not create fact check without user" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check user: nil
      end
    end
  end

  test "should not create fact check without claim description" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check claim_description: nil
      end
    end
  end

  test "should belong to user" do
    u = create_user
    fc = create_fact_check user: u
    assert_equal u, fc.user
    assert_equal [fc], u.fact_checks
  end

  test "should belong to claim description" do
    cd = create_claim_description
    fc = create_fact_check claim_description: cd
    assert_equal cd, fc.claim_description
    assert_equal fc, cd.fact_check
  end

  test "should provide a valid URL" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check url: random_string
      end
    end
  end

  test "should set default language" do
    fc = create_fact_check
    assert_equal 'en', fc.language
    fc = create_fact_check language: 'ar'
    assert_equal 'ar', fc.language
  end

  test "should not create a fact check if does not have permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media
    cd = create_claim_description project_media: pm
    with_current_user_and_team(u, t) do
      assert_no_difference 'FactCheck.count' do
        assert_raises RuntimeError do
          create_fact_check claim_description: cd, user: u
        end
      end
    end
  end

  test "should create a fact check if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    with_current_user_and_team(u, t) do
      assert_difference 'FactCheck.count' do
        create_fact_check claim_description: cd, user: u
      end
    end
  end

  test "should index text fields" do
    setup_elasticsearch
    t = create_team
    u = create_user
    pm = create_project_media team: t, disable_es_callbacks: false
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd, user: u, summary: 'summary_text', title: 'title_text'
    result = $repository.find(get_es_id(pm))
    assert_equal 'summary_text', result['fact_check_summary']
    assert_equal 'title_text', result['fact_check_title']
  end

  test "should keep report and fact-check in sync when text report is created and updated" do
    create_report_design_annotation_type
    u = create_user is_admin: true
    pm = create_project_media
    create_claim_description project_media: pm
    assert_nil pm.reload.fact_check_title
    assert_nil pm.reload.fact_check_summary
    assert_nil pm.reload.published_url

    d = create_dynamic_annotation annotation_type: 'report_design', annotator: u, annotated: pm, set_fields: { options: [{ language: 'en', use_text_message: true, title: 'Text report created title', text: 'Text report created summary', published_article_url: 'http://text.report/created' }] }.to_json, action: 'save'
    assert_equal 'Text report created title', pm.reload.fact_check_title
    assert_equal 'Text report created summary', pm.reload.fact_check_summary
    assert_equal 'http://text.report/created', pm.reload.published_url

    d = Dynamic.find(d.id)
    d.set_fields = { options: [{ language: 'en', use_text_message: true, title: 'Text report updated title', text: 'Text report updated summary', published_article_url: 'http://text.report/updated' }] }.to_json
    d.action = 'publish'
    d.save!
    assert_equal 'Text report updated title', pm.reload.fact_check_title
    assert_equal 'Text report updated summary', pm.reload.fact_check_summary
    assert_equal 'http://text.report/updated', pm.reload.published_url
  end

  test "should keep report and fact-check in sync when image report is created and updated" do
    create_report_design_annotation_type
    u = create_user is_admin: true
    pm = create_project_media
    create_claim_description project_media: pm
    assert_nil pm.reload.fact_check_title
    assert_nil pm.reload.fact_check_summary
    assert_nil pm.reload.published_url

    d = create_dynamic_annotation annotation_type: 'report_design', annotator: u, annotated: pm, set_fields: { options: [{ language: 'en', use_visual_card: true, headline: 'Image report created title', description: 'Image report created summary' }] }.to_json, action: 'save'
    assert_equal 'Image report created title', pm.reload.fact_check_title
    assert_equal 'Image report created summary', pm.reload.fact_check_summary
    assert_nil pm.reload.published_url

    d = Dynamic.find(d.id)
    d.set_fields = { options: [{ language: 'en', use_visual_card: true, headline: 'Image report updated title', description: 'Image report updated summary' }] }.to_json
    d.action = 'publish'
    d.save!
    assert_equal 'Image report updated title', pm.reload.fact_check_title
    assert_equal 'Image report updated summary', pm.reload.fact_check_summary
    assert_nil pm.reload.published_url
  end

  test "should keep report and fact-check in sync when fact-check is created and updated" do
    create_report_design_annotation_type
    u = create_user is_admin: true
    pm = create_project_media
    cd = create_claim_description project_media: pm
    assert_nil pm.get_dynamic_annotation('report_design')

    fc = create_fact_check title: 'Created fact-check title', summary: 'Created fact-check summary', url: 'http://fact.check/created', user: u, claim_description: cd
    r = pm.reload.get_dynamic_annotation('report_design')
    assert_equal 'Created fact-check title', r.report_design_field_value('title')
    assert_equal 'Created fact-check title', r.report_design_field_value('headline')
    assert_equal 'Created fact-check summary', r.report_design_field_value('text')
    assert_equal 'Created fact-check summary', r.report_design_field_value('description')
    assert_equal 'http://fact.check/created', r.report_design_field_value('published_article_url')

    fc = FactCheck.find(fc.id)
    fc.title = 'Updated fact-check title'
    fc.summary = 'Updated fact-check summary'
    fc.url = 'http://fact.check/updated'
    fc.save!
    r = pm.get_dynamic_annotation('report_design')
    assert_equal 'Updated fact-check title', r.report_design_field_value('title')
    assert_equal 'Updated fact-check title', r.report_design_field_value('headline')
    assert_equal 'Updated fact-check summary', r.report_design_field_value('text')
    assert_equal 'Updated fact-check summary', r.report_design_field_value('description')
    assert_equal 'http://fact.check/updated', r.report_design_field_value('published_article_url')
  end
end
