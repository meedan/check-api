require_relative '../test_helper'

class ClaimDescriptionTest < ActiveSupport::TestCase
  def setup
    super
    ClaimDescription.delete_all
  end

  test "should create claim description" do
    assert_difference 'ClaimDescription.count' do
      create_claim_description
    end
  end

  test "should have versions" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'admin'
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      with_current_user_and_team(u, t) do
        cd = nil
        fc = nil
        assert_difference 'PaperTrail::Version.count', 2 do
          cd = create_claim_description project_media: pm, user: u
          fc = create_fact_check claim_description: cd
        end
        cd.description = 'update description'
        cd.save!
        fc.title = 'update title'
        fc.save!
        # Remove FactCheck
        cd.project_media_id = nil
        cd.save!
        assert_equal 3, cd.versions.count
        assert_equal 2, fc.versions.count
        v_count = Version.from_partition(t.id).where(associated_type: 'ProjectMedia', associated_id: pm.id, item_type: ['ClaimDescription', 'FactCheck']).count
        assert_equal 5, v_count
        # Add existing FactCheck to another media
        cd.project_media_id = pm2.id
        cd.save!
        assert_equal 4, cd.versions.count
        assert_equal 2, fc.versions.count
        # Old item logs
        v_count = Version.from_partition(t.id).where(associated_type: 'ProjectMedia', associated_id: pm.id, item_type: ['ClaimDescription', 'FactCheck']).count
        assert_equal 2, v_count
        # New item logs
        v_count = Version.from_partition(t.id).where(associated_type: 'ProjectMedia', associated_id: pm2.id, item_type: ['ClaimDescription', 'FactCheck']).count
        assert_equal 4, v_count
      end
    end
  end

  test "should not create claim description without user" do
    assert_no_difference 'ClaimDescription.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_claim_description user: nil
      end
    end
  end

  test "should not create claim description without project media" do
    assert_no_difference 'ClaimDescription.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_claim_description project_media: nil
      end
    end
  end

  test "should belong to user" do
    u = create_user
    cd = create_claim_description user: u
    assert_equal u, cd.user
    assert_equal [cd], u.claim_descriptions
  end

  test "should belong to project media" do
    pm = create_project_media
    cd = create_claim_description project_media: pm
    assert_equal pm, cd.project_media
    assert_equal cd, pm.claim_description
    assert_equal [cd], pm.claim_descriptions
    assert_raises ActiveRecord::RecordInvalid do
      create_claim_description project_media: pm
    end
    cd = ClaimDescription.new
    cd.description = random_string,
    cd.context = random_string,
    cd.project_media = pm
    assert_raises ActiveRecord::NotNullViolation do
      cd.save(validate: false)
    end
  end

  test "should have a fact check" do
    cd = create_claim_description
    fc = create_fact_check claim_description: cd
    assert_equal fc, cd.fact_check
    assert_equal cd, fc.claim_description
    assert_equal [fc], cd.fact_checks
  end

  test "should not create a claim description if does not have permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media
    with_current_user_and_team(u, t) do
      assert_no_difference 'ClaimDescription.count' do
        assert_raises RuntimeError do
          create_claim_description user: u, project_media: pm
        end
      end
    end
  end

  test "should create a claim description if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      assert_difference 'ClaimDescription.count' do
        cd = create_claim_description user: u, project_media: pm
      end
    end
  end

  test "should create a claim description with context only if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      assert_difference 'ClaimDescription.count' do
        cd = create_claim_description user: u, project_media: pm, description: nil
      end
    end
  end

  test "should index text_fields" do
    setup_elasticsearch
    t = create_team
    u = create_user
    pm = create_project_media team: t, disable_es_callbacks: false
    cd = create_claim_description project_media: pm, description: 'description_text'
    result = $repository.find(get_es_id(pm))
    assert_equal 'description_text', result['claim_description_content']
  end

  test "should destroy a claim when destroy the item" do
    t = create_team
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    assert_nothing_raised do
      pm.destroy!
    end
  end

  test "should replace item when applying fact-check from blank media" do
    Sidekiq::Testing.inline!
    t = create_team
    pm1 = create_project_media team: t, media: create_claim_media, archived: CheckArchivedFlags::FlagCodes::FACTCHECK_IMPORT
    cd = create_claim_description project_media: pm1
    fc = create_fact_check claim_description: cd
    pm2 = create_project_media team: t
    cd.project_media = pm2
    assert_difference 'ProjectMedia.count', -1 do
      cd.save!
    end
    assert_nil ProjectMedia.find_by_id(pm1.id)
    assert_equal fc, pm2.fact_check
  end

  test "should pause report when removing fact-check" do
    Sidekiq::Testing.inline!
    t = create_team
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd

    publish_report(pm)
    assert_equal 'published', fc.reload.report_status
    assert_equal 'published', pm.report_status(true)

    cd.project_media = nil
    cd.save!
    assert_equal 'paused', fc.reload.report_status
    assert_equal 'paused', pm.report_status(true)
  end

  test "should get information from removed item" do
    pm = create_project_media
    cd = create_claim_description project_media: pm
    cd.project_media = nil
    cd.save!
    assert_equal pm, cd.project_media_was
  end

  test "should not attach to item if fact-check is in the trash" do
    t = create_team
    cd = create_claim_description team: t, project_media: nil
    fc = create_fact_check claim_description: cd, trashed: true
    pm = create_project_media team: t
    assert_raises ActiveRecord::RecordInvalid do
      cd = ClaimDescription.find(cd.id)
      cd.project_media = pm
      cd.save!
    end
  end

  test "should update status for main and related items when set project_media" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    smooch_bot = create_smooch_bot
    create_team_bot_installation team_id: t.id, user_id: smooch_bot.id
    pm = create_project_media team: t
    pm_child = create_project_media team: t
    create_relationship source_id: pm.id, target_id: pm_child.id, relationship_type: Relationship.confirmed_type
    assert_equal 'undetermined', pm.reload.status
    assert_equal 'undetermined', pm_child.reload.status
    # Create fact-check with verified status
    cd = create_claim_description team_id: t.id, project_media: nil
    fc = create_fact_check claim_description: cd, rating: 'verified'
    Sidekiq::Testing.inline! do
      cd.project_media = pm
      cd.save!
      assert_equal 'verified', pm.reload.status
      assert_equal 'verified', pm_child.reload.status
    end
  end
end
