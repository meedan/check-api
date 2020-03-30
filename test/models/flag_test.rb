require_relative '../test_helper'

class FlagTest < ActiveSupport::TestCase
  def setup
    super
    create_flag_annotation_type
  end

  test "should create flag" do
    assert_difference "Dynamic.where(annotation_type: 'flag').count" do
      create_flag
    end
  end

  test "should set type automatically" do
    f = create_flag
    assert_equal 'flag', f.annotation_type
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_project_media
    s2 = create_project_media
    Annotation.delete_all
    f1 = create_flag annotator: u1, annotated: s1
    f2 = create_flag annotator: u1, annotated: s1
    f3 = create_flag annotator: u1, annotated: s1
    f4 = create_flag annotator: u2, annotated: s1
    f5 = create_flag annotator: u2, annotated: s1
    f6 = create_flag annotator: u3, annotated: s2
    f7 = create_flag annotator: u3, annotated: s2
    assert_equal [u1.id, u2.id].sort, s1.annotators.map(&:id).sort
    assert_equal [u3.id], s2.annotators.map(&:id)
  end

  test "should get flag values" do
    keys = ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam']
    flags = {}
    keys.each do |key|
      flags[key] = random_number(4)
    end
    f = nil
    assert_nothing_raised do
      f = create_flag set_fields: { flags: flags }.to_json
    end
    keys.each do |key|
      assert_equal flags[key], f.get_field_value('flags')[key]
    end
  end

  test "should validate flag against JSON schema" do
    assert_nothing_raised do
      create_flag set_fields: valid_flags_data.to_json
    end
    missing_key = valid_flags_data ; missing_key[:flags].delete('spam')
    extra_key = valid_flags_data ; extra_key[:flags]['foo'] = 3
    value_less_than_min = valid_flags_data ; value_less_than_min[:flags]['spam'] = -1
    value_greater_than_max = valid_flags_data ; value_greater_than_max[:flags]['spam'] = 6
    [
      { noflags: 'test' },
      { flags: ['foo', 'bar'] },
      missing_key,
      extra_key,
      value_less_than_min,
      value_greater_than_max
    ].each do |data|
      assert_raises ActiveRecord::RecordInvalid do
        create_flag set_fields: data.to_json
      end
    end
  end

  test "should get flag data" do
    f = create_flag
    assert_not_nil f.data
  end
end
