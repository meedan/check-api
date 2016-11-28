class TagSearch
  include CheckElasticSearchModel

  attribute :tag, String, presence: true
  attribute :full_tag, String, presence: true, mapping: { index: 'not_analyzed' }

  validates_presence_of :tag

  before_validation :normalize_tag, :store_full_tag

  private

  def normalize_tag
    self.tag = self.tag.gsub(/^#/, '') unless self.tag.nil?
  end

  def store_full_tag
    self.full_tag = self.tag
  end

end
