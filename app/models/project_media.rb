class ProjectMedia < ActiveRecord::Base
  attr_accessible
  attr_accessor :information, :disable_es_callbacks

  belongs_to :project
  belongs_to :media
  belongs_to :user
  has_annotations

  after_create :set_quote_information, :set_initial_media_status, :add_elasticsearch_data
  after_update :set_information

  notifies_slack on: :create,
                 if: proc { |pm| m = pm.media; m.current_user.present? && m.current_team.present? && m.current_team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |pm| pm.slack_notification_message },
                 channel: proc { |pm| m = pm.media; m.project.setting(:slack_channel) || m.current_team.setting(:slack_channel) },
                 webhook: proc { |pm| m = pm.media; m.current_team.setting(:slack_webhook) }

  notifies_pusher on: :create,
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project] },
                  data: proc { |pm| pm.media.to_json }

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def media_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
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
    st.save!
  end

  def slack_notification_message
    m = self.media
    data = self.data
    type, text = m.quote.blank? ?
      [ 'link', data['title'] ] :
      [ 'claim', m.quote ]
    "*#{m.user.name}* added a new #{type}: <#{m.origin}/project/#{self.project_id}/media/#{m.id}|*#{text}*>"
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
    data = self.data
    unless data.nil?
      ms.title = data['title']
      ms.description = data['description']
      ms.quote = m.quote
    end
    ms.save!
    #ElasticSearchWorker.perform_in(1.second, YAML::dump(ms), YAML::dump({}), 'add_parent')
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def get_media_annotations(type = nil)
    em = self.media.annotations.where(annotation_type: type).last
  end

  def data
    em_pender = self.get_annotations('embed').last
    em_pender = self.get_media_annotations('embed') if em_pender.nil?
    embed = JSON.parse(em_pender.data['embed']) unless em_pender.nil?
    self.overriden_embed_attributes.each{ |k| sk = k.to_s; embed[sk] = em_pender.data[sk] unless em_pender.data[sk].nil? } unless embed.nil?
    embed
  end

  def tags
    self.get_annotations('tag')
  end

  def last_status
    last = self.get_annotations('status').first
    last.nil? ? Status.default_id(self, self.project) : last.data[:status]
  end

  def published
    self.created_at.to_i.to_s
  end

  def overriden_embed_attributes
    %W(title description username)
  end

  private

  def set_information
    info = self.parse_information
    unless self.information_blank?
      em = get_embed(self)
      em = set_information_for_context if em.nil?
      self.set_information_for_embed(em, info)
      self.information = {}.to_json
    end
  end

  def set_quote_information
    unless self.media.quote.blank?
      self.information = {title: self.media.quote}.to_json
      set_information
    end
  end

  protected

  def parse_information
    self.information.blank? ? {} : JSON.parse(self.information)
  end

  def information_blank?
    self.parse_information.all? { |_k, v| v.blank? }
  end

  def get_embed(obj)
    Embed.where(annotation_type: 'embed', annotated_type: obj.class.to_s , annotated_id: obj.id).last
  end

  def set_information_for_context
    em_none = get_embed(self.media)
    if em_none.nil?
      em = Embed.new
      em.embed = self.information
    else
      # clone existing one and reset annotator fields
      em = em_none.dup
      em.annotator_id = em.annotator_type = nil
    end
    em.annotated = self
    em.annotator = self.current_user unless self.current_user.nil?
    em
  end

  def set_information_for_embed(em, info)
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) and !v.blank? }
    em.save!
  end

end
