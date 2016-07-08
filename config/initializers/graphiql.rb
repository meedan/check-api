GraphiQL::Rails.config.query_params = true
GraphiQL::Rails.config.custom_script = '/javascripts/graphiql.js'
GraphiQL::Rails.config.initial_query = 'query me { me { name, provider } }'
