class PokemonSummaryScene  
  
  TOTALPAGES = 5
  
  def pbStartScene(party,partyindex,inbattle=false)
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    
    @pageNumber = TOTALPAGES #Edita el numero para añadir/quitar páginas.
    @pageNumber = TOTALPAGES-1 if @pokemon.ribbonCount <= 0 #Quita la página de las cintas.

    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokemon"].ox, @sprites["pokemon"].oy = 0, 0
    @sprites["pokemon"].x = 8
    @sprites["pokemon"].y = 144 - 32
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(30,320,@pokemon.item,@viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonpresel"].visible     = false
    @sprites["ribbonpresel"].preselected = true
    @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonsel"].visible = false

    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg; return
    end
    
    @sprites["itemicon"].item = @pokemon.item
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/summary#{page}")

    drawPageIcon(page-1)
    drawCommonElements(page, false)

    case page
    when 1; drawPageInfo
    when 2; drawPageData
    when 3; drawPageStats
    when 4; drawPageMoves
      
    #Añade paginas aquí. vvv
    #when 5; drawPageSix
    #Por conveniencia las cintas son siempre la ultima página.
    #Así puedes
    else; drawPageRibbons#(Cintas)
    end
  end

  def initialize
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    
    @page    = 1 
    @sprites = {}
    
    @sprites["bg"]=IconSprite.new(0,0,@viewport)
    @sprites["bg"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summarybg")
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    
    @base    = Color.new(248,248,248)
    @shadow  = Color.new(47,46,54)
    @base2   = Color.new(64,64,64)
    @shadow2 = Color.new(176,176,176)
    
    @typebitmap     = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @tera_typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/teraTypes"))
    @amistadbitmap  =AnimatedBitmap.new(_INTL("Graphics/#{SUMMARY_ROUTE}/friendship"))
    
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].ox, @sprites["pokeicon"].oy = 0 , 0
    @sprites["pokeicon"].x,  @sprites["pokeicon"].y  = 14, 52
    
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 56
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 260
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"],2)
    
  end
  
  def pbStartForgetScene(party,partyindex,moveToLearn)
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page       = 4
    @sprites["movesel"] = MoveSelectionSprite.new(@viewport,moveToLearn>0)
    @sprites["movesel"].visible = false
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    drawSelectedMove(moveToLearn,@pokemon.moves[0].id)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
  end
  
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbPokerus(pkmn)
    return pkmn.pokerusStage
  end

  def drawPageIcon(page=0)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @pagebitmap = AnimatedBitmap.new("Graphics/Pictures/Summary/icons")
    rectsize = 64
    pagenum  = @pageNumber
    tmy      = 0
    tmx      = Graphics.width - rectsize*pagenum
    
    for i in 0...pagenum
      pgrect=Rect.new(i*rectsize,i == page ? rectsize : 0,rectsize,rectsize)
      overlay.blt(tmx+(rectsize*i),tmy,@pagebitmap.bitmap,pgrect)
    end
  end

  def drawCommonElements(page, isEgg=false)
    overlay = @sprites["overlay"].bitmap
    textpos = []
    
    # Configuración común para todas las páginas
    pagename = isEgg ? _INTL("NOTAS ENTRENADOR") : 
               [_INTL("DATOS"), 
                _INTL("NOTAS ENTRENADOR"), 
                _INTL("CARACTERÍSTICAS"), 
                _INTL("MOVIMIENTOS"), 
                _INTL("CINTAS")][page-1]
    
    textpos.push([pagename,26,16,0,@base,@shadow])
    textpos.push([@pokemon.name,46,62,0,@base,@shadow])
    
    unless isEgg
      textpos.push([@pokemon.level.to_s,46,92,0,@base2,@shadow2])
      if @pokemon.isMale?
        textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
      elsif @pokemon.isFemale?
        textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
      end
    end
    
    textpos.push([_INTL("Objeto"),66,318,0,@base,@shadow])
    if @pokemon.hasItem?
      textpos.push([PBItems.getName(@pokemon.item),16,352,0,@base2,@shadow2])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(192,200,208),Color.new(208,216,224)])
    end
    
    # Dibujar elementos gráficos comunes
    imagepos = []
    unless isEgg
      ballimage = sprintf("Graphics/Pictures/Summary/summaryball%02d",@pokemon.ballused)
      imagepos.push([ballimage,14,60])
      
      if pbPokerus(@pokemon)==1 || @pokemon.hp==0 || @pokemon.status>0
        status=6 if pbPokerus(@pokemon)==1
        status=@pokemon.status-1 if @pokemon.status>0
        status=5 if @pokemon.hp==0
        imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
      end
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])if pbPokerus(@pokemon)==2
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])    if @pokemon.isShiny?
    end
    
    pbDrawImagePositions(overlay,imagepos) unless imagepos.empty?
    pbDrawTextPositions(overlay,textpos)
    drawMarkings(overlay,84,286,68,20,@pokemon.markings) unless isEgg
  end


  def drawPageOneEgg
    @sprites["itemicon"].item = @pokemon.item
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    @sprites["background"].setBitmap("Graphics/Pictures/Summary/summaryEgg")
    
    drawCommonElements(2, true)
    
    memo = ""
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetAbbrevMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += _INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n",date,month,year)
    end
    
    mapname = pbGetMapNameFromId(@pokemon.obtainMap)
    if (@pokemon.obtainText rescue false) && @pokemon.obtainText!=""
      mapname = @pokemon.obtainText
    end
    
    if mapname && mapname!=""
      memo += _INTL("<c3=404040,B0B0B0>Un extraño Huevo Pokémon hallado en <c3=F83820,E09890>{1}<c3=404040,B0B0B0>.\n",mapname)
    else
      memo += _INTL("<c3=404040,B0B0B0>Un extraño Huevo Pokémon.\n",mapname)
    end
    
    memo += "\n"
    memo += _INTL("<c3=404040,B0B0B0>\"Estado del Huevo\"\n")
    
    eggstate = _INTL("Parece que a este Huevo le tomará mucho tiempo abrirse.")
    eggstate = _INTL("¿Qué saldrá? Aún le queda para abrirse.") if @pokemon.eggsteps<10200
    eggstate = _INTL("A veces se mueve. Debería abrirse pronto.") if @pokemon.eggsteps<2550
    eggstate = _INTL("Está haciendo ruidos. ¡Está a punto de abrirse!") if @pokemon.eggsteps<1275
    
    memo += sprintf("<c3=404040,B0B0B0>%s\n",eggstate)
    drawFormattedTextEx(overlay,232,78,268,memo)
  end

  def drawPageInfo
    overlay = @sprites["overlay"].bitmap
    dexNumBase   = (@pokemon.isShiny?) ? Color.new(248,56,32) : @base2
    dexNumShadow = (@pokemon.isShiny?) ? Color.new(224,152,144) : @shadow2
    
    if (@pokemon.isShadow? rescue false)
      shadowfract = @pokemon.heartgauge*1.0/PokeBattle_Pokemon::HEARTGAUGESIZE
      imagepos = [
         ["Graphics/Pictures/Summary/overlay_shadow",224,240],
         ["Graphics/Pictures/Summary/overlay_shadowbar",242,280,0,0,(shadowfract*248).floor,-1]
      ]
      pbDrawImagePositions(overlay,imagepos)
    end
    
    textpos = [
       [_INTL("N° Dex"),238,80,0,@base,@shadow],
       [_INTL("Especie"),238,112,0,@base,@shadow],
       [PBSpecies.getName(@pokemon.species),435,112,2,@base2,@shadow2],
       [_INTL("Tipo"),238,144,0,@base,@shadow],
       [_INTL("EO"),238,176,0,@base,@shadow],
       [_INTL("N° ID"),238,208,0,@base,@shadow],
    ]
    
    dexnum = @pokemon.species
    dexnumshift = false
    
    if $PokemonGlobal.pokedexUnlocked[$PokemonGlobal.pokedexUnlocked.length-1]
      dexnumshift = true
    else
      dexnum = 0
      for i in 0...$PokemonGlobal.pokedexUnlocked.length-1
        next if !$PokemonGlobal.pokedexUnlocked[i]
        num = pbGetRegionalNumber(i,@pokemon.species)
        next if num<=0
        dexnum = num
        dexnumshift = true
        break
      end
    end

    if dexnum<=0
      textpos << ["???",435,80,2,dexNumBase,dexNumShadow]
    else
      dexnum -= 1 if dexnumshift
      textpos << [sprintf("%03d",dexnum),435,80,2,dexNumBase,dexNumShadow]
    end
    
    if @pokemon.ot==""
      textpos << [_INTL("RENTAL"),435,176,2,@base2,@shadow2]
      textpos << ["?????",435,208,2,@base2,@shadow2]
    else
      ownerbase   = @base2
      ownershadow = @shadow2
      case @pokemon.otgender
      when 0; ownerbase = Color.new(24,112,216); ownershadow = Color.new(136,168,208)
      when 1; ownerbase = Color.new(248,56,32);  ownershadow = Color.new(224,152,144)
      end
      textpos << [@pokemon.ot,435,176,2,ownerbase,ownershadow]
      textpos << [sprintf("%05d",@pokemon.publicID),435,208,2,@base2,@shadow2]
    end
    
    if (@pokemon.isShadow? rescue false)
      textpos << [_INTL("Medidor del Corazón"),238,240,0,@base,@shadow]
      heartmessage = [_INTL("¡La puerta de su corazón está abierta! ¡Hacer purificación definitiva!"),
                      _INTL("La puerta de su corazón está casi abierta del todo."),
                      _INTL("La puerta de su corazón está bastante abierta."),
                      _INTL("La puerta de su corazón está un poco abierta."),
                      _INTL("La puerta de su corazón está apenas abierta."),
                      _INTL("La puerta está fuertemente cerrada.")][@pokemon.heartStage]
      memo = sprintf("<c3=404040,B0B0B0>%s\n",heartmessage)
      drawFormattedTextEx(overlay,234,304,264,memo)
    else
      startexp=PBExperience.pbGetStartExperience(@pokemon.level,@pokemon.growthrate)
      endexp=PBExperience.pbGetStartExperience(@pokemon.level+1,@pokemon.growthrate)
      textpos << [_INTL("Puntos de Experiencia"),238,240,0,@base,@shadow]
      textpos << [@pokemon.exp.to_s_formatted,488,272,1,@base2,@shadow2]
      textpos << [_INTL("Para subir de nivel"),238,304,0,@base,@shadow]
      textpos << [(endexp-@pokemon.exp).to_s_formatted,488,336,1,@base2,@shadow2]
      
      if @pokemon.level<PBExperience::MAXLEVEL
        overlay.fill_rect(362,372,(@pokemon.exp-startexp)*128/(endexp-startexp),2,Color.new(72,120,160))
        overlay.fill_rect(362,374,(@pokemon.exp-startexp)*128/(endexp-startexp),4,Color.new(24,144,248))
      end
    end
    
    pbDrawTextPositions(overlay,textpos)
    
    type1rect = Rect.new(0,@pokemon.type1*28,64,28)
    type2rect = Rect.new(0,@pokemon.type2*28,64,28)
    if @pokemon.type1==@pokemon.type2
      overlay.blt(402,146,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(370,146,@typebitmap.bitmap,type1rect)
      overlay.blt(436,146,@typebitmap.bitmap,type2rect)
    end
    
    if @pokemon.teratype && pbHasTeraOrb
      teratyperect=Rect.new(0,@pokemon.teratype*32,32,32)
      if ![getConst(PBSpecies,:OGERPON),getConst(PBSpecies,:TERAPAGOS)].include?(@pokemon.species) && !$game_switches[NO_TERA_CRISTAL]
        overlay.blt(330,142,@tera_typebitmap.bitmap,teratyperect)
      end
    end
  end

  def drawPageData
    overlay = @sprites["overlay"].bitmap
    memo = ""
    
    amistad=@pokemon.happiness/44
    amistad=amistad.floor
    if EXPANDED_SUMMARY_INFO
      textpos=[[_INTL("Amistad:"),256+8,334,0,@base2,@shadow2]]
      nivelamistad=Rect.new(0,amistad*18,128,18)
      overlay.blt(356,334+8,@amistadbitmap.bitmap,nivelamistad)
    end
    pbDrawTextPositions(overlay,textpos)
    
    showNature = !(@pokemon.isShadow? rescue false) || @pokemon.heartStage>3
    if showNature
      natureName = PBNatures.getName(@pokemon.nature)
      memo += _INTL("Naturaleza <c3=F83820,E09890>{1}<c3=404040,B0B0B0>\n",natureName)
    end
    
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetAbbrevMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += _INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n",date,month,year)
    end
    
    mapname = pbGetMapNameFromId(@pokemon.obtainMap)
    if (@pokemon.obtainText rescue false) && @pokemon.obtainText!=""
      mapname = @pokemon.obtainText
    end
    mapname = _INTL("Lugar lejano") if !mapname || mapname==""
    memo += sprintf("<c3=F83820,E09890>%s\n",mapname)
    
    mettext = [_INTL("Encontrado con Nv. {1}.",@pokemon.obtainLevel),
               _INTL("Huevo recibido."),
               _INTL("Intercambiado con Nv. {1}.",@pokemon.obtainLevel),
               "",
               _INTL("Lo conocí en un encuentro fatídico en Nv. {1}.",@pokemon.obtainLevel)
              ][@pokemon.obtainMode]
    memo += sprintf("<c3=404040,B0B0B0>%s\n",mettext) if mettext && mettext!=""
    
    if @pokemon.obtainMode==1
      if @pokemon.timeEggHatched
        date  = @pokemon.timeEggHatched.day
        month = pbGetAbbrevMonthName(@pokemon.timeEggHatched.mon)
        year  = @pokemon.timeEggHatched.year
        memo += _INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n",date,month,year)
      end
      mapname = pbGetMapNameFromId(@pokemon.hatchedMap)
      mapname = _INTL("Lugar lejano") if !mapname || mapname==""
      memo += sprintf("<c3=F83820,E09890>%s\n",mapname)
      memo += _INTL("<c3=404040,B0B0B0>Huevo eclosionado.\n")
    else
      memo += "\n"
    end
    
    if showNature
      bestiv     = 0
      tiebreaker = @pokemon.personalID%6
      for i in 0...6
        if @pokemon.iv[i]==@pokemon.iv[bestiv]
          bestiv = i if i>=tiebreaker && bestiv<tiebreaker
        elsif @pokemon.iv[i]>@pokemon.iv[bestiv]
          bestiv = i
        end
      end
      characteristic = [_INTL("Le encanta comer."),       # Loves to eat
                        _INTL("A menudo se duerme."),     # Often dozes off
                        _INTL("Suele perder cosas."),     # Often scatters things
                        _INTL("A veces se enoja."),       # Scatters things often
                        _INTL("Le gusta relajarse."),     # Likes to relax
                        _INTL("Orgulloso de su fuerza."), # Proud of its power.
                        _INTL("Le gusta revolverse."),    # Likes to thrash about
                        _INTL("Un poco cabezota."),       # A little quick tempered
                        _INTL("Le gusta luchar."),        # Likes to fight
                        _INTL("Muy cabezota."),           # Quick tempered
                        _INTL("Cuerpo resistente."),      # Sturdy body
                        _INTL("Capaz de hacerlo solo."),  # Capable of taking hits
                        _INTL("Muy persistente."),        # Highly persistent
                        _INTL("Buen fajador."),           # Good endurance
                        _INTL("Muy perseverante."),       # Good perseverance
                        _INTL("Le gusta correr."),        # Likes to run
                        _INTL("Oído siempre alerta."),    # Alert to sounds
                        _INTL("Impetuoso y bobo."),       # Impetuous and silly
                        _INTL("Es un poco payaso."),      # Somewhat of a clown
                        _INTL("Huye rápido."),            # Quick to flee
                        _INTL("Muy curioso."),            # Highly curious
                        _INTL("Travieso."),               # Mischievous
                        _INTL("Muy astuto."),             # Thoroughly cunning
                        _INTL("A veces se distrae."),     # Often lost in thought
                        _INTL("Muy quisquilloso."),       # Very finicky
                        _INTL("Voluntarioso."),           # Strong willed
                        _INTL("Algo orgulloso."),         # Somewhat vain
                        _INTL("Muy insolente."),          # Strongly defiant
                        _INTL("Odia perder."),            # Hates to lose
                        _INTL("Tiene mal genio.")         # Somewhat stubborn
                       ][bestiv*5+@pokemon.iv[bestiv]%5]
      memo += sprintf("<c3=404040,B0B0B0>%s\n",characteristic)
    end
    
    drawFormattedTextEx(overlay,232,78,268,memo)
  end

  def drawPageStats
    overlay = @sprites["overlay"].bitmap
    
    statshadows = []
    for i in 0...5; statshadows[i]=@shadow; end
    if !@pokemon.isShadow? || @pokemon.heartStage>3
      natup=(@pokemon.nature/5).floor
      natdn=(@pokemon.nature%5).floor
      statshadows[natup] = Color.new(136,96,72) if natup!=natdn
      statshadows[natdn] = Color.new(64,120,152) if natup!=natdn
    end
    
    textpos=[
       [_INTL(PBStats.getName(0,true)),234,76,0,@base,@shadow],
       [_INTL(PBStats.getName(1,true)),234,120,0,@base,statshadows[0]],
       [_INTL(PBStats.getName(2,true)),234,152,0,@base,statshadows[1]],
       [_INTL(PBStats.getName(4,true)),234,184,0,@base,statshadows[3]],
       [_INTL(PBStats.getName(5,true)),234,216,0,@base,statshadows[4]],
       [_INTL(PBStats.getName(3,true)),234,248,0,@base,statshadows[2]],
       [_INTL("Habilidad"),224,284,0,@base,@shadow],
       [PBAbilities.getName(@pokemon.ability),342,284,0,@base2,@shadow2],
    ]

    statX = EXPANDED_SUMMARY_INFO ? 366 : 456
    textpos+=[
         [sprintf("%3d/%3d",@pokemon.hp,@pokemon.totalhp),statX,76,1,@base2,@shadow2],
         [sprintf("%d",@pokemon.attack),statX,120,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.defense),statX,152,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.spatk),statX,184,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.spdef),statX,216,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.speed),statX,248,2,@base2,@shadow2],
    ]
    if EXPANDED_SUMMARY_INFO
      textpos+=[
         [sprintf("%d",@pokemon.ev[0]),424,76,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.ev[1]),424,120,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.ev[2]),424,152,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.ev[4]),424,184,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.ev[5]),424,216,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.ev[3]),424,248,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.iv[0]),476,76,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.iv[1]),476,120,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.iv[2]),476,152,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.iv[4]),476,184,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.iv[5]),476,216,2,@base2,@shadow2],
         [sprintf("%d",@pokemon.iv[3]),476,248,2,@base2,@shadow2],
      ]
    end
    
    pbSetSystemFont(overlay)
    pbDrawTextPositions(overlay,textpos)
    
    abilitydesc = pbGetMessage(MessageTypes::AbilityDescs,@pokemon.ability)
    pbSetSmallFont(overlay)
    
    if EXPANDED_SUMMARY_INFO
      drawTextEx(overlay,224,316,282,2,"Presiona C para más información.",@base2,@shadow2)
    else
      drawTextEx(overlay,224,316,282,2,abilitydesc,@base2,@shadow2)
    end
    
    pbSetSystemFont(overlay)
    
    if @pokemon.hp>0
      hpcolors=[
         Color.new(24,192,32),Color.new(0,144,0),
         Color.new(248,184,0),Color.new(184,112,0),
         Color.new(240,80,32),Color.new(168,48,56)
      ]
      hpzone=0
      hpzone=1 if @pokemon.hp<=(@pokemon.totalhp/2).floor
      hpzone=2 if @pokemon.hp<=(@pokemon.totalhp/4).floor
      overlay.fill_rect(272,110,@pokemon.hp*96/@pokemon.totalhp,2,hpcolors[hpzone*2+1])
      overlay.fill_rect(272,112,@pokemon.hp*96/@pokemon.totalhp,4,hpcolors[hpzone*2])
    end
  end
  
  def drawPageStatsExpanded
    drawPageStats
    overlay = @sprites["overlay"].bitmap
    
    imagepos = [["Graphics/Pictures/Summary/summary3details",208,56]]
    pbDrawImagePositions(overlay,imagepos)
    
    textpos = [[PBAbilities.getName(@pokemon.ability),232,76,0,@base,@shadow]]
    pbDrawTextPositions(overlay,textpos)
    
    desc = pbGetMessage(MessageTypes::AbilityDescs,@pokemon.ability)
    pbSetSmallFont(overlay)
    drawFormattedTextEx(overlay,232,112,272,desc,@base2,@shadow2)
    pbSetSystemFont(overlay)
    
    loop do
      Input.update
      Graphics.update
      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        Input.update
        break
      end
      pbUpdate
    end
  end
  
  def drawPageMoves
    overlay = @sprites["overlay"].bitmap
    moveBase   = @base2
    moveShadow = @shadow2
    ppBase   = [moveBase,
                Color.new(248,192,0),
                Color.new(248,136,32),
                Color.new(248,72,72)]
    ppShadow = [moveShadow,
                Color.new(144,104,0),
                Color.new(144,72,24),
                Color.new(136,48,48)]
    
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = true
    
    textpos  = []
    imagepos = []
    yPos = 98
    
    for i in 0...@pokemon.moves.length
      move=@pokemon.moves[i]
      if move.id>0
        imagepos << ["Graphics/Pictures/types",248,yPos+2,0,move.type*28,64,28]
        textpos << [PBMoves.getName(move.id),316,yPos,0,moveBase,moveShadow]
        if move.totalpp>0
          textpos << [_INTL("PP"),342,yPos+32,0,moveBase,moveShadow]
          ppfraction = 0
          if move.pp==0;                 ppfraction = 3
          elsif move.pp*4<=move.totalpp; ppfraction = 2
          elsif move.pp*2<=move.totalpp; ppfraction = 1
          end
          textpos << [sprintf("%d/%d",move.pp,move.totalpp),460,yPos+32,1,ppBase[ppfraction],ppShadow[ppfraction]]
        end
      else
        textpos << ["-",316,yPos,0,moveBase,moveShadow]
        textpos << ["--",442,yPos+32,1,moveBase,moveShadow]
      end
      yPos += 64
    end
    
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end

  def drawSelectedMove(moveToLearn,moveid)
    drawMoveSelection(moveToLearn)
    overlay = @sprites["overlay"].bitmap
    
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].pokemon  = @pokemon
    @sprites["pokeicon"].visible  = true
    @sprites["itemicon"].visible  = false if @sprites["itemicon"]
    
    moveData = PBMoveData.new(moveid)
    basedamage = moveData.basedamage
    category   = moveData.category
    accuracy   = moveData.accuracy
    
    textpos = []
    if basedamage==0
      textpos << ["---",216,154,1,@base2,@shadow2]
    elsif basedamage==1
      textpos << ["???",216,154,1,@base2,@shadow2]
    else
      textpos << [sprintf("%d",basedamage),216,154,1,@base2,@shadow2]
    end
    
    if accuracy==0
      textpos << ["---",216,186,1,@base2,@shadow2]
    else
      textpos << [sprintf("%d%",accuracy),216+overlay.text_size("%").width,186,1,@base2,@shadow2]
    end
    
    pbDrawTextPositions(overlay,textpos)
    imagepos = [["Graphics/Pictures/category",166,124,0,category*28,64,28]]
    pbDrawImagePositions(overlay,imagepos)
    
    pbSetSmallFont(overlay)
    drawTextEx(overlay,4,218,230,5,
       pbGetMessage(MessageTypes::MoveDescriptions,moveid),@base2,@shadow2)
    pbSetSystemFont(overlay)
    
  end

  def drawMoveSelection(moveToLearn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    if moveToLearn!=0
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/summary4learning")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Summary/summary4details")
    end
    
    textpos = [
       [_INTL("MOVIMIENTOS"),26,16,0,@base,@shadow],
       [_INTL("CATEGORÍA"),20,122,0,@base,@shadow],
       [_INTL("POTENCIA"),20,154,0,@base,@shadow],
       [_INTL("PRECISIÓN"),20,186,0,@base,@shadow]
    ]
    
    imagepos = []
    yPos = 98
    yPos -= 76 if moveToLearn!=0
    
    for i in 0...5
      move = @pokemon.moves[i]
      if i==4
        move = PBMove.new(moveToLearn) if moveToLearn!=0
        yPos += 20
      end
      if move && move.id>0
        imagepos << ["Graphics/Pictures/types",248,yPos+2,0,move.type*28,64,28]
        textpos << [PBMoves.getName(move.id),316,yPos,0,@base2,@shadow2]
        if move.totalpp>0
          textpos << [_INTL("PP"),342,yPos+32,0,@base2,@shadow2]
          ppfraction = 0
          if move.pp==0;                 ppfraction = 3
          elsif move.pp*4<=move.totalpp; ppfraction = 2
          elsif move.pp*2<=move.totalpp; ppfraction = 1
          end
          textpos << [sprintf("%d/%d",move.pp,move.totalpp),460,yPos+32,1,@base2,@shadow2]
        end
      else
        textpos << ["-",316,yPos,0,@base2,@shadow2]
        textpos << ["--",442,yPos+32,1,@base2,@shadow2]
      end
      yPos += 64
    end
    
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
    
    type1rect = Rect.new(0,@pokemon.type1*28,64,28)
    type2rect = Rect.new(0,@pokemon.type2*28,64,28)
    if @pokemon.type1==@pokemon.type2
      overlay.blt(130,78,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(96,78,@typebitmap.bitmap,type1rect)
      overlay.blt(166,78,@typebitmap.bitmap,type2rect)
    end
  end

  def drawPageRibbons
    overlay = @sprites["overlay"].bitmap
    @sprites["uparrow"].visible   = false
    @sprites["downarrow"].visible = false
    
    textpos = [
       [_INTL("Número de Cintas:"),234,332,0,@base2,@shadow2],
       [@pokemon.ribbonCount.to_s,450,332,1,@base2,@shadow2],
    ]
    pbDrawTextPositions(overlay,textpos)
    
    imagepos = []
    coord = 0
    if @pokemon.ribbons
      for i in @ribbonOffset*4...@ribbonOffset*4+12
        break if !@pokemon.ribbons[i]
        ribn = @pokemon.ribbons[i]-1
        imagepos << ["Graphics/Pictures/ribbons",230+68*(coord%4),78+68*(coord/4).floor,
                                                  64*(ribn%8),64*(ribn/8).floor,64,64]
        coord += 1
        break if coord>=12
      end
    end
    pbDrawImagePositions(overlay,imagepos)
  end

  def drawSelectedRibbon(ribbonid)
    drawPageRibbons
    overlay = @sprites["overlay"].bitmap
    
    imagepos = [["Graphics/Pictures/Summary/overlay_ribbon",8,280]]
    pbDrawImagePositions(overlay,imagepos)
    
    name = ribbonid ? PBRibbons.getName(ribbonid) : ""
    desc = ribbonid ? PBRibbons.getDescription(ribbonid) : ""
    
    textpos = [[name,18,286,0,@base,@shadow]]
    pbDrawTextPositions(overlay,textpos)
    drawTextEx(overlay,18,318,480,2,desc,@base2,@shadow2)
  end
  
  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE() if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
        break
      end
    end
    @sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Sí"),_INTL("No")])) {
      cmdwindow.z       = @viewport.z+1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::B)
            ret = false
            break
          elsif Input.trigger?(Input::C) && @sprites["messagebox"].resume
            ret = (cmdwindow.index==0)
            break
          end
        end
      end
    }
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands, index = 0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) do
      cmdwindow.z = @viewport.z + 1
      cmdwindow.index = index
      pbBottomRight(cmdwindow)
      loop do
        Graphics.update
        Input.update
        cmdwindow.update
        pbUpdate
        if Input.trigger?(Input::BACK)
          pbPlayCancelSE
          ret = -1
          break
        elsif Input.trigger?(Input::USE)
          pbPlayDecisionSE
          ret = cmdwindow.index
          break
        end
      end
    end
    return ret
  end
  
  def drawMarkings(bitmap,x,y,width,height,markings)
    totaltext=""
    oldfontname=bitmap.font.name
    oldfontsize=bitmap.font.size
    oldfontcolor=bitmap.font.color
    bitmap.font.size=24
    bitmap.font.name="Arial"
    PokemonStorage::MARKINGCHARS.each{|item| totaltext+=item }
    totalsize=bitmap.text_size(totaltext)
    realX=x+(width/2)-(totalsize.width/2)
    realY=y+(height/2)-(totalsize.height/2)
    i=0
    PokemonStorage::MARKINGCHARS.each{|item|
       marked=(markings&(1<<i))!=0
       bitmap.font.color=(marked) ? Color.new(72,64,56) : Color.new(184,184,160)
       itemwidth=bitmap.text_size(item).width
       bitmap.draw_text(realX,realY,itemwidth+2,totalsize.height,item)
       realX+=itemwidth
       i+=1
    }
    bitmap.font.name=oldfontname
    bitmap.font.size=oldfontsize
    bitmap.font.color=oldfontcolor
  end
  
  def pbGoToPrevious
    newindex = @partyindex
    while newindex>0
      newindex -= 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex<@party.length-1
      newindex += 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
    @pokemon = @party[@partyindex]
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["itemicon"].item = @pokemon.item
    pbSEStop
    pbPlayCry(@pokemon)
    
    @pageNumber = TOTALPAGES #Edita el numero para añadir/quitar páginas.
    @pageNumber = TOTALPAGES-1 if @pokemon.ribbonCount <= 0 #Quita la página de las cintas.
    @page = @pageNumber if @page > @pageNumber
    
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching = false
    drawSelectedMove(0,@pokemon.moves[selmove].id)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z = @sprites["movesel"].z+1
      else
        @sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["movepresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible = false
          switching = false
        else
          if !@pokemon.isShadow?
            if !switching
              @sprites["movepresel"].index   = selmove
              @sprites["movepresel"].visible = true
              oldselmove = selmove
              switching = true
            else
              tmpmove                    = @pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
              @pokemon.moves[selmove]    = tmpmove
              @sprites["movepresel"].visible = false
              switching = false
              drawSelectedMove(0,@pokemon.moves[selmove].id)
            end
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        selmove = 0 if selmove>=4
        selmove = @pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index = selmove
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove = 0 if selmove>=4
        selmove = 4 if selmove<0
        @sprites["movesel"].index = selmove
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      end
    end
    @sprites["movesel"].visible=false
  end

  def pbRibbonSelection
    @sprites["ribbonsel"].visible = true
    @sprites["ribbonsel"].index   = 0
    selribbon    = @ribbonOffset*4
    oldselribbon = selribbon
    switching = false
    numRibbons = @pokemon.ribbons.length
    numRows    = [((numRibbons+3)/4).floor,3].max
    drawSelectedRibbon(@pokemon.ribbons[selribbon])
    loop do
      @sprites["uparrow"].visible   = (@ribbonOffset>0)
      @sprites["downarrow"].visible = (@ribbonOffset<numRows-3)
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["ribbonpresel"].index==@sprites["ribbonsel"].index
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z+1
      else
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z
      end
      hasMovedCursor = false
      if Input.trigger?(Input::B)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["ribbonpresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::C)
        if !switching
          if @pokemon.ribbons[selribbon]
            pbPlayDecisionSE
            @sprites["ribbonpresel"].index = selribbon-@ribbonOffset*4
            oldselribbon = selribbon
            @sprites["ribbonpresel"].visible = true
            switching = true
          end
        else
          pbPlayDecisionSE
          tmpribbon                      = @pokemon.ribbons[oldselribbon]
          @pokemon.ribbons[oldselribbon] = @pokemon.ribbons[selribbon]
          @pokemon.ribbons[selribbon]    = tmpribbon
          if @pokemon.ribbons[oldselribbon] || @pokemon.ribbons[selribbon]
            @pokemon.ribbons.compact!
            if selribbon>=numRibbons
              selribbon = numRibbons-1
              hasMovedCursor = true
            end
          end
          @sprites["ribbonpresel"].visible = false
          switching = false
          drawSelectedRibbon(@pokemon.ribbons[selribbon])
        end
      elsif Input.trigger?(Input::UP)
        selribbon -= 4
        selribbon += numRows*4 if selribbon<0
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        selribbon += 4
        selribbon -= numRows*4 if selribbon>=numRows*4
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        selribbon -= 1
        selribbon += 4 if selribbon%4==3
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT)
        selribbon += 1
        selribbon -= 4 if selribbon%4==0
        hasMovedCursor = true
        pbPlayCursorSE
      end
      if hasMovedCursor
        @ribbonOffset = (selribbon/4).floor if selribbon<@ribbonOffset*4
        @ribbonOffset = (selribbon/4).floor-2 if selribbon>=(@ribbonOffset+3)*4
        @ribbonOffset = 0 if @ribbonOffset<0
        @ribbonOffset = numRows-3 if @ribbonOffset>numRows-3
        @sprites["ribbonsel"].index    = selribbon-@ribbonOffset*4
        @sprites["ribbonpresel"].index = oldselribbon-@ribbonOffset*4
        drawSelectedRibbon(@pokemon.ribbons[selribbon])
      end
    end
    @sprites["ribbonsel"].visible = false
  end

  def pbChooseMoveToForget(moveToLearn)
    selmove = 0
    maxmove = (moveToLearn>0) ? 4 : 3
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        selmove = 4
        pbPlayCloseMenuSE if moveToLearn>0
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove<0
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(moveToLearn,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove>maxmove
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = (moveToLearn>0) ? maxmove : 0
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(moveToLearn,newmove)
      end
    end
    return (selmove==4) ? -1 : selmove
  end

  def pbScene
    
    pbPlayCry(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::A)
        pbSEStop
        pbPlayCry(@pokemon)
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        if @page==3
          pbPlayDecisionSE
          drawPageStatsExpanded
          dorefresh = true
        elsif @page==4
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif @page==@pageNumber
          pbPlayDecisionSE
          pbRibbonSelection
          dorefresh = true
        elsif !@inbattle
          #pbPlayCry(@pokemon)
          
          pbPlayDecisionSE
          dorefresh = pbOptions

        end
      elsif Input.trigger?(Input::UP) && @partyindex>0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex!=oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 1 if @page<1
        @page = @pageNumber if @page>@pageNumber
        if @page!=oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 1 if @page<1
        @page = @pageNumber if @page>@pageNumber
        if @page!=oldpage   # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh = true
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @partyindex
  end
  
  # Método actualizado para usar MenuHandlers
  def pbOptions
    dorefresh = false
    command_list = []
    commands = []
    
    # Construir comandos usando MenuHandlers
    MenuHandlers.each_available(:summary_options, self, @pokemon, @partyindex) do |option, hash, name|
      command_list.push(name)
      commands.push(hash)
    end
    command_list.push(_INTL("Cancelar"))
    
    # Mostrar menú y ejecutar comando seleccionado
    command = pbShowCommands(command_list)
    if command >= 0 && command < commands.length
      dorefresh = commands[command]["effect"].call(self, @pokemon, @partyindex)
    end
    
    return dorefresh
  end
    
end

class PokemonSummary
  def initialize(scene,inbattle=false)
    @scene = scene
    @inbattle = inbattle
  end

  def pbStartScreen(party,partyindex)
    @scene.pbStartScene(party,partyindex,@inbattle)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party,partyindex,moveToLearn)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,moveToLearn)
    loop do
      ret = @scene.pbChooseMoveToForget(moveToLearn)
      if ret>=0 && moveToLearn!=0 && pbIsHiddenMove?(party[partyindex].moves[ret].id) && !$DEBUG
        Kernel.pbMessage(_INTL("Los movimientos de MO no se pueden olvidar así.")){ @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party,partyindex,message)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,0)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(0)
      if ret<0
        Kernel.pbMessage(_INTL("¡Debes elegir un movimiento!")){ @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end
end

class MoveSelectionSprite < SpriteWrapper
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport=nil,fifthmove=false)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/summarymovesel")
    @frame = 0
    @index = 0
    @fifthmove = fifthmove
    @preselected = false
    @updating = false
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def preselected=(value)
    @preselected = value
    refresh
  end

  def refresh
    w = @movesel.width
    h = @movesel.height/2
    self.x = 240
    self.y = 92+(self.index*64)
    self.y -= 76 if @fifthmove
    self.y += 20 if @fifthmove && self.index==4
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating = true
    super
    @movesel.update
    @updating = false
    refresh
  end
end

class RibbonSelectionSprite < MoveSelectionSprite
  def initialize(viewport=nil)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/cursor_ribbon")
    @frame = 0
    @index = 0
    @preselected = false
    @updating = false
    @spriteVisible = true
    refresh
  end

  def visible=(value)
    super
    @spriteVisible = value if !@updating
  end

  def refresh
    w = @movesel.width
    h = @movesel.height/2
    self.x = 228+(self.index%4)*68
    self.y = 76+((self.index/4).floor*68)
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating = true
    super
    self.visible = @spriteVisible && @index>=0 && @index<12
    @movesel.update
    @updating = false
    refresh
  end
end


#===============================================================================
# MenuHandlers para cuando pulsas C
#===============================================================================
MenuHandlers.add(:summary_options, :pokedex, {
  "name"      => _INTL("Ver Pokédex"),
  "order"     => 10,
  "condition" => proc { |screen, pokemon, party_idx| next !pokemon.isEgg?},
  "effect"    => proc { |screen, pokemon, party_idx|
    pbFadeOutIn {
      scene=PokemonPokedexScene.new
      pokedexscreen=PokemonPokedex.new(scene)
      pokedexscreen.pbDexEntry(pokemon.species)
    }
    next true
  }
})