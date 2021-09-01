# Clear cached permissions based on role and team privacy
TEAM_ROLES = %w[authenticated collaborator editor admin]
TEAM_ROLES.each do |role|
  # loop roles for private/ non private teams
  [1, 0].each{ |pr| Rails.cache.delete("team_permissions_#{pr.to_i}_#{role}_role")}
end
