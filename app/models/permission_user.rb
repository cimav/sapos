class PermissionUser < ActiveRecord::Base
  attr_accessible :id,:user_id,:program_id
  belongs_to :user
  belongs_to :program

  after_save :check_zero_values

  def check_zero_values
    if self.program_id == 0
      self.destroy
    end 
  end
end
