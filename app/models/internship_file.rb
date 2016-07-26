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
  
  REQUESTED_DOCUMENTS = {
    NORMAL              => 'Documento genérico',
    SIGN_REQUEST        => 'Solicitud con firmas',
    INSTITUTION_REQUEST => 'Solicitud oficial de la institución de procedencia',
    REGISTRATION_PROOF  => 'Constancia de inscripción de institución de procedencia',
    PHOTO               => 'Fotografía para la credencial'
  }


  def delete_linked_file
    self.remove_file!
  end
end
