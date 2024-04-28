class PokeBattle_Move
  attr_accessor(:id)
  attr_reader(:battle)
  attr_reader(:name)
  attr_reader(:function)
  attr_reader(:basedamage)
  attr_reader(:type)
  attr_reader(:accuracy)
  attr_reader(:addlEffect)
  attr_reader(:target)
  attr_reader(:priority)
  attr_reader(:flags)
  attr_reader(:thismove)
  attr_accessor(:pp)
  attr_accessor(:totalpp)
  attr_accessor(:zmove)

  NOTYPE          = 0x01
  IGNOREPKMNTYPES = 0x02
  NOWEIGHTING     = 0x04
  NOCRITICAL      = 0x08
  NOREFLECT       = 0x10
  SELFCONFUSE     = 0x20

################################################################################
# Creating a move / Creación de un movimiento
################################################################################
  def initialize(battle,move)
    @id = move.id
    @battle = battle
    @name = PBMoves.getName(id)   # Devuelve el nombre del movimiento
    # Devuelve datos sobre el movimiento
    movedata = PBMoveData.new(id)
    @function   = movedata.function
    @basedamage = movedata.basedamage
    @type       = movedata.type
    @accuracy   = movedata.accuracy
    @addlEffect = movedata.addlEffect
    @target     = movedata.target
    @priority   = movedata.priority
    @flags      = movedata.flags
    @category   = movedata.category
    @thismove   = move
    @pp         = move.pp   # Puede ser cambiado con Mimic/Transform
    @powerboost = false   # For Aerilate, Pixilate, Refrigerate
    @zmove      = false
  end

# This is the code actually used to generate a PokeBattle_Move object.  The
# object generated is a subclass of this one which depends on the move's
# function code (found in the script section PokeBattle_MoveEffect).
  def PokeBattle_Move.pbFromPBMove(battle,move)
    move=PBMove.new(0) if !move
    movedata=PBMoveData.new(move.id)
    className=sprintf("PokeBattle_Move_%03X",movedata.function)
    if Object.const_defined?(className)
      return Kernel.const_get(className).new(battle,move)
    else
      return PokeBattle_UnimplementedMove.new(battle,move)
    end
  end

################################################################################
# Acerca del movimiento
################################################################################
  def totalpp
    return @totalpp if @totalpp && @totalpp>0
    return @thismove.totalpp if @thismove
    return 0
  end

  def addlEffect
    return @addlEffect
  end

  def to_int
    return @id
  end

  def pbModifyType(type,attacker,opponent)
    if type>=0
      if attacker.hasWorkingAbility(:NORMALIZE) && hasConst?(PBTypes,:NORMAL)
        type=getConst(PBTypes,:NORMAL)
      elsif isConst?(type,PBTypes,:NORMAL)
        if attacker.hasWorkingAbility(:AERILATE) && hasConst?(PBTypes,:FLYING)
          type=getConst(PBTypes,:FLYING)
          @powerboost=true
        elsif attacker.hasWorkingAbility(:REFRIGERATE) && hasConst?(PBTypes,:ICE)
          type=getConst(PBTypes,:ICE)
          @powerboost=true
        elsif attacker.hasWorkingAbility(:PIXILATE) && hasConst?(PBTypes,:FAIRY)
          type=getConst(PBTypes,:FAIRY)
          @powerboost=true
        elsif attacker.hasWorkingAbility(:GALVANIZE) && hasConst?(PBTypes,:ELECTRIC)
          type=getConst(PBTypes,:ELECTRIC)
          @powerboost=true
        end
      end
    end
    return type
  end

  def pbType(type,attacker,opponent)
    @powerboost=false
    type=pbModifyType(type,attacker,opponent)
    if type>=0 && hasConst?(PBTypes,:ELECTRIC)
      if @battle.field.effects[PBEffects::IonDeluge] && isConst?(type,PBTypes,:NORMAL)
        type=getConst(PBTypes,:ELECTRIC)
        @powerboost=false
      end
      if @battle.field.effects[PBEffects::PlasmaFists] && isConst?(type,PBTypes,:NORMAL)
        type=getConst(PBTypes,:ELECTRIC)
        @powerboost=false
      elsif isConst?(type,PBTypes,:NORMAL)
        if @battle.field.effects[PBEffects::PlasmaFists] && attacker.hasWorkingAbility(:AERILATE) &&
         hasConst?(PBTypes,:FLYING)
          type=getConst(PBTypes,:FLYING)
          @powerboots=true
        elsif @battle.field.effects[PBEffects::PlasmaFists] && attacker.hasWorkingAbility(:REFRIGERATE) &&
         hasConst?(PBTypes,:ICE)
          type=getConst(PBTypes,:ICE)
          @powerboots=true
        elsif @battle.field.effects[PBEffects::PlasmaFists] && attacker.hasWorkingAbility(:PIXILATE) &&
         hasConst?(PBTypes,:FAIRY)
          type=getConst(PBTypes,:FAIRY)
          @powerboots=true
        elsif @battle.field.effects[PBEffects::PlasmaFists] && attacker.hasWorkingAbility(:GALVANIZE) &&
         hasConst?(PBTypes,:ELECTRIC)
          type=getConst(PBTypes,:ELECTRIC)
          @powerboots=true
        end
      end
      if attacker.effects[PBEffects::Electrify]
        type=getConst(PBTypes,:ELECTRIC)
        @powerboost=false
      end
    end
    return type
  end

  def pbIsPhysical?(type)
    if USEMOVECATEGORY
      return @category==0
    else
      return !PBTypes.isSpecialType?(type)
    end
  end

  def pbIsSpecial?(type)
    if USEMOVECATEGORY
      return @category==1
    else
      return PBTypes.isSpecialType?(type)
    end
  end

  def pbIsStatus?
    return @category==2
  end

  def pbIsDamaging?
    return !pbIsStatus?
  end

  def pbTargetsMultiple?(attacker)
    numtargets=0
    if @target==PBTargets::AllOpposing
      # TODO: should apply even if partner faints during an attack
      numtargets+=1 if !attacker.pbOpposing1.isFainted?
      numtargets+=1 if !attacker.pbOpposing2.isFainted?
      return numtargets>1
    elsif @target==PBTargets::AllNonUsers
      # TODO: should apply even if partner faints during an attack
      numtargets+=1 if !attacker.pbOpposing1.isFainted?
      numtargets+=1 if !attacker.pbOpposing2.isFainted?
      numtargets+=1 if !attacker.pbPartner.isFainted?
      return numtargets>1
    end
    return false
  end

  def pbPriority(attacker)
    ret=@priority
    return ret
  end

  def pbNumHits(attacker)
    # Parental Bond goes here (for single target moves only)
    if attacker.hasWorkingAbility(:PARENTALBOND)
      if pbIsDamaging? && !pbTargetsMultiple?(attacker) &&
         !pbIsMultiHit && !pbTwoTurnAttack(attacker)
        exceptions=[0x6E,   # Esfuerzo
                    0xE0,   # Autodestru./Explosión
                    0xE1,   # Sacrificio
                    0xF7]   # Lanzamiento
        if !exceptions.include?(@function)
          attacker.effects[PBEffects::ParentalBond]=3
          return 2
        end
      end
    end
    # Need to record that Parental Bond applies, to weaken the second attack
    return 1
  end

  def pbIsMultiHit   # not the same as pbNumHits>1
    return false
  end

  def pbTwoTurnAttack(attacker)
    return false
  end

  def pbAdditionalEffect(attacker,opponent)
  end

  def pbCanUseWhileAsleep?
    return false
  end

  def isHealingMove?
    return false
  end

  def isRecoilMove?
    return false
  end

  def unusableInGravity?
    return false
  end

  def isContactMove?
    return (@flags&0x01)!=0 # flag a: Makes contact
  end

  def canProtectAgainst?
    return (@flags&0x02)!=0 # flag b: Protect/Detect
  end

  def canMagicCoat?
    return (@flags&0x04)!=0 # flag c: Magic Coat
  end

  def canSnatch?
    return (@flags&0x08)!=0 # flag d: Snatch
  end

  def canMirrorMove? # This method isn't used
    return (@flags&0x10)!=0 # flag e: Copyable by Mirror Move
  end

  def canKingsRock?
    return (@flags&0x20)!=0 # flag f: King's Rock
  end

  def canThawUser?
    return (@flags&0x40)!=0 # flag g: Thaws user before moving
  end

  def hasHighCriticalRate?
    return (@flags&0x80)!=0 # flag h: Has high critical hit rate
  end

  def isBitingMove?
    return (@flags&0x100)!=0 # flag i: Is biting move
  end

  def isPunchingMove?
    return (@flags&0x200)!=0 # flag j: Is punching move
  end

  def isSoundBased?
    return (@flags&0x400)!=0 # flag k: Is sound-based move
  end

  def isPowderMove?
    return (@flags&0x800)!=0 # flag l: Is powder move
  end

  def isPulseMove?
    return (@flags&0x1000)!=0 # flag m: Is pulse move
  end

  def isBombMove?
    return (@flags&0x2000)!=0 # flag n: Is bomb move
  end

  def isRazorMove?
    return isConst?(@id,PBMoves,:AIRCUTTER) ||
           isConst?(@id,PBMoves,:SECRETSWORD) ||
           isConst?(@id,PBMoves,:RAZORSHELL) ||
           isConst?(@id,PBMoves,:CUT) ||
           isConst?(@id,PBMoves,:FURYCUTTER) ||
           isConst?(@id,PBMoves,:SOLARBLADE) ||
           isConst?(@id,PBMoves,:SLASH) ||
           isConst?(@id,PBMoves,:SACREDSWORD) ||
           isConst?(@id,PBMoves,:AERIALACE) ||
           isConst?(@id,PBMoves,:STONEAXE) ||
           isConst?(@id,PBMoves,:RAZORLEAF) ||
           isConst?(@id,PBMoves,:LEAFBLADE) ||
           isConst?(@id,PBMoves,:PSYCHOCUT) ||
           isConst?(@id,PBMoves,:AQUACUTTER) ||
           isConst?(@id,PBMoves,:AIRSLASH) ||
           isConst?(@id,PBMoves,:CEASELESSEDGE) ||
           isConst?(@id,PBMoves,:BEHEMOTHBLADE) ||
           isConst?(@id,PBMoves,:NIGHTSLASH) ||
           isConst?(@id,PBMoves,:CROSSPOISON) ||
           isConst?(@id,PBMoves,:XSCISSOR) ||
           isConst?(@id,PBMoves,:BITTERBLADE) ||
           isConst?(@id,PBMoves,:POPULATIONBOMB) ||
           isConst?(@id,PBMoves,:KOWTOWCLEAVE) ||
           isConst?(@id,PBMoves,:MIGHTYCLEAVE) ||
           isConst?(@id,PBMoves,:PSYBLADE) ||
           isConst?(@id,PBMoves,:TACHYONCUTTER) 
           
  end

  def isDanceMove?
    return isConst?(@id,PBMoves,:QUIVERDANCE) ||
           isConst?(@id,PBMoves,:DRAGONDANCE) ||
           isConst?(@id,PBMoves,:FIERYDANCE) ||
           isConst?(@id,PBMoves,:FEATHERDANCE) ||
           isConst?(@id,PBMoves,:PETALDANCE) ||
           isConst?(@id,PBMoves,:SWORDSDANCE) ||
           isConst?(@id,PBMoves,:TEETERDANCE) ||
           isConst?(@id,PBMoves,:LUNARDANCE) ||
           isConst?(@id,PBMoves,:REVELATIONDANCE) ||
           isConst?(@id,PBMoves,:VICTORYDANCE) ||
           isConst?(@id,PBMoves,:AQUASTEP)||
           isConst?(@id,PBMoves,:CLANGOROUSSOUL)
  end

  def isWindMove?
    return isConst?(@id,PBMoves,:AIRCUTTER) ||
           isConst?(@id,PBMoves,:TAILWIND) ||
           isConst?(@id,PBMoves,:TWISTER) ||
           isConst?(@id,PBMoves,:SPRINGTIDESTORM) ||
           isConst?(@id,PBMoves,:WILDBOLTSTORM) ||
           isConst?(@id,PBMoves,:BLEAKWINDSTORM) ||
           isConst?(@id,PBMoves,:SANDSEARSTORM) ||
           isConst?(@id,PBMoves,:HEATWAVE) ||
           isConst?(@id,PBMoves,:GUST) ||
           isConst?(@id,PBMoves,:HURRICANE) ||
           isConst?(@id,PBMoves,:ICYWIND) ||
           isConst?(@id,PBMoves,:FAIRYWIND) ||
           isConst?(@id,PBMoves,:PETALBLIZZARD) ||
           isConst?(@id,PBMoves,:BLIZZARD) ||
           isConst?(@id,PBMoves,:SANDSTORM) ||
           isConst?(@id,PBMoves,:WHIRLWIND)
  end

  def doesBypassIgnorableAbilities?
    return false
  end

  def doesBypassTargetSwap?
    return false
  end

  def tramplesMinimize?(param=1) # Causes perfect accuracy and double damage
    return false if !USENEWBATTLEMECHANICS
    return isConst?(@id,PBMoves,:BODYSLAM) ||
           isConst?(@id,PBMoves,:FLYINGPRESS) ||
           isConst?(@id,PBMoves,:PHANTOMFORCE)
  end

  def successCheckPerHit?
    return false
  end

  def ignoresSubstitute?(attacker)
    if USENEWBATTLEMECHANICS
      return true if isSoundBased?
      return true if attacker && attacker.hasWorkingAbility(:INFILTRATOR)
      return true if attacker && isConst?(thismove.id,PBMoves,:AFTERYOU)
      return true if attacker && isConst?(thismove.id,PBMoves,:AROMATICMIST)
      return true if attacker && isConst?(thismove.id,PBMoves,:ATTRACT)
      return true if attacker && isConst?(thismove.id,PBMoves,:BESTOW)
      return true if attacker && isConst?(thismove.id,PBMoves,:BOOMBURST)
      return true if attacker && isConst?(thismove.id,PBMoves,:BUGBUZZ)
      return true if attacker && isConst?(thismove.id,PBMoves,:CHATTER)
      return true if attacker && isConst?(thismove.id,PBMoves,:CLANGINGSCALES)
      return true if attacker && isConst?(thismove.id,PBMoves,:CONFIDE)
      return true if attacker && isConst?(thismove.id,PBMoves,:CONVERSION2)
      return true if attacker && isConst?(thismove.id,PBMoves,:CURSE)
      return true if attacker && isConst?(thismove.id,PBMoves,:DESTINYBOND)
      return true if attacker && isConst?(thismove.id,PBMoves,:DISABLE)
      return true if attacker && isConst?(thismove.id,PBMoves,:DISARMINGVOICE)
      return true if attacker && isConst?(thismove.id,PBMoves,:ECHOEDVOICE)
      return true if attacker && isConst?(thismove.id,PBMoves,:ENCORE)
      return true if attacker && isConst?(thismove.id,PBMoves,:FAIRYLOCK)
      return true if attacker && isConst?(thismove.id,PBMoves,:FORESIGHT)
      return true if attacker && isConst?(thismove.id,PBMoves,:GEARUP)
      return true if attacker && isConst?(thismove.id,PBMoves,:GRASSWHISTLE)
      return true if attacker && isConst?(thismove.id,PBMoves,:GROWL)
      return true if attacker && isConst?(thismove.id,PBMoves,:GRUDGE)
      return true if attacker && isConst?(thismove.id,PBMoves,:GUARDSWAP)
      return true if attacker && isConst?(thismove.id,PBMoves,:HAZE)
      return true if attacker && isConst?(thismove.id,PBMoves,:HEALBELL)
      return true if attacker && isConst?(thismove.id,PBMoves,:HEARTSWAP)
      return true if attacker && isConst?(thismove.id,PBMoves,:HELPINGHAND)
      return true if attacker && isConst?(thismove.id,PBMoves,:HYPERSPACEFURY)
      return true if attacker && isConst?(thismove.id,PBMoves,:HYPERSPACEHOLY)
      return true if attacker && isConst?(thismove.id,PBMoves,:HYPERVOICE)
      return true if attacker && isConst?(thismove.id,PBMoves,:IMPRISON)
      return true if attacker && isConst?(thismove.id,PBMoves,:INSTRUCT)
      return true if attacker && isConst?(thismove.id,PBMoves,:MAGNETICFLUX)
      return true if attacker && isConst?(thismove.id,PBMoves,:METALSOUND)
      return true if attacker && isConst?(thismove.id,PBMoves,:MIRACLEEYE)
      return true if attacker && isConst?(thismove.id,PBMoves,:NOBLEROAR)
      return true if attacker && isConst?(thismove.id,PBMoves,:ODORSLEUTH)
      return true if attacker && isConst?(thismove.id,PBMoves,:PARTINGSHOT)
      return true if attacker && isConst?(thismove.id,PBMoves,:PERISHSONG)
      return true if attacker && isConst?(thismove.id,PBMoves,:PLAYNICE)
      return true if attacker && isConst?(thismove.id,PBMoves,:POWDER)
      return true if attacker && isConst?(thismove.id,PBMoves,:POWERSWAP)
      return true if attacker && isConst?(thismove.id,PBMoves,:PSYCHUP)
      return true if attacker && isConst?(thismove.id,PBMoves,:RECLECTTYPE)
      return true if attacker && isConst?(thismove.id,PBMoves,:RELICSONG)
      return true if attacker && isConst?(thismove.id,PBMoves,:ROAR)
      return true if attacker && isConst?(thismove.id,PBMoves,:ROLEPLAY)
      return true if attacker && isConst?(thismove.id,PBMoves,:ROUND)
      return true if attacker && isConst?(thismove.id,PBMoves,:SCREECH)
      return true if attacker && isConst?(thismove.id,PBMoves,:SING)
      return true if attacker && isConst?(thismove.id,PBMoves,:SKILLSWAP)
      return true if attacker && isConst?(thismove.id,PBMoves,:SNARL)
      return true if attacker && isConst?(thismove.id,PBMoves,:SNORE)
      return true if attacker && isConst?(thismove.id,PBMoves,:SPARKLINGARIA)
      return true if attacker && isConst?(thismove.id,PBMoves,:SPECTRALTHIEF)
      return true if attacker && isConst?(thismove.id,PBMoves,:SPEEDSWAP)
      return true if attacker && isConst?(thismove.id,PBMoves,:SPITE)
      return true if attacker && isConst?(thismove.id,PBMoves,:SUPERSONIC)
      return true if attacker && isConst?(thismove.id,PBMoves,:TAUNT)
      return true if attacker && isConst?(thismove.id,PBMoves,:TORMENT)
      return true if attacker && isConst?(thismove.id,PBMoves,:UPROAR)
      return true if attacker && isConst?(thismove.id,PBMoves,:WHIRLWIND)
      return true if attacker && isConst?(thismove.id,PBMoves,:LIFEDEW)
      return true if attacker && isConst?(thismove.id,PBMoves,:TEATIME)
    end
    return false
  end

################################################################################
# Efectividad del tipo de este movimiento
################################################################################
  def pbTypeImmunityByAbility(type,attacker,opponent)
    return false if attacker.index==opponent.index
    return false if attacker.hasMoldBreaker
    return false if doesBypassIgnorableAbilities?
    # Herbívoro
    if opponent.hasWorkingAbility(:SAPSIPPER) && isConst?(type,PBTypes,:GRASS)
      PBDebug.log("[Habilidad disparada] Herbívoro de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,opponent)
        opponent.pbIncreaseStatWithCause(PBStats::ATTACK,1,opponent,PBAbilities.getName(opponent.ability))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      end
      return true
    end
    # Colector / Pararrayos
    if (opponent.hasWorkingAbility(:STORMDRAIN) && isConst?(type,PBTypes,:WATER)) ||
       (opponent.hasWorkingAbility(:LIGHTNINGROD) && isConst?(type,PBTypes,:ELECTRIC))
      PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(opponent.ability)} de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if opponent.pbCanIncreaseStatStage?(PBStats::SPATK,opponent)
        opponent.pbIncreaseStatWithCause(PBStats::SPATK,1,opponent,PBAbilities.getName(opponent.ability))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      end
      return true
    end
    # Electromotor
    if opponent.hasWorkingAbility(:MOTORDRIVE) && isConst?(type,PBTypes,:ELECTRIC)
      PBDebug.log("[Habilidad disparada] Electromotor de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if opponent.pbCanIncreaseStatStage?(PBStats::SPEED,opponent)
        opponent.pbIncreaseStatWithCause(PBStats::SPEED,1,opponent,PBAbilities.getName(opponent.ability))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      end
      return true
    end
    # Cuerpo Horneado
    if opponent.hasWorkingAbility(:WELLBAKEDBODY) && isConst?(type,PBTypes,:FIRE)
      PBDebug.log("[Habilidad disparada] Electromotor de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if opponent.pbCanIncreaseStatStage?(PBStats::DEFENSE,opponent)
        opponent.pbIncreaseStatWithCause(PBStats::DEFENSE,2,opponent,PBAbilities.getName(opponent.ability))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      end
      return true
    end
    # Surcavientos
    if opponent.hasWorkingAbility(:WINDRIDER) && isWindMove?
      PBDebug.log("[Habilidad disparada] Surcavientos de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,opponent)
        opponent.pbIncreaseStatWithCause(PBStats::ATTACK,1,opponent,PBAbilities.getName(opponent.ability))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      end
      return true
    end
    # Piel Seca / Absorbe Elec. / Absorbe Agua / Geofagia
    if (opponent.hasWorkingAbility(:DRYSKIN) && isConst?(type,PBTypes,:WATER)) ||
       (opponent.hasWorkingAbility(:VOLTABSORB) && isConst?(type,PBTypes,:ELECTRIC)) ||
       (opponent.hasWorkingAbility(:WATERABSORB) && isConst?(type,PBTypes,:WATER)) ||
       (opponent.hasWorkingAbility(:EARTHEATER) && isConst?(type,PBTypes,:GROUND))
      PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(opponent.ability)} de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if opponent.effects[PBEffects::HealBlock]==0
        if opponent.pbRecoverHP((opponent.totalhp/4).floor,true)>0
          @battle.pbDisplay(_INTL("¡{2} de {1} recuperó sus PS!",
             opponent.pbThis,PBAbilities.getName(opponent.ability)))
        else
          @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
             opponent.pbThis,PBAbilities.getName(opponent.ability),@name))
        end
        return true
      end
    end
    # Absorbe Fuego
    if opponent.hasWorkingAbility(:FLASHFIRE) && isConst?(type,PBTypes,:FIRE)
      PBDebug.log("[Habilidad disparada] Absorbe Fuego de #{opponent.pbThis} (hizo ineficaz #{@name})")
      if !opponent.effects[PBEffects::FlashFire]
        opponent.effects[PBEffects::FlashFire]=true
        @battle.pbDisplay(_INTL("¡{2} de {1} subió la potencia de sus movimientos de tipo Fuego!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
      else
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      end
      return true
    end
    # Telepatía
    if opponent.hasWorkingAbility(:TELEPATHY) && pbIsDamaging? &&
       !opponent.pbIsOpposing?(attacker.index)
      PBDebug.log("[Habilidad disparada] Telepatía de #{opponent.pbThis} (hizo ineficaz #{@name})")
      @battle.pbDisplay(_INTL("¡{1} evita los ataques de sus Pokémon aliados!",opponent.pbThis))
      return true
    end
    # Antibalas
    if opponent.hasWorkingAbility(:BULLETPROOF) && isBombMove?
      PBDebug.log("[Habilidad disparada] Antibalas de #{opponent.pbThis} (hizo ineficaz #{@name})")
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",
         opponent.pbThis,PBAbilities.getName(opponent.ability),self.name))
      return true
    end
    return false
  end

  def pbTypeModifier(type,attacker,opponent)
    return 8 if type<0
    return 8 if isConst?(type,PBTypes,:GROUND) && opponent.pbHasType?(:FLYING) &&
                opponent.hasWorkingItem(:IRONBALL) && !USENEWBATTLEMECHANICS
    atype=type # attack type
    otype1=opponent.type1
    otype2=opponent.type2
    if opponent.type1==PBTypes::STELLAR
      otype1=opponent.pokemon.original_types[0]
      otype2=opponent.pokemon.original_types[1]
    end
    otype3=opponent.effects[PBEffects::Type3] || -1
    # Voz Fluida
    if attacker.hasWorkingAbility(:LIQUIDVOICE) && isSoundBased?
      atype=getConst(PBTypes,:WATER) || 0
    end
    # Respiro
    if isConst?(otype1,PBTypes,:FLYING) && opponent.effects[PBEffects::Roost]
      if isConst?(otype2,PBTypes,:FLYING) && isConst?(otype3,PBTypes,:FLYING)
        otype1=getConst(PBTypes,:NORMAL) || 0
      else
        otype1=otype2
      end
    end
    if isConst?(otype2,PBTypes,:FLYING) && opponent.effects[PBEffects::Roost]
      otype2=otype1
    end
    # Get effectivenesses
    mod1=PBTypes.getEffectiveness(atype,otype1)
    mod2=(otype1==otype2) ? 2 : PBTypes.getEffectiveness(atype,otype2)
    mod3=(otype3<0 || otype1==otype3 || otype2==otype3) ? 2 : PBTypes.getEffectiveness(atype,otype3)
    if opponent.hasWorkingItem(:RINGTARGET)
      mod1=2 if mod1==0
      mod2=2 if mod2==0
      mod3=2 if mod3==0
    end
    if opponent.isTera? && type==PBTypes::STELLAR
      return 16
    end
    # Foresight / Ojo Mental
    if attacker.hasWorkingAbility(:SCRAPPY) || opponent.effects[PBEffects::Foresight] ||
       attacker.hasWorkingAbility(:MINDSEYE)
      mod1=2 if isConst?(otype1,PBTypes,:GHOST) && PBTypes.isIneffective?(atype,otype1)
      mod2=2 if isConst?(otype2,PBTypes,:GHOST) && PBTypes.isIneffective?(atype,otype2)
      mod3=2 if isConst?(otype3,PBTypes,:GHOST) && PBTypes.isIneffective?(atype,otype3)
    end
    # Miracle Eye
    if opponent.effects[PBEffects::MiracleEye]
      mod1=2 if isConst?(otype1,PBTypes,:DARK) && PBTypes.isIneffective?(atype,otype1)
      mod2=2 if isConst?(otype2,PBTypes,:DARK) && PBTypes.isIneffective?(atype,otype2)
      mod3=2 if isConst?(otype3,PBTypes,:DARK) && PBTypes.isIneffective?(atype,otype3)
    end
    # Delta Stream's weather
    if @battle.pbWeather==PBWeather::STRONGWINDS
      mod1=2 if isConst?(otype1,PBTypes,:FLYING) && PBTypes.isSuperEffective?(atype,otype1)
      mod2=2 if isConst?(otype2,PBTypes,:FLYING) && PBTypes.isSuperEffective?(atype,otype2)
      mod3=2 if isConst?(otype3,PBTypes,:FLYING) && PBTypes.isSuperEffective?(atype,otype3)
    end
    # Smack Down makes Ground moves work against fliers
    if (!opponent.isAirborne?(attacker.hasMoldBreaker ||
      doesBypassIgnorableAbilities?) || @function==0x11C) && # Smack Down
       isConst?(atype,PBTypes,:GROUND)
      mod1=2 if isConst?(otype1,PBTypes,:FLYING)
      mod2=2 if isConst?(otype2,PBTypes,:FLYING)
      mod3=2 if isConst?(otype3,PBTypes,:FLYING)
    end
    if @function==0x135 && !attacker.effects[PBEffects::Electrify] # Freeze-Dry
      mod1=4 if isConst?(otype1,PBTypes,:WATER)
      if isConst?(otype2,PBTypes,:WATER)
        mod2=(otype1==otype2) ? 2 : 4
      end
      if isConst?(otype3,PBTypes,:WATER)
        mod3=(otype1==otype3 || otype2==otype3) ? 2 : 4
      end
    end
    if opponent.effects[PBEffects::TarShot] && isConst?(atype,PBTypes,:FIRE) # Tar Shot
      weakness=mod1
      mod1=weakness+1
    end
    return mod1*mod2*mod3
  end

  def pbTypeModMessages(type,attacker,opponent)
    return 8 if type<0
    typemod=pbTypeModifier(type,attacker,opponent)
    if typemod==0
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
    else
      return 0 if pbTypeImmunityByAbility(type,attacker,opponent)
    end
    return typemod
  end

################################################################################
# Revisión de la precisión del movimiento
################################################################################
  def pbModifyBaseAccuracy(baseaccuracy,attacker,opponent)
    return baseaccuracy
  end

  def pbAccuracyCheck(attacker,opponent)
    baseaccuracy=@accuracy
    baseaccuracy=pbModifyBaseAccuracy(baseaccuracy,attacker,opponent)
    baseaccuracy=0 if opponent.effects[PBEffects::Minimize] && tramplesMinimize?(1)
    return true if baseaccuracy==0
    return true if attacker.hasWorkingAbility(:NOGUARD) ||
                   opponent.hasWorkingAbility(:NOGUARD)
    return true if opponent.hasWorkingAbility(:STORMDRAIN) &&
                   isConst?(pbType(@type,attacker,opponent),PBTypes,:WATER)
    return true if opponent.hasWorkingAbility(:LIGHTNINGROD) &&
                   isConst?(pbType(@type,attacker,opponent),PBTypes,:ELECTRIC)
    return true if opponent.effects[PBEffects::Telekinesis]>0
    # One-hit KO accuracy handled elsewhere
    accstage=attacker.stages[PBStats::ACCURACY]
    accstage=0 if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:UNAWARE) &&
    !doesBypassIgnorableAbilities?
    accuracy=(accstage>=0) ? (accstage+3)*100.0/3 : 300.0/(3-accstage)
    evastage=opponent.stages[PBStats::EVASION]
    evastage-=2 if @battle.field.effects[PBEffects::Gravity]>0
    evastage=-6 if evastage<-6
    evastage=0 if evastage>0 && USENEWBATTLEMECHANICS &&
                  attacker.hasWorkingAbility(:KEENEYE)
    evastage=0 if opponent.effects[PBEffects::Foresight] ||
                  opponent.effects[PBEffects::MiracleEye] ||
                  @function==0xA9 || # Chip Away
                  attacker.hasWorkingAbility(:UNAWARE) ||
                  attacker.hasWorkingAbility(:MINDSEYE)
    evasion=(evastage>=0) ? (evastage+3)*100.0/3 : 300.0/(3-evastage)
    if attacker.hasWorkingAbility(:COMPOUNDEYES)
      accuracy*=1.3
    end
    if attacker.hasWorkingAbility(:HUSTLE) && pbIsDamaging? &&
       pbIsPhysical?(pbType(@type,attacker,opponent))
      accuracy*=0.8
    end
    if attacker.hasWorkingAbility(:VICTORYSTAR)
      accuracy*=1.1
    end
    partner=attacker.pbPartner
    if partner && partner.hasWorkingAbility(:VICTORYSTAR)
      accuracy*=1.1
    end
    if attacker.effects[PBEffects::MicleBerry]
      attacker.effects[PBEffects::MicleBerry]=false
      accuracy*=1.2
    end
    if attacker.hasWorkingItem(:WIDELENS)
      accuracy*=1.1
    end
    if attacker.hasWorkingItem(:ZOOMLENS) &&
       (@battle.choices[opponent.index][0]!=1 || # Didn't choose a move
       opponent.hasMovedThisRound?) # Used a move already
      accuracy*=1.2
    end
    if !attacker.hasMoldBreaker && !doesBypassIgnorableAbilities?
      if opponent.hasWorkingAbility(:WONDERSKIN) && pbIsStatus? &&
         attacker.pbIsOpposing?(opponent.index)
        accuracy=50 if accuracy>50
      end
      if opponent.hasWorkingAbility(:TANGLEDFEET) &&
         opponent.effects[PBEffects::Confusion]>0
        evasion*=1.2
      end
      if opponent.hasWorkingAbility(:SANDVEIL) &&
         @battle.pbWeather==PBWeather::SANDSTORM
        evasion*=1.25
      end
      if opponent.hasWorkingAbility(:SNOWCLOAK) &&
         @battle.pbWeather==PBWeather::HAIL
        evasion*=1.25
      end
    end
    if opponent.hasWorkingItem(:BRIGHTPOWDER)
      evasion*=1.1
    end
    if opponent.hasWorkingItem(:LAXINCENSE)
      evasion*=1.1
    end
    return @battle.pbRandom(100)<(baseaccuracy*accuracy/evasion)
  end

################################################################################
# Cálculo de daño y modificadores
################################################################################
  def pbCritialOverride(attacker,opponent)
    return false
  end

  def pbIsCritical?(attacker,opponent)
    if attacker.effects[PBEffects::LaserFocus]>0
      attacker.effects[PBEffects::LaserFocus]=0
      return true
    end
    if !attacker.hasMoldBreaker && !doesBypassIgnorableAbilities?
      if opponent.hasWorkingAbility(:BATTLEARMOR) ||
         opponent.hasWorkingAbility(:SHELLARMOR)
        return false
      end
      return true if attacker.hasWorkingAbility(:MERCILESS) && opponent.status==PBStatuses::POISON
      return true if attacker.effects[PBEffects::LaserFocus]>0
    end
    return false if opponent.pbOwnSide.effects[PBEffects::LuckyChant]>0
    return true if pbCritialOverride(attacker,opponent)
    c=0
    ratios=(USENEWBATTLEMECHANICS) ? [16,8,2,1,1] : [16,8,4,3,2]
    c+=attacker.effects[PBEffects::FocusEnergy]
    c+=1 if hasHighCriticalRate?
    if (attacker.inHyperMode? rescue false) && isConst?(self.type,PBTypes,:SHADOW)
      c+=1
    end
    c+=1 if attacker.hasWorkingAbility(:SUPERLUCK)
    if attacker.hasWorkingItem(:STICK) &&
       (isConst?(attacker.species,PBSpecies,:FARFETCHD) ||
        isConst?(attacker.species,PBSpecies,:SIRFETCHD))
      c+=2
    end
    if attacker.hasWorkingItem(:LUCKYPUNCH) &&
       isConst?(attacker.species,PBSpecies,:CHANSEY)
      c+=2
    end
    c+=1 if attacker.hasWorkingItem(:RAZORCLAW)
    c+=1 if attacker.hasWorkingItem(:SCOPELENS)
    c=4 if c>4
    return @battle.pbRandom(ratios[c])==0
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg
  end

  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    return damagemult
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    return damagemult
  end

  def pbCalcDamage(attacker,opponent,options=0)
    opponent.damagestate.critical=false
    opponent.damagestate.typemod=0
    opponent.damagestate.calcdamage=0
    opponent.damagestate.hplost=0
    return 0 if @basedamage==0
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]
    if (options&NOTYPE)==0
      type=pbType(@type,attacker,opponent)
    else
      type=-1 # Will be treated as physical
    end
    if (options&NOCRITICAL)==0
      isCrit=pbIsCritical?(attacker,opponent)
      opponent.damagestate.critical=isCrit
      $criticosFarf += 1 if attacker.species==83 && isCrit
    end
    ##### Calcuate base power of move #####
    basedmg=@basedamage # From PBS file
    basedmg=pbBaseDamage(basedmg,attacker,opponent) # Some function codes alter base power
    damagemult=0x1000
    if opponent.hasWorkingAbility(:WATERBUBBLE) && isConst?(type,PBTypes,:FIRE)
        damagemult=(damagemult*0.5).round
    elsif attacker.hasWorkingAbility(:WATERBUBBLE) && isConst?(type,PBTypes,:WATER)
        damagemult=(damagemult*2).round
    end
    if attacker.hasWorkingAbility(:STEELWORKER) && isConst?(type,PBTypes,:STEEL)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:STEELYSPIRIT) && isConst?(type,PBTypes,:STEEL)
      damagemult=(damagemult*1.5).round
    end
    if attacker.pbPartner.hasWorkingAbility(:STEELYSPIRIT) && isConst?(type,PBTypes,:STEEL)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:TRANSISTOR) && isConst?(type,PBTypes,:ELECTRIC)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:DRAGONSMAW) && isConst?(type,PBTypes,:DRAGON)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:ROCKYPAYLOAD) && isConst?(type,PBTypes,:ROCK)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:TECHNICIAN) && basedmg<=60 && @id>0
      damagemult=(damagemult*1.5).round
    end
    if attacker.isTera? && 60>basedmg && !pbIsMultiHit
      basedmg=60
    end
    if attacker.hasWorkingAbility(:IRONFIST) && isPunchingMove?
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingAbility(:PUNCHINGGLOVE) && isPunchingMove?
      damagemult=(damagemult*1.1).round
    end
    if attacker.hasWorkingAbility(:STRONGJAW) && isBitingMove?
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:MEGALAUNCHER) && isPulseMove?
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:RECKLESS) && isRecoilMove?
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingAbility(:SHARPNESS) && isRazorMove?
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:FLAREBOOST) &&
       attacker.status==PBStatuses::BURN && pbIsSpecial?(type)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:TOXICBOOST) &&
       attacker.status==PBStatuses::POISON && pbIsPhysical?(type)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:PUNKROCK) && isSoundBased?
      damagemult=(damagemult*1.3).round
    end
    if attacker.hasWorkingAbility(:ANALYTIC) &&
       (@battle.choices[opponent.index][0]!=1 || # Didn't choose a move
       opponent.hasMovedThisRound?) # Used a move already
      damagemult=(damagemult*1.3).round
    end
    if attacker.hasWorkingAbility(:RIVALRY) &&
       attacker.gender!=2 && opponent.gender!=2
      if attacker.gender==opponent.gender
        damagemult=(damagemult*1.25).round
      else
        damagemult=(damagemult*0.75).round
      end
    end
    if attacker.hasWorkingAbility(:SANDFORCE) &&
       @battle.pbWeather==PBWeather::SANDSTORM &&
       (isConst?(type,PBTypes,:ROCK) ||
       isConst?(type,PBTypes,:GROUND) ||
       isConst?(type,PBTypes,:STEEL))
      damagemult=(damagemult*1.3).round
    end
    if attacker.hasWorkingAbility(:SHEERFORCE) && self.addlEffect>0
      damagemult=(damagemult*1.3).round
    end
    if attacker.hasWorkingAbility(:TOUGHCLAWS) && isContactMove?
      damagemult=(damagemult*1.3).round
    end
    if (attacker.hasWorkingAbility(:AERILATE) ||
       attacker.hasWorkingAbility(:REFRIGERATE) ||
       attacker.hasWorkingAbility(:PIXILATE) ||
       attacker.hasWorkingAbility(:GALVANIZE)) && @powerboost
      damagemult=(damagemult*1.2).round
    end
    if (@battle.pbCheckGlobalAbility(:DARKAURA) && isConst?(type,PBTypes,:DARK)) ||
       (@battle.pbCheckGlobalAbility(:FAIRYAURA) && isConst?(type,PBTypes,:FAIRY))
      if @battle.pbCheckGlobalAbility(:AURABREAK)
        damagemult=(damagemult*2/3).round
      else
        damagemult=(damagemult*4/3).round
      end
    end
    if !attacker.hasMoldBreaker && !doesBypassIgnorableAbilities?
      if opponent.hasWorkingAbility(:HEATPROOF) && isConst?(type,PBTypes,:FIRE)
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:THICKFAT) &&
         (isConst?(type,PBTypes,:ICE) || isConst?(type,PBTypes,:FIRE))
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:PURIFYINGSALT) &&
        isConst?(type,PBTypes,:GHOST)
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:FURCOAT) &&
         (pbIsPhysical?(type) || @function==0x122) # Psyshock
        damagemult=(damagemult*0.5).round
      end
      if @battle.pbCheckGlobalAbility(:VESSELOFRUIN) && !attacker.hasWorkingAbility(:VESSELOFRUIN) && pbIsSpecial?(type)
        damagemult=(damagemult*0.75).round
      end
      if @battle.pbCheckGlobalAbility(:SWORDOFRUIN) && !opponent.hasWorkingAbility(:SWORDOFRUIN) && pbIsPhysical?(type)
        damagemult=(damagemult*1.25).round
      end
      if @battle.pbCheckGlobalAbility(:TABLETSOFRUIN) && !attacker.hasWorkingAbility(:TABLETSOFRUIN) && pbIsPhysical?(type)
        damagemult=(damagemult*0.75).round
      end
      if @battle.pbCheckGlobalAbility(:BEADSOFRUIN) && !opponent.hasWorkingAbility(:BEADSOFRUIN) && pbIsPhysical?(type)
        damagemult=(damagemult*1.25).round
      end
      if opponent.hasWorkingAbility(:PUNKROCK) && isSoundBased?
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:DRYSKIN) && isConst?(type,PBTypes,:FIRE)
        damagemult=(damagemult*1.25).round
      end
    end
    # Gems are the first items to be considered, as Symbiosis can replace a
    # consumed Gem and the replacement item should work immediately.
    if @function!=0x106 && @function!=0x107 && @function!=0x108 # Pledge moves
      if (attacker.hasWorkingItem(:NORMALGEM) && isConst?(type,PBTypes,:NORMAL)) ||
         (attacker.hasWorkingItem(:FIGHTINGGEM) && isConst?(type,PBTypes,:FIGHTING)) ||
         (attacker.hasWorkingItem(:FLYINGGEM) && isConst?(type,PBTypes,:FLYING)) ||
         (attacker.hasWorkingItem(:POISONGEM) && isConst?(type,PBTypes,:POISON)) ||
         (attacker.hasWorkingItem(:GROUNDGEM) && isConst?(type,PBTypes,:GROUND)) ||
         (attacker.hasWorkingItem(:ROCKGEM) && isConst?(type,PBTypes,:ROCK)) ||
         (attacker.hasWorkingItem(:BUGGEM) && isConst?(type,PBTypes,:BUG)) ||
         (attacker.hasWorkingItem(:GHOSTGEM) && isConst?(type,PBTypes,:GHOST)) ||
         (attacker.hasWorkingItem(:STEELGEM) && isConst?(type,PBTypes,:STEEL)) ||
         (attacker.hasWorkingItem(:FIREGEM) && isConst?(type,PBTypes,:FIRE)) ||
         (attacker.hasWorkingItem(:WATERGEM) && isConst?(type,PBTypes,:WATER)) ||
         (attacker.hasWorkingItem(:GRASSGEM) && isConst?(type,PBTypes,:GRASS)) ||
         (attacker.hasWorkingItem(:ELECTRICGEM) && isConst?(type,PBTypes,:ELECTRIC)) ||
         (attacker.hasWorkingItem(:PSYCHICGEM) && isConst?(type,PBTypes,:PSYCHIC)) ||
         (attacker.hasWorkingItem(:ICEGEM) && isConst?(type,PBTypes,:ICE)) ||
         (attacker.hasWorkingItem(:DRAGONGEM) && isConst?(type,PBTypes,:DRAGON)) ||
         (attacker.hasWorkingItem(:DARKGEM) && isConst?(type,PBTypes,:DARK)) ||
         (attacker.hasWorkingItem(:FAIRYGEM) && isConst?(type,PBTypes,:FAIRY))
        damagemult=(USENEWBATTLEMECHANICS) ? (damagemult*1.3).round : (damagemult*1.5).round
        @battle.pbCommonAnimation("UseItem",attacker,nil)
        @battle.pbDisplayBrief(_INTL("¡La {1} aumentó la potencia de {2}!",
           PBItems.getName(attacker.item),@name))
        attacker.pbConsumeItem
      end
    end
    if (attacker.hasWorkingItem(:SILKSCARF) && isConst?(type,PBTypes,:NORMAL)) ||
       (attacker.hasWorkingItem(:BLACKBELT) && isConst?(type,PBTypes,:FIGHTING)) ||
       (attacker.hasWorkingItem(:SHARPBEAK) && isConst?(type,PBTypes,:FLYING)) ||
       (attacker.hasWorkingItem(:POISONBARB) && isConst?(type,PBTypes,:POISON)) ||
       (attacker.hasWorkingItem(:SOFTSAND) && isConst?(type,PBTypes,:GROUND)) ||
       (attacker.hasWorkingItem(:HARDSTONE) && isConst?(type,PBTypes,:ROCK)) ||
       (attacker.hasWorkingItem(:SILVERPOWDER) && isConst?(type,PBTypes,:BUG)) ||
       (attacker.hasWorkingItem(:SPELLTAG) && isConst?(type,PBTypes,:GHOST)) ||
       (attacker.hasWorkingItem(:METALCOAT) && isConst?(type,PBTypes,:STEEL)) ||
       (attacker.hasWorkingItem(:CHARCOAL) && isConst?(type,PBTypes,:FIRE)) ||
       (attacker.hasWorkingItem(:MYSTICWATER) && isConst?(type,PBTypes,:WATER)) ||
       (attacker.hasWorkingItem(:MIRACLESEED) && isConst?(type,PBTypes,:GRASS)) ||
       (attacker.hasWorkingItem(:MAGNET) && isConst?(type,PBTypes,:ELECTRIC)) ||
       (attacker.hasWorkingItem(:TWISTEDSPOON) && isConst?(type,PBTypes,:PSYCHIC)) ||
       (attacker.hasWorkingItem(:NEVERMELTICE) && isConst?(type,PBTypes,:ICE)) ||
       (attacker.hasWorkingItem(:DRAGONFANG) && isConst?(type,PBTypes,:DRAGON)) ||
       (attacker.hasWorkingItem(:BLACKGLASSES) && isConst?(type,PBTypes,:DARK)) ||
       (attacker.hasWorkingItem(:FAIRYFEATHER) && isConst?(type,PBTypes,:FAIRY))
      damagemult=(damagemult*1.2).round
    end
    if (attacker.hasWorkingItem(:FISTPLATE) && isConst?(type,PBTypes,:FIGHTING)) ||
       (attacker.hasWorkingItem(:SKYPLATE) && isConst?(type,PBTypes,:FLYING)) ||
       (attacker.hasWorkingItem(:TOXICPLATE) && isConst?(type,PBTypes,:POISON)) ||
       (attacker.hasWorkingItem(:EARTHPLATE) && isConst?(type,PBTypes,:GROUND)) ||
       (attacker.hasWorkingItem(:STONEPLATE) && isConst?(type,PBTypes,:ROCK)) ||
       (attacker.hasWorkingItem(:INSECTPLATE) && isConst?(type,PBTypes,:BUG)) ||
       (attacker.hasWorkingItem(:SPOOKYPLATE) && isConst?(type,PBTypes,:GHOST)) ||
       (attacker.hasWorkingItem(:IRONPLATE) && isConst?(type,PBTypes,:STEEL)) ||
       (attacker.hasWorkingItem(:FLAMEPLATE) && isConst?(type,PBTypes,:FIRE)) ||
       (attacker.hasWorkingItem(:SPLASHPLATE) && isConst?(type,PBTypes,:WATER)) ||
       (attacker.hasWorkingItem(:MEADOWPLATE) && isConst?(type,PBTypes,:GRASS)) ||
       (attacker.hasWorkingItem(:ZAPPLATE) && isConst?(type,PBTypes,:ELECTRIC)) ||
       (attacker.hasWorkingItem(:MINDPLATE) && isConst?(type,PBTypes,:PSYCHIC)) ||
       (attacker.hasWorkingItem(:ICICLEPLATE) && isConst?(type,PBTypes,:ICE)) ||
       (attacker.hasWorkingItem(:DRACOPLATE) && isConst?(type,PBTypes,:DRAGON)) ||
       (attacker.hasWorkingItem(:DREADPLATE) && isConst?(type,PBTypes,:DARK)) ||
       (attacker.hasWorkingItem(:PIXIEPLATE) && isConst?(type,PBTypes,:FAIRY))
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:ROCKINCENSE) && isConst?(type,PBTypes,:ROCK)
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:ROSEINCENSE) && isConst?(type,PBTypes,:GRASS)
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:SEAINCENSE) && isConst?(type,PBTypes,:WATER)
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:WAVEINCENSE) && isConst?(type,PBTypes,:WATER)
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:ODDINCENSE) && isConst?(type,PBTypes,:PSYCHIC)
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:MUSCLEBAND) && pbIsPhysical?(type)
      damagemult=(damagemult*1.1).round
    end
    if attacker.hasWorkingItem(:WISEGLASSES) && pbIsSpecial?(type)
      damagemult=(damagemult*1.1).round
    end
    if attacker.hasWorkingItem(:LUSTROUSORB) &&
       isConst?(attacker.species,PBSpecies,:PALKIA) &&
       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:WATER))
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:ADAMANTORB) &&
       isConst?(attacker.species,PBSpecies,:DIALGA) &&
       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:STEEL))
      damagemult=(damagemult*1.2).round
    end
    if attacker.hasWorkingItem(:GRISEOUSORB) &&
       isConst?(attacker.species,PBSpecies,:GIRATINA) &&
       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:GHOST))
      damagemult=(damagemult*1.2).round
    end
    damagemult=pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if attacker.effects[PBEffects::MeFirst]
      damagemult=(damagemult*1.5).round
    end
    if attacker.effects[PBEffects::HelpingHand] && (options&SELFCONFUSE)==0
      damagemult=(damagemult*1.5).round
    end
    if attacker.effects[PBEffects::Charge]>0 && isConst?(type,PBTypes,:ELECTRIC)
      damagemult=(damagemult*2.0).round
    end
    if isConst?(type,PBTypes,:FIRE)
      for i in 0...4
        if @battle.battlers[i].effects[PBEffects::WaterSport] && !@battle.battlers[i].isFainted?
          damagemult=(damagemult*0.33).round
          break
        end
      end
      if @battle.field.effects[PBEffects::WaterSportField]>0
        damagemult=(damagemult*0.33).round
      end
    end
    if isConst?(type,PBTypes,:ELECTRIC)
      for i in 0...4
        if @battle.battlers[i].effects[PBEffects::MudSport] && !@battle.battlers[i].isFainted?
          damagemult=(damagemult*0.33).round
          break
        end
      end
      if @battle.field.effects[PBEffects::MudSportField]>0
        damagemult=(damagemult*0.33).round
      end
    end
    if @battle.field.effects[PBEffects::ElectricTerrain]>0 &&
       !attacker.isAirborne?(attacker.hasMoldBreaker ||
       doesBypassIgnorableAbilities?)
      damagemult=(damagemult*1.3).round if isConst?(type,PBTypes,:ELECTRIC)
      damagemult=(damagemult*1.33).round if attacker.hasWorkingAbility(:HADRONENGINE) && pbIsSpecial?(type)
    end

    if @battle.field.effects[PBEffects::GrassyTerrain]>0 &&
       !attacker.isAirborne?(attacker.hasMoldBreaker ||
       doesBypassIgnorableAbilities?) && isConst?(type,PBTypes,:GRASS)
      damagemult=(damagemult*1.3).round
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0 &&
       !opponent.isAirborne?(attacker.hasMoldBreaker||
       doesBypassIgnorableAbilities?) && isConst?(type,PBTypes,:DRAGON)
      damagemult=(damagemult*0.3).round
    end
    if @battle.field.effects[PBEffects::PsychicTerrain]>0 &&
       !attacker.isAirborne?(attacker.hasMoldBreaker||
       doesBypassIgnorableAbilities?) && isConst?(type,PBTypes,:PSYCHIC)
      damagemult=(damagemult*1.3).round
    end
    if opponent.effects[PBEffects::Minimize] && tramplesMinimize?(2)
      damagemult=(damagemult*2.0).round
    end
    basedmg=(basedmg*damagemult*1.0/0x1000).round
    ##### Calculate attacker's attack stat #####
    atk=attacker.attack
    atkstage=attacker.stages[PBStats::ATTACK]+6
    if @function==0x121 # Foul Play
      atk=opponent.attack
      atkstage=opponent.stages[PBStats::ATTACK]+6
    end
    if type>=0 && pbIsSpecial?(type)
      atk=attacker.spatk
      atkstage=attacker.stages[PBStats::SPATK]+6
      if @function==0x121 # Foul Play
        atk=opponent.spatk
        atkstage=opponent.stages[PBStats::SPATK]+6
      end
    end
    if @function==0x175 # Body Press
      atk=attacker.defense
      atkstage=attacker.stages[PBStats::DEFENSE]+6
    end
    if attacker.hasMoldBreaker || !opponent.hasWorkingAbility(:UNAWARE) ||
      doesBypassIgnorableAbilities?
      atkstage=6 if opponent.damagestate.critical && atkstage<6
      atk=(atk*1.0*stagemul[atkstage]/stagediv[atkstage]).floor
    end
    if attacker.hasWorkingAbility(:HUSTLE) && pbIsPhysical?(type)
      atk=(atk*1.5).round
    end
    atkmult=0x1000
    if @battle.internalbattle
      if @battle.pbOwnedByPlayer?(attacker.index) && pbIsPhysical?(type) &&
         @battle.pbPlayer.numbadges>=BADGESBOOSTATTACK
        atkmult=(atkmult*1.1).round
      end
      if @battle.pbOwnedByPlayer?(attacker.index) && pbIsSpecial?(type) &&
         @battle.pbPlayer.numbadges>=BADGESBOOSTSPATK
        atkmult=(atkmult*1.1).round
      end
    end
    if attacker.hp<=(attacker.totalhp/3).floor
      if (attacker.hasWorkingAbility(:OVERGROW) && isConst?(type,PBTypes,:GRASS)) ||
         (attacker.hasWorkingAbility(:BLAZE) && isConst?(type,PBTypes,:FIRE)) ||
         (attacker.hasWorkingAbility(:TORRENT) && isConst?(type,PBTypes,:WATER)) ||
         (attacker.hasWorkingAbility(:SWARM) && isConst?(type,PBTypes,:BUG))
        atkmult=(atkmult*1.5).round
      end
    end
    if attacker.hasWorkingAbility(:GUTS) &&
       attacker.status!=0 && pbIsPhysical?(type)
      atkmult=(atkmult*1.5).round
    end
    if (attacker.hasWorkingAbility(:PLUS) || attacker.hasWorkingAbility(:MINUS)) &&
       pbIsSpecial?(type)
      partner=attacker.pbPartner
      if partner.hasWorkingAbility(:PLUS) || partner.hasWorkingAbility(:MINUS)
        atkmult=(atkmult*1.5).round
      end
    end
    if attacker.pbPartner.hasWorkingAbility(:BATTERY) && pbIsSpecial?(type)
        atkmult=(atkmult*1.5).round
    end
    if attacker.hasWorkingAbility(:DEFEATIST) &&
       attacker.hp<=(attacker.totalhp/2).floor
      atkmult=(atkmult*0.5).round
    end
    if (attacker.hasWorkingAbility(:PUREPOWER) ||
       attacker.hasWorkingAbility(:HUGEPOWER)) && pbIsPhysical?(type)
      atkmult=(atkmult*2.0).round
    end
    if attacker.hasWorkingAbility(:SUPREMEOVERLORD)
      party=@battle.pbParty(attacker.index)
      if party.select{|p|p.hp==0}.length==5
        atkmult=(atkmult*1.5).round
      elsif party.select{|p|p.hp==0}.length==4
        atkmult=(atkmult*1.4).round
      elsif party.select{|p|p.hp==0}.length==3
        atkmult=(atkmult*1.3).round
      elsif party.select{|p|p.hp==0}.length==2
        atkmult=(atkmult*1.2).round
      elsif party.select{|p|p.hp==0}.length==1
        atkmult=(atkmult*1.1).round
      end
    end
    if attacker.hasWorkingAbility(:SOLARPOWER) && pbIsSpecial?(type) &&
       (@battle.pbWeather==PBWeather::SUNNYDAY && !attacker.hasWorkingItem(:UTILITYUMBRELLA) ||
       @battle.pbWeather==PBWeather::HARSHSUN && !attacker.hasWorkingItem(:UTILITYUMBRELLA))
      atkmult=(atkmult*1.5).round
    end
    if attacker.hasWorkingAbility(:FLASHFIRE) &&
       attacker.effects[PBEffects::FlashFire] && isConst?(type,PBTypes,:FIRE)
      atkmult=(atkmult*1.5).round
    end
    if attacker.hasWorkingAbility(:SLOWSTART) &&
       attacker.turncount<=5 && pbIsPhysical?(type)
      atkmult=(atkmult*0.5).round
    end
    if (@battle.pbWeather==PBWeather::SUNNYDAY ||
       @battle.pbWeather==PBWeather::HARSHSUN) && pbIsPhysical?(type)
      if attacker.hasWorkingAbility(:FLOWERGIFT) && !attacker.hasWorkingItem(:UTILITYUMBRELLA) ||
         attacker.pbPartner.hasWorkingAbility(:FLOWERGIFT) && !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        atkmult=(atkmult*1.5).round
      end
    end
    if attacker.pbPartner.hasWorkingAbility(:POWERSPOT)
      atkmult=(atkmult*1.3).round
    end
    if attacker.hasWorkingAbility(:GORILLATACTICS) && pbIsPhysical?(type)
      atkmult=(atkmult*1.5).round
    end
    if attacker.hasWorkingItem(:THICKCLUB) &&
       (isConst?(attacker.species,PBSpecies,:CUBONE) ||
       isConst?(attacker.species,PBSpecies,:MAROWAK)) && pbIsPhysical?(type)
      atkmult=(atkmult*2.0).round
    end
    if attacker.hasWorkingItem(:DEEPSEATOOTH) &&
       isConst?(attacker.species,PBSpecies,:CLAMPERL) && pbIsSpecial?(type)
      atkmult=(atkmult*2.0).round
    end
    if attacker.hasWorkingItem(:LIGHTBALL) &&
       isConst?(attacker.species,PBSpecies,:PIKACHU)
      atkmult=(atkmult*2.0).round
    end
    if attacker.hasWorkingItem(:SOULDEW) &&
       (isConst?(attacker.species,PBSpecies,:LATIAS) ||
       isConst?(attacker.species,PBSpecies,:LATIOS)) && pbIsSpecial?(type) &&
       !@battle.rules["souldewclause"]
      atkmult=(atkmult*1.5).round
    end
    if attacker.hasWorkingItem(:CHOICEBAND) && pbIsPhysical?(type)
      atkmult=(atkmult*1.5).round
    end
    if attacker.hasWorkingItem(:CHOICESPECS) && pbIsSpecial?(type)
      atkmult=(atkmult*1.5).round
    end
    atk=(atk*atkmult*1.0/0x1000).round
    ##### Calculate opponent's defense stat #####
    defense=opponent.defense
    defstage=opponent.stages[PBStats::DEFENSE]+6
    # TODO: Wonder Room should apply around here
    applysandstorm=false
    applysnow=false
    if type>=0 && pbIsSpecial?(type) && @function!=0x122 # Psyshock
      defense=opponent.spdef
      defstage=opponent.stages[PBStats::SPDEF]+6
      applysandstorm=true
    end
    if type>=0 && pbIsPhysical?(type)
      defense2=opponent.spdef
      defstage2=opponent.stages[PBStats::DEFENSE]+6
      applysnow=true
    end
    if !attacker.hasWorkingAbility(:UNAWARE)
      defstage=6 if @function==0xA9 # Chip Away (ignore stat stages)
      #defstage2=6 if @function==0xA9 # Chip Away (ignore stat stages)
      defstage=6 if opponent.damagestate.critical && defstage>6
      #defstage2=6 if opponent.damagestate.critical && defstage2>6
      defense=(defense*1.0*stagemul[defstage]/stagediv[defstage]).floor
      #defense2=(defense2*1.0*stagemul[defstage2]/stagediv[defstage2]).floor
    end
    if @battle.pbWeather==PBWeather::SANDSTORM &&
       opponent.pbHasType?(:ROCK) && applysandstorm
      defense=(defense*1.5).round
    end
    if SNOW_REPLACES_HAIL
      if @battle.pbWeather==PBWeather::HAIL &&
         opponent.pbHasType?(:ICE) && applysnow
        defense2=(defense2*1.5).round
      end
    end
    defmult=0x1000
    if @battle.internalbattle
      if @battle.pbOwnedByPlayer?(opponent.index) && pbIsPhysical?(type) &&
         @battle.pbPlayer.numbadges>=BADGESBOOSTDEFENSE
        defmult=(defmult*1.1).round
      end
      if @battle.pbOwnedByPlayer?(opponent.index) && pbIsSpecial?(type) &&
         @battle.pbPlayer.numbadges>=BADGESBOOSTSPDEF
        defmult=(defmult*1.1).round
      end
    end
    if !attacker.hasMoldBreaker && !doesBypassIgnorableAbilities?
      if opponent.hasWorkingAbility(:MARVELSCALE) &&
         opponent.status>0 && pbIsPhysical?(type)
        defmult=(defmult*1.5).round
      end
      if opponent.hasWorkingAbility(:GRASSPELT) &&
       @battle.field.effects[PBEffects::GrassyTerrain]>0 &&
       pbIsPhysical?(type)
        defmult=(defmult*1.5).round
      end
      if (@battle.pbWeather==PBWeather::SUNNYDAY ||
          @battle.pbWeather==PBWeather::HARSHSUN) && pbIsSpecial?(type)
        if  opponent.hasWorkingAbility(:FLOWERGIFT) && !opponent.hasWorkingItem(:UTILITYUMBRELLA) ||
            opponent.pbPartner.hasWorkingAbility(:FLOWERGIFT) && !opponent.hasWorkingItem(:UTILITYUMBRELLA)
          defmult=(defmult*1.5).round
        end
      end
      if opponent.hasWorkingAbility(:ICESCALES) && pbIsSpecial?(type)
        defmult=(defmult*1.5).round
      end
    end
    if opponent.hasWorkingItem(:ASSAULTVEST) && pbIsSpecial?(type)
      defmult=(defmult*1.5).round
    end
    if opponent.hasWorkingItem(:EVIOLITE)
      evos=pbGetEvolvedFormData(opponent.species)
      if evos && evos.length>0
        defmult=(defmult*1.5).round
      end
    end
    if opponent.hasWorkingItem(:DEEPSEASCALE) &&
       isConst?(opponent.species,PBSpecies,:CLAMPERL) && pbIsSpecial?(type)
      defmult=(defmult*2.0).round
    end
    if opponent.hasWorkingItem(:METALPOWDER) &&
       isConst?(opponent.species,PBSpecies,:DITTO) &&
       !opponent.effects[PBEffects::Transform]
      defmult=(defmult*1.5).round
    end
    if opponent.hasWorkingItem(:SOULDEW) &&
       (isConst?(opponent.species,PBSpecies,:LATIAS) ||
       isConst?(opponent.species,PBSpecies,:LATIOS)) && pbIsSpecial?(type) &&
       !@battle.rules["souldewclause"]
      defmult=(defmult*1.5).round
    end
    defense=(defense*defmult*1.0/0x1000).round
    ##### Main damage calculation #####
    damage=(((2.0*attacker.level/5+2).floor*basedmg*atk/defense).floor/50).floor+2
    # Multi-targeting attacks
    if pbTargetsMultiple?(attacker)
      damage=(damage*0.75).round
    end
    # Weather
    case @battle.pbWeather
    when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
      if !opponent.hasWorkingItem(:UTILITYUMBRELLA) || !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        if isConst?(type,PBTypes,:FIRE)
          damage=(damage*1.5).round
        elsif isConst?(type,PBTypes,:WATER)
          damage=(damage*0.5).round
        end
      end
      damage=(damage*1.33).round if attacker.hasWorkingAbility(:ORICHALCUMPULSE) && pbIsPhysical?(type)
    when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
      if !opponent.hasWorkingItem(:UTILITYUMBRELLA) || !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        if isConst?(type,PBTypes,:FIRE)
          damage=(damage*0.5).round
        elsif isConst?(type,PBTypes,:WATER)
          damage=(damage*1.5).round
        end
      end
    end
    # Critical hits
    if opponent.damagestate.critical
      damage=(USENEWBATTLEMECHANICS) ? (damage*1.5).round : (damage*2.0).round
    end
    # Random variance
    if (options&NOWEIGHTING)==0
      random=85+@battle.pbRandom(16)
      damage=(damage*random/100.0).floor
    end
    # STAB
    if attacker.isTera?
      dexdata1=pbOpenDexData
      pbDexDataOffset(dexdata1,attacker.species,8)
      ret1=dexdata1.fgetb
      dexdata1.close
      dexdata2=pbOpenDexData
      pbDexDataOffset(dexdata2,attacker.species,9)
      ret2=dexdata2.fgetb
      dexdata2.close
      if attacker.type1==PBTypes::STELLAR
        if (ret1==type || ret2==type) && attacker.astral_stab[0]
          damage*=2
          attacker.astral_stab[0]=false
        else
          damage=(damage*1.2).round
        end
      else
        if attacker.pbHasType?(type) && (ret1==type || ret2==type)
          if attacker.hasWorkingAbility(:ADAPTABILITY)
            damage=(damage*2.25).round
          else
            damage=(damage*2).round
          end
        elsif attacker.pbHasType?(type) || (ret1==type || ret2==type)
          if attacker.hasWorkingAbility(:ADAPTABILITY)
            damage=(damage*2).round
          else
            damage=(damage*1.5).round
          end
        end
      end
    elsif attacker.pbHasType?(type)
      if attacker.hasWorkingAbility(:ADAPTABILITY)
        damage=(damage*2).round
      else
        damage=(damage*1.5).round
      end
    end
    # Type effectiveness
    if (options&IGNOREPKMNTYPES)==0
      typemod=pbTypeModMessages(type,attacker,opponent)
      damage=(damage*typemod/8.0).round
      opponent.damagestate.typemod=typemod
      if typemod==0
        opponent.damagestate.calcdamage=0
        opponent.damagestate.critical=false
        return 0
      end
    else
      opponent.damagestate.typemod=8
    end
    # Burn
    if attacker.status==PBStatuses::BURN && pbIsPhysical?(type) &&
       !attacker.hasWorkingAbility(:GUTS) &&
       !(USENEWBATTLEMECHANICS && @function==0x7E) # Facade
      damage=(damage*0.5).round
    end
    # BES-T Frostbite
    if FROSTBITE_REPLACES_FREEZE
      if attacker.status==PBStatuses::FROZEN && pbIsSpecial?(type) &&
         !attacker.hasWorkingAbility(:GUTS) &&
         !(USENEWBATTLEMECHANICS && @function==0x7E) # Facade
        damage=(damage*0.5).round
      end
    end
    # Make sure damage is at least 1
    damage=1 if damage<1
    # Final damage modifiers
    finaldamagemult=0x1000
    if !opponent.damagestate.critical && (options&NOREFLECT)==0 &&
       !attacker.hasWorkingAbility(:INFILTRATOR)
      # Reflect
      if opponent.pbOwnSide.effects[PBEffects::Reflect]>0 && pbIsPhysical?(type)
        if @battle.doublebattle
          finaldamagemult=(finaldamagemult*0.66).round
        else
          finaldamagemult=(finaldamagemult*0.5).round
        end
      end
      # Light Screen
      if opponent.pbOwnSide.effects[PBEffects::LightScreen]>0 && pbIsSpecial?(type)
        if @battle.doublebattle
          finaldamagemult=(finaldamagemult*0.66).round
        else
          finaldamagemult=(finaldamagemult*0.5).round
        end
      end
      # Aurora Veil
      if opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0 && pbIsPhysical?(type)
        if @battle.doublebattle
          finaldamagemult=(finaldamagemult*0.66).round
        else
          finaldamagemult=(finaldamagemult*0.5).round
        end
      end
      if opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0 && pbIsSpecial?(type)
        if @battle.doublebattle
          finaldamagemult=(finaldamagemult*0.66).round
        else
          finaldamagemult=(finaldamagemult*0.5).round
        end
      end
    end
    if attacker.effects[PBEffects::ParentalBond]==1
      finaldamagemult=(finaldamagemult*0.5).round
    end
    if attacker.hasWorkingAbility(:TINTEDLENS) && opponent.damagestate.typemod<8
      finaldamagemult=(finaldamagemult*2.0).round
    end
    if attacker.hasWorkingAbility(:SNIPER) && opponent.damagestate.critical
      finaldamagemult=(finaldamagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:STAKEOUT) && opponent.effects[PBEffects::Stakeout]
      finaldamagemult=(finaldamagemult*2.0).round
    end
    if attacker.hasWorkingAbility(:NEUROFORCE) && opponent.damagestate.typemod>8
      finaldamagemult=(finaldamagemult*1.25).round
    end

    if @function==0x267 && opponent.damagestate.typemod>8
      finaldamagemult=(finaldamagemult*1.33).round
    end

    if opponent.hasWorkingAbility(:PRISMARMOR) && opponent.damagestate.typemod>8
      finaldamagemult=(finaldamagemult*0.75).round
    end
    if opponent.hasWorkingAbility(:SHADOWSHIELD) && opponent.hp==opponent.totalhp
      finaldamagemult=(finaldamagemult*0.5).round
    end
    if !attacker.hasMoldBreaker && !doesBypassIgnorableAbilities?
      if opponent.hasWorkingAbility(:WATERBUBBLE) && isConst?(type,PBTypes,:FIRE)
        finaldamagemult=(finaldamagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:MULTISCALE) && opponent.hp==opponent.totalhp
        finaldamagemult=(finaldamagemult*0.5).round
      end
      if (opponent.hasWorkingAbility(:SOLIDROCK) ||
         opponent.hasWorkingAbility(:FILTER)) &&
         opponent.damagestate.typemod>8
        finaldamagemult=(finaldamagemult*0.75).round
      end
      if opponent.pbPartner.hasWorkingAbility(:FRIENDGUARD)
        finaldamagemult=(finaldamagemult*0.75).round
      end
    end
    if opponent.hasWorkingAbility(:FLUFFY) && isConst?(type,PBTypes,:FIRE)
      if !isContactMove?
        finaldamagemult=(finaldamagemult*2.0).round
      end
      elsif opponent.hasWorkingAbility(:FLUFFY) && attacker.hasWorkingAbility(:LONGREACH) && isContactMove?
        finaldamagemult=(finaldamagemult*1.0).round
      elsif opponent.hasWorkingAbility(:FLUFFY) && isContactMove?
        finaldamagemult=(finaldamagemult*0.5).round
    end
    if attacker.hasWorkingItem(:METRONOME)
      met=1+0.2*[attacker.effects[PBEffects::Metronome],5].min
      finaldamagemult=(finaldamagemult*met).round
    end
    if attacker.hasWorkingItem(:EXPERTBELT) &&
       opponent.damagestate.typemod>8
      finaldamagemult=(finaldamagemult*1.2).round
    end
    if attacker.hasWorkingItem(:LIFEORB) && (options&SELFCONFUSE)==0
      attacker.effects[PBEffects::LifeOrb]=true
      finaldamagemult=(finaldamagemult*1.3).round
    end
    if opponent.damagestate.typemod>8 && (options&IGNOREPKMNTYPES)==0
      if (opponent.hasWorkingItem(:CHOPLEBERRY) && isConst?(type,PBTypes,:FIGHTING)) ||
         (opponent.hasWorkingItem(:COBABERRY) && isConst?(type,PBTypes,:FLYING)) ||
         (opponent.hasWorkingItem(:KEBIABERRY) && isConst?(type,PBTypes,:POISON)) ||
         (opponent.hasWorkingItem(:SHUCABERRY) && isConst?(type,PBTypes,:GROUND)) ||
         (opponent.hasWorkingItem(:CHARTIBERRY) && isConst?(type,PBTypes,:ROCK)) ||
         (opponent.hasWorkingItem(:TANGABERRY) && isConst?(type,PBTypes,:BUG)) ||
         (opponent.hasWorkingItem(:KASIBBERRY) && isConst?(type,PBTypes,:GHOST)) ||
         (opponent.hasWorkingItem(:BABIRIBERRY) && isConst?(type,PBTypes,:STEEL)) ||
         (opponent.hasWorkingItem(:OCCABERRY) && isConst?(type,PBTypes,:FIRE)) ||
         (opponent.hasWorkingItem(:PASSHOBERRY) && isConst?(type,PBTypes,:WATER)) ||
         (opponent.hasWorkingItem(:RINDOBERRY) && isConst?(type,PBTypes,:GRASS)) ||
         (opponent.hasWorkingItem(:WACANBERRY) && isConst?(type,PBTypes,:ELECTRIC)) ||
         (opponent.hasWorkingItem(:PAYAPABERRY) && isConst?(type,PBTypes,:PSYCHIC)) ||
         (opponent.hasWorkingItem(:YACHEBERRY) && isConst?(type,PBTypes,:ICE)) ||
         (opponent.hasWorkingItem(:HABANBERRY) && isConst?(type,PBTypes,:DRAGON)) ||
         (opponent.hasWorkingItem(:COLBURBERRY) && isConst?(type,PBTypes,:DARK)) ||
         (opponent.hasWorkingItem(:ROSELIBERRY) && isConst?(type,PBTypes,:FAIRY))
        finaldamagemult=(finaldamagemult*0.5).round
        opponent.damagestate.berryweakened=true
        @battle.pbCommonAnimation("UseItem",opponent,nil)
      end
    end
    if opponent.hasWorkingItem(:CHILANBERRY) && isConst?(type,PBTypes,:NORMAL) &&
       (options&IGNOREPKMNTYPES)==0
      finaldamagemult=(finaldamagemult*0.5).round
      opponent.damagestate.berryweakened=true
      @battle.pbCommonAnimation("UseItem",opponent,nil)
    end
    finaldamagemult=pbModifyDamage(finaldamagemult,attacker,opponent)
    damage=(damage*finaldamagemult*1.0/0x1000).round
    opponent.damagestate.calcdamage=damage
    PBDebug.log("Move's damage calculated to be #{damage}")
    return damage
  end

  def pbReduceHPDamage(damage,attacker,opponent)
    endure=false
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker) &&     # Sustituto
       (!attacker || attacker.index!=opponent.index)
      PBDebug.log("[Efecto prolongado disparado] Sustituto de #{opponent.pbThis} recibió el daño")
      damage=opponent.effects[PBEffects::Substitute] if damage>opponent.effects[PBEffects::Substitute]
      opponent.effects[PBEffects::Substitute]-=damage
      opponent.damagestate.substitute=true
      @battle.scene.pbDamageAnimation(opponent,0)
      @battle.pbDisplayPaused(_INTL("¡El sustituto recibe el daño en lugar de {1}!",opponent.name))
      if opponent.effects[PBEffects::Substitute]<=0
        opponent.effects[PBEffects::Substitute]=0
        @battle.pbDisplayPaused(_INTL("¡El sustituto de {1} se acabó!",opponent.name))
        PBDebug.log("[Efecto terminado] Sustituto de #{opponent.pbThis} terminado")
      end
      opponent.damagestate.hplost=damage
      damage=0
    elsif isConst?(opponent.species,PBSpecies,:EISCUE) && opponent.hasWorkingAbility(:ICEFACE) &&
          opponent.form!=1 && pbIsPhysical?(type) && !attacker.hasMoldBreaker
      opponent.form=1; opponent.pbUpdate(true)
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("¡{1} cambió de forma!",opponent.name))
      PBDebug.log("[Form changed] #{opponent.pbThis} changed to form #{opponent.form}")
      opponent.damagestate.hplost=damage
      damage=0
    else
      opponent.damagestate.substitute=false
      if opponent.hasWorkingAbility(:DISGUISE) &&
         !attacker.hasMoldBreaker && opponent.form==0 && damage>0 &&
         isConst?(opponent.species,PBSpecies,:MIMIKYU) && !doesBypassIgnorableAbilities?
        damage=0
      end
      # Tera Shell
        if opponent.hasWorkingAbility(:TERASHELL) && opponent.hp==opponent.totalhp &&
          !attacker.hasMoldBreaker && damage>0 && !doesBypassIgnorableAbilities?
          opponent.damagestate.typemod=6
          @battle.pbDisplay(_INTL("¡La habilidad hizo poco eficaz este movimiento!"))
        end
      # Glaive Rush
      if damage>0 && opponent.effects[PBEffects::GlaiveRush]
        damage*=2
        @battle.pbDisplay(_INTL("¡La potencia del ataque se ha duplicado!"))
        opponent.effects[PBEffects::GlaiveRush]=false
      end
      if damage>=opponent.hp
        damage=opponent.hp
        if @function==0xE9 # False Swipe
          damage=damage-1
        elsif opponent.effects[PBEffects::Endure]                                        # Aguante
          damage=damage-1
          opponent.damagestate.endured=true
          PBDebug.log("[Efecto prolongado disparado] Aguante de #{opponent.pbThis}")
        elsif damage==opponent.totalhp
          if opponent.hasWorkingAbility(:STURDY) && !attacker.hasMoldBreaker &&
            !doesBypassIgnorableAbilities?                                               # Robustez
            opponent.damagestate.sturdy=true
            damage=damage-1
            PBDebug.log("[Habilidad disparada] Robustez de #{opponent.pbThis}")
          elsif opponent.hasWorkingItem(:FOCUSSASH) && opponent.hp==opponent.totalhp     # Banda Focus
            opponent.damagestate.focussash=true
            damage=damage-1
            PBDebug.log("[Objeto disparado] Banda Focus de #{opponent.pbThis}")
          elsif opponent.hasWorkingItem(:FOCUSBAND) && @battle.pbRandom(10)==0           # Cinta Focus
            opponent.damagestate.focusband=true
            damage=damage-1
            PBDebug.log("[Objeto disparado] Cinta Focus de #{opponent.pbThis}")
          end
        end
        damage=0 if damage<0
      end
      oldhp=opponent.hp
      opponent.hp-=damage
      effectiveness=0
      if opponent.damagestate.typemod<8
        effectiveness=1   # "Not very effective"
      elsif opponent.damagestate.typemod>8
        effectiveness=2   # "Super effective"
      end
      if opponent.damagestate.typemod!=0
        @battle.scene.pbDamageAnimation(opponent,effectiveness)
      end
      @battle.scene.pbHPChanged(opponent,oldhp)
      opponent.damagestate.hplost=damage
    end
    return damage
  end

################################################################################
# Effects     /    Efectos
################################################################################
  def pbEffectMessages(attacker,opponent,ignoretype=false,alltargets=nil)
    if opponent.damagestate.critical
      if alltargets && alltargets.length>1
        @battle.pbDisplay(_INTL("¡Es un golpe crítico en {1}!",opponent.pbThis(true)))
      else
        @battle.pbDisplay(_INTL("¡Es un golpe crítico!"))
      end
    end
    if !pbIsMultiHit && attacker.effects[PBEffects::ParentalBond]==0
      if opponent.damagestate.typemod>8
        if alltargets && alltargets.length>1
          @battle.pbDisplay(_INTL("¡Es super efectivo en {1}!",opponent.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("¡Es super efectivo!"))
        end
      elsif opponent.damagestate.typemod>=1 && opponent.damagestate.typemod<8
        if alltargets && alltargets.length>1
          @battle.pbDisplay(_INTL("No es muy efectivo en {1}...",opponent.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("No es muy efectivo..."))
        end
      end
    end
    if opponent.damagestate.endured
      @battle.pbDisplay(_INTL("¡{1} aguantó el golpe!",opponent.pbThis))
    elsif opponent.damagestate.sturdy
      @battle.pbDisplay(_INTL("¡{1} resistió con Robustez!",opponent.pbThis))
    elsif opponent.damagestate.focussash
      @battle.pbDisplay(_INTL("¡{1} resistió usando Banda Focus!",opponent.pbThis))
      opponent.pbConsumeItem
    elsif opponent.damagestate.focusband
      @battle.pbDisplay(_INTL("¡{1} resistió usando Cinta Focus!",opponent.pbThis))
    end
  end

  def pbEffectFixedDamage(damage,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    type=pbType(@type,attacker,opponent)
    typemod=pbTypeModMessages(type,attacker,opponent)
    opponent.damagestate.critical=false
    opponent.damagestate.typemod=0
    opponent.damagestate.calcdamage=0
    opponent.damagestate.hplost=0
    if typemod!=0
      opponent.damagestate.calcdamage=damage
      opponent.damagestate.typemod=8
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      damage=1 if damage<1 # HP reduced can't be less than 1
      damage=pbReduceHPDamage(damage,attacker,opponent)
      pbEffectMessages(attacker,opponent,alltargets)
      pbOnDamageLost(damage,attacker,opponent)
      return damage
    end
    return 0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return 0 if !opponent
    damage=pbCalcDamage(attacker,opponent)
    if opponent.damagestate.typemod!=0
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    end
    damage=pbReduceHPDamage(damage,attacker,opponent)
    pbEffectMessages(attacker,opponent)
    pbOnDamageLost(damage,attacker,opponent)
    return damage   # The HP lost by the opponent due to this attack
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
  end

################################################################################
# Uso del movimiento
################################################################################
  def pbOnStartUse(attacker)
    return true
  end

  def pbAddTarget(targets,attacker)
  end

  def pbDisplayUseMessage(attacker)
  # Valores de retorno:
  # -1 si el ataque debería terminar como fallo
  # 0 si el ataque debería proceder con su efecto
  # 1 si el ataque debería terminar con éxito
  # 2 if Bide is storing energy
    @battle.pbDisplayBrief(_INTL("¡{1} ha usado\r\n{2}!",attacker.pbThis,name))
    return 0
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    if attacker.effects[PBEffects::ParentalBond]==1
      @battle.pbCommonAnimation("ParentalBond",attacker,opponent)
      return
    end
    @battle.pbAnimation(id,attacker,opponent,hitnum)
  end

  def pbOnDamageLost(damage,attacker,opponent)
    # Usado por Counter/Mirror Coat/Revenge/Focus Punch/Bide
    type=@type
    type=pbType(type,attacker,opponent)
    if opponent.effects[PBEffects::Bide]>0
      opponent.effects[PBEffects::BideDamage]+=damage
      opponent.effects[PBEffects::BideTarget]=attacker.index
    end
    if @function==0x90 # Hidden Power
      type=getConst(PBTypes,:NORMAL) || 0
    end
    if pbIsPhysical?(type) && !attacker.hasWorkingAbility(:LONGREACH)
      opponent.effects[PBEffects::Counter]=damage
      opponent.effects[PBEffects::CounterTarget]=attacker.index
    elsif pbIsSpecial?(type)
      opponent.effects[PBEffects::MirrorCoat]=damage
      opponent.effects[PBEffects::MirrorCoatTarget]=attacker.index
    end
    #berries -- moved here by Adrenst
#    for j in 0...4
#      @battle.battlers[j].pbBerryCureCheck(true)
#    end
    # Wimp Out -- Adrenst
    if opponent.hasWorkingAbility(:WIMPOUT) && opponent.hp<=(opponent.totalhp/2).floor && (opponent.hp+damage)>(opponent.totalhp/2) && !opponent.damagestate.substitute
      if !opponent.isFainted? && @battle.pbCanChooseNonActive?(opponent.index) &&
      !@battle.pbAllFainted?(@battle.pbParty(opponent.index))
        if @battle.opponent
           @battle.pbDisplay(_INTL("¡Se activó Huída de {1}!", opponent.pbThis))
          opponent.effects[PBEffects::Uturn]=true
        else
          @battle.pbRun(opponent.index);
        end
      end
    end
    # Emergency Exit -- Adrenst
    if opponent.hasWorkingAbility(:EMERGENCYEXIT) && opponent.hp<=(opponent.totalhp/2).floor && (opponent.hp+damage)>(opponent.totalhp/2) && !opponent.damagestate.substitute
      if !opponent.isFainted? && @battle.pbCanChooseNonActive?(opponent.index) &&
      !@battle.pbAllFainted?(@battle.pbParty(opponent.index))
        if @battle.opponent
           @battle.pbDisplay(_INTL("¡Se activó Retirada de {1}!", opponent.pbThis))
          opponent.effects[PBEffects::Uturn]=true
        else
          @battle.pbRun(opponent.index);
        end
      end
    end
    opponent.lastHPLost=damage                   # para Revenge/Focus Punch/Metal Burst
    opponent.tookDamage=true if damage>0         # para Assurance
    opponent.lastAttacker.push(attacker.index)   # para Revenge/Metal Burst
    attacker.lastTarget = opponent.index         # para Instruct
  end

  def pbMoveFailed(attacker,opponent)
    # Called to determine whether the move failed
    return false
  end
end
