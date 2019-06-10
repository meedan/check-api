class AddCustomMessagesSettingsToSmoochBot < ActiveRecord::Migration
  def change
    tb = TeamBot.where(identifier: 'smooch').last
    unless tb.nil?
      settings = tb.settings.clone
      {
        'smooch_bot_result' => 'Message sent with the verification results (placeholders: %{status} (final status of the report) and %{url} (public URL to verification results))',
        'smooch_bot_result_changed' => 'Message sent with the new verification results when a final status of an item changes (placeholders: %{previous_status} (previous final status of the report), %{status} (new final status of the report) and %{url} (public URL to verification results))',
        'smooch_bot_ask_for_confirmation' => 'Message that asks the user to confirm the request to verify an item... should mention that the user needs to sent "1" to confirm',
        'smooch_bot_message_confirmed' => 'Message that confirms to the user that the request is in the queue to be verified',
        'smooch_bot_message_type_unsupported' => 'Message that informs the user that the type of message is not supported (for example, audio and video)',
        'smooch_bot_message_unconfirmed' => 'Message sent when the user does not send "1" to confirm a request',
        'smooch_bot_not_final' => 'Message when an item was wrongly marked as final, but that status is reverted (placeholder: %{status} (previous final status))',
        'smooch_bot_meme' => 'Message sent along with a meme (placeholder: %{url} (public URL to verification results))',
      }.each do |name, label|
        settings << { name: "smooch_message_#{name}", label: label, type: 'string', default: '' }
      end
      tb.settings = settings
      tb.save!
    end
  end
end
