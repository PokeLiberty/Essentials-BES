#===============================================================================
# BES-T
# El debug de PScreen_Storage y PScreen_Party, para facilitar la edición de codigo en estos dos ultimos de forma más sencilla.
#===============================================================================
class PokemonScreen
  def pbPokemonDebug(pkmn,pkmnid)
    command=0
    loop do
      command=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
         _INTL("PS/Estado"),
         _INTL("Nivel"),
         _INTL("Especie"),
         _INTL("Movimientos"),
         _INTL("Género"),
         _INTL("Habilidad"),
         _INTL("Naturaleza"),
         _INTL("Shininess"),
         _INTL("Forma"),
         _INTL("Felicidad"),
         _INTL("EV/IV/pID"),
         _INTL("Pokérus"),
         _INTL("EO"),
         _INTL("Apodo"),
         _INTL("Poké Ball"),
         _INTL("Cintas"),
         _INTL("Huevo"),
         _INTL("Pokémon Oscuro"),
         _INTL("Teracristalización"),
         _INTL("Dynamax"),
         _INTL("Hacer Reg. Mist."),
         _INTL("Duplicar"),
         _INTL("Borrar"),
         _INTL("Salir")
      ],command)
      case command
      ### Cancel ###
      when -1, 22
        break
      ### HP/Status ###
      when 0
        cmd=0
        loop do
          cmd=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
             _INTL("Setear PS"),
             _INTL("Estado: Dormido"),
             _INTL("Estado: Envenenado"),
             _INTL("Estado: Quemado"),
             _INTL("Estado: Paralizado"),
             _INTL("Estado: Congelado"),
             _INTL("Debilitar"),
             _INTL("Curar")
          ],cmd)
          # Break
          if cmd==-1
            break
          # Set HP
          elsif cmd==0
            params=ChooseNumberParams.new
            params.setRange(0,pkmn.totalhp)
            params.setDefaultValue(pkmn.hp)
            newhp=Kernel.pbMessageChooseNumber(
               _INTL("Establecer los PS del Pokémon (máx. {1}).",pkmn.totalhp),params) { @scene.update }
            if newhp!=pkmn.hp
              pkmn.hp=newhp
              pbDisplay(_INTL("Los PS de {1} se establecieron en {2}.",pkmn.name,pkmn.hp))
              pbRefreshSingle(pkmnid)
            end
          # Set status
          elsif cmd>=1 && cmd<=5
            if pkmn.hp>0
              pkmn.status=cmd
              pkmn.statusCount=0
              if pkmn.status==PBStatuses::SLEEP
                params=ChooseNumberParams.new
                params.setRange(0,9)
                params.setDefaultValue(0)
                sleep=Kernel.pbMessageChooseNumber(
                   _INTL("Establecer el contador de sueño del Pokémon."),params) { @scene.update }
                pkmn.statusCount=sleep
              end
              pbDisplay(_INTL("El estado de {1} fue cambiado.",pkmn.name))
              pbRefreshSingle(pkmnid)
            else
              pbDisplay(_INTL("El estado de {1} no pudo ser cambiado.",pkmn.name))
            end
          # Faint  /  Debilitado
          elsif cmd==6
            pkmn.hp=0
            pbDisplay(_INTL("Los PS de {1} están en 0.",pkmn.name))
            pbRefreshSingle(pkmnid)
          # Heal   /  Curado
          elsif cmd==7
            pkmn.heal
            pbDisplay(_INTL("{1} está completamente curado.",pkmn.name))
            pbRefreshSingle(pkmnid)
          end
        end
      ### Level ###
      when 1
        params=ChooseNumberParams.new
        params.setRange(1,PBExperience::MAXLEVEL)
        params.setDefaultValue(pkmn.level)
        level=Kernel.pbMessageChooseNumber(
           _INTL("Establecer el nivel del Pokémon (máx. {1}).",PBExperience::MAXLEVEL),params) { @scene.update }
        if level!=pkmn.level
          pkmn.level=level
          pkmn.calcStats
          pbDisplay(_INTL("El nivel del {1} se estableció en {2}.",pkmn.name,pkmn.level))
          pbRefreshSingle(pkmnid)
        end
      ### Species ###
      when 2
        species=pbChooseSpecies(pkmn.species)
        if species!=0
          oldspeciesname=PBSpecies.getName(pkmn.species)
          pkmn.species=species
          pkmn.calcStats
          oldname=pkmn.name
          pkmn.name=PBSpecies.getName(pkmn.species) if pkmn.name==oldspeciesname
          pbDisplay(_INTL("La especie de {1} fue cambiada a {2}.",oldname,PBSpecies.getName(pkmn.species)))
          pbSeenForm(pkmn)
          pbRefreshSingle(pkmnid)
        end
      ### Moves ###
      when 3
        cmd=0
        loop do
          cmd=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
             _INTL("Enseñar movimiento"),
             _INTL("Olvidar movimiento"),
             _INTL("Restaurar lista de mov."),
             _INTL("Restaurar mov. iniciales")],cmd)
          # Break
          if cmd==-1
            break
          # Teach move
          elsif cmd==0
            move=pbChooseMoveList
            if move!=0
              pbLearnMove(pkmn,move)
              pbRefreshSingle(pkmnid)
            end
          # Forget move
          elsif cmd==1
            move=pbChooseMove(pkmn,_INTL("Seleccione el movimiento a olvidar."))
            if move>=0
              movename=PBMoves.getName(pkmn.moves[move].id)
              pkmn.pbDeleteMoveAtIndex(move)
              pbDisplay(_INTL("{1} olvidó {2}.",pkmn.name,movename))
              pbRefreshSingle(pkmnid)
            end
          # Reset movelist
          elsif cmd==2
            pkmn.resetMoves
            pbDisplay(_INTL("Los movimientos de {1} fueron restablecidos.",pkmn.name))
            pbRefreshSingle(pkmnid)
          # Reset initial moves
          elsif cmd==3
            pkmn.pbRecordFirstMoves
            pbDisplay(_INTL("{1} recuperó sus movimientos iniciales.",pkmn.name))
            pbRefreshSingle(pkmnid)
          end
        end
      ### Gender ###
      when 4
        if pkmn.gender==2
          pbDisplay(_INTL("{1} no tiene género.",pkmn.name))
        else
          cmd=0
          loop do
            oldgender=(pkmn.isMale?) ? _INTL("macho") : _INTL("hembra")
            msg=[_INTL("El género {1} es natural.",oldgender),
                 _INTL("El género {1} es forzado.",oldgender)][pkmn.genderflag ? 1 : 0]
            cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer macho"),
               _INTL("Hacer hembra"),
               _INTL("Quitar cambio")],cmd)
            # Break
            if cmd==-1
              break
            # Make male
            elsif cmd==0
              pkmn.setGender(0)
              if pkmn.isMale?
                pbDisplay(_INTL("Ahora {1} es macho.",pkmn.name))
              else
                pbDisplay(_INTL("El género de {1} no se puedo cambiar.",pkmn.name))
              end
            # Make female
            elsif cmd==1
              pkmn.setGender(1)
              if pkmn.isFemale?
                pbDisplay(_INTL("Ahora {1} es hembra.",pkmn.name))
              else
                pbDisplay(_INTL("El género de {1} no se puede cambiar.",pkmn.name))
              end
            # Remove override
            elsif cmd==2
              pkmn.genderflag=nil
              pbDisplay(_INTL("Se quitó el cambio de género."))
            end
            pbSeenForm(pkmn)
            pbRefreshSingle(pkmnid)
          end
        end
      ### Ability ###
      when 5
        cmd=0
        loop do
          abils=pkmn.getAbilityList
          oldabil=PBAbilities.getName(pkmn.ability)
          commands=[]
          for i in abils
            commands.push((i[1]<2 ? "" : "(H) ")+PBAbilities.getName(i[0]))
          end
          commands.push(_INTL("Quitar cambio"))
          msg=[_INTL("La habilidad {1} es natural.",oldabil),
               _INTL("La habilidad {1} es forzada.",oldabil)][pkmn.abilityflag!=nil ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,commands,cmd)
          # Break
          if cmd==-1
            break
          # Set ability override
          elsif cmd>=0 && cmd<abils.length
            pkmn.setAbility(abils[cmd][1])
          # Remove override
          elsif cmd==abils.length
            pkmn.abilityflag=nil
          end
          pbRefreshSingle(pkmnid)
        end
      ### Nature ###
      when 6
        cmd=0
        loop do
          oldnature=PBNatures.getName(pkmn.nature)
          commands=[]
          (PBNatures.getCount).times do |i|
            commands.push(PBNatures.getName(i))
          end
          commands.push(_INTL("Quitar cambio"))
          msg=[_INTL("La naturaleza {1} es natural.",oldnature),
               _INTL("La naturaleza {1} es forzada.",oldnature)][pkmn.natureflag ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,commands,cmd)
          # Break
          if cmd==-1
            break
          # Set nature override
          elsif cmd>=0 && cmd<PBNatures.getCount
            pkmn.setNature(cmd)
            pkmn.calcStats
          # Remove override
          elsif cmd==PBNatures.getCount
            pkmn.natureflag=nil
          end
          pbRefreshSingle(pkmnid)
        end
      ### Shininess ###
      when 7
        cmd=0
        loop do
          oldshiny=(pkmn.isShiny?) ? _INTL("shiny") : _INTL("normal")
          msg=[_INTL("Shininess ({1}) es natural.",oldshiny),
               _INTL("Shininess ({1}) es forzado.",oldshiny)][pkmn.shinyflag!=nil ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer shiny"),
               _INTL("Hacer normal"),
               _INTL("Quitar cambio")],cmd)
          # Break
          if cmd==-1
            break
          # Make shiny
          elsif cmd==0
            pkmn.makeShiny
          # Make normal
          elsif cmd==1
            pkmn.makeNotShiny
          # Remove override
          elsif cmd==2
            pkmn.shinyflag=nil
          end
          pbRefreshSingle(pkmnid)
        end
      ### Form ###
      when 8
        params=ChooseNumberParams.new
        params.setRange(0,100)
        params.setDefaultValue(pkmn.form)
        f=Kernel.pbMessageChooseNumber(
           _INTL("Establecer la forma del Pokémon."),params) { @scene.update }
        if f!=pkmn.form
          pkmn.form=f
          pbDisplay(_INTL("La forma de {1} se cambió a {2}.",pkmn.name,pkmn.form))
          pbSeenForm(pkmn)
          pbRefreshSingle(pkmnid)
        end
      ### Happiness ###
      when 9
        params=ChooseNumberParams.new
        params.setRange(0,255)
        params.setDefaultValue(pkmn.happiness)
        h=Kernel.pbMessageChooseNumber(
           _INTL("Establecer la felicidad de Pokémon (máx. 255)."),params) { @scene.update }
        if h!=pkmn.happiness
          pkmn.happiness=h
          pbDisplay(_INTL("La felicidad de {1} fue establecida en {2}.",pkmn.name,pkmn.happiness))
          pbRefreshSingle(pkmnid)
        end
      ### EV/IV/pID ###
      when 10
        stats=[_INTL("PS"),_INTL("Ataque"),_INTL("Defensa"),
               _INTL("Velocidad"),_INTL("At. Esp."),_INTL("Def. Esp.")]
        cmd=0
        loop do
          persid=sprintf("0x%08X",pkmn.personalID)
          cmd=@scene.pbShowCommands(_INTL("ID personal es {1}.",persid),[
             _INTL("Setear EVs"),
             _INTL("Setear IVs"),
             _INTL("Randomise pID")],cmd)
          case cmd
          # Break
          when -1
            break
          # Set EVs
          when 0
            cmd2=0
            loop do
              evcommands=[]
              for i in 0...stats.length
                evcommands.push(stats[i]+" (#{pkmn.ev[i]})")
              end
              cmd2=@scene.pbShowCommands(_INTL("¿Cuál EV cambiar?"),evcommands,cmd2)
              if cmd2==-1
                break
              elsif cmd2>=0 && cmd2<stats.length
                params=ChooseNumberParams.new
                params.setRange(0,PokeBattle_Pokemon::EVSTATLIMIT)
                params.setDefaultValue(pkmn.ev[cmd2])
                params.setCancelValue(pkmn.ev[cmd2])
                f=Kernel.pbMessageChooseNumber(
                   _INTL("SEstablecer el EV para {1} (máx. {2}).",
                      stats[cmd2],PokeBattle_Pokemon::EVSTATLIMIT),params) { @scene.update }
                pkmn.ev[cmd2]=f
                pkmn.totalhp
                pkmn.calcStats
                pbRefreshSingle(pkmnid)
              end
            end
          # Set IVs
          when 1
            cmd2=0
            loop do
              hiddenpower=pbHiddenPower(pkmn.iv)
              msg=_INTL("Poder Oculto:\n{1}, potencia {2}.",PBTypes.getName(hiddenpower[0]),hiddenpower[1])
              ivcommands=[]
              for i in 0...stats.length
                ivcommands.push(stats[i]+" (#{pkmn.iv[i]})")
              end
              ivcommands.push(_INTL("Hacer aleatorio"))
              cmd2=@scene.pbShowCommands(msg,ivcommands,cmd2)
              if cmd2==-1
                break
              elsif cmd2>=0 && cmd2<stats.length
                params=ChooseNumberParams.new
                params.setRange(0,31)
                params.setDefaultValue(pkmn.iv[cmd2])
                params.setCancelValue(pkmn.iv[cmd2])
                f=Kernel.pbMessageChooseNumber(
                   _INTL("Establecer el IV para {1} (máx. 31).",stats[cmd2]),params) { @scene.update }
                pkmn.iv[cmd2]=f
                pkmn.calcStats
                pbRefreshSingle(pkmnid)
              elsif cmd2==ivcommands.length-1
                pkmn.iv[0]=rand(32)
                pkmn.iv[1]=rand(32)
                pkmn.iv[2]=rand(32)
                pkmn.iv[3]=rand(32)
                pkmn.iv[4]=rand(32)
                pkmn.iv[5]=rand(32)
                pkmn.calcStats
                pbRefreshSingle(pkmnid)
              end
            end
          # Randomise pID
          when 2
            pkmn.personalID=rand(256)
            pkmn.personalID|=rand(256)<<8
            pkmn.personalID|=rand(256)<<16
            pkmn.personalID|=rand(256)<<24
            pkmn.calcStats
            pbRefreshSingle(pkmnid)
          end
        end
      ### Pokérus ###
      when 11
        cmd=0
        loop do
          pokerus=(pkmn.pokerus) ? pkmn.pokerus : 0
          msg=[_INTL("{1} no tiene Pokérus.",pkmn.name),
               _INTL("Tiene grado {1}, infectado por {2} días más.",pokerus/16,pokerus%16),
               _INTL("Tiene grado {1}, no infectado.",pokerus/16)][pkmn.pokerusStage]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Dar grado aleatorio"),
               _INTL("Hacer no infectado"),
               _INTL("Limpiar Pokérus")],cmd)
          # Break
          if cmd==-1
            break
          # Give random strain
          elsif cmd==0
            pkmn.givePokerus
          # Make not infectious
          elsif cmd==1
            strain=pokerus/16
            p=strain<<4
            pkmn.pokerus=p
          # Clear Pokérus
          elsif cmd==2
            pkmn.pokerus=0
          end
        end
      ### Ownership ###
      when 12
        cmd=0
        loop do
          gender=[_INTL("Masculino"),_INTL("Femenino"),_INTL("Desconocido")][pkmn.otgender]
          msg=[_INTL("Pokémon del jugador\n{1}\n{2}\n{3} ({4})",pkmn.ot,gender,pkmn.publicID,pkmn.trainerID),
               _INTL("Pokémon extranjero\n{1}\n{2}\n{3} ({4})",pkmn.ot,gender,pkmn.publicID,pkmn.trainerID)
              ][pkmn.isForeign?($Trainer) ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer del jugador"),
               _INTL("Setear nombre del EO"),
               _INTL("Setear género del EO"),
               _INTL("ID extranjero aleatorio"),
               _INTL("Setear ID extranjero")],cmd)
          # Break
          if cmd==-1
            break
          # Make player's
          elsif cmd==0
            pkmn.trainerID=$Trainer.id
            pkmn.ot=$Trainer.name
            pkmn.otgender=$Trainer.gender
          # Set OT's name
          elsif cmd==1
            newot=pbEnterPlayerName(_INTL("Nombre del EO de {1}",pkmn.name),1,7)
            pkmn.ot=newot
          # Set OT's gender
          elsif cmd==2
            cmd2=@scene.pbShowCommands(_INTL("Establecer el género del EO."),
               [_INTL("Masculino"),_INTL("Femenino"),_INTL("Desconocido")])
            pkmn.otgender=cmd2 if cmd2>=0
          # Random foreign ID
          elsif cmd==3
            pkmn.trainerID=$Trainer.getForeignID
          # Set foreign ID
          elsif cmd==4
            params=ChooseNumberParams.new
            params.setRange(0,65535)
            params.setDefaultValue(pkmn.publicID)
            val=Kernel.pbMessageChooseNumber(
               _INTL("Setear el nuevo ID (máx. 65535)."),params) { @scene.update }
            pkmn.trainerID=val
            pkmn.trainerID|=val<<16
          end
        end
      ### Nickname ###
      when 13
        cmd=0
        loop do
          speciesname=PBSpecies.getName(pkmn.species)
          msg=[_INTL("{1} tiene el apodo {2}.",speciesname,pkmn.name),
               _INTL("{1} no tiene apodo.",speciesname)][pkmn.name==speciesname ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Renombrar"),
               _INTL("Borrar nombre")],cmd)
          # Break
          if cmd==-1
            break
          # Rename
          elsif cmd==0
            newname=pbEnterPokemonName(_INTL("Apodo de {1}",speciesname),0,10,"",pkmn)
            pkmn.name=(newname=="") ? speciesname : newname
            pbRefreshSingle(pkmnid)
          # Erase name
          elsif cmd==1
            pkmn.name=speciesname
          end
        end
      ### Poké Ball ###
      when 14
        cmd=0
        loop do
          oldball=PBItems.getName(pbBallTypeToBall(pkmn.ballused))
          commands=[]; balls=[]
          for key in $BallTypes.keys
            item=getID(PBItems,$BallTypes[key])
            balls.push([key,PBItems.getName(item)]) if item && item>0
          end
          balls.sort! {|a,b| a[1]<=>b[1]}
          for i in 0...commands.length
            cmd=i if pkmn.ballused==balls[i][0]
          end
          for i in balls
            commands.push(i[1])
          end
          cmd=@scene.pbShowCommands(_INTL("Usada {1}.",oldball),commands,cmd)
          if cmd==-1
            break
          else
            pkmn.ballused=balls[cmd][0]
          end
        end
      ### Ribbons ###
      when 15
        cmd=0
        loop do
          commands=[]
          for i in 1..PBRibbons.maxValue
            commands.push(_INTL("{1} {2}",
               pkmn.hasRibbon?(i) ? "[X]" : "[  ]",PBRibbons.getName(i)))
          end
          cmd=@scene.pbShowCommands(_INTL("{1} cintas.",pkmn.ribbonCount),commands,cmd)
          if cmd==-1
            break
          elsif cmd>=0 && cmd<commands.length
            if pkmn.hasRibbon?(cmd+1)
              pkmn.takeRibbon(cmd+1)
            else
              pkmn.giveRibbon(cmd+1)
            end
          end
        end
      ### Egg ###
      when 16
        cmd=0
        loop do
          msg=[_INTL("No es un huevo"),
               _INTL("Huevo con pasos: {1}.",pkmn.eggsteps)][pkmn.isEgg? ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer huevo"),
               _INTL("Hacer Pokémon"),
               _INTL("Setear pasos en 1")],cmd)
          # Break
          if cmd==-1
            break
          # Make egg
          elsif cmd==0
            if pbHasEgg?(pkmn.species) ||
               pbConfirm(_INTL("{1} no puede ser un huevo. ¿Hacerlo huevo de todas formas?",PBSpecies.getName(pkmn.species)))
              pkmn.level=EGGINITIALLEVEL
              pkmn.calcStats
              pkmn.name=_INTL("Huevo")
              dexdata=pbOpenDexData
              pbDexDataOffset(dexdata,pkmn.species,21)
              pkmn.eggsteps=dexdata.fgetw
              dexdata.close
              pkmn.hatchedMap=0
              pkmn.obtainMode=1
              pbRefreshSingle(pkmnid)
            end
          # Make Pokémon
          elsif cmd==1
            pkmn.name=PBSpecies.getName(pkmn.species)
            pkmn.eggsteps=0
            pkmn.hatchedMap=0
            pkmn.obtainMode=0
            pbRefreshSingle(pkmnid)
          # Set eggsteps to 1
          elsif cmd==2
            pkmn.eggsteps=1 if pkmn.eggsteps>0
          end
        end
      ### Shadow Pokémon ###
      when 17
        cmd=0
        loop do
          msg=[_INTL("No es un Pokémon Oscuro."),
               _INTL("Medidor del corazón en {1}.",pkmn.heartgauge)][(pkmn.isShadow? rescue false) ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
             _INTL("Hacer Oscuro"),
             _INTL("Bajar medidor del corazón")],cmd)
          # Break
          if cmd==-1
            break
          # Make Shadow
          elsif cmd==0
            if !(pkmn.isShadow? rescue false) && pkmn.respond_to?("makeShadow")
              pkmn.makeShadow
              pbDisplay(_INTL("{1} ahora es un Pokémon Oscuro.",pkmn.name))
              pbRefreshSingle(pkmnid)
            else
              pbDisplay(_INTL("{1} ya es un Pokémon Oscuro.",pkmn.name))
            end
          # Lower heart gauge
          elsif cmd==1
            if (pkmn.isShadow? rescue false)
              prev=pkmn.heartgauge
              pkmn.adjustHeart(-700)
              Kernel.pbMessage(_INTL("El medidor del corazón de {1} bajo de {2} a {3} (ahora etapa {4}).",
                 pkmn.name,prev,pkmn.heartgauge,pkmn.heartStage))
              pbReadyToPurify(pkmn)
            else
              Kernel.pbMessage(_INTL("{1} no es un Pokémon Oscuro.",pkmn.name))
            end
          end
        end
      ### Opciones de Teracristalización
      when 18
        cmd=0
        loop do
          cmd=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
             _INTL("Setear Teratipo"),
             _INTL("Teracristalizar")],cmd)
          case cmd
          when -1
            break
          when 0
            cmdt=0
            typenames=[]
            for i in 0..PBTypes.maxValue
              typenames.push(PBTypes.getName(i))
            end
            loop do
              cmdt=@scene.pbShowCommands(_INTL("¿A cual tipo?",pkmn.name),typenames,cmdt)
              pkmn.teratype=cmdt
              break
            end
          when 1
            pkmn.teracristalized=!pkmn.teracristalized
          end
        end
      when 19
        cmd=0
        loop do
          cmd=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
             _INTL("Setear Nivel Dynamax"),
             _INTL("Factor Gigamax")],cmd)
          case cmd
          when -1
            break
          when 0
            params=ChooseNumberParams.new
            params.setRange(0,10)
            params.setDefaultValue(pkmn.dynamax_lvl)
            val=Kernel.pbMessageChooseNumber(
               _INTL("Setear el nuevo valor (máx. 100)."),params) { @scene.update }
            pkmn.dynamax_lvl=val
          when 1
            pkmn.gmaxfactor=!pkmn.gmaxfactor
          end
        end
      ### Make Mystery Gift ###
      when 20
        pbCreateMysteryGift(0,pkmn)
      ### Duplicate ###
      when 21
        if pbConfirm(_INTL("¿Estás seguro de que quieres copiar este Pokémon?"))
          clonedpkmn=pkmn.clone
          clonedpkmn.iv=pkmn.iv.clone
          clonedpkmn.ev=pkmn.ev.clone
          pbStorePokemon(clonedpkmn)
          pbHardRefresh
          pbDisplay(_INTL("El Pokémon fue duplicado."))
          break
        end
      ### Delete ###
      when 22
        if pbConfirm(_INTL("¿Estás seguro de que quieres borrar este Pokémon?"))
          @party[pkmnid]=nil
          @party.compact!
          pbHardRefresh
          pbDisplay(_INTL("El Pokémon fue borrado."))
          break
        end
      end
    end
  end
end

class PokemonStorageScreen
  def debugMenu(selected,pkmn,heldpoke)
    command=0
    loop do
      command=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
         _INTL("Nivel"),
         _INTL("Especie"),
         _INTL("Movimientos"),
         _INTL("Género"),
         _INTL("Habilidad"),
         _INTL("Naturaleza"),
         _INTL("Shininess"),
         _INTL("Forma"),
         _INTL("Felicidad"),
         _INTL("EV/IV/pID"),
         _INTL("Pokérus"),
         _INTL("Entren. Original"),
         _INTL("Apodo"),
         _INTL("Poké Ball"),
         _INTL("Cintas"),
         _INTL("Huevo"),
         _INTL("Pokémon Oscuro"),
         _INTL("Hacer Reg. Mist."),
         _INTL("Duplicar"),
         _INTL("Borrar"),
         _INTL("Salir")
      ],command)
      case command
      ### Cancel ###
      when -1, 20
        break
      ### Level ###
      when 0
        params=ChooseNumberParams.new
        params.setRange(1,PBExperience::MAXLEVEL)
        params.setDefaultValue(pkmn.level)
        level=Kernel.pbMessageChooseNumber(
           _INTL("Setear el nivel del Pokémon (máx. {1}).",PBExperience::MAXLEVEL),params)
        if level!=pkmn.level
          pkmn.level=level
          pkmn.calcStats
          pbDisplay(_INTL("El nivel de {1} fue seteado en {2}.",pkmn.name,pkmn.level))
          @scene.pbHardRefresh
        end
      ### Species ###
      when 1
        species=pbChooseSpecies(pkmn.species)
        if species!=0
          oldspeciesname=PBSpecies.getName(pkmn.species)
          pkmn.species=species
          pkmn.calcStats
          oldname=pkmn.name
          pkmn.name=PBSpecies.getName(pkmn.species) if pkmn.name==oldspeciesname
          pbDisplay(_INTL("La especie de {1} se cambió a {2}.",oldname,PBSpecies.getName(pkmn.species)))
          pbSeenForm(pkmn)
          @scene.pbHardRefresh
        end
      ### Moves ###
      when 2
        cmd=0
        loop do
          cmd=@scene.pbShowCommands(_INTL("¿Qué hacer con {1}?",pkmn.name),[
             _INTL("Enseñar movimiento"),
             _INTL("Olvidar movimiento"),
             _INTL("Restablecer lista de movimientos"),
             _INTL("Restablecer movimientos iniciales")],cmd)
          # Break
          if cmd==-1
            break
          # Teach move
          elsif cmd==0
            move=pbChooseMoveList
            if move!=0
              pbLearnMove(pkmn,move)
              @scene.pbHardRefresh
            end
          # Forget Move
          elsif cmd==1
            pbChooseMove(pkmn,1,2)
            if pbGet(1)>=0
              pkmn.pbDeleteMoveAtIndex(pbGet(1))
              pbDisplay(_INTL("{1} olvidó {2}.",pkmn.name,pbGet(2)))
              @scene.pbHardRefresh
            end
          # Reset Movelist
          elsif cmd==2
            pkmn.resetMoves
            pbDisplay(_INTL("Los movimientos de {1} se restablecieron.",pkmn.name))
            @scene.pbHardRefresh
          # Reset initial moves
          elsif cmd==3
            pkmn.pbRecordFirstMoves
            pbDisplay(_INTL("Los movimientos de {1} se restablecieron a sus iniciales.",pkmn.name))
            @scene.pbHardRefresh
          end
        end
      ### Gender ###
      when 3
        if pkmn.gender==2
          pbDisplay(_INTL("{1} no tiene género.",pkmn.name))
        else
          cmd=0
          loop do
            oldgender=(pkmn.isMale?) ? _INTL("macho") : _INTL("hembra")
            msg=[_INTL("El género de {1} es natural.",oldgender),
                 _INTL("El género de {1} es forzado.",oldgender)][pkmn.genderflag ? 1 : 0]
            cmd=@scene.pbShowCommands(msg,[
               _INTL("Cambiar a macho"),
               _INTL("Cambiar a hembra"),
               _INTL("Quitar modificación")],cmd)
            # Break
            if cmd==-1
              break
            # Make male
            elsif cmd==0
              pkmn.setGender(0)
              if pkmn.isMale?
                pbDisplay(_INTL("{1} ahora es macho.",pkmn.name))
              else
                pbDisplay(_INTL("El género de {1} no puede ser cambiado.",pkmn.name))
              end
            # Make female
            elsif cmd==1
              pkmn.setGender(1)
              if pkmn.isFemale?
                pbDisplay(_INTL("{1} ahora es hembra.",pkmn.name))
              else
                pbDisplay(_INTL("El género de {1} no puede ser cambiado.",pkmn.name))
              end
            # Remove override
            elsif cmd==2
              pkmn.genderflag=nil
              pbDisplay(_INTL("Modificación de género retirada."))
            end
            pbSeenForm(pkmn)
            @scene.pbHardRefresh
          end
        end
      ### Ability ###
      when 4
        cmd=0
        loop do
          abils=pkmn.getAbilityList
          oldabil=PBAbilities.getName(pkmn.ability)
          commands=[]
          for i in abils
            commands.push((i[1]<2 ? "" : "(H) ")+PBAbilities.getName(i[0]))
          end
          commands.push(_INTL("Quitar modificación"))
          msg=[_INTL("La habilidad {1} es natural.",oldabil),
               _INTL("La habilidad {1} es forzada.",oldabil)][pkmn.abilityflag!=nil ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,commands,cmd)
          # Break
          if cmd==-1
            break
          # Set ability override
          elsif cmd>=0 && cmd<abils.length
            pkmn.setAbility(abils[cmd][1])
          # Remove override
          elsif cmd==abils.length
            pkmn.abilityflag=nil
          end
          @scene.pbHardRefresh
        end
      ### Nature ###
      when 5
        cmd=0
        loop do
          oldnature=PBNatures.getName(pkmn.nature)
          commands=[]
          (PBNatures.getCount).times do |i|
            commands.push(PBNatures.getName(i))
          end
          commands.push(_INTL("Quitar modificación"))
          msg=[_INTL("La naturaleza {1} es natural.",oldnature),
               _INTL("La naturaleza {1} es forzada.",oldnature)][pkmn.natureflag ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,commands,cmd)
          # Break
          if cmd==-1
            break
          # Set nature override
          elsif cmd>=0 && cmd<PBNatures.getCount
            pkmn.setNature(cmd)
            pkmn.calcStats
          # Remove override
          elsif cmd==PBNatures.getCount
            pkmn.natureflag=nil
          end
          @scene.pbHardRefresh
        end
      ### Shininess ###
      when 6
        cmd=0
        loop do
          oldshiny=(pkmn.isShiny?) ? _INTL("shiny") : _INTL("normal")
          msg=[_INTL("El variocolor ({1}) es natural.",oldshiny),
               _INTL("El variocolor ({1}) fue forzado.",oldshiny)][pkmn.shinyflag!=nil ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer variocolor"),
               _INTL("Hacer normal"),
               _INTL("Quitar modificación")],cmd)
          # Break
          if cmd==-1
            break
          # Make shiny
          elsif cmd==0
            pkmn.makeShiny
          # Make normal
          elsif cmd==1
            pkmn.makeNotShiny
          # Remove override
          elsif cmd==2
            pkmn.shinyflag=nil
          end
          @scene.pbHardRefresh
        end
      ### Form ###
      when 7
        params=ChooseNumberParams.new
        params.setRange(0,100)
        params.setDefaultValue(pkmn.form)
        f=Kernel.pbMessageChooseNumber(_INTL("Setear la forma del Pokémon."),params)
        if f!=pkmn.form
          pkmn.form=f
          pbDisplay(_INTL("La forma de {1} fue seteada en {2}.",pkmn.name,pkmn.form))
          pbSeenForm(pkmn)
          @scene.pbHardRefresh
        end
      ### Happiness ###
      when 8
        params=ChooseNumberParams.new
        params.setRange(0,255)
        params.setDefaultValue(pkmn.happiness)
        h=Kernel.pbMessageChooseNumber(
           _INTL("Establecer la felicidad del Pokémon (máx. 255)."),params)
        if h!=pkmn.happiness
          pkmn.happiness=h
          pbDisplay(_INTL("La felicidad de {1} fue establecida en {2}.",pkmn.name,pkmn.happiness))
          @scene.pbHardRefresh
        end
      ### EV/IV/pID ###
      when 9
        stats=[_INTL("PS"),_INTL("Ataque"),_INTL("Defensa"),
               _INTL("Velocidad"),_INTL("Ataque Especial"),_INTL("Defensa Especial")]
        cmd=0
        loop do
          persid=sprintf("0x%08X",pkmn.personalID)
          cmd=@scene.pbShowCommands(_INTL("ID personal es {1}.",persid),[
             _INTL("Setear EVs"),
             _INTL("Setear IVs"),
             _INTL("Hacer aleatorio pID")],cmd)
          case cmd
          # Break
          when -1
            break
          # Set EVs
          when 0
            cmd2=0
            loop do
              evcommands=[]
              for i in 0...stats.length
                evcommands.push(stats[i]+" (#{pkmn.ev[i]})")
              end
              cmd2=@scene.pbShowCommands(_INTL("¿Qué EV cambiar?"),evcommands,cmd2)
              if cmd2==-1
                break
              elsif cmd2>=0 && cmd2<stats.length
                params=ChooseNumberParams.new
                params.setRange(0,PokeBattle_Pokemon::EVSTATLIMIT)
                params.setDefaultValue(pkmn.ev[cmd2])
                params.setCancelValue(pkmn.ev[cmd2])
                f=Kernel.pbMessageChooseNumber(
                   _INTL("Setear el EV para {1} (máx. {2}).",
                      stats[cmd2],PokeBattle_Pokemon::EVSTATLIMIT),params)
                pkmn.ev[cmd2]=f
                pkmn.calcStats
                @scene.pbHardRefresh
              end
            end
          # Set IVs
          when 1
            cmd2=0
            loop do
              hiddenpower=pbHiddenPower(pkmn.iv)
              msg=_INTL("Poder Oculto:\n{1}, potencia {2}.",PBTypes.getName(hiddenpower[0]),hiddenpower[1])
              ivcommands=[]
              for i in 0...stats.length
                ivcommands.push(stats[i]+" (#{pkmn.iv[i]})")
              end
              ivcommands.push(_INTL("Hacer aleatorio"))
              cmd2=@scene.pbShowCommands(msg,ivcommands,cmd2)
              if cmd2==-1
                break
              elsif cmd2>=0 && cmd2<stats.length
                params=ChooseNumberParams.new
                params.setRange(0,31)
                params.setDefaultValue(pkmn.iv[cmd2])
                params.setCancelValue(pkmn.iv[cmd2])
                f=Kernel.pbMessageChooseNumber(
                   _INTL("Setear el IV para {1} (máx. 31).",stats[cmd2]),params)
                pkmn.iv[cmd2]=f
                pkmn.calcStats
                @scene.pbHardRefresh
              elsif cmd2==ivcommands.length-1
                pkmn.iv[0]=rand(32)
                pkmn.iv[1]=rand(32)
                pkmn.iv[2]=rand(32)
                pkmn.iv[3]=rand(32)
                pkmn.iv[4]=rand(32)
                pkmn.iv[5]=rand(32)
                pkmn.calcStats
                @scene.pbHardRefresh
              end
            end
          # Randomise pID
          when 2
            pkmn.personalID=rand(256)
            pkmn.personalID|=rand(256)<<8
            pkmn.personalID|=rand(256)<<16
            pkmn.personalID|=rand(256)<<24
            pkmn.calcStats
            @scene.pbHardRefresh
          end
        end
      ### Pokérus ###
      when 10
        cmd=0
        loop do
          pokerus=(pkmn.pokerus) ? pkmn.pokerus : 0
          msg=[_INTL("{1} no tiene Pokérus.",pkmn.name),
               _INTL("Tiene etapa {1}, infectado por {2} días más.",pokerus/16,pokerus%16),
               _INTL("Tiene etapa {1}, no infectado.",pokerus/16)][pkmn.pokerusStage]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Dar etapa aleatoria"),
               _INTL("Hacer no infectado"),
               _INTL("Limpiar Pokérus")],cmd)
          # Break
          if cmd==-1
            break
          # Give random strain
          elsif cmd==0
            pkmn.givePokerus
          # Make not infectious
          elsif cmd==1
            strain=pokerus/16
            p=strain<<4
            pkmn.pokerus=p
          # Clear Pokérus
          elsif cmd==2
            pkmn.pokerus=0
          end
        end
      ### Ownership ###
      when 11
        cmd=0
        loop do
          gender=[_INTL("Macho"),_INTL("Hembra"),_INTL("Desconocido")][pkmn.otgender]
          msg=[_INTL("Pokémon del jugador\n{1}\n{2}\n{3} ({4})",pkmn.ot,gender,pkmn.publicID,pkmn.trainerID),
               _INTL("Pokémon extrangero\n{1}\n{2}\n{3} ({4})",pkmn.ot,gender,pkmn.publicID,pkmn.trainerID)
              ][pkmn.isForeign?($Trainer) ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer del jugador"),
               _INTL("Setear nombre del EO"),
               _INTL("Setear género del EO"),
               _INTL("ID extrangero aleatorio"),
               _INTL("Setear ID extrangero")],cmd)
          # Break
          if cmd==-1
            break
          # Make player's
          elsif cmd==0
            pkmn.trainerID=$Trainer.id
            pkmn.ot=$Trainer.name
            pkmn.otgender=$Trainer.gender
          # Set OT's name
          elsif cmd==1
            newot=pbEnterPlayerName(_INTL("¿{1} es el nombre del EO?",pkmn.name),1,7)
            pkmn.ot=newot
          # Set OT's gender
          elsif cmd==2
            cmd2=@scene.pbShowCommands(_INTL("Setear género del EO."),
               [_INTL("Masculino"),_INTL("Femenino"),_INTL("Desconocido")])
            pkmn.otgender=cmd2 if cmd2>=0
          # Random foreign ID
          elsif cmd==3
            pkmn.trainerID=$Trainer.getForeignID
          # Set foreign ID
          elsif cmd==4
            params=ChooseNumberParams.new
            params.setRange(0,65535)
            params.setDefaultValue(pkmn.publicID)
            val=Kernel.pbMessageChooseNumber(
               _INTL("Setear ID nuevo (máx. 65535)."),params)
            pkmn.trainerID=val
            pkmn.trainerID|=val<<16
          end
        end
      ### Nickname ###
      when 12
        cmd=0
        loop do
          speciesname=PBSpecies.getName(pkmn.species)
          msg=[_INTL("{1} tiene el apodo {2}.",speciesname,pkmn.name),
               _INTL("{1} no tiene apodo.",speciesname)][pkmn.name==speciesname ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Renombrar"),
               _INTL("Borrar nombre")],cmd)
          # Break
          if cmd==-1
            break
          # Rename
          elsif cmd==0
            newname=pbEnterPokemonName(_INTL("Apodo de {1}",speciesname),0,10,"",pkmn)
            pkmn.name=(newname=="") ? speciesname : newname
            @scene.pbHardRefresh
          # Erase name
          elsif cmd==1
            pkmn.name=speciesname
          end
        end
      ### Poké Ball ###
      when 13
        cmd=0
        loop do
          oldball=PBItems.getName(pbBallTypeToBall(pkmn.ballused))
          commands=[]; balls=[]
          for key in $BallTypes.keys
            item=getID(PBItems,$BallTypes[key])
            balls.push([key,PBItems.getName(item)]) if item && item>0
          end
          balls.sort! {|a,b| a[1]<=>b[1]}
          for i in 0...commands.length
            cmd=i if pkmn.ballused==balls[i][0]
          end
          for i in balls
            commands.push(i[1])
          end
          cmd=@scene.pbShowCommands(_INTL("Usada {1}.",oldball),commands,cmd)
          if cmd==-1
            break
          else
            pkmn.ballused=balls[cmd][0]
          end
        end
      ### Ribbons ###
      when 14
        cmd=0
        loop do
          commands=[]
          for i in 1..PBRibbons.maxValue
            commands.push(_INTL("{1} {2}",
               pkmn.hasRibbon?(i) ? "[X]" : "[  ]",PBRibbons.getName(i)))
          end
          cmd=@scene.pbShowCommands(_INTL("{1} cintas.",pkmn.ribbonCount),commands,cmd)
          if cmd==-1
            break
          elsif cmd>=0 && cmd<commands.length
            if pkmn.hasRibbon?(cmd+1)
              pkmn.takeRibbon(cmd+1)
            else
              pkmn.giveRibbon(cmd+1)
            end
          end
        end
      ### Egg ###
      when 15
        cmd=0
        loop do
          msg=[_INTL("No es un huevo"),
               _INTL("Pasos del huevo: {1}.",pkmn.eggsteps)][pkmn.isEgg? ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
               _INTL("Hacer huevo"),
               _INTL("Hacer Pokémon"),
               _INTL("Setear pasos en 1")],cmd)
          # Break
          if cmd==-1
            break
          # Make egg
          elsif cmd==0
            if pbHasEgg?(pkmn.species) ||
               pbConfirm(_INTL("{1} no puede ser un huevo. ¿Hacer de todos modos?",PBSpecies.getName(pkmn.species)))
              pkmn.level=EGGINITIALLEVEL
              pkmn.calcStats
              pkmn.name=_INTL("Huevo")
              dexdata=pbOpenDexData
              pbDexDataOffset(dexdata,pkmn.species,21)
              pkmn.eggsteps=dexdata.fgetw
              dexdata.close
              pkmn.hatchedMap=0
              pkmn.obtainMode=1
              @scene.pbHardRefresh
            end
          # Make Pokémon
          elsif cmd==1
            pkmn.name=PBSpecies.getName(pkmn.species)
            pkmn.eggsteps=0
            pkmn.hatchedMap=0
            pkmn.obtainMode=0
            @scene.pbHardRefresh
          # Set eggsteps to 1
          elsif cmd==2
            pkmn.eggsteps=1 if pkmn.eggsteps>0
          end
        end
      ### Shadow Pokémon ###
      when 16
        cmd=0
        loop do
          msg=[_INTL("No es un Pokémon Oscuro."),
               _INTL("Medidor del Corazón en {1}.",pkmn.heartgauge)][(pkmn.isShadow? rescue false) ? 1 : 0]
          cmd=@scene.pbShowCommands(msg,[
             _INTL("Hacer Oscuro"),
             _INTL("Bajar Medidor Corazón")],cmd)
          # Break
          if cmd==-1
            break
          # Make Shadow
          elsif cmd==0
            if !(pkmn.isShadow? rescue false) && pkmn.respond_to?("makeShadow")
              pkmn.makeShadow
              pbDisplay(_INTL("{1} ahora es un Pokémon Oscuro.",pkmn.name))
              @scene.pbHardRefresh
            else
              pbDisplay(_INTL("{1} ya es un Pokémon Oscuro.",pkmn.name))
            end
          # Lower heart gauge
          elsif cmd==1
            if (pkmn.isShadow? rescue false)
              prev=pkmn.heartgauge
              pkmn.adjustHeart(-700)
              Kernel.pbMessage(_INTL("El medidor del corazón de {1} bajó de {2} hasta {3} (ahora en etapa {4}).",
                 pkmn.name,prev,pkmn.heartgauge,pkmn.heartStage))
              pbReadyToPurify(pkmn)
            else
              Kernel.pbMessage(_INTL("{1} no es un Pokémon Oscuro.",pkmn.name))
            end
          end
        end
      ### Make Mystery Gift ###
      when 17
        pbCreateMysteryGift(0,pkmn)
      ### Duplicate ###
      when 18
        if pbConfirm(_INTL("¿Estás seguro de que quieres copiar este Pokémon?"))
          clonedpkmn=pkmn.clone
          clonedpkmn.iv=pkmn.iv.clone
          clonedpkmn.ev=pkmn.ev.clone
          if @storage.pbMoveCaughtToParty(clonedpkmn)
            if selected[0]!=-1
              pbDisplay(_INTL("El Pokémon duplicado fue movido a tu equipo."))
            end
          else
            oldbox=@storage.currentBox
            newbox=@storage.pbStoreCaught(clonedpkmn)
            if newbox<0
              pbDisplay(_INTL("Todas las cajas están llenas."))
            elsif newbox!=oldbox
              pbDisplay(_INTL("El Pokémon duplicado fue movido a la caja \"{1}.\"",@storage[newbox].name))
              @storage.currentBox=oldbox
            end
          end
          @scene.pbHardRefresh
          break
        end
      ### Delete ###
      when 19
        if pbConfirm(_INTL("¿Estás seguro de borrar este Pokémon?"))
          @scene.pbRelease(selected,heldpoke)
          if heldpoke
            @heldpkmn=nil
          else
            @storage.pbDelete(selected[0],selected[1])
          end
          @scene.pbRefresh
          pbDisplay(_INTL("El Pokémon fue borrado."))
          break
        end
      end
    end
  end
end
