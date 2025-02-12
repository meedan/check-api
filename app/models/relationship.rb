class Relationship < ApplicationRecord
  include CheckElasticSearch
  include RelationshipBulk

  attr_accessor :is_being_copied, :archive_target

  belongs_to :source, class_name: 'ProjectMedia', optional: true
  belongs_to :target, class_name: 'ProjectMedia', optional: true
  belongs_to :user, optional: true

  serialize :relationship_type

  before_validation :set_user, on: :create
  before_validation :set_confirmed, if: :is_being_confirmed?, on: :update
  before_validation :move_fact_check_and_report_to_main, on: :create
  validate :relationship_type_is_valid, :items_are_from_the_same_team
  validate :target_not_published_report, on: :create
  validate :similar_item_exists, on: :create, if: proc { |r| r.is_suggested? }
  validate :cant_be_related_to_itself
  validates :relationship_type, uniqueness: { scope: [:source_id, :target_id], message: :already_exists }, on: :create

  before_create :point_targets_to_new_source
  before_create :destroy_same_suggested_item, if: proc { |r| r.is_confirmed? }
  after_create :move_to_same_project_as_main, prepend: true
  after_create :update_counters, prepend: true
  after_update :reset_counters, prepend: true
  after_update :propagate_inversion
  after_save :turn_off_unmatched_field, if: proc { |r| r.is_confirmed? || r.is_suggested? }
  after_save :move_explainers_to_source, :apply_status_to_children, if: proc { |r| r.is_confirmed? }
  before_destroy :archive_detach_to_list
  after_destroy :update_counters, prepend: true
  after_destroy :turn_on_unmatched_field, if: proc { |r| r.is_confirmed? || r.is_suggested? }
  after_commit :update_counter_and_elasticsearch, on: [:create, :update]
  after_commit :destroy_elasticsearch_relation, on: :destroy

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
    source.nil? ? nil : ActiveRecord::Base.connection.quote_string({
      source: {
        title: source.title,
        type: source.report_type,
        url: source.full_url,
        by_check: by_check,
      }
    }.to_json)
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
    unless self.archive_target.blank?
      pm = self.target
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

  def self.create_unless_exists(source_id, target_id, relationship_type, options = {})
    # Verify that the target is not part of another source; in this case, we should return the existing relationship.
    r = Relationship.where(target_id: target_id).where.not(source_id: source_id).last
    return r unless r.nil?
    # otherwise we should get the existing relationship based on source, target and type
    r = Relationship.where(source_id: source_id, target_id: target_id).where('relationship_type = ?', relationship_type.to_yaml).last
    exception_message = nil
    exception_class = nil
    if r.nil?
      # Add to existing media cluster if source is already a target:
      # If we're trying to create a relationship between C (target_id) and B (source_id), but there is already a relationship between A (source_id) and B (target_id),
      # then, instead, create the relationship between A (source_id) and C (target_id) (so, if A's cluster contains B, then C comes in and our algorithm says C is similar
      # to B, it is added to A's cluster). Exception: If the relationship between A (source_id) and B (target_id) is a suggestion, we should not create any relationship
      # at all when trying to create a relationship between C (target_id) and B (source_id) (regardless if it’s a suggestion or a confirmed match) - but we should log that case.
      existing = Relationship.where(target_id: source_id).first
      unless existing.nil?
        if existing.relationship_type == Relationship.suggested_type
          error_msg = StandardError.new('Not creating relationship because requested source_id is already suggested to another item.')
          CheckSentry.notify(error_msg, source_id: source_id, target_id: target_id, relationship_type: relationship_type, options: options)
          return nil
        end
        source_id = existing.source_id
      end

      begin
        r = Relationship.new
        r.skip_check_ability = true
        r.relationship_type = relationship_type
        r.source_id = source_id
        r.target_id = target_id
        options.each do |key, value|
          r.send("#{key}=", value) if r.respond_to?("#{key}=")
        end
        r.save!
      rescue StandardError => e
        CheckSentry.notify(e, source_id: source_id, target_id: target_id, relationship_type: relationship_type)
        r = Relationship.where(source_id: source_id, target_id: target_id).where('relationship_type = ?', relationship_type.to_yaml).last
        exception_message = e.message
        exception_class = e.class.name
      end
    end
    if r.nil?
      Rails.logger.error("[Relationship::create_unless_exists] returning nil: source_id #{source_id}, target_id #{target_id}, relationship_type #{relationship_type}.")
      error_msg = StandardError.new("Unable to create new relationship as requested: #{exception_message}")
      CheckSentry.notify(error_msg, source_id: source_id, target_id: target_id, relationship_type: relationship_type, options: options, exception_message: exception_message, exception_class: exception_class)
    end
    r
  end

  def self.replicate_status_to_children(pm_id, uid, tid)
    pm = ProjectMedia.find_by_id(pm_id)
    return if pm.nil?
    User.current = User.where(id: uid).last
    Team.current = Team.where(id: tid).last
    status = pm.last_verification_status
    pm.source_relationships.confirmed.find_each do |relationship|
      target = relationship.target
      s = target.annotations.where(annotation_type: 'verification_status').last&.load
      next if s.nil? || s.status == status
      s.status = status
      s.bypass_status_publish_check = true
      s.save!
    end
    User.current = nil
    Team.current = nil
  end

  protected

  def update_elasticsearch_parent(action = 'create_or_update')
    return if self.is_default? || self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    [self.source, self.target].compact.each do |pm|
      updated_at = Time.now
      # touch item to update `updated_at` date
      pm.update_columns(updated_at: updated_at)
      data = { updated_at: updated_at.utc }
      data['parent_id'] = {
        method: "#{action}_parent_id",
        klass: self.class.name,
        id: self.id,
        default: pm.id,
        type: 'int'
      }
      pm.update_elasticsearch_doc(data.keys, data, pm.id, true)
    end if self.is_confirmed?
  end

  def set_unmatched_field(value)
    items = [self.target]
    count = 0
    # unmatch source when there is no other targets assigned to same source
    count = Relationship.where(source_id: self.source_id).where.not(target_id: self.target_id).count if value
    items << self.source if count == 0
    items.compact.each do |item|
      if item.unmatched != value
        item.unmatched = value
        item.skip_check_ability = true
        item.save!
      end
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
      Relationship.where(source_id: self.target_id).find_each do |r|
        r.source_id = self.source_id
        r.skip_check_ability = true
        r.save!
      end
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

  def target_not_published_report
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
    target_ids = Relationship.where(source_id: self.source_id).map(&:target_id)
    # Delete duplicate relationships from target (CHECK-1603)
    Relationship.where(source_id: self.target_id, target_id: target_ids).delete_all
    Relationship.where(source_id: self.target_id).find_each do |old_relationship|
      old_relationship.delete
      options = {
        user_id: User.current&.id || old_relationship.user_id,
        weight: old_relationship.weight
      }
      Relationship.create_unless_exists(self.source_id, old_relationship.target_id, old_relationship.relationship_type, options)
      old_relationship.source.clear_cached_fields
      old_relationship.target.clear_cached_fields
    end
  end

  def set_confirmed
    if User.current
      self.confirmed_at = Time.now
      self.confirmed_by = User.current.id
    end
  end

  def turn_off_unmatched_field
    set_unmatched_field(0)
  end

  def turn_on_unmatched_field
    set_unmatched_field(1)
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
      CheckNotification::InfoMessages.send('moved_to_private_folder', item_title: secondary.title)
    end
  end

  def move_explainers_to_source
    # Three cases to move explainers
    # 1) Relationship is new and confirmed
    # 2) Item is being confirmed (move from suggested to confirmed)
    # 3) Pin item (sawp source_id & target_id)
    if self.relationship_type_before_last_save.nil? || self.is_being_confirmed? || (self.source_id_before_last_save && self.source_id_before_last_save == self.target_id)
      ExplainerItem.transaction do
        # Destroy common Explainer from target item (use destroy to log this event)
        explainer_ids = ExplainerItem.where(project_media_id: [self.source_id, self.target_id])
        .group('explainer_id').having("count(explainer_id) = ?", 2).pluck(:explainer_id)
        ExplainerItem.where(explainer_id: explainer_ids, project_media_id: self.target_id).destroy_all
        # Move the Explainer from target to source by using update_all(as no callbacks) and then update logs
        ExplainerItem.where(project_media_id: self.target_id).update_all(project_media_id: self.source_id)
        # Update logs (to make item history consistent with Explainers attached to item)
        Version.from_partition(self.source.team_id)
        .where(event_type: 'create_explaineritem', associated_type: 'ProjectMedia', associated_id: self.target_id)
        .update_all(associated_id: self.source_id)
      end
    end
  end

  def apply_status_to_children
    Relationship.delay_for(1.second, { queue: 'smooch_priority' }).replicate_status_to_children(self.source_id, User.current&.id, Team.current&.id)
  end

  def destroy_same_suggested_item
    Relationship.transaction do
      # Check if same item already exists as a suggested item by a bot
      suggestions = Relationship.where(source_id: self.source_id, target_id: self.target_id).joins(:user).where('users.type' => 'BotUser').where('relationship_type = ?', Relationship.suggested_type.to_yaml)
      Rails.logger.info "[Relationship] Deleting #{suggestions.count} suggestions between items #{self.source_id} and #{self.target_id}..."
      suggestions.destroy_all
    end
  end

  def cant_be_related_to_itself
    errors.add(:base, I18n.t(:item_cant_be_related_to_itself)) if self.source_id == self.target_id
  end

  def move_fact_check_and_report_to_main
    Relationship.transaction do
      source = self.source
      target = self.target
      if source && target && source.team_id == target.team_id # Must verify since this method runs before the validation
        target_report = target.get_annotations('report_design').to_a.map(&:load).last

        # If the child item has a claim/fact-check and published report but the parent item doesn't, then move the claim/fact-check/report from the child to the parent
        if !source.claim_description && target.claim_description && target_report && target_report.get_field_value('state') == 'published'
          # Move report
          target_report.annotated_id = source.id
          target_report.save!

          # Move claim/fact-check
          claim_description = target.claim_description
          claim_description.project_media = source
          claim_description.save!

          # Clear caches
          source.clear_cached_fields
          target.clear_cached_fields
          source.reload
          target.reload
        end
      end
    end
  end
end
