-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aSortOrder = { 
	["Setup"] = 1, 
	["Success"] = 2, 
	["Failure"] = 3,
	["Level"] = 4, 
	["Complexity"] = 5,
	["Primary Skills"] = 6, 
	["Secondary Skills"] = 7,
	["Acrobatics"] = 8, 
	["Arcana"] = 9,	
	["Athletics"] = 10,
	["Bluff"] = 11,	
	["Diplomacy"] = 12,
	["Dungeoneering"] = 13,
	["Endurance"] = 14, 
	["Heal"] = 15, 
	["History"] = 16, 
	["Insight"] = 17,	
	["Intimidate"] = 18, 
	["Nature"] = 19, 
	["Perception"] = 20, 
	["Religion"] = 21, 
	["Stealth"] = 22,	
	["Streetwise"] = 23,
	["Thievery"] = 24 };
	
function onSortCompare(w1, w2)
	local sName1 = w1.name.getValue();
	local sName2 = w2.name.getValue();
	
	local sOrder1 = aSortOrder[string.gsub(sName1, ":", "")];
	if not sOrder1 then
		sOrder1 = tonumber(sName1) or 100
	end
	local sOrder2 = aSortOrder[string.gsub(sName2, ":", "")];
	if not sOrder2 then
		sOrder2 = tonumber(sName2) or 100;
	end
	
	if sOrder1 ~= sOrder2 then
		return sOrder1 > sOrder2;
	end
end
