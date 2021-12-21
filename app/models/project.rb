class Project < ApplicationRecord
  include CheckPusher
  include ValidationsHelper
  include DestroyLater
  include AssignmentConcern
  include AnnotationBase::Association

  module PrivacySettings
    ALL = 0
    EDITORS = 1
    ADMINS = 2
  end

  scope :allowed, ->(team) { where('privacy <= ?', Project.privacy_for_role(team)) }

  attr_accessor :project_media_ids_were, :previous_project_group_id, :previous_default_project_id, :items_destination_project_id

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }
  belongs_to :user, optional: true
  belongs_to :team, optional: true
  belongs_to :project_group, optional: true
  has_many :project_medias

  mount_uploader :lead_image, ImageUploader

  before_validation :set_description_and_team_and_user, on: :create
  before_validation :generate_token, on: :create

  after_commit :send_slack_notification, on: [:create, :update]
  after_commit :update_elasticsearch_data, on: :update
  after_update :archive_or_restore_project_medias_if_needed
  after_update :keep_only_one_default_folder, if: proc { |p| p.saved_change_to_is_default? }
  before_destroy :move_project_medias
  after_destroy :reset_current_project

  validates_presence_of :title
  validates :lead_image, size: true
  validate :team_is_not_archived, :unique_default_folder_per_team, unless: proc { |p| p.is_being_copied }
  validate :project_group_is_under_same_team

  has_annotations

  notifies_pusher on: [:save, :destroy], event: 'project_updated', targets: proc { |p| [p.team] }, data: proc { |p| { id: p.id }.to_json }

  check_settings

  cached_field :medias_count,
    start_as: 0,
    update_es: false,
    recalculate: proc { |p|
      ProjectMedia.where({ archived: CheckArchivedFlags::FlagCodes::NONE, project_id: p.id, sources_count: 0 }).count
    },
    update_on: [
      {
        model: Relationship,
        affected_ids: proc { |r| ProjectMedia.where(id: r.target_id).map(&:project_id) },
        events: {
          save: :recalculate,
          destroy: :recalculate
        }
      },
      {
        model: ProjectMedia,
        if: proc { |pm| !pm.project_id.nil? },
        affected_ids: proc { |pm| [pm.project_id] },
        events: {
          create: :recalculate,
          destroy: :recalculate
        }
      },
      {
        model: ProjectMedia,
        if: proc { |pm| pm.saved_change_to_archived? || pm.saved_change_to_project_id? },
        affected_ids: proc { |pm| [pm.project_id, pm.project_id_before_last_save] },
        events: {
          update: :recalculate,
        }
      },
    ]

  def check_search_team
    self.team.check_search_team
  end

  def check_search_project
    CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => self.id }, 'projects' => [self.id] }.to_json)
  end

  def project_group_was
    ProjectGroup.find_by_id(self.previous_project_group_id) unless self.previous_project_group_id.nil?
  end

  def previous_default_project
    Project.find_by_id(self.previous_default_project_id) unless self.previous_default_project_id.nil?
  end

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
    # We are not really using now, so just return the default image
    # self.lead_image&.file&.public_url&.to_s
    CheckConfig.get('checkdesk_base_url') + self.lead_image.url
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

  def update_elasticsearch_doc_team_bg(_options)
    client = $repository.client
    options = {
      index: CheckElasticSearchModel.get_index_alias,
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
        type: I18n.t("activerecord.models.project"), app: CheckConfig.get('app_name')
      })
    }.merge(self.slack_params_assignment)
  end

  def slack_notification_message(event = nil)
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
    "#{CheckConfig.get('checkdesk_client')}/#{self.team.slug}/project/#{self.id}"
  end

  def search_id
    CheckSearch.id({ 'parent' => { 'type' => 'project', 'id' => self.id }, 'projects' => [self.id] })
  end

  def search
    CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => self.id }, 'projects' => [self.id] }.to_json)
  end

  def generate_token(force = false)
    self.token = nil if self.is_being_copied
    if force
      self.token = SecureRandom.uuid
    else
      self.token ||= SecureRandom.uuid
    end
  end

  def self.archive_or_restore_project_medias_if_needed(archived, team_id)
    ProjectMedia.where({ team_id: team_id }).update_all({ archived: archived })
  end

  def self.current
    RequestStore.store[:project]
  end

  def self.current=(project)
    RequestStore.store[:project] = project
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

  def self.bulk_update_medias_count(pids)
    pids_count = Hash[pids.product([0])] # Initialize all projects as zero
    ProjectMedia.where({ archived: CheckArchivedFlags::FlagCodes::NONE, project_id: pids, sources_count: 0 })
    .group('project_id')
    .count.to_h.each do |pid, count|
      pids_count[pid.to_i] = count.to_i
    end
    pids_count.each { |pid, count| Rails.cache.write("check_cached_field:Project:#{pid}:medias_count", count) }
  end

  def self.privacy_for_role(team = Team.current, user = User.current)
    role = user && team ? user.role(team) : ''
    { 'editor' => PrivacySettings::EDITORS, 'admin' => PrivacySettings::ADMINS }[role] || PrivacySettings::ALL
  end

  def before_destroy_later
    self.move_project_medias
  end

  def move_project_medias
    self.project_media_ids_were = self.project_media_ids
    unless self.project_media_ids.blank?
      # assing related ProjectMedia to destination project or default one
      move_to_id = self.items_destination_project_id || self.team.default_folder&.id
      ProjectMedia.bulk_update(self.project_media_ids, { action: 'move_to', params: { move_to: move_to_id }.to_json }, self.team) unless move_to_id.blank?
    end
  end

  # FIXME: This method doesn't make sense but is required and used only by the GraphQL layer, which expects this method to exist in opposition to previous_default_project parent for project mutations
  def projects
    []
  end

  private

  def keep_only_one_default_folder
    # Update other default projects to be false
    self.team.projects.where.not(id: self.id).where(is_default: true).update_all(is_default: false) if self.is_default?
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
    v = Version.from_partition(self.team_id).where(item_id: self.id, item_type: self.class.name).last
    unless v.nil? || v.changeset['team_id'].blank?
      keys = %w(team_id)
      data = {'team_id' => self.team_id}
      options = {keys: keys, data: data}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_doc_team')
    end
  end

  def archive_or_restore_project_medias_if_needed
    Project.delay.archive_or_restore_project_medias_if_needed(self.archived, self.team_id) if self.saved_change_to_archived?
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived))
  end

  def reset_current_project
    User.where(current_project_id: self.id).each{ |user| user.update_columns(current_project_id: nil) }
  end

  def project_group_is_under_same_team
    errors.add(:base, I18n.t(:project_group_must_be_under_same_team)) if self.project_group && self.project_group.team_id != self.team_id
  end

  def unique_default_folder_per_team
    if self.new_record? && self.is_default?
      errors.add(:base, I18n.t(:unique_default_folder_per_team)) unless self.team.default_folder.nil?
    elsif self.is_default_changed? && !self.is_default?
      default_folder = self.team.default_folder
      errors.add(:base, I18n.t(:unique_default_folder_per_team)) if self.id == default_folder.id
    end
  end
end
