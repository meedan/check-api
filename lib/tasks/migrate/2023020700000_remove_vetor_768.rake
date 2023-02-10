require 'net/http'
require 'json'
require 'pp'

namespace :check do
    namespace :migrate do
  
      # run this task inside check-api container with `bundle exec rake check:migrate:remove_vector_768_and_reindex['https://ES_URL','USER','PWD']``

      desc 'trigger reindexing of ProjectMedia that only have deprecated vector_768 index'
      task :remove_vector_768_and_reindex, [:es_url, :es_user, :es_pwd] => :environment do |t, args|
        MIGRATION_TASK_ID = 'remove_vector_768_and_reindex'
        ES_URL = args[:es_url]
        ES_USER = args[:es_user]
        ES_PWD = args[:es_pwd]

        puts("Will connect to Alegre ElasticSearch using #{ES_URL} and user #{ES_USER}") 

        CHUNK_SIZE = 5
        # TODO: looks like we will need to use colling instead of window because greater than 10k hits
        # https://www.elastic.co/guide/en/elasticsearch/reference/current/scroll-api.html
        from = 0
        ES_QUERY_PATH = "/alegre_similarity/_search?pretty&from=#{from}&size=#{CHUNK_SIZE}"

        # find documents that have the vector_768 but not the other 3 vector index types
        # and format in the context team id to facet by workspace
        # and return only the project_media and team_id fields from context
        QUERY_PAYLOAD = '
        {
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

        # loop over the team ids, so we can chunk up by team workspace
        BotUser.alegre_user.team_bot_installations.find_each do |tb|

          # DEBUG: hardcode the team id because only [1,2] in local dev
          tb.team_id = 30


          # we can't use Bot::Alegre.request_api because that talks to postgres and doesn't know about ES indexes
          # so we are directly constructing an ES query to find the records we need to reindex
          query_url = ES_URL + ES_QUERY_PATH
          uri = URI.parse(query_url)
          puts "[#{Time.now}] Starting fetching context list from ES for team_id :#{tb.team_id} "

          req = Net::HTTP::Post.new(uri)
          # TODO: auth creds are per env
          req.basic_auth(ES_URL, ES_PWD)
          req['Content-Type'] = 'application/json'

          # format the team id into the es query
          req.body = QUERY_PAYLOAD % [tb.team_id]

          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(req)
          end
          # debug
          # puts(res.body)
          # #TODO need to handle connection errors
          result_obj = JSON.parse(res.body)
          items = result_obj['hits']['hits']
          
          # puts(items)
          puts("\tFound #{items.length} items with only old index")
          # if no hits, skip to next team
          next if items.length < 1
           
          pm_ids = []
          # loop over all the contexts in the chunk to extract the pm_ids to reindex
          # TODO: probably repalce with list comprehension .. but some objects messy
          items.each do |item|
            pp(item)
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

            # fetch the ProjectMedia object from team and media ids
            # pm = ProjectMedia.where(team_id: team_id).where("project_medias.id = ? ", pm_id)
            # pp(pm)

          end

          # TODO: need to dedupe list because the same media will be indexed several different ways
          if pm_ids.uniq.length < pm_ids.length
            puts("\tfound duplicate ProjectMedia ids for team #{pm_ids}")
          end 
          pm_ids = pm_ids.uniq

        puts("reindexing project media ids #{pm_ids} for team_id #{tb.team_id}")
        # we will use ReindexAlegreWorkspace run_reindex, pushing one team at a time
        # because ProjectMedia ids are only unique within team
        query = ProjectMedia.where(team_id: tb.team_id).where(id: pm_ids)
        ReindexAlegreWorkspace.new.run_reindex(query, MIGRATION_TASK_ID)

        #TODO: how do we know status
        
        end
      end
    end
  end