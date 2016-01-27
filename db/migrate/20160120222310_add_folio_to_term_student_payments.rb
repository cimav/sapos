class AddFolioToTermStudentPayments < ActiveRecord::Migration
  def change
    add_column :term_student_payments, :folio, :string
  end
end
