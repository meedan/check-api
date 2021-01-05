GraphiQL::Rails.config.query_params = true
GraphiQL::Rails.config.custom_script = '/javascripts/graphiql.js'
GraphiQL::Rails.config.initial_query = 'query me { me { name, provider } }'
GraphiQL::Rails.config.headers ||= {}
GraphiQL::Rails.config.headers[CheckConfig.get('authorization_header')] = -> (context) {
  context.params[:api_key].blank? ? nil : context.params[:api_key]
}
GraphiQL::Rails.config.headers['X-Check-Team'] = -> (context) {
  context.params[:team_slug].blank? ? nil : context.params[:team_slug]
}
