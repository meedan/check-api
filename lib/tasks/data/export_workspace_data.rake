# WORKSPACE_DATA_S3_BUCKET='s3-bucket-name' STATUSES_TO_EXPORT='False,Verified' bundle exec rake check:data:export_workspace_data[workspace-slug-1,workspace-slug-2,...,workspace-slug-N]

namespace :check do
  namespace :data do
    desc 'Export all workspace data into a CSV uploaded to S3'
    task export_workspace_data: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      statuses_to_export = ENV.fetch('STATUSES_TO_EXPORT').to_s.split(',')
      bucket_name = ENV.fetch('WORKSPACE_DATA_S3_BUCKET')
      region = 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts 'Please provide the AWS credentials.'
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

      slugs = params.to_a
      Team.where(slug: slugs).find_each do |team|
        slug = team.slug
        filename = "workspace-data-#{slug}-#{Time.now.strftime('%Y-%m-%d')}.csv"
        filepath = File.join(Rails.root, 'tmp', filename)
        puts "Exporting data for workspace and saving to #{filepath}..."
        output = File.open(filepath, 'w+')

        header = ['Claim', 'Status', 'Created by', 'Submitted at', 'Published at', 'Number of media', 'Media: Shares', 'Media: Reactions', 'Media: Comments', 'Tags', 'Reviewed by']
        fields = team.team_tasks.sort
        fields.each { |tt| header << tt.label }
        output.puts(header.collect{ |x| '"' + x.to_s.gsub('"', '') + '"' }.join(','))

        n = team.project_medias.count
        i = 0
        team.project_medias.find_each do |pm|
          i += 1
          puts "[#{i}/#{n}] Exporting item from workspace #{slug}..."
          status = pm.status_i18n
          if statuses_to_export.include?(status)
            row = [
              pm.claim_description&.description,
              status,
              pm.author_name,
              pm.created_at.strftime("%Y-%m-%d %H:%M:%S"),
              pm.published_at&.strftime("%Y-%m-%d %H:%M:%S"),
              pm.linked_items_count,
              pm.share_count,
              pm.reaction_count,
              pm.comment_count,
              pm.tags_as_sentence,
              User.find_by_id(Version.from_partition(team.id).where(associated_type: 'ProjectMedia', associated_id: pm.id).last&.whodunnit&.to_i)&.name
            ]
            annotations = pm.get_annotations('task').map(&:load)
            fields.each do |field|
              annotation = annotations.find { |a| a.team_task_id == field.id }
              row << (annotation ? (begin annotation.first_response_obj.file_data[:file_urls].join("\n") rescue annotation.first_response.to_s end) : '')
            end
            output.puts(row.collect{ |x| '"' + x.to_s.gsub('"', '') + '"' }.join(','))
          end
        end

        puts "Generated export for #{slug} at #{filepath}."
        output.close

        puts "Starting upload for #{filename}..."
        if object_uploaded?(s3_client, bucket_name, filename, filepath)
          puts "Uploaded #{filename}."
        else
          puts "Error uploading #{filename} to S3. Check credentials?"
        end
      end

      ActiveRecord::Base.logger = old_logger
    end
  end
end
