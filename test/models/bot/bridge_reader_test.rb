require_relative '../../test_helper'

class Bot::BridgeReaderTest < ActiveSupport::TestCase
  def setup
    Bot::BridgeReader.delete_all
    @bot = create_bridge_reader_bot
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
  end

  test "should return default bot" do
    assert_equal @bot, Bot::BridgeReader.default
  end

  test "should be disabled if there are no configs" do
    stub_config('bridge_reader_private_url', '') do
      Bot::BridgeReader.default.disabled?
    end
  end

  test "should not notify embed system when project media is updated" do
    pm = create_project_media project: @project
    pm.created_at = DateTime.now - 1.day
    ProjectMedia.any_instance.stubs(:notify_destroyed).never
    pm.save!
    ProjectMedia.any_instance.unstub(:notify_destroyed)
  end

  test "should notify embed system when project media is destroyed" do
    pm = create_project_media project: @project
    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).with(pm, 'destroyed', nil).once
    pm.disable_es_callbacks = true
    pm.destroy
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
  end

  test "should not notify embed system if there are no configs" do
    pm = create_project_media project: @project
    pm.created_at = DateTime.now - 1.day
    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).with(pm, 'updated', { id: pm.id.to_s}).never
    stub_config('bridge_reader_private_url', '') do
      pm.save!
    end
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
  end

  test "should not notify embed system if field is not translation" do
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    DynamicAnnotation::Field.any_instance.stubs(:notify_created).never
    d = create_dynamic_annotation
    DynamicAnnotation::Field.any_instance.unstub(:notify_created)
  end

  test "should notify embed system when translation is created" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).once
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm, set_fields: { translation_text: 'Translated' }.to_json
    field = d.get_fields.select{ |f| f['field_name'] == 'translation_text' }.first
    assert_equal({ id: pm.id.to_s }, field.notify_embed_system_created_object)
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
  end

  test "should notify embed system when translation is updated" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm, set_fields: { translation_text: 'Translated' }.to_json
    field = d.get_fields.select{ |f| f['field_name'] == 'translation_text' }.first

    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).once
    field = DynamicAnnotation::Field.find(field.id)
    field.value = 'Translated reviewed'
    field.save!
    assert_equal({ id: pm.id.to_s }, field.notify_embed_system_updated_object)
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
  end

  test "should notify embed system when translation is destroyed" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm, set_fields: { translation_text: 'Translated' }.to_json
    field = d.get_fields.select{ |f| f['field_name'] == 'translation_text' }.first

    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).once
    field.destroy
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
  end

  test "should notify embed system when team is created" do
    Team.any_instance.stubs(:notify_created).once
    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).once
    t = create_team(slug: 'check-team')
    assert_equal({ slug: 'check-team' }, t.notify_embed_system_created_object)
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
    Team.any_instance.unstub(:notify_created)
  end

  test "should notify embed system when project is updated" do
    t = create_team(slug: 'check-team-updated')
    t.name = 'Changed'
    Team.any_instance.stubs(:notify_updated).once
    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).once
    t.save!
    assert_equal t.as_json, t.notify_embed_system_updated_object
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
    Team.any_instance.unstub(:notify_updated)
  end

  test "should have a JSON payload" do
    f = create_field
    assert_nothing_raised do
      JSON.parse(f.notify_embed_system_payload('foo', 'bar'))
    end
  end

  test "should have a notification URI" do
    f = create_field
    assert_kind_of URI, f.notification_uri('foo')
  end

  test "should notify" do
    f = create_field
    @bot.send :notify_embed_system, f, 'foo', 'bar'
  end

  test "project media should have a JSON payload" do
    pm = create_project_media
    assert_nothing_raised do
      JSON.parse(pm.notify_embed_system_payload('foo', 'bar'))
    end
  end

  test "project media should have a notification URI" do
    pm = create_project_media
    assert_kind_of URI, pm.notification_uri('foo')
  end

  test "team should have a JSON payload" do
    t = create_team
    assert_nothing_raised do
      JSON.parse(t.notify_embed_system_payload('foo', 'bar'))
    end
  end

  test "team should have a notification URI" do
    t = create_team
    assert_kind_of URI, t.notification_uri('foo')
  end

  test "should notify embed system when team is updated" do
    Bot::BridgeReader.any_instance.stubs(:notify_embed_system).once
    t = create_team(slug: 'check-team')
    t = Team.find(t.id)
    t.name = 'Check Team'
    t.save!
    Bot::BridgeReader.any_instance.unstub(:notify_embed_system)
  end
end
