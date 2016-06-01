Sapos::Application.routes.draw do
  get "scholarship_categories/index"

  root :to => 'welcome#index'

  match 'areas/busqueda' => 'areas#live_search'

  match 'egresados/busqueda' => 'graduates#live_search'
  match 'egresados/analizar/:student_id' => 'graduates#analizer'
  match 'egresados/nuevo/:id/:dialog' => 'graduates#new'
  match 'egresados/listo' => 'graduates#ready'

  match 'estudiantes/busqueda' => 'students#live_search'
  match 'estudiantes/:id/cambiar_foto' => 'students#change_image'
  match 'estudiantes/upload_image' => 'students#upload_image'
  match 'estudiantes/:id/archivos' => 'students#files'
  match 'estudiantes/:id/archivo/:file_id' => 'students#file'
  match 'estudiantes/upload_file' => 'students#upload_file'
  match 'estudiantes/delete_file' => 'students#delete_file'
  match 'estudiantes/:id/nuevo_avance' => 'students#new_advance'
  match 'estudiantes/create_advance' => 'students#create_advance'
  match 'estudiantes/asignar_numero_tesis' => 'students#assign_thesis_number'
  match 'estudiantes/:id/horario/:term_id' => 'students#schedule_table'
  match 'estudiantes/:id/credencial' => 'students#id_card'
  match 'estudiantes/:id/kardex' => 'students#kardex'
  match 'estudiantes/:id/boleta/:term_id' => 'students#term_grades'
  match 'estudiantes/lista' => 'students#term_grades_list'
  match 'estudiantes/avances' => 'students#advances_list'
  match 'estudiantes/constancias/:type/:id/:sign_id' => 'students#certificates'
  match 'estudiantes/constancias_grado/:thesis_id' => 'students#grade_certificates'
  match 'estudiantes/constancias_sinodales/:student_id/:staff_id' => 'students#sinodal_certificates'
  match 'estudiantes/diploma/:thesis_id' => 'students#diploma'
  #match 'estudiantes/constancia_total/:thesis_id' => 'students#total_studies_certificate'
  match 'estudiantes/constancia_total/:thesis_id' => 'certificates#total_studies_certificate'
  match 'estudiantes/:id/borrar' => 'students#destroy'
  match 'estudiantes/buscar' => 'students#student_exists'
  match 'estudiantes/:id/expediente' => 'students#record'
  match 'estudiantes/upload_one_file' => 'students#upload_one_file'
  match 'estudiantes/protocolo/:id/:staff_id' => 'students#get_protocol'

  match 'estudiantes/destroy_file/:id' => 'student_files#destroy_file'
  match 'estudiantes/file/:id' => 'student_files#download'

  match 'inscripciones' => 'students#enrollments_admin'
  match 'inscripciones/pagos' => 'students#payments'

  match 'estudiantes/archivos/avances/:id' => 'student_advances_file#index'

  match '/avances/borrar/:id' => 'student_advances_file#destroy'
  match '/avances/subir_archivo' => 'student_advances_file#upload_file'
  match '/avances/:id/file' => 'student_advances_file#file'

  resources :student_files
  resources :applicant_files

  match 'docentes/reporte' => 'staffs#report'
  match 'docentes/busqueda' => 'staffs#live_search'
  match 'docentes/:id/cambiar_foto' => 'staffs#change_image'
  match 'docentes/upload_image' => 'staffs#upload_image'
  match 'docentes/:id/seminarios' => 'staffs#seminars_table'
  match 'docentes/:id/nuevo_seminario' => 'staffs#new_seminar'
  match 'docentes/create_seminar' => 'staffs#create_seminar'
  match 'docentes/update_seminar' => 'staffs#update_seminar'
  match 'docentes/:id/seminario/:seminar_id' => 'staffs#edit_seminar'
  match 'docentes/:id/delete_seminar/:seminar_id' => 'staffs#delete_seminar'
  match 'docentes/:id/delete_external_course/:external_course_id' => 'staffs#delete_external_course'
  match 'docentes/:id/delete_lab_practice/:lab_practice_id' => 'staffs#delete_lab_practice'
  match 'docentes/:id/cursos-externos' => 'staffs#external_courses_table'
  match 'docentes/:id/nuevo_curso_externo' => 'staffs#new_external_course'
  match 'docentes/create_external_course' => 'staffs#create_external_course'
  match 'docentes/update_external_course' => 'staffs#update_external_course'
  match 'docentes/:id/curso-externo/:external_course_id' => 'staffs#edit_external_course'
  match 'docentes/:id/practicas-laboratorio' => 'staffs#lab_practices_table'
  match 'docentes/:id/nueva_practica_laboratorio' => 'staffs#new_lab_practice'
  match 'docentes/create_lab_practice' => 'staffs#create_lab_practice'
  match 'docentes/update_lab_practice' => 'staffs#update_lab_practice'
  match 'docentes/:id/practica-laboratorio/:lab_practice_id' => 'staffs#edit_lab_practice'
  match 'docentes/:id/estudiantes' => 'staffs#students'
  match 'docentes/horario/:id' => 'staffs#schedule_table'
  match 'docentes/:id/credencial' => 'staffs#id_card'
  match 'docentes/:id/archivos' => 'staffs#files'
  match 'docentes/:id/archivo/:file_id' => 'staffs#file'
  match 'docentes/upload_file' => 'staffs#upload_file'
  match 'docentes/delete_file' => 'staffs#delete_file'

  resources :staff_files

  match 'internados/busqueda' => 'internships#live_search'
  match 'internados/:id/cambiar_foto' => 'internships#change_image'
  match 'internados/upload_image' => 'internships#upload_image'
  match 'internados/:id/archivos' => 'internships#files'
  match 'internados/:id/archivo/:file_id' => 'internships#file'
  match 'internados/upload_file' => 'internships#upload_file'
  match 'internados/delete_file' => 'internships#delete_file'
  match 'internados/:id/credencial' => 'internships#id_card'
  match 'internados/constancias/:type/:id' => 'internships#certificates'
  match 'internados/aspirante' => 'internships#applicant_form'
  match 'internados/aspirante/area/:option' => 'internships#applicant_form'
  match 'internados/aspirante/crear' => 'internships#applicant_create'
  match 'internados/aspirante/:id/formato/:token' => 'internships#applicant_file'
  match 'internados/aspirantes/cita/:id/:staff_id' => 'internships#applicant_interview'

  resources :internship_files

  match 'instituciones/busqueda' => 'institutions#live_search'
  match 'instituciones/:id/cambiar_logo' => 'institutions#change_image'
  match 'instituciones/upload_image' => 'institutions#upload_image'


  match 'campus/busqueda' => 'campus#live_search'
  match 'campus/:id/cambiar_logo' => 'campus#change_image'
  match 'campus/upload_image' => 'campus#upload_image'

   match 'tipos_internados/busqueda' => 'internship_types#live_search'
   match 'departamentos/busqueda' => 'departments#live_search'

  match 'aulas/busqueda' => 'classrooms#live_search'
  match 'aulas/horario/:id' => 'classrooms#schedule_table'

  match 'becas/:id/nueva_beca' => 'scholarship#new'

  match 'becas/categorias/busqueda' => 'scholarship_categories#live_search'
  match 'becas/categorias/:id/tipos' => 'scholarship_categories#types_table'
  match 'becas/categorias/:id/nuevo_tipo' => 'scholarship_categories#new_type'
  match 'becas/categorias/create_type' => 'scholarship_categories#create_type'
  match 'becas/categorias/update_type' => 'scholarship_categories#update_type'
  match 'becas/categorias/:id/tipo/:scholarship_type_id' => 'scholarship_categories#edit_type'

  match 'laboratorios/busqueda' => 'laboratories#live_search'

  match 'usuarios/busqueda' => 'users#live_search'
  match 'usuarios/:id/permisos/:type' => 'users#permissions'

  match 'programas/busqueda' => 'programs#live_search'
  match 'programas/:id/:studies_plan_id/nuevo_curso' => 'programs#new_course'
  match 'programas/create_course' => 'programs#create_course'
  match 'programas/:id/:studies_plan_id/plan' => 'programs#plan_table'
  match 'programas/:id/curso/:course_id' => 'programs#edit_course'
  match 'programas/:id/periodos' => 'programs#terms_table'
  match 'programas/:id/nuevo_periodo' => 'programs#new_term'
  match 'programas/create_term' => 'programs#create_term'
  match 'programas/update_term' => 'programs#update_term'
  match 'programas/:id/periodo/:term_id' => 'programs#edit_term'
  match 'programas/:id/terms_dropdown' => 'programs#terms_dropdown'
  match 'programas/:id/periodo/:term_id/courses_dropdown' => 'programs#courses_dropdown'
  match 'programas/:id/periodo/:term_id/seleccionar_cursos' => 'programs#select_courses_for_term'
  match 'programas/:id/periodo/:term_id/:studies_plan_id/asignar_cursos' => 'programs#courses_assign'
  match 'programas/:id/periodo/:term_id/asignar_cursos_al_periodo' => 'programs#assign_courses_to_term'
  match 'programas/:id/periodo/:term_id/curso/:course_id/horario' => 'programs#schedule_table'
  match 'programas/:id/periodo/:term_id/curso/:course_id/horario/:group' => 'programs#schedule_table'
  match 'programas/:id/periodo/:term_id/curso/:course_id/nueva_sesion' => 'programs#new_schedule'
  match 'programas/:id/periodo/:term_id/curso/:course_id/nueva_sesion/:group' => 'programs#new_schedule'
  match 'programas/create_session' => 'programs#create_schedule'
  match 'programas/update_session' => 'programs#update_schedule'
  match 'programas/:id/periodo/:term_id/curso/:course_id/sesion/:term_course_schedule_id' => 'programs#edit_schedule'
  match 'programas/:id/periodo/:term_id/curso/:course_id/estudiantes' => 'programs#students_table'
  match 'programas/:id/periodo/:term_id/curso/:course_id/estudiantes/:group' => 'programs#students_table'
  match 'programas/:id/periodo/:term_id/curso/:course_id/agregar_estudiante' => 'programs#new_course_student'
  match 'programas/:id/periodo/:term_id/curso/:course_id/agregar_estudiante/:group' => 'programs#new_course_student'
  match 'programas/create_course_student' => 'programs#create_course_student'
  match 'programas/update_course_student' => 'programs#update_course_student'
  match 'programas/:id/periodo/:term_id/curso/:course_id/estudiante/:term_course_student_id' => 'programs#edit_course_student'
  match 'programas/:id/periodo/:term_id/curso/:course_id/estudiante/:term_course_student_id/desactivar' => 'programs#inactive_course_student'
  match 'programas/:id/periodo/:term_id/inscripciones' => 'programs#enrollment_table'
  match 'programas/:id/periodo/:term_id/nueva_inscripcion' => 'programs#new_enrollment'
  match 'programas/:id/create_enrollment' => 'programs#create_enrollment'
  match 'programas/:id/update_enrollment' => 'programs#update_enrollment'
  match 'programas/:id/periodo/:term_id/inscripcion/:term_student_id' => 'programs#edit_enrollment'
  match 'programas/:id/periodo/:term_id/curso/:course_id/asistencia' => 'programs#attendee_table'
  match 'programas/:id/periodo/:term_id/curso/:course_id/asistencia/:group' => 'programs#attendee_table'
  match 'programas/:id/periodo/:term_id/curso/:course_id/nuevo_grupo' => 'programs#new_group'
  match 'programas/:id/periodo/:term_id/curso/:course_id/documentacion/:group' => 'programs#documentation'
  match 'programas/create_group' => 'programs#create_group'
  match 'programas/:id/periodo/:term_id/curso/:course_id/groups_dropdown/:group' => 'programs#groups_dropdown'
  match 'programas/:id/periodo/:term_id/curso/:course_id/grupo/:group/cambiar_titular' => 'programs#update_staff_to_group'
  match 'programas/update_group' => 'programs#update_group'
  match 'programas/:id/documentos' => 'programs#files'
  match 'programas/upload_file' => 'programs#upload_file'
  match 'programas/delete_file' => 'programs#delete_file'
  match 'programas/:id/documentos/:file_id' => 'programs#file'

  match 'aspirantes/destroy_file/:id' => 'applicant_files#destroy'
  match 'aspirantes/file/:id' => 'applicant_files#download'

  match 'aspirantes/applicant_logout' => 'applicants#applicant_logout'
  match 'aspirantes/upload_file_register' => 'applicants#upload_file_register'
  match 'aspirantes/:id/archivos' => 'applicants#files'
  match 'aspirantes/:id/archivos/:register' => 'applicants#files'
  match 'aspirantes/archivos/registro' => 'applicants#files_register'
  match 'aspirantes/:id/upload_file' => 'applicants#upload_file'
  match 'aspirantes/descargar/solicitud/:applicant_id' => 'applicants#download_app_file'
  match 'aspirantes/busqueda' => 'applicants#live_search'
  match 'aspirantes/constancias/:type/:id' => 'applicants#certificates'
  match 'aspirantes/registro' => 'applicants#register'
  match 'aspirantes/registro/nuevo' => 'applicants#new_register'
  match 'aspirantes/registro/actualizar' => 'applicants#update_register'
  match 'aspirantes/registro/datos' => 'applicants#data'
  match 'aspirantes/registro/obtener/campus/:program_id' => 'applicants#get_campus'
  match 'aspirantes/registro/logout' => 'applicants#applicant_logout'

  #match 'planes_estudios/' => 'studies_plans#show'
  match 'planes_estudios/:program_id/nuevo' => 'studies_plans#new'
  match 'planes_estudios/crear' => 'studies_plans#create'
  match 'planes_estudios/:program_id/combo' => 'studies_plans#combo'
  match 'planes_estudios/:id' => 'studies_plans#show'
  match 'planes_estudios/editar/:id' => 'studies_plans#update'
  
  match 'reportes' => 'reports#index'
  
  match 'seminarios' => 'seminars#index'
  match 'seminarios/busqueda' => 'seminars#live_search'
  match 'seminarios/new' => 'seminars#new'
  match 'seminarios/crear' => 'seminars#create'
  match 'seminarios/editar/:id' => 'seminars#update'
  match 'avances/:id' => 'seminars#show'
  match 'seminarios/advance_data' => 'seminars#advance_data'

  match 'comite/busqueda' => 'committee_sessions#live_search'
  
  match 'comite/sesion/minuta/:s_id' => 'committee_sessions#memorandum'
  match 'comite/acuerdos/imprimir/:a_id/:s_id' => 'committee_sessions#document_agreement'
  match 'comite/sesion/asistencia/agregar/:cs_id/:st_id' => 'committee_sessions#add_attendee'
  match 'comite/sesion/asistencia/borrar/:csa_id' => 'committee_sessions#delete_attendee'
  match 'comite/sesion/asistencia/:id/:checked' => 'committee_sessions#roll_attendee'
  match 'comite/acuerdos/persona/borrar/:s_id' => 'committee_sessions#delete_person'
  match 'comite/acuerdos/texto/:a_id' => 'committee_sessions#save_text_agreement'
  match 'comite/acuerdos/borrar/:a_id' => 'committee_sessions#delete_agreement'
  match 'comite/acuerdos/:a_id/agregar/auth/:id' => 'committee_sessions#add_auth'
  match 'comite/acuerdos/:a_id/agregar/note/:note' => 'committee_sessions#add_note'
  match 'comite/acuerdos/:a_id/agregar/:person/:id' => 'committee_sessions#add_person'
  match 'comite/acuerdos/:s_id/:a_id' => 'committee_sessions#agreements'
  match 'comite/traer/cursos/:term' => 'committee_sessions#get_courses'
  match 'comite/revalidacion/cursos/:id' => 'committee_sessions#get_revalidation_courses'
  match 'comite/desbloquear/:id' => 'committee_sessions#unlock'

  resources :documentation_files

  match 'logs/show' => 'logs#index'

  scope(:path_names => { :new => "nuevo", :edit => "editar" }) do
    resources :students, :path => "estudiantes"
    resources :staffs, :path => "docentes"
    resources :internships, :path => "internados"
    resources :programs, :path => "programas"
    resources :institutions, :path => "instituciones"
    resources :campus, :path => "campus"
    resources :classrooms, :path => "aulas"
    resources :laboratories, :path => "laboratorios"
    resources :scholarship_categories, :path => "becas/categorias"
    resources :users, :path => "usuarios"
    resources :departments, :path => "departamentos"
    resources :internship_types, :path => "tipos_internados"
    resources :graduates, :path => "egresados"
    resources :scholarship, :path => "becas"
    resources :applicants, :path => "aspirantes"
    resources :areas, :path => "areas"
    resources :committee_sessions, :path => "comite"
    resources :committee_agreement_objects, :path => "objetos"
    resources :seminars, :path => "seminarios"
    resources :advances, :path => "avances"
    #resources :studies_plans, :path => "planes_estudios"
  end

  # API
  get '/api/estudiantes-activos/:email' => 'api#active_students', :constraints  => { :email => /[0-z\.\@]+/ }

  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match "/logout" => 'sessions#destroy'
  match '/login' => 'login#index'
end
