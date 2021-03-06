class Graduate < ActiveRecord::Base
  attr_accessible :id,:student_id,:workplace,:income,:gyre,:prizes,:sni,:sni_status,:subsequent_studies,:period_from,:period_to,:notes,:email,:phone
  
  default_scope joins(:student).where('students.deleted=?',0).readonly(false)
 
  belongs_to :student

  validates_uniqueness_of :student_id
  validates :student_id, :presence => true
  #validates :workplace, :presence => true
  
  NONE    = 0
  
  AGRICULTURE        = 1
  MINING             = 2
  ELECTRICITY        = 3
  CONSTRUCTION       = 4
  FOOD_INDUSTRY      = 5 
  WOOD_INDUSTRY      = 6
  MACHINERY_INDUSTRY = 7
  WHOLESALE_TRADE    = 8
  RETAIL_TRADE       = 9
  TRANSPORTATION     = 10
  POSTAL_SERVICES    = 11
  MASS_MEDIA_INFORMATION = 12
  FINANCIAL_SERVICES     = 13
  REAL_STATE_SERVICES    = 14
  SCIENTIFIC_SERVICES    = 15
  ENTERPRISE_MANAGEMENT  = 16
  SERVICES_TO_BUSSINESS  = 17
  EDUCATIONAL_SERVICES   = 18
  HEALTH_SERVICES        = 19
  CULTURAL_SPORT_SERVICES   = 20
  HOTEL_RESTAURANT_SERVICES = 21
  OTHER_SERVICES_NOT_GOVERMENT = 22
  GOVERMENT_ACTIVITIES  = 23

  CANDIDATE = 1
  SNI_1 = 2
  SNI_2 = 3
  SNI_3 = 4
  HONORARY = 5

  RANGE_1 = 1
  RANGE_2 = 2
  RANGE_3 = 3
  RANGE_4 = 4

  GYRE = {
    NONE               => '--------',
    AGRICULTURE        => 'AGRICULTURA GANADERIA APROVECHAMIENTO FORESTAL PESCA Y CAZA',
    MINING             => 'MINERIA',
    ELECTRICITY        => 'ELECTRICIDAD AGUA Y SUMINISTRO DE GAS POR DUCTOS AL CONSUMIDOR FINAL',
    CONSTRUCTION       => 'CONSTRUCCION',
    FOOD_INDUSTRY      => 'INDUSTRIA MANUFACTURERA ALIMENTARIA, TABACO, BEBIDAS Y FABRICACION DE TEXTILES',
    WOOD_INDUSTRY      => 'INDUSTRIA MANUFACTURERA DE MADERA, PAPEL, DERIVADOS DEL PETROLEO E INDUSTRIA QUIMICA',
    MACHINERY_INDUSTRY => 'INDUSTRIA MANUFACTURERA MAQUINARIA EQUIPO',
    WHOLESALE_TRADE    => 'COMERCIO AL POR MAYOR',
    RETAIL_TRADE       => 'COMERCIO AL POR MENOR',
    TRANSPORTATION     => 'TRANSPORTES CORREOS Y ALMACENAMIENTO',
    POSTAL_SERVICES    => 'SERVICIOS POSTALES, MENSAJERIA, PAQUETERIA Y ALMACENAMIENTO',
    MASS_MEDIA_INFORMATION => 'INFORMACION EN MEDIOS MASIVOS',
    FINANCIAL_SERVICES     => 'SERVICIOS FINANCIEROS Y DE SEGUROS',
    REAL_STATE_SERVICES    => 'SERVICIOS INMOBILIARIOS Y DE ALQUILER DE BIENES INMUEBLES INTANGIBLES',
    SCIENTIFIC_SERVICES    => 'SERVICIOS PROFESIONALES CIENTIFICOS Y TECNICOS',
    ENTERPRISE_MANAGEMENT  => 'DIRECCION DE CORPORATIVOS Y EMPRESAS',
    SERVICES_TO_BUSSINESS  => 'SERVICIOS DE APOYO A LOS NEGOCIOS Y MANEJO DE DESECHOS Y SERVICIOS DE REMEDIACION',
    EDUCATIONAL_SERVICES   => 'SERVICIOS EDUCATIVOS',
    HEALTH_SERVICES        => 'SERVICIOS DE SALUD Y DE ASISTENCIA SOCIAL',
    CULTURAL_SPORT_SERVICES   => 'SERVICIOS DE ESPARCIMIENTO CULTURALES Y DEPORTIVOS Y OTROS SERVICIOS RECREATIVOS',
    HOTEL_RESTAURANT_SERVICES => 'SERVICIOS DE ALOJAMIENTO TEMPORAL Y DE PREPARACION DE ALIMENTOS Y BEBIDAS',
    OTHER_SERVICES_NOT_GOVERMENT => 'OTROS SERVICIOS EXCEPTO ACTIVIDADES DE GOBIERNO',
    GOVERMENT_ACTIVITIES  => 'ACTIVIDADES DEL GOBIERNO Y ORGANISMOS INTERNACIONALES Y EXTRATERRITORIALES'
  }
 
  SNI_STATUS = {
    NONE        => '--------',
    CANDIDATE => 'Candidato',
    SNI_1 => 'SNI 1',
    SNI_2 => 'SNI 2',
    SNI_3 => 'SNI 3',
    HONORARY    => 'Honorario'
  }
  
  INCOMES  = {
    NONE    => '--------',
    RANGE_1 => '$0 - $10,000',
    RANGE_2 => '$10,000 - $25,000',
    RANGE_3 => '$25,000 - $40,000',
    RANGE_4 => '$40,000+'
  }

end
