class Media < ApplicationRecord
  include AnnotationBase::Association

  self.inheritance_column = :type

  attr_accessor :disable_es_callbacks

  belongs_to :account, optional: true
  belongs_to :user, optional: true
  has_many :project_medias, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_annotations

  before_validation :set_type, :set_url_nil_if_empty, :set_user, on: :create

  after_create :set_uuid

  def self.types
    %w(Link Claim UploadedFile UploadedImage UploadedVideo UploadedAudio Blank)
  end

  validates_inclusion_of :type, in: Media.types

  def class_name
    'Media'
  end

  def team_ids
    self.project_medias.map(&:team_id)
  end

  def file_path
  end

  def self.filename(file, extension = true)
    hash = begin Digest::MD5.hexdigest(file.read) rescue nil end
    return hash unless extension
    file = file.try(:filename) || file.try(:path) || file.try(:tempfile) || file.try(:file)
    ext = File.extname(file)
    "#{hash}#{ext}"
  end

  def embed_path
    ''
  end

  def thumbnail_path
    ''
  end

  def picture
    ''
  end

  def text
    ''
  end

  def metadata
    begin JSON.parse(self.get_annotations('metadata').last.load.get_field_value('metadata_value')).with_indifferent_access rescue {} end
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def original_published_time
    ''
  end

  def media_type
    ''
  end

  def domain
    ''
  end

  private

  def set_url_nil_if_empty
    self.url = nil if self.url.blank?
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def self.class_from_input(input)
    type = nil
    if input[:url].blank?
      type = 'Claim' unless input[:quote].blank?
    else
      type = 'Link'
    end
    type
  end

  def set_type
    self.type = Media.class_from_input({ url: self.url, quote: self.quote }) if self.type.blank?
  end

  def set_uuid
    self.update_column(:uuid, self.id)
  end
end
