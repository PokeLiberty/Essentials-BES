=begin
-  def pbChooseNewEnemy(index,party)
Use this method to choose a new Pokémon for the enemy
The enemy's party is guaranteed to have at least one
choosable member.
index - Index to the battler to be replaced (use e.g. @battle.battlers[index] to
access the battler)
party - Enemy's party

- def pbWildBattleSuccess
This method is called when the player wins a wild Pokémon battle.
This method can change the battle's music for example.

- def pbTrainerBattleSuccess
This method is called when the player wins a Trainer battle.
This method can change the battle's music for example.

- def pbFainted(pkmn)
This method is called whenever a Pokémon faints.
pkmn - PokeBattle_Battler object indicating the Pokémon that fainted

- def pbChooseEnemyCommand(index)
Use this method to choose a command for the enemy.
index - Index of enemy battler (use e.g. @battle.battlers[index] to
access the battler)

- def pbCommandMenu(index)
Use this method to display the list of commands and choose
a command for the player.
index - Index of battler (use e.g. @battle.battlers[index] to
access the battler)
Return values:
0 - Fight
1 - Pokémon
2 - Bag
3 - Run
=end
#===============================================================================
# Battle scene (the visuals of the battle)
#===============================================================================
class PokeBattle_Scene
  attr_accessor :abortable
  attr_reader :viewport
  attr_reader :sprites
  BLANK      = 0
  MESSAGEBOX = 1
  COMMANDBOX = 2
  FIGHTBOX   = 3

  def initialize
    @battle=nil
    @lastcmd=[0,0,0,0]
    @lastmove=[0,0,0,0]
    @pkmnwindows=[nil,nil,nil,nil]
    @sprites={}
    @battlestart=true
    @messagemode=false
    @messagemode2=false
    @abortable=false
    @aborted=false
  end

  def pbUpdate
    partyAnimationUpdate
    @sprites["battlebg"].update if @sprites["battlebg"].respond_to?("update")
  end

  def pbGraphicsUpdate
    partyAnimationUpdate
    @sprites["battlebg"].update if @sprites["battlebg"].respond_to?("update")
    Graphics.update
  end

  def pbInputUpdate
    Input.update
    if Input.trigger?(Input::B) && @abortable && !@aborted
      @aborted=true
      @battle.pbAbort
    end
  end

  def pbShowWindow(windowtype)
    @sprites["messagebox"].visible = (windowtype==MESSAGEBOX ||
                                      windowtype==COMMANDBOX ||
                                      windowtype==FIGHTBOX ||
                                      windowtype==BLANK )
    @sprites["messagewindow"].visible = (windowtype==MESSAGEBOX)
    @sprites["commandwindow"].visible = (windowtype==COMMANDBOX)
    @sprites["fightwindow"].visible = (windowtype==FIGHTBOX)
  end

  def pbSetMessageMode(mode)
    @messagemode=mode
    msgwindow=@sprites["messagewindow"]
    if mode # Within Pokémon command
      msgwindow.baseColor=PokeBattle_SceneConstants::MENUBASECOLOR
      msgwindow.shadowColor=PokeBattle_SceneConstants::MENUSHADOWCOLOR
      msgwindow.opacity=255
      msgwindow.x=16
      msgwindow.width=Graphics.width
      msgwindow.height=96
      msgwindow.y=Graphics.height-msgwindow.height+2
    else
      msgwindow.baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
      msgwindow.shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
      msgwindow.opacity=0
      msgwindow.x=16
      msgwindow.width=Graphics.width-32
      msgwindow.height=96
      msgwindow.y=Graphics.height-msgwindow.height+2
    end
  end

  def pbSetMessageMode2(mode)
    @messagemode2=mode
    msgwindow=@sprites["messagewindow"]
    if mode # Within Pokémon command
      msgwindow.baseColor=PokeBattle_SceneConstants::MENUBASECOLOR
      msgwindow.shadowColor=PokeBattle_SceneConstants::MENUSHADOWCOLOR
      msgwindow.opacity=255
      msgwindow.x=16
      msgwindow.width=Graphics.width
      msgwindow.height=96
      msgwindow.y=Graphics.height-msgwindow.height+2
    else
      msgwindow.baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
      msgwindow.shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
      msgwindow.opacity=0
      msgwindow.x=16
      msgwindow.width=Graphics.width-32
      msgwindow.height=96
      msgwindow.y=Graphics.height-msgwindow.height+2
    end
  end

  def pbWaitMessage
    if @briefmessage
      pbShowWindow(MESSAGEBOX)
      cw=@sprites["messagewindow"]
      60.times do
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate(cw)
      end
      cw.text=""
      cw.visible=false
      @briefmessage=false
    end
  end

  def pbDisplay(msg,brief=false)
    pbDisplayMessage(msg,brief)
  end

  def pbDisplayMessage(msg,brief=false)
    pbWaitMessage
    pbRefresh
    pbShowWindow(MESSAGEBOX)
    cw=@sprites["messagewindow"]
    cw.text=msg
    i=0
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate(cw)
      if i==40
        cw.text=""
        cw.visible=false
        return
      end
      if Input.trigger?(Input::C) || @abortable
        if cw.pausing?
          pbPlayDecisionSE() if !@abortable
          cw.resume
        end
      end
      if !cw.busy?
        if brief
          @briefmessage=true
          return
        end
        i+=1
      end
    end
  end

  def pbDisplayPausedMessage(msg)
    pbWaitMessage
    pbRefresh
    pbShowWindow(MESSAGEBOX)
    if @messagemode
      @switchscreen.pbDisplay(msg)
      return
    end
    if @messagemode2
      @revivalscreen.pbDisplay(msg)
      return
    end
    cw=@sprites["messagewindow"]
    cw.text=_INTL("{1}\1",msg)
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate(cw)
      if Input.trigger?(Input::C) || @abortable
        if cw.busy?
          pbPlayDecisionSE() if cw.pausing? && !@abortable
          cw.resume
        elsif !inPartyAnimation?
          cw.text=""
          pbPlayDecisionSE()
          cw.visible=false if @messagemode
          cw.visible=false if @messagemode2
          return
        end
      end
      cw.update
    end
  end

  def pbDisplayConfirmMessage(msg)
    return pbShowCommands(msg,[_INTL("Sí"),_INTL("No")],1)==0
  end

  def pbShowCommands(msg,commands,defaultValue)
    pbWaitMessage
    pbRefresh
    pbShowWindow(MESSAGEBOX)
    dw=@sprites["messagewindow"]
    dw.text=msg
    cw = Window_CommandPokemon.new(commands)
    cw.x=Graphics.width-cw.width
    cw.y=Graphics.height-cw.height-dw.height
    cw.index=0
    cw.viewport=@viewport
    pbRefresh
    loop do
      cw.visible=!dw.busy?
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate(cw)
      dw.update
      if Input.trigger?(Input::B) && defaultValue>=0
        if dw.busy?
          pbPlayDecisionSE() if dw.pausing?
          dw.resume
        else
          cw.dispose
          dw.text=""
          return defaultValue
        end
      end
      if Input.trigger?(Input::C)
        if dw.busy?
          pbPlayDecisionSE() if dw.pausing?
          dw.resume
        else
          cw.dispose
          dw.text=""
          return cw.index
        end
      end
    end
  end

  def pbFrameUpdate(cw=nil)
    cw.update if cw
    for i in 0...4
      if @sprites["battlebox#{i}"]
        @sprites["battlebox#{i}"].update
      end
      if @sprites["pokemon#{i}"]
        @sprites["pokemon#{i}"].update
      end
      if (@battle.battlers[i].isTera? rescue false)
        @sprites["pokemon#{i}"].tone=TERATONES[@battle.battlers[i].pokemon.teratype]
      end
    end
  end

  def pbRefresh
    for i in 0...4
      if @sprites["battlebox#{i}"]
        @sprites["battlebox#{i}"].refresh
      end
    end
  end

  def pbAddSprite(id,x,y,filename,viewport)
    sprite=IconSprite.new(x,y,viewport)
    if filename
      sprite.setBitmap(filename) rescue nil
    end
    @sprites[id]=sprite
    return sprite
  end

  def pbAddPlane(id,filename,viewport)
    sprite=AnimatedPlane.new(viewport)
    if filename
      sprite.setBitmap(filename)
    end
    @sprites[id]=sprite
    return sprite
  end

  def pbDisposeSprites
    pbDisposeSpriteHash(@sprites)
  end

  def pbBeginCommandPhase
    # Called whenever a new round begins.
    @battlestart=false
  end
  
  def pbShowOpponent(index)
    if @battle.opponent
      if @battle.opponent.is_a?(Array)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[index].trainertype)
      else
        trainerfile=pbTrainerSpriteFile(@battle.opponent.trainertype)
      end
    else
      trainerfile="Graphics/Characters/trfront"
    end
    pbAddSprite("trainer",Graphics.width,PokeBattle_SceneConstants::FOETRAINER_Y,
       trainerfile,@viewport)
    if @sprites["trainer"].bitmap
      @sprites["trainer"].y-=@sprites["trainer"].bitmap.height
      @sprites["trainer"].z=8
    end
    20.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      @sprites["trainer"].x-=6
    end
  end

  def pbHideOpponent
    20.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      @sprites["trainer"].x+=6
    end
  end
  
  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text,Graphics.width)
    @sprites["helpwindow"].y=0
    @sprites["helpwindow"].x=0
    @sprites["helpwindow"].text=text
    @sprites["helpwindow"].visible=true
  end

  def pbHideHelp
    @sprites["helpwindow"].visible=false
  end

  def pbBackdrop
    environ=@battle.environment
    # Choose backdrop
    backdrop="Field"
    if environ==PBEnvironment::Cave
      backdrop="Cave"
    elsif environ==PBEnvironment::MovingWater || environ==PBEnvironment::StillWater
      backdrop="Water"
    elsif environ==PBEnvironment::Underwater
      backdrop="Underwater"
    elsif environ==PBEnvironment::Rock
      backdrop="Mountain"
    else
      if !$game_map || !pbGetMetadata($game_map.map_id,MetadataOutdoor)
        backdrop="IndoorA"
      end
    end
    if $game_map
      back=pbGetMetadata($game_map.map_id,MetadataBattleBack)
      if back && back!=""
        backdrop=back
      end
    end
    if $PokemonGlobal && $PokemonGlobal.nextBattleBack
      backdrop=$PokemonGlobal.nextBattleBack
    end
    backdrop = $PokemonTemp.battle_rules["backdrop"] || backdrop
    # Choose bases
    base=""
    trialname=""
    if environ==PBEnvironment::Grass || environ==PBEnvironment::TallGrass
      trialname="Grass"
    elsif environ==PBEnvironment::Sand
      trialname="Sand"
    elsif $PokemonGlobal.surfing
      trialname="Water"
    end
    trialname = $PokemonTemp.battle_rules["base"] || trialname
    if pbResolveBitmap(sprintf("Graphics/Battlebacks/playerbase"+backdrop+trialname))
      base=trialname
    end
    # Choose time of day
    time=""
    if ENABLESHADING
      trialname=""
      timenow=pbGetTimeNow
      if PBDayNight.isNight?(timenow)
        trialname="Night"
      elsif PBDayNight.isEvening?(timenow)
        trialname="Eve"
      end
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/battlebg"+backdrop+trialname))
        time=trialname
      end
    end
    # Apply graphics
    battlebg="Graphics/Battlebacks/battlebg"+backdrop+time
    enemybase="Graphics/Battlebacks/enemybase"+backdrop+base+time
    playerbase="Graphics/Battlebacks/playerbase"+backdrop+base+time
    pbAddPlane("battlebg",battlebg,@viewport)
    pbAddSprite("playerbase",
       PokeBattle_SceneConstants::PLAYERBASEX,
       PokeBattle_SceneConstants::PLAYERBASEY,playerbase,@viewport)
    @sprites["playerbase"].x-=@sprites["playerbase"].bitmap.width/2 if @sprites["playerbase"].bitmap!=nil
    @sprites["playerbase"].y-=@sprites["playerbase"].bitmap.height if @sprites["playerbase"].bitmap!=nil
    pbAddSprite("enemybase",
       PokeBattle_SceneConstants::FOEBASEX,
       PokeBattle_SceneConstants::FOEBASEY,enemybase,@viewport)
    @sprites["enemybase"].x-=@sprites["enemybase"].bitmap.width/2 if @sprites["enemybase"].bitmap!=nil
    @sprites["enemybase"].y-=@sprites["enemybase"].bitmap.height/2 if @sprites["enemybase"].bitmap!=nil
    @sprites["battlebg"].z=0
    @sprites["playerbase"].z=1
    @sprites["enemybase"].z=1
  end

  # Returns whether the party line-ups are currently appearing on-screen
  def inPartyAnimation?
    return @enablePartyAnim && @partyAnimPhase<3
  end

  def partyAnimationRestart(doublePreviewTop)
    @doublePreviewTop=doublePreviewTop
    yvalue=114
    yvalue-=72 if doublePreviewTop
    pbAddSprite("partybarfoe",-400,yvalue,"Graphics/#{BATTLE_ROUTE}/battleLineup",@viewport)
    @sprites["partybarfoe"].visible=true
    @partyAnimPhase=0
  end

  def partyAnimationFade
    frame=0
    while(frame<24)
      if @partyAnimPhase!=3
        pbGraphicsUpdate
        next
      end
      frame+=1
      @sprites["partybarfoe"].x+=8
      @sprites["partybarfoe"].opacity-=12
      for i in 0...6
        partyI = i
        @sprites["enemy#{partyI}"].opacity-=12
        @sprites["enemy#{partyI}"].x+=8 if frame >= i*4
      end
      pbGraphicsUpdate
    end
    for i in 0...6
      partyI = i
      pbDisposeSprite(@sprites,"player#{partyI}")
    end
    pbDisposeSprite(@sprites,"partybarfoe")
  end

  # Shows the party line-ups appearing on-screen
  def partyAnimationUpdate
    return if !inPartyAnimation?
    ballmovedist=16 # How far a ball moves each frame
    # Bar slides on
    if @partyAnimPhase==0
      @sprites["partybarfoe"].x+=16
      @sprites["partybarplayer"].x-=16 if @sprites["partybarplayer"]
      if @sprites["partybarfoe"].x+@sprites["partybarfoe"].bitmap.width>=PokeBattle_SceneConstants::FOEPARTYBAR_X
        @sprites["partybarfoe"].x=PokeBattle_SceneConstants::FOEPARTYBAR_X-@sprites["partybarfoe"].bitmap.width
        @sprites["partybarplayer"].x=PokeBattle_SceneConstants::PLAYERPARTYBAR_X if @sprites["partybarplayer"]
        @partyAnimPhase=1
      end
      return
    end
    # Set up all balls ready to slide on
    if @partyAnimPhase==1
      @xposplayer=PokeBattle_SceneConstants::PLAYERPARTYBALL1_X
      counter=0
      # Make sure the ball starts off-screen
      while @xposplayer<Graphics.width
        counter+=1; @xposplayer+=ballmovedist
      end
      @xposenemy=PokeBattle_SceneConstants::FOEPARTYBALL1_X-counter*ballmovedist
      for i in 0...6
        # Choose the ball's graphic (player's side)
        ballgraphic="Graphics/#{BATTLE_ROUTE}/ballempty"
        if i<@battle.party1.length && @battle.party1[i]
          if @battle.party1[i].hp<=0 || @battle.party1[i].isEgg?
            ballgraphic="Graphics/#{BATTLE_ROUTE}/ballfainted"
          elsif @battle.party1[i].status>0
            ballgraphic="Graphics/#{BATTLE_ROUTE}/ballstatus"
          else
            ballgraphic="Graphics/#{BATTLE_ROUTE}/ballnormal"
          end
        end
        pbAddSprite("player#{i}",
           @xposplayer+i*ballmovedist*6,PokeBattle_SceneConstants::PLAYERPARTYBALL1_Y,
           ballgraphic,@viewport)
        @sprites["player#{i}"].z=41
        # Choose the ball's graphic (opponent's side)
        ballgraphic="Graphics/#{BATTLE_ROUTE}/ballempty"
        enemyindex=i
        if @battle.doublebattle && i>=3
          enemyindex=(i%3)+@battle.pbSecondPartyBegin(1)
        end
        if enemyindex<@battle.party2.length && @battle.party2[enemyindex]
          if @battle.party2[enemyindex].hp<=0 || @battle.party2[enemyindex].isEgg?
            ballgraphic="Graphics/#{BATTLE_ROUTE}/ballfainted"
          elsif @battle.party2[enemyindex].status>0
            ballgraphic="Graphics/#{BATTLE_ROUTE}/ballstatus"
          else
            ballgraphic="Graphics/#{BATTLE_ROUTE}/ballnormal"
          end
        end
        pbAddSprite("enemy#{i}",
           @xposenemy-i*ballmovedist*6,PokeBattle_SceneConstants::FOEPARTYBALL1_Y,
           ballgraphic,@viewport)
        @sprites["enemy#{i}"].y-=72 if @doublePreviewTop
        @sprites["enemy#{i}"].z=41
      end
      @partyAnimPhase=2
    end
    # Balls slide on
    if @partyAnimPhase==2
      for i in 0...6
        if @sprites["enemy#{i}"].x<PokeBattle_SceneConstants::FOEPARTYBALL1_X-i*PokeBattle_SceneConstants::FOEPARTYBALL_GAP
          @sprites["enemy#{i}"].x+=ballmovedist
          @sprites["player#{i}"].x-=ballmovedist if @sprites["partybarplayer"]
          if @sprites["enemy#{i}"].x>=PokeBattle_SceneConstants::FOEPARTYBALL1_X-i*PokeBattle_SceneConstants::FOEPARTYBALL_GAP
            @sprites["enemy#{i}"].x=PokeBattle_SceneConstants::FOEPARTYBALL1_X-i*PokeBattle_SceneConstants::FOEPARTYBALL_GAP
            @sprites["player#{i}"].x=PokeBattle_SceneConstants::PLAYERPARTYBALL1_X+i*PokeBattle_SceneConstants::PLAYERPARTYBALL_GAP
            if i==5
              @partyAnimPhase=3
            end
          end
        end
      end
    end
  end

  def pbStartBattle(battle)
    # Called whenever the battle begins
    @battle=battle
    @lastcmd=[0,0,0,0]
    @lastmove=[0,0,0,0]
    @showingplayer=true
    @showingenemy=true
    @sprites.clear
    @viewport=Viewport.new(0,Graphics.height/2,Graphics.width,0)
    @viewport.z=99999
    @traineryoffset=(Graphics.height-320) # Adjust player's side for screen size
    @foeyoffset=(@traineryoffset*3/4).floor  # Adjust foe's side for screen size
    pbBackdrop
    pbAddSprite("partybarfoe",
       PokeBattle_SceneConstants::FOEPARTYBAR_X,
       PokeBattle_SceneConstants::FOEPARTYBAR_Y,
       "Graphics/#{BATTLE_ROUTE}/battleLineup",@viewport)
    pbAddSprite("partybarplayer",
       PokeBattle_SceneConstants::PLAYERPARTYBAR_X,
       PokeBattle_SceneConstants::PLAYERPARTYBAR_Y,
       "Graphics/#{BATTLE_ROUTE}/battleLineup",@viewport)
    @sprites["partybarfoe"].x-=@sprites["partybarfoe"].bitmap.width
    @sprites["partybarplayer"].mirror=true
    @sprites["partybarfoe"].z=40
    @sprites["partybarplayer"].z=40
    @sprites["partybarfoe"].visible=false
    @sprites["partybarplayer"].visible=false
    if @battle.player.is_a?(Array)
      trainerfile=pbPlayerSpriteBackFile(@battle.player[0].trainertype)
      pbAddSprite("player",
           PokeBattle_SceneConstants::PLAYERTRAINERD1_X,
           PokeBattle_SceneConstants::PLAYERTRAINERD1_Y,trainerfile,@viewport)
      trainerfile=pbTrainerSpriteBackFile(@battle.player[1].trainertype)
      pbAddSprite("playerB",
           PokeBattle_SceneConstants::PLAYERTRAINERD2_X,
           PokeBattle_SceneConstants::PLAYERTRAINERD2_Y,trainerfile,@viewport)
      if @sprites["player"].bitmap
        if @sprites["player"].bitmap.width>@sprites["player"].bitmap.height
          @sprites["player"].src_rect.x=0
          @sprites["player"].src_rect.width=@sprites["player"].bitmap.width/5
        end
        @sprites["player"].x-=(@sprites["player"].src_rect.width/2)
        @sprites["player"].y-=@sprites["player"].bitmap.height
        @sprites["player"].z=30
      end
      if @sprites["playerB"].bitmap
        if @sprites["playerB"].bitmap.width>@sprites["playerB"].bitmap.height
          @sprites["playerB"].src_rect.x=0
          @sprites["playerB"].src_rect.width=@sprites["playerB"].bitmap.width/5
        end
        @sprites["playerB"].x-=(@sprites["playerB"].src_rect.width/2)
        @sprites["playerB"].y-=@sprites["playerB"].bitmap.height
        @sprites["playerB"].z=31
      end
    else
      trainerfile=pbPlayerSpriteBackFile(@battle.player.trainertype)
      pbAddSprite("player",
           PokeBattle_SceneConstants::PLAYERTRAINER_X,
           PokeBattle_SceneConstants::PLAYERTRAINER_Y,trainerfile,@viewport)
      if @sprites["player"].bitmap
        if @sprites["player"].bitmap.width>@sprites["player"].bitmap.height
          @sprites["player"].src_rect.x=0
          @sprites["player"].src_rect.width=@sprites["player"].bitmap.width/5
        end
        @sprites["player"].x-=(@sprites["player"].src_rect.width/2)
        @sprites["player"].y-=@sprites["player"].bitmap.height
        @sprites["player"].z=30
      end
    end
    if @battle.opponent
      if @battle.opponent.is_a?(Array)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[1].trainertype)
        pbAddSprite("trainer2",
           PokeBattle_SceneConstants::FOETRAINERD2_X,
           PokeBattle_SceneConstants::FOETRAINERD2_Y,trainerfile,@viewport)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[0].trainertype)
        pbAddSprite("trainer",
           PokeBattle_SceneConstants::FOETRAINERD1_X,
           PokeBattle_SceneConstants::FOETRAINERD1_Y,trainerfile,@viewport)
      else
        trainerfile=pbTrainerSpriteFile(@battle.opponent.trainertype)
        pbAddSprite("trainer",
           PokeBattle_SceneConstants::FOETRAINER_X,
           PokeBattle_SceneConstants::FOETRAINER_Y,trainerfile,@viewport)
      end
    else
      trainerfile="Graphics/Characters/trfront"
      pbAddSprite("trainer",
           PokeBattle_SceneConstants::FOETRAINER_X,
           PokeBattle_SceneConstants::FOETRAINER_Y,trainerfile,@viewport)
    end
    if @sprites["trainer"].bitmap
      @sprites["trainer"].x-=(@sprites["trainer"].bitmap.width/2)
      @sprites["trainer"].y-=@sprites["trainer"].bitmap.height
      @sprites["trainer"].z=8
    end
    if @sprites["trainer2"] && @sprites["trainer2"].bitmap
      @sprites["trainer2"].x-=(@sprites["trainer2"].bitmap.width/2)
      @sprites["trainer2"].y-=@sprites["trainer2"].bitmap.height
      @sprites["trainer2"].z=7
    end
    @sprites["shadow0"]=IconSprite.new(0,0,@viewport)
    @sprites["shadow0"].z=3
    pbAddSprite("shadow1",0,0,"Graphics/#{BATTLE_ROUTE}/battleShadow",@viewport)
    @sprites["shadow1"].z=3
    @sprites["shadow1"].visible=false
    @sprites["pokemon0"]=PokemonBattlerSprite.new(battle.doublebattle,0,@viewport)
    @sprites["pokemon0"].z=21
    @sprites["pokemon1"]=PokemonBattlerSprite.new(battle.doublebattle,1,@viewport)
    @sprites["pokemon1"].z=16
    if battle.doublebattle
      @sprites["shadow2"]=IconSprite.new(0,0,@viewport)
      @sprites["shadow2"].z=3
      pbAddSprite("shadow3",0,0,"Graphics/#{BATTLE_ROUTE}/battleShadow",@viewport)
      @sprites["shadow3"].z=3
      @sprites["shadow3"].visible=false
      @sprites["pokemon2"]=PokemonBattlerSprite.new(battle.doublebattle,2,@viewport)
      @sprites["pokemon2"].z=26
      @sprites["pokemon3"]=PokemonBattlerSprite.new(battle.doublebattle,3,@viewport)
      @sprites["pokemon3"].z=11
    end
    @sprites["battlebox0"]=PokemonDataBox.new(battle.battlers[0],battle.doublebattle,@viewport)
    @sprites["battlebox1"]=PokemonDataBox.new(battle.battlers[1],battle.doublebattle,@viewport)
    if battle.doublebattle
      @sprites["battlebox2"]=PokemonDataBox.new(battle.battlers[2],battle.doublebattle,@viewport)
      @sprites["battlebox3"]=PokemonDataBox.new(battle.battlers[3],battle.doublebattle,@viewport)
    end
    pbAddSprite("messagebox",0,Graphics.height-96,"Graphics/#{BATTLE_ROUTE}/battleMessage",@viewport)
    @sprites["messagebox"].z=90
    @sprites["helpwindow"]=Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["helpwindow"].visible=false
    @sprites["helpwindow"].z=90
    @sprites["messagewindow"]=Window_AdvancedTextPokemon.new("")
    @sprites["messagewindow"].letterbyletter=true
    @sprites["messagewindow"].viewport=@viewport
    @sprites["messagewindow"].z=100
    @sprites["commandwindow"]=CommandMenuDisplay.new(@viewport)
    @sprites["commandwindow"].z=100
    @sprites["fightwindow"]=FightMenuDisplay.new(nil,@viewport)
    @sprites["fightwindow"].z=100
    pbShowWindow(MESSAGEBOX)
    pbSetMessageMode(false)
    pbSetMessageMode2(false)
    trainersprite1=@sprites["trainer"]
    trainersprite2=@sprites["trainer2"]
    if !@battle.opponent
      @sprites["trainer"].visible=false
      if @battle.party2.length>=1
        if @battle.party2.length==1
          species=@battle.party2[0].species
          @sprites["pokemon1"].setPokemonBitmap(@battle.party2[0],false)
          @sprites["pokemon1"].tone=Tone.new(-128,-128,-128,-128)
          @sprites["pokemon1"].x=PokeBattle_SceneConstants::FOEBATTLER_X
          @sprites["pokemon1"].x-=@sprites["pokemon1"].width/2
          @sprites["pokemon1"].y=PokeBattle_SceneConstants::FOEBATTLER_Y
          @sprites["pokemon1"].y+=adjustBattleSpriteY(@sprites["pokemon1"],species,1)
          @sprites["pokemon1"].visible=true
          @sprites["shadow1"].x=PokeBattle_SceneConstants::FOEBATTLER_X
          @sprites["shadow1"].y=PokeBattle_SceneConstants::FOEBATTLER_Y
          @sprites["shadow1"].x-=@sprites["shadow1"].bitmap.width/2 if @sprites["shadow1"].bitmap!=nil
          @sprites["shadow1"].y-=@sprites["shadow1"].bitmap.height/2 if @sprites["shadow1"].bitmap!=nil
          @sprites["shadow1"].visible=showShadow?(species)
          trainersprite1=@sprites["pokemon1"]
        elsif @battle.party2.length==2
          species=@battle.party2[0].species
          @sprites["pokemon1"].setPokemonBitmap(@battle.party2[0],false)
          @sprites["pokemon1"].tone=Tone.new(-128,-128,-128,-128)
          @sprites["pokemon1"].x=PokeBattle_SceneConstants::FOEBATTLERD1_X
          @sprites["pokemon1"].x-=@sprites["pokemon1"].width/2
          @sprites["pokemon1"].y=PokeBattle_SceneConstants::FOEBATTLERD1_Y
          @sprites["pokemon1"].y+=adjustBattleSpriteY(@sprites["pokemon1"],species,1)
          @sprites["pokemon1"].visible=true
          @sprites["shadow1"].x=PokeBattle_SceneConstants::FOEBATTLERD1_X
          @sprites["shadow1"].y=PokeBattle_SceneConstants::FOEBATTLERD1_Y
          @sprites["shadow1"].x-=@sprites["shadow1"].bitmap.width/2 if @sprites["shadow1"].bitmap!=nil
          @sprites["shadow1"].y-=@sprites["shadow1"].bitmap.height/2 if @sprites["shadow1"].bitmap!=nil
          @sprites["shadow1"].visible=showShadow?(species)
          trainersprite1=@sprites["pokemon1"]
          species=@battle.party2[1].species
          @sprites["pokemon3"].setPokemonBitmap(@battle.party2[1],false)
          @sprites["pokemon3"].tone=Tone.new(-128,-128,-128,-128)
          @sprites["pokemon3"].x=PokeBattle_SceneConstants::FOEBATTLERD2_X
          @sprites["pokemon3"].x-=@sprites["pokemon3"].width/2
          @sprites["pokemon3"].y=PokeBattle_SceneConstants::FOEBATTLERD2_Y
          @sprites["pokemon3"].y+=adjustBattleSpriteY(@sprites["pokemon3"],species,3)
          @sprites["pokemon3"].visible=true
          @sprites["shadow3"].x=PokeBattle_SceneConstants::FOEBATTLERD2_X
          @sprites["shadow3"].y=PokeBattle_SceneConstants::FOEBATTLERD2_Y
          @sprites["shadow3"].x-=@sprites["shadow3"].bitmap.width/2 if @sprites["shadow3"].bitmap!=nil
          @sprites["shadow3"].y-=@sprites["shadow3"].bitmap.height/2 if @sprites["shadow3"].bitmap!=nil
          @sprites["shadow3"].visible=showShadow?(species)
          trainersprite2=@sprites["pokemon3"]
        end
      end
    end
    #################
    # Move trainers/bases/etc. off-screen
    oldx=[]
    oldx[0]=@sprites["playerbase"].x; @sprites["playerbase"].x+=Graphics.width
    oldx[1]=@sprites["player"].x; @sprites["player"].x+=Graphics.width
    if @sprites["playerB"]
      oldx[2]=@sprites["playerB"].x; @sprites["playerB"].x+=Graphics.width
    end
    oldx[3]=@sprites["enemybase"].x; @sprites["enemybase"].x-=Graphics.width
    oldx[4]=trainersprite1.x; trainersprite1.x-=Graphics.width
    if trainersprite2
      oldx[5]=trainersprite2.x; trainersprite2.x-=Graphics.width
    end
    oldx[6]=@sprites["shadow1"].x; @sprites["shadow1"].x-=Graphics.width
    if @sprites["shadow3"]
      oldx[7]=@sprites["shadow3"].x; @sprites["shadow3"].x-=Graphics.width
    end
    @sprites["partybarfoe"].x-=PokeBattle_SceneConstants::FOEPARTYBAR_X
    @sprites["partybarplayer"].x+=Graphics.width-PokeBattle_SceneConstants::PLAYERPARTYBAR_X
    #################
    appearspeed=12
    (1+Graphics.width/appearspeed).times do
      tobreak=true
      if @viewport.rect.y>0
        @viewport.rect.y-=appearspeed/2
        @viewport.rect.y=0 if @viewport.rect.y<0
        @viewport.rect.height+=appearspeed
        @viewport.rect.height=Graphics.height if @viewport.rect.height>Graphics.height
        tobreak=false
      end
      if !tobreak
        for i in @sprites
          i[1].ox=@viewport.rect.x
          i[1].oy=@viewport.rect.y
        end
      end
      if @sprites["playerbase"].x>oldx[0]
        @sprites["playerbase"].x-=appearspeed; tobreak=false
        @sprites["playerbase"].x=oldx[0] if @sprites["playerbase"].x<oldx[0]
      end
      if @sprites["player"].x>oldx[1]
        @sprites["player"].x-=appearspeed; tobreak=false
        @sprites["player"].x=oldx[1] if @sprites["player"].x<oldx[1]
      end
      if @sprites["playerB"] && @sprites["playerB"].x>oldx[2]
        @sprites["playerB"].x-=appearspeed; tobreak=false
        @sprites["playerB"].x=oldx[2] if @sprites["playerB"].x<oldx[2]
      end
      if @sprites["enemybase"].x<oldx[3]
        @sprites["enemybase"].x+=appearspeed; tobreak=false
        @sprites["enemybase"].x=oldx[3] if @sprites["enemybase"].x>oldx[3]
      end
      if trainersprite1.x<oldx[4]
        trainersprite1.x+=appearspeed; tobreak=false
        trainersprite1.x=oldx[4] if trainersprite1.x>oldx[4]
      end
      if trainersprite2 && trainersprite2.x<oldx[5]
        trainersprite2.x+=appearspeed; tobreak=false
        trainersprite2.x=oldx[5] if trainersprite2.x>oldx[5]
      end
      if @sprites["shadow1"].x<oldx[6]
        @sprites["shadow1"].x+=appearspeed; tobreak=false
        @sprites["shadow1"].x=oldx[6] if @sprites["shadow1"].x>oldx[6]
      end
      if @sprites["shadow3"] && @sprites["shadow3"].x<oldx[7]
        @sprites["shadow3"].x+=appearspeed; tobreak=false
        @sprites["shadow3"].x=oldx[7] if @sprites["shadow3"].x>oldx[7]
      end
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if tobreak
    end
    #################
    if @battle.opponent
      @enablePartyAnim=true
      @partyAnimPhase=0
      @sprites["partybarfoe"].visible=true
      @sprites["partybarplayer"].visible=true
    else
      pbPlayCry(@battle.party2[0])   # Play cry for wild Pokémon
      @sprites["battlebox1"].appear
      @sprites["battlebox3"].appear if @battle.party2.length==2
      appearing=true
      begin
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
        @sprites["pokemon1"].tone.red+=8 if @sprites["pokemon1"].tone.red<0
        @sprites["pokemon1"].tone.blue+=8 if @sprites["pokemon1"].tone.blue<0
        @sprites["pokemon1"].tone.green+=8 if @sprites["pokemon1"].tone.green<0
        @sprites["pokemon1"].tone.gray+=8 if @sprites["pokemon1"].tone.gray<0
        appearing=@sprites["battlebox1"].appearing
        if @battle.party2.length==2
          @sprites["pokemon3"].tone.red+=8 if @sprites["pokemon3"].tone.red<0
          @sprites["pokemon3"].tone.blue+=8 if @sprites["pokemon3"].tone.blue<0
          @sprites["pokemon3"].tone.green+=8 if @sprites["pokemon3"].tone.green<0
          @sprites["pokemon3"].tone.gray+=8 if @sprites["pokemon3"].tone.gray<0
          appearing=(appearing || @sprites["battlebox3"].appearing)
        end
      end while appearing
      # Show shiny animation for wild Pokémon
      if @battle.battlers[1].isShiny? && @battle.battlescene
        pbCommonAnimation("Shiny",@battle.battlers[1],nil)
      end
      if @battle.party2.length==2
        if @battle.battlers[3].isShiny? && @battle.battlescene
          pbCommonAnimation("Shiny",@battle.battlers[3],nil)
        end
      end
    end
  end

  def pbEndBattle(result)
    @abortable=false
    pbShowWindow(BLANK)
    # Fade out all sprites
    pbBGMFade(1.0)
    pbFadeOutAndHide(@sprites)
    pbDisposeSprites
  end

  def pbRecall(battlerindex)
    @briefmessage=false
    if @battle.pbIsOpposing?(battlerindex)
      origin=PokeBattle_SceneConstants::FOEBATTLER_Y
      if @battle.doublebattle
        origin=PokeBattle_SceneConstants::FOEBATTLERD1_Y if battlerindex==1
        origin=PokeBattle_SceneConstants::FOEBATTLERD2_Y if battlerindex==3
      end
      @sprites["shadow#{battlerindex}"].visible=false
    else
      origin=PokeBattle_SceneConstants::PLAYERBATTLER_Y
      if @battle.doublebattle
        origin=PokeBattle_SceneConstants::PLAYERBATTLERD1_Y if battlerindex==0
        origin=PokeBattle_SceneConstants::PLAYERBATTLERD2_Y if battlerindex==2
      end
    end
    spritePoke=@sprites["pokemon#{battlerindex}"]
    picturePoke=PictureEx.new(spritePoke.z)
    dims=[spritePoke.x,spritePoke.y]
    center=getSpriteCenter(spritePoke)
    # starting positions
    picturePoke.moveVisible(1,true)
    picturePoke.moveOrigin(1,PictureOrigin::Center)
    picturePoke.moveXY(0,1,center[0],center[1])
    # directives
    picturePoke.moveTone(10,1,Tone.new(248,248,248,248))
    delay=picturePoke.totalDuration
    picturePoke.moveSE(delay,"Audio/SE/recall")
    picturePoke.moveZoom(15,delay,0)
    picturePoke.moveXY(15,delay,center[0],origin)
    picturePoke.moveVisible(picturePoke.totalDuration,false)
    picturePoke.moveTone(0,picturePoke.totalDuration,Tone.new(0,0,0,0))
    picturePoke.moveOrigin(picturePoke.totalDuration,PictureOrigin::TopLeft)
    loop do
      picturePoke.update
      setPictureSprite(spritePoke,picturePoke)
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !picturePoke.running?
    end
  end

  def pbTrainerSendOut(battlerindex,pkmn)
    illusionpoke=@battle.battlers[battlerindex].effects[PBEffects::Illusion]
    @briefmessage=false
    fadeanim=nil
    while inPartyAnimation?; end
    if @showingenemy
      fadeanim=TrainerFadeAnimation.new(@sprites)
    end
    frame=0
    @sprites["pokemon#{battlerindex}"].setPokemonBitmap(pkmn,false)
    if illusionpoke
      @sprites["pokemon#{battlerindex}"].setPokemonBitmap(illusionpoke,false)
    end
    sendout=PokeballSendOutAnimation.new(@sprites["pokemon#{battlerindex}"],
       @sprites,@battle.battlers[battlerindex],illusionpoke,@battle.doublebattle)
    loop do
      fadeanim.update if fadeanim
      frame+=1
      if frame==1
        @sprites["battlebox#{battlerindex}"].appear
      end
      if frame>=10
        sendout.update
      end
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if (!fadeanim || fadeanim.animdone?) && sendout.animdone? &&
         !@sprites["battlebox#{battlerindex}"].appearing
    end
    if @battle.battlers[battlerindex].isShiny? && @battle.battlescene
      pbCommonAnimation("Shiny",@battle.battlers[battlerindex],nil)
    end
    sendout.dispose
    if @showingenemy
      @showingenemy=false
      pbDisposeSprite(@sprites,"trainer")
      pbDisposeSprite(@sprites,"partybarfoe")
      for i in 0...6
        pbDisposeSprite(@sprites,"enemy#{i}")
      end
    end
    pbRefresh
  end

  def pbSendOut(battlerindex,pkmn) # Player sending out Pokémon
    while inPartyAnimation?; end
    illusionpoke=@battle.battlers[battlerindex].effects[PBEffects::Illusion]
    balltype=pkmn.ballused
    balltype=illusionpoke.ballused if illusionpoke
    ballbitmap=sprintf("Graphics/#{BATTLE_ROUTE}/ball%02d",balltype)
    pictureBall=PictureEx.new(32)
    delay=1
    pictureBall.moveVisible(delay,true)
    pictureBall.moveName(delay,ballbitmap)
    pictureBall.moveOrigin(delay,PictureOrigin::Center)
    # Setting the ball's movement path
    path=[[0,   146], [10,  134], [21,  122], [30,  112],
          [39,  104], [46,   99], [53,   95], [61,   93],
          [68,   93], [75,   96], [82,  102], [89,  111],
          [94,  121], [100, 134], [106, 150], [111, 166],
          [116, 183], [120, 199], [124, 216], [127, 238]]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    angle=0
    multiplier=1.0
    if @battle.doublebattle
      multiplier=(battlerindex==0) ? 0.7 : 1.3
    end
    for coord in path
      delay=pictureBall.totalDuration
      pictureBall.moveAngle(0,delay,angle)
      pictureBall.moveXY(1,delay,coord[0]*multiplier,coord[1])
      angle+=40
      angle%=360
    end
    pictureBall.adjustPosition(0,@traineryoffset)
    @sprites["battlebox#{battlerindex}"].visible=false
    @briefmessage=false
    fadeanim=nil
    if @showingplayer
      fadeanim=PlayerFadeAnimation.new(@sprites)
    end
    frame=0
    @sprites["pokemon#{battlerindex}"].setPokemonBitmap(pkmn,true)
    if illusionpoke
      @sprites["pokemon#{battlerindex}"].setPokemonBitmap(illusionpoke,true)
    end
    sendout=PokeballPlayerSendOutAnimation.new(@sprites["pokemon#{battlerindex}"],
       @sprites,@battle.battlers[battlerindex],illusionpoke,@battle.doublebattle)
    loop do
      fadeanim.update if fadeanim
      frame+=1
      if frame>1 && !pictureBall.running? && !@sprites["battlebox#{battlerindex}"].appearing
        @sprites["battlebox#{battlerindex}"].appear
      end
      if frame>=3 && !pictureBall.running?
        sendout.update
      end
      if (frame>=10 || !fadeanim) && pictureBall.running?
        pictureBall.update
        setPictureIconSprite(spriteBall,pictureBall)
      end
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if (!fadeanim || fadeanim.animdone?) && sendout.animdone? &&
         !@sprites["battlebox#{battlerindex}"].appearing
    end
    spriteBall.dispose
    sendout.dispose
    if @battle.battlers[battlerindex].isShiny? && @battle.battlescene
      pbCommonAnimation("Shiny",@battle.battlers[battlerindex],nil)
    end
    if @showingplayer
      @showingplayer=false
      pbDisposeSprite(@sprites,"player")
      pbDisposeSprite(@sprites,"partybarplayer")
      for i in 0...6
        pbDisposeSprite(@sprites,"player#{i}")
      end
    end
    pbRefresh
  end

  def pbTrainerWithdraw(battle,pkmn)
    pbRefresh
  end

  def pbWithdraw(battle,pkmn)
    pbRefresh
  end

  def pbMoveString(move)
    ret=move.name
    typename=PBTypes.getName(move.type)
    if move.id>0
      ret+=_INTL(" ({1}) PP: {2}/{3}",typename,move.pp,move.totalpp)
    end
    return ret
  end

  def pbBeginAttackPhase
    pbSelectBattler(-1)
    pbGraphicsUpdate
  end

  def pbSafariStart
    @briefmessage=false
    @sprites["battlebox0"]=SafariDataBox.new(@battle,@viewport)
    @sprites["battlebox0"].appear
    loop do
      @sprites["battlebox0"].update
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !@sprites["battlebox0"].appearing
    end
    pbRefresh
  end

  def pbResetCommandIndices
    @lastcmd=[0,0,0,0]
  end

  def pbResetMoveIndex(index)
    @lastmove[index]=0
  end

  def pbSafariCommandMenu(index)
    pbCommandMenuEx(index,[
       _INTL("¿Qué hará {1}?",@battle.pbPlayer.name),
       _INTL("Ball"),
       _INTL("Cebo"),
       _INTL("Piedra"),
       _INTL("Huir")
    ],2)
  end


# Use this method to display the inventory
# The return value is the item chosen, or 0 if the choice was canceled.
  def pbItemMenu(index)
    ret=0
    retindex=-1
    pkmnid=-1
    endscene=true
    oldsprites=pbFadeOutAndHide(@sprites)
    itemscene=PokemonBag_Scene.new
    itemscene.pbStartScene($PokemonBag)
    loop do
      item=itemscene.pbChooseItem
      break if item==0
      usetype=$ItemData[item][ITEMBATTLEUSE]
      cmdUse=-1
      commands=[]
      if usetype==0
        commands[commands.length]=_INTL("Salir")
      else
        commands[cmdUse=commands.length]=_INTL("Usar")
        commands[commands.length]=_INTL("Salir")
      end
      itemname=PBItems.getName(item)
      command=itemscene.pbShowCommands(_INTL("{1} está seleccionado.",itemname),commands)
      if cmdUse>=0 && command==cmdUse
        if usetype==1 || usetype==3
          modparty=[]
          for i in 0...6
            modparty.push(@battle.party1[@battle.party1order[i]])
          end
          pkmnlist=PokemonScreen_Scene.new
          pkmnscreen=PokemonScreen.new(pkmnlist,modparty)
          itemscene.pbEndScene
          pkmnscreen.pbStartScene(_INTL("¿En qué Pokémon usarlo?"),@battle.doublebattle)
          activecmd=pkmnscreen.pbChoosePokemon
          pkmnid=@battle.party1order[activecmd]
          if activecmd>=0 && pkmnid>=0 && ItemHandlers.hasBattleUseOnPokemon(item)
            pkmnlist.pbEndScene
            ret=item
            retindex=pkmnid
            endscene=false
            break
          end
          pkmnlist.pbEndScene
          itemscene.pbStartScene($PokemonBag)
        elsif usetype==2 || usetype==4
          if ItemHandlers.hasBattleUseOnBattler(item)
            ret=item
            retindex=index
            break
          end
        end
      end
    end
    pbConsumeItemInBattle($PokemonBag,ret) if ret>0
    itemscene.pbEndScene if endscene
    pbFadeInAndShow(@sprites,oldsprites)
    return [ret,retindex]
  end

# Called whenever a Pokémon should forget a move.  It should return -1 if the
# selection is canceled, or 0 to 3 to indicate the move to forget.  The function
# should not allow HM moves to be forgotten.
  def pbForgetMove(pokemon,moveToLearn)
    ret=-1
    pbFadeOutIn(99999){
       scene=PokemonSummaryScene.new
       screen=PokemonSummary.new(scene)
       ret=screen.pbStartForgetScreen([pokemon],0,moveToLearn)
    }
    return ret
  end

# Called whenever a Pokémon needs one of its moves chosen. Used for Ether.
  def pbChooseMove(pokemon,message)
    ret=-1
    pbFadeOutIn(99999){
       scene=PokemonSummaryScene.new
       screen=PokemonSummary.new(scene)
       ret=screen.pbStartChooseMoveScreen([pokemon],0,message)
    }
    return ret
  end

  def pbNameEntry(helptext,pokemon)
    return pbEnterPokemonName(helptext,0,10,"",pokemon)
  end

  def pbSelectBattler(index,selectmode=1)
    numwindows=@battle.doublebattle ? 4 : 2
    for i in 0...numwindows
      sprite=@sprites["battlebox#{i}"]
      sprite.selected=(i==index) ? selectmode : 0
      sprite=@sprites["pokemon#{i}"]
      sprite.selected=(i==index) ? selectmode : 0
    end
  end

  def pbFirstTarget(index,targettype)
    case targettype
    when PBTargets::SingleNonUser
      for i in 0...4
        if i!=index && !@battle.battlers[i].isFainted? &&
           @battle.battlers[index].pbIsOpposing?(i)
          return i
        end
      end
    when PBTargets::UserOrPartner
      return index
    end
    return -1
  end

  def pbUpdateSelected(index)
    numwindows=@battle.doublebattle ? 4 : 2
    for i in 0...numwindows
      if i==index
        @sprites["battlebox#{i}"].selected=2
        @sprites["pokemon#{i}"].selected=2
      else
        @sprites["battlebox#{i}"].selected=0
        @sprites["pokemon#{i}"].selected=0
      end
      @sprites["battlebox#{i}"].update
      @sprites["pokemon#{i}"].update
    end
    pbFrameUpdate
  end

# Use this method to make the player choose a target
# for certain moves in double battles.
  def pbChooseTarget(index,targettype)
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

    curwindow=pbFirstTarget(index,targettype)
    if curwindow==-1
      raise RuntimeError.new(_INTL("Sin objetivo por alguna razón..."))
    end
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      pbUpdateSelected(curwindow)
      if Input.trigger?(Input::C)
        pbUpdateSelected(-1)
        return curwindow
      end
      if Input.trigger?(Input::B)
        pbUpdateSelected(-1)
        return -1
      end
      if curwindow>=0
        if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
          loop do
            case targettype
            when PBTargets::SingleNonUser
              case curwindow
              when 0; newcurwindow=2
              when 1; newcurwindow=0
              when 2; newcurwindow=3
              when 3; newcurwindow=1
              end
            when PBTargets::UserOrPartner
              newcurwindow=(curwindow+2)%4
            end
            curwindow=newcurwindow
            next if targettype==PBTargets::SingleNonUser && curwindow==index
            break if !@battle.battlers[curwindow].isFainted?
          end
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)
          loop do
            case targettype
            when PBTargets::SingleNonUser
              case curwindow
              when 0; newcurwindow=1
              when 1; newcurwindow=3
              when 2; newcurwindow=0
              when 3; newcurwindow=2
              end
            when PBTargets::UserOrPartner
              newcurwindow=(curwindow+2)%4
            end
            curwindow=newcurwindow
            next if targettype==PBTargets::SingleNonUser && curwindow==index
            break if !@battle.battlers[curwindow].isFainted?
          end
        end
      end
    end
  end

  def pbSwitch(index,lax,cancancel)
    party=@battle.pbParty(index)
    partypos=@battle.party1order
    ret=-1
    # Fade out and hide all sprites
    visiblesprites=pbFadeOutAndHide(@sprites)
    pbShowWindow(BLANK)
    pbSetMessageMode(true)
    modparty=[]
    for i in 0...6
      modparty.push(party[partypos[i]])
    end
    scene=PokemonScreen_Scene.new
    @switchscreen=PokemonScreen.new(scene,modparty)
    @switchscreen.pbStartScene(_INTL("Elige un Pokémon."),
       @battle.doublebattle && !@battle.fullparty1)
    loop do
      scene.pbSetHelpText(_INTL("Elige un Pokémon."))
      activecmd=@switchscreen.pbChoosePokemon
      if cancancel && activecmd==-1
        ret=-1
        break
      end
      if activecmd>=0
        commands=[]
        cmdShift=-1
        cmdSummary=-1
        pkmnindex=partypos[activecmd]
        commands[cmdShift=commands.length]=_INTL("Cambio") if !party[pkmnindex].isEgg?
        commands[cmdSummary=commands.length]=_INTL("Datos")
        commands[commands.length]=_INTL("Salir")
        command=scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",party[pkmnindex].name),commands)
        if cmdShift>=0 && command==cmdShift
          canswitch=lax ? @battle.pbCanSwitchLax?(index,pkmnindex,true) :
             @battle.pbCanSwitch?(index,pkmnindex,true)
          if canswitch
            ret=pkmnindex
            break
          end
        elsif cmdSummary>=0 && command==cmdSummary
          scene.pbSummary(activecmd)
        end
      end
    end
    @switchscreen.pbEndScene
    @switchscreen=nil
    pbShowWindow(BLANK)
    pbSetMessageMode(false)
    # back to main battle screen
    pbFadeInAndShow(@sprites,visiblesprites)
    return ret
  end

  def pbRevivalScene(index,lax,cancancel)
    party=@battle.pbParty(index)
    partypos=@battle.party1order
    ret=-1
    # Fade out and hide all sprites
    visiblesprites=pbFadeOutAndHide(@sprites)
    pbShowWindow(BLANK)
    pbSetMessageMode2(true)
    modparty=[]
    for i in 0...6
      modparty.push(party[partypos[i]])
    end
    scene=PokemonScreen_Scene.new
    @revivalscreen=PokemonScreen.new(scene,modparty)
    @revivalscreen.pbStartScene(_INTL("Elige un Pokémon."),
       @battle.doublebattle && !@battle.fullparty1)
    loop do
      scene.pbSetHelpText(_INTL("Elige un Pokémon."))
      activecmd=@revivalscreen.pbChoosePokemon
      if activecmd>=0
        commands=[]
        cmdRevive=-1
        pkmnindex=partypos[activecmd]
        commands[cmdRevive=commands.length]=_INTL("Revivir") if !party[pkmnindex].isEgg?
        commands[commands.length]=_INTL("Salir")
        command=scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",party[pkmnindex].name),commands)
        if cmdRevive>=0 && command==cmdRevive
          canrevive=lax ? @battle.pbCanReviveLax?(index,pkmnindex,true) :
             @battle.pbCanRevive?(index,pkmnindex,true)
          if canrevive
            ret=pkmnindex
            break
          end
        end
      end
    end
    @revivalscreen.pbEndScene
    @revivalscreen=nil
    pbShowWindow(BLANK)
    pbSetMessageMode2(false)
    # back to main battle screen
    pbFadeInAndShow(@sprites,visiblesprites)
    return ret
  end

  def pbDamageAnimation(pkmn,effectiveness)
    pkmnsprite=@sprites["pokemon#{pkmn.index}"]
    shadowsprite=@sprites["shadow#{pkmn.index}"]
    sprite=@sprites["battlebox#{pkmn.index}"]
    oldshadowvisible=shadowsprite.visible
    oldvisible=sprite.visible
    sprite.selected=3
    @briefmessage=false
    6.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
    end
    case effectiveness
    when 0
      pbSEPlay("normaldamage")
    when 1
      pbSEPlay("notverydamage")
    when 2
      pbSEPlay("superdamage")
    end
    8.times do
      pkmnsprite.visible=!pkmnsprite.visible
      if oldshadowvisible
        shadowsprite.visible=!shadowsprite.visible
      end
      4.times do
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
        sprite.update
      end
    end
    sprite.selected=0
    sprite.visible=oldvisible
  end

# This method is called whenever a Pokémon's HP changes.
# Used to animate the HP bar.
  def pbHPChanged(pkmn,oldhp,anim=false)
    @briefmessage=false
    hpchange=pkmn.hp-oldhp
    if hpchange<0
      hpchange=-hpchange
      PBDebug.log("[Modificación PS] #{pkmn.pbThis} perdió #{hpchange} PS (#{oldhp}=>#{pkmn.hp})")
    else
      PBDebug.log("[Modificación PS] #{pkmn.pbThis} ganó #{hpchange} PS (#{oldhp}=>#{pkmn.hp})")
    end
    if anim && @battle.battlescene
      if pkmn.hp>oldhp
        pbCommonAnimation("HealthUp",pkmn,nil)
      elsif pkmn.hp<oldhp
        pbCommonAnimation("HealthDown",pkmn,nil)
      end
    end
    sprite=@sprites["battlebox#{pkmn.index}"]
    sprite.animateHP(oldhp,pkmn.hp)
    while sprite.animatingHP
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      sprite.update
    end
  end
  
  #Animación para un pokémon salvaje huyendo. #BES-T
  def pbHideWild(pkmn)
    @sprites["shadow#{pkmn.index}"].visible=false
    pkmnsprite=@sprites["pokemon#{pkmn.index}"]
    20.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      if pkmnsprite
        pkmnsprite.opacity-=(255/20)
      end
    end
    if pkmnsprite
      pkmnsprite.visible=false
    end
    pbSEPlay("Battle flee")
    8.times do
      @sprites["battlebox#{pkmn.index}"].opacity-=32
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
    end
    @sprites["battlebox#{pkmn.index}"].visible=false
  end
  
# This method is called whenever a Pokémon faints.
  def pbFainted(pkmn)
    frames=pbCryFrameLength(pkmn.pokemon)
    pbPlayCry(pkmn.pokemon)
    frames.times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
    end
    @sprites["shadow#{pkmn.index}"].visible=false
    pkmnsprite=@sprites["pokemon#{pkmn.index}"]
    ycoord=0
    if @battle.doublebattle
      ycoord=PokeBattle_SceneConstants::PLAYERBATTLERD1_Y if pkmn.index==0
      ycoord=PokeBattle_SceneConstants::FOEBATTLERD1_Y if pkmn.index==1
      ycoord=PokeBattle_SceneConstants::PLAYERBATTLERD2_Y if pkmn.index==2
      ycoord=PokeBattle_SceneConstants::FOEBATTLERD2_Y if pkmn.index==3
    else
      if @battle.pbIsOpposing?(pkmn.index)
        ycoord=PokeBattle_SceneConstants::FOEBATTLER_Y
      else
        ycoord=PokeBattle_SceneConstants::PLAYERBATTLER_Y
      end
    end
    pbSEPlay("faint")
    loop do
      pkmnsprite.y+=8
      if pkmnsprite.y-pkmnsprite.oy+pkmnsprite.src_rect.height>=ycoord
        pkmnsprite.src_rect.height=ycoord-pkmnsprite.y+pkmnsprite.oy
      end
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if pkmnsprite.y>=ycoord
    end
    pkmnsprite.visible=false
    8.times do
      @sprites["battlebox#{pkmn.index}"].opacity-=32
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
    end
    @sprites["battlebox#{pkmn.index}"].visible=false
    pkmn.pbResetForm
  end

# Use this method to choose a command for the enemy.
  def pbChooseEnemyCommand(index)
    @battle.pbDefaultChooseEnemyCommand(index)
  end

# Use this method to choose a new Pokémon for the enemy
# The enemy's party is guaranteed to have at least one choosable member.
  def pbChooseNewEnemy(index,party)
    @battle.pbDefaultChooseNewEnemy(index,party)
  end

# This method is called when the player wins a wild Pokémon battle.
# This method can change the battle's music for example.
  def pbWildBattleSuccess
    pbBGMPlay(pbGetWildVictoryME())
  end

# This method is called when the player wins a Trainer battle.
# This method can change the battle's music for example.
  def pbTrainerBattleSuccess
    pbBGMPlay(pbGetTrainerVictoryME(@battle.opponent))
  end

  def pbEXPBar(pokemon,battler,startexp,endexp,tempexp1,tempexp2)
    if battler
      @sprites["battlebox#{battler.index}"].refreshExpLevel
      exprange=(endexp-startexp)
      startexplevel=0
      endexplevel=0
      if exprange!=0
        startexplevel=(tempexp1-startexp)*PokeBattle_SceneConstants::EXPGAUGESIZE/exprange
        endexplevel=(tempexp2-startexp)*PokeBattle_SceneConstants::EXPGAUGESIZE/exprange
      end
      @sprites["battlebox#{battler.index}"].animateEXP(startexplevel,endexplevel)
      while @sprites["battlebox#{battler.index}"].animatingEXP
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
        @sprites["battlebox#{battler.index}"].update
      end
    end
  end

  def pbShowPokedex(species)
    pbFadeOutIn(99999){
       scene=PokemonPokedexScene.new
       screen=PokemonPokedex.new(scene)
       screen.pbDexEntry(species)
    }
  end

  def pbChangeSpecies(attacker,species)
    pkmn=@sprites["pokemon#{attacker.index}"]
    shadow=@sprites["shadow#{attacker.index}"]
    back=!@battle.pbIsOpposing?(attacker.index)
    pkmn.setPokemonBitmapSpecies(attacker.pokemon,species,back)
    pkmn.x=-pkmn.bitmap.width/2
    pkmn.y=adjustBattleSpriteY(pkmn,species,attacker.index)
    if @battle.doublebattle
      case attacker.index
      when 0
        pkmn.x+=PokeBattle_SceneConstants::PLAYERBATTLERD1_X
        pkmn.y+=PokeBattle_SceneConstants::PLAYERBATTLERD1_Y
      when 1
        pkmn.x+=PokeBattle_SceneConstants::FOEBATTLERD1_X
        pkmn.y+=PokeBattle_SceneConstants::FOEBATTLERD1_Y
      when 2
        pkmn.x+=PokeBattle_SceneConstants::PLAYERBATTLERD2_X
        pkmn.y+=PokeBattle_SceneConstants::PLAYERBATTLERD2_Y
      when 3
        pkmn.x+=PokeBattle_SceneConstants::FOEBATTLERD2_X
        pkmn.y+=PokeBattle_SceneConstants::FOEBATTLERD2_Y
      end
    else
      pkmn.x+=PokeBattle_SceneConstants::PLAYERBATTLER_X if attacker.index==0
      pkmn.y+=PokeBattle_SceneConstants::PLAYERBATTLER_Y if attacker.index==0
      pkmn.x+=PokeBattle_SceneConstants::FOEBATTLER_X if attacker.index==1
      pkmn.y+=PokeBattle_SceneConstants::FOEBATTLER_Y if attacker.index==1
    end
    if shadow && !back
      shadow.visible=showShadow?(species)
    end
    pkmn=@sprites["pokemon#{attacker.index}"]
    back=!@battle.pbIsOpposing?(attacker.index)
    t=0
    10.times do
      t+=51 if t < 255
      pkmn.tone=Tone.new(t,t,t)
      pkmn.zoom_x+=0.02
      pkmn.zoom_y+=0.02
      pbWait(1)
    end
    pkmn.setPokemonBitmap(pokemon,back)
    10.times do
      t-=51 if t > 0
      pkmn.tone=Tone.new(t,t,t)
      pkmn.zoom_x-=0.02
      pkmn.zoom_y-=0.02
      pbWait(1)
    end
  end

  def pbChangePokemon(attacker,pokemon)
    pkmn=@sprites["pokemon#{attacker.index}"]
    shadow=@sprites["shadow#{attacker.index}"]
    back=!@battle.pbIsOpposing?(attacker.index)
    pkmn.setPokemonBitmap(pokemon,back)
    pkmn.x=-pkmn.bitmap.width/2
    pkmn.y=adjustBattleSpriteY(pkmn,pokemon.species,attacker.index)
    if @battle.doublebattle
      case attacker.index
      when 0
        pkmn.x+=PokeBattle_SceneConstants::PLAYERBATTLERD1_X
        pkmn.y+=PokeBattle_SceneConstants::PLAYERBATTLERD1_Y
      when 1
        pkmn.x+=PokeBattle_SceneConstants::FOEBATTLERD1_X
        pkmn.y+=PokeBattle_SceneConstants::FOEBATTLERD1_Y
      when 2
        pkmn.x+=PokeBattle_SceneConstants::PLAYERBATTLERD2_X
        pkmn.y+=PokeBattle_SceneConstants::PLAYERBATTLERD2_Y
      when 3
        pkmn.x+=PokeBattle_SceneConstants::FOEBATTLERD2_X
        pkmn.y+=PokeBattle_SceneConstants::FOEBATTLERD2_Y
      end
    else
      pkmn.x+=PokeBattle_SceneConstants::PLAYERBATTLER_X if attacker.index==0
      pkmn.y+=PokeBattle_SceneConstants::PLAYERBATTLER_Y if attacker.index==0
      pkmn.x+=PokeBattle_SceneConstants::FOEBATTLER_X if attacker.index==1
      pkmn.y+=PokeBattle_SceneConstants::FOEBATTLER_Y if attacker.index==1
    end
    if shadow && !back
      shadow.visible=showShadow?(pokemon.species)
    end
    pkmn=@sprites["pokemon#{attacker.index}"]
    back=!@battle.pbIsOpposing?(attacker.index)
    t=0
    10.times do
      t+=51 if t < 255
      pkmn.tone=Tone.new(t,t,t)
      pkmn.zoom_x+=0.02
      pkmn.zoom_y+=0.02
      pbWait(1)
    end
    pkmn.setPokemonBitmap(pokemon,back)
    10.times do
      t-=51 if t > 0
      pkmn.tone=Tone.new(t,t,t)
      pkmn.zoom_x-=0.02
      pkmn.zoom_y-=0.02
      pbWait(1)
    end
  end

  def pbSaveShadows
    shadows=[]
    for i in 0...4
      s=@sprites["shadow#{i}"]
      shadows[i]=s ? s.visible : false
      s.visible=false if s
    end
    yield
    for i in 0...4
      s=@sprites["shadow#{i}"]
      s.visible=shadows[i] if s
    end
  end

  def pbFindAnimation(moveid,userIndex,hitnum)
    begin
      move2anim=load_data("Data/move2anim.dat")
      noflip=false
      if (userIndex&1)==0   # On player's side
        anim=move2anim[0][moveid]
      else                  # On opposing side
        anim=move2anim[1][moveid]
        noflip=true if anim
        anim=move2anim[0][moveid] if !anim
      end
      return [anim+hitnum,noflip] if anim
      # Actual animation not found, get the default animation for the move's type
      # Animación actual no encontrada, se usa animación por defecto según el tipo del movimiento
      move=PBMoveData.new(moveid)
      type=move.type

      # BES-T - ANIMACIONES COHERENTES CON LA CATEGORIA
      if move.category==0 #FISICOS
      typedefaultanim=[[:NORMAL,:TACKLE],
                       [:FIGHTING,:DOUBLEKICK],
                       [:FLYING,:WINGATTACK],
                       [:POISON,:POISONJAB],
                       [:GROUND,:EARTHQUAKE],
                       [:ROCK,:ROCKTHROW],
                       [:BUG,:TWINEEDLE],
                       [:GHOST,:SHADOWCLAW],
                       [:STEEL,:GYROBALL],
                       [:FIRE,:FLAMETHROWER],
                       [:WATER,:AQUAJET],
                       [:GRASS,:LEAFBLADE],
                       [:ELECTRIC,:SPARK],
                       [:PSYCHIC,:ZENHEADBUTT],
                       [:ICE,:ICEBALL],
                       [:DRAGON,:DRAGONRUSH],
                       [:DARK,:PURSUIT],
                       [:FAIRY,:TACKLE]]

      elsif move.category==1 #ESPECIAL
      typedefaultanim=[[:NORMAL,:HIDDENPOWER],
                       [:FIGHTING,:DOUBLEKICK],
                       [:FLYING,:GUST],
                       [:POISON,:SLUDGE],
                       [:GROUND,:EARTHQUAKE],
                       [:ROCK,:ROCKTHROW],
                       [:BUG,:BUGBUZZ],
                       [:GHOST,:SHADOWBALL],
                       [:STEEL,:MIRRORSHOT],
                       [:FIRE,:FLAMETHROWER],
                       [:WATER,:WATERGUN],
                       [:GRASS,:RAZORLEAF],
                       [:ELECTRIC,:THUNDERSHOCK],
                       [:PSYCHIC,:CONFUSION],
                       [:ICE,:ICEBEAM],
                       [:DRAGON,:DRAGONRAGE],
                       [:DARK,:DARKPULSE],
                       [:FAIRY,:FAIRYWIND]]

      else #ESTADO
      typedefaultanim=[[:NORMAL,:WORKUP],
                       [:FIGHTING,:BULKUP],
                       [:FLYING,:ROOST],
                       [:POISON,:ACIDARMOR],
                       [:GROUND,:ROCKPOLISH],
                       [:ROCK,:ROCKPOLISH],
                       [:BUG,:POWDER],
                       [:GHOST,:SHADOWBALL],
                       [:STEEL,:GYROBALL],
                       [:FIRE,:BURNUP],
                       [:WATER,:WITHDRAW],
                       [:GRASS,:RAZORLEAF],
                       [:ELECTRIC,:CHARGE],
                       [:PSYCHIC,:CALMMIND],
                       [:ICE,:HAZE],
                       [:DRAGON,:DRAGONDANCE],
                       [:DARK,:QUASH],
                       [:FAIRY,:AROMATICMIST]]

      end

      for i in typedefaultanim
        if isConst?(type,PBTypes,i[0]) && hasConst?(PBMoves,i[1])
          noflip=false
          if (userIndex&1)==0   # On player's side
            anim=move2anim[0][getConst(PBMoves,i[1])]
          else                  # On opposing side
            anim=move2anim[1][getConst(PBMoves,i[1])]
            noflip=true if anim
            anim=move2anim[0][getConst(PBMoves,i[1])] if !anim
          end
          return [anim,noflip] if anim
          break
        end
      end
      # Default animation for the move's type not found, use Tackle's animation
      # Animación por defecto para tipos de movimientos no encontrados, se usa la animación de Placaje
      if hasConst?(PBMoves,:TACKLE)
        anim=move2anim[0][getConst(PBMoves,:TACKLE)]
        return [anim,false] if anim
      end
    rescue
      return nil
    end
    return nil
  end

  def pbCommonAnimation(animname,user,target,hitnum=0)
    $pkmn_animations=load_data("Data/PkmnAnimations.rxdata") if $pkmn_animations
    animations=$pkmn_animations
    for i in 0...animations.length
      if animations[i] && animations[i].name=="Common:"+animname
        pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
        return
      end
    end
  end

  def pbToggleDataboxes(toggle = false)
    unless toggle
      8.times do
        @sprites["battlebox0"].opacity-=32 if @sprites["battlebox0"]
        @sprites["battlebox1"].opacity-=32 if @sprites["battlebox1"]
        @sprites["battlebox2"].opacity-=32 if @sprites["battlebox2"]
        @sprites["battlebox3"].opacity-=32 if @sprites["battlebox3"]
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
      end
      for i in 0...3
        @sprites["battlebox#{i}"].opacity = 0 if @sprites["battlebox#{i}"]
      end
    else
      8.times do
        @sprites["battlebox0"].opacity+=32 if @sprites["battlebox0"]
        @sprites["battlebox1"].opacity+=32 if @sprites["battlebox1"]
        @sprites["battlebox2"].opacity+=32 if @sprites["battlebox2"]
        @sprites["battlebox3"].opacity+=32 if @sprites["battlebox3"]
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
      end
      for i in 0...3
        @sprites["battlebox#{i}"].opacity = 255 if @sprites["battlebox#{i}"]
      end
    end
  end

  def pbAnimation(moveid,user,target,hitnum=0)
    animid=pbFindAnimation(moveid,user.index,hitnum)
    return if !animid
    anim=animid[0]
    $pkmn_animations=load_data("Data/PkmnAnimations.rxdata") if $pkmn_animations
    animations=$pkmn_animations
    pbToggleDataboxes if PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES
    pbSaveShadows {
       if animid[1] # On opposing side and using OppMove animation
         pbAnimationCore(animations[anim],target,user,true)
       else         # On player's side, and/or using Move animation
         pbAnimationCore(animations[anim],user,target)
       end
    }
    pbToggleDataboxes(true) if PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES
    if PBMoveData.new(moveid).function==0x69 && user && target # Transform
      # Change form to transformed version
      pbChangePokemon(user,target.pokemon)
    end
  end

  def pbAnimationCore(animation,user,target,oppmove=false)
    return if !animation
    @briefmessage=false
    usersprite=(user) ? @sprites["pokemon#{user.index}"] : nil
    targetsprite=(target) ? @sprites["pokemon#{target.index}"] : nil
    olduserx=usersprite ? usersprite.x : 0
    oldusery=usersprite ? usersprite.y : 0
    oldtargetx=targetsprite ? targetsprite.x : 0
    oldtargety=targetsprite ? targetsprite.y : 0
    if !targetsprite
      target=user if !target
      animplayer=PBAnimationPlayerX.new(animation,user,target,self,oppmove)
      userwidth=(!usersprite || !usersprite.bitmap || usersprite.bitmap.disposed?) ? 128 : usersprite.bitmap.width
      userheight=(!usersprite || !usersprite.bitmap || usersprite.bitmap.disposed?) ? 128 : usersprite.bitmap.height
      animplayer.setLineTransform(
         PokeBattle_SceneConstants::FOCUSUSER_X,PokeBattle_SceneConstants::FOCUSUSER_Y,
         PokeBattle_SceneConstants::FOCUSTARGET_X,PokeBattle_SceneConstants::FOCUSTARGET_Y,
         olduserx+(userwidth/2),oldusery+(userheight/2),
         olduserx+(userwidth/2),oldusery+(userheight/2))
    else
      animplayer=PBAnimationPlayerX.new(animation,user,target,self,oppmove)
      userwidth=(!usersprite || !usersprite.bitmap || usersprite.bitmap.disposed?) ? 128 : usersprite.bitmap.width
      userheight=(!usersprite || !usersprite.bitmap || usersprite.bitmap.disposed?) ? 128 : usersprite.bitmap.height
      targetwidth=(!targetsprite.bitmap || targetsprite.bitmap.disposed?) ? 128 : targetsprite.bitmap.width
      targetheight=(!targetsprite.bitmap || targetsprite.bitmap.disposed?) ? 128 : targetsprite.bitmap.height
      animplayer.setLineTransform(
         PokeBattle_SceneConstants::FOCUSUSER_X,PokeBattle_SceneConstants::FOCUSUSER_Y,
         PokeBattle_SceneConstants::FOCUSTARGET_X,PokeBattle_SceneConstants::FOCUSTARGET_Y,
         olduserx+(userwidth/2),oldusery+(userheight/2),
         oldtargetx+(targetwidth/2),oldtargety+(targetheight/2))
    end
    animplayer.start
    while animplayer.playing?
      animplayer.update
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
    end
    usersprite.ox=0 if usersprite
    usersprite.oy=0 if usersprite
    usersprite.x=olduserx if usersprite
    usersprite.y=oldusery if usersprite
    targetsprite.ox=0 if targetsprite
    targetsprite.oy=0 if targetsprite
    targetsprite.x=oldtargetx if targetsprite
    targetsprite.y=oldtargety if targetsprite
    animplayer.dispose
  end

  def pbLevelUp(pokemon,battler,oldtotalhp,oldattack,olddefense,oldspeed,
                oldspatk,oldspdef)
    pbTopRightWindow(_INTL("#{PBStats.getName(0,true)} Máx.<r>+{1}<br>#{PBStats.getName(1,true)}<r>+{2}<br>#{PBStats.getName(2,true)}<r>+{3}<br>#{PBStats.getName(4,true)}<r>+{4}<br>#{PBStats.getName(5,true)}<r>+{5}<br>#{PBStats.getName(3,true)}<r>+{6}",
       pokemon.totalhp-oldtotalhp,pokemon.attack-oldattack,pokemon.defense-olddefense,pokemon.spatk-oldspatk,pokemon.spdef-oldspdef,pokemon.speed-oldspeed))
       pbTopRightWindow(_INTL("#{PBStats.getName(0,true)} Máx.<r>+{1}<br>#{PBStats.getName(1,true)}<r>+{2}<br>#{PBStats.getName(2,true)}<r>+{3}<br>#{PBStats.getName(4,true)}<r>+{4}<br>#{PBStats.getName(5,true)}<r>+{5}<br>#{PBStats.getName(3,true)}<r>+{6}",
       pokemon.totalhp,pokemon.attack,pokemon.defense,pokemon.spatk,pokemon.spdef,pokemon.speed))
  end

  def pbThrowAndDeflect(ball,targetBattler)
    @briefmessage=false
    balltype=pbGetBallType(ball)
    ball=sprintf("Graphics/#{BATTLE_ROUTE}/ball%02d",balltype)
    # sprite
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    # picture
    pictureBall=PictureEx.new(@sprites["pokemon#{targetBattler}"].z+1)
    center=getSpriteCenter(@sprites["pokemon#{targetBattler}"])
    # starting positions
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ball)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    pictureBall.moveXY(0,1,10,180)
    # directives
    pictureBall.moveSE(1,"Audio/SE/throw")
    pictureBall.moveCurve(30,1,150,70,30+Graphics.width/2,10,center[0],center[1])
    pictureBall.moveAngle(30,1,-1080)
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    delay=pictureBall.totalDuration
    pictureBall.moveSE(delay,"Audio/SE/balldrop")
    pictureBall.moveXY(20,delay,0,Graphics.height)
    loop do
      pictureBall.update
      setPictureIconSprite(spriteBall,pictureBall)
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running?
    end
    spriteBall.dispose
  end

  def pbThrow(ball,shakes,critical,targetBattler,showplayer=false)
    @briefmessage=false
    burst=-1
    $pkmn_animations=load_data("Data/PkmnAnimations.rxdata") if $pkmn_animations
    animations=$pkmn_animations
    for i in 0...2
      t=(i==0) ? ball : 0
      for j in 0...animations.length
        if animations[j]
          if animations[j].name=="Common:BallBurst#{t}"
            burst=t if burst<0
            break
          end
        end
      end
      break if burst>=0
    end
    pokeballThrow(ball,shakes,critical,targetBattler,self,@battle.battlers[targetBattler],burst,showplayer)
  end

  def pbThrowSuccess
    if !@battle.opponent
      @briefmessage=false
      pbMEPlay("Jingle - HMTM")
      frames=(3.5*Graphics.frame_rate).to_i
      frames.times do
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
      end
    end
  end

  def pbHideCaptureBall
    if @sprites["capture"]
      loop do
        break if @sprites["capture"].opacity<=0
        @sprites["capture"].opacity-=12
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
      end
    end
  end

  def pbThrowBait
    @briefmessage=false
    ball=sprintf("Graphics/#{BATTLE_ROUTE}/battleBait")
    armanim=false
    if @sprites["player"].bitmap.width>@sprites["player"].bitmap.height
      armanim=true
    end
    # sprites
    spritePoke=@sprites["pokemon1"]
    spritePlayer=@sprites["player"]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    # pictures
    pictureBall=PictureEx.new(spritePoke.z+1)
    picturePoke=PictureEx.new(spritePoke.z)
    picturePlayer=PictureEx.new(spritePoke.z+2)
    dims=[spritePoke.x,spritePoke.y]
    pokecenter=getSpriteCenter(@sprites["pokemon1"])
    playerpos=[@sprites["player"].x,@sprites["player"].y]
    ballendy=PokeBattle_SceneConstants::FOEBATTLER_Y-4
    # starting positions
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ball)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    pictureBall.moveXY(0,1,64,256)
    picturePoke.moveVisible(1,true)
    picturePoke.moveOrigin(1,PictureOrigin::Center)
    picturePoke.moveXY(0,1,pokecenter[0],pokecenter[1])
    picturePlayer.moveVisible(1,true)
    picturePlayer.moveName(1,@sprites["player"].name)
    picturePlayer.moveOrigin(1,PictureOrigin::TopLeft)
    picturePlayer.moveXY(0,1,playerpos[0],playerpos[1])
    # directives
    picturePoke.moveSE(1,"Audio/SE/throw")
    pictureBall.moveCurve(30,1,64,256,Graphics.width/2,48,
                          PokeBattle_SceneConstants::FOEBATTLER_X-48,
                          PokeBattle_SceneConstants::FOEBATTLER_Y)
    pictureBall.moveAngle(30,1,-720)
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    if armanim
      picturePlayer.moveSrc(1,@sprites["player"].bitmap.height,0)
      picturePlayer.moveXY(0,1,playerpos[0]-14,playerpos[1])
      picturePlayer.moveSrc(4,@sprites["player"].bitmap.height*2,0)
      picturePlayer.moveXY(0,4,playerpos[0]-12,playerpos[1])
      picturePlayer.moveSrc(8,@sprites["player"].bitmap.height*3,0)
      picturePlayer.moveXY(0,8,playerpos[0]+20,playerpos[1])
      picturePlayer.moveSrc(16,@sprites["player"].bitmap.height*4,0)
      picturePlayer.moveXY(0,16,playerpos[0]+16,playerpos[1])
      picturePlayer.moveSrc(40,0,0)
      picturePlayer.moveXY(0,40,playerpos[0],playerpos[1])
    end
    # Show Pokémon jumping before eating the bait
    picturePoke.moveSE(50,"Audio/SE/jump")
    picturePoke.moveXY(8,50,pokecenter[0],pokecenter[1]-8)
    picturePoke.moveXY(8,58,pokecenter[0],pokecenter[1])
    pictureBall.moveVisible(66,false)
    picturePoke.moveSE(66,"Audio/SE/jump")
    picturePoke.moveXY(8,66,pokecenter[0],pokecenter[1]-8)
    picturePoke.moveXY(8,74,pokecenter[0],pokecenter[1])
    # TODO: Show Pokémon eating the bait (pivots at the bottom right corner)
    picturePoke.moveOrigin(picturePoke.totalDuration,PictureOrigin::TopLeft)
    picturePoke.moveXY(0,picturePoke.totalDuration,dims[0],dims[1])
    loop do
      pictureBall.update
      picturePoke.update
      picturePlayer.update
      setPictureIconSprite(spriteBall,pictureBall)
      setPictureSprite(spritePoke,picturePoke)
      setPictureIconSprite(spritePlayer,picturePlayer)
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running? && !picturePoke.running? && !picturePlayer.running?
    end
    spriteBall.dispose
  end

  def pbThrowRock
    @briefmessage=false
    ball=sprintf("Graphics/#{BATTLE_ROUTE}/battleRock")
    anger=sprintf("Graphics/#{BATTLE_ROUTE}/battleAnger")
    armanim=false
    if @sprites["player"].bitmap.width>@sprites["player"].bitmap.height
      armanim=true
    end
    # sprites
    spritePoke=@sprites["pokemon1"]
    spritePlayer=@sprites["player"]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    spriteAnger=IconSprite.new(0,0,@viewport)
    spriteAnger.visible=false
    # pictures
    pictureBall=PictureEx.new(spritePoke.z+1)
    picturePoke=PictureEx.new(spritePoke.z)
    picturePlayer=PictureEx.new(spritePoke.z+2)
    pictureAnger=PictureEx.new(spritePoke.z+1)
    dims=[spritePoke.x,spritePoke.y]
    pokecenter=getSpriteCenter(@sprites["pokemon1"])
    playerpos=[@sprites["player"].x,@sprites["player"].y]
    ballendy=PokeBattle_SceneConstants::FOEBATTLER_Y-4
    # starting positions
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ball)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    pictureBall.moveXY(0,1,64,256)
    picturePoke.moveVisible(1,true)
    picturePoke.moveOrigin(1,PictureOrigin::Center)
    picturePoke.moveXY(0,1,pokecenter[0],pokecenter[1])
    picturePlayer.moveVisible(1,true)
    picturePlayer.moveName(1,@sprites["player"].name)
    picturePlayer.moveOrigin(1,PictureOrigin::TopLeft)
    picturePlayer.moveXY(0,1,playerpos[0],playerpos[1])
    pictureAnger.moveVisible(1,false)
    pictureAnger.moveName(1,anger)
    pictureAnger.moveXY(0,1,pokecenter[0]-56,pokecenter[1]-48)
    pictureAnger.moveOrigin(1,PictureOrigin::Center)
    pictureAnger.moveZoom(0,1,100)
    # directives
    picturePoke.moveSE(1,"Audio/SE/throw")
    pictureBall.moveCurve(30,1,64,256,Graphics.width/2,48,pokecenter[0],pokecenter[1])
    pictureBall.moveAngle(30,1,-720)
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    pictureBall.moveSE(30,"Audio/SE/notverydamage")
    if armanim
      picturePlayer.moveSrc(1,@sprites["player"].bitmap.height,0)
      picturePlayer.moveXY(0,1,playerpos[0]-14,playerpos[1])
      picturePlayer.moveSrc(4,@sprites["player"].bitmap.height*2,0)
      picturePlayer.moveXY(0,4,playerpos[0]-12,playerpos[1])
      picturePlayer.moveSrc(8,@sprites["player"].bitmap.height*3,0)
      picturePlayer.moveXY(0,8,playerpos[0]+20,playerpos[1])
      picturePlayer.moveSrc(16,@sprites["player"].bitmap.height*4,0)
      picturePlayer.moveXY(0,16,playerpos[0]+16,playerpos[1])
      picturePlayer.moveSrc(40,0,0)
      picturePlayer.moveXY(0,40,playerpos[0],playerpos[1])
    end
    pictureBall.moveVisible(40,false)
    # Show Pokémon being angry
    pictureAnger.moveSE(48,"Audio/SE/jump")
    pictureAnger.moveVisible(48,true)
    pictureAnger.moveZoom(8,48,130)
    pictureAnger.moveZoom(8,56,100)
    pictureAnger.moveXY(0,64,pokecenter[0]+56,pokecenter[1]-64)
    pictureAnger.moveSE(64,"Audio/SE/jump")
    pictureAnger.moveZoom(8,64,130)
    pictureAnger.moveZoom(8,72,100)
    pictureAnger.moveVisible(80,false)
    picturePoke.moveOrigin(picturePoke.totalDuration,PictureOrigin::TopLeft)
    picturePoke.moveXY(0,picturePoke.totalDuration,dims[0],dims[1])
    loop do
      pictureBall.update
      picturePoke.update
      picturePlayer.update
      pictureAnger.update
      setPictureIconSprite(spriteBall,pictureBall)
      setPictureSprite(spritePoke,picturePoke)
      setPictureIconSprite(spritePlayer,picturePlayer)
      setPictureIconSprite(spriteAnger,pictureAnger)
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running? && !picturePoke.running? &&
               !picturePlayer.running? && !pictureAnger.running?
    end
    spriteBall.dispose
  end
  
#===============================================================================
# BES-T  MUSICA AL TENER VIDA BAJA
#===============================================================================
  # Inicializar el estado de baja vida en la batalla
  alias pbStartBattle_lHP pbStartBattle
  def pbStartBattle(battle)
    pbStartBattle_lHP(battle)
    @lowHPBGM = false   
  end
  
  # Restaurar música al cambiar un Pokémon y verificar si el siguiente necesita la música de baja vida
  alias pbRecall_lHP pbRecall
  def pbRecall(battlerindex)
    pbRecall_lHP(battlerindex)
    $game_system.bgm_restore if @lowHPBGM
    @lowHPBGM = false
  end
  
  # Revisar la música al enviar un Pokémon
  alias pbSendOut_lHP pbSendOut
  def pbSendOut(battlerindex, pkmn)
    pbSendOut_lHP(battlerindex, pkmn)
    pkmn = @battle.battlers[battlerindex]
    pbLowHPMusic(pkmn)
  end
  
  # Método para gestionar la música de baja vida
  def pbLowHPMusic(pkmn)
    return if !PokeBattle_SceneConstants::PLAY_LOW_HP_MUSIC
    return if @battle.doublebattle
    track = PokeBattle_SceneConstants::LOW_HP_MUSIC_FILE
    
    # Solo reproducir si el Pokémon tiene vida baja y aún no se ha activado
    if pkmn.hp > 0 && (pkmn.hp <= pkmn.totalhp / 4)
      unless @lowHPBGM
        $game_system.bgm_memorize
        pbBGMPlay(track)
        @lowHPBGM = true
      end
    else
      # Restaurar música si el Pokémon tiene suficiente vida
      if @lowHPBGM
        $game_system.bgm_restore
        @lowHPBGM = false
      end
    end
  end
  
  # Revisar la música al cambiar el HP del Pokémon
  alias pbHPChanged_lHP pbHPChanged
  def pbHPChanged(pkmn, oldhp, anim = false)
    pbHPChanged_lHP(pkmn, oldhp, anim)
    pbLowHPMusic(pkmn) if pkmn.index % 2 == 0
  end
end
