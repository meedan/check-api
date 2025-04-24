class CheckGraphql
  POOL = Concurrent::ThreadPoolExecutor.new(
    min_threads: 1,
    max_threads: 20,
    max_queue: 0 # unbounded work queue
  )

  class << self
    def id_from_object(obj, type, _ctx)
      return obj.id if obj.is_a?(CheckSearch)
      obj_type = obj.is_a?(OpenStruct) ? obj.type : type
      obj_type = obj.type if obj.is_a?(BotUser)
      Base64.encode64("#{obj_type}/#{obj.id}")
    end

    def decode_id(id)
      type, id = begin Base64.decode64(id).split('/') rescue [nil, nil] end
      type = 'BotUser' if type == 'Webhook'
      [type, id]
    end

    def object_from_id(id, ctx)
      type_name, id = self.decode_id(id)
      obj = nil
      return obj if type_name.blank?
      if type_name == 'About'
        name = Rails.application.class.module_parent_name
        obj = OpenStruct.new({ name: name, version: VERSION, id: 1, type: 'About' })
      elsif type_name == 'Me'
        obj = User.find_if_can(id)
      elsif ['Relationships', 'RelationshipsSource', 'RelationshipsTarget'].include?(type_name)
        obj = ProjectMedia.find_if_can(id)
      elsif type_name == 'CheckSearch'
        Team.find_if_can(Team.current&.id.to_i, ctx[:ability])
        obj = CheckSearch.new(id)
      else
        obj = type_name.constantize.find_if_can(id)
      end
      if type_name == 'TeamUser' && obj.class_name != 'TeamUser'
        obj = obj.becomes(TeamUser)
        obj.type = nil
        obj.instance_variable_set(:@new_record, false)
      end
      obj
    end
  end
end
