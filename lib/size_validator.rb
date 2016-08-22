class SizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.nil?
      path = value.path
      unless path.blank?
        w, h = ::MiniMagick::Image.open(path)[:dimensions]
        if w < 200 || w > 600 || h < 200 || h > 600
          record.errors[attribute] << "must be between 200 x 200 and 600 x 600 pixels"
        end
      end
    end
  end
end
