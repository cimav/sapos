class CreateExstudents < ActiveRecord::Migration
  def change
    create_table :exstudents do |t|
      t.references :student
      t.string :phone
      t.string :cellphone
      t.string :email
      t.integer :scholarship_type
      t.string :subsequent_studies
      t.integer :sni
      t.boolean :academic_mobility
      t.string :academic_mobility_place
      t.boolean :have_job
      t.integer :job_type
      t.integer :job_legal_regime
      t.string :job_company_name
      t.string :job_role
      t.integer :salary
      t.string :job_chief_name
      t.string :job_phone
      t.string :job_email
      t.integer :job_coincidence
      t.integer :job_studies_impact
      t.string :job_studies_impact_reason
      t.string :recommendations
      t.integer :satisfaction_level
      t.string :satisfaction_reason
      t.boolean :study_program_again
      t.string :study_program_again_reason

      t.timestamps
    end
    add_index :exstudents, :student_id
  end
end
