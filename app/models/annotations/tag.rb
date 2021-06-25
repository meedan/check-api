class Tag < ApplicationRecord
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

  def team=(team)
    @team = team
  end

  def self.bulk_create(inputs, team)
    # Make sure that all items are under the team
    input_ids = inputs.select{ |input| input['annotated_type'] == 'ProjectMedia' }.collect{ |input| input['annotated_id'].to_i }.uniq
    ids = ProjectMedia.select(:id).where(id: input_ids, team_id: team.id).map(&:id)

    # Create all TagText we need, if any, and create a mapping from tag text to Tagtext.id
    texts = inputs.select{ |input| ids.include?(input['annotated_id'].to_i) && input['tag'].is_a?(String) }.collect{ |input| input['tag'] }.uniq
    existing_texts = TagText.where(text: texts, team_id: team.id).select(:text).map(&:text)
    new_texts = []
    (texts - existing_texts).each { |text| new_texts << { team_id: team.id, text: text } }
    TagText.import(new_texts, { validate: false, recursive: false, timestamps: true })
    texts_to_ids = {}
    TagText.where(text: texts, team_id: team.id).each { |tag_text| texts_to_ids[tag_text.text] = tag_text.id }

    # Bulk-insert tags
    inserts = []
    inputs.each do |input|
      tag = texts_to_ids[input['tag']] || input['tag']
      inserts << input.to_h.with_indifferent_access.reject{ |k, _v| k.to_s == 'tag' }.merge({ annotation_type: 'tag', data: { tag: tag } }) if ids.include?(input['annotated_id'].to_i)
    end
    result = Annotation.import inserts, validate: false, recursive: false, timestamps: true

    # Run callbacks in background
    Tag.delay.run_bulk_create_callbacks(result.ids.map(&:to_i).to_json)

    { team: team }
  end

  def self.run_bulk_create_callbacks(ids_json)
    ids = JSON.parse(ids_json)
    callbacks = [:add_elasticsearch_tag, :apply_rules_and_actions, :update_tags_count]
    ids.each do |id|
      t = Tag.find_by_id(id)
      callbacks.each do |callback|
        t.send(callback)
      end
    end
  end

  private

  def get_tag_text_reference
    if self.tag.is_a?(String)
      team_id = self.team&.id
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
