module CheckdeskPermissions
  private

  def check_ability
    unless self.current_user.nil?
      ability = Ability.new(self.current_user,  self.context_team)
      op = self.new_record? ? :create : :update
      raise "No permission to #{op} #{self.class}" unless ability.can?(op, self)
    end
  end

  def check_destroy_ability
    unless self.current_user.nil?
      ability = Ability.new(self.current_user, self.context_team)
      raise "No permission to delete #{self.class}" unless ability.can?(:destroy, self)
    end
  end

  # def check_read_ability
  #   unless self.current_user.nil?
  #     ability = Ability.new(self.current_user)
  #     raise "No permission to read #{self.class}" unless ability.can?(:read, self)
  #   end
  # end
end
