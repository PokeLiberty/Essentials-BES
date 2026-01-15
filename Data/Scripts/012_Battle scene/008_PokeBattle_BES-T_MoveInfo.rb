################################################################################
#             ***************************************************              #
#             ***  SISTEMA DE INFO DE MOVIMIENTOS EN COMBATE  ***              #
#             ***************************************************              #
################################################################################
#===============================================================================
# Clase para mostrar información detallada de movimientos
#===============================================================================
class MoveInfoScene
  attr_reader :sprites, :viewport, :move_id, :battler
  
  def initialize(move_id, battler, battle, initial_index = 0)
    @battle  = battle
    @move_id = move_id
    @battler = battler
    @sprites = {}
    @exit = false
    @current_index = initial_index
    
    # Crear viewport
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    
    # Actualizar datos del movimiento
    update_move_data
  end
  
  #-----------------------------------------------------------------------------
  # Actualizar datos del movimiento actual
  #-----------------------------------------------------------------------------
  def update_move_data
    @move_id = @battler.moves[@current_index].id
    @movedata = PBMoveData.new(@move_id)
    @move_name = PBMoves.getName(@move_id)
    @move_desc = pbGetMessage(MessageTypes::MoveDescriptions, @move_id)
  end
  
  #-----------------------------------------------------------------------------
  # Bucle principal
  #-----------------------------------------------------------------------------
  def main
    create_sprites
    loop do
      Graphics.update
      Input.update
      update_sprites
      handle_input
      break if @exit
    end
    dispose
  end
  
  #-----------------------------------------------------------------------------
  # Crear sprites
  #-----------------------------------------------------------------------------
  def create_sprites
    # Fondo de batalla difuminado
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = Bitmap.new("Graphics/Pictures/Battle/Scene_3")
    @sprites["bg"].z = 1
    
    # Overlay para texto
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["overlay"].z = 10
    pbSetSystemFont(@sprites["overlay"].bitmap)
    
    create_arrows
  end
  
  def create_arrows
    @sprites["leftarrow"] = AnimatedSprite.new(
      "Graphics/Pictures/leftarrow", 8, 40, 28, 6, @viewport
    )
    @sprites["leftarrow"].x = 4
    @sprites["leftarrow"].y = Graphics.height/2
    @sprites["leftarrow"].z = 15
    @sprites["leftarrow"].play
    
    @sprites["rightarrow"] = AnimatedSprite.new(
      "Graphics/Pictures/rightarrow", 8, 40, 28, 6, @viewport
    )
    @sprites["rightarrow"].x = Graphics.width - 44
    @sprites["rightarrow"].y = Graphics.height/2
    @sprites["rightarrow"].z = 15
    @sprites["rightarrow"].play
  end
  
  #-----------------------------------------------------------------------------
  # Actualizar sprites
  #-----------------------------------------------------------------------------
  def update_sprites
    pbUpdateSpriteHash(@sprites)
    draw_info
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar información
  #-----------------------------------------------------------------------------
  def draw_info
    bitmap = @sprites["overlay"].bitmap
    bitmap.clear
    
    base = BattleInfoConfig::INFO2_BASE_COLOR
    shadow = BattleInfoConfig::INFO2_SHADOW_COLOR
    base2 = BattleInfoConfig::INFO_BASE_COLOR
    shadow2 = BattleInfoConfig::INFO_SHADOW_COLOR
    
    x_start = 24
    y = 40
    
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(bitmap, [[@move_name, x_start, y, 0, base, shadow]])
    draw_category_and_type(bitmap,250, y, base, shadow)
    pbSetNarrowFont(@sprites["overlay"].bitmap)
    y = 78
    draw_power_accuracy_pp(bitmap, x_start, y, base, shadow, base2, shadow2)
    draw_target(bitmap, x_start+200+32, y, base, shadow, base2, shadow2)
    y += 128
    pbSetSystemFont(@sprites["overlay"].bitmap)
    draw_flags(bitmap, x_start, y, base, shadow, base2, shadow2)
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar categoría y tipo
  #-----------------------------------------------------------------------------
  def draw_category_and_type(bitmap, x, y, base, shadow)
    # Tipo #Usamos el de la dex pa' rellenar mas. ~Clara
    types_bmp = Bitmap.new("Graphics/Pictures/pokedexTypes")
  
    # Debug
    move_type = MoveTypeHelper.get_move_type(@battler, @battler.moves[@current_index], @battle) rescue @movedata.type 
    
    src_y = getID(PBTypes, move_type) * 32
    bitmap.blt(x, y, types_bmp, Rect.new(0, src_y, 96, 32))
    types_bmp.dispose
    
    category_bmp = Bitmap.new("Graphics/Pictures/category")
    category_type = @movedata.category
    src_y = @movedata.category * 28
    bitmap.blt(x+ 96+ 64 + 16, y+2, category_bmp, Rect.new(0, src_y, 64, 28))
    category_bmp.dispose
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar poder, precisión y PP
  #-----------------------------------------------------------------------------
  def draw_power_accuracy_pp(bitmap, x, y, base, shadow, base2, shadow2)
    power_text = @movedata.basedamage > 0 ? @movedata.basedamage.to_s : "---"
    pbDrawTextPositions(bitmap, [
      [_INTL("Potencia:"), x, y, 0, base, shadow],
      [power_text, 232, y, 1, base2, shadow2]
    ])
    accuracy_text = @movedata.accuracy > 0 ? @movedata.accuracy.to_s : "---"
    pbDrawTextPositions(bitmap, [
      [_INTL("Precisión:"), x, y+30, 0, base, shadow],
      [accuracy_text, 232, y+30, 1, base2, shadow2]
    ])
    pp_text = @movedata.totalpp > 0 ? @movedata.totalpp.to_s : "---"
    pbDrawTextPositions(bitmap, [
      [_INTL("PP:"), x, y+30+30, 0, base, shadow],
      [pp_text, 232, y+30+30, 1, base2, shadow2]
    ])
    priority = @movedata.priority
    priority_text = priority > 0 ? "+#{priority}" : priority.to_s
    pbDrawTextPositions(bitmap, [
      [_INTL("Prioridad:"), x, y+30+30+30, 0, base, shadow],
      [priority_text, 232, y+30+30+30, 1, base2, shadow2]
    ])
  end

  #-----------------------------------------------------------------------------
  # Dibujar objetivo del movimiento
  #-----------------------------------------------------------------------------
  def draw_target(bitmap, x, y, base, shadow, base2, shadow2)
    target_text = case @movedata.target
      when PBTargets::SingleNonUser then _INTL("Un Pokémon adyacente")
      when PBTargets::UserOrPartner then _INTL("Usuario o aliado")
      when PBTargets::RandomOpposing then _INTL("Oponente aleatorio")
      when PBTargets::AllOpposing then _INTL("Todos los oponentes")
      when PBTargets::AllNonUsers then _INTL("Todos excepto usuario")
      when PBTargets::User then _INTL("Usuario")
      when PBTargets::BothSides then _INTL("Ambos lados")
      when PBTargets::UserSide then _INTL("Lado del usuario")
      when PBTargets::OpposingSide then _INTL("Lado enemigo")
      when PBTargets::Partner then _INTL("Aliado")
      when PBTargets::OppositeOpposing then _INTL("Aliado")
      else _INTL("Especial")
    end
    pbDrawTextPositions(bitmap, [
      [_INTL("Objetivo:"), x, y, 0, base, shadow],
      [target_text, x, y+30, 0, base2, shadow2]
    ])
    effect_chance = @movedata.addlEffect      
    effect_text = effect_chance > 0 ? "#{effect_chance}%" : "---"
    pbDrawTextPositions(bitmap, [
      [_INTL("Efecto secundario:"), x, y+30+30, 0, base, shadow],
      [_INTL("{1}", effect_text), x, y+30+30+30, 0, base2, shadow2]
    ])
  end
  #-----------------------------------------------------------------------------
  # Dibujar flags del movimiento
  #-----------------------------------------------------------------------------
  def draw_flags(bitmap, x, y, base, shadow, base2, shadow2)
    flags = []
    # Crear instancia de movimiento para acceder a los métodos
      move = PokeBattle_Move.pbFromPBMove(@battle, PBMove.new(@move_id))
      # Flags especiales
      #flags.push(_INTL("Ignora sustituto")) if move.ignoresSubstitute?(@battler)
      #flags.push(_INTL("Aplasta Minimizar")) if move.tramplesMinimize?
      # Flags básicas usando los métodos de PokeBattle_Move
      flags.push(_INTL("Contacto")) if move.isContactMove?
      flags.push(_INTL("Protegible")) if move.canProtectAgainst?
      flags.push(_INTL("Reflectable")) if move.canMagicCoat?
      flags.push(_INTL("Arrebatable")) if move.canSnatch?
      flags.push(_INTL("Imitable")) if move.canMirrorMove?
      flags.push(_INTL("Retroceso")) if move.canKingsRock?
      flags.push(_INTL("Deshiela")) if move.canThawUser?
      flags.push(_INTL("Crítico+")) if move.hasHighCriticalRate?
      # Flags de tipo de movimiento
      flags.push(_INTL("Mordisco")) if move.isBitingMove?
      flags.push(_INTL("Puño")) if move.isPunchingMove?
      flags.push(_INTL("Sonido")) if move.isSoundBased?
      flags.push(_INTL("Polvo")) if move.isPowderMove?
      flags.push(_INTL("Pulso")) if move.isPulseMove?
      flags.push(_INTL("Bomba")) if move.isBombMove?
      flags.push(_INTL("Corte")) if move.isRazorMove?
      flags.push(_INTL("Danza")) if move.isDanceMove?
      flags.push(_INTL("Viento")) if move.isWindMove?
    flags.push("---") if flags.empty?
    pbDrawTextPositions(bitmap, [
      [_INTL("Características:"), x, y, 0, base, shadow]
    ])
    y += 32
    # Mostrar flags en columnas (máximo 12 para no saturar)
    max_flags = [flags.length, 12].min
    flags[0...max_flags].each_with_index do |flag, i|
      col = i % 3
      row = i / 3
      flag_x = x + 20 + (col * 140)
      flag_y = y + (row * 24)
      pbDrawTextPositions(bitmap, [
        [_INTL("* {1}", flag), flag_x, flag_y, 0, base2, shadow2]
      ])
    end
  end
  
  #-----------------------------------------------------------------------------
  # Manejo de input
  #-----------------------------------------------------------------------------
  def handle_input
    if Input.trigger?(Input::B) || Input.trigger?(Input::C)
      pbPlayCancelSE
      @exit = true
      Input.update
      return
    end
    # Navegación entre movimientos
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      old_index = @current_index
      
      loop do
        if Input.trigger?(Input::LEFT)
          @current_index = (@current_index - 1) % 4
        else
          @current_index = (@current_index + 1) % 4
        end
        break if @battler.moves[@current_index].id != 0
        break if @current_index == old_index
      end
      # Si cambiamos de movimiento, actualizar
      if @current_index != old_index && @battler.moves[@current_index].id != 0
        pbPlayCursorSE
        update_move_data
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Liberar recursos
  #-----------------------------------------------------------------------------
  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Extensión de FightMenuDisplay para mostrar info de movimientos
#===============================================================================
class FightMenuDisplay
  attr_writer :battle
  
  alias move_initialize initialize
  def initialize(battler,viewport=nil)
    @battle
    move_initialize(battler,viewport)
    @statinfo=IconSprite.new(0,0,viewport)
    @statinfo.setBitmap("Graphics/Pictures/Battle/infoStats") if !pbInSafari?
    @statinfo.y=PokeBattle_SceneConstants::INFOBUTTON_Y
    @statinfo.x=PokeBattle_SceneConstants::INFOBUTTON_X
  end

  alias move_info_update update
  def update
    move_info_update
    # Detectar Input::L para mostrar información del movimiento
    if Input.trigger?(Input::L) && @battler
      move = @battler.moves[@index]
      if move && move.id != 0
        show_move_info(move.id,@battle)
      end
    end
  end
  
  def show_move_info(move_id,battle)    
    scene = MoveInfoScene.new(move_id, @battler, battle, @index)
    scene.main
  end
  
    alias move_x x=
    def x=(value)
      move_x(value)
      @statinfo.x=value if @statinfo
    end
  
    alias move_y y=
    def y=(value)
      move_y(value)
      @statinfo.y=value if @statinfo
    end
    
    alias move_z z=
    def z=(value)
      move_z(value)
      @statinfo.z=value if @statinfo
    end
  
    alias move_ox ox=
    def ox=(value)
      move_ox(value)
      @statinfo.ox=value if @statinfo
    end

    alias move_oy oy=
    def oy=(value)
      move_oy(value)
      @statinfo.oy=value if @statinfo
    end
    

    alias move_visible visible=
    def visible=(value)
      move_visible(value)
      @statinfo.visible=value if @statinfo
    end

    alias move_color color=
    def color=(value)
      move_color(value)
      @statinfo.color=value if @statinfo
    end
  
    alias move_dispose dispose
    def dispose
      @statinfo.dispose if @statinfo
      move_dispose
      return if disposed?
    end
    
    alias move_update update
    def update
      move_update
      @statinfo.update if @statinfo
    end
    
end

#===============================================================================
# Move Type Helper Module
#===============================================================================
module MoveTypeHelper
  # Obtiene el tipo real de un movimiento considerando habilidades, clima, etc.
  # @param pokemon [PokeBattle_Pokemon] El Pokémon que usa el movimiento
  # @param move [PokeBattle_Move] El movimiento a evaluar
  # @param battle [PokeBattle_Battle] La batalla actual
  # @return [Integer] El tipo del movimiento
  def self.get_move_type(pokemon, move, battle)
    case move.id
    when PBMoves::WEATHERBALL
      case battle.pbWeather
      when PBWeather::SUNNYDAY, PBWeather::HARSHSUN
        return PBTypes::FIRE
      when PBWeather::RAINDANCE, PBWeather::HEAVYRAIN
        return PBTypes::WATER
      when PBWeather::SANDSTORM
        return PBTypes::ROCK
      when PBWeather::HAIL
        return PBTypes::ICE
      end
    when PBMoves::HIDDENPOWER
      return pbHiddenPower(pokemon.iv)[0]
    when PBMoves::JUDGMENT, PBMoves::MULTIATTACK
      return pokemon.type1
    when PBMoves::TECHNOBLAST
      case pokemon.item
      when PBItems::CHILLDRIVE
        return PBTypes::ICE
      when PBItems::BURNDRIVE
        return PBTypes::FIRE
      when PBItems::DOUSEDRIVE
        return PBTypes::WATER
      when PBItems::SHOCKDRIVE
        return PBTypes::ELECTRIC
      end
    when PBMoves::AURAWHEEL
      return pokemon.form == 0 ? PBTypes::ELECTRIC : PBTypes::DARK
    when PBMoves::TERRAINPULSE
      if battle.field.effects[PBEffects::ElectricTerrain] > 0
        return getConst(PBTypes, :ELECTRIC)
      elsif battle.field.effects[PBEffects::MistyTerrain] > 0
        return getConst(PBTypes, :FAIRY)
      elsif battle.field.effects[PBEffects::PsychicTerrain] > 0
        return getConst(PBTypes, :PSYCHIC)
      elsif battle.field.effects[PBEffects::GrassyTerrain] > 0
        return getConst(PBTypes, :GRASS)
      end
    when PBMoves::TERABLAST
      return pokemon.teratype if (pokemon.isTera? rescue false)
    end
    
    # Habilidad Normalize
    if pokemon.ability == PBAbilities::NORMALIZE
      return PBTypes::NORMAL
    end
    
    # Habilidades que cambian movimientos Normales
    if move.type == PBTypes::NORMAL
      if pokemon.ability == PBAbilities::AERILATE
        return PBTypes::FLYING
      elsif pokemon.ability == PBAbilities::REFRIGERATE
        return PBTypes::ICE
      elsif pokemon.ability == PBAbilities::PIXILATE
        return PBTypes::FAIRY
      elsif pokemon.ability == PBAbilities::GALVANIZE
        return PBTypes::ELECTRIC
      end
    end
    
    # Efectos de campo que cambian movimientos Normales
    if (battle.field.effects[PBEffects::IonDeluge] || 
        battle.field.effects[PBEffects::PlasmaFists]) && 
        isConst?(move.type, PBTypes, :NORMAL)
      return getConst(PBTypes, :ELECTRIC)
    end
    
    # Tipo base del movimiento
    return move.type
  end
end