require_relative '../../test_helper'

class DynamicAnnotation::FieldTest < ActiveSupport::TestCase
  test "should create field" do
    assert_difference 'DynamicAnnotation::Field.count' do
      create_field
    end
  end

  test "should set annotation type automatically" do
    at = create_annotation_type annotation_type: 'task_response_free_text'
    a = create_dynamic_annotation annotation_type: 'task_response_free_text'
    f = create_field annotation_type: nil, annotation_id: a.id
    assert_equal 'task_response_free_text', f.reload.annotation_type
    assert_equal at, f.reload.annotation_type_object
  end

  test "should belong to annotation" do
    a = create_dynamic_annotation
    f = create_field annotation_id: a.id
    assert_equal a, f.reload.annotation
  end

  test "should belong to field instance" do
    fi = create_field_instance name: 'response'
    f = create_field field_name: 'response'
    assert_equal fi, f.reload.field_instance
  end

  test "should set field_type automatically" do
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance name: 'response', field_type_object: ft
    f = create_field field_name: 'response'
    assert_equal 'text_field', f.reload.field_type
    assert_equal ft, f.reload.field_type_object
  end

  test "should have value" do
    value = { lat: '-13.34', lon: '2.54' }
    f = create_field value: value
    assert_equal value, f.reload.value
  end

  test "should have versions" do
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance name: 'response', field_type_object: ft
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    a = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      assert_difference 'PaperTrail::Version.count' do
        create_field annotation_id: a.id, field_name: 'response'
      end
    end
  end

  test "should get string value" do
    DynamicAnnotation::Field.class_eval do
      def field_formatter_name_response
        response_value(self.value)
      end
    end
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance name: 'response', field_type_object: ft
    f = create_field field_name: 'response', value: '{"selected":["Hello","Aloha"],"other":null}'
    assert_equal 'Hello and Aloha', f.to_s
  end

  test "should get language" do
    ft = create_field_type field_type: 'language'
    fi = create_field_instance name: 'language', field_type_object: ft
    f1 = create_field field_name: 'language', value: 'fr'
    assert_equal 'fr', f1.value
    f3 = create_field field_name: 'language', value: 'xx'
    assert_equal 'xx', f3.value
  end

  test "should get language name" do
    ft = create_field_type field_type: 'language'
    fi = create_field_instance name: 'language', field_type_object: ft
    f1 = create_field field_name: 'language', value: 'fr'
    assert_equal 'French', f1.to_s
    f3 = create_field field_name: 'language', value: 'xx'
    assert_equal 'xx', f3.to_s
  end

  test "should get formatted value in JSON" do
    ft = create_field_type field_type: 'language'
    fi = create_field_instance name: 'language', field_type_object: ft
    f1 = create_field field_name: 'language', value: 'fr'
    assert_equal 'French', f1.as_json[:formatted_value]
  end

  test "should validate and format geojson field" do
    create_geojson_field

    assert_raises ActiveRecord::RecordInvalid do
      create_field field_name: 'response_geolocation', value: '-10,20'
    end

    assert_raises ActiveRecord::RecordInvalid do
      geojson = {
        type: 'Feature',
        geometry: {
          coordinates: [-12.9015866, -38.560239]
        },
        properties: {
          name: 'Salvador, BA, Brazil'
        }
      }.to_json
      create_field field_name: 'response_geolocation', value: geojson
    end

    assert_nothing_raised do
      geojson = {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [-12.9015866, -38.560239]
        },
        properties: {
          name: 'Salvador, BA, Brazil'
        }
      }.to_json
      f = create_field field_name: 'response_geolocation', value: geojson
      assert_equal 'Salvador, BA, Brazil (-12.9015866, -38.560239)', f.to_s
    end

    assert_nothing_raised do
      geojson = {
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [0,0]
        },
        properties: {
          name: 'Only Name'
        }
      }.to_json
      f = create_field field_name: 'response_geolocation', value: geojson
      assert_equal 'Only Name', f.to_s
    end
  end

  test "should format datetime field" do
    create_datetime_field
    f = create_field field_name: 'response_datetime', value: '2017-08-21 13:42:23 -0700'
    assert_equal 'August 21, 2017', f.to_s
  end

  test "should validate datetime field" do
    create_datetime_field
    assert_nothing_raised do
      create_field field_name: 'response_datetime', value: '2017-08-21 13:42:23 -0700'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_field field_name: 'response_datetime', value: 'yesterday'
    end
  end

  protected

  def create_geojson_field
    geo = create_field_type field_type: 'geojson', label: 'GeoJSON'
    create_field_instance name: 'response_geolocation', field_type_object: geo
  end

  def create_datetime_field
    dt = create_field_type field_type: 'datetime'
    create_field_instance name: 'response_datetime', field_type_object: dt
  end
end
