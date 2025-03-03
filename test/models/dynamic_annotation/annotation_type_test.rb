require_relative '../../test_helper'

class DynamicAnnotation::AnnotationTypeTest < ActiveSupport::TestCase
  test "should create annotation type" do
    assert_difference 'DynamicAnnotation::AnnotationType.count' do
      create_annotation_type
    end
  end

  test "should not create annotation type if type is blank" do
    assert_no_difference 'DynamicAnnotation::AnnotationType.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_annotation_type annotation_type: nil
      end
    end
  end

  test "should not create annotation type if label is blank" do
    assert_no_difference 'DynamicAnnotation::AnnotationType.count' do
      assert_raises ActiveRecord::StatementInvalid do
        create_annotation_type label: nil
      end
    end
  end

  test "should not create annotation type if type has invalid format" do
    assert_no_difference 'DynamicAnnotation::AnnotationType.count' do
      assert_raises NameError do
        create_annotation_type annotation_type: 'This is not valid'
      end
    end
  end

  test "should not create duplicated annotation type" do
    assert_difference 'DynamicAnnotation::AnnotationType.count' do
      create_annotation_type annotation_type: 'location'
    end
    assert_no_difference 'DynamicAnnotation::AnnotationType.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_annotation_type annotation_type: 'location'
      end
    end
  end

  test "should have schema" do
    at = create_annotation_type annotation_type: 'task_response_free_text'
    fi1 = create_field_instance annotation_type_object: at, name: 'response'
    fi2 = create_field_instance annotation_type_object: at, name: 'note'
    assert_equal [fi1, fi2], at.reload.schema
  end

  test "should not create annotation type with reserved name" do
    assert_no_difference 'DynamicAnnotation::AnnotationType.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_annotation_type annotation_type: 'tag'
      end
    end
  end

  test "should have many annotations" do
    at = create_annotation_type annotation_type: 'task_response_free_text'
    a1 = create_dynamic_annotation annotation_type: 'task_response_free_text'
    a2 = create_dynamic_annotation annotation_type: 'task_response_free_text'
    assert_equal [a1, a2].sort, at.reload.annotations.sort
  end

  test "should have a valid JSON schema" do
    assert_raises ActiveRecord::RecordInvalid do
      create_annotation_type json_schema: { type: 'foo' }
    end
    assert_nothing_raised do
      create_annotation_type json_schema: { type: 'object' }
    end
  end
end
