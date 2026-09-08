class CheckDataExportWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform(id)
    de = CheckDataExport.find_by_id(id)
    de.regenerate_download_url unless de.nil?
  end
end
