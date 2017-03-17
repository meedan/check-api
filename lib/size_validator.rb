class SizeValidator < ActiveModel::EachValidator
  DEFAULTS = {
    min_width: 200,
    max_width: 600,
    min_height: 200,
    max_height: 600
  }.with_indifferent_access

  def self.config(key)
    CONFIG["image_#{key}"] || DEFAULTS[key]
  end

  def invalid_size?(w, h)
    w < SizeValidator.config('min_width') ||
    w > SizeValidator.config('max_width') ||
    h < SizeValidator.config('min_height') ||
    h > SizeValidator.config('max_height')
  end

  def validate_each(record, attribute, value)
    if !value.nil? && !value.path.blank?
      w, h = ::MiniMagick::Image.open(value.path)[:dimensions]
      record.errors[attribute] << I18n.t(:"errors.messages.invalid_size",
        min_width: SizeValidator.config('min_width'),
        min_height: SizeValidator.config('min_height'),
        max_width: SizeValidator.config('max_width'),
        max_height: SizeValidator.config('max_height')
      ) if invalid_size?(w, h)
    end
  end
end
