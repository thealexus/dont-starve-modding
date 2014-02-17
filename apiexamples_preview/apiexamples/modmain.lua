
-- This texture is necessary for some of the examples.
Assets = {
	Asset("ATLAS", "images/myatlas.xml"),
	Asset("IMAGE", "images/myprefab.tex"),
}

-----------------------------------
-- Crafting recipes
--
--  AddRecipe("name", {ingredients}, tab, techlevel)
--  optional arguements:
--  AddRecipe("name", {ingredients}, tab, techlevel, "placer", minspacing, no_unlock, num_to_give)
--		Use this to create a new recipe object. Recipes automatically register
--		themselves.
--
--		Check out recipes.lua for plenty of examples.
--
--	Ingredient("type", amount, atlas)
--		If you want to specify a custom ingredient you must also specify the
--		atlas its inventory image is found in.
--
-----------------------------------

local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH
-- Create an ingredient requirement of one "myprefab". This one uses a
-- fictional prefab and atlas, but you can specify your own prefabs and
-- inventory items.
local customIngredient = Ingredient("myprefab", 1, "images/myatlas.xml")
-- Create a recipe. The atlas for a recipe must be specified after it is
-- created as below.  Note that custom ingredients can be specified as above,
-- or right in the Recipe call.
local myprefabRecipe = Recipe("myprefab", { Ingredient("petals", 2), customIngredient, Ingredient("myprefab", 4, "images/myatlas.xml") }, RECIPETABS.SURVIVAL, TECH.SCIENCE_ONE )
myprefabRecipe.atlas = "images/myatlas.xml"

-----------------------------------
-- Cookpot recipes
--
--  AddIngredientValues({"item"}, {"tag"=value})
--		Lets the game know the "worth" of an item. You can supply a list of
--		items in the first parameter if they will all have the same values.
--
--		Each tag is a particular "kind" of thing that a recipe might require
--		(i.e. meat, veggie) and the value is how much of that kind your item is
--		worth.
--
--		See cooking.lua for examples. 
--
--	AddCookerRecipe("cooker", recipe)
--		Adds the recipe for that kind of cooker. In the base game the only
--		cooker is "cookpot".
--
--		See preparedfoods.lua for recipe examples.
--
-----------------------------------

-- Give flowers some cooking value. We made up a new "kind" of food, called flower.
AddIngredientValues({"petals", "petals_evil"}, {flower=1})

-- Add a new recipe which requires flowers as an ingredient.
-- NOTE!!! No prefabs for this recipe exist, so you won't actually be able to
-- cook it. This is just a code sample.
local flowercake = {
	name = "flowercake",
	test = function(cooker, names, tags) return tags.flower >= 2 and names.butter end,
	priority = 1,
	weight = 1,
	foodtype="VEGGIE",
	health = TUNING.HEALING_TINY,
	hunger = TUNING.CALORIES_LARGE,
	sanity = TUNING.SANITY_TINY,
	perishtime = TUNING.PERISH_MED,
	cooktime = 0.75,
}
AddCookerRecipe("cookpot", flowercake)
-- TODO: Allow custom food items to be visible within the cookpot.

-----------------------------------
-- Actions and Handlers
--
--  AddAction(action)
--		Puts a new action into the global actions table and sets up the basic
--		string for it.
--
--	AddStategraphActionHandler("stategraphname", newActionHandler)
--		Appends a handler for your action (or an existing action!) to an
--		existing stategraph.
--
-----------------------------------

local Action = GLOBAL.Action
local ActionHandler = GLOBAL.ActionHandler

local MYACT = Action(3)
MYACT.str = "Do My Action"
MYACT.id = "MYACT"
MYACT.fn = function(act)
	print(act.doer.. " is doing my action!")
end

AddAction(MYACT)

AddStategraphActionHandler("wilson", ActionHandler(MYACT, "doshortaction"))


-----------------------------------
-- Stategraph mod example
--
--	AddStategraphState("stategraphname", newState)
--	AddStategraphEvent("stategraphname", newEvent)
--	AddStategraphActionHandler("stategraphname", newActionHandler)
--		Use these functions to append new states, events, and actions handlers
--		to existing states.
--
--	AddStategraphPostInit("stategraphname", initfn)
--		Use this to modify and mangle existing stategraphs, such as digging
--		into existing states or appending new functionality to existing
--		handlers.
-- 
-----------------------------------
local State = GLOBAL.State
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local FRAMES = GLOBAL.FRAMES

local spinstate = State({
	name = "spin_around",
	tags = {"idle", "canrotate"},
	onenter = function(inst)
		inst.Transform:SetRotation(0)
		inst.AnimState:PushAnimation("idle_loop", true)
	end,
	timeline = {
		TimeEvent(20*FRAMES, function(inst) inst.Transform:SetRotation(90) end),
		TimeEvent(40*FRAMES, function(inst) inst.Transform:SetRotation(180) end),
		TimeEvent(60*FRAMES, function(inst) inst.Transform:SetRotation(270) end),
		TimeEvent(80*FRAMES, function(inst) inst.Transform:SetRotation(0) end),
		TimeEvent(100*FRAMES, function(inst) inst.sg:GoToState("idle") end),
	},
	events = {
	},
})

local newIdleTimeout = function(inst)
	if math.random() < 0.5 then
		inst.sg:GoToState("funnyidle")
	else
		inst.sg:GoToState("spin_around")
	end
end

local function SGWilsonPostInit(sg)
	-- note! This overwrites the old timeout behavior! If possible you should
	-- always try appending your behaviour instead.
	sg.states["idle"].ontimeout = newIdleTimeout
end


AddStategraphState("wilson", spinstate)
AddStategraphPostInit("wilson", SGWilsonPostInit)

-----------------------------------
-- Brain mod example
--
--  AddBrainPostInit("brainname", initfn)
--		Lets you modify a brain after it's been initialized. The most useful
--		part is probably adding or removing nodes from brain.bt, which is the
--		brain's behaviour tree.
--
--		Note that "brainname" is the name of the lua file in scripts/brains/.
-----------------------------------

-- Since the final brain a creature gets doesn't quite look like the brain
-- specified in code, use this utility to print a brain to the console and
-- to log.txt.
local function DumpBT(bnode, indent)
	local s = ""
	for i=1,indent do
		s = s.."|   "
	end
	s = s..bnode.name
	print(s)
	if bnode.children then
		for i,childnode in ipairs(bnode.children) do
			DumpBT(childnode, indent+1)
		end
	end
end

-- This example shows both removing and adding nodes to the Behaviour Tree, through
-- finding an existing node, removing it, and re-inserting it at a different location.
local function MakePigsHateTrees(brain)

	-- Uncomment this section to see the brain printed to the console/log.txt, so
	-- that you can see what the behaviours are called and how they are structured.
	-- We'll use a little bit of searching and a little bit of direct indexing to
	-- find the nodes we want so referencing the "final" output is very useful.

	--print("\n\n\t\t\t\tDumping a pigbrain")
	--DumpBT(brain.bt.root, 0)
	--print("\n\n")


	-- We want pigs to chop trees more than anything, except when they are on fire.
	-- First we find their chopping action and remove it from the tree. Then we'll
	-- modify it, and re-insert it at the top of the tree, right after their
	-- "OnFire" behaviour. So they will prefer chopping to attacking enemies and
	-- everything else, except they'll still stop while on fire.

	-- First find the priority node guarded by the IsDay condition. This is inside
	-- a Parallel node inside the root Parallel node.
	local daygroup = nil
	--print("looking for isday")
	for i,node in ipairs(brain.bt.root.children) do
		--print("\t"..node.name.." > "..(node.children and node.children[1].name or ""))
		if node.name == "Parallel" and node.children[1].name == "IsDay" then
			daygroup = node.children[2]
			break
		end
	end
	if not daygroup then
		print("Couldn't find the 'IsDay' behaviour in this brain!")
		return
	end

	-- Then search in the daygroup for the Sequence which contains all the chopping
	-- behaviours.
	local chopsequence = nil
	local chopsequenceindex = nil
	--print("looking for chop")
	for i,node in ipairs(daygroup.children) do
		--print("\t"..node.name.." > "..(node.children and node.children[1].name or ""))
		if node.name == "Sequence" and node.children[1].name == "chop" then
			chopsequence = node
			chopsequenceindex = i
			break
		end
	end
	if not chopsequence then
		print("Couldn't find the chopping behaviour in this brain!")
		return
	end

	-- We have the chop sequence, so remove it from the old location
	table.remove(daygroup.children, chopsequenceindex)


	-- Right now pigs only chop if their leader is chopping, lets change that
	local function StartChopppingCond(inst)
		return true -- always! ME HATES TREE
	end
	local function KeepChoppingCond(inst)
		return true -- always! TREE DIE NOW
	end

	chopsequence.children[1].fn = function() return StartChopppingCond(brain.inst) end -- this is the chop node
	chopsequence.children[2].children[1].fn = function() return KeepChoppingCond(brain.inst) end -- this is the keep chopping node

	-- Find the OnFire Parallel in the root
	local fireindex = nil
	for i,node in ipairs(brain.bt.root.children) do
		if node.name == "Parallel" and node.children[1].name == "OnFire" then
			fireindex = i
			break
		end
	end

	-- Finally, re-insert our chop behaviour after the OnFire.
	table.insert(brain.bt.root.children, fireindex+1, chopsequence)


	-- Print make sure our change took!
	--print("\n\n\t\t\t\tCHANGED BRAIN")
	--DumpBT(brain.bt.root, 0)
end

AddBrainPostInit("pigbrain", MakePigsHateTrees)

-----------------------------------
-- Component mod example
--
--  AddComponentPostInit("componentname", initfn)
--		Use this to modify a component's properties or behavior
-----------------------------------

local function DoubleHealthDeltaInit(component)
	local original_dodelta = component.DoDelta
	component.DoDelta = function(self, amount, overtime, cause, ignore_invincible)
		local double_amount = amount*2
		original_dodelta(self, double_amount, overtime, cause, ignore_invincible)
	end
end
AddComponentPostInit("health", DoubleHealthDeltaInit)

-----------------------------------
-- Prefab mod example
--
--  AddPrefabPostInit("prefabname", initfn)
--		Use this to modify a prefab by adding, removing, or editing its properties
--		and components.
-----------------------------------

local function BetterCarrotInit(prefab)
	prefab.components.edible.hungervalue = 200 -- carrots are the best food ever!!
end
AddPrefabPostInit("carrot", BetterCarrotInit)

-----------------------------------
-- Widget mod example
--
--  Modding widgets is a little different because widgets are class
--  definitions, not data.  So we use a general method to append a "post
--  constructor" to the widget's class.
--
--  AddClassPostConstruct("widgets/widgetfile", initfn)
--		Use this to run a function after a class's constructor runs. The initfn
--		should have the same signature as the class's constructor.
-----------------------------------

-- Make the health/sanity/hunger indicators twice as large
local function BadgePostConstruct(self, anim, owner)
	self:SetScale(2,2,2)
end
AddClassPostConstruct("widgets/badge", BadgePostConstruct)


-----------------------------------
-- General Class post construct
--
--  Many classes, like the widgets, are returned from the file they are in, and
--  so can be modified using their path only. Other classes get placed in
--  global and have to be patched using both their path (to load the class) and
--  class name (to find it).
--
--  These methods both append a "post constructor" to the class.
--
--  AddClassPostConstruct("path/to/file", initfn)
--		Use this to run a function after a class's constructor runs, when that
--		class is returned directly from the file. The initfn should have the
--		same signature as the class's constructor.
--  AddGlobalClassPostConstruct("path/to/file", "Classname", initfn)
--		Use this to run a function after a class's constructor runs, when that
--		class is placed into the global table. The initfn should have the same
--		signature as the class's constructor.
-----------------------------------

-- Make the health/sanity/hunger indicators twice as large
local function BadgePostConstruct(self, anim, owner)
	self:SetScale(2,2,2)
end
AddClassPostConstruct("widgets/badge", BadgePostConstruct)


-- Make all brains with a ChattyNode become instantly more surfer. (Stand near
-- a pig to check it out!
local function ChattyNodePostConstructor(self, inst, chatlines, child)
	local newchatlines = {}
	for i,v in ipairs(self.chatlines) do
		newchatlines[i] = v .. " DUDE!"
	end
	self.chatlines = newchatlines
end
AddGlobalClassPostConstruct("behaviours/chattynode", "ChattyNode", ChattyNodePostConstructor)


-----------------------------------
-- Player character mod example
--
--  AddSimPostInit( initfn )
--		This returns the player charcter once the game has loaded. Use this to
--		modify and player character on startup, or to play with the game state
--		and world state.
--
-----------------------------------

function WeakerPlayersInit(player)
	-- example of modifying the player charater
	player.components.health:SetMaxHealth(50)
end

AddSimPostInit(WeakerPlayersInit)

-- Also note that any post init function can be added as many times as you like.

AddSimPostInit(function() print "Sim Post Init #1" end)
AddSimPostInit(function() print "Sim Post Init #2" end)
AddSimPostInit(function() print "Sim Post Init #3" end)

