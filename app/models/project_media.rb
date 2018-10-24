class ProjectMedia < ActiveRecord::Base
  attr_accessor :quote, :quote_attributions, :file, :previous_project_id, :set_annotation, :set_tasks_responses, :team, :cached_permissions, :is_being_created, :related_to_id

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

  after_create :set_quote_embed, :create_auto_tasks, :create_reverse_image_annotation, :create_annotation, :get_language, :create_mt_annotation, :send_slack_notification, :set_project_source, :notify_team_bots_create
  after_commit :create_relationship, on: :create
  after_update :move_media_sources, :archive_or_restore_related_medias_if_needed, :notify_team_bots_update
  after_destroy :destroy_related_medias

  notifies_pusher on: [:save, :destroy],
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project, pm.project_was, pm.media, pm.project.team] },
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
    statuses = Workflow::Workflow.options(self, self.default_media_status_type)[:statuses]
    current_status = statuses.select { |st| st['id'] == self.last_status }
    user = self.user
    {
      user: user.nil? ? nil : Bot::Slack.to_slack(user.name),
      user_image: user.nil? ? nil : user.profile_image,
      project: Bot::Slack.to_slack(self.project.title),
      role: user.nil? ? nil : I18n.t("role_" + user.role(self.project.team).to_s),
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
    no_user = params[:user] ? "" : "_no_user"
    {
      pretext: I18n.t("slack.messages.project_media_#{event}#{no_user}", params),
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
    self.embed.dig('title') || self.media.quote
  end

  def description
    self.embed.dig('description') || (self.media.type == 'Claim' ? nil : self.text)
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def embed
    em_pender = self.media.get_annotations('embed').last
    em_overriden = self.get_annotations('embed').last
    if em_overriden.nil?
      em = em_pender
    else
      em = em_overriden
      em['data']['embed'] = em_pender['data']['embed'] unless em_pender.nil?
    end
    embed = JSON.parse(em.data['embed']) unless em.nil?
    self.overridden_embed_attributes.each{ |k| sk = k.to_s; embed[sk] = em.data[sk] unless em.data[sk].nil? } unless embed.nil?
    embed
  end

  def overridden
    data = {}
    self.overridden_embed_attributes.each{|k| data[k] = false}
    if self.media.type == 'Link'
      em = self.get_annotations('embed').last
      unless em.nil?
        em_media = self.media.get_annotations('embed').last
        data.each do |k, _v|
          data[k] = true if em['data'][k] != em_media['data'][k] and !em['data'][k].blank?
        end
      end
    end
    data
  end

  def overridden_embed_attributes
    %W(title description username)
  end

  def embed=(info)
    info = info.blank? ? {} : JSON.parse(info)
    unless info.blank?
      em = self.get_annotations('embed').last
      em = em.load unless em.nil?
      em = initiate_embed_annotation(info) if em.nil?
      em.disable_es_callbacks = Rails.env.to_s == 'test'
      em.client_mutation_id = self.client_mutation_id
      self.override_embed_data(em, info)
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

  def get_language
    Bot::Alegre.default.get_language_from_alegre(self.text, self) unless Bot::Alegre.default.nil?
  end

  def full_url
    "#{self.project.url}/media/#{self.id}"
  end

  def update_mt=(_update)
    mt = self.annotations.where(annotation_type: 'mt').last
    MachineTranslationWorker.perform_in(1.second, YAML::dump(self), YAML::dump(User.current)) unless mt.nil?
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
    unresolved = required_tasks.select{ |t| t.status != 'Resolved' }
    unresolved.blank?
  end

  def is_finished?
    statuses = Workflow::Workflow.options(self, self.default_media_status_type)[:statuses]
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

  protected

  def initiate_embed_annotation(info)
    em = Embed.new
    em.embed = info.to_json
    em.annotated = self
    em.annotator = User.current unless User.current.nil?
    em
  end

  def override_embed_data(em, info)
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) }
    em.skip_notifications = true if self.is_being_created
    em.save!
  end

  def set_es_account_data
    data = {}
    a = self.media.account
    embed = a.embed
    self.overridden_embed_attributes.each{ |k| sk = k.to_s; data[sk] = embed[sk] unless embed[sk].nil? } unless embed.nil?
    data["id"] = a.id unless data.blank?
    [data]
  end

  # private
  #
  # Please add private methods to app/models/concerns/project_media_private.rb

end
