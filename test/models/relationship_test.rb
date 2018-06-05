require_relative '../test_helper'

class RelationshipTest < ActiveSupport::TestCase
  def setup
    super
    Relationship.delete_all
  end

  test "should create relationship" do
    assert_difference 'Relationship.count' do
      create_relationship
    end
  end

  test "should have source" do
    pm = create_project_media
    r = create_relationship source_id: pm.id
    assert_equal pm, r.source
  end

  test "should have target" do
    pm = create_project_media
    r = create_relationship target_id: pm.id
    assert_equal pm, r.target
  end

  test "should serialize flags" do
    r = create_relationship
    assert_kind_of Array, r.flags
  end

  test "should not save if source is missing" do
    assert_raises ActiveRecord::StatementInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship source_id: nil
      end
    end
  end

  test "should not save if target is missing" do
    assert_raises ActiveRecord::StatementInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship target_id: nil
      end
    end
  end

  test "should not save if type is missing" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship kind: nil
      end
    end
  end

  test "should have a valid kind" do
    assert_difference 'Relationship.count' do
      create_relationship kind: 'part_of'
    end
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship kind: 'invalid'
      end
    end
  end

  test "should have valid flags" do
    assert_difference 'Relationship.count', 4 do
      create_relationship flags: ['commutative', 'transitive']
      create_relationship flags: ['commutative']
      create_relationship flags: ['transitive']
      create_relationship flags: []
    end
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'Relationship.count' do
        create_relationship flags: ['foo', 'commutative', 'transitive']
        create_relationship flags: ['bar']
      end
    end
  end

  test "should get related reports based on relationship flags" do
    pm1 = create_project_media
    pm2 = create_project_media
    pm3 = create_project_media
    pm4 = create_project_media
    pm5 = create_project_media
    pm6 = create_project_media
    pm7 = create_project_media
    create_relationship source_id: pm1.id, target_id: pm2.id, flags: ['transitive']
    create_relationship source_id: pm1.id, target_id: pm6.id, flags: []
    create_relationship source_id: pm2.id, target_id: pm3.id, flags: []
    create_relationship source_id: pm6.id, target_id: pm7.id, flags: []
    create_relationship source_id: pm4.id, target_id: pm1.id, flags: ['commutative']
    create_relationship source_id: pm5.id, target_id: pm1.id, flags: []
    assert_equal [pm2, pm3, pm4, pm6].map(&:id).sort, pm1.related_reports.map(&:id).sort
  end

  test "should destroy relationships when project media is destroyed" do
    pm = create_project_media
    create_relationship source_id: pm.id
    create_relationship target_id: pm.id
    assert_difference 'Relationship.count', -2 do
      pm.destroy
    end
  end
end
