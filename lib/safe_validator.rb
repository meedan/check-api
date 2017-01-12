class SafeValidator < ActiveModel::EachValidator
  def virus_found?(file)
    response = RestClient.post(CONFIG['clamav_service_path'], file: File.new(file.path), name: file.path.split('/').last)
    response.body.chomp == 'Everything ok : false'
  end

  def validate_each(record, attribute, value)
    if !value.nil? && !value.path.blank? && !CONFIG['clamav_service_path'].blank? && self.virus_found?(value)
      record.errors[attribute] << "validation failed! Virus was found."
    end
  end
end
