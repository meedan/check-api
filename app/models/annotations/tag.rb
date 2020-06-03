class Tag < ActiveRecord::Base
  include AnnotationBase

  # "tag" is a reference to a TagText object
  field :tag, Integer, presence: true

  before_validation :get_tag_text_reference

  validates_presence_of :tag
  validates :data, uniqueness: { scope: [:annotated_type, :annotated_id, :fragment], message: :already_exists }, if: lambda { |t| t.id.blank? }
  validate :tag_text_exists

  after_commit :add_elasticsearch_tag, on: :create
  after_commit :update_elasticsearch_tag, on: :update
  after_commit :destroy_elasticsearch_tag, on: :destroy
  after_commit :apply_rules_and_actions, on: [:create]
  after_commit :update_tags_count

  def content
    { tag: self.tag_text, tag_text_id: self.tag }.to_json
  end

  def tag_text_object
    TagText.where(id: self.tag).last
  end

  def tag_text
    self.tag_text_object&.text&.to_s
  end

  def team
    Team.where(id: self.get_team.first).last
  end

  private

  def get_tag_text_reference
    if self.tag.is_a?(String)
      team_id = self.get_team.first
      tag_text = TagText.where(text: self.tag, team_id: team_id).last
      if tag_text.nil? && team_id.present?
        tag_text = TagText.new
        tag_text.text = self.tag
        tag_text.team_id = team_id
        tag_text.skip_check_ability = true
        tag_text.save!
      end
      self.tag = tag_text.nil? ? 0 : tag_text.id
    end
  end

  def tag_text_exists
    errors.add(:base, I18n.t(:tag_text_id_not_found)) if TagText.where(id: self.tag).last.nil?
  end

  def add_elasticsearch_tag
    add_update_nested_obj({ op: 'create', nested_key: 'tags', keys: ['tag'], data: { 'tag' => self.tag_text }})
  end

  def update_elasticsearch_tag
    add_update_nested_obj({ op: 'update', nested_key: 'tags', keys: ['tag'], data: { 'tag' => self.tag_text }})
  end

  def destroy_elasticsearch_tag
    destroy_es_items('tags')
  end

  def update_tags_count
    tag_text = self.tag_text_object
    tag_text.update_column(:tags_count, tag_text.calculate_tags_count) unless tag_text.nil?
  end

  def apply_rules_and_actions
    team = self.team
    if !team.nil? && self.annotated_type == 'ProjectMedia'
      # Evaluate only the rules that contain a condition that matches this tag
      rule_ids = team.get_rules_that_match_condition do |condition, value|
        condition == 'tagged_as' && self.tag_text == value
      end
      team.apply_rules_and_actions(self.annotated, rule_ids)
    end
  end
end
