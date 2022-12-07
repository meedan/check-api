# rake check:migrate:clusterize_requests[feed_id,force]
namespace :check do
  namespace :migrate do
    task clusterize_requests: :environment do |_t, params|
      feed_id = params.to_a.first.to_i
      force = (params.to_a.last.to_i == 1)
      feed = Feed.find(feed_id)
      started = Time.now.to_i

      # Generate a backup if needed
      if force
        puts "[#{Time.now}] Generating a backup of current requests..."
        backup = File.open(File.join(Rails.root, 'tmp', "backup-feed-requests-#{feed_id}-#{Time.now.to_i}.csv"), 'w+')
        header = Request.first.as_json.keys
        backup.puts(header.join(','))
        i = 0
        n = Request.where(feed_id: feed_id).count
        Request.where(feed_id: feed_id).find_each do |r|
          data = r.as_json
          row = []
          header.each { |key| row << data[key] }
          backup.puts(row.join(','))
          i += 1
          puts "[#{Time.now}] [#{i}/#{n}] Backed up request ##{r.id}"
        end
        backup.close
      end

      # Reset data if needed
      if force
        i = 0
        n = Request.where(feed_id: feed_id).count
        Request.where(feed_id: feed_id).find_each do |r|
          i += 1
          subscriptions_count = ((!r.webhook_url.blank? || !r.last_called_webhook_at.blank?) ? 1 : 0)
          r.update_columns({ last_submitted_at: r.created_at, medias_count: 1, requests_count: 1, request_id: nil, subscriptions_count: subscriptions_count, fact_checked_by_count: 0, project_medias_count: 0 })
          puts "[#{Time.now}] [#{i}/#{n}] Reset request ##{r.id}"
        end
      end

      # Clusterize
      query = Request.where(request_id: nil, feed_id: feed_id).order('id ASC')
      n = query.count
      i = 0
      query.find_each do |r|
        i += 1
        failed = false
        begin
          r.attach_to_similar_request!
          Request.send_to_alegre(r.id)
        rescue Exception => e
          failed = e.message
        end
        puts "[#{Time.now}] [#{i}/#{n}] Clusterized request ##{r.id} (#{failed ? 'failed with ' + e.message : 'success'})"
      end

      # Update number of fact-checks and number of project medias
      i = 0
      query = ProjectMediaRequest.joins(:request).where('requests.feed_id' => feed_id)
      n = query.count
      query.find_each do |pmr|
        i += 1
        pmr.send(:update_request_fact_checked_by)
        pmr.send(:update_request_project_medias_count)
        puts "[#{Time.now}] [#{i}/#{n}] Updated project media request ##{pmr.id}"
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
