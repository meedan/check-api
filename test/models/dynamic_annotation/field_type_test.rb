require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')

class DynamicAnnotation::FieldTypeTest < ActiveSupport::TestCase
  test "should create field type" do
    assert_difference 'DynamicAnnotation::FieldType.count' do
      create_field_type
    end
  end

  test "should not create field type if type is blank" do
    assert_no_difference 'DynamicAnnotation::FieldType.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_field_type field_type: nil
      end
    end
  end

  test "should not create field type if label is blank" do
    assert_no_difference 'DynamicAnnotation::FieldType.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_field_type label: nil
      end
    end
  end

  test "should not create field type if type has invalid format" do
    assert_no_difference 'DynamicAnnotation::FieldType.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_field_type field_type: 'This is not valid'
      end
    end
  end

  test "should not create duplicated field type" do
    assert_difference 'DynamicAnnotation::FieldType.count' do
      create_field_type field_type: 'text_field'
    end
    assert_no_difference 'DynamicAnnotation::FieldType.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_field_type field_type: 'text_field'
      end
    end
  end

  test "should have many field instances" do
    ft = create_field_type field_type: 'text_field'
    fi1 = create_field_instance field_type_object: ft, name: 'response'
    fi2 = create_field_instance field_type_object: ft, name: 'note'
    assert_equal [fi1, fi2], ft.reload.field_instances
  end
end
