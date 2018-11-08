class Source < ActiveRecord::Base
  attr_accessor :disable_es_callbacks

  include HasImage
  include CheckElasticSearch
  include CheckNotifications::Pusher
  include ValidationsHelper
  include CustomLock

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  has_many :project_sources
  has_many :account_sources, dependent: :destroy
  has_many :projects, through: :project_sources
  has_many :accounts, through: :account_sources
  belongs_to :user
  belongs_to :team
  has_one :bot_user

  has_annotations

  before_validation :set_user, :set_team, on: :create

  validates_presence_of :name
  validate :is_unique_per_team, on: :create
  validate :team_is_not_archived, unless: proc { |s| s.team && s.team.is_being_copied }

  after_create :create_metadata, :notify_team_bots_create
  after_update :notify_team_bots_update, :send_slack_notification
  after_commit :update_elasticsearch_source, on: :update
  after_save :cache_source_overridden

  notifies_pusher on: :update, event: 'source_updated', data: proc { |s| s.to_json }, targets: proc { |s| [s] }

  custom_optimistic_locking include_attributes: [:name, :image, :description]

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def slack_params
    user = User.current or self.user
    project_source = self.project_sources[0]
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      role: I18n.t("role_" + user.role(self.team).to_s),
      team: Bot::Slack.to_slack(self.team.name),
      type: I18n.t("activerecord.models.source"),
      title: Bot::Slack.to_slack(self.name),
      project: Bot::Slack.to_slack(project_source.project.title),
      description: Bot::Slack.to_slack(self.description, false),
      url: project_source.full_url,
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.source"), app: CONFIG['app_name']
      })
    }
  end

  def slack_notification_message(update = true)
    return nil if self.project_sources.blank?
    params = self.slack_params
    event = update ? "update" : "create"
    {
      pretext: I18n.t("slack.messages.project_source_#{event}", params),
      title: params[:title],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      text: params[:description],
      fields: [
        {
          title: I18n.t(:'slack.fields.project'),
          value: params[:project],
          short: true
        }
      ],
      actions: [
        {
          type: "button",
          text: params[:button],
          url: params[:url]
        }
      ]
    }
  end

  def medias
    #TODO: fix me - list valid project media ids
    m_ids = Media.where(account_id: self.account_ids).map(&:id)
    m_ids.concat ClaimSource.where(source_id: self.id).map(&:media_id)
    conditions = { media_id: m_ids }
    conditions['projects.team_id'] = Team.current.id unless Team.current.nil?
    ProjectMedia.joins(:project).where(conditions)
  end

  def collaborators
    self.annotators
  end

  def medias_count
    self.medias.count
  end

  def accounts_count
    self.accounts.count
  end

  def get_team
    teams = []
    projects = self.projects.map(&:id)
    teams = Project.where(:id => projects).map(&:team_id).uniq unless projects.empty?
    return teams
  end

  def image
    return CONFIG['checkdesk_base_url'] + self.file.url if !self.file.nil? && self.file.url != '/images/source.png'
    self.avatar || (self.accounts.empty? ? CONFIG['checkdesk_base_url'] + '/images/source.png' : self.accounts.first.data['picture'].to_s)
  end

  def description
    return self.slogan if self.slogan != self.name && !self.slogan.blank?
    self.accounts.empty? ? '' : self.accounts.first.data['description'].to_s
  end

  def set_avatar(image)
    self.update_columns(avatar: image)
  end

  def get_annotations(type = nil)
    conditions = {}
    conditions[:annotation_type] = type unless type.nil?
    conditions[:annotated_type] = 'ProjectSource'
    conditions[:annotated_id] = get_project_sources.map(&:id)
    self.annotations(type) + Annotation.where(conditions)
  end

  def file_mandatory?
    false
  end

  def update_elasticsearch_source
    return if self.disable_es_callbacks
    self.project_sources.each do |parent|
      self.update_elasticsearch_doc(%w(title description), {'title' => self.name, 'description' => self.description}, parent)
    end
  end

  def get_versions_log
    PaperTrail::Version.where(associated_type: 'ProjectSource', associated_id: get_project_sources).order('created_at ASC')
  end

  def get_versions_log_count
    get_project_sources.sum(:cached_annotations_count)
  end

  def update_from_pender_data(data)
    self.update_name_from_data(data)
    self.avatar = data['author_picture'] if data && !data['author_picture'].blank?
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
      a.refresh_embed_data
      a.skip_check_ability = true
      a.save!
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
    self.team = Team.current unless Team.current.nil?
  end

  def get_project_sources
    conditions = {}
    conditions[:project_id] = Team.current.projects unless Team.current.nil?
    self.project_sources.where(conditions)
  end

  def is_unique_per_team
    unless self.team.nil? || self.name.blank?
      s = Source.get_duplicate(self.name, self.team)
      errors.add(:base, "This source already exists in this team and has id #{s.id}") unless s.nil?
    end
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived_for_source, default: "Can't create source under trashed team"))
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
    TeamBot.notify_bots_in_background("#{event}_source", self.team_id, self)
  end
end
