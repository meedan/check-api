class CheckDataExport < ApplicationRecord
  belongs_to :team
  belongs_to :user

  validates_presence_of :team_id, :user_id, :download_url
  validates_uniqueness_of :team_id

  validate :user_is_admin_member

  after_save :enqueue_regenerate_download_url, if: proc { |de| de.auto_extend_url_expiry && de.saved_change_to_generated_at? }

  def regenerate_download_url
    # 1. Extract the unique key from the download URL string
    download_url = self.download_url
    unique_key = File.basename(URI.parse(download_url).path)
    shortened_url = Shortener::ShortenedUrl.find_by(unique_key: unique_key)
    unless shortened_url.nil?
      max_s3_allowed_days = CheckConfig.get('check_sunset_s3_max_expire_days', 7, :integer)
      expired_at = self.expired_at
      current_time = Time.current
      # Get days diff to determine if we still need to schedule another job to regenerate S3 URL
      days_diff = (expired_at.to_date - current_time.to_date).to_i
      # Regenerate S3 URL
      s3_url = CheckS3.presigned_url(self.s3_key,[max_s3_allowed_days, days_diff].min.days.to_i, CheckConfig.get('check_sunset_s3_bucket'))
      # Update target url in Shortener::ShortenedUrl
      shortened_url.update_column(:url, s3_url)
      self.generated_at = current_time
      self.auto_extend_url_expiry = days_diff > max_s3_allowed_days
      self.skip_check_ability = true
      begin self.save! rescue Rails.logger.info "[CheckDataExport] Unable to regenerate download URL for workspace #{self.team.slug} [ID: #{self.id}]" end
    end
  end

  private

  def user_is_admin_member
    if self.team && self.user
      errors.add(:user_id, I18n.t(:"errors.messages.check_export_data_user_must_be_admin_member")) unless self.team.team_users.where(user_id: self.user.id, role: 'admin', status: 'member').exists?
    end
  end

  def enqueue_regenerate_download_url
    # Schedule regenerate S3 URL to run before existing URL expires
    CheckDataExportWorker.perform_in(CheckConfig.get('check_sunset_s3_max_expire_days', 7, :integer).days, self.id)
  end
end
