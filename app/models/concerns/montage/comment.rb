module Montage::Comment
  include Montage::Base

  def start_seconds=(seconds)
    self.fragment = "t=#{seconds}"
  end

  def start_seconds
    t = self.parsed_fragment['t']
    t ? t[0].to_f : 0.0
  end

  def comment_as_montage_comment_json
    video = self.annotated.extend(Montage::Video)
    user = self.annotator.extend(Montage::User)
    {
      id: self.id,
      created: self.created,
      modified: self.modified,
      start_seconds: self.start_seconds, 
      text: self.text,
      duration: video.duration,
      project_id: video.project_id,
      youtube_id: video.youtube_id,
      user: {
        id: user.id,
        email: user.email, 
        first_name: user.first_name,
        last_name: user.last_name,
        profile_img_url: user.profile_img_url
      } 
    }
  end
end 
