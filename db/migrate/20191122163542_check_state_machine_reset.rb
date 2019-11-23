class CheckStateMachineReset < ActiveRecord::Migration
  def change
    CheckStateMachine.redis.keys('check_state_machine:*:state').each{|k| CheckStateMachine.redis.del(k) }
  end
end
