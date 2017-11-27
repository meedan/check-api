require_relative '../test_helper'

class TeamSourceTest < ActiveSupport::TestCase
  
  test "should create team source" do
  	assert_difference 'TeamSource.count' do
      create_team_source
    end
  end

   test "should set user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source
    with_current_user_and_team(u, t) do
      ts = create_team_source team: t, source: s
      assert_equal u, ts.user
    end
  end

  test "should have a team and source" do
    assert_no_difference 'TeamSource.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_team_source team: nil
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_team_source source: nil
      end
    end
  end

  test "should not create duplicated source per team" do
  	t = create_team
    s = create_source
    create_team_source team: t, source: s
    assert_raises ActiveRecord::RecordInvalid do
      create_team_source team: t, source: s
    end
    assert_difference 'TeamSource.count' do
      create_team_source team: create_team, source: s
  	end
  end

  test "should have annotations" do
    ts = create_team_source
    c1 = create_comment annotated: ts
    c2 = create_comment annotated: ts
    c3 = create_comment annotated: nil
    assert_equal [c1.id, c2.id].sort, ts.reload.annotations.map(&:id).sort
  end

  test "should not create source under trashed team" do
    t = create_team
    t.archived = true
    t.save!
    s = create_source

    assert_raises ActiveRecord::RecordInvalid do
      create_team_source team: t, source: s
    end
  end

end
