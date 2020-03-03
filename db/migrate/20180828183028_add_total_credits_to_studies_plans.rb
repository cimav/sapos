class AddTotalCreditsToStudiesPlans < ActiveRecord::Migration
  def change
    add_column :studies_plans, :total_credits, :decimal, :precision => 8, :scale => 2
  end
end
