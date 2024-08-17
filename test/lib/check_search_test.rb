require_relative '../test_helper'

class CheckSearchTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "should export CSV" do
    t = create_team
    create_team_task team_id: t.id, fieldset: 'tasks'
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    csv = CheckSearch.export_to_csv('{}', t.id)
    assert File.exist?(csv)
    assert_equal 3, File.readlines(csv).size # One line is for the header
  end
end
