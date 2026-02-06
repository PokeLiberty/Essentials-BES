################################################################################
#
#                               SizeEvents v.3.0
#                                Autor : Bezier
#                       Compatible con : 16.2
#              Sugerencias para mejora : Pablus y Scept
#
# Este script permite definir eventos con tamaño superior a 1 cuadro,
# ahorrando eventos que afecten a una zona usando 1 solo evento.
# Añade al nombre del evento el texto size(w,h) para definir un tamaño de
# 'w' cuadros de ancho y 'h' cuadros de alto. Ejemplo.
#
#    evento: X
#    nombre: bloqueo size(4,2)
#         esto define un evento extendido de ancho 4 y alto 2
#
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
#    [ ] [ ] [h] [h] [h] [h] [ ] [ ] [ ] [ ]
#    [ ] [ ] [X] [w] [w] [w] [ ] [ ] [ ] [ ]
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
################################################################################
#
# Al entrar en contacto con un evento de teletransporte, traslada al jugador
# al cuadro correspondiente aplicando un desfase desde donde está el evento.
# En el siguiente ejemplo, el personaje, \PN, entra en el cuadro extendido 2,
# a 2 cuadros por encima del evento [X], el cual tiene un destino de 
# teletransporte a la posición [T]. El jugador aparecerá en T+2.
# Se aplica tanto para eventos en horizontal como en vertical
#    evento: X
#    nombre: size(1,3)
#    destino de tp desde el evento: X ---> T
#    entra en [X + 2] ---> sale por [T + 2]
#
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
#    \PN --->[2]-[-]-[-]-[-]-[2]---> \PN [ ]
#    [ ] [ ] [1] [ ] [ ] [ ] [1] [ ] [ ] [ ]
#    [ ] [ ] [X] ----------> [T] [ ] [ ] [ ]
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
################################################################################
#
# * Versión 2.0 - Teletransportes cruzados [Sugerido por Scept]
# Al entrar en contacto con un evento de teletransporte, traslada al jugador
# al cuadro correspondiente aplicando el desfase y un cambio de coordenadas.
# En el siguiente ejemplo, el personaje, \PN, entra en el cuadro extendido 2,
# a 2 cuadros por encima del evento [X], el cual tiene un destino de 
# teletransporte a la posición [T]. El jugador aparecerá en T+2 cruzado
# Se aplica tanto para eventos en horizontal como en vertical
#    evento: X
#    nombre: size(1,3)
#    destino de tp desde el evento: X ---> T
#    entra en [X + 2] ---> sale por [T + 2_x]
#
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [   ] [   ] [ ]
#    \PN --->[2]-[-]-[-]-[-]-[2]-[---]-[-· ] [ ]
#    [ ] [ ] [1] [ ] [ ] [ ] [1] [   ] [ v ] [ ]
#    [ ] [ ] [X] ----------> [T] [1_x] [2_x] \PN
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [   ] [   ] [ ]
################################################################################
#
# * Versión 3.0 - Omitir el desfase en los teletransportes [Sugerido por Pablus]
# Se ha añadido un interruptor con el cual se puede omitir el desfase que aplica
# a los teletransportes para mantener una correlación de cuadros.
#    evento: X
#    nombre: size(1,3)
#    destino de tp desde el evento: X ---> T
#    interruptor SIZEEVENT_OMITOFFSET_SWITCH activado
#    entra en [X + 2] ---> sale por [T] SIN DESFASE
#
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
#    \PN --->[2] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
#    [ ] [ ] [1] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
#    [ ] [ ] [X] ----------> [T]---> \PN [ ]
#    [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ] [ ]
################################################################################
# Interruptor para omitir el desfase en los teletransportes
# Con este interruptor activo se omitirán todos los desfases en los teletransportes
# permitiendo que todos los cuadros del evento extendido hagan tp a un único punto
# Se puede usar cualquier interruptor.

SIZEEVENT_OMITOFFSET_SWITCH = 999
# Interruptor que se usa para modificar la dirección de teletransporte extendido
# Los tp normales funcionan en horizontal o vertical, pero con este interruptor
# activado, se puede entrar en un tp horizontal y salir por una zona en vertical
# Se puede usar cualquier interruptor.
SIZEEVENT_TPCROSS_SWITCH = 998

class Game_Character
 
  alias initialize_se_char initialize
  def initialize(map=nil)
    initialize_se_char(map)
    @width = 1
    @height = 1
  end
 
  def at_coordinate?(check_x, check_y)
    return check_x >= @x && check_x < @x + @width &&
           check_y > @y - @height && check_y <= @y
  end
 
  def passableEx?(x, y, d, strict=false)
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    return false unless self.map.valid?(new_x, new_y)
    return true if @through
    if strict
      return false unless self.map.passableStrict?(x, y, d, self)
      return false unless self.map.passableStrict?(new_x, new_y, 10 - d, self)
    else
      return false unless self.map.passable?(x, y, d, self)
      return false unless self.map.passable?(new_x, new_y, 10 - d, self)
    end
    for event in self.map.events.values
      if event.at_coordinate?(new_x, new_y) #event.x == new_x and event.y == new_y
        unless event.through
          return false if self != $game_player || event.character_name != ""
        end
      end
    end
    if $game_player.x == new_x and $game_player.y == new_y
      unless $game_player.through
        return false if @character_name != ""
      end
    end
    return true
  end
end
 
class Game_Event < Game_Character
 
  alias initialize_se_event initialize
  def initialize(map_id, event, map=nil)
    initialize_se_event(map_id, event, map)
    if @event.name[/size\((\d+),(\d+)\)/i]
      @width = $~[1].to_i
      @height = $~[2].to_i
    end
  end
 
  def onEvent?
    return @map_id==$game_map.map_id && at_coordinate?($game_player.x, $game_player.y)
  end
 
  def check_event_trigger_auto
    if @trigger == 2 && at_coordinate?($game_player.x, $game_player.y) # Event touch
      if not jumping? and over_trigger?
        start
      end
    elsif @trigger == 3 # Autorun
      start
    end
  end
end
 
class Game_Player < Game_Character
 
  def pbFacingEvent
    if $game_system.map_interpreter.running?
      return nil
    end
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    for event in $game_map.events.values
      if event.at_coordinate?(new_x, new_y)
        if not event.jumping? and not event.over_trigger?
          return event
        end
      end
    end
    if $game_map.counter?(new_x, new_y)
      new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
      new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
      for event in $game_map.events.values
        if event.at_coordinate?(new_x, new_y)
          if not event.jumping? and not event.over_trigger?
            return event
          end
        end
      end
    end
    return nil
  end
  #-----------------------------------------------------------------------------
  # * Same Position Starting Determinant
  #-----------------------------------------------------------------------------
  def check_event_trigger_here(triggers)
    result = false
    # If event is running
    if $game_system.map_interpreter.running?
      return result
    end
    # All event loops
    for event in $game_map.events.values
      # If event coordinates and triggers are consistent
      if event.at_coordinate?(@x, @y) && triggers.include?(event.trigger)
        # If starting determinant is same position event (other than jumping)
        if not event.jumping? and event.over_trigger?
          event.start
          result = true
        end
      end
    end
    return result
  end
  #-----------------------------------------------------------------------------
  # * Front Event Starting Determinant
  #-----------------------------------------------------------------------------
  def check_event_trigger_there(triggers)
    result = false
    # If event is running
    if $game_system.map_interpreter.running?
      return result
    end
    # Calculate front event coordinates
    new_x = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    new_y = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    # All event loops
    for event in $game_map.events.values
      # If event coordinates and triggers are consistent
      if event.at_coordinate?(new_x, new_y) && triggers.include?(event.trigger)
        # If starting determinant is front event (other than jumping)
        if not event.jumping? and !event.over_trigger?
          event.start
          result = true
        end
      end
    end
    # If fitting event is not found
    if result == false
      # If front tile is a counter
      if $game_map.counter?(new_x, new_y)
        # Calculate 1 tile inside coordinates
        new_x += (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
        new_y += (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
        # All event loops
        for event in $game_map.events.values
          # If event coordinates and triggers are consistent
          if event.at_coordinate?(new_x, new_y) && triggers.include?(event.trigger)
            # If starting determinant is front event (other than jumping)
            if not event.jumping? and !event.over_trigger?
              event.start
              result = true
            end
          end
        end
      end
    end
    return result
  end
  #-----------------------------------------------------------------------------
  # * Touch Event Starting Determinant
  #-----------------------------------------------------------------------------
  def check_event_trigger_touch(x, y)
    result = false
    # If event is running
    if $game_system.map_interpreter.running?
      return result
    end
    # All event loops
    for event in $game_map.events.values
      if event.name[/^Trainer\((\d+)\)$/]
        distance=$~[1].to_i
        next if !pbEventCanReachPlayer?(event,self,distance)
      end
      if event.name[/^Counter\((\d+)\)$/]
        distance=$~[1].to_i
        next if !pbEventFacesPlayer?(event,self,distance)
      end
      # If event coordinates and triggers are consistent
      if event.at_coordinate?(x, y) && [1,2].include?(event.trigger)
        # If starting determinant is front event (other than jumping)
        if not event.jumping? and not event.over_trigger?
          event.start
          result = true
        end
      end
    end
    return result
  end
end
 
class Scene_Map
  alias transfer_player_size transfer_player
  def transfer_player(cancelVehicles=true)
 
    # Si se está omitiendo el desfase de teletransporte,
    # traslada al jugador a la posición correspondiente según el tamaño
    if $game_switches[SIZEEVENT_OMITOFFSET_SWITCH]
      inc_x = 0
      inc_y = 0
      interpreter=pbMapInterpreter
      if interpreter
        event=interpreter.get_character(0)
        if event
          if event.name[/size\((\d+),(\d+)\)/i]
            difx = $game_player.x - event.x
            dify = $game_player.y - event.y
 
            # Si se está aplicando un teletransporte cruzado,
            # invierte los desfases de desplazamiento horizontal y vertical
            if $game_switches[SIZEEVENT_TPCROSS_SWITCH]
              $game_temp.player_new_x -= dify
              $game_temp.player_new_y -= difx
            else
              $game_temp.player_new_x += difx
              $game_temp.player_new_y += dify
            end
          end
        end
      end
    end
 
    transfer_player_size
  end
end