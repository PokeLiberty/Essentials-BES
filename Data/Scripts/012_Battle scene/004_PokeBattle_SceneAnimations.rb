#===============================================================================
# Shows the enemy trainer(s)'s Pokémon being thrown out.  It appears at coords
# (@spritex,@spritey), and moves in y to @endspritey where it stays for the rest
# of the battle, i.e. the latter is the more important value.
# Doesn't show the ball itself being thrown.
#===============================================================================
class PokeballSendOutAnimation
    SPRITESTEPS=10
    STARTZOOM=0.125
  
    def initialize(sprite,spritehash,pkmn,illusionpoke,doublebattle)
      @illusionpoke=illusionpoke
      @disposed=false
      @ballused=pkmn.pokemon ? pkmn.pokemon.ballused : 0
      if @illusionpoke
        @ballused=@illusionpoke.ballused || 0
      end
      @PokemonBattlerSprite=sprite
      @PokemonBattlerSprite.visible=false
      @PokemonBattlerSprite.tone=Tone.new(248,248,248,248)
      @pokeballsprite=IconSprite.new(0,0,sprite.viewport)
      @pokeballsprite.setBitmap(sprintf("Graphics/#{BATTLE_ROUTE}/ball%02d",@ballused))
      if doublebattle
        @spritex=PokeBattle_SceneConstants::FOEBATTLERD1_X if pkmn.index==1
        @spritex=PokeBattle_SceneConstants::FOEBATTLERD2_X if pkmn.index==3
      else
        @spritex=PokeBattle_SceneConstants::FOEBATTLER_X
      end
      @spritey=0
      if @illusionpoke
        @endspritey=adjustBattleSpriteY(sprite,@illusionpoke.species,pkmn.index)
      else
        @endspritey=adjustBattleSpriteY(sprite,pkmn.species,pkmn.index)
      end
      if doublebattle
        @spritey=PokeBattle_SceneConstants::FOEBATTLERD1_Y if pkmn.index==1
        @spritey=PokeBattle_SceneConstants::FOEBATTLERD2_Y if pkmn.index==3
        @endspritey+=PokeBattle_SceneConstants::FOEBATTLERD1_Y if pkmn.index==1
        @endspritey+=PokeBattle_SceneConstants::FOEBATTLERD2_Y if pkmn.index==3
      else
        @spritey=PokeBattle_SceneConstants::FOEBATTLER_Y
        @endspritey+=PokeBattle_SceneConstants::FOEBATTLER_Y
      end
      @spritehash=spritehash
      @pokeballsprite.x=@spritex-@pokeballsprite.bitmap.width/2
      @pokeballsprite.y=@spritey-@pokeballsprite.bitmap.height/2-4
      @pokeballsprite.z=@PokemonBattlerSprite.z+1
      @pkmn=pkmn
      @shadowX=@spritex
      @shadowY=@spritey
      if @spritehash["shadow#{@pkmn.index}"] && @spritehash["shadow#{@pkmn.index}"].bitmap!=nil
        @shadowX-=@spritehash["shadow#{@pkmn.index}"].bitmap.width/2
        @shadowY-=@spritehash["shadow#{@pkmn.index}"].bitmap.height/2
      end
      @shadowVisible=showShadow?(pkmn.species)
      if @illusionpoke
        @shadowVisible=showShadow?(@illusionpoke.species)
      end
      @stepspritey=(@spritey-@endspritey)
      @zoomstep=(1.0-STARTZOOM)/SPRITESTEPS
      @animdone=false
      @frame=0
    end
  
    def disposed?
      return @disposed
    end
  
    def animdone?
      return @animdone
    end
  
    def dispose
      return if disposed?
      @pokeballsprite.dispose
      @disposed=true
    end
  
    def update
      return if disposed?
      @pokeballsprite.update
      @frame+=1
      if @frame==2
        pbSEPlay("recall")
      end
      if @frame==4
        @PokemonBattlerSprite.visible=true
        @PokemonBattlerSprite.zoom_x=STARTZOOM
        @PokemonBattlerSprite.zoom_y=STARTZOOM
        pbSpriteSetCenter(@PokemonBattlerSprite,@spritex,@spritey)
        if @illusionpoke
          pbPlayCry(@illusionpoke)
        else
          pbPlayCry(@pkmn.pokemon ? @pkmn.pokemon : @pkmn.species)
        end
        @pokeballsprite.setBitmap(sprintf("Graphics/#{BATTLE_ROUTE}/ball%02d_open",@ballused))
      end
      if @frame==8
        @pokeballsprite.visible=false
      end
      if @frame>8 && @frame<=16
        color=Color.new(248,248,248,256-(16-@frame)*32)
        @spritehash["enemybase"].color=color
        @spritehash["playerbase"].color=color
        @spritehash["battlebg"].color=color
        for i in 0...4
          @spritehash["shadow#{i}"].color=color if @spritehash["shadow#{i}"]
        end
      end
      if @frame>16 && @frame<=24
        color=Color.new(248,248,248,(24-@frame)*32)
        tone=(24-@frame)*32
        @PokemonBattlerSprite.tone=Tone.new(tone,tone,tone,tone)
        @spritehash["enemybase"].color=color
        @spritehash["playerbase"].color=color
        @spritehash["battlebg"].color=color
        for i in 0...4
          @spritehash["shadow#{i}"].color=color if @spritehash["shadow#{i}"]
        end
      end
      if @frame>5 && @PokemonBattlerSprite.zoom_x<1.0
        @PokemonBattlerSprite.zoom_x+=@zoomstep
        @PokemonBattlerSprite.zoom_y+=@zoomstep
        @PokemonBattlerSprite.zoom_x=1.0 if @PokemonBattlerSprite.zoom_x > 1.0
        @PokemonBattlerSprite.zoom_y=1.0 if @PokemonBattlerSprite.zoom_y > 1.0
        currentY=@spritey-(@stepspritey*@PokemonBattlerSprite.zoom_y)
        pbSpriteSetCenter(@PokemonBattlerSprite,@spritex,currentY)
        @PokemonBattlerSprite.y=currentY
      end
      if @PokemonBattlerSprite.tone.gray<=0 && @PokemonBattlerSprite.zoom_x>=1.0
        @animdone=true
        if @spritehash["shadow#{@pkmn.index}"]
          @spritehash["shadow#{@pkmn.index}"].x=@shadowX
          @spritehash["shadow#{@pkmn.index}"].y=@shadowY
          @spritehash["shadow#{@pkmn.index}"].visible=@shadowVisible
        end
      end
    end
  end
  
  #===============================================================================
  # Shows the player's (or partner's) Pokémon being thrown out.  It appears at
  # (@spritex,@spritey), and moves in y to @endspritey where it stays for the rest
  # of the battle, i.e. the latter is the more important value.
  # Doesn't show the ball itself being thrown.
  #===============================================================================
  class PokeballPlayerSendOutAnimation
  #  Ball curve: 8,52; 22,44; 52, 96
  #  Player: Color.new(16*8,23*8,30*8)
    SPRITESTEPS=10
    STARTZOOM=0.125
  
    def initialize(sprite,spritehash,pkmn,illusionpoke,doublebattle)
      @illusionpoke=illusionpoke
      @disposed=false
      @PokemonBattlerSprite=sprite
      @pkmn=pkmn
      @PokemonBattlerSprite.visible=false
      @PokemonBattlerSprite.tone=Tone.new(248,248,248,248)
      @spritehash=spritehash
      if doublebattle
        @spritex=PokeBattle_SceneConstants::PLAYERBATTLERD1_X if pkmn.index==0
        @spritex=PokeBattle_SceneConstants::PLAYERBATTLERD2_X if pkmn.index==2
      else
        @spritex=PokeBattle_SceneConstants::PLAYERBATTLER_X
      end
      @spritey=0
      if @illusionpoke
        @endspritey=adjustBattleSpriteY(sprite,@illusionpoke.species,pkmn.index)
      else
        @endspritey=adjustBattleSpriteY(sprite,pkmn.species,pkmn.index)
      end
      if doublebattle
        @spritey+=PokeBattle_SceneConstants::PLAYERBATTLERD1_Y if pkmn.index==0
        @spritey+=PokeBattle_SceneConstants::PLAYERBATTLERD2_Y if pkmn.index==2
        @endspritey+=PokeBattle_SceneConstants::PLAYERBATTLERD1_Y if pkmn.index==0
        @endspritey+=PokeBattle_SceneConstants::PLAYERBATTLERD2_Y if pkmn.index==2
      else
        @spritey+=PokeBattle_SceneConstants::PLAYERBATTLER_Y
        @endspritey+=PokeBattle_SceneConstants::PLAYERBATTLER_Y
      end
      @animdone=false
      @frame=0
    end
  
    def disposed?
      return @disposed
    end
  
    def animdone?
      return @animdone
    end
  
    def dispose
      return if disposed?
      @disposed=true
    end
  
    def update
      return if disposed?
      @frame+=1
      if @frame==4
        @PokemonBattlerSprite.visible=true
        @PokemonBattlerSprite.zoom_x=STARTZOOM
        @PokemonBattlerSprite.zoom_y=STARTZOOM
        pbSEPlay("recall")
        pbSpriteSetCenter(@PokemonBattlerSprite,@spritex,@spritey)
        if @illusionpoke
          pbPlayCry(@illusionpoke)
        else
          pbPlayCry(@pkmn.pokemon ? @pkmn.pokemon : @pkmn.species)
        end
      end
      if @frame>8 && @frame<=16
        color=Color.new(248,248,248,256-(16-@frame)*32)
        @spritehash["enemybase"].color=color
        @spritehash["playerbase"].color=color
        @spritehash["battlebg"].color=color
        for i in 0...4
          @spritehash["shadow#{i}"].color=color if @spritehash["shadow#{i}"]
        end
      end
      if @frame>16 && @frame<=24
        color=Color.new(248,248,248,(24-@frame)*32)
        tone=(24-@frame)*32
        @PokemonBattlerSprite.tone=Tone.new(tone,tone,tone,tone)
        @spritehash["enemybase"].color=color
        @spritehash["playerbase"].color=color
        @spritehash["battlebg"].color=color
        for i in 0...4
          @spritehash["shadow#{i}"].color=color if @spritehash["shadow#{i}"]
        end
      end
      if @frame>5 && @PokemonBattlerSprite.zoom_x<1.0
        @PokemonBattlerSprite.zoom_x+=0.1
        @PokemonBattlerSprite.zoom_y+=0.1
        @PokemonBattlerSprite.zoom_x=1.0 if @PokemonBattlerSprite.zoom_x > 1.0
        @PokemonBattlerSprite.zoom_y=1.0 if @PokemonBattlerSprite.zoom_y > 1.0
        pbSpriteSetCenter(@PokemonBattlerSprite,@spritex,0)
        @PokemonBattlerSprite.y=@spritey+(@endspritey-@spritey)*@PokemonBattlerSprite.zoom_y
      end
      if @PokemonBattlerSprite.tone.gray<=0 && @PokemonBattlerSprite.zoom_x>=1.0
        @animdone=true
      end
    end
  end
  
  
  
  #===============================================================================
  # Shows the enemy trainer(s) and the enemy party lineup sliding off screen.
  # Doesn't show the ball thrown or the Pokémon.
  #===============================================================================
  class TrainerFadeAnimation
    def initialize(sprites)
      @frame=0
      @sprites=sprites
      @animdone=false
    end
  
    def animdone?
      return @animdone
    end
  
    def update
      return if @animdone
      @frame+=1
      @sprites["trainer"].x+=8
      @sprites["trainer2"].x+=8 if @sprites["trainer2"]
      @sprites["partybarfoe"].x+=8
      @sprites["partybarfoe"].opacity-=12
      for i in 0...6
        @sprites["enemy#{i}"].opacity-=12
        @sprites["enemy#{i}"].x+=8 if @frame>=i*4
      end
      @animdone=true if @sprites["trainer"].x>=Graphics.width &&
         (!@sprites["trainer2"] || @sprites["trainer2"].x>=Graphics.width)
    end
  end
  
  
  
  #===============================================================================
  # Shows the player (and partner) and the player party lineup sliding off screen.
  # Shows the player's/partner's throwing animation (if they have one).
  # Doesn't show the ball thrown or the Pokémon.
  #===============================================================================
  class PlayerFadeAnimation
    def initialize(sprites)
      @frame=0
      @sprites=sprites
      @animdone=false
    end
  
    def animdone?
      return @animdone
    end
  
    def update
      return if @animdone
      @frame+=1
      @sprites["player"].x-=8
      @sprites["playerB"].x-=8 if @sprites["playerB"]
      @sprites["partybarplayer"].x-=8
      @sprites["partybarplayer"].opacity-=12
      for i in 0...6
        if @sprites["player#{i}"]
          @sprites["player#{i}"].opacity-=12
          @sprites["player#{i}"].x-=8 if @frame>=i*4
        end
      end
      pa=@sprites["player"]
      pb=@sprites["playerB"]
      pawidth=128
      pbwidth=128
      if (pa && pa.bitmap && !pa.bitmap.disposed?)
        if pa.bitmap.height<pa.bitmap.width
          numframes=pa.bitmap.width/pa.bitmap.height # Number of frames
          pawidth=pa.bitmap.width/numframes # Width per frame
          @sprites["player"].src_rect.x=pawidth*1 if @frame>0
          @sprites["player"].src_rect.x=pawidth*2 if @frame>8
          @sprites["player"].src_rect.x=pawidth*3 if @frame>12
          @sprites["player"].src_rect.x=pawidth*4 if @frame>16
          @sprites["player"].src_rect.width=pawidth
        else
          pawidth=pa.bitmap.width
          @sprites["player"].src_rect.x=0
          @sprites["player"].src_rect.width=pawidth
        end
      end
      if (pb && pb.bitmap && !pb.bitmap.disposed?)
        if pb.bitmap.height<pb.bitmap.width
          numframes=pb.bitmap.width/pb.bitmap.height # Number of frames
          pbwidth=pb.bitmap.width/numframes # Width per frame
          @sprites["playerB"].src_rect.x=pbwidth*1 if @frame>0
          @sprites["playerB"].src_rect.x=pbwidth*2 if @frame>8
          @sprites["playerB"].src_rect.x=pbwidth*3 if @frame>12
          @sprites["playerB"].src_rect.x=pbwidth*4 if @frame>16
          @sprites["playerB"].src_rect.width=pbwidth
        else
          pbwidth=pb.bitmap.width
          @sprites["playerB"].src_rect.x=0
          @sprites["playerB"].src_rect.width=pbwidth
        end
      end
      if pb
        @animdone=true if pb.x<=-pbwidth
      else
        @animdone=true if pa.x<=-pawidth
      end
    end
  end
  
  
  
  #===============================================================================
  # Shows the player's Poké Ball being thrown to capture a Pokémon.
  #===============================================================================
  def pokeballThrow(ball,shakes,critical,targetBattler,scene,battler,burst=-1,showplayer=false)
    balltype=pbGetBallType(ball)
    animtrainer=false
    if showplayer && @sprites["player"].bitmap.width>@sprites["player"].bitmap.height
      animtrainer=true
    end
    oldvisible=@sprites["shadow#{targetBattler}"].visible
    @sprites["shadow#{targetBattler}"].visible=false
    ball=sprintf("Graphics/#{BATTLE_ROUTE}/ball%02d",balltype)
    ballopen=sprintf("Graphics/#{BATTLE_ROUTE}/ball%02d_open",balltype)
    # sprites
    spritePoke=@sprites["pokemon#{targetBattler}"]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    spritePlayer=@sprites["player"] if animtrainer
    # pictures
    pictureBall=PictureEx.new(spritePoke.z+1)
    picturePoke=PictureEx.new(spritePoke.z)
    dims=[spritePoke.x,spritePoke.y]
    center=getSpriteCenter(@sprites["pokemon#{targetBattler}"])
    if @battle.doublebattle
      ballendy=PokeBattle_SceneConstants::FOEBATTLERD1_Y-4 if targetBattler==1
      ballendy=PokeBattle_SceneConstants::FOEBATTLERD2_Y-4 if targetBattler==3
    else
      ballendy=PokeBattle_SceneConstants::FOEBATTLER_Y-4
    end
    if animtrainer
      picturePlayer=PictureEx.new(spritePoke.z+2)
      playerpos=[@sprites["player"].x,@sprites["player"].y]
    end
    # starting positions
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ball)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    if animtrainer
      pictureBall.moveXY(0,1,64,256)
    else
      pictureBall.moveXY(0,1,10,180)
    end
    picturePoke.moveVisible(1,true)
    picturePoke.moveOrigin(1,PictureOrigin::Center)
    picturePoke.moveXY(0,1,center[0],center[1])
    if animtrainer
      picturePlayer.moveVisible(1,true)
      picturePlayer.moveName(1,spritePlayer.name)
      picturePlayer.moveOrigin(1,PictureOrigin::TopLeft)
      picturePlayer.moveXY(0,1,playerpos[0],playerpos[1])
    end
    # directives
    picturePoke.moveSE(1,"Audio/SE/throw")
    if animtrainer
      pictureBall.moveCurve(30,1,64,256,30+Graphics.width/2,10,center[0],center[1])
      pictureBall.moveAngle(30,1,-720)
    else
      pictureBall.moveCurve(30,1,150,70,30+Graphics.width/2,10,center[0],center[1])
      pictureBall.moveAngle(30,1,-1080)
    end
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    delay=pictureBall.totalDuration+4
    picturePoke.moveTone(10,delay,Tone.new(0,-224,-224,0))
    delay=picturePoke.totalDuration
    picturePoke.moveSE(delay,"Audio/SE/recall")
    pictureBall.moveName(delay+4,ballopen)
    if animtrainer
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
    loop do
      pictureBall.update
      picturePoke.update
      picturePlayer.update if animtrainer
      setPictureIconSprite(spriteBall,pictureBall)
      setPictureSprite(spritePoke,picturePoke)
      setPictureIconSprite(spritePlayer,picturePlayer) if animtrainer
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running? && !picturePoke.running?
    end
    # Burst animation here
    if burst>=0 && scene.battle.battlescene
      scene.pbCommonAnimation("BallBurst#{burst}",battler,nil)
    end
    pictureBall.clearProcesses
    picturePoke.clearProcesses
    delay=0
    picturePoke.moveZoom(15,delay,0)
    picturePoke.moveXY(15,delay,center[0],center[1])
    picturePoke.moveSE(delay+10,"Audio/SE/jumptoball")
    picturePoke.moveVisible(delay+15,false)
    pictureBall.moveName(picturePoke.totalDuration+2,ball)
    delay=pictureBall.totalDuration+6
    if critical
      pictureBall.moveSE(delay,"Audio/SE/ballshake")
      pictureBall.moveXY(2,delay,center[0]+4,center[1])
      pictureBall.moveXY(4,pictureBall.totalDuration,center[0]-4,center[1])
      pictureBall.moveSE(pictureBall.totalDuration,"Audio/SE/ballshake")
      pictureBall.moveXY(4,pictureBall.totalDuration,center[0]+4,center[1])
      pictureBall.moveXY(4,pictureBall.totalDuration,center[0]-4,center[1])
      pictureBall.moveXY(2,pictureBall.totalDuration,center[0],center[1])
      delay=pictureBall.totalDuration+4
    end
    pictureBall.moveXY(10,delay,center[0],ballendy)
    pictureBall.moveSE(pictureBall.totalDuration,"Audio/SE/balldrop")
    pictureBall.moveXY(5,pictureBall.totalDuration+2,center[0],ballendy-((ballendy-center[1])/2))
    pictureBall.moveXY(5,pictureBall.totalDuration+2,center[0],ballendy)
    pictureBall.moveSE(pictureBall.totalDuration,"Audio/SE/balldrop")
    pictureBall.moveXY(3,pictureBall.totalDuration+2,center[0],ballendy-((ballendy-center[1])/4))
    pictureBall.moveXY(3,pictureBall.totalDuration+2,center[0],ballendy)
    pictureBall.moveSE(pictureBall.totalDuration,"Audio/SE/balldrop")
    pictureBall.moveXY(1,pictureBall.totalDuration+2,center[0],ballendy-((ballendy-center[1])/8))
    pictureBall.moveXY(1,pictureBall.totalDuration+2,center[0],ballendy)
    pictureBall.moveSE(pictureBall.totalDuration,"Audio/SE/balldrop")
    picturePoke.moveXY(0,pictureBall.totalDuration,center[0],ballendy)
    delay=pictureBall.totalDuration+18# if shakes==0
    numshakes = (critical) ? 1 : [shakes,3].min
    numshakes.times do
      pictureBall.moveSE(delay,"Audio/SE/ballshake")
      pictureBall.moveXY(3,delay,center[0]-8,ballendy)
      pictureBall.moveAngle(3,delay,20) # positive means counterclockwise
      delay=pictureBall.totalDuration
      pictureBall.moveXY(6,delay,center[0]+8,ballendy)
      pictureBall.moveAngle(6,delay,-20) # negative means clockwise
      delay=pictureBall.totalDuration
      pictureBall.moveXY(3,delay,center[0],ballendy)
      pictureBall.moveAngle(3,delay,0)
      delay=pictureBall.totalDuration+18
    end
    if shakes<4
      picturePoke.moveSE(delay,"Audio/SE/recall")
      pictureBall.moveName(delay,ballopen)
      pictureBall.moveVisible(delay+10,false)
      picturePoke.moveVisible(delay,true)
      picturePoke.moveZoom(15,delay,100)
      picturePoke.moveXY(15,delay,center[0],center[1])
      picturePoke.moveTone(0,delay,Tone.new(248,248,248,248))
      picturePoke.moveTone(24,delay,Tone.new(0,0,0,0))
      delay=picturePoke.totalDuration
    end
    pictureBall.moveXY(0,delay,center[0],ballendy)
    picturePoke.moveOrigin(picturePoke.totalDuration,PictureOrigin::TopLeft)
    picturePoke.moveXY(0,picturePoke.totalDuration,dims[0],dims[1])
    loop do
      pictureBall.update
      picturePoke.update
      setPictureIconSprite(spriteBall,pictureBall)
      setPictureSprite(spritePoke,picturePoke)
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running? && !picturePoke.running?
    end
    if shakes<4
      @sprites["shadow#{targetBattler}"].visible=oldvisible
      spriteBall.dispose
    else
      spriteBall.tone=Tone.new(-64,-64,-64,128)
      pbSEPlay("ballcatch",100,150)
      spriteBall.color = Color.new(0,0,0,0)
      ballstar = {}
      stargraphic= "Graphics/#{BATTLE_ROUTE}/battle_star"
      
      if !pbResolveBitmap(stargraphic).nil?
        for j in 0...3
          ballstar["#{j}"] = Sprite.new(spriteBall.viewport)
          ballstar["#{j}"].bitmap = BitmapCache.load_bitmap(stargraphic)
          ballstar["#{j}"].ox = ballstar["#{j}"].bitmap.width/2
          ballstar["#{j}"].oy = ballstar["#{j}"].bitmap.height/2
          ballstar["#{j}"].x = spriteBall.x
          ballstar["#{j}"].y = spriteBall.y
          ballstar["#{j}"].opacity = 0
          ballstar["#{j}"].z = spriteBall.z + 1
        end
        for i in 0...16
          for j in 0...3
            ballstar["#{j}"].y -= [3,4,3][j]
            ballstar["#{j}"].x -= [3,0,-3][j]
            ballstar["#{j}"].opacity += 32*(i < 8 ? 1 : -1)
            ballstar["#{j}"].angle += [4,2,-4][j]
          end
          @sprites["battlebox#{targetBattler}"].opacity-=25.5
          spriteBall.color.alpha += 8
          pbWait(1)
        end
      end
      @sprites["capture"]=spriteBall
      spritePoke.visible=false
    end
  end
    