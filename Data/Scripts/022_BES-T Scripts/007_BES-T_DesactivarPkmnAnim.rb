#===============================================================================
# Activar/desactivar sprites animados
# Créditos a maartiiindev_
#===============================================================================
class AnimatedBitmapWrapper
  alias update_before_toggle update unless method_defined?(:update_before_toggle)

  def update
    return false if $PokemonSystem.pkmnanim == 1
    update_before_toggle
  end
end