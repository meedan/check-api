require_relative '../../test_helper'

class Bot::Alegre2Test < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    b = create_alegre_bot(name: "alegre", login: "alegre")
    b.approve!
    @team = t = create_team
    t.set_languages = ['en','pt','es']
    t.save!
    b.install_to!(t)
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
    Bot::Alegre.stubs(:should_get_similar_items_of_type?).returns(true)
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    @media_path = random_url
    @params = { url: @media_path, context: { has_custom_id: true, team_id: @team.id }, threshold: 0.9, match_across_content_types: true }
  end

  def teardown
    super
    Bot::Alegre.unstub(:should_get_similar_items_of_type?)
  end

  test "should match similar videos" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    pm2 = create_project_media team: @team, media: create_uploaded_video
    pm3 = create_project_media team: @team, media: create_uploaded_video
    Bot::Alegre.stubs(:request_api).with('get', '/video/similarity/', @params, 'body').returns({
      result: [
        {
          context: [
            { team_id: @team.id.to_s, project_media_id: pm1.id.to_s }
          ],
          score: 0.971234,
          filename: '/app/persistent_disk/blah/12342.tmk'
        },
        {
          context: [
            { team_id: @team.id.to_s, project_media_id: pm2.id.to_s }
          ],
          score: 0.983167,
          filename: '/app/persistent_disk/blah/12343.tmk'
        }
      ]
    }.with_indifferent_access)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.983167
  end

  test "should match similar audios" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    pm3 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:request_api).with('get', '/audio/similarity/', @params, 'body').returns({
      result: [
        {
          id: 1,
          doc_id: random_string,
          chromaprint_fingerprint: [6581800, 2386744, 2583368, 2488648, 6343163, 14978026, 300191082, 309757210, 304525578, 304386106, 841261098, 841785386],
          url: 'https://foo.com/bar.wav',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm1.id.to_s }
          ],
          score: 0.971234,
        },
        {
          id: 2,
          doc_id: random_string,
          chromaprint_fingerprint: [2386744, 2583368, 2488648, 6343163, 14978026, 300191082, 309757210, 304525578, 304386106, 841261098, 841785386, 858042410, 825593963, 823509230],
          url: 'https://bar.com/foo.wav',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm2.id.to_s }
          ],
          score: 0.983167,
        }
      ]
    }.with_indifferent_access)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.983167
  end

  test "should match audio with similar audio from video" do
    p = create_project
    pm1 = create_project_media team: @team, media: create_uploaded_video
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    pm3 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:request_api).with('get', '/audio/similarity/', @params, 'body').returns({
      result: [
        {
          id: 2,
          doc_id: random_string,
          hash_value: '0111',
          url: 'https://foo.com/baz.mp4',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm1.id.to_s }
          ],
          score: 0.971234,
        },
        {
          id: 1,
          doc_id: random_string,
          hash_value: '0101',
          url: 'https://foo.com/bar.mp4',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm2.id.to_s, content_type: 'video' }
          ],
          score: 0.983167,
        }
      ]
    }.with_indifferent_access)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.983167
  end

  test "should match similar images" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    pm2 = create_project_media team: @team, media: create_uploaded_image
    pm3 = create_project_media team: @team, media: create_uploaded_image
    result = {
      result: [
        {
          id: 1,
          sha256: random_string(256),
          phash: random_string(72),
          url: 'https://foo.com/bar.png',
          context: [{
            team_id: @team.id.to_s,
            project_media_id: pm1.id.to_s
          }],
          score: 0.5
        },
        {
          id: 2,
          sha256: random_string(256),
          phash: random_string(72),
          url: 'https://bar.com/foo.png',
          context: [{
            team_id: @team.id.to_s,
            project_media_id: pm2.id.to_s
          }],
          score: 0.9
        }
      ]
    }.with_indifferent_access
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.89 }), 'body').returns(result)
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.95 }), 'body').returns(result)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.9
  end

  test "should handle similar items from different workspaces" do
    t2 = create_team
    t3 = create_team
    pm1a = create_project_media team: @team, media: create_uploaded_image
    pm2 = create_project_media team: t2, media: create_uploaded_image
    pm3 = create_project_media team: t3, media: create_uploaded_image
    pm4 = create_project_media media: create_uploaded_image
    pm1b = create_project_media team: @team, media: create_uploaded_image
    response = {
      result: [
        {
          id: pm4.id,
          sha256: random_string,
          phash: random_string,
          url: random_url,
          context: [
            {
              team_id: t2.id,
              has_custom_id: true,
              project_media_id: pm2.id
            },
            {
              team_id: @team.id,
              has_custom_id: true,
              project_media_id: pm1b.id
            },
            {
              team_id: t3.id,
              has_custom_id: true,
              project_media_id: pm3.id
            },
          ],
          score: 0
        }
      ]
    }.with_indifferent_access
    Bot::Alegre.stubs(:media_file_url).with(pm1a).returns(@media_path)
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.89 }), 'body').returns(response)
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.95 }), 'body').returns(response)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm1a)
    end
    Bot::Alegre.unstub(:request_api)
    assert_equal pm1b, Relationship.last.source
    assert_equal pm1a, Relationship.last.target
  end
end
