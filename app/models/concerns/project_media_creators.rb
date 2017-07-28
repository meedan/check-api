require 'active_support/concern'

module ProjectMediaCreators
  extend ActiveSupport::Concern

  private

  def create_auto_tasks
    tasks = self.project.nil? ? [] : self.project.auto_tasks
    created = []
    tasks.each do |task|
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
      created << t
    end
    self.respond_to_auto_tasks(created)
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
      src_lang = bot.language_object(self, :value)
      if !src_lang.blank? && bot.should_classify?(self.text)
        languages = self.project.get_languages
        unless languages.nil?
          annotation = Dynamic.new
          annotation.annotated = self
          annotation.annotator = bot
          annotation.annotation_type = 'mt'
          annotation.set_fields = {'mt_translations': [].to_json}.to_json
          annotation.save!
        end
      end
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

  def respond_to_auto_tasks(tasks)
    # set_tasks_responses = { task_slug (string) => response (string) }
    responses = self.set_tasks_responses.to_h
    tasks.each do |task|
      if responses.has_key?(task.slug)
        task = Task.find(task.id)
        type = "task_response_#{task.type}"
        fields = {
          "response_#{task.type}" => responses[task.slug],
          "note_#{task.type}" => '',
          "task_#{task.type}" => task.id.to_s
        }
        task.response = { annotation_type: type, set_fields: fields.to_json }.to_json
        task.save!
      end
    end
  end

  def create_project_source
    a = self.media.account
    unless a.nil?
      source = Account.create_for_source(a.url).source
      unless ProjectSource.where(project_id: self.project_id, source_id: source.id).exists?
        ps = ProjectSource.new
        ps.project_id = self.project_id
        ps.source_id = source.id
        ps.skip_check_ability = true
        ps.save!
      end
    end
  end
end
