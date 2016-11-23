class Tag < ActiveRecord::Base
  include AnnotationBase

  field :tag, String, presence: true
  field :full_tag, String, presence: true

  validates_presence_of :tag
  validates :data, uniqueness: { scope: [:annotated_type, :annotated_id, :context_type, :context_id] }, if: lambda { |t| t.id.blank? }
  
  before_validation :normalize_tag, :store_full_tag

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
end
