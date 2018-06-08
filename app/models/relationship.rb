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

  def self.targets_grouped_by_type(project_media, filters = nil)
    targets = {}
    ids = nil
    unless filters.nil?
      filters['projects'] ||= [project_media.project_id.to_s]
      search = CheckSearch.new(filters.to_json)
      query = search.medias_build_search_query
      ids = search.medias_get_search_result(query).map(&:annotated_id).map(&:to_i)
    end
    project_media.source_relationships.includes(:target).each do |relationship|
      key = relationship.relationship_type.to_json
      targets[key] ||= []
      targets[key] << relationship.target if ids.nil? || ids.include?(relationship.target_id)
    end
    list = []
    targets.each do |key, value|
      id = [project_media.id, key].join(':')
      list << { type: key, targets: value, id: id }.with_indifferent_access
    end
    list
  end

  protected

  def es_values
    list = []
    unless self.target.nil?
      self.target.target_relationships.each do |relationship|
        list << relationship.es_value
      end
    end
    list
  end

  def es_value
    Digest::MD5.hexdigest(self.relationship_type.to_json) + '_' + self.source_id.to_s
  end

  def update_counters(value)
    self.source.update_column(:targets_count, self.source.targets_count + value) unless self.source.nil?
    self.target.update_column(:sources_count, self.target.sources_count + value) unless self.target.nil?
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
    self.update_counters(1)
  end

  def decrement_counters
    self.update_counters(-1)
  end

  def index_source
    self.update_media_search(['relationship_sources'], { 'relationship_sources' => self.es_values }, self.target)
  end

  def unindex_source
    value = self.es_values - [self.es_value]
    value = ['-'] if value.empty?
    self.update_media_search(['relationship_sources'], { 'relationship_sources' => value }, self.target)
  end
end
