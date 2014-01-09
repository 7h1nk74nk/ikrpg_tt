-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bLock)
	local bLocalShow = true;
	
	if self[sControl] then
		if bLock then
			self[sControl].setReadOnly(true);
			if self[sControl].getValue() == "" then
				bLocalShow = false;
			end
		else
			self[sControl].setReadOnly(false);
		end
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
	
	return bLocalShow;
end

function update()
	local bReadOnly = windowlist.isReadOnly();

	updateControl("name", bReadOnly);
	updateControl("action", bReadOnly);
	updateControl("recharge", bReadOnly);
	updateControl("range", bReadOnly);
	updateControl("keywords", bReadOnly);
	shortdescription.setReadOnly(bReadOnly);
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		getDatabaseNode().delete();
	end
end

function getShortString()
	-- Include the power name
	local str = "Item Power [" .. DB.getValue(getDatabaseNode(), "...name", "") .. "]";
	
	-- Add in the action requirement
	local actval = string.lower(DB.getValue(getDatabaseNode(), "action", ""));
	if actval == "minor" or actval == "minor action" then
		str = str .. " [min]";
	elseif actval == "move" or actval == "move action" then
		str = str .. " [mov]";
	elseif actval == "standard" or actval == "standard action" then
		str = str .. " [std]";
	elseif actval == "free" or actval == "free action" then
		str = str .. " [free]";
	elseif actval == "interrupt" or actval == "immediate interrupt" then
		str = str .. " [imm]";
	elseif actval == "reaction" or actval == "immediate reaction" then
		str = str .. " [imm]";
	end

	-- Return the short string
	return str;
end

function getFullString()
	-- Start with the short string
	local str = getShortString();

	-- Add everything else in the notes
	local shortdesc = DB.getValue(getDatabaseNode(), "shortdescription", "");
	if shortdesc == "-" then
		shortdesc = "";
	end
	if shortdesc ~= "" then
		str = str .. " -> " .. shortdesc;
	end

	-- Return the full string
	return str;
end

function activatePower(showfullstr)
	local desc = "";
	if showfullstr == true then
		desc = getFullString();
	else
		desc = getShortString();
	end
	ChatManager.Message(desc, true, ActorManager.getActor("pc", getDatabaseNode().getChild(".....")));
end
