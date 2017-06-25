require_relative '../test_helper'

class MachineTranslationWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false

    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON structure')
    at = create_annotation_type annotation_type: 'mt', label: 'Machine translation'
    create_field_instance annotation_type_object: at, name: 'mt_translations', label: 'Machine translations', field_type_object: ft, optional: false
  end

  test "should update machine translation in background" do
    Sidekiq::Testing.fake!
    MachineTranslationWorker.drain
    assert_equal 0, MachineTranslationWorker.jobs.size
    t = create_team
    p = create_project team: t
    p.settings = {:languages => ['ar']}; p.save!
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      text = 'Testing'
      url = CONFIG['alegre_host'] + "/api/languages/identification?text=" + text
      response = '{"type":"language","data": [["EN", 1]]}'
      WebMock.stub_request(:get, url).with(:headers => {'X-Alegre-Token'=> CONFIG['alegre_token']}).to_return(body: response)
      pm = create_project_media project: p, quote: text
      pm.update_mt = 1
      assert_equal 1, MachineTranslationWorker.jobs.size
    end
  end

end
