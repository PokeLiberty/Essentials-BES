#===============================================================================
# Item icon
#===============================================================================
class ItemIconSprite < SpriteWrapper
  attr_reader :item
  ANIMICONSIZE = 48
  FRAMESPERCYCLE = 40

  def initialize(x,y,item,viewport=nil)
    super(viewport)
    @animbitmap=nil
    @animframe=0
    @numframes=1
    @frame=0
    self.x=x
    self.y=y
    @forceitemchange = true
    self.item=item
    @forceitemchange = false
    @blankzero = false
  end

  def width
    return 0 if !self.bitmap || self.bitmap.disposed?
    return (@numframes==1) ? self.bitmap.width : ANIMICONSIZE
  end

  def height
    return (self.bitmap && !self.bitmap.disposed?) ? self.bitmap.height : 0
  end

  def blankzero=(val)
    @blankzero = val
    @forceitemchange = true
    self.item = @item
    @forceitemchange = false
  end

  def setOffset(offset=PictureOrigin::Center)
    @offset=offset
    changeOrigins
  end

  def changeOrigins
    @offset=PictureOrigin::Center if !@offset
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Top, PictureOrigin::TopRight
      self.oy=0
    when PictureOrigin::Left, PictureOrigin::Center, PictureOrigin::Right
      self.oy=self.height/2
    when PictureOrigin::BottomLeft, PictureOrigin::Bottom, PictureOrigin::BottomRight
      self.oy=self.height
    end
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Left, PictureOrigin::BottomLeft
      self.ox=0
    when PictureOrigin::Top, PictureOrigin::Center, PictureOrigin::Bottom
      self.ox=self.width/2
    when PictureOrigin::TopRight, PictureOrigin::Right, PictureOrigin::BottomRight
      self.ox=self.width
    end
  end

  def item=(value)
    return if @item==value && !@forceitemchange
    @item=value
    @animbitmap.dispose if @animbitmap
    @animbitmap=nil
    if @item && !(@item==0 && @blankzero)
      @animbitmap=AnimatedBitmap.new(pbItemIconFile(value))
      self.bitmap=@animbitmap.bitmap
      if self.bitmap.height==ANIMICONSIZE
        @numframes=[(self.bitmap.width/ANIMICONSIZE).floor,1].max
        self.src_rect=Rect.new(0,0,ANIMICONSIZE,ANIMICONSIZE)
      else
        @numframes=1
        self.src_rect=Rect.new(0,0,self.bitmap.width,self.bitmap.height)
      end
      @animframe=0
      @frame=0
    else
      self.bitmap=nil
    end
    changeOrigins
  end

  def dispose
    @animbitmap.dispose if @animbitmap
    super
  end

  def update
    @updating=true
    super
    if @animbitmap
      @animbitmap.update
      self.bitmap=@animbitmap.bitmap 
      if @numframes>1
        frameskip=(FRAMESPERCYCLE/@numframes).floor
        @frame=(@frame+1)%FRAMESPERCYCLE
        if @frame>=frameskip
          @animframe=(@animframe+1)%@numframes
          self.src_rect.x=@animframe*ANIMICONSIZE
          @frame=0
        end
      end
    end
    @updating=false
  end
end

#===============================================================================
# Item held icon (used in the party screen)
#===============================================================================
class HeldItemIconSprite < SpriteWrapper
  def initialize(x,y,pokemon,viewport=nil)
    super(viewport)
    self.x = x
    self.y = y
    @pokemon = pokemon
    @item = 0
    self.item = @pokemon.item
  end

  def pokemon=(value)
    @pokemon = value
    self.item = @pokemon.item
  end

  def item=(value)
    return if @item==value
    @item = value
    @animbitmap.dispose if @animbitmap
    @animbitmap = nil
    if @item && @item>0
      @animbitmap = AnimatedBitmap.new(pbHeldItemIconFile(value))
      self.bitmap = @animbitmap.bitmap
    else
      self.bitmap = nil
    end
  end

  def dispose
    @animbitmap.dispose if @animbitmap
    super
  end

  def update
    super
    self.item = @pokemon.item
    if @animbitmap
      @animbitmap.update
      self.bitmap = @animbitmap.bitmap
    end
  end
end