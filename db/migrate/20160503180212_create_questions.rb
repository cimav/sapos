class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :group
      t.integer :question_type
      t.integer :order
      t.text    :question
      t.timestamps
    end
  end
end
