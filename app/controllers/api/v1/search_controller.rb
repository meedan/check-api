module Api
  module V1
    class SearchController < Api::V1::BaseApiController
      include SearchDoc

      skip_before_filter :authenticate_from_token!

      def create
        #keyword, filters = build_search_query(params[:query])
        options = {keyword: 'title_context_a', project: 'testingtesting', tag: 'sports'}
        querya_ids = build_search_query_a(options)
        queryb_ids = build_search_query_b(options)
        ids = querya_ids & queryb_ids
        result = Array.new
        ids.each {|id| result << Media.find(id)}
        render json: { result: result }
      end

      def build_search_query_a(options)
        keyword = options.has_key?(:keyword) ? options[:keyword] : ''
        filters = [{"term": { "annotation_type": "embed"}}]
        filters << {"term": { "annotated_type": "media"}}
        if options.has_key?(:project)
          p = Project.where(title: options[:project]).last
          filters << {"term": { "context_id": p.id}} unless p.nil?
        end
        if options.has_key?(:from)
          u = User.where(name: options[:from]).last
          filters << {"term": { "annotator_id": u.id}} unless u.nil?
        end
        # data filter
        #filters <<  {"range": { "published_at": { "from": options[:from], "to": options[:to]}}}
        query = {
          filtered: {
            query: { query_string: { query: keyword } },
            filter: { bool: { must: [ filters ] } }
          }
        }
        get_query_result(query)
      end

      def build_search_query_b(options)
        filters = Array.new
        if options.has_key?(:tag)
          filters << [{"term": { "tag": options[:tag]}}]
        end
        query = {
          filtered: {
            query: { match_all: {} },
            filter: {bool: {should: filters  } }
          }
        }
        get_query_result(query)
      end


      def get_query_result(query)
        g = {
          annotated: {
            terms: { field: :annotated_id },
            aggs: { type: { terms: { field: :annotated_type } } }
          }
        }
        ids = []
        Annotation.search(query: query, aggs: g).response['aggregations']['annotated']['buckets'].each do |result|
          #model = result['type']['buckets']['key'].singularize.camelize.constantize
          #annotations << Media.find(result['key'])
          ids << result['key']
        end
        ids
      end

    end
  end
end
