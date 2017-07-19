class Account < ActiveRecord::Base
  include PenderData

  attr_accessor :source

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }, ignore: [:updated_at]
  belongs_to :user
  belongs_to :team
  has_many :medias
  has_many :account_sources
  has_many :sources, through: :account_sources

  has_annotations

  before_validation :set_user, :set_team, on: :create

  validates_presence_of :url
  validate :validate_pender_result, on: :create
  validate :pender_result_is_a_profile, on: :create
  validates :url, uniqueness: true

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
    self.sources.map(&:get_team).flatten.uniq
  end

  def data
    em = self.annotations('embed').last
    JSON.parse(em.embed)
  end

  def embed
    em = self.annotations('embed').last
    embed = JSON.parse(em.data['embed']) unless em.nil?
    embed
  end

  def create_source
    source = self.source
    
    if source.nil? && Team.current.present?
      self.source = self.sources.where(team_id: Team.current.id).last
      return unless self.source.nil?
    end

    if source.nil?
      data = self.pender_data
      source = Source.new
      source.avatar = data['picture']
      source.name = data['title'].blank? ? 'Untitled' : data['title']
      source.slogan = data['description'].to_s
      source.save!
    end

    self.sources << source
    self.save!
    self.source = source
  end

  def self.create_for_source(url, source = nil)
    return if url.blank?
    a = Account.where(url: url).last
    if a.nil?
      a = Account.new
      a.source = source
      a.url = url
      if a.save
        return a
      else
        a = Account.where(url: a.url).last
      end
    end
    
    unless a.nil?
      a.skip_check_ability = true
      a.pender_data = a.embed
      a.source = source
      a.create_source
    end
    a
  end

  private

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_team
    self.team = Team.current unless Team.current.nil?
  end

  def pender_result_is_a_profile
    errors.add(:base, 'Sorry, this is not a profile') if !self.pender_data.nil? && self.pender_data['provider'] != 'page' && self.pender_data['type'] != 'profile'
  end
end
