begin
  module PBEffects
    # These effects apply to a battler
    AquaRing           = 0
    Attract            = 1
    BatonPass          = 2
    Bide               = 3
    BideDamage         = 4
    BideTarget         = 5
    Charge             = 6
    ChoiceBand         = 7
    Confusion          = 8
    Counter            = 9
    CounterTarget      = 10
    Curse              = 11
    DefenseCurl        = 12
    DestinyBond        = 13
    Disable            = 14
    DisableMove        = 15
    Electrify          = 16
    Embargo            = 17
    Encore             = 18
    EncoreIndex        = 19
    EncoreMove         = 20
    Endure             = 21
    FirstPledge        = 22
    FlashFire          = 23
    Flinch             = 24
    FocusEnergy        = 25
    FollowMe           = 26
    Foresight          = 27
    FuryCutter         = 28
    FutureSight        = 29
    FutureSightMove    = 30
    FutureSightUser    = 31
    FutureSightUserPos = 32
    GastroAcid         = 33
    Grudge             = 34
    HealBlock          = 35
    HealingWish        = 36
    HelpingHand        = 37
    HyperBeam          = 38
    Illusion           = 39
    Imprison           = 40
    Ingrain            = 41
    KingsShield        = 42
    LeechSeed          = 43
    LifeOrb            = 44
    LockOn             = 45
    LockOnPos          = 46
    LunarDance         = 47
    MagicCoat          = 48
    MagnetRise         = 49
    MeanLook           = 50
    MeFirst            = 51
    Metronome          = 52
    MicleBerry         = 53
    Minimize           = 54
    MiracleEye         = 55
    MirrorCoat         = 56
    MirrorCoatTarget   = 57
    MoveNext           = 58
    MudSport           = 59
    MultiTurn          = 60 # Trapping move
    MultiTurnAttack    = 61
    MultiTurnUser      = 62
    Nightmare          = 63
    Outrage            = 64
    ParentalBond       = 65
    PerishSong         = 66
    PerishSongUser     = 67
    PickupItem         = 68
    PickupUse          = 69
    Pinch              = 70 # Battle Palace only
    Powder             = 71
    PowerTrick         = 72
    Protect            = 73
    ProtectNegation    = 74
    ProtectRate        = 75
    Pursuit            = 76
    Quash              = 77
    Rage               = 78
    Revenge            = 79
    Roar               = 80
    Rollout            = 81
    Roost              = 82
    SkipTurn           = 83 # For when using Poké Balls/Poké Dolls
    SkyDrop            = 84
    SmackDown          = 85
    Snatch             = 86
    SpikyShield        = 87
    Stockpile          = 88
    StockpileDef       = 89
    StockpileSpDef     = 90
    Substitute         = 91
    Taunt              = 92
    Telekinesis        = 93
    Torment            = 94
    Toxic              = 95
    Transform          = 96
    Truant             = 97
    TwoTurnAttack      = 98
    Type3              = 99
    Unburden           = 100
    Uproar             = 101
    Uturn              = 102
    WaterSport         = 103
    WeightChange       = 104
    Wish               = 105
    WishAmount         = 106
    WishMaker          = 107
    Yawn               = 108
    LaserFocus         = 110
    BanefulBunker      = 111
    ThroatChop         = 112
    ShellTrap          = 121
    Stakeout           = 122
    Dancer             = 123
    Obstruct           = 124
    JawLock            = 125
    JawLockUser        = 126
    TarShot            = 127
    Octolock           = 128
    OctolockUser       = 129
    PerishBody         = 130
    NoRetreat          = 131
    GorillaTactics     = 132
    CorrosiveGas       = 133
    LashOut            = 134
    BurningJealousy    = 135
    Mimicry            = 136
    PowerShift         = 137
    CudChew            = 138
    GigatonHammer      = 139
    SaltCure           = 140
    RevivalBlessing    = 141
    Silktrap           = 142
    RageFist           = 143
    SyrupBomb          = 144
    BurningBulwark     = 145
    Commander          = 146
    GlaiveRush         = 147
    ShedTail           = 148
    Protosynthesis     = 150
    BoosterEnergy      = 151 
    

    ZHeal              = 149
    Dynamax            = 152
    DBoost             = 153
    DButton            = 154
    # Max Move Effects
    MaxGuard           = 155  # The effect for the move Max Guard.
    ChiStrike          = 166  # The crit-boosting effect of G-Max Chi Strike.
    # Gigantamax
    Gigantamax         = 167
    MaxMove1           = 168
    MaxMove2           = 169
    MaxMove3           = 170
    MaxMove4           = 171

    ############################################################################
    # These effects apply to a side
    CraftyShield       = 0
    EchoedVoiceCounter = 1
    EchoedVoiceUsed    = 2
    LastRoundFainted   = 3
    LightScreen        = 4
    LuckyChant         = 5
    MatBlock           = 6
    Mist               = 7
    QuickGuard         = 8
    Rainbow            = 9
    Reflect            = 10
    Round              = 11
    Safeguard          = 12
    SeaOfFire          = 13
    Spikes             = 14
    StealthRock        = 15
    StickyWeb          = 16
    Swamp              = 17
    Tailwind           = 18
    ToxicSpikes        = 19
    WideGuard          = 20
    AuroraVeil         = 21
    FaintedAlly        = 22

    VineLash           = 101  # The lingering effect of G-Max Vine Lash.
    WildFire           = 102  # The lingering effect of G-Max Wildfire.
    Cannonade          = 103  # The lingering effect of G-Max Cannonade.
    Volcalith          = 104  # The lingering effect of G-Max Volcalith.
    Steelsurge         = 105  # The hazard effect of G-Max Steelsurge.
    ############################################################################
    # These effects apply to the battle (i.e. both sides)
    ElectricTerrain = 0
    FairyLock       = 1
    FusionBolt      = 2
    FusionFlare     = 3
    GrassyTerrain   = 4
    Gravity         = 5
    IonDeluge       = 6
    MagicRoom       = 7
    MistyTerrain    = 8
    MudSportField   = 9
    TrickRoom       = 10
    WaterSportField = 11
    WonderRoom      = 12
    PsychicTerrain  = 13
    PlasmaFists     = 14
    
    ############################################################################
    # These effects apply to the usage of a move
    SkipAccuracyCheck = 0
    SpecialUsage      = 1
    PassedTrying      = 2
    TotalDamage       = 3
    LastMoveFailed    = 4
  end

rescue Exception
  if $!.is_a?(SystemExit) || "#{$!.class}"=="Reset"
    raise $!
  end
end