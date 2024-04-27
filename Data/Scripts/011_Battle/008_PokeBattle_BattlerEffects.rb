class PokeBattle_Battler
#===============================================================================
# Sleep   /   Dormido
#===============================================================================
  def pbCanSleep?(attacker,showMessages,move=nil,ignorestatus=false)
    return false if isFainted?
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("{1} no se vio afectado.",pbThis)) if showMessages
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡La coraza de {1} le protege!",pbThis)) if showMessages
      return false
    end
    selfsleep=(attacker && attacker.index==self.index)
    if !ignorestatus && status==PBStatuses::SLEEP 
      @battle.pbDisplay(_INTL("¡{1} ya está dormido!",pbThis)) if showMessages
      return false
    end
    if !selfsleep
      if self.status!=0 ||
         (@effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker)))
        @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if showMessages
        return false
      end
    end
    if !self.isAirborne?((attacker && attacker.hasMoldBreaker) || (move && move.doesBypassIgnorableAbilities?))
      if @battle.field.effects[PBEffects::ElectricTerrain]>0                             # Campo Eléctrico
        @battle.pbDisplay(_INTL("¡El Campo Eléctrico evita que {1} se quede dormido!",pbThis(true))) if showMessages
        return false
      elsif @battle.field.effects[PBEffects::MistyTerrain]>0                             # Campo de Niebla
        @battle.pbDisplay(_INTL("¡El Campo de Niebla evita que {1} se quede dormido!",pbThis(true))) if showMessages
        return false
      end
    end
    if (attacker && attacker.hasMoldBreaker) || !hasWorkingAbility(:SOUNDPROOF) ||
      (move && move.doesBypassIgnorableAbilities?)
      for i in 0...4
        if @battle.battlers[i].effects[PBEffects::Uproar]>0
          @battle.pbDisplay(_INTL("¡Pero {1} no puede dormir por el alboroto!",pbThis(true))) if showMessages
          return false
        end
      end 
    end
    if !attacker || attacker.index==self.index || (!attacker.hasMoldBreaker &&
      (!move || !move.doesBypassIgnorableAbilities?))
      if hasWorkingAbility(:VITALSPIRIT) ||                # Espíritu Vital
         hasWorkingAbility(:INSOMNIA) ||                   # Insomnio
         hasWorkingAbility(:SWEETVEIL) ||                  # Velo Dulce
         hasWorkingAbility(:PURIFYINGSALT) ||              # Sal Purificadora
         (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||   # Velo Flor
         (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||    # Defensa Hoja
                                            @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
        abilityname=PBAbilities.getName(self.ability)
        @battle.pbDisplay(_INTL("¡{2} de {1} evita quedarse dormido!",pbThis,abilityname)) if showMessages
        return false
      end
      if pbPartner.hasWorkingAbility(:SWEETVEIL) ||
         (pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS))
        abilityname=PBAbilities.getName(pbPartner.ability)
        @battle.pbDisplay(_INTL("¡{1} se mantiene despierto gracias al {2} de su aliado!",pbThis,abilityname)) if showMessages
        return false
      end
    end
    if !selfsleep
      if pbOwnSide.effects[PBEffects::Safeguard]>0 &&                                    # Velo Sagrado
         (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))                        # Allanamiento
        @battle.pbDisplay(_INTL("¡{1} está protegido por Velo Sagrado!",pbThis)) if showMessages
        return false
      end
    end
    return true
  end

  def pbCanSleepYawn?
    return false if status!=0
    return false if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)    
    return false if self.hasWorkingAbility(:SHIELDSDOWN) && isConst?(self.species,PBSpecies,:MINIOR) && self.form==0
    if !hasWorkingAbility(:SOUNDPROOF)
      for i in 0...4
        return false if @battle.battlers[i].effects[PBEffects::Uproar]>0
      end
    end
    if !self.isAirborne?
      return false if @battle.field.effects[PBEffects::ElectricTerrain]>0
      return false if @battle.field.effects[PBEffects::MistyTerrain]>0
    end
    if hasWorkingAbility(:VITALSPIRIT) ||
       hasWorkingAbility(:INSOMNIA) ||
       hasWorkingAbility(:COMATOSE) ||
       hasWorkingAbility(:SWEETVEIL) ||
       hasWorkingAbility(:PURIFYINGSALT) ||
       (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                          @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
      return false
    end
    return false if pbPartner.hasWorkingAbility(:SWEETVEIL)
    return true
  end

  def pbSleep(msg=nil)
    self.status=PBStatuses::SLEEP
    self.statusCount=2+@battle.pbRandom(3)
    self.statusCount=(self.statusCount/2).floor if self.hasWorkingAbility(:EARLYBIRD)
    pbCancelMoves
    @battle.pbCommonAnimation("Sleep",self,nil)
    if msg && msg!=""
      @battle.pbDisplay(msg)
    else
      @battle.pbDisplay(_INTL("¡{1} se durmió!",pbThis))
    end
    PBDebug.log("[Cambio de estado] #{pbThis} se durmió por (#{self.statusCount} turnos)")
  end

  def pbSleepSelf(duration=-1)
    if self.hasWorkingAbility(:COMATOSE)
      @battle.pbDisplay(_INTL("{1} ya se encuentra en un estado de letargo!",pbThis))
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡{1} no se vio afectado!",pbThis)) if showMessages
      return false
    end
    self.status=PBStatuses::SLEEP
    if duration>0
      self.statusCount=duration
    else
      self.statusCount=2+@battle.pbRandom(3)
    end
    self.statusCount=(self.statusCount/2).floor if self.hasWorkingAbility(:EARLYBIRD)
    pbCancelMoves
    @battle.pbCommonAnimation("Sleep",self,nil)
    PBDebug.log("[Cambio de estado] #{pbThis} se fue a dormir (#{self.statusCount} turnos)")
  end

#===============================================================================
# Poison / Veneno
#===============================================================================
  def pbCanPoison?(attacker,showMessages,move=nil)
    return false if isFainted?
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("{1} no se vio afectado.",pbThis)) if showMessages
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡La coraza de {1} le protege!",pbThis)) if showMessages
      return false
    end
    if status==PBStatuses::POISON
      @battle.pbDisplay(_INTL("{1} ya está envenenado.",pbThis)) if showMessages
      return false
    end
    if self.status!=0 ||
       (@effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker)))
      @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
      return false
    end
    if (pbHasType?(:POISON) || pbHasType?(:STEEL) || hasWorkingAbility(:PASTELVEIL)) && !hasWorkingItem(:RINGTARGET)
      @battle.pbDisplay(_INTL("No afecta a {1}...",pbThis(true))) if showMessages
      return false
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0 &&                               # Campo de Niebla
       !self.isAirborne?((attacker && attacker.hasMoldBreaker) || (
       move && move.doesBypassIgnorableAbilities?))
      @battle.pbDisplay(_INTL("¡El Campo de Niebla evita que {1} sea envenedado!",pbThis(true))) if showMessages
      return false
    end
    if (!attacker || !attacker.hasMoldBreaker) && (!move || !move.doesBypassIgnorableAbilities?)
      if hasWorkingAbility(:IMMUNITY) ||                   # Inmunidad
         hasWorkingAbility(:PURIFYINGSALT) ||              # Sal Purificadora
         (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
         (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                            @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
        @battle.pbDisplay(_INTL("¡{2} de {1} evita el envenenamiento!",pbThis,PBAbilities.getName(self.ability))) if showMessages
        return false
      end
      if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS) ||
         pbPartner.hasWorkingAbility(:PASTELVEIL)                  
        abilityname=PBAbilities.getName(pbPartner.ability)
        @battle.pbDisplay(_INTL("¡{2} del aliado de {1} evita el envenenamiento!",pbThis,abilityname)) if showMessages
        return false
      end
    end
    if pbOwnSide.effects[PBEffects::Safeguard]>0 &&
       (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))                          # Allanamiento
      @battle.pbDisplay(_INTL("¡El equipo de {1} está protegido por Velo Sagrado!",pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbCanPoisonSynchronize?(opponent)
    return false if @battle.field.effects[PBEffects::MistyTerrain]>0 && !self.isAirborne?
    return false if isFainted?
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó la Sincronía!",
                        pbThis,PBAbilities.getName(self.ability)))
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó la Sincronía!",
                              pbThis,PBAbilities.getName(self.ability)))
      return false
    end
    if (pbHasType?(:POISON) || pbHasType?(:STEEL)) && !hasWorkingItem(:RINGTARGET)
      @battle.pbDisplay(_INTL("¡{2} de {1} no tuvo efecto en {3}!",
         opponent.pbThis,PBAbilities.getName(opponent.ability),pbThis(true)))
      return false
    end   
    return false if self.status!=0
    if hasWorkingAbility(:IMMUNITY) ||
       hasWorkingAbility(:PURIFYINGSALT) ||
       (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
       (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                          @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
         pbThis,PBAbilities.getName(self.ability),
         opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
         pbPartner.pbThis,PBAbilities.getName(pbPartner.ability),
         opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    return true
  end

  def pbCanPoisonSpikes?(moldbreaker=false)
    return false if isFainted?
    return false if self.status!=0
    return false if pbHasType?(:POISON) || pbHasType?(:STEEL)
    return false if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
    return false if self.hasWorkingAbility(:SHIELDSDOWN) && isConst?(self.species,PBSpecies,:MINIOR) && self.form==0
    if !moldbreaker
      return false if hasWorkingAbility(:IMMUNITY) ||
                      hasWorkingAbility(:PURIFYINGSALT) ||
                      (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
                      (pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS))
      return false if hasWorkingAbility(:LEAFGUARD) &&
                      (@battle.pbWeather==PBWeather::SUNNYDAY ||
                      @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA)
    end
    return false if pbOwnSide.effects[PBEffects::Safeguard]>0
    return true
  end

  def pbPoison(attacker,msg=nil,toxic=false)
    self.status=PBStatuses::POISON
    self.statusCount=(toxic) ? 1 : 0
    self.effects[PBEffects::Toxic]=0
    @battle.pbCommonAnimation("Poison",self,nil)
    if msg && msg!=""
      @battle.pbDisplay(msg)
    else
      if toxic
        @battle.pbDisplay(_INTL("¡{1} ha sido gravemente envenenado!",pbThis))
      else
        @battle.pbDisplay(_INTL("¡{1} ha sido envenenado!",pbThis))
      end
    end
    
    if attacker.hasWorkingAbility(:POISONPUPPETEER) && self.pbCanConfuse?(attacker,false)
      self.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",pbThis))
    end
    
    if toxic
      PBDebug.log("[Cambio de estado] #{pbThis} ha sido gravemente envenenado")
    else
      PBDebug.log("[Cambio de estado] #{pbThis} ha sido envenenado")
    end
    if attacker && self.index!=attacker.index &&
       self.hasWorkingAbility(:SYNCHRONIZE)                # Sincronía
      if attacker.pbCanPoisonSynchronize?(self)
        PBDebug.log("[Habilidad disparada] Sincronía de #{self.pbThis}")
        attacker.pbPoison(nil,_INTL("¡{2} de {1} envenenó a {3}!",self.pbThis,
           PBAbilities.getName(self.ability),attacker.pbThis(true)),toxic)
      end
    end
  end

#===============================================================================
# Burn / Quemadura
#===============================================================================
  def pbCanBurn?(attacker,showMessages,move=nil)
    return false if isFainted?
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("{1} no se vio afectado.",pbThis)) if showMessages
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡La coraza de {1} le protege!",pbThis)) if showMessages
      return false
    end
    if self.status==PBStatuses::BURN 
      @battle.pbDisplay(_INTL("{1} ya tiene una quemadura.",pbThis)) if showMessages
      return false
    end
    if self.status!=0 ||
       (@effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker)))
      @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
      return false
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0 &&
       !self.isAirborne?((attacker && attacker.hasMoldBreaker) || (
       move && move.doesBypassIgnorableAbilities?))
      @battle.pbDisplay(_INTL("¡El Campo de Niebla evita que {1} sea quemado!",pbThis(true))) if showMessages
      return false
    end
    if pbHasType?(:FIRE) && !hasWorkingItem(:RINGTARGET)
      @battle.pbDisplay(_INTL("No afecta a {1}...",pbThis(true))) if showMessages
      return false
    end
    if !attacker || !attacker.hasMoldBreaker
      if hasWorkingAbility(:WATERVEIL) ||                    # Velo Agua
         hasWorkingAbility(:WATERBUBBLE) ||                  # Pompa
         hasWorkingAbility(:PURIFYINGSALT) ||                # Sal Purificadora 
         (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
         (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                            @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
        @battle.pbDisplay(_INTL("¡{2} de {1} evita que se queme!",pbThis,PBAbilities.getName(self.ability))) if showMessages
        return false
      end
      if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
        abilityname=PBAbilities.getName(pbPartner.ability)
        @battle.pbDisplay(_INTL("¡{2} del aliado de {1} evita que se queme!",pbThis,abilityname)) if showMessages
        return false
      end
    end
    if pbOwnSide.effects[PBEffects::Safeguard]>0 &&
       (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))
      @battle.pbDisplay(_INTL("¡El equipo de {1} está protegido por Velo Sagrado!",pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbCanBurnSynchronize?(opponent)
    return false if @battle.field.effects[PBEffects::MistyTerrain]>0 && !self.isAirborne?
    return false if isFainted?
    return false if self.status!=0
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó la Sincronía!",
                        pbThis,PBAbilities.getName(self.ability)))
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó la Sincronía!",
                              pbThis,PBAbilities.getName(self.ability)))
      return false
    end
    if pbHasType?(:FIRE) && !hasWorkingItem(:RINGTARGET)
       @battle.pbDisplay(_INTL("¡{2} de {1} no tuvo efecto en {3}!",
          opponent.pbThis,PBAbilities.getName(opponent.ability),pbThis(true)))
       return false
    end   
    if hasWorkingAbility(:WATERVEIL) ||
       hasWorkingAbility(:WATERBUBBLE) ||
       hasWorkingAbility(:PURIFYINGSALT) ||
       (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
       (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                          @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
      @battle.pbDisplay(_INTL("¡{2} de {1} inutilizó {4} de {3}!",
         pbThis,PBAbilities.getName(self.ability),
         opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
         pbPartner.pbThis,PBAbilities.getName(pbPartner.ability),
         opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    return true
  end

  def pbBurn(attacker,msg=nil)
    self.status=PBStatuses::BURN
    self.statusCount=0
    @battle.pbCommonAnimation("Burn",self,nil)
    if msg && msg!=""
      @battle.pbDisplay(msg)
    else
      @battle.pbDisplay(_INTL("¡{1} ha sido quemado!",pbThis))
    end
    PBDebug.log("[Cambio de estado] #{pbThis} ha sido quemado")
    if attacker && self.index!=attacker.index &&
       self.hasWorkingAbility(:SYNCHRONIZE)
      if attacker.pbCanBurnSynchronize?(self)
        PBDebug.log("[Habilidad disparada] Sincronía de #{self.pbThis}")
        attacker.pbBurn(nil,_INTL("¡{2} de {1} ha quemado a {3}!",self.pbThis,
           PBAbilities.getName(self.ability),attacker.pbThis(true)))
      end
    end
  end

#===============================================================================
# Paralyze / Parálisis
#===============================================================================
  def pbCanParalyze?(attacker,showMessages,move=nil)
    return false if isFainted?
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("{1} no se vio afectado.",pbThis)) if showMessages
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡La coraza de {1} le protege!",pbThis)) if showMessages
      return false
    end
    if status==PBStatuses::PARALYSIS
      @battle.pbDisplay(_INTL("¡{1} ya está paralizado!",pbThis)) if showMessages
      return false
    end
    if self.status!=0 ||
       (@effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker)))
      @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
      return false
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0 &&
       !self.isAirborne?((attacker && attacker.hasMoldBreaker) || (
       move && move.doesBypassIgnorableAbilities?))
      @battle.pbDisplay(_INTL("¡El Campo de Niebla evita que {1} sea paralizado!",pbThis(true))) if showMessages
      return false
    end
    if pbHasType?(:ELECTRIC) && USENEWBATTLEMECHANICS
      @battle.pbDisplay(_INTL("No afecta a {1}...",pbThis(true))) if showMessages
      return false
    end
    if (!attacker || !attacker.hasMoldBreaker) && (!move || !move.doesBypassIgnorableAbilities?)
      if hasWorkingAbility(:LIMBER) ||                       # Flexibilidad
         hasWorkingAbility(:PURIFYINGSALT) ||                # Sal Purificadora
         (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
         (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                            @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
        @battle.pbDisplay(_INTL("¡{2} de {1} impide que se quede paralizado!",pbThis,PBAbilities.getName(self.ability))) if showMessages
        return false
      end
      if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
        abilityname=PBAbilities.getName(pbPartner.ability)
        @battle.pbDisplay(_INTL("¡{2} del aliado de {1} impide que se quede paralizado!",pbThis,abilityname)) if showMessages
        return false
      end
    end
    if pbOwnSide.effects[PBEffects::Safeguard]>0 &&
       (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))
      @battle.pbDisplay(_INTL("¡El equipo de {1} está protegido por Velo Sagrado!",pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbCanParalyzeSynchronize?(opponent)
    return false if @battle.field.effects[PBEffects::MistyTerrain]>0 && !self.isAirborne?
    return false if self.status!=0
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó la Sincronía!",
                        pbThis,PBAbilities.getName(self.ability)))
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó la Sincronía!",
                              pbThis,PBAbilities.getName(self.ability)))
      return false
    end
    return false if pbHasType?(:ELECTRIC) && !hasWorkingItem(:RINGTARGET) && USENEWBATTLEMECHANICS
    if hasWorkingAbility(:LIMBER) ||
       hasWorkingAbility(:PURIFYINGSALT) ||
       (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
       (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                          @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
         pbThis,PBAbilities.getName(self.ability),
         opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
         pbPartner.pbThis,PBAbilities.getName(pbPartner.ability),
         opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    return true
  end

  def pbParalyze(attacker,msg=nil)
    self.status=PBStatuses::PARALYSIS
    self.statusCount=0
    @battle.pbCommonAnimation("Paralysis",self,nil)
    if msg && msg!=""
      @battle.pbDisplay(msg)
    else
      @battle.pbDisplay(_INTL("¡{1} está paralizado! ¡Quizás no pueda moverse!",pbThis))
    end
    PBDebug.log("[Cambio de estado] #{pbThis} ha sido paralizado")
    if attacker && self.index!=attacker.index &&
       self.hasWorkingAbility(:SYNCHRONIZE)
      if attacker.pbCanParalyzeSynchronize?(self)
        PBDebug.log("[Habilidad disparada] Sincronía de #{self.pbThis}")
        attacker.pbParalyze(nil,_INTL("¡{2} de {1} ha paralizado a {3}! ¡Quizás no pueda moverse!",
           self.pbThis,PBAbilities.getName(self.ability),attacker.pbThis(true)))
      end
    end
  end

#===============================================================================
# Freeze / Congelamiento
#===============================================================================
  def pbCanFreeze?(attacker,showMessages,move=nil)
    
    frezename = "congelado" 
    frezename = "helado" if FROSTBITE_REPLACES_FREEZE
    
    return false if isFainted?
    if self.hasWorkingAbility(:COMATOSE) && isConst?(self.species,PBSpecies,:KOMALA)
      @battle.pbDisplay(_INTL("{1} no se vio afectado.",pbThis)) if showMessages
      return false
    end
    if self.hasWorkingAbility(:SHIELDSDOWN) &&
      isConst?(self.species,PBSpecies,:MINIOR) &&  self.form==0
      @battle.pbDisplay(_INTL("¡La coraza de {1} le protege!",pbThis)) if showMessages
      return false
    end
    if status==PBStatuses::FROZEN
      @battle.pbDisplay(_INTL("¡{1} ya está {2}!",pbThis,frezename)) if showMessages
      return false
    end
    if self.status!=0 ||
       (@effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker))) ||
       @battle.pbWeather==PBWeather::SUNNYDAY ||
       @battle.pbWeather==PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if showMessages
      return false
    end
    if pbHasType?(:ICE) && !hasWorkingItem(:RINGTARGET)
      @battle.pbDisplay(_INTL("No afecta a {1}...",pbThis(true))) if showMessages
      return false
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0 &&
       !self.isAirborne?((attacker && attacker.hasMoldBreaker) || (
       move && move.doesBypassIgnorableAbilities?))
      @battle.pbDisplay(_INTL("¡El Campo de Niebla evita que {1} sea {2}!",pbThis(true),frezename)) if showMessages
      return false
    end
    if (!attacker || !attacker.hasMoldBreaker) && (!move || !move.doesBypassIgnorableAbilities?)
      if hasWorkingAbility(:MAGMAARMOR) ||
         hasWorkingAbility(:PURIFYINGSALT) ||
         (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) ||
         (hasWorkingAbility(:LEAFGUARD) && (@battle.pbWeather==PBWeather::SUNNYDAY ||
                                            @battle.pbWeather==PBWeather::HARSHSUN) && !hasWorkingItem(:UTILITYUMBRELLA))
        @battle.pbDisplay(_INTL("¡{2} de {1} evita quedarse {3}!",pbThis,PBAbilities.getName(self.ability),frezename)) if showMessages
        return false
      end
      if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
        abilityname=PBAbilities.getName(pbPartner.ability)
        @battle.pbDisplay(_INTL("¡{2} del aliado de {1} evita que sea {2}!",pbThis,abilityname,frezename)) if showMessages
        return false
      end
    end
    if pbOwnSide.effects[PBEffects::Safeguard]>0 &&
       (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))
      @battle.pbDisplay(_INTL("¡El equipo de {1} está protegido por Velo Sagrado!",pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbFreeze(msg=nil)
    self.status=PBStatuses::FROZEN
    self.statusCount=0
    pbCancelMoves
    @battle.pbCommonAnimation("Frozen",self,nil)
    if msg && msg!=""
      @battle.pbDisplay(msg)
    else
      if FROSTBITE_REPLACES_FREEZE 
        @battle.pbDisplay(_INTL("¡{1} se ha helado!",pbThis))
      else
        @battle.pbDisplay(_INTL("¡{1} se ha congelado!",pbThis))
      end
    end
    PBDebug.log("[Cambio de estado] #{pbThis} se ha congelado")
  end

#===============================================================================
# Generalised status displays
#===============================================================================
  def pbContinueStatus(showAnim=true)
    case self.status
    when PBStatuses::SLEEP
      @battle.pbCommonAnimation("Sleep",self,nil)
      @battle.pbDisplay(_INTL("{1} está dormido como un tronco.",pbThis))
    when PBStatuses::POISON
      @battle.pbCommonAnimation("Poison",self,nil)
      @battle.pbDisplay(_INTL("¡El veneno resta PS a {1}!",pbThis))
    when PBStatuses::BURN
      @battle.pbCommonAnimation("Burn",self,nil)
      @battle.pbDisplay(_INTL("¡{1} se resiente de la quemadura!",pbThis))
    when PBStatuses::PARALYSIS
      @battle.pbCommonAnimation("Paralysis",self,nil)
      @battle.pbDisplay(_INTL("¡{1} está paralizado! ¡No se puede mover!",pbThis)) 
    when PBStatuses::FROZEN
      @battle.pbCommonAnimation("Frozen",self,nil)
      if !FROSTBITE_REPLACES_FREEZE
        @battle.pbDisplay(_INTL("¡{1} está congelado!",pbThis))
      else
        @battle.pbDisplay(_INTL("¡{1} está helado!",pbThis))
      end
    end
  end

  def pbCureStatus(showMessages=true)
    oldstatus=self.status
    self.status=0
    self.statusCount=0
    if showMessages
      case oldstatus
      when PBStatuses::SLEEP
        @battle.pbDisplay(_INTL("¡{1} se despertó!",pbThis))
      when PBStatuses::POISON
      when PBStatuses::BURN
      when PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} ya no está paralizado!",pbThis))
      when PBStatuses::FROZEN
        @battle.pbDisplay(_INTL("¡{1} se descongeló!",pbThis))
      end
    end
    PBDebug.log("[Cambio de estado] El estado de #{pbThis} ha sido curado")
  end

#===============================================================================
# Confuse / Confusión
#===============================================================================
  def pbCanConfuse?(attacker=nil,showMessages=true,move=nil)
    return false if isFainted?
    if effects[PBEffects::Confusion]>0
      @battle.pbDisplay(_INTL("¡{1} ya está confuso!",pbThis)) if showMessages
      return false
    end
    if @effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker))
      @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
      return false
    end
    if (!attacker || !attacker.hasMoldBreaker) && (!move || !move.doesBypassIgnorableAbilities?)
      if hasWorkingAbility(:OWNTEMPO)
        @battle.pbDisplay(_INTL("¡{2} de {1} impide que quede confuso!",pbThis,PBAbilities.getName(self.ability))) if showMessages
        return false
      end
    end
    if pbOwnSide.effects[PBEffects::Safeguard]>0 &&
       (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))
      @battle.pbDisplay(_INTL("¡El equipo de {1} está protegido por Velo Sagrado!",pbThis)) if showMessages
      return false
    end
    return true
  end

  def pbCanConfuseSelf?(showMessages)
    return false if isFainted?
    if effects[PBEffects::Confusion]>0
      @battle.pbDisplay(_INTL("¡{1} ya está confuso!",pbThis)) if showMessages
      return false
    end
    if hasWorkingAbility(:OWNTEMPO)
      @battle.pbDisplay(_INTL("¡{2} de {1} impide que quede confuso!",pbThis,PBAbilities.getName(self.ability))) if showMessages
      return false
    end
    return true
  end

  def pbConfuse
    @effects[PBEffects::Confusion]=2+@battle.pbRandom(4)
    @battle.pbCommonAnimation("Confusion",self,nil)
    PBDebug.log("[Efecto prolongado disparado] #{pbThis} quedó confuso (#{@effects[PBEffects::Confusion]} turnos)")
  end

  def pbConfuseSelf
    if pbCanConfuseSelf?(false)
      @effects[PBEffects::Confusion]=2+@battle.pbRandom(4)
      @battle.pbCommonAnimation("Confusion",self,nil)
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",pbThis))
      PBDebug.log("[Efecto prolongado disparado] #{pbThis} quedó confuso (#{@effects[PBEffects::Confusion]} turnos)")
    end
  end

  def pbContinueConfusion
    @battle.pbCommonAnimation("Confusion",self,nil)
    @battle.pbDisplayBrief(_INTL("¡{1} está confuso!",pbThis))
  end

  def pbCureConfusion(showMessages=true)
    @effects[PBEffects::Confusion]=0
    @battle.pbDisplay(_INTL("¡{1} ya no está confuso!",pbThis)) if showMessages
    PBDebug.log("[Efecto terminado] #{pbThis} ya no está confuso")
  end

#===============================================================================
# Attraction   /   Atracción
#===============================================================================
  def pbCanAttract?(attacker,showMessages=true)
    return false if isFainted?
    return false if !attacker || attacker.isFainted?
    if @effects[PBEffects::Attract]>=0
      @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
      return false
    end
    agender=attacker.gender
    ogender=self.gender
    if agender==2 || ogender==2 || agender==ogender
      @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
      return false
    end
    if (!attacker || !attacker.hasMoldBreaker) && hasWorkingAbility(:OBLIVIOUS)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita que se enamore!",pbThis,
         PBAbilities.getName(self.ability))) if showMessages
      return false
    end
    return true
  end

  def pbAttract(attacker,msg=nil)
    @effects[PBEffects::Attract]=attacker.index
    @battle.pbCommonAnimation("Attract",self,nil)
    if msg && msg!=""
      @battle.pbDisplay(msg)
    else
      @battle.pbDisplay(_INTL("¡{1} se ha enamorado!",pbThis))
    end
    PBDebug.log("[Efecto prolongado disparado] #{pbThis} se ha enamorado (de #{attacker.pbThis(true)})")
    if self.hasWorkingItem(:DESTINYKNOT) &&                                              # Lazo Destino
       attacker.pbCanAttract?(self,false)
      PBDebug.log("[Objeto disparado] Lazo Destino de #{pbThis}")
      attacker.pbAttract(self,_INTL("¡{2} de {1} enamoró a {3}!",pbThis,
         PBItems.getName(self.item),attacker.pbThis(true)))
    end
  end

  def pbAnnounceAttract(seducer)
    @battle.pbCommonAnimation("Attract",self,nil)
    @battle.pbDisplayBrief(_INTL("¡{1} se enamoró de {2}!",
       pbThis,seducer.pbThis(true)))
  end

  def pbContinueAttract
    @battle.pbDisplay(_INTL("¡El amor impide que {1} ataque!",pbThis)) 
  end

  def pbCureAttract
    @effects[PBEffects::Attract]=-1
    PBDebug.log("[Efecto terminado] #{pbThis} ya no está enamorado")
  end

#===============================================================================
# Flinching / Retroceso
#===============================================================================
  def pbFlinch(attacker)
    return false if (!attacker || !attacker.hasMoldBreaker) && hasWorkingAbility(:INNERFOCUS)      # Foco Interno
    @effects[PBEffects::Flinch]=true
    return true
  end

#===============================================================================
# Increase stat stages  /  Incremento de niveles de las características
#===============================================================================
  def pbTooHigh?(stat)
    return @stages[stat]>=6
  end

  def pbCanIncreaseStatStage?(stat,attacker=nil,showMessages=false,move=nil,moldbreaker=false,ignoreContrary=false)
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary                               # Respondón
          return pbCanReduceStatStage?(stat,attacker,showMessages,moldbreaker,true)
        end
      end
    end
    return false if isFainted?
    if pbTooHigh?(stat)
      @battle.pbDisplay(_INTL("¡{2} de {1} no subirá más!",
         pbThis,PBStats.getName(stat))) if showMessages
      return false
    end
    return true
  end

  def pbIncreaseStatBasic(stat,increment,attacker=nil,moldbreaker=false,ignoreContrary=false)
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary                               # Respondón
          return pbReduceStatBasic(stat,increment,attacker,moldbreaker,true)
        end
        increment*=2 if hasWorkingAbility(:SIMPLE)
      end
    end
    increment=[increment,6-@stages[stat]].min
    PBDebug.log("[Cambio características] #{PBStats.getName(stat)} de #{pbThis} subió #{increment} nivel(es) (era #{@stages[stat]}, ahora #{@stages[stat]+increment})")
    @stages[stat]+=increment
    return increment
  end

  def pbIncreaseStat(stat,increment,attacker,showMessages,move=nil,upanim=true,moldbreaker=false,ignoreContrary=false)
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary
          return pbReduceStat(stat,increment,attacker,showMessages,move,upanim,moldbreaker,true)
        end
      end
    end
    return false if stat!=PBStats::ATTACK && stat!=PBStats::DEFENSE &&
                    stat!=PBStats::SPATK && stat!=PBStats::SPDEF &&
                    stat!=PBStats::SPEED && stat!=PBStats::EVASION &&
                    stat!=PBStats::ACCURACY
    if pbCanIncreaseStatStage?(stat,attacker,showMessages,move,moldbreaker,ignoreContrary)
      increment=pbIncreaseStatBasic(stat,increment,attacker,moldbreaker,ignoreContrary)
      if increment>0
        if ignoreContrary
          @battle.pbDisplay(_INTL("¡{2} de {1} activado!",pbThis,PBAbilities.getName(self.ability))) if upanim
        end
        @battle.pbCommonAnimation("StatUp",self,nil) if upanim
        arrStatTexts=[_INTL("¡{2} de {1} subió!",pbThis,PBStats.getName(stat)),
           _INTL("¡{2} de {1} subió mucho!",pbThis,PBStats.getName(stat)),
           _INTL("¡{2} de {1} subió drásticamente!",pbThis,PBStats.getName(stat))]
        @battle.pbDisplay(arrStatTexts[[increment-1,2].min])
        @effects[PBEffects::BurningJealousy] = true        
        return true
      end
    end
    return false
  end

  def pbIncreaseStatWithCause(stat,increment,attacker,cause,showanim=true,showmessage=true,moldbreaker=false,ignoreContrary=false)
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary
          return pbReduceStatWithCause(stat,increment,attacker,cause,showanim,showmessage,moldbreaker,true)
        end
      end
    end
    return false if stat!=PBStats::ATTACK && stat!=PBStats::DEFENSE &&
                    stat!=PBStats::SPATK && stat!=PBStats::SPDEF &&
                    stat!=PBStats::SPEED && stat!=PBStats::EVASION &&
                    stat!=PBStats::ACCURACY
    if pbCanIncreaseStatStage?(stat,attacker,false,nil,moldbreaker,ignoreContrary)
      increment=pbIncreaseStatBasic(stat,increment,attacker,moldbreaker,ignoreContrary)
      if increment>0
        if ignoreContrary
          @battle.pbDisplay(_INTL("¡{2} de {1} activado!",pbThis,PBAbilities.getName(self.ability))) if showanim
        end
        @battle.pbCommonAnimation("StatUp",self,nil) if showanim
        if attacker.index==self.index
          arrStatTexts=[_INTL("¡{2} de {1} subió su {3}!",pbThis,cause,PBStats.getName(stat)),
             _INTL("¡{2} de {1} subió drásticamente su {3}!",pbThis,cause,PBStats.getName(stat)),
             _INTL("¡{2} de {1} subió al máximo!",pbThis,PBStats.getName(stat))]
        else
          arrStatTexts=[_INTL("¡{2} de {1} subió {4} de {3}!",attacker.pbThis,cause,pbThis(true),PBStats.getName(stat)),
             _INTL("¡{2} de {1} subió mucho {4} de {3}!",attacker.pbThis,cause,pbThis(true),PBStats.getName(stat)),
             _INTL("¡{2} de {1} subió drásticamente {4} de {3}!",attacker.pbThis,cause,pbThis(true),PBStats.getName(stat))]
        end
        @battle.pbDisplay(arrStatTexts[[increment-1,2].min]) if showmessage
        @effects[PBEffects::BurningJealousy] = true
        return true
      end
    end
    return false
  end

#===============================================================================
# Decrease stat stages  /  Decremento de niveles de las características
#===============================================================================
  def pbTooLow?(stat)
    return @stages[stat]<=-6
  end

  # Tickle/Cosquillas (04A) y Noble Roar (13A) no pueden usar esto, pero se repite en su lugar.
  # (La razón es que estos movimientos bajan más de una característica independientemente, y por lo
  # tanto se podrían mostrar ciertos mensajes repetidas veces, lo que no es deseable.)
  def pbCanReduceStatStage?(stat,attacker=nil,showMessages=false,move=nil,moldbreaker=false,ignoreContrary=false,ignoremirror=false)
    selfreduce=(attacker && attacker.index==self.index) # Moved to the top for Mirror Armor
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary
          return pbCanIncreaseStatStage?(stat,attacker,showMessages,move,moldbreaker,true)
        end
        if hasWorkingAbility(:MIRRORARMOR) && !(ignoremirror || selfreduce)
          return attacker.pbCanReduceStatStage?(stat,self,showMessages,move,moldbreaker,ignoreContrary,true)
        end
      end
    end
    return false if isFainted?
    if !selfreduce
      if @effects[PBEffects::Substitute]>0 && (!move || !move.ignoresSubstitute?(attacker))
        @battle.pbDisplay(_INTL("¡Pero falló!")) if showMessages
        return false
      end
      if pbOwnSide.effects[PBEffects::Mist]>0 &&
        (!attacker || !attacker.hasWorkingAbility(:INFILTRATOR))
        @battle.pbDisplay(_INTL("¡{1} se ha protegido con Neblina!",pbThis)) if showMessages
        return false
      end
      if hasWorkingAbility(:FULLMETALBODY)
          abilityname=PBAbilities.getName(self.ability)
          @battle.pbDisplay(_INTL("¡{2} de {1} evita la pérdida de características!",pbThis,abilityname)) if showMessages
          return false
      end
      if !moldbreaker && (!attacker || !attacker.hasMoldBreaker) && (!move || 
        !move.doesBypassIgnorableAbilities?)
        if hasWorkingAbility(:CLEARBODY) || hasWorkingAbility(:WHITESMOKE) ||
           hasWorkingItem(:CLEARAMULET)
          abilityname=PBAbilities.getName(self.ability)
          @battle.pbDisplay(_INTL("¡{2} de {1} evita la pérdida de características!",pbThis,abilityname)) if showMessages
          return false
        end
        if pbHasType?(:GRASS)
          if hasWorkingAbility(:FLOWERVEIL)
            abilityname=PBAbilities.getName(self.ability)
            @battle.pbDisplay(_INTL("¡{2} de {1} evita la pérdida de sus características!",pbThis,abilityname)) if showMessages
            return false
          elsif pbPartner.hasWorkingAbility(:FLOWERVEIL)
            abilityname=PBAbilities.getName(pbPartner.ability)
            @battle.pbDisplay(_INTL("¡{2} de {1} evita la pérdida de sus características de {3}!",pbPartner.pbThis,abilityname,pbThis(true))) if showMessages
            return false
          end
        end
        if stat==PBStats::ATTACK && hasWorkingAbility(:HYPERCUTTER)
          abilityname=PBAbilities.getName(self.ability)
          @battle.pbDisplay(_INTL("¡{2} de {1} evita que baje su Ataque!",pbThis,abilityname)) if showMessages
          return false
        end
        if stat==PBStats::DEFENSE && hasWorkingAbility(:BIGPECKS)
          abilityname=PBAbilities.getName(self.ability)
          @battle.pbDisplay(_INTL("¡{2} de {1} evita que baje su Defensa!",pbThis,abilityname)) if showMessages
          return false
        end
        if stat==PBStats::ACCURACY && hasWorkingAbility(:KEENEYE)
          abilityname=PBAbilities.getName(self.ability)
          @battle.pbDisplay(_INTL("¡{2} de {1} evita que baje su precisión!",pbThis,abilityname)) if showMessages
          return false
        end
      end
    end
    if pbTooLow?(stat)
      @battle.pbDisplay(_INTL("¡{2} de {1} no bajará más!",
         pbThis,PBStats.getName(stat))) if showMessages
      return false
    end
    return true
  end

  def pbReduceStatBasic(stat,increment,attacker=nil,moldbreaker=false,ignoreContrary=false,ignoremirror=false)
    if !moldbreaker # moldbreaker is true only when Roar forces out a Pokémon into Sticky Web
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary
          return pbIncreaseStatBasic(stat,increment,attacker,moldbreaker,true)
        end
        if hasWorkingAbility(:MIRRORARMOR) && !ignoremirror
          return attacker.pbReduceStatBasic(stat,increment,self,moldbreaker,ignoreContrary,true)
        end
        increment*=2 if hasWorkingAbility(:SIMPLE)
      end
    end
    increment=[increment,6+@stages[stat]].min
    PBDebug.log("[Cambio características] #{PBStats.getName(stat)} de #{pbThis} bajó #{increment} nivel(es) (era #{@stages[stat]}, ahora #{@stages[stat]-increment})")
    @stages[stat]-=increment
    return increment
  end

  def pbReduceStat(stat,increment,attacker,showMessages,move=nil,downanim=true,moldbreaker=false,ignoreContrary=false,ignoremirror=false)
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary
          return pbIncreaseStat(stat,increment,attacker,showMessages,move,downanim,moldbreaker,true)
        end
        if hasWorkingAbility(:MIRRORARMOR) && !ignoremirror
          return attacker.pbReduceStat(stat,increment,self,showMessages,move,downanim,moldbreaker,ignoreContrary,true)
        end
      end
    end
    return false if stat!=PBStats::ATTACK && stat!=PBStats::DEFENSE &&
                    stat!=PBStats::SPATK && stat!=PBStats::SPDEF &&
                    stat!=PBStats::SPEED && stat!=PBStats::EVASION &&
                    stat!=PBStats::ACCURACY
    if pbCanReduceStatStage?(stat,attacker,showMessages,move,moldbreaker,ignoreContrary,ignoremirror)
      increment=pbReduceStatBasic(stat,increment,attacker,moldbreaker,ignoreContrary,ignoremirror)
      if increment>0
        if ignoreContrary
          @battle.pbDisplay(_INTL("¡{2} de {1} activado!",pbThis,PBAbilities.getName(self.ability))) if downanim
        end
        if ignoremirror
          @battle.pbDisplay(_INTL("¡{2} de {1} activada!",attacker.pbThis,PBAbilities.getName(attacker.ability))) if downanim
        end
        @battle.pbCommonAnimation("StatDown",self,nil) if downanim
        arrStatTexts=[_INTL("¡{2} de {1} bajó!",pbThis,PBStats.getName(stat)),
           _INTL("¡{2} de {1} bajó mucho!",pbThis,PBStats.getName(stat)),
           _INTL("¡{2} de {1} bajó severamente!",pbThis,PBStats.getName(stat))]
        @battle.pbDisplay(arrStatTexts[[increment-1,2].min])
        # Defiant
        if hasWorkingAbility(:DEFIANT) && (!attacker || attacker.pbIsOpposing?(self.index))
          pbIncreaseStatWithCause(PBStats::ATTACK,2,self,PBAbilities.getName(self.ability))
        end
        # Competitive
        if hasWorkingAbility(:COMPETITIVE) && (!attacker || attacker.pbIsOpposing?(self.index))
          pbIncreaseStatWithCause(PBStats::SPATK,2,self,PBAbilities.getName(self.ability))
        end
        # Eject Pack
        if hasWorkingItem(:EJECTPACK) && ((!attacker || attacker.pbIsOpposing?(self.index)) || (attacker && attacker.index==self.index))
          if @battle.pbCanSwitch?(self.index,-1,false) && !@battle.pbAllFainted?(@battle.pbParty(self.index))
            @battle.pbCommonAnimation("UseItem",self,nil)
            pbConsumeItem(false,true)
            newpoke=0
            newpoke=@battle.pbSwitchInBetween(self.index,true,false)
            newpokename=newpoke
            if isConst?(@battle.pbParty(self.index)[newpoke].ability,PBAbilities,:ILLUSION)
              newpokename=@battle.pbGetLastPokeInTeam(self.index)
            end
            pbResetForm
            @battle.pbRecallAndReplace(self.index,newpoke,newpokename)
            @battle.choices[self.index]=[0,0,nil,-1]   # Replacement Pokémon does nothing this round
            pbAbilitiesOnSwitchIn(true)
          end
        end
        @effects[PBEffects::LashOut] = true
        return true
      end
    end
    return false
  end

  def pbReduceStatWithCause(stat,increment,attacker,cause,showanim=true,showmessage=true,moldbreaker=false,ignoreContrary=false,ignoremirror=false)
    if !moldbreaker
      if !attacker || attacker.index==self.index || !attacker.hasMoldBreaker
        if hasWorkingAbility(:CONTRARY) && !ignoreContrary
          return pbIncreaseStatWithCause(stat,increment,attacker,cause,showanim,showmessage,moldbreaker,true)
        end
        if hasWorkingAbility(:MIRRORARMOR) && !ignoreContrary
          return attacker.pbReduceStatWithCause(stat,increment,self,cause,showanim,showmessage,moldbreaker,ignoreContrary,true)
        end
      end
    end
    return false if stat!=PBStats::ATTACK && stat!=PBStats::DEFENSE &&
                    stat!=PBStats::SPATK && stat!=PBStats::SPDEF &&
                    stat!=PBStats::SPEED && stat!=PBStats::EVASION &&
                    stat!=PBStats::ACCURACY
    if pbCanReduceStatStage?(stat,attacker,false,nil,moldbreaker,ignoreContrary,ignoremirror)
      increment=pbReduceStatBasic(stat,increment,attacker,moldbreaker,ignoreContrary,ignoremirror)
      if increment>0
        if ignoreContrary
          @battle.pbDisplay(_INTL("¡{2} de {1} activado!",pbThis,PBAbilities.getName(self.ability))) if downanim
        end
        if ignoremirror
          @battle.pbDisplay(_INTL("¡{2} de {1} activada!",attacker.pbThis,PBAbilities.getName(attacker.ability))) if showanim
        end
        @battle.pbCommonAnimation("StatDown",self,nil) if showanim
        if attacker.index==self.index
          arrStatTexts=[_INTL("¡{2} de {1} bajó su {3}!",pbThis,cause,PBStats.getName(stat)),
             _INTL("¡{2} de {1} bajó mucho su {3}!",pbThis,cause,PBStats.getName(stat)),
             _INTL("¡{2} de {1} bajó severamente su {3}!",pbThis,PBStats.getName(stat))]
        else
          if ignoremirror
            arrStatTexts=[_INTL("¡{1} bajó {3} de {2}!",attacker.pbThis,pbThis(true),PBStats.getName(stat)),
               _INTL("¡{1} bajó mucho {3} de {2}!",attacker.pbThis,pbThis(true),PBStats.getName(stat)),
               _INTL("¡{1} bajó severamente {3} de {2}!",attacker.pbThis,pbThis(true),PBStats.getName(stat))]
        else
          arrStatTexts=[_INTL("¡{2} de {1} bajó {4} de {3}!",attacker.pbThis,cause,pbThis(true),PBStats.getName(stat)),
             _INTL("¡{2} de {1} bajó mucho {4} de {3}!",attacker.pbThis,cause,pbThis(true),PBStats.getName(stat)),
             _INTL("¡{2} de {1} bajó severamente {4} de {3}!",attacker.pbThis,cause,pbThis(true),PBStats.getName(stat))]
        end
      end
        @battle.pbDisplay(arrStatTexts[[increment-1,2].min]) if showmessage
        # Defiant
        if hasWorkingAbility(:DEFIANT) && (!attacker || attacker.pbIsOpposing?(self.index))
          pbIncreaseStatWithCause(PBStats::ATTACK,2,self,PBAbilities.getName(self.ability))
        end
        # Competitive
        if hasWorkingAbility(:COMPETITIVE) && (!attacker || attacker.pbIsOpposing?(self.index))
          pbIncreaseStatWithCause(PBStats::SPATK,2,self,PBAbilities.getName(self.ability))
        end
        # Eject Pack
        if hasWorkingItem(:EJECTPACK) && ((!attacker || attacker.pbIsOpposing?(self.index)) || (attacker && attacker.index==self.index))
          if @battle.pbCanSwitch?(self.index,-1,false) && !@battle.pbAllFainted?(@battle.pbParty(self.index))
            @battle.pbCommonAnimation("UseItem",self,nil)
            pbConsumeItem(false,true)
            newpoke=0
            newpoke=@battle.pbSwitchInBetween(self.index,true,false)
            newpokename=newpoke
            if isConst?(@battle.pbParty(self.index)[newpoke].ability,PBAbilities,:ILLUSION)
              newpokename=@battle.pbGetLastPokeInTeam(self.index)
            end
            pbResetForm
            @battle.pbRecallAndReplace(self.index,newpoke,newpokename)
            @battle.choices[self.index]=[0,0,nil,-1]   # Replacement Pokémon does nothing this round
            pbAbilitiesOnSwitchIn(true)
          end
        end
        @effects[PBEffects::LashOut] = true
        return true
      end
    end
    return false
  end

  def pbReduceAttackStatIntimidate(opponent)
    return false if isFainted?
    if effects[PBEffects::Substitute]>0
      @battle.pbDisplay(_INTL("¡El sustituto ha protegido a {1} de {3} de {2}!",
         pbThis,opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
      return false
    end
    if !opponent.hasWorkingAbility(:CONTRARY)
      if pbOwnSide.effects[PBEffects::Mist]>0
        @battle.pbDisplay(_INTL("¡{1} se ha protegido de {3} de {2} con Neblina!",
           pbThis,opponent.pbThis(true),PBAbilities.getName(opponent.ability)))
        return false
      end
      if hasWorkingAbility(:CLEARBODY) || hasWorkingAbility(:WHITESMOKE) ||
         hasWorkingAbility(:HYPERCUTTER) || hasWorkingAbility(:FULLMETALBODY) ||
         (hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)) || 
         hasWorkingItem(:CLEARAMULET)
        abilityname=PBAbilities.getName(self.ability)
        oppabilityname=PBAbilities.getName(opponent.ability)
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
           pbThis,abilityname,opponent.pbThis(true),oppabilityname))
        return false
      end
      if pbPartner.hasWorkingAbility(:FLOWERVEIL) && pbHasType?(:GRASS)
        abilityname=PBAbilities.getName(pbPartner.ability)
        oppabilityname=PBAbilities.getName(opponent.ability)
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {4} de {3}!",
           pbPartner.pbThis,abilityname,opponent.pbThis(true),oppabilityname))
        return false
      end
    end
    return pbReduceStatWithCause(PBStats::ATTACK,1,opponent,PBAbilities.getName(opponent.ability))
  end
end