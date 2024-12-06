#===============================================================================
# Data box for safari battles
#===============================================================================
class SafariDataBox < SpriteWrapper
    attr_accessor :selected
    attr_reader :appearing
  
    def initialize(battle,viewport=nil)
      super(viewport)
      @selected=0
      @battle=battle
      @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battlePlayerSafari")
      @spriteX=PokeBattle_SceneConstants::SAFARIBOX_X
      @spriteY=PokeBattle_SceneConstants::SAFARIBOX_Y
      @appearing=false
      @contents=BitmapWrapper.new(@databox.width,@databox.height)
      self.bitmap=@contents
      self.visible=false
      self.z=50
      pbSetSystemFont(self.bitmap)
      refresh
    end
  
    def appear
      refresh
      self.visible=true
      self.opacity=255
      self.x=@spriteX+240
      self.y=@spriteY
      @appearing=true
    end
  
    def refresh
      self.bitmap.clear
      self.bitmap.blt(0,0,@databox.bitmap,Rect.new(0,0,@databox.width,@databox.height))
      pbSetSystemFont(self.bitmap)
      textpos=[]
      base=PokeBattle_SceneConstants::BOXTEXTBASECOLOR
      shadow=PokeBattle_SceneConstants::BOXTEXTSHADOWCOLOR
      textpos.push([_INTL("Safari Balls"),30,8,false,base,shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE])
      textpos.push([_INTL("Quedan: {1}",@battle.ballcount),30,38,false,base,shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE])
      pbDrawTextPositions(self.bitmap,textpos)
    end
  
    def update
      super
      if @appearing
        self.x-=12
        self.x=@spriteX if self.x<@spriteX
        @appearing=false if self.x<=@spriteX
        self.y=@spriteY
        return
      end
      self.x=@spriteX
      self.y=@spriteY
    end
  end
  
  
  
  #===============================================================================
  # Data box for regular battles (both single and double)
  #===============================================================================
  class PokemonDataBox < SpriteWrapper
    attr_reader :battler
    attr_accessor :selected
    attr_accessor :appearing
    attr_reader :animatingHP
    attr_reader :animatingEXP
  
    def initialize(battler,doublebattle,viewport=nil)
      super(viewport)
      @explevel=0
      @battler=battler
      @selected=0
      @frame=0
      @showhp=false
      @showexp=false
      @appearing=false
      @animatingHP=false
      @starthp=0
      @currenthp=0
      @endhp=0
      @expflash=0
      @spritebaseX = ((@battler.index&1)==0) ? 34 : 16  # Player's/foe's
      if doublebattle
        case @battler.index
        when 0
          @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battlePlayerBoxD")
          @spriteX=PokeBattle_SceneConstants::PLAYERBOXD1_X
          @spriteY=PokeBattle_SceneConstants::PLAYERBOXD1_Y
        when 1
          @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battleFoeBoxD")
          @spriteX=PokeBattle_SceneConstants::FOEBOXD1_X
          @spriteY=PokeBattle_SceneConstants::FOEBOXD1_Y
        when 2
          @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battlePlayerBoxD")
          @spriteX=PokeBattle_SceneConstants::PLAYERBOXD2_X
          @spriteY=PokeBattle_SceneConstants::PLAYERBOXD2_Y
        when 3
          @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battleFoeBoxD")
          @spriteX=PokeBattle_SceneConstants::FOEBOXD2_X
          @spriteY=PokeBattle_SceneConstants::FOEBOXD2_Y
        end
      else
        case @battler.index
        when 0
          @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battlePlayerBoxS")
          @spriteX=PokeBattle_SceneConstants::PLAYERBOX_X
          @spriteY=PokeBattle_SceneConstants::PLAYERBOX_Y
          @showhp=true
          @showexp=true
        when 1
          @databox=AnimatedBitmap.new("Graphics/#{BATTLE_ROUTE}/battleFoeBoxS")
          @spriteX=PokeBattle_SceneConstants::FOEBOX_X
          @spriteY=PokeBattle_SceneConstants::FOEBOX_Y
        end
      end
      @statuses=AnimatedBitmap.new(_INTL("Graphics/#{BATTLE_ROUTE}/battleStatuses"))
      @contents=BitmapWrapper.new(@databox.width,@databox.height)
      self.bitmap=@contents
      self.visible=false
      self.z=50
      refreshExpLevel
      refresh
    end
  
    def dispose
      @statuses.dispose
      @databox.dispose
      @contents.dispose
      super
    end
  
    def refreshExpLevel
      if !@battler.pokemon
        @explevel=0
      else
        growthrate=@battler.pokemon.growthrate
        startexp=PBExperience.pbGetStartExperience(@battler.pokemon.level,growthrate)
        endexp=PBExperience.pbGetStartExperience(@battler.pokemon.level+1,growthrate)
        if startexp==endexp
          @explevel=0
        else
          @explevel=(@battler.pokemon.exp-startexp)*PokeBattle_SceneConstants::EXPGAUGESIZE/(endexp-startexp)
        end
      end
    end
  
    def exp
      return @animatingEXP ? @currentexp : @explevel
    end
  
    def hp
      return @animatingHP ? @currenthp : @battler.hp
    end
  
    def animateHP(oldhp,newhp)
      @starthp=oldhp
      @currenthp=oldhp
      @endhp=newhp
      @animatingHP=true
    end
  
    def animateEXP(oldexp,newexp)
      @currentexp=oldexp
      @endexp=newexp
      @animatingEXP=true
    end
  
    def appear
      refreshExpLevel
      refresh
      self.visible=true
      self.opacity=255
      self.x = ((@battler.index&1)==0) ? @spriteX+320 : @spriteX-320  # Player's/foe's
      self.y=@spriteY
      @appearing=true
    end
  
    def refresh
      self.bitmap.clear
      return if !@battler.pokemon
      self.bitmap.blt(0,0,@databox.bitmap,Rect.new(0,0,@databox.width,@databox.height))
      base=PokeBattle_SceneConstants::BOXTEXTBASECOLOR
      shadow=PokeBattle_SceneConstants::BOXTEXTSHADOWCOLOR
      pokename=@battler.name
      pbSetSystemFont(self.bitmap)
      
      textpos = []
      imagepos=[]
      if @battler.isShiny?
        shinyX=206
        shinyX=-6 if (@battler.index&1)==0 # If player's Pokémon
        imagepos.push(["Graphics/Pictures/shiny.png",@spritebaseX+shinyX,36,0,0,-1,-1])
      end
      if (@battler.isMega? rescue false)
        imagepos.push(["Graphics/#{BATTLE_ROUTE}/battleMegaEvoBox.png",@spritebaseX+8,34,0,0,-1,-1])
      elsif (@battler.isUltra? rescue false)
        imagepos.push(["Graphics/#{BATTLE_ROUTE}/battleUltraBurstBox.png",@spritebaseX+140,4,0,0,-1,-1])
      elsif (@battler.isPrimal? rescue false)
        imagepos.push(["Graphics/#{BATTLE_ROUTE}/battlePrimal#{PBSpecies.getName(@battler.species)}Box.png",@spritebaseX+140,4,0,0,-1,-1])
      elsif (@battler.isTera? rescue false)
        imagepos.push(["Graphics/Pictures/teraTypes.png",@spritebaseX+140,4,0,@battler.type1*32,32,32])
      end
      if @battler.owned && (@battler.index&1)==1
        imagepos.push(["Graphics/#{BATTLE_ROUTE}/battleBoxOwned.png",@spritebaseX+8,36,0,0,-1,-1])
      end
      pbDrawImagePositions(self.bitmap,imagepos)
      
      textpos=[
         [pokename,@spritebaseX+8,6,false,base,shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE]
      ]
      genderX=self.bitmap.text_size(pokename).width
      genderX+=@spritebaseX+14
      case @battler.displayGender
      when 0 # Male
        textpos.push([_INTL("♂"),genderX,6,false,Color.new(48,96,216),shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE])
      when 1 # Female
        textpos.push([_INTL("♀"),genderX,6,false,Color.new(248,88,40),shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE])
      end
      pbDrawTextPositions(self.bitmap,textpos)
      pbSetSmallFont(self.bitmap)
      textpos=[
         [_INTL("Nv. {1}",@battler.level),@spritebaseX+202,8,true,base,shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE]
      ]
      if @showhp
        hpstring=_ISPRINTF("{1: 2d}/{2: 2d}",self.hp,@battler.totalhp)
        textpos.push([hpstring,@spritebaseX+188,48,true,base,shadow,PokeBattle_SceneConstants::DTBOX_OUTLINE])
      end
      pbDrawTextPositions(self.bitmap,textpos)
  
      if @battler.status>0
        self.bitmap.blt(@spritebaseX+24,36,@statuses.bitmap,
           Rect.new(0,(@battler.status-1)*16,44,16))
      end
      hpGaugeSize=PokeBattle_SceneConstants::HPGAUGESIZE
      hpgauge=@battler.totalhp==0 ? 0 : (self.hp*hpGaugeSize/@battler.totalhp)
      hpgauge=2 if hpgauge==0 && self.hp>0
      hpzone=0
      hpzone=1 if self.hp<=(@battler.totalhp/2).floor
      hpzone=2 if self.hp<=(@battler.totalhp/4).floor
      hpcolors=[
         PokeBattle_SceneConstants::HPCOLORGREENDARK,
         PokeBattle_SceneConstants::HPCOLORGREEN,
         PokeBattle_SceneConstants::HPCOLORYELLOWDARK,
         PokeBattle_SceneConstants::HPCOLORYELLOW,
         PokeBattle_SceneConstants::HPCOLORREDDARK,
         PokeBattle_SceneConstants::HPCOLORRED
      ]
      # fill with black (shows what the HP used to be)
      hpGaugeX=PokeBattle_SceneConstants::HPGAUGE_X
      hpGaugeY=PokeBattle_SceneConstants::HPGAUGE_Y
      if @animatingHP && self.hp>0
        self.bitmap.fill_rect(@spritebaseX+hpGaugeX,hpGaugeY,
           @starthp*hpGaugeSize/@battler.totalhp,6,Color.new(0,0,0))
      end
      # fill with HP color
      self.bitmap.fill_rect(@spritebaseX+hpGaugeX,hpGaugeY,hpgauge,2,hpcolors[hpzone*2])
      self.bitmap.fill_rect(@spritebaseX+hpGaugeX,hpGaugeY+2,hpgauge,4,hpcolors[hpzone*2+1])
      if @showexp
        # fill with EXP color
        expGaugeX=PokeBattle_SceneConstants::EXPGAUGE_X
        expGaugeY=PokeBattle_SceneConstants::EXPGAUGE_Y
        self.bitmap.fill_rect(@spritebaseX+expGaugeX,expGaugeY,self.exp,2,
           PokeBattle_SceneConstants::EXPCOLORSHADOW)
        self.bitmap.fill_rect(@spritebaseX+expGaugeX,expGaugeY+2,self.exp,2,
           PokeBattle_SceneConstants::EXPCOLORBASE)
      end
    end
  
    def update
      super
      @frame = (@frame+1)%24
      if @animatingHP
        if @currenthp<@endhp
          @currenthp+=[1,(@battler.totalhp/PokeBattle_SceneConstants::HPGAUGESIZE).floor].max
          @currenthp=@endhp if @currenthp>@endhp
        elsif @currenthp>@endhp
          @currenthp-=[1,(@battler.totalhp/PokeBattle_SceneConstants::HPGAUGESIZE).floor].max
          @currenthp=@endhp if @currenthp<@endhp
        end
        @animatingHP=false if @currenthp==@endhp
        refresh
      end
      if @animatingEXP
        if !@showexp
          @currentexp=@endexp
        elsif @currentexp<@endexp   # Gaining Exp
          if @endexp>=PokeBattle_SceneConstants::EXPGAUGESIZE ||
             @endexp-@currentexp>=PokeBattle_SceneConstants::EXPGAUGESIZE/4
            @currentexp+=4
          else
            @currentexp+=2
          end
          @currentexp=@endexp if @currentexp>@endexp
        elsif @currentexp>@endexp   # Losing Exp
          if @endexp==0 ||
             @currentexp-@endexp>=PokeBattle_SceneConstants::EXPGAUGESIZE/4
            @currentexp-=4
          elsif @currentexp>@endexp
            @currentexp-=2
          end
          @currentexp=@endexp if @currentexp<@endexp
        end
        refresh
        if @currentexp==@endexp
          if @currentexp==PokeBattle_SceneConstants::EXPGAUGESIZE
            if @expflash==0
              pbSEPlay("expfull")
              self.flash(Color.new(64,200,248),8)
              @expflash=8
            else
              @expflash-=1
              if @expflash==0
                @animatingEXP=false
                refreshExpLevel
              end
            end
          else
            @animatingEXP=false
          end
        end
      end
      # Move data box onto the screen
      if @appearing
        if (@battler.index&1)==0 # if player's Pokémon
          self.x-=12
          self.x=@spriteX if self.x<@spriteX
          @appearing=false if self.x<=@spriteX
        else
          self.x+=12
          self.x=@spriteX if self.x>@spriteX
          @appearing=false if self.x>=@spriteX
        end
        self.y=@spriteY
        return
      end
      self.x=@spriteX
      self.y=@spriteY
      # Data box bobbing while Pokémon is selected
      if @selected==1 || @selected==2   # Choosing commands/targeted or damaged
        if (@frame/6).floor==1
          self.y = @spriteY-2
        elsif (@frame/6).floor==3
          self.y=@spriteY+2
        end
      end
    end
  end