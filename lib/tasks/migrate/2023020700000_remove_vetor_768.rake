require 'net/http'
require 'json'
require 'pp'

namespace :check do
    namespace :migrate do
  
      # run this task inside check-api container with 
      # `bundle exec rake check:migrate:remove_vector_768_and_reindex['https://ES_URL','USER','PWD']``

      desc 'trigger reindexing of ProjectMedia that only have deprecated vector_768 index'
      task :remove_vector_768_and_reindex, [:es_url, :es_user, :es_pwd] => :environment do |t, args|
        MIGRATION_TASK_ID = 'remove_vector_768_and_reindex'
        ES_URL = args[:es_url]
        ES_USER = args[:es_user]
        ES_PWD = args[:es_pwd]

        puts("Will connect to Alegre ElasticSearch using #{ES_URL} and user #{ES_USER}") 
        WRITE_LIMIT = 5 # for testing, this should limit how many changes will be made
        BATCH_SIZE = 5  # TODO: lets use 2500 in live, to match batch size in reindex_alegre_workspace.rb

        ES_QUERY_PATH = "/alegre_similarity/_search?pretty&size=#{BATCH_SIZE}"

        # query intention:
        # find documents that have the vector_768 but not the other 3 vector index types
        # and format in the context team id to facet by workspace
        # and return only the project_media and team_id fields from context
        # we are using a sort index and paginiated search results because greater than 10k hits in live
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html#search-after

        QUERY_PAYLOAD = '
        {
          "sort" : [
            {"created_at": "asc"}
          ],
          "search_after": [%d],
          "query": {
            "bool": {
              "filter": [
                {
                  "exists": {
                    "field": "vector_768"
                  }
                },
                {
                  "nested": {
                    "path": "context",
                    "query": {
                      "term": {"context.team_id": %d}
                    }
                  }
                },
                {
                  "bool":{
                    "must_not":[
                      {
                        "exists": {
                          "field": "vector_xlm-r-bert-base-nli-stsb-mean-tokens"
                        }
                      },
                      {
                        "exists": {
                          "field": "vector_indian-sbert"
                        }
                      },
                      {
                        "exists": {
                          "field": "vector_paraphrase-filipino-mpnet-base-v2"
                        }
                      }
                    ]
                  }
                }
              ]
            }
          },
          "_source": ["context.project_media_id","context.team_id"]
          }
        '
        # TODO: need to add sorting and sortafter params to query

        updated_count = 0
        # loop over the team ids, so we can chunk up by team workspace
        BotUser.alegre_user.team_bot_installations.find_each do |tb|

          # DEBUG: hardcode the team id because only [1,2] in local dev
          tb.team_id = 30

          # we can't use Bot::Alegre.request_api because that talks to postgres and doesn't know about ES indexes
          # so we are directly constructing an ES query to find the records we need to reindex
          # NOTE: this is not how we should normally talk to ES, use the Alegre service endpoint instead if possible
          query_url = ES_URL + ES_QUERY_PATH
          uri = URI.parse(query_url)
          puts "[#{Time.now}] Starting fetching context list from ES for team_id :#{tb.team_id} "

          req = Net::HTTP::Post.new(uri)
          req.basic_auth(ES_URL, ES_PWD)
          req['Content-Type'] = 'application/json'

          # keep track of max sort id for ES pagination
          max_sort_id = 0

          # format the pagination state and team id into the es query
          req.body = QUERY_PAYLOAD % [max_sort_id, tb.team_id]

          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme=='https') do |http|
            http.request(req)
          end
          # debug
          # puts(res.body)
          # #TODO need to handle connection errors
          result_obj = JSON.parse(res.body)
          #puts(result_obj.inspect)
          items = result_obj['hits']['hits']

          puts("\tFound #{items.length} items with only old index")
          # if no hits, skip to next team
          next if items.length < 1
           
          pm_ids = []
          # loop over all the contexts in the chunk to extract the pm_ids to reindex
          items.each do |item|
            pp(item)
            # keep track of ES sort id for pagination
            sort_id = item['sort'][0]
            max_sort_id = [max_sort_id,sort_id].max 

            # there are some funky objects in qa, so skip if no context
            if item['_source']['context'].nil?
                puts("\t\tskipping item because missing context")
                next
            end
            
            team_id = item['_source']['context']['team_id']
            # just being careful in case the query gets messed up
            raise 'Team ids in context did not match chunk team id' unless team_id == tb.team_id
            pm_id = item['_source']['context']['project_media_id']
            pm_ids.append(pm_id)

          end

          # need to dedupe list because the same media will be indexed several different ways
          pm_ids = pm_ids.uniq
        if updated_count+pm_ids.length > WRITE_LIMIT 
          abort("stopping reindex because write limit of #{WRITE_LIMIT} would be exceeded")
        end

        puts("reindexing project media ids #{pm_ids} for team_id #{tb.team_id}")
        # we will use ReindexAlegreWorkspace run_reindex, pushing one team at a time
        # because ProjectMedia ids are only unique within team
        query = ProjectMedia.where(team_id: tb.team_id).where(id: pm_ids)
        ReindexAlegreWorkspace.new.run_reindex(query, MIGRATION_TASK_ID)
        updated_count+=pm_ids.length 

        end   # end team loop
        puts("reindexing complete with #{updated_count} updates requested")
      end
    end
  end