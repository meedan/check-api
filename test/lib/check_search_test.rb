require_relative '../test_helper'

class TeamStatisticsTest < ActiveSupport::TestCase
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
  end
end
