require 'test_helper'

class GraphqlTests < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    @exporter.recording = true

    super

    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil

    user = create_user
    authenticate_with_user(user)

    @exporter.reset
  end

  def teardown
    @exporter.recording = false
  end

  test "on create: sends graphql query to observability provider" do
    query = 'query { search(query: "{}") { number_of_results } }'

    post :create, params: { query: query }

    graphql_query_spans = @exporter.finished_spans.select{|span| span.attributes.has_key?('app.graphql.query')}
    assert graphql_query_spans.length > 0
    assert_equal query, graphql_query_spans.last['app.graphql.query']
  end

  test "on batch: sends graphql query to observability provider" do
    query = [
      { query: "query { team(slug: \"team-name\") { name } }", variables: {}, id: "q1" },
      { query: "query { team(slug: \"team-name\") { name } }", variables: {}, id: "q2" },
      { query: "query { team(slug: \"team-name\") { name } }", variables: {}, id: "q3" }
    ]

    post :batch, params: { _json: query.to_json }

    graphql_query_spans = @exporter.finished_spans.select{|span| span.attributes.has_key?('app.graphql.query')}
    assert graphql_query_spans.length > 0
    assert_equal query, graphql_query_spans.last['app.graphql.query']
  end
end
