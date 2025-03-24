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

  def self.find_or_create_media_from_content(media_type, media_content = nil, additional_args = {})
    case media_type
    when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
      find_or_create_uploaded_file_media(media_content, media_type, additional_args)
    when 'Claim'
      find_or_create_claim_media(media_content, additional_args)
    when 'Link'
      begin
        find_or_create_link_media(media_content, additional_args)
      rescue Timeout::Error
        Rails.logger.warn("[Link Media Creation] Timeout error while trying to create a Link Media from #{media_content}. A Claim Media will be created instead.")
        find_or_create_claim_media(media_content, additional_args)
      end
    when 'Blank'
      Blank.create!
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

  def self.downloaded_file(url)
    raise "Invalid URL when creating media from original claim attribute" unless url =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/
    uri = URI.parse(url)
    extension = File.extname(uri.path)
    filename = "download-#{SecureRandom.uuid}#{extension}"
    filepath = File.join(Rails.root, 'tmp', filename)

    request = Net::HTTP::Get.new(uri)
    response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 30, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    body = response.body

    File.atomic_write(filepath) { |file| file.write(body) }
    File.open(filepath)
  end

  def self.find_or_create_uploaded_file_media(file_media, media_type, additional_args = {})
    has_original_claim = additional_args&.fetch(:has_original_claim, nil)
    original_claim_url = additional_args&.fetch(:original_claim_url, nil)
    klass = media_type.constantize

    if has_original_claim
      existing_media = klass.find_by(original_claim_hash: Digest::MD5.hexdigest(original_claim_url))

      if existing_media
        existing_media
      else
        klass.create!(file: file_media, original_claim: original_claim_url)
      end
    else
      m = klass.find_by(file: Media.filename(file_media)) || klass.new(file: file_media)
      m.save! if m.new_record?
      m
    end
  end

  def self.find_or_create_claim_media(claim_media, additional_args = {})
    has_original_claim = additional_args.fetch(:has_original_claim, nil)
    quote_attributions = additional_args.fetch(:quote_attributions, nil)

    if has_original_claim
      Claim.find_by(original_claim_hash: Digest::MD5.hexdigest(claim_media)) || Claim.create!(quote: claim_media, original_claim: claim_media)
    else
      Claim.create!(quote: claim_media, quote_attributions: quote_attributions)
    end
  end

  def self.find_or_create_link_media(link_media, additional_args = {})
    has_original_claim = additional_args.fetch(:has_original_claim, nil)
    project_media_team = additional_args.fetch(:team, nil)

    pender_key = project_media_team&.get_pender_key if project_media_team
    url_from_pender = Link.normalized(link_media, pender_key)

    if has_original_claim
      Link.find_by(url: url_from_pender) || Link.find_by(original_claim_hash: Digest::MD5.hexdigest(link_media)) || Link.create!(url: link_media, pender_key: pender_key, original_claim: link_media)
    else
      Link.find_by(url: url_from_pender) || Link.create(url: link_media, pender_key: pender_key)
    end
  end
end
