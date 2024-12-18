class PokemonMenu_Scene
  def pbShowCommands(commands)
    ret=-1
    cmdwindow=@sprites["cmdwindow"]
    cmdwindow.viewport=@viewport
    cmdwindow.index=$PokemonTemp.menuLastChoice
    cmdwindow.resizeToFit(commands)
    cmdwindow.commands=commands
    cmdwindow.x=Graphics.width-cmdwindow.width
    cmdwindow.y=0
    cmdwindow.visible=true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        ret=-1
        break
      end
      if Input.trigger?(Input::C)
        pbPlayDecisionSE
        ret=cmdwindow.index
        $PokemonTemp.menuLastChoice=ret
        break
      end
    end
    return ret
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text,Graphics.height)
    @sprites["infowindow"].text=text
    @sprites["infowindow"].visible=true
    @infostate=true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text,Graphics.height)
    @sprites["helpwindow"].text=text
    @sprites["helpwindow"].visible=true
    @helpstate=true
    pbBottomLeft(@sprites["helpwindow"])
  end

  def pbStartScene
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    @sprites["cmdwindow"]=Window_CommandPokemon.new([])
    @sprites["infowindow"]=Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["infowindow"].visible=false
    @sprites["helpwindow"]=Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["helpwindow"].visible=false
    @sprites["cmdwindow"].visible=false
    @infostate=false
    @helpstate=false
    pbSEPlay("GUI menu open")
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible=false
    @sprites["infowindow"].visible=false
    @sprites["helpwindow"].visible=false
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible=true
    @sprites["infowindow"].visible=@infostate
    @sprites["helpwindow"].visible=@helpstate
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh
  end
end



class PokemonMenu
  def initialize(scene)
    @scene=scene
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbStartPokemonMenu
    @scene.pbStartScene
    endscene=true
    pbSetViableDexes
    commands=[]
    cmdPokedex  = -1
    cmdPokemon  = -1
    cmdBag      = -1
    cmdTrainer  = -1
    cmdSave     = -1
    cmdOption   = -1
    cmdPokegear = -1
    cmdDebug    = -1
    cmdQuit     = -1
    cmdEndGame  = -1
    if !$Trainer
      if $DEBUG
        Kernel.pbMessage(_INTL("El entrenador no ha sido definido, por lo tanto no puede ser mostrado."))
        Kernel.pbMessage(_INTL("Por favor, consulta la documentación para aprender a configurar un entrenador."))
      end
      return
    end
    commands[cmdPokedex=commands.length]=_INTL("Pokédex") if $Trainer.pokedex && $PokemonGlobal.pokedexViable.length>0
    commands[cmdPokemon=commands.length]=_INTL("Pokémon") if $Trainer.party.length>0
    commands[cmdBag=commands.length]=_INTL("Mochila") if !pbInBugContest?
    commands[cmdPokegear=commands.length]=_INTL("Pokégear") if $Trainer.pokegear
    commands[cmdTrainer=commands.length]=$Trainer.name
    if pbInSafari?
      if SAFARISTEPS<=0
        @scene.pbShowInfo(_INTL("Balls: {1}",pbSafariState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Pasos: {1}/{2}<br>Balls: {3}",pbSafariState.steps,SAFARISTEPS,pbSafariState.ballcount))
      end
      commands[cmdQuit=commands.length]=_INTL("Salir")
    elsif pbInBugContest?
      if pbBugContestState.lastPokemon
        @scene.pbShowInfo(_INTL("Capturado: {1}<br>Nivel: {2}<br>Balls: {3}",
           PBSpecies.getName(pbBugContestState.lastPokemon.species),
           pbBugContestState.lastPokemon.level,
           pbBugContestState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Capturado: Ninguno<br>Balls: {1}",pbBugContestState.ballcount))
      end
      commands[cmdQuit=commands.length]=_INTL("Salir")
    else
      commands[cmdSave=commands.length]=_INTL("Guardar") if !$game_system || !$game_system.save_disabled
    end
    commands[cmdOption=commands.length]=_INTL("Opciones")
    commands[cmdDebug=commands.length]=_INTL("Depurador") if $DEBUG
    commands[cmdEndGame=commands.length]=_INTL("Salir del Juego")
    loop do
      command=@scene.pbShowCommands(commands)
      if cmdPokedex>=0 && command==cmdPokedex
        if DEXDEPENDSONLOCATION
          pbFadeOutIn(99999) {
             scene=PokemonPokedexScene.new
             screen=PokemonPokedex.new(scene)
             screen.pbStartScreen
             @scene.pbRefresh
          }
        else
          if $PokemonGlobal.pokedexViable.length==1
            $PokemonGlobal.pokedexDex=$PokemonGlobal.pokedexViable[0]
            $PokemonGlobal.pokedexDex=-1 if $PokemonGlobal.pokedexDex==$PokemonGlobal.pokedexUnlocked.length-1
            pbFadeOutIn(99999) {
               scene=PokemonPokedexScene.new
               screen=PokemonPokedex.new(scene)
               screen.pbStartScreen
               @scene.pbRefresh
            }
          else
            pbLoadRpgxpScene(Scene_PokedexMenu.new)
          end
        end
      elsif cmdPokegear>=0 && command==cmdPokegear
        pbLoadRpgxpScene(Scene_Pokegear.new)
      elsif cmdPokemon>=0 && command==cmdPokemon
        sscene=PokemonScreen_Scene.new
        sscreen=PokemonScreen.new(sscene,$Trainer.party)
        hiddenmove=nil
        pbFadeOutIn(99999) { 
           hiddenmove=sscreen.pbPokemonScreen
           if hiddenmove
             @scene.pbEndScene
           else
             @scene.pbRefresh
           end
        }
        if hiddenmove
          Kernel.pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
          return
        end
      elsif cmdBag>=0 && command==cmdBag
        item=0
        scene=PokemonBag_Scene.new
        screen=PokemonBagScreen.new(scene,$PokemonBag)
        pbFadeOutIn(99999) { 
           item=screen.pbStartScreen 
           if item>0
             @scene.pbEndScene
           else
             @scene.pbRefresh
           end
        }
        if item>0
          Kernel.pbUseKeyItemInField(item)
          return
        end
      elsif cmdTrainer>=0 && command==cmdTrainer
        scene=PokemonTrainerCardScene.new
        screen=PokemonTrainerCard.new(scene)
        pbFadeOutIn(99999) { 
           screen.pbStartScreen
           @scene.pbRefresh
        }
      elsif cmdQuit>=0 && command==cmdQuit
        @scene.pbHideMenu
        if pbInSafari?
          if Kernel.pbConfirmMessage(_INTL("¿Quieres dejar el Safari de inmediato?"))
            @scene.pbEndScene
            pbSafariState.decision=1
            pbSafariState.pbGoToStart
            return
          else
            pbShowMenu
          end
        else
          if Kernel.pbConfirmMessage(_INTL("¿Quieres terminar el Consurso ahora?"))
            @scene.pbEndScene
            pbBugContestState.pbStartJudging
            return
          else
            pbShowMenu
          end
        end
      elsif cmdSave>=0 && command==cmdSave
        @scene.pbHideMenu
        scene=PokemonSaveScene.new
        screen=PokemonSave.new(scene)
        if screen.pbSaveScreen
          @scene.pbEndScene
          endscene=false
          break
        else
          pbShowMenu
        end
      elsif cmdDebug>=0 && command==cmdDebug
        pbFadeOutIn(99999) { 
           pbDebugMenu
           @scene.pbRefresh
        }
      elsif cmdOption>=0 && command==cmdOption
        scene=PokemonOptionScene.new
        screen=PokemonOption.new(scene)
        pbFadeOutIn(99999) {
           screen.pbStartScreen
           pbUpdateSceneMap
           @scene.pbRefresh
        }
      elsif cmdEndGame>=0 && command==cmdEndGame
        @scene.pbHideMenu
        if Kernel.pbConfirmMessage(_INTL("¿Quieres salir del juego?"))
          scene=PokemonSaveScene.new
          screen=PokemonSave.new(scene)
          if screen.pbSaveScreen
            @scene.pbEndScene
          end
          @scene.pbEndScene
          $scene=nil
          return
        else
          pbShowMenu
        end
      else
        break
      end
    end
    @scene.pbEndScene if endscene
  end  
end