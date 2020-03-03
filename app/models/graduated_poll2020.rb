class GraduatedPoll2020 < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :id ,:student_id,:email,:token,:sent_date,:situacion_actual,:estudiante_institucion,:empleado_lugar,:empleado_sector,:empleado_actividad_posgrado,:empleado_mejora_situacion,:sni,:posgrado_satisfaccion,:posgrado_contenidos_teoricos,:posgrado_contenidos_metodologicos,:posgrado_contenidos_practicos,:posgrado_comentarios,:infraestructura_aulas,:infraestructura_laboratorios,:infraestructura_biblioteca,:infraestructura_tic,:infraestructura_cafeteria,:infraestructura_espacios,:infraestructura_comentarios,:created_at,:updated_at,:home_phone,:mobile_phone,:work_phone

  belongs_to :student
end
