class Relationship < ActiveRecord::Base
  include CheckElasticSearch

  belongs_to :source, class_name: 'ProjectMedia'
  belongs_to :target, class_name: 'ProjectMedia'

  serialize :relationship_type

  validate :relationship_type_is_valid

  before_update { |relationship| raise ActiveRecord::ReadOnlyRecord }
  after_create :increment_counters, :index_source
  after_destroy :decrement_counters, :unindex_source

  def siblings
    ProjectMedia
    .joins(:target_relationships)
    .where('relationships.source_id': self.source_id)
    .where('relationships.relationship_type = ?', self.relationship_type.to_yaml)
    .where.not('relationships.target_id': self.target_id)
  end

  def self.targets_grouped_by_type(project_media)
    targets = {}
    project_media.source_relationships.includes(:target).each do |relationship|
      key = relationship.relationship_type.to_json
      targets[key] ||= []
      targets[key] << relationship.target
    end
    list = []
    targets.each do |key, value|
      id = [project_media.id, key].join(':')
      list << { type: key, targets: value, id: id }.with_indifferent_access
    end
    list
  end

  private

  def relationship_type_is_valid
    begin
      value = self.relationship_type.with_indifferent_access
      raise('Relationship type is invalid') unless (value.keys == ['source', 'target'] && value['source'].is_a?(String) && value['target'].is_a?(String))
    rescue
      errors.add(:relationship_type)
    end
  end

  def increment_counters
    self.source.update_column(:targets_count, self.source.targets_count + 1)
    self.target.update_column(:sources_count, self.target.sources_count + 1)
  end

  def decrement_counters
    self.source.update_column(:targets_count, self.source.targets_count - 1)
    self.target.update_column(:sources_count, self.target.sources_count - 1)
  end

  def index_source
    self.update_media_search(['relationship_source_id'], { 'relationship_source_id' => self.source_id }, self.target)
  end

  def unindex_source
    self.update_media_search(['relationship_source_id'], { 'relationship_source_id' => '0' }, self.target)
  end
end
