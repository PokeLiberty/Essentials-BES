#===============================================================================
# ** Map Autoscroll
#-------------------------------------------------------------------------------
# Wachunga
# Version 2 para BES
#===============================================================================
=begin
  BES-T Guia de uso

  # USAR ESTOS PARA MEJOR FUNCIONAMIENTO
  autoscroll_wait(x, y, speed) -> scroll hasta centrar tile x,y (velocidad 4)
  autoscroll_player_wait(speed)-> scroll hasta centrar al jugador (velocidad 4)

  autoscroll(x,y)              -> scroll hasta centrar tile x,y (velocidad 4)
  autoscroll(x,y,speed)        -> speed de 1 a 6
  autoscroll_player(speed)     -> scroll hasta centrar al jugador

  Debe llamarse desde un evento en un LOOP que espere a que termine, ej:

  @__as_done = autoscroll(52,8)
  ~ (Conditional Branch: @__as_done == false) -> Wait 1 frame -> Loop back

  o más simple, usar autoscroll_wait(x,y,speed) que bloquea el evento

  This script supplements the built-in "Scroll Map" event command with the
  aim of simplifying cutscenes (and map scrolling in general). Whereas the
  normal event command requires a direction and number of tiles to scroll,
  Map Autoscroll scrolls the map to center on the tile whose x and y
  coordinates are given.
  
  FEATURES
  - automatic map scrolling to given x,y coordinate (or player)
  - destination is fixed, so it's possible to scroll to same place even if
    origin is variable (e.g. moving NPC)
  - variable speed (just like "Scroll Map" event command)
  - diagonal scrolling supported  
  
  SETUP
  Instead of a "Scroll Map" event command, use the "Call Script" command
  and enter on the following on the first line:
  
  autoscroll(x,y)
  
  (replacing "x" and "y" with the x and y coordinates of the tile to scroll to)
  
  To specify a scroll speed other than the default (4), use:
  
  autoscroll(x,y,speed)
  
  (now also replacing "speed" with the scroll speed from 1-6)
  
  Diagonal scrolling happens automatically when the destination is diagonal
  relative to the starting point (i.e., not directly up, down, left or right).

  To scroll to the player, instead use the following:
  
  autoscroll_player(speed)  
  
  Note: because of how the interpreter and the "Call Script" event command
  are setup, the call to autoscroll(...) can only be on the first line of
  the "Call Script" event command (and not flowing down to subsequent lines).
  
  For example, the following call may not work as expected:
  
  autoscroll($game_variables[1],
  $game_variables[2])
  
  (since the long argument names require dropping down to a second line)
  A work-around is to setup new variables with shorter names in a preceding
  (separate) "Call Script" event command:
  
  @x = $game_variables[1]
  @y = $game_variables[2]
  
  and then use those as arguments:
  
  autoscroll(@x,@y)
  
  The renaming must be in a separate "Call Script" because otherwise
  the call to autoscroll(...) isn't on the first line.
  
  Originally requested by militantmilo80:
  http://www.rmxp.net/forums/index.php?showtopic=29519  
  
=end

class Interpreter
  SCROLL_SPEED_DEFAULT = 4

  #-----------------------------------------------------------------------------
  # * Map Autoscroll to Coordinates
  #     x     : x coordinate to scroll to and center on
  #     y     : y coordinate to scroll to and center on
  #     speed : (optional) scroll speed (from 1-6, default being 4)
  #-----------------------------------------------------------------------------
  def autoscroll(x, y, speed = SCROLL_SPEED_DEFAULT)
    if not $game_map.valid?(x, y)
      print 'Map Autoscroll: given x,y is invalid'
      return true
    elsif not (1..6).include?(speed)
      print 'Map Autoscroll: invalid speed (1-6 only)'
      return true
    end
    $game_map.start_autoscroll(x, y, speed)
    return !$game_map.autoscrolling?
  end
  #-----------------------------------------------------------------------------
  # * Map Autoscroll (to Player)
  #     speed : (optional) scroll speed (from 1-6, default being 4)
  #-----------------------------------------------------------------------------
  def autoscroll_player(speed = SCROLL_SPEED_DEFAULT)
    autoscroll($game_player.x, $game_player.y, speed)
  end

  #-----------------------------------------------------------------------------
  # * BES-T Versión bloqueante: usar esta mejor.
  #-----------------------------------------------------------------------------
  def autoscroll_wait(x, y, speed = SCROLL_SPEED_DEFAULT)
    autoscroll(x, y, speed)
    while $game_map.autoscrolling?
      pbWait(1)
    end
    return true
  end

  def autoscroll_player_wait(speed = SCROLL_SPEED_DEFAULT)
    autoscroll_wait($game_player.x, $game_player.y, speed)
  end
end



class Game_Map
  def start_autoscroll(x, y, speed = 4)
    center_x = (Graphics.width / 2 - Game_Map::TILEWIDTH / 2) * 4
    center_y = (Graphics.height / 2 - Game_Map::TILEHEIGHT / 2) * 4
    max_x = (self.width  - Graphics.width  * 1.0 / Game_Map::TILEWIDTH)  * 4 * Game_Map::TILEWIDTH
    max_y = (self.height - Graphics.height * 1.0 / Game_Map::TILEHEIGHT) * 4 * Game_Map::TILEHEIGHT

    target_x = [0, [x * Game_Map.realResX - center_x, max_x].min].max
    target_y = [0, [y * Game_Map.realResY - center_y, max_y].min].max

    @as_target_x = target_x
    @as_target_y = target_y
    @as_speed    = 2 ** speed   # píxeles-mapa por frame, misma escala que el sistema original
    @as_active   = true
  end

  def autoscrolling?
    @as_active == true
  end

  #-----------------------------------------------------------------------------
  # * Se llama una vez por frame (ver alias de update más abajo)
  #-----------------------------------------------------------------------------
  def update_autoscroll
    return unless @as_active

    dx = @as_target_x - @display_x
    dy = @as_target_y - @display_y

    if dx == 0 and dy == 0
      @as_active = false
      return
    end

    dist = Math.sqrt(dx.to_f * dx + dy.to_f * dy)
    step = @as_speed

    if dist <= step
      # último frame: llegar exacto, sin pasarse
      @display_x = @as_target_x
      @display_y = @as_target_y
      @as_active = false
    else
      ratio = step / dist
      @display_x += (dx * ratio).round
      @display_y += (dy * ratio).round
    end
  end

  alias autoscroll_orig_update update
  def update
    autoscroll_orig_update
    update_autoscroll
  end
end