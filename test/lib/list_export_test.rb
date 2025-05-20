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

  test "should export media (including child media) CSV" do
    setup_elasticsearch
    t = create_team
    create_team_task team_id: t.id, fieldset: 'tasks'
    parent = create_project_media team: t, disable_es_callbacks: false
    child = create_project_media team: t, disable_es_callbacks: false
    create_relationship source_id: parent.id, target_id: child.id, relationship_type: Relationship.confirmed_type

    sleep 2 # Wait for indexing

    export = ListExport.new(:media, { show_similar: true }.to_json, t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, export.number_of_rows
    assert_equal 2, csv_content.size
  end

  test "should export media feed CSV" do
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

  test "should export fact-check feed CSV" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false

    pender_url = CheckConfig.get('pender_url_private')
    WebMock.stub_request(:get, /#{pender_url}/).to_return(body: '{}', status: 200)

    t = create_team
    2.times do
      pm = create_project_media team: t, disable_es_callbacks: false
      r = publish_report(pm, {}, nil, { language: 'en', use_visual_card: false })
      r = Dynamic.find(r.id)
      r.disable_es_callbacks = false
      r.set_fields = { state: 'published' }.to_json
      r.save!
    end
    ss = create_saved_search team: t
    f = create_feed team: t, data_points: [1], media_saved_search: ss, published: true

    sleep 2 # Wait for indexing

    export = ListExport.new(:media, { feed_id: f.id, feed_view: 'fact_check' }.to_json, t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, export.number_of_rows
    assert_equal 2, csv_content.size
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

  test "should export dashboard CSV" do
    t = create_team
    # tipline_dashboard
    export = ListExport.new(:tipline_dashboard, { period: "past_week", platform: "whatsapp", language: "en" }.to_json, t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 1, csv_content.size
    assert_equal 1, export.number_of_rows
    # articles_dashboard
    export = ListExport.new(:articles_dashboard, { period: "past_week", platform: "whatsapp", language: "en" }.to_json, t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 1, csv_content.size
    assert_equal 1, export.number_of_rows
  end

  test "should export articles CSV" do
    t = create_team
    create_explainer team: t
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    create_fact_check claim_description: cd

    export = ListExport.new(:articles, '{}', t.id)
    csv_url = export.generate_csv_and_send_email(create_user)
    response = Net::HTTP.get_response(URI(csv_url))
    assert_equal 200, response.code.to_i
    csv_content = CSV.parse(response.body, headers: true)
    assert_equal 2, csv_content.size
    assert_equal 2, export.number_of_rows
  end
end
