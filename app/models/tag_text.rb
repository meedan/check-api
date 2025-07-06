class TagText < ApplicationRecord
  include CheckPusher
  attr_accessor :marked_for_deletion

  before_validation :normalize_tag
  before_validation :merge_tags, on: :update

  validates :text, uniqueness: { scope: :team_id }, unless: proc { |tag_text| tag_text.marked_for_deletion }
  validates_presence_of :text
  validates_presence_of :team_id

  after_destroy :destroy_tags_in_background, :delete_associated_rule
  after_update :update_tags_in_background, :delete_if_marked_for_deletion

  belongs_to :team, optional: true

  def tags
    TagText.tags(self.id, self.team_id)
  end

  def annotation_relation
    tags
  end

  def calculate_tags_count
    self.tags.count
  end

  # Performance here could be much better, and we are also considering only ProjectMedia tags
  def self.tags(id, team_id)
    Tag.where("data = ?", { tag: id }.with_indifferent_access.to_yaml)
       .joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'")
       .where('pm.team_id' => team_id)
  end

  def self.destroy_tags(id, team_id)
    TagText.tags(id, team_id).find_each{ |tag| tag.destroy! }
  end

  def self.update_tags(id, team_id, new_id = nil)
    tag_id = new_id
    tag_id = nil if !tag_id.nil? && TagText.where(id: tag_id).last.nil?
    TagText.tags(id, team_id).find_each do |tag|
      tag.updated_at = Time.now
      tag.tag = tag_id unless tag_id.nil?
      tag.save!
    end
  end

  private

  def normalize_tag
    self.text = self.text.strip.gsub(/^#/, '') unless self.text.nil?
  end

  def destroy_tags_in_background
    TagText.delay_for(1.second).destroy_tags(self.id, self.team_id)
  end

  def delete_associated_rule
    team = self.team
    rules = team.get_rules
    unless rules.blank?
      old_count = rules.count
      # This name created by check-web
      rule_name = "Rule for tag \"#{self.text}\""
      rules.delete_if{|r| r['name'] == rule_name}
      if rules.count != old_count
        team.set_rules = rules
        team.skip_check_ability
        team.save!
      end
    end
  end

  def update_tags_in_background
    TagText.delay_for(1.second).update_tags(self.id, self.team_id)
  end

  def merge_tags
    existing = TagText.where(text: self.text, team_id: self.team_id).last
    if !existing.nil? && existing.id != self.id
      TagText.delay_for(1.second).update_tags(self.id, self.team_id, existing.id)
      self.text = self.text_was
      self.marked_for_deletion = true
    end
  end

  def delete_if_marked_for_deletion
    self.delete if self.marked_for_deletion
  end
end
