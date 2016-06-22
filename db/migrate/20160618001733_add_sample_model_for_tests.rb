class AddSampleModelForTests < ActiveRecord::Migration
  def change
    if Rails.env.test?
      create_table :sample_models do |t|
        t.string :test
        t.timestamps
      end
    end
  end
end
