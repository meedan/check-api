require 'active_support/concern'

module ProjectMediaCreators
  extend ActiveSupport::Concern

  private

  def create_auto_tasks
    if self.should_create_auto_tasks?
      self.project.team.get_checklist.each do |task|
        if task['projects'].blank? || task['projects'].empty? || task['projects'].include?(self.project.id)
          t = Task.new
          t.label = task['label']
          t.type = task['type']
          t.description = task['description']
          t.jsonoptions = task['options'] unless task['options'].blank?
          t.annotator = User.current
          t.annotated = self
          t.skip_check_ability = true
          t.skip_notifications = true
          t.save!
        end
      end
    end
  end

  def create_reverse_image_annotation
    picture = self.media.picture
    unless picture.blank?
      d = Dynamic.new
      d.skip_check_ability = true
      d.skip_notifications = true
      d.annotation_type = 'reverse_image'
      d.annotator = Bot::Bot.where(name: 'Check Bot').last
      d.annotated = self
      d.set_fields = { reverse_image_path: picture }.to_json
      d.save!
    end
  end

  def create_annotation
    unless self.set_annotation.blank?
      params = JSON.parse(self.set_annotation)
      response = Dynamic.new
      response.annotated = self
      response.annotation_type = params['annotation_type']
      response.set_fields = params['set_fields']
      response.save!
    end
  end

  def create_mt_annotation
    bot = Bot::Alegre.default
    unless bot.nil?
      MachineTranslationWorker.perform_in(1.second, YAML::dump(self), YAML::dump(bot)) if bot.should_classify?(self.text)
    end
  end

  protected

  def create_image
    m = UploadedImage.new
    m.file = self.file
    m.save!
    m
  end

  def create_claim
    m = Claim.new
    m.quote = self.quote
    m.save!
    m
  end

  def create_link
    m = Link.new
    m.url = self.url
    # call m.valid? to get normalized URL before caling 'find_or_create_by'
    m.valid?
    m = Link.find_or_create_by(url: m.url)
    m
  end

  def create_media
    m = nil
    if !self.file.blank?
      m = self.create_image
    elsif !self.quote.blank?
      m = self.create_claim
    else
      m = self.create_link
    end
    m
  end
end
