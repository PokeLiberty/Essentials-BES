#===============================================================================
# * Advanced Pokédex - by FL
#===============================================================================
#
# This script is for Pokémon Essentials. When a switch is ON, it displays at 
# pokédex the pokémon PBS data for a caught pokémon like: base exp, egg steps
# to hatch, abilities, wild hold item, evolution, the moves that pokémon can 
# learn by level/breeding/machines/tutors, among others.
#
#===============================================================================
#
# To this script works, put it above main, put a 512x384 background for this
# screen in "Graphics/Pictures/advancedPokedex" location and three 512x384 for
# the top pokédex selection bar at "Graphics/Pictures/advancedPokedexEntryBar",
# "Graphics/Pictures/advancedPokedexNestBar" and
# "Graphics/Pictures/advancedPokedexFormBar".
#
# -In PokemonPokedex script section, after line (use Ctrl+F to find it)
# '@sprites["searchlist"].visible=false' add:
#
# @sprites["dexbar"]=IconSprite.new(0,0,@viewport)
# @sprites["dexbar"].setBitmap(_INTL("Graphics/Pictures/advancedPokedexEntryBar"))
# @sprites["dexbar"].visible=false
#
# -After line '@sprites["dexentry"].visible=true' add:
#
# if @sprites["dexbar"] && $game_switches[AdvancedPokedexScene::SWITCH]
#   @sprites["dexbar"].visible=true 
# end 
#
# -Change line 'newpage=page+1 if page<3' to 
# 'newpage=page+1 if page<($game_switches[AdvancedPokedexScene::SWITCH] ? 4 : 3)'.
# -After line 'ret=screen.pbStartScreen(@dexlist[curindex][0],listlimits)' add:
#
# when 4 # Advanced Data
#   scene=AdvancedPokedexScene.new
#   screen=AdvancedPokedex.new(scene)
#   ret=screen.pbStartScreen(@dexlist[curindex][0],listlimits)
#
# -In PokemonNestAndForm script section, before line 
# '@sprites["map"]=IconSprite.new(0,0,@viewport)' add:
#
# if $game_switches[AdvancedPokedexScene::SWITCH]
#   @sprites["dexbar"]=IconSprite.new(0,0,@viewport)
#   @sprites["dexbar"].setBitmap(_INTL("Graphics/Pictures/advancedPokedexNestBar"))
# end
#
# -Before line 
# '@sprites["info"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)'
# add:
#
# if $game_switches[AdvancedPokedexScene::SWITCH]
#   @sprites["dexbar"]=IconSprite.new(0,0,@viewport)
#   @sprites["dexbar"].setBitmap(_INTL("Graphics/Pictures/advancedPokedexFormBar"))
# end
#
# -After line 'pbChooseForm' add:
#
# elsif Input.trigger?(Input::RIGHT)
#   if $game_switches[AdvancedPokedexScene::SWITCH]
#     ret=6
#     break
#   end
#
#===============================================================================

class AdvancedPokedexScene
  # When true always shows the egg moves of the first evolution stage
  EGGMOVESFISTSTAGE = true
  # When false shows different messages for each of custom evolutions,
  # change the messages to ones that fills to your method
  HIDECUSTOMEVOLUTION = true
  # When true displays TMs/HMs/Tutors moves
  SHOWMACHINETUTORMOVES = true
  # When true picks the number for TMs and the first digit after a H for 
  # HMs (like H8) when showing machine moves.
  FORMATMACHINEMOVES = true
  # When false doesn't displays moves in tm.txt PBS that aren't in
  # any TM/HM item
  SHOWTUTORMOVES = true
  # The division between tutor and machine (TM/HMs) moves is made by 
  # the TM data in items.txt PBS 
  
  def pbStartScene(species)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @species=species
    @gender=$Trainer.formlastseen[species][0]
    @form=$Trainer.formlastseen[species][1]
    
    @dummypokemon=PokeBattle_Pokemon.new(1,1)
    @dummypokemon.species=species
    @dummypokemon.setGender(@gender)
    @dummypokemon.forceForm(@form)
    @sprites={}
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/advancedPokedex"))
    @sprites["overlay"]=BitmapSprite.new(
        Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay"].x=0
    @sprites["overlay"].y=0

    pbSetSmallFont(@sprites["overlay"].bitmap)

    @sprites["info"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["icon"]=PokemonSpeciesIconSprite.new(@species,@viewport)
    @sprites["icon"].pbSetParams(@species,@gender,@form)
    @sprites["icon"].x=52
    @sprites["icon"].y=290
    @type1=nil
    @type2=nil
    @page=1
    @totalPages=0
    if $Trainer.owned[@species]
      @infoPages=3
      @infoArray=getInfo
      @levelMovesArray=getLevelMoves
      @eggMovesArray=getEggMoves
      @machineMovesArray=getMachineMoves if SHOWMACHINETUTORMOVES
      @levelMovesPages = (@levelMovesArray.size+9)/10
      @eggMovesPages = (@eggMovesArray.size+9)/10
      @machineMovesPages=(@machineMovesArray.size+9)/10 if SHOWMACHINETUTORMOVES
      @totalPages = @infoPages+@levelMovesPages+@eggMovesPages
      @totalPages+=@machineMovesPages if SHOWMACHINETUTORMOVES
      displayPage
    end
    pbUpdate
    return true
  end
  
  BASECOLOR = Color.new(88,88,80)
  SHADOWCOLOR = Color.new(168,184,184)
  BASE_X = 32
  EXTRA_X = 224
  BASE_Y = 64
  EXTRA_Y = 32
  
  def getInfo
    @gender=$Trainer.formlastseen[@species][0]
    @form=$Trainer.formlastseen[@species][1]
    
    @dummypokemon=PokeBattle_Pokemon.new(1,1)
    @dummypokemon.species=@species
    @dummypokemon.setGender(@gender)
    @dummypokemon.forceForm(@form)
    ret = []
    for i in 0...2*4
      ret[i]=[]
      for j in 0...6
        ret[i][j]=nil
      end
    end  
    dexdata=pbOpenDexData
    # Type
    @type1=@dummypokemon.type1
    @type2=@dummypokemon.type2
    # Catch Rate
    pbDexDataOffset(dexdata,@dummypokemon.species,16)
    ret[2][0]=_INTL("Ratio de captura: {1}",dexdata.fgetb)
    # Happiness base
    pbDexDataOffset(dexdata,@dummypokemon.species,19)
    ret[2][1]=_INTL("Amistad base: {1}",dexdata.fgetb)
    # Base Exp
    pbDexDataOffset(dexdata,@dummypokemon.species,38)
    ret[2][2]=_INTL("Exp. Base: {1}",dexdata.fgetw)
    # Color
    pbDexDataOffset(dexdata,@dummypokemon.species,6)
    colorName=[
        _INTL("Rojo"),_INTL("Azul"),_INTL("Amarillo"),
        _INTL("Verde"),_INTL("Negro"),_INTL("Marrón"),
        _INTL("Morado"),_INTL("Gris"),_INTL("Blanco"),_INTL("Rosa")
    ][dexdata.fgetb]
    ret[2][3]=_INTL("Color: {1}",colorName)
    # Growth Rate
    pbDexDataOffset(dexdata,@dummypokemon.species,20)
    growthRate=dexdata.fgetb
    growthRateString = [_INTL("Medio"),_INTL("Errático"),_INTL("Fluctuante"),
        _INTL("Parabólico"),_INTL("Rápido"),_INTL("Lento")][growthRate]
    ret[2][3]=_INTL("Crecimiento: {1} ({2})",
        growthRateString,PBExperience.pbGetMaxExperience(growthRate))
    # Gender Rate
    pbDexDataOffset(dexdata,@dummypokemon.species,18)
    genderbyte=dexdata.fgetb
    genderPercent= 100-((genderbyte+1)*100/256.0)
    genderString = case genderbyte
      when 0;  _INTL("Siempre macho")
      when 254; _INTL("Siempre hembra")
      when 255; _INTL("Sin genero")
      else;    _INTL("Machos {1}%",genderPercent)
    end
    ret[2][4]=_INTL("Sexo: {1}",genderString)
    # Egg Steps to Hatch
    pbDexDataOffset(dexdata,@dummypokemon.species,21)
    stepsToHatch = dexdata.fgetw
    ret[4][2]=_INTL("Pasos para la eclosión: {1} ({2} ciclos)",
        stepsToHatch,stepsToHatch/255)
    # Breed Group
    pbDexDataOffset(dexdata,@dummypokemon.species,31)
    compat10=dexdata.fgetb
    compat11=dexdata.fgetb
    eggGroupArray=[
        nil,_INTL("Monstruo"),_INTL("Agua 1"),_INTL("Bicho"),_INTL("Volador"),
        _INTL("Tierra"),_INTL("Hada"),_INTL("Vegetal"),_INTL("Humanoide"),
        _INTL("Agua 3"),_INTL("Mineral"),_INTL("Desconocido"),
        _INTL("Agua 2"),_INTL("Ditto"),_INTL("Dragón"),_INTL("No puede criar")
    ]
    eggGroups = compat10==compat11 ? eggGroupArray[compat10] :
        _INTL("{1}, {2}",eggGroupArray[compat10],eggGroupArray[compat11])
    ret[4][3]=_INTL("Grupo Huevo: {1}",eggGroups)
    # Abilities
    pbDexDataOffset(dexdata,@dummypokemon.species,2)
    ability1=dexdata.fgetw
    ability2=dexdata.fgetw
    pbDexDataOffset(dexdata,@dummypokemon.species,40)
    hiddenAbility1=dexdata.fgetw
    
    begin;s1 = @dummypokemon.getAbilityList[0][0];rescue; s1 = nil; end
    begin;s2 = @dummypokemon.getAbilityList[1][0];rescue; s2 = nil; end
    begin;s3 = @dummypokemon.getAbilityList[3][0];rescue; s3 = nil; end
      
    begin
    p s1+", "+ s2+", "+ s3
    rescue;end
    
    sability1 = (PBAbilities.getName(s1)) if s1
    sability2 = (", "+PBAbilities.getName(s2)) if s2
    sability3 = (", "+PBAbilities.getName(s3)) if s3

    abilityString=(_INTL("{1}{2}{3}", sability1, sability2, sability3))
    ret[4][0]=_INTL("Habilidades: {1}",abilityString)

    # Wild hold item
    pbDexDataOffset(dexdata,@species,48)
    holdItems=[dexdata.fgetw,dexdata.fgetw,dexdata.fgetw]
    holdItemsStrings=[]
    if(holdItems[0]!=0 && holdItems[0]==holdItems[1] &&
        holdItems[0]==holdItems[2])
      holdItemsStrings.push(_INTL("{1} (Siempre)",
          PBItems.getName(holdItems[0])))
    else
      holdItemsStrings.push(_INTL("{1} (A menudo)",
          PBItems.getName(holdItems[0]))) if holdItems[0]>0
      holdItemsStrings.push(_INTL("{1} (A veces)",
          PBItems.getName(holdItems[1]))) if holdItems[1]>0
      holdItemsStrings.push(_INTL("{1} (Casi nunca)",
          PBItems.getName(holdItems[2]))) if holdItems[2]>0
    end
    ret[4][5] = _INTL("Objeto: {1}",holdItemsStrings.empty? ?
        "" : holdItemsStrings[0])
    ret[4][6] = holdItemsStrings[1] if holdItemsStrings.size>1
    ret[4][7] = holdItemsStrings[2] if holdItemsStrings.size>2
    # Base Stats
    pbDexDataOffset(dexdata,@species,10)
    baseStats=[
        @dummypokemon.baseStats[0], # HP
        @dummypokemon.baseStats[1], # Attack
        @dummypokemon.baseStats[2], # Defense
        @dummypokemon.baseStats[3], # Speed
        @dummypokemon.baseStats[4], # Special Attack
        @dummypokemon.baseStats[5]  # Special Defense
    ]
    baseStatsTot=0
    for i in 0...baseStats.size
      baseStatsTot+=baseStats[i]
    end
    baseStats.push(baseStatsTot)
    ret[0][0]=_ISPRINTF(
        "                        PS    ATQ  DEF  VEL  AT.E DF.E    TOTAL")
    ret[0][1]=_ISPRINTF(
        "Stats Base:       {1:03d}  {2:03d}  {3:03d}  {4:03d}  {5:03d}  {6:03d}     {7:03d}",
        baseStats[0],baseStats[1],baseStats[2],
        baseStats[3],baseStats[4],baseStats[5],baseStats[6])
    # Effort Points
    pbDexDataOffset(dexdata,@species,23)
    effortPoints=[
        dexdata.fgetb, # HP
        dexdata.fgetb, # Attack
        dexdata.fgetb, # Defense
        dexdata.fgetb, # Speed
        dexdata.fgetb, # Special Attack
        dexdata.fgetb  # Special Defense
    ]
    effortPointsTot=0
    for i in 0...effortPoints.size
      effortPoints[i]=0 if  !effortPoints[i]
      effortPointsTot+=effortPoints[i]
    end
    effortPoints.push(effortPointsTot)
    ret[0][2]=_ISPRINTF(
        "P. de Esfuerzo:     {1:03d}  {2:03d}  {3:03d}  {4:03d}  {5:03d}  {6:03d}",
        effortPoints[0],effortPoints[1],effortPoints[2],
        effortPoints[3],effortPoints[4],effortPoints[5],effortPoints[6])
    # Evolutions
    evolutionsStrings = []
    lastEvolutionSpecies = -1
    for evolution in pbGetEvolvedFormData(@dummypokemon.species)
      # The below "if" it's to won't list the same evolution species more than
      # one time. Only the last is displayed.
      #evolutionsStrings.pop if lastEvolutionSpecies==evolution[2]
      evolutionsStrings.push(getEvolutionMessage(evolution))
      lastEvolutionSpecies=evolution[2]
    end
    if !evolutionsStrings.empty?
      line=4
      column=0
    ret[column][line] = _INTL("EVO: {1}",evolutionsStrings.empty? ? 
        "" : evolutionsStrings[0])
    evolutionsStrings.shift
    line+=1
    for string in evolutionsStrings
      if(line>5) # For when the pokémon has more than 3 evolutions (AKA Eevee) 
        line=0
        column+=2
        @infoPages+=1 # Creates a new page
          ret += Array.new(2){ [] } 
      end
      ret[column][line] = string
      line+=1
    end
    end
    # End
    dexdata.close
    return ret
  end  
  
  # Gets the evolution array and return evolution message
  def getEvolutionMessage(evolution)
    evoPokemon = PBSpecies.getName(evolution[2])
    evoMethod = evolution[0]
    evoItem = evolution[1] # Sometimes it's level
    ret = case evoMethod
      when 1, 37
        _INTL("{1} cuando es feliz.",evoPokemon)
      
      when 1, 37, 38, 39
        _INTL("{1} cuando es feliz (Forma Alternativa)",evoPokemon)

      when 2
        _INTL("{1} cuando es feliz de día.",evoPokemon)
      when 3
        _INTL("{1} cuando es feliz de noche.",evoPokemon)
      when 4, 13, 31 # Pokémon that evolve by level AND Ninjask
        _INTL("{1} al nivel {2}.",evoPokemon,evoItem)   
      when 32, 33, 49 
        _INTL("{1} al nivel {2}. (Forma Alternativa)",evoPokemon,evoItem) 
      when 5
        _INTL("{1} intercambio o usando Cordón unión.",evoPokemon)
      when 6
        _INTL("{1} intercambio llevando {2}.",evoPokemon,PBItems.getName(evoItem))
      when 7, 34
        _INTL("{1} usando {2}.",evoPokemon,PBItems.getName(evoItem))
      when 35, 36
        _INTL("{1} usando {2}. (Forma Alternativa)",evoPokemon,PBItems.getName(evoItem))
      when 8 # Hitmonlee
        _INTL("{1} al nivel {2} y ATK > DEF.",evoPokemon,evoItem)
      when 9 # Hitmontop
        _INTL("{1} al nivel {2} y ATK = DEF.",evoPokemon,evoItem)
      when 10 # Hitmonchan
        _INTL("{1} al nivel {2} y DEF < ATK.",evoPokemon,evoItem)
      when 11, 12 # Silcoon/Cascoon
        _INTL("{1} al nivel {2} aleatoriamente.",evoPokemon,evoItem)
      when 14 # Shedinja
        _INTL("{1} al nivel {2} con un espacio libre.",evoPokemon,evoItem)
      when 15 # Milotic
        _INTL("{1} belleza al máximo {2}.",evoPokemon,evoItem) 
      when 16
        _INTL("{1} usando {2} y es macho.",evoPokemon,PBItems.getName(evoItem))
      when 17
        _INTL("{1} usando {2} y es hembra.",evoPokemon,PBItems.getName(evoItem))
      when 18
        _INTL("{1} llevando equipado un {2} de día.", evoPokemon,PBItems.getName(evoItem))
      when 19
        _INTL("{1} llevando equipado un {2} de noche.", evoPokemon,PBItems.getName(evoItem))
      when 46, 47, 48
        _INTL("{1} llevando equipado un {2}.", evoPokemon,PBItems.getName(evoItem))
      when 20, 51 
        _INTL("{1} si conoce {2}.", evoPokemon,PBMoves.getName(evoItem))
      when 52, 53
        _INTL("{1} si conoce {2}. (Forma Alternativa)", evoPokemon,PBMoves.getName(evoItem))
      when 21
        _INTL("{1} cuando {2} está en el equipo.",evoPokemon,PBSpecies.getName(evoItem))
      when 22
        _INTL("{1} al nivel {2} si es macho.",evoPokemon,evoItem)
      when 23
        _INTL("{1} al nivel {2} si es hembra.",evoPokemon,evoItem)
      when 24 # Evolves on a certain map
        _INTL("{1} en {2}.",evoPokemon, pbGetMapNameFromId(evoItem)) 
      when 25 # Escavalier/Accelgor
        _INTL("{1} intercambiándolo por {2}.",evoPokemon,PBSpecies.getName(evoItem)) 
      when 26, 40
        _INTL("{1} al nivel {2} de día.", evoPokemon,evoItem)
      when 41, 42
        _INTL("{1} al nivel {2} de día. (Forma Alternativa)", evoPokemon,evoItem)
      when 27, 43
        _INTL("{1} al nivel {2} de noche.", evoPokemon,evoItem)
      when 44, 45
        _INTL("{1} al nivel {2} de noche. (Forma Alternativa)", evoPokemon,evoItem)
      when 28
        _INTL("{1} al nivel {2} con un tipo siniestro en el equipo.", evoPokemon,evoItem)
      when 29
        _INTL("{1} al nivel {2} con lluvia.", evoPokemon,evoItem)
      when 30
        _INTL("{1} amistad y mov. de tipo {2}.", evoPokemon,PBTypes.getName(evoItem))
      when 50
        _INTL("{1} asestando 3 golpes críticos durante un combate.", evoPokemon)
      # When HIDECUSTOMEVOLUTION = false the below 7 messages will be displayed
      when 26;_INTL("{1} custom1 with {2}", evoPokemon,evoItem) 
      when 27;_INTL("{1} custom2 with {2}", evoPokemon,evoItem) 
      when 28;_INTL("{1} custom3 with {2}", evoPokemon,evoItem) 
      when 29;_INTL("{1} custom4 with {2}", evoPokemon,evoItem) 
      when 30;_INTL("{1} custom5 with {2}", evoPokemon,evoItem) 
      when 31;_INTL("{1} custom6 with {2}", evoPokemon,evoItem)
      when 32;_INTL("{1} custom7 with {2}", evoPokemon,evoItem)
      else; ""  
    end  
    ret = _INTL("{1} de manera desconocida.", evoPokemon) if(ret.empty? ||
        (evoMethod>=55 && HIDECUSTOMEVOLUTION))
    return ret    
  end
  
  def getLevelMoves
    ret=[]
    moves=[]
    pbEachNaturalMove(@dummypokemon){|move,level|
      #moves.push(level,move) if !moves.include?(move)
      move=PBMoves.getName(move)
      ret.push(_ISPRINTF("{1:02d} {2:s}",level,move))
    }
    
    #ret=[]
    #atkdata=pbRgssOpen("Data/attacksRS.dat","rb")
        
    #offset=atkdata.getOffset(@dummypokemon.species-1)
    #length=atkdata.getLength(@dummypokemon.species-1)>>1
    #atkdata.pos=offset
    #for k in 0..length-1
    #  level=atkdata.fgetw
    #  move=PBMoves.getName(atkdata.fgetw)
    #  ret.push(_ISPRINTF("{1:02d} {2:s}",level,move))
    #end
    #atkdata.close
    ret.sort!
    return ret
  end  
  
  def getEggMoves
    ret=[]  
    eggMoveSpecies = @dummypokemon.species
    eggMoveSpecies = pbGetBabySpecies(eggMoveSpecies) if EGGMOVESFISTSTAGE
    pbRgssOpen("Data/eggEmerald.dat","rb"){|f|
      f.pos=(eggMoveSpecies-1)*8
      offset=f.fgetdw
      length=f.fgetdw
      if length>0
        f.pos=offset
        i=0; loop do break unless i<length
          move=PBMoves.getName(f.fgetw)
          ret.push(_ISPRINTF("     {1:s}",move))
          i+=1
        end
      end
    }
    ret.sort!
    return ret
  end  
  
  def getMachineMoves
    ret=[]
    movesArray=[]
    machineMoves=[]
    tmData=load_data("Data/tm.dat")
    for move in 1...tmData.size
      next if !tmData[move]
      movesArray.push(move) if tmData[move].any?{ |item| item==@dummypokemon.species }
    end
    for item in 1..PBItems.maxValue
      if pbIsMachine?(item)
        move = $ItemData[item][ITEMMACHINE]
        if movesArray.include?(move)
          if FORMATMACHINEMOVES
            machineLabel = PBItems.getName(item)
            machineLabel = machineLabel[2,machineLabel.size-2] 
            machineLabel = "H"+machineLabel[1,1] if pbIsHiddenMachine?(item)
            ret.push(_ISPRINTF("{1:s} {2:s}",
                machineLabel,PBMoves.getName(move)))
            movesArray.delete(move)
          else
            machineMoves.push(move)
          end  
        end
      end  
    end
    # The above line removes the tutors moves. The movesArray will be 
    # empty if the machines are already in the ret array.
    movesArray = machineMoves if !SHOWTUTORMOVES
    unnumeredMoves=[]
    for move in movesArray # Show the moves unnumered
      unnumeredMoves.push(_ISPRINTF("     {1:s}",PBMoves.getName(move)))
    end  
    ret = ret.sort + unnumeredMoves.sort
    return ret
  end  
  
  def displayPage
    return if !$Trainer.owned[@species]
    if(@page<=@infoPages)
      pageInfo(@page)
    elsif(@page<=@infoPages+@levelMovesPages)
      pageMoves(@levelMovesArray,_INTL("Movimientos por Nivel:"),@page-@infoPages)
    elsif(@page<=@infoPages+@levelMovesPages+@eggMovesPages)
      pageMoves(@eggMovesArray,_INTL("Movimientos Huevo:"),
          @page-@infoPages-@levelMovesPages)
    elsif(SHOWMACHINETUTORMOVES && 
        @page <= @infoPages+@levelMovesPages+@eggMovesPages+@machineMovesPages)
      pageMoves(@machineMovesArray,_INTL("Por Máquina Tecnica:"),
          @page-@infoPages-@levelMovesPages-@eggMovesPages)
    end
  end  
  
  def pageInfo(page)
    @sprites["overlay"].bitmap.clear
    textpos = []
    for i in (12*(page-1))...(12*page)
      line = i%6
      column = i/6
      next if !@infoArray[column][line]
      x = BASE_X+EXTRA_X*(column%2)
      y = BASE_Y+EXTRA_Y*line
      textpos.push([@infoArray[column][line],x,y,false,BASECOLOR,SHADOWCOLOR])
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
  end  
  
  def pageMoves(movesArray,label,page)
    @sprites["overlay"].bitmap.clear
    textpos = [[label,BASE_X,BASE_Y,false,BASECOLOR,SHADOWCOLOR]]
    for i in (10*(page-1))...(10*page)
      break if i>=movesArray.size
      line = i%5
      column = i/5
      x = BASE_X+EXTRA_X*(column%2)
      y = BASE_Y+EXTRA_Y*(line+1)
      textpos.push([movesArray[i],x,y,false,BASECOLOR,SHADOWCOLOR])
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
  end  
  
  def pbUpdate
    @sprites["info"].bitmap.clear
    pbSetSystemFont(@sprites["info"].bitmap)
    height = Graphics.height-54
    text=[[PBSpecies.getName(@species),(Graphics.width+72)/2,height-32,
         2,BASECOLOR,SHADOWCOLOR]]
    text.push([_INTL("{1}/{2}",@page,@totalPages),Graphics.width-52,height,
         1,BASECOLOR,SHADOWCOLOR]) if $Trainer.owned[@species]
    pbDrawTextPositions(@sprites["info"].bitmap,text)
    typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/pokedexTypes"))
    if !@type1 # This "if" only occurs when the getInfo isn't called
      dexdata=pbOpenDexData
      pbDexDataOffset(dexdata,@species,8) # Type
      @type1=dexdata.fgetb
      @type2=dexdata.fgetb
      dexdata.close
    end
    type1rect=Rect.new(0,@type1*32,96,32)
    type2rect=Rect.new(0,@type2*32,96,32)
    if(@type1==@type2)
      @sprites["info"].bitmap.blt((Graphics.width+16-36)/2,height,
          typebitmap.bitmap,type1rect)
    else  
      @sprites["info"].bitmap.blt((Graphics.width+16-144)/2,height,
          typebitmap.bitmap,type1rect)
      @sprites["info"].bitmap.blt((Graphics.width+16+72)/2,height,
          typebitmap.bitmap,type2rect) if @type1!=@type2
    end
    @sprites["icon"].update
  end

  def pbControls(listlimits)
    Graphics.transition
    ret=0
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::C)
        @page+=1
        @page=1 if @page>@totalPages
        displayPage
      elsif Input.trigger?(Input::A)
        @page-=1
        @page=@totalPages if @page<1
        displayPage
      elsif Input.trigger?(Input::LEFT)
        ret=4
        break
      # If not at top of list  
      elsif Input.trigger?(Input::UP) && listlimits&1==0 
        ret=8
        break
      # If not at end of list  
      elsif Input.trigger?(Input::DOWN) && listlimits&2==0 
        ret=2
        break
      elsif Input.trigger?(Input::B)
        ret=1
        pbPlayCancelSE()
        pbFadeOutAndHide(@sprites)
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end


class AdvancedPokedex
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(species,listlimits)
    @scene.pbStartScene(species)
    ret=@scene.pbControls(listlimits)
    @scene.pbEndScene
    return ret
  end
end