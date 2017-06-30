require_relative '../test_helper'

class FlagTest < ActiveSupport::TestCase
  test "should create flag" do
    assert_difference 'Flag.length' do
      create_flag
    end
  end

  test "should set type automatically" do
    f = create_flag
    assert_equal 'flag', f.annotation_type
  end

  test "should have flag" do
    assert_no_difference 'Flag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_flag(flag: nil)
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_flag(flag: '')
      end
    end
  end

  test "should create version when flag is created" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    f = nil
    with_current_user_and_team(u, t) do
      f = create_flag(flag: 'Spam', annotated: pm)
    end
    assert_equal 1, f.versions.count
    v = f.versions.last
    assert_equal 'create', v.event
    assert_equal({"data"=>[{}, {"flag"=>"Spam"}], "annotator_type"=>[nil, "User"], "annotated_type"=>[nil, "ProjectMedia"], "annotated_id"=>[nil, pm.id], "annotator_id"=>[nil, f.annotator_id], "annotation_type"=>[nil, "flag"]}, v.changeset)
  end

  test "should create version when flag is updated" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    f = nil
    with_current_user_and_team(u, t) do
      f = create_flag(flag: 'Spam', annotated: pm)
      f = Flag.last
      f.flag = 'Graphic content'
      f.save
      assert_equal 2, f.versions.count
      v = PaperTrail::Version.last
      assert_equal 'update', v.event
      assert_equal({"data"=>[{"flag"=>"Spam"}, {"flag"=>"Graphic content"}]}, v.changeset)
    end
  end

  test "should get columns as array" do
    assert_kind_of Array, Flag.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, Flag.columns_hash
  end

  test "should not be abstract" do
    assert_not Flag.abstract_class?
  end

  test "should have content" do
    f = create_flag
    assert_equal ['flag'], JSON.parse(f.content).keys
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

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    p = create_project team: t
    create_team_user team: t, user: u2, role: 'contributor'
    pm = create_project_media project: p
    with_current_user_and_team(u2, t) do
      f = create_flag annotated: pm, annotator: nil
      assert_equal u2, f.annotator
    end
  end

  test "should not set annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    p  = create_project team: t
    create_team_user team: t, user: u2, role: 'contributor'
    m = create_valid_media team: t, user: u2
    pm = create_project_media project: p, user: u2
    with_current_user_and_team(u2, t) do
      f = create_flag annotated: pm, annotator: u1
      assert_equal u1, f.annotator
    end
  end

  test "should not create flag with invalid value" do
    assert_no_difference 'Flag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_flag flag: 'invalid'
      end
    end
    assert_difference 'Flag.length' do
      create_flag flag: 'Spam'
    end
  end

  test "should not create flag with invalid annotated" do
    assert_no_difference 'Flag.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_flag annotated: create_project
      end
    end
  end

 test "should get flag" do
    f = create_flag
    assert_equal 'Graphic content', f.flag_callback('graphic_journalist')
    assert_equal 'Invalid', f.flag_callback('Invalid')
  end

  test "should accept only ProjectMedia as annotated_type" do
    assert_equal ['ProjectMedia'], Flag.annotated_types
  end

  test "should protect attributes from mass assignment" do
    raw_params = { flag: 'Spam', annotated: create_project_media }

    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Flag.create(params)
    end
  end

end
