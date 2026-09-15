class CheckDataExportWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform(id, action)
    object = CheckDataExport.find_by_id(id)
    unless object.nil?
      next_action = {
        'initiate_readme' => 'export_workspace_data',
        'export_workspace_data' => 'export_workspace_user_data',
        'export_workspace_user_data' => 'export_workspace_articles_data',
        'export_workspace_articles_data' => 'export_workspace_annotations_data',
        'export_workspace_annotations_data' => 'export_workspace_tipline_requests_data',
        'export_workspace_tipline_requests_data' => 'export_workspace_tipline_newsletter_data',
        'export_workspace_tipline_newsletter_data' => 'export_workspace_item_data',
        'export_workspace_item_data' => nil,
      }
      if object.respond_to?(action)
        object.send(action, object.team)
        if next_action[action].nil?
          # Upload and send notification mail
          object.delay.upload_and_send_workspace_data(object.team)
        else
          CheckDataExportWorker.perform_in(1.second, object.id, next_action[action])
        end
      end
    end
  end
end
