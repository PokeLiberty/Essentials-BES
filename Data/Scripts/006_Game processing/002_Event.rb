#===============================================================================
# Defines an event that procedures can subscribe to.
#===============================================================================
class Event
  def initialize
    @callbacks = []
  end

  # Sets an event handler for this event and removes all other event handlers.
  def set(method)
    @callbacks.clear
    @callbacks.push(method)
  end

  # Removes an event handler procedure from the event.
  def -(other)
    @callbacks.delete(other)
    return self
  end

  # Adds an event handler procedure from the event.
  def +(other)
    return self if @callbacks.include?(other)
    @callbacks.push(other)
    return self
  end

  def -(method)
    for i in 0...@callbacks.length
      if @callbacks[i]==method
        @callbacks.delete_at(i)
        break
      end
    end
    return self
  end

# Adds an event handler procedure from the event.
  def +(method)
    for i in 0...@callbacks.length
      if @callbacks[i]==method
        return self
      end
    end
    @callbacks.push(method)
    return self
  end

  # Clears the event of event handlers.
  def clear
    @callbacks.clear
  end

  # Triggers the event and calls all its event handlers.  Normally called only
  # by the code where the event occurred.
  # The first argument is the sender of the event, the second argument contains
  # the event's parameters. If three or more arguments are given, this method
  # supports the following callbacks:
  # proc { |sender,params| } where params is an array of the other parameters, and
  # proc { |sender,arg0,arg1,...| }
  def trigger(*arg)
    arglist = arg[1, arg.length]
    @callbacks.each do |callback|
      if callback.arity > 2 && arg.length == callback.arity
        # Retrofitted for callbacks that take three or more arguments
        callback.call(*arg)
      else
        callback.call(arg[0], arglist)
      end
    end
  end

  # Triggers the event and calls all its event handlers. Normally called only
  # by the code where the event occurred. The first argument is the sender of
  # the event, the other arguments are the event's parameters.
  def trigger2(*arg)
    @callbacks.each do |callback|
      callback.call(*arg)
    end
  end
end

#===============================================================================
# Same as class Event, but each registered proc has a name (a symbol) so it can
# be referenced individually.
#===============================================================================
class NamedEvent
  def initialize
    @callbacks = {}
  end

  # Adds an event handler procedure from the event.
  def add(key, proc)
    @callbacks[key] = proc if !@callbacks.has_key?(key)
  end

  # Removes an event handler procedure from the event.
  def remove(key)
    @callbacks.delete(key)
  end

  # Clears the event of event handlers.
  def clear
    @callbacks.clear
  end

  # Triggers the event and calls all its event handlers. Normally called only
  # by the code where the event occurred.
  def trigger(*args)
    @callbacks.each_value { |callback| callback.call(*args) }
  end
end

#===============================================================================
# A class that stores code that can be triggered. Each piece of code has an
# associated ID, which can be anything that can be used as a key in a hash.
#===============================================================================
class HandlerHash
  def initialize(mod=nil)
    @mod=mod if mod
    @hash={}
    @addIfs=[]
    @symbolCache={}
  end

  def [](id)
    return @hash[id] if id && @hash[id]
    return nil
  end

  def fromSymbol(sym)
    if sym.is_a?(Symbol) || sym.is_a?(String)
      mod=Object.const_get(@mod) rescue nil
      return nil if !mod
      return mod.const_get(sym.to_sym) rescue nil
    else
      return sym
    end
  end

  def toSymbol(sym)
    if sym.is_a?(Symbol) || sym.is_a?(String)
      return sym.to_sym
    else
      ret=@symbolCache[sym]
      return ret if ret
      mod=Object.const_get(@mod) rescue nil
      return nil if !mod
      for key in mod.constants
        if mod.const_get(key)==sym
          ret=key.to_sym
          @symbolCache[sym]=ret
          break
        end
      end
      return ret
    end
  end

  def addIf(condProc,handler)
    @addIfs.push([condProc,handler])
  end

  def add(sym,handler=nil) # 'sym' can be an ID or symbol
    id=fromSymbol(sym)
    @hash[id]=handler if id && handler
    symbol=toSymbol(sym)
    @hash[symbol]=handler if symbol && handler
  end

  def copy(src,*dests)
    handler=self[src]
    if handler
      for dest in dests
        self.add(dest,handler)
      end
    end
  end

  def remove(key)
    @hash.delete(key)
  end

  def clear
    @hash.clear
  end

  def each
    @hash.each_pair { |key, value| yield key, value }
  end

  def keys
    return @hash.keys.clone
  end

  def trigger(sym,*args)
    handler=self[sym]
    return handler ? handler.call(fromSymbol(sym),*args) : nil
  end

  def [](sym) # 'sym' can be an ID or symbol
    id=fromSymbol(sym)
    ret=nil
    if id && @hash[id] # Real ID from the item
      ret=@hash[id]
    end
    symbol=toSymbol(sym)
    if symbol && @hash[symbol] # Symbol or string
      ret=@hash[symbol]
    end
    if !ret
      for addif in @addIfs
        if addif[0].call(id)
          return addif[1]
        end
      end
    end
    return ret
  end
end

#===============================================================================
# Este módulo almacena eventos que pueden ocurrir durante el juego. Un 
# procedimiento puede suscribirse a un evento agregándose a él. Entonces, se 
# llamará cada vez que ocurra el evento. Los eventos existentes son:
#-------------------------------------------------------------------------------
#   :on_game_map_setup - Cuando se configura un Game_Map. Cambia típicamente 
#                      datos de mapa.
#   :on_new_spriteset_map - Cuando se crea un Spriteset_Map. Agrega más cosas 
#                      para mostrar en el overworld.
#   :on_frame_update - Una vez por fotograma. Contadores varios de fotogramas/
#                      tiempo.
#   :on_leave_map - Al salir de un mapa. Finaliza efectos de clima y efectos
#                      expirados.
#   :on_enter_map - Al entrar en un nuevo mapa. Configura nuevos efectos, 
#                      finaliza efectos expirados.
#   :on_map_or_spriteset_change - Al entrar en un nuevo mapa o cuando se creó 
#                      el spriteset. Muestra cosas en pantalla.
#-------------------------------------------------------------------------------
#   :on_player_change_direction - Cuando el jugador se gira en una dirección 
#                      diferente.
#   :on_leave_tile - Cuando cualquier evento o el jugador comienza a moverse 
#                      desde una casilla.
#   :on_step_taken - Cuando cualquier evento o el jugador termina de dar un paso.
#   :on_player_step_taken - Cuando el jugador termina un paso/termina de surfear,
#                      excepto como parte de una ruta de movimiento. Contadores 
#                      basados en pasos.
#   :on_player_step_taken_can_transfer - Cuando el jugador termina de dar un paso/
#                      termina de surfear, excepto como parte de una ruta de 
#                      movimiento. Efectos basados en pasos que pueden transferir 
#                      al jugador a otro lugar.
#   :on_player_interact - Cuando el jugador presiona el botón de Usar en el 
#                      overworld.
#-------------------------------------------------------------------------------
#   :on_trainer_load - Cuando se genera un NPCTrainer (para luchar contra él o 
#                      como compañero acompañante). Varias modificaciones a ese 
#                      entrenador y sus Pokémon.
#   :on_wild_species_chosen - Cuando se elige una especie/nivel para un encuentro
#                      salvaje. Cambia la especie/nivel (por ejemplo, errante, 
#                      cadena del Poké Radar).
#   :on_wild_pokemon_created - Cuando se ha creado un Pokémon como "objeto" para 
#                      un encuentro salvaje. Varias modificaciones a ese Pokémon.
#   :on_calling_wild_battle - Cuando se llama a una batalla salvaje. Evita esa 
#                      batalla salvaje y en su lugar inicia un tipo de batalla 
#                      diferente (por ejemplo, Zona Safari).
#   :on_start_battle - Justo antes de que comience una batalla. Memoriza/
#                      restablece información sobre los Pokémon del grupo, que 
#                      se utiliza después de la batalla para comprobaciones de 
#                      evolución.
#   :on_end_battle - Justo después de que termina una batalla. Comprobaciones de
#                      evolución, Recogida/Recogida de miel, desmayo.
#   :on_wild_battle_end - Después de una batalla salvaje. Actualiza la 
#                      información de la cadena del Poké Radar.
#===============================================================================

module EventHandlers
  @@events = {}

  # Add a named callback for the given event.
  def self.add(event, key, proc)
    @@events[event] = NamedEvent.new if !@@events.has_key?(event)
    @@events[event].add(key, proc)
  end

  # Remove a named callback from the given event.
  def self.remove(event, key)
    @@events[event].remove(key)
  end

  # Clear all callbacks for the given event.
  def self.clear(key)
    @@events[key].clear
  end

  # Trigger all callbacks from an Event if it has been defined.
  def self.trigger(event, *args)
    return @@events[event].trigger(*args)
  end
end

#===============================================================================
# This module stores the contents of various menus. Each command in a menu is a
# hash of data (containing its name, relative order, code to run when chosen,
# etc.).
# Menus that use this module are:
#-------------------------------------------------------------------------------
# Pause menu
# Party screen main interact menu
# Pokégear main menu
# Options screen
# PC main menu
# Various debug menus (main, Pokémon, battle, battle Pokémon)
#===============================================================================
module MenuHandlers
  @@handlers = {}

  def self.add(menu, option, hash)
    @@handlers[menu]=HandlerHash.new if !@@handlers.has_key?(menu)
    @@handlers[menu].add(option, hash)
  end

  def self.remove(menu, option)
    @@handlers[menu].remove(option)
  end

  def self.clear(menu)
    @@handlers[menu].clear
  end

  def self.each(menu)
    return if !@@handlers.has_key?(menu)
    @@handlers[menu].each { |option, hash| yield option, hash }
  end

  def self.each_available(menu, *args)
    return if !@@handlers.has_key?(menu)
    options = @@handlers[menu]
    keys = options.keys
    sorted_keys = keys.sort_by { |option| options[option]["order"] || keys.index(option) }
    sorted_keys.each do |option|
      hash = options[option]
      next if hash["condition"] && !hash["condition"].call(*args)
      if hash["name"].is_a?(Proc)
        name = hash["name"].call
      else
        name = _INTL(hash["name"])
      end
      yield option, hash, name
    end
  end

  def self.call(menu, option, function, *args)
    option_hash = @@handlers[menu][option]
    return nil if !option_hash || !option_hash[function]
    return option_hash[function].call(*args)
  end
end

