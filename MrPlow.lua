-- Name: MrPlow
-- Author: Wobin
-- Email: wobster@gmail.com
-- Description: MrPlow is a physical restacker/defragger/sorter. It will
-- physically move the items in your inventory to suit certain rules.
--
-- Notes: This is an OO rewrite of the original, which was a horrific
-- convolution of spaghetti code, considering we didn't have Ace2 back then in
-- those old Ace days =P
--
-- It's also an exercise in "What the hell was I thinking at the time" we all
-- run into when refactoring code. Hopefully this write is a whole lot clearer
-- as to the mechanism of how MrPlow does stuff.

MrPlow = LibStub("AceAddon-3.0"):NewAddon("MrPlow", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local getTable
local returnTable
local db
local meta

MrPlow.PlowEngine = CreateFrame("Frame", "PlowEngine")

-- Pool of frames to reuse.
MrPlow.tablePool = setmetatable({},
	( {__index = function(self, n)
			if n==0 then
				return table.remove(self) or {}
			end
		end})
	)

function MrPlow.getTable(...)
	local newTable = MrPlow.tablePool[0]
	local args = select("#", ...)
	if args > 0 then
		for i=1, args do
			table.insert(newTable, (select(i, ...)))
		end
	end
        newTable.recycled = nil
	setmetatable(newTable, meta)
	return newTable
end

function MrPlow.returnTable(frame)
        if not frame or frame.recycled then return end
	for i,v in pairs(frame) do
		if type(frame[i]) == "table" then
			returnTable(frame[i])
		end
		frame[i] = nil
	end
        frame.recycled = true
	table.insert(MrPlow.tablePool, frame)
end

getTable = MrPlow.getTable
returnTable = MrPlow.returnTable

function MrPlow:OnInitialize()
	self.version = "5.0."..string.sub("$Revision: 60912 $", 12, -3)
	self.db = LibStub("AceDB-3.0"):New("MrPlowDB", {
		profile = {
			IgnoreItems = { [6265] = true },
			IgnoreSlots = {},
			IgnoreBags = {},
			EmptySpace = "Bottom",
		}
	});

	db = self.db.profile;
	self:RegisterChatCommand("mrplow", "DoStuff")
	self:RegisterChatCommand("mp", "DoStuff")
	MrPlow.PlowEngine:Enable();
	meta = MrPlow:getTable()
	meta.__mode = "v"

	local ldb = LibStub("LibDataBroker-1.1", true)
	if ldb then
		local t = {
			type = "launcher",
			icon = "Interface\\AddOns\\MrPlow\\icon.tga",
			-- TODO: Later add a right click to bring a drop down
			-- menu of things to do.
			OnClick = function()
				PlowEngine:MassSort(1, 2, 3, 4)
			end,
		}
		self.ldb = ldb:NewDataObject("MrPlow", t)
	end
end

function MrPlow:BagCheck()
	for i = 1, 4 do
		local name = GetBagName(i)
		local btype = GetItemFamily(name)
		-- Ignores all slots in a bag
		if (btype and btype > 0) and name ~= "Backpack" then
			db.IgnoreBags[i] = true
		-- This checks if the bag has changed to a bag we can sort
		elseif db.IgnoreBags[i] then
			db.IgnoreBags[i] = nil
		end
	end
end

function MrPlow:DoStuff(args)
	self:BagCheck()
	if args == "stack" then
		PlowEngine:Restack(0, 1, 2, 3, 4)
	elseif args == "defrag" then
		PlowEngine:Defragment(0, 1, 2, 3, 4)
	elseif args == "sort" then
		PlowEngine:MassSort(0, 1, 2, 3, 4)
	elseif args == "theworks" then
		PlowEngine:Restack(0, 1, 2, 3, 4)
		PlowEngine:Defragment(0, 1, 2, 3, 4)
		PlowEngine:MassSort(0, 1, 2, 3, 4)
	elseif args == "bankstack" then
		PlowEngine:Restack(-1, 5, 6, 7, 8, 9, 10, 11)
	elseif args == "bankdefrag" then
		PlowEngine:Defragment(-1, 5, 6, 7, 8, 9, 10, 11)
	elseif args == "banksort" then
		PlowEngine:MassSort(-1, 5, 6, 7, 8, 9, 10, 11)
	end
end

function MrPlow:OnClick()
	self.PlowEngine:SortMe()
end

function MrPlow:IsIgnoredSlot(bag, slot)
	return db.IgnoreSlots[bag] and db.IgnoreSlots[bag][slot] or false
end

function MrPlow:IgnoreSlots(bag, slot)
	if not db.IgnoreSlots[bag] then
		db.IgnoreSlots[bag] = getTable()
	end
	db.IgnoreSlots[bag][slot] = true
end

function MrPlow:UnignoreSlots(bag, slot)
	db.IgnoreSlots[bag][slot] = nil

	if not next(db.IgnoreSlots[bag]) then
		returnTable(db.IgnoreSlots[bag])
	end
end
