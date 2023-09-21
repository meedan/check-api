require_relative '../../test_helper'

class DynamicAnnotation::FieldTest < ActiveSupport::TestCase
  test "should create field" do
    assert_nothing_raised do
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
    value = { 'lat' => '-13.34', 'lon' => '2.54' }
    f = create_field value: value
    assert_equal value, f.reload.value
    # get associated_graphql_id
    assert_kind_of String, f.reload.associated_graphql_id
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
    assert_equal 'Hello, Aloha', f.to_s
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
      assert_equal 'Only Name (0, 0)', f.to_s
      assert_equal JSON.parse(geojson), f.value_json
    end
  end

  test "should format datetime field" do
    create_datetime_field
    f = create_field field_name: 'response_datetime', value: '2017-08-21 13:42:23 -0700 PST'
    assert_equal 'August 21, 2017 at 13:42 PST (-0700 UTC)', f.to_s
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

  test "should validate datetime field with Arabic numbers" do
    create_datetime_field
    assert_nothing_raised do
      create_field field_name: 'response_datetime', value: '2017-08-21 ١۲:١۲ -0700'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_field field_name: 'response_datetime', value: '2017-08-21 ۵۵:۵۵ -0700'
    end
  end

  test "should validate bot response" do
    create_bot_response_field
    assert_nothing_raised do
      create_field(field_name: 'team_bot_response_formatted_data', value: { title: 'Foo', description: 'Bar' }.to_json)
      create_field(field_name: 'team_bot_response_formatted_data', value: { title: 'Foo', description: 'Bar', image_url: 'http://image.url' }.to_json)
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_field(field_name: 'team_bot_response_formatted_data', value: { title: 'Foo' }.to_json)
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_field(field_name: 'team_bot_response_formatted_data', value: { description: 'Bar' }.to_json)
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_field(field_name: 'team_bot_response_formatted_data', value: 'Not a JSON')
    end
  end

  test "should query by JSON key" do
    json = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    begin create_field_instance(name: 'metadata', field_type_object: json) rescue nil end
    p1 = random_string
    p2 = random_string
    create_field field_name: 'metadata', value: { provider: p1, external_id: 10 }.to_json
    create_field field_name: 'metadata', value: { provider: p2, external_id: 20 }.to_json
    create_field field_name: 'metadata', value: { provider: p2, external_id: 30 }.to_json
    assert_equal 2, DynamicAnnotation::Field.find_in_json({ provider: p2 }).count
    assert_equal 1, DynamicAnnotation::Field.find_in_json({ provider: p1 }).count
    assert_equal 1, DynamicAnnotation::Field.find_in_json({ provider: p2, external_id: 20 }).count
    assert_equal 1, DynamicAnnotation::Field.find_in_json({ provider: p2, external_id: 30 }).count
  end

  test "should accept geojson polygon" do
    create_geojson_field

    assert_nothing_raised do
      geojson = {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [
              [
                12.401415380468768,
                41.979683334337345
              ],
              [
                12.406908544531268,
                41.81818006732377
              ],
              [
                12.590929540625018,
                41.77313177519179
              ],
              [
                12.733751806250018,
                41.88569312999465
              ],
              [
                12.632128271093768,
                42.012343110768704
              ]
            ]
          ]
        },
        "properties": {
          "name": "Rome"
        }
      }.to_json
      f = create_field field_name: 'response_geolocation', value: geojson, disable_es_callbacks: false
      f.to_s
    end
  end

  test "should get smooch user slack channel url" do
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    create_annotation_type_and_fields('Smooch User', {
      'Data' => ['JSON', false],
      'Slack Channel Url' => ['Text', true],
      'ID' => ['Text', false]
    })
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    author_id = random_string
    url = random_url
    set_fields = { smooch_user_id: author_id, smooch_user_data: { id: author_id }.to_json, smooch_user_slack_channel_url: url }.to_json
    d = create_dynamic_annotation annotated: t, annotation_type: 'smooch_user', set_fields: set_fields
    with_current_user_and_team(u, t) do
      ds = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: { 'authorId' => author_id }.to_json }.to_json
      f = ds.get_field('smooch_data')
      assert_equal url, f.smooch_user_slack_channel_url
      assert 1, Rails.cache.delete_matched("SmoochUserSlackChannelUrl:Team:*")
      assert_equal url, f.smooch_user_slack_channel_url
    end
  end

  test "should remove leading and trailing spaces from URLs when validating URL fields" do
    url = create_field_type field_type: 'url', label: 'URL'
    create_field_instance name: 'url', field_type_object: url
    f = nil
    assert_nothing_raised do
      f = create_field field_name: 'url', value: [{ 'url' => ' https://archive.org/web/  ' }]
    end
    assert_equal 'https://archive.org/web/', f.reload.value[0]['url']
  end

  test "should ignore permission check for changing status if previous value is empty" do
    create_verification_status_stuff
    pm = create_project_media
    a = create_dynamic_annotation annotation_type: 'verification_status', annotated: pm, set_fields: { verification_status_status: 'undetermined' }.to_json
    assert_equal 'undetermined', pm.reload.last_status
    f = a.get_field('verification_status_status')
    f.update_column(:value, [])
    f = DynamicAnnotation::Field.find(f.id)
    assert_nothing_raised do
      f.value = 'false'
      f.save!
    end
    assert_equal 'false', pm.reload.last_status
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

  def create_bot_response_field
    create_annotation_type_and_fields('Team Bot Response', { 'Raw Data' => ['JSON', true], 'Formatted Data' => ['Bot Response Format', false] })
  end
end
