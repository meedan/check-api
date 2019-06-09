class Account < ActiveRecord::Base
  include PenderData
  include CheckElasticSearch

  attr_accessor :source, :disable_es_callbacks, :disable_account_source_creation, :created_on_registration

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }, ignore: [:updated_at]
  belongs_to :user, inverse_of: :accounts
  belongs_to :team
  has_many :medias
  has_many :account_sources, dependent: :destroy
  has_many :sources, through: :account_sources

  has_annotations

  before_validation :set_user, :set_team, on: :create

  validates_presence_of :url
  validate :validate_pender_result, on: :create, unless: :created_on_registration?
  validate :pender_result_is_a_profile, on: :create, unless: :created_on_registration?
  validates :url, uniqueness: true

  after_create :set_metadata_annotation, :create_source, :set_provider
  after_commit :update_elasticsearch_account, on: :update

  serialize :omniauth_info

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
    m = self.annotations('metadata').last&.load
    data = begin JSON.parse(m.get_field_value('metadata_value')) rescue {} end
    data || {}
  end

  def metadata
    self.data
  end

  def image
    self.metadata['picture'] || ''
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
    self.refresh_metadata
    self.sources.each do |s|
      s.updated_at = Time.now
      s.skip_check_ability = true
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
      a.pender_data = a.metadata
      a.source = source
      a.disable_account_source_creation = disable_account_source_creation
      a.disable_es_callbacks = disable_es_callbacks
      a.create_source
    end
    a
  end

  def created_on_registration?
    self.created_on_registration || (self.data && self.data['pender'] == false)
  end

  def set_omniauth_info_as_annotation
    m = self.annotations('metadata').last
    if m.nil?
      m = Dynamic.new
      m.annotation_type = 'metadata'
      m.annotated = self
    else
      m = m.load
    end
    m.metadata_for_registration_account(self.omniauth_info)
  end

  def refresh_metadata
    if self.created_on_registration?
      self.set_omniauth_info_as_annotation
      self.update_columns(url: self.data['url']) if self.data['url']
    else
      self.refresh_pender_data
    end
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
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    parents = self.get_parents
    parents.each do |parent|
      self.add_update_nested_obj({op: 'update', nested_key: 'accounts', keys: %w(title description username), obj: parent})
    end unless parents.blank?
  end

  def set_metadata_annotation
    self.created_on_registration ? set_omniauth_info_as_annotation : set_pender_result_as_annotation
  end

  def set_provider
    if self.provider.blank?
      data = self.data
      provider = data['provider'] unless self.data.nil?
      self.update_columns(provider: provider) unless provider.blank?
    end
  end

  protected

  def get_parents
    ProjectSource.where(source_id: self.sources)
  end
end
