################################################################################
#             ***************************************************              #
#             *** MENÚ DE INFO EN COMBATE - VERSIÓN MEJORADA ***               #
#             ***************************************************              #
# Versión original adaptada para PE V16.3 por Skyflyer. 
# Basado en el script de bo4p5687.
# Editado por Clara para BES
################################################################################
module BattleInfoConfig
  # Configuración de visibilidad
  MOSTRAR_PS_RIVAL = true
  MOSTRAR_HABILIDAD_RIVAL = true
  MOSTRAR_OBJETO_RIVAL = true
  
  # Colores
  INFO_BASE_COLOR = Color.new(80,80,88)
  INFO_SHADOW_COLOR = Color.new(160,160,168)
  INFO2_BASE_COLOR = Color.new(252,252,252)
  INFO2_SHADOW_COLOR = Color.new(88,88,88)
end
module PokeBattle_SceneConstants
  INFOBUTTON_X        = 6
  INFOBUTTON_Y        = 288 - 48
end

class PokeBattle_Scene
  def pbShowBattleInfo(scene)
    # Ocultar databoxes si es necesario
    pbToggleDataboxes if defined?(PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES) &&
                         PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES
    # Mostrar escena de información
    sceneInfo = BattleInfoScene.new(scene)
    sceneInfo.main
    # Restaurar databoxes
    pbToggleDataboxes(true) if defined?(PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES) &&
                               PokeBattle_SceneConstants::HIDE_DATABOXES_DURING_MOVES
  end
end

#===============================================================================
# Clase principal de la escena de información de batalla
#===============================================================================
class BattleInfoScene
  attr_reader :sprites, :viewport, :battle, :position, :show_details
  
  def initialize(battle)
    @battle = battle
    @sprites = {}
    @position = 0
    @show_details = false
    @exit = false
    @current_scene = 1
    @last_detail_position = nil
    @effect_scroll_index = 0
    @effect_scroll_timer = 0
    @effect_scroll_delay = 60  # Frames entre rotaciones (60 = 1 segundo a 60 FPS)
    # Crear viewport
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    # Obtener datos de batalla
    @player_battlers = get_battlers(false)
    @opponent_battlers = get_battlers(true)
    @all_battlers = @player_battlers + @opponent_battlers
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
  
  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  #-----------------------------------------------------------------------------
  # Obtener battlers activos
  #-----------------------------------------------------------------------------
  def get_battlers(opposing)
    battlers = []
    @battle.battlers.each do |b|
      next unless b && !b.fainted?
      next unless b.pbIsOpposing?(0) == opposing
      battlers.push(b)
    end
    return battlers
  end
  
  #-----------------------------------------------------------------------------
  # Crear sprites
  #-----------------------------------------------------------------------------
  def create_sprites
    # Imagen de fondo (Scene_1 o Scene_2)
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = Bitmap.new("Graphics/Pictures/Battle/Scene_1")
    @sprites["bg"].z = 1
    # Overlay para texto
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["overlay"].z = 10
    pbSetSystemFont(@sprites["overlay"].bitmap)
    create_selection_panel
    create_arrows
  end
  
  #-----------------------------------------------------------------------------
  # Panel de selección
  #-----------------------------------------------------------------------------  
  def create_selection_panel
    @all_battlers.each_with_index do |battler, i|
      # Sprite del panel
      @sprites["panel_#{i}"] = Sprite.new(@viewport)
      @sprites["panel_#{i}"].bitmap = Bitmap.new("Graphics/Pictures/Battle/Choose")
      @sprites["panel_#{i}"].src_rect.height = @sprites["panel_#{i}"].bitmap.height / 2
      @sprites["panel_#{i}"].z = 3
      
      # Calcular posición según número de battlers
      is_player = i < @player_battlers.length
      
      y = is_player ? Graphics.height/2 - 38 : 70
      # 1v1: Un panel arriba (rival) y otro abajo (jugador)
      x = Graphics.width / 2 - @sprites["panel_#{i}"].src_rect.width / 2
      unless @all_battlers.length == 2
        # Batalla doble: 2 arriba (rivales) y 2 abajo (jugadores)
        if is_player
          local_index = i
        else
          local_index = i - @player_battlers.length
        end
        if @opponent_battlers.length > 1 || @player_battlers.length > 1
          x = (Graphics.width/2 + 16) - (local_index * Graphics.width/2  - 8)
        end
      end
      @sprites["panel_#{i}"].x = x
      @sprites["panel_#{i}"].y = y
    end
    create_pokemon_icons
  end
  
  #-----------------------------------------------------------------------------
  # Crear iconos de Pokémon(para la primera pantalla)
  #-----------------------------------------------------------------------------
  def create_pokemon_icons
    @all_battlers.each_with_index do |battler, i|
      next unless @sprites["panel_#{i}"]
      # Obtener el Pokémon a mostrar (considerar Illusion)
      display_pkmn = get_display_pokemon(battler)
      
      @sprites["icon_#{i}"].dispose if @sprites["icon_#{i}"]
      @sprites["icon_#{i}"] = PokemonIconSprite.new(display_pkmn, @viewport)
      @sprites["icon_#{i}"].x = @sprites["panel_#{i}"].x
      @sprites["icon_#{i}"].y = @sprites["panel_#{i}"].y
      @sprites["icon_#{i}"].z = @sprites["panel_#{i}"].z+1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Crear flechas de navegación
  #-----------------------------------------------------------------------------
  def create_arrows
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 6, @viewport)
    @sprites["leftarrow"].x = 4
    @sprites["leftarrow"].y = 16
    @sprites["leftarrow"].z = 9
    @sprites["leftarrow"].visible = false
    @sprites["leftarrow"].play

    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 6, @viewport)
    @sprites["rightarrow"].x = Graphics.width - 44
    @sprites["rightarrow"].y = 16
    @sprites["rightarrow"].z = 9
    @sprites["rightarrow"].visible = false
    @sprites["rightarrow"].play
  end
  
  #-----------------------------------------------------------------------------
  # Actualizar sprites
  #-----------------------------------------------------------------------------
  def update_sprites
    pbUpdateSpriteHash(@sprites)
    # Actualizar imagen de fondo según modo
    update_background_image
    # Actualizar paneles de selección
    @all_battlers.each_index do |i|
      next unless @sprites["panel_#{i}"]
      y_offset = (i == @position) ? @sprites["panel_#{i}"].src_rect.height : 0
      @sprites["panel_#{i}"].src_rect.y = y_offset
    end
    # Mostrar/ocultar elementos según modo
    if @show_details
      @sprites["leftarrow"].visible = true
      @sprites["rightarrow"].visible = true
      # Ocultar paneles en vista detallada
      @all_battlers.each_index do |i|
        @sprites["panel_#{i}"].visible = false if @sprites["panel_#{i}"]
      end
      # Mostrar solo el icono del Pokémon seleccionado
      @all_battlers.each_index do |i|
        if @sprites["icon_#{i}"]
          @sprites["icon_#{i}"].visible = (i == @position)
        end
      end
    else
      @sprites["leftarrow"].visible = false
      @sprites["rightarrow"].visible = false
      # Mostrar paneles e iconos en vista de selección
      @all_battlers.each_index do |i|
        @sprites["panel_#{i}"].visible = true if @sprites["panel_#{i}"]
        @sprites["icon_#{i}"].visible = true if @sprites["icon_#{i}"]
      end
    end
    draw_info # Dibujar información
  end
  
  #-----------------------------------------------------------------------------
  # Actualizar imagen de fondo
  #-----------------------------------------------------------------------------
  def update_background_image
    target_scene = @show_details ? 2 : 1
    # Verificar si necesitamos cambiar la imagen
    need_change = false
    if @sprites["bg"].bitmap.nil?
      need_change = true
    else
      # Guardar referencia al nombre actual (usamos una variable de instancia)
      @current_scene ||= 1
      need_change = (@current_scene != target_scene)
    end
    if need_change
      @sprites["bg"].bitmap.dispose if @sprites["bg"].bitmap
      @sprites["bg"].bitmap = Bitmap.new("Graphics/Pictures/Battle/Scene_#{target_scene}")
      @current_scene = target_scene
    end
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar información
  #-----------------------------------------------------------------------------
  def draw_info
    bitmap = @sprites["overlay"].bitmap
    bitmap.clear
    if @show_details
      @sprites["bg"].z = 5
      pbSetNarrowFont(@sprites["overlay"].bitmap)
      draw_detailed_info(bitmap)
    else
      @sprites["bg"].z = 1
      pbSetSystemFont(@sprites["overlay"].bitmap)
      draw_selection_info(bitmap)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Información detallada
  #-----------------------------------------------------------------------------
  def draw_detailed_info(bitmap)
    battler = @all_battlers[@position]
    return unless battler
   
    update_detail_icon(battler) # Actualizar icono grande para vista de detalles
    base = BattleInfoConfig::INFO2_BASE_COLOR
    shadow = BattleInfoConfig::INFO2_SHADOW_COLOR
    base2 = BattleInfoConfig::INFO_BASE_COLOR
    shadow2 = BattleInfoConfig::INFO_SHADOW_COLOR
    is_player = @position < @player_battlers.length
    show_rival_data = is_player || BattleInfoConfig::MOSTRAR_PS_RIVAL
    x_base = 84
    y = 4
    # Nombre y nivel
    pbDrawTextPositions(bitmap, [
      [battler.name, x_base, y, 0, base, shadow],
      [_INTL("Nv. {1}", battler.level), 216, y, 0, base, shadow],
      [_INTL("Turno: {1}", @battle.turncount + 1), 298, y, 0, base, shadow]
    ])
    if show_rival_data# PS
      hp_text = _INTL("PS: {1}/{2}", battler.hp, battler.totalhp)
      pbDrawTextPositions(bitmap, [[hp_text, x_base, 34, 0, base, shadow]])
      # Estado
      if battler.status > 0
        status_bitmap = Bitmap.new("Graphics/Pictures/statuses")
        src_y = (battler.status - 1) * 16
        bitmap.blt(x_base + 100, 40, status_bitmap, Rect.new(0, src_y, 44, 16))
        status_bitmap.dispose
      end
    end
    # Habilidad
    y_ability = 208
    if show_rival_data || BattleInfoConfig::MOSTRAR_HABILIDAD_RIVAL
      ability_name = PBAbilities.getName(battler.ability)
      pbDrawTextPositions(bitmap, [
        [_INTL("Habilidad:"), 24, y_ability, 0, base, shadow],
        [ability_name, 266, y_ability, 1, base2, shadow2]
      ])
    end
    # Objeto
    y_item = y_ability + 30
    if show_rival_data || BattleInfoConfig::MOSTRAR_OBJETO_RIVAL
      item_name = battler.item == 0 ? "---" : PBItems.getName(battler.item)
      pbDrawTextPositions(bitmap, [
        [_INTL("Objeto:"), 24, y_item, 0, base, shadow],
        [item_name, 266, y_item, 1, base2, shadow2]
      ])
    end
    draw_stats(bitmap, battler, x_base, 78)
    draw_weather(bitmap, 24, y_item + 28, base, shadow, base2, shadow2)
    draw_last_move(bitmap, 24, 304, base, shadow, base2, shadow2, battler)
    draw_battle_effects(bitmap, 280, y_ability, base, shadow, base2, shadow2)
    draw_types(bitmap, battler)
  end
  
  #-----------------------------------------------------------------------------
  # Actualizar icono de detalles
  #-----------------------------------------------------------------------------
  def update_detail_icon(battler)
    if @last_detail_position != @position
      @sprites["detail_icon"].dispose if @sprites["detail_icon"]
      display_pkmn = get_display_pokemon(battler)
      @sprites["detail_icon"] = PokemonIconSprite.new(display_pkmn, @viewport)
      # Posicionar el icono
      @sprites["detail_icon"].x = 16
      @sprites["detail_icon"].y = 0
      @sprites["detail_icon"].z = 9
      @sprites["detail_icon"].visible = true
      @last_detail_position = @position
      # Resetear scroll de efectos al cambiar de Pokémon
      @effect_scroll_index = 0
      @effect_scroll_timer = 0
    end
  end
  
  #-----------------------------------------------------------------------------
  # Obtener el Pokémon a mostrar
  #-----------------------------------------------------------------------------
  def get_display_pokemon(battler)
    if battler.effects[PBEffects::Illusion]
      illusion_battler = battler.effects[PBEffects::Illusion]
      # Verificar que el battler de ilusión tiene un pokemon válido
      return illusion_battler.pokemon if illusion_battler.respond_to?(:pokemon) && illusion_battler.pokemon
      return illusion_battler if illusion_battler.is_a?(PokeBattle_Pokemon)
    end
    return battler.pokemon if battler.respond_to?(:pokemon)
    return battler
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar estadísticas
  #-----------------------------------------------------------------------------
  def draw_stats(bitmap, battler, x_base, y_start)
    base = BattleInfoConfig::INFO2_BASE_COLOR
    shadow = BattleInfoConfig::INFO2_SHADOW_COLOR
    
    stats = [
      [PBStats::ATTACK,   PBStats.getName(1,true)],
      [PBStats::DEFENSE,  PBStats.getName(2,true)],
      [PBStats::SPATK,    PBStats.getName(4,true)],
      [PBStats::SPDEF,    PBStats.getName(5,true)],
      [PBStats::SPEED,    PBStats.getName(3,true)],
      [PBStats::ACCURACY, PBStats.getName(6,true)],
      [PBStats::EVASION,  PBStats.getName(7,true)]
    ]
    
    point_bmp = Bitmap.new("Graphics/Pictures/Battle/Point")
    inc_bmp = Bitmap.new("Graphics/Pictures/Battle/Increase")
    dec_bmp = Bitmap.new("Graphics/Pictures/Battle/Decrease")
    
    stats.each_with_index do |(stat_id, stat_name), i|
      x = (i % 2 == 0) ? 24 : 280
      y = y_start + (i / 2) * 30
      pbDrawTextPositions(bitmap, [[stat_name, x, y, 0, base, shadow]])
      stage = battler.stages[stat_id]# Cambios de stat
      draw_stat_changes(bitmap, x + 86, y, stage, point_bmp, inc_bmp, dec_bmp)
    end
    
    # Críticos (debajo de Precisión, columna derecha)
    crit_stage = get_critical_stage(battler)
    x = 280
    y = y_start + 3 * 30  # Fila 4 (índice 3) = debajo de Precisión
    pbDrawTextPositions(bitmap, [[_INTL("Crítico"), x, y, 0, base, shadow]])
    draw_stat_changes(bitmap, x + 86, y, crit_stage, point_bmp, inc_bmp, dec_bmp, 4)
    point_bmp.dispose
    inc_bmp.dispose
    dec_bmp.dispose
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar cambios de estadísticas
  #-----------------------------------------------------------------------------
  def draw_stat_changes(bitmap, x, y, stage, point_bmp, inc_bmp, dec_bmp, max_stage = 6)
    if stage > 0
      stage.abs.times do |j|
        bitmap.blt(x + 20 * j, y, inc_bmp, Rect.new(0, 0, 30, 30))
      end
    elsif stage < 0
      stage.abs.times do |j|
        bitmap.blt(x + 20 * j, y, dec_bmp, Rect.new(0, 0, 30, 30))
      end
    end
    remaining = max_stage - stage.abs
    if remaining > 0
      remaining.times do |j|
        bitmap.blt(x + 20 * (max_stage - remaining + j), y, point_bmp, Rect.new(0, 0, 30, 30))
      end
    end
  end
  

  
  #-----------------------------------------------------------------------------
  # Dibujar tipos
  #-----------------------------------------------------------------------------
  def draw_types(bitmap, battler)
    poke = get_display_pokemon(battler)
    if poke.respond_to?(:type1)
      type1 = poke.type1; type2 = poke.type2
    else
      type1 = battler.type1; type2 = battler.type2
    end
    types_bmp = Bitmap.new("Graphics/Pictures/types")
    x = Graphics.width - 98
    if type2 && type2 != type1
      [type1, type2].each_with_index do |type, i|
        src_y = getID(PBTypes, type) * 28
        y = 6 + i * 28
        bitmap.blt(x, y, types_bmp, Rect.new(0, src_y, 64, 28))
      end
    else
      src_y = getID(PBTypes, type1) * 28
      bitmap.blt(x, 16, types_bmp, Rect.new(0, src_y, 64, 28))
    end
    types_bmp.dispose
  end
  #-----------------------------------------------------------------------------
  # Dibujar clima (usando método de battle)
  #-----------------------------------------------------------------------------
  def draw_weather(bitmap, x, y, base, shadow, base2, shadow2)
    weather_text = @battle.active_weather
    pbDrawTextPositions(bitmap, [
      [_INTL("Clima:"), x, y, 0, base, shadow],
      [weather_text, 266, y, 1, base2, shadow2]
    ])
  end
  #-----------------------------------------------------------------------------
  # Dibujar último movimiento
  #-----------------------------------------------------------------------------
  def draw_last_move(bitmap, x, y, base, shadow, base2, shadow2, battler)
    pbDrawTextPositions(bitmap, [
      [_INTL("Último movimiento:"), x, y, 0, base, shadow]
    ])
    move_name = battler.lastMoveUsed == -1 ? "---" : 
                PBMoves.getName(battler.lastMoveUsed)
    pbDrawTextPositions(bitmap, [
      [move_name, x, y + 36, 0, base2, shadow2]
    ])
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar efectos de combate (usando métodos optimizados de battle)
  #-----------------------------------------------------------------------------
  def draw_battle_effects(bitmap, x, y, base, shadow, base2, shadow2)

    # Obtener todos los efectos
    all_effects = get_all_battle_effects
    max_display = 5
    
    # Si hay más efectos que el máximo, rotar
    if all_effects.length > max_display
      # Incrementar timer solo en vista detallada
      if @show_details
        @effect_scroll_timer += 1
        
        # Cuando el timer alcanza el delay, rotar al siguiente grupo
        if @effect_scroll_timer >= @effect_scroll_delay
          @effect_scroll_timer = 0
          @effect_scroll_index = (@effect_scroll_index + max_display) % all_effects.length
        end
      end
      # Obtener el grupo de efectos a mostrar (con wrap-around)
      effects_to_show = []
      max_display.times do |i|
        index = (@effect_scroll_index + i) % all_effects.length
        effects_to_show.push(all_effects[index])
      end
      # Indicador visual de que hay más efectos
      current_page = @effect_scroll_index / max_display + 1
      total_pages = (all_effects.length.to_f / max_display).ceil
      pbDrawTextPositions(bitmap, [
        [_INTL("Efectos de combate: ({1}/{2})", current_page, total_pages), x, y, 0, base, shadow]
      ])
    else
      effects_to_show = all_effects
      # Resetear scroll si cambiamos a menos efectos
      @effect_scroll_index = 0
      @effect_scroll_timer = 0
      pbDrawTextPositions(bitmap, [
        [_INTL("Efectos de combate:"), x, y, 0, base, shadow]
      ])
    end
    

    # Mostrar efectos
    effects_to_show.each_with_index do |effect_text, i|
      pbDrawTextPositions(bitmap, [
        [effect_text, x, y + 28 + (i * 26), 0, base2, shadow2]
      ])
    end
  end
    
  #-----------------------------------------------------------------------------
  # Obtener todos los efectos de batalla (posición, lado y campo)
  #-----------------------------------------------------------------------------
  def get_all_battle_effects
    effects = []
    # 1. Efectos de posición del Pokémon seleccionado
    position_effects = @battle.active_position
    battler_index = @battle.battlers.index(@all_battlers[@position])
    if battler_index && position_effects[battler_index]
      position_effects[battler_index].each_value do |effect_text|
        effects.push(effect_text) if effect_text
      end
    end
    
    # 2. Efectos del lado (jugador/rival)
    is_player = @position < @player_battlers.length
    side_index = is_player ? 0 : 1
    side_effects = @battle.active_side
    
    if side_effects[side_index]
      side_effects[side_index].each_value do |effect_text|
        effects.push(effect_text) if effect_text
      end
    end
    
    # 3. Efectos de campo (afectan a todos)
    field_effects = @battle.active_field
    
    if field_effects
      field_effects.each_value do |effect_text|
        effects.push(effect_text) if effect_text
      end
    end
    return effects
  end
  
  #-----------------------------------------------------------------------------
  # Información de selección
  #-----------------------------------------------------------------------------
  def draw_selection_info(bitmap)
    # Ocultar icono de detalles
    @sprites["detail_icon"].visible = false if @sprites["detail_icon"]
    # Resetear scroll de efectos al salir de vista detallada
    @effect_scroll_index = 0
    @effect_scroll_timer = 0
    base = BattleInfoConfig::INFO2_BASE_COLOR
    shadow = BattleInfoConfig::INFO2_SHADOW_COLOR
    @all_battlers.each_with_index do |battler, i|
      next unless @sprites["panel_#{i}"]
      x = @sprites["panel_#{i}"].x + 68
      y = @sprites["panel_#{i}"].y + 26
      pbDrawTextPositions(bitmap, [
        [battler.name, x, y, 0, base, shadow, true]
      ])
    end
    # Dibujar pokeballs del equipo
    draw_party_balls
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar pokeballs del equipo
  #-----------------------------------------------------------------------------
  def draw_party_balls
    ball_bmp = Bitmap.new("Graphics/Pictures/Battle/battler_ball")
    ball_w = ball_bmp.width / 4
    ball_h = ball_bmp.height
    # Jugador
    ball_x = Graphics.width/2 - (16*@battle.pbParty(0).length)/2
    draw_team_balls(@battle.pbParty(0), ball_x, 246, ball_bmp, ball_w, ball_h, false)
    # Rival
    if @battle.opponent
      ball_x = Graphics.width/2 - (16*@battle.pbParty(1).length)/2
      draw_team_balls(@battle.pbParty(1), ball_x, 40, ball_bmp, ball_w, ball_h, true)
    end
    ball_bmp.dispose
  end
  
  #-----------------------------------------------------------------------------
  # Dibujar balls de un equipo
  #-----------------------------------------------------------------------------
  def draw_team_balls(party, base_x, y, ball_bmp, ball_w, ball_h, is_opponent)
    return unless party
    bitmap = @sprites["overlay"].bitmap
    party.each_with_index do |pkmn, i|
      next if !pkmn || pkmn.isEgg?
      break if i >= 6
      x = base_x + (i * 16)
      # Determinar estado de la ball
      if pkmn.hp == 0
        src_x = 32
      elsif pkmn.status > 0
        src_x = 16
      else
        src_x = 0
      end
      bitmap.blt(x, y, ball_bmp, Rect.new(src_x, 0, ball_w, ball_h))
    end
  end
  
  #-----------------------------------------------------------------------------
  # CONTROLES DENTRO DEL MENÚ
  #-----------------------------------------------------------------------------
  def handle_input
    if Input.trigger?(Input::B)
      pbPlayDecisionSE
      @exit = true
      return
    end
    if Input.trigger?(Input::C)
      pbPlayDecisionSE
      @show_details = !@show_details
      return
    end
    if @show_details
      handle_detail_navigation
    else
      handle_selection_navigation
    end
  end
  
  #-----------------------------------------------------------------------------
  # Pantalla de datos del Pokémon
  #-----------------------------------------------------------------------------
  def handle_detail_navigation
    if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
      pbPlayDecisionSE
      loop do
        if Input.trigger?(Input::LEFT)
          @position = (@position - 1) % @all_battlers.length
        else
          @position = (@position + 1) % @all_battlers.length
        end
        break unless @all_battlers[@position].nil?
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Pantalla de elección del Pokémon
  #-----------------------------------------------------------------------------
  def handle_selection_navigation
    old_pos = @position
    total = @all_battlers.length
    if total == 2 # Si solo hay 2 Pokémon (uno del jugador, uno del rival)
      if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
        @position = (@position == 0) ? 1 : 0
        pbPlayDecisionSE
      end
    else # Si hay más de 2 Pokémon (batalla doble o más)
      if Input.trigger?(Input::RIGHT)
        @position = (@position - 1) % total
        pbPlayDecisionSE
      elsif Input.trigger?(Input::LEFT)
        @position = (@position + 1) % total
        pbPlayDecisionSE
      elsif Input.trigger?(Input::UP)
        # Cambiar entre filas (jugador/rival)
        if @position < @player_battlers.length
          # Estamos en jugador, ir a rival
          offset = @position % @player_battlers.length
          @position = @player_battlers.length + [offset, @opponent_battlers.length - 1].min
        else
          # Estamos en rival, ir a jugador
          offset = (@position - @player_battlers.length) % @opponent_battlers.length
          @position = [offset, @player_battlers.length - 1].min
        end
        pbPlayDecisionSE
      elsif Input.trigger?(Input::DOWN)
        # Cambiar entre filas (rival/jugador)
        if @position < @player_battlers.length
          # Estamos en jugador, ir a rival
          offset = @position % @player_battlers.length
          @position = @player_battlers.length + [offset, @opponent_battlers.length - 1].min
        else
          # Estamos en rival, ir a jugador
          offset = (@position - @player_battlers.length) % @opponent_battlers.length
          @position = [offset, @player_battlers.length - 1].min
        end
        pbPlayDecisionSE
      end
    end
    if @position >= total || @all_battlers[@position].nil?
      @position = old_pos # Validar posición
    end
  end
  
  #-----------------------------------------------------------------------------
  # Obtener nivel de crítico
  #-----------------------------------------------------------------------------
  def get_critical_stage(battler)
    c = 0
    return 4 if battler.effects[PBEffects::LaserFocus] > 0
    c += battler.effects[PBEffects::FocusEnergy]
    c += 1 if battler.hasWorkingAbility(:SUPERLUCK)
    if battler.hasWorkingItem(:STICK) && 
       (isConst?(battler.species, PBSpecies, :FARFETCHD) || 
        isConst?(battler.species, PBSpecies, :SIRFETCHD))
      c += 2
    end
    c += 2 if battler.hasWorkingItem(:LUCKYPUNCH) && 
              isConst?(battler.species, PBSpecies, :CHANSEY)
    c += 1 if battler.hasWorkingItem(:RAZORCLAW)
    c += 1 if battler.hasWorkingItem(:SCOPELENS)
    return [c, 4].min
  end


end


class PokeBattle_Battle

  def array_change_stats_in_battle(side=0)
		ret = {}
		[:player, :opponent].each_with_index { |name, i|
			ret[name] = {
				:name => [],
				:pkmn => []
			}
			@battlers.each_with_index { |pkmn, j|
        next unless pkmn && !pkmn.isFainted? && !pkmn.pbIsOpposing?(i)
				ret[name][:pkmn] << pkmn
			}
		}
		# Name of player
		@battlers.each_with_index { |pkmn, i|
			next unless pkmn && !pkmn.isFainted?
			if i%2==0
				ret[:player][:name] << ""
			else
				next if !@opponent
				ret[:opponent][:name] << ""
			end
		}
		# Player
		return ret[:player] if side == 0
		# Opponent
		return ret[:opponent]
	end
  
	#------------#
	# Get active #
	#------------#
  def active_weather
    return _INTL("Despejado") if pbWeather == 0
    weather_names = {
      PBWeather::SUNNYDAY => _INTL("Sol"),
      PBWeather::RAINDANCE => _INTL("Lluvia"),
      PBWeather::SANDSTORM => _INTL("Torm. arena"),
      #PBWeather::HAIL => _INTL("Granizo"),
      PBWeather::HARSHSUN => _INTL("Sol abrasador"),
      PBWeather::HEAVYRAIN => _INTL("Diluvio"),
      PBWeather::STRONGWINDS => _INTL("Turbulencias"),
      PBWeather::HAIL => _INTL("Nieve")
    }
    
    name = weather_names[pbWeather]
    duration = weatherduration
    
    return name if duration <= 0
    return _INTL("{1} ({2})", name, duration)
  end
  
  def active_field
    ret = {}
    count = 0
    # TERRENOS
    field_effects = field.effects
    terrain_effects = [
      [PBEffects::ElectricTerrain, PBMoves::ELECTRICTERRAIN],
      [PBEffects::GrassyTerrain, PBMoves::GRASSYTERRAIN],
      [PBEffects::MistyTerrain, PBMoves::MISTYTERRAIN],
      [PBEffects::PsychicTerrain, PBMoves::PSYCHICTERRAIN],
    ]
    terrain_effects.each { |effect_id, move_id|
      effect_value = field_effects[effect_id]
      if effect_value > 0
        count += 1
        ret[count.to_s] = _INTL("{1} ({2})", PBMoves.getName(move_id), effect_value.to_s)
      end
    }
    # EFECTOS DE CAMPO
    @field.effects.each_with_index { |effect, i|
      next if effect.nil? || !effect || effect == 0
      count += 1
      effect_name = nil
      begin # Evita crasheos
        case i
        when PBEffects::FairyLock  then effect_name = PBMoves.getName(PBMoves::FAIRYLOCK)
        when PBEffects::Gravity    then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::GRAVITY), effect.to_s)
        when PBEffects::MagicRoom  then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::MAGICROOM), effect.to_s)
        when PBEffects::TrickRoom  then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::TRICKROOM), effect.to_s)
        when PBEffects::WonderRoom then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::WONDERROOM), effect.to_s)
        when PBEffects::CorrosiveGas then effect_name = PBMoves.getName(PBMoves::CORROSIVEGAS)
        when PBEffects::MudSportField then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::MUDSPORT), effect.to_s)
        when PBEffects::WaterSportField then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::WATERSPORT), effect.to_s)
        end
        ret[count.to_s] = effect_name if effect_name
      rescue NameError;end
    }
  
    return ret
  end
  
  def active_side
    ret = [{}, {}]
    
    ret.each_with_index { |_, i|
      side_effects = @sides[i].effects
      count = 0
      side_effects.each_with_index { |effect, j|
        next if effect.nil? || !effect
        count += 1
        effect_name = nil
        begin # Evita crasheos
          # Efectos que no requieren verificación de != 0
          case j
          when PBEffects::StealthRock then effect_name = PBMoves.getName(PBMoves::STEALTHROCK)
          when PBEffects::StickyWeb   then effect_name = PBMoves.getName(PBMoves::STICKYWEB)
          end
          # Efectos que requieren verificación de != 0
          if effect != 0
            case j
            when PBEffects::EchoedVoiceCounter then effect_name = _INTL("Contador Eco Voz ({1})", effect.to_s)
            when PBEffects::AuroraVeil  then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::AURORAVEIL), effect.to_s)
            when PBEffects::LightScreen then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::LIGHTSCREEN), effect.to_s)
            when PBEffects::LuckyChant  then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::LUCKYCHANT), effect.to_s)
            when PBEffects::Reflect     then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::REFLECT), effect.to_s)
            when PBEffects::Safeguard   then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::SAFEGUARD), effect.to_s)
            when PBEffects::Spikes      then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::SPIKES), effect.to_s)
            when PBEffects::Swamp       then effect_name = _INTL("Pantano ({1})", effect.to_s)
            when PBEffects::SeaOfFire   then effect_name = _INTL("Mar de Llamas ({1})", effect.to_s)
            when PBEffects::Rainbow     then effect_name = _INTL("Arcoíris ({1})", effect.to_s)
            when PBEffects::Tailwind    then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::TAILWIND), effect.to_s)
            when PBEffects::ToxicSpikes then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::TOXICSPIKES), effect.to_s)
            when PBEffects::FaintedAlly then effect_name = _INTL("Aliado Derrotado ({1})", effect.to_s)
            end
          end
          # Solo asignar si hay un nombre de efecto válido
          ret[i][count.to_s] = effect_name if effect_name
        rescue NameError;end
      }
    }
    
    return ret
  end
  
  def active_position
    ret = []
    
    player = array_change_stats_in_battle
    opponent = array_change_stats_in_battle(1)
    @pkmn = []
    
    # Optimización: evitar múltiples accesos a arrays
    player_pkmn = player[:pkmn]
    opponent_pkmn = opponent[:pkmn]
    
    player_pkmn.each_with_index { |pkmn, i| @pkmn[2*i] = pkmn }
    opponent_pkmn.each_with_index { |pkmn, i| @pkmn[2*i+1] = pkmn }
    
    @pkmn.each_with_index { |pos, i|
      count = 0
      pkmn = @battlers[i]
      ret[i] = {}
      next unless pkmn && !pkmn.isFainted? && pos
      
      # Pre-calcular wishReady una sola vez
      wishReady = false
      pos_effects = pos.effects
      pos_effects.each_with_index { |effectDX, k|
        if k == PBEffects::Wish && effectDX > 0
          wishReady = true
          break
        end
      }
      
      pos_effects.each_with_index { |effect, j|
        next unless effect
        
        count += 1
        effect_name = nil
        
        begin # Evita crasheos
          case j
          
          when PBEffects::Confusion then effect_name = _INTL("Confuso") if effect != 0
          when PBEffects::Attract then effect_name = _INTL("Enamorado") if effect != -1
          when PBEffects::LeechSeed then effect_name = PBMoves.getName(PBMoves::LEECHSEED) if effect != -1
          when PBEffects::Protect  then effect_name = PBMoves.getName(PBMoves::PROTECT)
          when PBEffects::Substitute  then effect_name = PBMoves.getName(PBMoves::SUBSTITUTE) if effect != 0
          when PBEffects::Bide
            if effect > 0
              venganza = 3 - effect
              effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::BIDE), venganza.to_s) if venganza != 0
            end
          when PBEffects::Rollout
            if effect > 0
              desenrollar = 5 - effect
              effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::ROLLOUT), desenrollar.to_s) if desenrollar != 0
            end
          when PBEffects::WishAmount
            if effect != 0 && wishReady
              effect_name = _INTL("{1} ({2} PS)", PBMoves.getName(PBMoves::WISH), effect.to_s)
            end
          when PBEffects::FutureSight
            if effect != 0
              effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::FUTURESIGHT), effect.to_s)
            end
          when PBEffects::PerishSong, PBEffects::PerishBody
            effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::PERISHSONG), effect.to_s) if effect != 0
          when PBEffects::MeanLook, PBEffects::Octolock, PBEffects::NoRetreat, PBEffects::JawLock
            effect_name = _INTL("Apresado") if effect != -1
          when PBEffects::Curse          then effect_name = _INTL("Maldito")
          when PBEffects::FuryCutter     then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::FURYCUTTER), effect.to_s) if effect != 0
          when PBEffects::Charge         then effect_name = PBMoves.getName(PBMoves::CHARGE) if effect != 0
          when PBEffects::Metronome      then effect_name = _INTL("Atq. Consecutivos ({1})", effect.to_s) if effect != 0
          when PBEffects::DefenseCurl    then effect_name = PBMoves.getName(PBMoves::DEFENSECURL)
          when PBEffects::DestinyBond    then effect_name = PBMoves.getName(PBMoves::DESTINYBOND)
          when PBEffects::Embargo        then effect_name = PBMoves.getName(PBMoves::EMBARGO) if effect != 0
          when PBEffects::Foresight      then effect_name = PBMoves.getName(PBMoves::FORESIGHT)
          when PBEffects::HealBlock      then effect_name = PBMoves.getName(PBMoves::HEALBLOCK) if effect != 0
          when PBEffects::HyperBeam      then effect_name = _INTL("Necesita descansar") if effect != 0
          when PBEffects::Imprison       then effect_name = PBMoves.getName(PBMoves::IMPRISON)
          when PBEffects::Ingrain        then effect_name = PBMoves.getName(PBMoves::INGRAIN)
          when PBEffects::LockOn         then effect_name = PBMoves.getName(PBMoves::LOCKON) if effect != 0
          when PBEffects::MagnetRise     then effect_name = PBMoves.getName(PBMoves::MAGNETRISE) if effect != 0
          when PBEffects::Minimize       then effect_name = PBMoves.getName(PBMoves::MINIMIZE)
          when PBEffects::MiracleEye     then effect_name = PBMoves.getName(PBMoves::MIRACLEEYE)
          when PBEffects::Nightmare      then effect_name = PBMoves.getName(PBMoves::NIGHTMARE)
          when PBEffects::PowerTrick     then effect_name = PBMoves.getName(PBMoves::POWERTRICK)
          when PBEffects::Rage           then effect_name = PBMoves.getName(PBMoves::RAGE)
          when PBEffects::SmackDown      then effect_name = PBMoves.getName(PBMoves::SMACKDOWN)
          when PBEffects::Stockpile      then effect_name = _INTL("{1} ({2})", PBMoves.getName(PBMoves::STOCKPILE), effect.to_s) if effect != 0
          when PBEffects::Taunt          then effect_name = PBMoves.getName(PBMoves::TAUNT) if effect != 0
          when PBEffects::Telekinesis    then effect_name = PBMoves.getName(PBMoves::TELEKINESIS) if effect != 0
          when PBEffects::Transform      then effect_name = PBMoves.getName(PBMoves::TRANSFORM)
          when PBEffects::Unburden       then effect_name = PBMoves.getName(PBMoves::UNBURDEN)
          when PBEffects::Uproar         then effect_name = PBMoves.getName(PBMoves::UPROAR) if effect != 0
          when PBEffects::WeightChange   then effect_name = _INTL("Peso reducido") if effect != 0
          when PBEffects::Yawn           then effect_name = _INTL("Somnoliento") if effect != 0
          when PBEffects::LaserFocus     then effect_name = PBMoves.getName(PBMoves::LASERFOCUS) if effect != 0
          when PBEffects::ThroatChop     then effect_name = _INTL("Silenciado") if effect != 0
          when PBEffects::TarShot        then effect_name = PBMoves.getName(PBMoves::TARSHOT)
          
          # 9 gen
          when PBEffects::RageFist       then effect_name = _INTL("Daño Recibido ({1})", effect.to_s) if effect != 0
          when PBEffects::Commander      then effect_name = PBAbilities.getName(PBAbilities::COMMANDER) if effect != 0
          when PBEffects::GlaiveRush     then effect_name = _INTL("Vulnerable")
          when PBEffects::SaltCure       then effect_name = PBMoves.getName(PBMoves::SALTCURE)
          when PBEffects::SyrupBomb      then effect_name = _INTL("Caramelizado ({1})", effect.to_s) if effect != 0
          when PBEffects::Protosynthesis then effect_name = _INTL("Potenciado") if effect != 0
            
          #Protección tiene menos prioridad.
          when PBEffects::ProtectRate
            if effect != 1
              protsTotales = 0
              numProts = effect
              while numProts > 1
                numProts /= 2
                protsTotales += 1
              end
              effect_name = _INTL("Protegido({1})", protsTotales.to_s)
            end
            
          end
          # Solo asignar si hay un nombre de efecto válido
          ret[i][count.to_s] = effect_name if effect_name
        rescue NameError;end
      }
    }
    
    return ret
  end
  
end