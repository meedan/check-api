require_relative '../test_helper'

class FactCheckTest < ActiveSupport::TestCase
  def setup
    super
    FactCheck.delete_all
  end

  test "should create fact check" do
    assert_difference 'FactCheck.count' do
      create_fact_check
    end
  end

  test "should have versions" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'admin'
      pm = create_project_media team: t
      cd = create_claim_description project_media: pm, user: u
      with_current_user_and_team(u, t) do
        fc = nil
        assert_difference 'PaperTrail::Version.count', 1 do
          fc = create_fact_check claim_description: cd, user: u
        end
        assert_equal 1, fc.versions.count
      end
    end
  end

  test "should create fact check without optional fields" do
    Bot::Alegre.stubs(:send_field_to_similarity_index).returns({"success": true})
    assert_difference 'FactCheck.count' do
      create_fact_check url: nil, title: random_string, summary: nil
    end
    Bot::Alegre.unstub(:send_field_to_similarity_index)
  end

  test "should not create fact check without user" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check user: nil
      end
    end
  end

  test "should not create fact check without claim description" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check claim_description: nil
      end
    end
  end

  test "should belong to user" do
    u = create_user
    fc = create_fact_check user: u
    assert_equal u, fc.user
    assert_equal [fc], u.fact_checks
  end

  test "should belong to claim description" do
    cd = create_claim_description
    fc = create_fact_check claim_description: cd
    assert_equal cd, fc.claim_description
    assert_equal fc, cd.fact_check
    assert_raises ActiveRecord::RecordInvalid do
      create_fact_check claim_description: cd
    end
    fc = FactCheck.new
    fc.summary = random_string
    fc.url = random_url
    fc.title = random_string
    fc.claim_description = cd
    assert_raises ActiveRecord::NotNullViolation do
      fc.save(validate: false)
    end
  end

  test "should provide a valid URL" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check url: random_string
      end
    end
  end

  test "should set default language" do
    setup_elasticsearch
    fc = create_fact_check
    assert_equal 'en', fc.language
    t = create_team
    t.set_language = 'fr'
    t.set_languages(['fr'])
    t.save!
    pm = create_project_media team: t, disable_es_callbacks: false
    cd = create_claim_description project_media: pm, disable_es_callbacks: false
    fc = create_fact_check claim_description: cd, disable_es_callbacks: false
    assert_equal 'fr', fc.language
    result = $repository.find(get_es_id(pm))
    assert_equal ['fr'], result['fact_check_languages']
    # Validate language
    assert_raises ActiveRecord::RecordInvalid do
      create_fact_check claim_description: cd, language: 'en'
    end
    # should set language `und` when workspace has more than one language
    t.set_languages(['en', 'fr'])
    t.save!
    pm = create_project_media team: t, disable_es_callbacks: false
    cd = create_claim_description project_media: pm, disable_es_callbacks: false
    fc = create_fact_check claim_description: cd, disable_es_callbacks: false
    assert_equal 'und', fc.language
    result = $repository.find(get_es_id(pm))
    assert_equal ['und'], result['fact_check_languages']
    # update language
    fc.language = 'en'
    fc.disable_es_callbacks = false
    fc.save!
    result = $repository.find(get_es_id(pm))
    assert_equal ['en'], result['fact_check_languages']
    # delete fact check
    fc.disable_es_callbacks = false
    fc.destroy!
    result = $repository.find(get_es_id(pm))
    assert_equal [], result['fact_check_languages']
  end

  test "should not create a fact check if does not have permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media
    cd = create_claim_description project_media: pm
    with_current_user_and_team(u, t) do
      assert_no_difference 'FactCheck.count' do
        assert_raises RuntimeError do
          create_fact_check claim_description: cd, user: u
        end
      end
    end
  end

  test "should create a fact check if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    with_current_user_and_team(u, t) do
      assert_difference 'FactCheck.count' do
        create_fact_check claim_description: cd, user: u
      end
    end
  end

  test "should index text fields" do
    setup_elasticsearch
    t = create_team
    u = create_user
    pm = create_project_media team: t, disable_es_callbacks: false
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd, user: u, summary: 'summary_text', title: 'title_text'
    result = $repository.find(get_es_id(pm))
    assert_equal 'summary_text', result['fact_check_summary']
    assert_equal 'title_text', result['fact_check_title']
  end

  test "should keep report and fact-check in sync when text report is created and updated" do
    RequestStore.store[:skip_cached_field_update] = false
    create_report_design_annotation_type
    Sidekiq::Testing.inline! do
      u = create_user is_admin: true
      t = create_team
      t.set_languages = ['en', 'fr']
      t.save!
      pm = create_project_media team: t
      cd = create_claim_description project_media: pm
      assert_nil pm.reload.fact_check_title
      assert_nil pm.reload.fact_check_summary
      assert_nil pm.reload.published_url

      d = create_dynamic_annotation annotation_type: 'report_design', annotator: u, annotated: pm, set_fields: { options: { language: 'en', use_text_message: true, title: 'Text report created title', text: 'Text report created summary', published_article_url: 'http://text.report/created' } }.to_json, action: 'save'
      fc = cd.reload.fact_check
      assert_equal 'Text report created title', pm.reload.fact_check_title
      assert_equal 'Text report created summary', pm.reload.fact_check_summary
      assert_equal 'http://text.report/created', pm.reload.published_url
      assert_equal 'en', fc.reload.language

      d = Dynamic.find(d.id)
      d.set_fields = { options: { language: 'fr', use_text_message: true, title: 'Text report updated title', text: 'Text report updated summary', published_article_url: 'http://text.report/updated' } }.to_json
      d.action = 'publish'
      d.save!
      assert_equal 'Text report updated title', pm.reload.fact_check_title
      assert_equal 'Text report updated summary', pm.reload.fact_check_summary
      assert_equal 'http://text.report/updated', pm.reload.published_url
      assert_equal 'fr', fc.reload.language
    end
  end

  test "should keep report and fact-check in sync when image report is created and updated" do
    RequestStore.store[:skip_cached_field_update] = false
    create_report_design_annotation_type
    Sidekiq::Testing.inline! do
      u = create_user is_admin: true
      pm = create_project_media
      create_claim_description project_media: pm
      assert_nil pm.reload.fact_check_title
      assert_nil pm.reload.fact_check_summary
      assert_nil pm.reload.published_url

      d = create_dynamic_annotation annotation_type: 'report_design', annotator: u, annotated: pm, set_fields: { options: { language: 'en', use_visual_card: true, headline: 'Image report created title', description: 'Image report created summary' } }.to_json, action: 'save'
      assert_equal 'Image report created title', pm.reload.fact_check_title
      assert_equal 'Image report created summary', pm.reload.fact_check_summary
      assert_nil pm.reload.published_url

      d = Dynamic.find(d.id)
      d.set_fields = { options: { language: 'en', use_visual_card: true, headline: 'Image report updated title', description: 'Image report updated summary' } }.to_json
      d.action = 'publish'
      d.save!
      assert_equal 'Image report updated title', pm.reload.fact_check_title
      assert_equal 'Image report updated summary', pm.reload.fact_check_summary
      assert_nil pm.reload.published_url
    end
  end

  test "should keep report and fact-check in sync when fact-check is created and updated" do
    create_report_design_annotation_type
    t = create_team
    t.set_languages = ['en', 'fr']
    t.save!
    u = create_user is_admin: true
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    assert_nil pm.get_dynamic_annotation('report_design')

    fc = create_fact_check language: 'en', title: 'Created fact-check title', summary: 'Created fact-check summary', url: 'http://fact.check/created', user: u, claim_description: cd
    r = pm.reload.get_dynamic_annotation('report_design')
    assert_equal 'Created fact-check title', r.report_design_field_value('title')
    assert_equal 'Created fact-check title', r.report_design_field_value('headline')
    assert_equal 'Created fact-check summary', r.report_design_field_value('text')
    assert_equal 'Created fact-check summary', r.report_design_field_value('description')
    assert_equal 'http://fact.check/created', r.report_design_field_value('published_article_url')
    assert_equal 'en', r.report_design_field_value('language')

    fc = FactCheck.find(fc.id)
    fc.title = 'Updated fact-check title'
    fc.summary = 'Updated fact-check summary'
    fc.url = 'http://fact.check/updated'
    fc.language = 'fr'
    fc.save!
    r = pm.get_dynamic_annotation('report_design')
    assert_equal 'Updated fact-check title', r.report_design_field_value('title')
    assert_equal 'Updated fact-check title', r.report_design_field_value('headline')
    assert_equal 'Updated fact-check summary', r.report_design_field_value('text')
    assert_equal 'Updated fact-check summary', r.report_design_field_value('description')
    assert_equal 'http://fact.check/updated', r.report_design_field_value('published_article_url')
    assert_equal 'fr', r.report_design_field_value('language')
  end

  test "should save fact-check for audio" do
    create_report_design_annotation_type
    a = create_uploaded_audio
    pm = create_project_media media: a
    cd = create_claim_description project_media: pm
    assert_nothing_raised do
      create_fact_check claim_description: cd
    end
  end

  test "should validate title or summary exist" do
    fc = create_fact_check
    assert_nothing_raised do
      fc.title = ''
      fc.save!
    end
    assert_empty fc.reload.title
    assert_raises ActiveRecord::RecordInvalid do
      fc.summary = ''
      fc.save!
    end
    assert_not_empty fc.reload.summary
    fc.title = random_string
    fc.save!
    assert_nothing_raised do
      fc.summary = ''
      fc.save!
    end
    assert_empty fc.reload.summary
    assert_raises ActiveRecord::RecordInvalid do
      fc.title = ''
      fc.save!
    end
    assert_not_empty fc.reload.title
  end

  test "should validate rating" do
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check rating: 'invalid_status'
      end
    end
    assert_difference 'FactCheck.count' do
      create_fact_check rating: 'verified'
    end
    # Validate custom status
    t = create_team
    value = {
      label: 'Status',
      default: 'stop',
      active: 'done',
      statuses: [
        { id: 'stop', label: 'Stopped', completed: '', description: 'Not started yet', style: { backgroundColor: '#a00' } },
        { id: 'done', label: 'Done!', completed: '', description: 'Nothing left to be done here', style: { backgroundColor: '#fc3' } }
      ]
    }
    t.send :set_media_verification_statuses, value
    t.save!
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    assert_no_difference 'FactCheck.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_fact_check claim_description: cd, rating: 'invalid_status'
      end
    end
    allowed_statuses = t.reload.verification_statuses('media', nil)['statuses'].collect{|s| s[:id]}
    assert_difference 'FactCheck.count' do
      create_fact_check claim_description: cd, rating: 'stop'
    end
  end

  test "should create many fact-checks without signature" do
    assert_difference 'FactCheck.count', 2 do
      create_fact_check signature: nil
      create_fact_check signature: nil
    end
  end

  test "should not create fact-checks with the same signature" do
    create_fact_check signature: 'test'
    assert_raises ActiveRecord::RecordNotUnique do
      create_fact_check signature: 'test'
    end
  end

  test "should set report status correctly when fact-check is updated" do
    RequestStore.store[:skip_cached_field_update] = false
    create_report_design_annotation_type
    Sidekiq::Testing.inline! do
      pm = create_project_media
      cd = create_claim_description project_media: pm
      assert_equal 'unpublished', pm.reload.report_status

      fc = create_fact_check claim_description: cd
      assert_equal 'unpublished', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.save!
      assert_equal 'unpublished', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.save!
      assert_equal 'unpublished', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.publish_report = true
      fc.save!
      assert_equal 'published', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.save!
      assert_equal 'published', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.publish_report = false
      fc.save!
      assert_equal 'paused', pm.reload.report_status

      pm = create_project_media
      cd = create_claim_description project_media: pm
      fc = create_fact_check claim_description: cd, publish_report: true
      assert_equal 'published', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.save!
      assert_equal 'published', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.publish_report = false
      fc.save!
      assert_equal 'paused', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.save!
      assert_equal 'paused', pm.reload.report_status

      fc = FactCheck.find(fc.id)
      fc.title = random_string
      fc.publish_report = true
      fc.save!
      assert_equal 'published', pm.reload.report_status
    end
  end

  test "should index report information in fact check" do
    create_verification_status_stuff
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      with_current_user_and_team(u, t) do
        pm = create_project_media team: t
        cd = create_claim_description project_media: pm
        s = pm.last_verification_status_obj
        s.status = 'verified'
        s.save!
        r = publish_report(pm)
        fc = cd.reload.fact_check
        fc.title = 'Foo Bar'
        fc.save!
        fc = fc.reload
        assert_equal u.id, fc.publisher_id
        assert_equal 'published', fc.report_status
        assert_equal 'verified', fc.rating
        # Verify fact-checks filter
        filters = { publisher_ids: [u.id] }
        assert_equal [fc.id], t.filtered_fact_checks(filters).map(&:id)
        filters = { rating: ['verified'] }
        assert_equal [fc.id], t.filtered_fact_checks(filters).map(&:id)
        filters = { report_status: ['published'] }
        assert_equal [fc.id], t.filtered_fact_checks(filters).map(&:id)
        filters = { publisher_ids: [u.id], rating: ['verified'], report_status: ['published'] }
        assert_equal [fc.id], t.filtered_fact_checks(filters).map(&:id)
        r = Dynamic.find(r.id)
        r.set_fields = { state: 'paused' }.to_json
        r.action = 'pause'
        r.save!
        fc = fc.reload
        assert_nil fc.publisher_id
        assert_equal 'paused', fc.report_status
        assert_equal 'verified', fc.rating
        s.status = 'in_progress'
        s.save!
        assert_equal 'in_progress', fc.reload.rating
        # Verify fact-checks filter
        filters = { publisher_ids: [u.id] }
        assert_empty t.filtered_fact_checks(filters).map(&:id)
        filters = { rating: ['verified'] }
        assert_empty t.filtered_fact_checks(filters).map(&:id)
        filters = { report_status: ['published'] }
        assert_empty t.filtered_fact_checks(filters).map(&:id)
        filters = { rating: ['in_progress'], report_status: ['paused'] }
        assert_equal [fc.id], t.filtered_fact_checks(filters).map(&:id)
        # Verify text filter
        filters = { text: 'Test' }
        assert_empty t.filtered_fact_checks(filters).map(&:id)
        filters = { text: 'Foo' }
        assert_equal [fc.id], t.filtered_fact_checks(filters).map(&:id)
        # Update item status based on factcheck rating
        fc.rating = 'verified'
        fc.save!
        s = pm.reload.last_verification_status_obj
        assert_equal 'verified', s.status
      end
    end
  end

  test "should set fact-check as imported" do
    assert !create_fact_check(user: create_user).imported
    assert create_fact_check(user: create_bot_user).imported
  end

  test "should set initial rating" do
    create_verification_status_stuff

    # Test core statuses first
    t = create_team
    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd
    assert_equal 'undetermined', fc.reload.rating
    fc.rating = 'in_progress'
    fc.save!
    assert_equal 'in_progress', pm.reload.last_status

    # Test custom statuses now
    t = create_team
    value = {
      "label": "Custom Status Label",
      "active": "in_progress",
      "default": "new",
      "statuses": [
        {
          "id": "new",
          "style": {
            "color": "blue"
          },
          "locales": {
            "en": {
              "label": "New",
              "description": "An item that did not start yet"
            },
            "pt": {
              "label": "Novo",
              "description": "Um item que ainda não começou a ser verificado"
            }
          }
        },
        {
          "id": "in_progress",
          "style": {
            "color": "yellow"
          },
          "locales": {
            "en": {
              "label": "Working on it",
              "description": "We are working on it"
            },
            "pt": {
              "label": "Estamos trabalhando nisso",
              "description": "Estamos trabalhando nisso"
            }
          }
        }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!

    pm = create_project_media team: t
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd
    assert_equal 'new', fc.reload.rating
    fc.rating = 'in_progress'
    fc.save!
    assert_equal 'in_progress', pm.reload.last_status
  end

  test "should have team" do
    fc = create_fact_check
    assert_not_nil fc.team
  end

  test "should unpublish report when fact-check is sent to the trash" do
    Sidekiq::Testing.fake!
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media
    cd = create_claim_description(project_media: pm)
    fc = create_fact_check claim_description: cd
    r = publish_report(pm)
    assert_equal pm, cd.reload.project_media
    assert_equal 'published', pm.reload.report_status
    assert_equal 'published', fc.reload.report_status
    assert_equal 'published', r.reload.data['state']

    fc = FactCheck.find(fc.id)
    fc.trashed = true
    fc.save!

    assert_nil cd.reload.project_media
    assert_equal 'paused', pm.reload.report_status
    assert_equal 'paused', fc.reload.report_status
    assert_equal 'paused', r.reload.data['state']

    fc = FactCheck.find(fc.id)
    fc.trashed = false
    fc.save!

    assert_nil cd.reload.project_media
    assert_equal 'paused', pm.reload.report_status
    assert_equal 'paused', fc.reload.report_status
    assert_equal 'paused', r.reload.data['state']
  end

  test "should delete after days in the trash" do
    pm = create_project_media
    cd = create_claim_description(project_media: pm)
    fc = create_fact_check claim_description: cd
    Sidekiq::Testing.inline! do
      assert_no_difference 'ProjectMedia.count' do
        assert_difference 'FactCheck.count', -1 do
          assert_difference 'ClaimDescription.count', -1 do
            fc = FactCheck.find(fc.id)
            fc.trashed = true
            fc.save!
          end
        end
      end
    end
  end

  test "should not have duplicate tags" do
    pm = create_project_media
    cd = create_claim_description(project_media: pm)
    fc = create_fact_check claim_description: cd, tags: ['one', 'one', '#one']

    assert_equal 1, fc.tags.count
    assert_equal 'one', fc.tags.first
  end

  test "should add existing tag to a new fact check" do
    pm = create_project_media
    cd = create_claim_description(project_media: pm)
    create_fact_check claim_description: cd, tags: ['one']

    pm2 = create_project_media
    cd2 = create_claim_description(project_media: pm2)
    fc2 = create_fact_check claim_description: cd2, tags: ['#one']

    assert_equal 1, fc2.tags.count
    assert_equal 'one', fc2.tags.first
  end

  test "should move item to default core status when fact-check is removed from it" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    Sidekiq::Testing.inline! do
      pm = create_project_media
      assert_equal 'undetermined', pm.reload.status
      cd = create_claim_description(project_media: pm)
      fc = create_fact_check claim_description: cd, rating: 'false'
      assert_equal 'false', pm.reload.status
      cd.project_media = nil
      cd.save!
      assert_equal 'undetermined', pm.reload.status
    end
  end

  test "should move item to default custom status when fact-check is removed from it" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    t = create_team
    custom_statuses = {
      "label": "Custom Status Label",
      "active": "in_progress",
      "default": "unstarted",
      "statuses": [
        {
          "id": "unstarted",
          "style": {
            "color": "blue"
          },
          "locales": {
            "en": {
              "label": "Unstarted",
              "description": "An item that did not start yet"
            },
            "pt": {
              "label": "Não iniciado ainda",
              "description": "Um item que ainda não começou a ser verificado"
            }
          }
        },
        {
          "id": "in_progress",
          "style": {
            "color": "yellow"
          },
          "locales": {
            "en": {
              "label": "Working on it",
              "description": "We are working on it"
            },
            "pt": {
              "label": "Estamos trabalhando nisso",
              "description": "Estamos trabalhando nisso"
            }
          }
        }
      ]
    }
    t.set_media_verification_statuses(custom_statuses)
    t.save!
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t
      assert_equal 'unstarted', pm.reload.status
      cd = create_claim_description(project_media: pm)
      fc = create_fact_check claim_description: cd, rating: 'in_progress'
      assert_equal 'in_progress', pm.reload.status
      cd.project_media = nil
      cd.save!
      assert_equal 'unstarted', pm.reload.status
    end
  end

  test "should reset report when fact-check is detached" do
    RequestStore.store[:skip_cached_field_update] = false
    create_report_design_annotation_type
    Sidekiq::Testing.inline! do
      pm = create_project_media
      cd = create_claim_description(project_media: pm)
      fc = create_fact_check claim_description: cd, title: 'Foo'
      r = pm.get_dynamic_annotation('report_design')
      publish_report(pm, {}, r)
      assert_equal 'published', pm.reload.report_status
      assert_equal 'Foo', pm.reload.report_text_title

      cd.project_media = nil # Remove the claim/fact-check from the item
      cd.save!
      assert_equal 'paused', pm.reload.report_status
      assert_equal '', pm.reload.report_text_title

      cd.project_media = pm # Re-add the claim/fact-check to the item
      cd.save!
      assert_equal 'paused', pm.reload.report_status
      assert_equal 'Foo', pm.reload.report_text_title
    end
  end

  test "should reset cached fields when fact-check is detached" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      pm = create_project_media
      cd = create_claim_description project_media: pm
      fc = create_fact_check claim_description: cd, title: 'Foo'
      assert_equal fc.id, pm.reload.fact_check_id

      cd.project_media = nil # Remove the claim/fact-check from the item
      cd.save!
      assert_nil pm.reload.fact_check_id
    end
  end

  test "should be formatted as tipline search result" do
    fc = create_fact_check
    assert_kind_of TiplineSearchResult, fc.as_tipline_search_result
  end

  test "should set author" do
    u = create_user is_admin: true
    User.current = u
    fc = create_fact_check
    User.current = nil
    assert_equal u, fc.author
  end
end
