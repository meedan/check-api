# check that adding new suggested relation ships doesn't violate transitive similarity
require_relative '../../test_helper'

class Bot::AlegreRelationshipTest < ActiveSupport::TestCase
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
  end

    """    
    test 'should not replace when parent is blank' do
        p = create_project
        pm1 = create_project_media project: p, is_image: true
        pm2 = create_project_media project: p, media: Blank.new
        pm3 = create_project_media project: p, media: Blank.new
        assert_no_difference 'ProjectMedia.count' do
          assert_difference 'Relationship.count' do
            Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
          end
        end
      end
    """

    test 'item suggested to single other item will link' do
        p = create_project
        pm1 = create_project_media project: p
        pm2 = create_project_media project: p
        test_relationship = Bot::Alegre.add_relationships(pm2, {pm1.id => {score: 1, relationship_type: Relationship.suggested_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the appropriate ids
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm2)
    end

    test 'item confirmed to single other item will link' do
        p = create_project
        pm1 = create_project_media project: p
        pm2 = create_project_media project: p
        test_relationship = Bot::Alegre.add_relationships(pm2, {pm1.id => {score: 1, relationship_type: Relationship.confirmed_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the appropriate ids
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm2)
    end

    test 'item suggested to parent of confirmed pair will link' do
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm1.id => {score: 1, relationship_type: Relationship.suggested_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the appropriate ids
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm3)
    end

    test 'item confirmed to parent of confirmed pair will link' do
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm1.id => {score: 1, relationship_type: Relationship.confirmed_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the appropriate ids
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm3)
    end

    test 'item suggested to parent of suggested pair will link' do
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm1.id => {score: 1, relationship_type: Relationship.suggested_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the appropriate ids
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm3)
    end

    test 'item suggested to child of suggested pair will NOT link' do
        # this the new thing: don't chain suggestions
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.suggested_type}})
        # check that it was not created
        assert_nil( test_relationship)
        # check that it doesn't exist
        assert Relationship.where(target_id: pm2.id, source_id: pm3.id).first.nil?
 
    end

    test 'item confirmed to parent of suggested pair will link' do
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm1.id => {score: 1, relationship_type: Relationship.confirmed_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the appropriate ids
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm3)
    end

    test 'item confirmed to child of suggested pair will link and break relationship' do
        # because we are adding a stronger relationship to the child, 
        # the previous parent child relationship should be removed
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links to the child
        assert_equal( test_relationship.source, pm2)
        assert_equal( test_relationship.target, pm3)

        # check that the original link is removed
        assert Relationship.where(target_id: pm2.id, source_id: pm1.id).first.nil? 

    end

    test 'item confirmed to child of confirmed pair will link to parent' do
        # the links are good, but rewrite it as a link to the parent
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the parent (not the child)
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm3)
    end

    test 'item suggested to child of confirmed pair will link to parent' do
        # the links are good, but rewrite it as a link to the parent
        p = create_project
        pm1 = create_project_media project: p # parent
        pm2 = create_project_media project: p # child
        create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type

        pm3 = create_project_media project: p # the new item to be suggested
        test_relationship = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.suggested_type}})
        # check that it was created
        assert test_relationship.present?
        # check that it links the parent (not the child)
        assert_equal( test_relationship.source, pm1)
        assert_equal( test_relationship.target, pm3)
    end

  def teardown
    super
    Bot::Alegre.unstub(:media_file_url)
  end

end