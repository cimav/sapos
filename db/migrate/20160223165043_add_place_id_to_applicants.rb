class AddPlaceIdToApplicants < ActiveRecord::Migration
  def change
    add_column :applicants, :place_id, :integer
  end
end
