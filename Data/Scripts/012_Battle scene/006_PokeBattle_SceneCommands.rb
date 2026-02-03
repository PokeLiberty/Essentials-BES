#===============================================================================
# Command menu (Fight/Pokémon/Bag/Run)
#===============================================================================
class CommandMenuDisplay
    attr_accessor :mode
  
    def initialize(viewport=nil)
      @display=nil
      if PokeBattle_SceneConstants::USECOMMANDBOX
        @display=IconSprite.new(0,Graphics.height-96,viewport)
        @display.setBitmap("Graphics/#{BATTLE_ROUTE}/battleCommand")
      end
      @window=Window_CommandPokemon.newWithSize([],
         Graphics.width-240,Graphics.height-96,240,96,viewport)
      @window.columns=2
      @window.columnSpacing=4
      @window.ignore_input=true
      @msgbox=Window_UnformattedTextPokemon.newWithSize(
         "",16,Graphics.height-96+2,220,96,viewport)
      @msgbox.baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
      @msgbox.shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
      @msgbox.windowskin=nil
      @title=""
      @buttons=nil
      # BES-T Info combate
      @statinfo=IconSprite.new(0,0,viewport)
      @statinfo.setBitmap("Graphics/Pictures/Battle/infoStats") if !pbInSafari?
      @statinfo.y=PokeBattle_SceneConstants::INFOBUTTON_Y
      @statinfo.x=PokeBattle_SceneConstants::INFOBUTTON_X
      
      if PokeBattle_SceneConstants::USECOMMANDBOX
        @window.opacity=0
        @window.x=Graphics.width
        @buttons=CommandMenuButtons.new(self.index,self.mode,viewport)
      end
    end
  
    def x; @window.x; end
    def x=(value)
      @window.x=value
      @msgbox.x=value
      @display.x=value if @display
      @buttons.x=value if @buttons
      @statinfo.x=value if @statinfo # BES-T
    end
  
    def y; @window.y; end
    def y=(value)
      @window.y=value
      @msgbox.y=value
      @display.y=value if @display
      @buttons.y=value if @buttons
      @statinfo.y=value if @statinfo # BES-T
    end
  
    def z; @window.z; end
    def z=(value)
      @window.z=value
      @msgbox.z=value
      @display.z=value if @display
      @buttons.z=value+1 if @buttons
      @statinfo.z=value+2 if @statinfo # BES-T
    end
  
    def ox; @window.ox; end
    def ox=(value)
      @window.ox=value
      @msgbox.ox=value
      @display.ox=value if @display
      @buttons.ox=value if @buttons
      @statinfo.ox=value if @statinfo # BES-T
    end
  
    def oy; @window.oy; end
    def oy=(value)
      @window.oy=value
      @msgbox.oy=value
      @display.oy=value if @display
      @buttons.oy=value if @buttons
      @statinfo.oy=value if @statinfo # BES-T
    end
  
    def visible; @window.visible; end
    def visible=(value)
      @window.visible=value
      @msgbox.visible=value
      @display.visible=value if @display
      @buttons.visible=value if @buttons
      @statinfo.visible=value if @statinfo # BES-T
    end
  
    def color; @window.color; end
    def color=(value)
      @window.color=value
      @msgbox.color=value
      @display.color=value if @display
      @buttons.color=value if @buttons
      @statinfo.color=value if @statinfo # BES-T
    end
  
    def disposed?
      return @msgbox.disposed? || @window.disposed?
    end
  
    def dispose
      return if disposed?
      @msgbox.dispose
      @window.dispose
      @display.dispose if @display
      @buttons.dispose if @buttons
      @statinfo.dispose if @statinfo # BES-T
    end
  
    def index; @window.index; end
    def index=(value); @window.index=value; end
  
    def setTexts(value)
      @msgbox.text=value[0]
      commands=[]
      for i in 1..4
        commands.push(value[i]) if value[i] && value[i]!=nil
      end
      @window.commands=commands
    end
  
    def refresh
      @msgbox.refresh
      @window.refresh
      @buttons.refresh(self.index,self.mode) if @buttons
      @statinfo.refresh if @statinfo # BES-T
    end
  
    def update
      @msgbox.update
      @window.update
      @display.update if @display
      @buttons.update(self.index,self.mode) if @buttons
      @statinfo.update if @statinfo # BES-T
    end
  end
  
  
  
  class CommandMenuButtons < BitmapSprite
    def initialize(index=0,mode=0,viewport=nil)
      super(260,96,viewport)
      self.x=Graphics.width-260
      self.y=Graphics.height-96
      @mode=mode
      @buttonbitmap=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/battleCommandButtons"))
      refresh(index,mode)
      
      pbSetSystemFont(self.bitmap)
      @commandtext = [
        _INTL("Luchar"),  #0
        _INTL("Pokémon"), #1
        _INTL("Bolsa"),   #2
        _INTL("Huir"),    #3
        _INTL("Apoyo"),   #4
        _INTL("Ball"),    #5
        _INTL("Roca"),    #6
        _INTL("Cebo"),    #7
        _INTL("Ball"),    #8
      ]
    end
  
    def dispose
      @buttonbitmap.dispose
      super
    end
  
    def update(index=0,mode=0)
      refresh(index,mode)
    end
  
    def refresh(index,mode=0)
      self.bitmap.clear
      @mode=mode
      cmdarray=[0,2,1,3]
      textpos=[]
      case @mode
      when 1
        cmdarray=[0,2,1,4] # Use "Call"
      when 2
        cmdarray=[5,7,6,3] # Safari Zone battle
      when 3
        cmdarray=[0,8,1,3] # Bug Catching Contest
      end
      buttonWidth = 130
      buttonHeight = 46
      for i in 0...4
        next if i==index
        x=((i%2)==0) ? 0 : buttonWidth
        y=((i/2)==0) ? 6 : buttonHeight+2
        self.bitmap.blt(x,y,@buttonbitmap.bitmap,Rect.new(0,cmdarray[i]*46,buttonWidth,buttonHeight))
        
        if PokeBattle_SceneConstants::CMD_BUTTON_TEXT
          cmdText = @commandtext[cmdarray[i]].upcase if @commandtext
          basecolor   = PokeBattle_SceneConstants::COLOREDTYPE ? @buttonbitmap.bitmap.get_pixel(10,cmdarray[i]*buttonHeight+32) : PokeBattle_SceneConstants::MENUBASECOLOR
          shadowcolor = PokeBattle_SceneConstants::MENUSHADOWCOLOR
          textpos.push([_INTL("{1}",cmdText),x+64,y+8,2,
                      basecolor,shadowcolor,PokeBattle_SceneConstants::CMD_OUTLINE])
        end
      end
      for i in 0...4
        next if i!=index
        x=((i%2)==0) ? 0 : buttonWidth
        y=((i/2)==0) ? 6 : buttonHeight+2
        self.bitmap.blt(x,y,@buttonbitmap.bitmap,Rect.new(buttonWidth,cmdarray[i]*buttonHeight,buttonWidth,buttonHeight))
        
        if PokeBattle_SceneConstants::CMD_BUTTON_TEXT
          cmdText = @commandtext[cmdarray[i]].upcase if @commandtext
          basecolor   = PokeBattle_SceneConstants::COLOREDTYPE ? @buttonbitmap.bitmap.get_pixel(10,cmdarray[i]*buttonHeight+32) : PokeBattle_SceneConstants::MENUBASECOLOR
          shadowcolor = PokeBattle_SceneConstants::MENUSHADOWCOLORACTIVE
          textpos.push([_INTL("{1}",cmdText),x+64,y+8,2,
                      basecolor,shadowcolor,PokeBattle_SceneConstants::CMD_OUTLINE])
        end
      end
      pbDrawTextPositions(self.bitmap,textpos)
    end
  end
  
  
  
  #===============================================================================
  # Fight menu (choose a move)
  #===============================================================================
  class FightMenuDisplay
    attr_reader :battler
    attr_reader :index
    attr_accessor :megaButton
    attr_accessor :ultraButton
    attr_accessor :zButton
    attr_accessor :dynaButton
    attr_accessor :teraButton
  
    def initialize(battler,viewport=nil)
      @display=nil
      if PokeBattle_SceneConstants::USEFIGHTBOX
        @display=IconSprite.new(0,Graphics.height-96,viewport)
        @display.setBitmap("Graphics/#{BATTLE_ROUTE}/battleFight")
      end
      @window=Window_CommandPokemon.newWithSize([],0,Graphics.height-96,320,96,viewport)
      @window.columns=2
      @window.columnSpacing=4
      @window.ignore_input=true
      pbSetNarrowFont(@window.contents)
      @info=Window_AdvancedTextPokemon.newWithSize(
         "",320,Graphics.height-96,Graphics.width-320,96,viewport)
      pbSetNarrowFont(@info.contents)
      @ctag=shadowctag(PokeBattle_SceneConstants::MENUBASECOLOR,
                       PokeBattle_SceneConstants::MENUSHADOWCOLOR)
      @buttons=nil
      @battler=battler
      @index=0
      @megaButton=0 # 0=don't show, 1=show, 2=pressed
      @ultraButton=0  # 0=don't show, 1=show, 2=pressed
      @zButton=0    # 0=don't show, 1=show, 2=pressed
      @dynaButton=0 # 0=don't show, 1=show, 2=pressed
      @teraButton=0 # 0=don't show, 1=show, 2=pressed
      if PokeBattle_SceneConstants::USEFIGHTBOX
        @window.opacity=0
        @window.x=Graphics.width
        @info.opacity=0
        @info.x=Graphics.width+Graphics.width-96
        @buttons=FightMenuButtons.new(self.index,nil,viewport)
      end
      refresh
    end
  
    def x; @window.x; end
    def x=(value)
      @window.x=value
      @info.x=value
      @display.x=value if @display
      @buttons.x=value if @buttons
    end
  
    def y; @window.y; end
    def y=(value)
      @window.y=value
      @info.y=value
      @display.y=value if @display
      @buttons.y=value if @buttons
    end
  
    def z; @window.z; end
    def z=(value)
      @window.z=value
      @info.z=value
      @display.z=value if @display
      @buttons.z=value+1 if @buttons
    end
  
    def ox; @window.ox; end
    def ox=(value)
      @window.ox=value
      @info.ox=value
      @display.ox=value if @display
      @buttons.ox=value if @buttons
    end
  
    def oy; @window.oy; end
    def oy=(value)
      @window.oy=value
      @info.oy=value
      @display.oy=value if @display
      @buttons.oy=value if @buttons
    end
  
    def visible; @window.visible; end
    def visible=(value)
      @window.visible=value
      @info.visible=value
      @display.visible=value if @display
      @buttons.visible=value if @buttons
    end
  
    def color; @window.color; end
    def color=(value)
      @window.color=value
      @info.color=value
      @display.color=value if @display
      @buttons.color=value if @buttons
    end
  
    def disposed?
      return @info.disposed? || @window.disposed?
    end
  
    def dispose
      return if disposed?
      @info.dispose
      @display.dispose if @display
      @buttons.dispose if @buttons
      @window.dispose
    end
  
    def battler=(value)
      @battler=value
      refresh
    end
  
    def setIndex(value)
      if @battler && @battler.moves[value].id!=0
        @index=value
        @window.index=value
        refresh
        return true
      end
      return false
    end
  
    def refresh
      @buttons.battle=@battler.battle if @battler
      @buttons.pokemon=@battler.pokemon if @battler
      return if !@battler
      commands=[]
      for i in 0...4
        break if @battler.moves[i].id==0
        commands.push(@battler.moves[i].name)
      end
      @window.commands=commands
      selmove=@battler.moves[@index]
      movetype=PBTypes.getName(selmove.type)
      if selmove.totalpp==0
        @info.text=_ISPRINTF("{1:s}PP: ---<br>TIPO/{2:s}",@ctag,movetype)
      else
        @info.text=_ISPRINTF("{1:s}PP: {2: 2d}/{3: 2d}<br>TIPO/{4:s}",
           @ctag,selmove.pp,selmove.totalpp,movetype)
      end
      @buttons.refresh(self.index,@battler ? @battler.moves : nil,@megaButton,@ultraButton,@zButton,@dynaButton,@teraButton) if @buttons
    end
  
    def update
      @info.update
      @window.update
      @display.update if @display
      if @buttons
        moves=@battler ? @battler.moves : nil
        @buttons.update(self.index,moves,@megaButton,@ultraButton,@zButton,@dynaButton,@teraButton)
      end
    end
  end
  
  
  
  class FightMenuButtons < BitmapSprite
    UPPERGAP=46
    attr_writer :pokemon
    attr_writer :battle
  
    def initialize(index=0,moves=nil,viewport=nil)
      super(Graphics.width,96+UPPERGAP,viewport)
      self.x=0
      self.y=Graphics.height-96-UPPERGAP
      pbSetNarrowFont(self.bitmap)
      @buttonbitmap=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battleFightButtons")
      @typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
      @megaevobitmap=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/battleMegaEvo"))
      @ultraburstbitmap=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/cursor_ultra"))
      @zmovebitmap=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/battleZMove"))
      @dynamaxbitmap=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/battleDynamax"))
      @terastalbitmap=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/battleTerastal"))
      @pokemon
      refresh(index,moves,0,0,0,0,0)
    end
  
    def dispose
      @buttonbitmap.dispose
      @typebitmap.dispose
      @megaevobitmap.dispose
      @ultraburstbitmap.dispose
      @terastalbitmap.dispose
      super
    end
  
    def update(index=0,moves=nil,megaButton=0,ultraButton=0,zButton=0,dynaButton=0,teraButton=0)
      refresh(index,moves,megaButton,ultraButton,zButton,dynaButton,teraButton)
    end
  
    def getMoveName(move)
      movename = move.name
      if PokeBattle_SceneConstants::SHORTEN_MOVES && movename.length > 16
        # Elimina la palabra "de" y los espacios extra
        movename = movename.gsub(" de ", " ")
        if movename.length > 16 #Corta de nuevo si sigue siendo muy grande
          movename = movename[0..12] + "..."
        end
        return movename
      end
      return movename
    end
    
    def refresh(index,moves,megaButton,ultraButton,zButton,dynaButton,teraButton)
      return if !moves
      self.bitmap.clear
      moveboxes=_INTL("Graphics/#{BATTLE_ROUTE}/battleFightButtons")
      textpos=[]
      buttonWidth = 192
      buttonHeight = 46
      for i in 0...4
        next if i==index
        next if moves[i].id==0
        x=((i%2)==0) ? 4 : buttonWidth 
        y=((i/2)==0) ? 6 : buttonHeight+2
        y+=UPPERGAP
        moveType = getMoveType(moves[i])
        movename = getMoveName(moves[i])
        self.bitmap.blt(x,y,@buttonbitmap.bitmap,Rect.new(0,moveType*buttonHeight, buttonWidth ,buttonHeight))
        basecolor = PokeBattle_SceneConstants::COLOREDTYPE ? @buttonbitmap.bitmap.get_pixel(10,moveType*buttonHeight+34) : PokeBattle_SceneConstants::MENUBASECOLOR
        textpos.push([_INTL("{1}",movename),x+96,y+8,2,
                      basecolor,PokeBattle_SceneConstants::MENUSHADOWCOLOR,
                      PokeBattle_SceneConstants::CMD_OUTLINE])
      end
      ppcolors=[
         PokeBattle_SceneConstants::PPTEXTBASECOLOR,PokeBattle_SceneConstants::PPTEXTSHADOWCOLOR,
         PokeBattle_SceneConstants::PPTEXTBASECOLOR,PokeBattle_SceneConstants::PPTEXTSHADOWCOLOR,
         PokeBattle_SceneConstants::PPTEXTBASECOLORYELLOW,PokeBattle_SceneConstants::PPTEXTSHADOWCOLORYELLOW,
         PokeBattle_SceneConstants::PPTEXTBASECOLORORANGE,PokeBattle_SceneConstants::PPTEXTSHADOWCOLORORANGE,
         PokeBattle_SceneConstants::PPTEXTBASECOLORRED,PokeBattle_SceneConstants::PPTEXTSHADOWCOLORRED
      ]
      for i in 0...4
        next if i!=index
        next if moves[i].id==0
        x=((i%2)==0) ? 4 : buttonWidth 
        y=((i/2)==0) ? 6 : buttonHeight+2
        y+=UPPERGAP
        moveType = getMoveType(moves[i])
        movename = getMoveName(moves[i])
        
        self.bitmap.blt(x,y,@buttonbitmap.bitmap,Rect.new(buttonWidth,moveType*buttonHeight,buttonWidth,buttonHeight))
        self.bitmap.blt(416,20+UPPERGAP,@typebitmap.bitmap,Rect.new(0,moveType*28,64,28))
        basecolor = PokeBattle_SceneConstants::COLOREDTYPE ? @buttonbitmap.bitmap.get_pixel(10,moveType*buttonHeight+34) : PokeBattle_SceneConstants::MENUBASECOLOR
        textpos.push([_INTL("{1}",movename),x+96,y+8,2,
                      basecolor,PokeBattle_SceneConstants::MENUSHADOWCOLORACTIVE,
                      PokeBattle_SceneConstants::CMD_OUTLINE])
        if moves[i].totalpp>0
          ppfraction=(4.0*moves[i].pp/moves[i].totalpp).ceil
          textpos.push([_INTL("PP: {1}/{2}",moves[i].pp,moves[i].totalpp),
             448,50+UPPERGAP,2,ppcolors[(4-ppfraction)*2],ppcolors[(4-ppfraction)*2+1]])
        end
      end
      pbDrawTextPositions(self.bitmap,textpos)
      if megaButton>0
        self.bitmap.blt(200,0,@megaevobitmap.bitmap,Rect.new(0,(megaButton-1)*46,96,46))
      elsif dynaButton>0
        self.bitmap.blt(200,0,@dynamaxbitmap.bitmap,Rect.new(0,(dynaButton-1)*46,96,46))
      elsif teraButton>0
        if teraButton==2
          terapos=@pokemon.teratype+1
        else
          terapos=0
        end
        self.bitmap.blt(200,0,@terastalbitmap.bitmap,Rect.new(0,terapos*46,96,46))
      elsif ultraButton>0
        self.bitmap.blt(200,0,@ultraburstbitmap.bitmap,Rect.new(0,(ultraButton-1)*46,96,46))
      elsif zButton>0
        self.bitmap.blt(200,0,@zmovebitmap.bitmap,Rect.new(0,(zButton-1)*46,96,46))
      end
    end
  
    def getMoveType(move)
      case move.id
      when PBMoves::WEATHERBALL
        case @battle.pbWeather
        when PBWeather::SUNNYDAY, PBWeather::HARSHSUN;   return PBTypes::FIRE
        when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN; return PBTypes::WATER
        when PBWeather::SANDSTORM;                       return PBTypes::ROCK
        when PBWeather::HAIL;                            return PBTypes::ICE
        end
      when PBMoves::HIDDENPOWER
        return pbHiddenPower(@pokemon.iv)[0]
      when PBMoves::JUDGMENT, PBMoves::MULTIATTACK
        return @pokemon.type1
      when PBMoves::TECHNOBLAST
        case @pokemon.item
        when PBItems::CHILLDRIVE; return PBTypes::ICE
        when PBItems::BURNDRIVE;  return PBTypes::FIRE
        when PBItems::DOUSEDRIVE; return PBTypes::WATER
        when PBItems::SHOCKDRIVE; return PBTypes::ELECTRIC
        end
      when PBMoves::AURAWHEEL
        return @pokemon.form==0 ? PBTypes::ELECTRIC : PBTypes::DARK
      when PBMoves::TERRAINPULSE
        if @battle.field.effects[PBEffects::ElectricTerrain]>0
          return (getConst(PBTypes,:ELECTRIC))
        elsif @battle.field.effects[PBEffects::MistyTerrain]>0
          return (getConst(PBTypes,:FAIRY))
        elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
          return (getConst(PBTypes,:PSYCHIC))
        elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
          return (getConst(PBTypes,:GRASS))
        end
      when PBMoves::TERABLAST
        return @pokemon.teratype if (@pokemon.isTera? rescue false)
      end
      if @pokemon.ability==PBAbilities::NORMALIZE
        return PBTypes::NORMAL
      end
      if move.type==PBTypes::NORMAL
        if @pokemon.ability==PBAbilities::AERILATE
          return PBTypes::FLYING
        elsif @pokemon.ability==PBAbilities::REFRIGERATE
          return PBTypes::ICE
        elsif @pokemon.ability==PBAbilities::PIXILATE
          return PBTypes::FAIRY
        elsif @pokemon.ability==PBAbilities::GALVANIZE
          return PBTypes::ELECTRIC
        end
      end
      if (@battle.field.effects[PBEffects::IonDeluge] || @battle.field.effects[PBEffects::PlasmaFists]) && isConst?(move.type,PBTypes,:NORMAL)
        return getConst(PBTypes,:ELECTRIC)
      end
      return move.type
    end
  end

class PokeBattle_Scene

  # Use this method to display the list of commands.
  # Return values: 0=Fight, 1=Bag, 2=Pokémon, 3=Run, 4=Call
  def pbCommandMenu(index)
    shadowTrainer=(hasConst?(PBTypes,:SHADOW) && @battle.opponent)
    ret=pbCommandMenuEx(index,[
       _INTL("¿Qué hará {1}?",@battle.battlers[index].name),
       _INTL("Luchar"),
       _INTL("Mochila"),
       _INTL("Pokémon"),
       shadowTrainer ? _INTL("Llamar") : _INTL("Huir")
    ],(shadowTrainer ? 1 : 0))
    ret=4 if ret==3 && shadowTrainer   # Convert "Run" to "Call"
    return ret
  end

  def pbCommandMenuEx(index,texts,mode=0)      # Mode: 0 - regular battle
    pbShowWindow(COMMANDBOX)                   #       1 - Shadow Pokémon battle
    cw=@sprites["commandwindow"]               #       2 - Safari Zone
    cw.setTexts(texts)                         #       3 - Bug Catching Contest
    cw.index=@lastcmd[index]
    cw.mode=mode
    pbSelectBattler(index)
    pbRefresh
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate(cw)
      # Update selected command
      if Input.trigger?(Input::LEFT) && (cw.index&1)==1
        pbPlayCursorSE()
        cw.index-=1
      elsif Input.trigger?(Input::RIGHT) &&  (cw.index&1)==0
        pbPlayCursorSE()
        cw.index+=1
      elsif Input.trigger?(Input::UP) &&  (cw.index&2)==2
        pbPlayCursorSE()
        cw.index-=2
      elsif Input.trigger?(Input::DOWN) &&  (cw.index&2)==0
        pbPlayCursorSE()
        cw.index+=2
      end
      if Input.trigger?(Input::C)   # Confirm choice
        pbPlayDecisionSE()
        ret=cw.index
        @lastcmd[index]=ret
        return ret
      elsif Input.trigger?(Input::B) && index==2 && @lastcmd[0]!=2 # Cancel
        pbPlayDecisionSE()
        return -1
      elsif Input.trigger?(Input::L) && !pbInSafari? #Q
        pbShowBattleInfo(@battle)
      end
    end
  end

# Use this method to display the list of moves for a Pokémon
  def pbFightMenu(index)
    pbShowWindow(FIGHTBOX)
    cw = @sprites["fightwindow"]
    battler=@battle.battlers[index]
    cw.battler=battler
    lastIndex=@lastmove[index]
    if battler.moves[lastIndex].id!=0
      cw.setIndex(lastIndex)
    else
      cw.setIndex(0)
    end
    cw.megaButton=0
    cw.megaButton=1 if @battle.pbCanMegaEvolve?(index)
    cw.ultraButton=0
    cw.ultraButton=1 if @battle.pbCanUltraBurst?(index)
    cw.teraButton=0
    cw.teraButton=1 if @battle.pbCanTeraCristal?(index)
    cw.zButton=0
    cw.zButton=1 if @battle.pbCanZMove?(index)
    # NO FUNCIONAN, DEJADOS PARA MEJOR COMPATIBILIDAD
    # SOLO PARA EL CASO DE QUE UNO QUIERA PONERLOS
    cw.dynaButton=0
    cw.dynaButton=1 if false
    pbSelectBattler(index)
    pbRefresh
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate(cw)
      # Update selected command
      if Input.trigger?(Input::LEFT) && (cw.index&1)==1
        pbPlayCursorSE() if cw.setIndex(cw.index-1)
      elsif Input.trigger?(Input::RIGHT) &&  (cw.index&1)==0
        pbPlayCursorSE() if cw.setIndex(cw.index+1)
      elsif Input.trigger?(Input::UP) &&  (cw.index&2)==2
        pbPlayCursorSE() if cw.setIndex(cw.index-2)
      elsif Input.trigger?(Input::DOWN) &&  (cw.index&2)==0
        pbPlayCursorSE() if cw.setIndex(cw.index+2)
      end
      if Input.trigger?(Input::C)   # Confirm choice
        ret=cw.index
        if cw.zButton==2
          if battler.pbCompatibleZMoveFromIndex?(ret)
            pbPlayDecisionSE()
            @lastmove[index]=ret
            return ret
          else
            @battle.pbDisplay(_INTL("¡{1} no es compatible con {2}!",PBMoves.getName(battler.moves[ret]),PBItems.getName(battler.item)))
            @lastmove[index]=cw.index
            return -1
          end
        else
        pbPlayDecisionSE()
        @lastmove[index]=ret
        return ret
        end
      elsif Input.trigger?(Input::A)   # Use Mega Evolution
        if @battle.pbCanMegaEvolve?(index) && !pbIsZCrystal?(battler.item)
          @battle.pbRegisterMegaEvolution(index)
          cw.megaButton=2
          pbPlayDecisionSE()
        elsif @battle.pbCanUltraBurst?(index)  # Use Ultra Burst
          @battle.pbRegisterUltraBurst(index)
          cw.ultraButton=2
          pbPlayDecisionSE()
        elsif @battle.pbCanTeraCristal?(index)
          @battle.pbRegisterTeraCristal(index)
          cw.teraButton=2
          pbPlayDecisionSE()
        elsif @battle.pbCanZMove?(index)  # Use Z Move
          @battle.pbRegisterZMove(index)
          cw.zButton=2
          pbPlayDecisionSE()
        end
      elsif Input.trigger?(Input::B)   # Cancel fight menu
        @lastmove[index]=cw.index
        pbPlayCancelSE()
        return -1
      elsif Input.trigger?(Input::L) && !pbInSafari? #Q
        pbShowBattleInfo(@battle)
      end
    end
  end


end