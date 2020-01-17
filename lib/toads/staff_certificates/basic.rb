module Toads
  module StaffCertificates
    class Basic
      attr_accessor :first_page_clean
     
      def initialize(options)
        @options          = options
        @background       = "#{Rails.root.to_s}/private/prawn_templates/membretada.png"
        @margin           = options[:margin]      || [130,55,110,55]
        @background_scale = 0.36
        @options[:line_breaks] = {:begining=>0,:correspondence=>1,:content=>2,:carefully=>2,:sign=>2} 
        #@line_breaks      = options[:line_breaks] || {:begining=>0,:correspondence=>1,:content=>2,:carefully=>2,:sign=>2}
        @first_page_clean = true
        @pdf              = options[:pdf] || Prawn::Document.new(:background => @background, :background_scale=>@background_scale, :margin=>@margin )
        @pdf.font_families.update(
          "Montserrat"    => { :bold        => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Bold.ttf"),
                               :italic      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Italic.ttf"),
                               :bold_italic => Rails.root.join("app/assets/fonts/montserrat/Montserrat-BoldItalic.ttf"),
                               :normal      => Rails.root.join("app/assets/fonts/montserrat/Montserrat-Regular.ttf") 
                             })
        @pdf.font "Montserrat"
        @pdf.font_size 11
        @pdf.fill_color "000000"
      end # initialize
     
      def consecutivo(time)
        self.get_consecutive(@options[:staff], time, @options[:cert_type])
      end
     
      def cabecera
        w = 255
        h = 50
       
        time = Time.new
        #@pdf.text "#### #{@options[:line_breaks][:begining]}"

        @options[:line_breaks][:begining].times do 
          @pdf.text "\n"
        end

       
       
        @pdf.text "<b>Coordinación de estudios de Posgrado\nOficio PO - #{self.consecutivo(time)}/#{time.year.to_s}</b>\n#{@options[:city]}, a #{time.day.to_s} de #{get_month_name(time.month)} de #{time.year.to_s}.", :inline_format=>true, :align=>:right, :width=>w, :height=>h
      end #def cabecera
      
      def correspondencia
        w = 255
        h = 50
        
        @options[:line_breaks][:correspondence].times do 
          @pdf.text "\n"
        end
       
        @pdf.text "A quien corresponda\n", :align=>:left,:valign=>:top, :width=>w, :height=>h,:inline_format=>true
        @pdf.text "<b>Presente.</b>", :align=>:left, :character_spacing=>4,:inline_format=>true
        
      end
     
      def contenido
        @pdf.text "Sin contenido"
      end
     
      def final
        text = "\nSe extiende la presente constancia a petición del interesado, para los fines legales que haya lugar."
        @pdf.text text
        ############################## FIRMA ##############################
        @options[:line_breaks][:carefully].times do 
          @pdf.text "\n"
        end
        
        @atentamente = "<b>A t e n t a m e n t e"
        @options[:line_breaks][:sign].times do 
          @atentamente << "\n"
        end
       
        @atentamente << "#{@options[:firma]}\n#{@options[:puesto]}</b>"
        #@atentamente = "\n<b>A t e n t a m e n t e\n\n\n#{@options[:firma]}\n#{@options[:puesto]}</b>"
        @pdf.text @atentamente, :align=>:center,:inline_format=>true
        ############################## ###### ##############################
      end
     
      def pie
        @pdf.number_pages "Página <page> de <total>", {:at=>[0, -73],:align=>:center,:size=>8,:color=>"d4b48f"}
      end
     
      def order
        self.cabecera
        self.correspondencia
        self.contenido
        self.final
        self.pie
      end
     
      def render
         self.order 
         @pdf.render
      end #def render
          
      def get_month_name(number)
        months = ["enero","febrero","marzo","abril","mayo","junio","julio","agosto","septiembre","octubre","noviembre","diciembre"]
        name = months[number - 1]
        return name
      end
     
     
      def get_consecutive(object, time, type)
        maximum = ::Certificate.where(:year => time.year).maximum("consecutive")

        if maximum.nil?
          maximum = 1
        else
          maximum = maximum + 1
        end

        certificate                 = ::Certificate.new()
        certificate.consecutive     = maximum
        certificate.year            = time.year
        certificate.attachable_id   = object.id
        certificate.attachable_type = object.class.to_s
        certificate.type_id         = type
        certificate.save

        return "%03d" % maximum
      end #def get_consecutive

    end # class Certificate
  end #module Certificate
end #module Toads
