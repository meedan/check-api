class ProjectMedia < ActiveRecord::Base
  attr_accessor :url, :quote, :file, :embed, :disable_es_callbacks, :previous_project_id, :set_annotation

  include ProjectMediaAssociations
  include ProjectMediaCreators
  include ProjectMediaEmbed
  include Versioned
  include NotifyEmbedSystem

  validates_presence_of :media_id, :project_id

  before_validation :set_media, :set_user, on: :create
  validate :is_unique, on: :create

  after_create :set_quote_embed, :set_initial_media_status, :add_elasticsearch_data, :create_auto_tasks, :create_reverse_image_annotation, :create_annotation, :get_language, :create_mt_annotation, :send_slack_notification
  after_update :update_elasticsearch_data
  before_destroy :destroy_elasticsearch_media

  notifies_pusher on: :save,
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project, pm.media] },
                  if: proc { |pm| !pm.skip_notifications },
                  data: proc { |pm| pm.media.as_json.merge(class_name: pm.report_type).to_json }

  include CheckElasticSearch

  def report_type
    self.media.class.name.downcase
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def set_initial_media_status
    st = Status.new
    st.annotated = self
    st.annotator = self.user
    st.status = Status.default_id(self.media, self.project)
    st.created_at = self.created_at
    st.disable_es_callbacks = self.disable_es_callbacks
    st.skip_check_ability = true
    st.save!
  end

  def slack_notification_message
    type = self.media.class.name.demodulize.downcase
    User.current.present? ?
      I18n.t(:slack_create_project_media,
        user: Bot::Slack.to_slack(User.current.name),
        type: I18n.t(type.to_sym),
        url: Bot::Slack.to_slack_url(self.full_url, "*#{self.title}*"),
        project: Bot::Slack.to_slack(self.project.title)
      ) :
      I18n.t(:slack_create_project_media_no_user,
        type: I18n.t(type.to_sym),
        url: Bot::Slack.to_slack_url(self.full_url, "*#{self.title}*"),
        project: Bot::Slack.to_slack(self.project.title)
      )
  end

  def title
    title = self.media.quote unless self.media.quote.blank?
    title = self.embed['title'] unless self.embed.blank? || self.embed['title'].blank?
    title
  end

  def add_elasticsearch_data
    return if self.disable_es_callbacks
    p = self.project
    m = self.media
    ms = MediaSearch.new
    ms.id = self.id
    ms.team_id = p.team.id
    ms.project_id = p.id
    ms.set_es_annotated(self)
    ms.status = self.last_status unless CONFIG['app_name'] === 'Bridge'
    data = self.embed
    unless data.nil?
      ms.title = data['title']
      ms.description = data['description']
      ms.quote = m.quote
    end
    ms.account = self.set_es_account_data unless self.media.account.nil?
    ms.save!
  end

  def update_elasticsearch_data
    return if self.disable_es_callbacks
    if self.project_id_changed?
      keys = %w(project_id team_id)
      data = {'project_id' => self.project_id, 'team_id' => self.project.team_id}
      options = {keys: keys, data: data, parent: self.id}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_parent')
    end
  end

  def destroy_elasticsearch_media
    destroy_elasticsearch_data(MediaSearch, 'parent')
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def get_versions_log
    PaperTrail::Version.where(project_media_id: self.id).order('created_at ASC')
  end

  def get_versions_log_count
    self.reload.cached_annotations_count
  end

  def get_media_annotations(type = nil)
    self.media.annotations.where(annotation_type: type).last
  end

  def embed
    em_pender = self.get_media_annotations('embed')
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

  def last_status
    last = self.get_annotations('status').first
    last.nil? ? Status.default_id(self, self.project) : last.data[:status]
  end

  def overridden
    data = {}
    self.overridden_embed_attributes.each{|k| data[k] = false}
    if self.media.type == 'Link'
      em = self.get_annotations('embed').last
      unless em.nil?
        em_media = self.get_media_annotations('embed')
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
      self.override_embed_data(em, info)
    end
  end

  def self.belonged_to_project(pmid, pid)
    pm = ProjectMedia.find_by_id pmid
    if pm && (pm.project_id == pid || pm.versions.where_object(project_id: pid).exists?)
      return pm.id
    else
      pm = ProjectMedia.where(project_id: pid, media_id: pmid).last
      return pm.id if pm
    end
  end

  def project_was
    Project.find(self.previous_project_id) unless self.previous_project_id.blank?
  end

  def refresh_media=(_refresh)
    self.media.refresh_pender_data
    self.updated_at = Time.now
  end

  def text
    self.media.text
  end

  def get_language
    bot = Bot::Alegre.default
    bot.get_language_from_alegre(self.text, self) unless bot.nil?
  end

  def full_url
    "#{self.project.url}/media/#{self.id}"
  end

  def check_search_team
    CheckSearch.new({ 'parent' => { 'type' => 'team', 'slug' => self.project.team.slug } }.to_json)
  end

  def check_search_project
    CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => self.project.id }, 'projects' => [self.project.id] }.to_json)
  end

  def should_create_auto_tasks?
    self.project && self.project.team && !self.project.team.get_checklist.blank?
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

  private

  def is_unique
    pm = ProjectMedia.where(project_id: self.project_id, media_id: self.media_id).last
    errors.add(:base, "This media already exists in this project and has id #{pm.id}") unless pm.nil?
  end

  def set_media
    unless self.url.blank? && self.quote.blank? && self.file.blank?
      m = self.create_media
      self.media_id = m.id unless m.nil?
    end
  end

  def set_quote_embed
    self.embed = ({ title: self.media.quote }.to_json) unless self.media.quote.blank?
    self.embed = ({ title: File.basename(self.media.file.path) }.to_json) unless self.media.file.blank?
  end

  def set_user
    self.user = User.current unless User.current.nil?
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
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) and !v.blank? }
    em.save!
  end

  def set_es_account_data
    data = {}
    a = self.media.account
    em = a.annotations('embed').last
    embed = JSON.parse(em.data['embed']) unless em.nil?
    self.overridden_embed_attributes.each{ |k| sk = k.to_s; data[sk] = embed[sk] unless embed[sk].nil? } unless embed.nil?
    data["id"] = a.id unless data.blank?
    [data]
  end
end
