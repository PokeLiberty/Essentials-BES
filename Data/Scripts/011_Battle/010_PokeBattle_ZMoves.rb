class PokeBattle_ZMoves < PokeBattle_Move
  attr_accessor(:id)
  attr_reader(:battle)
  attr_reader(:name)
  attr_reader(:function)
  attr_accessor(:basedamage)
  attr_reader(:type)
  attr_reader(:accuracy)
  attr_reader(:addlEffect)
  attr_reader(:target)
  attr_reader(:priority)
  attr_reader(:flags)
  attr_reader(:category)
  attr_reader(:thismove)
  attr_accessor(:pp)
  attr_accessor(:totalpp)
  attr_reader(:oldmove)
  attr_reader(:status)
  attr_reader(:oldname)
  attr_accessor(:zmove)
################################################################################
# Creating a z move
################################################################################
  def initialize(battle,battler,move,crystal,simplechoice=false)
    @status     = !(move.pbIsPhysical?(move.type) || move.pbIsSpecial?(move.type))
    @oldmove    = move
    @oldname    = move.name
    @id         = pbZMoveId(move,crystal)
    @battle     = battle
    @name       = pbZMoveName(move,crystal)
    @nameEspanol= pbZMoveName2(move,crystal)
    # Get data on the move
    oldmovedata = PBMoveData.new(move.id)
    @function   = pbZMoveFunction(move,crystal)
    @basedamage = pbZMoveBaseDamage(move,crystal)
    @type       = move.type
    @accuracy   = pbZMoveAccuracy(move,crystal)
    @addlEffect = 0
    @target     = move.target
    @priority   = @oldmove.priority
    @flags      = pbZMoveFlags(move,crystal)
    if @flags.is_a?(String)
      f=0
      i=@flags
      f+=1 if i.include?("a")
      f+=2 if i.include?("b")
      f+=4 if i.include?("c")
      f+=8 if i.include?("d")
      f+=16 if i.include?("e")
      f+=32 if i.include?("f")
      @flags=f
    end
    @category   = oldmovedata.category
    @pp         = 1
    @totalpp    = 1
    @thismove   = self #move
    @zmove      = true
    if !@status
      @priority = 0
    end

    moveZname = @nameEspanol

    battler.pbBeginTurn(self)
    if !@status
      @battle.pbDisplayBrief(_INTL("¡{1} liberó todo el poder de su movimiento Z!",battler.pbThis))
      @battle.pbDisplayBrief(_INTL("¡{1}!",moveZname)) if moveZname
    end
    zchoice=@battle.choices[battler.index] #[0,0,move,move.target]
    if simplechoice!=false
      zchoice=simplechoice
    end
    ztargets=[]
    user=battler.pbFindUser(zchoice,ztargets)


    if ztargets.length==0
      if @thismove.target==PBTargets::SingleNonUser ||
         @thismove.target==PBTargets::RandomOpposing ||
         @thismove.target==PBTargets::AllOpposing ||
         @thismove.target==PBTargets::AllNonUsers ||
         @thismove.target==PBTargets::Partner ||
         @thismove.target==PBTargets::UserOrPartner ||
         @thismove.target==PBTargets::SingleOpposing ||
         @thismove.target==PBTargets::OppositeOpposing
        @battle.pbDisplay(_INTL("Pero no habia objetivo..."))
      else
        #selftarget status moves here
        pbZStatus(@id,battler)
        battler.pbUseMove(zchoice,true)
        #zchoice[2].name = moveZname

        #@oldmove.name = @oldname.to_s if @oldname
      end
    else
      if @status
        #targeted status Z's here
        pbZStatus(@id,battler)
        battler.pbUseMove(zchoice,true)
        #zchoice[2].name = moveZname
        #@oldmove.name = @oldname.to_s if @oldname
      else
        turneffects=[]
        turneffects[PBEffects::SpecialUsage]=false
        turneffects[PBEffects::PassedTrying]=false
        turneffects[PBEffects::TotalDamage]=0
        battler.pbProcessMoveAgainstTarget(@thismove,user,ztargets[0],1,turneffects,true,nil,true)
        battler.pbReducePPOther(@oldmove)
      end
    end
  end

  def pbZMoveId(oldmove,crystal)
    if @status
      return oldmove.id
    else
      case crystal
      when getID(PBItems,:NORMALIUMZ)   ;return "Z001"
      when getID(PBItems,:FIGHTINIUMZ)  ;return "Z002"
      when getID(PBItems,:FLYINIUMZ)    ;return "Z003"
      when getID(PBItems,:POISONIUMZ)   ;return "Z004"
      when getID(PBItems,:GROUNDIUMZ)   ;return "Z005"
      when getID(PBItems,:ROCKIUMZ)     ;return "Z006"
      when getID(PBItems,:BUGINIUMZ)    ;return "Z007"
      when getID(PBItems,:GHOSTIUMZ)    ;return "Z008"
      when getID(PBItems,:STEELIUMZ)    ;return "Z009"
      when getID(PBItems,:FIRIUMZ)      ;return "Z010"
      when getID(PBItems,:WATERIUMZ)    ;return "Z011"
      when getID(PBItems,:GRASSIUMZ)    ;return "Z012"
      when getID(PBItems,:ELECTRIUMZ)   ;return "Z013"
      when getID(PBItems,:PSYCHIUMZ)    ;return "Z014"
      when getID(PBItems,:ICIUMZ)       ;return "Z015"
      when getID(PBItems,:DRAGONIUMZ)   ;return "Z016"
      when getID(PBItems,:DARKINIUMZ)   ;return "Z017"
      when getID(PBItems,:FAIRIUMZ)     ;return "Z018"
      when getID(PBItems,:ALORAICHIUMZ) ;return "Z019"
      when getID(PBItems,:DECIDIUMZ)    ;return "Z020"
      when getID(PBItems,:INCINIUMZ)    ;return "Z021"
      when getID(PBItems,:PRIMARIUMZ)   ;return "Z022"
      when getID(PBItems,:EEVIUMZ)      ;return "Z023"
      when getID(PBItems,:PIKANIUMZ)    ;return "Z024"
      when getID(PBItems,:SNORLIUMZ)    ;return "Z025"
      when getID(PBItems,:MEWNIUMZ)     ;return "Z026"
      when getID(PBItems,:TAPUNIUMZ)    ;return "Z027"
      when getID(PBItems,:MARSHADIUMZ)  ;return "Z028"
      when getID(PBItems,:PIKASHUNIUMZ) ;return "Z029"
      when getID(PBItems,:ULTRANECROZIUMZ) ;return "Z030"
      when getID(PBItems,:LYCANIUMZ)  ;return "Z031"
      when getID(PBItems,:MIMIKIUMZ)  ;return "Z032"
      when getID(PBItems,:KOMMONIUMZ) ;return "Z033"
      when getID(PBItems,:SOLGANIUMZ) ;return "Z034"
      when getID(PBItems,:LUNALIUMZ)  ;return "Z035"

      end
    end
  end

  def pbZMoveName(oldmove,crystal)
    if @status
      return "Z-" + oldmove.name
    else
      case crystal
      when getID(PBItems,:NORMALIUMZ)  ;return "Breakneck Blitz"
      when getID(PBItems,:FIGHTINIUMZ) ;return "All-Out Pummeling"
      when getID(PBItems,:FLYINIUMZ)   ;return "Supersonic Skystrike"
      when getID(PBItems,:POISONIUMZ)  ;return "Acid Downpour"
      when getID(PBItems,:GROUNDIUMZ)  ;return "Tectonic Rage"
      when getID(PBItems,:ROCKIUMZ)    ;return "Continental Crush"
      when getID(PBItems,:BUGINIUMZ)   ;return "Savage Spin-Out"
      when getID(PBItems,:GHOSTIUMZ)   ;return "Never-Ending Nightmare"
      when getID(PBItems,:STEELIUMZ)   ;return "Corkscrew Crash"
      when getID(PBItems,:FIRIUMZ)     ;return "Inferno Overdrive"
      when getID(PBItems,:WATERIUMZ)   ;return "Hydro Vortex"
      when getID(PBItems,:GRASSIUMZ)   ;return "Bloom Doom"
      when getID(PBItems,:ELECTRIUMZ)  ;return "Gigavolt Havoc"
      when getID(PBItems,:PSYCHIUMZ)   ;return "Shattered Psyche"
      when getID(PBItems,:ICIUMZ)      ;return "Subzero Slammer"
      when getID(PBItems,:DRAGONIUMZ)  ;return "Devastating Drake"
      when getID(PBItems,:DARKINIUMZ)  ;return "Black Hole Eclipse"
      when getID(PBItems,:FAIRIUMZ)    ;return "Twinkle Tackle"
      when getID(PBItems,:ALORAICHIUMZ);return "Stoked Sparksurfer"
      when getID(PBItems,:DECIDIUMZ)   ;return "Sinister Arrow Raid"
      when getID(PBItems,:INCINIUMZ)   ;return "Malicious Moonsault"
      when getID(PBItems,:PRIMARIUMZ)  ;return "Oceanic Operetta"
      when getID(PBItems,:EEVIUMZ)     ;return "Extreme Evoboost"
      when getID(PBItems,:PIKANIUMZ)   ;return "Catastropika"
      when getID(PBItems,:SNORLIUMZ)   ;return "Pulverizing Pancake"
      when getID(PBItems,:MEWNIUMZ)    ;return "Genesis Supernova"
      when getID(PBItems,:TAPUNIUMZ)   ;return "Guardian of Alola"
      when getID(PBItems,:MARSHADIUMZ) ;return "Soul-Stealing 7-Star Strike"
      when getID(PBItems,:PIKASHUNIUMZ);return "10,000,000 Volt Tunderbolt"
      when getID(PBItems,:ULTRANECROZIUMZ) ;return "Light That Burns the Sky"
      when getID(PBItems,:LYCANIUMZ)  ;return "Splintered Stormshards"
      when getID(PBItems,:MIMIKIUMZ)  ;return "Let's Snuggle Forever"
      when getID(PBItems,:KOMMONIUMZ) ;return "Clangorous Soulblaze"
      when getID(PBItems,:SOLGANIUMZ) ;return "Searing Sunraze Smash"
      when getID(PBItems,:LUNALIUMZ)  ;return "Menacing Moonraze Maelstrom"
      end
    end
  end

  #BES-T ZMOVES EN ESPAÑOL
  def pbZMoveName2(oldmove,crystal)
    if @status
      return oldmove.name + "Z"
    else
      case crystal
      when getID(PBItems,:NORMALIUMZ)  ;return "Carrera arrolladora"
      when getID(PBItems,:FIGHTINIUMZ) ;return "Ráfaga demoledora"
      when getID(PBItems,:FLYINIUMZ)   ;return "Picado supersónico"
      when getID(PBItems,:POISONIUMZ)  ;return "Diluvio corrosivo"
      when getID(PBItems,:GROUNDIUMZ)  ;return "Barrena telúrica"
      when getID(PBItems,:ROCKIUMZ)    ;return "Aplastamiento gigalítico"
      when getID(PBItems,:BUGINIUMZ)   ;return "Guadaña sedosa"
      when getID(PBItems,:GHOSTIUMZ)   ;return "Presa espectral"
      when getID(PBItems,:STEELIUMZ)   ;return "Hélice trepanadora"
      when getID(PBItems,:FIRIUMZ)     ;return "Hecatombe pírica"
      when getID(PBItems,:WATERIUMZ)   ;return "Hidrovórtice abisal"
      when getID(PBItems,:GRASSIUMZ)   ;return "Megatón floral"
      when getID(PBItems,:ELECTRIUMZ)  ;return "Gigavoltio destructor"
      when getID(PBItems,:PSYCHIUMZ)   ;return "Disruptor psíquico"
      when getID(PBItems,:ICIUMZ)      ;return "Crioaliento despiadado"
      when getID(PBItems,:DRAGONIUMZ)  ;return "Dracoaliento devastador"
      when getID(PBItems,:DARKINIUMZ)  ;return "Agujero negro aniquilador"
      when getID(PBItems,:FAIRIUMZ)    ;return "Arrumaco sideral"
      when getID(PBItems,:ALORAICHIUMZ);return "Surfeo galvánico"
      when getID(PBItems,:DECIDIUMZ)   ;return "Aluvión de flechas sombrías"
      when getID(PBItems,:INCINIUMZ)   ;return "Hiperplancha oscura"
      when getID(PBItems,:PRIMARIUMZ)  ;return "Sinfonía de la diva marina"
      when getID(PBItems,:EEVIUMZ)     ;return "Novena potencia"
      when getID(PBItems,:PIKANIUMZ)   ;return "Pikavoltio letal"
      when getID(PBItems,:SNORLIUMZ)   ;return "Arrojo intempestivo"
      when getID(PBItems,:MEWNIUMZ)    ;return "Supernova original"
      when getID(PBItems,:TAPUNIUMZ)   ;return "Cólera del guardián"
      when getID(PBItems,:MARSHADIUMZ) ;return "Constelación robaalmas"
      when getID(PBItems,:PIKASHUNIUMZ);return "Gigarrayo fulminante"
      when getID(PBItems,:ULTRANECROZIUMZ) ;return "Fotodestrucción apocalíptica"
      when getID(PBItems,:LYCANIUMZ)  ;return "Tempestad rocosa"
      when getID(PBItems,:MIMIKIUMZ)  ;return "Somanta amistosa"
      when getID(PBItems,:KOMMONIUMZ) ;return "Estruendo implacable"
      when getID(PBItems,:SOLGANIUMZ) ;return "Embestida solar"
      when getID(PBItems,:LUNALIUMZ)  ;return "Deflagración lunar"
      end
    end
  end

  def pbZMoveFunction(oldmove,crystal)
    if @status
      return oldmove.function
    else
      "Z"
    end
  end

  def pbZMoveBaseDamage(oldmove,crystal)
    if @status
      return 0
    else
      case crystal
      when getID(PBItems,:ALORAICHIUMZ) ;return 175
      when getID(PBItems,:DECIDIUMZ)    ;return 180
      when getID(PBItems,:INCINIUMZ)    ;return 180
      when getID(PBItems,:PRIMARIUMZ)   ;return 195
      when getID(PBItems,:EEVIUMZ)      ;return 0
      when getID(PBItems,:PIKANIUMZ)    ;return 210
      when getID(PBItems,:SNORLIUMZ)    ;return 210
      when getID(PBItems,:MEWNIUMZ)     ;return 185
      when getID(PBItems,:TAPUNIUMZ)    ;return 0
      when getID(PBItems,:MARSHADIUMZ)  ;return 195
      when getID(PBItems,:PIKASHUNIUMZ) ;return 195
      when getID(PBItems,:ULTRANECROZIUMZ) ;return 200
      when getID(PBItems,:LYCANIUMZ)  ;return 190
      when getID(PBItems,:MIMIKIUMZ)  ;return 190
      when getID(PBItems,:KOMMONIUMZ) ;return 185
      when getID(PBItems,:SOLGANIUMZ) ;return 200
      when getID(PBItems,:LUNALIUMZ)  ;return 200

      else
        case @oldmove.id
        when getID(PBMoves,:MEGADRAIN)    ;return 120
        when getID(PBMoves,:WEATHERBALL)  ;return 160
        when getID(PBMoves,:HEX)          ;return 160
        when getID(PBMoves,:GEARGRIND)    ;return 180
        when getID(PBMoves,:VCREATE)      ;return 220
        when getID(PBMoves,:FLYINGPRESS)  ;return 170
        when getID(PBMoves,:COREENFORCER) ;return 140
        else
          check=@oldmove.basedamage
          if check<56
            return 100
          elsif check<66
            return 120
          elsif check<76
            return 140
          elsif check<86
            return 160
          elsif check<96
            return 175
          elsif check<101
            return 180
          elsif check<111
            return 185
          elsif check<126
            return 190
          elsif check<131
            return 195
          elsif check>139
            return 200
          end
        end
      end
    end
  end

  def pbZMoveAccuracy(oldmove,crystal)
    if @status
      return oldmove.accuracy
    else
      return 0 #Z Moves can't miss
    end
  end


  def pbZMoveFlags(oldmove,crystal)
    if @status
      return oldmove.flags
    else
      case crystal
      when getID(PBItems,:NORMALIUMZ)  ;return ""
      when getID(PBItems,:FIGHTINIUMZ) ;return ""
      when getID(PBItems,:FLYINIUMZ)   ;return ""
      when getID(PBItems,:POISONIUMZ)  ;return ""
      when getID(PBItems,:GROUNDIUMZ)  ;return ""
      when getID(PBItems,:ROCKIUMZ)    ;return ""
      when getID(PBItems,:BUGINIUMZ)   ;return ""
      when getID(PBItems,:GHOSTIUMZ)   ;return ""
      when getID(PBItems,:STEELIUMZ)   ;return ""
      when getID(PBItems,:FIRIUMZ)     ;return ""
      when getID(PBItems,:WATERIUMZ)   ;return ""
      when getID(PBItems,:GRASSIUMZ)   ;return ""
      when getID(PBItems,:ELECTRIUMZ)  ;return ""
      when getID(PBItems,:PSYCHIUMZ)   ;return ""
      when getID(PBItems,:ICIUMZ)      ;return ""
      when getID(PBItems,:DRAGONIUMZ)  ;return ""
      when getID(PBItems,:DARKINIUMZ)  ;return ""
      when getID(PBItems,:FAIRIUMZ)    ;return ""
      when getID(PBItems,:ALORAICHIUMZ);return "f"
      when getID(PBItems,:DECIDIUMZ)   ;return "f"
      when getID(PBItems,:INCINIUMZ)   ;return "af"
      when getID(PBItems,:PRIMARIUMZ)  ;return "f"
      when getID(PBItems,:EEVIUMZ)     ;return ""
      when getID(PBItems,:PIKANIUMZ)   ;return "af"
      when getID(PBItems,:SNORLIUMZ)   ;return "af"
      when getID(PBItems,:MEWNIUMZ)    ;return ""
      when getID(PBItems,:TAPUNIUMZ)   ;return "f"
      when getID(PBItems,:MARSHADIUMZ) ;return "a"
      when getID(PBItems,:PIKASHUNIUMZ);return ""
      when getID(PBItems,:ULTRANECROZIUMZ);return ""
      when getID(PBItems,:LYCANIUMZ)  ;return ""
      when getID(PBItems,:MIMIKIUMZ)  ;return ""
      when getID(PBItems,:KOMMONIUMZ) ;return ""
      when getID(PBItems,:SOLGANIUMZ) ;return ""
      when getID(PBItems,:LUNALIUMZ)  ;return ""
      end
    end
  end

################################################################################
# PokeBattle_Move Features needed for move use
################################################################################
  def pbIsSpecial?(type)
    @oldmove.pbIsSpecial?(type)
  end

  def pbIsPhysical?(type)
    @oldmove.pbIsPhysical?(type)
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return 0 if !opponent
    if @id == "Z027" # Guardian of Alola
      return pbEffectFixedDamage((opponent.hp*3/4).floor,attacker,opponent,hitnum,alltargets,showanimation)
    elsif @id == "Z023" # Extreme Evoboost
      if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        @battle.pbDisplay(_INTL("¡Las característiscas de {1} están al máximo!",attacker.pbThis))
        return -1
      end
      pbShowAnimation(@name,attacker,nil,hitnum,alltargets,showanimation)
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,false,true,nil,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,2,false,true,nil,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,2,false,true,nil,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,2,false,true,nil,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,2,false,true,nil,showanim)
        showanim=false
      end
      attacker.lastRoundMoved=@battle.turncount
      return 0
    end
    damage=pbCalcDamage(attacker,opponent)
    if opponent.damagestate.typemod!=0
      pbShowAnimation(@name,attacker,opponent,hitnum,alltargets,showanimation)
    end
    damage=pbReduceHPDamage(damage,attacker,opponent)
    pbEffectMessages(attacker,opponent)
    pbOnDamageLost(damage,attacker,opponent)
    if @id == "Z019" # Stoked Sparksurfer
      if opponent.pbCanParalyze?(false)
        opponent.pbParalyze(attacker)
        @battle.pbDisplay(_INTL("¡{1} está paralizado!  Puede que no se mueva",opponent.pbThis))
      end
    end
    attacker.lastRoundMoved=@battle.turncount
    return damage
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    if !opponent.effects[PBEffects::ProtectNegation] && (opponent.pbOwnSide.effects[PBEffects::MatBlock] ||
      opponent.effects[PBEffects::Protect] || opponent.effects[PBEffects::SpikyShield])
      @battle.pbDisplay(_INTL("¡{1} no pudo protegerse completamente!",opponent.pbThis))
      return (damagemult/4).floor
    else
      return damagemult
    end
  end

  def pbType(type,attacker,opponent)
    return @type
  end

  def pbCanUseWhileAsleep?
    return false
  end

  def isDanceMove?
    return false
  end

  def pbTargetsMultiple?(attacker)
    return false
  end

  def hasHighCriticalRate?
    return false
  end

################################################################################
# PokeBattle_ActualScene Feature for playing animation (based on common anims)
################################################################################

  def pbShowAnimation(movename,user,target,hitnum=0,alltargets=nil,showanimation=true)
    animname=movename.delete(" ").delete("-").upcase
    animations=load_data("Data/PkmnAnimations.rxdata")
    for i in 0...animations.length
      if @battle.pbBelongsToPlayer?(user.index)
        if animations[i] && animations[i].name=="ZMove:"+animname && showanimation
          @battle.scene.pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
          return
        end
      else
        if animations[i] && animations[i].name=="OppZMove:"+animname && showanimation
          @battle.scene.pbAnimationCore(animations[i],target,(user!=nil) ? user : target)
          return
        elsif animations[i] && animations[i].name=="ZMove:"+animname && showanimation
          @battle.scene.pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
          return
        end
      end
    end
  end

################################################################################
# Z Status Effect check
################################################################################

  def pbZStatus(move,attacker)
    atk1 =   [getID(PBMoves,:BULKUP),getID(PBMoves,:HONECLAWS),getID(PBMoves,:HOWL),getID(PBMoves,:LASERFOCUS),getID(PBMoves,:LEER),getID(PBMoves,:MEDITATE),getID(PBMoves,:ODORSLEUTH),getID(PBMoves,:POWERTRICK),getID(PBMoves,:ROTOTILLER),getID(PBMoves,:SCREECH),getID(PBMoves,:SHARPEN),getID(PBMoves,:TAILWHIP),getID(PBMoves,:TAUNT),getID(PBMoves,:TOPSYTURVY),getID(PBMoves,:WILLOWISP),getID(PBMoves,:WORKUP)]
    atk2 =   [getID(PBMoves,:MIRRORMOVE)]
    atk3 =   [getID(PBMoves,:SPLASH)]
    def1 =   [getID(PBMoves,:AQUARING),getID(PBMoves,:BABYDOLLEYES),getID(PBMoves,:BANEFULBUNKER),getID(PBMoves,:BLOCK),getID(PBMoves,:CHARM),getID(PBMoves,:DEFENDORDER),getID(PBMoves,:FAIRYLOCK),getID(PBMoves,:FLOWERSHIELD),getID(PBMoves,:GRASSYTERRAIN),getID(PBMoves,:GROWL),getID(PBMoves,:HARDEN),getID(PBMoves,:MATBLOCK),getID(PBMoves,:NOBLEROAR),getID(PBMoves,:PAINSPLIT),getID(PBMoves,:PLAYNICE),getID(PBMoves,:POISONGAS),getID(PBMoves,:POISONPOWDER),getID(PBMoves,:QUICKGUARD),getID(PBMoves,:REFLECT),getID(PBMoves,:ROAR),getID(PBMoves,:SPIDERWEB),getID(PBMoves,:SPIKES),getID(PBMoves,:SPIKYSHIELD),getID(PBMoves,:STEALTHROCK),getID(PBMoves,:STRENGTHSAP),getID(PBMoves,:TEARFULLOOK),getID(PBMoves,:TICKLE),getID(PBMoves,:TORMENT),getID(PBMoves,:TOXIC),getID(PBMoves,:TOXICSPIKES),getID(PBMoves,:VENOMDRENCH),getID(PBMoves,:WIDEGUARD),getID(PBMoves,:WITHDRAW)]
    def2 =   []
    def3 =   []
    spatk1 = [getID(PBMoves,:CONFUSERAY),getID(PBMoves,:ELECTRIFY),getID(PBMoves,:EMBARGO),getID(PBMoves,:FAKETEARS),getID(PBMoves,:GEARUP),getID(PBMoves,:GRAVITY),getID(PBMoves,:GROWTH),getID(PBMoves,:INSTRUCT),getID(PBMoves,:IONDELUGE),getID(PBMoves,:METALSOUND),getID(PBMoves,:MINDREADER),getID(PBMoves,:MIRACLEEYE),getID(PBMoves,:NIGHTMARE),getID(PBMoves,:PSYCHICTERRAIN),getID(PBMoves,:REFLECTTYPE),getID(PBMoves,:SIMPLEBEAM),getID(PBMoves,:SOAK),getID(PBMoves,:SWEETKISS),getID(PBMoves,:TELEKINESIS)]
    spatk2 = [getID(PBMoves,:HEALBLOCK),getID(PBMoves,:PSYCHOSHIFT)]
    spatk3 = []
    spdef1 = [getID(PBMoves,:CHARGE),getID(PBMoves,:CONFIDE),getID(PBMoves,:COSMICPOWER),getID(PBMoves,:CRAFTYSHIELD),getID(PBMoves,:EERIEIMPULSE),getID(PBMoves,:ENTRAINMENT),getID(PBMoves,:FLATTER),getID(PBMoves,:GLARE),getID(PBMoves,:INGRAIN),getID(PBMoves,:LIGHTSCREEN),getID(PBMoves,:MAGICROOM),getID(PBMoves,:MAGNETICFLUX),getID(PBMoves,:MEANLOOK),getID(PBMoves,:MISTYTERRAIN),getID(PBMoves,:MUDSPORT),getID(PBMoves,:SPOTLIGHT),getID(PBMoves,:STUNSPORE),getID(PBMoves,:THUNDERWAVE),getID(PBMoves,:WATERSPORT),getID(PBMoves,:WHIRLWIND),getID(PBMoves,:WISH),getID(PBMoves,:WONDERROOM)]
    spdef2 = [getID(PBMoves,:AROMATICMIST),getID(PBMoves,:CAPTIVATE),getID(PBMoves,:IMPRISON),getID(PBMoves,:MAGICCOAT),getID(PBMoves,:POWDER)]
    spdef3 = []
    speed1 = [getID(PBMoves,:AFTERYOU),getID(PBMoves,:AURORAVEIL),getID(PBMoves,:ELECTRICTERRAIN),getID(PBMoves,:ENCORE),getID(PBMoves,:GASTROACID),getID(PBMoves,:GRASSWHISTLE),getID(PBMoves,:GUARDSPLIT),getID(PBMoves,:GUARDSWAP),getID(PBMoves,:HAIL),getID(PBMoves,:HYPNOSIS),getID(PBMoves,:LOCKON),getID(PBMoves,:LOVELYKISS),getID(PBMoves,:POWERSPLIT),getID(PBMoves,:POWERSWAP),getID(PBMoves,:QUASH),getID(PBMoves,:RAINDANCE),getID(PBMoves,:ROLEPLAY),getID(PBMoves,:SAFEGUARD),getID(PBMoves,:SANDSTORM),getID(PBMoves,:SCARYFACE),getID(PBMoves,:SING),getID(PBMoves,:SKILLSWAP),getID(PBMoves,:SLEEPPOWDER),getID(PBMoves,:SPEEDSWAP),getID(PBMoves,:STICKYWEB),getID(PBMoves,:STRINGSHOT),getID(PBMoves,:SUNNYDAY),getID(PBMoves,:SUPERSONIC),getID(PBMoves,:TOXICTHREAD),getID(PBMoves,:WORRYSEED),getID(PBMoves,:YAWN)]
    speed2 = [getID(PBMoves,:ALLYSWITCH),getID(PBMoves,:BESTOW),getID(PBMoves,:MEFIRST),getID(PBMoves,:RECYCLE),getID(PBMoves,:SNATCH),getID(PBMoves,:SWITCHEROO),getID(PBMoves,:TRICK)]
    speed3 = []
    acc1   = [getID(PBMoves,:COPYCAT),getID(PBMoves,:DEFENSECURL),getID(PBMoves,:DEFOG),getID(PBMoves,:FOCUSENERGY),getID(PBMoves,:MIMIC),getID(PBMoves,:SWEETSCENT),getID(PBMoves,:TRICKROOM)]
    acc2   = []
    acc3   = []
    eva1   = [getID(PBMoves,:CAMOFLAUGE),getID(PBMoves,:DETECT),getID(PBMoves,:FLASH),getID(PBMoves,:KINESIS),getID(PBMoves,:LUCKYCHANT),getID(PBMoves,:MAGNETRISE),getID(PBMoves,:SANDATTACK),getID(PBMoves,:SMOKESCREEN)]
    eva2   = []
    eva3   = []
    stat1  = [getID(PBMoves,:CELEBRATE),getID(PBMoves,:CONVERSION),getID(PBMoves,:FORESTSCURSE),getID(PBMoves,:GEOMANCY),getID(PBMoves,:HAPPYHOUR),getID(PBMoves,:HOLDHANDS),getID(PBMoves,:PURIFY),getID(PBMoves,:SKETCH),getID(PBMoves,:TRICKORTREAT)]
    stat2  = []
    stat3  = []
    crit1  = [getID(PBMoves,:ACUPRESSIRE),getID(PBMoves,:FORESIGHT),getID(PBMoves,:HEARTSWAP),getID(PBMoves,:SLEEPTALK),getID(PBMoves,:TAILWIND)]
    reset  = [getID(PBMoves,:ACIDARMOR),getID(PBMoves,:AGILITY),getID(PBMoves,:AMNESIA),getID(PBMoves,:ATTRACT),getID(PBMoves,:AUTOTOMIZE),getID(PBMoves,:BARRIER),getID(PBMoves,:BATONPASS),getID(PBMoves,:CALMMIND),getID(PBMoves,:COIL),getID(PBMoves,:COTTONGUARD),getID(PBMoves,:COTTONSPORE),getID(PBMoves,:DARKVOID),getID(PBMoves,:DISABLE),getID(PBMoves,:DOUBLETEAM),getID(PBMoves,:ENDURE),getID(PBMoves,:FLORALHEALING),getID(PBMoves,:FOLLOWME),getID(PBMoves,:HEALORDER),getID(PBMoves,:HEALPULSE),getID(PBMoves,:HELPINGHAND),getID(PBMoves,:IRONDEFENSE),getID(PBMoves,:KINGSSHIELD),getID(PBMoves,:LEECHSEED),getID(PBMoves,:MILKDRINK),getID(PBMoves,:MINIMIZE),getID(PBMoves,:MOONLIGHT),getID(PBMoves,:MORNINGSUN),getID(PBMoves,:NASTYPLOT),getID(PBMoves,:PERISHSONG),getID(PBMoves,:PROTECT),getID(PBMoves,:RAGEPOWDER),getID(PBMoves,:RECOVER),getID(PBMoves,:REST),getID(PBMoves,:ROCKPOLISH),getID(PBMoves,:ROOST),getID(PBMoves,:SHELLSMASH),getID(PBMoves,:SHIFTGEAR),getID(PBMoves,:SHOREUP),getID(PBMoves,:SHELLSMASH),getID(PBMoves,:SHIFTGEAR),getID(PBMoves,:SHOREUP),getID(PBMoves,:SLACKOFF),getID(PBMoves,:SOFTBOILED),getID(PBMoves,:SPORE),getID(PBMoves,:SUBSTITUTE),getID(PBMoves,:SWAGGER),getID(PBMoves,:SWALLOW),getID(PBMoves,:SYNTHESIS),getID(PBMoves,:TAILGLOW)]
    heal   = [getID(PBMoves,:AROMATHERAPY),getID(PBMoves,:BELLYDRUM),getID(PBMoves,:CONVERSION2),getID(PBMoves,:HAZE),getID(PBMoves,:HEALBELL),getID(PBMoves,:MIST),getID(PBMoves,:PSYCHUP),getID(PBMoves,:REFRESH),getID(PBMoves,:SPITE),getID(PBMoves,:STOCKPILE),getID(PBMoves,:TELEPORT),getID(PBMoves,:TRANSFORM)]
    heal2  = [getID(PBMoves,:MEMENTO),getID(PBMoves,:PARTINGSHOT)]
    centre = [getID(PBMoves,:DESTINYBOND),getID(PBMoves,:GRUDGE)]
    if atk1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡El Ataque de {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif atk2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡El Ataque de {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif atk3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡El Ataque de {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif def1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Defensa de {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif def2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Defensa de {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif def3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Defensa de {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif spatk1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡El Ataque Especial {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif spatk2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡El Ataque Especial {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif spatk3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡El Ataque Especial {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif spdef1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Defensa Especial {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif spdef2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Defensa Especial {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif spdef3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Defensa Especial {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif speed1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Velocidad {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif speed2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Velocidad {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif speed3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Velocidad {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif acc1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
        attacker.pbIncreaseStat(PBStats::ACCURACY,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Precisión {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif acc2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
        attacker.pbIncreaseStat(PBStats::ACCURACY,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Precisión {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif acc3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
        attacker.pbIncreaseStat(PBStats::ACCURACY,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Precisión {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif eva1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Evasión {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif eva2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,2,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Evasión {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif eva3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,3,false,nil,nil,true,false,false)
        @battle.pbDisplayBrief(_INTL("¡La Evasión {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif stat1.include?(move)
      @battle.pbCommonAnimation("StatUp",attacker,nil)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::SPATK,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPEED,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó sus estadísticas!",attacker.pbThis))
    elsif stat2.include?(move)
      @battle.pbCommonAnimation("StatUp",attacker,nil)
      attacker.pbIncreaseStat(PBStats::ATTACK,2,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,2,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::SPATK,2,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,2,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPEED,2,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó mucho sus estadísticas!",attacker.pbThis))
    elsif stat3.include?(move)
      @battle.pbCommonAnimation("StatUp",attacker,nil)
      attacker.pbIncreaseStat(PBStats::ATTACK,3,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,3,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::SPATK,3,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,3,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPEED,3,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó drásticamente sus estadísticas!",attacker.pbThis))
    elsif crit1.include?(move)
      @battle.pbAnimation(getConst(PBMoves,:FOCUSENERGY),attacker,nil)
      if attacker.effects[PBEffects::FocusEnergy]<3
        attacker.effects[PBEffects::FocusEnergy]+=1
        @battle.pbDisplayBrief(_INTL("¡{1} ve aumentada su probabilidad de asestar golpes críticos gracias al Poder Z!",attacker.pbThis))
      end
    elsif reset.include?(move)
      for i in [PBStats::ATTACK,PBStats::DEFENSE,
                PBStats::SPEED,PBStats::SPATK,PBStats::SPDEF,
                PBStats::EVASION,PBStats::ACCURACY]
        attacker.stages[i]=0 if attacker.stages[i]<0
      end
      @battle.pbAnimation(getConst(PBMoves,:HAZE),attacker,nil)
      @battle.pbDisplayBrief(_INTL("¡Las características de {1} que habían disminuido han vuelto a sus valores originales gracias al Poder Z!",attacker.pbThis))
    elsif heal.include?(move)
      @battle.pbAnimation(getConst(PBMoves,:RECOVER),attacker,nil)
      attacker.pbRecoverHP(attacker.totalhp,false)
      @battle.pbDisplayBrief(_INTL("¡{1} ha recobrado la salud gracias al Poder Z!",attacker.pbThis))
    elsif heal2.include?(move)
      @battle.pbAnimation(getConst(PBMoves,:RECOVER),attacker,nil)
      attacker.effects[PBEffects::ZHeal]=true
    elsif centre.include?(move)
      @battle.pbAnimation(getConst(PBMoves,:FOLLOWME),attacker,nil)
      attacker.effects[PBEffects::FollowMe]=true
      if !attacker.pbPartner.isFainted?
        attacker.pbPartner.effects[PBEffects::FollowMe]=false
        attacker.pbPartner.effects[PBEffects::RagePowder]=false
        @battle.pbDisplayBrief(_INTL("¡{1} se ha convertido en el centro de atención debido al Poder Z!!",attacker.pbThis))
      end
    else
      @battle.pbCommonAnimation("StatUp",attacker,nil)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::SPATK,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPEED,1,false,nil,nil,false,false,false) if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó sus estadísticas!",attacker.pbThis))
    end
  end

end
################################################################################
# Z - MOVES ITEMS
################################################################################
def pbIsZCrystal?(item)
  return $ItemData[item] && ($ItemData[item][ITEMTYPE]==7 || $ItemData[item][ITEMTYPE]==8)
end

class PokeBattle_Battler
  def pbZCrystalFromType(type)
    case type
    when 0  ;crystal = getID(PBItems,:NORMALIUMZ)
    when 1  ;crystal = getID(PBItems,:FIGHTINIUMZ)
    when 2  ;crystal = getID(PBItems,:FLYINIUMZ)
    when 3  ;crystal = getID(PBItems,:POISONIUMZ)
    when 4  ;crystal = getID(PBItems,:GROUNDIUMZ)
    when 5  ;crystal = getID(PBItems,:ROCKIUMZ)
    when 6  ;crystal = getID(PBItems,:BUGINIUMZ)
    when 7  ;crystal = getID(PBItems,:GHOSTIUMZ)
    when 8  ;crystal = getID(PBItems,:STEELIUMZ)
    when 10 ;crystal = getID(PBItems,:FIRIUMZ)
    when 11 ;crystal = getID(PBItems,:WATERIUMZ)
    when 12 ;crystal = getID(PBItems,:GRASSIUMZ)
    when 13 ;crystal = getID(PBItems,:ELECTRIUMZ)
    when 14 ;crystal = getID(PBItems,:PSYCHIUMZ)
    when 15 ;crystal = getID(PBItems,:ICIUMZ)
    when 16 ;crystal = getID(PBItems,:DRAGONIUMZ)
    when 17 ;crystal = getID(PBItems,:DARKINIUMZ)
    when 18 ;crystal = getID(PBItems,:FAIRIUMZ)
    end
    return crystal
  end

  def hasZMove?
    canuse=false
    pkmn=self
    case pkmn.item
    when getID(PBItems,:NORMALIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==0
      end
    when getID(PBItems,:FIGHTINIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==1
      end
    when getID(PBItems,:FLYINIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==2
      end
    when getID(PBItems,:POISONIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==3
      end
    when getID(PBItems,:GROUNDIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==4
      end
    when getID(PBItems,:ROCKIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==5
      end
    when getID(PBItems,:BUGINIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==6
      end
    when getID(PBItems,:GHOSTIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==7
      end
    when getID(PBItems,:STEELIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==8
      end
    when getID(PBItems,:FIRIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==10
      end
    when getID(PBItems,:WATERIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==11
      end
    when getID(PBItems,:GRASSIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==12
      end
    when getID(PBItems,:ELECTRIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==13
      end
    when getID(PBItems,:PSYCHIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==14
      end
    when getID(PBItems,:ICIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==15
      end
    when getID(PBItems,:DRAGONIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==16
      end
    when getID(PBItems,:DARKINIUMZ)
      for move in pkmn.moves
        if move.type==17
          canuse=true
        end
      end
    when getID(PBItems,:FAIRIUMZ)
      for move in pkmn.moves
        canuse=true if move.type==18
      end
    when getID(PBItems,:ALORAICHIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:THUNDERBOLT)
      end
      canuse=false if pkmn.species!=26 || pkmn.form!=1
    when getID(PBItems,:DECIDIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SPIRITSHACKLE)
      end
      canuse=false if pkmn.species!=724
    when getID(PBItems,:INCINIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:DARKESTLARIAT)
      end
      canuse=false if pkmn.species!=727
    when getID(PBItems,:PRIMARIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SPARKLINGARIA)
      end
      canuse=false if pkmn.species!=730
    when getID(PBItems,:EEVIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:LASTRESORT)
      end
      canuse=false if pkmn.species!=133
    when getID(PBItems,:PIKANIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:VOLTTACKLE)
      end
      canuse=false if pkmn.species!=25
    when getID(PBItems,:SNORLIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:GIGAIMPACT)
      end
      canuse=false if pkmn.species!=143
    when getID(PBItems,:MEWNIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:PSYCHIC)
      end
      canuse=false if pkmn.species!=151
    when getID(PBItems,:TAPUNIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:NATURESMADNESS)
      end
      if !(pokemon.species==785 ||
           pokemon.species==786 ||
           pokemon.species==787 ||
           pokemon.species==788)
        canuse=false
      end
    when getID(PBItems,:MARSHADIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SPECTRALTHIEF)
      end
      canuse=false if pkmn.species!=802
    when getID(PBItems,:PIKASHUNIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:THUNDERBOLT)
      end
      canuse=false if pkmn.species!=25
    when getID(PBItems,:ULTRANECROZIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:PHOTONGEYSER)
      end
      canuse=false if pkmn.species!=800 || pkmn.form!=3
    when getID(PBItems,:LYCANIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:STONEEDGE)
      end
      canuse=false if pkmn.species!=745
    when getID(PBItems,:MIMIKIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:PLAYROUGH)
      end
      canuse=false if pkmn.species!=778
    when getID(PBItems,:KOMMONIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:CLANGINGSCALES)
      end
      canuse=false if pkmn.species!=784
    when getID(PBItems,:SOLGANIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SUNSTEELSTRIKE)
      end
    when getID(PBItems,:LUNALIUMZ)
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:MOONGEISTBEAM)
      end
    # AÑADE NUEVOS Z MOVES AQUÍ

    end



    return canuse
  end

  def pbCompatibleZMoveFromMove?(move)
    pkmn=self
    case pkmn.item
    when getID(PBItems,:NORMALIUMZ)
      return true if move.type==0
    when getID(PBItems,:FIGHTINIUMZ)
      return true if move.type==1
    when getID(PBItems,:FLYINIUMZ)
      return true if move.type==2
    when getID(PBItems,:POISONIUMZ)
      return true if move.type==3
    when getID(PBItems,:GROUNDIUMZ)
      return true if move.type==4
    when getID(PBItems,:ROCKIUMZ)
      return true if move.type==5
    when getID(PBItems,:BUGINIUMZ)
      return true if move.type==6
    when getID(PBItems,:GHOSTIUMZ)
      return true if move.type==7
    when getID(PBItems,:STEELIUMZ)
      return true if move.type==8
    when getID(PBItems,:FIRIUMZ)
      return true if move.type==10
    when getID(PBItems,:WATERIUMZ)
      return true if move.type==11
    when getID(PBItems,:GRASSIUMZ)
      return true if move.type==12
    when getID(PBItems,:ELECTRIUMZ)
      return true if move.type==13
    when getID(PBItems,:PSYCHIUMZ)
      return true if move.type==14
    when getID(PBItems,:ICIUMZ)
      return true if move.type==15
    when getID(PBItems,:DRAGONIUMZ)
      return true if move.type==16
    when getID(PBItems,:DARKINIUMZ)
      return true if move.type==17
    when getID(PBItems,:FAIRIUMZ)
      return true if move.type==18
    when getID(PBItems,:ALORAICHIUMZ)
      return true if move.id==getID(PBMoves,:THUNDERBOLT)
    when getID(PBItems,:DECIDIUMZ)
      return true if move.id==getID(PBMoves,:SPIRITSHACKLE)
    when getID(PBItems,:INCINIUMZ)
      return true if move.id==getID(PBMoves,:DARKESTLARIAT)
    when getID(PBItems,:PRIMARIUMZ)
      return true if move.id==getID(PBMoves,:SPARKLINGARIA)
    when getID(PBItems,:EEVIUMZ)
      return true if move.id==getID(PBMoves,:LASTRESORT)
    when getID(PBItems,:PIKANIUMZ)
      return true if move.id==getID(PBMoves,:VOLTTACKLE)
    when getID(PBItems,:SNORLIUMZ)
      return true if move.id==getID(PBMoves,:GIGAIMPACT)
    when getID(PBItems,:MEWNIUMZ)
      return true if move.id==getID(PBMoves,:PSYCHIC)
    when getID(PBItems,:TAPUNIUMZ)
      return true if move.id==getID(PBMoves,:NATURESMADNESS)
    when getID(PBItems,:MARSHADIUMZ)
      return true if move.id==getID(PBMoves,:SPECTRALTHIEF)
    when getID(PBItems,:PIKASHUNIUMZ)
      return true if move.id==getID(PBMoves,:THUNDERBOLT)
    when getID(PBItems,:ULTRANECROZIUMZ)
      return true if move.id==getID(PBMoves,:PHOTONGEYSER)
    when getID(PBItems,:LYCANIUMZ)
      return true if move.id==getID(PBMoves,:STONEEDGE)
    when getID(PBItems,:MIMIKIUMZ)
      return true if move.id==getID(PBMoves,:PLAYROUGH)
    when getID(PBItems,:KOMMONIUMZ)
      return true if move.id==getID(PBMoves,:CLANGINGSCALES)
    when getID(PBItems,:SOLGANIUMZ)
      return true if move.id==getID(PBMoves,:SUNSTEELSTRIKE)
    when getID(PBItems,:LUNALIUMZ)
      return true if move.id==getID(PBMoves,:MOONGEISTBEAM)
    end
    return false
  end

  def pbCompatibleZMoveFromIndex?(moveindex)
    pkmn=self
    case pkmn.item
    when getID(PBItems,:NORMALIUMZ)
      return true if pkmn.moves[moveindex].type==0
    when getID(PBItems,:FIGHTINIUMZ)
      return true if pkmn.moves[moveindex].type==1
    when getID(PBItems,:FLYINIUMZ)
      return true if pkmn.moves[moveindex].type==2
    when getID(PBItems,:POISONIUMZ)
      return true if pkmn.moves[moveindex].type==3
    when getID(PBItems,:GROUNDIUMZ)
      return true if pkmn.moves[moveindex].type==4
    when getID(PBItems,:ROCKIUMZ)
      return true if pkmn.moves[moveindex].type==5
    when getID(PBItems,:BUGINIUMZ)
      return true if pkmn.moves[moveindex].type==6
    when getID(PBItems,:GHOSTIUMZ)
      return true if pkmn.moves[moveindex].type==7
    when getID(PBItems,:STEELIUMZ)
      return true if pkmn.moves[moveindex].type==8
    when getID(PBItems,:FIRIUMZ)
      return true if pkmn.moves[moveindex].type==10
    when getID(PBItems,:WATERIUMZ)
      return true if pkmn.moves[moveindex].type==11
    when getID(PBItems,:GRASSIUMZ)
      return true if pkmn.moves[moveindex].type==12
    when getID(PBItems,:ELECTRIUMZ)
      return true if pkmn.moves[moveindex].type==13
    when getID(PBItems,:PSYCHIUMZ)
      return true if pkmn.moves[moveindex].type==14
    when getID(PBItems,:ICIUMZ)
      return true if pkmn.moves[moveindex].type==15
    when getID(PBItems,:DRAGONIUMZ)
      return true if pkmn.moves[moveindex].type==16
    when getID(PBItems,:DARKINIUMZ)
      return true if pkmn.moves[moveindex].type==17
    when getID(PBItems,:FAIRIUMZ)
       return true if pkmn.moves[moveindex].type==18
    when getID(PBItems,:ALORAICHIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:THUNDERBOLT)
    when getID(PBItems,:DECIDIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:SPIRITSHACKLE)
    when getID(PBItems,:INCINIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:DARKESTLARIAT)
    when getID(PBItems,:PRIMARIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:SPARKLINGARIA)
    when getID(PBItems,:EEVIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:LASTRESORT)
    when getID(PBItems,:PIKANIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:VOLTTACKLE)
    when getID(PBItems,:SNORLIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:GIGAIMPACT)
    when getID(PBItems,:MEWNIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:PSYCHIC)
    when getID(PBItems,:TAPUNIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:NATURESMADNESS)
    when getID(PBItems,:MARSHADIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:SPECTRALTHIEF)
    when getID(PBItems,:PIKASHUNIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:THUNDERBOLT)
    when getID(PBItems,:ULTRANECROZIUMZ)
       return true if pkmn.moves[moveindex].id==getID(PBMoves,:PHOTONGEYSER)
    when getID(PBItems,:LYCANIUMZ)
      return true if pkmn.moves[moveindex].id==getID(PBMoves,:STONEEDGE)
    when getID(PBItems,:MIMIKIUMZ)
      return true if pkmn.moves[moveindex].id==getID(PBMoves,:PLAYROUGH)
    when getID(PBItems,:KOMMONIUMZ)
      return true if pkmn.moves[moveindex].id==getID(PBMoves,:CLANGINGSCALES)
    when getID(PBItems,:SOLGANIUMZ)
      return true if pkmn.moves[moveindex].id==getID(PBMoves,:SUNSTEELSTRIKE)
    when getID(PBItems,:LUNALIUMZ)
      return true if pkmn.moves[moveindex].id==getID(PBMoves,:MOONGEISTBEAM)
    end

    return false
  end
end
