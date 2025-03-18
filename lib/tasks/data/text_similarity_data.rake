# bundle exec rake check:data:text_similarity_data['s3_bucket_name=s3_bucket_name&workspace_slugs[]=workspace-slug-1&workspace_slugs[]=workspace-slug-2&...&workspace_slugs[]=workspace-slug-n']

namespace :check do
  namespace :data do
    desc 'Export text similarity data.'
    task :text_similarity_data, [:query_string] => [:environment] do |_task, args|
      ActiveRecord::Base.logger = nil
      require 'zlib'
      require 'stringio'

      def channel_name(item)
        CheckChannels::ChannelCodes.all_channels.find{ |_k, v| v == item.channel.to_h['main'].to_i }.to_a[0] ||
        CheckChannels::ChannelCodes.all_channels['TIPLINE'].find{ |_k, v| v == item.channel.to_h['main'].to_i }.to_a[0]
      end

      def origin_name(item)
        CheckMediaClusterOrigins::OriginCodes.all_origins.find{ |_k, v| v == item.media_cluster_origin.to_i }.to_a[0]
      end

      def standalone_article(article, type)
        body_method_mapping = {
          'explainer' => :description,
          'fact-check' => :summary
        }
        claim = nil
        claim = article.claim_description.description if type == 'fact-check'
        {
          id: nil,
          team_id: nil,
          team_slug: nil,
          media_id: nil,
          title: nil,
          description: nil,
          channel: nil,
          origin: nil,
          relationships: [],
          articles: [{
            id: article.graphql_id,
            title: article.title,
            body: article.send(body_method_mapping[type]),
            url: article.url,
            type: type,
            claim: claim,
            created_at: article.created_at,
            language: article.language
          }]
        }
      end

      # Parse input parameters
      options = Rack::Utils.parse_nested_query(args[:query_string])
      s3_bucket_name = options['s3_bucket_name']
      workspace_slugs = options['workspace_slugs']
      team_ids = Team.where(slug: workspace_slugs).map(&:id)

      # Structure for the data: Array of next project media objects like:
      # {
      #    id: 1,
      #    title: 'Example',
      #    ...,
      #    articles: [...],
      #    relationships: [...],
      # }
      data = [] 

      # Single-query approach (WIP / draft)
      # query = ProjectMedia
      #         .joins(:team).where('teams.slug' => workspace_slugs) # Only items from the selected workspaces
      #         .joins('LEFT JOIN explainer_items ei ON ei.project_media_id = project_medias.id LEFT JOIN explainers e ON e.id = ei.explainer_id') # Includes explainers
      #         .joins('LEFT JOIN claim_descriptions cd ON cd.project_media_id = project_medias.id LEFT JOIN fact_checks fc ON fc.claim_description_id = cd.id') # Includes fact-checks
      #         .joins('LEFT JOIN relationships r ON r.source_id = project_medias.id OR r.target_id = project_medias.id') # Includes relationships
      # query.to_sql

      # ActiveRecord approach

      # Get text items associated with explainers and fact-checks
      query = ProjectMedia.joins(:media).where('project_medias.team_id' => team_ids, 'medias.type' => 'Claim') # Only text items from the selected workspaces
      total = query.count
      i = 0
      query.find_each do |item|
        i += 1
        puts "[#{Time.now}] Exporting item #{i}/#{total}..."

        # Item data
        object = {
          id: item.id,
          team_id: item.team_id,
          team_slug: item.team.slug,
          media_id: item.media_id,
          title: item.title,
          description: item.description,
          channel: channel_name(item),
          origin: origin_name(item),
          created_at: item.created_at,
          language: item.language_code
        }

        # Explainers, if any
        object[:articles] = []
        item.explainers.find_each do |explainer|
          object[:articles] << {
            id: explainer.graphql_id,
            title: explainer.title,
            body: explainer.description,
            url: explainer.url,
            claim: nil,
            type: 'explainer',
            created_at: explainer.created_at,
            language: explainer.language
          }
        end

        # Fact-check, if any
        unless item.fact_check.nil?
          fact_check = item.fact_check
          object[:articles] << {
            id: fact_check.graphql_id,
            title: fact_check.title,
            body: fact_check.summary,
            url: fact_check.url,
            claim: fact_check.claim_description.description,
            type: 'fact-check',
            created_at: fact_check.created_at,
            language: fact_check.language
          }
        end

        # Relationships
        object[:relationships] = []
        Relationship.where('source_id = ? OR target_id = ?', item.id, item.id).find_each do |relationship|
          object[:relationships] << {
            parent_id: relationship.source_id,
            child_id: relationship.target_id,
          }.merge(relationship.as_json)
        end

        data << object
      end

      # Complete the data with the explainers that are not associated to any item
      Explainer.joins('LEFT JOIN explainer_items ei ON ei.explainer_id = explainers.id').where('ei.explainer_id IS NULL').where('explainers.team_id' => team_ids).find_each do |explainer|
        data << standalone_article(explainer, 'explainer')
      end

      # Complete the data with the fact-checks that are not associated to any item
      FactCheck.joins(:claim_description).where('claim_descriptions.team_id' => team_ids, 'claim_descriptions.project_media_id' => nil).find_each do |fact_check|
        data << standalone_article(fact_check, 'fact-check')
      end
      FactCheck.joins(claim_description: { project_media: :media }).where('claim_descriptions.team_id' => team_ids, 'medias.type' => 'Blank').find_each do |fact_check|
        data << standalone_article(fact_check, 'fact-check')
      end

      # Convert to JSON and upload to S3
      region = CheckConfig.get('storage_bucket_region') || 'eu-west-1'
      begin
        s3_client = Aws::S3::Client.new(region: region)
      rescue Aws::Sigv4::Errors::MissingCredentialsError
        puts 'Please provide the AWS credentials.'
        exit 1
      end
      body = data.collect{ |row| row.to_json }.join("\n")
      key = "text-similarity-data-export-#{Time.now.strftime('%Y-%m-%d')}.json"
      output_file_path = File.join(Rails.root, 'tmp', key)
      file = File.open(output_file_path, 'w+')
      file.puts body
      file.close
      zipped = "#{output_file_path}.gz"
      Zlib::GzipWriter.open(zipped) do |gz|
        gz.write IO.binread(output_file_path)
      end
      zfile_path = File.join(Rails.root, 'tmp', zipped)

      response = s3_client.put_object(
        bucket: s3_bucket_name,
        key: "#{key}.gz",
        body: zfile_path,
        content_encoding: 'gzip',
      )
      if response.etag
        puts 'Uploaded to S3 successfully.'
      else
        puts 'Error uploading to S3.'
        exit 1
      end
    end
  end
end
