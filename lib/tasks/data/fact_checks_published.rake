# bundle exec rake check:data:fact_checks_published[from,to,workspace.slugs.separated.by.dots]

namespace :check do
  namespace :data do
    desc 'List fact-checks published in a certain interval'
    task fact_checks_published: :environment do |_t, params|
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil

      from, to, slugs = params.to_a
      from = Time.parse(from).beginning_of_day
      to = Time.parse(to).end_of_day
      slugs = slugs.split('.')
      
      filepath = "/tmp/#{Digest::MD5.hexdigest([from.strftime("%Y-%m-%d"), to.strftime("%Y-%m-%d"), slugs].flatten.join('-'))}.csv"
      puts "Getting published fact-checks from #{from} to #{to} for workspaces #{slugs} and saving to #{filepath}."
      output = File.open(filepath, 'w+')

      header = ['URL', 'Title', 'Summary', 'Organization', 'Country', 'Date published on Check']
      output.puts(header.collect{ |cell| '"' + cell + '"' }.join(','))

      slugs.each_with_index do |slug, i|
        t = Team.find_by_slug(slug)
        q = FactCheck.joins(claim_description: :project_media).where('project_medias.team_id' => t.id, 'fact_checks.updated_at' => from..to)
        n = q.count
        j = 0
        q.find_each do |fc|
          j += 1
          pm = fc.claim_description.project_media
          # Just include published fact-checks with at least one request (from the feed or from the tipline)
          published = (pm.report_status(true) == 'published')
          feed_requested = (ProjectMediaRequest.where(project_media_id: pm.id).exists?)
          tipline_requested = (Annotation.where(annotation_type: 'smooch', annotated_type: 'ProjectMedia', annotated_id: pm.id).exists?)
          if (published && (feed_requested || tipline_requested))
            row = [fc.url, fc.title, fc.summary, t.name, t.country, fc.updated_at]
            output.puts(row.collect{ |cell| '"' + cell.to_s.gsub('"', '') + '"' }.join(','))
          end
          puts "[#{Time.now}] [Slug #{i + 1}/#{slugs.size} (#{slug})] [Fact-check #{j}/#{n} (##{fc.id})] Published? #{published} | Requested through feed? #{feed_requested} | Requested through tipline? #{tipline_requested}"
        end
      end

      puts 'Finished!'
      output.close
      ActiveRecord::Base.logger = old_logger
    end
  end
end
