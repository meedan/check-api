require_relative '../test_helper'

class ClaimDescriptionTest < ActiveSupport::TestCase
  def setup
    super
    ClaimDescription.delete_all
  end

  test "should create claim description" do
    assert_difference 'ClaimDescription.count' do
      create_claim_description
    end
  end

  test "should have versions" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      cd = nil
      assert_difference 'PaperTrail::Version.count', 1 do
        cd = create_claim_description project_media: pm, user: u
      end
      assert_equal 1, cd.versions.count
    end
  end

  test "should not create claim description without user" do
    assert_no_difference 'ClaimDescription.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_claim_description user: nil
      end
    end
  end

  test "should not create claim description without project media" do
    assert_no_difference 'ClaimDescription.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_claim_description project_media: nil
      end
    end
  end

  test "should belong to user" do
    u = create_user
    cd = create_claim_description user: u
    assert_equal u, cd.user
    assert_equal [cd], u.claim_descriptions
  end

  test "should belong to project media" do
    pm = create_project_media
    cd = create_claim_description project_media: pm
    assert_equal pm, cd.project_media
    assert_equal cd, pm.claim_description
    assert_equal [cd], pm.claim_descriptions
  end

  test "should have a fact check" do
    cd = create_claim_description
    fc = create_fact_check claim_description: cd
    assert_equal fc, cd.fact_check
    assert_equal cd, fc.claim_description
    assert_equal [fc], cd.fact_checks
  end

  test "should not create a claim description if does not have permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media
    with_current_user_and_team(u, t) do
      assert_no_difference 'ClaimDescription.count' do
        assert_raises RuntimeError do
          create_claim_description user: u, project_media: pm
        end
      end
    end
  end

  test "should create a claim description if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      assert_difference 'ClaimDescription.count' do
        cd = create_claim_description user: u, project_media: pm
      end
    end
  end

  test "should create a claim description with context only if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      assert_difference 'ClaimDescription.count' do
        cd = create_claim_description user: u, project_media: pm, description: nil
      end
    end
  end

  test "should index text_fields" do
    setup_elasticsearch
    t = create_team
    u = create_user
    pm = create_project_media team: t, disable_es_callbacks: false
    cd = create_claim_description project_media: pm, description: 'description_text'
    result = $repository.find(get_es_id(pm))
    assert_equal 'description_text', result['claim_description_content']
  end

  test "should destroy a claim when destroy the item" do
    t = create_team
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    assert_nothing_raised do
      pm.destroy!
    end
  end
end
