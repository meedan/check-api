class ConvertTaskAnswerNotesToComments < ActiveRecord::Migration
  def change
    field_names = ['note_free_text', 'note_yes_no', 'note_single_choice', 'note_multiple_choice', 'note_datetime']
    total = DynamicAnnotation::Field.where(field_name: field_names).count
    i = 0
    DynamicAnnotation::Field.where(field_name: field_names).find_each do |answer_note|
      i += 1
      puts "Migrating task answer #{i}/#{total}"
      answer = answer_note.annotation
      if !answer_note.value.blank? && 
        unless answer.nil?
          taskref = answer.get_fields.select{ |f| f.field_type == 'task_reference' }.last
          unless taskref.nil?
            task = Task.where(id: taskref.value.to_i).last
            unless task.nil?
              User.current = answer.annotator
              comment = Comment.new
              comment.annotation_type = 'comment'
              comment.text = answer_note.value
              comment.annotated = task
              comment.annotator = answer.annotator
              comment.created_at = answer.created_at
              comment.skip_check_ability = true
              comment.skip_notifications = true
              comment.save(validate: false)
              User.current = nil
            end
          end
        end
      end
      answer_note.destroy!
    end
  end
end
