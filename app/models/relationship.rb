class Relationship < ApplicationRecord
  include CheckElasticSearch
  include RelationshipBulk

  attr_accessor :is_being_copied, :add_to_project_id, :archive_target

  belongs_to :source, class_name: 'ProjectMedia', optional: true
  belongs_to :target, class_name: 'ProjectMedia', optional: true
  belongs_to :user, optional: true

  serialize :relationship_type

  before_validation :set_user, on: :create
  before_validation :set_confirmed, if: :is_being_confirmed?, on: :update
  before_validation :set_cluster, if: :is_being_confirmed?, on: :update
  validate :relationship_type_is_valid, :items_are_from_the_same_team
  validate :target_not_pulished_report, on: :create
  validate :similar_item_exists, on: :create, if: proc { |r| r.is_suggested? }
  validate :cant_be_related_to_itself
  validates :relationship_type, uniqueness: { scope: [:source_id, :target_id], message: :already_exists }, on: :create

  before_create :destroy_suggest_item, if: proc { |r| r.is_confirmed? }
  after_create :move_to_same_project_as_main, prepend: true
  after_create :point_targets_to_new_source, :update_counters, prepend: true
  after_update :reset_counters, prepend: true
  after_update :propagate_inversion
  before_destroy :archive_detach_to_list
  after_destroy :update_counters, prepend: true
  after_commit :update_counter_and_elasticsearch, on: [:create, :update]
  after_commit :update_counters, :destroy_elasticsearch_relation, on: :destroy
  after_commit :set_cluster, on: [:create]

  has_paper_trail on: [:create, :update, :destroy], if: proc { |x| User.current.present? && !x.is_being_copied? }, versions: { class_name: 'Version' }

  notifies_pusher on: [:save, :destroy],
                  event: 'relationship_change',
                  targets: proc { |r| r.source.nil? ? [] : [r.source&.media, r.target&.media] }, bulk_targets: proc { |r| [r.source&.media, r.target&.media] },
                  if: proc { |r| !r.skip_notifications },
                  data: proc { |r| Relationship.where(id: r.id).last.nil? ? { source_id: r.source_id, target_id: r.target_id }.to_json : r.to_json }

  scope :confirmed, -> { where('relationship_type = ?', Relationship.confirmed_type.to_yaml) }
  scope :suggested, -> { where('relationship_type = ?', Relationship.suggested_type.to_yaml) }
  scope :default, -> { where('relationship_type = ?', Relationship.default_type.to_yaml) }

  def team
    self.source&.team
  end

  def source_project_media
    self.source
  end

  def target_project_media
    self.target
  end

  def version_metadata(_object_changes = nil)
    by_check = BotUser.alegre_user&.id == User.current&.id
    source = self.source
    source.nil? ? nil : {
      source: {
        title: ActiveRecord::Base.connection.quote_string(source.title),
        type: source.report_type,
        url: ActiveRecord::Base.connection.quote_string(source.full_url),
        by_check: by_check,
      }
    }.to_json
  end

  def self.confirmed_parent(pm)
    parent = Relationship.confirmed.where(target_id: pm&.id).last&.source
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

  def archive_detach_to_list
    unless self.add_to_project_id.blank? && self.archive_target.blank?
      pm = self.target
      pm.project_id = self.add_to_project_id unless self.add_to_project_id.blank?
      pm.archived = self.archive_target if [CheckArchivedFlags::FlagCodes::TRASHED, CheckArchivedFlags::FlagCodes::SPAM].include?(self.archive_target)
      begin pm.save! rescue nil end
    end
  end

  def is_being_confirmed?
    method = self.saved_change_to_relationship_type? ? :relationship_type_before_last_save : :relationship_type_was
    self.send(method).to_json == Relationship.suggested_type.to_json && self.relationship_type.to_json == Relationship.confirmed_type.to_json
  end

  def update_counters
    return if self.is_default? || self.source.nil? || self.target.nil?
    source = self.source
    target = self.target

    target.skip_check_ability = true
    target.sources_count = Relationship.where(target_id: target.id).where('relationship_type = ?', Relationship.confirmed_type.to_yaml).count
    target.save!

    source.skip_check_ability = true
    source.targets_count = Relationship.where(source_id: source.id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).count
    source.save!
  end

  def create_or_update_parent_id
    self.source_id
  end

  protected

  def update_elasticsearch_parent(action = 'create_or_update')
    return if self.is_default? || self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    # touch target to update `updated_at` date
    target =  self.target
    unless target.nil?
      updated_at = Time.now
      target.update_columns(updated_at: updated_at)
      data = { updated_at: updated_at.utc }
      data['parent_id'] = {
        method: "#{action}_parent_id",
        klass: self.class.name,
        id: self.id,
        default: target_id,
        type: 'int'
      } if self.is_confirmed?
      target.update_elasticsearch_doc(data.keys, data, target.id, true)
    end
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
    if (self.source_id_before_last_save && self.source_id_before_last_save != self.source_id) || (self.target_id_before_last_save && self.target_id_before_last_save != self.target_id)
      previous = Relationship.new(source_id: self.source_id_before_last_save, target_id: self.target_id_before_last_save)
      previous.update_counters
      current = Relationship.new(source_id: self.source_id, target_id: self.target_id)
      current.update_counters
    end
  end

  def propagate_inversion
    if self.source_id_before_last_save == self.target_id && self.target_id_before_last_save == self.source_id
      ids = Relationship.where(source_id: self.target_id).map(&:id).join(',')
      report = Dynamic.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: self.source_id_before_last_save).last
      unless report.nil?
        report.annotated_id = self.source_id
        report.save!
      end
      claim = ClaimDescription.where(project_media_id: self.source_id_before_last_save).last
      unless claim.nil?
        claim.project_media_id = self.source_id
        claim.save
      end
      Relationship.where(source_id: self.target_id).update_all({ source_id: self.source_id })
      self.source&.clear_cached_fields
      self.target&.clear_cached_fields
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

  def target_not_pulished_report
    unless self.target.nil?
      state = self.target.get_annotations('report_design').last&.load&.get_field_value('state')
      errors.add(:base, I18n.t(:target_is_published)) if state == 'published'
    end
  end

  def similar_item_exists
    r = Relationship.where(source_id: self.source_id, target_id: self.target_id)
    .where('relationship_type = ?', Relationship.confirmed_type.to_yaml).last
    errors.add(:base, I18n.t(:similar_item_exists)) unless r.nil?
  end

  def point_targets_to_new_source
    # Get existing targets for the source
    target_ids = Relationship.where(source_id: self.source_id, relationship_type: self.relationship_type).map(&:target_id)
    # Delete duplicate relation from target(CHECK-1603)
    Relationship.where(source_id: self.target_id, relationship_type: self.relationship_type, target_id: target_ids).delete_all
    Relationship.where(source_id: self.target_id).where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).each do |old_relationship|
      old_relationship.delete
      new_relationship = Relationship.new(
        source_id: self.source_id,
        target_id: old_relationship.target_id,
        relationship_type: old_relationship.relationship_type,
        user_id: old_relationship.user_id,
        weight: old_relationship.weight
      )
      new_relationship.skip_check_ability = true
      new_relationship.save!
    end
  end

  def set_confirmed
    if User.current
      self.confirmed_at = Time.now
      self.confirmed_by = User.current.id
    end
  end

  def set_cluster
    if self.relationship_type.to_json == Relationship.confirmed_type.to_json && User.current && User.current&.id != BotUser.alegre_user&.id
      pm = self.target
      new_cluster = self.source.cluster
      old_cluster = pm.cluster
      if old_cluster.nil? || (old_cluster.size == 1 && old_cluster.project_media_id == pm.id)
        unless old_cluster.nil?
          old_cluster.skip_check_ability = true
          old_cluster.destroy!
        end
        new_cluster.project_medias << pm unless new_cluster.nil?
      end
    end
  end

  def update_counter_and_elasticsearch
    self.update_counters
    self.update_elasticsearch_parent
  end

  def destroy_elasticsearch_relation
    update_elasticsearch_parent('destroy')
  end

  def move_to_same_project_as_main
    main = self.source
    secondary = self.target
    if (self.is_confirmed? || self.is_suggested?) && secondary && main && secondary.project_id != main.project_id
      secondary.project_id = main.project_id
      secondary.save!
      CheckNotification::InfoMessages.send('moved_to_private_folder', item_title: secondary.title) unless secondary.reload.user_can_see_project?(secondary.user)
    end
  end

  def destroy_suggest_item
    # Check if same item already exists as a suggested item
    Relationship.where(source_id: self.source_id, target_id: self.target_id)
    .where('relationship_type = ?', Relationship.suggested_type.to_yaml).destroy_all
  end

  def cant_be_related_to_itself
    errors.add(:base, I18n.t(:item_cant_be_related_to_itself)) if self.source_id == self.target_id
  end
end
