class PokeSelectionPlaceholderSprite < SpriteWrapper
  attr_accessor :text

  def initialize(pokemon,index,viewport=nil)
    super(viewport)
    xvalues=[0,256,0,256,0,256]
    yvalues=[0,16,96,112,192,208]
    @pbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelBlank")
    self.bitmap=@pbitmap.bitmap
    self.x=xvalues[index]
    self.y=yvalues[index]
    @text=nil
  end

  def update
    super
    @pbitmap.update
    self.bitmap=@pbitmap.bitmap
  end

  def selected
    return false
  end

  def selected=(value)
  end

  def preselected
    return false
  end

  def preselected=(value)
  end

  def switching
    return false
  end

  def switching=(value)
  end

  def refresh
  end

  def dispose
    @pbitmap.dispose
    super
  end
end



class PokeSelectionConfirmCancelSprite < SpriteWrapper
  attr_reader :selected

  def initialize(text,x,y,narrowbox=false,viewport=nil)
    super(viewport)
    @refreshBitmap=true
    @bgsprite=ChangelingSprite.new(0,0,viewport)
    if narrowbox
      @bgsprite.addBitmap("deselbitmap","Graphics/#{PARTY_ROUTE}/partyCancelNarrow")
      @bgsprite.addBitmap("selbitmap","Graphics/#{PARTY_ROUTE}/partyCancelSelNarrow")
    else
      @bgsprite.addBitmap("deselbitmap","Graphics/#{PARTY_ROUTE}/partyCancel")
      @bgsprite.addBitmap("selbitmap","Graphics/#{PARTY_ROUTE}/partyCancelSel")
    end

    @bgsprite.changeBitmap("deselbitmap")
    @overlaysprite=BitmapSprite.new(@bgsprite.bitmap.width,@bgsprite.bitmap.height,viewport)
    @yoffset=8
    ynarrow=narrowbox ? -6 : 0
    pbSetSystemFont(@overlaysprite.bitmap)
    textpos=[[text,56,8+ynarrow,2,Color.new(248,248,248),Color.new(40,40,40)]]
    pbDrawTextPositions(@overlaysprite.bitmap,textpos)
    @overlaysprite.z=self.z+1 # For compatibility with RGSS2
    self.x=x
    self.y=y
  end

  def dispose
    @overlaysprite.bitmap.dispose
    @overlaysprite.dispose
    @bgsprite.dispose
    super
  end

  def viewport=(value)
    super
    refresh
  end

  def color=(value)
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

  def selected=(value)
    @selected=value
    refresh
  end

  def refresh
    @bgsprite.changeBitmap((@selected) ? "selbitmap" : "deselbitmap")
    if @bgsprite && !@bgsprite.disposed?
      @bgsprite.x=self.x
      @bgsprite.y=self.y
      @overlaysprite.x=self.x
      @overlaysprite.y=self.y
      @bgsprite.color=self.color
      @overlaysprite.color=self.color
    end
  end
end



class PokeSelectionCancelSprite < PokeSelectionConfirmCancelSprite
  def initialize(viewport=nil)
    super(_INTL("SALIR"),398,328,false,viewport)
  end
end



class PokeSelectionConfirmSprite < PokeSelectionConfirmCancelSprite
  def initialize(viewport=nil)
    super(_INTL("CONFIRMAR"),398,308,true,viewport)
  end
end



class PokeSelectionCancelSprite2 < PokeSelectionConfirmCancelSprite
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



class PokeSelectionSprite < SpriteWrapper
  attr_reader :selected
  attr_reader :preselected
  attr_reader :switching
  attr_reader :pokemon
  attr_reader :active
  attr_accessor :text

  def initialize(pokemon,index,viewport=nil)
    super(viewport)
    @pokemon=pokemon
    active=(index==0)
    @active=active
    if active # Rounded panel
      @deselbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRound")
      @selbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRoundSel")
      @deselfntbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRoundFnt")
      @selfntbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRoundSelFnt")
      @deselswapbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRoundSwap")
      @selswapbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRoundSelSwap")
    else # Rectangular panel
      @deselbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRect")
      @selbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRectSel")
      @deselfntbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRectFnt")
      @selfntbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRectSelFnt")
      @deselswapbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRectSwap")
      @selswapbitmap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyPanelRectSelSwap")
    end
    @spriteXOffset=28
    @spriteYOffset=0
    @pokeballXOffset=10
    @pokeballYOffset=0
    @pokenameX=96
    @pokenameY=16
    @levelX=20
    @levelY=62
    @statusX=80
    @statusY=68
    @genderX=224
    @genderY=16
    @hpX=224
    @hpY=60
    @hpbarX=96
    @hpbarY=50
    @gaugeX=128
    @gaugeY=52
    @itemXOffset=62
    @itemYOffset=48
    @annotX=96
    @annotY=58
    xvalues=[0,256,0,256,0,256]
    yvalues=[0,16,96,112,192,208]
    @text=nil
    @statuses=AnimatedBitmap.new(_INTL("Graphics/Pictures/statuses"))
    @hpbar=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyHP")
    @hpbarfnt=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyHPfnt")
    @hpbarswap=AnimatedBitmap.new("Graphics/#{PARTY_ROUTE}/partyHPswap")
    @pokeballsprite=ChangelingSprite.new(0,0,viewport)
    @pokeballsprite.addBitmap("pokeballdesel","Graphics/#{PARTY_ROUTE}/partyBall")
    @pokeballsprite.addBitmap("pokeballsel","Graphics/#{PARTY_ROUTE}/partyBallSel")
    @pkmnsprite=PokemonIconSprite.new(pokemon,viewport)
    @pkmnsprite.active=active
    @itemsprite=ChangelingSprite.new(0,0,viewport)
    @itemsprite.addBitmap("itembitmap","Graphics/Pictures/item")
    @itemsprite.addBitmap("mailbitmap","Graphics/Pictures/mail")
    @spriteX=xvalues[index]
    @spriteY=yvalues[index]
    @refreshBitmap=true
    @refreshing=false
    @preselected=false
    @switching=false
    @pkmnsprite.z=self.z+2 # For compatibility with RGSS2
    @itemsprite.z=self.z+3 # For compatibility with RGSS2
    @pokeballsprite.z=self.z+1 # For compatibility with RGSS2
    self.selected=false
    self.x=@spriteX
    self.y=@spriteY
    refresh
  end

  def dispose
    @selbitmap.dispose
    @statuses.dispose
    @hpbar.dispose
    @deselbitmap.dispose
    @itemsprite.dispose
    @pkmnsprite.dispose
    @pokeballsprite.dispose
    self.bitmap.dispose
    super
  end

  def selected=(value)
    @selected=value
    @refreshBitmap=true
    refresh
  end

  def text=(value)
    @text=value
    @refreshBitmap=true
    refresh
  end

  def pokemon=(value)
    @pokemon=value
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.pokemon=value
    end
    @refreshBitmap=true
    refresh
  end

  def preselected=(value)
    if value!=@preselected
      @preselected=value
      refresh
    end
  end

  def switching=(value)
    if value!=@switching
      @switching=value
      refresh
    end
  end

  def color=(value)
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

  def hp
    return @pokemon.hp
  end

  def refresh
    return if @refreshing
    return if disposed?
    @refreshing=true
    if !self.bitmap || self.bitmap.disposed?
      self.bitmap=BitmapWrapper.new(@selbitmap.width,@selbitmap.height)
    end
    if @pkmnsprite && !@pkmnsprite.disposed?
      @pkmnsprite.x=self.x+@spriteXOffset
      @pkmnsprite.y=self.y+@spriteYOffset
      @pkmnsprite.color=pbSrcOver(@pkmnsprite.color,self.color)
      @pkmnsprite.selected=self.selected
    end
    if @pokeballsprite && !@pokeballsprite.disposed?
      @pokeballsprite.x=self.x+@pokeballXOffset
      @pokeballsprite.y=self.y+@pokeballYOffset
      @pokeballsprite.color=self.color
      @pokeballsprite.changeBitmap(self.selected ? "pokeballsel" : "pokeballdesel")
    end
    if @itemsprite && !@itemsprite.disposed?
      @itemsprite.visible=(@pokemon.item>0)
      if @itemsprite.visible
        @itemsprite.changeBitmap(@pokemon.mail ? "mailbitmap" : "itembitmap")
        @itemsprite.x=self.x+@itemXOffset
        @itemsprite.y=self.y+@itemYOffset
        @itemsprite.color=self.color
      end
    end
    if @refreshBitmap
      @refreshBitmap=false
      self.bitmap.clear if self.bitmap
      if self.selected
        if self.preselected
          self.bitmap.blt(0,0,@selswapbitmap.bitmap,Rect.new(0,0,@selswapbitmap.width,@selswapbitmap.height))
          self.bitmap.blt(0,0,@deselswapbitmap.bitmap,Rect.new(0,0,@deselswapbitmap.width,@deselswapbitmap.height))
        elsif @switching
          self.bitmap.blt(0,0,@selswapbitmap.bitmap,Rect.new(0,0,@selswapbitmap.width,@selswapbitmap.height))
        elsif @pokemon.hp<=0 && !@pokemon.isEgg?
          self.bitmap.blt(0,0,@selfntbitmap.bitmap,Rect.new(0,0,@selfntbitmap.width,@selfntbitmap.height))
        else
          self.bitmap.blt(0,0,@selbitmap.bitmap,Rect.new(0,0,@selbitmap.width,@selbitmap.height))
        end
      else
        if self.preselected
          self.bitmap.blt(0,0,@deselswapbitmap.bitmap,Rect.new(0,0,@deselswapbitmap.width,@deselswapbitmap.height))
        elsif @pokemon.hp<=0 && !@pokemon.isEgg?
          self.bitmap.blt(0,0,@deselfntbitmap.bitmap,Rect.new(0,0,@deselfntbitmap.width,@deselfntbitmap.height))
        else
          self.bitmap.blt(0,0,@deselbitmap.bitmap,Rect.new(0,0,@deselbitmap.width,@deselbitmap.height))
        end
      end
      base=Color.new(248,248,248)
      shadow=Color.new(40,40,40)
      pbSetSystemFont(self.bitmap)
      pokename=@pokemon.name
      textpos=[[pokename,@pokenameX,@pokenameY,0,base,shadow]]
      if !@pokemon.isEgg?
        if !@text || @text.length==0
          tothp=@pokemon.totalhp
          textpos.push([_ISPRINTF("{1: 3d}/{2: 3d}",@pokemon.hp,tothp),
             @hpX,@hpY,1,base,shadow])
          barbg=(@pokemon.hp<=0) ? @hpbarfnt : @hpbar
          barbg=(self.preselected || (self.selected && @switching)) ? @hpbarswap : barbg
          self.bitmap.blt(@hpbarX,@hpbarY,barbg.bitmap,Rect.new(0,0,@hpbar.width,@hpbar.height))
          hpgauge=@pokemon.totalhp==0 ? 0 : (self.hp*96/@pokemon.totalhp)
          hpgauge=1 if hpgauge==0 && self.hp>0
          hpzone=0
          hpzone=1 if self.hp<=(@pokemon.totalhp/2).floor
          hpzone=2 if self.hp<=(@pokemon.totalhp/4).floor
          hpcolors=[
             Color.new(24,192,32),Color.new(96,248,96),   # Green
             Color.new(232,168,0),Color.new(248,216,0),   # Orange
             Color.new(248,72,56),Color.new(248,152,152)  # Red
          ]
          # fill with HP color
          self.bitmap.fill_rect(@gaugeX,@gaugeY,hpgauge,2,hpcolors[hpzone*2])
          self.bitmap.fill_rect(@gaugeX,@gaugeY+2,hpgauge,4,hpcolors[hpzone*2+1])
          self.bitmap.fill_rect(@gaugeX,@gaugeY+6,hpgauge,2,hpcolors[hpzone*2])
          if @pokemon.hp==0 || @pokemon.status>0
            status=(@pokemon.hp==0) ? 5 : @pokemon.status-1
            statusrect=Rect.new(0,16*status,44,16)
            self.bitmap.blt(@statusX,@statusY,@statuses.bitmap,statusrect)
          end
        end
        if @pokemon.isMale?
          textpos.push([_INTL("♂"),@genderX,@genderY,0,Color.new(0,112,248),Color.new(120,184,232)])
        elsif @pokemon.isFemale?
          textpos.push([_INTL("♀"),@genderX,@genderY,0,Color.new(232,32,16),Color.new(248,168,184)])
        end
      end
      pbDrawTextPositions(self.bitmap,textpos)
      if !@pokemon.isEgg?
        pbSetSmallFont(self.bitmap)
        leveltext=[([_INTL("Nv.{1}",@pokemon.level),@levelX,@levelY,0,base,shadow])]
        pbDrawTextPositions(self.bitmap,leveltext)
      end
      if @text && @text.length>0
        pbSetSystemFont(self.bitmap)
        annotation=[[@text,@annotX,@annotY,0,base,shadow]]
        pbDrawTextPositions(self.bitmap,annotation)
      end
    end
    @refreshing=false
  end

  def update
    super
    @pokeballsprite.update if @pokeballsprite && !@pokeballsprite.disposed?
    @itemsprite.update if @itemsprite && !@itemsprite.disposed?
    if @pkmnsprite && !@pkmnsprite.disposed?
      if @pkmnsprite.pokemon.isTera?
        @pkmnsprite.tone=TERATONES[@pkmnsprite.pokemon.teratype] if @pkmnsprite.pokemon.isTera?
      else
        @pkmnsprite.tone=Tone.new(0,0,0,0)
      end
      @pkmnsprite.update
    end
  end
end


##############################


class PokemonScreen_Scene
  def pbShowCommands(helptext,commands,index=0)
    ret = -1
    helpwindow = @sprites["helpwindow"]
    helpwindow.visible = true
    using(cmdwindow = Window_CommandPokemonColor.new(commands)) {
      cmdwindow.z     = @viewport.z+1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
       helpwindow.text=""
      helpwindow.resizeHeightToFit(helptext,Graphics.width-cmdwindow.width)
      helpwindow.text = helptext
      pbBottomLeft(helpwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        self.update
        if Input.trigger?(Input::B)
           pbPlayCancelSE()
          ret = -1
          break
         end
        if Input.trigger?(Input::C)
           pbPlayDecisionSE()
          ret = cmdwindow.index
          break
        end
      end
    }
    return ret
  end


  def update
    pbUpdateSpriteHash(@sprites)
  end

  def pbSetHelpText(helptext)
    helpwindow=@sprites["helpwindow"]
    pbBottomLeftLines(helpwindow,1)
    helpwindow.text=helptext
    helpwindow.width=398
    helpwindow.visible=true
  end

  def pbStartScene(party,starthelptext,annotations=nil,multiselect=false)
    @sprites={}
    @party=party
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @multiselect=multiselect

    @sprites["partybg"]=IconSprite.new(0,0,@viewport)
    @sprites["partybg"].setBitmap("Graphics/#{PARTY_ROUTE}/partybg")
    #addBackgroundPlane(@sprites,"partybg","partybg",@viewport)
    @sprites["messagebox"]=Window_AdvancedTextPokemon.new("")
    @sprites["helpwindow"]=Window_UnformattedTextPokemon.new(starthelptext)
    @sprites["messagebox"].viewport=@viewport
    @sprites["messagebox"].visible=false
    @sprites["messagebox"].letterbyletter=true
    @sprites["helpwindow"].viewport=@viewport
    @sprites["helpwindow"].visible=true
    pbBottomLeftLines(@sprites["messagebox"],2)
    pbBottomLeftLines(@sprites["helpwindow"],1)
    pbSetHelpText(starthelptext)
    # Add party Pokémon sprites
    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"]=PokeSelectionSprite.new(
           @party[i],i,@viewport)
      else
        @sprites["pokemon#{i}"]=PokeSelectionPlaceholderSprite.new(
           @party[i],i,@viewport)
      end
      if annotations
        @sprites["pokemon#{i}"].text=annotations[i]
      end
    end
    if @multiselect
      @sprites["pokemon6"]=PokeSelectionConfirmSprite.new(@viewport)
      @sprites["pokemon7"]=PokeSelectionCancelSprite2.new(@viewport)
    else
      @sprites["pokemon6"]=PokeSelectionCancelSprite.new(@viewport)
    end
    # Select first Pokémon
    @activecmd=0
    @sprites["pokemon0"].selected=true
    pbFadeInAndShow(@sprites) { update }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbChangeSelection(key,currentsel)
    numsprites=(@multiselect) ? 8 : 7
    case key
    when Input::LEFT
      begin
        currentsel-=1
      end while currentsel>0 && currentsel<@party.length && !@party[currentsel]
      if currentsel>=@party.length && currentsel<6
        currentsel=@party.length-1
      end
      currentsel=numsprites-1 if currentsel<0
    when Input::RIGHT
      begin
        currentsel+=1
      end while currentsel<@party.length && !@party[currentsel]
      if currentsel==@party.length
        currentsel=6
      elsif currentsel==numsprites
        currentsel=0
      end
    when Input::UP
      if currentsel>=6
        begin
          currentsel-=1
        end while currentsel>0 && !@party[currentsel]
      else
        begin
          currentsel-=2
        end while currentsel>0 && !@party[currentsel]
      end
      if currentsel>=@party.length && currentsel<6
        currentsel=@party.length-1
      end
      currentsel=numsprites-1 if currentsel<0
    when Input::DOWN
      if currentsel>=5
        currentsel+=1
      else
        currentsel+=2
        currentsel=6 if currentsel<6 && !@party[currentsel]
      end
      if currentsel>=@party.length && currentsel<6
        currentsel=6
      elsif currentsel>=numsprites
        currentsel=0
      end
    end
    return currentsel
  end

  def pbRefresh
    for i in 0...6
      sprite=@sprites["pokemon#{i}"]
      if sprite
        if sprite.is_a?(PokeSelectionSprite)
          sprite.pokemon=sprite.pokemon
        else
          sprite.refresh
        end
      end
    end
  end

  def pbRefreshSingle(i)
    sprite=@sprites["pokemon#{i}"]
    if sprite
      if sprite.is_a?(PokeSelectionSprite)
        sprite.pokemon=sprite.pokemon
      else
        sprite.refresh
      end
    end
  end

  def pbHardRefresh
    oldtext=[]
    lastselected=-1
    for i in 0...6
      oldtext.push(@sprites["pokemon#{i}"].text)
      lastselected=i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end
    lastselected=@party.length-1 if lastselected>=@party.length
    lastselected=0 if lastselected<0
    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"]=PokeSelectionSprite.new(
        @party[i],i,@viewport)
      else
        @sprites["pokemon#{i}"]=PokeSelectionPlaceholderSprite.new(
        @party[i],i,@viewport)
      end
      @sprites["pokemon#{i}"].text=oldtext[i]
    end
    pbSelect(lastselected)
  end

  def pbPreSelect(pkmn)
    @activecmd=pkmn
  end

  def pbChoosePokemon(switching=false,initialsel=-1)
    for i in 0...6
      @sprites["pokemon#{i}"].preselected=(switching && i==@activecmd)
      @sprites["pokemon#{i}"].switching=switching
    end
    @activecmd=initialsel if initialsel>=0
    pbRefresh
    loop do
      Graphics.update
      Input.update
      self.update
      oldsel=@activecmd
      key=-1
      key=Input::DOWN if Input.repeat?(Input::DOWN)
      key=Input::RIGHT if Input.repeat?(Input::RIGHT)
      key=Input::LEFT if Input.repeat?(Input::LEFT)
      key=Input::UP if Input.repeat?(Input::UP)
      if key>=0
        @activecmd=pbChangeSelection(key,@activecmd)
      end
      if @activecmd!=oldsel # Changing selection
        pbPlayCursorSE()
        numsprites=(@multiselect) ? 8 : 7
        for i in 0...numsprites
          @sprites["pokemon#{i}"].selected=(i==@activecmd)
        end
      end
      if Input.trigger?(Input::B)
        return -1
      end
      if Input.trigger?(Input::C)
        pbPlayDecisionSE()
        cancelsprite=(@multiselect) ? 7 : 6
        return (@activecmd==cancelsprite) ? -1 : @activecmd
      end
    end
  end

  def pbSelect(item)
    @activecmd=item
    numsprites=(@multiselect) ? 8 : 7
    for i in 0...numsprites
      @sprites["pokemon#{i}"].selected=(i==@activecmd)
    end
  end

  def pbDisplay(text)
    @sprites["messagebox"].text=text
    @sprites["messagebox"].visible=true
    @sprites["helpwindow"].visible=false
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      self.update
      if @sprites["messagebox"].busy? && Input.trigger?(Input::C)
        pbPlayDecisionSE() if @sprites["messagebox"].pausing?
        @sprites["messagebox"].resume
      end
      if !@sprites["messagebox"].busy? &&
         (Input.trigger?(Input::C) || Input.trigger?(Input::B))
        break
      end
    end
    @sprites["messagebox"].visible=false
    @sprites["helpwindow"].visible=true
  end

  def pbSwitchBegin(oldid,newid)
    pbSEPlay("GUI party switch")
    oldsprite=@sprites["pokemon#{oldid}"]
    newsprite=@sprites["pokemon#{newid}"]
    22.times do
      oldsprite.x+=(oldid&1)==0 ? -12 : 12
      newsprite.x+=(newid&1)==0 ? -12 : 12
      Graphics.update
      Input.update
      self.update
    end
  end

  def pbSwitchEnd(oldid,newid)
    pbSEPlay("GUI party switch")
    oldsprite=@sprites["pokemon#{oldid}"]
    newsprite=@sprites["pokemon#{newid}"]
    oldsprite.pokemon=@party[oldid]
    newsprite.pokemon=@party[newid]
    22.times do
      oldsprite.x-=(oldid&1)==0 ? -12 : 12
      newsprite.x-=(newid&1)==0 ? -12 : 12
      Graphics.update
      Input.update
      self.update
    end
    for i in 0...6
      @sprites["pokemon#{i}"].preselected=false
      @sprites["pokemon#{i}"].switching=false
    end
    pbRefresh
  end

  def pbDisplayConfirm(text)
    ret=-1
    @sprites["messagebox"].text=text
    @sprites["messagebox"].visible=true
    @sprites["helpwindow"].visible=false
    using(cmdwindow=Window_CommandPokemon.new([_INTL("Sí"),_INTL("No")])){
       cmdwindow.z=@viewport.z+1
       cmdwindow.visible=false
       pbBottomRight(cmdwindow)
       cmdwindow.y-=@sprites["messagebox"].height
       loop do
         Graphics.update
         Input.update
         cmdwindow.visible=true if !@sprites["messagebox"].busy?
         cmdwindow.update
         self.update
         if Input.trigger?(Input::B) && !@sprites["messagebox"].busy?
           ret=false
           break
         end
         if Input.trigger?(Input::C) && @sprites["messagebox"].resume && !@sprites["messagebox"].busy?
           ret=(cmdwindow.index==0)
           break
         end
       end
    }
    @sprites["messagebox"].visible=false
    @sprites["helpwindow"].visible=true
    return ret
  end

  def pbAnnotate(annot)
    for i in 0...6
      if annot
        @sprites["pokemon#{i}"].text=annot[i]
      else
        @sprites["pokemon#{i}"].text=nil
      end
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
end


######################################


class PokemonScreen
  def initialize(scene,party)
    @party=party
    @scene=scene
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

  def pbSwitch(oldid,newid)
    if oldid!=newid
      @scene.pbSwitchBegin(oldid,newid)
      tmp=@party[oldid]
      @party[oldid]=@party[newid]
      @party[newid]=tmp
      @scene.pbSwitchEnd(oldid,newid)
    end
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

  def pbPokemonGiveScreen(item)
    @scene.pbStartScene(@party,_INTL("¿Dar a qué Pokémon?"))
    pkmnid=@scene.pbChoosePokemon
    ret=false
    if pkmnid>=0
      ret=pbGiveMail(item,@party[pkmnid],pkmnid)
    end
    pbRefreshSingle(pkmnid)
    @scene.pbEndScene
    return ret
  end

  def pbPokemonGiveMailScreen(mailIndex)
    @scene.pbStartScene(@party,_INTL("¿Dar a qué Pokémon?"))
    pkmnid=@scene.pbChoosePokemon
    if pkmnid>=0
      pkmn=@party[pkmnid]
      if pkmn.item!=0 || pkmn.mail
        pbDisplay(_INTL("Este Pokémon ya lleva un objeto. No puede llevar una carta."))
      elsif pkmn.isEgg?
        pbDisplay(_INTL("Los Huevos no pueden llevar una carta."))
      else
        pbDisplay(_INTL("La carta ha sido transferida desde la casilla."))
        pkmn.mail=$PokemonGlobal.mailbox[mailIndex]
        pkmn.setItem(pkmn.mail.item)
        $PokemonGlobal.mailbox.delete_at(mailIndex)
        pbRefreshSingle(pkmnid)
      end
    end
    @scene.pbEndScene
  end

  def pbStartScene(helptext,doublebattle,annotations=nil)
    @scene.pbStartScene(@party,helptext,annotations)
  end

  def pbChoosePokemon(helptext=nil)
    @scene.pbSetHelpText(helptext) if helptext
    return @scene.pbChoosePokemon
  end

  def pbChooseMove(pokemon,helptext)
    movenames=[]
    for i in pokemon.moves
      break if i.id==0
      if i.totalpp==0
        movenames.push(_INTL("{1} (PP: ---)",PBMoves.getName(i.id),i.pp,i.totalpp))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})",PBMoves.getName(i.id),i.pp,i.totalpp))
      end
    end
    return @scene.pbShowCommands(helptext,movenames)
  end

  def pbEndScene
    @scene.pbEndScene
  end

  # Checks for identical species
  def pbCheckSpecies(array)
    for i in 0...array.length
      for j in i+1...array.length
        return false if array[i].species==array[j].species
      end
    end
    return true
  end

# Checks for identical held items
  def pbCheckItems(array)
    for i in 0...array.length
      next if !array[i].hasItem?
      for j in i+1...array.length
        return false if array[i].item==array[j].item
      end
    end
    return true
  end

  def pbPokemonMultipleEntryScreenEx(ruleset)
    annot=[]
    statuses=[]
    ordinals=[
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
    ret=nil
    addedEntry=false
    for i in 0...@party.length
      if ruleset.isPokemonValid?(@party[i])
        statuses[i]=1
      else
        statuses[i]=2
      end
    end
    for i in 0...@party.length
      annot[i]=ordinals[statuses[i]]
    end
    @scene.pbStartScene(@party,_INTL("Elige un Pokémon y confirma."),annot,true)
    loop do
      realorder=[]
      for i in 0...@party.length
        for j in 0...@party.length
          if statuses[j]==i+3
            realorder.push(j)
            break
          end
        end
      end
      for i in 0...realorder.length
        statuses[realorder[i]]=i+3
      end
      for i in 0...@party.length
        annot[i]=ordinals[statuses[i]]
      end
      @scene.pbAnnotate(annot)
      if realorder.length==ruleset.number && addedEntry
        @scene.pbSelect(6)
      end
      @scene.pbSetHelpText(_INTL("Elige un Pokémon y confirma."))
      pkmnid=@scene.pbChoosePokemon
      addedEntry=false
      if pkmnid==6 # Confirm was chosen
        ret=[]
        for i in realorder
          ret.push(@party[i])
        end
        error=[]
        if !ruleset.isValid?(ret,error)
          pbDisplay(error[0])
          ret=nil
        else
          break
        end
      end
      if pkmnid<0 # Canceled
        break
      end
      cmdEntry=-1
      cmdNoEntry=-1
      cmdSummary=-1
      commands=[]
      if (statuses[pkmnid] || 0) == 1
        commands[cmdEntry=commands.length]=_INTL("Participa")
      elsif (statuses[pkmnid] || 0) > 2
        commands[cmdNoEntry=commands.length]=_INTL("No participa")
      end
      pkmn=@party[pkmnid]
      commands[cmdSummary=commands.length]=_INTL("Datos")
      commands[commands.length]=_INTL("Salir")
      command=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),commands) if pkmn
      if cmdEntry>=0 && command==cmdEntry
        if realorder.length>=ruleset.number && ruleset.number>0
          pbDisplay(_INTL("No pueden participar más de {1} Pokémon.",ruleset.number))
        else
          statuses[pkmnid]=realorder.length+3
          addedEntry=true
          pbRefreshSingle(pkmnid)
        end
      elsif cmdNoEntry>=0 && command==cmdNoEntry
        statuses[pkmnid]=1
        pbRefreshSingle(pkmnid)
      elsif cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid)
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbChooseAblePokemon(ableProc,allowIneligible=false)
    annot=[]
    eligibility=[]
    for pkmn in @party
      elig=ableProc.call(pkmn)
      eligibility.push(elig)
      annot.push(elig ? _INTL("PUEDE") : _INTL("NO PUEDE"))
    end
    ret=-1
    @scene.pbStartScene(@party,
       @party.length>1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."),annot)
    loop do
      @scene.pbSetHelpText(
         @party.length>1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
      pkmnid=@scene.pbChoosePokemon
      if pkmnid<0
        break
      elsif !eligibility[pkmnid] && !allowIneligible
        pbDisplay(_INTL("Este Pokémon no puede ser elegido."))
      else
        ret=pkmnid
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbRefreshAnnotations(ableProc)   # For after using an evolution stone
    annot=[]
    for pkmn in @party
      elig=ableProc.call(pkmn)
      annot.push(elig ? _INTL("PUEDE") : _INTL("NO PUEDE"))
    end
    @scene.pbAnnotate(annot)
  end

  def pbClearAnnotations
    @scene.pbAnnotate(nil)
  end

  def pbPokemonScreen
    @scene.pbStartScene(@party,@party.length>1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."),nil)
    loop do
      @scene.pbSetHelpText(@party.length>1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
      pkmnid=@scene.pbChoosePokemon
      break if pkmnid<0
      pkmn=@party[pkmnid]
      commands   = []
      cmdSummary = -1
      cmdDebug   = -1
      cmdMoves   = [-1,-1,-1,-1]
      cmdSwitch  = -1
      cmdMail    = -1
      cmdItem    = -1
      cmdRelearner = -1
      cmdRename    = -1

      # Build the commands
      commands[cmdSummary=commands.length]      = _INTL("Datos")
      commands[cmdDebug=commands.length]        = _INTL("Depurador") if $DEBUG
      for i in 0...pkmn.moves.length
        move=pkmn.moves[i]
        # Check for hidden moves and add any that were found
        if !pkmn.isEgg? && (isConst?(move.id,PBMoves,:MILKDRINK) ||
                            isConst?(move.id,PBMoves,:SOFTBOILED) ||
                            HiddenMoveHandlers.hasHandler(move.id))
          commands[cmdMoves[i]=commands.length] = [PBMoves.getName(move.id),1]
        end
      end

      commands[cmdSwitch=commands.length]       = _INTL("Mover") if @party.length>1
      if !pkmn.isEgg?
        if pkmn.mail
          commands[cmdMail=commands.length]     = _INTL("Carta")
        else
          commands[cmdItem=commands.length]     = _INTL("Objeto")
        end
      end

      if pbGetRelearnableMoves(pkmn).length>0 && MENU_MOVERELEANER
       commands[cmdRelearner = commands.length]   = _INTL("Cambiar movimientos")
       end
      if MENU_NICKNAME
        commands[cmdRename = commands.length]= _INTL("Cambiar nombre") if !pkmn.isEgg?
      end

      commands[commands.length]                 = _INTL("Salir")
      command=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),commands)

      havecommand=false
      for i in 0...4
        if cmdMoves[i]>=0 && command==cmdMoves[i]
          havecommand=true
          if isConst?(pkmn.moves[i].id,PBMoves,:SOFTBOILED) ||
             isConst?(pkmn.moves[i].id,PBMoves,:MILKDRINK)
            amt=[(pkmn.totalhp/5).floor,1].max
            if pkmn.hp<=amt
              pbDisplay(_INTL("No tiene PS suficientes..."))
              break
            end
            @scene.pbSetHelpText(_INTL("¿En cuál Pokémon usarlo?"))
            oldpkmnid=pkmnid
            loop do
              @scene.pbPreSelect(oldpkmnid)
              pkmnid=@scene.pbChoosePokemon(true,pkmnid)
              break if pkmnid<0
              newpkmn=@party[pkmnid]
              if pkmnid==oldpkmnid
                pbDisplay(_INTL("¡{1} no puede usar {2} en sí mismo!",pkmn.name,PBMoves.getName(pkmn.moves[i].id)))
              elsif newpkmn.isEgg?
                pbDisplay(_INTL("¡{1} no puede usarse en un Huevo!",PBMoves.getName(pkmn.moves[i].id)))
              elsif newpkmn.hp==0 || newpkmn.hp==newpkmn.totalhp
                pbDisplay(_INTL("{1} no puede usarse en ese Pokémon.",PBMoves.getName(pkmn.moves[i].id)))
              else
                pkmn.hp-=amt
                hpgain=pbItemRestoreHP(newpkmn,amt)
                @scene.pbDisplay(_INTL("{1} recuperó {2} puntos de salud.",newpkmn.name,hpgain))
                pbRefresh
              end
              break if pkmn.hp<=amt
            end
            break
          elsif Kernel.pbCanUseHiddenMove?(pkmn,pkmn.moves[i].id)
            @scene.pbEndScene
            if isConst?(pkmn.moves[i].id,PBMoves,:FLY)
              scene=PokemonRegionMapScene.new(-1,false)
              screen=PokemonRegionMap.new(scene)
              ret=screen.pbStartFlyScreen
              if ret
                $PokemonTemp.flydata=ret
                return [pkmn,pkmn.moves[i].id]
              end
              @scene.pbStartScene(@party,
                 @party.length>1 ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
              break
            end
            return [pkmn,pkmn.moves[i].id]
          else
            break
          end
        end
      end
      next if havecommand

      if cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid)
      elsif cmdDebug>=0 && command==cmdDebug
        pbPokemonDebug(pkmn,pkmnid)
      elsif cmdRelearner>=0 && command==cmdRelearner
       if pbGetRelearnableMoves(pkmn).length>0
         pbRelearnMoveScreen(pkmn)
       end
       pbRefresh
      elsif cmdRename>=0 && command==cmdRename
       if pkmn.isEgg? || pkmn.isForeign?($Trainer)
          pbDisplay(_INTL("¡No puedes cambiar el mote de este pokémon!"))
         else
          speciesname=PBSpecies.getName(pkmn.species)
          newname=pbEnterPokemonName(_INTL("Mote de {1}",speciesname),0,10,"",pkmn)
          pkmn.name=(newname=="") ? speciesname : newname
          pbRefreshSingle(pkmnid)
        end
      elsif cmdSwitch>=0 && command==cmdSwitch
        @scene.pbSetHelpText(_INTL("¿A qué posición mover?"))
        oldpkmnid=pkmnid
        pkmnid=@scene.pbChoosePokemon(true)
        if pkmnid>=0 && pkmnid!=oldpkmnid
          pbSwitch(oldpkmnid,pkmnid)
        end
      elsif cmdMail>=0 && command==cmdMail
        command=@scene.pbShowCommands(_INTL("¿Qué quieres hacer con la carta?"),
           [_INTL("Leer"),_INTL("Quitar"),_INTL("Salir")])
        case command
        when 0 # Read
          pbFadeOutIn(99999){
             pbDisplayMail(pkmn.mail,pkmn)
          }
        when 1 # Take
          pbTakeMail(pkmn)
          pbRefreshSingle(pkmnid)
        end
      elsif cmdItem>=0 && command==cmdItem
        itemcommands = []
        cmdUseItem   = -1
        cmdGiveItem  = -1
        cmdTakeItem  = -1
        cmdMoveItem  = -1
        # Build the commands
        itemcommands[cmdUseItem=itemcommands.length]  = _INTL("Usar")
        itemcommands[cmdGiveItem=itemcommands.length] = _INTL("Dar")
        itemcommands[cmdTakeItem=itemcommands.length] = _INTL("Quitar") if pkmn.hasItem?
        itemcommands[cmdMoveItem=itemcommands.length] = _INTL("Mover") if pkmn.hasItem? && !pbIsMail?(pkmn.item)
        itemcommands[itemcommands.length]             = _INTL("Salir")
        command=@scene.pbShowCommands(_INTL("¿Qué quieres hacer con él?"),itemcommands)
        if cmdUseItem>=0 && command==cmdUseItem   # Use
          item=@scene.pbUseItem($PokemonBag,pkmn)
          if item>0
            pbUseItemOnPokemon(item,pkmn,self)
            pbRefreshSingle(pkmnid)
          end
        elsif cmdGiveItem>=0 && command==cmdGiveItem   # Give
          item=@scene.pbChooseItem($PokemonBag)
          if item>0
            pbGiveMail(item,pkmn,pkmnid)
            pbRefreshSingle(pkmnid)
          end
        elsif cmdTakeItem>=0 && command==cmdTakeItem   # Take
          pbTakeMail(pkmn)
          pbRefreshSingle(pkmnid)
        elsif cmdMoveItem>=0 && command==cmdMoveItem   # Move
          item=pkmn.item
          itemname=PBItems.getName(item)
          @scene.pbSetHelpText(_INTL("¿A qué Pokémon quieres darle {1}?",itemname))
          oldpkmnid=pkmnid
          loop do
            @scene.pbPreSelect(oldpkmnid)
            pkmnid=@scene.pbChoosePokemon(true,pkmnid)
            break if pkmnid<0
            newpkmn=@party[pkmnid]
            if pkmnid==oldpkmnid
              break
            elsif newpkmn.isEgg?
              pbDisplay(_INTL("Un Huevo no puede llevar un objeto."))
            elsif !newpkmn.hasItem?
              newpkmn.setItem(item)
              pkmn.setItem(0)
              pbRefresh
              pbDisplay(_INTL("Le has dado {2} a {1}.",newpkmn.name,itemname))
              break
            elsif pbIsMail?(newpkmn.item)
              pbDisplay(_INTL("Debes tomar la carta de {1} antes de darle otro objeto.",newpkmn.name))
            else
              newitem=newpkmn.item
              newitemname=PBItems.getName(newitem)
              pbDisplay(_INTL("{1} ya está llevando {2}.\1",newpkmn.name,newitemname))
              if pbConfirm(_INTL("¿Quieres intercambiar estos objetos?"))
                newpkmn.setItem(item)
                pkmn.setItem(newitem)
                pbRefresh
                pbDisplay(_INTL("Le has dado {2} a {1}.",newpkmn.name,itemname))
                pbDisplay(_INTL("Le has dado {2} a {1}.",pkmn.name,newitemname))
                break
              end
            end
          end
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end

#BES-T Colores en los comandos del menú :D
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
    pbDrawShadowText(self.contents,rect.x,rect.y,rect.width,rect.height,
       @commands[index],base,shadow)
  end
end
