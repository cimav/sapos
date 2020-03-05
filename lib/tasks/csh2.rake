# coding: utf-8

namespace :csh2 do
  desc "Conexiones con el Curso de Seguridad e Higiene"
  task :copy => :environment do 
    now   = Time.now
    year  = now.year.to_s
    month = now.month.to_s.rjust(2,"0")
    day   = now.day.to_s.rjust(2,"0")
    time  = "#{now.hour.to_s.rjust(2,"0")}#{now.min.to_s.rjust(2,"0")}#{now.sec.to_s.rjust(2,"0")}"

    file_name = "SegLab#{year}#{month}#{day}#{time}.txt"   
    puts "copying #{file_name}"
    File.open("private/files/csh/#{file_name}","wb") do |file|
      file << open('http://csh.cimav.edu.mx/results/SegLab.txt').read
    end  
 
    file_name = "BPL#{year}#{month}#{day}#{time}.txt"   
    puts "copying #{file_name} "
    File.open("private/files/csh/#{file_name}","wb") do |file|
      file << open('http://csh.cimav.edu.mx/results/BPL.txt').read
    end  
  end#task copy

  task :diff => :environment do
    directory = "private/files/csh/SegLab*"
    diff_file = "private/files/csh/SegLabDiffFile.txt"
    File.delete(diff_file) if File.exist?(diff_file)
    SedDiff(directory,diff_file,SafetyCourse::SEG_LAB)

    directory = "private/files/csh/BPL*"
    diff_file = "private/files/csh/BPLDiffFile.txt"
    File.delete(diff_file) if File.exist?(diff_file)
    SedDiff(directory,diff_file,SafetyCourse::BPL)
  end#task diff

  task :analize => :environment do 
    diff_file = "private/files/csh/SegLabDiffFile.txt"
    AnalizeDiffFile(diff_file)
    diff_file = "private/files/csh/BPLDiffFile.txt"
    AnalizeDiffFile(diff_file)
  end#task analize

  task :validate => :environment do 
     #safety_courses = SafetyCourse.where("attachable_id is null AND created_at > DATE_SUB(now(),INTERVAL 2 MONTH)")
     safety_courses_where = "attachable_id is null AND created_at > DATE_SUB(now(),INTERVAL 2 MONTH)"
       #where_hash = {:internships=>{:status=>3}} ## estatus de aspirante autorizado
       #internships = Internship.joins.includes(:internship_file).where(where_hash).order(:created_at)
       
  end#task validate
end #namespace

########################################## METODOS ###########################################
def SedDiff(directory,diff_file,safety_course_type)
  dir = Dir[directory]

  if dir.size<=0
    puts "Directorio Vacío"
  elsif dir.size.eql? 1
    FileUtils.cp(dir[0],diff_file)
  else
    dir.sort!{|a,b| b<=>a}
    dir.each do |f|
      puts f
    end
    file1 = dir[0]
    file2 = dir[1]
    cmd       = "diff #{file2} #{file1}"
    value     = %x[ #{cmd} ]

    File.open(diff_file,"wb") do |file|
      file << value
    end

    cmd = "tail -n +2 \"#{diff_file}\" > \"#{diff_file}.tmp\" && mv \"#{diff_file}.tmp\" \"#{diff_file}\""
    %x[ #{cmd} ]

    cmd = "sed -i 's/^> //' #{diff_file}"
    %x[ #{cmd} ]
  end #if dir.size
end ##SedDiff method

##########################################
def AnalizeDiffFile(diff_file)
    row     = SafetyCourse.new
    counter = 0
    IO.foreach(diff_file) do |line|
      if line.match(/^Array/)
        row = SafetyCourse.new
        row.safety_course_type = safety_course_type
        counter = 0
      end
      
      if line.match(/\[USER_NAME\]/)
        row.name = line.gsub(/\[.+\] \=>/,"").strip
        counter = counter + 1
      end
      if line.match(/\[USER_EMAIL\]/)
        row.email = line.gsub(/\[.+\] \=>/,"").strip
        counter = counter + 1
      end
      if line.match(/\[ps\]/) #%necesario
         row.score_needed = line.gsub(/\[.+\] \=>/,"").strip.to_i
        counter = counter + 1
      end
      if line.match(/\[sp\]/)  #%obtenido
        row.score_obtained = line.gsub(/\[.+\] \=>/,"").strip.to_i
        counter = counter + 1
      end

      if counter.eql? 4
        if row.score_needed <= row.score_obtained
          row.approved = true
        else
          row.approved = false
        end

        if row.save
          puts row.email
        else
          puts row.errors.full_messages
        end
      end
    end #IO.foreach
end
