################################################################################
# Las Mega Evoluciones y Reversiones Primigenias son tratadas como cambios de
# forma en Essentials. El código de abajo es poco más que lo que ya estaba en la
# sección del script Pokemon_MultipleForms, pero específicamente para las
# Mega Evoluciones y Reversiones Primigenias.
################################################################################
class PokeBattle_Pokemon
   def hasMegaForm?
     v=MultipleForms.call("getMegaForm",self)
     return v!=nil
   end

   def isMega?
     v=MultipleForms.call("getMegaForm",self)
     return v!=nil && v==@form
   end

   def makeMega
     v=MultipleForms.call("getMegaForm",self)
     self.form=v if v!=nil
   end

   def makeUnmega
    v = MultipleForms.call("getUnmegaForm",self)
      if v!=nil; self.form = v
       elsif isMega?; self.form = 0
      end
   end

   def megaName
     v=MultipleForms.call("getMegaName",self)
     return (v!=nil) ? v : _INTL("Mega {1}",PBSpecies.getName(self.species))
   end

   def megaMessage
     v=MultipleForms.call("megaMessage",self)
     return (v!=nil) ? v : 0   # 0=mensaje por defecto, 1=mensaje de Rayquaza
   end

   def isUltra?
     v=MultipleForms.call("getUltraForm",self)
     return v!=nil && v==@form
   end

   def makeUnUltra
     if isUltra?
       return self.form = @startform
     end
     return false
   end

   def hasPrimalForm?
     v=MultipleForms.call("getPrimalForm",self)
     return v!=nil
   end

   def isPrimal?
     v=MultipleForms.call("getPrimalForm",self)
     return v!=nil && v==@form
   end

   def makePrimal
     v=MultipleForms.call("getPrimalForm",self)
     self.form=v if v!=nil
   end

   def makeUnprimal
    v = MultipleForms.call("getUnprimalForm",self)
    if v!=nil; self.form = v
      elsif isPrimal?; self.form = 0
    end
   end

   def revertOtherForms
    if isConst?(self.species,PBSpecies,:GRENINJA) ||
        isConst?(self.species,PBSpecies,:MIMIKYU)
        self.form=0
    elsif isConst?(self.species,PBSpecies,:ZYGARDE)
      if $zygardeform>=0
         self.form=$zygardeform
         $zygardeform=-1
       elsif self.form==2  # If caught a Full Forme
         self.form=rand(2)
      end
    elsif self.isTera?
        self.makeUntera
    end
  end
 end

 # Mega Evoluciones XY ############################################################

 MultipleForms.register(:VENUSAUR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:VENUSAURITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,100,123,80,122,120] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:THICKFAT),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 24 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1555 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:CHARIZARD,{
 "getMegaForm"=>proc{|pokemon|
    next 2 if isConst?(pokemon.item,PBItems,:CHARIZARDITEX)
    next 1 if isConst?(pokemon.item,PBItems,:CHARIZARDITEY)
    next
 },
 "getMegaName"=>proc{|pokemon|
    next _INTL("Mega Charizard X") if pokemon.form==2
    next _INTL("Mega Charizard Y") if pokemon.form==1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [78,130,111,100,130,85] if pokemon.form==2
    next [78,104,78,100,159,115] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:DRAGON) if pokemon.form==2
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:TOUGHCLAWS),0]] if pokemon.form==2
    next [[getID(PBAbilities,:DROUGHT),0]] if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1105 if pokemon.form==2
    next 1005 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:BLASTOISE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BLASTOISINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [79,103,120,78,135,115] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:MEGALAUNCHER),0]] if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1011 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:ALAKAZAM,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:ALAKAZITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [55,50,65,150,175,95] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:TRACE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 12 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GENGAR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GENGARITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [60,65,80,130,170,95] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SHADOWTAG),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 14 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:KANGASKHAN,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:KANGASKHANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [105,125,100,100,60,100] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:PARENTALBOND),0]] if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1000 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:PINSIR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:PINSIRITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,155,120,105,65,90] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:FLYING) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:AERILATE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 17 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 590 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GYARADOS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GYARADOSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [95,155,109,81,70,130] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:DARK) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:MOLDBREAKER),0]] if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 3050 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:AERODACTYL,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:AERODACTYLITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,135,85,150,70,95] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:TOUGHCLAWS),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 21 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 790 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:MEWTWO,{
 "getMegaForm"=>proc{|pokemon|
    next 2 if isConst?(pokemon.item,PBItems,:MEWTWONITEX)
    next 1 if isConst?(pokemon.item,PBItems,:MEWTWONITEY)
    next
 },
 "getMegaName"=>proc{|pokemon|
    next _INTL("Mega Mewtwo X") if pokemon.form==2
    next _INTL("Mega Mewtwo Y") if pokemon.form==1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [106,190,100,130,154,100] if pokemon.form==2
    next [106,150,70,140,194,120] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:FIGHTING) if pokemon.form==2
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:STEADFAST),0]] if pokemon.form==2
    next [[getID(PBAbilities,:INSOMNIA),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 23 if pokemon.form==2
    next 15 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1270 if pokemon.form==2
    next 330 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:AMPHAROS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:AMPHAROSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [90,95,105,45,165,110] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:DRAGON) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:MOLDBREAKER),0]] if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SCIZOR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SCIZORITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,150,140,75,65,100] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:TECHNICIAN),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 20 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1250 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:HERACROSS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:HERACRONITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,185,115,75,40,105] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SKILLLINK),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 17 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 625 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:HOUNDOOM,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:HOUNDOOMINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [75,90,90,115,140,90] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SOLARPOWER),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 19 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 495 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:TYRANITAR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:TYRANITARITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [100,164,150,71,95,120] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SANDSTREAM),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 25 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 2550 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:BLAZIKEN,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BLAZIKENITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,160,80,100,130,80] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SPEEDBOOST),0]] if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GARDEVOIR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GARDEVOIRITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [68,85,65,100,165,135] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:PIXILATE),0]] if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:MAWILE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:MAWILITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [50,105,125,50,55,95] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:HUGEPOWER),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 10 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 235 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:AGGRON,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:AGGRONITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,140,230,50,60,80] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:STEEL) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:FILTER),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 22 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 3950 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:MEDICHAM,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:MEDICHAMITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [60,100,85,100,80,85] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:PUREPOWER),0]] if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:MANECTRIC,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:MANECTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,75,80,135,135,80] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:INTIMIDATE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 18 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 440 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:BANETTE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BANETTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [64,165,75,75,93,83] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:PRANKSTER),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 12 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 130 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:ABSOL,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:ABSOLITE)
    next 1 if isConst?(pokemon.item,PBItems,:ABSOLITEZ)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,150,60,115,115,60] if pokemon.form==1
    next [65,154,60,151,75,60] if pokemon.form==2
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
    next
 },
  "type2"=>proc{|pokemon|
    next getID(PBTypes,:GHOST) if pokemon.form==2
    next
 },
 "weight"=>proc{|pokemon|
    next 490 if pokemon.form >= 2
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GARCHOMP,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GARCHOMPITE)
    next 1 if isConst?(pokemon.item,PBItems,:GARCHOMPITEZ)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [108,170,115,92,120,95] if pokemon.form==1
    next [108,130,85,151,141,85] if pokemon.form==2
    next
 },
   "type2"=>proc{|pokemon|
    next getID(PBTypes,:DRAGON) if pokemon.form==2
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SANDFORCE),0]] if pokemon.form==1
    next
 },
"weight"=>proc{|pokemon|
    next 990 if pokemon.form >= 2
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:LUCARIO,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:LUCARIONITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,145,88,112,140,70] if pokemon.form==1
    next [70,100,70,151,164,70] if pokemon.form==2
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:ADAPTABILITY),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 13 if pokemon.form >= 1
    next
 },
 "weight"=>proc{|pokemon|
    next 575 if pokemon.form==1
    next 494 if pokemon.form==2
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:ABOMASNOW,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:ABOMASITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [90,132,105,30,132,105] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SNOWWARNING),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 27 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1850 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 # Mega Evoluciones ORAS ##########################################################

 MultipleForms.register(:BEEDRILL,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BEEDRILLITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,150,40,145,15,80] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:ADAPTABILITY),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 14 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 405 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:PIDGEOT,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:PIDGEOTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [83,80,80,121,135,80] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:NOGUARD),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 22 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 505 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:STEELIX,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:STEELIXITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [75,125,230,30,55,95] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SANDFORCE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 105 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 7400 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SCEPTILE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SCEPTILITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,110,75,145,145,85] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:DRAGON) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:LIGHTNINGROD),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 19 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 552 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SWAMPERT,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SWAMPERTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [100,150,110,70,95,110] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SWIFTSWIM),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 19 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1020 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SABLEYE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SABLENITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [50,85,125,20,85,115] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1610 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SHARPEDO,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SHARPEDONITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,140,70,105,110,65] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:STRONGJAW),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 25 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1303 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:CAMERUPT,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:CAMERUPTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,120,100,20,145,105] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SHEERFORCE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 25 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 3205 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:ALTARIA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:ALTARIANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [75,110,110,80,110,105] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:FAIRY) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:PIXILATE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 15 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GLALIE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GLALITITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,120,80,100,120,80] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:REFRIGERATE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 21 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 3502 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SALAMENCE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SALAMENCITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [95,145,130,120,120,90] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:AERILATE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 18 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1126 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:METAGROSS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:METAGROSSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,145,150,110,105,110] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:TOUGHCLAWS),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 25 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 9429 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:LATIAS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:LATIASITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,100,120,110,140,150] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 18 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 520 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:LATIOS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:LATIOSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,130,100,110,160,120] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 23 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 700 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:RAYQUAZA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if pokemon.hasMove?(:DRAGONASCENT)
    next
 },
 "megaMessage"=>proc{|pokemon|
    next 1
 },
 "getBaseStats"=>proc{|pokemon|
    next [105,180,100,115,180,100] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:DELTASTREAM),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 108 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 3920 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:LOPUNNY,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:LOPUNNITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,136,94,135,54,96] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:FIGHTING) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:SCRAPPY),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 13 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 283 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GALLADE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GALLADITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [68,165,95,110,65,115] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:INNERFOCUS),0]] if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 564 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:AUDINO,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:AUDINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [103,60,126,50,80,126] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:FAIRY) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:HEALER),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 15 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 320 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:DIANCIE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:DIANCITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [50,160,110,110,160,110] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 11 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 278 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:CLEFABLE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:CLEFABLITE)
    next
 },
"type2"=>proc{|pokemon|
    next getID(PBTypes,:FLYING) if pokemon.form==1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [95,80,93,70,135,110] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 17 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 423 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:VICTREEBEL,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:VICTREEBELITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,125,85,70,135,95] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 45 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1255 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:STARMIE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:STARMINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [60,140,105,120,130,105] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 23 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 800 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:DRAGONITE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:DRAGONINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [60,140,105,120,130,105] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 22 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 2900 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })


 MultipleForms.register(:MEGANIUM,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:MEGANIUMITE)
    next
 },
"type2"=>proc{|pokemon|
    next getID(PBTypes,:FAIRY) if pokemon.form==1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,92,115,80,143,115] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 24 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 2010 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:FERALIGATR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:FERALIGITE)
    next
 },
  "type2"=>proc{|pokemon|
    next getID(PBTypes,:DRAGON) if pokemon.form==1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [85,160,125,78,89,78] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 23 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1088 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SKARMORY,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SKARMORITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,140,110,110,40,100] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 17 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 404 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:FROSLASS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:FROSLASSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,80,70,120,140,100] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 26 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 299 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:EMBOAR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:EMBOARITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [110,148,75,75,110,110] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 18 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1803 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:EXCADRILL,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:EXCADRITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [110,165,100,103,65,65] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 9 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 600 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SCOLIPEDE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SCOLIPITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [60,140,149,62,75,99] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 32 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 2305 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:SCRAFTY,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SCRAFTINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,130,135,68,55,135] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 11 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 310 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:EELEKTROSS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:EELEKTROSSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [85,145,80,80,135,90] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 30 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1800 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:CHANDELURE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:CHANDELURITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [60,75,110,90,175,110] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "height"=>proc{|pokemon|
    next 25 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 696 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:CHESNAUGHT,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:CHESNAUGHTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [88,137,172,44,74,115] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:DELPHOX,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:DELPHOXITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [75,69,72,159,125,134] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GRENINJA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GRENINJITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [72,125,77,142,133,81] if pokemon.form==1
    next [72,145,67,132,153,71] if pokemon.form==2 #Greninja-Ash
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:PYROAR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:PYROARITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [86,88,92,126,129,86] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 15 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 933 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:MALAMAR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:MALAMARITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [86,102,88,88,98,120] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 29 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 698 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:BARBARACLE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BARBARACITE)
    next
 },
"type2"=>proc{|pokemon|
    next getID(PBTypes,:FIGHTING) if pokemon.form==1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [72,140,130,88,64,106] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 22 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1000 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:DRAGALGE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:DRAGALGITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,85,105,44,132,163] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 21 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 1003 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:HAWLUCHA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:HAWLUCHANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [78,137,100,118,74,93] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 10 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 25 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })


MultipleForms.register(:DRAMPA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:DRAMPANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [78,85,110,36,160,116] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 3 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 2405 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:FALINKS,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:FALINKSITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,135,135,100,70,65] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
  "height"=>proc{|pokemon|
    next 16 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 990 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:CHIMECHO,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:CHIMECHITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [75,50,110,65,135,120] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:STEEL) if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 80 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 12 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:STARAPTOR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:STARAPTITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [85,140,100,110,60,90] if pokemon.form==1
    next
 },
 "type1"=>proc{|pokemon|
    next getID(PBTypes,:FIGHTING) if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 500 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 19 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:HEATRAN,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:HEATRANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [91,120,106,67,175,141] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 570 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 28 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:DARKRAI,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:DARKRANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [70,120,130,85,165,130] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 240 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 30 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:GOLURK,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GOLURKITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [89,159,105,55,70,105] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 330 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 40 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:MEOWSTIC,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:MEOWSTICITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [74,48,76,124,143,101] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 101 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 8 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:CRABOMINABLE,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:CRABOMINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [97,157,122,33,62,107] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 2528 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 26 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GOLISOPOD,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GOLISOPITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [75,150,175,40,70,120] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:STEEL) if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 1480 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 23 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:MAGEARNA,{
 "getMegaForm"=>proc{|pokemon|
    next 2 if isConst?(pokemon.item,PBItems,:MAGEARNITE)
    next 3 if isConst?(pokemon.item,PBItems,:MAGEARNITE) if pokemon.form== 1
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [80,125,115,95,170,115] if pokemon.form >= 2
    
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form >= 2
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 2481 if pokemon.form >= 2
    next
 },
 "height"=>proc{|pokemon|
    next 13 if pokemon.form >= 2
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 1 if pokemon.form== 3
   next 0
 }
 })

 MultipleForms.register(:ZERAORA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:ZERAORITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [88,157,75,153,147,80] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:SCOVILLAIN,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:SCOVILLAINITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [65,138,85,75,138,85] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 220 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 12 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:GLIMMORA,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:GLIMMORANITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [83,90,105,101,150,96] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 770 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 28 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

MultipleForms.register(:BAXCALIBUR,{
 "getMegaForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BAXCALIBRITE)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [115,175,117,87,105,101] if pokemon.form==1
    next
 },
 #"getAbilityList"=>proc{|pokemon|
 #   next [[getID(PBAbilities,:MAGICBOUNCE),0]] if pokemon.form==1
 #   next
 #}, #No se sabe cual es la hab oficial.
 "weight"=>proc{|pokemon|
    next 3150 if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 21 if pokemon.form==1
    next
 },
 "getUnmegaForm"=>proc{|pokemon|
   next 0
 }
 })

 ################################################################################
 ######################### Regresión Primigenia #################################
 ################################################################################

 MultipleForms.register(:KYOGRE,{
 "getPrimalForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:BLUEORB)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [100,150,90,90,180,160] if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:PRIMORDIALSEA),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 98 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 4300 if pokemon.form==1
    next
 },
 "getUnprimalForm"=>proc{|pokemon|
   next 0
 }
 })

 MultipleForms.register(:GROUDON,{
 "getPrimalForm"=>proc{|pokemon|
    next 1 if isConst?(pokemon.item,PBItems,:REDORB)
    next
 },
 "getBaseStats"=>proc{|pokemon|
    next [100,180,160,90,150,90] if pokemon.form==1
    next
 },
 "type2"=>proc{|pokemon|
    next getID(PBTypes,:FIRE) if pokemon.form==1
    next
 },
 "getAbilityList"=>proc{|pokemon|
    next [[getID(PBAbilities,:DESOLATELAND),0]] if pokemon.form==1
    next
 },
 "height"=>proc{|pokemon|
    next 50 if pokemon.form==1
    next
 },
 "weight"=>proc{|pokemon|
    next 9997 if pokemon.form==1
    next
 },
 "getUnprimalForm"=>proc{|pokemon|
   next 0
 }
 })
