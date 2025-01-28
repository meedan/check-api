class Media < ApplicationRecord
  include AnnotationBase::Association

  self.inheritance_column = :type

  attr_accessor :disable_es_callbacks

  belongs_to :account, optional: true
  belongs_to :user, optional: true
  has_many :project_medias, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_annotations

  before_validation :set_type, :set_url_nil_if_empty, :set_user, :set_original_claim_hash, on: :create

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

  def self.find_or_create_from_original_claim(claim, project_media_team)
    if claim.match?(/\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/)
      uri = URI.parse(claim)
      content_type = fetch_content_type(uri)
      ext = File.extname(uri.path)

      case content_type
      when /^image\//
        create_uploaded_file_media_from_url('UploadedImage', claim, ext)
      when /^video\//
        create_uploaded_file_media_from_url('UploadedVideo', claim, ext)
      when /^audio\//
        create_uploaded_file_media_from_url('UploadedAudio', claim, ext)
      else
        create_link_media(claim, project_media_team)
      end
    else
      create_claim_media(claim)
    end
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

  def set_original_claim_hash
    self.original_claim_hash = Digest::MD5.hexdigest(original_claim) unless self.original_claim.blank?
  end

  def self.fetch_content_type(uri)
    response = Net::HTTP.get_response(uri)
    response['content-type']
  end

  def self.create_uploaded_file_media_from_url(media_type, url, ext)
    klass = media_type.constantize
    file = download_file(url, ext)
    existing_media = klass.find_by(original_claim_hash: Digest::MD5.hexdigest(url))

    if existing_media
      existing_media
    else
      klass.create!(file: file, original_claim: url)
    end
  end

  def self.download_file(url, ext)
    raise "Invalid URL when creating media from original claim attribute" unless url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/

    file = Tempfile.new(['download', ext])
    file.binmode
    file.write(URI(url).open.read)
    file.rewind
    file
  end

  def self.create_claim_media(text)
    Claim.find_by(original_claim_hash: Digest::MD5.hexdigest(text)) || Claim.create!(quote: text, original_claim: text)
  end

  def self.create_link_media(url, project_media_team)
    pender_key = project_media_team.get_pender_key if project_media_team
    url_from_pender = Link.normalized(url, pender_key)
    Link.find_by(url: url_from_pender) || Link.find_by(original_claim_hash: Digest::MD5.hexdigest(url)) || Link.create!(url: url, pender_key: pender_key, original_claim: url)
  end
end
