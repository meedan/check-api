class Project < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :team
  has_many :project_sources
  has_many :sources , through: :project_sources
  has_many :project_medias
  has_many :medias , through: :project_medias

  mount_uploader :lead_image, ImageUploader
  validates_presence_of :title, :description

  has_annotations

  def user_id_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user.id
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def lead_image_callback(value, _mapping_ids = nil)
    unless value.blank?
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
