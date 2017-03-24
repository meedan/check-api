class Claim < Media
  validates :quote, presence: true, on: :create

  def text
    self.quote
  end
end
