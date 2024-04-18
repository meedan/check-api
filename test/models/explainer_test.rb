require_relative '../test_helper'

class ExplainerTest < ActiveSupport::TestCase
  def setup
    super
    Explainer.delete_all
  end

  test "should create explainer" do
    assert_difference 'Explainer.count' do
      create_explainer
    end
  end

  test "should have versions" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'admin'
      pm = create_project_media team: t
      with_current_user_and_team(u, t) do
        ex = nil
        assert_difference 'PaperTrail::Version.count', 1 do
          ex = create_explainer user: u, team: t
        end
        assert_equal 1, ex.versions.count
      end
    end
  end

  test "should not create explainer without user or team" do
    assert_no_difference 'Explainer.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_explainer user: nil
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_explainer team: nil
      end
    end
  end

  test "should belong to user and team" do
    u = create_user
    t = create_team
    ex = create_explainer user: u, team: t
    assert_equal u, ex.user
    assert_equal t, ex.team
  end

  test "should not create an explainer if does not have permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    with_current_user_and_team(u, t) do
      assert_no_difference 'Explainer.count' do
        assert_raises RuntimeError do
          create_explainer team: create_team
        end
      end
    end
  end

  test "should create an explainer if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    with_current_user_and_team(u, t) do
      assert_difference 'Explainer.count' do
        create_explainer team: t
      end
    end
  end

  test "should tag explainer" do
    ex = create_explainer
    tag = create_tag annotated: ex
    assert_equal [tag], ex.annotations('tag')
  end
end
