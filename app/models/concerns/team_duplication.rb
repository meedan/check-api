require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    def self.duplicate(t)
      team = t.dup
      team.generate_slug
      team.save
      team
    end
  end

  def generate_slug
    i = 1
    loop do
      slug = self.slug.concat("-copy-#{i}")
      break unless Team.find_by(slug: slug)
      i += 1
    end
  end

end
