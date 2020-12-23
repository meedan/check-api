require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern
  include ErrorNotification

  included do
    attr_accessor :mapping, :original_team, :copy_team

    def self.duplicate(t)
      @clones = []
      @project_id_map = {}
      team_id = nil
      begin
        ActiveRecord::Base.transaction do
          Version.skip_callback(:create, :after, :increment_project_association_annotations_count)
          team = t.deep_clone include: [
            :projects,
            :contacts,
            :tag_texts,
            :team_tasks
          ] do |original, copy|
            next if original.is_a?(Version)
            @clones << {original: original, clone: copy}
            if original.is_a?(Team)
              copy.name = "Copy of #{copy.name}"
              copy.slug = copy.generate_copy_slug
              copy.is_being_copied = true
            elsif original.is_a?(Project)
              copy.generate_token(true)
            elsif original.is_a?(TagText)
              copy.team_id = team_id if !team_id.nil?
            end
            copy.save(validate: false)
            if original.is_a?(Project)
              @project_id_map[original.id] = copy.id
            elsif copy.is_a?(Team)
              team_id = copy.id
            end
          end
          processed_user_ids = self.process_team_bot_installations(t, team)
          self.process_team_users(t, team, processed_user_ids)
          team.save(validate: false)
          self.store_clones(team)
          # • The rules key in the workspace settings field should point to the cloned lists for any action of type move to list or add to list
          # • Implement a GraphQL mutation to clone a workspace
          return team
        end
      rescue StandardError => e
        self.log_error(e, t)
        nil
      end
    end

    def self.process_team_users(t, team, processed_user_ids)
      t.team_users.each do |tu|
        next if processed_user_ids.include?(tu.user_id)
        new_tu = TeamUser.new(tu.attributes.select{|k,_| k!="id"})
        new_tu.team = team
        new_tu.save!
      end
    end

    def self.process_team_bot_installations(t, team)
      processed_user_ids = []
      t.team_bot_installations.each do |tbi|
        new_tbi = tbi.deep_clone
        new_tbi.team = team
        if new_tbi.user.name == "Smooch"
          new_tbi.settings["smooch_project_id"] = @project_id_map[tbi.settings["smooch_project_id"]]
        end
        new_tbi.save(validate: false)
        processed_user_ids << new_tbi.user_id
      end
      processed_user_ids
    end

    def self.store_clones(team)
      @clones.each do |clone|
        if !clone[:original].is_a?(Team)
          if clone[:clone].respond_to?(:team_id) && clone[:clone].team_id.nil?
            clone[:clone].team_id = team.id
          end
          if clone[:original].is_a?(TeamTask)
            clone[:clone].project_ids = clone[:clone].project_ids.collect{|pid| @project_id_map[pid]}
          end
        end
        clone[:clone].save!
      end
    end

    def self.log_error(e, t)
      self.notify_error(e, { team_id: t.id }, RequestStore[:request])
      Rails.logger.error "[Team Duplication] Could not duplicate team #{t.slug}: #{e.message} #{e.backtrace.join("\n")}"
    end
  end

  def generate_copy_slug
    i = 1
    slug = ''
    loop do
      slug = self.slug + "-copy-#{i}"
      if slug.length > 63
        extra = slug.length - 63
        slug.remove!(slug[11..10+extra])
      end
      break unless Team.find_by(slug: slug)
      i += 1
    end
    slug
  end
end
