require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern
  include ErrorNotification

  included do
    attr_accessor :mapping, :original_team, :copy_team

    def self.duplicate(t, custom_slug = nil, custom_name = nil)
      @bot_ids = []
      @clones = []
      @project_id_map = {}
      @team_id = nil
      @custom_name = custom_name
      @custom_slug = custom_slug
      ActiveRecord::Base.transaction do
        Version.skip_callback(:create, :after, :increment_project_association_annotations_count)
        team = t.deep_clone include: [
          :projects,
          :contacts,
          :tag_texts,
          :team_tasks
        ] do |original, copy|
          next if original.is_a?(Version)
          @clones << { original: original, clone: copy }
          self.alter_copy_by_type(original, copy)
        end
        self.process_team_bot_installations(t, team)
        team = self.modify_settings(t, team)
        team = self.update_team_rules(team)
        Team.current = team
        self.add_current_user(team)
        team.save!
        self.store_clones
        return team
      end
    end

    def self.modify_settings(old_team, new_team)
      team_task_map = Hash[@clones.select{|x| x[:original].is_a?(TeamTask)}.collect{|x| [x[:original].id, x[:clone].id]}]
      new_list_columns = old_team.get_list_columns.to_a.collect{|lc| lc.include?("task_value_") ? "task_value_#{team_task_map[lc.split("_").last.to_i]}" : lc}
      new_team.set_list_columns = new_list_columns
      new_team.set_languages = old_team.get_languages
      new_team
    end

    def self.add_current_user(team)
      return nil if User.current.nil?
      TeamUser.new(
        role: "owner",
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

    def self.alter_project_copy(copy)
      copy.generate_token(true)
      copy.set_slack_notifications_enabled = false
    end

    def self.alter_copy_by_type(original, copy)
      if original.is_a?(Team)
        self.alter_team_copy(copy)
      elsif original.is_a?(Project)
        self.alter_project_copy(copy)
      elsif original.is_a?(TagText)
        copy.team_id = @team_id if !@team_id.nil?
        copy.tags_count = 0
      end
      copy.save!
      if original.is_a?(Project)
        @project_id_map[original.id] = copy.id
      elsif copy.is_a?(Team)
        @team_id = copy.id
      end
    end

    def self.update_team_rules(new_team)
      team_task_map = Hash[@clones.select{ |c| c[:original].is_a?(TeamTask) }.collect{ |tt| [tt[:original].id, tt[:clone].id] }]
      new_team.get_rules.to_a.each do |rule|
        rule["actions"].to_a.each do |action|
          if ["move_to_project", "copy_to_project", "add_to_project"].include?(action["action_definition"])
            action["action_value"] = @project_id_map[action["action_value"].to_i]
          end
        end
        rule.dig("rules", "groups").to_a.each do |group|
          group["conditions"].each do |condition|
            if ["item_is_assigned_to_user", "item_user_is"].include?(condition["rule_definition"])
              condition["rule_value"] = (!User.current.nil? && !(@bot_ids|[User.current.id]).include?(condition["rule_value"])) ? User.current.id : nil
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
        new_tbi.team = team
        if new_tbi.user.name == 'Smooch'
          new_tbi = Bot::Smooch.sanitize_installation(new_tbi, true)
          new_tbi.settings['smooch_project_id'] = @project_id_map[tbi.settings["smooch_project_id"]]
          new_tbi.settings['smooch_workflows'] = tbi.settings["smooch_workflows"].deep_dup
          tbi.settings['smooch_workflows'].to_a.each_with_index do |w, i|
            w['smooch_custom_resources'].to_a.each_with_index do |r, j|
              new_tbi.settings['smooch_workflows'][i]['smooch_custom_resources'][j] = r.deep_dup.merge({ 'smooch_custom_resource_id' => (0...8).map { (65 + rand(26)).chr }.join })
            end
          end
        end
        new_tbi.save(validate: false)
        @bot_ids << new_tbi.user_id
      end
    end

    def self.store_clones
      @clones.each do |clone|
        if !clone[:original].is_a?(Team)
          if clone[:original].is_a?(TeamTask)
            clone[:clone].project_ids = clone[:clone].project_ids.collect{ |pid| @project_id_map[pid] }
          end
        end
        clone[:clone].save!
      end
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
