class AddInstitutionAndProgramKeyToPrograms < ActiveRecord::Migration
  def change
    add_column :programs, :institution_key, :string
    add_column :programs, :program_key, :string
  end
end
