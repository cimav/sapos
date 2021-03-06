class ApplicantFile < ActiveRecord::Base
  attr_accessible :id, :applicant_id, :file_type, :description, :file
  mount_uploader :file, ApplicantFileUploader
 
  validates :description, :presence => true
  validates :applicant_id, :presence => true
  validates :file_type, :presence => true
  validates :file, :presence => true

  before_destroy :delete_linked_file

  BIRTH_CERTIFICATE = 1
  CURP              = 2
  PROOF_OF_ADDRESS  = 3
  VOTING_CARD       = 4
  PREVIOUS_DEGREE_CERTIFICATE         = 5
  PREVIOUS_DEGREE_TEST_CERTIFICATE    = 6
  PREVIOUS_DEGREE_STUDIES_CERTIFICATE = 7
  CENEVAL  = 8
  TOEFL    = 9
  ACADEMIC_CURRICULUM = 10
  CONACYT_ENDED_SCHOLARSHIP_CERTIFICATE = 11
  APPLICATION = 12
  OTHER       = 13
  PRELIMINARY_RESEARCH = 14
  ACADEMIC_RECOMENDATION_LETTER = 15
  REASONS = 16

  REQUESTED_DOCUMENTS = {
    BIRTH_CERTIFICATE                   => 'Acta de Nacimiento',
    CURP                                => 'C.U.R.P',
    PROOF_OF_ADDRESS                    => 'Comprobante de Domicilio',
    VOTING_CARD                         => 'Credencial para votar',
    PREVIOUS_DEGREE_CERTIFICATE         => 'Titulo del grado anterior',
    PREVIOUS_DEGREE_TEST_CERTIFICATE    => 'Acta de examen del grado anterior',
    PREVIOUS_DEGREE_STUDIES_CERTIFICATE => 'Certificado de estudios del grado anterior',
    CENEVAL                             => 'Resultados del Examen Ceneval Exani III',
    TOEFL                               => 'Resultados del Examen TOEFL',
    ACADEMIC_CURRICULUM                 => 'Curriculum Academico',
    CONACYT_ENDED_SCHOLARSHIP_CERTIFICATE => 'Carta de finiquito de becario CONACyT',
    APPLICATION                         => 'Solicitud',
    PRELIMINARY_RESEARCH                => "Anteproyecto de investigacion",
    ACADEMIC_RECOMENDATION_LETTER       => "Carta de recomendación académica", 
    OTHER                               => 'Otro',
    REASONS                             => 'Carta de exposición de motivos',
 }
  
  REQUESTED_DOCUMENTS_EN = {
    BIRTH_CERTIFICATE                   => 'Birth Certificate',
    CURP                                => 'C.U.R.P',
    PROOF_OF_ADDRESS                    => 'Proof of address',
    VOTING_CARD                         => 'Id',
    PREVIOUS_DEGREE_CERTIFICATE         => 'Titulo del grado anterior',
    PREVIOUS_DEGREE_TEST_CERTIFICATE    => 'Degree',
    PREVIOUS_DEGREE_STUDIES_CERTIFICATE => 'Official transcript',
    CENEVAL                             => 'Resultados del Examen Ceneval Exani III',
    TOEFL                               => 'Resultados del Examen TOEFL',
    ACADEMIC_CURRICULUM                 => 'Curriculum Vitae',
    CONACYT_ENDED_SCHOLARSHIP_CERTIFICATE => 'Carta de finiquito de becario CONACyT',
    APPLICATION                         => 'Solicitud',
    PRELIMINARY_RESEARCH                => "Anteproyecto de investigacion",
    ACADEMIC_RECOMENDATION_LETTER       => "Recomendation letter", 
    OTHER                               => 'Otro',
    REASONS                             => 'Statement of reasons letter',
 }


  def delete_linked_file
    self.remove_file!
  end
end
