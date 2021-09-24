class FixSmoochBotProfileImage < ActiveRecord::Migration[4.2]
  def change
    source = Source.where(name: 'Smooch').last
    source.update_column(:avatar, CheckConfig.get('checkdesk_base_url') + '/smooch.png') unless source.nil?
  end
end
