class PokeBattle_DamageState
  attr_accessor :hplost        # PS perdidos por el oponente, incluido los PS perdidos por un sustituto
  attr_accessor :critical      # Bandera de golpe crítico
  attr_accessor :calcdamage    # Daño calculado
  attr_accessor :typemod       # Efectividad del tipo
  attr_accessor :substitute    # Un sustituto toma el daño
  attr_accessor :focusband     # Se usó Cinta Focus
  attr_accessor :focussash     # Se usó Banda Focus
  attr_accessor :sturdy        # Se activó la habilidad Robustez
  attr_accessor :endured       # Se usó Aguante
  attr_accessor :berryweakened # Se usó una baya de resistencia al tipo

  def reset
    @hplost        = 0
    @critical      = false
    @calcdamage    = 0
    @typemod       = 0
    @substitute    = false
    @focusband     = false
    @focussash     = false
    @sturdy        = false
    @endured       = false
    @berryweakened = false
  end

  def initialize
    reset
  end
end



################################################################################
# Success state (used for Battle Arena)
################################################################################
class PokeBattle_SuccessState
  attr_accessor :typemod
  attr_accessor :useState    # 0 - not used, 1 - failed, 2 - succeeded
  attr_accessor :protected
  attr_accessor :skill

  def initialize
    clear
  end

  def clear
    @typemod   = 4
    @useState  = 0
    @protected = false
    @skill     = 0
  end

  def updateSkill
    if @useState==1 && !@protected
      @skill-=2
    elsif @useState==2
      if @typemod>4
        @skill+=2 # "Super effective"
      elsif @typemod>=1 && @typemod<4
        @skill-=1 # "Not very effective"
      elsif @typemod==0
        @skill-=2 # Ineffective
      else
        @skill+=1
      end
    end
    @typemod=4
    @useState=0
    @protected=false
  end
end