class Project < ActiveRecord::Base

  include ValidationsHelper
  include DestroyLater
  include AssignmentConcern

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

  after_commit :send_slack_notification, on: [:create, :update]
  after_commit :update_elasticsearch_data, on: :update
  after_update :archive_or_restore_project_medias_if_needed
  after_destroy :reset_current_project

  validates_presence_of :title
  validates :lead_image, size: true
  validate :slack_channel_format, unless: proc { |p| p.settings.nil? }
  validate :project_languages_format, unless: proc { |p| p.settings.nil? }
  validate :team_is_not_archived, unless: proc { |p| p.is_being_copied }

  has_annotations

  notifies_pusher on: :create, event: 'project_created', targets: proc { |p| [p.team] }, data: proc { |p| { id: p.id }.to_json }

  check_settings

  include CheckExport

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def lead_image_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def get_team
    [self.team.id]
  end

  def avatar
    custom = self.lead_image&.file&.public_url&.to_s&.gsub(/^#{Regexp.escape(CONFIG['storage']['endpoint'])}/, CONFIG['storage']['public_endpoint'])
    default = CONFIG['checkdesk_base_url'] + self.lead_image.url
    custom || default
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
        avatar: self.team.avatar,
        name: self.team.name,
        slug: self.team.slug,
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

  def update_elasticsearch_doc_team_bg(_options)
    client = MediaSearch.gateway.client
    options = {
      index: CheckElasticSearchModel.get_index_alias,
      type: 'media_search',
      body: {
        script: { source: "ctx._source.team_id = params.team_id", params: { team_id: self.team_id } },
        query: { term: { project_id: { value: self.id } } }
      }
    }
    client.update_by_query options
  end

  def slack_params
    user = User.current or self.user
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      project: Bot::Slack.to_slack(self.title),
      role: I18n.t("role_" + user.role(self.team).to_s),
      team: Bot::Slack.to_slack(self.team.name),
      url: self.url,
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.project"), app: CONFIG['app_name']
      })
    }.merge(self.slack_params_assignment)
  end

  def slack_notification_message
    params = self.slack_params
    message = {
      pretext: I18n.t("slack.messages.project_create", params),
      title: params[:project],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      actions: [
        {
          type: "button",
          text: params[:button],
          url: params[:url]
        }
      ]
    }
    if params[:assignment_event]
      event = params[:assignment_event]
      message[:pretext] = I18n.t("slack.messages.project_#{event}", params)
      message[:fields] = [
        {
          title: I18n.t(:'slack.fields.assigned'),
          value: params[:assigned],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.unassigned'),
          value: params[:unassigned],
          short: true
        }
      ]
    end
    message
  end

  def url
    "#{CONFIG['checkdesk_client']}/#{self.team.slug}/project/#{self.id}"
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'project', 'id' => self.id }, 'projects' => [self.id] })
  end

  def search
    CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => self.id }, 'projects' => [self.id] }.to_json)
  end

  def languages=(languages)
    self.send(:set_languages, languages)
  end

  def languages
    languages = self.get_languages
    languages.nil? ? [] : languages
  end

  def generate_token
    self.token = nil if self.is_being_copied
    self.token ||= SecureRandom.uuid
  end

  def auto_tasks
    tasks = []
    self.team.team_tasks.order('id ASC').each do |task|
      tasks << task if task.project_ids.include?(self.id) || task.project_ids.blank?
    end
    tasks
  end

  def self.archive_or_restore_project_medias_if_needed(archived, project_id)
    ProjectMedia.where({ project_id: project_id }).update_all({ archived: archived })
  end

  def is_being_copied
    self.team && self.team.is_being_copied
  end

  def propagate_assignment_to(user = nil)
    targets = []
    ProjectMedia.where(project_id: self.id).find_each do |pm|
      status = pm.last_status_obj
      unless status.nil?
        targets << status
        targets << status.propagate_assignment_to(user)
      end
    end
    targets.flatten
  end

  def inactive
    team.inactive
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
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    v = self.versions.last
    unless v.nil? || v.changeset['team_id'].blank?
      keys = %w(team_id)
      data = {'team_id' => self.team_id}
      options = {keys: keys, data: data}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_doc_team')
    end
  end

  def archive_or_restore_project_medias_if_needed
    Project.delay.archive_or_restore_project_medias_if_needed(self.archived, self.id) if self.archived_changed?
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived))
  end

  def reset_current_project
    User.where(current_project_id: self.id).each{ |user| user.update_columns(current_project_id: nil) }
  end
end
