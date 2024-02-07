require 'active_support/concern'

module SmoochBlocking
  extend ActiveSupport::Concern

  module ClassMethods
    def ban_user(message)
      unless message.nil?
        uid = message['authorId']
        self.block_user(uid)
      end
    end

    def block_user_from_error_code(uid, error_code)
      self.block_user(uid) if error_code == 131056 # Error of type "pair rate limit hit"
    end

    def block_user(uid)
      begin
        block = BlockedTiplineUser.new(uid: uid)
        block.skip_check_ability = true
        block.save!
        Rails.logger.info("[Smooch Bot] Blocked user #{uid}")
        Rails.cache.write("smooch:banned:#{uid}", Time.now.to_i)
      rescue ActiveRecord::RecordNotUnique
        # User already blocked
        Rails.logger.info("[Smooch Bot] User #{uid} already blocked")
      end
    end

    def unblock_user(uid)
      Rails.cache.delete("smooch:banned:#{uid}")
      blocked_user = BlockedTiplineUser.where(uid: uid).last
      blocked_user.destroy! unless blocked_user.nil?
      Rails.logger.info("[Smooch Bot] Unblocked user #{uid}")
    end

    def user_blocked?(uid)
      !uid.blank? && (!Rails.cache.read("smooch:banned:#{uid}").nil? || BlockedTiplineUser.where(uid: uid).exists?)
    end

    def user_banned?(payload)
      uid = payload.dig('appUser', '_id')
      self.user_blocked?(uid)
    end
  end
end
