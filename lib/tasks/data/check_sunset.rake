namespace :check do
  namespace :sunset do
    # bundle exec rails check:sunset:notify_workspace_admins[team-slug, team-role, 'email1|email2|...']
    task :notify_workspace_admins, [:slug, :role, :emails] => :environment do |_t, args|
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        # TODO define these workspaces to exclude form notifications
        workspace_3PFC = []
        workspace_clients = []
        # TODO: Verifiy slug not belong to workspace_3PFC OR workspace_clients
        emails = args[:emails].to_s.split('|').map(&:strip)
        to_mails = []
        # Confirm emails belongs to target workspace
        to = team.team_users.map(&:user).map(&:email).compact & emails unless emails.empty?
        # Concat emails for specific role
        role = args[:role].to_s
        unless role.blank?
          role_emails = team.team_users.where(status: 'member', role: role).map(&:user).map(&:email).compact
          to_mails.concat(role_emails).uniq!
        end
        # Send email
        User.where(email: to_mails).find_each do |user|
          puts "Sending email to #{user.email}\n"
          SunsetMailer.delay.notify(user, team.name)
        end
      end
    end
  end
end
