class PokeBattle_FakeBattler
  def initialize(pokemon,index)
    @pokemon=pokemon
    @index=index
    @owned=$Trainer.owned[pokemon.species]
  end

  def index; return @index; end
  def pokemon; @pokemon; end
  def species; @pokemon.species; end
  def gender; @pokemon.gender; end
  def status; @pokemon.status; end
  def hp; @pokemon.hp; end
  def level; @pokemon.level; end
  def name; @pokemon.name; end
  def totalhp; @pokemon.totalhp; end
  def owned; return @owned; end
  def isFainted?; return false; end
  def isShiny?; return @pokemon.isShiny?; end
  def isShadow?; return false; end
  def hasMega?; return false; end
  def isMega?; return false; end
  def hasPrimal?; return false; end
  def isPrimal?; return false; end
  def displayGender; return @pokemon.gender; end
  def captured; return false; end
  def captured=(value); end

  def pbThis(lowercase=false)
    return lowercase ? _INTL("el {1} salvaje",@pokemon.name) : _INTL("El {1} salvaje",@pokemon.name)
  end
end



class PokeBattle_SafariZone
  attr_accessor :environment
  attr_accessor :party1
  attr_accessor :party2
  attr_reader :player
  attr_accessor :battlescene
  include PokeBattle_BattleCommon

  def initialize(scene,player,party2)
    @scene=scene
    @party2=party2
    @peer=PokeBattle_BattlePeer.create()
    @firstfailedthrow=false # First failed catch attempt with a pokeball
    @player=player
    @battlers=[
       PokeBattle_FakeBattler.new(party2[0],0),
       PokeBattle_FakeBattler.new(party2[0],1),
       PokeBattle_FakeBattler.new(party2[0],2),
       PokeBattle_FakeBattler.new(party2[0],3)
    ]
    @environment=PBEnvironment::None
    @battlescene=true
    @decision=0
    @ballcount=0
  end

  def pbIsOpposing?(index)
    return (index%2)==1
  end

  def pbIsDoubleBattler?(index)
    return (index>=2)
  end

  def battlers; return @battlers; end
  def opponent; return nil; end
  def doublebattle; return false; end

  def ballcount
    return (@ballcount<0) ? 0 : @ballcount
  end

  def ballcount=(value)
    @ballcount=(value<0) ? 0 : value
  end

  def pbPlayer
    return @player
  end



  class BattleAbortedException < Exception
  end



  def pbAbort
    raise BattleAbortedException.new("Battle aborted")
  end

  def pbEscapeRate(rareness)
    ret=25
    ret=50 if rareness<200
    ret=75 if rareness<150
    ret=100 if rareness<100
    ret=125 if rareness<25
    return ret
  end

  def pbStartBattle
    begin
      wildpoke=@party2[0]
      self.pbPlayer.seen[wildpoke.species]=true
      pbSeenForm(wildpoke)
      @scene.pbStartBattle(self)
      pbDisplayPaused(_INTL("¡Apareció un {1} salvaje!",wildpoke.name))
      @scene.pbSafariStart
      dexdata=pbOpenDexData
      pbDexDataOffset(dexdata,wildpoke.species,16)
      rareness=dexdata.fgetb # Get rareness from dexdata file
      dexdata.close
      g=(rareness*100)/1275
      e=(pbEscapeRate(rareness)*100)/1275
      g=[[g,3].max,20].min
      e=[[e,3].max,20].min
      lastCommand=0
      begin
        cmd=@scene.pbSafariCommandMenu(0)
        case cmd
        when 0 # Ball
          if pbBoxesFull?
            pbDisplay(_INTL("¡Las cajas están llenas! ¡Ya no puedes capturar más Pokémon!"))
            next
          end
          @ballcount-=1
          rare=(g*1275)/100
          safariBall=getConst(PBItems,:SAFARIBALL)
          if safariBall
            result=pbThrowPokeBall(1,safariBall,rare,true,true,@firstfailedthrow)
            case result
            when 0
              @firstfailedthrow=true
            when -1
              @ballcount+=1
              @firstfailedthrow=true
            end
          end
        when 1 # Bait
          pbDisplayBrief(_INTL("¡{1} tiró algunos cebos hacia {2}!",self.pbPlayer.name,wildpoke.name))
          @scene.pbThrowBait
          g/=2 # Harder to catch
          e/=2 # Less likely to escape
          g=[[g,3].max,20].min
          e=[[e,3].max,20].min
          lastCommand=1
        when 2 # Rock
          pbDisplayBrief(_INTL("¡{1} tiró una roca al {2}!",self.pbPlayer.name,wildpoke.name))
          @scene.pbThrowRock
          g*=2 # Easier to catch
          e*=2 # More likely to escape
          g=[[g,3].max,20].min
          e=[[e,3].max,20].min
          lastCommand=2
        when 3 # Run
          pbDisplayPaused(_INTL("¡Has huido sin problemas!"))
          @decision=3
        end
        if @decision==0
          if @ballcount<=0
            pbDisplay(_INTL("Anuncio: ¡No te quedan más Safari Balls! ¡Fin del juego!")) 
            @decision=2
          elsif pbRandom(100)<5*e
             pbDisplay(_INTL("¡{1} huyó!",wildpoke.name))
             @decision=3
          elsif lastCommand==1
             pbDisplay(_INTL("¡{1} está comiendo!",wildpoke.name)) 
          elsif lastCommand==2
             pbDisplay(_INTL("¡{1} está enojado!",wildpoke.name)) 
          else
             pbDisplay(_INTL("¡{1} te está mirando fijamente!",wildpoke.name)) 
          end
        end
      end while @decision==0
      @scene.pbEndBattle(@decision)
    rescue BattleAbortedException
      @decision=0
      @scene.pbEndBattle(@decision)
    end
    return @decision
  end

  #############
  def pbDebugUpdate
    @debugupdate+=1
    if @debugupdate==30
#     Graphics.update
      @debugupdate=0
    end
  end

  def pbDisplayPaused(msg)
    if @debug
      pbDebugUpdate
      PBDebug.log(msg)
    else
      @scene.pbDisplayPausedMessage(msg)
    end
  end

  def pbDisplay(msg)
    if @debug
      pbDebugUpdate
      PBDebug.log(msg)
    else
      @scene.pbDisplayMessage(msg)
    end
  end

  def pbDisplayBrief(msg)
    if @debug
      pbDebugUpdate
      PBDebug.log(msg)
    else
      @scene.pbDisplayMessage(msg,true)
    end
  end

  def pbDisplayConfirm(msg)
    if @debug
      pbDebugUpdate
      PBDebug.log(msg)
      return true
    else
      return @scene.pbDisplayConfirmMessage(msg)
    end
  end

  def pbAIRandom(x)
    return rand(x)
  end

  def pbRandom(x)
    return rand(x)
  end

  def pbGainEXP; end
end