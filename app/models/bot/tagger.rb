require 'json'

class Bot::Tagger < BotUser
  check_settings

  class Error < ::StandardError
  end

  def self.get_tag_text(tag_id, auto_tag_prefix, ignore_autotags)
    tag = TagText.find_by_id(tag_id)&.text
    if tag.nil? || (ignore_autotags && tag[0] == auto_tag_prefix)
      return nil
    else
      tag[0] == auto_tag_prefix ? tag[1..] : tag
    end
  end

  def self.log(message, pm_id = nil, level = Logger::INFO)
    prefix = "[AutoTagger Bot] "
    prefix += "[ProjectMedia ##{pm_id}] " if pm_id
    Rails.logger.log(level, "#{prefix} #{message}")
  end

  def self.run(body)
    self.log("Received event with body of #{body}", nil, Logger::INFO)
    if CheckConfig.get('alegre_host').blank?
      self.log("Skipping events because alegre_host config is blank", nil, Logger::DEBUG)
      return false
    end

    handled = false
    pm = nil
    begin
      settings = JSON.parse(body[:settings])
      auto_tag_prefix = settings["auto_tag_prefix"]
      threshold = settings["threshold"] / 100.0
      ignore_autotags = settings["ignore_autotags"]
      pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
      if body.dig(:event) == 'create_project_media' && !pm.nil?
        self.log("This item was just created, processing...", pm.id, Logger::INFO)

        # Search all text fields for all items in the workspace using only the configured vector model
        search_texts = ['original_title', 'original_description', 'extracted_text', 'transcription', 'claim_description_content'].map{ |field| pm.send(field) if !pm.nil? && pm.respond_to?(field) }

        # Remove duplicate and nil values
        search_texts = search_texts.uniq.compact.reject{ |q| q.length == 0 }
        self.log("Query values are: #{search_texts}", pm.id, Logger::INFO)

        # Search for each text field in search_texts
        # Do not use Elasticsearch. The threshold to use comes from the Tagger bot settings.
        # Method signature: get_items_with_similar_text(pm, fields, threshold, query_text, models, team_ids = [pm&.team_id])
        results = []
        search_texts.each do |query|
          results << Bot::Alegre.get_items_with_similar_text(pm, Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, [{ value: threshold }], query, [Bot::Alegre.matching_model_to_use(pm.team_id)].flatten.reject{ |m| m == Bot::Alegre::ELASTICSEARCH_MODEL })
          # self.debug("Results (#{query}): #{results}", pm.id, Logger::INFO)
        end
        # Combine the list of hashes into one hash
        results = results.reduce({}, :merge!)
        self.log("#{results.length} nearest neighbors #{results.keys()}", pm.id, Logger::INFO)
        self.log("Results: #{results}", pm.id, Logger::INFO)

        # For each nearest neighbor, get the tags.
        tag_counts = results.map{ |nn_pm, _| ProjectMedia.find(nn_pm).get_annotations('tag') }.flatten
        # Transform from tag objects to strings
        # .compact removes any nil values returned by get_tag_text
        tag_counts = tag_counts.map{ |t| self.get_tag_text(t[:data][:tag],auto_tag_prefix, ignore_autotags) }.compact
        # Convert to counts and sort by the counts (low to high)
        tag_counts = tag_counts.group_by(&:itself).transform_values(&:count).sort_by{ |_k, v| v }
        # tag_counts is now an array of arrays with counts e.g., [['nature', 1], ['sport', 2]]
        self.log("Tag distribution #{tag_counts}", pm.id, Logger::INFO)
        if tag_counts.length > 0
          max_count = tag_counts.last[1]
          if max_count < settings["minimum_count"]
            self.log("Max count #{max_count} is less than minimum required to apply a tag", pm.id, Logger::INFO)
            return false
          end
          most_common_tags = tag_counts.reject{ |_k, v| v < max_count }
          self.log("Most common tags #{most_common_tags}", pm.id, Logger::INFO)
          most_common_tags.each do |tag|
            Tag.create!(annotated: pm, annotator: BotUser.get_user('tagger'), tag: auto_tag_prefix + tag[0])
          end
        else
          self.log("No most common tag", pm.id, Logger::INFO)
        end
        handled = true
      end
    rescue StandardError => e
      error = Error.new(e)
      Rails.logger.error("[AutoTagger Bot] Exception for event #{body['event']}: #{error.class} - #{error.message}")
      CheckSentry.notify(error, bot: self.name, body: body)
    end

    handled
  end
end
