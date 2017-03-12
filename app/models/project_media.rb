class ProjectMedia < ActiveRecord::Base
  attr_accessor :url, :quote, :file, :embed, :disable_es_callbacks, :previous_project_id

  belongs_to :project
  belongs_to :media
  belongs_to :user
  has_annotations

  include Versioned

  validates_presence_of :media_id, :project_id

  before_validation :set_media, :set_user, on: :create
  validate :is_unique, on: :create

  after_create :set_quote_embed, :set_initial_media_status, :add_elasticsearch_data, :create_auto_tasks, :create_reverse_image_annotation
  after_update :update_elasticsearch_data
  before_destroy :destroy_elasticsearch_media

  notifies_slack on: :create,
                 if: proc { |pm| t = pm.project.team; User.current.present? && t.present? && t.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |pm| pm.slack_notification_message },
                 channel: proc { |pm| p = pm.project; p.setting(:slack_channel) || p.team.setting(:slack_channel) },
                 webhook: proc { |pm| pm.project.team.setting(:slack_webhook) }

  notifies_pusher on: :create,
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project] },
                  if: proc { |pm| !pm.skip_notifications },
                  data: proc { |pm| pm.media.to_json }

  include CheckElasticSearch

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
    I18n.t(:slack_create_project_media,
      user: self.class.to_slack(User.current.name),
      type: I18n.t(type.to_sym),
      url: self.class.to_slack_url("#{self.project.team.slug}/project/#{self.project_id}/media/#{self.id}", "*#{self.title}*"),
      project: self.class.to_slack(self.project.title)
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
    ms.status = self.last_status
    data = self.embed
    unless data.nil?
      ms.title = data['title']
      ms.description = data['description']
      ms.quote = m.quote
    end
    ms.save!
    # ElasticSearchWorker.perform_in(1.second, YAML::dump(ms), YAML::dump({}), 'add_parent')
  end

  def update_elasticsearch_data
    return if self.disable_es_callbacks
    if self.project_id_changed?
      keys = %w(project_id team_id)
      data = {'project_id' => self.project_id, 'team_id' => self.project.team_id}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(keys), YAML::dump(data), 'update_parent')
    end
  end

  def destroy_elasticsearch_media
    destroy_elasticsearch_data(MediaSearch, 'parent')
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def get_versions_log
    events = %w(create_comment update_status create_tag create_task create_dynamicannotationfield update_dynamicannotationfield create_flag update_embed update_projectmedia update_task create_embed)

    joins = "LEFT JOIN annotations "\
            "ON versions.item_type IN ('Status','Comment','Embed','Tag','Flag','Dynamic','Task','Annotation') "\
            "AND CAST(annotations.id AS TEXT) = versions.item_id "\
            "AND annotations.annotated_type = 'ProjectMedia' "\
            "LEFT JOIN dynamic_annotation_fields d "\
            "ON CAST(d.id AS TEXT) = versions.item_id "\
            "AND versions.item_type = 'DynamicAnnotation::Field' "\
            "LEFT JOIN annotations a2 "\
            "ON a2.id = d.annotation_id "\
            "AND a2.annotated_type = 'ProjectMedia'"

    where = "(annotations.id IS NOT NULL AND annotations.annotated_id = ?) "\
            "OR (d.id IS NOT NULL AND a2.annotated_id = ?)"\
            "OR (annotations.id IS NULL AND d.id IS NULL AND versions.item_type = 'ProjectMedia' AND versions.item_id = ?)"

    PaperTrail::Version.joins(joins).where(where, self.id, self.id, self.id.to_s).where('versions.event_type' => events).distinct('versions.id').order('versions.created_at ASC')
  end

  def get_versions_log_count
    self.get_versions_log.where.not(event_type: 'create_dynamicannotationfield').count
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

  protected

  def create_image
    m = UploadedImage.new
    m.file = self.file
    m.save!
    m
  end

  def create_claim
    m = Claim.new
    m.quote = self.quote
    m.save!
    m
  end

  def create_link
    m = Link.new
    m.url = self.url
    # call m.valid? to get normalized URL before caling 'find_or_create_by'
    m.valid?
    m = Link.find_or_create_by(url: m.url)
    m
  end

  def create_media
    m = nil
    if !self.file.blank?
      m = self.create_image
    elsif !self.quote.blank?
      m = self.create_claim
    else
      m = self.create_link
    end
    m
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

  def create_auto_tasks
    if self.project && self.project.team && !self.project.team.get_checklist.blank?
      self.project.team.get_checklist.each do |task|
        if task['projects'].empty? || task['projects'].include?(self.project.id)
          t = Task.new
          t.label = task['label']
          t.type = task['type']
          t.description = task['description']
          t.annotator = User.current
          t.annotated = self
          t.skip_check_ability = true
          t.save!
        end
      end
    end
  end

  def create_reverse_image_annotation
    picture = self.media.picture
    unless picture.blank?
      d = Dynamic.new
      d.skip_check_ability = true
      d.skip_notifications = true
      d.annotation_type = 'reverse_image'
      d.annotator = Bot.where(name: 'Check Bot').last
      d.annotated = self
      d.set_fields = { reverse_image_path: picture }.to_json
      d.save!
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
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) and !v.blank? }
    em.save!
  end
end
