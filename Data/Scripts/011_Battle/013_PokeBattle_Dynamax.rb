class PokeBattle_ActiveSide
  attr_accessor :effects
  
  alias initialize_dynamax initialize
  def initialize
    initialize_dynamax
    # Efectos Dynamax
    @effects[PBEffects::VineLash]   = 0
    @effects[PBEffects::WildFire]   = 0
    @effects[PBEffects::Cannonade]  = 0
    @effects[PBEffects::Volcalith]  = 0
    @effects[PBEffects::Steelsurge] = false
  end
end

class PokeBattle_Battler
  attr_accessor :dynamax
  attr_accessor :gigantamax
  
  alias pbInitEffects_dynamax pbInitEffects
  def pbInitEffects(batonpass)
    pbInitEffects_dynamax(batonpass)
    # Dynamax / Gigantamax
    @effects[PBEffects::Dynamax]    = 0
    @effects[PBEffects::DBoost]     = false
    @effects[PBEffects::DButton]    = false
    @effects[PBEffects::Gigantamax] = 0
    # Max Move Effects
    @effects[PBEffects::MaxGuard]   = false
    @effects[PBEffects::ChiStrike]  = 0
    # Max Special Usage
    @effects[PBEffects::MaxMove1]   = 0
    @effects[PBEffects::MaxMove2]   = 0
    @effects[PBEffects::MaxMove3]   = 0
    @effects[PBEffects::MaxMove4]   = 0
  end


 # Dynamax is compatible with large maps
 def hasDynamax?
    maps = DYNAMAXMAPS # maps for allow Dynamax
    if $game_map && maps.include?($game_map.map_id) &&
      !(self.isConst?(species,PBSpecies,:ZACIAN) ||
        self.isConst?(species,PBSpecies,:ZAMAZENTA) || 
        self.isConst?(species,PBSpecies,:ETERNATUS))
      return true
    end
    return false
  end
  
  def isDynamax?
    if @pokemon
      return (@pokemon.isDynamax? rescue false)
    end
    return false
  end
  
  def makeUnmax
    @pokemon.makeUngigantamax
    @pokemon.makeUndynamax
  end
  
  def hasGigantamax?
    return false if @effects[PBEffects::Transform]
    if @pokemon && @pokemon.gmaxFactor?
      return (@pokemon.hasGigantamaxForm? rescue false)
    end
    return false
  end

  def gmaxFactor?;  return @pokemon && @pokemon.gmaxFactor?;  end
  
  def isGigantamax?
    if @pokemon
      return (@pokemon.isGigantamax? rescue false)
    end
    return false
  end
  
  def pbUndynamax
    if @pokemon
      text = "Dynamax"
      text = "Gigantamax" if isGigantamax?
      text = "Eternamax"  if isConst?(species,PBSpecies,:ETERNATUS)
      oldhp = @hp
      @battle.pbCommonAnimation("UnDynamaxAnimationHere",self,nil)
      @effects[PBEffects::DBoost] = false
      @effects[PBEffects::Dynamax] = 0
      @effects[PBEffects::DButton] = false
      @effects[PBEffects::Gigantamax]=0

      @pokemon.makeUngigantamax
      @pokemon.makeUndynamax
      makeUnmax
      pbUpdate(false)
      @pokemon.pbReversion(true)
      pbUnMaxMove(true)
      @battle.scene.pbChangePokemon(self, @pokemon)
      @battle.scene.pbHPChanged(self,totalhp) if !isFainted?
      @battle.pbDisplay(_INTL("{1}'s {2} energy left its body!",pbThis,text))
      @battle.scene.pbRefresh
      @battle.pbCommonAnimation("UnDynamaxAnimation2Here",self,nil)
    end
  end
  
end

class PokeBattle_Battle
  def pbHasDBand?(battlerIndex)
    return false if !$PokemonBag
    return true if !pbBelongsToPlayer?(battlerIndex)
    for i in DBANDS
      next if !hasConst?(PBItems,i)
      return true if $PokemonBag.pbQuantity(i)>0
    end
    return false
  end
  
  def dynaMax
    return @dynaMax
  end
  
################################################################################
# Dynamax battler.
################################################################################

  def pbCanDynamax?(index)
    return false if $game_switches[NO_DYNAMAX]
    return false if !@battlers[index].hasDynamax?
    #return false if pbIsOpposing?(index) && !@opponent
    return false if !pbHasDBand?(index)
    # If a Poke holding a Mega Stone / Z-Crystal, Dynamax not be able
    # to activate for him!
    return false if @battlers[index].hasZMove?
    return false if @battlers[index].hasMega?
    return false if @rules["noDynamax"]
    side = (pbIsOpposing?(index)) ? 1 : 0
    owner = pbGetOwnerIndex(index)
    return false if @dynaMax[side][owner]!=-1
    return false if @battlers[index].effects[PBEffects::SkyDrop]
    if !pbBelongsToPlayer?(index)
      @battlers[index].pbMaxMove if @battlers[index].pokemon.max_ace
    end
    return true
  end
  
  def pbRegisterDynamax(index)
    side = (pbIsOpposing?(index)) ? 1 : 0
    owner = pbGetOwnerIndex(index)
    @dynaMax[side][owner]=index
  end

  def pbDynamax(index)
    return if !@battlers[index] || !@battlers[index].pokemon
    return if !(@battlers[index].hasDynamax? rescue false)
    return if (@battlers[index].isDynamax? rescue true)
    @scene.pbToggleDataboxes if PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES
    ownername = (pbGetOwner(index).fullname rescue "")
    ownername = pbGetOwner(index).name if pbBelongsToPlayer?(index)
    @battlers[index].effects[PBEffects::Dynamax]=3
    @battlers[index].effects[PBEffects::DBoost]=true
    @scene.pbRecall(index) if pbBelongsToPlayer?(index) || pbIsOpposing?(index) && @opponent
    @battlers[index].pbMaxMove
    # Checking Gigantamax
    if @battlers[index].hasGigantamax?
      @battlers[index].pokemon.makeGigantamax
      @battlers[index].effects[PBEffects::Gigantamax]=3
      @battlers[index].form=@battlers[index].pokemon.form
    end
    @battlers[index].pokemon.makeDynamax
    if pbBelongsToPlayer?(index) || @battlers[index].pbPartner && !pbIsOpposing?(index)
      @scene.pbSendOut(index,@battlers[index].pokemon)
    elsif pbIsOpposing?(index) && @opponent
      @scene.pbTrainerSendOut(index,@battlers[index].pokemon)
    end
    
    oldhp =  @battlers[index].hp
    @battlers[index].pbUpdate(false)
    @scene.pbHPChanged(@battlers[index],oldhp)
    @battlers[index].pokemon.pbReversion(true)
    
    @scene.pbChangePokemon(@battlers[index],@battlers[index].pokemon)
    pbPlayCrySpecies(@battlers[index],100,90)
    maxname=(@battlers[index].pokemon.maxName rescue nil)
    if !maxname || maxname ==""
      maxname = _INTL ("{1}",PBSpecies.getName(@battlers[index].pokemon.species))
    end
    PBDebug.log("[Dynamax] #{@battlers[index].pbThis} became Max #{maxname}") rescue nil
    side = (pbIsOpposing?(index)) ? 1 : 0
    owner = pbGetOwnerIndex(index)
    @dynaMax[side][owner]=-2
    @scene.pbToggleDataboxes(true) if PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES
    
  end
  
end



# Añadir al PokeBattle_Pokemon para guardar movimientos originales
class PokeBattle_Pokemon
  attr_accessor :max_moves_original
  
  alias initialize_maxmoves initialize
  def initialize(*args)
    initialize_maxmoves(*args)
    @max_moves_original = [nil, nil, nil, nil]
  end
  
  # Asegurarse de que siempre está inicializado
  def max_moves_original
    @max_moves_original = [nil, nil, nil, nil] if !@max_moves_original
    return @max_moves_original
  end
end



class PokeBattle_Battler
  
  def pbMaxMove
    # Asegurar que max_moves_original existe
    @pokemon.max_moves_original = [nil, nil, nil, nil] if !@pokemon.max_moves_original
    imposter=isConst?(species,PBSpecies,:DITTO) && isConst?(ability,PBAbilities,:LIMBER)
    for i in 0...4
      # Solo verificar que existe el movimiento y el id, sin comparar con 0
      if @moves[i] && @moves[i].id && @moves[i].id.to_s != "" && !imposter
        # Guardar el movimiento original si no está guardado ya
        if !@pokemon.max_moves_original[i]
          @pokemon.max_moves_original[i] = @pokemon.moves[i]
        end
        # Crear el Max Move basado en el movimiento original
        original_move = PokeBattle_Move.pbFromPBMove(@battle, @pokemon.moves[i])
        @moves[i] = PokeBattle_MaxMove.createMaxMove(@battle, self, @pokemon.moves[i], original_move)
        # Mantener los PP del movimiento original
        @moves[i].pp = @pokemon.moves[i].pp
        @moves[i].totalpp = @pokemon.moves[i].totalpp
      end
    end
    return true
  end

  # Revertir Max Moves a movimientos normales
  def pbUnMaxMove(unmax=false)
    # Asegurar que max_moves_original existe
    @pokemon.max_moves_original = [nil, nil, nil, nil] if !@pokemon.max_moves_original
    for i in 0...4
      # Restaurar movimiento original guardado
      if @pokemon.max_moves_original[i]
        @moves[i] = PokeBattle_Move.pbFromPBMove(@battle, @pokemon.moves[i])
        if unmax
          # Reducir PP del movimiento original según uso
          case i
          when 0
            @pokemon.moves[i].pp -= @effects[PBEffects::MaxMove1] if @effects[PBEffects::MaxMove1]
          when 1
            @pokemon.moves[i].pp -= @effects[PBEffects::MaxMove2] if @effects[PBEffects::MaxMove2]
          when 2
            @pokemon.moves[i].pp -= @effects[PBEffects::MaxMove3] if @effects[PBEffects::MaxMove3]
          when 3
            @pokemon.moves[i].pp -= @effects[PBEffects::MaxMove4] if @effects[PBEffects::MaxMove4]
          end
          @pokemon.moves[i].pp = 0 if @pokemon.moves[i].pp < 0
        end
        @moves[i].pp = @pokemon.moves[i].pp
        @moves[i].totalpp = @pokemon.moves[i].totalpp
        # Limpiar el guardado
        @pokemon.max_moves_original[i] = nil
      elsif @pokemon.moves[i] && @pokemon.moves[i].id  # Verificación sin comparar con 0
        # Fallback: crear desde PBS solo si existe el movimiento
        @moves[i] = PokeBattle_Move.pbFromPBMove(@battle, @pokemon.moves[i])
        @moves[i].pp = @pokemon.moves[i].pp
        @moves[i].totalpp = @pokemon.moves[i].totalpp
      end
    end
    
    # Reiniciar contadores de uso de Max Moves
    if unmax
      @effects[PBEffects::MaxMove1] = 0 if @effects[PBEffects::MaxMove1]
      @effects[PBEffects::MaxMove2] = 0 if @effects[PBEffects::MaxMove2]
      @effects[PBEffects::MaxMove3] = 0 if @effects[PBEffects::MaxMove3]
      @effects[PBEffects::MaxMove4] = 0 if @effects[PBEffects::MaxMove4]
    end
  end
  
end

class PokeBattle_Move
  attr_accessor(:dynamax)
end

class PokeBattle_MaxMove < PokeBattle_Move
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
  attr_accessor(:dynamax)
  attr_reader(:original_move_id)
################################################################################
# Creating a Max Move - MÉTODO ESTÁTICO PARA CREAR SIN USAR
################################################################################
  def self.createMaxMove(battle, battler, pbmove, original_move)
    # Crear el Max Move
    maxmove = self.new(battle, battler, original_move, pbmove, true)
    return maxmove
  end

  # Retornar el ID del movimiento original para compatibilidad
  def id
    return @original_move_id if @original_move_id
    return @id
  end

################################################################################
# Initialize - Modificado para soportar creación simple
################################################################################
  def initialize(battle, battler, move, pbmove=nil, simple=false)
    @battle     = battle
    @oldmove    = move
    @oldname    = move.name
    @status     = move.pbIsStatus?
    
    # Obtener datos del movimiento
    if pbmove
      oldmovedata = PBMoveData.new(pbmove.id)
      @type       = move.type
      @target     = move.target
      @category   = oldmovedata.category
    else
      @type       = move.type
      @target     = move.target
      @category   = move.category rescue 0
    end
    @original_move_id = pbmove ? pbmove.id : move.id
    
    @id         = pbMaxMoveId(move, battler)
    @name       = pbMaxMoveName(move, battler)
    @function   = pbMaxMoveFunction(move, battler)
    @basedamage = @status ? 0 : pbMaxMoveBaseDamage(move)
    @accuracy   = 0
    @addlEffect = 0
    @priority   = 0
    @flags      = pbMaxMoveFlags(move, battler)
    
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
    
    @pp         = move.pp
    @totalpp    = move.totalpp
    @thismove   = self
    @dynamax    = true
    
    # Si es creación simple (desde pbMaxMove), no ejecutar el movimiento
    return if simple
    
    # Código original de ejecución (no debería ejecutarse en uso normal)
    moveMaxname = @name

    battler.pbBeginTurn(self)
    if !@status
      @battle.pbDisplayBrief(_INTL("¡{1} ha usado un Movimiento Dinamax!",battler.pbThis))
      @battle.pbDisplayBrief(_INTL("¡{1}!",moveMaxname)) if moveMaxname
    end
  end

  def pbMaxMoveId(oldmove, battler)
    if @status
      return "MAXGUARD"
    else
      # Check for Gigantamax moves
      if battler.hasGigantamax?
        gmaxmove = pbGetGigantamaxMove(battler, oldmove.type)
        return gmaxmove if gmaxmove
      end
      
      # Regular Max Moves based on type
      case oldmove.type
      when 0  ; return "MAXSTRIKE"
      when 1  ; return "MAXKNUCKLE"
      when 2  ; return "MAXAIRSTREAM"
      when 3  ; return "MAXOOZE"
      when 4  ; return "MAXQUAKE"
      when 5  ; return "MAXROCKFALL"
      when 6  ; return "MAXFLUTTERBY"
      when 7  ; return "MAXPHANTASM"
      when 8  ; return "MAXSTEELSPIKE"
      when 10 ; return "MAXFLARE"
      when 11 ; return "MAXGEYSER"
      when 12 ; return "MAXOVERGROWTH"
      when 13 ; return "MAXLIGHTNING"
      when 14 ; return "MAXMINDSTORM"
      when 15 ; return "MAXHAILSTORM"
      when 16 ; return "MAXWYRMWIND"
      when 17 ; return "MAXDARKNESS"
      when 18 ; return "MAXSTARFALL"
      end
    end
    return "MAXSTRIKE" # Fallback
  end

  def pbGetGigantamaxMove(battler, type)
    species = battler.species
    if isConst?(species,PBSpecies,:CHARIZARD) && type==10
      return "GMAXWILDFIRE"
    elsif isConst?(species,PBSpecies,:BUTTERFREE) && type==6
      return "GMAXBEFUDDLE"
    elsif isConst?(species,PBSpecies,:PIKACHU) && type==13
      return "GMAXVOLTCRASH"
    elsif isConst?(species,PBSpecies,:MEOWTH) && type==0
      return "GMAXGOLDRUSH"
    elsif isConst?(species,PBSpecies,:MACHAMP) && type==1
      return "GMAXCHISTRIKE"
    elsif isConst?(species,PBSpecies,:GENGAR) && type==7
      return "GMAXTERROR"
    elsif isConst?(species,PBSpecies,:KINGLER) && type==11
      return "GMAXFOAMBURST"
    elsif isConst?(species,PBSpecies,:LAPRAS) && type==11
      return "GMAXRESONANCE"
    elsif isConst?(species,PBSpecies,:EEVEE) && type==0
      return "GMAXCUDDLE"
    elsif isConst?(species,PBSpecies,:SNORLAX) && type==0
      return "GMAXREPLENISH"
    elsif isConst?(species,PBSpecies,:GARBODOR) && type==3
      return "GMAXMALODOR"
    elsif isConst?(species,PBSpecies,:MELMETAL) && type==8
      return "GMAXMELTDOWN"
    elsif isConst?(species,PBSpecies,:CORVIKNIGHT) && type==2
      return "GMAXWINDRAGE"
    elsif isConst?(species,PBSpecies,:ORBEETLE) && type==14
      return "GMAXGRAVITAS"
    elsif isConst?(species,PBSpecies,:DREDNAW) && type==11
      return "GMAXSTONESURGE"
    elsif isConst?(species,PBSpecies,:COALOSSAL) && type==5
      return "GMAXVOLCALITH"
    elsif isConst?(species,PBSpecies,:FLAPPLE) && type==12
      return "GMAXTARTNESS"
    elsif isConst?(species,PBSpecies,:APPLETUN) && type==12
      return "GMAXSWEETNESS"
    elsif isConst?(species,PBSpecies,:SANDACONDA) && type==4
      return "GMAXSANDBLAST"
    elsif isConst?(species,PBSpecies,:TOXTRICITY) && type==13
      return "GMAXSTUNSHOCK"
    elsif isConst?(species,PBSpecies,:CENTISKORCH) && type==10
      return "GMAXCENTIFERNO"
    elsif isConst?(species,PBSpecies,:HATTERENE) && type==14
      return "GMAXSMITE"
    elsif isConst?(species,PBSpecies,:GRIMMSNARL) && type==17
      return "GMAXSNOOZE"
    elsif isConst?(species,PBSpecies,:ALCREMIE) && type==18
      return "GMAXFINALE"
    elsif isConst?(species,PBSpecies,:COPPERAJAH) && type==8
      return "GMAXSTEELSURGE"
    elsif isConst?(species,PBSpecies,:DURALUDON) && type==8
      return "GMAXDEPLETION"
    elsif isConst?(species,PBSpecies,:ETERNATUS) && type==3
      return "GMAXETERNBEAM"
    elsif isConst?(species,PBSpecies,:VENUSAUR) && type==12
      return "GMAXVINELASH"
    elsif isConst?(species,PBSpecies,:BLASTOISE) && type==11
      return "GMAXCANNONADE"
    elsif isConst?(species,PBSpecies,:URSHIFU)
      return "GMAXRAPIDFLOW" if type==11
      return "GMAXONEBLOW" if type==17
    elsif isConst?(species,PBSpecies,:RILLABOOM) && type==12
      return "GMAXDRUMSOLO"
    elsif isConst?(species,PBSpecies,:CINDERACE) && type==10
      return "GMAXFIREBALL"
    elsif isConst?(species,PBSpecies,:INTELEON) && type==11
      return "GMAXHYDROSNIPE"
    elsif isConst?(species,PBSpecies,:MELMETAL) && type==8
      return "GMAXMELTDOWN"
    end
    return nil
  end

  def pbMaxMoveName(oldmove, battler)
    if @status
      return $PokemonSystem.language !=1 ? _INTL("Maxibarrera") : "Max Guard"
    else
      moveid = pbMaxMoveId(oldmove, battler)
      case moveid
      when "MAXSTRIKE"       ; return $PokemonSystem.language !=1 ? _INTL("Maxiataque")   : "Max Strike"
      when "MAXKNUCKLE"      ; return $PokemonSystem.language !=1 ? _INTL("Maxipuño")     : "Max Knuckle"
      when "MAXAIRSTREAM"    ; return $PokemonSystem.language !=1 ? _INTL("Maxiciclón")   : "Max Airstream"
      when "MAXOOZE"         ; return $PokemonSystem.language !=1 ? _INTL("Maxiácido")    : "Max Ooze"
      when "MAXQUAKE"        ; return $PokemonSystem.language !=1 ? _INTL("Maxitemblor")  : "Max Quake"
      when "MAXROCKFALL"     ; return $PokemonSystem.language !=1 ? _INTL("Maxilito")     : "Max Rockfall"
      when "MAXFLUTTERBY"    ; return $PokemonSystem.language !=1 ? _INTL("Maxinsecto")   : "Max Flutterby"
      when "MAXPHANTASM"     ; return $PokemonSystem.language !=1 ? _INTL("Maxiespectro") : "Max Phantasm"
      when "MAXSTEELSPIKE"   ; return $PokemonSystem.language !=1 ? _INTL("Maximetal")    : "Max Steelspike"
      when "MAXFLARE"        ; return $PokemonSystem.language !=1 ? _INTL("Maxignición")  : "Max Flare"
      when "MAXGEYSER"       ; return $PokemonSystem.language !=1 ? _INTL("Maxichorro")   : "Max Geyser"
      when "MAXOVERGROWTH"   ; return $PokemonSystem.language !=1 ? _INTL("Maxiflora")    : "Max Overgrowth"
      when "MAXLIGHTNING"    ; return $PokemonSystem.language !=1 ? _INTL("Maxitormenta") : "Max Lightning"
      when "MAXMINDSTORM"    ; return $PokemonSystem.language !=1 ? _INTL("Maxionda")     : "Max Mindstorm"
      when "MAXHAILSTORM"    ; return $PokemonSystem.language !=1 ? _INTL("Maxihelada")   : "Max Hailstorm"
      when "MAXWYRMWIND"     ; return $PokemonSystem.language !=1 ? _INTL("Maxidraco")    : "Max Wyrmwind"
      when "MAXDARKNESS"     ; return $PokemonSystem.language !=1 ? _INTL("Maxisombra")   : "Max Darkness"
      when "MAXSTARFALL"     ; return $PokemonSystem.language !=1 ? _INTL("Maxiestela")   : "Max Starfall"
      when "GMAXWILDFIRE"    ; return $PokemonSystem.language !=1 ? _INTL("Gigallamarada")     : "G-Max Wildfire"
      when "GMAXBEFUDDLE"    ; return $PokemonSystem.language !=1 ? _INTL("Gigaestupor"): "G-Max Befuddle"
      when "GMAXVOLTCRASH"   ; return $PokemonSystem.language !=1 ? _INTL("Gigatronada")   : "G-Max Volt Crash"
      when "GMAXGOLDRUSH"    ; return $PokemonSystem.language !=1 ? _INTL("Gigamonedas")  : "G-Max Gold Rush"
      when "GMAXCHISTRIKE"   ; return $PokemonSystem.language !=1 ? _INTL("Gigapuñición")     : "G-Max Chi Strike"
      when "GMAXTERROR"      ; return $PokemonSystem.language !=1 ? _INTL("Gigaeaparición")  : "G-Max Terror"
      when "GMAXFOAMBURST"   ; return $PokemonSystem.language !=1 ? _INTL("Gigaespuma")   : "G-Max Foam Burst"
      when "GMAXRESONANCE"   ; return $PokemonSystem.language !=1 ? _INTL("Gigarmelodía") : "G-Max Resonance"
      when "GMAXCUDDLE"      ; return $PokemonSystem.language !=1 ? _INTL("Gigaternura")   : "G-Max Cuddle"
      when "GMAXREPLENISH"   ; return $PokemonSystem.language !=1 ? _INTL("Gigarreciclaje")  : "G-Max Replenish"
      when "GMAXMALODOR"     ; return $PokemonSystem.language !=1 ? _INTL("Gigapestilencia") : "G-Max Malodor"
      when "GMAXMELTDOWN"    ; return $PokemonSystem.language !=1 ? _INTL("Gigafundido")   : "G-Max Meltdown"
      when "GMAXWINDRAGE"    ; return $PokemonSystem.language !=1 ? _INTL("Gigahuracán")   : "G-Max Wind Rage"
      when "GMAXGRAVITAS"    ; return $PokemonSystem.language !=1 ? _INTL("Gigabóveda") : "G-Max Gravitas"
      when "GMAXSTONESURGE"  ; return $PokemonSystem.language !=1 ? _INTL("Gigatrampa rocas"): "G-Max Stonesurge"
      when "GMAXVOLCALITH"   ; return $PokemonSystem.language !=1 ? _INTL("Gigarroca ígnea")   : "G-Max Volcalith"
      when "GMAXTARTNESS"    ; return $PokemonSystem.language !=1 ? _INTL("Gigacorrosión")   : "G-Max Tartness"
      when "GMAXSWEETNESS"   ; return $PokemonSystem.language !=1 ? _INTL("Giganéctar")   : "G-Max Sweetness"
      when "GMAXSANDBLAST"   ; return $PokemonSystem.language !=1 ? _INTL("Gigapolvareda")    : "G-Max Sandblast"
      when "GMAXSTUNSHOCK"   ; return $PokemonSystem.language !=1 ? _INTL("Gigadescarga")   : "G-Max Stun Shock"
      when "GMAXCENTIFERNO"  ; return $PokemonSystem.language !=1 ? _INTL("Gigacienfuegos") : "G-Max Centiferno"
      when "GMAXSMITE"       ; return $PokemonSystem.language !=1 ? _INTL("Gigacastigo")  : "G-Max Smite"
      when "GMAXSNOOZE"      ; return $PokemonSystem.language !=1 ? _INTL("Gigasopor"): "G-Max Snooze"
      when "GMAXFINALE"      ; return $PokemonSystem.language !=1 ? _INTL("Gigacolofón")  : "G-Max Finale"
      when "GMAXSTEELSURGE"  ; return $PokemonSystem.language !=1 ? _INTL("Gigatrampa acero")    : "G-Max Steelsurge"
      when "GMAXDEPLETION"   ; return $PokemonSystem.language !=1 ? _INTL("Gigadesgaste") : "G-Max Depletion"
      when "GMAXETERNBEAM"   ; return $PokemonSystem.language !=1 ? _INTL("Rayo Infinito") : "Eternabeam"
      when "GMAXVINELASH"    ; return $PokemonSystem.language !=1 ? _INTL("Gigalianas")    : "G-Max Vine Lash"
      when "GMAXCANNONADE"   ; return $PokemonSystem.language !=1 ? _INTL("Gigacañonazo")    : "G-Max Cannonade"
      when "GMAXRAPIDFLOW"   ; return $PokemonSystem.language !=1 ? _INTL("Gigagolpe fluido") : "G-Max Rapid Flow"
      when "GMAXONEBLOW"     ; return $PokemonSystem.language !=1 ? _INTL("Gigagolpe brusco")  : "G-Max One Blow"
      when "GMAXDRUMSOLO"    ; return $PokemonSystem.language !=1 ? _INTL("Gigarredoble")  : "G-Max Drum Solo"
      when "GMAXFIREBALL"    ; return $PokemonSystem.language !=1 ? _INTL("Gigaesfera ígnea") : "G-Max Fireball"
      when "GMAXHYDROSNIPE"  ; return $PokemonSystem.language !=1 ? _INTL("Gigadisparo") : "G-Max Hydrosnipe"
      end
    end
    return $PokemonSystem.language !=1 ? _INTL("Maxiataque") : "Max Strike"
  end

  def pbMaxMoveFunction(oldmove, battler)
    return @status ? oldmove.function : "MAX"
  end

  def pbMaxMoveBaseDamage(oldmove)
    check = oldmove.basedamage
    
    case oldmove.id
    when getID(PBMoves,:MEGADRAIN)    ; return 90
    when getID(PBMoves,:WEATHERBALL)  ; return 130
    when getID(PBMoves,:HEX)          ; return 130
    when getID(PBMoves,:GEARGRIND)    ; return 140
    when getID(PBMoves,:VCREATE)      ; return 150
    when getID(PBMoves,:FLYINGPRESS)  ; return 130
    when getID(PBMoves,:COREENFORCER) ; return 130
    end
    
    return 90 if check < 40
    return 100 if check < 50
    return 110 if check < 60
    return 120 if check < 70
    return 130 if check < 100
    return 140 if check < 140
    return 150
  end

  def pbMaxMoveFlags(oldmove, battler)
    return @status ? oldmove.flags : ""
  end

################################################################################
# PokeBattle_Move Features
################################################################################
  def pbIsSpecial?(type)
    return @oldmove.pbIsSpecial?(type)
  end

  def pbIsPhysical?(type)
    return @oldmove.pbIsPhysical?(type)
  end

  def pbEffectAfterHit(attacker,opponent,turneffects)
    pbMaxMoveSecondaryEffect(attacker,opponent)
  end

  def pbEffect(attacker,opponent,hitnum=0,alltargets=nil,showanimation=true)
    return 0 if !opponent
    if @status
      attacker.effects[PBEffects::MaxGuard]=true
      @battle.pbDisplay(_INTL("¡{1} se protegió!",attacker.pbThis))
      return 0
    end
    damage=pbCalcDamage(attacker,opponent)
    if opponent.damagestate.typemod!=0
      pbShowAnimation(@name,attacker,opponent,hitnum,alltargets,showanimation)
    end
    damage=pbReduceHPDamage(damage,attacker,opponent)
    pbEffectMessages(attacker,opponent)
    pbOnDamageLost(damage,attacker,opponent)
    attacker.lastRoundMoved=@battle.turncount
    return damage
  end

  def pbModifyDamage(damagemult,attacker,opponent)
    if !opponent.effects[PBEffects::ProtectNegation] && (opponent.pbOwnSide.effects[PBEffects::MatBlock] ||
      opponent.effects[PBEffects::Protect] || opponent.effects[PBEffects::SpikyShield])
      if !opponent.effects[PBEffects::MaxGuard]
        @battle.pbDisplay(_INTL("¡{1} no pudo protegerse completamente!",opponent.pbThis))
        return (damagemult/4).floor
      else
        return 0
      end
    else
      return damagemult
    end
  end
  
  def pbMaxMoveSecondaryEffect(attacker,opponent)
    return if !@id
    case @id
    when "MAXGUARD"
    @priority = 4
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
    # Verificar si el último movimiento fue un movimiento de protección
    # Si lastMoveUsed es un String (Max Move), resetear ProtectRate
    if  @id == "MAXGUARD"
      
    elsif attacker.lastMoveUsed >= 0
      # Es un movimiento normal - verificar si es un movimiento de protección
      lastMoveData = PBMoveData.new(attacker.lastMoveUsed)
      if !ratesharers.include?(lastMoveData.function)
        attacker.effects[PBEffects::ProtectRate]=1
      end
    else # No hay último movimiento válido
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
    else
      attacker.effects[PBEffects::Protect]=true
      attacker.effects[PBEffects::ProtectRate]*=2
      attacker.effects[PBEffects::MaxGuard]=true
      @battle.pbAnimation(getConst(PBMoves,:PROTECT),attacker,nil)
      @battle.pbDisplay(_INTL("¡{1} se está protegiendo!",attacker.pbThis))
    end
  when "MAXKNUCKLE"
      if attacker.pbCanIncreaseStatStage?(PBStats::ATTACK,false)
        attacker.pbIncreaseStat(PBStats::ATTACK,1,false,true,nil,true)
        if attacker.pbPartner && !attacker.pbPartner.isFainted?
          attacker.pbPartner.pbIncreaseStat(PBStats::ATTACK,1,false,true,nil,true)
        end
      end
    when "MAXAIRSTREAM"
      if attacker.pbCanIncreaseStatStage?(PBStats::SPEED,false)
        attacker.pbIncreaseStat(PBStats::SPEED,1,false,true,nil,true)
        if attacker.pbPartner && !attacker.pbPartner.isFainted?
          attacker.pbPartner.pbIncreaseStat(PBStats::SPEED,1,false,true,nil,true)
        end
      end
    when "MAXOOZE"
      opponent.pbReduceStat(PBStats::SPATK,1,false,true,nil,true) if opponent.pbCanReduceStatStage?(PBStats::SPATK,false)
    when "MAXQUAKE"
      opponent.pbReduceStat(PBStats::SPDEF,1,false,true,nil,true) if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false)
    when "MAXSTEELSPIKE"
      if attacker.pbCanIncreaseStatStage?(PBStats::DEFENSE,false)
        attacker.pbIncreaseStat(PBStats::DEFENSE,1,false,true,nil,true)
        if attacker.pbPartner && !attacker.pbPartner.isFainted?
          attacker.pbPartner.pbIncreaseStat(PBStats::DEFENSE,1,false,true,nil,true)
        end
      end
    when "MAXFLARE"
      @battle.weather = PBWeather::SUNNYDAY
      @battle.weatherduration = 5
      @battle.pbCommonAnimation("Sunny",nil,nil)
      @battle.pbDisplay(_INTL("¡La luz del sol se intensificó!"))
    when "MAXGEYSER"
      @battle.weather = PBWeather::RAINDANCE
      @battle.weatherduration = 5
      @battle.pbCommonAnimation("Rain",nil,nil)
      @battle.pbDisplay(_INTL("¡Empezó a llover!"))
    when "MAXOVERGROWTH"
      @battle.field.effects[PBEffects::GrassyTerrain] = 5
      @battle.pbAnimation(getConst(PBMoves,:GRASSYTERRAIN),attacker,nil) rescue nil
      @battle.pbDisplay(_INTL("¡Hierba empezó a crecer bajo los pies de todos!"))
    when "MAXLIGHTNING"
      @battle.field.effects[PBEffects::ElectricTerrain] = 5
      @battle.pbAnimation(getConst(PBMoves,:ELECTRICTERRAIN),attacker,nil) rescue nil
      @battle.pbDisplay(_INTL("¡Una corriente eléctrica recorrió el campo de batalla!"))
    when "MAXMINDSTORM"
      @battle.field.effects[PBEffects::PsychicTerrain] = 5
      @battle.pbAnimation(getConst(PBMoves,:PSYCHICTERRAIN),attacker,nil) rescue nil
      @battle.pbDisplay(_INTL("¡El campo de batalla se volvió muy extraño!"))
    when "MAXHAILSTORM"
      @battle.weather = PBWeather::HAIL
      @battle.weatherduration = 5
      @battle.pbCommonAnimation("Hail",nil,nil)
      @battle.pbDisplay(_INTL("¡Empezó a nevar!"))
    when "MAXSTARFALL"
      @battle.field.effects[PBEffects::MistyTerrain] = 5
      @battle.pbAnimation(getConst(PBMoves,:MISTYTERRAIN),attacker,nil) rescue nil
      @battle.pbDisplay(_INTL("¡Niebla cubrió el campo de batalla!"))
    when "MAXPHANTASM"
      opponent.pbReduceStat(PBStats::DEFENSE,1,false,true,nil,true) if opponent.pbCanReduceStatStage?(PBStats::DEFENSE,false)
    when "MAXSTRIKE"
      opponent.pbReduceStat(PBStats::SPEED,1,false,true,nil,true) if opponent.pbCanReduceStatStage?(PBStats::SPEED,false)
    when "MAXDARKNESS"
      opponent.pbReduceStat(PBStats::SPDEF,1,false,true,nil,true) if opponent.pbCanReduceStatStage?(PBStats::SPDEF,false)
################################################################################
#     GMAX MOVES
################################################################################
    when "GMAXWILDFIRE"  # Charizard Gigantamax
      if attacker.pbOpposingSide.effects[PBEffects::WildFire]==0
        attacker.pbOpposingSide.effects[PBEffects::WildFire]=4
        if !opponent.isFainted?
          @battle.pbAnimation(getConst(PBMoves,:FIRESPIN),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en el fuego!", opponent.pbThis))
        end
      end
    when "GMAXVINELASH"  # Venusaur Gigantamax
      # Daño residual de tipo Planta durante 4 turnos (no-Planta)
      if attacker.pbOpposingSide.effects[PBEffects::VineLash]==0
        attacker.pbOpposingSide.effects[PBEffects::VineLash]=4
        if !opponent.isFainted?
          @battle.pbAnimation(getConst(PBMoves,:VINEWHIP),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en las enredaderas!", opponent.pbThis))
        end
      end
    when "GMAXCANNONADE"  # Blastoise Gigantamax
      # Daño residual de tipo Agua durante 4 turnos (no-Agua)
      if attacker.pbOpposingSide.effects[PBEffects::Cannonade]==0
        attacker.pbOpposingSide.effects[PBEffects::Cannonade]=4
        if !opponent.isFainted?
          @battle.pbAnimation(getConst(PBMoves,:WHIRLPOOL),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} se ve arrastrado por la corriente!", opponent.pbThis))
        end
      end
    when "GMAXBEFUDDLE" # Butterfree Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.damagestate.substitute
          @battle.pbAnimation(getConst(PBMoves,:SPORE),i,nil) rescue nil
          case @battle.pbRandom(2)
          when 0
            if i.pbCanPoison?(attacker,false,self)
              i.pbPoison(attacker)
            end
          when 1
            if i.pbCanSleep?(attacker,false,self)
              i.pbSleep
            end
          when 2
            if i.pbCanParalyze?(attacker,false,self)
              i.pbParalyze(attacker)
            end
          end
        end
      end
    when "GMAXVOLTCRASH"   # Pikachu Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.damagestate.substitute
          if i.pbCanParalyze?(attacker,false,self)
            i.pbParalyze(attacker)
          end
        end
      end
    when "GMAXGOLDRUSH"   # Meowth Gigantamax
      if opponent.damagestate.calcdamage>0
        if @battle.pbOwnedByPlayer?(attacker.index)
          @battle.extramoney+=5*attacker.level
          @battle.extramoney=MAXMONEY if @battle.extramoney>MAXMONEY
        end
        @battle.pbDisplay(_INTL("¡Hay monedas por todas partes!"))
      end
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.pbCanConfuse?(attacker,true,self)
          i.pbConfuse
          @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",i.pbThis))
        end
      end
    when "GMAXCHISTRIKE"   # Machamp Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.effects[PBEffects::ChiStrike]
          i.effects[PBEffects::ChiStrike]+=1
          @battle.pbAnimation(getConst(PBMoves,:FOCUSENERGY),i,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} se está preparando para luchar!",i.pbThis))
        end
      end
    when "GMAXTERROR"   # Gengar Gigantamax
      if opponent.damagestate.calcdamage>0 && !opponent.damagestate.substitute &&
          !opponent.isFainted?
        if opponent.effects[PBEffects::MeanLook]<0 &&
            (!USENEWBATTLEMECHANICS || !opponent.pbHasType?(:GHOST))
          opponent.effects[PBEffects::MeanLook]=attacker.index
          @battle.pbDisplay(_INTL("¡{1} no puede escapar!",opponent.pbThis))
        end
      end
    when "GMAXFOAMBURST"   # Kingler Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.pbCanReduceStatStage?(PBStats::SPEED,false)
          i.pbReduceStat(PBStats::SPEED,2,false,true,nil,true)
        end
      end
    when "GMAXRESONANCE"   # Lapras Gigantamax
      if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]==0
        attacker.pbOwnSide.effects[PBEffects::AuroraVeil]=5
        attacker.pbOwnSide.effects[PBEffects::AuroraVeil]=8 if attacker.hasWorkingItem(:LIGHTCLAY)
        @battle.pbAnimation(getConst(PBMoves,:AURORAVEIL),attacker,nil) rescue nil
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡{1} subió la Defensa y la Defensa Especial de tu equipo!",@name))
        else
          @battle.pbDisplay(_INTL("¡{1} subió la Defensa y la Defensa Especial del equipo enemigo!",@name))
        end
      end
    when "GMAXCUDDLE"   # Eevee Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        i.pbCanAttract?(attacker)
      end
    when "GMAXREPLENISH"   # Snorlax Gigantamax
      for i in [attacker,attacker.pbPartner]
        next if !i || i.isFainted?
        item=i.pokemon.itemRecycle
        itemname=PBItems.getName(item)
        i.item=item
        if !@battle.opponent          # En una batalla con salvaje
          i.pokemon.itemInitial=item if i.pokemon.itemInitial==0
        end
        i.pokemon.itemRecycle=0
        i.effects[PBEffects::PickupItem]=0
        i.effects[PBEffects::PickupUse]=0
        @battle.pbAnimation(getConst(PBMoves,:RECYCLE),i,nil) rescue nil
        @battle.pbDisplay(_INTL("¡{1} encontró una {2}!",attacker.pbThis,itemname))
      end
    when "GMAXMALODOR"   # Garbordor Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.damagestate.substitute
          if i.pbCanPoison?(attacker,false,self)
            i.pbPoison(attacker)
          end
        end
      end
    when "GMAXMELTDOWN"   # Melmetal Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.effects[PBEffects::Torment]
          @battle.pbAnimation(getConst(PBMoves,:TORMENT),i,nil) rescue nil
          i.effects[PBEffects::Torment]=true
        end
      end
    when "GMAXDRUMSOLO"  # Rillaboom Gigantamax (fuego, ignora habilidades)
      # TODO:
    when "GMAXFIREBALL"  # Cinderace Gigantamax (fuego, ignora habilidades)
      # TODO:
    when "GMAXHYDROSNIPE"  # Inteleon Gigantamax (agua, ignora habilidades)
      # TODO:
    when "GMAXWINDRAGE" # Corviknight Gigantamax
      @battle.pbAnimation(getConst(PBMoves,:DEFOG),opponent,nil) rescue nil
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
    when "GMAXGRAVITAS"  # Orbeetle
      @battle.pbAnimation(getConst(PBMoves,:GRAVITY),opponent,nil) rescue nil
      if @battle.field.effects[PBEffects::Gravity]>0
        @battle.field.effects[PBEffects::Gravity]=5
        for i in 0...4
          poke=@battle.battlers[i]
          next if !poke
          if PBMoveData.new(poke.effects[PBEffects::TwoTurnAttack]).function==0xC9 || # Fly
             PBMoveData.new(poke.effects[PBEffects::TwoTurnAttack]).function==0xCC || # Bounce
             PBMoveData.new(poke.effects[PBEffects::TwoTurnAttack]).function==0xCE    # Sky Drop
            poke.effects[PBEffects::TwoTurnAttack]=0
          end
          poke.effects[PBEffects::SkyDrop]=false if poke.effects[PBEffects::SkyDrop]
          poke.effects[PBEffects::MagnetRise]=0 if poke.effects[PBEffects::MagnetRise]>0
          poke.effects[PBEffects::Telekinesis]=0 if poke.effects[PBEffects::Telekinesis]>0
        end
        @battle.pbDisplay(_INTL("¡Se ha incrementado la Gravedad!"))
      end
    when "GMAXSTONESURGE"   # Drednaw Gigantamax
      if opponent && !attacker.pbOpposingSide.effects[PBEffects::StealthRock]
        @battle.pbAnimation(getConst(PBMoves,:STEALTHROCK),opponent,nil) rescue nil
        attacker.pbOpposingSide.effects[PBEffects::StealthRock] = true
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡El equipo enemigo está rodeado de piedras puntiagudas!"))
        else
          @battle.pbDisplay(_INTL("¡Tu equipo está rodeado de piedras puntiagudas!"))
        end
      end
    when "GMAXVOLCALITH"  # Coalosal Gigantamax
      if attacker.pbOpposingSide.effects[PBEffects::Volcalith]==0
        attacker.pbOpposingSide.effects[PBEffects::Volcalith]=4
        if !opponent.isFainted?
          @battle.pbAnimation(getConst(PBMoves,:ROCKTOMB),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} fue rodeado de rocas!", opponent.pbThis))
        end
      end
    when "GMAXTARTNESS"   # Flapple Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.pbCanReduceStatStage?(PBStats::EVASION,false)
          i.pbReduceStat(PBStats::EVASION,1,false,true,nil,true)
        end
      end
    when "GMAXSWEETNESS"  # Appletun Gigantamax
      # Cura problemas de estado de los aliados
      for i in [attacker,attacker.pbPartner]
        next if !i || i.isFainted?
        next if i.status < 1
        @battle.pbAnimation(getConst(PBMoves,:AROMATHERAPY),opponent,nil) rescue nil
        oldstatus = i.status
        i.status = 0
        i.statusCount = 0
        case oldstatus
        when PBStatuses::SLEEP
          @battle.pbDisplay(_INTL("¡{1} se despertó!", i.pbThis))
        when PBStatuses::POISON
          @battle.pbDisplay(_INTL("¡{1} se curó del veneno!", i.pbThis))
        when PBStatuses::BURN
          @battle.pbDisplay(_INTL("¡{1} se curó de la quemadura!", i.pbThis))
        when PBStatuses::PARALYSIS
          @battle.pbDisplay(_INTL("¡{1} se curó de la parálisis!", i.pbThis))
        when PBStatuses::FROZEN
          @battle.pbDisplay(_INTL("¡{1} se descongeló!", i.pbThis))
        end
      end
    when "GMAXSANDBLAST"   # Sandaconda Gigantamax
      if opponent.damagestate.calcdamage>0 && !opponent.isFainted? &&
         !opponent.damagestate.substitute
        if opponent.effects[PBEffects::MultiTurn]==0
          opponent.effects[PBEffects::MultiTurn]=5+@battle.pbRandom(2)
          if attacker.hasWorkingItem(:GRIPCLAW)
            opponent.effects[PBEffects::MultiTurn]=(USENEWBATTLEMECHANICS) ? 8 : 6
          end
          opponent.effects[PBEffects::MultiTurnAttack]=@id
          opponent.effects[PBEffects::MultiTurnUser]=attacker.index
          @battle.pbAnimation(getConst(PBMoves,:SANDTOMB),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} quedó atrapado en Bucle Arena!",opponent.pbThis))
        end
      end
    when "GMAXSTUNSHOCK" # Toxtricity Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.damagestate.substitute
          case @battle.pbRandom(1)
          when 0
            if i.pbCanPoison?(attacker,false,self)
              i.pbPoison(attacker)
            end
          when 1
            if i.pbCanParalyze?(attacker,false,self)
              i.pbParalyze(attacker)
            end
          end
        end
      end
    when "GMAXCENTIFERNO"   # Centiskorch Gigantamax
      if opponent.damagestate.calcdamage>0 && !opponent.isFainted? &&
         !opponent.damagestate.substitute
        if opponent.effects[PBEffects::MultiTurn]==0
          opponent.effects[PBEffects::MultiTurn]=5+@battle.pbRandom(2)
          if attacker.hasWorkingItem(:GRIPCLAW)
            opponent.effects[PBEffects::MultiTurn]=(USENEWBATTLEMECHANICS) ? 8 : 6
          end
          opponent.effects[PBEffects::MultiTurnAttack]=@id
          opponent.effects[PBEffects::MultiTurnUser]=attacker.index
          @battle.pbAnimation(getConst(PBMoves,:FIRESPIN),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡{1} fue atrapado en el torbellino!",opponent.pbThis))
        end
      end
    when "GMAXSMITE" # Hatterene Gigantamax
      for i in [opponent,opponent.pbPartner]
        next if !i || i.isFainted?
        if !i.pbCanConfuse?(attacker,true,self)
          i.pbConfuse
          @battle.pbDisplay(_INTL("¡{1} se encuentra confuso!",i.pbThis))
        end
      end
    when "GMAXSNOOZE"   # Grimmsnarl Gigantamax
      if opponent.effects[PBEffects::Yawn]==0 && @battle.pbRandom(10)<5
        opponent.effects[PBEffects::Yawn]=2
        @battle.pbAnimation(getConst(PBMoves,:YAWN),attacker,nil) rescue nil
        @battle.pbDisplay(_INTL("¡{1} adormeció a {2}!",attacker.pbThis,opponent.pbThis(true)))
      end
    when "GMAXFINALE"  # Alcremie Gigantamax
      fullHP=false
      for i in [attacker,attacker.pbPartner]
        next if !i || i.isFainted?
        if i.hp==i.totalhp
          @battle.pbDisplay(_INTL("¡Los PS de {1} están al máximo!",i.pbThis))
          fullHP=true
          next
        end
        i.pbRecoverHP((i.totalhp/6).round,true)
        @battle.pbDisplay(_INTL("{1} recuperó salud.",i.pbThis))
      end
    when "GMAXSTEELSURGE"   # Coperajah Gigantamax
      if opponent && !attacker.pbOpposingSide.effects[PBEffects::Steelsurge]
        attacker.pbOpposingSide.effects[PBEffects::Steelsurge] = true
        @battle.pbAnimation(getConst(PBMoves,:STEALTHROCK),opponent,nil) rescue nil
        if !@battle.pbIsOpposing?(attacker.index)
          @battle.pbDisplay(_INTL("¡El equipo enemigo está rodeado de piezas de acero puntiagudas!"))
        else
          @battle.pbDisplay(_INTL("¡Tu equipo está rodeado de piezas de acero puntiagudas!"))
        end
      end
    when "GMAXDEPLETION"   # Duraludon Gigantamax
      for i in opponent.moves
        if i.id==opponent.lastMoveUsed && i.id>0 && i.pp>0
          pbShowAnimation(@id,attacker,opponent,hitnum,alltargets,showanimation)
          reduction=[2,i.pp].min
          i.pp-=reduction
          @battle.pbAnimation(getConst(PBMoves,:SPITE),opponent,nil) rescue nil
          @battle.pbDisplay(_INTL("¡Se redujeron los PP de {2} de {1} en {3}!",opponent.pbThis(true),i.name,reduction))
          return 0
        end
      end
    when "GMAXRAPIDFLOW", "GMAXONEBLOW"  # Urshifu Gigantamax
      opponent.effects[PBEffects::ProtectNegation]=true
      opponent.pbOwnSide.effects[PBEffects::CraftyShield]=false
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

  def pbShowAnimation(movename,user,target,hitnum=0,alltargets=nil,showanimation=true)
    return if !showanimation
    animname=movename.to_s.delete(" ").delete("-").upcase
    animations=load_data("Data/PkmnAnimations.rxdata")
    
    # Intentar encontrar la animación específica del Max Move
    for i in 0...animations.length
      if @battle.pbBelongsToPlayer?(user.index)
        if animations[i] && animations[i].name=="MaxMove:"+animname
          @battle.scene.pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
          return
        end
      else
        if animations[i] && animations[i].name=="OppMaxMove:"+animname
          @battle.scene.pbAnimationCore(animations[i],target,(user!=nil) ? user : target)
          return
        elsif animations[i] && animations[i].name=="MaxMove:"+animname
          @battle.scene.pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
          return
        end
      end
    end
    
    # Si no se encontró animación específica, usar animación de respaldo según el tipo
    fallback = pbGetMaxMoveFallbackAnimation(@id)
    if fallback
      for i in 0...animations.length
        if @battle.pbBelongsToPlayer?(user.index)
          if animations[i] && animations[i].name==fallback
            @battle.scene.pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
            return
          end
        else
          oppfallback = "Opp#{fallback}"
          if animations[i] && animations[i].name==oppfallback
            @battle.scene.pbAnimationCore(animations[i],target,(user!=nil) ? user : target)
            return
          elsif animations[i] && animations[i].name==fallback
            @battle.scene.pbAnimationCore(animations[i],user,(target!=nil) ? target : user)
            return
          end
        end
      end
    end
  end
  
  def pbGetMaxMoveFallbackAnimation(moveid)
    # Mapeo de Max Moves a animaciones de respaldo existentes
    fallbacks = {
      # Max Moves regulares
      "MAXSTRIKE"     => "Move:GIGAIMPACT",       # Normal
      "MAXKNUCKLE"    => "Move:CLOSECOMBAT",      # Lucha
      "MAXAIRSTREAM"  => "Move:HURRICANE",        # Volador
      "MAXOOZE"       => "Move:SLUDGEBOMB",       # Veneno
      "MAXQUAKE"      => "Move:EARTHQUAKE",       # Tierra
      "MAXROCKFALL"   => "Move:STONEEDGE",        # Roca
      "MAXFLUTTERBY"  => "Move:BUGBUZZ",          # Bicho
      "MAXPHANTASM"   => "Move:SHADOWBALL",       # Fantasma
      "MAXSTEELSPIKE" => "Move:FLASHCANNON",      # Acero
      "MAXFLARE"      => "Move:BLASTBURN",        # Fuego
      "MAXGEYSER"     => "Move:HYDROCANNON",      # Agua
      "MAXOVERGROWTH" => "Move:FRENZYPLANT",      # Planta
      "MAXLIGHTNING"  => "Move:THUNDER",          # Eléctrico
      "MAXMINDSTORM"  => "Move:PSYCHOBOOST",      # Psíquico
      "MAXHAILSTORM"  => "Move:BLIZZARD",         # Hielo
      "MAXWYRMWIND"   => "Move:DRACOMETEOR",      # Dragón
      "MAXDARKNESS"   => "Move:NIGHTDAZE",        # Siniestro
      "MAXSTARFALL"   => "Move:MOONBLAST",        # Hada
      "MAXGUARD"      => "Move:PROTECT",          # Maxibarrera
      
      # G-Max Moves
      "GMAXWILDFIRE"    => "Move:FIERYDANCE",     # Charizard
      "GMAXBEFUDDLE"    => "Move:BUGBUZZ",        # Butterfree
      "GMAXVOLTCRASH"   => "Move:THUNDER",        # Pikachu
      "GMAXGOLDRUSH"    => "Move:PAYDAY",         # Meowth
      "GMAXCHISTRIKE"   => "Move:CLOSECOMBAT",    # Machamp (Chi Strike)
      "GMAXTERROR"      => "Move:SHADOWBALL",     # Gengar
      "GMAXFOAMBURST"   => "Move:SURF",           # Kingler
      "GMAXRESONANCE"   => "Move:SPARKLINGARIA",  # Lapras
      "GMAXCUDDLE"      => "Move:PLAYROUGH",      # Eevee
      "GMAXREPLENISH"   => "Move:GIGAIMPACT",     # Snorlax
      "GMAXMALODOR"     => "Move:GUNKSHOT",       # Garbodor
      "GMAXMELTDOWN"    => "Move:FLASHCANNON",    # Melmetal
      "GMAXWINDRAGE"    => "Move:HURRICANE",      # Corviknight
      "GMAXGRAVITAS"    => "Move:GRAVITY",        # Orbeetle
      "GMAXSTONESURGE"  => "Move:STEALTHROCK",    # Drednaw
      "GMAXVOLCALITH"   => "Move:LAVAPLUME",      # Coalossal
      "GMAXTARTNESS"    => "Move:APPLEACID",      # Appletun
      "GMAXSANDBLAST"   => "Move:SANDSTORM",      # Sandaconda
      "GMAXSTUNSHOCK"   => "Move:THUNDER",        # Toxtricity
      "GMAXCENTIFERNO"  => "Move:FIRELASH",       # Centiskorch
      "GMAXSMITE"       => "Move:PSYCHIC",        # Hatterene
      "GMAXSNOOZE"      => "Move:DARKPULSE",      # Grimmsnarl
      "GMAXFINALE"      => "Move:DAZZLINGGLEAM",  # Alcremie
      "GMAXSTEELSURGE"  => "Move:STEELBEAM",      # Copperajah
      "GMAXDEPLETION"   => "Move:DRACOMETEOR",    # Duraludon
      "GMAXETERNBEAM"   => "Move:ETERNABEAM",     # Eternatus
      
      "GMAXVINELASH"    => "Move:FRENZYPLANT",      
      "GMAXCANNONADE"   => "Move:HYDROCANNON",      
      "GMAXRAPIDFLOW"   => "Move:HYDROCANNON",    
      "GMAXONEBLOW"     => "Move:NIGHTDAZE",      
      "GMAXDRUMSOLO"    => "Move:DRUMBEATING",      
      "GMAXFIREBALL"    => "Move:PYROBALL",      
      "GMAXHYDROSNIPE"  => "Move:SNIPESHOT",      
    }
    return fallbacks[moveid] if fallbacks[moveid]
    # Si no hay mapeo específico, usar animación genérica basada en tipo
    if moveid && moveid.include?("MAX")
      return "Move:GIGAIMPACT"  # Animación genérica por defecto
    end
    return nil
  end
end

#Movimiento para Zacian, Zamazenta y Eternatus.
class PokeBattle_Move_D890 < PokeBattle_Move
  def pbBaseDamage(basedmg,attacker,opponent)
    if opponent.isDynamax?
      return basedmg*2
    end
    return basedmg
  end
end