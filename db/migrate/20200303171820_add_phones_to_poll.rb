class AddPhonesToPoll < ActiveRecord::Migration
  def change
  	add_column :graduated_poll2020s, :home_phone, :string
    add_column :graduated_poll2020s, :mobile_phone, :string
  	add_column :graduated_poll2020s, :work_phone, :string

  end
end
