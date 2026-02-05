TPSPECIES   = 0
TPLEVEL     = 1
TPITEM      = 2
TPMOVE1     = 3
TPMOVE2     = 4
TPMOVE3     = 5
TPMOVE4     = 6
TPABILITY   = 7
TPGENDER    = 8
TPFORM      = 9
TPSHINY     = 10
TPNATURE    = 11
TPIV        = 12
TPHAPPINESS = 13
TPNAME      = 14
TPSHADOW    = 15
TPBALL      = 16
TPTERA      = 17
TPMAX       = 18
TPDEFAULTS = [0,10,0,0,0,0,0,nil,nil,0,false,nil,10,70,nil,false,0,nil,false]

def pbLoadTrainer(trainerid,trainername,partyid=0)
  if trainerid.is_a?(String) || trainerid.is_a?(Symbol)
    if !hasConst?(PBTrainers,trainerid)
      raise _INTL("El tipo de entrenador no existe ({1}, {2}, ID {3})",trainerid,trainername,partyid)
    end
    trainerid=getID(PBTrainers,trainerid)
  end
  success=false
  items=[]
  party=[]
  opponent=nil
  trainers=load_data("Data/trainers.dat")
  for trainer in trainers
    name=trainer[1]
    thistrainerid=trainer[0]
    thispartyid=trainer[4]
    next if trainerid!=thistrainerid || name!=trainername || partyid!=thispartyid
    items=trainer[2].clone
    name=pbGetMessageFromHash(MessageTypes::TrainerNames,name)
    for i in RIVALNAMES
      if isConst?(trainerid,PBTrainers,i[0]) && $game_variables[i[1]]!=0
        name=$game_variables[i[1]]
      end
    end
    opponent=PokeBattle_Trainer.new(name,thistrainerid)
    opponent.setForeignID($Trainer) if $Trainer
    for poke in trainer[3]
      species=poke[TPSPECIES]
      level=poke[TPLEVEL]
      pokemon=PokeBattle_Pokemon.new(species,level,opponent)
      pokemon.formNoCall=poke[TPFORM]
      pokemon.resetMoves
      pokemon.setItem(poke[TPITEM])
      if poke[TPMOVE1]>0 || poke[TPMOVE2]>0 || poke[TPMOVE3]>0 || poke[TPMOVE4]>0
        k=0
        for move in [TPMOVE1,TPMOVE2,TPMOVE3,TPMOVE4]
          pokemon.moves[k]=PBMove.new(poke[move])
          k+=1
        end
        pokemon.moves.compact!
      end
      pokemon.setAbility(poke[TPABILITY])
      pokemon.setGender(poke[TPGENDER])
      if poke[TPSHINY]                 # si éste es un Pokémon shiny
        pokemon.makeShiny
      else
        pokemon.makeNotShiny
      end
      pokemon.setNature(poke[TPNATURE])
      iv=poke[TPIV]
      for i in 0...6
        pokemon.iv[i]=iv&0x1F
        pokemon.ev[i]=[85,level*3/2].min
      end
      pokemon.happiness=poke[TPHAPPINESS]
      pokemon.name=poke[TPNAME] if poke[TPNAME] && poke[TPNAME]!=""
      if poke[TPSHADOW]                # si éste es un Pokémon Oscuro
        pokemon.makeShadow rescue nil
        pokemon.pbUpdateShadowMoves(true) rescue nil
        pokemon.makeNotShiny
      end
      if poke[TPTERA]                # si éste es un Pokémon Oscuro
        pokemon.teratype=poke[TPTERA]
        pokemon.tera_ace=true
      end
      pokemon.max_ace=poke[TPMAX]
      pokemon.gmaxfactor=poke[TPMAX] if pokemon.hasGigantamaxForm?
      pokemon.ballused=poke[TPBALL]
      pokemon.calcStats
      party.push(pokemon)
    end
    success=true
    break
  end
  return success ? [opponent,items,party] : nil
end

def pbConvertTrainerData
  data=load_data("Data/trainertypes.dat")
  trainertypes=[]
  for i in 0...data.length
    record=data[i]
    if record
      trainertypes[record[0]]=record[2]
    end
  end
  MessageTypes.setMessages(MessageTypes::TrainerTypes,trainertypes)
  pbSaveTrainerTypes()
  pbSaveTrainerBattles()
end

def pbNewTrainer(trainerid,trainername,trainerparty)
  pokemon=[]
  level=TPDEFAULTS[TPLEVEL]
  for i in 1..6
    if i==1
      Kernel.pbMessage(_INTL("Ingrese el primer Pokémon.",i))
    else
      break if !Kernel.pbConfirmMessage(_INTL("¿Agregar otro Pokémon?"))
    end
    loop do
      species=pbChooseSpeciesOrdered(1)
      if species<=0
        if i==1
          Kernel.pbMessage(_INTL("¡Este entrenador debe tener al menos 1 Pokémon!"))
        else
          break
        end
      else
        params=ChooseNumberParams.new
        params.setRange(1,PBExperience::MAXLEVEL)
        params.setDefaultValue(level)
        level=Kernel.pbMessageChooseNumber(_INTL("Establecer el nivel de {1}.",
           PBSpecies.getName(species)),params)
        tempPoke=PokeBattle_Pokemon.new(species,level)
        pokemon.push([species,level,0,
           tempPoke.moves[0].id,
           tempPoke.moves[1].id,
           tempPoke.moves[2].id,
           tempPoke.moves[3].id
        ])
        break
      end
    end
  end
  trainer=[trainerid,trainername,[],pokemon,trainerparty]
  data=load_data("Data/trainers.dat")
  data.push(trainer)
  data=save_data(data,"Data/trainers.dat")
  pbConvertTrainerData
  Kernel.pbMessage(_INTL("Los datos del entrenador han sido agregados a la lista de combates y en PBS/trainers.txt."))
  return trainer
end

def pbTrainerTypeCheck(symbol)
  ret=true
  if $DEBUG
    if !hasConst?(PBTrainers,symbol)
      ret=false
    else
      trtype=PBTrainers.const_get(symbol)
      data=load_data("Data/trainertypes.dat")
      ret=false if !data || !data[trtype]
    end
    if !ret
      if Kernel.pbConfirmMessage(_INTL("¿Agregar tipo de entrenador nuevo {1}?",symbol))
        pbTrainerTypeEditorNew(symbol.to_s)
      end
      pbMapInterpreter.command_end if pbMapInterpreter
    end
  end
  return ret
end

def pbGetFreeTrainerParty(trainerid,trainername)
  for i in 0...256
    trainer=pbLoadTrainer(trainerid,trainername,i)
    return i if !trainer
  end
  return -1
end

def pbTrainerCheck(trainerid,trainername,maxbattles,startBattleId=0)
  if $DEBUG
    if trainerid.is_a?(String) || trainerid.is_a?(Symbol)
      pbTrainerTypeCheck(trainerid)
      return false if !hasConst?(PBTrainers,trainerid)
      trainerid=PBTrainers.const_get(trainerid)
    end
    for i in 0...maxbattles
      trainer=pbLoadTrainer(trainerid,trainername,i+startBattleId)
      if !trainer
        traineridstring="#{trainerid}"
        traineridstring=getConstantName(PBTrainers,trainerid) rescue "-"
        if Kernel.pbConfirmMessage(_INTL("¿Agregar combate nuevo {1} (de {2}) para ({3}, {4})?",
          i+1,maxbattles,traineridstring,trainername))
          pbNewTrainer(trainerid,trainername,i)
        end
      end
    end
  end
  return true
end

def pbMissingTrainer(trainerid, trainername, trainerparty)
  if trainerid.is_a?(String) || trainerid.is_a?(Symbol)
    if !hasConst?(PBTrainers,trainerid)
      raise _INTL("El tipo de entrenador no existe ({1}, {2}, ID {3})",trainerid,trainername,partyid)
    end
    trainerid=getID(PBTrainers,trainerid)
  end
  traineridstring="#{trainerid}"
  traineridstring=getConstantName(PBTrainers,trainerid) rescue "-"
  if $DEBUG
      message=""
    if trainerparty!=0
      message=(_INTL("¿Agregar entrenador nuevo ({1}, {2}, ID {3})?",traineridstring,trainername,trainerparty))
    else
      message=(_INTL("¿Agregar entrenador nuevo ({1}, {2})?",traineridstring,trainername))
    end
    cmd=Kernel.pbMessage(message,[_INTL("Sí"),_INTL("No")],2)
    if cmd==0
      pbNewTrainer(trainerid,trainername,trainerparty)
    end
    return cmd
  else
    raise _INTL("No se encontró entrenador ({1}, {2}, ID {3})",traineridstring,trainername,trainerparty)
  end
end

class TrainerWalkingCharSprite < SpriteWrapper
  def initialize(charset,viewport=nil)
    super(viewport)
    @animbitmap=nil
    self.charset=charset
    @animframe=0   # Cuadro/frame actual
    @frame=0       # Contador
    @frameskip=6   # Velocidad de la animación
  end

  def charset=(value)
    @animbitmap.dispose if @animbitmap
    @animbitmap=nil
    bitmapFileName=sprintf("Graphics/Characters/%s",value)
    @charset=pbResolveBitmap(bitmapFileName)
    if @charset
      @animbitmap=AnimatedBitmap.new(@charset)
      self.bitmap=@animbitmap.bitmap
      self.src_rect.set(0,0,self.bitmap.width/4,self.bitmap.height/4)
    else
      self.bitmap=nil
    end
  end

  def altcharset=(value)     # Usado para el ícono de la pantalla de nombrado
    @animbitmap.dispose if @animbitmap
    @animbitmap=nil
    @charset=pbResolveBitmap(value)
    if @charset
      @animbitmap=AnimatedBitmap.new(@charset)
      self.bitmap=@animbitmap.bitmap
      self.src_rect.set(0,0,self.bitmap.width/4,self.bitmap.height)
    else
      self.bitmap=nil
    end
  end

  def animspeed=(value)
    @frameskip=value
  end

  def dispose
    @animbitmap.dispose if @animbitmap
    super
  end

  def update
    @updating=true
    super
    if @animbitmap
      @animbitmap.update
      self.bitmap=@animbitmap.bitmap
    end
    @frame+=1
    @frame=0 if @frame>100
    if @frame>=@frameskip
      @animframe=(@animframe+1)%4
      self.src_rect.x=@animframe*@animbitmap.bitmap.width/4
      @frame=0
    end
    @updating=false
  end
end
