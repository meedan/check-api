require_relative '../test_helper'

class ReindexAlegreWorkspaceTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot(name: "alegre", login: "alegre")
    @bot.approve!
    team = create_team
    team.set_languages = ['en','pt','es']
    team.save!
    @bot.install_to!(team)
    @team = team
    @m = create_claim_media quote: 'I like apples'
    @pm = create_project_media team: @team, media: @m
    create_flag_annotation_type
    create_extracted_text_annotation_type
    @tbi = TeamBotInstallation.new
    @tbi.set_text_similarity_enabled = true
    @tbi.user = BotUser.alegre_user
    @tbi.team = @team
    @tbi.save
    Bot::Alegre.stubs(:get_alegre_tbi).returns(TeamBotInstallation.new)
    Sidekiq::Testing.inline!
    Bot::Alegre.stubs(:request).with('post', '/similarity/async/text', anything).returns("done")
  end

  def teardown
    super
    [@tbi, @pm, @m, @team, @bot].collect(&:destroy)
    Bot::Alegre.unstub(:get_alegre_tbi)
    Bot::Alegre.unstub(:request)
  end

  test "should trigger reindex" do
    assert_nothing_raised do
      ReindexAlegreWorkspace.perform_async(@team.id)
    end
  end

  test "checks cache_key" do
    assert_equal "check:migrate:reindex_event__a_b:pm_id", ReindexAlegreWorkspace.new.cache_key("a", "b")
  end

  test "checks cache_key functionality" do
    assert_equal "check:migrate:reindex_event__a_b:pm_id", ReindexAlegreWorkspace.new.cache_key("a", "b")
    assert_equal true, ReindexAlegreWorkspace.new.write_last_id("a", "b", 1)
    assert_equal 1, ReindexAlegreWorkspace.new.get_last_id("a", "b")
    assert_equal true, ReindexAlegreWorkspace.new.clear_last_id("a", "b")
  end

  test "makes sure get_default_query queries project medias" do
    assert_equal "project_medias", ReindexAlegreWorkspace.new.get_default_query(1, 0).table.name
  end

  test "checks alegre package in get_request_doc" do
    package = {
      :doc=>{
        :doc_id=>Bot::Alegre.item_doc_id(@pm, "title"),
        :text=>"Some text",
        :context=>{
          :team_id=>@pm.team_id,
          :project_media_id=>@pm.id,
          :has_custom_id=>true,
          :temporary_media=>false,
          :field=>"title"
        },
        :models=>["elasticsearch"],
        :requires_callback=>true
      },
      :type=>"text"
    }
    response = ReindexAlegreWorkspace.new.get_request_doc(@pm, "title", "Some text")
    assert_equal package, response
  end

  test "gets docs from get_request_docs_for_project_media" do
    docs = []
    ReindexAlegreWorkspace.new.get_request_docs_for_project_media(@pm) do |doc|
      docs << doc
    end
    assert_equal false, docs.empty?
  end

  test "runs the check_for_write" do
    response = ReindexAlegreWorkspace.new.check_for_write([], "a", @team.id)
    assert_equal Array, response.class
  end

  test "processes a team" do
    response = ReindexAlegreWorkspace.new.process_team([], @team.id, ReindexAlegreWorkspace.new.get_default_query(@team.id, 0), "a")
    assert_equal Array, response.class
  end
  
  test "tests the parallel request" do
    package = {
      :doc=>{
        :doc_id=>Bot::Alegre.item_doc_id(@pm, "title"),
        :text=>"Some text",
        :context=>{
          :team_id=>@pm.team_id,
          :project_media_id=>@pm.id,
          :has_custom_id=>true,
          :temporary_media=>false,
          :field=>"title"
        },
        :models=>["elasticsearch"]
      },
      :type=>"text"
    }
    response = ReindexAlegreWorkspace.new.check_for_write(1.upto(30).collect{|x| package}, "a", @team.id, true)
    assert_equal Array, response.class
  end

  test "reindexes all project_medias" do
    response = ReindexAlegreWorkspace.new.reindex_project_medias(ReindexAlegreWorkspace.new.get_default_query(@team.id, 0), "a")
    assert_equal Array, response.class
  end
end
