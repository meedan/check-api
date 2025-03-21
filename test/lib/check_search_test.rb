require_relative '../test_helper'

class CheckSearchTest < ActiveSupport::TestCase
  def setup
    @team = create_team
  end

  def teardown
  end

  test "should strip special characters from keyword parameter" do
    query = 'Something has increased 1000% last year'
    search = CheckSearch.new({ keyword: query }.to_json, nil, @team.id)
    assert_equal 'Something has increased 1000  last year', search.instance_variable_get('@options')['keyword']

    query = 'Something is going to happen on 04/11, reportedly'
    search = CheckSearch.new({ keyword: query }.to_json, nil, @team.id)
    assert_equal 'Something is going to happen on 04 11  reportedly', search.instance_variable_get('@options')['keyword']

    query = "Something is going to happen on Foo's house"
    search = CheckSearch.new({ keyword: query }.to_json, nil, @team.id)
    assert_equal "Something is going to happen on Foo's house", search.instance_variable_get('@options')['keyword']
  end

  test "should search for array field containing nil values" do
    search = CheckSearch.new({ users: [1, nil] }.to_json, nil, @team.id)
    assert_not_nil search.send(:doc_conditions)
  end

  test "should adjust social media filter" do
    search = CheckSearch.new({ show: ['social_media', 'images'] }.to_json, nil, @team.id)
    assert_equal ['images', 'twitter', 'youtube', 'tiktok', 'instagram', 'facebook', 'telegram'].sort, search.instance_variable_get('@options')['show'].sort
  end
end
