module PBWeather
  SHADOWSKY = 8
end



def pbPurify(pokemon,scene)
  if pokemon.heartgauge==0 && pokemon.shadow
    return if !pokemon.savedev && !pokemon.savedexp
    pokemon.shadow=false
    pokemon.giveRibbon(PBRibbons::NATIONAL)
    scene.pbDisplay(_INTL("{1} ha abierto la puerta de su corazón!",pokemon.name))
    oldmoves=[]
    for i in 0...4; oldmoves.push(pokemon.moves[i].id); end
    pokemon.pbUpdateShadowMoves()
    for i in 0...4
      if pokemon.moves[i].id!=0 && pokemon.moves[i].id!=oldmoves[i]
        scene.pbDisplay(_INTL("¡{1} ha recuperado el movimiento \n{2}!",
           pokemon.name,PBMoves.getName(pokemon.moves[i].id)))
      end
    end
    pokemon.pbRecordFirstMoves
    if pokemon.savedev
      for i in 0...6
        pbApplyEVGain(pokemon,i,pokemon.savedev[i])
      end
      pokemon.savedev=nil
    end
    newexp=PBExperience.pbAddExperience(pokemon.exp,pokemon.savedexp||0,pokemon.growthrate)
    pokemon.savedexp=nil
    newlevel=PBExperience.pbGetLevelFromExperience(newexp,pokemon.growthrate)
    curlevel=pokemon.level
    if newexp!=pokemon.exp
      scene.pbDisplay(_INTL("¡{1} ha recuperado {2} Puntos de Experiencia!",pokemon.name,newexp-pokemon.exp))
    end
    if newlevel==curlevel
      pokemon.exp=newexp
      pokemon.calcStats
    else
      pbChangeLevel(pokemon,newlevel,scene) # por conveniencia
      pokemon.exp=newexp
    end
    speciesname=PBSpecies.getName(pokemon.species)
    if scene.pbConfirm(_INTL("¿Quieres darle un apodo a {1}?",speciesname))
      helptext=_INTL("Apodo de {1}",speciesname)
      newname=pbEnterPokemonName(helptext,0,10,"",pokemon)
      pokemon.name=newname if newname!=""
    end
  end
end



class PokemonTemp
  attr_accessor :heartgauges
end



Events.onStartBattle+=proc {|sender,e|
   $PokemonTemp.heartgauges=[]
   for i in 0...$Trainer.party.length
     $PokemonTemp.heartgauges[i]=$Trainer.party[i].heartgauge
   end
}

Events.onEndBattle+=proc {|sender,e|
   decision=e[0]
   canlose=e[1]
   for i in 0...$PokemonTemp.heartgauges.length
     pokemon=$Trainer.party[i]
     if pokemon && ($PokemonTemp.heartgauges[i] &&
        $PokemonTemp.heartgauges[i]!=0 && pokemon.heartgauge==0)
       pbReadyToPurify(pokemon)
     end
   end
}



# Clase de la escena para controlar la aparición de la pantalla
class RelicStoneScene
# Procesa la escena
  def pbPurify()
  end

# Se actualiza la escena aquí, es llamado una vez por cada frame
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

# End the scene here
  def pbEndScene
    # Fade out all sprites
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Dispose all sprites
    pbDisposeSpriteHash(@sprites)
    # Dispose the viewport
    @viewport.dispose
  end

  def pbDisplay(msg,brief=false)
    UIHelper.pbDisplay(
       @sprites["msgwindow"],msg,brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(
       @sprites["msgwindow"],msg) { pbUpdate }
  end

  def pbStartScene(pokemon)
    # Create sprite hash
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @pokemon=pokemon
    addBackgroundPlane(@sprites,"bg","relicstonebg",@viewport)
    @sprites["msgwindow"]=Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible=true
    @sprites["msgwindow"].viewport=@viewport
    @sprites["msgwindow"].text=""
    @sprites["msgwindow"].x=0
    @sprites["msgwindow"].y=Graphics.height-96
    @sprites["msgwindow"].width=Graphics.width
    @sprites["msgwindow"].height=96
    pbDeactivateWindows(@sprites)
    # Fade in all sprites
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
end



# Screen class for handling game logic
class RelicStoneScreen
  def initialize(scene)
    @scene = scene
  end

  def pbDisplay(x)
    @scene.pbDisplay(x)
  end

  def pbConfirm(x)
    @scene.pbConfirm(x)
  end

  def pbRefresh
  end

  def pbStartScreen(pokemon)
    @scene.pbStartScene(pokemon)
    @scene.pbPurify()
    pbPurify(pokemon,self)
    @scene.pbEndScene()
  end
end



def pbRelicStoneScreen(pkmn)
  retval=true
  pbFadeOutIn(99999){
     scene=RelicStoneScene.new
     screen=RelicStoneScreen.new(scene)
     retval=screen.pbStartScreen(pkmn)
  }
  return retval
end

def pbIsPurifiable?(pkmn)
  return false if !pkmn
  if pkmn.isShadow? && pkmn.heartgauge==0 &&
     !isConst?(pkmn.species,PBSpecies,:LUGIA)
    return true
  end
  return false
end

def pbHasPurifiableInParty
  return $Trainer.party.any? {|item| pbIsPurifiable?(item) }
end

def pbRelicStone
  if pbHasPurifiableInParty()
    Kernel.pbMessage(_INTL("¡Hay un Pokemon que podría habrír la puerta de su corazón!"))
    # Elige un Pokemon que puede ser purificado
    pbChoosePokemon(1,2,proc {|poke|
       !poke.isEgg? && poke.hp>0 && poke.isShadow? && poke.heartgauge==0
    })
    if $game_variables[1]>=0
      pbRelicStoneScreen($Trainer.party[$game_variables[1]])
    end
  else
    Kernel.pbMessage(_INTL("No tienen ningún Pokemon que pueda ser purificado."))
  end
end

def pbRaiseHappinessAndReduceHeart(pokemon,scene,amount)
  if !pokemon.isShadow?
    scene.pbDisplay(_INTL("No tendrá ningún efecto."))
    return false
  end
  if pokemon.happiness==255 && pokemon.heartgauge==0
    scene.pbDisplay(_INTL("No tendrá ningún efecto."))
    return false
  elsif pokemon.happiness==255
    pokemon.adjustHeart(-amount)
    scene.pbDisplay(_INTL("¡{1} te adora!\nLa puerta de su corazón se ha abierto un poco.",pokemon.name))
    pbReadyToPurify(pokemon)
    return true
  elsif pokemon.heartgauge==0
    pokemon.changeHappiness("vitamin")
    scene.pbDisplay(_INTL("{1} se ha vuelto amistoso.",pokemon.name))
    return true
  else
    pokemon.changeHappiness("vitamin")
    pokemon.adjustHeart(-amount)
    scene.pbDisplay(_INTL("{1} se ha vuelto amistoso.\nLa puerta de su corazón se ha abierto un poco.",pokemon.name))
    pbReadyToPurify(pokemon)
    return true
  end
end

ItemHandlers::UseOnPokemon.add(:JOYSCENT,proc{|item,pokemon,scene|
   pbRaiseHappinessAndReduceHeart(pokemon,scene,500)
})

ItemHandlers::UseOnPokemon.add(:EXCITESCENT,proc{|item,pokemon,scene|
   pbRaiseHappinessAndReduceHeart(pokemon,scene,1000)
})

ItemHandlers::UseOnPokemon.add(:VIVIDSCENT,proc{|item,pokemon,scene|
   pbRaiseHappinessAndReduceHeart(pokemon,scene,2000)
})

ItemHandlers::UseOnPokemon.add(:TIMEFLUTE,proc{|item,pokemon,scene|
   if !pokemon.isShadow?
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     next false
   end
   pokemon.heartgauge=0
   pbReadyToPurify(pokemon)
   next true
})

ItemHandlers::BattleUseOnBattler.add(:JOYSCENT,proc{|item,battler,scene|
   if !battler.isShadow?
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     return false
   end
   if battler.inHyperMode?
     battler.pokemon.hypermode=false
     battler.pokemon.adjustHeart(-300)
     scene.pbDisplay(_INTL("¡{1} ha vuelto en sí gracias al {2}!",battler.pbThis,PBItems.getName(item)))
#     if battler.happiness!=255 || battler.pokemon.heartgauge!=0
#       pbRaiseHappinessAndReduceHeart(battler.pokemon,scene,500)
#     end
     return true
   end
#   return pbRaiseHappinessAndReduceHeart(battler.pokemon,scene,500)
   scene.pbDisplay(_INTL("No tendrá ningún efecto."))
   return false
})

ItemHandlers::BattleUseOnBattler.add(:EXCITESCENT,proc{|item,battler,scene|
   if !battler.isShadow?
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     return false
   end
   if battler.inHyperMode?
     battler.pokemon.hypermode=false
     battler.pokemon.adjustHeart(-300)
     scene.pbDisplay(_INTL("¡{1} ha vuelto en sí gracias al {2}!",battler.pbThis,PBItems.getName(item)))
#     if battler.happiness!=255 || battler.pokemon.heartgauge!=0
#       pbRaiseHappinessAndReduceHeart(battler.pokemon,scene,1000)
#     end
     return true
   end
#   return pbRaiseHappinessAndReduceHeart(battler.pokemon,scene,1000)
   scene.pbDisplay(_INTL("No tendrá ningún efecto."))
   return false
})

ItemHandlers::BattleUseOnBattler.add(:VIVIDSCENT,proc{|item,battler,scene|
   if !battler.isShadow?
     scene.pbDisplay(_INTL("No tendrá ningún efecto."))
     return false
   end
   if battler.inHyperMode?
     battler.pokemon.hypermode=false
     battler.pokemon.adjustHeart(-300)
     scene.pbDisplay(_INTL("¡{1} ha vuelto en sí gracias al {2}!",battler.pbThis,PBItems.getName(item)))
 #    if battler.happiness!=255 || battler.pokemon.heartgauge!=0
#       pbRaiseHappinessAndReduceHeart(battler.pokemon,scene,2000)
#     end
     return true
   end
#   return pbRaiseHappinessAndReduceHeart(battler.pokemon,scene,2000)
   scene.pbDisplay(_INTL("No tendrá ningún efecto."))
   return false
})

def pbApplyEVGain(pokemon,ev,evgain)
  totalev=0
  for i in 0...6
    totalev+=pokemon.ev[i]
  end
  if totalev+evgain>PokeBattle_Pokemon::EVLIMIT # No puede exceder el límite global
    evgain-=totalev+evgain-PokeBattle_Pokemon::EVLIMIT
  end
  if pokemon.ev[ev]+evgain>PokeBattle_Pokemon::EVSTATLIMIT
    evgain-=totalev+evgain-PokeBattle_Pokemon::EVSTATLIMIT
  end
  if evgain>0
    pokemon.ev[ev]+=evgain
  end
end

def pbReplaceMoves(pokemon,move1,move2=0,move3=0,move4=0)
  return if !pokemon
  [move1,move2,move3,move4].each{|move|
     moveIndex=-1
     if move!=0
       # Busca los movimientos dados
       for i in 0...4
         moveIndex=i if pokemon.moves[i].id==move
       end
     end
     if moveIndex==-1
       # Busca un espacio para remplazar el movimiento
       for i in 0...4
         if (pokemon.moves[i].id==0 && move!=0) || (
             pokemon.moves[i].id!=move1 &&
             pokemon.moves[i].id!=move2 &&
             pokemon.moves[i].id!=move3 &&
             pokemon.moves[i].id!=move4)
           # Remplaza el movimiento
           pokemon.moves[i]=PBMove.new(move)
           break
         end
       end
     end
  }
end



class PokeBattle_Pokemon
  attr_accessor :heartgauge
  attr_accessor :shadow
  attr_accessor :hypermode
  attr_accessor :savedev
  attr_accessor :savedexp
  attr_accessor :shadowmoves
  attr_accessor :shadowmovenum
  HEARTGAUGESIZE = 3840

  def hypermode
    return (self.heartgauge==0 || self.hp==0) ? false : @hypermode
  end

  def heartgauge
    @heartgauge=0 if !@heartgauge
    return @heartgauge
  end

  def heartStage
    return 0 if !@shadow
    hg=HEARTGAUGESIZE/5.0
    return ([self.heartgauge,HEARTGAUGESIZE].min/hg).ceil
  end

  def adjustHeart(value)
    if @shadow
      @heartgauge=0 if !@heartgauge
      @heartgauge+=value
      @heartgauge=HEARTGAUGESIZE if @heartgauge>HEARTGAUGESIZE
      @heartgauge=0 if @heartgauge<0
    end
  end

  def isShadow?
    return @heartgauge && @heartgauge>=0 && @shadow
  end

  def makeShadow
    self.shadow=true
    self.heartgauge=HEARTGAUGESIZE
    self.savedexp=0
    self.savedev=[0,0,0,0,0,0]
    self.shadowmoves=[0,0,0,0,0,0,0,0]
    # Retrieve shadow moves
    moves=load_data("Data/shadowmoves.dat") rescue []
    if moves[self.species] && moves[self.species].length>0
      for i in 0...[4,moves[self.species].length].min
        self.shadowmoves[i]=moves[self.species][i]
      end
      self.shadowmovenum=moves[self.species].length
    else
      # Sin movimientos oscuros especiales
      self.shadowmoves[0]=getConst(PBMoves,:SHADOWRUSH)||0
      self.shadowmovenum=1
    end
    for i in 0...4 # Guarda los movimientos viejos
      self.shadowmoves[4+i]=self.moves[i].id
    end
    pbUpdateShadowMoves
  end

  def pbUpdateShadowMoves(allmoves=false)
    if @shadowmoves
      m=@shadowmoves
      if !@shadow
        # Sin movimientos oscuros
        pbReplaceMoves(self,m[4],m[5],m[6],m[7])
        @shadowmoves=nil
      else
        moves=[]
        relearning=[3,3,2,1,1,0][heartStage]
        relearning=3 if allmoves
        relearned=0
        # Agrega todos los movimientos oscuros
        for i in 0...4; moves.push(m[i]) if m[i]!=0; end
        # Agrega X movimientos regulares
        for i in 0...4
          next if i<@shadowmovenum
          if m[i+4]!=0 && relearned<relearning
            moves.push(m[i+4]); relearned+=1
          end
        end
        pbReplaceMoves(self,moves[0]||0,moves[1]||0,moves[2]||0,moves[3]||0)
      end
    end
  end

  alias :__shadow_expeq :exp=

  def exp=(value)
    if self.isShadow?
      @savedexp+=value-self.exp
    else
      __shadow_expeq(value)
    end
  end

  alias :__shadow_hpeq :hp=

  def hp=(value)
     __shadow_hpeq(value)
     @hypermode=false if value<=0
  end
end



def pbReadyToPurify(pokemon)
  return if !pokemon || !pokemon.isShadow?
  pokemon.pbUpdateShadowMoves() 
  if pokemon.heartgauge==0
    Kernel.pbMessage(_INTL("{1} está listo para la purificación!",pokemon.name))
  end
end

Events.onStepTaken+=proc{
   for pkmn in $Trainer.party
     if pkmn.hp>0 && !pkmn.isEgg? && pkmn.heartgauge>0
       pkmn.adjustHeart(-1)
       pbReadyToPurify(pkmn) if pkmn.heartgauge==0
     end
   end
   if ($PokemonGlobal.purifyChamber rescue nil)
     $PokemonGlobal.purifyChamber.update
   end
   for i in 0...2
     pkmn=$PokemonGlobal.daycare[i][0]
     next if !pkmn
     pkmn.adjustHeart(-1)
     pkmn.pbUpdateShadowMoves()
   end
}


=begin
Todos los tipos que no son Oscuros tienen debilidad contra el tipo Oscuro
El tipo Oscuro es poco eficiente contra sí mismo.
Como comentario, los movimientos Oscuros en Colosseum no son afectados por Debilidades ni Resistencias, mientras que en XD, el tipo Oscuro es super efectivo contra todos los otros tipos.
2/5 - muestra naturaleza

XD - Shadow Rush -- 55, 100 - Causa daño.
Colosseum - Shadow Rush -- 90, 100
Si este ataque tiene éxito, el usuario pierde la mitad de los PS que perdió el oponente como resultado del ataque (retroceso).
Si el usuario se encuentra en Retroestado, este ataque tiene alta probabilidad de golpe crítico.
=end


class PokeBattle_Battle
  alias __shadow_pbUseItemOnPokemon pbUseItemOnPokemon

  def pbUseItemOnPokemon(item,pkmnIndex,userPkmn,scene,*arg)
    pokemon=self.party1[pkmnIndex]
    if pokemon.hypermode &&
       !isConst?(item,PBItems,:JOYSCENT) &&
       !isConst?(item,PBItems,:EXCITESCENT) &&
       !isConst?(item,PBItems,:VIVIDSCENT)
      scene.pbDisplay(_INTL("No puede usarse en ese Pokemon."))
      return false
    end
    return __shadow_pbUseItemOnPokemon(item,pkmnIndex,userPkmn,scene,*arg)
  end
end



class PokeBattle_Battler
  alias __shadow_pbInitPokemon pbInitPokemon

  def pbInitPokemon(*arg)
    if self.pokemonIndex>0 && self.inHyperMode? && !isFainted?
      # Llamado sin el Retroestado
      self.pokemon.hypermode=false
      self.pokemon.adjustHeart(-50)
    end
    __shadow_pbInitPokemon(*arg)
    # Llamado en batalla
    if self.isShadow?
      if hasConst?(PBTypes,:SHADOW)
        self.type1=getID(PBTypes,:SHADOW)
        self.type2=getID(PBTypes,:SHADOW)
      end
      self.pokemon.adjustHeart(-30) if @battle.pbOwnedByPlayer?(@index)
    end
  end

  alias __shadow_pbEndTurn pbEndTurn

  def pbEndTurn(*arg)
    __shadow_pbEndTurn(*arg)
    if self.inHyperMode? && !self.battle.pbAllFainted?(self.battle.party1) && 
       !self.battle.pbAllFainted?(self.battle.party2)
      self.battle.pbDisplay(_INTL("¡El ataque en Retroestado hiere a {1}!",self.pbThis(true))) 
      pbConfusionDamage
    end
  end

  def isShadow?
    p=self.pokemon
    if p && p.respond_to?("heartgauge") && p.heartgauge>0
      return true
    end
    return false
  end

  def inHyperMode?
    return false if isFainted?
    p=self.pokemon
    if p && p.respond_to?("hypermode") && p.hypermode
      return true
    end
    return false
  end

  def pbHyperMode
    p=self.pokemon
    if p.isShadow? && !p.hypermode
      if @battle.pbRandom(p.heartgauge)<=PokeBattle_Pokemon::HEARTGAUGESIZE/4
        p.hypermode=true
        @battle.pbDisplay(_INTL("¡{1} se encuentra en un estado emocional estraordinario!\n¡Ha entrado en Retroestado!",self.pbThis))
      end
    end
  end

  def pbHyperModeObedience(move)
    return true if !move
    if self.inHyperMode? && !isConst?(move.type,PBTypes,:SHADOW)
      return rand(10)<8 ? false : true
    end
    return true
  end
end



################################################################################
# Sin efectos secundarios.
# (Soplo Oscuro, Vigor Oscuro, Brío Oscuro, Rabia Oscura, Carga Oscura, Onda Oscura)
# (Shadow Blast, Shadow Blitz, Shadow Break, Shadow Rave, Shadow Rush, Shadow Wave)
################################################################################
class PokeBattle_Move_126 < PokeBattle_Move_000
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Paraliza al objetivo.
# (Rayo Oscuro / Shadow Bolt)
################################################################################
class PokeBattle_Move_127 < PokeBattle_Move_007
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Quema al objetivo.
# (Fuego Oscuro / Shadow Fire)
################################################################################
class PokeBattle_Move_128 < PokeBattle_Move_00A
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Congela al objetivo.
# (Hielo Oscuro / Shadow Chill)
################################################################################
class PokeBattle_Move_129 < PokeBattle_Move_00C
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Confunde al objetivo.
# (Miedo Oscuro / Shadow Panic)
################################################################################
class PokeBattle_Move_12A < PokeBattle_Move_013
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Reduce la Defensa del objetivo en 2 niveles.
# (Ocaso Oscuro / Shadow Down)
################################################################################
class PokeBattle_Move_12B < PokeBattle_Move_04C
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Reduce la evasión del objetivo en 2 niveles.
# (Bruma Oscura / Shadow Mist)
################################################################################
class PokeBattle_Move_12C < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return -1 if !opponent.pbCanReduceStatStage?(PBStats::EVASION,attacker,true,self)
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    ret=opponent.pbReduceStat(PBStats::EVASION,2,attacker,false,self)
    attacker.pbHyperMode if ret
    return ret ? 0 : -1
  end
end




################################################################################
# La potencia se duplica si el objetivo está usando Buceo.
# (Tifón Oscuro / Shadow Storm)
################################################################################
class PokeBattle_Move_12D < PokeBattle_Move_075
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# Ataque de dos turnos. En el primero, reduce por la mitad los OS de todos los Pokémon activos.
# Salta el segundo turno (si es exitoso).
# (Mitad Oscura / Shadow Half)
################################################################################
class PokeBattle_Move_12E < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    affected=[]
    for i in 0...4
      affected.push(i) if @battle.battlers[i].hp>1
    end
    if affected.length==0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return -1
    end
    pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
    for i in affected
      @battle.battlers[i].pbReduceHP((@battle.battlers[i].hp/2).floor)
    end
    @battle.pbDisplay(_INTL("¡Los PS de cada Pokémon se redujeron a la mitad!"))
    attacker.effects[PBEffects::HyperBeam]=2
    attacker.currentMove=@id
    return 0
  end
end



################################################################################
# El objetivo no puede huir o ser cambiado mientras el usuario se encuentre activo.
# (Traba Oscura / Shadow Hold)
################################################################################
class PokeBattle_Move_12F < PokeBattle_Move_0EF
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end
end



################################################################################
# El usuario sufre un daño igual a la mitad de sus PS actuales.
# (Fin Oscuro / Shadow End)
################################################################################
class PokeBattle_Move_130 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    ret=super(attacker,opponent,hitnum,alltargets,showanimation)
    attacker.pbHyperMode if ret>=0
    return ret
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    if !attacker.isFainted? && turneffects[PBEffects::TotalDamage]>0
      attacker.pbReduceHP((attacker.hp/2.0).round)
      @battle.pbDisplay(_INTL("¡{1} es herido por el retroceso!",attacker.pbThis))
    end
  end
end



################################################################################
# Inicia el clima Oscuro.
# (Cielo Oscuro / Shadow Sky)
################################################################################
class PokeBattle_Move_131 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    case @battle.weather
    when PBWeather::HEAVYRAIN
      @battle.pbDisplay(_INTL("¡No hay alivio para este diluvio!"))
      return -1
    when PBWeather::HARSHSUN
      @battle.pbDisplay(_INTL("¡El sol realmente abrazador no ha mermado en absoluto!"))
      return -1
    when PBWeather::SHADOWSKY
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return -1
    end
    pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
    @battle.weather=PBWeather::SHADOWSKY
    @battle.weatherduration=5
    @battle.pbCommonAnimation("ShadowSky",nil,nil)
    @battle.pbDisplay(_INTL("¡El cielo se ha teñido de oscuridad!"))
    return 0
  end
end



################################################################################
# Termina los efectos de Pantalla Luz, Reflejo y Velo Sagrado de ambos lados.
# (Muda Oscura / Shadow Shed)
################################################################################
class PokeBattle_Move_132 < PokeBattle_Move
  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    if @battle.sides[0].effects[PBEffects::Reflect]>0 ||
       @battle.sides[1].effects[PBEffects::Reflect]>0 ||
       @battle.sides[0].effects[PBEffects::LightScreen]>0 ||
       @battle.sides[1].effects[PBEffects::LightScreen]>0 ||
       @battle.sides[0].effects[PBEffects::Safeguard]>0 ||
       @battle.sides[1].effects[PBEffects::Safeguard]>0
      pbShowAnimation(@id,attacker,nil,hitnum,alltargets,showanimation)
      @battle.sides[0].effects[PBEffects::Reflect]=0
      @battle.sides[1].effects[PBEffects::Reflect]=0
      @battle.sides[0].effects[PBEffects::LightScreen]=0
      @battle.sides[1].effects[PBEffects::LightScreen]=0
      @battle.sides[0].effects[PBEffects::Safeguard]=0
      @battle.sides[1].effects[PBEffects::Safeguard]=0
      @battle.pbDisplay(_INTL("¡Se han anulado todas las barreras!"))
      attacker.pbHyperMode
      return 0
    else
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return -1
    end
  end
end