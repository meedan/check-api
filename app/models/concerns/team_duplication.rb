require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :mapping, :original_team, :copy_team

    def self.duplicate(t, custom_slug = nil, custom_name = nil)
      @bot_ids = []
      @clones = []
      @team_id = nil
      @custom_name = custom_name
      @custom_slug = custom_slug
      ApplicationRecord.transaction do
        team = t.deep_clone include: [
          :saved_searches,
          :tag_texts,
          :team_tasks
        ],
        preprocessor: -> (original, copy) {
          next if original.is_a?(Version)
          @clones << { original: original, clone: copy }
          self.alter_copy_by_type(original, copy)
        }
        self.process_team_bot_installations(t, team)
        team = self.modify_settings(t, team)
        team = self.update_team_rules(team)
        self.adjust_team_tasks(team)
        Team.current = team
        self.add_current_user(team)
        team.skip_check_ability = true
        team.save!
        self.store_clones
        return team
      end
    end

    def self.modify_settings(old_team, new_team)
      new_team.set_languages = old_team.get_languages
      new_team.set_language = old_team.get_language
      new_team
    end

    def self.add_current_user(team)
      return nil if User.current.nil?
      TeamUser.new(
        skip_check_ability: true,
        role: "admin",
        status: "member",
        user_id: User.current.id,
        team_id: team.id
      ).save!
    end

    def self.alter_team_copy(copy)
      copy.name = @custom_name || "Copy of #{copy.name}"
      copy.slug = @custom_slug || copy.generate_copy_slug
      copy.is_being_copied = true
      copy.set_slack_notifications_enabled = false
    end

    def self.alter_saved_search_copy(copy)
      copy.is_being_copied = true
    end

    def self.alter_tag_text_copy(copy)
      copy.team_id = @team_id if !@team_id.nil?
      copy.tags_count = 0
    end

    def self.adjust_team_tasks(team)
      team_task_map = self.team_task_map
      team.team_tasks.each do |copy|
        unless copy.conditional_info.nil?
          ci = JSON.parse(copy.conditional_info)
          ci['selectedFieldId'] = team_task_map[ci['selectedFieldId'].to_i] unless ci['selectedFieldId'].blank?
          copy.conditional_info = ci.to_json
          copy.save!
        end
      end
    end

    def self.alter_team_task_copy(_copy)
    end

    def self.alter_copy_by_type(original, copy)
      copy.skip_check_ability = true # We use a specific "duplicate" permission before calling the Team.duplicate method
      self.send("alter_#{original.class_name.underscore}_copy", copy)
      copy.save!
      if copy.is_a?(Team)
        @team_id = copy.id
      end
    end

    def self.team_task_map
      Hash[@clones.select{ |c| c[:original].is_a?(TeamTask) }.collect{ |tt| [tt[:original].id, tt[:clone].id] }]
    end

    def self.alter_rule_value_user(user_id)
      (!User.current.nil? && !(@bot_ids|[User.current.id]).include?(user_id)) ? User.current.id : nil
    end

    def self.update_team_rules(new_team)
      team_task_map = self.team_task_map
      new_team.get_rules.to_a.each do |rule|
        rule.dig("rules", "groups").to_a.each do |group|
          group["conditions"].each do |condition|
            if ["item_is_assigned_to_user", "item_user_is"].include?(condition["rule_definition"])
              condition["rule_value"] = self.alter_rule_value_user(condition["rule_value"])
            end
            condition["rule_value"]["team_task_id"] = team_task_map[condition["rule_value"]["team_task_id"]] if condition["rule_definition"].match(/^field_from_fieldset/)
          end
        end
      end
      new_team
    end

    def self.process_team_bot_installations(t, team)
      t.team_bot_installations.each do |tbi|
        new_tbi = TeamBotInstallation.where(team: team, user: tbi.user).first || tbi.deep_dup
        next if new_tbi.user.name == 'Smooch'
        new_tbi.team = team
        new_tbi.skip_check_ability = true
        new_tbi.save(validate: false)
        @bot_ids << new_tbi.user_id
      end
    end

    def self.store_clones
      @clones.each do |clone|
        if !clone[:original].is_a?(Team)
          if clone[:original].is_a?(SavedSearch)
            clone[:clone].filters = self.update_saved_search_filters(clone[:clone].filters)
          end
        end
        clone[:clone].skip_check_ability = true
        clone[:clone].save!
      end
    end

    def self.update_saved_search_filters(filters)
      return filters if filters.nil?
      filters = JSON.parse(filters.to_s) if filters.is_a?(String)
      filters['team_tasks'].to_a.each_with_index { |filter, i| filters['team_tasks'][i]['id'] = self.team_task_map[filter['id'].to_i].to_s }
      filters
    end
  end

  def generate_copy_slug
    i = 1
    slug = ''
    loop do
      slug = self.slug + "-copy-#{i}"
      if slug.length > 63
        extra = slug.length - 63
        slug.remove!(slug[11..10 + extra])
      end
      break unless Team.find_by(slug: slug)
      i += 1
    end
    slug
  end
end
