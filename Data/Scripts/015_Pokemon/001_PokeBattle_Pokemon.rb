################################################################################
# Esta clase contiene todos los datos de cada Pokémon. El arreglo $Trainer.party
# contiene cada uno de los Pokémon del equipo actual del entrenador.
################################################################################
class PokeBattle_Pokemon
  attr_reader(:totalhp)       # PS totales actuales
  attr_reader(:attack)        # Ataque actual
  attr_reader(:defense)       # Defensa actual
  attr_reader(:speed)         # Velocidad actual
  attr_reader(:spatk)         # Ataque Especial actual
  attr_reader(:spdef)         # Defensa Especial actual
  attr_accessor(:iv)          # Arreglo de 6 IVs (Valores individuales)
                              #    correspondientes a cada característica
  attr_accessor(:ev)          # EVs (Valores de esfuerzo)
  attr_accessor(:species)     # Especie (número en la Pokédex National)
  attr_accessor(:personalID)  # ID Personal
  attr_accessor(:trainerID)   # ID del Entrenador en 32-bit (el ID secreto está
                              #    en los 16 bits superiores)
  attr_accessor(:hp)          # PS actuales
  attr_accessor(:pokerus)     # Gravedad del Pokérus y tiempo de infección
  attr_accessor(:item)        # Objeto Llevado
  attr_accessor(:itemRecycle) # Objeto llevado consumido (solo usado en combate)
  attr_accessor(:itemInitial) # Resulting held item (solo usado en combate)
  attr_accessor(:belch)       # Si el Pokémon puede usar Eructo (solo usado en combate)
  attr_accessor(:mail)        # Carta
  attr_accessor(:fused)       # El Pokémon fusionado con éste
  attr_accessor(:name)        # Apodo
  attr_accessor(:exp)         # Puntos de experiencia actuales
  attr_accessor(:happiness)   # Felicidad actual
  attr_accessor(:status)      # Cambio de estado (PBStatuses)
  attr_accessor(:statusCount) # Contador de sueño/bandera de tóxico
  attr_accessor(:eggsteps)    # Pasos para eclosionar el huevo, 0 si el Pokémon no es un huevo
  attr_accessor(:moves)       # Movimientos (PBMove)
  attr_accessor(:firstmoves)  # Los movimientos conocidos al momento de capturarlo
  attr_accessor(:ballused)    # Ball usada
  attr_accessor(:markings)    # Marcas
  attr_accessor(:obtainMode)  # Método de captura:
                              #    0 - encuentro, 1 - como huevo, 2 - intercambiado,
                              #    4 - encuentro fatídico
  attr_accessor(:obtainMap)   # Mapa donde fue capturado
  attr_accessor(:obtainText)  # Si no estpa en nil, remplaza el nombre del mapa donde se capturó
  attr_accessor(:obtainLevel) # Nivel con el que se obtuvo
  attr_accessor(:hatchedMap)  # Mapa donde eclosionó el huevo
  attr_accessor(:language)    # Idioma
  attr_accessor(:ot)          # Nombre del Entrenador Original
  attr_accessor(:otgender)    # Género del Entrenador Original:
                              #    0 - masculino, 1 - femenino, 2 - mixto, 3 - desconocido
                              #    Sólo es informativo, no se usa para verificar
                              #    el dueño del Pokémon
  attr_accessor(:abilityflag) # Fuerza la habilidad primera/segunda/oculta (0/1/2)
  attr_accessor(:genderflag)  # Fuerza el género macho (0) o hembra (1)
  attr_accessor(:natureflag)  # Fuerza una naturaleza en particular
  attr_accessor(:shinyflag)   # Fuerza el variocolor shininess (true/false)
  attr_accessor(:ribbons)     # Arreglo de cintas
  attr_accessor :teratype     # Teratipo del Pokémon
  attr_accessor :teracristalized # Si es true el Pokémon está teracristalzado
  attr_accessor :tera_ace #Si es true el Pokémon teracristalizará (solo usado en entrenadores)
  attr_accessor :cool,:beauty,:cute,:smart,:tough,:sheen # Contest stats
  attr_accessor :original_types

  EVLIMIT     = 510   # Máximo de EVs totales
  EVSTATLIMIT = 252   # Másixmo de EVs que puede tener una sola característica

################################################################################
# Ownership, obtained information
################################################################################
# Returns the gender of this Pokémon's original trainer (2=unknown).
  def otgender
    @otgender=2 if !@otgender
    return @otgender
  end

# Returns whether the specified Trainer is NOT this Pokemon's original trainer.
  def isForeign?(trainer)
    return @trainerID!=trainer.id || @ot!=trainer.name
  end

# Returns the public portion of the original trainer's ID.
  def publicID
    return @trainerID&0xFFFF
  end

# Returns this Pokémon's level when this Pokémon was obtained.
  def obtainLevel
    @obtainLevel=0 if !@obtainLevel
    return @obtainLevel
  end

# Returns the time when this Pokémon was obtained.
  def timeReceived
    return @timeReceived ? Time.at(@timeReceived) : Time.gm(2000)
  end

# Sets the time when this Pokémon was obtained.
  def timeReceived=(value)
    # Seconds since Unix epoch
    if value.is_a?(Time)
      @timeReceived=value.to_i
    else
      @timeReceived=value
    end
  end

# Returns the time when this Pokémon hatched.
  def timeEggHatched
    if obtainMode==1
      return @timeEggHatched ? Time.at(@timeEggHatched) : Time.gm(2000)
    else
      return Time.gm(2000)
    end
  end

# Sets the time when this Pokémon hatched.
  def timeEggHatched=(value)
    # Seconds since Unix epoch
    if value.is_a?(Time)
      @timeEggHatched=value.to_i
    else
      @timeEggHatched=value
    end
  end

################################################################################
# Level
################################################################################
# Returns this Pokemon's level.
  def level
    return PBExperience.pbGetLevelFromExperience(@exp,self.growthrate)
  end

# Sets this Pokemon's level by changing its Exp. Points.
  def level=(value)
    if value<1 || value>PBExperience::MAXLEVEL
      raise ArgumentError.new(_INTL("El número de nivel ({1}) no es válido.",value))
    end
    self.exp=PBExperience.pbGetStartExperience(value,self.growthrate)
  end

# Returns whether this Pokemon is an egg.
  def isEgg?
    return @eggsteps>0
  end

  def egg?; return isEgg?; end

# Returns this Pokemon's growth rate.
  def growthrate
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,20)
    ret=dexdata.fgetb
    dexdata.close
    return ret
  end

# Returns this Pokemon's base Experience value.
  def baseExp
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,38)
    ret=dexdata.fgetw
    dexdata.close
    return ret
  end

################################################################################
# Gender
################################################################################
# Returns this Pokemon's gender. 0=male, 1=female, 2=genderless
  def gender
    return @genderflag if @genderflag!=nil
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,18)
    genderbyte=dexdata.fgetb
    dexdata.close
    case genderbyte
    when 255
      return 2 # genderless
    when 254
      return 1 # always female
    else
      lowbyte=@personalID&0xFF
      return PokeBattle_Pokemon.isFemale(lowbyte,genderbyte) ? 1 : 0
    end
  end

# Helper function that determines whether the input values would make a female.
  def self.isFemale(b,genderRate)
    return true if genderRate==254    # AlwaysFemale
    return false if genderRate==255   # Genderless
    return b<=genderRate
  end

# Returns whether this Pokémon species is restricted to only ever being one
# gender (or genderless).
  def isSingleGendered?
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,18)
    genderbyte=dexdata.fgetb
    dexdata.close
    return genderbyte==255 || genderbyte==254 || genderbyte==0
  end

# Returns whether this Pokémon is male.
  def isMale?
    return self.gender==0
  end

# Returns whether this Pokémon is female.
  def isFemale?
    return self.gender==1
  end

# Returns whether this Pokémon is genderless.
  def isGenderless?
    return self.gender==2
  end

# Sets this Pokémon's gender to a particular gender (if possible).
  def setGender(value)
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,18)
    genderbyte=dexdata.fgetb
    dexdata.close
    if genderbyte!=255 && genderbyte!=0 && genderbyte!=254
      @genderflag=value
    end
  end

  def makeMale; setGender(0); end
  def makeFemale; setGender(1); end

################################################################################
# Ability
################################################################################
# Returns the index of this Pokémon's ability.
  def abilityIndex
    abil=@abilityflag!=nil ? @abilityflag : (@personalID&1)
    return abil
  end

# Returns the ID of this Pokemon's ability.
  def ability
    abil=abilityIndex
    abils=getAbilityList
    ret1=0; ret2=0
    for i in 0...abils.length
      next if !abils[i][0] || abils[i][0]<=0
      return abils[i][0] if abils[i][1]==abil
      ret1=abils[i][0] if abils[i][1]==0
      ret2=abils[i][0] if abils[i][1]==1
    end
    abil=(@personalID&1) if abil>=2
    return ret2 if abil==1 && ret2>0
    return ret1
  end

# Returns whether this Pokémon has a particular ability.
  def hasAbility?(value=0)
    if value==0
      return self.ability>0
    else
      if value.is_a?(String) || value.is_a?(Symbol)
        value=getID(PBAbilities,value)
      end
      return self.ability==value
    end
    return false
  end

# Sets this Pokémon's ability to a particular ability (if possible).
  def setAbility(value)
    @abilityflag=value
  end

  def hasHiddenAbility?
    abil=abilityIndex
    return abil!=nil && abil>=2
  end

  def hasEventAbility?
    abil=abilityIndex
    return abil!=nil && abil>=3
  end

# Returns the list of abilities this Pokémon can have.
  def getAbilityList
    abils=[]; ret=[]
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,2)
    abils.push(dexdata.fgetw)
    abils.push(dexdata.fgetw)
    pbDexDataOffset(dexdata,@species,40)
    abils.push(dexdata.fgetw)
    abils.push(dexdata.fgetw)
    abils.push(dexdata.fgetw)
    abils.push(dexdata.fgetw)
    dexdata.close
    for i in 0...abils.length
      next if !abils[i] || abils[i]<=0
      ret.push([abils[i],i])
    end
    return ret
  end

################################################################################
# Nature
################################################################################
# Returns the ID of this Pokémon's nature.
  def nature
    return @natureflag if @natureflag!=nil
    return @personalID%25
  end

# Returns whether this Pokémon has a particular nature.
  def hasNature?(value=-1)
    if value<0
      return self.nature>=0
    else
      if value.is_a?(String) || value.is_a?(Symbol)
        value=getID(PBNatures,value)
      end
      return self.nature==value
    end
    return false
  end

# Sets this Pokémon's nature to a particular nature.
  def setNature(value)
    if value.is_a?(String) || value.is_a?(Symbol)
      value=getID(PBNatures,value)
    end
    @natureflag=value
    self.calcStats
  end

################################################################################
# Shininess
################################################################################
# Returns whether this Pokemon is shiny (differently colored).
  def isShiny?
    return @shinyflag if @shinyflag!=nil
    a=@personalID^@trainerID
    b=a&0xFFFF
    c=(a>>16)&0xFFFF
    d=b^c
    return (d<SHINYPOKEMONCHANCE)
  end

# Makes this Pokemon shiny.
  def makeShiny
    @shinyflag=true
  end

# Makes this Pokemon not shiny.
  def makeNotShiny
    @shinyflag=false
  end

################################################################################
# Pokérus
################################################################################
# Gives this Pokemon Pokérus (either the specified strain or a random one).
  def givePokerus(strain=0)
    return if self.pokerusStage==2 # Can't re-infect a cured Pokémon
    if strain<=0 || strain>=16
      strain=1+rand(15)
    end
    time=1+(strain%4)
    @pokerus=time
    @pokerus|=strain<<4
  end

# Resets the infection time for this Pokemon's Pokérus (even if cured).
  def resetPokerusTime
    return if @pokerus==0
    strain=@pokerus%16
    time=1+(strain%4)
    @pokerus=time
    @pokerus|=strain<<4
  end

# Reduces the time remaining for this Pokemon's Pokérus (if infected).
  def lowerPokerusCount
    return if self.pokerusStage!=1
    @pokerus-=1
  end

# Returns the Pokérus infection stage for this Pokemon.
  def pokerusStage
    return 0 if !@pokerus || @pokerus==0        # Not infected
    return 2 if @pokerus>0 && (@pokerus%16)==0  # Cured
    return 1                                    # Infected
  end

################################################################################
# Types
################################################################################
# Returns whether this Pokémon has the specified type.
  def hasType?(type)
    if type.is_a?(String) || type.is_a?(Symbol)
      return isConst?(self.type1,PBTypes,type) || isConst?(self.type2,PBTypes,type)
    else
      return self.type1==type || self.type2==type
    end
  end

# Returns this Pokémon's first type.
  def type1
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,8)
    ret=dexdata.fgetb
    dexdata.close
    return ret
  end

# Returns this Pokémon's second type.
  def type2
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,9)
    ret=dexdata.fgetb
    dexdata.close
    return ret
  end

################################################################################
# Movimientos
################################################################################
# Devuelve la cantidad de movimientos conocidos por el Pokémon.
  def numMoves
    ret=0
    for i in 0...4
      ret+=1 if @moves[i].id!=0
    end
    return ret
  end

# Devuelve true si el Pokémon conoce el movimiento dado.
  def hasMove?(move)
    if move.is_a?(String) || move.is_a?(Symbol)
      move=getID(PBMoves,move)
    end
    return false if !move || move<=0
    for i in 0...4
      return true if @moves[i].id==move
    end
    return false
  end

  def knowsMove?(move); return self.hasMove?(move); end

  def getMoveList
    movelist=[]
    atkdata=pbRgssOpen("Data/attacksRS.dat","rb")
    offset=atkdata.getOffset(@species-1)
    length=atkdata.getLength(@species-1)>>1
    atkdata.pos=offset
    for k in 0..length-1
      level=atkdata.fgetw
      move=atkdata.fgetw
      movelist.push([level,move])
    end
    atkdata.close
    return movelist
  end

# Establece los movimientos conocidos de este Pokémon con los movimientos que tenía originalmente.
  def resetMoves
    moves=self.getMoveList
    movelist=[]
    for i in moves
      if i[0]<=self.level
        movelist[movelist.length]=i[1]
      end
    end
    movelist|=[] # Quita duplicados
    listend=movelist.length-4
    listend=0 if listend<0
    j=0
    for i in listend...listend+4
      moveid=(i>=movelist.length) ? 0 : movelist[i]
      @moves[j]=PBMove.new(moveid)
      j+=1
    end
  end

# Aprende silenciosamente el movimiento indicado. Se borrará el primer movimiento en caso de ser necesario.
  def pbLearnMove(move)
    if move.is_a?(String) || move.is_a?(Symbol)
      move=getID(PBMoves,move)
    end
    return if move<=0
    for i in 0...4
      if @moves[i].id==move
        j=i+1; while j<4
          break if @moves[j].id==0
          tmp=@moves[j]
          @moves[j]=@moves[j-1]
          @moves[j-1]=tmp
          j+=1
        end
        return
      end
    end
    for i in 0...4
      if @moves[i].id==0
        @moves[i]=PBMove.new(move)
        return
      end
    end
    @moves[0]=@moves[1]
    @moves[1]=@moves[2]
    @moves[2]=@moves[3]
    @moves[3]=PBMove.new(move)
  end

# Quita el movimiento dado de este Pokémon.
  def pbDeleteMove(move)
    if move.is_a?(String) || move.is_a?(Symbol)
      move=getID(PBMoves,move)
    end
    return if !move || move<=0
    newmoves=[]
    for i in 0...4
      newmoves.push(@moves[i]) if @moves[i].id!=move
    end
    newmoves.push(PBMove.new(0))
    for i in 0...4
      @moves[i]=newmoves[i]
    end
  end

# Deletes the move at the given index from the Pokémon.
  def pbDeleteMoveAtIndex(index)
    newmoves=[]
    for i in 0...4
      newmoves.push(@moves[i]) if i!=index
    end
    newmoves.push(PBMove.new(0))
    for i in 0...4
      @moves[i]=newmoves[i]
    end
  end

# Deletes all moves from the Pokémon.
  def pbDeleteAllMoves
    for i in 0...4
      @moves[i]=PBMove.new(0)
    end
  end

# Copies currently known moves into a separate array, for Move Relearner.
  def pbRecordFirstMoves
    @firstmoves=[]
    for i in 0...4
      @firstmoves.push(@moves[i].id) if @moves[i].id>0
    end
  end

  def isCompatibleWithMove?(move)
    return pbSpeciesCompatible?(self.species,move)
  end

################################################################################
# Atributos y cintas de concurso
################################################################################
  def cool; @cool ? @cool : 0; end
  def beauty; @beauty ? @beauty : 0; end
  def cute; @cute ? @cute : 0; end
  def smart; @smart ? @smart : 0; end
  def tough; @tough ? @tough : 0; end
  def sheen; @sheen ? @sheen : 0; end

# Devuelve el número de cintas que tiene este Pokemon.
  def ribbonCount
    @ribbons=[] if !@ribbons
    return @ribbons.length
  end

# Devuelve si este Pokémon tiene la cinta especificada.
  def hasRibbon?(ribbon)
    @ribbons=[] if !@ribbons
    ribbon=getID(PBRibbons,ribbon) if !ribbon.is_a?(Integer)
    return false if ribbon==0
    return @ribbons.include?(ribbon)
  end

# Entrega a este Pokémon la cinta especificada.
  def giveRibbon(ribbon)
    @ribbons=[] if !@ribbons
    ribbon=getID(PBRibbons,ribbon) if !ribbon.is_a?(Integer)
    return if ribbon==0
    @ribbons.push(ribbon) if !@ribbons.include?(ribbon)
  end

# Remplaza una cinta por su siguiente, si es posible.
  def upgradeRibbon(*arg)
    @ribbons=[] if !@ribbons
    for i in 0...arg.length-1
      for j in 0...@ribbons.length
        thisribbon=(arg[i].is_a?(Integer)) ? arg[i] : getID(PBRibbons,arg[i])
        if @ribbons[j]==thisribbon
          nextribbon=(arg[i+1].is_a?(Integer)) ? arg[i+1] : getID(PBRibbons,arg[i+1])
          @ribbons[j]=nextribbon
          return nextribbon
        end
      end
    end
    if !hasRibbon?(arg[arg.length-1])
      firstribbon=(arg[0].is_a?(Integer)) ? arg[0] : getID(PBRibbons,arg[0])
      giveRibbon(firstribbon)
      return firstribbon
    end
    return 0
  end

# Quita las cintas especificadas de este Pokémon.
  def takeRibbon(ribbon)
    return if !@ribbons
    ribbon=getID(PBRibbons,ribbon) if !ribbon.is_a?(Integer)
    return if ribbon==0
    for i in 0...@ribbons.length
      if @ribbons[i]==ribbon
        @ribbons[i]=nil; break
      end
    end
    @ribbons.compact!
  end

# Quita todas las cintas de este Pokémon.
  def clearAllRibbons
    @ribbons=[]
  end

################################################################################
# Teracristalización
################################################################################
  def teratype #Devuelve el teratipo del Pokémon
    if @species==getConst(PBSpecies,:OGERPON)
      return PBTypes::FIRE if @item==getConst(PBItems,:HEARTHFLAMEMASK)
      return PBTypes::WATER if @item==getConst(PBItems,:WELLSPRINGMASK)
      return PBTypes::ROCK if @item==getConst(PBItems,:CORRNERSTONEMASK)
      return PBTypes::GRASS
    elsif @species==getConst(PBSpecies,:TERAPAGOS)
      return getID(PBTypes,:STELLAR)
    end
    return @teratype
  end

  def pbGenerateTeratype
    avaibletypes=[]
    for i in 0..PBTypes.maxValue
      avaibletypes.push(i) if !PBTypes.isPseudoType?(i) && !isConst?(i,PBTypes,:SHADOW)
    end
    teratype=avaibletypes.sample
    return teratype
  end

  def setTeratype(type) #Setea el teratipo del Pokémon
    type=getID(PBTypes,type) if type.is_a?(Symbol) || type.is_a?(String)
    @teratype=type
  end

  def isTera? #Comprueba si el Pokémon está teracristalizado
    return self.teracristalized
  end

  def makeTera #Teracristaiza al Pokémon
    @teracristalized=true
  end

  def makeUntera #Desteracristaiza al Pokémon
    @teracristalized=false
    if @species==PBSpecies::TERAPAGOS
      form=0
    end
  end

  def pbPokemonTeratype?(type) #Comprueba si el Pokémon tine cierto teratipo
    type=getID(PBTypes,type) if type.is_a?(Symbol)
    return true if @teratype==type
  end
################################################################################
# Otros
################################################################################
# Devuelve si este Pokémon está llevando un objeto.
  def hasItem?(value=0)
    if value==0
      return self.item>0
    else
      if value.is_a?(String) || value.is_a?(Symbol)
        value=getID(PBItems,value)
      end
      return self.item==value
    end
    return false
  end

# Establece el objeto de este Pokémon. Acepta symbols.
  def setItem(value)
    if value.is_a?(String) || value.is_a?(Symbol)
      value=getID(PBItems,value)
    end
    self.item=value
  end

# Devuelve el objeto que esta especie puede llevar cuando se encuentra salvaje
  def wildHoldItems
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,48)
    itemcommon=dexdata.fgetw
    itemuncommon=dexdata.fgetw
    itemrare=dexdata.fgetw
    dexdata.close
    itemcommon=0 if !itemcommon
    itemuncommon=0 if !itemuncommon
    itemrare=0 if !itemrare
    return [itemcommon,itemuncommon,itemrare]
  end

# Devuelve la carta de este Pokémon.
  def mail
    return nil if !@mail
    if @mail.item==0 || !self.hasItem? || @mail.item!=self.item
      @mail=nil
      return nil
    end
    return @mail
  end

  def species=(value)
    @species    = value
    @name       = PBSpecies.getName(@species)
    @level      = nil   # In case growth rate is different for the new species
    @forcedForm = nil
    calcStats
  end

  def isSpecies?(s)
    s = getID(PBSpecies,s)
    return s && @species==s
  end

# Devuelve el idioma de este Pokémon.
  def language; @language ? @language : 0; end

# Devuelve las marcar que tiene este Pokémon.
  def markings
    @markings=0 if !@markings
    return @markings
  end

# Devuelve una cadena que representa la forma Unown de este Pokémon.
  def unownShape
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZ?!"[@form,1]
  end

# Devuelve la altura de este Pokémon.
  def height
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,33)
    weight=dexdata.fgetw
    dexdata.close
    return weight
  end

# Devuelve el peso de este Pokémon.
  def weight
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,35)
    weight=dexdata.fgetw
    dexdata.close
    return weight
  end

# Devuelve los EV entregados por este Pokémon.
  def evYield
    ret=[]
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,23)
    for i in 0...6
      v=dexdata.fgetb
      v=0 if !v
      ret.push(v)
    end
    dexdata.close
    return ret
  end

  def kind
    return pbGetMessage(MessageTypes::Kinds,@species)
  end

  def dexEntry
    return pbGetMessage(MessageTypes::Entries,@species)
  end

# Establece los PS del Pokémon.
  def hp=(value)
    value=0 if value<0
    @hp=value
    if @hp==0
      @status=0
      @statusCount=0
    end
  end

# Restaura todos los PS del Pokémon.
  def healHP
    return if isEgg?
    @hp=@totalhp
  end

# Restaura el estado del Pokémon.
  def healStatus
    return if isEgg?
    @status=0
    @statusCount=0
  end

# Restaura todos los PP del Pokémon.
  def healPP(index=-1)
    return if isEgg?
    if index>=0
      @moves[index].pp=@moves[index].totalpp
    else
      for i in 0...4
        @moves[i].pp=@moves[i].totalpp
      end
    end
  end

# Restaura todos los PS, PP y estado del Pokémon.
  def heal
    return if isEgg?
    healHP
    healStatus
    healPP
  end

# Cambia la felicidad del Pokémon dependiendo de lo que haya ocurrido para que cambie.
  def changeHappiness(method)
    gain=0; luxury=false
    case method
    when "walking"
      gain=1
      gain+=1 if @happiness<200
      gain+=1 if @obtainMap==$game_map.map_id
      luxury=true
    when "level up"
      gain=2
      gain=3 if @happiness<200
      gain=5 if @happiness<100
      luxury=true
    when "groom"
      gain=4
      gain=10 if @happiness<200
      luxury=true
    when "faint"
      gain=-1
    when "vitamin"
      gain=2
      gain=3 if @happiness<200
      gain=5 if @happiness<100
    when "EV berry"
      gain=2
      gain=5 if @happiness<200
      gain=10 if @happiness<100
    when "powder"
      gain=-10
      gain=-5 if @happiness<200
    when "Energy Root"
      gain=-15
      gain=-10 if @happiness<200
    when "Revival Herb"
      gain=-20
      gain=-15 if @happiness<200
    else
      Kernel.pbMessage(_INTL("Método de modificación de felicidad desconocido."))
    end
    gain+=1 if luxury && self.ballused==pbGetBallType(:LUXURYBALL)
    if isConst?(self.item,PBItems,:SOOTHEBELL) && gain>0
      gain=(gain*1.5).floor
    end
    @happiness+=gain
    @happiness=[[255,@happiness].min,0].max
  end

################################################################################
# Cálculo de características, creación de Pokémon.
################################################################################
# Devuelve las características base de este Pokémon. Un arreglo de seis valores.
  def baseStats
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,10)
    ret=[
       dexdata.fgetb, # PS
       dexdata.fgetb, # Ataque
       dexdata.fgetb, # Defensa
       dexdata.fgetb, # Velocidad
       dexdata.fgetb, # Ataque Especial
       dexdata.fgetb  # Defensa Especial
    ]
    dexdata.close
    return ret
  end

# Devuelve los PS máximos de este Pokémon.
  def calcHP(base,level,iv,ev)
    return 1 if base==1
    return ((base*2+iv+(ev>>2))*level/100).floor+level+10
  end

# Devuelve la característica especificada de este Pokémon (no se usa para PS totales).
  def calcStat(base,level,iv,ev,pv)
    return ((((base*2+iv+(ev>>2))*level/100).floor+5)*pv/100).floor
  end

# Recalcula las características de este Pokémon.
  def calcStats
    nature=self.nature
    stats=[]
    pvalues=[100,100,100,100,100]
    nd5=(nature/5).floor
    nm5=(nature%5).floor
    if nd5!=nm5
      pvalues[nd5]=110
      pvalues[nm5]=90
    end
    level=self.level
    bs=self.baseStats
    for i in 0..5
      base=bs[i]
      if i==PBStats::HP
        stats[i]=calcHP(base,level,@iv[i],@ev[i])
      else
        stats[i]=calcStat(base,level,@iv[i],@ev[i],pvalues[i-1])
      end
    end
    diff=@totalhp-@hp
    @totalhp=stats[0]
    @hp=@totalhp-diff
    @hp=0 if @hp<=0
    @hp=@totalhp if @hp>@totalhp
    @attack=stats[1]
    @defense=stats[2]
    @speed=stats[3]
    @spatk=stats[4]
    @spdef=stats[5]
  end

# Creación de un objeto Pokémon nuevo.
#    species   - Especie del Pokémon.
#    level     - Nivel del Pokémon.
#    player    - Objeto PokeBattle_Trainer para el entrenador original.
#    withMoves - Si está en false, este Pokémon no tendrá movimientos.
  def initialize(species,level,player=nil,withMoves=true)
    if species.is_a?(String) || species.is_a?(Symbol)
      species=getID(PBSpecies,species)
    end
    cname=getConstantName(PBSpecies,species) rescue nil
    if !species || species<1 || species>PBSpecies.maxValue || !cname
      raise ArgumentError.new(_INTL("El número de especie (núm. {1} de {2}) no es válido.",
         species,PBSpecies.maxValue))
      return nil
    end
    time=pbGetTimeNow
    @timeReceived=time.getgm.to_i # Usa GMT
    @species=species
    # IVs (Valores Individuales)
    @personalID=rand(256)
    @personalID|=rand(256)<<8
    @personalID|=rand(256)<<16
    @personalID|=rand(256)<<24
    @hp=1
    @totalhp=1
    @ev=[0,0,0,0,0,0]
    @iv=[]
    @iv[0]=rand(32)
    @iv[1]=rand(32)
    @iv[2]=rand(32)
    @iv[3]=rand(32)
    @iv[4]=rand(32)
    @iv[5]=rand(32)
    if player
      @trainerID=player.id
      @ot=player.name
      @otgender=player.gender
      @language=player.language
    else
      @trainerID=0
      @ot=""
      @otgender=2
    end
    dexdata=pbOpenDexData
    pbDexDataOffset(dexdata,@species,19)
    @happiness=dexdata.fgetb
    dexdata.close
    @name=PBSpecies.getName(@species)
    @eggsteps=0
    @status=0
    @statusCount=0
    @item=0
    @mail=nil
    @fused=nil
    @ribbons=[]
    @teratype=pbGenerateTeratype()
    @moves=[]
    self.ballused=0
    self.level=level
    calcStats
    @hp=@totalhp
    if $game_map
      @obtainMap=$game_map.map_id
      @obtainText=nil
      @obtainLevel=level
    else
      @obtainMap=0
      @obtainText=nil
      @obtainLevel=level
    end
    @obtainMode=0   # Encuentro
    @obtainMode=4 if $game_switches && $game_switches[FATEFUL_ENCOUNTER_SWITCH]
    @hatchedMap=0
    @original_types=[0,0]
    if withMoves
      atkdata=pbRgssOpen("Data/attacksRS.dat","rb")
      offset=atkdata.getOffset(species-1)
      length=atkdata.getLength(species-1)>>1
      atkdata.pos=offset
      # Genera lista de movimientos
      movelist=[]
      for i in 0..length-1
        alevel=atkdata.fgetw
        move=atkdata.fgetw
        if alevel<=level
          movelist[movelist.length]=move
        end
      end
      atkdata.close
      movelist|=[] # Elimina duplicados
      # Se usan los últimos 4 elementos en la lista de movimientos
      listend=movelist.length-4
      listend=0 if listend<0
      j=0
      for i in listend...listend+4
        moveid=(i>=movelist.length) ? 0 : movelist[i]
        @moves[j]=PBMove.new(moveid)
        j+=1
      end
    else
      for i in 0...4
        @moves[i]=PBMove.new(0)
      end
    end
  end
end
