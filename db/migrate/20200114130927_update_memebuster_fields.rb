class UpdateMemebusterFields < ActiveRecord::Migration[4.2]
  def change
    ['memebuster_image', 'memebuster_headline', 'memebuster_body', 'memebuster_status', 'memebuster_overlay', 'memebuster_operation'].each do |name|
      fi = DynamicAnnotation::FieldInstance.where(name: name).last
      fi.optional = true
      fi.save!
    end
  end
end
