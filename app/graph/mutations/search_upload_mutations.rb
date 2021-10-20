module SearchUploadMutations
  SearchUpload = GraphQL::Relay::Mutation.define do
    name 'SearchUpload'

    return_field :file_handle, types.String

    resolve -> (_result, _input, ctx) {
      hash = CheckSearch.upload_file(ctx[:file])
      return { file_handle: hash }
    }
  end
end
