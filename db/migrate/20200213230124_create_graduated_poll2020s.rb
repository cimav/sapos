class CreateGraduatedPoll2020s < ActiveRecord::Migration
  def change
    create_table :graduated_poll2020s do |t|
      t.references :student
      t.string  :email
      t.string  :token
      t.date    :sent_date
      t.string  :situacion_actual
      t.string  :estudiante_institucion
      t.string  :empleado_lugar
      t.string  :empleado_sector
      t.string  :empleado_actividad_posgrado
      t.string  :empleado_mejora_situacion
      t.string  :sni
      t.string  :posgrado_satisfaccion
      t.string  :posgrado_contenidos_teoricos
      t.string  :posgrado_contenidos_metodologicos
      t.string  :posgrado_contenidos_practicos
      t.text    :posgrado_comentarios
      t.string  :infraestructura_aulas
      t.string  :infraestructura_laboratorios
      t.string  :infraestructura_biblioteca
      t.string  :infraestructura_tic
      t.string  :infraestructura_cafeteria
      t.string  :infraestructura_espacios
      t.text    :infraestructura_comentarios
      t.timestamps
    end
  end
end
