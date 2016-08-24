class SizeValidator < ActiveModel::EachValidator
  def invalid_size?(w, h)
    w < 200 || w > 600 || h < 200 || h > 600
  end

  def validate_each(record, attribute, value)
    if !value.nil? && !value.path.blank?
      w, h = ::MiniMagick::Image.open(value.path)[:dimensions]
      record.errors[attribute] << "must be between 200 x 200 and 600 x 600 pixels" if invalid_size?(w, h)
    end
  end
end
