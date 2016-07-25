class Team < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  has_many :projects
  has_many :team_users
  has_many :users, through: :team_users
  mount_uploader :logo, ImageUploader
  validates_presence_of :name, :description

  has_annotations

  def logo_callback(value, _mapping_ids = nil)
    unless value.blank?
      uri = URI.parse(value)
      result = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.path) }
      if result.code.to_i < 400
        extn = File.extname  value
        name = File.basename value, extn
        file = Tempfile.new [name, ".#{value.split('.').last}"]
        file.binmode # note that our tempfile must be in binary mode
        file.write open(value).read
        file.rewind
        file
      end
    end
  end

end
