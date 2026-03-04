# ELIMINA ESTE SCRIPT SI QUIERES USAR EL ANTIGUO FORMATO PARA CARPETAS Y 
# SIN SPRITES ANIMADOS
# used to scale the Pokemon bitmaps to 200%
POKEMONSPRITESCALE = 2
# used to scale the backsprite for battle perspective (200%)
BACKSPRITESCALE = 3

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
    @speed = (Graphics.frame_rate>=60) ? 3 : 2
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
    return false if @totalFrames == 1
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
#  BES-T Fix de Spinda con sprites animados
#===============================================================================
#  Corrige el problema de los patrones de Spinda
#  y añade soporte para crear otros pokémon con función similar.
#===============================================================================
# Función para verificar si un color está en la lista de colores objetivo
def isTargetColor(color, target_colors)
  target_colors.each do |target|
    if color.red == target[0] && color.green == target[1] && color.blue == target[2]
      return true
    end
  end
  return false
end

def drawSpotUniversal(bitmap, spotpattern, x, y, red, green, blue, target_colors = nil)
  target_colors ||= [
    [230, 213, 164], 
    [205, 164, 115],  
    [116, 80, 63], 
    [156, 131, 90]
  ]
  
  height = spotpattern.length
  width = spotpattern[0].length
  is_large_sprite = bitmap.height >= 200
  scale_factor = is_large_sprite ? 3 : 2
  
  (0...height).each do |yy|
    spot = spotpattern[yy]
    (0...width).each do |xx|
      next unless spot[xx] == 1
      
      base_x = x + xx
      base_y = y + yy
      
      if is_large_sprite
        xOrg = base_x * scale_factor
        yOrg = base_y * scale_factor
        next if xOrg >= bitmap.width || yOrg >= bitmap.height
      else
        xOrg = base_x << 1
        yOrg = base_y << 1
      end
      
      color = bitmap.get_pixel(xOrg, yOrg)
      next unless isTargetColor(color, target_colors)
      
      # Modificar color
      color.red = [[color.red + red, 0].max, 255].min
      color.green = [[color.green + green, 0].max, 255].min
      color.blue = [[color.blue + blue, 0].max, 255].min
      
      # Aplicar color a área escalada
      (0...scale_factor).each do |dy|
        (0...scale_factor).each do |dx|
          pixel_x = xOrg + dx
          pixel_y = yOrg + dy
          if pixel_x < bitmap.width && pixel_y < bitmap.height
            bitmap.set_pixel(pixel_x, pixel_y, color)
          end
        end
      end
    end
  end
end

# CODIGO DE SPINDA FIXEADO
def pbSpindaSpots(pokemon,bitmap)
  # Colores por defecto si no se especifican
  target_colors = [
    [230, 213, 164], 
    [205, 164, 115],  
    [116, 80, 63], 
    [156, 131, 90], 
  ]

  # Colores de las manchas
  sR = 0;sG = -115; sB = -75
  if pokemon.isShiny?
    sR = -75;sG = -10; sB = -150
  end
  
  spot1=[
     [0,0,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,0,0]
  ]
  spot2=[
     [0,0,1,1,1,0,0],
     [0,1,1,1,1,1,0],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [0,1,1,1,1,1,0],
     [0,0,1,1,1,0,0]
  ]
  spot3=[
     [0,0,0,0,0,1,1,1,1,0,0,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,0,0,0,1,1,1,0,0,0,0,0]
  ]
  spot4=[
     [0,0,0,0,1,1,1,0,0,0,0,0],
     [0,0,1,1,1,1,1,1,1,0,0,0],
     [0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,0,1,1,1,1,1,0,0,0]
  ]
  
  id=pokemon.personalID
  h=(id>>28)&15; g=(id>>24)&15; f=(id>>20)&15; 
  e=(id>>16)&15; d=(id>>12)&15; c=(id>>8)&15; 
  b=(id>>4)&15; a=(id)&15; 
  
  # Detectar si es sprite grande para ajustar posiciones (240x240 desde base 80x80)
  is_large_sprite = bitmap.width >= 200 || bitmap.height >= 200
  unless is_large_sprite
    drawSpotUniversal(bitmap,spot1,b+34,a+26,sR,sG,sB,target_colors)
    drawSpotUniversal(bitmap,spot2,d+22,c+24,sR,sG,sB,target_colors)
    drawSpotUniversal(bitmap,spot3,f+40,e+8,sR,sG,sB,target_colors)
    drawSpotUniversal(bitmap,spot4,h+16,g+6,sR,sG,sB,target_colors)  
  else  
    # Offset adicional para sprites grandes
    base_offset_x = 0  # Movido más a la izquierda
    base_offset_y = 10 #26   # Ajusta según necesites
    drawSpotUniversal(bitmap,spot1,(b+34)+base_offset_x,(a+26)+base_offset_y,sR,sG,sB,target_colors)
    drawSpotUniversal(bitmap,spot2,(d+22)+base_offset_x,(c+24)+base_offset_y,sR,sG,sB,target_colors)
    drawSpotUniversal(bitmap,spot3,(f+40)+base_offset_x,(e+8)+base_offset_y,sR,sG,sB,target_colors)
    drawSpotUniversal(bitmap,spot4,(h+16)+base_offset_x,(g+6)+base_offset_y,sR,sG,sB,target_colors)
  end
end

################################################################################
# Ejemplo del nuevo sistema con otros pokémon. 
# En el array debes colocar otros array con los colores SOBRE los que quieres que dibuje los puntos.
################################################################################

=begin
MultipleForms.register(:TUPOKE,{
"alterBitmap"=>proc{|pokemon,bitmap|
   pbCustomPokemonSpots(pokemon, bitmap, [
      [126, 210, 252], # #7ed2fc - azul claro
      [93, 168, 202],  # #5da8ca - azul medio  
      [1, 103, 135]    # azul oscuro
    ])
}
})
=end