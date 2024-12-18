class BugContestState
  attr_accessor :ballcount
  attr_accessor :decision
  attr_accessor :lastPokemon
  attr_reader :timer
  ContestantNames=[
     _INTL("Cazabichos Eduardo"),
     _INTL("Cazabichos Benito"),
     _INTL("Cazabichos José"),
     _INTL("Campista Gabriel"),
     _INTL("Entrenador Guay Nico"),
     _INTL("Chica Abril"),
     _INTL("Dominguera Cintia"),
     _INTL("Joven Samuel")
  ]
  TimerSeconds=BUGCONTESTTIME

  def initialize
    clear
    @lastContest=nil
  end

  def pbContestHeld?
    return false if !@lastContest
    timenow=pbGetTimeNow
    return timenow.to_i-@lastContest<86400
  end

  def expired?
    return false if !undecided?
    return false if TimerSeconds<=0
    curtime=@timer+TimerSeconds*Graphics.frame_rate
    curtime=[curtime-Graphics.frame_count,0].max
    return (curtime<=0)
  end

  def clear
    @ballcount=0
    @ended=false
    @inProgress=false
    @decision=0
    @encounterMap=0
    @lastPokemon=nil
    @otherparty=[]
    @contestants=[]
    @places=[]
    @start=nil
    @reception=[]
  end

  def inProgress?
    return @inProgress
  end

  def undecided?
    return (@inProgress && @decision==0)
  end

  def decided?
    return (@inProgress && @decision!=0) || @ended
  end

  def pbSetPokemon(chosenpoke)
    @chosenPokemon=chosenpoke
  end

# Reception map is handled separately from contest map since the reception map
# can be outdoors, with its own grassy patches.
  def pbSetReception(*arg)
    @reception=[]
    for i in arg
      @reception.push(i)
    end
  end

  def pbOffLimits?(map)
#    p [map,@contestMap,@reception]
    return false if map==@contestMap
    for i in @reception
      return false if map==i
    end
    return true
  end

  def pbSetJudgingPoint(startMap,startX,startY,dir=8)
    @start=[startMap,startX,startY,dir]
  end

  def pbSetContestMap(map)
    @contestMap=map
  end

  def pbJudge
    judgearray=[]
    if @lastPokemon
      judgearray.push([-1,@lastPokemon.species,pbBugContestScore(@lastPokemon)])
    end
    @contestants=[]
    [5,ContestantNames.length].min.times do
      loop do
        value=rand(ContestantNames.length)
        if !@contestants.any?{|i| i==value }
          @contestants.push(value)
          break
        end
      end
    end
    enctype=EncounterTypes::BugContest
    if !$PokemonEncounters.pbMapHasEncounter?(@contestMap,enctype)
      enctype=EncounterTypes::Land
    end
    for cont in @contestants
      enc=$PokemonEncounters.pbMapEncounter(@contestMap,enctype)
      if !enc
        raise _INTL("No hay Pokémon salvajes en el mapa {1}, por lo que se cancela el concurso.",@contestMap)
      end
      pokemon=PokeBattle_Pokemon.new(enc[0],enc[1],$Trainer)
      pokemon.hp=rand(pokemon.totalhp)
      score=pbBugContestScore(pokemon)
      judgearray.push([cont,pokemon.species,score])
    end
    if judgearray.length<3
      raise _INTL("Muy pocos concursantes cazando bichos.")
    end
    judgearray.sort!{|a,b| b[2]<=>a[2]} # sort by score in descending order
    @places.push(judgearray[0])
    @places.push(judgearray[1])
    @places.push(judgearray[2])
  end

  def pbGetPlaceInfo(place)
    cont=@places[place][0]
    if cont<0
      $game_variables[1]=$Trainer.name
    else
      $game_variables[1]=ContestantNames[cont]
    end
    $game_variables[2]=PBSpecies.getName(@places[place][1])
    $game_variables[3]=@places[place][2]
  end

  def pbClearIfEnded
    if !@inProgress
      if !(@start && @start[0]==$game_map.map_id)
        clear
      end
    end
  end

  def pbStartJudging
    @decision=1
    pbJudge
    if $scene.is_a?(Scene_Map)
      pbFadeOutIn(99999){
         $game_temp.player_transferring = true
         $game_temp.player_new_map_id = @start[0]
         $game_temp.player_new_x = @start[1]
         $game_temp.player_new_y = @start[2]
         $game_temp.player_new_direction = @start[3]
         $scene.transfer_player
         $game_map.need_refresh=true # in case player moves to the same map
      }
    end
  end

  def pbIsContestant?(i)
    return @contestants.any?{|item|  i==item }
  end

  def pbStart(ballcount)
    @ballcount=ballcount
    @inProgress=true
    @otherparty=[]
    @lastPokemon=nil
    @lastContest=nil
    @timer=Graphics.frame_count
    @places=[]
    chosenpkmn=$Trainer.party[@chosenPokemon]
    for i in 0...$Trainer.party.length
      if i!=@chosenPokemon
        @otherparty.push($Trainer.party[i])
      end
    end
    @contestants=[]
    [5,ContestantNames.length].min.times do
      loop do
        value=rand(ContestantNames.length)
        if !@contestants.any?{|i| i==value }
          @contestants.push(value)
          break
        end
      end
    end
    $Trainer.party=[chosenpkmn]
    @decision=0
    @ended=false
  end

  def place
    for i in 0...3
      return i if @places[i][0]<0
    end
    return 3
  end

  def pbEnd(interrupted=false)
    return if !@inProgress
    for poke in @otherparty
      $Trainer.party.push(poke)
    end
    if !interrupted 
      if @lastPokemon
        pbNicknameAndStore(@lastPokemon)
      end
      @ended=true
    else
      @ended=false
    end
    @lastPokemon=nil
    @otherparty=[]
    @reception=[]
    @ballcount=0
    @inProgress=false
    @decision=0
    timenow=pbGetTimeNow
    @lastContest=timenow.to_i
    $game_map.need_refresh=true
  end
end

# Returns a score for this Pokemon in the Bug Catching Contest.
# Not exactly the HGSS calculation, but it should be decent enough.
def pbBugContestScore(pokemon)
  levelscore=pokemon.level*4
  ivscore=0
  for i in pokemon.iv; ivscore+=i; end
  ivscore=(ivscore*100/186).floor
  hpscore=(100*pokemon.hp/pokemon.totalhp).floor
  dexdata=pbOpenDexData
  pbDexDataOffset(dexdata,pokemon.species,16)
  rareness=dexdata.fgetb
  dexdata.close
  rarescore=60
  rarescore+=20 if rareness<=120
  rarescore+=20 if rareness<=60
  score=levelscore+ivscore+hpscore+rarescore
  return score
end

def pbBugContestState
  if !$PokemonGlobal.bugContestState
    $PokemonGlobal.bugContestState=BugContestState.new
  end
  return $PokemonGlobal.bugContestState
end

# Returns true if the Bug Catching Contest in progress
def pbInBugContest?
  return pbBugContestState.inProgress?
end

# Returns true if the Bug Catching Contest in progress and has not yet been judged
def pbBugContestUndecided?
  return pbBugContestState.undecided?
end

# Returns true if the Bug Catching Contest in progress and is being judged
def pbBugContestDecided?
  return pbBugContestState.decided?
end



class PokeBattle_BugContestBattle < PokeBattle_Battle
  attr_accessor :ballcount

  def initialize(*arg)
    @ballcount=0
    super(*arg)
  end

  def pbItemMenu(index)
    @ballcount-=1 if @ballcount>0
    return [getConst(PBItems,:SPORTBALL) || -1,index]
  end

  def pbCommandMenu(i)
    return @scene.pbCommandMenuEx(i,[
       _INTL("Compet Balls: {1}",@ballcount),
       _INTL("Luchar"),
       _INTL("Ball"),
       _INTL("Pokémon"),
       _INTL("Huir")
    ],3)
  end

  def pbStorePokemon(pokemon)
    if pbBugContestState.lastPokemon
      lastPokemon=pbBugContestState.lastPokemon
      pbDisplayPaused(_INTL("Ya has capturado un {1}.",lastPokemon.name))
      helptext=_INTL("POKéMON ANTERIOR:<br> {1} Nv{2} MáxPS: {3}<br>ESTE POKÉMON:<br> {4} Nv{5} MáxPS: {6}",
         lastPokemon.name,lastPokemon.level,lastPokemon.totalhp,
         pokemon.name,pokemon.level,pokemon.totalhp
      )
      @scene.pbShowHelp(helptext)
      if pbDisplayConfirm(_INTL("¿Cambiar Pokémon?"))
        pbBugContestState.lastPokemon=pokemon
        @scene.pbHideHelp
      else
        @scene.pbHideHelp
        return
      end
    else
      pbBugContestState.lastPokemon=pokemon
    end
    pbDisplay(_INTL("¡{1} capturado!",pokemon.name))
  end

  def pbEndOfRoundPhase
    super
    if @ballcount<=0 && @decision==0
      @decision=3
    end
  end
end



class TimerDisplay # :nodoc:
  def initialize(start,maxtime)
    @timer=Window_AdvancedTextPokemon.newWithSize("",Graphics.width-120,0,120,64)
    @timer.z=99999
    @total_sec=nil
    @start=start
    @maxtime=maxtime
  end

  def dispose
    @timer.dispose
  end

  def disposed?
    @timer.disposed?
  end

  def update
    curtime=[(@start+@maxtime)-Graphics.frame_count,0].max
    curtime/=Graphics.frame_rate
    if curtime != @total_sec
      # Calculate total number of seconds
      @total_sec = curtime
      # Make a string for displaying the timer
      min = @total_sec / 60
      sec = @total_sec % 60
      @timer.text = _ISPRINTF("<ac>{1:02d}:{2:02d}", min, sec)
    end
  end
end



Events.onMapChange+=proc{|sender,e|
   pbBugContestState.pbClearIfEnded
}

Events.onMapSceneChange+=proc{|sender,e|
   scene=e[0]
   mapChanged=e[1]
   if pbInBugContest? && pbBugContestState.decision==0 && BugContestState::TimerSeconds>0
     scene.spriteset.addUserSprite(TimerDisplay.new(
        pbBugContestState.timer,
        BugContestState::TimerSeconds*Graphics.frame_rate))
   end
}

Events.onMapUpdate+=proc{|sender,e|
   if !$Trainer || !$PokemonGlobal || !$game_player || !$game_map
     # do nothing
   elsif !$game_player.move_route_forcing && !pbMapInterpreterRunning? &&
         !$game_temp.message_window_showing
     if pbBugContestState.expired?
       Kernel.pbMessage("ANUNCIADOR: ¡BEEEEEP!")
       Kernel.pbMessage("¡Tiempo fuera!")
       pbBugContestState.pbStartJudging
     end
   end
}

Events.onMapChanging+=proc{|sender,e|
   newmapID=e[0]
   newmap=e[1]
   if pbInBugContest?
     if pbBugContestState.pbOffLimits?(newmapID)
       # Clear bug contest if player flies/warps/teleports out of the contest
       pbBugContestState.pbEnd(true)
     end
   end
}

def Kernel.pbBugContestStartOver
  for i in $Trainer.party; i.heal; end
  pbBugContestState.pbStartJudging
end

Events.onWildBattleOverride+= proc { |sender,e|
   species=e[0]
   level=e[1]
   handled=e[2]
   next if handled[0]!=nil
   next if !pbInBugContest?
   handled[0]=pbBugContestBattle(species,level)
}

def pbBugContestBattle(species,level)
  genwildpoke=pbGenerateWildPokemon(species,level)
  Events.onStartBattle.trigger(nil,genwildpoke)
  scene=pbNewBattleScene
  battle=PokeBattle_BugContestBattle.new(scene,$Trainer.party,[genwildpoke],$Trainer,nil)
  battle.ballcount=pbBugContestState.ballcount
  battle.internalbattle=true
  decision=0
  pbBattleAnimation(pbGetWildBattleBGM(species)) { 
     decision=battle.pbStartBattle
     Events.onEndBattle.trigger(nil,decision,true)
     if decision==2 || decision==5
       $game_system.bgm_unpause
       $game_system.bgs_unpause
       Kernel.pbBugContestStartOver
     end
  }
  pbBugContestState.ballcount=battle.ballcount
  Input.update
  Events.onWildBattleEnd.trigger(nil,species,level,decision)
  if pbBugContestState.ballcount==0
    Kernel.pbMessage("ANUNCIADOR: ¡El Concurso Cazabichos ha terminado!")
    pbBugContestState.pbStartJudging
  end
  return (decision!=2 && decision!=5)
end