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

    def compress_folder(folder_path, zip_path)
      require 'zip'
      FileUtils.rm_f(zip_path)
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        Dir.glob("#{folder_path}/**/**").each do |file|
          relative_path = file.sub("#{folder_path}/", '')
          next if relative_path.empty?
          if File.directory?(file)
            zipfile.mkdir(relative_path) unless zipfile.find_entry(relative_path)
          else
            zipfile.add(relative_path, file)
          end
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
        to_mails = team.team_users.map(&:user).map(&:email).compact & emails unless emails.empty?
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
        requests_count = TiplineRequest.where(team_id: team.id).count
        fact_checks_count = team.fact_checks.count
        explainers_count = team.explainers.count
        tbi = team.team_bot_installations.where(user_id: smooch.id).first
        tipline_wa = 'No'
        tipline_non_wa = 'No'
        has_tipline = 'No'
        all_tiplines = ''
        unless tbi.nil?
          tiplines = tbi.smooch_enabled_integrations.keys
          all_tiplines = tiplines.join('-')
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
          team.id,
          team.name,
          team.url,
          team.created_at,
          last_active,
          users_count,
          items_count,
          requests_count,
          fact_checks_count,
          explainers_count,
          has_tipline,
          tipline_wa,
          tipline_non_wa,
          all_tiplines,
          has_active_api,
          last_active_non_meedan
        ]
        # Write to CSV
        file = "#{Rails.root}/public/#{team.slug}/workspace_data.csv"
        headers = [
          "ID",
          "Name",
          "URL",
          "Created at",
          "Last activity",
          "Users #",
          "Items #",
          "Requests #",
          "FactChecks #",
          "Explainers #",
          "Enabled tipline?",
          "Active WhatsApp integration?",
          "Active non-WhatsApp integration?",
          "Active tiplines",
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
    task :export_workspace_articles_data,[:slug] => [:environment, :export_workspace_user_data] do |_t, args|
      print_task_title 'Exporting workspace articles data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = team.get_articles_exported_data({}).drop(1) # Remove the header, we don't it
        headers = data_csv.shift
        file = "#{Rails.root}/public/#{team.slug}/workspace_articles_data.csv"
        write_to_csv(file, headers, data_csv)
      end
    end
    task :export_workspace_tasks_data,[:slug] => [:environment, :export_workspace_articles_data] do |_t, args|
      print_task_title 'Exporting workspace tasks data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
      end
    end
    task :export_workspace_tipline_requets_data,[:slug] => [:environment, :export_workspace_tasks_data] do |_t, args|
      print_task_title 'Exporting workspace TiplineRequests data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        TiplineRequest.where(team_id: team.id).find_each do |tr|
          data_csv << [
            tr.id,
            tr.language,
            tr.created_at,
            tr.tipline_user_uid,
            tr.smooch_data.to_json
          ]
        end
        file = "#{Rails.root}/public/#{team.slug}/workspace_tipline_requets_data.csv"
        headers = [
         "ID",
         "Language",
         "Platform",
         "Creation date",
         "User UID",
         "Data"
        ]
        write_to_csv(file, headers, data_csv)
      end
    end
    task :export_workspace_item_data,[:slug] => [:environment, :export_workspace_tipline_requets_data] do |_t, args|
      print_task_title 'Exporting workspace item data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        team.project_medias.includes(:source, :media).find_each do |pm|
          media = pm.media
          media_data = media.quote || media.url || media.file&.url
          data_csv << [
            pm.id,
            pm.title,
            pm.description,
            pm.created_at,
            pm.tags_as_sentence,
            pm.status,
            pm.source&.name,
            media.type,
            media_data
          ]
        end
        file = "#{Rails.root}/public/#{team.slug}/workspace_item_data.csv"
        headers = [
          "ID",
          "Title",
          "Description",
          "Creation date",
          "Tags",
          "Status",
          "Source",
          "Media type",
          "Media data",
        ]
        write_to_csv(file, headers, data_csv)
      end
    end

    # Upload workspace data to S3
    task :export_and_upload_workspace_data,[:slug] => [:environment, :export_workspace_item_data] do |_t, args|
      print_task_title 'Uploading workspace data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        # compress & upload
        folder_path = "#{Rails.root}/public/#{team.slug}"
        zip_path = "#{Rails.root}/public/#{team.slug}-#{Time.now.to_i}.zip"
        puts "Compressing #{folder_path} -> #{zip_path}"
        compress_folder(folder_path, zip_path)
        # Save to S3
        download_url = CheckS3.write_presigned("export/workspaces_data/#{team.slug}/#{Time.now.to_i}/#{team.slug}.zip", 'application/zip', zip_path, CheckConfig.get('export_csv_expire', 7.days.to_i, :integer))
        puts "Download link (valid 7 days): #{download_url}"
        # Send download link to workspace admins
        team.team_users.where(status: 'member').find_each do |tu|
          puts "Sending email to #{tu.user.email}\n"
          SunsetMailer.delay.notify(tu.user, tu.team.name)
        end
      end
    end
  end
end
