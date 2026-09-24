require "test_helper"

class CheckDataExportTest < ActiveSupport::TestCase
  test "should create data export" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    assert_difference 'CheckDataExport.count' do
      create_check_data_export team: t, user: u
    end
  end

  test "Should set team and user" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    assert_no_difference 'CheckDataExport.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_check_data_export team: nil
      end
    end
    assert_no_difference 'CheckDataExport.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_check_data_export user: nil
      end
    end
    with_current_user_and_team(u, t) do
      de = nil
      assert_difference 'CheckDataExport.count' do
        de = create_check_data_export team: t, user: u
      end
      assert_equal u.id, de.user_id
      assert_equal t.id, de.team_id
    end
  end

  test "should validate status" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    de = create_check_data_export user: u, team: t
    assert_equal 'requested', de.status
    assert_raises(ArgumentError) do
      de.status = 'unknown'
      de.save!
    end
    de.status = 'generated'
    de.save!
    assert_equal 'generated', de.reload.status
  end

  test "should not duplicate team" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_check_data_export team: t, user: u
    assert_no_difference 'CheckDataExport.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_check_data_export team: t, user: u
      end
    end
  end

  test "should be an admin member in team" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'editor'
    assert_no_difference 'CheckDataExport.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_check_data_export team: t, user: u
      end
    end
  end

  test "read ability for CheckDataExport" do
    u = create_user
    t = create_team
    u2 = create_user
    tu = create_team_user user: u , team: t, role: 'admin'
    create_team_user user: u2 , team: t, role: 'admin'
    de = create_check_data_export team: t, user: u, expired_at: Time.current + 7.days
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.can?(:read, de)
      de.expired_at = Time.current - 7.days
      de.save!
      assert ability.cannot?(:read, de)
    end
    with_current_user_and_team(u2, t) do
      ability = Ability.new
      assert ability.cannot?(:read, de)
    end
    tu.role = 'editor'
    tu.save!
    with_current_user_and_team(u, t) do
      ability = Ability.new
      assert ability.cannot?(:read, de)
    end
  end

  test "should send download notification" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    de = create_check_data_export team: t, user: u, status: 'requested'
    with_current_user_and_team(u, t) do
      de.status = 'generated'
      de.save!
    end
  end
end
