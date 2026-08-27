namespace :check do
  namespace :sunset do
    # bundle exec rails check:sunset:notify_workspace_admins[team-slug, high:low]
    task :notify_workspace_admins, [:slug, :priority] => :environment do |_t, args|
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        priority = args[:priority].to_s
        raise "You should set mail priority" unless ['high', 'low'].include?(priority)
        mail_type = "notify_#{priority}_usage"
        # Define 3PFC and clients workspaces
        excluded_workspaces = []
        unless excluded_workspaces.include?(team.slug)
          to_mails = team.team_users.where(status: 'member', role: 'admin').map(&:user).map(&:email).compact
          # Send email
          User.where(email: to_mails).find_each do |user|
            puts "Sending email to #{user.email}\n"
            SunsetMailer.delay.notify(mail_type, user, team.name, team.url)
          end
        end
      end
    end
  end
end
