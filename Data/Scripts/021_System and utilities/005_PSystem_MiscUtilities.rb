################################################################################
# Aquí se encuentran las utilities que el usuario promedio no necesita comprobar.
################################################################################
################################################################################
# General purpose utilities
################################################################################
def _pbNextComb(comb,length)
    i=comb.length-1
    begin
      valid=true
      for j in i...comb.length
        if j==i
          comb[j]+=1
        else
          comb[j]=comb[i]+(j-i)
        end
        if comb[j]>=length
          valid=false
          break
        end
      end
      return true if valid
      i-=1
    end while i>=0
    return false
  end
  
  # Iterates through the array and yields each combination of _num_ elements in
  # the array.
  def pbEachCombination(array,num)
    return if array.length<num || num<=0
    if array.length==num
      yield array
      return
    elsif num==1
      for x in array
        yield [x]
      end
      return
    end
    currentComb=[]
    arr=[]
    for i in 0...num
      currentComb[i]=i
    end
    begin
      for i in 0...num
        arr[i]=array[currentComb[i]]
      end
      yield arr
    end while _pbNextComb(currentComb,array.length)
  end
  
  def pbGetCDID()
    sendString=proc{|x|
       mciSendString=Win32API.new('winmm','mciSendString','%w(p,p,l,l)','l')
       next "" if !mciSendString
       buffer="\0"*2000
       x=mciSendString.call(x,buffer,2000,0)
       if x==0
         next buffer.gsub(/\0/,"")
       else
         next ""
       end
    }
    sendString.call("open cdaudio shareable")
    ret=""
    if sendString.call("status cdaudio media present")=="true"
      ret=sendString.call("info cdaudio identity")
      if ret==""
        ret=sendString.call("info cdaudio info identity")
      end
    end
    sendString.call("close cdaudio")
    return ret
  end
  
  # Gets the path of the user's "My Documents" folder.
  def pbGetMyDocumentsFolder()
    csidl_personal=0x0005
    shGetSpecialFolderLocation=Win32API.new("shell32.dll","SHGetSpecialFolderLocation","llp","i")
    shGetPathFromIDList=Win32API.new("shell32.dll","SHGetPathFromIDList","lp","i")
    if !shGetSpecialFolderLocation || !shGetPathFromIDList
      return "."
    end
    idl=[0].pack("V")
    ret=shGetSpecialFolderLocation.call(0,csidl_personal,idl)
    return "." if ret!=0
    path="\0"*512
    ret=shGetPathFromIDList.call(idl.unpack("V")[0],path)
    return "." if ret==0
    return path.gsub(/\0/,"")
  end
  
  # Returns a country ID
  # http://msdn.microsoft.com/en-us/library/dd374073%28VS.85%29.aspx?
  def pbGetCountry()
    getUserGeoID=Win32API.new("kernel32","GetUserGeoID","l","i") rescue nil
    if getUserGeoID
      return getUserGeoID.call(16)
    end
    return 0
  end
  
  # Returns a language ID
  def pbGetLanguage()
    getUserDefaultLangID=Win32API.new("kernel32","GetUserDefaultLangID","","i") rescue nil
    ret=0
    if getUserDefaultLangID
      ret=getUserDefaultLangID.call()&0x3FF
    end
    if ret==0 # Unknown
      ret=MiniRegistry.get(MiniRegistry::HKEY_CURRENT_USER,
         "Control Panel\\Desktop\\ResourceLocale","",0)
      ret=MiniRegistry.get(MiniRegistry::HKEY_CURRENT_USER,
         "Control Panel\\International","Locale","0").to_i(16) if ret==0
      ret=ret&0x3FF
      return 0 if ret==0  # Unknown
    end
    return 1 if ret==0x11 # Japanese
    return 2 if ret==0x09 # English
    return 3 if ret==0x0C # French
    return 4 if ret==0x10 # Italian
    return 5 if ret==0x07 # German
    return 7 if ret==0x0A # Spanish
    return 8 if ret==0x12 # Korean
    return 2 # Use 'English' by default
  end
  
  # Converts a Celsius temperature to Fahrenheit.
  def toFahrenheit(celsius)
    return (celsius*9.0/5.0).round+32
  end
  
  # Converts a Fahrenheit temperature to Celsius.
  def toCelsius(fahrenheit)
    return ((fahrenheit-32)*5.0/9.0).round
  end
  
  
  
  ################################################################################
  # Linear congruential random number generator
  ################################################################################
  class LinearCongRandom
    def initialize(mul, add, seed=nil)
      @s1=mul
      @s2=add
      @seed=seed
      @seed=(Time.now.to_i&0xffffffff) if !@seed
      @seed=(@seed+0xFFFFFFFF)+1 if @seed<0
    end
  
    def self.dsSeed
      t=Time.now
      seed = (((t.mon * t.mday + t.min + t.sec)&0xFF) << 24) | (t.hour << 16) | (t.year - 2000)
      seed=(seed+0xFFFFFFFF)+1 if seed<0
      return seed
    end
  
    def self.pokemonRNG
      self.new(0x41c64e6d,0x6073,self.dsSeed)
    end
  
    def self.pokemonRNGInverse
      self.new(0xeeb9eb65,0xa3561a1,self.dsSeed)
    end
  
    def self.pokemonARNG
      self.new(0x6C078965,0x01,self.dsSeed)
    end
  
    def getNext16 # calculates @seed * @s1 + @s2
      @seed=((((@seed & 0x0000ffff) * (@s1 & 0x0000ffff)) & 0x0000ffff) |
         (((((((@seed & 0x0000ffff) * (@s1 & 0x0000ffff)) & 0xffff0000) >> 16) +
         ((((@seed & 0xffff0000) >> 16) * (@s1 & 0x0000ffff)) & 0x0000ffff) +
         (((@seed & 0x0000ffff) * ((@s1 & 0xffff0000) >> 16)) & 0x0000ffff)) &
         0x0000ffff) << 16)) + @s2
      r=(@seed>>16)
      r=(r+0xFFFFFFFF)+1 if r<0
      return r
    end
  
    def getNext
      r=(getNext16()<<16)|(getNext16())
      r=(r+0xFFFFFFFF)+1 if r<0
      return r
    end
  end
  
  
  
  ################################################################################
  # JavaScript-related utilities
  ################################################################################
  # Returns true if the given string represents a valid object in JavaScript
  # Object Notation, and false otherwise.
  def  pbIsJsonString(str)
    return false if (!str || str[ /^[\s]*$/ ])
    d=/(?:^|:|,)(?: ?\[)+/
    charEscapes=/\\[\"\\\/nrtubf]/ #"
    stringLiterals=/"[^"\\\n\r\x00-\x1f\x7f-\x9f]*"/ #"
    whiteSpace=/[\s]+/
    str=str.gsub(charEscapes,"@").gsub(stringLiterals,"true").gsub(whiteSpace," ")
    # prevent cases like "truetrue" or "true true" or "true[true]" or "5-2" or "5true"
    otherLiterals=/(true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)(?! ?[0-9a-z\-\[\{\"])/ #"
    str=str.gsub(otherLiterals,"]").gsub(d,"") #"
    #p str
    return str[ /^[\],:{} ]*$/ ] ? true : false
  end
  
  # Returns a Ruby object that corresponds to the given string, which is encoded in
  # JavaScript Object Notation (JSON). Returns nil if the string is not valid JSON.
  def pbParseJson(str)
    if !pbIsJsonString(str)
      return nil
    end
    stringRE=/(\"(\\[\"\'\\rntbf]|\\u[0-9A-Fa-f]{4,4}|[^\\\"])*\")/ #"
    strings=[]
    str=str.gsub(stringRE){
       sl=strings.length
       ss=$1
       if ss.include?("\\u")
         ss.gsub!(/\\u([0-9A-Fa-f]{4,4})/){
            codepoint=$1.to_i(16)
            if codepoint<=0x7F
              next sprintf("\\x%02X",codepoint)
            elsif codepoint<=0x7FF
              next sprintf("%s%s",
                 (0xC0|((codepoint>>6)&0x1F)).chr,
                 (0x80|(codepoint   &0x3F)).chr)
            else
              next sprintf("%s%s%s",
                 (0xE0|((codepoint>>12)&0x0F)).chr,
                 (0x80|((codepoint>>6)&0x3F)).chr,
                 (0x80|(codepoint   &0x3F)).chr)
            end
         }
       end
       strings.push(eval(ss))
       next sprintf("strings[%d]",sl)
    }
    str=str.gsub(/\:/,"=>")
    str=str.gsub(/null/,"nil")
    return eval("("+str+")")
  end
  
  
  
  ################################################################################
  # XML-related utilities
  ################################################################################
  # Represents XML content.
  class MiniXmlContent
    attr_reader :value
  
    def initialize(value)
      @value=value
    end
  end
  
  
  
  # Represents an XML element.
  class MiniXmlElement
    attr_accessor :name,:attributes,:children
  
    def initialize(name)
      @name=name
      @attributes={}
      @children=[]
    end
  
  #  Gets the value of the attribute with the given name, or nil if it doesn't
  #  exist.
    def a(name)
      self.attributes[name]
    end
  
  #  Gets the entire text of this element.
    def value
      ret=""
      for c in @children
        ret+=c.value
      end
      return ret
    end
  
  #  Gets the first child of this element with the given name, or nil if it
  # doesn't exist.
    def e(name)
      for c in @children
        return c if c.is_a?(MiniXmlElement) && c.name==name
      end
      return nil
    end
  
    def eachElementNamed(name)
      for c in @children
        yield c if c.is_a?(MiniXmlElement) && c.name==name
      end
    end
  end
  
  
  
  # A small class for reading simple XML documents. Such documents must
  # meet the following restrictions:
  #  They may contain comments and processing instructions, but they are
  #    ignored.
  #  They can't contain any entity references other than 'gt', 'lt',
  #    'amp', 'apos', or 'quot'.
  #  They can't contain a DOCTYPE declaration or DTDs.
  class MiniXmlReader
    def initialize(data)
      @root=nil
      @elements=[]
      @done=false
      @data=data
      @content=""
    end
  
    def createUtf8(codepoint) #:nodoc:
      raise ArgumentError.new("Illegal character") if codepoint<9 ||
         codepoint==11||codepoint==12||(codepoint>=14 && codepoint<32) ||
         codepoint==0xFFFE||codepoint==0xFFFF||(codepoint>=0xD800 && codepoint<0xE000)
      if codepoint<=0x7F
        return codepoint.chr
      elsif codepoint<=0x7FF
        str=(0xC0|((codepoint>>6)&0x1F)).chr
        str+=(0x80|(codepoint   &0x3F)).chr
        return str
      elsif codepoint<=0xFFFF
        str=(0xE0|((codepoint>>12)&0x0F)).chr
        str+=(0x80|((codepoint>>6)&0x3F)).chr
        str+=(0x80|(codepoint   &0x3F)).chr
        return str
      elsif codepoint<=0x10FFFF
        str=(0xF0|((codepoint>>18)&0x07)).chr
        str+=(0x80|((codepoint>>12)&0x3F)).chr
        str+=(0x80|((codepoint>>6)&0x3F)).chr
        str+=(0x80|(codepoint   &0x3F)).chr
        return str
      else
        raise ArgumentError.new("Illegal character")
      end
      return str
    end
  
    def unescape(attr) #:nodoc:
      attr=attr.gsub(/\r(\n|$|(?=[^\n]))/,"\n")
      raise ArgumentError.new("Attribute value contains '<'") if attr.include?("<")
      attr=attr.gsub(/&(lt|gt|apos|quot|amp|\#([0-9]+)|\#x([0-9a-fA-F]+));|([\n\r\t])/){
         next " " if $4=="\n"||$4=="\r"||$4=="\t"
         next "<" if $1=="lt"
         next ">" if $1=="gt"
         next "'" if $1=="apos"
         next "\"" if $1=="quot"
         next "&" if $1=="amp"
         next createUtf8($2.to_i) if $2
         next createUtf8($3.to_i(16)) if $3
      }
      return attr
    end
  
    def readAttributes(attribs) #:nodoc:
      ret={}
      while attribs.length>0
        if attribs[/(\s+([\w\-]+)\s*\=\s*\"([^\"]*)\")/]
          attribs=attribs[$1.length,attribs.length]
          name=$2; value=$3
          if ret[name]!=nil
            raise ArgumentError.new("Attribute already exists")
          end
          ret[name]=unescape(value)
        elsif attribs[/(\s+([\w\-]+)\s*\=\s*\'([^\']*)\')/]
          attribs=attribs[$1.length,attribs.length]
          name=$2; value=$3
          if ret[name]!=nil
            raise ArgumentError.new("Attribute already exists")
          end
          ret[name]=unescape(value)
        else
          raise ArgumentError.new("Can't parse attributes")
        end
      end
      return ret
    end
  
  # Reads the entire contents of an XML document. Returns the root element of
  # the document or raises an ArgumentError if an error occurs.
    def read
      if @data[/\A((\xef\xbb\xbf)?<\?xml\s+version\s*=\s*(\"1\.[0-9]\"|\'1\.[0-9]\')(\s+encoding\s*=\s*(\"[^\"]*\"|\'[^\']*\'))?(\s+standalone\s*=\s*(\"(yes|no)\"|\'(yes|no)\'))?\s*\?>)/]
        # Ignore XML declaration
        @data=@data[$1.length,@data.length]
      end
      while readOneElement(); end
      return @root
    end
  
    def readOneElement #:nodoc:
      if @data[/\A\s*\z/]
        @data=""
        if !@root
          raise ArgumentError.new("Not an XML document.")
        elsif !@done
          raise ArgumentError.new("Unexpected end of document.")
        end
        return false
      end
      if @data[/\A(\s*<([\w\-]+)((?:\s+[\w\-]+\s*\=\s*(?:\"[^\"]*\"|\'[^\']*\'))*)\s*(\/>|>))/]
        @data=@data[$1.length,@data.length]
        elementName=$2
        attributes=$3
        endtag=$4
        if @done
          raise ArgumentError.new("Element tag at end of document")
        end
        if @content.length>0 && @elements.length>0
          @elements[@elements.length-1].children.push(MiniXmlContent.new(@content))
          @content=""
        end
        element=MiniXmlElement.new(elementName)
        element.attributes=readAttributes(attributes)
        if !@root
          @root=element
        else
          @elements[@elements.length-1].children.push(element)
        end
        if endtag==">"
          @elements.push(element)
        else
          if @elements.length==0
            @done=true
          end
        end
      elsif @data[/\A(<!--([\s\S]*?)-->)/]
        # ignore comments
        if $2.include?("--")
          raise ArgumentError.new("Incorrect comment")
        end
        @data=@data[$1.length,@data.length]
      elsif @data[/\A(<\?([\w\-]+)\s+[\s\S]*?\?>)/]
        # ignore processing instructions
        @data=@data[$1.length,@data.length]
        if $2.downcase=="xml"
          raise ArgumentError.new("'xml' processing instruction not allowed")
        end
      elsif @data[/\A(<\?([\w\-]+)\?>)/]
        # ignore processing instructions
        @data=@data[$1.length,@data.length]
        if $2.downcase=="xml"
          raise ArgumentError.new("'xml' processing instruction not allowed")
        end
      elsif @data[/\A(\s*<\/([\w\-]+)>)/]
        @data=@data[$1.length,@data.length]
        elementName=$2
        if @done
          raise ArgumentError.new("End tag at end of document")
        end
        if @elements.length==0
          raise ArgumentError.new("Unexpected end tag")
        elsif @elements[@elements.length-1].name!=elementName
          raise ArgumentError.new("Incorrect end tag")
        else
          if @content.length>0
            @elements[@elements.length-1].children.push(MiniXmlContent.new(@content))
            @content=""
          end
          @elements.pop()
          if @elements.length==0
            @done=true
          end
        end
      else
        if @elements.length>0
          # Parse content
          if @data[/\A([^<&]+)/]
            content=$1
            @data=@data[content.length,@data.length]
            if content.include?("]]>")
              raise ArgumentError.new("Incorrect content")
            end
            content.gsub!(/\r(\n|\z|(?=[^\n]))/,"\n")
            @content+=content
          elsif @data[/\A(<\!\[CDATA\[([\s\S]*?)\]\]>)/]
            content=$2
            @data=@data[$1.length,@data.length]
            content.gsub!(/\r(\n|\z|(?=[^\n]))/,"\n")
            @content+=content
          elsif @data[/\A(&(lt|gt|apos|quot|amp|\#([0-9]+)|\#x([0-9a-fA-F]+));)/]
            @data=@data[$1.length,@data.length]
            content=""
            if $2=="lt"; content="<"
            elsif $2=="gt"; content=">"
            elsif $2=="apos"; content="'"
            elsif  $2=="quot"; content="\""
            elsif $2=="amp"; content="&"
            elsif $3; content=createUtf8($2.to_i)
            elsif $4; content=createUtf8($3.to_i(16))
            end
            @content+=content
          elsif !@data[/\A</]
            raise ArgumentError.new("Can't read XML content")
          end
        else
          raise ArgumentError.new("Can't parse XML")
        end
      end
      return true
    end
  end
  
################################################################################
# Player-related utilities II, random name generator
################################################################################
def pbGetUserName()
    buffersize=100
    getUserName=Win32API.new('advapi32.dll','GetUserName','pp','i')
    10.times do
      size=[buffersize].pack("V")
      buffer="\0"*buffersize
      if getUserName.call(buffer,size)!=0
        return buffer.gsub(/\0/,"")
      end
      buffersize+=200
    end
    return ""
  end
  
  def getRandomNameEx(type,variable,upper,maxLength=100)
    return "" if maxLength<=0
    name=""
    50.times {
      name=""
      formats=[]
      case type
      when 0 # Names for males
        formats=%w( F5 BvE FE FE5 FEvE )
      when 1 # Names for females
        formats=%w( vE6 vEvE6 BvE6 B4 v3 vEv3 Bv3 )
      when 2 # Neutral gender names
        formats=%w( WE WEU WEvE BvE BvEU BvEvE )
      else
        return ""
      end
      format=formats[rand(formats.length)]
      format.scan(/./) {|c|
         case c
         when "c" # consonant
           set=%w( b c d f g h j k l m n p r s t v w x z )
           name+=set[rand(set.length)]
         when "v" # vowel
           set=%w( a a a e e e i i i o o o u u u )
           name+=set[rand(set.length)]
         when "W" # beginning vowel
           set=%w( a a a e e e i i i o o o u u u au au ay ay
              ea ea ee ee oo oo ou ou )
           name+=set[rand(set.length)]
         when "U" # ending vowel
           set=%w( a a a a a e e e i i i o o o o o u u ay ay ie ie ee ue oo )
           name+=set[rand(set.length)]
         when "B" # beginning consonant
           set1=%w( b c d f g h j k l l m n n p r r s s t t v w y z )
           set2=%w(
              bl br ch cl cr dr fr fl gl gr kh kl kr ph pl pr sc sk sl
              sm sn sp st sw th tr tw vl zh )
           name+=rand(3)>0 ? set1[rand(set1.length)] : set2[rand(set2.length)]
         when "E" # ending consonant
           set1=%w( b c d f g h j k k l l m n n p r r s s t t v z )
           set2=%w( bb bs ch cs ds fs ft gs gg ld ls
              nd ng nk rn kt ks
              ms ns ph pt ps sk sh sp ss st rd
              rn rp rm rt rk ns th zh)
           name+=rand(3)>0 ? set1[rand(set1.length)] : set2[rand(set2.length)]
         when "f" # consonant and vowel
           set=%w( iz us or )
           name+=set[rand(set.length)]
         when "F" # consonant and vowel
           set=%w( bo ba be bu re ro si mi zho se nya gru gruu glee gra glo ra do zo ri
              di ze go ga pree pro po pa ka ki ku de da ma mo le la li )
           name+=set[rand(set.length)]
         when "2"
           set=%w( c f g k l p r s t )
           name+=set[rand(set.length)]
         when "3"
           set=%w( nka nda la li ndra sta cha chie )
           name+=set[rand(set.length)]
         when "4"
           set=%w( una ona ina ita ila ala ana ia iana )
           name+=set[rand(set.length)]
         when "5"
           set=%w( e e o o ius io u u ito io ius us )
           name+=set[rand(set.length)]
         when "6"
           set=%w( a a a elle ine ika ina ita ila ala ana )
           name+=set[rand(set.length)]
         end
      }
      break if name.length<=maxLength
    }
    name=name[0,maxLength]
    case upper
    when 0
      name=name.upcase
    when 1
      name[0,1]=name[0,1].upcase
    end
    if $game_variables && variable
      $game_variables[variable]=name
      $game_map.need_refresh = true if $game_map
    end
    return name
  end
  
  def getRandomName(maxLength=100)
    return getRandomNameEx(2,nil,nil,maxLength)
  end

################################################################################
# Event timing utilities
################################################################################
def pbTimeEvent(variableNumber,secs=86400)
  if variableNumber && variableNumber>=0
    if $game_variables
      secs=0 if secs<0
      timenow=pbGetTimeNow
      $game_variables[variableNumber]=[timenow.to_f,secs]
      $game_map.refresh if $game_map
    end
  end
end

def pbTimeEventDays(variableNumber,days=0)
  if variableNumber && variableNumber>=0
    if $game_variables
      days=0 if days<0
      timenow=pbGetTimeNow
      time=timenow.to_f
      expiry=(time%86400.0)+(days*86400.0)
      $game_variables[variableNumber]=[time,expiry-time]
      $game_map.refresh if $game_map
    end
  end
end

def pbTimeEventValid(variableNumber)
  retval=false
  if variableNumber && variableNumber>=0 && $game_variables
    value=$game_variables[variableNumber]
    if value.is_a?(Array)
      timenow=pbGetTimeNow
      retval=(timenow.to_f - value[0] > value[1]) # value[1] is age in seconds
      retval=false if value[1]<=0 # zero age
    end
    if !retval
      $game_variables[variableNumber]=0
      $game_map.refresh if $game_map
    end
  end
  return retval
end


################################################################################
# Constants utilities
################################################################################
def isConst?(val,mod,constant)
  begin
    isdef=mod.const_defined?(constant.to_sym)
    return false if !isdef
  rescue
    return false
  end
  return (val==mod.const_get(constant.to_sym))
end

def hasConst?(mod,constant)
  return false if !mod || !constant || constant==""
  return mod.const_defined?(constant.to_sym) rescue false
end

def getConst(mod,constant)
  return nil if !mod || !constant || constant==""
  return mod.const_get(constant.to_sym) rescue nil
end

def getID(mod,constant)
  return nil if !mod || !constant || constant==""
  if constant.is_a?(Symbol) || constant.is_a?(String)
    if (mod.const_defined?(constant.to_sym) rescue false)
      return mod.const_get(constant.to_sym) rescue 0
    else
      return 0
    end
  else
    return constant
  end
end

################################################################################
# General-purpose utilities with dependencies II
################################################################################
def pbFadeOutInWithMusic(zViewport)
  playingBGS=$game_system.getPlayingBGS
  playingBGM=$game_system.getPlayingBGM
  $game_system.bgm_pause(1.0)
  $game_system.bgs_pause(1.0)
  pos=$game_system.bgm_position
  pbFadeOutIn(zViewport) {
     yield
     $game_system.bgm_position=pos
     $game_system.bgm_resume(playingBGM)
     $game_system.bgs_resume(playingBGS)
  }
end

# Gets the wave data from a file and displays an message if an error occurs.
# Can optionally delete the wave file (this is useful if the file was a
# temporary file created by a recording).
# Requires the script AudioUtilities
# Requires the script "PokemonMessages"
def getWaveDataUI(filename,deleteFile=false)
  error=getWaveData(filename)
  if deleteFile
    begin
      File.delete(filename)
    rescue Errno::EINVAL, Errno::EACCES, Errno::ENOENT
    end
  end
  case error
  when 1
    Kernel.pbMessage(_INTL("Los datos grabados no se pudieron encontrar o guardar."))
  when 2
    Kernel.pbMessage(_INTL("Los datos grabados tenían un formato inválido."))
  when 3
    Kernel.pbMessage(_INTL("El formado de los datos grabados no está soportado."))
  when 4
    Kernel.pbMessage(_INTL("No había ningún sonido en la grabación. Asegúrese de que el micrófono está conectado a la PC y listo."))
  else
    return error
  end
  return nil
end

# Starts recording, and displays a message if the recording failed to start.
# Returns true if successful, false otherwise
# Requires the script AudioUtilities
# Requires the script "PokemonMessages"
def beginRecordUI
  code=beginRecord
  case code
  when 0; return true
  when 256+66
    Kernel.pbMessage(_INTL("Todos los dispositivos de grabación están ocupados. No se puede grabar en este momento."))
    return false
  when 256+72
    Kernel.pbMessage(_INTL("Se encontró dispositivo de grabación no soportado. No es posible la grabación."))
    return false
  else
    buffer="\0"*256
    MciErrorString.call(code,buffer,256)
    Kernel.pbMessage(_INTL("Fallo en la grabación: {1}",buffer.gsub(/\x00/,"")))
    return false
  end
end

def pbHideVisibleObjects
  visibleObjects=[]
  ObjectSpace.each_object(Sprite){|o|
     if !o.disposed? && o.visible && (!$ResizeBorder || $ResizeBorder.sprite.bitmap!=o.bitmap)
       visibleObjects.push(o)
       o.visible=false
     end
  }
  ObjectSpace.each_object(Viewport){|o|
     if !pbDisposed?(o) && o.visible
       visibleObjects.push(o)
       o.visible=false
     end
  }
  ObjectSpace.each_object(Plane){|o|
     if !o.disposed? && o.visible
       visibleObjects.push(o)
       o.visible=false
     end
  }
  ObjectSpace.each_object(Tilemap){|o|
     if !o.disposed? && o.visible
       visibleObjects.push(o)
       o.visible=false
     end
  }
  ObjectSpace.each_object(Window){|o|
     if !o.disposed? && o.visible
       visibleObjects.push(o)
       o.visible=false
     end
  }
  return visibleObjects
end

def pbShowObjects(visibleObjects)
  for o in visibleObjects
    if !pbDisposed?(o)
      o.visible=true
    end
  end
end

def pbLoadRpgxpScene(scene)
  return if !$scene.is_a?(Scene_Map)
  oldscene=$scene
  $scene=scene
  Graphics.freeze
  oldscene.disposeSpritesets
  visibleObjects=pbHideVisibleObjects
  Graphics.transition(15)
  Graphics.freeze
  while $scene && !$scene.is_a?(Scene_Map)
    $scene.main
  end
  Graphics.transition(15)
  Graphics.freeze
  oldscene.createSpritesets
  pbShowObjects(visibleObjects)
  Graphics.transition(20)
  $scene=oldscene
end

# Gets the value of a variable.
def pbGet(id)
  return 0 if !id || !$game_variables
  return $game_variables[id]
end

# Sets the value of a variable.
def pbSet(id,value)
  if id && id>=0
    $game_variables[id]=value if $game_variables
    $game_map.need_refresh = true if $game_map
  end
end

# Runs a common event and waits until the common event is finished.
# Requires the script "PokemonMessages"
def pbCommonEvent(id)
  return false if id<0
  ce=$data_common_events[id]
  return false if !ce
  celist=ce.list
  interp=Interpreter.new
  interp.setup(celist,0)
  begin
    Graphics.update
    Input.update
    interp.update
    pbUpdateSceneMap
  end while interp.running?
  return true
end

#===============================================================================
#  Extensions for Array objects
#===============================================================================
class ::Array
  #-----------------------------------------------------------------------------
  #  swaps two values in arrays
  #-----------------------------------------------------------------------------
  def swap(val1, val2)
    index1 = self.index(val1)
    index2 = self.index(val2)
    self[index1] = val2
    self[index2] = val1
  end
  #-----------------------------------------------------------------------------
  #  swaps specific indexes
  #-----------------------------------------------------------------------------
  def swap_at(index1, index2)
    val1 = self[index1].clone
    val2 = self[index2].clone
    self[index1] = val2
    self[index2] = val1
  end
  #-----------------------------------------------------------------------------
  #  gets first value
  #-----------------------------------------------------------------------------
  def first(index = nil)
    return (index == 0) if !index.nil?
    return self[0]
  end
  #-----------------------------------------------------------------------------
  #  gets last value
  #-----------------------------------------------------------------------------
  def last(index = nil)
    return (index == self.length - 1) if !index.nil?
    return self[self.length - 1]
  end
  #-----------------------------------------------------------------------------
  #  gets random value
  #-----------------------------------------------------------------------------
  def sample
    return self[rand(self.length)]
  end
  #-----------------------------------------------------------------------------
  #  pushes value to last index
  #-----------------------------------------------------------------------------
  def to_last(val)
    self.delete(val) if self.include?(val)
    self.push(val)
  end
  #-----------------------------------------------------------------------------
  #  check if part of string matches
  #-----------------------------------------------------------------------------
  def string_include?(val)
    return false if !val.is_a?(String)
    ret = false
    for a in self
      ret = true if a.is_a?(String) && val.include?(a)
    end
    return ret
  end
  #-----------------------------------------------------------------------------
end

