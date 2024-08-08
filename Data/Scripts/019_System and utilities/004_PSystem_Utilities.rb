################################################################################
# Player-related utilities, random name generator
################################################################################
def pbChangePlayer(id)
  return false if id<0 || id>=8
  meta=pbGetMetadata(0,MetadataPlayerA+id)
  return false if !meta
  $Trainer.trainertype=meta[0] if $Trainer
  $game_player.character_name=meta[1]
  $game_player.character_hue=0
  $PokemonGlobal.playerID=id
  $Trainer.metaID=id if $Trainer
end

def pbGetPlayerGraphic
  id=$PokemonGlobal.playerID
  return "" if id<0 || id>=8
  meta=pbGetMetadata(0,MetadataPlayerA+id)
  return "" if !meta
  return pbPlayerSpriteFile(meta[0])
end

def pbGetPlayerTrainerType
  id=$PokemonGlobal.playerID
  return 0 if id<0 || id>=8
  meta=pbGetMetadata(0,MetadataPlayerA+id)
  return 0 if !meta
  return meta[0]
end

def pbGetTrainerTypeGender(trainertype)
  ret=2 # 2 = gender unknown
  pbRgssOpen("Data/trainertypes.dat","rb"){|f|
     trainertypes=Marshal.load(f)
     if !trainertypes[trainertype]
       ret=2
     else
       ret=trainertypes[trainertype][7]
       ret=2 if !ret
     end
  }
  return ret
end

def pbTrainerName(name=nil,outfit=0)
  if $PokemonGlobal.playerID<0
    pbChangePlayer(0)
  end
  trainertype=pbGetPlayerTrainerType
  trname=name
  $Trainer=PokeBattle_Trainer.new(trname,trainertype)
  $Trainer.outfit=outfit
  if trname==nil
    trname=pbEnterPlayerName(_INTL("¿Cuál es tu nombre?"),0,7)
    if trname==""
      gender=pbGetTrainerTypeGender(trainertype)
      trname=pbSuggestTrainerName(gender)
    end
  end
  $Trainer.name=trname
  $PokemonBag=PokemonBag.new
  $PokemonTemp.begunNewGame=true
end

def pbSuggestTrainerName(gender)
  userName=pbGetUserName()
  userName=userName.gsub(/\s+.*$/,"")
  if userName.length>0 && userName.length<7
    userName[0,1]=userName[0,1].upcase
    return userName
  end
  userName=userName.gsub(/\d+$/,"")
  if userName.length>0 && userName.length<7
    userName[0,1]=userName[0,1].upcase
    return userName
  end
  owner=MiniRegistry.get(MiniRegistry::HKEY_LOCAL_MACHINE,
     "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
     "RegisteredOwner","")
  owner=owner.gsub(/\s+.*$/,"")
  if owner.length>0 && owner.length<7
    owner[0,1]=owner[0,1].upcase
    return owner
  end
  return getRandomNameEx(gender,nil,1,7)
end

################################################################################
# General-purpose utilities with dependencies
################################################################################
# Similar to pbFadeOutIn, but pauses the music as it fades out.
# Requires scripts "Audio" (for bgm_pause) and "SpriteWindow" (for pbFadeOutIn).
def pbExclaim(event,id=EXCLAMATION_ANIMATION_ID,tinting=false)
  if event.is_a?(Array)
    sprite=nil
    done=[]
    for i in event
      if !done.include?(i.id)
        sprite=$scene.spriteset.addUserAnimation(id,i.x,i.y,tinting)
        done.push(i.id)
      end
    end
  else
    sprite=$scene.spriteset.addUserAnimation(id,event.x,event.y,tinting)
  end
  while !sprite.disposed?
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end
end

def pbNoticePlayer(event)
  if !pbFacingEachOther(event,$game_player)
    pbExclaim(event)
  end
  pbTurnTowardEvent($game_player,event)
  Kernel.pbMoveTowardPlayer(event)
end

################################################################################
# Creating and storing Pokémon
################################################################################
# For demonstration purposes only, not to be used in a real game.
def pbCreatePokemon
  party=[]
  species=[:RABSCA,:PIDGEOTTO,:TATSUGIRI,:DONDOZO,:DIGLETT,:CHANSEY]
  for id in species
    party.push(getConst(PBSpecies,id)) if hasConst?(PBSpecies,id)
  end
  # Species IDs of the Pokémon to be created
  for i in 0...party.length
    species=party[i]
    # Generate Pokémon with species and level 20
    $Trainer.party[i]=PokeBattle_Pokemon.new(species,20,$Trainer)
    $Trainer.seen[species]=true # Set this species to seen and owned
    $Trainer.owned[species]=true
    pbSeenForm($Trainer.party[i])
  end
  $Trainer.party[0].pbLearnMove(:REVIVALBLESSING)
  $Trainer.party[0].pbLearnMove(:TELEPORT)
  $Trainer.party[1].pbLearnMove(:FLY)
  $Trainer.party[2].pbLearnMove(:FLASH)
  $Trainer.party[3].pbLearnMove(:SURF)
  $Trainer.party[3].pbLearnMove(:DIVE)
  $Trainer.party[3].pbLearnMove(:WATERFALL)
  $Trainer.party[4].pbLearnMove(:DIG)
  $Trainer.party[4].pbLearnMove(:CUT)
  $Trainer.party[4].pbLearnMove(:HEADBUTT)
  $Trainer.party[4].pbLearnMove(:ROCKSMASH)
  $Trainer.party[5].pbLearnMove(:SOFTBOILED)
  $Trainer.party[5].pbLearnMove(:STRENGTH)
  $Trainer.party[5].pbLearnMove(:SWEETSCENT)
  for i in 0...party.length
    $Trainer.party[i].pbRecordFirstMoves
  end
end

def pbBoxesFull?
  return !$Trainer || ($Trainer.party.length==6 && $PokemonStorage.full?)
end

def pbNickname(pokemon)
  speciesname=PBSpecies.getName(pokemon.species)
  if Kernel.pbConfirmMessage(_INTL("¿Quieres ponerle un mote a {1}?",speciesname))
    helptext=_INTL("Apodo de {1}",speciesname)
    newname=pbEnterPokemonName(helptext,0,10,"",pokemon)
    pokemon.name=newname if newname!=""
  end
end

def pbStorePokemon(pokemon)
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("¡No hay espacio para el Pokémon!\1"))
    Kernel.pbMessage(_INTL("¡Las Cajas del PC están llenas y no aceptan ni un Pokémon más!"))
    return
  end
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length]=pokemon
  else
    pokemon2 = -1
    if Kernel.pbConfirmMessageSerious(_INTL("¿Te gustaría añadir a {1} a tu equipo?",pokemon.name))
      Kernel.pbMessage(_INTL("Selecciona un Pokémon para intercambiar."))
      pbChoosePokemon(1,2)
      poke = pbGet(1)
      if poke != -1
        pokemon2 = pokemon
        pokemon = $Trainer.pokemonParty[poke]
        pbRemovePokemonAt(poke)
        $Trainer.party[$Trainer.party.length] = pokemon2
      end
    end
    oldcurbox=$PokemonStorage.currentBox
    storedbox=$PokemonStorage.pbStoreCaught(pokemon)
    curboxname=$PokemonStorage[oldcurbox].name
    boxname=$PokemonStorage[storedbox].name
    creator=nil
    creator=Kernel.pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
    if storedbox!=oldcurbox
      if creator
        Kernel.pbMessage(_INTL("La caja \"{1}\" del PC de {2} está llena.\1",curboxname,creator))
      else
        Kernel.pbMessage(_INTL("La caja \"{1}\" del PC de alguien PC está llena.\1",curboxname))
      end
      Kernel.pbMessage(_INTL("{1} fue transferido a la caja \"{2}\".",pokemon.name,boxname))
    else
      if creator
        Kernel.pbMessage(_INTL("{1} fue transferido al PC de {2}.\1",pokemon.name,creator))
      else
        Kernel.pbMessage(_INTL("{1} fue transferido al PC de alguien.\1",pokemon.name))
      end
      Kernel.pbMessage(_INTL("Fue guardado en la caja \"{1}\".",boxname))
    end
    if pokemon2 != -1
      pbSEPlay("PokemonGet")
      Kernel.pbMessage(_INTL("¡{1} se une al equipo {2}!",$Trainer.name,pokemon2.name))
    end
  end
end

def pbNicknameAndStore(pokemon,nick=true)
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("¡No hay espacio para el Pokémon!\1"))
    Kernel.pbMessage(_INTL("¡Las Cajas del PC están llenas y no aceptan ni un Pokémon más!"))
    return
  end
  $Trainer.seen[pokemon.species]=true
  $Trainer.owned[pokemon.species]=true
  pbNickname(pokemon) if nick
  pbStorePokemon(pokemon)
end

def pbAddPokemon(pokemon,level=nil,seeform=true,nick=true)
  return if !pokemon || !$Trainer
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("¡No hay espacio para el Pokémon!\1"))
    Kernel.pbMessage(_INTL("¡Las Cajas del PC están llenas y no aceptan ni un Pokémon más!"))
    return false
  end
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon=getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon=PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  speciesname=PBSpecies.getName(pokemon.species)
  Kernel.pbMessage(_INTL("¡{1} ha obtenido un {2}!\\se[PokemonGet]\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon) if nick
  pbSeenForm(pokemon) if seeform
  return true
end

def pbAddPokemonSilent(pokemon,level=nil,seeform=true)
  return false if !pokemon || pbBoxesFull? || !$Trainer
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon=getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon=PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  $Trainer.seen[pokemon.species]=true
  $Trainer.owned[pokemon.species]=true
  pbSeenForm(pokemon) if seeform
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length]=pokemon
  else
    $PokemonStorage.pbStoreCaught(pokemon)
  end
  return true
end

def pbAddToParty(pokemon,level=nil,seeform=true)
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon=getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon=PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  speciesname=PBSpecies.getName(pokemon.species)
  Kernel.pbMessage(_INTL("¡{1} ha obtenido un {2}!\\se[PokemonGet]\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon)
  pbSeenForm(pokemon) if seeform
  return true
end

def pbAddToPartySilent(pokemon,level=nil,seeform=true)
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon=getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon=PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  $Trainer.seen[pokemon.species]=true
  $Trainer.owned[pokemon.species]=true
  pbSeenForm(pokemon) if seeform
  pokemon.pbRecordFirstMoves
  $Trainer.party[$Trainer.party.length]=pokemon
  return true
end

def pbAddForeignPokemon(pokemon,level=nil,ownerName=nil,nickname=nil,ownerGender=0,seeform=true)
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon=getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon=PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  # Set original trainer to a foreign one (if ID isn't already foreign)
  if pokemon.trainerID==$Trainer.id
    pokemon.trainerID=$Trainer.getForeignID
    pokemon.ot=ownerName if ownerName && ownerName!=""
    pokemon.otgender=ownerGender
  end
  # Set nickname
  pokemon.name=nickname[0,10] if nickname && nickname!=""
  # Recalculate stats
  pokemon.calcStats
  if ownerName
    Kernel.pbMessage(_INTL("{1} ha recibido un Pokémon de {2}.\\se[PokemonGet]\1",$Trainer.name,ownerName))
  else
    Kernel.pbMessage(_INTL("{1} ha recibido un Pokémon.\\se[PokemonGet]\1",$Trainer.name))
  end
  pbStorePokemon(pokemon)
  $Trainer.seen[pokemon.species]=true
  $Trainer.owned[pokemon.species]=true
  pbSeenForm(pokemon) if seeform
  return true
end

def pbGenerateEgg(pokemon,text="",steps=nil)
  return false if !pokemon || !$Trainer
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon=getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer)
    pokemon=PokeBattle_Pokemon.new(pokemon,EGGINITIALLEVEL,$Trainer)
  end
  # Get egg steps
  dexdata=pbOpenDexData
  pbDexDataOffset(dexdata,pokemon.species,21)
  eggsteps=dexdata.fgetw
  dexdata.close
  # Set egg's details
  pokemon.name=_INTL("Huevo")
  if steps !=nil
    pokemon.eggsteps=steps
  else
    pokemon.eggsteps=eggsteps
  end
  pokemon.obtainText=text
  pokemon.calcStats
  # Add egg to party or PC
  pbStorePokemon(pokemon)
  return true
end

def pbRemovePokemonAt(index)
  return false if index<0 || !$Trainer || index>=$Trainer.party.length
  haveAble=false
  for i in 0...$Trainer.party.length
    next if i==index
    haveAble=true if $Trainer.party[i].hp>0 && !$Trainer.party[i].isEgg?
  end
  return false if !haveAble
  $Trainer.party.delete_at(index)
  return true
end

def pbSeenForm(poke,gender=0,form=0)
  $Trainer.formseen=[] if !$Trainer.formseen
  $Trainer.formlastseen=[] if !$Trainer.formlastseen
  if poke.is_a?(String) || poke.is_a?(Symbol)
    poke=getID(PBSpecies,poke)
  end
  if poke.is_a?(PokeBattle_Pokemon)
    gender=poke.gender
    form=(poke.form rescue 0)
    species=poke.species
  else
    species=poke
  end
  return if !species || species<=0
  gender=0 if gender>1
  formnames=pbGetMessage(MessageTypes::FormNames,species)
  form=0 if !formnames || formnames==""
  $Trainer.formseen[species]=[[],[]] if !$Trainer.formseen[species]
  $Trainer.formseen[species][gender][form]=true
  $Trainer.formlastseen[species]=[] if !$Trainer.formlastseen[species]
  $Trainer.formlastseen[species]=[gender,form] if $Trainer.formlastseen[species]==[]
end

################################################################################
# Analysing Pokémon
################################################################################
# Heals all Pokémon in the party.
def pbHealAll
  return if !$Trainer
  for i in $Trainer.party
    i.heal
  end
end

# Returns the first unfainted, non-egg Pokémon in the player's party.
def pbFirstAblePokemon(variableNumber)
  for i in 0...$Trainer.party.length
    p=$Trainer.party[i]
    if p && !p.isEgg? && p.hp>0
      pbSet(variableNumber,i)
      return $Trainer.party[i]
    end
  end
  pbSet(variableNumber,-1)
  return nil
end

# Checks whether the player would still have an unfainted Pokémon if the
# Pokémon given by _pokemonIndex_ were removed from the party.
def pbCheckAble(pokemonIndex)
  for i in 0...$Trainer.party.length
    p=$Trainer.party[i]
    next if i==pokemonIndex
    return true if p && !p.isEgg? && p.hp>0
  end
  return false
end

# Returns true if there are no usable Pokémon in the player's party.
def pbAllFainted
  for i in $Trainer.party
    return false if !i.isEgg? && i.hp>0
  end
  return true
end

def pbBalancedLevel(party)
  return 1 if party.length==0
  # Calculate the mean of all levels
  sum=0
  party.each{|p| sum+=p.level }
  return 1 if sum==0
  average=sum.to_f/party.length.to_f
  # Calculate the standard deviation
  varianceTimesN=0
  for i in 0...party.length
    deviation=party[i].level-average
    varianceTimesN+=deviation*deviation
  end
  # Note: This is the "population" standard deviation calculation, since no
  # sample is being taken
  stdev=Math.sqrt(varianceTimesN/party.length)
  mean=0
  weights=[]
  # Skew weights according to standard deviation
  for i in 0...party.length
    weight=party[i].level.to_f/sum.to_f
    if weight<0.5
      weight-=(stdev/PBExperience::MAXLEVEL.to_f)
      weight=0.001 if weight<=0.001
    else
      weight+=(stdev/PBExperience::MAXLEVEL.to_f)
      weight=0.999 if weight>=0.999
    end
    weights.push(weight)
  end
  weightSum=0
  weights.each{|weight| weightSum+=weight }
  # Calculate the weighted mean, assigning each weight to each level's
  # contribution to the sum
  for i in 0...party.length
    mean+=party[i].level*weights[i]
  end
  mean/=weightSum
  # Round to nearest number
  mean=mean.round
  # Adjust level to minimum
  mean=1 if mean<1
  # Add 2 to the mean to challenge the player
  mean+=2
  # Adjust level to maximum
  mean=PBExperience::MAXLEVEL if mean>PBExperience::MAXLEVEL
  return mean
end

# Returns the Pokémon's size in millimeters.
def pbSize(pokemon)
  dexdata=pbOpenDexData
  pbDexDataOffset(dexdata,pokemon.species,33)
  baseheight=dexdata.fgetw # Gets the base height in tenths of a meter
  dexdata.close
  hpiv=pokemon.iv[0]&15
  ativ=pokemon.iv[1]&15
  dfiv=pokemon.iv[2]&15
  spiv=pokemon.iv[3]&15
  saiv=pokemon.iv[4]&15
  sdiv=pokemon.iv[5]&15
  m=pokemon.personalID&0xFF
  n=(pokemon.personalID>>8)&0xFF
  s=(((ativ^dfiv)*hpiv)^m)*256+(((saiv^sdiv)*spiv)^n)
  xyz=[]
  if s<10
    xyz=[290,1,0]
  elsif s<110
    xyz=[300,1,10]
  elsif s<310
    xyz=[400,2,110]
  elsif s<710
    xyz=[500,4,310]
  elsif s<2710
    xyz=[600,20,710]
  elsif s<7710
    xyz=[700,50,2710]
  elsif s<17710
    xyz=[800,100,7710]
  elsif s<32710
    xyz=[900,150,17710]
  elsif s<47710
    xyz=[1000,150,32710]
  elsif s<57710
    xyz=[1100,100,47710]
  elsif s<62710
    xyz=[1200,50,57710]
  elsif s<64710
    xyz=[1300,20,62710]
  elsif s<65210
    xyz=[1400,5,64710]
  elsif s<65410
    xyz=[1500,2,65210]
  else
    xyz=[1700,1,65510]
  end
  return (((s-xyz[2])/xyz[1]+xyz[0]).floor*baseheight/10).floor
end

# Returns true if the given species can be legitimately obtained as an egg.
def pbHasEgg?(species)
  if species.is_a?(String) || species.is_a?(Symbol)
    species=getID(PBSpecies,species)
  end
  evospecies=pbGetEvolvedFormData(species)
  compatspecies=(evospecies && evospecies[0]) ? evospecies[0][2] : species
  dexdata=pbOpenDexData
  pbDexDataOffset(dexdata,compatspecies,31)
  compat1=dexdata.fgetb   # Get egg group 1 of this species
  compat2=dexdata.fgetb   # Get egg group 2 of this species
  dexdata.close
  return false if isConst?(compat1,PBEggGroups,:Ditto) ||
                  isConst?(compat1,PBEggGroups,:Undiscovered) ||
                  isConst?(compat2,PBEggGroups,:Ditto) ||
                  isConst?(compat2,PBEggGroups,:Undiscovered)
  baby=pbGetBabySpecies(species)
  return true if species==baby   # Is a basic species
  baby=pbGetBabySpecies(species,0,0)
  return true if species==baby   # Is an egg species without incense
  return false
end

################################################################################
# Look through Pokémon in storage, choose a Pokémon in the party
################################################################################
# Yields every Pokémon/egg in storage in turn.
def pbEachPokemon
  for i in -1...$PokemonStorage.maxBoxes
    for j in 0...$PokemonStorage.maxPokemon(i)
      poke=$PokemonStorage[i][j]
      yield(poke,i) if poke
    end
  end
end

# Yields every Pokémon in storage in turn.
def pbEachNonEggPokemon
  pbEachPokemon{|pokemon,box|
     yield(pokemon,box) if !pokemon.isEgg?
  }
end

# Choose a Pokémon/egg from the party.
# Stores result in variable _variableNumber_ and the chosen Pokémon's name in
# variable _nameVarNumber_; result is -1 if no Pokémon was chosen
def pbChoosePokemon(variableNumber,nameVarNumber,ableProc=nil, allowIneligible=false)
  chosen=0
  pbFadeOutIn(99999){
     scene=PokemonScreen_Scene.new
     screen=PokemonScreen.new(scene,$Trainer.party)
     if ableProc
       chosen=screen.pbChooseAblePokemon(ableProc,allowIneligible)
     else
       screen.pbStartScene(_INTL("Elige un Pokémon."),false)
       chosen=screen.pbChoosePokemon
       screen.pbEndScene
     end
  }
  pbSet(variableNumber,chosen)
  if chosen>=0
    pbSet(nameVarNumber,$Trainer.party[chosen].name)
  else
    pbSet(nameVarNumber,"")
  end
end

def pbChooseNonEggPokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc {|poke|
     !poke.isEgg?
  })
end

def pbChooseAblePokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc {|poke|
     !poke.isEgg? && poke.hp>0
  })
end

def pbChoosePokemonForTrade(variableNumber,nameVarNumber,wanted)
  pbChoosePokemon(variableNumber,nameVarNumber,proc {|poke|
     if wanted.is_a?(String) || wanted.is_a?(Symbol)
       wanted=getID(PBSpecies,wanted)
     end
     return !poke.isEgg? && !(poke.isShadow? rescue false) && poke.species==wanted
  })
end

################################################################################
# Checks through the party for something
################################################################################
# BES-T Esto ahora tambien te permite comprobar la forma.
def pbHasSpecies?(species, form=nil)
  if species.is_a?(String) || species.is_a?(Symbol)
    species=getID(PBSpecies,species)
  end
  for pokemon in $Trainer.party
    next if pokemon.isEgg?

    if form == nil
      return true if pokemon.species==species
    else
      return true if pokemon.species==species && pokemon.form==form
    end
  end
  return false
end

def pbHasFatefulSpecies?(species)
  if species.is_a?(String) || species.is_a?(Symbol)
    species=getID(PBSpecies,species)
  end
  for pokemon in $Trainer.party
    next if pokemon.isEgg?
    return true if pokemon.species==species && pokemon.obtainMode==4
  end
  return false
end

def pbHasType?(type)
  if type.is_a?(String) || type.is_a?(Symbol)
    type=getID(PBTypes,type)
  end
  for pokemon in $Trainer.party
    next if pokemon.isEgg?
    return true if pokemon.hasType?(type)
  end
  return false
end

# Checks whether any Pokémon in the party knows the given move, and returns
# the index of that Pokémon, or nil if no Pokémon has that move.
def pbCheckMove(move)
  move=getID(PBMoves,move)
  return nil if !move || move<=0
  for i in $Trainer.party
    next if i.isEgg?
    for j in i.moves
      return i if j.id==move
    end
  end
  return nil
end

# Deletes the given move from the given Pokémon.
# DEPRECATED - Use pokemon.pbDeleteMove(move) instead
def pbDeleteMoveByID(pokemon,id)
  return if !id || id==0 || !pokemon
  newmoves=[]
  for i in 0...4
    newmoves.push(pokemon.moves[i]) if pokemon.moves[i].id!=id
  end
  newmoves.push(PBMove.new(0))
  for i in 0...4
    pokemon.moves[i]=newmoves[i]
  end
end

# Deletes the given move from the given Pokémon.
# DEPRECATED - Use pokemon.pbDeleteMove(move) instead
def pbDeleteMoveByID(pokemon,id)
  return if !id || id==0 || !pokemon
  newmoves=[]
  for i in 0...4
    newmoves.push(pokemon.moves[i]) if pokemon.moves[i].id!=id
  end
  newmoves.push(PBMove.new(0))
  for i in 0...4
    pokemon.moves[i]=newmoves[i]
  end
end

################################################################################
# Regional and National Pokédexes
################################################################################
# Gets the Regional Pokédex number of the national species for the specified
# Regional Dex.  The parameter "region" is zero-based.  For example, if two
# regions are defined, they would each be specified as 0 and 1.
def pbGetRegionalNumber(region, nationalSpecies)
  if nationalSpecies<=0 || nationalSpecies>PBSpecies.maxValue
    # Return 0 if national species is outside range
    return 0
  end
  pbRgssOpen("Data/regionals.dat","rb"){|f|
     numRegions=f.fgetw
     numDexDatas=f.fgetw
     if region>=0 && region<numRegions
       f.pos=4+region*numDexDatas*2
       f.pos+=nationalSpecies*2
       return f.fgetw
    end
  }
  return 0
end

# Gets the National Pokédex number of the specified species and region.  The
# parameter "region" is zero-based.  For example, if two regions are defined,
# they would each be specified as 0 and 1.
def pbGetNationalNumber(region, regionalSpecies)
  pbRgssOpen("Data/regionals.dat","rb"){|f|
     numRegions=f.fgetw
     numDexDatas=f.fgetw
     if region>=0 && region<numRegions
       f.pos=4+region*numDexDatas*2
       # "i" specifies the national species
       for i in 0...numDexDatas
         regionalNum=f.fgetw
         return i if regionalNum==regionalSpecies
       end
     end
  }
  return 0
end

# Gets an array of all national species within the given Regional Dex, sorted by
# Regional Dex number.  The number of items in the array should be the
# number of species in the Regional Dex plus 1, since index 0 is considered
# to be empty.  The parameter "region" is zero-based.  For example, if two
# regions are defined, they would each be specified as 0 and 1.
def pbAllRegionalSpecies(region)
  ret=[0]
  pbRgssOpen("Data/regionals.dat","rb"){|f|
     numRegions=f.fgetw
     numDexDatas=f.fgetw
     if region>=0 && region<numRegions
       f.pos=4+region*numDexDatas*2
       # "i" specifies the national species
       for i in 0...numDexDatas
         regionalNum=f.fgetw
         ret[regionalNum]=i if regionalNum!=0
       end
       # Replace unspecified regional
       # numbers with zeros
       for i in 0...ret.length
         ret[i]=0 if !ret[i]
       end
     end
  }
  return ret
end

# Gets the ID number for the current region based on the player's current
# position.  Returns the value of "defaultRegion" (optional, default is -1) if
# no region was defined in the game's metadata.  The ID numbers returned by
# this function depend on the current map's position metadata.
def pbGetCurrentRegion(defaultRegion=-1)
  mappos=!$game_map ? nil : pbGetMetadata($game_map.map_id,MetadataMapPosition)
  if !mappos
    return defaultRegion # No region defined
  else
    return mappos[0]
  end
end

# Decides which Dex lists are able to be viewed (i.e. they are unlocked and have
# at least 1 seen species in them), and saves all viable dex region numbers
# (National Dex comes after regional dexes).
# If the Dex list shown depends on the player's location, this just decides if
# a species in the current region has been seen - doesn't look at other regions.
# Here, just used to decide whether to show the Pokédex in the Pause menu.
def pbSetViableDexes
  $PokemonGlobal.pokedexViable=[]
  if DEXDEPENDSONLOCATION
    region=pbGetCurrentRegion
    region=-1 if region>=$PokemonGlobal.pokedexUnlocked.length-1
    if $Trainer.pokedexSeen(region)>0
      $PokemonGlobal.pokedexViable[0]=region
    end
  else
    numDexes=$PokemonGlobal.pokedexUnlocked.length
    case numDexes
    when 1          # National Dex only
      if $PokemonGlobal.pokedexUnlocked[0]
        if $Trainer.pokedexSeen>0
          $PokemonGlobal.pokedexViable.push(0)
        end
      end
    else            # Regional dexes + National Dex
      for i in 0...numDexes
        regionToCheck=(i==numDexes-1) ? -1 : i
        if $PokemonGlobal.pokedexUnlocked[i]
          if $Trainer.pokedexSeen(regionToCheck)>0
            $PokemonGlobal.pokedexViable.push(i)
          end
        end
      end
    end
  end
end

# Unlocks a Dex list.  The National Dex is -1 here (or nil argument).
def pbUnlockDex(dex=-1)
  index=dex
  index=$PokemonGlobal.pokedexUnlocked.length-1 if index<0
  index=$PokemonGlobal.pokedexUnlocked.length-1 if index>$PokemonGlobal.pokedexUnlocked.length-1
  $PokemonGlobal.pokedexUnlocked[index]=true
end

# Locks a Dex list.  The National Dex is -1 here (or nil argument).
def pbLockDex(dex=-1)
  index=dex
  index=$PokemonGlobal.pokedexUnlocked.length-1 if index<0
  index=$PokemonGlobal.pokedexUnlocked.length-1 if index>$PokemonGlobal.pokedexUnlocked.length-1
  $PokemonGlobal.pokedexUnlocked[index]=false
end



################################################################################
# Other utilities
################################################################################
def pbTextEntry(helptext,minlength,maxlength,variableNumber)
  $game_variables[variableNumber]=pbEnterText(helptext,minlength,maxlength)
  $game_map.need_refresh = true if $game_map
end

def pbMoveTutorAnnotations(move,movelist=nil)
  ret=[]
  for i in 0...6
    ret[i]=nil
    next if i>=$Trainer.party.length
    found=false
    for j in 0...4
      if !$Trainer.party[i].isEgg? && $Trainer.party[i].moves[j].id==move
        ret[i]=_INTL("APRENDIDO")
        found=true
      end
    end
    next if found
    species=$Trainer.party[i].species
    if !$Trainer.party[i].isEgg? && movelist && movelist.any?{|j| j==species }
      # Checked data from movelist
      ret[i]=_INTL("PUEDE")
    elsif !$Trainer.party[i].isEgg? && $Trainer.party[i].isCompatibleWithMove?(move)
      # Checked data from PBS/tm.txt
      ret[i]=_INTL("PUEDE")
    else
      ret[i]=_INTL("NO PUEDE")
    end
  end
  return ret
end

def pbMoveTutorChoose(move,movelist=nil,bymachine=false)
  ret=false
  if move.is_a?(String) || move.is_a?(Symbol)
    move=getID(PBMoves,move)
  end
  if movelist!=nil && movelist.is_a?(Array)
    for i in 0...movelist.length
      if movelist[i].is_a?(String) || movelist[i].is_a?(Symbol)
        movelist[i]=getID(PBSpecies,movelist[i])
      end
    end
  end
  pbFadeOutIn(99999){
     scene=PokemonScreen_Scene.new
     movename=PBMoves.getName(move)
     screen=PokemonScreen.new(scene,$Trainer.party)
     annot=pbMoveTutorAnnotations(move,movelist)
     screen.pbStartScene(_INTL("¿A qué Pokémon enseñarle?"),false,annot)
     loop do
       chosen=screen.pbChoosePokemon
       if chosen>=0
         pokemon=$Trainer.party[chosen]
         if pokemon.isEgg?
           Kernel.pbMessage(_INTL("{1} no puede ser aprendido por un Huevo.",movename))
         elsif (pokemon.isShadow? rescue false)
           Kernel.pbMessage(_INTL("No se puede enseñar ningún movimiento a un Pokémon Oscuro."))
         elsif movelist && !movelist.any?{|j| j==pokemon.species }
           Kernel.pbMessage(_INTL("{1} no es compatible con {2}.",pokemon.name,movename))
           Kernel.pbMessage(_INTL("{1} no puede ser aprendido.",movename))
         elsif !pokemon.isCompatibleWithMove?(move)
           Kernel.pbMessage(_INTL("{1} no es compatible con {2}.",pokemon.name,movename))
           Kernel.pbMessage(_INTL("{1} no puede ser aprendido.",movename))
         else
           if pbLearnMove(pokemon,move,false,bymachine)
             ret=true
             break
           end
         end
       else
         break
       end
     end
     screen.pbEndScene
  }
  return ret # Returns whether the move was learned by a Pokemon
end

def pbChooseMove(pokemon,variableNumber,nameVarNumber)
  return if !pokemon
  ret=-1
  pbFadeOutIn(99999){
     scene=PokemonSummaryScene.new
     screen=PokemonSummary.new(scene)
     ret=screen.pbStartForgetScreen([pokemon],0,0)
  }
  $game_variables[variableNumber]=ret
  if ret>=0
    $game_variables[nameVarNumber]=PBMoves.getName(pokemon.moves[ret].id)
  else
    $game_variables[nameVarNumber]=""
  end
  $game_map.need_refresh = true if $game_map
end

# Opens the Pokémon screen
def pbPokemonScreen
  return if !$Trainer
  sscene=PokemonScreen_Scene.new
  sscreen=PokemonScreen.new(sscene,$Trainer.party)
  pbFadeOutIn(99999) { sscreen.pbPokemonScreen }
end

def pbSaveScreen
  ret=false
  scene=PokemonSaveScene.new
  screen=PokemonSave.new(scene)
  ret=screen.pbSaveScreen
  return ret
end

def pbConvertItemToItem(variable,array)
  item=pbGet(variable)
  pbSet(variable,0)
  for i in 0...(array.length/2)
    if isConst?(item,PBItems,array[2*i])
      pbSet(variable,getID(PBItems,array[2*i+1]))
      return
    end
  end
end

def pbConvertItemToPokemon(variable,array)
  item=pbGet(variable)
  pbSet(variable,0)
  for i in 0...(array.length/2)
    if isConst?(item,PBItems,array[2*i])
      pbSet(variable,getID(PBSpecies,array[2*i+1]))
      return
    end
  end
end

class PokemonGlobalMetadata
  attr_accessor :trainerRecording
end

def pbRecordTrainer
  wave=pbRecord(nil,10)
  if wave
    $PokemonGlobal.trainerRecording=wave
    return true
  end
  return false
end

#BES-T, permite entregar una cinta a todos los pokémon actualmente en el equipo.
def giveRibbonToAll(ribbon)
  for i in 0...$Trainer.party.length
    poke=$Trainer.party[i]
    poke.giveRibbon(ribbon)
  end
rescue
  p "Entrega de cinta fallida, revisa que el nombre interno corresponde con uno existente." if $DEBUG
end