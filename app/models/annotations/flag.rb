class Flag < ActiveRecord::Base
  include AnnotationBase

  field :flag, String, presence: true

  validates_presence_of :flag

  def self.flag_types
    ['Spam', 'Graphic content', 'Needing fact-checking', 'Needing deletion', 'Follow story', 'Mark as graphic']
  end
  validates :flag, included: { values: self.flag_types }

  def content
    { flag: self.flag }.to_json
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
