class Hash
  def deep_reject_key!(key)
    keys.each { |k| delete(k) if k == key || self[k] == self[key] }
    values.each { |v| v.deep_reject_key!(key) if v.is_a? Hash }
    self
  end
end
