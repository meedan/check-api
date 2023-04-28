class Bot::Tagger < BotUser
    check_settings
    class Error < ::StandardError
    end

    AUTO_TAG_PREFIX="⚡"

    def self.get_tag_text(tag_id)
      tag=TagText.find(tag_id).text
      tag[0]==AUTO_TAG_PREFIX ? tag[1..] : tag
    end

    def self.run(body)
        Rails.logger.info("[AutoTagger Bot] Received event with body of #{body}")
        if CheckConfig.get('alegre_host').blank?
          Rails.logger.warn("[AutoTagger Bot] Skipping events because `alegre_host` config is blank")
          return false
        end
    
        handled = false
        pm = nil
        begin
          pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
          if body.dig(:event) == 'create_project_media' && !pm.nil?
            Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] This item was just created, processing...") 
            results=Bot::Alegre.get_merged_similar_items(pm, [{ value: 0.7 }], Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, pm.title)
            Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] #{results.length} nearest neighbors #{results.keys()}")
            Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Results: #{results}")
            tag_counts=results.map{|nn_pm,_| ProjectMedia.find(nn_pm).get_annotations('tag')}.flatten.map{|t| self.get_tag_text(t[:data][:tag])}.group_by(&:itself).transform_values(&:count)
            tag_counts=tag_counts.sort_by{|k,v| v}
            Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Tag distribution #{tag_counts}")
            #TODO future decide if we should reject autotags (or make it a setting)    .reject{|t|t[0]==AUTO_TAG_PREFIX}.first
            if tag_counts&.length>0
              max_count=tag_counts.last[1]
              most_common_tags=tag_counts.reject{|k,v| v<max_count}
              Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Most common tags #{most_common_tags}")
              most_common_tags.each do |tag|
                Tag.create(annotated:pm,tag: AUTO_TAG_PREFIX+tag[0])
              end
            else
              Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] No most common tag")
            end
            handled = true
        end
      rescue StandardError => e
        Rails.logger.error("[AutoTagger Bot] Exception for event `#{body['event']}`: #{e.message}")
        self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
      end
  
      #self.unarchive_if_archived(pm)
  
      handled
    end
  
end    