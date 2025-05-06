class Source < ApplicationRecord
  attr_accessor :disable_es_callbacks, :add_to_project_media_id, :urls, :validate_primary_link_exist, :set_tasks_responses

  include HasImage
  include CheckElasticSearch
  include CheckPusher
  include ValidationsHelper
  include CustomLock
  include ProjectMediaSourceAssociations
  include AnnotationBase::Association

  has_many :account_sources, dependent: :destroy
  has_many :accounts, through: :account_sources
  has_many :project_medias
  belongs_to :user, optional: true
  belongs_to :team, optional: true
  has_one :bot_user

  before_validation :set_user, :set_team, on: :create

  validates_presence_of :name
  validate :is_unique_per_team
  validate :primary_url_exists, on: :create
  validate :team_is_not_archived, unless: proc { |s| s.team && s.team.is_being_copied }

  after_create :create_metadata, :notify_team_bots_create, :create_auto_tasks
  after_update :notify_team_bots_update
  after_save :cache_source_overridden, :add_to_project_media, :create_related_accounts

  has_annotations

  notifies_pusher on: :update, event: 'source_updated', data: proc { |s| s.to_json }, targets: proc { |s| [s] }

  custom_optimistic_locking include_attributes: [:name, :image, :description]

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def medias
    self.project_medias.where(archived: CheckArchivedFlags::FlagCodes::NONE)
  end

  def collaborators
    self.annotators
  end

  def project_media
    ProjectMedia.find_by_id(self.add_to_project_media_id) unless self.add_to_project_media_id.nil?
  end

  def medias_count
    self.medias.count
  end

  def accounts_count
    self.accounts.count
  end

  def image
    custom = self.public_path
    custom || self.avatar || (self.accounts.empty? ? CheckConfig.get('checkdesk_base_url') + '/images/source.png' : self.accounts.first.data['picture'].to_s)
  end

  def description
    return self.slogan if self.slogan != self.name && !self.slogan.blank?
    self.accounts.empty? ? '' : self.accounts.first.data['description'].to_s
  end

  def set_avatar(image)
    new_record? ? (self.avatar = image) : self.update_columns(avatar: image)
  end

  def get_annotations(type = nil)
    self.annotations(type)
  end

  def file_mandatory?
    false
  end

  def update_from_pender_data(data)
    self.update_name_from_data(data)
    self.set_avatar(data['author_picture']) if data && !data['author_picture'].blank?
  end

  def update_name_from_data(data)
    gname = self.name ||= "Untitled-#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
    if data.nil?
      self.name = gname if self.name.blank?
    else
      self.name = data['author_name'].blank? ? gname : data['author_name'] if self.name.blank? or self.name.start_with?('Untitled')
    end
  end

  def refresh_accounts=(refresh)
    return if refresh.blank?
    self.accounts.each do |a|
      a.pender_key = self.team.get_pender_key if self.team
      a.refresh_metadata
      a.skip_check_ability = true
      a.save!
      a.touch # call this method to set updated_at with current time
    end
    self.update_from_pender_data(self.accounts.first.data)
    self.updated_at = Time.now
    self.save!
  end

  def self.create_source(name, team = Team.current)
    s = Source.get_duplicate(name, team) unless team.nil?
    return s unless s.nil?
    s = Source.new
    s.name = name
    s.team_id = team.id unless team.nil?
    s.skip_check_ability = true
    s.save!
    s.reload
  end

  def self.get_duplicate(name, team)
    Source.where('lower(name) = lower(?) AND team_id = ?', name, team.id).last
  end

  def overridden
    Rails.cache.fetch("source_overridden_cache_#{self.id}") do
      get_overridden
    end
  end

  def cache_source_overridden
    Rails.cache.write("source_overridden_cache_#{self.id}", get_overridden)
  end

  private

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_team
    self.team = Team.current if self.team_id.nil? && !Team.current.nil?

    if self.team.nil? && self.user.present?
      self.team = self.user.team if self.user.team.present?
    end
  end

  def is_unique_per_team
    unless self.team.nil? || self.name.blank?
      s = Source.get_duplicate(self.name, self.team)
      unless s.nil?
        raise_source_error(s) if self.id.nil? || s.id != self.id
      end
    end
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived_for_source))
  end

  def create_metadata
    unless DynamicAnnotation::AnnotationType.where(annotation_type: 'metadata').last.nil?
      user = User.current
      User.current = nil
      m = Dynamic.new
      m.skip_check_ability = true
      m.skip_notifications = true
      m.disable_es_callbacks = Rails.env.to_s == 'test'
      m.annotation_type = 'metadata'
      m.annotated = self
      m.annotator = user
      m.set_fields = { metadata_value: {}.to_json }.to_json
      m.is_being_copied = self.team&.is_being_copied
      m.save!
      User.current = user
    end
  end

  def get_overridden
    overridden = {"name" => true, "description" => true, "image" => true}
    a = self.accounts.first
    unless a.nil?
      name = a.data.nil? ? '' : a.data['author_name']
      overridden = {
        "name" => self.name == name ? a.id: true,
        "description" => self.slogan.blank? ? a.id : true,
        "image" => self.avatar.blank? ? a.id : true
      }
    end
    overridden
  end

  def notify_team_bots_create
    self.send :notify_team_bots, 'create'
  end

  def notify_team_bots_update
    self.send :notify_team_bots, 'update'
  end

  def notify_team_bots(event)
    BotUser.enqueue_event("#{event}_source", self.team_id, self)
  end

  def add_to_project_media
    unless self.add_to_project_media_id.blank?
      pm = ProjectMedia.find_by_id self.add_to_project_media_id
      unless pm.nil?
        pm.source_id = self.id
        pm.skip_check_ability = true
        pm.save!
      end
    end
  end

  def get_source_urls
    begin JSON.parse(self.urls) rescue nil end unless self.urls.blank?
  end

  def primary_url_exists
    # validate if the primary link (first url in self.urls) exists in team
    urls = get_source_urls
    if !urls.blank? && Team.current && self.validate_primary_link_exist
      # run account.valid to get normalized URL
      a = Account.new
      a.url = urls.first
      a.valid?
      a = Account.where(url: a.url).last
      s = a.sources.where(team_id: Team.current.id).last unless a.nil?
      raise_source_error(s) unless s.nil?
    end
  end

  def raise_source_error(s)
    error = {
      message: I18n.t(:source_exists),
      code: LapisConstants::ErrorCodes::const_get('DUPLICATED'),
      data: {
        team_id: s.team_id,
        type: 'source',
        id: s.id,
        name: s.name
      }
    }
    raise error.to_json
  end

  def create_related_accounts
    urls = get_source_urls
    unless urls.blank?
      urls.each do |url|
        as = AccountSource.new
        as.source = self
        as.url = url
        as.skip_check_ability = true
        begin as.save! rescue {} end
      end
    end
  end
end
