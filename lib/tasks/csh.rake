# coding: utf-8
namespace :csh do
  desc "Conexiones con el Curso de Seguridad e Higiene"
  task :search => :environment do 
  	#where_hash = {:internships=>{:status=>3,:applicant_status=>3}}
  	#where_hash = {:internships=>{:status=>[0,3]}}
  	where_hash = {:internships=>{:status=>3}}
  	where      = "internships.created_at > DATE_SUB(now(),INTERVAL 3 MONTH)"
    internships = Internship.includes(:internship_file).where(where_hash).where(where).order(:created_at)  ## todos los aspirantes (status:3) con estatus de autorizado(3)
    without_course    = 0
    approveds_counter = 0
    internships.each do |i|
      if i.internship_file.where(:description=>'Curso').size >= 1
      	next
      end

      without_course    = without_course + 1

      vars                = Hash.new
      vars[:email]        = i.email
      vars[:hash]         = Hash.new
      vars[:row]          = Array.new
      vars[:counter]      = 0
      vars[:exam1]        = false
      vars[:exam2]        = false
      vars[:exam3]        = false
      vars[:counter_hash] = 0 

      open("http://csh.cimav.edu.mx/resultados/resultados1.txt") {|f|
        f.each_line {|line|
          vars = analize(line, vars)
        }
      }
    
      if !(vars[:hash].size.eql? 0)
        if vars[:hash]["#{vars[:counter_hash]}"][6].include? "User passes"
          vars[:exam1] = true
        end
      end
      puts "1: |#{vars[:email]}| #{vars[:exam1]}"
    
      vars[:hash].clear
      vars[:counter_hash] = 0
    
      open("http://csh.cimav.edu.mx/resultados/resultados2.txt") {|f|
        f.each_line {|line|
          vars = analize(line, vars)
        }
      }
      if !(vars[:hash].size.eql? 0)
        if vars[:hash]["#{vars[:counter_hash]}"][6].include? "User passes"
          vars[:exam2] = true
        end
      end
      puts "2: |#{vars[:email]}| #{vars[:exam2]}"
    
      vars[:hash].clear
      vars[:counter_hash] = 0
    
      open("http://csh.cimav.edu.mx/resultados/resultados3.txt") {|f|
        f.each_line {|line|
          vars = analize(line, vars)
        }
      }
    
      if !(vars[:hash].size.eql? 0)
        if vars[:hash]["#{vars[:counter_hash]}"][6].include? "User passes"
          vars[:exam3] = true
        end
      end
      puts "3: |#{vars[:email]}| #{vars[:exam3]}"
      
    
      vars[:hash].clear
      vars[:counter_hash] = 0
    

      if vars[:exam1] && vars[:exam2] && vars[:exam3]
        approveds_counter = approveds_counter + 1
        i_file = InternshipFile.new
        i_file.internship_id = i.id
        i_file.description   = "Curso"
        i_file.file          = "Curso"
        i_file.file_type     = 6
        i_file.save
      end
    end #internships
    puts "Total: #{without_course} Aprobados: #{approveds_counter}"

  end#task

  def analize(line,vars)
    if vars[:counter]>0
      if line.upcase.include? vars[:email].upcase
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      elsif line.include? "Quiz title"
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      elsif line.include? "Points awarded"
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      elsif line.include? "Total score"
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      elsif line.include? "Passing score"
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      elsif line.include? "User fails"
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      elsif line.include? "User passes"
      	vars[:row] << line
      	vars[:counter] = vars[:counter] + 1
      else
      	vars[:counter] = 0
      	vars[:row].pop
      end

    end# if vars[:counter]

    if vars[:counter].eql? 7
      vars[:counter_hash] = vars[:counter_hash] + 1
  
      vars[:hash]["#{vars[:counter_hash]}"] = vars[:row].clone
  
      vars[:counter] = 0
      vars[:row].clear
    end

    if line.include? "User name"
      vars[:row] << line
      vars[:counter] = 1
    end

    return vars
  end# def analize
end
