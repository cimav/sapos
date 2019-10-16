use sapos_development;

DROP TRIGGER IF EXISTS failing_grade;

delimiter //
CREATE trigger failing_grade AFTER UPDATE
ON term_course_students
FOR EACH ROW 
BEGIN
  IF NEW.grade < 70 THEN    
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","ariane.paz@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","rocio.baeza@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","alejandro.lopez@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","emilio.dominguez@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","luz.leal@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","sergio.flores@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","sion.olive@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","alberto.diaz@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","eduardo.martinez@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
    INSERT INTO emails VALUES(NULL,"atencion.posgrado@cimav.edu.mx","mario.najera@cimav.edu.mx","Un estudiante ha recibido calificación reprobatoria",NEW.id,99,CURDATE(),CURDATE());
  END IF;
END;//
delimiter ;





