# rake check:migrate:set_author_for_articles
namespace :check do
  namespace :migrate do
    task set_author_for_articles: :environment do
      started = Time.now.to_i
      
      [ClaimDescription, FactCheck, Explainer].each do |model|
        query = model.where('created_at = updated_at').where(author_id: nil).order('id ASC')
        puts "[#{Time.now}] Total of instances of model #{model} to be updated: #{query.count}"
        i = 0
        query.in_batches(of: 1000) do |batch|
          i += 1
          batch.update_all('author_id = user_id')
          puts "[#{Time.now}] Updated batch ##{i} of instances of model #{model}"
        end
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
