module Montage::User
  include Montage::Base

  def date_joined
    self.created_at.to_s
  end

  def accepted_nda
    !self.last_accepted_terms_at.blank?
  end

  def first_name
    self.name.split(/\s/).first
  end

  def last_name
    self.name.split(/\s/).last
  end

  def is_superuser
    self.is_admin
  end

  def last_login
    self.last_sign_in_at.to_s
  end

  def profile_img_url
    self.profile_image
  end

  def username
    self.login
  end

  def tags_added
    total = 0
    self.teams.each do |team|
      total += Version.from_partition(team.id).where(whodunnit: self.id.to_s, event_type: 'create_tag').count
    end
    total
  end
end
