module Api
  module V1
    class SearchController < Api::V1::BaseApiController
      include SearchDoc

      skip_before_filter :authenticate_from_token!

      def create
        keyword, filters = build_search_query(params[:query])
        query = {
          filtered: { query: { query_string: { query: keyword } },
          filter: { and: { filters: [ filters ] } } }
        }
        aggs = { g: { terms: { field: :annotated_id } } }
        annotations = []
        Annotation.search(query: query, aggs: aggs).response['aggregations']['g']['buckets'].each do |result|
          annotations << Media.find(result['key'])
        end
        render json: { result: annotations }
      end

      def build_search_query(str)
        regex = /((\w+)\:(\w+)|\w+)/
        matches = str.scan regex
        keyword = ''
        filters = [{"term": { "annotation_type": "embed"}}]
        matches.each do |data|
          if !data[1].nil?
            case data[1]
            when 'in'
              p = Project.where(title: data[2]).last
              filters << {"term": { "context_id": p.id}} unless p.nil?
            when 'from'
              u = User.where(name: data[2]).last
              filters << {"term": { "annotator_id": u.id}} unless u.nil?
            end
          else
            keyword = data[0]
          end
        end
        return keyword, filters
      end

    end
  end
end
