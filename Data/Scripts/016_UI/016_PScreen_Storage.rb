class PokemonBox
  attr_reader :pokemon
  attr_accessor :name
  attr_accessor :background

  def initialize(name,maxPokemon=30)
    @pokemon = []
    @name = name
    @background = 0
    for i in 0...maxPokemon
      @pokemon[i] = nil
    end
  end

  def length
    return @pokemon.length
  end

  def nitems
    return @pokemon.nitems
  end

  def full?
    return (@pokemon.nitems==self.length)
  end

  def empty?
    return (@pokemon.nitems==0)
  end

  def [](i)
    return @pokemon[i]
  end

  def []=(i,value)
    @pokemon[i] = value
  end

  def each
    @pokemon.each{|item| yield item}
  end

  def clear
    @pokemon.clear
  end
end



class PokemonStorage
  attr_reader :boxes
  attr_accessor :currentBox
  attr_writer :unlockedWallpapers
  BASICWALLPAPERQTY = 16

  def initialize(maxBoxes=STORAGEBOXES,maxPokemon=30)
    @boxes = []
    for i in 0...maxBoxes
      @boxes[i] = PokemonBox.new(_INTL("Caja {1}",i+1),maxPokemon)
      @boxes[i].background = i%BASICWALLPAPERQTY
    end
    @currentBox = 0
    @boxmode = -1
    @unlockedWallpapers = []
    for i in 0...allWallpapers.length
      @unlockedWallpapers[i] = false
    end
  end

  def allWallpapers
    return [
       # Basic wallpapers
       _INTL("Bosque"),_INTL("Ciudad"),_INTL("Desierto"),_INTL("Sabana"),
       _INTL("Montaña"),_INTL("Volcán"),_INTL("Nieve"),_INTL("Cueva"),
       _INTL("Playa"),_INTL("Mar"),_INTL("Río"),_INTL("Cielo"),
       _INTL("Centro Pokémon"),_INTL("Máquina"),_INTL("Losas"),_INTL("Sencillo"),
       # Special wallpapers
       _INTL("Espacio"),_INTL("Backyard"),_INTL("Nostalgico 1"),_INTL("Torchic"),
       _INTL("Trio 1"),_INTL("PikaPika 1"),_INTL("Leyenda 1"),_INTL("Equipo Galaxia 1"),
       _INTL("Distorsión"),_INTL("Concurso"),_INTL("Nostalgic 2"),_INTL("Croagunk"),
       _INTL("Trio 2"),_INTL("PikaPika 2"),_INTL("Leyenda 2"),_INTL("Equipo Galaxia 2"),
       _INTL("Corazón"),_INTL("Plata"),_INTL("Hermano Mayor"),_INTL("Pokéathlon"),
       _INTL("Trio 3"),_INTL("Pikoreja"),_INTL("Chica Kimono"),_INTL("Rocket")
    ]
  end

  def unlockedWallpapers
    @unlockedWallpapers = [] if !@unlockedWallpapers
    return @unlockedWallpapers
  end

  def availableWallpapers
    ret = [[],[]]   # Names, IDs
    papers = allWallpapers
    @unlockedWallpapers = [] if !@unlockedWallpapers
    for i in 0...papers.length
      next if !isAvailableWallpaper(i)
      ret[0].push(papers[i]); ret[1].push(i)
    end
    return ret
  end

  def isAvailableWallpaper(i)
    @unlockedWallpapers = [] if !@unlockedWallpapers
    return true if i<BASICWALLPAPERQTY
    return true if @unlockedWallpapers[i]
    return false
  end

  def party
    $Trainer.party
  end

  def party=(value)
    raise ArgumentError.new("Not supported")
  end

  MARKINGCHARS=["●","■","▲","♥"]

  def maxBoxes
    return @boxes.length
  end

  def maxPokemon(box)
    return 0 if box>=self.maxBoxes
    return (box<0) ? 6 : self[box].length
  end

  def full?
    for i in 0...self.maxBoxes
      return false if !@boxes[i].full?
    end
    return true
  end

  def pbFirstFreePos(box)
    if box==-1
      ret = self.party.nitems
      return (ret==6) ? -1 : ret
    else
      for i in 0...maxPokemon(box)
        return i if !self[box,i]
      end
      return -1
    end
  end

  def [](x,y=nil)
    if y==nil
      return (x==-1) ? self.party : @boxes[x]
    else
      for i in @boxes
        raise "Box is a Pokémon, not a box" if i.is_a?(PokeBattle_Pokemon)
      end
      return (x==-1) ? self.party[y] : @boxes[x][y]
    end
  end

  def []=(x,y,value)
    if x==-1
      self.party[y] = value
    else
      @boxes[x][y] = value
    end
  end

  def pbCopy(boxDst,indexDst,boxSrc,indexSrc)
    if indexDst<0 && boxDst<self.maxBoxes
      found = false
      for i in 0...maxPokemon(boxDst)
        if !self[boxDst,i]
          found = true
          indexDst = i
          break
        end
      end
      return false if !found
    end
    if boxDst==-1
      return false if self.party.nitems>=6
      self.party[self.party.length] = self[boxSrc,indexSrc]
      self.party.compact!
    else
      pkmn = self[boxSrc,indexSrc]
      if !pkmn
        raise "Trying to copy nil to storage"
      end
      pkmn.heal
      pkmn.formTime = nil if pkmn.respond_to?("formTime") && pkmn.formTime
      self[boxDst,indexDst] = pkmn
    end
    return true
  end

  def pbMove(boxDst,indexDst,boxSrc,indexSrc)
    return false if !pbCopy(boxDst,indexDst,boxSrc,indexSrc)
    pbDelete(boxSrc,indexSrc)
    return true
  end

  def pbMoveCaughtToParty(pkmn)
    return false if self.party.nitems>=6
    self.party[self.party.length] = pkmn
  end

  def pbMoveCaughtToBox(pkmn,box)
    for i in 0...maxPokemon(box)
      if self[box,i]==nil
        if box>=0
          pkmn.heal
          pkmn.formTime = nil if pkmn.respond_to?("formTime") && pkmn.formTime
        end
        self[box,i] = pkmn
        return true
      end
    end
    return false
  end

  def pbStoreCaught(pkmn)
    for i in 0...maxPokemon(@currentBox)
      if self[@currentBox,i]==nil
        self[@currentBox,i] = pkmn
        return @currentBox
      end
    end
    for j in 0...self.maxBoxes
      for i in 0...maxPokemon(j)
        if self[j,i]==nil
          self[j,i] = pkmn
          @currentBox = j
          return @currentBox
        end
      end
    end
    return -1
  end

  def pbDelete(box,index)
    if self[box,index]
      self[box,index] = nil
      self.party.compact! if box==-1
    end
  end

  def clear
    for i in 0...self.maxBoxes
      @boxes[i].clear
    end
  end
end

#===============================================================================
# Regional Storage scripts
#===============================================================================
class RegionalStorage
  def initialize
    @storages = []
    @lastmap = -1
    @rgnmap = -1
  end

  def getCurrentStorage
    if !$game_map
      raise _INTL("The player is not on a map, so the region could not be determined.")
    end
    if @lastmap!=$game_map.map_id
      @rgnmap = pbGetCurrentRegion # may access file IO, so caching result
      @lastmap = $game_map.map_id
    end
    if @rgnmap<0
      raise _INTL("The current map has no region set. Please set the MapPosition metadata setting for this map.")
    end
    if !@storages[@rgnmap]
      @storages[@rgnmap] = PokemonStorage.new
    end
    return @storages[@rgnmap]
  end

  def allWallpapers
    return getCurrentStorage.allWallpapers
  end

  def availableWallpapers
    return getCurrentStorage.availableWallpapers
  end

  def unlockWallpaper(index)
    getCurrentStorage.unlockWallpaper(index)
  end

  def boxes
    return getCurrentStorage.boxes
  end

  def party
    return getCurrentStorage.party
  end

  def maxBoxes
    return getCurrentStorage.maxBoxes
  end

  def maxPokemon(box)
    return getCurrentStorage.maxPokemon(box)
  end

  def full?
    getCurrentStorage.full?
  end

  def currentBox
    return getCurrentStorage.currentBox
  end

  def currentBox=(value)
    getCurrentStorage.currentBox = value
  end

  def [](x,y=nil)
    getCurrentStorage[x,y]
  end

  def []=(x,y,value)
    getCurrentStorage[x,y] = value
  end

  def pbFirstFreePos(box)
    getCurrentStorage.pbFirstFreePos(box)
  end

  def pbCopy(boxDst,indexDst,boxSrc,indexSrc)
    getCurrentStorage.pbCopy(boxDst,indexDst,boxSrc,indexSrc)
  end

  def pbMove(boxDst,indexDst,boxSrc,indexSrc)
    getCurrentStorage.pbCopy(boxDst,indexDst,boxSrc,indexSrc)
  end

  def pbMoveCaughtToParty(pkmn)
    getCurrentStorage.pbMoveCaughtToParty(pkmn)
  end

  def pbMoveCaughtToBox(pkmn,box)
    getCurrentStorage.pbMoveCaughtToBox(pkmn,box)
  end

  def pbStoreCaught(pkmn)
    getCurrentStorage.pbStoreCaught(pkmn)
  end

  def pbDelete(box,index)
    getCurrentStorage.pbDelete(pkmn)
  end
end

#===============================================================================
#
#===============================================================================

def pbUnlockWallpaper(index)
  $PokemonStorage.unlockedWallpapers[index] = true
end

def pbLockWallpaper(index)   # Don't know why you'd want to do this
  $PokemonStorage.unlockedWallpapers[index] = false
end

class Interpolator
  ZOOM_X  = 1
  ZOOM_Y  = 2
  X       = 3
  Y       = 4
  OPACITY = 5
  COLOR   = 6
  WAIT    = 7

  def initialize
    @tweening=false
    @tweensteps=[]
    @sprite=nil
    @frames=0
    @step=0
  end

  def tweening?
    return @tweening
  end

  def tween(sprite,items,frames)
    @tweensteps=[]
    if sprite && !sprite.disposed? && frames>0
      @frames=frames
      @step=0
      @sprite=sprite
      for item in items
        case item[0]
        when ZOOM_X
          @tweensteps[item[0]]=[sprite.zoom_x,item[1]-sprite.zoom_x]
        when ZOOM_Y
          @tweensteps[item[0]]=[sprite.zoom_y,item[1]-sprite.zoom_y]
        when X
          @tweensteps[item[0]]=[sprite.x,item[1]-sprite.x]
        when Y
          @tweensteps[item[0]]=[sprite.y,item[1]-sprite.y]
        when OPACITY
          @tweensteps[item[0]]=[sprite.opacity,item[1]-sprite.opacity]
        when COLOR
          @tweensteps[item[0]]=[sprite.color.clone,Color.new(
             item[1].red-sprite.color.red,
             item[1].green-sprite.color.green,
             item[1].blue-sprite.color.blue,
             item[1].alpha-sprite.color.alpha
          )]
        end
      end
      @tweening=true
    end
  end

  def update
    if @tweening
      t=(@step*1.0)/@frames
      for i in 0...@tweensteps.length
        item=@tweensteps[i]
        next if !item
        case i
        when ZOOM_X
          @sprite.zoom_x=item[0]+item[1]*t
        when ZOOM_Y
          @sprite.zoom_y=item[0]+item[1]*t
        when X
          @sprite.x=item[0]+item[1]*t
        when Y
          @sprite.y=item[0]+item[1]*t
        when OPACITY
          @sprite.opacity=item[0]+item[1]*t
        when COLOR
          @sprite.color=Color.new(
             item[0].red+item[1].red*t,
             item[0].green+item[1].green*t,
             item[0].blue+item[1].blue*t,
             item[0].alpha+item[1].alpha*t
          )
        end
      end
      @step+=1
      if @step==@frames
        @step=0
        @frames=0
        @tweening=false
      end
    end
  end
end

#===============================================================================
# Pokémon icons
#===============================================================================
class PokemonBoxIcon < IconSprite
  def initialize(pokemon,viewport=nil)
    super(0,0,viewport)
    @pokemon = pokemon
    @release = Interpolator.new
    @startRelease = false
    refresh
  end

  def releasing?
    return @release.tweening?
  end

  def release
    self.ox = self.src_rect.width/2   # 32
    self.oy = self.src_rect.height/2   # 32
    self.x += self.src_rect.width/2   # 32
    self.y += self.src_rect.height/2   # 32
    @release.tween(self,[
       [Interpolator::ZOOM_X,0],
       [Interpolator::ZOOM_Y,0],
       [Interpolator::OPACITY,0]
    ],100)
    @startRelease = true
  end

  def refresh
    return if !@pokemon
    self.setBitmap(pbPokemonIconFile(@pokemon))
    self.src_rect = Rect.new(0,0,self.bitmap.height,self.bitmap.height)
  end

  def update
    super
    @release.update
    self.color = Color.new(0,0,0,0)
    dispose if @startRelease && !releasing?
  end
end



#===============================================================================
# Pokémon sprite
#===============================================================================
class MosaicPokemonSprite < PokemonSprite
  attr_reader :mosaic

  def initialize(*args)
    super(*args)
    @mosaic = 0
    @inrefresh = false
    @mosaicbitmap = nil
    @mosaicbitmap2 = nil
    @oldbitmap = self.bitmap
  end

  def dispose
    super
    @mosaicbitmap.dispose if @mosaicbitmap
    @mosaicbitmap = nil
    @mosaicbitmap2.dispose if @mosaicbitmap2
    @mosaicbitmap2 = nil
  end

  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic<0
    mosaicRefresh(@oldbitmap)
  end

  def bitmap=(value)
    super
    mosaicRefresh(value)
  end

  def mosaicRefresh(bitmap)
    return if @inrefresh
    @inrefresh = true
    @oldbitmap = bitmap
    if @mosaic<=0 || !@oldbitmap
      @mosaicbitmap.dispose if @mosaicbitmap
      @mosaicbitmap = nil
      @mosaicbitmap2.dispose if @mosaicbitmap2
      @mosaicbitmap2 = nil
      self.bitmap = @oldbitmap
    else
      newWidth  = [(@oldbitmap.width/@mosaic),1].max
      newHeight = [(@oldbitmap.height/@mosaic),1].max
      @mosaicbitmap2.dispose if @mosaicbitmap2
      @mosaicbitmap = pbDoEnsureBitmap(@mosaicbitmap,newWidth,newHeight)
      @mosaicbitmap.clear
      @mosaicbitmap2 = pbDoEnsureBitmap(@mosaicbitmap2,@oldbitmap.width,@oldbitmap.height)
      @mosaicbitmap2.clear
      @mosaicbitmap.stretch_blt(Rect.new(0,0,newWidth,newHeight),@oldbitmap,@oldbitmap.rect)
      @mosaicbitmap2.stretch_blt(
         Rect.new(-@mosaic/2+1,-@mosaic/2+1,
         @mosaicbitmap2.width,@mosaicbitmap2.height),
         @mosaicbitmap,Rect.new(0,0,newWidth,newHeight))
      self.bitmap = @mosaicbitmap2
    end
    @inrefresh = false
  end
end



class AutoMosaicPokemonSprite < MosaicPokemonSprite
  def update
    super
    self.mosaic -= 1
  end
end



#===============================================================================
# Cursor
#===============================================================================
class PokemonBoxArrow < SpriteWrapper
  attr_accessor :quickswap

  def initialize(viewport=nil)
    super(viewport)
    @frame = 0
    @holding = false
    @updating = false
    @quickswap = false
    @grabbingState = 0
    @placingState = 0
    @heldpkmn = nil
    @handsprite = ChangelingSprite.new(0,0,viewport)
    @handsprite.addBitmap("point1","Graphics/#{STORAGE_ROUTE}/cursor_point_1")
    @handsprite.addBitmap("point2","Graphics/#{STORAGE_ROUTE}/cursor_point_2")
    @handsprite.addBitmap("grab","Graphics/#{STORAGE_ROUTE}/cursor_grab")
    @handsprite.addBitmap("fist","Graphics/#{STORAGE_ROUTE}/cursor_fist")
    @handsprite.addBitmap("point1q","Graphics/#{STORAGE_ROUTE}/cursor_point_1_q")
    @handsprite.addBitmap("point2q","Graphics/#{STORAGE_ROUTE}/cursor_point_2_q")
    @handsprite.addBitmap("grabq","Graphics/#{STORAGE_ROUTE}/cursor_grab_q")
    @handsprite.addBitmap("fistq","Graphics/#{STORAGE_ROUTE}/cursor_fist_q")
    @handsprite.changeBitmap("fist")
    @spriteX = self.x
    @spriteY = self.y
  end

  def dispose
    @handsprite.dispose
    @heldpkmn.dispose if @heldpkmn
    super
  end

  def heldPokemon
    @heldpkmn = nil if @heldpkmn && @heldpkmn.disposed?
    @holding = false if !@heldpkmn
    return @heldpkmn
  end

  def visible=(value)
    super
    @handsprite.visible = value
    sprite = heldPokemon
    sprite.visible = value if sprite
  end

  def color=(value)
    super
    @handsprite.color = value
    sprite = heldPokemon
    sprite.color = value if sprite
  end

  def holding?
    return self.heldPokemon && @holding
  end

  def grabbing?
    return @grabbingState>0
  end

  def placing?
    return @placingState>0
  end

  def x=(value)
    super
    @handsprite.x = self.x
    @spriteX = x if !@updating
    heldPokemon.x = self.x if holding?
  end

  def y=(value)
    super
    @handsprite.y = self.y
    @spriteY = y if !@updating
    heldPokemon.y = self.y+16 if holding?
  end

  def z=(value)
    super
    @handsprite.z = value
  end

  def setSprite(sprite)
    if holding?
      @heldpkmn = sprite
      @heldpkmn.viewport = self.viewport if @heldpkmn
      @heldpkmn.z = 1 if @heldpkmn
      @holding = false if !@heldpkmn
      self.z = 2
    end
  end

  def deleteSprite
    @holding = false
    if @heldpkmn
      @heldpkmn.dispose
      @heldpkmn = nil
    end
  end

  def grab(sprite)
    @grabbingState = 1
    @heldpkmn = sprite
    @heldpkmn.viewport = self.viewport
    @heldpkmn.z = 1
    self.z = 2
  end

  def place
    @placingState = 1
  end

  def release
    @heldpkmn.release if @heldpkmn
  end

  def update
    @updating = true
    super
    heldpkmn = heldPokemon
    heldpkmn.update if heldpkmn
    @handsprite.update
    @holding = false if !heldpkmn
    if @grabbingState>0
      if @grabbingState<=8
        @handsprite.changeBitmap((@quickswap) ? "grabq" : "grab")
        self.y = @spriteY+(@grabbingState)*2
        @grabbingState += 1
      elsif @grabbingState<=16
        @holding = true
        @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
        self.y = @spriteY+(16-@grabbingState)*2
        @grabbingState += 1
      else
        @grabbingState = 0
      end
    elsif @placingState>0
      if @placingState<=8
        @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
        self.y = @spriteY+(@placingState)*2
        @placingState += 1
      elsif @placingState<=16
        @holding = false
        @heldpkmn = nil
        @handsprite.changeBitmap((@quickswap) ? "grabq" : "grab")
        self.y = @spriteY+(16-@placingState)*2
        @placingState += 1
      else
        @placingState = 0
      end
    elsif holding?
      @handsprite.changeBitmap((@quickswap) ? "fistq" : "fist")
    else
      self.x = @spriteX
      self.y = @spriteY
      if (@frame/20)==0
        @handsprite.changeBitmap((@quickswap) ? "point1q" : "point1")
      else
        @handsprite.changeBitmap((@quickswap) ? "point2q" : "point2")
      end
    end
    @frame += 1
    @frame = 0 if @frame==40
    @updating = false
  end
end



#===============================================================================
# Box
#===============================================================================
class PokemonBoxSprite < SpriteWrapper
  attr_accessor :refreshBox
  attr_accessor :refreshSprites
  def initialize(storage,boxnumber,viewport=nil)
    super(viewport)
    @storage = storage
    @boxnumber = boxnumber
    @refreshBox = true
    @refreshSprites = true
    @pokemonsprites = []
    for i in 0...30
      @pokemonsprites[i] = nil
      pokemon = @storage[boxnumber,i]
      @pokemonsprites[i] = PokemonBoxIcon.new(pokemon,viewport)
    end
    @contents = BitmapWrapper.new(324,296)
    self.bitmap = @contents
    self.x = 184
    self.y = 18
    refresh
  end

  def dispose
    if !disposed?
      for i in 0...30
        @pokemonsprites[i].dispose if @pokemonsprites[i]
        @pokemonsprites[i] = nil
      end
      @boxbitmap.dispose
      @contents.dispose
      super
    end
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    if @refreshSprites
      for i in 0...30
        if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
          @pokemonsprites[i].color = value
        end
      end
    end
    refresh
  end

  def visible=(value)
    super
    for i in 0...30
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
    refresh
  end

  def getBoxBitmap
    if !@bg || @bg!=@storage[@boxnumber].background
      curbg = @storage[@boxnumber].background
      if !curbg || (curbg.is_a?(String) && curbg.length==0)
        @bg = @boxnumber%PokemonStorage::BASICWALLPAPERQTY
      else
        if curbg.is_a?(String) && curbg[/^box(\d+)$/]
          curbg = $~[1].to_i
          @storage[@boxnumber].background = curbg
        end
        @bg = curbg
      end
      if !@storage.isAvailableWallpaper(@bg)
        @bg = @boxnumber%PokemonStorage::BASICWALLPAPERQTY
        @storage[@boxnumber].background = @bg
      end
      @boxbitmap.dispose if @boxbitmap
      @boxbitmap = AnimatedBitmap.new("Graphics/#{STORAGE_ROUTE}/box#{@bg}")
    end
  end

  def getPokemon(index)
    return @pokemonsprites[index]
  end

  def setPokemon(index,sprite)
    @pokemonsprites[index] = sprite
    refresh
  end

  def grabPokemon(index,arrow)
    sprite = @pokemonsprites[index]
    if sprite
      arrow.grab(sprite)
      @pokemonsprites[index] = nil
      refresh
    end
  end

  def deletePokemon(index)
    @pokemonsprites[index].dispose
    @pokemonsprites[index] = nil
    refresh
  end

  def refresh
    if @refreshBox
      boxname = @storage[@boxnumber].name
      getBoxBitmap
      @contents.blt(0,0,@boxbitmap.bitmap,Rect.new(0,0,324,296))
      pbSetSystemFont(@contents)
      widthval = @contents.text_size(boxname).width
      xval = 162-(widthval/2)
      pbDrawShadowText(@contents,xval,8,widthval,32,boxname,Color.new(248,248,248),Color.new(40,48,48))
      @refreshBox = false
    end
    yval = self.y+30
    for j in 0...5
      xval = self.x+10
      for k in 0...6
        sprite = @pokemonsprites[j*6+k]
        if sprite && !sprite.disposed?
          sprite.viewport = self.viewport
          sprite.x = xval
          sprite.y = yval
          sprite.z = 0
        end
        xval += 48
      end
      yval += 48
    end
  end

  def update
    super
    for i in 0...30
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].update
      end
    end
  end
end



#===============================================================================
# Party pop-up panel
#===============================================================================
class PokemonBoxPartySprite < SpriteWrapper
  def initialize(party,viewport=nil)
    super(viewport)
    @party = party
    @boxbitmap = AnimatedBitmap.new("Graphics/#{STORAGE_ROUTE}/boxpartytab")
    @pokemonsprites = []
    for i in 0...6
      @pokemonsprites[i] = nil
      pokemon = @party[i]
      if pokemon
        @pokemonsprites[i] = PokemonBoxIcon.new(pokemon,viewport)
      end
    end
    @contents = BitmapWrapper.new(172,352)
    self.bitmap = @contents
    self.x = 182
    self.y = Graphics.height-352
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def dispose
    for i in 0...6
      @pokemonsprites[i].dispose if @pokemonsprites[i]
    end
    @boxbitmap.dispose
    @contents.dispose
    super
  end

  def x=(value)
    super
    refresh
  end

  def y=(value)
    super
    refresh
  end

  def color=(value)
    super
    for i in 0...6
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].color = pbSrcOver(@pokemonsprites[i].color,value)
      end
    end
  end

  def visible=(value)
    super
    for i in 0...6
      if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
        @pokemonsprites[i].visible = value
      end
    end
  end

  def getPokemon(index)
    return @pokemonsprites[index]
  end

  def setPokemon(index,sprite)
    @pokemonsprites[index] = sprite
    @pokemonsprites.compact!
    refresh
  end

  def grabPokemon(index,arrow)
    sprite = @pokemonsprites[index]
    if sprite
      arrow.grab(sprite)
      @pokemonsprites[index] = nil
      @pokemonsprites.compact!
      refresh
    end
  end

  def deletePokemon(index)
    @pokemonsprites[index].dispose
    @pokemonsprites[index] = nil
    @pokemonsprites.compact!
    refresh
  end

  def refresh
    @contents.blt(0,0,@boxbitmap.bitmap,Rect.new(0,0,172,352))
    pbDrawTextPositions(self.bitmap,[
       [_INTL("Salir"),86,242,2,Color.new(248,248,248),Color.new(80,80,80),1]
    ])

    xvalues = [18,90,18,90,18,90]
    yvalues = [2,18,66,82,130,146]
    for j in 0...6
      @pokemonsprites[j] = nil if @pokemonsprites[j] && @pokemonsprites[j].disposed?
    end
    @pokemonsprites.compact!
    for j in 0...6
      sprite = @pokemonsprites[j]
      if sprite && !sprite.disposed?
        sprite.viewport = self.viewport
        sprite.x = self.x+xvalues[j]
        sprite.y = self.y+yvalues[j]
        sprite.z = 0
      end
    end
  end

  def update
    super
    for i in 0...6
      @pokemonsprites[i].update if @pokemonsprites[i] && !@pokemonsprites[i].disposed?
    end
  end
end



#===============================================================================
# Pokémon storage visuals
#===============================================================================
class PokemonStorageScene
  attr_reader :quickswap

  def initialize
    @command = 1
  end

  def pbStartBox(screen,command)
    @screen = screen
    @storage = screen.storage
    @bgviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @bgviewport.z = 99999
    @boxviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @boxviewport.z = 99999
    @boxsidesviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @boxsidesviewport.z = 99999
    @arrowviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @arrowviewport.z = 99999
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @selection = 0
    @quickswap = false
    @sprites = {}
    @choseFromParty = false
    @command = command
    @sprites["background"] = IconSprite.new(0,0,@bgviewport)
    @sprites["background"].setBitmap("Graphics/#{STORAGE_ROUTE}/boxbg")

    @sprites["box"] = PokemonBoxSprite.new(@storage,@storage.currentBox,@boxviewport)
    @sprites["boxsides"] = IconSprite.new(0,0,@boxsidesviewport)
    @sprites["boxsides"].setBitmap("Graphics/#{STORAGE_ROUTE}/boxsides")
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@boxsidesviewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["pokemon"] = AutoMosaicPokemonSprite.new(@boxsidesviewport)
    #@sprites["pokemon"].setOffset(PictureOrigin::Center)
    #@sprites["pokemon"].x = 90
    #@sprites["pokemon"].y = 134
    @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party,@boxsidesviewport)
    if command!=2 # Drop down tab only on Deposit
      @sprites["boxparty"].x = 182
      @sprites["boxparty"].y = Graphics.height
    end
    @sprites["arrow"] = PokemonBoxArrow.new(@arrowviewport)
    @sprites["arrow"].z += 1
    if command!=2
      pbSetArrow(@sprites["arrow"],@selection)
      pbUpdateOverlay(@selection)
      pbSetMosaic(@selection)
    else
      pbPartySetArrow(@sprites["arrow"],@selection)
      pbUpdateOverlay(@selection,@storage.party)
      pbSetMosaic(@selection)
    end
    pbFadeInAndShow(@sprites)
  end

  def pbCloseBox
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @boxviewport.dispose
    @boxsidesviewport.dispose
    @arrowviewport.dispose
  end

  def pbDisplay(message)
    msgwindow = Window_UnformattedTextPokemon.newWithSize("",180,0,Graphics.width-180,32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.resizeHeightToFit(message,Graphics.width-180)
    msgwindow.text           = message
    pbBottomRight(msgwindow)
    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        break
      end
      msgwindow.update
      self.update
    end
    msgwindow.dispose
    Input.update
  end

  def pbShowCommands(message,commands,index=0)
    ret = 0
    msgwindow = Window_UnformattedTextPokemon.newWithSize("",180,0,Graphics.width-180,32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.text           = message
    msgwindow.resizeHeightToFit(message,Graphics.width-180)
    pbBottomRight(msgwindow)
    cmdwindow = Window_CommandPokemon.new(commands)
    cmdwindow.viewport = @viewport
    cmdwindow.visible  = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    cmdwindow.height   = Graphics.height-msgwindow.height if cmdwindow.height>Graphics.height-msgwindow.height
    pbBottomRight(cmdwindow)
    cmdwindow.y        -= msgwindow.height
    cmdwindow.index    = index
    loop do
      Graphics.update
      Input.update
      msgwindow.update
      cmdwindow.update
      if Input.trigger?(Input::B)
        ret = -1
        break
      elsif Input.trigger?(Input::C)
        ret = cmdwindow.index
        break
      end
      self.update
    end
    msgwindow.dispose
    cmdwindow.dispose
    Input.update
    return ret
  end

  def pbSetArrow(arrow,selection)
    case selection
    when -1, -4, -5 # Box name, move left, move right
      arrow.x = 157*2
      arrow.y = -12*2
    when -2 # Party Pokémon
      arrow.x = 119*2
      arrow.y = 139*2
    when -3 # Close Box
      arrow.x = 207*2
      arrow.y = 139*2
    else
      arrow.x = (97+24*(selection%6))*2
      arrow.y = (8+24*(selection/6))*2
    end
  end

  def pbChangeSelection(key,selection)
    case key
    when Input::UP
      if selection==-1 # Box name
        selection = -2
      elsif selection==-2 # Party
        selection = 25
      elsif selection==-3 # Close Box
        selection = 28
      else
        selection -= 6
        selection = -1 if selection<0
      end
    when Input::DOWN
      if selection==-1 # Box name
        selection = 2
      elsif selection==-2 # Party
        selection = -1
      elsif selection==-3 # Close Box
        selection = -1
      else
        selection += 6
        selection = -2 if selection==30 || selection==31 || selection==32
        selection = -3 if selection==33 || selection==34 || selection==35
      end
    when Input::LEFT
      if selection==-1 # Box name
        selection = -4 # Move to previous box
      elsif selection==-2
        selection = -3
      elsif selection==-3
        selection = -2
      else
        selection -= 1
        selection += 6 if selection==-1 || selection%6==5
      end
    when Input::RIGHT
      if selection==-1 # Box name
        selection = -5 # Move to next box
      elsif selection==-2
        selection = -3
      elsif selection==-3
        selection = -2
      else
        selection += 1
        selection -= 6 if selection%6==0
      end
    end
    return selection
  end

  def pbPartySetArrow(arrow,selection)
    if selection>=0
      xvalues = [100,136,100,136,100,136,118]
      yvalues = [1,9,33,41,65,73,110]
      arrow.angle = 0
      arrow.mirror = false
      arrow.ox = 0
      arrow.oy = 0
      arrow.x = xvalues[selection]*2
      arrow.y = yvalues[selection]*2
    end
  end

  def pbPartyChangeSelection(key,selection)
    case key
    when Input::LEFT
      selection -= 1
      selection = 6 if selection<0
    when Input::RIGHT
      selection += 1
      selection = 0 if selection>6
    when Input::UP
      if selection==6
        selection = 5
      else
        selection -= 2
        selection = 6 if selection<0
      end
    when Input::DOWN
      if selection==6
        selection = 0
      else
        selection += 2
        selection = 6 if selection>6
      end
    end
    return selection
  end

  def pbSelectBoxInternal(party)
    selection = @selection
    pbSetArrow(@sprites["arrow"],selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    loop do
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key>=0
        pbPlayCursorSE
        selection = pbChangeSelection(key,selection)
        pbSetArrow(@sprites["arrow"],selection)
        if selection==-4
          nextbox = (@storage.currentBox+@storage.maxBoxes-1)%@storage.maxBoxes
          pbSwitchBoxToLeft(nextbox)
          @storage.currentBox = nextbox
        elsif selection==-5
          nextbox = (@storage.currentBox+1)%@storage.maxBoxes
          pbSwitchBoxToRight(nextbox)
          @storage.currentBox = nextbox
        end
        selection = -1 if selection==-4 || selection==-5
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      end
      self.update
      if Input.trigger?(Input::L)
        pbPlayCursorSE
        nextbox = (@storage.currentBox+@storage.maxBoxes-1)%@storage.maxBoxes
        pbSwitchBoxToLeft(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::R)
        pbPlayCursorSE
        nextbox = (@storage.currentBox+1)%@storage.maxBoxes
        pbSwitchBoxToRight(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::F5)   # Jump to box name
        if selection!=-1
          pbPlayCursorSE
          selection = -1
          pbSetArrow(@sprites["arrow"],selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
        end
      elsif Input.trigger?(Input::A) && @command==0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap)
      elsif Input.trigger?(Input::B)
        @selection = selection
        return nil
      elsif Input.trigger?(Input::C)
        @selection = selection
        if selection>=0
          return [@storage.currentBox,selection]
        elsif selection==-1 # Box name
          return [-4,-1]
        elsif selection==-2 # Party Pokémon
          return [-2,-1]
        elsif selection==-3 # Close Box
          return [-3,-1]
        end
      end
    end
  end

  def pbSelectBox(party)
    return pbSelectBoxInternal(party) if @command==1 # Withdraw
    ret = nil
    loop do
      if !@choseFromParty
        ret = pbSelectBoxInternal(party)
      end
      if @choseFromParty || (ret && ret[0]==-2) # Party Pokémon
        if !@choseFromParty
          pbShowPartyTab
          @selection = 0
        end
        ret = pbSelectPartyInternal(party,false)
        if ret<0
          pbHidePartyTab
          @selection = 0
          @choseFromParty = false
        else
          @choseFromParty = true
          return [-1,ret]
        end
      else
        @choseFromParty = false
        return ret
      end
    end
  end

  def pbSelectPartyInternal(party,depositing)
    selection = @selection
    pbPartySetArrow(@sprites["arrow"],selection)
    pbUpdateOverlay(selection,party)
    pbSetMosaic(selection)
    lastsel = 1
    loop do
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key>=0
        pbPlayCursorSE
        newselection = pbPartyChangeSelection(key,selection)
        if newselection==-1
          return -1 if !depositing
        elsif newselection==-2
          selection = lastsel
        else
          selection = newselection
        end
        pbPartySetArrow(@sprites["arrow"],selection)
        lastsel = selection if selection>0
        pbUpdateOverlay(selection,party)
        pbSetMosaic(selection)
      end
      self.update
      if Input.trigger?(Input::A) && @command==0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap)
      elsif Input.trigger?(Input::B)
        @selection = selection
        return -1
      elsif Input.trigger?(Input::C)
        if selection>=0 && selection<6
          @selection = selection
          return selection
        elsif selection==6   # Close Box
          @selection = selection
          return (depositing) ? -3 : -1
        end
      end
    end
  end

  def pbSelectParty(party)
    return pbSelectPartyInternal(party,true)
  end

  def pbChangeBackground(wp)
    @sprites["box"].refreshSprites = false
    alpha = 0
    Graphics.update
    self.update
    16.times do
      alpha += 16
      Graphics.update
      Input.update
      @sprites["box"].color = Color.new(248,248,248,alpha)
      self.update
    end
    @sprites["box"].refreshBox = true
    @storage[@storage.currentBox].background = wp
    4.times do
      Graphics.update
      Input.update
      self.update
    end
    16.times do
      alpha -= 16
      Graphics.update
      Input.update
      @sprites["box"].color = Color.new(248,248,248,alpha)
      self.update
    end
    @sprites["box"].refreshSprites = true
  end

  def pbSwitchBoxToRight(newbox)
    newbox = PokemonBoxSprite.new(@storage,newbox,@boxviewport)
    newbox.x = 520
    Graphics.frame_reset
    begin
      Graphics.update
      Input.update
      @sprites["box"].x -= 32
      newbox.x -= 32
      self.update
    end until newbox.x<=184
    diff = newbox.x-184
    newbox.x = 184; @sprites["box"].x -= diff
    @sprites["box"].dispose
    @sprites["box"] = newbox
  end

  def pbSwitchBoxToLeft(newbox)
    newbox = PokemonBoxSprite.new(@storage,newbox,@boxviewport)
    newbox.x = -152
    Graphics.frame_reset
    begin
      Graphics.update
      Input.update
      @sprites["box"].x += 32
      newbox.x += 32
      self.update
    end until newbox.x>=184
    diff = newbox.x-184
    newbox.x = 184; @sprites["box"].x -= diff
    @sprites["box"].dispose
    @sprites["box"] = newbox
  end

  def pbJumpToBox(newbox)
    if @storage.currentBox!=newbox
      if newbox>@storage.currentBox
        pbSwitchBoxToRight(newbox)
      else
        pbSwitchBoxToLeft(newbox)
      end
      @storage.currentBox = newbox
    end
  end

  def pbSetMosaic(selection)
    if !@screen.pbHeldPokemon
      if @boxForMosaic!=@storage.currentBox || @selectionForMosaic!=selection
        @sprites["pokemon"].mosaic = 10
        @boxForMosaic = @storage.currentBox
        @selectionForMosaic = selection
      end
    end
  end

  def pbSetQuickSwap(value)
    @quickswap = value
    @sprites["arrow"].quickswap = value
  end

  def pbShowPartyTab
    pbSEPlay("GUI storage show party panel")
    distancePerFrame = 48*30/Graphics.frame_rate
    loop do
      Graphics.update
      Input.update
      @sprites["boxparty"].y -= distancePerFrame
      self.update
      break if @sprites["boxparty"].y<=Graphics.height-352
    end
    @sprites["boxparty"].y = Graphics.height-352
  end

  def pbHidePartyTab
    pbSEPlay("GUI storage hide party panel")
    distancePerFrame = 48*30/Graphics.frame_rate
    loop do
      Graphics.update
      Input.update
      @sprites["boxparty"].y += distancePerFrame
      self.update
      break if @sprites["boxparty"].y>=Graphics.height
    end
    @sprites["boxparty"].y = Graphics.height
  end

  def pbHold(selected)
    pbSEPlay("GUI storage pick up")
    if selected[0]==-1
      @sprites["boxparty"].grabPokemon(selected[1],@sprites["arrow"])
    else
      @sprites["box"].grabPokemon(selected[1],@sprites["arrow"])
    end
    while @sprites["arrow"].grabbing?
      Graphics.update
      Input.update
      self.update
    end
  end

  def pbSwap(selected,heldpoke)
    pbSEPlay("GUI storage pick up")
    heldpokesprite = @sprites["arrow"].heldPokemon
    boxpokesprite = nil
    if selected[0]==-1
      boxpokesprite = @sprites["boxparty"].getPokemon(selected[1])
    else
      boxpokesprite = @sprites["box"].getPokemon(selected[1])
    end
    if selected[0]==-1
      @sprites["boxparty"].setPokemon(selected[1],heldpokesprite)
    else
      @sprites["box"].setPokemon(selected[1],heldpokesprite)
    end
    @sprites["arrow"].setSprite(boxpokesprite)
    @sprites["pokemon"].mosaic = 10
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selected[1]
  end

  def pbPlace(selected,heldpoke)
    pbSEPlay("GUI storage put down")
    heldpokesprite = @sprites["arrow"].heldPokemon
    @sprites["arrow"].place
    while @sprites["arrow"].placing?
      Graphics.update
      Input.update
      self.update
    end
    if selected[0]==-1
      @sprites["boxparty"].setPokemon(selected[1],heldpokesprite)
    else
      @sprites["box"].setPokemon(selected[1],heldpokesprite)
    end
    @boxForMosaic = @storage.currentBox
    @selectionForMosaic = selected[1]
  end

  def pbWithdraw(selected,heldpoke,partyindex)
    pbHold(selected) if !heldpoke
    pbShowPartyTab
    pbPartySetArrow(@sprites["arrow"],partyindex)
    pbPlace([-1,partyindex],heldpoke)
    pbHidePartyTab
  end

  def pbStore(selected,heldpoke,destbox,firstfree)
    if heldpoke
      if destbox==@storage.currentBox
        heldpokesprite = @sprites["arrow"].heldPokemon
        @sprites["box"].setPokemon(firstfree,heldpokesprite)
        @sprites["arrow"].setSprite(nil)
      else
        @sprites["arrow"].deleteSprite
      end
    else
      sprite = @sprites["boxparty"].getPokemon(selected[1])
      if destbox==@storage.currentBox
        @sprites["box"].setPokemon(firstfree,sprite)
        @sprites["boxparty"].setPokemon(selected[1],nil)
      else
        @sprites["boxparty"].deletePokemon(selected[1])
      end
    end
  end

  def pbRelease(selected,heldpoke)
    box = selected[0]
    index = selected[1]
    if heldpoke
      sprite = @sprites["arrow"].heldPokemon
    elsif box==-1
      sprite = @sprites["boxparty"].getPokemon(index)
    else
      sprite = @sprites["box"].getPokemon(index)
    end
    if sprite
      sprite.release
      while sprite.releasing?
        Graphics.update
        sprite.update
        self.update
      end
    end
  end

  def pbChooseBox(msg)
    commands = []
    for i in 0...@storage.maxBoxes
      box = @storage[i]
      if box
        commands.push(_INTL("{1} ({2}/{3})",box.name,box.nitems,box.length))
      end
    end
    return pbShowCommands(msg,commands,@storage.currentBox)
  end

  def pbBoxName(helptext,minchars,maxchars)
    oldsprites = pbFadeOutAndHide(@sprites)
    ret = pbEnterBoxName(helptext,minchars,maxchars)
    if ret.length>0
      @storage[@storage.currentBox].name = ret
    end
    @sprites["box"].refreshBox = true
    pbRefresh
    pbFadeInAndShow(@sprites,oldsprites)
  end

  def pbChooseItem(bag)
    oldsprites=pbFadeOutAndHide(@sprites)
    scene=PokemonBag_Scene.new
    screen=PokemonBagScreen.new(scene,bag)
    ret=screen.pbGiveItemScreen
    pbFadeInAndShow(@sprites,oldsprites)
    return ret
  end

  def pbSummary(selected,heldpoke)
    oldsprites=pbFadeOutAndHide(@sprites)
    scene=PokemonSummaryScene.new
    screen=PokemonSummary.new(scene)
    if heldpoke
      screen.pbStartScreen([heldpoke],0)
    elsif selected[0]==-1
      @selection=screen.pbStartScreen(@storage.party,selected[1])
      pbPartySetArrow(@sprites["arrow"],@selection)
      pbUpdateOverlay(@selection,@storage.party)
    else
      @selection=screen.pbStartScreen(@storage.boxes[selected[0]],selected[1])
      pbSetArrow(@sprites["arrow"],@selection)
      pbUpdateOverlay(@selection)
    end
    pbFadeInAndShow(@sprites,oldsprites)
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
       bitmap.font.color=(marked) ? Color.new(80,80,80) : Color.new(208,200,184)
       itemwidth=bitmap.text_size(item).width
       bitmap.draw_text(realX,realY,itemwidth+2,totalsize.height,item)
       realX+=itemwidth
       i+=1
    }
    bitmap.font.name=oldfontname
    bitmap.font.size=oldfontsize
    bitmap.font.color=oldfontcolor
  end

  def getMarkingCommands(markings)
    selectedtag="<c=505050>"
    deselectedtag="<c=D0C8B8>"
    commands=[]
    for i in 0...PokemonStorage::MARKINGCHARS.length
      commands.push( ((markings&(1<<i))==0 ? deselectedtag : selectedtag)+"<fn=Arial>"+PokemonStorage::MARKINGCHARS[i])
    end
    commands.push(_INTL("Aceptar"))
    commands.push(_INTL("Salir"))
    return commands
  end

  def pbMark(selected,heldpoke)
    ret=0
    msgwindow=Window_UnformattedTextPokemon.newWithSize("",180,0,Graphics.width-180,32)
    msgwindow.viewport=@viewport
    msgwindow.visible=true
    msgwindow.letterbyletter=false
    msgwindow.resizeHeightToFit(_INTL("Marcar tu Pokémon."),Graphics.width-180)
    msgwindow.text=_INTL("Marcar tu Pokémon.")
    pokemon=heldpoke
    if heldpoke
      pokemon=heldpoke
    elsif selected[0]==-1
      pokemon=@storage.party[selected[1]]
    else
      pokemon=@storage.boxes[selected[0]][selected[1]]
    end
    pbBottomRight(msgwindow)
    selectedtag="<c=505050>"
    deselectedtag="<c=D0C8B8>"
    commands=getMarkingCommands(pokemon.markings)
    cmdwindow=Window_AdvancedCommandPokemon.new(commands)
    cmdwindow.viewport=@viewport
    cmdwindow.visible=true
    cmdwindow.resizeToFit(cmdwindow.commands)
    cmdwindow.width=132
    cmdwindow.height=Graphics.height-msgwindow.height if cmdwindow.height>Graphics.height-msgwindow.height
    cmdwindow.update
    pbBottomRight(cmdwindow)
    markings=pokemon.markings
    cmdwindow.y-=msgwindow.height
    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::B)
        break # cancel
      end
      if Input.trigger?(Input::C)
        if cmdwindow.index==commands.length-1
          break # cancel
        elsif cmdwindow.index==commands.length-2
          pokemon.markings=markings # OK
          break
        elsif cmdwindow.index>=0
          mask=(1<<cmdwindow.index)
          if (markings&mask)==0
            markings|=mask
          else
            markings&=~mask
          end
          commands=getMarkingCommands(markings)
          cmdwindow.commands=commands
        end
      end
      pbUpdateSpriteHash(@sprites)
      msgwindow.update
      cmdwindow.update
    end
    msgwindow.dispose
    cmdwindow.dispose
    Input.update
  end

  def pbRefresh
    @sprites["box"].refresh
    @sprites["boxparty"].refresh
  end

  def pbHardRefresh
    oldPartyY = @sprites["boxparty"].y
    @sprites["box"].dispose
    @sprites["box"] = PokemonBoxSprite.new(@storage,@storage.currentBox,@boxviewport)
    @sprites["boxparty"].dispose
    @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party,@boxsidesviewport)
    @sprites["boxparty"].y = oldPartyY
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
       bitmap.font.color=(marked) ? Color.new(80,80,80) : Color.new(208,200,184)
       itemwidth=bitmap.text_size(item).width
       bitmap.draw_text(realX,realY,itemwidth+2,totalsize.height,item)
       realX+=itemwidth
       i+=1
    }
    bitmap.font.name=oldfontname
    bitmap.font.size=oldfontsize
    bitmap.font.color=oldfontcolor
  end


  def pbUpdateOverlay(selection,party=nil)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    buttonbase = Color.new(248,248,248)
    buttonshadow = Color.new(80,80,80)
    pbDrawTextPositions(overlay,[
       [_INTL("Equipo: {1}",(@storage.party.length rescue 0)),270,328,2,buttonbase,buttonshadow,1],
       [_INTL("Salir"),446,328,2,buttonbase,buttonshadow,1],
    ])
    pokemon = nil
    if @screen.pbHeldPokemon
      pokemon = @screen.pbHeldPokemon
    elsif selection>=0
      pokemon = (party) ? party[selection] : @storage[@storage.currentBox,selection]
    end
    if !pokemon
      @sprites["pokemon"].visible = false
      return
    end
    @sprites["pokemon"].visible = true
    base   = Color.new(88,88,80)
    shadow = Color.new(168,184,184)
    nonbase   = Color.new(208,208,208)
    nonshadow = Color.new(224,224,224)
    pokename = pokemon.name
    textstrings = [
       [pokename,10,8,false,base,shadow]
    ]
    if !pokemon.egg?
      imagepos = []
      if pokemon.isMale?
        textstrings.push([_INTL("♂"),148,8,false,Color.new(24,112,216),Color.new(136,168,208)])
      elsif pokemon.isFemale?
        textstrings.push([_INTL("♀"),148,8,false,Color.new(248,56,32),Color.new(224,152,144)])
      end
      #imagepos.push(["Graphics/Pictures/Storage/overlay_lv",6,246,0,0,-1,-1])
      textstrings.push([pokemon.level.to_s,36,234,false,base,shadow])
      if pokemon.ability>0
        textstrings.push([PBAbilities.getName(pokemon.ability),86,306,2,base,shadow])
      else
        textstrings.push([_INTL("Sin habilidad"),86,306,2,nonbase,nonshadow])
      end
      if pokemon.item>0
        textstrings.push([PBItems.getName(pokemon.item),86,342,2,base,shadow])
      else
        textstrings.push([_INTL("Sin objeto"),86,342,2,nonbase,nonshadow])
      end
      if pokemon.isShiny?
        imagepos.push(["Graphics/Pictures/shiny",156,198,0,0,-1,-1])
      end
      typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
      type1rect=Rect.new(0,pokemon.type1*28,64,28)
      type2rect=Rect.new(0,pokemon.type2*28,64,28)
      
      if pokemon.type1==pokemon.type2
        overlay.blt(52,272,typebitmap.bitmap,type1rect)
      else
        overlay.blt(18,272,typebitmap.bitmap,type1rect)
        overlay.blt(88,272,typebitmap.bitmap,type2rect)
      end
      if pokemon.teratype && pbHasTeraOrb
        teratypebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/teraTypes"))
        teratyperect=Rect.new(0,pokemon.teratype*32,32,32)
        if ![getConst(PBSpecies,:OGERPON),getConst(PBSpecies,:TERAPAGOS)].include?(pokemon.species) && !$game_switches[NO_TERA_CRISTAL]
          overlay.blt(66,232,teratypebitmap.bitmap,teratyperect)
        end
      end
      drawMarkings(overlay,70,240,128,20,pokemon.markings)
      pbDrawImagePositions(overlay,imagepos)
    end
    pbSetSystemFont(overlay)
    pbDrawTextPositions(overlay,textstrings)
    if !pokemon.isEgg?
      textstrings.clear
      textstrings.push([_INTL("Nv."),10,238,false,base,shadow])
      pbSetSmallFont(overlay)
    pbDrawTextPositions(overlay,textstrings)
    end
    pbSetSystemFont(overlay)
    @sprites["pokemon"].setPokemonBitmap(pokemon)
    pbPositionPokemonSprite(@sprites["pokemon"],26,70)
  end


  def update
    pbUpdateSpriteHash(@sprites)
  end
end



#===============================================================================
# Pokémon storage mechanics
#===============================================================================
class PokemonStorageScreen
  attr_reader :scene
  attr_reader :storage

  def initialize(scene,storage)
    @scene = scene
    @storage = storage
    @pbHeldPokemon = nil
  end

  def pbStartScreen(command)
    @heldpkmn = nil
    if command==0
### MOVE #######################################################################
      @scene.pbStartBox(self,command)
      loop do
        selected = @scene.pbSelectBox(@storage.party)
        if selected==nil
          if pbHeldPokemon
            pbDisplay(_INTL("¡Estás sosteniendo un Pokémon!"))
            next
          end
          next if pbConfirm(_INTL("¿Continuar operaciones de Caja?"))
          break
        elsif selected[0]==-3 # Close box
          if pbHeldPokemon
            pbDisplay(_INTL("¡Estás sosteniendo un Pokémon!"))
            next
          end
          break if pbConfirm(_INTL("¿Salir de la Caja?"))
          next
        elsif selected[0]==-4 # Box name
          pbBoxCommands
        else
          pokemon = @storage[selected[0],selected[1]]
          heldpoke = pbHeldPokemon
          next if !pokemon && !heldpoke
          if @scene.quickswap
            if @heldpkmn
              (pokemon) ? pbSwap(selected) : pbPlace(selected)
            else
              pbHold(selected)
            end
          else
            commands = []
            cmdMove     = -1
            cmdSummary  = -1
            cmdWithdraw = -1
            cmdItem     = -1
            cmdMark     = -1
            cmdRelease  = -1
            cmdDebug    = -1
            cmdCancel   = -1
            if heldpoke
              helptext=_INTL("{1} fue seleccionado.",heldpoke.name)
              commands[cmdMove=commands.length]   = (pokemon) ? _INTL("Cambiar") : _INTL("Colocar")
            elsif pokemon
              helptext=_INTL("{1} fue seleccionado.",pokemon.name)
              commands[cmdMove=commands.length]   = _INTL("Mover")
            end
            commands[cmdSummary=commands.length]  = _INTL("Datos")
            commands[cmdWithdraw=commands.length] = (selected[0]==-1) ? _INTL("Dejar") : _INTL("Sacar")
            commands[cmdItem=commands.length]     = _INTL("Objeto")
            commands[cmdMark=commands.length]     = _INTL("Marcar")
            commands[cmdRelease=commands.length]  = _INTL("Soltar")
            commands[cmdDebug=commands.length]    = _INTL("Depurador") if $DEBUG
            commands[cmdCancel=commands.length]   = _INTL("Salir")
            command=pbShowCommands(helptext,commands)
            if cmdMove>=0 && command==cmdMove   # Move/Shift/Place
              if @heldpkmn
                (pokemon) ? pbSwap(selected) : pbPlace(selected)
              else
                pbHold(selected)
              end
            elsif cmdSummary>=0 && command==cmdSummary   # Summary
              pbSummary(selected,@heldpkmn)
            elsif cmdWithdraw>=0 && command==cmdWithdraw   # Withdraw/Store
              (selected[0]==-1) ? pbStore(selected,@heldpkmn) : pbWithdraw(selected,@heldpkmn)
            elsif cmdItem>=0 && command==cmdItem   # Item
              pbItem(selected,@heldpkmn)
            elsif cmdMark>=0 && command==cmdMark   # Mark
              pbMark(selected,@heldpkmn)
            elsif cmdRelease>=0 && command==cmdRelease   # Release
              pbRelease(selected,@heldpkmn)
            elsif cmdDebug>=0 && command==cmdDebug   # Debug
              debugMenu(selected,(@heldpkmn) ? @heldpkmn : pokemon,heldpoke)
            end
          end
        end
      end
      @scene.pbCloseBox
    elsif command==1
### WITHDRAW ###################################################################
      @scene.pbStartBox(self,command)
      loop do
        selected = @scene.pbSelectBox(@storage.party)
        if selected==nil
          next if pbConfirm(_INTL("¿Continuar operaciones de Caja?"))
          break
        else
          case selected[0]
          when -2 # Party Pokémon
            pbDisplay(_INTL("¿Cuál vas a tomar?"))
            next
          when -3 # Close box
            break if pbConfirm(_INTL("¿Salir de la Caja?"))
            next
          when -4 # Box name
            pbBoxCommands
            next
          end
          pokemon = @storage[selected[0],selected[1]]
          next if !pokemon
          command=pbShowCommands(
             _INTL("{1} fue seleccionado.",pokemon.name),[_INTL("Sacar"),
             _INTL("Datos"),_INTL("Marcar"),_INTL("Soltar"),_INTL("Salir")])
          case command
          when 0 # Withdraw
            pbWithdraw(selected,nil)
          when 1 # Summary
            pbSummary(selected,nil)
          when 2 # Mark
            pbMark(selected,nil)
          when 3 # Release
            pbRelease(selected,nil)
          end
        end
      end
      @scene.pbCloseBox
    elsif command==2
### DEPOSIT ####################################################################
      @scene.pbStartBox(self,command)
      loop do
        selected = @scene.pbSelectParty(@storage.party)
        if selected==-3 # Close box
          break if pbConfirm(_INTL("¿Salir de la Caja?"))
          next
        elsif selected<0
          next if pbConfirm(_INTL("¿Hacer más cambios?"))
          break
        else
          pokemon = @storage[-1,selected]
          next if !pokemon
          command=pbShowCommands(
             _INTL("{1} fue seleccionado.",pokemon.name),[_INTL("Guardar"),
             _INTL("Datos"),_INTL("Marcar"),_INTL("Soltar"),_INTL("Salir")])
          case command
          when 0 # Store
            pbStore([-1,selected],nil)
          when 1 # Summary
            pbSummary([-1,selected],nil)
          when 2 # Mark
            pbMark([-1,selected],nil)
          when 3 # Release
            pbRelease([-1,selected],nil)
          end
        end
      end
      @scene.pbCloseBox
    elsif command==3
      @scene.pbStartBox(self,command)
      @scene.pbCloseBox
    end
  end

  def pbHardRefresh   # For debug
    @scene.pbHardRefresh
  end

  def pbRefreshSingle(i)   # For debug
    @scene.pbUpdateOverlay(i[1],(i[0]==-1) ? @storage.party : nil)
    @scene.pbHardRefresh
  end

  def pbDisplay(message)
    @scene.pbDisplay(message)
  end

  def pbConfirm(str)
    return pbShowCommands(str,[_INTL("Sí"),_INTL("No")])==0
  end

  def pbShowCommands(msg,commands,index=0)
    return @scene.pbShowCommands(msg,commands,index)
  end

  def pbAble?(pokemon)
    pokemon && !pokemon.egg? && pokemon.hp>0
  end

  def pbAbleCount
    count = 0
    for p in @storage.party
      count += 1 if pbAble?(p)
    end
    return count
  end

  def pbHeldPokemon
    return @heldpkmn
  end

  def pbWithdraw(selected,heldpoke)
    box = selected[0]
    index = selected[1]
    if box==-1
      raise _INTL("No se puede retirar del equipo...");
    end
    if @storage.party.nitems>=6
      pbDisplay(_INTL("¡Tu equipo está completo!"))
      return false
    end
    @scene.pbWithdraw(selected,heldpoke,@storage.party.length)
    if heldpoke
      @storage.pbMoveCaughtToParty(heldpoke)
      @heldpkmn = nil
    else
      @storage.pbMove(-1,-1,box,index)
    end
    @scene.pbRefresh
    return true
  end

  def pbStore(selected,heldpoke)
    box = selected[0]
    index = selected[1]
    if box!=-1
      raise _INTL("No se puede dejar desde la Caja...")
    end
    if pbAbleCount<=1 && pbAble?(@storage[box,index]) && !heldpoke
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
    elsif heldpoke && heldpoke.mail
      pbDisplay(_INTL("Primero se debe quitar la Carta."))
    elsif !heldpoke && @storage[box,index].mail
      pbDisplay(_INTL("Primero se debe quitar la Carta."))
    else
      loop do
        destbox = @scene.pbChooseBox(_INTL("¿En qué Caja dejarlo?"))
        if destbox>=0
          success = false
          firstfree = @storage.pbFirstFreePos(destbox)
          if firstfree<0
            pbDisplay(_INTL("La Caja está llena."))
            next
          end
          @scene.pbStore(selected,heldpoke,destbox,firstfree)
          if heldpoke
            @storage.pbMoveCaughtToBox(heldpoke,destbox)
            @heldpkmn = nil
          else
            @storage.pbMove(destbox,-1,-1,index)
          end
        end
        break
      end
      @scene.pbRefresh
    end
  end

  def pbHold(selected)
    box = selected[0]
    index = selected[1]
    if box==-1 && pbAble?(@storage[box,index]) && pbAbleCount<=1
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
      return
    end
    @scene.pbHold(selected)
    @heldpkmn = @storage[box,index]
    @storage.pbDelete(box,index)
    @scene.pbRefresh
  end

  def pbPlace(selected)
    box = selected[0]
    index = selected[1]
    if @storage[box,index]
      raise _INTL("Posición {1},{2} está vacía...",box,index)
    end
    if box!=-1 && index>=@storage.maxPokemon(box)
      pbDisplay("No se puede colocar ahí.")
      return
    end
    if box!=-1 && @heldpkmn.mail
      pbDisplay("Primero se debe quitar la Carta.")
      return
    end
    if box>=0
      @heldpkmn.heal
      @heldpkmn.formTime = nil if @heldpkmn.respond_to?("formTime") && @heldpkmn.formTime
    end
    @scene.pbPlace(selected,@heldpkmn)
    @storage[box,index] = @heldpkmn
    if box==-1
      @storage.party.compact!
    end
    @scene.pbRefresh
    @heldpkmn = nil
  end

  def pbSwap(selected)
    box = selected[0]
    index = selected[1]
    if !@storage[box,index]
      raise _INTL("Position {1},{2} is empty...",box,index)
    end
    if box==-1 && pbAble?(@storage[box,index]) && pbAbleCount<=1 && !pbAble?(@heldpkmn)
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
      return false
    end
    if box!=-1 && @heldpkmn.mail
      pbDisplay("Primero se debe quitar la Carta.")
      return false
    end
    @scene.pbSwap(selected,@heldpkmn)
    if box>=0
      @heldpkmn.heal
      @heldpkmn.formTime = nil if @heldpkmn.respond_to?("formTime") && @heldpkmn.formTime
    end
    tmp = @storage[box,index]
    @storage[box,index] = @heldpkmn
    @heldpkmn = tmp
    @scene.pbRefresh
    return true
  end

  def pbRelease(selected,heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box,index]
    return if !pokemon
    if pokemon.egg?
      pbDisplay(_INTL("No puedes soltar un Huevo."))
      return false
    elsif pokemon.mail
      pbDisplay(_INTL("Primero se debe quitar la Carta."))
      return false
    end
    if box==-1 && pbAbleCount<=1 && pbAble?(pokemon) && !heldpoke
      pbDisplay(_INTL("¡Ése es tu último Pokémon!"))
      return
    end
    command = pbShowCommands(_INTL("¿Soltar a este Pokémon?"),[_INTL("No"),_INTL("Sí")])
    if command==1
      pkmnname = pokemon.name
      @scene.pbRelease(selected,heldpoke)
      if heldpoke
        @heldpkmn = nil
      else
        @storage.pbDelete(box,index)
      end
      @scene.pbRefresh
      pbDisplay(_INTL("Soltaste a {1}.",pkmnname))
      pbDisplay(_INTL("¡Adiós, {1}!",pkmnname))
      @scene.pbRefresh
    end
    return
  end

  def pbChooseMove(pkmn,helptext,index=0)
    movenames = []
    for i in pkmn.moves
      break if i.id==0
      if i.totalpp==0
        movenames.push(_INTL("{1} (PP: ---)",PBMoves.getName(i.id),i.pp,i.totalpp))
      else
        movenames.push(_INTL("{1} (PP: {2}/{3})",PBMoves.getName(i.id),i.pp,i.totalpp))
      end
    end
    return @scene.pbShowCommands(helptext,movenames,index)
  end

  def pbSummary(selected,heldpoke)
    @scene.pbSummary(selected,heldpoke)
  end

  def pbMark(selected,heldpoke)
    @scene.pbMark(selected,heldpoke)
  end

  def pbItem(selected,heldpoke)
    box = selected[0]
    index = selected[1]
    pokemon = (heldpoke) ? heldpoke : @storage[box,index]
    if pokemon.egg?
      pbDisplay(_INTL("Un Huevo no puede llevar un objeto."))
      return
    elsif pokemon.mail
      pbDisplay(_INTL("Primero se debe quitar la Carta."))
      return
    end
    if pokemon.item>0
      itemname = PBItems.getName(pokemon.item)
      if pbConfirm(_INTL("¿Tomar {1}?",itemname))
        if !$PokemonBag.pbStoreItem(pokemon.item)
          pbDisplay(_INTL("No se puede guardar {1}.",itemname))
        else
          pbDisplay(_INTL("Tomaste {1}.",itemname))
          pokemon.setItem(0)
          @scene.pbHardRefresh
        end
      end
    else
      item = scene.pbChooseItem($PokemonBag)
      if item>0
        itemname = PBItems.getName(item)
        pokemon.setItem(item)
        $PokemonBag.pbDeleteItem(item)
        pbDisplay(_INTL("¡Ahora lleva {1}!",itemname))
        @scene.pbHardRefresh
      end
    end
  end

  def pbBoxCommands
    commands = [
       _INTL("Saltar"),
       _INTL("Paisaje"),
       _INTL("Nombre"),
       _INTL("Salir"),
    ]
    command = pbShowCommands(
       _INTL("¿Qué deseas hacer?"),commands)
    case command
    when 0
      destbox = @scene.pbChooseBox(_INTL("¿Ir a qué Caja?"))
      if destbox>=0
        @scene.pbJumpToBox(destbox)
      end
    when 1
      papers = @storage.availableWallpapers
      index = 0
      for i in 0...papers[1].length
        if papers[1][i]==@storage[@storage.currentBox].background
          index = i; break
        end
      end
      wpaper = pbShowCommands(_INTL("Elige un fondo."),papers[0],index)
      if wpaper>=0
        @scene.pbChangeBackground(papers[1][wpaper])
      end
    when 2
      @scene.pbBoxName(_INTL("¿Nombre de la Caja?"),0,12)
    end
  end

  def pbChoosePokemon(party=nil)
    @heldpkmn = nil
    @scene.pbStartBox(self,2)
    retval = nil
    loop do
      selected = @scene.pbSelectBox(@storage.party)
      if selected && selected[0]==-3 # Close box
        break if pbConfirm(_INTL("¿Salir de la Caja?"))
        next
      end
      if selected==nil
        next if pbConfirm(_INTL("¿Hacer más cambios?"))
        break
      elsif selected[0]==-4 # Box name
        pbBoxCommands
      else
        pokemon = @storage[selected[0],selected[1]]
        next if !pokemon
        commands = [
           _INTL("Elegir"),
           _INTL("Datos"),
           _INTL("Sacar"),
           _INTL("Objeto"),
           _INTL("Marcar")
        ]
        commands.push(_INTL("Salir"))
        commands[2] = _INTL("Guardar") if selected[0]==-1
        helptext = _INTL("{1} fue seleccionado.",pokemon.name)
        command = pbShowCommands(helptext,commands)
        case command
        when 0 # Move/Shift/Place
          if pokemon
            retval = selected
            break
          end
        when 1 # Summary
          pbSummary(selected,nil)
        when 2 # Withdraw
          if selected[0]==-1
            pbStore(selected,nil)
          else
            pbWithdraw(selected,nil)
          end
        when 3 # Item
          pbItem(selected,nil)
        when 4 # Mark
          pbMark(selected,nil)
        end
      end
    end
    @scene.pbCloseBox
    return retval
  end
end

################################################################################
# PC menus
################################################################################
def Kernel.pbGetStorageCreator
  creator=pbStorageCreator
  creator=_INTL("Bill") if !creator || creator==""
  return creator
end

def pbPCItemStorage
  loop do
    command=Kernel.pbShowCommandsWithHelp(nil,
       [_INTL("Sacar Objeto"),
       _INTL("Dejar Objeto"),
       _INTL("Tirar Objeto"),
       _INTL("Salir")],
       [_INTL("Sacar objetos de la PC."),
       _INTL("Almacenar objetos en la PC."),
       _INTL("Tirar objetos almacenados en la PC."),
       _INTL("Volver al menú anterior.")],-1
    )
    if command==0 # Withdraw Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage=PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        Kernel.pbMessage(_INTL("No hay objetos."))
      else
        pbFadeOutIn(99999){
           scene=WithdrawItemScene.new
           screen=PokemonBagScreen.new(scene,$PokemonBag)
           ret=screen.pbWithdrawItemScreen
        }
      end
    elsif command==1 # Deposit Item
      pbFadeOutIn(99999){
         scene=PokemonBag_Scene.new
         screen=PokemonBagScreen.new(scene,$PokemonBag)
         ret=screen.pbDepositItemScreen
      }
    elsif command==2 # Toss Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage=PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        Kernel.pbMessage(_INTL("No hay objetos."))
      else
        pbFadeOutIn(99999){
           scene=TossItemScene.new
           screen=PokemonBagScreen.new(scene,$PokemonBag)
           ret=screen.pbTossItemScreen
        }
      end
    else
      break
    end
  end
end

def pbPCMailbox
  if !$PokemonGlobal.mailbox || $PokemonGlobal.mailbox.length==0
    Kernel.pbMessage(_INTL("Aquí no hay ninguna Carta."))
  else
    loop do
      commands=[]
      for mail in $PokemonGlobal.mailbox
        commands.push(mail.sender)
      end
      commands.push(_INTL("Salir"))
      command=Kernel.pbShowCommands(nil,commands,-1)
      if command>=0 && command<$PokemonGlobal.mailbox.length
        mailIndex=command
        command=Kernel.pbMessage(_INTL("¿Qué quieres hacer con la Carta de {1}?",
           $PokemonGlobal.mailbox[mailIndex].sender),[
           _INTL("Leer"),
           _INTL("Mover a la Mochila"),
           _INTL("Dar"),
           _INTL("Salir")
           ],-1)
        if command==0                   # Leer
          pbFadeOutIn(99999){
             pbDisplayMail($PokemonGlobal.mailbox[mailIndex])
          }
        elsif command==1                # Mover a la Mochila
          if Kernel.pbConfirmMessage(_INTL("El mensaje se perderá. ¿Estás de acuerdo?"))
            if $PokemonBag.pbStoreItem($PokemonGlobal.mailbox[mailIndex].item)
              Kernel.pbMessage(_INTL("La Carta regresó a la Mochila con el mensaje borrado."))
              $PokemonGlobal.mailbox.delete_at(mailIndex)
            else
              Kernel.pbMessage(_INTL("La mochila está llena."))
            end
          end
        elsif command==2                # Dar
          pbFadeOutIn(99999){
             sscene=PokemonScreen_Scene.new
             sscreen=PokemonScreen.new(sscene,$Trainer.party)
             sscreen.pbPokemonGiveMailScreen(mailIndex)
          }
        end
      else
        break
      end
    end
  end
end

def pbTrainerPCMenu
  loop do
    command=Kernel.pbMessage(_INTL("¿Qué quieres hacer?"),[
       _INTL("Almacén Objetos"),
       _INTL("Buzón"),
       _INTL("Desconexión")
       ],-1)
    if command==0
      pbPCItemStorage
    elsif command==1
      pbPCMailbox
    else
      break
    end
  end
end



module PokemonPCList
  @@pclist=[]

  def self.registerPC(pc)
    @@pclist.push(pc)
  end

  def self.getCommandList()
    commands=[]
    for pc in @@pclist
      if pc.shouldShow?
        commands.push(pc.name)
      end
    end
    commands.push(_INTL("Desconexión"))
    return commands
  end

  def self.callCommand(cmd)
    if cmd<0 || cmd>=@@pclist.length
      return false
    end
    i=0
    for pc in @@pclist
      if pc.shouldShow?
        if i==cmd
           pc.access()
           return true
        end
        i+=1
      end
    end
    return false
  end
end



def pbTrainerPC
  Kernel.pbMessage(_INTL("\\se[computeropen]{1} encendió la PC.",$Trainer.name))
  pbTrainerPCMenu
  pbSEPlay("computerclose")
end



class TrainerPC
  def shouldShow?
    return true
  end

  def name
    return _INTL("PC de {1}",$Trainer.name)
  end

  def access
    Kernel.pbMessage(_INTL("\\se[accesspc]Accedió al PC de {1}.",$Trainer.name))
    pbTrainerPCMenu
  end
end



class StorageSystemPC
  def shouldShow?
    return true
  end

  def name
    if $PokemonGlobal.seenStorageCreator
      return _INTL("PC de {1}",Kernel.pbGetStorageCreator)
    else
      return _INTL("PC de Alguien")
    end
  end

  def access
    Kernel.pbMessage(_INTL("\\se[accesspc]Acceso al Sistema de Almacenamiento de Pokémon concedido."))
    loop do
      command=Kernel.pbShowCommandsWithHelp(nil,
         [_INTL("Mover Pokémon"),
          _INTL("Sacar Pokémon"),
          _INTL("Dejar Pokémon"),
         _INTL("¡Nos vemos!")],
         [_INTL("Mover los Pokémon de las Cajas y tu equipo."),
          _INTL("Pasar un Pokémon guardado en una Caja a tu equipo."),
          _INTL("Guardar un Pokémon de tu equipo en una Caja."),
         _INTL("Regresar al menú anterior.")],-1
      )
      if command>=0 && command<3
        if command==1 && $PokemonStorage.party.length>=6
          Kernel.pbMessage(_INTL("¡Tu equipo está completo!"))
          next
        end
        count=0
        for p in $PokemonStorage.party
          count+=1 if p && !p.isEgg? && p.hp>0
        end
        if command==2 && count<=1
          Kernel.pbMessage(_INTL("¡No puedes dejar a tu último Pokémon!"))
          next
        end
        pbFadeOutIn(99999){
           scene=PokemonStorageScene.new
           screen=PokemonStorageScreen.new(scene,$PokemonStorage)
           screen.pbStartScreen(command)
        }
      else
        break
      end
    end
  end
end

def pbPokeCenterPC
  unless SHORTER_SYSTEM_TEXTS
    Kernel.pbMessage(_INTL("\\se[computeropen]{1} encendió el PC.",$Trainer.name))
    loop do
      commands=PokemonPCList.getCommandList()
      command=Kernel.pbMessage(_INTL("¿A qué PC quieres acceder?"),
         commands,commands.length)
      if !PokemonPCList.callCommand(command)
        break
      end
    end
  else
    pbSEPlay("computeropen")
    pbFadeOutIn(99999){
      scene=PokemonStorageScene.new
      screen=PokemonStorageScreen.new(scene,$PokemonStorage)
      screen.pbStartScreen(0)
    }
  end
  pbSEPlay("computerclose")
end

PokemonPCList.registerPC(StorageSystemPC.new)
PokemonPCList.registerPC(TrainerPC.new)
