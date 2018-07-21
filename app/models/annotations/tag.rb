class Tag < ActiveRecord::Base
  include AnnotationBase

  field :tag, String, presence: true

  validates_presence_of :tag
  validates :data, uniqueness: { scope: [:annotated_type, :annotated_id], message: :already_exists }, if: lambda { |t| t.id.blank? }

  before_validation :normalize_tag
  after_commit :add_elasticsearch_tag, on: :create
  after_commit :update_elasticsearch_tag, on: :update
  after_commit :destroy_elasticsearch_tag, on: :destroy

  def content
    { tag: self.tag }.to_json
  end

  private

  def normalize_tag
    self.tag = self.tag.strip.gsub(/^#/, '') unless self.tag.nil?
  end

  def add_elasticsearch_tag
    add_update_nested_obj({op: 'create', nested_key: 'tags', keys: ['tag']})
  end

  def update_elasticsearch_tag
    add_update_nested_obj({op: 'update', nested_key: 'tags', keys: ['tag']})
  end

  def destroy_elasticsearch_tag
    destroy_es_items('tags')
  end
end
