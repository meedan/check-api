class Relationship < ActiveRecord::Base
  FLAGS = ['commutative', 'transitive']
  KINDS = ['contains', 'part_of']

  belongs_to :source, class_name: 'ProjectMedia'
  belongs_to :target, class_name: 'ProjectMedia'

  serialize :flags

  validates :kind, inclusion: { in: KINDS }
  validate :flags_are_valid

  def has_flag?(flag)
    self.flags.map(&:to_s).include?(flag.to_s)
  end

  private

  def flags_are_valid
    unless self.flags.is_a?(Array) && (self.flags - FLAGS).empty?
      errors.add(:flags)
    end
  end
end
