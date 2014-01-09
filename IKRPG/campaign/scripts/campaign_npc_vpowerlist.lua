-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bUpdatingCategories = false;
local aCategoryWindows = {};
local aCategoryNames = {
	["aura"] = "Auras",
	[""] = "Traits",
	["standard"] = "Standard Actions",
	["move"] = "Move Actions",
	["minor"] = "Minor Actions",
	["free"] = "Free Actions",
	["trigger"] = "Triggered Actions"
};
local aCategorySortOrder = {
	["aura"] = 1,
	[""] = 2,
	["standard"] = 3,
	["move"] = 4,
	["minor"] = 5,
	["free"] = 6,
	["trigger"] = 7
};

function update()
	local bLock = isReadOnly();
	
	local bShow = false;
	for _,w in pairs(getWindows()) do
		if w.update() then
			bShow = true;
		end
	end
	
	if bLock then
		setVisible(bShow);
	else
		setVisible(false);
	end

	applyFilter();
end
			
function onFilter(w)
	return w.onFilter();
end

function onListRearranged(bListChanged)
	if bListChanged then
		rebuildCategories();
	end
end

function onSortCompare(w1, w2)
	local bIsCategory1, bIsCategory2;
	local sCategory1, sCategory2;

	if w1.getClass() == "npc_vpower" then
		sCategory1 = w1.category.getValue();
		bIsCategory1 = false;
	elseif w1.getClass() == "npc_vpower_header" then
		sCategory1 = w1.category.getValue();
		bIsCategory1 = true;
	end
	if w2.getClass() == "npc_vpower" then
		sCategory2 = w2.category.getValue();
		bIsCategory2 = false;
	elseif w2.getClass() == "npc_vpower_header" then
		sCategory2 = w2.category.getValue();
		bIsCategory2 = true;
	end
	if not sCategory1 then
		sCategory1 = "";
	end
	if not sCategory2 then
		sCategory2 = "";
	end

	local nCategory1 = 2;
	local nCategory2 = 2;
	if aCategorySortOrder[sCategory1] then
		nCategory1 = aCategorySortOrder[sCategory1];
	end
	if aCategorySortOrder[sCategory2] then
		nCategory2 = aCategorySortOrder[sCategory2];
	end
	if nCategory1 ~= nCategory2 then
		return nCategory1 > nCategory2;
	end
	
	if bIsCategory1 then
		return false;
	elseif bIsCategory2 then
		return true;
	end
end

function rebuildCategories()
	if bUpdatingCategories then
		return;
	end
	bUpdatingCategories = true;
	
	-- Close all category headings
	for _,v in pairs(aCategoryWindows) do
		v.close();
	end
	aCategoryWindows = {};

	-- Create new category headings
	for _,v in ipairs(getWindows()) do
		local sCategory = v.category.getValue();
		if not aCategoryWindows[sCategory] then
			local win = createWindowWithClass("npc_vpower_header");
			if win then
				win.category.setValue(sCategory);
				win.name.setValue(aCategoryNames[sCategory]);
			end

			aCategoryWindows[sCategory] = win;
		end
	end
	
	applySort();

	bUpdatingCategories = false;
end

