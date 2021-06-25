class CheckStateMachineReset < ActiveRecord::Migration[4.2]
  def change
    CheckStateMachine.redis.keys('check_state_machine:*:state').each{|k| CheckStateMachine.redis.del(k) }
  end
end
