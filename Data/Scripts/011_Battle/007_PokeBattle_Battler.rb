$zygardeform=-1 # Records, eventually, to what form should Zygarde return after battle
class PokeBattle_Battler
  attr_reader :battle
  attr_reader :pokemon
  attr_reader :name
  attr_reader :index
  attr_accessor :pokemonIndex
  attr_reader :totalhp
  attr_reader :fainted
  attr_accessor :lastAttacker
  attr_accessor :turncount
  attr_accessor :effects
  attr_accessor :species
  attr_accessor :type1
  attr_accessor :type2
  attr_accessor :ability
  attr_accessor :gender
  attr_accessor :attack
  attr_writer :defense
  attr_accessor :spatk
  attr_writer :spdef
  attr_accessor :speed
  attr_accessor :stages
  attr_accessor :iv
  attr_accessor :moves
  attr_accessor :participants
  attr_accessor :tookDamage
  attr_accessor :lastHPLost
  attr_accessor :lastMoveUsed
  attr_accessor :lastMoveUsedType
  attr_accessor :lastMoveUsedSketch
  attr_accessor :lastRegularMoveUsed
  attr_accessor :lastRoundMoved
  attr_accessor :movesUsed
  attr_accessor :currentMove
  attr_accessor :damagestate
  attr_accessor :captured
  attr_accessor :lastTarget
  attr_accessor :astral_stab


  def inHyperMode?; return false; end
  def isShadow?; return false; end

################################################################################
# Complex accessors
################################################################################
  def defense
    return @battle.field.effects[PBEffects::WonderRoom]>0 ? @spdef : @defense
  end

  def spdef
    return @battle.field.effects[PBEffects::WonderRoom]>0 ? @defense : @spdef
  end

  def nature
    return (@pokemon) ? @pokemon.nature : 0
  end

  def happiness
    return (@pokemon) ? @pokemon.happiness : 0
  end

  def pokerusStage
    return (@pokemon) ? @pokemon.pokerusStage : 0
  end

  attr_reader :form

  def form=(value)
    @form=value
    @pokemon.form=value if @pokemon
  end

  def isSpecies?(species)
    return @pokemon && @pokemon.isSpecies?(species)
  end

  def hasMega?
    return false if @effects[PBEffects::Transform]
    if @pokemon
      return (@pokemon.hasMegaForm? rescue false)
    end
    return false
  end

  def isMega?
    if @pokemon
      return (@pokemon.isMega? rescue false)
    end
    return false
  end

  def makeUntera
    @pokemon.makeUntera
  end

  def makeTera
    @pokemon.makeTera
  end

  def isTera?
    return @pokemon.teracristalized if @pokemon
  end


  def hasUltra?
    return false if @effects[PBEffects::Transform]
    if @pokemon
      return (@pokemon.hasUltraForm? rescue false)
    end
    return false
  end

  def isUltra?
    if @pokemon
      return (@pokemon.isUltra? rescue false)
    end
    return false
  end

  def hasPrimal?
    return false if @effects[PBEffects::Transform]
    if @pokemon
      return (@pokemon.hasPrimalForm? rescue false)
    end
    return false
  end

  def isPrimal?
    if @pokemon
      return (@pokemon.isPrimal? rescue false)
    end
    return false
  end

  attr_reader :level

  def level=(value)
    @level=value
    @pokemon.level=(value) if @pokemon
  end

  attr_reader :status

  def status=(value)
    if @status==PBStatuses::SLEEP && value==0
      @effects[PBEffects::Truant]=false
    end
    @status=value
    @pokemon.status=value if @pokemon
    if value!=PBStatuses::POISON
      @effects[PBEffects::Toxic]=0
    end
    if value!=PBStatuses::POISON && value!=PBStatuses::SLEEP
      @statusCount=0
      @pokemon.statusCount=0 if @pokemon
    end
  end

  attr_reader :statusCount

  def statusCount=(value)
    @statusCount=value
    @pokemon.statusCount=value if @pokemon
  end

  attr_reader :hp

  def hp=(value)
    @hp=value.to_i
    @pokemon.hp=value.to_i if @pokemon
  end

  attr_reader :item

  def item=(value)
    @item=value
    @pokemon.setItem(value) if @pokemon
  end

  def weight(attacker=nil)
    w=(@pokemon) ? @pokemon.weight : 500
    if !attacker || !attacker.hasMoldBreaker
      w*=2 if self.hasWorkingAbility(:HEAVYMETAL)
      w/=2 if self.hasWorkingAbility(:LIGHTMETAL)
    end
    w/=2 if self.hasWorkingItem(:FLOATSTONE)
    w+=@effects[PBEffects::WeightChange]
    w=w.floor
    w=1 if w<1
    return w
  end

  def name
    if @effects[PBEffects::Illusion]
      return @effects[PBEffects::Illusion].name
    end
    return @name
  end

  def displayGender
    if @effects[PBEffects::Illusion]
      return @effects[PBEffects::Illusion].gender
    end
    return self.gender
  end

  def isShiny?
    if @effects[PBEffects::Illusion]
      return @effects[PBEffects::Illusion].isShiny?
    end
    return @pokemon.isShiny? if @pokemon
    return false
  end

  def owned
    return (@pokemon) ? $Trainer.owned[@pokemon.species] && !@battle.opponent : false
  end

################################################################################
# Creating a battler
################################################################################
  def initialize(btl,index)
    @battle       = btl
    @index        = index
    @hp           = 0
    @totalhp      = 0
    @fainted      = true
    @captured     = false
    @stages       = []
    @effects      = []
    @damagestate  = PokeBattle_DamageState.new
    pbInitBlank
    pbInitEffects(false)
    pbInitPermanentEffects
    @astral_stab  = [true,true]
  end

  def pbInitPokemon(pkmn,pkmnIndex)
    if pkmn.isEgg?
      raise _INTL("Un huevo no puede ser un Pokémon activo")
    end
    @name         = pkmn.name
    @species      = pkmn.species
    @level        = pkmn.level
    @hp           = pkmn.hp
    @totalhp      = pkmn.totalhp
    @gender       = pkmn.gender
    @ability      = pkmn.ability
    @item         = pkmn.item
    @type1        = pkmn.type1
    @type2        = pkmn.type2
    @form         = pkmn.form
    @attack       = pkmn.attack
    @defense      = pkmn.defense
    @speed        = pkmn.speed
    @spatk        = pkmn.spatk
    @spdef        = pkmn.spdef
    @status       = pkmn.status
    @statusCount  = pkmn.statusCount
    @pokemon      = pkmn
    @pokemonIndex = pkmnIndex
    @participants = [] # Participants will earn Exp. Points if this battler is defeated
    @moves        = [
       PokeBattle_Move.pbFromPBMove(@battle,pkmn.moves[0]),
       PokeBattle_Move.pbFromPBMove(@battle,pkmn.moves[1]),
       PokeBattle_Move.pbFromPBMove(@battle,pkmn.moves[2]),
       PokeBattle_Move.pbFromPBMove(@battle,pkmn.moves[3])
    ]
    @iv           = []
    @iv[0]        = pkmn.iv[0]
    @iv[1]        = pkmn.iv[1]
    @iv[2]        = pkmn.iv[2]
    @iv[3]        = pkmn.iv[3]
    @iv[4]        = pkmn.iv[4]
    @iv[5]        = pkmn.iv[5]
  end

  def pbInitDummyPokemon(pkmn,pkmnIndex)
    if pkmn.isEgg?
      raise _INTL("Un huevo no puede ser un Pokémon activo")
    end
    @name         = pkmn.name
    @species      = pkmn.species
    @level        = pkmn.level
    @hp           = pkmn.hp
    @totalhp      = pkmn.totalhp
    @gender       = pkmn.gender
    @type1        = pkmn.type1
    @type2        = pkmn.type2
    @form         = pkmn.form
    @attack       = pkmn.attack
    @defense      = pkmn.defense
    @speed        = pkmn.speed
    @spatk        = pkmn.spatk
    @spdef        = pkmn.spdef
    @status       = pkmn.status
    @statusCount  = pkmn.statusCount
    @pokemon      = pkmn
    @pokemonIndex = pkmnIndex
    @participants = []
    @iv           = []
    @iv[0]        = pkmn.iv[0]
    @iv[1]        = pkmn.iv[1]
    @iv[2]        = pkmn.iv[2]
    @iv[3]        = pkmn.iv[3]
    @iv[4]        = pkmn.iv[4]
    @iv[5]        = pkmn.iv[5]
  end

  def pbInitBlank
    @name         = ""
    @species      = 0
    @level        = 0
    @hp           = 0
    @totalhp      = 0
    @gender       = 0
    @ability      = 0
    @type1        = 0
    @type2        = 0
    @form         = 0
    @attack       = 0
    @defense      = 0
    @speed        = 0
    @spatk        = 0
    @spdef        = 0
    @status       = 0
    @statusCount  = 0
    @pokemon      = nil
    @pokemonIndex = -1
    @participants = []
    @moves        = [nil,nil,nil,nil]
    @iv           = [0,0,0,0,0,0]
    @item         = 0
    @weight       = nil
  end

  def pbInitPermanentEffects
    # These effects are always retained even if a Pokémon is replaced
    @effects[PBEffects::FutureSight]        = 0
    @effects[PBEffects::FutureSightMove]    = 0
    @effects[PBEffects::FutureSightUser]    = -1
    @effects[PBEffects::FutureSightUserPos] = -1
    @effects[PBEffects::HealingWish]        = false
    @effects[PBEffects::LunarDance]         = false
    @effects[PBEffects::Wish]               = 0
    @effects[PBEffects::WishAmount]         = 0
    @effects[PBEffects::WishMaker]          = -1
    @effects[PBEffects::CorrosiveGas]       = false
  end

  def pbInitEffects(batonpass)
    if !batonpass
      # These effects are retained if Baton Pass is used
      @stages[PBStats::ATTACK]   = 0
      @stages[PBStats::DEFENSE]  = 0
      @stages[PBStats::SPEED]    = 0
      @stages[PBStats::SPATK]    = 0
      @stages[PBStats::SPDEF]    = 0
      @stages[PBStats::EVASION]  = 0
      @stages[PBStats::ACCURACY] = 0
      @lastMoveUsedSketch        = -1
      @effects[PBEffects::AquaRing]    = false
      @effects[PBEffects::Confusion]   = 0
      @effects[PBEffects::Curse]       = false
      @effects[PBEffects::Embargo]     = 0
      @effects[PBEffects::FocusEnergy] = 0
      @effects[PBEffects::GastroAcid]  = false
      @effects[PBEffects::HealBlock]   = 0
      @effects[PBEffects::Ingrain]     = false
      @effects[PBEffects::NoRetreat]   = false
      @effects[PBEffects::Octolock]    = false
      @effects[PBEffects::OctolockUser]= -1
      for i in 0...4
        next if !@battle.battlers[i]
        if @battle.battlers[i].effects[PBEffects::OctolockUser]==@index &&
           @battle.battlers[i].effects[PBEffects::Octolock]
           @battle.battlers[i].effects[PBEffects::Octolock]=false
          @battle.battlers[i].effects[PBEffects::OctolockUser]=-1
        end
      end
      @effects[PBEffects::JawLock]     = false
      @effects[PBEffects::JawLockUser] = -1
      for i in 0...4
        next if !@battle.battlers[i]
        if @battle.battlers[i].effects[PBEffects::JawLockUser]==@index &&
           @battle.battlers[i].effects[PBEffects::JawLock]
           @battle.battlers[i].effects[PBEffects::JawLock]=false
          @battle.battlers[i].effects[PBEffects::JawLockUser]=-1
        end
      end
      @effects[PBEffects::LeechSeed]   = -1
      @effects[PBEffects::LockOn]      = 0
      @effects[PBEffects::LockOnPos]   = -1
      for i in 0...4
        next if !@battle.battlers[i]
        if @battle.battlers[i].effects[PBEffects::LockOnPos]==@index &&
           @battle.battlers[i].effects[PBEffects::LockOn]>0
          @battle.battlers[i].effects[PBEffects::LockOn]=0
          @battle.battlers[i].effects[PBEffects::LockOnPos]=-1
        end
      end
      @effects[PBEffects::MagnetRise]     = 0
      @effects[PBEffects::PerishSong]     = 0
      @effects[PBEffects::PerishSongUser] = -1
      @effects[PBEffects::PowerTrick]     = false
      @effects[PBEffects::PowerShift]     = false
      @effects[PBEffects::Telekinesis]    = 0
      @effects[PBEffects::Substitute]     = 0 if @effects[PBEffects::ShedTail]!=nil && !@effects[PBEffects::ShedTail]
    else
      if @effects[PBEffects::LockOn]>0
        @effects[PBEffects::LockOn]=2
      else
        @effects[PBEffects::LockOn]=0
      end
      if @effects[PBEffects::PowerTrick]
        @attack,@defense=@defense,@attack
      end
    end
    @damagestate.reset
    @fainted          = false
    @lastAttacker     = []
    @lastTarget       = 0
    @lastHPLost       = 0
    @tookDamage       = false
    @lastMoveUsed     = -1
    @lastMoveUsedType = -1
    @lastRoundMoved   = -1
    @movesUsed        = []
    @turncount        = 0
    @effects[PBEffects::Attract]          = -1
    for i in 0...4
      next if !@battle.battlers[i]
      if @battle.battlers[i].effects[PBEffects::Attract]==@index
        @battle.battlers[i].effects[PBEffects::Attract]=-1
      end
    end
    @effects[PBEffects::BatonPass]        = false
    @effects[PBEffects::Bide]             = 0
    @effects[PBEffects::BideDamage]       = 0
    @effects[PBEffects::BideTarget]       = -1
    @effects[PBEffects::Charge]           = 0
    @effects[PBEffects::ChoiceBand]       = -1
    @effects[PBEffects::Counter]          = -1
    @effects[PBEffects::CounterTarget]    = -1
    @effects[PBEffects::CudChew]          = 0
    @effects[PBEffects::DefenseCurl]      = false
    @effects[PBEffects::DestinyBond]      = false
    @effects[PBEffects::Disable]          = 0
    @effects[PBEffects::DisableMove]      = 0
    @effects[PBEffects::Electrify]        = false
    @effects[PBEffects::Encore]           = 0
    @effects[PBEffects::EncoreIndex]      = 0
    @effects[PBEffects::EncoreMove]       = 0
    @effects[PBEffects::Endure]           = false
    @effects[PBEffects::FirstPledge]      = 0
    @effects[PBEffects::FlashFire]        = false
    @effects[PBEffects::Flinch]           = false
    @effects[PBEffects::FollowMe]         = 0
    @effects[PBEffects::Foresight]        = false
    @effects[PBEffects::FuryCutter]       = 0
    @effects[PBEffects::GigatonHammer]    = 0
    @effects[PBEffects::Grudge]           = false
    @effects[PBEffects::HelpingHand]      = false
    @effects[PBEffects::HyperBeam]        = 0
    @effects[PBEffects::Illusion]         = nil
    @effects[PBEffects::BurningJealousy]  = false
    @effects[PBEffects::LashOut]          = false
    @effects[PBEffects::ShedTail]         = false
    if self.hasWorkingAbility(:ILLUSION)
      lastpoke=@battle.pbGetLastPokeInTeam(@index)
      if lastpoke!=@pokemonIndex
        @effects[PBEffects::Illusion]     = @battle.pbParty(@index)[lastpoke]
      end
    end
    @effects[PBEffects::Imprison]         = false
    @effects[PBEffects::KingsShield]      = false
    @effects[PBEffects::LaserFocus]       = 0
    @effects[PBEffects::LastMoveFailed]   = false
    @effects[PBEffects::LifeOrb]          = false
    @effects[PBEffects::MagicCoat]        = false
    @effects[PBEffects::MeanLook]         = -1
    for i in 0...4
      next if !@battle.battlers[i]
      if @battle.battlers[i].effects[PBEffects::MeanLook]==@index
        @battle.battlers[i].effects[PBEffects::MeanLook]=-1
      end
    end
    @effects[PBEffects::MeFirst]          = false
    @effects[PBEffects::Metronome]        = 0
    @effects[PBEffects::MicleBerry]       = false
    @effects[PBEffects::Minimize]         = false
    @effects[PBEffects::MiracleEye]       = false
    @effects[PBEffects::MirrorCoat]       = -1
    @effects[PBEffects::MirrorCoatTarget] = -1
    @effects[PBEffects::MoveNext]         = false
    @effects[PBEffects::MudSport]         = false
    @effects[PBEffects::MultiTurn]        = 0
    @effects[PBEffects::MultiTurnAttack]  = 0
    @effects[PBEffects::MultiTurnUser]    = -1
    for i in 0...4
      next if !@battle.battlers[i]
      if @battle.battlers[i].effects[PBEffects::MultiTurnUser]==@index
        @battle.battlers[i].effects[PBEffects::MultiTurn]=0
        @battle.battlers[i].effects[PBEffects::MultiTurnUser]=-1
      end
    end
    @effects[PBEffects::Nightmare]        = false
    @effects[PBEffects::Outrage]          = 0
    @effects[PBEffects::ParentalBond]     = 0
    @effects[PBEffects::PickupItem]       = 0
    @effects[PBEffects::PickupUse]        = 0
    @effects[PBEffects::Pinch]            = false
    @effects[PBEffects::Powder]           = false
    @effects[PBEffects::Protect]          = false
    @effects[PBEffects::ProtectNegation]  = false
    @effects[PBEffects::ProtectRate]      = 1
    @effects[PBEffects::Pursuit]          = false
    @effects[PBEffects::Quash]            = false
    @effects[PBEffects::Rage]             = false
    @effects[PBEffects::Revenge]          = 0
    @effects[PBEffects::Roar]             = false
    @effects[PBEffects::Rollout]          = 0
    @effects[PBEffects::Roost]            = false
    @effects[PBEffects::ShellTrap]        = false
    @effects[PBEffects::SkipTurn]         = false
    @effects[PBEffects::SkyDrop]          = false
    @effects[PBEffects::SmackDown]        = false
    @effects[PBEffects::Snatch]           = false
    @effects[PBEffects::SpikyShield]      = false
    @effects[PBEffects::Stockpile]        = 0
    @effects[PBEffects::StockpileDef]     = 0
    @effects[PBEffects::StockpileSpDef]   = 0
    @effects[PBEffects::Taunt]            = 0
    @effects[PBEffects::ThroatChop]       = 0
    @effects[PBEffects::Torment]          = false
    @effects[PBEffects::Toxic]            = 0
    @effects[PBEffects::Transform]        = false
    @effects[PBEffects::Truant]           = false
    @effects[PBEffects::TwoTurnAttack]    = 0
    @effects[PBEffects::Type3]            = -1
    @effects[PBEffects::Unburden]         = false
    @effects[PBEffects::Uproar]           = 0
    @effects[PBEffects::Uturn]            = false
    @effects[PBEffects::WaterSport]       = false
    @effects[PBEffects::WeightChange]     = 0
    @effects[PBEffects::Yawn]             = 0
    @effects[PBEffects::Obstruct]         = false
    @effects[PBEffects::TarShot]          = false
    @effects[PBEffects::PerishBody]       = 0
    @effects[PBEffects::GorillaTactics]   = -1
    @effects[PBEffects::Mimicry]          = [nil, nil]
    @effects[PBEffects::RevivalBlessing]  = false
    @effects[PBEffects::Silktrap]         = false
    @effects[PBEffects::RageFist]         = false
    @effects[PBEffects::BurningBulwark]   = false
    @effects[PBEffects::Commander]        = 0
    @effects[PBEffects::GlaiveRush]       = false
    @effects[PBEffects::ShedTail]         = false
    @effects[PBEffects::SaltCure]         = false
    @effects[PBEffects::SyrupBomb]        = 0
  end

  def pbUpdate(fullchange=false)
    if @pokemon
      @pokemon.calcStats
      @level     = @pokemon.level
      @hp        = @pokemon.hp
      @totalhp   = @pokemon.totalhp
      if !@effects[PBEffects::Transform]
        @attack    = @pokemon.attack
        @defense   = @pokemon.defense
        @speed     = @pokemon.speed
        @spatk     = @pokemon.spatk
        @spdef     = @pokemon.spdef
        if fullchange
          @ability = @pokemon.ability
          @type1   = @pokemon.type1
          @type2   = @pokemon.type2
        end
      end
    end
  end

  def pbInitialize(pkmn,index,batonpass)
    # Cura Natural
    if self.hasWorkingAbility(:NATURALCURE)
      self.status=0
    end
    # Cambio Heroico
    if self.hasWorkingAbility(:ZEROTOHERO) &&
      isConst?(self.species,PBSpecies,:PALAFIN) && self.form==0
      self.form=1
    end
    # Regeneración
    if self.hasWorkingAbility(:REGENERATOR)
      self.pbRecoverHP((totalhp/3).floor)
    end
    pbInitPokemon(pkmn,index)
    pbInitEffects(batonpass)
  end

# Used only to erase the battler of a Shadow Pokémon that has been snagged.
  def pbReset
    @pokemon                = nil
    @pokemonIndex           = -1
    self.hp                 = 0
    pbInitEffects(false)
    # reset status
    self.status             = 0
    self.statusCount        = 0
    @fainted                = true
    # reset choice
    @battle.choices[@index] = [0,0,nil,-1]
    return true
  end

# Update Pokémon who will gain EXP if this battler is defeated
  def pbUpdateParticipants
    return if self.isFainted? # can't update if already fainted
    if @battle.pbIsOpposing?(@index)
      found1=false
      found2=false
      for i in @participants
        found1=true if i==pbOpposing1.pokemonIndex
        found2=true if i==pbOpposing2.pokemonIndex
      end
      if !found1 && !pbOpposing1.isFainted?
        @participants[@participants.length]=pbOpposing1.pokemonIndex
      end
      if !found2 && !pbOpposing2.isFainted?
        @participants[@participants.length]=pbOpposing2.pokemonIndex
      end
    end
  end

################################################################################
# About this battler
################################################################################



  def pbThis(lowercase=false)
    if @battle.pbIsOpposing?(@index)
      if @battle.opponent
        return lowercase ? _INTL("{1} rival",self.name) : _INTL("{1} rival",self.name)      # Le quité 'el' y 'El' a estas 3 líneas
      else
        return lowercase ? _INTL("{1} salvaje",self.name) : _INTL("{1} salvaje",self.name)
      end
    elsif @battle.pbOwnedByPlayer?(@index)
      return _INTL("{1}",self.name)
    else
      return lowercase ? _INTL("{1} aliado",self.name) : _INTL("{1} aliado",self.name)
    end
  end

  def pbHasType?(type)
    ret=false
    if type.is_a?(Symbol) || type.is_a?(String)
      ret=isConst?(self.type1,PBTypes,type.to_sym) ||
          isConst?(self.type2,PBTypes,type.to_sym)
      if @effects[PBEffects::Type3]>=0
        ret|=isConst?(@effects[PBEffects::Type3],PBTypes,type.to_sym)
      end
    else
      ret=(self.type1==type || self.type2==type)
      if @effects[PBEffects::Type3]>=0
        ret|=(@effects[PBEffects::Type3]==type)
      end
    end
    return ret
  end

  def pbHasMove?(id)
    if id.is_a?(String) || id.is_a?(Symbol)
      id=getID(PBMoves,id)
    end
    return false if !id || id==0
    for i in @moves
      return true if i.id==id
    end
    return false
  end

  def pbHasMoveType?(type)
    if type.is_a?(String) || type.is_a?(Symbol)
      type=getID(PBTypes,type)
    end
    return false if !type || type<0
    for i in @moves
      return true if i.type==type
    end
    return false
  end

  def pbHasMoveFunction?(code)
    return false if !code
    for i in @moves
      return true if i.function==code
    end
    return false
  end

  def hasMovedThisRound?
    return false if !@lastRoundMoved
    return @lastRoundMoved==@battle.turncount
  end

  def isFainted?
    return @hp<=0
  end

  def fainted? #BES-T Compt - v17
    return @hp<=0
  end

  def hasMoldBreaker
    return true if hasWorkingAbility(:MOLDBREAKER) ||
                   hasWorkingAbility(:TERAVOLT) ||
                   hasWorkingAbility(:TURBOBLAZE) ||
                   hasWorkingAbility(:MYCELIUMMIGHT)
    return false
  end

  def hasWorkingAbility(ability,ignorefainted=false)
    return false if self.isFainted? && !ignorefainted
    return false if @effects[PBEffects::GastroAcid]
    for i in 0...4
      hasabil=false; poke=@battle.battlers[i]
      if isConst?(poke.ability,PBAbilities,:NEUTRALIZINGGAS) && !poke.isFainted?
        hasabil=true
      end
      return false if hasabil
    end
    return isConst?(@ability,PBAbilities,ability)
  end

  def hasWorkingItem(item,ignorefainted=false)
    return false if self.isFainted? && !ignorefainted
    return false if @effects[PBEffects::Embargo]>0
    return false if @effects[PBEffects::CorrosiveGas]
    return false if @battle.field.effects[PBEffects::MagicRoom]>0
    return false if self.hasWorkingAbility(:KLUTZ,ignorefainted)
    return isConst?(@item,PBItems,item)
  end

  def hasWorkingBerry(ignorefainted=false)
    return false if self.isFainted? && !ignorefainted
    return false if @effects[PBEffects::Embargo]>0
    return false if @effects[PBEffects::CorrosiveGas]
    return false if @battle.field.effects[PBEffects::MagicRoom]>0
    return false if self.hasWorkingAbility(:KLUTZ,ignorefainted)
    return pbIsBerry?(@item)
  end

  def isAirborne?(ignoreability=false)
    return false if self.hasWorkingItem(:IRONBALL)
    return false if @effects[PBEffects::Ingrain]
    return false if @effects[PBEffects::SmackDown]
    return false if @battle.field.effects[PBEffects::Gravity]>0
    return true if self.pbHasType?(:FLYING) && !@effects[PBEffects::Roost]
    return true if self.hasWorkingAbility(:LEVITATE) && !ignoreability
    return true if self.hasWorkingItem(:AIRBALLOON)
    return true if @effects[PBEffects::MagnetRise]>0
    return true if @effects[PBEffects::Telekinesis]>0
    return false
  end

  def pbSpeed()
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]
    speed=@speed
    stage=@stages[PBStats::SPEED]+6
    speed=(speed*stagemul[stage]/stagediv[stage]).floor
    speedmult=0x1000
    case @battle.pbWeather
    when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
      speedmult=speedmult*2 if self.hasWorkingAbility(:SWIFTSWIM) && !self.hasWorkingItem(:UTILITYUMBRELLA)
    when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
      speedmult=speedmult*2 if self.hasWorkingAbility(:CHLOROPHYLL) && !self.hasWorkingItem(:UTILITYUMBRELLA)
    when PBWeather::SANDSTORM
      speedmult=speedmult*2 if self.hasWorkingAbility(:SANDRUSH)
    when PBWeather::HAIL
      speedmult=speedmult*2 if self.hasWorkingAbility(:SLUSHRUSH)
    end
    if self.hasWorkingAbility(:QUICKFEET) && self.status>0
      speedmult=(speedmult*1.5).round
    end
    if self.hasWorkingAbility(:SURGESURFER) && @battle.field.effects[PBEffects::ElectricTerrain]>0
      speedmult=speedmult*2
    end
    if self.hasWorkingAbility(:UNBURDEN) && @effects[PBEffects::Unburden] &&
       self.item==0
      speedmult=speedmult*2
    end
    if self.hasWorkingAbility(:SLOWSTART) && self.turncount<=5
      speedmult=(speedmult/2).round
    end
    if self.hasWorkingItem(:MACHOBRACE) ||
       self.hasWorkingItem(:POWERWEIGHT) ||
       self.hasWorkingItem(:POWERBRACER) ||
       self.hasWorkingItem(:POWERBELT) ||
       self.hasWorkingItem(:POWERANKLET) ||
       self.hasWorkingItem(:POWERLENS) ||
       self.hasWorkingItem(:POWERBAND)
      speedmult=(speedmult/2).round
    end
    if self.hasWorkingItem(:CHOICESCARF)
      speedmult=(speedmult*1.5).round
    end
    if isConst?(self.item,PBItems,:IRONBALL)
      speedmult=(speedmult/2).round
    end
    if self.hasWorkingItem(:QUICKPOWDER) && isConst?(self.species,PBSpecies,:DITTO) &&
       !@effects[PBEffects::Transform]
      speedmult=speedmult*2
    end
    if self.pbOwnSide.effects[PBEffects::Tailwind]>0
      speedmult=speedmult*2
    end
    if self.pbOwnSide.effects[PBEffects::Swamp]>0
      speedmult=(speedmult/2).round
    end
    if self.status==PBStatuses::PARALYSIS && !self.hasWorkingAbility(:QUICKFEET)
      speedmult=(speedmult/4).round
    end
    if @battle.internalbattle && @battle.pbOwnedByPlayer?(@index) &&
       @battle.pbPlayer.numbadges>=BADGESBOOSTSPEED
      speedmult=(speedmult*1.1).round
    end
    speed=(speed*speedmult*1.0/0x1000).round
    return [speed,1].max
  end

################################################################################
# Change HP
################################################################################
  def pbReduceHP(amt,anim=false,registerDamage=true)
    if amt>=self.hp
      amt=self.hp
    elsif amt<1 && !self.isFainted?
      amt=1
    end
    oldhp=self.hp
    self.hp-=amt
    raise _INTL("PS menor a 0") if self.hp<0
    raise _INTL("PS mayor a los PS totales") if self.hp>@totalhp
    @battle.scene.pbHPChanged(self,oldhp,anim) if amt>0
    @tookDamage=true if amt>0 && registerDamage
    return amt
  end

  def pbRecoverHP(amt,anim=false)
    if self.hp+amt>@totalhp
      amt=@totalhp-self.hp
    elsif amt<1 && self.hp!=@totalhp
      amt=1
    end
    oldhp=self.hp
    self.hp+=amt
    raise _INTL("PS menor a 0") if self.hp<0
    raise _INTL("PS mayor a los PS totales") if self.hp>@totalhp
    @battle.scene.pbHPChanged(self,oldhp,anim) if amt>0
    return amt
  end

  def pbFaint(showMessage=true)
    if !self.isFainted?
      PBDebug.log("!!!***No se puede debilitar con PS mayor a 0")
      return true
    end
    if @fainted
#      PBDebug.log("!!!***No se puede debilitar si ya está debilitado")
      return true
    end
    @battle.scene.pbFainted(self)
    pbInitEffects(false)
    # Reset status
    self.status=0
    self.statusCount=0
    if @pokemon && @battle.internalbattle
      @pokemon.changeHappiness("faint")
    end
    if self.isMega?
      @pokemon.makeUnmega
    end
    if self.isUltra?
       @pokemon.makeUnUltra
    end
    if self.isPrimal?
      @pokemon.makeUnprimal
    end
    if self.isTera?
      @pokemon.makeUntera
    end
    @pokemon.revertOtherForms
    @fainted=true
    # reset choice
    @battle.choices[@index]=[0,0,nil,-1]
    pbOwnSide.effects[PBEffects::LastRoundFainted]=@battle.turncount
    pbOwnSide.effects[PBEffects::FaintedAlly]+=1
    @battle.pbDisplayPaused(_INTL("¡{1} se ha debilitado!",pbThis)) if showMessage
    PBDebug.log("[Pokémon debilitado] #{pbThis}")
    return true
  end
################################################################################
# Find other battlers/sides in relation to this battler
################################################################################
# Returns the data structure for this battler's side
  def pbOwnSide
    return @battle.sides[@index&1] # Player: 0 and 2; Foe: 1 and 3
  end

# Returns the data structure for the opposing Pokémon's side
  def pbOpposingSide
    return @battle.sides[(@index&1)^1] # Player: 1 and 3; Foe: 0 and 2
  end

# Returns whether the position belongs to the opposing Pokémon's side
  def pbIsOpposing?(i)
    return (@index&1)!=(i&1)
  end

# Returns the battler's partner
  def pbPartner
    return @battle.battlers[(@index&1)|((@index&2)^2)]
  end

# Returns the battler's first opposing Pokémon
  def pbOpposing1
    return @battle.battlers[((@index&1)^1)]
  end

# Returns the battler's second opposing Pokémon
  def pbOpposing2
    return @battle.battlers[((@index&1)^1)+2]
  end

  def pbOppositeOpposing
    return @battle.battlers[(@index^1)]
  end

  def pbOppositeOpposing2
    return @battle.battlers[(@index^1)|((@index&2)^2)]
  end

  def pbNonActivePokemonCount()
    count=0
    party=@battle.pbParty(self.index)
    for i in 0...party.length
      if (self.isFainted? || i!=self.pokemonIndex) &&
         (pbPartner.isFainted? || i!=self.pbPartner.pokemonIndex) &&
         party[i] && !party[i].isEgg? && party[i].hp>0
        count+=1
      end
    end
    return count
  end

################################################################################
# Forms
################################################################################
  @@miniorform = 0  # Records the form of Minior at the beginning of battle
  def pbCheckForm
    return if @effects[PBEffects::Transform]
    return if self.isFainted?
    transformed=false
    # Forecast
    if isConst?(self.species,PBSpecies,:CASTFORM)
      if self.hasWorkingAbility(:FORECAST)
        case @battle.pbWeather
        when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
          if self.form!=1 && !self.hasWorkingItem(:UTILITYUMBRELLA)
            self.form=1; transformed=true
          end
        when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
          if self.form!=2 && !self.hasWorkingItem(:UTILITYUMBRELLA)
            self.form=2; transformed=true
          end
        when PBWeather::HAIL
          if self.form!=3
            self.form=3; transformed=true
          end
        else
          if self.form!=0
            self.form=0; transformed=true
          end
        end
      else
        if self.form!=0
          self.form=0; transformed=true
        end
      end
    end
    # Cherrim
    if isConst?(self.species,PBSpecies,:CHERRIM) && !self.hasWorkingItem(:UTILITYUMBRELLA)
      if self.hasWorkingAbility(:FLOWERGIFT) &&
         (@battle.pbWeather==PBWeather::SUNNYDAY ||
         @battle.pbWeather==PBWeather::HARSHSUN)
        if self.form!=1
          self.form=1; transformed=true
        end
      else
        if self.form!=0
          self.form=0; transformed=true
        end
      end
    end
    # Shaymin
    if isConst?(self.species,PBSpecies,:SHAYMIN)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Dialga
    if isConst?(self.species,PBSpecies,:DIALGA)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Palkia
    if isConst?(self.species,PBSpecies,:PALKIA)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Giratina
    if isConst?(self.species,PBSpecies,:GIRATINA)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Arceus
    if isConst?(self.ability,PBAbilities,:MULTITYPE) &&
       isConst?(self.species,PBSpecies,:ARCEUS)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Darmanitan
    if isConst?(self.species,PBSpecies,:DARMANITAN)
      if self.hasWorkingAbility(:ZENMODE) && @hp<=((@totalhp/2).floor)
        if self.form==0
          self.form=2; transformed=true
        elsif self.form==1
          self.form=3; transformed=true
        end
      elsif self.hasWorkingAbility(:ZENMODE) && @hp>((@totalhp/2).floor)
        if self.form==2
          self.form=0; transformed=true
        elsif self.form==3
          self.form=1; transformed=true
        end
      end
    end
    # Wishiwashi
    if isConst?(self.species,PBSpecies,:WISHIWASHI)
      if self.hasWorkingAbility(:SCHOOLING) && @hp<=((@totalhp/4).floor)
        if self.form!=0
          self.form=0; transformed=true
        end
      else
        if self.form!=1 && @level >=20
          self.form=1; transformed=true
        end
      end
    end
    # Keldeo
    if isConst?(self.species,PBSpecies,:KELDEO)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    # Zygarde
    if self.hasWorkingAbility(:POWERCONSTRUCT) &&
       isConst?(self.species,PBSpecies,:ZYGARDE) && self.form!=2 &&
       self.hp<(self.totalhp/2).ceil
      $zygardeform=self.form
      self.form=2
      transformed=true
      @battle.pbDisplay(_INTL("{1} siente la presencia de muchos...",pbThis))
    end
    # Minior
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&
      self.hp>(self.totalhp*0.5).floor && self.form!=0
      @@miniorform=self.form
      self.form=0
      @battle.pbDisplay(_INTL("¡El cuerpo de {1} fue petrificado!",self.pbThis))
      transformed=true
    elsif self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&
       self.hp<=(self.totalhp*0.5).floor && self.form==0 && @@miniorform>0
      self.form=@@miniorform
      @battle.pbDisplay(_INTL("¡La coraza rocosa de {1} se rompió!",self.pbThis))
      transformed=true
    elsif self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&
       self.hp<=(self.totalhp*0.5).floor && self.form==0 && @@miniorform=0
       self.form=1+rand(7)
       @@miniorform=self.form
       @battle.pbDisplay(_INTL("¡El núcleo de {1} fue quebrado!",self.pbThis))
       transformed=true
    end

    if transformed
      pbUpdate(true)
      @battle.scene.pbChangePokemon(self,@pokemon)
      PBDebug.log("[Form changed] #{pbThis} changed to form #{self.form}")
    end
    # Genesect
    if isConst?(self.species,PBSpecies,:GENESECT)
      if self.form!=@pokemon.form
        self.form=@pokemon.form
        transformed=true
      end
    end
    if transformed
      pbUpdate(true)
      @battle.scene.pbChangePokemon(self,@pokemon)
      @battle.pbDisplay(_INTL("¡{1} se ha transformado!",pbThis))
      PBDebug.log("[Cambio de forma] #{pbThis} cambió a forma #{self.form}")
    end
    # Silvally
    if isConst?(self.ability,PBAbilities,:RKSSYSTEM) &&
       isConst?(self.species,PBSpecies,:SILVALLY) && !self.isFainted?
      if self.form!=@pokemon.form
         self.form=@pokemon.form
         transformed=true
      end
    end
  end

  def pbResetForm
    if !@effects[PBEffects::Transform]
      if isConst?(self.species,PBSpecies,:CASTFORM) ||
         isConst?(self.species,PBSpecies,:CHERRIM) ||
         isConst?(self.species,PBSpecies,:MELOETTA) ||
         isConst?(self.species,PBSpecies,:AEGISLASH) ||
         isConst?(self.species,PBSpecies,:XERNEAS) ||
         isConst?(self.species,PBSpecies,:WISHIWASHI) ||
         isConst?(self.species,PBSpecies,:CRAMORANT) ||
         isConst?(self.species,PBSpecies,:EISCUE) ||
         isConst?(self.species,PBSpecies,:MORPEKO)||
         isConst?(self.species,PBSpecies,:ZACIAN)||
         isConst?(self.species,PBSpecies,:ZAMAZENTA)
        self.form=0
      end
      if isConst?(self.species,PBSpecies,:DARMANITAN)
        self.form=0 if self.form==2; self.form=1 if self.form==3
      end
      if isConst?(self.species,PBSpecies,:MINIOR)
        if @@miniorform>0
          self.form=@@miniorform
        else
          self.form=1+rand(7)
          @@miniorform=self.form
        end
      end
    end
    pbUpdate(true)
  end

################################################################################
# Efectos de las habilidades
################################################################################
  def pbAbilitiesOnSwitchIn(onactive)
    return if self.isFainted?
    if hasWorkingAbility(:MIMICRY) && onactive
      @effects[PBEffects::Mimicry] = [self.type1,self.type2]
    end
    if onactive
      @battle.pbPrimalReversion(self.index)
    end
    # Clima
    if onactive
      # Mar del Albor
      if self.hasWorkingAbility(:PRIMORDIALSEA) && @battle.weather!=PBWeather::HEAVYRAIN
        @battle.weather=PBWeather::HEAVYRAIN                 # Diluvio
        @battle.weatherduration=-1
        @battle.pbCommonAnimation("HeavyRain",nil,nil)
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo diluviar!",pbThis,PBAbilities.getName(self.ability)))
        PBDebug.log("[Habilidad disparada] Mar del Albor de #{pbThis} hizo diluviar")
      end
      # Tierra del Ocaso
      if self.hasWorkingAbility(:DESOLATELAND) && @battle.weather!=PBWeather::HARSHSUN
        @battle.weather=PBWeather::HARSHSUN                  # Sol realmente abrazador
        @battle.weatherduration=-1
        @battle.pbCommonAnimation("Sunny",nil,nil)
        @battle.pbDisplay(_INTL("¡{2} de {1} volvió al sol realmente abrasador!",pbThis,PBAbilities.getName(self.ability)))
        PBDebug.log("[Habilidad disparada] Tierra del Ocaso de #{pbThis} volvió al sol realmente abrasador")
      end
      # Ráfaga Delta
      if self.hasWorkingAbility(:DELTASTREAM) && @battle.weather!=PBWeather::STRONGWINDS
        @battle.weather=PBWeather::STRONGWINDS               # Turbulencias misteriosas
        @battle.weatherduration=-1
        @battle.pbCommonAnimation("StrongWinds",nil,nil)
        @battle.pbDisplay(_INTL("¡{2} de {1} causó unas misteriosas turbulencias que protegen a los Pokémon de tipo Volador!",pbThis,PBAbilities.getName(self.ability)))
        PBDebug.log("[Habilidad disparada] Ráfaga Delta de #{pbThis} causó unas misteriosas turbulencias")
      end
      if @battle.weather!=PBWeather::HEAVYRAIN &&
         @battle.weather!=PBWeather::HARSHSUN &&
         @battle.weather!=PBWeather::STRONGWINDS
        # Habilidad: Llovizna - Tiempo: Danza Lluvia (Lluvia)
        if self.hasWorkingAbility(:DRIZZLE) && (@battle.weather!=PBWeather::RAINDANCE || @battle.weatherduration!=-1)
          @battle.weather=PBWeather::RAINDANCE
          if USENEWBATTLEMECHANICS
            @battle.weatherduration=5
            @battle.weatherduration=8 if hasWorkingItem(:DAMPROCK)
          else
            @battle.weatherduration=-1
          end
          @battle.pbCommonAnimation("Rain",nil,nil)
          @battle.pbDisplay(_INTL("¡{2} de {1} hizo llover!",pbThis,PBAbilities.getName(self.ability)))
          PBDebug.log("[Habilidad disparada] Llovizna de #{pbThis} hizo llover")
        end
        # Habilidad: Sequía - Tiempo: Día Soleado (Sol pega fuerte)
        if (self.hasWorkingAbility(:DROUGHT) || self.hasWorkingAbility(:ORICHALCUMPULSE)) && (@battle.weather!=PBWeather::SUNNYDAY || @battle.weatherduration!=-1)
          @battle.weather=PBWeather::SUNNYDAY
          if USENEWBATTLEMECHANICS
            @battle.weatherduration=5
            @battle.weatherduration=8 if hasWorkingItem(:HEATROCK)
          else
            @battle.weatherduration=-1
          end
          @battle.pbCommonAnimation("Sunny",nil,nil)
          @battle.pbDisplay(_INTL("¡{2} de {1} intensificó los rayos del sol!",pbThis,PBAbilities.getName(self.ability)))
          PBDebug.log("[Habilidad disparada] Sequía de #{pbThis} aumentó la intensidad del sol")
        end
        # Habilidad: Chorro Arena - Tiempo: Tormenta de Arena
        if self.hasWorkingAbility(:SANDSTREAM) && (@battle.weather!=PBWeather::SANDSTORM || @battle.weatherduration!=-1)
          @battle.weather=PBWeather::SANDSTORM
          if USENEWBATTLEMECHANICS
            @battle.weatherduration=5
            @battle.weatherduration=8 if hasWorkingItem(:SMOOTHROCK)
          else
            @battle.weatherduration=-1
          end
          @battle.pbCommonAnimation("Sandstorm",nil,nil)
          @battle.pbDisplay(_INTL("¡{2} de {1} levantó una tormenta de arena!",pbThis,PBAbilities.getName(self.ability)))
          PBDebug.log("[Habilidad disparada] Chorro Arena de #{pbThis} levantó una tormenta de arena")
        end
        # Habilidad Nevada: - Tiempo: Granizo
        if self.hasWorkingAbility(:SNOWWARNING) && (@battle.weather!=PBWeather::HAIL || @battle.weatherduration!=-1)
          @battle.weather=PBWeather::HAIL
          if USENEWBATTLEMECHANICS
            @battle.weatherduration=5
            @battle.weatherduration=8 if hasWorkingItem(:ICYROCK)
          else
            @battle.weatherduration=-1
          end
          @battle.pbCommonAnimation("Hail",nil,nil)
          @battle.pbDisplay(_INTL("¡{2} de {1} provocó granizo!",pbThis,PBAbilities.getName(self.ability)))
          PBDebug.log("[Habilidad disparada] Nevada de #{pbThis} provocó granizo")
          for i in 0...4
            poke=@battle.battlers[i]
            if poke.hasWorkingAbility(:ICEFACE) && isConst?(poke.species,PBSpecies,:EISCUE) && poke.form!=0
              poke.form=0
              poke.pbUpdate(true)
              @battle.scene.pbChangePokemon(poke,poke.pokemon)
              @battle.pbDisplay(_INTL("¡{1} cambió de forma!",poke.pbThis))
              PBDebug.log("[Form changed] #{poke.pbThis} changed to form #{poke.form}")
            end
          end
        end
      end
      # Bucle Aire y Aclimatación
      if self.hasWorkingAbility(:AIRLOCK) ||
         self.hasWorkingAbility(:CLOUDNINE)
        @battle.pbDisplay(_INTL("¡{1} tiene {2}!",pbThis,PBAbilities.getName(self.ability)))
        @battle.pbDisplay(_INTL("El tiempo atmosférico ya no ejerce ninguna influencia."))
      end
      if self.hasWorkingAbility(:TERAFORMZERO)
        @battle.pbDisplay(_INTL("¡{1} tiene {2}!",pbThis,PBAbilities.getName(self.ability)))
        @battle.field.effects[PBEffects::PsychicTerrain]=0
        @battle.field.effects[PBEffects::ElectricTerrain]=0
        @battle.field.effects[PBEffects::GrassyTerrain]=0
        @battle.field.effects[PBEffects::MistyTerrain]=0
        @battle.weatherduration=0
      end
    end

    @battle.pbPrimordialWeather
    # Rastro
    if self.hasWorkingAbility(:TRACE)
      choices=[]
      for i in 0...4
        foe=@battle.battlers[i]
        if pbIsOpposing?(i) && !foe.isFainted?
          abil=foe.ability
          if abil>0 &&
             !isConst?(abil,PBAbilities,:TRACE) &&
             !isConst?(abil,PBAbilities,:MULTITYPE) &&
             !isConst?(abil,PBAbilities,:ILLUSION) &&
             !isConst?(abil,PBAbilities,:FLOWERGIFT) &&
             !isConst?(abil,PBAbilities,:IMPOSTER) &&
             !isConst?(abil,PBAbilities,:STANCECHANGE) &&
             !isConst?(abil,PBAbilities,:COMATOSE) &&
             !isConst?(abil,PBAbilities,:BATTLEBOND) &&
             !isConst?(abil,PBAbilities,:POWERCONSTRUCT) &&
             !isConst?(abil,PBAbilities,:DISGUISE) &&
             !isConst?(abil,PBAbilities,:POWEROFALCHEMY) &&
             !isConst?(abil,PBAbilities,:RECEIVER) &&
             !isConst?(abil,PBAbilities,:SCHOOLING) &&
             !isConst?(abil,PBAbilities,:SHIELDSDOWN) &&
             !isConst?(abil,PBAbilities,:RKSSYSTEM) &&
             !isConst?(abil,PBAbilities,:ICEFACE) &&
             !isConst?(abil,PBAbilities,:GULPMISSILE) &&
             !isConst?(abil,PBAbilities,:ZEROTOHERO)
            choices.push(i)
          end
        end
      end
      if choices.length>0
        choice=choices[@battle.pbRandom(choices.length)]
        battlername=@battle.battlers[choice].pbThis(true)
        battlerability=@battle.battlers[choice].ability
        @ability=battlerability
        abilityname=PBAbilities.getName(battlerability)
        @battle.pbDisplay(_INTL("¡{1} ha copiado la habilidad {3} de {2}!",pbThis,battlername,abilityname))
        PBDebug.log("[Habilidad disparada] Rastro de #{pbThis} se convirtió en #{abilityname} de #{battlername}")
      end
    end
    # Reacción Química & Receptor
    if (self.hasWorkingAbility(:POWEROFALCHEMY) || self.hasWorkingAbility(:RECEIVER)) &&
     @battle.doublebattle && pbPartner.isFainted?
      usable=false
      abil=pbPartner.ability
      if abil>0 &&
             !isConst?(abil,PBAbilities,:POWEROFALCHEMY) &&
             !isConst?(abil,PBAbilities,:TRACE) &&
             !isConst?(abil,PBAbilities,:MULTITYPE) &&
             !isConst?(abil,PBAbilities,:ILLUSION) &&
             !isConst?(abil,PBAbilities,:FLOWERGIFT) &&
             !isConst?(abil,PBAbilities,:IMPOSTER) &&
             !isConst?(abil,PBAbilities,:STANCECHANGE) &&
             !isConst?(abil,PBAbilities,:COMATOSE) &&
             !isConst?(abil,PBAbilities,:BATTLEBOND) &&
             !isConst?(abil,PBAbilities,:POWERCONSTRUCT) &&
             !isConst?(abil,PBAbilities,:RECEIVER) &&
             !isConst?(abil,PBAbilities,:FORECAST) &&
             !isConst?(abil,PBAbilities,:WONDERGUARD) &&
             !isConst?(abil,PBAbilities,:DISGUISE) &&
             !isConst?(abil,PBAbilities,:ZENMODE) &&
             !isConst?(abil,PBAbilities,:SCHOOLING) &&
             !isConst?(abil,PBAbilities,:SHIELDSDOWN) &&
             !isConst?(abil,PBAbilities,:RKSSYSTEM) &&
             !isConst?(abil,PBAbilities,:ICEFACE) &&
             !isConst?(abil,PBAbilities,:GULPMISSILE) &&
             !isConst?(abil,PBAbilities,:ZEROTOHERO)
            usable=true
      end
      if usable
        battlername=pbPartner.pbThis(true)
        abilityname=PBAbilities.getName(abil)
        PBDebug.log("[Ability triggered] #{self.pbThis}'s #{PBAbilities.getName(self.ability)} turned into #{abilityname} from #{battlername}")
        self.ability=abil
        @battle.pbDisplay(_INTL("¡{1} copió {3} de {2}!",pbThis,battlername,abilityname))
      end
    end

    # Hospitalidad
    if self.hasWorkingAbility(:HOSPITALITY) && onactive
      if self.pbPartner && !self.pbPartner.isFainted?
        if self.pbPartner.hp==self.pbPartner.totalhp
          @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",self.pbPartner.pbThis))
        else
          self.pbPartner.pbRecoverHP((self.pbPartner.totalhp/4).round,true)
          @battle.pbDisplay(_INTL("{1} recuperó salud.",self.pbPartner.pbThis))
        end
      end
    end
    # Paleosítensis
    if self.hasWorkingAbility(:PROTOSYNTHESIS) && (@battle.weather==PBWeather::SUNNYDAY || self.hasWorkingItem(:BOOSTERENERGY)) && onactive
      if self.attack >= self.defense &&
        self.attack >= self.spatk &&
        self.attack >= self.spdef &&
        self.attack >= self.speed
        if pbIncreaseStatWithCause(PBStats::ATTACK,1,self,PBAbilities.getName(ability))
         PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Attack)")
        end
      elsif self.defense >= self.spatk &&
          self.defense >= self.spdef &&
          self.defense >= self.speed
          if pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Defense)")
        end
      elsif self.spatk >= self.spdef &&
        self.spatk >= self.speed
          if pbIncreaseStatWithCause(PBStats::SPATK,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Special Attack)")
        end
      elsif self.spdef >= self.speed
          if pbIncreaseStatWithCause(PBStats::SPDEF,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Special Defense)")
        end
      else
        if pbIncreaseStatWithCause(PBStats::SPEED,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Speed)")
        end
      end
    end
    # Carga Cuark
    if self.hasWorkingAbility(:QUARKDRIVE) && (@battle.field.effects[PBEffects::ElectricTerrain]>0 || self.hasWorkingItem(:BOOSTERENERGY)) && onactive
      if self.attack >= self.defense &&
        self.attack >= self.spatk &&
        self.attack >= self.spdef &&
        self.attack >= self.speed
        if pbIncreaseStatWithCause(PBStats::ATTACK,1,self,PBAbilities.getName(ability))
         PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Attack)")
        end
      elsif self.defense >= self.spatk &&
          self.defense >= self.spdef &&
          self.defense >= self.speed
          if pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Defense)")
        end
      elsif self.spatk >= self.spdef &&
        self.spatk >= self.speed
          if pbIncreaseStatWithCause(PBStats::SPATK,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Special Attack)")
        end
      elsif self.spdef >= self.speed
          if pbIncreaseStatWithCause(PBStats::SPDEF,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Special Defense)")
        end
      else
        if pbIncreaseStatWithCause(PBStats::SPEED,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Speed)")
        end
      end
    end

    # Intimidación
    if self.hasWorkingAbility(:INTIMIDATE) && onactive
      PBDebug.log("[Habilidad disparada] Intimidación de #{pbThis}")
      for i in 0...4
        if pbIsOpposing?(i) && !@battle.battlers[i].isFainted?
          unless @battle.battlers[i].hasWorkingAbility(:OBLIVIOUS) ||
             @battle.battlers[i].hasWorkingAbility(:OWNTEMPO) ||
             @battle.battlers[i].hasWorkingAbility(:SCRAPPY)
            @battle.battlers[i].pbReduceAttackStatIntimidate(self)
          end
          if @battle.battlers[i].hasWorkingAbility(:RATTLED)
            if @battle.battlers[i].pbIncreaseStatWithCause(PBStats::SPEED,1,@battle.battlers[i],PBAbilities.getName(@battle.battlers[i].ability))
              PBDebug.log("[Ability triggered] #{@battle.battlers[i].pbThis}'s Rattled")
            end
          end
          if @battle.battlers[i].hasWorkingAbility(:GUARDDOG)
            if @battle.battlers[i].pbIncreaseStatWithCause(PBStats::ATTACK,1,@battle.battlers[i],PBAbilities.getName(@battle.battlers[i].ability))
              PBDebug.log("[Ability triggered] #{@battle.battlers[i].pbThis}'s Rattled")
            end
          end
        end
      end
    end

    # Commander
    if (self.hasWorkingAbility(:COMMANDER) && @battle.doublebattle && pbPartner.isFainted? && self.effects[PBEffects::Commander]!=0)
      if isConst?(pbPartner.species,PBSpecies,:DONDOZO)
        self.effects[PBEffects::Commander]=0
        @battle.pbAnimation(getConst(PBMoves,:DIVE),self,nil)
        @battle.pbDisplay(_INTL("¡{1} ha salido de Dondozo!",pbThis))
      end
    end
    # Néctar dulce
    if self.hasWorkingAbility(:SUPERSWEETSYRUP) && onactive
      PBDebug.log("[Habilidad disparada] Intimidación de #{pbThis}")
      for i in 0...4
        if pbIsOpposing?(i) && !@battle.battlers[i].isFainted?
          if @battle.battlers[i].pbReduceStatWithCause(PBStats::EVASION,1,@battle.battlers[i],PBAbilities.getName(ability))
            PBDebug.log("[Ability triggered] Néctar dulce de #{pbThis} ")
          end
        end
      end
    end
    # Evocarrecuerdos
    if self.hasWorkingAbility(:EMBODYASPECT1) && onactive
      if pbIncreaseStatWithCause(PBStats::SPEED,1,self,PBAbilities.getName(ability))
        PBDebug.log("[Habilidad disparada] Evocarrecuerdos de #{pbThis} (sube el Ataque)")
      end
    end
    if self.hasWorkingAbility(:EMBODYASPECT2) && onactive
      if pbIncreaseStatWithCause(PBStats::ATTACK,1,self,PBAbilities.getName(ability))
        PBDebug.log("[Habilidad disparada] Evocarrecuerdos de #{pbThis} (sube el Ataque)")
      end
    end
    if self.hasWorkingAbility(:EMBODYASPECT3) && onactive
      if pbIncreaseStatWithCause(PBStats::SPDEF,1,self,PBAbilities.getName(ability))
        PBDebug.log("[Habilidad disparada] Evocarrecuerdos de #{pbThis} (sube el Ataque)")
      end
    end
    if self.hasWorkingAbility(:EMBODYASPECT4) && onactive
      if pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBAbilities.getName(ability))
        PBDebug.log("[Habilidad disparada] Evocarrecuerdos de #{pbThis} (sube el Ataque)")
      end
    end
    # Unísono
    if self.hasWorkingAbility(:COSTAR) && onactive
      PBDebug.log("[Habilidad disparada] Medicina Extraña de #{pbThis}")
      for i in 0...4
        if !pbIsOpposing?(i) && @battle.battlers[i]!=self && !@battle.battlers[i].isFainted?
          self.stages[PBStats::ATTACK] = @battle.battlers[i].stages[PBStats::ATTACK]
          self.stages[PBStats::DEFENSE] = @battle.battlers[i].stages[PBStats::DEFENSE]
          self.stages[PBStats::SPEED] = @battle.battlers[i].stages[PBStats::SPEED]
          self.stages[PBStats::SPATK] = @battle.battlers[i].stages[PBStats::SPATK]
          self.stages[PBStats::SPDEF] = @battle.battlers[i].stages[PBStats::SPDEF]
          self.stages[PBStats::ACCURACY] = @battle.battlers[i].stages[PBStats::ACCURACY]
          self.stages[PBStats::EVASION] = @battle.battlers[i].stages[PBStats::EVASION]
          self.effects[PBEffects::FocusEnergy] = @battle.battlers[i].effects[PBEffects::FocusEnergy]
        @battle.pbDisplay(_INTL("¡{1} ha copiado los cambios en las características de {2}!",pbThis,@battle.battlers[i].pbThis))
        end
      end
    end

    # Medicina Extraña
    if self.hasWorkingAbility(:CURIOUSMEDICINE) && onactive
      PBDebug.log("[Habilidad disparada] Medicina Extraña de #{pbThis}")
      for i in 0...4
        if !pbIsOpposing?(i) && @battle.battlers[i]!=self && !@battle.battlers[i].isFainted?
          @battle.battlers[i].stages[PBStats::ATTACK]   = 0
          @battle.battlers[i].stages[PBStats::DEFENSE]  = 0
          @battle.battlers[i].stages[PBStats::SPEED]    = 0
          @battle.battlers[i].stages[PBStats::SPATK]    = 0
          @battle.battlers[i].stages[PBStats::SPDEF]    = 0
          @battle.battlers[i].stages[PBStats::ACCURACY] = 0
          @battle.battlers[i].stages[PBStats::EVASION]  = 0
        @battle.pbDisplay(_INTL("¡Se eliminaron los cambios en las características de {1}!",@battle.battlers[i].pbThis))
        end
      end
    end
    # Descarga
    if self.hasWorkingAbility(:DOWNLOAD) && onactive
      odef=ospdef=0
      if pbOpposing1 && !pbOpposing1.isFainted?
        odef+=pbOpposing1.defense
        ospdef+=pbOpposing1.spdef
      end
      if pbOpposing2 && !pbOpposing2.isFainted?
        odef+=pbOpposing2.defense
        ospdef+=pbOpposing1.spdef
      end
      if ospdef>odef
        if pbIncreaseStatWithCause(PBStats::ATTACK,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Habilidad disparada] Descarga de #{pbThis} (sube el Ataque)")
        end
      else
        if pbIncreaseStatWithCause(PBStats::SPATK,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Habilidad disparada] Descarga de #{pbThis} (sube el Ataque Especial)")
        end
      end
    end
    # Cacheo
    if self.hasWorkingAbility(:FRISK) && @battle.pbOwnedByPlayer?(@index) && onactive
      foes=[]
      foes.push(pbOpposing1) if pbOpposing1.item>0 && !pbOpposing1.isFainted?
      foes.push(pbOpposing2) if pbOpposing2.item>0 && !pbOpposing2.isFainted?
      if USENEWBATTLEMECHANICS
        PBDebug.log("[Habilidad disparada] Cacheo de #{pbThis}") if foes.length>0
        for i in foes
          itemname=PBItems.getName(i.item)
          @battle.pbDisplay(_INTL("¡{1} cacheó a {2} y encontró {3}!",pbThis,i.pbThis(true),itemname))
        end
      elsif foes.length>0
        PBDebug.log("[Habilidad disparada] Cacheo de #{pbThis}")
        foe=foes[@battle.pbRandom(foes.length)]
        itemname=PBItems.getName(foe.item)
        @battle.pbDisplay(_INTL("¡{1} cacheó a su rival y encontró {2}!",pbThis,itemname))
      end
    end
    # Anticipación
    if self.hasWorkingAbility(:ANTICIPATION) && @battle.pbOwnedByPlayer?(@index) && onactive
      PBDebug.log("[Habilidad disparada] #{pbThis} tiene Anticipación")
      found=false
      for foe in [pbOpposing1,pbOpposing2]
        next if foe.isFainted?
        for j in foe.moves
          movedata=PBMoveData.new(j.id)
          eff=PBTypes.getCombinedEffectiveness(movedata.type,type1,type2,@effects[PBEffects::Type3])
          if (movedata.basedamage>0 && eff>8) ||
             (movedata.function==0x70 && eff>0) # OHKO
            found=true
            break
          end
        end
        break if found
      end
      @battle.pbDisplay(_INTL("¡Anticipación de {1} le hizo estremecerse!",pbThis)) if found
    end
    # Forewarn      /  Alerta
    if self.hasWorkingAbility(:FOREWARN) && @battle.pbOwnedByPlayer?(@index) && onactive
      PBDebug.log("[Habilidad disparada] #{pbThis} tiene Alerta")
      highpower=0
      fwmoves=[]
      for foe in [pbOpposing1,pbOpposing2]
        next if foe.isFainted?
        for j in foe.moves
          movedata=PBMoveData.new(j.id)
          power=movedata.basedamage
          power=160 if movedata.function==0x70    # OHKO
          power=150 if movedata.function==0x8B    # Eruption
          power=120 if movedata.function==0x71 || # Counter
                       movedata.function==0x72 || # Mirror Coat
                       movedata.function==0x73 || # Metal Burst
          power=80 if movedata.function==0x6A ||  # SonicBoom
                      movedata.function==0x6B ||  # Dragon Rage
                      movedata.function==0x6D ||  # Night Shade
                      movedata.function==0x6E ||  # Endeavor
                      movedata.function==0x6F ||  # Psywave
                      movedata.function==0x89 ||  # Return
                      movedata.function==0x8A ||  # Frustration
                      movedata.function==0x8C ||  # Crush Grip
                      movedata.function==0x8D ||  # Gyro Ball
                      movedata.function==0x90 ||  # Hidden Power
                      movedata.function==0x96 ||  # Natural Gift
                      movedata.function==0x97 ||  # Trump Card
                      movedata.function==0x98 ||  # Flail
                      movedata.function==0x9A     # Grass Knot
          if power>highpower
            fwmoves=[j.id]; highpower=power
          elsif power==highpower
            fwmoves.push(j.id)
          end
        end
      end
      if fwmoves.length>0
        fwmove=fwmoves[@battle.pbRandom(fwmoves.length)]
        movename=PBMoves.getName(fwmove)
        @battle.pbDisplay(_INTL("¡Alerta de {1} detectó {2}!",pbThis,movename))
      end
    end

    # Semillas
      if self.hasWorkingItem(:ELECTRICSEED) && !self.pbTooHigh?(PBStats::DEFENSE) &&
            @battle.field.effects[PBEffects::ElectricTerrain]>0
        self.pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBItems.getName(self.item))
        self.pbConsumeItem
      end
      if self.hasWorkingItem(:GRASSYSEED) && !self.pbTooHigh?(PBStats::DEFENSE) &&
            @battle.field.effects[PBEffects::GrassyTerrain]>0
        self.pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBItems.getName(self.item))
        self.pbConsumeItem
      end
      if self.hasWorkingItem(:PSYCHICSEED) && !self.pbTooHigh?(PBStats::SPDEF) &&
            @battle.field.effects[PBEffects::PsychicTerrain]>0
        self.pbIncreaseStatWithCause(PBStats::SPDEF,1,self,PBItems.getName(self.item))
        self.pbConsumeItem
      end
      if self.hasWorkingItem(:MISTYSEED) && !self.pbTooHigh?(PBStats::SPDEF) &&
            @battle.field.effects[PBEffects::MistyTerrain]>0
        self.pbIncreaseStatWithCause(PBStats::SPDEF,1,self,PBItems.getName(self.item))
        self.pbConsumeItem
      end

    # Habilidades de campos
    if (self.hasWorkingAbility(:ELECTRICSURGE) || self.hasWorkingAbility(:HADRONENGINE)) &&
      @battle.field.effects[PBEffects::ElectricTerrain]<=0 && onactive
      @battle.field.effects[PBEffects::PsychicTerrain]=0
      @battle.field.effects[PBEffects::GrassyTerrain]=0
      @battle.field.effects[PBEffects::MistyTerrain]=0
      if self.hasWorkingItem(:TERRAINEXTENDER)
        @battle.field.effects[PBEffects::ElectricTerrain]=8
      else
        @battle.field.effects[PBEffects::ElectricTerrain]=5
      end
       # @battle.pbDisplayEffect(self,false)
       # @battle.pbHideEffect(self)
      @battle.pbDisplay(_INTL("¡Se ha formado un campo de corriente eléctrica en el campo de batalla!"))
      PBDebug.log("[#{pbThis} summoned Electric Terrain]")
      for battler in @battle.battlers
        next if battler.isFainted?
        if battler.hasWorkingAbility(:MIMICRY)
          battler.pbActivateMimicry
        end
      end
    end
    # Psychic Surge
    if self.hasWorkingAbility(:PSYCHICSURGE) &&
      @battle.field.effects[PBEffects::PsychicTerrain]<=0 && onactive
      @battle.field.effects[PBEffects::ElectricTerrain]=0
      @battle.field.effects[PBEffects::GrassyTerrain]=0
      @battle.field.effects[PBEffects::MistyTerrain]=0
      if self.hasWorkingItem(:TERRAINEXTENDER)
        @battle.field.effects[PBEffects::PsychicTerrain]=8
      else
        @battle.field.effects[PBEffects::PsychicTerrain]=5
      end

       # @battle.pbDisplayEffect(self,false)
       # @battle.pbHideEffect(self)
      @battle.pbDisplay(_INTL("¡El campo de batalla se volvió extraño!"))
      PBDebug.log("[#{pbThis} summoned Psychic Terrain]")
      for battler in @battle.battlers
        next if battler.isFainted?
        if battler.hasWorkingAbility(:MIMICRY)
          battler.pbActivateMimicry
        end
      end
    end
    # Grassy Surge
    if self.hasWorkingAbility(:GRASSYSURGE) &&
      @battle.field.effects[PBEffects::GrassyTerrain]<=0 && onactive
      @battle.field.effects[PBEffects::ElectricTerrain]=0
      @battle.field.effects[PBEffects::PsychicTerrain]=0
      @battle.field.effects[PBEffects::MistyTerrain]=0
      if self.hasWorkingItem(:TERRAINEXTENDER)
        @battle.field.effects[PBEffects::GrassyTerrain]=8
      else
        @battle.field.effects[PBEffects::GrassyTerrain]=5
      end
       # @battle.pbDisplayEffect(self,false)
       # @battle.pbHideEffect(self)
      @battle.pbDisplay(_INTL("¡El terreno de combate se ha cubierto de hierba!"))
      PBDebug.log("[#{pbThis} summoned Grassy Terrain]")
      for battler in @battle.battlers
        next if battler.isFainted?
        if battler.hasWorkingAbility(:MIMICRY)
          battler.pbActivateMimicry
        end
      end
    end
    # Misty Surge
    if self.hasWorkingAbility(:MISTYSURGE) &&
      @battle.field.effects[PBEffects::MistyTerrain]<=0 && onactive
      @battle.field.effects[PBEffects::ElectricTerrain]=0
      @battle.field.effects[PBEffects::GrassyTerrain]=0
      @battle.field.effects[PBEffects::PsychicTerrain]=0
      if self.hasWorkingItem(:TERRAINEXTENDER)
        @battle.field.effects[PBEffects::MistyTerrain]=8
      else
        @battle.field.effects[PBEffects::MistyTerrain]=5
      end
       # @battle.pbDisplayEffect(self,false)
       # @battle.pbHideEffect(self)
      @battle.pbDisplay(_INTL("¡La niebla ha envuelto el terreno de combate!"))
      PBDebug.log("[#{pbThis}: Misty Surge made Misty Terrain]")
      for battler in @battle.battlers
        next if battler.isFainted?
        if battler.hasWorkingAbility(:MIMICRY)
          battler.pbActivateMimicry
        end
      end
    end
    # Mensaje de Presión
    if self.hasWorkingAbility(:PRESSURE) && onactive
        @battle.pbDisplay(_INTL("¡{1} ejerce su Presión!",pbThis))
    end
    # Mensaje de Rompemoldes
    if self.hasWorkingAbility(:MOLDBREAKER) && onactive
      @battle.pbDisplay(_INTL("¡{1} ha usado rompemoldes!",pbThis))
    end
    # Mensaje de Turbollama
    if self.hasWorkingAbility(:TURBOBLAZE) && onactive
      @battle.pbDisplay(_INTL("¡{1} desprende un aura llameante!",pbThis))
    end
    # Mensaje de Terravoltaje
    if self.hasWorkingAbility(:TERAVOLT) && onactive
      @battle.pbDisplay(_INTL("¡{1} desprende un aura electrizante!",pbThis))
    end
    # Mensaje de Aura Oscura
    if self.hasWorkingAbility(:DARKAURA) && onactive
      @battle.pbDisplay(_INTL("¡{1} iradia un aura oscura!",pbThis))
    end
    # Mensaje de Aura Feérica
    if self.hasWorkingAbility(:FAIRYAURA) && onactive
      @battle.pbDisplay(_INTL("¡{1} iradia un aura feérica!",pbThis))
    end
    # Mensaje de Rompeaura
    if self.hasWorkingAbility(:AURABREAK) && onactive
      @battle.pbDisplay(_INTL("¡{1} revierte las auras de todos los demás Pokémon!",pbThis))
    end
    # Mensaje de Inicio Lento
    if self.hasWorkingAbility(:SLOWSTART) && onactive
      @battle.pbDisplay(_INTL("¡{1} no rinde todo lo que podría!",
         pbThis,PBAbilities.getName(self.ability)))
    end
    if self.species==PBSpecies::TERAPAGOS && self.hasWorkingAbility(:TERASHIFT)
      self.pokemon.form=1
      @battler.pbUpdate(true)
      @battle.scene.pbChangePokemon(self,@pokemon)
      @battle.pbDisplay(_INTL("¡{1} se transformó!",pbThis))
    end
    # Antibarrera
    if self.hasWorkingAbility(:SCREENCLEANER) && onactive
      if self.pbOwnSide.effects[PBEffects::LightScreen]>0 || self.pbOpposingSide.effects[PBEffects::LightScreen]>0 ||
      self.pbOwnSide.effects[PBEffects::Reflect]> 0 || self.pbOpposingSide.effects[PBEffects::Reflect]>0 ||
      self.pbOwnSide.effects[PBEffects::AuroraVeil]>0 || self.pbOpposingSide.effects[PBEffects::AuroraVeil]>0
        if self.pbOwnSide.effects[PBEffects::LightScreen]>0; self.pbOwnSide.effects[PBEffects::LightScreen]=0
          @battle.pbDisplay(_INTL("¡Pantalla Luz dejó de funcionar!"))
        end
        if self.pbOpposingSide.effects[PBEffects::LightScreen]>0; self.pbOpposingSide.effects[PBEffects::LightScreen]=0
          @battle.pbDisplay(_INTL("¡Pantalla Luz dejó de funcionar!"))
        end
        if self.pbOwnSide.effects[PBEffects::Reflect]>0; self.pbOwnSide.effects[PBEffects::Reflect]=0
          @battle.pbDisplay(_INTL("¡Reflejo dejó de funcionar!"))
        end
        if self.pbOpposingSide.effects[PBEffects::Reflect]>0; self.pbOpposingSide.effects[PBEffects::Reflect]=0
          @battle.pbDisplay(_INTL("¡Reflejo dejó de funcionar!"))
        end
        if self.pbOwnSide.effects[PBEffects::AuroraVeil]>0; self.pbOwnSide.effects[PBEffects::AuroraVeil]=0
          @battle.pbDisplay(_INTL("¡Velo Aurora dejó de funcionar!"))
        end
        if self.pbOpposingSide.effects[PBEffects::AuroraVeil]>0; self.pbOpposingSide.effects[PBEffects::AuroraVeil]=0
          @battle.pbDisplay(_INTL("¡Velo Aurora dejó de funcionar!"))
        end
      end
    end
    # Impostor
    if self.hasWorkingAbility(:IMPOSTER) && !@effects[PBEffects::Transform] && onactive
      choice=pbOppositeOpposing
      blacklist=[
         0xC9,    # Fly
         0xCA,    # Dig
         0xCB,    # Dive
         0xCC,    # Bounce
         0xCD,    # Shadow Force
         0xCE,    # Sky Drop
         0x14D    # Phantom Force
      ]
      if choice.effects[PBEffects::Transform] ||
         choice.effects[PBEffects::Illusion] ||
         choice.effects[PBEffects::Substitute]>0 ||
         choice.effects[PBEffects::SkyDrop] ||
         blacklist.include?(PBMoveData.new(choice.effects[PBEffects::TwoTurnAttack]).function)
        PBDebug.log("[Habilidad disparada] Impostor de #{pbThis} no logró la transformación")
      else
        PBDebug.log("[Habilidad disparada] Impostor de #{pbThis}")
        @battle.pbAnimation(getConst(PBMoves,:TRANSFORM),self,choice)
        @effects[PBEffects::Transform]=true
        @type1=choice.type1
        @type2=choice.type2
        @effects[PBEffects::Type3]=-1
        @ability=choice.ability
        @attack=choice.attack
        @defense=choice.defense
        @speed=choice.speed
        @spatk=choice.spatk
        @spdef=choice.spdef
        for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                  PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
          @stages[i]=choice.stages[i]
        end
        for i in 0...4
          @moves[i]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(choice.moves[i].id))
          @moves[i].pp=5
          @moves[i].totalpp=5
        end
        @effects[PBEffects::Disable]=0
        @effects[PBEffects::DisableMove]=0
        @battle.pbDisplay(_INTL("¡{1} se transformó en {2}!",pbThis,choice.pbThis(true)))
        PBDebug.log("[Pokémon transformado] #{pbThis} se transformó en #{choice.pbThis(true)}")
      end
    end
    # Velo Pastel
    if self.hasWorkingAbility(:PASTELVEIL) && @battle.doublebattle && !pbPartner.isFainted? && onactive
      if pbPartner.status==PBStatuses::POISON
        PBDebug.log("[Ability triggered] #{pbThis}'s Pastel Veil")
        @battle.pbDisplay(_INTL("¡{1} se ha curado del envenenamiento!",pbPartner.pbThis))
        pbPartner.status=0
        pbPartner.statusCount=0
      end
    end
    # Commander
    if self.hasWorkingAbility(:COMMANDER) && @battle.doublebattle && !pbPartner.isFainted? && onactive && self.effects[PBEffects::Commander]==0
      if isConst?(pbPartner.species,PBSpecies,:DONDOZO)
        PBDebug.log("[Ability triggered] #{pbThis}'s Commander")
        self.effects[PBEffects::Commander]=1
        pbPartner.effects[PBEffects::FollowMe]=self.effects[PBEffects::FollowMe]+1
        @battle.pbAnimation(getConst(PBMoves,:DIVE),self,nil)
        @battle.pbDisplay(_INTL("¡{1} se ha metido en la boca de Dondozo!",pbThis))
        if pbPartner.pbIncreaseStatWithCause(PBStats::ATTACK,2,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Commander (raising Attack)")
        end
        if pbPartner.pbIncreaseStatWithCause(PBStats::DEFENSE,2,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Commander (raising Defense)")
        end
        if pbPartner.pbIncreaseStatWithCause(PBStats::SPATK,2,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Commander (raising Sp Atck)")
        end
        if pbPartner.pbIncreaseStatWithCause(PBStats::SPDEF,2,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Commander (raising Sp Def)")
        end
        if pbPartner.pbIncreaseStatWithCause(PBStats::SPEED,2,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Commander (raising Speed)")
        end
      end
    end
    if isConst?(pbPartner.species,PBSpecies,:TATSUGIRI) && !isConst?(self.species,PBSpecies,:DONDOZO) && !pbPartner.isFainted? && onactive && pbPartner.effects[PBEffects::Commander]!=0
      pbPartner.effects[PBEffects::Commander]=0
      @battle.pbAnimation(getConst(PBMoves,:DIVE),pbPartner,nil)
      @battle.pbDisplay(_INTL("¡Tatsugiri ha salido de la boca de Dondozo!"))
    end
    # Mensaje de Gas Reactivo
    if isConst?(self.ability,PBAbilities,:NEUTRALIZINGGAS) && onactive
      @battle.pbDisplay(_INTL("¡Un gas reactivo se propaga por toda la zona!"))
      PBDebug.log("[#{pbThis} summoned Neutralizing Gas]")
    end
    # Escudo Recio
    if self.hasWorkingAbility(:DAUNTLESSSHIELD) && onactive
      if pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBAbilities.getName(ability))
        PBDebug.log("[Ability triggered] #{pbThis}'s Dauntless Shield (raising Defense)")
      end
    end
    # Espada Indómita
    if self.hasWorkingAbility(:INTREPIDSWORD) && onactive
      if pbIncreaseStatWithCause(PBStats::ATTACK,1,self,PBAbilities.getName(ability))
        PBDebug.log("[Ability triggered] #{pbThis}'s Intrepid Sword (raising Attack)")
      end
    end
    # Mensaje del Globo Helio
    if self.hasWorkingItem(:AIRBALLOON) && onactive
      @battle.pbDisplay(_INTL("¡{1} está flotando en el aire gracias a su {2}!",pbThis,PBItems.getName(self.item)))
    end
    # Mimicry
    if self.hasWorkingAbility(:MIMICRY)
      self.pbActivateMimicry
    end
  end

  def pbEffectsOnDealingDamage(move,user,target,damage)
    movetype=move.pbType(move.type,user,target)
    if damage>0 && move.isContactMove? && !user.hasWorkingAbility(:LONGREACH) &&
      !user.hasWorkingItem(:PROTECTIVEPADS) && (!user.hasWorkingItem(:PUNCHINGGLOVE) && !move.isPunchingMove?)
      if !target.damagestate.substitute
        # Rizos Rebeldes
        if target.hasWorkingAbility(:TANGLINGHAIR,true)
          if user.pbReduceStatWithCause(PBStats::SPEED,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Tangling Hair")
          end
        end
        # Toxiestrella
        if target.hasWorkingItem(:STICKYBARB,true) && user.item==0 && !user.isFainted?          # Toxiestrella
          user.item=target.item
          target.item=0
          target.effects[PBEffects::Unburden]=true
          if !@battle.opponent && !@battle.pbIsOpposing?(user.index)
            if user.pokemon.itemInitial==0 && target.pokemon.itemInitial==user.item
              user.pokemon.itemInitial=user.item
              target.pokemon.itemInitial=0
            end
          end
          @battle.pbDisplay(_INTL("¡{2} de {1} fue transferida a {3}!",
             target.pbThis,PBItems.getName(user.item),user.pbThis(true)))
          PBDebug.log("[Objeto disparado] Toxiestrella de #{target.pbThis} fue pasada a #{user.pbThis(true)}")
        end
        # Casco Dentado
        if target.hasWorkingItem(:ROCKYHELMET,true) && !user.isFainted?                  # Casco Dentado
          if !user.hasWorkingAbility(:MAGICGUARD)
            PBDebug.log("[Objeto disparado] Casco Dentado de #{target.pbThis}")
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP((user.totalhp/6).floor)
            @battle.pbDisplay(_INTL("¡{1} fue dañado por {2}!",user.pbThis,
               PBItems.getName(target.item)))
          end
        end
        if @battle.choices[target.index][0]==1
          targetmove=@battle.choices[target.index][2]
          if targetmove.function==0x1BC &&                                               # Beak Blast
           move.isContactMove? && user.pbCanBurn?(false,targetmove,target)
            user.pbBurn(target)
          end
          if targetmove.function==0x193 && move.pbIsPhysical?(user)                      # Shell Trap
            target.effects[PBEffects::ShellTrap]=true
          end
        end
        # Resquicio
        if target.hasWorkingAbility(:AFTERMATH,true) && target.isFainted? &&             # Resquicio
           !user.isFainted?
          if !@battle.pbCheckGlobalAbility(:DAMP) &&
             !user.hasMoldBreaker && !user.hasWorkingAbility(:MAGICGUARD)
            PBDebug.log("[Habilidad disparada] Resquicio de #{target.pbThis}")
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP((user.totalhp/4).floor)
            @battle.pbDisplay(_INTL("¡{1} fue dañado por Resquicio del rival!",user.pbThis))
          end
        end
        # Gran Encanto
        if target.hasWorkingAbility(:CUTECHARM) && @battle.pbRandom(10)<3                # Gran Encanto
          if !user.isFainted? && user.pbCanAttract?(target,false)
            PBDebug.log("[Habilidad disparada] # Gran Encanto de #{target.pbThis}")
            user.pbAttract(target,_INTL("¡{2} de {1} enamoró a {3}!",target.pbThis,
               PBAbilities.getName(target.ability),user.pbThis(true)))
          end
        end
        # Efecto Espora
        if target.hasWorkingAbility(:EFFECTSPORE,true) && @battle.pbRandom(10)<3         # Efecto Espora
          if USENEWBATTLEMECHANICS &&
             (user.pbHasType?(:GRASS) ||
             user.hasWorkingAbility(:OVERCOAT) ||
             user.hasWorkingItem(:SAFETYGOGGLES))
          else
            PBDebug.log("[Habilidad disparada] Efecto Espora de #{target.pbThis}")
            case @battle.pbRandom(3)
            when 0
              if user.pbCanPoison?(nil,false)
                user.pbPoison(target,_INTL("¡{2} de {1} envenenó a {3}!",target.pbThis,
                   PBAbilities.getName(target.ability),user.pbThis(true)))
              end
            when 1
              if user.pbCanSleep?(nil,false)
                user.pbSleep(_INTL("¡{2} de {1} durmió a {3}!",target.pbThis,
                   PBAbilities.getName(target.ability),user.pbThis(true)))
              end
            when 2
              if user.pbCanParalyze?(nil,false)
                user.pbParalyze(target,_INTL("¡{2} de {1} paralizó a {3}! ¡Quizás no pueda moverse!",
                   target.pbThis,PBAbilities.getName(target.ability),user.pbThis(true)))
              end
            end
          end
        end
        # Cuerpo Llama
        if target.hasWorkingAbility(:FLAMEBODY,true) && @battle.pbRandom(10)<3 &&        # Cuerpo Llama
           user.pbCanBurn?(nil,false)
          PBDebug.log("[Habilidad disparada] Cuerpo Llama fr #{target.pbThis}")
          user.pbBurn(target,_INTL("¡{2} de {1} quemó a {3}!",target.pbThis,
             PBAbilities.getName(target.ability),user.pbThis(true)))
        end
        # Momia
        if target.hasWorkingAbility(:MUMMY,true) && !user.isFainted? && !user.hasWorkingItem(:ABILITYSHIELD)
          if !isConst?(user.ability,PBAbilities,:MULTITYPE) &&
             !isConst?(user.ability,PBAbilities,:STANCECHANGE) &&
             !isConst?(user.ability,PBAbilities,:MUMMY) &&
             !isConst?(user.ability,PBAbilities,:COMATOSE) &&
             !isConst?(user.ability,PBAbilities,:SCHOOLING) &&
             !isConst?(user.ability,PBAbilities,:DISGUISE) &&
             !isConst?(user.ability,PBAbilities,:BATTLEBOND) &&
             !isConst?(user.ability,PBAbilities,:POWERCONSTRUCT) &&
             !isConst?(user.ability,PBAbilities,:SHIELDSDOWN) &&
             !isConst?(user.ability,PBAbilities,:RKSSYSTEM)  &&
             !isConst?(user.ability,PBAbilities,:ZEROTOHERO)
            PBDebug.log("[Habilidad disparada] La habilidad Momia de #{target.pbThis} ha sido copiada en #{user.pbThis(true)}")
            user.ability=getConst(PBAbilities,:MUMMY) || 0
            @battle.pbDisplay(_INTL("¡{1} ha sido momificado por {2}!",
               user.pbThis,target.pbThis(true)))
          end
        end
        # Olor Persistente
        if target.hasWorkingAbility(:LINGERINGAROMA,true) && !user.isFainted? && !user.hasWorkingItem(:ABILITYSHIELD)
          if !isConst?(user.ability,PBAbilities,:MULTITYPE) &&
             !isConst?(user.ability,PBAbilities,:STANCECHANGE) &&
             !isConst?(user.ability,PBAbilities,:COMATOSE) &&
             !isConst?(user.ability,PBAbilities,:SCHOOLING) &&
             !isConst?(user.ability,PBAbilities,:DISGUISE) &&
             !isConst?(user.ability,PBAbilities,:BATTLEBOND) &&
             !isConst?(user.ability,PBAbilities,:POWERCONSTRUCT) &&
             !isConst?(user.ability,PBAbilities,:SHIELDSDOWN) &&
             !isConst?(user.ability,PBAbilities,:RKSSYSTEM) &&
             !isConst?(user.ability,PBAbilities,:ICEFACE) &&
             !isConst?(user.ability,PBAbilities,:ZEROTOHERO) &&
             !isConst?(user.ability,PBAbilities,:LINGERINGAROMA)
            PBDebug.log("[Habilidad disparada] La habilidad Olor Persistente de #{target.pbThis} ha sido copiada en #{user.pbThis(true)}")
            user.ability=getConst(PBAbilities,:LINGERINGAROMA) || 0
            @battle.pbDisplay(_INTL("¡A {1} se le ha pegado el olor de {2}!",
               user.pbThis,target.pbThis(true)))
          end
        end
        # Alma Errante
        if target.hasWorkingAbility(:WANDERINGSPIRIT,true) && !user.isFainted? && !user.hasWorkingItem(:ABILITYSHIELD)
          if !isConst?(user.ability,PBAbilities,:WANDERINGSPIRIT) &&
             !isConst?(user.ability,PBAbilities,:MULTITYPE)       &&
             !isConst?(user.ability,PBAbilities,:STANCECHANGE)    &&
             !isConst?(user.ability,PBAbilities,:BATTLEBOND)      &&
             !isConst?(user.ability,PBAbilities,:SCHOOLING)       &&
             !isConst?(user.ability,PBAbilities,:COMATOSE)        &&
             !isConst?(user.ability,PBAbilities,:DISGUISE)        &&
             !isConst?(user.ability,PBAbilities,:RKSSYSTEM)       &&
             !isConst?(user.ability,PBAbilities,:SHIELDSDOWN)     &&
             !isConst?(user.ability,PBAbilities,:ICEFACE)         &&
             !isConst?(user.ability,PBAbilities,:ZEROTOHERO)
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Wandering Spirit swap onto #{user.pbThis(true)}'s Ability")
            tmp=user.ability
            user.ability=target.ability
            target.ability=tmp
            @battle.pbDisplay(_INTL("{1} ha intercambiado su habilidad con la de su objetivo!",target.pbThis))
            user.pbAbilitiesOnSwitchIn(true)
            target.pbAbilitiesOnSwitchIn(true)
          end
        end
        # Punto Tóxico
        if target.hasWorkingAbility(:POISONPOINT,true) && @battle.pbRandom(10)<3 &&      # Punto Tóxico
           user.pbCanPoison?(nil,false)
          PBDebug.log("[Habilidad disparada] Punto Tóxico de #{target.pbThis}")
          user.pbPoison(target,_INTL("¡{2} de {1} envenenó a {3}!",target.pbThis,
             PBAbilities.getName(target.ability),user.pbThis(true)))
        end
        # Piel Tosca / Punta Acero
        if (target.hasWorkingAbility(:ROUGHSKIN,true) ||                                 #  Piel Tosca
           target.hasWorkingAbility(:IRONBARBS,true)) && !user.isFainted?
          if !user.hasWorkingAbility(:MAGICGUARD)
            PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(target.ability)} de #{target.pbThis}")
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP((user.totalhp/8).floor)
            @battle.pbDisplay(_INTL("¡{2} de {1} hirió a {3}!",target.pbThis,
               PBAbilities.getName(target.ability),user.pbThis(true)))
          end
        end
        # Elec. Estática
        if target.hasWorkingAbility(:STATIC,true) && @battle.pbRandom(10)<3 &&           # Electricidad Estática
           user.pbCanParalyze?(nil,false)
          PBDebug.log("[Habilidad disparada] Electricidad Estática de #{target.pbThis}")
          user.pbParalyze(target,_INTL("¡{2} de {1} paralizó a {3}! ¡Quizás no pueda moverse!",
             target.pbThis,PBAbilities.getName(target.ability),user.pbThis(true)))
           end
        # Baba
        if target.hasWorkingAbility(:GOOEY,true)
          if user.pbReduceStatWithCause(PBStats::SPEED,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Baba de #{target.pbThis}")
          end
        end
        # Toque Tóxico
        if user.hasWorkingAbility(:POISONTOUCH,true) &&
           target.pbCanPoison?(nil,false) && @battle.pbRandom(10)<3
          PBDebug.log("[Habilidad disparada] Toque Tóxico de #{user.pbThis}")
          target.pbPoison(user,_INTL("¡{2} de {1} envenenó a {3}!",user.pbThis,
             PBAbilities.getName(user.ability),target.pbThis(true)))
        end
        # Cuerpo Mortal
        if target.hasWorkingAbility(:PERISHBODY,true) && !user.hasMoldBreaker &&
           user.effects[PBEffects::PerishBody]==0 && target.effects[PBEffects::PerishBody]==0
          @battle.pbDisplay(_INTL("¡Ambos Pokémon se debilitarán en tres turnos!"))
          user.effects[PBEffects::PerishBody]=3; target.effects[PBEffects::PerishBody]=3
        end
      end
    end
    if damage>0
      if !target.damagestate.substitute
        # Cadena Tóxica
        if user.hasWorkingAbility(:TOXICCHAIN,true) &&
           target.pbCanPoison?(nil,false) && @battle.pbRandom(10)<3
          PBDebug.log("[Habilidad disparada] Cadena Tóxica de #{user.pbThis}")
          target.pbPoison(user,_INTL("¡{2} de {1} envenenó a {3}!",user.pbThis,
             PBAbilities.getName(user.ability),target.pbThis(true)))
        end
        # Cuerpo Maldito
        if target.hasWorkingAbility(:CURSEDBODY,true) && @battle.pbRandom(10)<3      # Cuerpo Maldito
          if user.effects[PBEffects::Disable]<=0 && move.pp>0 && !user.isFainted?
            user.effects[PBEffects::Disable]=4
            user.effects[PBEffects::DisableMove]=move.id
            @battle.pbDisplay(_INTL("¡{2} de {1} ha desactivado el movimiento de {3}!",target.pbThis,
               PBAbilities.getName(target.ability),user.pbThis(true)))
            PBDebug.log("[Habilidad disparada] Cuerpo Maldito de #{target.pbThis} ha desactivado el movimiento de #{user.pbThis(true)}")
          end
        end
        # Capa Tóxica
        if target.hasWorkingAbility(:TOXICDEBRIS) && move.pbIsPhysical?(movetype) &&
          user.pbOwnSide.effects[PBEffects::ToxicSpikes]<=1

          @battle.pbAnimation(getConst(PBMoves,:TOXICSPIKES),target,nil)
          user.pbOwnSide.effects[PBEffects::ToxicSpikes]+=1
          if !@battle.pbIsOpposing?(user.index)
            @battle.pbDisplay(_INTL("¡El equipo enemigo ha sido rodeado de púas venenosas!"))
          else
            @battle.pbDisplay(_INTL("¡Tu equipo ha sido rodeado de púas venenosas!"))
          end
        end
        # Firmeza
        if target.hasWorkingAbility(:STAMINA)
          if target.pbIncreaseStatWithCause(PBStats::DEFENSE,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Stamina")
          end
        end
        # Hidrorrefuerzo
        if target.hasWorkingAbility(:WATERCOMPACTION) && isConst?(movetype,PBTypes,:WATER)
          if target.pbIncreaseStatWithCause(PBStats::DEFENSE,2,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Water Composition")
          end
        end
        # Justiciero
        if target.hasWorkingAbility(:JUSTIFIED) && isConst?(movetype,PBTypes,:DARK)    # Justiciero
          if target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Justiciero de #{target.pbThis}")
          end
        end

        # Cólera
        if target.hasWorkingAbility(:BERSERK) &&
            target.hp+damage>target.totalhp/2 &&
            target.hp<target.totalhp/2
          if target.pbIncreaseStatWithCause(PBStats::SPATK,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Stamina")
          end
        end
        # Cobardía
        if target.hasWorkingAbility(:RATTLED) &&
           (isConst?(movetype,PBTypes,:BUG) ||
            isConst?(movetype,PBTypes,:DARK) ||
            isConst?(movetype,PBTypes,:GHOST))
          if target.pbIncreaseStatWithCause(PBStats::SPEED,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Cobardía de #{target.pbThis}")
          end
        end
        # Armadura Frágil
        if target.hasWorkingAbility(:WEAKARMOR) && move.pbIsPhysical?(movetype)
          if target.pbReduceStatWithCause(PBStats::DEFENSE,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Armadura Frágil de #{target.pbThis} (baja Defensa)")
          end
          if target.pbIncreaseStatWithCause(PBStats::SPEED,2,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Armadura Frágil de #{target.pbThis} (sube Velocidad)")
          end
        end
        # Expulsarena
        if target.hasWorkingAbility(:SANDSPIT)
          if @battle.weather!=PBWeather::HEAVYRAIN && @battle.weather!=PBWeather::HARSHSUN &&
             @battle.weather!=PBWeather::STRONGWINDS && @battle.weather!=PBWeather::SANDSTORM
            @battle.weather=PBWeather::SANDSTORM
            @battle.weatherduration=5
            @battle.weatherduration=8 if target.hasWorkingItem(:SMOOTHROCK)
            @battle.pbCommonAnimation("Sandstorm",nil,nil)
            @battle.pbDisplay(_INTL("¡Se acerca una tormenta de arena!"))
          end
        end
        # Energía Eólica
        if target.hasWorkingAbility(:WINDPOWER) && move.isWindMove?
          target.effects[PBEffects::Charge]=2
          @battle.pbAnimation(getConst(PBMoves,:CHARGE),target,nil)
          @battle.pbDisplay(_INTL("¡{1} comenzó a cargar energía!",target.pbThis))
        end
        # Dinamo
        if target.hasWorkingAbility(:ELECTROMORPHOSIS)
          target.effects[PBEffects::Charge]=2
          @battle.pbDisplay(_INTL("¡{1} comenzó a cargar energía!",target.pbThis))
        end
        # Surcavientos
        if target.hasWorkingAbility(:WINDRIDER) && move.isWindMove?
          if target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Wind Rider de #{target.pbThis}")
          end
        end
        # Termoconversión
        if target.hasWorkingAbility(:THERMALEXCHANGE) && isConst?(movetype,PBTypes,:FIRE)
          if target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Habilidad disparada] Termoconversión de #{target.pbThis}")
          end
        end
        # Coraza Ira
        if target.hasWorkingAbility(:ANGERSHELL) &&
            target.hp+damage>target.totalhp/2 &&
            target.hp<target.totalhp/2
          if target.pbCanIncreaseStatStage?(PBStats::ATTACK,target) &&
             target.pbCanIncreaseStatStage?(PBStats::SPATK,target) &&
             target.pbCanIncreaseStatStage?(PBStats::SPEED,target)
            target.pbReduceStatWithCause(PBStats::DEFENSE,1,target,PBAbilities.getName(target.ability))
            target.pbReduceStatWithCause(PBStats::SPDEF,1,target,PBAbilities.getName(target.ability))
            target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,PBAbilities.getName(target.ability))
            target.pbIncreaseStatWithCause(PBStats::SPATK,1,target,PBAbilities.getName(target.ability))
            target.pbIncreaseStatWithCause(PBStats::SPEED,1,target,PBAbilities.getName(target.ability))
          end
          PBDebug.log("[Ability triggered] #{target.pbThis}'s Anger Shell")
        end
        # Disemillar
          if target.hasWorkingAbility(:SEEDSOWER) &&
              @battle.field.effects[PBEffects::GrassyTerrain]<=0
              @battle.field.effects[PBEffects::ElectricTerrain]=0
              @battle.field.effects[PBEffects::PsychicTerrain]=0
              @battle.field.effects[PBEffects::MistyTerrain]=0
            if self.hasWorkingItem(:TERRAINEXTENDER)
              @battle.field.effects[PBEffects::GrassyTerrain]=8
            else
              @battle.field.effects[PBEffects::GrassyTerrain]=5
            end
            @battle.pbDisplay(_INTL("¡El terreno de combate se ha cubierto de hierba!"))
            PBDebug.log("[#{pbThis} summoned Grassy Terrain]")
            for battler in @battle.battlers
              next if battler.isFainted?
              if battler.hasWorkingAbility(:MIMICRY)
                battler.pbActivateMimicry
             end
           end
        end
        # Pelusa
        if target.hasWorkingAbility(:COTTONDOWN)
          for i in 0...4
            if @battle.battlers[i]!=target
              if @battle.battlers[i].pbReduceStatWithCause(PBStats::SPEED,1,target,PBAbilities.getName(target.ability))
                PBDebug.log("[Ability triggered] #{target.pbThis}'s Cotton Down")
              end
            end
          end
        end
        # Combustible
        if target.hasWorkingAbility(:STEAMENGINE) &&
          (isConst?(movetype,PBTypes,:WATER) || isConst?(movetype,PBTypes,:FIRE))
          if target.pbIncreaseStatWithCause(PBStats::SPEED,6,target,PBAbilities.getName(target.ability))
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Steam Engine")
          end
        end
        # Tragamisil
        if target.hasWorkingAbility(:GULPMISSILE,true) && isConst?(target.species,PBSpecies,:CRAMORANT) &&
           target.form!=0 && !(PBMoveData.new(target.effects[PBEffects::TwoTurnAttack]).function==0xCB)
          lowerspeed=false; lowerspeed=true if target.form==1 # Gulping Form (Arrokuda)
          paralyze=false; paralyze=true if target.form==2     # Gorging Form (Pikachu)
          target.form=0
          @battle.scene.pbChangePokemon(target,target.pokemon)
          @battle.pbAnimation(getConst(PBMoves,:TACKLE),user,nil)
          user.pbReduceHP((user.totalhp/4).floor) if !user.hasWorkingAbility(:MAGICGUARD)
          PBDebug.log("[Form changed] #{pbThis} changed to #{self.form}")
          if lowerspeed
            if user.pbCanReduceStatStage?(PBStats::DEFENSE,user)
              user.pbReduceStat(PBStats::DEFENSE,1,user,true)
            end
          elsif paralyze && user.status==0
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Gulp Missile")
            user.pbParalyze(target,nil)
          end
        end
        # Globo Helio
        if target.hasWorkingItem(:AIRBALLOON,true)
          PBDebug.log("[Objeto disparado] Globo Helio de #{target.pbThis} ha reventado")
          @battle.pbDisplay(_INTL("¡Ha explotado el Globo Helio de {1}!",target.pbThis))
          target.pbConsumeItem(true,false)
        # Tubérculo
        elsif target.hasWorkingItem(:ABSORBBULB) && isConst?(movetype,PBTypes,:WATER)    # Tubérculo
          if target.pbIncreaseStatWithCause(PBStats::SPATK,1,target,PBItems.getName(target.item))
            PBDebug.log("[Objeto disparado] #{PBItems.getName(target.item)} de #{target.pbThis}")
            target.pbConsumeItem
          end
        # Musgo Brillante
        elsif target.hasWorkingItem(:LUMINOUSMOSS) && isConst?(movetype,PBTypes,:WATER)  # Musgo Brillante
          if target.pbIncreaseStatWithCause(PBStats::SPDEF,1,target,PBItems.getName(target.item))
            PBDebug.log("[Objeto disparado] #{PBItems.getName(target.item)} de #{target.pbThis}")
            target.pbConsumeItem
          end
        # Pila
        elsif target.hasWorkingItem(:CELLBATTERY) && isConst?(movetype,PBTypes,:ELECTRIC)  # Pila
          if target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,PBItems.getName(target.item))
            PBDebug.log("[Objeto disparado] #{PBItems.getName(target.item)} de #{target.pbThis}")
            target.pbConsumeItem
          end
        # Bola de Nieve
        elsif target.hasWorkingItem(:SNOWBALL) && isConst?(movetype,PBTypes,:ICE)          # Bola de Nieve
          if target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,PBItems.getName(target.item))
            PBDebug.log("[Objeto disparado] #{PBItems.getName(target.item)} de #{target.pbThis}")
            target.pbConsumeItem
          end
        # Seguro Debilidad
        elsif target.hasWorkingItem(:WEAKNESSPOLICY) && target.damagestate.typemod>8     # Seguro Debilidad
          showanim=true
          if !target.hasWorkingAbility(:DISGUISE) || target.form!=0
           if target.pbIncreaseStatWithCause(PBStats::ATTACK,2,target,PBItems.getName(target.item),showanim)
            PBDebug.log("[Objeto disparado] Seguro Debilidad de #{target.pbThis} (Ataque)")
            showanim=false
           end
           if target.pbIncreaseStatWithCause(PBStats::SPATK,2,target,PBItems.getName(target.item),showanim)
            PBDebug.log("[Objeto disparado] Seguro Debilidad de #{target.pbThis} (Ataque Especial)")
            showanim=false
           end
          end
          target.pbConsumeItem if !showanim
        # Espray Bucal
        elsif user.hasWorkingItem(:THROATSPRAY) && move.isSoundBased?
          if user.pbIncreaseStatWithCause(PBStats::SPATK,1,user,PBItems.getName(user.item))
            PBDebug.log("[Item triggered] #{user.pbThis}'s #{PBItems.getName(user.item)}")
            user.pbConsumeItem
          end
        elsif target.hasWorkingItem(:ENIGMABERRY) && target.damagestate.typemod>8          # Baya Enigma
          target.pbActivateBerryEffect
        elsif (target.hasWorkingItem(:JABOCABERRY) && move.pbIsPhysical?(movetype)) ||     # Baya Jaboca
              (target.hasWorkingItem(:ROWAPBERRY) && move.pbIsSpecial?(movetype))          # Baya Magua
          if !user.hasWorkingAbility(:MAGICGUARD) && !user.isFainted?                      # Muro Mágico
            PBDebug.log("[Objeto disparado] #{PBItems.getName(target.item)} de #{target.pbThis}")
            @battle.scene.pbDamageAnimation(user,0)
            user.pbReduceHP((user.totalhp/8).floor)
            @battle.pbDisplay(_INTL("¡{1} usó su {2} y dañó a {3}!",target.pbThis,
               PBItems.getName(target.item),user.pbThis(true)))
            target.pbConsumeItem
          end
        elsif target.hasWorkingItem(:KEEBERRY) && move.pbIsPhysical?(movetype)
          target.pbActivateBerryEffect
        elsif target.hasWorkingItem(:MARANGABERRY) && move.pbIsSpecial?(movetype)
          target.pbActivateBerryEffect
        end
      end
      # Irascible
      if target.hasWorkingAbility(:ANGERPOINT)
        if target.damagestate.critical && !target.damagestate.substitute &&
           target.pbCanIncreaseStatStage?(PBStats::ATTACK,target)
          PBDebug.log("[Habilidad disparada] Irascible de #{target.pbThis}")
          target.stages[PBStats::ATTACK]=6
          @battle.pbCommonAnimation("StatUp",target,nil)
          @battle.pbDisplay(_INTL("¡{2} de {1} subió al máximo su {3}!",
             target.pbThis,PBAbilities.getName(target.ability),PBStats.getName(PBStats::ATTACK)))
        end
      end
    end
    user.pbAbilityCureCheck
    target.pbAbilityCureCheck
  end

  def pbEffectsAfterHit(user,target,thismove,turneffects)
    return if turneffects[PBEffects::TotalDamage]==0
    if user.hasWorkingAbility(:WATERBUBBLE) && user.status==PBStatuses::BURN
      PBDebug.log("[Habilidad disparada] #{pbThis}'s #{PBAbilities.getName(@ability)}")
      pbCureStatus(false)
      @battle.pbDisplay(_INTL("Pompa de {1} evitó la quemadura",pbThis,PBAbilities.getName(user.ability))) if showMessages
    end
    if !(user.hasWorkingAbility(:SHEERFORCE) && thismove.addlEffect>0)
      # Objetos de objetivos:
      # Tarjeta Roja
      if target.hasWorkingItem(:REDCARD) && @battle.pbCanSwitch?(user.index,-1,false)
        user.effects[PBEffects::Roar]=true
        @battle.pbDisplay(_INTL("¡{1} ha sacado una {2} a {3}!",
           target.pbThis,PBItems.getName(target.item),user.pbThis(true)))
        target.pbConsumeItem
      # Botón Escape
      elsif target.hasWorkingItem(:EJECTBUTTON) && @battle.pbCanChooseNonActive?(target.index)
        target.effects[PBEffects::Uturn]=true
        @battle.pbDisplay(_INTL("¡{1} regresa gracias al {2}!",
           target.pbThis,PBItems.getName(target.item)))
        target.pbConsumeItem
      end
      # Objetos de usuario:
      # Campana Concha
      if user.hasWorkingItem(:SHELLBELL) && user.effects[PBEffects::HealBlock]==0
        PBDebug.log("[Objeto disparado] #{user.pbThis}'s Shell Bell (total damage=#{turneffects[PBEffects::TotalDamage]})")
        hpgain=user.pbRecoverHP((turneffects[PBEffects::TotalDamage]/8).floor,true)
        if hpgain>0
          @battle.pbDisplay(_INTL("¡{1} ha recuperado unos pocos PS con {2}!",
             user.pbThis,PBItems.getName(user.item)))
        end
      end
      # Vidasfera
      if user.effects[PBEffects::LifeOrb] && !user.hasWorkingAbility(:MAGICGUARD)
        PBDebug.log("[Objeto disparado] #{user.pbThis}'s Life Orb (recoil)")
        hploss=user.pbReduceHP((user.totalhp/10).floor,true)
        if hploss>0
          @battle.pbDisplay(_INTL("¡{1} ha perdido algunos de sus PS!",user.pbThis))
        end
      end
      user.pbFaint if user.isFainted? # no return
      # Cambio Color
      movetype=thismove.pbType(thismove.type,user,target)
      if target.hasWorkingAbility(:COLORCHANGE) && !target.isTera? &&
         !PBTypes.isPseudoType?(movetype) && !target.pbHasType?(movetype)
        PBDebug.log("[Habilidad disparada] Cambio Color de #{target.pbThis} cambió al tipo #{PBTypes.getName(movetype)}")
        target.type1=movetype
        target.type2=movetype
        target.effects[PBEffects::Type3]=-1
        @battle.pbDisplay(_INTL("¡{2} de {1} ha cambiado su tipo a {3}!",target.pbThis,
           PBAbilities.getName(target.ability),PBTypes.getName(movetype)))
      end
    end
    # Vigilante
    if user.hasWorkingAbility(:STAKEOUT) && target.effects[PBEffects::Stakeout]
      PBDebug.log("[Ability triggered] #{user.pbThis}'s Stakeout worked")
      @battle.pbDisplay(_INTL("¡Vigilante de {1} potenció el ataque!",user.pbThis))
    end
    # Autoestima
    if user.hasWorkingAbility(:MOXIE) && target.isFainted?
      if user.pbIncreaseStatWithCause(PBStats::ATTACK,1,user,PBAbilities.getName(user.ability))
        PBDebug.log("[Habilidad disparada] Autoestima de #{user.pbThis}")
      end
    end
    # Relincho Blanco
    if user.hasWorkingAbility(:CHILLINGNEIGH) && target.isFainted?
      if user.pbIncreaseStatWithCause(PBStats::ATTACK,1,user,PBAbilities.getName(user.ability))
        PBDebug.log("[Habilidad disparada] Relincho Blanco de #{user.pbThis}")
      end
    end
    # Unidad Ecuestre (Glacial)
    if user.hasWorkingAbility(:ASONE1) && target.isFainted?
      if user.pbIncreaseStatWithCause(PBStats::ATTACK,1,user,PBAbilities.getName(user.ability))
        PBDebug.log("[Habilidad disparada] Relincho Blanco de #{user.pbThis}")
      end
    end
    # Relincho Negro
    if user.hasWorkingAbility(:GRIMNEIGH) && target.isFainted?
      if user.pbIncreaseStatWithCause(PBStats::SPATK,1,user,PBAbilities.getName(user.ability))
        PBDebug.log("[Habilidad disparada] Relincho Negro de #{user.pbThis}")
      end
    end
    # Unidad Ecuestre (Espectral)
    if user.hasWorkingAbility(:ASONE2) && target.isFainted?
      if user.pbIncreaseStatWithCause(PBStats::SPATK,1,user,PBAbilities.getName(user.ability))
        PBDebug.log("[Habilidad disparada] Relincho Negro de #{user.pbThis}")
      end
    end
    # Fuerte Afecto
    if isConst?(user.species,PBSpecies,:GRENINJA) && user.hasWorkingAbility(:BATTLEBOND)
      if target.isFainted? && user.form!=1
        user.form=1
        pbUpdate(true)
        @battle.scene.pbChangePokemon(user,user.pokemon)
        @battle.pbDisplay(_INTL("¡{1} creó un fuerte vínculo con su entrenador!",user.pbThis))
        PBDebug.log("[Ability triggered] #{user.pbThis}'s Battle Bond")
        PBDebug.log("[Form changed] #{user.pbThis} changed to form #{self.form}")
      end
    end
    # Coránima
    if user.hasWorkingAbility(:SOULHEART) && target.isFainted? && pbPartner.isFainted?
      user=self
      if !user.pbTooHigh?(PBStats::SPATK)
        user.pbIncreaseStatBasic(PBStats::SPATK,1)
        @battle.pbCommonAnimation("StatUp",user,nil)
        @battle.pbDisplay(_INTL("¡El Ataque Especial de {1} subió!",user.pbThis(true)))
      else
        @battle.pbDisplay(_INTL("¡Coránima de {1} subió su Ataque Especial!",user.pbThis))
      end
    end
    # Ultraimpulso
    if self.hasWorkingAbility(:BEASTBOOST) && target.isFainted?
      if user.attack >= user.defense &&
         user.attack >= user.spatk &&
         user.attack >= user.spdef &&
         user.attack >= user.speed
         if pbIncreaseStatWithCause(PBStats::ATTACK,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Attack)")
        end
      elsif user.defense >= user.spatk &&
         user.defense >= user.spdef &&
         user.defense >= user.speed
         if pbIncreaseStatWithCause(PBStats::DEFENSE,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Defense)")
        end
      elsif user.spatk >= user.spdef &&
         user.spatk >= user.speed
         if pbIncreaseStatWithCause(PBStats::SPATK,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Special Attack)")
        end
      elsif user.spdef >= user.speed
         if pbIncreaseStatWithCause(PBStats::SPDEF,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Special Defense)")
        end
      else
        if pbIncreaseStatWithCause(PBStats::SPEED,1,self,PBAbilities.getName(ability))
          PBDebug.log("[Ability triggered] #{pbThis}'s Beast Boost (raising Speed)")
        end
      end
    end
    # Prestidigitador
    if user.hasWorkingAbility(:MAGICIAN)
      if target.item>0 && user.item==0 &&
         user.effects[PBEffects::Substitute]==0 &&
         target.effects[PBEffects::Substitute]==0 &&
         !target.hasWorkingAbility(:STICKYHOLD) &&
         !@battle.pbIsUnlosableItem(target,target.item) &&
         !@battle.pbIsUnlosableItem(user,target.item) &&
         (@battle.opponent || !@battle.pbIsOpposing?(user.index))
        user.item=target.item
        target.item=0
        target.effects[PBEffects::Unburden]=true
        if !@battle.opponent &&   # In a wild battle
           user.pokemon.itemInitial==0 &&
           target.pokemon.itemInitial==user.item
          user.pokemon.itemInitial=user.item
          target.pokemon.itemInitial=0
        end
        @battle.pbDisplay(_INTL("¡{1} le ha robado un {3} a {2} usando {4}!",user.pbThis,
           target.pbThis(true),PBItems.getName(user.item),PBAbilities.getName(user.ability)))
        PBDebug.log("[Habilidad disparada] Prestidigitador de #{user.pbThis} ha robado #{PBItems.getName(user.item)} de #{target.pbThis(true)}")
      end
    end
    # Hurto
    if target.hasWorkingAbility(:PICKPOCKET)
      if target.item==0 && user.item>0 &&
         user.effects[PBEffects::Substitute]==0 &&
         target.effects[PBEffects::Substitute]==0 &&
         !user.hasWorkingAbility(:STICKYHOLD) &&
         !@battle.pbIsUnlosableItem(user,user.item) &&
         !@battle.pbIsUnlosableItem(target,user.item) &&
         (@battle.opponent || !@battle.pbIsOpposing?(target.index))
        target.item=user.item
        user.item=0
        user.effects[PBEffects::Unburden]=true
        if !@battle.opponent &&   # In a wild battle
           target.pokemon.itemInitial==0 &&
           user.pokemon.itemInitial==target.item
          target.pokemon.itemInitial=target.item
          user.pokemon.itemInitial=0
        end
        @battle.pbDisplay(_INTL("¡{1} le ha robado un {3} a {2}!",target.pbThis,
           user.pbThis(true),PBItems.getName(target.item)))
        PBDebug.log("[Habilidad disparada] Hurto de #{target.pbThis} ha robado #{PBItems.getName(target.item)} de #{user.pbThis(true)}")
      end
    end
  end

  def pbAbilityCureCheck
    return if self.isFainted?
    case self.status
    when PBStatuses::SLEEP
      if self.hasWorkingAbility(:VITALSPIRIT) || self.hasWorkingAbility(:INSOMNIA)
        PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis}")
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{2} de {1} le despertó!",pbThis,PBAbilities.getName(@ability)))
      end
    when PBStatuses::POISON
      if self.hasWorkingAbility(:IMMUNITY)
        PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis}")
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{2} de {1} le curó el veneno!",pbThis,PBAbilities.getName(@ability)))
      end
    when PBStatuses::BURN
      if self.hasWorkingAbility(:WATERVEIL)
        PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis}")
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{2} de {1} le curó la quemadura!",pbThis,PBAbilities.getName(@ability)))
      end
    when PBStatuses::PARALYSIS
      if self.hasWorkingAbility(:LIMBER)
        PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis}")
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{2} de {1} le curó la parálisis!",pbThis,PBAbilities.getName(@ability)))
      end
    when PBStatuses::FROZEN
      if self.hasWorkingAbility(:MAGMAARMOR)
        PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis}")
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{2} de {1} le permitió descongelarse!",pbThis,PBAbilities.getName(@ability)))
      end
    end
    if @effects[PBEffects::Confusion]>0 && self.hasWorkingAbility(:OWNTEMPO)
      PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis} (attract)")
      pbCureConfusion(false)
      @battle.pbDisplay(_INTL("¡{2} de {1} le quitó su problema de confusión!",pbThis,PBAbilities.getName(@ability)))
    end
    if @effects[PBEffects::Attract]>=0 && self.hasWorkingAbility(:OBLIVIOUS)
      PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis}")
      pbCureAttract
      @battle.pbDisplay(_INTL("¡{2} de {1} le quitó el enamoramiento!",pbThis,PBAbilities.getName(@ability)))
    end
    if USENEWBATTLEMECHANICS && @effects[PBEffects::Taunt]>0 && self.hasWorkingAbility(:OBLIVIOUS)
      PBDebug.log("[Habilidad disparada] #{PBAbilities.getName(@ability)} de #{pbThis} (taunt)")
      @effects[PBEffects::Taunt]=0
      @battle.pbDisplay(_INTL("¡{2} de {1} le hizo olvidarse de la Mofa!",pbThis,PBAbilities.getName(@ability)))
    end
  end

################################################################################
# Held item effects  /  Efectos de objetos llevados
################################################################################
  def pbConsumeItem(recycle=true,pickup=true)
    itemname=PBItems.getName(self.item)
    @pokemon.itemRecycle=self.item if recycle
    @pokemon.itemInitial=0 if @pokemon.itemInitial==self.item
    if pickup
      @effects[PBEffects::PickupItem]=self.item
      @effects[PBEffects::PickupUse]=@battle.nextPickupUse
    end
    self.item=0
    self.effects[PBEffects::Unburden]=true
    # Simbiosis
    if pbPartner && pbPartner.hasWorkingAbility(:SYMBIOSIS) && recycle
      if pbPartner.item>0 &&
         !@battle.pbIsUnlosableItem(pbPartner,pbPartner.item) &&
         !@battle.pbIsUnlosableItem(self,pbPartner.item)
        @battle.pbDisplay(_INTL("¡{2} de {1} permite compartir su {3} con {4}!",
           pbPartner.pbThis,PBAbilities.getName(pbPartner.ability),
           PBItems.getName(pbPartner.item),pbThis(true)))
        self.item=pbPartner.item
        pbPartner.item=0
        pbPartner.effects[PBEffects::Unburden]=true
        pbBerryCureCheck
      end
    end
  end

  def pbConfusionBerry(flavor,message1,message2)
    return false if @effects[PBEffects::HealBlock]>0
    if hasWorkingAbility(:RIPEN)
      amt=self.pbRecoverHP((self.totalhp*2/3).floor,true)
    else
      amt=self.pbRecoverHP((self.totalhp/3).floor,true)
    end
    if amt>0
      @battle.pbDisplay(message1)
      if (self.nature%5)==flavor && (self.nature/5).floor!=(self.nature%5)
        @battle.pbDisplay(message2)
        pbConfuseSelf
      end
      return true
    end
    return false
  end

  def pbStatIncreasingBerry(stat,berryname)
    if hasWorkingAbility(:RIPEN)
      return pbIncreaseStatWithCause(stat,2,self,berryname)
    else
      return pbIncreaseStatWithCause(stat,1,self,berryname)
    end
  end

  def pbActivateMimicry
    type = 0
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      type = PBTypes::ELECTRIC
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
      type = PBTypes::GRASS
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
      type = PBTypes::FAIRY
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
      type = PBTypes::PSYCHIC
    else
      type = -1
    end
    if type>=0 && self.type1 != type && self.type2 != type
#      pbShowAnimation(PBMoves::CAMOUFLAGE,self,nil,0,nil,true)
      self.type1=type
      self.type2=type
      self.effects[PBEffects::Type3]=-1
      typename=PBTypes.getName(type)
      @battle.pbDisplay(_INTL("¡{1} cambió al tipo {2}!",pbThis,typename))
    elsif type==-1 && (self.type1 != self.effects[PBEffects::Mimicry][0] ||
          self.type2 != self.effects[PBEffects::Mimicry][1])
#      pbShowAnimation(PBMoves::CAMOUFLAGE,self,nil,0,nil,true)
      self.type1 = self.effects[PBEffects::Mimicry][0]
      self.type2 = self.effects[PBEffects::Mimicry][1]
      self.effects[PBEffects::Type3]=-1
      @battle.pbDisplay(_INTL("¡Los tipos de {1} volvieron a la normalidad!",pbThis))
    end
  end

  def pbActivateBerryEffect(berry=0,consume=true)
    berry=self.item if berry==0
    berryname=(berry==0) ? "" : PBItems.getName(berry)
    PBDebug.log("[Item triggered] #{pbThis}'s #{berryname}")
    consumed=false
    if isConst?(berry,PBItems,:ORANBERRY)
      if hasWorkingAbility(:RIPEN)
        amt=self.pbRecoverHP(20,true)
      else
        amt=self.pbRecoverHP(10,true)
      end
      if amt>0
        @battle.pbDisplay(_INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:SITRUSBERRY) ||
          isConst?(berry,PBItems,:ENIGMABERRY)
      if hasWorkingAbility(:RIPEN)
        amt=self.pbRecoverHP((self.totalhp/2).floor,true)
      else
        amt=self.pbRecoverHP((self.totalhp/4).floor,true)
      end
      if amt>0
        @battle.pbDisplay(_INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:CHESTOBERRY)
      if self.status==PBStatuses::SLEEP
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{1} se ha despertado gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:PECHABERRY)
      if self.status==PBStatuses::POISON
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{1} se ha curado del envenenamiento gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:RAWSTBERRY)
      if self.status==PBStatuses::BURN
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{1} se ha curado la quemadura gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:CHERIBERRY)
      if self.status==PBStatuses::PARALYSIS
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{1} se ha recuperado de la parálisis gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:ASPEARBERRY)
      if self.status==PBStatuses::FROZEN
        pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{1} se ha descongelado gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:LEPPABERRY)
      found=[]
      for i in 0...@pokemon.moves.length
        if @pokemon.moves[i].id!=0
          if (consume && @pokemon.moves[i].pp==0) ||
             (!consume && @pokemon.moves[i].pp<@pokemon.moves[i].totalpp)
            found.push(i)
          end
        end
      end
      if found.length>0
        choice=(consume) ? found[0] : found[@battle.pbRandom(found.length)]
        pokemove=@pokemon.moves[choice]
        if hasWorkingAbility(:RIPEN)
          pokemove.pp+=20
        else
          pokemove.pp+=10
        end
        pokemove.pp=pokemove.totalpp if pokemove.pp>pokemove.totalpp
        self.moves[choice].pp=pokemove.pp
        movename=PBMoves.getName(pokemove.id)
        @battle.pbDisplay(_INTL("¡{1} ha restaurado los PP de {3} con {2}!",pbThis,berryname,movename))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:PERSIMBERRY)
      if @effects[PBEffects::Confusion]>0
        pbCureConfusion(false)
        @battle.pbDisplay(_INTL("¡{1} se ha librado de la confusión gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:LUMBERRY)
      if self.status>0 || @effects[PBEffects::Confusion]>0
        st=self.status; conf=(@effects[PBEffects::Confusion]>0)
        pbCureStatus(false)
        pbCureConfusion(false)
        case st
        when PBStatuses::SLEEP
          @battle.pbDisplay(_INTL("¡{1} se ha despertado gracias a la {2}!",pbThis,berryname))
        when PBStatuses::POISON
          @battle.pbDisplay(_INTL("¡{1} se ha curado del envenenamiento gracias a la {2}!",pbThis,berryname))
        when PBStatuses::BURN
          @battle.pbDisplay(_INTL("¡{1} se ha curado la quemadura gracias a la {2}!",pbThis,berryname))
        when PBStatuses::PARALYSIS
          @battle.pbDisplay(_INTL("¡{1} se ha recuperado de la parálisis gracias a la {2}!",pbThis,berryname))
        when PBStatuses::FROZEN
          @battle.pbDisplay(_INTL("¡{1} se ha descongelado gracias a la {2}!",pbThis,berryname))
        end
        if conf
          @battle.pbDisplay(_INTL("¡{1} se ha librado de la confusión gracias a la {2}!",pbThis,berryname))
        end
        consumed=true
      end
    elsif isConst?(berry,PBItems,:FIGYBERRY)
      consumed=pbConfusionBerry(1,
         _INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname),
         _INTL("¡La {2} estaba demasiado picante para {1}!",pbThis(true),berryname))
    elsif isConst?(berry,PBItems,:WIKIBERRY)
      consumed=pbConfusionBerry(4,
         _INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname),
         _INTL("¡La {2} estaba demasiado seca para {1}!",pbThis(true),berryname))
    elsif isConst?(berry,PBItems,:MAGOBERRY)
      consumed=pbConfusionBerry(3,
         _INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname),
         _INTL("¡La {2} estaba demasiado dulce para {1}!",pbThis(true),berryname))
    elsif isConst?(berry,PBItems,:AGUAVBERRY)
      consumed=pbConfusionBerry(5,
         _INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname),
         _INTL("¡La {2} estaba demasiado amarga para {1}!",pbThis(true),berryname))
    elsif isConst?(berry,PBItems,:IAPAPABERRY)
      consumed=pbConfusionBerry(2,
         _INTL("¡{1} recuperó salud usando una {2}!",pbThis,berryname),
         _INTL("¡La {2} estaba muy ácida para {1}!",pbThis(true),berryname))
    elsif isConst?(berry,PBItems,:LIECHIBERRY)
      consumed=pbStatIncreasingBerry(PBStats::ATTACK,berryname)
    elsif isConst?(berry,PBItems,:GANLONBERRY) ||
          isConst?(berry,PBItems,:KEEBERRY)
      consumed=pbStatIncreasingBerry(PBStats::DEFENSE,berryname)
    elsif isConst?(berry,PBItems,:SALACBERRY)
      consumed=pbStatIncreasingBerry(PBStats::SPEED,berryname)
    elsif isConst?(berry,PBItems,:PETAYABERRY)
      consumed=pbStatIncreasingBerry(PBStats::SPATK,berryname)
    elsif isConst?(berry,PBItems,:APICOTBERRY) ||
          isConst?(berry,PBItems,:MARANGABERRY)
      consumed=pbStatIncreasingBerry(PBStats::SPDEF,berryname)
    elsif isConst?(berry,PBItems,:LANSATBERRY)
      if @effects[PBEffects::FocusEnergy]<2
        @effects[PBEffects::FocusEnergy]=2
        @battle.pbDisplay(_INTL("¡{1} se está preparando para luchar gracias a la {2}!",pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:MICLEBERRY)
      if !@effects[PBEffects::MicleBerry]
        @effects[PBEffects::MicleBerry]=true
        @battle.pbDisplay(_INTL("¡El siguiente movimiento de {1} tendrá mayor precisión gracias a la {2}!",
           pbThis,berryname))
        consumed=true
      end
    elsif isConst?(berry,PBItems,:STARFBERRY)
      stats=[]
      for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPATK,PBStats::SPDEF,PBStats::SPEED]
        stats.push(i) if pbCanIncreaseStatStage?(i,self)
      end
      if stats.length>0
        stat=stats[@battle.pbRandom(stats.length)]
        if hasWorkingAbility(:RIPEN)
          consumed=pbIncreaseStatWithCause(stat,4,self,berryname)
        else
          consumed=pbIncreaseStatWithCause(stat,2,self,berryname)
        end
      end
    end
    if consumed
      # Rumia
      if hasWorkingAbility(:CUDCHEW)
        self.effects[PBEffects::CudChew]=1
      end
      # Carrillo
      if hasWorkingAbility(:CHEEKPOUCH)
        amt=self.pbRecoverHP((@totalhp/3).floor,true)
        if amt>0
          @battle.pbDisplay(_INTL("¡{2} de {1} ha restaurado algunos PS!",
             pbThis,PBAbilities.getName(ability)))
        end
      end
      pbConsumeItem if consume
      self.pokemon.belch=true if self.pokemon
    end
  end

  def pbBerryCureCheck(hpcure=false)
    return if self.isFainted?
    unnerver=(pbOpposing1.hasWorkingAbility(:UNNERVE) ||
              pbOpposing2.hasWorkingAbility(:UNNERVE) ||
              pbOpposing1.hasWorkingAbility(:ASONE1) ||
              pbOpposing2.hasWorkingAbility(:ASONE1) ||
              pbOpposing1.hasWorkingAbility(:ASONE2) ||
              pbOpposing2.hasWorkingAbility(:ASONE2))
    itemname=(self.item==0) ? "" : PBItems.getName(self.item)
    if hpcure
      if self.hasWorkingItem(:BERRYJUICE) && self.hp<=(self.totalhp/2).floor   # Zumo de Baya
        amt=self.pbRecoverHP(20,true)
        if amt>0
          @battle.pbCommonAnimation("UseItem",self,nil)
          @battle.pbDisplay(_INTL("¡{1} ha restaurado su salud gracias a la {2}!",pbThis,itemname))
          pbConsumeItem
          return
        end
      end
    end
    if !unnerver
      if hpcure
        if self.hp<=(self.totalhp/2).floor
          if self.hasWorkingItem(:ORANBERRY) ||
             self.hasWorkingItem(:SITRUSBERRY)
            pbActivateBerryEffect
            return
          end
          if self.hasWorkingItem(:FIGYBERRY) ||
            self.hasWorkingItem(:WIKIBERRY) ||
            self.hasWorkingItem(:MAGOBERRY) ||
            self.hasWorkingItem(:AGUAVBERRY) ||
            self.hasWorkingItem(:IAPAPABERRY)
            pbActivateBerryEffect
            return
          end
        end
      end
      if (self.hasWorkingAbility(:GLUTTONY) && self.hp<=(self.totalhp/2).floor) ||
         self.hp<=(self.totalhp/4).floor
        if self.hasWorkingItem(:LIECHIBERRY) ||
           self.hasWorkingItem(:GANLONBERRY) ||
           self.hasWorkingItem(:SALACBERRY) ||
           self.hasWorkingItem(:PETAYABERRY) ||
           self.hasWorkingItem(:APICOTBERRY) ||
           self.hasWorkingItem(:FIGYBERRY) ||
           self.hasWorkingItem(:WIKIBERRY) ||
           self.hasWorkingItem(:MAGOBERRY) ||
           self.hasWorkingItem(:AGUAVBERRY) ||
           self.hasWorkingItem(:IAPAPABERRY)
          pbActivateBerryEffect
          return
        end
        if self.hasWorkingItem(:LANSATBERRY) ||
           self.hasWorkingItem(:STARFBERRY)
          pbActivateBerryEffect
          return
        end
        if self.hasWorkingItem(:MICLEBERRY)
          pbActivateBerryEffect
          return
        end
        if self.hasWorkingItem(:CUSTAPBERRY)
          pbActivateBerryEffect
          return
        end
      end
      if self.hasWorkingItem(:LEPPABERRY)
        pbActivateBerryEffect
        return
      end
      if self.hasWorkingItem(:CHESTOBERRY) ||
         self.hasWorkingItem(:PECHABERRY) ||
         self.hasWorkingItem(:RAWSTBERRY) ||
         self.hasWorkingItem(:CHERIBERRY) ||
         self.hasWorkingItem(:ASPEARBERRY) ||
         self.hasWorkingItem(:PERSIMBERRY) ||
         self.hasWorkingItem(:LUMBERRY)
        pbActivateBerryEffect
        return
      end
    end
    if self.hasWorkingItem(:WHITEHERB)
      reducedstats=false
      for i in [PBStats::ATTACK,PBStats::DEFENSE,
                PBStats::SPEED,PBStats::SPATK,PBStats::SPDEF,
                PBStats::ACCURACY,PBStats::EVASION]
        if @stages[i]<0
          @stages[i]=0; reducedstats=true
        end
      end
      if reducedstats
        PBDebug.log("[Objeto disparado] #{itemname} de #{pbThis}")
        @battle.pbCommonAnimation("UseItem",self,nil)
        @battle.pbDisplay(_INTL("¡{1} ha restaurado su estado gracias a la {2}!",pbThis,itemname))
        pbConsumeItem
        return
      end
    end
    if self.hasWorkingItem(:MENTALHERB) &&              # Hierba Mental
       (@effects[PBEffects::Attract]>=0 ||
       @effects[PBEffects::Taunt]>0 ||
       @effects[PBEffects::Encore]>0 ||
       @effects[PBEffects::Torment] ||
       @effects[PBEffects::Disable]>0 ||
       @effects[PBEffects::HealBlock]>0)
      PBDebug.log("[Objeto disparado] #{itemname} de #{pbThis}")
      @battle.pbCommonAnimation("UseItem",self,nil)
      @battle.pbDisplay(_INTL("¡{1} se le pasó el enamoramiento usando {2}!",pbThis,itemname)) if @effects[PBEffects::Attract]>=0    # Enamoramiento
      @battle.pbDisplay(_INTL("¡El efecto de Mofa de {1} ha pasado!",pbThis)) if @effects[PBEffects::Taunt]>0                        # Mofa
      @battle.pbDisplay(_INTL("¡{1} se liberó de Repetición!",pbThis)) if @effects[PBEffects::Encore]>0                              # Repetición
      @battle.pbDisplay(_INTL("¡El efecto de Tormento de {1} ha pasado!",pbThis)) if @effects[PBEffects::Torment]                    # Tormento
      @battle.pbDisplay(_INTL("¡{1} se ha liberado de la anulación!",pbThis)) if @effects[PBEffects::Disable]>0                      # Anulación
      @battle.pbDisplay(_INTL("¡Anticura de {1} se agotó!",pbThis)) if @effects[PBEffects::HealBlock]>0                              # Anticura
      self.pbCureAttract
      @effects[PBEffects::Taunt]=0
      @effects[PBEffects::Encore]=0
      @effects[PBEffects::EncoreMove]=0
      @effects[PBEffects::EncoreIndex]=0
      @effects[PBEffects::Torment]=false
      @effects[PBEffects::Disable]=0
      @effects[PBEffects::HealBlock]=0
      pbConsumeItem
      return
    end
    if hpcure && self.hasWorkingItem(:LEFTOVERS) && self.hp!=self.totalhp &&        # Restos
       @effects[PBEffects::HealBlock]==0
      PBDebug.log("[Objeto disparado] Restos de #{pbThis}")
      @battle.pbCommonAnimation("UseItem",self,nil)
      pbRecoverHP((self.totalhp/16).floor,true)
      @battle.pbDisplay(_INTL("¡{1} ha restaurado un poco sus PS con {2}!",pbThis,itemname))
    end
    if hpcure && self.hasWorkingItem(:BLACKSLUDGE)                                  # Lodo Negro
      if pbHasType?(:POISON)
        if self.hp!=self.totalhp &&
           (!USENEWBATTLEMECHANICS || @effects[PBEffects::HealBlock]==0)
          PBDebug.log("[Objeto disparado] Lodo Negro de #{pbThis} (cura)")          # Lodo Negro
          @battle.pbCommonAnimation("UseItem",self,nil)
          pbRecoverHP((self.totalhp/16).floor,true)
          @battle.pbDisplay(_INTL("¡{1} ha restaurado un poco sus PS con {2}!",pbThis,itemname))
        end
      elsif !self.hasWorkingAbility(:MAGICGUARD)
        PBDebug.log("[Objeto disparado] Lodo Negro de #{pbThis} (daño)")            # Lodo Negro
        @battle.pbCommonAnimation("UseItem",self,nil)
        pbReduceHP((self.totalhp/8).floor,true)
        @battle.pbDisplay(_INTL("¡{1} ha sido herido por {2}!",pbThis,itemname))
      end
      pbFaint if self.isFainted?
    end
  end

################################################################################
# Move user and targets
################################################################################
  def pbFindUser(choice,targets)
    move=choice[2]
    target=choice[3]
    user=self   # Normally, the user is self
    # Targets in normal cases
    case pbTarget(move)
    when PBTargets::SingleNonUser
      if target>=0
        targetBattler=@battle.battlers[target]
        if !pbIsOpposing?(targetBattler.index)
          if !pbAddTarget(targets,targetBattler)
            pbAddTarget(targets,pbOpposing2) if !pbAddTarget(targets,pbOpposing1)
          end
        else
          pbAddTarget(targets,targetBattler.pbPartner) if !pbAddTarget(targets,targetBattler)
        end
      else
        pbRandomTarget(targets)
      end
    when PBTargets::SingleOpposing
      if target>=0
        targetBattler=@battle.battlers[target]
        if !pbIsOpposing?(targetBattler.index)
          if !pbAddTarget(targets,targetBattler)
            pbAddTarget(targets,pbOpposing2) if !pbAddTarget(targets,pbOpposing1)
          end
        else
          pbAddTarget(targets,targetBattler.pbPartner) if !pbAddTarget(targets,targetBattler)
        end
      else
        pbRandomTarget(targets)
      end
    when PBTargets::OppositeOpposing
      pbAddTarget(targets,pbOppositeOpposing) if !pbAddTarget(targets,pbOppositeOpposing2)
    when PBTargets::RandomOpposing
      pbRandomTarget(targets)
    when PBTargets::AllOpposing
      # Just pbOpposing1 because partner is determined late
      pbAddTarget(targets,pbOpposing2) if !pbAddTarget(targets,pbOpposing1)
    when PBTargets::AllNonUsers
      for i in 0...4 # not ordered by priority
        pbAddTarget(targets,@battle.battlers[i]) if i!=@index
      end
    when PBTargets::UserOrPartner
      if target>=0 # Pre-chosen target
        targetBattler=@battle.battlers[target]
        pbAddTarget(targets,targetBattler.pbPartner) if !pbAddTarget(targets,targetBattler)
      else
        pbAddTarget(targets,self)
      end
    when PBTargets::Partner
      pbAddTarget(targets,pbPartner)
    else
      move.pbAddTarget(targets,self)
    end
    return user
  end

  def pbChangeUser(thismove,user)
    priority=@battle.pbPriority
    # Cambia el usuario actual por el usuario de Robo
    if thismove.canSnatch?
      for i in priority
        if i.effects[PBEffects::Snatch]
          @battle.pbDisplay(_INTL("¡{1} robó el movimiento de {2}!",i.pbThis,user.pbThis(true)))
          PBDebug.log("[Efecto prolongado disparado] Robo de #{i.pbThis} permitió usar #{thismove.name} de #{user.pbThis(true)}")
          i.effects[PBEffects::Snatch]=false
          target=user
          user=i
          # Los PP se Robo son reducidos si el usuario anterior tiene Presión
          userchoice=@battle.choices[user.index][1]
          if target.hasWorkingAbility(:PRESSURE) && user.pbIsOpposing?(target.index) && userchoice>=0
            pressuremove=user.moves[userchoice]
            pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
          end
          break if USENEWBATTLEMECHANICS
        end
      end
    end
    return user
  end

  def pbTarget(move)
    target=move.target
    if move.function==0x10D && pbHasType?(:GHOST) # Curse
      target=PBTargets::OppositeOpposing
    end
    side=(pbIsOpposing?(self.index)) ? 1 : 0
    owner=@battle.pbGetOwnerIndex(self.index)
    if @battle.zMove[side][owner]==self.index && (move.pbIsPhysical?(move.type) || move.pbIsSpecial?(move.type))
      target=PBTargets::SingleNonUser
    end
    return target
  end

  def pbAddTarget(targets,target)
    if !target.isFainted?
      targets[targets.length]=target
      return true
    end
    return false
  end

  def pbRandomTarget(targets)
    choices=[]
    pbAddTarget(choices,pbOpposing1)
    pbAddTarget(choices,pbOpposing2)
    if choices.length>0
      pbAddTarget(targets,choices[@battle.pbRandom(choices.length)])
    end
  end

  def pbChangeTarget(thismove,userandtarget,targets)
    priority=@battle.pbPriority
    changeeffect=0
    user=userandtarget[0]
    target=userandtarget[1]
    # Pararrayos
    if targets.length==1 && isConst?(thismove.pbType(thismove.type,user,target),PBTypes,:ELECTRIC) &&
       !target.hasWorkingAbility(:LIGHTNINGROD) && !thismove.doesBypassTargetSwap? &&
       !(user.hasWorkingAbility(:STALWART)||user.hasWorkingAbility(:PROPELLERTAIL))
      for i in priority                     # usa Pokémon con mayor prioridad
        next if user.index==i.index || target.index==i.index
        if i.hasWorkingAbility(:LIGHTNINGROD)
          PBDebug.log("[Habilidad disparada] Pararrayos de #{i.pbThis} (cambio de objetivo)")
          target=i                          # Pararrayos de X recibe el ataque!
          changeeffect=1
          break
        end
      end
    end
    # Colector
    if targets.length==1 && isConst?(thismove.pbType(thismove.type,user,target),PBTypes,:WATER) &&
       !target.hasWorkingAbility(:STORMDRAIN) && !thismove.doesBypassTargetSwap? &&
       !(user.hasWorkingAbility(:STALWART)||user.hasWorkingAbility(:PROPELLERTAIL))
      for i in priority                     # usa Pokémon con mayor prioridad
        next if user.index==i.index || target.index==i.index
        if i.hasWorkingAbility(:STORMDRAIN)
          PBDebug.log("[Habilidad disparada] Colector de #{i.pbThis} (cambio de objetivo)")
          target=i                          # Colector de X recibe el ataque!
          changeeffect=1
          break
        end
      end
    end
    # Cambio de objtivo por el usuario de Señuelo (sobreescribe Capa Mágica
    # porque la verificación de Capa Mágica de abajo usa este objetivo)
    if PBTargets.targetsOneOpponent?(thismove)
      newtarget=nil; strength=100
      for i in priority                     # usa Pokémon con mayor prioridad
        next if !user.pbIsOpposing?(i.index)
        if !i.isFainted? && !@battle.switching && !i.effects[PBEffects::SkyDrop] &&
           i.effects[PBEffects::FollowMe]>0 && i.effects[PBEffects::FollowMe]<strength &&
           !thismove.doesBypassTargetSwap? &&
           !(user.hasWorkingAbility(:STALWART)||user.hasWorkingAbility(:PROPELLERTAIL))
          PBDebug.log("[Efecto prolongado disparado] Señuelo de #{i.pbThis}")
          newtarget=i; strength=i.effects[PBEffects::FollowMe]
          changeeffect=0
        end
      end
      target=newtarget if newtarget
    end
    # TODO: Presión es incorrecta aquí si Capa Mágica cambio el objetivo
    if user.pbIsOpposing?(target.index) && target.hasWorkingAbility(:PRESSURE)
      PBDebug.log("[Habilidad disparada] Presión de #{target.pbThis} (en pbChangeTarget)")
      user.pbReducePP(thismove) # Reduce PP
    end
    # Cambia el usuario actual por el usuario de Robo
    if thismove.canSnatch?
      for i in priority
        if i.effects[PBEffects::Snatch]
          @battle.pbDisplay(_INTL("¡{1} robó el movimiento de {2}!",i.pbThis,user.pbThis(true)))
          PBDebug.log("[Efecto prolongado disparado] Robo de #{i.pbThis} permite usar #{thismove.name} de #{user.pbThis(true)}")
          i.effects[PBEffects::Snatch]=false
          target=user
          user=i
          # Los PP de Robo son reducidos si el usuario anterior tiene Presión
          userchoice=@battle.choices[user.index][1]
          if target.hasWorkingAbility(:PRESSURE) && user.pbIsOpposing?(target.index) && userchoice>=0
            PBDebug.log("[Habilidad disparada] Presión de #{target.pbThis} (parte de Robo)")
            pressuremove=user.moves[userchoice]
            pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
          end
        end
      end
    end
    if thismove.canMagicCoat?
      if target.effects[PBEffects::MagicCoat]
        # intercambio usuario y objetivo
#        PBDebug.log("[Efecto prolongado disparado] Capa Mágica de #{i.pbThis} permite usar #{thismove.name} de #{user.pbThis(true)}")
        changeeffect=3
        tmp=user
        user=target
        target=tmp
        # Los PP de Capa Mágica son reducidos si el usuario anterior tiene Presión
        userchoice=@battle.choices[user.index][1]
        if target.hasWorkingAbility(:PRESSURE) && user.pbIsOpposing?(target.index) && userchoice>=0
          PBDebug.log("[Habilidad disparada] Presión de #{target.pbThis} (parte de Capa Mágica)")
          pressuremove=user.moves[userchoice]
          pbSetPP(pressuremove,pressuremove.pp-1) if pressuremove.pp>0
        end
      elsif !user.hasMoldBreaker && target.hasWorkingAbility(:MAGICBOUNCE)       # Espejo Mágico
        !thismove.doesBypassIgnorableAbilities?
        # intercambio usuario y objetivo
        PBDebug.log("[Habilidad disparada] Espejo Mágico de #{target.pbThis} permite usar #{thismove.name} de #{user.pbThis(true)}")
        changeeffect=3
        tmp=user
        user=target
        target=tmp
      end
    end
    if changeeffect==1
      @battle.pbDisplay(_INTL("¡{2} de {1} atrajo el ataque!",target.pbThis,PBAbilities.getName(target.ability)))
    elsif changeeffect==3
      @battle.pbDisplay(_INTL("¡{1} ha devuelto {2}!",user.pbThis,thismove.name))
    end
    userandtarget[0]=user
    userandtarget[1]=target
    if !user.hasMoldBreaker && target.hasWorkingAbility(:SOUNDPROOF) &&
       thismove.isSoundBased? && !thismove.doesBypassIgnorableAbilities? &&
       thismove.function!=0xE5 &&   # Canto Mortal es controlado en otro lugar
       thismove.function!=0x151     # Última Palabra es controlado en otro lugar
      PBDebug.log("[Habilidad disparada] Insonorizar de #{target.pbThis} ha bloqueado #{thismove.name} de #{user.pbThis(true)}")
      @battle.pbDisplay(_INTL("¡{2} de {1} lo hace inmune a {3}!",target.pbThis,
         PBAbilities.getName(target.ability),thismove.name))
      return false
    end
    return true
  end

################################################################################
# PP de movimientos
################################################################################
  def pbSetPP(move,pp)
    move.pp=pp
    # [PBEffects::Mimic] sin efectos, dado que Mimético no puede copiar Mimético
    if move.thismove && move.id==move.thismove.id && !@effects[PBEffects::Transform]
      move.thismove.pp=pp
    end
  end

  def pbReducePP(move)
    if @effects[PBEffects::TwoTurnAttack]>0 ||
       @effects[PBEffects::Bide]>0 ||
       @effects[PBEffects::Outrage]>0 ||
       @effects[PBEffects::Rollout]>0 ||
       @effects[PBEffects::HyperBeam]>0 ||
       @effects[PBEffects::Uproar]>0
      # No need to reduce PP if two-turn attack
      return true
    end
    return true if move.pp<0         # No se reducen PP por llamados especiales de un movimiento
    return true if move.totalpp==0   # PP infinitos, se pueden usar por siempre
    return false if move.pp==0
    if move.pp>0
      pbSetPP(move,move.pp-1)
    end
    return true
  end

  def pbReducePPOther(move)
    pbSetPP(move,move.pp-1) if move.pp>0
  end

################################################################################
# Uso de movimiento
################################################################################
  def pbObedienceCheck?(choice)
    return true if choice[0]!=1
    if @battle.pbOwnedByPlayer?(@index) && @battle.internalbattle
      badgelevel=20
      badgelevel=30  if @battle.pbPlayer.numbadges>=1
      badgelevel=40  if @battle.pbPlayer.numbadges>=2
      badgelevel=50  if @battle.pbPlayer.numbadges>=3
      badgelevel=60  if @battle.pbPlayer.numbadges>=4
      badgelevel=70  if @battle.pbPlayer.numbadges>=5
      badgelevel=80  if @battle.pbPlayer.numbadges>=6
      badgelevel=90  if @battle.pbPlayer.numbadges>=7
      badgelevel=100 if @battle.pbPlayer.numbadges>=8
      move=choice[2]
      disobedient=false
      if @pokemon.isForeign?(@battle.pbPlayer) && @level>badgelevel
        a=((@level+badgelevel)*@battle.pbRandom(256)/255).floor
        disobedient|=a<badgelevel
      end
      if self.respond_to?("pbHyperModeObedience")
        disobedient|=!self.pbHyperModeObedience(move)
      end
      if disobedient
        PBDebug.log("[Desobediencia] #{pbThis} ha desobedecido")
        @effects[PBEffects::Rage]=false
        if self.status==PBStatuses::SLEEP &&
           (move.function==0x11 || move.function==0xB4) # Snore, Sleep Talk
          @battle.pbDisplay(_INTL("¡{1} ignora las órdenes mientras se va a dormir!",pbThis))
          return false
        end
        b=((@level+badgelevel)*@battle.pbRandom(256)/255).floor
        if b<badgelevel
          return false if !@battle.pbCanShowFightMenu?(@index)
          othermoves=[]
          for i in 0...4
            next if i==choice[1]
            othermoves[othermoves.length]=i if @battle.pbCanChooseMove?(@index,i,false)
          end
          if othermoves.length>0
            @battle.pbDisplay(_INTL("¡{1} se hace el distraido!",pbThis))
            newchoice=othermoves[@battle.pbRandom(othermoves.length)]
            choice[1]=newchoice
            choice[2]=@moves[newchoice]
            choice[3]=-1
          end
          return true
        elsif self.status!=PBStatuses::SLEEP
          c=@level-b
          r=@battle.pbRandom(256)
          if r<c && pbCanSleep?(self,false)
            pbSleepSelf()
            @battle.pbDisplay(_INTL("¡{1} está tomando una siesta!",pbThis))
            return false
          end
          r-=c
          if r<c
            @battle.pbDisplay(_INTL("¡Está tan confuso que se hirió a sí mismo!"))
            pbConfusionDamage
          else
            message=@battle.pbRandom(4)
            @battle.pbDisplay(_INTL("¡{1} ignoró las órdenes!",pbThis)) if message==0
            @battle.pbDisplay(_INTL("¡{1} se alejó!",pbThis)) if message==1
            @battle.pbDisplay(_INTL("¡{1} está con pereza!",pbThis)) if message==2
            @battle.pbDisplay(_INTL("¡{1} fingió no darse cuenta!",pbThis)) if message==3
          end
          return false
        end
      end
      return true
    else
      return true
    end
  end

  def pbSuccessCheck(thismove,user,target,turneffects,accuracy=true)
    unseenfist=isConst?(user.ability,PBAbilities,:UNSEENFIST) && thismove.isContactMove?
    if user.effects[PBEffects::TwoTurnAttack]>0
      return true
    end
# TODO: "Before Protect" applies to Counter/Mirror Coat
    if !target.hasWorkingAbility(:COMATOSE)
      if thismove.function==0xDE && target.status!=PBStatuses::SLEEP # Dream Eater
        @battle.pbDisplay(_INTL("¡{1} no se vio afectado!",target.pbThis))
        PBDebug.log("[Move failed] #{user.pbThis}'s Dream Eater's target isn't asleep")
        return false
      end
    end
    if thismove.function==0x113 && user.effects[PBEffects::Stockpile]==0       # Spit Up / Escupir
      @battle.pbDisplay(_INTL("¡Pero no consiguió escupir energía!"))
      PBDebug.log("[Movimiento falló] Escupir de #{user.pbThis} no hizo nada debido a que el contador de Reserva está en 0")
      return false
    end
    if target.effects[PBEffects::Protect] && thismove.canProtectAgainst? &&    # Protección
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Movimiento falló] Protección de #{target.pbThis} se está protegiendo")
      return false
    end
    p=thismove.priority
    if USENEWBATTLEMECHANICS
      p+=1 if user.hasWorkingAbility(:PRANKSTER) && thismove.pbIsStatus?                     # Bromista
      p+=1 if user.hasWorkingAbility(:GALEWINGS) && isConst?(thismove.type,PBTypes,:FLYING)  # Alas Vendaval
      p+=3 if user.hasWorkingAbility(:TRIAGE) && thismove.isHealingMove? &&                  # Primer Auxilio
              !isConst?(thismove.id,PBMoves,:AQUARING) &&
              !isConst?(thismove.id,PBMoves,:GRASSYTERRAIN) &&
              !isConst?(thismove.id,PBMoves,:INGRAIN) &&
              !isConst?(thismove.id,PBMoves,:LEECHSEED) &&
              !isConst?(thismove.id,PBMoves,:PAINSPLIT) &&
              !isConst?(thismove.id,PBMoves,:PRESENT) &&
              !isConst?(thismove.id,PBMoves,:POLLENPUFF)
    end
    if target.pbOwnSide.effects[PBEffects::QuickGuard] && thismove.canProtectAgainst? &&     # Anticipo
       p>0 && !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} ha sido protegido por Anticipo!",target.pbThis))
      PBDebug.log("[Movimiento falló] El Anticipo del lado del oponente ha detenido el ataque")
      return false
    end
    if @battle.field.effects[PBEffects::PsychicTerrain]>0 && p>0 && !target.isAirborne?
      @battle.pbDisplay(_INTL("¡Campo Psíquico protegió a {1}!",target.pbThis))
      PBDebug.log("[Movimiento falló] Campo Psíquico evitó el ataque")
      return false
    end
    # Regia Presencia
    if target.hasWorkingAbility(:QUEENLYMAJESTY) && p>0 && !user.hasMoldBreaker # Regia Presencia
      @battle.pbDisplay(_INTL("¡Regia Presencia impidió el ataque!",target.pbThis))
      PBDebug.log("[Movimiento falló] Regia Presencia bloqueó el ataque")
      return false
    end
    if target.pbPartner.hasWorkingAbility(:QUEENLYMAJESTY) && p>0 && !user.hasMoldBreaker
      @battle.pbDisplay(_INTL("¡Regia Presencia impidió el ataque!",target.pbThis))
      PBDebug.log("[Movimiento falló] Regia Presencia bloqueó el ataque")
      return false
    end
    # Cola Armadura
    if target.hasWorkingAbility(:ARMORTAIL) && p>0 && !user.hasMoldBreaker

      @battle.pbDisplay(_INTL("¡Cola Armadura impidió el ataque!",target.pbThis))
      PBDebug.log("[Movimiento falló] Regia Presencia bloqueó el ataque")
      return false
    end
    if target.pbPartner.hasWorkingAbility(:ARMORTAIL) && p>0 && !user.hasMoldBreaker
      @battle.pbDisplay(_INTL("¡Cola Armadura impidió el ataque!",target.pbThis))
      PBDebug.log("[Movimiento falló] Regia Presencia bloqueó el ataque")
      return false
    end
    # Cuerpo Vívido
    if target.hasWorkingAbility(:DAZZLING) && p>0 && !user.hasMoldBreaker
      @battle.pbDisplay(_INTL("¡Cuerpo Vívido impidió el ataque!",target.pbThis))
      PBDebug.log("[Movimiento falló] Regia Presencia bloqueó el ataque")
      return false
    end
    if target.pbPartner.hasWorkingAbility(:DAZZLING) && p>0 && !user.hasMoldBreaker
      @battle.pbDisplay(_INTL("¡Cuerpo Vívido impidió el ataque!",target.pbThis))
      PBDebug.log("[Movimiento falló] Regia Presencia bloqueó el ataque")
      return false
    end
    # Vastaguardia
    if target.pbOwnSide.effects[PBEffects::WideGuard] &&
       PBTargets.hasMultipleTargets?(thismove) && !thismove.pbIsStatus? &&
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} ha sido protegido por Vastaguardia!",target.pbThis))
      PBDebug.log("[Movimiento falló] La Vastaguardia del lado del oponente ha detenido el ataque")
      return false
    end
    if target.pbOwnSide.effects[PBEffects::CraftyShield] && thismove.pbIsStatus? &&      # Truco Defensa
       thismove.function!=0xE5 && !unseenfist                                       # Canto Mortal
      @battle.pbDisplay(_INTL("¡Truco Defensa ha protegido a {1}!",target.pbThis(true)))
      PBDebug.log("[Movimiento falló] El Truco Defensa del lado del oponente ha detenido el ataque")
      return false
    end
    if target.pbOwnSide.effects[PBEffects::MatBlock] && !thismove.pbIsStatus? &&         # Escudo Tatami
       thismove.canProtectAgainst? && !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡Escudo Tatami ha neutralizado {1}!",thismove.name))
      PBDebug.log("[Movimiento falló] El Escudo Tatami del lado del oponente ha detenido el ataque")
      return false
    end
    # TODO: Telépata/Fijar Blanco (Mind Reader/Lock-On)
    # --Esquema/Premonición/Más Psique funcionan incluso en Vuelo/Buceo/Excavar
    if thismove.pbMoveFailed(user,target)         # TODO: Aplica a Ronquido/Sorpresa (Snore/Fake Out)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      PBDebug.log(sprintf("[Movimiento falló] Falló pbMoveFailed (código de función %02X)",thismove.function))
      return false
    end
    # Escudo Real (deliberadamente después de pbMoveFailed)
    if target.effects[PBEffects::KingsShield] && !thismove.pbIsStatus? &&
       thismove.canProtectAgainst? && !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Movimiento falló] Escudo Real de #{target.pbThis} ha detenido el ataque")
      if thismove.isContactMove? && !user.hasWorkingAbility(:LONGREACH) && !user.hasWorkingItem(:PROTECTIVEPADS) &&
        (!user.hasWorkingItem(:PUNCHINGGLOVE) && !thismove.isPunchingMove?) && !user.isFainted?
        user.pbReduceStat(PBStats::ATTACK,1,nil,false)
      end
      return false
    end
    # Barrera Espinosa
    if target.effects[PBEffects::SpikyShield] && thismove.canProtectAgainst? &&
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Movimiento falló] Barrera Espinosa de #{user.pbThis} ha detenido el ataque")
      if thismove.isContactMove? && !user.hasWorkingAbility(:LONGREACH) && !user.hasWorkingItem(:PROTECTIVEPADS) &&
        (!user.hasWorkingItem(:PUNCHINGGLOVE) && !thismove.isPunchingMove?) && !user.isFainted?
        @battle.scene.pbDamageAnimation(user,0)
        amt=user.pbReduceHP((user.totalhp/8).floor)
        @battle.pbDisplay(_INTL("¡{1} ha sido dañado!",user.pbThis)) if amt>0
      end
      return false
    end
    # Búnker
    if target.effects[PBEffects::BanefulBunker] && thismove.canProtectAgainst? &&
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Move failed] #{user.pbThis}'s Baneful Bunker stopped the attack!")
      if thismove.isContactMove? && !user.isFainted? && user.pbCanPoison?(nil,false) && !user.hasWorkingAbility(:LONGREACH) &&
        (!user.hasWorkingItem(:PUNCHINGGLOVE) && !thismove.isPunchingMove?) && !user.isFainted?
        PBDebug.log("#{target.pbThis} poisoned by Baneful Bunker")
        user.pbPoison(target,_INTL("¡{1} fue envenenado!",target.pbThis))
      end
      return false
    end
    # Obstrucción
    if target.effects[PBEffects::Obstruct] && thismove.canProtectAgainst? &&
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Move failed] #{target.pbThis}'s Obstruct stopped the attack")
      if thismove.isContactMove? && !user.hasWorkingAbility(:LONGREACH) &&
         !user.hasWorkingItem(:PROTECTIVEPADS) && (!user.hasWorkingItem(:PUNCHINGGLOVE) && !thismove.isPunchingMove?) && !user.isFainted?
        user.pbReduceStat(PBStats::DEFENSE,2,nil,false)
      end
      return false
    end
    # Telatrampa
    if target.effects[PBEffects::Silktrap] && thismove.canProtectAgainst? &&
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Move failed] #{target.pbThis}'s Silktrap stopped the attack")
      if thismove.isContactMove? && !user.hasWorkingAbility(:LONGREACH) && !user.hasWorkingItem(:PROTECTIVEPADS) &&
        (!user.hasWorkingItem(:PUNCHINGGLOVE) && !thismove.isPunchingMove?) && !user.isFainted?
        user.pbReduceStat(PBStats::SPEED,1,nil,false)
      end
      return false
    end
    #Burning Bulwark
    if target.effects[PBEffects::BurningBulwark] && thismove.canProtectAgainst? &&
       !target.effects[PBEffects::ProtectNegation] && !unseenfist
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",target.pbThis))
      @battle.successStates[user.index].protected=true
      PBDebug.log("[Move failed] #{user.pbThis}'s Baneful Bunker stopped the attack!")
      if thismove.isContactMove? && !user.isFainted? && user.pbCanBurn?(nil,false) && !user.hasWorkingAbility(:LONGREACH) &&
         !user.hasWorkingItem(:PROTECTIVEPADS) && (!user.hasWorkingItem(:PUNCHINGGLOVE) && !thismove.isPunchingMove?) && !user.isFainted?
        PBDebug.log("#{target.pbThis} poisoned by Baneful Bunker")
        user.pbBurn(target,_INTL("¡{1} fue envenenado!",target.pbThis))
      end
      return false
    end
    # Inmunidad a movimientos basados en polvos
    if USENEWBATTLEMECHANICS && thismove.isPowderMove? &&
       (target.pbHasType?(:GRASS) ||
       (!user.hasMoldBreaker && target.hasWorkingAbility(:OVERCOAT) &&
       !thismove.doesBypassIgnorableAbilities?) ||
       target.hasWorkingItem(:SAFETYGOGGLES))
      @battle.pbDisplay(_INTL("No ha afectado a\r\n{1}...",target.pbThis(true)))
      PBDebug.log("[Movimiento falló] #{target.pbThis} es inmune a movimientos basados en polvo por alguna razón")
      return false
    end
    if thismove.basedamage>0 && thismove.function!=0x02 &&                     # Combate
       thismove.function!=0x111                                                # Premonición
      type=thismove.pbType(thismove.type,user,target)
      typemod=thismove.pbTypeModifier(type,user,target)
      #Cuerpo Aureo
      if (thismove.pbIsStatus? && thismove.doesBypassIgnorableAbilities?) &&
         !user.hasMoldBreaker && target.hasWorkingAbility(:GOODASGOLD)

         @battle.pbDisplay(_INTL("¡{1} es inmune a movimientos de Estado gracias a Cuerpo Áureo!",target.pbThis))
      end
      # Inmunidad a movimientos de tipo Tierra en base a Pokémon en el aire
      if isConst?(type,PBTypes,:GROUND) && target.isAirborne?(user.hasMoldBreaker ||
        thismove.doesBypassIgnorableAbilities?) &&
         !target.hasWorkingItem(:RINGTARGET) && thismove.function!=0x11C       # Obj. Blanco - Mov. Antiaéreo
        if !user.hasMoldBreaker && target.hasWorkingAbility(:LEVITATE) &&
          !thismove.doesBypassIgnorableAbilities?                              # Levitación
          @battle.pbDisplay(_INTL("¡{1} es inmune a movimientos de tipo Tierra gracias a Levitación!",target.pbThis))
          PBDebug.log("[Habilidad disparada] Levitación de #{target.pbThis} anula movimientos de tipo Tierra")
          return false
        end
        if target.hasWorkingItem(:AIRBALLOON)                                  # Globo Helio
          @battle.pbDisplay(_INTL("¡{1} evita los movimientos de tipo Tierra gracias al Globo Helio!",target.pbThis))
          PBDebug.log("[Objeto disparado] Globo Helio de #{target.pbThis} anula movimientos de tipo Tierra")
          return false
        end
        if target.effects[PBEffects::MagnetRise]>0                             # Levitón
          @battle.pbDisplay(_INTL("¡{1} evita los movimientos de tipo Tierra con Levitón!",target.pbThis))
          PBDebug.log("[Efecto prolongado disparado] Levitón de #{target.pbThis} anula movimientos de tipo Tierra")
          return false
        end
        if target.effects[PBEffects::Telekinesis]>0                            # Telequinesis
          @battle.pbDisplay(_INTL("¡{1} evita los movimientos de tipo Tierra con Telequinesis!",target.pbThis))
          PBDebug.log("[Efecto prolongado disparado] Telequinesis de #{target.pbThis} anula movimientos de tipo Tierra")
          return false
        end
      end
      if !user.hasMoldBreaker && target.hasWorkingAbility(:WONDERGUARD) &&     # Superguarda
         type>=0 && typemod<=8 && !thismove.doesBypassIgnorableAbilities?
        @battle.pbDisplay(_INTL("¡{1} evitó el daño usando Superguarda!",target.pbThis))
        PBDebug.log("[Habilidad disparada] Superguarda de #{target.pbThis}")
        return false
      end
      if typemod==0
        @battle.pbDisplay(_INTL("No afecta a\r\n{1}...",target.pbThis(true)))
        PBDebug.log("[Movimiento falló] Inmunidad por tipo")
        return false
      end
    end
    if accuracy
      if target.effects[PBEffects::LockOn]>0 && target.effects[PBEffects::LockOnPos]==user.index        # Fijar Blanco
        PBDebug.log("[Efecto prolongado disparado] Fijar Blanco de #{target.pbThis}")
        return true
      end
      miss=false; override=false
      invulmove=PBMoveData.new(target.effects[PBEffects::TwoTurnAttack]).function
      case invulmove
      when 0xC9, 0xCC                                      # Vuelo, Bote
        miss=true unless thismove.function==0x08 ||        # Trueno
                         thismove.function==0x15 ||        # Vendaval
                         thismove.function==0x77 ||        # Tornado
                         thismove.function==0x78 ||        # Ciclón
                         thismove.function==0x11B ||       # Gancho Alto
                         thismove.function==0x11C ||       # Antiaéreo
                         isConst?(thismove.id,PBMoves,:WHIRLWIND)
      when 0xCA                                            # Dig
        miss=true unless thismove.function==0x76 ||        # Terremoto
                         thismove.function==0x95           # Magnitud
      when 0xCB                                            # Buceo
        miss=true unless thismove.function==0x75 ||        # Surf
                         thismove.function==0xD0           # Torbellino
      when 0xCD                                            # Golpe Umbrío
        miss=true
      when 0xCE                                            # Caída Libre
        miss=true unless thismove.function==0x08 ||        # Trueno
                         thismove.function==0x15 ||        # Vendaval
                         thismove.function==0x77 ||        # Tornado
                         thismove.function==0x78 ||        # Ciclón
                         thismove.function==0x11B ||       # Gancho Alto
                         thismove.function==0x11C          # Antiaéreo
      when 0x14D                                           # Golpe Fantasma
        miss=true
      end
      if target.effects[PBEffects::SkyDrop]
        miss=true unless thismove.function==0x08 ||        # Trueno
                         thismove.function==0x15 ||        # Vendaval
                         thismove.function==0x77 ||        # Tornado
                         thismove.function==0x78 ||        # Ciclón
                         thismove.function==0xCE ||        # Caída Libre
                         thismove.function==0x11B ||       # Gancho Alto
                         thismove.function==0x11C          # Antiaéreo
      end
      miss=false if user.hasWorkingAbility(:NOGUARD) ||    # Indefenso
                    target.hasWorkingAbility(:NOGUARD) ||
                    @battle.futuresight
      miss=true if target.effects[PBEffects::Commander]>0  # Commander

      override=true if USENEWBATTLEMECHANICS && thismove.function==0x06 &&     # Tóxico
                    thismove.basedamage==0 && user.pbHasType?(:POISON)
      override=true if !miss && turneffects[PBEffects::SkipAccuracyCheck] # Called by another move
      if !override && (miss || !thismove.pbAccuracyCheck(user,target))         # Incluye Contraataque/Manto Espejo
        PBDebug.log(sprintf("[Movimiento falló] Falló pbAccuracyCheck (código de función %02X) o el objetivo es semi-invulnerable",thismove.function))
        if thismove.target==PBTargets::AllOpposing &&
           (!user.pbOpposing1.isFainted? ? 1 : 0) + (!user.pbOpposing2.isFainted? ? 1 : 0) > 1
          @battle.pbDisplay(_INTL("¡{1} ha evitado el ataque!",target.pbThis))
        elsif thismove.target==PBTargets::AllNonUsers &&
           (!user.pbOpposing1.isFainted? ? 1 : 0) + (!user.pbOpposing2.isFainted? ? 1 : 0) + (!user.pbPartner.isFainted? ? 1 : 0) > 1
          @battle.pbDisplay(_INTL("¡{1} ha esquivado el ataque!",target.pbThis))
        elsif target.effects[PBEffects::TwoTurnAttack]>0
          @battle.pbDisplay(_INTL("¡{1} ha evitado el ataque!",target.pbThis))
        elsif thismove.function==0xDC                      # Drenadoras
          @battle.pbDisplay(_INTL("¡{1} ha esquivado el ataque!",target.pbThis))
        else
          @battle.pbDisplay(_INTL("¡Falló el ataque de {1}!",user.pbThis))
        end
        return false
      end
    end
    return true
  end

  def pbTryUseMove(choice,thismove,turneffects)
    return true if turneffects[PBEffects::PassedTrying]
    # TODO: Devolver true si el ataque ya ha sido reflejado por Capa Mágica una vez
    if !turneffects[PBEffects::SkipAccuracyCheck]
      return false if !pbObedienceCheck?(choice)
    end
    if @effects[PBEffects::SkyDrop]              # No hay mensajes aquí intencionalmente
      PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} debido a Caída Libre")
      return false
    end
    if @battle.field.effects[PBEffects::Gravity]>0 && thismove.unusableInGravity?        # Gravedad
      @battle.pbDisplay(_INTL("¡{1} no pudo usar {2} debido a la gravedad!",pbThis,thismove.name))
      PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} debido a Gravedad")
      return false
    end
    if @effects[PBEffects::Taunt]>0 && thismove.basedamage==0                            # Mofa
      @battle.pbDisplay(_INTL("¡{1} no puede usar {2} debido a la Mofa!",pbThis,thismove.name))
      PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} debido a la Mofa")
      return false
    end
    if @effects[PBEffects::HealBlock]>0 && thismove.isHealingMove?                       # Anticura
      @battle.pbDisplay(_INTL("¡{1} no puede usar {2} debido a Anticura!",pbThis,thismove.name))
      PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} debido a Anticura")
      return false
    end
    if @effects[PBEffects::Torment] && thismove.id==@lastMoveUsed &&
       thismove.id!=@battle.struggle.id && @effects[PBEffects::TwoTurnAttack]==0
      @battle.pbDisplayPaused(_INTL("¡{1} no puede usar el mismo movimiento dos veces seguidas debido al Tormento!",pbThis))
      PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} debido al Tormento")
      return false
    end
    if @effects[PBEffects::GigatonHammer]==2 && thismove.function==0x245
      @battle.pbDisplay(_INTL("¡{1} no puede usar {2} dos veces seguidas!",pbThis,thismove.name))
      PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} dos veces seguidas")
      return false
    end
    if pbOpposing1.effects[PBEffects::Imprison] && !pbOpposing1.isFainted?               # Cerca
      if thismove.id==pbOpposing1.moves[0].id ||
         thismove.id==pbOpposing1.moves[1].id ||
         thismove.id==pbOpposing1.moves[2].id ||
         thismove.id==pbOpposing1.moves[3].id
        @battle.pbDisplay(_INTL("¡{1} no puede usar {2} porque está sellado!",pbThis,thismove.name))
        PBDebug.log("[Movimiento falló] #{thismove.name} no puede usar #{thismove.name} debido a la Cerca de #{pbOpposing1.pbThis(true)}")
        return false
      end
    end
    if @effects[PBEffects::ThroatChop]>0 && !pbOpposing1.isFainted?
      if thismove.isSoundBased?
        @battle.pbDisplay(_INTL("¡{1} no pudo usar {2} debido a Golpe Mordaza!",pbThis,thismove.name))
        PBDebug.log("[Move failed] #{pbThis} can't use #{thismove.name} because they were Throat chopped!")
        return false
      end
    end
    if pbOpposing2.effects[PBEffects::Imprison] && !pbOpposing2.isFainted?               # Cerca
      if thismove.id==pbOpposing2.moves[0].id ||
         thismove.id==pbOpposing2.moves[1].id ||
         thismove.id==pbOpposing2.moves[2].id ||
         thismove.id==pbOpposing2.moves[3].id
        @battle.pbDisplay(_INTL("¡{1} no puede usar {2} porque está sellado!",pbThis,thismove.name))
        PBDebug.log("[Movimiento falló] #{thismove.name} no puede usar #{thismove.name} debido a la Cerca de #{pbOpposing2.pbThis(true)}")
        return false
      end
    end
    if @effects[PBEffects::Disable]>0 && thismove.id==@effects[PBEffects::DisableMove] &&
       !@battle.switching                      # Persecución ignora si se encuentra desactivado
      @battle.pbDisplayPaused(_INTL("¡{2} de {1} está desactivado!",pbThis,thismove.name))
      PBDebug.log("[Movimiento falló] #{thismove.name} de #{pbThis} está desactivado")
      return false
    end
    if choice[1]==-2                            # Palacio Batalla
      @battle.pbDisplay(_INTL("¡{1} parece incapaz de usar su poder!",pbThis))
      PBDebug.log("[Movimiento falló] Palacio Batalla: #{pbThis} no es capaz de usar su poder")
      return false
    end
    if @effects[PBEffects::HyperBeam]>0
      @battle.pbDisplay(_INTL("¡{1} necesita recuperarse de su ataque!",pbThis))
      PBDebug.log("[Movimiento falló] #{pbThis} debe descansar después de usar #{PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(@currentMove)).name}")
      return false
    end
    if self.hasWorkingAbility(:TRUANT) && @effects[PBEffects::Truant]          # Ausente
      @battle.pbDisplay(_INTL("¡{1} está vagueando!",pbThis))
      PBDebug.log("[Habilidad disparada] Ausente de #{pbThis}")
      return false
    end
    if !turneffects[PBEffects::SkipAccuracyCheck]
      if self.status==PBStatuses::SLEEP
        self.statusCount-=1
        if self.statusCount<=0
          self.pbCureStatus
        else
          self.pbContinueStatus
          PBDebug.log("[Estado] #{pbThis} sigue dormido (contador: #{self.statusCount})")
          if !thismove.pbCanUseWhileAsleep?        # Ronquido / Sonámbulo / Enfado
            PBDebug.log("[Movimiento falló] #{pbThis} no puede usar #{thismove.name} mientras duerme")
            return false
          end
        end
      end
    end
    if self.status==PBStatuses::FROZEN
      if thismove.canThawUser?
        PBDebug.log("[Efecto de mov. disparado] #{pbThis} se ha descongelado usando #{thismove.name}")
        self.pbCureStatus(false)
        @battle.pbDisplay(_INTL("¡{1} derritió el hielo!",pbThis))
        pbCheckForm
      elsif @battle.pbRandom(10)<2 && !turneffects[PBEffects::SkipAccuracyCheck] && !FROSTBITE_REPLACES_FREEZE
        self.pbCureStatus
        pbCheckForm
      elsif !thismove.canThawUser? && !FROSTBITE_REPLACES_FREEZE
        self.pbContinueStatus
        PBDebug.log("[Estado] #{pbThis} continúa congelado y no se puedo mover")
        return false
      end
    end
    if !turneffects[PBEffects::SkipAccuracyCheck]
      if @effects[PBEffects::Confusion]>0
        @effects[PBEffects::Confusion]-=1
        if @effects[PBEffects::Confusion]<=0
          pbCureConfusion
        else
          pbContinueConfusion
          PBDebug.log("[Estado] #{pbThis} sigue confuso (contador: #{@effects[PBEffects::Confusion]})")
          if @battle.pbRandom(3)==0
            if isConst?(self.species,PBSpecies,:EISCUE) && self.hasWorkingAbility(:ICEFACE) && self.form!=1
              @battle.pbAnimation(getConst(PBMoves,:TACKLE),self,self)
              self.form=1; pbUpdate(true)
              @battle.scene.pbChangePokemon(self,@pokemon)
              @battle.pbDisplay(_INTL("¡{1} cambió de forma!",self.pbThis))
              PBDebug.log("[Form changed] #{self.pbThis} changed to form #{self.form}")
              return false
            else
              pbConfusionDamage
              @battle.pbDisplay(_INTL("¡Está tan confuso que se hirió a sí mismo!"))
              PBDebug.log("[Estado] #{pbThis} se daña a sí mismo en su confusión y no se puede mover")
              return false
            end
          end
        end
      end
    end
    if @effects[PBEffects::Flinch]
      @effects[PBEffects::Flinch]=false
      @battle.pbDisplay(_INTL("¡{1} retrocedió y no se pudo mover!",self.pbThis))
      PBDebug.log("[Efecto prolongado disparado] #{pbThis} retrocedió y no se pudo mover")
      if self.hasWorkingAbility(:STEADFAST)                          # Impasible
        if pbIncreaseStatWithCause(PBStats::SPEED,1,self,PBAbilities.getName(self.ability))
          PBDebug.log("[Habilidad disparada] Impasible de #{pbThis}")
        end
      end
      return false
    end
    if !turneffects[PBEffects::SkipAccuracyCheck]
      if @effects[PBEffects::Attract]>=0
        pbAnnounceAttract(@battle.battlers[@effects[PBEffects::Attract]])
        if @battle.pbRandom(2)==0
          pbContinueAttract
          PBDebug.log("[Efecto prolongado disparado] #{pbThis} está enamorado y no se pudo mover")
          return false
        end
      end
      if self.status==PBStatuses::PARALYSIS
        if @battle.pbRandom(4)==0
          pbContinueStatus
          PBDebug.log("[Estado] #{pbThis} está completamente paralizado y no se pudo mover")
          return false
        end
      end
    end
    turneffects[PBEffects::PassedTrying]=true
    return true
  end

  def pbConfusionDamage
    self.damagestate.reset
    confmove=PokeBattle_Confusion.new(@battle,nil)
    confmove.pbEffect(self,self)
    pbFaint if self.isFainted?
  end

  def pbUpdateTargetedMove(thismove,user)
    # TODO: Robo, movimientos que usan otros movimientos
    # TODO: Todos los casos de objetivos
    # Ataques en dos turnos, control de Capa Mágica, Premonición, Contraataque / Manto Espejo / Venganza
  end

  def pbProcessMoveAgainstTarget(thismove,user,target,numhits,turneffects,nocheck=false,alltargets=nil,showanimation=true,dancercheck=false)
    realnumhits=0
    totaldamage=0
    destinybond=false
    for i in 0...numhits
      target.damagestate.reset
      if thismove.function==0x212 && @battle.doublebattle && target!=user.pbPartner && # Dragon Darts
         !target.pbPartner.isFainted?
        changetarget=false
        for i in @battle.pbPriority
          next if !user.pbIsOpposing?(i.index)
          changetarget=true if i.effects[PBEffects::FollowMe]>0
        end
        if (thismove.pbTypeModifier(thismove.pbType(thismove.type,user,originalTarget),user,originalTarget)==0 ||
           thismove.pbTypeImmunityByAbility(thismove.pbType(thismove.type,user,originalTarget),user,originalTarget) ||
           (originalTarget.effects[PBEffects::Protect] ||
           (originalTarget.pbOwnSide.effects[PBEffects::QuickGuard] && thismove.priority>0) ||
           originalTarget.effects[PBEffects::SpikyShield] ||
           originalTarget.effects[PBEffects::BanefulBunker] ||
           originalTarget.effects[PBEffects::Obstruct] ||
           originalTarget.effects[PBEffects::Silktrap]) ||
           originalTarget.effects[PBEffects::TwoTurnAttack]>0 ||
           !thismove.pbAccuracyCheck(user,originalTarget)) && !changetarget
          target=originalTarget.pbPartner
        end
      end
      # Verificación de éxito (cálculo de precisión/evasión)
      if !nocheck &&
         !pbSuccessCheck(thismove,user,target,turneffects,i==0 || thismove.successCheckPerHit?)
        if thismove.function==0xBF && realnumhits>0                  # Triplepatada
          break                # Se considera éxitoso si Triplepatada golpea al menos una vez
        elsif thismove.function==0x10B || thismove.function==0x15C   # Patada Salto Alta, Patada Salto, Patada Hacha
          if !user.hasWorkingAbility(:MAGICGUARD)
            PBDebug.log("[Efecto de mov. disparado] #{user.pbThis} es dañado por la caída")
            #TODO: No se muestra es el mensaje es "No afecta a XXX..."
            @battle.pbDisplay(_INTL("¡{1} ha fallado y terminó en el suelo!",user.pbThis))
            damage=(user.totalhp/2).floor
            if damage>0
              @battle.scene.pbDamageAnimation(user,0)
              user.pbReduceHP(damage)
            end
            user.pbFaint if user.isFainted?
          end
        end
        #BLUNDER POLICY
        if user.hasWorkingItem(:BLUNDERPOLICY) &&
                                            user.pbCanIncreaseStatStage?(
                                            PBStats::SPEED,user) &&
                                            !(thismove.function==0x116) # Golpe Bajo
          pbIncreaseStat(PBStats::SPEED,2,user,false,self)
          user.pbConsumeItem
        end
        user.effects[PBEffects::Outrage]=0 if thismove.function==0xD2          # Enfado
        user.effects[PBEffects::Rollout]=0 if thismove.function==0xD3          # Desenrollar
        user.effects[PBEffects::FuryCutter]=0 if thismove.function==0x91       # Cortefuria
        user.effects[PBEffects::Stockpile]=0 if thismove.function==0x113       # Escupir
        user.effects[PBEffects::LastMoveFailed]=true
        return
      end
      # Incremento de contadores de movimientos que llevan la cuenta de usos sucesivos
      if thismove.function==0x91                           # Cortefuria
        user.effects[PBEffects::FuryCutter]+=1 if user.effects[PBEffects::FuryCutter]<4
      else
        user.effects[PBEffects::FuryCutter]=0
      end
      if thismove.function==0x92                           # Eco Voz
        if !user.pbOwnSide.effects[PBEffects::EchoedVoiceUsed] &&
           user.pbOwnSide.effects[PBEffects::EchoedVoiceCounter]<5
          user.pbOwnSide.effects[PBEffects::EchoedVoiceCounter]+=1
        end
        user.pbOwnSide.effects[PBEffects::EchoedVoiceUsed]=true
      end
      # Cuenta los golpes para Amor Filial si aplica
      user.effects[PBEffects::ParentalBond]-=1 if user.effects[PBEffects::ParentalBond]>0
      # Cuenta los golpes para Dracoflechas si golpea la primera vez
      if thismove.function==0x212 && @battle.doublebattle && realnumhits>0
        secondTarget=target.pbPartner
        changetarget=false
        for i in @battle.pbPriority
          next if !user.pbIsOpposing?(i.index)
          changetarget=true if i.effects[PBEffects::FollowMe]>0
        end
        if (thismove.pbTypeModifier(thismove.pbType(thismove.type,user,secondTarget),user,secondTarget)==0 ||
           thismove.pbTypeImmunityByAbility(thismove.pbType(thismove.type,user,secondTarget),user,secondTarget) ||
           (secondTarget.effects[PBEffects::Protect] ||
           (secondTarget.pbOwnSide.effects[PBEffects::QuickGuard] && thismove.priority>0) ||
           secondTarget.effects[PBEffects::SpikyShield] ||
           secondTarget.effects[PBEffects::BanefulBunker] ||
           secondTarget.effects[PBEffects::Obstruct] ||
           secondTarget.effects[PBEffects::Silktrap]) ||
           secondTarget.effects[PBEffects::TwoTurnAttack]>0 ||
           secondTarget.isFainted? ||
           !thismove.pbAccuracyCheck(user,secondTarget)) && !changetarget
          target=secondTarget.pbPartner if secondTarget.pbPartner!=user.pbPartner
        else
          target=secondTarget if secondTarget.pbPartner!=user.pbPartner
          if target.hasWorkingAbility(:PRESSURE) && !originalTarget.hasWorkingAbility(:PRESSURE)
            PBDebug.log("[Ability triggered] #{target.pbThis}'s Pressure (in pbChangeTarget)")
            user.pbReducePP(thismove) # Reduce PP
          end
        end
      end
      # Este golpe sucederá, contarlo
      realnumhits+=1
      # Cálculo de daño y/o efecto principal
      damage=thismove.pbEffect(user,target,i,alltargets,showanimation)    # Retroceso/drenaje, etc. se aplican aquí
      totaldamage+=damage if damage>0
      # Mensaje y consumo de las bayas que debilitan ataques
      if target.damagestate.berryweakened
        @battle.pbDisplay(_INTL("¡La {1} ha debilitado el daño en {2}!",
           PBItems.getName(target.item),target.pbThis(true)))
        target.pbConsumeItem
      end
      # Ilusión
      if target.effects[PBEffects::Illusion] && target.hasWorkingAbility(:ILLUSION) &&
         damage>0 && !target.damagestate.substitute
        PBDebug.log("[Habilidad disparada] La Ilusión de #{target.pbThis} se terminó")
        target.effects[PBEffects::Illusion]=nil
        @battle.scene.pbChangePokemon(target,target.pokemon)
        @battle.pbDisplay(_INTL("¡La {2} de {1} se terminó!",target.pbThis,
            PBAbilities.getName(target.ability)))
      end
      # Disguise
      if target.hasWorkingAbility(:DISGUISE) &&
        isConst?(target.species,PBSpecies,:MIMIKYU) && target.form==0 &&
        thismove.pbIsDamaging? && !target.damagestate.substitute &&
        !user.hasMoldBreaker && !thismove.doesBypassIgnorableAbilities?
        PBDebug.log("[Ability triggered] #{target.pbThis}'s Disguise ended")
        @battle.pbDisplay(_INTL("¡El disfraz ha actuado como señuelo!"))
        target.form=1
        target.pbUpdate(true)
        @battle.scene.pbChangePokemon(target,target.pokemon)
        @battle.pbDisplay(_INTL("¡El disfraz de {1} se ha roto!",target.pbThis))
        target.pbReduceHP((target.totalhp/8).floor)
        if target.hasWorkingItem(:AIRBALLOON,true)
          PBDebug.log("[Item triggered] #{target.pbThis}'s Air Balloon popped")
          @battle.pbDisplay(_INTL("¡Ha explotado el Globo Helio de {1}!",target.pbThis))
          target.pbConsumeItem(true,false)
        end
      end

      if user.isFainted?
        user.pbFaint # no return
      end
      if numhits>1 && target.damagestate.calcdamage<=0
        user.effects[PBEffects::LastMoveFailed]=true
        return
      end
      @battle.pbJudgeCheckpoint(user,thismove)
      # Efectos adicionales
      if target.damagestate.calcdamage>0 &&
         !user.hasWorkingAbility(:SHEERFORCE) &&
         (user.hasMoldBreaker || !target.hasWorkingAbility(:SHIELDDUST) ||
         thismove.doesBypassIgnorableAbilities? || !target.hasWorkingItem(:COVERTCLOAK))
        addleffect=thismove.addlEffect
        addleffect*=2 if (user.hasWorkingAbility(:SERENEGRACE) ||
                         user.pbOwnSide.effects[PBEffects::Rainbow]>0) &&
                         thismove.function!=0xA4           # Daño Secreto
        addleffect=100 if $DEBUG && Input.press?(Input::CTRL)
        if @battle.pbRandom(100)<addleffect
          PBDebug.log("[Efecto de mov. disparado] Efecto secundario de #{thismove.name}")
          thismove.pbAdditionalEffect(user,target)
        end
      end
      # Efectos de habilidades
      pbEffectsOnDealingDamage(thismove,user,target,damage)
      # Rabia
      if !user.isFainted? && target.isFainted?
        if target.effects[PBEffects::Grudge] && target.pbIsOpposing?(user.index)
          thismove.pp=0
          @battle.pbDisplay(_INTL("¡{2} de {1} perdió todos sus PP debido a la Rabia!",
             user.pbThis,thismove.name))
          PBDebug.log("[Efecto prolongado disparado] Rabia de #{target.pbThis} hizo perder todos los PP de #{thismove.name}")
        end
      end
      if target.isFainted?
        destinybond=destinybond || target.effects[PBEffects::DestinyBond]
      end
      user.pbFaint if user.isFainted? # no return
      break if user.isFainted?
      break if target.isFainted?
      # Hace retroceder al objetivo
      if target.damagestate.calcdamage>0 && !target.damagestate.substitute
        if user.hasMoldBreaker || !target.hasWorkingAbility(:SHIELDDUST) ||
          thismove.doesBypassIgnorableAbilities? || !target.hasWorkingItem(:COVERTCLOAK)
          canflinch=false
          if (user.hasWorkingItem(:KINGSROCK) || user.hasWorkingItem(:RAZORFANG)) &&
             thismove.canKingsRock?
            canflinch=true
          end
          if user.hasWorkingAbility(:STENCH) &&            # Hedor
             thismove.function!=0x09 &&                    # Colmillo Rayo
             thismove.function!=0x0B &&                    # Colmillo Ígneo
             thismove.function!=0x0E &&                    # Colmillo Hielo
             thismove.function!=0x0F &&                    # movimientos que causan retroceso
             thismove.function!=0x10 &&                    # Pisotón
             thismove.function!=0x11 &&                    # Ronquido
             thismove.function!=0x12 &&                    # Sorpresa
             thismove.function!=0x78 &&                    # Ciclón
             thismove.function!=0xC7                       # Ataque Aéreo
            canflinch=true
          end
          if canflinch && @battle.pbRandom(10)==0
            PBDebug.log("[Objeto/Habilidad disparado] Roca del Rey, Colmillagudo o Hedor de #{user.pbThis}")
            target.pbFlinch(user)
          end
        end
      end
      if target.damagestate.calcdamage>0 && !target.isFainted?
        # Descongelamiento
        if target.status==PBStatuses::FROZEN &&
           (isConst?(thismove.pbType(thismove.type,user,target),PBTypes,:FIRE) ||
           (USENEWBATTLEMECHANICS && isConst?(thismove.id,PBMoves,:SCALD)))
          target.pbCureStatus
        end
        # Furia
        if target.effects[PBEffects::Rage] && target.pbIsOpposing?(user.index)
          # TODO: Aparentemente se dispara cuando un Pokémon enemigo usa Premonición después de un ataque de Premonición
          if target.pbIncreaseStatWithCause(PBStats::ATTACK,1,target,"",true,false)
            PBDebug.log("[Efecto prolongado disparado] Furia de #{target.pbThis}")
            @battle.pbDisplay(_INTL("¡La furia de {1} está aumentando!",target.pbThis))
          end
        end
      end
      target.pbFaint if target.isFainted? # no return
      user.pbFaint if user.isFainted? # no return
      break if user.isFainted? || target.isFainted?
################################################################################
      # Dancer using damaging moves
    if thismove.isDanceMove? && !dancercheck
      if @battle.doublebattle
        for k in @battle.pbPriority(true)
          if k!=user && !k.isFainted?
            if !k.effects[PBEffects::Dancer] &&
            k.hasWorkingAbility(:DANCER)
            @battle.battlers[user.index].effects[PBEffects::Dancer]=true
              if k==user.pbPartner
                if !target.isFainted?
                  if target==user.pbPartner
                    if !user.pbOpposing1.isFainted?
                      @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                      k.effects[PBEffects::Dancer]=true
                      pbProcessMoveAgainstTarget(thismove,k,user.pbOpposing1,numhits,turneffects,nocheck,alltargets,showanimation,true)
                    elsif !user.pbOpposing2.isFainted?
                      @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                      k.effects[PBEffects::Dancer]=true
                      pbProcessMoveAgainstTarget(thismove,k,user.pbOpposing2,numhits,turneffects,nocheck,alltargets,showanimation,true)
                    elsif !user.isFainted?
                      @battle.pbDisplay(_INTL("¡{1} quiere bailar, pero no dañará a su aliado!",user.pbPartner.pbThis))
                    else
                      @battle.pbDisplay(_INTL("¡Qué pena! {1} quería bailar...",user.pbPartner.pbThis))
                    end
                  else
                    @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                    k.effects[PBEffects::Dancer]=true
                    pbProcessMoveAgainstTarget(thismove,k,target,numhits,turneffects,nocheck,alltargets,showanimation,true)
                  end
                elsif !target.pbPartner.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                  k.effects[PBEffects::Dancer]=true
                  pbProcessMoveAgainstTarget(thismove,k,target.pbPartner,numhits,turneffects,nocheck,alltargets,showanimation,true)
                elsif !user.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} quiere bailar, pero no dañará a su aliado!",user.pbPartner.pbThis))
                else
                  @battle.pbDisplay(_INTL("¡Qué pena! {1} quería bailar...",user.pbPartner.pbThis))
                end
              elsif k==user.pbOpposing1
                if !user.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                  k.effects[PBEffects::Dancer]=true
                  pbProcessMoveAgainstTarget(thismove,k,user,numhits,turneffects,nocheck,alltargets,showanimation,true)
                elsif !user.pbPartner.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                  k.effects[PBEffects::Dancer]=true
                  pbProcessMoveAgainstTarget(thismove,k,user.pbPartner,numhits,turneffects,nocheck,alltargets,showanimation,true)
                elsif !user.pbOpposing2.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} quiere bailar, pero no dañará a su aliado!",user.pbOpposing1.pbThis))
                else
                  @battle.pbDisplay(_INTL("¡Qué pena! {1} quería bailar...",user.pbOpposing1.pbThis))
                end
              elsif k==user.pbOpposing2
                if !user.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                  k.effects[PBEffects::Dancer]=true
                  pbProcessMoveAgainstTarget(thismove,k,user,numhits,turneffects,nocheck,alltargets,showanimation,true)
                elsif !user.pbPartner.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} también baila!",k.pbThis))
                  k.effects[PBEffects::Dancer]=true
                  pbProcessMoveAgainstTarget(thismove,k,user.pbPartner,numhits,turneffects,nocheck,alltargets,showanimation,true)
                elsif !user.pbOpposing1.isFainted?
                  @battle.pbDisplay(_INTL("¡{1} quiere bailar, pero no dañará a su aliado!",user.pbOpposing1.pbThis))
                else
                  @battle.pbDisplay(_INTL("¡Qué pena! {1} quería bailar...",user.pbOpposing2.pbThis))
                end
              end
            end
          end
        end
      elsif target.hasWorkingAbility(:DANCER) && !target.isFainted? && !user.isFainted?
           @battle.pbDisplay(_INTL("¡{1} también baila!",target.pbThis))
           pbProcessMoveAgainstTarget(thismove,target,user,numhits,turneffects,nocheck,alltargets,showanimation,true)
      elsif target.hasWorkingAbility(:DANCER) && !target.isFainted? && user.isFainted?
           @battle.pbDisplay(_INTL("¡Qué pena! {1} quería bailar...",target.pbThis))
      end
    end
################################################################################
      # Verificación de bayas (maybe just called by ability effect, since only necessary Berries are checked)
      for j in 0...4
        @battle.battlers[j].pbBerryCureCheck
      end
      if i==numhits-1
        if isConst?(thismove.id,PBMoves,:SCALESHOT)
          if user.pbCanIncreaseStatStage?(PBStats::SPEED,user,false,self)
            user.pbIncreaseStat(PBStats::SPEED,1,user,false,self)
          end
          if user.pbCanReduceStatStage?(PBStats::DEFENSE,user,false,self)
            user.pbReduceStat(PBStats::DEFENSE,1,user,false,self)
          end
        end
      end
      break if user.isFainted? || target.isFainted?
      target.pbUpdateTargetedMove(thismove,user)
      break if target.damagestate.calcdamage<=0
    end
    turneffects[PBEffects::TotalDamage]+=totaldamage if totaldamage>0
    # Battle Arena only - attack is successful
    @battle.successStates[user.index].useState=2
    @battle.successStates[user.index].typemod=target.damagestate.typemod
    # Efectividad por tipo
    if numhits>1
      if target.damagestate.typemod>8
        if alltargets.length>1
          @battle.pbDisplay(_INTL("¡Es super efectivo en {1}!",target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("¡Es super efectivo!"))
        end
      elsif target.damagestate.typemod>=1 && target.damagestate.typemod<8
        if alltargets.length>1
          @battle.pbDisplay(_INTL("No es muy efectivo en {1}...",target.pbThis(true)))
        else
          @battle.pbDisplay(_INTL("No es muy efectivo..."))
        end
      end
      if realnumhits==1
        @battle.pbDisplay(_INTL("¡Golpeó {1} vez!",realnumhits))
      else
        @battle.pbDisplay(_INTL("¡Golpeó {1} veces!",realnumhits)) if !isConst?(thismove.id,PBMoves,:DRAGONDARTS)
      end
    end
    PBDebug.log("El movimiento golpeó #{numhits} vez(es), daño total=#{turneffects[PBEffects::TotalDamage]}")
    # Innards Out
    if target.ability==PBAbilities::INNARDSOUT && target.isFainted? &&
     thismove.pbIsDamaging? && !target.effects[PBEffects::GastroAcid]
      PBDebug.log("[Ability triggered] #{target.pbThis}'s Innards Out")
      @battle.pbDisplay(_INTL("{1} fue dañado por {3} de {2}!",user.pbThis,
      target.pbThis,PBAbilities.getName(target.ability)))
      user.pbReduceHP(turneffects[PBEffects::TotalDamage])
    end
    # Debilitamiento si llega a 0 PS
    target.pbFaint if target.isFainted? # no return
    user.pbFaint if user.isFainted? # no return
    thismove.pbEffectAfterHit(user,target,turneffects)
    target.pbFaint if target.isFainted? # no return
    user.pbFaint if user.isFainted? # no return
    # Mismo Destino
    if !user.isFainted? && target.isFainted?
      if destinybond && target.pbIsOpposing?(user.index)
        PBDebug.log("[Efecto prolongado disparado] Mismo Destino de #{target.pbThis}")
        @battle.pbDisplay(_INTL("¡{1} se llevó al atacante consigo!",target.pbThis))
        user.pbReduceHP(user.hp)
        user.pbFaint # no return
        @battle.pbJudgeCheckpoint(user)
      end
    end
    pbEffectsAfterHit(user,target,thismove,turneffects)
    # Verificación de bayas
    for j in 0...4
      @battle.battlers[j].pbBerryCureCheck
    end
    target.pbUpdateTargetedMove(thismove,user)
    user.effects[PBEffects::LastMoveFailed]=false
  end

  def pbUseMoveSimple(moveid,index=-1,target=-1)
    choice=[]
    choice[0]=1       # "Use move"
    choice[1]=index   # Índice del movimiento a ser usado entre los movimientos del usuario
    choice[2]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(moveid)) # PokeBattle_Move object of the move
    choice[2].pp=-1
    choice[3]=target  # Objetivo (-1 significa que no tiene objetivo aún)
    if index>=0
      @battle.choices[@index][1]=index
    end
    PBDebug.log("#{pbThis} usa movimiento simple #{choice[2].name}")
    side=(@battle.pbIsOpposing?(self.index)) ? 1 : 0
    owner=@battle.pbGetOwnerIndex(self.index)
    if @battle.zMove[side][owner]==self.index
      crystal = pbZCrystalFromType(choice[2].type)
      PokeBattle_ZMoves.new(@battle,self,choice[2],crystal,choice)
    else
    pbUseMove(choice,true)
    end
    return
  end

  def pbUseMove(choice,specialusage=false)
    # TODO: lastMoveUsed is not to be updated on nested calls
    # Note: user.lastMoveUsedType IS to be updated on nested calls; is used for Conversion 2
    turneffects=[]
    turneffects[PBEffects::SpecialUsage]=specialusage
    turneffects[PBEffects::SkipAccuracyCheck]=specialusage
    turneffects[PBEffects::PassedTrying]=false
    turneffects[PBEffects::TotalDamage]=0
    # Start using the move
    pbBeginTurn(choice)
    # Force the use of certain moves if they're already being used
    if @effects[PBEffects::TwoTurnAttack]>0 ||
       @effects[PBEffects::HyperBeam]>0 ||
       @effects[PBEffects::Outrage]>0 ||
       @effects[PBEffects::Rollout]>0 ||
       @effects[PBEffects::Uproar]>0 ||
       @effects[PBEffects::Bide]>0
      choice[2]=PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(@currentMove))
      turneffects[PBEffects::SpecialUsage]=true
      PBDebug.log("Continuación de movimiento multi-turnos #{choice[2].name}")
    elsif @effects[PBEffects::Encore]>0
      if @battle.pbCanShowCommands?(@index) &&
         @battle.pbCanChooseMove?(@index,@effects[PBEffects::EncoreIndex],false)
        if choice[1]!=@effects[PBEffects::EncoreIndex] # Was Encored mid-round
          choice[1]=@effects[PBEffects::EncoreIndex]
          choice[2]=@moves[@effects[PBEffects::EncoreIndex]]
          choice[3]=-1 # No target chosen
        end
        PBDebug.log("Using Encored move #{choice[2].name}")
      end
    end
    thismove=choice[2]
    return if !thismove || thismove.id==0 # if move was not chosen
    if !turneffects[PBEffects::SpecialUsage]
      # TODO: Quick Claw message
    end
    # Cambio Táctico
    if hasWorkingAbility(:STANCECHANGE) && isConst?(species,PBSpecies,:AEGISLASH) &&
       !@effects[PBEffects::Transform]
      if thismove.pbIsDamaging? && self.form!=1
        self.form=1
        pbUpdate(true)
        @battle.scene.pbChangePokemon(self,@pokemon)
        @battle.pbDisplay(_INTL("¡{1} ha cambiado a su Forma Filo!",pbThis))
        PBDebug.log("[Cambio de forma] #{pbThis} ha cambiado a su Forma Filo")
      elsif isConst?(thismove.id,PBMoves,:KINGSSHIELD) && self.form!=0
        self.form=0
        pbUpdate(true)
        @battle.scene.pbChangePokemon(self,@pokemon)
        @battle.pbDisplay(_INTL("¡{1} ha cambiado a su Forma Escudo!",pbThis))
        PBDebug.log("[Cambio de forma] #{pbThis} ha cambiado a su Forma Escudo")
      end
    end
    # Record that user has used a move this round (ot at least tried to)
    self.lastRoundMoved=@battle.turncount
    # Intenta usar el movimiento
    if !pbTryUseMove(choice,thismove,turneffects)
      self.lastMoveUsed=-1
      self.lastMoveUsedType=-1
      if !turneffects[PBEffects::SpecialUsage]
        self.lastMoveUsedSketch=-1 if self.effects[PBEffects::TwoTurnAttack]==0
        self.lastRegularMoveUsed=-1
      end
      pbCancelMoves
      @battle.pbGainEXP
      pbEndTurn(choice)
      @battle.pbJudge #      @battle.pbSwitch
      return
    end
    if !turneffects[PBEffects::SpecialUsage]
      if !pbReducePP(thismove)
        @battle.pbDisplay(_INTL("¡{1} usó\r\n{2}!",pbThis,thismove.name))
        @battle.pbDisplay(_INTL("¡Pero no le quedan PP al movimiento!"))
        self.lastMoveUsed=-1
        self.lastMoveUsedType=-1
        self.lastMoveUsedSketch=-1 if self.effects[PBEffects::TwoTurnAttack]==0
        self.lastRegularMoveUsed=-1
        pbEndTurn(choice)
        @battle.pbJudge #        @battle.pbSwitch
        PBDebug.log("[Movimiento falló] #{thismove.name} no tiene más PP")
        return
      end
    end
    # Remember that user chose a two-turn move
    if thismove.pbTwoTurnAttack(self)
      # Beginning use of two-turn attack
      @effects[PBEffects::TwoTurnAttack]=thismove.id
      @currentMove=thismove.id
    else
      @effects[PBEffects::TwoTurnAttack]=0 # Cancel use of two-turn attack
    end
    # Charge up Metronome item
    if self.lastMoveUsed==thismove.id
      self.effects[PBEffects::Metronome]+=1
    else
      self.effects[PBEffects::Metronome]=0
    end
    # "X used Y!" message
    case thismove.pbDisplayUseMessage(self)
    when 2   # Continuing Bide
      return
    when 1   # Starting Bide
      self.lastMoveUsed=thismove.id
      self.lastMoveUsedType=thismove.pbType(thismove.type,self,nil)
      if !turneffects[PBEffects::SpecialUsage]
        self.lastMoveUsedSketch=thismove.id if self.effects[PBEffects::TwoTurnAttack]==0
        self.lastRegularMoveUsed=thismove.id
      end
      @battle.lastMoveUsed=thismove.id
      @battle.lastMoveUser=self.index
      @battle.successStates[self.index].useState=2
      @battle.successStates[self.index].typemod=8
      return
    when -1   # Was hurt while readying Focus Punch, fails use
      self.lastMoveUsed=thismove.id
      self.lastMoveUsedType=thismove.pbType(thismove.type,self,nil)
      if !turneffects[PBEffects::SpecialUsage]
        self.lastMoveUsedSketch=thismove.id if self.effects[PBEffects::TwoTurnAttack]==0
        self.lastRegularMoveUsed=thismove.id
      end
      @battle.lastMoveUsed=thismove.id
      @battle.lastMoveUser=self.index
      @battle.successStates[self.index].useState=2 # somehow treated as a success
      @battle.successStates[self.index].typemod=8
      PBDebug.log("[Movimiento falló] #{pbThis} fue dañado mientras preparaba el Puño Certero")
      return
    end
    # Find the user and target(s)
    targets=[]
    user=pbFindUser(choice,targets)
    #Change to two targets for expanding force with psychic terrain
    if isConst?(thismove.id,PBMoves,:EXPANDINGFORCE) && @battle.field.effects[PBEffects::PsychicTerrain]>0 && !user.isAirborne? && @battle.doublebattle
      targets = [pbOpposing1, pbOpposing2] if (!pbOpposing1.isFainted? && !pbOpposing2.isFainted?)
    end
    # Battle Arena only - assume failure
    @battle.successStates[user.index].useState=1
    @battle.successStates[user.index].typemod=8
    # Check whether Selfdestruct works
    if !thismove.pbOnStartUse(user) # Selfdestruct, Natural Gift, Beat Up can return false here
      PBDebug.log(sprintf("[Movimiento falló] Falló pbOnStartUse (código de función %02X)",thismove.function))
      user.lastMoveUsed=thismove.id
      user.lastMoveUsedType=thismove.pbType(thismove.type,user,nil)
      if !turneffects[PBEffects::SpecialUsage]
        user.lastMoveUsedSketch=thismove.id if user.effects[PBEffects::TwoTurnAttack]==0
        user.lastRegularMoveUsed=thismove.id
      end
      @battle.lastMoveUsed=thismove.id
      @battle.lastMoveUser=user.index
      return
    end
    # Mar del Albor, Tierra del Ocaso
    if thismove.pbIsDamaging?
      case @battle.pbWeather
      when PBWeather::HEAVYRAIN
        if isConst?(thismove.pbType(thismove.type,user,nil),PBTypes,:FIRE) && !user.hasWorkingItem(:UTILITYUMBRELLA)
          PBDebug.log("[Movimiento falló] La lluvia del Mar del Albor anuló el ataque de tipo fuego #{thismove.name}")
          @battle.pbDisplay(_INTL("¡El ataque de tipo Fuego desapareció en medio del diluvio!"))
          user.lastMoveUsed=thismove.id
          user.lastMoveUsedType=thismove.pbType(thismove.type,user,nil)
          if !turneffects[PBEffects::SpecialUsage]
            user.lastMoveUsedSketch=thismove.id if user.effects[PBEffects::TwoTurnAttack]==0
            user.lastRegularMoveUsed=thismove.id
          end
          @battle.lastMoveUsed=thismove.id
          @battle.lastMoveUser=user.index
          return
        end
      when PBWeather::HARSHSUN
        if isConst?(thismove.pbType(thismove.type,user,nil),PBTypes,:WATER) && !user.hasWorkingItem(:UTILITYUMBRELLA)
          PBDebug.log("[Movimiento falló] El sol de la Tierra del Ocaso anuló el ataque de tipo Agua #{thismove.name}")
          @battle.pbDisplay(_INTL("¡El ataque de tipo Agua se evaporó por la fuerza del sol abrazador!"))
          user.lastMoveUsed=thismove.id
          user.lastMoveUsedType=thismove.pbType(thismove.type,user,nil)
          if !turneffects[PBEffects::SpecialUsage]
            user.lastMoveUsedSketch=thismove.id if user.effects[PBEffects::TwoTurnAttack]==0
            user.lastRegularMoveUsed=thismove.id
          end
          @battle.lastMoveUsed=thismove.id
          @battle.lastMoveUser=user.index
          return
        end
      end
    end
    # Polvo Explosivo
    if user.effects[PBEffects::Powder] && isConst?(thismove.pbType(thismove.type,user,nil),PBTypes,:FIRE)
      PBDebug.log("[Efecto prolongado disparado] Polvo Explosivo de anuló el movimiento de tipo Fuego")
      @battle.pbCommonAnimation("Powder",user,nil)
      @battle.pbDisplay(_INTL("¡Cuando las llamas tocaron el polvo que cubría al Pokémon, éste explotó!"))
      user.pbReduceHP(1+(user.totalhp/4).floor) if !user.hasWorkingAbility(:MAGICGUARD)
      user.lastMoveUsed=thismove.id
      user.lastMoveUsedType=thismove.pbType(thismove.type,user,nil)
      if !turneffects[PBEffects::SpecialUsage]
        user.lastMoveUsedSketch=thismove.id if user.effects[PBEffects::TwoTurnAttack]==0
        user.lastRegularMoveUsed=thismove.id
      end
      @battle.lastMoveUsed=thismove.id
      @battle.lastMoveUser=user.index
      user.pbFaint if user.isFainted?
      pbEndTurn(choice)
      return
    end
    # Mutatipo
    if (user.hasWorkingAbility(:PROTEAN) || user.hasWorkingAbility(:LIBERO)) && !user.isTera? &&
       thismove.function!=0xAE &&   # Mirror Move
       thismove.function!=0xAF &&   # Copycat
       thismove.function!=0xB0 &&   # Me First
       thismove.function!=0xB3 &&   # Nature Power
       thismove.function!=0xB4 &&   # Sleep Talk
       thismove.function!=0xB5 &&   # Assist
       thismove.function!=0xB6      # Metronome
      movetype=thismove.pbType(thismove.type,user,nil)
      unless user.turncount > 1
        if !user.pbHasType?(movetype)
          typename=PBTypes.getName(movetype)
          PBDebug.log("[Habilidad disparada] Mutatipo de #{pbThis} lo hizo de tipo #{typename}")
          user.type1=movetype
          user.type2=movetype
          user.effects[PBEffects::Type3]=-1
          @battle.pbDisplay(_INTL("¡{1} se ha transformado en tipo {2}!",user.pbThis,typename))
        end
      end
    end
    # Try to use move against user if there aren't any targets
    if targets.length==0
      user=pbChangeUser(thismove,user)
      if thismove.target==PBTargets::SingleNonUser ||
         thismove.target==PBTargets::RandomOpposing ||
         thismove.target==PBTargets::AllOpposing ||
         thismove.target==PBTargets::AllNonUsers ||
         thismove.target==PBTargets::Partner ||
         thismove.target==PBTargets::UserOrPartner ||
         thismove.target==PBTargets::SingleOpposing ||
         thismove.target==PBTargets::OppositeOpposing
        @battle.pbDisplay(_INTL("Pero no hay objetivo..."))
      else
        PBDebug.logonerr{
           thismove.pbEffect(user,nil)
        }
        # Dancer using non-damaging move
           if thismove.isDanceMove?
             for s in @battle.pbPriority(true)
               if s!=user &&
               s.hasWorkingAbility(:DANCER) &&
                 !s.isFainted?
                 @battle.pbDisplay(_INTL("¡{1} también baila!",s.pbThis))
                 PBDebug.logonerr{
                  thismove.pbEffect(s,nil)
                 }
               end
             end
           end
      end
    else
      # We have targets
      showanimation=true
      alltargets=[]
      for i in 0...targets.length
        alltargets.push(targets[i].index) if !targets.include?(targets[i].index)
      end
      # For each target in turn
      i=0; loop do break if i>=targets.length
        # Get next target
        userandtarget=[user,targets[i]]
        success=pbChangeTarget(thismove,userandtarget,targets)
        user=userandtarget[0]
        target=userandtarget[1]
        if i==0 && thismove.target==PBTargets::AllOpposing
          # Add target's partner to list of targets
          pbAddTarget(targets,target.pbPartner)
        end
        # If couldn't get the next target
        if !success
          i+=1
          next
        end
        # Get the number of hits
        numhits=thismove.pbNumHits(user)
        # Reset damage state, set Focus Band/Focus Sash to available
        target.damagestate.reset
        # Use move against the current target
        pbProcessMoveAgainstTarget(thismove,user,target,numhits,turneffects,false,alltargets,showanimation)
        showanimation=false
        i+=1
      end
    end
    # Pokémon switching caused by Roar, Whirlwind, Circle Throw, Dragon Tail, Red Card
    if !user.isFainted?
      switched=[]
      for i in 0...4
        if @battle.battlers[i].effects[PBEffects::Roar]
          @battle.battlers[i].effects[PBEffects::Roar]=false
          @battle.battlers[i].effects[PBEffects::Uturn]=false
          @battle.battlers[i].effects[PBEffects::ShedTail]=false
          next if @battle.battlers[i].isFainted?
          next if !@battle.pbCanSwitch?(i,-1,false)
          choices=[]
          party=@battle.pbParty(i)
          for j in 0...party.length
            choices.push(j) if @battle.pbCanSwitchLax?(i,j,false)
          end
          if choices.length>0
            newpoke=choices[@battle.pbRandom(choices.length)]
            newpokename=newpoke
            if isConst?(party[newpoke].ability,PBAbilities,:ILLUSION)
              newpokename=@battle.pbGetLastPokeInTeam(i)
            end
          switched.push(i)
            @battle.battlers[i].pbResetForm
            @battle.pbRecallAndReplace(i,newpoke,newpokename,false,user.hasMoldBreaker ||
            thismove.doesBypassIgnorableAbilities?)
            @battle.pbDisplay(_INTL("¡{1} ha sido arrastrado!",@battle.battlers[i].pbThis))
            @battle.choices[i]=[0,0,nil,-1]   # Replacement Pokémon does nothing this round
          end
        end
      end
      for i in @battle.pbPriority
        next if !switched.include?(i.index)
        i.pbAbilitiesOnSwitchIn(true)
      end
    end
    # Pokémon switching caused by U-Turn, Volt Switch, Eject Button
    switched=[]
    for i in 0...4
      if @battle.battlers[i].effects[PBEffects::Uturn]
        @battle.battlers[i].effects[PBEffects::Uturn]=false
        @battle.battlers[i].effects[PBEffects::Roar]=false
        if !@battle.battlers[i].isFainted? && @battle.pbCanChooseNonActive?(i) &&
           !@battle.pbAllFainted?(@battle.pbOpposingParty(i))
          # TODO: Pursuit should go here, and negate this effect if it KO's attacker
          @battle.pbDisplay(_INTL("¡{1} regresó con {2}!",@battle.battlers[i].pbThis,@battle.pbGetOwner(i).name))
          newpoke=0
          newpoke=@battle.pbSwitchInBetween(i,true,false)
          newpokename=newpoke
          if isConst?(@battle.pbParty(i)[newpoke].ability,PBAbilities,:ILLUSION)
            newpokename=@battle.pbGetLastPokeInTeam(i)
          end
          switched.push(i)
          @battle.battlers[i].pbResetForm
          @battle.pbRecallAndReplace(i,newpoke,newpokename,@battle.battlers[i].effects[PBEffects::BatonPass])
          @battle.choices[i]=[0,0,nil,-1]   # Replacement Pokémon does nothing this round
        end
      end
    end
    for i in @battle.pbPriority
      next if !switched.include?(i.index)
      i.pbAbilitiesOnSwitchIn(true)
    end
    # Relevo
    if user.effects[PBEffects::BatonPass]
      user.effects[PBEffects::BatonPass]=false
      if !user.isFainted? && @battle.pbCanChooseNonActive?(user.index) &&
         !@battle.pbAllFainted?(@battle.pbParty(user.index))
        newpoke=0
        newpoke=@battle.pbSwitchInBetween(user.index,true,false)
        newpokename=newpoke
        if isConst?(@battle.pbParty(user.index)[newpoke].ability,PBAbilities,:ILLUSION)
          newpokename=@battle.pbGetLastPokeInTeam(user.index)
        end
        user.pbResetForm
        @battle.pbRecallAndReplace(user.index,newpoke,newpokename,true)
        @battle.choices[user.index]=[0,0,nil,-1]   # Replacement Pokémon does nothing this round
        user.pbAbilitiesOnSwitchIn(true)
      end
    end
    # Plegaria Vital
    if user.effects[PBEffects::RevivalBlessing]
      user.effects[PBEffects::RevivalBlessing]=false
      if !user.isFainted? && !@battle.pbAllFainted?(@battle.pbParty(user.index))
        newpoke=0
        newpoke=@battle.pbRevivalBlessing(user.index,true,false)
        newpokemonname=newpoke
        @battle.pbRevival(index,newpoke)
        @battle.pbMessagesOnRevival(index,newpoke,newpokename)
      end
    end
    # Record move as having been used
    user.lastMoveUsed=thismove.id
    user.lastMoveUsedType=thismove.pbType(thismove.type,user,nil)
    if !turneffects[PBEffects::SpecialUsage]
      user.lastMoveUsedSketch=thismove.id if user.effects[PBEffects::TwoTurnAttack]==0
      user.lastRegularMoveUsed=thismove.id
      user.movesUsed.push(thismove.id) if !user.movesUsed.include?(thismove.id) # For Last Resort
    end
    @battle.lastMoveUsed=thismove.id
    @battle.lastMoveUser=user.index
    # Gain Exp
    @battle.pbGainEXP
    # Battle Arena only - update skills
    for i in 0...4
      @battle.successStates[i].updateSkill
    end
    # End of move usage
    pbEndTurn(choice)
    @battle.pbJudge #    @battle.pbSwitch
    return
  end

  def pbCancelMoves
    # If failed pbTryUseMove or have already used Pursuit to chase a switching foe
    # Cancel multi-turn attacks (note: Hyper Beam effect is not canceled here)
    @effects[PBEffects::TwoTurnAttack]=0 if @effects[PBEffects::TwoTurnAttack]>0
    @effects[PBEffects::Outrage]=0
    @effects[PBEffects::Rollout]=0
    @effects[PBEffects::Uproar]=0
    @effects[PBEffects::Bide]=0
    @currentMove=0
    # Reset counters for moves which increase them when used in succession
    @effects[PBEffects::FuryCutter]=0
    PBDebug.log("Cancelled using the move")
  end

################################################################################
# Turn processing
################################################################################
  def pbBeginTurn(choice)
    # Cancel some lingering effects which only apply until the user next moves
    @effects[PBEffects::DestinyBond]=false
    @effects[PBEffects::Grudge]=false
    @effects[PBEffects::Dancer]=false
    # Reset Parental Bond's count
    @effects[PBEffects::ParentalBond]=0
    # Encore's effect ends if the encored move is no longer available
    if @effects[PBEffects::Encore]>0 &&
       @moves[@effects[PBEffects::EncoreIndex]].id!=@effects[PBEffects::EncoreMove]
      PBDebug.log("Resetting Encore effect")
      @effects[PBEffects::Encore]=0
      @effects[PBEffects::EncoreIndex]=0
      @effects[PBEffects::EncoreMove]=0
    end
    # Wake up in an uproar
    if self.status==PBStatuses::SLEEP && !self.hasWorkingAbility(:SOUNDPROOF)
      for i in 0...4
        if @battle.battlers[i].effects[PBEffects::Uproar]>0
          pbCureStatus(false)
          @battle.pbDisplay(_INTL("¡{1} se despertó con el Alboroto!",pbThis))
        end
      end
    end
  end

  def pbEndTurn(choice)
    # True end(?)
    if @effects[PBEffects::ChoiceBand]<0 && @lastMoveUsed>=0 && !self.isFainted? &&
       (self.hasWorkingItem(:CHOICEBAND) ||
       self.hasWorkingItem(:CHOICESPECS) ||
       self.hasWorkingItem(:CHOICESCARF))
      @effects[PBEffects::ChoiceBand]=@lastMoveUsed
    end
    if @effects[PBEffects::GorillaTactics]<0 && @lastMoveUsed>=0 && !isFainted? &&
       self.hasWorkingAbility(:GORILLATACTICS)
      @effects[PBEffects::GorillaTactics]=@lastMoveUsed
    end
    @battle.pbPrimordialWeather
    for i in 0...4
      @battle.battlers[i].pbBerryCureCheck
    end
    for i in 0...4
      @battle.battlers[i].pbAbilityCureCheck
    end
    for i in 0...4
      @battle.battlers[i].pbAbilitiesOnSwitchIn(false)
    end
    for i in 0...4
      @battle.battlers[i].pbCheckForm
      @battle.battlers[i].effects[PBEffects::Dancer]=false
    end
  end

  def pbProcessTurn(choice)
    # Can't use a move if fainted
    return false if self.isFainted?
    # Wild roaming Pokémon always flee if possible
    if !@battle.opponent && @battle.pbIsOpposing?(self.index) &&
       @battle.rules["alwaysflee"] && @battle.pbCanRun?(self.index)
      pbBeginTurn(choice)
      @battle.pbDisplay(_INTL("¡{1} ha huido!",self.pbThis))
      @battle.decision=3
      pbEndTurn(choice)
      PBDebug.log("[Huida] #{pbThis} ha huido")
      return true
    end
    # If this battler's action for this round wasn't "use a move"
    if choice[0]!=1
      # Clean up effects that end at battler's turn
      pbBeginTurn(choice)
      pbEndTurn(choice)
      return false
    end
    # Turn is skipped if Pursuit was used during switch
    if @effects[PBEffects::Pursuit]
      @effects[PBEffects::Pursuit]=false
      pbCancelMoves
      pbEndTurn(choice)
      @battle.pbJudge #      @battle.pbSwitch
      return false
    end
    # Use the move
    if choice[2].zmove
      choice[2].zmove=false
      @battle.pbUseZMove(self.index,choice[2],self.item)
    else
#   @battle.pbDisplayPaused("Before: [#{@lastMoveUsedSketch},#{@lastMoveUsed}]")
    PBDebug.log("#{pbThis} usó #{choice[2].name}")
    PBDebug.logonerr{
       pbUseMove(choice,choice[2]==@battle.struggle)
    }
    end
#   @battle.pbDisplayPaused("After: [#{@lastMoveUsedSketch},#{@lastMoveUsed}]")
    return true
  end
end
