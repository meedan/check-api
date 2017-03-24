class Media < ActiveRecord::Base
  self.inheritance_column = :type

  attr_accessor :project_id, :project_object

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  belongs_to :account
  belongs_to :user
  has_many :project_medias, dependent: :destroy
  has_many :projects, through: :project_medias
  has_annotations

  before_validation :set_type, :set_url_nil_if_empty, :set_user, on: :create

  def self.types
    %w(Link Claim UploadedFile UploadedImage)
  end

  validates_inclusion_of :type, in: Media.types

  def class_name
    'Media'
  end

  def get_team
    self.projects.map(&:team_id)
  end

  def get_team_objects
    self.projects.map(&:team)
  end

  def overridden_embed_attributes
    %W(title description username quote)
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

  def media_url
    self.url
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
end
