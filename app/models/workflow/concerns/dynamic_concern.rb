module Workflow
  module Concerns
    module DynamicConcern
      Dynamic.class_eval do
        before_validation :store_previous_status

        def status=(value)
          self.set_fields = { "#{self.annotation_type}_status" => value }.to_json
        end

        def status
          self&.get_field("#{self.annotation_type}_status")&.value
        end

        ::Workflow::Workflow.workflow_ids.each do |id|
          attr_accessor "previous_#{id}".to_sym
          
          define_method(id) do
            self.get_field("#{id}_status").to_s if self.annotation_type == id
          end

          define_method "slack_notification_message_#{id}" do
            from, to = Bot::Slack.to_slack(self.send("previous_#{id}")), Bot::Slack.to_slack(self.send(id))
            url = Bot::Slack.to_slack_url(self.annotated_client_url, self.annotated.title)
            project = Bot::Slack.to_slack(self.annotated.project.title)
            user = Bot::Slack.to_slack(User.current.name)

            if !from.blank? && from != to
              I18n.t("slack_update_#{id}",
                url: url,
                user: user,
                project: project,
                report: Bot::Slack.to_slack_url(self.annotated_client_url, self.annotated.title),
                from: from,
                to: to
              )
            elsif self.assigned_to_id != self.previous_assignee
              assignee = nil
              action = ''
              if self.assigned_to_id.to_i > 0
                assignee = Bot::Slack.to_slack(User.find(self.assigned_to_id).name)
                action = 'assign'
              else
                assignee = Bot::Slack.to_slack(User.find(self.previous_assignee).name)
                action = 'unassign'
              end
              I18n.t("slack_#{action}_#{id}".to_sym,
                user: user,
                url: url,
                assignee: assignee,
                project: project
              )
            end
          end
        end

        private

        def store_previous_status
          ::Workflow::Workflow.workflow_ids.each do |id|
            self.send("previous_#{id}=", self.send(id)) if self.annotation_type == id
          end
        end
      end # Dynamic.class_eval
    end
  end
end
