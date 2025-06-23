require_relative '../test_helper'

class ElasticSearch6Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  [:created_at, :updated_at, :last_seen].each do |field|
    test "should filter by #{field} range" do
      RequestStore.store[:skip_cached_field_update] = false
      t = create_team

      to = Time.new(2019, 05, 21, 14, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {end_time: to}, timezone: "GMT"}}

      query[:range][field][:start_time] = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 0, result.medias.count

      Time.stubs(:now).returns(Time.new(2019, 05, 19, 13, 00))
      pm1 = create_project_media team: t, quote: 'Test A', disable_es_callbacks: false
      sleep 2

      Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
      pm2 = create_project_media team: t, quote: 'Test B', disable_es_callbacks: false
      sleep 2

      Time.stubs(:now).returns(Time.new(2019, 05, 21, 13, 00))
      pm3 = create_project_media team: t, quote: 'Test C', disable_es_callbacks: false
      sleep 2

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
          result = CheckSearch.new(query.to_json, nil, t.id)
          assert_equal items.sort, result.medias.map(&:id).sort
        end
      end

      # query on ES
      query[:keyword] = 'Test'
      mapping.each_pair do |timezone, start_dates|
        query[:range][:timezone] = timezone
        start_dates.each do |from, items|
          query[:range][field][:start_time] = from
          result = CheckSearch.new(query.to_json, nil, t.id)
          assert_equal items.sort, result.medias.map(&:id).sort
        end
      end
    end
  end

  [:created_at, :updated_at, :last_seen].each do |field|
    test "should handle inputs when filter by #{field} range" do
      RequestStore.store[:skip_cached_field_update] = false
      t = create_team

      Time.stubs(:now).returns(Time.new(2019, 05, 19, 13, 00))
      pm1 = create_project_media team: t, quote: 'claim a', disable_es_callbacks: false
      sleep 2

      Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
      pm2 = create_project_media team: t, quote: 'claim b', disable_es_callbacks: false
      sleep 2
      Time.unstub(:now)

      # Missing start_time, end_time and timezone
      # PG
      query = { range: {"#{field}": {}}}
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing timezone
      from = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")
      to = Time.new(2019, 05, 20, 14, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {start_time: from, end_time: to}}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {start_time: from, end_time: to}, timezone: ''}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing start_time and end_time
      query = { range: {"#{field}": {}, timezone: 'GMT'}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {start_time: '', end_time: ''}, timezone: 'GMT'}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing start_time
      to = Time.new(2019, 05, 20, 14, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {start_time: '', end_time: to}}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {end_time: to}}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Missing end_time
      from = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d %H:%M")
      query = { range: {"#{field}": {start_time: from, end_time: ''}}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      query = { range: {"#{field}": {start_time: from}}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort

      # Wrong date format
      from = Time.new(2019, 05, 19, 12, 01).strftime("%Y-%m-%d")
      to = Time.new(2019, 05, 20, 14, 01).strftime("%Y-%m-%dT%H:%M")
      query = { range: {"#{field}": {start_time: from, end_time: to}}}
      # PG
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
      # ES
      query[:keyword] = 'claim'
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal [pm1.id, pm2.id].sort, result.medias.map(&:id).sort
    end
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
