class Claim < Media
  validates :quote, presence: true, on: :create
end
