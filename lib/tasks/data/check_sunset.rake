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

    def append_export_documentation(readme_path, filename, description, headers)
      File.open(readme_path, "a") do |file|
        file.puts
        file.puts filename
        file.puts "-" * filename.length
        file.puts "Description: #{description}"
        file.puts
        file.puts "Headers:"
        headers.each do |key, description|
          file.puts "- #{key}: #{description}"
        end
        file.puts
      end
    end

    # bundle exec rails check:sunset:notify_workspace_admins[team-slug, high:low]
    task :notify_workspace_admins, [:slug, :priority] => :environment do |_t, args|
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        priority = args[:priority].to_s
        raise "You should set mail priority" unless ['high', 'low'].include?(priority)
        # Set mail copy based on priority i.e, high: means workspace with high usage
        mail_type = "notify_#{priority}_usage"
        to_mails = team.team_users.where(status: 'member', role: 'admin').map(&:user).map(&:email).compact
        # Send email
        User.where(email: to_mails).find_each do |user|
          puts "Sending email to #{user.email}\n"
          SunsetMailer.delay.notify(mail_type, user, team.name, team.url)
        end
      end
    end

    # Export workspace data
    task :export_workspace_init_readme, [:slug] => :environment do |_t, args|
      print_task_title 'CSV Export Documentation'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        FileUtils.mkdir_p(export_dir)
        File.write(
          export_dir.join("README.txt"),
          <<~README
            CSV Export Documentation
            ========================
            This export contains information and data from the workspace in CSV format. Each CSV file contains a specific type of workspace data, such as workspace information, users, items, annotations, FactChecks, Explainers, and Tipline requests.

            Media Files
            ===========
            Media files are not included directly in the CSV export. For items that contain media, the corresponding Media data or media URL in workspace_item_data.csv should be used to download the actual media files.

          README
        )
      end
    end
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
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        file = export_dir.join('workspace_data.csv')
        headers = {
          'ID' => 'Unique identifier of the workspace.',
          'Name' => 'Name of the workspace.',
          'URL' => 'URL used to access the workspace.',
          'Created at' => 'Date when the workspace was created.',
          'Last activity' => 'Date of the most recent activity in the workspace.',
          'Users #' => 'Total number of users in the workspace.',
          'Items #' => 'Total number of items in the workspace, including Claims, Links, Images, Videos, and Audio.',
          'Requests #' => 'Total number of requests submitted through the workspace\'s tiplines.',
          'FactChecks #' => 'Total number of FactChecks in the workspace.',
          'Explainers #' => 'Total number of Explainers in the workspace.',
          'Enabled tipline?' => 'Indicates whether the workspace has a tipline enabled (Yes/No).',
          'Active WhatsApp integration?' => 'Indicates whether the workspace has an active WhatsApp integration (Yes/No).',
          'Active non-WhatsApp integration?' => 'Indicates whether the workspace has any active tipline integration other than WhatsApp (Yes/No).',
          'Active tiplines' => 'List of all active tiplines associated with the workspace, separated by -.',
          'Active API?' => 'Indicates whether the workspace has an active API (Yes/No).',
          'Last access' => 'Date of the most recent access to the workspace.',
        }
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_data.csv', 'Contains workspace information and activity statistics.', headers)
      end
    end
    # bundle exec rails check:sunset:export_workspace_user_data[team-slug]
    task :export_workspace_user_data,[:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace user data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        team.team_users.where(status: 'member').find_each do |tu|
          print '.'
          user = tu.user
          data_csv << [
            user.id,
            user.name,
            user.email,
            tu.created_at,
            tu.last_active_at,
            tu.role
          ]
        end
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        file = export_dir.join('workspace_user_data.csv')
        headers = {
          'ID' => 'Unique identifier of the user.',
          'Name' => 'Name of the user.',
          'Email' => 'Email address of the user.',
          'Joined date' => 'Date when the user joined the workspace.',
          'Last access date' => 'Date when the user most recently accessed the workspace.',
          'Role' => 'User\'s role in the workspace.',
        }
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_user_data.csv', 'Contains information about workspace users and their access.', headers)
      end
    end
    # bundle exec rails check:sunset:export_workspace_articles_data[team-slug]
    task :export_workspace_articles_data,[:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace articles data (FactChecks & Explainers)'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        # Export FactChecks
        data_csv = FactCheck.get_exported_data({}, team).drop(1)
        file = export_dir.join('workspace_fact_checks_data.csv')
        headers = {
          'ID' => 'Unique identifier of the FactCheck.',
          'Title' => 'Title of the FactCheck',
          'Summary' => 'Summary of the FactCheck',
          'URL' => 'URL of the FactCheck',
          'Language' => 'Language of the FactCheck in two-letter format, such as en/ar/fr.',
          'Report Status' => 'Current status of the FactCheck report.',
          'Imported?' => 'Indicates whether the FactCheck was imported into the workspace'
        }
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_fact_checks_data.csv', 'Contains information about FactChecks in the workspace.', headers)
        # Export Explainers
        data_csv = Explainer.get_exported_data({}, team).drop(1)
        headers = {
          'ID' => 'Unique identifier of the Explainer.',
          'Title' => 'Title of the Explainer',
          'Description' => 'Description of the Explainer',
          'URL' => 'URL of the Explainer',
          'Language' => 'Language of the Explainer in two-letter format, such as en/ar/fr.',
        }
        file = export_dir.join('workspace_explainers_data.csv')
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_explainers_data.csv', 'Contains information about Explainers in the workspace.', headers)
      end
    end
    # bundle exec rails check:sunset:export_workspace_annotations_data[team-slug]
    task :export_workspace_annotations_data,[:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace annotations data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        team_tasks = team.team_tasks
        unless team_tasks.empty?
          headers_id = team_tasks.map(&:id)
          data_csv = []
          team.project_medias.find_each do |pm|
            print '.'
            a_ttid = {}
            pm.get_annotations(['task']).find_each do |a|
              a_ttid[a.data["team_task_id"]] = a.id
            end
            a_answer = {}
            DynamicAnnotation::Field.select("a.annotated_id AS tid, dynamic_annotation_fields.value AS answer")
            .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN annotations a2 ON a2.id = a.annotated_id")
            .where("field_name LIKE 'response_%'")
            .where('a.annotated_type' => 'Task', 'a2.annotated_type' => 'ProjectMedia', 'a2.annotated_id' => pm.id).each do |f|
              a_answer[f.tid] = begin JSON.parse(f.answer) rescue f.answer end
            end
            next if a_answer.empty?
            pm_raw = [pm.id]
            headers_id.each do |ttid|
              pm_raw << (a_answer[a_ttid[ttid]] || '-')
            end
            data_csv << pm_raw
          end
          export_dir = Rails.root.join('tmp', 'sunset', team.slug)
          file = export_dir.join('workspace_annotations_data.csv')
          headers = { 'Item ID' => 'Unique identifier of the item associated with the annotation.' }
          team_tasks.each do |tt|
            headers["#{tt.label} (#{tt.id})"] = tt.description
          end
          write_to_csv(file, headers.keys, data_csv)
          append_export_documentation(export_dir.join('README.txt'), 'workspace_annotations_data.csv', 'Contains information about workspace annotations. Each column represents an annotation label, and each row contains the corresponding annotation value for an item.', headers)
        end
      end
    end
    # bundle exec rails check:sunset:export_workspace_tipline_requests_data[team-slug]
    task :export_workspace_tipline_requests_data,[:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace TiplineRequests data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        TiplineRequest.where(team_id: team.id).find_each do |tr|
          print '.'
          data_csv << [
            tr.id,
            tr.language,
            tr.platform,
            tr.created_at,
            tr.tipline_user_uid,
            tr.smooch_data['text']
          ]
        end
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        file = export_dir.join('workspace_tipline_requests_data.csv')
        headers = {
          'ID' => 'Unique identifier of the TiplineRequest.',
          'Language' => 'Language of the TiplineRequest in two-letter format, such as en/ar/fr.',
          'Platform' => 'Platform through which the TiplineRequest was submitted.',
          'Creation date' => 'Date and time when the TiplineRequest was created.',
          'User UID' => 'Unique identifier of the tipline user who submitted the request.',
          'Text' => 'Text submitted as part of the TiplineRequest.'
        }
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_tipline_requests_data.csv', 'Contains information about requests submitted through workspace tiplines.', headers)
      end
    end
    # bundle exec rails check:sunset:export_workspace_tipline_newsletter_data[team-slug]
    task :export_workspace_tipline_newsletter_data,[:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace TiplineNewsletter data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        team.tipline_newsletters.find_each do |tn|
          print '.'
          data_csv << [
            tn.id,
            tn.header_type,
            tn.header_file,
            tn.header_overlay_text,
            tn.header_media_url,
            tn.introduction,
            tn.content_type,
            tn.rss_feed_url,
            tn.number_of_articles,
            tn.first_article,
            tn.second_article,
            tn.third_article,
            tn.footer,
            tn.last_sent_at,
            tn.language,
            tn.enabled,
            tn.created_at,
          ]
        end
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        file = export_dir.join('workspace_tipline_newsletter_data.csv')
        headers = {
          'ID' => 'Unique identifier for the TiplineNewsletter.',
          'Header type' => 'Type of header used in the newsletter.',
          'Header file' => 'File used as the newsletter header.',
          'Header overlay text' => 'Text displayed as an overlay on the newsletter header.',
          'Header media url' => 'URL of the media used in the newsletter header.',
          'Introduction' => 'Introduction text displayed in the newsletter.',
          'Content type' => 'Type of content included in the newsletter.',
          'RSS feed url' => 'URL of the RSS feed used to populate the newsletter content.',
          'Number of articles' => 'Number of articles included in the newsletter.',
          'First article' => 'Content of the first article',
          'Second article' => 'Content of the second article',
          'Third article' => 'Content of the third article',
          'Footer' => 'Footer text displayed in the newsletter.',
          'Last sent at' => 'Date and time when the newsletter was last sent.',
          'Language' => 'Language of the TiplineNewsletter in two-letter format, such as en/ar/fr.',
          'Enabled' => 'Indicates whether the newsletter is enabled',
          'Creation date' => 'Date and time when the newsletter was created.',
        }
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_tipline_newsletter_data.csv', 'Contains information about Tipline newsletters configured for the workspace.', headers)
      end
    end
    # bundle exec rails check:sunset:export_workspace_item_data[team-slug]
    task :export_workspace_item_data,[:slug] => :environment do |_t, args|
      print_task_title 'Exporting workspace item data'
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        data_csv = []
        team.project_medias.includes(:source, :media).find_each do |pm|
          print '.'
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
        export_dir = Rails.root.join('tmp', 'sunset', team.slug)
        file = export_dir.join('workspace_item_data.csv')
        headers = {
          'ID' => 'Unique identifier of the item.',
          'Title' => 'Title of the item',
          'Description' => 'Description of the item',
          'Creation date' => 'Date and time when the item was created.',
          'Tags' => 'Tags associated with the item',
          'Status' => 'Current status of the item.',
          'Source' => 'Source associated with the item',
          'Media type' => 'Type of the item, such as Claim, Link, Image, Video, or Audio.',
          'Media data' => 'Content or reference associated with the item, such as a Quote, URL, or file path.',
        }
        write_to_csv(file, headers.keys, data_csv)
        append_export_documentation(export_dir.join('README.txt'), 'workspace_item_data.csv', 'Contains information about workspace items, including Claims, Links, and Media.', headers)
      end
    end

    # bundle exec rails check:sunset:export_upload_and_send_workspace_data[team-slug, email] EXPORT_OUTPUT_BUCKET=XXXXX
    task :export_upload_and_send_workspace_data,[:slug, :email] => :environment do |_t, args|
      started = Time.now.to_i
      slug = args[:slug].to_s
      team = Team.find_by_slug slug
      unless team.nil?
        email = args[:email].to_s
        puts "email:: #{email}"
        user = User.where(email: email).first
        if user && team.team_users.where(user_id: user.id, role: 'admin', status: 'member').exists?
          # Call all exported tasks
          Rake::Task['check:sunset:export_workspace_init_readme'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_data'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_user_data'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_articles_data'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_annotations_data'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_tipline_requests_data'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_tipline_newsletter_data'].invoke(args[:slug])
          Rake::Task['check:sunset:export_workspace_item_data'].invoke(args[:slug])
          print_task_title 'Uploading workspace data'
          # compress & upload
          folder_path = Rails.root.join('tmp', 'sunset', team.slug)
          zip_path = Rails.root.join('tmp', 'sunset', "#{team.slug}.zip")
          puts "Compressing #{folder_path} -> #{zip_path}"
          compress_folder(folder_path, zip_path)
          # Save to S3
          bucket_name = ENV.fetch('EXPORT_OUTPUT_BUCKET')
          begin
            zip_content = File.binread(zip_path)
            s3_url = CheckS3.write_presigned("#{team.slug}/#{SecureRandom.hex(16)}/#{team.slug}.zip", 'application/zip', zip_content, 7.days.to_i, bucket_name, 'private')
            key = Shortener::ShortenedUrl.generate!(s3_url).unique_key
            download_url = CheckConfig.get('short_url_host') + '/' + key
            puts "Download link (valid for 7 days): #{download_url}"
          rescue StandardError => e
            puts "Failed to upload exported data #{e.message}"
          ensure
            # Delete a directory for exported data and zip file
            FileUtils.rm_rf(folder_path)
            File.delete(zip_path) if File.exist?(zip_path)
          end
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
