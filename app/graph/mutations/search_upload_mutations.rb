module SearchUploadMutations
  class SearchUpload < Mutations::BaseMutation
    field :file_handle, GraphQL::Types::String, null: true, camelize: false
    field :file_url, GraphQL::Types::String, null: true, camelize: false

    def resolve(**_inputs)
      hash = CheckSearch.upload_file(context[:file])
      file_path = "check_search/#{hash}"
      { file_handle: hash, file_url: CheckS3.public_url(file_path) }
    end
  end
end
