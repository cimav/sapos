class AddDefinitiveInactiveDateToStudents < ActiveRecord::Migration
  def up
    add_column :students, :definitive_inactive_date, :date
  end

  def down
    remove_column :students, :definitive_inactive_date
  end
end
