################################################################################
# Superclase que gestiona movimientos que usan un código de función inexistente.
# Los movimientos de daño simplemente hacen el daño calculado sin efectos adicionales.
# Los movimientos que no son de daño siempre fallarán.
################################################################################
class PokeBattle_UnimplementedMove < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbIsDamaging?
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    else
      @battle.pbDisplay("¡Pero falló!")
      return -1
    end
  end
end



################################################################################
# Superclase para un movimiento que falla. Siempre falla.
# Ya no se usa esta clase.
################################################################################
class PokeBattle_FailedMove < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    @battle.pbDisplay("¡Pero falló!")
    return -1
  end
end



################################################################################
# Pseudo-movimiento para el daño de confusión.
################################################################################
class PokeBattle_Confusion < PokeBattle_Move
  def initialize(battle,move)
    @battle     = battle
    @basedamage = 40
    @type       = -1
    @accuracy   = 100
    @pp         = -1
    @addlEffect = 0
    @target     = 0
    @priority   = 0
    @flags      = 0
    @thismove   = move
    @name       = ""
    @id         = 0
  end

  def pbIsPhysical?(type); return true; end
  def pbIsSpecial?(type); return false; end

  def pbCalcDamage(attacker,opponent)
    return super(attacker,opponent,
       PokeBattle_Move::NOCRITICAL|PokeBattle_Move::SELFCONFUSE|PokeBattle_Move::NOTYPE|PokeBattle_Move::NOWEIGHTING)
  end

  def pbEffectMessages(attacker,opponent,ignoretype=false)
    return super(attacker,opponent,true)
  end
end



################################################################################
# Implementación del movimiento Combate.
# Para casos donde el movimiento real llamado Combate no esté definido.
################################################################################
class PokeBattle_Struggle < PokeBattle_Move
  def initialize(battle,move)
    @id         = -1    # no funciona si está en 0
    @battle     = battle
    @name       = _INTL("Forcejeo")
    @basedamage = 50
    @type       = -1
    @accuracy   = 0
    @addlEffect = 0
    @target     = 0
    @priority   = 0
    @flags      = 0
    @thismove   = nil   # no está asociado con un movimiento
    @pp         = -1
    @totalpp    = 0
    if move
      @id = move.id
      @name = PBMoves.getName(id)
    end
  end

  def pbIsPhysical?(type); return true; end
  def pbIsSpecial?(type); return false; end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      attacker.pbReduceHP((attacker.totalhp/4.0).round)
      @battle.pbDisplay(_INTL("¡{1} también se ha hecho daño!",attacker.pbThis))
    end
  end

  def pbCalcDamage(attacker,opponent)
    return super(attacker,opponent,PokeBattle_Move::IGNOREPKMNTYPES)
  end
end



################################################################################
# No additional effect.
################################################################################
class PokeBattle_Move_000 < PokeBattle_Move
end



################################################################################
# No hace nada en absoluto.
# (Salpicadura/Splash)
################################################################################
class PokeBattle_Move_001 < PokeBattle_Move
  def unusableInGravity?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡Pero no pasó nada!"))
    return 0
  end
end



################################################################################
# Sobreescribe el efecto por defecto de Combate de arriba.
# (Combate/Struggle)
################################################################################
class PokeBattle_Move_002 < PokeBattle_Struggle
end



################################################################################
# Manda a dormir al objetivo.
################################################################################
class PokeBattle_Move_003 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    if opponent.pbCanSleep?(attacker,true,self)
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbSleep
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanSleep?(attacker,false,self)
      opponent.pbSleep
    end
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if isConst?(@id,PBMoves,:RELICSONG)
      if isConst?(attacker.species,PBSpecies,:MELOETTA) &&
         !attacker.effects[PBEffects::Transform] &&
         !(attacker.hasWorkingAbility(:SHEERFORCE) && self.addlEffect>0) &&
         !attacker.isFainted?
        attacker.form=(attacker.form+1)%2
        attacker.pbUpdate(true)
        @battle.scene.pbChangePokemon(attacker,attacker.pokemon)
        @battle.pbDisplay(_INTL("¡{1} se ha transformado!",attacker.pbThis))
        PBDebug.log("[Cambio de forma] #{attacker.pbThis} cambió a forma #{attacker.form}")
      end
    end
  end
end



################################################################################
# Adormece al objetivo; lo dormirá al final de la siquiente ronda.
# (Yawn/Bostezo)
################################################################################
class PokeBattle_Move_004 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !opponent.pbCanSleep?(attacker,true,self)
    if opponent.effects[PBEffects::Yawn]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Yawn]=2
    @battle.pbDisplay(_INTL("¡{1} adormeció a {2}!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end



################################################################################
# Envenena al objetivo.
################################################################################
class PokeBattle_Move_005 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    if attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbPoison(attacker)
      return 0
    else
      return -1 if !opponent.pbCanPoison?(attacker,true,self)
    end
    return -1 if !opponent.pbCanPoison?(attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbPoison(attacker)
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker)
    end
  end
end



################################################################################
# Envenena grávemente al objetivo.
# (Colmillo Ven, Tóxico)
# (Controlado en pbSuccessCheck de Battler): Golpea a objetivos semi-invulnerables
# si el usuario es de tipo Veneno y el movimiento es de estado.
################################################################################
class PokeBattle_Move_006 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    if attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbPoison(attacker,nil,true)
      return 0
    else
      return -1 if !opponent.pbCanPoison?(attacker,true,self)
    end
    return -1 if !opponent.pbCanPoison?(attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbPoison(attacker,nil,true)
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker,nil,true)
    end
  end
end



################################################################################
# Paraliza al objetivo.
# Onda Trueno: No afecta a objetivos si el tipo del movimiento no lo afecta.
# At. Fulgor: Potencia la siguiente Llama Fusión que se use en esta ronda.
################################################################################
class PokeBattle_Move_007 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbIsDamaging?
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0 && isConst?(@id,PBMoves,:BOLTSTRIKE)
        @battle.field.effects[PBEffects::FusionFlare]=true
      end
      return ret
    else
      if isConst?(@id,PBMoves,:THUNDERWAVE)
        if pbTypeModifier(type,attacker,opponent)==0
          @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
          return -1
        end
      end
      return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
      return -1 if !opponent.pbCanParalyze?(attacker,true,self)
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbParalyze(attacker)
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanParalyze?(attacker,false,self)
      opponent.pbParalyze(attacker)
    end
  end
end



################################################################################
# Paraliza al objetivo. Precisión perfecta en la lluvia, 50% en el día soleado.
# (Trueno/Thunder)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_008 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanParalyze?(attacker,false,self)
      opponent.pbParalyze(attacker)
    end
  end

  def pbModifyBaseAccuracy(baseaccuracy,attacker,opponent)
    case @battle.pbWeather
    when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
      if !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        return 0
      end
    when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
      if !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        return 50
      end
    end
    return baseaccuracy
  end
end



################################################################################
# Paraliza al objetivo. Puede hacer que el objetivo retroceda.
# (Colmillo Rayo/Thunder Fang)
################################################################################
class PokeBattle_Move_009 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if @battle.pbRandom(10)==0
      if opponent.pbCanParalyze?(attacker,false,self)
        opponent.pbParalyze(attacker)
      end
    end
    if @battle.pbRandom(10)==0
      opponent.pbFlinch(attacker)
    end
  end
end



################################################################################
# Quema al objetivo.
# Llama Azul: Potencia el siguiente Rayo Fusión que se use en esta ronda.
################################################################################
class PokeBattle_Move_00A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbIsDamaging?
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0 && isConst?(@id,PBMoves,:BLUEFLARE)
        @battle.field.effects[PBEffects::FusionBolt]=true
      end
      return ret
    else
      return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
      return -1 if !opponent.pbCanBurn?(attacker,true,self)
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbBurn(attacker)
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanBurn?(attacker,false,self)
      opponent.pbBurn(attacker)
    end
  end
end



################################################################################
# Quema al objetivo. Puede hacer que el objetivo retroceda.
# (Colm. Ígneo/Fire Fang)
################################################################################
class PokeBattle_Move_00B < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if @battle.pbRandom(10)==0
      if opponent.pbCanBurn?(attacker,false,self)
        opponent.pbBurn(attacker)
      end
    end
    if @battle.pbRandom(10)==0
      opponent.pbFlinch(attacker)
    end
  end
end



################################################################################
# Congela al objetivo.
################################################################################
class PokeBattle_Move_00C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanFreeze?(attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbFreeze
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanFreeze?(attacker,false,self)
      opponent.pbFreeze
    end
  end
end



################################################################################
# Congela al objetivo. Precisión perfecta durante el granizo.
# (Ventisca/Blizzard)
################################################################################
class PokeBattle_Move_00D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanFreeze?(attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbFreeze
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanFreeze?(attacker,false,self)
      opponent.pbFreeze
    end
  end

  def pbModifyBaseAccuracy(baseaccuracy,attacker,opponent)
    if @battle.pbWeather==PBWeather::HAIL
      return 0
    end
    return baseaccuracy
  end
end



################################################################################
# Congela al objetivo. Puede hacer que el objetivo retroceda.
# (Colm. Hielo/Ice Fang)
################################################################################
class PokeBattle_Move_00E < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if @battle.pbRandom(10)==0
      if opponent.pbCanFreeze?(attacker,false,self)
        opponent.pbFreeze
      end
    end
    if @battle.pbRandom(10)==0
      opponent.pbFlinch(attacker)
    end
  end
end



################################################################################
# Hace que el objetivo retroceda.
################################################################################
class PokeBattle_Move_00F < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end
end



################################################################################
# Hace que el objetivo retroceda. Hace el doble de daño y tiene precisión perfecta
# si el objetivo ha usado Reducción.
################################################################################
class PokeBattle_Move_010 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end

  def tramplesMinimize?(param=1)
    return false if isConst?(@id,PBMoves,:DRAGONRUSH) && !USENEWBATTLEMECHANICS
    return true if param==1 && USENEWBATTLEMECHANICS # Perfect accuracy
    return true if param==2 # Double damage
    return false
  end
end



################################################################################
# Hace que el objetivo retroceda. Falla si el usuario no está dormido.
# (Ronquido/Snore)
################################################################################
class PokeBattle_Move_011 < PokeBattle_Move
  def pbCanUseWhileAsleep?
    return true
  end

  def pbMoveFailed(attacker,opponent)
    return attacker.status!=PBStatuses::SLEEP &&
    (!attacker.hasWorkingAbility(:COMATOSE) ||
    !isConst?(attacker.species,PBSpecies,:KOMALA))
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end
end



################################################################################
# Hace que el objetivo retroceda. Falla si éste no es el primer turno del usuario.
# (Sorpresa/Fake Out)
################################################################################
class PokeBattle_Move_012 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return (attacker.turncount>1)
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end
end



################################################################################
# Confunde al objetivo.
################################################################################
class PokeBattle_Move_013 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    if opponent.pbCanConfuse?(attacker,true,self)
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanConfuse?(attacker,false,self)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
    end
  end
end



################################################################################
# Confunde al objetivo. La probabilidad de causar confusión depende del volúmen del grito grabado.
# La probabilidad de confusión es 0% si el usuario no tiene grabado ningún grito.
# (Cháchara/Chatter)
# TODO: Reproduce el grito actual como parte de la animación del movimiento.
#       @battle.scene.pbChatter(attacker,opponent) sólo reproduce el grito
################################################################################
class PokeBattle_Move_014 < PokeBattle_Move
  def addlEffect
    return 100 if USENEWBATTLEMECHANICS
    if attacker.pokemon && attacker.pokemon.chatter
      return attacker.pokemon.chatter.intensity*10/127
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanConfuse?(attacker,false,self)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
    end
  end
end



################################################################################
# Confunde al objetivo. Precisión perfecta en lluvia, 50% en día soleado.
# (Vendaval/Hurricane)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_015 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    if opponent.pbCanConfuse?(attacker,true,self)
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
      return 0
    end
    return -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanConfuse?(attacker,false,self)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
    end
  end

  def pbModifyBaseAccuracy(baseaccuracy,attacker,opponent)
    case @battle.pbWeather
    when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
      if !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        return 0
      end
    when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
      if !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        return 50
      end
    end
    return baseaccuracy
  end
end



################################################################################
# Enamora al objetivo.
# (Atracción/Attract)
################################################################################
class PokeBattle_Move_016 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbCanAttract?(attacker)
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
        return -1
      elsif opponent.pbPartner.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbPartner.pbThis,PBAbilities.getName(opponent.pbPartner.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbAttract(attacker)
    return 0
  end
end



################################################################################
# Quema, congela o paraliza al objetivo.
# (Triataque/Tri Attack)
################################################################################
class PokeBattle_Move_017 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    case @battle.pbRandom(3)
    when 0
      if opponent.pbCanBurn?(attacker,false,self)
        opponent.pbBurn(attacker)
      end
    when 1
      if opponent.pbCanFreeze?(attacker,false,self)
        opponent.pbFreeze
      end
    when 2
      if opponent.pbCanParalyze?(attacker,false,self)
        opponent.pbParalyze(attacker)
      end
    end
  end
end



################################################################################
# Cura al usuario la quemadura, envenenamiento o parálisis.
# (Alivio/Refresh)
################################################################################
class PokeBattle_Move_018 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status!=PBStatuses::BURN &&
       attacker.status!=PBStatuses::POISON &&
       attacker.status!=PBStatuses::PARALYSIS
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    else
      t=attacker.status
      attacker.pbCureStatus(false)
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      if t==PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",attacker.pbThis))
      elsif t==PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",attacker.pbThis))
      elsif t==PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",attacker.pbThis))
      end
      return 0
    end
  end
end



################################################################################
# Cura a todos los Pokémon del equipo los problemas de estado permanentes.
# (Aromaterapia, Campana Cura/Aromatherapy, Heal Bell)
################################################################################
class PokeBattle_Move_019 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    if isConst?(@id,PBMoves,:AROMATHERAPY)
      @battle.pbDisplay(_INTL("¡Un aroma tranquilizador impregnó la zona!"))
    else
      @battle.pbDisplay(_INTL("¡Ha repicado una campana!"))
    end
    activepkmn=[]
    for i in @battle.battlers
      next if attacker.pbIsOpposing?(i.index) || i.isFainted?
      activepkmn.push(i.pokemonIndex)
      next if USENEWBATTLEMECHANICS && i.index!=attacker.index &&
         pbTypeImmunityByAbility(pbType(@type,attacker,i),attacker,i)
      case i.status
      when PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",i.pbThis))
      when PBStatuses::SLEEP
        @battle.pbDisplay(_INTL("¡{1} se despertó!",i.pbThis))
      when PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",i.pbThis))
      when PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",i.pbThis))
      when PBStatuses::FROZEN
        @battle.pbDisplay(_INTL("¡{1} se descongeló!",i.pbThis))
      end
      i.pbCureStatus(false)
    end
    party=@battle.pbParty(attacker.index) # NOTE: Considers both parties in multi battles
    for i in 0...party.length
      next if activepkmn.include?(i)
      next if !party[i] || party[i].isEgg? || party[i].hp<=0
      case party[i].status
      when PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",party[i].name))
      when PBStatuses::SLEEP
          @battle.pbDisplay(_INTL("¡{1} se despertó!",party[i].name))
      when PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",party[i].name))
      when PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",party[i].name))
      when PBStatuses::FROZEN
        @battle.pbDisplay(_INTL("¡{1} se descongeló!",party[i].name))
      end
      party[i].status=0
      party[i].statusCount=0
    end
    return 0
  end
end



################################################################################
# Protege al equipo del usuario de problemas de estado.
# (Velo Sagrado/Safeguard)
################################################################################
class PokeBattle_Move_01A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::Safeguard]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    attacker.pbOwnSide.effects[PBEffects::Safeguard]=5
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Tu equipo se rodeó de un velo misterioso!"))
    else
      @battle.pbDisplay(_INTL("¡El equipo rival se rodeó de un velo misterioso!"))
    end
    return 0
  end
end



################################################################################
# El usuario pasa su problema de estado al objetivo.
# (Psico-cambio/Psycho Shift)
################################################################################
class PokeBattle_Move_01B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status==0 ||
      (attacker.status==PBStatuses::PARALYSIS && !opponent.pbCanParalyze?(attacker,false,self)) ||
      (attacker.status==PBStatuses::SLEEP && !opponent.pbCanSleep?(attacker,false,self)) ||
      (attacker.status==PBStatuses::POISON && !opponent.pbCanPoison?(attacker,false,self)) ||
      (attacker.status==PBStatuses::BURN && !opponent.pbCanBurn?(attacker,false,self)) ||
      (attacker.status==PBStatuses::FROZEN && !opponent.pbCanFreeze?(attacker,false,self))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    case attacker.status
    when PBStatuses::PARALYSIS
      opponent.pbParalyze(attacker)
      opponent.pbAbilityCureCheck
      attacker.pbCureStatus(false)
      @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",attacker.pbThis))
    when PBStatuses::SLEEP
      opponent.pbSleep
      opponent.pbAbilityCureCheck
      attacker.pbCureStatus(false)
      @battle.pbDisplay(_INTL("¡{1} se despertó!",attacker.pbThis))
    when PBStatuses::POISON
      opponent.pbPoison(attacker,nil,attacker.statusCount!=0)
      opponent.pbAbilityCureCheck
      attacker.pbCureStatus(false)
      @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",attacker.pbThis))
    when PBStatuses::BURN
      opponent.pbBurn(attacker)
      opponent.pbAbilityCureCheck
      attacker.pbCureStatus(false)
      @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",attacker.pbThis))
    when PBStatuses::FROZEN
      opponent.pbFreeze
      opponent.pbAbilityCureCheck
      attacker.pbCureStatus(false)
      @battle.pbDisplay(_INTL("¡{1} se descongeló!",attacker.pbThis))
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque del usuario en 1 nivel.
################################################################################
class PokeBattle_Move_01C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la Defensa del usuario en 1 nivel.
################################################################################
class PokeBattle_Move_01D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la Defensa del usuario en 1 nivel. El usuario se acurruca. (Defense Curl / Rizo Defensa)
################################################################################
class PokeBattle_Move_01E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[PBEffects::DefenseCurl]=true
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self)
    return ret ? 0 : -1
  end
end



################################################################################
# Incrementa la Velocidad del usuario en 1 nivel.
################################################################################
class PokeBattle_Move_01F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa el Ataque Especial del usuario en 1 nivel.
################################################################################
class PokeBattle_Move_020 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la Defensa Especial del usuario en 1 nivel.
# Potencia el siguiente ataque del usuario si es del tipo Eléctrico. (Carga)
################################################################################
class PokeBattle_Move_021 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[PBEffects::Charge]=2
    @battle.pbDisplay(_INTL("¡{1} comenzó a cargar energía!",attacker.pbThis))
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,true,self)
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self)
    end
    return 0
  end
end



################################################################################
# Incrementa la evasión del usuario en 1 nivel.
################################################################################
class PokeBattle_Move_022 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::EVASION,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::EVASION,1,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la probabilidad de golpe crítico del usuario. (Foco Energía)
################################################################################
class PokeBattle_Move_023 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    if attacker.effects[PBEffects::FocusEnergy]>=2
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::FocusEnergy]=2
    @battle.pbDisplay(_INTL("¡{1} se está preparando para luchar!",attacker.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.effects[PBEffects::FocusEnergy]<2
      attacker.effects[PBEffects::FocusEnergy]=2
      @battle.pbDisplay(_INTL("¡{1} se está preparando para luchar!",attacker.pbThis))
    end
  end
end



################################################################################
# Incrementa el Ataque y la Defensa del usuario en 1 nivel cada una. (Corpulencia/Bulk Up)
################################################################################
class PokeBattle_Move_024 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque, la Defensa y la precisión del usuario en 1 nivel cada una. (Enrosque)
################################################################################
class PokeBattle_Move_025 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ACCURACY,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque y la Velocidad del usuario en 1 nivel cada una. (Danza Dragón/Dragon Dance)
################################################################################
class PokeBattle_Move_026 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque y el Ataque Especial del usuario en 1 nivel cada una. (Avivar)
################################################################################
class PokeBattle_Move_027 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque y el Ataque Especial del usuario en 1 nivel cada una.
# Si el clima es Soleado, el incremento es de 2 niveles en lugar de 1. (Desarrollo/Growth)
################################################################################
class PokeBattle_Move_028 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    increment=1
    if (@battle.pbWeather==PBWeather::SUNNYDAY ||
       @battle.pbWeather==PBWeather::HARSHSUN) && !attacker.hasWorkingItem(:UTILITYUMBRELLA)
      increment=2
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,increment,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,increment,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque y la precisión del usuario en 1 nivel cada una. (Afilagarras/Hone Claws)
################################################################################
class PokeBattle_Move_029 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ACCURACY,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa la Defensa y la Defensa Especial del usuario en 1 nivel cada una. (Masa Cósmica/Cosmic Power)
################################################################################
class PokeBattle_Move_02A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque Especial, la Defensa Especial y la Velocidad del usuario en 1 nivel cada una. (Danza Aleteo/Quiver Dance)
################################################################################
class PokeBattle_Move_02B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque Especial y la Defensa Especial del usuario en 1 nivel cada una. (Paz Mental/Calm Mind)
################################################################################
class PokeBattle_Move_02C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa el Ataque, Defensa, Velocidad, Ataque Especial y Defensa Especial del usuario
# en 1 nivel cada una. (Poder Pasado, Vien. Aciago, Viento Plata / AncientPower, Ominous Wind, Silver Wind)
################################################################################
class PokeBattle_Move_02D < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self,showanim)
      showanim=false
    end
  end
end



################################################################################
# Incrementa el Ataque del usuario en 2 niveles.
################################################################################
class PokeBattle_Move_02E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::ATTACK,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,2,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa el Defensa del usuario en 2 niveles.
################################################################################
class PokeBattle_Move_02F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,2,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la Velocidad del usuario en 2 niveles.
################################################################################
class PokeBattle_Move_030 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPEED,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,2,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la Velocidad del usuario en 2 niveles. Reduce el peso del usuario en 100 kg. (Aligerar/Autotomize)
################################################################################
class PokeBattle_Move_031 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPEED,2,attacker,false,self)
    if ret
      attacker.effects[PBEffects::WeightChange]-=1000
      @battle.pbDisplay(_INTL("¡{1} se volvió más ágil!",attacker.pbThis))
    end
    return ret ? 0 : -1
  end
end



################################################################################
# Incrementa el Ataque Especial del usuario en 2 niveles.
################################################################################
class PokeBattle_Move_032 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPATK,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,2,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la Defensa Especial del usuario en 2 niveles.
################################################################################
class PokeBattle_Move_033 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPDEF,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,2,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa la evasión del usuario en 2 niveles. Reducción del usuario. (Reducción/Minimize)
################################################################################
class PokeBattle_Move_034 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    attacker.effects[PBEffects::Minimize]=true
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::EVASION,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    attacker.effects[PBEffects::Minimize]=true
    if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::EVASION,2,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Defensa y la Defensa Especial del usuario en 1 nivel cada una. (Rompecoraza/Shell Smash)
# Incrementa el Ataque, la Velocidad y el Ataque Especial del usuario en 2 niveles cada uno.
################################################################################
class PokeBattle_Move_035 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbReduceStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      showanim=false
    end
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,2,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,2,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,2,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa la Velocidad del usuario en 2 niveles y su Ataque en 1. (Cambiomarcha/Shift Gear)
################################################################################
class PokeBattle_Move_036 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,2,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# Incrementa una característica del usuario al azar en 2 niveles (salvo PS). (Acupresión/Acupressure)
################################################################################
class PokeBattle_Move_037 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.index!=opponent.index
      if (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)) ||
         opponent.pbOwnSide.effects[PBEffects::CraftyShield]
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
    end
    array=[]
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      array.push(i) if opponent.pbCanIncreaseStatStage?(i,attacker,false,self)
    end
    if array.length==0
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",opponent.pbThis))
      return -1
    end
    stat=array[@battle.pbRandom(array.length)]
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbIncreaseStat(stat,2,attacker,false,self)
    return 0
  end
end

################################################################################
# Incrementa la Defensa del usuario en 3 niveles.
################################################################################
class PokeBattle_Move_038 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,3,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,3,attacker,false,self)
    end
  end
end



################################################################################
# Incrementa el Ataque Especial del usuario en 3 niveles.
################################################################################
class PokeBattle_Move_039 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPATK,3,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,3,attacker,false,self)
    end
  end
end



################################################################################
# Reduce los PS del usuario por la mitad de los PS máximos y sube su Ataque al máximo. (Tambor/Belly Drum)
################################################################################
class PokeBattle_Move_03A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp<=(attacker.totalhp/2).floor ||
       !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbReduceHP((attacker.totalhp/2).floor)
    if attacker.hasWorkingAbility(:CONTRARY)
      attacker.stages[PBStats::ATTACK]=-6
      @battle.pbCommonAnimation("StatDown",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} redujo su salud para minimizar su Ataque!",attacker.pbThis))
    else
      attacker.stages[PBStats::ATTACK]=6
      @battle.pbCommonAnimation("StatUp",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} redujo su salud para maximizar su Ataque!",attacker.pbThis))
    end
    return 0
  end
end



################################################################################
# Reduce el Ataque y la Defensa del usuario en 1 nivel cada una.
# (Fuerza Bruta/Superpower)
################################################################################
class PokeBattle_Move_03B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      showanim=true
      if attacker.pbCanReduceStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbReduceStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    return ret
  end
end



################################################################################
# Reduce la Defensa y la Defensa Especial del usuario en 1 nivel cada una.
# (A Bocajarro/Close Combat)
################################################################################
class PokeBattle_Move_03C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      showanim=true
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPDEF,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    return ret
  end
end



################################################################################
# Reduce la Defensa, Defensa Especial y Velocidad del usuario en 1 nivel cada una.
# Los aliados del usuario pierden 1/16 de los PS máximos. (V de Fuego / V-create)
################################################################################
class PokeBattle_Move_03D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbPartner && !attacker.pbPartner.isFainted?
        attacker.pbPartner.pbReduceHP((attacker.pbPartner.totalhp/16).floor,true)
      end
      showanim=true
      if attacker.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPEED,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPDEF,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    return ret
  end
end



################################################################################
# Reduce la Velocidad del usuario en 1 nivel.
################################################################################
class PokeBattle_Move_03E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
      end
    end
    return ret
  end
end



################################################################################
# Reduce el Ataque Especial del usuario en 2 niveles.
################################################################################
class PokeBattle_Move_03F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPATK,2,attacker,false,self)
      end
    end
    return ret
  end
end



################################################################################
# Incrementa el Ataque Especial del objetivo en 1 nivel y lo confunde.
# (Camelo/Flatter)
################################################################################
class PokeBattle_Move_040 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Falló el ataque de {1}!",attacker.pbThis))
      return -1
    end
    ret=-1
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      opponent.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self)
      ret=0
    end
    if opponent.pbCanConfuse?(attacker,true,self)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
      ret=0
    end
    return ret
  end
end



################################################################################
# Incrementa el Ataque del objetivo en 2 niveles y lo confunde.
# (Contoneo/Swagger)
################################################################################
class PokeBattle_Move_041 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Falló el ataque de {1}!",attacker.pbThis))
      return -1
    end
    ret=-1
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      opponent.pbIncreaseStat(PBStats::ATTACK,2,attacker,false,self)
      ret=0
    end
    if opponent.pbCanConfuse?(attacker,true,self)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
      ret=0
    end
    return ret
  end
end



################################################################################
# Reduce el Ataque del objetivo en 1 nivel.
################################################################################
class PokeBattle_Move_042 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker,false,self)
      opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Defensa del objetivo en 1 nivel.
################################################################################
class PokeBattle_Move_043 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Velocidad del objetivo en 1 nivel.
################################################################################
class PokeBattle_Move_044 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
      opponent.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
    end
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if isConst?(@id,PBMoves,:TARSHOT) && !opponent.effects[PBEffects::TarShot]
      opponent.effects[PBEffects::TarShot]=true
      @battle.pbDisplay(_INTL("¡{1} ahora es débil al fuego!",opponent.pbThis))
    end
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    if isConst?(@id,PBMoves,:BULLDOZE) &&
       @battle.field.effects[PBEffects::GrassyTerrain]>0
      return (damagemult/2.0).round
    end
    return damagemult
  end
end


################################################################################
# Reduce el Ataque Especial del objetivo en 1 nivel.
################################################################################
class PokeBattle_Move_045 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPATK,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
      opponent.pbReduceStat(PBStats::SPATK,1,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Defensa Especial del objetivo en 1 nivel.
################################################################################
class PokeBattle_Move_046 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPDEF,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
      opponent.pbReduceStat(PBStats::SPDEF,1,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la precisión del objetivo en 1 nivel.
################################################################################
class PokeBattle_Move_047 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ACCURACY,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::ACCURACY,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::ACCURACY,attacker,false,self)
      opponent.pbReduceStat(PBStats::ACCURACY,1,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la evasión del objetivo en 1 o 2 niveles.
# (Dulce Aroma/Sweet Scent)
################################################################################
class PokeBattle_Move_048 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    increment=(USENEWBATTLEMECHANICS) ? 2 : 1
    ret=opponent.pbReduceStat(PBStats::EVASION,increment,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker,false,self)
      increment=(USENEWBATTLEMECHANICS) ? 2 : 1
      opponent.pbReduceStat(PBStats::EVASION,increment,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la evasión del objetivo en 1 nivel. Elimina todas las barreras y obstáculos
# del lado rival del campo o de ambos lados. (Despejar/Defog)
################################################################################
class PokeBattle_Move_049 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbReduceStat(PBStats::EVASION,1,attacker,false,self)
    opponent.pbOwnSide.effects[PBEffects::Reflect]     = 0
    opponent.pbOwnSide.effects[PBEffects::LightScreen] = 0
    opponent.pbOwnSide.effects[PBEffects::AuroraVeil]  = 0
    opponent.pbOwnSide.effects[PBEffects::Mist]        = 0
    opponent.pbOwnSide.effects[PBEffects::Safeguard]   = 0
    opponent.pbOwnSide.effects[PBEffects::Spikes]      = 0
    opponent.pbOwnSide.effects[PBEffects::StealthRock] = false
    opponent.pbOwnSide.effects[PBEffects::StickyWeb]   = false
    opponent.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
    if USENEWBATTLEMECHANICS
      opponent.pbOpposingSide.effects[PBEffects::Reflect]     = 0
      opponent.pbOpposingSide.effects[PBEffects::LightScreen] = 0
      opponent.pbOpposingSide.effects[PBEffects::AuroraVeil]  = 0
      opponent.pbOpposingSide.effects[PBEffects::Mist]        = 0
      opponent.pbOpposingSide.effects[PBEffects::Safeguard]   = 0
      opponent.pbOpposingSide.effects[PBEffects::Spikes]      = 0
      opponent.pbOpposingSide.effects[PBEffects::StealthRock] = false
    if  @battle.field.effects[PBEffects::ElectricTerrain]>0
        @battle.field.effects[PBEffects::ElectricTerrain]=0
        @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
          @battle.field.effects[PBEffects::GrassyTerrain]=0
          @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
          @battle.field.effects[PBEffects::MistyTerrain]=0
          @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
          @battle.field.effects[PBEffects::PsychicTerrain]=0
          @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que había en el terreno de combate."))
    end
      opponent.pbOpposingSide.effects[PBEffects::StickyWeb]   = false
      opponent.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if !opponent.damagestate.substitute
      if opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker,false,self)
        opponent.pbReduceStat(PBStats::EVASION,1,attacker,false,self)
      end
    end
    opponent.pbOwnSide.effects[PBEffects::Reflect]     = 0
    opponent.pbOwnSide.effects[PBEffects::LightScreen] = 0
    opponent.pbOwnSide.effects[PBEffects::AuroraVeil]  = 0
    opponent.pbOwnSide.effects[PBEffects::Mist]        = 0
    opponent.pbOwnSide.effects[PBEffects::Safeguard]   = 0
    opponent.pbOwnSide.effects[PBEffects::Spikes]      = 0
    opponent.pbOwnSide.effects[PBEffects::StealthRock] = false
    opponent.pbOwnSide.effects[PBEffects::StickyWeb]   = false
    opponent.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
    if USENEWBATTLEMECHANICS
      opponent.pbOpposingSide.effects[PBEffects::Reflect]     = 0
      opponent.pbOpposingSide.effects[PBEffects::LightScreen] = 0
      opponent.pbOpposingSide.effects[PBEffects::AuroraVeil]  = 0
      opponent.pbOpposingSide.effects[PBEffects::Mist]        = 0
      opponent.pbOpposingSide.effects[PBEffects::Safeguard]   = 0
      opponent.pbOpposingSide.effects[PBEffects::Spikes]      = 0
      opponent.pbOpposingSide.effects[PBEffects::StealthRock] = false
    if  @battle.field.effects[PBEffects::ElectricTerrain]>0
        @battle.field.effects[PBEffects::ElectricTerrain]=0
        @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
          @battle.field.effects[PBEffects::GrassyTerrain]=0
          @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
          @battle.field.effects[PBEffects::MistyTerrain]=0
          @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
          @battle.field.effects[PBEffects::PsychicTerrain]=0
          @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que había en el terreno de combate."))
    end
      opponent.pbOpposingSide.effects[PBEffects::StickyWeb]   = false
      opponent.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0
    end
  end
end



################################################################################
# Reduce el Ataque y la Defensa del objetivo en 1 nivel cada una.
# (Cosquillas/Tickle)
################################################################################
class PokeBattle_Move_04A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    # Duplica def pbCanReduceStatStage? de forma que ciertos mensajes no sean mostrados
    # repetidas veces
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Falló el ataque de {1}!",attacker.pbThis))
      return -1
    end
    if opponent.pbTooLow?(PBStats::ATTACK) &&
       opponent.pbTooLow?(PBStats::DEFENSE)
      @battle.pbDisplay(_INTL("¡Las características de {1} no bajarán más!",opponent.pbThis))
      return -1
    end
    if opponent.pbOwnSide.effects[PBEffects::Mist]>0
      @battle.pbDisplay(_INTL("¡{1} se ha protegido con Neblina!",opponent.pbThis))
      return -1
    end
    if opponent.hasWorkingAbility(:FULLMETALBODY)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita la pérdida de características!",opponent.pbThis,
           PBAbilities.getName(opponent.ability)))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:CLEARBODY) ||
         opponent.hasWorkingAbility(:WHITESMOKE) ||
         opponent.hasWorkingItem(:CLEARAMULET)
        @battle.pbDisplay(_INTL("¡{2} de {1} evita la pérdida de características!",opponent.pbThis,
           PBAbilities.getName(opponent.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:HYPERCUTTER) &&
       !opponent.pbTooLow?(PBStats::ATTACK)
      abilityname=PBAbilities.getName(opponent.ability)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita que baje el Ataque!",opponent.pbThis,abilityname))
    elsif opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      ret=0; showanim=false
    end
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:BIGPECKS) &&
       !opponent.pbTooLow?(PBStats::DEFENSE)
      abilityname=PBAbilities.getName(opponent.ability)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita que baje la Defensa!",opponent.pbThis,abilityname))
    elsif opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      ret=0; showanim=false
    end
    return ret
  end
end



################################################################################
# Reduce el Ataque del objetivo en 2 niveles.
################################################################################
class PokeBattle_Move_04B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::ATTACK,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker,false,self)
      opponent.pbReduceStat(PBStats::ATTACK,2,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Defensa del objetivo en 2 niveles. (Chirrido/Screech)
################################################################################
class PokeBattle_Move_04C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::DEFENSE,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      opponent.pbReduceStat(PBStats::DEFENSE,2,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Velocidad del objetivo en 2 niveles.
# (Esporagodón, Cara Susto, Disparo Demora / Cotton Spore, Scary Face, String Shot)
################################################################################
class PokeBattle_Move_04D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    increment=(isConst?(@id,PBMoves,:STRINGSHOT) && !USENEWBATTLEMECHANICS) ? 1 : 2
    ret=opponent.pbReduceStat(PBStats::SPEED,increment,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
      increment=(isConst?(@id,PBMoves,:STRINGSHOT) && !USENEWBATTLEMECHANICS) ? 1 : 2
      opponent.pbReduceStat(PBStats::SPEED,increment,attacker,false,self)
    end
  end
end



################################################################################
# Reduce el Ataque Especial del objetivo en 2 niveles. Solo funciona con el género opuesto.
# (Seducción/Captivate)
################################################################################
class PokeBattle_Move_04E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,true,self)
    if attacker.gender==2 || opponent.gender==2 || attacker.gender==opponent.gender
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:OBLIVIOUS)
      @battle.pbDisplay(_INTL("¡{2} de {1} evitó el enamoramiento!",opponent.pbThis,
         PBAbilities.getName(opponent.ability)))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPATK,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if attacker.gender!=2 && opponent.gender!=2 && attacker.gender!=opponent.gender
      if attacker.hasMoldBreaker || !opponent.hasWorkingAbility(:OBLIVIOUS)
        if opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
          opponent.pbReduceStat(PBStats::SPATK,2,attacker,false,self)
        end
      end
    end
  end
end



################################################################################
# Reduce el Ataque Especial del objetivo en 2 niveles. (Eerie Impulse)
################################################################################
class PokeBattle_Move_13D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPATK,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
      opponent.pbReduceStat(PBStats::SPATK,2,attacker,false,self)
    end
  end
end



################################################################################
# Reduce la Defensa Especial del objetivo en 2 niveles.
################################################################################
class PokeBattle_Move_04F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPDEF,2,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
      opponent.pbReduceStat(PBStats::SPDEF,2,attacker,false,self)
    end
  end
end



################################################################################
# Reinicia las características de todos los objetivos a 0.
# (Nieblaclara/Clear Smog)
################################################################################
class PokeBattle_Move_050 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
      opponent.stages[PBStats::ATTACK]   = 0
      opponent.stages[PBStats::DEFENSE]  = 0
      opponent.stages[PBStats::SPEED]    = 0
      opponent.stages[PBStats::SPATK]    = 0
      opponent.stages[PBStats::SPDEF]    = 0
      opponent.stages[PBStats::ACCURACY] = 0
      opponent.stages[PBStats::EVASION]  = 0
      @battle.pbDisplay(_INTL("¡Los cambios de características de {1} fueron eliminados!",opponent.pbThis))
    end
    return ret
  end
end



################################################################################
# Reinicia los niveles de todas las características de todos los combatientes a 0.
# (Niebla/Haze)
################################################################################
class PokeBattle_Move_051 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for i in 0...4
      @battle.battlers[i].stages[PBStats::ATTACK]   = 0
      @battle.battlers[i].stages[PBStats::DEFENSE]  = 0
      @battle.battlers[i].stages[PBStats::SPEED]    = 0
      @battle.battlers[i].stages[PBStats::SPATK]    = 0
      @battle.battlers[i].stages[PBStats::SPDEF]    = 0
      @battle.battlers[i].stages[PBStats::ACCURACY] = 0
      @battle.battlers[i].stages[PBStats::EVASION]  = 0
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡Se eliminaron todos los cambios de estado!"))
    return 0
  end
end



################################################################################
# El usuario y el objetivo intercambian los niveles de Ataque y Ataque Especial.
# (Cambia Fue./Power Swap)
################################################################################
class PokeBattle_Move_052 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    astage=attacker.stages
    ostage=opponent.stages
    astage[PBStats::ATTACK],ostage[PBStats::ATTACK]=ostage[PBStats::ATTACK],astage[PBStats::ATTACK]
    astage[PBStats::SPATK],ostage[PBStats::SPATK]=ostage[PBStats::SPATK],astage[PBStats::SPATK]
    @battle.pbDisplay(_INTL("¡{1} intercambió todos los cambios de Ataque y Ataque Especial con el objetivo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# El usuario y el objetivo intercambian los niveles de Defensa y Defensa Especial.
# (Cambia Defensa/Guard Swap)
################################################################################
class PokeBattle_Move_053 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    astage=attacker.stages
    ostage=opponent.stages
    astage[PBStats::DEFENSE],ostage[PBStats::DEFENSE]=ostage[PBStats::DEFENSE],astage[PBStats::DEFENSE]
    astage[PBStats::SPDEF],ostage[PBStats::SPDEF]=ostage[PBStats::SPDEF],astage[PBStats::SPDEF]
    @battle.pbDisplay(_INTL("¡{1} intercambió todos los cambios de Defensa y Defensa Especial con el objetivo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# El usuario y el objetivo intercambian los niveles de todas las características.
# (Cambia Almas/Heart Swap)
################################################################################
class PokeBattle_Move_054 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      attacker.stages[i],opponent.stages[i]=opponent.stages[i],attacker.stages[i]
    end
    @battle.pbDisplay(_INTL("¡{1} intercambió los cambios de características con el objetivo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# El usuario copia los niveles de las características del objetivo.
# (Más Psique/Psych Up)
################################################################################
class PokeBattle_Move_055 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      attacker.stages[i]=opponent.stages[i]
    end
    @battle.pbDisplay(_INTL("¡{1} copió las nuevas características de {2}!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end



################################################################################
# Durante 5 rondas, los niveles de las características del usuario y aliados
# no pueden ser bajadas por los rivales.
# (Neblina/Mist)
################################################################################
class PokeBattle_Move_056 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::Mist]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::Mist]=5
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Neblina ha cubierto a tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡Neblina ha cubierto al equipo enemigo!"))
    end
    return 0
  end
end



################################################################################
# Intercambia las características de Ataque y Defensa del usuario.
# (Truco Fuerza/Power Trick)
################################################################################
class PokeBattle_Move_057 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.attack,attacker.defense=attacker.defense,attacker.attack
    attacker.effects[PBEffects::PowerTrick]=!attacker.effects[PBEffects::PowerTrick]
    @battle.pbDisplay(_INTL("¡{1} cambió su Ataque y Defensa!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Promedia el Ataque del usuario y el objetivo.
# Promedia el Ataque Especial del usuario y el objetivo.
# (Isofuerza/Power Split)
################################################################################
class PokeBattle_Move_058 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    avatk=((attacker.attack+opponent.attack)/2).floor
    avspatk=((attacker.spatk+opponent.spatk)/2).floor
    attacker.attack=opponent.attack=avatk
    attacker.spatk=opponent.spatk=avspatk
    @battle.pbDisplay(_INTL("¡{1} comparte su fuerza con el objetivo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Promedia la Defensa del usuario y el objetivo.
# Promedia la Defensa Especial del usuario y el objetivo.
# (Isoguardia/Guard Split)
################################################################################
class PokeBattle_Move_059 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    avdef=((attacker.defense+opponent.defense)/2).floor
    avspdef=((attacker.spdef+opponent.spdef)/2).floor
    attacker.defense=opponent.defense=avdef
    attacker.spdef=opponent.spdef=avspdef
    @battle.pbDisplay(_INTL("¡{1} comparte su guardia con el objetivo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Promedia los PS actuales del usuario y el objetivo.
# (Divide Dolor/Pain Split)
################################################################################
class PokeBattle_Move_05A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    olda=attacker.hp
    oldo=opponent.hp
    avhp=((attacker.hp+opponent.hp)/2).floor
    attacker.hp=[avhp,attacker.totalhp].min
    opponent.hp=[avhp,opponent.totalhp].min
    @battle.scene.pbHPChanged(attacker,olda)
    @battle.scene.pbHPChanged(opponent,oldo)
    @battle.pbDisplay(_INTL("¡Los combatientes comparten el daño sufrido!"))
    return 0
  end
end



################################################################################
# Durante 4 rondas, duplica la Velocidad de todos los combatientes del lado del usuario.
# (Viento Afín/Tailwind)
################################################################################
class PokeBattle_Move_05B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::Tailwind]=4
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Viento Afín sopla a favor de tu equipo!"))
      if attacker.hasWorkingAbility(:WINDPOWER)
        attacker.effects[PBEffects::Charge]=2
        @battle.pbAnimation(getConst(PBMoves,:CHARGE),attacker,nil)
        @battle.pbDisplay(_INTL("¡{1} comenzó a cargar energía!",attacker.pbThis))
      end
      if attacker.hasWorkingAbility(:WINDRIDER) && attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
      end
    else
      @battle.pbDisplay(_INTL("¡Viento Afín sopla a favor del equipo enemigo!"))
    end
    return 0
  end
end



################################################################################
# Este movimiento se convierte en el último movimiento usado por el objetivo,
# hasta que el usuario sea cambiado.
# out. (Mimético/Mimic)
################################################################################
class PokeBattle_Move_05C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
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
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    for i in attacker.moves
      if i.id==opponent.lastMoveUsed
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...attacker.moves.length
      if attacker.moves[i].id==@id
        newmove=PBMove.new(opponent.lastMoveUsed)
        attacker.moves[i]=PokeBattle_Move.pbFromPBMove(@battle,newmove)
        movename=PBMoves.getName(opponent.lastMoveUsed)
        @battle.pbDisplay(_INTL("¡{1} aprendió {2}!",attacker.pbThis,movename))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end



################################################################################
# Este movimiento se convierte permanentemente en el último movimiento utilizado por el objetivo.
# (Esquema/Sketch)
################################################################################
class PokeBattle_Move_05D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,   # Struggle
       0x14,   # Chatter
       0x5D    # Sketch
    ]
    if attacker.effects[PBEffects::Transform] ||
       opponent.lastMoveUsedSketch<=0 ||
       isConst?(PBMoveData.new(opponent.lastMoveUsedSketch).type,PBTypes,:SHADOW) ||
       blacklist.include?(PBMoveData.new(opponent.lastMoveUsedSketch).function)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    for i in attacker.moves
      if i.id==opponent.lastMoveUsedSketch
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
    end
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    for i in 0...attacker.moves.length
      if attacker.moves[i].id==@id
        newmove=PBMove.new(opponent.lastMoveUsedSketch)
        attacker.moves[i]=PokeBattle_Move.pbFromPBMove(@battle,newmove)
        party=@battle.pbParty(attacker.index)
        party[attacker.pokemonIndex].moves[i]=newmove
        movename=PBMoves.getName(opponent.lastMoveUsedSketch)
        @battle.pbDisplay(_INTL("¡{1} usó Esquema en {2}!",attacker.pbThis,movename))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end



################################################################################
# Cambia el tipo del usuario por el tipo de uno de los demás movimientos del usuario
# elegido al azar, O por el tipo del primer movimiento del usuario.
# (Conversión/Conversion)
################################################################################
class PokeBattle_Move_05E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if isConst?(attacker.ability,PBAbilities,:MULTITYPE)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    types=[]
    for i in attacker.moves
      next if i.id==@id
      next if PBTypes.isPseudoType?(i.type)
      next if attacker.pbHasType?(i.type)
      if !types.include?(i.type)
        types.push(i.type)
        break if USENEWBATTLEMECHANICS
      end
    end
    if types.length==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    newtype=types[@battle.pbRandom(types.length)]
    attacker.type1=newtype
    attacker.type2=newtype
    attacker.effects[PBEffects::Type3]=-1
    typename=PBTypes.getName(newtype)
    @battle.pbDisplay(_INTL("¡{1} se transformó en el tipo {2}!",attacker.pbThis,typename))
  end
end



################################################################################
# Cambia el tipo del usuario por uno al azar que sea resistente o tenga inmunidad al
# último movimiento usado por el objetivo.
# (Conversión2/Conversion 2)
################################################################################
class PokeBattle_Move_05F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if isConst?(attacker.ability,PBAbilities,:MULTITYPE)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.lastMoveUsed<=0 ||
       PBTypes.isPseudoType?(PBMoveData.new(opponent.lastMoveUsed).type)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    types=[]
    atype=opponent.lastMoveUsedType
    if atype<0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    for i in 0..PBTypes.maxValue
      next if PBTypes.isPseudoType?(i)
      next if attacker.pbHasType?(i)
      types.push(i) if PBTypes.getEffectiveness(atype,i)<2
    end
    if types.length==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    newtype=types[@battle.pbRandom(types.length)]
    attacker.type1=newtype
    attacker.type2=newtype
    attacker.effects[PBEffects::Type3]=-1
    typename=PBTypes.getName(newtype)
    @battle.pbDisplay(_INTL("¡{1} se transformó en el tipo {2}!",attacker.pbThis,typename))
    return 0
  end
end



################################################################################
# Modifica el tipo del Pokémon según el terreno de combate donde esté.
# (Camuflaje/Camouflage)
################################################################################
class PokeBattle_Move_060 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if isConst?(attacker.ability,PBAbilities,:MULTITYPE)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    type=getConst(PBTypes,:NORMAL) || 0
    case @battle.environment
    when PBEnvironment::None;        type=getConst(PBTypes,:NORMAL) || 0
    when PBEnvironment::Grass;       type=getConst(PBTypes,:GRASS) || 0
    when PBEnvironment::TallGrass;   type=getConst(PBTypes,:GRASS) || 0
    when PBEnvironment::MovingWater; type=getConst(PBTypes,:WATER) || 0
    when PBEnvironment::StillWater;  type=getConst(PBTypes,:WATER) || 0
    when PBEnvironment::Underwater;  type=getConst(PBTypes,:WATER) || 0
    when PBEnvironment::Cave;        type=getConst(PBTypes,:ROCK) || 0
    when PBEnvironment::Rock;        type=getConst(PBTypes,:GROUND) || 0
    when PBEnvironment::Sand;        type=getConst(PBTypes,:GROUND) || 0
    when PBEnvironment::Forest;      type=getConst(PBTypes,:BUG) || 0
    when PBEnvironment::Snow;        type=getConst(PBTypes,:ICE) || 0
    when PBEnvironment::Volcano;     type=getConst(PBTypes,:FIRE) || 0
    when PBEnvironment::Graveyard;   type=getConst(PBTypes,:GHOST) || 0
    when PBEnvironment::Sky;         type=getConst(PBTypes,:FLYING) || 0
    when PBEnvironment::Space;       type=getConst(PBTypes,:DRAGON) || 0
    end
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      type=getConst(PBTypes,:ELECTRIC) if hasConst?(PBTypes,:ELECTRIC)
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
      type=getConst(PBTypes,:GRASS) if hasConst?(PBTypes,:GRASS)
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
      type=getConst(PBTypes,:FAIRY) if hasConst?(PBTypes,:FAIRY)
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
      type=getConst(PBTypes,:PSYCHIC) if hasConst?(PBTypes,:PSYCHIC)
    end
    if attacker.pbHasType?(type)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.type1=type
    attacker.type2=type
    attacker.effects[PBEffects::Type3]=-1
    typename=PBTypes.getName(type)
    @battle.pbDisplay(_INTL("¡{1} se transformó en el tipo {2}!",attacker.pbThis,typename))
    return 0
  end
end



################################################################################
# El objetivo se convierte en tipo Agua (Anegar/Soak) o en tipo Psíquico (Polvo
# Mágico/Magic Powder).
################################################################################
class PokeBattle_Move_061 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.isTera?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    if isConst?(opponent.ability,PBAbilities,:MULTITYPE) &&
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    if isConst?(@id,PBMoves,:SOAK)
      if opponent.type1==getConst(PBTypes,:WATER) &&
         opponent.type2==getConst(PBTypes,:WATER) &&
        (opponent.effects[PBEffects::Type3]<0 ||
        opponent.effects[PBEffects::Type3]==getConst(PBTypes,:WATER))
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
    elsif isConst?(@id,PBMoves,:MAGICPOWDER)
      if opponent.type1==getConst(PBTypes,:PSYCHIC) &&
         opponent.type2==getConst(PBTypes,:PSYCHIC) &&
        (opponent.effects[PBEffects::Type3]<0 ||
        opponent.effects[PBEffects::Type3]==getConst(PBTypes,:PSYCHIC))
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
    end
    if isConst?(@id,PBMoves,:SOAK)
      opponent.type1=getConst(PBTypes,:WATER)
      opponent.type2=getConst(PBTypes,:WATER)
      opponent.effects[PBEffects::Type3]=-1
      typename=PBTypes.getName(getConst(PBTypes,:WATER))
    elsif isConst?(@id,PBMoves,:MAGICPOWDER)
      opponent.type1=getConst(PBTypes,:PSYCHIC)
      opponent.type2=getConst(PBTypes,:PSYCHIC)
      opponent.effects[PBEffects::Type3]=-1
      typename=PBTypes.getName(getConst(PBTypes,:PSYCHIC))
    end
    @battle.pbDisplay(_INTL("¡{1} se transformó en el tipo {2}!",opponent.pbThis,typename))
    return 0
  end
end



################################################################################
# El usuario copia los tipos del objetivo.
# (Clonatipo/Reflect Type)
################################################################################
class PokeBattle_Move_062 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if isConst?(attacker.ability,PBAbilities,:MULTITYPE)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if attacker.pbHasType?(opponent.type1) &&
       attacker.pbHasType?(opponent.type2) &&
       attacker.pbHasType?(opponent.effects[PBEffects::Type3]) &&
       opponent.pbHasType?(attacker.type1) &&
       opponent.pbHasType?(attacker.type2) &&
       opponent.pbHasType?(attacker.effects[PBEffects::Type3])
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.type1=opponent.type1
    attacker.type2=opponent.type2
    attacker.effects[PBEffects::Type3]=-1
    @battle.pbDisplay(_INTL("¡{1} ahora es del mismo tipo que {2}!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end



################################################################################
# La habilidad del objetivo cambia a Simple. (Onda Simple/Simple Beam)
################################################################################
class PokeBattle_Move_063 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:SIMPLE) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:ZEROTOHERO) ||
       opponent.hasWorkingItem(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldabil=opponent.ability
    opponent.ability=getConst(PBAbilities,:SIMPLE) || 0
    abilityname=PBAbilities.getName(getConst(PBAbilities,:SIMPLE))
    @battle.pbDisplay(_INTL("¡La habilidad de {1} ha cambiado a {2}!",opponent.pbThis,abilityname))
    if opponent.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{opponent.pbThis} ha terminado")
      opponent.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",opponent.pbThis,PBAbilities.getName(oldabil)))
    end
    return 0
  end
end



################################################################################
# La habilidad del objetivo cambia a Insomnio. (Abatidoras/Worry Seed)
################################################################################
class PokeBattle_Move_064 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker) ||
       opponent.hasWorkingItem(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    if isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:TRUANT) ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:ZEROTOHERO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldabil=opponent.ability
    opponent.ability=getConst(PBAbilities,:INSOMNIA) || 0
    abilityname=PBAbilities.getName(getConst(PBAbilities,:INSOMNIA))
    @battle.pbDisplay(_INTL("¡La habilidad de {1} ha cambiado a {2}!",opponent.pbThis,abilityname))
    if opponent.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{opponent.pbThis} ha terminado")
      opponent.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",opponent.pbThis,PBAbilities.getName(oldabil)))
    end
    return 0
  end
end



################################################################################
# El usuario copia la habilidad del objetivo. (Imitación/Role Play)
################################################################################
class PokeBattle_Move_065 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.ability==0 ||
       attacker.ability==opponent.ability ||
       isConst?(attacker.ability,PBAbilities,:MULTITYPE) ||
       isConst?(attacker.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(attacker.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(attacker.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(attacker.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(attacker.ability,PBAbilities,:SCHOOLING) ||
       isConst?(attacker.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(attacker.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:FLOWERGIFT) ||
       isConst?(opponent.ability,PBAbilities,:FORECAST) ||
       isConst?(opponent.ability,PBAbilities,:ILLUSION) ||
       isConst?(opponent.ability,PBAbilities,:IMPOSTER) ||
       isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:TRACE) ||
       isConst?(opponent.ability,PBAbilities,:WONDERGUARD) ||
       isConst?(opponent.ability,PBAbilities,:ZENMODE) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:POWEROFALCHEMY) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:RECEIVER) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:ZEROTOHERO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldabil=attacker.ability
    attacker.ability=opponent.ability
    abilityname=PBAbilities.getName(opponent.ability)
    @battle.pbDisplay(_INTL("¡{1} copió {3} de {2}!",attacker.pbThis,opponent.pbThis(true),abilityname))
    if attacker.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{attacker.pbThis} ha terminado")
      attacker.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(attacker,attacker.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",attacker.pbThis,PBAbilities.getName(oldabil)))
    end
    return 0
  end
end



################################################################################
# El objetivo copia la habilidad del usuario. (Danza Amiga/Entrainment)
################################################################################
class PokeBattle_Move_066 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker) ||
       opponent.hasWorkingItem(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if attacker.ability==0 ||
       attacker.ability==opponent.ability ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:FLOWERGIFT) ||
       isConst?(opponent.ability,PBAbilities,:FORECAST) ||
       isConst?(opponent.ability,PBAbilities,:IMPOSTER) ||
       isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:TRACE) ||
       isConst?(opponent.ability,PBAbilities,:TRUANT) ||
       isConst?(opponent.ability,PBAbilities,:ZENMODE) ||
       isConst?(opponent.ability,PBAbilities,:POWEROFALCHEMY) ||
       isConst?(opponent.ability,PBAbilities,:RECEIVER) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:ZEROTOHERO) ||
       isConst?(attacker.ability,PBAbilities,:COMATOSE) ||
       isConst?(attacker.ability,PBAbilities,:DISGUISE) ||
       isConst?(attacker.ability,PBAbilities,:FLOWERGIFT) ||
       isConst?(attacker.ability,PBAbilities,:FORECAST) ||
       isConst?(attacker.ability,PBAbilities,:IMPOSTER) ||
       isConst?(attacker.ability,PBAbilities,:MULTITYPE) ||
       isConst?(attacker.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(attacker.ability,PBAbilities,:TRACE) ||
       isConst?(attacker.ability,PBAbilities,:TRUANT) ||
       isConst?(attacker.ability,PBAbilities,:ZENMODE) ||
       isConst?(attacker.ability,PBAbilities,:POWEROFALCHEMY) ||
       isConst?(attacker.ability,PBAbilities,:RECEIVER) ||
       isConst?(attacker.ability,PBAbilities,:SCHOOLING) ||
       isConst?(attacker.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(attacker.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(attacker.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(attacker.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(attacker.ability,PBAbilities,:ICEFACE) ||
       isConst?(attacker.ability,PBAbilities,:ZEROTOHERO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldabil=opponent.ability
    opponent.ability=attacker.ability
    abilityname=PBAbilities.getName(attacker.ability)
    @battle.pbDisplay(_INTL("¡La habilidad de {1} ha cambiado a {2}!",opponent.pbThis,abilityname))
    if opponent.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{opponent.pbThis} ha terminado")
      opponent.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",opponent.pbThis,PBAbilities.getName(oldabil)))
    end
    return 0
  end
end



################################################################################
# El usuario y el objetivo intercambian sus habilidades. (Intercambio/Skill Swap)
################################################################################
class PokeBattle_Move_067 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (attacker.ability==0 && opponent.ability==0) ||
       (attacker.ability==opponent.ability && !USENEWBATTLEMECHANICS) ||
       isConst?(attacker.ability,PBAbilities,:ILLUSION) ||
       isConst?(opponent.ability,PBAbilities,:ILLUSION) ||
       isConst?(attacker.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(attacker.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(attacker.ability,PBAbilities,:ZENMODE) ||
       isConst?(opponent.ability,PBAbilities,:ZENMODE) ||
       isConst?(attacker.ability,PBAbilities,:WONDERGUARD) ||
       isConst?(opponent.ability,PBAbilities,:WONDERGUARD) ||
       isConst?(attacker.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(attacker.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(attacker.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(attacker.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(attacker.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(attacker.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(attacker.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(attacker.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       isConst?(attacker.ability,PBAbilities,:ZEROTOHERO) ||
       isConst?(opponent.ability,PBAbilities,:ZEROTOHERO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    tmp=attacker.ability
    attacker.ability=opponent.ability
    opponent.ability=tmp
    @battle.pbDisplay(_INTL("¡{1} cambió su habilidad {2} por {3} del objetivo!",
       attacker.pbThis,PBAbilities.getName(opponent.ability),
       PBAbilities.getName(attacker.ability)))
    attacker.pbAbilitiesOnSwitchIn(true)
    opponent.pbAbilitiesOnSwitchIn(true)
    return 0
  end
end



################################################################################
# La habilidad del objetivo es anulada. (Bilis/Gastro Acid)
################################################################################
class PokeBattle_Move_068 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker) ||
       opponent.hasWorkingItem(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:ZEROTOHERO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldabil=opponent.ability
    opponent.effects[PBEffects::GastroAcid]=true
    opponent.effects[PBEffects::Truant]=false
    @battle.pbDisplay(_INTL("¡Se suprimió la habilidad de {1}!",opponent.pbThis))
    if opponent.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{opponent.pbThis} ha terminado")
      opponent.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",opponent.pbThis,PBAbilities.getName(oldabil)))
    end
    return 0
  end
end



################################################################################
# El usuario se transforma en el objetivo. (Transform)
################################################################################
class PokeBattle_Move_069 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0xC9,   # Vuelo
       0xCA,   # Excavar
       0xCB,   # Buceo
       0xCC,   # Bote
       0xCD,   # Golpe Umbrío
       0xCE,   # Caída Libre
       0x14D   # Golpe Fantasma
    ]
    if attacker.effects[PBEffects::Transform] ||
       opponent.effects[PBEffects::Transform] ||
       opponent.effects[PBEffects::Illusion] ||
       (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)) ||
       opponent.effects[PBEffects::SkyDrop] ||
       blacklist.include?(PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Transform]=true
    attacker.type1=opponent.type1
    attacker.type2=opponent.type2
    attacker.effects[PBEffects::Type3]=-1
    attacker.ability=opponent.ability
    attacker.attack=opponent.attack
    attacker.defense=opponent.defense
    attacker.speed=opponent.speed
    attacker.spatk=opponent.spatk
    attacker.spdef=opponent.spdef
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      attacker.stages[i]=opponent.stages[i]
    end
    for i in 0...4
      attacker.moves[i]=PokeBattle_Move.pbFromPBMove(
         @battle,PBMove.new(opponent.moves[i].id))
      attacker.moves[i].pp=5
      attacker.moves[i].totalpp=5
    end
    attacker.effects[PBEffects::Disable]=0
    attacker.effects[PBEffects::DisableMove]=0
    @battle.pbDisplay(_INTL("¡{1} se transformó en {2}!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end



################################################################################
# Inflinge siempre 20 PS de daño. (Bomba Sónica/SonicBoom)
################################################################################
class PokeBattle_Move_06A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return pbEffectFixedDamage(20,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Inflinge siempre 40 PS de daño. (Furia Dragón/Dragon Rage)
################################################################################
class PokeBattle_Move_06B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return pbEffectFixedDamage(40,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Reduce a la mitad los PS actuales del objetivo. (Superdiente/Super Fang)
################################################################################
class PokeBattle_Move_06C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return pbEffectFixedDamage([(opponent.hp/2).floor,1].max,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Inflinge daño igual al nivel del usuario.
# (Tinieblas, Movimiento Sísmico / Night Shade, Seismic Toss)
################################################################################
class PokeBattle_Move_06D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return pbEffectFixedDamage(attacker.level,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Reduce los PS del objetivo para que igualen a los del atacante.
# (Esfuerzo/Endeavor)
################################################################################
class PokeBattle_Move_06E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp>=opponent.hp
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return pbEffectFixedDamage(opponent.hp-attacker.hp,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Inflinge un daño entre 0,5 y 1,5 veces el nivel del usuario.
# (Psicoonda/Psywave)
################################################################################
class PokeBattle_Move_06F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    dmg=[(attacker.level*(@battle.pbRandom(101)+50)/100).floor,1].max
    return pbEffectFixedDamage(dmg,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# KO de un golpe. La precisión incrementa por diferencia entre los niveles del usuario y el objetivo.
################################################################################
class PokeBattle_Move_070 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:STURDY)
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo con {2}!",opponent.pbThis,PBAbilities.getName(opponent.ability)))
      return false
    end
    if opponent.level>attacker.level
      @battle.pbDisplay(_INTL("¡{1} no se vió afectado!",opponent.pbThis))
      return false
    end
    acc=@accuracy+attacker.level-opponent.level
    return @battle.pbRandom(100)<acc
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if isConst?(@id,PBMoves,:SHEERCOLD) && opponent.pbHasType?(:ICE)
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
      return -1
    end
    damage=pbEffectFixedDamage(opponent.totalhp,attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.isFainted?
      @battle.pbDisplay(_INTL("¡K.O. en 1 golpe!"))
    end
    return damage
  end
end


################################################################################
# Contraataca un movimiento físico usado contra el usuario en la misma ronda,
# con el doble de potencia.
# (Contraataque/Counter)
################################################################################
class PokeBattle_Move_071 < PokeBattle_Move
  def pbAddTarget(targets,attacker)
    if attacker.effects[PBEffects::CounterTarget]>=0 &&
       attacker.pbIsOpposing?(attacker.effects[PBEffects::CounterTarget])
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[PBEffects::CounterTarget]])
        attacker.pbRandomTarget(targets)
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Counter]<0 || !opponent
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ret=pbEffectFixedDamage([attacker.effects[PBEffects::Counter]*2,1].max,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end



################################################################################
# Contraataca un movimiento especial usado contra el usuario en la misma ronda,
# con el doble de potencia.
# (Manto Espejo/Mirror Coat)
################################################################################
class PokeBattle_Move_072 < PokeBattle_Move
  def pbAddTarget(targets,attacker)
    if attacker.effects[PBEffects::MirrorCoatTarget]>=0 &&
       attacker.pbIsOpposing?(attacker.effects[PBEffects::MirrorCoatTarget])
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[PBEffects::MirrorCoatTarget]])
        attacker.pbRandomTarget(targets)
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::MirrorCoat]<0 || !opponent
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ret=pbEffectFixedDamage([attacker.effects[PBEffects::MirrorCoat]*2,1].max,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end



################################################################################
# Contraataca el último movimiento de daño usado contra el usuario en la misma ronda,
# con 1,5x de potencia.
# (Repr. Metal/Metal Burst)
################################################################################
class PokeBattle_Move_073 < PokeBattle_Move
  def pbAddTarget(targets,attacker)
    if attacker.lastAttacker.length>0
      lastattacker=attacker.lastAttacker[attacker.lastAttacker.length-1]
      if lastattacker>=0 && attacker.pbIsOpposing?(lastattacker)
        if !attacker.pbAddTarget(targets,@battle.battlers[lastattacker])
          attacker.pbRandomTarget(targets)
        end
      end
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.lastHPLost==0 || !opponent
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ret=pbEffectFixedDamage([(attacker.lastHPLost*1.5).floor,1].max,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end



################################################################################
# Los aliados del objetivo pierden 1/16 de sus PS máximos.
# (Pirotecnia/Flame Burst)
################################################################################
class PokeBattle_Move_074 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if opponent.pbPartner && !opponent.pbPartner.isFainted? &&
         !opponent.pbPartner.hasWorkingAbility(:MAGICGUARD)
        opponent.pbPartner.pbReduceHP((opponent.pbPartner.totalhp/16).floor)
        @battle.pbDisplay(_INTL("El golpe de las llamas también alcanza a {1}",opponent.pbPartner.pbThis(true)))
      end
    end
    return ret
  end
end



################################################################################
# La potencia se duplica si el objetivo estó usando Buceo. (Surf)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_075 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCB # Buceo
      return (damagemult*2.0).round
    end
    return damagemult
  end
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if isConst?(attacker.species,PBSpecies,:CRAMORANT) && attacker.hasWorkingAbility(:GULPMISSILE) &&
       attacker.form==0 && !attacker.isFainted?
       if attacker.hp > attacker.totalhp/2
         attacker.form=1
       else
         attacker.form=2
       end
      attacker.pbUpdate(false)
      @battle.scene.pbChangePokemon(attacker,attacker.pokemon)
      PBDebug.log("[Form changed] #{attacker.pbThis} changed to form #{attacker.form}")
    end
  end
end



################################################################################
# La potencia se duplica si el objetivo estó usando Excavar.
# La potencia se reduce a la mitad si el Campo de Hierba está activo.
# (Terremoto/Earthquake)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_076 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    ret=damagemult
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCA # Excavar
      ret=(damagemult*2.0).round
    end
    if @battle.field.effects[PBEffects::GrassyTerrain]>0
      ret=(damagemult/2.0).round
    end
    return ret
  end
end



################################################################################
# La potencia se duplica si el objetivo estó usando Bote, Vuelo o Caída Libre.
# (Tornado/Gust)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_077 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Vuelo
       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC || # Bote
       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCE || # Caída Libre
       opponent.effects[PBEffects::SkyDrop]
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si el objetivo estó usando Bote, Vuelo o Caída Libre.
# Puede hacer que el objetivo retroceda.
# (Ciclón/Twister)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_078 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Vuelo
       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC || # Bote
       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCE || # Caída Libre
       opponent.effects[PBEffects::SkyDrop]
      return basedmg*2
    end
    return basedmg
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end
end



################################################################################
# La potencia se duplica si se ha utilizado Llama Fusión en la misma ronda.
# (Rayo Fusión/Fusion Bolt)
################################################################################
class PokeBattle_Move_079 < PokeBattle_Move
  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if @battle.field.effects[PBEffects::FusionBolt]
      @battle.field.effects[PBEffects::FusionBolt]=false
      @doubled=true
      return (damagemult*2.0).round
    end
    return damagemult
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    @doubled=false
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      @battle.field.effects[PBEffects::FusionFlare]=true
    end
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.damagestate.critical || @doubled
      return super(id,attacker,opponent,1,alltargets,showanimation) # Charged anim
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# La potencia se duplica si se ha utilizado Rayo Fusión en la misma ronda.
# (Llama Fusión/Fusion Flare)
################################################################################
class PokeBattle_Move_07A < PokeBattle_Move
  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if @battle.field.effects[PBEffects::FusionFlare]
      @battle.field.effects[PBEffects::FusionFlare]=false
      return (damagemult*2.0).round
    end
    return damagemult
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      @battle.field.effects[PBEffects::FusionBolt]=true
    end
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.damagestate.critical || @doubled
      return super(id,attacker,opponent,1,alltargets,showanimation) # Charged anim
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# La potencia se duplica si el objetivo está envenenado.
# (Cargatóxica/Venoshock)
################################################################################
class PokeBattle_Move_07B < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.status==PBStatuses::POISON &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker))
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si el objetivo está paralizado. El objetivo se libera de la parálisis.
# (Estímulo/SmellingSalt)
################################################################################
class PokeBattle_Move_07C < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.status==PBStatuses::PARALYSIS &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker))
      return basedmg*2
    end
    return basedmg
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !opponent.isFainted? && opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute && opponent.status==PBStatuses::PARALYSIS
      opponent.pbCureStatus
    end
  end
end



################################################################################
# La potencia se duplica si el objetivo está dormido. El objetivo se despierta.
# (Espabila/Wake-Up Slap)
################################################################################
class PokeBattle_Move_07D < PokeBattle_Move
def pbBaseDamage(basedmg,attacker,opponent)
    if (opponent.status==PBStatuses::SLEEP &&
       (opponent.effects[PBEffects::Substitute]==0 ||
       ignoresSubstitute?(attacker))) || (opponent.hasWorkingAbility(:COMATOSE) &&
       isConst(opponent.species,PBSpecies,:KOMALA) &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)))
      return basedmg*2
    end
    return basedmg
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !opponent.isFainted? && opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute && opponent.status==PBStatuses::SLEEP
      opponent.pbCureStatus
    end
  end
end



################################################################################
# La potencia se duplica es el usuario está quemado, envenenado o paralizado.
# (Imagen/Facade)
################################################################################
class PokeBattle_Move_07E < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.status==PBStatuses::POISON ||
       attacker.status==PBStatuses::BURN ||
       attacker.status==PBStatuses::PARALYSIS
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si el objetivo tiene algún problema de estado.
# (Infortunio/Hex)
################################################################################
class PokeBattle_Move_07F < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (opponent.status>0 &&
       (opponent.effects[PBEffects::Substitute]==0 ||
       ignoresSubstitute?(attacker))) || (opponent.hasWorkingAbility(:COMATOSE) &&
       isConst?(opponent.species,PBSpecies,:KOMALA) &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)))
      return basedmg*2
    end
    return basedmg
  end
end


################################################################################
# La potencia se duplica si el objetivo tiene los PS a la mitad o menos.
# (Salmuera/Brine)
################################################################################
class PokeBattle_Move_080 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.hp<=opponent.totalhp/2
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si el usuario perdió PS debido al movimiento del objetivo
# en la misma ronda.
# (Desquite, Alud / Revenge, Avalanche)
################################################################################
class PokeBattle_Move_081 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.lastHPLost>0 && attacker.lastAttacker.include?(opponent.index)
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si el objetivo ya ha perdido PS en la misma ronda.
# (Buena Baza/Assurance)
################################################################################
class PokeBattle_Move_082 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.tookDamage
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si un aliado del usuario ya ha usado este movimiento en
# la misma ronda.
# (Canon/Round)
# Si un aliado está por usar el mismo movimiento, se ejecuta a continuación,
# ignorando las prioridades.
################################################################################
class PokeBattle_Move_083 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    ret=basedmg
    attacker.pbOwnSide.effects[PBEffects::Round].times do
      ret*=2
    end
    return ret
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      attacker.pbOwnSide.effects[PBEffects::Round]+=1
      if attacker.pbPartner && !attacker.pbPartner.hasMovedThisRound?
        if @battle.choices[attacker.pbPartner.index][0]==1 # Will use a move
          partnermove=@battle.choices[attacker.pbPartner.index][2]
          if partnermove.function==@function
            attacker.pbPartner.effects[PBEffects::MoveNext]=true
            attacker.pbPartner.effects[PBEffects::Quash]=false
          end
        end
      end
    end
    return ret
  end
end



################################################################################
# La potencia se duplica si el objetivo ya se ha movido en la misma ronda.
# (Vendetta/Payback)
################################################################################
class PokeBattle_Move_084 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.choices[opponent.index][0]!=1 ||   # No se ha elegido un movimiento
       opponent.hasMovedThisRound?                # Ya ha usado un movimiento
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si se ha debilitado un compañero del usuario en la ronda anterior.
# (Represalia/Retaliate)
################################################################################
class PokeBattle_Move_085 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if attacker.pbOwnSide.effects[PBEffects::LastRoundFainted]>=0 &&
       attacker.pbOwnSide.effects[PBEffects::LastRoundFainted]==@battle.turncount-1
      return basedmg*2
    end
    return basedmg
  end
end



################################################################################
# La potencia se duplica si el usuario no lleva ningún objeto.
# (Acróbata/Acrobatics)
################################################################################
class PokeBattle_Move_086 < PokeBattle_Move
  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if attacker.item==0
      return (damagemult*2.0).round
    end
    return damagemult
  end
end



################################################################################
# La potencia se duplica con algún clima activo. El tipo cambia depende del clima activo.
# (Meteorobola/Weather Ball)
################################################################################
class PokeBattle_Move_087 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.pbWeather!=0
      return basedmg*2
    end
    return basedmg
  end

  def pbModifyType(type,attacker,opponent)
    type=getConst(PBTypes,:NORMAL) || 0
    case @battle.pbWeather
    when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
      if !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        type=(getConst(PBTypes,:FIRE) || type)
      end
    when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
      if !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        type=(getConst(PBTypes,:WATER) || type)
      end
    when PBWeather::SANDSTORM
      type=(getConst(PBTypes,:ROCK) || type)
    when PBWeather::HAIL
      type=(getConst(PBTypes,:ICE) || type)
    end
    return type
  end
end



################################################################################
# La potencia se duplica si el rival intenta cambiar o usa Ida y Vuelta/Voltiocambio/Última Palabra.
# (Persecución/Pursuit)
# (Handled in Battle's pbAttackPhase): Makes this attack happen before switching.
################################################################################
class PokeBattle_Move_088 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.switching
      return basedmg*2
    end
    return basedmg
  end

  def pbAccuracyCheck(attacker,opponent)
    return true if @battle.switching
    return super(attacker,opponent)
  end
end



################################################################################
# La potencia se incrementa con la felicidad del usuario.
# (Retroceso/Return)
################################################################################
class PokeBattle_Move_089 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [(attacker.happiness*2/5).floor,1].max
  end
end



################################################################################
# La potencia se merma con la felicidad del usuario.
# (Frustración/Frustration)
################################################################################
class PokeBattle_Move_08A < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [((255-attacker.happiness)*2/5).floor,1].max
  end
end



################################################################################
# La potencia se incrementa con los PS del usuario.
# (Estallido, Salpicar / Eruption, Water Spout)
################################################################################
class PokeBattle_Move_08B < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [(150*attacker.hp/attacker.totalhp).floor,1].max
  end
end



################################################################################
# La potencia se incrementa según los PS del oponente.
# (Agarrón, Estrujón / Crush Grip, Wring Out)
################################################################################
class PokeBattle_Move_08C < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [(120*opponent.hp/opponent.totalhp).floor,1].max
  end
end



################################################################################
# La potencia se incrementa mientras el objetivo es más rápido que el usuario.
# (Giro Bola/Gyro Ball)
################################################################################
class PokeBattle_Move_08D < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return [[(25*opponent.pbSpeed/attacker.pbSpeed).floor,150].min,1].max
  end
end



################################################################################
# La potencia se incrementa con los cambios positivos en las características del usuario,
# se ignoran los negativos.
# (Poderreserva/Stored Power)
################################################################################
class PokeBattle_Move_08E < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    mult=1
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      mult+=attacker.stages[i] if attacker.stages[i]>0
    end
    return 20*mult
  end
end



################################################################################
# La potencia se incrementa con los cambios positivos en las características del objetivo,
# se ignoran los negativos.
# (Castigo/Punishment)
################################################################################
class PokeBattle_Move_08F < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    mult=3
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      mult+=opponent.stages[i] if opponent.stages[i]>0
    end
    return [20*mult,200].min
  end
end



################################################################################
# La potencia y el tipo dependen de los IVs del usuario.
# (Poder Oculto/Hidden Power)
################################################################################
class PokeBattle_Move_090 < PokeBattle_Move
  def pbModifyType(type,attacker,opponent)
    hp=pbHiddenPower(attacker.iv)
    type=hp[0]
    return type
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return 60 if USENEWBATTLEMECHANICS
    hp=pbHiddenPower(attacker.iv)
    return hp[1]
  end
end

def pbHiddenPower(iv)
  powermin=30
  powermax=70
  type=0; base=0
  types=[]
  for i in 0..PBTypes.maxValue
    types.push(i) if !PBTypes.isPseudoType?(i) &&
                     !isConst?(i,PBTypes,:NORMAL) && !isConst?(i,PBTypes,:SHADOW)
  end
  type|=(iv[PBStats::HP]&1)
  type|=(iv[PBStats::ATTACK]&1)<<1
  type|=(iv[PBStats::DEFENSE]&1)<<2
  type|=(iv[PBStats::SPEED]&1)<<3
  type|=(iv[PBStats::SPATK]&1)<<4
  type|=(iv[PBStats::SPDEF]&1)<<5
  type=(type*(types.length-1)/63).floor
  hptype=types[type]
  base|=(iv[PBStats::HP]&2)>>1
  base|=(iv[PBStats::ATTACK]&2)
  base|=(iv[PBStats::DEFENSE]&2)<<1
  base|=(iv[PBStats::SPEED]&2)<<2
  base|=(iv[PBStats::SPATK]&2)<<3
  base|=(iv[PBStats::SPDEF]&2)<<4
  base=(base*(powermax-powermin)/63).floor+powermin
  return [hptype,base]
end

################################################################################
# La potencia se duplica con cada uso consecutivo.
# (Cortefuria/Fury Cutter)
################################################################################
class PokeBattle_Move_091 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    basedmg=basedmg<<(attacker.effects[PBEffects::FuryCutter]-1)   # puede ser de 1 a 4
    return basedmg
  end
end



################################################################################
# La potencia es multiplicada por el número de rondas consecutivas en los que este movimiento
# ha sido utilizado por cualquier Pokémon del lado del usuario.
# (Eco Voz/Echoed Voice)
################################################################################
class PokeBattle_Move_092 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    basedmg*=attacker.pbOwnSide.effects[PBEffects::EchoedVoiceCounter] # can be 1 to 5
    return basedmg
  end
end



################################################################################
# El usuario se mantiene furioso hasta el inicio de una ronda en la que no utilice este movimiento.
# (Furia/Rage)
# (Controlado en pbProcessMoveAgainstTarget de Battler): Sube el Ataque en 1 nivel cada
#  vez que pierde PS debido a un movimiento.
################################################################################
class PokeBattle_Move_093 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Rage]=true if ret>0
    @battle.pbDisplay(_INTL("¡{1} está furioso!",attacker.pbThis(true)))
    return ret
  end
end



################################################################################
# Daña o cura aleatoriamente al objetivo.
# (Presente/Present)
################################################################################
class PokeBattle_Move_094 < PokeBattle_Move
  def pbOnStartUse(attacker)
    # Just to ensure that Parental Bond's second hit damages if the first hit does
    @forcedamage=false
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    @forcedamage=true
    return @calcbasedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    @calcbasedmg=1
    r=@battle.pbRandom((@forcedamage) ? 8 : 10)
    if r<4
      @calcbasedmg=40
    elsif r<7
      @calcbasedmg=80
    elsif r<8
      @calcbasedmg=120
    else
      if pbTypeModifier(pbType(@type,attacker,opponent),attacker,opponent)==0
        @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
        return -1
      end
      if opponent.hp==opponent.totalhp
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
      damage=pbCalcDamage(attacker,opponent)          # Consumes Gems even if it will heal
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation)       # Animación de curación
      opponent.pbRecoverHP((opponent.totalhp/4).floor,true)
      @battle.pbDisplay(_INTL("{1} recuperó su salud.",opponent.pbThis))
      return 0
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# La potencia es tomada al azar, se duplica si el objetivo está usando Excavar.
# (Magnitud/Magnitude)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_095 < PokeBattle_Move
  def pbOnStartUse(attacker)
    basedmg=[10,30,50,70,90,110,150]
    magnitudes=[
       4,
       5,5,
       6,6,6,6,
       7,7,7,7,7,7,
       8,8,8,8,
       9,9,
       10
    ]
    magni=magnitudes[@battle.pbRandom(magnitudes.length)]
    @calcbasedmg=basedmg[magni-4]
    @battle.pbDisplay(_INTL("¡Magnitud {1}!",magni))
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    ret=@calcbasedmg
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCA # Dig
      ret*=2
    end
    if @battle.field.effects[PBEffects::GrassyTerrain]>0
      ret=(ret/2.0).round
    end
    return ret
  end
end



################################################################################
# La potencia y el tipo de este movimiento depende de la baya que porta el usuario.
# La baya se destruye.
# (Don Natural/Natural Gift)
################################################################################
class PokeBattle_Move_096 < PokeBattle_Move
  def pbOnStartUse(attacker)
    if !pbIsBerry?(attacker.item) ||
       attacker.effects[PBEffects::Embargo]>0 ||
       @battle.field.effects[PBEffects::MagicRoom]>0 ||
       attacker.hasWorkingAbility(:KLUTZ) ||
       attacker.pbOpposing1.hasWorkingAbility(:UNNERVE) ||
       attacker.pbOpposing2.hasWorkingAbility(:UNNERVE) ||
       attacker.pbOpposing1.hasWorkingAbility(:ASONE1) ||
       attacker.pbOpposing2.hasWorkingAbility(:ASONE1) ||
       attacker.pbOpposing1.hasWorkingAbility(:ASONE2) ||
       attacker.pbOpposing2.hasWorkingAbility(:ASONE2)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return false
    end
    @berry=attacker.item
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    damagearray={
       80 => [:CHERIBERRY,:CHESTOBERRY,:PECHABERRY,:RAWSTBERRY,:ASPEARBERRY,
              :LEPPABERRY,:ORANBERRY,:PERSIMBERRY,:LUMBERRY,:SITRUSBERRY,
              :FIGYBERRY,:WIKIBERRY,:MAGOBERRY,:AGUAVBERRY,:IAPAPABERRY,
              :RAZZBERRY,:OCCABERRY,:PASSHOBERRY,:WACANBERRY,:RINDOBERRY,
              :YACHEBERRY,:CHOPLEBERRY,:KEBIABERRY,:SHUCABERRY,:COBABERRY,
              :PAYAPABERRY,:TANGABERRY,:CHARTIBERRY,:KASIBBERRY,:HABANBERRY,
              :COLBURBERRY,:BABIRIBERRY,:CHILANBERRY,:ROSELIBERRY],
       90 => [:BLUKBERRY,:NANABBERRY,:WEPEARBERRY,:PINAPBERRY,:POMEGBERRY,
              :KELPSYBERRY,:QUALOTBERRY,:HONDEWBERRY,:GREPABERRY,:TAMATOBERRY,
              :CORNNBERRY,:MAGOSTBERRY,:RABUTABERRY,:NOMELBERRY,:SPELONBERRY,
              :PAMTREBERRY],
       100 => [:WATMELBERRY,:DURINBERRY,:BELUEBERRY,:LIECHIBERRY,:GANLONBERRY,
              :SALACBERRY,:PETAYABERRY,:APICOTBERRY,:LANSATBERRY,:STARFBERRY,
              :ENIGMABERRY,:MICLEBERRY,:CUSTAPBERRY,:JABOCABERRY,:ROWAPBERRY,
              :KEEBERRY,:MARANGABERRY]
    }
    for i in damagearray.keys
      data=damagearray[i]
      if data
        for j in data
          if isConst?(@berry,PBItems,j)
            ret=i
            ret+=20 if USENEWBATTLEMECHANICS
            return ret
          end
        end
      end
    end
    return 1
  end

  def pbModifyType(type,attacker,opponent)
    type=getConst(PBTypes,:NORMAL) || 0
    typearray={
       :NORMAL   => [:CHILANBERRY],
       :FIRE     => [:CHERIBERRY,:BLUKBERRY,:WATMELBERRY,:OCCABERRY],
       :WATER    => [:CHESTOBERRY,:NANABBERRY,:DURINBERRY,:PASSHOBERRY],
       :ELECTRIC => [:PECHABERRY,:WEPEARBERRY,:BELUEBERRY,:WACANBERRY],
       :GRASS    => [:RAWSTBERRY,:PINAPBERRY,:RINDOBERRY,:LIECHIBERRY],
       :ICE      => [:ASPEARBERRY,:POMEGBERRY,:YACHEBERRY,:GANLONBERRY],
       :FIGHTING => [:LEPPABERRY,:KELPSYBERRY,:CHOPLEBERRY,:SALACBERRY],
       :POISON   => [:ORANBERRY,:QUALOTBERRY,:KEBIABERRY,:PETAYABERRY],
       :GROUND   => [:PERSIMBERRY,:HONDEWBERRY,:SHUCABERRY,:APICOTBERRY],
       :FLYING   => [:LUMBERRY,:GREPABERRY,:COBABERRY,:LANSATBERRY],
       :PSYCHIC  => [:SITRUSBERRY,:TAMATOBERRY,:PAYAPABERRY,:STARFBERRY],
       :BUG      => [:FIGYBERRY,:CORNNBERRY,:TANGABERRY,:ENIGMABERRY],
       :ROCK     => [:WIKIBERRY,:MAGOSTBERRY,:CHARTIBERRY,:MICLEBERRY],
       :GHOST    => [:MAGOBERRY,:RABUTABERRY,:KASIBBERRY,:CUSTAPBERRY],
       :DRAGON   => [:AGUAVBERRY,:NOMELBERRY,:HABANBERRY,:JABOCABERRY],
       :DARK     => [:IAPAPABERRY,:SPELONBERRY,:COLBURBERRY,:ROWAPBERRY,:MARANGABERRY],
       :STEEL    => [:RAZZBERRY,:PAMTREBERRY,:BABIRIBERRY],
       :FAIRY    => [:ROSELIBERRY,:KEEBERRY]
    }
    for i in typearray.keys
      data=typearray[i]
      if data
        for j in data
          if isConst?(@berry,PBItems,j)
            type=getConst(PBTypes,i) || type
          end
        end
      end
    end
    return type
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if turneffects[PBEffects::TotalDamage]>0
      attacker.pbConsumeItem
    end
  end
end



################################################################################
# La potencia aumenta mientras menos PP le quede a este movimiento.
# (As Oculto/Trump Card)
################################################################################
class PokeBattle_Move_097 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    dmgs=[200,80,60,50,40]
    ppleft=[@pp,4].min             # El PP se reduce antes de usar el movimiento
    basedmg=dmgs[ppleft]
    return basedmg
  end
end



################################################################################
# La potencia aumenta mientras menos PS le quede al usuario.
# (Azote, Inversión / Flail, Reversal)
################################################################################
class PokeBattle_Move_098 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    n=(48*attacker.hp/attacker.totalhp).floor
    ret=20
    ret=40 if n<33
    ret=80 if n<17
    ret=100 if n<10
    ret=150 if n<5
    ret=200 if n<2
    return ret
  end
end



################################################################################
# La pontencia aumenta mientras el usuario sea más rápido que el objetivo.
# (Bola Voltio/Electro Ball)
################################################################################
class PokeBattle_Move_099 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    n=([attacker.pbSpeed,1].max/[opponent.pbSpeed,1].max).floor
    ret=60
    ret=80 if n>=2
    ret=120 if n>=3
    ret=150 if n>=4
    return ret
  end
end



################################################################################
# La potencia aumenta mientras más pesado sea el objetivo.
# (Hierba Lazo, Patada Baja / Grass Knot, Low Kick)
################################################################################
class PokeBattle_Move_09A < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    weight=opponent.weight(attacker)
    ret=20
    ret=40 if weight>=100
    ret=60 if weight>=250
    ret=80 if weight>=500
    ret=100 if weight>=1000
    ret=120 if weight>=2000
    return ret
  end
end



################################################################################
# La potencia aumenta mientras más pesado sea el usuario en relación al objetivo.
# (Golpe Calor, Cuerpopesado / Heat Crash, Heavy Slam)
################################################################################
class PokeBattle_Move_09B < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    n=(attacker.weight/opponent.weight(attacker)).floor
    ret=40
    ret=60 if n>=2
    ret=80 if n>=3
    ret=100 if n>=4
    ret=120 if n>=5
    return ret
  end
end



################################################################################
# Potencia el ataque de un aliado por 1,5 en esta ronda.
# (Refuerzo/Helping Hand)
################################################################################
class PokeBattle_Move_09C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle || opponent.isFainted? ||
       @battle.choices[opponent.index][0]!=1 ||            # No se eligió un movimiento
       opponent.hasMovedThisRound? ||
       opponent.effects[PBEffects::HelpingHand]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::HelpingHand]=true
    @battle.pbDisplay(_INTL("¡{1} está listo para ayudar a {2}!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end



################################################################################
# Debilita ataques de tipo Eléctrico.
# (Chapoteolodo/Mud Sport)
################################################################################
class PokeBattle_Move_09D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if USENEWBATTLEMECHANICS
      if @battle.field.effects[PBEffects::MudSportField]>0
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.field.effects[PBEffects::MudSportField]=5
      @battle.pbDisplay(_INTL("¡Se han debilitado los ataques de tipo Eléctrico!"))
      return 0
    else
      for i in 0...4
        if attacker.battle.battlers[i].effects[PBEffects::MudSport]
          @battle.pbDisplay(_INTL("¡Pero falló!"))
          return -1
        end
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      attacker.effects[PBEffects::MudSport]=true
      @battle.pbDisplay(_INTL("¡Se han debilitado los ataques de tipo Eléctrico!"))
      return 0
    end
    return -1
  end
end



################################################################################
# Debilita ataques de tipo Fuego.
# (Hidrochorro/Water Sport)
################################################################################
class PokeBattle_Move_09E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if USENEWBATTLEMECHANICS
      if @battle.field.effects[PBEffects::WaterSportField]>0
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.field.effects[PBEffects::WaterSportField]=5
      @battle.pbDisplay(_INTL("¡Se han debilitado los ataques de tipo Fuego!"))
      return 0
    else
      for i in 0...4
        if attacker.battle.battlers[i].effects[PBEffects::WaterSport]
          @battle.pbDisplay(_INTL("¡Pero falló!"))
          return -1
        end
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      attacker.effects[PBEffects::WaterSport]=true
      @battle.pbDisplay(_INTL("¡Se han debilitado los ataques de tipo Fuego!"))
      return 0
    end
  end
end



################################################################################
# El tipo del movimiento depende del objeto portado por el usuario.
# (Sentencia, Tecno Shock / Judgment, Techno Blast)
################################################################################
class PokeBattle_Move_09F < PokeBattle_Move
  def pbModifyType(type,attacker,opponent)
    type=getConst(PBTypes,:NORMAL) || 0
    if isConst?(@id,PBMoves,:JUDGMENT)
      type=(getConst(PBTypes,:FIGHTING) || 0) if attacker.hasWorkingItem(:FISTPLATE)
      type=(getConst(PBTypes,:FLYING) || 0)   if attacker.hasWorkingItem(:SKYPLATE)
      type=(getConst(PBTypes,:POISON) || 0)   if attacker.hasWorkingItem(:TOXICPLATE)
      type=(getConst(PBTypes,:GROUND) || 0)   if attacker.hasWorkingItem(:EARTHPLATE)
      type=(getConst(PBTypes,:ROCK) || 0)     if attacker.hasWorkingItem(:STONEPLATE)
      type=(getConst(PBTypes,:BUG) || 0)      if attacker.hasWorkingItem(:INSECTPLATE)
      type=(getConst(PBTypes,:GHOST) || 0)    if attacker.hasWorkingItem(:SPOOKYPLATE)
      type=(getConst(PBTypes,:STEEL) || 0)    if attacker.hasWorkingItem(:IRONPLATE)
      type=(getConst(PBTypes,:FIRE) || 0)     if attacker.hasWorkingItem(:FLAMEPLATE)
      type=(getConst(PBTypes,:WATER) || 0)    if attacker.hasWorkingItem(:SPLASHPLATE)
      type=(getConst(PBTypes,:GRASS) || 0)    if attacker.hasWorkingItem(:MEADOWPLATE)
      type=(getConst(PBTypes,:ELECTRIC) || 0) if attacker.hasWorkingItem(:ZAPPLATE)
      type=(getConst(PBTypes,:PSYCHIC) || 0)  if attacker.hasWorkingItem(:MINDPLATE)
      type=(getConst(PBTypes,:ICE) || 0)      if attacker.hasWorkingItem(:ICICLEPLATE)
      type=(getConst(PBTypes,:DRAGON) || 0)   if attacker.hasWorkingItem(:DRACOPLATE)
      type=(getConst(PBTypes,:DARK) || 0)     if attacker.hasWorkingItem(:DREADPLATE)
      type=(getConst(PBTypes,:FAIRY) || 0)    if attacker.hasWorkingItem(:PIXIEPLATE)
    elsif isConst?(@id,PBMoves,:TECHNOBLAST)
      return getConst(PBTypes,:ELECTRIC) if attacker.hasWorkingItem(:SHOCKDRIVE)
      return getConst(PBTypes,:FIRE)     if attacker.hasWorkingItem(:BURNDRIVE)
      return getConst(PBTypes,:ICE)      if attacker.hasWorkingItem(:CHILLDRIVE)
      return getConst(PBTypes,:WATER)    if attacker.hasWorkingItem(:DOUSEDRIVE)
    elsif isConst?(@id,PBMoves,:MULTIATTACK)
      return getConst(PBTypes,:FIGHTING) if attacker.hasWorkingItem(:FIGHTINGMEMORY)
      return getConst(PBTypes,:FLYING)   if attacker.hasWorkingItem(:FLYINGMEMORY)
      return getConst(PBTypes,:POISON)   if attacker.hasWorkingItem(:POISONMEMORY)
      return getConst(PBTypes,:GROUND)   if attacker.hasWorkingItem(:GROUNDMEMORY)
      return getConst(PBTypes,:ROCK)     if attacker.hasWorkingItem(:ROCKMEMORY)
      return getConst(PBTypes,:BUG)      if attacker.hasWorkingItem(:BUGMEMORY)
      return getConst(PBTypes,:GHOST)    if attacker.hasWorkingItem(:GHOSTMEMORY)
      return getConst(PBTypes,:STEEL)    if attacker.hasWorkingItem(:STEELMEMORY)
      return getConst(PBTypes,:FIRE)     if attacker.hasWorkingItem(:FIREMEMORY)
      return getConst(PBTypes,:WATER)    if attacker.hasWorkingItem(:WATERMEMORY)
      return getConst(PBTypes,:GRASS)    if attacker.hasWorkingItem(:GRASSMEMORY)
      return getConst(PBTypes,:ELECTRIC) if attacker.hasWorkingItem(:ELECTRICMEMORY)
      return getConst(PBTypes,:PSYCHIC)  if attacker.hasWorkingItem(:PSYCHICMEMORY)
      return getConst(PBTypes,:ICE)      if attacker.hasWorkingItem(:ICEMEMORY)
      return getConst(PBTypes,:DRAGON)   if attacker.hasWorkingItem(:DRAGONMEMORY)
      return getConst(PBTypes,:DARK)     if attacker.hasWorkingItem(:DARKMEMORY)
      return getConst(PBTypes,:FAIRY)    if attacker.hasWorkingItem(:FAIRYMEMORY)
    end
    return type
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if isConst?(@id,PBMoves,:TECHNOBLAST)
      anim=0
      anim=1 if isConst?(pbType(@type,attacker,opponent),PBTypes,:ELECTRIC)
      anim=2 if isConst?(pbType(@type,attacker,opponent),PBTypes,:FIRE)
      anim=3 if isConst?(pbType(@type,attacker,opponent),PBTypes,:ICE)
      anim=4 if isConst?(pbType(@type,attacker,opponent),PBTypes,:WATER)
      return super(id,attacker,opponent,anim,alltargets,showanimation) # Type-specific anim
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Este ataque siempre resulta en un golpe crítico.
# (Vaho Gélido, Llave Corsé / Frost Breath, Storm Throw)
################################################################################
class PokeBattle_Move_0A0 < PokeBattle_Move
  def pbCritialOverride(attacker,opponent)
    return true
  end
end



################################################################################
# Durante 5 rondas, los ataques enemigos no podrán ser críticos.
# (Conjuro/Lucky Chant)
################################################################################
class PokeBattle_Move_0A1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::LuckyChant]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::LuckyChant]=5
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡El Conjuro protege a tu equipo de los golpes críticos!"))
    else
      @battle.pbDisplay(_INTL("¡El Conjuro protege al equipo enemigo de los golpes críticos!"))
    end
    return 0
  end
end



################################################################################
# Durante 5 rondas, se debilita la potencia de los movimientos físicos contra
# el equipo del usuario.
# (Reflejo/Reflect)
################################################################################
class PokeBattle_Move_0A2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::Reflect]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::Reflect]=5
    attacker.pbOwnSide.effects[PBEffects::Reflect]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Reflejo subió la Defensa de tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡Reflejo subió la Defensa del equipo enemigo!"))
    end
    return 0
  end
end



################################################################################
# Durante 5 rondas, se debilita la potencia de los ataques especiales contra
# el equipo del usuario.
# (Pantalla Luz / Light Screen)
################################################################################
class PokeBattle_Move_0A3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::LightScreen]=5
    attacker.pbOwnSide.effects[PBEffects::LightScreen]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Pantalla de Luz subió la Defensa Especial de tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡Pantalla de Luz subió la Defensa Especial del equipo enemigo!"))
    end
    return 0
  end
end



################################################################################
# El efecto depende del entorno.
# (Daño Secreto/Secret Power)
################################################################################
class PokeBattle_Move_0A4 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      if opponent.pbCanParalyze?(attacker,false,self)
        opponent.pbParalyze(attacker)
      end
      return
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
      if opponent.pbCanSleep?(attacker,false,self)
        opponent.pbSleep
      end
      return
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
      if opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
        opponent.pbReduceStat(PBStats::SPATK,1,attacker,false,self)
      end
      return
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
      if opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
        opponent.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
      end
      return
    end
    case @battle.environment
    when PBEnvironment::Grass, PBEnvironment::TallGrass, PBEnvironment::Forest
      if opponent.pbCanSleep?(attacker,false,self)
        opponent.pbSleep
      end
    when PBEnvironment::MovingWater, PBEnvironment::Underwater
      if opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker,false,self)
        opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self)
      end
    when PBEnvironment::StillWater, PBEnvironment::Sky
      if opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
        opponent.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
      end
    when PBEnvironment::Sand
      if opponent.pbCanReduceStatStage?(PBStats::ACCURACY,attacker,false,self)
        opponent.pbReduceStat(PBStats::ACCURACY,1,attacker,false,self)
      end
    when PBEnvironment::Rock
      if USENEWBATTLEMECHANICS
        if opponent.pbCanReduceStatStage?(PBStats::ACCURACY,attacker,false,self)
          opponent.pbReduceStat(PBStats::ACCURACY,1,attacker,false,self)
        end
      else
        if opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)
          opponent.pbFlinch(attacker)
        end
      end
    when PBEnvironment::Cave, PBEnvironment::Graveyard, PBEnvironment::Space
      if opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)
        opponent.pbFlinch(attacker)
      end
    when PBEnvironment::Snow
      if opponent.pbCanFreeze?(attacker,false,self)
        opponent.pbFreeze
      end
    when PBEnvironment::Volcano
      if opponent.pbCanBurn?(attacker,false,self)
        opponent.pbBurn(attacker)
      end
    else
      if opponent.pbCanParalyze?(attacker,false,self)
        opponent.pbParalyze(attacker)
      end
    end
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    id=getConst(PBMoves,:BODYSLAM)
    case @battle.environment
    when PBEnvironment::Grass, PBEnvironment::TallGrass
      id=((USENEWBATTLEMECHANICS) ? getConst(PBMoves,:VINEWHIP) : getConst(PBMoves,:NEEDLEARM)) || id
    when PBEnvironment::MovingWater; id=getConst(PBMoves,:WATERPULSE) || id
    when PBEnvironment::StillWater;  id=getConst(PBMoves,:MUDSHOT) || id
    when PBEnvironment::Underwater;  id=getConst(PBMoves,:WATERPULSE) || id
    when PBEnvironment::Cave;        id=getConst(PBMoves,:ROCKTHROW) || id
    when PBEnvironment::Rock;        id=getConst(PBMoves,:MUDSLAP) || id
    when PBEnvironment::Sand;        id=getConst(PBMoves,:MUDSLAP) || id
    when PBEnvironment::Forest;      id=getConst(PBMoves,:RAZORLEAF) || id
    # Ice tiles in Gen 6 should be Ice Shard
    when PBEnvironment::Snow;        id=getConst(PBMoves,:ICESHARD) || id
    when PBEnvironment::Volcano;     id=getConst(PBMoves,:INCINERATE) || id
    when PBEnvironment::Graveyard;   id=getConst(PBMoves,:SHADOWSNEAK) || id
    when PBEnvironment::Sky;         id=getConst(PBMoves,:GUST) || id
    when PBEnvironment::Space;       id=getConst(PBMoves,:SWIFT) || id
    end
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      id=getConst(PBMoves,:THUNDERSHOCK) || id
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
      id=getConst(PBMoves,:VINEWHIP) || id
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
      id=getConst(PBMoves,:FAIRYWIND) || id
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
      id=getConst(PBMoves,:CONFUSION) || id
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation) # Environment-specific anim
  end
end



################################################################################
# Golpea siempre.
################################################################################
class PokeBattle_Move_0A5 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end
end



################################################################################
# Asegura el golpe del ataque del usuario en la siguiente ronda.
# (Fijar Blanco, Telépata / Lock-On, Mind Reader)
################################################################################
class PokeBattle_Move_0A6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::LockOn]=2
    opponent.effects[PBEffects::LockOnPos]=attacker.index
    @battle.pbDisplay(_INTL("¡{1} apuntó a {2}!",attacker.pbThis,opponent.pbThis(true)))
    return 0
  end
end



################################################################################
# Los cambios en la evasión del objetivo son ignorados desde esta ronda en adelante.
# (Profecía, Rastreo / Foresight, Odor Sleuth)
# Los movimientos de tipo Normal y Lucha tienen eficiencia normal contra
# los objetivos de tipo Fantasma.
################################################################################
class PokeBattle_Move_0A7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Foresight]=true
    @battle.pbDisplay(_INTL("¡{1} fue identificado!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Los cambios en la evasión del objetivo son ignorados desde esta ronda en adelante.
# (Gran Ojo/Miracle Eye)
# Los movimientos de tipo Psíquico tienen eficiencia normal contra
# los objetivos de tipo Siniestro.
################################################################################
class PokeBattle_Move_0A8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::MiracleEye]=true
    @battle.pbDisplay(_INTL("¡{1} fue identificado!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Este movimiento ignora los cambios en la Defensa, Defensa Especial y evasión del objetivo.
# (Guardia Baja, Espadasanta / Chip Away, Sacred Sword)
################################################################################
class PokeBattle_Move_0A9 < PokeBattle_Move
# Controlado en superclass def pbAccuracyCheck y def pbCalcDamage, ¡no editar!
end



################################################################################
# El usuario se protege de movimientos con la bandera "B" en esta ronda.
# (Detección, Protección / Detect, Protect)
################################################################################
class PokeBattle_Move_0AA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Protect]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# El equipo del usuario es protegido de movimientos con prioridad mayor a 0 esta ronda.
# (Anticipo/Quick Guard)
################################################################################
class PokeBattle_Move_0AB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::QuickGuard]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 && # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       (!USENEWBATTLEMECHANICS &&
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor)
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::QuickGuard]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Anticipo ha protegido a tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡Anticipo ha protegido al equipo rival!"))
    end
    return 0
  end
end



################################################################################
# El equipo del usuario es protegido de movimientos de objetivos múltiples esta ronda.
# (Vastaguardia/Wide Guard)
################################################################################
class PokeBattle_Move_0AC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::WideGuard]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 && # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       (!USENEWBATTLEMECHANICS &&
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor)
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::WideGuard]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Vastaguardia ha protegido a tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡Vastaguardia ha protegido al equipo rival!"))
    end
    return 0
  end
end



################################################################################
# Ignora las protecciones del objetivo. Si tiene éxito, todos los demás movimientos
# de esta ronda también las ignoran.
# (Amago/Feint)
################################################################################
class PokeBattle_Move_0AD < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if ret>0
      opponent.effects[PBEffects::ProtectNegation]=true
      opponent.pbOwnSide.effects[PBEffects::CraftyShield]=false
    end
    return ret
  end
end



################################################################################
# Utiliza el último movimiento que haya usado el objetivo.
# (Mov. Espejo/Mirror Move)
################################################################################
class PokeBattle_Move_0AE < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.lastMoveUsed<=0 ||
       (PBMoveData.new(opponent.lastMoveUsed).flags&0x10)==0 # flag e: Copyable by Mirror Move
      @battle.pbDisplay(_INTL("¡El Movimiento Espejo falló!"))
      return -1
    end
    attacker.pbUseMoveSimple(opponent.lastMoveUsed,-1,opponent.index)
    return 0
  end
end



################################################################################
# Utiliza el último movimiento que haya sido usado.
# (Copión/Copycat)
################################################################################
class PokeBattle_Move_0AF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x69,    # Transformación
       0x71,    # Contraataque
       0x72,    # Manto Espejo
       0x73,    # Repr. Metal
       0x9C,    # Refuerzo
       0xAA,    # Detección, Protección
       0xAD,    # Amago
       0xB2,    # Robo
       0xE7,    # Mismodestino
       0xE8,    # Aguante
       0xEC,    # Llave Giro, Cola Dragón
       0xF1,    # Antojo, Ladrón
       0xF2,    # Trapicheo, Truco
       0xF3,    # Ofrenda
       0x115,   # Puño Certero
       0x117,   # Señuelo, Polvo Ira
       0x158,   # Eructo
       0x15B,   # Búnker
       0x184,   # Obstrucción
       0x257,   # Telatrampa
       0XAF     # Copión
    ]
    if USENEWBATTLEMECHANICS
      blacklist+=[
         0xEB,    # Rugido, Remolino
         # ataques de dos turnos
         0xC3,    # V. Cortante
         0xC4,    # Rayo Solar, Cuchilla Solar
         0xC5,    # Rayo Gélido
         0xC6,    # Llama Gélida
         0xC7,    # Ataque Aéreo
         0xC8,    # Cabezazo
         0xC9,    # Vuelo
         0xCA,    # Excavar
         0xCB,    # Buceo
         0xCC,    # Bote
         0xCD,    # Golpe Umbrío
         0xCE,    # Caída Libre
         0x14D,   # Golpe Fantasma
         0x14E,   # Geocontrol
         0x190    # Rayo Meteórico
      ]
    end
    if @battle.lastMoveUsed<=0 ||
       blacklist.include?(PBMoveData.new(@battle.lastMoveUsed).function)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    attacker.pbUseMoveSimple(@battle.lastMoveUsed,-1,@battle.lastMoveUser)
    return 0
  end
end



################################################################################
# Usa el movimiento que el objetivo está por usar esta ronda, con x1,5 de potencia.
# (Yo Primero/Me First)
################################################################################
class PokeBattle_Move_0B0 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,    # Combate
       0x14,    # Cháchara
       0x71,    # Contraataque
       0x72,    # Manto Espejo
       0x73,    # Repr. Metal
       0xB0,    # Yo Primero
       0xF1,    # Antojo, Ladrón
       0x115,   # Puño Certero
       0x158    # Eructo
    ]
    oppmove=@battle.choices[opponent.index][2]
    if @battle.choices[opponent.index][0]!=1 || # Didn't choose a move
       opponent.hasMovedThisRound? ||
       !oppmove || oppmove.id<=0 ||
       oppmove.pbIsStatus? ||
       blacklist.include?(oppmove.function)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    attacker.effects[PBEffects::MeFirst]=true
    attacker.pbUseMoveSimple(oppmove.id,-1,-1)
    attacker.effects[PBEffects::MeFirst]=false
    return 0
  end
end



################################################################################
# Esta ronda, refleja todos los movimientos con la bandera "C" dirigidos al usuario
# de vuelta al origen.
# (Capa Mágica/Magic Coat)
################################################################################
class PokeBattle_Move_0B1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::MagicCoat]=true
    @battle.pbDisplay(_INTL("¡{1} se cubrió con Capa Mágica!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Esta ronda, roba todos los movimientos con bandera "D" que se usen.
# (Robo/Snatch)
################################################################################
class PokeBattle_Move_0B2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Snatch]=true
    @battle.pbDisplay(_INTL("¡{1} espera a que su rival haga algún movimiento!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Utiliza un movimientos diferente dependiendo del entorno.
# (Adaptación/Nature Power)
################################################################################
class PokeBattle_Move_0B3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    move=getConst(PBMoves,:TRIATTACK) || 0
    case @battle.environment
    when PBEnvironment::Grass, PBEnvironment::TallGrass, PBEnvironment::Forest
      move=((USENEWBATTLEMECHANICS) ? getConst(PBMoves,:ENERGYBALL) : getConst(PBMoves,:SEEDBOMB)) || move
    when PBEnvironment::MovingWater; move=getConst(PBMoves,:HYDROPUMP) || move
    when PBEnvironment::StillWater;  move=getConst(PBMoves,:MUDBOMB) || move
    when PBEnvironment::Underwater;  move=getConst(PBMoves,:HYDROPUMP) || move
    when PBEnvironment::Cave
      move=((USENEWBATTLEMECHANICS) ? getConst(PBMoves,:POWERGEM) : getConst(PBMoves,:ROCKSLIDE)) || move
    when PBEnvironment::Rock
      move=((USENEWBATTLEMECHANICS) ? getConst(PBMoves,:EARTHPOWER) : getConst(PBMoves,:ROCKSLIDE)) || move
    when PBEnvironment::Sand
      move=((USENEWBATTLEMECHANICS) ? getConst(PBMoves,:EARTHPOWER) : getConst(PBMoves,:EARTHQUAKE)) || move
    # Ice tiles in Gen 6 should be Ice Beam
    when PBEnvironment::Snow
      move=((USENEWBATTLEMECHANICS) ? getConst(PBMoves,:FROSTBREATH) : getConst(PBMoves,:ICEBEAM)) || move
    when PBEnvironment::Volcano;     move=getConst(PBMoves,:LAVAPLUME) || move
    when PBEnvironment::Graveyard;   move=getConst(PBMoves,:SHADOWBALL) || move
    when PBEnvironment::Sky;         move=getConst(PBMoves,:AIRSLASH) || move
    when PBEnvironment::Space;       move=getConst(PBMoves,:DRACOMETEOR) || move
    end
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      move=getConst(PBMoves,:THUNDERBOLT) || move
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
      move=getConst(PBMoves,:ENERGYBALL) || move
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
      move=getConst(PBMoves,:MOONBLAST) || move
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
      move=getConst(PBMoves,:PSYCHIC) || move
    end
    if move==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    thismovename=PBMoves.getName(@id)
    movename=PBMoves.getName(move)
    @battle.pbDisplay(_INTL("¡{1} se convirtió en {2}!",thismovename,movename))
    target=(USENEWBATTLEMECHANICS && opponent) ? opponent.index : -1
    attacker.pbUseMoveSimple(move,-1,target)
    return 0
  end
end



################################################################################
# Utiliza un movimiento al azar entre los conocidos por el usuario.
# Falla si el usuario no está dormido.
# (Sonámbulo/Sleep Talk)
################################################################################
class PokeBattle_Move_0B4 < PokeBattle_Move
  def pbCanUseWhileAsleep?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status!=PBStatuses::SLEEP &&
      (!attacker.hasWorkingAbility(:COMATOSE) ||
      !isConst?(attacker.species,PBSpecies,:KOMALA))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    blacklist=[
       0x02,    # Combate
       0x14,    # Cháchara
       0x5C,    # Mimético
       0x5D,    # Esquema
       0xAE,    # Mov. Espejo
       0xAF,    # Copión
       0xB0,    # Yo Primero
       0xB3,    # Adaptación
       0xB4,    # Sonámbulo
       0xB5,    # Ayuda
       0xB6,    # Metrónomo
       0xD1,    # Alboroto
       0xD4,    # Venganza
       0x115,   # Puño Certero
# Ataques de dos turnos
       0xC3,    # V. Cortante
       0xC4,    # Rayo Solar
       0xC5,    # Rayo Gélido
       0xC6,    # Llama Gélida
       0xC7,    # Ataque Aéreo
       0xC8,    # Cabezazo
       0xC9,    # Vuelo
       0xCA,    # Excavar
       0xCB,    # Bucreo
       0xCC,    # Bote
       0xCD,    # Golpe Umbrío
       0xCE,    # Caída Libre
       0x14D,   # Golpe Fantasma
       0x14E,   # Geocontrol
    ]
    choices=[]
    for i in 0...4
      found=false
      next if attacker.moves[i].id==0
      found=true if blacklist.include?(attacker.moves[i].function)
      next if found
      choices.push(i) if @battle.pbCanChooseMove?(attacker.index,i,false,true)
    end
    if choices.length==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    choice=choices[@battle.pbRandom(choices.length)]
    attacker.pbUseMoveSimple(attacker.moves[choice].id,choice,attacker.pbOppositeOpposing.index)
    return 0
  end
end



################################################################################
# Uses a random move known by any non-user Pokémon in the user's party.
# (Ayuda/Assist)
################################################################################
class PokeBattle_Move_0B5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,    # Combate
       0x14,    # Cháchara
       0x5C,    # Mimético
       0x5D,    # Esquema
       0x69,    # Transform.
       0x71,    # Contraataque
       0x72,    # Manto Espejo
       0x73,    # Repr. Metal
       0x9C,    # Refuerzo
       0xAA,    # Detección, Protección
       0xAD,    # Amago
       0xAE,    # Mov. Espejo
       0xAF,    # Copión
       0xB0,    # Yo Primero
       0xB2,    # Robo
       0xB3,    # Adaptación
       0xB4,    # Sonámbulo
       0xB5,    # Ayuda
       0xB6,    # Metrónomo
       0xCD,    # Golpe Umbrío
       0xE7,    # Mismodestino
       0xE8,    # Aguante
       0xEB,    # Rugido, Remolino
       0xEC,    # Llave Giro, Cola Dragón
       0xF1,    # Antojo, Ladrón
       0xF2,    # Trapicheo, Truco
       0xF3,    # Ofrenda
       0x115,   # Puño Certero
       0x117,   # Señuelo, Polvo Ira
       0x149,   # Escudo Tatami
       0x14B,   # Escudo Real
       0x14C,   # Barrera Espinosa
       0x14D,   # Golpe Fantasma
       0x158,   # Eructo
       0x15B,   # Búnker
       0x184,   # Obstrucción
       0x257    # Telatrampa
    ]
    if USENEWBATTLEMECHANICS
      blacklist+=[
         # Ataques de dos turnos
         0xC3,    # V. Cortante
         0xC4,    # Rayo Solar, Cuchilla Solar
         0xC5,    # Rayo Gélido
         0xC6,    # Llama Gélida
         0xC7,    # Ataque Aéreo
         0xC8,    # Cabezazo
         0xC9,    # Vuelo
         0xCA,    # Excavar
         0xCB,    # Buceo
         0xCC,    # Bote
         0xCD,    # Golpe Umbrío
         0xCE,    # Caída Libre
         0x14D,   # Golpe Fantasma
         0x14E,   # Geocontrol
         0x190    # Rayo Meteórico
      ]
    end
    moves=[]
    party=@battle.pbParty(attacker.index) # NOTE: pbParty is common to both allies in multi battles
    for i in 0...party.length
      if i!=attacker.pokemonIndex && party[i] && !(USENEWBATTLEMECHANICS && party[i].isEgg?)
        for j in party[i].moves
          next if isConst?(j.type,PBTypes,:SHADOW)
          next if j.id==0
          found=false
          moves.push(j.id) if !blacklist.include?(PBMoveData.new(j.id).function)
        end
      end
    end
    if moves.length==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    move=moves[@battle.pbRandom(moves.length)]
    attacker.pbUseMoveSimple(move)
    return 0
  end
end



################################################################################
# Utiliza un movimiento al azar entre todos los existentes.
# (Metrónomo/Metronome)
################################################################################
class PokeBattle_Move_0B6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,    # Combate
       0x11,    # Ronquido
       0x14,    # Cháchara
       0x5C,    # Mimético
       0x5D,    # Esquema
       0x69,    # Transformación
       0x71,    # Contraataque
       0x72,    # Manto Espejo
       0x73,    # Represión Metal
       0x9C,    # Refuerzo
       0xAA,    # Detección, Protección
       0xAB,    # Anticipo
       0xAC,    # Vastaguardia
       0xAD,    # Amago
       0xAE,    # Mov. Espejo
       0xAF,    # Copión
       0xB0,    # Yo Primero
       0xB2,    # Robo
       0xB3,    # Nature Power
       0xB4,    # Sonámbulo
       0xB5,    # Ayuda
       0xB6,    # Metrónomo
       0xE7,    # Mismo Destino
       0xE8,    # Aguante
       0xF1,    # Antojo, Ladrón
       0xF2,    # Trapicheo, Truco
       0xF3,    # Ofrenda
       0x115,   # Puño Certero
       0x117,   # Señuelo, Polvo Ira
       0x11D,   # Cede Paso
       0x11E,   # Último Lugar
       0x149,   # Escudo Tatami
       0x14B,   # Escudo Real
       0x14C,   # Barrera Espinosa
       0x15B,   # Búnker
       0x184,   # Obstrucción
       0x257    # Telatrampa
    ]
    blacklistmoves=[
       :FREEZESHOCK,
       :ICEBURN,
       :RELICSONG,
       :SECRETSWORD,
       :SNARL,
       :TECHNOBLAST,
       :VCREATE,
       :GEOMANCY
    ]
    i=0; loop do break unless i<1000
      move=@battle.pbRandom(PBMoves.maxValue)+1
      next if isConst?(PBMoveData.new(move).type,PBTypes,:SHADOW)
      found=false
      if blacklist.include?(PBMoveData.new(move).function)
        found=true
      else
        for j in blacklistmoves
          if isConst?(move,PBMoves,j)
            found=true
            break
          end
        end
      end
      if !found
        pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
        attacker.pbUseMoveSimple(move)
        return 0
      end
      i+=1
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end



################################################################################
# El objetivo no podrá volver a usar el mismo movimiento dos veces seguidas.
# (Tormento/Torment)
################################################################################
class PokeBattle_Move_0B7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Torment]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
        return -1
      elsif opponent.pbPartner.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbPartner.pbThis,PBAbilities.getName(opponent.pbPartner.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Torment]=true
    @battle.pbDisplay(_INTL("¡{1} es víctima de Tormento!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Desactiva todos los movimientos del objetivo que el usuario también conozca.
# (Cerca/Imprison)
################################################################################
class PokeBattle_Move_0B8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Imprison]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Imprison]=true
    @battle.pbDisplay(_INTL("¡{1} selló movimientos del oponente!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Durante 5 rondas, desactiva el último movimiento usado por el objetivo.
# (Anulación/Disable)
################################################################################
class PokeBattle_Move_0B9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Disable]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
        return -1
      elsif opponent.pbPartner.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbPartner.pbThis,PBAbilities.getName(opponent.pbPartner.ability)))
        return -1
      end
    end
    for i in opponent.moves
      if i.id>0 && i.id==opponent.lastMoveUsed && (i.pp>0 || i.totalpp==0)
        pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
        opponent.effects[PBEffects::Disable]=5
        opponent.effects[PBEffects::DisableMove]=opponent.lastMoveUsed
        @battle.pbDisplay(_INTL("¡{2} de {1} fue desactivado!",opponent.pbThis,i.name))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end



################################################################################
# Durante 4 rondas, desactiva los movimientos que no hacen daño del objetivo.
# (Mofa/Taunt)
################################################################################
class PokeBattle_Move_0BA < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Taunt]>0 ||
       (USENEWBATTLEMECHANICS &&
       !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:OBLIVIOUS))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
        return -1
      elsif opponent.pbPartner.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbPartner.pbThis,PBAbilities.getName(opponent.pbPartner.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Taunt]=4
    @battle.pbDisplay(_INTL("¡{1} se dejó engañar por Mofa!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Durante 5 rondas, desactiva los movimientos de salud del objetivo.
# (Anticura/Heal Block)
################################################################################
class PokeBattle_Move_0BB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::HealBlock]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
        return -1
      elsif opponent.pbPartner.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbPartner.pbThis,PBAbilities.getName(opponent.pbPartner.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::HealBlock]=5
    @battle.pbDisplay(_INTL("¡{1} no puede curarse!",opponent.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent) #9 gen
    return if opponent.damagestate.substitute
    if opponent.effects[PBEffects::HealBlock]<1
      opponent.effects[PBEffects::HealBlock]=5
      @battle.pbDisplay(_INTL("¡{1} no puede curarse!",opponent.pbThis))
    end
  end

end



################################################################################
# Durante 4 rondas, el objetivo debe utilizar el mismo movimiento en cada ronda.
# (Otra Vez/Encore)
################################################################################
class PokeBattle_Move_0BC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    blacklist=[
       0x02,    # Struggle
       0x5C,    # Mimic
       0x5D,    # Sketch
       0x69,    # Transform
       0xAE,    # Mirror Move
       0xBC     # Encore
    ]
    if opponent.effects[PBEffects::Encore]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.lastMoveUsed<=0 ||
       blacklist.include?(PBMoveData.new(opponent.lastMoveUsed).function)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbThis,PBAbilities.getName(opponent.ability)))
        return -1
      elsif opponent.pbPartner.hasWorkingAbility(:AROMAVEIL)
        @battle.pbDisplay(_INTL("¡Pero falló debido a {2} de {1}!",
           opponent.pbPartner.pbThis,PBAbilities.getName(opponent.pbPartner.ability)))
        return -1
      end
    end
    for i in 0...4
      if opponent.lastMoveUsed==opponent.moves[i].id &&
         (opponent.moves[i].pp>0 || opponent.moves[i].totalpp==0)
        pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
        opponent.effects[PBEffects::Encore]=4
        opponent.effects[PBEffects::EncoreIndex]=i
        opponent.effects[PBEffects::EncoreMove]=opponent.moves[i].id
        @battle.pbDisplay(_INTL("¡{1} es víctima de Otra Vez!",opponent.pbThis))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end



################################################################################
# Golpea dos veces.
################################################################################
class PokeBattle_Move_0BD < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 2
  end
end



################################################################################
# Golpea dos veces. Puede envenenar al objetivo con cada golpe.
# (Dobleataque/Twineedle)
################################################################################
class PokeBattle_Move_0BE < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 2
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker)
    end
  end
end



################################################################################
# Golpea  3 veces. La potencia se multiplica por el número de golpes.
# (Triplepatada/Triple Kick)
# Se revisa la precisión para cada golpe.
################################################################################
class PokeBattle_Move_0BF < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 3
  end

  def successCheckPerHit?
    return @checks
  end

  def pbOnStartUse(attacker)
    @calcbasedmg=@basedamage
    # Issue #14: Dado trucado no está programado - albertomcastro4
    @checks=!(attacker.hasWorkingAbility(:SKILLLINK) || attacker.hasWorkingItem(:LOADEDDICE))
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    ret=@calcbasedmg
    @calcbasedmg+=basedmg
    return ret
  end
end



################################################################################
# Golpea de 2 a 5 veces.
################################################################################
class PokeBattle_Move_0C0 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    hitchances=[2,2,3,3,4,5]
    # Issue #14: Dado trucado no está programado - albertomcastro4
    hitchances = [4,5] if attacker.hasWorkingItem(:LOADEDDICE)
    ret=hitchances[@battle.pbRandom(hitchances.length)]
    ret=5 if attacker.hasWorkingAbility(:SKILLLINK)
    return ret
  end
end



################################################################################
# Golpea X veces, donde X es 1 (el usuario) mas el número de Pokémon en el equipo
# del usuario que no estén debilitados (los participantes). Falla si X es 0.
# El poder base de cada golpe depende del Ataque base de cada una de las especies
# participantes en los golpes.
# (Paliza/Beat Up)
################################################################################
class PokeBattle_Move_0C1 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return @participants.length
  end

  def pbOnStartUse(attacker)
    party=@battle.pbParty(attacker.index)
    @participants=[]
    for i in 0...party.length
      if attacker.pokemonIndex==i
        @participants.push(i)
      elsif party[i] && !party[i].isEgg? && party[i].hp>0 && party[i].status==0
        @participants.push(i)
      end
    end
    if @participants.length==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return false
    end
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    party=@battle.pbParty(attacker.index)
    atk=party[@participants[0]].baseStats[1]
    @participants[0]=nil; @participants.compact!
    return 5+(atk/10)
  end
end



################################################################################
# Ataque de dos turnos. Ataca el primer turno, se salta el segundo (si fue exitoso).
################################################################################
class PokeBattle_Move_0C2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      attacker.effects[PBEffects::HyperBeam]=2
      attacker.currentMove=@id
    end
    return ret
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (V. Cortante/Razor Wind)
################################################################################
class PokeBattle_Move_0C3 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} es azotado por un torbellino!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)                                  # Hierba Única
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Rayo Solar/SolarBeam)
# El poder se reduce a la mitad en cualquier clima salvo día soleado.
# En día soleado, este movimiento toma 1 solo turno.
################################################################################
class PokeBattle_Move_0C4 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false; @sunny=false
    if attacker.effects[PBEffects::TwoTurnAttack]==0
      if (@battle.pbWeather==PBWeather::SUNNYDAY ||
         @battle.pbWeather==PBWeather::HARSHSUN) && !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        @immediate=true; @sunny=true
      end
    end
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if @battle.pbWeather!=0 &&
       @battle.pbWeather!=PBWeather::SUNNYDAY &&
       @battle.pbWeather!=PBWeather::HARSHSUN
      return (damagemult*0.5).round
    end
    return damagemult
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} absorbió luz solar!",attacker.pbThis))
    end
    if @immediate && !@sunny
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end




################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Rayo Gélido/Freeze Shock)
# Puede paralizar al objetivo.
################################################################################
class PokeBattle_Move_0C5 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} se rodeó de una luz gélida!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanParalyze?(attacker,false,self)
      opponent.pbParalyze(attacker)
    end
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Llama Gélida/Ice Burn)
# Puede quemar al objetivo.
################################################################################
class PokeBattle_Move_0C6 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} se rodeó de un aire helado!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanBurn?(attacker,false,self)
      opponent.pbBurn(attacker)
    end
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Ataque Aéreo/Sky Attack)
# Puede hacer retroceder al objetivo.
################################################################################
class PokeBattle_Move_0C7 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} está brillando!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end
end



################################################################################
# Ataque de dos turnos. Sube la Defensa del usuario en 1 nivel el primer turno,
# ataca en el segundo.
# (Cabezazo/Skull Bash)
################################################################################
class PokeBattle_Move_0C8 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} bajó su cabeza!",attacker.pbThis))
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self)
      end
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Vuelo/Fly)
# (Controlado en pbSuccessCheck de Battler): Es semi-invulnerable durante el uso.
################################################################################
class PokeBattle_Move_0C9 < PokeBattle_Move
  def unusableInGravity?
    return true
  end

  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.scene.pbVanishSprite(attacker) # BES- T Sprite Vuelo
      @battle.pbDisplay(_INTL("¡{1} voló muy alto!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    @battle.scene.pbUnVanishSprite(attacker) # BES- T Sprite Vuelo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Excavar/Dig)
# (Controlado en pbSuccessCheck de Battler): Es semi-invulnerable durante el uso.
################################################################################
class PokeBattle_Move_0CA < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.scene.pbVanishSprite(attacker) # BES- T Sprite Vuelo
      @battle.pbDisplay(_INTL("¡{1} se ha ocultado bajo tierra!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    @battle.scene.pbUnVanishSprite(attacker) # BES- T Sprite Vuelo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Buceo/Dive)
# (Controlado en pbSuccessCheck de Battler): Es semi-invulnerable durante el uso.
################################################################################
class PokeBattle_Move_0CB < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.scene.pbVanishSprite(attacker) # BES- T Sprite Vuelo
      @battle.pbDisplay(_INTL("¡{1} se ha ocultado bajo el agua!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    if isConst?(attacker.species,PBSpecies,:CRAMORANT) && attacker.hasWorkingAbility(:GULPMISSILE) &&
       !attacker.isFainted? && attacker.form==0 && (@immediate || attacker.effects[PBEffects::TwoTurnAttack]>0)
       if attacker.hp > attacker.totalhp/2
         attacker.form=1
       else
         attacker.form=2
       end
      attacker.pbUpdate(false)
      @battle.scene.pbChangePokemon(attacker,attacker.pokemon)
      PBDebug.log("[Form changed] #{attacker.pbThis} changed to form #{attacker.form}")
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    @battle.scene.pbUnVanishSprite(attacker) # BES- T Sprite Vuelo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Bote/Bounce)
# Puede paralizar al objetivo.
# (Controlado en pbSuccessCheck de Battler): Es semi-invulnerable durante el uso.
################################################################################
class PokeBattle_Move_0CC < PokeBattle_Move
  def unusableInGravity?
    return true
  end

  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.scene.pbVanishSprite(attacker) # BES- T Sprite Vuelo
      @battle.pbDisplay(_INTL("¡{1} saltó muy alto!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    @battle.scene.pbUnVanishSprite(attacker) # BES- T Sprite Vuelo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanParalyze?(attacker,false,self)
      opponent.pbParalyze(attacker)
    end
  end
end



################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Golpe Umbrío/Shadow Force)
# Es invulnerable durante el uso.
# Ignora la Detección, Escudo Real, Escudo Tatami, Protección y Barrera Espinosa del
# objetivo en esta ronda. Si tiene éxito, anula esas barreras por el resto de la ronda.
################################################################################
class PokeBattle_Move_0CD < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.scene.pbVanishSprite(attacker) # BES- T Sprite Vuelo
      @battle.pbDisplay(_INTL("¡{1} ha desaparecido!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    @battle.scene.pbUnVanishSprite(attacker) # BES- T Sprite Vuelo
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if ret>0
      opponent.effects[PBEffects::ProtectNegation]=true
      opponent.pbOwnSide.effects[PBEffects::CraftyShield]=false
    end
    return ret
  end
end

################################################################################
# Movimiento de dos turnos. Desaparece del campo el primer turno.
# Ataca en el segundo turno.
# (Golpe Fantasma/Phantom Force)
# Es invulnerable durante el uso.
# Este turno, ignora movimientos del objetivo como Detección, Escudo Real,
# Escudo Tatami, Protección y Barrera Espinosa. Si tiene éxito, los anula este turno.
# Causa el doble de daño y tiene precisión perfecta si el objetivo ha usado Reducción.
################################################################################
class PokeBattle_Move_14D < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.scene.pbVanishSprite(attacker) # BES- T Sprite Vuelo
      @battle.pbDisplay(_INTL("¡{1} desaparece en un abrir y cerrar de ojos!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    @battle.scene.pbUnVanishSprite(attacker) # BES- T Sprite Vuelo
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if ret>0
      opponent.effects[PBEffects::ProtectNegation]=true
      opponent.pbOwnSide.effects[PBEffects::CraftyShield]=false
    end
    return ret
  end

  def tramplesMinimize?(param=1)
    return true if param==1 && USENEWBATTLEMECHANICS # Perfect accuracy
    return true if param==2 # Double damage
    return false
  end
end

################################################################################
# Ataque de dos turnos. Se salta el primer turno, ataca el segundo.
# (Caída Libre/Sky Drop)
# (Controlado en pbSuccessCheck de Battler):  Es semi-invulnerable durante el uso.
# El objetivo también es semi-invulnerable durante el uso, y no puede tomar ninguna acción.
# No hace daño a los objetivos que están en el aire (pero tampoco los deja moverse).
################################################################################
class PokeBattle_Move_0CE < PokeBattle_Move
  def unusableInGravity?
    return true
  end

  def pbMoveFailed(attacker,opponent)
    ret=false
    ret=true if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
    ret=true if opponent.effects[PBEffects::TwoTurnAttack]>0
    ret=true if opponent.effects[PBEffects::SkyDrop] && attacker.effects[PBEffects::TwoTurnAttack]>0
    ret=true if !opponent.pbIsOpposing?(attacker.index)
    ret=true if USENEWBATTLEMECHANICS && opponent.weight(attacker)>=2000
    return ret
  end

  def pbTwoTurnAttack(attacker)
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} se ha llevado al {2} por los aires!",attacker.pbThis,opponent.pbThis(true)))
      @battle.scene.pbVanishSprite(attacker)
      opponent.effects[PBEffects::SkyDrop]=true
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    ret=super
    @battle.pbDisplay(_INTL("El {1} se ha liberado de Caída Libre!",opponent.pbThis))
    opponent.effects[PBEffects::SkyDrop]=false
    return ret
  end

  def pbTypeModifier(type,attacker,opponent)
    return 0 if opponent.pbHasType?(:FLYING)
    return 0 if !attacker.hasMoldBreaker &&
       opponent.hasWorkingAbility(:LEVITATE) && !opponent.effects[PBEffects::SmackDown]
    return super
  end
end

################################################################################
# Movimiento de trampa. Atrapa por 5 o 6 rondas.
# Los objetivos atrapados pierden 1/16 de sus PS máximos al final de cada ronda.
# Trapped Pokémon lose 1/16 of max HP
################################################################################
class PokeBattle_Move_0CF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.isFainted? &&
       !opponent.damagestate.substitute
      if opponent.effects[PBEffects::MultiTurn]==0
        opponent.effects[PBEffects::MultiTurn]=5+@battle.pbRandom(2)
        if attacker.hasWorkingItem(:GRIPCLAW)
          opponent.effects[PBEffects::MultiTurn]=(USENEWBATTLEMECHANICS) ? 8 : 6
        end
        opponent.effects[PBEffects::MultiTurnAttack]=@id
        opponent.effects[PBEffects::MultiTurnUser]=attacker.index
        if isConst?(@id,PBMoves,:BIND)
          @battle.pbDisplay(_INTL("¡{1} es oprimido por Atadura de {2}!",opponent.pbThis,attacker.pbThis(true)))
        elsif isConst?(@id,PBMoves,:CLAMP)
          @battle.pbDisplay(_INTL("¡{1} atenazó a {2}!",attacker.pbThis,opponent.pbThis(true)))
        elsif isConst?(@id,PBMoves,:FIRESPIN)
          @battle.pbDisplay(_INTL("¡{1} fue atrapado en el torbellino!",opponent.pbThis))
        elsif isConst?(@id,PBMoves,:MAGMASTORM)
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en Lluvia Ígnea!",opponent.pbThis))
        elsif isConst?(@id,PBMoves,:SANDTOMB)
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en Bucle Arena!",opponent.pbThis))
        elsif isConst?(@id,PBMoves,:WRAP)
          @battle.pbDisplay(_INTL("¡{1} fue atrapado por {2}!",opponent.pbThis,attacker.pbThis(true)))
        elsif isConst?(@id,PBMoves,:INFESTATION)
          @battle.pbDisplay(_INTL("¡{1} ha sido infectado con la infestación de {2}!",opponent.pbThis,attacker.pbThis(true)))
          elsif isConst?(@id,PBMoves,:THUNDERCAGE)
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en la jaula!",opponent.pbThis))
        elsif isConst?(@id,PBMoves,:CEASELESSEDGE)
          @battle.pbDisplay(_INTL("¡A {1} se le han clavado unos fragmentos afilados!",opponent.pbThis))
        else
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en el torbellino!",opponent.pbThis))
        end
      end
    end
    return ret
  end
end



################################################################################
# Movimiento de trampa. Atrapa por 5 o 6 rondas.
# Los objetivos atrapados pierden 1/16 de sus PS máximos al final de cada ronda.
# (Torbellino/Whirlpool)
# La potencia se duplica si el objetivo está usando Buceo.
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_0D0 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.isFainted? &&
       !opponent.damagestate.substitute
      if opponent.effects[PBEffects::MultiTurn]==0
        opponent.effects[PBEffects::MultiTurn]=5+@battle.pbRandom(2)
        if attacker.hasWorkingItem(:GRIPCLAW)
          opponent.effects[PBEffects::MultiTurn]=(USENEWBATTLEMECHANICS) ? 8 : 6
        end
        opponent.effects[PBEffects::MultiTurnAttack]=@id
        opponent.effects[PBEffects::MultiTurnUser]=attacker.index
        @battle.pbDisplay(_INTL("¡{1} fue atrapado en el torbellino!",opponent.pbThis))
      end
    end
    return ret
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCB # Dive
      return (damagemult*2.0).round
    end
    return damagemult
  end
end



################################################################################
# El usuario debe utilizar este movimiento por 2 rondas más.
# Ningún combatiente del campo puede dormir. (Uproar/Alboroto)
################################################################################
class PokeBattle_Move_0D1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.effects[PBEffects::Uproar]==0
        attacker.effects[PBEffects::Uproar]=3
        @battle.pbDisplay(_INTL("¡{1} montó un Alboroto!",attacker.pbThis))
        attacker.currentMove=@id
      end
    end
    return ret
  end
end



################################################################################
# El usuario usará este movimiento por 1 o 2 rondas más. Al final, el usuario
# termina confuso.
# (Enfado, , Golpe / Outrage, Petal Dange, Thrash)
################################################################################
class PokeBattle_Move_0D2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 &&
       attacker.effects[PBEffects::Outrage]==0 &&
       attacker.status!=PBStatuses::SLEEP
      attacker.effects[PBEffects::Outrage]=2+@battle.pbRandom(2)
      attacker.currentMove=@id
    elsif pbTypeModifier(@type,attacker,opponent)==0
      # Cancel effect if attack is ineffective
      attacker.effects[PBEffects::Outrage]=0
    end
    if attacker.effects[PBEffects::Outrage]>0
      attacker.effects[PBEffects::Outrage]-=1
      if attacker.effects[PBEffects::Outrage]==0 && attacker.pbCanConfuseSelf?(false)
        attacker.pbConfuse
        @battle.pbDisplay(_INTL("¡{1} quedó confuso por la fatiga!",attacker.pbThis))
      end
    end
    return ret
  end
end



################################################################################
# El usuario usará este movimiento 4 rondas más. La potencia se duplica en cada ronda.
# La potencia también se duplica si el usuario a usado Rizo Defensa.
# (Bola Hielo, Desenrollar / Ice Ball, Rollout)
################################################################################
class PokeBattle_Move_0D3 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    shift=(4-attacker.effects[PBEffects::Rollout]) # from 0 through 4, 0 is most powerful
    shift+=1 if attacker.effects[PBEffects::DefenseCurl]
    basedmg=basedmg<<shift
    return basedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[PBEffects::Rollout]=5 if attacker.effects[PBEffects::Rollout]==0
    attacker.effects[PBEffects::Rollout]-=1
    attacker.currentMove=thismove.id
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage==0 ||
       pbTypeModifier(@type,attacker,opponent)==0 ||
       attacker.status==PBStatuses::SLEEP
      # Cancel effect if attack is ineffective
      attacker.effects[PBEffects::Rollout]=0
    end
    return ret
  end
end



################################################################################
# El usuario resiste ésta y la siguiente ronda. Luego, causa el doble del daño
# total recibido mientras resistía al último combatiente que lo dañó.
# (Venganza/Bide)
################################################################################
class PokeBattle_Move_0D4 < PokeBattle_Move
  def pbDisplayUseMessage(attacker)
    if attacker.effects[PBEffects::Bide]==0
      @battle.pbDisplayBrief(_INTL("¡{1} ha usado<br>{2}!",attacker.pbThis,name))
      attacker.effects[PBEffects::Bide]=2
      attacker.effects[PBEffects::BideDamage]=0
      attacker.effects[PBEffects::BideTarget]=-1
      attacker.currentMove=@id
      pbShowAnimation(@id,attacker,nil)
      return 1
    else
      attacker.effects[PBEffects::Bide]-=1
      if attacker.effects[PBEffects::Bide]==0
        @battle.pbDisplayBrief(_INTL("¡{1} liberó energía!",attacker.pbThis))
        return 0
      else
        @battle.pbDisplayBrief(_INTL("¡{1} está juntando energía!",attacker.pbThis))
        return 2
      end
    end
  end

  def pbAddTarget(targets,attacker)
    if attacker.effects[PBEffects::BideTarget]>=0
      if !attacker.pbAddTarget(targets,@battle.battlers[attacker.effects[PBEffects::BideTarget]])
        attacker.pbRandomTarget(targets)
      end
    else
      attacker.pbRandomTarget(targets)
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::BideDamage]==0 || !opponent
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if USENEWBATTLEMECHANICS
      typemod=pbTypeModifier(pbType(@type,attacker,opponent),attacker,opponent)
      if typemod==0
        @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
        return -1
      end
    end
    ret=pbEffectFixedDamage(attacker.effects[PBEffects::BideDamage]*2,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end



################################################################################
# Cura al usuario por 1/2 de sus PS máximos.
################################################################################
class PokeBattle_Move_0D5 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(((attacker.totalhp+1)/2).floor,true)
    @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
    return 0
  end
end



################################################################################
# Cura al usuario por 1/2 de sus PS máximos.
# (Respiro/Roost)
# El usuario descansa, por lo que su tipo Volador es ignorado en los ataques
# dirigidos a él.
################################################################################
class PokeBattle_Move_0D6 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(((attacker.totalhp+1)/2).floor,true)
    attacker.effects[PBEffects::Roost]=true unless attacker.isTera?
    @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
    return 0
  end
end



################################################################################
# El combatiente que se encuentre en la posición del usuario por 1/2 de sus
# PS máximos al final del siguiente turno.
# (Deseo/Wish)
################################################################################
class PokeBattle_Move_0D7 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Wish]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Wish]=2
    attacker.effects[PBEffects::WishAmount]=((attacker.totalhp+1)/2).floor
    attacker.effects[PBEffects::WishMaker]=attacker.pokemonIndex
    return 0
  end
end



################################################################################
# Cura al usuario por una cantidad que depende del clima.
# (Luz Lunar, Sol Matinal, Síntesis / Moonlight, Morning Sun, Synthesis)
################################################################################
class PokeBattle_Move_0D8 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",attacker.pbThis))
      return -1
    end
    hpgain=0
    if (@battle.pbWeather==PBWeather::SUNNYDAY ||
       @battle.pbWeather==PBWeather::HARSHSUN)  && !attacker.hasWorkingItem(:UTILITYUMBRELLA)
      hpgain=(attacker.totalhp*2/3).floor
    elsif @battle.pbWeather!=0
      hpgain=(attacker.totalhp/4).floor
    else
      hpgain=(attacker.totalhp/2).floor
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
    return 0
  end
end



################################################################################
# El usuario recupera sus PS máximos y queda dormido por 2 rondas más.
# (Descanso/Rest)
################################################################################
class PokeBattle_Move_0D9 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanSleep?(attacker,true,self,true)
      return -1
    end
    if attacker.status==PBStatuses::SLEEP
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbSleepSelf(3)
    @battle.pbDisplay(_INTL("¡{1} se fue a dormir y recuperó salud!",attacker.pbThis))
    hp=attacker.pbRecoverHP(attacker.totalhp-attacker.hp,true)
    @battle.pbDisplay(_INTL("¡{1} recuperó salud!",attacker.pbThis)) if hp>0
    return 0
  end
end



################################################################################
# Rodea al usuario. El usuario rodeado recupera 1/16 de sus PS máximos al
# final de cada ronda.
# (Acua Aro/Aqua Ring)
################################################################################
class PokeBattle_Move_0DA < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::AquaRing]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::AquaRing]=true
    @battle.pbDisplay(_INTL("¡{1} se rodeó de un manto de agua!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Arraiga al usuario. El usuario arraigado recupera 1/16 de sus PS máximos al
# final de cada ronda, y no puede huir o ser cambiado.
# (Arraigo/Ingrain)
################################################################################
class PokeBattle_Move_0DB < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Ingrain]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Ingrain]=true
    @battle.pbDisplay(_INTL("¡{1} echó raíces!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Lanza semillas al objetivo. El objetivo pierde 1/8 de sus PS máximos al final
# de cada ronda, y el combatiente que se encuentre en la posición del usuario
# ganará la misma cantidad.
# (Drenadoras/Leech Seed)
################################################################################
class PokeBattle_Move_0DC < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    if opponent.effects[PBEffects::LeechSeed]>=0
      @battle.pbDisplay(_INTL("¡{1} esquivó el ataque!",opponent.pbThis))
      return -1
    end
    if opponent.pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::LeechSeed]=attacker.index
    @battle.pbDisplay(_INTL("¡{1} fue infectado!",opponent.pbThis))
    return 0
  end
end



################################################################################
# El usuario recupera la mitad de los PS que inflinge como daño.
################################################################################
class PokeBattle_Move_0DD < PokeBattle_Move
  def isHealingMove?
    return USENEWBATTLEMECHANICS
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=(opponent.damagestate.hplost/2).round
      if opponent.hasWorkingAbility(:LIQUIDOOZE)
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} absorbió el Lodo Líquido!",attacker.pbThis))
      elsif attacker.effects[PBEffects::HealBlock]==0
        hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} ha perdido energía!",opponent.pbThis))
      end
    end
    return ret
  end
end



################################################################################
# El usuario recupera la mitad de los PS que inflinge como daño.
# (Come Sueños/Dream Eater)
# (Controlado en pbSuccessCheck de Battler): Falla si el objetivo no está dormido.
################################################################################
class PokeBattle_Move_0DE < PokeBattle_Move
  def isHealingMove?
    return USENEWBATTLEMECHANICS
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=(opponent.damagestate.hplost/2).round
      if opponent.hasWorkingAbility(:LIQUIDOOZE)
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} absorbió el Lodo Líquido!",attacker.pbThis))
      elsif attacker.effects[PBEffects::HealBlock]==0
        hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} ha perdido energía!",opponent.pbThis))
      end
    end
    return ret
  end
end



################################################################################
# El objetivo recupera 1/2 de sus PS máximos.
# (Pulso Cura/Heal Pulse)
################################################################################
class PokeBattle_Move_0DF < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.hp==opponent.totalhp
      @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",opponent.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    hpgain=((opponent.totalhp+1)/2).floor
    hpgain=(opponent.totalhp*3/4).round if attacker.hasWorkingAbility(:MEGALAUNCHER)
    opponent.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("¡{1} recuperó su salud!",opponent.pbThis))
    return 0
  end
end



################################################################################
# El usuario se debilita.
# (Explosión, Autodestru. / Explosion, Selfdestruct)
################################################################################
class PokeBattle_Move_0E0 < PokeBattle_Move
  def pbOnStartUse(attacker)
    if !attacker.hasMoldBreaker
      bearer=@battle.pbCheckGlobalAbility(:DAMP)
      if bearer!=nil
        @battle.pbDisplay(_INTL("¡{2} de {1} evitó que {3} utilice {4}!",
           bearer.pbThis,PBAbilities.getName(bearer.ability),attacker.pbThis(true),@name))
        return false
      end
    end
    return true
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    super(id,attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted?
      attacker.pbReduceHP(attacker.hp)
      attacker.pbFaint if attacker.isFainted?
    end
  end
end



################################################################################
# Inflinge un daño fijo igual a los PS actuales.
# El uusuario se debilita (si tiene éxito).
# (Sacrificio/Final Gambit)
################################################################################
class PokeBattle_Move_0E1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    typemod=pbTypeModifier(pbType(@type,attacker,opponent),attacker,opponent)
    if typemod==0
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
      return -1
    end
    ret=pbEffectFixedDamage(attacker.hp,attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    super(id,attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted?
      attacker.pbReduceHP(attacker.hp)
      attacker.pbFaint if attacker.isFainted?
    end
  end
end



################################################################################
# Reduce el Ataque y Ataque Especial del objetivo en 2 niveles cada uno.
# El usuario se debilita incluso si el efecto no hace nada.
# Legado / Memento
################################################################################
class PokeBattle_Move_0E2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true
    if opponent.pbReduceStat(PBStats::ATTACK,2,attacker,false,self,showanim)
      ret=0; showanim=false
    end
    if opponent.pbReduceStat(PBStats::SPATK,2,attacker,false,self,showanim)
      ret=0; showanim=false
    end
    attacker.pbReduceHP(attacker.hp)
    return ret
  end
end



################################################################################
# El usuario se debilita. El combatiente que remplace al usuario se recuperará
# completamente (PS y estado). Falla si el usuario no puede ser remplazado.
# Deseo Cura / Healing Wish
################################################################################
class PokeBattle_Move_0E3 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbReduceHP(attacker.hp)
    attacker.effects[PBEffects::HealingWish]=true
    return 0
  end
end



################################################################################
# El usuario se debilita. El combatiente que remplace al usuario se recuperará
# completamente (PS, PP y estado). Falla si el usuario no puede ser remplazado.
# Danza Lunar / Lunar Dance
################################################################################
class PokeBattle_Move_0E4 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbReduceHP(attacker.hp)
    attacker.effects[PBEffects::LunarDance]=true
    return 0
  end
end



################################################################################
# Todos los combatientes actuales se debilitarán después de 3 rondas más.
# Canto Mortal / Perish Song
################################################################################
class PokeBattle_Move_0E5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    failed=true
    for i in 0...4
      if @battle.battlers[i].effects[PBEffects::PerishSong]==0 &&
         (attacker.hasMoldBreaker ||
         !@battle.battlers[i].hasWorkingAbility(:SOUNDPROOF))
        failed=false; break
      end
    end
    if failed
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡Todos los Pokémon que oyeron la canción se debilitarán dentro de tres turnos!"))
    for i in 0...4
      if @battle.battlers[i].effects[PBEffects::PerishSong]==0
        if !attacker.hasMoldBreaker && @battle.battlers[i].hasWorkingAbility(:SOUNDPROOF)
          @battle.pbDisplay(_INTL("¡{2} de {1} bloquea {3}!",@battle.battlers[i].pbThis,
             PBAbilities.getName(@battle.battlers[i].ability),@name))
        else
          @battle.battlers[i].effects[PBEffects::PerishSong]=4
          @battle.battlers[i].effects[PBEffects::PerishSongUser]=attacker.index
        end
      end
    end
    return 0
  end
end



################################################################################
# Si el usuario es debilitado antes de su siguiente movimiento, el ataque que lo
# haga perderá todos sus PP.
# Rabia / Grudge
################################################################################
class PokeBattle_Move_0E6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Grudge]=true
    @battle.pbDisplay(_INTL("¡{1} quiere provocar Rabia a su rival!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Si el usuario es debilitado antes de su siguiente movimiento, el atacante que
# lo haga también se debilitará.
# Mismodestino / Destiny Bond
################################################################################
class PokeBattle_Move_0E7 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::DestinyBond]=true
    @battle.pbDisplay(_INTL("¡{1} intenta llevarse al rival!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Si el usuario fuese a debilitarse esta ronda, sobrevivirá con 1 PS.
# Aguante / Endure
################################################################################
class PokeBattle_Move_0E8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 && # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Endure]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se ha fortalecido!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Si el objetivo fuera a debilitarse por este ataque, sobrevivirá con 1 PS.
# Falsotortazo / False Swipe
################################################################################
class PokeBattle_Move_0E9 < PokeBattle_Move
# Handled in superclass def pbReduceHPDamage, ¡no editar!
end



################################################################################
# Cambia de Pokémon en el combate. Prioridad negativa.
# Teleport / Teletransporte (nuevo)
################################################################################
class PokeBattle_Move_300 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
   if @battle.opponent
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Uturn]=true
    return 0
   end
     pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡{1} huyó del combate!",attacker.pbThis))
    @battle.decision=3
    return 0
  end
end

################################################################################
# Cambia de Pokémon en el combate. Prioridad negativa.
# Teleport / Teletransporte (nuevo)
################################################################################
class PokeBattle_Move_300 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Uturn]=true
    return 0
  end
end

################################################################################
# En batallas con salvajes, hace huir al objetivo. Falla si el nivel del objetivo
# es mayor que el del usuario.
# En batallas con entrenadores, el objetivo es intercambiado.
# Para movimientos de estado.
# (Rugido, Remolino / Roar, Whirlwind)
################################################################################
class PokeBattle_Move_0EB < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:SUCTIONCUPS)
      @battle.pbDisplay(_INTL("¡{1} se aferra al suelo con {2}!",opponent.pbThis,PBAbilities.getName(opponent.ability)))
      return -1
    end
    if !attacker.hasMoldBreaker && opponent.effects[PBEffects::Commander] > 0 || opponent.pbPartner != nil && opponent.pbPartner.effects[PBEffects::Commander] > 0
      @battle.pbDisplay(_INTL("¡{1} no puede ser cambiado, debido a {2}!",opponent.pbThis,PBAbilities.getName(opponent.ability)))
      return -1
    end
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:GUARDDOG)
      @battle.pbDisplay(_INTL("¡{1} no puede ser cambiado, debido a {2}!",opponent.pbThis,PBAbilities.getName(opponent.ability)))
      return -1
    end
    if opponent.effects[PBEffects::Ingrain]
      @battle.pbDisplay(_INTL("¡{1} se aferra al suelo con sus raíces!",opponent.pbThis))
      return -1
    end
    if !@battle.opponent
      if opponent.level>attacker.level
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.decision=3 # Set decision to escaped
      return 0
    else
      choices=false
      party=@battle.pbParty(opponent.index)
      for i in 0...party.length
        if @battle.pbCanSwitch?(opponent.index,i,false,true)
          choices=true
          break
        end
      end
      if !choices
        @battle.pbDisplay(_INTL("¡Pero falló!"))
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      opponent.effects[PBEffects::Roar]=true
      return 0
    end
  end
end

################################################################################
# En batallas con salvajes, hace que el objetivo huya. Falla si el objetivo es
# de mayor nivel que el usuario.
# En batallas con entrenadores, el objetivo es cambiado.
# Para movimientos de daño.
# Llave Giro, Cola Dragón / Circle Throw, Dragon Tail
################################################################################
class PokeBattle_Move_0EC < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && !opponent.isFainted? &&
       opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       (attacker.hasMoldBreaker || (!opponent.hasWorkingAbility(:SUCTIONCUPS) ||
        !opponent.hasWorkingAbility(:GUARDDOG) ||
         opponent.effects[PBEffects::Commander] > 0 || opponent.pbPartner != nil && opponent.pbPartner.effects[PBEffects::Commander] > 0)) &&
       !opponent.effects[PBEffects::Ingrain]
      if !@battle.opponent
        if opponent.level<=attacker.level
          @battle.decision=3 # Set decision to escaped
        end
      else
        party=@battle.pbParty(opponent.index)
        for i in 0..party.length-1
          if @battle.pbCanSwitch?(opponent.index,i,false)
            opponent.effects[PBEffects::Roar]=true
            break
          end
        end
      end
    end
  end
end



################################################################################
# El usuario es cambiado. Varios efectos que lleva el usuario son pasados al
# remplazo.
# Relevo / Baton Pass
################################################################################
class PokeBattle_Move_0ED < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.pbCanChooseNonActive?(attacker.index)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::BatonPass]=true
    return 0
  end
end



################################################################################
# Después de causar daño, el usuario es cambiado. Se ignoran los movimientos de trampas.
# Ida y Vuelta, Voltiocambio / U-turn, Volt Switch
# TODO: Persecución debería interrumpir este movimiento.
################################################################################
class PokeBattle_Move_0EE < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && opponent.damagestate.calcdamage>0 &&
       @battle.pbCanChooseNonActive?(attacker.index) &&
       !@battle.pbAllFainted?(@battle.pbParty(opponent.index))
      attacker.effects[PBEffects::Uturn]=true
    end
    return ret
  end
end



################################################################################
# El objetivo no podrá huir ni ser cambiado, mientras que el usuario se mantenga activo.
# Bloqueo, Mal de Ojo, Telaraña, Mil Temblores / Block, Mean Look, Spider Web, Thousand Waves
################################################################################
class PokeBattle_Move_0EF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbIsDamaging?
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
         !opponent.isFainted?
        if opponent.effects[PBEffects::MeanLook]<0 &&
           (!USENEWBATTLEMECHANICS || !opponent.pbHasType?(:GHOST))
          opponent.effects[PBEffects::MeanLook]=attacker.index
          @battle.pbDisplay(_INTL("¡{1} no pudo escapar!",opponent.pbThis))
        end
      end
      return ret
    end
    if opponent.effects[PBEffects::MeanLook]>=0 ||
       (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if USENEWBATTLEMECHANICS && opponent.pbHasType?(:GHOST)
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::MeanLook]=attacker.index
    @battle.pbDisplay(_INTL("¡{1} no pudo escapar!",opponent.pbThis))
    return 0
  end
end



################################################################################
# El objetivo tira su objeto. Lo recuperará al final del combate.
# Si el objetivo tiene un objeto que pueda parder, el daño es multiplicado x1,5.
# Desarme / Knock Off
################################################################################
class PokeBattle_Move_0F0 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && !opponent.isFainted? && opponent.item!=0 &&
       opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
      if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:STICKYHOLD)
        abilityname=PBAbilities.getName(opponent.ability)
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",opponent.pbThis,abilityname,@name))
      elsif !@battle.pbIsUnlosableItem(opponent,opponent.item)
        itemname=PBItems.getName(opponent.item)
        opponent.item=0
        opponent.effects[PBEffects::ChoiceBand]=-1
        opponent.effects[PBEffects::Unburden]=true
        @battle.pbDisplay(_INTL("¡{2} de {1} cayó al suelo!",opponent.pbThis,itemname))
      end
    end
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    if USENEWBATTLEMECHANICS &&
       !@battle.pbIsUnlosableItem(opponent,opponent.item)
       # El daño se incrementa incluso cuando el oponente tiene Viscosidad
      return (damagemult*1.5).round
    end
    return damagemult
  end
end



################################################################################
# El usuario roba el objeto al objetivo en caso que el usuario no tenga ninguno.
# El usuario se queda con los objetos robados en batallas con salvajes después
# de la batalla.
# Antojo, Ladrón / Covet, Thief
################################################################################
class PokeBattle_Move_0F1 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && !opponent.isFainted? && opponent.item!=0 &&
       opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
      if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:STICKYHOLD)
        abilityname=PBAbilities.getName(opponent.ability)
        @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",opponent.pbThis,abilityname,@name))
      elsif !@battle.pbIsUnlosableItem(opponent,opponent.item) &&
            !@battle.pbIsUnlosableItem(attacker,opponent.item) &&
            attacker.item==0 &&
            (@battle.opponent || !@battle.pbIsOpposing?(attacker.index))
        itemname=PBItems.getName(opponent.item)
        attacker.item=opponent.item
        opponent.item=0
        opponent.effects[PBEffects::ChoiceBand]=-1
        opponent.effects[PBEffects::Unburden]=true
        if !@battle.opponent && # In a wild battle
           attacker.pokemon.itemInitial==0 &&
           opponent.pokemon.itemInitial==attacker.item
          attacker.pokemon.itemInitial=attacker.item
          opponent.pokemon.itemInitial=0
        end
        @battle.pbDisplay(_INTL("¡{1} robó {3} de {2}!",attacker.pbThis,opponent.pbThis(true),itemname))
      end
    end
  end
end



################################################################################
# El usuario y el objetivo intercambian los objetos. Se conserva el objeto
# cambiado en una batalla con salvajes.
# Trapicheo, Truco / Switcheroo, Trick
################################################################################
class PokeBattle_Move_0F2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)) ||
       (attacker.item==0 && opponent.item==0) ||
       (!@battle.opponent && @battle.pbIsOpposing?(attacker.index))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if @battle.pbIsUnlosableItem(opponent,opponent.item) ||
       @battle.pbIsUnlosableItem(attacker,opponent.item) ||
       @battle.pbIsUnlosableItem(opponent,attacker.item) ||
       @battle.pbIsUnlosableItem(attacker,attacker.item)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:STICKYHOLD)
      abilityname=PBAbilities.getName(opponent.ability)
      @battle.pbDisplay(_INTL("¡{2} de {1} hizo ineficaz {3}!",opponent.pbThis,abilityname,name))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldattitem=attacker.item
    oldoppitem=opponent.item
    oldattitemname=PBItems.getName(oldattitem)
    oldoppitemname=PBItems.getName(oldoppitem)
    tmpitem=attacker.item
    attacker.item=opponent.item
    opponent.item=tmpitem
    if !@battle.opponent && # In a wild battle
       attacker.pokemon.itemInitial==oldattitem &&
       opponent.pokemon.itemInitial==oldoppitem
      attacker.pokemon.itemInitial=oldoppitem
      opponent.pokemon.itemInitial=oldattitem
    end
    @battle.pbDisplay(_INTL("¡{1} cambió objetos con su oponente!",attacker.pbThis))
    if oldoppitem>0 && oldattitem>0
      @battle.pbDisplayPaused(_INTL("{1} ha obtenido {2}.",attacker.pbThis,oldoppitemname))
      @battle.pbDisplay(_INTL("{1} ha obtenido {2}.",opponent.pbThis,oldattitemname))
    else
      @battle.pbDisplay(_INTL("{1} ha obtenido {2}.",attacker.pbThis,oldoppitemname)) if oldoppitem>0
      @battle.pbDisplay(_INTL("{1} ha obtenido {2}.",opponent.pbThis,oldattitemname)) if oldattitem>0
    end
    attacker.effects[PBEffects::ChoiceBand]=-1
    opponent.effects[PBEffects::ChoiceBand]=-1
    return 0
  end
end



################################################################################
# El usuario le entrega su objeto al objetivo. No se recupera al final de una
# batalla con salvajes.
# Ofrenda / Bestow
################################################################################
class PokeBattle_Move_0F3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)) ||
       attacker.item==0 || opponent.item!=0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if @battle.pbIsUnlosableItem(attacker,attacker.item) ||
       @battle.pbIsUnlosableItem(opponent,attacker.item)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    itemname=PBItems.getName(attacker.item)
    opponent.item=attacker.item
    attacker.item=0
    attacker.effects[PBEffects::ChoiceBand]=-1
    attacker.effects[PBEffects::Unburden]=true
    if !@battle.opponent && # In a wild battle
       opponent.pokemon.itemInitial==0 &&
       attacker.pokemon.itemInitial==opponent.item
      opponent.pokemon.itemInitial=opponent.item
      attacker.pokemon.itemInitial=0
    end
    @battle.pbDisplay(_INTL("¡{1} ha recibido {2} de {3}!",opponent.pbThis,itemname,attacker.pbThis(true)))
    return 0
  end
end



################################################################################
# El usuario consume la baya del objetivo y obtiene su efecto.
# Picadura, Picoteo / Bug Bite, Pluck
################################################################################
class PokeBattle_Move_0F4 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && !opponent.isFainted? && pbIsBerry?(opponent.item) &&
       opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
      if attacker.hasMoldBreaker || !opponent.hasWorkingAbility(:STICKYHOLD)
        item=opponent.item
        itemname=PBItems.getName(item)
        opponent.pbConsumeItem(false,false)
        @battle.pbDisplay(_INTL("¡{1} robó y se comió la {2} del oponente!",attacker.pbThis,itemname))
        if !attacker.hasWorkingAbility(:KLUTZ) &&
           attacker.effects[PBEffects::Embargo]==0
          attacker.pbActivateBerryEffect(item,false)
        end
        # Symbiosis
        if attacker.item==0 &&
           attacker.pbPartner && attacker.pbPartner.hasWorkingAbility(:SYMBIOSIS)
          partner=attacker.pbPartner
          if partner.item>0 &&
             !@battle.pbIsUnlosableItem(partner,partner.item) &&
             !@battle.pbIsUnlosableItem(attacker,partner.item)
            @battle.pbDisplay(_INTL("¡{2} de {1} le dejó compartir su {3} con {4}!",
               partner.pbThis,PBAbilities.getName(partner.ability),
               PBItems.getName(partner.item),attacker.pbThis(true)))
            attacker.item=partner.item
            partner.item=0
            partner.effects[PBEffects::Unburden]=true
            attacker.pbBerryCureCheck
          end
        end
      end
    end
  end
end



################################################################################
# La baya del objetivo es destruida.
# Calcinación / Incinerate
################################################################################
class PokeBattle_Move_0F5 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted? && opponent.damagestate.calcdamage>0 &&
       !opponent.damagestate.substitute &&
       (pbIsBerry?(opponent.item) || (USENEWBATTLEMECHANICS && pbIsGem?(opponent.item)))
      itemname=PBItems.getName(opponent.item)
      opponent.pbConsumeItem(false,false)
      @battle.pbDisplay(_INTL("¡La {2} de {1} fue quemada!",opponent.pbThis,itemname))
    end
    return ret
  end
end



################################################################################
# El usuario recupera el último objeto que llevaba y consumió.
# Reciclaje / Recycle
################################################################################
class PokeBattle_Move_0F6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pokemon || attacker.pokemon.itemRecycle==0 || attacker.pokemon.itemRecycle==nil
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    item=attacker.pokemon.itemRecycle
    itemname=PBItems.getName(item)
    attacker.item=item
    if !@battle.opponent          # En una batalla con salvaje
      attacker.pokemon.itemInitial=item if attacker.pokemon.itemInitial==0
    end
    attacker.pokemon.itemRecycle=0
    attacker.effects[PBEffects::PickupItem]=0
    attacker.effects[PBEffects::PickupUse]=0
    @battle.pbDisplay(_INTL("¡{1} encontró una {2}!",attacker.pbThis,itemname))
    return 0
  end
end



################################################################################
# El usuario lanza el objeto al objetivo. La potencia y el efecto depende del objeto.
# Lanzamiento / Fling
################################################################################
class PokeBattle_Move_0F7 < PokeBattle_Move
  # Optimized fling array with better organization and Ruby 1.8.7 compatibility
  def flingarray
    @flingarray ||= {
      130 => [:IRONBALL],
      100 => [:ARMORFOSSIL, :CLAWFOSSIL, :COVERFOSSIL, :DOMEFOSSIL, :HARDSTONE,
              :HELIXFOSSIL, :JAWFOSSIL, :OLDAMBER, :PLUMEFOSSIL, :RAREBONE,
              :ROOTFOSSIL, :SAILFOSSIL, :SKULLFOSSIL],
      90 => [:DEEPSEATOOTH, :DRACOPLATE, :DREADPLATE, :EARTHPLATE, :FISTPLATE,
             :FLAMEPLATE, :GRIPCLAW, :ICICLEPLATE, :INSECTPLATE, :IRONPLATE,
             :MEADOWPLATE, :MINDPLATE, :PIXIEPLATE, :SKYPLATE, :SPLASHPLATE,
             :SPOOKYPLATE, :STONEPLATE, :THICKCLUB, :TOXICPLATE, :ZAPPLATE],
      80 => [:ASSAULTVEST, :BLUNDERPOLICY, :CRACKEDPOT, :DAWNSTONE, :DUSKSTONE,
             :EJECTPACK, :ELECTIRIZER, :MAGMARIZER, :ODDKEYSTONE, :OVALSTONE,
             :PROTECTOR, :QUICKCLAW, :RAZORCLAW, :ROOMSERVICE, :SAFETYGOGGLES,
             :SHINYSTONE, :STICKYBARB, :UTILITYUMBRELLA, :WEAKNESSPOLICY,
             :MALICIOUSARMOR, :AUSPICIOUSARMOR, :LEADERSCREST],
      70 => [:BURNDRIVE, :CHILLDRIVE, :DOUSEDRIVE, :DRAGONFANG, :POISONBARB,
             :POWERANKLET, :POWERBAND, :POWERBELT, :POWERBRACER, :POWERLENS,
             :POWERWEIGHT, :SHOCKDRIVE],
      60 => [:ADAMANTORB, :DAMPROCK, :GRISEOUSORB, :HEATROCK, :LUSTROUSORB,
             :MACHOBRACE, :ROCKYHELMET, :STICK, :BLACKAUGURITE, :PEATBLOCK],
      50 => [:DUBIOUSDISC, :SHARPBEAK],
      40 => [:EVIOLITE, :ICYROCK, :LUCKYPUNCH],
      30 => [:ABILITYCAPSULE, :ABILITYURGE, :ABSORBBULB, :AMAZEMULCH, :AMULETCOIN,
             :ANTIDOTE, :AWAKENING, :BALMMUSHROOM, :BERRYJUICE, :BIGMUSHROOM,
             :BIGNUGGET, :BIGPEARL, :BINDINGBAND, :BLACKBELT, :BLACKFLUTE,
             :BLACKGLASSES, :BLACKSLUDGE, :BLUEFLUTE, :BLUESHARD, :BOOSTMULCH,
             :BURNHEAL, :CALCIUM, :CARBOS, :CASTELIACONE, :CELLBATTERY,
             :CHARCOAL, :CLEANSETAG, :COMETSHARD, :DAMPMULCH, :DEEPSEASCALE,
             :DIREHIT, :DIREHIT2, :DIREHIT3, :DRAGONSCALE, :EJECTBUTTON,
             :ELIXIR, :ENERGYPOWDER, :ENERGYROOT, :ESCAPEROPE, :ETHER,
             :EVERSTONE, :EXPSHARE, :FIRESTONE, :FLAMEORB, :FLOATSTONE,
             :FLUFFYTAIL, :FRESHWATER, :FULLHEAL, :FULLRESTORE, :GALARICACUFF,
             :GALARICAWREATH, :GOOEYMULCH, :GREENSHARD, :GROWTHMULCH, :GUARDSPEC,
             :HEALPOWDER, :HEARTSCALE, :HEAVYDUTYBOOTS, :HONEY, :HPUP, 
             :HYPERPOTION, :ICEHEAL, :ICESTONE, :IRON, :ITEMDROP, :ITEMURGE, 
             :KINGSROCK, :LAVACOOKIE, :LEAFSTONE, :LEMONADE, :LIFEORB, 
             :LIGHTBALL, :LIGHTCLAY, :LUCKYEGG, :LUMINOUSMOSS, :LUMIOSEGALETTE, 
             :MAGNET, :MAXELIXIR, :MAXETHER, :MAXPOTION, :MAXREPEL, :MAXREVIVE, 
             :METALCOAT, :METRONOME, :MIRACLESEED, :MOOMOOMILK, :MOONSTONE, 
             :MYSTICWATER, :NEVERMELTICE, :NUGGET, :OLDGATEAU, :PARALYZEHEAL, 
             :PARLYZHEAL, :PASSORB, :PEARL, :PEARLSTRING, :POKEDOLL, :POKETOY, 
             :POTENCIATOR, :POTION, :PPMAX, :PPUP, :PRISMSCALE, :PROTEIN, 
             :RAGECANDYBAR, :RARECANDY, :RAZORFANG, :REDFLUTE, :REDSHARD, 
             :RELICBAND, :RELICCOPPER, :RELICCROWN, :RELICGOLD, :RELICSILVER, 
             :RELICSTATUE, :RELICVASE, :REPEL, :RESETURGE, :REVIVALHERB, 
             :REVIVE, :RICHMULCH, :SACHET, :SACREDASH, :SCOPELENS, 
             :SHALOURSABLE, :SHELLBELL, :SHOALSALT, :SHOALSHELL, :SMOKEBALL, 
             :SNOWBALL, :SODAPOP, :SOULDEW, :SPELLTAG, :STABLEMULCH, 
             :STARDUST, :STARPIECE, :SUNSTONE, :SUPERPOTION, :SUPERREPEL, 
             :SURPRISEMULCH, :SWEETAPPLE, :SWEETHEART, :TARTAPPLE,
             :THUNDERSTONE, :TINYMUSHROOM, :TOXICORB, :TWISTEDSPOON, :UPGRADE,
             :WATERSTONE, :WHIPPEDDREAM, :WHITEFLUTE, :XACCURACY, :XACCURACY2, 
             :XACCURACY3, :XACCURACY6, :XATTACK, :XATTACK2, :XATTACK3, 
             :XATTACK6, :XDEFEND, :XDEFEND2, :XDEFEND3, :XDEFEND6, :XDEFENSE, 
             :XDEFENSE2, :XDEFENSE3, :XDEFENSE6, :XSPDEF, :XSPDEF2, :XSPDEF3, 
             :XSPDEF6, :XSPATK, :XSPATK2, :XSPATK3, :XSPATK6, :XSPECIAL, 
             :XSPECIAL2, :XSPECIAL3, :XSPECIAL6, :XSPEED, :XSPEED2, :XSPEED3,
             :XSPEED6, :YELLOWFLUTE, :YELLOWSHARD, :ZINC],
      20 => [:CLEVERWING, :GENIUSWING, :HEALTHWING, :MUSCLEWING, :PRETTYWING,
             :RESISTWING, :SWIFTWING],
      10 => [:AIRBALLOON, :BIGROOT, :BLUESCARF, :BRIGHTPOWDER, :CHOICEBAND,
             :CHOICESCARF, :CHOICESPECS, :DESTINYKNOT, :EXPERTBELT, :FOCUSBAND,
             :FOCUSSASH, :FULLINCENSE, :GREENSCARF, :LAGGINGTAIL, :LAXINCENSE,
             :LEFTOVERS, :LUCKINCENSE, :MENTALHERB, :METALPOWDER, :MUSCLEBAND,
             :ODDINCENSE, :PINKSCARF, :POWERHERB, :PUREINCENSE, :QUICKPOWDER,
             :REAPERCLOAK, :REDCARD, :REDSCARF, :RINGTARGET, :ROCKINCENSE,
             :ROSEINCENSE, :SEAINCENSE, :SHEDSHELL, :SILKSCARF, :SILVERPOWDER,
             :SMOOTHROCK, :SOFTSAND, :SOOTHEBELL, :WAVEINCENSE, :WHITEHERB,
             :WIDELENS, :WISEGLASSES, :YELLOWSCARF, :ZOOMLENS, :ELECTRICSEED,
             :GRASSYSEED, :MISTYSEED, :PSYCHICSEED]
    }
  end
  
  # Check if move can be used
  def pbMoveFailed(attacker, opponent)
    # Check basic failure conditions
    return true if attacker.item == 0 ||
                   @battle.pbIsUnlosableItem(attacker, attacker.item) ||
                   pbIsPokeBall?(attacker.item) ||
                   @battle.field.effects[PBEffects::MagicRoom] > 0 ||
                   attacker.hasWorkingAbility(:KLUTZ) ||
                   attacker.effects[PBEffects::Embargo] > 0

    # Check if item is flingable
    return false if getFlingPower(attacker.item) > 1
    # Check berry conditions with proper Unnerve handling
    if pbIsBerry?(attacker.item)
      opponents = []
      opponents.push(attacker.pbOpposing1) if attacker.pbOpposing1
      opponents.push(attacker.pbOpposing2) if attacker.pbOpposing2
      
      unnerve_active = opponents.any? do |opp|
        opp && (opp.hasWorkingAbility(:UNNERVE) ||
                opp.hasWorkingAbility(:ASONE1) ||
                opp.hasWorkingAbility(:ASONE2))
      end
      
      return !unnerve_active
    end
    return true
  end
    
  def pbBaseDamage(basedmg, attacker, opponent)
    getFlingPower(attacker.item)
  end
  
  def getFlingPower(item)
    return 10 if pbIsBerry?(item)
    return 80 if pbIsMegaStone?(item)
    flingarray.each do |power, items|
      return power if items.any? { |i| isConst?(item, PBItems, i) }
    end
    return 1
  end
  
  # Main effect method
  def pbEffect(attacker, opponent, hitnum = 0, alltargets = nil, showanimation = true)
    if attacker.item == 0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return 0
    end
    thrownItem = attacker.item
    attacker.effects[PBEffects::Unburden] = true
    @battle.pbDisplay(_INTL("¡{1} lanzó {2}!", attacker.pbThis, PBItems.getName(thrownItem)))
    ret = super(attacker, opponent, hitnum, alltargets, showanimation)
    # Apply additional effects if damage was dealt
    if opponent.damagestate.calcdamage > 0 && 
       !opponent.damagestate.substitute &&
       !opponent.hasWorkingItem(:COVERTCLOAK) &&
       (attacker.hasMoldBreaker || !opponent.hasWorkingAbility(:SHIELDDUST))
      
      applyThrownItemEffect(attacker, opponent, thrownItem)
    end
    # Consume the item
    attacker.pbConsumeItem
    return ret
  end
  
  # Apply thrown item effects
  def applyThrownItemEffect(attacker, opponent, item)
    if pbIsBerry?(item)
      opponent.pbActivateBerryEffect(item, false)
    elsif isConst?(item, PBItems, :FLAMEORB)
      opponent.pbBurn(attacker) if opponent.pbCanBurn?(attacker, false, self)
    elsif isConst?(item, PBItems, :KINGSROCK) || isConst?(item, PBItems, :RAZORFANG)
      opponent.pbFlinch(attacker)
    elsif isConst?(item, PBItems, :LIGHTBALL)
      opponent.pbParalyze(attacker) if opponent.pbCanParalyze?(attacker, false, self)
    elsif isConst?(item, PBItems, :MENTALHERB)
      applyMentalHerbEffects(opponent)
    elsif isConst?(item, PBItems, :POISONBARB)
      opponent.pbPoison(attacker) if opponent.pbCanPoison?(attacker, false, self)
    elsif isConst?(item, PBItems, :TOXICORB)
      opponent.pbPoison(attacker, nil, true) if opponent.pbCanPoison?(attacker, false, self)
    elsif isConst?(item, PBItems, :WHITEHERB)
      applyWhiteHerbEffects(opponent)
    end
  end

  # Apply Mental Herb effects
  def applyMentalHerbEffects(pokemon)
    effects_cured = []
    if pokemon.effects[PBEffects::Attract] >= 0
      pokemon.pbCureAttract
      effects_cured << _INTL("¡{1} dejó de estar enamorado!", pokemon.pbThis)
    end
    if pokemon.effects[PBEffects::Taunt] > 0
      pokemon.effects[PBEffects::Taunt] = 0
      effects_cured << _INTL("¡La Mofa de {1} se terminó!", pokemon.pbThis)
    end
    if pokemon.effects[PBEffects::Encore] > 0
      pokemon.effects[PBEffects::Encore] = 0
      pokemon.effects[PBEffects::EncoreMove] = 0
      pokemon.effects[PBEffects::EncoreIndex] = 0
      effects_cured << _INTL("¡Los efectos de Otra Vez de {1} se terminaron!", pokemon.pbThis)
    end
    if pokemon.effects[PBEffects::Torment]
      pokemon.effects[PBEffects::Torment] = false
      effects_cured << _INTL("¡Los efectos de Tormento de {1} se terminaron!", pokemon.pbThis)
    end
    if pokemon.effects[PBEffects::Disable] > 0
      pokemon.effects[PBEffects::Disable] = 0
      effects_cured << _INTL("¡{1} ya no está desactivado!", pokemon.pbThis)
    end
    if pokemon.effects[PBEffects::HealBlock] > 0
      pokemon.effects[PBEffects::HealBlock] = 0
      effects_cured << _INTL("¡Los efectos de Anticura de {1} se terminaron!", pokemon.pbThis)
    end
    # Display all cured effects
    effects_cured.each { |msg| @battle.pbDisplay(msg) }
  end
  # Apply White Herb effects
  def applyWhiteHerbEffects(pokemon)
    stats_restored = false
    [PBStats::ATTACK, PBStats::DEFENSE, PBStats::SPEED, 
     PBStats::SPATK, PBStats::SPDEF, PBStats::EVASION, PBStats::ACCURACY].each do |stat|
      if pokemon.stages[stat] < 0
        pokemon.stages[stat] = 0
        stats_restored = true
      end
    end
    if stats_restored
      @battle.pbDisplay(_INTL("¡El estado de {1} volvió a la normalidad!", pokemon.pbThis(true)))
    end
  end
end

################################################################################
# Durante 5 rondas, el objetivo no puede usar el objeto que lleva, el objeto
# pierde el efecto que pueda tener y el entrenador no puede usar ningún objeto
# en el objetivo.
# Embargo
################################################################################
class PokeBattle_Move_0F8 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Embargo]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Embargo]=5
    @battle.pbDisplay(_INTL("¡{1} no puede usar objetos!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Durante 5 rondas, los objetos no se pueden usar de ninguna forma y tampoco
# tienen efecto.
# Los objetos se pueden cambiar de mano, pero no tirar.
# Magic Room / Zona Mágica
################################################################################
class PokeBattle_Move_0F9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::MagicRoom]>0
      @battle.field.effects[PBEffects::MagicRoom]=0
      @battle.pbDisplay(_INTL("¡La Zona Mágica se acabó, y los efectos de los objetos volvieron a la normalidad!"))
    else
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.field.effects[PBEffects::MagicRoom]=5
      @battle.pbDisplay(_INTL("¡Se ha creado un espacio mágico en el que los efectos de los objetos desaparecieron!"))
    end
    return 0
  end
end



################################################################################
# El usuario recibe daño de retroceso igual a 1/4 del daño causado.
################################################################################
class PokeBattle_Move_0FA < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if !attacker.hasWorkingAbility(:ROCKHEAD) &&
         !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((turneffects[PBEffects::TotalDamage]/4.0).round)
        @battle.pbDisplay(_INTL("¡{1} es dañado por el retroceso!",attacker.pbThis))
      end
    end
  end
end



################################################################################
# El usuario recibe daño de retroceso igual a 1/3 del daño causado.
################################################################################
class PokeBattle_Move_0FB < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if !attacker.hasWorkingAbility(:ROCKHEAD) &&
         !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((turneffects[PBEffects::TotalDamage]/3.0).round)
        @battle.pbDisplay(_INTL("¡{1} es dañado por el retroceso!",attacker.pbThis))
      end
    end
  end
end



################################################################################
# El usuario recibe daño de retroceso igual a 1/3 del daño causado.
# (Testarazo/Head Smash)
################################################################################
class PokeBattle_Move_0FC < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if !attacker.hasWorkingAbility(:ROCKHEAD) &&
         !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((turneffects[PBEffects::TotalDamage]/2.0).round)
        @battle.pbDisplay(_INTL("¡{1} es dañado por el retroceso!",attacker.pbThis))
      end
    end
  end
end



################################################################################
# El usuario recibe daño de retroceso igual a 1/3 del daño causado.
# Puede paralizar al objetivo.
# Placaje Eléc. / Volt Tackle
################################################################################
class PokeBattle_Move_0FD < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if !attacker.hasWorkingAbility(:ROCKHEAD) &&
         !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((turneffects[PBEffects::TotalDamage]/3.0).round)
        @battle.pbDisplay(_INTL("¡{1} es dañado por el retroceso!",attacker.pbThis))
      end
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanParalyze?(attacker,false,self)
      opponent.pbParalyze(attacker)
    end
  end
end



################################################################################
# El usuario recibe daño de retroceso igual a 1/3 del daño causado.
# Puede quemar al objetivo.
# Envite Ígneo / Flare Blitz
################################################################################
class PokeBattle_Move_0FE < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if !attacker.hasWorkingAbility(:ROCKHEAD) &&
         !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((turneffects[PBEffects::TotalDamage]/3.0).round)
        @battle.pbDisplay(_INTL("¡{1} es dañado por el retroceso!",attacker.pbThis))
      end
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanBurn?(attacker,false,self)
      opponent.pbBurn(attacker)
    end
  end
end



################################################################################
# Activa el clima Soleado.
# Día Soleado / Sunny Day
################################################################################
class PokeBattle_Move_0FF < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    case @battle.weather
    when PBWeather::HEAVYRAIN
      @battle.pbDisplay(_INTL("¡No hay alivio para este diluvio!"))
      return -1
    when PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡El sol realmente abrazador no ha mermado en absoluto!"))
      return -1
    when PBWeather::STRONGWINDS
      @battle.pbDisplay(_INTL("¡Las misteriosas turbulencias siguen soplando sin cesar!"))
      return -1
    when PBWeather::SUNNYDAY
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.weather=PBWeather::SUNNYDAY
    @battle.weatherduration=5
    @battle.weatherduration=8 if attacker.hasWorkingItem(:HEATROCK)
    @battle.pbCommonAnimation("Sunny",nil,nil)
    @battle.pbDisplay(_INTL("¡El sol está brillando!"))
    return 0
  end
end



################################################################################
# Activa el clima lluvioso.
# Danza Lluvia / Rain Dance
################################################################################
class PokeBattle_Move_100 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    case @battle.weather
    when PBWeather::HEAVYRAIN
      @battle.pbDisplay(_INTL("¡No hay alivio para este diluvio!"))
      return -1
    when PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡El sol realmente abrazador no ha mermado en absoluto!"))
      return -1
    when PBWeather::STRONGWINDS
      @battle.pbDisplay(_INTL("¡Las misteriosas turbulencias siguen soplando sin cesar!"))
      return -1
    when PBWeather::RAINDANCE
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.weather=PBWeather::RAINDANCE
    @battle.weatherduration=5
    @battle.weatherduration=8 if attacker.hasWorkingItem(:DAMPROCK)
    @battle.pbCommonAnimation("Rain",nil,nil)
    @battle.pbDisplay(_INTL("¡Ha empezado a llover!"))
    return 0
  end
end



################################################################################
# Activa el clima Tormenta de Arena.
# Torm. Arena / Sandstorm
################################################################################
class PokeBattle_Move_101 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    case @battle.weather
    when PBWeather::HEAVYRAIN
      @battle.pbDisplay(_INTL("¡No hay alivio para este diluvio!"))
      return -1
    when PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡El sol realmente abrazador no ha mermado en absoluto!"))
      return -1
    when PBWeather::STRONGWINDS
      @battle.pbDisplay(_INTL("¡Las misteriosas turbulencias siguen soplando sin cesar!"))
      return -1
    when PBWeather::SANDSTORM
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.weather=PBWeather::SANDSTORM
    @battle.weatherduration=5
    @battle.weatherduration=8 if attacker.hasWorkingItem(:SMOOTHROCK)
    @battle.pbCommonAnimation("Sandstorm",nil,nil)
    @battle.pbDisplay(_INTL("¡Se acerca una tormenta de arena!"))
    return 0
  end
end



################################################################################
# Activa el clima Granizo.
# Granizo / Hail
################################################################################
class PokeBattle_Move_102 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    case @battle.weather
    when PBWeather::HEAVYRAIN
      @battle.pbDisplay(_INTL("¡No hay alivio para este diluvio!"))
      return -1
    when PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡El sol realmente abrazador no ha mermado en absoluto!"))
      return -1
    when PBWeather::STRONGWINDS
      @battle.pbDisplay(_INTL("¡Las misteriosas turbulencias siguen soplando sin cesar!"))
      return -1
    when PBWeather::HAIL
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.weather=PBWeather::HAIL
    @battle.weatherduration=5
    @battle.weatherduration=8 if attacker.hasWorkingItem(:ICYROCK)
    @battle.pbCommonAnimation("Hail",nil,nil)
    @battle.pbDisplay(_INTL("¡Ha empezado a granizar!"))
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
    return 0
  end
end



################################################################################
# Trampa de entrada. Se coloca una capa de púas en el campo enemigo (máx. 3 capas).
# Púas / Spikes
################################################################################
class PokeBattle_Move_103 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[PBEffects::Spikes]>=3
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOpposingSide.effects[PBEffects::Spikes]+=1
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡El equipo enemigo ha sido rodeado de púas!"))
    else
      @battle.pbDisplay(_INTL("¡Tu equipo ha sido rodeado de púas!"))
    end
    return 0
  end
end



################################################################################
# Trampa de entrada. Se coloca una capa de púas venenosas en el campo enemigo (máx. 2 capas).
# Púas Tóxicas / Toxic Spikes
################################################################################
class PokeBattle_Move_104 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[PBEffects::ToxicSpikes]>=2
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOpposingSide.effects[PBEffects::ToxicSpikes]+=1
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡El equipo enemigo ha sido rodeado de púas venenosas!"))
    else
      @battle.pbDisplay(_INTL("¡Tu equipo ha sido rodeado de púas venenosas!"))
    end
    return 0
  end
end



################################################################################
# Trampa de entrada. Arroja rocas puntiagudas en el campo enemigo.
# Trampa Rocas / Stealth Rock
################################################################################
class PokeBattle_Move_105 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[PBEffects::StealthRock]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOpposingSide.effects[PBEffects::StealthRock]=true
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡El equipo enemigo está rodeado de piedras puntiagudas!"))
    else
      @battle.pbDisplay(_INTL("¡Tu equipo está rodeado de piedras puntiagudas!"))
    end
    return 0
  end
end



################################################################################
# Fuerza a un movimiento Voto aliado ser usado a continuación, si no estaba listo. (Voto Planta  /  Grass Pledge)
# Se combina con un movimiento Voto de un aliado en caso de ser usado.
# La potencia se duplica, y puede causar un mar de llamas o un pantano en el campo rival.
################################################################################
class PokeBattle_Move_106 < PokeBattle_Move
  def pbOnStartUse(attacker)
    @doubledamage=false; @overridetype=false
    if attacker.effects[PBEffects::FirstPledge]==0x107 ||   # Voto Fuego
       attacker.effects[PBEffects::FirstPledge]==0x108      # Voto Agua
      @battle.pbDisplay(_INTL("¡Los dos movimientos se han unido! ¡Es un movimiento combinado!"))
      @doubledamage=true
      if attacker.effects[PBEffects::FirstPledge]==0x107    # Voto Fuego
        @overridetype=true
      end
    end
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @doubledamage
      return basedmg*2
    end
    return basedmg
  end

  def pbModifyType(type,attacker,opponent)
    if @overridetype
      type=getConst(PBTypes,:FIRE) || 0
    end
    return super(type,attacker,opponent)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle || !attacker.pbPartner || attacker.pbPartner.isFainted?
      attacker.effects[PBEffects::FirstPledge]=0
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    end
    # Efecto del movimiento combinado
    if attacker.effects[PBEffects::FirstPledge]==0x107          # Voto Fuego
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0
        attacker.pbOpposingSide.effects[PBEffects::SeaOfFire]=4
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡El equipo rival se ve rodeado por un mar de llamas!"))
          @battle.pbCommonAnimation("SeaOfFireOpp",nil,nil)
        else
          @battle.pbDisplay(_INTL("¡Tu equipo se ve rodeado por un mar de llamas!"))
          @battle.pbCommonAnimation("SeaOfFire",nil,nil)
        end
      end
      attacker.effects[PBEffects::FirstPledge]=0
      return ret
    elsif attacker.effects[PBEffects::FirstPledge]==0x108       # Voto Agua
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0
        attacker.pbOpposingSide.effects[PBEffects::Swamp]=4
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡Ha aparecido un pantano alrededor del equipo rival!"))
          @battle.pbCommonAnimation("SwampOpp",nil,nil)
        else
          @battle.pbDisplay(_INTL("¡Ha aparecido un pantano alrededor de tu equipo!"))
          @battle.pbCommonAnimation("Swamp",nil,nil)
        end
      end
      attacker.effects[PBEffects::FirstPledge]=0
      return ret
    end
    # Establece aliado para un movimiento combinado
    attacker.effects[PBEffects::FirstPledge]=0
    partnermove=-1
    if @battle.choices[attacker.pbPartner.index][0]==1          # Elige un movimiento
      if !attacker.pbPartner.hasMovedThisRound?
        move=@battle.choices[attacker.pbPartner.index][2]
        if move && move.id>0
          partnermove=@battle.choices[attacker.pbPartner.index][2].function
        end
      end
    end
    if partnermove==0x107 ||                                    # Voto Fuego
       partnermove==0x108                                       # Voto Agua
      @battle.pbDisplay(_INTL("{1} está esperando a {2}...",attacker.pbThis,attacker.pbPartner.pbThis(true)))
      attacker.pbPartner.effects[PBEffects::FirstPledge]==@function
      attacker.pbPartner.effects[PBEffects::MoveNext]=true
      return 0
    end
    # Usa el movimiento por sí solo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @overridetype
      return super(getConst(PBMoves,:FIREPLEDGE),attacker,opponent,hitnum,alltargets,showanimation)
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Fuerza a un movimiento Voto aliado ser usado a continuación, si no estaba listo. (Voto Fuego  /  Fire Pledge)
# Se combina con un movimiento Voto de un aliado en caso de ser usado.
# La potencia se duplica, y puede causar un mar de llamas en el campo rival o un arcoiris sobre el campo del usuario.
################################################################################
class PokeBattle_Move_107 < PokeBattle_Move
  def pbOnStartUse(attacker)
    @doubledamage=false; @overridetype=false
    if attacker.effects[PBEffects::FirstPledge]==0x106 ||       # Voto Planta
       attacker.effects[PBEffects::FirstPledge]==0x108          # Voto Agua
      @battle.pbDisplay(_INTL("¡Los dos movimientos se han unido! ¡Es un movimiento combinado!"))
      @doubledamage=true
      if attacker.effects[PBEffects::FirstPledge]==0x108        # Voto Agua
        @overridetype=true
      end
    end
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @doubledamage
      return basedmg*2
    end
    return basedmg
  end

  def pbModifyType(type,attacker,opponent)
    if @overridetype
      type=getConst(PBTypes,:WATER) || 0
    end
    return super(type,attacker,opponent)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle || !attacker.pbPartner || attacker.pbPartner.isFainted?
      attacker.effects[PBEffects::FirstPledge]=0
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    end
    # Efecto del movimiento combinado
    if attacker.effects[PBEffects::FirstPledge]==0x106          # Voto Planta
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0
        attacker.pbOpposingSide.effects[PBEffects::SeaOfFire]=4
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡El equipo rival se ve rodeado por un mar de llamas!"))
          @battle.pbCommonAnimation("SeaOfFireOpp",nil,nil)
        else
          @battle.pbDisplay(_INTL("¡Tu equipo se ve rodeado por un mar de llamas!"))
          @battle.pbCommonAnimation("SeaOfFire",nil,nil)
        end
      end
      attacker.effects[PBEffects::FirstPledge]=0
      return ret
    elsif attacker.effects[PBEffects::FirstPledge]==0x108       # Voto Agua
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0
        attacker.pbOwnSide.effects[PBEffects::Rainbow]=4
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡Ha aparecido un arcoiris sobre tu equipo!"))
          @battle.pbCommonAnimation("Rainbow",nil,nil)
        else
          @battle.pbDisplay(_INTL("¡Ha aparecido un arcoiris sobre el equipo rival!"))
          @battle.pbCommonAnimation("RainbowOpp",nil,nil)
        end
      end
      attacker.effects[PBEffects::FirstPledge]=0
      return ret
    end
    # Establece aliado para un movimiento combinado
    attacker.effects[PBEffects::FirstPledge]=0
    partnermove=-1
    if @battle.choices[attacker.pbPartner.index][0]==1          # Elige un movimiento
      if !attacker.pbPartner.hasMovedThisRound?
        move=@battle.choices[attacker.pbPartner.index][2]
        if move && move.id>0
          partnermove=@battle.choices[attacker.pbPartner.index][2].function
        end
      end
    end
    if partnermove==0x106 ||                                    # Voto Planta
       partnermove==0x108                                       # Voto Agua
      @battle.pbDisplay(_INTL("{1} está esperando a {2}...",attacker.pbThis,attacker.pbPartner.pbThis(true)))
      attacker.pbPartner.effects[PBEffects::FirstPledge]==@function
      attacker.pbPartner.effects[PBEffects::MoveNext]=true
      return 0
    end
    # Usa el movimiento por sí solo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @overridetype
      return super(getConst(PBMoves,:WATERPLEDGE),attacker,opponent,hitnum,alltargets,showanimation)
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Fuerza a un movimiento Voto aliado ser usado a continuación, si no estaba listo. (Voto Agua  /  Water Pledge)
# Se combina con un movimiento Voto de un aliado en caso de ser usado.
# La potencia se duplica, y puede causar un pantano en el campo rival o un arcoiris sobre el campo del usuario.
################################################################################
class PokeBattle_Move_108 < PokeBattle_Move
  def pbOnStartUse(attacker)
    @doubledamage=false; @overridetype=false
    if attacker.effects[PBEffects::FirstPledge]==0x106 ||       # Voto Planta
       attacker.effects[PBEffects::FirstPledge]==0x107          # Voto Fuego
      @battle.pbDisplay(_INTL("¡Los dos movimientos se han unido! ¡Es un movimiento combinado!"))
      @doubledamage=true
      if attacker.effects[PBEffects::FirstPledge]==0x106        # Voto Planta
        @overridetype=true
      end
    end
    return true
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @doubledamage
      return basedmg*2
    end
    return basedmg
  end

  def pbModifyType(type,attacker,opponent)
    if @overridetype
      type=getConst(PBTypes,:GRASS) || 0
    end
    return super(type,attacker,opponent)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle || !attacker.pbPartner || attacker.pbPartner.isFainted?
      attacker.effects[PBEffects::FirstPledge]=0
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    end
    # Efecto del movimiento combinado
    if attacker.effects[PBEffects::FirstPledge]==0x106          # Voto Planta
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0
        attacker.pbOpposingSide.effects[PBEffects::Swamp]=4
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡Ha aparecido un pantano alrededor del equipo rival!"))
          @battle.pbCommonAnimation("SwampOpp",nil,nil)
        else
          @battle.pbDisplay(_INTL("¡Ha aparecido un pantano alrededor de tu equipo!"))
          @battle.pbCommonAnimation("Swamp",nil,nil)
        end
      end
      attacker.effects[PBEffects::FirstPledge]=0
      return ret
    elsif attacker.effects[PBEffects::FirstPledge]==0x107       # Voto Fuego
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0
        attacker.pbOwnSide.effects[PBEffects::Rainbow]=4
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡Ha aparecido un arcoiris sobre tu equipo!"))
          @battle.pbCommonAnimation("Rainbow",nil,nil)
        else
          @battle.pbDisplay(_INTL("¡Ha aparecido un arcoiris sobre el equipo rival!"))
          @battle.pbCommonAnimation("RainbowOpp",nil,nil)
        end
      end
      attacker.effects[PBEffects::FirstPledge]=0
      return ret
    end
    # Establece aliado para un movimiento combinado
    attacker.effects[PBEffects::FirstPledge]=0
    partnermove=-1
    if @battle.choices[attacker.pbPartner.index][0]==1          # Elige un movimiento
      if !attacker.pbPartner.hasMovedThisRound?
        move=@battle.choices[attacker.pbPartner.index][2]
        if move && move.id>0
          partnermove=@battle.choices[attacker.pbPartner.index][2].function
        end
      end
    end
    if partnermove==0x106 ||                                    # Voto Planta
       partnermove==0x107                                       # Voto Fuego
      @battle.pbDisplay(_INTL("{1} está esperando a {2}...",attacker.pbThis,attacker.pbPartner.pbThis(true)))
      attacker.pbPartner.effects[PBEffects::FirstPledge]==@function
      attacker.pbPartner.effects[PBEffects::MoveNext]=true
      return 0
    end
    # Usa el movimiento por sí solo
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @overridetype
      return super(getConst(PBMoves,:GRASSPLEDGE),attacker,opponent,hitnum,alltargets,showanimation)
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Dispersa monedas que el jugador levanta cuando gana la batalla.
# (Día de Pago  /  Pay Day)
################################################################################
class PokeBattle_Move_109 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if @battle.pbOwnedByPlayer?(attacker.index)
        @battle.extramoney+=5*attacker.level
        @battle.extramoney=MAXMONEY if @battle.extramoney>MAXMONEY
      end
      @battle.pbDisplay(_INTL("¡Hay monedas por todas partes!"))
    end
    return ret
  end
end



################################################################################
# Acaba con Pantalla Luz y Reflejo del lado enemigo.
# (Demolición  /  Brick Break)
################################################################################
class PokeBattle_Move_10A < PokeBattle_Move
  def pbCalcDamage(attacker,opponent)
    return super(attacker,opponent,PokeBattle_Move::NOREFLECT)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.pbOpposingSide.effects[PBEffects::Reflect]>0
      attacker.pbOpposingSide.effects[PBEffects::Reflect]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡Reflejo del equipo enemigo no funciona!"))
      else
        @battle.pbDisplayPaused(_INTL("¡Reflejo no funciona en tu equipo!"))
      end
    end
    if attacker.pbOpposingSide.effects[PBEffects::LightScreen]>0
      attacker.pbOpposingSide.effects[PBEffects::LightScreen]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡Pantalla Luz del equipo enemigo no funciona!"))
      else
        @battle.pbDisplay(_INTL("¡Pantalla Luz no funciona en tu equipo!"))
      end
    end
	   if attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]>0
      attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡Velo Aurora del equipo enemigo no funciona!"))
      else
        @battle.pbDisplay(_INTL("¡Velo Aurora no funciona en tu equipo!"))
      end
    end
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[PBEffects::Reflect]>0 ||
       attacker.pbOpposingSide.effects[PBEffects::LightScreen]>0 ||
       attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]>0
      return super(id,attacker,opponent,1,alltargets,showanimation) # Wall-breaking anim
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Si el ataque falla, el usuario es dañado restando 1/2 de los PS máximos.
# (Pat. Super Alta, Patada Salto / Hi Jump Kick, Jump Kick)
################################################################################
class PokeBattle_Move_10B < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def unusableInGravity?
    return true
  end
end



################################################################################
# El usuario conviente 1/4 de sus PS máximos en un sustituto.
# (Sustituto/Substitute)
################################################################################
class PokeBattle_Move_10C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Substitute]>0
      @battle.pbDisplay(_INTL("¡{1} ya tiene un sustituto!",attacker.pbThis))
      return -1
    end
    sublife=[(attacker.totalhp/4).floor,1].max
    if attacker.hp<=sublife
      @battle.pbDisplay(_INTL("¡Estaba muy debil para crear un sustituto!"))
      return -1
    end
    attacker.pbReduceHP(sublife,false,false)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::MultiTurn]=0
    attacker.effects[PBEffects::MultiTurnAttack]=0
    attacker.effects[PBEffects::Substitute]=sublife
    @battle.pbDisplay(_INTL("¡{1} creó un sustituto!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Si el usuario no es Fantasma: Reduce la Velocidad del usuario, pero incrementa
# su Ataque y Defensa en 1 nivel cada uno.
# Si el usuario es Fantasma: Se resta 1/2 de los PS máximos del usuario y maldice al objetivo.
# Un Pokémon maldecido pierde 1/4 de sus PS máximos al final de cada ronda.
# (Maldición/Curse)
################################################################################
class PokeBattle_Move_10D < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    failed=false
    if attacker.pbHasType?(:GHOST)
      if opponent.effects[PBEffects::Curse] ||
         opponent.pbOwnSide.effects[PBEffects::CraftyShield]
        failed=true
      else
        pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
        @battle.pbDisplay(_INTL("¡{1} reduce sus PS y maldice a {2}!",attacker.pbThis,opponent.pbThis(true)))
        opponent.effects[PBEffects::Curse]=true
        attacker.pbReduceHP((attacker.totalhp/2).floor)
      end
    else
      lowerspeed=attacker.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
      raiseatk=attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      raisedef=attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      if !lowerspeed && !raiseatk && !raisedef
        failed=true
      else
        pbShowAnimation(@id,attacker,nil,1,alltargets,showanimation)   # Animación de movimiento no Fantasma
        if lowerspeed
          attacker.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
        end
        showanim=true
        if raiseatk
          attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
          showanim=false
        end
        if raisedef
          attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
          showanim=false
        end
      end
    end
    if failed
      @battle.pbDisplay(_INTL("¡Pero falló!"))
    end
    return failed ? -1 : 0
  end
end



################################################################################
# El último movimiento del objetivo pierde 4 PP.
# (Rencor/Spite)
################################################################################
class PokeBattle_Move_10E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for i in opponent.moves
      if i.id==opponent.lastMoveUsed && i.id>0 && i.pp>0
        pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
        reduction=[4,i.pp].min
        i.pp-=reduction
        @battle.pbDisplay(_INTL("¡Se redujeron los PP de {2} de {1} en {3}!",opponent.pbThis(true),i.name,reduction))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end



################################################################################
# El objetivo perderá 1/4 de sus PS máximos al final de cada ronda mientras
# permanezca dormido.
# (Pesadilla/Nightmare)
################################################################################
class PokeBattle_Move_10F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (opponent.status!=PBStatuses::SLEEP || opponent.effects[PBEffects::Nightmare] ||
       (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker))) &&
       (!opponent.hasWorkingAbility(:COMATOSE) ||
       isConst?(opponent.species,PBSpecies,:KOMALA) || opponent.effects[PBEffects::Nightmare] ||
       (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Nightmare]=true
    @battle.pbDisplay(_INTL("¡{1} ha caído en una Pesadilla!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Remueve movimientos de trampa, obstáculos de entrada y Drenadoras del lado del usuario.
# (Giro Rápido/Rapid Spin)
################################################################################
class PokeBattle_Move_110 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,true,self)
        attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
      end
      if attacker.effects[PBEffects::MultiTurn]>0
        mtattack=PBMoves.getName(attacker.effects[PBEffects::MultiTurnAttack])
        mtuser=@battle.battlers[attacker.effects[PBEffects::MultiTurnUser]]
        @battle.pbDisplay(_INTL("¡{1} se liberó de {3} de {2}!",attacker.pbThis,mtuser.pbThis(true),mtattack))
        attacker.effects[PBEffects::MultiTurn]=0
        attacker.effects[PBEffects::MultiTurnAttack]=0
        attacker.effects[PBEffects::MultiTurnUser]=-1
      end
      if attacker.effects[PBEffects::LeechSeed]>=0
        attacker.effects[PBEffects::LeechSeed]=-1
        @battle.pbDisplay(_INTL("¡{1} se liberó de las Drenadoras!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::StealthRock]
        attacker.pbOwnSide.effects[PBEffects::StealthRock]=false
        @battle.pbDisplay(_INTL("¡{1} se deshizo de las piedras puntiagudas!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::Spikes]>0
        attacker.pbOwnSide.effects[PBEffects::Spikes]=0
        @battle.pbDisplay(_INTL("¡{1} se deshizo de las púas!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
        attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]=0
        @battle.pbDisplay(_INTL("¡{1} se deshizo de las púas venenosas!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
        attacker.pbOwnSide.effects[PBEffects::StickyWeb]=false
        @battle.pbDisplay(_INTL("¡{1} se deshizo de la red pegajosa!",attacker.pbThis))
      end
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
    end
  end
end

################################################################################
# Ataca 2 rondas en el futuro.
# (Deseo Oculto, Premonición / Doom Desire, Future Sight)
################################################################################
class PokeBattle_Move_111 < PokeBattle_Move
  def pbDisplayUseMessage(attacker)
    return 0 if @battle.futuresight
    return super(attacker)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::FutureSight]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if @battle.futuresight
      # Attack hits
      return super(attacker,opponent,hitnum,alltargets,showanimation)
    end
    # Attack is launched
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::FutureSight]=3
    opponent.effects[PBEffects::FutureSightMove]=@id
    opponent.effects[PBEffects::FutureSightUser]=attacker.pokemonIndex
    opponent.effects[PBEffects::FutureSightUserPos]=attacker.index
    if isConst?(@id,PBMoves,:FUTURESIGHT)
      @battle.pbDisplay(_INTL("¡{1} previó un ataque!",attacker.pbThis))
    else
      @battle.pbDisplay(_INTL("¡Deseo Oculto de {1} se cumplirá más adelante!",attacker.pbThis))
    end
    return 0
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.futuresight
      return super(id,attacker,opponent,1,alltargets,showanimation) # Animación de golpe al oponente
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Incrementa la Defensa y Defensa Especial del usuario en 1 nivel cada una.
# Sube la Reserva del usuario en 1 (máximo 3).
# (Reserva/Stockpile)
################################################################################
class PokeBattle_Move_112 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Stockpile]>=3
      @battle.pbDisplay(_INTL("¡{1} no puede reservar más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Stockpile]+=1
    @battle.pbDisplay(_INTL("¡{1} reservó {2}!",attacker.pbThis,
        attacker.effects[PBEffects::Stockpile]))
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      attacker.effects[PBEffects::StockpileDef]+=1
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      attacker.effects[PBEffects::StockpileSpDef]+=1
      showanim=false
    end
    return 0
  end
end



################################################################################
# La potencia es de 100 multiplicada por las reservas del usuario (X).
# Restablece la reserva en 0.
# Reduce la Defensa y Defensa Especial del usuario en X niveles cada una.
# (Escupir/Spit Up)
################################################################################
class PokeBattle_Move_113 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return (attacker.effects[PBEffects::Stockpile]==0)
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    return 100*attacker.effects[PBEffects::Stockpile]
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      showanim=true
      if attacker.effects[PBEffects::StockpileDef]>0
        if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
          attacker.pbReduceStat(PBStats::DEFENSE,attacker.effects[PBEffects::StockpileDef],
             attacker,false,self,showanim)
          showanim=false
        end
      end
      if attacker.effects[PBEffects::StockpileSpDef]>0
        if attacker.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
          attacker.pbReduceStat(PBStats::SPDEF,attacker.effects[PBEffects::StockpileSpDef],
             attacker,false,self,showanim)
          showanim=false
        end
      end
      attacker.effects[PBEffects::Stockpile]=0
      attacker.effects[PBEffects::StockpileDef]=0
      attacker.effects[PBEffects::StockpileSpDef]=0
      @battle.pbDisplay(_INTL("{1}'s stockpiled effect wore off!",attacker.pbThis))
    end
  end
end



################################################################################
# Recupera los PS del usuario dependiendo del contador de la reserva (X).
# Restablece la reserva en 0.
# Reduce la Defensa y Defensa Especial del usuario en X niveles cada una.
# (Tragar/Swallow)
################################################################################
class PokeBattle_Move_114 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    hpgain=0
    case attacker.effects[PBEffects::Stockpile]
    when 0
      @battle.pbDisplay(_INTL("¡Pero no consiguió tragar energía!"))
      return -1
    when 1
      hpgain=(attacker.totalhp/4).floor
    when 2
      hpgain=(attacker.totalhp/2).floor
    when 3
      hpgain=attacker.totalhp
    end
    if attacker.hp==attacker.totalhp &&
       attacker.effects[PBEffects::StockpileDef]==0 &&
       attacker.effects[PBEffects::StockpileSpDef]==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    if attacker.pbRecoverHP(hpgain,true)>0
      @battle.pbDisplay(_INTL("{{1} recuperó salud.",attacker.pbThis))
    end
    showanim=true
    if attacker.effects[PBEffects::StockpileDef]>0
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbReduceStat(PBStats::DEFENSE,attacker.effects[PBEffects::StockpileDef],
           attacker,false,self,showanim)
        showanim=false
      end
    end
    if attacker.effects[PBEffects::StockpileSpDef]>0
      if attacker.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPDEF,attacker.effects[PBEffects::StockpileSpDef],
           attacker,false,self,showanim)
        showanim=false
      end
    end
    attacker.effects[PBEffects::Stockpile]=0
    attacker.effects[PBEffects::StockpileDef]=0
    attacker.effects[PBEffects::StockpileSpDef]=0
    @battle.pbDisplay(_INTL("¡Desaparecieron los efectos de la reserva de {1}!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Falla si el usuario ha sido golpeado por un movimiento de daño esta ronda.
# (Puño Certero/Focus Punch)
################################################################################
class PokeBattle_Move_115 < PokeBattle_Move
  def pbDisplayUseMessage(attacker)
    if attacker.lastHPLost>0
      @battle.pbDisplayBrief(_INTL("¡{1} perdió su concentración y no se pudo mover!",attacker.pbThis))
      return -1
    end
    return super(attacker)
  end
end

################################################################################
# Falla si el objetivo no ha elegido un movimiento de daño en esta ronda, o si ya
# se ha movido.
# (Golpe Bajo/Sucker Punch)
################################################################################
class PokeBattle_Move_116 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return true if @battle.choices[opponent.index][0]!=1   # No ha elegido un movimiento
    oppmove=@battle.choices[opponent.index][2]
    return true if !oppmove || oppmove.id<=0 || oppmove.pbIsStatus?
    return true if opponent.hasMovedThisRound? && oppmove.function!=0xB0   # Yo Primero
    return false
  end
end



################################################################################
# Esta ronda, el usuario de convierte en el objetivo de los ataques que tienen
# un solo objetivo.
# (Señuelo, Polvo Ira / Follow Me, Rage Powder)
################################################################################
class PokeBattle_Move_117 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::FollowMe]=1
    if !attacker.pbPartner.isFainted? && attacker.pbPartner.effects[PBEffects::FollowMe]>0
      attacker.effects[PBEffects::FollowMe]=attacker.pbPartner.effects[PBEffects::FollowMe]+1
    end
    @battle.pbDisplay(_INTL("¡{1} se ha convertido en el centro de atención!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Durante 5 rondas, incrementa la gravedad en el campo.
# Los Pokémon no pueden mantenerse en el aire.
# (Gravedad/Gravity)
################################################################################
class PokeBattle_Move_118 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::Gravity]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::Gravity]=5
    for i in 0...4
      poke=@battle.battlers[i]
      next if !poke
      if PBMoveData.new(poke.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Fly
         PBMoveData.new(poke.effects[PBEffects::TwoTurnAttack]).function==0xCC || # Bounce
         PBMoveData.new(poke.effects[PBEffects::TwoTurnAttack]).function==0xCE    # Sky Drop
        poke.effects[PBEffects::TwoTurnAttack]=0
      end
      if poke.effects[PBEffects::SkyDrop]
        poke.effects[PBEffects::SkyDrop]=false
      end
      if poke.effects[PBEffects::MagnetRise]>0
        poke.effects[PBEffects::MagnetRise]=0
      end
      if poke.effects[PBEffects::Telekinesis]>0
        poke.effects[PBEffects::Telekinesis]=0
      end
    end
    @battle.pbDisplay(_INTL("¡Se ha incrementado la Gravedad!"))
    return 0
  end
end



################################################################################
# Durante 5 rondas, el usuario se mantiene en el aire.
# (Levitón/Magnet Rise)
################################################################################
class PokeBattle_Move_119 < PokeBattle_Move
  def unusableInGravity?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Ingrain] ||
       attacker.effects[PBEffects::SmackDown] ||
       attacker.effects[PBEffects::MagnetRise]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::MagnetRise]=5
    @battle.pbDisplay(_INTL("¡{1} levita por electromagnetismo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Durante 3 rondas, el objetivo es mantenido en el aire y puede ser golpeado siempre.
# (Telequinesis/Telekinesis)
################################################################################
class PokeBattle_Move_11A < PokeBattle_Move
  def unusableInGravity?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Ingrain] ||
       opponent.effects[PBEffects::SmackDown] ||
       opponent.effects[PBEffects::Telekinesis]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Telekinesis]=3
    @battle.pbDisplay(_INTL("¡{1} ha sido lanzado por los aires!",opponent.pbThis))
    return 0
  end
end




################################################################################
# Golpea a objetivos semi-invulnerables que esté en el aire.
# (Gancho Alto/Sky Uppercut)
################################################################################
class PokeBattle_Move_11B < PokeBattle_Move
# Controlado en pbSuccessCheck de Battler, ¡no editar!
end



################################################################################
# Mantiene en el suelo al objetivo mientras esté activo.
# (Antiaéreo, Mil Flechas / Smack Down, Thousand Arrows)
# (Controlado en pbSuccessCheck de Battler): Golpea a algunos objetivos semi-invulnerables.
################################################################################
class PokeBattle_Move_11C < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 ||   # Vuelo
       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC ||   # Bote
       PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCE ||   # Caída Libre
       opponent.effects[PBEffects::SkyDrop]
      return basedmg*2
    end
    return basedmg
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
       !opponent.effects[PBEffects::Roost]
      opponent.effects[PBEffects::SmackDown]=true
      showmsg=(opponent.pbHasType?(:FLYING) ||
               opponent.hasWorkingAbility(:LEVITATE))
      if PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Fly
         PBMoveData.new(opponent.effects[PBEffects::TwoTurnAttack]).function==0xCC    # Bounce
        opponent.effects[PBEffects::TwoTurnAttack]=0; showmsg=true
      end
      if opponent.effects[PBEffects::MagnetRise]>0
        opponent.effects[PBEffects::MagnetRise]=0; showmsg=true
      end
      if opponent.effects[PBEffects::Telekinesis]>0
        opponent.effects[PBEffects::Telekinesis]=0; showmsg=true
      end
      @battle.pbDisplay(_INTL("¡{1} ha sido derribado y sufre daño!",opponent.pbThis)) if showmsg
    end
    return ret
  end
end



################################################################################
# El objetivo se mueve inmediatamente después del usuario, ignorando prioridad y velocidad.
# (Cede Paso/After You)
################################################################################
class PokeBattle_Move_11D < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return true if opponent.effects[PBEffects::MoveNext]
    return true if @battle.choices[opponent.index][0]!=1    # No ha elegido un movimiento
    oppmove=@battle.choices[opponent.index][2]
    return true if !oppmove || oppmove.id<=0
    return true if opponent.hasMovedThisRound?
    return false
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::MoveNext]=true
    opponent.effects[PBEffects::Quash]=false
    @battle.pbDisplay(_INTL("¡{2} decidió aprovechar la oportunidad que le dió {1}!",attacker.pbThis,opponent.pbThis))
    return 0
  end
end



################################################################################
# El objetivo se mueve último esta ronda, ignorando prioridad y velocidad.
# (Último Lugar/Quash)
################################################################################
class PokeBattle_Move_11E < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return true if opponent.effects[PBEffects::Quash]
    return true if @battle.choices[opponent.index][0]!=1 # Didn't choose a move
    oppmove=@battle.choices[opponent.index][2]
    return true if !oppmove || oppmove.id<=0
    return true if opponent.hasMovedThisRound?
    return false
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Quash]=true
    opponent.effects[PBEffects::MoveNext]=false
    @battle.pbDisplay(_INTL("¡{1} retrasó su turno!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Durante 5 rondas, por cada soporte de prioridad, los combatientes más lentos
# se mueven antes que los más rápidos.
# (Espacio Raro/Trick Room)
################################################################################
class PokeBattle_Move_11F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::TrickRoom]>0
      @battle.field.effects[PBEffects::TrickRoom]=0
      @battle.pbDisplay(_INTL("¡{1} alteró las dimensiones!",attacker.pbThis))
    else
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      @battle.field.effects[PBEffects::TrickRoom]=5
      @battle.pbDisplay(_INTL("¡{1} alteró las dimensiones!",attacker.pbThis))
    end
    return 0
  end
end



################################################################################
# El usuario intercambia la posición con un aliado.
# (Cambio Banda/Ally Switch)
################################################################################
class PokeBattle_Move_120 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle ||
       !attacker.pbPartner || attacker.pbPartner.isFainted?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    a=@battle.battlers[attacker.index]
    b=@battle.battlers[attacker.pbPartner.index]
    temp=a; a=b; b=temp
    # Swap effects that point at the position rather than the Pokémon
    # NOT PerishSongUser (no need to swap), Attract, MultiTurnUser
    effectstoswap=[PBEffects::BideTarget,
                   PBEffects::CounterTarget,
                   PBEffects::LeechSeed,
                   PBEffects::LockOnPos,
                   PBEffects::MeanLook,
                   PBEffects::MirrorCoatTarget]
    for i in effectstoswap
      a.effects[i],b.effects[i]=b.effects[i],a.effects[i]
    end
    a.pbUpdate(true)
    b.pbUpdate(true)
    @battle.pbDisplay(_INTL("¡{1} y {2} han intercambiado posiciones!",b.pbThis,a.pbThis(true)))
  end
end



################################################################################
# En los cálculos de este movimiento se utiliza el Ataque del objetivo en lugar
# del Ataque del usuario.
# (Juego Sucio/Foul Play)
################################################################################
class PokeBattle_Move_121 < PokeBattle_Move
# Controlado en superclass def pbCalcDamage, ¡no editar!
end



################################################################################
# En los cálculos de este movimiento se utiliza la Defensa del objetivo en lugar
# de la Defensa Especial.
# (Psicocarga, Onda Mental, Sablemístico / Psyshock, Psystrike, Secret Sword)
################################################################################
class PokeBattle_Move_122 < PokeBattle_Move
# Controlado en superclass def pbCalcDamage, ¡no editar!
end



################################################################################
# Solamente daña a objetivos que comparte algún tipo con el usuario.
# (Sincrorruido/Synchronoise)
################################################################################
class PokeBattle_Move_123 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbHasType?(attacker.type1) &&
       !opponent.pbHasType?(attacker.type2) &&
       !opponent.pbHasType?(attacker.effects[PBEffects::Type3])
      @battle.pbDisplay(_INTL("¡{1} no se vió afectado!",opponent.pbThis))
      return -1
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end



################################################################################
# Durante 5 rondas, intercambia la Defensa base con la Defensa Especial base
# de todos los combatientes.
# (Zona Extraña/Wonder Room)
################################################################################
class PokeBattle_Move_124 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::WonderRoom]>0
      @battle.field.effects[PBEffects::WonderRoom]=0
      @battle.pbDisplay(_INTL("Wonder Room wore off, and the Defense and Sp. Def stats returned to normal!"))
    else
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      @battle.field.effects[PBEffects::WonderRoom]=5
      @battle.pbDisplay(_INTL("It created a bizarre area in which the Defense and Sp. Def stats are swapped!"))
    end
    return 0
  end
end



################################################################################
# Falla salvo que el usuario ya haya utilizado todos los demás movimientos que conoce.
# (Última Baza/Last Resort)
################################################################################
class PokeBattle_Move_125 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    counter=0; nummoves=0
    for move in attacker.moves
      next if move.id<=0
      counter+=1 if move.id!=@id && !attacker.movesUsed.include?(move.id)
      nummoves+=1
    end
    return counter!=0 || nummoves==1
  end
end



#===============================================================================
# NOTA: Los movimientos oscuros usan los códigos de función 126-132 inclusivos.
#===============================================================================



################################################################################
# No hace nada en absoluto.
# (Manos Juntas/Hold Hands)
################################################################################
class PokeBattle_Move_133 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle ||
       !attacker.pbPartner || attacker.pbPartner.isFainted?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    return 0
  end
end



################################################################################
# No hace nada en absoluto. Muestra un mensaje especial.
# (Celebración/Celebrate)
################################################################################
class PokeBattle_Move_134 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡Felicidades, {1}!",$Trainer.name))
    return 0
  end
end



################################################################################
# Enfría súbitamente al objetivo e incluso puede congelarlo.
# (Liofilización/Freeze-Dry)
# (Superclass's pbTypeModifier): La efectividad contra el tipo Agua es x2.
################################################################################
class PokeBattle_Move_135 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanFreeze?(attacker,false,self)
      opponent.pbFreeze
    end
  end
end



################################################################################
# Incrementa la Defensa del usuario en 1 nivel por cada objetivo golpeado.
# (Torm. Diamantes/Diamond Storm)
################################################################################
class PokeBattle_Move_136 < PokeBattle_Move_01D
# No tiene diferencias con el código de función 01D.
# En el futuro, podría ser necesario separarlos.
end



################################################################################
# Incrementa la Defensa y Defensa Especial del usuario y de los compañeros que
# tengan las habilidades Más o Menos.
# (Aura Magnética/Magnetic Flux)
################################################################################
class PokeBattle_Move_137 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    didsomething=false
    for i in [attacker,attacker.pbPartner]
      next if !i || i.isFainted?
      next if !i.hasWorkingAbility(:PLUS) && !i.hasWorkingAbility(:MINUS)
      next if !i.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self) &&
              !i.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      if i.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
        i.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
      if i.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
        i.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    if !didsomething
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end
end



################################################################################
# Incrementa la Defensa Especial de los compañeros en 1 nivel.
# (Niebla Aromática/Aromatic Mist)
################################################################################
class PokeBattle_Move_138 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle || !opponent ||
       !opponent.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self)
    return ret ? 0 : -1
  end
end



################################################################################
# Decreases the target's Attack by 1 stage. Always hits.
# (Camaradería/Play Nice)
################################################################################
class PokeBattle_Move_139 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self)
    return ret ? 0 : -1
  end
end



################################################################################
# Reduce el Ataque y Ataque Especial del objetivo en 1 nivel cada uno.
# (Rugido de Guerra/Noble Roar)
################################################################################
class PokeBattle_Move_13A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    # Replicates def pbCanReduceStatStage? so that certain messages aren't shown
    # multiple times
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Falló el ataque de {1}!",attacker.pbThis))
      return -1
    end
    if opponent.pbTooLow?(PBStats::ATTACK) &&
       opponent.pbTooLow?(PBStats::SPATK)
      @battle.pbDisplay(_INTL("¡Las características de {1} no bajarán más!",opponent.pbThis))
      return -1
    end
    if opponent.pbOwnSide.effects[PBEffects::Mist]>0
      @battle.pbDisplay(_INTL("¡{1} se ha protegido con Neblina!",opponent.pbThis))
      return -1
    end
    if opponent.hasWorkingAbility(:FULLMETALBODY)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita que bajen las características!",opponent.pbThis,
           PBAbilities.getName(opponent.ability)))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:CLEARBODY) ||
         opponent.hasWorkingAbility(:WHITESMOKE) ||
         opponent.hasWorkingItem(:CLEARAMULET)
        @battle.pbDisplay(_INTL("¡{2} de {1} evita que bajen las características!",opponent.pbThis,
           PBAbilities.getName(opponent.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true
    if !attacker.hasMoldBreaker && opponent.hasWorkingAbility(:HYPERCUTTER)
      abilityname=PBAbilities.getName(opponent.ability)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita que baje el Ataque!",opponent.pbThis,abilityname))
    elsif opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      ret=0; showanim=false
    end
    if opponent.pbReduceStat(PBStats::SPATK,1,attacker,false,self,showanim)
      ret=0; showanim=false
    end
    return ret
  end
end



################################################################################
# Reduce la Defensa del objetivo en 1 nivel. Golpea siempre.
# (Cerco Dimensión/Hyperspace Fury)
################################################################################
class PokeBattle_Move_13B < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return true if !isConst?(attacker.species,PBSpecies,:HOOPA)
    return true if attacker.form!=1
    return false
  end

  def pbAccuracyCheck(attacker,opponent)
    return true
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self)
    end
  end
end



################################################################################
# Reduce el Ataque Especial del objetivo en 1 nivel. Golpea siempre.
# (Confidencia/Confide)
################################################################################
class PokeBattle_Move_13C < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::SPATK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::SPATK,1,attacker,false,self)
    return ret ? 0 : -1
  end
end



################################################################################
# Incrementa el Ataque y Ataque Especialde todos los Pokémon de tipo Planta
# en el terreno de combate en 1 nivel cada uno.
# No afecta a los Pokémon que están en el aire.
# (Fertilizante/Rototiller)
################################################################################
class PokeBattle_Move_13E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    didsomething=false
    for i in [attacker,attacker.pbPartner,attacker.pbOpposing1,attacker.pbOpposing2]
      next if !i || i.isFainted?
      next if !i.pbHasType?(:GRASS)
      next if i.isAirborne?(attacker.hasMoldBreaker)
      next if !i.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
              !i.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      if i.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        i.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
      if i.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        i.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    if !didsomething
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end
end



################################################################################
# Incrementa la Defensa de todos los Pokémon de tipo Planta en el terreno
# de combate en 1 nivel cada uno.
# (Defensa Floral/Flower Shield)
################################################################################
class PokeBattle_Move_13F < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    didsomething=false
    for i in [attacker,attacker.pbPartner,attacker.pbOpposing1,attacker.pbOpposing2]
      next if !i || i.isFainted?
      next if !i.pbHasType?(:GRASS)
      next if !i.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      if i.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
        i.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    if !didsomething
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end
end



################################################################################
# Reduce el Ataque, Ataque Especial y la Velocidad de todos los rivales
# envenenados en 1 nivel cada uno.
# (Trampa Venenosa/Venom Drench)
################################################################################
class PokeBattle_Move_140 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.status!=PBStatuses::POISON
      @battle.pbDisplay(_INTL("¡{1} no se vio afectado!",opponent.pbThis))
      return -1
    end
    if opponent.effects[PBEffects::Substitute]>0
      @battle.pbDisplay(_INTL("¡Pero falló!",attacker.pbThis))
      return -1
    end
    if opponent.pbTooLow?(PBStats::ATTACK) &&
       opponent.pbTooLow?(PBStats::SPATK) &&
       opponent.pbTooLow?(PBStats::SPEED)
      @battle.pbDisplay(_INTL("¡Las características de {1} no bajarán más!",opponent.pbThis))
      return -1
    end
    if opponent.pbOwnSide.effects[PBEffects::Mist]>0
      @battle.pbDisplay(_INTL("¡{1} se ha protegido con Neblina!",opponent.pbThis))
      return -1
    end

    if opponent.hasWorkingAbility(:FULLMETALBODY)
      @battle.pbDisplay(_INTL("¡{2} de {1} evita que bajen las características!",opponent.pbThis,
           PBAbilities.getName(opponent.ability)))
      return -1
    end
    if !attacker.hasMoldBreaker
      if opponent.hasWorkingAbility(:CLEARBODY) ||
         opponent.hasWorkingAbility(:WHITESMOKE)
        @battle.pbDisplay(_INTL("¡{2} de {1} evita que bajen las características!",opponent.pbThis,
           PBAbilities.getName(opponent.ability)))
        return -1
      end
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=-1; showanim=true
    if opponent.pbReduceStat(PBStats::ATTACK,1,false,showanim)
      ret=0; showanim=false
    end
    if opponent.pbReduceStat(PBStats::SPATK,1,false,showanim)
      ret=0; showanim=false
    end
    if opponent.pbReduceStat(PBStats::SPEED,1,false,showanim)
      ret=0; showanim=false
    end
    return ret
  end
end



################################################################################
# Invierte por completo los cambios en las características del Pokémon objetivo.
# (Reversión/Topsy-Turvy)
################################################################################
class PokeBattle_Move_141 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    nonzero=false
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      if opponent.stages[i]!=0
        nonzero=true; break
      end
    end
    if !nonzero
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)# if !didsomething
    for i in [PBStats::ATTACK,PBStats::DEFENSE,PBStats::SPEED,
              PBStats::SPATK,PBStats::SPDEF,PBStats::ACCURACY,PBStats::EVASION]
      opponent.stages[i]*=-1
    end
    @battle.pbDisplay(_INTL("¡Se han invertido las estadísticas de {1}!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Agrega al objetivo el tipo Fantasma.
# (Halloween/Trick-or-Treat)
################################################################################
class PokeBattle_Move_142 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)) ||
       !hasConst?(PBTypes,:GHOST) || opponent.pbHasType?(:GHOST) ||
       isConst?(opponent.ability,PBAbilities,:MULTITYPE)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Type3]=getConst(PBTypes,:GHOST)
    typename=PBTypes.getName(getConst(PBTypes,:GHOST))
    @battle.pbDisplay(_INTL("¡{1} ha sido transformado en tipo {2}!",opponent.pbThis,typename))
    return 0
  end
end



################################################################################
# Agrega al objetivo el tipo Planta.
# (Condena Silvana/Forest's Curse)
################################################################################
class PokeBattle_Move_143 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    if opponent.effects[PBEffects::LeechSeed]>=0
      @battle.pbDisplay(_INTL("¡{1} esquivó el ataque!",opponent.pbThis))
      return -1
    end
    if !hasConst?(PBTypes,:GRASS) || opponent.pbHasType?(:GRASS) ||
       isConst?(opponent.ability,PBAbilities,:MULTITYPE)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Type3]=getConst(PBTypes,:GRASS)
    typename=PBTypes.getName(getConst(PBTypes,:GRASS))
    @battle.pbDisplay(_INTL("¡{1} ha sido transformado en tipo {2}!",opponent.pbThis,typename))
    return 0
  end
end



################################################################################
# El daño es multiplicado por la efectividad del tipo Volador contra el objetivo.
# Hace el doble de daño y tiene precisión perfecta si el objetivo ha usado Reducción.
# (Plancha Voladora/Flying Press)
################################################################################
class PokeBattle_Move_144 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    type=getConst(PBTypes,:FLYING) || -1
    if type>=0
      mult=PBTypes.getCombinedEffectiveness(type,
         opponent.type1,opponent.type2,opponent.effects[PBEffects::Type3])
      return ((damagemult*mult)/8).round
    end
    return damagemult
  end

  def tramplesMinimize?(param=1)
    return true if param==1 && USENEWBATTLEMECHANICS # Perfect accuracy
    return true if param==2 # Double damage
    return false
  end
end



################################################################################
# Los movimientos del objetivo se vuelven de tipo Eléctrico por el resto de la ronda.
# (Electrificación/Electrify)
################################################################################
class PokeBattle_Move_145 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if pbTypeImmunityByAbility(pbType(@type,attacker,opponent),attacker,opponent)
    if opponent.effects[PBEffects::Electrify]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if @battle.choices[opponent.index][0]!=1 ||     # No ha elegido un movimiento
       !@battle.choices[opponent.index][2] ||
       @battle.choices[opponent.index][2].id<=0 ||
       opponent.hasMovedThisRound?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::Electrify]=true
    @battle.pbDisplay(_INTL("¡{1} ha sido electrificado!",opponent.pbThis))
    return 0
  end
end



################################################################################
# Todos los movimientos de tipo Normal se vuelven Eléctricos por el resto de la ronda.
# (Cortina Plasma/Ion Deluge)
################################################################################
class PokeBattle_Move_146 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 && # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved || @battle.field.effects[PBEffects::IonDeluge]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::IonDeluge]=true
    @battle.pbDisplay(_INTL("¡Una lluvia de electrones cae sobre el terreno de combate!"))
    return 0
  end
end



################################################################################
# Golpea siempre. (Paso Dimensional/Hyperspace Hole)
# TODO: Golpea a través de varias barreras.
################################################################################
class PokeBattle_Move_147 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end
end


################################################################################
# Cubre de polvo al enemigo. Durante esta ronda, si el objetivo utiliza un
# movimiento de tipo Fuego, perderá 1/4 de sus PS máximos.
# (Polvo Explosivo/Powder)
################################################################################
class PokeBattle_Move_148 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Powder]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    opponent.effects[PBEffects::Powder]=true
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡{1} ha sido cubierto con polvo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# Esta ronda, el equipo del usuario es inmune a movimientos de daño.
# (Escudo Tatami/Mat Block)
################################################################################
class PokeBattle_Move_149 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return (attacker.turncount>1)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.pbOwnSide.effects[PBEffects::MatBlock]=true
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡{1} va a usar un tatami para bloquear ataques!",attacker.pbThis))
    return 0
  end
end



################################################################################
# User's side is protected against status moves this round.
# (Truco Defensa/Crafty Shield)
################################################################################
class PokeBattle_Move_14A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&              # Escoge un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::CraftyShield]=true
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡El Truco Defensa ha protegido a tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡El Truco Defensa ha protegido al equipo rival!"))
    end
    return 0
  end
end



################################################################################
# El usuario se protege contra movimientos de daño esta ronda.
# Reduce el Ataque del usuario de un movimiento de contacto en 2 niveles.
# (Escudo Real/King's Shield)
################################################################################
class PokeBattle_Move_14B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::KingsShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::KingsShield]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end



################################################################################
# El usuario se protege de movimientos que lo tienen como objetivo esta ronda.
# Causa daño al usuario de un movimiento de contacto por 1/8 de sus PS máximos.
# (Barrera Espinosa/Spiky Shield)
################################################################################
class PokeBattle_Move_14C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::SpikyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::SpikyShield]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end


################################################################################
# Movimiento de dos turnos. Salta el primer turno. En el segundo, se incrementan
# el Ataque Especial, Defensa Especial y Velocidad del usuario en 2 niveles cada uno.
################################################################################
class PokeBattle_Move_14E < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} está absorbiendo energía!",attacker.pbThis))
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,2,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,2,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,2,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end



################################################################################
# El usuario gana 3/4 de los PS inflingidos como daño al objetivo.
# (Beso Drenaje, Ala Mortífera / Draining Kiss, Oblivion Wing)
################################################################################
class PokeBattle_Move_14F < PokeBattle_Move
  def isHealingMove?
    return USENEWBATTLEMECHANICS
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=(opponent.damagestate.hplost*3/4).round
      if opponent.hasWorkingAbility(:LIQUIDOOZE)
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} ha absorbido el lodo líquido!",attacker.pbThis))
      elsif attacker.effects[PBEffects::HealBlock]==0
        hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡La energía de {1} ha sido absorbida!",opponent.pbThis))
      end
    end
    return ret
  end
end



################################################################################
# Si el objetivo es debilitado con este movimiento, se incrementa el Ataque del
# usuario en 2 niveles.
# (Aguijón Letal/Fell Stinger)
################################################################################
class PokeBattle_Move_150 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && opponent.isFainted?
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::ATTACK,2,attacker,false,self)
      end
    end
    return ret
  end
end



################################################################################
# Reduce el Ataque y Ataque Especial del objetivo en 1 nivel cada uno.
# Luego, el usuario es cambiado. Ignora movimientos de trampa.
# (Última Palabra/Parting Shot)
# TODO: Persecución debería interrumpir este movimiento.
################################################################################
class PokeBattle_Move_151 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=-1
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    if !self.isSoundBased? ||
       attacker.hasMoldBreaker || !opponent.hasWorkingAbility(:SOUNDPROOF)
      showanim=true
      if opponent.pbReduceStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false; ret=0
      end
      if opponent.pbReduceStat(PBStats::SPATK,1,attacker,false,self,showanim)
        showanim=false; ret=0
      end
    end
    if !attacker.isFainted? &&
       @battle.pbCanChooseNonActive?(attacker.index) &&
       !@battle.pbAllFainted?(@battle.pbParty(opponent.index))
      attacker.effects[PBEffects::Uturn]=true; ret=0
    end
    return ret
  end
end



################################################################################
# Ningún Pokémon puede se cambiado o huir hasta el final de la siguiente ronda,
# mientras que el usuario se mantenga activo.
# (Cerrojo Feérico/Fairy Lock)
################################################################################
class PokeBattle_Move_152 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::FairyLock]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::FairyLock]=2
    @battle.pbDisplay(_INTL("¡Nadie podrá huir durante el próximo turno!"))
    return 0
  end
end



################################################################################
# Obstáculo de entrada. Coloca una red pegajosa en el campo rival que reduce
# la Velocidad de los Pokémon.
# (Red Viscosa/Sticky Web)
################################################################################
class PokeBattle_Move_153 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[PBEffects::StickyWeb]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbOpposingSide.effects[PBEffects::StickyWeb]=true
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Una red viscosa se extiende a los pies del equipo rival!"))
    else
      @battle.pbDisplay(_INTL("¡Una red viscosa se extiende a los pies de tu equipo!"))
    end
    return 0
  end
end



################################################################################
# For 5 rounds, creates an electric terrain which boosts Electric-type moves and
# prevents Pokémon from falling asleep. Affects non-airborne Pokémon only.
# (Electric Terrain)
################################################################################
class PokeBattle_Move_154 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::GrassyTerrain]=0
    @battle.field.effects[PBEffects::MistyTerrain]=0
    @battle.field.effects[PBEffects::PsychicTerrain]=0
    if attacker.hasWorkingItem(:TERRAINEXTENDER)
      @battle.field.effects[PBEffects::ElectricTerrain]=8
    else
      @battle.field.effects[PBEffects::ElectricTerrain]=5
    end
    @battle.pbDisplay(_INTL("¡Se ha formado un campo de corriente eléctrica en el campo de batalla!"))
    for battler in @battle.battlers
      next if battler.isFainted?
      if battler.hasWorkingAbility(:MIMICRY)
         battler.pbActivateMimicry
      end
    end
    return 0
  end
end



################################################################################
# For 5 rounds, creates a grassy terrain which boosts Grass-type moves and heals
# Pokémon at the end of each round. Affects non-airborne Pokémon only.
# (Grassy Terrain)
################################################################################
class PokeBattle_Move_155 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::GrassyTerrain]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::ElectricTerrain]=0
    @battle.field.effects[PBEffects::MistyTerrain]=0
    @battle.field.effects[PBEffects::PsychicTerrain]=0
    if attacker.hasWorkingItem(:TERRAINEXTENDER)
      @battle.field.effects[PBEffects::GrassyTerrain]=8
    else
      @battle.field.effects[PBEffects::GrassyTerrain]=5
    end
    @battle.pbDisplay(_INTL("¡El terreno de combate se ha cubierto de hierba!"))
    for battler in @battle.battlers
      next if battler.isFainted?
      if battler.hasWorkingAbility(:MIMICRY)
         battler.pbActivateMimicry
      end
    end
    return 0
  end
end


################################################################################
# For 5 rounds, creates a misty terrain which weakens Dragon-type moves and
# protects Pokémon from status problems. Affects non-airborne Pokémon only.
# (Misty Terrain)
################################################################################
class PokeBattle_Move_156 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::MistyTerrain]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::ElectricTerrain]=0
    @battle.field.effects[PBEffects::GrassyTerrain]=0
    @battle.field.effects[PBEffects::PsychicTerrain]=0
    if attacker.hasWorkingItem(:TERRAINEXTENDER)
      @battle.field.effects[PBEffects::MistyTerrain]=8
    else
      @battle.field.effects[PBEffects::MistyTerrain]=5
    end
    @battle.pbDisplay(_INTL("¡La niebla ha envuelto el terreno de combate!"))
    for battler in @battle.battlers
      next if battler.isFainted?
      if battler.hasWorkingAbility(:MIMICRY)
         battler.pbActivateMimicry
      end
    end
    return 0
  end
end


################################################################################
# For 5 rounds, creates a psychic terrain which boosts Psychic-type moves and
# protects Pokémon from priority moves. Affects non-airborne Pokémon only.
# (Psychic Terrain)
################################################################################
class PokeBattle_Move_159 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::PsychicTerrain]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.field.effects[PBEffects::ElectricTerrain]=0
    @battle.field.effects[PBEffects::MistyTerrain]=0
    @battle.field.effects[PBEffects::GrassyTerrain]=0
    if attacker.hasWorkingItem(:TERRAINEXTENDER)
      @battle.field.effects[PBEffects::PsychicTerrain]=8
    else
      @battle.field.effects[PBEffects::PsychicTerrain]=5
    end
    @battle.pbDisplay(_INTL("¡El campo de batalla se volvió extraño!"))
    for battler in @battle.battlers
      next if battler.isFainted?
      if battler.hasWorkingAbility(:MIMICRY)
         battler.pbActivateMimicry
      end
    end
    return 0
  end
end

################################################################################
# Duplica el dinero que obtiene el jugador tras ganar el combate.
# (Paga Extra/Happy Hour)
################################################################################
class PokeBattle_Move_157 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.pbIsOpposing?(attacker.index) || @battle.doublemoney
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.doublemoney=true
    @battle.pbDisplay(_INTL("¡La felicidad se respira en el aire!"))
    return 0
  end
end



################################################################################
# Fallará salvo que el usuario haya consumido una baya en algún momento.
# (Eructo/Belch)
################################################################################
class PokeBattle_Move_158 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return !attacker.pokemon || !attacker.pokemon.belch
  end
end


################################################################################
# For 5 rounds, lowers power of physical and special attacks against the user's
# Side. (Aurora Veil)
################################################################################
class PokeBattle_Move_CF6 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if @battle.pbWeather!=PBWeather::HAIL
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbOwnSide.effects[PBEffects::AuroraVeil]=5
    attacker.pbOwnSide.effects[PBEffects::AuroraVeil]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
    if !@battle.pbIsOpposing?(attacker.index)
      @battle.pbDisplay(_INTL("¡Velo Aurora subió la Defensa y la Defensa Especial de tu equipo!"))
    else
      @battle.pbDisplay(_INTL("¡Velo Aurora subió la Defensa y la Defensa Especial del equipo enemigo!"))
    end
    return 0
  end
end

################################################################################
# Deals damage and makes the target unable to switch out. (Spirit Shackle)
################################################################################
class PokeBattle_Move_CF11 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbIsDamaging?
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
         !opponent.isFainted?
        if opponent.effects[PBEffects::MeanLook]<0
          opponent.effects[PBEffects::MeanLook]=attacker.index
          @battle.pbDisplay(_INTL("¡{1} no puede escapar!",opponent.pbThis))
        end
      end
      return ret
    end
  end
end

################################################################################
# User and target swap their Speed stats. (Speed Swap)
################################################################################
class PokeBattle_Move_CF10 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.speed,opponent.speed=opponent.speed,attacker.speed
    @battle.pbDisplay(_INTL("¡{1} y {2} intercambiaron su Velocidad!",attacker.pbThis,opponent.pbThis))
    return 0
  end
end

################################################################################
# Raises the Attack and Special Attack of an ally. (Gear Up)
################################################################################
class PokeBattle_Move_CF12 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    didsomething=false
    for i in [attacker,attacker.pbPartner]
      next if !i || i.isFainted?
      next if !i.hasWorkingAbility(:PLUS) && !i.hasWorkingAbility(:MINUS)
      next if !i.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
              !i.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      if i.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        i.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
      if i.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        i.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    if !didsomething
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end
end

################################################################################
# Heals the target's Status condition and heals the user by 50%. (Purify)
################################################################################
class PokeBattle_Move_CF3 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=false)
    if opponent.status!=PBStatuses::BURN &&
       opponent.status!=PBStatuses::POISON &&
       opponent.status!=PBStatuses::PARALYSIS &&
       opponent.status!=PBStatuses::SLEEP &&
       opponent.status!=PBStatuses::FROZEN
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    else
      t=opponent.status
      opponent.pbCureStatus(false)
      if t==PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡Purificación de {1} curó la quemadura de {2}!",attacker.pbThis,opponent.pbThis))
      elsif t==PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡Purificación de {1} curó el envenenamiento de {2}!",attacker.pbThis,opponent.pbThis))
      elsif t==PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡Purificación de {1} curó la parálisis de {2}!",attacker.pbThis,opponent.pbThis))
      elsif t==PBStatuses::SLEEP
        @battle.pbDisplay(_INTL("¡Purificación de {1} despertó a {2}!",attacker.pbThis,opponent.pbThis))
      elsif t==PBStatuses::FROZEN
        @battle.pbDisplay(_INTL("¡Purificación de {1} descongeló a {2}!",attacker.pbThis,opponent.pbThis))
      end
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      attacker.pbRecoverHP(((attacker.totalhp+1)/2).floor,true)
      @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
      return 0
    end
  end
end

################################################################################
# Heals user by an amount depending on the weather. (Shore Up)
################################################################################
class PokeBattle_Move_CF5 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡{1} tiene su salud al máximo!",attacker.pbThis))
      return -1
    end
    hpgain=0
    if @battle.pbWeather==PBWeather::SANDSTORM
      hpgain=(attacker.totalhp*2/3).floor
    else
      hpgain=(attacker.totalhp/2).floor
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
    return 0
  end
end

################################################################################
# Inflicts damage to the target. If the target is burned, the burn is healed.
# (Sparkling Aria)
################################################################################
class PokeBattle_Move_CF8 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !opponent.isFainted? && opponent.damagestate.calcdamage>0 &&
      !opponent.damagestate.substitute && opponent.status==PBStatuses::BURN
      opponent.pbCureStatus
    end
  end
end

################################################################################
# If the target is an ally, heals the target for the amount of damage that would
# have been dealt.  If target is an opponent, damages them normally. (Pollen Puff)
################################################################################
class PokeBattle_Move_CF19 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbPartner != nil
      if attacker.pbPartner == opponent
        damage=pbCalcDamage(attacker,opponent)
        opponent.pbRecoverHP(damage,true)
        return 0
      end
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Fails if this isn't the user's first turn. (First Impression)
################################################################################
class PokeBattle_Move_15A < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return (attacker.turncount>1)
  end
end


################################################################################
# Heals the user for an amount equal to the target's effective Attack stat
# Lowers the target's Attack by 1 stage. (Strength Sap)
################################################################################
class PokeBattle_Move_CF13 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::HealBlock]>0
      bob="heal"
      bob=_INTL("use {1}",name) if !opponent.pbCanReduceStatStage?(PBStats::ATTACK,true,false,attacker)
      @battle.pbDisplay(_INTL("¡{1} no puede {2} debido a Anticura!",attacker.pbThis,bob))
      return -1
    elsif attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡La salud de {1} está al máximo!",attacker.pbThis))
      return -1
    else
      oatk=opponent.attack
      attacker.pbRecoverHP(oatk,true)
      @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
      if opponent.pbCanReduceStatStage?(PBStats::ATTACK,opponent,false,self)
        opponent.pbReduceStat(PBStats::ATTACK,1,opponent,false,self)
      end
    end
    return 0
  end
end

################################################################################
# Heals user by an amount depending on the terrain. (Floral Healing)
################################################################################
class PokeBattle_Move_CF2 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡La salud de {1} está al máximo!",attacker.pbThis))
      return -1
    end
    hpgain=0
    if @battle.field.effects[PBEffects::GrassyTerrain]>0
      hpgain=(attacker.totalhp*2/3).floor
    else
      hpgain=(attacker.totalhp/2).floor
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(hpgain,true)
    @battle.pbDisplay(_INTL("{1} recuperó salud",attacker.pbThis))
    return 0
  end
end

################################################################################
# Lowers the target's Attack and Special Attack. Bypasses Accuracy. (Tearful Look)
################################################################################
class PokeBattle_Move_CF14 < PokeBattle_Move
  def pbAccuracyCheck(attacker,opponent)
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      showanim=true
      if opponent.pbCanReduceStatStage?(PBStats::ATTACK,opponent,false,self)
        opponent.pbReduceStat(PBStats::ATTACK,1,opponent,false,self,showanim)
        showanim=false
      end
      if opponent.pbCanReduceStatStage?(PBStats::SPATK,opponent,false,self)
        opponent.pbReduceStat(PBStats::SPATK,1,opponent,false,self,showanim)
        showanim=false
      end
    return ret
  end
end

################################################################################
# Copies the opponent's stat changes and then resets it. After this, it will
# Attack. (Spectral Thief)
################################################################################
class PokeBattle_Move_CF9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    @battle.pbDisplay(_INTL("¡{1} robó los cambios de características de {2}!",attacker.pbThis,opponent.pbThis(true)))
    if opponent.stages[PBStats::ATTACK]>0
      attacker.pbIncreaseStat(PBStats::ATTACK,opponent.stages[PBStats::ATTACK],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      opponent.stages[PBStats::ATTACK]=0
    end
    if opponent.stages[PBStats::DEFENSE]>0
      attacker.pbIncreaseStat(PBStats::DEFENSE,opponent.stages[PBStats::DEFENSE],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      opponent.stages[PBStats::DEFENSE]=0
    end
    if opponent.stages[PBStats::SPATK]>0
      attacker.pbIncreaseStat(PBStats::SPATK,opponent.stages[PBStats::SPATK],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      opponent.stages[PBStats::SPATK]=0
    end
    if opponent.stages[PBStats::SPDEF]>0
      attacker.pbIncreaseStat(PBStats::SPDEF,opponent.stages[PBStats::SPDEF],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      opponent.stages[PBStats::SPDEF]=0
    end
    if opponent.stages[PBStats::SPEED]>0
      attacker.pbIncreaseStat(PBStats::SPEED,opponent.stages[PBStats::SPEED],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      opponent.stages[PBStats::SPEED]=0
    end
    if opponent.stages[PBStats::ACCURACY]>0
      attacker.pbIncreaseStat(PBStats::ACCURACY,opponent.stages[PBStats::ACCURACY],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::ACCURACY,attacker,false,self)
      opponent.stages[PBStats::ACCURACY]=0
    end
    if opponent.stages[PBStats::EVASION]>0
      attacker.pbIncreaseStat(PBStats::EVASION,opponent.stages[PBStats::EVASION],attacker,false,self) if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,false,self)
      opponent.stages[PBStats::EVASION]=0
    end
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    return ret
  end
end

################################################################################
# Reduce la Defensa del usuario. (Clanging Scales)
################################################################################
class PokeBattle_Move_CF1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      showanim=true
      if attacker.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    return ret
  end
end

################################################################################
# Lo que haga Stomping Tantrum.
################################################################################
class PokeBattle_Move_CF22 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    return basedmg*2 if attacker.effects[PBEffects::LastMoveFailed]
    return basedmg
  end
end

################################################################################
# The user's next move will be a critical hit. (Laser Focus)
################################################################################
class PokeBattle_Move_19A < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[PBEffects::LaserFocus]=2
    @battle.pbDisplay(_INTL("¡{1} empezó a concentrarse!",attacker.pbThis))
    return 0
  end
end

################################################################################
# User is protected against damaging moves this round. Poisons the
# user of a stopped contact move. (Baneful Bunker)
################################################################################
class PokeBattle_Move_15B < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::BanefulBunker]
      @battle.pbDisplay(_INTL("¡Pero falló"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::BanefulBunker]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Lo que haga Throat Chop.
################################################################################
class PokeBattle_Move_CF15 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
        !opponent.isFainted?
      opponent.effects[PBEffects::ThroatChop]=2
      @battle.pbDisplay(_INTL("¡{1} no puede usar movimientos sonoros!",opponent.pbThis))
    end
    return ret
  end
end

################################################################################
# Lo que haga Spotlight.
################################################################################
class PokeBattle_Move_CF23 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !@battle.doublebattle
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,opponent,nil,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::FollowMe]=1
    if !opponent.pbPartner.isFainted? && opponent.pbPartner.effects[PBEffects::FollowMe]>0
      opponent.effects[PBEffects::FollowMe]=opponent.pbPartner.effects[PBEffects::FollowMe]+1
    end
    @battle.pbDisplay(_INTL("¡{1} se ha convertido en el centro de atención!",opponent.pbThis))
    return 0
  end
end

################################################################################
# Instructs the target to use the move it last used again. (Instruct)
################################################################################
class PokeBattle_Move_CF0 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.lastMoveUsed<=0 ||
       (PBMoveData.new(opponent.lastMoveUsed).flags&0x10)==0 # flag e: Copyable by Mirror Move
      @battle.pbDisplay(_INTL("¡El Mandato falló!"))
      return -1
    end
    opponent.pbUseMoveSimple(opponent.lastMoveUsed,-1,opponent.lastTarget)
    return 0
  end
end

################################################################################
# Move type changes based on user's primary type. (Revelation Dance)
################################################################################
class PokeBattle_Move_192 < PokeBattle_Move
  def pbType(type,attacker,opponent)
    return attacker.type1
  end
end

################################################################################
# All Normal-type moves become Electric-type for the rest of the round.
# (Plasma Fist)
################################################################################
class PokeBattle_Move_CF2 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if pbIsDamaging?
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      unmoved=false
      for poke in @battle.battlers
        next if poke.index==attacker.index
        if @battle.choices[poke.index][0]==1 && # Chose a move
           !poke.hasMovedThisRound?
          unmoved=true; break
        end
      end
      if !unmoved || @battle.field.effects[PBEffects::PlasmaFists]
        @battle.pbDisplay(_INTL("¡Una lluvia de electrones cae sobre el terreno de combate!"))
        return -1
      end
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation=false)
      @battle.field.effects[PBEffects::PlasmaFists]=true
      @battle.pbDisplay(_INTL("¡Una lluvia de electrones cae sobre el terreno de combate!"))
      return ret
    end
  end
end

################################################################################
# User takes recoil damage equal to 1/2 of the damage this move dealt.
# (Mind Blown)
################################################################################
class PokeBattle_Move_1CF < PokeBattle_Move
  def pbOnStartUse(attacker)
    if !attacker.hasMoldBreaker
      bearer=@battle.pbCheckGlobalAbility(:DAMP)
      if bearer!=nil
          @battle.pbDisplay(_INTL("¡{2} de {1} evitó que {3} utilice {4}!",
             bearer.pbThis,PBAbilities.getName(bearer.ability),attacker.pbThis(true),@name))
        return false
      end
    end
    return true
  end
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted?
      if !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((attacker.totalhp/2.0).round)
      end
    end
  end
end

################################################################################
# Shell Trap
################################################################################
class PokeBattle_Move_193 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return !attacker.effects[PBEffects::ShellTrap]
  end
end

################################################################################
# (handled elsewhere) If anyone makes contact with the Pokemon while they are
#    charging this move, they will be inflicted with a burn
################################################################################
class PokeBattle_Move_1BC < PokeBattle_Move
end

################################################################################
# Ignores foe's ignoring abilities. (Sunsteel Strike, Moongeist Beam)
################################################################################
class PokeBattle_Move_171 < PokeBattle_Move
  def doesBypassIgnorableAbilities?
    return true
  end
end

################################################################################
# Ignores foe's ignoring abilities. This move's category is Special, if Special
# Attack of the attacker is greater than its Attack, and Physical otherwise.
# (Photon Geyser)
################################################################################
class PokeBattle_Move_170 < PokeBattle_Move
  def doesBypassIgnorableAbilities?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.attack+attacker.stages[PBStats::ATTACK]>attacker.spatk+attacker.stages[PBStats::SPATK]
      @category=0
    else
      @category=1
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# El movimiento solo puede usarse si comparte tipo con el atacante, el cual lo
# pierde tras usar el ataque.
# Burn Up / Llama Final - Double Shock / Electropalmas
################################################################################
class PokeBattle_Move_1C9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    type=@type
    if !attacker.pbHasType?(type)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    return ret if attacker.isTera?
    if attacker.effects[PBEffects::Type3]==type
      attacker.effects[PBEffects::Type3]=-1
    end
    if attacker.type1==type && attacker.type2==type
      attacker.type1=getConst(PBTypes,:QMARKS)
      attacker.type2=getConst(PBTypes,:QMARKS)
    elsif attacker.type1==type
      attacker.type1=attacker.type2
    elsif attacker.type2==type
      attacker.type2=attacker.type1
    end
    if isConst?(@id,PBMoves,:BURNUP)
      @battle.pbDisplay(_INTL("¡{1} perdió el tipo Fuego!",attacker.pbThis))
    elsif isConst?(@id,PBMoves,:DOUBLESHOCK)
      @battle.pbDisplay(_INTL("¡{1} perdió el tipo Eléctrico!",attacker.pbThis))
    end
    return 0
  end
end

################################################################################
# Poisons the target (Toxic Thread)
# Decreases the target's Speed by 1 stage.
################################################################################
class PokeBattle_Move_1B9 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    speed=opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
    poison=opponent.pbCanPoison?(attacker,false,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation) if speed || poison
    ret=false
    ret=opponent.pbReduceStat(PBStats::SPEED,1,attacker,true,self) if speed
    ret|=poison
    opponent.pbPoison(attacker) if poison || attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
    @battle.pbDisplay(_INTL("¡Pero falló!")) if !ret
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
      opponent.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
    end
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker)
    end
  end
end

################################################################################
# Deals damage. If target has already moved, its ability will be supressed.
# (Core Enforcer)
################################################################################
class PokeBattle_Move_CF21 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if opponent.hasMovedThisRound?
      if opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker)
        return -1
      end
      if isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
         isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
         isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
         isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
         isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
         isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
         isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
         isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
         isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
         isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
         isConst?(opponent.ability,PBAbilities,:ZEROTOHERO) ||
         opponent.hasWorkingItem(:ABILITYSHIELD)
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=false)
      oldabil=opponent.ability
      opponent.effects[PBEffects::GastroAcid]=true
      opponent.effects[PBEffects::Truant]=false
      @battle.pbDisplay(_INTL("¡Se suprimió la habilidad de {1}!",opponent.pbThis))
      if opponent.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
        PBDebug.log("[Ability triggered] #{opponent.pbThis}'s Illusion ended")
        opponent.effects[PBEffects::Illusion]=nil
        @battle.scene.pbChangePokemon(opponent,opponent.pokemon)
        @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",opponent.pbThis,PBAbilities.getName(oldabil)))
      end
      return 0
    end
  end
end

################################################################################
# Hits twice. May cause the target to flinch. (Double Iron Bash)
################################################################################
class PokeBattle_Move_191 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    opponent.pbFlinch(attacker)
  end

  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 2
  end
end

################################################################################
# Increases the user's Speed by 1 stage. Fail if the user is not a Morpeko.
# If the user is a Morpeko-Hangry, this move will be Dark type. (Aura Wheel)
################################################################################
class PokeBattle_Move_174 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return !isConst?(attacker.species,PBSpecies,:MORPEKO)
  end

  def pbModifyType(type,attacker,opponent)
    type=getConst(PBTypes,:ELECTRIC) || 0
    if attacker.form!=0
      type=getConst(PBTypes,:DARK) || 0
    end
    return type
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
    end
  end
end

################################################################################
# If the user moves before the target, this move's power is doubled (Bolt Beak,
# Fishious Rend)
################################################################################
class PokeBattle_Move_176 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.choices[opponent.index][0]==1 && # Chose a move
       !opponent.hasMovedThisRound?
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Swaps barriers, veils and other effects between each side of the battlefield.
# (Court Change)
################################################################################
class PokeBattle_Move_178 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    changeside=false
    for i in 0...2
      next if @battle.sides[i].effects[PBEffects::Spikes]==0 &&
              @battle.sides[i].effects[PBEffects::ToxicSpikes]==0 &&
             !@battle.sides[i].effects[PBEffects::StealthRock] &&
             !@battle.sides[i].effects[PBEffects::StickyWeb] &&
              @battle.sides[i].effects[PBEffects::Reflect]==0 &&
              @battle.sides[i].effects[PBEffects::LightScreen]==0 &&
              @battle.sides[i].effects[PBEffects::AuroraVeil]==0 &&
              @battle.sides[i].effects[PBEffects::Tailwind]==0
      changeside=true
    end
    if !changeside
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    else
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      ownside=@battle.sides[0]; oppside=@battle.sides[1]
      ownside.effects[PBEffects::Spikes]=oppside.effects[PBEffects::Spikes]
      oppside.effects[PBEffects::Spikes]=ownside.effects[PBEffects::Spikes]
      ownside.effects[PBEffects::ToxicSpikes]=oppside.effects[PBEffects::ToxicSpikes]
      oppside.effects[PBEffects::ToxicSpikes]=ownside.effects[PBEffects::ToxicSpikes]
      ownside.effects[PBEffects::StealthRock]=oppside.effects[PBEffects::StealthRock]
      oppside.effects[PBEffects::StealthRock]=ownside.effects[PBEffects::StealthRock]
      ownside.effects[PBEffects::StickyWeb]=oppside.effects[PBEffects::StickyWeb]
      oppside.effects[PBEffects::StickyWeb]=ownside.effects[PBEffects::StickyWeb]
      ownside.effects[PBEffects::Reflect]=oppside.effects[PBEffects::Reflect]
      oppside.effects[PBEffects::Reflect]=ownside.effects[PBEffects::Reflect]
      ownside.effects[PBEffects::LightScreen]=oppside.effects[PBEffects::LightScreen]
      oppside.effects[PBEffects::LightScreen]=ownside.effects[PBEffects::LightScreen]
      ownside.effects[PBEffects::AuroraVeil]=oppside.effects[PBEffects::AuroraVeil]
      oppside.effects[PBEffects::AuroraVeil]=ownside.effects[PBEffects::AuroraVeil]
      ownside.effects[PBEffects::Tailwind]=oppside.effects[PBEffects::Tailwind]
      oppside.effects[PBEffects::Tailwind]=ownside.effects[PBEffects::Tailwind]
      @battle.pbDisplay(_INTL("¡{1} intercambió los efectos de cada lado del campo!",attacker.pbThis))
      return 0
    end
  end
end

################################################################################
# User is protected against damaging moves this round. Decreases the Defense of
# the user of a stopped contact move by 2 stages. (Obstruct)
################################################################################
class PokeBattle_Move_184 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Obstruct]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Obstruct]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Prevents both the user and the target from escaping. (Jaw Lock)
################################################################################
class PokeBattle_Move_181 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if (opponent.effects[PBEffects::JawLockUser]<0 && !opponent.effects[PBEffects::JawLock] &&
        attacker.effects[PBEffects::JawLockUser]<0 && !attacker.effects[PBEffects::JawLock])
      opponent.effects[PBEffects::JawLockUser]=attacker.index
      attacker.effects[PBEffects::JawLockUser]=attacker.index
      opponent.effects[PBEffects::JawLock]=true
      attacker.effects[PBEffects::JawLock]=true
      @battle.pbDisplay(_INTL("¡Ningún Pokémon puede escapar!"))
    end
  end
end

################################################################################
# User's Defense is used instead of user's Attack for this move's calculations.
# (Body Press)
################################################################################
class PokeBattle_Move_175 < PokeBattle_Move
# Se calcula en pbCalcDamage
end

################################################################################
# Consumes berry and raises the user's Defense by 2 stages. (Stuff Cheeks)
################################################################################
class PokeBattle_Move_188 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !pbIsBerry?(attacker.item) ||
       attacker.pbOpposing1.hasWorkingAbility(:UNNERVE) ||
       attacker.pbOpposing2.hasWorkingAbility(:UNNERVE) ||
       attacker.pbOpposing1.hasWorkingAbility(:ASONE1) ||
       attacker.pbOpposing2.hasWorkingAbility(:ASONE1) ||
       attacker.pbOpposing1.hasWorkingAbility(:ASONE2) ||
       attacker.pbOpposing2.hasWorkingAbility(:ASONE2)
      @battle.pbDisplay("¡Pero falló!")
      return -1
    end
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,true,self)
    attacker.pbActivateBerryEffect
    attacker.pbConsumeItem
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=attacker.pbIncreaseStat(PBStats::DEFENSE,2,attacker,false,self)
    return ret ? 0 : -1
  end
end

################################################################################
# Lowers target's Defense and Special Defense by 1 stage at the end of each
# turn. Prevents target from retreating. (Octolock)
################################################################################
class PokeBattle_Move_185 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::Octolock] || opponent.effects[PBEffects::NoRetreat] ||
      (opponent.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(attacker))
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if USENEWBATTLEMECHANICS && opponent.pbHasType?(:GHOST)
      @battle.pbDisplay(_INTL("No afecta a {1}...",opponent.pbThis(true)))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::OctolockUser]=attacker.index
    opponent.effects[PBEffects::Octolock]=true
    @battle.pbDisplay(_INTL("¡{1} no puede escapar debido a {2}!",opponent.pbThis,@name))
    return 0
  end
end

################################################################################
# Forces all active Pokémon to consume their held berries. This move bypasses
# Substitutes. (Tea Time)
################################################################################
class PokeBattle_Move_187 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.pbDisplay(_INTL("¡Es la hora del té! ¡Todos se comieron sus bayas!"))
    for i in 0...4
      if !pbIsBerry?(@battle.battlers[i].item)
        @battle.pbDisplay(_INTL("¡Pero no pasó nada!"))
        return -1
      else
        @battle.battlers[i].pbActivateBerryEffect
        @battle.battlers[i].pbConsumeItem
        return 0
      end
    end
  end
end

################################################################################
# The user restores 1/4 of its maximum HP, rounded half up. If there is and
# adjacent ally, the user restores 1/4 of both its and its ally's maximum HP,
# rounded up. (Life Dew)
################################################################################
class PokeBattle_Move_182 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    didsomething=false
    fullHP=false
    for i in [attacker,attacker.pbPartner]
      next if !i || i.isFainted?
      if i.hp==i.totalhp
        @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",i.pbThis))
        fullHP=true
        next
      end
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      i.pbRecoverHP((i.totalhp/4).round,true)
      @battle.pbDisplay(_INTL("{1} recuperó salud.",i.pbThis))
    end
    return -1 if fullHP
    if !didsomething
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end
end

################################################################################
# Increases each stat by 1 stage. Prevents user from fleeing. (No Retreat)
################################################################################
class PokeBattle_Move_183 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    meanlook=false; meanlook=true if attacker.effects[PBEffects::MeanLook]>=0
    if attacker.effects[PBEffects::NoRetreat] && !meanlook
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPATK,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      attacker.pbIncreaseStat(PBStats::SPEED,1,false,true,nil,showanim)
      showanim=false
    end
    @battle.pbDisplay(_INTL("¡{1} no puede escapar debido a {2}!",attacker.pbThis,@name)) if !meanlook
    attacker.effects[PBEffects::NoRetreat]=true if !attacker.effects[PBEffects::NoRetreat]
    return 0
  end
end

################################################################################
# Aumenta mucho el Ataque y Ataque Especial del objetivo.
# Decorate / Decoración
################################################################################
class PokeBattle_Move_179 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,opponent,false,self) &&
       !opponent.pbCanIncreaseStatStage?(PBStats::SPATK,opponent,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",opponent.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,opponent,false,self)
      opponent.pbIncreaseStat(PBStats::ATTACK,2,opponent,false,self,showanim)
      showanim=false
    end
    if opponent.pbCanIncreaseStatStage?(PBStats::SPATK,opponent,false,self)
      opponent.pbIncreaseStat(PBStats::SPATK,2,opponent,false,self,showanim)
      showanim=false
    end
    return 0
  end
end

################################################################################
# Raises all user's stats by 1 stage in exchange for the user losing 1/3 of its
# maximum HP, rounded down. Fails if the user would faint. (Clangorous Soul)
################################################################################
class PokeBattle_Move_177 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp<=(attacker.totalhp/3).floor ||
      !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false) &&
      !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPATK,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,false)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      attacker.pbIncreaseStat(PBStats::SPEED,1,false,true,nil,showanim)
      showanim=false
    end
    attacker.pbReduceHP((attacker.totalhp/3).round)
    return 0
  end
end

################################################################################
# No es redirigido por habilidades como Storm Drain.
# Snipe Shot / Disparo Certero
################################################################################
class PokeBattle_Move_180 < PokeBattle_Move
  def doesBypassTargetSwap?
    return true
  end
end

################################################################################
# De 2 a 5 golpes, siempre golpes críticos
# Surging Strikes / Azote Torrencial
################################################################################
class PokeBattle_Move_189 < PokeBattle_Move
  def pbCritialOverride(attacker,opponent)
    return true
  end

  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 3
  end
end

################################################################################
# Ataque de dos turnos. Sube el Ataque Especial del usuario en 1 nivel el primer
# turno, ataca en el segundo.
# Meteobeam / Rayo Meteórico
################################################################################
class PokeBattle_Move_190 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      @battle.pbDisplay(_INTL("¡{1} rebosa energía cósmica!",attacker.pbThis))
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self)
      end
    end
    if @immediate
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a su Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Sube el Ataque y la Defensa del objetivo.
# Coaching / Motivación
################################################################################
class PokeBattle_Move_200 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,opponent,false,self) &&
       !opponent.pbCanIncreaseStatStage?(PBStats::DEFENSE,opponent,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",opponent.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,opponent,false,self)
      opponent.pbIncreaseStat(PBStats::ATTACK,1,opponent,false,self,showanim)
      showanim=false
    end
    if opponent.pbCanIncreaseStatStage?(PBStats::DEFENSE,opponent,false,self)
      opponent.pbIncreaseStat(PBStats::DEFENSE,1,opponent,false,self,showanim)
      showanim=false
    end
    return 0
  end
end

################################################################################
# Sube el Ataque y la Defensa del objetivo.
# Rising Voltage / Alto Voltaje
################################################################################
class PokeBattle_Move_201 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      return basedmg*2
    end
    return basedmg
  end
end

################################################################################
# Sube el Ataque y la Defensa del objetivo.
# Misty Explosion / Bruma Explosiva
################################################################################
class PokeBattle_Move_202 < PokeBattle_Move
  def pbOnStartUse(attacker)
    if !attacker.hasMoldBreaker
      bearer=@battle.pbCheckGlobalAbility(:DAMP)
      if bearer!=nil
        @battle.pbDisplay(_INTL("¡{2} de {1} evitó que {3} utilice {4}!",
           bearer.pbThis,PBAbilities.getName(bearer.ability),attacker.pbThis(true),@name))
        return false
      end
    end
    return true
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    super(id,attacker,opponent,hitnum,alltargets,showanimation)
    if !attacker.isFainted?
      attacker.pbReduceHP(attacker.hp)
      attacker.pbFaint if attacker.isFainted?
    end
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.field.effects[PBEffects::MistyTerrain]>0
      return basedmg*1.5
    end
    return basedmg
  end
end

################################################################################
# La potencia se duplica con algún campo activo. El tipo cambia depende del campo activo.
# Terrain Pulse / Pulso de Campo
################################################################################
class PokeBattle_Move_203 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.field.effects[PBEffects::MistyTerrain]>0 ||
       @battle.field.effects[PBEffects::PsychicTerrain]>0 ||
       @battle.field.effects[PBEffects::ElectricTerrain]>0 ||
       @battle.field.effects[PBEffects::GrassyTerrain]>0
      return basedmg*2
    end
    return basedmg
  end

  def pbModifyType(type,attacker,opponent)
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
       type=(getConst(PBTypes,:ELECTRIC) || type)
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
       type=(getConst(PBTypes,:FAIRY) || type)
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
       type=(getConst(PBTypes,:PSYCHIC) || type)
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
       type=(getConst(PBTypes,:GRASS) || type)
    end
    return type
  end
end

################################################################################
# El movimiento falla si el rival no lleva objeto.
# Poltergeist / Poltergeist
################################################################################
class PokeBattle_Move_204 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return true if opponent.item==0 ||
                   @battle.field.effects[PBEffects::MagicRoom]>0 ||
                   opponent.hasWorkingAbility(:KLUTZ) ||
                   opponent.effects[PBEffects::Embargo]>0
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
      @battle.pbDisplay(_INTL("¡{1} va a ser atacado por su {2}!",opponent.pbThis,PBItems.getName(opponent.item)))
      ret=super(attacker,opponent,hitnum,alltargets,showanimation)
      return ret
  end
end

################################################################################
# Elimina el campo activo y falla si no hay ningún campo activo.
# Steel Roller / Allanador Férreo
################################################################################
class PokeBattle_Move_205 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::GrassyTerrain]==0 && @battle.field.effects[PBEffects::ElectricTerrain]==0 &&
       @battle.field.effects[PBEffects::PsychicTerrain]==0 && @battle.field.effects[PBEffects::MistyTerrain]==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    else
      if @battle.field.effects[PBEffects::ElectricTerrain]>0
         @battle.field.effects[PBEffects::ElectricTerrain]=0
         @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
      end
      if @battle.field.effects[PBEffects::PsychicTerrain]>0
        @battle.field.effects[PBEffects::PsychicTerrain]=0
        @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que había en el terreno de combate."))
      end
      if @battle.field.effects[PBEffects::GrassyTerrain]>0
        @battle.field.effects[PBEffects::GrassyTerrain]=0
        @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
      end
      if @battle.field.effects[PBEffects::MistyTerrain]>0
        @battle.field.effects[PBEffects::MistyTerrain]=0
        @battle.pbDisplay(_INTL("La niebla se ha disipado."))
      end
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    end
  end
end

################################################################################
# Ataca por la parte física si la Defensa del oponente es menor que su Def. Esp.
# Shell Side Arm / Moluscañón
################################################################################
class PokeBattle_Move_206 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    stagemul=[10,10,10,10,10,10,10,15,20,25,30,35,40]
    stagediv=[40,35,30,25,20,15,10,10,10,10,10,10,10]
    calcattackstage=attacker.stages[PBStats::ATTACK]+6
    calcattack=(attacker.attack*1.0*stagemul[calcattackstage]/stagediv[calcattackstage]).floor
    calcspatkstage=attacker.stages[PBStats::SPATK]+6
    calcspatk=(attacker.spatk*1.0*stagemul[calcspatkstage]/stagediv[calcspatkstage]).floor
    calcdefensestage=opponent.stages[PBStats::DEFENSE]+6
    calcdefense=(opponent.defense*1.0*stagemul[calcdefensestage]/stagediv[calcdefensestage]).floor
    calcspdefstage=opponent.stages[PBStats::SPDEF]+6
    calcspdef=(opponent.spdef*1.0*stagemul[calcspdefstage]/stagediv[calcspdefstage]).floor

    @category=(calcattack-calcdefense>calcspatk-calcspdef) ? 0 : 1
    @flags= (calcattack-calcdefense>calcspatk-calcspdef) ? @flags : @flags && (0x02 || 0x10 || 0x20) #Turns off contact if special move

    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker)
    end
  end
end

################################################################################
# El ataque se potencia en Campo Psíquico y golpea a todos los Pokémon.
# Expanding Force / Vasta Fuerza
################################################################################
class PokeBattle_Move_207 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.field.effects[PBEffects::PsychicTerrain]>0
      return basedmg*1.5
    end
    return basedmg
  end
end

################################################################################
# Los objetos equipados de los objetivos son inutilizados.
# Corrosive Gas / Gas Corrosivo
################################################################################
class PokeBattle_Move_1A1 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.effects[PBEffects::CorrosiveGas] || opponent.hasWorkingAbility(:STICKYHOLD) ||
       @battle.pbIsUnlosableItem(opponent,opponent.item) || opponent.item == 0
#      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.effects[PBEffects::CorrosiveGas] = true
    @battle.pbDisplay(_INTL("¡{1} ha derretido la {3} de {2}!",attacker.pbThis,opponent.pbThis,
                                                       PBItems.getName(opponent.item)))
    return 0
  end
end

################################################################################
# La potencia se duplica si las estadísticas del atacante bajaron en el turno.
# Lash Out / Desahogo
################################################################################
class PokeBattle_Move_208 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    if attacker.effects[PBEffects::LashOut]
      return (damagemult*2.0).round
    end
    return damagemult
  end
end

################################################################################
# Quema al oponente si se sube las estadísticas en el turno.
# Burning Jealousy / Envidia Ardiente
################################################################################
class PokeBattle_Move_209 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanBurn?(attacker,false,self) &&
      opponent.effects[PBEffects::BurningJealousy]
      opponent.pbBurn(attacker)
    end
  end
end

###############################################################################
# Restaura 1/4 de los PS totales del atacante y sus aliados en combate. También
# elimina los problemas de estado.
# Jungle Healing / Cura Selvática
################################################################################
class PokeBattle_Move_210 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    didsomething=false
    fullHP=false
    for i in [attacker,attacker.pbPartner]
      next if !i || i.isFainted?
      i.status = 0
      if i.hp==i.totalhp
        @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",i.pbThis))
        fullHP=true
        next
      end
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation) if !didsomething
      didsomething=true
      showanim=true
      i.pbRecoverHP((i.totalhp/4).round,true)
      @battle.pbDisplay(_INTL("¡{1} recuperó salud!",i.pbThis))
    end
    return -1 if fullHP
    if !didsomething
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end
end

################################################################################
# El ataque tiene prioridad +1 en Campo de Hierba.
# Grassy Glide / Fitoimpulso
################################################################################
class PokeBattle_Move_211 < PokeBattle_Move
  # Se hace en donde la prioridad
end

################################################################################
# Golpea 2 veces y, en combates dobles, un golpe a cada objetivo.
# Dragon Darts / Dracoflechas
################################################################################
class PokeBattle_Move_212 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 2
  end
end

################################################################################
# Reduce la Defensa del objetivo en 1 nivel y x1.5 de potencia en Gravedad.
# Grav Apple / Fuerza G
################################################################################
class PokeBattle_Move_213 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self)
    return ret ? 0 : -1
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self)
    end
  end

  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.field.effects[PBEffects::Gravity]>0
      return basedmg*1.5
    end
    return basedmg
  end
end

################################################################################
# El usuario pierde la mitad de sus PS totales al usar el ataque.
# Steel Beam / Metaláser
################################################################################
class PokeBattle_Move_214 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted?
      if !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((attacker.totalhp/2.0).round)
      end
    end
  end
end

################################################################################
# Golpea y quita 3 PP al último movimiento usado por el oponente.
# Eerie Spell / Conjuro Funesto
################################################################################
class PokeBattle_Move_215 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    for i in opponent.moves
      if i.id==opponent.lastMoveUsed && i.id>0 && i.pp>0
        pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
        reduction=[3,i.pp].min
        i.pp-=reduction
        @battle.pbDisplay(_INTL("¡Se redujeron los PP de {2} de {1} en {3}!",opponent.pbThis(true),i.name,reduction))
        return 0
      end
    end
    @battle.pbDisplay(_INTL("¡Pero falló!"))
    return -1
  end
end

################################################################################
# Incrementa el Ataque, la Defensa y la Velocidad del
# usuario en 1 nivel cada uno.
# Victory Dance / Danza Triunfal
################################################################################
class PokeBattle_Move_228 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end

################################################################################
# El usuario pierde la mitad de sus PS totales al usar el ataque y reduce su
# Velocidad.
# Chloroblast / Clorofiláser
################################################################################
class PokeBattle_Move_229 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPEED,1,attacker,false,self)
      end
    end
    return ret
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted?
      if !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((attacker.totalhp/2.0).round)
      end
    end
  end
end

################################################################################
# Duerme, congela o paraliza al objetivo.
# Dire Claw / Garra Nociva
################################################################################
class PokeBattle_Move_230 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    case @battle.pbRandom(3)
    when 0
      if opponent.pbCanPoison?(attacker,false,self)
        opponent.pbPoison(attacker)
      end
    when 1
      if opponent.pbCanSleep?(attacker,false,self)
        opponent.pbSleep
      end
    when 2
      if opponent.pbCanParalyze?(attacker,false,self)
        opponent.pbParalyze(attacker)
      end
    end
  end
end

################################################################################
# El usuario pierde PS por el retroceso, pero aumenta su Velocidad.
# Wave Crash / Envite Acuático
################################################################################
class PokeBattle_Move_231 < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if !attacker.hasWorkingAbility(:ROCKHEAD) &&
         !attacker.hasWorkingAbility(:MAGICGUARD)
        attacker.pbReduceHP((turneffects[PBEffects::TotalDamage]/3.0).round)
        @battle.pbDisplay(_INTL("¡{1} es dañado por el retroceso!",attacker.pbThis))
      end
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self)
    end
  end
end

################################################################################
# La potencia se duplica es el usuario está quemado, envenenado o paralizado.
# Además puede envenenar.
# Barb Barrage / Mil Púas Tóxicas
################################################################################
class PokeBattle_Move_232 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (opponent.status>0 &&
       (opponent.effects[PBEffects::Substitute]==0 ||
       ignoresSubstitute?(attacker))) || (opponent.hasWorkingAbility(:COMATOSE) &&
       isConst?(opponent.species,PBSpecies,:KOMALA) &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)))
      return basedmg*2
    end
    return basedmg
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker)
    end
  end
end

################################################################################
# La potencia se duplica es el usuario está quemado, envenenado o paralizado.
# Además puede congelar.
# Bitter Malice / Rencor Reprimido
################################################################################
class PokeBattle_Move_233 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (opponent.status>0 &&
       (opponent.effects[PBEffects::Substitute]==0 ||
       ignoresSubstitute?(attacker))) || (opponent.hasWorkingAbility(:COMATOSE) &&
       isConst?(opponent.species,PBSpecies,:KOMALA) &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)))
      return basedmg*2
    end
    return basedmg
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanFreeze?(attacker,false,self)
      opponent.pbFreeze
    end
  end
end

################################################################################
# Incrementa la Defensa y la Evasión del usuario en 1 nivel cada una.
# Shelter / Retracción
################################################################################
class PokeBattle_Move_234 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::EVASION,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::EVASION,1,attacker,false,self,showanim)
      showanim=false
    end
    return 0
  end
end

################################################################################
# La potencia se duplica es el oponente tiene un problema de estado.
# Además puede quemar.
# Infernal Parade / Marcha Espectral
################################################################################
class PokeBattle_Move_235 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (opponent.status>0 &&
       (opponent.effects[PBEffects::Substitute]==0 ||
       ignoresSubstitute?(attacker))) || (opponent.hasWorkingAbility(:COMATOSE) &&
       isConst?(opponent.species,PBSpecies,:KOMALA) &&
       (opponent.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(attacker)))
      return basedmg*2
    end
    return basedmg
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanBurn?(attacker,false,self)
      opponent.pbBurn(attacker)
    end
  end
end

################################################################################
# Daña al oponente y deja Trampa Rocas en su campo.
# Stone Axe / Hachazo Pétreo
################################################################################
class PokeBattle_Move_236 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if !attacker.pbOpposingSide.effects[PBEffects::StealthRock]
      attacker.pbOpposingSide.effects[PBEffects::StealthRock]=true
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡El equipo enemigo está rodeado de piedras puntiagudas!"))
      else
        @battle.pbDisplay(_INTL("¡Tu equipo está rodeado de piedras puntiagudas!"))
      end
    end
  end
end

################################################################################
# Cura los problemas de estado del usuario y sube 1 nivel su At.Esp. y Def.Esp.
# Take Heart / Bálsamo Ósado
################################################################################
class PokeBattle_Move_237 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.status!=PBStatuses::BURN &&
       attacker.status!=PBStatuses::POISON &&
       attacker.status!=PBStatuses::PARALYSIS
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    else
      t=attacker.status
      attacker.pbCureStatus(false)
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      if t==PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",attacker.pbThis))
      elsif t==PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",attacker.pbThis))
      elsif t==PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",attacker.pbThis))
      end
    if !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
      return -1
    end
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
      showanim=false
    end
      return 0
    end
  end
end

################################################################################
# Cura al usuario la mitad de sus PS máximos y aumenta su Evasión.
# Lunar Blessing / Plegaria Lunar
################################################################################
class PokeBattle_Move_238 < PokeBattle_Move
  def isHealingMove?
    return true
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp==attacker.totalhp
      @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",attacker.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.pbRecoverHP(((attacker.totalhp+1)/2).floor,true)
    @battle.pbDisplay(_INTL("{1} recuperó salud.",attacker.pbThis))
    activepkmn=[]
    for i in @battle.battlers
      next if attacker.pbIsOpposing?(i.index) || i.isFainted?
      activepkmn.push(i.pokemonIndex)
      next if USENEWBATTLEMECHANICS && i.index!=attacker.index &&
         pbTypeImmunityByAbility(pbType(@type,attacker,i),attacker,i)
      case i.status
      when PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",i.pbThis))
      when PBStatuses::SLEEP
        @battle.pbDisplay(_INTL("¡{1} se despertó!",i.pbThis))
      when PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",i.pbThis))
      when PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",i.pbThis))
      when PBStatuses::FROZEN
        @battle.pbDisplay(_INTL("¡{1} se descongeló!",i.pbThis))
      end
      i.pbCureStatus(false)
    end
    party=@battle.pbParty(attacker.index) # NOTE: Considers both parties in multi battles
    for i in 0...party.length
      next if activepkmn.include?(i)
      next if !party[i] || party[i].isEgg? || party[i].hp<=0
      case party[i].status
      when PBStatuses::PARALYSIS
        @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!",party[i].name))
      when PBStatuses::SLEEP
          @battle.pbDisplay(_INTL("¡{1} se despertó!",party[i].name))
      when PBStatuses::POISON
        @battle.pbDisplay(_INTL("¡{1} se curó del envenenamiento!",party[i].name))
      when PBStatuses::BURN
        @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!",party[i].name))
      when PBStatuses::FROZEN
        @battle.pbDisplay(_INTL("¡{1} se descongeló!",party[i].name))
      end
      party[i].status=0
      party[i].statusCount=0
    end
    showanim=true
    return 0
  end
end

################################################################################
# Aumenta la ofensiva del usuario si es mayor que su defensiva. Si no, al revés.
# Mystical Power / Poder Místico
################################################################################
class PokeBattle_Move_239 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.attack + attacker.spatk >= attacker.defense + attacker.spdef
      if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
        showanim=false
      end
    else
      if !attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self) &&
         !attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
        @battle.pbDisplay(_INTL("¡Las características de {1} no subirán más!",attacker.pbThis))
        return -1
      end
      pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    return 0
  end
end


################################################################################
# Intercambia su Ataque por su At.Esp. y su Defensa por su Def.Esp.
# Power Shift / Cambiapoder
################################################################################
class PokeBattle_Move_240 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.attack,attacker.defense=attacker.defense,attacker.attack
    attacker.spatk,attacker.spdef=attacker.spdef,attacker.spatk
    attacker.effects[PBEffects::PowerShift]=!attacker.effects[PBEffects::PowerShift]
    @battle.pbDisplay(_INTL("¡{1} cambió su ofensiva y defensiva!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Puede aumentar Ataque, Defensa, At.Esp. y Def.Esp. del usuario (forma 0).
# Puede reducir Defensa y Def.Esp. del objetivo (forma 1).
# Springtide Storm / Ciclón primavera
################################################################################
class PokeBattle_Move_241 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if attacker.form==0
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanIncreaseStatStage?(PBStats::SPDEF,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPDEF,1,attacker,false,self,showanim)
        showanim=false
      end
    elsif attacker.form==1
      return if opponent.damagestate.substitute
      if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
        opponent.pbReduceStat(PBStats::DEFENSE,1,attacker,false,self)
      end
      if opponent.pbCanReduceStatStage?(PBStats::SPDEF,attacker,false,self)
        opponent.pbReduceStat(PBStats::SPDEF,1,attacker,false,self)
      end
    end
  end
end

################################################################################
# Reduce la Velocidad del usuario en 2 niveles.
# Spin Out / Quemarrueda
################################################################################
class PokeBattle_Move_243 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      showanim=true
      if attacker.pbCanReduceStatStage?(PBStats::SPEED,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPEED,2,attacker,false,self,showanim)
        showanim=false
      end
    end
    return ret
  end
end

################################################################################
# Reduce los PS del usuario a la mitad y sube dos niveles su Ataque, At. Esp. y
# Velocidad.
# Fillet Away / Deslome
################################################################################
class PokeBattle_Move_244 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.hp<=(attacker.totalhp/2).floor ||
       !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self) &&
       !attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
      attacker.pbIncreaseStat(PBStats::ATTACK,2,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,false)
      attacker.pbIncreaseStat(PBStats::SPATK,2,false,true,nil,showanim)
      showanim=false
    end
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
      attacker.pbIncreaseStat(PBStats::SPEED,2,false,true,nil,showanim)
      showanim=false
    end
    attacker.pbReduceHP((attacker.totalhp/2).round)
    return 0
  end
end

################################################################################
# Este movimiento no puede usarse el turno siguiente despues de usarlo.
# Gigaton Hammer / Martillo Colosal
################################################################################
class PokeBattle_Move_245 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::GigatonHammer]=1
    return ret
  end
end

################################################################################
# Aplica Salazón al objetivo y pierde 1/8 de PS cada turno (1/4 si es tipo Agua
# o Acero).
# Salt Cure / Salazón
################################################################################
class PokeBattle_Move_246 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute
     !opponent.isFainted? && !opponent.effects[PBEffects::SaltCure]
     opponent.effects[PBEffects::SaltCure]=true
     @battle.pbDisplay(_INTL("¡{1} está en salazón!",opponent.pbThis))
    end
    return ret
  end
end

################################################################################
# El usuario copia la habilidad del objetivo para el y sus aliados. (Doodle/Decalcomanía)
################################################################################
class PokeBattle_Move_247 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if opponent.pbOwnSide.effects[PBEffects::CraftyShield]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    if opponent.ability==0 ||
       attacker.ability==opponent.ability ||
       isConst?(attacker.ability,PBAbilities,:MULTITYPE) ||
       isConst?(attacker.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(attacker.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(attacker.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(attacker.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(attacker.ability,PBAbilities,:SCHOOLING) ||
       isConst?(attacker.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(attacker.ability,PBAbilities,:ICEFACE) ||
       isConst?(opponent.ability,PBAbilities,:FLOWERGIFT) ||
       isConst?(opponent.ability,PBAbilities,:FORECAST) ||
       isConst?(opponent.ability,PBAbilities,:ILLUSION) ||
       isConst?(opponent.ability,PBAbilities,:IMPOSTER) ||
       isConst?(opponent.ability,PBAbilities,:MULTITYPE) ||
       isConst?(opponent.ability,PBAbilities,:STANCECHANGE) ||
       isConst?(opponent.ability,PBAbilities,:TRACE) ||
       isConst?(opponent.ability,PBAbilities,:WONDERGUARD) ||
       isConst?(opponent.ability,PBAbilities,:ZENMODE) ||
       isConst?(opponent.ability,PBAbilities,:BATTLEBOND) ||
       isConst?(opponent.ability,PBAbilities,:POWERCONSTRUCT) ||
       isConst?(opponent.ability,PBAbilities,:COMATOSE) ||
       isConst?(opponent.ability,PBAbilities,:DISGUISE) ||
       isConst?(opponent.ability,PBAbilities,:POWEROFALCHEMY) ||
       isConst?(opponent.ability,PBAbilities,:RKSSYSTEM) ||
       isConst?(opponent.ability,PBAbilities,:RECEIVER) ||
       isConst?(opponent.ability,PBAbilities,:SCHOOLING) ||
       isConst?(opponent.ability,PBAbilities,:SHIELDSDOWN) ||
       isConst?(opponent.ability,PBAbilities,:ICEFACE) ||
       opponent.hasWorkingItem(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    oldabil=attacker.ability
    attacker.ability=opponent.ability
    abilityname=PBAbilities.getName(opponent.ability)
    @battle.pbDisplay(_INTL("¡{1} copió {3} de {2}!",attacker.pbThis,opponent.pbThis(true),abilityname))
    if attacker.pbPartner
      attacker.pbPartner.ability=opponent.ability
      @battle.pbDisplay(_INTL("¡{1} copió {3} de {2}!",attacker.pbPartner.pbThis,opponent.pbThis(true),abilityname))
    end
    if attacker.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{attacker.pbThis} ha terminado")
      attacker.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(attacker,attacker.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",attacker.pbThis,PBAbilities.getName(oldabil)))
    end
    if attacker.pbPartner.effects[PBEffects::Illusion] && isConst?(oldabil,PBAbilities,:ILLUSION)
      PBDebug.log("[Habilidad disparada] Ilusión de #{attacker.pbPartner.pbThis} ha terminado")
      attacker.pbPartner.effects[PBEffects::Illusion]=nil
      @battle.scene.pbChangePokemon(attacker.pbPartner,attacker.pbPartner.pokemon)
      @battle.pbDisplay(_INTL("¡{2} de {1} se ha acabado!",attacker.pbPartner.pbThis,PBAbilities.getName(oldabil)))
    end
    return 0
  end
end

################################################################################
# El usuario se cambia por otro Pokémon del equipo, pero antes utiliza parte de los PS propios para crear un sustituto para su relevo.
# (Shed Tail / Autonomia)
################################################################################
class PokeBattle_Move_248 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.effects[PBEffects::Substitute]>0
      @battle.pbDisplay(_INTL("¡{1} ya tiene un sustituto!",attacker.pbThis))
      return -1
    end
    sublife=[(attacker.totalhp/4).floor,1].max
    if attacker.hp<=sublife
      @battle.pbDisplay(_INTL("¡Estaba muy débil para crear un sustituto!"))
      return -1
    end
    attacker.pbReduceHP(sublife,false,false)
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    #@battle.scene.setSubstitute(attacker.index) #sustituto
    attacker.effects[PBEffects::MultiTurn]=0
    attacker.effects[PBEffects::MultiTurnAttack]=0
    attacker.effects[PBEffects::Substitute]=sublife
    @battle.pbDisplay(_INTL("¡{1} creó un sustituto!",attacker.pbThis))
    if shouldHaveUTurnEffects?(attacker, opponent)
      attacker.effects[PBEffects::Uturn] = true
      attacker.effects[PBEffects::ShedTail] = true
    else
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    return 0
  end

  def shouldHaveUTurnEffects?(attacker, opponent)
    return false if attacker.isFainted?
    return false unless @battle.pbCanChooseNonActive?(attacker.index)
    return false if [1, 3].include?(attacker.index) && !@battle.opponent
    #return false if [1, 3].include?(attacker.index) && @battle.sosbattle
    return true
  end
end

################################################################################
# Golpea tres veces.
# Triple Dive / Triple Inmersión
################################################################################
class PokeBattle_Move_249 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 3
  end
end

################################################################################
# Anula los efectos de Púas, Trampa Rocas, Red Viscosa, Púas Tóxicas y Sustituto. Aumenta el Ataque y la Velocidad del usuario.
# (Tidy Up/Limpieza General)
################################################################################
class PokeBattle_Move_250 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    opponent.pbReduceStat(PBStats::EVASION,1,attacker,false,self)
    opponent.pbOwnSide.effects[PBEffects::Reflect]     = 0
    opponent.pbOwnSide.effects[PBEffects::LightScreen] = 0
    opponent.pbOwnSide.effects[PBEffects::AuroraVeil]  = 0
    opponent.pbOwnSide.effects[PBEffects::Mist]        = 0
    opponent.pbOwnSide.effects[PBEffects::Safeguard]   = 0
    opponent.pbOwnSide.effects[PBEffects::Spikes]      = 0
    opponent.pbOwnSide.effects[PBEffects::StealthRock] = false
    opponent.pbOwnSide.effects[PBEffects::StickyWeb]   = false
    opponent.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
    if USENEWBATTLEMECHANICS
      opponent.pbOpposingSide.effects[PBEffects::Reflect]     = 0
      opponent.pbOpposingSide.effects[PBEffects::LightScreen] = 0
      opponent.pbOpposingSide.effects[PBEffects::AuroraVeil]  = 0
      opponent.pbOpposingSide.effects[PBEffects::Mist]        = 0
      opponent.pbOpposingSide.effects[PBEffects::Safeguard]   = 0
      opponent.pbOpposingSide.effects[PBEffects::Spikes]      = 0
      opponent.pbOpposingSide.effects[PBEffects::StealthRock] = false
    if  @battle.field.effects[PBEffects::ElectricTerrain]>0
        @battle.field.effects[PBEffects::ElectricTerrain]=0
        @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
          @battle.field.effects[PBEffects::GrassyTerrain]=0
          @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
          @battle.field.effects[PBEffects::MistyTerrain]=0
          @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
          @battle.field.effects[PBEffects::PsychicTerrain]=0
          @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que había en el terreno de combate."))
    end
      opponent.pbOpposingSide.effects[PBEffects::StickyWeb]   = false
      opponent.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0
    end
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
      showanim=false
    end
    showanim=true
    if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self,showanim)
      showanim=false
    end
    opponent.pbOwnSide.effects[PBEffects::Reflect]     = 0
    opponent.pbOwnSide.effects[PBEffects::LightScreen] = 0
    opponent.pbOwnSide.effects[PBEffects::AuroraVeil]  = 0
    opponent.pbOwnSide.effects[PBEffects::Mist]        = 0
    opponent.pbOwnSide.effects[PBEffects::Safeguard]   = 0
    opponent.pbOwnSide.effects[PBEffects::Spikes]      = 0
    opponent.pbOwnSide.effects[PBEffects::StealthRock] = false
    opponent.pbOwnSide.effects[PBEffects::StickyWeb]   = false
    opponent.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
    if USENEWBATTLEMECHANICS
      opponent.pbOpposingSide.effects[PBEffects::Reflect]     = 0
      opponent.pbOpposingSide.effects[PBEffects::LightScreen] = 0
      opponent.pbOpposingSide.effects[PBEffects::AuroraVeil]  = 0
      opponent.pbOpposingSide.effects[PBEffects::Mist]        = 0
      opponent.pbOpposingSide.effects[PBEffects::Safeguard]   = 0
      opponent.pbOpposingSide.effects[PBEffects::Spikes]      = 0
      opponent.pbOpposingSide.effects[PBEffects::StealthRock] = false
    if  @battle.field.effects[PBEffects::ElectricTerrain]>0
        @battle.field.effects[PBEffects::ElectricTerrain]=0
        @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    elsif @battle.field.effects[PBEffects::GrassyTerrain]>0
          @battle.field.effects[PBEffects::GrassyTerrain]=0
          @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    elsif @battle.field.effects[PBEffects::MistyTerrain]>0
          @battle.field.effects[PBEffects::MistyTerrain]=0
          @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    elsif @battle.field.effects[PBEffects::PsychicTerrain]>0
          @battle.field.effects[PBEffects::PsychicTerrain]=0
          @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que había en el terreno de combate."))
    end
      opponent.pbOpposingSide.effects[PBEffects::StickyWeb]   = false
      opponent.pbOpposingSide.effects[PBEffects::ToxicSpikes] = 0
    end
  end
end

################################################################################
# La potencia base aumenta 50 por cada compañero debilitado en combate.
# Last Respects / Homenaje Póstumo
################################################################################
class PokeBattle_Move_251 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    basedmg=basedmg+(attacker.pbOwnSide.effects[PBEffects::FaintedAlly]*50)
    return basedmg
  end
end

################################################################################
# Elimina el campo activo.
# Ice Spinner / Pirueta Helada
################################################################################
class PokeBattle_Move_252 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
       @battle.field.effects[PBEffects::ElectricTerrain]=0
       @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    end
    if @battle.field.effects[PBEffects::PsychicTerrain]>0
      @battle.field.effects[PBEffects::PsychicTerrain]=0
      @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que había en el terreno de combate."))
    end
    if @battle.field.effects[PBEffects::GrassyTerrain]>0
      @battle.field.effects[PBEffects::GrassyTerrain]=0
      @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    end
    if @battle.field.effects[PBEffects::MistyTerrain]>0
      @battle.field.effects[PBEffects::MistyTerrain]=0
      @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    end
  end
end

################################################################################
# Remueve movimientos de trampa, obstáculos de entrada y Drenadoras del lado
# del usuario. También envenena al oponente.
# Mortal Spin / Giro Rápido
################################################################################
class PokeBattle_Move_253 < PokeBattle_Move
  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      if attacker.effects[PBEffects::MultiTurn]>0
        mtattack=PBMoves.getName(attacker.effects[PBEffects::MultiTurnAttack])
        mtuser=@battle.battlers[attacker.effects[PBEffects::MultiTurnUser]]
        @battle.pbDisplay(_INTL("¡{1} se liberó de {3} de {2}!",attacker.pbThis,mtuser.pbThis(true),mtattack))
        attacker.effects[PBEffects::MultiTurn]=0
        attacker.effects[PBEffects::MultiTurnAttack]=0
        attacker.effects[PBEffects::MultiTurnUser]=-1
      end
      if attacker.effects[PBEffects::LeechSeed]>=0
        attacker.effects[PBEffects::LeechSeed]=-1
        @battle.pbDisplay(_INTL("¡{1} se liberó de las Drenadoras!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::StealthRock]
        attacker.pbOwnSide.effects[PBEffects::StealthRock]=false
        @battle.pbDisplay(_INTL("¡{1} se deshizo de las piedras puntiagudas!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::Spikes]>0
        attacker.pbOwnSide.effects[PBEffects::Spikes]=0
        @battle.pbDisplay(_INTL("¡{1} se deshizo de las púas!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
        attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]=0
        @battle.pbDisplay(_INTL("¡{1} se deshizo de las púas venenosas!",attacker.pbThis))
      end
      if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
        attacker.pbOwnSide.effects[PBEffects::StickyWeb]=false
        @battle.pbDisplay(_INTL("¡{1} se deshizo de la red pegajosa!",attacker.pbThis))
      end
    end
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanPoison?(attacker,false,self) ||
     attacker.hasWorkingAbility(:CORROSION) && opponent.status==0
      opponent.pbPoison(attacker)
    end
  end
end

################################################################################
# Revive a un aliado debilitado con la mitad de sus PS.
# Revival Blessing / Plegaria Vital
################################################################################
class PokeBattle_Move_254 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    party=@battle.pbParty(attacker.index)
    if party.select{|p|p.hp==0}.length==0
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::RevivalBlessing]=true
    return 0
  end
end


################################################################################
# Ataque de dos turnos. Sube el Ataque Especial del usuario en 1 nivel el primer
# turno, ataca en el segundo.
# Electrorrayo / Electroshot
################################################################################
class PokeBattle_Move_255 < PokeBattle_Move
  def pbTwoTurnAttack(attacker)
    @immediate=false; @sunny=false
    if attacker.effects[PBEffects::TwoTurnAttack]==0
      if (@battle.pbWeather==PBWeather::RAINDANCE ||
         @battle.pbWeather==PBWeather::HEAVYRAIN) && !attacker.hasWorkingItem(:UTILITYUMBRELLA)
        @immediate=true; @sunny=true
      end
    end
    if !@immediate && attacker.hasWorkingItem(:POWERHERB)
      @immediate=true
    end
    return false if @immediate
    return attacker.effects[PBEffects::TwoTurnAttack]==0
  end

  def pbBaseDamageMultiplier(damagemult,attacker,opponent)
    if @battle.pbWeather!=0 &&
       @battle.pbWeather!=PBWeather::RAINDANCE &&
       @battle.pbWeather!=PBWeather::HEAVYRAIN
      return (damagemult*0.5).round
    end
    return damagemult
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @immediate || attacker.effects[PBEffects::TwoTurnAttack]>0
      pbShowAnimation(@id,attacker,opponent,1,alltargets,showanimation) # Charging anim
      if attacker.pbCanIncreaseStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPATK,1,attacker,false,self)
      end
      @battle.pbDisplay(_INTL("¡{1} comienza a acumular electricidad!",attacker.pbThis))
    end
    if @immediate && !@sunny
      @battle.pbCommonAnimation("UseItem",attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} ya está listo gracias a la Hierba Única!",attacker.pbThis))
      attacker.pbConsumeItem
    end
    return 0 if attacker.effects[PBEffects::TwoTurnAttack]>0
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Ataque de dos turnos. Sube el Ataque Especial del usuario en 1 nivel el primer
# turno, ataca en el segundo.
# Láser Veleidoso / Fickle Beam
################################################################################
class PokeBattle_Move_256 < PokeBattle_Move
  def pbModifyDamage(damagemult,attacker,opponent)
    if rand(9)<3 # Buceo
      return (damagemult*2.0).round
    end
    return damagemult
  end
end

################################################################################
# El usuario se protege y reduce la Velocidad del oponente si utiliza un
# movimiento de contacto.
# Silk Trap / Telatrampa
################################################################################
class PokeBattle_Move_257 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::Silktrap]
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detección, Protección
       0xAB,   # Anticipo
       0xAC,   # Vastaguardia
       0xE8,   # Aguante
       0x14B,  # Escudo Real
       0x14C,  # Barrera Espinosa
       0x15B,  # Búnker
       0x184,  # Obstrucción
       0x257   # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::Silktrap]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Destruye pantallas y cambia en función del tipo secundario del usuario.
# Raging Bull / Furia Taurina
################################################################################
class PokeBattle_Move_258 < PokeBattle_Move
  def pbType(type,attacker,opponent)
    return attacker.type2
  end

  def pbCalcDamage(attacker,opponent)
    return super(attacker,opponent,PokeBattle_Move::NOREFLECT)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.pbOpposingSide.effects[PBEffects::Reflect]>0
      attacker.pbOpposingSide.effects[PBEffects::Reflect]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡Reflejo del equipo enemigo no funciona!"))
      else
        @battle.pbDisplayPaused(_INTL("¡Reflejo no funciona en tu equipo!"))
      end
    end
    if attacker.pbOpposingSide.effects[PBEffects::LightScreen]>0
      attacker.pbOpposingSide.effects[PBEffects::LightScreen]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡Pantalla Luz del equipo enemigo no funciona!"))
      else
        @battle.pbDisplay(_INTL("¡Pantalla Luz no funciona en tu equipo!"))
      end
    end
    if attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]>0
      attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]=0
      if !@battle.pbIsOpposing?(attacker.index)
        @battle.pbDisplay(_INTL("¡Velo Aurora del equipo enemigo no funciona!"))
      else
        @battle.pbDisplay(_INTL("¡Velo Aurora no funciona en tu equipo!"))
      end
    end
    return ret
  end

  def pbShowAnimation(id,attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.pbOpposingSide.effects[PBEffects::Reflect]>0 ||
       attacker.pbOpposingSide.effects[PBEffects::LightScreen]>0 ||
       attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]>0
      return super(id,attacker,opponent,1,alltargets,showanimation) # Wall-breaking anim
    end
    return super(id,attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Ataque de dos turnos. Sube el Ataque Especial del usuario en 1 nivel el primer
# turno, ataca en el segundo.
# Bramido Dragón / Dragon Cheer
################################################################################
class PokeBattle_Move_259 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    if attacker.effects[PBEffects::FocusEnergy]>=2
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    if attacker.pbHasType?(:DRAGON)
      attacker.effects[PBEffects::FocusEnergy]=2
    else
      attacker.effects[PBEffects::FocusEnergy]=1
    end
    @battle.pbDisplay(_INTL("¡{1} se está preparando para luchar!",attacker.pbThis))
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.effects[PBEffects::FocusEnergy]<2
      if attacker.pbHasType?(:DRAGON)
        attacker.effects[PBEffects::FocusEnergy]=2
      else
        attacker.effects[PBEffects::FocusEnergy]=1
      end
      @battle.pbDisplay(_INTL("¡{1} se está preparando para luchar!",attacker.pbThis))
    end
  end
end

################################################################################
# Quema al oponente si se sube las estadísticas en el turno.
# Canto Encantador / Alluring Voice
################################################################################
class PokeBattle_Move_260 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanConfuse?(attacker,false,self) &&
      opponent.effects[PBEffects::BurningJealousy]
      opponent.pbConfuse(attacker)
    end
  end
end

################################################################################
# Falla si el objetivo no está preparando un movimiento de prioridad alta.
# (Palma Rauda/UPPER HAND)
################################################################################
class PokeBattle_Move_261 < PokeBattle_Move
  def pbMoveFailed(attacker,opponent)
    return true if @battle.choices[opponent.index][0]!=1   # No ha elegido un movimiento
    oppmove=@battle.choices[opponent.index][2]
    return true if !oppmove || oppmove.id<=0 || oppmove.priority>0
    return true if opponent.hasMovedThisRound? && oppmove.function!=0xB0   # Yo Primero
    return false
  end
end

################################################################################
# Increases the user and its partner's Attack by 1 stage. (Howl)
################################################################################
class PokeBattle_Move_262 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return super(attacker,opponent,hitnum,alltargets,showanimation) if pbIsDamaging?
    return -1 if !attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,true,self) &&
                 !attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
    attacker.pbPartner.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
    return 0
  end

  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
    end
    if attacker.pbPartner.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self)
    end
  end
end

################################################################################
# Cambia el tipo al Teratipo del usuario si este está teracristalizado y golpea
# Con el ataque físico especial según cual es más alto.
################################################################################
class PokeBattle_Move_263 < PokeBattle_Move

  def pbBaseDamage(damagemult,attacker,opponent)
    if attacker.type1==PBTypes::STELLAR
      return 100
    else
      return 80
    end
  end

  def pbModifyType(type,attacker,opponent)
    if attacker.isTera?
      return attacker.pokemon.teratype
    else
      return type
    end
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.attack+attacker.stages[PBStats::ATTACK]>attacker.spatk+attacker.stages[PBStats::SPATK]
      @category=0
    else
      @category=1
    end
    if opponent.damagestate.calcdamage>0 && attacker.type1==PBTypes::STELLAR
      showanim=true
      if attacker.pbCanReduceStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbReduceStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
      if attacker.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPATK,1,attacker,false,self,showanim)
        showanim=false
      end
    end
    return super(attacker,opponent,hitnum,alltargets,showanimation)
  end
end

################################################################################
# Reduce el Ataque Especial del usuario en 2 niveles. Y añade dinero trás el combate.
# Fiebre Dorada / MAKE IT RAIN
################################################################################
class PokeBattle_Move_264 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      if attacker.pbCanReduceStatStage?(PBStats::SPATK,attacker,false,self)
        attacker.pbReduceStat(PBStats::SPATK,2,attacker,false,self)
      end
    end
    if opponent.damagestate.calcdamage>0
      if @battle.pbOwnedByPlayer?(attacker.index)
        @battle.extramoney+=5*attacker.level
        @battle.extramoney=MAXMONEY if @battle.extramoney>MAXMONEY
      end
      @battle.pbDisplay(_INTL("¡Hay monedas por todas partes!"))
    end
    return ret
  end
end

################################################################################
# El ataque se potencia en Sol y golpea a todos los Pokémon.
# Hidrovapor / Hydrosteam
################################################################################
class PokeBattle_Move_265 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if (@battle.pbWeather==PBWeather::SUNNYDAY ||
        @battle.pbWeather==PBWeather::HARSHSUN) && !attacker.hasWorkingItem(:UTILITYUMBRELLA)
      return basedmg*1.5
    end
    return basedmg
  end
end

################################################################################
# El ataque se potencia en Campo Electrico y golpea a todos los Pokémon.
# Psicohojas / Psyblade
################################################################################
class PokeBattle_Move_266 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if @battle.field.effects[PBEffects::ElectricTerrain]>0
      return basedmg*1.5
    end
    return basedmg
  end
end

################################################################################
# La potencia del movimiento aumenta si el ataque es supereficaz.
# Electroderrape, Nitrochoque
################################################################################
class PokeBattle_Move_267 < PokeBattle_Move
  # El daño se comprueba donde Neuroforce
end

################################################################################
# Ataque de dos turnos. Sube el Ataque Especial del usuario en 1 nivel el primer
# turno, ataca en el segundo.
# Llama Protectora / Burning Bulwark
################################################################################
class PokeBattle_Move_268 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if attacker.effects[PBEffects::BurningBulwark]
      @battle.pbDisplay(_INTL("¡Pero falló"))
      return -1
    end
    ratesharers=[
       0xAA,   # Detect, Protect
       0xAB,   # Quick Guard
       0xAC,   # Wide Guard
       0xE8,   # Endure
       0x14B,  # King's Shield
       0x14C,  # Spiky Shield
       0x15B,  # Baneful Bunker
       0x184,  # Obstruct
       0xF931, # Burning Bulwark
       0xF92,  # Telatrampa
    ]
    if !ratesharers.include?(PBMoveData.new(attacker.lastMoveUsed).function)
      attacker.effects[PBEffects::ProtectRate]=1
    end
    unmoved=false
    for poke in @battle.battlers
      next if poke.index==attacker.index
      if @battle.choices[poke.index][0]==1 &&      # Elige un movimiento
         !poke.hasMovedThisRound?
        unmoved=true; break
      end
    end
    if !unmoved ||
       @battle.pbRandom(65536)>=(65536/attacker.effects[PBEffects::ProtectRate]).floor
      attacker.effects[PBEffects::ProtectRate]=1
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    attacker.effects[PBEffects::BurningBulwark]=true
    attacker.effects[PBEffects::ProtectRate]*=2
    @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    return 0
  end
end

################################################################################
# Puede aumentar Ataque (forma 0).
# Puede aumentar Defensa (forma 1).
# Puede aumentar Velocidad (forma 2).
# Oído Cocina / Order Up
################################################################################
class PokeBattle_Move_269 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent)
    if attacker.pbPartner.form==0
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,attacker,false,self,showanim)
        showanim=false
      end
    elsif attacker.pbPartner.form==1
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,attacker,false,self,showanim)
        showanim=false
      end
    elsif attacker.pbPartner.form==2
      showanim=true
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,attacker,false,self)
        attacker.pbIncreaseStat(PBStats::SPEED,1,attacker,false,self,showanim)
        showanim=false
      end
    end
  end
end

################################################################################
# En el turno siguiente, los ataques que lance el rival no fallarán y causarán el doble de daño.
# Asalto espadón / Glaive Rush
################################################################################
class PokeBattle_Move_270 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    attacker.effects[PBEffects::GlaiveRush]=true if opponent.damagestate.calcdamage>0
  end
end

################################################################################
# Aumenta el Ataque del objetivo en 2 niveles y reduce su Defensa en 2 niveles.
# Spicy Extract / Extracto Picante
################################################################################
class PokeBattle_Move_271 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if !opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self) &&
       !opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      @battle.pbDisplay(_INTL("¡Las características de {1} no cambiarán más!",opponent.pbThis))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    showanim=true
    if opponent.pbCanIncreaseStatStage?(PBStats::ATTACK,attacker,false,self)
      opponent.pbIncreaseStat(PBStats::ATTACK,2,attacker,false,self,showanim)
    end
    if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,attacker,false,self)
      opponent.pbReduceStat(PBStats::DEFENSE,2,attacker,false,self,showanim)
    end
    return 0
  end
end

################################################################################
# Golpea 10 veces. La potencia se multiplica por el número de golpes.
# (Proliferación / Population Bomb)
# Se revisa la precisión para cada golpe.
################################################################################
class PokeBattle_Move_272 < PokeBattle_Move
  def pbIsMultiHit
    return true
  end

  def pbNumHits(attacker)
    return 10
  end

  # Issue #14: Dado trucado no está programado - albertomcastro4
  # Si tienes Dado Trucado, los 4 primeros golpes siempre aciertan. A partir del 4, se verifica la precisión. 
  def pbOnStartUse(attacker)
    @skill_link = attacker.hasWorkingAbility(:SKILLLINK)
    @loaded_dice = attacker.hasWorkingItem(:LOADEDDICE)
    @checks = !(@skill_link || @loaded_dice)
    @num_hits = 0
    return true
  end

  def successCheckPerHit?
    @num_hits += 1
    @checks = true if @num_hits >= 4 && (@loaded_dice && !@skill_link)
    return @checks
  end
end

################################################################################
# Mete nieve y cambia. Se ignoran los movimientos de trampas.
# (Fría acogida/Chilly Reception)
################################################################################
class PokeBattle_Move_273 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=-1
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    canhail = true
    case @battle.weather
    when PBWeather::HEAVYRAIN
      @battle.pbDisplay(_INTL("¡No hay alivio para este diluvio!"))
      canhail = false
    when PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡El sol realmente abrazador no ha mermado en absoluto!"))
      canhail = false
    when PBWeather::STRONGWINDS
      @battle.pbDisplay(_INTL("¡Las misteriosas turbulencias siguen soplando sin cesar!"))
      canhail = false
    when PBWeather::HAIL
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      canhail = false
    end
    if canhail == true
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      @battle.weather=PBWeather::HAIL
      @battle.weatherduration=5
      @battle.weatherduration=8 if attacker.hasWorkingItem(:ICYROCK)
      @battle.pbCommonAnimation("Hail",nil,nil)
      @battle.pbDisplay(_INTL("¡Ha empezado a granizar!"))
    end
    if !attacker.isFainted? &&
       @battle.pbCanChooseNonActive?(attacker.index) &&
       !@battle.pbAllFainted?(@battle.pbParty(opponent.index))
      attacker.effects[PBEffects::Uturn]=true; ret=0
    end
    return ret
  end
end



################################################################################
# Cuantos más golpes haya recibido el usuario, mayor será la potencia del movimiento.
# (Puño Furia/Rage Fist)
################################################################################
class PokeBattle_Move_274 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    ret=350 if attacker.effects[PBEffects::RageFist]>=6
    ret=300 if attacker.effects[PBEffects::RageFist]==5
    ret=250 if attacker.effects[PBEffects::RageFist]==4
    ret=200 if attacker.effects[PBEffects::RageFist]==3
    ret=150 if attacker.effects[PBEffects::RageFist]==2
    ret=100 if attacker.effects[PBEffects::RageFist]==1
    ret=50 if attacker.effects[PBEffects::RageFist]==0
    return ret
  end
end

################################################################################
# El usuario recupera la mitad de los PS que inflinge como daño. Y puede causar quemaduras.
# (Cañón Batidor, MATCHA GOTCHA)
################################################################################
class PokeBattle_Move_275 < PokeBattle_Move_00A
  def isHealingMove?
    return USENEWBATTLEMECHANICS
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    if opponent.damagestate.calcdamage>0
      hpgain=(opponent.damagestate.hplost/2).round
      if opponent.hasWorkingAbility(:LIQUIDOOZE)
        attacker.pbReduceHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} absorbió el Lodo Líquido!",attacker.pbThis))
      elsif attacker.effects[PBEffects::HealBlock]==0
        hpgain=(hpgain*1.3).floor if attacker.hasWorkingItem(:BIGROOT)
        attacker.pbRecoverHP(hpgain,true)
        @battle.pbDisplay(_INTL("¡{1} ha perdido energía!",opponent.pbThis))
      end
    end
    return ret
  end
end

################################################################################
# Su Velocidad se reduzca progresivamente durante tres turnos.
# Bomba Caramelo / Syrup Bomb
################################################################################
class PokeBattle_Move_276 < PokeBattle_Move
  def pbAdditionalEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    opponent.effects[PBEffects::SyrupBomb]=3 if opponent.damagestate.calcdamage>0
  end
end

################################################################################
# Cambia a el segundo tipo del pokemon.
################################################################################
class PokeBattle_Move_277 < PokeBattle_Move
  def pbType(type,attacker,opponent)
    ret = attacker.type2
    ret = attacker.type1 if !attacker.type2
    return ret
  end
end


################################################################################
# Si el ataque falla, el usuario pierde 1/2 de los PS máximos. Puede confundir.
# Axe Kick / Patada Hacha
################################################################################
class PokeBattle_Move_278 < PokeBattle_Move
  def isRecoilMove?
    return true
  end

  def pbAdditionalEffect(attacker,opponent)
    return if opponent.damagestate.substitute
    if opponent.pbCanConfuse?(attacker,false,self)
      opponent.pbConfuse
      @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",opponent.pbThis))
    end
  end
end

################################################################################
# Ataca al objetivo irradiando el poder de sus cristales.
# Si Terapagos usa este movimiento en su Forma Astral, inflige daño a todos los rivales.
# Teraclúster
################################################################################
class PokeBattle_Move_279 < PokeBattle_Move
  def pbModifyType(type,attacker,opponent)
    type=getConst(PBTypes,:NORMAL) || 0
    if isConst?(attacker.species,PBSpecies,:TERAPAGOS) && attacker.isTera?
      type=getConst(PBTypes,:STELLAR) || 0
    end
    return type
  end
end