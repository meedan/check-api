class Relationship < ActiveRecord::Base
  include CheckElasticSearch

  attr_accessor :is_being_copied

  belongs_to :source, class_name: 'ProjectMedia'
  belongs_to :target, class_name: 'ProjectMedia'
  belongs_to :user

  serialize :relationship_type

  before_validation :set_user
  validate :relationship_type_is_valid
  validate :items_are_from_the_same_team
  validates :relationship_type, uniqueness: { scope: [:source_id, :target_id], message: :already_exists }, on: :create

  after_create :point_targets_to_new_source, :update_counters, prepend: true
  after_update :reset_counters, prepend: true
  after_update :propagate_inversion
  after_destroy :update_counters, prepend: true
  after_commit :update_counters

  has_paper_trail on: [:create, :update, :destroy], if: proc { |x| User.current.present? && !x.is_being_copied? }, class_name: 'Version'

  notifies_pusher on: [:save, :destroy],
                  event: 'relationship_change',
                  targets: proc { |r| r.source.nil? ? [] : [r.source.media, r.target.media] }, bulk_targets: proc { |r| [r.source.media, r.target.media] },
                  if: proc { |r| !r.skip_notifications },
                  data: proc { |r| Relationship.where(id: r.id).last.nil? ? { source_id: r.source_id, target_id: r.target_id }.to_json : r.to_json }

  scope :confirmed, -> { where('relationship_type = ?', Relationship.confirmed_type.to_yaml) }

  def team
    self.source.team
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

  def self.confirmed_parent(pm)
    parent = Relationship.confirmed.where(target_id: pm.id).last&.source
    parent || pm
  end

  def is_suggested?
    Relationship.suggested_type == self.relationship_type
  end

  def is_confirmed?
    Relationship.confirmed_type == self.relationship_type
  end

  def is_default?
    Relationship.default_type == self.relationship_type
  end

  def self.suggested_type
    { source: 'suggested_sibling', target: 'suggested_sibling' }
  end

  def self.confirmed_type
    { source: 'confirmed_sibling', target: 'confirmed_sibling' }
  end

  def self.default_type
    { source: 'parent', target: 'child' }
  end

  def self.propagate_inversion(ids, source_id)
    Relationship.where(id: ids.split(',')).each do |r|
      r.source_id = source_id
      r.send(:reset_counters)
    end
  end

  def is_being_copied?
    (self.source && self.source.is_being_copied) || self.is_being_copied
  end

  # Overwrite
  def destroy_annotations_and_versions
    # We want to keep the history of related items added or removed
  end

  def relationship_source_type=(type)
    self.relationship_type ||= {}
    self.relationship_type[:source] = type
  end

  def relationship_target_type=(type)
    self.relationship_type ||= {}
    self.relationship_type[:target] = type
  end

  protected

  def update_counters
    return if self.is_default?
    source = self.source
    target = self.target

    target.skip_check_ability = true
    target.sources_count = Relationship.where(target_id: target.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
    target.save!

    source.skip_check_ability = true
    source.targets_count = Relationship.where(source_id: source.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
    source.save!
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

  def reset_counters
    if (self.source_id_was && self.source_id_was != self.source_id) || (self.target_id_was && self.target_id_was != self.target_id)
      previous = Relationship.new(source_id: self.source_id_was, target_id: self.target_id_was)
      previous.update_counters
      current = Relationship.new(source_id: self.source_id, target_id: self.target_id)
      current.update_counters
    end
  end

  def propagate_inversion
    if self.source_id_was == self.target_id && self.target_id_was == self.source_id
      ids = Relationship.where(source_id: self.target_id).map(&:id).join(',')
      Relationship.where(source_id: self.target_id).update_all({ source_id: self.source_id })
      Relationship.delay_for(1.second).propagate_inversion(ids, self.source_id)
    end
  end

  def set_user
    current_user = User.current
    self.user = current_user if self.user.nil? && !current_user.nil?
  end

  def items_are_from_the_same_team
    if self.source && self.target && self.source.team_id != self.target.team_id
      errors.add(:base, I18n.t(:relationship_not_same_team))
    end
  end

  def point_targets_to_new_source
    Relationship.where(source_id: self.target_id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).each do |old_relationship|
      old_relationship.delete
      new_relationship = Relationship.new(source_id: self.source_id, target_id: old_relationship.target_id, relationship_type: old_relationship.relationship_type, user_id: old_relationship.user_id, weight: old_relationship.weight)
      new_relationship.skip_check_ability = true
      new_relationship.save!
    end
  end
end
