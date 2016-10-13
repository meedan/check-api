module Api
  module V1
    class SearchController < Api::V1::BaseApiController
      include SearchDoc

      skip_before_filter :authenticate_from_token!

      def create
        #keyword, filters = build_search_query(params[:query])
        filters = [{"term": { "annotation_type": "embed"}}]
        filters << {"term": { "annotator_id": "1"}}
        filters << {"term": { "context_id": "4"}}
        keyword = 'report title'
        result = Annotation.search query: {
          filtered: {
            query: {
              query_string: {
                query: keyword
              }
              },
              filter: {
                and: {
                  filters: [
                    filters
                  ]
                }
              }
            }
          }
        annotations = Array.new
        result.each do |obj|
          model = obj.annotated_type.singularize.camelize.constantize
          annotations << model.find(obj.annotated_id)
        end
        render json: { result: annotations }
      end

      def build_search_query(str)
        regex = /((\w+)\:(\w+)|\w+)/
        matches = str.scan regex
        filters = [{"term": { "annotation_type": "embed"}}]
        #filters << {"term": { "annotator_id": "1"}}
        matches.each do |data|
          if !data[1].nil?
            case data[0]
            when 'in:project'
              p = Project.where(title: data[2]).last
              filters << {"term": { "context_id": "4"}}
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
