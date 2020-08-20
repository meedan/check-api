class ProjectMedia < ActiveRecord::Base
  attr_accessor :quote, :quote_attributions, :file, :media_type, :set_annotation, :set_tasks_responses, :add_to_project_id, :previous_project_id, :cached_permissions, :is_being_created, :related_to_id, :relationship, :skip_rules

  include ProjectAssociation
  include ProjectMediaAssociations
  include ProjectMediaCreators
  include ProjectMediaEmbed
  include ProjectMediaExport
  include Versioned
  include ValidationsHelper
  include ProjectMediaPrivate
  include ProjectMediaCachedFields
  include ProjectMediaBulk

  validates_presence_of :media, :team

  validates :media_id, uniqueness: { scope: :team_id }, unless: proc { |pm| pm.is_being_copied  }

  before_validation :set_team_id, on: :create
  after_create :create_project_media_project, :set_quote_metadata, :create_annotation, :send_slack_notification, :notify_team_bots_create
  after_create :create_auto_tasks_for_team_item, if: proc { |pm| pm.add_to_project_id.nil? }
  after_commit :apply_rules_and_actions_on_create, on: [:create]
  after_commit :create_relationship, on: [:update, :create]
  after_update :archive_or_restore_related_medias_if_needed, :notify_team_bots_update
  after_update :apply_rules_and_actions_on_update, if: proc { |pm| pm.changes.keys.include?('read') }
  after_destroy :destroy_related_medias

  notifies_pusher on: [:save, :destroy],
                  event: 'media_updated',
                  targets: proc { |pm| [pm.media, pm.team].concat(pm.projects) },
                  if: proc { |pm| !pm.skip_notifications },
                  data: proc { |pm| pm.media.as_json.merge(class_name: pm.report_type).to_json }

  def report_type
    self.media.class.name.downcase
  end

  def related_to_team?(team)
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
      role: I18n.t('role_' + user.role(self.team).to_s),
      team: Bot::Slack.to_slack(self.team.name),
      type: I18n.t("activerecord.models.#{self.media.class.name.underscore}"),
      title: Bot::Slack.to_slack(self.title),
      related_to: self.related_to ? Bot::Slack.to_slack_url(self.related_to.full_url, self.related_to.title) : nil,
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

  def picture
    self.media&.picture&.to_s
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

  def refresh_media=(_refresh)
    Bot::Keep.archiver_annotation_types.each do |type|
      a = self.annotations.where(annotation_type: 'archiver').last
      a.nil? ? self.create_archive_annotation(type) : self.reset_archive_response(a, type)
    end
    team = self.team
    pender_key = team.get_pender_key if team
    self.media.pender_key = pender_key
    self.media.refresh_pender_data
    self.updated_at = Time.now
    # update account if we have a new author_url
    update_media_account if self.media.type == 'Link'
  end

  def text
    self.media.text
  end

  def full_url
    "#{CONFIG['checkdesk_client']}/#{self.team.slug}/media/#{self.id}"
  end

  def get_dynamic_annotation(type)
    Dynamic.where(annotation_type: type, annotated_type: 'ProjectMedia', annotated_id: self.id).last
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

  def related_items_ids
    parent = Relationship.where(target_id: self.id).last&.source || self
    ids = [parent.id]
    Relationship.where(source_id: parent.id).find_each do |r|
      ids << r.target_id
    end
    ids.uniq.sort
  end

  def encode_with(coder)
    extra = { 'related_to_id' => self.related_to_id }
    coder['extra'] = extra
    coder['raw_attributes'] = attributes_before_type_cast
    coder['attributes'] = @attributes
    coder['new_record'] = new_record?
    coder['active_record_yaml_version'] = 0
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
    previous_user = User.current
    Relationship.where(target_id: project_media_id).each do |r|
      User.current = user
      r.skip_check_ability = true
      r.target = project_media
      r.destroy
      User.current = nil
      v = r.versions.from_partition(project_media.team_id).where(event_type: 'destroy_relationship').last
      unless v.nil?
        v.meta = r.version_metadata
        v.save!
      end
    end
    User.current = previous_user
  end

  def project_ids
    self.projects.map(&:id)
  end

  def add_destination_team_tasks(project, only_selected)
    tasks = project.team.auto_tasks(project.id, only_selected)
    existing_tasks = Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: self.id)
      .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tasks.map(&:id)) unless tasks.blank?
    unless existing_tasks.blank?
      tt_ids = existing_tasks.collect{|i| i.data['team_task_id']}
      tasks.delete_if {|t| tt_ids.include?(t.id)}
    end
    self.create_auto_tasks(project.id, tasks) unless tasks.blank?
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
    # set fields with integer value
    fields_i = ['archived', 'sources_count', 'linked_items_count', 'share_count', 'last_seen', 'demand', 'user_id', 'read']
    fields_i.each{ |f| ms.send("#{f}=", self.send(f).to_i) }
  end

  # private
  #
  # Please add private methods to app/models/concerns/project_media_private.rb
end
