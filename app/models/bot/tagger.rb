class Bot::Tagger < BotUser
    check_settings
    class Error < ::StandardError
    end

    AUTO_TAG_PREFIX="⚡"

    def self.run(body)
        Rails.logger.info("[AutoTagger Bot] Received event with body of #{body}")
        if CheckConfig.get('alegre_host').blank?
          Rails.logger.warn("[AutoTagger Bot] Skipping events because `alegre_host` config is blank")
          return false
        end
        #TODO: Check if bot is installed on this team
    
        handled = false
        pm = nil
        begin
          pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
          if body.dig(:event) == 'create_project_media' && !pm.nil?
            Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] This item was just created, processing...")
            results=Bot::Alegre.get_merged_similar_items(pm, [{ value: 0.7 }], Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, pm.title)
            #results=Bot::Alegre.get_items_with_similarity(type, pm, 0.7)
            tag_counts=results.map{|nn_pm| ProjectMedia.find(nn_pm).get_annotations('tag')}.reject{|t| t[0]==AUTO_TAG_PREFIX}.group_by(&:itself).transform_values(&:count)
            most_comon_tag=tag_counts.max()&[0]
            if !most_common_tag
              most_common_tag=nil
            else
              #TODO this is wrong
              Tag.create(annotated:pm,tag:AUTO_TAG_PREFIX+most_common_tag)
            end
            handled = true
        end
      rescue StandardError => e
        Rails.logger.error("[Alegre Bot] Exception for event `#{body['event']}`: #{e.message}")
        self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
      end
  
      #self.unarchive_if_archived(pm)
  
      handled
    end
  
end    