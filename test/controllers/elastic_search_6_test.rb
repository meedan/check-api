require_relative '../test_helper'

class ElasticSearch6Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should index and sort by most requested" do
    p = create_project

    pm1 = create_project_media project: p, disable_es_callbacks: false
    2.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm1, disable_es_callbacks: false }
    sleep 5

    pm2 = create_project_media project: p, disable_es_callbacks: false
    4.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, disable_es_callbacks: false }
    sleep 5

    pm3 = create_project_media project: p, disable_es_callbacks: false
    1.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm3, disable_es_callbacks: false }
    sleep 5

    pm4 = create_project_media project: p, disable_es_callbacks: false
    3.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm4, disable_es_callbacks: false }
    sleep 5

    order = [pm3, pm1, pm4, pm2]
    orders = {asc: order, desc: order.reverse}
    orders.keys.each do |order|
      search = {
        sort: [
          {
            'dynamics.smooch': {
              order: order,
              nested: {
                path: 'dynamics',
              }
            }
          }
        ],
        query: {
          match_all: {}
        }
      }
      pms = []
      MediaSearch.search(search).results.each do |r|
        pms << r.annotated_id if r.annotated_type == 'ProjectMedia'
      end
      assert_equal orders[order.to_sym].map(&:id), pms
    end
  end

  [:asc, :desc].each do |order|
    test "should filter and sort by most requested #{order}" do
      p = create_project

      query = { sort: 'smooch', sort_type: order.to_s }

      result = CheckSearch.new(query.to_json)
      assert_equal 0, result.medias.count

      pm1 = create_project_media project: p, disable_es_callbacks: false
      2.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm1, disable_es_callbacks: false }
      pm2 = create_project_media project: p, disable_es_callbacks: false
      4.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, disable_es_callbacks: false }
      pm3 = create_project_media project: p, disable_es_callbacks: false
      1.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm3, disable_es_callbacks: false }
      pm4 = create_project_media project: p, disable_es_callbacks: false
      3.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm4, disable_es_callbacks: false }
      pm5 = create_project_media project: p, disable_es_callbacks: false
      sleep 5

      orders = {asc: [pm3, pm1, pm4, pm2, pm5], desc: [pm2, pm4, pm1, pm3, pm5]}
      result = CheckSearch.new(query.to_json)
      assert_equal 5, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
    end
  end

  test "should decrease elasticsearch smooch when annotations is removed" do
    p = create_project
    pm = create_project_media project: p, disable_es_callbacks: false
    s1 = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, disable_es_callbacks: false
    s2 = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, disable_es_callbacks: false
    sleep 3

    result = MediaSearch.find(get_es_id(pm))
    assert_equal [2], result['dynamics'].select { |d| d.has_key?('smooch')}.map { |s| s['smooch']}
    s1.destroy
    sleep 1

    result = MediaSearch.find(get_es_id(pm))
    assert_equal [1], result['dynamics'].select { |d| d.has_key?('smooch')}.map { |s| s['smooch']}
  end

  [:created_at, :updated_at].each do |field|
    test "should filter by #{field} range" do
      p = create_project

      to = Time.new(2019, 05, 21, 14, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {end_time: to}, timezone: "GMT"}}

      query[:range][field][:start_time] = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")
      result = CheckSearch.new(query.to_json)
      assert_equal 0, result.medias.count

      Time.stubs(:now).returns(Time.new(2019, 05, 19, 13, 00))
      pm1 = create_project_media project: p, quote: 'Test A', disable_es_callbacks: false
      sleep 5

      Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
      pm2 = create_project_media project: p, quote: 'Test B', disable_es_callbacks: false
      sleep 5

      Time.stubs(:now).returns(Time.new(2019, 05, 21, 13, 00))
      pm3 = create_project_media project: p, quote: 'Test C', disable_es_callbacks: false
      sleep 5

      Time.unstub(:now)

      mapping = {
        'GMT': {
          "#{Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")}": [pm1.id, pm2.id, pm3.id],
          "#{Time.new(2019, 05, 20, 12, 01).strftime("%Y-%m-%d %H:%M")}": [pm2.id, pm3.id],
          "#{Time.new(2019, 05, 21, 12, 01).strftime("%Y-%m-%d %H:%M")}": [pm3.id]
        },
        'America/Bahia': {
          "#{Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")}": [pm2.id, pm3.id],
          "#{Time.new(2019, 05, 20, 12, 01).strftime("%Y-%m-%d %H:%M")}": [pm3.id],
          "#{Time.new(2019, 05, 21, 12, 01).strftime("%Y-%m-%d %H:%M")}": []
        }
      }

      # query on PG
      mapping.each_pair do |timezone, start_dates|
        query[:range][:timezone] = timezone
        start_dates.each do |from, items|
          query[:range][field][:start_time] = from
          result = CheckSearch.new(query.to_json)
          assert_equal items.sort, result.medias.map(&:id).sort
        end
      end

      # query on ES
      query[:keyword] = 'Test'
      mapping.each_pair do |timezone, start_dates|
        query[:range][:timezone] = timezone
        start_dates.each do |from, items|
          query[:range][field][:start_time] = from
          result = CheckSearch.new(query.to_json)
          assert_equal items.sort, result.medias.map(&:id).sort
        end
      end
    end
  end

  [:created_at, :updated_at].each do |field|
    test "should handle inputs when filter by #{field} range" do
      p = create_project

      Time.stubs(:now).returns(Time.new(2019, 05, 19, 13, 00))
      pm1 = create_project_media project: p, disable_es_callbacks: false
      sleep 5

      Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
      pm2 = create_project_media project: p, disable_es_callbacks: false
      sleep 5
      Time.unstub(:now)

      # Missing start_time, end_time and timezone
      query = { range: {"#{field}": {}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing timezone
      from = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")
      to = Time.new(2019, 05, 20, 14, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {start_time: from, end_time: to}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {start_time: from, end_time: to}, timezone: ''}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing start_time and end_time
      query = { range: {"#{field}": {}, timezone: 'GMT'}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {start_time: '', end_time: ''}, timezone: 'GMT'}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing start_time
      to = Time.new(2019, 05, 20, 14, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {start_time: '', end_time: to}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {end_time: to}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing end_time
      from = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {start_time: from, end_time: ''}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {start_time: from}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Wrong date format
      from = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d")
      to = Time.new(2019, 05, 20, 14, 01).strftime("%Y-%m-%dT%H:%M")
      query = { range: {"#{field}": {start_time: from, end_time: to}}}
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
    end
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
