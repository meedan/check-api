class Relationship < ActiveRecord::Base
  include CheckElasticSearch

  belongs_to :source, class_name: 'ProjectMedia'
  belongs_to :target, class_name: 'ProjectMedia'

  serialize :relationship_type

  validate :relationship_type_is_valid

  after_create :increment_counters, :index_source
  after_update :propagate_inversion, :reset_counters
  after_destroy :decrement_counters, :unindex_source

  has_paper_trail on: [:create, :update, :destroy], if: proc { |x| User.current.present? && !x.is_being_copied }

  notifies_pusher on: [:save, :destroy],
                  event: 'relationship_change',
                  targets: proc { |r| r.source.nil? ? [] : [r.source.media] },
                  bulk_targets: proc { |r| [r.source.media] },
                  if: proc { |r| !r.skip_notifications },
                  data: proc { |r| Relationship.where(id: r.id).last.nil? ? { source_id: r.source_id }.to_json : r.to_json }

  def siblings(inclusive = false, limit = 50)
    query = Relationship
    .includes(:target)
    .where(source_id: self.source_id)
    .where('relationship_type = ?', self.relationship_type.to_yaml)
    .order('id DESC')
    .limit(limit)
    query = inclusive ? query : query.where.not(target_id: self.target_id)
    pms = []
    query.collect do |r|
      t = r.target
      next if t.inactive
      pm = t
      pm.relationship = r
      pms << pm
    end
    pms
  end

  def source_project_media
    self.source
  end

  def target_project_media
    self.target
  end

  def version_metadata(_object_changes = nil)
    target = self.target
    target.nil? ? nil : {
      target: {
        title: target.title,
        type: target.report_type,
        url: target.full_url
      }
    }.to_json
  end

  def self.targets_grouped_by_type(project_media, filters = nil, limit = 50)
    targets = {}
    ids = nil
    unless filters.blank?
      filters['projects'] ||= [project_media.project_id.to_s]
      search = CheckSearch.new(filters.to_json)
      query = search.medias_build_search_query
      ids = search.medias_get_search_result(query).map(&:annotated_id).map(&:to_i)
    end
    relationships_mapping = {}
    project_media.source_relationships.includes(:target).limit(limit).each do |relationship|
      key = relationship.relationship_type.to_json
      targets[key] ||= []
      if ids.nil? || ids.include?(relationship.target_id)
        relationships_mapping[relationship.target_id] = relationship
        targets[key] << relationship.target_id
      end
    end
    list = []
    targets.each do |key, value|
      id = [project_media.id, key].join('/')
      medias = ProjectMedia.where(id: value, inactive: false).order('id DESC').limit(limit).collect{ |t| t.relationship = relationships_mapping[t.id] ; t }
      list << { type: key, targets: medias, id: id }.with_indifferent_access
    end
    list
  end

  def self.default_type
    { source: 'parent', target: 'child' }
  end

  def self.target_id(project_media, type = Relationship.default_type)
    Base64.encode64("RelationshipsTarget/#{project_media.id}/#{type.to_json}")
  end

  def self.source_id(project_media, type = Relationship.default_type)
    Base64.encode64("RelationshipsSource/#{project_media.id}/#{type.to_json}")
  end

  def is_being_copied
    self.source && self.source.is_being_copied
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

  def reset_counters
    if (self.source_id_was && self.source_id_was != self.source_id) || (self.target_id_was && self.target_id_was != self.target_id)
      previous = Relationship.new(source_id: self.source_id_was, target_id: self.target_id_was)
      previous.update_counters(-1)
      previous.send :unindex_source
      current = Relationship.new(source_id: self.source_id, target_id: self.target_id)
      current.update_counters(1)
      current.send :index_source
    end
  end

  def index_source
    self.update_elasticsearch_doc(['relationship_sources'], { 'relationship_sources' => self.es_values }, self.target)
  end

  def unindex_source
    value = self.es_values - [self.es_value]
    value = ['-'] if value.empty?
    self.update_elasticsearch_doc(['relationship_sources'], { 'relationship_sources' => value }, self.target)
  end

  def propagate_inversion
    if self.source_id_was == self.target_id && self.target_id_was == self.source_id
      ids = Relationship.where(source_id: self.target_id).map(&:graphql_id)
      GraphqlCrudOperations.crud_operation('update', self, { source_id: self.source_id, ids: ids }, nil, [], {})
    end
  end
end
