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
# BES-T: Efecto de captura Essentials v21
#   Adaptado por maartiiindev_ para BES
#===============================================================================
  POKEBALL_ANIM_SPEED = 2
  POKEBALL_STAR_SPEED = 3
  POKEBALL_BURST_SPEED = 3

  def pokeballThrow(ball,shakes,critical,targetBattler,scene,battler,burst=-1,showplayer=false)
    spd=lambda{|n| (n*POKEBALL_ANIM_SPEED).round}

    balltype=pbGetBallType(ball)
    poke_ball=$BallTypes[balltype] || :POKEBALL
    success=(shakes>=4)
    numShakes=(critical && shakes>0) ? 1 : shakes

    oldvisible=@sprites["shadow#{targetBattler}"].visible
    @sprites["shadow#{targetBattler}"].visible=false
    ballfile=sprintf("Graphics/#{BATTLE_ROUTE}/ball_%s",poke_ball)
    ballopenfile=sprintf("Graphics/#{BATTLE_ROUTE}/ball_%s_open",poke_ball)

    spritePoke=@sprites["pokemon#{targetBattler}"]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false

    cropBallFrame=lambda{
      next if !spriteBall.bitmap
      if spriteBall.bitmap.width>=spriteBall.bitmap.height
        spriteBall.src_rect.x=0
        spriteBall.src_rect.y=0
        spriteBall.src_rect.width=spriteBall.bitmap.height/2
        spriteBall.src_rect.height=spriteBall.bitmap.height
      end
      spriteBall.ox=spriteBall.src_rect.width/2
      spriteBall.oy=spriteBall.src_rect.height/2
    }

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
    ballGroundY=ballendy

    # Lanzamiento: Arco hasta el otro Pokémon
    ballStartX=-6
    ballStartY=246
    pictureBall.moveXY(0,1,ballStartX,ballStartY)
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ballfile)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    pictureBall.moveSE(1,"Audio/SE/throw")
    midX=(ballStartX+center[0])/2
    midY=[ballStartY,center[1]].min-140
    pictureBall.moveCurve(spd.call(16),1,midX,midY,midX,midY,center[0],center[1])
    pictureBall.moveAngle(spd.call(16),1,critical ? -1440 : -1080)
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    loop do
      pictureBall.update
      setPictureIconSprite(spriteBall,pictureBall)
      cropBallFrame.call
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running?
    end
    pictureBall.clearProcesses

    pictureBall.moveName(1,ballopenfile)
    pictureBall.moveSE(1,"Audio/SE/recall")
    loop do
      pictureBall.update
      setPictureIconSprite(spriteBall,pictureBall)
      cropBallFrame.call
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running?
    end
    pictureBall.clearProcesses
    spd.call(6).times do
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
    end

    # Destello y absorbido 
    picturePoke.moveXY(0,1,center[0],center[1])
    picturePoke.moveVisible(1,true)
    picturePoke.moveOrigin(1,PictureOrigin::Center)
    picturePoke.moveSE(1,"Audio/SE/jumptoball")
    picturePoke.moveZoom(spd.call(5),1,0)
    picturePoke.moveXY(spd.call(5),1,center[0],center[1])
    picturePoke.moveVisible(1+spd.call(5),false)

    burstParticles,burstFrames=pbCaptureAbsorbBurst(spritePoke.z+2,center[0],center[1],poke_ball,POKEBALL_BURST_SPEED)

    loop do
      picturePoke.update
      setPictureSprite(spritePoke,picturePoke)
      if burstFrames>0
        burstParticles.each { |pic,spr| pic.update; setPictureIconSprite(spr,pic) }
        burstFrames-=1
      end
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !picturePoke.running? && burstFrames<=0
    end
    burstParticles.each { |pic,spr| spr.dispose }
    picturePoke.clearProcesses

    pictureBall.moveName(1,ballfile)
    pictureBall.moveTone(spd.call(3),1,Tone.new(96,64,-160,160))
    pictureBall.moveTone(spd.call(3),1+spd.call(3),Tone.new(0,0,0,0))
    loop do
      pictureBall.update
      setPictureIconSprite(spriteBall,pictureBall)
      cropBallFrame.call
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running?
    end
    pictureBall.clearProcesses
    #------------------
    delay=1
    if critical
      pictureBall.moveXY(spd.call(1),delay,center[0]+4,ballendy+50)
      pictureBall.moveXY(spd.call(2),pictureBall.totalDuration,center[0]-4,ballendy+50)
      pictureBall.moveXY(spd.call(1),pictureBall.totalDuration,center[0],ballendy+50)
      delay=pictureBall.totalDuration+spd.call(3)
    end
    bounce_heights=[1,2,4,8]
    bounce_times=[4,4,3,2]
    bounce_start_y=center[1]
    4.times do |i|
      t=spd.call(bounce_times[i])
      d=bounce_heights[i]
      pictureBall.moveXY(t,delay,center[0],ballGroundY-((ballGroundY-bounce_start_y)/d))
      pictureBall.moveXY(t,pictureBall.totalDuration,center[0],ballGroundY)
      pictureBall.moveSE(pictureBall.totalDuration,"Audio/SE/Battle ball drop")
      delay=pictureBall.totalDuration
    end

    # Shake ball
    delay=pictureBall.totalDuration+spd.call(18)
    [numShakes,3].min.times do |i|
      pictureBall.moveSE(delay,"Audio/SE/ballshake")
      pictureBall.moveXY(spd.call(3),delay,center[0]-8,ballGroundY)
      pictureBall.moveAngle(spd.call(3),delay,20)
      delay=pictureBall.totalDuration
      pictureBall.moveXY(spd.call(6),delay,center[0]+8,ballGroundY)
      pictureBall.moveAngle(spd.call(6),delay,-20)
      delay=pictureBall.totalDuration
      pictureBall.moveXY(spd.call(3),delay,center[0],ballGroundY)
      pictureBall.moveAngle(spd.call(3),delay,0)
      delay=pictureBall.totalDuration+spd.call(18)
    end
    loop do
      pictureBall.update
      setPictureIconSprite(spriteBall,pictureBall)
      cropBallFrame.call
      pbGraphicsUpdate
      pbInputUpdate
      pbFrameUpdate
      break if !pictureBall.running?
    end
    pictureBall.clearProcesses
    #-------------------------------
    if success
      # Captura exitosa
      pbSEPlay("Battle catch click",100,150)
      ballstar = {}
      stargraphic= "Graphics/#{BATTLE_ROUTE}/ballBurst_star"
      if !pbResolveBitmap(stargraphic).nil?
        star_duration = 16*POKEBALL_STAR_SPEED
        x_dir      = [-1, 0, 1]
        y_offsets  = [[0,74,52],[0,62,28],[0,74,48]]
        start_ang  = [0,345,15]
        spin_extra = [144,0,45]
        for j in 0...3
          ballstar["#{j}"] = Sprite.new(spriteBall.viewport)
          ballstar["#{j}"].bitmap = BitmapCache.load_bitmap(stargraphic)
          ballstar["#{j}"].ox = ballstar["#{j}"].bitmap.width/2
          ballstar["#{j}"].oy = ballstar["#{j}"].bitmap.height/2
          ballstar["#{j}"].x = spriteBall.x
          ballstar["#{j}"].y = spriteBall.y
          ballstar["#{j}"].opacity = 0
          ballstar["#{j}"].z = spriteBall.z + 1
          ballstar["#{j}"].angle = start_ang[j]
          ballstar["#{j}"].zoom_x = [0.5,0.5,0.33][j]
          ballstar["#{j}"].zoom_y = ballstar["#{j}"].zoom_x
        end
        for i in 0...star_duration
          index = i+1
          proportion = index.to_f/star_duration
          for j in 0...3
            x = 72*index/star_duration
            yp = y_offsets[j]
            a = (2*yp[2])-(4*yp[1])
            b = yp[2]-a
            y = ((a*proportion)+b)*proportion
            ballstar["#{j}"].x = spriteBall.x+(x_dir[j]*x)
            ballstar["#{j}"].y = spriteBall.y-y
            ballstar["#{j}"].angle += spin_extra[j].to_f/star_duration if j.even?
            if i<4
              ballstar["#{j}"].opacity += 64
            elsif i>=star_duration-4
              ballstar["#{j}"].opacity -= 64
            end
            if i==2
              ballstar["#{j}"].tone = Tone.new(0,0,-96)
            elsif i==5
              ballstar["#{j}"].tone = Tone.new(0,0,0)
            end
          end
          @sprites["battlebox#{targetBattler}"].opacity-=15
          pbWait(1)
        end
        for j in 0...3
          ballstar["#{j}"].dispose
        end
      end
      spd.call(16).times do
        spriteBall.opacity-=16
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
      end
      spritePoke.visible=false
      spriteBall.dispose
    else
      pictureBall.moveName(1,ballopenfile)
      pictureBall.moveSE(1,"Audio/SE/recall")
      loop do
        pictureBall.update
        setPictureIconSprite(spriteBall,pictureBall)
        cropBallFrame.call
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
        break if !pictureBall.running?
      end
      pictureBall.clearProcesses

      # Falla la captura
      failBurst,failFrames=pbCaptureAbsorbBurst(spritePoke.z-1,center[0],ballGroundY,poke_ball,POKEBALL_BURST_SPEED)

      picturePoke.moveXY(0,1,center[0],ballGroundY)
      picturePoke.moveZoom(0,1,0)
      picturePoke.moveVisible(1,true)
      picturePoke.moveTone(0,1,Tone.new(248,248,248,248))
      picturePoke.moveZoom(spd.call(15),1,100)
      picturePoke.moveOrigin(1,PictureOrigin::TopLeft)
      picturePoke.moveXY(spd.call(15),1,dims[0],dims[1])
      picturePoke.moveTone(spd.call(24),1,Tone.new(0,0,0,0))

      loop do
        picturePoke.update
        setPictureSprite(spritePoke,picturePoke)
        if failFrames>0
          failBurst.each { |pic,spr| pic.update; setPictureIconSprite(spr,pic) }
          failFrames-=1
        end
        pbGraphicsUpdate
        pbInputUpdate
        pbFrameUpdate
        break if !picturePoke.running? && failFrames<=0
      end
      failBurst.each { |pic,spr| spr.dispose }
      picturePoke.clearProcesses
      @sprites["shadow#{targetBattler}"].visible=oldvisible
      spriteBall.dispose
    end
  end