#===============================================================================
# Formas Regionales
# Añade dentro del array los mapas donde puedan aparecer las formas regionales.
#===============================================================================
ALOLA_MAPS  = [32]
GALAR_MAPS  = [32]
HISUI_MAPS  = [33]
PALDEA_MAPS = [34]

########################################################################
######################### Formas Alola #################################
########################################################################
# RATTATA

MultipleForms.register(:RATTATA,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:GLUTTONY),0],
         [getID(PBAbilities,:HUSTLE),1],
         [getID(PBAbilities,:THICKFAT),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:TAILWHIP],[4,:QUICKATTACK],[7,:FOCUSENERGY],
                     [10,:BITE],[13,:PURSUIT],[16,:HYPERFANG],[19,:ASSURANCE],
                     [22,:CRUNCH],[25,:SUCKERPUNCH],[28,:SUPERFANG],[31,:DOUBLEEDGE],
                     [34,:ENDEAVOR]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:ICEBEAM,:BLIZZARD,
                     :PROTECT,:RAINDANCE,:FRUSTRATION,:RETURN,:SHADOWBALL,
                     :DOUBLETEAM,:SLUDGEBOMB,:TORMENT,:FACADE,:REST,:ATTRACT,
                     :THIEF,:ROUND,:QUASH,:EMBARGO,:SHADOWCLAW,:GRASSKNOT,
                     :SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,:SNARL,:DARKPULSE,
                     :CONFIDE,:ICYWIND,:ENDEAVOR,:ZENHEADBUTT,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:SUPERFANG,:UPROAR,
                     :CRUNCH,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# RATICATE

MultipleForms.register(:RATICATE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [75,71,70,77,40,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:GLUTTONY),0],
         [getID(PBAbilities,:HUSTLE),1],
         [getID(PBAbilities,:THICKFAT),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCARYFACE],[1,:TACKLE],[1,:SWORDSDANCE],[1,:TAILWHIP],[4,:QUICKATTACK],[7,:FOCUSENERGY],
                     [10,:BITE],[13,:PURSUIT],[16,:HYPERFANG],[19,:ASSURANCE],
                     [24,:CRUNCH],[29,:SUCKERPUNCH],[34,:SUPERFANG],[39,:DOUBLEEDGE],
                     [44,:ENDEAVOR]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ROAR,:TOXIC,:BULKUP,:VENOSHOCK,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:ICEBEAM,:BLIZZARD,
                     :HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:RETURN,:SHADOWBALL,
                     :DOUBLETEAM,:SLUDGEWAVE,:SLUDGEBOMB,:TORMENT,:FACADE,:REST,:ATTRACT,
                     :THIEF,:ROUND,:QUASH,:EMBARGO,:SHADOWCLAW,:GIGAIMPACT,:SWORDSDANCE,:GRASSKNOT,
                     :SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,:SNARL,:DARKPULSE,
                     :CONFIDE,:ICYWIND,:ENDEAVOR,:ZENHEADBUTT,:STOMPINGTANTRUM,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:SUPERFANG,:UPROAR,
                     :CRUNCH,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# RAICHU

MultipleForms.register(:RAICHU,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 3
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==3
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,85,50,110,95,85] if pokemon.form==3
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SURGESURFER),0]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==3
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PSYCHIC],[1,:SPEEDSWAP],[1,:THUNDERSHOCK],[1,:QUICKATTACK],[1,:TAILWHIP],[1,:THUNDERBOLT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :PSYSHOCK,:CALMMIND,:TOXIC,:HIDDENPOWER,:HYPERBEAM,:LIGHTSCREEN,
                     :PROTECT,:RAINDANCE,:SAFEGUARD,:FRUSTRATION,:THUNDERBOLT,:THUNDER,:RETURN,:DIG,:PSYCHIC,
                     :BRICKBREAK,:DOUBLETEAM,:REFLECT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:ECHOEDVOICE,
                     :FOCUSBLAST,:FLING,:CHARGEBEAM,:GIGAIMPACT,:FLASH,:VOLTSWITCH,:THUNDERWAVE,:GRASSKNOT,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:WILDCHARGE,:SECRETPOWER,:CONFIDE,:KNOCKOFF,:FOCUSPUNCH,:RECYCLE,
                     :ALLYSWITCH,:COVET,:ELECTROWEB,:HELPINGHAND,:LASERFOCUS,:LASTRESORT,:MAGICCOAT,:MAGICROOM,:MAGNETRISE,
                     :SIGNALBEAM,:SHOCKWAVE,:SNATCH,:SNORE,:SUPERFANG,:TELEKINESIS,:THUNDERPUNCH,:UPROAR,
                     :ELECTROBALL,:NASTYPLOT,:IRONTAIL,:RISINGVOLTAGE,:EXPANDINGFORCE,:VOLTTACKLE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SANDSHREW

MultipleForms.register(:SANDSHREW,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [50,75,90,40,10,35] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SLUSHRUSH),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCRATCH],[1,:DEFENSECURL],[3,:BIDE],[5,:POWDERSNOW],[7,:ICEBALL],[9,:RAPIDSPIN],
                     [11,:FURYCUTTER],[14,:METALCLAW],[17,:SWIFT],[20,:FURYSWIPES],[23,:IRONDEFENSE],
                     [26,:SLASH],[30,:IRONHEAD],[34,:GYROBALL],[38,:SWORDSDANCE],[42,:HAIL],
                     [46,:BLIZZARD]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :HONECLAWS,:TOXIC,:HAIL,:HIDDENPOWER,:SUNNYDAY,:BLIZZARD,
                     :PROTECT,:SAFEGUARD,:FRUSTRATION,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :FLING,:SHADOWCLAW,:GYROBALL,:SWORDSDANCE,:BULLDOZE,:FROSTBREATH,:ROCKSLIDE,:XSCISSOR,
                     :POISONJAB,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:ICYWIND,:KNOCKOFF,:FOCUSPUNCH,:IRONHEAD,
                     :AQUATAIL,:AURORAVEIL,:COVET,:ICEPUNCH,:SNORE,:SUPERFANG,:WORKUP,
                     :ICICLESPEAR,:LEECHLIFE,:IRONTAIL,:STEELBEAM,:TRIPLEAXEL,:STEELROLLER]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SANDSLASH

MultipleForms.register(:SANDSLASH,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [75,100,120,65,25,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SLUSHRUSH),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ICICLESPEAR],[1,:ICICLECRASH],[1,:METALBURST],[1,:METALCLAW],[1,:ICEBALL],[1,:SLASH],[1,:DEFENSECURL]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :HONECLAWS,:TOXIC,:HAIL,:HIDDENPOWER,:SUNNYDAY,:BLIZZARD,:HYPERBEAM,
                     :PROTECT,:SAFEGUARD,:FRUSTRATION,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:FOCUSBLAST,
                     :FLING,:SHADOWCLAW,:GIGAIMPACT,:GYROBALL,:SWORDSDANCE,:BULLDOZE,:FROSTBREATH,:ROCKSLIDE,:XSCISSOR,
                     :POISONJAB,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:ICYWIND,:KNOCKOFF,:FOCUSPUNCH,:IRONHEAD,
                     :AQUATAIL,:AURORAVEIL,:COVET,:DRILLRUN,:ICEPUNCH,:SNORE,:SUPERFANG,:WORKUP,
                     :ICICLESPEAR,:LEECHLIFE,:IRONTAIL,:STEELBEAM,:TRIPLEAXEL,:STEELROLLER]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# VULPIX

MultipleForms.register(:VULPIX,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SNOWWARNING),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POWDERSNOW],[4,:TAILWHIP],[7,:ROAR],[9,:BABYDOLLEYES],[10,:ICESHARD],[12,:CONFUSERAY],
                     [15,:ICYWIND],[18,:PAYBACK],[20,:MIST],[23,:FEINTATTACK],[26,:HEX],
                     [28,:AURORABEAM],[31,:EXTRASENSORY],[34,:SAFEGUARD],[36,:ICEBEAM],[39,:IMPRISON],
                     [42,:BLIZZARD],[44,:GRUDGE],[47,:CAPTIVATE],[50,:SHEERCOLD]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ROAR,:TOXIC,:HAIL,:HIDDENPOWER,:ICEBEAM,:BLIZZARD,:PROTECT,:RAINDANCE,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,:DOUBLETEAM,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :PAYBACK,:PSYCHUP,:FROSTBREATH,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:SECRETPOWER,:DARKPULSE,
                     :CONFIDE,:ICYWIND,:FOULPLAY,:PAINSPLIT,:ZENHEADBUTT,
                     :AQUATAIL,:AURORAVEIL,:COVET,:HEALBELL,:ROLEPLAY,:SNORE,
                     :SPITE,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# NINETALES

MultipleForms.register(:NINETALES,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[22]                  # Map IDs for second form
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FAIRY) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [73,67,75,109,81,100] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SNOWCLOAK),0],
         [getID(PBAbilities,:SNOWWARNING),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:DAZZLINGGLEAM],[1,:MOONBLAST],[1,:NASTYPLOT],[1,:IMPRISON],[1,:ICESHARD],[1,:ICEBEAM],[1,:CONFUSERAY],[1,:SAFEGUARD]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :PSYSHOCK,:CALMIND,:ROAR,:TOXIC,:HAIL,:HIDDENPOWER,:ICEBEAM,:BLIZZARD,:HYPERBEAM,:PROTECT,:RAINDANCE,
                     :SAFEGUARD,:FRUSTRATION,:RETURN,:DOUBLETEAM,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :PAYBACK,:GIGAIMPACT,:PSYCHUP,:FROSTBREATH,:DREAMEATER,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:SECRETPOWER,:DARKPULSE,
                     :DAZZLINGGLEAM,:CONFIDE,:ICYWIND,:FOULPLAY,:PAINSPLIT,:ZENHEADBUTT,
                     :AQUATAIL,:AURORAVEIL,:COVET,:HEALBELL,:LASERFOCUS,:ROLEPLAY,:SNORE,:SPITE,:WONDERROOM,
                     :NASTPLOT,:SPITE,:IRONTAIL,:TRIPLEAXEL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DIGLETT

MultipleForms.register(:DIGLETT,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [10,55,30,90,35,45] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SANDVEIL),0],
         [getID(PBAbilities,:TANGLINGHAIR),1],
         [getID(PBAbilities,:SANDFORCE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:METALCLAW],[1,:SANDATTACK],[4,:GROWL],[7,:ASTONISH],[10,:MUDSLAP],[14,:MAGNITUDE],
                     [18,:BULLDOZE],[22,:SUCKERPUNCH],[25,:MUDBOMB],[28,:EARTHPOWER],[31,:DIG],
                     [35,:IRONHEAD],[39,:EARTHQUAKE],[43,:FISSURE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:PROTECT,:FRUSTRATION,:EARTHQUAKE,:DIG,:RETURN,:DOUBLETEAM,
                     :SLUDGEBOMB,:SANDSTORM,:ROCKTOMB,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:SHADOWCLAW,:BULLDOZE,:ROCKSLIDE,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,:WORKUP,
                     :FLASHCANNON,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:IRONHEAD,:STOMPINGTANTRUM,:SNORE,
                     :EARTHPOWER,:STEELBEAM,:SCORCHINGSANDS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DUGTRIO

MultipleForms.register(:DUGTRIO,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [35,100,60,110,50,70] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SANDVEIL),0],
         [getID(PBAbilities,:TANGLINGHAIR),1],
         [getID(PBAbilities,:SANDFORCE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SANDTOMB],[1,:METALCLAW],[1,:SANDATTACK],[1,:ROTOTILLER],[1,:TRIATTACK],[1,:NIGHTSLASH],
                     [4,:GROWL],[7,:ASTONISH],[10,:MUDSLAP],[14,:MAGNITUDE],
                     [18,:BULLDOZE],[22,:SUCKERPUNCH],[25,:MUDBOMB],[30,:EARTHPOWER],[35,:DIG],
                     [41,:IRONHEAD],[47,:EARTHQUAKE],[53,:FISSURE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:HYPERBEAM,:PROTECT,:FRUSTRATION,:EARTHQUAKE,:DIG,:RETURN,:DOUBLETEAM,
                     :SLUDGEWAVE,:SLUDGEBOMB,:SANDSTORM,:ROCKTOMB,:AERIALACE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:SHADOWCLAW,:GIGAIMPACT,:STONEEDGE,:BULLDOZE,:ROCKSLIDE,:SWAGGER,:SLEEPTALK,:SUBSTITUTE,
                     :FLASHCANNON,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:IRONHEAD,:STOMPINGTANTRUM,:WORKUP,:SNORE,
                     :EARTHPOWER,:TRIATTACK,:STEELBEAM,:SCORCHINGSANDS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MEOWTH

MultipleForms.register(:MEOWTH,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   elsif $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 2
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:DARK)   # Forma Alola
   when 2; next getID(PBTypes,:STEEL)  # Forma Galar
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:DARK)   # Forma Alola
   when 2; next getID(PBTypes,:STEEL)  # Forma Galar
   end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0              # Forma Normal
   case pokemon.form
   when 1; next [40,35,35,90,50,40]     # Forma Alola
   when 2; next [50,65,55,40,40,40]     # Forma Galar
  end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:PICKUP),0],[getID(PBAbilities,:TECHNICIAN),1],[getID(PBAbilities,:RATTLED),2]] # Forma Alola
   when 2; next [[getID(PBAbilities,:PICKUP),0],[getID(PBAbilities,:TOUGHCLAWS),1],[getID(PBAbilities,:UNNERVE),2]] # Forma Galar
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCRATCH],[1,:GROWL],[6,:BITE],[9,:FAKEOUT],[14,:FURYSWIPES],[17,:SCREECH],
                     [22,:FEINTATTACK],[25,:TAUNT],[30,:PAYDAY],[33,:SLASH],[38,:NASTYPLOT],
                     [41,:ASSURANCE],[46,:CAPTIVATE],[49,:NIGHTSLASH],[50,:FEINT],[55,:DARKPULSE]]
   when 2; movelist=[[1,:FAKEOUT],[1,:GROWL],[4,:HONECLAWS],[8,:SCRATCH],[12,:PAYDAY],[16,:METALCLAW],
                     [20,:TAUNT],[24,:SWAGGER],[29,:FURYSWIPES],[32,:SCREECH],[36,:SLASH],
                     [40,:METALSOUND],[44,:THRASH]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:PROTECT,:RAINDANCE,:FRUSTRATION,:THUNDERBOLT,:THUNDER,:RETURN,
                     :SHADOWBALL,:DOUBLETEAM,:AERIALACE,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:QUASH,:EMBARGO,:SHADOWCLAW,:PAYBACK,:PSYCHUP,:DREAMEATER,:SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,
                     :DARKPULSE,:CONFIDE,:FOULPLAY,:ICYWIND,:SEEDBOMB,:KNOCKOFF,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:UPROAR,:WATERPULSE,:WORKUP,
                     :GUNKSHOT,:NASTYPLOT,:SPITE,:HYPERVOICE,:IRONTAIL,:LASHOUT]
   when 2; movelist=[# MTs y tutores
                     :DIG,:REST,:THIEF,:SNORE,:PROTECT,:ATTRACT,:FACADE,:RAINDANCE,:SUNNYDAY,
                     :UTURN,:PAYBACK,:SHADOWCLAW,:ROUND,:RETALIATE,:SWORDSDANCE,:THUNDERBOLT,
                     :THUNDER,:SUBSTITUTE,:SLEEPTALK,:IRONTAIL,:CRUNCH,:SHADOWBALL,:UPROAR,
                     :TAUNT,:HYPERVOICE,:IRONDEFENSE,:DARKPULSE,:GYROBALL,:SEEDBOMB,:GUNKSHOT,
                     :NASTYPLOT,:IRONHEAD,:FOULPLAY,:WORKUP,:PLAYROUGH,:THROATCHOP,:SWAGGER,
                     :COVET,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# PERSIAN

MultipleForms.register(:PERSIAN,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [65,60,60,115,75,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:FURCOAT),0],
         [getID(PBAbilities,:TECHNICIAN),1],
         [getID(PBAbilities,:RATTLED),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SWIFT],[1,:SCRATCH],[1,:GROWL],[1,:PLAYROUGH],[1,:SWITCHEROO],[1,:QUASH],
                     [6,:BITE],[9,:FAKEOUT],[14,:FURYSWIPES],[17,:SCREECH],
                     [22,:FEINTATTACK],[25,:TAUNT],[32,:POWERGEM],[37,:SLASH],[44,:NASTYPLOT],
                     [49,:ASSURANCE],[56,:CAPTIVATE],[61,:NIGHTSLASH],[65,:FEINT],[69,:DARKPULSE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :ROAR,:TOXIC,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:THUNDERBOLT,:THUNDER,:RETURN,
                     :SHADOWBALL,:DOUBLETEAM,:AERIALACE,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :ECHOEDVOICE,:QUASH,:EMBARGO,:SHADOWCLAW,:PAYBACK,:GIGAIMPACT,:PSYCHUP,:DREAMEATER,:SWAGGER,:SLEEPTALK,:UTURN,:SUBSTITUTE,
                     :SNARL,:DARKPULSE,:CONFIDE,:FOULPLAY,:ICYWIND,:SEEDBOMB,:KNOCKOFF,
                     :COVET,:LASTRESORT,:SHOCKWAVE,:SNATCH,:SNORE,:UPROAR,:WATERPULSE,:WORKUP,
                     :POWERGEM,:GUNKSHOT,:NASTYPLOT,:SPITE,:HYPERVOICE,:IRONTAIL,:PLAYROUGH,
                     :BURNINGJEALOUSY,:LASHOUT,:SKITTERSMACK]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GEODUDE

MultipleForms.register(:GEODUDE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MAGNETPULL),0],
         [getID(PBAbilities,:STURDY),1],
         [getID(PBAbilities,:GALVANIZE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:DEFENSECURL],[4,:CHARGE],[6,:ROCKPOLISH],[10,:ROLLOUT],[12,:SPARK],
                     [16,:ROCKTHROW],[18,:SMACKDOWN],[22,:THUNDERPUNCH],[24,:SELFDESTRUCT],
                     [28,:STEALTHROCK],[30,:ROCKBLAST],[34,:DISCHARGE],[36,:EXPLOSION],[40,:DOUBLEEDGE],
                     [42,:STONEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:PROTECT,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:FACADE,:REST,:ATTRACT,:ROUND,
                     :FLING,:CHARGEBEAM,:EXPLOSION,:ROCKPOLISH,:STONEEDGE,:VOLTSWITCH,:GYROBALL,:BULLDOZE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:NATUREPOWER,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:BLOCK,:FOCUSPUNCH,:SUPERPOWER,:BRUTALSWING,
                     :ELECTROWEB,:FIREPUNCH,:MAGNETRISE,:SNORE,:THUNDERPUNCH,
                     :EARTHPOWER,:ROCKBLAST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GRAVELER

MultipleForms.register(:GRAVELER,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MAGNETPULL),0],
         [getID(PBAbilities,:STURDY),1],
         [getID(PBAbilities,:GALVANIZE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:DEFENSECURL],[4,:CHARGE],[6,:ROCKPOLISH],[10,:ROLLOUT],[12,:SPARK],
                     [16,:ROCKTHROW],[18,:SMACKDOWN],[22,:THUNDERPUNCH],[24,:SELFDESTRUCT],
                     [30,:STEALTHROCK],[34,:ROCKBLAST],[40,:DISCHARGE],[44,:EXPLOSION],[50,:DOUBLEEDGE],
                     [54,:STONEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:PROTECT,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:FACADE,:REST,:ATTRACT,:ROUND,
                     :FLING,:CHARGEBEAM,:EXPLOSION,:ROCKPOLISH,:STONEEDGE,:VOLTSWITCH,:GYROBALL,:BULLDOZE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:NATUREPOWER,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:BLOCK,:FOCUSPUNCH,:SUPERPOWER,:BRUTALSWING,:STOMPINGTANTRUM,
                     :ALLYSWITCH,:ELECTROWEB,:FIREPUNCH,:MAGNETRISE,:SNORE,:THUNDERPUNCH,
                     :EARTHPOWER,:ROCKBLAST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GOLEM

MultipleForms.register(:GOLEM,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MAGNETPULL),0],
         [getID(PBAbilities,:STURDY),1],
         [getID(PBAbilities,:GALVANIZE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:DEFENSECURL],[4,:CHARGE],[6,:ROCKPOLISH],[10,:STEAMROLLER],[12,:SPARK],
                     [16,:ROCKTHROW],[18,:SMACKDOWN],[22,:THUNDERPUNCH],[24,:SELFDESTRUCT],
                     [30,:STEALTHROCK],[34,:ROCKBLAST],[40,:DISCHARGE],[44,:EXPLOSION],[50,:DOUBLEEDGE],
                     [54,:STONEEDGE],[60,:HEAVYSLAM]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ROAR,:TOXIC,:HIDDENPOWER,:SUNNYDAY,:HYPERBEAM,:PROTECT,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,
                     :BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:FACADE,:REST,:ATTRACT,:ROUND,:ECHOEDVOICE,:FOCUSBLAST,
                     :FLING,:CHARGEBEAM,:EXPLOSION,:GIGAIMPACT,:ROCKPOLISH,:STONEEDGE,:VOLTSWITCH,:GYROBALL,:BULLDOZE,:ROCKSLIDE,
                     :SWAGGER,:SLEEPTALK,:SUBSTITUTE,:WILDCHARGE,:NATUREPOWER,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:BLOCK,:FOCUSPUNCH,:SUPERPOWER,:IRONHEAD,:BRUTALSWING,:STOMPINGTANTRUM,
                     :ALLYSWITCH,:ELECTROWEB,:FIREPUNCH,:MAGNETRISE,:SHOCKWAVE,:SNORE,:THUNDERPUNCH,
                     :EARTHPOWER,:ROCKBLAST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GRIMER

MultipleForms.register(:GRIMER,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:POISONTOUCH),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:POWEROFALCHEMY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POUND],[1,:POISONGAS],[4,:HARDEN],[7,:BITE],[12,:DISABLE],[15,:ACIDSPRAY],
                     [18,:POISONFANG],[21,:MINIMIZE],[26,:FLING],[29,:KNOCKOFF],
                     [32,:CRUNCH],[37,:SCREECH],[40,:GUNKSHOT],[43,:ACIDARMOR],[46,:BELCH],
                     [48,:MEMENTO]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :TOXIC,:VENOSHOCK,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:PROTECT,:RAINDANCE,:FRUSTRATION,:RETURN,
                     :SHADOWBALL,:DOUBLETEAM,:SLUDGEWAVE,:FLAMETHROWER,:SLUDGEBOMB,:FIREBLAST,:ROCKTOMB,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :FLING,:QUASH,:EMBARGO,:EXPLOSION,:PAYBACK,:ROCKPOLISH,:STONEEDGE,:ROCKSLIDE,:INFESTATION,:POISONJAB,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:SNARL,:POWERUPPUNCH,:CONFIDE,:GIGADRAIN,:KNOCKOFF,:PAINSPLIT,:BRUTALSWING,
                     :FIREPUNCH,:GASTROACID,:ICEPUNCH,:SHOCKWAVE,:SNORE,:THUNDERPUNCH,
                     :GUNKSHOT,:CRUNCH,:SPITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MUK

MultipleForms.register(:MUK,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:POISONTOUCH),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:POWEROFALCHEMY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:VENOMDRENCH],[1,:POUND],[1,:POISONGAS],[4,:HARDEN],[7,:BITE],[12,:DISABLE],[15,:ACIDSPRAY],
                     [18,:POISONFANG],[21,:MINIMIZE],[26,:FLING],[29,:KNOCKOFF],
                     [32,:CRUNCH],[37,:SCREECH],[40,:GUNKSHOT],[46,:ACIDARMOR],[52,:BELCH],
                     [57,:MEMENTO]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :TOXIC,:VENOSHOCK,:HIDDENPOWER,:SUNNYDAY,:TAUNT,:HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:THUNDERBOLT,:RETURN,
                     :SHADOWBALL,:BRICKBREAK,:DOUBLETEAM,:SLUDGEWAVE,:FLAMETHROWER,:SLUDGEBOMB,:FIREBLAST,:ROCKTOMB,:TORMENT,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,
                     :FOCUSBLAST,:FLING,:QUASH,:EMBARGO,:EXPLOSION,:PAYBACK,:GIGAIMPACT,:ROCKPOLISH,:STONEEDGE,:ROCKSLIDE,:INFESTATION,:POISONJAB,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:SNARL,:DARKPULSE,:POWERUPPUNCH,:CONFIDE,:GIGADRAIN,:KNOCKOFF,:PAINSPLIT,:BLOCK,:FOCUSPUNCH,:RECYCLE,:BRUTALSWING,
                     :FIREPUNCH,:GASTROACID,:ICEPUNCH,:SHOCKWAVE,:SNORE,:THUNDERPUNCH,
                     :GUNKSHOT,:CRUNCH,:SPITE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# EXEGGUTOR

MultipleForms.register(:EXEGGUTOR,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DRAGON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,105,85,45,125,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:FRISK),0],
         [getID(PBAbilities,:HARVEST),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:DRAGONHAMMER],[1,:SEEDBOMB],[1,:CLAMP],[1,:HYPNOSIS],[1,:CONFUSION],[17,:PSYSHOCK],
                     [27,:EGGBOMB],[37,:WOODHAMMER],[47,:LEAFSTORM]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs y tutores
                     :PSYSHOCK,:TOXIC,:HIDDENPOWER,:SUNNYDAY,:HYPERBEAM,:LIGHTSCREEN,:PROTECT,:FRUSTRATION,:SOLARBEAM,:EARTHQUAKE,:RETURN,
                     :PSYCHIC,:BRICKBREAK,:DOUBLETEAM,:REFLECT,:FLAMETHROWER,:SLUDGEBOMB,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:ENERGYBALL,
                     :EXPLOSION,:GIGAIMPACT,:FLASH,:SWORDSDANCE,:PSYCHUP,:BULLDOZE,:DRAGONTAIL,:INFESTATION,:DREAMEATER,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:TRICKROOM,:SECRETPOWER,:NATUREPOWER,:CONFIDE,:GIGADRAIN,:SEEDBOMB,:KNOCKOFF,:BLOCK,:SKILLSWAP,:SUPERPOWER,:DRAGONPULSE,:IRONHEAD,:ZENHEADBUTT,:BRUTALSWING,:STOMPINGTANTRUM,
                     :GRAVITY,:LOWKICK,:SNORE,:SYNTHESIS,:TELEKINESIS,:WORRYSEED,
                     :LEAFSTORM,:OUTRAGE,:DRACOMETEOR,:IRONTAIL,:TERRAINPULSE,:GRASSYGLIDE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MAROWAK

MultipleForms.register(:MAROWAK,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && ALOLA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,105,85,45,125,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:CURSEDBODY),0],
         [getID(PBAbilities,:LIGHTNINGROD),1],
         [getID(PBAbilities,:ROCKHEAD),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SHADOWBONE],[1,:GROWL],[3,:TAILWHIP],[7,:BONECLUB],[11,:FLAMEWHEEL],[13,:LEER],
                     [17,:HEX],[21,:BONEMERANG],[23,:WILLOWISP],[33,:THRASH],[37,:FLING],[43,:STOMPINGTANTRUM],[49,:ENDEAVOR],
                     [53,:FLAREBLITZ],[59,:RETALIATE],[65,:BONERUSH]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :TOXIC,:HIDDENPOWER,:SUNNYDAY,:ICEBEAM,:BLIZZARD,:HYPERBEAM,:PROTECT,:RAINDANCE,:FRUSTRATION,:SMACKDOWN,:THUNDERBOLT,:THUNDER,:EARTHQUAKE,:RETURN,:DIG,
                     :SHADOWBALL,:BRICKBREAK,:DOUBLETEAM,:FLAMETHROWER,:SANDSTORM,:FIREBLAST,:ROCKTOMB,:AERIALACE,:FLAMECHARGE,:FACADE,:REST,:ATTRACT,:THIEF,:ROUND,:ECHOEDVOICE,
                     :FOCUSBLAST,:FALSESWIPE,:FLING,:INCINERATE,:WILLOWISP,:RETALIATE,:GIGAIMPACT,:STONEEDGE,:SWORDSDANCE,:BULLDOZE,:ROCKSLIDE,:DREAMEATER,:SWAGGER,
                     :SLEEPTALK,:SUBSTITUTE,:SECRETPOWER,:DARKPULSE,:POWERUPPUNCH,:CONFIDE,:STEALTHROCK,:IRONDEFENSE,:ICYWIND,:ENDEAVOR,:KNOCKOFF,:PAINSPLIT,:FOCUSPUNCH,:IRONHEAD,:BRUTALSWING,:STOMPINGTANTRUM,
                     :ALLYSWITCH,:FIREPUNCH,:HEATWAVE,:LASERFOCUS,:LOWKICK,:SNORE,:THUNDERPUNCH,:UPROAR,
                     :FLAREBLITZ,:SPITE,:EARTHPOWER,:OUTRAGE,:IRONTAIL,:BURNINGJEALOUSY,:POLTERGEIST,
                     :SCORCHINGSANDS]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

########################################################################
######################### Formas Galar #################################
########################################################################

# PONYTA

MultipleForms.register(:PONYTA,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [50,85,55,90,65,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:RUNAWAY),0],
         [getID(PBAbilities,:PASTELVEIL),1],
         [getID(PBAbilities,:ANTICIPATION),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:GROWL],[5,:TAILWHIP],[10,:CONFUSION],[15,:FAIRYWIND],
                     [20,:AGILITY],[25,:PSYBEAM],[30,:STOMP],[35,:HEALPULSE],[41,:TAKEDOWN],
                     [45,:DAZZLINGGLEAM],[50,:PSYCHIC],[55,:HEALINGWISH]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,:BOUNCE,:LOWKICK,
                     :ROUND,:SUBSTITUTE,:SLEEPTALK,:PSYCHIC,:IRONTAIL,:CALMMIND,
                     :ZENHEADBUTT,:STOREDPOWER,:ALLYSWITCH,:WILDCHARGE,:PLAYROUGH,
                     :DAZZLINGGLEAM,:HIGHHORSEPOWER,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# RAPIDASH

MultipleForms.register(:RAPIDASH,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FAIRY) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [65,100,70,105,80,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:RUNAWAY),0],
         [getID(PBAbilities,:PASTELVEIL),1],
         [getID(PBAbilities,:ANTICIPATION),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PSYCHOCUT],[1,:MEGAHORN],[1,:QUICKATTACK],[1,:TAILWHIP], 
                     [1,:TACKLE],[1,:GROWL],[1,:CONFUSION],[15,:FAIRYWIND],
                     [20,:AGILITY],[25,:PSYBEAM],[30,:STOMP],[35,:HEALPULSE],[43,:TAKEDOWN],
                     [49,:DAZZLINGGLEAM],[56,:PSYCHIC],[63,:HEALINGWISH]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :HYPERBEAM,:GIGAIMPACT,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,:BOUNCE,
                     :TRICKROOM,:MAGICROOM,:WONDERROOM,:SMARTSTRIKE,:SWORDSDANCE,:DRILLRUN,
                     :LOWKICK,:ROUND,:SUBSTITUTE,:SLEEPTALK,:PSYCHIC,:IRONTAIL,:CALMMIND,
                     :ZENHEADBUTT,:STOREDPOWER,:ALLYSWITCH,:WILDCHARGE,:PLAYROUGH,
                     :DAZZLINGGLEAM,:HIGHHORSEPOWER,:THROATCHOP,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLOWPOKE

MultipleForms.register(:SLOWPOKE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,65,65,15,40,40] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:GLUTTONY),0],
         [getID(PBAbilities,:OWNTEMPO),1],
         [getID(PBAbilities,:REGENERATOR),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:CURSE],[1,:TACKLE],[3,:GROWL],[6,:ACID],[9,:YAWN],
                     [12,:CONFUSION],[15,:DISABLE],[18,:WATERPULSE],[21,:HEADBUTT],
                     [24,:ZENHEADBUTT],[27,:AMNESIA],[30,:SURF],[33,:SLACKOFF],
                     [36,:PSYCHIC],[39,:PSYCHUP],[42,:RAINDANCE],[45,:HEALPULSE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :THUNDERWAVE,:DIG,:LIGHTSCREEN,:SAFEGUARD,:REST,:SNORE,:PROTECT,:ICYWIND,
                     :ATTRACT,:RAINDANCE,:SUNNYDAY,:HAIL,:FACADE,:DIVE,:TRICKROOM,:WONDERROOM,
                     :ROUND,:BULLDOZE,:FLAMETHROWER,:SURF,:HYDROPUMP,:ICEBEAM,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:FIREBLAST,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:IRONTAIL,:SHADOWBALL,
                     :TRICK,:SKILLSWAP,:CALMMIND,:ZENHEADBUTT,:GRASSKNOT,:STOREDPOWER,:TRIATTACK,
                     :SCALD,:LIQUIDATION,:BRINE,:PSYCHICTERRAIN,:WEATHERBALL,:AMNESIA,:EXPANDINGFORCE,
                     :FIREPUNCH,:THUNDERPUNCH]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLOWBRO

MultipleForms.register(:SLOWBRO,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"getMegaForm"=>proc{|pokemon|
   next 2 if isConst?(pokemon.item,PBItems,:SLOWBRONITE) && pokemon.form==0
   next
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next getID(PBTypes,:WATER) if pokemon.form==2
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next getID(PBTypes,:PSYCHIC) if pokemon.form==2
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,100,95,30,100,70] if pokemon.form==1
  next [95,75,180,30,130,80] if pokemon.form==2
  next
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:QUICKDRAW),0],[getID(PBAbilities,:OWNTEMPO),1],[getID(PBAbilities,:REGENERATOR),2]]
   when 2; next [[getID(PBAbilities,:SHELLARMOR),0]]
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SHELLSIDEARM],[1,:TACKLE],[1,:GROWL],[1,:ACID],[1,:CURSE],
                     [9,:YAWN],[12,:CONFUSION],[15,:DISABLE],[18,:WATERPULSE],
                     [21,:HEADBUTT],[24,:ZENHEADBUTT],[27,:AMNESIA],[30,:SURF],
                     [33,:SLACKOFF],[36,:PSYCHIC],[39,:PSYCHUP],[42,:RAINDANCE],
                     [45,:HEALPULSE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :THUNDERWAVE,:DIG,:LIGHTSCREEN,:SAFEGUARD,:REST,:SNORE,:PROTECT,:ICYWIND,
                     :ATTRACT,:RAINDANCE,:SUNNYDAY,:HAIL,:FACADE,:DIVE,:TRICKROOM,:WONDERROOM,
                     :ROUND,:BULLDOZE,:FLAMETHROWER,:SURF,:HYDROPUMP,:ICEBEAM,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:FIREBLAST,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:IRONTAIL,:SHADOWBALL,
                     :TRICK,:SKILLSWAP,:CALMMIND,:ZENHEADBUTT,:GRASSKNOT,:STOREDPOWER,:TRIATTACK,
                     :SCALD,:LIQUIDATION,:BRINE,:PSYCHICTERRAIN,:WEATHERBALL,:AMNESIA,:AVALANCHE,
                     :EXPANDINGFORCE,:BRICKBREAK,:DRAINPUNCH,:FOCUSBLAST,:GIGAIMPACT,:HYPERBEAM,
                     :ICEPUNCH,:IRONDEFENSE,:MUDDYWATER,:NASTYPLOT,:POISONJAB,:RAZORSHELL,:SLUDGEBOMB,
                     :SLUDGEWAVE,:VENOSHOCK,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
},
"getUnmegaForm"=>proc{|pokemon|
   next 0 if pokemon.form==2
}
})

# FARFETCH'D

MultipleForms.register(:FARFETCHD,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [52,95,55,55,58,62] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:STEADFAST),0],
         [getID(PBAbilities,:SCRAPPY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PECK],[1,:SANDATTACK],[5,:LEER],[10,:FURYCUTTER],[15,:ROCKSMASH],
                     [20,:BRUTALSWING],[25,:DETECT],[30,:KNOCKOFF],[35,:DEFOG],
                     [40,:BRICKBREAK],[45,:SWORDSDANCE],[50,:SLAM],[55,:LEAFBLADE],
                     [60,:FINALGAMBIT],[65,:BRAVEBIRD]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :REST,:SNORE,:PROTECT,:STEELWING,:ATTRACT,:SUNNYDAY,:FACADE,
                     :HELPINGHAND,:BRICKBREAK,:ROUND,:RETALIATE,:BRUTALSWING,
                     :SWORDSDANCE,:SUBSTITUTE,:SLEEPTALK,:SUPERPOWER,:POISONJAB,
                     :WORKUP,:THROATCHOP,:KNOCKOFF,:COVET,:DEFOG,:SKYATTACK,:DUALWINGBEAT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# WEEZING

MultipleForms.register(:WEEZING,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FAIRY) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:LEVITATE),0],
         [getID(PBAbilities,:NEUTRALIZINGGAS),1],
         [getID(PBAbilities,:MISTYSURGE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:DOUBLEHIT],[1,:STRANGESTEAM],[1,:DEFOG],[1,:HEATWAVE],[1,:SMOG],
                     [1,:SMOKESCREEN],[1,:HAZE],[1,:POISONGAS],[1,:TACKLE],[9,:FAIRYWIND],
                     [1,:AROMATICMIST],[12,:CLEARSMOG],[16,:ASSURANCE],[20,:SLUDGE],
                     [24,:AROMATHERAPY],[28,:SELFDESTRUCT],[32,:SLUDGEBOMB],[38,:TOXIC],
                     [44,:BELCH],[50,:EXPLOSION],[56,:MEMENTO],[62,:DESTINYBOND],[68,:MISTYTERRAIN]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :TOXIC,:HYPERBEAM,:GIGAIMPACT,:REST,:THIEF,:SNORE,:PROTECT,:ATTRACT,
                     :RAINDANCE,:SUNNYDAY,:WILLOWISP,:FACADE,:PAYBACK,:WONDERROOM,:VENOSHOCK,
                     :ROUND,:BRUTALSWING,:FLAMETHROWER,:THUNDERBOLT,:THUNDER,:FIREBLAST,
                     :SUBSTITUTE,:SLUDGEBOMB,:SLEEPTALK,:SHADOWBALL,:UPROAR,:HEATWAVE,
                     :TAUNT,:OVERHEAT,:GYROBALL,:DARKPULSE,:SLUDGEWAVE,:DAZZLINGGLEAM,
                     :PAINSPLIT,:EXPLOSION,:DEFOG,:CORROSIVEGAS,:MISTYEXPLOSION,:CONFIDE,
                     :RETURN,:FRUSTRATION,:HIDDENPOWER]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MR. MIME

MultipleForms.register(:MRMIME,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [50,65,65,100,90,90] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:VITALSPIRIT),0],
         [getID(PBAbilities,:SCREENCLEANER),1],
         [getID(PBAbilities,:ICEBODY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:COPYCAT],[1,:ENCORE],[1,:ROLEPLAY],[1,:PROTECT],[1,:RECYCLE],
                     [1,:MIMIC],[1,:LIGHTSCREEN],[1,:REFLECT],[1,:SAFEGUARD],[1,:DAZZLINGGLEAM],
                     [1,:MISTYTERRAIN],[1,:POUND],[1,:RAPIDSPIN],[1,:BATONPASS],[1,:ICESHARD],
                     [12,:CONFUSION],[16,:ALLYSWITCH],[20,:ICYWIND],[24,:DOUBLEKICK],[28,:PSYBEAM],
                     [32,:HYPNOSIS],[36,:MIRRORCOAT],[40,:SUCKERPUNCH],[44,:FREEZEDRY],
                     [48,:PSYCHIC],[52,:TEETERDANCE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ICEPUNCH,:HYPERBEAM,:GIGAIMPACT,:SOLARBEAM,:THUNDERWAVE,:TRICKROOM,
                     :LIGHTSCREEN,:REFLECT,:SAFEGUARD,:ICYWIND,:THIEF,:HELPINGHAND,:FLING,
                     :REST,:SNORE,:PROTECT,:ATTRACT,:SUNNYDAY,:FACADE,:RAINDANCE,:HAIL,:CONFIDE,
                     :BRICKBREAK,:ICICLESPEAR,:ROUND,:PAYBACK,:WONDERROOM,:MAGICROOM,:DRAINPUNCH,
                     :STOMPINGTANTRUM,:ICEBEAM,:SUBSTITUTE,:SLEEPTALK,:BLIZZARD,:PSYCHIC,:PSYSHOCK,
                     :THUNDER,:THUNDERBOLT,:SHADOWBALL,:UPROAR,:TAUNT,:TRICK,:SKILLSWAP,:IRONDEFENSE,
                     :CALMMIND,:FOCUSBLAST,:ENERGYBALL,:NASTYPLOT,:ZENHEADBUTT,:GRASSKNOT,:FOULPLAY,
                     :STOREDPOWER,:ALLYSWITCH,:DAZZLINGGLEAM,:RECYCLE,:ROLEPLAY,:TRIPLEAXEL,:EXPANDINGFORCE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ARTICUNO

MultipleForms.register(:ARTICUNO,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,85,85,95,125,95] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:COMPETITIVE),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:GUST],[1,:PSYCHOSHIFT],[5,:CONFUSION],[10,:REFLECT],
                     [15,:HYPNOSIS],[20,:AGILITY],[25,:ANCIENTPOWER],[30,:TAILWIND],
                     [35,:PSYCHOCUT],[40,:RECOVER],[45,:FREEZINGGLARE],
                     [50,:DREAMEATER],[55,:HURRICANE],[60,:MINDREADER],[65,:FUTURESIGHT],
                     [70,:TRICKROOM]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :FLY,:HYPERBEAM,:GIGAIMPACT,:REFLECT,:LIGHTSCREEN,:REST,:PROTECT,
                     :STEELWING,:FACADE,:UTURN,:PSYCHOCUT,:TRICKROOM,:ROUND,:AIRSLASH,
                     :PSYCHIC,:AGILITY,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:SHADOWBALL,
                     :SKILLSWAP,:HYPERVOICE,:CALMMIND,:BRAVEBIRD,:HURRICANE,:STOREDPOWER,
                     :EXPANDINGFORCE,:DUALWINGBEAT,:SNORE,:ALLYSWITCH]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZAPDOS

MultipleForms.register(:ZAPDOS,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,125,90,100,85,90] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:DEFIANT),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:PECK],[1,:FOCUSENERGY],[5,:ROCKSMASH],[10,:LIGHTSCREEN],
                     [15,:PLUCK],[20,:AGILITY],[25,:ANCIENTPOWER],[30,:BRICKBREAK],
                     [35,:DRILLPECK],[40,:QUICKGUARD],[45,:THUNDEROUSKICK],
                     [50,:BULKUP],[55,:COUNTER],[60,:DETECT],[65,:CLOSECOMBAT],
                     [70,:REVERSAL]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :FLY,:HYPERBEAM,:GIGAIMPACT,:LIGHTSCREEN,:REST,:PROTECT,
                     :STEELWING,:FACADE,:BRICKBREAK,:UTURN,:PAYBACK,:ROUND,
                     :ACROBATICS,:RETALIATE,:STOMPINGTANTRUM,:LOWKICK,:AGILITY,
                     :SUBSTITUTE,:SLEEPTALK,:TAUNT,:SUPERPOWER,:BULKUP,:CLOSECOMBAT,
                     :BRAVEBIRD,:HURRICANE,:THROATCHOP,:COACHING,:DUALWINGBEAT,
                     :SNORE,:BOUNCE,:LOWSWEEP]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# MOLTRES

MultipleForms.register(:MOLTRES,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,85,90,90,100,125] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:BERSERK),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:GUST],[1,:LEER],[5,:PAYBACK],[10,:SAFEGUARD],
                     [15,:WINGATTACK],[20,:AGILITY],[25,:ANCIENTPOWER],[30,:SUCKERPUNCH],
                     [35,:AIRSLASH],[40,:AFTERYOU],[45,:FIERYWRATH],
                     [50,:NASTYPLOT],[55,:HURRICANE],[60,:ENDURE],[65,:MEMENTO],
                     [70,:SKYATTACK]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :FLY,:HYPERBEAM,:GIGAIMPACT,:SAFEGUARD,:REST,:PROTECT,
                     :STEELWING,:FACADE,:UTURN,:PAYBACK,:ROUND,:HEX,:SNARL,:AIRSLASH,
                     :AGILITY,:SUBSTITUTE,:SLEEPTALK,:SHADOWBALL,:TAUNT,:HYPERVOICE,
                     :DARKPULSE,:BRAVEBIRD,:NASTYPLOT,:FOULPLAY,:HURRICANE,:LASHOUT,
                     :DUALWINGBEAT,:SNORE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLOWKING

MultipleForms.register(:SLOWKING,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,65,80,30,110,110] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:CURIOUSMEDICINE),0],[getID(PBAbilities,:OWNTEMPO),1],[getID(PBAbilities,:REGENERATOR),2]]
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:EERIESPELL],[1,:NASTYPLOT],[1,:POWERGEM],[1,:SWAGGER],
                     [1,:TACKLE],[1,:GROWL],[1,:ACID],[1,:CURSE],[9,:YAWN],
                     [12,:CONFUSION],[15,:DISABLE],[18,:WATERPULSE],
                     [21,:HEADBUTT],[24,:ZENHEADBUTT],[27,:AMNESIA],[30,:SURF],
                     [33,:SLACKOFF],[36,:PSYCHIC],[39,:PSYCHUP],[42,:RAINDANCE],
                     [45,:HEALPULSE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :THUNDERWAVE,:DIG,:LIGHTSCREEN,:SAFEGUARD,:REST,:SNORE,:PROTECT,:ICYWIND,
                     :ATTRACT,:RAINDANCE,:SUNNYDAY,:HAIL,:FACADE,:DIVE,:TRICKROOM,:WONDERROOM,
                     :ROUND,:BULLDOZE,:FLAMETHROWER,:SURF,:HYDROPUMP,:ICEBEAM,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:FIREBLAST,:SUBSTITUTE,:SLEEPTALK,:PSYSHOCK,:IRONTAIL,:SHADOWBALL,
                     :TRICK,:SKILLSWAP,:CALMMIND,:ZENHEADBUTT,:GRASSKNOT,:STOREDPOWER,:TRIATTACK,
                     :SCALD,:LIQUIDATION,:BRINE,:PSYCHICTERRAIN,:WEATHERBALL,:AMNESIA,:AVALANCHE,
                     :EXPANDINGFORCE,:BRICKBREAK,:DRAINPUNCH,:FOCUSBLAST,:GIGAIMPACT,:HYPERBEAM,
                     :ICEPUNCH,:IRONDEFENSE,:MUDDYWATER,:NASTYPLOT,:POISONJAB,:RAZORSHELL,:SLUDGEBOMB,
                     :SLUDGEWAVE,:VENOSHOCK,:EXPANDINGFORCE,:SNORE,:FLING]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# CORSOLA

MultipleForms.register(:CORSOLA,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,55,100,30,65,100] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:WEAKARMOR),0],
         [getID(PBAbilities,:CURSEDBODY),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:HARDEN],[5,:ASTONISH],[10,:DISABLE],[15,:SPITE],
                     [20,:ANCIENTPOWER],[25,:HEX],[30,:CURSE],[35,:STRENGTHSAP],
                     [40,:POWERGEM],[45,:NIGHTSHADE],[50,:GRUDGE],[55,:MIRRORCOAT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :DIG,:LIGHTSCREEN,:REFLECT,:SAFEGUARD,:ROCKSLIDE,:ICYWIND,:SANDSTORM,
                     :REST,:SNORE,:PROTECT,:ATTRACT,:SUNNYDAY,:FACADE,:RAINDANCE,:HAIL,
                     :ROCKTOMB,:ICICLESPEAR,:ROUND,:ROCKBLAST,:BULLDOZE,:STOMPINGTANTRUM,
                     :HYDROPUMP,:SURF,:ICEBEAM,:SUBSTITUTE,:SLEEPTALK,:BLIZZARD,:EARTHQUAKE,
                     :PSYCHIC,:SHADOWBALL,:IRONDEFENSE,:CALMMIND,:POWERGEM,:EARTHPOWER,
                     :STONEEDGE,:STEALTHROCK,:SCALD,:THROATCHOP,:LIQUIDATION,:NATUREPOWER,
                     :WATERPULSE,:METEORBEAM]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZIGZAGOON

MultipleForms.register(:ZIGZAGOON,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:PICKUP),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:QUICKFEET),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:LEER],[3,:SANDATTACK],[6,:LICK],
                     [9,:SNARL],[12,:HEADBUTT],[15,:BABYDOLLEYES],[18,:PINMISSILE],
                     [21,:REST],[24,:TAKEDOWN],[27,:SCARYFACE],[30,:COUNTER],
                     [33,:TAUNT],[36,:DOUBLEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :THUNDERWAVE,:DIG,:REST,:THIEF,:SNORE,:PROTECT,
                     :ICYWIND,:ATTRACT,:RAINDANCE,:SUNNYDAY,:FACADE,:HELPINGHAND,
                     :PAYBACK,:FLING,:ROUND,:RETALIATE,:SNARL,:SURF,:ICEBEAM,:BLIZZARD,
                     :THUNDERBOLT,:THUNDER,:SUBSTITUTE,:SLEEPTALK,:IRONTAIL,:SHADOWBALL,
                     :TAUNT,:TRICK,:HYPERVOICE,:SEEDBOMB,:GUNKSHOT,:GRASSKNOT,:WORKUP,
                     :KNOCKOFF,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# LINOONE

MultipleForms.register(:LINOONE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:PICKUP),0],
         [getID(PBAbilities,:GLUTTONY),1],
         [getID(PBAbilities,:QUICKFEET),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:NIGHTSLASH],[1,:SWITCHEROO],[1,:PINMISSILE],[1,:BABYDOLLEYES],
                     [1,:TACKLE],[1,:LEER],[1,:SANDATTACK],[1,:LICK],[9,:SNARL],[12,:HEADBUTT],
                     [15,:HONECLAWS],[18,:FURYSWIPES],[23,:REST],[28,:TAKEDOWN],[33,:SCARYFACE],
                     [38,:COUNTER],[43,:TAUNT],[48,:DOUBLEEDGE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :HYPERBEAM,:GIGAIMPACT,:THUNDERWAVE,:DIG,:REST,:THIEF,:SNORE,:PROTECT,
                     :ICYWIND,:ATTRACT,:RAINDANCE,:SUNNYDAY,:FACADE,:HELPINGHAND,:PAYBACK,
                     :FLING,:SHADOWCLAW,:ROUND,:RETALIATE,:SNARL,:STOMPINGTANTRUM,:SURF,:ICEBEAM,
                     :BLIZZARD,:THUNDERBOLT,:THUNDER,:SUBSTITUTE,:SLEEPTALK,:IRONTAIL,:SHADOWBALL,
                     :TAUNT,:TRICK,:HYPERVOICE,:SEEDBOMB,:GUNKSHOT,:GRASSKNOT,:WORKUP,:THROATCHOP,
                     :HONECLAWS,:KNOCKOFF,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DARUMAKA

MultipleForms.register(:DARUMAKA,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 3
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==3
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==3
  next
},
"getBaseStats"=>proc{|pokemon|
  next [70,90,45,50,15,45] if pokemon.form==3
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:HUSTLE),0],
         [getID(PBAbilities,:INNERFOCUS),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 3; movelist=[[1,:POWDERSNOW],[1,:TACKLE],[4,:TAUNT],[8,:BITE], 
                     [12,:AVALANCHE],[16,:WORKUP],[20,:ICEFANG],[24,:HEADBUTT],
                     [28,:ICEPUNCH],[32,:UPROAR],[36,:BELLYDRUM],[40,:BLIZZARD],
                     [44,:THRASH],[48,:SUPERPOWER]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 3; movelist=[# MTs
                     :FIREPUNCH,:ICEPUNCH,:SOLARBEAM,:DIG,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,
                     :ROCKSLIDE,:THIEF,:SUNNYDAY,:WILLOWISP,:BRICKBREAK,:ROCKTOMB,:UTURN,:FLING,
                     :ICEFANG,:FIREFANG,:ROUND,:ICEBEAM,:BLIZZARD,:FLAMETHROWER,:FIREBLAST,:UPROAR,
                     :SUBSTITUTE,:SLEEPTALK,:HEATWAVE,:TAUNT,:SUPERPOWER,:OVERHEAT,:GYROBALL,
                     :FLAREBLITZ,:ZENHEADBUTT,:GRASSKNOT,:WORKUP,:INCINERATE,:POWERUPPUNCH,
                     :FOCUSPUNCH]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DARMANITAN

MultipleForms.register(:DARMANITAN,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 3
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 2; next getID(PBTypes,:ICE)    # Forma Galar
   when 1; next getID(PBTypes,:FIRE)   # Forma Daruma
   when 3; next getID(PBTypes,:ICE)    # Forma Galar Daruma
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0              # Forma Normal
   case pokemon.form
   when 2; next getID(PBTypes,:ICE)     # Forma Galar
   when 1; next getID(PBTypes,:PSYCHIC) # Forma Daruma
   when 3; next getID(PBTypes,:FIRE)    # Forma Galar Daruma
   end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0                  # Forma Normal
   case pokemon.form
   when 2; next [105,140,55,95,30,55]       # Forma Galar
   when 1; next [105,30,105,55,140,105]     # Forma Daruma
   when 3; next [105,160,55,135,30,55]      # Forma Galar Daruma
  end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 2; next [[getID(PBAbilities,:GORILLATACTICS),0],[getID(PBAbilities,:ZENMODE),2]] # Forma Galar
   when 1; next [[getID(PBAbilities,:ZENMODE),0]] # Forma Daruma
   when 3; next [[getID(PBAbilities,:ZENMODE),0]] # Forma Galar Daruma
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 2; movelist=[[1,:ICICLECRASH],[1,:POWDERSNOW],[1,:BITE],[1,:TACKLE],[1,:TAUNT],[12,:AVALANCHE],
                     [16,:WORKUP],[20,:ICEFANG],[24,:HEADBUTT],[28,:ICEPUNCH],[32,:UPROAR],
                     [38,:BELLYDRUM],[44,:BLIZZARD],[50,:THRASH],[56,:SUPERPOWER]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 2; movelist=[# MTs y tutores
                     :FIREPUNCH,:ICEPUNCH,:GIGAIMPACT,:HYPERBEAM,:SOLARBEAM,:DIG,:BODYPRESS,
                     :REST,:ROCKSLIDE,:THIEF,:SNORE,:PROTECT,:ATTRACT,:SUNNYDAY,:WORKUP,
                     :WILLOWISP,:FACADE,:BRICKBREAK,:ROCKTOMB,:UTURN,:PAYBACK,:FLING,
                     :ICEFANG,:FIREFANG,:ROUND,:BULLDOZE,:FLAMETHROWER,:ICEBEAM,:BLIZZARD,
                     :EARTHQUAKE,:PSYCHIC,:FIREBLAST,:SLEEPTALK,:SUBSTITUTE,:UPROAR,
                     :HEATWAVE,:TAUNT,:SUPERPOWER,:OVERHEAT,:IRONDEFENSE,:BULKUP,:GYROBALL,
                     :FLAREBLITZ,:FOCUSBLAST,:ZENHEADBUTT,:IRONHEAD,:STONEEDGE,:GRASSKNOT,
                     :INCINERATE,:POWERUPPUNCH,:FOCUSPUNCH,:BURNINGJEALOUSY,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# YAMASK

MultipleForms.register(:YAMASK,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GROUND) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [38,55,85,30,30,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:WANDERINGSPIRIT),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:ASTONISH],[1,:PROTECT],[4,:HAZE],[8,:NIGHTSHADE],[12,:DISABLE],
                     [16,:BRUTALSWING],[20,:CRAFTYSHIELD],[24,:HEX],[28,:MEANLOOK],[32,:SLAM],
                     [36,:CURSE],[40,:SHADOWBALL],[44,:EARTHQUAKE],[48,:POWERSPIT],
                     [48,:GUARDSPIT],[52,:DESTINYBOND]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :SAFEGUARD,:ROCKSLIDE,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,
                     :WILLOWISP,:RAINDANCE,:SANDSTORM,:ROCKTOMB,:PAYBACK,:TRICKROOM,
                     :WONDERROOM,:ROUND,:BRUTALSWING,:EARTHQUAKE,:SUBSTITUTE,:SLEEPTALK,
                     :PSYCHIC,:SHADOWBALL,:TRICK,:SKILLSWAP,:IRONDEFENSE,:CALMMIND,:EARTHPOWER,
                     :DARKPULSE,:ENERGYBALL,:NASTYPLOT,:ZENHEADBUTT,:ALLYSWITCH,:POLTERGEIST]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# STUNFISK

MultipleForms.register(:STUNFISK,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && GALAR_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GROUND) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [109,81,99,32,66,84] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MIMICRY),0]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:MUDSLAP],[1,:TACKLE],[1,:WATERGUN],[1,:METALCLAW], 
                     [5,:ENDURE],[10,:MUDSHOT],[15,:REVENGE],[20,:METALSOUND],
                     [25,:SUCKERPUNCH],[30,:IRONDEFENSE],[35,:BOUNCE],[40,:MUDDYWATER],
                     [45,:SNAPTRAP],[50,:FLAIL],[55,:FISSURE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :THUNDERWAVE,:DIG,:ROCKSLIDE,:REST,:SNORE,:PROTECT,:ATTRACT,:FACADE,:BOUNCE,
                     :SANDSTORM,:RAINDANCE,:ROCKTOMB,:PAYBACK,:ICEFANG,:BULLDOZE,:EARTHQUAKE,
                     :STOMPINGTANTRUM,:ROUND,:SUBSTITUTE,:SLEEPTALK,:SURF,:SLUDGEBOMB,:CRUNCH,
                     :UPROAR,:MUDDYWATER,:IRONDEFENSE,:EARTHPOWER,:FLASHCANNON,:STONEEDGE,
                     :STEALTHROCK,:SLUDGEWAVE,:FOULPLAY,:SCALD,:STEELBEAM,:PAINSPLIT,:BIND,
                     :TERRAINPULSE,:LASHOUT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

########################################################################
######################### Formas Hisui #################################
########################################################################

# GROWLITHE

MultipleForms.register(:GROWLITHE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ROCK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,75,45,50,65,50] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:INTIMIDATE),0],
         [getID(PBAbilities,:FLASHFIRE),1],
         [getID(PBAbilities,:ROCKHEAD),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:EMBER],[1,:LEER],[4,:HOWL],[8,:BITE],[12,:FLAMEWHEEL],
                     [16,:HELPINGHAND],[24,:FIREFANG],[28,:RETALIATE],[32,:CRUNCH],
                     [36,:TAKEDOWN],[40,:FLAMETHROWER],[44,:ROAR],[48,:ROCKSLIDE],
                     [52,:REVERSAL],[56,:FLAREBLITZ]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AGILITY,:BODYSLAM,:CLOSECOMBAT,:CRUNCH,:DIG,:DOUBLEEDGE,
                     :ENDURE,:FACADE,:FIREBLAST,:FIREFANG,:FIRESPIN,:FLAMECHARGE,
                     :FLAMETHROWER,:FLAREBLITZ,:HEATWAVE,:HELPINGHAND,:OUTRAGE,
                     :OVERHEAT,:POWERGEM,:PROTECT,:PSYCHICFANGS,:REST,:REVERSAL,
                     :ROAR,:ROCKBLAST,:ROCKSLIDE,:ROCKTOMB,:SANDSTORM,:SCARYFACE,
                     :SCORCHINGSANDS,:SLEEPTALK,:SMACKDOWN,:SMARTSTRIKE,
                     :STEALTHROCK,:STONEEDGE,:SUBSTITUTE,:SUNNYDAY,:TAKEDOWN,
                     :TEMPERFLARE,:THUNDERFANG,:WILDCHARGE,:WILLOWISP]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ARCANINE

MultipleForms.register(:ARCANINE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ROCK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,115,80,90,95,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:INTIMIDATE),0],
         [getID(PBAbilities,:FLASHFIRE),1],
         [getID(PBAbilities,:ROCKHEAD),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:EXTREMESPEED],[1,:FLAMEWHEEL],[1,:FIREFANG],
                     [1,:FLAREBLITZ],[1,:HOWL],[1,:HELPINGHAND],[1,:CRUNCH],
                     [1,:REVERSAL],[1,:RETALIATE],[1,:TAKEDOWN],[1,:AGILITY],
                     [1,:ROCKTHROW],[1,:EMBER],[1,:ROAR],[1,:BITE],[1,:LEER],
                     [1,:ROCKSLIDE],[5,:FLAMETHROWER],[64,:RAGINGFURY]]

   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AERIALACE,:AGILITY,:BODYSLAM,:BULLDOZE,:CLOSECOMBAT,:CRUNCH,
                     :DIG,:DOUBLEEDGE,:DRAGONPULSE,:ENDURE,:FACADE,:FIREBLAST,
                     :FIREFANG,:FIRESPIN,:FLAMECHARGE,:FLAMETHROWER,:FLAREBLITZ,
                     :GIGAIMPACT,:HEATCRASH,:HEATWAVE,:HELPINGHAND,:HYPERBEAM,
                     :HYPERVOICE,:IRONHEAD,:OUTRAGE,:OVERHEAT,:POWERGEM,:PROTECT,
                     :PSYCHICFANGS,:REST,:REVERSAL,:ROAR,:ROCKBLAST,:ROCKSLIDE,
                     :ROCKTOMB,:SANDSTORM,:SCARYFACE,:SCORCHINGSANDS,:SLEEPTALK,
                     :SMACKDOWN,:SMARTSTRIKE,:SNARL,:SOLARBEAM,:STEALTHROCK,
                     :STONEEDGE,:SUBSTITUTE,:SUNNYDAY,:TAKEDOWN,:TEMPERFLARE,
                     :THIEF,:THUNDERFANG,:WILDCHARGE,:WILLOWISP]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# VOLTORB

MultipleForms.register(:VOLTORB,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [40,30,50,100,55,55] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SOUNDPROOF),0],
         [getID(PBAbilities,:STATIC),1],
         [getID(PBAbilities,:AFTERMATH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:CHARGE],[4,:THUNDERSHOCK],[6,:STUNSPORE],
                     [9,:BULLETSEED],[11,:ROLLOUT],[13,:SCREECH],[16,:CHARGEBEAM],
                     [20,:SWIFT],[22,:ELECTROBALL],[26,:SELFDESTRUCT],
                     [29,:ENERGYBALL],[34,:DISCHARGE],[34,:SEEDBOMB],
                     [41,:EXPLOSION],[46,:GYROBALL],[50,:GRASSYTERRAIN]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AGILITY,:BULLETSEED,:CHARGE,:CHARGEBEAM,:DOUBLEEDGE,
                     :ELECTRICTERRAIN,:ELECTROBALL,:ELECTROWEB,:ENDURE,
                     :ENERGYBALL,:FACADE,:FOULPLAY,:GIGADRAIN,:GRASSKNOT,
                     :GRASSYGLIDE,:GRASSYTERRAIN,:GYROBALL,:LEAFSTORM,:PROTECT,
                     :RAINDANCE,:REFLECT,:REST,:SEEDBOMB,:SLEEPTALK,:SOLARBEAM,
                     :SUBSTITUTE,:SWIFT,:TAKEDOWN,:TAUNT,:THIEF,:THUNDER,
                     :THUNDERBOLT,:THUNDERWAVE,:VOLTSWITCH,:WILDCHARGE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ELECTRODE

MultipleForms.register(:ELECTRODE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ELECTRIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [60,50,70,150,80,80] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SOUNDPROOF),0],
         [getID(PBAbilities,:STATIC),1],
         [getID(PBAbilities,:AFTERMATH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:CHLOROBLAST],[1,:TACKLE],[1,:CHARGE],[4,:THUNDERSHOCK],
                     [6,:STUNSPORE],[9,:BULLETSEED],[11,:ROLLOUT],[13,:SCREECH],
                     [16,:CHARGEBEAM],[20,:SWIFT],[22,:ELECTROBALL],
                     [26,:SELFDESTRUCT],[29,:ENERGYBALL],[34,:DISCHARGE],
                     [34,:SEEDBOMB],[41,:EXPLOSION],[46,:GYROBALL],
                     [50,:GRASSYTERRAIN]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AGILITY,:BULLETSEED,:CHARGE,:CHARGEBEAM,:CURSE,:DOUBLEEDGE,
                     :ELECTRICTERRAIN,:ELECTROBALL,:ELECTROWEB,:ENDURE,
                     :ENERGYBALL,:FACADE,:FOULPLAY,:GIGADRAIN,:GIGAIMPACT,:GRASSKNOT,
                     :GRASSYGLIDE,:GRASSYTERRAIN,:GYROBALL,:HYPERBEAM,:LEAFSTORM,
                     :PROTECT,:RAINDANCE,:REFLECT,:REST,:SCARYFACE,:SEEDBOMB,
                     :SLEEPTALK,:SOLARBEAM,:SUBSTITUTE,:SUPERCELLSLAM,:SWIFT,
                     :TAKEDOWN,:TAUNT,:THIEF,:THUNDER,:THUNDERBOLT,:THUNDERWAVE,
                     :VOLTSWITCH,:WILDCHARGE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# TYPHLOSION

MultipleForms.register(:TYPHLOSION,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIRE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [73,84,78,95,119,85] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:BLAZE),0],
         [getID(PBAbilities,:FRISK),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:INFERNALPARADE],[1,:GYROBALL],[1,:ERUPTION],
                     [1,:SMOKESCREEN],[1,:TACKLE],[1,:EMBER],[1,:LEER],
                     [1,:DOUBLEEDGE],[13,:QUICKATTACK],[20,:FLAMEWHEEL],
                     [24,:DEFENSECURL],[31,:SWIFT],[35,:FLAMECHARGE],
                     [43,:LAVAPLUME],[48,:FLAMETHROWER],[56,:INFERNO],
                     [61,:ROLLOUT],[74,:OVERHEAT]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AERIALACE,:BLASTBURN,:BODYSLAM,:BRICKBREAK,:BULLDOZE,
                     :BURNINGJEALOUSY,:CALMMIND,:CONFUSERAY,:CURSE,:DIG,
                     :DOUBLEEDGE,:EARTHQUAKE,:ENDEAVOR,:ENDURE,:FACADE,:FIREBLAST,
                     :FIREFANG,:FIREPLEDGE,:FIREPUNCH,:FIRESPIN,:FLAMECHARGE,
                     :FLAMETHROWER,:FLAREBLITZ,:FOCUSBLAST,:FOCUSPUNCH,:GIGAIMPACT,
                     :GYROBALL,:HEATWAVE,:HEX,:HYPERBEAM,:IRONHEAD,:LOWKICK,
                     :NIGHTSHADE,:OVERHEAT,:PLAYROUGH,:POLTERGEIST,:PROTECT,:REST,
                     :REVERSAL,:ROAR,:ROCKSLIDE,:SHADOWBALL,:SHADOWCLAW,:SLEEPTALK,
                     :SOLARBEAM,:SPITE,:STOMPINGTANTRUM,:SUBSTITUTE,:SUNNYDAY,
                     :SWIFT,:TAKEDOWN,:TEMPERFLARE,:THUNDERPUNCH,:WILDCHARGE,
                     :WILLOWISP,:ZENHEADBUTT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# QWILFISH
MultipleForms.register(:QWILFISH,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [65,95,85,85,55,55] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SWIFTSWIM),0],
         [getID(PBAbilities,:POISONPOINT),1],
         [getID(PBAbilities,:INTIMIDATE),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:POISONSTING],[1,:TACKLE],[4,:HARDEN],[8,:BITE],
                     [12,:FELLSTINGER],[16,:MINIMIZE],[20,:SPIKES],[24,:BRINE],
                     [28,:BARBBARRAGE],[32,:PINMISSILE],[36,:TOXICSPIKES],
                     [40,:SPITUP],[40,:STOCKPILE],[44,:TOXIC],[48,:CRUNCH],
                     [52,:ACUPRESSURE],[56,:DESTINYBOND]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ACIDSPRAY,:AGILITY,:BLIZZARD,:CHILLINGWATER,:CRUNCH,:CURSE,
                     :DARKPULSE,:DOUBLEEDGE,:ENDURE,:FACADE,:GIGAIMPACT,:GUNKSHOT,
                     :GYROBALL,:HAZE,:HEX,:HYDROPUMP,:ICEBEAM,:ICYWIND,:LASHOUT,
                     :LIQUIDATION,:MUDSHOT,:PAINSPLIT,:POISONJAB,:POISONTAIL,
                     :PROTECT,:RAINDANCE,:REST,:REVERSAL,:SCALESHOT,:SCARYFACE,
                     :SHADOWBALL,:SLEEPTALK,:SLUDGEBOMB,:SPIKES,:SPITE,:SUBSTITUTE,
                     :SURF,:SWIFT,:SWORDSDANCE,:TAKEDOWN,:TAUNT,:THROATCHOP,
                     :TOXIC,:TOXICSPIKES,:VENOSHOCK,:WATERFALL,:WATERPULSE]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SNEASEL
MultipleForms.register(:SNEASEL,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [55,95,55,115,35,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:INNERFOCUS),0],
         [getID(PBAbilities,:KEENEYE),1],
         [getID(PBAbilities,:PICKPOCKET),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:SCRATCH],[1,:LEER],[1,:ROCKSMASH],[6,:TAUNT],
                     [12,:QUICKATTACK],[18,:METALCLAW],[24,:POISONJAB],
                     [30,:BRICKBREAK],[36,:HONECLAWS],[42,:SLASH],[48,:AGILITY],
                     [54,:SCREECH],[60,:CLOSECOMBAT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ACIDSPRAY,:AERIALACE,:AGILITY,:BRICKBREAK,:BULKUP,
                     :CALMMIND,:CLOSECOMBAT,:COACHING,:DIG,:ENDURE,:FACADE,
                     :FALSESWIPE,:FLING,:FOCUSBLAST,:FOCUSPUNCH,:GIGAIMPACT,
                     :GRASSKNOT,:GUNKSHOT,:LASHOUT,:LOWKICK,:LOWSWEEP,:METALCLAW,
                     :NASTYPLOT,:POISONJAB,:POISONTAIL,:PROTECT,:RAINDANCE,:REST,
                     :REVERSAL,:SHADOWBALL,:SHADOWCLAW,:SLEEPTALK,:SLUDGEBOMB,
                     :SLUDGEWAVE,:SPITE,:SUBSTITUTE,:SUNNYDAY,:SWIFT,:SWORDSDANCE,
                     :TAKEDOWN,:TAUNT,:THIEF,:THROATCHOP,:TOXIC,:TOXICSPIKES,
                     :TRAILBLAZE,:VACUUMWAVE,:VENOSHOCK,:XSCISSOR]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SAMUROTT

MultipleForms.register(:SAMUROTT,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:WATER) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DARK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [90,108,80,85,100,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:TORRENT),0],
         [getID(PBAbilities,:SHARPNESS),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:CEASELESSEDGE],[1,:SLASH],[1,:SUCKERPUNCH],
                     [1,:MEGAHORN],[1,:TAILWHIP],[1,:TACKLE],[1,:WATERGUN],
                     [13,:FOCUSENERGY],[18,:RAZORSHELL],[21,:FURYCUTTER],
                     [25,:WATERPULSE],[29,:AERIALACE],[34,:AQUAJET],[39,:ENCORE],
                     [46,:AQUATAIL],[51,:RETALIATE],[58,:SWORDSDANCE],
                     [63,:HYDROPUMP]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AERIALACE,:AIRSLASH,:AVALANCHE,:BLIZZARD,:BODYSLAM,
                     :BRICKBREAK,:BULLDOZE,:CHILLINGWATER,:DARKPULSE,:DIG,
                     :DRILLRUN,:ENCORE,:ENDURE,:FACADE,:FALSESWIPE,:FLING,
                     :FLIPTURN,:GIGAIMPACT,:GRASSKNOT,:HELPINGHAND,:HYDROCANNON,
                     :HYDROPUMP,:HYPERBEAM,:ICEBEAM,:ICYWIND,:KNOCKOFF,:LASHOUT,
                     :LIQUIDATION,:PROTECT,:RAINDANCE,:REST,:SCARYFACE,:SLEEPTALK,
                     :SMARTSTRIKE,:SNARL,:SNOWSCAPE,:SUBSTITUTE,:SURF,:SWIFT,
                     :SWORDSDANCE,:TAKEDOWN,:TAUNT,:THIEF,:THROATCHOP,:UPPERHAND,
                     :VACUUMWAVE,:WATERFALL,:WATERPLEDGE,:WATERPULSE,:WHIRLPOOL,
                     :XSCISSOR
                    ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# LILLIGANT

MultipleForms.register(:LILLIGANT,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [70,105,75,105,50,75] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:CHLOROPHYLL),0],
         [getID(PBAbilities,:HUSTLE),1],
         [getID(PBAbilities,:LEAFGUARD),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:VICTORYDANCE],[1,:TEETERDANCE],[1,:SOLARBLADE],
                     [1,:PETALBLIZZARD],[1,:AFTERYOU],[1,:ENTRAINMENT],
                     [1,:LEAFSTORM],[1,:DEFOG],[1,:ENERGYBALL],[1,:LEAFBLADE],
                     [1,:MAGICALLEAF],[1,:MEGAKICK],[1,:SUNNYDAY],[1,:SYNTHESIS],
                     [1,:GIGADRAIN],[1,:SLEEPPOWDER],[1,:STUNSPORE],[1,:GROWTH],
                     [1,:LEECHSEED],[1,:MEGADRAIN],[1,:ABSORB],[1,:HELPINGHAND],
                     [5,:AXEKICK]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ACROBATICS,:AERIALACE,:AIRSLASH,:BRICKBREAK,:BULLETSEED,
                     :CHARM,:CLOSECOMBAT,:COACHING,:ENCORE,:ENDURE,:ENERGYBALL,
                     :FACADE,:GIGADRAIN,:GIGAIMPACT,:GRASSKNOT,:GRASSYGLIDE,
                     :GRASSYTERRAIN,:HELPINGHAND,:HURRICANE,:HYPERBEAM,:ICESPINNER,
                     :LEAFSTORM,:LOWKICK,:LOWSWEEP,:MAGICALLEAF,:METRONOME,
                     :PETALBLIZZARD,:POISONJAB,:POLLENPUFF,:PROTECT,:PSYCHUP,
                     :RAINDANCE,:REST,:SEEDBOMB,:SLEEPTALK,:SOLARBEAM,:SOLARBLADE,
                     :SUBSTITUTE,:SUNNYDAY,:SWORDSDANCE,:TAKEDOWN,:TRAILBLAZE,
                     :TRIPLEAXEL,:UPPERHAND,:VACUUMWAVE,:WEATHERBALL
                    ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZORUA

MultipleForms.register(:ZORUA,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:NORMAL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [35,60,40,70,85,40] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:ILLUSION),0]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:LEER],[1,:SCRATCH],[4,:TORMENT],[8,:HONECLAWS],
                     [12,:SHADOWSNEAK],[16,:CURSE],[20,:TAUNT],[24,:KNOCKOFF],
                     [28,:SPITE],[32,:AGILITY],[36,:SHADOWBALL],[40,:BITTERMALICE],
                     [44,:NASTYPLOT],[48,:FOULPLAY]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AGILITY,:BURNINGJEALOUSY,:CALMMIND,:CONFUSERAY,:CURSE,
                     :DARKPULSE,:DIG,:ENDURE,:FACADE,:FAKETEARS,:FLING,:FOCUSPUNCH,
                     :FOULPLAY,:GIGAIMPACT,:HEX,:HYPERBEAM,:ICYWIND,:IMPRISON,
                     :KNOCKOFF,:LASHOUT,:NASTYPLOT,:NIGHTSHADE,:PAINSPLIT,
                     :PHANTOMFORCE,:PROTECT,:PSYCHUP,:RAINDANCE,:REST,:ROAR,
                     :SHADOWBALL,:SHADOWCLAW,:SKITTERSMACK,:SLEEPTALK,:SLUDGEBOMB,
                     :SNARL,:SNOWSCAPE,:SPITE,:SUBSTITUTE,:SWIFT,:TAKEDOWN,:TAUNT,
                     :THIEF,:TRICK,:UTURN,:WILLOWISP]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# ZOROARK

MultipleForms.register(:ZOROARK,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:NORMAL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:GHOST) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [55,100,60,110,125,60] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:ILLUSION),0]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:SHADOWCLAW],[1,:UTURN],[1,:HONECLAWS],[1,:SCRATCH],
                     [1,:LEER],[1,:TORMENT],[12,:SHADOWSNEAK],[16,:CURSE],
                     [20,:TAUNT],[24,:KNOCKOFF],[28,:SPITE],[34,:AGILITY],
                     [40,:SHADOWBALL],[46,:BITTERMALICE],[52,:NASTYPLOT],
                     [58,:FOULPLAY]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AERIALACE,:AGILITY,:BODYSLAM,:BRICKBREAK,:BURNINGJEALOUSY,
                     :CALMMIND,:CONFUSERAY,:CRUNCH,:CURSE,:DARKPULSE,:DIG,:ENDURE,
                     :FACADE,:FAKETEARS,:FLAMETHROWER,:FLING,:FOCUSBLAST,
                     :FOCUSPUNCH,:FOULPLAY,:GIGAIMPACT,:GRASSKNOT,:HELPINGHAND,
                     :HEX,:HYPERBEAM,:HYPERVOICE,:ICYWIND,:IMPRISON,:KNOCKOFF,
                     :LASHOUT,:LOWKICK,:LOWSWEEP,:NASTYPLOT,:NIGHTSHADE,:PAINSPLIT,
                     :PHANTOMFORCE,:POLTERGEIST,:PROTECT,:PSYCHIC,:PSYCHUP,
                     :RAINDANCE,:REST,:ROAR,:SCARYFACE,:SHADOWBALL,:SHADOWCLAW,
                     :SKITTERSMACK,:SLEEPTALK,:SLUDGEBOMB,:SNARL,:SNOWSCAPE,:SPITE,
                     :SUBSTITUTE,:SWIFT,:SWORDSDANCE,:TAKEDOWN,:TAUNT,:THIEF,
                     :THROATCHOP,:TRICK,:UTURN,:WILLOWISP]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# BRAVIARY

MultipleForms.register(:BRAVIARY,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:PSYCHIC) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FLYING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [110,83,70,65,112,70] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:KEENEYE),0],
         [getID(PBAbilities,:SHEERFORCE),1],
         [getID(PBAbilities,:COMPETITIVE),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:ESPERWING],[1,:SUPERPOWER],[1,:LEER],[1,:WINGATTACK],
                     [1,:HONECLAWS],[1,:SKYATTACK],[1,:PECK],[18,:TAILWIND],
                     [24,:SCARYFACE],[30,:AERIALACE],[36,:SLASH],[42,:WHIRLWIND],
                     [48,:CRUSHCLAW],[57,:AIRSLASH],[64,:DEFOG],[72,:THRASH],
                     [80,:HURRICANE]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ACROBATICS,:AERIALACE,:AGILITY,:AIRCUTTER,:AIRSLASH,
                     :BODYSLAM,:BRAVEBIRD,:BULKUP,:CALMMIND,:CLOSECOMBAT,
                     :CONFUSERAY,:DAZZLINGGLEAM,:DOUBLEEDGE,:DUALWINGBEAT,
                     :ENDURE,:EXPANDINGFORCE,:FACADE,:FEATHERDANCE,:FLY,
                     :FUTURESIGHT,:GIGAIMPACT,:HEATWAVE,:HELPINGHAND,
                     :HURRICANE,:HYPERBEAM,:HYPERVOICE,:ICYWIND,:METALCLAW,
                     :NIGHTSHADE,:PROTECT,:PSYBEAM,:PSYCHIC,:PSYCHICNOISE,
                     :PSYCHICTERRAIN,:PSYCHUP,:PSYSHOCK,:RAINDANCE,:REST,
                     :REVERSAL,:ROCKSLIDE,:ROCKTOMB,:SCARYFACE,:SHADOWBALL,
                     :SHADOWCLAW,:SLEEPTALK,:SNARL,:STOREDPOWER,:SUBSTITUTE,
                     :SUNNYDAY,:SWIFT,:TAILWIND,:TAKEDOWN,:UTURN,:VACUUMWAVE,
                     :ZENHEADBUTT]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# SLIGGOO

MultipleForms.register(:SLIGGOO,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DRAGON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [58,75,83,40,83,113] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SAPSIPPER),0],
         [getID(PBAbilities,:SHELLARMOR),1],
         [getID(PBAbilities,:GOOEY),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:SHELTER],[1,:ACIDARMOR],[1,:DRAGONBREATH],[1,:TACKLE],
                     [1,:WATERGUN],[1,:ABSORB],[15,:PROTECT],[20,:FLAIL],
                     [25,:WATERPULSE],[30,:RAINDANCE],[35,:DRAGONPULSE],
                     [43,:CURSE],[49,:IRONHEAD],[56,:MUDDYWATER]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ACIDSPRAY,:BLIZZARD,:BODYSLAM,:CHARM,:CHILLINGWATER,:CURSE,
                     :DRACOMETEOR,:DRAGONPULSE,:ENDURE,:FACADE,:FLASHCANNON,
                     :GYROBALL,:HEAVYSLAM,:ICEBEAM,:ICESPINNER,:IRONHEAD,
                     :MUDDYWATER,:MUDSHOT,:OUTRAGE,:PROTECT,:RAINDANCE,:REST,
                     :ROCKSLIDE,:ROCKTOMB,:SANDSTORM,:SKITTERSMACK,:SLEEPTALK,
                     :SLUDGEBOMB,:SLUDGEWAVE,:STEELBEAM,:SUBSTITUTE,:SUNNYDAY,
                     :TAKEDOWN,:THUNDER,:THUNDERBOLT,:WATERPULSE
                     ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# GOODRA

MultipleForms.register(:GOODRA,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:STEEL) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:DRAGON) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [80,100,100,60,110,150] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:SAPSIPPER),0],
         [getID(PBAbilities,:SHELLARMOR),1],
         [getID(PBAbilities,:GOOEY),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:IRONTAIL],[1,:SHELTER],[1,:ACIDSPRAY],[1,:FEINT],
                     [1,:TEARFULLOOK],[1,:DRAGONBREATH],[1,:TACKLE],[1,:ABSORB],
                     [1,:WATERGUN],[15,:PROTECT],[20,:FLAIL],[25,:WATERPULSE],
                     [30,:RAINDANCE],[35,:DRAGONPULSE],[43,:CURSE],[49,:BODYSLAM],
                     [49,:IRONHEAD],[58,:MUDDYWATER],[67,:HEAVYSLAM]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :ACIDSPRAY,:BLIZZARD,:BODYPRESS,:BODYSLAM,:BREAKINGSWIPE,
                     :BULLDOZE,:CHARM,:CHILLINGWATER,:CURSE,:DRACOMETEOR,
                     :DRAGONCHEER,:DRAGONCLAW,:DRAGONPULSE,:DRAGONTAIL,:EARTHQUAKE,
                     :ENDURE,:FACADE,:FIREBLAST,:FIREPUNCH,:FLAMETHROWER,
                     :FLASHCANNON,:GIGAIMPACT,:GYROBALL,:HEAVYSLAM,:HYDROPUMP,
                     :HYPERBEAM,:ICEBEAM,:ICESPINNER,:IRONHEAD,:KNOCKOFF,:LASHOUT,
                     :MUDDYWATER,:MUDSHOT,:OUTRAGE,:PROTECT,:RAINDANCE,:REST,
                     :ROCKSLIDE,:ROCKTOMB,:SANDSTORM,:SCARYFACE,:SKITTERSMACK,
                     :SLEEPTALK,:SLUDGEBOMB,:SLUDGEWAVE,:STEELBEAM,
                     :STOMPINGTANTRUM,:SUBSTITUTE,:SUNNYDAY,:SURF,:TAKEDOWN,
                     :THUNDER,:THUNDERBOLT,:THUNDERPUNCH,:WATERPULSE,:WEATHERBALL,
                     :IRONDEFENSE
                    ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# AVALUGG

MultipleForms.register(:AVALUGG,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:ICE) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:ROCK) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [95,127,184,38,34,36] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:STRONGJAW),0],
         [getID(PBAbilities,:ICEBODY),1],
         [getID(PBAbilities,:STURDY),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:ROCKSLIDE],[1,:POWDERSNOW],[1,:RAPIDSPIN],[1,:WIDEGUARD],
                     [1,:HARDEN],[1,:TACKLE],[9,:CURSE],[12,:ICYWIND],[15,:PROTECT],
                     [18,:AVALANCHE],[21,:BITE],[24,:ICEFANG],[27,:IRONDEFENSE],
                     [30,:RECOVER],[33,:CRUNCH],[36,:TAKEDOWN],[41,:BLIZZARD],
                     [46,:DOUBLEEDGE],[51,:STONEEDGE],[61,:MOUNTAINGALE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AVALANCHE,:BLIZZARD,:BODYPRESS,:BODYSLAM,:BULLDOZE,
                     :CHILLINGWATER,:CRUNCH,:CURSE,:DIG,:DOUBLEEDGE,:EARTHQUAKE,
                     :ENDURE,:FACADE,:GIGAIMPACT,:GYROBALL,:HARDPRESS,:HEAVYSLAM,
                     :HIGHHORSEPOWER,:HYPERBEAM,:ICEBEAM,:ICEFANG,:ICESPINNER,
                     :ICICLESPEAR,:ICYWIND,:IRONDEFENSE,:IRONHEAD,:METEORBEAM,
                     :PROTECT,:RAINDANCE,:REST,:ROCKBLAST,:ROCKSLIDE,:ROCKTOMB,
                     :SANDSTORM,:SCARYFACE,:SLEEPTALK,:SNOWSCAPE,:STEALTHROCK,
                     :STOMPINGTANTRUM,:STONEEDGE,:SUBSTITUTE,:TAKEDOWN,:HYDROPUMP
                    ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# DECIDUEYE

MultipleForms.register(:DECIDUEYE,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && HISUI_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:GRASS) if pokemon.form==1
  next
},
"type2"=>proc{|pokemon|
  next getID(PBTypes,:FIGHTING) if pokemon.form==1
  next
},
"getBaseStats"=>proc{|pokemon|
  next [88,112,80,60,95,95] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:OVERGROW),0],
         [getID(PBAbilities,:LONGREACH),2]]
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[0,:TRIPLEARROWS],[1,:LEAFSTORM],[1,:LEAFAGE],[1,:TACKLE],
                     [1,:GROWL],[1,:UTURN],[9,:PECK],[12,:SHADOWSNEAK],
                     [15,:RAZORLEAF],[20,:SYNTHESIS],[25,:PLUCK],[30,:BULKUP],
                     [37,:SUCKERPUNCH],[44,:LEAFBLADE],[51,:FEATHERDANCE],
                     [58,:BRAVEBIRD]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[# MTs
                     :AERIALACE,:AIRCUTTER,:AIRSLASH,:AURASPHERE,:BATONPASS,
                     :BRAVEBIRD,:BRICKBREAK,:BULKUP,:BULLETSEED,:CLOSECOMBAT,
                     :COACHING,:CONFUSERAY,:DUALWINGBEAT,:ENDURE,:ENERGYBALL,
                     :FACADE,:FALSESWIPE,:FEATHERDANCE,:FOCUSBLAST,:FOCUSPUNCH,
                     :FRENZYPLANT,:GIGADRAIN,:GIGAIMPACT,:GRASSKNOT,:GRASSPLEDGE,
                     :GRASSYGLIDE,:GRASSYTERRAIN,:HAZE,:HELPINGHAND,:HYPERBEAM,
                     :KNOCKOFF,:LEAFSTORM,:LIGHTSCREEN,:LOWKICK,:LOWSWEEP,
                     :MAGICALLEAF,:NASTYPLOT,:NIGHTSHADE,:PROTECT,:RAINDANCE,
                     :REST,:REVERSAL,:ROCKTOMB,:SCARYFACE,:SEEDBOMB,:SHADOWCLAW,
                     :SLEEPTALK,:SMACKDOWN,:SOLARBEAM,:SUBSTITUTE,:SUNNYDAY,:SWIFT,
                     :SWORDSDANCE,:TAILWIND,:TAKEDOWN,:TAUNT,:TRAILBLAZE,
                     :UPPERHAND,:UTURN]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

########################################################################
######################### Formas Paldea ################################
########################################################################

# WOOPER
MultipleForms.register(:WOOPER,{
"getFormOnCreation"=>proc{|pokemon|
   if $game_map && PALDEA_MAPS.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
  next getID(PBTypes,:POISON) if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:POISONPOINT),0],
         [getID(PBAbilities,:WATERABSORB),1],
         [getID(PBAbilities,:UNAWARE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TAILWHIP],[1,:MUDSHOT],[4,:TACKLE],[8,:POISONTAIL],
                     [12,:TOXICSPIKES],[16,:SLAM],[21,:YAWN],[24,:POISONJAB],
                     [28,:SLUDGEWAVE],[32,:AMNESIA],[36,:TOXIC],[40,:EARTHQUAKE]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[:PROTECT,:SUBSTITUTE,:RAINDANCE,:SUNNYDAY,:ATTRACT,:TAUNT,
                     :EARTHQUAKE,:TOXIC,:SWAGGER,:REST,:SLEEPTALK,:DOUBLETEAM,
                     :RETURN,:FRUSTRATION,:HIDDENPOWER,:FACADE,:STOMPINGTANTRUM,
                     :SLUDGEWAVE,:POISONJAB,:DIG,:ROCKTOMB,:SANDSTORM,:BLIZZARD,
                     :SLUDGEBOMB,:STONEEDGE,:BODYPRESS,:WATERFALL,:SURF,
                     :ROCKSLIDE,:LIQUIDATION,:STEALTHROCK,:IRONTAIL]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})

# TAUROS

MultipleForms.register(:TAUROS,{
"getFormOnCreation"=>proc{|pokemon|
   maps1=PALDEA_MAPS   # ID del mapa para la Variante Combatiente
   maps2=[140]         # ID del mapa para la Variante Ardiente
   maps3=[142]         # ID del mapa para la Variante Acuática
   if $game_map && maps1.include?($game_map.map_id)
     next 1
   elsif $game_map && maps2.include?($game_map.map_id)
     next 2
   elsif $game_map && maps3.include?($game_map.map_id)
     next 3
   else
     next 0
   end
},
"type1"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:FIGHTING)   # Variante Combatiente
   when 2; next getID(PBTypes,:FIGHTING)   # Variante Ardiente
   when 3; next getID(PBTypes,:FIGHTING)   # Variante Acuática
   end
},
"type2"=>proc{|pokemon|
   next if pokemon.form==0             # Forma Normal
   case pokemon.form
   when 1; next getID(PBTypes,:FIGHTING)   # Variante Combatiente
   when 2; next getID(PBTypes,:FIRE)       # Variante Ardiente
   when 3; next getID(PBTypes,:WATER)      # Variante Acuática
   end
},
"getBaseStats"=>proc{|pokemon|
   next if pokemon.form==0              # Forma Normal
   case pokemon.form
   when 1; next [75,110,105,100,30,70]  # Variante Combatiente
   when 2; next [75,110,105,100,30,70]  # Variante Ardiente
   when 3; next [75,110,105,100,30,70]  # Variante Acuática
  end
},
"getAbilityList"=>proc{|pokemon|
   case pokemon.form
   when 1; next [[getID(PBAbilities,:INTIMIDATE),0],[getID(PBAbilities,:ANGERPOINT),1],[getID(PBAbilities,:CUDCHEW),2]] # Variante Combatiente
   when 1; next [[getID(PBAbilities,:INTIMIDATE),0],[getID(PBAbilities,:ANGERPOINT),1],[getID(PBAbilities,:CUDCHEW),2]] # Variante Ardiente
   when 1; next [[getID(PBAbilities,:INTIMIDATE),0],[getID(PBAbilities,:ANGERPOINT),1],[getID(PBAbilities,:CUDCHEW),2]] # Variante Acuática
   else;   next                                       
   end
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:TACKLE],[1,:TAILWHIP],[5,:WORKUP],[10,:DOUBLEKICK],[15,:ASSURANCE],
                     [20,:HEADBUTT],[25,:SCARYFACE],[30,:ZENHEADBUTT],[35,:RAGINGBULL],
                     [40,:REST],[45,:SWAGGER],[50,:THRASH],[55,:DOUBLEEDGE],[60,:CLOSECOMBAT]]
   when 2; movelist=[[1,:TACKLE],[1,:TAILWHIP],[5,:WORKUP],[10,:DOUBLEKICK],[15,:FLAMECHARGE],
                     [20,:HEADBUTT],[25,:SCARYFACE],[30,:ZENHEADBUTT],[35,:RAGINGBULL],
                     [40,:REST],[45,:SWAGGER],[50,:THRASH],[55,:FLAREBLITZ],[60,:CLOSECOMBAT]]
   when 3; movelist=[[1,:TACKLE],[1,:TAILWHIP],[5,:WORKUP],[10,:DOUBLEKICK],[15,:AQUAJET],
                     [20,:HEADBUTT],[25,:SCARYFACE],[30,:ZENHEADBUTT],[35,:RAGINGBULL],
                     [40,:REST],[45,:SWAGGER],[50,:THRASH],[55,:WAVECRASH],[60,:CLOSECOMBAT]]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
}
})

# URSALUNA
MultipleForms.register(:URSALUNA,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[42]                  # Map IDs for second form
   if $game_map && maps.include?($game_map.map_id)
     next 1
   else
     next 0
   end
},
"getBaseStats"=>proc{|pokemon|
  next [113,70,120,52,135,65] if pokemon.form==1
  next
},
"getAbilityList"=>proc{|pokemon|
   next if pokemon.form==0                    
   next [[getID(PBAbilities,:MINDSEYE),0],
         [getID(PBAbilities,:MINDSEYE),1],
         [getID(PBAbilities,:MINDSEYE),2]] 
},
"getMoveList"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[[1,:MOONLIGHT],[1,:HEADLONGRUSH],[1,:SCRATCH],[1,:LEER],
                     [1,:LICK],[8,:FURYSWIPES],[13,:PAYBACK],[17,:HARDEN],
                     [22,:SLASH],[25,:PLAYNICE],[35,:SCARYFACE],[41,:SNORE],
                     [41,:REST],[48,:EARTHPOWER],[56,:MOONBLAST],[64,:HAMMERARM],
                     [70,:BLOODMOON]
                    ]
   end
   for i in movelist
     i[1]=getConst(PBMoves,i[1])
   end
   next movelist
},
"getMoveCompatibility"=>proc{|pokemon|
   next if pokemon.form==0
   movelist=[]
   case pokemon.form
   when 1; movelist=[
                     :AVALANCHE,:BODYPRESS,:BODYSLAM,:BRICKBREAK,:BULLDOZE,
                     :CALMMIND,:CRUNCH,:DIG,:DOUBLEEDGE,:EARTHPOWER,:EARTHQUAKE,
                     :ENDURE,:FACADE,:FIREPUNCH,:FLING,:FOCUSBLAST,:FOCUSPUNCH,
                     :GIGAIMPACT,:GUNKSHOT,:HARDPRESS,:HEAVYSLAM,:HELPINGHAND,
                     :HIGHHORSEPOWER,:HYPERBEAM,:HYPERVOICE,:ICEPUNCH,:LOWKICK,
                     :METALCLAW,:MUDSHOT,:PROTECT,:RAINDANCE,:REST,:ROAR,
                     :ROCKSLIDE,:ROCKTOMB,:SCARYFACE,:SEEDBOMB,:SHADOWCLAW,
                     :SLEEPTALK,:SMACKDOWN,:SNARL,:STOMPINGTANTRUM,:STONEEDGE,
                     :SUBSTITUTE,:SUNNYDAY,:SWIFT,:SWORDSDANCE,:TAKEDOWN,:TAUNT,
                     :THIEF,:THUNDERPUNCH,:TRAILBLAZE,:UPROAR,:VACUUMWAVE
                    ]
   end
   for i in 0...movelist.length
     movelist[i]=getConst(PBMoves,movelist[i])
   end
   next movelist
}
})
