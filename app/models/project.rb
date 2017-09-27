class Project < ActiveRecord::Base

  include ValidationsHelper
  include DestroyLater

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  belongs_to :user
  belongs_to :team
  has_many :project_sources, dependent: :destroy
  has_many :sources , through: :project_sources
  has_many :project_medias, dependent: :destroy
  has_many :medias , through: :project_medias

  mount_uploader :lead_image, ImageUploader

  before_validation :set_description_and_team_and_user, on: :create
  before_validation :generate_token, on: :create

  after_create :send_slack_notification
  after_update :update_elasticsearch_data, :archive_or_restore_project_medias_if_needed

  validates_presence_of :title
  validates :lead_image, size: true
  validate :slack_channel_format, unless: proc { |p| p.settings.nil? }
  validate :project_languages_format, unless: proc { |p| p.settings.nil? }
  validate :team_is_not_archived

  has_annotations

  notifies_pusher on: :create,
                  event: 'project_created',
                  targets: proc { |p| [p.team] },
                  data: proc { |p| p.to_json }

  check_settings

  include CheckCsvExport

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def lead_image_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    CONFIG['checkdesk_base_url'] + self.lead_image.url
  end

  def as_json(options = {})
    project = {
      dbid: self.id,
      title: self.title,
      id: Base64.encode64("Project/#{self.id}")
    }
    unless options[:without_team]
      project[:team] = {
        id: Base64.encode64("Team/#{self.id}"),
        dbid: self.team_id,
        projects: { edges: self.team.projects.collect{ |p| { node: p.as_json(without_team: true) } } }
      }
    end
    project
  end

  def medias_count
    self.project_medias.count
  end

  def slack_notifications_enabled=(enabled)
    self.send(:set_slack_notifications_enabled, enabled)
  end

  def slack_channel=(channel)
    self.send(:set_slack_channel, channel)
  end

  def viber_token=(token)
    self.send(:set_viber_token, token)
  end

  def admin_label
    unless self.new_record? || self.team.nil?
      [self.team.name.truncate(15),self.title.truncate(25)].join(' - ')
    end
  end

  def update_elasticsearch_team_bg
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    client = Elasticsearch::Client.new url: url
    options = {
      index: CheckElasticSearchModel.get_index_name,
      type: 'media_search',
      body: {
        script: { inline: "ctx._source.team_id=team_id", lang: "groovy", params: { team_id: self.team_id } },
        query: { term: { project_id: { value: self.id } } }
      }
    }
    client.update_by_query options
  end

  def slack_notification_message
    I18n.t(:slack_create_project,
      user: Bot::Slack.to_slack(User.current.name),
      url: Bot::Slack.to_slack_url(self.url, "*#{self.title}*")
    )
  end

  def url
    "#{CONFIG['checkdesk_client']}/#{self.team.slug}/project/#{self.id}"
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'project', 'id' => self.id }, 'projects' => [self.id] })
  end

  def languages=(languages)
    self.send(:set_languages, languages)
  end

  def languages
    languages = self.get_languages
    languages.nil? ? [] : languages
  end

  def generate_token
    self.token ||= SecureRandom.uuid
  end

  def has_auto_tasks?
    self.team && !self.team.get_checklist.blank?
  end

  def auto_tasks
    tasks = []
    if self.has_auto_tasks?
      self.team.get_checklist.each do |task|
        if task['projects'].blank? || task['projects'].empty? || task['projects'].include?(self.id)
          task['slug'] = Task.slug(task['label'])
          tasks << task
        end
      end
    end
    tasks
  end

  def self.archive_or_restore_project_medias_if_needed(archived, project_id)
    ProjectMedia.where({ project_id: project_id }).update_all({ archived: archived })
  end

  private

  def project_languages_format
    languages = self.get_languages
    unless languages.blank?
      error_message = "Languages is invalid, it should have the format ['en', 'ar', 'fr']"
      errors.add(:base, I18n.t(:invalid_format_for_project_languages, default: error_message)) unless languages.is_a?(Array)
    end
  end

  def set_description_and_team_and_user
    self.description ||= ''
    if !User.current.nil? && !self.team_id
      self.team = User.current.current_team
    end
    self.user ||= User.current
  end

  def update_elasticsearch_data
    if self.team_id_changed?
      keys = %w(team_id)
      data = {'team_id' => self.team_id}
      options = {keys: keys, data: data}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_team')
    end
  end

  def archive_or_restore_project_medias_if_needed
    Project.delay.archive_or_restore_project_medias_if_needed(self.archived, self.id) if self.archived_changed?
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived, default: "Can't create project under trashed team"))
  end
end
