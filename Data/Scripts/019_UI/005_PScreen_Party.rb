#===============================================================================
# Pokémon party buttons and menu
#===============================================================================
class PokemonPartyConfirmCancelSprite < SpriteWrapper
  attr_reader :selected

  def initialize(text,x,y,narrowbox=false,viewport=nil)
    super(viewport)
    @refreshBitmap = true
    @bgsprite = ChangelingSprite.new(0,0,viewport)
    if narrowbox
      @bgsprite.addBitmap("desel","Graphics/#{PARTY_ROUTE}/partyCancelNarrow")
      @bgsprite.addBitmap("sel","Graphics/#{PARTY_ROUTE}/partyCancelSelNarrow")
    else
      @bgsprite.addBitmap("desel","Graphics/#{PARTY_ROUTE}/partyCancel")
      @bgsprite.addBitmap("sel","Graphics/#{PARTY_ROUTE}/partyCancelSel")
    end
    @bgsprite.changeBitmap("desel")
    @overlaysprite = BitmapSprite.new(@bgsprite.bitmap.width,@bgsprite.bitmap.height,viewport)
    @overlaysprite.z = self.z+1
    pbSetSystemFont(@overlaysprite.bitmap)
    @yoffset = 8
    textpos = [[text,56,(narrowbox) ? 2 : 8,2,Color.new(248,248,248),Color.new(40,40,40)]]
    pbDrawTextPositions(@overlaysprite.bitmap,textpos)
    self.x = x
    self.y = y
  end

  def dispose
    @bgsprite.dispose
    @overlaysprite.bitmap.dispose
    @overlaysprite.dispose
    super
  end

  def viewport=(value)
    super
    refresh
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    refresh
  end

  def selected=(value)
    if @selected!=value
      @selected = value
      refresh
    end
  end

  def refresh
    if @bgsprite && !@bgsprite.disposed?
      @bgsprite.changeBitmap((@selected) ? "sel" : "desel")
      @bgsprite.x     = self.x
      @bgsprite.y     = self.y
      @bgsprite.color = self.color
    end
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
  end
end



class PokemonPartyCancelSprite < PokemonPartyConfirmCancelSprite
  def initialize(viewport=nil)
    super(_INTL("SALIR"),398,328,false,viewport)
  end
end



class PokemonPartyConfirmSprite < PokemonPartyConfirmCancelSprite
  def initialize(viewport=nil)
    super(_INTL("CONFIRMAR"),398,308,true,viewport)
  end
end



class PokemonPartyCancelSprite2 < PokemonPartyConfirmCancelSprite
  def initialize(viewport=nil)
    super(_INTL("SALIR"),398,346,true,viewport)
  end
end

class ChangelingSprite < SpriteWrapper
  def initialize(x=0,y=0,viewport=nil)
    super(viewport)
    self.x=x
    self.y=y
    @bitmaps={}
    @currentBitmap=nil
  end

  def addBitmap(key,path)
    if @bitmaps[key]
      @bitmaps[key].dispose
    end
    @bitmaps[key]=AnimatedBitmap.new(path)
  end

  def changeBitmap(key)
    @currentBitmap=@bitmaps[key]
    self.bitmap=@currentBitmap ? @currentBitmap.bitmap : nil
  end

  def dispose
    return if disposed?
    for bm in @bitmaps.values; bm.dispose; end
    @bitmaps.clear
    super
  end

  def update
    return if disposed?
    for bm in @bitmaps.values; bm.update; end
    self.bitmap=@currentBitmap ? @currentBitmap.bitmap : nil
  end
end


class Window_CommandPokemonColor < Window_CommandPokemon
  def initialize(commands,width=nil)
    @colorKey = []
    for i in 0...commands.length
      if commands[i].is_a?(Array)
        @colorKey[i] = commands[i][1]
        commands[i] = commands[i][0]
      end
    end
    super(commands,width)
  end

  def drawItem(index,_count,rect)
    pbSetSystemFont(self.contents) if @starting
    rect = drawCursor(index,rect)
    base   = self.baseColor
    shadow = self.shadowColor
    if @colorKey[index] && @colorKey[index]==1
      base   = Color.new(0,80,160)
      shadow = Color.new(128,192,240)
    end
    pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,@commands[index],base,shadow)
  end
end



#===============================================================================
# Pokémon party panels
#===============================================================================
class PokemonPartyBlankPanel < SpriteWrapper
  attr_accessor :text

  def initialize(_pokemon,index,viewport=nil)
    super(viewport)
    self.x = [0, Graphics.width/2][index%2]
    self.y = [0, 16, 96, 112, 192, 208][index]
    @panelbgsprite = AnimatedBitmap.new("Graphics/Pictures/Party/panel_blank")
    self.bitmap = @panelbgsprite.bitmap
    @text = nil
  end

  def dispose
    @panelbgsprite.dispose
    super
  end

  def selected; return false; end
  def selected=(value); end
  def preselected; return false; end
  def preselected=(value); end
  def switching; return false; end
  def switching=(value); end
  def refresh; end
end



class PokemonPartyPanel < SpriteWrapper
  attr_reader :pokemon
  attr_reader :active
  attr_reader :selected
  attr_reader :preselected
  attr_reader :switching
  attr_reader :text

  def initialize(pokemon,index,viewport=nil)
    super(viewport)
    @pokemon = pokemon
    @active = (index==0)   # true = rounded panel, false = rectangular panel
    @refreshing = true
    self.x = [0, Graphics.width/2][index%2]
    self.y = [0, 16, 96, 112, 192, 208][index]
    @panelbgsprite = ChangelingSprite.new(0,0,viewport)
    @panelbgsprite.z = self.z
    if @active   # Rounded panel
      @panelbgsprite.addBitmap("able","Graphics/#{PARTY_ROUTE}/partyPanelRound")
      @panelbgsprite.addBitmap("ablesel","Graphics/#{PARTY_ROUTE}/partyPanelRoundSel")
      @panelbgsprite.addBitmap("fainted","Graphics/#{PARTY_ROUTE}/partyPanelRoundFnt")
      @panelbgsprite.addBitmap("faintedsel","Graphics/#{PARTY_ROUTE}/partyPanelRoundSelFnt")
      @panelbgsprite.addBitmap("swap","Graphics/#{PARTY_ROUTE}/partyPanelRoundSwap")
      @panelbgsprite.addBitmap("swapsel","Graphics/#{PARTY_ROUTE}/partyPanelRoundSelSwap")
      @panelbgsprite.addBitmap("swapsel2","Graphics/#{PARTY_ROUTE}/partyPanelRoundSelSwap2")
    else   # Rectangular panel
      @panelbgsprite.addBitmap("able","Graphics/#{PARTY_ROUTE}/partyPanelRect")
      @panelbgsprite.addBitmap("ablesel","Graphics/#{PARTY_ROUTE}/partyPanelRectSel")
      @panelbgsprite.addBitmap("fainted","Graphics/#{PARTY_ROUTE}/partyPanelRectFnt")
      @panelbgsprite.addBitmap("faintedsel","Graphics/#{PARTY_ROUTE}/partyPanelRectSelFnt")
      @panelbgsprite.addBitmap("swap","Graphics/#{PARTY_ROUTE}/partyPanelRectSwap")
      @panelbgsprite.addBitmap("swapsel","Graphics/#{PARTY_ROUTE}/partyPanelRectSwap")
      @panelbgsprite.addBitmap("swapsel2","Graphics/#{PARTY_ROUTE}/partyPanelRectSelSwap2")
    end
    @hpbgsprite = ChangelingSprite.new(0,0,viewport)
    @hpbgsprite.z = self.z+1
    @hpbgsprite.addBitmap("able","Graphics/#{PARTY_ROUTE}/partyHP")
    @hpbgsprite.addBitmap("fainted","Graphics/#{PARTY_ROUTE}/partyHPfnt")
    @hpbgsprite.addBitmap("swap","Graphics/#{PARTY_ROUTE}/partyHPswap")
    @ballsprite = ChangelingSprite.new(0,0,viewport)
    @ballsprite.z = self.z+1
    @ballsprite.addBitmap("desel","Graphics/#{PARTY_ROUTE}/partyBall")
    @ballsprite.addBitmap("sel","Graphics/#{PARTY_ROUTE}/partyBallSel")
    @pkmnsprite = PokemonIconSprite.new(pokemon,viewport)
    @pkmnsprite.ox=0
    @pkmnsprite.oy=0
    @pkmnsprite.active = @active
    @pkmnsprite.z      = self.z+2
    @helditemsprite = HeldItemIconSprite.new(0,0,@pokemon,viewport)
    @helditemsprite.z = self.z+3
    @overlaysprite = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
    @overlaysprite.z = self.z+4
    @hpbar    = AnimatedBitmap.new("Graphics/Pictures/Party/overlay_hp")
    @statuses = AnimatedBitmap.new(_INTL("Graphics/Pictures/statuses"))
    @selected      = false
    @preselected   = false
    @switching     = false
    @text          = nil
    @refreshBitmap = true
    @refreshing    = false
    refresh
  end

  def dispose
    @panelbgsprite.dispose
    @hpbgsprite.dispose
    @ballsprite.dispose
    @pkmnsprite.dispose
    @helditemsprite.dispose
    @overlaysprite.bitmap.dispose
    @overlaysprite.dispose
    @hpbar.dispose
    @statuses.dispose
    super
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    refresh
  end

  def text=(value)
    if @text!=value
      @text = value
      @refreshBitmap = true
      refresh
    end
  end

  def pokemon=(value)
    @pokemon = value
    @pkmnsprite.pokemon = value if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.pokemon = value if @helditemsprite && !@helditemsprite.disposed?
    @refreshBitmap = true
    refresh
  end

  def selected=(value)
    if @selected!=value
      @selected = value
      refresh
    end
  end

  def preselected=(value)
    if @preselected!=value
      @preselected = value
      refresh
    end
  end

  def switching=(value)
    if @switching!=value
      @switching = value
      refresh
    end
  end

  def hp; return @pokemon.hp; end

  def refresh
    return if disposed?
    return if @refreshing
    @refreshing = true
    if @panelbgsprite && !@panelbgsprite.disposed?
      if self.selected
        if self.preselected;       @panelbgsprite.changeBitmap("swapsel2")
        elsif @switching;          @panelbgsprite.changeBitmap("swapsel")
        elsif @pokemon.hp<=0;      @panelbgsprite.changeBitmap("faintedsel")
        else;                      @panelbgsprite.changeBitmap("ablesel")
        end
      else
        if self.preselected;       @panelbgsprite.changeBitmap("swap")
        elsif @pokemon.hp<=0;      @panelbgsprite.changeBitmap("fainted")
        else;                      @panelbgsprite.changeBitmap("able")
        end
      end
      @panelbgsprite.x     = self.x
      @panelbgsprite.y     = self.y
      @panelbgsprite.color = self.color
    end
    if @hpbgsprite && !@hpbgsprite.disposed?
      @hpbgsprite.visible = (!@pokemon.isEgg? && !(@text && @text.length>0))
      if @hpbgsprite.visible
        if self.preselected || (self.selected && @switching); @hpbgsprite.changeBitmap("swap")
        elsif @pokemon.hp<=0;                                 @hpbgsprite.changeBitmap("fainted")
        else;                                                 @hpbgsprite.changeBitmap("able")
        end
        @hpbgsprite.x     = self.x+96
        @hpbgsprite.y     = self.y+50
        @hpbgsprite.color = self.color
      end
    end
    if @ballsprite && !@ballsprite.disposed?
      @ballsprite.changeBitmap((self.selected) ? "sel" : "desel")
      @ballsprite.x     = self.x+10
      @ballsprite.y     = self.y
      @ballsprite.color = self.color
    end
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.x        = self.x+28
      @pkmnsprite.y        = self.y+0
      @pkmnsprite.color    = self.color
      @pkmnsprite.selected = self.selected
    end
    if @helditemsprite && !@helditemsprite.disposed?
      if @helditemsprite.visible
        @helditemsprite.x     = self.x+62
        @helditemsprite.y     = self.y+48
        @helditemsprite.color = self.color
      end
    end
    if @overlaysprite && !@overlaysprite.disposed?
      @overlaysprite.x     = self.x
      @overlaysprite.y     = self.y
      @overlaysprite.color = self.color
    end
    if @refreshBitmap
      @refreshBitmap = false
      @overlaysprite.bitmap.clear if @overlaysprite.bitmap
      basecolor   = Color.new(248,248,248)
      shadowcolor = Color.new(40,40,40)
      pbSetSystemFont(@overlaysprite.bitmap)
      textpos = []
      # Draw Pokémon name
      textpos.push([@pokemon.name,96,16,0,basecolor,shadowcolor])
      if !@pokemon.isEgg?
        if !@text || @text.length==0
          # Draw HP numbers
          textpos.push([sprintf("% 3d /% 3d",@pokemon.hp,@pokemon.totalhp),224,60,1,basecolor,shadowcolor])
          # Draw HP bar
          if @pokemon.hp>0
            w = @pokemon.hp*96*1.0/@pokemon.totalhp
            w = 1 if w<1
            w = ((w/2).round)*2
            hpzone = 0
            hpzone = 1 if @pokemon.hp<=(@pokemon.totalhp/2).floor
            hpzone = 2 if @pokemon.hp<=(@pokemon.totalhp/4).floor
            hprect = Rect.new(0,hpzone*8,w,8)
            @overlaysprite.bitmap.blt(128,52,@hpbar.bitmap,hprect)
          end
          # Draw status
          status = -1
          status = 6 if @pokemon.pokerusStage==1
          status = @pokemon.status-1 if @pokemon.status>0
          status = 5 if @pokemon.hp<=0
          if status>=0
            statusrect = Rect.new(0,16*status,44,16)
            @overlaysprite.bitmap.blt(78,68,@statuses.bitmap,statusrect)
          end
        end
        # Draw gender symbol
        if @pokemon.isMale?
          textpos.push([_INTL("♂"),224,16,0,Color.new(0,112,248),Color.new(120,184,232)])
        elsif @pokemon.isFemale?
          textpos.push([_INTL("♀"),224,16,0,Color.new(232,32,16),Color.new(248,168,184)])
        end
        # Draw shiny icon
        if @pokemon.isShiny?
          pbDrawImagePositions(@overlaysprite.bitmap,[[
             "Graphics/Pictures/shiny",80,48,0,0,16,16]])
        end
      end
      pbDrawTextPositions(@overlaysprite.bitmap,textpos)
      # Draw level text
      if !@pokemon.isEgg?
        @levelX=20
        @levelY=62
        pbSetSmallFont(@overlaysprite.bitmap)
        leveltext=[([_INTL("Nv.{1}",@pokemon.level),@levelX,@levelY,0,basecolor,shadowcolor])]
        pbDrawTextPositions(@overlaysprite.bitmap,leveltext)
        
        #pbDrawImagePositions(@overlaysprite.bitmap,[[
        #   "Graphics/Pictures/Party/overlay_lv",20,70,0,0,22,14]])
        #pbSetSmallFont(@overlaysprite.bitmap)
        #pbDrawTextPositions(@overlaysprite.bitmap,[
        #   [@pokemon.level.to_s,42,62,0,basecolor,shadowcolor]
        #])
      end
      # Draw annotation text
      if @text && @text.length>0
        pbSetSystemFont(@overlaysprite.bitmap)
        pbDrawTextPositions(@overlaysprite.bitmap,[
           [@text,96,58,0,basecolor,shadowcolor]
        ])
      end
    end
    @refreshing = false
  end

  def update
    super
    @panelbgsprite.update if @panelbgsprite && !@panelbgsprite.disposed?
    @hpbgsprite.update if @hpbgsprite && !@hpbgsprite.disposed?
    @ballsprite.update if @ballsprite && !@ballsprite.disposed?
    @pkmnsprite.update if @pkmnsprite && !@pkmnsprite.disposed?
    @helditemsprite.update if @helditemsprite && !@helditemsprite.disposed?
  end
end



#===============================================================================
# Pokémon party visuals
#===============================================================================
class PokemonScreen_Scene
  def pbStartScene(party,starthelptext,annotations=nil,multiselect=false)
    @sprites = {}
    @party = party
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @multiselect = multiselect
    addBackgroundPlane(@sprites,"partybg","Party/partybg",@viewport)
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"],2)
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new(starthelptext)
    @sprites["helpwindow"].viewport = @viewport
    @sprites["helpwindow"].visible  = true
    pbBottomLeftLines(@sprites["helpwindow"],1)
    pbSetHelpText(starthelptext)
    # Add party Pokémon sprites
    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonPartyPanel.new(@party[i],i,@viewport)
      else
        @sprites["pokemon#{i}"] = PokemonPartyBlankPanel.new(@party[i],i,@viewport)
      end
      @sprites["pokemon#{i}"].text = annotations[i] if annotations
    end
    if @multiselect
      @sprites["pokemon6"] = PokemonPartyConfirmSprite.new(@viewport)
      @sprites["pokemon7"] = PokemonPartyCancelSprite2.new(@viewport)
    else
      @sprites["pokemon6"] = PokemonPartyCancelSprite.new(@viewport)
    end
    # Select first Pokémon
    @activecmd = 0
    @sprites["pokemon0"].selected = true
    pbFadeInAndShow(@sprites) { update }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbDisplay(text)
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    @sprites["helpwindow"].visible = false
    pbPlayDecisionSE
    loop do
      Graphics.update
      Input.update
      self.update
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      else
        if Input.trigger?(Input::B) || Input.trigger?(Input::C)
          break
        end
      end
    end
    @sprites["messagebox"].visible = false
    @sprites["helpwindow"].visible = true
  end

  def pbDisplayConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    @sprites["helpwindow"].visible = false
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Sí"),_INTL("No")])) {
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      cmdwindow.z = @viewport.z+1
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        self.update
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::B)
            ret = false
            break
          elsif Input.trigger?(Input::C) && @sprites["messagebox"].resume
            ret = (cmdwindow.index==0)
            break
          end
        end
      end
    }
    @sprites["messagebox"].visible = false
    @sprites["helpwindow"].visible = true
    return ret
  end

  def pbShowCommands(helptext,commands,index=0)
    ret = -1
    helpwindow = @sprites["helpwindow"]
    helpwindow.visible = true
    using(cmdwindow = Window_CommandPokemonColor.new(commands)) {
      cmdwindow.z     = @viewport.z+1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
      helpwindow.resizeHeightToFit(helptext,Graphics.width-cmdwindow.width)
      helpwindow.text = helptext
      pbBottomLeft(helpwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        self.update
        if Input.trigger?(Input::B)
          pbPlayCancelSE
          ret = -1
          break
        elsif Input.trigger?(Input::C)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    }
    return ret
  end

  def pbSetHelpText(helptext)
    helpwindow = @sprites["helpwindow"]
    pbBottomLeftLines(helpwindow,1)
    helpwindow.text = helptext
    helpwindow.width = 398
    helpwindow.visible = true
  end

  def pbHasAnnotations?
    return @sprites["pokemon0"].text!=nil
  end

  def pbAnnotate(annot)
    for i in 0...6
      @sprites["pokemon#{i}"].text = (annot) ? annot[i] : nil
    end
  end

  def pbSelect(item)
    @activecmd = item
    numsprites = (@multiselect) ? 8 : 7
    for i in 0...numsprites
      @sprites["pokemon#{i}"].selected = (i==@activecmd)
    end
  end

  def pbPreSelect(item)
    @activecmd = item
  end

  def pbSwitchBegin(oldid,newid)
    pbSEPlay("GUI party switch")
    oldsprite = @sprites["pokemon#{oldid}"]
    newsprite = @sprites["pokemon#{newid}"]
    timeTaken = Graphics.frame_rate*4/10
    distancePerFrame = (Graphics.width/(2.0*timeTaken)).ceil
    timeTaken.times do
      oldsprite.x += (oldid&1)==0 ? -distancePerFrame : distancePerFrame
      newsprite.x += (newid&1)==0 ? -distancePerFrame : distancePerFrame
      Graphics.update
      Input.update
      self.update
    end
  end

  def pbSwitchEnd(oldid,newid)
    pbSEPlay("GUI party switch")
    oldsprite = @sprites["pokemon#{oldid}"]
    newsprite = @sprites["pokemon#{newid}"]
    oldsprite.pokemon = @party[oldid]
    newsprite.pokemon = @party[newid]
    timeTaken = Graphics.frame_rate*4/10
    distancePerFrame = (Graphics.width/(2.0*timeTaken)).ceil
    timeTaken.times do
      oldsprite.x -= (oldid&1)==0 ? -distancePerFrame : distancePerFrame
      newsprite.x -= (newid&1)==0 ? -distancePerFrame : distancePerFrame
      Graphics.update
      Input.update
      self.update
    end
    for i in 0...6
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching   = false
    end
    pbRefresh
  end

  def pbClearSwitching
    for i in 0...6
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching   = false
    end
  end

  def pbSummary(pkmnid)
    oldsprites=pbFadeOutAndHide(@sprites)
    scene=PokemonSummaryScene.new
    screen=PokemonSummary.new(scene)
    screen.pbStartScreen(@party,pkmnid)
    pbFadeInAndShow(@sprites,oldsprites)
  end

  def pbChooseItem(bag)
    oldsprites=pbFadeOutAndHide(@sprites)
    @sprites["helpwindow"].visible=false
    @sprites["messagebox"].visible=false
    scene=PokemonBag_Scene.new
    screen=PokemonBagScreen.new(scene,bag)
    ret=screen.pbGiveItemScreen
    pbFadeInAndShow(@sprites,oldsprites)
    return ret
  end

  def pbUseItem(bag,pokemon)
    oldsprites=pbFadeOutAndHide(@sprites)
    @sprites["helpwindow"].visible=false
    @sprites["messagebox"].visible=false
    scene=PokemonBag_Scene.new
    screen=PokemonBagScreen.new(scene,bag)
    ret=screen.pbUseItemScreen(pokemon)
    pbFadeInAndShow(@sprites,oldsprites)
    return ret
  end
  
  def pbMessageFreeText(text,startMsg,maxlength)
    return Kernel.pbMessageFreeText(
       _INTL("Ingrese un mensaje (máx. {1} caracteres).",maxlength),
       _INTL("{1}",startMsg),false,maxlength,Graphics.width) { update }
  end
  
  def pbChoosePokemon(switching=false,initialsel=-1,canswitch=0)
    for i in 0...6
      @sprites["pokemon#{i}"].preselected = (switching && i==@activecmd)
      @sprites["pokemon#{i}"].switching   = switching
    end
    @activecmd = initialsel if initialsel>=0
    pbRefresh
    loop do
      Graphics.update
      Input.update
      self.update
      oldsel = @activecmd
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key>=0
        @activecmd = pbChangeSelection(key,@activecmd)
      end
      if @activecmd!=oldsel   # Changing selection
        pbPlayCursorSE
        numsprites = (@multiselect) ? 8 : 7
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected = (i==@activecmd)
        end
      end
      cancelsprite = (@multiselect) ? 7 : 6
      if Input.trigger?(Input::A) && canswitch==1 && @activecmd!=cancelsprite
        pbPlayDecisionSE
        return [1,@activecmd]
      elsif Input.trigger?(Input::A) && canswitch==2
        return -1
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE if !switching
        return -1
      elsif Input.trigger?(Input::C)
        if @activecmd==cancelsprite
          (switching) ? pbPlayDecisionSE : pbPlayCloseMenuSE
          return -1
        else
          pbPlayDecisionSE
          return @activecmd
        end
      end
    end
  end

  def pbChangeSelection(key,currentsel)
    numsprites = (@multiselect) ? 8 : 7
    case key
    when Input::LEFT
      begin
        currentsel -= 1
      end while currentsel>0 && currentsel<@party.length && !@party[currentsel]
      if currentsel>=@party.length && currentsel<6
        currentsel = @party.length-1
      end
      currentsel = numsprites-1 if currentsel<0
    when Input::RIGHT
      begin
        currentsel += 1
      end while currentsel<@party.length && !@party[currentsel]
      if currentsel==@party.length
        currentsel = 6
      elsif currentsel==numsprites
        currentsel = 0
      end
    when Input::UP
      if currentsel>=6
        begin
          currentsel -= 1
        end while currentsel>0 && !@party[currentsel]
      else
        begin
          currentsel -= 2
        end while currentsel>0 && !@party[currentsel]
      end
      if currentsel>=@party.length && currentsel<6
        currentsel = @party.length-1
      end
      currentsel = numsprites-1 if currentsel<0
    when Input::DOWN
      if currentsel>=5
        currentsel += 1
      else
        currentsel += 2
        currentsel = 6 if currentsel<6 && !@party[currentsel]
      end
      if currentsel>=@party.length && currentsel<6
        currentsel = 6
      elsif currentsel>=numsprites
        currentsel = 0
      end
    end
    return currentsel
  end

  def pbHardRefresh
    oldtext = []
    lastselected = -1
    for i in 0...6
      oldtext.push(@sprites["pokemon#{i}"].text)
      lastselected = i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end
    lastselected = @party.length-1 if lastselected>=@party.length
    lastselected = 0 if lastselected<0
    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"] = PokemonPartyPanel.new(@party[i],i,@viewport)
      else
        @sprites["pokemon#{i}"] = PokemonPartyBlankPanel.new(@party[i],i,@viewport)
      end
      @sprites["pokemon#{i}"].text = oldtext[i]
    end
    pbSelect(lastselected)
  end

  def pbRefresh
    for i in 0...6
      sprite = @sprites["pokemon#{i}"]
      if sprite
        if sprite.is_a?(PokemonPartyPanel)
          sprite.pokemon = sprite.pokemon
        else
          sprite.refresh
        end
      end
    end
  end

  def pbRefreshSingle(i)
    sprite = @sprites["pokemon#{i}"]
    if sprite
      if sprite.is_a?(PokemonPartyPanel)
        sprite.pokemon = sprite.pokemon
      else
        sprite.refresh
      end
    end
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end
  

end

#===============================================================================
# Pokémon party mechanics
#===============================================================================
class PokemonScreen
  attr_reader :scene
  attr_reader :party

  def initialize(scene, party)
    @scene = scene
    @party = party
  end

  def pbStartScene(helptext, doublebattle = false, annotations = nil)
    @scene.pbStartScene(@party, helptext, annotations)
  end

  def pbChoosePokemon(helptext = nil)
    @scene.pbSetHelpText(helptext) if helptext
    return @scene.pbChoosePokemon
  end

  def pbPokemonGiveScreen(item)
    @scene.pbStartScene(@party, _INTL("¿Dar a qué Pokémon?"))
    pkmnid = @scene.pbChoosePokemon
    ret = false
    if pkmnid >= 0
      ret = pbGiveMail(item, @party[pkmnid], pkmnid)
    end
    pbRefreshSingle(pkmnid)
    @scene.pbEndScene
    return ret
  end

  def pbPokemonGiveMailScreen(mailIndex)
    @scene.pbStartScene(@party, _INTL("¿Dar a qué Pokémon?"))
    pkmnid = @scene.pbChoosePokemon
    if pkmnid >= 0
      pkmn = @party[pkmnid]
      if pkmn.item != 0 || pkmn.mail
        pbDisplay(_INTL("Este Pokémon ya lleva un objeto. No puede llevar una carta."))
      elsif pkmn.isEgg?
        pbDisplay(_INTL("Los Huevos no pueden llevar una carta."))
      else
        pbDisplay(_INTL("La carta ha sido transferida desde la casilla."))
        pkmn.mail = $PokemonGlobal.mailbox[mailIndex]
        pkmn.setItem(pkmn.mail.item)
        $PokemonGlobal.mailbox.delete_at(mailIndex)
        pbRefreshSingle(pkmnid)
      end
    end
    @scene.pbEndScene
  end

  def pbMailScreen(item,pkmn,pkmnid)
    message=""
    loop do
      message=@scene.pbMessageFreeText(
         _INTL("Ingresa un mensaje (máx. de 256 caracteres)."),"",256)
      if message!=""
        # Store mail if a message was written
        poke1=poke2=poke3=nil
        if $Trainer.party[pkmnid+2]
          p=$Trainer.party[pkmnid+2]
          poke1=[p.species,p.gender,p.isShiny?,(p.form rescue 0),(p.isShadow? rescue false)]
          poke1.push(true) if p.isEgg?
        end
        if $Trainer.party[pkmnid+1]
          p=$Trainer.party[pkmnid+1]
          poke2=[p.species,p.gender,p.isShiny?,(p.form rescue 0),(p.isShadow? rescue false)]
          poke2.push(true) if p.isEgg?
        end
        poke3=[pkmn.species,pkmn.gender,pkmn.isShiny?,(pkmn.form rescue 0),(pkmn.isShadow? rescue false)]
        poke3.push(true) if pkmn.isEgg?
        pbStoreMail(pkmn,item,message,poke1,poke2,poke3)
        return true
      else
        return false if pbConfirm(_INTL("¿Quieres dejar al Pokémon sin la carta?"))
      end
    end
  end

  def pbTakeMail(pkmn)
    if !pkmn.hasItem?
      pbDisplay(_INTL("{1} no está llevando nada.",pkmn.name))
    elsif !$PokemonBag.pbCanStore?(pkmn.item)
      pbDisplay(_INTL("La mochila está llena. No se puede le puede quitar el objeto al Pokémon."))
    elsif pkmn.mail
      if pbConfirm(_INTL("¿Quieres enviar la carta a tu PC?"))
        if !pbMoveToMailbox(pkmn)
          pbDisplay(_INTL("El buzón de la PC está lleno."))
        else
          pbDisplay(_INTL("La carta fue enviada a tu PC."))
          pkmn.setItem(0)
        end
      elsif pbConfirm(_INTL("Si le quitas la carta, perderás el mensaje. ¿Estás de acuerdo?"))
        pbDisplay(_INTL("Se ha quitado la carta al Pokémon."))
        $PokemonBag.pbStoreItem(pkmn.item)
        pkmn.setItem(0)
        pkmn.mail=nil
      end
    else
      $PokemonBag.pbStoreItem(pkmn.item)
      itemname=PBItems.getName(pkmn.item)
      pbDisplay(_INTL("Recibiste {1} de {2}.",itemname,pkmn.name))
      pkmn.setItem(0)
    end
  end

  def pbGiveMail(item,pkmn,pkmnid=0)
    thisitemname=PBItems.getName(item)
    if pkmn.isEgg?
      pbDisplay(_INTL("Los huevos no pueden llevar objetos."))
      return false
    elsif pkmn.mail
      pbDisplay(_INTL("Quitar la carta de {1} antes de darle otro objeto.",pkmn.name))
      return false
    end
    if pkmn.item!=0
      itemname=PBItems.getName(pkmn.item)
      pbDisplay(_INTL("¡{1} ya lleva una unidad de {2}.\1",pkmn.name,itemname))
      if pbConfirm(_INTL("¿Quieres cambiar un objeto por el otro?"))
        $PokemonBag.pbDeleteItem(item)
        if !$PokemonBag.pbStoreItem(pkmn.item)
          if !$PokemonBag.pbStoreItem(item) # Compensate
            raise _INTL("No se puede recuperar objeto descartado de la mochila")
          end
          pbDisplay(_INTL("La Mochila está llena. No se puede quitar el objeto del Pokémon."))
        else
          if pbIsMail?(item)
            if pbMailScreen(item,pkmn,pkmnid)
              pkmn.setItem(item)
              pbDisplay(_INTL("¡Se ha sustituido {1} por {2}!",itemname,thisitemname))
              return true
            else
              if !$PokemonBag.pbStoreItem(item) # Compensate
                raise _INTL("No se puede recuperar objeto descartado de la mochila.")
              end
            end
          else
            pkmn.setItem(item)
            pbDisplay(_INTL("¡Se ha sustituido {1} por {2}!",itemname,thisitemname))
            return true
          end
        end
      end
    else
      if !pbIsMail?(item) || pbMailScreen(item,pkmn,pkmnid) # Open the mail screen if necessary
        $PokemonBag.pbDeleteItem(item)
        pkmn.setItem(item)
        pbDisplay(_INTL("¡{1} lleva ahora {2}!",pkmn.name,thisitemname))
        return true
      end
    end
    return false
  end
  
  
  def pbEndScene
    @scene.pbEndScene
  end

  def pbHardRefresh
    @scene.pbHardRefresh
  end

  def pbRefresh
    @scene.pbRefresh
  end

  def pbRefreshSingle(i)
    @scene.pbRefreshSingle(i)
  end

  def pbDisplay(text)
    @scene.pbDisplay(text)
  end

  def pbConfirm(text)
    return @scene.pbDisplayConfirm(text)
  end

  def pbShowCommands(helptext, commands, index = 0)
    return @scene.pbShowCommands(helptext, commands, index)
  end

  # Checks for identical species
  def pbCheckSpecies(array)
    for i in 0...array.length
      for j in i+1...array.length
        return false if array[i].species == array[j].species
      end
    end
    return true
  end

  # Checks for identical held items
  def pbCheckItems(array)
    for i in 0...array.length
      next if !array[i].hasItem?
      for j in i+1...array.length
        return false if array[i].item == array[j].item
      end
    end
    return true
  end

  def pbSwitch(oldid, newid)
    if oldid != newid
      @scene.pbSwitchBegin(oldid, newid)
      tmp = @party[oldid]
      @party[oldid] = @party[newid]
      @party[newid] = tmp
      @scene.pbSwitchEnd(oldid, newid)
    end
  end
  
  def pbChooseMove(pokemon, helptext, index = 0)
    movenames = []
    for i in pokemon.moves
      break if i.id == 0
      if i.totalpp == 0
        movenames.push(_INTL("{1} (PP: ---)", PBMoves.getName(i.id)))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})", PBMoves.getName(i.id), i.pp, i.totalpp))
      end
    end
    return @scene.pbShowCommands(helptext, movenames, index)
  end

  # For after using an evolution stone
  def pbRefreshAnnotations(ableProc)
    annot = []
    for pkmn in @party
      elig = ableProc.call(pkmn)
      annot.push(elig ? _INTL("PUEDE") : _INTL("NO PUEDE"))
    end
    @scene.pbAnnotate(annot)
  end

  def pbClearAnnotations
    @scene.pbAnnotate(nil)
  end

  def pbPokemonMultipleEntryScreenEx(ruleset)
    annot = []
    statuses = []
    ordinals = [
      _INTL("NO APTO"),
      _INTL("NO REGISTRADO"),
      _INTL("INHABILITADO"),
      _INTL("PRIMERO"),
      _INTL("SEGUNDO"),
      _INTL("TERCERO"),
      _INTL("CUARTO"),
      _INTL("QUINTO"),
      _INTL("SEXTO")
    ]
    if !ruleset.hasValidTeam?(@party)
      return nil
    end
    ret = nil
    addedEntry = false
    for i in 0...@party.length
      if ruleset.isPokemonValid?(@party[i])
        statuses[i] = 1
      else
        statuses[i] = 2
      end
    end
    for i in 0...@party.length
      annot[i] = ordinals[statuses[i]]
    end
    @scene.pbStartScene(@party, _INTL("Elige un Pokémon y confirma."), annot, true)
    loop do
      realorder = []
      for i in 0...@party.length
        for j in 0...@party.length
          if statuses[j] == i + 3
            realorder.push(j)
            break
          end
        end
      end
      for i in 0...realorder.length
        statuses[realorder[i]] = i + 3
      end
      for i in 0...@party.length
        annot[i] = ordinals[statuses[i]]
      end
      @scene.pbAnnotate(annot)
      if realorder.length == ruleset.number && addedEntry
        @scene.pbSelect(6)
      end
      @scene.pbSetHelpText(_INTL("Elige un Pokémon y confirma."))
      pkmnid = @scene.pbChoosePokemon
      addedEntry = false
      if pkmnid == 6 # Confirm was chosen
        ret = []
        for i in realorder
          ret.push(@party[i])
        end
        error = []
        if !ruleset.isValid?(ret, error)
          pbDisplay(error[0])
          ret = nil
        else
          break
        end
      end
      if pkmnid < 0 # Canceled
        break
      end
      cmdEntry = -1
      cmdNoEntry = -1
      cmdSummary = -1
      commands = []
      if (statuses[pkmnid] || 0) == 1
        commands[cmdEntry = commands.length] = _INTL("Participa")
      elsif (statuses[pkmnid] || 0) > 2
        commands[cmdNoEntry = commands.length] = _INTL("No participa")
      end
      pkmn = @party[pkmnid]
      commands[cmdSummary = commands.length] = _INTL("Datos")
      commands[commands.length] = _INTL("Salir")
      command = @scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), commands) if pkmn
      if cmdEntry >= 0 && command == cmdEntry
        if realorder.length >= ruleset.number && ruleset.number > 0
          pbDisplay(_INTL("No pueden participar más de {1} Pokémon.", ruleset.number))
        else
          statuses[pkmnid] = realorder.length + 3
          addedEntry = true
          pbRefreshSingle(pkmnid)
        end
      elsif cmdNoEntry >= 0 && command == cmdNoEntry
        statuses[pkmnid] = 1
        pbRefreshSingle(pkmnid)
      elsif cmdSummary >= 0 && command == cmdSummary
        @scene.pbSummary(pkmnid)
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbChooseAblePokemon(ableProc, allowIneligible = false)
    annot = []
    eligibility = []
    for pkmn in @party
      elig = ableProc.call(pkmn)
      eligibility.push(elig)
      annot.push(elig ? _INTL("PUEDE") : _INTL("NO PUEDE"))
    end
    ret = -1
    @scene.pbStartScene(@party,
      @party.length > 1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."), annot)
    loop do
      @scene.pbSetHelpText(
        @party.length > 1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
      pkmnid = @scene.pbChoosePokemon
      if pkmnid < 0
        break
      elsif !eligibility[pkmnid] && !allowIneligible
        pbDisplay(_INTL("Este Pokémon no puede ser elegido."))
      else
        ret = pkmnid
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbPokemonScreen
    @scene.pbStartScene(@party, @party.length > 1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."), nil)
    loop do
      @scene.pbSetHelpText(@party.length > 1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
      pkmnid = @scene.pbChoosePokemon
      break if pkmnid < 0
      pkmn = @party[pkmnid]
      # Get all commands
      command_list = []
      commands = []
      MenuHandlers.each_available(:party_menu, self, @party, pkmnid) do |option, hash, name|
        command_list.push(name)
        commands.push(hash)
      end
      command_list.push(_INTL("Salir"))
      # Add field move commands
      if !pkmn.isEgg?
        insert_index = ($DEBUG) ? 2 : 1
        pkmn.moves.each_with_index do |move, i|
          next if !HiddenMoveHandlers.hasHandler(move.id) &&
                  !isConst?(move.id, PBMoves, :MILKDRINK) &&
                  !isConst?(move.id, PBMoves, :SOFTBOILED)
          command_list.insert(insert_index, [PBMoves.getName(move.id), 1])
          commands.insert(insert_index, i)
          insert_index += 1
        end
      end
      # Choose a menu option
      choice = @scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), command_list)
      next if choice < 0 || choice >= commands.length
      # Effect of chosen menu option
      case commands[choice]
      when Hash   # Option defined via a MenuHandler
        commands[choice]["effect"].call(self, @party, pkmnid)
      when Integer   # Hidden move's index
        move = pkmn.moves[commands[choice]]
        if isConst?(move.id, PBMoves, :MILKDRINK) ||
           isConst?(move.id, PBMoves, :SOFTBOILED)
          amt = [(pkmn.totalhp / 5).floor, 1].max
          if pkmn.hp <= amt
            pbDisplay(_INTL("No tiene PS suficientes..."))
            next
          end
          @scene.pbSetHelpText(_INTL("¿En cuál Pokémon usarlo?"))
          oldpkmnid = pkmnid
          loop do
            @scene.pbPreSelect(oldpkmnid)
            pkmnid = @scene.pbChoosePokemon(true, pkmnid)
            break if pkmnid < 0
            newpkmn = @party[pkmnid]
            movename = PBMoves.getName(move.id)
            if pkmnid == oldpkmnid
              pbDisplay(_INTL("¡{1} no puede usar {2} en sí mismo!", pkmn.name, movename))
            elsif newpkmn.isEgg?
              pbDisplay(_INTL("¡{1} no puede usarse en un Huevo!", movename))
            elsif newpkmn.hp == 0 || newpkmn.hp == newpkmn.totalhp
              pbDisplay(_INTL("{1} no puede usarse en ese Pokémon.", movename))
            else
              pkmn.hp -= amt
              hpgain = pbItemRestoreHP(newpkmn, amt)
              @scene.pbDisplay(_INTL("{1} recuperó {2} puntos de salud.", newpkmn.name, hpgain))
              pbRefresh
            end
            break if pkmn.hp <= amt
          end
          @scene.pbSelect(oldpkmnid)
          pbRefresh
        elsif Kernel.pbCanUseHiddenMove?(pkmn, move.id)
          @scene.pbEndScene
          if isConst?(move.id, PBMoves, :FLY)
            scene = PokemonRegionMapScene.new(-1, false)
            screen = PokemonRegionMap.new(scene)
            ret = screen.pbStartFlyScreen
            if ret
              $PokemonTemp.flydata = ret
              return [pkmn, move.id]
            end
            @scene.pbStartScene(@party,
              @party.length > 1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
            next
          end
          return [pkmn, move.id]
        end
      end
    end
    @scene.pbEndScene
    return nil
  end

  def pbPokemonDebug(pkmn, pkmnid)
    # Implementación del depurador (debe estar definida en otro lugar)
  end
end

#===============================================================================
# Party screen menu commands
#===============================================================================
def pbHeldItemIconFile(item)   # Used in the party screen
  return nil if !item || item==0
  
  namebase = "item"
  namebase = "mail" if pbIsMail?(item)
  namebase = "mega" if pbIsMegaStone?(item)
  namebase = "z_crystal" if pbIsZCrystal?(item)
  
  bitmapFileName = sprintf("Graphics/Pictures/Party/icon_%s_%s",namebase,getConstantName(PBItems,item)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName = sprintf("Graphics/Pictures/Party/icon_%s_%03d",namebase,item)
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName = sprintf("Graphics/Pictures/Party/icon_%s",namebase)
    end
  end
  return bitmapFileName
end

MenuHandlers.add(:party_menu, :summary, {
  "name"      => _INTL("Datos"),
  "order"     => 10,
  "effect"    => proc { |screen, party, party_idx|
    screen.scene.pbSummary(party_idx)
  }
})

MenuHandlers.add(:party_menu, :debug, {
  "name"      => _INTL("Depurador"),
  "order"     => 20,
  "condition" => proc { |screen, party, party_idx| next $DEBUG },
  "effect"    => proc { |screen, party, party_idx|
    screen.pbPokemonDebug(party[party_idx], party_idx)
  }
})

MenuHandlers.add(:party_menu, :switch, {
  "name"      => _INTL("Mover"),
  "order"     => 30,
  "condition" => proc { |screen, party, party_idx| next party.length > 1 },
  "effect"    => proc { |screen, party, party_idx|
    screen.scene.pbSetHelpText(_INTL("¿A qué posición mover?"))
    oldpkmnid = party_idx
    pkmnid = screen.scene.pbChoosePokemon(true)
    screen.pbSwitch(oldpkmnid, pkmnid) if pkmnid >= 0 && pkmnid != oldpkmnid
  }
})

MenuHandlers.add(:party_menu, :mail, {
  "name"      => _INTL("Carta"),
  "order"     => 40,
  "condition" => proc { |screen, party, party_idx| next !party[party_idx].isEgg? && party[party_idx].mail },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    command = screen.scene.pbShowCommands(_INTL("¿Qué quieres hacer con la carta?"),
                                          [_INTL("Leer"), _INTL("Quitar"), _INTL("Salir")])
    case command
    when 0   # Read
      pbFadeOutIn(99999) {
        pbDisplayMail(pkmn.mail, pkmn)
      }
    when 1   # Take
      screen.pbTakeMail(pkmn)
      screen.pbRefreshSingle(party_idx)
    end
  }
})

MenuHandlers.add(:party_menu, :item, {
  "name"      => _INTL("Objeto"),
  "order"     => 50,
  "condition" => proc { |screen, party, party_idx| next !party[party_idx].isEgg? && !party[party_idx].mail },
  "effect"    => proc { |screen, party, party_idx|
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:party_menu_item, screen, party, party_idx) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    command_list.push(_INTL("Salir"))
    # Choose a menu option
    choice = screen.scene.pbShowCommands(_INTL("¿Qué quieres hacer con él?"), command_list)
    next if choice < 0 || choice >= commands.length
    commands[choice]["effect"].call(screen, party, party_idx)
  }
})

MenuHandlers.add(:party_menu_item, :use, {
  "name"      => _INTL("Usar"),
  "order"     => 10,
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    item = screen.scene.pbUseItem($PokemonBag, pkmn)
    if item > 0
      pbUseItemOnPokemon(item, pkmn, screen)
      screen.pbRefreshSingle(party_idx)
    end
  }
})

MenuHandlers.add(:party_menu_item, :give, {
  "name"      => _INTL("Dar"),
  "order"     => 20,
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    item = screen.scene.pbChooseItem($PokemonBag)
    if item > 0
      screen.pbGiveMail(item, pkmn, party_idx)
      screen.pbRefreshSingle(party_idx)
    end
  }
})

MenuHandlers.add(:party_menu_item, :take, {
  "name"      => _INTL("Quitar"),
  "order"     => 30,
  "condition" => proc { |screen, party, party_idx| next party[party_idx].hasItem? },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    screen.pbTakeMail(pkmn)
    screen.pbRefreshSingle(party_idx)
  }
})

MenuHandlers.add(:party_menu_item, :move, {
  "name"      => _INTL("Mover"),
  "order"     => 40,
  "condition" => proc { |screen, party, party_idx| next party[party_idx].hasItem? && !pbIsMail?(party[party_idx].item) },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    item = pkmn.item
    itemname = PBItems.getName(item)
    screen.scene.pbSetHelpText(_INTL("¿A qué Pokémon quieres darle {1}?", itemname))
    oldpkmnid = party_idx
    moved = false
    loop do
      screen.scene.pbPreSelect(oldpkmnid)
      pkmnid = screen.scene.pbChoosePokemon(true, party_idx)
      break if pkmnid < 0
      newpkmn = party[pkmnid]
      break if pkmnid == oldpkmnid
      if newpkmn.isEgg?
        screen.pbDisplay(_INTL("Un Huevo no puede llevar un objeto."))
        next
      elsif !newpkmn.hasItem?
        newpkmn.setItem(item)
        pkmn.setItem(0)
        screen.pbRefresh
        screen.pbDisplay(_INTL("Le has dado {2} a {1}.", newpkmn.name, itemname))
        moved = true
        break
      elsif pbIsMail?(newpkmn.item)
        screen.pbDisplay(_INTL("Debes tomar la carta de {1} antes de darle otro objeto.", newpkmn.name))
        next
      end
      # New Pokémon is also holding an item
      newitem = newpkmn.item
      newitemname = PBItems.getName(newitem)
      screen.pbDisplay(_INTL("{1} ya está llevando {2}.\1", newpkmn.name, newitemname))
      next if !screen.pbConfirm(_INTL("¿Quieres intercambiar estos objetos?"))
      newpkmn.setItem(item)
      pkmn.setItem(newitem)
      screen.pbRefresh
      screen.pbDisplay(_INTL("Le has dado {2} a {1}.", newpkmn.name, itemname))
      screen.pbDisplay(_INTL("Le has dado {2} a {1}.", pkmn.name, newitemname))
      moved = true
      break
    end
    screen.scene.pbSelect(oldpkmnid) if !moved
  }
})

MenuHandlers.add(:party_menu, :relearner, {
  "name"      => _INTL("Cambiar movimientos"),
  "order"     => 60,
  "condition" => proc { |screen, party, party_idx|
    next false if !defined?(MENU_MOVERELEANER) || !MENU_MOVERELEANER
    next pbGetRelearnableMoves(party[party_idx]).length > 0
  },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    if pbGetRelearnableMoves(pkmn).length > 0
      pbRelearnMoveScreen(pkmn)
    end
    screen.pbRefresh
  }
})

MenuHandlers.add(:party_menu, :rename, {
  "name"      => _INTL("Cambiar nombre"),
  "order"     => 70,
  "condition" => proc { |screen, party, party_idx|
    next false if !defined?(MENU_NICKNAME) || !MENU_NICKNAME
    next !party[party_idx].isEgg?
  },
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    if pkmn.isEgg? || pkmn.isForeign?($Trainer)
      screen.pbDisplay(_INTL("¡No puedes cambiar el mote de este pokémon!"))
    else
      speciesname = PBSpecies.getName(pkmn.species)
      newname = pbEnterPokemonName(_INTL("Mote de {1}", speciesname), 0, 10, "", pkmn)
      pkmn.name = (newname == "") ? speciesname : newname
      screen.pbRefreshSingle(party_idx)
    end
  }
})

        
def pbPokemonScreen
  pbFadeOutIn {
    sscene = PokemonParty_Scene.new
    sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
    sscreen.pbPokemonScreen
  }
end

