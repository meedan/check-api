module Montage::ProjectUser
  include Montage::Base

  def is_admin
    self.role == 'owner'
  end

  def is_owner
    self.role == 'owner'
  end

  def is_assigned
    self.status == 'member'
  end

  def is_pending
    self.status == 'requested'
  end

  # FIXME: Need to track that information
  def last_updates_viewed
    self.user.extend(Montage::User).last_login
  end

  def as_current_user_info
    {
      created: self.created,
      id: self.id,
      is_admin: self.is_admin,
      is_owner: self.is_owner,
      is_assigned: self.is_assigned,
      is_pending: self.is_pending,
      last_updates_viewed: self.last_updates_viewed,
      modified: self.modified
    }
  end
end
