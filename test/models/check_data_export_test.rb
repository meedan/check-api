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

  test "should regenerate download url" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    s3_url = random_url
    short_url = Shortener::ShortenedUrl.generate!(s3_url)
    download_url = CheckConfig.get('short_url_host') + '/' + short_url.unique_key
    stub_configs({ 'check_sunset_download_expire_days' => 15, 'check_sunset_s3_max_expire_days' => 7 }) do
      Sidekiq::Testing.fake! do
        Sidekiq::Worker.clear_all
        assert_equal 0, CheckDataExportWorker.jobs.size
        current_time = Time.current
        download_expire_days = CheckConfig.get('check_sunset_download_expire_days', 15, :integer)
        expired_at = current_time + download_expire_days.days
        de = create_check_data_export team: t, user: u, download_url: download_url, generated_at: current_time, expired_at: expired_at, auto_extend_url_expiry: true
        assert_equal 1, CheckDataExportWorker.jobs.size
        travel_to(current_time + 7.days) do
          new_url = random_url
          CheckS3.stubs(:presigned_url).returns(new_url)
          # Run existing background job should trigger another job and set auto_extend_url_expiry = true
          CheckDataExportWorker.perform_one
          assert de.reload.auto_extend_url_expiry
          assert_equal new_url, short_url.reload.url
          assert_equal 1, CheckDataExportWorker.jobs.size
        end
        travel_to(current_time + 14.days) do
           new_url = random_url
          CheckS3.stubs(:presigned_url).returns(new_url)
          # Run existing background job should not trigger another job and set auto_extend_url_expiry = false
          CheckDataExportWorker.perform_one
          assert_not de.reload.auto_extend_url_expiry
          assert_equal new_url, short_url.reload.url
          assert_equal 0, CheckDataExportWorker.jobs.size
        end
      end
    end
  end
end
