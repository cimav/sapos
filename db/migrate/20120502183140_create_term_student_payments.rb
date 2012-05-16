class CreateTermStudentPayments < ActiveRecord::Migration
  def self.up
    create_table :term_student_payments do |t|
       t.references :term_student
       t.decimal "amount"
       t.integer "status"
       t.timestamps 
    end
  end

  def self.down
    drop_table :term_student_payments
  end
end
