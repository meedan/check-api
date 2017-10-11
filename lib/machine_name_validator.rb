class MachineNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.to_s.match(/\A([a-z_]+)\Z/).nil?
      record.errors[attribute] << "accepts only downcase letters and underscore (provided value was: '#{value}')"
    end
  end
end
