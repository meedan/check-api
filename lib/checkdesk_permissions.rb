module CheckdeskPermissions

  def find_if_can(id, current_user, current_team)
    unless self.current_user.nil?
      ability = Ability.new(current_user, current_team)
      if ability.can?(:read, self)
        self.find(id)
      else
        raise "Sorry, you can't read this #{self.class.name.downcase}"
      end
    else
      self.find(id)
    end
  end

  def permissions
    perms = Hash.new
    unless self.current_user.nil?
      @ability = Ability.new(self.current_user, self.context_team)
      perms["read #{self.class}"] = @ability.can?(:read, self)
      perms["update #{self.class}"] = @ability.can?(:update, self)
      perms["destroy #{self.class}"] = @ability.can?(:destroy, self)
      perms = perms.merge self.set_create_permissions(self.class.name)
    end
    perms.to_json
  end

  def set_create_permissions(obj)
    create = {
      'Team' => %w[Project Account TeamUser User Contact],
      'Account' => %w[media],
      'Media' => %w[ProjectMedia],
      'Project' => %w[ProjectSource Source Media ProjectMedia],
      'Source' => %w[Account ProjectSource Project],
      'User' => %w[Source TeamUser Team Project]
    }
    perms = Hash.new
    unless create[obj].nil?
      create[obj].each do |data|
        model = data.singularize.camelize.constantize.new
        model.current_user = self.current_user
        model.context_team = self.context_team
        data.send('team_id=', self.context_team.id) if model.respond_to?('team_id=')
        perms["create #{data}"] = @ability.can?(:create, model)
      end
    end
    perms
  end

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

end
