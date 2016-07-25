module ActiveRecordExtensions
  extend ActiveSupport::Concern

  # Used to migrate data from CD2 to this
  def image_callback(value)
    unless value.blank?
      uri = URI.parse(value)
      result = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
      if result.code.to_i < 400
        file = Tempfile.new
        file.binmode # note that our tempfile must be in binary mode
        file.write open(value).read
        file.rewind
        file
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)
