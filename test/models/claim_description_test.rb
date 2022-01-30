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

  test "should not create claim description without description" do
    assert_no_difference 'ClaimDescription.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_claim_description description: nil
      end
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
  end

  test "should have a fact check" do
    cd = create_claim_description
    fc = create_fact_check claim_description: cd
    assert_equal fc, cd.fact_check
    assert_equal cd, fc.claim_description
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
        create_claim_description user: u, project_media: pm
      end
    end
  end
end
