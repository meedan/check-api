require 'byebug'

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

  def self.find_or_create_media_associated_to(project_media)
    m = nil
    original_claim = project_media.set_original_claim&.strip
    media_type = project_media.media_type
    team = project_media.team

    if original_claim
      case media_type
      when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
        m = find_or_create_uploaded_file_media(original_claim, media_type, true)
      when 'Claim'
        m = find_or_create_claim_media(original_claim, nil, true)
      when 'Link'
        m = find_or_create_link_media(original_claim, team, true)
      when 'Blank'
        m = Blank.create!
      end
    else
      case media_type
      when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
        m = find_or_create_uploaded_file_media(project_media.file, media_type)
      when 'Claim'
        m = find_or_create_claim_media(project_media.quote, project_media.quote_attributions)
      when 'Link'
        m = find_or_create_link_media(project_media.url, team)
      when 'Blank'
        m = Blank.create!
      end
    end
    m
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

  def self.download_file(url, ext)
    raise "Invalid URL when creating media from original claim attribute" unless url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/

    file = Tempfile.new(['download', ext])
    file.binmode
    file.write(URI(url).open.read)
    file.rewind
    file
  end

  # we set it to UploadedImage by default, should we?
  # def self.create_with_file(project_media, media_type = 'UploadedImage')
  def self.find_or_create_uploaded_file_media(file_media, media_type, has_original_claim = false)
    klass = media_type.constantize

    if has_original_claim
      uri = URI.parse(file_media)
      ext = File.extname(uri.path)

      existing_media = klass.find_by(original_claim_hash: Digest::MD5.hexdigest(file_media))

      if existing_media
        existing_media
      else
        file = download_file(file_media, ext)
        klass.create!(file: file, original_claim: file_media)
      end
    else
      m = klass.find_by(file: Media.filename(file_media)) || klass.new(file: file_media)
      m.save! if m.new_record?
      m
    end
  end

  def self.find_or_create_claim_media(claim_media, quote_attributions = nil, has_original_claim = false)
    if has_original_claim
      Claim.find_by(original_claim_hash: Digest::MD5.hexdigest(claim_media)) || Claim.create!(quote: claim_media, original_claim: claim_media)
    else
      Claim.create!(quote: claim_media, quote_attributions: quote_attributions)
    end
  end

  def self.find_or_create_link_media(link_media, project_media_team, has_original_claim = false)
    pender_key = project_media_team.get_pender_key if project_media_team
    url_from_pender = Link.normalized(link_media, pender_key)

    if has_original_claim
      Link.find_by(url: url_from_pender) || Link.find_by(original_claim_hash: Digest::MD5.hexdigest(link_media)) || Link.create!(url: link_media, pender_key: pender_key, original_claim: link_media)
    else
      Link.find_by(url: url_from_pender) || Link.create(url: link_media, pender_key: pender_key)
    end
  end
end
