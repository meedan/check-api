class IncludedValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    values = options[:values]
    unless values.include?(value) 
      record.errors[attribute] << "must be one of: #{values.join(', ')}"
    end
  end
end
