class PokemonTemp
  attr_accessor :pokemonMoveData

  def pbOpenMoveData
    if !self.pokemonMoveData
      pbRgssOpen("Data/moves.dat","rb"){|f|
         self.pokemonMoveData=f.read
      }
    end
    if block_given?
      StringInput.open(self.pokemonMoveData) {|f| yield f }
    else
      return StringInput.open(self.pokemonMoveData)
    end
  end
end



class PBMoveData
  attr_reader :function,:basedamage,:type,:accuracy
  attr_reader :totalpp,:addlEffect,:target,:priority
  attr_reader :flags
  attr_reader :category

  def initializeOld(moveid)
    movedata=pbRgssOpen("Data/rsattacks.dat")
    movedata.pos=moveid*9
    @function   = movedata.fgetb
    @basedamage = movedata.fgetb
    @type       = movedata.fgetb
    @accuracy   = movedata.fgetb
    @totalpp    = movedata.fgetb
    @addlEffect = movedata.fgetb
    @target     = movedata.fgetb
    @priority   = movedata.fgetsb
    @flags      = movedata.fgetb
    movedata.close
  end

  def initialize(moveid)
    movedata=nil
    if $PokemonTemp
      movedata=$PokemonTemp.pbOpenMoveData
    else
      movedata=pbRgssOpen("Data/moves.dat")
    end
    movedata.pos=moveid*14
    @function    = movedata.fgetw
    @basedamage  = movedata.fgetb
    @type        = movedata.fgetb
    @category    = movedata.fgetb
    @accuracy    = movedata.fgetb
    @totalpp     = movedata.fgetb
    @addlEffect  = movedata.fgetb
    @target      = movedata.fgetw
    @priority    = movedata.fgetsb
    @flags       = movedata.fgetw
    movedata.close
  end
end



class PBMove
  attr_reader(:id)       # Devuelve el ID del movimiento
  attr_accessor(:pp)     # Devuelve los PP disponibles para este movimiento
  attr_accessor(:ppup)   # Devuelve el número de Más PP utilizados en este movimiento

# Devuelve el tipo del movimiento
  def type
    movedata=PBMoveData.new(@id)
    return movedata.type
  end

# Devuelve los PP máximos para este movimiento
  def totalpp
    movedata=PBMoveData.new(@id)
    tpp=movedata.totalpp
    return tpp+(tpp*@ppup/5).floor
  end

# Inicializa el objeto a un ID de movimiento especificado
  def initialize(moveid)
    movedata=PBMoveData.new(moveid)
    @pp=movedata.totalpp
    @id=moveid
    @ppup=0
  end
end