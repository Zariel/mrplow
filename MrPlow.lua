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
	self.db = LibStub("AceDB-3.0"):New("MrPlowDB", { profile = {IgnoreItems = { [6265] = true },
								IgnoreSlots = {},
								IgnoreBags = {},
								EmptySpace = "Bottom",
								} });
	db = self.db.profile;
	self:RegisterChatCommand( "mrplow", "DoStuff")
	self:RegisterChatCommand( "mp", "DoStuff")
	MrPlow.PlowEngine:Enable();
	meta = MrPlow:getTable()
	meta.__mode = "v"
end

local bagcheck = function()
	local bags = {0,1,2,3,4}
	for k,v in pairs(bags) do
		local name = GetBagName(v)
		local btype = GetItemFamily(name)
		if (btype and btype > 0) and name ~= "Backpack" then
			table.remove(bags, k)
		end
	end

	return bags
end

function MrPlow:DoStuff(args)
	MrPlow:Print(args)
	local bags = bagcheck()
	if args == "stack" then
		PlowEngine:Restack(unpack(bags))
	elseif args == "defrag" then
		PlowEngine:Defragment(unpack(bags))
	elseif args == "sort" then
		PlowEngine:MassSort(unpack(bags))
	elseif args == "bankstack" then
		PlowEngine:Restack(-1,5,6,7,8,9,10,11)
	elseif args == "bankdefrag" then
		PlowEngine:Defragment(-1,5,6,7,8,9,10,11)
	elseif args == "banksort" then
		PlowEngine:MassSort(-1,5,6,7,8,9,10,11)
	end
end

function MrPlow:OnClick()
	self.PlowEngine:SortMe()
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
