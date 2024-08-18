require_relative '../test_helper'

class CheckSearchTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "should export CSV and expire it" do
    t = create_team
    create_team_task team_id: t.id, fieldset: 'tasks'
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t

    stub_configs({ 'export_csv_expire' => 2 }) do

      # Generate a CSV with the two exported items
      csv_url = CheckSearch.export_to_csv('{}', t.id)
      response = Net::HTTP.get_response(URI(csv_url))
      assert_equal 200, response.code.to_i
      csv_content = CSV.parse(response.body, headers: true)
      assert_equal 2, csv_content.size

      # Make sure it expires after 2 seconds
      sleep 3 # Just to be safe
      response = Net::HTTP.get_response(URI(csv_url))
      assert_equal 403, response.code.to_i
    end
  end
end
