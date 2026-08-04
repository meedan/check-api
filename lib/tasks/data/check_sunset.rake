namespace :check do
  namespace :sunset do
    def print_task_title(title)
      puts '----------------------------------------------------------------'
      puts title.upcase + '...'
      puts '----------------------------------------------------------------'
      puts
    end

    def write_to_csv(file, headers, data_csv)
      dir_path = File.dirname(file)
      FileUtils.mkdir_p(dir_path)
      CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
        data_csv.each do |d|
          writer << d
        end
      end
    end
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
    # Export workspace data
    # bundle exec rails check:sunset:export_workspace_data[team-slug]
    task :export_workspace_data, [:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        smooch = BotUser.smooch_user
        puts "Processing team #{team.slug}....."
        puts "\nExport workspace data ..."
        last_active = Version.from_partition(team.id).last&.created_at || team.created_at
        users_count = team.team_users.where(status: 'member').count
        items_count = team.project_medias.count
        tbi = team.team_bot_installations.where(user_id: smooch.id).first
        tipline_wa = 'No'
        tipline_non_wa = 'No'
        has_tipline = 'No'
        unless tbi.nil?
          tiplines = tbi.smooch_enabled_integrations.keys
          if tiplines.length > 0
            has_tipline = 'Yes'
            tipline_wa = 'Yes' if tiplines.include?('whatsapp')
            tiplines.delete('whatsapp')
            tipline_non_wa = 'Yes' if tiplines.length > 0
          end
        end
        # Check Active API
        has_active_api = 'No'
        api_keys = ApiKey.where(team_id: team.id).where('expire_at > ?', Time.now)
        unless api_keys.empty?
          webhook_installations = team.team_users.joins(:user).where('users.type' => 'BotUser', 'users.default' => false).select{ |team_user| team_user.user.events.present? && team_user.user.get_request_url.present? && !team_user.user.get_approved }
          u_ids = webhook_installations.map(&:user_id)
          bu_ids = api_keys.map(&:bot_user).compact.map(&:id)
          has_active_api = 'Yes' unless (bu_ids - u_ids).empty?
        end
        # Last active for non Meedan users
        last_active_non_meedan = team.team_users.joins(:user).where.not("users.email ILIKE ? OR users.email ILIKE ?", "%@meedan.com", "%@meedan.org").maximum(:last_active_at)
        data_csv << [
          team.name,
          team.url,
          team.created_at,
          last_active,
          users_count,
          items_count,
          tipline_wa,
          tipline_non_wa,
          has_tipline,
          has_active_api,
          last_active_non_meedan
        ]
        # Write to CSV
        file = "#{Rails.root}/public/#{team.slug}/workspace_data.csv"
        headers = [
         "Name",
         "URL",
         "Created at",
         "Last activity",
         "Number of users",
         "Number of items",
         "Active WhatsApp integration?",
         "Active non-WhatsApp integration?",
         "Enabled tipline?",
         "Active API?",
         "Last access(non-meedian)"
        ]
        write_to_csv(file, headers, data_csv)
      end
    end
    task :export_workspace_user_data,[:slug] => [:environment, :export_workspace_data] do |_t, args|
      print_task_title 'Exporting workspace user data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        team.team_users.where(status: 'member').find_each do |tu|
          user = tu.user
          data_csv << [
            user.name,
            user.email,
            tu.created_at,
            tu.last_active_at,
            tu.role
          ]
        end
        file = "#{Rails.root}/public/#{team.slug}/workspace_user_data.csv"
        headers = [
         "Name",
         "Email",
         "Joined data",
         "Last access date",
         "Role"
        ]
        write_to_csv(file, headers, data_csv)
      end
    end
    task :export_workspace_item_data,[:slug] => [:environment, :export_workspace_user_data] do |_t, args|
      print_task_title 'Exporting workspace item data'
    end
    # Upload workspace data to S3
    task :export_and_upload_workspace_data,[:slug] => [:environment, :export_workspace_item_data] do |_t, args|
      print_task_title 'Uploading workspace data'
    end
  end
end
