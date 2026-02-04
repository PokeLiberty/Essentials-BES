def pbAddScriptTexts(items,script)
  script.scan(/(?:_I)\s*\(\s*\"((?:[^\\\"]*\\\"?)*[^\"]*)\"/){|s|
     string=s[0]
     string.gsub!(/\\\"/,"\"")
     string.gsub!(/\\\\/,"\\")
     items.push(string)
  }
end

def pbAddRgssScriptTexts(items,script)
  script.scan(/(?:_INTL|_ISPRINTF)\s*\(\s*\"((?:[^\\\"]*\\\"?)*[^\"]*)\"/){|s|
     string=s[0]
     string.gsub!(/\\r/,"\r")
     string.gsub!(/\\n/,"\n")
     string.gsub!(/\\1/,"\1")
     string.gsub!(/\\\"/,"\"")
     string.gsub!(/\\\\/,"\\")
     items.push(string)
  }
end

def pbSetTextMessages
  Graphics.update
  begin
    t = Time.now.to_i
    texts=[]
    for script in $RGSS_SCRIPTS
      if Time.now.to_i - t >= 5
        t = Time.now.to_i
        Graphics.update
      end
      scr=Zlib::Inflate.inflate(script[2])
      pbAddRgssScriptTexts(texts,scr)
    end
    # Se deben agregar mensajes porque este código es usado tanto en el sistema del juego como el Editor.
    MessageTypes.addMessagesAsHash(MessageTypes::ScriptTexts,texts)
    commonevents=pbLoadRxData("Data/CommonEvents")
    items=[]
    choices=[]
    for event in commonevents.compact
      if Time.now.to_i - t >= 5
        t = Time.now.to_i
        Graphics.update
      end
      begin
        neednewline=false
        lastitem=""
        for j in 0...event.list.size
          list = event.list[j]
          if neednewline && list.code!=401
            if lastitem!=""
              lastitem.gsub!(/([^\.\!\?])\s\s+/){|m| $1+" "}
              items.push(lastitem)
              lastitem=""
            end         
            neednewline=false
          end
          if list.code == 101
            lastitem+="#{list.parameters[0]}"
            neednewline=true
          elsif list.code == 102
            for k in 0...list.parameters[0].length
              choices.push(list.parameters[0][k])
            end
            neednewline=false
          elsif list.code == 401
            lastitem+=" " if lastitem!=""
            lastitem+="#{list.parameters[0]}"
            neednewline=true
          elsif list.code == 355 || list.code == 655
            pbAddScriptTexts(items,list.parameters[0])
          elsif list.code == 111 && list.parameters[0]==12
            pbAddScriptTexts(items,list.parameters[1])
          elsif list.code == 209
            route=list.parameters[1]
            for k in 0...route.list.size
              if route.list[k].code == 45
                pbAddScriptTexts(items,route.list[k].parameters[0])
              end
            end
          end
        end
        if neednewline
          if lastitem!=""
            items.push(lastitem)
            lastitem=""
          end         
        end
      end
    end
    if Time.now.to_i - t >= 5
      t = Time.now.to_i
      Graphics.update
    end
    items|=[]
    choices|=[]
    items.concat(choices)
    MessageTypes.setMapMessagesAsHash(0,items)
    mapinfos = pbLoadRxData("Data/MapInfos")
    mapnames=[]
    for id in mapinfos.keys
      mapnames[id]=mapinfos[id].name
    end
    MessageTypes.setMessages(MessageTypes::MapNames,mapnames)
    for id in mapinfos.keys
      if Time.now.to_i - t >= 5
        t = Time.now.to_i
        Graphics.update
      end
      filename=sprintf("Data/Map%03d.%s",id,"rxdata")
      next if !pbRgssExists?(filename)
      map = load_data(filename)
      items=[]
      choices=[]
      for event in map.events.values
        if Time.now.to_i - t >= 5
          t = Time.now.to_i
          Graphics.update
        end
        begin
          for i in 0...event.pages.size
            neednewline=false
            lastitem=""
            for j in 0...event.pages[i].list.size
              list = event.pages[i].list[j]
              if neednewline && list.code!=401
                if lastitem!=""
                  lastitem.gsub!(/([^\.\!\?])\s\s+/){|m| $1+" "}
                  items.push(lastitem)
                  lastitem=""
                end         
                neednewline=false
              end
              if list.code == 101
                lastitem+="#{list.parameters[0]}"
                neednewline=true
              elsif list.code == 102
                for k in 0...list.parameters[0].length
                  choices.push(list.parameters[0][k])
                end
                neednewline=false
              elsif list.code == 401
                lastitem+=" " if lastitem!=""
                lastitem+="#{list.parameters[0]}"
                neednewline=true
              elsif list.code == 355 || list.code==655
                pbAddScriptTexts(items,list.parameters[0])
              elsif list.code == 111 && list.parameters[0]==12
                pbAddScriptTexts(items,list.parameters[1])
              elsif list.code==209
                route=list.parameters[1]
                for k in 0...route.list.size
                  if route.list[k].code==45
                    pbAddScriptTexts(items,route.list[k].parameters[0])
                  end
                end
              end
            end
            if neednewline
              if lastitem!=""
                items.push(lastitem)
                lastitem=""
              end         
            end
          end
        end
      end
      if Time.now.to_i - t >= 5
        t = Time.now.to_i
        Graphics.update
      end
      items|=[]
      choices|=[]
      items.concat(choices)
      MessageTypes.setMapMessagesAsHash(id,items)
      if Time.now.to_i - t >= 5
        t = Time.now.to_i
        Graphics.update
      end
    end
  rescue Hangup
  end
  Graphics.update
end

def pbEachIntlSection(file)
  lineno=1
  re=/^\s*\[\s*([^\]]+)\s*\]\s*$/
  havesection=false
  sectionname=nil
  lastsection=[]
  file.each_line {|line|
     if lineno==1 && line[0]==0xEF && line[1]==0xBB && line[2]==0xBF
       line=line[3,line.length-3]
     end
     if !line[/^\#/] && !line[/^\s*$/]
       if line[re]
         if havesection
           yield lastsection,sectionname 
         end
         lastsection.clear
         sectionname=$~[1]
         havesection=true
       else
         if sectionname==nil
           raise _INTL("Se esperaba una identificación de sección al inicio del archivo (línea {1})",lineno)
         end
         lastsection.push(line.gsub(/\s+$/,""))
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

def pbGetText(infile)
  begin
    file=File.open(infile,"rb") 
  rescue
    raise _INTL("No se pudo encontrar {1}",infile)
  end
  intldat=[]
  begin
    pbEachIntlSection(file){|section,name|
       index=name
       if section.length==0
         next
       end
       if !name[/^([Mm][Aa][Pp])?(\d+)$/]
         raise _INTL("Nombre de sección inválido {1}",name)
       end
       ismap=$~[1] && $~[1]!=""
       id=$~[2].to_i
       itemlength=0
       if section[0][/^\d+$/]
         intlhash=[]
         itemlength=3
         if ismap
           raise _INTL("La sección {1} no puede ser una lista ordenada (la sección ha sido interpretada como una lista ordenada porque su primer línea es un número)",name)
         end
         if section.length%3!=0
           raise _INTL("La cuenta de líneas de la sección {1} no es divisible en 3 (la sección ha sido interpretada como una lista ordenada porque su primer línea es un número)",name)
         end
       else
         intlhash=OrderedHash.new
         itemlength=2
         if section.length%2!=0
           raise _INTL("La sección {1} tiene una cantidad extraña de entradas (la sección ha sido interpretada como una hash porque su primer línea no es un número)",name)
         end
       end
       i=0;loop do break unless i<section.length
         if itemlength==3
           if !section[i][/^\d+$/]
             raise _INTL("Se esperaba un número en la sección {1}, en su lugar se obtuvo {2}",name,section[i])
           end
           key=section[i].to_i
           i+=1
         else
           key=MessageTypes.denormalizeValue(section[i])
         end
         intlhash[key]=MessageTypes.denormalizeValue(section[i+1])
         i+=2
       end
       if ismap
         intldat[0]=[] if !intldat[0]
         intldat[0][id]=intlhash
       else
         intldat[id]=intlhash
       end
    }
  ensure
    file.close
  end
  return intldat
end

def pbCompileText
  outfile=File.open("intl.dat","wb")
  begin
    intldat=pbGetText("intl.txt")
    Marshal.dump(intldat,outfile)
  rescue
    raise
  ensure
    outfile.close
  end
end



class OrderedHash < Hash
  def initialize
    @keys=[]
    super
  end

  def keys
    return @keys.clone
  end

  def inspect
    str="{"
    for i in 0...@keys.length
      str+=", " if i>0
      str+=@keys[i].inspect+"=>"+self[@keys[i]].inspect
    end
    str+="}"
    return str
  end

  alias :to_s :inspect

  def []=(key,value)
    oldvalue=self[key]
    if !oldvalue && value
      @keys.push(key)
    elsif !value
      @keys|=[]
      @keys-=[key]
    end
    return super(key,value)
  end

  def self._load(string)
    ret=self.new
    keysvalues=Marshal.load(string)
    keys=keysvalues[0]
    values=keysvalues[1]
    for i in 0...keys.length
      ret[keys[i]]=values[i]
    end
    return ret
  end

  def _dump(depth=100)
    values=[]
    for key in @keys
      values.push(self[key])
    end
    return Marshal.dump([@keys,values])
  end
end



class Messages
  def initialize(filename=nil,delayLoad=false)
    @messages=nil
    @filename=filename
    if @filename && !delayLoad
      loadMessageFile(@filename)
    end
  end

  def delayedLoad
    if @filename && !@messages
      loadMessageFile(@filename)
      @filename=nil
    end
  end

  def self.stringToKey(str)
    if str[/[\r\n\t\1]|^\s+|\s+$|\s{2,}/]
       key=str.clone
       key.gsub!(/^\s+/,"")
       key.gsub!(/\s+$/,"")
       key.gsub!(/\s{2,}/," ")
       return key
    end
    return str
  end

  def self.normalizeValue(value)
    value = value.to_s
    if value[/[\r\n\t\x01]|^[\[\]]/]
      ret=value.clone
      ret.gsub!(/\r/,"<<r>>")
      ret.gsub!(/\n/,"<<n>>")
      ret.gsub!(/\t/,"<<t>>")
      ret.gsub!(/\[/,"<<[>>")
      ret.gsub!(/\]/,"<<]>>")
      ret.gsub!(/\x01/,"<<1>>")
      return ret
    end
    return value
  end

  def self.denormalizeValue(value)
    if value[/<<[rnt1\[\]]>>/]
      ret=value.clone
      ret.gsub!(/<<1>>/,"\1")
      ret.gsub!(/<<r>>/,"\r")
      ret.gsub!(/<<n>>/,"\n")
      ret.gsub!(/<<\[>>/,"[")
      ret.gsub!(/<<\]>>/,"]")
      ret.gsub!(/<<t>>/,"\t")
      return ret
    end
    return value
  end

  def self.writeObject(f,msgs,secname,origMessages=nil)
    return if !msgs
    if msgs.is_a?(Array)
      f.write("[#{secname}]\r\n")
      for j in 0...msgs.length
        next if msgs[j]==nil || msgs[j]==""
        value=Messages.normalizeValue(msgs[j])
        origValue=""
        if origMessages
          origValue=Messages.normalizeValue(origMessages.get(secname,j))
        else
          origValue=Messages.normalizeValue(MessageTypes.get(secname,j))
        end
        f.write("#{j}\r\n")
        f.write(origValue+"\r\n")
        f.write(value+"\r\n")
      end
    elsif msgs.is_a?(OrderedHash)
      f.write("[#{secname}]\r\n")
      keys=msgs.keys
      for key in keys
        next if msgs[key]==nil || msgs[key]==""
        value=Messages.normalizeValue(msgs[key])
        valkey=Messages.normalizeValue(key)
        # key is already serialized
        f.write(valkey+"\r\n")
        f.write(value+"\r\n")
      end
    end
  end

  def messages
    return @messages || []
  end

  def extract(outfile)
#    return if !@messages
    origMessages=Messages.new("Data/messages.dat")
    File.open(outfile,"wb"){|f|
       f.write(0xef.chr)
       f.write(0xbb.chr)
       f.write(0xbf.chr)
       f.write("# To localize this text for a particular language, please\r\n")
       f.write("# translate every second line of this file.\r\n")
       if origMessages.messages[0]
         for i in 0...origMessages.messages[0].length
           msgs=origMessages.messages[0][i]
           Messages.writeObject(f,msgs,"Map#{i}",origMessages)
         end
       end
       for i in 1...origMessages.messages.length
         msgs=origMessages.messages[i]
         Messages.writeObject(f,msgs,i,origMessages)
       end
    }
  end

  def setMessages(type,array)
    @messages=[] if !@messages
    arr=[]
    for i in 0...array.length
      arr[i]=(array[i]) ? array[i] : ""
    end
    @messages[type]=arr
  end

  def addMessages(type,array)
    @messages=[] if !@messages
    arr=(@messages[type]) ? @messages[type] : []
    for i in 0...array.length
      arr[i]=(array[i]) ? array[i] : (arr[i]) ? arr[i] : ""
    end
    @messages[type]=arr
  end

  def self.createHash(type,array)
    arr=OrderedHash.new
    for i in 0...array.length
      if array[i]
        key=Messages.stringToKey(array[i])
        arr[key]=array[i]
      end
    end
    return arr
  end

  def self.addToHash(type,array,hash)
    if !hash
      hash=OrderedHash.new
    end
    for i in 0...array.length
      if array[i]
        key=Messages.stringToKey(array[i])
        hash[key]=array[i]
      end
    end
    return hash
  end

  def setMapMessagesAsHash(type,array)
    @messages=[] if !@messages
    @messages[0]=[] if !@messages[0]
    @messages[0][type]=Messages.createHash(type,array)
  end

  def addMapMessagesAsHash(type,array)
    @messages=[] if !@messages
    @messages[0]=[] if !@messages[0]
    @messages[0][type]=Messages.addToHash(type,array,@messages[0][type])
  end

  def setMessagesAsHash(type,array)
    @messages=[] if !@messages
    @messages[type]=Messages.createHash(type,array)
  end

  def addMessagesAsHash(type,array)
    @messages=[] if !@messages
    @messages[type]=Messages.addToHash(type,array,@messages[type])
  end

  def saveMessages(filename=nil)
    filename="Data/messages.dat" if !filename
    File.open(filename,"wb"){|f|
       Marshal.dump(@messages,f)
    }
  end

  def loadMessageFile(filename)
    begin
      Kernel.pbRgssOpen(filename,"rb"){|f|
         @messages=Marshal.load(f)
      }
      if !@messages.is_a?(Array)
        @messages=nil
        raise "Corrupted data"
      end
      return @messages
    rescue
      @messages=nil
      return nil
    end
  end

  def set(type,id,value)
    delayedLoad
    return if !@messages
    return if !@messages[type]
    @messages[type][id]=value
  end

  def getCount(type)
    delayedLoad
    return 0 if !@messages
    return 0 if !@messages[type]
    return @messages[type].length
  end

  def get(type,id)
    delayedLoad
    return "" if !@messages
    return "" if !@messages[type]
    return "" if !@messages[type][id]
    return @messages[type][id]
  end

  def getFromHash(type,key)
    delayedLoad
    return key if !@messages
    return key if !@messages[type]
    id=Messages.stringToKey(key)
    return key if !@messages[type][id]
    return @messages[type][id]
  end

  def getFromMapHash(type,key)
    delayedLoad
    return key if !@messages
    return key if !@messages[0]
    return key if !@messages[0][type] && !@messages[0][0]
    id=Messages.stringToKey(key)
    if @messages[0][type] &&  @messages[0][type][id]
      return @messages[0][type][id]
    elsif @messages[0][0] && @messages[0][0][id]
      return @messages[0][0][id]
    end
    return key
  end
end



module MessageTypes
  # Value 0 is used for common event and map event text
  Species           = 1
  Kinds             = 2
  Entries           = 3
  FormNames         = 4
  Moves             = 5
  MoveDescriptions  = 6
  Items             = 7
  ItemPlurals       = 8
  ItemDescriptions  = 9
  Abilities         = 10
  AbilityDescs      = 11
  Types             = 12
  TrainerTypes      = 13
  TrainerNames      = 14
  BeginSpeech       = 15
  EndSpeechWin      = 16
  EndSpeechLose     = 17
  RegionNames       = 18
  PlaceNames        = 19
  PlaceDescriptions = 20
  MapNames          = 21
  PhoneMessages     = 22
  ScriptTexts       = 23
  @@messages         = Messages.new
  @@messagesFallback = Messages.new("Data/messages.dat",true)

  def self.stringToKey(str)
    return Messages.stringToKey(str)
  end

  def self.normalizeValue(value)
    return Messages.normalizeValue(value)
  end

  def self.denormalizeValue(value)
    Messages.denormalizeValue(value)
  end

  def self.writeObject(f,msgs,secname)
    Messages.denormalizeValue(str)
  end

  def self.extract(outfile)
    @@messages.extract(outfile)
  end

  def self.setMessages(type,array)
    @@messages.setMessages(type,array)
  end

  def self.addMessages(type,array)
    @@messages.addMessages(type,array)
  end

  def self.createHash(type,array)
    Messages.createHash(type,array)
  end

  def self.addMapMessagesAsHash(type,array)
    @@messages.addMapMessagesAsHash(type,array)
  end

  def self.setMapMessagesAsHash(type,array)
    @@messages.setMapMessagesAsHash(type,array)
  end

  def self.addMessagesAsHash(type,array)
    @@messages.addMessagesAsHash(type,array)
  end

  def self.setMessagesAsHash(type,array)
    @@messages.setMessagesAsHash(type,array)
  end

  def self.saveMessages(filename=nil)
    @@messages.saveMessages(filename)
  end

  def self.loadMessageFile(filename)
    @@messages.loadMessageFile(filename)
  end

  def self.get(type,id)
    ret=@@messages.get(type,id)
    if ret==""
      ret=@@messagesFallback.get(type,id)
    end
    return ret
  end

  def self.getCount(type)
    c1=@@messages.getCount(type)
    c2=@@messagesFallback.getCount(type)
    return c1>c2 ? c1 : c2
  end

  def self.getOriginal(type,id)
    return @@messagesFallback.get(type,id)
  end

  def self.getFromHash(type,key)
    @@messages.getFromHash(type,key)
  end

  def self.getFromMapHash(type,key)
    @@messages.getFromMapHash(type,key)
  end
end



def pbLoadMessages(file)
  return MessageTypes.loadMessageFile(file)
end

def pbGetMessageCount(type)
  return MessageTypes.getCount(type)
end

def pbGetMessage(type,id)
  return MessageTypes.get(type,id)
end

def pbGetMessageFromHash(type,id)
  return MessageTypes.getFromHash(type,id)
end

# Replaces first argument with a localized version and formats the other
# parameters by replacing {1}, {2}, etc. with those placeholders.
def _INTL(*arg)
  begin
    string=MessageTypes.getFromHash(MessageTypes::ScriptTexts,arg[0])
  rescue
    string=arg[0]
  end
  string=string.clone
  for i in 1...arg.length
    string.gsub!(/\{#{i}\}/,"#{arg[i]}")
  end
  return string
end

# Replaces first argument with a localized version and formats the other
# parameters by replacing {1}, {2}, etc. with those placeholders.
# This version acts more like sprintf, supports e.g. {1:d} or {2:s}
def _ISPRINTF(*arg)
  begin
    string=MessageTypes.getFromHash(MessageTypes::ScriptTexts,arg[0])
  rescue
    string=arg[0]
  end
  string=string.clone
  for i in 1...arg.length
    string.gsub!(/\{#{i}\:([^\}]+?)\}/){|m|
       next sprintf("%"+$1,arg[i])
    }
  end
  return string
end

def _I(str)
  return _MAPINTL($game_map.map_id,str)
end

def _MAPINTL(mapid,*arg)
  string=MessageTypes.getFromMapHash(mapid,arg[0])
  string=string.clone
  for i in 1...arg.length
    string.gsub!(/\{#{i}\}/,"#{arg[i]}")
  end
  return string
end

def _MAPISPRINTF(mapid,*arg)
  string=MessageTypes.getFromMapHash(mapid,arg[0])
  string=string.clone
  for i in 1...arg.length
    string.gsub!(/\{#{i}\:([^\}]+?)\}/){|m|
       next sprintf("%"+$1,arg[i])
    }
  end
  return string
end


################################################################################################
# BES-T
# Permite separar los archivos para la traducción en varios archivos distintos y 2 carpetas.
# La compilación la manda automaticamente a Data.
# Necesita que LANGUAGES en Settings este configurado correctamente.
################################################################################################
module MessageTypes
  
  CORE_TYPES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  
  TYPE_NAMES = {
    0 => "EVENT_TEXTS",
    1 => "SPECIES_NAMES",
    2 => "SPECIES_CATEGORIES",
    3 => "POKEDEX_ENTRIES",
    4 => "SPECIES_FORM_NAMES",
    5 => "MOVE_NAMES",
    6 => "MOVE_DESCRIPTIONS",
    7 => "ITEM_NAMES",
    8 => "ITEM_NAME_PLURALS",
    9 => "ITEM_DESCRIPTIONS",
    10 => "ABILITY_NAMES",
    11 => "ABILITY_DESCRIPTIONS",
    12 => "TYPE_NAMES",
    13 => "TRAINER_TYPE_NAMES",
    14 => "TRAINER_NAMES",
    15 => "FRONTIER_INTRO_SPEECHES",
    16 => "FRONTIER_END_SPEECHES_WIN",
    17 => "FRONTIER_END_SPEECHES_LOSE",
    18 => "REGION_NAMES",
    19 => "REGION_LOCATION_NAMES",
    20 => "REGION_LOCATION_DESCRIPTIONS",
    21 => "MAP_NAMES",
    22 => "PHONE_MESSAGES",
    23 => "SCRIPT_TEXTS"
  }
  
  # Tipos que usan IDs numéricas (todos los Core + MAP_NAMES)
  INDEXED_TYPES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 18, 21]
  
  def self.isIndexedType?(type)
    return INDEXED_TYPES.include?(type)
  end
  
  def self.isCoreType?(type)
    return CORE_TYPES.include?(type)
  end
  
  def self.getTypeName(type)
    return TYPE_NAMES[type] ? TYPE_NAMES[type] : "Type#{type}"
  end
end

class Messages
  def self.writeTypeToFile(f, msgs, secname, origMessages=nil, omitIndex=false)
    return if !msgs
    if msgs.is_a?(Array)
      f.write("[#{secname}]\r\n")
      for j in 0...msgs.length
        next if nil_or_empty?(msgs[j])
        value = Messages.normalizeValue(msgs[j])
        origValue = ""
        if origMessages
          origValue = Messages.normalizeValue(origMessages.get(secname, j))
        else
          origValue = Messages.normalizeValue(MessageTypes.get(secname, j))
        end
        if !omitIndex
          f.write("#{j}\r\n")
        end
        f.write(origValue + "\r\n")
        f.write(value + "\r\n")
      end
    elsif msgs.is_a?(OrderedHash)
      f.write("[#{secname}]\r\n")
      keys = msgs.keys
      for key in keys
        next if nil_or_empty?(msgs[key])
        value = Messages.normalizeValue(msgs[key])
        valkey = Messages.normalizeValue(key)
        f.write(valkey + "\r\n")
        f.write(value + "\r\n")
      end
    end
  end
  
  def extractByType
    origMessages = Messages.new("Data/messages.dat")
    
    # Crear directorios si no existen
    Dir.mkdir("Translation_Core") rescue nil
    Dir.mkdir("Translation_Game") rescue nil
    
    # Extraer mensajes de mapas (tipo 0) - va a Game
    if origMessages.messages[0]
      File.open("Translation_Game/MapEvents.txt", "wb") { |f|
        f.write(0xef.chr)
        f.write(0xbb.chr)
        f.write(0xbf.chr)
        f.write("# Map Events and Common Events\r\n")
        f.write("# To localize this text, translate every second line.\r\n")
        
        for i in 0...origMessages.messages[0].length
          msgs = origMessages.messages[0][i]
          if msgs && !msgs.empty?
            Messages.writeTypeToFile(f, msgs, "Map#{i}", origMessages)
          end
        end
      }
    end
    
    # Extraer cada MessageType individualmente
    for i in 1...origMessages.messages.length
      msgs = origMessages.messages[i]
      next if !msgs || msgs.empty?
      
      typeName = MessageTypes.getTypeName(i)
      folder = MessageTypes.isCoreType?(i) ? "Translation_Core" : "Translation_Game"
      filename = "#{folder}/#{typeName}.txt"
      
      File.open(filename, "wb") { |f|
        f.write(0xef.chr)
        f.write(0xbb.chr)
        f.write(0xbf.chr)
        f.write("# #{typeName}\r\n")
        f.write("# To localize this text, translate every second line.\r\n")
        
        Messages.writeTypeToFile(f, msgs, i, origMessages)
      }
    end
  end
end

# Actualizar MessageTypes
module MessageTypes
  def self.extractByType
    @@messages.extractByType
  end
end

# Función para compilar desde directorios
def pbCompileFromFolders(folders, outfile = "intl.dat")
  intldat = []
  processedFiles = []
  
  # Cargar datos originales para obtener las IDs
  origMessages = nil
  if FileTest.exist?("Data/messages.dat")
    begin
      origMessages = Messages.new("Data/messages.dat")
    rescue
      # Si falla al cargar, continuamos sin él
      origMessages = nil
    end
  end
  
  for folder in folders
    next if !FileTest.directory?(folder)
    
    # Obtener todos los archivos .txt del directorio
    files = Dir.entries(folder).select { |f| f =~ /\.txt$/i }
    
    for filename in files
      filepath = "#{folder}/#{filename}"
      next if !FileTest.exist?(filepath)
      
      begin
        fileData = pbGetText(filepath)
        processedFiles.push(filepath)
        
        # Combinar datos
        if fileData[0] # Map messages
          intldat[0] = [] if !intldat[0]
          for i in 0...fileData[0].length
            if fileData[0][i]
              intldat[0][i] = fileData[0][i]
            end
          end
        end
        
        # Otros tipos de mensajes
        for i in 1...fileData.length
          if fileData[i]
            # Si es un tipo indexado y los datos vienen sin índices, reconstruirlos
            if MessageTypes.isIndexedType?(i) && fileData[i].is_a?(OrderedHash)
              if origMessages && origMessages.messages[i]
                # Crear un mapeo de texto original -> ID
                origArray = origMessages.messages[i]
                textToId = {}
                
                for j in 0...origArray.length
                  if !nil_or_empty?(origArray[j])
                    key = Messages.stringToKey(origArray[j])
                    textToId[key] = j
                  end
                end
                
                # Reconstruir array usando el mapeo
                rebuiltArray = []
                hashKeys = fileData[i].keys
                
                for key in hashKeys
                  if textToId[key]
                    rebuiltArray[textToId[key]] = fileData[i][key]
                  end
                end
                
                intldat[i] = rebuiltArray
              else
                # Sin datos originales, convertir OrderedHash a Array denso
                arr = []
                index = 0
                fileData[i].keys.each { |key|
                  arr[index] = fileData[i][key]
                  index += 1
                }
                intldat[i] = arr
              end
            else
              intldat[i] = fileData[i]
            end
          end
        end
      rescue
        raise _INTL("Error al procesar {1}: {2}", filepath, $!.message)
      end
    end
  end
  
  if processedFiles.length == 0
    raise _INTL("No se encontraron archivos de traducción en las carpetas especificadas")
  end
  
  # Guardar archivo combinado
  File.open(outfile, "wb") { |f|
    Marshal.dump(intldat, f)
  }
  
  return processedFiles.length
end

# Función UI para extraer por tipo
def pbExtractTextByType
  # Seleccionar idioma
  if !defined?(LANGUAGES) || !LANGUAGES
    Kernel.pbMessage(_INTL("No se encontró la configuración de LANGUAGES."))
    return
  end
  
  langNames = []
  for lang in LANGUAGES
    langNames.push(lang[0])
  end
  
  msgwindow = Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow, _INTL("Selecciona el idioma para extraer:"))
  Kernel.pbDisposeMessageWindow(msgwindow)
  
  langIndex = Kernel.pbShowCommands(nil, langNames, -1)
  return if langIndex < 0
  
  selectedLang = LANGUAGES[langIndex][0]
  langCode = selectedLang.downcase
  
  # Seleccionar qué extraer
  msgwindow = Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow, _INTL("¿Qué deseas extraer?"))
  Kernel.pbDisposeMessageWindow(msgwindow)
  
  options = [
    _INTL("Solo Core"),
    _INTL("Solo Game"),
    _INTL("Ambos"),
    _INTL("Cancelar")
  ]
  
  choice = Kernel.pbShowCommands(nil, options, -1)
  return if choice < 0 || choice == 3
  
  extractCore = (choice == 0 || choice == 2)
  extractGame = (choice == 1 || choice == 2)
  
  msgwindow = Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow, _INTL("Por favor, espera.\\wtnp[0]"))
  
  begin
    origMessages = Messages.new("Data/messages.dat")
    
    # Crear directorios según selección
    coreFolderName = "Text_#{langCode}_core"
    gameFolderName = "Text_#{langCode}_game"
    
    Dir.mkdir(coreFolderName) rescue nil if extractCore
    Dir.mkdir(gameFolderName) rescue nil if extractGame
    
    # Extraer mensajes de mapas (tipo 0) - va a Game
    if extractGame && origMessages.messages[0]
      typeName = MessageTypes.getTypeName(0)
      File.open("#{gameFolderName}/#{typeName}.txt", "wb") { |f|
        f.write(0xef.chr)
        f.write(0xbb.chr)
        f.write(0xbf.chr)
        f.write("# #{typeName}\r\n")
        f.write("# To localize this text, translate every second line.\r\n")
        
        for i in 0...origMessages.messages[0].length
          msgs = origMessages.messages[0][i]
          if msgs && !msgs.empty?
            Messages.writeTypeToFile(f, msgs, "Map#{i}", origMessages)
          end
        end
      }
    end
    
    # Extraer cada MessageType individualmente
    for i in 1...origMessages.messages.length
      msgs = origMessages.messages[i]
      next if !msgs || msgs.empty?
      
      isCore = MessageTypes.isCoreType?(i)
      next if isCore && !extractCore
      next if !isCore && !extractGame
      
      typeName = MessageTypes.getTypeName(i)
      folder = isCore ? coreFolderName : gameFolderName
      filename = "#{folder}/#{typeName}.txt"
      omitIndex = MessageTypes.isIndexedType?(i)
      
      File.open(filename, "wb") { |f|
        f.write(0xef.chr)
        f.write(0xbb.chr)
        f.write(0xbf.chr)
        f.write("# #{typeName}\r\n")
        f.write("# To localize this text, translate every second line.\r\n")
        
        Messages.writeTypeToFile(f, msgs, i, origMessages, omitIndex)
      }
    end
    
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Los textos se extrajeron exitosamente.\1"))
    if extractCore
      Kernel.pbMessageDisplay(msgwindow,
        _INTL("{1}: Datos de Pokémon (especies, movimientos, objetos, etc.).\1", coreFolderName))
    end
    if extractGame
      Kernel.pbMessageDisplay(msgwindow,
        _INTL("{1}: Datos del juego (entrenadores, diálogos, mapas, etc.).\1", gameFolderName))
    end
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Traduce las segundas líneas de cada par en los archivos.\1"))
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Luego elige \"Compilar Texto desde Carpetas.\""))
  rescue
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Error al extraer texto: {1}", $!.message))
  end
  
  Kernel.pbDisposeMessageWindow(msgwindow)
end

# Función UI para compilar desde carpetas
def pbCompileTextFromFoldersUI
  # Seleccionar idioma
  if !defined?(LANGUAGES) || !LANGUAGES
    Kernel.pbMessage(_INTL("No se encontró la configuración de LANGUAGES."))
    return
  end
  
  langNames = []
  for lang in LANGUAGES
    langNames.push(lang[0])
  end
  
  msgwindow = Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow, _INTL("Selecciona el idioma a compilar:"))
  Kernel.pbDisposeMessageWindow(msgwindow)
  
  langIndex = Kernel.pbShowCommands(nil, langNames, -1)
  return if langIndex < 0
  
  selectedLang = LANGUAGES[langIndex][0]
  langCode = selectedLang.downcase
  outputFile = LANGUAGES[langIndex][1]
  
  # Si es el idioma por defecto (sin archivo), usar intl.dat
  if outputFile == "" || outputFile == nil
    outputFile = "intl.dat"
  end
  
  msgwindow = Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow, _INTL("Por favor, espera.\\wtnp[0]"))
  
  begin
    coreFolderName = "Text_#{langCode}_core"
    gameFolderName = "Text_#{langCode}_game"
    
    folders = []
    folders.push(coreFolderName) if FileTest.directory?(coreFolderName)
    folders.push(gameFolderName) if FileTest.directory?(gameFolderName)
    
    if folders.length == 0
      Kernel.pbMessageDisplay(msgwindow,
        _INTL("No se encontraron las carpetas {1} o {2}.\1", coreFolderName, gameFolderName))
      Kernel.pbMessageDisplay(msgwindow,
        _INTL("Asegúrate de haber extraído los textos primero."))
      Kernel.pbDisposeMessageWindow(msgwindow)
      return
    end
    
    # Compilar a Data/archivo
    outputPath = "Data/#{outputFile}"
    fileCount = pbCompileFromFolders(folders, outputPath)
    
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Texto compilado exitosamente desde {1} archivo(s).", fileCount))
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("El archivo {1} se guardó en la carpeta Data.", outputFile))
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Idioma: {1}", selectedLang))
    if outputFile != "intl.dat"
      Kernel.pbMessageDisplay(msgwindow,
        _INTL("Este archivo ya está configurado en LANGUAGES y se cargará automáticamente."))
    end
  rescue RuntimeError
    Kernel.pbMessageDisplay(msgwindow,
      _INTL("Fallo al compilar el texto: {1}", $!.message))
  end
  
  Kernel.pbDisposeMessageWindow(msgwindow)
end