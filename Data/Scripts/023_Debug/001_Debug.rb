class PokemonDataCopy
  attr_accessor :dataOldHash
  attr_accessor :dataNewHash
  attr_accessor :dataTime
  attr_accessor :data

  def crc32(x)
    return Zlib::crc32(x)
  end

  def readfile(filename)
    File.open(filename, "rb"){|f|
       f.read
    }
  end

  def writefile(str,filename)
    File.open(filename, "wb"){|f|
       f.write(str)
    }
  end

  def filetime(filename)
    File.open(filename, "r"){|f|
       f.mtime
    }
  end

  def initialize(data,datasave)
    @datafile=data
    @datasave=datasave
    @data=readfile(@datafile)
    @dataOldHash=crc32(@data)
    @dataTime=filetime(@datafile)
  end

  def changed?
    ts=readfile(@datafile)
    tsDate=filetime(@datafile)
    tsHash=crc32(ts)
    return tsHash!=@dataNewHash && tsHash!=@dataOldHash && tsDate > @dataTime
  end

  def save(newtilesets)
    newdata=Marshal.dump(newtilesets)
    if !changed?
      @data=newdata
      @dataNewHash=crc32(newdata)
      writefile(newdata,@datafile)
    else
      @dataOldHash=crc32(@data)
      @dataNewHash=crc32(newdata)
      @dataTime=filetime(@datafile)
      @data=newdata
      writefile(newdata,@datafile)
    end
    save_data(self,@datasave)
  end
end



class PokemonDataWrapper
  attr_reader :data

  def initialize(file,savefile,prompt)
    @savefile=savefile
    @file=file
    if pbRgssExists?(@savefile)
      @ts=load_data(@savefile)
      if !@ts.changed? || prompt.call==true
        @data=Marshal.load(StringInput.new(@ts.data))
      else
        @ts=PokemonDataCopy.new(@file,@savefile)
        @data=load_data(@file)
      end
    else
      @ts=PokemonDataCopy.new(@file,@savefile)
      @data=load_data(@file)
    end
  end

  def save
    @ts.save(@data)
  end
end



def pbMapTree
  mapinfos=pbLoadRxData("Data/MapInfos")
  maplevels=[]
  retarray=[]
  for i in mapinfos.keys
    info=mapinfos[i]
    level=-1
    while info
      info=mapinfos[info.parent_id]
      level+=1
    end
    if level>=0
      info=mapinfos[i]
      maplevels.push([i,level,info.parent_id,info.order])
    end
  end
  maplevels.sort!{|a,b|
     next a[1]<=>b[1] if a[1]!=b[1] # level
     next a[2]<=>b[2] if a[2]!=b[2] # parent ID
     next a[3]<=>b[3] # order
  }
  stack=[]
  stack.push(0,0)
  while stack.length>0
    parent = stack[stack.length-1]
    index = stack[stack.length-2]
    if index>=maplevels.length
      stack.pop
      stack.pop
      next
    end
    maplevel=maplevels[index]
    stack[stack.length-2]+=1
    if maplevel[2]!=parent
      stack.pop
      stack.pop
      next
    end
    retarray.push([maplevel[0],mapinfos[maplevel[0]].name,maplevel[1]])
    for i in index+1...maplevels.length
      if maplevels[i][2]==maplevel[0]
        stack.push(i)
        stack.push(maplevel[0])
        break
      end
    end
  end
  return retarray
end

def pbExtractText
  msgwindow=Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow,_INTL("Por favor, espera.\\wtnp[0]"))
  MessageTypes.extract("intl.txt")
  Kernel.pbMessageDisplay(msgwindow,
     _INTL("Todos los textos del juego se extrajeron y se guardaron en intl.txt.\1"))
  Kernel.pbMessageDisplay(msgwindow,
     _INTL("Para localizar el texto en un idioma en particular, traduzca todas las segundas líneas de cada par en el archivo.\1"))
  Kernel.pbMessageDisplay(msgwindow,
     _INTL("Luego de traducirlas, elija \"Compilar Texto.\""))
  Kernel.pbDisposeMessageWindow(msgwindow)
end

def pbCompileTextUI
  msgwindow=Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow,_INTL("Por favor, espera.\\wtnp[0]"))
  begin
    pbCompileText
    Kernel.pbMessageDisplay(msgwindow,
       _INTL("Texto compilado exitosamente y guardado en intl.dat."))
    Kernel.pbMessageDisplay(msgwindow,
       _INTL("Para usar el archivo en un juego, ubica el archivo en la carpeta Data con un nombre diferente, y luego edita la matriz LANGUAGES en el script Settings."))
    rescue RuntimeError
    Kernel.pbMessageDisplay(msgwindow,
       _INTL("Fallo al compilar el texto: {1}",$!.message))
  end
  Kernel.pbDisposeMessageWindow(msgwindow)
end



class CommandList
  def initialize
    @commandHash={}
    @commands=[]
  end

  def getCommand(index)
    for key in @commandHash.keys
      return key if @commandHash[key]==index
    end
    return nil
  end

  def add(key,value)
    @commandHash[key]=@commands.length
    @commands.push(value)
  end

  def list
    @commands.clone
  end
end



def pbDefaultMap()
  return $game_map.map_id if $game_map
  return $data_system.edit_map_id if $data_system
  return 0
end

def pbWarpToMap()
  mapid=pbListScreen(_INTL("SALTAR A MAPA"),MapLister.new(pbDefaultMap()))
  if mapid>0
    map=Game_Map.new
    map.setup(mapid)
    success=false
    x=0
    y=0
    100.times do
      x=rand(map.width)
      y=rand(map.height)
      next if !map.passableStrict?(x,y,$game_player)
      blocked=false
      for event in map.events.values
        if event.x == x && event.y == y && !event.through
          blocked=true if self != $game_player || event.character_name != ""
        end
      end
      next if blocked
      success=true
      break
    end
    if !success
      x=rand(map.width)
      y=rand(map.height)
    end
    return [mapid,x,y]
  end
  return nil
end

def pbDebugMenu
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  sprites={}
  commands=CommandList.new
  commands.add("switches",_INTL("Interruptores"))
  commands.add("variables",_INTL("Variables"))
  commands.add("refreshmap",_INTL("Refrescar Mapa"))
  commands.add("warp",_INTL("Saltar a Mapa"))
  commands.add("healparty",_INTL("Curar Equipo"))
  commands.add("additem",_INTL("Agregar Objeto"))
  commands.add("fillbag",_INTL("Llenar Mochila"))
  commands.add("clearbag",_INTL("Vaciar Mochila"))
  commands.add("addpokemon",_INTL("Agregar Pokémon"))
  commands.add("fillboxes",_INTL("Llenar Cajas de Almacenamiento"))
  commands.add("clearboxes",_INTL("Vaciar Cajas de Almacenamiento"))
  commands.add("usepc",_INTL("Usar PC"))
  commands.add("setplayer",_INTL("Setear Personaje del Jugador"))
  commands.add("renameplayer",_INTL("Renombrar Jugador"))
  commands.add("randomid",_INTL("Cambiar ID del Jugador"))
  commands.add("changeoutfit",_INTL("Cambiar Ropa del Jugador"))
  commands.add("setmoney",_INTL("Setear Dinero"))
  commands.add("setcoins",_INTL("Setear Fichas"))
  commands.add("setbadges",_INTL("Setear Medallas"))
  commands.add("demoparty",_INTL("Obtener Equipo de Prueba"))
  commands.add("toggleshoes",_INTL("Habilitar Deportivas"))
  commands.add("togglepokegear",_INTL("Habilitar Pokégear"))
  commands.add("togglepokedex",_INTL("Habilitar Pokédex"))
  commands.add("dexlists",_INTL("Acceso a los Dex"))
  commands.add("chargeorb",_INTL("Cargar Teraorbe"))
  commands.add("upgradeorb",_INTL("Mejaorar Teraorbe"))
  commands.add("readyrematches",_INTL("Activar Revanchas del Celular"))
  commands.add("mysterygift",_INTL("Gestionar Regalos Misteriosos"))
  commands.add("daycare",_INTL("Opciones de la Guardería"))
  commands.add("quickhatch",_INTL("Eclosión rápida"))
  commands.add("roamerstatus",_INTL("Estado de los Pokémon errantes"))
  commands.add("roam",_INTL("Avanzar errantes"))
  commands.add("setencounters",_INTL("Setear Encuentros"))
  commands.add("setmetadata",_INTL("Setear Metadatos"))
  commands.add("terraintags",_INTL("Setear Etiquetas de Terrenos"))
  commands.add("trainertypes",_INTL("Editar Tipos de Entrenadores"))
  commands.add("resettrainers",_INTL("Restablecer Entrenadores"))
  commands.add("testwildbattle",_INTL("Probar Batalla con Salvaje"))
  commands.add("testdoublewildbattle",_INTL("Probar Batalla Doble con Salvajes"))
  commands.add("testtrainerbattle",_INTL("Probar Batalla con Entrenador"))
  commands.add("testdoubletrainerbattle",_INTL("Probar Batalla Doble con Entrenadores"))
  commands.add("relicstone",_INTL("Relic Stone"))
  commands.add("purifychamber",_INTL("Cámara de Purificación"))
  commands.add("extracttext",_INTL("Extraer Texto"))
  commands.add("compiletext",_INTL("Compilar Texto"))
  commands.add("compiledata",_INTL("Compilar Datos"))
  #commands.add("mapconnections",_INTL("Conexiones de Mapas"))
  #commands.add("animeditor",_INTL("Editor de Animaciones"))
  commands.add("debugconsole",_INTL("Consola de Depuración"))
  commands.add("togglelogging",_INTL("Activar Registro de Batalla"))
  sprites["cmdwindow"]=Window_CommandPokemonEx.new(commands.list)
  cmdwindow=sprites["cmdwindow"]
  cmdwindow.viewport=viewport
  cmdwindow.resizeToFit(cmdwindow.commands)
  cmdwindow.height=Graphics.height if cmdwindow.height>Graphics.height
  cmdwindow.x=0
  cmdwindow.y=0
  cmdwindow.visible=true
  pbFadeInAndShow(sprites)
  ret=-1
  loop do
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      if Input.trigger?(Input::B)
        ret=-1
        break
      end
      if Input.trigger?(Input::C)
        ret=cmdwindow.index
        break
      end
    end
    break if ret==-1
    cmd=commands.getCommand(ret)
    if cmd=="switches"
      pbFadeOutIn(99999) { pbDebugScreen(0) }
    elsif cmd=="variables"
      pbFadeOutIn(99999) { pbDebugScreen(1) }
    elsif cmd=="refreshmap"
      $game_map.need_refresh = true
      Kernel.pbMessage(_INTL("Se refrescará el mapa."))
    elsif cmd=="warp"
      map=pbWarpToMap()
      if map
        pbFadeOutAndHide(sprites)
        pbDisposeSpriteHash(sprites)
        viewport.dispose
        if $scene.is_a?(Scene_Map)
          $game_temp.player_new_map_id=map[0]
          $game_temp.player_new_x=map[1]
          $game_temp.player_new_y=map[2]
          $game_temp.player_new_direction=2
          $scene.transfer_player
          $game_map.refresh
        else
          Kernel.pbCancelVehicles
          $MapFactory.setup(map[0])
          $game_player.moveto(map[1],map[2])
          $game_player.turn_down
          $game_map.update
          $game_map.autoplay
          $game_map.refresh
        end
        return
      end
    elsif cmd=="healparty"
      for i in $Trainer.party
        i.heal
      end
      Kernel.pbMessage(_INTL("El equipo Pokémon recuperó la salud."))
    elsif cmd=="additem"
      item=pbListScreen(_INTL("AGREGAR OBJETO"),ItemLister.new(0))
      if item && item>0
        params=ChooseNumberParams.new
        params.setRange(1,BAGMAXPERSLOT)
        params.setInitialValue(1)
        params.setCancelValue(0)
        qty=Kernel.pbMessageChooseNumber(
           _INTL("Selecciona el número del objeto."),params
        )
        if qty>0
          if qty==1
            Kernel.pbReceiveItem(item)
          else
            Kernel.pbMessage(_INTL("El objeto ha sido agregado."))
            $PokemonBag.pbStoreItem(item,qty)
          end
        end
      end
    elsif cmd=="fillbag"
      params=ChooseNumberParams.new
      params.setRange(1,BAGMAXPERSLOT)
      params.setInitialValue(1)
      params.setCancelValue(0)
      qty=Kernel.pbMessageChooseNumber(
         _INTL("Elige el número de objetos."),params
      )
      if qty>0
        itemconsts=[]
        for i in PBItems.constants
          itemconsts.push(PBItems.const_get(i))
        end
        itemconsts.sort!{|a,b| a<=>b}
        for i in itemconsts
          $PokemonBag.pbStoreItem(i,qty)
        end
        Kernel.pbMessage(_INTL("Se llenó la Mochila con {1} unidades de cada objeto.",qty))
      end
    elsif cmd=="clearbag"
      $PokemonBag.clear
      Kernel.pbMessage(_INTL("Se vació la Mochila."))
    elsif cmd=="addpokemon"
      species=pbChooseSpeciesOrdered(1)
      if species!=0
        params=ChooseNumberParams.new
        params.setRange(1,PBExperience::MAXLEVEL)
        params.setInitialValue(5)
        params.setCancelValue(0)
        level=Kernel.pbMessageChooseNumber(
           _INTL("Indicar el nivel del Pokémon."),params)
        if level>0
          pbAddPokemon(species,level)
        end
      end
    elsif cmd=="fillboxes"
      $Trainer.formseen=[] if !$Trainer.formseen
      $Trainer.formlastseen=[] if !$Trainer.formlastseen
      added=0; completed=true
      for i in 1..PBSpecies.maxValue
        if added>=STORAGEBOXES*30
          completed=false; break
        end
        cname=getConstantName(PBSpecies,i) rescue nil
        next if !cname
        pkmn=PokeBattle_Pokemon.new(i,50,$Trainer)
        $PokemonStorage[(i-1)/$PokemonStorage.maxPokemon(0),
                        (i-1)%$PokemonStorage.maxPokemon(0)]=pkmn
        $Trainer.seen[i]=true
        $Trainer.owned[i]=true
        $Trainer.formlastseen[i]=[] if !$Trainer.formlastseen[i]
        $Trainer.formlastseen[i]=[0,0] if $Trainer.formlastseen[i]==[]
        $Trainer.formseen[i]=[[],[]] if !$Trainer.formseen[i]
        for j in 0..27
          $Trainer.formseen[i][0][j]=true
          $Trainer.formseen[i][1][j]=true
        end
        added+=1
      end
      Kernel.pbMessage(_INTL("Las Cajas fueron llenadas de un Pokémon de cada especie."))
      if !completed
        Kernel.pbMessage(_INTL("Nota: La capacidad de almacenamiento ({1} cajas de 30) es menor que el número de especies.",STORAGEBOXES))
      end
    elsif cmd=="clearboxes"
      for i in 0...$PokemonStorage.maxBoxes
        for j in 0...$PokemonStorage.maxPokemon(i)
          $PokemonStorage[i,j]=nil
        end
      end
      Kernel.pbMessage(_INTL("Se vaciaron las Cajas."))
    elsif cmd=="usepc"
      pbPokeCenterPC
    elsif cmd=="setplayer"
      limit=0
      for i in 0...8
        meta=pbGetMetadata(0,MetadataPlayerA+i)
        if !meta
          limit=i
          break
        end
      end
      if limit<=1
        Kernel.pbMessage(_INTL("Hay un sólo personaje definido."))
      else
        params=ChooseNumberParams.new
        params.setRange(0,limit-1)
        params.setDefaultValue($PokemonGlobal.playerID)
        newid=Kernel.pbMessageChooseNumber(
           _INTL("Seleccione el nuevo personaje del jugador."),params)
        if newid!=$PokemonGlobal.playerID
          pbChangePlayer(newid)
          Kernel.pbMessage(_INTL("El personaje del jugador ha sido cambiado."))
        end
      end
    elsif cmd=="renameplayer"
      trname=pbEnterPlayerName("¿Tu nombre?",0,7,$Trainer.name)
      if trname==""
        trainertype=pbGetPlayerTrainerType
        gender=pbGetTrainerTypeGender(trainertype)
        trname=pbSuggestTrainerName(gender)
      end
      $Trainer.name=trname
      Kernel.pbMessage(_INTL("El nombre de jugador cambió a {1}.",$Trainer.name))
    elsif cmd=="randomid"
      $Trainer.id=rand(256)
      $Trainer.id|=rand(256)<<8
      $Trainer.id|=rand(256)<<16
      $Trainer.id|=rand(256)<<24
      Kernel.pbMessage(_INTL("El ID del jugador se cambió por {1} (2).",$Trainer.publicID,$Trainer.id))
    elsif cmd=="changeoutfit"
      oldoutfit=$Trainer.outfit
      params=ChooseNumberParams.new
      params.setRange(0,99)
      params.setDefaultValue(oldoutfit)
      $Trainer.outfit=Kernel.pbMessageChooseNumber(_INTL("Establecer la ropa del jugador."),params)
      Kernel.pbMessage(_INTL("La ropa del jugador ha sido cambiada.")) if $Trainer.outfit!=oldoutfit
    elsif cmd=="chargeorb"
      pbCharge_TeraOrb()
      Kernel.pbMessage(_INTL("El teraorbe se cargó completamente."))
    elsif cmd=="upgradeorb"
      params=ChooseNumberParams.new
      params.setRange(0,999)
      params.setDefaultValue($PokemonGlobal.teraorb[1]) 
      val=Kernel.pbMessageChooseNumber(_INTL("Nuevo máximo de energía del teraorbe."),params)
      pbUpgradeTeraorb(val)
    elsif cmd=="setmoney"
      params=ChooseNumberParams.new
      params.setMaxDigits(6)
      params.setDefaultValue($Trainer.money)
      $Trainer.money=Kernel.pbMessageChooseNumber(
         _INTL("Indicar la cantidad de dinero del jugador."),params)
      Kernel.pbMessage(_INTL("Ahora tiene ${1}.",$Trainer.money))
    elsif cmd=="setcoins"
      params=ChooseNumberParams.new
      params.setRange(0,MAXCOINS)
      params.setDefaultValue($PokemonGlobal.coins)
      $PokemonGlobal.coins=Kernel.pbMessageChooseNumber(
         _INTL("Indicar la cantidad de fichas del jugador."),params)
      Kernel.pbMessage(_INTL("Ahora tiene {1} fichas.",$PokemonGlobal.coins))
    elsif cmd=="setbadges"
      badgecmd=0
      loop do
        badgecmds=[]
        for i in 0...32
          badgecmds.push(_INTL("{1} Medalla {2}",$Trainer.badges[i] ? "[Y]" : "[  ]",i+1))
        end
        badgecmd=Kernel.pbShowCommands(nil,badgecmds,-1,badgecmd)
        break if badgecmd<0
        $Trainer.badges[badgecmd]=!$Trainer.badges[badgecmd]
      end
    elsif cmd=="demoparty"
      pbCreatePokemon
      Kernel.pbMessage(_INTL("Equipo completado con Pokémon de prueba."))
    elsif cmd=="toggleshoes"
      $PokemonGlobal.runningShoes=!$PokemonGlobal.runningShoes
      Kernel.pbMessage(_INTL("Deportivas puestas.")) if $PokemonGlobal.runningShoes
      Kernel.pbMessage(_INTL("Deportivas quitadas.")) if !$PokemonGlobal.runningShoes
    elsif cmd=="togglepokegear"
      $Trainer.pokegear=!$Trainer.pokegear
      Kernel.pbMessage(_INTL("Pokégear listo.")) if $Trainer.pokegear
      Kernel.pbMessage(_INTL("Pokégear quitado.")) if !$Trainer.pokegear
    elsif cmd=="togglepokedex"
      $Trainer.pokedex=!$Trainer.pokedex
      Kernel.pbMessage(_INTL("Pokédex listo.")) if $Trainer.pokedex
      Kernel.pbMessage(_INTL("Pokédex quitado.")) if !$Trainer.pokedex
    elsif cmd=="dexlists"
      dexescmd=0
      loop do
        dexescmds=[]
        d=pbDexNames
        for i in 0...d.length
          name=d[i]
          name=name[0] if name.is_a?(Array)
          dexindex=i
          unlocked=$PokemonGlobal.pokedexUnlocked[dexindex]
          dexescmds.push(_INTL("{1} {2}",unlocked ? "[Y]" : "[  ]",name))
        end
        dexescmd=Kernel.pbShowCommands(nil,dexescmds,-1,dexescmd)
        break if dexescmd<0
        dexindex=dexescmd
        if $PokemonGlobal.pokedexUnlocked[dexindex]
          pbLockDex(dexindex)
        else
          pbUnlockDex(dexindex)
        end
      end
    elsif cmd=="readyrematches"
      if !$PokemonGlobal.phoneNumbers || $PokemonGlobal.phoneNumbers.length==0
        Kernel.pbMessage(_INTL("No hay entrenadores en el Celular."))
      else
        for i in $PokemonGlobal.phoneNumbers
          if i.length==8 # A trainer with an event
            i[4]=2
            pbSetReadyToBattle(i)
          end
        end
        Kernel.pbMessage(_INTL("Ahora todos los entrenadores registrados en el Celular están listos para una revancha."))
      end
    elsif cmd=="mysterygift"
      pbManageMysteryGifts
    elsif cmd=="daycare"
      daycarecmd=0
      loop do
        daycarecmds=[
           _INTL("Datos"),
           _INTL("Dejar Pokémon"),
           _INTL("Sacar Pokémon"),
           _INTL("Generar Huevo"),
           _INTL("Recibir Huevo"),
           _INTL("Entregar Huevo")
        ]
        daycarecmd=Kernel.pbShowCommands(nil,daycarecmds,-1,daycarecmd)
        break if daycarecmd<0
        case daycarecmd
        when 0 # Summary
          if $PokemonGlobal.daycare
            num=pbDayCareDeposited
            Kernel.pbMessage(_INTL("Hay {1} Pokémon en la guardería.",num))
            if num>0
              txt=""
              for i in 0...num
                next if !$PokemonGlobal.daycare[i][0]
                pkmn=$PokemonGlobal.daycare[i][0]
                initlevel=$PokemonGlobal.daycare[i][1]
                gender=[_INTL("♂"),_INTL("♀"),_INTL("genderless")][pkmn.gender]
                txt+=_INTL("{1}) {2} ({3}), Nv.{4} (dejado con Nv.{5})",
                   i,pkmn.name,gender,pkmn.level,initlevel)
                txt+="\n" if i<num-1
              end
              Kernel.pbMessage(txt)
            end
            if $PokemonGlobal.daycareEgg==1
              Kernel.pbMessage(_INTL("Un huevo está esperando ser retirado."))
            elsif pbDayCareDeposited==2
              if pbDayCareGetCompat==0
                Kernel.pbMessage(_INTL("Los Pokémon dejados no se pueden reproducir."))
              else
                Kernel.pbMessage(_INTL("Los Pokémon dejados se pueden reproducir."))
              end
            end
          end
        when 1 # Deposit Pokémon
          if pbEggGenerated?
            Kernel.pbMessage(_INTL("Hay un nuevo disponible, no se puede dejar ningún Pokémon."))
          elsif pbDayCareDeposited==2
            Kernel.pbMessage(_INTL("Ya se dejaron dos Pokémon en la guardería."))
          elsif $Trainer.party.length==0
            Kernel.pbMessage(_INTL("No hay equipo, no se puede dejar ningún Pokémon."))
          else
            pbChooseNonEggPokemon(1,3)
            if pbGet(1)>=0
              pbDayCareDeposit(pbGet(1))
              Kernel.pbMessage(_INTL("Se ha dejado a {1}.",pbGet(3)))
            end
          end
        when 2 # Withdraw Pokémon
          if pbEggGenerated?
            Kernel.pbMessage(_INTL("Hay un huevo disponible, no se puede sacar ningún Pokémon."))
          elsif pbDayCareDeposited==0
            Kernel.pbMessage(_INTL("No hay ningún Pokémon en la guardería."))
          elsif $Trainer.party.length>=6
            Kernel.pbMessage(_INTL("El equipo está completo, no se puede sacar ningún Pokémon."))
          else
            pbDayCareChoose(_INTL("¿Cúal quieres sacar?"),1)
            if pbGet(1)>=0
              pbDayCareGetDeposited(pbGet(1),3,4)
              pbDayCareWithdraw(pbGet(1))
              Kernel.pbMessage(_INTL("Se ha sacado a {1}.",pbGet(3)))
            end
          end
        when 3 # Generate egg
          if $PokemonGlobal.daycareEgg==1
            Kernel.pbMessage(_INTL("Ya hay un huevo esperando ser retirado."))
          elsif pbDayCareDeposited!=2
            Kernel.pbMessage(_INTL("Deben haber dos Pokémon en la guardería para generar un huevo."))
          elsif pbDayCareGetCompat==0
            Kernel.pbMessage(_INTL("Los Pokémon de la guardería no se pueden reproducir."))
          else
            $PokemonGlobal.daycareEgg=1
            Kernel.pbMessage(_INTL("Ahora hay un huevo esperando ser retirado."))
          end
        when 4 # Collect egg
          if $PokemonGlobal.daycareEgg!=1
            Kernel.pbMessage(_INTL("No hay ningún huevo disponible."))
          elsif $Trainer.party.length>=6
            Kernel.pbMessage(_INTL("El equipo está lleno, no se puede retirar el huevo."))
          else
            pbDayCareGenerateEgg
            $PokemonGlobal.daycareEgg=0
            $PokemonGlobal.daycareEggSteps=0
            Kernel.pbMessage(_INTL("Se ha recogido el huevo de {1}.",
               PBSpecies.getName($Trainer.party[$Trainer.party.length-1].species)))
          end
        when 5 # Dispose egg
          if $PokemonGlobal.daycareEgg!=1
            Kernel.pbMessage(_INTL("No hay ningún huevo disponible."))
          else
            $PokemonGlobal.daycareEgg=0
            $PokemonGlobal.daycareEggSteps=0
            Kernel.pbMessage(_INTL("El huevo ha sido regalado al criador Pokémon."))
          end
        end
      end
    elsif cmd=="quickhatch"
      for pokemon in $Trainer.party
        pokemon.eggsteps=1 if pokemon.isEgg?
      end
      Kernel.pbMessage(_INTL("Ahora les queda a todos los huevos del equipo un solo paso para eclosionar."))
    elsif cmd=="roamerstatus"
      if RoamingSpecies.length==0
        Kernel.pbMessage(_INTL("No se definieron Pokémon errantes."))
      else
        text="\\l[8]"
        for i in 0...RoamingSpecies.length
          poke=RoamingSpecies[i]
          if $game_switches[poke[2]]
            status=$PokemonGlobal.roamPokemon[i]
            if status==true
              if $PokemonGlobal.roamPokemonCaught[i]
                text+=_INTL("{1} (Nv.{2}) capturado.",
                   PBSpecies.getName(getID(PBSpecies,poke[0])),poke[1])
              else
                text+=_INTL("{1} (Nv.{2}) debilitado.",
                   PBSpecies.getName(getID(PBSpecies,poke[0])),poke[1])
              end
            else
              curmap=$PokemonGlobal.roamPosition[i]
              if curmap
                mapinfos=load_data("Data/MapInfos.rxdata")
                text+=_INTL("{1} (Nv.{2}) está vagando por el mapa {3} ({4}){5}",
                   PBSpecies.getName(getID(PBSpecies,poke[0])),poke[1],curmap,
                   mapinfos[curmap].name,(curmap==$game_map.map_id) ? _INTL("(este mapa)") : "")
              else
                text+=_INTL("{1} (Nv.{2}) está vagando (mapa no definido).",
                   PBSpecies.getName(getID(PBSpecies,poke[0])),poke[1])
              end
            end
          else
            text+=_INTL("{1} (Nv.{2}) no está vagando (el interruptor {3} está apagado).",
               PBSpecies.getName(getID(PBSpecies,poke[0])),poke[1],poke[2])
          end
          text+="\n" if i<RoamingSpecies.length-1
        end
        Kernel.pbMessage(text)
      end
    elsif cmd=="roam"
      if RoamingSpecies.length==0
        Kernel.pbMessage(_INTL("No se definieron Pokémon errantes."))
      else
        pbRoamPokemon(true)
        $PokemonGlobal.roamedAlready=false
        Kernel.pbMessage(_INTL("Los Pokémon continuaron vagando."))
      end
    elsif cmd=="setencounters"
      encdata=load_data("Data/encounters.dat")
      oldencdata=Marshal.dump(encdata)
      mapedited=false
      map=pbDefaultMap()
      loop do
        map=pbListScreen(_INTL("SETEAR ENCUENTROS"),MapLister.new(map))
        break if map<=0
        mapedited=true if map==pbDefaultMap()
        pbEncounterEditorMap(encdata,map)
      end
      save_data(encdata,"Data/encounters.dat")
      pbSaveEncounterData()
      pbClearData()
    elsif cmd=="setmetadata"
      pbMetadataScreen(pbDefaultMap())
      pbClearData()
    elsif cmd=="terraintags"
      pbFadeOutIn(99999) { pbTilesetScreen }
    elsif cmd=="trainertypes"
      pbFadeOutIn(99999) { pbTrainerTypeEditor }
    elsif cmd=="resettrainers"
      if $game_map
        for event in $game_map.events.values
          if event.name[/Trainer\(\d+\)/]
            $game_self_switches[[$game_map.map_id,event.id,"A"]]=false
            $game_self_switches[[$game_map.map_id,event.id,"B"]]=false
          end
        end
        $game_map.need_refresh=true
        Kernel.pbMessage(_INTL("Todos los entrenadores de este mapa fueron restablecidos."))
      else
        Kernel.pbMessage(_INTL("Este comando no se puede utilizar aquí."))
      end
    elsif cmd=="testwildbattle"
      species=pbChooseSpeciesOrdered(1)
      if species!=0
        params=ChooseNumberParams.new
        params.setRange(1,PBExperience::MAXLEVEL)
        params.setInitialValue(5)
        params.setCancelValue(0)
        level=Kernel.pbMessageChooseNumber(
           _INTL("Indicar el nivel del Pokémon."),params)
        if level>0
          pbWildBattle(species,level)
        end
      end
    elsif cmd=="testdoublewildbattle"
      Kernel.pbMessage(_INTL("Elegir el primer Pokémon."))
      species1=pbChooseSpeciesOrdered(1)
      if species1!=0
        params=ChooseNumberParams.new
        params.setRange(1,PBExperience::MAXLEVEL)
        params.setInitialValue(5)
        params.setCancelValue(0)
        level1=Kernel.pbMessageChooseNumber(
           _INTL("Indicar el nivel del primer Pokémon."),params)
        if level1>0
          Kernel.pbMessage(_INTL("Elegir el segundo Pokémon."))
          species2=pbChooseSpeciesOrdered(1)
          if species2!=0
            params=ChooseNumberParams.new
            params.setRange(1,PBExperience::MAXLEVEL)
            params.setInitialValue(5)
            params.setCancelValue(0)
            level2=Kernel.pbMessageChooseNumber(
               _INTL("Indicar el nivel del segundo Pokémon."),params)
            if level2>0
              pbDoubleWildBattle(species1,level1,species2,level2)
            end
          end
        end
      end
    elsif cmd=="testtrainerbattle"
      battle=pbListScreen(_INTL("ENTRENADOR INDIVIDUAL"),TrainerBattleLister.new(0,false))
      if battle
        trainerdata=battle[1]
        pbTrainerBattle(trainerdata[0],trainerdata[1],"...",false,trainerdata[4],true)
      end
    elsif cmd=="testdoubletrainerbattle"
      battle1=pbListScreen(_INTL("ENTRENADOR DOBLE 1"),TrainerBattleLister.new(0,false))
      if battle1
        battle2=pbListScreen(_INTL("ENTRENADOR DOBLE 2"),TrainerBattleLister.new(0,false))
        if battle2
          trainerdata1=battle1[1]
          trainerdata2=battle2[1]
          pbDoubleTrainerBattle(trainerdata1[0],trainerdata1[1],trainerdata1[4],"...",
                                trainerdata2[0],trainerdata2[1],trainerdata2[4],"...",
                                true)
        end
      end
    elsif cmd=="relicstone"
      pbRelicStone()
    elsif cmd=="purifychamber"
      pbPurifyChamber()
    elsif cmd=="extracttext"
      pbExtractTextByType
      #pbExtractText
    elsif cmd=="compiletext"
      pbCompileTextFromFoldersUI
      #pbCompileTextUI
    elsif cmd=="compiledata"
      msgwindow=Kernel.pbCreateMessageWindow
      pbCompileAllData(true) {|msg| Kernel.pbMessageDisplay(msgwindow,msg,false) }
      Kernel.pbMessageDisplay(msgwindow,_INTL("Se han compilado todos los datos del juego."))
      Kernel.pbDisposeMessageWindow(msgwindow)
    elsif cmd=="mapconnections"
      pbFadeOutIn(99999) { pbEditorScreen }
    elsif cmd=="animeditor"
      pbFadeOutIn(99999) { pbAnimationEditor }
    elsif cmd=="debugconsole"
      Console::setup_console
    elsif cmd=="togglelogging"
      $INTERNAL=!$INTERNAL
      Kernel.pbMessage(_INTL("El registro de depuración de batallas se creará en la carpeta Data.")) if $INTERNAL
      Kernel.pbMessage(_INTL("No se creará el registro de depuración de batallas.")) if !$INTERNAL
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end



class SpriteWindow_DebugRight < Window_DrawableCommand
  attr_reader :mode

  def initialize
    super(0, 0, Graphics.width, Graphics.height)
  end

  def shadowtext(x,y,w,h,t,align=0,colors=0)
    width = self.contents.text_size(t).width
    if align==1 # Right aligned
      x += (w-width)
    elsif align==2 # Centre aligned
      x += (w/2)-(width/2)
    end
    base = Color.new(12*8,12*8,12*8)
    if colors==1 # Red
      base = Color.new(168,48,56)
    elsif colors==2 # Green
      base = Color.new(0,144,0)
    end
    pbDrawShadowText(self.contents,x,y,[width,w].max,h,t,base,Color.new(26*8,26*8,25*8))
  end

  def drawItem(index,count,rect)
    pbSetNarrowFont(self.contents)
    colors = 0; codeswitch = false
    if @mode==0
      name = $data_system.switches[index+1]
      codeswitch = (name[/^s\:/])
      val = (codeswitch) ? (eval($~.post_match) rescue nil) : $game_switches[index+1]
      if val==nil; status = "[-]"; colors = 0; codeswitch = true
      elsif val; status = "[ON]"; colors = 2
      else; status = "[OFF]"; colors = 1
      end
    else
      name = $data_system.variables[index+1]
      status = $game_variables[index+1].to_s
      status = "\"__\"" if !status || status==""
    end
    name = '' if name==nil
    id_text = sprintf("%04d:",index+1)
    width = self.contents.text_size(id_text).width
    rect = drawCursor(index,rect)
    totalWidth = rect.width
    idWidth     = totalWidth*15/100
    nameWidth   = totalWidth*65/100
    statusWidth = totalWidth*20/100
    self.shadowtext(rect.x,rect.y,idWidth,rect.height,id_text)
    self.shadowtext(rect.x+idWidth,rect.y,nameWidth,rect.height,name,0,(codeswitch) ? 1 : 0)
    self.shadowtext(rect.x+idWidth+nameWidth,rect.y,statusWidth,rect.height,status,1,colors)
  end

  def itemCount
    return (@mode==0) ? $data_system.switches.size-1 : $data_system.variables.size-1
  end

  def mode=(mode)
    @mode = mode
    refresh
  end
end



def pbDebugSetVariable(id,diff)
  pbPlayCursorSE()
  $game_variables[id]=0 if $game_variables[id]==nil
  if $game_variables[id].is_a?(Numeric)
    $game_variables[id]=[$game_variables[id]+diff,99999999].min
    $game_variables[id]=[$game_variables[id],-99999999].max
  end
end

def pbDebugVariableScreen(id)
  value=0
  if $game_variables[id].is_a?(Numeric)
    value=$game_variables[id]
  end
  params=ChooseNumberParams.new
  params.setDefaultValue(value)
  params.setMaxDigits(8)
  params.setNegativesAllowed(true)
  value=Kernel.pbMessageChooseNumber(_INTL("Establecer variable {1}.",id),params)
  $game_variables[id]=[value,99999999].min
  $game_variables[id]=[$game_variables[id],-99999999].max
end

def pbDebugScreen(mode)
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=99999
  sprites={}
  sprites["right_window"] = SpriteWindow_DebugRight.new
  right_window=sprites["right_window"]
  right_window.mode=mode
  right_window.viewport=viewport
  right_window.active=true
  right_window.index=0
  pbFadeInAndShow(sprites)
  loop do
    Graphics.update
    Input.update
    pbUpdateSpriteHash(sprites)
    if Input.trigger?(Input::B)
      pbPlayCancelSE()
      break
    end
    current_id = right_window.index+1
    if mode == 0
      if Input.trigger?(Input::C)
        pbPlayDecisionSE()
        $game_switches[current_id] = (not $game_switches[current_id])
        right_window.refresh
      end
    elsif mode == 1
      if Input.repeat?(Input::RIGHT)
        pbDebugSetVariable(current_id,1)
        right_window.refresh
      elsif Input.repeat?(Input::LEFT)
        pbDebugSetVariable(current_id,-1)
        right_window.refresh
      elsif Input.trigger?(Input::C)
        pbDebugVariableScreen(current_id)
        right_window.refresh
      end
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end



class Scene_Debug
  def main
    Graphics.transition(15)
    pbDebugMenu
    $scene=Scene_Map.new
    $game_map.refresh
    Graphics.freeze
  end
end
