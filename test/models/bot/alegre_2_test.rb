require_relative '../../test_helper'

class Bot::Alegre2Test < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot(name: "alegre", login: "alegre")
    @bot.approve!
    p = create_project
    p.team.set_languages = ['en','pt','es']
    p.team.save!
    @bot.install_to!(p.team)
    @team = p.team
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media project: p, media: m
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
    Bot::Alegre.stubs(:should_get_similar_items_of_type?).returns(true)
  end

  def teardown
    super
    Bot::Alegre.unstub(:should_get_similar_items_of_type?)
  end

  test "should relate project media to similar items as video" do
    p = create_project
    pm1 = create_project_media team: @pm.team
    pm1 = create_project_media project: p, media: create_uploaded_video
    pm2 = create_project_media project: p, media: create_uploaded_video
    pm3 = create_project_media project: p, media: create_uploaded_video
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "context"=>[
            {"team_id"=>pm1.team.id.to_s, "project_media_id"=>pm1.id.to_s}
          ],
          "score"=>"0.983167",
          "filename"=>"/app/persistent_disk/blah/12342.tmk"
        },
        {
          "context"=>[
            {"team_id"=>pm2.team.id.to_s, "project_media_id"=>pm2.id.to_s}
          ],
          "score"=>"0.983167",
          "filename"=>"/app/persistent_disk/blah/12343.tmk"
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm1, r.source
    assert_equal r.weight, 0.983167
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should relate project media to similar items as audio" do
    p = create_project
    pm1 = create_project_media team: @pm.team
    pm1 = create_project_media project: p, media: create_uploaded_audio
    pm2 = create_project_media project: p, media: create_uploaded_audio
    pm3 = create_project_media project: p, media: create_uploaded_audio
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "id" => 1,
          "doc_id" => "blah",
          "hash_value" => "0101",
          "url" => "https://foo.com/bar.wav",
          "context"=>[
            {"team_id"=>pm1.team.id.to_s, "project_media_id"=>pm1.id.to_s}
          ],
          "score"=>"0.983167",
        },
        {
          "id" => 2,
          "doc_id" => "blah2",
          "hash_value" => "0111",
          "url" => "https://foo.com/baz.wav",
          "context"=>[
            {"team_id"=>pm2.team.id.to_s, "project_media_id"=>pm2.id.to_s}
          ],
          "score"=>"0.983167",
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm1, r.source
    assert_equal r.weight, 0.983167
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should relate project media to similar items as audio and also include audio from videos" do
    p = create_project
    pm1 = create_project_media team: @pm.team
    pm1 = create_project_media project: p, media: create_uploaded_video
    pm2 = create_project_media project: p, media: create_uploaded_audio
    pm3 = create_project_media project: p, media: create_uploaded_audio
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "id" => 1,
          "doc_id" => "blah",
          "hash_value" => "0101",
          "url" => "https://foo.com/bar.mp4",
          "context"=>[
            {"team_id"=>pm1.team.id.to_s, "project_media_id"=>pm1.id.to_s, "content_type" => "video"}
          ],
          "score"=>"0.983167",
        },
        {
          "id" => 2,
          "doc_id" => "blah2",
          "hash_value" => "0111",
          "url" => "https://foo.com/baz.mp4",
          "context"=>[
            {"team_id"=>pm2.team.id.to_s, "project_media_id"=>pm2.id.to_s}
          ],
          "score"=>"0.983167",
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm1, r.source
    assert_equal r.weight, 0.983167
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should relate project media to similar items" do
    p = create_project
    pm1 = create_project_media project: p, media: create_uploaded_image
    pm2 = create_project_media project: p, media: create_uploaded_image
    pm3 = create_project_media project: p, media: create_uploaded_image
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "id" => 1,
          "sha256" => "1782b1d1993fcd9f6fd8155adc6009a9693a8da7bb96d20270c4bc8a30c97570",
          "phash" => 17399941807326929,
          "url" => "https:\/\/www.gstatic.com\/webp\/gallery3\/1.png",
          "context" => [{
            "team_id" => pm2.team.id.to_s,
            "project_media_id" => pm2.id.to_s
          }],
          "score" => 1.0
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 1
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
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
    Bot::Alegre.stubs(:request_api).returns(response)
    assert_nothing_raised do
      assert_difference 'Relationship.count' do
        Bot::Alegre.relate_project_media_to_similar_items(pm1a)
      end
    end
    assert_equal pm1b, Relationship.last.source
    assert_equal pm1a, Relationship.last.target
    Bot::Alegre.unstub(:request_api)
  end
end
