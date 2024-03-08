class PokeBattle_ZMoves
  attr_accessor(:id)
  attr_reader(:battle)
  attr_reader(:name)
  attr_reader(:function)
  attr_accessor(:basedamage)
  attr_reader(:type)
  attr_reader(:accuracy)
  attr_reader(:addlEffect)
  attr_reader(:target)   
  #attr_reader(:priority) #Priority already handled
  attr_reader(:flags)
  attr_reader(:category)  
  attr_reader(:thismove)
  attr_reader(:oldmove)
  attr_reader(:status)
  attr_reader(:oldname)
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
    @addlEffect = 0 #pbZMoveAddlEffectChance(move,crystal)
    @target     = move.target
    #@priority   = movedata.priority
    @flags      = pbZMoveFlags(move,crystal)
    @category   = oldmovedata.category
    @thismove   = self #move  
    battler.pbBeginTurn(self)
    if !@status
      @battle.pbDisplayBrief(_INTL("¡{1} liberó todo el poder de su movimiento Z!",battler.pbThis))
      @battle.pbDisplayBrief(_INTL("¡{1}!",@nameEspanol))
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
        zchoice[2].name = @name
        battler.pbUseMove(zchoice)
        @oldmove.name = @oldname
      end      
    else
      if @status
        #targeted status Z's here
        pbZStatus(@id,battler)
        zchoice[2].name = @name
        battler.pbUseMove(zchoice)
        @oldmove.name = @oldname
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
      return "Z-" + oldmove.name
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
  
  def pbEffectFixedDamage(damage,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    type=@type
    typemod=pbTypeModMessages(type,attacker,opponent)
    opponent.damagestate.critical=false
    opponent.damagestate.typemod=0
    opponent.damagestate.calcdamage=0
    opponent.damagestate.hplost=0
    if typemod!=0
      opponent.damagestate.calcdamage=damage
      opponent.damagestate.typemod=4
      pbShowAnimation(@name,attacker,opponent,hitnum,alltargets,showanimation)
      damage=1 if damage<1 # HP reduced can't be less than 1
      damage=pbModifyDamage(damage,attacker,opponent)
      damage=pbReduceHPDamage(damage,attacker,opponent)
      pbEffectMessages(attacker,opponent)
      pbOnDamageLost(damage,attacker,opponent)
      return damage
    end
    return 0
  end  

  def pbOnDamageLost(damage,attacker,opponent)
    #Used by Counter/Mirror Coat/Revenge/Focus Punch/Bide
    type=@type  
    if opponent.effects[PBEffects::Bide]>0
      opponent.effects[PBEffects::BideDamage]+=damage
      opponent.effects[PBEffects::BideTarget]=attacker.index
    end            
    if @oldmove.pbIsPhysical?(type)
      opponent.effects[PBEffects::Counter]=damage
      opponent.effects[PBEffects::CounterTarget]=attacker.index
    end
    if @oldmove.pbIsSpecial?(type)
      opponent.effects[PBEffects::MirrorCoat]=damage
      opponent.effects[PBEffects::MirrorCoatTarget]=attacker.index
    end
    opponent.lastHPLost=damage # for Revenge/Focus Punch/Metal Burst
    opponent.tookDamage=true if damage>0 # for Assurance
    opponent.lastAttacker.push(attacker.index) # for Revenge/Metal Burst
  end 
  
  def pbEffectMessages(attacker,opponent,ignoretype=false)
    if opponent.damagestate.critical
      @battle.pbDisplay(_INTL("¡Es un golpe crítico!"))
    end
    if opponent.damagestate.typemod>8
      @battle.pbDisplay(_INTL("¡Es super efectivo!"))
    elsif opponent.damagestate.typemod>=1 && opponent.damagestate.typemod<8
      @battle.pbDisplay(_INTL("No es muy efectivo..."))
    end
    if opponent.damagestate.endured
      @battle.pbDisplay(_INTL("¡{1} aguantó el golpe!",opponent.pbThis))
    elsif opponent.damagestate.sturdy
      @battle.pbDisplay(_INTL("¡{1} resistió con Robustez!",opponent.pbThis))
      opponent.damagestate.sturdy=false
    elsif opponent.damagestate.focussash
      @battle.pbDisplay(_INTL("¡{1} resistió usando Banda Focus!",opponent.pbThis))
    elsif opponent.damagestate.focusband
      @battle.pbDisplay(_INTL("¡{1} resistió usando Cinta Focus!",opponent.pbThis))
    end
  end  
  
  def pbReduceHPDamage(damage,attacker,opponent)
    endure=false
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker) &&
       (!attacker || attacker.index!=opponent.index)
      PBDebug.log("[Lingering effect triggered] #{opponent.pbThis}'s Substitute took the damage")
      damage=opponent.effects[PBEffects::Substitute] if damage>opponent.effects[PBEffects::Substitute]
      opponent.effects[PBEffects::Substitute]-=damage
      opponent.damagestate.substitute=true
      @battle.scene.pbDamageAnimation(opponent,0)
      @battle.pbDisplayPaused(_INTL("¡El sustituto recibe el daño en lugar de {1}!",opponent.name))
      if opponent.effects[PBEffects::Substitute]<=0
        opponent.effects[PBEffects::Substitute]=0
        @battle.pbDisplayPaused(_INTL("¡El sustituto de {1} se acabó!",opponent.name))
        PBDebug.log("[End of effect] #{opponent.pbThis}'s Substitute faded")
      end
      opponent.damagestate.hplost=damage
      damage=0
    else
      opponent.damagestate.substitute=false
      if damage>=opponent.hp
        damage=opponent.hp
        if @function==0xE9 # False Swipe
          damage=damage-1
        elsif opponent.effects[PBEffects::Endure]
          damage=damage-1
          opponent.damagestate.endured=true
          PBDebug.log("[Lingering effect triggered] #{opponent.pbThis}'s Endure")
        elsif damage==opponent.totalhp
          if opponent.hasWorkingAbility(:STURDY) && !attacker.hasMoldBreaker
            opponent.damagestate.sturdy=true
            damage=damage-1
            PBDebug.log("[Ability triggered] #{opponent.pbThis}'s Sturdy")
          elsif opponent.hasWorkingItem(:FOCUSSASH) && opponent.hp==opponent.totalhp
            opponent.damagestate.focussash=true
            damage=damage-1
            PBDebug.log("[Item triggered] #{opponent.pbThis}'s Focus Sash")
          elsif opponent.hasWorkingItem(:FOCUSBAND) && @battle.pbRandom(10)==0
            opponent.damagestate.focusband=true
            damage=damage-1
            PBDebug.log("[Item triggered] #{opponent.pbThis}'s Focus Band")
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
  
  def pbType(type,attacker,opponent)
    return @type
  end  

  def isContactMove?    
    return @flags.include?("a")
  end
  
  def pbCanUseWhileAsleep?
    return false
  end  
  
  def isDanceMove?    
    return false
  end  
  
  def pbTypeModifier(type,attacker,opponent)
    return 8 if type<0
    return 8 if isConst?(type,PBTypes,:GROUND) && opponent.pbHasType?(:FLYING) &&
                opponent.hasWorkingItem(:IRONBALL) && !USENEWBATTLEMECHANICS
    atype=type # attack type
    otype1=opponent.type1
    otype2=opponent.type2
    otype3=opponent.effects[PBEffects::Type3] || -1
    # Roost
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
    # Foresight
    if attacker.hasWorkingAbility(:SCRAPPY) || opponent.effects[PBEffects::Foresight]
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
    if (!opponent.isAirborne?(attacker.hasMoldBreaker) || @function==0x11C) && # Smack Down
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
    return mod1*mod2*mod3
  end
  
  def pbCalcDamage(attacker,opponent,options=0)
    opponent.damagestate.critical=false
    opponent.damagestate.typemod=0
    opponent.damagestate.calcdamage=0
    opponent.damagestate.hplost=0
    return 0 if @basedamage==0
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]    
    type=pbType(@type,attacker,opponent)
    opponent.damagestate.critical=pbIsCritical?(attacker,opponent)
    ##### Calcuate base power of move #####
    basedmg=@basedamage # Fron PBS file
    #basedmg=pbBaseDamage(basedmg,attacker,opponent) # Some function codes alter base power
    damagemult=0x1000
    if attacker.hasWorkingAbility(:TECHNICIAN) && basedmg<=60 && @id>0
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:IRONFIST) && isPunchingMove?
      damagemult=(damagemult*1.2).round
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
    if attacker.hasWorkingAbility(:FLAREBOOST) &&
       attacker.status==PBStatuses::BURN && pbIsSpecial?(type)
      damagemult=(damagemult*1.5).round
    end
    if attacker.hasWorkingAbility(:TOXICBOOST) &&
       attacker.status==PBStatuses::POISON && pbIsPhysical?(type)
      damagemult=(damagemult*1.5).round
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
      damagemult=(damagemult*4/3).round
    end
#    if (attacker.hasWorkingAbility(:AERILATE) ||
#       attacker.hasWorkingAbility(:REFRIGERATE) ||
#       attacker.hasWorkingAbility(:PIXILATE)) && @powerboost
#      damagemult=(damagemult*1.3).round
#    end
    if (@battle.pbCheckGlobalAbility(:DARKAURA) && isConst?(type,PBTypes,:DARK)) ||
       (@battle.pbCheckGlobalAbility(:FAIRYAURA) && isConst?(type,PBTypes,:FAIRY))
      if @battle.pbCheckGlobalAbility(:AURABREAK)
        damagemult=(damagemult*2/3).round
      else
        damagemult=(damagemult*4/3).round
      end
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:HEATPROOF) && isConst?(type,PBTypes,:FIRE)
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:THICKFAT) &&
         (isConst?(type,PBTypes,:ICE) || isConst?(type,PBTypes,:FIRE))
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:FURCOAT) &&
         (pbIsPhysical?(type) || @function==0x122) # Psyshock
        damagemult=(damagemult*0.5).round
      end
      if opponent.hasWorkingAbility(:DRYSKIN) && isConst?(type,PBTypes,:FIRE)
        damagemult=(damagemult*1.25).round
      end
    end
    # Gems are the first items to be considered, as Symbiosis can replace a
    # consumed Gem and the replacement item should work immediately.
#    if @function!=0x106 && @function!=0x107 && @function!=0x108 # Pledge moves
#      if (attacker.hasWorkingItem(:NORMALGEM) && isConst?(type,PBTypes,:NORMAL)) ||
#         (attacker.hasWorkingItem(:FIGHTINGGEM) && isConst?(type,PBTypes,:FIGHTING)) ||
#         (attacker.hasWorkingItem(:FLYINGGEM) && isConst?(type,PBTypes,:FLYING)) ||
#         (attacker.hasWorkingItem(:POISONGEM) && isConst?(type,PBTypes,:POISON)) ||
#         (attacker.hasWorkingItem(:GROUNDGEM) && isConst?(type,PBTypes,:GROUND)) ||
#         (attacker.hasWorkingItem(:ROCKGEM) && isConst?(type,PBTypes,:ROCK)) ||
#         (attacker.hasWorkingItem(:BUGGEM) && isConst?(type,PBTypes,:BUG)) ||
#         (attacker.hasWorkingItem(:GHOSTGEM) && isConst?(type,PBTypes,:GHOST)) ||
#         (attacker.hasWorkingItem(:STEELGEM) && isConst?(type,PBTypes,:STEEL)) ||
#         (attacker.hasWorkingItem(:FIREGEM) && isConst?(type,PBTypes,:FIRE)) ||
#         (attacker.hasWorkingItem(:WATERGEM) && isConst?(type,PBTypes,:WATER)) ||
#         (attacker.hasWorkingItem(:GRASSGEM) && isConst?(type,PBTypes,:GRASS)) ||
#         (attacker.hasWorkingItem(:ELECTRICGEM) && isConst?(type,PBTypes,:ELECTRIC)) ||
#         (attacker.hasWorkingItem(:PSYCHICGEM) && isConst?(type,PBTypes,:PSYCHIC)) ||
#         (attacker.hasWorkingItem(:ICEGEM) && isConst?(type,PBTypes,:ICE)) ||
#         (attacker.hasWorkingItem(:DRAGONGEM) && isConst?(type,PBTypes,:DRAGON)) ||
#         (attacker.hasWorkingItem(:DARKGEM) && isConst?(type,PBTypes,:DARK)) ||
#         (attacker.hasWorkingItem(:FAIRYGEM) && isConst?(type,PBTypes,:FAIRY))
#        damagemult=(USENEWBATTLEMECHANICS) ? (damagemult*1.3).round : (damagemult*1.5).round
#        @battle.pbCommonAnimation("UseItem",attacker,nil)
#        @battle.pbDisplayBrief(_INTL("The {1} strengthened {2}'s power!",
#           PBItems.getName(attacker.item),@name))
#        attacker.pbConsumeItem
#      end
#    end
#    if (attacker.hasWorkingItem(:SILKSCARF) && isConst?(type,PBTypes,:NORMAL)) ||
#       (attacker.hasWorkingItem(:BLACKBELT) && isConst?(type,PBTypes,:FIGHTING)) ||
#       (attacker.hasWorkingItem(:SHARPBEAK) && isConst?(type,PBTypes,:FLYING)) ||
#       (attacker.hasWorkingItem(:POISONBARB) && isConst?(type,PBTypes,:POISON)) ||
#       (attacker.hasWorkingItem(:SOFTSAND) && isConst?(type,PBTypes,:GROUND)) ||
#       (attacker.hasWorkingItem(:HARDSTONE) && isConst?(type,PBTypes,:ROCK)) ||
#       (attacker.hasWorkingItem(:SILVERPOWDER) && isConst?(type,PBTypes,:BUG)) ||
#       (attacker.hasWorkingItem(:SPELLTAG) && isConst?(type,PBTypes,:GHOST)) ||
#       (attacker.hasWorkingItem(:METALCOAT) && isConst?(type,PBTypes,:STEEL)) ||
#       (attacker.hasWorkingItem(:CHARCOAL) && isConst?(type,PBTypes,:FIRE)) ||
#       (attacker.hasWorkingItem(:MYSTICWATER) && isConst?(type,PBTypes,:WATER)) ||
#       (attacker.hasWorkingItem(:MIRACLESEED) && isConst?(type,PBTypes,:GRASS)) ||
#       (attacker.hasWorkingItem(:MAGNET) && isConst?(type,PBTypes,:ELECTRIC)) ||
#       (attacker.hasWorkingItem(:TWISTEDSPOON) && isConst?(type,PBTypes,:PSYCHIC)) ||
#       (attacker.hasWorkingItem(:NEVERMELTICE) && isConst?(type,PBTypes,:ICE)) ||
#       (attacker.hasWorkingItem(:DRAGONFANG) && isConst?(type,PBTypes,:DRAGON)) ||
#       (attacker.hasWorkingItem(:BLACKGLASSES) && isConst?(type,PBTypes,:DARK))
#      damagemult=(damagemult*1.2).round
#    end
#    if (attacker.hasWorkingItem(:FISTPLATE) && isConst?(type,PBTypes,:FIGHTING)) ||
#       (attacker.hasWorkingItem(:SKYPLATE) && isConst?(type,PBTypes,:FLYING)) ||
#       (attacker.hasWorkingItem(:TOXICPLATE) && isConst?(type,PBTypes,:POISON)) ||
#       (attacker.hasWorkingItem(:EARTHPLATE) && isConst?(type,PBTypes,:GROUND)) ||
#       (attacker.hasWorkingItem(:STONEPLATE) && isConst?(type,PBTypes,:ROCK)) ||
#       (attacker.hasWorkingItem(:INSECTPLATE) && isConst?(type,PBTypes,:BUG)) ||
#       (attacker.hasWorkingItem(:SPOOKYPLATE) && isConst?(type,PBTypes,:GHOST)) ||
#       (attacker.hasWorkingItem(:IRONPLATE) && isConst?(type,PBTypes,:STEEL)) ||
#       (attacker.hasWorkingItem(:FLAMEPLATE) && isConst?(type,PBTypes,:FIRE)) ||
#       (attacker.hasWorkingItem(:SPLASHPLATE) && isConst?(type,PBTypes,:WATER)) ||
#       (attacker.hasWorkingItem(:MEADOWPLATE) && isConst?(type,PBTypes,:GRASS)) ||
#       (attacker.hasWorkingItem(:ZAPPLATE) && isConst?(type,PBTypes,:ELECTRIC)) ||
#       (attacker.hasWorkingItem(:MINDPLATE) && isConst?(type,PBTypes,:PSYCHIC)) ||
#       (attacker.hasWorkingItem(:ICICLEPLATE) && isConst?(type,PBTypes,:ICE)) ||
#       (attacker.hasWorkingItem(:DRACOPLATE) && isConst?(type,PBTypes,:DRAGON)) ||
#       (attacker.hasWorkingItem(:DREADPLATE) && isConst?(type,PBTypes,:DARK)) ||
#       (attacker.hasWorkingItem(:PIXIEPLATE) && isConst?(type,PBTypes,:FAIRY))
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:ROCKINCENSE) && isConst?(type,PBTypes,:ROCK)
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:ROSEINCENSE) && isConst?(type,PBTypes,:GRASS)
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:SEAINCENSE) && isConst?(type,PBTypes,:WATER)
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:WAVEINCENSE) && isConst?(type,PBTypes,:WATER)
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:ODDINCENSE) && isConst?(type,PBTypes,:PSYCHIC)
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:MUSCLEBAND) && pbIsPhysical?(type)
#      damagemult=(damagemult*1.1).round
#    end
#    if attacker.hasWorkingItem(:WISEGLASSES) && pbIsSpecial?(type)
#      damagemult=(damagemult*1.1).round
#    end
#    if attacker.hasWorkingItem(:LUSTROUSORB) &&
#       isConst?(attacker.species,PBSpecies,:PALKIA) &&
#       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:WATER))
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:ADAMANTORB) &&
#       isConst?(attacker.species,PBSpecies,:DIALGA) &&
#       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:STEEL))
#      damagemult=(damagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:GRISEOUSORB) &&
#       isConst?(attacker.species,PBSpecies,:GIRATINA) &&
#       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:GHOST))
#      damagemult=(damagemult*1.2).round
#    end
#    damagemult=pbBaseDamageMultiplier(damagemult,attacker,opponent)
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
       !attacker.isAirborne? && isConst?(type,PBTypes,:ELECTRIC)
      damagemult=(damagemult*1.5).round
    end
    if @battle.field.effects[PBEffects::GrassyTerrain]>0 &&
       !attacker.isAirborne? && isConst?(type,PBTypes,:GRASS)
      damagemult=(damagemult*1.5).round
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0 &&
       !opponent.isAirborne?(attacker.hasMoldBreaker) && isConst?(type,PBTypes,:DRAGON)
      damagemult=(damagemult*0.5).round
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
    if attacker.hasMoldBreaker || !opponent.hasWorkingAbility(:UNAWARE)
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
    if attacker.hasWorkingAbility(:DEFEATIST) &&
       attacker.hp<=(attacker.totalhp/2).floor
      atkmult=(atkmult*0.5).round
    end
    if (attacker.hasWorkingAbility(:PUREPOWER) ||
       attacker.hasWorkingAbility(:HUGEPOWER)) && pbIsPhysical?(type)
      atkmult=(atkmult*2.0).round
    end
    if attacker.hasWorkingAbility(:SOLARPOWER) && pbIsSpecial?(type) &&
       (@battle.pbWeather==PBWeather::SUNNYDAY ||
       @battle.pbWeather==PBWeather::HARSHSUN)
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
      if attacker.hasWorkingAbility(:FLOWERGIFT) ||
         attacker.pbPartner.hasWorkingAbility(:FLOWERGIFT)
        atkmult=(atkmult*1.5).round
      end
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
    if type>=0 && pbIsSpecial?(type) && @function!=0x122 # Psyshock
      defense=opponent.spdef
      defstage=opponent.stages[PBStats::SPDEF]+6
      applysandstorm=true
    end
    if !attacker.hasWorkingAbility(:UNAWARE)
      defstage=6 if @function==0xA9 # Chip Away (ignore stat stages)
      defstage=6 if opponent.damagestate.critical && defstage>6
      defense=(defense*1.0*stagemul[defstage]/stagediv[defstage]).floor
    end
    if @battle.pbWeather==PBWeather::SANDSTORM &&
       opponent.pbHasType?(:ROCK) && applysandstorm
      defense=(defense*1.5).round
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
    if @battle.field.effects[PBEffects::GrassyTerrain]>0
      defmult=(defmult*1.5).round
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:MARVELSCALE) &&
         opponent.status>0 && pbIsPhysical?(type)
        defmult=(defmult*1.5).round
      end
      if (@battle.pbWeather==PBWeather::SUNNYDAY ||
         @battle.pbWeather==PBWeather::HARSHSUN) && pbIsSpecial?(type)
        if opponent.hasWorkingAbility(:FLOWERGIFT) ||
           opponent.pbPartner.hasWorkingAbility(:FLOWERGIFT)
          defmult=(defmult*1.5).round
        end
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
      if isConst?(type,PBTypes,:FIRE)
        damage=(damage*1.5).round
      elsif isConst?(type,PBTypes,:WATER)
        damage=(damage*0.5).round
      end
    when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
      if isConst?(type,PBTypes,:FIRE)
        damage=(damage*0.5).round
      elsif isConst?(type,PBTypes,:WATER)
        damage=(damage*1.5).round
      end
    end
    # Critical hits
    if opponent.damagestate.critical
      damage=(USENEWBATTLEMECHANICS) ? (damage*1.5).round : (damage*2.0).round
      damage=(USENEWBATTLEMECHANICS) ? (damage*1.5).round : (damage*2.0).round
    end
    # Random variance
#    if (options&NOWEIGHTING)==0
      random=85+@battle.pbRandom(16)
      damage=(damage*random/100.0).floor
#    end
    # STAB
    if attacker.pbHasType?(type) #&& (options&IGNOREPKMNTYPES)==0
      if attacker.hasWorkingAbility(:ADAPTABILITY)
        damage=(damage*2).round
      else
        damage=(damage*1.5).round
      end
    end
    # Type effectiveness
#    if (options&IGNOREPKMNTYPES)==0
      typemod=pbTypeModMessages(type,attacker,opponent)
      damage=(damage*typemod/8.0).round
      opponent.damagestate.typemod=typemod
      if typemod==0
        opponent.damagestate.calcdamage=0
        opponent.damagestate.critical=false
        return 0
      end
#    else
#      opponent.damagestate.typemod=8
#    end
    # Burn
    if attacker.status==PBStatuses::BURN && pbIsPhysical?(type) &&
       !attacker.hasWorkingAbility(:GUTS) &&
       !(USENEWBATTLEMECHANICS && @function==0x7E) # Facade
      damage=(damage*0.5).round
    end
    # Make sure damage is at least 1
    damage=1 if damage<1
    # Final damage modifiers
    finaldamagemult=0x1000
    if !opponent.damagestate.critical #&& (options&NOREFLECT)==0 &&
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
    if !attacker.hasMoldBreaker
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
#    if attacker.hasWorkingItem(:METRONOME)
#      met=1+0.2*[attacker.effects[PBEffects::Metronome],5].min
#      finaldamagemult=(finaldamagemult*met).round
#    end
#    if attacker.hasWorkingItem(:EXPERTBELT) &&
#       opponent.damagestate.typemod>8
#      finaldamagemult=(finaldamagemult*1.2).round
#    end
#    if attacker.hasWorkingItem(:LIFEORB) && (options&SELFCONFUSE)==0
#      attacker.effects[PBEffects::LifeOrb]=true
#      finaldamagemult=(finaldamagemult*1.3).round
#    end
    if opponent.damagestate.typemod>8 #&& (options&IGNOREPKMNTYPES)==0
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
    if opponent.hasWorkingItem(:CHILANBERRY) && isConst?(type,PBTypes,:NORMAL) #&&
       #(options&IGNOREPKMNTYPES)==0
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
  
  
  
  def pbModifyDamage(damagemult,attacker,opponent)
    if !opponent.effects[PBEffects::ProtectNegation] && (opponent.pbOwnSide.effects[PBEffects::MatBlock] || 
      opponent.effects[PBEffects::Protect] || opponent.effects[PBEffects::SpikyShield])
      @battle.pbDisplay(_INTL("¡{1} no pudo protegerse completamente!",opponent.pbThis))
      return (damagemult/4).floor
    else      
      return damagemult
    end    
  end    
  
  def pbIsCritical?(attacker,opponent)
    if attacker.effects[PBEffects::LaserFocus]>0
      attacker.effects[PBEffects::LaserFocus]=0
      return true
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:BATTLEARMOR) ||
         opponent.hasWorkingAbility(:SHELLARMOR)
        return false
      end      
      return true if attacker.hasWorkingAbility(:MERCILESS) && opponent.status==PBStatuses::POISON      
      return true if attacker.effects[PBEffects::LaserFocus]>0
    end
    return false if opponent.pbOwnSide.effects[PBEffects::LuckyChant]>0
    c=0
    ratios=(USENEWBATTLEMECHANICS) ? [16,8,2,1,1] : [16,8,4,3,2]
    c+=attacker.effects[PBEffects::FocusEnergy]
    if (attacker.inHyperMode? rescue false) && isConst?(self.type,PBTypes,:SHADOW)
      c+=1
    end
    c+=1 if attacker.hasWorkingAbility(:SUPERLUCK)
    c=4 if c>4
    return @battle.pbRandom(ratios[c])==0
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
  
  def pbTargetsMultiple?(attacker)
    return false
  end  
  
  def pbTypeImmunityByAbility(type,attacker,opponent)
    return false if attacker.index==opponent.index
    return false if attacker.hasMoldBreaker
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
        attacker.pbIncreaseStat(PBStats::ATTACK,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡El Ataque de {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif atk2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡El Ataque de {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif atk3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡El Ataque de {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif def1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Defensa de {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif def2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Defensa de {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif def3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Defensa de {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif spatk1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡El Ataque Especial {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif spatk2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡El Ataque Especial {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif spatk3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡El Ataque Especial {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif spdef1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Defensa Especial {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif spdef2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Defensa Especial {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif spdef3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Defensa Especial {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif speed1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Velocidad {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif speed2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Velocidad {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif speed3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Velocidad {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif acc1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
        attacker.pbIncreaseStat(PBStats::ACCURACY,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Precisión {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif acc2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
        attacker.pbIncreaseStat(PBStats::ACCURACY,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Precisión {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif acc3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,false)
        attacker.pbIncreaseStat(PBStats::ACCURACY,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Precisión {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif eva1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,1,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Evasión {1} ha aumentado gracias al Poder Z!",attacker.pbThis))
      end
    elsif eva2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,2,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Evasión {1} ha aumentado mucho gracias al Poder Z!",attacker.pbThis))
      end
    elsif eva3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,false)
        attacker.pbIncreaseStat(PBStats::EVASION,3,false,nil,nil,false,false,false)         
        @battle.pbDisplayBrief(_INTL("¡La Evasión {1} ha aumentado drásticamente gracias al Poder Z!",attacker.pbThis))
      end
    elsif stat1.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,false,nil,nil,false,false,false)                 
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,false,nil,nil,false,false,false)                 
      end      
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó sus estadísticas!",attacker.pbThis))
    elsif stat2.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,2,false,nil,nil,false,false,false)                 
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,2,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,2,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,2,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,2,false,nil,nil,false,false,false)                 
      end      
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó mucho sus estadísticas!",attacker.pbThis))
    elsif stat3.include?(move)
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,3,false,nil,nil,false,false,false)                 
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,3,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,3,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,3,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,3,false,nil,nil,false,false,false)                 
      end      
      @battle.pbDisplayBrief(_INTL("¡El Poder Z de {1} aumentó drásticamente sus estadísticas!",attacker.pbThis))
    elsif crit1.include?(move)
      if attacker.effects[PBEffects::FocusEnergy]<3
        attacker.effects[PBEffects::FocusEnergy]+=1
        @battle.pbDisplayBrief(_INTL("¡{1} ve aumentada su probabilidad de asestar golpes críticos gracias al Poder Z!",attacker.pbThis))
      end      
    elsif reset.include?(move)
      for i in [PBStats::ATTACK,PBStats::DEFENSE,
                PBStats::SPEED,PBStats::SPATK,PBStats::SPDEF,
                PBStats::EVASION,PBStats::ACCURACY]
        if attacker.stages[i]<0
          attacker.stages[i]=0
        end
      end
      @battle.pbDisplayBrief(_INTL("¡Las características de {1} que habían disminuido han vuelto a sus valores originales gracias al Poder Z!",attacker.pbThis))
    elsif heal.include?(move)
      attacker.pbRecoverHP(attacker.totalhp,false)
      @battle.pbDisplayBrief(_INTL("¡{1} ha recobrado la salud gracias al Poder Z!",attacker.pbThis))
    elsif heal2.include?(move)
      attacker.effects[PBEffects::ZHeal]=true
    elsif centre.include?(move)
      attacker.effects[PBEffects::FollowMe]=true
      if !attacker.pbPartner.isFainted?
        attacker.pbPartner.effects[PBEffects::FollowMe]=false
        attacker.pbPartner.effects[PBEffects::RagePowder]=false  
        @battle.pbDisplayBrief(_INTL("¡{1} se ha convertido en el centro de atención debido al Poder Z!!",attacker.pbThis))
      end
    else
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,false,nil,nil,false,false,false)                 
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
        attacker.pbIncreaseStat(PBStats::SPATK,1,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,false,nil,nil,false,false,false)                 
      end      
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,false,nil,nil,false,false,false)                 
      end      
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
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==0
      end   
    when getID(PBItems,:FIGHTINIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==1
      end     
    when getID(PBItems,:FLYINIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==2
      end   
    when getID(PBItems,:POISONIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==3
      end           
    when getID(PBItems,:GROUNDIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==4
      end    
    when getID(PBItems,:ROCKIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==5
      end           
    when getID(PBItems,:BUGINIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==6
      end  
    when getID(PBItems,:GHOSTIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==7
      end           
    when getID(PBItems,:STEELIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==8
      end           
    when getID(PBItems,:FIRIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==10
      end       
    when getID(PBItems,:WATERIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==11
      end           
    when getID(PBItems,:GRASSIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==12
      end               
    when getID(PBItems,:ELECTRIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==13
      end          
    when getID(PBItems,:PSYCHIUMZ)
      canuse=false   
      for move in pkmn.moves        
        canuse=true if move.type==14
      end   
    when getID(PBItems,:ICIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==15
      end               
    when getID(PBItems,:DRAGONIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==16
      end               
    when getID(PBItems,:DARKINIUMZ)
      canuse=false   
      for move in pkmn.moves
        if move.type==17
          canuse=true
        end
      end           
    when getID(PBItems,:FAIRIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.type==18
      end                     
    when getID(PBItems,:ALORAICHIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:THUNDERBOLT)
      end
      canuse=false if pkmn.species!=26 || pkmn.form!=1
    when getID(PBItems,:DECIDIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SPIRITSHACKLE)
      end
      canuse=false if pkmn.species!=724        
    when getID(PBItems,:INCINIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:DARKESTLARIAT)
      end
      canuse=false if pkmn.species!=727         
    when getID(PBItems,:PRIMARIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SPARKLINGARIA)
      end
      canuse=false if pkmn.species!=730
    when getID(PBItems,:EEVIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:LASTRESORT)
      end
      canuse=false if pkmn.species!=133
    when getID(PBItems,:PIKANIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:VOLTTACKLE)
      end
      canuse=false if pkmn.species!=25
    when getID(PBItems,:SNORLIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:GIGAIMPACT)
      end
      canuse=false if pkmn.species!=143
    when getID(PBItems,:MEWNIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:PSYCHIC)
      end
      canuse=false if pkmn.species!=151
    when getID(PBItems,:TAPUNIUMZ)
      canuse=false   
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
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SPECTRALTHIEF)
      end
      canuse=false if pkmn.species!=802
    when getID(PBItems,:PIKASHUNIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:THUNDERBOLT)
      end
      canuse=false if pkmn.species!=25
    when getID(PBItems,:ULTRANECROZIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:PHOTONGEYSER)
      end
      canuse=false if pkmn.species!=800 #|| pkmn.form==3
    when getID(PBItems,:LYCANIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:STONEEDGE)
      end
      canuse=false if pkmn.species!=745
    when getID(PBItems,:MIMIKIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:PLAYROUGH)
      end
      canuse=false if pkmn.species!=778
    when getID(PBItems,:KOMMONIUMZ)
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:CLANGINGSCALES)
      end
      canuse=false if pkmn.species!=784
    when getID(PBItems,:SOLGANIUMZ) 
      canuse=false   
      for move in pkmn.moves
        canuse=true if move.id==getID(PBMoves,:SUNSTEELSTRIKE)
      end
    when getID(PBItems,:LUNALIUMZ)
      canuse=false   
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

