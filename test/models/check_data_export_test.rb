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

  test "Should set team and CheckDataExport" do
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
end
