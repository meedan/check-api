class SizeValidator < ActiveModel::EachValidator
  DEFAULTS = {
    min_width: 200,
    max_width: 600,
    min_height: 200,
    max_height: 600
  }.with_indifferent_access

  def config(key)
    CONFIG["image_#{key}"] || DEFAULTS[key]
  end

  def invalid_size?(w, h)
    w < self.config('min_width') || w > self.config('max_width') || h < self.config('min_height') || h > self.config('max_height')
  end

  def validate_each(record, attribute, value)
    if !value.nil? && !value.path.blank?
      w, h = ::MiniMagick::Image.open(value.path)[:dimensions]
      record.errors[attribute] << "must be between #{self.config('min_width')}x#{self.config('max_width')} and #{self.config('min_height')}x#{self.config('max_height')} pixels" if invalid_size?(w, h)
    end
  end
end
