#===============================================================================
# * Unreal Time System - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It makes the time in game have its
# own clock that only pass when you are in game instead of using real time
# (like Harvest Moon and Zelda: Ocarina of Time).
#
#===============================================================================
#
# To this script works, put it above main. If you wish to some parts still use
# real time like the Trainer Card start time and Pokémon Trainer Memo, 
# just change 'pbGetTimeNow' to 'Time.now' in their scripts (in this example, 
# PokemonMap and PokeBattle_Pokemon scripts sections).
#
# The game tone only refreshes each 30 real time seconds. To change this
# refresh interval, at PField_Time, change the '30' on line
# 'Graphics.frame_count-@dayNightToneLastUpdate>=Graphics.frame_rate*30'.
#
# This script use the Ruby Time class that can only hold years around 
# 1970-2038 range. If you wish to have other years values, sum/subtract when
# displaying the year. Examples: 
# If you wants year 1000, start in 1970 and, when displaying year name use 
# 'pbGetTimeNow.year-970'. 
# If you wants year 5000, start in 1970 and, when displaying year name use 
# 'pbGetTimeNow.year+3030'.
# 
# Some time methods:
# 'pbGetTimeNow.year', 'pbGetTimeNow.mon' (the numbers from 1-12), 
# 'pbGetTimeNow.day','pbGetTimeNow.hour', 'pbGetTimeNow.min', 
# 'pbGetTimeNow.sec', 'pbGetAbbrevMonthName(pbGetTimeNow.mon)',
# 'pbGetTimeNow.strftime("%A")' (displays weekday name),
# 'pbGetTimeNow.strftime("%I:%M %p")' (displays Hours:Minutes pm/am)
# 
#===============================================================================

# Set false to disable this system (returns Time.now)
NTN_ENABLED=true 

# Make this true to time only pass at field (Scene_Map) 
# A note to scripters: To make time pass on other scenes, put line
# '$PokemonGlobal.addNewFrameCount' near to line 'Graphics.update'
NTN_TIMESTOPS=true 

# Make this true to time pass in battle, during turns and command selection.
# This won't affect the Pokémon and Bag submenus.
# Only works if NTN_TIMESTOPS=true.
NTN_BATTLEPASS=true

# Make this true to time pass when the Dialog box or the main menu are open.
# This won't affect the submenus like Pokémon and Bag.
# Only works if NTN_TIMESTOPS=true.
NTN_TALKPASS=true

# Time proportion here. 
# So if it is 100, one second in real time will be 100 seconds in game.
# If it is 60, one second in real time will be one minute in game.
NTS_TIMEPROPORTION=60

# Choose switch number that when true the time won't pass (or -1 to cancel). 
# Only works if NTN_TIMESTOPS=true.
NTN_SWITCHSTOPS=-1

# Choose variable(s) number(s) that can hold time passage (or -1 to cancel).
# The time in this variable isn't affected by NTS_TIMEPROPORTION.
# Example: When the player sleeps you wish to the time in game advance
# 8 hours, so put in NTN_EXTRASECONDS a game variable number and sum 
# 28800 (60*60*8) in this variable every time that the players sleeps.
NTN_EXTRASECONDS=-1
NTN_EXTRADAYS=-1

# Initial values
NTN_INITIALYEAR=2000 # Can ONLY holds around range 1970-2038
NTN_INITIALMONTH=1
NTN_INITIALDAY=1
NTN_INITIALHOUR=12
NTN_INITIALMINUTE=0

def pbGetTimeNow
  return Time.now if !NTN_ENABLED
  
  if(NTN_TIMESTOPS)
    # Sum the extra values to newFrameCount
    if(NTN_EXTRASECONDS>0)
      $PokemonGlobal.newFrameCount+=(
        pbGet(NTN_EXTRASECONDS)*Graphics.frame_rate)/NTS_TIMEPROPORTION
      $game_variables[NTN_EXTRASECONDS]=0
    end  
    if(NTN_EXTRADAYS>0)
      $PokemonGlobal.newFrameCount+=((60*60*24)*
        pbGet(NTN_EXTRADAYS)*Graphics.frame_rate)/NTS_TIMEPROPORTION
      $game_variables[NTN_EXTRADAYS]=0
    end
  elsif(NTN_EXTRASECONDS>0 && NTN_EXTRADAYS>0)
    # Checks to regulate the max/min values at NTN_EXTRASECONDS
    while (pbGet(NTN_EXTRASECONDS)>=(60*60*24))
      $game_variables[NTN_EXTRASECONDS]-=(60*60*24)
      $game_variables[NTN_EXTRADAYS]+=1
    end
    while (pbGet(NTN_EXTRASECONDS)<=-(60*60*24))
      $game_variables[NTN_EXTRASECONDS]+=(60*60*24)
      $game_variables[NTN_EXTRADAYS]-=1
    end  
  end  
  start_time=Time.local(NTN_INITIALYEAR,NTN_INITIALMONTH,NTN_INITIALDAY,
    NTN_INITIALHOUR,NTN_INITIALMINUTE)
  time_played=(NTN_TIMESTOPS && $PokemonGlobal) ? 
    $PokemonGlobal.newFrameCount : Graphics.frame_count
  time_played=(time_played*NTS_TIMEPROPORTION)/Graphics.frame_rate
  time_jumped=0
  time_jumped+=pbGet(NTN_EXTRASECONDS) if NTN_EXTRASECONDS>-1 
  time_jumped+=pbGet(NTN_EXTRADAYS)*(60*60*24) if NTN_EXTRADAYS>-1 
  time_ret = nil
  # To prevent crashes due to year limit, every time that you reach in year 
  # 2036 the system will subtract 6 years (to works with leap year) from
  # your date and sum in $PokemonGlobal.extraYears. You can sum your actual
  # year with this extraYears when displaying years.
  loop do
    extraYears=($PokemonGlobal) ? $PokemonGlobal.extraYears : 0
    time_fix=extraYears*60*60*24*(365*6+1)/6
    time_ret=start_time+(time_played+time_jumped-time_fix)
    break if time_ret.year<2036
    $PokemonGlobal.extraYears+=6
  end
  return time_ret
end

if NTN_ENABLED
  class PokemonGlobalMetadata
    attr_accessor :newFrameCount
    attr_accessor :extraYears 
    
    def addNewFrameCount
      self.newFrameCount+=1 if !(
        NTN_SWITCHSTOPS>0 && $game_switches[NTN_SWITCHSTOPS])
    end
    
    def newFrameCount
      @newFrameCount=0 if !@newFrameCount
      return @newFrameCount
    end
    
    def extraYears
      @extraYears=0 if !@extraYears
      return @extraYears
    end
  end  

  if NTN_TIMESTOPS  
    class Scene_Map
      alias :updateold :update
    
      def update
        $PokemonGlobal.addNewFrameCount
        updateold
      end
    
      if NTN_TALKPASS  
        alias :miniupdateold :miniupdate
        
        def miniupdate
          $PokemonGlobal.addNewFrameCount 
          miniupdateold
        end
      end
    end  
  
    if NTN_BATTLEPASS
      class PokeBattle_Scene
        alias :pbGraphicsUpdateold :pbGraphicsUpdate
        
        def pbGraphicsUpdate
          $PokemonGlobal.addNewFrameCount 
          pbGraphicsUpdateold
        end
      end
    end
  end
end