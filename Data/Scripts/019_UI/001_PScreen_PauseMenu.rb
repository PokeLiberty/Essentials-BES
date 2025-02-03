#===============================================================================
#
#===============================================================================
class Game_Temp
  attr_accessor :menu_last_choice         # pause menu: index of last selection
  
  alias pMenu_initialize initialize
  def initialize
    pMenu_initialize
    @menu_last_choice       = 0
  end
end

class PokemonMenu_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 32, 32, @viewport)
    @sprites["helpwindow"].visible = false
    @infostate = false
    @helpstate = false
    pbSEPlay("GUI menu open")
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text, Graphics.height)
    @sprites["infowindow"].text    = text
    @sprites["infowindow"].visible = true
    @infostate = true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text, Graphics.height)
    @sprites["helpwindow"].text    = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
    @helpstate = true
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = true
    @sprites["infowindow"].visible = @infostate
    @sprites["helpwindow"].visible = @helpstate
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"].visible = false
  end

  def pbShowCommands(commands)
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = commands
    cmdwindow.index    = $game_temp.menu_last_choice
    cmdwindow.resizeToFit(commands)
    cmdwindow.x        = Graphics.width - cmdwindow.width
    cmdwindow.y        = 0
    cmdwindow.visible  = true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::B) || Input.trigger?(Input::A)
        ret = -1
        break
      elsif Input.trigger?(Input::C)
        ret = cmdwindow.index
        $game_temp.menu_last_choice = ret
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh; end
end

#===============================================================================
#
#===============================================================================
class PokemonMenu
  def initialize(scene)
    @scene = scene
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbShowInfo; end

  def pbStartPokemonMenu
    if !$Trainer
      if $DEBUG
        Kernel.pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
        Kernel.pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
      end
      return
    end
    @scene.pbStartScene
    # Show extra info window if relevant
    pbShowInfo
    pbSetViableDexes
    # Get all commands
    command_list = []
    commands = []
    MenuHandlers.each_available(:pause_menu) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    # Main loop
    end_scene = false
    loop do
      choice = @scene.pbShowCommands(command_list)
      if choice < 0
        pbPlayCloseMenuSE
        end_scene = true
        break
      end
      break if commands[choice]["effect"].call(@scene)
    end
    @scene.pbEndScene if end_scene
  end
end

#Añade la información del safari/captura de bichos.
class PokemonMenu
  alias_method :__original_pbShowInfo, :pbShowInfo unless method_defined?(:__original_pbShowInfo)

  def pbShowInfo
    __original_pbShowInfo
    if pbInSafari?
      safari_info = if SAFARISTEPS > 0
                      _INTL("Pasos: {1}/{2}\nBalls: {3}",pbSafariState.steps,SAFARISTEPS,pbSafariState.ballcount)
                    else
                      _INTL("Balls: {1}",pbSafariState.ballcount)
                    end
      return @scene.pbShowInfo(safari_info)
    end

    if pbInBugContest?
      if pbBugContestState.lastPokemon
        contest_info = _INTL("Capturado: {1}\nNivel: {2}\nBalls: {3}",
                             PBSpecies.getName(pbBugContestState.lastPokemon.species),
                             pbBugContestState.lastPokemon.level,
                             pbBugContestState.ballcount)
      else
        contest_info = _INTL("Capturado: None\nBalls: {1}", pbBugContestState.ballcount)
      end
      return @scene.pbShowInfo(contest_info)
    end
  end
end

#===============================================================================
# Pause menu commands.
#===============================================================================
MenuHandlers.add(:pause_menu, :pokedex, {
  "name"      => _INTL("Pokédex"),
  "order"     => 10,
  "condition" => proc { next $Trainer.pokedex && $PokemonGlobal.pokedexViable.length>0},
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    if DEXDEPENDSONLOCATION
      pbFadeOutIn(99999) {
        scene=PokemonPokedexScene.new
        screen=PokemonPokedex.new(scene)
        screen.pbStartScreen
        menu.pbRefresh
      }
    else
      if $PokemonGlobal.pokedexViable.length==1
        $PokemonGlobal.pokedexDex=$PokemonGlobal.pokedexViable[0]
        $PokemonGlobal.pokedexDex=-1 if $PokemonGlobal.pokedexDex==$PokemonGlobal.pokedexUnlocked.length-1
        pbFadeOutIn(99999) {
          scene=PokemonPokedexScene.new
          screen=PokemonPokedex.new(scene)
          screen.pbStartScreen
          menu.pbRefresh
        }
      else
        pbLoadRpgxpScene(Scene_PokedexMenu.new)
      end
    end
    next false
  }
})

MenuHandlers.add(:pause_menu, :party, {
  "name"      => _INTL("Pokémon"),
  "order"     => 20,
  "condition" => proc { next $Trainer.party.length>0 },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    sscene=PokemonScreen_Scene.new
    sscreen=PokemonScreen.new(sscene,$Trainer.party)
    hiddenmove=nil
    pbFadeOutIn(99999) { 
      hiddenmove=sscreen.pbPokemonScreen
      if hiddenmove
        menu.pbEndScene
      else
        menu.pbRefresh
      end
    }
    next false if !hiddenmove
    $game_temp.in_menu = false
    Kernel.pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
    next true
  }
})

MenuHandlers.add(:pause_menu, :bag, {
  "name"      => _INTL("Bolsa"),
  "order"     => 30,
  "condition" => proc { next !pbInBugContest? },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    item=0
    scene=PokemonBag_Scene.new
    screen=PokemonBagScreen.new(scene,$PokemonBag)
    pbFadeOutIn(99999) { 
      item=screen.pbStartScreen 
      if item>0
        menu.pbEndScene
      else
        menu.pbRefresh
      end
    }
    next false unless item>0
    $game_temp.in_menu = false
    Kernel.pbUseKeyItemInField(item)
    next true
  }
})

MenuHandlers.add(:pause_menu, :pokegear, {
  "name"      => _INTL("Pokégear"),
  "order"     => 40,
  "condition" => proc { next $Trainer.pokegear },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn(99999) {
      scene = Scene_Pokegear.new
      screen = PokemonPokegearScreen.new(scene)
      screen.pbStartScreen
      menu.pbRefresh
    }
    next false
  }
})

MenuHandlers.add(:pause_menu, :town_map, {
  "name"      => _INTL("Mapa"),
  "order"     => 40,
  "condition" => proc { next !$Trainer.pokegear && $PokemonBag.pbQuantity(:TOWNMAP)>0 },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbShowMap(-1,false)
  }
})

MenuHandlers.add(:pause_menu, :trainer_card, {
  "name"      => proc { next $Trainer.name },
  "order"     => 50,
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn(99999) {
      scene = PokemonTrainerCard_Scene.new
      screen = PokemonTrainerCardScreen.new(scene)
      screen.pbStartScreen
      menu.pbRefresh
    }
    next false
  }
})

MenuHandlers.add(:pause_menu, :save, {
  "name"      => _INTL("Guardar"),
  "order"     => 60,
  "condition" => proc {
    next $game_system && !$game_system.save_disabled && !pbInSafari? && !pbInBugContest?
  },
  "effect"    => proc { |menu|
    menu.pbHideMenu
    scene = PokemonSave_Scene.new
    screen = PokemonSaveScreen.new(scene)
    if screen.pbSaveScreen
      menu.pbEndScene
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
})

MenuHandlers.add(:pause_menu, :quit_game, {
  "name"      => _INTL("Retirarse"),
  "order"     => 60,
  "condition" => proc {
    next pbInSafari? || pbInBugContest?
  },
  "effect"    => proc { |menu|
    menu.pbHideMenu
    if pbInSafari?
      if Kernel.pbConfirmMessage(_INTL("¿Quieres dejar el Safari de inmediato?"))
        menu.pbEndScene
        pbSafariState.decision=1
        pbSafariState.pbGoToStart
        next true
      else
        menu.pbRefresh
        menu.pbShowMenu
        next false
      end
    else
      if Kernel.pbConfirmMessage(_INTL("¿Quieres terminar el Consurso ahora?"))
        menu.pbEndScene
        pbBugContestState.pbStartJudging
        next true
      else
        menu.pbRefresh
        menu.pbShowMenu
        next false
      end
    end

    next false
  }
})

MenuHandlers.add(:pause_menu, :options, {
  "name"      => _INTL("Opciones"),
  "order"     => 70,
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    scene=PokemonOptionScene.new
    screen=PokemonOption.new(scene)
    pbFadeOutIn(99999) {
      screen.pbStartScreen
      pbUpdateSceneMap
      menu.pbRefresh
    }
    next false
  }
})

MenuHandlers.add(:pause_menu, :debug, {
  "name"      => _INTL("Debug"),
  "order"     => 80,
  "condition" => proc { next $DEBUG },
  "effect"    => proc { |menu|
    pbPlayDecisionSE
    pbFadeOutIn(99999) { 
      pbDebugMenu
      menu.pbRefresh
    }
    next false
  }
})

MenuHandlers.add(:pause_menu, :quit_game, {
  "name"      => _INTL("Salir del Juego"),
  "order"     => 90,
  "effect"    => proc { |menu|
    menu.pbHideMenu
    if Kernel.pbConfirmMessage(_INTL("¿Quieres salir del juego?"))
      scene=PokemonSaveScene.new
      screen=PokemonSave.new(scene)
      if screen.pbSaveScreen
        menu.pbEndScene
      end
      menu.pbEndScene
      $scene=nil
      next true
    end
    menu.pbRefresh
    menu.pbShowMenu
    next false
  }
})