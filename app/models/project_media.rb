class ProjectMedia < ActiveRecord::Base
  attr_accessor :quote, :quote_attributions, :file, :previous_project_id, :set_annotation, :set_tasks_responses, :team, :cached_permissions, :is_being_created

  include ProjectAssociation
  include ProjectMediaAssociations
  include ProjectMediaCreators
  include ProjectMediaEmbed
  include ProjectMediaExport
  include Versioned
  include NotifyEmbedSystem
  include ValidationsHelper

  validates_presence_of :media, :project

  validate :project_is_not_archived, unless: proc { |pm| pm.is_being_copied  }
  validates :media_id, uniqueness: { scope: :project_id }

  after_create :set_quote_embed, :set_initial_media_status, :create_auto_tasks, :create_reverse_image_annotation, :create_annotation, :get_language, :create_mt_annotation, :send_slack_notification, :set_project_source
  after_update :move_media_sources

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

  def move_media_to_active_status
    s = self.get_annotations('status').last
    s = s.load unless s.nil?
    set_active_status(s) if !s.nil? && s.status == Status.default_id(self.media, self.project)
  end

  def set_active_status(s)
    active = Status.active_id(self.media, self.project)
    unless active.nil?
      s.status = active
      s.skip_check_ability = true
      s.save!
    end
  end

  def slack_notification_message
    type = self.media.class.name.demodulize.downcase
    User.current.present? ?
      I18n.t(:slack_create_project_media,
        user: Bot::Slack.to_slack(User.current.name),
        type: I18n.t(type.to_sym),
        url: Bot::Slack.to_slack_url(self.full_url, self.title),
        project: Bot::Slack.to_slack(self.project.title)
      ) :
      I18n.t(:slack_create_project_media_no_user,
        type: I18n.t(type.to_sym),
        url: Bot::Slack.to_slack_url(self.full_url, self.title),
        project: Bot::Slack.to_slack(self.project.title)
      )
  end

  def title
    title = self.media.quote unless self.media.quote.blank?
    title = self.embed['title'] unless self.embed.blank? || self.embed['title'].blank?
    title
  end

  def description
    description = self.text
    description = self.embed['description'] unless self.embed.blank? || self.embed['description'].blank?
    description
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

  def last_status_obj
    self.get_annotations('status').first
  end

  def last_status
    last = self.last_status_obj
    last.nil? ? Status.default_id(self, self.project) : last.data[:status]
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

  def notify_destroyed?
    true
  end

  def notify_updated?
    true
  end

  def notify_created?
    false
  end

  def notify_embed_system_updated_object
    { id: self.id.to_s }
  end

  def notify_embed_system_payload(event, object)
    { translation: object, condition: event, timestamp: Time.now.to_i }.to_json
  end

  def notification_uri(_event)
    url = self.project.nil? ? '' : [CONFIG['bridge_reader_url_private'], 'medias', 'notify', self.project.team.slug, self.project.id, self.id.to_s].join('/')
    URI.parse(URI.encode(url))
  end

  def project_source
    get_project_source(self.project_id)
  end

  def custom_permissions(ability = nil)
    perms = {}
    perms["embed ProjectMedia"] = !self.archived
    ability ||= Ability.new
    perms["restore ProjectMedia"] = ability.can?(:restore, self)
    perms
  end

  private

  def move_media_sources
    if self.project_id_changed?
      ps = get_project_source(self.project_id_was)
      unless ps.nil?
        target_ps = ProjectSource.where(project_id: self.project_id, source_id: ps.source_id).last
        if target_ps.nil?
          ps.project_id = self.project_id
          ps.skip_check_ability = true
          ps.disable_es_callbacks = Rails.env.to_s == 'test'
          ps.save!
        else
          ps.destroy
        end
      end
    end
  end

  def get_project_source(pid)
    sources = []
    sources = self.media.account.sources.map(&:id) unless self.media.account.nil?
    sources.concat ClaimSource.where(media_id: self.media_id).map(&:source_id)
    ProjectSource.where(project_id: pid, source_id: sources).first
  end

  def project_is_not_archived
    parent_is_not_archived(self.project, I18n.t(:error_project_archived, default: "Can't create media under trashed project"))
  end

  def update_media_account
    a = self.media.account
    embed = self.media.embed
    unless a.nil? || a.embed['author_url'] == embed['author_url']
      s = a.sources.where(team_id: Team.current.id).last
      s = nil if !s.nil? && s.name.start_with?('Untitled')
      new_a = self.send(:account_from_author_url, embed['author_url'], s)
      set_media_account(new_a, s) unless new_a.nil?
    end
  end

  def account_from_author_url(author_url, source)
    begin Account.create_for_source(author_url, source) rescue nil end
  end

  def set_media_account(account, source)
    m = self.media
    a = self.media.account
    m.account = account
    m.skip_check_ability = true
    m.save!
    a.skip_check_ability = true
    a.destroy if a.medias.count == 0
    # Add a project source if new source was created
    self.create_project_source if source.nil?
    # update es
    self.update_media_search(['account'], {account: self.set_es_account_data}, self.id)
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
end
