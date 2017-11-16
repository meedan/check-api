require_relative '../test_helper'

class SourceIdentityTest < ActiveSupport::TestCase
  
  test "should create source identity" do
    assert_difference 'SourceIdentity.length' do
      create_source_identity
    end
  end

  test "should have name" do
    assert_no_difference 'SourceIdentity.length' do
      assert_raise ActiveRecord::RecordInvalid do
        create_source_identity(name: nil)
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_source_identity(name: '')
      end
    end
  end

  test "should be unique" do
    t = create_team
    name = 'testing'
    s = create_source team: t, name: name
    assert_difference 'SourceIdentity.length' do
      create_source_identity name: name, annotated: s
    end
    assert_no_difference 'SourceIdentity.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity name: name, annotated: create_source
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity name: name.upcase, annotated: create_source
      end
    end
  end

  test "should create version when source identity is created" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    ts = create_team_source team: t
    with_current_user_and_team(u, t) do
      si = create_source_identity(name: 'test', annotated: ts)
      assert_equal 1, si.versions.count
      v = si.versions.last
      assert_equal 'create', v.event
    end
  end

  test "should create version when source identity is updated" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    ts = create_team_source team: t
    with_current_user_and_team(u, t) do
      si = create_source_identity(name: 'foo', bio: 'foo', annotated: ts, annotator: u)
      si = SourceIdentity.last
      si.name = 'bar'; si.bio = 'bar'
      si.disable_es_callbacks = true
      si.save!
      assert_equal 2, si.versions.count
      v = PaperTrail::Version.last
      assert_equal 'update', v.event
      assert_equal({"data"=>[{"name"=>"foo", "bio"=> "foo"}, {"name"=>"bar", "bio" => "bar"}]}, v.changeset)
    end
  end

  test "should get columns as array" do
    assert_kind_of Array, SourceIdentity.columns
  end

  test "should get columns as hash" do
    assert_kind_of Hash, SourceIdentity.columns_hash
  end

  test "should not be abstract" do
    assert_not SourceIdentity.abstract_class?
  end

  test "should have content" do
    si = create_source_identity
    assert_equal ['name', 'bio'], JSON.parse(si.content).keys
  end

  test "should have annotators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_team_source
    s2 = create_team_source
    create_source_identity annotator: u1, annotated: s1
    create_source_identity annotator: u1, annotated: s1
    create_source_identity annotator: u1, annotated: s1
    create_source_identity annotator: u2, annotated: s1
    create_source_identity annotator: u2, annotated: s1
    create_source_identity annotator: u3, annotated: s2
    create_source_identity annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.annotators.sort
    assert_equal [u3].sort, s2.annotators.sort
  end

  test "should set annotator if not set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'contributor'
    ts = create_team_source team: t
    u2 = User.find(u2.id)

    with_current_user_and_team(u2, t) do
      si = create_source_identity annotator: nil, annotated: ts
      assert_equal u2, si.annotator
    end
  end

  test "should not set annotator if set" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u2, role: 'contributor'
    ts = create_team_source team: t
    with_current_user_and_team(u2, t) do
      si = create_source_identity annotated: ts, annotator: u1
      assert_equal u1, si.annotator
    end
  end

  test "should destroy source identity" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    ts = create_team_source team: t
    si = create_source_identity annotated: ts, annotator: u
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        si.destroy
      end
    end
  end

  test "should have image" do
    si = nil
    assert_difference 'SourceIdentity.length' do
      si = create_source_identity file: 'rails.png'
    end
    assert_not_nil si.file
  end

  test "should not upload a file that is not an image" do
    assert_no_difference 'SourceIdentity.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity file: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big image" do
    assert_no_difference 'SourceIdentity.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity file: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small image" do
    assert_no_difference 'SourceIdentity.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity file: 'ruby-small.png'
      end
    end
  end

  test "should have public path" do
    t = create_source_identity file: 'rails.png'
    assert_match /^http/, t.public_path
  end

  test "should not upload a heavy image" do
    assert_no_difference 'SourceIdentity.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity file: 'rails-photo.jpg'
      end
    end
  end

  test "should create versions" do
    i = create_source_identity file: 'rails.png'
    assert_not_nil i.file.thumbnail
    assert_not_nil i.file.embed
  end

  test "should not upload corrupted file" do
    assert_no_difference 'SourceIdentity.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source_identity file: 'corrupted-image.png'
      end
    end
  end

  test "should have image data" do
    si1 = create_source_identity file: 'rails.png'
    a1 = Annotation.find(si1.id).image_data
    assert a1.has_key?(:embed)
    assert a1.has_key?(:thumbnail)
    si2 = create_source_identity
    a2 = Annotation.find(si2.id).image_data
    assert_equal({}, a2)
  end

end
