class TiplineMessagesPagination < GraphQL::Pagination::ArrayConnection
  def cursor_for(item)
    encode(item.id.to_i.to_s)
  end
end