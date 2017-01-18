class Flag < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  field :flag, String, presence: true

  validates_presence_of :flag
  validates :annotated_type, included: { values: ['ProjectMedia', nil] }
  validates :flag, included: { values: ['Spam', 'Graphic content', 'Needing fact-checking', 'Needing deletion', 'Follow story', 'Mark as graphic'] }

  def content
    { flag: self.flag }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def flag_callback(value, _mapping_ids = nil)
    flags = Hash[
      'spam' => 'Spam',
      'graphic_journalist' => 'Graphic content',
      'factcheck_journalist' => 'Needing fact-checking',
      'graphic' => 'Graphic content',
      'factcheck' => 'Needing fact-checking',
      'delete' => 'Needing deletion',
      'follow_story' => 'Follow story'
    ]
    flags[value].nil? ? value : flags[value]
  end
end
