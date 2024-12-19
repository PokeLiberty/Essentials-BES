def findBottom(bitmap)
  return 0 if !bitmap
  for i in 1..bitmap.height
    for j in 0..bitmap.width-1
      return bitmap.height-i if bitmap.get_pixel(j,bitmap.height-i).alpha>0
    end
  end
  return 0
end

def pbAutoPositionAll()
  metrics=load_data("Data/metrics.dat")
  for i in 1..PBSpecies.maxValue
    Graphics.update if i%50==0
    bitmap1=AnimatedBitmap.new(sprintf("Graphics/Battlers/%03db",i))
    bitmap2=AnimatedBitmap.new(sprintf("Graphics/Battlers/%03d",i))
    if bitmap1 && bitmap1.bitmap
      metrics[0][i]=(bitmap1.height-(findBottom(bitmap1.bitmap)+1))/2
    end
    if bitmap2 && bitmap2.bitmap
      metrics[1][i]=2+(bitmap2.height-(findBottom(bitmap2.bitmap)+1))/2
      metrics[1][i]+=(160-bitmap2.height)/4
    end
    bitmap1.dispose if bitmap1
    bitmap2.dispose if bitmap2
  end
  save_data(metrics,"Data/metrics.dat")
  pbSavePokemonData()
end



class SpritePositioner
  def update
    pbUpdateSpriteHash(@sprites)
  end

  def refresh
    if !@pkmn
      @sprites["pokemon0"].visible=false
      @sprites["pokemon1"].visible=false
      @sprites["shadow1"].visible=false
      return
    end
    pbPositionPokemonSprite(@sprites["pokemon0"],
                            PokeBattle_SceneConstants::PLAYERBATTLER_X-64,0)
    @sprites["pokemon0"].y=PokeBattle_SceneConstants::PLAYERBATTLER_Y
    @sprites["pokemon0"].y+=adjustBattleSpriteY(@sprites["pokemon0"],@pkmn.species,0,@metrics)
    @sprites["pokemon0"].visible=true
    pbPositionPokemonSprite(@sprites["pokemon1"],
                            PokeBattle_SceneConstants::FOEBATTLER_X-64,0)
    @sprites["pokemon1"].y=PokeBattle_SceneConstants::FOEBATTLER_Y
    @sprites["pokemon1"].y+=adjustBattleSpriteY(@sprites["pokemon1"],@pkmn.species,1,@metrics)
    @sprites["pokemon1"].visible=true
    @sprites["shadow1"].visible=(@metrics[2][@pkmn.species]>0)
  end

  def pbSaveMetrics
    save_data(@metrics,"Data/metrics.dat")
    pbSavePokemonData()
  end

  def pbAutoPosition
    oldmetric0=@metrics[0][@pkmn.species]
    oldmetric1=@metrics[1][@pkmn.species]
    bitmap1=@sprites["pokemon0"].bitmap
    bitmap2=@sprites["pokemon1"].bitmap
    newmetric0=(bitmap1.height-(findBottom(bitmap1)+1))/2
    newmetric1=2+(bitmap2.height-(findBottom(bitmap2)+1))/2
    newmetric1+=(160-bitmap2.height)/4
    if newmetric0!=oldmetric0 || newmetric1!=oldmetric1
      @metrics[0][@pkmn.species]=newmetric0
      @metrics[1][@pkmn.species]=newmetric1
      @metricsChanged=true
      refresh
    end
  end

  def pbSetParameter(param)
    return if !@pkmn
    if param==3
      pbAutoPosition()
      return
    end
    sprite=(param==0) ? @sprites["pokemon0"] : @sprites["pokemon1"]
    altitude=@metrics[param][@pkmn.species]
    oldaltitude=altitude
    @sprites["info"].visible=true
    loop do
      sprite.visible=(Graphics.frame_count%15)<12
      Graphics.update
      Input.update
      self.update
      @sprites["info"].setTextToFit(_ISPRINTF("{1:d}",altitude))
      if Input.repeat?(Input::UP)
        altitude=(param==2) ? altitude+1 : altitude-1
        altitude=[altitude,0].max if param==2
        @metrics[param][@pkmn.species]=altitude
        refresh
      elsif Input.repeat?(Input::DOWN)
        altitude=(param==2) ? altitude-1 : altitude+1
        altitude=[altitude,0].max if param==2
        @metrics[param][@pkmn.species]=altitude
        refresh
      end
      if Input.repeat?(Input::B)
        @metrics[param][@pkmn.species]=oldaltitude
        pbPlayCancelSE()
        refresh
        break
      end
      if Input.repeat?(Input::C)
        @metricsChanged=true
        pbPlayDecisionSE()
        break
      end
    end
    @sprites["info"].visible=false
    sprite.visible=true
  end

  def pbClose
    if @metricsChanged
      pbSaveMetrics
      @metricsChanged=false
    end
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbChangeSpecies(species)
    @pkmn=(species<=0) ? nil : PokeBattle_Pokemon.new(species,1)
    @sprites["pokemon0"].setPokemonBitmap(@pkmn,true)
    @sprites["pokemon1"].setPokemonBitmap(@pkmn,false)
  end

  def pbSpecies
    if @starting
      pbFadeInAndShow(@sprites) { update }
      @starting=false
    end
    cw=Window_CommandPokemonEx.newEmpty(0,0,260,160,@viewport)
    cw.x=Graphics.width-cw.width
    cw.y=Graphics.height-cw.height
    allspecies=[]
    commands=[]
    for i in 1..PBSpecies.maxValue
      name=PBSpecies.getName(i)
      if name!=""
        allspecies.push([i,name])
      end
    end
    allspecies.sort!{|a,b| a[1]==b[1] ? a[0]<=>b[0] : a[1]<=>b[1] }
    for s in allspecies
      commands.push(_INTL("{1} - {2}",s[0],s[1]))
    end
    cw.commands=commands
    cw.index=@oldSpeciesIndex
    species=0
    oldindex=-1
    loop do
      Graphics.update
      Input.update
      cw.update
      if cw.index!=oldindex
        oldindex=cw.index
        pbChangeSpecies(allspecies[cw.index][0])
        refresh
      end
      self.update
      if Input.trigger?(Input::C)
        pbChangeSpecies(allspecies[cw.index][0])
        species=allspecies[cw.index][0]
        break
      end
      if Input.trigger?(Input::B)
        pbChangeSpecies(0)
        refresh
        break
      end
    end
    @oldSpeciesIndex=cw.index
    cw.dispose 
    return species
  end

  def pbMenu(species)
    pbChangeSpecies(species)
    refresh
    cw=Window_CommandPokemon.new([
       _INTL("Set Ally Position"),
       _INTL("Set Enemy Position"),
       _INTL("Set Enemy Altitude"),
       _INTL("Auto-Position Sprites")
    ])
    cw.x=Graphics.width-cw.width
    cw.y=Graphics.height-cw.height
    cw.viewport=@viewport
    ret=-1
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::C)
        pbPlayDecisionSE()
        ret=cw.index
        break
      end
      if Input.trigger?(Input::B)
        pbPlayCancelSE()
        break
      end
    end
    cw.dispose
    return ret
  end

  def pbOpen
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    battlebg="Graphics/Battlebacks/battlebgIndoorA"
    enemybase="Graphics/Battlebacks/enemybaseIndoorA"
    playerbase="Graphics/Battlebacks/playerbaseIndoorA"
    @sprites["battlebg"]=AnimatedPlane.new(@viewport)
    @sprites["battlebg"].setBitmap(battlebg)
    @sprites["playerbase"]=IconSprite.new(
       PokeBattle_SceneConstants::PLAYERBASEX,
       PokeBattle_SceneConstants::PLAYERBASEY,@viewport)
    @sprites["playerbase"].setBitmap(playerbase)
    @sprites["playerbase"].x-=@sprites["playerbase"].bitmap.width/2 if @sprites["playerbase"].bitmap!=nil
    @sprites["playerbase"].y-=@sprites["playerbase"].bitmap.height if @sprites["playerbase"].bitmap!=nil
    @sprites["enemybase"]=IconSprite.new(
       PokeBattle_SceneConstants::FOEBASEX,
       PokeBattle_SceneConstants::FOEBASEY,@viewport)
    @sprites["enemybase"].setBitmap(enemybase)
    @sprites["enemybase"].x-=@sprites["enemybase"].bitmap.width/2 if @sprites["enemybase"].bitmap!=nil
    @sprites["enemybase"].y-=@sprites["enemybase"].bitmap.height/2 if @sprites["enemybase"].bitmap!=nil
    @sprites["battlebg"].z=0
    @sprites["playerbase"].z=1
    @sprites["enemybase"].z=1
    @sprites["shadow1"]=IconSprite.new(
       PokeBattle_SceneConstants::FOEBATTLER_X,
       PokeBattle_SceneConstants::FOEBATTLER_Y,@viewport)
    @sprites["shadow1"].setBitmap("Graphics/Pictures/battleShadow")
    @sprites["shadow1"].x-=@sprites["shadow1"].bitmap.width/2 if @sprites["shadow1"].bitmap!=nil
    @sprites["shadow1"].y-=@sprites["shadow1"].bitmap.height/2 if @sprites["shadow1"].bitmap!=nil
    @sprites["shadow1"].z=3
    @sprites["shadow1"].visible=false
    @sprites["pokemon0"]=PokemonSprite.new(@viewport)
    @sprites["pokemon0"].z=21
    @sprites["pokemon1"]=PokemonSprite.new(@viewport)
    @sprites["pokemon1"].z=16
    @sprites["messagebox"]=IconSprite.new(0,Graphics.height-96,@viewport)
    @sprites["messagebox"].setBitmap("Graphics/Pictures/battleMessage")
    @sprites["messagebox"].z=90
    @sprites["messagebox"].visible=true
    @sprites["info"]=Window_UnformattedTextPokemon.new("")
    @sprites["info"].viewport=@viewport
    @sprites["info"].visible=false
    @oldSpeciesIndex=0
    @species=0
    @pkmn=nil
    @metrics=load_data("Data/metrics.dat")
    @metricsChanged=false
    refresh
    @starting=true
  end
end



class SpritePositionerScreen
  def initialize(scene)
    @scene=scene
  end

  def pbStart
    @scene.pbOpen
    loop do
      species=@scene.pbSpecies
      break if species<=0
      loop do
        command=@scene.pbMenu(species)
        break if command<0
        @scene.pbSetParameter(command)
      end
    end
    @scene.pbClose
  end
end