module SearchUploadMutations
  SearchUpload = GraphQL::Relay::Mutation.define do
    name 'SearchUpload'

    return_field :file_handle, types.String
    return_field :file_url, types.String

    resolve -> (_result, _input, ctx) {
      hash = CheckSearch.upload_file(ctx[:file])
      file_path = "check_search/#{hash}"
      { file_handle: hash, file_url: CheckS3.public_url(file_path) }
    }
  end
end
