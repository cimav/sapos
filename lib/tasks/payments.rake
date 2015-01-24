# coding: utf-8
namespace :payments do
  desc "All related to payments"
  ##################################################################################################################################
  #####                                           TASK CHECK                                                                   #####
  ##################################################################################################################################
  task :check => :environment do 
    filep        = "#{Rails.root}/log/payments.log"
    filesp       = "#{Rails.root}/private/banorte-files/"
    @f           = File.open(filep,'a')
    @env         = Rails.env
    CONCENTRA    = "134375"
    CUENTA       = "127370266"
    CICLO        = "2015-1"
    @corrupted   = 0
    @payers      = 0
    @epayers     = 0    #enrollment_payers
    @aepayers    = []   #array_enrollment_payers
    set_line "<<<<<<<<<<< - BEGIN SCRIPT - >>>>>>>>>>"
    files = Dir.glob("#{filesp}RCCG5.*.134375.gz")
    date_array = []
    files.each do |f|
      a     = f.split('.')
      date  = a[a.size-3]
      day   = date[0..1]
      month = date[2..3]
      year  = date[4..7]
      
      date_array << Date.new(year.to_i,month.to_i,day.to_i)
      #date_array << "#{year} #{month} #{day}"
    end
    
    counter   = 0
    date_array.sort.each do |da|
      year      = da.year
      month     = da.mon
      day       = da.mday
      date      = "#{day.to_s.rjust(2,"0")}#{month.to_s.rjust(2,"0")}#{year}"
      archivo   = "#{filesp}RCCG5.#{date}.134375.gz"
      File.open(archivo,'r') do |bf| ## bank file = bf
        #puts "<<<<<<<<<<< - BEGIN - >>>>>>>>>>"
        #puts "Analizando archivo: RCCG5.#{date}.134375.gz"
        gz = Zlib::GzipReader.new(bf)
        #puts "Decodificando archivo"
        decode_f = gz.read
        #puts "Spliteando archivo"
        df       = to_utf8(decode_f)  ## data file
        df_array = df.split(' ')
        line_by_line(df_array)
        #first_line(df_array)
        #last_line(df_array)
        gz.close
        #puts "Cerrando archivo: RCCG5.#{date}.134375.gz"
        counter = counter + 1
      end ##File.open
    end ##date_array.sort
    f_epayers_by_date()
    i_epayers()
    #print_epayers(@aepayers)
    print_epayers_log(@aepayers)
    set_line "#Archivos: #{counter} #A.Corrompidos: #{@corrupted} #Pagantes: #{@payers} #Pagantes.Insc: #{@epayers} Sin identificar: #{@aepayers.size}"
  end ## task :check
end #namespace payments
 
 ####################################################### METODOS ##############################################################

  ## (filtro) borra los pagos que no esten en el ultimo mes
  def f_epayers_by_date()
    array     = []
    today     = Date.today
    yesterday = today - 30 
    @aepayers.each do |aep|
      if aep[5] > yesterday
        array << aep
      end 
    end #@aepayers.each
    @aepayers = array
  end

  ## inserta los pagadores en la base de datos
  def i_epayers()
    errors   = []
    @aepayers.each do |aep|
      s = Student.where(:card=>aep[6])
      line = ""
      ## si encontramos el registro buscamos si esta inscrito al nuevo ciclo
      if s.size.eql? 1
        line = line + "Alumno encontrado "
        #buscando si esta inscrito al ciclo
        ts = TermStudent.joins(:term).where(:student_id=>s[0].id).where("terms.name like '%#{CICLO}%'")
        if ts.size>=1
          line = line + "con registro para el ciclo #{CICLO} "
          tsp = TermStudentPayment.where(:term_student_id=>ts[0].id,:status=>3)          

          if tsp.size>=1
            line = line + "y ya existe un pago total "
          else
            line = line + "y damos de alta un pago "
            amount = "#{aep[2][0..13]}.#{aep[2][14..15]}".to_f

            tsp                 = TermStudentPayment.new()
            tsp.term_student_id = ts[0].id
            tsp.amount          = amount
            tsp.status          = 3
            tsp.save
          end ##if tsp.size
        else
          line = line + "sin registros para el ciclo #{CICLO} "
        end ##if ts.size
        
        line = line + "para #{aep[7]} (#{aep[6]})"
        set_line line
      else
        errors << aep
      end ##if s.size
    end
    
    @aepayers = errors
  end

  ## imprime de forma presentable los epayers
  def print_epayers(a)
    a.each_with_index do |n,i|
      print_and_space(n[0])
      print_and_space(n[1])
      print_and_space(n[2])
      print_and_space(n[3])
      print_and_space(n[4])
      print_and_space(n[5].to_s)
      print_and_space(n[6])
      print_and_space(n[7])
      print "\n"
    end
  end  
  
  ## imprime de forma presentable los epayers
  def print_epayers_log(a)
    a.each_with_index do |n,i|
      set_line "#{n[0]} #{n[1]} #{n[2]} #{n[3]} #{n[4]} #{n[5].to_s} #{n[6]} #{n[7]}"
    end
  end  

  ## analizamos linea por linea
  def line_by_line(a)
    d     = []
    name  = []
    a.each_with_index do |l,i|
      if i.eql? 0
        if !first_line_ok(l)
          @corrupted = @corrupted + 1
          break ## abandonamos el analisis de ese archivo
        end #first_line_ok
      elsif i.eql? a.size-1
        #puts "<<<<< - FIN DE ARCHIVO ->>>>>"  ## linea final del archivo, no nos sirve para mucho
      else
        if l[0..1].eql? "20"  
          #pay_line(l)
          pld = pay_line_dates(l)
          d << pld[0]   #folio
          d << pld[1]   #concepto
          d << pld[2]   #matricula
          d << pld[3]   #deposito
          @payers = @payers + 1
        elsif l[0..2].eql? "000"
          #pay_line_2(l)
          pld2 = pay_line_dates_2(l)
          d << pld2[0]   #concepto
          d << pld2[1]   #hora
          d << pld2[2]   #fecha
        elsif l.eql? CONCENTRA
          #print "#{d[0]} #{d[2]} #{d[3]} #{d[4]} #{d[5]} #{d[1]} "
          #name_lines(name)
          if d[3].eql? "0000000000330000"
            date = Date.new(d[6][0..3].to_i,d[6][4..5].to_i,d[6][6..7].to_i)
            @aepayers << [d[0],d[1],d[3],d[4],d[5],date,d[2],get_name(name)]
            @epayers = @epayers + 1
          end
          d    = []
          name = []
        else
          name << l
        end #if 20 elsif 000
      end # i.eql? 0
    end #df_array.each
  end
  
  ## devuelve el nombre en una sola linea
  def get_name(a)
    aux = ""
    a.each do |n|
      aux = aux + "#{n} "
    end
    return aux.chop
  end  


  ## Imprime el nombre en una sola linea
  def name_lines(a)
    a.each do |n|
      print_and_space(n)
    end
    print "\n"
  end  

  ## Comprueba que la primera linea este correcta
  def first_line_ok(l)
    if l[0].eql? "0"
      if l[1..6].eql? CONCENTRA
        if l[22..30].eql? CUENTA
          return true
        else
          puts "Primera linea corrompida[3]"
          return false
        end
      else
        puts "Primera linea corrompida[2]"
        return false
      end
    else
      puts "Primera linea corrompida[1]"
      return false
    end
  end
  
  ## Nos trae los conceptos que nos interesan
  def pay_line_dates(s)
    return [s[6..15],s[2..5],s[69..s.size-1],s[53..68]] #folio,concepto,matricula, deposito
  end
  
  ## Nos trae los conceptos que nos interesan
  def pay_line_dates_2(s)
    return [s[8..11],s[12..17],s[22..29]]  ## concepto, hora hhmmss, fecha yyyymmdd
  end
  
  ## Analiza la segunda inea de pago de forma general
  def pay_line_2(s)
    print_and_space(s[0..2])         #000 - static
    print_and_space(s[3..7])         # 10101 - static
    print_and_space(s[8..11])        # Concepto
    print_and_space(s[12..17])       # hora hhmmss
    print_and_space(s[18..21])       # A000 - static
    print_and_space(s[22..29])       # fecha yyyymmdd
    print_and_space(s[30..31])       # ** - static
    print_and_space(s[32..s.size-1]) ## desconocida, rara vez cambia, tal vez cuando se paga con tarjeta
    print "\n"
  end
  

  ## Analiza la linea de pago de forma general
  def pay_line(s)
    print_and_space(s[0..1])       #20 - static
    print_and_space(s[2..5])       # Concepto
    print_and_space(s[6..15])      # Variable desconocida, probablemente folio de pago
    print_and_space(s[16..21])     #Concentra 
    print_and_space(s[22..25])     # Variable desconocida, varia muy poco solo el ultimo digito entre 5 y 1
    print_and_space(s[26..41])     #Deposito
    print_and_space(s[42..52])     #0000000000N - static
    print_and_space(s[53..68])     #Deposito (se repite)
    print_and_space(s[69..s.size-1])  ## MATRICULA y/o datos de referencia
    print "\n"
  end

  ## Analiza la primer linea de forma general
  def first_line(a)
    print_and_space(a[0][0])       #zero - static
    print_and_space(a[0][1..6])    #concentra
    print_and_space(a[0][7..14])   #fecha yyyymmdd
    print_and_space(a[0][15..21])  #0000000 - static
    print_and_space(a[0][22..30])  #cuenta
    print "\n"
  end

  ## Analiza la ultima linea de forma general
  def last_line(a)
    print_and_space(a[a.size - 1][0])       #4 - static
    print_and_space(a[a.size - 1][1..6])    #numero registros
    print_and_space(a[a.size - 1][7..22])   #total
    print_and_space(a[a.size - 1][23..66])  #chorrosientosmil zeros - static?
    print_and_space(a[a.size - 1][67..72])  #numero registros (se repite)
    print_and_space(a[a.size - 1][73..89])  #total (se repite)
    print "\n"
  end
  
  ## imprime un espacio despues del string
  def print_and_space(str)
    print str+" "
  end

  ## hace que se impriman con fluidez(smoothly) los textos 
  ##def print_and_flush(str)
  ##  print str
  ##  $stdout.flush
  ##  sleep 1
  ##end
   
  ## evita el error que devuelve el split cuando encuentra un caracter extraño
  def to_utf8(str)
    str = str.force_encoding("UTF-8")
    return str if str.valid_encoding?
    str = str.force_encoding("BINARY")
    str.encode("UTF-8", invalid: :replace, undef: :replace)
  end
