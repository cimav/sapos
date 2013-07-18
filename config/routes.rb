Sapos::Application.routes.draw do
  get "scholarship_categories/index"

  root :to => 'welcome#index'
  
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
  match 'estudiantes/constancias/:type/:id' => 'students#certificates'
  match 'estudiantes/constancias_grado/:thesis_id' => 'students#grade_certificates'

  match 'estudiantes/archivos/avances/:id' => 'student_advances_file#index'
  match '/avances/borrar/:id' => 'student_advances_file#destroy'
  match '/avances/subir_archivo' => 'student_advances_file#upload_file'
  match '/avances/:id/file' => 'student_advances_file#file'
  
  resources :student_files
  resources :applicant_files

  match 'aspirantes/:id/upload_file' => 'applicants#upload_file'
  match 'aspirantes/destroy_file/:id' => 'applicant_files#destroy'
  match 'aspirantes/file/:id' => 'applicant_files#download'

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
  match 'programas/:id/nuevo_curso' => 'programs#new_course'
  match 'programas/create_course' => 'programs#create_course'
  match 'programas/:id/plan' => 'programs#plan_table'
  match 'programas/:id/curso/:course_id' => 'programs#edit_course'
  match 'programas/:id/periodos' => 'programs#terms_table'
  match 'programas/:id/nuevo_periodo' => 'programs#new_term'
  match 'programas/create_term' => 'programs#create_term'
  match 'programas/update_term' => 'programs#update_term'
  match 'programas/:id/periodo/:term_id' => 'programs#edit_term'
  match 'programas/:id/terms_dropdown' => 'programs#terms_dropdown'
  match 'programas/:id/periodo/:term_id/courses_dropdown' => 'programs#courses_dropdown'
  match 'programas/:id/periodo/:term_id/seleccionar_cursos' => 'programs#select_courses_for_term'
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
  
  match 'aspirantes/busqueda' => 'applicants#live_search'
  match 'aspirantes/:id/archivos' => 'applicants#files'

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
  end

  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match "/logout" => 'sessions#destroy'
  match '/login' => 'login#index'
end
