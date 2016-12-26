class Tag < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  field :tag, String, presence: true
  field :full_tag, String, presence: true

  validates_presence_of :tag
  validates :data, uniqueness: { scope: [:annotated_type, :annotated_id] }, if: lambda { |t| t.id.blank? }
  validates :annotated_type, included: { values: ['ProjectSource', 'ProjectMedia', nil] }

  before_validation :normalize_tag, :store_full_tag
  after_save :add_update_elasticsearch_tag

  def content
    { tag: self.tag }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

  private

  def normalize_tag
    self.tag = self.tag.gsub(/^#/, '') unless self.tag.nil?
  end

  def store_full_tag
    self.full_tag = self.tag
  end

  def add_update_elasticsearch_tag
    add_update_media_search_child('tag_search', %w(tag full_tag))
  end

end
