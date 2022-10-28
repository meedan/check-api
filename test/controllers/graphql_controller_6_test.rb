require 'test_helper'

class GraphqlTests < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new

    super

    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil

    user = create_user
    authenticate_with_user(user)
  end

  def teardown
    super

    TracingService.unstub(:add_attribute_to_current_span)
  end

  test "on create: sends graphql query to observability provider" do
    query = 'query { search(query: "{}") { number_of_results } }'

    TracingService.expects(:add_attribute_to_current_span).with('app.graphql.query', query)
    
    post :create, params: { query: query }
  end

  test "on batch: sends graphql query to observability provider" do
    query = [
      { query: "query { team(slug: \"team-name\") { name } }", variables: {}, id: "q1" },
      { query: "query { team(slug: \"team-name\") { name } }", variables: {}, id: "q2" },
      { query: "query { team(slug: \"team-name\") { name } }", variables: {}, id: "q3" }
    ].to_json

    TracingService.expects(:add_attribute_to_current_span).with('app.graphql.query', query)
    
    post :batch, params: { _json: query }
  end
end
