class CreateAdmissionExams < ActiveRecord::Migration
  def change
    create_table :admission_exams do |t|
      t.boolean :make
      t.boolean :apply
      t.boolean :review
      t.date :exam_date
      t.references :staff
      t.integer :status

      t.timestamps
    end
    add_index :admission_exams, :staff_id
  end
end
