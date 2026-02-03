#===============================================================================
# Sistema de Localización para Pokémon Essentials v16
# Permite cargar traducciones alternativas de movimientos, objetos y habilidades
# sin modificar el código existente
#===============================================================================

# Configuración de localizaciones disponibles
# Cada elemento corresponde a un idioma en LANGUAGES
# nil = no hay variaciones para ese idioma
# Array = [["Nombre corto", carpeta_o_nil], ...] donde nil es la traducción base
LOCALIZATION = [  
  [["Castellano", nil], ["Latino", "Latam"]], # Índice 0: Español (España base, Latinoamérica alternativa)
  [nil, nil],                     # Índice 1: Inglés (sin variaciones)
  [nil, nil], 
]

module LocalizationSystem
  LOCALIZATION_PATH = "Localizations/"
  
  # Hash para almacenar las traducciones cargadas
  @@moves_translations = {}
  @@items_translations = {}
  @@abilities_translations = {}
  @@current_locale = nil
  @@current_locale_name = ""
  
  # Carga una localización específica
  # lang_index: índice del idioma principal (de LANGUAGES)
  # variant_index: índice de la variante (de LOCALIZATION[lang_index])
  def self.loadLocale(lang_index, variant_index)
    return false if !LOCALIZATION[lang_index]
    return false if !LOCALIZATION[lang_index].is_a?(Array)
    return false if !LOCALIZATION[lang_index][variant_index]
    
    variant = LOCALIZATION[lang_index][variant_index]
    return false if !variant.is_a?(Array) || variant.length < 2
    
    locale_folder = variant[1]
    locale_name = variant[0]
    
    # Si la carpeta es nil, es la traducción base (no hacer nada)
    if locale_folder.nil?
      clearLocale
      @@current_locale = [lang_index, variant_index]
      @@current_locale_name = locale_name
      return true
    end
    
    locale_path = LOCALIZATION_PATH + locale_folder + "/"
    
    # Verificar que la carpeta existe
    if !FileTest.directory?(locale_path)
      return false
    end
    
    # Limpiar traducciones anteriores
    @@moves_translations.clear
    @@items_translations.clear
    @@abilities_translations.clear
    
    # Cargar archivos de traducción
    loadTranslationFile(locale_path + "Moves.txt", @@moves_translations)
    loadTranslationFile(locale_path + "Items.txt", @@items_translations)
    loadTranslationFile(locale_path + "Abilities.txt", @@abilities_translations)
    
    @@current_locale = [lang_index, variant_index]
    @@current_locale_name = locale_name
    return true
  end
  
  # Carga un archivo de traducción
  def self.loadTranslationFile(filepath, target_hash)
    return if !FileTest.exist?(filepath)
    
    File.open(filepath, "r") do |f|
      f.each_line do |line|
        line = line.strip
        next if line.length == 0 || line[0] == ?#
        
        if line.include?("=")
          key, value = line.split("=", 2)
          key = key.strip.upcase
          value = value.strip
          
          # Intentar convertir la clave a un ID si es posible
          begin
            if defined?(PBMoves) && target_hash == @@moves_translations
              id = getID(PBMoves, key)
              target_hash[id] = value if id
            elsif defined?(PBItems) && target_hash == @@items_translations
              id = getID(PBItems, key)
              target_hash[id] = value if id
            elsif defined?(PBAbilities) && target_hash == @@abilities_translations
              id = getID(PBAbilities, key)
              target_hash[id] = value if id
            end
          rescue
            # Si falla, guardar con la clave de texto
            target_hash[key] = value
          end
        end
      end
    end
  end
  
  # Desactiva la localización actual
  def self.clearLocale
    @@moves_translations.clear
    @@items_translations.clear
    @@abilities_translations.clear
    @@current_locale = nil
    @@current_locale_name = ""
  end
  
  # Obtiene el nombre traducido de un movimiento
  def self.getMoveTranslation(id)
    return @@moves_translations[id] if @@moves_translations[id]
    return nil
  end
  
  # Obtiene el nombre traducido de un objeto
  def self.getItemTranslation(id)
    return @@items_translations[id] if @@items_translations[id]
    return nil
  end
  
  # Obtiene el nombre traducido de una habilidad
  def self.getAbilityTranslation(id)
    return @@abilities_translations[id] if @@abilities_translations[id]
    return nil
  end
  
  # Verifica si hay una localización activa
  def self.isActive?
    return !@@current_locale.nil?
  end
  
  # Obtiene la localización actual [lang_index, variant_index]
  def self.getCurrentLocale
    return @@current_locale
  end
  
  # Obtiene el nombre de la localización actual
  def self.getCurrentLocaleName
    return @@current_locale_name
  end
  
  # Obtiene las variantes disponibles para un idioma
  def self.getLocaleVariants(lang_index)
    return [] if !LOCALIZATION[lang_index]
    return [] if !LOCALIZATION[lang_index].is_a?(Array)
    
    variants = []
    LOCALIZATION[lang_index].each_with_index do |variant, i|
      next if !variant || !variant.is_a?(Array) || variant.length < 2
      variants.push([variant[0], i]) # [nombre, índice]
    end
    
    return variants
  end
end

#===============================================================================
# Parches para PBMoves
#===============================================================================
class << PBMoves
  alias _localization_getName getName unless method_defined?(:_localization_getName)
  def getName(id)
    if LocalizationSystem.isActive?
      translated = LocalizationSystem.getMoveTranslation(id)
      return translated if translated
    end
    return _localization_getName(id)
  end
end

#===============================================================================
# Parches para PBItems
#===============================================================================
class << PBItems
  alias _localization_getName getName unless method_defined?(:_localization_getName)
  def getName(id)
    if LocalizationSystem.isActive?
      translated = LocalizationSystem.getItemTranslation(id)
      return translated if translated
    end
    return _localization_getName(id)
  end
end

#===============================================================================
# Parches para PBAbilities
#===============================================================================
class << PBAbilities
  alias _localization_getName getName unless method_defined?(:_localization_getName)
  def getName(id)
    if LocalizationSystem.isActive?
      translated = LocalizationSystem.getAbilityTranslation(id)
      return translated if translated
    end
    return _localization_getName(id)
  end
end


#===============================================================================
# Funciones de ayuda para cargar/guardar la configuración
#===============================================================================
# Clase para almacenar la configuración del sistema
class PokemonSystem
  attr_accessor :locale
  
  alias _localization_initialize initialize unless method_defined?(:_localization_initialize)
  def initialize
    _localization_initialize
    @locale = nil
  end
end

#===============================================================================
# Función auxiliar para obtener nombres de variantes del idioma actual
#===============================================================================
def pbGetCurrentLanguageLocaleNames
  lang_index = $PokemonSystem.language
  variants = LocalizationSystem.getLocaleVariants(lang_index)
  options = []
  variants.each do |variant|
    options.push(variant[0]) # variant[0] es el nombre corto (ej: "ES", "LA")
  end
  return options
end

#===============================================================================
# Opción de Localización para el Menú de Opciones
#===============================================================================
MenuHandlers.add(:options_menu, :localization, {
  "name"        => _INTL("Localización"),
  "order"       => LANGUAGES.length > 1 ? 2 : 115,
  "type"        => SingleValueOption,
  "parameters"  => pbGetCurrentLanguageLocaleNames,
  "description" => _INTL("Elige la localización que prefieras para los nombres de movimientos, objetos y habilidades."),
  "condition"   => proc { next pbGetCurrentLanguageLocaleNames.length > 0 },
  "get_proc"    => proc { 
    current = LocalizationSystem.getCurrentLocale
    # Devolver el índice de la variante actual
    next current[1] if current && current[0]==($PokemonSystem ? $PokemonSystem.language : 0)
    next 0 
  },
  "set_proc"    => proc { |value, _scene|
    lang_index = $PokemonSystem ? $PokemonSystem.language : 0
    if LocalizationSystem.loadLocale(lang_index, value)
      $PokemonSystem.locale = [lang_index, value]
    else # Si falla la carga, limpiar
      LocalizationSystem.clearLocale
      $PokemonSystem.locale = nil
    end
  }
})

#===============================================================================
# Recargar localización al cargar partida
#===============================================================================
class PokemonLoad
  alias _localization_pbStartLoadScreen pbStartLoadScreen unless method_defined?(:_localization_pbStartLoadScreen)
  def pbStartLoadScreen
    _localization_pbStartLoadScreen
    if $PokemonSystem && $PokemonSystem.locale
      locale = $PokemonSystem.locale
      LocalizationSystem.loadLocale(locale[0], locale[1]) if locale.is_a?(Array) && locale.length == 2
    end
  end
end

#===============================================================================
# Recargar localización al cambiar de idioma
#===============================================================================
def getLangs
  commands=[]
  for lang in LANGUAGES
    commands.push(lang[0])
  end
  return commands
end

MenuHandlers.add(:options_menu, :language, {
  "name"        => _INTL("Idioma"),
  "order"       => 1,
  "type"        => SingleValueOption,
  "parameters"  => getLangs,
  "description" => _INTL("Elige el idioma que prefieras."),
  "condition"   => proc { next LANGUAGES.length > 1 },
  "get_proc"    => proc { next $PokemonSystem.language },
  "set_proc"    => proc { |value, scene| 
    old_lang = $PokemonSystem.language
    next if old_lang == value  # No hacer nada si no cambió
    
    $PokemonSystem.language = value
    pbLoadMessages("Data/" + LANGUAGES[value][1])
    
    # Cargar localización automáticamente
    variants = LocalizationSystem.getLocaleVariants(value)
    if variants.length > 0
      LocalizationSystem.loadLocale(value, 0)
      $PokemonSystem.locale = [value, 0]
    else
      LocalizationSystem.clearLocale
      $PokemonSystem.locale = nil
    end
    # Refrescar la escena sin cerrar y reabrir
    scene.pbEndScene
    scene.pbStartScene(scene.in_load_screen)
    scene.pbOptions    
  }
})