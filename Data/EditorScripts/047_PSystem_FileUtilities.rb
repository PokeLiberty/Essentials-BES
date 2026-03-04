
#===============================================================================
# FUNCIONES HELPER - Construcción de variantes
#===============================================================================

# Construye array de carpetas en orden de prioridad (v21 → v16)
def pbBattlerFolders(back=false, female=false, shiny=false)
  folders_v21 = []
  folders_v16 = []
  
  # v21: Graphics/Pokemon/
  if shiny && back
    folders_v21 << "Graphics/Pokemon/BackShiny/"
  elsif shiny
    folders_v21 << "Graphics/Pokemon/FrontShiny/"
  elsif back
    folders_v21 << "Graphics/Pokemon/Back/"
  else
    folders_v21 << "Graphics/Pokemon/Front/"
  end
  folders_v21 << "Graphics/Pokemon/Front/Female/" if female && !back && !shiny
  folders_v21 << "Graphics/Pokemon/Back/Female/" if female && back && !shiny
  folders_v21 << "Graphics/Pokemon/FrontShiny/Female/" if female && shiny && !back
  folders_v21 << "Graphics/Pokemon/BackShiny/Female/" if female && shiny && back
  
  # v16: Graphics/Battlers/
  if shiny && back
    folders_v16 << "Graphics/Battlers/BackShiny/"
  elsif shiny
    folders_v16 << "Graphics/Battlers/FrontShiny/"
  elsif back
    folders_v16 << "Graphics/Battlers/Back/"
  else
    folders_v16 << "Graphics/Battlers/Front/"
  end
  folders_v16 << "Graphics/Battlers/Front/Female/" if female && !back && !shiny
  folders_v16 << "Graphics/Battlers/Back/Female/" if female && back && !shiny
  folders_v16 << "Graphics/Battlers/FrontShiny/Female/" if female && shiny && !back
  folders_v16 << "Graphics/Battlers/BackShiny/Female/" if female && shiny && back
  
  return folders_v21 + folders_v16
end

# Construye variantes de nombres de archivo
def pbBitmapVariants(species, form=0, shadow=false)
  tform = (form && form > 0) ? "_#{form}" : ""
  tshadow = shadow ? "_shadow" : ""
  speciesname = getConstantName(PBSpecies, species) rescue nil
  
  variants = []
  
  # Prioridad: nombre de especie + forma/shadow → ID numérico
  if speciesname
    variants << "#{speciesname}#{tform}#{tshadow}"
    variants << "#{speciesname}#{tform}" if tshadow
    variants << "#{speciesname}#{tshadow}" if tform
    variants << speciesname
  end
  
  variants << sprintf("%03d%s%s", species, tform, tshadow)
  variants << sprintf("%03d%s", species, tform) if tshadow
  variants << sprintf("%03d%s", species, tshadow) if tform
  variants << sprintf("%03d", species)
  
  return variants
end

# Busca en múltiples carpetas y variantes
def pbSearchBitmapVariants(folders, variants)
  folders.each do |folder|
    variants.each do |variant|
      bitmap = "#{folder}#{variant}"
      begin
        ret = pbResolveBitmap(bitmap)
        return ret if ret
      rescue
        # Continúa si la carpeta no existe o hay error
        next
      end
    end
  end
  return nil
end

#===============================================================================
# Load Pokémon sprites
#===============================================================================
def pbLoadPokemonBitmap(pokemon, back=false)
  scale = back ? BACKSPRITESCALE : POKEMONSPRITESCALE
  return pbLoadPokemonBitmapSpecies(pokemon, pokemon.species, back, scale)
end

def pbLoadPokemonBitmapSpecies(pokemon, species, back=false, scale=POKEMONSPRITESCALE)
  scale = back ? BACKSPRITESCALE : POKEMONSPRITESCALE
  ret = nil
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  
  if pokemon.isEgg?
    bitmapFileName = pbLoadEggBitmap(species, pokemon.isShiny?)
  else
    bitmapFileName = pbCheckPokemonBitmapFiles([species, back, (pokemon.isFemale?), 
                                                pokemon.isShiny?, (pokemon.form rescue 0),
                                                (pokemon.isShadow? rescue false)])
  end
  
  bitmapFileName = sprintf("Graphics/Battlers/000") if bitmapFileName.nil?
  animatedBitmap = AnimatedBitmapWrapper.new(bitmapFileName, scale) if bitmapFileName
  ret = animatedBitmap if bitmapFileName
  
  # Compatibilidad con alterBitmap
  alterBitmap = (MultipleForms.getFunction(species, "alterBitmap") rescue nil) if !pokemon.isEgg? && animatedBitmap
  if bitmapFileName && alterBitmap
    if animatedBitmap.totalFrames == 1
      alterBitmap.call(pokemon, animatedBitmap.bitmap)
    else
      animatedBitmap.prepareStrip
      for i in 0...animatedBitmap.totalFrames
        alterBitmap.call(pokemon, animatedBitmap.alterBitmap(i))
      end
      animatedBitmap.compileStrip
    end
    ret = animatedBitmap
  end
  return ret
end

def pbLoadEggBitmap(species, shiny=false)
  # v21
  variants = pbBitmapVariants(species, 0, false)
  folders = ["Graphics/Pokemon/Eggs/"] + ["Graphics/Battlers/Eggs/"]
  bitmap = pbSearchBitmapVariants(folders, variants)
  return bitmap if bitmap
  
  # Fallback
  return pbResolveBitmap("Graphics/Battlers/Eggs/000s") if shiny
  return pbResolveBitmap("Graphics/Battlers/Eggs/000")
end

def pbLoadSpeciesBitmap(species, female=false, form=0, shiny=false, shadow=false, back=false, egg=false, scale=POKEMONSPRITESCALE)
  ret = nil
  if egg
    bitmapFileName = pbLoadEggBitmap(species, shiny)
  else
    bitmapFileName = pbCheckPokemonBitmapFiles([species, back, female, shiny, form, shadow])
  end
  bitmapFileName = sprintf("Graphics/Battlers/Front/000") if !bitmapFileName
  ret = AnimatedBitmapWrapper.new(bitmapFileName, scale) if bitmapFileName
  return ret
end

def pbCheckPokemonBitmapFiles(params)
  species, back, female, shiny, form, shadow = params[0], params[1], params[2], params[3], params[4], params[5]
  
  # Construir carpetas
  folders = pbBattlerFolders(back, female, shiny)
  
  # Construir variantes de nombre
  variants = pbBitmapVariants(species, form, shadow)
  
  # Buscar
  return pbSearchBitmapVariants(folders, variants)
end

def pbPokemonBitmapFile(species, shiny, back=false)
  variants = pbBitmapVariants(species, 0, false)
  
  folders = []
  if shiny && back
    folders = ["Graphics/Pokemon/BackShiny/", "Graphics/Battlers/BackShiny/", "Graphics/Battlers/Back Shiny/"]
  elsif shiny
    folders = ["Graphics/Pokemon/FrontShiny/", "Graphics/Battlers/FrontShiny/", "Graphics/Battlers/Front Shiny/"]
  elsif back
    folders = ["Graphics/Pokemon/Back/", "Graphics/Battlers/Back/"]
  else
    folders = ["Graphics/Pokemon/Front/", "Graphics/Battlers/Front/"]
  end
  
  return pbSearchBitmapVariants(folders, variants)
end

def pbLoadFakePokemonBitmap(species, boy=false, shiny=false, form=0, back=false)
  bitmapFileName = pbCheckPokemonBitmapFiles([species, back, boy, shiny, form, false])
  animatedBitmap = AnimatedBitmapWrapper.new(bitmapFileName)
  return animatedBitmap
end

#===============================================================================
# Load Pokémon icons
#===============================================================================
def pbLoadPokemonIcon(pokemon)
  return AnimatedBitmap.new(pbPokemonIconFile(pokemon)).deanimate
end

def pbPokemonIconFile(pokemon)
  bitmapFileName = pbCheckPokemonIconFiles([pokemon.species, (pokemon.isFemale?),
                                            pokemon.isShiny?, (pokemon.form rescue 0),
                                            (pokemon.isShadow? rescue false)], pokemon.isEgg?)
  return bitmapFileName || sprintf("Graphics/Icons/icon000")
end

def pbCheckPokemonIconFiles(params, egg=false)
  species, female, shiny, form, shadow = params[0], params[1], params[2], params[3], params[4]
  
  if egg
    tshiny = shiny ? "s" : ""
    speciesname = getConstantName(PBSpecies, species) rescue nil
    
    # v21: sin prefijo
    variants_v21 = []
    variants_v21 << "#{speciesname}egg" if speciesname
    variants_v21 << sprintf("%03degg", species)
    bitmap = pbSearchBitmapVariants(["Graphics/Pokemon/Icons/"], variants_v21)
    return bitmap if bitmap
    
    # v16: con prefijo
    variants_v16 = []
    variants_v16 << "icon#{speciesname}egg" if speciesname
    variants_v16 << sprintf("icon%03degg", species)
    bitmap = pbSearchBitmapVariants(["Graphics/Icons/"], variants_v16)
    return bitmap if bitmap
    
    begin
      return pbResolveBitmap("Graphics/Icons/iconEgg")
    rescue
      return nil
    end
  end
  
  # Construir variantes
  tgender = female ? "f" : ""
  tshiny = shiny ? "s" : ""
  tform = (form && form > 0) ? "_#{form}" : ""
  tshadow = shadow ? "_shadow" : ""
  speciesname = getConstantName(PBSpecies, species) rescue nil
  
  # v21: sin prefijo "icon"
  variants_v21 = []
  if speciesname
    variants_v21 << "#{speciesname}#{tgender}#{tshiny}#{tform}#{tshadow}"
    variants_v21 << "#{speciesname}#{tgender}#{tshiny}#{tform}" if tshadow
    variants_v21 << "#{speciesname}#{tgender}#{tshiny}#{tshadow}" if tform
    variants_v21 << "#{speciesname}#{tgender}#{tshiny}" if tform && tshadow
    variants_v21 << "#{speciesname}#{tgender}#{tshiny}"
    variants_v21 << "#{speciesname}#{tgender}" if tshiny || tshadow
    variants_v21 << speciesname
  end
  
  variants_v21 << sprintf("%03d%s%s%s%s", species, tgender, tshiny, tform, tshadow)
  variants_v21 << sprintf("%03d%s%s%s", species, tgender, tshiny, tform) if tshadow
  variants_v21 << sprintf("%03d%s%s%s", species, tgender, tshiny, tshadow) if tform
  variants_v21 << sprintf("%03d%s%s", species, tgender, tshiny)
  variants_v21 << sprintf("%03d%s", species, tgender) if tshiny || tshadow
  variants_v21 << sprintf("%03d", species)
  
  bitmap = pbSearchBitmapVariants(["Graphics/Pokemon/Icons/"], variants_v21)
  return bitmap if bitmap
  
  # v16: con prefijo "icon"
  variants_v16 = []
  if speciesname
    variants_v16 << "icon#{speciesname}#{tgender}#{tshiny}#{tform}#{tshadow}"
    variants_v16 << "icon#{speciesname}#{tgender}#{tshiny}#{tform}" if tshadow
    variants_v16 << "icon#{speciesname}#{tgender}#{tshiny}#{tshadow}" if tform
    variants_v16 << "icon#{speciesname}#{tgender}#{tshiny}" if tform && tshadow
    variants_v16 << "icon#{speciesname}#{tgender}#{tshiny}"
    variants_v16 << "icon#{speciesname}#{tgender}" if tshiny || tshadow
    variants_v16 << "icon#{speciesname}"
  end
  
  variants_v16 << sprintf("icon%03d%s%s%s%s", species, tgender, tshiny, tform, tshadow)
  variants_v16 << sprintf("icon%03d%s%s%s", species, tgender, tshiny, tform) if tshadow
  variants_v16 << sprintf("icon%03d%s%s%s", species, tgender, tshiny, tshadow) if tform
  variants_v16 << sprintf("icon%03d%s%s", species, tgender, tshiny)
  variants_v16 << sprintf("icon%03d%s", species, tgender) if tshiny || tshadow
  variants_v16 << sprintf("icon%03d", species)
  
  bitmap = pbSearchBitmapVariants(["Graphics/Icons/"], variants_v16)
  return bitmap if bitmap
  
  begin
    return pbResolveBitmap("Graphics/Icons/icon000")
  rescue
    return nil
  end
end

#===============================================================================
# Load Pokémon footprint graphics
#===============================================================================
def pbPokemonFootprintFile(pokemon, form=0)
  return nil if !pokemon
  
  species = pokemon.is_a?(Numeric) ? pokemon : pokemon.species
  form = pokemon.is_a?(Numeric) ? form : (pokemon.form rescue 0)
  
  tform = (form && form > 0) ? "_#{form}" : ""
  speciesname = getConstantName(PBSpecies, species) rescue nil
  
  variants = []
  if speciesname
    variants << "footprint#{speciesname}#{tform}"
    variants << "footprint#{speciesname}" if tform
  end
  
  variants << sprintf("footprint%03d%s", species, tform)
  variants << sprintf("footprint%03d", species)
  
  folders = ["Graphics/Pokemon/Footprints/", "Graphics/Icons/Footprints/"]
  bitmap = pbSearchBitmapVariants(folders, variants)
  return bitmap
end

#===============================================================================
# Load item icons
#===============================================================================
def pbItemIconFile(item)
  return nil if !item
  bitmapFileName=nil
  if item==0
    bitmapFileName=sprintf("Graphics/Icons/itemBack")
  else
    bitmapFileName=sprintf("Graphics/Icons/item%s",getConstantName(PBItems,item)) rescue nil
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=sprintf("Graphics/Icons/item%03d",item)
    end
  end
  # BES-T Usa un icono por defecto para las MT y las megapiedras, si no existe uno.
  if pbIsMachine?(item) && !pbResolveBitmap(bitmapFileName)
    movedata=pbRgssOpen("Data/moves.dat")
    movedata.pos=$ItemData[item][ITEMMACHINE]*14+3
    typeid=movedata.fgetb
    movedata.close
    type=getConstantName(PBTypes,typeid)
    bitmapFileName=sprintf("Graphics/Icons/TM_%s",type)
  end
  if pbIsMegaStone?(item) && !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Icons/item_Megastone")
  end
  return bitmapFileName
end

#===============================================================================
# Load mail background graphics
#===============================================================================
def pbMailBackFile(item)
  return nil if !item
  bitmapFileName=sprintf("Graphics/Pictures/mail%s",getConstantName(PBItems,item)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Pictures/mail%03d",item)
  end
  return bitmapFileName
end

#===============================================================================
# Load NPC charsets
#===============================================================================
def pbTrainerCharFile(type)   # Used by the phone
  return nil if !type
  bitmapFileName=sprintf("Graphics/Characters/trchar%s",getConstantName(PBTrainers,type)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Characters/trchar%03d",type)
  end
  return bitmapFileName
end

def pbTrainerCharNameFile(type)   # Used by Battle Frontier and compiler
  return nil if !type
  bitmapFileName=sprintf("trchar%s",getConstantName(PBTrainers,type)) rescue nil
  if !pbResolveBitmap(sprintf("Graphics/Characters/"+bitmapFileName))
    bitmapFileName=sprintf("trchar%03d",type)
  end
  return bitmapFileName
end

#===============================================================================
# Load trainer sprites
#===============================================================================
def pbTrainerSpriteFile(type)
  return nil if !type
  bitmapFileName=sprintf("Graphics/Battlers/Trainers/trainer%s",getConstantName(PBTrainers,type)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Battlers/Trainers/trainer%03d",type)
  end
  return bitmapFileName
end

def pbTrainerSpriteBackFile(type)
  return nil if !type
  bitmapFileName=sprintf("Graphics/Battlers/Trainers/trback%s",getConstantName(PBTrainers,type)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Battlers/Trainers/trback%03d",type)
  end
  return bitmapFileName
end

def pbPlayerSpriteFile(type)
  return nil if !type
  outfit=$Trainer ? $Trainer.outfit : 0
  bitmapFileName=sprintf("Graphics/Battlers/Trainers/trainer%s_%d",
     getConstantName(PBTrainers,type),outfit) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Battlers/Trainers/trainer%03d_%d",type,outfit)
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=pbTrainerSpriteFile(type)
    end
  end
  return bitmapFileName
end

def pbPlayerSpriteBackFile(type)
  return nil if !type
  outfit=$Trainer ? $Trainer.outfit : 0
  bitmapFileName=sprintf("Graphics/Battlers/Trainers/trback%s_%d",
     getConstantName(PBTrainers,type),outfit) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Battlers/Trainers/trback%03d_%d",type,outfit)
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=pbTrainerSpriteBackFile(type)
    end
  end
  return bitmapFileName
end

#===============================================================================
# Load player's head icons (used in the Town Map)
#===============================================================================
def pbTrainerHeadFile(type)
  return nil if !type
  bitmapFileName=sprintf("Graphics/Pictures/mapPlayer%s",getConstantName(PBTrainers,type)) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Pictures/mapPlayer%03d",type)
  end
  return bitmapFileName
end

def pbPlayerHeadFile(type)
  return nil if !type
  outfit = ($Trainer) ? $Trainer.outfit : 0
  bitmapFileName=sprintf("Graphics/Pictures/mapPlayer%s_%d",
     getConstantName(PBTrainers,type),outfit) rescue nil
  if !pbResolveBitmap(bitmapFileName)
    bitmapFileName=sprintf("Graphics/Pictures/mapPlayer%03d_%d",type,outfit)
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=pbTrainerHeadFile(type)
    end
  end
  return bitmapFileName
end

#===============================================================================
# Analyse audio files
#===============================================================================
def pbResolveAudioSE(file)
  return nil if !file
  if RTP.exists?("Audio/SE/"+file,["",".wav",".mp3",".ogg"])
    return RTP.getPath("Audio/SE/"+file,["",".wav",".mp3",".ogg"])
  end
  return nil
end

def pbResolveAudioBGS(file)
  return nil if !file
  if RTP.exists?("Audio/BGS/"+file,["",".wav",".mp3",".ogg"])
    return RTP.getPath("Audio/BGS/"+file,["",".wav",".mp3",".ogg"])
  end
  return nil
end

def pbCryFrameLength(pokemon,form=0,pitch=nil)
  return 0 if !pokemon
  pitch=100 if !pitch
  pitch=pitch.to_f/100
  return 0 if pitch<=0
  playtime=0.0
  if pokemon.is_a?(Numeric)
    pkmnwav = pbResolveAudioSE(pbCryFile(pokemon,form))
    playtime=getPlayTime(pkmnwav) if pkmnwav
  elsif !pokemon.isEgg?
    if pokemon.respond_to?("chatter") && pokemon.chatter
      playtime=pokemon.chatter.time
      pitch=1.0
    else
      pkmnwav=pbResolveAudioSE(pbCryFile(pokemon))
      playtime=getPlayTime(pkmnwav) if pkmnwav
    end
  end
  playtime/=pitch # sound is lengthened the lower the pitch
  # 4 is added to provide a buffer between sounds
  return (playtime*Graphics.frame_rate).ceil+4
end

#===============================================================================
# Load/play Pokémon cry files
#===============================================================================
def pbPlayCry(pokemon,volume=90,pitch=nil)
  return if !pokemon
  if pokemon.is_a?(Numeric)
    pbPlayCrySpecies(pokemon,0,volume,pitch)
  elsif !pokemon.egg?
    if pokemon.respond_to?("chatter") && pokemon.chatter
      pokemon.chatter.play
    else
      pkmnwav=pbCryFile(pokemon)
      if pkmnwav
        pbSEPlay(RPG::AudioFile.new(pkmnwav,volume,
           (pitch) ? pitch : (pokemon.hp*25/pokemon.totalhp)+75)) rescue nil
      end
    end
  end
end

def pbPlayCrySpecies(pokemon,form=0,volume=90,pitch=nil)
  return if !pokemon
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Numeric)
    pkmnwav = pbCryFile(pokemon,form)
    if pkmnwav
      pbSEPlay(RPG::AudioFile.new(pkmnwav,volume,(pitch) ? pitch : 100)) rescue nil
    end
  end
end

def pbCryFile(pokemon,form=0)
  return nil if !pokemon
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Numeric)
    filename = sprintf("Cries/%sCry_%d",getConstantName(PBSpecies,pokemon),form) rescue nil
    if !pbResolveAudioSE(filename)
      filename = sprintf("Cries/%03dCry_%d",pokemon,form)
      if !pbResolveAudioSE(filename)
    filename=sprintf("Cries/%sCry",getConstantName(PBSpecies,pokemon)) rescue nil
        if !pbResolveAudioSE(filename)
          filename = sprintf("Cries/%03dCry",pokemon)
        end
      end
    end
    return filename if pbResolveAudioSE(filename)
  elsif !pokemon.egg?
    form = (pokemon.form rescue 0)
    filename = sprintf("Cries/%sCry_%d",getConstantName(PBSpecies,pokemon.species),form) rescue nil
    if !pbResolveAudioSE(filename)
      filename = sprintf("Cries/%03dCry_%d",pokemon.species,form)
    if !pbResolveAudioSE(filename)
      filename=sprintf("Cries/%sCry",getConstantName(PBSpecies,pokemon.species)) rescue nil
        if !pbResolveAudioSE(filename)
          filename = sprintf("Cries/%03dCry",pokemon.species)
        end
    end
    end
    return filename if pbResolveAudioSE(filename)
  end
  return nil
end

#===============================================================================
# Load various wild battle music
#===============================================================================
def pbGetWildBattleBGM(species)
  if $PokemonGlobal.nextBattleBGM
    return $PokemonGlobal.nextBattleBGM.clone
  end
  ret=nil
  if !ret && $game_map
    # Check map-specific metadata
    music=pbGetMetadata($game_map.map_id,MetadataMapWildBattleBGM)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  if !ret
    # Check global metadata
    music=pbGetMetadata(0,MetadataWildBattleBGM)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  ret = pbStringToAudioFile("Battle wild") if !ret
  return ret
end

def pbGetWildVictoryME
  if $PokemonGlobal.nextBattleME
    return $PokemonGlobal.nextBattleME.clone
  end
  ret=nil
  if !ret && $game_map
    # Check map-specific metadata
    music=pbGetMetadata($game_map.map_id,MetadataMapWildVictoryME)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  if !ret
    # Check global metadata
    music=pbGetMetadata(0,MetadataWildVictoryME)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  ret = pbStringToAudioFile("Battle victory") if !ret
  ret.name="../../Audio/ME/"+ret.name
  return ret
end

#===============================================================================
# Load/play various trainer battle music
#===============================================================================
def pbPlayTrainerIntroME(trainertype)
  pbRgssOpen("Data/trainertypes.dat","rb"){|f|
     trainertypes=Marshal.load(f)
     if trainertypes[trainertype]
       bgm=trainertypes[trainertype][6]
       if bgm && bgm!=""
         bgm=pbStringToAudioFile(bgm)
         pbMEPlay(bgm)
         return
       end
     end
  }
end

def pbGetTrainerBattleBGM(trainer) # can be a PokeBattle_Trainer or an array of PokeBattle_Trainer
  if $PokemonGlobal.nextBattleBGM
    return $PokemonGlobal.nextBattleBGM.clone
  end
  ret = nil
  music=nil
  pbRgssOpen("Data/trainertypes.dat","rb"){|f|
     trainertypes=Marshal.load(f)
     trainerarray = (trainer.is_a?(Array)) ? trainer : [trainer]
     for i in 0...trainerarray.length
       trainertype=trainerarray[i].trainertype
       if trainertypes[trainertype]
         music=trainertypes[trainertype][4]
       end
     end
  }
  if music && music!=""
    ret=pbStringToAudioFile(music)
  end
  if !ret && $game_map
    # Check map-specific metadata
    music=pbGetMetadata($game_map.map_id,MetadataMapTrainerBattleBGM)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  if !ret
    # Check global metadata
    music=pbGetMetadata(0,MetadataTrainerBattleBGM)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  ret = pbStringToAudioFile("Battle trainer") if !ret
  return ret
end

def pbGetTrainerBattleBGMFromType(trainertype)
  if $PokemonGlobal.nextBattleBGM
    return $PokemonGlobal.nextBattleBGM.clone
  end
  music=nil
  pbRgssOpen("Data/trainertypes.dat","rb"){|f|
    trainertypes=Marshal.load(f)
    if trainertypes[trainertype]
      music=trainertypes[trainertype][4]
    end
  }
  ret=nil
  if music && music!=""
    ret=pbStringToAudioFile(music)
  end
  if !ret && $game_map
    # Check map-specific metadata
    music=pbGetMetadata($game_map.map_id,MetadataMapTrainerBattleBGM)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  if !ret
    # Check global metadata
    music=pbGetMetadata(0,MetadataTrainerBattleBGM)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  ret = pbStringToAudioFile("Battle trainer") if !ret
  return ret
end

def pbGetTrainerVictoryME(trainer) # can be a PokeBattle_Trainer or an array of PokeBattle_Trainer
  if $PokemonGlobal.nextBattleME
    return $PokemonGlobal.nextBattleME.clone
  end
  music=nil
  pbRgssOpen("Data/trainertypes.dat","rb"){|f|
     trainertypes=Marshal.load(f)
     trainerarray = (trainer.is_a?(Array)) ? trainer : [trainer]
     for i in 0...trainerarray.length
       trainertype=trainerarray[i].trainertype
       if trainertypes[trainertype]
         music=trainertypes[trainertype][5]
       end
     end
  }
  ret=nil
  if music && music!=""
    ret=pbStringToAudioFile(music)
  end
  if !ret && $game_map
    # Check map-specific metadata
    music=pbGetMetadata($game_map.map_id,MetadataMapTrainerVictoryME)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  if !ret
    # Check global metadata
    music=pbGetMetadata(0,MetadataTrainerVictoryME)
    if music && music!=""
      ret=pbStringToAudioFile(music)
    end
  end
  ret = pbStringToAudioFile("Battle victory") if !ret
  ret.name="../../Audio/ME/"+ret.name
  return ret
end