class Game_Player
  def fullPattern
    case self.direction
    when 2
      return self.pattern
    when 4
      return 4+self.pattern
    when 6
      return 8+self.pattern
    when 8
      return 12+self.pattern
    else
      return 0
    end
  end

  def setDefaultCharName(chname,pattern)
    return if pattern<0 || pattern>=16
    @defaultCharacterName=chname
    @direction=[2,4,6,8][pattern/4]
    @pattern=pattern%4
  end

  def pbCanRun?
    return false if $game_temp.in_menu
    terrain=pbGetTerrainTag
    input=($PokemonSystem.runstyle==1) ? ($PokemonGlobal && $PokemonGlobal.runtoggle) : Input.press?(Input::A)
    return input &&
       !pbMapInterpreterRunning? && !@move_route_forcing && 
       $PokemonGlobal && $PokemonGlobal.runningShoes &&
       !$PokemonGlobal.diving && !$PokemonGlobal.surfing &&
       !$PokemonGlobal.bicycle && !PBTerrain.onlyWalk?(terrain)
  end

  def pbIsRunning?
    return !moving? && !@move_route_forcing && $PokemonGlobal && pbCanRun?
  end

  def character_name
    if !@defaultCharacterName
      @defaultCharacterName=""
    end
    if @defaultCharacterName!=""
      return @defaultCharacterName
    end
    if !moving? && !@move_route_forcing && $PokemonGlobal
      meta=pbGetMetadata(0,MetadataPlayerA+$PokemonGlobal.playerID)
      if $PokemonGlobal.playerID>=0 && meta && 
         !$PokemonGlobal.bicycle && !$PokemonGlobal.diving && !$PokemonGlobal.surfing
        if meta[4] && meta[4]!="" && Input.dir4!=0 && passable?(@x,@y,Input.dir4) && pbCanRun?
          # Display running character sprite
          @character_name=pbGetPlayerCharset(meta,4)
        else
          # Display normal character sprite 
          @character_name=pbGetPlayerCharset(meta,1)
        end
      end
    end
    return @character_name
  end

  alias update_old update
  # Walk Speed | Run Speed
  def update
    if PBTerrain.isIce?(pbGetTerrainTag)
      @move_speed = (Graphics.frame_rate>=60) ? 4 : 5 # Sliding on ice
    elsif !moving? && !@move_route_forcing && $PokemonGlobal
      if $PokemonGlobal.bicycle
        @move_speed = (Graphics.frame_rate>=60) ? 5 : 6 # Cycling
      elsif pbCanRun? || $PokemonGlobal.surfing || $PokemonGlobal.diving
        @move_speed = (Graphics.frame_rate>=60) ? 4 : 5 # Running, surfing or diving
      else
        @move_speed = (Graphics.frame_rate>=60) ? 3 : 4 # Walking
      end
    end
    update_old
  end


end
