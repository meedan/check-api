namespace :check do
  namespace :tipline do
    def parse_args(args)
      output = {}
      return output if args.blank?
      args.each do |a|
        arg = a.split('&')
        arg.each do |pair|
          key, value = pair.split(':')
          output.merge!({ key => value })
        end
      end
      output
    end

    # bundle exec rails check:tipline:get_user_uid['slug:team-slug&identifier:id']
    task get_user_uid: :environment do |_t, args|
      data_args = parse_args args.extras
      slug = data_args['slug']
      identifier = data_args['identifier']
      raise "You should pass team slug and user identifier" if slug.blank? || identifier.blank?
      team = Team.where(slug: slug).last
      raise "There is no team with slug [#{slug}]" if team.nil?
      result = DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_type: "smooch_user")
      .joins('INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id')
      .joins('INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id')
      .where('a.annotated_type = ? AND a.annotated_id = ?', "Team", team.id)
      uid_data = result.find{|f| f.value_json.dig('raw', 'clients', 0, 'displayName') == identifier }
      uid = uid_data.value_json.dig('id') unless uid_data.nil?
      puts "Tipline user id : \"#{uid}\""
    end

    # bundle exec rails check:tipline:delete_tipline_user['uid']
    task delete_tipline_user: :environment do |_t, args|
      uid = args.extras.last
      raise "You must pass user tipline id." if uid.blank?
      # Delete smooch_user annotation
      field = DynamicAnnotation::Field.where(field_name: "smooch_user_id", annotation_type: "smooch_user", value: uid).last
      team = nil
      unless field.nil?
        # update user id
        new_uid = "deleted-#{SecureRandom.hex}"
        puts "Updating smooch_user_id field :: #{field.id} with new id :: #{new_uid}"
        field.value = new_uid
        field.skip_check_ability = true
        field.save!
        # override existing cache field
        Rails.cache.delete("smooch:user:external_identifier:#{uid}")
        Rails.cache.write("smooch:user:external_identifier:#{new_uid}", 'deleted')
        annotation  = field.annotation.load
        team = annotation.annotated
        # Update smooch user data
        su_data = annotation.get_field('smooch_user_data')
        puts "Updating smooch_user_data field :: #{su_data.id}"
        value_json = su_data.value_json.with_indifferent_access
        value_json['id'] = new_uid
        value_json['raw']['_id'] = new_uid
        user_data = value_json['raw']['clients'][0].with_indifferent_access
        case user_data['platform']
        when 'whatsapp'
          user_data['displayName'] = 'deleted'
        when 'telegram'
          user_data['raw']['username'] = 'deleted'
        when 'messenger', 'viber', 'line'
          user_data['externalId'] = 'deleted'
        when 'twitter'
          user_data['raw']['screen_name'] = 'deleted'
        end
        value_json['raw']['clients'][0] = user_data
        su_data.value_json = value_json
        su_data.value = value_json.to_json
        su_data.skip_check_ability = true
        su_data.save!
        # Delete TiplineSubscription
        puts "Deleting TiplineSubscription ...."
        TiplineSubscription.where(uid: uid).destroy_all
        # Anonymize tipline requests: Replace authorID and other user ID fields (if any) by deleted in smooch_data annotation fields
        puts "Anonymize tipline requests ..."
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          ids = pms.map(&:id)
          a_pm = {}
          Annotation.where(annotation_type: "smooch", annotated_type: "ProjectMedia", annotated_id: ids).find_each do |a|
            print '.'
            a_pm[a.id] = a.annotated_id
          end
          updated_fields = []
          es_data = {}
          DynamicAnnotation::Field.where(field_name: 'smooch_data', annotation_type: 'smooch', annotation_id: a_pm.keys)
          .where("value_json ->> 'authorId' = ?", uid).find_each do |field|
            print '.'
            value_json = field.value_json
            value_json['name'] = 'deleted'
            value_json['authorId'] = new_uid
            field.value_json = value_json
            field.value = value_json.to_json
            updated_fields << field
            data = {
              'username' => 'deleted',
              'identifier' => new_uid,
              'content' => field.value_json['text']
            }
            options = { op: 'update', pm_id: a_pm[field.annotation_id], nested_key: 'requests', keys: data.keys, data: data, skip_get_data: true }
            field.add_update_nested_obj(options)
          end
          # Bulk update smooch_date
          DynamicAnnotation::Field.import(updated_fields, on_duplicate_key_update: [:value, :value_json, :updated_at], recursive: false, validate: false)
        end
      end
    end
  end
end