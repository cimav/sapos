class CreateTermStudentMessages < ActiveRecord::Migration
  def change
    create_table :term_student_messages do |t|
      t.references :term_student
      t.text "message"
      t.timestamps 
    end
  end
end
