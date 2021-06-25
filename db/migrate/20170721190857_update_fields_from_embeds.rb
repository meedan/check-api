class UpdateFieldsFromEmbeds < ActiveRecord::Migration[4.2]

  def change
    @n = 0
    return unless defined?(Embed)
    Embed.where(annotation_type: 'embed').find_each do |e|
      embed = JSON.parse(e.embed)
      e.skip_notifications = true
      case embed['provider']
      when 'bridge', 'youtube', 'page'
        self.fix_author_name(e, embed)
      when 'facebook'
        self.fix_author_name(e, embed, embed['user_name'])
      when 'instagram'
        self.fix_author_name_and_username(e, embed)
      when 'twitter'
        embed['user'].blank? ? self.fix_author_name_and_username(e, embed) : self.fix_author_name_and_username(e, embed, embed['user']['name'])
      end
    end
    puts "Migration is finished! #{@n} items were changed"
  end

  def fix_author_name(e, embed, value = '')
    data = self.fill_in_author_name(embed, value = '')
    unless data.nil?
      e.embed = data.to_json
      e.save!
    end
  end

  def fix_author_name_and_username(e, embed, value = '')
    fixed_author = self.fill_in_author_name(embed, value = '')
    if fixed_author.nil?
      data = self.fix_username(embed)
    else
      data = self.fix_username(fixed_author)
    end
    e.username = data['username']
    e.embed = data.to_json
    e.save!
  end

  def fill_in_author_name(embed, value = '')
    return unless embed['author_name'].blank?
    embed['author_name'] = if value.blank?
                             embed['username'].blank? ? '' : embed['username'].gsub(/^@/, '')
                           else
                             value
                           end
    @n += 1
    embed
  end

  def fix_username(embed)
    return embed if embed['username'].blank? || embed['username'].starts_with?('@')
    embed['username'] = '@' + embed['username']
    @n += 1
    embed
  end
end
