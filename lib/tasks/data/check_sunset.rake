namespace :check do
  namespace :sunset do
    task :delete_teams_cache_and_es_values, [:workspace, :role, :emails] => :environment do |_t, args|
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        # TODO define these workspaces to exclude form notifications
        workspace_3PFC = []
        workspace_clients = []
        # TODO: Verifiy slug not belong to workspace_3PFC OR workspace_clients
        emails = args[:emails].to_s.split('|').map(&:strip)
        to = []
        # Confirm emails belongs to target workspace
        to = team.team_users.map(&:user).map(&:email).compact & emails unless emails.empty?
        # Concat emails for specific role
        role = args[:role].to_s
        unless role.blank?
          role_emails = team.team_users.where(status: 'member', role: role).map(&:user).map(&:email).compact
          to.concat(role_emails).uniq!
        end
        # Send email
        to.each{ |email| SunsetMailer.delay.notify(email)} 
      end
    end
  end
end
