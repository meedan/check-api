class ConvertTaskOptionsToArray < ActiveRecord::Migration[4.2]
  def change
    Team.all.find_each do |t|
      next if t.get_checklist.nil?
      t.get_checklist.each do |task|
        options = task[:options]
        if !options.nil? && options.is_a?(String)
          begin
            task[:options] = JSON.parse(task[:options])
          rescue Exception => e
            puts "Could not parse task options from team: #{t.inspect}: (#{e.message})"
          end
        end
      end
      t.save(validate: false)
    end
  end
end
