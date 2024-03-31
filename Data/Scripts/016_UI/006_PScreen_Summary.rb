class MoveSelectionSprite < SpriteWrapper
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport=nil,fifthmove=false)
    super(viewport)
    @movesel=AnimatedBitmap.new("Graphics/#{SUMMARY_ROUTE}/summarymovesel")
    @frame=0
    @index=0
    @fifthmove=fifthmove
    @preselected=false
    @updating=false
    @spriteVisible=true
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index=value
    refresh
  end

  def preselected=(value)
    @preselected=value
    refresh
  end

  def visible=(value)
    super
    @spriteVisible=value if !@updating
  end

  def refresh
    w=@movesel.width
    h=@movesel.height/2
    self.x=240
    self.y=92+(self.index*64)
    self.y-=76 if @fifthmove
    self.y+=20 if @fifthmove && self.index==4
    self.bitmap=@movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating=true
    super
    @movesel.update
    @updating=false
    refresh
  end
end



class PokemonSummaryScene
  def pbPokerus(pkmn)
    return pkmn.pokerusStage
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party,partyindex)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @party=party
    @partyindex=partyindex
    @pokemon=@party[@partyindex]
    @sprites={}
    @typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @tera_typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/teraTypes"))
    @sprites["background2"]=IconSprite.new(0,0,@viewport)
    @sprites["background2"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summarybg")
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["pokemon"]=PokemonSprite.new(@viewport)
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokemon"].tone=TERATONES[@pokemon.teratype] if @pokemon.isTera?
    @sprites["pokemon"].mirror=false
    @sprites["pokemon"].color=Color.new(0,0,0,0)
    pbPositionPokemonSprite(@sprites["pokemon"],40,144)
    @sprites["pokeicon"]=PokemonBoxIcon.new(@pokemon,@viewport)
    @sprites["pokeicon"].x=14
    @sprites["pokeicon"].y=52
    @sprites["pokeicon"].mirror=false
    @sprites["pokeicon"].visible=false
    @sprites["movepresel"]=MoveSelectionSprite.new(@viewport)
    @sprites["movepresel"].visible=false
    @sprites["movepresel"].preselected=true
    @sprites["movesel"]=MoveSelectionSprite.new(@viewport)
    @sprites["movesel"].visible=false
    @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonpresel"].visible     = false
    @sprites["ribbonpresel"].preselected = true
    @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonsel"].visible = false
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
    @page=0
    drawPageOne(@pokemon)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartForgetScene(party,partyindex,moveToLearn)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @party=party
    @partyindex=partyindex
    @pokemon=@party[@partyindex]
    @sprites={}
    @page=3
    @typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["pokeicon"]=PokemonBoxIcon.new(@pokemon,@viewport)
    @sprites["pokeicon"].x=14
    @sprites["pokeicon"].y=52
    @sprites["pokeicon"].mirror=false
    @sprites["movesel"]=MoveSelectionSprite.new(@viewport,moveToLearn>0)
    @sprites["movesel"].visible=false
    @sprites["movesel"].visible=true
    @sprites["movesel"].index=0
    drawSelectedMove(@pokemon,moveToLearn,@pokemon.moves[0].id)
    pbFadeInAndShow(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @tera_typebitmap.dispose
    @viewport.dispose
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

  def drawPageOne(pokemon)
    if pokemon.isEgg?
      drawPageOneEgg(pokemon)
      return
    end
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary1")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/#{SUMMARY_ROUTE}/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    if (pokemon.isShadow? rescue false)
      imagepos.push(["Graphics/#{SUMMARY_ROUTE}/summaryShadow",224,240,0,0,-1,-1])
      shadowfract=pokemon.heartgauge*1.0/PokeBattle_Pokemon::HEARTGAUGESIZE
      imagepos.push(["Graphics/#{SUMMARY_ROUTE}/summaryShadowBar",242,280,0,0,(shadowfract*248).floor,-1])
    end
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    numberbase=(pokemon.isShiny?) ? Color.new(248,56,32) : Color.new(64,64,64)
    numbershadow=(pokemon.isShiny?) ? Color.new(224,152,144) : Color.new(176,176,176)
    publicID=pokemon.publicID
    speciesname=PBSpecies.getName(pokemon.species)
    growthrate=pokemon.growthrate
    startexp=PBExperience.pbGetStartExperience(pokemon.level,growthrate)
    endexp=PBExperience.pbGetStartExperience(pokemon.level+1,growthrate)
    pokename=@pokemon.name
    textpos=[
       [_INTL("DATOS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Objeto"),16,320,0,base,shadow],
       [_ISPRINTF("N° Dex"),238,80,0,base,shadow],
       [sprintf("%03d",pokemon.species),435,80,2,numberbase,numbershadow],
       [_INTL("Especie"),238,112,0,base,shadow],
       [speciesname,435,112,2,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Tipo"),238,144,0,base,shadow],
       [_INTL("EO"),238,176,0,base,shadow],
       [_INTL("N° ID"),238,208,0,base,shadow],
    ]
    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    if (pokemon.isShadow? rescue false)
      textpos.push([_INTL("Medidor del Corazón"),238,240,0,base,shadow])
      heartmessage=[_INTL("¡La puerta de su corazón está abierta! ¡Hacer purificación definitiva!"),
                    _INTL("La puerta de su corazón está casi abierta del todo."),
                    _INTL("La puerta de su corazón está bastante abierta."),
                    _INTL("La puerta de su corazón está un poco abierta."),
                    _INTL("La puerta de su corazón está apenas abierta."),
                    _INTL("La puerta está fuertemente cerrada.")
                    ][pokemon.heartStage]
      memo=sprintf("<c3=404040,B0B0B0>%s\n",heartmessage)
      drawFormattedTextEx(overlay,238,304,276,memo)
    else
      textpos.push([_INTL("Puntos de Experiencia"),238,240,0,base,shadow])
      textpos.push([sprintf("%d",pokemon.exp),488,272,1,Color.new(64,64,64),Color.new(176,176,176)])
      textpos.push([_INTL("Para subir de nivel"),238,304,0,base,shadow])
      textpos.push([sprintf("%d",endexp-pokemon.exp),488,336,1,Color.new(64,64,64),Color.new(176,176,176)])
    end
    idno=(pokemon.ot=="") ? "?????" : sprintf("%05d",publicID)
    textpos.push([idno,435,208,2,Color.new(64,64,64),Color.new(176,176,176)])
    if pokemon.ot==""
      textpos.push([_INTL("PRESTADO"),435,176,2,Color.new(64,64,64),Color.new(176,176,176)])
    else
      ownerbase=Color.new(64,64,64)
      ownershadow=Color.new(176,176,176)
      if pokemon.otgender==0            # EO masculino
        ownerbase=Color.new(24,112,216)
        ownershadow=Color.new(136,168,208)
      elsif pokemon.otgender==1         # EO femenino
        ownerbase=Color.new(248,56,32)
        ownershadow=Color.new(224,152,144)
      end
      textpos.push([pokemon.ot,435,176,2,ownerbase,ownershadow])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
    type1rect=Rect.new(0,pokemon.type1*28,64,28)
    type2rect=Rect.new(0,pokemon.type2*28,64,28)
    teratyperect=Rect.new(0,pokemon.teratype*32,32,32)
    if pokemon.type1==pokemon.type2
      overlay.blt(402,146,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(370,146,@typebitmap.bitmap,type1rect)
      overlay.blt(436,146,@typebitmap.bitmap,type2rect)
    end
    if ![getConst(PBSpecies,:OGERPON),getConst(PBSpecies,:TERAPAGOS)].include?(pokemon.species) && !$game_switches[NO_TERA_CRISTAL]
      overlay.blt(330,142,@tera_typebitmap.bitmap,teratyperect)
    end
    if pokemon.level<PBExperience::MAXLEVEL
      overlay.fill_rect(362,372,(pokemon.exp-startexp)*128/(endexp-startexp),2,Color.new(72,120,160))
      overlay.fill_rect(362,374,(pokemon.exp-startexp)*128/(endexp-startexp),4,Color.new(24,144,248))
    end
  end

  def drawPageOneEgg(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summaryEgg")
    imagepos=[]
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    textpos=[
       [_INTL("NOTAS ENTRENADOR"),26,16,0,base,shadow],
       [pokemon.name,46,62,0,base,shadow],
       [_INTL("Objeto"),16,320,0,base,shadow]
    ]
    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    pbDrawTextPositions(overlay,textpos)
    memo=""
    if pokemon.timeReceived
      month=pbGetAbbrevMonthName(pokemon.timeReceived.mon)
      date=pokemon.timeReceived.day
      year=pokemon.timeReceived.year
      memo+=_INTL("<c3=404040,B0B0B0>{2} de {1} de {3}\n",month,date,year)
    end
    mapname=pbGetMapNameFromId(pokemon.obtainMap)
    if (pokemon.obtainText rescue false) && pokemon.obtainText!=""
      mapname=pokemon.obtainText
    end
    if mapname && mapname!=""
      memo+=_INTL("<c3=404040,B0B0B0>Un extraño Huevo Pokémon hallado por la <c3=F83820,E09890>{1}<c3=404040,B0B0B0>.\n",mapname)
    end
    memo+="<c3=404040,B0B0B0>\n"
    memo+=_INTL("<c3=404040,B0B0B0>\"Estado del Huevo\"\n")
    eggstate=_INTL("Parece que a este Huevo le tomará mucho tiempo abrirse.")
    eggstate=_INTL("¿Qué saldrá? Aún le queda para abrirse.") if pokemon.eggsteps<10200
    eggstate=_INTL("A veces se mueve. Debería abrirse pronto.") if pokemon.eggsteps<2550
    eggstate=_INTL("Está haciendo ruidos. ¡Está a punto de abrirse!") if pokemon.eggsteps<1275
    memo+=sprintf("<c3=404040,B0B0B0>%s\n",eggstate)
    drawFormattedTextEx(overlay,232,78,276,memo)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawPageTwo(pokemon)
    @Amistadbitmap=AnimatedBitmap.new(_INTL("Graphics/#{SUMMARY_ROUTE}/friendship"))
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary2")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/#{SUMMARY_ROUTE}/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    naturename=PBNatures.getName(pokemon.nature)
    pokename=@pokemon.name
    textpos=[
       [_INTL("NOTAS ENTRENADOR"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Objeto"),16,320,0,base,shadow
       ]
    ]
    if EXPANDED_SUMMARY_INFO
      textpos.push([_INTL("Amistad:"),256+8,334,0,Color.new(64,64,64),Color.new(176,176,176)])
      amistad=pokemon.happiness/44
      amistad=amistad.floor
    end

    nivelamistad=Rect.new(0,amistad*18,128,18)
    overlay.blt(356,334+8,@Amistadbitmap.bitmap,nivelamistad)

    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    memo=""
    shownature=(!(pokemon.isShadow? rescue false)) || pokemon.heartStage<=3
    if shownature
      memo+=_INTL("<c3=404040,B0B0B0>Naturaleza <c3=F83820,E09890>{1}<c3=404040,B0B0B0>.\n",naturename)
    end
    if pokemon.timeReceived
      month=pbGetAbbrevMonthName(pokemon.timeReceived.mon)
      date=pokemon.timeReceived.day
      year=pokemon.timeReceived.year
      memo+=_INTL("<c3=404040,B0B0B0>{2} de {1} de {3}\n",month,date,year)
    end
    mapname=pbGetMapNameFromId(pokemon.obtainMap)
    if (pokemon.obtainText rescue false) && pokemon.obtainText!=""
      mapname=pokemon.obtainText
    end
    if mapname && mapname!=""
      memo+=sprintf("<c3=F83820,E09890>%s\n",mapname)
    else
      memo+=_INTL("<c3=F83820,E09890>Faraway place\n")
    end
    if pokemon.obtainMode
      mettext=[_INTL("Encontrado con Nv. {1}.",pokemon.obtainLevel),
               _INTL("Huevo recibido."),
               _INTL("Intercambiado con Nv. {1}.",pokemon.obtainLevel),
               "",
               _INTL("Lo conocí en un encuentro fatídico en Nv. {1}.",pokemon.obtainLevel)
               ][pokemon.obtainMode]
      memo+=sprintf("<c3=404040,B0B0B0>%s\n",mettext)
      if pokemon.obtainMode==1 # hatched
        if pokemon.timeEggHatched
          month=pbGetAbbrevMonthName(pokemon.timeEggHatched.mon)
          date=pokemon.timeEggHatched.day
          year=pokemon.timeEggHatched.year
          memo+=_INTL("<c3=404040,B0B0B0>{2} de {1} de {3}\n",month,date,year)
        end
        mapname=pbGetMapNameFromId(pokemon.hatchedMap)
        if mapname && mapname!=""
          memo+=sprintf("<c3=F83820,E09890>%s\n",mapname)
        else
          memo+=_INTL("<c3=F83820,E09890>Faraway place\n")
        end
        memo+=_INTL("<c3=404040,B0B0B0>Huevo eclosionado.\n")
      else
        memo+="<c3=404040,B0B0B0>\n"
      end
    end
    if shownature
      bestiv=0
      tiebreaker=pokemon.personalID%6
      for i in 0...6
        if pokemon.iv[i]==pokemon.iv[bestiv]
          bestiv=i if i>=tiebreaker && bestiv<tiebreaker
        elsif pokemon.iv[i]>pokemon.iv[bestiv]
          bestiv=i
        end
      end
      characteristic=[_INTL("Le encanta comer."),       # Loves to eat
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
                      ][bestiv*5+pokemon.iv[bestiv]%5]
      memo+=sprintf("<c3=404040,B0B0B0>%s\n",characteristic)
    end
    drawFormattedTextEx(overlay,232,78,276,memo)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawPageThree(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary3")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/#{SUMMARY_ROUTE}/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    statshadows=[]
    for i in 0...5; statshadows[i]=shadow; end
    if !(pokemon.isShadow? rescue false) || pokemon.heartStage<=3
      natup=(pokemon.nature/5).floor
      natdn=(pokemon.nature%5).floor
      statshadows[natup]=Color.new(136,96,72) if natup!=natdn
      statshadows[natdn]=Color.new(64,120,152) if natup!=natdn
    end
    pbSetSystemFont(overlay)
    abilityname=PBAbilities.getName(pokemon.ability)
    abilitydesc=pbGetMessage(MessageTypes::AbilityDescs,pokemon.ability)
    pokename=@pokemon.name

    textpos=[
       [_INTL("CARACTERÍSTICAS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Objeto"),16,320,0,base,shadow],
       [_INTL("Habilidad"),224,284,0,base,shadow],
       [abilityname,342,284,0,Color.new(64,64,64),Color.new(176,176,176)],

       [_INTL("PS"),234,76,0,base,shadow],
       [_INTL("Ataque"),234,120,0,base,statshadows[0]],
       [_INTL("Defensa"),234,152,0,base,statshadows[1]],
       [_INTL("At. Esp."),234,184,0,base,statshadows[3]],
       [_INTL("Def. Esp."),234,216,0,base,statshadows[4]],
       [_INTL("Velocidad"),234,248,0,base,statshadows[2]],
       ]

    if EXPANDED_SUMMARY_INFO
    textpos+=[
       [sprintf("%3d/%3d",pokemon.hp,pokemon.totalhp),344,76,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.attack),366,120,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.defense),366,152,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.spatk),366,184,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.spdef),366,216,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.speed),366,248,2,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    #EV
    textpos+=[
       [sprintf("%d",pokemon.ev[0]),424,76,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.ev[1]),424,120,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.ev[2]),424,152,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.ev[4]),424,184,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.ev[5]),424,216,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.ev[3]),424,248,2,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    #IV
    textpos+=[
       [sprintf("%d",pokemon.iv[0]),476,76,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.iv[1]),476,120,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.iv[2]),476,152,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.iv[4]),476,184,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.iv[5]),476,216,2,Color.new(64,64,64),Color.new(176,176,176)],
       [sprintf("%d",pokemon.iv[3]),476,248,2,Color.new(64,64,64),Color.new(176,176,176)],
    ]

    else
      textpos+=[
         [sprintf("%3d/%3d",pokemon.hp,pokemon.totalhp),456,76,2,Color.new(64,64,64),Color.new(176,176,176)],
         [sprintf("%d",pokemon.attack),456,120,2,Color.new(64,64,64),Color.new(176,176,176)],
         [sprintf("%d",pokemon.defense),456,152,2,Color.new(64,64,64),Color.new(176,176,176)],
         [sprintf("%d",pokemon.spatk),456,184,2,Color.new(64,64,64),Color.new(176,176,176)],
         [sprintf("%d",pokemon.spdef),456,216,2,Color.new(64,64,64),Color.new(176,176,176)],
         [sprintf("%d",pokemon.speed),456,248,2,Color.new(64,64,64),Color.new(176,176,176)],
      ]
    end
    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    pbSetSmallFont(overlay)
    if EXPANDED_SUMMARY_INFO
      drawTextEx(overlay,224,316,282,2,"Presiona C para más información.",Color.new(64,64,64),Color.new(176,176,176))
    else
      drawTextEx(overlay,224,316,282,2,abilitydesc,Color.new(64,64,64),Color.new(176,176,176))
    end
    pbSetSystemFont(overlay)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
    if pokemon.hp>0
      hpcolors=[
         Color.new(24,192,32),Color.new(0,144,0),     # Green
         Color.new(248,184,0),Color.new(184,112,0),   # Orange
         Color.new(240,80,32),Color.new(168,48,56)    # Red
      ]
      hpzone=0
      hpzone=1 if pokemon.hp<=(@pokemon.totalhp/2).floor
      hpzone=2 if pokemon.hp<=(@pokemon.totalhp/4).floor
      overlay.fill_rect(272,110,pokemon.hp*96/pokemon.totalhp,2,hpcolors[hpzone*2+1])
      overlay.fill_rect(272,112,pokemon.hp*96/pokemon.totalhp,4,hpcolors[hpzone*2])
    end
  end

  def drawPageThreeExpanded(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary3details")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/#{SUMMARY_ROUTE}/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    statshadows=[]
    for i in 0...5; statshadows[i]=shadow; end
    if !(pokemon.isShadow? rescue false) || pokemon.heartStage<=3
      natup=(pokemon.nature/5).floor
      natdn=(pokemon.nature%5).floor
      statshadows[natup]=Color.new(136,96,72) if natup!=natdn
      statshadows[natdn]=Color.new(64,120,152) if natup!=natdn
    end
    pbSetSystemFont(overlay)
    abilityname=PBAbilities.getName(pokemon.ability)
    abilitydesc=pbGetMessage(MessageTypes::AbilityDescs,pokemon.ability)
    pokename=@pokemon.name
    textpos=[
       [_INTL("CARACTERÍSTICAS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Objeto"),16,320,0,base,shadow],
       [abilityname,232,76,0,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end

    textpos.push([_INTL("Poder Oculto",abilityname),256+8,334,0,base,shadow])
    hp=pbHiddenPower(pokemon.iv)
    type1rect=Rect.new(0,hp[0]*28,64,28)
    overlay.blt(416-8,334+2,@typebitmap.bitmap,type1rect)

    pbDrawTextPositions(overlay,textpos)

    #drawTextEx(overlay,224,316,282,2,abilitydesc,Color.new(64,64,64),Color.new(176,176,176))
    pbSetSmallFont(overlay)
    drawFormattedTextEx(overlay,232,112,272,abilitydesc,Color.new(64,64,64),Color.new(176,176,176))

    pbSetSystemFont(overlay)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)



    loop do
      Input.update
      Graphics.update
      if Input.trigger?(Input::B)
        Input.update
        break
      elsif Input.trigger?(Input::C)
        Input.update
        break
      end
      pbUpdate
    end

  end

  def drawPageFour(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary4")
    @sprites["pokemon"].visible=true
    @sprites["pokeicon"].visible=false
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/#{SUMMARY_ROUTE}/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    pokename=@pokemon.name
    textpos=[
       [_INTL("MOVIMIENTOS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Objeto"),16,320,0,base,shadow]
    ]
    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    imagepos=[]
    yPos=98
    for i in 0...pokemon.moves.length
      if pokemon.moves[i].id>0
        imagepos.push(["Graphics/Pictures/types",248,yPos+2,0,
           pokemon.moves[i].type*28,64,28])
        textpos.push([PBMoves.getName(pokemon.moves[i].id),316,yPos,0,
           Color.new(64,64,64),Color.new(176,176,176)])
        if pokemon.moves[i].totalpp>0
          textpos.push([_ISPRINTF("PP"),342,yPos+32,0,
             Color.new(64,64,64),Color.new(176,176,176)])
          textpos.push([sprintf("%d/%d",pokemon.moves[i].pp,pokemon.moves[i].totalpp),
             460,yPos+32,1,Color.new(64,64,64),Color.new(176,176,176)])
        end
      else
        textpos.push(["-",316,yPos,0,Color.new(64,64,64),Color.new(176,176,176)])
        textpos.push(["--",442,yPos+32,1,Color.new(64,64,64),Color.new(176,176,176)])
      end
      yPos+=64
    end
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawSelectedMove(pokemon,moveToLearn,moveid)
    overlay=@sprites["overlay"].bitmap
    @sprites["pokemon"].visible=false if @sprites["pokemon"]
    @sprites["pokeicon"].setBitmap(pbPokemonIconFile(pokemon))
    @sprites["pokeicon"].src_rect=Rect.new(0,0,64,64)
    @sprites["pokeicon"].visible=true
    movedata=PBMoveData.new(moveid)
    basedamage=movedata.basedamage
    type=movedata.type
    category=movedata.category
    accuracy=movedata.accuracy
    drawMoveSelection(pokemon,moveToLearn)
    pbSetSystemFont(overlay)
    move=moveid
    textpos=[
       [basedamage<=1 ? basedamage==1 ? "???" : "---" : sprintf("%d",basedamage),
          216,154,1,Color.new(64,64,64),Color.new(176,176,176)],
       [accuracy==0 ? "---" : sprintf("%d",accuracy),
          216,186,1,Color.new(64,64,64),Color.new(176,176,176)]
    ]
    pbDrawTextPositions(overlay,textpos)
    imagepos=[["Graphics/Pictures/category",166,124,0,category*28,64,28]]
    pbDrawImagePositions(overlay,imagepos)
    pbSetSmallFont(overlay)
    drawTextEx(overlay,4,218,240,5,
       pbGetMessage(MessageTypes::MoveDescriptions,moveid),
       Color.new(64,64,64),Color.new(176,176,176))
    pbSetSystemFont(overlay)
  end

  def drawMoveSelection(pokemon,moveToLearn)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary4details")
    if moveToLearn!=0
      @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary4learning")
    end
    pbSetSystemFont(overlay)
    textpos=[
       [_INTL("MOVIMIENTOS"),26,16,0,base,shadow],
       [_INTL("CATEGORÍA"),20,122,0,base,shadow],
       [_INTL("POTENCIA"),20,154,0,base,shadow],
       [_INTL("PRECISIÓN"),20,186,0,base,shadow]
    ]
    type1rect=Rect.new(0,pokemon.type1*28,64,28)
    type2rect=Rect.new(0,pokemon.type2*28,64,28)
    if pokemon.type1==pokemon.type2
      overlay.blt(130,78,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(96,78,@typebitmap.bitmap,type1rect)
      overlay.blt(166,78,@typebitmap.bitmap,type2rect)
    end
    imagepos=[]
    yPos=98
    yPos-=76 if moveToLearn!=0
    for i in 0...5
      moveobject=nil
      if i==4
        moveobject=PBMove.new(moveToLearn) if moveToLearn!=0
        yPos+=20
      else
        moveobject=pokemon.moves[i]
      end
      if moveobject
        if moveobject.id!=0
          imagepos.push(["Graphics/Pictures/types",248,yPos+2,0,
             moveobject.type*28,64,28])
          textpos.push([PBMoves.getName(moveobject.id),316,yPos,0,
             Color.new(64,64,64),Color.new(176,176,176)])
          if moveobject.totalpp>0
            textpos.push([_ISPRINTF("PP"),342,yPos+32,0,
               Color.new(64,64,64),Color.new(176,176,176)])
            textpos.push([sprintf("%d/%d",moveobject.pp,moveobject.totalpp),
               460,yPos+32,1,Color.new(64,64,64),Color.new(176,176,176)])
          end
        else
          textpos.push(["-",316,yPos,0,Color.new(64,64,64),Color.new(176,176,176)])
          textpos.push(["--",442,yPos+32,1,Color.new(64,64,64),Color.new(176,176,176)])
        end
      end
      yPos+=64
    end
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end

  def drawPageFive(pokemon)
    overlay=@sprites["overlay"].bitmap
    overlay.clear
    @sprites["background"].setBitmap("Graphics/#{SUMMARY_ROUTE}/summary5")
    imagepos=[]
    if pbPokerus(pokemon)==1 || pokemon.hp==0 || @pokemon.status>0
      status=6 if pbPokerus(pokemon)==1
      status=@pokemon.status-1 if @pokemon.status>0
      status=5 if pokemon.hp==0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    if pokemon.isShiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134,0,0,-1,-1])
    end
    if pbPokerus(pokemon)==2
      imagepos.push([sprintf("Graphics/#{SUMMARY_ROUTE}/summaryPokerus"),176,100,0,0,-1,-1])
    end
    ballused=@pokemon.ballused ? @pokemon.ballused : 0
    ballimage=sprintf("Graphics/#{SUMMARY_ROUTE}/summaryball%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60,0,0,-1,-1])
    pbDrawImagePositions(overlay,imagepos)
    base=Color.new(248,248,248)
    shadow=Color.new(104,104,104)
    pbSetSystemFont(overlay)
    pokename=@pokemon.name
    textpos=[
       [_INTL("CINTAS"),26,16,0,base,shadow],
       [pokename,46,62,0,base,shadow],
       [pokemon.level.to_s,46,92,0,Color.new(64,64,64),Color.new(176,176,176)],
       [_INTL("Objeto"),16,320,0,base,shadow],
       [_INTL("Número de Cintas:"),234,332,0,Color.new(64,64,64),Color.new(176,176,176)],
       [@pokemon.ribbonCount.to_s,450,332,1,Color.new(64,64,64),Color.new(176,176,176)],
    ]
    if pokemon.hasItem?
      textpos.push([PBItems.getName(pokemon.item),16,352,0,Color.new(64,64,64),Color.new(176,176,176)])
    else
      textpos.push([_INTL("Ninguno"),16,352,0,Color.new(184,184,160),Color.new(208,208,200)])
    end
    if pokemon.isMale?
      textpos.push([_INTL("♂"),178,62,0,Color.new(24,112,216),Color.new(136,168,208)])
    elsif pokemon.isFemale?
      textpos.push([_INTL("♀"),178,62,0,Color.new(248,56,32),Color.new(224,152,144)])
    end
    pbDrawTextPositions(overlay,textpos)
    imagepos=[]
    coord=0
    if @pokemon.ribbons
      for i in @ribbonOffset*4...@ribbonOffset*4+12
        break if !@pokemon.ribbons[i]
        ribn = @pokemon.ribbons[i]-1
        imagepos.push(["Graphics/Pictures/ribbons",230+68*(coord%4),78+68*(coord/4).floor,
                                                   64*(ribn%8),64*(ribn/8).floor,64,64])
        coord += 1
        break if coord>=12
      end
    end
    pbDrawImagePositions(overlay,imagepos)
    drawMarkings(overlay,15,291,72,20,pokemon.markings)
  end

  def drawSelectedRibbon(pokemon,ribbonid)
    # Draw all of page five
    drawPageFive(pokemon)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    pbSetSystemFont(overlay)
    base   = Color.new(64,64,64)
    shadow = Color.new(176,176,176)
    nameBase   = Color.new(248,248,248)
    nameShadow = Color.new(104,104,104)
    # Get data for selected ribbon
    name = ribbonid ? PBRibbons.getName(ribbonid) : ""
    desc = ribbonid ? PBRibbons.getDescription(ribbonid) : ""
    # Draw the description box
    imagepos = [
       ["Graphics/#{SUMMARY_ROUTE}/overlay_ribbon",8,280,0,0,-1,-1]
    ]
    pbDrawImagePositions(overlay,imagepos)
    # Draw name of selected ribbon
    textpos = [
       [name,18,286,0,nameBase,nameShadow]
    ]
    pbDrawTextPositions(overlay,textpos)
    # Draw selected ribbon's description
    drawTextEx(overlay,18,318,480,2,desc,base,shadow)
  end

  def pbChooseMoveToForget(moveToLearn)
    selmove=0
    ret=0
    maxmove=(moveToLearn>0) ? 4 : 3
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        ret=4
        break
      end
      if Input.trigger?(Input::C)
        break
      end
      if Input.trigger?(Input::DOWN)
        selmove+=1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=(moveToLearn>0) ? maxmove : 0
        end
        selmove=0 if selmove>maxmove
        @sprites["movesel"].index=selmove
        newmove=(selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(@pokemon,moveToLearn,newmove)
        ret=selmove
      end
      if Input.trigger?(Input::UP)
        selmove-=1
        selmove=maxmove if selmove<0
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=@pokemon.numMoves-1
        end
        @sprites["movesel"].index=selmove
        newmove=(selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(@pokemon,moveToLearn,newmove)
        ret=selmove
      end
    end
    return (ret==4) ? -1 : ret
  end

  def pbMoveSelection
    @sprites["movesel"].visible=true
    @sprites["movesel"].index=0
    selmove=0
    oldselmove=0
    switching=false
    drawSelectedMove(@pokemon,0,@pokemon.moves[selmove].id)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z=@sprites["movesel"].z+1
      else
        @sprites["movepresel"].z=@sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        break if !switching
        @sprites["movepresel"].visible=false
        switching=false
      end
      if Input.trigger?(Input::C)
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible=false
          switching=false
        else
          if !(@pokemon.isShadow? rescue false)
            if !switching
              @sprites["movepresel"].index=selmove
              oldselmove=selmove
              @sprites["movepresel"].visible=true
              switching=true
            else
              tmpmove=@pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove]=@pokemon.moves[selmove]
              @pokemon.moves[selmove]=tmpmove
              @sprites["movepresel"].visible=false
              switching=false
              drawSelectedMove(@pokemon,0,@pokemon.moves[selmove].id)
            end
          end
        end
      end
      if Input.trigger?(Input::DOWN)
        selmove+=1
        selmove=0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove=0 if selmove>=4
        selmove=4 if selmove<0
        @sprites["movesel"].index=selmove
        newmove=@pokemon.moves[selmove].id
        pbPlayCursorSE()
        drawSelectedMove(@pokemon,0,newmove)
      end
      if Input.trigger?(Input::UP)
        selmove-=1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=@pokemon.numMoves-1
        end
        selmove=0 if selmove>=4
        selmove=@pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index=selmove
        newmove=@pokemon.moves[selmove].id
        pbPlayCursorSE()
        drawSelectedMove(@pokemon,0,newmove)
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
    drawSelectedRibbon(@pokemon,@pokemon.ribbons[selribbon])
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
        pbPlayCancelSE
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
          drawSelectedRibbon(@pokemon,@pokemon.ribbons[selribbon])
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
        drawSelectedRibbon(@pokemon,@pokemon.ribbons[selribbon])
      end
    end
    @sprites["ribbonsel"].visible = false
  end



  def pbGoToPrevious
    if @page!=0
      newindex=@partyindex
      while newindex>0
        newindex-=1
        if @party[newindex] && !@party[newindex].isEgg?
          @partyindex=newindex
          break
        end
      end
    else
      newindex=@partyindex
      while newindex>0
        newindex-=1
        if @party[newindex]
          @partyindex=newindex
          break
        end
      end
    end
  end

  def pbGoToNext
    if @page!=0
      newindex=@partyindex
      while newindex<@party.length-1
        newindex+=1
        if @party[newindex] && !@party[newindex].isEgg?
          @partyindex=newindex
          break
        end
      end
    else
      newindex=@partyindex
      while newindex<@party.length-1
        newindex+=1
        if @party[newindex]
          @partyindex=newindex
          break
        end
      end
    end
  end

  def pbScene
    pbPlayCry(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        break
      end
      dorefresh=false
      if Input.trigger?(Input::C)
        if @page==0 && @page==1
          #break
          pbPlayCry(@pokemon)
        elsif @page==2
          if EXPANDED_SUMMARY_INFO
            drawPageThreeExpanded(@pokemon)
            dorefresh=true
            drawPageThree(@pokemon)
          else
            pbPlayCry(@pokemon)
          end
        elsif @page==3
          pbMoveSelection
          dorefresh=true
          drawPageFour(@pokemon)
        elsif @page==4
          pbRibbonSelection
          dorefresh=true
        end
      end
      if Input.trigger?(Input::UP) && @partyindex>0
        oldindex=@partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          @pokemon=@party[@partyindex]
          @sprites["pokemon"].setPokemonBitmap(@pokemon)
          @sprites["pokemon"].color=Color.new(0,0,0,0)
          if @pokemon.isTera?
            @sprites["pokemon"].tone=TERATONES[@pokemon.teratype]
          else
            @sprites["pokemon"].tone=Tone.new(0,0,0,0)
          end
          pbPositionPokemonSprite(@sprites["pokemon"],40,144)
          pbSEStop; pbPlayCry(@pokemon)
          @ribbonOffset = 0
          dorefresh=true
        end
      end
      if Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex=@partyindex
        pbGoToNext
        if @partyindex!=oldindex
          @pokemon=@party[@partyindex]
          @sprites["pokemon"].setPokemonBitmap(@pokemon)
          @sprites["pokemon"].color=Color.new(0,0,0,0)
          if @pokemon.isTera?
            @sprites["pokemon"].tone=TERATONES[@pokemon.teratype]
          else
            @sprites["pokemon"].tone=Tone.new(0,0,0,0)
          end
          pbPositionPokemonSprite(@sprites["pokemon"],40,144)
          pbSEStop; pbPlayCry(@pokemon)
          @ribbonOffset = 0
          dorefresh=true
        end
      end
      if Input.trigger?(Input::LEFT) && !@pokemon.isEgg?
        oldpage=@page
        @page-=1
        @page=0 if @page<0
        @page=4 if @page>4
        dorefresh=true
        if @page!=oldpage # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh=true
        end
      end
      if Input.trigger?(Input::RIGHT) && !@pokemon.isEgg?
        oldpage=@page
        @page+=1
        @page=0 if @page<0
        @page=4 if @page>4
        if @page!=oldpage # Move to next page
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          dorefresh=true
        end
      end
      if dorefresh
        case @page
        when 0
          drawPageOne(@pokemon)
        when 1
          drawPageTwo(@pokemon)
        when 2
          drawPageThree(@pokemon)
        when 3
          drawPageFour(@pokemon)
        when 4
          drawPageFive(@pokemon)
        end
      end
    end
    return @partyindex
  end
end



class PokemonSummary
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(party,partyindex)
    @scene.pbStartScene(party,partyindex)
    ret=@scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party,partyindex,moveToLearn)
    ret=-1
    @scene.pbStartForgetScene(party,partyindex,moveToLearn)
    loop do
      ret=@scene.pbChooseMoveToForget(moveToLearn)
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
    ret=-1
    @scene.pbStartForgetScene(party,partyindex,0)
    Kernel.pbMessage(message){ @scene.pbUpdate }
    loop do
      ret=@scene.pbChooseMoveToForget(0)
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
