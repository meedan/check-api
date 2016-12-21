class Media < ActiveRecord::Base
  attr_accessible
  attr_accessor :project_id, :duplicated_of, :information, :project_object

  has_paper_trail on: [:create, :update]
  belongs_to :account
  belongs_to :user
  has_many :project_medias
  has_many :projects, through: :project_medias
  has_annotations

  include PenderData
  include MediaInformation

  validate :validate_pender_result, on: :create
  validate :pender_result_is_an_item, on: :create
  validate :url_is_unique, on: :create
  validate :validate_quote_for_media_with_empty_url, on: :create

  before_validation :set_url_nil_if_empty, :set_user, on: :create
  after_create :set_pender_result_as_annotation, :set_information, :set_project, :set_account
  after_update :set_information
  after_rollback :duplicate

  def current_team
    self.project.team if self.project
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def account_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

  def jsondata(context = nil)
    context = self.get_media_context(context)
    self.data(context).to_json
  end

  def project_media(context = nil)
    context = self.get_media_context(context)
    self.project_medias.find_by(:project_id => context.id) unless context.nil?
  end

  def user_in_context(context = nil)
    context = self.get_media_context(context)
    self.user if context.nil?
    pm = project_media(context)
    pm.user unless pm.nil?
  end

  def cached_annotations(type = nil, context = nil)
    return self.annotations(type, context) if self.no_cache
    @cached_annotations ||= self.annotations
    type = [type].flatten
    cached_annotations_filtered(type, context)
  end

  def data(context = nil)
    context = self.get_media_context(context)
    em_pender = self.cached_annotations('embed', context).last unless context.nil?
    em_pender = self.cached_annotations('embed', 'none').last if em_pender.nil?
    embed = JSON.parse(em_pender.data['embed']) unless em_pender.nil?
    self.overriden_embed_attributes.each{ |k| sk = k.to_s; embed[sk] = em_pender.data[sk] unless em_pender.data[sk].nil? } unless embed.nil?
    embed
  end

  def tags(context = nil)
    context = self.get_media_context(context)
    self.cached_annotations('tag', context)
  end

  def last_status(context = nil)
    context = self.get_media_context(context)
    last = self.cached_annotations('status', context).first
    last.nil? ? Status.default_id(self, context) : last.data[:status]
  end

  def published(context = nil)
    context = self.get_media_context(context)
    return self.created_at.to_i.to_s if context.nil?
    pm = project_media(context)
    pm.created_at.to_i.to_s unless pm.nil?
  end

  def get_team
    self.projects.map(&:team_id)
  end

  def get_team_objects
    self.projects.map(&:team)
  end

  def associate_to_project
    if !self.project_id.blank? && !ProjectMedia.where(project_id: self.project_id, media_id: self.id).exists?
      pm = ProjectMedia.new
      pm.project_id = self.project_id
      pm.media = self
      pm.user = pm.current_user = self.current_user
      pm.context_team = self.context_team
      pm.save!
    end
  end

  def relay_id
    str = "Media/#{self.id}"
    str += "/#{self.project_id}" unless self.project_id.nil?
    Base64.encode64(str)
  end

  def get_media_context(context = nil)
    context.nil? ? self.project : context
  end

  def domain
    host = URI.parse(self.url).host unless self.url.nil?
    host.nil? ? nil : host.gsub(/^(www|m)\./, '')
  end

  def project
    return self.project_object unless self.project_object.nil?
    if self.project_id
      Rails.cache.fetch("project_#{self.project_id}", expires_in: 30.seconds) do
        Project.find(self.project_id)
      end
    end
  end

  def overriden_embed_attributes
    %W(title description username quote)
  end

  protected

  def cached_annotations_filtered(type, context)
    ret = @cached_annotations
    ret = ret.select{ |a| type.include?(a.annotation_type) } unless type.nil?
    ret = ret.select{ |a| a.context_type == context.class.name && a.context_id.to_s == context.id.to_s } if context.kind_of?(ActiveRecord::Base)
    ret = ret.select{ |a| a.context_id.blank? } if context == 'none'
    ret = ret.select{ |a| !a.context_id.blank? } if context == 'some'
    ret
  end

  private

  def set_url_nil_if_empty
    self.url = nil if self.url.blank?
  end

  def set_user
    self.user = self.current_user unless self.current_user.nil?
  end

  def set_account
    unless self.pender_data.nil?
      account = Account.new
      account.url = self.pender_data['author_url']
      if account.save
        self.account = account
      else
        self.account = Account.where(url: account.url).last
      end
      self.save!
    end
  end

  def pender_result_is_an_item
    unless self.pender_data.nil?
      errors.add(:base, 'Sorry, this is not a valid media item') unless self.pender_data['type'] == 'item'
    end
  end

  def url_is_unique
    unless self.url.nil?
      existing = Media.where(url: self.url).first
      self.duplicated_of = existing
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end

  def validate_quote_for_media_with_empty_url
      if self.url.blank? and self.quote.blank?
        errors.add(:base, "quote can't be blank")
      end
  end

  def set_project
    self.associate_to_project
  end

  def duplicate
    dup = self.duplicated_of
    unless dup.blank?
      dup.project_id = self.project_id
      dup.context_team = self.context_team
      dup.current_user = self.current_user
      dup.origin = self.origin
      dup.associate_to_project
      return false
    end
    true
  end
end
