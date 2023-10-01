local mod = RegisterMod('Randomness Challenge', 1)
local json = require('json')
local game = Game()
local sfx = SFXManager()

mod.onGameStartHasRun = false
mod.isMomDead = false
mod.playerHash = nil
mod.playerType = nil
mod.showName = false
mod.rng = RNG()
mod.rngShiftIndex = 35

mod.isaacTemplate = { player = PlayerType.PLAYER_ISAAC, maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil }

-- only include items that the game doesn't setup by default, usually these are unlockable items (+ hearts, keys, bombs, coins)
-- hearts except for bone hearts require x2 for full hearts
-- init: characters will get their default items if changed in init, some characters like jacob or tainted forgotten have issues being changed in init (crashes, buggy behavior, etc)
mod.regularPlayerTypes = {
  { player = PlayerType.PLAYER_ISAAC,        init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = CollectibleType.COLLECTIBLE_D6,            trinket = nil,                              keys = 0, bombs = 1, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_MAGDALENE,    init = true,  maxhp = 8, bonehp = 0, redhp = 8, soulhp = 0, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_CAIN,         init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = nil,                                       trinket = TrinketType.TRINKET_PAPER_CLIP,   keys = 1, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_JUDAS,        init = true,  maxhp = 2, bonehp = 0, redhp = 2, soulhp = 0, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 3, twin = nil },
  { player = PlayerType.PLAYER_BLUEBABY,     init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 6, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_EVE,          init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = CollectibleType.COLLECTIBLE_RAZOR_BLADE,   trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_SAMSON,       init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil,                                       trinket = TrinketType.TRINKET_CHILDS_HEART, keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_AZAZEL,       init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 0, blackhp = 6, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_LAZARUS,      init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = CollectibleType.COLLECTIBLE_ANEMIC,        trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_THELOST,      init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 0, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 1, twin = nil },
  { player = PlayerType.PLAYER_LILITH,       init = true,  maxhp = 2, bonehp = 0, redhp = 2, soulhp = 0, blackhp = 4, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_KEEPER,       init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = CollectibleType.COLLECTIBLE_WOODEN_NICKEL, trinket = TrinketType.TRINKET_STORE_KEY,    keys = 0, bombs = 1, coins = 1, twin = nil },
  { player = PlayerType.PLAYER_APOLLYON,     init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_THEFORGOTTEN, init = true,  maxhp = 0, bonehp = 2, redhp = 4, soulhp = 0, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = { maxhp = 0, bonehp = 0, redhp = 0, soulhp = 2, blackhp = 0 } }, -- the soul needs health otherwise it won't appear
  { player = PlayerType.PLAYER_BETHANY,      init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 4, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = nil }, -- 4 soul charges rather than 8
  { player = PlayerType.PLAYER_JACOB,        init = false, maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil,                                       trinket = nil,                              keys = 0, bombs = 0, coins = 0, twin = { maxhp = 2, bonehp = 0, redhp = 2, soulhp = 2, blackhp = 0 } } -- esau health
}
mod.taintedPlayerTypes = {
  { player = PlayerType.PLAYER_ISAAC_B,        init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 1, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_MAGDALENE_B,    init = true,  maxhp = 8, bonehp = 0, redhp = 2, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil }, -- red hearts need to be 2 instead of 4?
  { player = PlayerType.PLAYER_CAIN_B,         init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 1, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_JUDAS_B,        init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 0, blackhp = 4, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 3, twin = nil },
  { player = PlayerType.PLAYER_BLUEBABY_B,     init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 6, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 3, coins = 0, twin = nil }, -- 3 poop bombs
  { player = PlayerType.PLAYER_EVE_B,          init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_SAMSON_B,       init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_AZAZEL_B,       init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 0, blackhp = 6, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_LAZARUS_B,      init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil }, -- we don't need to set lazarus2's health
  { player = PlayerType.PLAYER_THELOST_B,      init = true,  maxhp = 0, bonehp = 0, redhp = 0, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 1, twin = nil },
  { player = PlayerType.PLAYER_LILITH_B,       init = true,  maxhp = 2, bonehp = 0, redhp = 2, soulhp = 0, blackhp = 4, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_KEEPER_B,       init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 1, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_APOLLYON_B,     init = true,  maxhp = 4, bonehp = 0, redhp = 4, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil },
  { player = PlayerType.PLAYER_THEFORGOTTEN_B, init = false, maxhp = 0, bonehp = 0, redhp = 0, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = { maxhp = 0, bonehp = 0, redhp = 0, soulhp = 6, blackhp = 0 } }, -- soul health
  { player = PlayerType.PLAYER_BETHANY_B,      init = true,  maxhp = 0, bonehp = 0, redhp = 6, soulhp = 6, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil }, -- 6 blood charges rather than 12
  { player = PlayerType.PLAYER_JACOB_B,        init = true,  maxhp = 6, bonehp = 0, redhp = 6, soulhp = 0, blackhp = 0, item = nil, trinket = nil, keys = 0, bombs = 0, coins = 0, twin = nil }
}

-- endstage: use 2 of 2 and not the void
-- the beast goes directly to a cutscene, so not including delirium as an option
mod.endingBosses = {
  { name = 'Mom',                                                        weight = 3, endstage = LevelStage.STAGE3_2, altpath = false, secretpath = false, hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> Delirium',                                            weight = 1, endstage = LevelStage.STAGE3_2, altpath = false, secretpath = false, hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> It Lives',                                            weight = 3, endstage = LevelStage.STAGE4_2, altpath = false, secretpath = false, hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Delirium',                                weight = 1, endstage = LevelStage.STAGE4_2, altpath = false, secretpath = false, hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Satan',                                   weight = 3, endstage = LevelStage.STAGE5,   altpath = false, secretpath = false, hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Satan -> Delirium',                       weight = 1, endstage = LevelStage.STAGE5,   altpath = false, secretpath = false, hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Satan -> The Lamb',                       weight = 3, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Satan -> The Lamb -> Delirium',           weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Satan -> Mega Satan',                     weight = 3, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = false, megasatan = true,  delirium = false },
  { name = 'Mom -> It Lives -> Satan -> Mega Satan -> Delirium',         weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = false, megasatan = true,  delirium = true },
  { name = 'Mom -> It Lives -> Isaac',                                   weight = 3, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = false, hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Isaac -> Delirium',                       weight = 1, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = false, hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Isaac -> Blue Baby',                      weight = 3, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Isaac -> Blue Baby -> Delirium',          weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Isaac -> Mega Satan',                     weight = 3, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = false, megasatan = true,  delirium = false },
  { name = 'Mom -> It Lives -> Isaac -> Mega Satan -> Delirium',         weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = false, megasatan = true,  delirium = true },
  { name = 'Mom -> It Lives -> Hush',                                    weight = 2, endstage = LevelStage.STAGE4_3, altpath = false, secretpath = false, hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Delirium',                        weight = 1, endstage = LevelStage.STAGE4_3, altpath = false, secretpath = false, hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Hush -> Satan',                           weight = 2, endstage = LevelStage.STAGE5,   altpath = false, secretpath = false, hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Satan -> Delirium',               weight = 1, endstage = LevelStage.STAGE5,   altpath = false, secretpath = false, hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Hush -> Satan -> The Lamb',               weight = 2, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Satan -> The Lamb -> Delirium',   weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Hush -> Satan -> Mega Satan',             weight = 2, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = true,  megasatan = true,  delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Satan -> Mega Satan -> Delirium', weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = false, hush = true,  megasatan = true,  delirium = true },
  { name = 'Mom -> It Lives -> Hush -> Isaac',                           weight = 2, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = false, hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Isaac -> Delirium',               weight = 1, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = false, hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Hush -> Isaac -> Blue Baby',              weight = 2, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Isaac -> Blue Baby -> Delirium',  weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> It Lives -> Hush -> Isaac -> Mega Satan',             weight = 2, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = true,  megasatan = true,  delirium = false },
  { name = 'Mom -> It Lives -> Hush -> Isaac -> Mega Satan -> Delirium', weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = false, hush = true,  megasatan = true,  delirium = true },
  { name = 'Knife -> Mom',                                               weight = 3, endstage = LevelStage.STAGE3_2, altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = false },
  { name = 'Knife -> Mom -> Delirium',                                   weight = 1, endstage = LevelStage.STAGE3_2, altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> Mother',                                              weight = 3, endstage = LevelStage.STAGE4_2, altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Delirium',                                  weight = 1, endstage = LevelStage.STAGE4_2, altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Satan',                                     weight = 3, endstage = LevelStage.STAGE5,   altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Satan -> Delirium',                         weight = 1, endstage = LevelStage.STAGE5,   altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Satan -> The Lamb',                         weight = 3, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Satan -> The Lamb -> Delirium',             weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Satan -> Mega Satan',                       weight = 3, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = false, megasatan = true,  delirium = false },
  { name = 'Mom -> Mother -> Satan -> Mega Satan -> Delirium',           weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = false, megasatan = true,  delirium = true },
  { name = 'Mom -> Mother -> Isaac',                                     weight = 3, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = true,  hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Isaac -> Delirium',                         weight = 1, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = true,  hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Isaac -> Blue Baby',                        weight = 3, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = false, megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Isaac -> Blue Baby -> Delirium',            weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = false, megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Isaac -> Mega Satan',                       weight = 3, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = false, megasatan = true,  delirium = false },
  { name = 'Mom -> Mother -> Isaac -> Mega Satan -> Delirium',           weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = false, megasatan = true,  delirium = true },
  { name = 'Mom -> Mother -> Hush',                                      weight = 2, endstage = LevelStage.STAGE4_3, altpath = false, secretpath = true,  hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Hush -> Delirium',                          weight = 1, endstage = LevelStage.STAGE4_3, altpath = false, secretpath = true,  hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Hush -> Satan',                             weight = 2, endstage = LevelStage.STAGE5,   altpath = false, secretpath = true,  hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Hush -> Satan -> Delirium',                 weight = 1, endstage = LevelStage.STAGE5,   altpath = false, secretpath = true,  hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Hush -> Satan -> The Lamb',                 weight = 2, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Hush -> Satan -> The Lamb -> Delirium',     weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Hush -> Satan -> Mega Satan',               weight = 2, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = true,  megasatan = true,  delirium = false },
  { name = 'Mom -> Mother -> Hush -> Satan -> Mega Satan -> Delirium',   weight = 1, endstage = LevelStage.STAGE6,   altpath = false, secretpath = true,  hush = true,  megasatan = true,  delirium = true },
  { name = 'Mom -> Mother -> Hush -> Isaac',                             weight = 2, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = true,  hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Hush -> Isaac -> Delirium',                 weight = 1, endstage = LevelStage.STAGE5,   altpath = true,  secretpath = true,  hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Hush -> Isaac -> Blue Baby',                weight = 2, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = true,  megasatan = false, delirium = false },
  { name = 'Mom -> Mother -> Hush -> Isaac -> Blue Baby -> Delirium',    weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = true,  megasatan = false, delirium = true },
  { name = 'Mom -> Mother -> Hush -> Isaac -> Mega Satan',               weight = 2, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = true,  megasatan = true,  delirium = false },
  { name = 'Mom -> Mother -> Hush -> Isaac -> Mega Satan -> Delirium',   weight = 1, endstage = LevelStage.STAGE6,   altpath = true,  secretpath = true,  hush = true,  megasatan = true,  delirium = true },
  { name = 'Ascent -> The Beast',                                        weight = 5, endstage = LevelStage.STAGE8,   altpath = false, secretpath = false, hush = false, megasatan = false, delirium = false }, -- there's no way to consistently spawn the door to the pre-ascent so we'll go to the mausoleum via the boss room
  { name = 'Knife -> Ascent -> The Beast',                               weight = 5, endstage = LevelStage.STAGE8,   altpath = false, secretpath = true,  hush = false, megasatan = false, delirium = false }
}

mod.backdropTypes = {
  BackdropType.BASEMENT,
  BackdropType.CELLAR,
  BackdropType.BURNT_BASEMENT,
  BackdropType.CAVES,
  BackdropType.CATACOMBS,
  BackdropType.FLOODED_CAVES,
  BackdropType.DEPTHS,
  BackdropType.NECROPOLIS,
  BackdropType.DANK_DEPTHS,
  BackdropType.WOMB,
  BackdropType.UTERO,
  BackdropType.SCARRED_WOMB,
  BackdropType.BLUE_WOMB,
  BackdropType.SHEOL,
  BackdropType.CATHEDRAL,
  BackdropType.DARKROOM,
  BackdropType.CHEST,
  BackdropType.DOWNPOUR,
  BackdropType.MINES,
  BackdropType.MAUSOLEUM,
  BackdropType.CORPSE,
  BackdropType.MAUSOLEUM2,
  BackdropType.MAUSOLEUM3,
  BackdropType.MAUSOLEUM4,
  BackdropType.CORPSE2,
  BackdropType.CORPSE3,
  BackdropType.DROSS,
  BackdropType.ASHPIT,
  BackdropType.GEHENNA,
  BackdropType.MORTIS,
}

mod.state = {}
mod.state.defaultNumKeys = 0
mod.state.defaultNumBombs = 0
mod.state.defaultNumCoins = 0
mod.state.endingBoss = { name = '', weight = 0, endstage = 0, altpath = false, secretpath = false, hush = false, megasatan = false, delirium = false }

function mod:onGameStart(isContinue)
  if not mod:isChallenge() then
    return
  end
  
  if isContinue then
    local die = false
    
    if mod:HasData() then
      local _, state = pcall(json.decode, mod:LoadData())
      
      if type(state) == 'table' and
         math.type(state.defaultNumKeys) == 'integer' and
         math.type(state.defaultNumBombs) == 'integer' and
         math.type(state.defaultNumCoins) == 'integer' and
         type(state.endingBoss) == 'table' and
         type(state.endingBoss.name) == 'string' and
         math.type(state.endingBoss.weight) == 'integer' and state.endingBoss.weight >= 0 and
         math.type(state.endingBoss.endstage) == 'integer' and state.endingBoss.endstage > LevelStage.STAGE_NULL and state.endingBoss.endstage < LevelStage.NUM_STAGES and
         type(state.endingBoss.altpath) == 'boolean' and
         type(state.endingBoss.secretpath) == 'boolean' and
         type(state.endingBoss.hush) == 'boolean' and
         type(state.endingBoss.megasatan) == 'boolean' and
         type(state.endingBoss.delirium) == 'boolean'
      then
        mod.state.defaultNumKeys = state.defaultNumKeys
        mod.state.defaultNumBombs = state.defaultNumBombs
        mod.state.defaultNumCoins = state.defaultNumCoins
        mod:setEndingBoss(state.endingBoss)
      else
        die = true
      end
    else
      die = true
    end
    
    if die then
      -- die so we can restart and get back to a good state
      for i = 0, game:GetNumPlayers() - 1 do
        local player = game:GetPlayer(i)
        player:Die() -- Kill
      end
    end
  else -- not continue
    local weightedEndingBosses = {}
    for _, endingBoss in ipairs(mod.endingBosses) do
      for i = 1, endingBoss.weight do
        table.insert(weightedEndingBosses, endingBoss)
      end
    end
    
    mod:setEndingBoss(weightedEndingBosses[mod.rng:RandomInt(#weightedEndingBosses) + 1])
    
    if mod.state.endingBoss.megasatan then
      mod:addKeyPieces()
    end
    if mod.state.endingBoss.endstage == LevelStage.STAGE8 then -- beast
      game:SetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH_INIT, true) -- no harm in setting this early
    end
    
    -- there's a small edge case if you use the clicker to change to eden and then quit/continue
    -- this reruns onPlayerInit which would change you to another character again
    local itemPool = game:GetItemPool()
    itemPool:RemoveCollectible(CollectibleType.COLLECTIBLE_CLICKER)
  end
  
  mod.showName = true
  mod.onGameStartHasRun = true
  mod:onNewRoom()
end

function mod:onGameExit(shouldSave)
  if shouldSave then
    mod:SaveData(json.encode(mod.state))
    mod.state.defaultNumKeys = 0
    mod.state.defaultNumBombs = 0
    mod.state.defaultNumCoins = 0
    mod:clearEndingBoss()
  else
    mod.state.defaultNumKeys = 0
    mod.state.defaultNumBombs = 0
    mod.state.defaultNumCoins = 0
    mod:clearEndingBoss()
    mod:SaveData(json.encode(mod.state))
  end
  
  mod.onGameStartHasRun = false
  mod.isMomDead = false
  mod.playerHash = nil
  mod.playerType = nil
  mod.showName = false
  mod:seedRng()
end

function mod:onNewRoom()
  if not mod:isChallenge() then
    return
  end
  
  if not mod.onGameStartHasRun then
    return
  end
  
  if mod:isTrainerChallenge() then
    mod:changeBackdropType()
  end
  
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  local currentDimension = mod:getCurrentDimension()
  local isCurse = mod:isCurseOfTheLabyrinth()
  
  mod.isMomDead = false
  
  if level:IsAscent() then
    if roomDesc.GridIndex == level:GetStartingRoomIndex() and currentDimension == 0 then
      mod:spawnTrapdoor(room:GetCenterPos()) -- spawn heaven door during ascent
    elseif not mod:isRepentanceStageType() and mod:isMom() then
      mod:updateMausoleumTrapdoor() -- show mausoleum trapdoor sprite
    end
  else -- not ascent
    if ( -- enter boss room after killing mausoleum heart
         (stage == LevelStage.STAGE3_2 or (isCurse and stage == LevelStage.STAGE3_1)) and
         mod:isRepentanceStageType() and room:IsCurrentRoomLastBoss() and
         game:GetStateFlag(GameStateFlag.STATE_MAUSOLEUM_HEART_KILLED)
       ) or
       ( -- enter blue woom
         (stage == LevelStage.STAGE4_2 or (isCurse and stage == LevelStage.STAGE4_1)) and
         roomDesc.GridIndex == GridRooms.ROOM_BLUE_WOOM_IDX
       ) or
       ( -- enter void room
         stage == LevelStage.STAGE4_3 and roomDesc.GridIndex == GridRooms.ROOM_THE_VOID_IDX
       )
    then
      mod:spawnTrapdoor(room:GetCenterPos()) -- trapdoors will stick around
    elseif mod.state.endingBoss.megasatan and stage == LevelStage.STAGE6 then
      if roomDesc.GridIndex == level:GetStartingRoomIndex() and currentDimension == 0 then
        mod:spawnMegaSatanRoomDoor() -- spawn mega satan door in first room
      elseif roomDesc.GridIndex == GridRooms.ROOM_MEGA_SATAN_IDX and room:IsClear() then
        mod:spawnMegaSatanDoorExit()
      end
    elseif room:IsClear() then
      if mod:hasMoreStagesToGo() then
        if mod.state.endingBoss.hush and mod:isMother() then -- re-enter mother room after clearing, and headed to hush
          mod:updateBlueWombTrapdoor() -- the game automatically makes this look like a regular trapdoor, update the sprite again
        elseif mod.state.endingBoss.endstage == LevelStage.STAGE8 and not mod:isRepentanceStageType() and mod:isMom() then
          mod:updateMausoleumTrapdoor()
        elseif room:IsCurrentRoomLastBoss() then -- re-enter boss room after clearing
          if mod:shouldSpawnBlueWombDoor() then
            mod:spawnBlueWombDoor(false)
          elseif mod:shouldSpawnSecretExit() then
            mod:spawnSecretExit(false) -- for whatever reason, trapdoors in secret exit rooms don't need to be spawned
          end
        end
      else -- no more stages to go
        if mod.state.endingBoss.delirium and mod:isHush() then -- re-enter hush room after clearing
          mod:spawnTheVoidDoor() -- doors have to be re-spawned every time
        end
      end
    end
  end
end

function mod:onUpdate()
  if not mod:isChallenge() then
    return
  end
  
  local level = game:GetLevel()
  local hud = game:GetHUD()
  
  mod:closeSecretExitTrapdoor()
  mod:updateCorpseStage()
  mod:setSecretPath()
  
  if mod.showName then
    hud:ShowItemText(level:GetName(), mod.state.endingBoss.name, false)
    mod.showName = false
  end
end

-- check input every frame
function mod:onRender()
  if not mod:isChallenge() then
    return
  end
  
  if game:IsPaused() then
    return
  end
  
  for i = 0, game:GetNumPlayers() - 1 do
    local player = game:GetPlayer(i)
    if Input.IsActionTriggered(ButtonAction.ACTION_MAP, player.ControllerIndex) then
      mod.showName = true
      break
    end
  end
end

function mod:onPreEntitySpawn(entityType, variant, subType, position, velocity, spawner, seed)
  if not mod:isChallenge() then
    return
  end
  
  local room = game:GetRoom()
  
  -- there's options doesn't seem to work in the mom boss room in challenges so we don't need to worry about different positioning
  if entityType == EntityType.ENTITY_PICKUP and variant == PickupVariant.PICKUP_COLLECTIBLE and
     mod.isMomDead and mod:isMom() and room:IsClear() and
     position.X == 320 and position.Y == 360 and velocity.X == 0 and velocity.Y == 0 and spawner == nil
  then
    mod.isMomDead = false
    
    if mod.state.endingBoss.endstage == LevelStage.STAGE5 or mod.state.endingBoss.endstage == LevelStage.STAGE6 then
      if mod.state.endingBoss.altpath then
        return { entityType, variant, CollectibleType.COLLECTIBLE_POLAROID, seed } -- isaac/blue baby
      else -- not altpath
        return { entityType, variant, CollectibleType.COLLECTIBLE_NEGATIVE, seed } -- satan/the lamb
      end
    end
  end
end

function mod:onPreSpawnAward()
  if not mod:isChallenge() then
    return
  end
  
  if mod:isMegaSatan() then
    local room = game:GetRoom()
    
    if mod.state.endingBoss.delirium then
      mod:spawnVoidPortal(room:GetGridPosition(157))
    else
      mod:spawnTrophy(room:GetGridPosition(157))
    end
    
    mod:spawnMegaSatanDoorExit()
    
    return true
  end
end

-- filtered to ENTITY_MOM
function mod:onNpcDeath(entityNpc)
  if not mod:isChallenge() then
    return
  end
  
  if mod:isMom() then
    mod.isMomDead = true
  end
end

-- filtered to PICKUP_TROPHY
function mod:onPickupInit(pickup)
  if not mod:isChallenge() then
    return
  end
  
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  
  if (room:IsCurrentRoomLastBoss() or mod:isMother() or mod:isHush()) and stage ~= LevelStage.STAGE7 then -- does not include mega satan, exclude the void
    if mod.state.endingBoss.megasatan and stage == LevelStage.STAGE6 and room:GetType() == RoomType.ROOM_BOSS and roomDesc.GridIndex >= 0 then -- remove trophy from normal boss
      pickup:Remove()
    elseif mod.state.endingBoss.delirium and stage >= mod.state.endingBoss.endstage then -- at or past the ending stage (not counting the void)
      pickup:Remove()
      if mod:isHush() then
        mod:spawnTheVoidDoor()
      else
        mod:spawnVoidPortal(pickup.Position)
      end
    elseif mod:hasMoreStagesToGo() then
      pickup:Remove()
      if mod:shouldSpawnBlueWombDoor() then
        mod:spawnBlueWombDoor(true)
      elseif mod:shouldSpawnSecretExit() then
        mod:spawnSecretExit(true)
      elseif stage == LevelStage.STAGE6 then
        mod:spawnVoidPortal(pickup.Position) -- spawning a trapdoor here just replays the same floor
      else
        mod:spawnTrapdoor(pickup.Position) -- the game clears out this position so spawning the trapdoor here makes sense
      end
    end
  end
end

-- filtered to PICKUP_COLLECTIBLE
function mod:onPickupUpdate(pickup)
  if pickup.SubType == CollectibleType.COLLECTIBLE_POLAROID or pickup.SubType == CollectibleType.COLLECTIBLE_NEGATIVE then
    if mod:isMom() and pickup.Price ~= 0 then -- can happen due to satanic bible
      pickup.Price = 0
      pickup.AutoUpdatePrice = false
    end
  end
end

-- filtered to 0-Player
function mod:onPlayerInit(player)
  if not mod:isChallenge() then
    return
  end
  
  -- eden is setup as the default template, eden is excluded from the random options
  -- not using isaac because it becomes a problem on continue
  if player:GetPlayerType() ~= PlayerType.PLAYER_EDEN then
    return
  end
  
  if mod:isRandomChallenge() then
    mod:choosePlayerType(player, true, true)
  elseif mod:isRegularChallenge() then
    mod:choosePlayerType(player, true, false)
  elseif mod:isTaintedChallenge() then
    mod:choosePlayerType(player, false, true)
  end
end

-- filtered to PLAYER_ISAAC and PLAYER_LILITH
function mod:onPeffectUpdate(player)
  if not mod:isChallenge() then
    return
  end
  
  if mod.playerHash and mod.playerHash == GetPtrHash(player) then
    if player:GetPlayerType() == PlayerType.PLAYER_LILITH then
      player:RespawnFamiliars() -- otherwise the incubus doesn't spawn
    elseif mod.playerType then
      mod:changePlayerType(player, mod.playerType)
    end
    mod.playerHash = nil
    mod.playerType = nil
  end
end

function mod:choosePlayerType(player, useRegularPlayerTypes, useTaintedPlayerTypes)
  local playerType
  local sum = mod:getKeyboardSum()
  
  if useRegularPlayerTypes and useTaintedPlayerTypes then
    local regularPlayerTypesCount = #mod.regularPlayerTypes
    local taintedPlayerTypesCount = #mod.taintedPlayerTypes
    
    if mod:isTaintedKeyboardModifier() and sum >= 1 and sum <= taintedPlayerTypesCount then
      playerType = mod.taintedPlayerTypes[sum]
    elseif sum >= 1 and sum <= regularPlayerTypesCount then
      playerType = mod.regularPlayerTypes[sum]
    else
      -- RandomInt returns 0 to max-1, lua tables use 1-based indexes
      local rand = mod.rng:RandomInt(regularPlayerTypesCount + taintedPlayerTypesCount) + 1
      if rand <= regularPlayerTypesCount then
        playerType = mod.regularPlayerTypes[rand]
      else
        playerType = mod.taintedPlayerTypes[rand - regularPlayerTypesCount]
      end
    end
  else
    local playerTypes = useTaintedPlayerTypes and mod.taintedPlayerTypes or mod.regularPlayerTypes
    local playerTypesCount = #playerTypes
    
    if sum >= 1 and sum <= playerTypesCount then
      playerType = playerTypes[sum]
    else
      playerType = playerTypes[mod.rng:RandomInt(playerTypesCount) + 1]
    end
  end
  
  -- always clear this in init
  mod:clearKeysBombsCoins(player)
  
  if playerType.init then -- do it now
    mod:changePlayerType(player, playerType)
    if player:GetPlayerType() == PlayerType.PLAYER_LILITH then
      mod.playerHash = GetPtrHash(player)
      mod.playerType = nil
    end
  else -- do it later
    -- certain characters have problems changing type in init
    mod:changePlayerType(player, mod.isaacTemplate) -- switch eden to isaac so we don't get any random eden items
    mod.playerHash = GetPtrHash(player)
    mod.playerType = playerType
  end
end

function mod:changePlayerType(player, playerType)
  player:ChangePlayerType(playerType.player)
  
  mod:clearHearts(player)
  player:AddMaxHearts(playerType.maxhp)  -- works as coins for keeper
  player:AddBoneHearts(playerType.bonehp)
  player:AddHearts(playerType.redhp)     -- works as coins for keeper, can be used for Tainted Bethany instead of AddBloodCharge
  player:AddSoulHearts(playerType.soulhp) -- can be used for Bethany instead of AddSoulCharge
  player:AddBlackHearts(playerType.blackhp)
  
  if playerType.item then
    local itemConfig = Isaac.GetItemConfig()
    player:AddCollectible(playerType.item, itemConfig:GetCollectible(playerType.item).InitCharge, true, ActiveSlot.SLOT_PRIMARY, 0)
  end
  
  if playerType.trinket then
    player:AddTrinket(playerType.trinket, true)
  end
  
  player:AddKeys(playerType.keys)
  if player:GetPlayerType() == PlayerType.PLAYER_BLUEBABY_B then
    player:AddPoopMana(playerType.bombs)
  else
    player:AddBombs(playerType.bombs)
  end
  player:AddCoins(playerType.coins)
  
  if playerType.twin then
    local twin = player:GetOtherTwin() or player:GetSubPlayer()
    if twin then
      mod:clearHearts(twin)
      twin:AddMaxHearts(playerType.twin.maxhp)
      twin:AddBoneHearts(playerType.twin.bonehp)
      twin:AddHearts(playerType.twin.redhp)
      twin:AddSoulHearts(playerType.twin.soulhp)
      twin:AddBlackHearts(playerType.twin.blackhp)
    end
  end
end

-- remove all hearts, this is safe in repentance
function mod:clearHearts(player)
  player:AddMaxHearts(player:GetMaxHearts() * -1, true)
  player:AddBoneHearts(player:GetBoneHearts() * -1)
  player:AddSoulHearts(player:GetSoulHearts() * -1) -- includes black hearts
  player:AddBrokenHearts(player:GetBrokenHearts() * -1)
end

-- remove any default keys/bombs/coins (shared across players)
function mod:clearKeysBombsCoins(player)
  if game:GetFrameCount() == 0 and #Isaac.FindByType(EntityType.ENTITY_PLAYER, -1, -1, false, false) == 0 then
    mod.state.defaultNumKeys = player:GetNumKeys()
    mod.state.defaultNumBombs = player:GetNumBombs()
    mod.state.defaultNumCoins = player:GetNumCoins()
  end
  player:AddKeys(mod.state.defaultNumKeys * -1)
  player:AddBombs(mod.state.defaultNumBombs * -1)
  player:AddCoins(mod.state.defaultNumCoins * -1)
end

function mod:getKeyboardSum()
  local keys = {
    [Keyboard.KEY_1] = 1,
    [Keyboard.KEY_2] = 2,
    [Keyboard.KEY_3] = 3,
    [Keyboard.KEY_4] = 4,
    [Keyboard.KEY_5] = 5,
    [Keyboard.KEY_6] = 6,
    [Keyboard.KEY_7] = 7,
    [Keyboard.KEY_8] = 8,
    [Keyboard.KEY_9] = 9,
    [Keyboard.KEY_0] = 10,
    [Keyboard.KEY_KP_1] = 1,
    [Keyboard.KEY_KP_2] = 2,
    [Keyboard.KEY_KP_3] = 3,
    [Keyboard.KEY_KP_4] = 4,
    [Keyboard.KEY_KP_5] = 5,
    [Keyboard.KEY_KP_6] = 6,
    [Keyboard.KEY_KP_7] = 7,
    [Keyboard.KEY_KP_8] = 8,
    [Keyboard.KEY_KP_9] = 9,
    [Keyboard.KEY_KP_0] = 10
  }
  
  local sum = 0
  local keyboard = 0
  
  for key, val in pairs(keys) do
    if Input.IsButtonPressed(key, keyboard) then
      sum = sum + val
    end
  end
  
  return sum
end

function mod:isTaintedKeyboardModifier()
  local keyboard = 0
  return Input.IsButtonPressed(Keyboard.KEY_T, keyboard)
end

function mod:addKeyPieces()
  local player = game:GetPlayer(0)
  
  if not mod:hasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) then
    player:AddCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1, 0, true, ActiveSlot.SLOT_PRIMARY, 0)
  end
  if not mod:hasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2) then
    player:AddCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2, 0, true, ActiveSlot.SLOT_PRIMARY, 0)
  end
end

function mod:hasMoreStagesToGo()
  local level = game:GetLevel()
  local stage = level:GetStage()
  
  return stage < mod.state.endingBoss.endstage or (mod:isCurseOfTheLabyrinth() and stage < mod.state.endingBoss.endstage - 1) -- this assumes the endstage is always set to the 2 of 2 floor
end

function mod:shouldSpawnBlueWombDoor()
  local level = game:GetLevel()
  local stage = level:GetStage()
  
  -- don't include mother here, i prefer the behavior of spawning a blue womb hole directly from the boss room
  return mod.state.endingBoss.hush and not mod:isRepentanceStageType() and (stage == LevelStage.STAGE4_2 or (mod:isCurseOfTheLabyrinth() and stage == LevelStage.STAGE4_1))
end

function mod:shouldSpawnSecretExit()
  local level = game:GetLevel()
  local stage = level:GetStage()
  local isCurse = mod:isCurseOfTheLabyrinth()
  
  return (
           mod.state.endingBoss.secretpath and
           (
             (
               mod:isRepentanceStageType() and
               (
                 (stage == LevelStage.STAGE1_2 or (isCurse and stage == LevelStage.STAGE1_1)) or
                 (stage == LevelStage.STAGE2_2 or (isCurse and stage == LevelStage.STAGE2_1)) or
                 ((stage == LevelStage.STAGE3_2 or (isCurse and stage == LevelStage.STAGE3_1)) and not game:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH_INIT) and not game:GetStateFlag(GameStateFlag.STATE_MAUSOLEUM_HEART_KILLED))
               )
             ) or
             (
               not mod:isRepentanceStageType() and
               (
                 stage == LevelStage.STAGE1_1 or stage == LevelStage.STAGE1_2 or
                 stage == LevelStage.STAGE2_1 or stage == LevelStage.STAGE2_2 or
                 (stage == LevelStage.STAGE3_1 and not isCurse)
               )
             )
           )
         )
end

function mod:spawnSecretExit(animate)
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local stage = level:GetStage()
  local isCurse = mod:isCurseOfTheLabyrinth()
  
  room:TrySpawnSecretExit(animate, true)
  
  if (isCurse and stage < LevelStage.STAGE3_1) or (not isCurse and stage <= LevelStage.STAGE3_1) then -- doors that require keys/bombs/hearts
    for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
      local door = room:GetDoor(i)
      if door and door.TargetRoomType == RoomType.ROOM_SECRET_EXIT and door:IsLocked() then
        door:SetLocked(false)
        break
      end
    end
  elseif mod:isRepentanceStageType() and (stage == LevelStage.STAGE3_2 or (isCurse and stage == LevelStage.STAGE3_1)) then
    for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
      local door = room:GetDoor(i)
      if door then
        if door.TargetRoomType == RoomType.ROOM_BOSS then -- mausoleum heart
          if mod:hasCollectible(CollectibleType.COLLECTIBLE_KNIFE_PIECE_1) and mod:hasCollectible(CollectibleType.COLLECTIBLE_KNIFE_PIECE_2) then -- has full knife
            if door:GetVariant() ~= DoorVariant.DOOR_LOCKED_CRACKED then -- walking out of a disappearing devil/angel room can cause the game to unlock this door when it shouldn't be
              door:SetVariant(DoorVariant.DOOR_LOCKED_CRACKED)           -- SetLocked(true) won't set the right type of locked door here
              door:Close()
            end
          else -- doesn't have knife
            if door:IsLocked() then
              door:SetLocked(false)
            end
          end
        elseif door.TargetRoomType == RoomType.ROOM_DEVIL or door.TargetRoomType == RoomType.ROOM_ANGEL or door.TargetRoomType == RoomType.ROOM_BOSSRUSH then
          if door:IsLocked() then -- this can happen due to fixing the issue above
            door:SetLocked(false)
          end
        end
      end
    end
  end
end

function mod:spawnBlueWombDoor(firstTime)
  local room = game:GetRoom()
  room:TrySpawnBlueWombDoor(firstTime, true, true)
end

function mod:spawnTheVoidDoor()
  local room = game:GetRoom()
  room:TrySpawnTheVoidDoor(true)
end

function mod:spawnMegaSatanRoomDoor()
  local room = game:GetRoom()
  if room:TrySpawnMegaSatanRoomDoor(true) then
    local door = room:GetDoor(DoorSlot.UP0)
    if door and door.TargetRoomIndex == GridRooms.ROOM_MEGA_SATAN_IDX then
      if not (mod:hasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1) and mod:hasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2)) then -- does not have full key
        local sprite = door:GetSprite()
        door.State = DoorState.STATE_OPEN
        sprite:Play('Opened')
      end
    end
  end
end

function mod:spawnMegaSatanDoorExit()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  if room:GetDoor(DoorSlot.DOWN0) == nil and room:TrySpawnBlueWombDoor(false, true, true) then
    local door = room:GetDoor(DoorSlot.DOWN0)
    if door then
      local sprite = door:GetSprite()
      door.TargetRoomType = RoomType.ROOM_DEFAULT
      door.TargetRoomIndex = level:GetPreviousRoomIndex() -- GetStartingRoomIndex
      sprite:Load('gfx/grid/door_24_megasatandoor.anm2', true)
      sprite:Play('Opened', true)
    end
  end
end

-- spawn trapdoor or heaven door
function mod:spawnTrapdoor(position)
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  local isCurse = mod:isCurseOfTheLabyrinth()
  
  if level:IsAscent() or
     (
       mod.state.endingBoss.altpath and
       roomDesc.GridIndex ~= GridRooms.ROOM_BLUE_WOOM_IDX and
       roomDesc.GridIndex ~= GridRooms.ROOM_THE_VOID_IDX and
       (
         (
           mod:isRepentanceStageType() and
           (
             ((stage == LevelStage.STAGE4_2 or (isCurse and stage == LevelStage.STAGE4_1)) and not mod.state.endingBoss.hush) or stage == LevelStage.STAGE4_3 or stage == LevelStage.STAGE5
           )
         ) or
         (
           not mod:isRepentanceStageType() and
           (
             (stage == LevelStage.STAGE4_2 or (isCurse and stage == LevelStage.STAGE4_1)) or stage == LevelStage.STAGE4_3 or stage == LevelStage.STAGE5
           )
         )
       )
     )
  then -- heaven door
    if #Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, false, false) == 0 then
      Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, position, Vector.Zero, nil)
    end
    if level:IsAscent() then
      local gridEntity = room:GetGridEntityFromPos(position)
      if gridEntity and gridEntity:GetType() == GridEntityType.GRID_SPIDERWEB then
        room:RemoveGridEntity(gridEntity:GetGridIndex(), 0, false)
      end
    end
  else -- trapdoor
    local trapdoor = Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, position, true)
    if trapdoor:GetType() ~= GridEntityType.GRID_TRAPDOOR then
      room:RemoveGridEntity(room:GetGridIndex(position), 0, false)
      room:Update()
      trapdoor = Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 0, position, true)
    end
    
    if mod.state.endingBoss.hush and mod:isMother() then
      mod:setBlueWombholeSprite(trapdoor:GetSprite())
    elseif mod.state.endingBoss.endstage == LevelStage.STAGE8 and not mod:isRepentanceStageType() and mod:isMom() then
      mod:setMausoleumTrapdoorSprite(trapdoor:GetSprite())
    end
  end
end

function mod:spawnVoidPortal(position)
  local room = game:GetRoom()
  
  local portal = Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 1, position, true)
  if portal:GetType() ~= GridEntityType.GRID_TRAPDOOR then
    room:RemoveGridEntity(room:GetGridIndex(position), 0, false)
    room:Update()
    portal = Isaac.GridSpawn(GridEntityType.GRID_TRAPDOOR, 1, position, true)
  end
  
  portal.VarData = 1
  portal:GetSprite():Load('gfx/grid/voidtrapdoor.anm2', true)
end

function mod:spawnTrophy(position)
  Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TROPHY, 0, position, Vector.Zero, nil)
end

function mod:updateMausoleumTrapdoor()
  local room = game:GetRoom()
  
  local trapdoor = room:GetGridEntityFromPos(room:GetCenterPos())
  if trapdoor and trapdoor:GetType() == GridEntityType.GRID_TRAPDOOR then
    mod:setMausoleumTrapdoorSprite(trapdoor:GetSprite())
  end
end

function mod:setMausoleumTrapdoorSprite(sprite)
  sprite:Load('gfx/grid/trapdoor_mausoleum.anm2', true)
  --game:ShowHallucination(0, BackdropType.MAUSOLEUM_ENTRANCE)
end

function mod:updateBlueWombTrapdoor()
  local room = game:GetRoom()
  
  local trapdoor = room:GetGridEntityFromPos(room:GetCenterPos())
  if trapdoor and trapdoor:GetType() == GridEntityType.GRID_TRAPDOOR then
    mod:setBlueWombholeSprite(trapdoor:GetSprite())
  end
end

function mod:setBlueWombholeSprite(sprite)
  sprite:Load('gfx/grid/door_11_wombhole.anm2', false)
  sprite:ReplaceSpritesheet(0, 'gfx/grid/door_11_wombhole_blue.png') -- show blue womb hole to hush
  sprite:LoadGraphics()
end

-- the game constantly tries to re-open trapdoors, so we have to keep re-closing them
-- maybe there's a better way to do this?
function mod:closeSecretExitTrapdoor()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  local isCurse = mod:isCurseOfTheLabyrinth()
  
  if mod.state.endingBoss.secretpath and room:GetType() == RoomType.ROOM_SECRET_EXIT and roomDesc.GridIndex == GridRooms.ROOM_SECRET_EXIT_IDX and mod:isRepentanceStageType() and
     (
       (
         (stage == LevelStage.STAGE1_2 or (isCurse and stage == LevelStage.STAGE1_1)) and not mod:hasCollectible(CollectibleType.COLLECTIBLE_KNIFE_PIECE_1)
       ) or
       (
         (stage == LevelStage.STAGE2_2 or (isCurse and stage == LevelStage.STAGE2_1)) and not mod:hasCollectible(CollectibleType.COLLECTIBLE_KNIFE_PIECE_2)
       )
     )
  then
    local gridEntity = room:GetGridEntityFromPos(room:GetCenterPos())
    if gridEntity and gridEntity:GetType() == GridEntityType.GRID_TRAPDOOR then
      gridEntity.State = 0                         -- closed
      gridEntity:GetSprite():SetFrame('Closed', 0) -- show closed state
    end
  end
end

function mod:updateCorpseStage()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  local stageType = level:GetStageType()
  
  if mod:isRepentanceStageType() and (stage == LevelStage.STAGE4_2 or (mod:isCurseOfTheLabyrinth() and stage == LevelStage.STAGE4_1)) and
     roomDesc.GridIndex ~= GridRooms.ROOM_BLUE_WOOM_IDX and not room:IsCurrentRoomLastBoss() and mod:isTakingTrapdoor()
  then
    if mod:hasMoreStagesToGo() and not mod.state.endingBoss.hush then
      -- code inspired from runs continue past mother mod
      level:SetStage(stage, StageType.STAGETYPE_ORIGINAL) -- STAGETYPE_WOTL / STAGETYPE_AFTERBIRTH, needed if we want to go to satan or isaac after mother
    elseif stage == LevelStage.STAGE4_1 then
      -- the default after corpse 2 is to go to hush, however going down a trapdoor from corpse xl causes a crash, tell the game we were on corpse 2 which will take us to hush
      level:SetStage(LevelStage.STAGE4_2, stageType)
    end
  end
end

-- TrySpawnSecretExit doesn't usually work here
-- so re-using the normal trapdoor instead
function mod:setSecretPath()
  local level = game:GetLevel()
  local stage = level:GetStage()
  
  if mod.state.endingBoss.endstage == LevelStage.STAGE8 and -- beast
     not level:IsAscent() and not mod:isRepentanceStageType() and (stage == LevelStage.STAGE3_2 or (mod:isCurseOfTheLabyrinth() and stage == LevelStage.STAGE3_1)) and
     mod:isTakingTrapdoor()
  then
    game:SetStateFlag(GameStateFlag.STATE_SECRET_PATH, true)
    --game:SetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH_INIT, true)
  end
end

function mod:isTakingTrapdoor()
  if game:IsPaused() then
    local room = game:GetRoom()
    
    for i = 0, game:GetNumPlayers() - 1 do
      local player = game:GetPlayer(i)
      local playerIdx = room:GetGridIndex(player.Position)
      local sprite = player:GetSprite()
      
      if sprite:IsPlaying('Trapdoor') then
        local gridEntity = room:GetGridEntity(playerIdx)
        if gridEntity and gridEntity:GetType() == GridEntityType.GRID_TRAPDOOR then
          if gridEntity:GetVariant() ~= 1 then -- exclude void portal
            return true
          end
        end
      elseif sprite:IsPlaying('LightTravel') then
        for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.HEAVEN_LIGHT_DOOR, 0, false, false)) do
          if playerIdx == room:GetGridIndex(entity.Position) then
            return true
          end
        end
      end
    end
  end
  
  return false
end

function mod:hasCollectible(collectible)
  for i = 0, game:GetNumPlayers() - 1 do
    local player = game:GetPlayer(i)
    
    if player:HasCollectible(collectible, false) then
      return true
    end
  end
  
  return false
end

function mod:changeBackdropType()
  local seeds = game:GetSeeds()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local stage = level:GetStage()
  if mod:isRepentanceStageType() then
    stage = stage + 1
  end
  
  if mod:tblHasVal(mod.backdropTypes, room:GetBackdropType()) and room:GetType() ~= RoomType.ROOM_DEVIL and room:GetType() ~= RoomType.ROOM_ANGEL then
    local rng = RNG()
    rng:SetSeed(seeds:GetStageSeed(stage), mod.rngShiftIndex) -- room:GetDecorationSeed
    
    game:ShowHallucination(0, mod.backdropTypes[rng:RandomInt(#mod.backdropTypes) + 1])
    sfx:Stop(SoundEffect.SOUND_DEATH_CARD)
  end
end

function mod:tblHasVal(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  
  return false
end

function mod:getCurrentDimension()
  local level = game:GetLevel()
  return mod:getDimension(level:GetCurrentRoomDesc())
end

function mod:getDimension(roomDesc)
  local level = game:GetLevel()
  local ptrHash = GetPtrHash(roomDesc)
  
  -- 0: main dimension
  -- 1: secondary dimension, used by downpour mirror dimension and mines escape sequence
  -- 2: death certificate dimension
  for i = 0, 2 do
    if ptrHash == GetPtrHash(level:GetRoomByIdx(roomDesc.SafeGridIndex, i)) then
      return i
    end
  end
  
  return -1
end

function mod:isRepentanceStageType()
  local level = game:GetLevel()
  local stageType = level:GetStageType()
  
  return stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B
end

function mod:isMom()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  
  return (stage == LevelStage.STAGE3_2 or (mod:isCurseOfTheLabyrinth() and stage == LevelStage.STAGE3_1)) and
         room:IsCurrentRoomLastBoss() and
         roomDesc.GridIndex >= 0
end

function mod:isMother()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  local stage = level:GetStage()
  
  return mod:isRepentanceStageType() and
         (stage == LevelStage.STAGE4_2 or (mod:isCurseOfTheLabyrinth() and stage == LevelStage.STAGE4_1)) and
         room:GetType() == RoomType.ROOM_BOSS and
         roomDesc.GridIndex == GridRooms.ROOM_SECRET_EXIT_IDX
end

function mod:isHush()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  
  return level:GetStage() == LevelStage.STAGE4_3 and
         room:GetType() == RoomType.ROOM_BOSS and
         room:GetRoomShape() == RoomShape.ROOMSHAPE_2x2 and
         roomDesc.GridIndex >= 0
end

function mod:isMegaSatan()
  local level = game:GetLevel()
  local room = level:GetCurrentRoom()
  local roomDesc = level:GetCurrentRoomDesc()
  
  return level:GetStage() == LevelStage.STAGE6 and
         room:GetType() == RoomType.ROOM_BOSS and
         roomDesc.GridIndex == GridRooms.ROOM_MEGA_SATAN_IDX
end

function mod:isCurseOfTheLabyrinth()
  local level = game:GetLevel()
  local curses = level:GetCurses()
  local curse = LevelCurse.CURSE_OF_LABYRINTH
  
  return curses & curse == curse
end

function mod:seedRng()
  repeat
    local rand = Random()  -- 0 to 2^32
    if rand > 0 then       -- if this is 0, it causes a crash later on
      mod.rng:SetSeed(rand, mod.rngShiftIndex)
    end
  until(rand > 0)
end

function mod:setEndingBoss(endingBoss)
  mod.state.endingBoss.name = endingBoss.name
  mod.state.endingBoss.weight = endingBoss.weight
  mod.state.endingBoss.endstage = endingBoss.endstage
  mod.state.endingBoss.altpath = endingBoss.altpath
  mod.state.endingBoss.secretpath = endingBoss.secretpath
  mod.state.endingBoss.hush = endingBoss.hush
  mod.state.endingBoss.megasatan = endingBoss.megasatan
  mod.state.endingBoss.delirium = endingBoss.delirium
end

function mod:clearEndingBoss()
  mod.state.endingBoss.name = ''
  mod.state.endingBoss.weight = 0
  mod.state.endingBoss.endstage = 0
  mod.state.endingBoss.altpath = false
  mod.state.endingBoss.secretpath = false
  mod.state.endingBoss.hush = false
  mod.state.endingBoss.megasatan = false
  mod.state.endingBoss.delirium = false
end

function mod:isChallenge()
  local challenge = Isaac.GetChallenge()
  return challenge == Isaac.GetChallengeIdByName('Randomness Challenge') or
         challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Regular)') or
         challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Tainted)') or
         challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Eden)') or
         challenge == Isaac.GetChallengeIdByName('Randomness Challenge (T-Eden)') or
         challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Trainer)')
end

function mod:isRandomChallenge()
  local challenge = Isaac.GetChallenge()
  return challenge == Isaac.GetChallengeIdByName('Randomness Challenge')
end

function mod:isRegularChallenge()
  local challenge = Isaac.GetChallenge()
  return challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Regular)')
end

function mod:isTaintedChallenge()
  local challenge = Isaac.GetChallenge()
  return challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Tainted)')
end

function mod:isTrainerChallenge()
  local challenge = Isaac.GetChallenge()
  return challenge == Isaac.GetChallengeIdByName('Randomness Challenge (Trainer)')
end

mod:seedRng()
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.onUpdate)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onRender)
mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, mod.onPreEntitySpawn)
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, mod.onPreSpawnAward)
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.onNpcDeath, EntityType.ENTITY_MOM)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.onPickupInit, PickupVariant.PICKUP_TROPHY)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.onPickupUpdate, PickupVariant.PICKUP_COLLECTIBLE)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.onPlayerInit, 0) -- 0 is player, 1 is co-op baby
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.onPeffectUpdate, PlayerType.PLAYER_ISAAC)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.onPeffectUpdate, PlayerType.PLAYER_LILITH)