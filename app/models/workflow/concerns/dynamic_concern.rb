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

        ::Workflow::Workflow.workflows.each do |workflow|
          id = workflow.id

          attr_accessor "previous_#{id}".to_sym

          define_method(id) do
            self.get_field("#{id}_status").to_s if self.annotation_type == id
          end

          if workflow.notify_slack?
            define_method "slack_notification_message_#{id}" do
              from_status = self.send("previous_#{id}")
              to_status = self.send(id)
              params = self.slack_params.merge({
                from_status: Bot::Slack.to_slack(from_status),
                to_status: Bot::Slack.to_slack(to_status),
                workflow: I18n.t("statuses.ids.#{id}")
              })
              if from_status != to_status && !from_status.blank?
                event = 'status'
              elsif !params[:assignment_event].blank?
                params.delete(:from_status)
                event = params[:assignment_event]
              else
                return nil
              end
              {
                pretext: I18n.t("slack.messages.project_media_#{event}", params),
                title: params[:title],
                title_link: params[:url],
                author_name: params[:user],
                author_icon: params[:user_image],
                text: params[:description],
                fields: [
                  {
                    title: I18n.t(:'slack.fields.status'),
                    value: params[:to_status],
                    short: true
                  },
                  {
                    title: I18n.t(:'slack.fields.status_previous'),
                    value: params[:from_status],
                    short: true
                  },
                  {
                    title: I18n.t(:'slack.fields.assigned'),
                    value: params[:assigned],
                    short: true
                  },
                  {
                    title: I18n.t(:'slack.fields.unassigned'),
                    value: params[:unassigned],
                    short: true
                  },
                  {
                    title: params[:parent_type],
                    value: params[:item],
                    short: false
                  }
                ],
                actions: [
                  {
                    type: "button",
                    text: params[:button],
                    url: params[:url]
                  }
                ]
              }
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
