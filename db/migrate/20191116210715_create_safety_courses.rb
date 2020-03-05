class CreateSafetyCourses < ActiveRecord::Migration
  def change
    create_table :safety_courses do |t|
      t.integer :safety_course_type
      t.string  :name
      t.string  :email
      t.integer :score_needed
      t.integer :score_obtained
      t.boolean :approved 
      t.integer :attachable_id
      t.string  :attachable_type
      
      t.timestamps
    end
    
  end
end
