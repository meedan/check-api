class SetArchiveLimits < ActiveRecord::Migration
  def change
    Team.all.each do |t|
      limits = t.limits || {}
      limits = limits.with_indifferent_access
      if limits[:keep_integration] == true
        limits = limits.merge({
          keep_archive_is: true,
          keep_screenshot: true,
          keep_video_vault: true,
          keep_archive_org: true
        })
      else
        limits = limits.merge({
          keep_archive_is: false,
          keep_screenshot: false,
          keep_video_vault: false,
          keep_archive_org: true
        })
      end
      t.limits = limits
      t.save(validate: false)
    end
  end
end
