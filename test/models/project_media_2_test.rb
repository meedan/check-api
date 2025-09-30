require_relative '../test_helper'

class ProjectMedia2Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should cache number of linked items" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      pm = create_project_media team: t
      assert_queries(0, '=') { assert_equal(1, pm.linked_items_count) }
      pm2 = create_project_media team: t
      assert_queries(0, '=') { assert_equal(1, pm2.linked_items_count) }
      create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
      assert_queries(0, '=') { assert_equal(2, pm.linked_items_count) }
      assert_queries(0, '=') { assert_equal(1, pm2.linked_items_count) }
      pm3 = create_project_media team: t
      assert_queries(0, '=') { assert_equal(1, pm3.linked_items_count) }
      r = create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
      assert_queries(0, '=') { assert_equal(3, pm.linked_items_count) }
      assert_queries(0, '=') { assert_equal(1, pm2.linked_items_count) }
      assert_queries(0, '=') { assert_equal(1, pm3.linked_items_count) }
      r.destroy!
      assert_queries(0, '=') { assert_equal(2, pm.linked_items_count) }
      assert_queries(0, '=') { assert_equal(1, pm2.linked_items_count) }
      assert_queries(0, '=') { assert_equal(1, pm3.linked_items_count) }
      assert_queries(0, '>') { assert_equal(2, pm.linked_items_count(true)) }
    end
  end

  test "should cache show warning cover" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      team = create_team
      pm = create_project_media team: team
      assert_not pm.show_warning_cover
      flag = create_flag annotated: pm
      flag.set_fields = { show_cover: true }.to_json
      flag.save!
      assert pm.show_warning_cover
      puts "Data :: #{pm.show_warning_cover}"
      assert_queries(0, '=') { assert_equal(true, pm.show_warning_cover) }
      assert_queries(0, '>') { assert_equal(true, pm.show_warning_cover(true)) }
    end
  end

  test "should cache status" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      pm = create_project_media
      assert pm.respond_to?(:status)
      assert_queries 0, '=' do
        assert_equal 'undetermined', pm.status
      end
      s = pm.last_verification_status_obj
      s.status = 'verified'
      s.save!
      assert_queries 0, '=' do
        assert_equal 'verified', pm.status
      end
      assert_queries(0, '>') do
        assert_equal 'verified', pm.status(true)
      end
    end
  end

  test "should cache title" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      pm = create_project_media quote: 'Title 0'
      assert_equal 'Title 0', pm.title
      Bot::Alegre.stubs(:send_field_to_similarity_index).returns({"success": true})
      cd = create_claim_description project_media: pm, description: 'Title 1'
      assert_queries 0, '=' do
        assert_equal 'Title 1', pm.title
      end
      create_fact_check claim_description: cd, title: 'Title 2'
      assert_queries 0, '=' do
        assert_equal 'Title 1', pm.title
      end
      assert_queries(0, '>') do
        assert_equal 'Title 1', pm.reload.title(true)
      end
      Bot::Alegre.unstub(:send_field_to_similarity_index)
    end
  end

  test "should cache title for imported items" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      create_team_user team: t, user: u, role: 'admin'
      with_current_user_and_team(u, t) do
        pm = ProjectMedia.create!(
          media: create_claim_media,
          team: t,
          user: u,
          channel: { main: CheckChannels::ChannelCodes::FETCH }
        )
        cd = ClaimDescription.new
        cd.skip_check_ability = true
        cd.project_media = pm
        cd.description = '-'
        cd.user = u
        cd.save!
        fc_summary = 'fc_summary'
        fc_title = 'fc_title'
        fc = FactCheck.new
        fc.claim_description = cd
        fc.title = fc_title
        fc.summary = fc_summary
        fc.user = u
        fc.skip_report_update = true
        fc.save!
        assert_equal fc_title, pm.title
        assert_equal fc_summary, pm.description
      end
    end
  end

  test "should cache description" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      pm = create_project_media quote: 'Description 0'
      assert_equal 'Description 0', pm.description
      cd = create_claim_description description: 'Description 1', project_media: pm
      assert_queries 0, '=' do
        assert_equal 'Description 1', pm.description
      end
      create_fact_check claim_description: cd, summary: 'Description 2'
      assert_queries 0, '=' do
        assert_equal 'Description 1', pm.description
      end
      assert_queries(0, '>') do
        assert_equal 'Description 1', pm.reload.description(true)
      end
    end
  end

  test "should index sortable fields" do
    RequestStore.store[:skip_cached_field_update] = false
    # sortable fields are [linked_items_count, and last_seen]
    setup_elasticsearch
    Rails.stubs(:env).returns('development'.inquiry)
    team = create_team
    pm = create_project_media team: team, disable_es_callbacks: false
    result = $repository.find(get_es_id(pm))
    assert_equal 1, result['linked_items_count']
    assert_equal pm.created_at.to_i, result['last_seen']
    assert_equal pm.reload.last_seen, pm.read_attribute(:last_seen)
    t = t0 = create_tipline_request(team_id: team.id, associated: pm).created_at.to_i
    result = $repository.find(get_es_id(pm))
    assert_equal t, result['last_seen']
    assert_equal pm.reload.last_seen, pm.read_attribute(:last_seen)

    pm2 = create_project_media team: team, disable_es_callbacks: false
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    t = pm2.created_at.to_i
    result = $repository.find(get_es_id(pm))
    result2 = $repository.find(get_es_id(pm2))
    assert_equal 2, result['linked_items_count']
    assert_equal 1, result2['linked_items_count']
    assert_equal t, result['last_seen']
    assert_equal pm.reload.last_seen, pm.read_attribute(:last_seen)

    t = create_tipline_request(team_id: team.id, associated: pm2).created_at.to_i
    result = $repository.find(get_es_id(pm))
    assert_equal t, result['last_seen']
    assert_equal pm.reload.last_seen, pm.read_attribute(:last_seen)

    r.destroy!
    result = $repository.find(get_es_id(pm))
    assert_equal t0, result['last_seen']
    assert_equal pm.reload.last_seen, pm.read_attribute(:last_seen)
    result = $repository.find(get_es_id(pm))
    result2 = $repository.find(get_es_id(pm2))
    assert_equal 1, result['linked_items_count']
    assert_equal 1, result2['linked_items_count']
  end

  test "should get team" do
    t = create_team
    pm = create_project_media team: t
    assert_equal t, pm.reload.team
    t2 = create_team
    pm.team = t2
    assert_equal t2, pm.team
    assert_equal t, ProjectMedia.find(pm.id).team
  end

  test "should cache last_seen value" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      team = create_team
      pm = create_project_media team: team
      t0 = pm.created_at.to_i
      # pm.last_seen should equal pm.created_at if no tipline request (aka 'smooch' annotation)
      assert_queries(0, '=') { assert_equal(t0, pm.last_seen) }
      t1 = create_tipline_request(team_id: team.id, associated: pm).created_at.to_i
      # pm.last_seen should equal pm tipline request created_at if item is not related
      assert_queries(0, '=') { assert_equal(t1, pm.last_seen) }
      pm2 = create_project_media team: team
      t2 = pm2.created_at.to_i
      # pm2.last_seen should equal pm2.created_at if no tipline request (aka 'smooch' annotation)
      assert_queries(0, '=') { assert_equal(t2, pm2.last_seen) }
      r1 = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
      # pm is now a parent and pm2 its child with no smooch annotation, so pm.last_seen should match pm2.created_at
      assert_queries(0, '=') { assert_equal(t2, pm.last_seen) }
      # adding a smooch annotation to pm2 should update parent last_seen
      t3 = create_tipline_request(team_id: team.id, associated: pm2).created_at.to_i
      assert_queries(0, '=') { assert_equal(t3, pm.last_seen) }
      # now let's add a second child pm3...
      pm3 = create_project_media team: team
      t4 = create_tipline_request(team_id: team.id, associated: pm3).created_at.to_i
      r2 = create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
      # pm3.last_seen should equal pm3 smooch annotation created_at
      assert_queries(0, '=') { assert_equal(t4, pm3.last_seen) }
      assert_queries(0, '>') { assert_equal(t4, pm3.last_seen(true)) }
      # last_seen for each child item should be smooch annotation created_at of that single item
      assert_queries(0, '=') { assert_equal(t3, pm2.last_seen) }
      assert_queries(0, '>') { assert_equal(t3, pm2.last_seen(true)) }
      r1.destroy!
      r2.destroy!
      # last_seen of former parent should be restored to smooch annotation created_at after relationship is destroyed
      assert_queries(0, '=') { assert_equal(t1, pm.last_seen) }
      assert_queries(0, '>') { assert_equal(t1, pm.last_seen(true)) }
      # last_seen of former child should be unchanged after relationship is destroyed
      assert_queries(0, '=') { assert_equal(t3, pm2.last_seen) }
      assert_queries(0, '>') { assert_equal(t3, pm2.last_seen(true)) }
    end
  end

end
