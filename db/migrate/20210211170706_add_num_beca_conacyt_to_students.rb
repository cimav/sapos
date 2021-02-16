class AddNumBecaConacytToStudents < ActiveRecord::Migration
  def change
    add_column :students, :num_beca_conacyt, :string
  end
end
