module Toads
  module StaffCertificates
    module Individual
      class Basic < Toads::StaffCertificates::Basic
        def initialize(options)
          options[:margin] = [85,60,60,60]
          super(options)
        end
       
        ####################################################################
        # Alumnos como director y co_director de tesis
        def dir_tesis
          @students = @options[:active_students]
          @students = @students + @options[:active_students_co]
          #@options[:line_breaks] = {:begining=>0,:correspondence=>3,:content=>1,:carefully=>4,:sign=>2} 

          if @students.size > 0
            data = []
            data_helper    = []
            margin         = [140,55,60,55]
            @options[:pdf] = @pdf
                     
            if @pdf.page_count.eql? 1 
              if self.first_page_clean
                @pdf.move_cursor_to 792-margin[0]-margin[2]  ## obviando que el tamaño de la página es Letter 792x612
              end
            else
              @pdf.start_new_page(:margin=>margin)
            end

            @students.each_with_index do |student,index|
              unless self.first_page_clean
                if index < @students.size
                  @pdf.start_new_page(:margin=>margin)
                end
              end
                          
              @options[:student] = student
              thesis_director = Toads::StaffCertificates::Individual::ThesisDirector.new(@options)                  
              thesis_director.order
             
              self.first_page_clean = false
            end
          end
        end #def dir_tesis
       
        ####################################################################
        # cursos impartidos INDIVIDUAL
        def courses           
          margin                = [130,55,60,55]
          @options[:margin]     = margin
          term_course_schedules = @options[:term_course_schedules]
          @options[:pdf]        = @pdf
          @options[:line_breaks] = {:begining=>0,:correspondence=>1,:content=>1,:carefully=>1,:sign=>2} 

          if @pdf.page_count.eql? 1 
            if self.first_page_clean
              @pdf.move_cursor_to 792-margin[0]-margin[2]  ## obviando que el tamaño de la página es Letter 792x612
            end
          end
         
          if term_course_schedules.size > 0
            courses = Toads::StaffCertificates::Individual::StaffCourses.new(@options) 
            courses.order
            if @pdf.page_count.eql? 1
              self.first_page_clean = false
            end
          else
            if @pdf.page_count.eql? 1
              self.first_page_clean = true
            end
          end

        end #def courses

        ####################################################################
        # director externo
        def external_director                
          @students      = @options[:active_students_external]
          margin         = [140,55,60,55]
          @options[:pdf] = @pdf     
         
          if @students.size > 0
            if @pdf.page_count.eql? 1 
              if self.first_page_clean
                @pdf.move_cursor_to 792-margin[0]-margin[2]  ## obviando que el tamaño de la página es Letter 792x612
              end
            end
       
            @students.each_with_index do |student,index|             
              if index < @students.size           
                @options[:line_breaks] = {:begining=>1,:correspondence=>3,:content=>1,:carefully=>4,:sign=>2} 
              end
     
              @options[:student] = student
              
              external_director = Toads::StaffCertificates::Individual::ExternalDirector.new(@options)                  
              external_director.order
             
              if @pdf.page_count.eql? 1
                @pdf.start_new_page(:margin=>margin)
                self.first_page_clean = false
              end
            end # index
           
            
          end # @students.each_with_index
        end #def external_director
       
        ####################################################################
        # comité tutoral
        def tutoral_committee
          active_advances = []      
          active_advances = @options[:advances]
          @options[:pdf]  = @pdf   
          margin         = [140,55,60,55]
         
          if @pdf.page_count.eql? 1 
            if self.first_page_clean
              @pdf.move_cursor_to 792-margin[0]-margin[2]  ## obviando que el tamaño de la página es Letter 792x612
            end
          end
                  
          if active_advances.size > 0
            active_advances.each_with_index do |a,index|
              if index < active_advances.size           
                @options[:line_breaks] = {:begining=>1,:correspondence=>3,:content=>1,:carefully=>4,:sign=>2} 
                @pdf.start_new_page(:margin=>margin)
              end
                          
              @options[:a] = a
              active_advance = Toads::StaffCertificates::Individual::TutoralCommittee.new(@options)
              active_advance.order   
             
              if @pdf.page_count.eql? 1
                @pdf.start_new_page(:margin=>margin)
                self.first_page_clean = false
              end # if @pdf.page_count
            end # active_advances.each
          end  # if active_advances.size

        end # def tutoral_committee

        ####################################################################
        # sobreescribimos pie y order
        #
        def render
          self.courses
          self.dir_tesis
          self.external_director
          self.tutoral_committee
          @pdf.render
        end

      end #class Individual
    end #module Individual
  end #module Certificate
end #module Toads
