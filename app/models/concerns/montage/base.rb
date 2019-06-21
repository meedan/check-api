module Montage
  module Base
    def created
      self.created_at.to_s
    end

    def modified
      self.updated_at.to_s
    end
  end
end
