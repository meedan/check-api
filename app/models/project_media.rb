class ProjectMedia < ActiveRecord::Base
  attr_accessor :quote, :quote_attributions, :file, :previous_project_id, :set_annotation, :set_tasks_responses, :team, :cached_permissions, :is_being_created, :related_to_id, :relationship

  include ProjectAssociation
  include ProjectMediaAssociations
  include ProjectMediaCreators
  include ProjectMediaEmbed
  include ProjectMediaExport
  include Versioned
  include ValidationsHelper
  include ProjectMediaPrivate

  validates_presence_of :media, :project

  validate :project_is_not_archived, unless: proc { |pm| pm.is_being_copied  }
  validates :media_id, uniqueness: { scope: :project_id }

  after_create :set_quote_metadata, :create_auto_tasks, :create_reverse_image_annotation, :create_annotation, :send_slack_notification, :set_project_source, :notify_team_bots_create
  after_commit :create_relationship, on: [:update, :create]
  after_update :move_media_sources, :archive_or_restore_related_medias_if_needed, :notify_team_bots_update
  after_destroy :destroy_related_medias

  notifies_pusher on: [:save, :destroy],
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project, pm.project_was, pm.media, pm.project.team] },
                  bulk_targets: proc { |pm| [pm.project, pm.project_was, pm.project.team] },
                  if: proc { |pm| !pm.skip_notifications },
                  data: proc { |pm| pm.media.as_json.merge(class_name: pm.report_type).to_json }

  def report_type
    self.media.class.name.downcase
  end

  def related_to_team?(team)
    (self.team ||= self.project.team) if self.project
    self.team == team
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def slack_params
    statuses = Workflow::Workflow.options(self, self.default_project_media_status_type)[:statuses]
    current_status = statuses.select { |st| st['id'] == self.last_status }
    user = User.current || self.user
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      role: I18n.t('role_' + user.role(self.project.team).to_s),
      project: Bot::Slack.to_slack(self.project.title),
      team: Bot::Slack.to_slack(self.project.team.name),
      type: I18n.t("activerecord.models.#{self.media.class.name.underscore}"),
      title: Bot::Slack.to_slack(self.title),
      related_to: self.related_to ? Bot::Slack.to_slack_url(self.related_to.full_url, self.related_to.title) : nil,
      source: self.project_source&.source ? Bot::Slack.to_slack_url(self.project_source.full_url, self.project_source.source.name) : nil,
      description: Bot::Slack.to_slack(self.description, false),
      url: self.full_url,
      status: Bot::Slack.to_slack(current_status[0]['label']),
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{self.class_name.underscore}"), app: CONFIG['app_name']
      })
    }
  end

  def slack_notification_message(update = false)
    params = self.slack_params
    event = update ? "update" : "create"
    related = params[:related_to].blank? ? "" : "_related"
    {
      pretext: I18n.t("slack.messages.project_media_#{event}#{related}", params),
      title: params[:title],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      text: params[:description],
      fields: [
        {
          title: I18n.t(:'slack.fields.status'),
          value: params[:status],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.project'),
          value: params[:project],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.source'),
          value: params[:source],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.related_to'),
          value: params[:related_to],
          short: false
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

  def title
    self.metadata.dig('title') || self.media.quote
  end

  def description
    self.metadata.dig('description') || (self.media.type == 'Claim' ? nil : self.text)
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def metadata
    self.original_metadata.merge(self.custom_metadata)
  end

  def original_metadata
    begin JSON.parse(self.media.get_annotations('metadata').last.load.get_field_value('metadata_value')) rescue {} end
  end

  def custom_metadata
    begin JSON.parse(self.get_annotations('metadata').last.load.get_field_value('metadata_value')) rescue {} end
  end

  def overridden
    data = {}
    self.overridden_metadata_attributes.each{ |k| data[k] = false }
    if self.media.type == 'Link'
      cm = self.custom_metadata
      om = self.original_metadata
      data.each do |k, _v|
        data[k] = true if cm[k] != om[k] and !cm[k].blank?
      end
    end
    data
  end

  def overridden_metadata_attributes
    %W(title description username)
  end

  def metadata=(info)
    info = info.blank? ? {} : JSON.parse(info)
    unless info.blank?
      m = self.get_annotations('metadata').last
      m = m.load unless m.nil?
      m = initiate_metadata_annotation(info) if m.nil?
      m.disable_es_callbacks = Rails.env.to_s == 'test'
      m.client_mutation_id = self.client_mutation_id
      self.override_metadata_data(m, info)
    end
  end

  def project_was
    Project.find(self.previous_project_id) unless self.previous_project_id.blank?
  end

  def refresh_media=(_refresh)
    Bot::Keep.archiver_annotation_types.each do |type|
      a = self.annotations.where(annotation_type: type).last
      a.nil? ? self.create_archive_annotation(type) : self.reset_archive_response(a)
    end
    self.media.refresh_pender_data
    self.updated_at = Time.now
    # update account if we have a new author_url
    update_media_account if self.media.type == 'Link'
  end

  def text
    self.media.text
  end

  def full_url
    "#{self.project.url}/media/#{self.id}"
  end

  def update_mt=(_update)
    #mt = self.annotations.where(annotation_type: 'mt').last
    #MachineTranslationWorker.perform_in(1.second, YAML::dump(self), YAML::dump(User.current)) unless mt.nil?
  end

  def get_dynamic_annotation(type)
    Dynamic.where(annotation_type: type, annotated_type: 'ProjectMedia', annotated_id: self.id).last
  end

  def project_source
    cache_key = "project_source_id_cache_for_project_media_#{self.id}"
    psid = Rails.cache.fetch(cache_key) do
      ps = get_project_source(self.project_id)
      ps.nil? ? 0 : ps.id
    end
    ps = ProjectSource.where(id: psid).last
    if ps.nil?
      ps = get_project_source(self.project_id)
      Rails.cache.write(cache_key, ps.id) unless ps.nil?
    end
    ps
  end

  def custom_permissions(ability = nil)
    perms = {}
    perms["embed ProjectMedia"] = !self.archived
    ability ||= Ability.new
    perms["restore ProjectMedia"] = ability.can?(:restore, self)
    perms["lock Annotation"] = ability.can?(:lock_annotation, self)
    perms["administer Content"] = ability.can?(:administer_content, self)
    perms
  end

  def is_completed?
    required_tasks = self.required_tasks
    unresolved = required_tasks.select{ |t| t.status != 'resolved' }
    unresolved.blank?
  end

  def is_finished?
    statuses = Workflow::Workflow.options(self, self.default_project_media_status_type)[:statuses]
    current_status = statuses.select { |st| st['id'] == self.last_status }
    current_status[0]['completed'].to_i == 1
  end

  def relationships_object
    unless self.related_to_id.nil?
      type = Relationship.default_type.to_json
      id = [self.related_to_id, type].join('/')
      OpenStruct.new({ id: id, type: type })
    end
  end

  def relationships_source
    self.relationships_object
  end

  def relationships_target
    self.relationships_object
  end

  def related_to
    ProjectMedia.where(id: self.related_to_id).last unless self.related_to_id.nil?
  end

  def encode_with(coder)
    extra = { 'related_to_id' => self.related_to_id }
    coder['extra'] = extra
    coder['raw_attributes'] = attributes_before_type_cast
    coder['attributes'] = @attributes
    coder['new_record'] = new_record?
    coder['active_record_yaml_version'] = 0
  end

  def assignments_progress(uid = 0)
    user = uid.to_i > 0 ? User.where(id: uid).last : User.current
    data = { answered: 0, total: 0 }
    data = Rails.cache.read("cache-assignments-progress-#{user.id}-project-media-#{self.id}") unless user.nil?
    data
  end

  def self.archive_or_restore_related_medias(archived, project_media_id)
    ids = Relationship.where(source_id: project_media_id).map(&:target_id)
    ProjectMedia.where(id: ids).update_all(archived: archived)
  end

  def self.destroy_related_medias(project_media, user_id = nil)
    project_media = YAML::load(project_media)
    project_media_id = project_media.id
    relationships = Relationship.where(source_id: project_media_id)
    targets = relationships.map(&:target)
    relationships.destroy_all
    targets.map(&:destroy)
    user = User.where(id: user_id).last
    Relationship.where(target_id: project_media_id).each do |r|
      User.current = user
      r.skip_check_ability = true
      r.target = project_media
      r.destroy
      User.current = nil
      v = r.versions.where(event_type: 'destroy_relationship').last
      unless v.nil?
        v.meta = r.version_metadata
        v.save!
      end
    end
  end

  def targets_by_users
    ids = self.source_relationships.joins('INNER JOIN users ON users.id = relationships.user_id').where("users.type != 'BotUser' OR users.type IS NULL").map(&:target_id)
    ProjectMedia.where(id: ids)
  end

  protected

  def initiate_metadata_annotation(info)
    m = Dynamic.new
    m.annotation_type = 'metadata'
    m.set_fields = { metadata_value: info.to_json }.to_json
    m.annotated = self
    m.annotator = User.current unless User.current.nil?
    m
  end

  def override_metadata_data(m, info)
    current_info = self.custom_metadata
    info.each{ |k, v| current_info[k] = v }
    m.skip_notifications = true if self.is_being_created
    m.set_fields = { metadata_value: current_info.to_json }.to_json
    m.save!
  end

  def set_es_account_data
    data = {}
    a = self.media.account
    metadata = a.metadata
    self.overridden_metadata_attributes.each{ |k| sk = k.to_s; data[sk] = metadata[sk] unless metadata[sk].nil? } unless metadata.nil?
    data["id"] = a.id unless data.blank?
    [data]
  end

  def add_extra_elasticsearch_data(ms)
    m = self.media
    unless m.nil?
      ms.associated_type = m.type
      ms.accounts = self.set_es_account_data unless m.account.nil?
      data = self.metadata
      unless data.nil?
        ms.title = data['title']
        ms.description = data['description']
        ms.quote = m.quote
      end
    end
    ms.verification_status = self.last_status
    ts = self.annotations.where(annotation_type: "translation_status").last
    ms.translation_status = ts.load.status unless ts.nil?
    ms.archived = self.archived.to_i
    ms.inactive = self.inactive.to_i
  end

  # private
  #
  # Please add private methods to app/models/concerns/project_media_private.rb

end
