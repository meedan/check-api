# bundle exec rake check:data:fact_checks_published[output-file-prefix,from..to,workspace.slugs.separated.by.dots]

namespace :check do
  namespace :data do
    desc 'List fact-checks published in a certain interval'
    task fact_checks_published: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      def parse_period(value)
        if value == 'today'
          [Time.now.beginning_of_day, Time.now.end_of_day]
        elsif value == 'yesterday'
          [Time.now.yesterday.beginning_of_day, Time.now.yesterday.end_of_day]
        else
          from, to = value.split('..')
          [Time.parse(from).beginning_of_day, Time.parse(to).end_of_day]
        end
      end

      bucket_name = ENV.fetch('FACT_CHECKS_S3_BUCKET')
      region = 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts "Please provide the AWS credentials."
        exit 1
      end

      def object_uploaded?(s3_client, bucket_name, object_key, file_path)
        response = s3_client.put_object(
          bucket: bucket_name,
          key: object_key,
          body: File.read(file_path)
        )
        if response.etag
          return true
        else
          return false
        end
      rescue StandardError => e
        puts "Error uploading S3 object: #{e.message}"
        return false
      end

      # Rules per workspace: just include fact-checks URLs that match these rules
      # Workspace ID => RegExp
      rules = {
        7821 => /\/(comprova|confere)\//
      }

      prefix, period, slugs = params.to_a
      from, to = parse_period(period)
      slugs = slugs.split('.')

      filename = "#{prefix}-#{from.strftime('%Y-%m-%d')}.csv"
      filepath = "/tmp/#{filename}"
      puts "Getting published fact-checks from #{from} to #{to} for workspaces #{slugs} and saving to #{filepath}."
      output = File.open(filepath, 'w+')

      header = ['URL', 'Title', 'Summary', 'Organization', 'Country', 'Date published on Check', 'First detected on']
      output.puts(header.collect{ |cell| '"' + cell + '"' }.join(','))

      slugs.each_with_index do |slug, i|
        t = Team.find_by_slug(slug)
        q = FactCheck.joins(claim_description: :project_media).where('project_medias.team_id' => t.id, 'fact_checks.updated_at' => from..to)
        n = q.count
        j = 0
        q.find_each do |fc|
          j += 1
          pm = fc.claim_description.project_media
          tid = pm.team_id
          # Just include published fact-checks with at least one request (from the feed or from the tipline)
          published = (pm.report_status(true) == 'published')
          feed_request = ProjectMediaRequest.where(project_media_id: pm.id).order('id ASC').first
          tipline_request = Annotation.where(annotation_type: 'smooch', annotated_type: 'ProjectMedia', annotated_id: pm.id).order('id ASC').first
          request = (feed_request || tipline_request)
          if rules[tid].blank? || (rules[tid] =~ fc.url)
            row = [fc.url, fc.title, fc.summary, t.name, t.country, fc.updated_at, request&.created_at]
            output.puts(row.collect{ |cell| '"' + cell.to_s.gsub('"', '') + '"' }.join(','))
          end
          puts "[#{Time.now}] [Slug #{i + 1}/#{slugs.size} (#{slug})] [Fact-check #{j}/#{n} (##{fc.id})] Published? #{published} | Requested through feed? #{feed_request.present?} | Requested through tipline? #{tipline_request.present?}"
        end
      end

      puts 'Finished!'
      output.close

      puts "Starting upload for #{filename}"
      if object_uploaded?(s3_client, bucket_name, filename, filepath)
        puts "Uploaded #{filename}"
      else
        puts "Error uploading #{filename} to S3. Check credentials?"
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
