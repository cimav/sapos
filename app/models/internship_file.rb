class InternshipFile < ActiveRecord::Base
  attr_accessible :id,:internship_id,:description,:file,:created_at,:updated_at,:file_type
  mount_uploader :file, InternshipFileUploader
  validates :description, :presence => true

  before_destroy :delete_linked_file

  NORMAL              = 1
  SIGN_REQUEST        = 2
  INSTITUTION_REQUEST = 3
  REGISTRATION_PROOF  = 4
  PHOTO               = 5
  COURSE              = 6
  MEDICAL_PROOF       = 7
  PHOTO_ID            = 8
  RECOMMENDATION      = 9
  REASONS             = 10
  PHOTO               = 11
  
    
  REQUESTED_DOCUMENTS = {
    NORMAL              => 'Documento genérico',
    SIGN_REQUEST        => 'Solicitud con firmas',
    INSTITUTION_REQUEST => 'Solicitud oficial de la institución de procedencia',
    REGISTRATION_PROOF  => 'Constancia de la institución de procedencia',
    COURSE              => 'Curso de seguridad e higiene aprobado',
    MEDICAL_PROOF       => 'Comprobante de Servicio Médico',
    PHOTO_ID            => 'Identificación Oficial con Fotografía',
    RECOMMENDATION      => 'Carta de recomendación',
    REASONS             => 'Carta de exposición de motivos',
    PHOTO               => 'Fotografía para la credencial'
  }


  def delete_linked_file
    self.remove_file!
  end
end
