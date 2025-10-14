################################################################################
 WILD_AI_LEVEL = 20 #Nivel en el que los salvajes comenzaran a ser inteligentes.
 WILD_AI_SWITCH = NO_CAPTURE_SWITCH
################################################################################
# AI skill levels:
#           0:     Wild Pokémon
#           1-31:  Basic trainer (young/inexperienced)
#           32-47: Some skill
#           48-99: High skill
#           100+:  Gym Leaders, E4, Champion, highest level
module PBTrainerAI
  # Minimum skill level to be in each AI category
  def PBTrainerAI.minimumSkill; 1; end
  def PBTrainerAI.mediumSkill; 32; end
  def PBTrainerAI.highSkill; 48; end
  def PBTrainerAI.bestSkill; 100; end   # Gym Leaders, E4, Champion
end

class PokeBattle_Battle
################################################################################
# Get a score for each move being considered (trainer-owned Pokémon only).
# Moves with higher scores are more likely to be chosen.
################################################################################
  def pbGetMoveScore(move,attacker,opponent,skill=100)
    #Movimientos que buffan o ayudan al rival.
    setup_moves = [
      :SWORDSDANCE, :DRAGONDANCE, :CALMMIND, :WORKUP, :NASTYPLOT, :TAILGLOW,
      :BELLYDRUM, :BULKUP, :COIL, :CURSE, :GROWTH, :HONECLAWS, :QUIVERDANCE,
      :SHELLSMASH, :LEECHSEED, :SUBSTITUTE, :AGILITY, :ROCKPOLISH, :SHIFTGEAR,
      :NORETREAT, :CLANGINGSCALES, :HONECLAWS, :COSMICPOWER, :AUTONOMIZE, :SHEDTAIL, 
      :IRONDEFENSE, :AMNESIA, :TAILWIND, :COIL, :STOCKPILE
    ]
    lowerUser_moves = [:SUPERPOWER, :OVERHEAT, :DRACOMETEOR, :LEAFSTORM, 
                       :FLEURCANNON, :PSYCHOBOOST, :MAKEITRAIN]
    sleep_moves = [:SPORE, :SLEEPPOWDER, :HYPNOSIS, :SING, :GRASSWHISTLE, 
                   :NIGHTMARE, :DREAMEATER, :YAWN]
    #Movimientos con Prioridad que puede parar Palma Rauda
    pri_moves = [:FAKEOUT,:QUICKGUARD,
                 :UPPERHAND,:WIDEGUARD,:ALLYSWITCH,:EXTREMESPEED,:FEINT,
                 :FIRSTIMPRESSION,:FOLLOWME,:RAGEPOWDER,:ACCELEROCK,:AQUAJET,
                 :BABYDOLLEYES,:BULLETPUNCH,:ICESHARD,:JETPUNCH,
                 :MACHPUNCH,:QUICKATTACK,:SHADOWSNEAK,:SUCKERPUNCH,:THUNDERCLAP,
                 :VACUUMWAVE,:WATERSHURIKEN]
    #Movimientos afectados por Dia Soleado y/o reducidos por otros climas
    solar_moves = [:MOONLIGHT, :SYNTHESIS, :MORNINGSUN, :SOLARBEAM, 
                   :SOLARBLADE, :GROWTH]
    # Habilidades que no pueden cambiar por otro movimiento o hab
    # Realmente habria una lista especifica para cada move, pero es mas compacto
    # así y evitamos que la IA haga cosas raras.
    # ~Clara
    abilities_to_avoid = [
      :TRUANT, :MULTITYPE, :ZENMODE, :STANCECHANGE, :SCHOOLING, :COMATOSE, 
      :SHIELDSDOWN, :DISGUISE, :RKSSYSTEM, :BATTLEBOND, :POWERCONSTRUCT, 
      :ICEFACE, :GULPMISSILE, :ASONE1, :ASONE2, :COMMANDER, :TRACE, :FORECAST, :FLOWERGIFT, 
      :ILLUSION, :IMPOSTER, :POWEROFALCHEMY, :RECEIVER, :HUNGERSWITCH, 
      :NEUTRALIZINGGAS, :ZEROTOHERO, :WONDERGUARD, :PROTOSYNTHESIS, :QUARKDRIVE, 
      :ORICHALCUMPULSE, :HADRONENGINE, :POISONPUPPETEER, :TERASHIFT
    ]
    bad_items = [
      :FLAMEORB, :TOXICORB, :STICKYBARB, :IRONBALL, :LAGGINGTAIL, :FULLINCENSE, 
      :RINGTARGET, :CHOICEBAND, :CHOICESCARF, :CHOICESPECS
    ]

    #Aqui empieza de verdad el script
    skill=PBTrainerAI.minimumSkill if skill<PBTrainerAI.minimumSkill
    score=100
    opponent=attacker.pbOppositeOpposing unless opponent
    opponent=opponent.pbPartner if opponent && opponent.isFainted?
    score=-100 if move.pp <= 0
    # Bromista / Prankster
    prankpri = (move.basedamage == 0 && attacker.hasWorkingAbility(:PRANKSTER))
    if move.priority > 0 || prankpri
      if move.basedamage > 0
        fastermon = (attacker.pbSpeed > pbRoughStat(opponent, PBStats::SPEED, skill)) ^ (@trickroom != 0)
        if score > 100
          score *= @doublebattle ? 1.3 : (fastermon ? 1.3 : 2)
        else
          score *= 0.7 if !fastermon && attacker.hasWorkingAbility(:STANCECHANGE)
        end
        movedamage = -1
        opppri = false
        pridam = -1
        score += @doublebattle ? 75 : 150 if !fastermon && movedamage > attacker.hp
        if opppri
          score *= 1.1
          score *= (fastermon ? 3 : 0.5) if pridam > attacker.hp
        end
        if !fastermon
          score *= 0 if opponent.effects[PBEffects::TwoTurnAttack] > 0
        end
        score *= 0 if @field.effects[PBEffects::PsychicTerrain] > 0
        score *= 0 if [:DAZZLING, :QUEENLYMAJESTY, :ARMORTAIL].any? { |ab| opponent.hasWorkingAbility(ab) }
      end
      quickcheck = skill >= PBTrainerAI.highSkill && attacker.pbHasMove?(getID(PBMoves, :QUICKGUARD))
      score *= 0.2 if quickcheck
    elsif move.priority < 0
      if fastermon
        score *= 0.9
        score *= 2 if move.basedamage > 0 && opponent.effects[PBEffects::TwoTurnAttack] > 0
      end
    end

##### Alter score depending on the move's function code ########################
    case move.function
    when 0x00 # No extra effect
    when 0x01 # Splash
      score-=95
      score=0 if skill>=PBTrainerAI.minimumSkill
    when 0x02 # Struggle
    when 0x03 # Sleep 
      if opponent.pbCanSleep?(attacker,false) && opponent.effects[PBEffects::Yawn]==0      
        miniscore=100
        miniscore*=1.3
        if attacker.pbHasMove?(getID(PBMoves,:DREAMEATER)) || 
          attacker.pbHasMove?(getID(PBMoves,:NIGHTMARE)) || 
          attacker.hasWorkingAbility(:BADDREAMS)
          miniscore*=1.5
        end
        miniscore*=1.3 if setup_moves.any? {|mov| attacker.pbHasMove?(getID(PBMoves, mov))}

        miniscore*=1.2 if opponent.hp==opponent.totalhp
        ministat = 0
        [PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPATK, PBStats::SPDEF, PBStats::SPEED, PBStats::ACCURACY, PBStats::EVASION].each do |stat|
          ministat += opponent.stages[stat]
        end
        miniscore *= (1 + 0.05 * ministat) if ministat > 0
        miniscore*=0.3 if opponent.hasWorkingAbility(:NATURALCURE)
        miniscore*=0.7 if opponent.hasWorkingAbility(:MARVELSCALE)
        if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
          miniscore*=1.3
        end
        if attacker.hasWorkingItem(:LEFTOVERS) || 
          (attacker.hasWorkingAbility(:POISONHEAL) && attacker.status==PBStatuses::POISON)
          miniscore*=1.2
        end
        miniscore*=0.5 if opponent.hasWorkingAbility(:SYNCHRONIZE) && attacker.status==0
        if ([:SPORE, :SLEEPPOWDER].include?(move.id) &&
            (opponent.hasWorkingItem(:SAFETYGOGGLES) ||
            opponent.hasWorkingAbility(:OVERCOAT) ||
            opponent.pbHasType?(:GRASS))) || 
            ([:SING, :GRASSWHISTLE].include?(move.id) && opponent.hasWorkingAbility(:SOUNDPROOF)) ||
            (attacker.hasWorkingAbility(:HYDRATION) && (pbWeather==PBWeather::RAINDANCE))
          miniscore = 0
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            miniscore*=2 if attacker.hasWorkingAbility(:SERENEGRACE)
          end   
          miniscore+=100
        end
        miniscore/=100.0
        score*=miniscore
        score*=2 if attacker.hasWorkingAbility(:SERENEGRACE)
        score=0 if isConst?(move.id,PBMoves,:DARKVOID) && !isConst?(attacker.species,PBSpecies,:DARKRAI) 
      else
        if skill>=PBTrainerAI.mediumSkill  
          if move.basedamage==0
            score-=90 
            score-=90 if opponent.pbOwnSide.effects[PBEffects::Safeguard]>0 || @field.effects[PBEffects::MistyTerrain]>0
          end
        end
      end
    when 0x04 #Yawn
      score += 40 if attacker.turncount == 0
      if opponent.effects[PBEffects::Yawn] > 0 || !opponent.pbCanSleep?(attacker, false)
        score -= 90
      else
        score += 30
        score -= 30 if opponent.hasWorkingAbility(:MARVELSCALE) && skill >= PBTrainerAI.highSkill
        if skill >= PBTrainerAI.bestSkill
          score -= 50 if opponent.moves.any? { |m| PBMoveData.new(m.id).function == 0xB4 || m.function == 0x11 }
        end
      end
    when 0x05, 0x06, 0xBE # Poison
      if opponent.pbCanPoison?(attacker,false)
        score+=30
          score+=30 if opponent.hp<=opponent.totalhp/4
          score+=50 if opponent.hp<=opponent.totalhp/8
          score-=40 if opponent.effects[PBEffects::Yawn]>0
        if skill>=PBTrainerAI.mediumSkill
          score+=10 if pbRoughStat(opponent,PBStats::DEFENSE,skill)>100
          score+=10 if pbRoughStat(opponent,PBStats::SPDEF,skill)>100
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:TOXICBOOST)
        end
      else
        if skill>=PBTrainerAI.mediumSkill  
          if move.basedamage==0
            score-=90 
            score-=90 if opponent.pbOwnSide.effects[PBEffects::Safeguard]>0 || @field.effects[PBEffects::MistyTerrain]>0
          end
        end
      end
    when 0x08 # Thunder + Paralyze
      if opponent.pbCanParalyze?(attacker,false) && opponent.effects[PBEffects::Yawn]<=0
        miniscore=100
        miniscore *= 1.1 if setup_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov)) }
        miniscore*=1.2 if opponent.hp==opponent.totalhp

        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]+opponent.stages[PBStats::SPATK]+opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini = 5 * ministat + 100
          minimini /= 100.0
          miniscore *= minimini
        end
        if skill>=PBTrainerAI.highSkill
          miniscore-=40 if opponent.hasWorkingAbility(:GUTS)
          miniscore-=50 if opponent.hasWorkingAbility(:MARVELSCALE)
          miniscore-=40 if opponent.hasWorkingAbility(:QUICKFEET)
          miniscore-=10 if opponent.hasWorkingAbility(:NATURALCURE)
        end
                
        if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed && 
          (pbRoughStat(opponent,PBStats::SPEED,skill)/2.0)<attacker.pbSpeed && @trickroom==0
          miniscore*=1.5
        end
        if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
          miniscore*=1.1
        end
        count = -1
       
        miniscore*=1.1 if opponent.effects[PBEffects::Confusion]>0
        miniscore*=1.1 if opponent.effects[PBEffects::Attract]>=0
        miniscore*=0.4 if opponent.effects[PBEffects::Yawn]>0
        miniscore-=100
        if move.addlEffect.to_f != 100
          miniscore*=(move.addlEffect.to_f/100)
          miniscore*=2 if attacker.hasWorkingAbility(:SERENEGRACE)
        end
        miniscore+=100
        miniscore/=100.0
        score*=miniscore
      end
      if pbWeather==PBWeather::RAINDANCE
        score+=20
      else
        score-=40
      end
      if opponent.hasWorkingAbility(:LIGHTNINGROD) || 
         attacker.pbPartner.hasWorkingAbility(:LIGHTNINGROD)
        score=0
      end
    when 0x07, 0x09, 0xC5
      if opponent.pbCanParalyze?(attacker,false) &&
         !(skill>=PBTrainerAI.mediumSkill &&
         isConst?(move.id,PBMoves,:THUNDERWAVE) &&
         pbTypeModifier(move.type,attacker,opponent)==0)
        score+=30
        if skill>=PBTrainerAI.mediumSkill
           aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
           ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          if aspeed<ospeed
            score+=30
          elsif aspeed>ospeed
            score-=40
          end
        end
        if skill>=PBTrainerAI.highSkill
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:QUICKFEET)
        end
      else
        if skill>=PBTrainerAI.mediumSkill  
          if move.basedamage==0
            score-=90 
            score-=90 if opponent.pbOwnSide.effects[PBEffects::Safeguard]>0 || @field.effects[PBEffects::MistyTerrain]>0
          end
        end
      end
    when 0x0A, 0x0B, 0xC6
      if opponent.pbCanBurn?(attacker,false)
        score+=30
        if skill>=PBTrainerAI.highSkill
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:QUICKFEET)
          score-=40 if opponent.hasWorkingAbility(:FLAREBOOST)
        end
      else
        if skill>=PBTrainerAI.mediumSkill
          score-=90 if move.basedamage==0
          score-=90 if opponent.pbOwnSide.effects[PBEffects::Safeguard]>0 || @field.effects[PBEffects::MistyTerrain]>0
        end
      end
    when 0x0C, 0x0D, 0x0E
      if opponent.pbCanFreeze?(attacker,false)
        score+=30
        if skill>=PBTrainerAI.highSkill
          score-=20 if opponent.hasWorkingAbility(:MARVELSCALE)
        end
      else
        if skill>=PBTrainerAI.mediumSkill
          if move.basedamage==0
            score-=90 
            score-=90 if opponent.pbOwnSide.effects[PBEffects::Safeguard]>0 || @field.effects[PBEffects::MistyTerrain]>0
          end
        end
      end
    when 0x0F
      score+=30
      if skill>=PBTrainerAI.highSkill
        score+=30 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                     opponent.effects[PBEffects::Substitute]==0
      end
    when 0x10
      if skill>=PBTrainerAI.highSkill
        score+=30 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                     opponent.effects[PBEffects::Substitute]==0
      end
      score+=30 if opponent.effects[PBEffects::Minimize]
    when 0x11
      if attacker.status==PBStatuses::SLEEP
        score+=100 # Because it can be used while asleep
        if skill>=PBTrainerAI.highSkill
          score+=30 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                       opponent.effects[PBEffects::Substitute]==0
        end
      else
        score-=90 # Because it will fail here
        score=0 if skill>=PBTrainerAI.bestSkill
      end
    when 0x12
      if attacker.turncount==0
        if skill>=PBTrainerAI.highSkill
          score+=30 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                       opponent.effects[PBEffects::Substitute]==0
        end
      else
        score-=90 # Because it will fail here
        score=0 if skill>=PBTrainerAI.bestSkill
      end
    when 0x13 # Confusion 
      if opponent.pbCanConfuse?(false)
        miniscore=100
        miniscore*=1.2
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        if ministat>0
          minimini=10*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end      
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.2
        end
        miniscore*=1.1 if opponent.effects[PBEffects::Attract]>=0
        miniscore*=1.1 if opponent.status==PBStatuses::PARALYSIS
        miniscore*=0.4 if opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
        miniscore*=0.7 if opponent.hasWorkingAbility(:TANGLEDFEET)    
        if attacker.pbHasMove?(getID(PBMoves,:SUBSTITUTE))
          miniscore*=1.2
          miniscore*=1.3 if attacker.effects[PBEffects::Substitute]>0
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            miniscore*=2 if attacker.hasWorkingAbility(:SERENEGRACE)
          end   
          miniscore+=100
        end
        miniscore/=100.0
        score*=miniscore
      else
        score=0 if move.basedamage<=0
      end
    when 0x14 # Chatter
        #This is no longer used, Chatter works off of the standard confusion
        #function code, 0x13
    when 0x15
      score+=90 if pbWeather==PBWeather::RAINDANCE
      score-=30 if pbWeather==PBWeather::SUNNYDAY
    when 0x16
      canattract=true
      agender=attacker.gender
      ogender=opponent.gender
      if agender==2 || ogender==2 || agender==ogender
        score-=90; canattract=false
      elsif opponent.effects[PBEffects::Attract]>=0
        score-=80; canattract=false
      elsif skill>=PBTrainerAI.bestSkill &&
         opponent.hasWorkingAbility(:OBLIVIOUS)
        score-=80; canattract=false
      end
      if skill>=PBTrainerAI.highSkill
        if canattract && opponent.hasWorkingItem(:DESTINYKNOT) &&
           attacker.pbCanAttract?(opponent,false)
          score-=30
        end
      end
    when 0x17
      score+=30 if opponent.status==0
    when 0x18
      if attacker.status==PBStatuses::BURN
        score+=40
      elsif attacker.status==PBStatuses::POISON
        score+=40
        if skill>=PBTrainerAI.mediumSkill
          if attacker.hp<attacker.totalhp/8
            score+=60
          elsif skill>=PBTrainerAI.highSkill &&
             attacker.hp<(attacker.effects[PBEffects::Toxic]+1)*attacker.totalhp/16
            score+=60
          end
        end
      elsif attacker.status==PBStatuses::PARALYSIS
        score+=40
      else
        score-=90
      end
    when 0x19
      party=pbParty(attacker.index)
      statuses=0
      for i in 0...party.length
        statuses+=1 if party[i] && party[i].status!=0
      end
      if statuses==0
        score-=80
      else
        score+=20*statuses
      end
    when 0x1A
      if attacker.pbOwnSide.effects[PBEffects::Safeguard]>0 || @field.effects[PBEffects::MistyTerrain]>0
        score-=80 
      elsif attacker.status!=0
        score-=40
      else
        score+=30
      end
    when 0x1B
      if attacker.status==0
        score-=90
      else
        score+=40
      end
    when 0x1C
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::ATTACK)
          score-=90
        elsif attacker.stages[PBStats::ATTACK]>=2
          score-=70
        else
          score-=attacker.stages[PBStats::ATTACK]*20
          if skill>=PBTrainerAI.mediumSkill
            hasphysicalattack=false
            for thismove in attacker.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsPhysical?(thismove.type)
                hasphysicalattack=true
              end
            end
            if hasphysicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=20 if attacker.stages[PBStats::ATTACK]<0
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          score+=20 if hasphysicalattack
        end
      end
    when 0x1D, 0x1E, 0xC8
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::DEFENSE)
          score-=90
        elsif attacker.stages[PBStats::DEFENSE]>=2
          score-=70
        else
          score-=attacker.stages[PBStats::DEFENSE]*20
        end
      else
        score+=20 if attacker.stages[PBStats::DEFENSE]<0
      end
    when 0x1F
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPEED)
          score-=90
        elsif attacker.stages[PBStats::SPEED]>=2
          score-=70
        else
          score-=attacker.stages[PBStats::SPEED]*10
          if skill>=PBTrainerAI.highSkill
            aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
            ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
            score+=30 if aspeed<ospeed && aspeed*2>ospeed
          end
        end
      else
        score+=20 if attacker.stages[PBStats::SPEED]<0
      end
    when 0x20
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPATK)
          score-=90
        elsif attacker.stages[PBStats::SPATK]>=2
          score-=70
        else
          score-=attacker.stages[PBStats::SPATK]*20
          if skill>=PBTrainerAI.mediumSkill
            hasspecicalattack=false
            for thismove in attacker.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsSpecial?(thismove.type)
                hasspecicalattack=true
              end
            end
            if hasspecicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=20 if attacker.stages[PBStats::SPATK]<0
        if skill>=PBTrainerAI.mediumSkill
          hasspecicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecicalattack=true
            end
          end
          score+=20 if hasspecicalattack
        end
      end
    when 0x21
      foundmove=false
      for i in 0...4
        if isConst?(attacker.moves[i].type,PBTypes,:ELECTRIC) &&
           attacker.moves[i].basedamage>0
          foundmove=true
          break
        end
      end
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPDEF)
          score-=90
        else
          score-=attacker.stages[PBStats::SPDEF]*20
        end
        score+=20 if foundmove
      else
        score+=20 if attacker.stages[PBStats::SPDEF]<0
        score+=20 if foundmove
      end
    when 0x22
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::EVASION)
          score-=90
        else
          score-=attacker.stages[PBStats::EVASION]*10
        end
      else
        score+=20 if attacker.stages[PBStats::EVASION]<0
      end
    when 0x23
      if move.basedamage==0
        if attacker.effects[PBEffects::FocusEnergy]>=2
          score-=80
        else
          score+=30
        end
      else
        score+=30 if attacker.effects[PBEffects::FocusEnergy]<2
      end
    when 0x24
      if attacker.pbTooHigh?(PBStats::ATTACK) &&
         attacker.pbTooHigh?(PBStats::DEFENSE)
        score-=90
      elsif attacker.stages[PBStats::ATTACK]>=2 && 
        attacker.stages[PBStats::DEFENSE]>=2
        score-=70
      else
        score-=attacker.stages[PBStats::ATTACK]*10
        score-=attacker.stages[PBStats::DEFENSE]*10
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
      end
    when 0x25
      if attacker.pbTooHigh?(PBStats::ATTACK) &&
         attacker.pbTooHigh?(PBStats::DEFENSE) &&
         attacker.pbTooHigh?(PBStats::ACCURACY)
        score-=90
      elsif attacker.stages[PBStats::ATTACK]>=2 && 
            attacker.stages[PBStats::DEFENSE]>=2 &&
            attacker.stages[PBStats::ACCURACY]>=2
            score-=70
      else
        score-=attacker.stages[PBStats::ATTACK]*10
        score-=attacker.stages[PBStats::DEFENSE]*10
        score-=attacker.stages[PBStats::ACCURACY]*10
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
      end
    when 0x26 #Dragon Dance
      score+=40 if attacker.turncount==0 # Dragon Dance tends to be popular
      if attacker.pbTooHigh?(PBStats::ATTACK) &&
         attacker.pbTooHigh?(PBStats::SPEED)
        score-=90
      elsif attacker.stages[PBStats::ATTACK]>=2 && 
        attacker.stages[PBStats::SPEED]>=2
        score-=70
      else
        score-=attacker.stages[PBStats::ATTACK]*10
        score-=attacker.stages[PBStats::SPEED]*10
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
        if skill>=PBTrainerAI.highSkill
          aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
          ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          if aspeed<ospeed && aspeed*2>ospeed
            score+=20
          end
        end
      end
    when 0x27, 0x28 #Avivar
      if attacker.pbTooHigh?(PBStats::ATTACK) &&
         attacker.pbTooHigh?(PBStats::SPATK)
        score-=90
      elsif attacker.stages[PBStats::ATTACK]>=2 && 
        attacker.stages[PBStats::SPATK]>=2
        score-=90
      else
        score-=attacker.stages[PBStats::ATTACK]*10
        score-=attacker.stages[PBStats::SPATK]*10
        if skill>=PBTrainerAI.mediumSkill
          hasdamagingattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0
              hasdamagingattack=true; break
            end
          end
          if hasdamagingattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
        score+=20 if pbWeather==PBWeather::SUNNYDAY && move.function==0x28 #Grown
      end
    when 0x29
      if attacker.pbTooHigh?(PBStats::ATTACK) &&
         attacker.pbTooHigh?(PBStats::ACCURACY)
        score-=90
      elsif attacker.stages[PBStats::ATTACK]>=2
        score-=90
      else
        score-=attacker.stages[PBStats::ATTACK]*10
        score-=attacker.stages[PBStats::ACCURACY]*10
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
      end
    when 0x2A # Cosmic Power 
      score*=1.3 if attacker.pbHasMove?(getID(PBMoves,:STOREDPOWER))
      score*=0.8 if attacker.pbHasMove?(getID(PBMoves,:LEECHSEED))
      score*=1.2 if attacker.pbHasMove?(getID(PBMoves,:PAINSPLIT))

      if attacker.hasWorkingItem(:LEFTOVERS) || (attacker.hasWorkingItem(:BLACKSLUDGE) && attacker.pbHasType?(:POISON))
        score*=1.2
      end        
       
      score*=1.1 if attacker.turncount<2
      score*=1.1 if opponent.status!=0
      score*=1.3 if opponent.status==PBStatuses::SLEEP# || opponent.status==PBStatuses::FROZEN

      if opponent.effects[PBEffects::Encore]>0
        if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0            
          score*=1.5
        end          
      end  
        
      if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
        score*=0.3
      end
      score*=0.5 if attacker.effects[PBEffects::Confusion]>0
      score*=0.2 if attacker.effects[PBEffects::Toxic]>0

      score=0 if attacker.hasWorkingAbility(:CONTRARY)
      score=0 if opponent.hasWorkingAbility(:UNAWARE)
      score*=0 if attacker.pbTooHigh?(PBStats::SPDEF) && attacker.pbTooHigh?(PBStats::DEFENSE)

    when 0x2B # Quiver Dance
      if attacker.pbTooHigh?(PBStats::SPEED) &&
         attacker.pbTooHigh?(PBStats::SPATK) &&
         attacker.pbTooHigh?(PBStats::SPDEF)
        score-=90
      else
        score-=attacker.stages[PBStats::SPATK]*10
        score-=attacker.stages[PBStats::SPDEF]*10
        score-=attacker.stages[PBStats::SPEED]*10
        if skill>=PBTrainerAI.mediumSkill
          hasspecicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecicalattack=true
            end
          end
          if hasspecicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
        if skill>=PBTrainerAI.highSkill
          aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
          ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          if aspeed<ospeed && aspeed*2>ospeed
            score+=20
          end
        end
      end
    when 0x2C
      if attacker.pbTooHigh?(PBStats::SPATK) &&
         attacker.pbTooHigh?(PBStats::SPDEF)
        score-=90
      else
        score+=40 if attacker.turncount==0 # Calm Mind tends to be popular
        score-=attacker.stages[PBStats::SPATK]*10
        score-=attacker.stages[PBStats::SPDEF]*10
        if skill>=PBTrainerAI.mediumSkill
          hasspecicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecicalattack=true
            end
          end
          if hasspecicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
      end
    when 0x2D
      score+=10 if attacker.stages[PBStats::ATTACK]<0
      score+=10 if attacker.stages[PBStats::DEFENSE]<0
      score+=10 if attacker.stages[PBStats::SPEED]<0
      score+=10 if attacker.stages[PBStats::SPATK]<0
      score+=10 if attacker.stages[PBStats::SPDEF]<0 
      if skill>=PBTrainerAI.mediumSkill
        hasdamagingattack=false
        for thismove in attacker.moves
          if thismove.id!=0 && thismove.basedamage>0
            hasdamagingattack=true
          end
        end
        if hasdamagingattack
          score+=20
        end
      end
    when 0x2E # Swords Dance
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::ATTACK)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::ATTACK]*20
          if skill>=PBTrainerAI.mediumSkill
            hasphysicalattack=false
            for thismove in attacker.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsPhysical?(thismove.type)
                hasphysicalattack=true
              end
            end
            if hasphysicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if attacker.stages[PBStats::ATTACK]<0
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          end
        end
      end
    when 0x2F #Iron Defense
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::DEFENSE)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::DEFENSE]*20
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if attacker.stages[PBStats::DEFENSE]<0
      end
    when 0x30, 0x31 # Agility
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPEED)
          score-=90
        else
          score+=20 if attacker.turncount==0
          score-=attacker.stages[PBStats::SPEED]*10
          if skill>=PBTrainerAI.highSkill
            aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
            ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
            if aspeed<ospeed && aspeed*2>ospeed
              score+=30
            end
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if attacker.stages[PBStats::SPEED]<0
      end
    when 0x32 # Nasty Plot
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPATK)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::SPATK]*20
          if skill>=PBTrainerAI.mediumSkill
            hasspecicalattack=false
            for thismove in attacker.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsSpecial?(thismove.type)
                hasspecicalattack=true
              end
            end
            if hasspecicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if attacker.stages[PBStats::SPATK]<0
        if skill>=PBTrainerAI.mediumSkill
          hasspecicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecicalattack=true
            end
          end
          score+=20 if hasspecicalattack
        end
      end
    when 0x33 # Amnesia
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPDEF)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::SPDEF]*20
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if attacker.stages[PBStats::SPDEF]<0
      end
    when 0x34 #Minimize
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::EVASION)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::EVASION]*10
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if attacker.stages[PBStats::EVASION]<0
      end
    when 0x35
      score-=attacker.stages[PBStats::ATTACK]*20
      score-=attacker.stages[PBStats::SPEED]*20
      score-=attacker.stages[PBStats::SPATK]*20
      score+=attacker.stages[PBStats::DEFENSE]*10
      score+=attacker.stages[PBStats::SPDEF]*10
      if skill>=PBTrainerAI.mediumSkill
        hasdamagingattack=false
        for thismove in attacker.moves
          hasdamagingattack=true if thismove.id!=0 && thismove.basedamage>0
        end
        score+=20 if hasdamagingattack
      end
    when 0x36 #Dragon Dance
      if attacker.pbTooHigh?(PBStats::ATTACK) &&
         attacker.pbTooHigh?(PBStats::SPEED)
        score-=90
      else
        score-=attacker.stages[PBStats::ATTACK]*10
        score-=attacker.stages[PBStats::SPEED]*10
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
        if skill>=PBTrainerAI.highSkill
          aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
          ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          score+=30 if aspeed<ospeed && aspeed*2>ospeed
        end
      end
    when 0x37 #Acupressure/Acupresión
      # Check if all stats are too high
      if [PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPEED, PBStats::SPATK, PBStats::SPDEF, PBStats::ACCURACY, PBStats::EVASION].all? { |stat| opponent.pbTooHigh?(stat) }
        score -= 90
      else
        avstat = 0
        # Subtract all stat stages in a loop
        [PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPEED, PBStats::SPATK, PBStats::SPDEF, PBStats::ACCURACY, PBStats::EVASION].each do |stat|
          avstat -= opponent.stages[stat]
        end
        avstat = (avstat / 2).floor if avstat < 0 # More chance of getting even better
        score += avstat * 10
      end
    when 0x38 
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::DEFENSE)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::DEFENSE]*30
        end
      else
        score+=10 if attacker.turncount==0
        score+=30 if attacker.stages[PBStats::DEFENSE]<0
      end
    when 0x39 #Glow Tail
      if move.basedamage==0
        if attacker.pbTooHigh?(PBStats::SPATK)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score-=attacker.stages[PBStats::SPATK]*30
          if skill>=PBTrainerAI.mediumSkill
            hasspecicalattack=false
            for thismove in attacker.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsSpecial?(thismove.type)
                hasspecicalattack=true
              end
            end
            if hasspecicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=30 if attacker.stages[PBStats::SPATK]<0
        if skill>=PBTrainerAI.mediumSkill
          hasspecicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecicalattack=true
            end
          end
          if hasspecicalattack
            score+=30
          end
        end
      end
    when 0x3A #Belly Drum
      if attacker.pbTooHigh?(PBStats::ATTACK) ||
         attacker.hp<=attacker.totalhp/2
        score-=100
      else
        score+=(6-attacker.stages[PBStats::ATTACK])*10
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=40
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
      end
    when 0x3B #SUPER POWER
      avg=attacker.stages[PBStats::ATTACK]*10
      avg+=attacker.stages[PBStats::DEFENSE]*10
      score+=avg/2
    when 0x3C # Close Combat
      avg=attacker.stages[PBStats::DEFENSE]*10
      avg+=attacker.stages[PBStats::SPDEF]*10
      score+=avg/2
    when 0x3D
      avg=attacker.stages[PBStats::DEFENSE]*10
      avg+=attacker.stages[PBStats::SPEED]*10
      avg+=attacker.stages[PBStats::SPDEF]*10
      score+=(avg/3).floor
    when 0x3E
      score+=attacker.stages[PBStats::SPEED]*10
    when 0x3F
      score+=attacker.stages[PBStats::SPATK]*10
    when 0x40 #(Camelo/Flatter)
      if !opponent.pbCanConfuse?(attacker,false)
        score-=90
      else
        score+=30 if opponent.stages[PBStats::SPATK]<0
      end
    when 0x41 #Contoneo/Swagger
      if !opponent.pbCanConfuse?(attacker,false)
        score-=90
      else
        score+=30 if opponent.stages[PBStats::ATTACK]<0
      end
    when 0x42 #Growl
      if (pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)) || 
         opponent.stages[PBStats::ATTACK]>0 || 
         !opponent.pbCanReduceStatStage?(PBStats::ATTACK)
        score=0 if move.basedamage==0
      else
        miniscore=100
        if opponent.stages[PBStats::ATTACK]<0
          minimini = 5*opponent.stages[PBStats::ATTACK]
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=0.5 if attacker.pbHasMove?(getID(PBMoves,:FOULPLAY))
        miniscore*=0.5 if opponent.status==PBStatuses::BURN
        if opponent.hasWorkingAbility(:UNAWARE) || 
            opponent.hasWorkingAbility(:COMPETITIVE) || 
            opponent.hasWorkingAbility(:DEFIANT) || 
            opponent.hasWorkingAbility(:CONTRARY)
          miniscore*=0.1
        end   
        miniscore/=100.0
        score*=miniscore
      end     
    when 0x43
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker)
          score-=90
        else
          score+=opponent.stages[PBStats::DEFENSE]*20
        end
      else
        score+=20 if opponent.stages[PBStats::DEFENSE]>0
      end
      if opponent.hasWorkingAbility(:COMPETITIVE) || 
         opponent.hasWorkingAbility(:DEFIANT) || 
         opponent.hasWorkingAbility(:CONTRARY)
        score*=0.1
      end
      
    when 0x44 #Bajar velovidad
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker)
          score-=90
        else
          score+=opponent.stages[PBStats::SPEED]*10
          if skill>=PBTrainerAI.highSkill
            aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
            ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
            if aspeed<ospeed && aspeed*2>ospeed
              score+=30
            end
          end
        end
      else
        score+=20 if attacker.stages[PBStats::SPEED]>0
      end
      if opponent.hasWorkingAbility(:COMPETITIVE) || 
         opponent.hasWorkingAbility(:DEFIANT) || 
         opponent.hasWorkingAbility(:CONTRARY)
        score*=0.1
      end
    when 0x45
      if (pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)) || 
         opponent.stages[PBStats::SPATK]>0 || 
         !opponent.pbCanReduceStatStage?(PBStats::SPATK)
        score=0 if move.basedamage==0
      else
        miniscore=100
        if opponent.stages[PBStats::SPATK]<0
          minimini = 5*opponent.stages[PBStats::SPATK]
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if opponent.hasWorkingAbility(:UNAWARE) || 
            opponent.hasWorkingAbility(:COMPETITIVE) || 
            opponent.hasWorkingAbility(:DEFIANT) || 
            opponent.hasWorkingAbility(:CONTRARY)
          miniscore*=0.1
        end
        miniscore/=100.0
        score*=miniscore
      end     
    when 0x46
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker)
          score-=90
        else
          score+=opponent.stages[PBStats::SPDEF]*20
        end
      else
        score+=20 if opponent.stages[PBStats::SPDEF]>0
      end
      if opponent.hasWorkingAbility(:COMPETITIVE) || 
         opponent.hasWorkingAbility(:DEFIANT) || 
         opponent.hasWorkingAbility(:CONTRARY)
        score*=0.1
      end
    when 0x47 #Bajar Precision
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::ACCURACY,attacker)
          score-=90
        else
          score+=opponent.stages[PBStats::ACCURACY]*10
        end
      else
        score+=20 if opponent.stages[PBStats::ACCURACY]>0
      end
      if opponent.hasWorkingAbility(:COMPETITIVE) || 
         opponent.hasWorkingAbility(:DEFIANT) || 
         opponent.hasWorkingAbility(:CONTRARY)
        score*=0.1
      end
    when 0x48
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker)
          score-=90
        else
          score+=opponent.stages[PBStats::EVASION]*10
        end
      else
        score+=20 if opponent.stages[PBStats::EVASION]>0
      end
    when 0x49
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker)
          score-=90
        else
          score+=opponent.stages[PBStats::EVASION]*10
        end
      else
        score+=20 if opponent.stages[PBStats::EVASION]>0
      end
      score+=30 if opponent.pbOwnSide.effects[PBEffects::Reflect]>0 ||
                   opponent.pbOwnSide.effects[PBEffects::LightScreen]>0 ||
                   opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0 ||                   
                   opponent.pbOwnSide.effects[PBEffects::Mist]>0 ||
                   opponent.pbOwnSide.effects[PBEffects::Safeguard]>0
      score-=30 if opponent.pbOwnSide.effects[PBEffects::Spikes]>0 ||
                   opponent.pbOwnSide.effects[PBEffects::ToxicSpikes]>0 ||
                   opponent.pbOwnSide.effects[PBEffects::StealthRock]
    when 0x4A
      avg=opponent.stages[PBStats::ATTACK]*10
      avg+=opponent.stages[PBStats::DEFENSE]*10
      score+=avg/2
    when 0x4B
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score+=opponent.stages[PBStats::ATTACK]*20
          if skill>=PBTrainerAI.mediumSkill
            hasphysicalattack=false
            for thismove in opponent.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsPhysical?(thismove.type)
                hasphysicalattack=true
              end
            end
            if hasphysicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if opponent.stages[PBStats::ATTACK]>0
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in opponent.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          end
        end
      end
    when 0x4C
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score+=opponent.stages[PBStats::DEFENSE]*20
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if opponent.stages[PBStats::DEFENSE]>0
      end
    when 0x4D
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker)
          score-=90
        else
          score+=20 if attacker.turncount==0
          score+=opponent.stages[PBStats::SPEED]*20
          if skill>=PBTrainerAI.highSkill
            aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
            ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
            score+=30 if aspeed<ospeed && aspeed*2>ospeed
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=30 if opponent.stages[PBStats::SPEED]>0
      end
    when 0x4E
      if attacker.gender==2 || opponent.gender==2 ||
         attacker.gender==opponent.gender ||
         opponent.hasWorkingAbility(:OBLIVIOUS)
        score-=90
      elsif move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score+=opponent.stages[PBStats::SPATK]*20
          if skill>=PBTrainerAI.mediumSkill
            hasspecicalattack=false
            for thismove in opponent.moves
              if thismove.id!=0 && thismove.basedamage>0 &&
                 thismove.pbIsSpecial?(thismove.type)
                hasspecicalattack=true
              end
            end
            if hasspecicalattack
              score+=20
            elsif skill>=PBTrainerAI.highSkill
              score-=90
            end
          end
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if opponent.stages[PBStats::SPATK]>0
        if skill>=PBTrainerAI.mediumSkill
          hasspecicalattack=false
          for thismove in opponent.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecicalattack=true
            end
          end
          score+=30 if hasspecicalattack
        end
      end
    when 0x4F
      if move.basedamage==0
        if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker)
          score-=90
        else
          score+=40 if attacker.turncount==0
          score+=opponent.stages[PBStats::SPDEF]*20
        end
      else
        score+=10 if attacker.turncount==0
        score+=20 if opponent.stages[PBStats::SPDEF]>0
      end
    when 0x50
      if opponent.effects[PBEffects::Substitute]>0
        score-=90
      else
        anychange=false
        avg=opponent.stages[PBStats::ATTACK]; anychange=true if avg!=0
        avg+=opponent.stages[PBStats::DEFENSE]; anychange=true if avg!=0
        avg+=opponent.stages[PBStats::SPEED]; anychange=true if avg!=0
        avg+=opponent.stages[PBStats::SPATK]; anychange=true if avg!=0
        avg+=opponent.stages[PBStats::SPDEF]; anychange=true if avg!=0
        avg+=opponent.stages[PBStats::ACCURACY]; anychange=true if avg!=0
        avg+=opponent.stages[PBStats::EVASION]; anychange=true if avg!=0
        if anychange
          score+=avg*10
        else
          score-=90
        end
      end
    when 0x51
      if skill>=PBTrainerAI.mediumSkill
        stages=0
        for i in 0...4
          battler=@battlers[i]
          if attacker.pbIsOpposing?(i)
            stages+=battler.stages[PBStats::ATTACK]
            stages+=battler.stages[PBStats::DEFENSE]
            stages+=battler.stages[PBStats::SPEED]
            stages+=battler.stages[PBStats::SPATK]
            stages+=battler.stages[PBStats::SPDEF]
            stages+=battler.stages[PBStats::EVASION]
            stages+=battler.stages[PBStats::ACCURACY]
          else
            stages-=battler.stages[PBStats::ATTACK]
            stages-=battler.stages[PBStats::DEFENSE]
            stages-=battler.stages[PBStats::SPEED]
            stages-=battler.stages[PBStats::SPATK]
            stages-=battler.stages[PBStats::SPDEF]
            stages-=battler.stages[PBStats::EVASION]
            stages-=battler.stages[PBStats::ACCURACY]
          end
        end
        score+=stages*10
      end
    when 0x52
      if skill>=PBTrainerAI.mediumSkill
        aatk=attacker.stages[PBStats::ATTACK]
        aspa=attacker.stages[PBStats::SPATK]
        oatk=opponent.stages[PBStats::ATTACK]
        ospa=opponent.stages[PBStats::SPATK]
        if aatk>=oatk && aspa>=ospa
          score-=80
        else
          score+=(oatk-aatk)*10
          score+=(ospa-aspa)*10
        end
      else
        score-=50
      end
    when 0x53 # Guard Swap
      if skill>=PBTrainerAI.mediumSkill
        adef=attacker.stages[PBStats::DEFENSE]
        aspd=attacker.stages[PBStats::SPDEF]
        odef=opponent.stages[PBStats::DEFENSE]
        ospd=opponent.stages[PBStats::SPDEF]
        if adef>=odef && aspd>=ospd
          score-=80
        else
          score+=(odef-adef)*10
          score+=(ospd-aspd)*10
        end
      else
        score-=50
      end
    when 0x54 # Heart Swap
      if skill>=PBTrainerAI.mediumSkill
        astages=attacker.stages[PBStats::ATTACK]
        astages+=attacker.stages[PBStats::DEFENSE]
        astages+=attacker.stages[PBStats::SPEED]
        astages+=attacker.stages[PBStats::SPATK]
        astages+=attacker.stages[PBStats::SPDEF]
        astages+=attacker.stages[PBStats::EVASION]
        astages+=attacker.stages[PBStats::ACCURACY]
        ostages=opponent.stages[PBStats::ATTACK]
        ostages+=opponent.stages[PBStats::DEFENSE]
        ostages+=opponent.stages[PBStats::SPEED]
        ostages+=opponent.stages[PBStats::SPATK]
        ostages+=opponent.stages[PBStats::SPDEF]
        ostages+=opponent.stages[PBStats::EVASION]
        ostages+=opponent.stages[PBStats::ACCURACY]
        score+=(ostages-astages)*10
      else
        score-=50
      end
    when 0x55 # Psych Up
      if skill>=PBTrainerAI.mediumSkill
        equal=true
        for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                 PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
          stagediff=opponent.stages[i]-attacker.stages[i]
          score+=stagediff*10
          equal=false if stagediff!=0
        end
        score-=80 if equal
      else
        score-=50
      end
    when 0x56 # Mist
      score-=80 if attacker.pbOwnSide.effects[PBEffects::Mist]>0
      
    when 0x57 # Power Trick

      aatk=pbRoughStat(attacker,PBStats::ATTACK,skill)
      adef=pbRoughStat(attacker,PBStats::DEFENSE,skill)
      if aatk==adef || attacker.effects[PBEffects::PowerTrick] # No flip-flopping
        score-=90
      elsif adef>aatk # Prefer a higher Attack
        score+=50
      else
        score-=50
      end
      
    when 0x58 # Power Split
      if skill>=PBTrainerAI.mediumSkill
        aatk=pbRoughStat(attacker,PBStats::ATTACK,skill)
        aspatk=pbRoughStat(attacker,PBStats::SPATK,skill)
        oatk=pbRoughStat(opponent,PBStats::ATTACK,skill)
        ospatk=pbRoughStat(opponent,PBStats::SPATK,skill)
        if aatk<oatk && aspatk<ospatk
          score+=50
        elsif (aatk+aspatk)<(oatk+ospatk)
          score+=30
        else
          score-=50
        end
      else
        score-=30
      end
      
    when 0x59 # Guard Split
      if skill>=PBTrainerAI.mediumSkill
        adef=pbRoughStat(attacker,PBStats::DEFENSE,skill)
        aspdef=pbRoughStat(attacker,PBStats::SPDEF,skill)
        odef=pbRoughStat(opponent,PBStats::DEFENSE,skill)
        ospdef=pbRoughStat(opponent,PBStats::SPDEF,skill)
        if adef<odef && aspdef<ospdef
          score+=50
        elsif (adef+aspdef)<(odef+ospdef)
          score+=30
        else
          score-=50
        end
      else
        score-=30
      end
      
    when 0x5A # Pain Split
      if opponent.effects[PBEffects::Substitute]>0
        score-=90
      elsif attacker.hp>=(attacker.hp+opponent.hp)/2
        score-=90
      else
        score+=40
      end
      
    when 0x5B # Tailwind      
      if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0
        score = 0 
      else
        score+=90
        score*=1.5 if @doublebattle
        score*=1.5 if attacker.hasWorkingAbility(:WINDRIDER)
        score*=0.5 if opponent.hasWorkingAbility(:SPEEDBOOST) || opponent.hasWorkingAbility(:WINDRIDER)
        score*=0.1 if opponent.pbHasMove?(getID(PBMoves,:TRICKROOM))
      end
    when 0x5C # Mimic
      blacklist=[
         0x02,   # Struggle
         0x14,   # Chatter
         0x5C,   # Mimic
         0x5D,   # Sketch
         0xB6    # Metronome
      ]
      if attacker.effects[PBEffects::Transform] ||
         opponent.lastMoveUsed<=0 ||
         isConst?(PBMoveData.new(opponent.lastMoveUsed).type,PBTypes,:SHADOW) ||
         blacklist.include?(PBMoveData.new(opponent.lastMoveUsed).function)
        score-=90
      end
      for i in attacker.moves
        if i.id==opponent.lastMoveUsed
          score-=90; break
        end
      end
    when 0x5D # Sketch
      blacklist=[
         0x02,   # Struggle
         0x14,   # Chatter
         0x5D    # Sketch
      ]
      if attacker.effects[PBEffects::Transform] ||
         opponent.lastMoveUsedSketch<=0 ||
         isConst?(PBMoveData.new(opponent.lastMoveUsedSketch).type,PBTypes,:SHADOW) ||
         blacklist.include?(PBMoveData.new(opponent.lastMoveUsedSketch).function)
        score-=90
      end
      for i in attacker.moves
        if i.id==opponent.lastMoveUsedSketch
          score-=90; break
        end
      end
    when 0x5E # Conversion       
      if isConst?(attacker.ability,PBAbilities,:MULTITYPE) || isConst?(attacker.ability,PBAbilities,:RKSSYSTEM)
        score-=90
      else
        types=[]
        for i in attacker.moves
          next if i.id==@id
          next if PBTypes.isPseudoType?(i.type)
          next if attacker.pbHasType?(i.type)
          found=false
          types.push(i.type) if !types.include?(i.type)
        end
        score-=90 if types.length==0
      end
    when 0x5F # Conversion 2
      if isConst?(attacker.ability,PBAbilities,:MULTITYPE) || isConst?(attacker.ability,PBAbilities,:RKSSYSTEM)
        score-=90
      elsif opponent.lastMoveUsed<=0 ||
         PBTypes.isPseudoType?(PBMoveData.new(opponent.lastMoveUsed).type)
        score-=90
      else
        atype=-1
        for i in opponent.moves
          if i.id==opponent.lastMoveUsed
            atype=i.pbType(move.type,attacker,opponent); break
          end
        end
        if atype<0
          score-=90
        else
          types=[]
          for i in 0..PBTypes.maxValue
            next if attacker.pbHasType?(i)
            types.push(i) if PBTypes.getEffectiveness(atype,i)<2 
          end
          score-=90 if types.length==0
        end
      end
    when 0x60 # Camouflage
      if isConst?(attacker.ability,PBAbilities,:MULTITYPE) || isConst?(attacker.ability,PBAbilities,:RKSSYSTEM)
        score-=90
      elsif skill>=PBTrainerAI.mediumSkill
        envtypes=[
           :NORMAL, # None
           :GRASS,  # Grass
           :GRASS,  # Tall grass
           :WATER,  # Moving water
           :WATER,  # Still water
           :WATER,  # Underwater
           :ROCK,   # Rock
           :ROCK,   # Cave
           :GROUND  # Sand
        ]
        type=envtypes[@environment]
        score-=90 if attacker.pbHasType?(type)
      end
    when 0x61 # Soak
      sevar = false
      for i in attacker.moves
        sevar = true if isConst?(i.type,PBTypes,:ELECTRIC) || isConst?(i.type,PBTypes,:GRASS)
      end
      score*= sevar ? 1.5 : 0.7
      score*= opponent.pbHasMoveType?(:WATER) ? 0.5 : 1.1
      score=0 if opponent.hasWorkingAbility(:MULTITYPE) || opponent.hasWorkingAbility(:RKSSYSTEM)
      score=0 if opponent.pbHasType?(:WATER)
    when 0x62 # Reflect Type
      if isConst?(attacker.ability,PBAbilities,:MULTITYPE) || isConst?(attacker.ability,PBAbilities,:RKSSYSTEM)
        score-=90
      elsif attacker.pbHasType?(opponent.type1) &&
         attacker.pbHasType?(opponent.type2) &&
         opponent.pbHasType?(attacker.type1) &&
         opponent.pbHasType?(attacker.type2)
        score-=90
      end
    when 0x63 # Simple Beam
      if opponent.effects[PBEffects::Substitute]>0
        score-=90
        miniscore *= 0.3 if setup_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))}
      elsif skill>=PBTrainerAI.mediumSkill
        if abilities_to_avoid.any? { |ab| isConst?(opponent.ability, PBAbilities, ab)} || isConst?(opponent.ability,PBAbilities,:SIMPLE)
          score-=90
        end
      end
    when 0x64 # Worry Seed
      if opponent.effects[PBEffects::Substitute]>0
        score-=90
      end
      if abilities_to_avoid.any? { |ab| isConst?(opponent.ability, PBAbilities, ab)} || isConst?(opponent.ability,PBAbilities,:INSOMNIA)
        score-=90
      end
      score*=0.7 if sleep_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || attacker.hasWorkingAbility(:BADDREAMS)
    when 0x65 # Role Play
      score-=40 # don't prefer this move
      # Check if any of the conditions apply
      if opponent.ability == 0 ||
         attacker.ability == opponent.ability ||
         abilities_to_avoid.any? { |ab| isConst?(attacker.ability, PBAbilities, ab) } ||
         abilities_to_avoid.any? { |ab| isConst?(opponent.ability, PBAbilities, ab) }
        score -= 90
      end
      # Special abilities that affect the score
      if isConst?(opponent.ability, PBAbilities, :TRUANT) && attacker.pbIsOpposing?(opponent.index)
        score -= 90
      elsif isConst?(opponent.ability, PBAbilities, :SLOWSTART) && attacker.pbIsOpposing?(opponent.index)
        score -= 90
      end
    when 0x66  # Entrainment
      score-=40 # don't prefer this move
      score-=90 if opponent.effects[PBEffects::Substitute]>0
      # Apply penalty for matching any ability in the list
      if attacker.ability == 0 ||
         attacker.ability == opponent.ability ||
         abilities_to_avoid.any? { |ab| isConst?(attacker.ability, PBAbilities, ab) } ||
         abilities_to_avoid.any? { |ab| isConst?(opponent.ability, PBAbilities, ab) }
        score -= 90
      end
    
      # Specific abilities that increase score
      score += 200 if isConst?(attacker.ability, PBAbilities, :TRUANT) && attacker.pbIsOpposing?(opponent.index)
      score += 200 if isConst?(attacker.ability, PBAbilities, :WONDERGUARD)
      score += 25 if isConst?(attacker.ability, PBAbilities, :SPEEDBOOST)
      score += 30 if isConst?(opponent.ability, PBAbilities, :DEFEATIST)
      if isConst?(opponent.ability, PBAbilities, :SLOWSTART)
        score += 50
        score += 30 if attacker.pbIsOpposing?(opponent.index)
      end
    when 0x67 # Skill Swap
      score-=40 # don't prefer this move
      # Apply penalty if any of the conditions match
      if (attacker.ability == 0 && opponent.ability == 0) ||
         attacker.ability == opponent.ability ||
         abilities_to_avoid.any? { |ab| isConst?(attacker.ability, PBAbilities, ab)} ||
         abilities_to_avoid.any? { |ab| isConst?(opponent.ability, PBAbilities, ab)}
        score -= 90
      end
      # Apply penalty for specific opposing abilities at high skill level
      if skill >= PBTrainerAI.highSkill
        score -= 90 if isConst?(opponent.ability, PBAbilities, :TRUANT) && attacker.pbIsOpposing?(opponent.index)
        score -= 90 if isConst?(opponent.ability, PBAbilities, :SLOWSTART) && attacker.pbIsOpposing?(opponent.index)
      end
    when 0x68 # Gastro Acid
      if opponent.effects[PBEffects::Substitute]>0 ||
         opponent.effects[PBEffects::GastroAcid]
        score-=90
      elsif skill>=PBTrainerAI.highSkill
        score -= 90 if abilities_to_avoid.any? { |ab| isConst?(opponent.ability, PBAbilities, ab)}
      end
    when 0x69 # Transform
      score-=70
    when 0x6A # Sonicboom
      if opponent.hp<=20
        score+=80
      elsif opponent.level>=25
        score-=80 # Not useful against high-level Pokemon
      end
    when 0x6B # Dragon Rage
      score+=80 if opponent.hp<=40
    when 0x6C  # Super Fang
      score-=50
      score+=(opponent.hp*100/opponent.totalhp).floor
    when 0x6D # Seismic Toss
      score+=80 if opponent.hp<=attacker.level
    when 0x6E # Endeavor
      if attacker.hp>=opponent.hp
        score-=90
      elsif attacker.hp*2<opponent.hp
        score+=50
      end
    when 0x6F # Psywave
      score+=30 if opponent.hp<=attacker.level
    when 0x70 # Fissure
      score-=90 if opponent.hasWorkingAbility(:STURDY)
      score-=90 if opponent.level>attacker.level
    when 0x71 # Counter
      if opponent.effects[PBEffects::HyperBeam]>0
        score-=90
      else
        attack=pbRoughStat(attacker,PBStats::ATTACK,skill)
        spatk=pbRoughStat(attacker,PBStats::SPATK,skill)
        if attack*1.5<spatk
          score-=60
        elsif skill>=PBTrainerAI.mediumSkill &&
           opponent.lastMoveUsed>0
          moveData=PBMoveData.new(opponent.lastMoveUsed)
          if moveData.basedamage>0 &&
             (USEMOVECATEGORY && moveData.category==2) ||
             (!USEMOVECATEGORY && PBTypes.isSpecialType?(moveData.type))
            score-=60
          end
        end
      end
    when 0x72 # Mirror Coat
      if opponent.effects[PBEffects::HyperBeam]>0
        score-=90
      else
        attack=pbRoughStat(attacker,PBStats::ATTACK,skill)
        spatk=pbRoughStat(attacker,PBStats::SPATK,skill)
        if attack>spatk*1.5
          score-=60
        elsif skill>=PBTrainerAI.mediumSkill && opponent.lastMoveUsed>0
          moveData=PBMoveData.new(opponent.lastMoveUsed)
          if moveData.basedamage>0 &&
             (USEMOVECATEGORY && moveData.category==1) ||
             (!USEMOVECATEGORY && !PBTypes.isSpecialType?(moveData.type))
            score-=60
          end
        end
      end
      if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        score*=0.5
      end
      if (attacker.hasWorkingAbility(:STURDY) || attacker.hasWorkingItem(:FOCUSSASH)) && attacker.hp == attacker.totalhp
        score*=1.2
      else
        score*=0.8          
      end
      score*=0.7 if PBMoveData.new(attacker.lastMoveUsed).function==0x71
      miniscore = attacker.hp*(1.0/attacker.totalhp)
      score*=miniscore
      score*=0.3 if opponent.spatk<opponent.attack
      score*=1.1 if PBMoveData.new(attacker.lastMoveUsed).function==0x71
    when 0x73 # Metal Burst
      score-=90 if opponent.effects[PBEffects::HyperBeam]>0
    when 0x74 # Flame Burst 
      score+=10 if !opponent.pbPartner.isFainted?
    when 0x75 # Surf
    when 0x76 # Earthquake
    when 0x77 # Gust
    when 0x78 # Twister
      if skill>=PBTrainerAI.highSkill
        score+=30 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                     opponent.effects[PBEffects::Substitute]==0
      end
    when 0x79 # Fusion Bolt        
    when 0x7A # Fusion Flare
    when 0x7B # Venoshock
      score*=1.2 if attacker.status==PBStatuses::POISON
    when 0x7C # Smelling Salts
      if opponent.status==PBStatuses::PARALYSIS  && opponent.effects[PBEffects::Substitute]<=0 
        score*=0.8
        score*=0.5 if opponent.speed>attacker.speed && opponent.speed/2.0<attacker.speed
      end
    when 0x7D # Wake-Up Slap
      if opponent.status==PBStatuses::SLEEP && opponent.effects[PBEffects::Substitute]<=0
        score*=0.8
        if attacker.hasWorkingAbility(:BADDREAMS) || attacker.pbHasMove?(getID(PBMoves,:DREAMEATER)) || attacker.pbHasMove?(getID(PBMoves,:NIGHTMARE))
          score*=0.3
        end
        score*=1.3 if opponent.pbHasMove?(getID(PBMoves,:SNORE)) || opponent.pbHasMove?(getID(PBMoves,:SLEEPTALK))
      end        
    when 0x7E # Facade
      if [PBStatuses::POISON, PBStatuses::BURN, PBStatuses::SLEEP, PBStatuses::FROZEN, PBStatuses::PARALYSIS].include?(attacker.status)
        score *= 1.2
      end
      if attacker.hasWorkingAbility(:TOXICBOOST) && attacker.status==PBStatuses::POISON
        score*=1.2
      end
      score*=1.2 if attacker.hasWorkingAbility(:GUTS)
    when 0x7F # Hex
      if [PBStatuses::POISON, PBStatuses::BURN, PBStatuses::SLEEP, PBStatuses::FROZEN, PBStatuses::PARALYSIS].include?(opponent.status)
        score *= 1.2
      end
    when 0x80 # Brine
    when 0x81 # Revenge
      attspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
      oppspeed=pbRoughStat(opponent,PBStats::SPEED,skill)
      score+=30 if oppspeed>attspeed
    when 0x82 # Assurance
      score+=20 if @doublebattle
      if (pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed) ^ (@trickroom!=0)
          score*=1.5
      end        
    when 0x83 # Round
      if skill>=PBTrainerAI.mediumSkill
        score+=20 if @doublebattle && !attacker.pbPartner.isFainted? &&
                     attacker.pbPartner.pbHasMove?(move.id)
      end
    when 0x84
      attspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
      oppspeed=pbRoughStat(opponent,PBStats::SPEED,skill)
      score+=30 if oppspeed>attspeed
    when 0x85 # Retaliate 
    when 0x86 # Acrobatics
    when 0x87 # Weather Ball
    when 0x88 # Pursuit
      miniscore = 0
      miniscore+=opponent.stages[PBStats::ATTACK] if opponent.stages[PBStats::ATTACK]<0
      miniscore+=opponent.stages[PBStats::DEFENSE] if opponent.stages[PBStats::DEFENSE]<0
      miniscore+=opponent.stages[PBStats::SPEED] if opponent.stages[PBStats::SPEED]<0
      miniscore+=opponent.stages[PBStats::SPATK] if opponent.stages[PBStats::SPATK]<0
      miniscore+=opponent.stages[PBStats::SPDEF] if opponent.stages[PBStats::SPDEF]<0
      miniscore+=opponent.stages[PBStats::EVASION] if opponent.stages[PBStats::EVASION]<0
      miniscore+=opponent.stages[PBStats::ACCURACY] if opponent.stages[PBStats::ACCURACY]<0
      miniscore*=(-10)
      miniscore+=100
      miniscore/=100.0
      score*=miniscore

      score*=1.2 if opponent.effects[PBEffects::Confusion]>0
      score*=1.5 if opponent.effects[PBEffects::LeechSeed]>=0
      score*=1.3 if opponent.effects[PBEffects::Attract]>=0
      score*=0.7 if opponent.effects[PBEffects::Substitute]>0
      score*=1.5 if opponent.effects[PBEffects::Yawn]>0
    when 0x89 # Return
    when 0x8A # Frustration
    when 0x8B # Water Spout
      score*=0.5 if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
    when 0x8C # Crush Grip
    when 0x8D # Gyro Ball
    when 0x8E # Stored Power
    when 0x8F # Punishment
    when 0x90 # Hidden Power
    when 0x91 # Fury Cutter
      score*=0.7 if attacker.status==PBStatuses::PARALYSIS 
      score*=0.7 if attacker.effects[PBEffects::Confusion]>0
      score*=0.7 if attacker.effects[PBEffects::Attract]>=0
      if attacker.stages[PBStats::ACCURACY]<0
        ministat = attacker.stages[PBStats::ACCURACY]
        minimini = 15 * ministat
        minimini += 100
        minimini /= 100.0
        score*=minimini
      end
      miniscore = opponent.stages[PBStats::EVASION]
      miniscore*=(-5)
      miniscore+=100
      miniscore/=100.0
      score*=miniscore
      score*=1.3 if attacker.hp==attacker.totalhp
    when 0x92 # Echoed Voice
      score*=0.7 if attacker.status==PBStatuses::PARALYSIS 
      score*=0.7 if attacker.effects[PBEffects::Confusion]>0
      score*=0.7 if attacker.effects[PBEffects::Attract]>=0
      if attacker.stages[PBStats::ACCURACY]<0
        ministat = attacker.stages[PBStats::ACCURACY]
        minimini = 15 * ministat
        minimini += 100
        minimini /= 100.0
        score*=minimini
      end
      miniscore = opponent.stages[PBStats::EVASION]
      miniscore*=(-5)
      miniscore+=100
      miniscore/=100.0
      score*=miniscore
      score*=1.3 if attacker.hp==attacker.totalhp
    when 0x93 # Rage
      score+=25 if attacker.effects[PBEffects::Rage]
      score*=1.2 if attacker.attack>attacker.spatk
      score*=1.3 if attacker.hp==attacker.totalhp
    when 0x94 # Present 
      score*=1.2 if opponent.hp==opponent.totalhp
    when 0x95 # Magnitude
    when 0x96 # Natural Gift 
      if !pbIsBerry?(attacker.item) || attacker.hasWorkingAbility(:KLUTZ) || 
         @field.effects[PBEffects::MagicRoom]>0 || attacker.effects[PBEffects::Embargo]>0 || 
         opponent.hasWorkingAbility(:UNNVERVE)
        score*=0
      end        
    when 0x97 # Trump Card
      score*=1.2 if attacker.hp==attacker.totalhp
    when 0x98 # Reversal
      if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        score*=1.1
        score*1.3 if attacker.hp<attacker.totalhp
      end
    when 0x99 # Electro Ball
    when 0x9A # Low Kick
    when 0x9B # Heat Crash
    when 0x9C # Helping Hand      
      if @doublebattle || attacker.pbPartner.isFainted?
        effvar = false
        score*=2 if !effvar
        if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && ((attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
          score*=1.2
          score*=1.5 if attacker.hp*(1.0/attacker.totalhp) < 0.33
          if attacker.pbPartner.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) && attacker.pbPartner.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)
            score*=1.5
          end
        end
        ministat = [attacker.pbPartner.attack,attacker.pbPartner.spatk].max
        minimini = [attacker.attack,attacker.spatk].max
        ministat-=minimini
        ministat+=100
        ministat/=100.0
        score*=ministat
        
        if attacker.pbHasMove?(getID(PBMoves,:RAINDANCE)) && 
          (!pbWeather==PBWeather::RAINDANCE ||
          !pbCheckGlobalAbility(:AIRLOCK) ||
          !pbCheckGlobalAbility(:CLOUDNINE) ||
          !pbCheckGlobalAbility(:DELTASTREAM) ||
          !pbCheckGlobalAbility(:DESOLATELAND) ||
          !pbCheckGlobalAbility(:PRIMORDIALSEA))
          score*=0.5
        end
        
        if attacker.pbPartner.pbHasMove?(getID(PBMoves,:TAILWIND)) && attacker.pbOwnSide.effects[PBEffects::Tailwind]<=0
          score*=0.5
        end

        score*=0.3 if attacker.pbPartner.hp<=attacker.pbPartner.totalhp/2
        score*=0.5 if attacker.pbPartner.hp<=attacker.pbPartner.totalhp/4
      else
        score*=0
      end
      
    when 0x9D # Mud Sport
      if attacker.effects[PBEffects::MudSport]
        score-=90
      else
        if opponent.pbHasMoveType?(:ELECTRIC)
          score*=1.5
        else
          score-=90
        end
      end
    when 0x9E # Water Sport
      if attacker.effects[PBEffects::WaterSport]
        score-=90
      else
        if opponent.pbHasMoveType?(:FIRE)
          score*=1.5
        else
          score-=90
        end
      end
    when 0x9F # Judgement
      move.type = move.pbType(move.type,attacker,opponent)
    when 0xA0 # Frost Breath
      thisinitial = score
      if !opponent.hasWorkingAbility(:BATTLEARMOR) && !opponent.hasWorkingAbility(:SHELLARMOR) && !attacker.effects[PBEffects::LaserFocus]
        miniscore = 100
        ministat = 0
        ministat += opponent.stages[PBStats::DEFENSE] if opponent.stages[PBStats::DEFENSE]>0
        ministat += opponent.stages[PBStats::SPDEF] if opponent.stages[PBStats::SPDEF]>0
        miniscore += 10*ministat
        ministat = 0
        ministat -= attacker.stages[PBStats::ATTACK] if attacker.stages[PBStats::ATTACK]<0
        ministat -= attacker.stages[PBStats::SPATK] if attacker.stages[PBStats::SPATK]<0
        miniscore += 10*ministat
        miniscore -= 10*attacker.effects[PBEffects::FocusEnergy] if attacker.effects[PBEffects::FocusEnergy]>0
        miniscore/=100.0
        score*=miniscore
        if opponent.hasWorkingAbility(:ANGERPOINT) && thisinitial<100
          score*=0.7
          score*=0.2 if opponent.attack>opponent.spatk
        end
      else
        score*=0.7
      end
    when 0xA1 # Lucky Chant
      if attacker.pbOwnSide.effects[PBEffects::LuckyChant]==0  && 
         !attacker.hasWorkingAbility(:BATTLEARMOR) || 
         !attacker.hasWorkingAbility(:SHELLARMOR) && 
         (opponent.effects[PBEffects::FocusEnergy]>1 || 
         opponent.effects[PBEffects::LaserFocus])
        score+=20
      end        
    when 0xA2 # Reflect
      if attacker.pbOwnSide.effects[PBEffects::Reflect]<=0
        score*=1.2        
        score*=0.5 if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          score*=1.3
        end
        score*=1.5 if attacker.hasWorkingItem(:LIGHTCLAY)
        score*=1.2 if attacker.pbOwnSide.effects[PBEffects::LightScreen]<=0
      else
        score-=90
      end
    when 0xA3 # Light Screen 
      if attacker.pbOwnSide.effects[PBEffects::LightScreen]<=0
        score*=1.2
        score*=0.5 if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
        if pbRoughStat(opponent,PBStats::ATTACK,skill)<pbRoughStat(opponent,PBStats::SPATK,skill)
          score*=1.3
        end
        score*=1.5 if attacker.hasWorkingItem(:LIGHTCLAY)
        score*=1.2 if attacker.pbOwnSide.effects[PBEffects::Reflect]<=0
      else
        score-=90
      end
    when 0xCF6 # Aurora Veil
        if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]<=0
          if pbWeather==PBWeather::HAIL
            score*=1.5
            score*=0.1 if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
            score*=1.5 if attacker.hasWorkingItem(:LIGHTCLAY)
          else
            score-=90
          end
        else
          score-=90
        end
    when 0xA4 # Secret Power
      score*=1.2
    when 0xA5 # Never Miss
        score*=1.05 if score==110
        if !attacker.hasWorkingAbility(:NOGUARD) && !opponent.hasWorkingAbility(:NOGUARD)
          if attacker.stages[PBStats::ACCURACY]<0
            miniscore = (-5)*attacker.stages[PBStats::ACCURACY]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if opponent.stages[PBStats::EVASION]>0
            miniscore = (5)*opponent.stages[PBStats::EVASION]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if opponent.hasWorkingItem(:LAXINCENSE) || opponent.hasWorkingItem(:BRIGHTPOWDER)
            score*=1.2
          end
          if (opponent.hasWorkingAbility(:SANDVEIL) && pbWeather==PBWeather::SANDSTORM) || 
             (opponent.hasWorkingAbility(:SNOWCLOAK) && (pbWeather==PBWeather::HAIL))
            score*=1.3
          end
        end
    when 0xA6 # Lock On
      score-=90 if opponent.effects[PBEffects::Substitute]>0
      score-=90 if opponent.effects[PBEffects::LockOn]>0
    when 0xA7 # Foresight
      if opponent.effects[PBEffects::Foresight]
        score-=90
      elsif !opponent.pbHasType?(:GHOST)
        score-=90
      elsif opponent.pbHasType?(:GHOST)
        score+=90
      elsif opponent.stages[PBStats::EVASION]<=0
        score-=80
      end
    when 0xA8 # Miracle Eye
      if opponent.effects[PBEffects::MiracleEye]
        score-=90
      elsif !opponent.pbHasType?(:DARK)
        score-=90
      elsif opponent.stages[PBStats::EVASION]<=0
        score-=80
      end
    when 0xA9 # Chip Away
        ministat = 0
        ministat+=opponent.stages[PBStats::EVASION] if opponent.stages[PBStats::EVASION]>0
        ministat+=opponent.stages[PBStats::DEFENSE] if opponent.stages[PBStats::DEFENSE]>0
        ministat+=opponent.stages[PBStats::SPDEF]   if opponent.stages[PBStats::SPDEF]>0
        ministat*=5
        ministat+=100
        ministat/=100.0
        score*=ministat
    when 0xAA, 0x14B, 0x14C, 0x15B,  0x184, 0x257, 0x268# Protect
      score*=0.3 if setup_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov)) }
      if attacker.hasWorkingItem(:LEFTOVERS) || 
        (attacker.hasWorkingItem(:BLACKSLUDGE) && attacker.pbHasType?(:POISON)) || 
        attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing]
        score*=1.2
      end
      if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||  
         opponent.effects[PBEffects::LeechSeed]>=0
        score*=1.3
      end
      score*=2 if opponent.effects[PBEffects::PerishSong]!=0
      score*=0.2 if opponent.status==PBStatuses::SLEEP
      score*=0.2 if opponent.status==PBStatuses::FROZEN && !FROSTBITE_REPLACES_FREEZE
      if attacker.effects[PBEffects::ProtectRate]>1 ||
         opponent.effects[PBEffects::HyperBeam]>0
        score-=90
      else
          score-=(attacker.effects[PBEffects::ProtectRate]*40)
        score+=50 if attacker.turncount==0
        score+=30 if opponent.effects[PBEffects::TwoTurnAttack]!=0
      end
    when 0xAB # Quick Guard
      if (opponent.hasWorkingAbility(:GALEWINGS) && opponent.hp == opponent.totalhp) || 
         (opponent.hasWorkingAbility(:PRANKSTER) && attacker.pbHasType?(:DARK))
         score*=2
      else
         score*=0
      end                    
      if attacker.effects[PBEffects::ProtectRate]>1 ||
        opponent.effects[PBEffects::HyperBeam]>0
        score-=90
      end
    when 0xAC # Wide Guard
      if attacker.effects[PBEffects::ProtectRate]>1 ||
        opponent.effects[PBEffects::HyperBeam]>0
        score-=90
      end
    when 0xAD # Feint
      if opponent.pbHasMove?(getID(PBMoves,:PROTECT)) ||
         opponent.pbHasMove?(getID(PBMoves,:DETECT))  ||
         opponent.pbHasMove?(getID(PBMoves,:BANEFULBUNKER))  ||
         opponent.pbHasMove?(getID(PBMoves,:SPIKYSHIELD)) ||
         opponent.pbHasMove?(getID(PBMoves,:KINGSSHIELD))
         score*=1.2
      end 
    when 0xAE # Mirror Move
      if skill>=PBTrainerAI.highSkill
        score-=100 if opponent.lastMoveUsed<=0 ||
                     (PBMoveData.new(opponent.lastMoveUsed).flags&0x10)==0 # flag e: Copyable by Mirror Move
      end
      if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        score*=0.5
      end
    when 0xAF # Copycat
      if skill>=PBTrainerAI.highSkill
        score-=100 if opponent.lastMoveUsed<=0 ||
                     (PBMoveData.new(opponent.lastMoveUsed).flags&0x10)==0 # flag e: Copyable by Mirror Move
      end
      if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        score*=0.5
      end
    when 0xB0
    when 0xB1
    when 0xB2
    when 0xB3
    when 0xB4 # Sleep Talk
      if attacker.status==PBStatuses::SLEEP
        score+=200 # Because it can be used while asleep
      else
        score-=80
      end
    when 0xB5 # Assist
    when 0xB6 # Metronome
    when 0xB7
      score-=90 if opponent.effects[PBEffects::Torment]
    when 0xB8
      score-=90 if attacker.effects[PBEffects::Imprison]
    when 0xB9
      score-=90 if opponent.effects[PBEffects::Disable]>0 
    when 0xBA
      score-=90 if opponent.effects[PBEffects::Taunt]>0
    when 0xBB
      score-=90 if opponent.effects[PBEffects::HealBlock]>0
    when 0xBC
      aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
      ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
      if opponent.effects[PBEffects::Encore]>0
        score-=90
      elsif aspeed>ospeed
        if opponent.lastMoveUsed<=0
          score-=90
        else
          moveData=PBMoveData.new(opponent.lastMoveUsed)
          if moveData.basedamage==0 && (moveData.target==0x10 || moveData.target==0x20)
            score+=60
          elsif moveData.basedamage!=0 && moveData.target==0x00 &&
             pbTypeModifier(moveData.type,opponent,attacker)==0
            score+=60
          end
        end
      end
    when 0xBD
    when 0xBF
    when 0xC0
    when 0xC1
    when 0xC2
    when 0xC3
    when 0xC4
    when 0xC7
      score+=20 if attacker.effects[PBEffects::FocusEnergy]>0
      if skill>=PBTrainerAI.highSkill
        score+=20 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                     opponent.effects[PBEffects::Substitute]==0
      end
    when 0xC9
    when 0xCA
    when 0xCB
    when 0xCC
    when 0xCD
    when 0xCE
    when 0xCF, 0x276, 0x246, 0xD0 # Multiturn
      if opponent.effects[PBEffects::MultiTurn] == 0 && opponent.effects[PBEffects::Substitute] <= 0
        score *= 1.2
      
        ministat = [PBStats::ATTACK, PBStats::SPATK, PBStats::SPEED, PBStats::DEFENSE, PBStats::SPDEF].inject(0) do |sum, stat|
          sum + (opponent.stages[stat] > 0 ? opponent.stages[stat] : 0)
        end
        ministat = ((-5 * ministat) + 100) / 100.0
        score *= ministat
        if opponent.hp == opponent.totalhp
          score *= 1.2
        elsif opponent.hp * 2 < opponent.totalhp
          score *= 0.8
        end
        score *= 0.7 if attacker.hp * 3 < attacker.totalhp
        score *= 1.5 if opponent.effects[PBEffects::LeechSeed] >= 0
        score *= 1.3 if opponent.effects[PBEffects::Attract] > -1
        score *= 1.3 if opponent.effects[PBEffects::Confusion] > 0
        score *= 1.3 if attacker.hasWorkingItem(:BINDINGBAND)
        score *= 1.1 if attacker.hasWorkingItem(:GRIPCLAW)
      end
    when 0xD1
    when 0xD2
    when 0xD3 #Desenrollar
      score+=50
    when 0xD4 # Bide
      if attacker.hp<=attacker.totalhp/4
        score-=90 
      elsif attacker.hp<=attacker.totalhp/2
        score-=50 
      end
    when 0xD5, 0xD6, 182 # Recover
      if attacker.hp==attacker.totalhp
        score=0
      else
        score+=50
        score-=(attacker.hp*100/attacker.totalhp)
      end
      score*=0.3 if setup_moves.any? { |mov| opponent.pbHasMove?(getID(PBMoves, mov))}
      score*=1.2 if lowerUser_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))}
      score*=1.2 if setup_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))}
      if attacker.hp/attacker.totalhp<0.5
        score*=1.5
        score*=2 if attacker.effects[PBEffects::Curse]
        if attacker.hp*4<attacker.totalhp
          score*=1.5 if attacker.status==PBStatuses::POISON
          score*=2 if attacker.effects[PBEffects::LeechSeed]>=0
          if attacker.hp<attacker.totalhp*0.13
            score*=2 if attacker.status==PBStatuses::BURN
            if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) || 
               (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
              score*=2
            end  
          end            
        end          
      else
        score*=0.7
      end  
      if attacker.effects[PBEffects::Toxic]>0
        score*=0.5
        score*=0.5 if attacker.effects[PBEffects::Toxic]>4
      end
      if attacker.status==PBStatuses::PARALYSIS || attacker.effects[PBEffects::Attract]>=0 || attacker.effects[PBEffects::Confusion]>0
        score*=1.1
      end        
      if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN || opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
        score*=1.3
        score*=1.3 if opponent.effects[PBEffects::Toxic]>0
      end
      score=0 if attacker.effects[PBEffects::Wish]>0
    when 0xD7
      score-=90 if attacker.effects[PBEffects::Wish]>0
    when 0xD8
      if attacker.hp==attacker.totalhp
        score-=90
      else
        case pbWeather
        when PBWeather::SUNNYDAY
          score+=30
        when PBWeather::RAINDANCE, PBWeather::SANDSTORM, PBWeather::HAIL
          score-=30
        end
        score+=50
        score-=(attacker.hp*100/attacker.totalhp)
      end
    when 0xD9
      if attacker.hp==attacker.totalhp || !attacker.pbCanSleep?(attacker,false,nil,true)
        score-=90
      else
        score+=70
        score-=(attacker.hp*140/attacker.totalhp)
        score+=30 if attacker.status!=0
      end
    when 0xDA
      score-=90 if attacker.effects[PBEffects::AquaRing]
    when 0xDB
      score-=90 if attacker.effects[PBEffects::Ingrain]
    when 0xDC # Leech Seed
      if opponent.effects[PBEffects::LeechSeed]>=0
        score-=90
      elsif skill>=PBTrainerAI.mediumSkill && opponent.pbHasType?(:GRASS)
        score-=90
      else
        score+=60 if attacker.turncount==0
      end
    when 0xDD
      if skill>=PBTrainerAI.highSkill && opponent.hasWorkingAbility(:LIQUIDOOZE)
        score-=70
      else
        score+=20 if attacker.hp<=(attacker.totalhp/2)
      end
    when 0xDE
      if opponent.status!=PBStatuses::SLEEP
        score-=100
      elsif skill>=PBTrainerAI.highSkill && opponent.hasWorkingAbility(:LIQUIDOOZE)
        score-=70
      else
        score+=20 if attacker.hp<=(attacker.totalhp/2)
      end
    when 0xDF
      if attacker.pbIsOpposing?(opponent.index)
        score-=100
      else
        score+=20 if opponent.hp<(opponent.totalhp/2) &&
                     opponent.effects[PBEffects::Substitute]==0
      end
    when 0xE0
      reserves=attacker.pbNonActivePokemonCount
      foes=attacker.pbOppositeOpposing.pbNonActivePokemonCount

      #score-=(attacker.hp*100/attacker.totalhp)
      score*=0.7
      if attacker.hp==attacker.totalhp
        score*=0.2
      else
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        miniscore = 1-miniscore
        score*=miniscore
        if attacker.hp*4<attacker.totalhp            
          score*=1.3
          score*=1.4 if attacker.hasWorkingItem(:CUSTAPBERRY)
        end
      end

      if opponent.hasWorkingAbility(:DISGUISE) || opponent.effects[PBEffects::Substitute]>0
        score*=0.3
      end
      score = 0 if pbCheckGlobalAbility(:DAMP)
      if reserves==0 && foes>0
        score = 0 
      elsif reserves==0 && foes==0
        score = 0 
      end

    when 0xE1
    when 0xE2
      if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker) &&
         !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker)
        score-=100
      elsif attacker.pbNonActivePokemonCount()==0
        score-=100 
      else
        score+=(opponent.stages[PBStats::ATTACK]*10)
        score+=(opponent.stages[PBStats::SPATK]*10)
        score-=(attacker.hp*100/attacker.totalhp)
      end
    when 0xE3, 0xE4 #Lunar Dance
      if isConst?(attacker.species,PBSpecies,:BLISSEY)
        score+=100
      else
        score-=70
      end
    when 0xE5
      if attacker.pbNonActivePokemonCount()==0
        score-=90
      else
        score-=90 if opponent.effects[PBEffects::PerishSong]>0
      end
       
    when 0xE6
      score+=50
      score-=(attacker.hp*100/attacker.totalhp)
      score+=30 if attacker.hp<=(attacker.totalhp/10)
    when 0xE7
      score+=50
      score-=(attacker.hp*100/attacker.totalhp)
      score+=30 if attacker.hp<=(attacker.totalhp/10)
    when 0xE8
      score-=25 if attacker.hp>(attacker.totalhp/2)
      if skill>=PBTrainerAI.mediumSkill
        score-=90 if attacker.effects[PBEffects::ProtectRate]>1
        score-=90 if opponent.effects[PBEffects::HyperBeam]>0
      else
        score-=(attacker.effects[PBEffects::ProtectRate]*40)
      end
    when 0xE9
      if opponent.hp==1
        score-=90
      elsif opponent.hp<=(opponent.totalhp/8)
        score-=60
      elsif opponent.hp<=(opponent.totalhp/4)
        score-=30
      end
    when 0xEA
      score-=100 if @opponent
    when 0xEB
      if opponent.effects[PBEffects::Ingrain] ||
         (skill>=PBTrainerAI.highSkill && opponent.hasWorkingAbility(:SUCTIONCUPS))
        score-=90 
      else
        party=pbParty(opponent.index)
        ch=0
        for i in 0...party.length
          ch+=1 if pbCanSwitchLax?(opponent.index,i,false)
        end
        score-=90 if ch==0
      end
      if score>20
        score+=50 if opponent.pbOwnSide.effects[PBEffects::Spikes]>0
        score+=50 if opponent.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
        score+=50 if opponent.pbOwnSide.effects[PBEffects::StealthRock]
      end
    when 0xEC
      if !opponent.effects[PBEffects::Ingrain] &&
         !(skill>=PBTrainerAI.highSkill && opponent.hasWorkingAbility(:SUCTIONCUPS))
        score+=40 if opponent.pbOwnSide.effects[PBEffects::Spikes]>0
        score+=40 if opponent.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
        score+=40 if opponent.pbOwnSide.effects[PBEffects::StealthRock]
      end
    when 0xED # Baton Pass
      if !pbCanChooseNonActive?(attacker.index)
        score-=80
      else
        score-=40 if attacker.effects[PBEffects::Confusion]>0
        total=0
        total+=(attacker.stages[PBStats::ATTACK]*10)
        total+=(attacker.stages[PBStats::DEFENSE]*10)
        total+=(attacker.stages[PBStats::SPEED]*10)
        total+=(attacker.stages[PBStats::SPATK]*10)
        total+=(attacker.stages[PBStats::SPDEF]*10)
        total+=(attacker.stages[PBStats::EVASION]*10)
        total+=(attacker.stages[PBStats::ACCURACY]*10)
        if total<=0 || attacker.turncount==0
          score-=60
        else
          score+=total
          # special case: attacker has no damaging moves
          hasDamagingMove=false
          for m in attacker.moves
            if move.id!=0 && move.basedamage>0
              hasDamagingMove=true
            end
          end
          if !hasDamagingMove
            score+=75
          end
        end
      end
    when 0xEE # U-Turn / Volt Switch
      livecount=0
      for i in pbParty(attacker.index)
        next if i.nil?
        livecount+=1 if i.hp!=0
      end
      if livecount>1
        score*=0.7 if attacker.pbOwnSide.effects[PBEffects::StealthRock]
        score*=0.6 if attacker.pbOwnSide.effects[PBEffects::StickyWeb]

        if attacker.pbOwnSide.effects[PBEffects::Spikes]>0
          score*=0.9**attacker.pbOwnSide.effects[PBEffects::Spikes]
        end
        if attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
          score*=0.9**attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.1
        end
        if attacker.hasWorkingAbility(:REGENERATOR)
          hp_ratio = (attacker.hp.to_f) / attacker.totalhp
          score *= 1.2 if hp_ratio < 0.75
          score *= 1.2 if hp_ratio < 0.5
        end
        loweredstats = [
          PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPEED, PBStats::SPATK,
          PBStats::SPDEF, PBStats::EVASION
        ].select { |stat| attacker.stages[stat] < 0 }.inject(0) { |sum, stat| sum + attacker.stages[stat] }
      
        miniscore = (loweredstats * -15 + 100) / 100.0
        score *= miniscore
        raisedstats = [
          PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPEED, PBStats::SPATK,
          PBStats::SPDEF, PBStats::EVASION
        ].select { |stat| attacker.stages[stat] > 0 }.inject(0) { |sum, stat| sum + attacker.stages[stat] }
      
        miniscore = (raisedstats * -25 + 100) / 100.0
        score *= miniscore
        if attacker.effects[PBEffects::Toxic]>0 || attacker.effects[PBEffects::Attract]>-1 || attacker.effects[PBEffects::Confusion]>0
          score*=1.3
        end
        score*=1.5 if attacker.effects[PBEffects::LeechSeed]>-1
      end
    when 0xEF # Mean Look
      if !(opponent.effects[PBEffects::MeanLook]>=0 || opponent.effects[PBEffects::Ingrain] || opponent.pbHasType?(:GHOST)) && opponent.effects[PBEffects::Substitute]<=0
        score*=4 if opponent.effects[PBEffects::PerishSong]>0
        if attacker.hasWorkingAbility(:ARENATRAP) || 
          attacker.hasWorkingAbility(:SHADOWTAG)
          score*=0
        end
        if opponent.effects[PBEffects::Attract]>=0 || 
           opponent.effects[PBEffects::LeechSeed]>=0
          score*=1.3
        end
        score*=1.5 if opponent.effects[PBEffects::Curse]
        if attacker.pbHasMove?(getID(PBMoves,:WHIRLWIND)) || 
          attacker.pbHasMove?(getID(PBMoves,:ROAR)) || 
          attacker.pbHasMove?(getID(PBMoves,:DRAGONTAIL)) || 
          attacker.pbHasMove?(getID(PBMoves,:CIRCLETHROW)) 
          score*=0.7
        end
        if opponent.pbHasMove?(getID(PBMoves,:UTURN)) || 
          opponent.pbHasMove?(getID(PBMoves,:VOLTSWITCH)) ||
          opponent.pbHasMove?(getID(PBMoves,:FLIPTURN))
          score*=0.7
        end
        score*=0.1 if opponent.hasWorkingAbility(:RUNAWAY)
        score*=1.5 if attacker.pbHasMove?(getID(PBMoves,:PERISHSONG))
      else
        score-=90
      end

    when 0xF0 # Knock Off
      if (!opponent.hasWorkingAbility(:STICKYHOLD) || opponent.moldbroken) &&
        opponent.item!=0 && !pbIsUnlosableItem(opponent,opponent.item)
        score*=1.1
        if opponent.hasWorkingItem(:LEFTOVERS) || (opponent.hasWorkingItem(:BLACKSLUDGE) && opponent.pbHasType?(:POISON))
          score*=1.2
        end    
        if opponent.hasWorkingItem(:LIFEORB) || opponent.hasWorkingItem(:CHOICESCARF) ||
          opponent.hasWorkingItem(:CHOICEBAND) || opponent.hasWorkingItem(:CHOICESPECS) ||
          opponent.hasWorkingItem(:ASSAULTVEST) 
          score*=1.1
        else
          score+=20 if opponent.item!=0
        end
      end
    when 0xF1 # Covet
      if skill>=PBTrainerAI.highSkill
        if attacker.item==0 && opponent.item!=0
          score+=40
        else
          score-=90
        end
      else
        score-=80
      end
    when 0xF2 # Trick
      if attacker.item==0 && opponent.item==0
        score-=90
      elsif skill>=PBTrainerAI.highSkill && opponent.hasWorkingAbility(:STICKYHOLD)
        score-=90
      elsif bad_items.any? { |item| attacker.hasWorkingItem(item)}
        score+=50  
      elsif attacker.item==0 && opponent.item!=0
        score-=30 if PBMoveData.new(attacker.lastMoveUsed).function==0xF2 # Trick/Switcheroo
      end
    when 0xF3 # Bestow
      if attacker.item==0 || opponent.item!=0
        score-=90
      else
        if bad_items.any? { |item| attacker.hasWorkingItem(item)}
          score+=50
        else
          score-=80
        end
      end
    when 0xF4, 0xF5 # Incinerate, Bug Bite
      if opponent.effects[PBEffects::Substitute]==0 && pbIsBerry?(opponent.item)
        score+=50
        case opponent.item
        when getID(PBItems,:LUMBERRY)
          score*=2 if attacker.stats!=0
        when getID(PBItems,:SITRUSBERRY)
          score*=1.6 if attacker.hp*(1.0/attacker.totalhp)<0.66
        when getID(PBItems,:LIECHIBERRY)
          score*=1.5 if attacker.attack>attacker.spatk
        when getID(PBItems,:PETAYABERRY)
          score*=1.5 if attacker.spatk>attacker.attack
        when getID(PBItems,:CUSTAPBERRY), getID(PBItems,:SALACBERRY)
          score*=1.1
          score*=1.4 if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
        end
      end        
    when 0xF6 # Recycle
      if attacker.pokemon.itemRecycle!=0
        score*=2
        case attacker.pokemon.itemRecycle
          when getID(PBItems,:LUMBERRY)
            score*=2 if attacker.stats!=0
          when getID(PBItems,:SITRUSBERRY)
            score*=1.6 if attacker.hp*(1.0/attacker.totalhp)<0.66
        end
        if pbIsBerry?(attacker.pokemon.itemRecycle) 
          score*=0 if opponent.hasWorkingAbility(:UNNERVE)
        end
        score*=0 if opponent.hasWorkingAbility(:MAGICIAN)
        if attacker.hasWorkingAbility(:UNBURDEN) || attacker.hasWorkingAbility(:HARVEST) || attacker.pbHasMove?(getID(PBMoves,:ACROBATICS))
          score*=0
        end
      else
        score*=0
      end
    when 0xF7 # Fling
      if attacker.item==0 ||
         pbIsUnlosableItem(attacker,attacker.item) ||
         pbIsPokeBall?(attacker.item) ||
         attacker.hasWorkingAbility(:KLUTZ) ||
         attacker.effects[PBEffects::Embargo]>0
        score-=90
      end
    when 0xF8 # Embargo
      startscore = score
      if opponent.effects[PBEffects::Embargo]>0  && opponent.effects[PBEffects::Substitute]>0
        score*=0
      else
        if opponent.item!=0
          score*=1.1
          score*=1.1 if pbIsBerry?(opponent.item)
          case opponent.item
            when getID(PBItems,:LAXINCENSE), getID(PBItems,:EXPERTBELT), getID(PBItems,:MUSCLEBAND), getID(PBItems,:WISEGLASSES), getID(PBItems,:LIFEORB), getID(PBItems,:EVIOLITE), getID(PBItems,:ASSAULTVEST)
              score*=1.2
            when getID(PBItems,:LEFTOVERS), getID(PBItems,:BLACKSLUDGE)
              score*=1.3
          end
          score*=1.4 if opponent.hp*2<opponent.totalhp
        end
        score*=0 if score==startscore
      end        
    when 0xF9 # Magic Room
      if @field.effects[PBEffects::MagicRoom]>0
        score*=0
      else
        if opponent.item!=0
          score*=1.1
          score*=1.1 if pbIsBerry?(opponent.item)
          case opponent.item
          when getID(PBItems,:LAXINCENSE), getID(PBItems,:EXPERTBELT), getID(PBItems,:MUSCLEBAND), getID(PBItems,:WISEGLASSES), getID(PBItems,:LIFEORB), getID(PBItems,:EVIOLITE), getID(PBItems,:ASSAULTVEST)
            score*=1.2
          when getID(PBItems,:LEFTOVERS), getID(PBItems,:BLACKSLUDGE)
            score*=1.3
          end
        end
        if attacker.item!=0
          score*=0.8
          score*=0.8 if pbIsBerry?(opponent.item)
          case opponent.item
          when getID(PBItems,:LAXINCENSE), getID(PBItems,:EXPERTBELT), getID(PBItems,:MUSCLEBAND), getID(PBItems,:WISEGLASSES), getID(PBItems,:LIFEORB), getID(PBItems,:EVIOLITE), getID(PBItems,:ASSAULTVEST)
            score*=0.6
          when getID(PBItems,:LEFTOVERS), getID(PBItems,:BLACKSLUDGE)
            score*=0.4
          end
        end
      end 
    when 0xFA, 0xFB, 0xFC # Take Down, Wood Hammer, Head Smash
      if !attacker.hasWorkingAbility(:ROCKHEAD) || !attacker.hasWorkingAbility(:RECKLESS)
        score*=0.9
        if attacker.hp==attacker.totalhp && (attacker.hasWorkingAbility(:STURDY) || attacker.hasWorkingItem(:FOCUSSASH))
          score*=0.7
        end
        if attacker.hp*(1.0/attacker.totalhp)>0.1 && attacker.hp*(1.0/attacker.totalhp)<0.4
          score*=0.8
        end
      end
    when 0xFD # Volt Tackle
      if !attacker.hasWorkingAbility(:ROCKHEAD) || !attacker.hasWorkingAbility(:RECKLESS)
        score*=0.9
      if attacker.hp==attacker.totalhp && (attacker.hasWorkingAbility(:STURDY) || attacker.hasWorkingItem(:FOCUSSASH))
          score*=0.7
        end
        if attacker.hp*(1.0/attacker.totalhp)>0.2 && attacker.hp*(1.0/attacker.totalhp)<0.4
          score*=0.8
        end          
      end
      if opponent.pbCanParalyze?(attacker,false)
        score+=30
        if skill>=PBTrainerAI.mediumSkill
           aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
           ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          if aspeed<ospeed
            score+=30
          elsif aspeed>ospeed
            score-=40
          end
        end
        if skill>=PBTrainerAI.highSkill
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:QUICKFEET)
        end
      end
    when 0xFE # Flare Blitz
      #score-=30
      if !attacker.hasWorkingAbility(:ROCKHEAD) || !attacker.hasWorkingAbility(:RECKLESS)
        score*=0.9
      if attacker.hp==attacker.totalhp && (attacker.hasWorkingAbility(:STURDY) || attacker.hasWorkingItem(:FOCUSSASH))
          score*=0.7
        end
        if attacker.hp*(1.0/attacker.totalhp)>0.2 && attacker.hp*(1.0/attacker.totalhp)<0.4
          score*=0.8
        end          
      end
      if opponent.pbCanBurn?(attacker,false)
        score+=30
        if skill>=PBTrainerAI.highSkill
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:QUICKFEET)
          score-=40 if opponent.hasWorkingAbility(:FLAREBOOST)
        end
      end
      if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
        score*=1.7
      end      

    when 0xFF # Sunny Day
      if pbCheckGlobalAbility(:AIRLOCK) || pbCheckGlobalAbility(:CLOUDNINE) ||
         pbCheckGlobalAbility(:DELTASTREAM) || pbCheckGlobalAbility(:DESOLATELAND) ||
         pbCheckGlobalAbility(:PRIMORDIALSEA) || pbWeather==PBWeather::SUNNYDAY
        score-=90
      else
        for move in attacker.moves
          score+=20 if move.id!=0 && move.basedamage>0 && isConst?(move.type,PBTypes,:FIRE)
        end
        for move in opponent.moves
          score+=20 if move.id!=0 && move.basedamage>0 && isConst?(move.type,PBTypes,:WATER)
        end
        if attacker.hp==attacker.totalhp && 
          ((attacker.hasWorkingItem(:FOCUSSASH) || (attacker.hasWorkingAbility(:STURDY) && !(attacker.hasMoldBreaker rescue false))) &&
          (pbWeather==PBWeather::HAIL || attacker.pbHasType?(:ICE)) && 
          (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        score*=1.3 if attacker.hasWorkingItem(:HEATROCK)
        if attacker.pbHasMove?(getID(PBMoves,:WEATHERBALL)) || 
          attacker.hasWorkingAbility(:FORECAST)
          score*=2
        end
        score*=1.5 if pbWeather!=0 && pbWeather!=PBWeather::SUNNYDAY

        weather_moves = solar_moves
        weather_moves += [:HYDROSTEAM, :WEATHERBALL]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=1.5 
        end
        score*=1.5 if attacker.pbHasType?(:FIRE)

        if attacker.hasWorkingAbility(:CHLOROPHYLL) || attacker.hasWorkingAbility(:FLOWERGIFT)
          score*=2
          score*=2 if attacker.hasWorkingItem(:FOCUSASH)
          if attacker.effects[PBEffects::KingsShield]== true || 
           attacker.effects[PBEffects::BanefulBunker]== true ||
           attacker.effects[PBEffects::SpikyShield]== true
            score *=3
          end
        end
        
        if attacker.hasWorkingAbility(:SOLARPOWER) || 
          attacker.hasWorkingAbility(:LEAFGUARD)
          score*=1.3
        end
        if attacker.pbHasMove?(getID(PBMoves,:THUNDER)) || 
          attacker.pbHasMove?(getID(PBMoves,:HURRICANE))
          score*=0.7
        end
        
        score*=0.5 if attacker.hasWorkingAbility(:DRYSKIN)
        score*=1.5 if attacker.hasWorkingAbility(:HARVEST)
      end
      
    when 0x100 # Rain Dance
      if pbWeather==PBWeather::RAINDANCE || pbCheckGlobalAbility(:PRIMORDIALSEA) ||
         pbCheckGlobalAbility(:AIRLOCK) || pbCheckGlobalAbility(:CLOUDNINE) ||
         pbCheckGlobalAbility(:DELTASTREAM) || pbCheckGlobalAbility(:DESOLATELAND) 
        score-=90
      else
        for move in attacker.moves
          if move.id!=0 && move.basedamage>0 &&
             isConst?(move.type,PBTypes,:WATER)
            score+=20
          end
        end
        for move in opponent.moves
          if move.id!=0 && move.basedamage>0 &&
             isConst?(move.type,PBTypes,:FIRE)
            score+=20
          end
        end
        if attacker.hp==attacker.totalhp && 
          ((attacker.hasWorkingItem(:FOCUSSASH) || (attacker.hasWorkingAbility(:STURDY) && !(attacker.hasMoldBreaker rescue false))) && 
          (pbWeather==PBWeather::HAIL || attacker.pbHasType?(:ICE)) && 
          (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        if attacker.pbHasMove?(getID(PBMoves,:WEATHERBALL)) || 
          attacker.hasWorkingAbility(:FORECAST)
          score*=2
        end
  
        weather_moves = [:THUNDER, :HURRICANE, :WEATHERBALL, :ELECTROSHOT,
                         :SANDSEARSTORM, :WILDBOLTSTORM, :BLEAKWINDSTORM ]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=1.5 
        end
        
        score*=1.3 if attacker.hasWorkingItem(:DAMPROCK)
        score*=1.3 if pbWeather!=0 && pbWeather != PBWeather::RAINDANCE

        score*=2 if attacker.hasWorkingAbility(:SWIFTSWIM)
        score*=2 if attacker.hasWorkingItem(:FOCUSASH)

        if attacker.effects[PBEffects::KingsShield]== true || 
          attacker.effects[PBEffects::BanefulBunker]== true ||
          attacker.effects[PBEffects::SpikyShield]== true
          score *=3
        end
        
        if attacker.hasWorkingAbility(:DRYSKIN) || 
          attacker.hasWorkingAbility(:RAINDISH) ||
          attacker.hasWorkingAbility(:HYDRATION)
          score*=1.5
        end
        score*=0.5 if solar_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))}

        if isConst?(attacker.species,PBSpecies,:LUDICOLO) && @doublebattle
          score+=100
        else
          if attacker.hp<=attacker.totalhp/4
            score-=75
          elsif attacker.hp<=attacker.totalhp/2
            score-=35 
          end
        end
        
      end
      
    when 0x101 # Sandstorm      
      if pbCheckGlobalAbility(:AIRLOCK) ||
           pbCheckGlobalAbility(:CLOUDNINE) ||
           pbCheckGlobalAbility(:DELTASTREAM) ||
           pbCheckGlobalAbility(:DESOLATELAND) ||
           pbCheckGlobalAbility(:PRIMORDIALSEA) ||
           pbWeather==PBWeather::SANDSTORM
          score*=0
      else
        if attacker.hp==attacker.totalhp && 
          ((attacker.hasWorkingItem(:FOCUSSASH) || (attacker.hasWorkingAbility(:STURDY) && !(attacker.hasMoldBreaker rescue false))) && 
           ((pbWeather==PBWeather::HAIL) || attacker.pbHasType?(:ICE)) && 
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        score*=1.3 if attacker.hasWorkingItem(:SMOOTHROCK)
        score*=2 if pbWeather!=0 && pbWeather!=PBWeather::SANDSTORM
        score*=1.5 if attacker.pbHasType?(:ROCK)
        if attacker.pbHasMove?(getID(PBMoves,:WEATHERBALL)) || 
           attacker.hasWorkingAbility(:FORECAST)
          score*=2
        end
        weather_moves = [:SHOREUP, :WEATHERBALL]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=1.5 
        end
        if attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)
          score*=1.3
        else
          score*=0.7
        end
        if attacker.hasWorkingAbility(:SANDRUSH)
          score*=2
          if attacker.hasWorkingItem(:FOCUSASH)
            score*=2
          end
          if attacker.effects[PBEffects::KingsShield]== true || 
             attacker.effects[PBEffects::BanefulBunker]== true ||
             attacker.effects[PBEffects::SpikyShield]== true
             score *=3
          end
        end
        score*=1.3 if attacker.hasWorkingAbility(:SANDVEIL)
        score*=1.5 if attacker.pbHasMove?(getID(PBMoves,:SHOREUP))
        score*=1.5 if attacker.hasWorkingAbility(:SANDFORCE)
        score*=0.5 if solar_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))}
      end
    when 0x102 # Hail
      if pbCheckGlobalAbility(:AIRLOCK) ||
           pbCheckGlobalAbility(:CLOUDNINE) ||
           pbCheckGlobalAbility(:DELTASTREAM) ||
           pbCheckGlobalAbility(:DESOLATELAND) ||
           pbCheckGlobalAbility(:PRIMORDIALSEA) ||
           pbWeather==PBWeather::HAIL
          score*=0
      else
        if attacker.hp==attacker.totalhp && 
          ((attacker.hasWorkingItem(:FOCUSSASH) || (attacker.hasWorkingAbility(:STURDY) && 
          !(attacker.hasMoldBreaker rescue false))) && 
          ((pbWeather==PBWeather::HAIL) || attacker.pbHasType?(:ICE)) && 
          (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        
        score*=1.3 if attacker.hasWorkingItem(:ICYROCK)
        score*=1.3 if pbWeather!=0 && pbWeather!=PBWeather::HAIL

        if attacker.pbHasMove?(getID(PBMoves,:WEATHERBALL)) || 
          attacker.hasWorkingAbility(:FORECAST)
          score*=2
        end
        
        if attacker.pbHasType?(:ICE) && !SNOW_REPLACES_HAIL
          score*=2
        else
          score*=0.7
        end
        
        if attacker.hasWorkingAbility(:SLUSHRUSH)
          score*=2
          score*=2 if attacker.hasWorkingItem(:FOCUSASH) && !SNOW_REPLACES_HAIL
          if attacker.effects[PBEffects::KingsShield]== true || 
             attacker.effects[PBEffects::BanefulBunker]== true ||
             attacker.effects[PBEffects::SpikyShield]== true
            score *=3
          end
        end
        
        if attacker.hasWorkingAbility(:SNOWCLOAK) || 
          attacker.hasWorkingAbility(:ICEBODY)
          score*=1.3
        end
        
        score*=0.5 if solar_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))}
        weather_moves = [:BLIZZARD, :AURORAVEIL, :WEATHERBALL]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, move))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=1.5 
        end

      end  
    when 0x103 # Spikes
      if attacker.pbOpposingSide.effects[PBEffects::Spikes]>=3
        score-=90
      elsif !pbCanChooseNonActive?(attacker.pbOpposing1.index) &&
            !pbCanChooseNonActive?(attacker.pbOpposing2.index)
        # Opponent can't switch in any Pokemon
        score-=90
      else
        score+=5*attacker.pbOppositeOpposing.pbNonActivePokemonCount()
        score+=[40,26,13][attacker.pbOpposingSide.effects[PBEffects::Spikes]]
        if attacker.hp==attacker.totalhp && ((attacker.hasWorkingItem(:FOCUSSASH) || 
           (attacker.hasWorkingAbility(:STURDY) && !(attacker.hasMoldBreaker rescue false))) && 
           ((pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) && !SNOW_REPLACES_HAIL) && 
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.1
        end
        score*=1.2 if attacker.turncount<2
      end
    when 0x104 # Toxic Spikes
      if attacker.pbOpposingSide.effects[PBEffects::ToxicSpikes]>=2
        score-=90
      elsif !pbCanChooseNonActive?(attacker.pbOpposing1.index) &&
            !pbCanChooseNonActive?(attacker.pbOpposing2.index)
        # Opponent can't switch in any Pokemon
        score-=90
      else
        score+=4*attacker.pbOppositeOpposing.pbNonActivePokemonCount()
        score+=[26,13][attacker.pbOpposingSide.effects[PBEffects::ToxicSpikes]]
        if attacker.hp==attacker.totalhp && ((attacker.hasWorkingItem(:FOCUSSASH) || 
           (attacker.hasWorkingAbility(:STURDY) && !(attacker.hasMoldBreaker rescue false))) && 
           ((pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) && !SNOW_REPLACES_HAIL) && 
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.1
        end
        score*=1.2 if attacker.turncount<2
      end
    when 0x105 # Stealth Rock
      if attacker.pbOpposingSide.effects[PBEffects::StealthRock]
        score-=90
      elsif !pbCanChooseNonActive?(attacker.pbOpposing1.index) &&
            !pbCanChooseNonActive?(attacker.pbOpposing2.index)
        # Opponent can't switch in any Pokemon
        score-=90
      else
        score+=5*attacker.pbOppositeOpposing.pbNonActivePokemonCount()
        if attacker.hp==attacker.totalhp && ((attacker.hasWorkingItem(:FOCUSSASH) || (attacker.hasWorkingAbility(:STURDY) && !(attacker.hasMoldBreaker rescue false))) && (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.4
        end
        score*=1.3 if attacker.turncount<2
      end
    when 0x106 # Grass Pledge
    when 0x107 # Fire Pledge
    when 0x108 # Water Pledge
    when 0x109 # Pay Day
    when 0x10A # Brick Break
      score+=20 if attacker.pbOpposingSide.effects[PBEffects::Reflect]>0
      score+=20 if attacker.pbOpposingSide.effects[PBEffects::LightScreen]>0
      score+=20 if attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]>0      
    when 0x10B # Hi Jump Kick
      score+=10*(attacker.stages[PBStats::ACCURACY]-opponent.stages[PBStats::EVASION])
    when 0x10C # Substitute
      if attacker.effects[PBEffects::Substitute]>0
        score-=90
      elsif attacker.hp<=(attacker.totalhp/4)
        score-=90
      end
      score*=1.2 if opponent.effects[PBEffects::LeechSeed]>=0
      score*=1.2 if attacker.hasWorkingItem(:LEFTOVERS)     
      score*=1.2 if sleep_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || attacker.hasWorkingAbility(:BADDREAMS)
      score*=1.5 if attacker.pbHasMove?(getID(PBMoves,:FOCUSPUNCH))
      score*=1.5 if opponent.status==PBStatuses::SLEEP
      score*=0.3 if opponent.hasWorkingAbility(:INFILTRATOR)
      if opponent.pbHasMove?(getID(PBMoves,:UPROAR)) || 
        opponent.pbHasMove?(getID(PBMoves,:HYPERVOICE)) || 
        opponent.pbHasMove?(getID(PBMoves,:ECHOEDVOICE)) || 
        opponent.pbHasMove?(getID(PBMoves,:SNARL)) || 
        opponent.pbHasMove?(getID(PBMoves,:BOOMBURST)) 
        opponent.hasWorkingAbility(getID(PBMoves,:LIQUIDVOICE))
        score*=0.3
      end
      score*=1.3 if opponent.effects[PBEffects::Confusion]>0
      score*=1.3 if opponent.status==PBStatuses::PARALYSIS          
      score*=1.3 if opponent.effects[PBEffects::Attract]>=0
      score*=1.2 if attacker.pbHasMove?(getID(PBMoves,:BATONPASS))
      score*=1.1 if attacker.hasWorkingAbility(:SPEEDBOOST)
      score*=0.5 if @doublebattle
    when 0x10D # Curse
      if attacker.pbHasType?(:GHOST)
        if opponent.effects[PBEffects::Curse]
          score-=90
        elsif attacker.hp<=(attacker.totalhp/2)
          if attacker.pbNonActivePokemonCount()==0
            score-=90
          else
            score-=50
            score-=30 if @shiftStyle
          end
        end
        if attacker.hasWorkingAbility(:SHADOWTAG) || attacker.hasWorkingAbility(:ARENATRAP) || opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
          score*=1.3
        else
          score*=0.8
        end
      else
        avg=(attacker.stages[PBStats::SPEED]*10)
        avg-=(attacker.stages[PBStats::ATTACK]*10)
        avg-=(attacker.stages[PBStats::DEFENSE]*10)
        score+=avg/3
      end
    when 0x10E # Spite
      score += 20 if attacker.isSpecies?(:GYARADOS) #PARA EL JEFE
      if opponent.lastMoveUsed != 0
        moveData=PBMoveData.new(opponent.lastMoveUsed)
        typemod=pbTypeModifier(moveData.type,attacker,opponent)
        if moveData.basedamage == 0 
          score-=40
        else
          score += moveData.basedamage * 1.2
        end
        score*=2 if typemod >8
        score*=1.2 if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
      end
    when 0x10F # Nightmare
      if !opponent.effects[PBEffects::Nightmare] && opponent.status==PBStatuses::SLEEP && opponent.effects[PBEffects::Substitute]<=0
        score*=6 if opponent.status==PBStatuses::SLEEP
      else
        score-=90 if opponent.statusCount<=1
        score+=50 if opponent.statusCount>3
      end
      score*=0.5 if opponent.hasWorkingAbility(:EARLYBIRD)
      score*=6 if opponent.hasWorkingAbility(:COMATOSE)   
    when 0x110 # Rapid Spin
      score+=20 if attacker.effects[PBEffects::MultiTurn]>0
      score+=10 if attacker.effects[PBEffects::LeechSeed]>=0
      if attacker.pbNonActivePokemonCount()>0
        score+=20 if attacker.pbOwnSide.effects[PBEffects::Spikes]>0
        score+=20 if attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
        score+=20 if attacker.pbOwnSide.effects[PBEffects::StealthRock]
        score+=20 if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
      end
    when 0x111 # Future Sight
      if opponent.effects[PBEffects::FutureSight]>0
        score-=100
      elsif attacker.pbNonActivePokemonCount()==0
        # Future Sight tends to be wasteful if down to last Pokemon
        score-=70
      end
    when 0x112 # Stockpile
      avg=0
      avg-=(attacker.stages[PBStats::DEFENSE]*10)
      avg-=(attacker.stages[PBStats::SPDEF]*10)
      score+=avg/2
      if attacker.effects[PBEffects::Stockpile]>=3
        score-=80
      else
        # More preferable if user also has Spit Up/Swallow
        for move in attacker.moves
          if move.function==0x113 || move.function==0x114 # Spit Up, Swallow
            score+=20; break
          end
        end
      end
    when 0x113 # Spit Up
      score-=100 if attacker.effects[PBEffects::Stockpile]==0
    when 0x114 # Swallow
      if attacker.effects[PBEffects::Stockpile]==0
        score-=90
      elsif attacker.hp==attacker.totalhp
        score-=90
      else
        mult=[0,25,50,100][attacker.effects[PBEffects::Stockpile]]
        score+=mult
        score-=(attacker.hp*mult*2/attacker.totalhp)
      end
    when 0x115 # Focus Punch
      score+=50 if opponent.effects[PBEffects::HyperBeam]>0
      score-=35 if opponent.hp<=(opponent.totalhp/2) # If opponent is weak, no
      score-=70 if opponent.hp<=(opponent.totalhp/4) # need to risk this move
     
      score*=1.5 if opponent.effects[PBEffects::HyperBeam]>0
      score*=1.2 if opponent.status==PBStatuses::SLEEP && !opponent.hasWorkingAbility(:EARLYBIRD) && !opponent.hasWorkingAbility(:SHEDSKIN)

    when 0x116 # Sucker Punch
    when 0x117 # Follow Me
      if @doublebattle && attacker.pbPartner.hp!=0
        score*=1.3 if attacker.pbPartner.hasWorkingAbility(:MOODY)
        if attacker.pbPartner.turncount<1
          score*=1.2
        else
          score*=0.8
        end
        if attacker.hp==attacker.totalhp
          score*=1.2
        else
          score*=0.8
          score*=0.5 if attacker.hp*2 < attacker.totalhp
        end
        if attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) || attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)
          score*=1.2
        end
      else
        score-=100
      end
    when 0x118 # Gravity
      if @field.effects[PBEffects::Gravity]>0
        score-=90
      elsif skill>=PBTrainerAI.mediumSkill
        score-=30
        score-=20 if attacker.effects[PBEffects::SkyDrop]
        score-=20 if attacker.effects[PBEffects::MagnetRise]>0
        score-=20 if attacker.effects[PBEffects::Telekinesis]>0
        score-=20 if attacker.pbHasType?(:FLYING)
        score-=20 if attacker.hasWorkingAbility(:LEVITATE)
        score-=20 if attacker.hasWorkingItem(:AIRBALLOON)
        score+=20 if opponent.effects[PBEffects::SkyDrop]
        score+=20 if opponent.effects[PBEffects::MagnetRise]>0
        score+=20 if opponent.effects[PBEffects::Telekinesis]>0
        score+=20 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Fly
                     PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC || # Bounce
                     PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCE    # Sky Drop
        if attacker.pbHasMoveType?(:GROUND) && (opponent.pbHasType?(:FLYING) || 
           opponent.hasWorkingAbility(:LEVITATE) || opponent.hasWorkingItem(:AIRBALLOON))
          score*=2
        end
      end
    when 0x119 # Magnet Rise
      if attacker.effects[PBEffects::MagnetRise]>0 ||
         attacker.effects[PBEffects::Ingrain] ||
         attacker.effects[PBEffects::SmackDown]
        score*=0
      else
        score*=3 if opponent.pbHasMoveType?(:GROUND)
      end
    when 0x11A # Telekinesis
      if opponent.effects[PBEffects::Telekinesis]>0 ||
         opponent.effects[PBEffects::Ingrain] ||
         opponent.effects[PBEffects::SmackDown]
        score-=90
      end
    when 0x11B # Sky Uppercut
    when 0x11C # Smack Down
      if skill>=PBTrainerAI.mediumSkill
        score+=20 if opponent.effects[PBEffects::MagnetRise]>0
        score+=20 if opponent.effects[PBEffects::Telekinesis]>0
        score+=20 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Fly
                     PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC    # Bounce
        score+=20 if opponent.pbHasType?(:FLYING)
        score+=20 if opponent.hasWorkingAbility(:LEVITATE)
        score+=20 if opponent.hasWorkingItem(:AIRBALLOON)
      end
    when 0x11D # After You
    when 0x11E # Quash
    when 0x11F # Trick Room
      aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
      ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
      if aspeed<ospeed
        score+=150
      elsif @field.effects[PBEffects::TrickRoom]>0 && aspeed > ospeed
        score+=50
      elsif aspeed>ospeed
        score-=40
      end
    when 0x120
    when 0x121
    when 0x122
    when 0x123
      if !opponent.pbHasType?(attacker.type1) &&
         !opponent.pbHasType?(attacker.type2)
        score-=90
      end
    when 0x124
    when 0x125
    when 0x126
      score+=20 # Shadow moves are more preferable
    when 0x127
      score+=20 # Shadow moves are more preferable
      if opponent.pbCanParalyze?(attacker,false)
        score+=30
        if skill>=PBTrainerAI.mediumSkill
           aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
           ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          if aspeed<ospeed
            score+=30
          elsif aspeed>ospeed
            score-=40
          end
        end
        if skill>=PBTrainerAI.highSkill
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:QUICKFEET)
        end
      end
    when 0x128
      score+=20 # Shadow moves are more preferable
      if opponent.pbCanBurn?(attacker,false)
        score+=30
        if skill>=PBTrainerAI.highSkill
          score-=40 if opponent.hasWorkingAbility(:GUTS)
          score-=40 if opponent.hasWorkingAbility(:MARVELSCALE)
          score-=40 if opponent.hasWorkingAbility(:QUICKFEET)
          score-=40 if opponent.hasWorkingAbility(:FLAREBOOST)
        end
      end
    when 0x129
      score+=20 # Shadow moves are more preferable
      if opponent.pbCanFreeze?(attacker,false)
        score+=30
        score-=20 if opponent.hasWorkingAbility(:MARVELSCALE) && skill>=PBTrainerAI.highSkill
      end
    when 0x12A
      score+=20 # Shadow moves are more preferable
      if opponent.pbCanConfuse?(attacker,false)
        score+=30
      else
        score-=90 if skill>=PBTrainerAI.mediumSkill
      end
    when 0x12B
      score+=20 # Shadow moves are more preferable
      if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker)
        score-=90
      else
        score+=40 if attacker.turncount==0
        score+=opponent.stages[PBStats::DEFENSE]*20
      end
    when 0x12C
      score+=20 # Shadow moves are more preferable
      if !opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker)
        score-=90
      else
        score+=opponent.stages[PBStats::EVASION]*15
      end
    when 0x12D
      score+=20 # Shadow moves are more preferable
    when 0x12E
      score+=20 # Shadow moves are more preferable
      score+=20 if opponent.hp>=(opponent.totalhp/2)
      score-=20 if attacker.hp<(attacker.hp/2)
    when 0x12F
      score+=20 # Shadow moves are more preferable
      score-=110 if opponent.effects[PBEffects::MeanLook]>=0
    when 0x130
      score+=20 # Shadow moves are more preferable
      score-=40
    when 0x131
      score+=20 # Shadow moves are more preferable
      if pbCheckGlobalAbility(:AIRLOCK) ||
         pbCheckGlobalAbility(:CLOUDNINE)
        score-=90
      elsif pbWeather==PBWeather::SHADOWSKY
        score-=90
      end
    when 0x132
      score+=20 # Shadow moves are more preferable
      if opponent.pbOwnSide.effects[PBEffects::Reflect]>0 ||
         opponent.pbOwnSide.effects[PBEffects::LightScreen]>0 ||
         opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0 ||
         opponent.pbOwnSide.effects[PBEffects::Safeguard]>0
        score+=30
        score-=90 if attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
                     attacker.pbOwnSide.effects[PBEffects::LightScreen]>0 ||
                     attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0 ||                     
                     attacker.pbOwnSide.effects[PBEffects::Safeguard]>0
      else
        score-=110
      end
    when 0x133, 0x134
      score-=95
      score=0 if skill>=PBTrainerAI.highSkill
    when 0x135
      if opponent.pbCanFreeze?(attacker,false)
        score+=30
        score-=20 if opponent.hasWorkingAbility(:MARVELSCALE) && skill>=PBTrainerAI.highSkill
      end
    when 0x136
      score+=20 if attacker.stages[PBStats::DEFENSE]<0
    when 0x137
      if attacker.pbTooHigh?(PBStats::DEFENSE) &&
         attacker.pbTooHigh?(PBStats::SPDEF) &&
         !attacker.pbPartner.isFainted? &&
         attacker.pbPartner.pbTooHigh?(PBStats::DEFENSE) &&
         attacker.pbPartner.pbTooHigh?(PBStats::SPDEF)
        score-=90
      else
        score-=attacker.stages[PBStats::DEFENSE]*10
        score-=attacker.stages[PBStats::SPDEF]*10
        if !attacker.pbPartner.isFainted?
          score-=attacker.pbPartner.stages[PBStats::DEFENSE]*10
          score-=attacker.pbPartner.stages[PBStats::SPDEF]*10
        end
      end
    when 0x138
      if !@doublebattle
        score-=100
      elsif attacker.pbPartner.isFainted?
        score-=90
      else
        score-=attacker.pbPartner.stages[PBStats::SPDEF]*10
      end
    when 0x139
      if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker)
        score-=90
      else
        score+=opponent.stages[PBStats::ATTACK]*20
        if skill>=PBTrainerAI.mediumSkill
          hasphysicalattack=false
          for thismove in opponent.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsPhysical?(thismove.type)
              hasphysicalattack=true
            end
          end
          if hasphysicalattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
      end
    when 0x13A #Noble Roar
        if (!opponent.pbCanReduceStatStage?(PBStats::ATTACK) && !opponent.pbCanReduceStatStage?(PBStats::SPATK)) || (opponent.stages[PBStats::ATTACK]==-6 && opponent.stages[PBStats::SPATK]==-6) || (opponent.stages[PBStats::ATTACK]>0 && opponent.stages[PBStats::SPATK]>0)
          score=0 if move.basedamage==0
        else
          miniscore=100
          if attacker.hasWorkingAbility(:SHADOWTAG) || attacker.hasWorkingAbility(:ARENATRAP) || opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
            miniscore*=1.4
          end
          miniscore = 0
          # Loop over the stats and sum up the negative stage values
          [PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPEED, PBStats::SPATK, PBStats::SPDEF, PBStats::EVASION, PBStats::ACCURACY].each do |stat|
            miniscore += opponent.stages[stat] if opponent.stages[stat] < 0
          end
          miniscore *= -10
          miniscore += 100
          miniscore /= 100.0
          score *= miniscore
          miniscore*=0.5 if attacker.pbHasMove?(getID(PBMoves,:FOULPLAY))
          miniscore*=0.5 if attacker.pbNonActivePokemonCount==0

          if opponent.hasWorkingAbility(:COMPETITIVE) || 
             opponent.hasWorkingAbility(:DEFIANT) || 
             opponent.hasWorkingAbility(:CONTRARY)
            miniscore*=0.1
          end
          miniscore/=100.0
          score*=miniscore
        end  
    when 0x13B
      if !isConst?(attacker.species,PBSpecies,:HOOPA) || attacker.form!=1
        score-=100
      elsif opponent.stages[PBStats::DEFENSE]>0
        score+=20
      end
    when 0x13C
      score+=20 if opponent.stages[PBStats::SPATK]>0
    when 0x13D
      if !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker)
        score-=90
      else
        score+=40 if attacker.turncount==0
        score+=opponent.stages[PBStats::SPATK]*20
      end
    when 0x13E
      count=0
      for i in 0...4
        battler=@battlers[i]
        if battler.pbHasType?(:GRASS) && !battler.isAirborne? &&
           (!battler.pbTooHigh?(PBStats::ATTACK) || !battler.pbTooHigh?(PBStats::SPATK))
          count+=1
          if attacker.pbIsOpposing?(opponent.index)
            score-=20
          else
            score-=attacker.stages[PBStats::ATTACK]*10
            score-=attacker.stages[PBStats::SPATK]*10
          end
        end
      end
      score-=95 if count==0
    when 0x13F
      count=0
      for i in 0...4
        battler=@battlers[i]
        if battler.pbHasType?(:GRASS) && !battler.pbTooHigh?(PBStats::DEFENSE)
          count+=1
          if attacker.pbIsOpposing?(opponent.index)
            score-=20
          else
            score-=attacker.stages[PBStats::DEFENSE]*10
          end
        end
      end
      score-=95 if count==0
    when 0x140
      count=0
      for i in 0...4
        battler=@battlers[i]
        if battler.status==PBStatuses::POISON &&
           (!battler.pbTooLow?(PBStats::ATTACK) ||
           !battler.pbTooLow?(PBStats::SPATK) ||
           !battler.pbTooLow?(PBStats::SPEED))
          count+=1
          if attacker.pbIsOpposing?(opponent.index)
            score+=attacker.stages[PBStats::ATTACK]*10
            score+=attacker.stages[PBStats::SPATK]*10
            score+=attacker.stages[PBStats::SPEED]*10
          else
            score-=20
          end
        end
      end
      score-=95 if count==0
    when 0x141
      if opponent.effects[PBEffects::Substitute]>0
        score-=90
      else
        numpos=0; numneg=0
        for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                  PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
          stat=opponent.stages[i]
          (stat>0) ? numpos+=stat : numneg+=stat
        end
        if numpos!=0 || numneg!=0
          score+=(numpos-numneg)*10
        else
          score-=95
        end
      end
    when 0x142
      score-=90 if opponent.pbHasType?(:GHOST)
    when 0x143
      score-=90 if opponent.pbHasType?(:GRASS)
    when 0x144
    when 0x145
      aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
      ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
      score-=90 if aspeed>ospeed
    when 0x146 #Ion Deluge
    when 0x147 #Hyperspace Hole
    when 0x148 #Powder      
      if !(opponent.pbHasType?(:GRASS) || opponent.hasWorkingAbility(:OVERCOAT) || opponent.hasWorkingItem(:SAFETYGOGGLES))
        score*=1.2 if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        score*= opponent.pbHasMoveType?(:FIRE) ? 2 : 0.2
      end
      effcheck = PBTypes.getCombinedEffectiveness(getConst(PBTypes,:FIRE),attacker.type1,attacker.type2)
      if effcheck>4
        score*=2
        score*=2 if effcheck>8
      end
      if attacker.hp*(1.0/attacker.totalhp)>0.2 && attacker.hp*(1.0/attacker.totalhp)<0.4
        score*=0.5
      end
      score=0 if opponent.hasWorkingAbility(:MAGICGUARD) || opponent.effects[PBEffects::Powder]
      score=0 if !opponent.pbHasMoveType?(:FIRE) 
    when 0x149 #Matblock
      if attacker.turncount==0
        score+=30
      else
        score-=90 # Because it will fail here
        score=0 if skill>=PBTrainerAI.bestSkill
      end
    when 0x14A #Crafty Shield
    #when 0x14B, 0x14C
    #  if attacker.effects[PBEffects::ProtectRate]>1 ||
    #     opponent.effects[PBEffects::HyperBeam]>0
    #    score-=90
    #  else
    #    if skill>=PBTrainerAI.mediumSkill
    #      score-=(attacker.effects[PBEffects::ProtectRate]*40)
    #    end
    #    score+=50 if attacker.turncount==0
    #    score+=30 if opponent.effects[PBEffects::TwoTurnAttack]!=0
    #  end
    when 0x14D #Phantom Force
    when 0x14E #Geomancy
      if attacker.pbTooHigh?(PBStats::SPATK) &&
         attacker.pbTooHigh?(PBStats::SPDEF) &&
         attacker.pbTooHigh?(PBStats::SPEED)
        score-=90
      else
        score-=attacker.stages[PBStats::SPATK]*10 # Only *10 isntead of *20
        score-=attacker.stages[PBStats::SPDEF]*10 # because two-turn attack
        score-=attacker.stages[PBStats::SPEED]*10
        if skill>=PBTrainerAI.mediumSkill
          hasspecialattack=false
          for thismove in attacker.moves
            if thismove.id!=0 && thismove.basedamage>0 &&
               thismove.pbIsSpecial?(thismove.type)
              hasspecialattack=true
            end
          end
          if hasspecialattack
            score+=20
          elsif skill>=PBTrainerAI.highSkill
            score-=90
          end
        end
        if skill>=PBTrainerAI.highSkill
          aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
          ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
          score+=30 if aspeed<ospeed && aspeed*2>ospeed
        end
      end
    when 0x14F #Oblivion Wing
      if skill>=PBTrainerAI.highSkill && opponent.hasWorkingAbility(:LIQUIDOOZE)
        score-=80
      else
        score+=40 if attacker.hp<=(attacker.totalhp/2)
      end
    when 0x150 #Fell stinger
      score+=40 if opponent.hp<=(opponent.totalhp/8)
      score+=20 if !attacker.pbTooHigh?(PBStats::ATTACK) && opponent.hp<=(opponent.totalhp/4)
    when 0x151
      avg=opponent.stages[PBStats::ATTACK]*10
      avg+=opponent.stages[PBStats::SPATK]*10
      score+=avg/2
    when 0x152 # Fairy Lock
    when 0x153 # Sticky Web
      if opponent.pbOwnSide.effects[PBEffects::StickyWeb]
        score*=1.3 if attacker.hasWorkingItem(:FOCUSSASH) && attacker.hp==attacker.totalhp
        score*=1.3 if attacker.turncount<2
        score*=0.5 if attacker.pbNonActivePokemonCount==0
        if opponent.hasWorkingAbility(:UNAWARE) || 
          opponent.hasWorkingAbility(:COMPETITIVE) || 
          opponent.hasWorkingAbility(:DEFIANT) || 
          opponent.hasWorkingAbility(:CONTRARY)
          score*=0.1
        end
        score*=0.5 if opponent.hasWorkingAbility(:SPEEDBOOST)
        score*=1.5 if attacker.pbHasMove?(getID(PBMoves,:ELECTROBALL))
        score*=0.5 if attacker.pbHasMove?(getID(PBMoves,:GYROBALL))
      else
        score-=95 
      end 
    when 0x154 #Electric Terrain
      if @field.effects[PBEffects::ElectricTerrain]>0
        score-=95 
      else
        weather_moves = [:RISINGVOLTAGE, :TERRAINPULSE, :PSYBLADE]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=2
        end
        score*=2 if attacker.hasWorkingAbility(:SURGESURFER)
        score*=1.2 if attacker.pbHasType?(:ELECTRIC)
        score*=1.3 if attacker.hasWorkingItem(:ELECTRICSEED) || attacker.hasWorkingItem(:TERRAINEXTENDER)
        score-=40 if attacker.pbHasMove?(getID(PBMoves,:STEELROLLER)) || opponent.pbHasMove?(getID(PBMoves,:STEELROLLER))
      end 

    when 0x155 #Grassy Terrain
      if @field.effects[PBEffects::GrassyTerrain]>0
        score-=95 
      else
        weather_moves = [:GRASSYGLIDE, :TERRAINPULSE]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=2
        end
        score*=2 if attacker.hasWorkingAbility(:GRASSPELT)  
        score*=1.2 if attacker.pbHasType?(:GRASS)
        score*=1.3 if attacker.hasWorkingItem(:GRASSYSEED) || attacker.hasWorkingItem(:TERRAINEXTENDER)
        score-=40 if attacker.pbHasMove?(getID(PBMoves,:STEELROLLER)) || opponent.pbHasMove?(getID(PBMoves,:STEELROLLER))
      end 
    when 0x156 #Misty Terrain
      if @field.effects[PBEffects::MistyTerrain]>0
        score-=95         
      else
        weather_moves = [:MISTYEXPLOSION, :TERRAINPULSE]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=2
        end
        score*=1.2 if attacker.pbHasType?(:FAIRY)
        score*=1.3 if attacker.hasWorkingItem(:MISTYSEED) || attacker.hasWorkingItem(:TERRAINEXTENDER)
        score-=40 if attacker.pbHasMove?(getID(PBMoves,:STEELROLLER)) || opponent.pbHasMove?(getID(PBMoves,:STEELROLLER))
      end
    when 0x159 #Psychic Terrain
      if @field.effects[PBEffects::PsychicTerrain]>0
        score-=95 
      else
        weather_moves = [:EXPANDINGFORCE, :TERRAINPULSE]
        if weather_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov))} || 
           weather_moves.any? { |mov| attacker.pbPartner.pbHasMove?(getID(PBMoves, mov))}
          score*=2
        end
        score*=1.2 if attacker.pbHasType?(:PSYCHIC)
        score*=1.3 if attacker.hasWorkingItem(:PSYCHICSEED) || attacker.hasWorkingItem(:TERRAINEXTENDER)
        score-=40 if attacker.pbHasMove?(getID(PBMoves,:STEELROLLER)) || opponent.pbHasMove?(getID(PBMoves,:STEELROLLER))
      end 
    when 0x157 #Happy Hour
      score-=90
    when 0x158 #Belch
      score-=90 if !attacker.pokemon || !attacker.pokemon.belch  
    when 0x201 #RISING VOLTAGE
      score+=60 if @field.effects[PBEffects::ElectricTerrain]>0
    when 0x211 #GRASSY GLIDE
      score+=60 if @field.effects[PBEffects::GrassyTerrain]>0
    when 0x207 #EXPANDING FORCE
      score+=60 if @field.effects[PBEffects::PsychicTerrain]>0
    when 0x202 #MISTY EXPLOSION
      reserves=attacker.pbNonActivePokemonCount
      foes=attacker.pbOppositeOpposing.pbNonActivePokemonCount
      score+=60 if @field.effects[PBEffects::MistyTerrain]>0
      if attacker.hp==attacker.totalhp
        score*=0.2
      else
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        miniscore = 1-miniscore
        score*=miniscore
        if attacker.hp*4<attacker.totalhp            
          score*=1.3
          score*=1.4 if attacker.hasWorkingItem(:CUSTAPBERRY)
        end
      end
      if opponent.hasWorkingAbility(:DISGUISE) || opponent.effects[PBEffects::Substitute]>0
        score*=0.3
      end
      score = 0 if pbCheckGlobalAbility(:DAMP)
      if reserves==0 && foes>0
        score = 0 
      elsif reserves==0 && foes==0
        score -= 100 
      end
    when 0x203 #TERRAIN PULSE
    when 0x205 #STEEL ROLLER
      if @field.effects[PBEffects::PsychicTerrain]>0
        score-=50 if attacker.pbHasType?(:PSYCHIC)
        score+=60
      elsif @field.effects[PBEffects::MistyTerrain]>0
        score-=50 if attacker.pbHasType?(:FAIRY)
        score+=60
      elsif @field.effects[PBEffects::GrassyTerrain]>0
        score-=50 if attacker.hasWorkingAbility(:GRASSPELT)
        score-=50 if attacker.pbHasType?(:GRASS)
        score+=60
      elsif @field.effects[PBEffects::ElectricTerrain]>0
        score-=50 if attacker.hasWorkingAbility(:SURGESURFER)
        score-=50 if attacker.pbHasType?(:ELECTRIC)
        score+=60
      else
        score-=90
      end
      when 0xCF3 # Purify
        score*=1.3 if opponent.effects[PBEffects::Toxic]>0
        if attacker.hp==attacker.totalhp
          score=0
        else
          score+=50
          score-=(attacker.hp*100/attacker.totalhp)
        end
        score*=0.7 if setup_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov)) }
        score*=1.2 if lowerUser_moves.any? { |mov| attacker.pbHasMove?(getID(PBMoves, mov)) }

        if attacker.hp/attacker.totalhp<0.5
          score*=1.5
          score*=2 if attacker.effects[PBEffects::Curse]
          if attacker.hp*4<attacker.totalhp
            score*=1.5 if attacker.status==PBStatuses::POISON
            score*=2 if attacker.effects[PBEffects::LeechSeed]>=0
            if attacker.hp<attacker.totalhp*0.13
              score*=2 if attacker.status==PBStatuses::BURN
              if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) || (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
                score*=2
              end  
            end            
          end          
        else
          score*=0.7
        end  
        if attacker.effects[PBEffects::Toxic]>0
          score*=0.5
          score*=0.5 if attacker.effects[PBEffects::Toxic]>4
        end
        if attacker.status==PBStatuses::PARALYSIS || attacker.effects[PBEffects::Attract]>=0 || attacker.effects[PBEffects::Confusion]>0
          score*=1.1
        end        
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN || opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          score*=1.3 if opponent.effects[PBEffects::Toxic]>0
        end
        score=0 if attacker.effects[PBEffects::Wish]>0
        if [PBStatuses::POISON, PBStatuses::BURN, PBStatuses::SLEEP, PBStatuses::FROZEN, PBStatuses::PARALYSIS].include?(opponent.status)
          score=0
        end
      #### FIN WHEN
      when 0x259 # DRAGON CHEER 
        if move.basedamage==0
          if attacker.effects[PBEffects::FocusEnergy]>=2
            score-=80
          else
            score+=30
            score+=30 if attacker.pbHasType?(:DRAGON) || attacker.pbPartner.pbHasType?(:DRAGON)
          end
        else
          score+=30 if attacker.effects[PBEffects::FocusEnergy]<2
        end
      when 0x261 # UPPER HAND
        if pri_moves.any? {|mov| opponent.pbHasMove?(getID(PBMoves, mov))}
          if skill>=PBTrainerAI.highSkill
            score+=30 if !opponent.hasWorkingAbility(:INNERFOCUS) &&
                         opponent.effects[PBEffects::Substitute]==0
            score+=30 if attacker.hp/attacker.totalhp
          end
        elsif opponent.pbHasMove?(getID(PBMoves,:GRASSYGLIDE)) && @field.effects[PBEffects::GrassyTerrain]>0
          score+=60 
        else
          score-=90 # Because it will fail here
          score=0 if skill>=PBTrainerAI.bestSkill
        end
      end
    # A score of 0 here means it should absolutely not be used
    return score if score<=0
##### Other score modifications ################################################
    # Prefer damaging moves if AI has no more Pokémon
    if attacker.pbNonActivePokemonCount==0
      if skill>=PBTrainerAI.mediumSkill &&
         !(skill>=PBTrainerAI.highSkill && opponent.pbNonActivePokemonCount>0)
        if move.basedamage==0 || opponent.hp<=opponent.totalhp/2
          score/=1.5
        end
      end
    end
    # Don't prefer attacking the opponent if they'd be semi-invulnerable
    if opponent.effects[PBEffects::TwoTurnAttack]>0 &&
       skill>=PBTrainerAI.highSkill
      invulmove=PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function
      if move.accuracy>0 &&   # Checks accuracy, i.e. targets opponent
         ([0xC9,0xCA,0xCB,0xCC,0xCD,0xCE].include?(invulmove) ||
         opponent.effects[PBEffects::SkyDrop]) &&
         attacker.pbSpeed>opponent.pbSpeed
        if skill>=PBTrainerAI.bestSkill   # Can get past semi-invulnerability
          miss=false
          case invulmove
          when 0xC9, 0xCC # Fly, Bounce
            miss=true unless move.function==0x08 ||  # Thunder
                             move.function==0x15 ||  # Hurricane
                             move.function==0x77 ||  # Gust
                             move.function==0x78 ||  # Twister
                             move.function==0x11B || # Sky Uppercut
                             move.function==0x11C || # Smack Down
                             isConst?(move.id,PBMoves,:WHIRLWIND)
          when 0xCA # Dig
            miss=true unless move.function==0x76 || # Earthquake
                             move.function==0x95    # Magnitude
          when 0xCB # Dive
            miss=true unless move.function==0x75 || # Surf
                             move.function==0xD0    # Whirlpool
          when 0xCD # Shadow Force
            miss=true
          when 0xCE # Sky Drop
            miss=true unless move.function==0x08 ||  # Thunder
                             move.function==0x15 ||  # Hurricane
                             move.function==0x77 ||  # Gust
                             move.function==0x78 ||  # Twister
                             move.function==0x11B || # Sky Uppercut
                             move.function==0x11C    # Smack Down
          when 0x14D # Phantom Force
            miss=true
          end
          if opponent.effects[PBEffects::SkyDrop]
            miss=true unless move.function==0x08 ||  # Thunder
                             move.function==0x15 ||  # Hurricane
                             move.function==0x77 ||  # Gust
                             move.function==0x78 ||  # Twister
                             move.function==0x11B || # Sky Uppercut
                             move.function==0x11C    # Smack Down
          end
          score-=80 if miss
        else
          score-=80
        end
      end
    end
    # Pick a good move for the Choice items
    if attacker.hasWorkingItem(:CHOICEBAND) ||
       attacker.hasWorkingItem(:CHOICESPECS) ||
       attacker.hasWorkingItem(:CHOICESCARF)
      if skill>=PBTrainerAI.mediumSkill
        if move.basedamage>=60
          score+=60
        elsif move.basedamage>0
          score+=30
        elsif move.function==0xF2 # Trick
          score+=70
        else
          score-=60
        end
      end
    end
    # If user has King's Rock, prefer moves that may cause flinching with it # TODO
    # If user is asleep, prefer moves that are usable while asleep
    if attacker.status==PBStatuses::SLEEP
      if skill>=PBTrainerAI.mediumSkill
        if move.function!=0x11 && move.function!=0xB4 # Snore, Sleep Talk
          hasSleepMove=false
          for m in attacker.moves
            if m.function==0x11 || m.function==0xB4 # Snore, Sleep Talk
              hasSleepMove=true; break
            end
          end
          score-=60 if hasSleepMove
        end
      end
    end
    # If user is frozen, prefer a move that can thaw the user
    if attacker.status==PBStatuses::FROZEN
      if skill>=PBTrainerAI.mediumSkill
        if move.canThawUser?
          score+=40
        else
          hasFreezeMove=false
          for m in attacker.moves
            if m.canThawUser?
              hasFreezeMove=true; break
            end
          end
          score-=60 if hasFreezeMove
        end
      end
    end
    # If target is frozen, don't prefer moves that could thaw them # TODO
    # Adjust score based on how much damage it can deal
    if (move.basedamage == 0 && opponent.hasWorkingAbility(:GOODASGOLD)) # Good As Gold/Cuerpo Aureo
      score = 0
    end
    if move.basedamage>0
      typemod=pbTypeModifier(move.type,attacker,opponent)
      if typemod==0 || score<=0
        score=0
      elsif typemod<=8 &&
            opponent.hasWorkingAbility(:WONDERGUARD)
        score=0
      elsif isConst?(move.type,PBTypes,:GROUND) &&
            (opponent.hasWorkingAbility(:LEVITATE) ||
            opponent.effects[PBEffects::MagnetRise]>0 ||
            opponent.hasWorkingAbility(:EARTHEATER))
        score=0
      elsif move.isSoundBased? && opponent.hasWorkingAbility(:SOUNDPROOF)
        score=0
      elsif isConst?(move.type,PBTypes,:FIRE) &&
            (opponent.hasWorkingAbility(:FLASHFIRE) || 
             opponent.hasWorkingAbility(:WELLBAKEDBODY))
        score=0
      elsif isConst?(move.type,PBTypes,:WATER) &&
            (opponent.hasWorkingAbility(:WATERABSORB) ||
            opponent.hasWorkingAbility(:STORMDRAIN) ||
            opponent.hasWorkingAbility(:DRYSKIN))
        score=0
      elsif isConst?(move.type,PBTypes,:GRASS) &&
            opponent.hasWorkingAbility(:SAPSIPPER)
        score=0
      elsif isConst?(move.type,PBTypes,:ELECTRIC) &&
            (opponent.hasWorkingAbility(:VOLTABSORB) ||
            opponent.hasWorkingAbility(:LIGHTNINGROD) ||
            opponent.hasWorkingAbility(:MOTORDRIVE))
        score=0
      elsif move.isWindMove? &&
            opponent.hasWorkingAbility(:WINDRIDER)
        score=0
      elsif move.isBombMove? &&
            opponent.hasWorkingAbility(:BULLETPROOF)  
        score=0
      else
        # Calculate how much damage the move will do (roughly)
        realDamage=move.basedamage
        realDamage=60 if move.basedamage==1
          realDamage=pbBetterBaseDamage(move,attacker,opponent,skill,realDamage)
        realDamage=pbRoughDamage(move,attacker,opponent,skill,realDamage)
        # Account for accuracy of move
        accuracy=pbRoughAccuracy(move,attacker,opponent,skill)
        basedamage=realDamage*accuracy/100.0
        # Two-turn attacks waste 2 turns to deal one lot of damage
        # Not halved because semi-invulnerable during use or hits first turn
        basedamage*=2/3 if move.pbTwoTurnAttack(attacker) || move.function==0xC2 # Hyper Beam  
        # Prefer flinching effects
        if !opponent.hasWorkingAbility(:INNERFOCUS) &&
           opponent.effects[PBEffects::Substitute]==0
          if (attacker.hasWorkingItem(:KINGSROCK) || attacker.hasWorkingItem(:RAZORFANG)) &&
             move.canKingsRock?
            basedamage*=1.05
          elsif attacker.hasWorkingAbility(:STENCH) &&
                move.function!=0x09 && # Thunder Fang
                move.function!=0x0B && # Fire Fang
                move.function!=0x0E && # Ice Fang
                move.function!=0x0F && # flinch-inducing moves
                move.function!=0x10 && # Stomp
                move.function!=0x11 && # Snore
                move.function!=0x12 && # Fake Out
                move.function!=0x78 && # Twister
                move.function!=0xC7    # Sky Attack
            basedamage*=1.05
          end
        end
        # Convert damage to proportion of opponent's remaining HP
        basedamage=(basedamage*100.0/opponent.hp)
        # Don't prefer weak attacks
        #basedamage/=2 if basedamage<40
        # Prefer damaging attack if level difference is significantly high
        basedamage*=1.2 if attacker.level-10>opponent.level
        # Adjust score
        basedamage=basedamage.round
        basedamage=120 if basedamage>120   # Treat all OHKO moves the same
        basedamage+=40 if basedamage>100   # Prefer moves likely to OHKO
        score=score.round
        oldscore=score
        score+=basedamage
        PBDebug.log("[AI] #{PBMoves.getName(move.id)} damage calculated (#{realDamage}=>#{basedamage}% of target's #{opponent.hp} HP), score change #{oldscore}=>#{score}")
      end
    else
      # Don't prefer attacks which don't deal damage
      score-=10
      # Account for accuracy of move
      accuracy=pbRoughAccuracy(move,attacker,opponent,skill)
      score*=accuracy/100.0
      score=0 if score<=10 && skill>=PBTrainerAI.highSkill
    end
    score=score.to_i
    score=0 if score<0
    return score
  end

################################################################################
# Get type effectiveness and approximate stats.
################################################################################
  def pbTypeModifier(type,attacker,opponent)
    return 8 if type<0
    return 8 if isConst?(type,PBTypes,:GROUND) && opponent.pbHasType?(:FLYING) &&
                opponent.hasWorkingItem(:IRONBALL) && !USENEWBATTLEMECHANICS
    atype=type
    otype1=opponent.type1
    otype2=opponent.type2
    # Illusion
    if opponent.effects[PBEffects::Illusion]
      otype1 = opponent.effects[PBEffects::Illusion].type1
      otype2 = opponent.effects[PBEffects::Illusion].type2
    end
    otype3=opponent.effects[PBEffects::Type3] || -1
    # Roost
    if isConst?(otype1,PBTypes,:FLYING) && opponent.effects[PBEffects::Roost]
      if isConst?(otype2,PBTypes,:FLYING) && isConst?(otype3,PBTypes,:FLYING)
        otype1=getConst(PBTypes,:NORMAL) || 0
      else
        otype1=otype2
      end
    end
    otype2=otype1 if isConst?(otype2,PBTypes,:FLYING) && opponent.effects[PBEffects::Roost]
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
    if (attacker.hasWorkingAbility(:SCRAPPY) rescue false) || opponent.effects[PBEffects::Foresight]
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
    if pbWeather==PBWeather::STRONGWINDS
      mod1=2 if isConst?(otype1,PBTypes,:FLYING) && PBTypes.isSuperEffective?(atype,otype1)
      mod2=2 if isConst?(otype2,PBTypes,:FLYING) && PBTypes.isSuperEffective?(atype,otype2)
      mod3=2 if isConst?(otype3,PBTypes,:FLYING) && PBTypes.isSuperEffective?(atype,otype3)
    end
    # Smack Down makes Ground moves work against fliers
    if !opponent.isAirborne?((attacker.hasMoldBreaker rescue false)) && isConst?(atype,PBTypes,:GROUND)
      mod1=2 if isConst?(otype1,PBTypes,:FLYING)
      mod2=2 if isConst?(otype2,PBTypes,:FLYING)
      mod3=2 if isConst?(otype3,PBTypes,:FLYING)
    end
    return mod1*mod2*mod3
  end

  def pbTypeModifier2(battlerThis,battlerOther)
    # battlerThis isn't a Battler object, it's a Pokémon - it has no third type
    if battlerThis.type1==battlerThis.type2
      return 4*pbTypeModifier(battlerThis.type1,battlerThis,battlerOther)
    end
    ret=pbTypeModifier(battlerThis.type1,battlerThis,battlerOther)
    ret*=pbTypeModifier(battlerThis.type2,battlerThis,battlerOther)
    return ret*2 # 0,1,2,4,_8_,16,32,64
  end

  def pbRoughStat(battler,stat,skill)
    return battler.pbSpeed if skill>=PBTrainerAI.highSkill && stat==PBStats::SPEED
    stagemul=[2,2,2,2,2,2,2,3,4,5,6,7,8]
    stagediv=[8,7,6,5,4,3,2,2,2,2,2,2,2]
    stage=battler.stages[stat]+6
    value=0
    case stat
    when PBStats::ATTACK; value=battler.attack
    when PBStats::DEFENSE; value=battler.defense
    when PBStats::SPEED; value=battler.speed
    when PBStats::SPATK; value=battler.spatk
    when PBStats::SPDEF; value=battler.spdef
    end
    return (value*1.0*stagemul[stage]/stagediv[stage]).floor
  end

  def pbBetterBaseDamage(move,attacker,opponent,skill,basedamage)
    # Covers all function codes which have their own def pbBaseDamage
    case move.function
    when 0x6A # SonicBoom
      basedamage=20
    when 0x6B # Dragon Rage
      basedamage=40
    when 0x6C # Super Fang
      basedamage=(opponent.hp/2).floor
    when 0x6D # Night Shade
      basedamage=attacker.level
    when 0x6E # Endeavor
      basedamage=opponent.hp-attacker.hp
    when 0x6F # Psywave
      basedamage=attacker.level
    when 0x70 # OHKO
      basedamage=opponent.totalhp
    when 0x71 # Counter
      basedamage=60
    when 0x72 # Mirror Coat
      basedamage=60
    when 0x73 # Metal Burst
      basedamage=60
    when 0x75, 0x12D # Surf, Shadow Storm
      basedamage*=2 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCB # Dive
    when 0x76 # Earthquake
      basedamage*=2 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCA # Dig
    when 0x77, 0x78 # Gust, Twister
      basedamage*=2 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Fly
                       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC || # Bounce
                       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCE    # Sky Drop
    when 0x7B # Venoshock
      basedamage*=2 if opponent.status==PBStatuses::POISON
    when 0x7C # SmellingSalt
      basedamage*=2 if opponent.status==PBStatuses::PARALYSIS
    when 0x7D # Wake-Up Slap
      basedamage*=2 if opponent.status==PBStatuses::SLEEP
    when 0x7E # Facade
      basedamage*=2 if attacker.status==PBStatuses::POISON ||
                       attacker.status==PBStatuses::BURN ||
                       attacker.status==PBStatuses::PARALYSIS
    when 0x7F # Hex
      basedamage*=2 if opponent.status != 0
    when 0x80 # Brine
      basedamage*=2 if opponent.hp<=(opponent.totalhp/2).floor
    when 0x85 # Retaliate
      #TODO
    when 0x86 # Acrobatics
      basedamage*=2 if attacker.item==0 || attacker.hasWorkingItem(:FLYINGGEM)
    when 0x87 # Weather Ball
      basedamage*=2 if pbWeather!=0
    when 0x89 # Return
      basedamage=[(attacker.happiness*2/5).floor,1].max
    when 0x8A # Frustration
      basedamage=[((255-attacker.happiness)*2/5).floor,1].max
    when 0x8B # Eruption
      basedamage=[(150*attacker.hp/attacker.totalhp).floor,1].max
    when 0x8C # Crush Grip
      basedamage=[(120*opponent.hp/opponent.totalhp).floor,1].max
    when 0x8D # Gyro Ball
      ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
      aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
      basedamage=[[(25*ospeed/aspeed).floor,150].min,1].max
    when 0x8E # Stored Power
      mult=0
      for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
        mult+=attacker.stages[i] if attacker.stages[i]>0
      end
      basedamage=20*(mult+1)
    when 0x8F # Punishment
      mult=0
      for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
                PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
        mult+=opponent.stages[i] if opponent.stages[i]>0
      end
      basedamage=[20*(mult+3),200].min
    when 0x90 # Hidden Power
      hp=pbHiddenPower(attacker.iv)
      basedamage=hp[1]
    when 0x91 # Fury Cutter
      basedamage=basedamage<<(attacker.effects[PBEffects::FuryCutter]-1)
    when 0x92 # Echoed Voice
      basedamage*=attacker.pbOwnSide.effects[PBEffects::EchoedVoiceCounter]
    when 0x94 # Present
      basedamage=50
    when 0x95 # Magnitude
      basedamage=71
      basedamage*=2 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCA # Dig
    when 0x96 # Natural Gift
      damagearray={
         60 => [:CHERIBERRY,:CHESTOBERRY,:PECHABERRY,:RAWSTBERRY,:ASPEARBERRY,
                :LEPPABERRY,:ORANBERRY,:PERSIMBERRY,:LUMBERRY,:SITRUSBERRY,
                :FIGYBERRY,:WIKIBERRY,:MAGOBERRY,:AGUAVBERRY,:IAPAPABERRY,
                :RAZZBERRY,:OCCABERRY,:PASSHOBERRY,:WACANBERRY,:RINDOBERRY,
                :YACHEBERRY,:CHOPLEBERRY,:KEBIABERRY,:SHUCABERRY,:COBABERRY,
                :PAYAPABERRY,:TANGABERRY,:CHARTIBERRY,:KASIBBERRY,:HABANBERRY,
                :COLBURBERRY,:BABIRIBERRY,:CHILANBERRY],
         70 => [:BLUKBERRY,:NANABBERRY,:WEPEARBERRY,:PINAPBERRY,:POMEGBERRY,
                :KELPSYBERRY,:QUALOTBERRY,:HONDEWBERRY,:GREPABERRY,:TAMATOBERRY,
                :CORNNBERRY,:MAGOSTBERRY,:RABUTABERRY,:NOMELBERRY,:SPELONBERRY,
                :PAMTREBERRY],
         80 => [:WATMELBERRY,:DURINBERRY,:BELUEBERRY,:LIECHIBERRY,:GANLONBERRY,
                :SALACBERRY,:PETAYABERRY,:APICOTBERRY,:LANSATBERRY,:STARFBERRY,
                :ENIGMABERRY,:MICLEBERRY,:CUSTAPBERRY,:JABOCABERRY,:ROWAPBERRY]
      }
      haveanswer=false
      for i in damagearray.keys
        data=damagearray[i]
        if data
          for j in data
            if isConst?(attacker.item,PBItems,j)
              basedamage=i; haveanswer=true; break
            end
          end
        end
        break if haveanswer
      end
    when 0x97 # Trump Card
      dmgs=[200,80,60,50,40]
      ppleft=[move.pp-1,4].min   # PP is reduced before the move is used
      basedamage=dmgs[ppleft]
    when 0x98 # Flail
      n=(48*attacker.hp/attacker.totalhp).floor
      basedamage=20
      basedamage=40 if n<33
      basedamage=80 if n<17
      basedamage=100 if n<10
      basedamage=150 if n<5
      basedamage=200 if n<2
    when 0x99 # Electro Ball
      n=(attacker.pbSpeed/opponent.pbSpeed).floor
      basedamage=40
      basedamage=60 if n>=1
      basedamage=80 if n>=2
      basedamage=120 if n>=3
      basedamage=150 if n>=4
    when 0x9A # Low Kick
      weight=opponent.weight
      basedamage=20
      basedamage=40 if weight>100
      basedamage=60 if weight>250
      basedamage=80 if weight>500
      basedamage=100 if weight>1000
      basedamage=120 if weight>2000
    when 0x9B # Heavy Slam
      n=(attacker.weight/opponent.weight).floor
      basedamage=40
      basedamage=60 if n>=2
      basedamage=80 if n>=3
      basedamage=100 if n>=4
      basedamage=120 if n>=5
    when 0xA0 # Frost Breath
      basedamage*=2
    when 0xBD, 0xBE # Double Kick, Twineedle
      basedamage*=2
    when 0xBF # Triple Kick
      basedamage*=6
    when 0xC0 # Fury Attack
      if attacker.hasWorkingAbility(:SKILLLINK)
        basedamage*=5
      else
        basedamage=(basedamage*19/6).floor
      end
    when 0xC1 # Beat Up
      party=pbParty(attacker.index)
      mult=0
      for i in 0...party.length
        mult+=1 if party[i] && !party[i].isEgg? &&
                   party[i].hp>0 && party[i].status==0
      end
      basedamage*=mult
    when 0xC4 # SolarBeam
      if pbWeather!=0 && pbWeather!=PBWeather::SUNNYDAY
        basedamage=(basedamage*0.5).floor
      end
    when 0xD0 # Whirlpool
      if skill>=PBTrainerAI.mediumSkill
        basedamage*=2 if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCB # Dive
      end
    when 0xD3 # Rollout
      if skill>=PBTrainerAI.mediumSkill
        basedamage*=2 if attacker.effects[PBEffects::DefenseCurl]
      end
    when 0xE1 # Final Gambit
      basedamage=attacker.hp
    when 0xF7 # Fling
      #TODO
    when 0x113 # Spit Up
      basedamage*=attacker.effects[PBEffects::Stockpile]
    when 0x144
      type=getConst(PBTypes,:FLYING) || -1
      if type>=0
        mult=PBTypes.getCombinedEffectiveness(type,
           opponent.type1,opponent.type2,opponent.effects[PBEffects::Type3])
        basedamage=((basedamage*mult)/8).round
      end
    when 0x201 #RISING VOLTAGE
      basedamage*=2 if @field.effects[PBEffects::ElectricTerrain]>0
    when 0x211 #GRASSY GLIDE
      basedamage*=2 if @field.effects[PBEffects::GrassyTerrain]>0
    when 0x207 #EXPANDING FORCE
      basedamage*=2 if @field.effects[PBEffects::PsychicTerrain]>0
    when 0x202 #MISTY EXPLOSION
      basedamage*=2 if @field.effects[PBEffects::MistyTerrain]>0
    when 0x203
      if @field.effects[PBEffects::PsychicTerrain]>0
        basedamage*=2
      elsif @field.effects[PBEffects::MistyTerrain]>0
        basedamage*=2
      elsif @field.effects[PBEffects::GrassyTerrain]>0
        basedamage*=2
      elsif @field.effects[PBEffects::ElectricTerrain]>0
        basedamage*=2
      end
    end
    return basedamage
  end

  def pbRoughDamage(move,attacker,opponent,skill,basedamage)
    # Fixed damage moves
    return basedamage if move.function==0x6A ||   # SonicBoom
                         move.function==0x6B ||   # Dragon Rage
                         move.function==0x6C ||   # Super Fang
                         move.function==0x6D ||   # Night Shade
                         move.function==0x6E ||   # Endeavor
                         move.function==0x6F ||   # Psywave
                         move.function==0x70 ||   # OHKO
                         move.function==0x71 ||   # Counter
                         move.function==0x72 ||   # Mirror Coat
                         move.function==0x73 ||   # Metal Burst
                         move.function==0xE1      # Final Gambit
    type=move.type
    # More accurate move type (includes Normalize, most type-changing moves, etc.)
    type=move.pbType(type,attacker,opponent) if skill>=PBTrainerAI.highSkill
    if skill>=PBTrainerAI.highSkill
      if attacker.hasWorkingAbility(:WATERBUBBLE) && isConst?(type,PBTypes,:FIRE)
        basedamage=(basedamage*0.5).round
      elsif attacker.hasWorkingAbility(:WATERBUBBLE) && isConst?(type,PBTypes,:WATER)
        basedamage=(basedamage*2).round
      end
      # Technician
      if attacker.hasWorkingAbility(:TECHNICIAN) && basedamage<=60
        basedamage=(basedamage*1.5).round
      end
    end
    if skill>=PBTrainerAI.mediumSkill
      # Iron Fist
      if attacker.hasWorkingAbility(:IRONFIST) && move.isPunchingMove?
        basedamage=(basedamage*1.2).round
      end
      if attacker.hasWorkingAbility(:STRONGJAW) && move.isBitingMove?
        basedamage=(basedamage*1.2).round
      end
      if attacker.hasWorkingAbility(:MEGALAUNCHER) && move.isPulseMove?
        basedamage=(basedamage*1.5).round
      end
      if attacker.hasWorkingAbility(:STEELWORKER) && isConst?(type,PBTypes,:STEEL)
        basedamage=(basedamage*1.5).round
      end
      if attacker.hasWorkingAbility(:ROCKYPAYLOAD) && isConst?(type,PBTypes,:ROCK)
        basedamage=(basedamage*1.5).round
      end
      if attacker.hasWorkingAbility(:PUNKROCK) && move.isSoundBased?
        basedamage=(basedamage*1.3).round
      end
    end
    # Reckless
    if skill>=PBTrainerAI.mediumSkill
      if attacker.hasWorkingAbility(:RECKLESS)
        if @function==0xFA ||  # Take Down, etc.
           @function==0xFB ||  # Double-Edge, etc.
           @function==0xFC ||  # Head Smash
           @function==0xFD ||  # Volt Tackle
           @function==0xFE ||  # Flare Blitz
           @function==0x10B || # Jump Kick, Hi Jump Kick
           @function==0x130    # Shadow End
          basedamage=(basedamage*1.2).round
        end
      end
    end
    if skill>=PBTrainerAI.highSkill
      # Flare Boost
      if attacker.hasWorkingAbility(:FLAREBOOST) &&
         attacker.status==PBStatuses::BURN && move.pbIsSpecial?(type)
        basedamage=(basedamage*1.5).round
      end
      # Toxic Boost
      if attacker.hasWorkingAbility(:TOXICBOOST) &&
         attacker.status==PBStatuses::POISON && move.pbIsPhysical?(type)
        basedamage=(basedamage*1.5).round
      end
    end
    # Rivalry
    if skill>=PBTrainerAI.mediumSkill
      if attacker.hasWorkingAbility(:RIVALRY) &&
         attacker.gender!=2 && opponent.gender!=2
        if attacker.gender==opponent.gender
          basedamage=(basedamage*1.25).round
        else
          basedamage=(basedamage*0.75).round
        end
      end
      # Sand Force
      if attacker.hasWorkingAbility(:SANDFORCE) &&
         pbWeather==PBWeather::SANDSTORM &&
         (isConst?(type,PBTypes,:ROCK) ||
         isConst?(type,PBTypes,:GROUND) ||
         isConst?(type,PBTypes,:STEEL))
        basedamage=(basedamage*1.3).round
      end
    end
    if skill>=PBTrainerAI.bestSkill
      # Heatproof
      if opponent.hasWorkingAbility(:HEATPROOF) &&
         isConst?(type,PBTypes,:FIRE)
        basedamage=(basedamage*0.5).round
      end
      # Dry Skin
      if (opponent.hasWorkingAbility(:DRYSKIN) ||
          opponent.hasWorkingAbility(:FLUFFY)) &&
         isConst?(type,PBTypes,:FIRE)
        basedamage=(basedamage*1.25).round
      end
    end
    # Sheer Force
    if skill>=PBTrainerAI.highSkill
      if attacker.hasWorkingAbility(:SHEERFORCE) && move.addlEffect>0
        basedamage=(basedamage*1.3).round
      end
    end
    # Type-boosting items
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
      basedamage=(basedamage*1.2).round
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
      basedamage=(basedamage*1.2).round
    end
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
      basedamage=(basedamage*1.5).round
    end
    if attacker.hasWorkingItem(:ROCKINCENSE) && isConst?(type,PBTypes,:ROCK)
      basedamage=(basedamage*1.2).round
    end
    if attacker.hasWorkingItem(:ROSEINCENSE) && isConst?(type,PBTypes,:GRASS)
      basedamage=(basedamage*1.2).round
    end
    if attacker.hasWorkingItem(:SEAINCENSE) && isConst?(type,PBTypes,:WATER)
      basedamage=(basedamage*1.2).round
    end
    if attacker.hasWorkingItem(:WAVEINCENSE) && isConst?(type,PBTypes,:WATER)
      basedamage=(basedamage*1.2).round
    end
    if attacker.hasWorkingItem(:ODDINCENSE) && isConst?(type,PBTypes,:PSYCHIC)
      basedamage=(basedamage*1.2).round
    end
    # Muscle Band
    if attacker.hasWorkingItem(:MUSCLEBAND) && move.pbIsPhysical?(type)
      basedamage=(basedamage*1.1).round
    end
    # Wise Glasses
    if attacker.hasWorkingItem(:WISEGLASSES) && move.pbIsSpecial?(type)
      basedamage=(basedamage*1.1).round
    end
    # Legendary Orbs
    if isConst?(attacker.species,PBSpecies,:PALKIA) &&
       attacker.hasWorkingItem(:LUSTROUSORB) &&
       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:WATER))
      basedamage=(basedamage*1.2).round
    end
    if isConst?(attacker.species,PBSpecies,:DIALGA) &&
       attacker.hasWorkingItem(:ADAMANTORB) &&
       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:STEEL))
      basedamage=(basedamage*1.2).round
    end
    if isConst?(attacker.species,PBSpecies,:GIRATINA) &&
       attacker.hasWorkingItem(:GRISEOUSORB) &&
       (isConst?(type,PBTypes,:DRAGON) || isConst?(type,PBTypes,:GHOST))
      basedamage=(basedamage*1.2).round
    end
    # pbBaseDamageMultiplier - TODO
    # Me First
    # Charge
    if attacker.effects[PBEffects::Charge]>0 && isConst?(type,PBTypes,:ELECTRIC)
      basedamage=(basedamage*2.0).round
    end
    # Helping Hand - n/a
    
    # Water Sport
    if skill>=PBTrainerAI.mediumSkill
      if isConst?(type,PBTypes,:FIRE)
        for i in 0...4
          if @battlers[i].effects[PBEffects::WaterSport] && !@battlers[i].isFainted?
            basedamage=(basedamage*0.33).round
            break
          end
        end
      end
    end
    # Mud Sport
    if skill>=PBTrainerAI.mediumSkill
      if isConst?(type,PBTypes,:ELECTRIC)
        for i in 0...4
          if @battlers[i].effects[PBEffects::MudSport] && !@battlers[i].isFainted?
            basedamage=(basedamage*0.33).round
            break
          end
        end
      end
    end
    # Get base attack stat
    atk=pbRoughStat(attacker,PBStats::ATTACK,skill)
    atk=pbRoughStat(opponent,PBStats::ATTACK,skill) if move.function==0x121 # Foul Play
    if type>=0 && move.pbIsSpecial?(type)
      atk=pbRoughStat(attacker,PBStats::SPATK,skill)
      atk=pbRoughStat(opponent,PBStats::SPATK,skill) if move.function==0x121 # Foul Play
    end
    
    # Hustle
    if skill>=PBTrainerAI.highSkill
      if attacker.hasWorkingAbility(:HUSTLE) && move.pbIsPhysical?(type)
        atk=(atk*1.5).round
      end
    end
    # Thick Fat
    if skill>=PBTrainerAI.bestSkill
      if opponent.hasWorkingAbility(:THICKFAT) &&
         (isConst?(type,PBTypes,:ICE) || isConst?(type,PBTypes,:FIRE))
        atk=(atk*0.5).round
      end
    end
    # Purifying Salt
    if skill>=PBTrainerAI.bestSkill
      if opponent.hasWorkingAbility(:PURIFYINGSALT) && isConst?(type,PBTypes,:GHOST)
        atk=(atk*0.5).round
      end
    end
    # Pinch abilities
    if skill>=PBTrainerAI.mediumSkill
      if attacker.hp<=(attacker.totalhp/3).floor
        if (attacker.hasWorkingAbility(:OVERGROW) && isConst?(type,PBTypes,:GRASS)) ||
           (attacker.hasWorkingAbility(:BLAZE) && isConst?(type,PBTypes,:FIRE)) ||
           (attacker.hasWorkingAbility(:TORRENT) && isConst?(type,PBTypes,:WATER)) ||
           (attacker.hasWorkingAbility(:SWARM) && isConst?(type,PBTypes,:BUG))
          atk=(atk*1.5).round
        end
      end
    end
    # Guts
    if skill>=PBTrainerAI.highSkill
      if attacker.hasWorkingAbility(:GUTS) &&
         attacker.status!=0 && move.pbIsPhysical?(type)
        atk=(atk*1.5).round
      end
    end
    # Plus, Minus
    if skill>=PBTrainerAI.mediumSkill
      if (attacker.hasWorkingAbility(:PLUS) ||
         attacker.hasWorkingAbility(:MINUS)) && move.pbIsSpecial?(type)
        partner=attacker.pbPartner
        if partner.hasWorkingAbility(:PLUS) || partner.hasWorkingAbility(:MINUS)
          atk=(atk*1.5).round
        end
      end
      # Defeatist
      if attacker.hasWorkingAbility(:DEFEATIST) &&
         attacker.hp<=(attacker.totalhp/2).floor
        atk=(atk*0.5).round
      end
      # Battery
      if attacker.pbPartner.hasWorkingAbility(:BATTERY) && move.pbIsSpecial?(type)
        atk=(atk*1.5).round
      end
      # Pure Power, Huge Power
      if attacker.hasWorkingAbility(:PUREPOWER) ||
         attacker.hasWorkingAbility(:HUGEPOWER)
        atk=(atk*2.0).round
      end
      # Slow Start
      if attacker.hasWorkingAbility(:SLOWSTART) &&
         attacker.turncount<5 && move.pbIsPhysical?(type)
        atk=(atk*0.5).round
      end
    end
   
    

    
    if skill>=PBTrainerAI.highSkill
      # Solar Power
      if attacker.hasWorkingAbility(:SOLARPOWER) &&
         pbWeather==PBWeather::SUNNYDAY && move.pbIsSpecial?(type)
        atk=(atk*1.5).round
      end

      # Flash Fire
      if attacker.hasWorkingAbility(:FLASHFIRE) &&
         attacker.effects[PBEffects::FlashFire] && isConst?(type,PBTypes,:FIRE)
        atk=(atk*1.5).round
      end
       # Flower Gift
      if pbWeather==PBWeather::SUNNYDAY && move.pbIsPhysical?(type)
        if attacker.hasWorkingAbility(:FLOWERGIFT) &&
           isConst?(attacker.species,PBSpecies,:CHERRIM)
          atk=(atk*1.5).round
        end
        if attacker.pbPartner.hasWorkingAbility(:FLOWERGIFT) &&
           isConst?(attacker.pbPartner.species,PBSpecies,:CHERRIM)
          atk=(atk*1.5).round
        end
      end
    end
    
    # Attack-boosting items
    if attacker.hasWorkingItem(:THICKCLUB) &&
       (isConst?(attacker.species,PBSpecies,:CUBONE) ||
       isConst?(attacker.species,PBSpecies,:MAROWAK)) && move.pbIsPhysical?(type)
      atk=(atk*2.0).round
    end
    if attacker.hasWorkingItem(:DEEPSEATOOTH) &&
       isConst?(attacker.species,PBSpecies,:CLAMPERL) && move.pbIsSpecial?(type)
      atk=(atk*2.0).round
    end
    if attacker.hasWorkingItem(:LIGHTBALL) &&
       isConst?(attacker.species,PBSpecies,:PIKACHU)
      atk=(atk*2.0).round
    end
    if attacker.hasWorkingItem(:SOULDEW) &&
       (isConst?(attacker.species,PBSpecies,:LATIAS) ||
       isConst?(attacker.species,PBSpecies,:LATIOS)) && move.pbIsSpecial?(type)
      atk=(atk*1.5).round
    end
    if attacker.hasWorkingItem(:CHOICEBAND) && move.pbIsPhysical?(type)
      atk=(atk*1.5).round
    end
    if attacker.hasWorkingItem(:CHOICESPECS) && move.pbIsSpecial?(type)
      atk=(atk*1.5).round
    end
    # Get base defense stat
    defense=pbRoughStat(opponent,PBStats::DEFENSE,skill)
    applysandstorm=false
    if type>=0 && move.pbIsSpecial?(type)
      if move.function!=0x122 # Psyshock
        defense=pbRoughStat(opponent,PBStats::SPDEF,skill)
        applysandstorm=true
      end
    end
    applysnow=false
    if type>=0 && move.pbIsPhysical?(type)
      defense=pbRoughStat(opponent,PBStats::DEFENSE,skill)
      applysnow=true
    end
    
    if skill>=PBTrainerAI.highSkill
      # Sandstorm weather
      if pbWeather==PBWeather::SANDSTORM &&
         opponent.pbHasType?(:ROCK) && applysandstorm
        defense=(defense*1.5).round
      end

      # Snow weather
      if pbWeather==PBWeather::HAIL &&
         opponent.pbHasType?(:ICE) && applysnow
        defense=(defense*1.5).round if SNOW_REPLACES_HAIL
      end
    end

    if skill>=PBTrainerAI.bestSkill
      # Marvel Scale
      if opponent.hasWorkingAbility(:MARVELSCALE) &&
         opponent.status>0 && move.pbIsPhysical?(type)
        defense=(defense*1.5).round
      end
      # Flower Gift
      if pbWeather==PBWeather::SUNNYDAY && move.pbIsSpecial?(type)
        if opponent.hasWorkingAbility(:FLOWERGIFT) &&
           isConst?(opponent.species,PBSpecies,:CHERRIM)
          defense=(defense*1.5).round
        end
        if opponent.pbPartner.hasWorkingAbility(:FLOWERGIFT) &&
           isConst?(opponent.pbPartner.species,PBSpecies,:CHERRIM)
          defense=(defense*1.5).round
        end
      end
    end
    # Defense-boosting items
    if skill>=PBTrainerAI.highSkill
      if opponent.hasWorkingItem(:EVIOLITE)
        evos=pbGetEvolvedFormData(opponent.species)
        if evos && evos.length>0
          defense=(defense*1.5).round
        end
      end
      if opponent.hasWorkingItem(:DEEPSEASCALE) &&
         isConst?(opponent.species,PBSpecies,:CLAMPERL) && move.pbIsSpecial?(type)
        defense=(defense*2.0).round
      end
      if opponent.hasWorkingItem(:METALPOWDER) &&
         isConst?(opponent.species,PBSpecies,:DITTO) &&
         !opponent.effects[PBEffects::Transform] && move.pbIsPhysical?(type)
        defense=(defense*2.0).round
      end
      if opponent.hasWorkingItem(:SOULDEW) &&
         (isConst?(opponent.species,PBSpecies,:LATIAS) ||
         isConst?(opponent.species,PBSpecies,:LATIOS)) && move.pbIsSpecial?(type)
        defense=(defense*1.5).round
      end
    end
    # Main damage calculation
    damage=(((2.0*attacker.level/5+2).floor*basedamage*atk/defense).floor/50).floor+2 if basedamage >= 0
    # Multi-targeting attacks
    if skill>=PBTrainerAI.highSkill
      if move.pbTargetsMultiple?(attacker)
        damage=(damage*0.75).round
      end
    end
    # Weather
    if skill>=PBTrainerAI.mediumSkill
      case pbWeather
      when PBWeather::SUNNYDAY
        if isConst?(type,PBTypes,:FIRE)
          damage=(damage*1.5).round
        elsif isConst?(type,PBTypes,:WATER)
          damage=(damage*0.5).round
        end
      when PBWeather::RAINDANCE
        if isConst?(type,PBTypes,:FIRE)
          damage=(damage*0.5).round
        elsif isConst?(type,PBTypes,:WATER)
          damage=(damage*1.5).round
        end
      end
    end

    # Critical hits - n/a
    # Random variance - n/a
    # STAB
    if skill>=PBTrainerAI.mediumSkill
      if attacker.pbHasType?(type)
        if attacker.hasWorkingAbility(:ADAPTABILITY) &&
           skill>=PBTrainerAI.highSkill
          damage=(damage*2).round
        else
          damage=(damage*1.5).round
        end
      end
    end
    # Type effectiveness
    typemod=pbTypeModifier(type,attacker,opponent)
      damage=(damage*typemod*1.0/8).round
    # Burn
    if skill>=PBTrainerAI.mediumSkill
      if attacker.status==PBStatuses::BURN && move.pbIsPhysical?(type) &&
         !attacker.hasWorkingAbility(:GUTS)
        damage=(damage*0.5).round
      end
    end
    # Make sure damage is at least 1
    damage=1 if damage<1
    # Reflect
    if skill>=PBTrainerAI.highSkill
      if opponent.pbOwnSide.effects[PBEffects::Reflect]>0 && move.pbIsPhysical?(type)
        if !opponent.pbPartner.isFainted?
          damage=(damage*0.66).round
        else
          damage=(damage*0.5).round
        end
      end
    end
    # Aurora Veil
    if skill>=PBTrainerAI.highSkill
      if opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0 && move.pbIsPhysical?(type)
        if !opponent.pbPartner.isFainted?
          damage=(damage*0.66).round
        else
          damage=(damage*0.5).round
        end
      end
    end
    # Aurora Veil
    if skill>=PBTrainerAI.highSkill
      if opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0 && move.pbIsSpecial?(type)
        if !opponent.pbPartner.isFainted?
          damage=(damage*0.66).round
        else
          damage=(damage*0.5).round
        end
      end
    end
    # Light Screen
    if skill>=PBTrainerAI.highSkill
      if opponent.pbOwnSide.effects[PBEffects::LightScreen]>0 && move.pbIsSpecial?(type)
        if !opponent.pbPartner.isFainted?
          damage=(damage*0.66).round
        else
          damage=(damage*0.5).round
        end
      end
    end
    # Multiscale
    if skill>=PBTrainerAI.bestSkill
      if opponent.hasWorkingAbility(:MULTISCALE) &&
         opponent.hp==opponent.totalhp
        damage=(damage*0.5).round
      end
      if opponent.hasWorkingAbility(:SHADOWSHIELD) &&
         opponent.hp==opponent.totalhp
        damage=(damage*0.5).round
      end
    end
    # Tinted Lens
    if skill>=PBTrainerAI.bestSkill
      if attacker.hasWorkingAbility(:TINTEDLENS) && typemod<8
        damage=(damage*2.0).round
      end
    end
    # Friend Guard
    if skill>=PBTrainerAI.bestSkill
      if opponent.pbPartner.hasWorkingAbility(:FRIENDGUARD)
        damage=(damage*0.75).round
      end
    end
    # Sniper - n/a
    # Solid Rock, Filter
    if skill>=PBTrainerAI.bestSkill
      if (opponent.hasWorkingAbility(:SOLIDROCK) || opponent.hasWorkingAbility(:FILTER) ||
         opponent.hasWorkingAbility(:PRISMARMOR)) &&
         typemod>8
        damage=(damage*0.75).round
      end
    end
    
    if skill>=PBTrainerAI.bestSkill
      if attacker.hasWorkingAbility(:STAKEOUT) && opponent.effects[PBEffects::Stakeout]
        damage=(damage*2.0).round
      end
      if attacker.hasWorkingAbility(:NEUROFORCE) && opponent.damagestate.typemod>8
        damage=(damage*1.25).round
      end
    end
    # Final damage-altering items
    if attacker.hasWorkingItem(:METRONOME)
      if attacker.effects[PBEffects::Metronome]>4
        damage=(damage*2.0).round
      else
        met=1.0+attacker.effects[PBEffects::Metronome]*0.2
        damage=(damage*met).round
      end
    end
    if attacker.hasWorkingItem(:EXPERTBELT) && typemod>8
      damage=(damage*1.2).round
    end
    if attacker.hasWorkingItem(:LIFEORB)
      damage=(damage*1.3).round
    end

    if typemod>8 && skill>=PBTrainerAI.highSkill
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
         (opponent.hasWorkingItem(:COLBURBERRY) && isConst?(type,PBTypes,:DARK))
        damage=(damage*0.5).round
      end
    end
    if skill>=PBTrainerAI.highSkill
      if opponent.hasWorkingItem(:CHILANBERRY) && isConst?(type,PBTypes,:NORMAL)
        damage=(damage*0.5).round
      end
    end
    # pbModifyDamage - TODO
    # "AI-specific calculations below"
    # Increased critical hit rates
    if skill>=PBTrainerAI.mediumSkill
      c=0
      c+=attacker.effects[PBEffects::FocusEnergy]
      c+=1 if move.hasHighCriticalRate?
      c+=1 if (attacker.inHyperMode? rescue false) && isConst?(self.type,PBTypes,:SHADOW)
      c+=2 if isConst?(attacker.species,PBSpecies,:CHANSEY) && 
              attacker.hasWorkingItem(:LUCKYPUNCH)
      c+=2 if (isConst?(attacker.species,PBSpecies,:FARFETCHD) || isConst?(attacker.species,PBSpecies,:SIRFETCHD)) && 
              (attacker.hasWorkingItem(:LEEK) || attacker.hasWorkingItem(:STICK))
      c+=1 if attacker.hasWorkingAbility(:SUPERLUCK)
      c+=1 if attacker.hasWorkingItem(:SCOPELENS)
      c+=1 if attacker.hasWorkingItem(:RAZORCLAW)
      c=4 if c>4
      basedamage+=(basedamage*0.1*c)
    end
    return damage
  end

  def pbRoughAccuracy(move,attacker,opponent,skill)
    # Get base accuracy
    baseaccuracy=move.accuracy
    if skill>=PBTrainerAI.mediumSkill
      if pbWeather==PBWeather::SUNNYDAY &&
         (move.function==0x08 || move.function==0x15) # Thunder, Hurricane
        accuracy=50
      end
    end
    # Accuracy stages
    accstage=attacker.stages[PBStats::ACCURACY]
    accstage=0 if opponent.hasWorkingAbility(:UNAWARE)
    accuracy=(accstage>=0) ? (accstage+3)*100.0/3 : 300.0/(3-accstage)
    evastage=opponent.stages[PBStats::EVASION]
    evastage-=2 if @field.effects[PBEffects::Gravity]>0
    evastage=-6 if evastage<-6
    evastage=0 if opponent.effects[PBEffects::Foresight] ||
                  opponent.effects[PBEffects::MiracleEye] ||
                  move.function==0xA9 || # Chip Away
                  attacker.hasWorkingAbility(:UNAWARE)
    evasion=(evastage>=0) ? (evastage+3)*100.0/3 : 300.0/(3-evastage)
    accuracy*=baseaccuracy/evasion
    # Accuracy modifiers
    if skill>=PBTrainerAI.mediumSkill
      accuracy*=1.3 if attacker.hasWorkingAbility(:COMPOUNDEYES)
      
      if opponent.hasWorkingAbility(:WONDERSKIN) && move.pbIsStatus? && attacker.pbIsOpposing?(opponent.index)
        accuracy=50
      end      
      accuracy*=1.1 if attacker.hasWorkingAbility(:VICTORYSTAR)
      if skill>=PBTrainerAI.highSkill
        partner=attacker.pbPartner
        accuracy*=1.1 if partner && partner.hasWorkingAbility(:VICTORYSTAR)
      end
      accuracy*=1.2 if attacker.effects[PBEffects::MicleBerry]
      accuracy*=1.1 if attacker.hasWorkingItem(:WIDELENS)
      if skill>=PBTrainerAI.highSkill
        accuracy*=0.8 if attacker.hasWorkingAbility(:HUSTLE) &&
                         move.basedamage>0 &&
                         move.pbIsPhysical?(move.pbType(move.type,attacker,opponent))
      end
      if skill>=PBTrainerAI.bestSkill
        accuracy/=2 if opponent.hasWorkingAbility(:WONDERSKIN) &&
                       move.basedamage==0 &&
                       attacker.pbIsOpposing?(opponent.index)
        accuracy/=1.2 if opponent.hasWorkingAbility(:TANGLEDFEET) &&
                         opponent.effects[PBEffects::Confusion]>0
        accuracy/=1.2 if pbWeather==PBWeather::SANDSTORM &&
                         opponent.hasWorkingAbility(:SANDVEIL)
        accuracy/=1.2 if (pbWeather==PBWeather::HAIL) &&
                         opponent.hasWorkingAbility(:SNOWCLOAK)
      end
      if skill>=PBTrainerAI.highSkill
        accuracy/=1.1 if opponent.hasWorkingItem(:BRIGHTPOWDER)
        accuracy/=1.1 if opponent.hasWorkingItem(:LAXINCENSE)
      end
    end
    accuracy=100 if accuracy>100
    # Override accuracy
    accuracy=125 if move.accuracy==0   # Doesn't do accuracy check (always hits)
    accuracy=125 if move.function==0xA5 # Swift
    if skill>=PBTrainerAI.mediumSkill
      accuracy=125 if opponent.effects[PBEffects::LockOn]>0 &&
                      opponent.effects[PBEffects::LockOnPos]==attacker.index
      if skill>=PBTrainerAI.highSkill
        accuracy=125 if attacker.hasWorkingAbility(:NOGUARD) ||
                        opponent.hasWorkingAbility(:NOGUARD)
      end
      accuracy=125 if opponent.effects[PBEffects::Telekinesis]>0
      case pbWeather
      when PBWeather::HAIL
        accuracy=125 if move.function==0x0D # Blizzard
      when PBWeather::RAINDANCE
        accuracy=125 if move.function==0x08 || move.function==0x15 # Thunder, Hurricane
      end
      
      accuracy=100 if attacker.pbHasType?(:POISON) && move.id==getID(PBMoves,:TOXIC)
      accuracy=100 if (move.function==0x10 || move.function==0x9B || move.id==getID(PBMoves,:BODYSLAM) || move.id==getID(PBMoves,:FLYINGPRESS)) &&
                   opponent.effects[PBEffects::Minimize] # Flying Press, Stomp
      if move.function==0x70 # OHKO moves
        accuracy=move.accuracy+attacker.level-opponent.level
        accuracy=0 if opponent.hasWorkingAbility(:STURDY)
        accuracy=0 if opponent.level>attacker.level
      end
    end
    return accuracy
  end

################################################################################
# Choose a move to use.
################################################################################
  def pbChooseMoves(index)
    attacker=@battlers[index]
    scores=[0,0,0,0]
    targets=nil
    myChoices=[]
    totalscore=0
    target=-1
    skill=0
    
    wildbattle=!@opponent && pbIsOpposing?(index) && ((attacker.level < WILD_AI_LEVEL) &&
               !($game_switches[WILD_AI_SWITCH] ||  @rules["hightAI"]))
    if wildbattle # If wild battle
      for i in 0...4
        if pbCanChooseMove?(index,i,false)
          scores[i]=100
          myChoices.push(i)
          totalscore+=100
        end
      end
    else
      owner=pbGetOwner(attacker.index)
      if owner
        skill=pbGetOwner(attacker.index).skill || 0
      else
        dexdata=pbOpenDexData
        pbDexDataOffset(dexdata,attacker.pokemon.species,16)
        rareness=dexdata.fgetb # Get rareness from dexdata file
        dexdata.close

        skill=255 - (rareness-1) # para que hasta los mas comunes tengan un minimo de inteligencia
        skill=255 if $game_switches[WILD_AI_SWITCH] ||  @rules["hightAI"]
      end
      
      opponent=attacker.pbOppositeOpposing
      if @doublebattle && !opponent.isFainted? && !opponent.pbPartner.isFainted?
        # Choose a target and move.  Also care about partner.
        otheropp=opponent.pbPartner
        scoresAndTargets=[]
        targets=[-1,-1,-1,-1]
        for i in 0...4
          if pbCanChooseMove?(index,i,false)
            score1=pbGetMoveScore(attacker.moves[i],attacker,opponent,skill)
            score2=pbGetMoveScore(attacker.moves[i],attacker,otheropp,skill)
            #if (attacker.moves[i].target&0x20)!=0 # Target's user's side
            if (attacker.moves[i].target&0x08)!=0 # Targets all users
              if attacker.pbPartner.isFainted? || attacker.pbPartner.hasWorkingAbility(:TELEPATHY) # No partner
                score1*=5/3
                score2*=5/3
              else
                # If this move can also target the partner, get the partner's
                # score too
                s=pbGetMoveScore(attacker.moves[i],attacker,attacker.pbPartner,skill)
                if (isConst?(attacker.moves[i],PBTypes,:FIRE) && 
                  attacker.pbPartner.hasWorkingAbility(:FLASHFIRE)) ||
                 (isConst?(attacker.moves[i],PBTypes,:WATER) &&
                 (attacker.pbPartner.hasWorkingAbility(:WATERABSORB) ||
                  attacker.pbPartner.hasWorkingAbility(:STORMDRAIN)  ||
                  attacker.pbPartner.hasWorkingAbility(:DRYSKIN))) ||          
                 (isConst?(attacker.moves[i],PBTypes,:GRASS) && 
                  attacker.pbPartner.hasWorkingAbility(:SAPSIPPER)) ||
                 (isConst?(attacker.moves[i],PBTypes,:GROUND) && 
                  attacker.pbPartner.hasWorkingAbility(:LEVITATE)) ||
                 (isConst?(attacker.moves[i],PBTypes,:ELECTRIC) &&
                 (attacker.pbPartner.hasWorkingAbility(:VOLTABSORB) ||
                  attacker.pbPartner.hasWorkingAbility(:MOTORDRIVE)))
                  score1*=2.00
                  score2*=2.00
                else
                  if s>=140 # Highly effective
                    score1*=1/3
                    score2*=1/3
                  elsif s>=100 # Very effective
                    score1*=2/3
                    score2*=2/3
                  elsif s>=40 # Less effective
                    score1*=4/3
                    score2*=4/3
                  else # Hardly effective
                    score1*=5/3
                    score2*=5/3
                  end
                  if (attacker.pbPartner.hp.to_f)/attacker.pbPartner.totalhp>0.10 || ((attacker.pbPartner.pbSpeed<attacker.pbSpeed) ^ (@trickroom!=0))
                    s = 100-s
                    s=0 if s<0
                    s/=100.0
                    # multiplier to control how much to arbitrarily care about hitting partner; lower cares more
                    s * 0.7 
                    # care more if we're faster and would knock it out before it attacks
                    s * 0.7 if (attacker.pbPartner.pbSpeed<attacker.pbSpeed) ^ (@trickroom!=0)
                    score1*=s
                    score2*=s
                  end
                end
              end
            end
            myChoices.push(i)
            scoresAndTargets.push([i*2,i,score1,opponent.index])
            scoresAndTargets.push([i*2+1,i,score2,otheropp.index])
          end
        end
        scoresAndTargets.sort!{|a,b|
           if a[2]==b[2] # if scores are equal
             a[0]<=>b[0] # sort by index (for stable comparison)
           else
             b[2]<=>a[2]
           end
        }
        for i in 0...scoresAndTargets.length
          idx=scoresAndTargets[i][1]
          thisScore=scoresAndTargets[i][2]
          if thisScore>0
            if scores[idx]==0 || ((scores[idx]==thisScore && pbAIRandom(10)<5) ||
               (scores[idx]!=thisScore && pbAIRandom(10)<3))
              scores[idx]=thisScore
              targets[idx]=scoresAndTargets[i][3]
            end
          end
        end
        for i in 0...4
          scores[i]=0 if scores[i]<0
          totalscore+=scores[i]
        end
      else
        # Choose a move. There is only 1 opposing Pokémon.
        opponent=opponent.pbPartner if @doublebattle && opponent.isFainted?
        for i in 0...4
          if pbCanChooseMove?(index,i,false)
            scores[i]=pbGetMoveScore(attacker.moves[i],attacker,opponent,skill)
            myChoices.push(i)
          end
          scores[i]=0 if scores[i]<0
          totalscore+=scores[i]
        end
      end
    end
    maxscore=0
    for i in 0...4
      maxscore=scores[i] if scores[i] && scores[i]>maxscore
    end
    # Minmax choices depending on AI
    if !wildbattle && skill>=PBTrainerAI.mediumSkill
      threshold=(skill>=PBTrainerAI.bestSkill) ? 1.5 : (skill>=PBTrainerAI.highSkill) ? 2 : 3
      newscore=(skill>=PBTrainerAI.bestSkill) ? 5 : (skill>=PBTrainerAI.highSkill) ? 10 : 15
      for i in 0...scores.length
        if scores[i]>newscore && scores[i]*threshold<maxscore
          totalscore-=(scores[i]-newscore)
          scores[i]=newscore
        end
      end
      maxscore=0
      for i in 0...4
        maxscore=scores[i] if scores[i] && scores[i]>maxscore
      end
    end
    if $INTERNAL
      x="[AI] #{attacker.pbThis}'s moves: "
      j=0
      for i in 0...4
        if attacker.moves[i].id!=0
          x+=", " if j>0
          x+=PBMoves.getName(attacker.moves[i].id)+"="+scores[i].to_s
          j+=1
        end
      end
      PBDebug.log(x)
    end
    if !wildbattle && maxscore>100
      stdev=pbStdDev(scores)
      if stdev>=40 && pbAIRandom(10)!=0
        # If standard deviation is 40 or more,
        # there is a highly preferred move. Choose it.
        preferredMoves=[]
        for i in 0...4
          if attacker.moves[i].id!=0 && (scores[i]>=maxscore*0.8 || scores[i]>=200)
            preferredMoves.push(i)
            preferredMoves.push(i) if scores[i]==maxscore # Doubly prefer the best move
          end
        end
        if preferredMoves.length>0
          i=preferredMoves[pbAIRandom(preferredMoves.length)]
          PBDebug.log("[AI] Prefer #{PBMoves.getName(attacker.moves[i].id)}")
          pbRegisterMove(index,i,false)
          target=targets[i] if targets
          pbRegisterTarget(index,target) if @doublebattle && target>=0
          return
        end
      end
    end
    if !wildbattle && attacker.turncount
      badmoves=false
      if ((maxscore<=30 && attacker.turncount>2) ||
         (maxscore<=60 && attacker.turncount>5)) && pbAIRandom(10)<8
        badmoves=true
      end
      if !badmoves && totalscore<100 && attacker.turncount>1
        badmoves=true
        movecount=0
        for i in 0...4
          if attacker.moves[i].id!=0
            badmoves=false if scores[i]>0 && attacker.moves[i].basedamage>0
            movecount+=1
          end
        end
        badmoves=badmoves && pbAIRandom(100) < 10
      end
      if badmoves
        # Attacker has terrible moves, try switching instead
        if pbEnemyShouldWithdrawEx?(index,true)
          if $INTERNAL
            PBDebug.log("[AI] Switching due to terrible moves")
            PBDebug.log([index,@choices[index][0],@choices[index][1],
               pbCanChooseNonActive?(index),
               @battlers[index].pbNonActivePokemonCount()].inspect)
          end
          return
        end
      end
    end
    if maxscore<=0
      # If all scores are 0 or less, choose a move at random
      if myChoices.length>0
        pbRegisterMove(index,myChoices[pbAIRandom(myChoices.length)],false)
      else
        pbAutoChooseMove(index)
      end
    else
      randnum=pbAIRandom(totalscore)
      cumtotal=0
      for i in 0...4
        if scores[i]>0
          cumtotal+=scores[i]
          if randnum<cumtotal
            pbRegisterMove(index,i,false)
            target=targets[i] if targets
            break
          end
        end
      end
    end
    PBDebug.log("[AI] Will use #{@choices[index][2].name}") if @choices[index][2]
    pbRegisterTarget(index,target) if @doublebattle && target>=0
  end

################################################################################
# Decide whether the opponent should Mega Evolve - Ultra Burst - Z-Move - Tera their Pokémon.
################################################################################
  def pbEnemyShouldMegaEvolve?(index)
    # Simple "always should if possible"
    return pbCanMegaEvolve?(index)
  end
  
  def pbEnemyShouldUltraBurst?(index)
    # Simple "always should if possible"
    return pbCanUltraBurst?(index)
  end
  
  def pbEnemyShouldZMove?(index)
    return pbCanZMove?(index) #Conditions based on effectiveness and type handled later  
  end
  
  def fpEnemyShouldTeraCristal?(index)
    return true if @battlers[index].pokemon.tera_ace 
  end

################################################################################
# Decide whether the opponent should use an item on the Pokémon.
################################################################################
  def pbEnemyShouldUseItem?(index)
    item=pbEnemyItemToUse(index)
    if item>0
      pbRegisterItem(index,item,nil)
      return true
    end
    return false
  end

  def pbEnemyItemAlreadyUsed?(index,item,items)
    if @choices[1][0]==3 && @choices[1][1]==item
      qty=0
      for i in items
        qty+=1 if i==item
      end
      return true if qty<=1
    end
    return false
  end
  

  def pbEnemyItemToUse(index)
    return 0 if !@internalbattle
    items=pbGetOwnerItems(index)
    return 0 if !items
    battler=@battlers[index]
    opponent1 = battler.pbOppositeOpposing
    itemscore = 100
    return 0 if battler.isFainted? ||
                battler.effects[PBEffects::Embargo]>0
    hashpitem=false
    for i in items
      next if pbEnemyItemAlreadyUsed?(index,i,items)
      if isConst?(i,PBItems,:POTION) || 
         isConst?(i,PBItems,:SUPERPOTION) || 
         isConst?(i,PBItems,:HYPERPOTION) || 
         isConst?(i,PBItems,:MAXPOTION) ||
         isConst?(i,PBItems,:FULLRESTORE)
        hashpitem=true
      end
    end
    for i in items
      next if pbEnemyItemAlreadyUsed?(index,i,items)
      if isConst?(i,PBItems,:FULLRESTORE)
        return i if battler.hp<=battler.totalhp/4
        return i if battler.hp<=battler.totalhp/2 && pbAIRandom(10)<3
        return i if battler.hp<=battler.totalhp*2/3 &&
                    (battler.status>0 || battler.effects[PBEffects::Confusion]>0) &&
                    pbAIRandom(10)<3
                    
      elsif isConst?(i,PBItems,:POTION) || 
         isConst?(i,PBItems,:SUPERPOTION) || 
         isConst?(i,PBItems,:HYPERPOTION) || 
         isConst?(i,PBItems,:MAXPOTION) 
        canheal = true
        healmove = false
        for j in battler.moves
          healmove=true if j.isHealingMove?
        end
        if healmove
          canheal=false if battler.pbSpeed > opponent1.pbSpeed
        end
        return i if battler.hp<=battler.totalhp/4 && canheal == true
        return i if battler.hp<=battler.totalhp/2 && (pbAIRandom(10)<3 && canheal == true)

      elsif isConst?(i,PBItems,:FULLHEAL)
        
        if battler.status==PBStatuses::PARALYSIS
          notheal = true if battler.hasWorkingAbility(:QUICKFEET) || battler.hasWorkingAbility(:GUTS)
          notheal = true if battler.pbSpeed>opponent1.pbSpeed && (battler.pbSpeed*0.5)<opponent1.pbSpeed       
        elsif battler.status==PBStatuses::BURN
          notheal = true if battler.hasWorkingAbility(:QUICKFEET) || battler.hasWorkingAbility(:GUTS) || battler.hasWorkingAbility(:MAGICGUARD) || battler.hasWorkingAbility(:FLAREBOOST)
        elsif battler.status==PBStatuses::POISON
          notheal = true if battler.hasWorkingAbility(:QUICKFEET) || battler.hasWorkingAbility(:GUTS) || battler.hasWorkingAbility(:MAGICGUARD) || battler.hasWorkingAbility(:TOXICBOOST)
          if battler.effects[PBEffects::Toxic]>0 && !battler.hasWorkingAbility(:POISONHEAL)
            notheal = false
          end         
        elsif battler.status>0
          notheal = true if battler.hasWorkingAbility(:QUICKFEET) || battler.hasWorkingAbility(:GUTS)
        end
        return i if !hashpitem && notheal == true && 
                    (battler.status>0 || battler.effects[PBEffects::Confusion]>0)
                    
      elsif isConst?(i,PBItems,:XATTACK) ||
            isConst?(i,PBItems,:XDEFEND) ||
            isConst?(i,PBItems,:XSPEED) ||
            isConst?(i,PBItems,:XSPECIAL) ||
            isConst?(i,PBItems,:XSPDEF) ||
            isConst?(i,PBItems,:XACCURACY)
        stat=0
        stat=PBStats::ATTACK if isConst?(i,PBItems,:XATTACK)
        stat=PBStats::DEFENSE if isConst?(i,PBItems,:XDEFEND)
        stat=PBStats::SPEED if isConst?(i,PBItems,:XSPEED)
        stat=PBStats::SPATK if isConst?(i,PBItems,:XSPECIAL)
        stat=PBStats::SPDEF if isConst?(i,PBItems,:XSPDEF)
        stat=PBStats::ACCURACY if isConst?(i,PBItems,:XACCURACY)
        if stat>0 && !battler.pbTooHigh?(stat)
          return i if pbAIRandom(10)<3-battler.stages[stat]
        end
      end
    end
    return 0
  end



################################################################################
# Decide whether the opponent should switch Pokémon.
################################################################################
  def pbEnemyShouldWithdraw?(index)
    return pbEnemyShouldWithdrawEx?(index,false)
  end

  def pbEnemyShouldWithdrawEx?(index,alwaysSwitch)
    return false if !@opponent
    shouldswitch=alwaysSwitch
    typecheck=false
    batonpass=-1
    movetype=-1
    skill=pbGetOwner(index).skill || 0
    if @opponent && !shouldswitch && @battlers[index].turncount>0
      if skill>=PBTrainerAI.highSkill
        opponent=@battlers[index].pbOppositeOpposing
        opponent=opponent.pbPartner if opponent.isFainted?
        if !opponent.isFainted? && opponent.lastMoveUsed>0 && 
           (opponent.level-@battlers[index].level).abs<=6
          move=PBMoveData.new(opponent.lastMoveUsed)
          typemod=pbTypeModifier(move.type,@battlers[index],@battlers[index])
          movetype=move.type
          if move.basedamage>70 && typemod>8
            shouldswitch=(pbAIRandom(100)<30)
          elsif move.basedamage>50 && typemod>8
            shouldswitch=(pbAIRandom(100)<20)
          end
        end
      end
    end
    if !pbCanChooseMove?(index,0,false) &&
       !pbCanChooseMove?(index,1,false) &&
       !pbCanChooseMove?(index,2,false) &&
       !pbCanChooseMove?(index,3,false) &&
       @battlers[index].turncount &&
       @battlers[index].turncount>5
      shouldswitch=true
    end

    if skill>=PBTrainerAI.highSkill && @battlers[index].effects[PBEffects::PerishSong]!=1
      for i in 0...4
        move=@battlers[index].moves[i]
        if move.id!=0 && pbCanChooseMove?(index,i,false) &&
          move.function==0xED # Baton Pass
          batonpass=i
          break
        end
      end
    end

    if skill>=PBTrainerAI.highSkill
      if @battlers[index].effects[PBEffects::LeechSeed]>=0
        seedHP=(@battlers[index].totalhp/16)
        shouldswitch=true if seedHP<@battlers[index].hp && pbAIRandom(100)<80
      end
    end
    if skill>=PBTrainerAI.highSkill
      if @battlers[index].status==PBStatuses::POISON &&
         @battlers[index].statusCount>0
        toxicHP=(@battlers[index].totalhp/16)
        nextToxicHP=toxicHP*(@battlers[index].effects[PBEffects::Toxic]+1)
        if nextToxicHP>=@battlers[index].hp &&
           toxicHP<@battlers[index].hp && pbAIRandom(100)<80
          shouldswitch=true
        end
      end
    end
    # Consider boosts- if Pokemon can sweep, don't switch out.
    boosts = @battlers[index].stages[PBStats::ATTACK]
    boosts += @battlers[index].stages[PBStats::SPATK]
    boosts += @battlers[index].stages[PBStats::SPEED]
    aspeed = pbRoughStat(@battlers[index],PBStats::SPEED,skill)
    ospeed = pbRoughStat(@battlers[index].pbOppositeOpposing,PBStats::SPEED,skill)
    if aspeed > ospeed
      boosts = boosts * 6 #fast enough to sweep; prioritise these stats
    else
      boosts = boosts * 3 #sweeping stats prioritized
    end
    boosts += @battlers[index].stages[PBStats::DEFENSE]
    boosts += @battlers[index].stages[PBStats::SPDEF]
    shouldswitch=false if boosts >= 6
    ##
    if skill>=PBTrainerAI.mediumSkill
      if @battlers[index].effects[PBEffects::Encore]>0
        scoreSum=0
        scoreCount=0
        attacker=@battlers[index]
        encoreIndex=@battlers[index].effects[PBEffects::EncoreIndex]
        if !attacker.pbOpposing1.isFainted?
          scoreSum+=pbGetMoveScore(attacker.moves[encoreIndex],
             attacker,attacker.pbOpposing1,skill)
          scoreCount+=1
        end
        if !attacker.pbOpposing2.isFainted?
          scoreSum+=pbGetMoveScore(attacker.moves[encoreIndex],
             attacker,attacker.pbOpposing2,skill)
          scoreCount+=1
        end
        shouldswitch=true if scoreCount>0 && scoreSum/scoreCount<=20 && pbAIRandom(10)<8
      end
    end
    if skill>=PBTrainerAI.highSkill
      if !@doublebattle && !@battlers[index].pbOppositeOpposing.isFainted? 
        opp=@battlers[index].pbOppositeOpposing
        if (opp.effects[PBEffects::HyperBeam]>0 ||
           (opp.hasWorkingAbility(:TRUANT) &&
           opp.effects[PBEffects::Truant])) && pbAIRandom(100)<80
          shouldswitch=false
        end
      end
    end
    if @rules["suddendeath"]
      if @battlers[index].hp<=(@battlers[index].totalhp/4) && pbAIRandom(10)<3 && 
         @battlers[index].turncount>0
        shouldswitch=true
      elsif @battlers[index].hp<=(@battlers[index].totalhp/2) && pbAIRandom(10)<8 && 
         @battlers[index].turncount>0
        shouldswitch=true
      end
    end
    if skill>=PBTrainerAI.mediumSkill
      shouldswitch=true if @battlers[index].effects[PBEffects::PerishSong]==1
    end
    if shouldswitch
      list=[]
      party=pbParty(index)
      for i in 0...party.length
        if pbCanSwitch?(index,i,false)
          # If perish count is 1, it may be worth it to switch
          # even with Spikes, since Perish Song's effect will end
          if @battlers[index].effects[PBEffects::PerishSong]!=1
            # Will contain effects that recommend against switching
            spikes=@battlers[index].pbOwnSide.effects[PBEffects::Spikes]
            if (spikes==1 && party[i].hp<=(party[i].totalhp/8)) ||
               (spikes==2 && party[i].hp<=(party[i].totalhp/6)) ||
               (spikes==3 && party[i].hp<=(party[i].totalhp/4))
              if !party[i].hasType?(:FLYING) &&
                 !party[i].hasWorkingAbility(:LEVITATE)
                # Don't switch to this if too little HP
                next
              end
            end
          end
          if movetype>=0 && pbTypeModifier(movetype,@battlers[index],@battlers[index])==0
            weight=65
            # Greater weight if new Pokemon's type is effective against opponent
            weight=85 if pbTypeModifier2(party[i],@battlers[index].pbOppositeOpposing)>8
            list.unshift(i) if pbAIRandom(100)<weight# put this Pokemon first
          elsif movetype>=0 && pbTypeModifier(movetype,@battlers[index],@battlers[index])<8
            weight=40
            # Greater weight if new Pokemon's type is effective against opponent
            weight=60 if pbTypeModifier2(party[i],@battlers[index].pbOppositeOpposing)>8
            list.unshift(i)  if pbAIRandom(100)<weight # put this Pokemon first
          else
            list.push(i) # put this Pokemon last
          end
        end
      end
      if list.length>0
        if batonpass!=-1
          return pbRegisterSwitch(index,list[0]) if !pbRegisterMove(index,batonpass,false)
          return true
        else
          return pbRegisterSwitch(index,list[0])
        end
      end
    end
    return false
  end

  def pbDefaultChooseNewEnemy(index,party)
    enemies=[]
    for i in 0..party.length-1
      enemies.push(i) if pbCanSwitchLax?(index,i,false)
    end
    return pbChooseBestNewEnemy(index,party,enemies) if enemies.length>0
    return -1
  end

  def pbChooseBestNewEnemy(index,party,enemies)
    return -1 if !enemies || enemies.length==0
    $PokemonTemp=PokemonTemp.new if !$PokemonTemp
    o1=@battlers[index].pbOpposing1
    o2=@battlers[index].pbOpposing2
    o1=nil if o1 && o1.isFainted?
    o2=nil if o2 && o2.isFainted?
    best=-1
    bestSum=0
    for e in enemies
      pkmn=party[e]
      sum=0
      for move in pkmn.moves
        next if move.id==0
        md=PBMoveData.new(move.id)
        next if md.basedamage==0
        if o1
          sum+=PBTypes.getCombinedEffectiveness(md.type,o1.type1,o1.type2,o1.effects[PBEffects::Type3])
        end
        if o2
          sum+=PBTypes.getCombinedEffectiveness(md.type,o2.type1,o2.type2,o2.effects[PBEffects::Type3])
        end
      end
      if best==-1 || sum>bestSum
        best=e
        bestSum=sum
      end
    end
    return best
  end

################################################################################
# Choose an action.
################################################################################
  def pbDefaultChooseEnemyCommand(index)
    if !pbCanShowFightMenu?(index)
      return if pbEnemyShouldUseItem?(index)
      return if pbEnemyShouldWithdraw?(index)
      pbAutoChooseMove(index)
      return
    else
      return if pbEnemyShouldUseItem?(index)
      return if pbEnemyShouldWithdraw?(index)
      return if pbAutoFightMenu(index)
      pbRegisterMegaEvolution(index) if pbEnemyShouldMegaEvolve?(index)
      pbRegisterUltraBurst(index) if pbEnemyShouldUltraBurst?(index)
      return pbChooseEnemyZMove(index) if pbEnemyShouldZMove?(index)
      pbRegisterTeraCristal(index) if fpEnemyShouldTeraCristal?(index)
      pbChooseMoves(index)
    end
  end

  def pbChooseEnemyZMove(index)  #Put specific cases for trainers using status Z-Moves
    chosenmove=false
    chosenindex=-1
    for i in 0..3
      move=@battlers[index].moves[i]
      if @battlers[index].pbCompatibleZMoveFromMove?(move)
        if !chosenmove
          chosenindex = i
          chosenmove=move
        else
          if move.basedamage>chosenmove.basedamage
            chosenindex=i
            chosenmove=move
          end          
        end
      end
    end  
    attacker = @battlers[index]
    opponent=attacker.pbOppositeOpposing
    otheropp=opponent.pbPartner
    oppeff1 = pbTypeModifier(chosenmove.type,attacker,opponent)
    oppeff2 = pbTypeModifier(chosenmove.type,attacker,otheropp)
    oppeff1 = 0 if opponent.hp<(opponent.totalhp/2).round
    oppeff2 = 0 if otheropp.hp<(otheropp.totalhp/2).round
    if (oppeff1<4) && (oppeff2<4)
      pbChooseMoves(index)
    elsif oppeff1>oppeff2
      pbRegisterZMove(index)
      pbRegisterMove(index,chosenindex,false)
      pbRegisterTarget(index,opponent.index)
    elsif oppeff1<oppeff2
      pbRegisterZMove(index)
      pbRegisterMove(index,chosenindex,false)
      pbRegisterTarget(index,otheropp.index)      
    elsif oppeff1==oppeff2
      pbRegisterZMove(index)
      pbRegisterMove(index,chosenindex,false)
      pbRegisterTarget(index,opponent.index)      
    end  
  end  
################################################################################
# Other functions.
################################################################################
  def pbDbgPlayerOnly?(idx)
    return true if !$INTERNAL
    return pbOwnedByPlayer?(idx.index) if idx.respond_to?("index")
    return pbOwnedByPlayer?(idx)
  end

  def pbStdDev(scores)
    n=0
    sum=0
    scores.each{|s| sum+=s; n+=1 }
    return 0 if n==0
    mean=sum.to_f/n.to_f
    varianceTimesN=0
    for i in 0...scores.length
      if scores[i]>0
        deviation=scores[i].to_f-mean
        varianceTimesN+=deviation*deviation
      end
    end
    # Using population standard deviation 
    # [(n-1) makes it a sample std dev, would be 0 with only 1 sample]
    return Math.sqrt(varianceTimesN/n)
  end
end
