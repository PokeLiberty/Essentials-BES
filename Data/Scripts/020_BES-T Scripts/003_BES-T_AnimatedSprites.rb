# ELIMINA ESTE SCRIPT SI QUIERES USAR EL ANTIGUO FORMATO PARA CARPETAS Y 
# SIN SPRITES ANIMADOS
# used to scale the Pokemon bitmaps to 200%
POKEMONSPRITESCALE = 2
# used to scale the backsprite for battle perspective (200%)
BACKSPRITESCALE = 3

class DynamicPokemonSprite
  attr_accessor :shadow
  attr_accessor :sprite
  attr_accessor :showshadow
  attr_accessor :status
  attr_accessor :hidden
  attr_accessor :fainted
  attr_accessor :anim
  attr_accessor :charged
  attr_accessor :isShadow
  attr_reader :loaded
  attr_reader :selected
  attr_reader :isSub
  attr_reader :viewport
  attr_reader :pulse

def initialize(doublebattle,index,viewport=nil)
    @viewport=viewport
    @metrics=load_data("Data/metrics.dat")
    @selected=0
    @frame=0
    @frame2=0
    @frame3=0
    
    @status=0
    @loaded=false
    @charged=false
    @index=index
    @doublebattle=doublebattle
    @showshadow=true
    @altitude=0
    @yposition=0
    @shadow=Sprite.new(@viewport)
    @sprite=Sprite.new(@viewport)
      back=(@index%2==0)
    @substitute=AnimatedBitmapWrapper.new("Graphics/Battlers/"+(back ? "substitute_back" : "substitute"),POKEMONSPRITESCALE)
    @overlay=Sprite.new(@viewport)
    @isSub=false
    @lock=false
    @pokemon=nil
    @still=false
    @hidden=false
    @fainted=false
    @anim=false
    @isShadow=false
    
    @fp = {}
    
    @pulse = 8
    @k = 1
  end

  def setPokemonBitmap(pokemon,back=false,species=nil)
    return if !pokemon || pokemon.nil?
    @pokemon = pokemon
    @isShadow = true if @pokemon.isShadow?
    @altitude = @metrics[2][pokemon.species]
    if back
      @yposition = @metrics[0][pokemon.species]
      @altitude *= 0.5
    else
      @yposition = @metrics[1][pokemon.species]
    end
    scale = back ? BACKSPRITESCALE : POKEMONSPRITESCALE

    if !species.nil?
      @bitmap = pbLoadPokemonBitmapSpecies(pokemon,species,back,scale)
    else
      @bitmap = pbLoadPokemonBitmap(pokemon,back,scale)
    end
    @sprite.bitmap = @bitmap.bitmap.clone
    @shadow.bitmap = @bitmap.bitmap.clone
    @sprite.ox = @bitmap.width/2
    @sprite.oy = @bitmap.height
    @sprite.oy += @altitude
    @sprite.oy -= @yposition
    @sprite.oy -= pokemon.formOffsetY if pokemon.respond_to?(:formOffsetY)
    
    @fainted = false
    @loaded = true
    @hidden = false
    self.visible = true
    @pulse = 8
    @k = 1
    self.formatShadow
  end
end

class AnimatedBitmapWrapper
  attr_reader :width
  attr_reader :height
  attr_reader :totalFrames
  attr_reader :animationFrames
  attr_reader :currentIndex
  attr_accessor :scale
  
  def initialize(file,scale=2)
    p "filename is nil" if file==nil
    p ".gif files are not supported!" if File.extname(file)==".gif"
    
    @scale = scale
    @width = 0
    @height = 0
    @frame = 0
    @frames = 2
    @direction = +1
    @animationFinish = false
    @totalFrames = 0
    @currentIndex = 0
    @speed = 1
      # 0 - not moving at all
      # 1 - normal speed
      # 2 - medium speed
      # 3 - slow speed
    bmp = BitmapCache.load_bitmap(file)
    #bmp = Bitmap.new(file)
    @bitmapFile=Bitmap.new(bmp.width,bmp.height); @bitmapFile.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
    # initializes full Pokemon bitmap
    @bitmap=Bitmap.new(@bitmapFile.width,@bitmapFile.height)
    @bitmap.blt(0,0,@bitmapFile,Rect.new(0,0,@bitmapFile.width,@bitmapFile.height))
    @width=@bitmapFile.height*@scale
    @height=@bitmap.height*@scale
    
    @totalFrames=@bitmap.width/@bitmap.height
    @animationFrames=@totalFrames*@frames
    # calculates total number of frames
    @loop_points=[0,@totalFrames]
    # first value is start, second is end
    
    @actualBitmap=Bitmap.new(@width,@height)
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
  alias initialize_elite initialize unless self.method_defined?(:initialize_elite)
    
  def length; @totalFrames; end
  def disposed?; @actualBitmap.disposed?; end
  def dispose; @actualBitmap.dispose; end
  def copy; @actualBitmap.clone; end
  def bitmap; @actualBitmap; end
  def bitmap=(val); @actualBitmap=val; end
  def each; end
  def alterBitmap(index); return @strip[index]; end
    
  def prepareStrip
    @strip=[]
    for i in 0...@totalFrames
      bitmap=Bitmap.new(@width,@height)
      bitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmapFile,Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale))
      @strip.push(bitmap)
    end
  end
  def compileStrip
    @bitmap.clear
    for i in 0...@strip.length
      @bitmap.stretch_blt(Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale),@strip[i],Rect.new(0,0,@width,@height))
    end
  end
  
  def reverse
    if @direction  >  0
      @direction=-1
    elsif @direction < 0
      @direction=+1
    end
  end
  
  def setLoop(start, finish)
    @loop_points=[start,finish]
  end
  
  def setSpeed(value)
    @speed=value
  end
  
  def toFrame(frame)
    if frame.is_a?(String)
      if frame=="last"
        frame=@totalFrames-1
      else
        frame=0
      end
    end
    frame=@totalFrames if frame > @totalFrames
    frame=0 if frame < 0
    @currentIndex=frame
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
  
  def play
    return if @currentIndex >= @loop_points[1]-1
    self.update
  end
  
  def finished?
    return (@currentIndex==@totalFrames-1)
  end
  
  def update
    return false if @actualBitmap.disposed?
    return false if @speed < 1
    case @speed
    # frame skip
    when 1
      @frames=2
    when 2
      @frames=4
    when 3
      @frames=5
    end
    @frame+=1
    if @frame >= @frames
      # processes animation speed
      @currentIndex+=@direction
      @currentIndex=@loop_points[0] if @currentIndex >=@loop_points[1]
      @currentIndex=@loop_points[1]-1 if @currentIndex < @loop_points[0]
      @frame=0
    end
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
    # updates the actual bitmap
  end
  alias update_elite update unless self.method_defined?(:update_elite)
    
  # returns bitmap to original state
  def deanimate
    @frame=0
    @currentIndex=0
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
end

#===============================================================================
#  New Sprite class to utilize the animated bitmap wrappers
#===============================================================================
class BitmapWrapperSprite < Sprite
  
  def setBitmap(file,scale=POKEMONSPRITESCALE)
    @animatedBitmap = AnimatedBitmapWrapper.new(file,scale)
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
  def setSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false)
    if species > 0
      pokemon = PokeBattle_Pokemon.new(species,5)
      @animatedBitmap = pbLoadPokemonBitmapSpecies(pokemon,species,back)
    else
      @animatedBitmap = AnimatedBitmapWrapper.new("Graphics/Battlers/000")
    end
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
  def play
    @animatedBitmap.play
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
  def finished?; return @animatedBitmap.finished?; end
  def animatedBitmap; return @animatedBitmap; end
  
  alias update_wrapper update unless self.method_defined?(:update_wrapper)
  def update
    update_wrapper
    return if @animatedBitmap.nil?
    @animatedBitmap.update
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
end

class AnimatedSpriteWrapper < BitmapWrapperSprite; end
#===============================================================================
#  Aliases old PokemonBitmap generating functions and creates new ones,
#  utilizing the new BitmapWrapper
#===============================================================================
alias pbLoadPokemonBitmap_ebs pbLoadPokemonBitmap unless defined?(:pbLoadPokemonBitmap_ebs)
def pbLoadPokemonBitmap(pokemon, back=false, scale=POKEMONSPRITESCALE)
  scale = back ? BACKSPRITESCALE : POKEMONSPRITESCALE
  return pbLoadPokemonBitmapSpecies(pokemon,pokemon.species,back,scale)
end

# Note: Returns an AnimatedBitmap, not a Bitmap
alias pbLoadPokemonBitmapSpecies_ebs pbLoadPokemonBitmapSpecies unless defined?(:pbLoadPokemonBitmapSpecies_ebs)
def pbLoadPokemonBitmapSpecies(pokemon, species, back=false, scale=POKEMONSPRITESCALE)
  scale = back ? BACKSPRITESCALE : POKEMONSPRITESCALE
  ret=nil
  
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  
  if pokemon.isEgg?
    bitmapFileName=sprintf("Graphics/Battlers/Eggs/%s",getConstantName(PBSpecies,species)) rescue nil
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=sprintf("Graphics/Battlers/Eggs/%03d",species)
      if !pbResolveBitmap(bitmapFileName) && pokemon.isShiny?
        bitmapFileName=sprintf("Graphics/Battlers/Eggs/000s")
      elsif !pbResolveBitmap(bitmapFileName)
        bitmapFileName=sprintf("Graphics/Battlers/Eggs/000")
      end
    end
    bitmapFileName=pbResolveBitmap(bitmapFileName)
  else
    bitmapFileName=pbCheckPokemonBitmapFiles([species,back,
                                              (pokemon.isFemale?),
                                               pokemon.isShiny?,
                                              (pokemon.form rescue 0),
                                              (pokemon.isShadow? rescue false)])    
  end
  #p missingPokeSpriteError(pokemon,back) if bitmapFileName.nil?
  
  bitmapFileName=sprintf("Graphics/Battlers/000") if bitmapFileName.nil?
  
  
  animatedBitmap=AnimatedBitmapWrapper.new(bitmapFileName,scale) if bitmapFileName
  ret=animatedBitmap if bitmapFileName
  # Full compatibility with the alterBitmap methods is maintained
  # but unless the alterBitmap method gets rewritten and sprite animations get
  # hardcoded in the system, the bitmap alterations will not function properly
  # as they will not account for the sprite animation itself
  
  # alterBitmap methods for static sprites will work just fine
  alterBitmap=(MultipleForms.getFunction(species,"alterBitmap") rescue nil) if !pokemon.isEgg? && animatedBitmap && animatedBitmap.totalFrames==1 # remove this totalFrames clause to allow for dynamic sprites too
  if bitmapFileName && alterBitmap
    animatedBitmap.prepareStrip
    for i in 0...animatedBitmap.totalFrames
      alterBitmap.call(pokemon,animatedBitmap.alterBitmap(i))
    end
    animatedBitmap.compileStrip
    ret=animatedBitmap
  end
  return ret
end

# Note: Returns an AnimatedBitmap, not a Bitmap
def pbLoadSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false,scale=POKEMONSPRITESCALE)
  ret = nil
  if egg
    bitmapFileName=sprintf("Graphics/Battlers/Eggs/%s",getConstantName(PBSpecies,species)) rescue nil
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=sprintf("Graphics/Battlers/Eggs/%03d",species)
      if !pbResolveBitmap(bitmapFileName)
        bitmapFileName=sprintf("Graphics/Battlers/Eggs/000")
      end
    end
    bitmapFileName=pbResolveBitmap(bitmapFileName)
  else
    bitmapFileName = pbCheckPokemonBitmapFiles([species,back,female,shiny,form,shadow])
  end

  if !bitmapFileName
    bitmapFileName=sprintf("Graphics/Battlers/Front/000")
  end
  
  if bitmapFileName
    ret = AnimatedBitmapWrapper.new(bitmapFileName,scale)
  end
  return ret
end

# returns error message upon missing sprites
def missingPokeSpriteError(pokemon,back)
  error_b = back ? "Back" : "Front"
  error_b += "Shiny"                  if pokemon.isShiny?
  error_b += "/Female/"               if pokemon.isFemale?
  error_b += " shadow"                if pokemon.isShadow?
  error_b += " form #{pokemon.form} " if pokemon.form > 0
  return "Woops, looks like you're missing the #{error_b} sprite for #{PBSpecies.getName(pokemon.species)}!" if $DEBUG
end

# new methods of handing Pokemon sprite name references
def pbCheckPokemonBitmapFiles(params)
  species = params[0]
  back    = params[1]
  factors = []
  factors.push([5,params[5],false])   if params[5] && params[5]!=false # shadow
  factors.push([2,params[2],false])   if params[2] && params[2]!=false # gender
  factors.push([3,params[3],false])   if params[3] && params[3]!=false # shiny
  factors.push([4,params[4].to_s,""]) if params[4] && params[4].to_s!="" && params[4].to_s!="0" # form
  factors.push([6,params[6],false])   if params[6] && params[6]!=false	# albino
  tshadow   = false
  tgender   = false
  tshiny    = false
  tform = ""
  for i in 0...2**factors.length
    for j in 0...factors.length
      case factors[j][0]
      when 2  # gender
        tgender   = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      when 3  # shiny
        tshiny    = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      when 4  # form
        tform     = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      when 5  # shadow
        tshadow   = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      end
    end
    folder = "Graphics/Battlers/"
    if tshiny && back
      folder += "BackShiny/"
    elsif tshiny
      folder += "FrontShiny/"
    elsif back
      folder += "Back/"
    else
      folder += "Front/"
    end
    folder += "Female/" if tgender
    bitmapFileName = sprintf("#{folder}%s%s%s",getConstantName(PBSpecies,species),(tform!="" ? "_"+tform : ""),tshadow ? "_shadow" : "") rescue nil
    ret = pbResolveBitmap(bitmapFileName)
    return ret if ret
    bitmapFileName = sprintf("#{folder}%03d%s%s",species,(tform!="" ? "_"+tform : ""),tshadow ? "_shadow" : "")
    ret = pbResolveBitmap(bitmapFileName)
    return ret if ret
  end
  return nil
end

def pbPokemonBitmapFile(species, shiny, back=false)
  folder = "Graphics/Battlers/"
  if shiny && back
    folder += "BackShiny/"
  elsif shiny
    folder += "FrontShiny/"
  elsif back
    folder += "Back/"
  else
    folder += "Front/"
  end
  name = sprintf("#{folder}%s",getConstantName(PBSpecies,species)) rescue nil
  
  ret = pbResolveBitmap(name)
  return ret if ret
  name = sprintf("#{folder}%03d",species)

  return pbResolveBitmap(name)
end

def pbLoadFakePokemonBitmap(species,boy=false,shiny=false,form=0, back=false)
  bitmapFileName=pbCheckPokemonBitmapFiles([species,back,
                                              boy,
                                              shiny,
                                              form,
                                              false])    
  animatedBitmap=AnimatedBitmapWrapper.new(bitmapFileName)
#  echo("#{bitmapFileName}")
  return animatedBitmap
end

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