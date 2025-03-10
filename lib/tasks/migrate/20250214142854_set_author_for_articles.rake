# rake check:migrate:set_author_for_articles
ActiveRecord::Base.logger = nil
namespace :check do
  namespace :migrate do
    task set_author_for_articles: :environment do
      started = Time.now.to_i

      # Initially set the author for records that were not changed since they were created
      [ClaimDescription, FactCheck, Explainer].each do |model|
        query = model.where('created_at = updated_at').where(author_id: nil).order('id ASC')
        puts "[#{Time.now}] Total of instances of model #{model} to be updated: #{query.count}."
        i = 0
        query.in_batches(of: 1000) do |batch|
          i += 1
          batch.update_all('author_id = user_id')
          puts "[#{Time.now}] Updated author for batch ##{i} of instances of model #{model}."
        end
      end

      # For claims and fact-checks, look into the versions table to update the records that were updated since they were created
      Team.all.order('id ASC').find_each do |team|
        puts "[#{Time.now}] Updating article authors for workspace #{team.slug}..."
        claims = ClaimDescription.where(author_id: nil, team_id: team.id).order('id ASC')
        claims_count = claims.count
        puts "[#{Time.now}] Total of claims to be updated: #{claims_count}."
        i = 0
        claims.find_each do |claim|
          i += 1

          # Update claim
          claim_author = Version.from_partition(team.id).where(item_type: 'ClaimDescription', event: 'create', item_id: claim.id).last&.whodunnit
          # Skip if no author found from the versions table
          if claim_author.to_i == 0
            puts "[#{Time.now}] Skipping claim #{claim.id} because no author was found from the versions table."
          else
            claim.update_column(:author_id, claim_author.to_i)
            puts "[#{Time.now}] [#{i}/#{claims_count}] Updated author to be #{claim_author} for claim #{claim.id}."
          end

          # Update fact-check
          fact_check = claim.fact_check
          # Skip if no fact-check found for claim
          if fact_check.nil?
            puts "[#{Time.now}] [#{i}/#{claims_count}] Skipping, no fact-check found for claim #{claim.id}."
            next
          end
          fact_check_author = Version.from_partition(team.id).where(item_type: 'FactCheck', event: 'create', item_id: fact_check.id).last&.whodunnit
          # Skip if no author found from the versions table
          if fact_check_author.to_i == 0
            puts "[#{Time.now}] Skipping fact-check #{fact_check.id} because no author was found from the versions table."
          else
            fact_check.update_column(:author_id, fact_check_author.to_i)
            puts "[#{Time.now}] [#{i}/#{claims_count}] Updated author to be #{fact_check_author} for fact-check #{fact_check.id}."
          end
        end

        puts "[#{Time.now}] Updated article authors for workspace #{team.slug}."
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
