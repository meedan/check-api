class FixSmoochBotProfileImage < ActiveRecord::Migration
  def change
    source = Source.where(name: 'Smooch').last
    source.update_column(:avatar, CONFIG['checkdesk_base_url'] + '/smooch.png') unless source.nil?
  end
end
