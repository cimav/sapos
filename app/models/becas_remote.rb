class BecasRemote < ActiveRecord::Base
  establish_connection(:cimavnetmultix)
  self.table_name = "becas"
  attr_accessible :id, :name, :curp
end
