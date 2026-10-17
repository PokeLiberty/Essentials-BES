# Convierte una lista de bytes en String.
def pbBytesToStr(bytes)
  s=bytes.pack("C*")
  s.force_encoding("UTF-8") if s.respond_to?(:force_encoding)
  return s
end

# Codepoint Unicode -> carácter UTF-8.
def pbUTF8FromCodepoint(cp)
  if cp<0x80
    bytes=[cp]
  elsif cp<0x800
    bytes=[0xC0|(cp>>6), 0x80|(cp&0x3F)]
  elsif cp<0x10000
    bytes=[0xE0|(cp>>12), 0x80|((cp>>6)&0x3F), 0x80|(cp&0x3F)]
  else
    bytes=[0xF0|((cp>>18)&0x07), 0x80|((cp>>12)&0x3F),
           0x80|((cp>>6)&0x3F), 0x80|(cp&0x3F)]
  end
  return pbBytesToStr(bytes)
end

# Divide una cadena UTF-8 en caracteres (no en bytes).
# En Ruby 1.8, String#scan(/./) trabaja con bytes y rompe la Ñ y demás.
def pbUTF8Chars(str)
  bytes=str.unpack("C*")
  result=[]
  i=0
  while i<bytes.length
    b=bytes[i]
    if b<0x80
      len=1
    elsif b>=0xF0
      len=4
    elsif b>=0xE0
      len=3
    elsif b>=0xC0
      len=2
    else
      len=1
    end
    len=bytes.length-i if i+len>bytes.length
    result.push(pbBytesToStr(bytes[i,len]))
    i+=len
  end
  return result
end

#===============================================================================
# Teclado Win32 (estado de teclas y traducción a texto).
#===============================================================================
module KeyboardText
  VK_BACK    = 0x08
  VK_TAB     = 0x09
  VK_RETURN  = 0x0D
  VK_SHIFT   = 0x10
  VK_CONTROL = 0x11
  VK_MENU    = 0x12   # Alt (AltGr = Ctrl + Alt)
  VK_ESCAPE  = 0x1B
  VK_END     = 0x23
  VK_HOME    = 0x24
  VK_LEFT    = 0x25
  VK_RIGHT   = 0x27
  VK_DELETE  = 0x2E

  # true = imprime en la consola las teclas detectadas (diagnóstico)
  DEBUG = false
  
  # true = ignora las teclas si la ventana activa no es la del juego
  FOCUS_CHECK = false
  # Escribe una línea en kb_debug.txt (carpeta del juego). No bloquea el juego.
  def self.log(msg)
    begin
      File.open("kb_debug.txt","a") { |f| f.puts(msg) }
    rescue Exception
    end
  end
  # Caracteres de acento que devuelve el teclado al pulsar una tecla muerta
  DEAD_CHARS=[0xB4,0x60,0xA8,0x5E,0x7E]
  # Repetición de tecla mantenida (en frames)
  REPEAT_DELAY = 24
  REPEAT_RATE  = 3

  # Acento muerto (codepoint) => [letras base ASCII, letras acentuadas]
  ACCENTS = {
    0xB4 => ["AEIOUaeiou", "ÁÉÍÓÚáéíóú"],   # ´ agudo
    0x60 => ["AEIOUaeiou", "ÀÈÌÒÙàèìòù"],   # ` grave
    0xA8 => ["AEIOUaeiou", "ÄËÏÖÜäëïöü"],   # ¨ diéresis
    0x5E => ["AEIOUaeiou", "ÂÊÎÔÛâêîôû"],   # ^ circunflejo
    0x7E => ["AONaon",     "ÃÕÑãõñ"]        # ~ tilde
  }

  # Devuelve el carácter acentuado o nil si la combinación no existe.
  def self.compose(accent,base)
    entry=ACCENTS[accent]
    return nil if !entry || base>=0x80
    idx=entry[0].index(base.chr)
    return nil if !idx
    return pbUTF8Chars(entry[1])[idx]
  end

  # ¿El carácter cp es ya la versión acentuada de ese acento? (p. ej. ú para ´)
  def self.accented?(accent,cp)
    entry=ACCENTS[accent]
    return false if !entry
    return pbUTF8Chars(entry[1]).include?(pbUTF8FromCodepoint(cp))
  end

  # Inicialización perezosa. Devuelve true si Win32API está disponible.
  def self.setup
    if @available.nil?
      begin
        @getAsyncKeyState=Win32API.new("user32","GetAsyncKeyState","i","i")
        @getForegroundWindow=Win32API.new("user32","GetForegroundWindow","","i")
        @toUnicode=Win32API.new("user32","ToUnicode","iippii","i")
        @mapVirtualKey=Win32API.new("user32","MapVirtualKey","ii","i")
        @available=true
        begin
          @getKeyState=Win32API.new("user32","GetKeyState","i","i")
        rescue Exception
          @getKeyState=nil
        end
      rescue Exception => e
        @available=false
        @errorMsg=e.message
        puts "KeyboardText: Win32API NO disponible (#{e.message}). Solo funcionan Intro/Esc."
      end
      @held=Array.new(256,0)
      @state=Array.new(256,0)
      @kbs="\0"*256
      @dead=nil
    end
    return @available
  end

  def self.available?
    return setup
  end

  # Diagnóstico: devuelve un texto con el estado del teclado.
  def self.diagnose
    return "Win32API no disponible: #{@errorMsg}" if !setup
    lines=[]
    lines.push("ventana activa=#{@getForegroundWindow.call}  ventana juego=#{gameWindow}")
    lines.push("comprobación de foco: #{FOCUS_CHECK ? 'activa' : 'desactivada'}")
    buf="\0"*16
    ret=@toUnicode.call(0x41,@mapVirtualKey.call(0x41,0),"\0"*256,buf,8,4)
    lines.push("prueba ToUnicode(A): ret=#{ret} texto=#{buf.unpack('v*')[0].inspect} (esperado 1 y 97)")
    st=readKeys
    down=[]
    for vk in 0...256
      down.push(vk) if (st[vk]&0x80)!=0
    end
    lines.push("teclas pulsadas ahora (VK): #{down.inspect}")
    return lines.join("\n")
  end

  # Llamar al abrir una pantalla de texto. Las teclas que ya estaban pulsadas
  # (p. ej. el botón que abrió el cuadro) no cuentan como pulsaciones nuevas.
  def self.reset
    setup
    @dead=nil
    if @available
      st=readKeys
      for vk in 0...256
        @held[vk]=((st[vk]&0x80)!=0) ? 1 : 0
      end
    end
  end

  # ¿Está pulsada esta tecla en este frame?
  def self.down?(vk)
    setup
    return false if !@state
    return (@state[vk]&0x80)!=0
  end

  # Manejador de la ventana del juego. Si no se puede obtener, devuelve 0.
  def self.gameWindow
    if @gameWnd.nil?
      begin
        @gameWnd=Win32API.pbFindRgssWindow
      rescue Exception
        @gameWnd=0
      end
    end
    return @gameWnd
  end

  # ¿Tiene el foco la ventana del juego? Si no podemos comprobarlo, se asume que sí.
  def self.gameFocused?
    # Desactivado por defecto: la ventana 'juego' que se detecta no siempre es la
    # visible, y dejaba el teclado inutilizable. Poner true para volver a usarlo.
    return true if !FOCUS_CHECK
    fg=@getForegroundWindow.call
    return false if fg==0
    gw=gameWindow
    return true if gw==0
    return fg==gw
  end

  # Estado de las 256 teclas, en el formato de GetKeyboardState, usando
  # GetAsyncKeyState (global: funciona desde cualquier hilo). Sin foco = nada.
  def self.readKeys
    bytes=Array.new(256,0)
    @focused=gameFocused?
    if @focused
      for vk in 0...256
        bytes[vk]=((@getAsyncKeyState.call(vk)&0x8000)!=0) ? 0x80 : 0
      end
      # Shift/Ctrl/Alt genéricos = cualquiera de sus dos lados
      bytes[0x10]=bytes[0x10]|bytes[0xA0]|bytes[0xA1]
      bytes[0x11]=bytes[0x11]|bytes[0xA2]|bytes[0xA3]
      bytes[0x12]=bytes[0x12]|bytes[0xA4]|bytes[0xA5]
      # Teclas de bloqueo (Mayús, Num, Scroll): bit 0x01 = activado
      if @getKeyState
        for vk in [0x14,0x90,0x91]
          bytes[vk]=bytes[vk]|1 if (@getKeyState.call(vk)&1)!=0
        end
      end
    end
    @state=bytes
    @kbs=bytes.pack("C*")
    return @state
  end

  # Llamar UNA vez por frame. Devuelve una lista [[vk, texto_o_nil], ...] con
  # las pulsaciones nuevas (incluidas repeticiones de teclas mantenidas).
  # El texto es nil si la tecla no escribe nada (flechas, Backspace, Enter...).
  def self.poll
    return fallbackPoll if !setup
    st=readKeys
    pressed=[]
    for vk in 0...256
      if (st[vk]&0x80)!=0
        if @held[vk]==0
          @held[vk]=1
          pressed.push(vk)
        else
          @held[vk]+=1
          if @held[vk]>=REPEAT_DELAY && (@held[vk]-REPEAT_DELAY)%REPEAT_RATE==0 && vk!=@deadVk
            pressed.push(vk)
          end
        end
      else
        @held[vk]=0
        @deadVk=nil if vk==@deadVk
      end
    end
    # Teclas OEM (acentos, ñ, signos) antes que letras: si llegan en el mismo
    # frame, el acento debe procesarse antes que la letra que lo completa.
    oem=[]
    rest=[]
    for vk in pressed
      if (vk>=0xBA && vk<=0xC0) || (vk>=0xDB && vk<=0xDF)
        oem.push(vk)
      else
        rest.push(vk)
      end
    end
    pressed=oem+rest
    result=[]
    for vk in pressed
      result.push([vk,translate(vk)])
    end
    if DEBUG && (!pressed.empty? || @focused!=@lastFocused)
      log("[KB] foco=#{@focused} pulsadas=#{pressed.inspect} eventos=#{result.inspect}")
    end
    @lastFocused=@focused
    return result
  end

  # Traduce una tecla a texto según el teclado del sistema.
  def self.translate(vk)
    st=@state
    # Ctrl+tecla (atajos como Ctrl+C) no escribe texto.
    # AltGr envía Ctrl+Alt a la vez, y ese sí debe escribir (@, €, etc.).
    return nil if ((st[VK_CONTROL]&0x80)!=0) && ((st[VK_MENU]&0x80)==0)
    scan=@mapVirtualKey.call(vk,0)
    buf="\0"*16
    # flag 4 = no cambiar el estado de teclas muertas del sistema
    ret=@toUnicode.call(vk,scan,@kbs,buf,8,4)
    # Algunas capas de Win32API devuelven -1 como entero sin signo (4294967295).
    # Lo normalizamos y limitamos al tamaño del buffer (8 unidades UTF-16),
    # para que ningún bucle de abajo pueda recorrer miles de millones de vueltas.
    ret-=0x100000000 if ret>0x7FFFFFFF
    ret=8 if ret>8
    units=buf.unpack("v*")
    out=""
    if DEBUG && (ret<0 || @dead)
      log("[acento] vk=#{vk} ret=#{ret} units=#{units[0,4].inspect} pendiente=#{@dead.inspect}")
    end
    # Acento muerto. Windows puede devolver -1, o devolver el acento una o dos
    # veces (p. ej. "´´") si el estado de teclas muertas ya lo consumió el
    # sistema de mensajes. En todos esos casos el acento queda pendiente y no se imprime.
    same=(ret>0)
    if ret>0
      for k in 0...ret
        same=false if units[k]!=units[0]
      end
    end
    deadLike=(ret<0) || (same && DEAD_CHARS.include?(units[0]))
    if deadLike
      cp=units[0]
      if @dead==cp
        # Misma tecla de acento dos veces seguidas: un solo acento
        out=pbUTF8FromCodepoint(cp)
        @dead=nil
        return out
      end
      out=pbUTF8FromCodepoint(@dead) if @dead
      @dead=cp
      @deadVk=vk
      return (out=="") ? nil : out
    end
    return nil if ret==0   # Shift, Ctrl, flechas...: el acento pendiente se conserva
    i=0
    while i<ret
      u=units[i]
      i+=1
      if u>=0xD800 && u<=0xDBFF && i<ret && units[i]>=0xDC00 && units[i]<=0xDFFF
        cp=0x10000+((u-0xD800)<<10)+(units[i]-0xDC00)
        i+=1
      else
        cp=u
      end
      if cp<0x20 || cp==0x7F
        # Enter, Tab, Backspace, Esc... no son texto: cancelan el acento pendiente
        @dead=nil
        next
      end
      if @dead
        if cp==0x20
          # Como Windows: acento + espacio = solo el acento
          out+=pbUTF8FromCodepoint(@dead)
          @dead=nil
          next
        end
        if accented?(@dead,cp)
          out+=pbUTF8FromCodepoint(cp)
          @dead=nil
          next
        end
        composed=compose(@dead,cp)
        if composed
          out+=composed
          @dead=nil
          next
        end
        out+=pbUTF8FromCodepoint(@dead)
        @dead=nil
      end
      out+=pbUTF8FromCodepoint(cp)
    end
    return (out=="") ? nil : out
  end

  # Respaldo cuando Win32API no está disponible (MKXP fuera de Windows).
  def self.fallbackPoll
    events=[]
    begin
      events.push([VK_RETURN,nil]) if Input.triggerex?(:RETURN)
      events.push([VK_ESCAPE,nil]) if Input.triggerex?(:ESCAPE)
      events.push([VK_BACK,nil])   if Input.triggerex?(:BACKSPACE)
      events.push([VK_LEFT,nil])   if Input.triggerex?(:LEFT)
      events.push([VK_RIGHT,nil])  if Input.triggerex?(:RIGHT)
    rescue Exception
    end
    return events
  end
end
class Window_CharacterEntry < Window_DrawableCommand
  XSIZE=13
  YSIZE=4

  def initialize(charset,viewport=nil)
    @viewport=viewport
    @charset=charset
    @othercharset=""
    super(0,96,480,192)
    colors=getDefaultTextColors(self.windowskin)
    self.baseColor=colors[0]
    self.shadowColor=colors[1]
    self.columns=XSIZE
    refresh
  end

  def setOtherCharset(value)
    @othercharset=value.clone
    refresh
  end

  def setCharset(value)
    @charset=value.clone
    refresh
  end

  def character
    if self.index<0 || self.index>=@charset.length
      return "";
    else
      return @charset[self.index]
    end
  end

  def command
    return -1 if self.index==@charset.length
    return -2 if self.index==@charset.length+1
    return -3 if self.index==@charset.length+2
    return self.index
  end

  def itemCount
    return @charset.length+3
  end

  def drawItem(index,count,rect)
    rect=drawCursor(index,rect)
    if index==@charset.length # -1
      pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,"[ ]",
         self.baseColor,self.shadowColor)
    elsif index==@charset.length+1 # -2
      pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,@othercharset,
         self.baseColor,self.shadowColor)
    elsif index==@charset.length+2 # -3
      pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,_INTL("OK"),
         self.baseColor,self.shadowColor)
    else
      pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,@charset[index],
         self.baseColor,self.shadowColor)
    end
  end
end



class CharacterEntryHelper
  attr_reader :text
  attr_reader :maxlength
  attr_reader :passwordChar 
  attr_accessor :cursor

  def text=(value)
    @text=value
    ensure
  end

  def textChars
    chars=pbUTF8Chars(text)
    if @passwordChar!=""
      chars.length.times {|i|
         chars[i]=@passwordChar
      }
    end
    return chars
  end

  def initialize(text)
    @maxlength=-1
    @text=text
    @passwordChar=""
    @cursor=pbUTF8Chars(text).length
    ensure
  end

  def passwordChar=(value)
    @passwordChar=value ? value : ""
  end

  def maxlength=(value)
    @maxlength=value
    ensure
  end

  def length
    return pbUTF8Chars(self.text).length
  end

  def canInsert?
    chars=pbUTF8Chars(self.text)
    return false if @maxlength>=0 && chars.length>=@maxlength
    return true
  end

  def insert(ch)
    chars=pbUTF8Chars(self.text)
    return false if @maxlength>=0 && chars.length>=@maxlength
    chars.insert(@cursor,ch)
    @text=""
    for ch in chars
      @text+=ch if ch
    end
    @cursor+=1
    return true
  end

  def canDelete?
    chars=pbUTF8Chars(self.text)
    return false if chars.length<=0 || @cursor<=0
    return true
  end

  def delete
    chars=pbUTF8Chars(self.text)
    return false if chars.length<=0 || @cursor<=0
    chars.delete_at(@cursor-1)
    @text=""
    for ch in chars
      @text+=ch if ch
    end
    @cursor-=1
    return true
  end

  private

  def ensure
    return if @maxlength<0
    chars=pbUTF8Chars(self.text)
    if chars.length>@maxlength && @maxlength>=0
      chars=chars[0,@maxlength]
    end
    @text=""
    for ch in chars
      @text+=ch if ch
    end
  end
end



class Window_TextEntry < SpriteWindow_Base
  def initialize(text,x,y,width,height,heading=nil,usedarkercolor=false)
    super(x,y,width,height)
    colors=getDefaultTextColors(self.windowskin)
    @baseColor=colors[0]
    @shadowColor=colors[1]
    if usedarkercolor
      @baseColor=Color.new(16,24,32)
      @shadowColor=Color.new(168,184,184)
    end
    @helper=CharacterEntryHelper.new(text)
    @heading=heading
    self.active=true
    @frame=0
    refresh
  end

  def text
    @helper.text
  end

  def maxlength
    @helper.maxlength
  end

  def passwordChar
    @helper.passwordChar
  end

  def text=(value)
    @helper.text=value
    self.refresh
  end

  def passwordChar=(value)
    @helper.passwordChar=value
    refresh
  end

  def maxlength=(value)
    @helper.maxlength=value 
    self.refresh
  end

  def insert(ch)
    if @helper.insert(ch)
      @frame=0
      self.refresh
      return true
    end
    return false
  end

  def delete
    if @helper.delete
      @frame=0
      self.refresh
      return true
    end
    return false
  end

  def update
    @frame+=1
    @frame%=20
    self.refresh if ((@frame%10)==0)
    return if !self.active
    # Moving cursor
    if Input.repeat?(Input::LEFT) && Input.press?(Input::A)
      if @helper.cursor > 0
        @helper.cursor-=1
        @frame=0
        self.refresh
      end
      return
    end
    if Input.repeat?(Input::RIGHT) && Input.press?(Input::A)
      if @helper.cursor < pbUTF8Chars(self.text).length
        @helper.cursor+=1
        @frame=0
        self.refresh
      end
      return
    end
    # Backspace
    if Input.repeat?(Input::B)
      self.delete if @helper.cursor > 0
      return
    end
  end

  def refresh
    self.contents=pbDoEnsureBitmap(self.contents,self.width-self.borderX,
       self.height-self.borderY)
    bitmap=self.contents
    bitmap.clear
    x=0
    y=0
    if @heading
      textwidth=bitmap.text_size(@heading).width
      pbDrawShadowText(bitmap,x,y, textwidth+4, 32, @heading,@baseColor,@shadowColor)
      y+=32
    end
    x+=4
    width=self.width-self.borderX
    height=self.height-self.borderY
    cursorcolor=Color.new(16,24,32)
    textscan=pbUTF8Chars(self.text)
    scanlength=textscan.length
    @helper.cursor=scanlength if @helper.cursor>scanlength
    @helper.cursor=0 if @helper.cursor<0
    startpos=@helper.cursor
    fromcursor=0
    while (startpos>0)
      c=(@helper.passwordChar!="") ? @helper.passwordChar : textscan[startpos-1]
      fromcursor+=bitmap.text_size(c).width
      break if fromcursor>width-4
      startpos-=1
    end
    for i in startpos...scanlength
      c=(@helper.passwordChar!="") ? @helper.passwordChar : textscan[i]
      textwidth=bitmap.text_size(c).width
      next if c=="\n"  
      # Draw text
      pbDrawShadowText(bitmap,x,y, textwidth+4, 32, c,@baseColor,@shadowColor)
      # Draw cursor if necessary
      if ((@frame/10)&1) == 0 && i==@helper.cursor
        bitmap.fill_rect(x,y+4,2,24,cursorcolor)
      end
      # Add x to drawn text width
      x += textwidth
    end
    if ((@frame/10)&1) == 0 && textscan.length==@helper.cursor
      bitmap.fill_rect(x,y+4,2,24,cursorcolor)
    end
  end
end



def getLineBrokenText(bitmap,value,width,dims)
  x=0
  y=0
  textheight=0
  ret=[]
  if dims
    dims[0]=0
    dims[1]=0
  end
  line=0
  position=0
  column=0
  return ret if !bitmap || bitmap.disposed? || width<=0
  textmsg=value.clone
  lines=0
  color=Font.default_color
  ret.push(["",0,0,0,bitmap.text_size("X").height,0,0,0,0])
  while ((c = textmsg.slice!(/\n|(\S*([ \r\t\f]?))/)) != nil)
    break if c==""
    length=pbUTF8Chars(c).length
    ccheck=c
    if ccheck=="\n"
      ret.push(["\n",x,y,0,textheight,line,position,column,0])
      x=0
      y+=(textheight==0) ? bitmap.text_size("X").height : textheight
      line+=1
      textheight=0
      column=0
      position+=length
      ret.push(["",x,y,0,textheight,line,position,column,0])
      next
    end
    textcols=[]
    words=[ccheck]
    for i in 0...words.length
      word=words[i]
      if word && word!=""
        textSize=bitmap.text_size(word)
        textwidth=textSize.width
        if x>0 && x+textwidth>=width-2
          # Zero-length word break
          ret.push(["",x,y,0,textheight,line,position,column,0])
          x=0
          column=0
          y+=(textheight==0) ? bitmap.text_size("X").height : textheight
          line+=1
          textheight=0
        end
        textheight=[textheight,textSize.height].max
        ret.push([word,x,y,textwidth,textheight,line,position,column,length])
        x+=textwidth
        dims[0]=x if dims && dims[0]<x
      end
      if textcols[i]
        color=textcols[i]
      end
    end
    position+=length
    column+=length
  end
  dims[1]=y+textheight if dims
  return ret
end



class Window_MultilineTextEntry < SpriteWindow_Base
  def initialize(text,x,y,width,height)
    super(x,y,width,height)
    colors=getDefaultTextColors(self.windowskin)
    @baseColor=colors[0]
    @shadowColor=colors[1]
    @helper=CharacterEntryHelper.new(text)
    @firstline=0
    @cursorLine=0
    @cursorColumn=0
    @frame=0
    self.active=true
    refresh
  end

  attr_reader :baseColor
  attr_reader :shadowColor

  def baseColor=(value)
    @baseColor=value
    refresh
  end

  def shadowColor=(value)
    @shadowColor=value
    refresh
  end

  def text
    @helper.text
  end

  def maxlength
    @helper.maxlength
  end

  def text=(value)
    @helper.text=value
    @textchars=nil
    self.refresh
  end

  def maxlength=(value)
    @helper.maxlength=value 
    @textchars=nil
    self.refresh
  end

  def insert(ch)
    @helper.cursor=getPosFromLineAndColumn(@cursorLine,@cursorColumn)
    if @helper.insert(ch)
      @frame=0
      @textchars=nil
      moveCursor(0,1)
      self.refresh
      return true
    end
    return false
  end

  def delete
    @helper.cursor=getPosFromLineAndColumn(@cursorLine,@cursorColumn)
    if @helper.delete
      @frame=0
      moveCursor(0,-1) # use old textchars
      @textchars=nil
      self.refresh
      return true
    end
    return false
  end

  def getTextChars
    if !@textchars
      @textchars=getLineBrokenText(self.contents,@helper.text,
         self.contents.width,nil)
    end
    return @textchars
  end

  def getTotalLines
    textchars=getTextChars
    if textchars.length==0
      return 1
    else
      tchar=textchars[textchars.length-1]
      return tchar[5]+1
    end
  end

  def getLineY(line)
    textchars=getTextChars
    if textchars.length==0
      return 0
    else
      totallines=getTotalLines()
      line=0 if line<0
      line=totallines-1 if line>=totallines
      maximumY=0
      for i in 0...textchars.length
        thisline=textchars[i][5]
        y=textchars[i][2]
        return y if thisline==line
        maximumY=y if maximumY<y
      end
      return maximumY
    end
  end

  def getColumnsInLine(line)
    textchars=getTextChars
    if textchars.length==0
      return 0
    else
      totallines=getTotalLines()
      line=0 if line<0
      line=totallines-1 if line>=totallines
      endpos=0
      for i in 0...textchars.length
        thisline=textchars[i][5]
        thispos=textchars[i][6]
        thislength=textchars[i][8]
        if thisline==line
          endpos+=thislength
        end
      end
      return endpos
    end
  end

  def getPosFromLineAndColumn(line,column)
    textchars=getTextChars
    if textchars.length==0
      return 0
    else
      totallines=getTotalLines()
      line=0 if line<0
      line=totallines-1 if line>=totallines
      endpos=0
      for i in 0...textchars.length
        thisline=textchars[i][5]
        thispos=textchars[i][6]
        thiscolumn=textchars[i][7]
        thislength=textchars[i][8]
        if thisline==line
          endpos=thispos+thislength
#         echoln [endpos,thispos+(column-thiscolumn),textchars[i]]
          if column>=thiscolumn && column<=thiscolumn+thislength && thislength>0
            return thispos+(column-thiscolumn)
          end
        end
      end
      if endpos==0
#       echoln [totallines,line,column]
#       echoln textchars
      end
#     echoln "endpos=#{endpos}"
      return endpos
    end
  end

  def getLastVisibleLine
    textchars=getTextChars()
    textheight=[1,self.contents.text_size("X").height].max
    lastVisible=@firstline+((self.height-self.borderY)/textheight)-1
    return lastVisible
  end

  def updateCursorPos(doRefresh)
    # Calculate new cursor position
    @helper.cursor=getPosFromLineAndColumn(@cursorLine,@cursorColumn)
    if doRefresh
      @frame=0
      self.refresh
    end
    if @cursorLine<@firstline
      @firstline=@cursorLine
    end
    lastVisible=getLastVisibleLine()
    if @cursorLine>lastVisible
      @firstline+=(@cursorLine-lastVisible)
    end
  end

  def moveCursor(lineOffset, columnOffset)
    # Move column offset first, then lines (since column offset
    # can affect line offset)
#   echoln ["beforemoving",@cursorLine,@cursorColumn]
    totalColumns=getColumnsInLine(@cursorLine) # check current line
    totalLines=getTotalLines()
    oldCursorLine=@cursorLine
    oldCursorColumn=@cursorColumn
    @cursorColumn+=columnOffset
    if @cursorColumn<0 && @cursorLine>0
      # Will happen if cursor is moved left from the beginning of a line
      @cursorLine-=1
      @cursorColumn=getColumnsInLine(@cursorLine)
    elsif @cursorColumn>totalColumns && @cursorLine<totalLines-1
      # Will happen if cursor is moved right from the end of a line
      @cursorLine+=1
      @cursorColumn=0
      updateColumns=true
    end
    # Ensure column bounds
    totalColumns=getColumnsInLine(@cursorLine)
    @cursorColumn=totalColumns if @cursorColumn>totalColumns
    @cursorColumn=0 if @cursorColumn<0 # totalColumns can be 0
    # Move line offset
    @cursorLine+=lineOffset
    @cursorLine=0 if @cursorLine<0
    @cursorLine=totalLines-1 if @cursorLine>=totalLines
    # Ensure column bounds again
    totalColumns=getColumnsInLine(@cursorLine)
    @cursorColumn=totalColumns if @cursorColumn>totalColumns
    @cursorColumn=0 if @cursorColumn<0 # totalColumns can be 0
    updateCursorPos(
       oldCursorLine!=@cursorLine ||
       oldCursorColumn!=@cursorColumn
    )
#   echoln ["aftermoving",@cursorLine,@cursorColumn]
  end

  def update(events=nil)
    @frame+=1
    @frame%=20
    self.refresh if ((@frame%10)==0)
    return if !self.active
    events=KeyboardText.poll if !events
    ctrl=KeyboardText.down?(KeyboardText::VK_CONTROL)
    for ev in events
      vk=ev[0]
      txt=ev[1]
      if txt
        for ch in pbUTF8Chars(txt)
          self.insert(ch)
        end
        next
      end
      if ctrl && vk==KeyboardText::VK_HOME
        @cursorLine=0
        @cursorColumn=0
        updateCursorPos(true)
      elsif ctrl && vk==KeyboardText::VK_END
        @cursorLine=getTotalLines()-1
        @cursorColumn=getColumnsInLine(@cursorLine)
        updateCursorPos(true)
      else
        case vk
        when KeyboardText::VK_LEFT
          moveCursor(0,-1)
        when KeyboardText::VK_RIGHT
          moveCursor(0,1)
        when KeyboardText::VK_UP
          moveCursor(-1,0)
        when KeyboardText::VK_DOWN
          moveCursor(1,0)
        when KeyboardText::VK_RETURN
          self.insert("\n")
        when KeyboardText::VK_BACK
          self.delete
        end
      end
    end
  end

  def refresh
    newContents=pbDoEnsureBitmap(self.contents,self.width-self.borderX,
       self.height-self.borderY)
    @textchars=nil if self.contents!=newContents
    self.contents=newContents
    bitmap=self.contents
    bitmap.clear
    x=0
    y=0
    getTextChars
    x+=4
    width=self.width-self.borderX
    height=self.height-self.borderY
    cursorcolor=Color.new(0,0,0)
    textchars=getTextChars()
    scanlength=@helper.length
    startY=getLineY(@firstline)
    lastheight=32
    for i in 0...textchars.length
      thisline=textchars[i][5]
      thispos=textchars[i][6]
      thiscolumn=textchars[i][7]
      thislength=textchars[i][8]
      textY=textchars[i][2]-startY
      # Don't draw lines before the first or zero-length segments
      next if thisline<@firstline || thislength==0
      # Don't draw lines beyond the window's height
      break if textY >= height
      c=textchars[i][0]
      # Don't draw spaces
      next if c==" "
      textwidth=textchars[i][3]+4 # add 4 to prevent draw_text from stretching text
      textheight=textchars[i][4]
      lastheight=textheight
      # Draw text
      pbDrawShadowText(bitmap,textchars[i][1],textY, textwidth, textheight, c,@baseColor,@shadowColor)
    end
    # Draw cursor
    if ((@frame/10)&1) == 0
      textheight=bitmap.text_size("X").height
      cursorY=(textheight*@cursorLine)-startY
      cursorX=0
      for i in 0...textchars.length
        thisline=textchars[i][5]
        thispos=textchars[i][6]
        thiscolumn=textchars[i][7]
        thislength=textchars[i][8]
        if thisline==@cursorLine && @cursorColumn>=thiscolumn && 
           @cursorColumn<=thiscolumn+thislength
          cursorY=textchars[i][2]-startY
          cursorX=textchars[i][1]
          textheight=textchars[i][4]
          posToCursor=@cursorColumn-thiscolumn
          if posToCursor>=0
            partialString=pbUTF8Chars(textchars[i][0])[0,posToCursor].join("")
            cursorX+=bitmap.text_size(partialString).width
          end
          break
        end
      end
      cursorY+=4
      cursorHeight=[4,textheight-4,bitmap.text_size("X").height-4].max
      bitmap.fill_rect(cursorX,cursorY,2,cursorHeight,cursorcolor)
    end
  end
end



class Window_TextEntry_Keyboard < Window_TextEntry
  # Teclas ya traducidas por KeyboardText.poll (ver arriba).
  # events: lista [[vk, texto_o_nil], ...]. Si es nil, la ventana lee el teclado.
  def update(events=nil)
    @frame+=1
    @frame%=20
    self.refresh if ((@frame%10)==0)
    return if !self.active
    events=KeyboardText.poll if !events
    for ev in events
      vk=ev[0]
      txt=ev[1]
      if txt
        for ch in pbUTF8Chars(txt)
          self.insert(ch)
        end
        next
      end
      case vk
      when KeyboardText::VK_LEFT
        if @helper.cursor>0
          @helper.cursor-=1
          @frame=0
          self.refresh
        end
      when KeyboardText::VK_RIGHT
        if @helper.cursor<@helper.length
          @helper.cursor+=1
          @frame=0
          self.refresh
        end
      when KeyboardText::VK_HOME
        @helper.cursor=0
        @frame=0
        self.refresh
      when KeyboardText::VK_END
        @helper.cursor=@helper.length
        @frame=0
        self.refresh
      when KeyboardText::VK_BACK
        self.delete if @helper.cursor>0
      when KeyboardText::VK_DELETE
        if @helper.cursor<@helper.length
          @helper.cursor+=1
          self.delete
        end
      end
    end
  end
end




def Kernel.pbFreeText(msgwindow,currenttext,passwordbox,maxlength,width=240)
  window=Window_TextEntry_Keyboard.new(currenttext,0,0,width,64)
  ret=""
  window.maxlength=maxlength
  window.visible=true
  window.z=99999
  pbPositionNearMsgWindow(window,msgwindow,:right)
  window.text=currenttext
  window.passwordChar="*" if passwordbox
  KeyboardText.reset
  loop do
    Graphics.update
    Input.update
    events=KeyboardText.poll
    if events.any?{|e| e[0]==KeyboardText::VK_ESCAPE}
      ret=currenttext
      break
    end
    if events.any?{|e| e[0]==KeyboardText::VK_RETURN}
      ret=window.text
      break
    end
    window.update(events)
    msgwindow.update if msgwindow
    yield if block_given?
  end
  window.dispose
  Input.update
  return ret
end

def Kernel.pbMessageFreeText(message,currenttext,passwordbox,maxlength,width=240,&block)
  msgwindow=Kernel.pbCreateMessageWindow
  retval=Kernel.pbMessageDisplay(msgwindow,message,true,
     proc{|msgwindow|
        next Kernel.pbFreeText(msgwindow,currenttext,passwordbox,maxlength,width,&block)
     },&block)
  Kernel.pbDisposeMessageWindow(msgwindow)
  return retval
end



#===============================================================================
# Text entry screen - free typing.
#===============================================================================
class PokemonEntryScene
  @@Characters=[
     [pbUTF8Chars("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"),"[*]"],
     [pbUTF8Chars("0123456789   !@\#$%^&*()   ~`-_+={}[]   :;'\"<>,.?/   "),"[A]"],
  ]
  USEKEYBOARD=true

  def pbStartScene(helptext,minlength,maxlength,initialText,subject=0,pokemon=nil)
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    if USEKEYBOARD
      @sprites["entry"]=Window_TextEntry_Keyboard.new(initialText,
         0,0,400-112,96,helptext,true)
    else
      @sprites["entry"]=Window_TextEntry.new(initialText,0,0,400,96,helptext,true)
    end
    @sprites["entry"].x=(Graphics.width/2)-(@sprites["entry"].width/2)+32
    @sprites["entry"].viewport=@viewport
    @sprites["entry"].visible=true
    @minlength=minlength
    @maxlength=maxlength
    @symtype=0
    @sprites["entry"].maxlength=maxlength
    if !USEKEYBOARD
      @sprites["entry2"]=Window_CharacterEntry.new(@@Characters[@symtype][0])
      @sprites["entry2"].setOtherCharset(@@Characters[@symtype][1])
      @sprites["entry2"].viewport=@viewport
      @sprites["entry2"].visible=true
      @sprites["entry2"].x=(Graphics.width/2)-(@sprites["entry2"].width/2)
    end
    if minlength==0
      @sprites["helpwindow"]=Window_UnformattedTextPokemon.newWithSize(
         _INTL("Escribe usando el teclado. Presiona\nESC para cancelar, o INTRO para aceptar."),
         32,Graphics.height-96,Graphics.width-64,96,@viewport
      )
    else
      @sprites["helpwindow"]=Window_UnformattedTextPokemon.newWithSize(
         _INTL("Escribe usando el teclado. Presiona\nESC para cancelar, o INTRO para aceptar."),
         32,Graphics.height-96,Graphics.width-64,96,@viewport
      )
    end
    #x,y,width,height
    @sprites["helpwindow"].letterbyletter=false
    @sprites["helpwindow"].viewport=@viewport
    @sprites["helpwindow"].visible=USEKEYBOARD
    @sprites["helpwindow"].baseColor=Color.new(16,24,32)
    @sprites["helpwindow"].shadowColor=Color.new(168,184,184)
    addBackgroundPlane(@sprites,"background","Naming/naming2bg",@viewport)
    case subject
    when 1   # Player
      if $PokemonGlobal
        meta=pbGetMetadata(0,MetadataPlayerA+$PokemonGlobal.playerID)
        if meta
          @sprites["shadow"]=IconSprite.new(0,0,@viewport)
          @sprites["shadow"].setBitmap("Graphics/#{NAMING_ROUTE}/namingShadow")
          @sprites["shadow"].x=33*2
          @sprites["shadow"].y=32*2
          filename=pbGetPlayerCharset(meta,1)
          @sprites["subject"]=TrainerWalkingCharSprite.new(filename,@viewport)
          charwidth=@sprites["subject"].bitmap.width
          charheight=@sprites["subject"].bitmap.height
          @sprites["subject"].x = 44*2 - charwidth/8
          @sprites["subject"].y = 38*2 - charheight/4

          @sprites["trainer"]=IconSprite.new(336,112,@viewport)
          @sprites["trainer"].setBitmap(pbPlayerSpriteFile($Trainer.trainertype))
          pbPositionPokemonSprite(@sprites["trainer"],176,120)

        end
      end
    when 2   # Pokémon
      if pokemon
        @sprites["shadow"]=IconSprite.new(0,0,@viewport)
        @sprites["shadow"].setBitmap("Graphics/#{NAMING_ROUTE}/namingShadow")
        @sprites["shadow"].x=33*2
        @sprites["shadow"].y=32*2
        @sprites["subject"]=PokemonIconSprite.new(pokemon,@viewport)
        @sprites["subject"].x=56
        @sprites["subject"].y=14

        @sprites["pokemon"]=PokemonSprite.new(@viewport)
        @sprites["pokemon"].setPokemonBitmap(pokemon)
        @sprites["pokemon"].mirror=false
        @sprites["pokemon"].color=Color.new(0,0,0,0)
        
        pbPositionPokemonSprite(@sprites["pokemon"],176,120)

        @sprites["gender"]=BitmapSprite.new(32,32,@viewport)
        @sprites["gender"].x=430
        @sprites["gender"].y=54
        @sprites["gender"].bitmap.clear
        pbSetSystemFont(@sprites["gender"].bitmap)
        textpos=[]
        if pokemon.isMale?
          textpos.push([_INTL("♂"),0,0,false,Color.new(0,128,248),Color.new(168,184,184)])
        elsif pokemon.isFemale?
          textpos.push([_INTL("♀"),0,0,false,Color.new(248,24,24),Color.new(168,184,184)])
        end
        pbDrawTextPositions(@sprites["gender"].bitmap,textpos)
      end
    when 3   # Storage box
      @sprites["subject"]=TrainerWalkingCharSprite.new(nil,@viewport)
      @sprites["subject"].altcharset="Graphics/#{NAMING_ROUTE}/namingStorage"
      @sprites["subject"].animspeed=4
      charwidth=@sprites["subject"].bitmap.width
      charheight=@sprites["subject"].bitmap.height
      @sprites["subject"].x = 44*2 - charwidth/8
      @sprites["subject"].y = 26*2 - charheight/2
    when 4   # NPC
      @sprites["shadow"]=IconSprite.new(0,0,@viewport)
      @sprites["shadow"].setBitmap("Graphics/#{NAMING_ROUTE}/namingShadow")
      @sprites["shadow"].x=33*2
      @sprites["shadow"].y=32*2
      @sprites["subject"]=TrainerWalkingCharSprite.new(pokemon.to_s,@viewport)
      charwidth=@sprites["subject"].bitmap.width
      charheight=@sprites["subject"].bitmap.height
      @sprites["subject"].x = 44*2 - charwidth/8
      @sprites["subject"].y = 38*2 - charheight/4
    end
    pbFadeInAndShow(@sprites)
  end

  def pbEntry1
    ret=""
    KeyboardText.reset
    loop do
      Graphics.update
      Input.update
      events=KeyboardText.poll
      if @minlength==0 && events.any?{|e| e[0]==KeyboardText::VK_ESCAPE}
        ret=""
        break
      end
      if events.any?{|e| e[0]==KeyboardText::VK_RETURN} &&
         pbUTF8Chars(@sprites["entry"].text).length>=@minlength
        ret=@sprites["entry"].text
        break
      end
      @sprites["helpwindow"].update
      @sprites["entry"].update(events)
      @sprites["subject"].update if @sprites["subject"]
    end
    Input.update
    return ret
  end

  def pbEntry2
    ret=""
    loop do
      Graphics.update
      Input.update
      @sprites["helpwindow"].update
      @sprites["entry"].update
      @sprites["entry2"].update
      @sprites["subject"].update if @sprites["subject"]
      if Input.trigger?(Input::C)
        index=@sprites["entry2"].command
        if index==-3 # Confirm text
          ret=@sprites["entry"].text
          if pbUTF8Chars(ret).length<@minlength || pbUTF8Chars(ret).length>@maxlength
            pbPlayBuzzerSE()
          else
            pbPlayDecisionSE()
            break
          end
        elsif index==-1 # Insert a space
          if @sprites["entry"].insert(" ")
            pbPlayDecisionSE()
          else
            pbPlayBuzzerSE()
          end
        elsif index==-2 # Change character set
          pbPlayDecisionSE()
          @symtype+=1
          @symtype=0 if @symtype>=@@Characters.length
          @sprites["entry2"].setCharset(@@Characters[@symtype][0])
          @sprites["entry2"].setOtherCharset(@@Characters[@symtype][1])
        else # Insert given character
          if @sprites["entry"].insert(@sprites["entry2"].character)
            pbPlayDecisionSE() 
          else
            pbPlayBuzzerSE()
          end
        end
        next
      end
    end 
    Input.update
    return ret
  end

  def pbEntry
    return USEKEYBOARD ? pbEntry1 : pbEntry2
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



#===============================================================================
# Text entry screen - arrows to select letter.
#===============================================================================
class PokemonEntryScene2
  @@Characters=[
     [pbUTF8Chars("ABCDEFGHIJ ,."+"KLMNOPQRST '-"+"UVWXYZ     ♂♀"+"             "+"0123456789   "),_INTL("UPPER")],
     [pbUTF8Chars("abcdefghij ,."+"klmnopqrst '-"+"uvwxyz     ♂♀"+"             "+"0123456789   "),_INTL("lower")],
     [pbUTF8Chars(",.:;!?   ♂♀  "+"\"'()<>[]     "+"~@#%*&$      "+"+-=^_/\\|     "+"             "),_INTL("other")],
  ]
  ROWS=13
  COLUMNS=5
  MODE1=-5
  MODE2=-4
  MODE3=-3
  BACK=-2
  OK=-1

  class NameEntryCursor
    def initialize(viewport)
      @sprite=SpriteWrapper.new(viewport)
      @cursortype=0
      @cursor1=AnimatedBitmap.new("Graphics/#{NAMING_ROUTE}/NamingCursor1")
      @cursor2=AnimatedBitmap.new("Graphics/#{NAMING_ROUTE}/NamingCursor2")
      @cursor3=AnimatedBitmap.new("Graphics/#{NAMING_ROUTE}/NamingCursor3")
      @cursorPos=0
      updateInternal
    end

    def setCursorPos(value)
      @cursorPos=value
    end

    def updateCursorPos
      value=@cursorPos
      if value==PokemonEntryScene2::MODE1 # Upper case
        @sprite.x=48
        @sprite.y=120
        @cursortype=1
      elsif value==PokemonEntryScene2::MODE2 # Lower case
        @sprite.x=112
        @sprite.y=120
        @cursortype=1
      elsif value==PokemonEntryScene2::MODE3 # Other symbols
        @sprite.x=176
        @sprite.y=120
        @cursortype=1
      elsif value==PokemonEntryScene2::BACK # Back
        @sprite.x=312
        @sprite.y=120
        @cursortype=2
      elsif value==PokemonEntryScene2::OK # OK
        @sprite.x=392
        @sprite.y=120
        @cursortype=2
      elsif value>=0
        @sprite.x=52+32*(value%PokemonEntryScene2::ROWS)
        @sprite.y=180+38*(value/PokemonEntryScene2::ROWS)
        @cursortype=0
      end
    end

    def visible=(value)
      @sprite.visible=value
    end

    def visible
      @sprite.visible
    end

    def color=(value)
      @sprite.color=value
    end

    def color
      @sprite.color
    end

    def disposed?
      @sprite.disposed?
    end

    def updateInternal
      @cursor1.update
      @cursor2.update
      @cursor3.update
      updateCursorPos
      case @cursortype
      when 0
        @sprite.bitmap=@cursor1.bitmap
      when 1
        @sprite.bitmap=@cursor2.bitmap
      when 2
        @sprite.bitmap=@cursor3.bitmap
      end
    end

    def update
      updateInternal    
    end

    def dispose
      @cursor1.dispose
      @cursor2.dispose
      @cursor3.dispose
      @sprite.dispose
    end
  end



  def pbStartScene(helptext,minlength,maxlength,initialText,subject=0,pokemon=nil)
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @helptext=helptext
    @helper=CharacterEntryHelper.new(initialText)
    @bitmaps=[
       AnimatedBitmap.new("Graphics/#{NAMING_ROUTE}/namingTab1"),
       AnimatedBitmap.new("Graphics/#{NAMING_ROUTE}/namingTab2"),
       AnimatedBitmap.new("Graphics/#{NAMING_ROUTE}/namingTab3")
    ]
    @bitmaps[3]=@bitmaps[0].bitmap.clone
    @bitmaps[4]=@bitmaps[1].bitmap.clone
    @bitmaps[5]=@bitmaps[2].bitmap.clone
    for i in 0...3
      pos=0
      pbSetSystemFont(@bitmaps[i+3])
      textPos=[]
      for y in 0...COLUMNS
        for x in 0...ROWS
          textPos.push([@@Characters[i][0][pos],44+x*32,18+y*38,2,
             Color.new(16,24,32), Color.new(160,160,160)])
          pos+=1
        end
      end
      pbDrawTextPositions(@bitmaps[i+3],textPos)
    end
    @bitmaps[6]=BitmapWrapper.new(24,6)
    @bitmaps[6].fill_rect(2,2,22,4,Color.new(168,184,184))
    @bitmaps[6].fill_rect(0,0,22,4,Color.new(16,24,32))
    @sprites["bg"]=IconSprite.new(0,0,@viewport)
    @sprites["bg"].setBitmap("Graphics/#{NAMING_ROUTE}/namingbg")
    case subject
    when 1   # Player
      if $PokemonGlobal
        meta=pbGetMetadata(0,MetadataPlayerA+$PokemonGlobal.playerID)
        if meta
          @sprites["shadow"]=IconSprite.new(0,0,@viewport)
          @sprites["shadow"].setBitmap("Graphics/#{NAMING_ROUTE}/namingShadow")
          @sprites["shadow"].x=33*2
          @sprites["shadow"].y=32*2
          filename=pbGetPlayerCharset(meta,1)
          @sprites["subject"]=TrainerWalkingCharSprite.new(filename,@viewport)
          charwidth=@sprites["subject"].bitmap.width
          charheight=@sprites["subject"].bitmap.height
          @sprites["subject"].x = 44*2 - charwidth/8
          @sprites["subject"].y = 38*2 - charheight/4
        end
      end
    when 2   # Pokémon
      if pokemon
        @sprites["shadow"]=IconSprite.new(0,0,@viewport)
        @sprites["shadow"].setBitmap("Graphics/#{NAMING_ROUTE}/namingShadow")
        @sprites["shadow"].x=33*2
        @sprites["shadow"].y=32*2
        @sprites["subject"]=PokemonIconSprite.new(pokemon,@viewport)
        @sprites["subject"].x=56
        @sprites["subject"].y=14
        @sprites["gender"]=BitmapSprite.new(32,32,@viewport)
        @sprites["gender"].x=430
        @sprites["gender"].y=54
        @sprites["gender"].bitmap.clear
        pbSetSystemFont(@sprites["gender"].bitmap)
        textpos=[]
        if pokemon.isMale?
          textpos.push([_INTL("♂"),0,0,false,Color.new(0,128,248),Color.new(168,184,184)])
        elsif pokemon.isFemale?
          textpos.push([_INTL("♀"),0,0,false,Color.new(248,24,24),Color.new(168,184,184)])
        end
        pbDrawTextPositions(@sprites["gender"].bitmap,textpos)
      end
    when 3   # Storage box
      @sprites["subject"]=TrainerWalkingCharSprite.new(nil,@viewport)
      @sprites["subject"].altcharset="Graphics/#{NAMING_ROUTE}/namingStorage"
      @sprites["subject"].animspeed=4
      charwidth=@sprites["subject"].bitmap.width
      charheight=@sprites["subject"].bitmap.height
      @sprites["subject"].x = 44*2 - charwidth/8
      @sprites["subject"].y = 26*2 - charheight/2
    when 4   # NPC
      @sprites["shadow"]=IconSprite.new(0,0,@viewport)
      @sprites["shadow"].setBitmap("Graphics/#{NAMING_ROUTE}/namingShadow")
      @sprites["shadow"].x=33*2
      @sprites["shadow"].y=32*2
      @sprites["subject"]=TrainerWalkingCharSprite.new(pokemon.to_s,@viewport)
      charwidth=@sprites["subject"].bitmap.width
      charheight=@sprites["subject"].bitmap.height
      @sprites["subject"].x = 44*2 - charwidth/8
      @sprites["subject"].y = 38*2 - charheight/4
    end
    @sprites["bgoverlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbDoUpdateOverlay
    @blanks=[]
    @mode=0
    @minlength=minlength
    @maxlength=maxlength
    @maxlength.times {|i|
       @sprites["blank#{i}"]=SpriteWrapper.new(@viewport)
       @sprites["blank#{i}"].bitmap=@bitmaps[6]
       @sprites["blank#{i}"].x=160+24*i
       @blanks[i]=0
    }
    @sprites["bottomtab"]=SpriteWrapper.new(@viewport) # Current tab
    @sprites["bottomtab"].x=22
    @sprites["bottomtab"].y=162
    @sprites["bottomtab"].bitmap=@bitmaps[0+3]
    @sprites["toptab"]=SpriteWrapper.new(@viewport) # Next tab
    @sprites["toptab"].x=22-504
    @sprites["toptab"].y=162
    @sprites["toptab"].bitmap=@bitmaps[1+3]
    @sprites["controls"]=IconSprite.new(0,0,@viewport)
    @sprites["controls"].setBitmap("Graphics/#{NAMING_ROUTE}/namingControls")
    @sprites["controls"].x=16
    @sprites["controls"].y=96
    @init=true
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbDoUpdateOverlay2
    @sprites["cursor"]=NameEntryCursor.new(@viewport)
    @cursorpos=0
    @refreshOverlay=true
    @sprites["cursor"].setCursorPos(@cursorpos)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbUpdateOverlay
    @refreshOverlay=true
  end

  def pbDoUpdateOverlay2
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    modeIcon=[["Graphics/#{NAMING_ROUTE}/namingMode",48+@mode*64,120,@mode*60,0,60,44]]
    pbDrawImagePositions(overlay,modeIcon)
  end

  def pbDoUpdateOverlay
    return if !@refreshOverlay
    @refreshOverlay=false
    bgoverlay=@sprites["bgoverlay"].bitmap
    bgoverlay.clear
    pbSetSystemFont(bgoverlay)
    textPositions=[
       [@helptext,160,12,false,Color.new(16,24,32),Color.new(168,184,184)]
    ]
    chars=@helper.textChars
    x=166
    for ch in chars
      textPositions.push([ch,x,48,false,Color.new(16,24,32),Color.new(168,184,184)])
      x+=24
    end
    pbDrawTextPositions(bgoverlay,textPositions)
  end

  def pbChangeTab(newtab=@mode+1)
    pbSEPlay("GUI naming tab swap start")
    @sprites["cursor"].visible=false
    @sprites["toptab"].bitmap=@bitmaps[(newtab%3)+3]
    21.times do
      @sprites["toptab"].x+=24
      @sprites["bottomtab"].y+=12
      Graphics.update
      Input.update
      pbUpdate
    end
    tempx=@sprites["toptab"].x
    @sprites["toptab"].x=@sprites["bottomtab"].x
    @sprites["bottomtab"].x=tempx
    tempy=@sprites["toptab"].y
    @sprites["toptab"].y=@sprites["bottomtab"].y
    @sprites["bottomtab"].y=tempy
    tempbitmap=@sprites["toptab"].bitmap
    @sprites["toptab"].bitmap=@sprites["bottomtab"].bitmap
    @sprites["bottomtab"].bitmap=tempbitmap
    Graphics.update
    Input.update
    pbUpdate
    @mode=(newtab)%3
    newtab=@bitmaps[((@mode+1)%3)+3]
    @sprites["cursor"].visible=true
    @sprites["toptab"].bitmap=newtab
    @sprites["toptab"].x=22-504
    @sprites["toptab"].y=162
    pbSEPlay("GUI naming tab swap end")
    pbDoUpdateOverlay2
  end

  def pbUpdate
    for i in 0...3
      @bitmaps[i].update
    end
    if @init || Graphics.frame_count%5==0
      @init=false
      cursorpos=@helper.cursor
      cursorpos=@maxlength-1 if cursorpos>=@maxlength
      cursorpos=0 if cursorpos<0
      @maxlength.times {|i|
         if i==cursorpos
           @blanks[i]=1
         else
           @blanks[i]=0
         end
         @sprites["blank#{i}"].y=[78,82][@blanks[i]]
      }
    end
    pbDoUpdateOverlay
    pbUpdateSpriteHash(@sprites)
  end

  def pbColumnEmpty?(m)
    return false if m>=ROWS-1
    chset=@@Characters[@mode][0]
    return (
       chset[m]==" " &&
       chset[m+((ROWS-1))]==" " &&
       chset[m+((ROWS-1)*2)]==" " &&
       chset[m+((ROWS-1)*3)]==" "
    )
  end

  def wrapmod(x,y)
    result=x%y
    result+=y if result<0
    return result
  end

  def pbMoveCursor
    oldcursor=@cursorpos
    cursordiv=@cursorpos/ROWS
    cursormod=@cursorpos%ROWS
    cursororigin=@cursorpos-cursormod
    if Input.repeat?(Input::LEFT)
      if @cursorpos<0 # Controls
        @cursorpos-=1
        @cursorpos=OK if @cursorpos<MODE1
      else
        begin
          cursormod=wrapmod((cursormod-1),ROWS)
          @cursorpos=cursororigin+cursormod
        end while pbColumnEmpty?(cursormod)
      end
    elsif Input.repeat?(Input::RIGHT)
      if @cursorpos<0 # Controls
        @cursorpos+=1
        @cursorpos=MODE1 if @cursorpos>OK
      else
        begin
          cursormod=wrapmod((cursormod+1),ROWS)
          @cursorpos=cursororigin+cursormod
        end while pbColumnEmpty?(cursormod)
      end
    elsif Input.repeat?(Input::UP)
      if @cursorpos<0 # Controls
        case @cursorpos
        when MODE1
          @cursorpos=ROWS*(COLUMNS-1)
        when MODE2
          @cursorpos=ROWS*(COLUMNS-1)+2
        when MODE3
          @cursorpos=ROWS*(COLUMNS-1)+4
        when BACK
          @cursorpos=ROWS*(COLUMNS-1)+8
        when OK
          @cursorpos=ROWS*(COLUMNS-1)+11
        end
      elsif @cursorpos<ROWS # Top row of letters
        case @cursorpos
        when 0,1
          @cursorpos=MODE1
        when 2,3
          @cursorpos=MODE2
        when 4,5,6
          @cursorpos=MODE3
        when 7,8,9,10
          @cursorpos=BACK
        when 11,12
          @cursorpos=OK
        end
      else
        cursordiv=wrapmod((cursordiv-1),COLUMNS)
        @cursorpos=(cursordiv*ROWS)+cursormod
      end
    elsif Input.repeat?(Input::DOWN)
      if @cursorpos<0 # Controls
        case @cursorpos
        when MODE1
          @cursorpos=0
        when MODE2
          @cursorpos=2
        when MODE3
          @cursorpos=4
        when BACK
          @cursorpos=8
        when OK
          @cursorpos=11
        end
      elsif @cursorpos>=ROWS*(COLUMNS-1) # Bottom row of letters
        case @cursorpos
        when ROWS*(COLUMNS-1),ROWS*(COLUMNS-1)+1
          @cursorpos=MODE1
        when ROWS*(COLUMNS-1)+2,ROWS*(COLUMNS-1)+3
          @cursorpos=MODE2
        when ROWS*(COLUMNS-1)+4,ROWS*(COLUMNS-1)+5,ROWS*(COLUMNS-1)+6
          @cursorpos=MODE3
        when ROWS*(COLUMNS-1)+7,ROWS*(COLUMNS-1)+8,ROWS*(COLUMNS-1)+9,ROWS*(COLUMNS-1)+10
          @cursorpos=BACK
        when ROWS*(COLUMNS-1)+11,ROWS*(COLUMNS-1)+12
          @cursorpos=OK
        end
      else
        cursordiv=wrapmod((cursordiv+1),COLUMNS)
        @cursorpos=(cursordiv*ROWS)+cursormod
      end
    end
    if @cursorpos!=oldcursor # Cursor position changed
      @sprites["cursor"].setCursorPos(@cursorpos)
      pbPlayCursorSE()
      return true
    else
      return false
    end
  end

  def pbEntry
    ret=""
    loop do
      Graphics.update
      Input.update
      pbUpdate
      next if pbMoveCursor
      if Input.trigger?(Input::B)
        @helper.delete
        pbPlayCancelSE()
        pbUpdateOverlay
      elsif Input.trigger?(Input::C)
        if @cursorpos==BACK # Backspace
          @helper.delete
          pbPlayCancelSE()
          pbUpdateOverlay
        elsif @cursorpos==OK # Done
          pbSEPlay("GUI naming confirm")
          if @helper.length>=@minlength
            ret=@helper.text
            break
          end
        elsif @cursorpos==MODE1
          pbChangeTab(0) if @mode!=0
        elsif @cursorpos==MODE2
          pbChangeTab(1) if @mode!=1
        elsif @cursorpos==MODE3
          pbChangeTab(2) if @mode!=2
        else
          cursormod=@cursorpos%ROWS
          cursordiv=@cursorpos/ROWS
          charpos=cursordiv*(ROWS)+cursormod
          chset=@@Characters[@mode][0]
          if @helper.length>=@maxlength
            @helper.delete
          end
          @helper.insert(chset[charpos])
          pbPlayCursorSE()
          if @helper.length>=@maxlength
            @cursorpos=OK
            @sprites["cursor"].setCursorPos(@cursorpos)
          end
          pbUpdateOverlay
        end
      elsif Input.trigger?(Input::A)
        @cursorpos=OK
        @sprites["cursor"].setCursorPos(@cursorpos)
      elsif Input.trigger?(Input::F5)
        pbChangeTab
      end
    end
    Input.update
    return ret
 end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    for bitmap in @bitmaps
      bitmap.dispose if bitmap
    end
    @bitmaps.clear
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonEntry
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(helptext,minlength,maxlength,initialText,mode=-1,pokemon=nil)
    @scene.pbStartScene(helptext,minlength,maxlength,initialText,mode,pokemon)
    ret=@scene.pbEntry
    @scene.pbEndScene
    if ret.to_s =~ /\A\s*\z/
      ret = pokemon ? pokemon.name : initialText
    end
    return ret
  end
end



def pbEnterText(helptext,minlength,maxlength,initialText="",mode=0,pokemon=nil,nofadeout=false)
  ret=""
  if USEKEYBOARDTEXTENTRY
    pbFadeOutIn(99999,nofadeout){
       sscene=PokemonEntryScene.new
       sscreen=PokemonEntry.new(sscene)
       ret=sscreen.pbStartScreen(helptext,minlength,maxlength,initialText,mode,pokemon)
    }
  else
    pbFadeOutIn(99999,nofadeout){
       sscene=PokemonEntryScene2.new
       sscreen=PokemonEntry.new(sscene)
       ret=sscreen.pbStartScreen(helptext,minlength,maxlength,initialText,mode,pokemon)
    }
  end
  return ret
end

def pbEnterPlayerName(helptext,minlength,maxlength,initialText="",nofadeout=false)
  return pbEnterText(helptext,minlength,maxlength,initialText,1,nil,nofadeout)
end

def pbEnterPokemonName(helptext,minlength,maxlength,initialText="",pokemon=nil,nofadeout=false)
  return pbEnterText(helptext,minlength,maxlength,initialText,2,pokemon,nofadeout)
end

def pbEnterBoxName(helptext,minlength,maxlength,initialText="",nofadeout=false)
  return pbEnterText(helptext,minlength,maxlength,initialText,3,nil,nofadeout)
end

def pbEnterNPCName(helptext,minlength,maxlength,initialText="",id=0,nofadeout=false)
  return pbEnterText(helptext,minlength,maxlength,initialText,4,id,nofadeout)
end



class Interpreter
  def command_303
    if $Trainer
      $Trainer.name=pbEnterPlayerName(_INTL("Your name?"),1,@parameters[1],$Trainer.name)
      return true
    end
    if $game_actors && $data_actors && $data_actors[@parameters[0]] != nil
      # Set battle abort flag
      $game_temp.battle_abort = true
      ret=""
      pbFadeOutIn(99999){
         sscene=PokemonEntryScene.new
         sscreen=PokemonEntry.new(sscene)
         $game_actors[@parameters[0]].name=sscreen.pbStartScreen(
            _INTL("Enter {1}'s name.",$game_actors[@parameters[0]].name),
            1,@parameters[1],$game_actors[@parameters[0]].name)
      }
    end
    return true
  end
end



class Game_Interpreter
  def command_303
    if $Trainer
       $Trainer.name=pbEnterPlayerName(_INTL("Your name?"),1,
          @params[1],$Trainer.name)
      return true
    end
    if $game_actors && $data_actors && $data_actors[@params[0]] != nil
      # Set battle abort flag
      ret=""
      pbFadeOutIn(99999){
         sscene=PokemonEntryScene.new
         sscreen=PokemonEntry.new(sscene)
         $game_actors[@params[0]].name=sscreen.pbStartScreen(
            _INTL("Enter {1}'s name.",$game_actors[@params[0]].name),
            1,@params[1],$game_actors[@params[0]].name)
      }
    end
    return true
  end
end