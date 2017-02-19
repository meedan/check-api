require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')

class DynamicAnnotation::FieldInstanceTest < ActiveSupport::TestCase
  test "should create field instance" do
    assert_difference 'DynamicAnnotation::FieldInstance.count' do
      create_field_instance
    end
  end

  test "should not create field instance if name is blank" do
    assert_no_difference 'DynamicAnnotation::FieldInstance.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_field_instance name: nil
      end
    end
  end

  test "should not create field instance if label is blank" do
    assert_no_difference 'DynamicAnnotation::FieldInstance.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_field_instance label: nil
      end
    end
  end

  test "should not create field instance if name has invalid format" do
    assert_no_difference 'DynamicAnnotation::FieldInstance.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_field_instance name: 'This is not valid'
      end
    end
  end

  test "should not create duplicated field instances" do
    assert_difference 'DynamicAnnotation::FieldInstance.count' do
      create_field_instance name: 'response'
    end
    assert_no_difference 'DynamicAnnotation::FieldInstance.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_field_instance name: 'response'
      end
    end
  end

  test "should be optional by default" do
    fi = create_field_instance
    assert fi.optional
  end

  test "should have settings" do
    settings = { options: [1, 2, 3] }
    fi = create_field_instance settings: settings
    assert_equal settings, fi.reload.settings
  end

  test "should belong to field type" do
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance field_type_object: ft
    assert_equal 'text_field', fi.reload.field_type
    assert_equal ft, fi.reload.field_type_object
  end

  test "should belong to annotation type" do
    at = create_annotation_type annotation_type: 'task_response_free_text'
    fi = create_field_instance annotation_type_object: at
    assert_equal 'task_response_free_text', fi.reload.annotation_type
    assert_equal at, fi.reload.annotation_type_object
  end
end
