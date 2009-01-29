
-- The engine behind the movement of the items. This should take simple
-- arguments and move the items as per requirement.



local PlowEngine = MrPlow.PlowEngine

local db
local getTable = MrPlow.getTable
local returnTable = MrPlow.returnTable
MrPlow.currentProcess = nil
local currentProcess = MrPlow.currentProcess
local BagList = {}
local CurrentMove = nil

local Clean  = getTable()

local L = LibStub("AceLocale-3.0"):GetLocale("MrPlow", true)

PT = LibStub("LibPeriodicTable-3.1")

function PlowEngine:Enable()
	db = MrPlow.db.profile
	PlowEngine:SetScript("OnUpdate", PlowEngine.OnUpdate)
end

local sortCategories = {
	"Consumable.Potion",
	"Consumable.Warlock",
	"Consumable.Water.Basic",
	"Consumable.Water.Conjured",
	"Consumable.Food.Edible.Bread.Conjured",
	"Consumable.Weapon Buff.Poison",
	"Consumable.Weapon Buff.Stone",
	"Consumable.Weapon Buff.Oil",
	"Reputation.Turnin.The Aldor",
	"Reputation.Turnin.The Scryers"
}

local itemCategories = {
	ARMOR = 1,
	WEAPON = 2,
	QUEST = 3,
	KEY = 4,
	RECIPE = 5,
	REAGENT = 6,
	GEM = 7,
	TRADEGOODS = 8,
	CONSUMABLE = 9,
	CONTAINER = 10,
	QUIVER = 11,
	MISCELLANEOUS = 12,
	PROJECTILE = 13
}

local itemRanking = {
	[L["Armor"]] = itemCategories.ARMOR,
	[L["Weapon"]] = itemCategories.WEAPON,
	[L["Quest"]] = itemCategories.QUEST,
	[L["Key"]] = itemCategories.KEY,
	[L["Recipe"]] = itemCategories.RECIPE,
	[L["Reagent"]] = itemCategories.REAGENT,
	[L["Gem"]] = itemCategories.GEM,
	[L["Consumable"]] = itemCategories.CONSUMABLE,
	[L["Container"]] = itemCategories.CONTAINER,
	[L["Quiver"]] = itemCategories.QUIVER,
	[L["Miscellaneous"]] = itemCategories.MISCELLANEOUS,
	[L["Projectile"]] = itemCategories.PROJECTILE,
	[L["Trade Goods"]] = itemCategories.TRADEGOODS
}
local specialBagContents = {
	["Bag.Special.Ammo"]			=	"Reagent.Ammo.Bullet",
	["Bag.Special.Quiver"]			=	"Reagent.Ammo.Arrow",
	["Bag.Special.Enchanting"]		=	"Container.ItemsInType.Enchanting",
	["Bag.Special.Engineering"]		=	"Container.ItemsInType.Engineering",
	["Bag.Special.Herb"]			=	"Container.ItemsInType.Herb",
	["Bag.Special.Jewelcrafting"]	=	"Container.ItemsInType.Gem",
	["Bag.Special.Mining"]			=	"Container.ItemsInType.Mining",
	["Bag.Special.Soul Shard"]		=	"Container.ItemsInType.Soul Shard"
}

-- Trade Good sorting
local ingredientRanking = {
	["Tradeskill.Mat.ByType.Bar"] = 1,
	["Tradeskill.Mat.ByType.Bolt"] = 2,
	["Tradeskill.Mat.ByType.Cloth"] = 3,
	["Tradeskill.Mat.ByType.Crystal"] = 4,
	["Tradeskill.Mat.ByType.Dust"] = 5,
	["Tradeskill.Mat.ByType.Dye"] = 6,
	["Tradeskill.Mat.ByType.Elemental"] = 7,
	["Tradeskill.Mat.ByType.Essence"] = 8,
	["Tradeskill.Mat.ByType.Flux"] = 9,
	["Tradeskill.Mat.ByType.Gem"] = 10,
	["Tradeskill.Mat.ByType.Grinding Stone"] = 11,
	["Tradeskill.Mat.ByType.Herb"] = 12,
	["Tradeskill.Mat.ByType.Hide"] = 13,
	["Tradeskill.Mat.ByType.Leather"] = 14,
	["Tradeskill.Mat.ByType.Mote"] = 15,
	["Tradeskill.Mat.ByType.Oil"] = 16,
	["Tradeskill.Mat.ByType.Ore"] = 17,
	["Tradeskill.Mat.ByType.Part"] = 18,
	["Tradeskill.Mat.ByType.Pearl"] = 19,
	["Tradeskill.Mat.ByType.Poison"] = 20,
	["Tradeskill.Mat.ByType.Powder"] = 21,
	["Tradeskill.Mat.ByType.Primal"] = 22,
	["Tradeskill.Mat.ByType.Rod"] = 23,
	["Tradeskill.Mat.ByType.Salt"] = 24,
	["Tradeskill.Mat.ByType.Scale"] = 25,
	["Tradeskill.Mat.ByType.Shard"] = 26,
	["Tradeskill.Mat.ByType.Spice"] = 27,
	["Tradeskill.Mat.ByType.Spice"] = 28,
	["Tradeskill.Mat.ByType.Spider Silk"] = 29,
	["Tradeskill.Mat.ByType.Thread"] = 30,
	["Tradeskill.Mat.ByType.Vial"] = 31,
	["Tradeskill.Mat.ByProfession"] = 32,
	["Tradeskill.Crafted"] = 33,
}

local maxSort = 34 -- Default to this

local armWepRank = {
	INVTYPE_HEAD = 1,
	INVTYPE_NECK = 2,
	INVTYPE_SHOULDER = 3,
	INVTYPE_BODY = 4,
	INVTYPE_CHEST = 5,
	INVTYPE_ROBE = 5,
	INVTYPE_WAIST = 6,
	INVTYPE_LEGS = 7,
	INVTYPE_FEET = 8,
	INVTYPE_WRIST = 9,
	INVTYPE_HAND = 10,
	INVTYPE_FINGER = 11,
	INVTYPE_TRINKET = 12,
	INVTYPE_CLOAK = 13,
	INVTYPE_WEAPON = 14,
	INVTYPE_SHIELD = 15,
	INVTYPE_2HWEAPON = 16,
	INVTYPE_WEAPONMAINHAND = 18,
	INVTYPE_WEAPONOFFHAND = 19,
	INVTYPE_HOLDABLE = 20,
	INVTYPE_RANGED = 21,
	INVTYPE_THROWN = 22,
	INVTYPE_RANGEDRIGHT = 23,
	INVTYPE_AMMO = 24,
	INVTYPE_RELIC = 25,
	INVTYPE_TABARD = 26,
}

local PlowList = getTable() -- Storage for the Joblisting

PlowEngine:Hide() -- Prevent update

-- This function is to move items into other bags, be they bank bags or specifically to
-- special bags, like herb/enchant/etc. Quite simply, fill up all the spots in the BagsTo
-- with items from BagsFrom (if it fits).
-- Requirements: The bags in BagsTo are all of the same type. Which means that depending on
-- how this is called, we will have to subseparate the bags into their special types.
function PlowEngine:Consolidate(BagsFrom, BagsTo)
	local empty = getTable()

	-- Find out how much space we have
	for _,bag in ipairs(BagsTo) do
		for slot=1, GetContainerNumSlots(bag) do
			if not GetContainerItemLink(bag, slot) then -- we're empty
				table.insert(empty, getTable(bag, slot))
			end
		end
	end
	-- Now check if we're speshul.
	local isSpecial, bagType = PT:ItemInSet(GetInventoryItemLink("player", ContainerIDToInventoryID(BagsTo[1])), "Bag.Special")
	local fill = getTable()
	local available = #empty

	if isSpecial then
		for _,bag in ipairs(BagsFrom) do
			for slot=1, GetContainerNumSlots(bag) do
				if available > 0 then -- if there's room...
					local link = select(3, (GetContainerItemLink(bag, slot) or ""):find("item:(%d+):"))
					if link and PT:ItemInSet(link, specialBagContents[bagType]) then
						table.insert(fill, getTable(bag,slot))
						available = available - 1 
					end
				end
			end
		end
	end
end
-- This function finds non-empty stacks of the same item, and restacks them so
-- that it fills the least number of slots possible, with the remaining
-- unempty stack at the head of the line so that any auto insertion/removal (looting,
-- ammo usage, spell component usage etc) will use that non-full stack rather
-- than a full one, maintaining the compression as much as possible.
function PlowEngine:Restack(...)
	local db = MrPlow.db.profile
	local notFull = getTable()
	local dupe = getTable()

	if select("#", ...) > 0 then
		BagList = getTable(...)
	end

	for _, bag in ipairs(BagList) do
		for slot=1, GetContainerNumSlots(bag) do
			if not (db.IgnoreSlots[bag] and db.IgnoreSlots[bag][slot]) then -- If we're not ignoring this specific slot
				local link = select(3, (GetContainerItemLink(bag, slot) or ""):find("item:(%d+):"))
				if link then
					if not db.IgnoreItems[link] then -- if we're not ignoring this specific item
						local stackSize = select(2, GetContainerItemInfo(bag, slot))
						local fullStack = select(8, GetItemInfo(link))
						local nFull = notFull[link]

						-- if we've already recorded this item, and isn't a
						-- full stack, add it to dupes
						if nFull and stackSize < fullStack then
							if not dupe[link] then
								dupe[link] = getTable()
							end
							-- Move the entry from notFull (latest marker
							-- position for this object) to dupe and create a
							-- new marker point for the last item.
							table.insert(dupe[link], getTable(nFull[1], nFull[2], nFull[3], nFull[4]))
							returnTable(nFull)
							notFull[link] = getTable(bag, slot, stackSize, fullStack)
						else
							-- if it's not full, then put it on our list to fill up
							if stackSize < fullStack then
								notFull[link] = getTable(bag, slot, stackSize, fullStack)
							end
						end
					end
				end
			end
		end
	end
	--
	--Well, now we have two lists. notFull, which ostensibly lists the
	--items that have duplicates, and stores the last position found that does
	--not have a full stack. And dupe, which stores all the stacks previous to
	--the one marked in notFull that are not full in forward order.
	--
	-- So we now move through the lists and restack as required. Take from the
	-- first of the duplicate stacks, and move it to the 'notFull' last stack.
	-- This way we fill all stacks from the end back, leaving the uneven stack
	-- at the front of the list
	--
	for item, stacks in pairs(dupe) do
		-- We're going to remove an entry at a time from the dupe table and
		-- move the contents to the last stack marked by the notFull entry
		while #stacks > 0 do
			local fromStack = table.remove(stacks, 1)
			-- Each dupe has {Bag, Slot, Current Stack Size, Max Stack Size}
			local target = notFull[item]
			local toFill = target[4] - target[3]
			
			if fromStack[3] < toFill then
				-- if we can't fill the final stack, move the whole first stack
				-- across
				PlowEngine:MoveSlot(fromStack[1], fromStack[2], fromStack[3], target[1], target[2])
				target[3] = toFill - fromStack[3]
			else
				-- if we -can- totally fill the final stack with leftovers
				-- move what we can across, and move the fromStack back on the
				-- list and shift the target to be the last on the dupe list
				PlowEngine:MoveSlot(fromStack[1], fromStack[2], toFill, target[1], target[2])
				fromStack[3] = fromStack[3] - toFill
				if fromStack[3] > 0 then 
					-- if there's leftover, then move the remainder to the
					-- beginning of the dupe list
					table.insert(stacks, 1, getTable(fromStack[1], fromStack[2], fromStack[3], fromStack[4]))
				end
				-- clear the now full target
				returnTable(notFull[item])
				-- set the mark to the last non-empty stack
				notFull[item] = table.remove(stacks)
				-- Now, if stacks is empty, we have nothing else to fill, so
				-- drop out of the loop and clean up notFull[item]
			end
			
			returnTable(fromStack)
		end
		if notFull[item] then
			returnTable(notFull[item])
		end
	end
   -- Now run	
	if #PlowList > 0 then
		MrPlow:Print("Starting Restack")
		currentProcess = PlowEngine.Restack
		PlowEngine:Show()
	else
		MrPlow:Print("Stopping Restack")
		PlowEngine:Hide()
		MrPlow.currentFunction = nil
		returnTable(dupe)
		returnTable(notFull)
	end
end


function PlowEngine:Defragment(...)
	local db = MrPlow.db.profile
	local full = getTable()
	local empty = getTable()

	if select("#", ...) > 0 then
		BagList = getTable(...)
	end

	for _, bag in ipairs(BagList) do
		if not db.IgnoreBags[bag] then
			for slot=1, GetContainerNumSlots(bag) do
				if not (db.IgnoreSlots[bag] and db.IgnoreSlots[bag][slot]) then
					local link = select(3, (GetContainerItemLink(bag, slot) or ""):find("item:(%d+):"))
					if not link then -- empty slot
						if db.EmptySpace == "Bottom" then
							table.insert(empty, getTable(bag, slot))
						else
							table.insert(empty, 1, getTable(bag, slot))
						end
					elseif not db.IgnoreItems[link] then -- if full and not ignored
						if db.EmptySpace == "Bottom" then
							table.insert(full, 1, getTable(bag, slot))
						else
							table.insert(full, getTable(bag, slot))
						end
					end
				end       
			end
		end
	end            
	-- Now we have two lists. Depending on where we want the empty space (at
	-- the top or bottom) we have a list of empty spaces and a list of full
	-- spaces going in the opposite direction. Now we take from the full list,
	-- and move each item into the empty list. 
	
	while next(full) do
		local loose = table.remove(full, 1) -- get the last full slot
		local space = table.remove(empty, 1) -- and the first available empty slot
		local lPosition, sPosition
		
		if loose and space then
			lPosition = 100* loose[1] + loose[2]
			sPosition = 100* space[1] + space[2]
		end
		-- Now if the space is past the item (depending on which direction
		-- we're defragging in...) 
		if (not loose or not space) or -- We don't have anything to move or place to move it
			(sPosition > lPosition and db.EmptySpace == "Bottom") 
			or (sPosition < lPosition and db.EmptySpace == "Top") then -- We've crossed over the midpoint
		   
			if loose then
				returnTable(loose)
			end
			if space then
				returnTable(space)
			end
			returnTable(empty)
			returnTable(full)
			break
		end
		-- Otherwise, move away!
		PlowEngine:MoveSlot(loose[1], loose[2], -1, space[1], space[2])
   end
   -- Now run	
	if #PlowList > 0 then
		MrPlow:Print("Starting Defragment")
		currentProcess = PlowEngine.Defragment
		PlowEngine:Show()
	else
		MrPlow:Print("Finishing Defragment")
		PlowEngine:Hide()
		currentProcess = nil
		returnTable(empty)
		returnTable(full)
	end
   
end

-- Now for the sorting function. This is going to be hard to refactor
-- in a satisfactory manner, since we have to jump through so many hoops in
-- order to get the required result.

-----------------Sort Functions -----------------------------------------
-- Better to define them locally outside the function so they're only created 
-- once rather than every time the function is run. I'm kinda considering a
-- cascading set of sort functions so it goes through the top level and
-- filters down until if there's no rule, it sticks to alphabetical, and then
-- stacksize. Separating them out into different functions makes it easier to
-- insert finer grain filters at a later date.
--
-- Lets see:
--          Count -- Bottom level filter
--          Alpha
--          Rarity
--          Location
--          PT-Categorical (tradegoods etc)
--          ItemRank
--          Junk - Top level check

function SortCount(a,b)
	return a.itemCount < b.itemCount
end

function SortAlpha(a,b)
	if a.itemName == b.itemName then
		local pass, ret = pcall(function() return SortCount(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"SortCount: "..ret)
			return true
		end
	end
	return a.itemName < b.itemName
end

function SortRarity(a, b)
	if a.itemRarity == b.itemRarity then
		local pass, ret = pcall(function() return SortAlpha(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"SortAlpha: "..ret)
			return true
		end
	end
	return a.itemRarity < b.itemRarity
end

function SortLocation(a, b)
	if (not a.itemEquipLoc or b.itemEquipLoc or a.itemEquipLoc == "" or b.itemEquipLoc == "") then
		local pass, ret = pcall(function() return SortRarity(a, b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"SortRarity: "..ret)
			return true
		end
	end
	if not a.itemEquipLoc or not armWepRank[a.itemEquipLoc] then MrPlow:Print("a:"..a.itemName) end
	if not b.itemEquipLoc or not armWepRank[b.itemEquipLoc] then MrPlow:Print("b:"..b.itemName) end
	return armWepRank[a.itemEquipLoc] < armWepRank[b.itemEquipLoc] 
end

-- By this time, we're the same type of item so we only need to check one of
-- the inputs for details 
-- We're only going to subsort within the tradegoods and consumable category
-- so far as they're the only ones that are badly grouped and require PT
-- assistance to get viable results.
function SortPTCategory(a, b)
	if (a.itemType ~= L["Trade Goods"]) then
		return SortLocation(a, b)
	end
	local aSet = select(2, PT:ItemInSet(a.itemID, "Tradeskill.Mat.ByType")) or select(2, PT:ItemInSet(a.itemID, "Tradeskill.Mat")) or select(2, PT:ItemInSet(a.itemID, "Tradeskill"))
	local bSet = select(2, PT:ItemInSet(b.itemID, "Tradeskill.Mat.ByType")) or select(2, PT:ItemInSet(b.itemID, "Tradeskill.Mat")) or select(2, PT:ItemInSet(b.itemID, "Tradeskill"))
	if type(aSet) == "string" and type(bSet) == "string" then
		a.Set = aSet 
		b.Set = bSet
		local aRank = ingredientRanking[aSet] 
		local bRank = ingredientRanking[bSet] 


		if not aRank and not bRank then
			if aSet ~= bSet then
				return aSet < bSet
			else
				local pass, ret = pcall(function() return SortLocation(a, b) end)
				if pass then 
					return ret
				else
					ErrorPrint(a,b,"SortLocation: "..ret)
					return true
				end
			end
		end

		if not aRank then
			return false
		end

		if not bRank then
			return true
		end

		if aRank == bRank then
			return SortLocation(a, b)
		else
			return aRank < bRank
		end
	end
	return SortLocation(a, b)
end

function SortSpecificPT(a, b)
	local aSet, bSet
	-- Step through each of the special consumable categories, and assign the first available
	for i=1,#sortCategories do
		aSet = select(2, PT:ItemInSet( a.itemID, sortCategories[i])) 
		if aSet then break end
	end
	for i=1,#sortCategories do
		bSet = select(2, PT:ItemInSet( b.itemID, sortCategories[i])) 
		if bSet then break end
	end
	
	if not aSet and not bSet then
		local pass, ret = pcall(function() return SortPTCategory(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"PTCat: "..ret)
			return true
		end
	end

	-- Same type? Then filter further
	if aSet then a.Set = aSet end
	if bSet then b.Set = bSet end

	if aSet == bSet then 
		return SortLocation(a, b)
		--One in the special group and the other not? Special group has priority to be at the end
	elseif (aSet and not bSet) or (not aSet and bSet) then 
		return (aSet and 1 or -1) > (bSet and 1 or -1)
	elseif aSet and bSet then
		return aSet < bSet
	end
end

function SortItemRanking(a,b)
	if a.itemRanking == b.itemRanking then
		local pass, ret = pcall(function() return SortSpecificPT(a, b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"Specific PT: "..ret)
			return true
		end
	end
	return a.itemRanking < b.itemRanking
end

-- Does this actually work? I'm trying to drop the junk at the end of the
-- grouping, depending on where the empty space is set to be at the top or
-- bottom. If A is not junk, and B is, A is less than B. If A is junk and
-- B isn't then A is greater than B.
function SortJunk(a, b)
	if (a.itemRarity > 0 and b.itemRarity > 0) or (a.itemRarity == b.itemRarity) then
		local pass, ret = pcall(function() return SortItemRanking(a,b) end)
		if pass then 
			return ret
		else
			ErrorPrint(a,b,"Item Ranking: "..ret)
			return true
		end
	else
		return a.itemRarity > b.itemRarity
	end
end

function TopLevelSort(a,b)
	if a and b then
		local pass, ret = pcall(function() return SortJunk(a,b) end)
		if pass then
			return ret
		else
			ErrorPrint(a,b,"Junk: "..ret)
			return true
		end
	else
		return true
	end
end

function ErrorPrint(a,b,func)
	MrPlow:Print("Error in "..func.." between "..a.itemName.." at "..a.bag..":"..a.slot.." and "..b.itemName.." at "..b.bag..":"..b.slot)
end

Item = getTable()

Item.mt = getTable()

Item.mt.__lt = function(a, b)
    return TopLevelSort(a,b)
end

Item.mt.__eq = function(a, b)
	if a.itemID == b.itemID and a.itemCount == b.itemCount then
		return true
	else
		return false
	end
end


Item.new = function(count, ItemID, bag, slot)
	local item = getTable()
	local tbag = bag
	setmetatable(item, Item.mt)
	if bag > 50 then tbag = bag - 50 end
    item.pos = count
	item.itemName, item.itemLink, item.itemRarity, item.itemLevel, item.itemMinLevel, 
	item.itemType, item.itemSubType, item.itemStackCount, item.itemEquipLoc, item.itemTexture = GetItemInfo(ItemID)
	item.itemID = ItemID 
	item.itemCount = select(2, infoFunc(tbag, slot))
    item.itemRanking = itemRanking[item.itemType]
    if not item.itemRanking then item.itemRanking = -1 end
	item.bag = bag
	item.slot = slot
	item.Set = item.itemEquipLoc
	return item
end


-- The new mass movement sort. Kinda a binary sort in regards to movement.
-- This will be a whole lot more CPU intensive as it's not predetermining
-- the movement path, but depending on the current layout to determine what
-- needs to be moved. Experimental.
--
-- Okay, here's the information we have
--
-- Current Bag/Slot
-- Current Position
-- Sorted Position
-- Sorted Bag/Slot
--
-- What we need is to check that what we're swapping with isn't already where it's supposed to be.
function PlowEngine:MassSort(...)
    local OriginalLoc = getTable()
    local Jumble = getTable()
    local Dirty  = getTable()
	local itemCount = 0	
	local tbag
	
	if select("#", ...) > 0 then
		BagList = getTable(...)
		MrPlow:Print("Cleaning table")
		Clean = getTable() 
	end

	for bag, slot in self:NextSlot(BagList) do 
		
		if bag > 50 then
			infoFunc = GetGuildBankItemInfo
			linkFunc = GetGuildBankItemLink
			tbag = bag - 50
		elseif bag < 50 then
			infoFunc = GetContainerItemInfo
			linkFunc = GetContainerItemLink
			tbag = bag
		end

		if not (db.IgnoreSlots[bag] and db.IgnoreSlots[bag][slot]) then
			while true do
				if(select(3, infoFunc(tbag,slot))) then
					coroutine.yield(self)
				else
					break;
				end
			end				
			local link = select(3, (linkFunc(tbag, slot) or ""):find("item:(%d+)"))
			if link and not db.IgnoreItems[link] then
				itemCount = itemCount + 1
				local item = Item.new(itemCount, link, bag, slot)
				table.insert(Jumble, item)
				table.insert(OriginalLoc, getTable(bag, slot, item))
			end
		end
	end
    table.sort(Jumble)
	--PlowEngine:PrintList(Jumble,114)
	for i=1,#Jumble do
	    local item = Jumble[i]
	    -- If the current item to be placed does not have an identical item there or is in the same position 
	    -- as what needs to move into it, then continue
		if item ~= Jumble[item.pos] and item ~= OriginalLoc[i][3] then 
			-- If we haven't moved something into either of these slots, then continue
			if not (Dirty[item.bag..":"..item.slot] or Dirty[OriginalLoc[i][1]..":"..OriginalLoc[i][2]]) then
				-- If we're not displacing an already correct location, then continue
				if not Clean[item.bag..":"..item.slot] and not Clean[OriginalLoc[i][1]..":"..OriginalLoc[i][2]] then
					PlowEngine:MoveSlot(item.bag, item.slot, -1, OriginalLoc[i][1], OriginalLoc[i][2]) -- Move the item into it's proper position
					Dirty[item.bag..":"..item.slot] = true
					Dirty[OriginalLoc[i][1]..":"..OriginalLoc[i][2]] = true
					Clean[OriginalLoc[i][1]..":"..OriginalLoc[i][2]] = true -- Moving it into the correct position
				end
			end
		end
    end
	returnTable(Dirty)
	returnTable(Jumble)
	returnTable(OriginalLoc)

	if #PlowList > 0 then
		MrPlow:Print("Items to move: "..#PlowList)
		currentProcess = PlowEngine.MassSort
		PlowEngine:Show()
	else
		MrPlow:Print("Completing Sort")
		PlowEngine:Hide()
		currentProcess = nil
		returnTable(BagList)
		returnTable(Clean)
	end
end


-- separated out for later refactoring in regards to job control
function PlowEngine:MoveSlot(fromBag, fromSlot, amount, toBag, toSlot)
	table.insert(PlowList, getTable(fromBag, fromSlot, amount, toBag, toSlot))
end

local infoFunc = GetContainerItemInfo
local pickFunc = PickupContainerItem
local splitFunc = SplitContainerItem


function PlowEngine:CheckMove(fromBag, fromSlot, amount, toBag, toSlot)

	while true do
		local _, _, locked1 = infoFunc(fromBag, fromSlot)
		local _, _, locked2 = infoFunc(toBag, toSlot)
		if locked1 or locked2 then
			coroutine.yield(self, fromBag, fromSlot, amount, toBag, toSlot)
		else
			break
		end
	end

	-- Grab either a part, or the whole of a particular slot
	if amount > 0 then
		splitFunc(fromBag, fromSlot, amount)
	else
		pickFunc(fromBag, fromSlot)
	end

	-- Drop it in the target
	if CursorHasItem() then
		pickFunc(toBag, toSlot)
	end
end


function PlowEngine.OnUpdate(self, elapsed, ...)
	if not currentProcess then return end
	-- If we have bags to operate on, and PlowList is empty and we're not currently working on a suspended move, then run again.:
	if sortbags and coroutine.status(sortbags) == "suspended" then
		coroutine.resume(sortbags)
		return
	end
	if BagList and #BagList > 0 and #PlowList == 0 and midmove and coroutine.status(midmove) == "dead" then
		sortbags = coroutine.create(currentProcess)
		coroutine.resume(sortbags, self)
	end
	if not midmove or coroutine.status(midmove) == "dead" then 
		if #PlowList > 0 then
			CurrentMove = table.remove(PlowList, 1)
			midmove = coroutine.create(self.CheckMove)
		end
	else
		coroutine.resume(midmove, self, CurrentMove[1], CurrentMove[2], CurrentMove[3], CurrentMove[4], CurrentMove[5]) 
	end
end

-- coroutine iterator for bag lists
-- Basically this will take a list of bags to create an iterator for, and, depending on what -sort- of 'bag', ie
-- inventory, or guildbank will return the appropriate -next- [bag|tab]/slot
-- 51-56 will be guildbankslots
function PlowEngine:ProcessBags(BagList, BagIndex, Slot)
	local maxSlot
	
	if BagList[BagIndex] > 50 then
		maxSlot = 98
	else
		maxSlot = GetContainerNumSlots(BagList[BagIndex])
	end

	if Slot < maxSlot then
		return BagIndex, BagList[BagIndex], Slot + 1
	else
		if BagIndex < #BagList then
			return BagIndex + 1, BagList[BagIndex + 1], 1
		else
			return
		end
	end
end

function PlowEngine:NextSlot(BagList)
	local bagindex, bag, slot = 1, 0, 1
	return function()
		bagindex, bag, slot = self:ProcessBags(BagList, bagindex, slot)
		return bag, slot
	end
end

function PlowEngine:PrintList(List, limit)
    for i,v in ipairs(List) do
    	if i + 1 ~= v.slot then
	        MrPlow:Print((i+1)..":"..(v.itemName)..": ("..v.bag..":"..v.slot..") : "..(select(3, GetGuildBankItemLink(1, i+1):find("(%b[])")) or "none")) -- v[2] and v[1] ..":"..v[2] or v))
		end
        if limit == i  then break end
    end
end

function PlowEngine:SortMe()
    self:MassSort({0,1,2,3,4})
end
