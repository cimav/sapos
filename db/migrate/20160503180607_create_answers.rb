class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.references :question
      t.references :protocol
      t.integer    :answer
      t.text       :comments
      t.timestamps
    end
  end
end
