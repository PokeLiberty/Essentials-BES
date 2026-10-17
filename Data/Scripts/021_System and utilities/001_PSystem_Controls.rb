def pbSameThread(wnd)
  return false if wnd==0
  $pbThreadFuncs ||= [
    Win32API.new('kernel32','GetCurrentThreadId', '%w()','l'),
    Win32API.new('user32','GetWindowThreadProcessId', '%w(l p)','l')
  ]
  processid=[0].pack('l')
  threadid=$pbThreadFuncs[0].call
  wndthreadid=$pbThreadFuncs[1].call(wnd,processid)
  return (wndthreadid==threadid)
end


module Input

  DOWN  = 2
  LEFT  = 4
  RIGHT = 6
  UP    = 8
  A     = 11
  B     = 12
  C     = 13
  X     = 14
  Y     = 15
  Z     = 16
  L     = 17
  R     = 18

  #Teclas funcionales con MKXP, pero no remapeables
  SHIFT = 21
  CTRL  = 22
  ALT   = 23
  F5    = $MKXP ? :F5 : 25
  F6    = $MKXP ? :F6 : 26
  F7    = $MKXP ? :F7 : 27
  F8    = $MKXP ? :F8 : 28
  F9    = $MKXP ? :F9 : 29

  #Teclas no remapeables, deben usar un formato distinto para funcionar con $MKXP
  F3    = $MKXP ? :F3 : 30
  F4    = $MKXP ? :F4 : 31
  
  F12    = $MKXP ? :F12 : 32
  
  A2     = $MKXP ? :A  : 33
  B2     = $MKXP ? :B  : 34
  C2     = $MKXP ? :C  : 35
  X2     = $MKXP ? :X  : 36
  Y2     = $MKXP ? :Y  : 37
  Z2     = $MKXP ? :Z  : 38
  L2     = $MKXP ? :L  : 39
  R2     = $MKXP ? :R  : 40
  
  W      = $MKXP ? :W  : 41
  S      = $MKXP ? :S  : 42
  D      = $MKXP ? :D  : 43
  
  Q      = $MKXP ? :Q  : 44
  E      = $MKXP ? :E  : 45
  T      = $MKXP ? :T  : 46
  U      = $MKXP ? :U  : 47
  I      = $MKXP ? :I  : 48
  O      = $MKXP ? :O  : 49
  P      = $MKXP ? :P  : 50
  F      = $MKXP ? :F  : 51
  G      = $MKXP ? :G  : 52
  H      = $MKXP ? :H  : 53
  J      = $MKXP ? :J  : 54
  K      = $MKXP ? :K  : 55
  V      = $MKXP ? :V  : 56
  N      = $MKXP ? :N  : 57
  M      = $MKXP ? :M  : 58

  #BES-T COMPATIBILIDAD con otros Essentials
  USE      = C
  BACK     = B
  ACTION   = A
  JUMPUP   = L
  JUMPDOWN = R
  SPECIAL  = Z
  AUX1     = X
  AUX2     = Y
  
  ITEMKEYS      = [Input::F5,Input::F4,Input::F3]
  ITEMKEYSNAMES = [_INTL("F5"),_INTL("F4"),_INTL("F3")]
  
  LeftMouseKey  = 1
  RightMouseKey = 2
  
  unless $MKXP #BES-T soporte para mando nativo y el F1
  
    # GetAsyncKeyState or GetKeyState will work here
    @GetKeyState=Win32API.new("user32", "GetAsyncKeyState", "i", "i")
    @GetForegroundWindow=Win32API.new("user32", "GetForegroundWindow", "", "i")
    # Returns whether a key is being pressed
  
    def self.getstate(key)
      return (@GetKeyState.call(key)&0x8000)>0
    end
  
    def self.updateKeyState(i)
      gfw=@gfw
      if !@stateUpdated[i]
        newstate=self.getstate(i) && gfw
        @keystate[i] = 0 if !@keystate[i]
        @triggerstate[i]=(newstate&&@keystate[i]==0)
        @releasestate[i]=(!newstate&&@keystate[i]>0)
        @keystate[i] = (newstate) ? @keystate[i]+1 : 0
        @stateUpdated[i]=true
      end
    end
  
    def self.update
      @gfw=pbSameThread(@GetForegroundWindow.call())
      if @keystate
        for i in 0...256
          # just noting that the state should be updated
          # instead of thunking to Win32 256 times
          @stateUpdated[i]=false
          # If there is a repeat count, update anyway
          # (will normally apply only to a very few keys)
          updateKeyState(i) if !@keystate[i] || @keystate[i]>0
        end    
      else
        @stateUpdated=[]
        @keystate=[]
        @triggerstate=[]
        @releasestate=[]
        for i in 0...256
          @stateUpdated[i]=true
          @keystate[i]     = (self.getstate(i)) ? 1 : 0
          @triggerstate[i]=false
          @releasestate[i]=false
        end
      end
    end
  
    def self.buttonToKey(button)
      case button
      when Input::DOWN;                return [0x28] # Down
      when Input::LEFT;                return [0x25] # Left
      when Input::RIGHT;               return [0x27] # Right
      when Input::UP;                  return [0x26] # Up
      when Input::A, Input::ACTION;    return [0x5A,0x10] # Z, Shift
      when Input::B, Input::BACK;      return [0x58,0x1B] # X, ESC 
      when Input::C, Input::USE;       return [0x43,0x0D,0x20] # C, ENTER, Space
      when Input::X, Input::AUX1;      return [0x41] # A
      when Input::Y, Input::AUX2;      return [0x53] # S
      when Input::Z, Input::SPECIAL;   return [0x44] # D
      when Input::L, Input::JUMPUP ;   return [0x51,0x21] # Q, Page Up
      when Input::R, Input::JUMPDOWN ; return [0x57,0x22] # W, Page Down
      when Input::SHIFT;               return [0x10] # Shift
      when Input::CTRL;                return [0x11] # Ctrl
      when Input::ALT;                 return [0x12] # Alt
      when Input::F3;                  return [0x72] # F3
      when Input::F4;                  return [0x73] # F4
      when Input::F5;                  return [0x74] # F5
      when Input::F6;                  return [0x75] # F6
      when Input::F7;                  return [0x76] # F7
      when Input::F8;                  return [0x77] # F8
      when Input::F9;                  return [0x78] # F9
      when Input::F12;                 return [0x7B] # F12

      when Input::B2;                  return [0x42] # B
      when Input::P;                   return [0x50] # P
      when Input::I;                   return [0x49] # I
      when Input::J;                   return [0x4A] # J
      when Input::F;                   return [0x46] # F
      when Input::M;                   return [0x4D] # M
      when Input::Y2;                  return [0x59] # Y
      #when Input::L2
      #when Input::C2
      #when Input::X2
      #when Input::Z2
      #when Input::R2
      #when Input::Q
      #when Input::E
      #when Input::U
      #when Input::O
      #when Input::P
      #when Input::G
      #when Input::H
      #when Input::K
      #when Input::V
      #when Input::N
      end
      return []
    end
  
    def self.dir4
      button=0
      repeatcount=0
      return 0 if self.press?(Input::DOWN) && self.press?(Input::UP)
      return 0 if self.press?(Input::LEFT) && self.press?(Input::RIGHT)
      for b in [Input::DOWN,Input::LEFT,Input::RIGHT,Input::UP]
        rc=self.count(b)
        if rc>0 && (repeatcount==0 || rc<repeatcount)
            button=b
            repeatcount=rc
        end
      end
      return button
    end
  
    def self.dir8
      buttons=[]
      for b in [Input::DOWN,Input::LEFT,Input::RIGHT,Input::UP]
        rc=self.count(b)
        buttons.push([b,rc]) if rc>0
      end
      if buttons.length==0
        return 0
      elsif buttons.length==1
        return buttons[0][0]
      elsif buttons.length==2
        # since buttons sorted by button, no need to sort here
        return 0 if (buttons[0][0]==Input::DOWN && buttons[1][0]==Input::UP)
        return 0 if (buttons[0][0]==Input::LEFT && buttons[1][0]==Input::RIGHT)
      end
      buttons.sort!{|a,b| a[1]<=>b[1]}
      updown=0
      leftright=0
      for b in buttons
        updown=b[0] if updown==0 && (b[0]==Input::UP || b[0]==Input::DOWN)
        leftright=b[0] if leftright==0 && (b[0]==Input::LEFT || b[0]==Input::RIGHT)
      end
      if updown==Input::DOWN
        return 1 if leftright==Input::LEFT
        return 3 if leftright==Input::RIGHT
        return 2
      elsif updown==Input::UP
        return 7 if leftright==Input::LEFT
        return 9 if leftright==Input::RIGHT
        return 8
      else
        return 4 if leftright==Input::LEFT
        return 6 if leftright==Input::RIGHT
        return 0
      end
    end
  
    def self.count(button)
      for btn in self.buttonToKey(button)
        c=self.repeatcount(btn)
        return c if c>0
      end
      return 0
    end
  
    def self.release?(button)
      rc=0
      for btn in self.buttonToKey(button)
        c=self.repeatcount(btn)
        return false if c>0
        rc+=1 if self.releaseex?(btn)
      end
      return rc>0
    end
  
    def self.trigger?(button)
      return self.buttonToKey(button).any? {|item| self.triggerex?(item) }
    end
  
    def self.repeat?(button)
      return self.buttonToKey(button).any? {|item| self.repeatex?(item) }
    end
  
    def self.press?(button)
      return self.count(button)>0
    end
  
    def self.repeatex?(key)
      return false if !@keystate
      updateKeyState(key)
      return @keystate[key]==1 || (@keystate[key]>20 && (@keystate[key]&1)==0)
    end
  
    def self.releaseex?(key)
      return false if !@releasestate
      updateKeyState(key)
      return @releasestate[key]
    end
  
    def self.triggerex?(key)
      return false if !@triggerstate
      updateKeyState(key)
      return @triggerstate[key]
    end
  
    def self.repeatcount(key)
      return 0 if !@keystate
      updateKeyState(key)
      return @keystate[key]
    end
  
    def self.pressex?(key)
      return self.repeatcount(key)>0
    end
  end #MKXP
end

# Requires Win32API
module Mouse
  gsm = Win32API.new('user32', 'GetSystemMetrics', 'i', 'i')
  @GetCursorPos = Win32API.new('user32', 'GetCursorPos', 'p', 'i')
  @SetCapture = Win32API.new('user32', 'SetCapture', 'p', 'i')
  @ReleaseCapture = Win32API.new('user32', 'ReleaseCapture', '', 'i')
  module_function
  def getMouseGlobalPos
    pos = [0, 0].pack('ll')
    return (@GetCursorPos.call(pos)!=0) ? pos.unpack('ll') : [nil,nil]
  end

  def screen_to_client(x, y)
    return nil unless x and y
    screenToClient = Win32API.new('user32', 'ScreenToClient', %w(l p), 'i')
    pos = [x, y].pack('ll')
    return pos.unpack('ll') if screenToClient.call(Win32API.pbFindRgssWindow,pos)!=0
    return nil
  end

  def setCapture
    @SetCapture.call(Win32API.pbFindRgssWindow)
  end

  def releaseCapture
    @ReleaseCapture.call
  end

  # Returns the position of the mouse relative to the game window.
  def getMousePos(catch_anywhere = false)
    resizeFactor=($ResizeFactor) ? $ResizeFactor : 1
    x, y = screen_to_client(*getMouseGlobalPos)
    return nil unless x and y
    width, height = Win32API.client_size
    if catch_anywhere or (x >= 0 and y >= 0 and x < width and y < height)
      return (x/resizeFactor).to_i, (y/resizeFactor).to_i
    end
    return nil
  end

  def del
    return if @oldcursor == nil
    @SetClassLong.call(Win32API.pbFindRgssWindow,-12, @oldcursor)
    @oldcursor = nil
  end
end

#===============================================================================
# MKXP: las teclas con nombre (símbolos, p. ej. :F5) se consultan con
# triggerex?/pressex?/repeatex?. Varios scripts del proyecto llaman directamente
# a Input.trigger?(Input::F5), así que aquí se redirige automáticamente.
# Los botones numéricos (Input::C, Input::B...) siguen usando el método nativo.
#===============================================================================
if $MKXP && Input.respond_to?(:triggerex?)
  class << Input
    if Input.respond_to?(:trigger?)
      alias_method :pb_native_trigger?, :trigger?
      def trigger?(button)
        return triggerex?(button) if button.is_a?(Symbol)
        return pb_native_trigger?(button)
      end
    end
    if Input.respond_to?(:press?) && Input.respond_to?(:pressex?)
      alias_method :pb_native_press?, :press?
      def press?(button)
        return pressex?(button) if button.is_a?(Symbol)
        return pb_native_press?(button)
      end
    end
    if Input.respond_to?(:repeat?) && Input.respond_to?(:repeatex?)
      alias_method :pb_native_repeat?, :repeat?
      def repeat?(button)
        return repeatex?(button) if button.is_a?(Symbol)
        return pb_native_repeat?(button)
      end
    end
  end
end