require_relative '../test_helper'

class ProjectMediaTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
  end

  test "should query media" do
    setup_elasticsearch
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    create_project_media team: t, disable_es_callbacks: false
    create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm = create_project_media team: t, disable_es_callbacks: false
    create_relationship source_id: pm.id, target_id: create_project_media(team: t, disable_es_callbacks: false).id, relationship_type: Relationship.confirmed_type
    sleep 2
    assert_equal 3, CheckSearch.new({ team_id: t.id }.to_json, nil, t.id).medias.size
    assert_equal 4, CheckSearch.new({ show_similar: true, team_id: t.id }.to_json, nil, t.id).medias.size
  end

  test "should handle indexing conflicts" do
    require File.join(Rails.root, 'lib', 'middleware_sidekiq_server_retry')
    Sidekiq::Testing.server_middleware do |chain|
      chain.add ::Middleware::Sidekiq::Server::Retry
    end

    class ElasticSearchTestWorker
      include Sidekiq::Worker
      attr_accessor :retry_count
      sidekiq_options retry: 5

      sidekiq_retries_exhausted do |_msg, e|
        raise e
      end

      def perform(id)
        begin
          client = $repository.client
          client.update index: CheckElasticSearchModel.get_index_alias, id: id, retry_on_conflict: 0, body: { doc: { updated_at: Time.now + rand(50).to_i } }
        rescue Exception => e
          retry_count = retry_count.to_i + 1
          if retry_count < 5
            perform(id)
          else
            raise e
          end
        end
      end
    end

    setup_elasticsearch

    threads = []
    pm = create_project_media media: nil, quote: 'test', disable_es_callbacks: false
    id = get_es_id(pm)
    15.times do |i|
      threads << Thread.start do
        Sidekiq::Testing.inline! do
          ElasticSearchTestWorker.perform_async(id)
        end
      end
    end
    threads.map(&:join)
  end

  test "should localize status" do
    I18n.locale = :pt
    pm = create_project_media
    assert_equal 'Não Iniciado', pm.status_i18n(nil, { locale: 'pt' })
    t = create_team slug: 'test'
    value = {
      label: 'Field label',
      active: 'test',
      default: 'undetermined',
      statuses: [
        { id: 'undetermined', locales: { en: { label: 'Undetermined', description: '' } }, style: { color: 'blue' } },
        { id: 'test', locales: { en: { label: 'Test', description: '' }, pt: { label: 'Teste', description: '' } }, style: { color: 'red' } }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!
    p = create_project team: t
    pm = create_project_media project: p
    assert_equal 'Undetermined', pm.status_i18n(nil, { locale: 'pt' })
    I18n.stubs(:exists?).with('custom_message_status_test_test').returns(true)
    I18n.stubs(:t).returns('')
    I18n.stubs(:t).with(:custom_message_status_test_test, { locale: 'pt' }).returns('Teste')
    assert_equal 'Teste', pm.status_i18n('test', { locale: 'pt' })
    I18n.unstub(:t)
    I18n.unstub(:exists?)
    I18n.locale = :en
  end

  test "should not throw exception for trashed item if request does not come from a client" do
    pm = create_project_media project: p
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    User.current = nil
    assert_nothing_raised do
      create_tag annotated: pm
    end
    u = create_user(is_admin: true)
    User.current = u
    assert_raises ActiveRecord::RecordInvalid do
      create_tag annotated: pm
    end
    User.current = nil
  end

  test "should set initial custom status of orphan item" do
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
    pm = create_project_media project: nil, team: t
    assert_equal 'stop', pm.last_status
  end

  test "should change custom status of orphan item" do
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
    pm = create_project_media project: nil, team: t
    assert_nothing_raised do
      s = pm.last_status_obj
      s.status = 'done'
      s.save!
    end
  end

  test "should clear caches when report is updated" do
    ProjectMedia.any_instance.unstub(:clear_caches)
    Sidekiq::Testing.inline! do
      CcDeville.stubs(:clear_cache_for_url).times(6)
      pm = create_project_media
      pm.skip_clear_cache = false
      RequestStore.store[:skip_clear_cache] = false
      PenderClient::Request.stubs(:get_medias)
      publish_report(pm)
    end
    CcDeville.unstub(:clear_cache_for_url)
    PenderClient::Request.unstub(:get_medias)
    ProjectMedia.any_instance.stubs(:clear_caches)
  end

  test "should generate short URL when getting embed URL for the first time" do
    pm = create_project_media
    assert_difference 'Shortener::ShortenedUrl.count' do
      assert_match /^http/, pm.embed_url
    end
    assert_no_difference 'Shortener::ShortenedUrl.count' do
      assert_match /^http/, pm.embed_url
    end
  end

  test "should validate duplicate based on team" do
    t = create_team
    p = create_project team: t
    t2 = create_team
    p2 = create_project team: t2
    # Create media in different team with no list
    m = create_valid_media
    create_project_media team: t, media: m
    assert_nothing_raised do
      create_project_media team: t2, url: m.url
    end
    # Try to add same item to list
    assert_raises RuntimeError do
      create_project_media team: t, url: m.url
    end
    # Create item in a list then try to add it via all items(with no list)
    m2 = create_valid_media
    create_project_media team:t, project_id: p.id, media: m2
    assert_raises RuntimeError do
      create_project_media team: t, url: m2.url
    end
    # Add same item to list in different team
    assert_nothing_raised do
      create_project_media team: t2, url: m2.url
    end
    # create item in a list then try to add it to all items in different team
    m3 = create_valid_media
    create_project_media team: t, project_id: p.id, media: m3
    assert_nothing_raised do
      create_project_media team: t2, url: m3.url
    end
  end

  test "should cache sources list" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      s_a = create_source team: t, name: 'source_a'
      s_b = create_source team: t, name: 'source_b'
      s_c = create_source team: t, name: 'source_c'
      s_d = create_source team: t, name: 'source_d'
      pm = create_project_media team: t, source: s_a, skip_autocreate_source: false
      t1 = create_project_media team: t, source: s_b, skip_autocreate_source: false
      t2 = create_project_media team: t, source: s_c, skip_autocreate_source: false
      t3 = create_project_media team: t, source: s_d, skip_autocreate_source: false
      result = {}
      # Verify cache item source
      result[s_a.id] = s_a.name
      assert_queries(0, '=') { assert_equal result.to_json, pm.sources_as_sentence }
      # Verify cache source for similar items
      r1 = create_relationship source_id: pm.id, target_id: t1.id, relationship_type: Relationship.confirmed_type
      r2 = create_relationship source_id: pm.id, target_id: t2.id, relationship_type: Relationship.confirmed_type
      r3 = create_relationship source_id: pm.id, target_id: t3.id, relationship_type: Relationship.suggested_type
      result[s_b.id] = s_b.name
      result[s_c.id] = s_c.name
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal result.to_json, pm.sources_as_sentence }
      # Verify main source is a first element
      assert_equal pm.source_id, JSON.parse(pm.sources_as_sentence).keys.first.to_i
      # Verify update source names after destroy similar item
      r1.destroy
      result.delete(s_b.id)
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal result.to_json, pm.sources_as_sentence }
      # Verify update item source
      new_s1 = create_source team: t, name: 'new_source_1'
      pm.source = new_s1; pm.save!
      result.delete(s_a.id)
      result[new_s1.id] = new_s1.name
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal result.keys.map(&:to_s).sort, JSON.parse(pm.sources_as_sentence).keys.sort }
      # Verify update source for similar item
      result_similar = {}
      result_similar[s_c.id] = s_c.name
      assert_queries(0, '=') { assert_equal result_similar.to_json, t2.sources_as_sentence }
      new_s2 = create_source team: t, name: 'new_source_2'
      t2.source = new_s2; t2.save!
      t2 = ProjectMedia.find(t2.id)
      result_similar.delete(s_c.id)
      result_similar[new_s2.id] = new_s2.name
      assert_queries(0, '=') { assert_equal result_similar.to_json, t2.sources_as_sentence }
      result.delete(s_c.id)
      result[new_s2.id] = new_s2.name
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal result.to_json, pm.sources_as_sentence }
      # Verify update source name
      new_s2.name = 'update source'; new_s2.save!
      result[new_s2.id] = 'update source'
      pm = ProjectMedia.find(pm.id)
      assert_queries(0, '=') { assert_equal result.to_json, pm.sources_as_sentence }
      # Verify update relation
      r3.relationship_type = Relationship.confirmed_type; r3.save!
      result[s_d.id] = s_d.name
      pm = ProjectMedia.find(pm.id)
      result_keys = result.keys.map(&:to_i).sort
      sources_keys = JSON.parse(pm.sources_as_sentence).keys.map(&:to_i).sort
      assert_queries(0, '=') { assert_equal result_keys, sources_keys }
      Rails.cache.clear
      assert_queries(0, '>') { assert_equal result_keys, JSON.parse(pm.sources_as_sentence).keys.map(&:to_i).sort }
    end
  end

  test "should have web form channel" do
    pm = create_project_media channel: { main: CheckChannels::ChannelCodes::WEB_FORM }
    assert_equal 'Web Form', pm.reload.get_creator_name
  end

  test "should respond to file upload auto-task on creation" do
    url = random_url
    WebMock.stub_request(:get, url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))

    at = create_annotation_type annotation_type: 'task_response_file_upload', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_file_upload', label: 'Response', field_type_object: ft1

    t = create_team
    create_team_task team_id: t.id, label: 'Upload a file', task_type: 'file_upload'
    Sidekiq::Testing.inline! do
      pm = nil
      assert_difference 'Task.length', 1 do
        pm = create_project_media team: t, set_tasks_responses: { 'upload_a_file' => url }
      end
      task = pm.annotations('task').last
      assert task.first_response_obj&.load&.file.to_a.size > 0
    end
  end

  test "should get shared database creator" do
    pm = create_project_media channel: { main: CheckChannels::ChannelCodes::SHARED_DATABASE }
    assert_equal 'Shared Database', pm.creator_name
  end

  test "should make claims and fact-checks standalone when item is deleted" do
    pm = create_project_media
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd
    assert_difference 'ProjectMedia.count', -1 do
      assert_no_difference 'ClaimDescription.count' do
        assert_no_difference 'FactCheck.count' do
          pm.destroy!
        end
      end
    end
    assert_nil cd.reload.project_media
    assert_equal cd, fc.reload.claim_description
  end

  test "should delete project_media_requests and requests when item is deleted" do
    t = create_team
    m1 = create_claim_media
    pm = create_project_media team: t, media: m1
    r1 = create_request media: m1
    r2 = create_request
    r3 = create_request
    create_project_media_request project_media_id: pm.id, request_id: r1.id
    create_project_media_request project_media_id: pm.id, request_id: r2.id
    create_project_media_request project_media_id: pm.id, request_id: r3.id
    assert_difference 'ProjectMedia.count', -1 do
      assert_difference 'ProjectMediaRequest.count', -3 do
        assert_no_difference 'Request.count' do
          Sidekiq::Testing.inline! do
            pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
            pm.save!
          end
        end
      end
    end
    t2 = create_team
    pm2 = create_project_media team: t2, media: m1
    create_project_media_request project_media_id: pm2.id, request_id: r1.id
    assert_nothing_raised do
      r1.destroy!
    end
  end

  test "should get claim description and fact-check data" do
    pm = create_project_media
    assert_nil pm.claim_description_content
    assert_nil pm.claim_description_context
    cd = create_claim_description project_media: pm, description: 'Foo', context: 'Bar'
    fc = create_fact_check claim_description: cd
    assert_equal 'Foo', pm.claim_description_content
    assert_equal 'Bar', pm.claim_description_context
    assert_not_nil pm.fact_check_published_on
  end

  test "should cache if item is suggested or confirmed" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    main = create_project_media team: t
    pm = create_project_media team: t
    assert !pm.is_suggested
    assert !pm.is_confirmed
    assert_equal 0, pm.reload.unmatched
    assert_equal 0, main.reload.unmatched
    r = create_relationship source_id: main.id, target_id: pm.id, relationship_type: Relationship.suggested_type
    assert pm.is_suggested
    assert !pm.is_confirmed
    assert_equal 0, pm.reload.unmatched
    r.relationship_type = Relationship.confirmed_type
    r.save!
    assert !pm.is_suggested
    assert pm.is_confirmed
    assert_equal 0, pm.reload.unmatched
    r.destroy!
    assert !pm.is_suggested
    assert !pm.is_confirmed
    assert_equal 1, pm.reload.unmatched
    assert_equal 1, main.reload.unmatched
    r = create_relationship source_id: main.id, target_id: pm.id, relationship_type: Relationship.confirmed_type
    assert_equal 0, pm.reload.unmatched
    assert_equal 0, main.reload.unmatched
  end

  test "should delete for ever trashed items" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pm = nil
    cache_key = nil
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t
      # Check that cached field exists (pick a key to verify the key deleted after destroy item)
      cache_key = "check_cached_field:ProjectMedia:#{pm.id}:folder"
      assert Rails.cache.exist?(cache_key)
    end
    Sidekiq::Testing.fake! do
      pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm.save!
    end
    assert_not_nil ProjectMedia.find_by_id(pm.id)
    Sidekiq::Worker.drain_all
    assert_nil ProjectMedia.find_by_id(pm.id)
    assert_not Rails.cache.exist?(cache_key)
    # Restore item from trash before apply delete for ever
    pm = create_project_media team: t
    Sidekiq::Testing.fake! do
      pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm.save!
    end
    assert_not_nil ProjectMedia.find_by_id(pm.id)
    pm.archived = CheckArchivedFlags::FlagCodes::NONE
    pm.save!
    Sidekiq::Worker.drain_all
    assert_not_nil ProjectMedia.find_by_id(pm.id)
  end

  test "should delete for ever spam items" do
    t = create_team
    pm_s = create_project_media team: t
    pm_t1 = create_project_media team: t
    pm_t2 = create_project_media team: t
    pm_t3 = create_project_media team: t
    r1 = create_relationship source_id: pm_s.id, target_id: pm_t1.id, relationship_type: Relationship.default_type
    r2 = create_relationship source_id: pm_s.id, target_id: pm_t2.id, relationship_type: Relationship.confirmed_type
    r3 = create_relationship source_id: pm_s.id, target_id: pm_t3.id, relationship_type: Relationship.suggested_type
    Sidekiq::Testing.fake! do
      pm_s.archived = CheckArchivedFlags::FlagCodes::SPAM
      pm_s.save!
    end
    assert_not_nil ProjectMedia.find_by_id(pm_s.id)
    assert_equal 4, ProjectMedia.where(id: [pm_s.id, pm_t1.id, pm_t2.id, pm_t3.id]).count
    assert_equal 3, Relationship.where(id: [r1.id, r2.id, r3.id]).count
    Sidekiq::Worker.drain_all
    assert_equal CheckArchivedFlags::FlagCodes::SPAM, pm_s.reload.archived
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm_t3.reload.archived
    assert_equal 0, Relationship.where(id: [r1.id, r2.id, r3.id]).count
    assert_nil ProjectMedia.find_by_id(pm_t1.id)
    assert_nil ProjectMedia.find_by_id(pm_t2.id)
    # Restore item from spam before apply delete for ever
    pm_s = create_project_media team: t
    pm_t = create_project_media team: t
    r = create_relationship source_id: pm_s.id, target_id: pm_t.id, relationship_type: Relationship.confirmed_type
    Sidekiq::Testing.fake! do
      pm_s.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm_s.save!
    end
    assert_equal 2, ProjectMedia.where(id: [pm_s.id, pm_t.id]).count
    Sidekiq::Testing.fake! do
      pm_s.archived = CheckArchivedFlags::FlagCodes::NONE
      pm_s.save!
    end
    Sidekiq::Worker.drain_all
    assert_equal 2, ProjectMedia.where(id: [pm_s.id, pm_t.id], archived: CheckArchivedFlags::FlagCodes::NONE).count
    assert_not_nil Relationship.where(id: r.id).last
  end

  test "should create item with original claim video with arguments" do
    video_url = 'https://test.xyz/video.mp4?foo=bar'
    WebMock.stub_request(:get, video_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp4')), headers: { 'Content-Type' => 'video/mp4' })
    assert_difference 'ProjectMedia.count' do
      create_project_media media: nil, set_original_claim: video_url
    end
  end
end
