require_relative '../test_helper'

class MontageProjectTest < ActiveSupport::TestCase
  test "should return name" do
    p = create_project title: 'Foo'
    p = p.extend(Montage::Collection)
    assert_equal 'Foo', p.name
  end

  test "should return project id" do
    t = create_team
    p = create_project team: t
    p = p.extend(Montage::Collection)
    assert_equal t.id, p.project_id
  end
end 
