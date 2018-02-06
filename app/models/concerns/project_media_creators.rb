require 'active_support/concern'

module ProjectMediaCreators
  extend ActiveSupport::Concern

  def set_initial_media_status
    st = Status.new
    st.annotated = self
    st.annotator = self.user
    st.status = Status.default_id(self.media, self.project)
    st.created_at = self.created_at
    st.disable_es_callbacks = self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    st.skip_check_ability = true
    st.skip_notifications = true
    st.save!
  end

  def add_elasticsearch_data
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    p = self.project
    m = self.media
    ms = MediaSearch.new
    ms.id = self.id
    ms.team_id = p.team.id
    ms.project_id = p.id
    ms.associated_type = self.media.type
    ms.set_es_annotated(self)
    ms.status = self.last_status unless CONFIG['app_name'] === 'Bridge'
    data = self.embed
    unless data.nil?
      ms.title = data['title']
      ms.description = data['description']
      ms.quote = m.quote
    end
    ms.account = self.set_es_account_data unless self.media.account.nil?
    ms.save!
  end

  private

  def set_project_source
    self.create_project_source
  end

  def create_auto_tasks
    self.set_tasks_responses ||= {}
    tasks = self.project.nil? ? [] : self.project.auto_tasks
    created = []
    tasks.each do |task|
      t = Task.new
      t.label = task['label']
      t.type = task['type']
      t.required = (task['required'] == "1") ? true : false
      t.description = task['description']
      t.jsonoptions = task['options'] unless task['options'].blank?
      t.annotator = User.current
      t.annotated = self
      t.skip_check_ability = true
      t.skip_notifications = true
      t.save!
      created << t
      # set auto-response
      self.set_jsonld_response(task) if task.has_key?('mapping')
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
      d.disable_es_callbacks = Rails.env.to_s == 'test'
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
      response.disable_es_callbacks = Rails.env.to_s == 'test'
      response.skip_notifications = true
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
    m.quote_attributions = self.quote_attributions
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

  def set_jsonld_response(task)
    jsonld = self.embed['raw']['json+ld'] if self.embed.has_key?('raw')
    unless jsonld.nil?
      value = self.get_response_value(jsonld, task)
      self.set_tasks_responses[Task.slug(task['label'])] = value unless value.blank?
    end
  end

  def get_response_value(jsonld, task)
    require 'jsonpath'
    mapping = task['mapping']
    self.mapping_suggestions(task, mapping['type']).each do |name|
      return self.send(name, jsonld, mapping) if self.respond_to?(name)
    end
    data = mapping_value(jsonld, mapping)
    (!data.blank? && data.kind_of?(String)) ? mapping['prefix'].gsub(/\s+$/, '') + ' ' + data : ''
  end

  def mapping_value(jsonld, mapping)
    begin
      value = JsonPath.new(mapping['match']).first(jsonld)
    rescue
      value = nil
    end
    value
  end

  def mapping_suggestions(task, mapping_type)
    [
      "mapping_#{Task.slug(task['label'])}",
      "mapping_#{task['type']}_#{mapping_type}",
      "mapping_#{task['type']}",
    ]
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
    source = Account.create_for_source(a.url, nil, false, self.disable_es_callbacks).source unless a.nil?
    if source.nil?
      cs = ClaimSource.where(media_id: self.media_id).last
      source = cs.source unless cs.nil?
    end
    unless source.nil?
      unless ProjectSource.where(project_id: self.project_id, source_id: source.id).exists?
        ps = ProjectSource.new
        ps.project_id = self.project_id
        ps.source_id = source.id
        ps.disable_es_callbacks = self.disable_es_callbacks
        ps.skip_check_ability = true
        ps.save!
      end
    end
  end
end
