module Montage::Video
  include Montage::Base

  def duplicate_count
    ProjectMedia.where(media_id: self.media_id).count - 1
  end

  def youtube_api_data
    begin
      self.metadata['raw']['api'] || {}
    rescue
      {}
    end
  end

  def name
    self.title
  end

  def notes
    self.description
  end

  def pretty_created
    self.created_at.strftime("%b %d, %Y")
  end

  def pretty_publish_date
    begin
      DateTime.parse(self.publish_date).strftime("%b %d, %Y")
    rescue
      ""
    end
  end

  def publish_date
    data = self.youtube_api_data
    data['published_at']
  end

  def project_id
    self.project.team_id
  end

  def tag_count
    Tag.where(annotation_type: 'tag', annotated_type: 'ProjectMedia', annotated_id: self.id).count
  end

  def youtube_id
    self.metadata['external_id']
  end

  def channel_id
    self.youtube_api_data['channel_id']
  end

  def channel_name
    self.youtube_api_data['channel_title']
  end

  def duration
    self.youtube_api_data['duration'].to_i
  end

  def pretty_duration
    t = self.duration
    "%02d:%02d:%02d" % [t / 3600 % 24, t / 60 % 60, t % 60]
  end

  def project_media_as_montage_video_json
    {
      channel_id: self.channel_id,
      channel_name: self.channel_name,
      created: self.created,
      duplicate_count: self.duplicate_count,
      id: self.id,
      modified: self.modified,
      name: self.name,
      notes: self.notes,
      pretty_created: self.pretty_created,
      pretty_publish_date: self.pretty_publish_date,
      project_id: self.project_id,
      publish_date: self.publish_date,
      youtube_id: self.youtube_id,
      tag_count: self.tag_count,
      pretty_duration: self.pretty_duration,
      duration: self.duration,
      recorded_date_overridden: false, # FIXME: Implement this
      watch_count: 0, # FIXME: Implement this
      watched: false, # FIXME: Implement this
      precise_location: true, # FIXME: Implement this
      location_overridden: false, # FIXME: Implement this
      missing_from_youtube: false, # FIXME: Implement this
      favourited: false, # FIXME: Implement this
    }
  end
end

ProjectMedia.class_eval do
  def self.get_all_by_youtube_id(id, team_id)
    f = DynamicAnnotation::Field.find_in_json({ provider: 'youtube', external_id: id }).where(field_name: 'metadata_value').last
    ProjectMedia.joins(:project).where(media_id: f&.annotation&.annotated_id&.to_i).where('projects.team_id' => team_id)
  end

  def self.get_by_youtube_id(id, team_id)
    self.get_all_by_youtube_id(id, team_id).first
  end
end
