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
