
----------------------------------
-- Custom Room mod example
--
-- Rooms are the level at which terrain and prefabs are actually added to the
-- world. They represent any space in the game with a floor type and collection
-- of prefabs. Rooms have a number of different rules for how many prefabs of
-- which types will be laid inside them. They can also contain Static Layouts,
-- which are hand-made pieces of content like set pieces or scenarios.
--
--	AddRoom(newroom)
--		Inserts a room into the master roomlist, which can then be used by new or moded
--		tasks in their "room_choices".
--
--	AddRoomPreInit("roomname", initfn)
--		Gets the raw data for a room before it's processed, allowing for modifications to
--		its prefabs, layouts, and tags.
--
-----------------------------------

GLOBAL.require("constants") -- for GROUND
local GROUND = GLOBAL.GROUND
-- Adds a custom room. See "AddTaskPreInit" below for how to actually insert this into the worldgen.
AddRoom("LumpySwamp", {
	colour={r=.010,g=.010,b=.10,a=.50},
	value = GROUND.MARSH,
	contents =  {
		distributepercent = 0.4,
		distributeprefabs = {
			evergreen_sparse = 3,
			marsh_tree = 0.5,
			tentacle = 0.1,
		}
	}
})

-- Modify the contents of a particular room
local function BeefaloRoomPreInit(room)
	if not room.contents.distributeprefabs then
		room.contents.distributeprefabs = {}
	end
	room.contents.distributeprefabs.rock1 = 0.01
	room.contents.distributepercent = 0.1
end

-- This runs while the task is still just data as in rooms.lua and not a full working level yet.
AddRoomPreInit("BeefalowPlain", BeefaloRoomPreInit)


----------------------------------
-- Custom Task mod example
--
-- Tasks are the medium building block in levels. They consist of a bunch of
-- rooms which are thematically related. These rooms will all be placed on the
-- same "landmass" together with bridges to other tasks.
--
--	AddTask(newtask)
--		Inserts a task into the master tasklist, which can then be used by new or modded
--		levels in their "tasks".
--
--	AddTaskPreInit("taskname", initfn)
--		Gets the raw data for a task before it's processed, allowing for modifications to
--		its rooms and locks.
--
----------------------------------


-- Create a custom task. This needs to be added into a level somewhere for it
-- to show up! See "AddLevelPreInit" below.
GLOBAL.require("map/lockandkey") -- for LOCKS and KEYS
local LOCKS = GLOBAL.LOCKS
local KEYS = GLOBAL.KEYS
AddTask("Swampalo", {
	locks=LOCKS.NONE,
	keys_given={KEYS.MEAT,KEYS.WOOL,KEYS.POOP},
	room_choices={
		["BeefalowPlain"] = 5,
	},
	room_bg=GROUND.MARSH,
	background_room="BGMarsh",
	colour={r=0.5,g=0,b=0.8,a=0.5},
})


-- This runs while the task is still just data as in tasks.lua and not a full working level yet.
local function MakePickTaskPreInit(task)
	-- Insert the custom room we created above into the task.
	-- We could modify the task here as well.
	task.room_choices["LumpySwamp"] = 2
end
AddTaskPreInit("Make a pick", MakePickTaskPreInit)


----------------------------------
-- Custom Level mod example
--
-- Levels are the largest building block in the game, consisting primarily of a
-- collection of tasks, but also a lot of special settings like prefab
-- frequency rules, global setpieces, weather and clock tweaks, and so on.
--
-- In general, you'll want to modify (add or remove) tasks from an existing
-- level for the purpose of your mod.
--
--  AddLevel(newlevel)
--		Inserts a new level into the list of possible levels. This will cause the level
--		to show up in Customization -> Presets if it's a survival level, or into the
--		random playlist if it's an adventure level.
--
--	AddLevelPreInit("levelname", initfn)
--		Gets the raw data for a level before it's processed, allowing for modifications
--		to its tasks, overrides, etc.
--
--	AddLevelPreInitAny(initfn)
--		Same as above, but will apply to any level that gets generated, always.
--
----------------------------------

GLOBAL.require("map/level") -- for LEVELTYPE
local LEVELTYPE = GLOBAL.LEVELTYPE

-- Add a new level i.e. a custom preset.
AddLevel(LEVELTYPE.SURVIVAL, {
		id="MY_CUSTOM_LEVEL",
		name="My custom level",
		desc="This is an example of a custom level.",
		overrides={
				{"start_setpeice", 	"DefaultStart"},		
				{"start_node",		"Clearing"},
		},
		tasks = {
				"Make a pick",
				"Dig that rock",
				"Great Plains",
				"Squeltch",
				"Beeeees!",
				"Speak to the king",
				"Forest hunters",
		},
		numoptionaltasks = 4,
		optionaltasks = {
				"Befriend the pigs",
				"For a nice walk",
				"Kill the spiders",
				"Killer bees!",
				"Make a Beehat",
				"The hunters",
				"Magic meadow",
				"Frogs and bugs",
		},
		set_pieces = {
			["ResurrectionStone"] = { count=2, tasks={"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters" } },
			["WormholeGrass"] = { count=8, tasks={"Make a pick", "Dig that rock", "Great Plains", "Squeltch", "Beeeees!", "Speak to the king", "Forest hunters", "Befriend the pigs", "For a nice walk", "Kill the spiders", "Killer bees!", "Make a Beehat", "The hunters", "Magic meadow", "Frogs and bugs"} },
		},
})

-- This runs while the level is still just data as in levels.lua and not a full working level yet.
local function SurvivalLevelInit(level)
	-- Add the custom task we created above. We could modify the level here as well.
	table.insert(level.tasks, "Swampalo")
end

--AddLevelPreInit("SURVIVAL_DEFAULT", LevelInit) -- regular version runs for a particular level
AddLevelPreInitAny(SurvivalLevelInit) -- alternate version runs no matter what level is being generated


----------------------------------
-- Static Layouts
--
--	require("map/layouts").Layouts
--		Add or modify the list of static layouts. These layouts can be created
--		with external tools or manually as a text file. Once added to the
--		Layouts list, these can be inserted into room definitions. Examples of
--		these in-game include the teleportato piece areas, the abandoned bases,
--		and the skeletons.
--
----------------------------------

local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
-- We'll just use an existing layout here, but feel free to add your own in a
-- scripts/map/static_layouts folder.
Layouts["MyCustomLayout"] = StaticLayout.Get("map/static_layouts/insane_pig")
-- Add this layout to every "forest" room in the game
AddRoomPreInit("Forest", function(room)
	if not room.contents.countstaticlayouts then
		room.contents.countstaticlayouts = {}
	end
	room.contents.countstaticlayouts["MyCustomLayout"] = 1
end)
