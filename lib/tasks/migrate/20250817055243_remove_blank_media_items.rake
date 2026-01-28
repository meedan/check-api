# rake check:migrate:add_blank_media_to_standalone_fact_checks
namespace :check do
  namespace :migrate do
    def get_claim_uuid(id, quote)
      hash_value = Digest::MD5.hexdigest(quote.to_s.strip.downcase)
      uuid = Claim.where(quote_hash: hash_value).joins("INNER JOIN project_medias pm ON pm.media_id = medias.id").first&.id
      uuid ||= id
    end
    # bundle exec rails check:migrate:migrate_published_and_unpublished_items
    task migrate_published_and_unpublished_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      options = {
        index: CheckElasticSearchModel.get_index_alias,
      }
      # Remove blank items for unpublished reports
      puts "\nRemove blank items for unpublished reports\n"
      last_unpublished_cd_id = Rails.cache.read('check:migrate:remove_unpublished_blank_media_items:claim_description_id') || 0
      ClaimDescription.where("claim_descriptions.id > ?", last_unpublished_cd_id).joins(:fact_check).joins({project_media: :media})
      .where('medias.type = ?', 'Blank')
      .where.not('fact_checks.report_status = ?', 1)
      .find_in_batches(batch_size: 1000) do |claims|
        print '.'
        # Update project_media_id columns and reset Claims in ES docs
        ids = claims.pluck(:id)
        pm_ids = claims.pluck(:project_media_id)
        ClaimDescription.where(id: ids).update_all(project_media_id: nil)
        body = {
          script: { 
            source: "
              ctx._source.claim_description_content = params.content; \
              ctx._source.claim_description_context = params.context; \
              ctx._source.fact_check_title = params.fc_title; \
              ctx._source.fact_check_summary = params.fc_summary; \
              ctx._source.fact_check_url = params.fc_url; \
              ctx._source.fact_check_languages = params.fc_languages \
            ",
            params: { 
              content: nil,
              context: nil,
              fc_title: nil,
              fc_summary: nil,
              fc_url: nil,
              fc_languages: []
            }
          },
          query: { terms: { annotated_id: ids } }
        }
        options[:body] = body
        client.update_by_query options
        Rails.cache.write('check:migrate:remove_unpublished_blank_media_items:claim_description_id', ids.max)
      end

      # Replace blank items with Claim items for published reports
      puts "\nReplace blank items with Claim items for published reports\n"
      last_published_cd_id = Rails.cache.read('check:migrate:remove_published_blank_media_items:claim_description_id') || 0
      ClaimDescription.where("claim_descriptions.id > ?", last_published_cd_id).joins(:fact_check).joins({project_media: :media})
      .where('medias.type = ?', 'Blank')
      .where('fact_checks.report_status = ?', 1)
      .find_in_batches(batch_size: 1000) do |claims|
        print '.'
        # Update project_media_id columns and reset Claims in ES docs
        ids = claims.pluck(:id)
        pm_ids = claims.pluck(:project_media_id)
        ProjectMedia.select('project_medias.*, fact_checks.title AS fc_title')
        .where(id: pm_ids)
        .joins({claim_description: :fact_check})
        .find_in_batches(batch_size: 1000) do |items|
          print '.'
          items.each do |pm|
            print '.'
            claim_values = [{ type: 'Claim', quote: pm.fc_title, user_id: pm.user_id, created_at: pm.created_at, updated_at: pm.updated_at }]
            result = Claim.insert_all(claim_values, returning: [:id])
            mid = result.rows.first[0]
            ProjectMedia.find(pm.id).update_column(:media_id, mid)
          end
        end
        Rails.cache.write('check:migrate:remove_published_blank_media_items:claim_description_id', ids.max)
      end

      # Replace Blank items with Claims only (no fact-checks)
      claim_id = Claim.find_or_create_by(quote: '-')
      ProjectMedia.joins(:media)
      .where('medias.type = ?', 'Blank')
      .joins(:claim_description)
      .joins('LEFT JOIN fact_checks fc on fc.claim_description_id = claim_descriptions.id')
      .where('fc.id is NULL').in_batches(of: 500) do |items|
        print '.'
        items.update_all(media_id: claim_id)
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # rake task to set quote_hash for Claims
    # bundle exec rails check:migrate:set_claim_quote_hash
    task set_claim_quote_hash: :environment do
      started = Time.now.to_i
      last_claim_id = Rails.cache.read('check:migrate:set_claim_quote_hash') || 0
      Claim.where('id > ?', last_claim_id)
      .find_in_batches(batch_size: 2000) do |claims|
        c_items = []
        claims.each do |claim|
          print '.'
          claim.quote_hash = Digest::MD5.hexdigest(claim.quote.to_s.strip.downcase)
          c_items << claim.attributes
        end
        Claim.upsert_all(c_items)
        Rails.cache.write('check:migrate:set_claim_quote_hash', claims.pluck(:id).max)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # rake task to set Claim uuid
    # bundle exec rails check:migrate:set_claim_uuid
    task set_claim_uuid: :environment do
      started = Time.now.to_i
      Claim.where(uuid: 0)
      .find_in_batches(batch_size: 1000) do |claims|
        claims.each do |claim|
          print '.'
          uuid = get_claim_uuid(claim.id, claim.quote)
          claim.update_column(:uuid, uuid)
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # rake task to delete blank items
    # bundle exec rails check:migrate:remove_blank_media_items
    task remove_blank_media_items: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:remove_blank_media_items') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.joins(:media).where('medias.type = ?', 'Blank')
        .find_in_batches(batch_size: 500) do |pms|
          print '.'
          media_ids = pms.pluck(:media_id)
          # Use delete_all to make it faster.
          Media.where(id: media_ids, type: 'Blank').delete_all
          pm_ids = pms.map(&:id)
          # Use delete_all to make it faster but first I should delete all associated items in other tables like
          # ProjectMediaUser, ProjectMediaRequest, ClusterProjectMedia, TiplineRequest and ExplainerItem
          ApplicationRecord.transaction do
            ProjectMediaUser.where(project_media_id: pm_ids).delete_all
            ProjectMediaRequest.where(project_media_id: pm_ids).delete_all
            ClusterProjectMedia.where(project_media_id: pm_ids).delete_all
            TiplineRequest.where(associated_type: "ProjectMedia", associated_id: pm_ids).delete_all
            ExplainerItem.where(project_media_id: pm_ids).delete_all
            ProjectMedia.where(id: pm_ids).delete_all
          end
        end
        Rails.cache.write('check:migrate:remove_blank_media_items', team.id)
      end
      # Delete Blank items that not associated to ProjectMedia
      Blank.in_batches(of: 500) do |items|
        print '.'
        items.delete_all
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
