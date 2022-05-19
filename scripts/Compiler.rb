#===============================================================================
# Exceptions and critical code
#===============================================================================
class Reset < Exception
end



def pbGetExceptionMessage(e,script="")
  emessage=e.message
  if e.is_a?(Hangup)
    emessage="El script está tomando mucho tiempo. El juego se reiniciará."
  elsif e.is_a?(Errno::ENOENT)
    filename=emessage.sub("No existe dicho archivo o carpeta - ", "")
    emessage="Archivo #{filename} no encontrado."
  end
  if emessage && !safeExists?("Game.rgssad") && !safeExists?("Game.rgss2a")
    emessage=emessage.gsub(/uninitialized constant PBItems\:\:(\S+)/){
       "El objeto '#{$1}' no es válida. Agregue el objeto\r\na la lista de objetos en el editor. Consulta más información en la wiki." }
    emessage=emessage.gsub(/undefined method `(\S+?)' for PBItems\:Module/){
       "El objeto '#{$1}' no es válida. Agregue el objeto\r\na la lista de objetos en el editor. Consulta más información en la wiki." }
    emessage=emessage.gsub(/uninitialized constant PBTypes\:\:(\S+)/){
       "El tipo '#{$1}' no es válida. Agregue el tipo\r\nal archivo PBS/types.txt." }
    emessage=emessage.gsub(/undefined method `(\S+?)' for PBTypes\:Module/){
       "El tipo '#{$1}' no es válida. Agregue el tipo\r\nal archivo PBS/types.txt." }
    emessage=emessage.gsub(/uninitialized constant PBTrainers\:\:(\S+)$/){
       "El tipo de entrenador '#{$1}' no es válida. Agregue el entrenador\r\na la lista de tipos de entrenadores en el Editor. Consulta más\r\ninformación en la wiki." }
    emessage=emessage.gsub(/undefined method `(\S+?)' for PBTrainers\:Module/){
       "El tipo de entrenador '#{$1}' no es válida. Agregue el entrenador\r\na la lista de tipos de entrenadores en el Editor. Consulta más\r\ninformación en la wiki." }
    emessage=emessage.gsub(/uninitialized constant PBSpecies\:\:(\S+)$/){
       "La especie Pokemon '#{$1}' no es válida. Agregue\r\nla especie al archivo PBS/pokemon.txt.\r\nConsulta más información en la wiki." }
    emessage=emessage.gsub(/undefined method `(\S+?)' for PBSpecies\:Module/){
       "La especie Pokemon '#{$1}' no es válida. Agregue\r\nla especie al archivo PBS/pokemon.txt.\r\nConsulta más información en la wiki." }
  end
  return emessage
end

def pbPrintException(e)
  emessage=pbGetExceptionMessage(e)
  btrace=""
  if e.backtrace
    maxlength=$INTERNAL ? 25 : 10
    e.backtrace[0,maxlength].each do |i|
      btrace=btrace+"#{i}\r\n"
    end
  end
  btrace.gsub!(/Section(\d+)/){$RGSS_SCRIPTS[$1.to_i][1]}
  message="Excepción: #{e.class}\r\nMensaje: #{emessage}\r\n#{btrace}"
  errorlog="errorlog.txt"
  if (Object.const_defined?(:RTP) rescue false)
    errorlog=RTP.getSaveFileName("errorlog.txt")
  end
  errorlogline=errorlog.sub(Dir.pwd+"\\","")
  errorlogline=errorlogline.sub(Dir.pwd+"/","")
  if errorlogline.length>20
    errorlogline="\r\n"+errorlogline
  end
  File.open(errorlog,"ab"){|f| f.write(message) }
  if !e.is_a?(Hangup)
    print("#{message}\r\nEsta excepción ha sido registrada en #{errorlogline}.\r\nPresiona Ctrl+C para copiar este mensaje al portapapeles.")
  end
end

def pbCriticalCode
  ret=0
  begin
    yield
    ret=1
  rescue Exception
    e=$!
    if e.is_a?(Reset) || e.is_a?(SystemExit)
      raise
    else
      pbPrintException(e)
      if e.is_a?(Hangup)
        ret=2
        raise Reset.new
      end
    end
  end
  return ret
end



#===============================================================================
# Lectura de Archivos
#===============================================================================
module FileLineData
  @file=""
  @linedata=""
  @lineno=0
  @section=nil
  @key=nil
  @value=nil

  def self.file
    @file
  end

  def self.file=(value)
    @file=value
  end

  def self.clear
    @file=""
    @linedata=""
    @lineno=""
    @section=nil
    @key=nil
    @value=nil
  end

  def self.linereport
    if @section
      if @key!=nil
        return _INTL("Archivo {1}, seccion {2}, clave {3}\r\n{4}\r\n",@file,@section,@key,@value)
      else
        return _INTL("Archivo {1}, seccion {2}\r\n{3}\r\n",@file,@section,@value)
      end
    else
      return _INTL("Archivo {1}, linea {2}\r\n{3}\r\n",@file,@lineno,@linedata)
    end
  end

  def self.setSection(section,key,value)
    @section=section
    @key=key
    if value && value.length>200
      @value=_INTL("{1}...",value[0,200])
    else
      @value=!value ? "" : value.clone
    end
  end

  def self.setLine(line,lineno)
    @section=nil
    if line && line.length>200
      @linedata=_INTL("{1}...",line[0,200])
    else
      @linedata=line
    end
    @lineno=lineno
  end
end



def findIndex(a)
  index=-1
  count=0
  a.each {|i|
     if yield i
       index=count
       break
     end
     count+=1
  }
  return index
end

def prepline(line)
  line.sub!(/\s*\#.*$/,"")
  line.sub!(/\s+$/,"")
  return line
end

def pbEachFileSectionEx(f)
  lineno=1
  havesection=false
  sectionname=nil
  lastsection={}
  f.each_line {|line|
     if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
       line=line[3,line.length-3]
     end
     if !line[/^\#/] && !line[/^\s*$/]
       if line[/^\s*\[\s*(.*)\s*\]\s*$/]
         if havesection
           yield lastsection,sectionname 
         end
         sectionname=$~[1]
         havesection=true
         lastsection={}
       else
        if sectionname==nil
          FileLineData.setLine(line,lineno)
          raise _INTL("Se esperaba una sección al inicio del archivo. Este error también puede ocurrir si el archivo no ha sido guardado en codificación UTF-8.\r\n{1}",FileLineData.linereport)
        end
        if !line[/^\s*(\w+)\s*=\s*(.*)$/]
          FileLineData.setSection(sectionname,nil,line)
          raise _INTL("Sintaxis de línea errónea (se esperaba línea con formato XXX=YYY)\r\n{1}",FileLineData.linereport)
        end
        r1=$~[1]
        r2=$~[2]
        lastsection[r1]=r2.gsub(/\s+$/,"")
      end
    end
    lineno+=1
    if lineno%500==0
      Graphics.update
    end
    if lineno%50==0
      Win32API.SetWindowText(_INTL("Procesando linea {1}",lineno))
    end
  }
  if havesection
    yield lastsection,sectionname 
  end
end

def pbEachFileSection(f)
  pbEachFileSectionEx(f) {|section,name|
     if block_given? && name[/^\d+$/]
       yield section,name.to_i
     end
  }
end

def pbEachSection(f)
  lineno=1
  havesection=false
  sectionname=nil
  lastsection=[]
  f.each_line {|line|
     if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
       line=line[3,line.length-3]
     end
     if !line[/^\#/] && !line[/^\s*$/]
       if line[/^\s*\[\s*(.+?)\s*\]\s*$/]
         if havesection
           yield lastsection,sectionname 
         end
         sectionname=$~[1]
         lastsection=[]
         havesection=true
       else
         if sectionname==nil
           raise _INTL("Se esperaba una sección al inicio del archivo (línea {1}). La sección inicia con '[nombre de sección]'",lineno)
         end
         lastsection.push(line.gsub(/^\s+/,"").gsub(/\s+$/,""))
       end
     end
     lineno+=1
     if lineno%500==0
       Graphics.update
     end
  }
  if havesection
    yield lastsection,sectionname 
  end
end

def pbEachCommentedLine(f)
  lineno=1
  f.each_line {|line|
     if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
       line=line[3,line.length-3]
     end
     if !line[/^\#/] && !line[/^\s*$/]
       yield line, lineno
     end
     lineno+=1
  }
end

def pbCompilerEachCommentedLine(filename)
  File.open(filename,"rb"){|f|
     FileLineData.file=filename
     lineno=1
     f.each_line {|line|
        if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
          line=line[3,line.length-3]
        end
        if !line[/^\#/] && !line[/^\s*$/]
          FileLineData.setLine(line,lineno)
          yield line, lineno
        end
        lineno+=1
     }
  }
end

def pbEachPreppedLine(f)
  lineno=1
  f.each_line {|line|
     if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
       line=line[3,line.length-3]
     end
     line=prepline(line)
     if !line[/^\#/] && !line[/^\s*$/]
       yield line, lineno
     end
     lineno+=1
  }
end

def pbCompilerEachPreppedLine(filename)
  File.open(filename,"rb"){|f|
     FileLineData.file=filename
     lineno=1
     f.each_line {|line|
        if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
          line=line[3,line.length-3]
        end
        line=prepline(line)
        if !line[/^\#/] && !line[/^\s*$/]
          FileLineData.setLine(line,lineno)
          yield line, lineno
        end
        lineno+=1
     }
  }
end

#===============================================================================
# Revisión de valores válidos
#===============================================================================
def pbCheckByte(x,valuename)
  if x<0 || x>255
    raise _INTL("El valor \"{1}\" debe estar entre 0 y 255 (0x00-0xFF en hex), se obtuvo un valor de {2}\r\n{3}",
       valuename,x,FileLineData.linereport)
  end
end

def pbCheckSignedByte(x,valuename)
  if x<-128 || x>127
    raise _INTL("El valor \"{1}\" debe estar entre -128 y 127, se obtuvo un valor de {2}\r\n{3}",
       valuename,x,FileLineData.linereport)
  end
end

def pbCheckWord(x,valuename)
  if x<0 || x>65535
    raise _INTL("El valor \"{1}\" debe estar entre 0 y 65535 (0x0000-0xFFFF en hex), se obtuvo un valor de {2}\r\n{3}",
       valuename,x,FileLineData.linereport)
  end
end

def pbCheckSignedWord(x,valuename)
  if x<-32768 || x>32767
    raise _INTL("El valor \"{1}\" debe estar entre -32768 y 32767, se obtuvo un valor de {2}\r\n{3}",
       valuename,x,FileLineData.linereport)
  end
end

#===============================================================================
# Análisis csv
#===============================================================================
def csvfield!(str)
  ret=""
  str.sub!(/^\s*/,"")
  if str[0,1]=="\""
    str[0,1]=""
    escaped=false
    fieldbytes=0
    str.scan(/./) do |s|
      fieldbytes+=s.length
      break if s=="\"" && !escaped
      if s=="\\" && !escaped
        escaped=true
      else
        ret+=s
        escaped=false
      end
    end
    str[0,fieldbytes]=""
    if !str[/^\s*,/] && !str[/^\s*$/] 
      raise _INTL("Campo entrecomillado inválido (en: {1})\r\n{2}",str,FileLineData.linereport)
    end
    str[0,str.length]=$~.post_match
  else
    if str[/,/]
      str[0,str.length]=$~.post_match
      ret=$~.pre_match
    else
      ret=str.clone
      str[0,str.length]=""
    end
    ret.gsub!(/\s+$/,"")
  end
  return ret
end

def csvquote(str)
  return "" if !str || str==""
  if str[/[,\"]/] #|| str[/^\s/] || str[/\s$/] || str[/^#/]
    str=str.gsub(/[\"]/,"\\\"")
    str="\"#{str}\""
  end
  return str
end

def csvBoolean!(str,line=-1)
  field=csvfield!(str)
  if field[/^1|[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]$/]
    return true
  elsif field[/^0|[Ff][Aa][Ll][Ss][Ee]|[Nn][Oo]$/]
    return false
  else
    raise _INTL("El campo {1} no tiene un valor booleano (true, false, 1, 0)\r\n{2}",field,FileLineData.linereport)
    return false
  end
end

def csvInt!(str,line=-1)
  ret=csvfield!(str)
  if !ret[/^\-?\d+$/]
    raise _INTL("El campo {1} no tiene un valor entero\r\n{2}",ret,FileLineData.linereport)
  end
  return ret.to_i
end

def csvPosInt!(str,line=-1)
  ret=csvfield!(str)
  if !ret[/^\d+$/]
    raise _INTL("El campo {1} no tiene un valor entero positivo\r\n{2}",ret,FileLineData.linereport)
  end
  return ret.to_i
end

def csvFloat!(str,key,section)
  ret=csvfield!(str)
  return Float(ret) rescue raise _INTL("El campo {1} no tiene un valor numérico\r\n{2}",ret,FileLineData.linereport)
end

def csvEnumField!(value,enumer,key,section)
  ret=csvfield!(value)
  return checkEnumField(ret,enumer)
end

def csvEnumFieldOrInt!(value,enumer,key,section)
  ret=csvfield!(value)
  if ret[/\-?\d+/]
    return ret.to_i
  end
  return checkEnumField(ret,enumer)
end

def checkEnumField(ret,enumer)
  if enumer.is_a?(Module)
    begin
      if ret=="" || !enumer.const_defined?(ret)
        raise _INTL("Valor indefinido {1} en {2}\r\n{3}",ret,enumer.name,FileLineData.linereport)
      end
    rescue NameError
      raise _INTL("Valor incorrecto {1} en {2}\r\n{3}",ret,enumer.name,FileLineData.linereport)
    end
    return enumer.const_get(ret.to_sym)
  elsif enumer.is_a?(Symbol) || enumer.is_a?(String)
    enumer=Object.const_get(enumer.to_sym)
    begin
      if ret=="" || !enumer.const_defined?(ret)
        raise _INTL("Valor indefinido {1} en {2}\r\n{3}",ret,enumer.name,FileLineData.linereport)
      end
    rescue NameError
      raise _INTL("Valor incorrecto {1} en {2}\r\n{3}",ret,enumer.name,FileLineData.linereport)
    end
    return enumer.const_get(ret.to_sym)
  elsif enumer.is_a?(Array)
    idx=findIndex(enumer){|item| ret==item}
    if idx<0
      raise _INTL("Valor indefinido {1} (se esperaba uno de: {2})\r\n{3}",ret,enumer.inspect,FileLineData.linereport)
    end
    return idx
  elsif enumer.is_a?(Hash)
    value=enumer[ret]
    if value==nil
      raise _INTL("Valor incorrecto {1} (se esperaba uno de: {2})\r\n{3}",ret,enumer.keys.inspect,FileLineData.linereport)
    end
    return value
  end
  raise _INTL("Enumeración no definida\r\n{1}",FileLineData.linereport)
end

#===============================================================================
# Lectura/escritura de registros csv
#===============================================================================
def pbGetCsvRecord(rec,lineno,schema)
  record=[]
  repeat=false
  if schema[1][0,1]=="*"
    repeat=true
    start=1
  else
    repeat=false
    start=0
  end
  begin
    for i in start...schema[1].length
      chr=schema[1][i,1]
      case chr
      when "u"
        record.push(csvPosInt!(rec,lineno))
      when "v"
        field=csvPosInt!(rec,lineno)
        raise _INTL("El campo '{1}' debe ser mayor que 0\r\n{2}",field,FileLineData.linereport) if field==0
        record.push(field)
      when "i"
        record.push(csvInt!(rec,lineno))
      when "U", "I"
        field=csvfield!(rec)
        if field==""
          record.push(nil)
        elsif !field[/^\d+$/]
          raise _INTL("El campo '{1}' debe ser 0 o mayor\r\n{2}",field,FileLineData.linereport)
        else
          record.push(field.to_i)
        end
      when "x"
        field=csvfield!(rec)     
        if !field[/^[A-Fa-f0-9]+$/]
          raise _INTL("El campo '{1}' no es un número hexadecimal\r\n{2}",field,FileLineData.linereport)
        end
        record.push(field.hex)
      when "s"
        record.push(csvfield!(rec))
      when "S"
        field=csvfield!(rec)
        if field==""
          record.push(nil)
        else
          record.push(field)
        end
      when "n" # Name
        field=csvfield!(rec)
        if !field[/^(?![0-9])\w+$/]
          raise _INTL("El campo '{1}' solo debe contener letras, números y\r\nguiones bajos, sin iniciar con un número.\r\n{2}",field,FileLineData.linereport)
        end
        record.push(field)
      when "N" # Optional name
        field=csvfield!(rec)
        if field==""
          record.push(nil)
        else
          if !field[/^(?![0-9])\w+$/]
            raise _INTL("El campo '{1}' solo debe contener letras, números y\r\nguiones bajos, sin iniciar con un número.\r\n{2}",field,FileLineData.linereport)
          end
          record.push(field)
        end
      when "b"
        record.push(csvBoolean!(rec,lineno))
      when "e"
        record.push(csvEnumField!(rec,schema[2+i-start],"",FileLineData.linereport))
      end
    end
    break if repeat && rec==""
  end while repeat
  return (schema[1].length==1) ? record[0] : record
end

def pbWriteCsvRecord(record,file,schema)
  if !record.is_a?(Array)
    rec=[record]
  else
    rec=record.clone
  end
  for i in 0...schema[1].length
    chr=schema[1][i,1]
    file.write(",") if i>0 
    if rec[i].nil?
      # do nothing
    elsif rec[i].is_a?(String)
      file.write(csvquote(rec[i]))
    elsif rec[i]==true
      file.write("true")
    elsif rec[i]==false
      file.write("false")
    elsif rec[i].is_a?(Numeric)
      case chr
      when "e"
        enumer=schema[2+i]
        if enumer.is_a?(Array)
          file.write(enumer[rec[i]])
        elsif enumer.is_a?(Symbol) || enumer.is_a?(String)
          mod=Object.const_get(enumer.to_sym)
          if enumer.to_s=="PBTrainers" && !mod.respond_to?("getCount")
            file.write((getConstantName(mod,rec[i]) rescue pbGetTrainerConst(rec[i])))
          else
            file.write(getConstantName(mod,rec[i]))
          end
        elsif enumer.is_a?(Module)
          file.write(getConstantName(enumer,rec[i]))
        elsif enumer.is_a?(Hash)
          for key in enumer.keys
            if enumer[key]==rec[i]
              file.write(key)
              break
            end
          end
        end
      else
        file.write(rec[i].inspect)
      end
    else
      file.write(rec[i].inspect)
    end
  end
  return record
end

#===============================================================================
# Cifrado y decrifrado
#===============================================================================
def intSize(value)
  return 1 if value<0x80
  return 2 if value<0x4000
  return 3 if value<0x200000
  return 4 if value<0x10000000
  return 5
end

def encodeInt(strm,value)
  num=0
  loop do
    if value<0x80
      strm.fputb(value)
      return num+1
    end
    strm.fputb(0x80|(value&0x7F))
    value>>=7
    num+=1
  end
end

def decodeInt(strm)
  bits=0
  curbyte=0
  ret=0
  begin
    curbyte=strm.fgetb
    ret+=(curbyte&0x7F)<<bits
    bits+=7
  end while(((curbyte&0x80)>0)&&bits<0x1d)
  return ret
end

def strSize(str)
  return str.length+intSize(str.length)
end

def encodeString(strm,str)
  encodeInt(strm,str.length)
  strm.write(str)
end

def decodeString(strm)
  len=decodeInt(strm)
  return strm.read(len)
end

def strsplit(str,re)
  ret=[]
  tstr=str
  while re=~tstr
    ret[ret.length]=$~.pre_match
    tstr=$~.post_match
  end
  ret[ret.length]=tstr if ret.length
  return ret
end

def canonicalize(c)
  csplit=strsplit(c,/[\/\\]/)
  pos=-1
  ret=[]
  retstr=""
  for x in csplit
    if x=="."
    elsif x==".."
      ret.delete_at(pos) if pos>=0
      pos-=1
    else
      ret.push(x)
      pos+=1
    end
  end
  for i in 0...ret.length
    retstr+="/" if i>0
    retstr+=ret[i]
  end
  return retstr
end

def frozenArrayValue(arr)
  typestring=""
  for i in 0...arr.length
    if i>0
      typestring+=((i%20)==0) ? ",\r\n" : ","
    end
    typestring+=arr[i].to_s
  end
  return "["+typestring+"].freeze"
end

#===============================================================================
# Enum const manipulators and parsers
#===============================================================================
def pbGetConst(mod,item,err)
  isdef=false
  begin
    isdef=mod.const_defined?(item.to_sym)
  rescue
    raise sprintf(err,item)
  end
  raise sprintf(err,item) if !isdef
  return mod.const_get(item.to_sym)
end

def removeConstantValue(mod,value)
  for c in mod.constants
    if mod.const_get(c.to_sym)==value
      mod.send(:remove_const,c.to_sym)
    end
  end
end

def setConstantName(mod,value,name)
  for c in mod.constants
    if mod.const_get(c.to_sym)==value
      mod.send(:remove_const,c.to_sym)
    end
  end
  mod.const_set(name,value)
end

def getConstantName(mod,value)
  for c in mod.constants
    return c if mod.const_get(c.to_sym)==value
  end
  raise _INTL("El valor {1} no está definido como una constante en {2}",value,mod.name)
end

def parseItem(item)
  clonitem=item.upcase
  clonitem.sub!(/^\s*/){}
  clonitem.sub!(/\s*$/){}
  return pbGetConst(PBItems,clonitem,
     _INTL("Nombre de constante de objeto indefinido: %s\r\nEl nombre sólo consiste en letras, números y\r\nguiones bajos y no puede iniciar con un número.\r\nAsegúrate de que el objeto está definido en\r\nPBS/items.txt.\r\n{1}",
     FileLineData.linereport))
end

def parseSpecies(item)
  clonitem=item.upcase
  clonitem.gsub!(/^[\s\n]*/){}
  clonitem.gsub!(/[\s\n]*$/){}
  clonitem="NIDORANmA" if clonitem=="NIDORANMA"
  clonitem="NIDORANfE" if clonitem=="NIDORANFE"
  return pbGetConst(PBSpecies,clonitem,_INTL("Nombre de constante de especie indefinido: [%s]\r\nEl nombre sólo consiste en letras, números y\r\nguiones bajos y no puede iniciar con un número.\r\nAsegúrate de que el objeto está definido en\r\nPBS/pokemon.txt.\r\n{1}",FileLineData.linereport))
end

def parseMove(item)
  clonitem=item.upcase
  clonitem.sub!(/^\s*/){}
  clonitem.sub!(/\s*$/){}
  return pbGetConst(PBMoves,clonitem,_INTL("Nombre de constante de movimiento indefinido: %s\r\nEl nombre sólo consiste en letras, números y\r\nguiones bajos y no puede iniciar con un número.\r\nAsegúrate de que el objeto está definido en\r\nPBS/moves.txt.\r\n{1}",FileLineData.linereport))
end

def parseNature(item)
  clonitem=item.upcase
  clonitem.sub!(/^\s*/){}
  clonitem.sub!(/\s*$/){}
  return pbGetConst(PBNatures,clonitem,_INTL("Nombre de constante de naturaleza indefinido: %s\r\nEl nombre sólo consiste en letras, números y\r\nguiones bajos y no puede iniciar con un número.\r\nAsegúrate de que el objeto está definido en\r\nla sección del script PBNatures.\r\n{1}",FileLineData.linereport))
end

def parseTrainer(item)
  clonitem=item.clone
  clonitem.sub!(/^\s*/){}
  clonitem.sub!(/\s*$/){}
  return pbGetConst(PBTrainers,clonitem,_INTL("Nombre de constante de Entrenador indefinido: %s\r\nEl nombre sólo consiste en letras, números y\r\nguiones bajos y no puede iniciar con un número.\r\nAsegúrate de que el objeto está definido en\r\ntrainertypes.txt.\r\n{1}",FileLineData.linereport))
end

#===============================================================================
# Constantes definidas en un script
#===============================================================================
def pbFindScript(a,name)
  a.each{|i| 
     next if !i
     return i if i[1]==name
  }
  return nil
end

def pbAddScript(script,sectionname)
  begin
    scripts=load_data("Data/Constants.rxdata")
    scripts=[] if !scripts
  rescue
    scripts=[]
  end
  s=pbFindScript(scripts,sectionname)
  if s
    s[2]=Zlib::Deflate.deflate("#{script}\r\n")
  else
    scripts.push([rand(100000000),sectionname,Zlib::Deflate.deflate("#{script}\r\n")])
  end
  save_data(scripts,"Data/Constants.rxdata")
end



#===============================================================================
# Serial record
#===============================================================================
class SerialRecord < Array
  def bytesize
    return SerialRecord.bytesize(self)
  end

  def encode(strm)
    return SerialRecord.encode(self,strm)
  end

  def self.bytesize(arr)
    ret=0
    return 0 if !arr
    for field in arr
      if field==nil || field==true || field==false
        ret+=1
      elsif field.is_a?(String)
        ret+=strSize(field)+1
      elsif field.is_a?(Numeric)
        ret+=intSize(field)+1
      end
    end
    return ret
  end

  def self.encode(arr,strm)
    return if !arr
    for field in arr
      if field==nil
        strm.write("0")
      elsif field==true
        strm.write("T")
      elsif field==false
        strm.write("F")
      elsif field.is_a?(String)
        strm.write("\"")
        encodeString(strm,field)
      elsif field.is_a?(Numeric)
        strm.write("i")
        encodeInt(strm,field)
      end
    end
  end

  def self.decode(strm,offset,length)
    ret=SerialRecord.new
    strm.pos=offset
    while strm.pos<offset+length
      datatype=strm.read(1)
      case datatype
      when "0"
        ret.push(nil)
      when "T"
        ret.push(true)
      when "F"
        ret.push(false)
      when "\""
        ret.push(decodeString(strm))
      when "i"
        ret.push(decodeInt(strm))
      end
    end
    return ret
  end
end



def readSerialRecords(filename)
  ret=[]
  if !pbRgssExists?(filename)
    return ret
  end
  pbRgssOpen(filename,"rb"){|file|
     numrec=file.fgetdw>>3
     curpos=0
     for i in 0...numrec
       file.pos=curpos
       offset=file.fgetdw
       length=file.fgetdw
       record=SerialRecord.decode(file,offset,length)
       ret.push(record)
       curpos+=8
     end
  }
  return ret
end

def writeSerialRecords(filename,records)
  File.open(filename,"wb"){|file|
     totalsize=records.length*8
     for record in records
       file.fputdw(totalsize)
       bytesize=record.bytesize
       file.fputdw(bytesize)
       totalsize+=bytesize
     end
     for record in records
       record.encode(file)
     end
  }
end



#===============================================================================
# Estructuras de datos
#===============================================================================
class ByteArray
  include Enumerable

  def initialize(data=nil)
    @a=(data) ? data.unpack("C*") : []
  end

  def []=(i,value)
    @a[i]=value
  end

  def [](i)
    return @a[i]
  end

  def length; @a.length; end
  def size; @a.size; end

  def fillNils(length,value)
    for i in 0...length
      @a[i]=value if !@a[i]
    end
  end

  def each
    @a.each {|i| yield i}
  end

  def self._load(str)
    return self.new(str)
  end

  def _dump(depth=100)
    return @a.pack("C*")
  end
end



class WordArray
  include Enumerable

  def initialize(data=nil)
    @a=(data) ? data.unpack("v*") : []
  end

  def []=(i,value)
    @a[i]=value
  end

  def [](i)
    return @a[i]
  end

  def length; @a.length; end
  def size; @a.size; end

  def fillNils(length,value)
    for i in 0...length
      @a[i]=value if !@a[i]
    end
  end

  def each
    @a.each {|i| yield i}
  end

  def self._load(str)
    return self.new(str)
  end

  def _dump(depth=100)
    return @a.pack("v*")
  end
end



class SignedWordArray
  include Enumerable

  def initialize(data=nil)
    @a=(data) ? data.unpack("v*") : []
  end

  def []=(i,value)
    @a[i]=value
  end

  def [](i)
    v=@a[i]
    return v<0x8000 ? v : -((~v)&0xFFFF)-1
  end

  def length; @a.length; end
  def size; @a.size; end

  def fillNils(length,value)
    for i in 0...length
      @a[i]=value if !@a[i]
    end
  end

  def each
    @a.each {|i| yield i}
  end

  def self._load(str)
    return self.new(str)
  end

  def _dump(depth=100)
    return @a.pack("v*")
  end
end



#===============================================================================
# Compilación de tipos
#===============================================================================
def pbWriteDefaultTypes
  if !safeExists?("PBS/types.txt")
    File.open("PBS/types.txt","w"){|f|
       f.write(0xEF.chr)
       f.write(0xBB.chr)
       f.write(0xBF.chr)
fx=<<END
[0]
Name=Normal
InternalName=NORMAL
Weaknesses=FIGHTING
Immunities=GHOST

[1]
Name=Lucha
InternalName=FIGHTING
Weaknesses=FLYING,PSYCHIC
Resistances=ROCK,BUG,DARK

[2]
Name=Volador
InternalName=FLYING
Weaknesses=ROCK,ELECTRIC,ICE
Resistances=FIGHTING,BUG,GRASS
Immunities=GROUND

[3]
Name=Veneno
InternalName=POISON
Weaknesses=GROUND,PSYCHIC
Resistances=FIGHTING,POISON,BUG,GRASS

[4]
Name=Tierra
InternalName=GROUND
Weaknesses=WATER,GRASS,ICE
Resistances=POISON,ROCK
Immunities=ELECTRIC

[5]
Name=Roca
InternalName=ROCK
Weaknesses=FIGHTING,GROUND,STEEL,WATER,GRASS
Resistances=NORMAL,FLYING,POISON,FIRE

[6]
Name=Bicho
InternalName=BUG
Weaknesses=FLYING,ROCK,FIRE
Resistances=FIGHTING,GROUND,GRASS

[7]
Name=Fantasma
InternalName=GHOST
Weaknesses=GHOST,DARK
Resistances=POISON,BUG
Immunities=NORMAL,FIGHTING

[8]
Name=Acero
InternalName=STEEL
Weaknesses=FIGHTING,GROUND,FIRE
Resistances=NORMAL,FLYING,ROCK,BUG,GHOST,STEEL,GRASS,PSYCHIC,ICE,DRAGON,DARK
Immunities=POISON

[9]
Name=???
InternalName=QMARKS
IsPseudoType=true

[10]
Name=Fuego
InternalName=FIRE
IsSpecialType=true
Weaknesses=GROUND,ROCK,WATER
Resistances=BUG,STEEL,FIRE,GRASS,ICE

[11]
Name=Agua
InternalName=WATER
IsSpecialType=true
Weaknesses=GRASS,ELECTRIC
Resistances=STEEL,FIRE,WATER,ICE

[12]
Name=Planta
InternalName=GRASS
IsSpecialType=true
Weaknesses=FLYING,POISON,BUG,FIRE,ICE
Resistances=GROUND,WATER,GRASS,ELECTRIC

[13]
Name=Eléctrico
InternalName=ELECTRIC
IsSpecialType=true
Weaknesses=GROUND
Resistances=FLYING,STEEL,ELECTRIC

[14]
Name=Psíquico
InternalName=PSYCHIC
IsSpecialType=true
Weaknesses=BUG,GHOST,DARK
Resistances=FIGHTING,PSYCHIC

[15]
Name=Hielo
InternalName=ICE
IsSpecialType=true
Weaknesses=FIGHTING,ROCK,STEEL,FIRE
Resistances=ICE

[16]
Name=Dragón
InternalName=DRAGON
IsSpecialType=true
Weaknesses=ICE,DRAGON
Resistances=FIRE,WATER,GRASS,ELECTRIC

[17]
Name=Siniestro
InternalName=DARK
IsSpecialType=true
Weaknesses=FIGHTING,BUG
Resistances=GHOST,DARK
Immunities=PSYCHIC

END
       f.write(fx)
    }
  end
end

def pbCompileTypes
  pbWriteDefaultTypes
  sections=[]
  typechart=[]
  types=[]
  nameToType={}
  requiredtypes={
     "Name"=>[1,"s"],
     "InternalName"=>[2,"s"],
  }
  optionaltypes={
     "IsPseudoType"=>[3,"b"],
     "IsSpecialType"=>[4,"b"],
     "Weaknesses"=>[5,"*s"],
     "Resistances"=>[6,"*s"],
     "Immunities"=>[7,"*s"]
  }
  currentmap=-1
  foundtypes=[]
  pbCompilerEachCommentedLine("PBS/types.txt") {|line,lineno|
     if line[/^\s*\[\s*(\d+)\s*\]\s*$/]
       sectionname=$~[1]
       if currentmap>=0
         for reqtype in requiredtypes.keys
           if !foundtypes.include?(reqtype)
             raise _INTL("El valor obligatorio '{1}' no ha sido indicado en la sección '{2}'\r\n{3}",reqtype,currentmap,FileLineData.linereport)
           end
         end
         foundtypes.clear
       end
       currentmap=sectionname.to_i
       types[currentmap]=[currentmap,nil,nil,false,false,[],[],[]]
     else
       if currentmap<0
         raise _INTL("Se esperaba una sección al inicio del archivo\r\n{1}",FileLineData.linereport)
       end
       if !line[/^\s*(\w+)\s*=\s*(.*)$/]
         raise _INTL("Sintaxis de línea errónea (se esperaba línea con formato XXX=YYY)\r\n{1}",FileLineData.linereport)
       end
       matchData=$~
       schema=nil
       FileLineData.setSection(currentmap,matchData[1],matchData[2])
       if requiredtypes.keys.include?(matchData[1])
         schema=requiredtypes[matchData[1]]
         foundtypes.push(matchData[1])
       else
         schema=optionaltypes[matchData[1]]
       end
       if schema
         record=pbGetCsvRecord(matchData[2],lineno,schema)
         types[currentmap][schema[0]]=record
       end
     end
  }
  types.compact!
  maxValue=0
  for type in types; maxValue=[maxValue,type[0]].max; end
  pseudotypes=[]
  specialtypes=[]
  typenames=[]
  typeinames=[]
  typehash={}
  for type in types
    pseudotypes.push(type[0]) if type[3]
    typenames[type[0]]=type[1]
    typeinames[type[0]]=type[2]
    typehash[type[0]]=type
  end
  for type in types
    n=type[1]
    for w in type[5]; if !typeinames.include?(w)
      raise _INTL("'{1}' no es un tipo definido (PBS/types.txt, {2}, Weaknesses/Debilidades)",w,n)
    end; end
    for w in type[6]; if !typeinames.include?(w)
      raise _INTL("'{1}' no es un tipo definido (PBS/types.txt, {2}, Resistances/Resistencias)",w,n)
    end; end
    for w in type[7]; if !typeinames.include?(w)
      raise _INTL("'{1}' no es un tipo definido (PBS/types.txt, {2}, Immunities/Inmunidades)",w,n)
    end; end
  end
  for i in 0..maxValue
    pseudotypes.push(i) if !typehash[i]
  end
  pseudotypes.sort!
  for type in types; specialtypes.push(type[0]) if type[4]; end
  specialtypes.sort!
  MessageTypes.setMessages(MessageTypes::Types,typenames)
  code="class PBTypes\r\n"
  for type in types
    code+="#{type[2]}=#{type[0]}\r\n"
  end
  code+="def PBTypes.getName(id)\r\nreturn pbGetMessage(MessageTypes::Types,id)\r\nend\r\n"
  code+="def PBTypes.getCount; return #{types.length}; end\r\n"
  code+="def PBTypes.maxValue; return #{maxValue}; end\r\n"
  count=maxValue+1
  for i in 0...count
    type=typehash[i]
    j=0; k=i; while j<count
      typechart[k]=2
      atype=typehash[j]
      if type && atype
        typechart[k]=4 if type[5].include?(atype[2])    # Debilidades
        typechart[k]=1 if type[6].include?(atype[2])    # Resistencias
        typechart[k]=0 if type[7].include?(atype[2])    # Inmunidades
      end
      j+=1
      k+=count
    end
  end
  code+="end\r\n"
  eval(code)
  save_data([pseudotypes,specialtypes,typechart],"Data/types.dat")
  pbAddScript(code,"PBTypes")
  Graphics.update
end

#===============================================================================
# Compilación de los puntos del mapa de pueblos
#===============================================================================
def pbCompileTownMap
  nonglobaltypes={
     "Name"=>[0,"s"],
     "Filename"=>[1,"s"],
     "Point"=>[2,"uussUUUU"]
  }
  currentmap=-1
  rgnnames=[]
  placenames=[]
  placedescs=[]
  sections=[]
  pbCompilerEachCommentedLine("PBS/townmap.txt"){|line,lineno|
     if line[/^\s*\[\s*(\d+)\s*\]\s*$/]
       currentmap=$~[1].to_i
       sections[currentmap]=[]
     else
       if currentmap<0
         raise _INTL("Se esperaba una sección al inicio del archivo\r\n{1}",FileLineData.linereport)
       end
       if !line[/^\s*(\w+)\s*=\s*(.*)$/]
         raise _INTL("Sintaxis de línea errónea (se esperaba línea con formato XXX=YYY)\r\n{1}",FileLineData.linereport)
       end
       settingname=$~[1]
       schema=nonglobaltypes[settingname]
       if schema
         record=pbGetCsvRecord($~[2],lineno,schema)
         if settingname=="Name"
           rgnnames[currentmap]=record
         elsif settingname=="Point"
           placenames.push(record[2])
           placedescs.push(record[3])
           sections[currentmap][schema[0]]=[] if !sections[currentmap][schema[0]]
           sections[currentmap][schema[0]].push(record)
         else   # Filename
           sections[currentmap][schema[0]]=record
         end
       end
     end
  }
  File.open("Data/townmap.dat","wb"){|f|
     Marshal.dump(sections,f)
  }
  MessageTypes.setMessages(
     MessageTypes::RegionNames,rgnnames
  )
  MessageTypes.setMessagesAsHash(
     MessageTypes::PlaceNames,placenames
  )
  MessageTypes.setMessagesAsHash(
     MessageTypes::PlaceDescriptions,placedescs
  )
end

#===============================================================================
# Compilación de las conexiones de los mapas
#===============================================================================
def pbCompileConnections
  records=[]
  constants=""
  itemnames=[]
  pbCompilerEachPreppedLine("PBS/connections.txt"){|line,lineno|
     hashenum={
        "N"=>"N","North"=>"N",
        "E"=>"E","East"=>"E",
        "S"=>"S","South"=>"S",
        "W"=>"W","West"=>"W"
     }
     record=[]
     thisline=line.dup
     record.push(csvInt!(thisline,lineno))
     record.push(csvEnumFieldOrInt!(thisline,hashenum,"",sprintf("(line %d)",lineno)))
     record.push(csvInt!(thisline,lineno))
     record.push(csvInt!(thisline,lineno))
     record.push(csvEnumFieldOrInt!(thisline,hashenum,"",sprintf("(line %d)",lineno)))
     record.push(csvInt!(thisline,lineno))          
     if !pbRgssExists?(sprintf("Data/Map%03d.rxdata",record[0])) &&
        !pbRgssExists?(sprintf("Data/Map%03d.rvdata",record[0]))
       print _INTL("Aviso: El mapa {1}, mencionado en los datos\r\nde conexiones de mapas, no ha sido encontrado.\r\n{2}",record[0],FileLineData.linereport)
     end
     if !pbRgssExists?(sprintf("Data/Map%03d.rxdata",record[3])) &&
        !pbRgssExists?(sprintf("Data/Map%03d.rvdata",record[3]))
       print _INTL("Aviso: El mapa {1}, mencionado en los datos\r\nde conexiones de mapas, no ha sido encontrado.\r\n{2}",record[3],FileLineData.linereport)
     end
     case record[1]
     when "N"
       raise _INTL("El lado Norte del primer mapa debe conectarse con el lado Sur del segundo\r\n{1}",FileLineData.linereport) if record[4]!="S"
     when "S"
       raise _INTL("El lado Sur del primer mapa debe conectarse con el lado Norte del segundo\r\n{1}",FileLineData.linereport) if record[4]!="N"
     when "E"
       raise _INTL("El lado Este del primer mapa debe conectarse con el lado Oeste del segundo\r\n{1}",FileLineData.linereport) if record[4]!="W"
     when "W"
       raise _INTL("El lado Oeste del primer mapa debe conectarse con el lado Este del segundo\r\n{1}",FileLineData.linereport) if record[4]!="E"
     end
     records.push(record)
  }
  save_data(records,"Data/connections.dat")
  Graphics.update
end

#===============================================================================
# Compilación de las habilidades
#===============================================================================
def pbCompileAbilities
  records=[]
  movenames=[]
  movedescs=[]
  maxValue=0
  pbCompilerEachPreppedLine("PBS/abilities.txt"){|line,lineno|
     record=pbGetCsvRecord(line,lineno,[0,"vnss"])
     movenames[record[0]]=record[2]
     movedescs[record[0]]=record[3]
     maxValue=[maxValue,record[0]].max
     records.push(record)
  }
  MessageTypes.setMessages(MessageTypes::Abilities,movenames)
  MessageTypes.setMessages(MessageTypes::AbilityDescs,movedescs)
  code="class PBAbilities\r\n"
  for rec in records
    code+="#{rec[1]}=#{rec[0]}\r\n"
  end
  code+="\r\ndef PBAbilities.getName(id)\r\nreturn pbGetMessage(MessageTypes::Abilities,id)\r\nend"
  code+="\r\ndef PBAbilities.getCount\r\nreturn #{records.length}\r\nend\r\n"
  code+="\r\ndef PBAbilities.maxValue\r\nreturn #{maxValue}\r\nend\r\nend"
  eval(code)
  pbAddScript(code,"PBAbilities")
end

#===============================================================================
# Compilación de los datos de los movimientos
#===============================================================================
class PBMoveDataOld
  attr_reader :function,:basedamage,:type,:accuracy
  attr_reader :totalpp,:addlEffect,:target,:priority
  attr_reader :flags
  attr_reader :category

  def initialize(moveid)
    movedata=pbRgssOpen("Data/rsattacks.dat")
    movedata.pos=moveid*9
    @function=movedata.fgetb
    @basedamage=movedata.fgetb
    @type=movedata.fgetb
    @accuracy=movedata.fgetb
    @totalpp=movedata.fgetb
    @addlEffect=movedata.fgetb
    @target=movedata.fgetb
    @priority=movedata.fgetsb
    @flags=movedata.fgetb
    movedata.close
  end

  def category
    return 2 if @basedamage==0
    return @type<10 ? 0 : 1
  end
end



def pbCompileMoves
  records=[]
  movenames=[]
  movedescs=[]
  movedata=[]
  maxValue=0
  pbCompilerEachPreppedLine("PBS/moves.txt"){|line,lineno|
     thisline=line.clone
     record=[]
     flags=0
     begin
       record=pbGetCsvRecord(line,lineno,[0,"vnsxueeuuuxiss",
          nil,nil,nil,nil,nil,PBTypes,["Physical","Special","Status"],
          nil,nil,nil,nil,nil,nil,nil
       ])
       pbCheckWord(record[3],_INTL("Function code"))
       flags|=1 if record[12][/a/]
       flags|=2 if record[12][/b/]
       flags|=4 if record[12][/c/]
       flags|=8 if record[12][/d/]
       flags|=16 if record[12][/e/]
       flags|=32 if record[12][/f/]
       flags|=64 if record[12][/g/]
       flags|=128 if record[12][/h/]
       flags|=256 if record[12][/i/]
       flags|=512 if record[12][/j/]
       flags|=1024 if record[12][/k/]
       flags|=2048 if record[12][/l/]
       flags|=4096 if record[12][/m/]
       flags|=8192 if record[12][/n/]
       flags|=16384 if record[12][/o/]
       flags|=32768 if record[12][/p/]
     rescue
       oldmessage=$!.message
       raise if !pbRgssExists?("Data/rsattacks.dat")
       begin
         oldrecord=pbGetCsvRecord(thisline,lineno,[0,"unss",nil,nil,nil,nil])
       rescue
         raise $!.message+"\r\n"+oldmessage
       end
       oldmovedata=PBMoveDataOld.new(oldrecord[0])
       flags=oldmovedata.flags
       record=[oldrecord[0],oldrecord[1],oldrecord[2],
          oldmovedata.function,
          oldmovedata.basedamage,
          oldmovedata.type,
          oldmovedata.category,
          oldmovedata.accuracy,
          oldmovedata.totalpp,
          oldmovedata.addlEffect,
          oldmovedata.target,
          oldmovedata.priority,
          oldmovedata.flags,
          0,                        # No contest type defined
          oldrecord[3]]
     end
     pbCheckWord(record[3],_INTL("Function code"))
     pbCheckByte(record[4],_INTL("Base damage"))
     if record[6]==2 && record[4]!=0
       raise _INTL("Los movimientos de Estado deben tener daño base de 0, use Físico o Especial\r\n{1}",FileLineData.linereport)
     end
     if record[6]!=2 && record[4]==0
       print _INTL("Aviso: Los movimientos Físicos o Especiales no pueden tener daño base de 0, se cambia a movimientos de Estado\r\n{1}",FileLineData.linereport)
       record[6]=2
     end
     pbCheckByte(record[7],_INTL("Accuracy"))
     pbCheckByte(record[8],_INTL("Total PP"))
     pbCheckByte(record[9],_INTL("Additional Effect"))
     pbCheckWord(record[10],_INTL("Target"))
     pbCheckSignedByte(record[11],_INTL("Priority"))
     maxValue=[maxValue,record[0]].max
     movedata[record[0]]=[
        record[3],  # Código de función
        record[4],  # Daño
        record[5],  # Tipo
        record[6],  # Categoría
        record[7],  # Precisión
        record[8],  # PS totales
        record[9],  # Probabilidad del efecto
        record[10], # Objetivo
        record[11], # Prioridad
        flags,      # Banderas
        0           # Valor vacío, used to be contest type
     ].pack("vCCCCCCvCvC")
     movenames[record[0]]=record[2]  # Nombre
     movedescs[record[0]]=record[13] # Descripción
     records.push(record)
  }
  defaultdata=[0,0,0,0,0,0,0,0,0,0,0].pack("vCCCCCCvCvC")
  File.open("Data/moves.dat","wb"){|file|
     for i in 0...movedata.length
       file.write(movedata[i] ? movedata[i] : defaultdata)
     end
  }
  MessageTypes.setMessages(MessageTypes::Moves,movenames)
  MessageTypes.setMessages(MessageTypes::MoveDescriptions,movedescs)
  code="class PBMoves\r\n"
  for rec in records
    code+="#{rec[1]}=#{rec[0]}\r\n"
  end
  code+="\r\ndef PBMoves.getName(id)\r\nreturn pbGetMessage(MessageTypes::Moves,id)\r\nend"
  code+="\r\ndef PBMoves.getCount\r\nreturn #{records.length}\r\nend"
  code+="\r\ndef PBMoves.maxValue\r\nreturn #{maxValue}\r\nend\r\nend"
  eval(code)
  pbAddScript(code,"PBMoves")
end

#===============================================================================
# Compilación de los objetos
#===============================================================================
class ItemList
  include Enumerable

  def initialize; @list=[]; end
  def length; @list.length; end
  def []=(x,v); @list[x]=v; end
 
  def [](x)
    if !@list[x]
      defrecord=SerialRecord.new
      defrecord.push(0)
      defrecord.push("????????")
      defrecord.push(0)
      defrecord.push(0)
      defrecord.push("????????")
      @list[x]=defrecord
      return defrecord
    end
    return @list[x]
  end

  def each
    for i in 0...self.length
      yield self[i]
    end
  end
end



def readItemList(filename)
  ret=ItemList.new
  if !pbRgssExists?(filename)
    return ret
  end
  pbRgssOpen(filename,"rb"){|file|
     numrec=file.fgetdw>>3
     curpos=0
     for i in 0...numrec
       file.pos=curpos
       offset=file.fgetdw
       length=file.fgetdw
       record=SerialRecord.decode(file,offset,length)
       ret[record[0]]=record
       curpos+=8
     end
  }
  return ret
end

def pbCompileItems
  records=[]
  constants=""
  itemnames=[]
  itempluralnames=[]
  itemdescs=[]
  maxValue=0
  pbCompilerEachCommentedLine("PBS/items.txt"){|line,lineno|
     linerecord=pbGetCsvRecord(line,lineno,[0,"vnssuusuuUN"])
     record=SerialRecord.new
     record[ITEMID]        = linerecord[0]
     constant=linerecord[1]
     constants+="#{constant}=#{record[0]}\r\n"
     record[ITEMNAME]      = linerecord[2]
     itemnames[record[0]]=linerecord[2]
     record[ITEMPLURAL]    = linerecord[3]
     itempluralnames[record[0]]=linerecord[3]
     record[ITEMPOCKET]    = linerecord[4]
     record[ITEMPRICE]     = linerecord[5]
     record[ITEMDESC]      = linerecord[6]
     itemdescs[record[0]]=linerecord[6]
     record[ITEMUSE]       = linerecord[7]
     record[ITEMBATTLEUSE] = linerecord[8]
     record[ITEMTYPE]      = linerecord[9]
     if linerecord[9]!="" && linerecord[10]
       record[ITEMMACHINE] = parseMove(linerecord[10])
     else
       record[ITEMMACHINE] = 0
     end
     maxValue=[maxValue,record[0]].max
     records.push(record)
  }
  MessageTypes.setMessages(MessageTypes::Items,itemnames)
  MessageTypes.setMessages(MessageTypes::ItemPlurals,itempluralnames)
  MessageTypes.setMessages(MessageTypes::ItemDescriptions,itemdescs)
  writeSerialRecords("Data/items.dat",records)
  code="class PBItems\r\n#{constants}"
  code+="\r\ndef PBItems.getName(id)\r\nreturn pbGetMessage(MessageTypes::Items,id)\r\nend\r\n"
  code+="\r\ndef PBItems.getNamePlural(id)\r\nreturn pbGetMessage(MessageTypes::ItemPlurals,id)\r\nend\r\n"
  code+="\r\ndef PBItems.getCount\r\nreturn #{records.length}\r\nend\r\n"
  code+="\r\ndef PBItems.maxValue\r\nreturn #{maxValue}\r\nend\r\nend"
  eval(code)
  pbAddScript(code,"PBItems")
  Graphics.update
end

#===============================================================================
# Compilación de las plantas de bayas
#===============================================================================
def pbCompileBerryPlants
  sections=[]
  if File.exists?("PBS/berryplants.txt")
    pbCompilerEachCommentedLine("PBS/berryplants.txt"){|line,lineno|
       if line[ /^([^=]+)=(.*)$/ ]
         key=$1
         value=$2
         value=value.split(",")
         for i in 0...value.length
           value[i].sub!(/^\s*/){}
           value[i].sub!(/\s*$/){}
           value[i]=value[i].to_i
         end
         item=parseItem(key)
         sections[item]=value
       end
    }
  end
  save_data(sections,"Data/berryplants.dat")
end

#===============================================================================
# Compilación de los Pokémon
#===============================================================================
def pbCompilePokemonData
  # Bytes libres: 0, 1, 17, 29, 30, 37, 56-75
  sections=[]
  requiredtypes={
     "Name"=>[0,"s"],
     "Kind"=>[0,"s"],
     "InternalName"=>[0,"c"],
     "Pokedex"=>[0,"S"],
     "Moves"=>[0,"*uE",nil,PBMoves],
     "Color"=>[6,"e",PBColors],
     "Type1"=>[8,"e",PBTypes],
     "BaseStats"=>[10,"uuuuuu"],
     "Rareness"=>[16,"u"],
     "GenderRate"=>[18,"e",{"AlwaysMale"=>0,"FemaleOneEighth"=>31,
        "Female25Percent"=>63,"Female50Percent"=>127,"Female75Percent"=>191,
        "FemaleSevenEighths"=>223,"AlwaysFemale"=>254,"Genderless"=>255}],
     "Happiness"=>[19,"u"],
     "GrowthRate"=>[20,"e",{"Medium"=>0,"MediumFast"=>0,"Erratic"=>1,
        "Fluctuating"=>2,"Parabolic"=>3,"MediumSlow"=>3,"Fast"=>4,"Slow"=>5}],
     "StepsToHatch"=>[21,"w"],
     "EffortPoints"=>[23,"uuuuuu"],
     "Compatibility"=>[31,"eg",PBEggGroups,PBEggGroups],
     "Height"=>[33,"f"],
     "Weight"=>[35,"f"],
     "BaseEXP"=>[38,"w"],
  }
  optionaltypes={
     "BattlerPlayerY"=>[0,"i"],
     "BattlerEnemyY"=>[0,"i"],
     "BattlerAltitude"=>[0,"i"],
     "EggMoves"=>[0,"*E",PBMoves],
     "FormNames"=>[0,"S"],
     "RegionalNumbers"=>[0,"*w"],
     "Evolutions"=>[0,"*ses",nil,PBEvolution],
     "Abilities"=>[2,"EG",PBAbilities,PBAbilities],
     "Habitat"=>[7,"e",["","Grassland","Forest","WatersEdge","Sea","Cave","Mountain","RoughTerrain","Urban","Rare"]],
     "Type2"=>[9,"e",PBTypes],
     "HiddenAbility"=>[40,"EGGG",PBAbilities,PBAbilities,PBAbilities,PBAbilities],
     "WildItemCommon"=>[48,"E",PBItems],
     "WildItemUncommon"=>[50,"E",PBItems],
     "WildItemRare"=>[52,"E",PBItems],
     "Incense"=>[54,"E",PBItems]
  }
  currentmap=-1
  dexdatas=[]
  eggmoves=[]
  entries=[]
  kinds=[]
  speciesnames=[]
  moves=[]
  evolutions=[]
  regionals=[]
  formnames=[]
  metrics=[SignedWordArray.new,SignedWordArray.new,SignedWordArray.new]
  constants=""
  maxValue=0
  File.open("PBS/pokemon.txt","rb"){|f|
     FileLineData.file="PBS/pokemon.txt"
     pbEachFileSection(f){|lastsection,currentmap|
        dexdata=[]
        for i in 0...76
          dexdata[i]=0
        end
        thesemoves=[]
        theseevos=[]
        if !lastsection["Type2"] || lastsection["Type2"]==""
          if !lastsection["Type1"] || lastsection["Type1"]==""
            raise _INTL("No se ha definido el tipo del Pokémon en la sección {2} (PBS/pokemon.txt)",key,sectionDisplay) if hash==requiredtypes
            next
          end
          lastsection["Type2"]=lastsection["Type1"].clone
        end
        [requiredtypes,optionaltypes].each{|hash|
           for key in hash.keys
             FileLineData.setSection(currentmap,key,lastsection[key])
             maxValue=[maxValue,currentmap].max
             sectionDisplay=currentmap.to_s
             next if hash[key][0]<0
             if currentmap==0
               raise _INTL("Una especie Pokemon no puede ser enumerada en 0 (PBS/pokemon.txt)")
             end
             if !lastsection[key] || lastsection[key]==""
               raise _INTL("Un valor obligatorio {1} no ha sido encontrado o está en blanco en la sección {2} (PBS/pokemon.txt)",key,sectionDisplay) if hash==requiredtypes
               next
             end
             secvalue=lastsection[key]
             rtschema=hash[key]
             schema=hash[key][1]
             valueindex=0
             loop do
               offset=0
               for i in 0...schema.length
                 next if schema[i,1]=="*"
                 minus1=(schema[0,1]=="*") ? -1 : 0
                 if (schema[i,1]=="g" || schema[i,1]=="G") && secvalue==""
                   if key=="Compatibility"
                     dexdata[rtschema[0]+offset]=dexdata[rtschema[0]]
                   end
                   break
                 end
                 case schema[i,1]
                 when "e", "g"
                   value=csvEnumField!(secvalue,rtschema[2+i+minus1],key,sectionDisplay)
                   bytes=1
                 when "E", "G"
                   value=csvEnumField!(secvalue,rtschema[2+i+minus1],key,sectionDisplay)
                   bytes=2
                 when "i"
                   value=csvInt!(secvalue,key)
                   bytes=1
                 when "u"
                   value=csvPosInt!(secvalue,key)
                   bytes=1
                 when "w"
                   value=csvPosInt!(secvalue,key)
                   bytes=2
                 when "f"
                   value=csvFloat!(secvalue,key,sectionDisplay)
                   value=(value*10).round
                   if value<=0
                     raise _INTL("El valor '{1}' no puede ser menor que o igual a 0 (sección {2}, PBS/pokemon.txt)",key,currentmap)
                   end
                   bytes=2
                 when "c", "s"
                   value=csvfield!(secvalue)
                 when "S"
                   value=secvalue
                   secvalue=""
                 end
                 if key=="EggMoves"
                   eggmoves[currentmap]=[] if !eggmoves[currentmap]
                   eggmoves[currentmap].push(value)
                 elsif key=="Moves"
                   thesemoves.push(value)
                 elsif key=="RegionalNumbers"
                   regionals[valueindex]=[] if !regionals[valueindex]
                   regionals[valueindex][currentmap]=value
                 elsif key=="Evolutions"
                   theseevos.push(value)
                 elsif key=="InternalName"
                   raise _INTL("Nombre interno inválido: {1} (sección {2}, PBS/pokemon.txt)",value,currentmap) if !value[/^(?![0-9])\w*$/]
                   constants+="#{value}=#{currentmap}\r\n"
                 elsif key=="Kind"
                   raise _INTL("La clase {1} tiene más de 20 caracteres de longitud (sección {2}, PBS/pokemon.txt)",value,currentmap) if value.length>20
                   kinds[currentmap]=value
                 elsif key=="Pokedex"
                   entries[currentmap]=value
                 elsif key=="BattlerPlayerY"
                   pbCheckSignedWord(value,key)
                   metrics[0][currentmap]=value
                 elsif key=="BattlerEnemyY"
                   pbCheckSignedWord(value,key)
                   metrics[1][currentmap]=value
                 elsif key=="BattlerAltitude"
                   pbCheckSignedWord(value,key)
                   metrics[2][currentmap]=value
                 elsif key=="Name"
                   raise _INTL("El nombre de la especie {1} tiene más de 20 caracteres de longitud (sección {2}, PBS/pokemon.txt)",value,currentmap) if value.length>20
                   speciesnames[currentmap]=value
                 elsif key=="FormNames"
                   formnames[currentmap]=value
                 else
                   dexdata[rtschema[0]+offset]=value&0xFF
                   dexdata[rtschema[0]+1+offset]=(value>>8)&0xFF if bytes>1
                   offset+=bytes
                 end
                 valueindex+=1
               end
               break if secvalue==""
               break if schema[0,1]!="*"
             end
           end
        }
        movelist=[]
        evolist=[]
        for i in 0...thesemoves.length/2
          movelist.push([thesemoves[i*2],thesemoves[i*2+1],i])
        end
        movelist.sort!{|a,b| a[0]==b[0] ? a[2]<=>b[2] : a[0]<=>b[0]}
        for i in movelist; i.pop; end
        for i in 0...theseevos.length/3
          evolist.push([theseevos[i*3],theseevos[i*3+1],theseevos[i*3+2]])
        end
        moves[currentmap]=movelist
        evolutions[currentmap]=evolist
        dexdatas[currentmap]=dexdata
     }
  }
  if dexdatas.length==0
    raise _INTL("No se han definido especies de Pokémon en pokemon.txt")
  end
  count=dexdatas.compact.length
  code="module PBSpecies\r\n#{constants}"
  for i in 0...speciesnames.length
    speciesnames[i]="????????" if !speciesnames[i]
  end
  code+="def PBSpecies.getName(id)\r\nreturn pbGetMessage(MessageTypes::Species,id)\r\nend\r\n"
  code+="def PBSpecies.getCount\r\nreturn #{count}\r\nend\r\n"
  code+="def PBSpecies.maxValue\r\nreturn #{maxValue}\r\nend\r\nend"
  eval(code)
  pbAddScript(code,"PBSpecies")
  for e in 0...evolutions.length
    evolist=evolutions[e]
    next if !evolist
    for i in 0...evolist.length
      FileLineData.setSection(i,"Evolutions","")
      evonib=evolist[i][1]
      evolist[i][0]=csvEnumField!(evolist[i][0],PBSpecies,"Evolutions",i)
      case PBEvolution::EVOPARAM[evonib]
      when 1
        evolist[i][2]=csvPosInt!(evolist[i][2])
      when 2
        evolist[i][2]=csvEnumField!(evolist[i][2],PBItems,"Evolutions",i)
      when 3
        evolist[i][2]=csvEnumField!(evolist[i][2],PBMoves,"Evolutions",i)
      when 4
        evolist[i][2]=csvEnumField!(evolist[i][2],PBSpecies,"Evolutions",i)
      when 5
        evolist[i][2]=csvEnumField!(evolist[i][2],PBTypes,"Evolutions",i)
      else
        evolist[i][2]=0
      end
      evolist[i][3]=0
    end
  end
  _EVODATAMASK=0xC0
  _EVONEXTFORM=0x00
  _EVOPREVFORM=0x40
  for e in 0...evolutions.length
    evolist=evolutions[e]
    next if !evolist
    parent=nil
    child=-1
    for f in 0...evolutions.length
      evolist=evolutions[f]
      next if !evolist || e==f
      for g in evolist
        if g[0]==e && (g[3]&_EVODATAMASK)==_EVONEXTFORM
          parent=g
          child=f
          break
        end
      end
      break if parent
    end
    if parent
      evolutions[e]=[[child,parent[1],parent[2],_EVOPREVFORM]].concat(evolutions[e])
    end
  end
  metrics[0].fillNils(dexdatas.length,0) # Y del jugador
  metrics[1].fillNils(dexdatas.length,0) # Y del enemigo
  metrics[2].fillNils(dexdatas.length,0) # altitud
  save_data(metrics,"Data/metrics.dat")
  File.open("Data/regionals.dat","wb"){|f|
     f.fputw(regionals.length)
     f.fputw(dexdatas.length)
     for i in 0...regionals.length
       for j in 0...dexdatas.length
         num=regionals[i][j]
         num=0 if !num
         f.fputw(num)
       end
     end
  }
  File.open("Data/evolutions.dat","wb"){|f|
     mx=[maxValue,evolutions.length-1].max
     offset=mx*8
     for i in 1..mx
       f.fputdw(offset)
       f.fputdw(evolutions[i] ? evolutions[i].length*5 : 0)
       offset+=evolutions[i] ? evolutions[i].length*5 : 0
     end
     for i in 1..mx
       next if !evolutions[i]
       for j in evolutions[i]
         f.fputb(j[3]|j[1])
         f.fputw(j[2])
         f.fputw(j[0])
       end
     end
  }
  File.open("Data/dexdata.dat","wb"){|f|
     mx=[maxValue,dexdatas.length-1].max
     for i in 1..mx
       if dexdatas[i]
         dexdatas[i].each {|item| f.fputb(item)}
       else
         76.times { f.fputb(0) }
       end
     end
  }
  File.open("Data/eggEmerald.dat","wb"){|f|
     mx=[maxValue,eggmoves.length-1].max
     offset=mx*8
     for i in 1..mx
       f.fputdw(offset)
       f.fputdw(eggmoves[i] ? eggmoves[i].length : 0)
       offset+=eggmoves[i] ? eggmoves[i].length*2 : 0
     end
     for i in 1..mx
       next if !eggmoves[i]
       for j in eggmoves[i]
         f.fputw(j)
       end
     end
  }
  MessageTypes.setMessages(MessageTypes::Species,speciesnames)
  MessageTypes.setMessages(MessageTypes::Kinds,kinds)
  MessageTypes.setMessages(MessageTypes::Entries,entries)
  MessageTypes.setMessages(MessageTypes::FormNames,formnames)
  File.open("Data/attacksRS.dat","wb"){|f|
     mx=[maxValue,moves.length-1].max
     offset=mx*8
     for i in 1..mx
       f.fputdw(offset)
       f.fputdw(moves[i] ? moves[i].length*2 : 0)
       offset+=moves[i] ? moves[i].length*4 : 0
     end
     for i in 1..mx
       next if !moves[i]
       for j in moves[i]
         f.fputw(j[0])
         f.fputw(j[1])
       end
     end
  }
end

#===============================================================================
# Compilación de las compatibilidades de MT/MO/Tutor de Movimientos
#===============================================================================
def pbTMRS   # Copia de la lista de MT de la Gen 3
  rstm=[# MTs
        :FOCUSPUNCH,:DRAGONCLAW,:WATERPULSE,:CALMMIND,:ROAR,
        :TOXIC,:HAIL,:BULKUP,:BULLETSEED,:HIDDENPOWER,
        :SUNNYDAY,:TAUNT,:ICEBEAM,:BLIZZARD,:HYPERBEAM,
        :LIGHTSCREEN,:PROTECT,:RAINDANCE,:GIGADRAIN,:SAFEGUARD,
        :FRUSTRATION,:SOLARBEAM,:IRONTAIL,:THUNDERBOLT,:THUNDER,
        :EARTHQUAKE,:RETURN,:DIG,:PSYCHIC,:SHADOWBALL,
        :BRICKBREAK,:DOUBLETEAM,:REFLECT,:SHOCKWAVE,:FLAMETHROWER,
        :SLUDGEBOMB,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:AERIALACE,
        :TORMENT,:FACADE,:SECRETPOWER,:REST,:ATTRACT,
        :THIEF,:STEELWING,:SKILLSWAP,:SNATCH,:OVERHEAT,
        # MOs
        :CUT,:FLY,:SURF,:STRENGTH,:FLASH,:ROCKSMASH,:WATERFALL,:DIVE]
  ret=[]
  for i in 0...rstm.length
    ret.push((parseMove(rstm.to_s) rescue 0))
  end
  return ret
end

def pbCompileMachines
  lineno=1
  havesection=false
  sectionname=nil
  sections=[]
  if safeExists?("PBS/tm.txt")
    f=File.open("PBS/tm.txt","rb")
    FileLineData.file="PBS/tm.txt"
    f.each_line {|line|
       if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
         line=line[3,line.length-3]
       end
       FileLineData.setLine(line,lineno)
       if !line[/^\#/] && !line[/^\s*$/]
         if line[/^\s*\[\s*(.*)\s*\]\s*$/]
           sectionname=parseMove($~[1])
           sections[sectionname]=WordArray.new
           havesection=true
         else
           if sectionname==nil
             raise _INTL("Se esperaba una sección al inicio del archivo. Este error también puede ocurrir si el archivo no ha sido guardado en codificación UTF-8.\r\n{1}",FileLineData.linereport)
           end
           specieslist=line.sub(/\s+$/,"").split(",")
           for species in specieslist
             next if !species || species==""
             sec=sections[sectionname]
             sec[sec.length]=parseSpecies(species)
           end
         end
       end
       lineno+=1
       if lineno%500==0
         Graphics.update
       end
       if lineno%50==0
         Win32API.SetWindowText(_INTL("Procesando linea {1}",lineno))
       end
    }
    f.close
  elsif safeExists?("Data/tmRS.dat")
    tmrs=pbTMRS()
    for i in 0...58
      next if !tmrs[i] || tmrs[i]==0
      sections[tmrs[i]]=[]
    end
    File.open("Data/tmRS.dat","rb"){|f|
       species=1
       while !f.eof?
         data=f.read(8)+"\0\0\0\0\0\0\0\0"
         for i in 0...58
           next if !tmrs[i] || tmrs[i]==0
           if (data[i>>3]&(1<<(i&7)))!=0
             sections[tmrs[i]].push(species)
           end
         end
         species+=1
       end
    }
  end
  save_data(sections,"Data/tm.dat")
end

#===============================================================================
# Extracción de los tipos de entrenadores al archivo PBS, compilación de los
# tipos de entrenadores y entrenadores individuales
#===============================================================================
def pbExtractTrainers
  trainertypes=nil
  pbRgssOpen("Data/trainertypes.dat","rb"){|f|
     trainertypes=Marshal.load(f)
  }
  return if !trainertypes
  File.open("trainertypes.txt","wb"){|f|
     f.write(0xEF.chr)
     f.write(0xBB.chr)
     f.write(0xBF.chr)
     for i in 0...trainertypes.length
       next if !trainertypes[i]
       record=trainertypes[i]
       begin
         cnst=getConstantName(PBTrainers,record[0])
       rescue
         next
       end
       f.write(sprintf("%d,%s,%s,%d,%s,%s,%s,%s,%d,%s\r\n",
          record[0],csvquote(cnst),csvquote(record[2]),
          record[3],csvquote(record[4]),csvquote(record[5]),csvquote(record[6]),
          record[7] ? ["Male","Female","Mixed"][record[7]] : "Mixed",
          record[8],record[9]
       ))
     end
  }
end

def pbCompileTrainers
  # Tipos de entrenadores
  records=[]
  trainernames=[]
  count=0
  maxValue=0
  pbCompilerEachPreppedLine("PBS/trainertypes.txt"){|line,lineno|
     record=pbGetCsvRecord(line,lineno,[0,"unsUSSSeUS",     # ID puede ser 0
        nil,nil,nil,nil,nil,nil,nil,{
        ""=>2,"Male"=>0,"M"=>0,"0"=>0,"Female"=>1,"F"=>1,"1"=>1,"Mixed"=>2,"X"=>2,"2"=>2
        },nil,nil]
     )
     if record[3] && (record[3]<0 || record[3]>255)
       raise _INTL("Cantidad de dinero errónea (debe ser entre 0 y 255)\r\n{1}",FileLineData.linereport)
     end
     record[3]=30 if !record[3]
     if record[8] && (record[8]<0 || record[8]>255)
       raise _INTL("Valor de destreza erróneo (debe ser entre 0 y 255)\r\n{1}",FileLineData.linereport)
     end
     record[8]=record[3] if !record[8]
     if records[record[0]]
       raise _INTL("Hay dos tipos de entrenadores ({1} y {2}) con el mismo ID ({3}), lo que no está permitido.\r\n{4}",
          records[record[0]][1],record[1],record[0],FileLineData.linereport)
     end
     trainernames[record[0]]=record[2]
     records[record[0]]=record
     maxValue=[maxValue,record[0]].max
  }
  count=records.compact.length
  MessageTypes.setMessages(MessageTypes::TrainerTypes,trainernames)
  code="class PBTrainers\r\n"
  for rec in records
    next if !rec
    code+="#{rec[1]}=#{rec[0]}\r\n"
  end
  code+="\r\ndef self.getName(id)\r\nreturn pbGetMessage(MessageTypes::TrainerTypes,id)\r\nend"
  code+="\r\ndef self.getCount\r\nreturn #{count}\r\nend"
  code+="\r\ndef self.maxValue\r\nreturn #{maxValue}\r\nend\r\nend"
  eval(code)
  pbAddScript(code,"PBTrainers")
  File.open("Data/trainertypes.dat","wb"){|f|
     Marshal.dump(records,f)
  }
  # Entrenadores individuales
  lines=[]
  linenos=[]
  lineno=1
  File.open("PBS/trainers.txt","rb"){|f|
     FileLineData.file="PBS/trainers.txt"
     f.each_line {|line|
        if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
          line=line[3,line.length-3]
        end
        line=prepline(line)
        if line!=""
          lines.push(line)
          linenos.push(lineno)
        end
        lineno+=1
     }
  }
  nameoffset=0
  trainers=[]
  trainernames.clear
  i=0; loop do break unless i<lines.length
    FileLineData.setLine(lines[i],linenos[i])
    trainername=parseTrainer(lines[i])
    FileLineData.setLine(lines[i+1],linenos[i+1])
    nameline=strsplit(lines[i+1],/\s*,\s*/)
    name=nameline[0]
    raise _INTL("El nombre del entrenador es muy largo\r\n{1}",FileLineData.linereport) if name.length>=0x10000
    trainernames.push(name)
    partyid=0
    if nameline[1] && nameline[1]!=""
      raise _INTL("Se esperaba un número para el ID de batalla del entrenador\r\n{1}",FileLineData.linereport) if !nameline[1][/^\d+$/]
      partyid=nameline[1].to_i
    end
    FileLineData.setLine(lines[i+2],linenos[i+2])
    items=strsplit(lines[i+2],/\s*,\s*/)
    items[0].gsub!(/^\s+/,"")           # Cantidad de Pokémon
    raise _INTL("Se esperaba un número para la cantidad de Pokémon\r\n{1}",FileLineData.linereport) if !items[0][/^\d+$/]
    numpoke=items[0].to_i
    realitems=[]
    for j in 1...items.length           # Objetos que lleva el Entrenador
      realitems.push(parseItem(items[j])) if items[j] && items[j]!=""
    end
    pkmn=[]
    for j in 0...numpoke
      FileLineData.setLine(lines[i+j+3],linenos[i+j+3])
      poke=strsplit(lines[i+j+3],/\s*,\s*/)
      begin
        # Especies
        poke[TPSPECIES]=parseSpecies(poke[TPSPECIES])
      rescue
        raise _INTL("Se esperaba un nombre de especie: {1}\r\n{2}",poke[0],FileLineData.linereport)
      end
      # Nivel
      poke[TPLEVEL]=poke[TPLEVEL].to_i
      raise _INTL("Nivel erróneo: {1} (debe estar entre 1-{2})\r\n{3}",poke[TPLEVEL],
        PBExperience::MAXLEVEL,FileLineData.linereport) if poke[TPLEVEL]<=0 || poke[TPLEVEL]>PBExperience::MAXLEVEL
      # Objetos llevados
      if !poke[TPITEM] || poke[TPITEM]==""
        poke[TPITEM]=TPDEFAULTS[TPITEM]
      else
        poke[TPITEM]=parseItem(poke[TPITEM])
      end
      # Movimientos
      moves=[]
      for j in [TPMOVE1,TPMOVE2,TPMOVE3,TPMOVE4]
        moves.push(parseMove(poke[j])) if poke[j] && poke[j]!=""
      end
      for j in 0...4
        index=[TPMOVE1,TPMOVE2,TPMOVE3,TPMOVE4][j]
        if moves[j] && moves[j]!=0
          poke[index]=moves[j]
        else
          poke[index]=TPDEFAULTS[index]
        end
      end
      # Habilidad
      if !poke[TPABILITY] || poke[TPABILITY]==""
        poke[TPABILITY]=TPDEFAULTS[TPABILITY]
      else
        poke[TPABILITY]=poke[TPABILITY].to_i
        raise _INTL("Bandera de habilidad errónea: {1} (debe ser 0 o 1 o 2-5)\r\n{2}",poke[TPABILITY],FileLineData.linereport) if poke[TPABILITY]<0 || poke[TPABILITY]>5
      end
      # Género
      if !poke[TPGENDER] || poke[TPGENDER]==""
        poke[TPGENDER]=TPDEFAULTS[TPGENDER]
      else
        if poke[TPGENDER]=="M"
          poke[TPGENDER]=0
        elsif poke[TPGENDER]=="F"
          poke[TPGENDER]=1
        else
          poke[TPGENDER]=poke[TPGENDER].to_i
          raise _INTL("Bandera de género errónea: {1} (debe ser M o F, o 0 o 1)\r\n{2}",poke[TPGENDER],FileLineData.linereport) if poke[TPGENDER]<0 || poke[TPGENDER]>1
        end
      end
      # Forma
      if !poke[TPFORM] || poke[TPFORM]==""
        poke[TPFORM]=TPDEFAULTS[TPFORM]
      else
        poke[TPFORM]=poke[TPFORM].to_i
        raise _INTL("Forma errónea: {1} (debe ser 0 o mayor)\r\n{2}",poke[TPFORM],FileLineData.linereport) if poke[TPFORM]<0
      end
      # Shiny
      if !poke[TPSHINY] || poke[TPSHINY]==""
        poke[TPSHINY]=TPDEFAULTS[TPSHINY]
      elsif poke[TPSHINY]=="shiny"
        poke[TPSHINY]=true
      else
        poke[TPSHINY]=csvBoolean!(poke[TPSHINY].clone)
      end
      # Naturaleza
      if !poke[TPNATURE] || poke[TPNATURE]==""
        poke[TPNATURE]=TPDEFAULTS[TPNATURE]
      else
        poke[TPNATURE]=parseNature(poke[TPNATURE])
      end
      # IVs
      if !poke[TPIV] || poke[TPIV]==""
        poke[TPIV]=TPDEFAULTS[TPIV]
      else
        poke[TPIV]=poke[TPIV].to_i
        raise _INTL("IV errónea: {1} (debe estar entre 0-31)\r\n{2}",poke[TPIV],FileLineData.linereport) if poke[TPIV]<0 || poke[TPIV]>31
      end
      # Felicidad
      if !poke[TPHAPPINESS] || poke[TPHAPPINESS]==""
        poke[TPHAPPINESS]=TPDEFAULTS[TPHAPPINESS]
      else
        poke[TPHAPPINESS]=poke[TPHAPPINESS].to_i
        raise _INTL("Felicidad errónea: {1} (debe estar entre 0-255)\r\n{2}",poke[TPHAPPINESS],FileLineData.linereport) if poke[TPHAPPINESS]<0 || poke[TPHAPPINESS]>255
      end
      # Apodo
      if !poke[TPNAME] || poke[TPNAME]==""
        poke[TPNAME]=TPDEFAULTS[TPNAME]
      else
        poke[TPNAME]=poke[TPNAME].to_s
        raise _INTL("Apodo erróneo: {1} (debe ser de 1-20 caracteres)\r\n{2}",poke[TPNAME],FileLineData.linereport) if (poke[TPNAME].to_s).length>20
      end
      # Oscuro
      if !poke[TPSHADOW] || poke[TPSHADOW]==""
        poke[TPSHADOW]=TPDEFAULTS[TPSHADOW]
      else
        poke[TPSHADOW]=csvBoolean!(poke[TPSHADOW].clone)
      end
      # Ball
      if !poke[TPBALL] || poke[TPBALL]==""
        poke[TPBALL]=TPDEFAULTS[TPBALL]
      else
        poke[TPBALL]=poke[TPBALL].to_i
        raise _INTL("Ball errónea: {1} (debe ser 0 o mayor)\r\n{2}",poke[TPBALL],FileLineData.linereport) if poke[TPBALL]<0
      end
      pkmn.push(poke)
    end
    i+=3+numpoke
    MessageTypes.setMessagesAsHash(MessageTypes::TrainerNames,trainernames)
    trainers.push([trainername,name,realitems,pkmn,partyid])
    nameoffset+=name.length
  end
  save_data(trainers,"Data/trainers.dat")
end

#===============================================================================
# Compilación de los mensajes del celular
#===============================================================================
def pbCompilePhoneData
  return if !safeExists?("PBS/phone.txt")
  database=PhoneDatabase.new
  sections=[]
  File.open("PBS/phone.txt","rb"){|f|
     pbEachSection(f){|section,name|
        if name=="<Generics>"
          database.generics=section
          sections.concat(section)
        elsif name=="<BattleRequests>"
          database.battleRequests=section 
          sections.concat(section)
        elsif name=="<GreetingsMorning>"
          database.greetingsMorning=section 
          sections.concat(section)
        elsif name=="<GreetingsEvening>"
          database.greetingsEvening=section 
          sections.concat(section)
        elsif name=="<Greetings>"
          database.greetings=section
          sections.concat(section)
        elsif name=="<Bodies1>"
          database.bodies1=section 
          sections.concat(section)
        elsif name=="<Bodies2>"
          database.bodies2=section 
          sections.concat(section)
        end
     }
  }
  MessageTypes.setMessagesAsHash(MessageTypes::PhoneMessages,sections)
  save_data(database,"Data/phone.dat")
end

#===============================================================================
# Compilación de los metadatos
#===============================================================================
class PBTrainers; end



def pbCompileMetadata
  sections=[]
  currentmap=-1
  pbCompilerEachCommentedLine("PBS/metadata.txt") {|line,lineno|
     if line[/^\s*\[\s*(\d+)\s*\]\s*$/]
       sectionname=$~[1]
       if currentmap==0
         if sections[currentmap][MetadataHome]==nil
           raise _INTL("Los datos de la Casa son necesarios en la sección metadata.txt [{1}]",sectionname)
         end
         if sections[currentmap][MetadataPlayerA]==nil
           raise _INTL("Los datos de PlayerA son necesarios en la sección metadata.txt [{1}]",sectionname)
         end
       end
       currentmap=sectionname.to_i
       sections[currentmap]=[]
     else
       if currentmap<0
         raise _INTL("Se esperaba una sección al inicio del archivo\r\n{1}",FileLineData.linereport)
       end
       if !line[/^\s*(\w+)\s*=\s*(.*)$/]
         raise _INTL("Sintaxis de línea errónea (se esperaba línea con formato XXX=YYY)\r\n{1}",FileLineData.linereport)
       end
       matchData=$~
       schema=nil
       FileLineData.setSection(currentmap,matchData[1],matchData[2])
       if currentmap==0
         schema=PokemonMetadata::GlobalTypes[matchData[1]]
       else
         schema=PokemonMetadata::NonGlobalTypes[matchData[1]]
       end
       if schema
         record=pbGetCsvRecord(matchData[2],lineno,schema)
         sections[currentmap][schema[0]]=record
       end
     end
  }
  File.open("Data/metadata.dat","wb"){|f|
     Marshal.dump(sections,f)
  }
end

#===============================================================================
# Compilación de los entrenadores/Pokémon de la Torre de Batalla y las demás Copas
#===============================================================================
def pbCompileBTTrainers(filename)
  sections=[]
  btTrainersRequiredTypes={
     "Type"=>[0,"e",PBTrainers],
     "Name"=>[1,"s"],
     "BeginSpeech"=>[2,"s"],
     "EndSpeechWin"=>[3,"s"],
     "EndSpeechLose"=>[4,"s"],
     "PokemonNos"=>[5,"*u"]
  }
  requiredtypes=btTrainersRequiredTypes
  trainernames=[]
  beginspeech=[]
  endspeechwin=[]
  endspeechlose=[]
  if safeExists?(filename)
    File.open(filename,"rb"){|f|
       FileLineData.file=filename
       pbEachFileSectionEx(f){|section,name|
          rsection=[]
          for key in section.keys
            FileLineData.setSection(name,key,section[key])
            schema=requiredtypes[key]
            next if !schema
            record=pbGetCsvRecord(section[key],0,schema)
            rsection[schema[0]]=record  
          end
          trainernames.push(rsection[1]) 
          beginspeech.push(rsection[2])
          endspeechwin.push(rsection[3])
          endspeechlose.push(rsection[4])
          sections.push(rsection)
       }
    }
  end
  MessageTypes.addMessagesAsHash(MessageTypes::TrainerNames,trainernames)
  MessageTypes.addMessagesAsHash(MessageTypes::BeginSpeech,beginspeech)
  MessageTypes.addMessagesAsHash(MessageTypes::EndSpeechWin,endspeechwin)
  MessageTypes.addMessagesAsHash(MessageTypes::EndSpeechLose,endspeechlose)
  return sections
end

def pbCompileTrainerLists
  btTrainersRequiredTypes={
     "Trainers"=>[0,"s"],
     "Pokemon"=>[1,"s"],
     "Challenges"=>[2,"*s"]
  }
  if !safeExists?("PBS/trainerlists.txt")
    File.open("PBS/trainerlists.txt","wb"){|f|
       f.write(0xEF.chr)
       f.write(0xBB.chr)
       f.write(0xBF.chr)
       f.write("[DefaultTrainerList]\r\nTrainers=bttrainers.txt\r\nPokemon=btpokemon.txt\r\n")
    }
  end
  database=[]
  sections=[]
  MessageTypes.setMessagesAsHash(MessageTypes::BeginSpeech,[])
  MessageTypes.setMessagesAsHash(MessageTypes::EndSpeechWin,[])
  MessageTypes.setMessagesAsHash(MessageTypes::EndSpeechLose,[])
  File.open("PBS/trainerlists.txt","rb"){|f|
     FileLineData.file="PBS/trainerlists.txt"
     pbEachFileSectionEx(f){|section,name|
        next if name!="DefaultTrainerList" && name!="TrainerList"
        rsection=[]
        for key in section.keys
          FileLineData.setSection(name,key,section[key])
          schema=btTrainersRequiredTypes[key]
          next if key=="Challenges" && name=="DefaultTrainerList"
          next if !schema
          record=pbGetCsvRecord(section[key],0,schema)
          rsection[schema[0]]=record  
        end
        if !rsection[0]
          raise _INTL("No se ha indicado el archivo de datos de entrenadores en la sección {1}\r\n{2}",name,FileLineData.linereport)
        end
        if !rsection[1]
          raise _INTL("No se ha indicado el archivo de datos de entrenadores en la sección {1}\r\n{2}",name,FileLineData.linereport)
        end
        rsection[3]=rsection[0]
        rsection[4]=rsection[1]
        rsection[5]=(name=="DefaultTrainerList")
        if safeExists?("PBS/"+rsection[0])
          rsection[0]=pbCompileBTTrainers("PBS/"+rsection[0])
        else
          rsection[0]=[]
        end
        if safeExists?("PBS/"+rsection[1])
          filename="PBS/"+rsection[1]
          rsection[1]=[]
          pbCompilerEachCommentedLine(filename){|line,lineno|
             rsection[1].push(PBPokemon.fromInspected(line))
          }
        else
          rsection[1]=[]
        end
        if !rsection[2]
          rsection[2]=[]
        end
        while rsection[2].include?("")
          rsection[2].delete("")
        end
        rsection[2].compact!
        sections.push(rsection)
     }
  }
  save_data(sections,"Data/trainerlists.dat")
end

#===============================================================================
# Compilación de los encuentros con Pokémon salvajes
#===============================================================================
def pbCompileEncounters
  lines=[]
  linenos=[]
  FileLineData.file="PBS/encounters.txt"
  File.open("PBS/encounters.txt","rb"){|f|
     lineno=1
     f.each_line {|line|
        if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
          line=line[3,line.length-3]
        end
        line=prepline(line)
        if line.length!=0
          lines[lines.length]=line
          linenos[linenos.length]=lineno
        end
        lineno+=1
     }
  }
  encounters={}
  thisenc=nil
  lastenc=-1
  lastenclen=0
  needdensity=false
  lastmapid=-1
  i=0;
  while i<lines.length
    line=lines[i]
    FileLineData.setLine(line,linenos[i])
    mapid=line[/^\d+$/]
    if mapid
      lastmapid=mapid
      if thisenc && (thisenc[1][EncounterTypes::Land] ||
                     thisenc[1][EncounterTypes::LandMorning] ||
                     thisenc[1][EncounterTypes::LandDay] ||
                     thisenc[1][EncounterTypes::LandNight] ||
                     thisenc[1][EncounterTypes::BugContest]) &&
                     thisenc[1][EncounterTypes::Cave]
        raise _INTL("No se pueden definir encuentros en Campo y Cueva en la misma área (mapa ID {1})",mapid)
      end
      thisenc=[EncounterTypes::EnctypeDensities.clone,[]]
      encounters[mapid.to_i]=thisenc
      needdensity=true
      i+=1
      next
    end
    enc=findIndex(EncounterTypes::Names){|val| val==line}
    if enc>=0
      needdensity=false
      enclines=EncounterTypes::EnctypeChances[enc].length
      encarray=[]
      j=i+1; k=0
      while j<lines.length && k<enclines
        line=lines[j]
        FileLineData.setLine(lines[j],linenos[j])
        splitarr=strsplit(line,/\s*,\s*/)
        if !splitarr || splitarr.length<2
          raise _INTL("En encounters.txt, se esperaba un línea de especies,\r\npero se obtuvo \"{1}\" (posiblemente hay muy pocas entradas en un tipo de encuentro).\r\nVerifica el formato de la sección enumerada con {2},\r\nque se encuentra justo antes de esta línea.\r\n{3}",
             line,lastmapid,FileLineData.linereport)
        end
        splitarr[2]=splitarr[1] if splitarr.length==2
        splitarr[1]=splitarr[1].to_i
        splitarr[2]=splitarr[2].to_i
        maxlevel=PBExperience::MAXLEVEL
        if splitarr[1]<=0 || splitarr[1]>maxlevel
          raise _INTL("El número de nivel no es válido: {1}\r\n{2}",splitarr[1],FileLineData.linereport)
        end
        if splitarr[2]<=0 || splitarr[2]>maxlevel
          raise _INTL("El número de nivel no es válido: {1}\r\n{2}",splitarr[2],FileLineData.linereport)
        end
        if splitarr[1]>splitarr[2]
          raise _INTL("El nivel mínimo es mayor que el nivel máximo: {1}\r\n{2}",line,FileLineData.linereport)
        end
        splitarr[0]=parseSpecies(splitarr[0])
        linearr=splitarr
        encarray.push(linearr)
        thisenc[1][enc]=encarray
        j+=1
        k+=1
      end
      if j==lines.length && k<enclines
         raise _INTL("Se encontró fin de archivo inesperado. Hay muy pocas entradas en la última sección, se esperaban {1} entradas.\r\nVerifica el formato de la sección número {2}.\r\n{3}",
            enclines,lastmapid,FileLineData.linereport)
      end
      i=j
    elsif needdensity
      needdensity=false
      nums=strsplit(line,/,/)
      if nums && nums.length>=3
        for j in 0...EncounterTypes::EnctypeChances.length
          next if !EncounterTypes::EnctypeChances[j] ||
                  EncounterTypes::EnctypeChances[j].length==0
          next if EncounterTypes::EnctypeCompileDens[j]==0
          thisenc[0][j]=nums[EncounterTypes::EnctypeCompileDens[j]-1].to_i
        end
      else
        raise _INTL("Sintaxis de densidades errónea en encounters.txt; se obtuvo \"{1}\"\r\n{2}",line,FileLineData.linereport)
      end
      i+=1
    else
      raise _INTL("Tipo de encuentro indefinido {1}, se esperaba uno de los siguientes:\r\n{2}\r\n{3}",
         line,EncounterTypes::Names.inspect,FileLineData.linereport)
    end
  end
  save_data(encounters,"Data/encounters.dat")
end

#===============================================================================
# Compilación de los movimientos Oscuros
#===============================================================================
def pbCompileShadowMoves
  sections=[]
  if File.exists?("PBS/shadowmoves.txt")
    pbCompilerEachCommentedLine("PBS/shadowmoves.txt"){|line,lineno|
       if line[ /^([^=]+)=(.*)$/ ]
         key=$1
         value=$2
         value=value.split(",")
         species=parseSpecies(key)
         moves=[]
         for i in 0...[4,value.length].min
           moves.push((parseMove(value[i]) rescue nil))
         end
         moves.compact!
         sections[species]=moves if moves.length>0
       end
    }
  end
  save_data(sections,"Data/shadowmoves.dat")
end

#===============================================================================
# Compilación de las animaciones de batalla
#===============================================================================
def pbCompileAnimations
  begin
    if $RPGVX
      pbanims=load_data("Data/PkmnAnimations.rvdata")
    else
      pbanims=load_data("Data/PkmnAnimations.rxdata")
    end
  rescue
    pbanims=PBAnimations.new
  end
  move2anim=[[],[]]
=begin
  if $RPGVX
    anims=load_data("Data/Animations.rvdata")
  else
    anims=load_data("Data/Animations.rxdata")
  end
  for anim in anims
    next if !anim || anim.frames.length==1
    found=false
    for i in 0...pbanims.length
      if pbanims[i] && pbanims[i].id==anim.id
        found=true if pbanims[i].array.length>1
        break
      end
    end
    if !found
      pbanims[anim.id]=pbConvertRPGAnimation(anim)
    end
  end
=end
  for i in 0...pbanims.length
    next if !pbanims[i]
    if pbanims[i].name[/^OppMove\:\s*(.*)$/]
      if Kernel.hasConst?(PBMoves,$~[1])
        moveid=PBMoves.const_get($~[1])
        move2anim[1][moveid]=i
      end
    elsif pbanims[i].name[/^Move\:\s*(.*)$/]
      if Kernel.hasConst?(PBMoves,$~[1])
        moveid=PBMoves.const_get($~[1])
        move2anim[0][moveid]=i
      end
    end
  end
  save_data(move2anim,"Data/move2anim.dat")
  save_data(pbanims,"Data/PkmnAnimations.rxdata")
end

#===============================================================================
# Generación y modificación de los eventos
#===============================================================================
def pbGenerateMoveRoute(commands)
  route=RPG::MoveRoute.new
  route.repeat=false
  route.skippable=true
  route.list.clear
  i=0; while i<commands.length
    case commands[i]
    when PBMoveRoute::Wait, PBMoveRoute::SwitchOn, PBMoveRoute::SwitchOff,
         PBMoveRoute::ChangeSpeed, PBMoveRoute::ChangeFreq, PBMoveRoute::Opacity,
         PBMoveRoute::Blending, PBMoveRoute::PlaySE, PBMoveRoute::Script
      route.list.push(RPG::MoveCommand.new(commands[i],[commands[i+1]]))
      i+=1
    when PBMoveRoute::ScriptAsync
      route.list.push(RPG::MoveCommand.new(PBMoveRoute::Script,[commands[i+1]]))
      route.list.push(RPG::MoveCommand.new(PBMoveRoute::Wait,[0]))
      i+=1
    when PBMoveRoute::Jump
      route.list.push(RPG::MoveCommand.new(commands[i],[commands[i+1],commands[i+2]]))
      i+=2
    when PBMoveRoute::Graphic
      route.list.push(RPG::MoveCommand.new(commands[i],[commands[i+1],commands[i+2],commands[i+3],commands[i+4]]))
      i+=4
    else
      route.list.push(RPG::MoveCommand.new(commands[i]))
    end
    i+=1
  end
  route.list.push(RPG::MoveCommand.new(0))
  return route
end

def pbPushMoveRoute(list,character,route,indent=0)
  if route.is_a?(Array)
    route=pbGenerateMoveRoute(route)
  end
  for i in 0...route.list.length
    list.push(RPG::EventCommand.new(
       i==0 ? 209 : 509,indent,
       i==0 ? [character,route] : [route.list[i-1]]))
  end
end

def pbPushMoveRouteAndWait(list,character,route,indent=0)
  pbPushMoveRoute(list,character,route,indent)
  pbPushEvent(list,210,[],indent)
end

def pbPushWait(list,frames,indent=0)
  pbPushEvent(list,106,[frames],indent)
end

def pbPushEvent(list,cmd,params=nil,indent=0)
  list.push(RPG::EventCommand.new(cmd,indent,params ? params : []))
end

def pbPushEnd(list)
  list.push(RPG::EventCommand.new(0,0,[]))
end

def pbPushComment(list,cmt,indent=0)
  textsplit2=cmt.split(/\n/)
  for i in 0...textsplit2.length
    list.push(RPG::EventCommand.new(i==0 ? 108 : 408,indent,[textsplit2[i].gsub(/\s+$/,"")]))
  end
end

def pbPushText(list,text,indent=0)
  return if !text
  textsplit=text.split(/\\m/)
  for t in textsplit
    first=true
    if $RPGVX
      list.push(RPG::EventCommand.new(101,indent,["",0,0,2]))
      first=false
    end
    textsplit2=t.split(/\n/)
    for i in 0...textsplit2.length
      textchunk=textsplit2[i].gsub(/\s+$/,"")
      if textchunk && textchunk!=""
        list.push(RPG::EventCommand.new(first ? 101 : 401,indent,[textchunk]))
        first=false
      end
    end
  end
end

def pbPushScript(list,script,indent=0)
  return if !script
  first=true
  textsplit2=script.split(/\n/)
  for i in 0...textsplit2.length
    textchunk=textsplit2[i].gsub(/\s+$/,"")
    if textchunk && textchunk!=""
      list.push(RPG::EventCommand.new(first ? 355 : 655,indent,[textchunk]))
      first=false
    end
  end
end

def pbPushExit(list,indent=0)
  list.push(RPG::EventCommand.new(115,indent,[]))
end

def pbPushElse(list,indent=0)
  list.push(RPG::EventCommand.new(0,indent,[]))
  list.push(RPG::EventCommand.new(411,indent-1,[]))
end

def pbPushBranchEnd(list,indent=0)
  list.push(RPG::EventCommand.new(0,indent,[]))
  list.push(RPG::EventCommand.new(412,indent-1,[]))
end

def pbPushBranch(list,script,indent=0)
  list.push(RPG::EventCommand.new(111,indent,[12,script]))
end

def pbPushSelfSwitch(list,swtch,switchOn,indent=0)
  list.push(RPG::EventCommand.new(123,indent,[swtch,switchOn ? 0 : 1]))
end

def safequote(x)
  x=x.gsub(/\"\#\'\\/){|a| "\\"+a }
  x=x.gsub(/\t/,"\\t")
  x=x.gsub(/\r/,"\\r")
  x=x.gsub(/\n/,"\\n")
  return x
end

def safequote2(x)
  x=x.gsub(/\"\#\'\\/){|a| "\\"+a }
  x=x.gsub(/\t/,"\\t")
  x=x.gsub(/\r/,"\\r")
  x=x.gsub(/\n/," ")
  return x
end

def pbEventId(event)
  list=event.pages[0].list
  return nil if list.length==0
  codes=[]
  i=0;while i<list.length
    codes.push(list[i].code)
    i+=1
  end
end



class MapData
  def initialize
    @mapinfos=pbLoadRxData("Data/MapInfos")
    @system=pbLoadRxData("Data/System")
    @tilesets=pbLoadRxData("Data/Tilesets")
    @mapxy=[]
    @mapWidths=[]
    @mapHeights=[]
    @maps=[]
    @registeredSwitches={}
  end

  def registerSwitch(switch)
    if @registeredSwitches[switch]
      return @registeredSwitches[switch]
    end
    for id in 1..5000
      name=@system.switches[id]
      if !name || name=="" || name==switch
        @system.switches[id]=switch
        @registeredSwitches[switch]=id
        return id
      end
    end
    return 1
  end

  def saveTilesets
    filename="Data/Tilesets"
    if $RPGVX
      filename+=".rvdata"
    else
      filename+=".rxdata"
    end
    save_data(@tilesets,filename)
    filename="Data/System"
    if $RPGVX
      filename+=".rvdata"
    else
      filename+=".rxdata"
    end
    save_data(@system,filename)
  end

  def switchName(id)
    return @system.switches[id] || ""
  end

  def mapFilename(mapID)
    filename=sprintf("Data/map%03d",mapID)
    if $RPGVX
      filename+=".rvdata"
    else
      filename+=".rxdata"
    end
    return filename
  end

  def getMap(mapID)
    if @maps[mapID]
      return @maps[mapID]
    else
      begin
        @maps[mapID]=load_data(mapFilename(mapID))
        return @maps[mapID]
      rescue
        return nil
      end
    end
  end

  def isPassable?(mapID,x,y)
    if !$RPGVX
      map=getMap(mapID)
      return false if !map
      return false if x<0 || x>=map.width || y<0 || y>=map.height
      passages=@tilesets[map.tileset_id].passages
      priorities=@tilesets[map.tileset_id].priorities
      for i in [2, 1, 0]
        tile_id = map.data[x, y, i]
        return false if tile_id == nil
        return false if passages[tile_id] & 0x0f == 0x0f
        return true if priorities[tile_id] == 0
      end
    end
    return true
  end

  def setCounterTile(mapID,x,y)
    if !$RPGVX
      map=getMap(mapID)
      return if !map
      passages=@tilesets[map.tileset_id].passages
      for i in [2, 1, 0]
        tile_id = map.data[x, y, i]
        next if tile_id == 0 || tile_id==nil || !passages[tile_id]
        passages[tile_id]|=0x80
        break
      end
    end
  end

  def isCounterTile?(mapID,x,y)
    return false if $RPGVX
    map=getMap(mapID)
    return false if !map
    passages=@tilesets[map.tileset_id].passages
    for i in [2, 1, 0]
      tile_id = map.data[x, y, i]
      return false if tile_id == nil
      return true if passages[tile_id] && passages[tile_id] & 0x80 == 0x80
    end
    return false
  end

  def saveMap(mapID)
    save_data(getMap(mapID),mapFilename(mapID)) rescue nil
  end

  def getEventFromXY(mapID,x,y)
    return nil if x<0 || y<0
    mapPositions=@mapxy[mapID]
    if mapPositions
      return mapPositions[y*@mapWidths[mapID]+x]
    else
      map=getMap(mapID)
      return nil if !map
      @mapWidths[mapID]=map.width
      @mapHeights[mapID]=map.height
      mapPositions=[]
      width=map.width
      for e in map.events.values
        mapPositions[e.y*width+e.x]=e if e
      end
      @mapxy[mapID]=mapPositions
      return mapPositions[y*width+x]
    end
  end

  def getEventFromID(mapID,id)
    map=getMap(mapID)
    return nil if !map
    return map.events[id]
  end

  def mapinfos
    return @mapinfos
  end
end



class TrainerChecker
  def initialize
    @trainers=nil
    @trainertypes=nil
    @dontaskagain=false
  end

  def pbTrainerTypeCheck(symbol)
    ret=true
    if $DEBUG  
      return if @dontaskagain
      if !hasConst?(PBTrainers,symbol)
        ret=false
      else
        trtype=PBTrainers.const_get(symbol)
        @trainertypes=load_data("Data/trainertypes.dat") if !@trainertypes
        if !@trainertypes || !@trainertypes[trtype]     
          ret=false   
        end
      end  
      if !ret
        if Kernel.pbConfirmMessage(_INTL("¿Quieres agregar un entrenador nuevo con el nombre {1}?",symbol))
          pbTrainerTypeEditorNew(symbol.to_s)
          @trainers=nil
          @trainertypes=nil
        end
#        if pbMapInterpreter
#          pbMapInterpreter.command_end rescue nil
#        end
      end
    end 
    return ret
  end

  def pbTrainerBattleCheck(trtype,trname,trid)
    if $DEBUG
      return if @dontaskagain
      if trtype.is_a?(String) || trtype.is_a?(Symbol)
        pbTrainerTypeCheck(trtype)
        return if !hasConst?(PBTrainers,trtype)
        trtype=PBTrainers.const_get(trtype)
      end
      @trainers=load_data("Data/trainers.dat") if !@trainers
      if @trainers
        for trainer in @trainers
          name=trainer[1]
          thistrainerid=trainer[0]
          thispartyid=trainer[4]
          next if name!=trname || thistrainerid!=trtype || thispartyid!=trid
          return
        end
      end
      cmd=pbMissingTrainer(trtype,trname,trid)
      if cmd==2
        @dontaskagain=true
        Graphics.update
      end
      @trainers=nil
      @trainertypes=nil
    end
  end
end



def pbCompileTrainerEvents(mustcompile)
  mapdata=MapData.new
  t = Time.now.to_i
  Graphics.update
  trainerChecker=TrainerChecker.new
  for id in mapdata.mapinfos.keys.sort
    changed=false
    map=mapdata.getMap(id)
    next if !map || !mapdata.mapinfos[id]
    Win32API.SetWindowText(_INTL("Procesando mapa {1} ({2})",id,mapdata.mapinfos[id].name))
    for key in map.events.keys
      if Time.now.to_i - t >= 5
        Graphics.update
        t = Time.now.to_i
      end
      newevent=pbConvertToTrainerEvent(map.events[key],trainerChecker)
      if newevent
        changed=true
        map.events[key]=newevent
      end
      newevent=pbConvertToItemEvent(map.events[key])
      if newevent
        changed=true
        map.events[key]=newevent
      end
      newevent=pbFixEventUse(map.events[key],id,mapdata)
      if newevent
        changed=true
        map.events[key]=newevent
      end
    end
    if Time.now.to_i - t >= 5
      Graphics.update
      t = Time.now.to_i
    end
    changed=true if pbCheckCounters(map,id,mapdata)
    if changed
      mapdata.saveMap(id)
      mapdata.saveTilesets
    end
  end
  changed=false
  if Time.now.to_i-t>=5
    Graphics.update
    t=Time.now.to_i
  end
  commonEvents=pbLoadRxData("Data/CommonEvents")
  Win32API.SetWindowText(_INTL("Procesando eventos comunes"))
  for key in 0...commonEvents.length
    newevent=pbFixEventUse(commonEvents[key],0,mapdata)
    if newevent
      changed=true
      map.events[key]=newevent
    end
  end
  if changed
    if $RPGVX
      save_data(commonEvents,"Data/CommonEvents.rvdata")
    else
      save_data(commonEvents,"Data/CommonEvents.rxdata")
    end
  end
#  if !$RPGVX && $INTERNAL
#    convertVXProject(mapdata)
#  end
end

def isPlainEvent?(event)
  return event && event.pages.length<=1 && 
         event.pages[0].list.length<=1 &&
         event.pages[0].move_type==0 &&
         event.pages[0].condition.switch1_valid==false &&
         event.pages[0].condition.switch2_valid==false &&
         event.pages[0].condition.variable_valid==false &&
         event.pages[0].condition.self_switch_valid==false
end

def isPlainEventOrMart?(event)
  return event &&
         event.pages.length<=1 && 
         event.pages[0].move_type==0 &&
         event.pages[0].condition.switch1_valid==false &&
         event.pages[0].condition.switch2_valid==false &&
         event.pages[0].condition.variable_valid==false &&
         event.pages[0].condition.self_switch_valid==false &&
         ((event.pages[0].list.length<=1) || (
         event.pages[0].list.length<=12 &&
         event.pages[0].graphic.character_name!="" &&
         event.pages[0].list[0].code==355 &&
         event.pages[0].list[0].parameters[0][/^pbPokemonMart/]) || (
         event.pages[0].list.length>8 &&
         event.pages[0].graphic.character_name!="" &&
         event.pages[0].list[0].code==355 &&
         event.pages[0].list[0].parameters[0][/^Kernel\.pbSetPokemonCenter/])
         )
end

def applyPages(page,pages)
  for p in pages
    p.graphic=page.graphic
    p.walk_anime=page.walk_anime
    p.step_anime=page.step_anime
    p.direction_fix=page.direction_fix
    p.through=page.through
    p.always_on_top=page.always_on_top
  end
end

def isLikelyCounter?(thisEvent,otherEvent,mapID,mapdata)
  # Check whether other event is likely on a counter tile
  yonderX=otherEvent.x+(otherEvent.x-thisEvent.x)
  yonderY=otherEvent.y+(otherEvent.y-thisEvent.y)
  return true if mapdata.isCounterTile?(mapID,otherEvent.x,otherEvent.y)
  return thisEvent.pages[0].graphic.character_name!="" &&
         otherEvent.pages[0].graphic.character_name=="" &&
         otherEvent.pages[0].trigger==0 &&
         mapdata.isPassable?(mapID,thisEvent.x,thisEvent.y) &&
         !mapdata.isPassable?(mapID,otherEvent.x,otherEvent.y) &&
         mapdata.isPassable?(mapID,yonderX,yonderY)
end

def isLikelyPassage?(thisEvent,mapID,mapdata)
  return false if !thisEvent || thisEvent.pages.length==0
  return false if thisEvent.pages.length!=1
  if thisEvent.pages[0].graphic.character_name=="" &&
     thisEvent.pages[0].list.length<=12 &&
     thisEvent.pages[0].list.any? {|cmd| cmd.code==201 } &&
#     mapdata.isPassable?(mapID,thisEvent.x,thisEvent.y+1) &&
     mapdata.isPassable?(mapID,thisEvent.x,thisEvent.y) &&
     !mapdata.isPassable?(mapID,thisEvent.x-1,thisEvent.y) &&
     !mapdata.isPassable?(mapID,thisEvent.x+1,thisEvent.y) &&
     !mapdata.isPassable?(mapID,thisEvent.x-1,thisEvent.y-1) &&
     !mapdata.isPassable?(mapID,thisEvent.x+1,thisEvent.y-1)
    return true
  end
  return false
end

def pbCheckCounters(map,mapID,mapdata)
  todelete=[]
  changed=false
  for key in map.events.keys
    event=map.events[key]
    next if !event
    firstCommand=event.pages[0].list[0]
    if isPlainEventOrMart?(event)
      # Empty event, check for counter events
      neighbors=[]
      neighbors.push(mapdata.getEventFromXY(mapID,event.x,event.y-1))
      neighbors.push(mapdata.getEventFromXY(mapID,event.x,event.y+1))
      neighbors.push(mapdata.getEventFromXY(mapID,event.x-1,event.y))
      neighbors.push(mapdata.getEventFromXY(mapID,event.x+1,event.y))
      neighbors.compact!
      for otherEvent in neighbors
        next if isPlainEvent?(otherEvent)
        if isLikelyCounter?(event,otherEvent,mapID,mapdata)
          mapdata.setCounterTile(mapID,otherEvent.x,otherEvent.y)
          savedPage=event.pages[0]
          event.pages=otherEvent.pages
          applyPages(savedPage,event.pages)
          todelete.push(otherEvent.id)
          changed=true
        end
      end
    end
  end
  for key in todelete
    map.events.delete(key)
  end
  return changed
end

def pbAddPassageList(event,mapdata)
  return if !event || event.pages.length==0
  page=RPG::Event::Page.new
  page.condition.switch1_valid=true
  page.condition.switch1_id=mapdata.registerSwitch('s:tsOff?("A")')
  page.graphic.character_name=""
  page.trigger=3 # Autorun
  page.list.clear
  list=page.list
  pbPushBranch(list,"get_character(0).onEvent?")
  pbPushEvent(list,208,[0],1)
  pbPushWait(list,6,1)
  pbPushEvent(list,208,[1],1)
  pbPushMoveRouteAndWait(list,-1,[PBMoveRoute::Down],1)
  pbPushBranchEnd(list,1)
  pbPushScript(list,"setTempSwitchOn(\"A\")")
  pbPushEnd(list)
  event.pages.push(page)
end

def pbUpdateDoor(event,mapdata)
  changed=false
  return false if event.is_a?(RPG::CommonEvent)
  if event.pages.length>=2 && 
     event.pages[event.pages.length-1].condition.switch1_valid &&
     event.pages[event.pages.length-1].condition.switch1_id==22 &&
     event.pages[event.pages.length-1].list.length>5 &&
     event.pages[event.pages.length-1].graphic.character_name!="" &&
     mapdata.switchName(event.pages[event.pages.length-1].condition.switch1_id)!='s:tsOff?("A")' &&
     event.pages[event.pages.length-1].list[0].code==111
    event.pages[event.pages.length-1].condition.switch1_id=mapdata.registerSwitch('s:tsOff?("A")')
    changed=true
  end
  if event.pages.length>=2 && 
     event.pages[event.pages.length-1].condition.switch1_valid &&
     event.pages[event.pages.length-1].list.length>5 &&
     event.pages[event.pages.length-1].graphic.character_name!="" &&
     mapdata.switchName(event.pages[event.pages.length-1].condition.switch1_id)=='s:tsOff?("A")' &&
     event.pages[event.pages.length-1].list[0].code==111
    list=event.pages[event.pages.length-2].list
    transferCommand=list.find_all {|cmd| cmd.code==201 }
    if transferCommand.length==1 && !list.any?{|cmd| cmd.code==208 }
      list.clear
      pbPushMoveRouteAndWait(list,0,[
         PBMoveRoute::PlaySE,RPG::AudioFile.new("Entering Door"),PBMoveRoute::Wait,2,
         PBMoveRoute::TurnLeft,PBMoveRoute::Wait,2,
         PBMoveRoute::TurnRight,PBMoveRoute::Wait,2,
         PBMoveRoute::TurnUp,PBMoveRoute::Wait,2])
      pbPushMoveRouteAndWait(list,-1,[
         PBMoveRoute::ThroughOn,PBMoveRoute::Up,PBMoveRoute::ThroughOff])
      pbPushEvent(list,208,[0]) # Change Transparent Flag
      pbPushMoveRouteAndWait(list,0,[PBMoveRoute::Wait,2,
         PBMoveRoute::TurnRight,PBMoveRoute::Wait,2,
         PBMoveRoute::TurnLeft,PBMoveRoute::Wait,2,
         PBMoveRoute::TurnDown,PBMoveRoute::Wait,2])
      pbPushEvent(list,223,[Tone.new(-255,-255,-255),6])
      pbPushWait(list,8)
      pbPushEvent(list,208,[1])
      pbPushEvent(list,transferCommand[0].code,transferCommand[0].parameters)
      pbPushEvent(list,223,[Tone.new(0,0,0),6])
      pbPushEnd(list)
      list=event.pages[event.pages.length-1].list
      list.clear
      pbPushBranch(list,"get_character(0).onEvent?")
      pbPushEvent(list,208,[0],1)
      pbPushMoveRouteAndWait(list,0,[
         PBMoveRoute::TurnLeft,PBMoveRoute::Wait,6],1)
      pbPushEvent(list,208,[1],1)
      pbPushMoveRouteAndWait(list,-1,[PBMoveRoute::Down],1)
      pbPushMoveRouteAndWait(list,0,[
         PBMoveRoute::TurnUp,PBMoveRoute::Wait,2,
         PBMoveRoute::TurnRight,PBMoveRoute::Wait,2,
         PBMoveRoute::TurnDown,PBMoveRoute::Wait,2],1)
      pbPushBranchEnd(list,1)
      pbPushScript(list,"setTempSwitchOn(\"A\")")
      pbPushEnd(list)
      changed=true
    end
  end
  return changed
end

def pbEventIsEmpty?(e)
  return true if !e
  return false if e.is_a?(RPG::CommonEvent)
  return e.pages.length==0
end

def pbStartsWith(s,pfx)
  return s[0,pfx.length]==pfx
end

def pbEachPage(e)
  return true if !e
  if e.is_a?(RPG::CommonEvent)
    yield e
  else
    e.pages.each {|page| yield page }
  end 
end

def pbChangeScript(script,re)
  tmp=script[0].gsub(re){ yield($~) }
  if script[0]!=tmp
    script[0]=tmp; return true
  end
  return false
end

def pbChangeScripts(script)
  changed=false
  changed|=pbChangeScript(script,/\$game_variables\[(\d+)\](?!\s*(?:\=|\!|<|>))/){|m| "pbGet("+m[1]+")" }
  changed|=pbChangeScript(script,/\$Trainer\.party\[\s*pbGet\((\d+)\)\s*\]/){|m| "pbGetPokemon("+m[1]+")" }
  return changed
end

def pbFixEventUse(event,mapID,mapdata)
  return nil if pbEventIsEmpty?(event)
  changed=false
  trainerMoneyRE=/^\s*\$Trainer\.money\s*(<|<=|>|>=)\s*(\d+)\s*$/
  itemBallRE=/^\s*(Kernel\.)?pbItemBall/
  if pbUpdateDoor(event,mapdata)
    changed=true
  end
  pbEachPage(event) do |page|
    i=0
    list=page.list
    while i<list.length
      params=list[i].parameters
      if list[i].code==655
        x=[params[0]]
        changed|=pbChangeScripts(x)
        params[0]=x[0]
      elsif list[i].code==355
        lastScript=i
        if !params[0].is_a?(String)
          i+=1
          next
        end
        x=[params[0]]
        changed|=pbChangeScripts(x)
        params[0]=x[0]
        if params[0][0,1]!="f" && params[0][0,1]!="p" && params[0][0,1]!="K"
          i+=1
          next
        end
        script=" "+params[0]
        j=i+1
        while j<list.length
          break if list[j].code!=655
          script+=list[j].parameters[0]
          lastScript=j
          j+=1
        end
        script.gsub!(/\s+/,"")
        # Using old method of recovering
        if script=="foriin$Trainer.partyi.healend"
          for j in i..lastScript
            list.delete_at(i)
          end
          list.insert(i,
             RPG::EventCommand.new(314,list[i].indent,[0]) # Recover All
          )
          changed=true
        elsif script=="pbFadeOutIn(99999){foriin$Trainer.partyi.healend}"
          oldIndent=list[i].indent
          for j in i..lastScript
            list.delete_at(i)
          end
          list.insert(i,
             RPG::EventCommand.new(223,oldIndent,[Tone.new(-255,-255,-255),6]), # Fade to black
             RPG::EventCommand.new(106,oldIndent,[6]), # Wait
             RPG::EventCommand.new(314,oldIndent,[0]), # Recover All
             RPG::EventCommand.new(223,oldIndent,[Tone.new(0,0,0),6]), # Fade to normal
             RPG::EventCommand.new(106,oldIndent,[6]) # Wait
          )
          changed=true
        end
      elsif list[i].code==108
        if params[0][/SellItem\s*\(\s*(\w+)\s*\,\s*(\d+)\s*\)/]
          itemname=$1
          cost=$2.to_i
          if hasConst?(PBItems,itemname)
            oldIndent=list[i].indent
            list.delete_at(i)
            newEvents=[]
            if cost==0
              pbPushBranch(newEvents,"$PokemonBag.pbCanStore?(PBItems:"+":#{itemname})",oldIndent)
              pbPushText(newEvents,_INTL("¡Aquí tienes!"),oldIndent+1)
              pbPushScript(newEvents,"Kernel.pbReceiveItem(PBItems:"+":#{itemname})",oldIndent+1)
              pbPushElse(newEvents,oldIndent+1)
              pbPushText(newEvents,_INTL("No tienes más espacio en la Mochila."),oldIndent+1)
              pbPushBranchEnd(newEvents,oldIndent+1)
            else
              pbPushEvent(newEvents,111,[7,cost,0],oldIndent)
              pbPushBranch(newEvents,"$PokemonBag.pbCanStore?(PBItems:"+":#{itemname})",oldIndent+1)
              pbPushEvent(newEvents,125,[1,0,cost],oldIndent+2)
              pbPushText(newEvents,_INTL("\\G¡Aquí tienes!"),oldIndent+2)
              pbPushScript(newEvents,"Kernel.pbReceiveItem(PBItems:"+":#{itemname})",oldIndent+2)
              pbPushElse(newEvents,oldIndent+2)
              pbPushText(newEvents,_INTL("\\GNo tienes más espacio en la Mochila."),oldIndent+2)
              pbPushBranchEnd(newEvents,oldIndent+2)
              pbPushElse(newEvents,oldIndent+1)
              pbPushText(newEvents,_INTL("\\GNo tienes el dinero suficiente."),oldIndent+1)
              pbPushBranchEnd(newEvents,oldIndent+1)
            end
            list[i,0]=newEvents # insert 'newEvents' at index 'i'
            changed=true
          end
        end
      elsif list[i].code==115 && i==list.length-2
        # Superfluous exit command
        list.delete_at(i)
        changed=true
      elsif list[i].code==201 && list.length<=8
        if params[0]==0
          # Transfer back to door
          e=mapdata.getEventFromXY(params[1],params[2],params[3]-1)
          if e && e.pages.length>=2 && 
             e.pages[e.pages.length-1].condition.switch1_valid &&
             e.pages[e.pages.length-1].condition.switch1_id==22 &&
             mapdata.switchName(e.pages[e.pages.length-1].condition.switch1_id)!='s:tsOff?("A")' &&
             e.pages[e.pages.length-1].list.length>5 &&
             e.pages[e.pages.length-1].list[0].code==111
            e.pages[e.pages.length-1].condition.switch1_id=mapdata.registerSwitch('s:tsOff?("A")')
            mapdata.saveMap(params[1])
            changed=true
          end
          if isLikelyPassage?(e,params[1],mapdata)
            pbAddPassageList(e,mapdata)
            mapdata.saveMap(params[1])
            changed=true
          end
          if e && e.pages.length>=2 && 
             e.pages[e.pages.length-1].condition.switch1_valid &&
            mapdata.switchName(e.pages[e.pages.length-1].condition.switch1_id)=='s:tsOff?("A")'
            # If this is really a door, move transfer target to it
            params[3]-=1
            params[5]=1 # No fade
            changed=true
          end
          deletedRoute=nil
          deleteMoveRouteAt=proc{|list,_i|
             arr=[]
             if list[_i] && list[_i].code==209
               arr.push(list[_i]);list.delete_at(_i)
               while _i<list.length
                 break if !list[_i] || list[_i].code!=509
                 arr.push(list[_i]);list.delete_at(_i)     
               end
             end
             next arr
          }
          insertMoveRouteAt=proc{|list,_i,route|
             _j=route.length-1
             while _j>=0
               list.insert(_i,route[_j])
               _j-=1
             end
          }
          if params[4]==0 && # Retain direction
             i+1<list.length && list[i+1].code==209 && list[i+1].parameters[0]==-1
            route=list[i+1].parameters[1]
            if route && route.list.length<=2
              # Delete superfluous move route command if necessary
              if route.list[0].code==16 # Player/Turn Down
                deleteMoveRouteAt.call(list,i+1); params[4]=2; changed=true
              elsif route.list[0].code==17 # Left
                deleteMoveRouteAt.call(list,i+1); params[4]=4; changed=true
              elsif route.list[0].code==18 # Right
                deleteMoveRouteAt.call(list,i+1); params[4]=6; changed=true
              elsif route.list[0].code==19 # Up
                deleteMoveRouteAt.call(list,i+1); params[4]=8; changed=true
              elsif (route.list[0].code==1 || route.list[0].code==2 ||
                 route.list[0].code==3 || route.list[0].code==4) && list.length==4
                params[4]=[0,2,4,6,8][route.list[0].code]
                deletedRoute=deleteMoveRouteAt.call(list,i+1); changed=true
              end
            end
          elsif params[4]==0 && i>3
            for j in 0...i
              if list[j].code==209 && list[j].parameters[0]==-1
                route=list[j].parameters[1]
                oldlistlength=list.length
                if route && route.list.length<=2
                  # Delete superfluous move route command if necessary
                  if route.list[0].code==16 # Player/Turn Down
                    deleteMoveRouteAt.call(list,j); params[4]=2; changed=true;i-=(oldlistlength-list.length)
                  elsif route.list[0].code==17 # Left
                    deleteMoveRouteAt.call(list,j); params[4]=4; changed=true;i-=(oldlistlength-list.length)
                  elsif route.list[0].code==18 # Right
                    deleteMoveRouteAt.call(list,j); params[4]=6; changed=true;i-=(oldlistlength-list.length)
                  elsif route.list[0].code==19 # Up
                    deleteMoveRouteAt.call(list,j); params[4]=8; changed=true;i-=(oldlistlength-list.length)
                  end
                end
              end
            end
          elsif params[4]==0 && # Retain direction
             i+2<list.length && 
             list[i+1].code==223 &&
             list[i+2].code==209 && 
             list[i+2].parameters[0]==-1
            route=list[i+2].parameters[1]
            if route && route.list.length<=2
              # Delete superfluous move route command if necessary
              if route.list[0].code==16 # Player/Turn Down
                deleteMoveRouteAt.call(list,i+2); params[4]=2; changed=true
              elsif route.list[0].code==17 # Left
                deleteMoveRouteAt.call(list,i+2); params[4]=4; changed=true
              elsif route.list[0].code==18 # Right
                deleteMoveRouteAt.call(list,i+2); params[4]=6; changed=true
              elsif route.list[0].code==19 # Up
                deleteMoveRouteAt.call(list,i+2); params[4]=8; changed=true
              end
            end
          end
        end
        # If this is the only event command, convert to a full event
        if list.length==2 || (list.length==3 && (list[0].code==250 || list[1].code==250))
          params[5]=1 # No fade
          fullTransfer=list[i]
          indent=list[i].indent
          (list.length-1).times { list.delete_at(0) }
          list.insert(0,
             RPG::EventCommand.new(250,indent,[RPG::AudioFile.new("Exit Door",80,100)]), # Play SE
             RPG::EventCommand.new(223,indent,[Tone.new(-255,-255,-255),6]), # Fade to black
             RPG::EventCommand.new(106,indent,[8]), # Wait
             fullTransfer, # Transfer event
             RPG::EventCommand.new(223,indent,[Tone.new(0,0,0),6]) # Fade to normal
          )
          changed=true
        end
        if deletedRoute
          insertMoveRouteAt.call(list,list.length-1,deletedRoute)
          changed=true
        end
      elsif list[i].code==101 
        if list[i].parameters[0][0,1]=="\\"
          newx=list[i].parameters[0].clone
          newx.sub!(/^\\[Bb]\s+/,"\\b")
          newx.sub!(/^\\[Rr]\s+/,"\\r")
          newx.sub!(/^\\[Pp][Gg]\s+/,"\\pg")
          newx.sub!(/^\\[Pp][Oo][Gg]\s+/,"\\pog")
          newx.sub!(/^\\[Gg]\s+/,"\\G")
          newx.sub!(/^\\[Cc][Nn]\s+/,"\\CN")
          if list[i].parameters[0]!=newx
            list[i].parameters[0]=newx
            changed=true
          end
        end
        lines=1
        j=i+1; while j<list.length
          break if list[j].code!=401
          if lines%4==0
            list[j].code=101
            changed=true
          end
          lines+=1
          j+=1
        end
        if lines>=2 && list[i].parameters[0].length>0 && list[i].parameters[0].length<=20 &&
           !list[i].parameters[0][/\\n/]
          # Very short line
          list[i].parameters[0]+="\\n"+list[i+1].parameters[0]
          list.delete_at(i+1)
          i-=1 # revisit this text command
          changed=true
        elsif lines>=3 && list[i+lines] && list[i+lines].code==101
          # Check whether a sentence is being broken midway 
          # between two Text commands
          lastLine=list[i+lines-1].parameters[0].sub(/\s+$/,"")
          if lastLine.length>0 && !lastLine[/[\\<]/] && lastLine[/[^\.,\!\?\;\-\"]$/]
            message=list[i].parameters[0]
            j=i+1; while j<list.length
              break if list[j].code!=401
              message+="\n"+list[j].parameters[0]
              j+=1
            end
            punct=[message.rindex(". "),message.rindex(".\n"),
               message.rindex("!"),message.rindex("?"),-1].compact.max
            if punct==-1
              punct=[message.rindex(", "),message.rindex(",\n"),-1].compact.max
            end
            if punct!=-1
              # Delete old message
              indent=list[i].indent
              newMessage=message[0,punct+1].split("\n")
              nextMessage=message[punct+1,message.length].sub(/^\s+/,"").split("\n")
              list[i+lines].code=401
              lines.times { list.delete_at(i) }
              j=nextMessage.length-1;while j>=0
                list.insert(i,RPG::EventCommand.new(
                j==0 ? 101 : 401,indent,[nextMessage[j]]))
                j-=1
              end
              j=newMessage.length-1;while j>=0
                list.insert(i,RPG::EventCommand.new(
                j==0 ? 101 : 401,indent,[newMessage[j]]))
                j-=1
              end
              changed=true
              i+=1
              next
            end
          end
        end
      elsif list[i].code==111 && list[i].parameters[0]==12
        x=[list[i].parameters[1]]
        changed|=pbChangeScripts(x)
        list[i].parameters[1]=x[0]
        script=x[0]
        if script[trainerMoneyRE]
          # Checking money directly
          operator=$1
          amount=$2.to_i
          params[0]=7
          if operator=="<"
            params[2]=1
            params[1]=amount-1
          elsif operator=="<="
            params[2]=1
            params[1]=amount
          elsif operator==">"
            params[2]=0
            params[1]=amount+1
          elsif operator==">="
            params[2]=0
            params[1]=amount
          end
          changed=true
        elsif script[itemBallRE] && i>0
          # Using pbItemBall on non-item events
          list[i].parameters[1]=script.sub(/pbItemBall/,"pbReceiveItem")
          changed=true
        elsif script[/^\s*(Kernel\.)?(pbTrainerBattle|pbDoubleTrainerBattle)/]
          # Empty trainer battle conditional branches
          j=i+1
          isempty=true
          elseIndex=-1
          # Check if page is empty
          while j<page.list.length
            if list[j].indent<=list[i].indent
              if list[j].code==411 # Else
                elseIndex=j
              else
                break
              end
            end
            if list[j].code!=0 && list[j].code!=411
              isempty=false
              break
            end 
            j+=1
          end
          if isempty
            if elseIndex>=0
              list.insert(elseIndex+1,
                 RPG::EventCommand.new(115,list[i].indent+1,[]) # Exit Event Processing
              )
            else
              list.insert(i+1,
                 RPG::EventCommand.new(0,list[i].indent+1,[]), # Empty Event
                 RPG::EventCommand.new(411,list[i].indent,[]), # Else
                 RPG::EventCommand.new(115,list[i].indent+1,[]) # Exit Event Processing
              )
            end
            changed=true
          end
        end
      end
      i+=1
    end
  end
  return changed ? event : nil
end

def pbConvertToItemEvent(event)
  return nil if !event || event.pages.length==0
  ret=RPG::Event.new(event.x,event.y)
  name=event.name
  ret.name=event.name
  ret.id=event.id
  ret.pages=[]
  itemid=nil
  itemname=""
  hidden=false
  if name[/^HiddenItem\:\s*(\w+)\s*$/]
    itemname=$1
    return nil if !hasConst?(PBItems,itemname)
    itemid=PBItems.const_get(itemname)
    ret.name="HiddenItem"
    hidden=true
  elsif name[/^Item\:\s*(\w+)\s*$/]
    itemname=$1
    return nil if !hasConst?(PBItems,itemname)
    itemid=PBItems.const_get(itemname)
    ret.name="Item"
  else
    return nil
  end
  # Event page 1
  page=RPG::Event::Page.new
  if !hidden
    page.graphic.character_name="Object ball"
  end
  page.list=[]
  pbPushBranch(page.list,
     sprintf("Kernel.pbItemBall(:%s)",itemname))
  pbPushSelfSwitch(page.list,"A",true,1)
  pbPushElse(page.list,1)
  pbPushBranchEnd(page.list,1)
  pbPushEnd(page.list)
  ret.pages.push(page)
  # Event page 2
  page=RPG::Event::Page.new
  page.condition.self_switch_valid=true
  page.condition.self_switch_ch="A"
  ret.pages.push(page)
  return ret
end

def pbConvertToTrainerEvent(event,trainerChecker)
  return nil if !event || event.pages.length==0
  ret=RPG::Event.new(event.x,event.y)
  ret.name=event.name
  ret.id=event.id
  commands=[]
  list=event.pages[0].list
  return nil if list.length<2
  isFirstCommand=false
  i=0; while i<list.length
    if list[i].code==108
      command=list[i].parameters[0]
      j=i+1; while j<list.length
        break if list[j].code!=408
        command+="\r\n"+list[j].parameters[0]
        j+=1
      end
      if command[/^(Battle\:|Type\:|Name\:|EndSpeech\:|VanishIfSwitch\:|EndBattle\:|RegSpeech\:|BattleID\:|EndIfSwitch\:|DoubleBattle\:|Backdrop\:|Continue\:|Outcome\:)/i]
        commands.push(command)
        isFirstCommand=true if i==0
      end
    end
    i+=1
  end
  return nil if commands.length==0
  if isFirstCommand && !event.name[/Trainer/]
    ret.name="Trainer(3)"
  elsif isFirstCommand && event.name[/^\s*Trainer\s+\((\d+)\)\s*$/]
    ret.name="Trainer(#{$1})"
  end
  firstpage=Marshal::load(Marshal.dump(event.pages[0]))
  firstpage.trigger=2
  firstpage.list=[]
  trtype=nil
  trname=nil
  battles=[]
  endbattles=[]
  realcommands=[]
  endspeeches=[]
  regspeech=nil
  backdrop=nil
  battleid=0
  endifswitch=[]
  vanishifswitch=[]
  doublebattle=false
  continue=false
  outcome=0
  for command in commands
    if command[/^Battle\:\s*([\s\S]+)$/i]
      battles.push($~[1])
      pbPushComment(firstpage.list,command)
    end
    if command[/^Type\:\s*([\s\S]+)$/i]
      trtype=$~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")
      pbPushComment(firstpage.list,command)
    end
    if command[/^Name\:\s*([\s\S]+)$/i]
      trname=$~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")
      pbPushComment(firstpage.list,command)
    end
    if command[/^EndSpeech\:\s*([\s\S]+)$/i]
      endspeeches.push($~[1].gsub(/^\s+/,"").gsub(/\s+$/,""))
      pbPushComment(firstpage.list,command)
    end
    if command[/^EndIfSwitch\:\s*([\s\S]+)$/i]
      endifswitch.push(($~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")).to_i)
      pbPushComment(firstpage.list,command)
    end
    if command[/^DoubleBattle\:\s*([\s\S]+)$/i]
      value=$~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")
      doublebattle=true if value.upcase=="TRUE" || value.upcase=="YES"
      pbPushComment(firstpage.list,command)
    end
    if command[/^VanishIfSwitch\:\s*([\s\S]+)$/i]
      vanishifswitch.push(($~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")).to_i)
      pbPushComment(firstpage.list,command)
    end
    if command[/^Backdrop\:\s*([\s\S]+)$/i]
      backdrop=$~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")
      pbPushComment(firstpage.list,command)
    end
    if command[/^RegSpeech\:\s*([\s\S]+)$/i]
      regspeech=$~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")
      pbPushComment(firstpage.list,command)
    end
    if command[/^EndBattle\:\s*([\s\S]+)$/i]
      endbattles.push($~[1].gsub(/^\s+/,"").gsub(/\s+$/,""))
      pbPushComment(firstpage.list,command)
    end
    if command[/^BattleID\:\s*(\d+)$/i]
      battleid=$~[1].to_i
      pbPushComment(firstpage.list,command)
    end
    if command[/^Continue\:\s*([\s\S]+)$/i]
      value=$~[1].gsub(/^\s+/,"").gsub(/\s+$/,"")
      continue=true if value.upcase=="TRUE" || value.upcase=="YES"
      pbPushComment(firstpage.list,command)
    end
    if command[/^Outcome\:\s*(\d+)$/i]
      outcome=$~[1].to_i
      pbPushComment(firstpage.list,command)
    end
  end
  if battles.length<=0
    return nil
  end
  if firstpage.graphic.character_name=="" && hasConst?(PBTrainers,trtype)
    trainerid=getConst(PBTrainers,trtype)
    if trainerid
      filename=pbTrainerCharNameFile(trainerid)
      if FileTest.image_exist?("Graphics/Characters/"+filename)
        firstpage.graphic.character_name=sprintf(filename)
      end
    end
  end
  safetrcombo=sprintf("PBTrainers:"+":%s,\"%s\"",trtype,safequote(trname))
  safetrcombo2=sprintf(":%s,\"%s\"",trtype,safequote(trname))
  introplay=sprintf("pbTrainerIntro(:%s)",trtype)
  pbPushScript(firstpage.list,introplay)
  pbPushScript(firstpage.list,"Kernel.pbNoticePlayer(get_character(0))")
  pbPushText(firstpage.list,battles[0])
  if battles.length>1
    pbPushScript(firstpage.list,sprintf("Kernel.pbTrainerCheck(%s,%d,%d)",safetrcombo2,battles.length,battleid))
  end
  if backdrop
    pbPushScript(firstpage.list,sprintf("$PokemonGlobal.nextBattleBack=\"%s\"",safequote(backdrop)))
  end
  espeech=(endspeeches[0]) ? endspeeches[0] : "..."
  # Run trainer check now, except in editor
  trainerChecker.pbTrainerBattleCheck(trtype,trname,battleid) if !$INEDITOR
  pbPushBranch(firstpage.list,
     sprintf("pbTrainerBattle(%s,_I(\"%s\"),%s,%d,%s,%d)",
     safetrcombo,safequote2(espeech),
     doublebattle ? "true" : "false",
     battleid,
     continue ? "true" : "false",
     outcome)
  )
  if battles.length>1
    pbPushScript(firstpage.list,sprintf("pbPhoneRegisterBattle(_I(\"%s\"),get_character(0),%s,%d)",regspeech,safetrcombo,battles.length),1)
  end
  pbPushSelfSwitch(firstpage.list,"A",true,1)
  pbPushBranchEnd(firstpage.list,1)
  pbPushScript(firstpage.list,"pbTrainerEnd",0)
  pbPushEnd(firstpage.list)
  secondpage=Marshal::load(Marshal.dump(firstpage))
  secondpage.list=[]
  secondpage.trigger=0
  secondpage.condition=firstpage.condition.clone
  thirdpage=Marshal::load(Marshal.dump(secondpage))
  thirdpage.list=secondpage.list.clone
  thirdpage.condition=secondpage.condition.clone
  secondpage.condition.self_switch_valid=true
  secondpage.condition.self_switch_ch="A"
  thirdpage.condition.self_switch_valid=true
  thirdpage.condition.self_switch_ch="B"
  for i in 1...battles.length
    if endspeeches.length==0
      espeech="..."
    else
      espeech=(endspeeches[i]) ? endspeeches[i] : endspeeches[endspeeches.length-1]
    end
    if endbattles.length==0
      ebattle=nil
    else
      ebattle=(endbattles[i]) ? endbattles[i] : endbattles[endbattles.length-1]
    end
    if i==battles.length-1
      pbPushBranch(thirdpage.list,sprintf("pbPhoneBattleCount(%s)>=%d",safetrcombo,i))
      pbPushBranch(secondpage.list,sprintf("pbPhoneBattleCount(%s)>%d",safetrcombo,i))
    else
      pbPushBranch(thirdpage.list,sprintf("pbPhoneBattleCount(%s)==%d",safetrcombo,i))
      pbPushBranch(secondpage.list,sprintf("pbPhoneBattleCount(%s)==%d",safetrcombo,i))
    end
    pbPushText(secondpage.list,ebattle,1)
    pbPushScript(secondpage.list,sprintf("pbPhoneRegisterBattle(_I(\"%s\"),get_character(0),%s,%d)",regspeech,safetrcombo,battles.length),1)
    pbPushExit(secondpage.list,1)
    pbPushBranchEnd(secondpage.list,1)
    pbPushScript(thirdpage.list,introplay,1)
    pbPushText(thirdpage.list,battles[i],1)
    # Run trainer check now, except in editor
    trainerChecker.pbTrainerBattleCheck(trtype,trname,battleid+i) if !$INEDITOR
    if backdrop
      pbPushScript(thirdpage.list,sprintf("$PokemonGlobal.nextBattleBack=\"%s\"",safequote(backdrop)),1)
    end
    pbPushBranch(thirdpage.list,
       sprintf("pbTrainerBattle(%s,_I(\"%s\"),%s,%d,%s,%d)",
       safetrcombo,safequote2(espeech),
       doublebattle ? "true" : "false",
       battleid+i,
       continue ? "true" : "false",
       outcome),1
    )
    pbPushScript(thirdpage.list,
       sprintf("pbPhoneIncrement(%s,%d)",safetrcombo,battles.length),2)
    pbPushSelfSwitch(thirdpage.list,"A",true,2)
    pbPushSelfSwitch(thirdpage.list,"B",false,2)
    pbPushScript(thirdpage.list,"pbTrainerEnd",2)
    pbPushBranchEnd(thirdpage.list,2)
    pbPushExit(thirdpage.list,1)
    pbPushBranchEnd(thirdpage.list,1)
  end
  ebattle=(endbattles[0]) ? endbattles[0] : "..."
  pbPushText(secondpage.list,ebattle)
  if battles.length>1
    pbPushScript(secondpage.list,sprintf("pbPhoneRegisterBattle(_I(\"%s\"),get_character(0),%s,%d)",regspeech,safetrcombo,battles.length))
  end
  pbPushEnd(secondpage.list)
  pbPushEnd(thirdpage.list)
  if battles.length==1
    ret.pages=[firstpage,secondpage]
  else
    ret.pages=[firstpage,thirdpage,secondpage]
  end
  for endswitch in endifswitch
    ebattle=(endbattles[0]) ? endbattles[0] : "..."
    endIfSwitchPage=Marshal::load(Marshal.dump(secondpage))
    endIfSwitchPage.condition=secondpage.condition.clone
    if endIfSwitchPage.condition.switch1_valid
      endIfSwitchPage.condition.switch2_valid=true
      endIfSwitchPage.condition.switch2_id=endswitch
    else
      endIfSwitchPage.condition.switch1_valid=true
      endIfSwitchPage.condition.switch1_id=endswitch
    end
    endIfSwitchPage.condition.self_switch_valid=false
    endIfSwitchPage.list=[]
    pbPushText(endIfSwitchPage.list,ebattle)
    pbPushEnd(endIfSwitchPage.list)
    ret.pages.push(endIfSwitchPage)
  end
  for endswitch in vanishifswitch
    ebattle=(endbattles[0]) ? endbattles[0] : "..."
    endIfSwitchPage=Marshal::load(Marshal.dump(secondpage))
    endIfSwitchPage.graphic.character_name="" # make blank
    endIfSwitchPage.condition=secondpage.condition.clone
    if endIfSwitchPage.condition.switch1_valid
      endIfSwitchPage.condition.switch2_valid=true
      endIfSwitchPage.condition.switch2_id=endswitch
    else
      endIfSwitchPage.condition.switch1_valid=true
      endIfSwitchPage.condition.switch1_id=endswitch
    end
    endIfSwitchPage.condition.self_switch_valid=false
    endIfSwitchPage.list=[]
    pbPushEnd(endIfSwitchPage.list)
    ret.pages.push(endIfSwitchPage)
  end
  return ret
end

#===============================================================================
# Se agregan los archivos de mapas nuevos al árbol de mapas
#===============================================================================
def pbImportNewMaps
  return false if !$DEBUG
  mapfiles={}
  # Obtiene los IDs de todos los mapas de la carpeta Data
  Dir.chdir("Data"){
     mapdata=sprintf("Map*.%s","rxdata",$RPGVX ? "rvdata" : "rxdata")
     for map in Dir.glob(mapdata)
       if map[/map(\d+)\.rxdata/i]
         mapfiles[$1.to_i(10)]=true
       end
     end
  }
  mapinfos=pbLoadRxData("Data/MapInfos")
  maxOrder=0
  # Excluye los mapas encontrados en mapinfos
  for id in mapinfos.keys
    next if !mapinfos.id
    if mapfiles[id]
      mapfiles.delete(id)
    end
    maxOrder=[maxOrder,mapinfos[id].order].max
  end
  # Importa los mapas no encontrados en mapinfos
  maxOrder+=1
  imported=false
  for id in mapfiles.keys
    next if id==999                 # Ignora 999 (mapa aleatorio para mazmorras)
    mapname=sprintf("MAP%03d",id)
    mapinfo=RPG::MapInfo.new
    mapinfo.order=maxOrder
    maxOrder+=1
    mapinfo.name=mapname
    mapinfos[id]=mapinfo
    imported=true
  end
  if imported
    if $RPGVX
      save_data(mapinfos,"Data/MapInfos.rvdata")
    else
      save_data(mapinfos,"Data/MapInfos.rxdata") 
    end
    Kernel.pbMessage(_INTL("Los mapas nuevos en la carpeta Data fueron importados correctamente.",id))
  end
  return imported
end

#===============================================================================
# Compilación de todos los datos
#===============================================================================
def pbCompileAllData(mustcompile)
  FileLineData.clear
  if mustcompile
    if (!$INEDITOR || LANGUAGES.length<2) && pbRgssExists?("Data/messages.dat")
      MessageTypes.loadMessageFile("Data/messages.dat")
    end
    # No dependencies
    yield(_INTL("Compilando datos de los tipos"))
    pbCompileTypes
    # No dependencies
    yield(_INTL("Compilando datos del mapa de la región"))
    pbCompileTownMap
    # No dependencies
    yield(_INTL("Compilando datos de las conexiones de los mapas"))
    pbCompileConnections
    # No dependencies  
    yield(_INTL("Compilando datos de las habilidades"))
    pbCompileAbilities
    # Depends on PBTypes
    yield(_INTL("Compilando datos de los movimientos"))
    pbCompileMoves
    # Depends on PBMoves
    yield(_INTL("Compilando datos de los objetos"))
    pbCompileItems
    # Depends on PBItems
    yield(_INTL("Compilando datos de las plantas de bayas"))
    pbCompileBerryPlants
    # Depends on PBMoves, PBItems, PBTypes, PBAbilities
    yield(_INTL("Compilando datos de los Pokemon"))
    pbCompilePokemonData
    # Depends on PBSpecies, PBMoves
    yield(_INTL("Compilando datos de las máquinas"))
    pbCompileMachines
    # Depends on PBSpecies, PBItems, PBMoves
    yield(_INTL("Compilando datos de los entrenadores"))
    pbCompileTrainers
    # Depends on PBTrainers
    yield(_INTL("Compilando datos del celular"))
    pbCompilePhoneData
    # Depends on PBTrainers
    yield(_INTL("Compilando metadatos"))
    pbCompileMetadata
    # Depends on PBTrainers
    yield(_INTL("Compilando datos de batallas con entrenadores"))
    pbCompileTrainerLists
    # Depends on PBSpecies
    yield(_INTL("Compilando datos de los encuentros"))
    pbCompileEncounters
    # Depends on PBSpecies, PBMoves
    yield(_INTL("Compilando datos de los movimientos oscuros"))
    pbCompileShadowMoves
    yield(_INTL("Compilando mensajes"))
#    save_data([],"Data/dlcs.dat") if $DEBUG
  else
    if (!$INEDITOR || LANGUAGES.length<2) && safeExists?("Data/messages.dat")
      MessageTypes.loadMessageFile("Data/messages.dat")
    end
  end
  pbCompileAnimations
  pbCompileTrainerEvents(mustcompile)
  pbSetTextMessages
  MessageTypes.saveMessages
  if !$INEDITOR && LANGUAGES.length>=2
    pbLoadMessages("Data/"+LANGUAGES[$PokemonSystem.language][1])
  end
end

begin
  if $DEBUG
    datafiles=["attacksRS.dat",
               "berryplants.dat",
               "connections.dat",
               "dexdata.dat",
               "eggEmerald.dat",
               "encounters.dat",
               "evolutions.dat",
               "items.dat",
               "metadata.dat",
               "metrics.dat",
               "moves.dat",
               "phone.dat",
               "regionals.dat",
               "shadowmoves.dat",
               "tm.dat",
               "townmap.dat",
               "trainerlists.dat",
               "trainers.dat",
               "trainertypes.dat",
               "types.dat",
               "Constants.rxdata"]
    textfiles=["abilities.txt",
               "berryplants.txt",
               "connections.txt",
               "encounters.txt",
               "items.txt",
               "metadata.txt",
               "moves.txt",
               "phone.txt",
               "pokemon.txt",
               "shadowmoves.txt",
               "tm.txt",
               "townmap.txt",
               "trainerlists.txt",
               "trainers.txt",
               "trainertypes.txt",
               "types.txt"]
    latestdatatime=0
    latesttexttime=0
    mustcompile=false
    mustcompile|=pbImportNewMaps
    mustcompile|=!(PBSpecies.respond_to?("maxValue") rescue false)
    if !safeIsDirectory?("PBS")
      Dir.mkdir("PBS") rescue nil
      pbSaveAllData()
      mustcompile=true
    end
    for i in 0...datafiles.length
      begin
        File.open("Data/#{datafiles[i]}"){|file|
           latestdatatime=[latestdatatime,file.mtime.to_i].max
        }
      rescue SystemCallError
        mustcompile=true
      end
    end
    for i in 0...textfiles.length
      begin
        File.open("PBS/#{textfiles[i]}"){|file|
           latesttexttime=[latesttexttime,file.mtime.to_i].max
        }
      rescue SystemCallError
      end
    end
    mustcompile=mustcompile || (latesttexttime>=latestdatatime)
    Input.update
    mustcompile=true if Input.press?(Input::CTRL)
    if mustcompile
      for i in 0...datafiles.length
        begin
          File.delete("Data/#{datafiles[i]}")
        rescue SystemCallError
        end
      end
    end
    pbCompileAllData(mustcompile){|msg| Win32API.SetWindowText(msg) }
  end
rescue Exception
  e=$!
  raise e if "#{e.class}"=="Reset" || e.is_a?(Reset) || e.is_a?(SystemExit)
  pbPrintException(e)
  for i in 0...datafiles.length
    begin
      File.delete("Data/#{datafiles[i]}")
    rescue SystemCallError
    end
  end
  raise Reset.new if e.is_a?(Hangup)
  loop do
    Graphics.update
  end
end