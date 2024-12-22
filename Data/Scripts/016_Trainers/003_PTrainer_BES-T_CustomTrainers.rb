# ------------------------------------------------------------------------------
# Written by Stochastic, except for customTrainerBattle method which is a
# modified version of pbTrainerBattle method.
# Ligeramente modificado por Clara para BES
# ------------------------------------------------------------------------------
BR_DRAW = 5
BR_LOSS = 2
BR_WIN = 1
# ------------------------------------------------------------------------------
# species - Name of the species, e.g. "PIKACHU"
# level - Level
# moveset - Optional. Array of moves, e.g. [:MUDSLAP, :THUNDERBOLT, :VINEWHIP]
# If not specified, pokemon will be created with moves learned by leveling.
# The pokemon doesn't need to be able to learn the given moves, they can be
# arbitary.
# ------------------------------------------------------------------------------
def createPokemon(species, level, moveset=nil)
  begin
    poke = PokeBattle_Pokemon.new(species, level)
    poke.moves = convertMoves(moveset) if moveset
    poke.shinyflag = false
    return poke
  rescue
    return PokeBattle_Pokemon.new("PIKACHU", 5)
  end
end

def convertMoves(moves)
  moves.map! {|m| PBMove.new(getMoveID(m))}
  return moves
end

# provide move like this; :TACKLE
def getMoveID(move)
  return getConst(PBMoves,move)
end

# ------------------------------------------------------------------------------
# Creates a trainer with specified id, name, party, and optionally, items.
# Does not depend on defined trainers, only on trainer types
# ------------------------------------------------------------------------------
def createTrainer(trainerid,trainername,party,items=[])
  name = pbGetMessageFromHash(MessageTypes::TrainerNames, trainername)
  
  if trainerid.is_a?(String) || trainerid.is_a?(Symbol)
    pbTrainerTypeCheck(trainerid)
    return false if !hasConst?(PBTrainers,trainerid)
    trainerid=PBTrainers.const_get(trainerid)
  end
  
  opponent = PokeBattle_Trainer.new(name, trainerid)
  opponent.setForeignID($Trainer) if $Trainer
  opponent.party = party
  
  return [opponent,items,party]
end

# ------------------------------------------------------------------------------
# Initiates trainer battle. This is a modified pbTrainerBattle method.
#
# trainer - custom PokeBattle_Trainer provided by the user
# endspeech - what the trainer says in-battle when defeated
# doublebattle - Optional. Set it to true if you want a double battle
# canlose - Optional. Set it to true if you want your party to be healed after battle,
#and if you don't want to be sent to a pokemon center if you lose
# ------------------------------------------------------------------------------
def customTrainerBattle(trainer,endspeech,doublebattle=false,canlose=false)
  trainerparty=0 # added by SH
  if $Trainer.pokemonCount==0
    Kernel.pbMessage("SKIPPING BATTLE...") if $DEBUG
    return BR_LOSS # changed by SH
  end
  if !$PokemonTemp.waitingTrainer && $Trainer.ablePokemonCount>1 &&
     pbMapInterpreterRunning?
    thisEvent=pbMapInterpreter.get_character(0)
    triggeredEvents=$game_player.pbTriggeredTrainerEvents([2],false)
    otherEvent=[]
    for i in triggeredEvents
      if i.id!=thisEvent.id && !$game_self_switches[[$game_map.map_id,i.id,"A"]]
        otherEvent.push(i)
      end
    end
    if otherEvent.length==1
      if trainer[2].length<=3
        $PokemonTemp.waitingTrainer=[trainer,thisEvent.id,endspeech,doublebattle]
        return BR_LOSS # changed by SH
      end
    end
  end
  
  if $PokemonGlobal.partner && ($PokemonTemp.waitingTrainer || doublebattle)
    othertrainer=PokeBattle_Trainer.new(
       $PokemonGlobal.partner[1],$PokemonGlobal.partner[0])
    othertrainer.id=$PokemonGlobal.partner[2]
    othertrainer.party=$PokemonGlobal.partner[3]
    playerparty=[]
    for i in 0...$Trainer.party.length
      playerparty[i]=$Trainer.party[i]
    end
    for i in 0...othertrainer.party.length
      playerparty[6+i]=othertrainer.party[i]
    end
    fullparty1=true
    playertrainer=[$Trainer,othertrainer]
    doublebattle=true
  else
    playerparty=$Trainer.party
    playertrainer=$Trainer
    fullparty1=false
  end
  if $PokemonTemp.waitingTrainer
    combinedParty=[]
    fullparty2=false
    if false
      if $PokemonTemp.waitingTrainer[0][2].length>3
        raise "Opponent 1's party has more than three Pokémon, which is not allowed"
      end
      if trainer[2].length>3
        raise "Opponent 2's party has more than three Pokémon, which is not allowed"
      end
    elsif $PokemonTemp.waitingTrainer[0][2].length>3 || trainer[2].length>3
      for i in 0...$PokemonTemp.waitingTrainer[0][2].length
        combinedParty[i]=$PokemonTemp.waitingTrainer[0][2][i]
      end
      for i in 0...trainer[2].length
        combinedParty[6+i]=trainer[2][i]
      end
      fullparty2=true
    else
      for i in 0...$PokemonTemp.waitingTrainer[0][2].length
        combinedParty[i]=$PokemonTemp.waitingTrainer[0][2][i]
      end
      for i in 0...trainer[2].length
        combinedParty[3+i]=trainer[2][i]
      end
      fullparty2=false
    end
    scene=pbNewBattleScene
    battle=PokeBattle_Battle.new(scene,playerparty,combinedParty,playertrainer,
       [$PokemonTemp.waitingTrainer[0][0],trainer[0]])
    trainerbgm=pbGetTrainerBattleBGM(
       [$PokemonTemp.waitingTrainer[0][0],trainer[0]])
    battle.fullparty1=fullparty1
    battle.fullparty2=fullparty2
    battle.doublebattle=battle.pbDoubleBattleAllowed?()
    battle.endspeech=$PokemonTemp.waitingTrainer[2]
    battle.endspeech2=endspeech
    battle.items=[$PokemonTemp.waitingTrainer[0][1],trainer[1]]
  else
    scene=pbNewBattleScene
    battle=PokeBattle_Battle.new(scene,playerparty,trainer[2],playertrainer,trainer[0])
    battle.fullparty1=fullparty1
    battle.doublebattle=doublebattle ? battle.pbDoubleBattleAllowed?() : false
    battle.endspeech=endspeech
    battle.items=trainer[1]
    trainerbgm=pbGetTrainerBattleBGM(trainer[0])
  end
  if Input.press?(Input::CTRL) && $DEBUG
    Kernel.pbMessage("SKIPPING BATTLE...")
    Kernel.pbMessage("AFTER LOSING...")
    Kernel.pbMessage(battle.endspeech)
    Kernel.pbMessage(battle.endspeech2) if battle.endspeech2
    if $PokemonTemp.waitingTrainer
      pbMapInterpreter.pbSetSelfSwitch(
         $PokemonTemp.waitingTrainer[1],"A",true
      )
      $PokemonTemp.waitingTrainer=nil
    end
    return BR_WIN # changed by SH
  end
  Events.onStartBattle.trigger(nil,nil)
  battle.internalbattle=true
  pbPrepareBattle(battle)
  restorebgm=true
  decision=0
  tr = [trainer]; tr.push($PokemonTemp.waitingTrainer[0]) if $PokemonTemp.waitingTrainer
  pbBattleAnimation(trainerbgm,(battle.doublebattle) ? 3 : 1,tr) {
    pbSceneStandby {
        decision=battle.pbStartBattle(canlose)
     }
    pbAfterBattle(decision,canlose)
    if decision==1
      if $PokemonTemp.waitingTrainer
         pbMapInterpreter.pbSetSelfSwitch($PokemonTemp.waitingTrainer[1],"A",true)
      end
    end
  }
  Input.update
  $PokemonTemp.waitingTrainer=nil
  return decision  # changed by SH
end