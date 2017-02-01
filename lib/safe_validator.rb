class SafeValidator < ActiveModel::EachValidator
  def virus_found?(file)
    io = StringIO.new(File.read(file.path))
    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::InstreamCommand.new(io))
    response.class.name == 'ClamAV::VirusResponse'
  end

  def validate_each(record, attribute, value)
    if !value.nil? && !value.path.blank? && !CONFIG['clamav_service_path'].blank? && self.virus_found?(value)
      record.errors[attribute] << "validation failed! Virus was found."
    end
  end
end
