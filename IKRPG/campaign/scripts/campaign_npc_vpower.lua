-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aPowerList = {};

function onInit()
	updateCategory();
	updatePowerTitle();
	buildPowerFields();
end

function getCreatureName()
	return DB.getValue(getDatabaseNode(), "...name", "");
end

function update()
	powerfields.update();
	return onFilter();
end
			
function onFilter()
	local bLabel = (powertitle.getValue() ~= "");
	local bList = powerfields.isVisible();
	return (bLabel or bList);
end

function updatePowerTitle()
	local sTitle = name.getValue();
	
	local sKeywords = keywords.getValue();
	if (sKeywords ~= "") and (sKeywords ~= "-") then
		sTitle  = sTitle .. " (" .. sKeywords:lower() .. ")";
	end
	
	local sAction = action.getValue();
	local sRecharge = recharge.getValue();
	local sAura = nil;
	if sAction:find("Aura") then
		sAura = "Aura " .. range.getValue();
	end
	if (sRecharge ~= "") and (sRecharge ~= "-") then
		sTitle  = sTitle .. "  •  " .. sRecharge;
		if sAura then
			sTitle = sTitle .. "; " .. sAura;
		end
	elseif sAura then
		sTitle  = sTitle .. "  •  " .. sAura;
	end
	
	powertitle.setValue(sTitle);
end

function updateCategory()
	if category then
		local sAction = action.getValue();
		if sAction == "" or sAction == "-" then
			local sDesc = shortdescription.getValue();
			for sPowerField in sDesc:gmatch("[^\r]+") do
				local sLabel = sPowerField:match("^[^(.,:;][^.,:;]*:");
				if sLabel == "Action:" then
					sAction = sPowerField:sub(sLabel:len() + 1)
				end
			end
		end
		
		local sFilter = "";
		if sAction == "" or sAction == "-" then
			sFilter = "";
		elseif sAction:find("Aura") then
			sFilter = "aura";
		elseif sAction:find("Standard") then
			sFilter = "standard";
		elseif sAction:find("Move") then
			sFilter = "move";
		elseif sAction:find("Minor") then
			sFilter = "minor";
		elseif sAction:find("Free") then
			sFilter = "free";
		elseif sAction:find("Imm") or sAction:find("Condition") or sAction:find("Triggered") or sAction:find("Opportunity") then
			sFilter = "trigger";
		end
		
		category.setValue(sFilter);
	end
end

function buildPowerFields()
	aPowerList = {};
	
	local s = shortdescription.getValue();
	for sPowerField in s:gmatch("[^\r]+") do
		local sLabel = sPowerField:match("^[^(.,:;][^.,:;]*:");
		
		if sLabel then
			local nWords = 0;
			for sWord in s:gmatch("[^%s]+") do
				nWords = nWords + 1;
				if nWords > 3 then
					sLabel = nil;
					break;
				end
			end
		end
		
		if sLabel then
			addPowerField(sPowerField:sub(sLabel:len() + 1), sLabel);
		else
			addPowerField(sPowerField);
		end
	end
		
	local sAction = action.getValue();
	if not sAction:find("Aura") then
		local sRange = range.getValue();
		if sRange ~= "" and sRange ~= "-" then
			if (#aPowerList > 0) and (aPowerList[1].sLabel == "") then
				aPowerList[1].sText = sRange .. "; " .. aPowerList[1].sText;
			else
				local aPowerField = {};
				aPowerField.sLabel = "Range:";
				aPowerField.sText = StringManager.trim(sRange);
				table.insert(aPowerList, 1, aPowerField);
			end
		end
	end

	updatePowerFields();

	powerfields.applyFilter();
end

function addPowerField(sText, sLabel)
	local aPowerField = {};
	
	aPowerField.sText = StringManager.trim(sText);
	if sLabel then
		aPowerField.sLabel = StringManager.trim(sLabel);
	else
		aPowerField.sLabel = "";
	end

	table.insert(aPowerList, aPowerField);
end

function updatePowerFields()
	powerfields.closeAll();
	
	for _,vField in ipairs(aPowerList) do
		local win = powerfields.createWindow();
		win.label.setValue(vField.sLabel);
		win.text.setValue(vField.sText);
		if vField.sLabel == "" then
			win.label.setVisible(false);
			win.text.setAnchor("left", "", "left", "absolute", 0);
		end
	end
end
