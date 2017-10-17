class ClaimSource < ActiveRecord::Base

  belongs_to :media
  belongs_to :source

  validates_presence_of :media_id, :source_id
end
