if $MKXP
  class CustomTilemap
    def initialize(viewport)
      @tileset    = nil  # Refers to Map Tileset Name
      @autotiles  = CustomTilemapAutotiles.new
      @map_data   = nil  # Refers to 3D Array Of Tile Settings
      @flash_data = nil  # Refers to 3D Array of Tile Flashdata
      @priorities = nil  # Refers to Tileset Priorities
      @visible    = true # Refers to Tileset Visibleness
      @ox         = 0    # Bitmap Offsets
      @oy         = 0    # bitmap Offsets
      @plane      = false
      @haveGraphicsWH=Graphics.width!=nil rescue false
      if @haveGraphicsWH
        @graphicsWidth=Graphics.width
        @graphicsHeight=Graphics.height
      else
        @graphicsWidth=640
        @graphicsHeight=480
      end
      @tileWidth = Game_Map::TILEWIDTH rescue 32
      @tileHeight = Game_Map::TILEHEIGHT rescue 32
      @tileSrcWidth = 32
      @tileSrcHeight = 32
      @diffsizes=(@tileWidth!=@tileSrcWidth) || (@tileHeight!=@tileSrcHeight)
      @tone=Tone.new(0,0,0,0)
      @color=Color.new(0,0,0,0)
      @oldtone=Tone.new(0,0,0,0)
      @oldcolor=Color.new(0,0,0,0)
      @selfviewport=Viewport.new(0,0,graphicsWidth,graphicsHeight)
      @viewport=viewport ? viewport : @selfviewport
      @tiles=[]
      @autotileInfo=[]
      @regularTileInfo=[]
      @oldOx=0
      @oldOy=0
      @oldViewportOx=0
      @oldViewportOy=0
      @layer0=CustomTilemapSprite.new(viewport)
      @layer0.visible=true
      @nowshown=false
      @layer0.bitmap=Bitmap.new([graphicsWidth+320,1].max,[graphicsHeight+320,1].max)
      @flash=nil
      @layer0.ox=0
      @layer0.oy=0
      @oxLayer0=0
      @oyLayer0=0
      @oxFlash=0
      @oyFlash=0
      @layer0.z=0
      @priotiles=[]
      @priotilesfast=[]
      @prioautotiles=[]
      @autosprites=[]
      @framecount=[0,0,0,0,0,0,0,0]
      @tilesetChanged=true
      @flashChanged=false
      @firsttime=true
      @disposed=false
      @usedsprites=false
      @layer0clip=true
      @firsttimeflash=true
      @fullyrefreshed=false
      @fullyrefreshedautos=false
      @divided=false  # MKXP Tiles
      @tilesets=[]
    end
  
    def getRegularTile(sprite,id)
      # MKXP-TILESETS-KYU
      y = (((id - 384)>>3)*@tileSrcHeight)
      if $MKXP && @divided
        tileset_id=(y/8000.0).floor
        if tileset_id == @tilesets.length
          tileset_id = @tilesets.length-1
        end
        tileset = @tilesets[tileset_id]
        y -= 8000*(tileset_id)
      else
        tileset = @tileset
      end
      # FIN-MKXP-KYU
      if !@diffsizes
        if sprite.bitmap!=tileset
          sprite.bitmap=tileset
        end
        sprite.src_rect.set(((id - 384)&7)*@tileSrcWidth,y,
           @tileSrcWidth,@tileSrcHeight)
      else
        bitmap=@regularTileInfo[id]
        if !bitmap
          bitmap=Bitmap.new(@tileWidth,@tileHeight)
          rect=Rect.new(((id - 384)&7)*@tileSrcWidth,y,
             @tileSrcWidth,@tileSrcHeight)
          bitmap.stretch_blt(Rect.new(0,0,@tileWidth,@tileHeight),tileset,rect)
          @regularTileInfo[id]=bitmap
        end
        if sprite.bitmap!=bitmap
          sprite.bitmap=bitmap
        end
      end
    end
  
    #MKXP_Kyu
    def MKXP_Kyu(rect,id)
      h = (((id - 384)>>3)*@tileSrcHeight)
      if $MKXP && @divided
        tileset_id =(h/8000.0).floor
        if tileset_id == @tilesets.length
          tileset_id = @tilesets.length-1
        end
        tileset =  @tilesets[tileset_id]
        h -= 8000*(tileset_id)
        rect.set(((id - 384)&7)*@tileSrcWidth,h,
        @tileSrcWidth,@tileSrcHeight)
      else
        tileset = @tileset
      end
      rect.set(((id - 384)&7)*@tileSrcWidth,h,
      @tileSrcWidth,@tileSrcHeight)
      return tileset
    end
    #MKXP_KYU END
      
    def refreshLayer0(autotiles=false)
      if autotiles
        return true if !shown?
      end
      ptX=@ox-@oxLayer0
      ptY=@oy-@oyLayer0
      if !autotiles && !@firsttime && !@usedsprites &&
         ptX>=0 && ptX+@viewport.rect.width<=@layer0.bitmap.width &&
         ptY>=0 && ptY+@viewport.rect.height<=@layer0.bitmap.height
        if @layer0clip && @viewport.ox==0 && @viewport.oy==0
          @layer0.ox=0
          @layer0.oy=0
          @layer0.src_rect.set(ptX.round,ptY.round,
             @viewport.rect.width,@viewport.rect.height)
        else
          @layer0.ox=ptX.round
          @layer0.oy=ptY.round
          @layer0.src_rect.set(0,0,@layer0.bitmap.width,@layer0.bitmap.height)
        end
        return true
      end
      width=@layer0.bitmap.width
      height=@layer0.bitmap.height
      bitmap=@layer0.bitmap
      ysize=@map_data.ysize
      xsize=@map_data.xsize
      zsize=@map_data.zsize
      twidth=@tileWidth
      theight=@tileHeight
      mapdata=@map_data
      if autotiles
        return true if @fullyrefreshedautos && @prioautotiles.length==0
        xStart=(@oxLayer0/twidth)
        xStart=0 if xStart<0
        yStart=(@oyLayer0/theight)
        yStart=0 if yStart<0
        xEnd=xStart+(width/twidth)+1
        yEnd=yStart+(height/theight)+1
        xEnd=xsize if xEnd>xsize
        yEnd=ysize if yEnd>ysize
        return true if xStart>=xEnd || yStart>=yEnd
        trans=Color.new(0,0,0,0)
        temprect=Rect.new(0,0,0,0)
        tilerect=Rect.new(0,0,twidth,theight)
        zrange=0...zsize
        overallcount=0
        count=0
        if !@fullyrefreshedautos
          for y in yStart..yEnd
            for x in xStart..xEnd
              haveautotile=false
              for z in zrange
                id = mapdata[x, y, z]
                next if !id || id<48 || id>=384
                prioid=@priorities[id]
                next if prioid!=0 || !prioid
                fcount=@framecount[id/48-1]
                next if !fcount || fcount<2
                if !haveautotile
                  haveautotile=true
                  overallcount+=1
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  bitmap.fill_rect(xpos,ypos,twidth,theight,trans) if overallcount<=2000
                  break
                end
              end
              for z in zrange
                id = mapdata[x,y,z]
                next if !id || id<48
                prioid=@priorities[id]
                next if !prioid || prioid!=0
                if overallcount>2000
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  count=addTile(@autosprites,count,xpos,ypos,id)
                  next
                elsif id>=384
                # MKXP-TILESETS-KYU
                 tileset = MKXP_Kyu(temprect,id)
                # FIN-MKXP-KYU
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  if @diffsizes
                    bitmap.stretch_blt(Rect.new(xpos,ypos,twidth,theight),tileset,temprect)
                  else
                    bitmap.blt(xpos,ypos,tileset,temprect)
                  end
                else
                  tilebitmap=@autotileInfo[id]
                  if !tilebitmap
                    anim=autotileFrame(id)
                    next if anim<0
                    tilebitmap=Bitmap.new(twidth,theight)
                    bltAutotile(tilebitmap,0,0,id,anim)
                    @autotileInfo[id]=tilebitmap
                  end
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  bitmap.blt(xpos,ypos,tilebitmap,tilerect)
                end
              end
            end
          end
          Graphics.frame_reset
        else
          if !@priorect || !@priorectautos || @priorect[0]!=xStart ||
             @priorect[1]!=yStart ||
             @priorect[2]!=xEnd ||
             @priorect[3]!=yEnd
            @priorectautos=@prioautotiles.find_all{|tile|
               x=tile[0]
               y=tile[1]
               # "next" means "return" here
               next !(x<xStart || x>xEnd || y<yStart || y>yEnd)
            }
            @priorect=[xStart,yStart,xEnd,yEnd]
          end
     #   echoln ["autos",@priorect,@priorectautos.length,@prioautotiles.length]
          for tile in @priorectautos
            x=tile[0]
            y=tile[1]
            overallcount+=1
            xpos=(x*twidth)-@oxLayer0
            ypos=(y*theight)-@oyLayer0
            bitmap.fill_rect(xpos,ypos,twidth,theight,trans)
            z=0
            while z<zsize
              id = mapdata[x,y,z]
              z+=1
              next if !id || id<48
              prioid=@priorities[id]
              next if prioid!=0 || !prioid
              if id>=384
                # MKXP-TILESETS-KYU
                tileset = MKXP_Kyu(temprect,id)
                # FIN-MKXP-KYU
                if @diffsizes
                  bitmap.stretch_blt(Rect.new(xpos,ypos,twidth,theight),tileset,temprect)
                else
                  bitmap.blt(xpos,ypos,tileset,temprect)
                end
              else
                tilebitmap=@autotileInfo[id]
                if !tilebitmap
                  anim=autotileFrame(id)
                  next if anim<0
                  tilebitmap=Bitmap.new(twidth,theight)
                  bltAutotile(tilebitmap,0,0,id,anim)
                  @autotileInfo[id]=tilebitmap
                end
                bitmap.blt(xpos,ypos,tilebitmap,tilerect)
              end
            end
          end
          Graphics.frame_reset if overallcount>500
        end
        @usedsprites=false
        return true
      end
      return false if @usedsprites
      @firsttime=false
      @oxLayer0=@ox-(width>>2)
      @oyLayer0=@oy-(height>>2)
      if @layer0clip
        @layer0.ox=0
        @layer0.oy=0
        @layer0.src_rect.set(width>>2,height>>2,
           @viewport.rect.width,@viewport.rect.height)
      else
        @layer0.ox=(width>>2)
        @layer0.oy=(height>>2)
      end
      @layer0.bitmap.clear
      @oxLayer0=@oxLayer0.floor
      @oyLayer0=@oyLayer0.floor
      xStart=(@oxLayer0/twidth)
      xStart=0 if xStart<0
      yStart=(@oyLayer0/theight)
      yStart=0 if yStart<0
      xEnd=xStart+(width/twidth)+1
      yEnd=yStart+(height/theight)+1
      xEnd=xsize if xEnd>=xsize
      yEnd=ysize if yEnd>=ysize
      if xStart<xEnd && yStart<yEnd
        tmprect=Rect.new(0,0,0,0)
        yrange=yStart...yEnd
        xrange=xStart...xEnd
        for z in 0...zsize
          for y in yrange
            ypos=(y*theight)-@oyLayer0
            for x in xrange
              xpos=(x*twidth)-@oxLayer0
              id = mapdata[x, y, z]
              next if id==0 || !@priorities[id] || @priorities[id]!=0
              if id>=384
                # MKXP-TILESETS-KYU
               tileset = MKXP_Kyu(tmprect,id)
                # FIN-MKXP-KYU
                if @diffsizes
                  bitmap.stretch_blt(Rect.new(xpos,ypos,twidth,theight),tileset,tmprect)
                else
                  bitmap.blt(xpos,ypos,tileset,tmprect)
                end
              else
                frames=@framecount[id/48-1]
                if frames<=1
                  frame=0
                else
                  frame=(Graphics.frame_count/Animated_Autotiles_Frames)%frames
                end
                bltAutotile(bitmap,xpos,ypos,id,frame)
              end
            end
          end
        end
        Graphics.frame_reset
      end
      return true
    end
  
    def refresh(autotiles=false)
      @oldOx=@ox
      @oldOy=@oy
      usesprites=false
      if @layer0
        @layer0.visible=@visible
        usesprites=!refreshLayer0(autotiles)
        if autotiles && !usesprites
          return
        end
      else
        usesprites=true
      end
      refreshFlashSprite
      vpx=@viewport.rect.x
      vpy=@viewport.rect.y
      vpr=@viewport.rect.width+vpx
      vpb=@viewport.rect.height+vpy
      xsize=@map_data.xsize
      ysize=@map_data.ysize
      minX=(@ox/@tileWidth)-1
      maxX=((@ox+@viewport.rect.width)/@tileWidth)+1
      minY=(@oy/@tileHeight)-1
      maxY=((@oy+@viewport.rect.height)/@tileHeight)+1
      minX=0 if minX<0
      minX=xsize-1 if minX>=xsize
      maxX=0 if maxX<0
      maxX=xsize-1 if maxX>=xsize
      minY=0 if minY<0
      minY=ysize-1 if minY>=ysize
      maxY=0 if maxY<0
      maxY=ysize-1 if maxY>=ysize
      count=0
      if minX<maxX && minY<maxY
        @usedsprites=usesprites || @usedsprites
        if @layer0
          @layer0.visible=false if usesprites
        end
        if @fullyrefreshed
          if !@priotilesrect || !@priotilesfast || 
             @priotilesrect[0]!=minX ||
             @priotilesrect[1]!=minY ||
             @priotilesrect[2]!=maxX ||
             @priotilesrect[3]!=maxY
            @priotilesfast=@priotiles.find_all{|tile|
               x=tile[0]
               y=tile[1]
               # "next" means "return" here
               next !(x<minX || x>maxX || y<minY || y>maxY)
            }
            @priotilesrect=[minX,minY,maxX,maxY]
          end
          #   echoln [minX,minY,maxX,maxY,@priotilesfast.length,@priotiles.length]
          for prio in @priotilesfast
            xpos=(prio[0]*@tileWidth)-@ox
            ypos=(prio[1]*@tileHeight)-@oy
            count=addTile(@tiles,count,xpos,ypos,prio[3])
          end
        else
          if !@priotilesrect || !@priotilesfast || 
             @priotilesrect[0]!=minX ||
             @priotilesrect[1]!=minY ||
             @priotilesrect[2]!=maxX ||
             @priotilesrect[3]!=maxY
            @priotilesfast=[]
            for z in 0...@map_data.zsize
              for y in minY..maxY
                for x in minX..maxX
                  id = @map_data[x, y, z]
                  next if id==0 || !@priorities[id]
                  next if @priorities[id]==0
                  @priotilesfast.push([x,y,z,id])
                end
              end
            end
            @priotilesrect=[minX,minY,maxX,maxY]
          end
          for prio in @priotilesfast
            xpos=(prio[0]*@tileWidth)-@ox
            ypos=(prio[1]*@tileHeight)-@oy
            count=addTile(@tiles,count,xpos,ypos,prio[3])
          end
        end
      end
      if count<@tiles.length
        bigchange=(count<=(@tiles.length*2/3)) && (@tiles.length*2/3)>25
        j=count; len=@tiles.length; while j<len
          sprite=@tiles[j]
          @tiles[j+1]=-1
          if bigchange
            sprite.dispose
            @tiles[j]=nil
            @tiles[j+1]=nil
          elsif !@tiles[j].disposed?
            sprite.visible=false if sprite.visible
          end
          j+=2
        end
        @tiles.compact! if bigchange
      end
    end
  end

  class Bitmap
    alias mkxp_draw_text draw_text
  
    def draw_text(x, y, width, height, text, align = 0)
      height = text_size(text).height
      mkxp_draw_text(x, y+4, width, height, text, align)
    end
  end
  
end

