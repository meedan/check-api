class TiplineMessagesPagination < GraphQL::Pagination::ArrayConnection
  def cursor_for(item)
    encode(item.id.to_i.to_s)
  end

  def load_nodes
    @nodes ||= begin
      sliced_nodes =  if before && after
                        end_idx = index_from_cursor(before)
                        start_idx = index_from_cursor(after)
                        items.where(id: start_idx..end_idx)
                      elsif before
                        end_idx = index_from_cursor(before)
                        items.where('id < ?', end_idx)
                      elsif after
                        start_idx = index_from_cursor(after)
                        items.where('id > ?', start_idx)
                      else
                        items
                      end

      @has_previous_page =  if last
                              # There are items preceding the ones in this result
                              sliced_nodes.count > last
                            elsif after
                              # We've paginated into the Array a bit, there are some behind us
                              index_from_cursor(after) > items.map(&:id).min
                            else
                              false
                            end

      @has_next_page =  if first
                          # There are more items after these items
                          sliced_nodes.count > first
                        elsif before
                          # The original array is longer than the `before` index
                          index_from_cursor(before) < items.map(&:id).max
                        else
                          false
                        end

      limited_nodes = sliced_nodes

      limited_nodes = limited_nodes.first(first) if first
      limited_nodes = limited_nodes.last(last) if last

      limited_nodes
    end
  end
end
