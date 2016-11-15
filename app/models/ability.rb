class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.access == User::MANAGER
      if user.program_type == Program::P_PROPEDEUTICOS
        can :manage, [Student,Program,Internship]
      else
        can :manage, :all
      end
    end 

    if user.access == User::ADMINISTRATOR
        can :manage, [Student ,Staff, Program, Internship, Institution, Classroom, Laboratory, Department, Graduate, Scholarship]
        can :manage, User
        cannot [:create,:destroy,:update], User
        cannot [:create,:destroy], Student
    else
      can :live_search, :all  ## for default read all live_search
      if user.access == User::OPERATOR
        #can :manage, Student
        #cannot :destroy, Student
        #can :manage, Internship
        can [:read,:update,:certificates,:applicant_interview,:applicant_files,:upload_applicant_file,:applicant_file,:live_search,:change_image,:upload_image,:files,:file,:upload_file,:delete_file,:id_card], Internship
        can :manage, InternshipFile
      end

      if user.access == User::STUDENT
        can :manage, Internship
      end
    end
  end
end
