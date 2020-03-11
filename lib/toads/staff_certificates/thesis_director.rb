module Toads
  module StaffCertificates
    class ThesisDirector < Toads::StaffCertificates::Basic  
       def initialize(options)
         options[:line_breaks] = {:begining=>0,:correspondence=>0,:content=>1,:carefully=>0,:sign=>2}
         super(options)
       end
     
       def contenido
         @options[:line_breaks][:content].times do 
           @pdf.text "\n"
         end
        
        @pdf.text @options[:text], :align=>:justify, :inline_format=>true   
        @pdf.text "\n"

        students = @options[:students]
        
        data = []
        data << [{:content=>"<b>NOMBRE</b>",:align=>:center},{:content=>"<b>PROGRAMA</b>",:align=>:center},{:content=>"<b>TESIS</b>",:align=>:center},{:content=>"<b>ESTATUS</b>",:align=>:center}]

        students.each do |s|
          data << [s.full_name,s.program.name,s.thesis.title,Student::STATUS[s.status]]
        end

        if @options[:co_director]
          text = "<b>Participación como co-director de tesis</b>\n"
        else
          text = "<b>Participación como director de tesis</b>\n"
        end
        
        @pdf.text text, :align=>:center, :inline_format=>true              
             
        tabla = @pdf.make_table(data,:width=>510,:cell_style=>{:size=>10,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center,:column_widths => [100,100,240,70])
        tabla.draw
        
       end #def contenido
     
    end #class ThesisDirector
  end #module Certificate
end #module Toads        


