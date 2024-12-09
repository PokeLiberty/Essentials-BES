#===============================================================================
# Start a single wild battle
#===============================================================================
def pbWildBattle(species,level,variable=nil,canescape=true,canlose=false)
  if (Input.press?(Input::CTRL) && $DEBUG) || $Trainer.pokemonCount==0
    if $Trainer.pokemonCount>0
      Kernel.pbMessage(_INTL("SALTANDO BATALLA..."))
    end
    pbSet(variable,1)
    $PokemonGlobal.nextBattleBGM=nil
    $PokemonGlobal.nextBattleME=nil
    $PokemonGlobal.nextBattleBack=nil
    return true
  end
  canescape = $PokemonTemp.battle_rules["canRun"]
  canescape = !$PokemonTemp.battle_rules["canotRun"]
  if species.is_a?(String) || species.is_a?(Symbol)
    species=getID(PBSpecies,species)
  end
  handled=[nil]
  Events.onWildBattleOverride.trigger(nil,species,level,handled)
  return handled[0] if handled[0]!=nil
  currentlevels=[]
  for i in $Trainer.party
    currentlevels.push(i.level)
  end
  genwildpoke=pbGenerateWildPokemon(species,level)
  Events.onStartBattle.trigger(nil,genwildpoke)
  scene=pbNewBattleScene
  battle=PokeBattle_Battle.new(scene,$Trainer.party,[genwildpoke],$Trainer,nil)
  battle.internalbattle=true
  battle.cantescape=!canescape
  pbPrepareBattle(battle)
  decision=0
  pbBattleAnimation(pbGetWildBattleBGM(species),0,[genwildpoke]) {
     pbSceneStandby {
        decision=battle.pbStartBattle(canlose)
     }
     pbAfterBattle(decision,canlose)
  }
  Input.update
  pbSet(variable,decision)
  Events.onWildBattleEnd.trigger(nil,species,level,decision)
  return (decision!=2)
end
#===============================================================================
# Start a double wild battle
#===============================================================================
def pbDoubleWildBattle(species1,level1,species2=nil,level2=nil,variable=nil,canescape=true,canlose=false)
  if (Input.press?(Input::CTRL) && $DEBUG) || $Trainer.pokemonCount==0
    if $Trainer.pokemonCount>0
      Kernel.pbMessage(_INTL("SALTANDO BATALLA..."))
    end
    pbSet(variable,1)
    $PokemonGlobal.nextBattleBGM=nil
    $PokemonGlobal.nextBattleME=nil
    $PokemonGlobal.nextBattleBack=nil
    return true
  end
  if species1.is_a?(String) || species1.is_a?(Symbol)
    species1=getID(PBSpecies,species1)
  end
  if species2
    if species2.is_a?(String) || species2.is_a?(Symbol)
      species2=getID(PBSpecies,species2)
    end
  end
  currentlevels=[]
  for i in $Trainer.party
    currentlevels.push(i.level)
  end
  genwildpoke=pbGenerateWildPokemon(species1,level1)
  genwildpoke2=pbGenerateWildPokemon(species2,level2) if species2
  Events.onStartBattle.trigger(nil,genwildpoke)
  scene=pbNewBattleScene

  if $PokemonGlobal.partner
    othertrainer=PokeBattle_Trainer.new(
       $PokemonGlobal.partner[1],$PokemonGlobal.partner[0])
    othertrainer.id=$PokemonGlobal.partner[2]
    othertrainer.party=$PokemonGlobal.partner[3]
    combinedParty=[]
    for i in 0...$Trainer.party.length
      combinedParty[i]=$Trainer.party[i]
    end
    for i in 0...othertrainer.party.length
      combinedParty[6+i]=othertrainer.party[i]
    end
    if genwildpoke2
      battle=PokeBattle_Battle.new(scene,combinedParty,[genwildpoke,genwildpoke2],
                                   [$Trainer,othertrainer],nil)
    else
      battle=PokeBattle_Battle.new(scene,combinedParty,[genwildpoke],
                                   [$Trainer,othertrainer],nil)
    end
    battle.fullparty1=true
  else
    if genwildpoke2
      battle=PokeBattle_Battle.new(scene,$Trainer.party,[genwildpoke,genwildpoke2],
                                   $Trainer,nil)
    else
      battle=PokeBattle_Battle.new(scene,$Trainer.party,[genwildpoke],
                                   $Trainer,nil)
    end
    battle.fullparty1=false
  end
  battle.internalbattle=true
  battle.doublebattle=battle.pbDoubleBattleAllowed?()
  battle.doublebattle=true if $Trainer.party.length>1
  battle.cantescape=!canescape
  pbPrepareBattle(battle)
  decision=0
  pbBattleAnimation(pbGetWildBattleBGM(species1),0,[genwildpoke]) {
     pbSceneStandby {
        decision=battle.pbStartBattle(canlose)
     }
     pbAfterBattle(decision,canlose)
  }
  Input.update
  pbSet(variable,decision)
  return (decision!=2 && decision!=5)
end

#===============================================================================
# Start a trainer battle against one trainer
#===============================================================================

def pbTrainerBattle(trainerid,trainername,endspeech="...",
                  doublebattle=false,trainerparty=0,canlose=false,variable=nil)
if $Trainer.pokemonCount==0
  Kernel.pbMessage(_INTL("SALTANDO COMBATES...")) if $DEBUG
  return false
end
doublebattle=true if $PokemonTemp.battle_rules["double"] || $PokemonTemp.battle_rules["2v2"]
doublebattle=false if $PokemonTemp.battle_rules["single"] || $PokemonTemp.battle_rules["1v1"]
if !$PokemonTemp.waitingTrainer && pbMapInterpreterRunning? &&
   ($Trainer.ablePokemonCount>1 || $Trainer.ablePokemonCount>0 && $PokemonGlobal.partner)
  thisEvent=pbMapInterpreter.get_character(0)
  triggeredEvents=$game_player.pbTriggeredTrainerEvents([2],false)
  otherEvent=[]
  for i in triggeredEvents
    if i.id!=thisEvent.id && !$game_self_switches[[$game_map.map_id,i.id,"A"]]
      otherEvent.push(i)
    end
  end
  if otherEvent.length==1
    trainer=pbLoadTrainer(trainerid,trainername,trainerparty)
    Events.onTrainerPartyLoad.trigger(nil,trainer)
    if !trainer
      pbMissingTrainer(trainerid,trainername,trainerparty)
      return false
    end
    if trainer[2].length<=6
      $PokemonTemp.waitingTrainer=[trainer,thisEvent.id,endspeech]
      return false
    end
  end
end
trainer=pbLoadTrainer(trainerid,trainername,trainerparty)
Events.onTrainerPartyLoad.trigger(nil,trainer)
if !trainer
  pbMissingTrainer(trainerid,trainername,trainerparty)
  return false
end
if $PokemonGlobal.partner && ($PokemonTemp.waitingTrainer || doublebattle)
  othertrainer = PokeBattle_Trainer.new($PokemonGlobal.partner[1],$PokemonGlobal.partner[0])
  othertrainer.id=$PokemonGlobal.partner[2]
  othertrainer.party=$PokemonGlobal.partner[3]
  playerparty=[]
  for i in 0...$Trainer.party.length
    playerparty[i]=$Trainer.party[i]
  end
  for i in 0...othertrainer.party.length
    playerparty[6+i]=othertrainer.party[i]
  end
  playertrainer = [$Trainer,othertrainer]
  fullparty1=true
  doublebattle=true
else
  playerparty=$Trainer.party
  playertrainer=$Trainer
  fullparty1=false
end
if $PokemonTemp.waitingTrainer
  combinedParty=[]
  fullparty2=false
  if $PokemonTemp.waitingTrainer[0][2].length>3 || trainer[2].length>3
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
  battle.fullparty1=fullparty1
  battle.fullparty2=fullparty2
  battle.doublebattle=battle.pbDoubleBattleAllowed?()
  battle.endspeech=$PokemonTemp.waitingTrainer[2]
  battle.endspeech2=endspeech
  battle.items=[$PokemonTemp.waitingTrainer[0][1],trainer[1]]
  trainerbgm=pbGetTrainerBattleBGM([$PokemonTemp.waitingTrainer[0][0],trainer[0]])
else
  scene=pbNewBattleScene
  battle=PokeBattle_Battle.new(scene,playerparty,trainer[2],playertrainer,trainer[0])
  battle.fullparty1=fullparty1
  battle.doublebattle=(doublebattle) ? battle.pbDoubleBattleAllowed?() : false
  battle.endspeech=endspeech
  battle.items=trainer[1]
  trainerbgm=pbGetTrainerBattleBGM(trainer[0])
end
if Input.press?(Input::CTRL) && $DEBUG
  Kernel.pbMessage(_INTL("SALTANDO COMBATES..."))
  Kernel.pbMessage(_INTL("TRAS PERDER..."))
  Kernel.pbMessage(battle.endspeech)
  Kernel.pbMessage(battle.endspeech2) if battle.endspeech2
  if $PokemonTemp.waitingTrainer
    pbMapInterpreter.pbSetSelfSwitch($PokemonTemp.waitingTrainer[1],"A",true)
    $PokemonTemp.waitingTrainer=nil
  end
  return true
end
Events.onStartBattle.trigger(nil,nil)
battle.internalbattle=true
pbPrepareBattle(battle)
restorebgm=true
decision=0
Audio.me_stop
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
pbSet(variable,decision)
$PokemonTemp.waitingTrainer=nil
return (decision==1)
end


#===============================================================================
# Start a trainer battle against two trainers
#===============================================================================
def pbDoubleTrainerBattle(trainerid1, trainername1, trainerparty1, endspeech1,
                        trainerid2, trainername2, trainerparty2, endspeech2, 
                        canlose=false,variable=nil)
trainer1=pbLoadTrainer(trainerid1,trainername1,trainerparty1)
Events.onTrainerPartyLoad.trigger(nil,trainer1)
if !trainer1
  pbMissingTrainer(trainerid1,trainername1,trainerparty1)
end
trainer2=pbLoadTrainer(trainerid2,trainername2,trainerparty2)
Events.onTrainerPartyLoad.trigger(nil,trainer2)
if !trainer2
  pbMissingTrainer(trainerid2,trainername2,trainerparty2)
end
if !trainer1 || !trainer2
  return false
end
if $PokemonGlobal.partner
  othertrainer = PokeBattle_Trainer.new($PokemonGlobal.partner[1],$PokemonGlobal.partner[0])
  othertrainer.id=$PokemonGlobal.partner[2]
  othertrainer.party=$PokemonGlobal.partner[3]
  playerparty=[]
  for i in 0...$Trainer.party.length
    playerparty[i]=$Trainer.party[i]
  end
  for i in 0...othertrainer.party.length
    playerparty[6+i]=othertrainer.party[i]
  end
  playertrainer = [$Trainer,othertrainer]
  fullparty1=true
else
  playerparty=$Trainer.party
  playertrainer=$Trainer
  fullparty1=false
end
combinedParty=[]
for i in 0...trainer1[2].length
  combinedParty[i]=trainer1[2][i]
end
for i in 0...trainer2[2].length
  combinedParty[6+i]=trainer2[2][i]
end
scene=pbNewBattleScene
battle = PokeBattle_Battle.new(scene,playerparty,combinedParty,playertrainer,
                               [trainer1[0],trainer2[0]])
battle.fullparty1=fullparty1
battle.fullparty2=true
battle.doublebattle=battle.pbDoubleBattleAllowed?()
battle.endspeech=endspeech1
battle.endspeech2=endspeech2
battle.items=[trainer1[1],trainer2[1]]
trainerbgm = pbGetTrainerBattleBGM([trainer1[0],trainer2[0]])
if Input.press?(Input::CTRL) && $DEBUG
  Kernel.pbMessage(_INTL("SALTANDO COMBATES..."))
  Kernel.pbMessage(_INTL("TRAS PERDER..."))
  Kernel.pbMessage(battle.endspeech)
  Kernel.pbMessage(battle.endspeech2) if battle.endspeech2 && battle.endspeech2!=""
  return true
end
Events.onStartBattle.trigger(nil,nil)
battle.internalbattle=true
pbPrepareBattle(battle)
restorebgm=true
decision=0
pbBattleAnimation(trainerbgm,(battle.doublebattle) ? 3 : 1,[trainer1,trainer2]) {
   pbSceneStandby {
      decision=battle.pbStartBattle(canlose)
   }
   pbAfterBattle(decision,canlose)
}
Input.update
pbSet(variable,decision)
return (decision==1)
end

#===============================================================================
# After battles
#===============================================================================
def pbAfterBattle(decision,canlose)
  for i in $Trainer.party
    (i.makeUnmega rescue nil); (i.makeUnprimal rescue nil); (i.revertOtherForms rescue nil)
  end
  if $PokemonGlobal.partner
    pbHealAll
    for i in $PokemonGlobal.partner[3]
      i.heal
      (i.makeUnmega rescue nil); (i.makeUnprimal rescue nil); (i.revertOtherForms rescue nil);
    end
  end
  if decision==2 || decision==5 # if loss or draw
    if canlose
      for i in $Trainer.party;
        i.heal
        (i.makeUnmega rescue nil); (i.makeUnprimal rescue nil); (i.revertOtherForms rescue nil);
      end
      for i in 0...10
        Graphics.update
      end
    end
  end
  Events.onEndBattle.trigger(nil,decision,canlose)
end


#===============================================================================
# Batalla contrá un pokémon ya creado. (BES-T)
#===============================================================================
def pbWildBattlePoke(poke,variable=nil,canescape=true,canlose=false)
  species = poke.species
  level = poke.level
  
  if (Input.press?(Input::CTRL) && $DEBUG) || $Trainer.pokemonCount==0
    if $Trainer.pokemonCount>0
      Kernel.pbMessage(_INTL("SALTANDO BATALLA..."))
    end
    pbSet(variable,1)
    $PokemonGlobal.nextBattleBGM=nil
    $PokemonGlobal.nextBattleME=nil
    $PokemonGlobal.nextBattleBack=nil
    return true
  end
  canescape = $PokemonTemp.battle_rules["canRun"]
  canescape = !$PokemonTemp.battle_rules["canotRun"]
  
  genwildpoke=poke
  Events.onStartBattle.trigger(nil,genwildpoke)
  scene=pbNewBattleScene
  battle=PokeBattle_Battle.new(scene,$Trainer.party,[genwildpoke],$Trainer,nil)
  battle.internalbattle=true
  battle.cantescape=!canescape
  pbPrepareBattle(battle)
  decision=0
  pbBattleAnimation(pbGetWildBattleBGM(species)) {
     pbSceneStandby {
        decision=battle.pbStartBattle(canlose)
     }
     pbAfterBattle(decision,canlose)
  }
  Input.update
  pbSet(variable,decision)
  Events.onWildBattleEnd.trigger(nil,species,level,decision)
  return (decision!=2)
end