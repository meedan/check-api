require 'json'

class Bot::Tagger < BotUser
  check_settings
  class Error < ::StandardError
  end

  def self.get_tag_text(tag_id,auto_tag_prefix,ignore_autotags)
    tag=TagText.find_by_id(tag_id).text
    if tag.nil? || (ignore_autotags && tag[0]==auto_tag_prefix)
      tag=nil
    else
      tag[0]==auto_tag_prefix ? tag[1..] : tag
    end
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
      settings=JSON.parse(body["settings"])
      auto_tag_prefix=settings["auto_tag_prefix"]
      threshold=settings["threshold"]/100.0
      ignore_autotags=settings["ignore_autotags"]
      pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
      if body.dig(:event) == 'create_project_media' && !pm.nil?
        Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] This item was just created, processing...")
        results=Bot::Alegre.get_items_with_similar_text(pm, Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS,
          [{ value: threshold }], pm.title, [Bot::Alegre.matching_model_to_use(pm.team_id)].flatten.reject{|m| m==Bot::Alegre::ELASTICSEARCH_MODEL})
        Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] #{results.length} nearest neighbors #{results.keys()}")
        Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Results: #{results}")
        tag_counts=results.map{|nn_pm,_| ProjectMedia.find(nn_pm).get_annotations('tag')}.flatten.map{|t| self.get_tag_text(t[:data][:tag],auto_tag_prefix,ignore_autotags)}.group_by(&:itself).transform_values(&:count)
        tag_counts=tag_counts.reject{|t|t==nil}.sort_by{|_k,v| v}
        Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Tag distribution #{tag_counts}")
        if tag_counts.length > 0
          max_count=tag_counts.last[1]
          if max_count<settings["minimum_count"]
            Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Max count #{max_count} is less than minimum required to apply a tag")
            return false
          end
          most_common_tags=tag_counts.reject{|_k,v| v < max_count}
          Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] Most common tags #{most_common_tags}")
          most_common_tags.each do |tag|
            Tag.create!(annotated:pm, annotator: BotUser.get_user('tagger'), tag: auto_tag_prefix+tag[0])
          end
        else
          Rails.logger.info("[AutoTagger Bot] [ProjectMedia ##{pm.id}] No most common tag")
        end
        handled = true
      end
    rescue StandardError => e
      Rails.logger.error("[AutoTagger Bot] Exception for event `#{body['event']}`: #{e.message}")
      CheckSentry.notify(e, bot: self.name, body: body)
    end

    handled
  end

end
