class Account < ActiveRecord::Base
  include PenderData
  include CheckElasticSearch

  attr_accessor :source, :disable_es_callbacks, :disable_account_source_creation

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
  after_commit :update_elasticsearch_account, on: :update
  after_commit :destroy_elasticsearch_account, on: :destroy

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
    data = JSON.parse(em.embed) unless em.nil?
    data || {}
  end

  def embed
    em = self.annotations('embed').last
    embed = JSON.parse(em.data['embed']) unless em.nil?
    embed
  end

  def image
    self.embed['picture'] || ''
  end

  def create_source
    source = self.source

    if source.nil? && Team.current.present?
      self.source = self.sources.where(team_id: Team.current.id).last
      return unless self.source.nil?
    end

    if source.nil?
      data = self.pender_data
      source = get_source_obj(data)
      source.update_from_pender_data(data)
      source.save!
    end
    create_account_source(source)
    self.source = source
  end

  def get_source_obj(data)
    name = data['author_name'] unless data.nil?
    source = Source.create_source(name) unless name.blank?
    source = Source.new if source.nil?
    source
  end

  def refresh_account=(_refresh)
    self.refresh_pender_data
    self.sources.each do |s|
      s.updated_at = Time.now
      s.save!
    end
    self.updated_at = Time.now
  end

  def self.create_for_source(url, source = nil, disable_account_source_creation = false, disable_es_callbacks = false)
    a = Account.where(url: url).last
    if a.nil?
      a = Account.new
      a.disable_account_source_creation = disable_account_source_creation
      a.disable_es_callbacks = disable_es_callbacks
      a.source = source
      a.url = url
      if a.save
        return a
      else
        a2 = Account.where(url: a.url).last
        return a.save! if a2.nil?
        a = a2
      end
    end

    unless a.nil?
      a.skip_check_ability = true
      a.pender_data = a.embed
      a.source = source
      a.disable_account_source_creation = disable_account_source_creation
      a.disable_es_callbacks = disable_es_callbacks
      a.create_source
    end
    a
  end

  private

  def create_account_source(source)
    return if self.disable_account_source_creation
    self.sources << source
    self.save!
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_team
    self.team = Team.current unless Team.current.nil?
  end

  def pender_result_is_a_profile
    errors.add(:base, 'Sorry, this is not a profile') if !self.pender_data.nil? && self.pender_data['provider'] != 'page' && self.pender_data['type'] != 'profile'
  end

  def update_elasticsearch_account
    return if self.disable_es_callbacks
    parents = self.get_parents_for_es
    parents.each do |parent|
      self.add_update_media_search_child('account_search', %w(title description username), {}, parent)
    end unless parents.blank?
  end

  def destroy_elasticsearch_account
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = {es_type: AccountSearch, type: 'child'}
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'destroy')
  end

  protected

  def get_parents_for_es
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    parents = []
    ps_ids = ProjectSource.where(source_id: self.sources).map(&:id).to_a
    parents = ps_ids.map{|id| Base64.encode64("ProjectSource/#{id}") } unless ps_ids.blank?
    parents
  end
end
