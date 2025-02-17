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
  validates_uniqueness_of :original_claim_hash, allow_nil: true

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

  # copied
  def self.create_media_associated_to(project_media)
    puts '******************************** HIT Media'
    m = nil
    Media.set_media_type(project_media) if project_media.media_type.blank?
    media_type = project_media.media_type
    case media_type
    when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
      m = create_with_file(project_media,media_type)
    when 'Claim'
      m = create_claim(project_media)
    when 'Link'
      m = create_link(project_media)
    when 'Blank'
      m = Blank.create!
    end
    m
  end

  def self.find_or_create_from_original_claim(claim, project_media_team)
    if claim.match?(/\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/)
      uri = URI.parse(claim)
      content_type = Net::HTTP.get_response(uri)['content-type']
      ext = File.extname(uri.path)

      case content_type
      when /^image\//
        find_or_create_uploaded_file_media_from_original_claim('UploadedImage', claim, ext)
      when /^video\//
        find_or_create_uploaded_file_media_from_original_claim('UploadedVideo', claim, ext)
      when /^audio\//
        find_or_create_uploaded_file_media_from_original_claim('UploadedAudio', claim, ext)
      else
        find_or_create_link_media_from_original_claim(claim, project_media_team)
      end
    else
      find_or_create_claim_media_from_original_claim(claim)
    end
  end

  private

  def set_url_nil_if_empty
    self.url = nil if self.url.blank?
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  # copied
  def set_media_type(project_media)
    if !project_media.url.blank?
      project_media.media_type = 'Link'
    elsif !project_media.quote.blank?
      project_media.media_type = 'Claim'
    end
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

  # copied
  def self.create_with_file(project_media, media_type = 'UploadedImage')
    klass = media_type.constantize
    m = klass.find_by(file: Media.filename(project_media.file)) || klass.new(file: project_media.file)
    m.save! if m.new_record?
    m
  end

  def self.find_or_create_uploaded_file_media_from_original_claim(media_type, url, ext)
    klass = media_type.constantize
    existing_media = klass.find_by(original_claim_hash: Digest::MD5.hexdigest(url))

    if existing_media
      existing_media
    else
      file = download_file(url, ext)
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

  # copied
  def self.create_claim(project_media)
    m = Claim.new
    m.quote = project_media.quote
    m.quote_attributions = project_media.quote_attributions
    m.save!
    m
  end

  def self.find_or_create_claim_media_from_original_claim(text)
    Claim.find_by(original_claim_hash: Digest::MD5.hexdigest(text)) || Claim.create!(quote: text, original_claim: text)
  end

  # copied
  def self.create_link(project_media)
    team = project_media.team || Team.current
    pender_key = team.get_pender_key if team
    url_from_pender = Link.normalized(project_media.url, pender_key)
    Link.find_by(url: url_from_pender) || Link.create(url: project_media.url, pender_key: pender_key)
  end

  def self.find_or_create_link_media_from_original_claim(url, project_media_team)
    pender_key = project_media_team.get_pender_key if project_media_team
    url_from_pender = Link.normalized(url, pender_key)
    Link.find_by(url: url_from_pender) || Link.find_by(original_claim_hash: Digest::MD5.hexdigest(url)) || Link.create!(url: url, pender_key: pender_key, original_claim: url)
  end
end
