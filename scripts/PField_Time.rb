#===============================================================================
# Sistema de día y noche
#===============================================================================
def pbGetTimeNow
  return Time.now
end



module PBDayNight
  HourlyTones=[
     Tone.new(-70,-70,11,68),   # Night     # Midnight
     Tone.new(-70,-70,11,68),   # Night
     Tone.new(-70,-70,11,68),   # Night
     Tone.new(-70,-70,11,68),   # Night
     Tone.new(-70,-70,11,68),   # Night
     Tone.new(-17,   -51, -85,17),   # Day/morning
     Tone.new(-17,   -51, -85,17),   # Day/morning      # 6AM
     Tone.new(-17,   -51, -85,17),   # Day/morning
     Tone.new(-17,   -51, -85,17),   # Day/morning
     Tone.new(0,     0,     0,    0),   # Day/morning
     Tone.new(0,     0,     0,    0),   # Day
     Tone.new(0,     0,     0,    0),   # Day
     Tone.new(0,     0,     0,    0),   # Day      # Noon
     Tone.new(0,     0,     0,    0),   # Day
     Tone.new(0,     0,     0,    0),   # Day/afternoon
     Tone.new(0,     0,     0,    0),   # Day/afternoon
     Tone.new(0,     0,     0,    0),   # Day/afternoon
     Tone.new(0,     0,     0,    0),   # Day/afternoon
     Tone.new(-30,   -30,   5,  68),   # Day/evening      # 6PM
     Tone.new(-30,   -30,   5,  68),   # Day/evening
     Tone.new(-35,   -35,   7,  68),   # Day/evening
     Tone.new(-70,-70,11,68),   # Night
     Tone.new(-70,-70,11,68),   # Night
     Tone.new(-70,-70,11,68)   # Night
  ]
  @cachedTone=nil
  @dayNightToneLastUpdate=nil
  @oneOverSixty=1/60.0

# Devuelve verdadero si es de día.
  def self.isDay?(time=nil)
    time=pbGetTimeNow if !time
    return (time.hour>=6 && time.hour<20)
  end

# Devuelve verdadero si es de noche.
  def self.isNight?(time=nil)
    time=pbGetTimeNow if !time
    return (time.hour>=20 || time.hour<6)
  end

# Returns true if it's dusk.
  def self.isDusk?(time=nil)
    time = pbGetTimeNow if !time
    return (time.hour>=17 && time.hour<18)
  end  
  
# Devuelve verdadero si es de mañana.
  def self.isMorning?(time=nil)
    time=pbGetTimeNow if !time
    return (time.hour>=6 && time.hour<12)
  end

# Devuelve verdadero si es de tarde.
  def self.isAfternoon?(time=nil)
    time=pbGetTimeNow if !time
    return (time.hour>=12 && time.hour<20)
  end

# Devuelve verdadero si está anocheciendo.
  def self.isEvening?(time=nil)
    time=pbGetTimeNow if !time
    return (time.hour>=17 && time.hour<20)
  end

# Devuelve un número representando la cantidad de luz de día.
# 0=completamente de noche, 255=completamente de día
  def self.getShade
    time=pbGetDayNightMinutes
    time=(24*60)-time if time>(12*60)
    shade=255*time/(12*60)
  end

# Devuelve un objeto Tone (es decir, Tono) representando el tono de sombra sugerido
# para la hora actual del día.
  def self.getTone()
    @cachedTone=Tone.new(0,0,0) if !@cachedTone
    return @cachedTone if !ENABLESHADING
    if !@dayNightToneLastUpdate || @dayNightToneLastUpdate!=Graphics.frame_count       
      getToneInternal()
      @dayNightToneLastUpdate=Graphics.frame_count
    end
    return @cachedTone
  end

  def self.pbGetDayNightMinutes
    now=pbGetTimeNow   # Get the current in-game time
    return (now.hour*60)+now.min
  end

  private

# Función interna

  def self.getToneInternal()
    # Calculates the tone for the current frame, used for day/night effects
    realMinutes=pbGetDayNightMinutes
    hour=realMinutes/60
    minute=realMinutes%60
    tone=PBDayNight::HourlyTones[hour]
    nexthourtone=PBDayNight::HourlyTones[(hour+1)%24]
    # Calculate current tint according to current and next hour's tint and
    # depending on current minute
    @cachedTone.red=((nexthourtone.red-tone.red)*minute*@oneOverSixty)+tone.red
    @cachedTone.green=((nexthourtone.green-tone.green)*minute*@oneOverSixty)+tone.green
    @cachedTone.blue=((nexthourtone.blue-tone.blue)*minute*@oneOverSixty)+tone.blue
    @cachedTone.gray=((nexthourtone.gray-tone.gray)*minute*@oneOverSixty)+tone.gray
  end
end



def pbDayNightTint(object)
  if !$scene.is_a?(Scene_Map)
    return
  else
    if ENABLESHADING && $game_map && pbGetMetadata($game_map.map_id,MetadataOutdoor)
      tone=PBDayNight.getTone()
      object.tone.set(tone.red,tone.green,tone.blue,tone.gray)
    else
      object.tone.set(0,0,0,0)  
    end
  end  
end



#===============================================================================
# Fases de la Luna y Zodíaco
#===============================================================================
# Determina la fase de la luna.
# 0 - New Moon         - Luna Nueva
# 1 - Waxing Crescent  - Luna Nueva Visible
# 2 - First Quarter    - Cuarto Creciente
# 3 - Waxing Gibbous   - Luna Gibosa Creciente
# 4 - Full Moon        - Luna Llena
# 5 - Waning Gibbous   - Luna Gibosa Menguante
# 6 - Last Quarter     - Cuarto Menguante
# 7 - Waning Crescent  - Luna Menguante
def moonphase(time=nil)              # en UTC
  time=pbGetTimeNow if !time
  transitions=[
     1.8456618033125,
     5.5369854099375,
     9.2283090165625,
     12.9196326231875,
     16.6109562298125,
     20.3022798364375,
     23.9936034430625,
     27.6849270496875]
  yy=time.year-((12-time.mon)/10.0).floor
  j=(365.25*(4712+yy)).floor + (((time.mon+9)%12)*30.6+0.5).floor + time.day+59
  j-=(((yy/100.0)+49).floor*0.75).floor-38 if j>2299160
  j+=(((time.hour*60)+time.min*60)+time.sec)/86400.0
  v=(j-2451550.1)/29.530588853
  v=((v-v.floor)+(v<0 ? 1 : 0))
  ag=v*29.53
  for i in 0...transitions.length
    return i if ag<=transitions[i]
  end
  return 0
end

# Calculates the zodiac sign based on the given month and day:
# 0 is Aries, 11 is Pisces. Month is 1 if January, and so on.
def zodiac(month,day)
  time=[
     3,21,4,19,   # Aries       - Aries
     4,20,5,20,   # Taurus      - Tauro
     5,21,6,20,   # Gemini      - Géminis
     6,21,7,20,   # Cancer      - Cáncer
     7,23,8,22,   # Leo         - Leo
     8,23,9,22,   # Virgo       - Virgo
     9,23,10,22,  # Libra       - Libra
     10,23,11,21, # Scorpio     - Escorpio
     11,22,12,21, # Sagittarius - Sagitario
     12,22,1,19,  # Capricorn   - Capricornio
     1,20,2,18,   # Aquarius    - Acuario
     2,19,3,20    # Pisces      - Piscis
  ]
  for i in 0...12
    return i if month==time[i*4] && day>=time[i*4+1]
    return i if month==time[i*4+2] && day<=time[i*4+2]
  end
  return 0
end
 
# Returns the opposite of the given zodiac sign.
# 0 is Aries, 11 is Pisces.
def zodiacOpposite(sign)
  return (sign+6)%12
end

# 0 is Aries, 11 is Pisces.
def zodiacPartners(sign)
  return [(sign+4)%12,(sign+8)%12]
end

# 0 is Aries, 11 is Pisces.
def zodiacComplements(sign)
  return [(sign+1)%12,(sign+11)%12]
end

#===============================================================================
# Días de la semana
#===============================================================================
def pbIsWeekday(wdayVariable,*arg)
  timenow=pbGetTimeNow
  wday=timenow.wday
  ret=false
  for wd in arg
    ret=true if wd==wday
  end
  if wdayVariable>0
    $game_variables[wdayVariable]=[ 
       _INTL("Domingo"),
       _INTL("Lunes"),
       _INTL("Martes"),
       _INTL("Miércoles"),
       _INTL("Jueves"),
       _INTL("Viernes"),
       _INTL("Sábado")][wday] 
    $game_map.need_refresh = true if $game_map
  end
  return ret
end

#===============================================================================
# Meses
#===============================================================================
def pbIsMonth(monVariable,*arg)
  timenow=pbGetTimeNow
  thismon=timenow.mon
  ret=false
  for wd in arg
    ret=true if wd==thismon
  end
  if monVariable>0
    $game_variables[monVariable]=[ 
       _INTL("Enero"),
       _INTL("Febrero"),
       _INTL("Marzo"),
       _INTL("Abril"),
       _INTL("Mayo"),
       _INTL("Junio"),
       _INTL("Julio"),
       _INTL("Agosto"),
       _INTL("Septiembre"),
       _INTL("Octubre"),
       _INTL("Noviembre"),
       _INTL("Diciembre")][thismon-1] 
    $game_map.need_refresh = true if $game_map
  end
  return ret
end

def pbGetAbbrevMonthName(month)
  return ["",
          _INTL("Ene."),
          _INTL("Feb."),
          _INTL("Mar."),
          _INTL("Abr."),
          _INTL("May"),
          _INTL("Jun."),
          _INTL("Jul."),
          _INTL("Ago."),
          _INTL("Sep."),
          _INTL("Oct."),
          _INTL("Nov."),
          _INTL("Dic.")][month]
end

#===============================================================================
# Estaciones
#===============================================================================
def pbGetSeason
  return (pbGetTimeNow.mon-1)%4
end

def pbIsSeason(seasonVariable,*arg)
  thisseason=pbGetSeason
  ret=false
  for wd in arg
    ret=true if wd==thisseason
  end
  if seasonVariable>0
    $game_variables[seasonVariable]=[ 
       _INTL("Primavera"),
       _INTL("Verano"),
       _INTL("Otoño"),
       _INTL("Invierno")][thisseason] 
    $game_map.need_refresh = true if $game_map
  end
  return ret
end

def pbIsSpring; return pbIsSeason(0,0); end   # Ene, May, Sep
def pbIsSummer; return pbIsSeason(0,1); end   # Feb, Jun, Oct
def pbIsAutumn; return pbIsSeason(0,2); end   # Mar, Jul, Nov
def pbIsFall; return pbIsAutumn; end
def pbIsWinter; return pbIsSeason(0,3); end   # Abr, Ago, Dic

def pbGetSeasonName(season)
  return [_INTL("Primavera"),
          _INTL("Verano"),
          _INTL("Otoño"),
          _INTL("Invierno")][season]
end