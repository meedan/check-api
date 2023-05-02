class IncludedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    values = options[:values]
    unless values.include?(value)
      record.errors.add(attribute.to_sym, "must be one of: #{values.join(', ')}")
    end
  end
end
