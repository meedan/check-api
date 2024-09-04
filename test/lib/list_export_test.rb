require_relative '../test_helper'

class ListExportTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  test "should expire the export" do
    t = create_team
    create_team_task team_id: t.id, fieldset: 'tasks'
    pm = create_project_media team: t

    stub_configs({ 'export_csv_expire' => 2 }) do
      # Generate a CSV with the two exported items
      export = ListExport.new(:media, '{}', t.id)
      csv_url = export.generate_csv_and_send_email(create_user)
      response = Net::HTTP.get_response(URI(csv_url))
      assert_equal 200, response.code.to_i

      # Make sure it expires after 2 seconds
      sleep 3 # Just to be safe
      response = Net::HTTP.get_response(URI(csv_url))
      assert_equal 403, response.code.to_i
    end
  end

  test "should export media CSV" do
    t = create_team
    create_team_task team_id: t.id, fieldset: 'tasks'
    2.times { create_project_media team: t }

    export = ListExport.new(:media, '{}', t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, csv_content.size
    assert_equal 2, export.number_of_rows
  end

  test "should export feed CSV" do
    t = create_team
    f = create_feed team: t
    2.times { f.clusters << create_cluster }

    export = ListExport.new(:feed, { feed_id: f.id }.to_json, t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, csv_content.size
    assert_equal 2, export.number_of_rows
  end

  test "should export fact-checks CSV" do
    t = create_team
    2.times do
      pm = create_project_media team: t
      cd = create_claim_description project_media: pm
      create_fact_check claim_description: cd
    end

    export = ListExport.new(:fact_check, '{}', t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, csv_content.size
    assert_equal 2, export.number_of_rows
  end

  test "should export explainers CSV" do
    t = create_team
    2.times { create_explainer team: t }

    export = ListExport.new(:explainer, '{}', t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, csv_content.size
    assert_equal 2, export.number_of_rows
  end
end
