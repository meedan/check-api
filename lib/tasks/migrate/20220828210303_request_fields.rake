namespace :check do
  namespace :migrate do
    task request_fields: :environment do
      started = Time.now.to_i
      query = Request.where(media_id: nil).order('id ASC')
      count = query.count
      counter = 0
      query.find_each do |r|
        counter += 1
        failed = false
        begin
          request_type = (['audio', 'video', 'image', 'text'].include?(r.request_type) ? r.request_type : 'text')
          media = Request.get_media_from_query(request_type, r.content)
          r.update_columns({ media_id: media.id, last_submitted_at: r.created_at, medias_count: 1, requests_count: 1 })
          Request.send_to_alegre(r.id)
          sleep 1
          r = Request.find(r.id)
          r.attach_to_similar_request!
        rescue Exception => e
          failed = e.message
        end
        puts "[#{Time.now}] Processed item #{counter}/#{count}: ##{r.id} (#{failed ? 'failed with ' + e.message : 'success'})"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
