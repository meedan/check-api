require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MachineTranslationWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON structure')
    at = create_annotation_type annotation_type: 'mt', label: 'Machine translation'
    create_field_instance annotation_type_object: at, name: 'mt_translations', label: 'Machine translations', field_type_object: ft, optional: false
  end

  test "should update machine translation in background" do
    MachineTranslationWorker.drain
    t = create_team
    p = create_project team: t
    p.settings = {:languages => ['ar']}; p.save!
    pm = create_project_media project: p, quote: 'Test'
    pm.update_mt=1
    assert_equal 1, MachineTranslationWorker.jobs.size
  end

end
