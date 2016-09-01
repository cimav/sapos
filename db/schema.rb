# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160830200532) do

  create_table "academic_degrees", :force => true do |t|
    t.integer  "student_id"
    t.string   "year",           :limit => 4
    t.string   "name"
    t.integer  "institution_id"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "academic_degrees", ["institution_id"], :name => "index_academic_degrees_on_institution_id"
  add_index "academic_degrees", ["student_id"], :name => "index_academic_degrees_on_student_id"

  create_table "activity_logs", :force => true do |t|
    t.integer  "user_id"
    t.text     "activity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "advances", :force => true do |t|
    t.integer  "student_id"
    t.text     "title"
    t.datetime "advance_date"
    t.integer  "tutor1"
    t.integer  "tutor2"
    t.integer  "tutor3"
    t.integer  "tutor4"
    t.integer  "tutor5"
    t.string   "status",        :limit => 1
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "grade1"
    t.integer  "grade2"
    t.integer  "grade3"
    t.integer  "grade4"
    t.integer  "grade5"
    t.integer  "grade1_status"
    t.integer  "grade2_status"
    t.integer  "grade3_status"
    t.integer  "grade4_status"
    t.integer  "grade5_status"
    t.integer  "advance_type"
  end

  add_index "advances", ["student_id"], :name => "index_advances_on_student_id"
  add_index "advances", ["tutor1"], :name => "index_advances_on_tutor1"
  add_index "advances", ["tutor2"], :name => "index_advances_on_tutor2"
  add_index "advances", ["tutor3"], :name => "index_advances_on_tutor3"
  add_index "advances", ["tutor4"], :name => "index_advances_on_tutor4"
  add_index "advances", ["tutor5"], :name => "index_advances_on_tutor5"

  create_table "answers", :force => true do |t|
    t.integer  "question_id"
    t.integer  "protocol_id"
    t.integer  "answer"
    t.text     "comments"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "applicant_files", :force => true do |t|
    t.integer "applicant_id"
    t.integer "file_type"
    t.string  "description"
    t.string  "file"
  end

  add_index "applicant_files", ["applicant_id"], :name => "index_applicant_files_on_applicant_id"

  create_table "applicants", :force => true do |t|
    t.integer  "program_id"
    t.string   "folio"
    t.string   "first_name"
    t.string   "primary_last_name"
    t.string   "second_last_name"
    t.integer  "previous_institution"
    t.string   "previous_degree_type"
    t.string   "average"
    t.date     "date_of_birth"
    t.string   "phone"
    t.string   "cell_phone"
    t.string   "email"
    t.string   "address"
    t.integer  "civil_status"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "status"
    t.integer  "consecutive"
    t.integer  "staff_id"
    t.text     "notes"
    t.integer  "campus_id"
    t.integer  "student_id"
    t.integer  "place_id"
    t.string   "password"
  end

  create_table "areas", :force => true do |t|
    t.string   "name",       :limit => 100, :null => false
    t.integer  "area_type",                 :null => false
    t.string   "leader",     :limit => 100
    t.string   "position"
    t.text     "notes"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "campus", :force => true do |t|
    t.string   "short_name", :limit => 20
    t.string   "name"
    t.integer  "contact_id"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "certificates", :force => true do |t|
    t.integer  "consecutive"
    t.integer  "year"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.integer  "type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "classrooms", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "room_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
  end

  create_table "committee_agreement_files", :force => true do |t|
    t.integer  "committee_agreement_id"
    t.string   "description"
    t.string   "file"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "committee_agreement_files", ["committee_agreement_id"], :name => "index_committee_agreement_files_on_committee_agreement_id"

  create_table "committee_agreement_notes", :force => true do |t|
    t.integer  "committee_agreement_id"
    t.text     "notes"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "committee_agreement_objects", :force => true do |t|
    t.integer  "committee_agreement_id"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.text     "aux"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "committee_agreement_objects", ["committee_agreement_id"], :name => "index_committee_agreement_objects_on_committee_agreement_id"

  create_table "committee_agreement_people", :force => true do |t|
    t.integer  "committee_agreement_id"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.integer  "aux"
  end

  add_index "committee_agreement_people", ["committee_agreement_id"], :name => "index_committee_agreement_people_on_committee_agreement_id"

  create_table "committee_agreement_types", :force => true do |t|
    t.string   "description"
    t.integer  "authorization"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "committee_agreements", :force => true do |t|
    t.integer  "committee_agreement_type_id"
    t.integer  "committee_session_id"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.text     "notes"
    t.string   "auth"
  end

  create_table "committee_session_attendees", :force => true do |t|
    t.integer  "committee_session_id"
    t.integer  "staff_id"
    t.integer  "department_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.boolean  "checked",              :default => false
  end

  create_table "committee_sessions", :force => true do |t|
    t.integer  "session_type"
    t.integer  "status"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.datetime "date"
    t.datetime "end_session"
  end

  create_table "contacts", :force => true do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.integer  "state_id"
    t.string   "zip",             :limit => 20
    t.integer  "country_id"
    t.string   "mobile_phone",    :limit => 20
    t.string   "home_phone",      :limit => 20
    t.string   "work_phone",      :limit => 20
    t.string   "website"
    t.string   "lat",             :limit => 20
    t.string   "long",            :limit => 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contacts", ["country_id"], :name => "index_contacts_on_country_id"
  add_index "contacts", ["state_id"], :name => "index_contacts_on_state_id"

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", :force => true do |t|
    t.integer  "program_id"
    t.string   "code",            :limit => 10
    t.string   "name"
    t.decimal  "lecture_hours",                 :precision => 8, :scale => 2
    t.decimal  "lab_hours",                     :precision => 8, :scale => 2
    t.decimal  "credits",                       :precision => 8, :scale => 2
    t.text     "description"
    t.integer  "term",                                                        :default => 1
    t.integer  "prereq1"
    t.integer  "prereq2"
    t.integer  "prereq3"
    t.integer  "coreq1"
    t.integer  "coreq2"
    t.integer  "coreq3"
    t.text     "notes"
    t.integer  "status",                                                      :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "studies_plan_id"
  end

  add_index "courses", ["program_id"], :name => "index_courses_on_program_id"

  create_table "departments", :force => true do |t|
    t.string   "name",        :limit => 100, :null => false
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documentation_files", :force => true do |t|
    t.integer  "program_id"
    t.string   "description"
    t.string   "file"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "documentation_files", ["program_id"], :name => "index_documentation_files_on_program_id"

  create_table "emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.string   "subject"
    t.text     "content"
    t.integer  "status",     :default => 0
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "external_courses", :force => true do |t|
    t.integer  "staff_id"
    t.integer  "institution_id"
    t.text     "title"
    t.string   "location"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "hours"
    t.string   "participants"
    t.text     "information"
    t.string   "status",         :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "external_courses", ["institution_id"], :name => "index_external_courses_on_institution_id"
  add_index "external_courses", ["staff_id"], :name => "index_external_courses_on_staff_id"

  create_table "grades_logs", :force => true do |t|
    t.integer  "staff_id"
    t.integer  "term_course_student_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "graduates", :force => true do |t|
    t.integer  "student_id"
    t.string   "workplace",          :limit => 100
    t.integer  "income"
    t.integer  "gyre"
    t.text     "prizes"
    t.string   "sni",                :limit => 20
    t.integer  "sni_status"
    t.text     "subsequent_studies"
    t.date     "period_from"
    t.date     "period_to"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.text     "notes"
    t.string   "email"
    t.string   "phone"
  end

  add_index "graduates", ["student_id"], :name => "index_graduates_on_student_id"

  create_table "institutions", :force => true do |t|
    t.string   "short_name", :limit => 20
    t.string   "name"
    t.integer  "contact_id"
    t.string   "image"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "internship_files", :force => true do |t|
    t.integer  "internship_id"
    t.string   "description"
    t.string   "file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "file_type"
  end

  add_index "internship_files", ["internship_id"], :name => "index_internship_files_on_internship_id"

  create_table "internship_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "internships", :force => true do |t|
    t.integer  "internship_type_id"
    t.string   "first_name",              :limit => 50,                 :null => false
    t.string   "last_name",               :limit => 50,                 :null => false
    t.string   "gender",                  :limit => 1
    t.date     "date_of_birth"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "location"
    t.string   "email"
    t.integer  "institution_id"
    t.integer  "contact_id"
    t.integer  "staff_id"
    t.string   "thesis_title"
    t.text     "activities"
    t.integer  "status",                                 :default => 0
    t.string   "image"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "blood_type"
    t.integer  "campus_id"
    t.string   "career"
    t.string   "office"
    t.integer  "total_hours"
    t.string   "schedule"
    t.string   "control_number"
    t.integer  "grade"
    t.integer  "applicant_status"
    t.integer  "area_id"
    t.integer  "country_id"
    t.integer  "state_id"
    t.string   "phone",                   :limit => 20
    t.string   "health_insurance",        :limit => 150
    t.string   "health_insurance_number", :limit => 50
    t.string   "accident_contact"
    t.string   "password"
  end

  add_index "internships", ["contact_id"], :name => "index_internships_on_contact_id"
  add_index "internships", ["institution_id"], :name => "index_internships_on_institution_id"
  add_index "internships", ["internship_type_id"], :name => "index_internships_on_internship_type_id"
  add_index "internships", ["staff_id"], :name => "index_internships_on_staff_id"

  create_table "lab_practices", :force => true do |t|
    t.integer  "staff_id"
    t.integer  "laboratory_id"
    t.integer  "institution_id"
    t.text     "title"
    t.string   "location"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "hours"
    t.string   "participants"
    t.text     "information"
    t.string   "status",         :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lab_practices", ["institution_id"], :name => "index_lab_practices_on_institution_id"
  add_index "lab_practices", ["laboratory_id"], :name => "index_lab_practices_on_laboratory_id"
  add_index "lab_practices", ["staff_id"], :name => "index_lab_practices_on_staff_id"

  create_table "laboratories", :force => true do |t|
    t.integer  "campus_id"
    t.string   "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "laboratories", ["campus_id"], :name => "index_laboratories_on_campus_id"

  create_table "permission_users", :force => true do |t|
    t.integer  "user_id"
    t.integer  "program_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "programs", :force => true do |t|
    t.string   "name"
    t.string   "level",          :limit => 20
    t.string   "prefix",         :limit => 5
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "terms_duration"
    t.integer  "terms_qty"
    t.integer  "program_type"
  end

  create_table "protocols", :force => true do |t|
    t.integer  "advance_id"
    t.integer  "staff_id"
    t.integer  "group"
    t.integer  "grade_status"
    t.integer  "status"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.decimal  "grade",        :precision => 8, :scale => 2
  end

  create_table "questions", :force => true do |t|
    t.integer  "group"
    t.integer  "question_type"
    t.integer  "order"
    t.text     "question"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "scholarship_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scholarship_types", :force => true do |t|
    t.integer  "scholarship_category_id"
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scholarship_types", ["scholarship_category_id"], :name => "index_scholarship_types_on_scholarship_category_id"

  create_table "scholarships", :force => true do |t|
    t.integer  "student_id"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "status"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "scholarship_type_id"
    t.string   "amount"
    t.integer  "institution_id"
    t.integer  "department_id"
    t.string   "other_department"
  end

  add_index "scholarships", ["student_id"], :name => "index_scholarships_on_student_id"

  create_table "seminars", :force => true do |t|
    t.integer  "staff_id"
    t.text     "title"
    t.string   "category"
    t.string   "location"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "information"
    t.string   "status",      :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seminars", ["staff_id"], :name => "index_seminars_on_staff_id"

  create_table "staff_files", :force => true do |t|
    t.integer  "staff_id"
    t.string   "description"
    t.string   "file"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "staff_files", ["staff_id"], :name => "index_staff_files_on_staff_id"

  create_table "staffs", :force => true do |t|
    t.integer  "employee_number"
    t.string   "title",           :limit => 10
    t.string   "first_name",      :limit => 50,                  :null => false
    t.string   "last_name",       :limit => 50,                  :null => false
    t.string   "gender",          :limit => 1
    t.date     "date_of_birth"
    t.string   "location"
    t.string   "email"
    t.integer  "institution_id"
    t.integer  "contact_id"
    t.string   "cvu"
    t.string   "sni",             :limit => 20
    t.string   "status",          :limit => 20, :default => "0"
    t.string   "image"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "area_id"
  end

  create_table "stances", :force => true do |t|
    t.integer  "student_id"
    t.integer  "institution_id"
    t.date     "start_date"
    t.date     "end_date"
    t.string   "agreement"
    t.string   "status"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stances", ["institution_id"], :name => "index_stances_on_institution_id"
  add_index "stances", ["student_id"], :name => "index_stances_on_student_id"

  create_table "states", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_advances_file_messages", :force => true do |t|
    t.integer  "student_advances_file_id"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.text     "message"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "student_advances_files", :force => true do |t|
    t.integer  "term_student_id"
    t.integer  "student_advance_type"
    t.string   "description"
    t.string   "file"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "student_files", :force => true do |t|
    t.integer  "student_id"
    t.string   "description"
    t.string   "file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "file_type"
  end

  add_index "student_files", ["student_id"], :name => "index_student_files_on_student_id"

  create_table "students", :force => true do |t|
    t.integer  "program_id"
    t.string   "card",                 :limit => 20
    t.string   "previous_card",        :limit => 20
    t.integer  "consecutive"
    t.string   "first_name",           :limit => 50,                :null => false
    t.string   "last_name",            :limit => 50,                :null => false
    t.string   "gender",               :limit => 1
    t.date     "date_of_birth"
    t.string   "city"
    t.integer  "state_id"
    t.integer  "country_id"
    t.string   "email"
    t.integer  "previous_institution"
    t.string   "previous_degree_type"
    t.string   "previous_degree_desc"
    t.date     "previous_degree_date"
    t.integer  "contact_id"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "graduation_date"
    t.date     "inactive_date"
    t.integer  "supervisor"
    t.integer  "co_supervisor"
    t.integer  "department_id"
    t.string   "curp"
    t.string   "ife"
    t.string   "cvu"
    t.string   "location"
    t.string   "ssn"
    t.string   "blood_type"
    t.string   "accident_contact"
    t.string   "accident_phone"
    t.string   "passport"
    t.string   "image"
    t.integer  "status",                             :default => 1
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "campus_id"
    t.string   "email_cimav"
    t.string   "domain_password"
    t.integer  "deleted",                            :default => 0
    t.datetime "deleted_at"
    t.integer  "studies_plan_id"
    t.integer  "external_supervisor"
  end

  add_index "students", ["campus_id"], :name => "index_students_on_campus_id"
  add_index "students", ["card"], :name => "index_students_on_card"
  add_index "students", ["co_supervisor"], :name => "index_students_on_co_supervisor"
  add_index "students", ["contact_id"], :name => "index_students_on_contact_id"
  add_index "students", ["country_id"], :name => "index_students_on_country_id"
  add_index "students", ["department_id"], :name => "index_students_on_department_id"
  add_index "students", ["program_id"], :name => "index_students_on_program_id"
  add_index "students", ["supervisor"], :name => "index_students_on_supervisor"

  create_table "studies_plans", :force => true do |t|
    t.integer  "program_id"
    t.string   "code",       :limit => 20,                   :null => false
    t.string   "name",       :limit => 100
    t.text     "notes"
    t.string   "status",     :limit => 20,  :default => "0"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  add_index "studies_plans", ["program_id"], :name => "index_studies_plans_on_program_id"

  create_table "term_course_schedules", :force => true do |t|
    t.integer  "term_course_id"
    t.integer  "day"
    t.time     "start_hour"
    t.time     "end_hour"
    t.integer  "classroom_id"
    t.integer  "staff_id"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "class_type"
    t.integer  "status",         :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_course_schedules", ["classroom_id"], :name => "index_term_course_schedules_on_classroom_id"
  add_index "term_course_schedules", ["staff_id"], :name => "index_term_course_schedules_on_staff_id"
  add_index "term_course_schedules", ["term_course_id"], :name => "index_term_course_schedules_on_term_course_id"

  create_table "term_course_students", :force => true do |t|
    t.integer  "term_course_id"
    t.integer  "term_student_id"
    t.integer  "grade"
    t.integer  "status",          :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_course_students", ["term_course_id"], :name => "index_term_course_students_on_term_course_id"
  add_index "term_course_students", ["term_student_id"], :name => "index_term_course_students_on_term_student_id"

  create_table "term_courses", :force => true do |t|
    t.integer  "term_id"
    t.integer  "course_id"
    t.integer  "status",     :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "staff_id"
    t.string   "group"
  end

  add_index "term_courses", ["course_id"], :name => "index_term_courses_on_course_id"
  add_index "term_courses", ["staff_id"], :name => "index_term_courses_on_staff_id"
  add_index "term_courses", ["term_id"], :name => "index_term_courses_on_term_id"

  create_table "term_student_messages", :force => true do |t|
    t.integer  "term_student_id"
    t.text     "message"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "term_student_payments", :force => true do |t|
    t.integer  "term_student_id"
    t.decimal  "amount",          :precision => 10, :scale => 0
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "folio"
  end

  create_table "term_students", :force => true do |t|
    t.integer  "term_id"
    t.integer  "student_id"
    t.string   "notes"
    t.integer  "status",     :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "term_students", ["student_id"], :name => "index_term_students_on_student_id"
  add_index "term_students", ["term_id"], :name => "index_term_students_on_term_id"

  create_table "terms", :force => true do |t|
    t.integer  "program_id"
    t.string   "code",               :limit => 10
    t.string   "name",               :limit => 80
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "status",                           :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "advance_start_date"
    t.date     "advance_end_date"
    t.date     "grade_start_date"
    t.date     "grade_end_date"
  end

  add_index "terms", ["program_id"], :name => "index_terms_on_program_id"

  create_table "theses", :force => true do |t|
    t.integer  "student_id"
    t.string   "number",       :limit => 20
    t.integer  "consecutive"
    t.text     "title"
    t.text     "abstract"
    t.datetime "defence_date"
    t.integer  "examiner1"
    t.integer  "examiner2"
    t.integer  "examiner3"
    t.integer  "examiner4"
    t.integer  "examiner5"
    t.string   "status",       :limit => 1
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "theses", ["examiner1"], :name => "index_theses_on_examiner1"
  add_index "theses", ["examiner2"], :name => "index_theses_on_examiner2"
  add_index "theses", ["examiner3"], :name => "index_theses_on_examiner3"
  add_index "theses", ["examiner4"], :name => "index_theses_on_examiner4"
  add_index "theses", ["examiner5"], :name => "index_theses_on_examiner5"
  add_index "theses", ["student_id"], :name => "index_theses_on_student_id"

  create_table "tokens", :force => true do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "token"
    t.datetime "expires"
    t.integer  "status"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.integer  "access",                      :default => 2
    t.integer  "status",                      :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "program_id"
    t.integer  "campus_id"
    t.integer  "program_type"
    t.string   "areas",        :limit => 150
    t.text     "config"
  end

end
