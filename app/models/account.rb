class Account < ActiveRecord::Base
  include PenderData

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  belongs_to :user
  belongs_to :source
  belongs_to :team
  has_many :medias
  has_annotations

  validates_presence_of :url
  validate :validate_pender_result, on: :create
  validate :pender_result_is_a_profile, on: :create
  validate :url_is_unique, on: :create

  after_create :set_pender_result_as_annotation, :create_source

  def provider
    self.data['provider']
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def source_id_callback(value, _mapping_ids = nil)
    source = Source.where(name: value).last
    source.nil? ? nil : source.id
  end

  def get_team
    s = self.source
    s.get_team
  end

  def data
    em = self.annotations('embed').last
    JSON.parse(em.embed)
  end

  private

  def create_source
    if self.source.nil?
      data = self.pender_data
      source = Source.new
      source.avatar = data['picture']
      source.name = data['title'].blank? ? 'Untitled' : data['title']
      source.slogan = data['description'].to_s
      source.save!
      self.source = source
      self.save!
    end
  end

  def pender_result_is_a_profile
    errors.add(:base, 'Sorry, this is not a profile') if !self.pender_data.nil? && self.pender_data['provider'] != 'page' && self.pender_data['type'] != 'profile'
  end

  def url_is_unique
    existing = Account.where(url: self.url).where('source_id IS NOT NULL').first
    unless existing.nil?
      errors.add(:base, "Account with this URL exists and has source id #{existing.source_id}")
    end
  end
end
