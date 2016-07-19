class RenameGradeToGradeStatusFromProtocols < ActiveRecord::Migration
  def change
    rename_column :protocols, :grade, :grade_status
  end
end
