module Toads
  module StaffCertificates
    class Sinodal < Toads::StaffCertificates::Basic
      def initialize(options)
        options[:line_breaks] = {:begining=>0,:correspondence=>1,:content=>1,:carefully=>2,:sign=>2}
        super(options)
      end

      def contenido
        @options[:line_breaks][:content].times do 
          @pdf.text "\n"
        end

        @pdf.text @options[:text], :align=>:justify, :inline_format=> true
        @pdf.text "\n"

        @theses = @options[:theses]
         data = []
         data << [{:content=>"<b>NOMBRE</b>",:align=>:center},{:content=>"<b>PROGRAMA</b>",:align=>:center},{:content=>"<b>TESIS</b>",:align=>:center},{:content=>"<b>FECHA DE DEFENSA</b>",:align=>:center}]
        
        @theses.each do |t|
          defence_month = t.defence_date.month
          data << [t.student.full_name ,t.student.program.name,t.title,t.defence_date.strftime("%-d de #{defence_month} de %Y")]
        end

        @pdf.text "<b>Participación como sinodal</b>\n", :align=>:center, :inline_format=>true              
        tabla = @pdf.make_table(data,:width=>500,:cell_style=>{:size=>8,:padding=>2,:inline_format => true,:border_width=>1},:position=>:center,:column_widths => [100,95,200,105])
        tabla.draw
      end ## def contenido

    end ## class Sinodal
  end ## module StaffCertificates
end ## module Toads
