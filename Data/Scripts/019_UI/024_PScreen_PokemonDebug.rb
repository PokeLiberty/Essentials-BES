#===============================================================================
# BES-T - Debug unificado con MenuHandlers
# Sistema de depuración para PokemonScreen y PokemonStorageScreen
#===============================================================================
module PokemonDebugMixin
  # Método unificado de debug que usa MenuHandlers
  def pbPokemonDebugHandlers(pkmn, pkmnid_or_selected, heldpoke = nil)
    command = 0
    loop do
      # Construir comandos usando MenuHandlers
      command_list = []
      commands = []
      order = []
      
      # Recopilar comandos disponibles
      MenuHandlers.each_available(:debug_menu, self, pkmn, pkmnid_or_selected, heldpoke) do |option, hash, name|
        command_list.push(name)
        commands.push(hash)
        order.push(hash["order"] || 999)
      end
      
      # Ordenar por order
      sorted_indices = (0...commands.length).to_a.sort_by { |i| order[i] }
      command_list = sorted_indices.map { |i| command_list[i] }
      commands = sorted_indices.map { |i| commands[i] }
      
      command_list.push(_INTL("Salir"))
      
      # Mostrar menú
      command = @scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), command_list, command)
      break if command < 0 || command >= commands.length
      
      # Ejecutar comando seleccionado
      result = commands[command]["effect"].call(self, pkmn, pkmnid_or_selected, heldpoke)
      break if result == :break
    end
  end
  
  # Método auxiliar para refrescar según el tipo de pantalla
  def pbDebugRefresh(pkmnid_or_selected)
    if self.is_a?(PokemonScreen)
      pbRefreshSingle(pkmnid_or_selected)
    else
      @scene.pbHardRefresh
    end
  end
end

# Incluir el mixin en ambas clases, lo metemos así por si alguien aun usa el sistema antiguo.
class PokemonScreen
  include PokemonDebugMixin
  
  # Redefinir pbDebugMenu para usar el nuevo sistema
  def pbPokemonDebug(pkmn, pkmnid)
    pbPokemonDebugHandlers(pkmn, pkmnid)
  end
end

class PokemonStorageScreen
  include PokemonDebugMixin
  
  # Redefinir debugMenu para usar el nuevo sistema
  def debugMenu(selected, pkmn, heldpoke)
    pbPokemonDebugHandlers(pkmn, selected, heldpoke)
  end
end
#===============================================================================
# MenuHandlers para el menú de debug
#===============================================================================

MenuHandlers.add(:debug_menu, :hp_status, {
  "name"      => _INTL("PS/Estado"),
  "order"     => 10,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      cmd = screen.scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), [
        _INTL("Setear PS"),
        _INTL("Estado: Dormido"),
        _INTL("Estado: Envenenado"),
        _INTL("Estado: Quemado"),
        _INTL("Estado: Paralizado"),
        _INTL("Estado: Congelado"),
        _INTL("Debilitar"),
        _INTL("Curar")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0 # Set HP
        params = ChooseNumberParams.new
        params.setRange(0, pkmn.totalhp)
        params.setDefaultValue(pkmn.hp)
        newhp = Kernel.pbMessageChooseNumber(
          _INTL("Establecer los PS del Pokémon (máx. {1}).", pkmn.totalhp), params) { screen.scene.update }
        if newhp != pkmn.hp
          pkmn.hp = newhp
          screen.pbDisplay(_INTL("Los PS de {1} se establecieron en {2}.", pkmn.name, pkmn.hp))
          screen.pbDebugRefresh(pkmnid_or_selected)
        end
      when 1..5 # Set status
        if pkmn.hp > 0
          pkmn.status = cmd
          pkmn.statusCount = 0
          if pkmn.status == PBStatuses::SLEEP
            params = ChooseNumberParams.new
            params.setRange(0, 9)
            params.setDefaultValue(0)
            sleep = Kernel.pbMessageChooseNumber(
              _INTL("Establecer el contador de sueño del Pokémon."), params) { screen.scene.update }
            pkmn.statusCount = sleep
          end
          screen.pbDisplay(_INTL("El estado de {1} fue cambiado.", pkmn.name))
          screen.pbDebugRefresh(pkmnid_or_selected)
        else
          screen.pbDisplay(_INTL("El estado de {1} no pudo ser cambiado.", pkmn.name))
        end
      when 6 # Faint
        pkmn.hp = 0
        screen.pbDisplay(_INTL("Los PS de {1} están en 0.", pkmn.name))
        screen.pbDebugRefresh(pkmnid_or_selected)
      when 7 # Heal
        pkmn.heal
        screen.pbDisplay(_INTL("{1} está completamente curado.", pkmn.name))
        screen.pbDebugRefresh(pkmnid_or_selected)
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :level, {
  "name"      => _INTL("Nivel"),
  "order"     => 20,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    params = ChooseNumberParams.new
    params.setRange(1, PBExperience::MAXLEVEL)
    params.setDefaultValue(pkmn.level)
    level = Kernel.pbMessageChooseNumber(
      _INTL("Establecer el nivel del Pokémon (máx. {1}).", PBExperience::MAXLEVEL), params) { screen.scene.update }
    if level != pkmn.level
      pkmn.level = level
      pkmn.calcStats
      screen.pbDisplay(_INTL("El nivel del {1} se estableció en {2}.", pkmn.name, pkmn.level))
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :species, {
  "name"      => _INTL("Especie"),
  "order"     => 30,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    species = pbChooseSpecies(pkmn.species)
    if species != 0
      oldspeciesname = PBSpecies.getName(pkmn.species)
      pkmn.species = species
      pkmn.calcStats
      oldname = pkmn.name
      pkmn.name = PBSpecies.getName(pkmn.species) if pkmn.name == oldspeciesname
      screen.pbDisplay(_INTL("La especie de {1} fue cambiada a {2}.", oldname, PBSpecies.getName(pkmn.species)))
      pbSeenForm(pkmn)
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :moves, {
  "name"      => _INTL("Movimientos"),
  "order"     => 40,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      cmd = screen.scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), [
        _INTL("Enseñar movimiento"),
        _INTL("Olvidar movimiento"),
        _INTL("Restaurar lista de mov."),
        _INTL("Restaurar mov. iniciales")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0 # Teach move
        move = pbChooseMoveList
        if move != 0
          pbLearnMove(pkmn, move)
          screen.pbDebugRefresh(pkmnid_or_selected)
        end
      when 1 # Forget move
        if screen.is_a?(PokemonScreen)
          move = screen.pbChooseMove(pkmn, _INTL("Seleccione el movimiento a olvidar."))
          if move >= 0
            movename = PBMoves.getName(pkmn.moves[move].id)
            pkmn.pbDeleteMoveAtIndex(move)
            screen.pbDisplay(_INTL("{1} olvidó {2}.", pkmn.name, movename))
            screen.pbDebugRefresh(pkmnid_or_selected)
          end
        else
          pbChooseMove(pkmn, 1, 2)
          if pbGet(1) >= 0
            pkmn.pbDeleteMoveAtIndex(pbGet(1))
            screen.pbDisplay(_INTL("{1} olvidó {2}.", pkmn.name, pbGet(2)))
            screen.pbDebugRefresh(pkmnid_or_selected)
          end
        end
      when 2 # Reset movelist
        pkmn.resetMoves
        screen.pbDisplay(_INTL("Los movimientos de {1} fueron restablecidos.", pkmn.name))
        screen.pbDebugRefresh(pkmnid_or_selected)
      when 3 # Reset initial moves
        pkmn.pbRecordFirstMoves
        screen.pbDisplay(_INTL("{1} recuperó sus movimientos iniciales.", pkmn.name))
        screen.pbDebugRefresh(pkmnid_or_selected)
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :gender, {
  "name"      => _INTL("Género"),
  "order"     => 50,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    if pkmn.gender == 2
      screen.pbDisplay(_INTL("{1} no tiene género.", pkmn.name))
    else
      cmd = 0
      loop do
        oldgender = (pkmn.isMale?) ? _INTL("macho") : _INTL("hembra")
        msg = [_INTL("El género {1} es natural.", oldgender),
               _INTL("El género {1} es forzado.", oldgender)][pkmn.genderflag ? 1 : 0]
        cmd = screen.scene.pbShowCommands(msg, [
          _INTL("Hacer macho"),
          _INTL("Hacer hembra"),
          _INTL("Quitar cambio")
        ], cmd)
        
        break if cmd == -1
        
        case cmd
        when 0
          pkmn.setGender(0)
          if pkmn.isMale?
            screen.pbDisplay(_INTL("Ahora {1} es macho.", pkmn.name))
          else
            screen.pbDisplay(_INTL("El género de {1} no se puedo cambiar.", pkmn.name))
          end
        when 1
          pkmn.setGender(1)
          if pkmn.isFemale?
            screen.pbDisplay(_INTL("Ahora {1} es hembra.", pkmn.name))
          else
            screen.pbDisplay(_INTL("El género de {1} no se puede cambiar.", pkmn.name))
          end
        when 2
          pkmn.genderflag = nil
          screen.pbDisplay(_INTL("Se quitó el cambio de género."))
        end
        pbSeenForm(pkmn)
        screen.pbDebugRefresh(pkmnid_or_selected)
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :ability, {
  "name"      => _INTL("Habilidad"),
  "order"     => 60,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      abils = pkmn.getAbilityList
      oldabil = PBAbilities.getName(pkmn.ability)
      commands = []
      for i in abils
        commands.push((i[1] < 2 ? "" : "(H) ") + PBAbilities.getName(i[0]))
      end
      commands.push(_INTL("Quitar cambio"))
      msg = [_INTL("La habilidad {1} es natural.", oldabil),
             _INTL("La habilidad {1} es forzada.", oldabil)][pkmn.abilityflag != nil ? 1 : 0]
      cmd = screen.scene.pbShowCommands(msg, commands, cmd)
      
      break if cmd == -1
      
      if cmd >= 0 && cmd < abils.length
        pkmn.setAbility(abils[cmd][1])
      elsif cmd == abils.length
        pkmn.abilityflag = nil
      end
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :nature, {
  "name"      => _INTL("Naturaleza"),
  "order"     => 70,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      oldnature = PBNatures.getName(pkmn.nature)
      commands = []
      (PBNatures.getCount).times do |i|
        commands.push(PBNatures.getName(i))
      end
      commands.push(_INTL("Quitar cambio"))
      msg = [_INTL("La naturaleza {1} es natural.", oldnature),
             _INTL("La naturaleza {1} es forzada.", oldnature)][pkmn.natureflag ? 1 : 0]
      cmd = screen.scene.pbShowCommands(msg, commands, cmd)
      
      break if cmd == -1
      
      if cmd >= 0 && cmd < PBNatures.getCount
        pkmn.setNature(cmd)
        pkmn.calcStats
      elsif cmd == PBNatures.getCount
        pkmn.natureflag = nil
      end
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :shininess, {
  "name"      => _INTL("Shininess"),
  "order"     => 80,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      oldshiny = (pkmn.isShiny?) ? _INTL("shiny") : _INTL("normal")
      msg = [_INTL("Shininess ({1}) es natural.", oldshiny),
             _INTL("Shininess ({1}) es forzado.", oldshiny)][pkmn.shinyflag != nil ? 1 : 0]
      cmd = screen.scene.pbShowCommands(msg, [
        _INTL("Hacer shiny"),
        _INTL("Hacer normal"),
        _INTL("Quitar cambio")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0
        pkmn.makeShiny
      when 1
        pkmn.makeNotShiny
      when 2
        pkmn.shinyflag = nil
      end
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :form, {
  "name"      => _INTL("Forma"),
  "order"     => 90,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    params = ChooseNumberParams.new
    params.setRange(0, 100)
    params.setDefaultValue(pkmn.form)
    f = Kernel.pbMessageChooseNumber(
      _INTL("Establecer la forma del Pokémon."), params) { screen.scene.update }
    if f != pkmn.form
      pkmn.form = f
      screen.pbDisplay(_INTL("La forma de {1} se cambió a {2}.", pkmn.name, pkmn.form))
      pbSeenForm(pkmn)
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :happiness, {
  "name"      => _INTL("Felicidad"),
  "order"     => 100,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.happiness)
    h = Kernel.pbMessageChooseNumber(
      _INTL("Establecer la felicidad de Pokémon (máx. 255)."), params) { screen.scene.update }
    if h != pkmn.happiness
      pkmn.happiness = h
      screen.pbDisplay(_INTL("La felicidad de {1} fue establecida en {2}.", pkmn.name, pkmn.happiness))
      screen.pbDebugRefresh(pkmnid_or_selected)
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :ev_iv_pid, {
  "name"      => _INTL("EV/IV/pID"),
  "order"     => 110,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    stats = [_INTL("PS"), _INTL("Ataque"), _INTL("Defensa"),
             _INTL("Velocidad"), _INTL("At. Esp."), _INTL("Def. Esp.")]
    cmd = 0
    loop do
      persid = sprintf("0x%08X", pkmn.personalID)
      cmd = screen.scene.pbShowCommands(_INTL("ID personal es {1}.", persid), [
        _INTL("Setear EVs"),
        _INTL("Setear IVs"),
        _INTL("Randomise pID")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0 # Set EVs
        cmd2 = 0
        loop do
          evcommands = []
          for i in 0...stats.length
            evcommands.push(stats[i] + " (#{pkmn.ev[i]})")
          end
          cmd2 = screen.scene.pbShowCommands(_INTL("¿Cuál EV cambiar?"), evcommands, cmd2)
          break if cmd2 == -1
          
          if cmd2 >= 0 && cmd2 < stats.length
            params = ChooseNumberParams.new
            params.setRange(0, PokeBattle_Pokemon::EVSTATLIMIT)
            params.setDefaultValue(pkmn.ev[cmd2])
            params.setCancelValue(pkmn.ev[cmd2])
            f = Kernel.pbMessageChooseNumber(
              _INTL("SEstablecer el EV para {1} (máx. {2}).",
                stats[cmd2], PokeBattle_Pokemon::EVSTATLIMIT), params) { screen.scene.update }
            pkmn.ev[cmd2] = f
            pkmn.totalhp
            pkmn.calcStats
            screen.pbDebugRefresh(pkmnid_or_selected)
          end
        end
      when 1 # Set IVs
        cmd2 = 0
        loop do
          hiddenpower = pbHiddenPower(pkmn.iv)
          msg = _INTL("Poder Oculto:\n{1}, potencia {2}.", PBTypes.getName(hiddenpower[0]), hiddenpower[1])
          ivcommands = []
          for i in 0...stats.length
            ivcommands.push(stats[i] + " (#{pkmn.iv[i]})")
          end
          ivcommands.push(_INTL("Hacer aleatorio"))
          cmd2 = screen.scene.pbShowCommands(msg, ivcommands, cmd2)
          break if cmd2 == -1
          
          if cmd2 >= 0 && cmd2 < stats.length
            params = ChooseNumberParams.new
            params.setRange(0, 31)
            params.setDefaultValue(pkmn.iv[cmd2])
            params.setCancelValue(pkmn.iv[cmd2])
            f = Kernel.pbMessageChooseNumber(
              _INTL("Establecer el IV para {1} (máx. 31).", stats[cmd2]), params) { screen.scene.update }
            pkmn.iv[cmd2] = f
            pkmn.calcStats
            screen.pbDebugRefresh(pkmnid_or_selected)
          elsif cmd2 == ivcommands.length - 1
            pkmn.iv[0] = rand(32)
            pkmn.iv[1] = rand(32)
            pkmn.iv[2] = rand(32)
            pkmn.iv[3] = rand(32)
            pkmn.iv[4] = rand(32)
            pkmn.iv[5] = rand(32)
            pkmn.calcStats
            screen.pbDebugRefresh(pkmnid_or_selected)
          end
        end
      when 2 # Randomise pID
        pkmn.personalID = rand(256)
        pkmn.personalID |= rand(256) << 8
        pkmn.personalID |= rand(256) << 16
        pkmn.personalID |= rand(256) << 24
        pkmn.calcStats
        screen.pbDebugRefresh(pkmnid_or_selected)
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :pokerus, {
  "name"      => _INTL("Pokérus"),
  "order"     => 120,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      pokerus = (pkmn.pokerus) ? pkmn.pokerus : 0
      msg = [_INTL("{1} no tiene Pokérus.", pkmn.name),
             _INTL("Tiene grado {1}, infectado por {2} días más.", pokerus / 16, pokerus % 16),
             _INTL("Tiene grado {1}, no infectado.", pokerus / 16)][pkmn.pokerusStage]
      cmd = screen.scene.pbShowCommands(msg, [
        _INTL("Dar grado aleatorio"),
        _INTL("Hacer no infectado"),
        _INTL("Limpiar Pokérus")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0
        pkmn.givePokerus
      when 1
        strain = pokerus / 16
        p = strain << 4
        pkmn.pokerus = p
      when 2
        pkmn.pokerus = 0
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :ownership, {
  "name"      => _INTL("EO"),
  "order"     => 130,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      gender = [_INTL("Masculino"), _INTL("Femenino"), _INTL("Desconocido")][pkmn.otgender]
      msg = [_INTL("Pokémon del jugador\n{1}\n{2}\n{3} ({4})", pkmn.ot, gender, pkmn.publicID, pkmn.trainerID),
             _INTL("Pokémon extranjero\n{1}\n{2}\n{3} ({4})", pkmn.ot, gender, pkmn.publicID, pkmn.trainerID)
            ][pkmn.isForeign?($Trainer) ? 1 : 0]
      cmd = screen.scene.pbShowCommands(msg, [
        _INTL("Hacer del jugador"),
        _INTL("Setear nombre del EO"),
        _INTL("Setear género del EO"),
        _INTL("ID extranjero aleatorio"),
        _INTL("Setear ID extranjero")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0
        pkmn.trainerID = $Trainer.id
        pkmn.ot = $Trainer.name
        pkmn.otgender = $Trainer.gender
      when 1
        newot = pbEnterPlayerName(_INTL("Nombre del EO de {1}", pkmn.name), 1, 7)
        pkmn.ot = newot
      when 2
        cmd2 = screen.scene.pbShowCommands(_INTL("Establecer el género del EO."),
          [_INTL("Masculino"), _INTL("Femenino"), _INTL("Desconocido")])
        pkmn.otgender = cmd2 if cmd2 >= 0
      when 3
        pkmn.trainerID = $Trainer.getForeignID
      when 4
        params = ChooseNumberParams.new
        params.setRange(0, 65535)
        params.setDefaultValue(pkmn.publicID)
        val = Kernel.pbMessageChooseNumber(
          _INTL("Setear el nuevo ID (máx. 65535)."), params) { screen.scene.update }
        pkmn.trainerID = val
        pkmn.trainerID |= val << 16
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :nickname, {
  "name"      => _INTL("Apodo"),
  "order"     => 140,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      speciesname = PBSpecies.getName(pkmn.species)
      msg = [_INTL("{1} tiene el apodo {2}.", speciesname, pkmn.name),
             _INTL("{1} no tiene apodo.", speciesname)][pkmn.name == speciesname ? 1 : 0]
      cmd = screen.scene.pbShowCommands(msg, [
        _INTL("Renombrar"),
        _INTL("Borrar nombre")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0
        newname = pbEnterPokemonName(_INTL("Apodo de {1}", speciesname), 0, 10, "", pkmn)
        pkmn.name = (newname == "") ? speciesname : newname
        screen.pbDebugRefresh(pkmnid_or_selected)
      when 1
        pkmn.name = speciesname
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :pokeball, {
  "name"      => _INTL("Poké Ball"),
  "order"     => 150,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      oldball = PBItems.getName(pbBallTypeToBall(pkmn.ballused))
      commands = []
      balls = []
      for key in $BallTypes.keys
        item = getID(PBItems, $BallTypes[key])
        balls.push([key, PBItems.getName(item)]) if item && item > 0
      end
      balls.sort! { |a, b| a[1] <=> b[1] }
      for i in 0...commands.length
        cmd = i if pkmn.ballused == balls[i][0]
      end
      for i in balls
        commands.push(i[1])
      end
      cmd = screen.scene.pbShowCommands(_INTL("Usada {1}.", oldball), commands, cmd)
      if cmd == -1
        break
      else
        pkmn.ballused = balls[cmd][0]
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :ribbons, {
  "name"      => _INTL("Cintas"),
  "order"     => 160,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      commands = []
      for i in 1..PBRibbons.maxValue
        commands.push(_INTL("{1} {2}",
          pkmn.hasRibbon?(i) ? "[X]" : "[  ]", PBRibbons.getName(i)))
      end
      cmd = screen.scene.pbShowCommands(_INTL("{1} cintas.", pkmn.ribbonCount), commands, cmd)
      break if cmd == -1
      
      if cmd >= 0 && cmd < commands.length
        if pkmn.hasRibbon?(cmd + 1)
          pkmn.takeRibbon(cmd + 1)
        else
          pkmn.giveRibbon(cmd + 1)
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :ribbons, {
  "name"      => _INTL("Huevo"),
  "order"     => 170,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd=0
    loop do
    msg=[_INTL("No es un huevo"),
               _INTL("Huevo con pasos: {1}.",pkmn.eggsteps)][pkmn.isEgg? ? 1 : 0]
    cmd=screen.scene.pbShowCommands(msg,[
          _INTL("Hacer huevo"),
          _INTL("Hacer Pokémon"),
          _INTL("Setear pasos en 1")],cmd)
   
    if cmd==-1 # Break
      break
    elsif cmd==0# Make egg
      if pbHasEgg?(pkmn.species) ||
        Kernel.pbConfirmMessage(_INTL("{1} no puede ser un huevo. ¿Hacerlo huevo de todas formas?",PBSpecies.getName(pkmn.species)))
        pkmn.level=EGGINITIALLEVEL
        pkmn.calcStats
        pkmn.name=_INTL("Huevo")
        dexdata=pbOpenDexData
        pbDexDataOffset(dexdata,pkmn.species,21)
        pkmn.eggsteps=dexdata.fgetw
        dexdata.close
        pkmn.hatchedMap=0
        pkmn.obtainMode=1
        screen.pbDebugRefresh(pkmnid_or_selected)
      end
    elsif cmd==1 # Make Pokémon
      pkmn.name=PBSpecies.getName(pkmn.species)
      pkmn.eggsteps=0
      pkmn.hatchedMap=0
      pkmn.obtainMode=0
      screen.pbDebugRefresh(pkmnid_or_selected)
    elsif cmd==2 # Set eggsteps to 1
      pkmn.eggsteps=1 if pkmn.eggsteps>0
    end
  end

  }
})

MenuHandlers.add(:debug_menu, :shadow_pokemon, {
  "name"      => _INTL("Pokémon Oscuro"),
  "order"     => 180,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      msg = [(pkmn.isShadow? rescue false) ? 
             _INTL("Medidor del corazón en {1}.", pkmn.heartgauge) : 
             _INTL("No es un Pokémon Oscuro.")]
      
      cmd = screen.scene.pbShowCommands(msg[0], [
        _INTL("Hacer Oscuro"),
        _INTL("Bajar medidor del corazón")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0 # Make Shadow
        if !(pkmn.isShadow? rescue false) && pkmn.respond_to?("makeShadow")
          pkmn.makeShadow
          screen.pbDisplay(_INTL("{1} ahora es un Pokémon Oscuro.", pkmn.name))
          screen.pbDebugRefresh(pkmnid_or_selected)
        else
          screen.pbDisplay(_INTL("{1} ya es un Pokémon Oscuro.", pkmn.name))
        end
      when 1 # Lower heart gauge
        if (pkmn.isShadow? rescue false)
          prev = pkmn.heartgauge
          pkmn.adjustHeart(-700)
          Kernel.pbMessage(_INTL("El medidor del corazón de {1} bajo de {2} a {3} (ahora etapa {4}).",
            pkmn.name, prev, pkmn.heartgauge, pkmn.heartStage))
          pbReadyToPurify(pkmn) if defined?(pbReadyToPurify)
        else
          Kernel.pbMessage(_INTL("{1} no es un Pokémon Oscuro.", pkmn.name))
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :teracrystallization, {
  "name"      => _INTL("Teracristalización"),
  "order"     => 190,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      cmd = screen.scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), [
        _INTL("Setear Teratipo"),
        _INTL("Teracristalizar")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0 # Set Teratype
        cmdt = 0
        typenames = []
        for i in 0..PBTypes.maxValue
          typenames.push(PBTypes.getName(i))
        end
        
        loop do
          cmdt = screen.scene.pbShowCommands(_INTL("¿A cual tipo?", pkmn.name), typenames, cmdt)
          break if cmdt == -1
          pkmn.teratype = cmdt
          screen.pbDebugRefresh(pkmnid_or_selected)
          break
        end
      when 1 # Toggle Teracrystallization
        if pkmn.respond_to?(:teracristalized=)
          pkmn.teracristalized = !pkmn.teracristalized
          screen.pbDebugRefresh(pkmnid_or_selected)
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :dynamax, {
  "name"      => _INTL("Dynamax"),
  "order"     => 200,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    cmd = 0
    loop do
      cmd = screen.scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), [
        _INTL("Setear Nivel Dynamax"),
        _INTL("Factor Gigamax")
      ], cmd)
      
      break if cmd == -1
      
      case cmd
      when 0 # Set Dynamax Level
        params = ChooseNumberParams.new
        params.setRange(0, 10)
        params.setDefaultValue(pkmn.dynamax_lvl || 0)
        val = Kernel.pbMessageChooseNumber(
          _INTL("Setear el nuevo valor (máx. 10)."), params) { screen.scene.update }
        pkmn.dynamax_lvl = val
        screen.pbDebugRefresh(pkmnid_or_selected)
      when 1 # Toggle G-Max Factor
        if pkmn.respond_to?(:gmaxfactor=)
          pkmn.gmaxfactor = !pkmn.gmaxfactor
          screen.pbDebugRefresh(pkmnid_or_selected)
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :mystery_gift, {
  "name"      => _INTL("Regalo Misterioso"),
  "order"     => 210,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    if pbCreateMysteryGift(0, pkmn)
      screen.pbDisplay(_INTL("Regalo misterioso creado."))
    else
      screen.pbDisplay(_INTL("Error al crear regalo misterioso."))
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :duplicate, {
  "name"      => _INTL("Duplicar"),
  "order"     => 220,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    if screen.is_a?(PokemonScreen)
      # En PokemonScreen
      if Kernel.pbConfirmMessage(_INTL("¿Estás seguro de que quieres copiar este Pokémon?"))
        clonedpkmn = pkmn.clone
        clonedpkmn.iv = pkmn.iv.clone if pkmn.iv
        clonedpkmn.ev = pkmn.ev.clone if pkmn.ev
        pbStorePokemon(clonedpkmn)
        screen.pbHardRefresh
        screen.pbDisplay(_INTL("El Pokémon fue duplicado."))
        next :break
      end
    else
      # En PokemonStorageScreen
      if Kernel.pbConfirmMessage(_INTL("¿Estás seguro de que quieres copiar este Pokémon?"))
        clonedpkmn = pkmn.clone
        clonedpkmn.iv = pkmn.iv.clone if pkmn.iv
        clonedpkmn.ev = pkmn.ev.clone if pkmn.ev
        # Aquí necesitarías lógica para almacenar en el PC
        screen.pbDisplay(_INTL("Duplicación en almacenamiento aún no implementada."))
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :delete, {
  "name"      => _INTL("Borrar"),
  "order"     => 230,
  "effect"    => proc { |screen, pkmn, pkmnid_or_selected, heldpoke|
    if screen.is_a?(PokemonScreen)
      # En PokemonScreen
      if Kernel.pbConfirmMessage(_INTL("¿Estás seguro de que quieres borrar este Pokémon?"))
        screen.party[pkmnid_or_selected] = nil
        screen.party.compact!
        screen.pbHardRefresh
        screen.pbDisplay(_INTL("El Pokémon fue borrado."))
        next :break
      end
    else
      # En PokemonStorageScreen
      if Kernel.pbConfirmMessage(_INTL("¿Estás seguro de que quieres borrar este Pokémon?"))
        screen.scene.pbRelease(selected,heldpoke)
        if heldpoke
          @heldpkmn=nil
        else
          @storage.pbDelete(selected[0],selected[1])
        end
        screen.pbHardRefresh
        screen.pbDisplay(_INTL("El Pokémon fue borrado."))
        break
      end
    end
    next false
  }
})