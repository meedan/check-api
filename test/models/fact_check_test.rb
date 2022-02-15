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

  test "should not create fact check without summary" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check summary: nil
      end
    end
  end

  test "should create fact check without url" do
    assert_difference 'FactCheck.count' do
      create_fact_check url: nil
    end
  end

  test "should not create fact check without title" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check title: nil
      end
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

  test "should index text_fields" do
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
end
