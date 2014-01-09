-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Update the visuals
	update();
	onRechargeChanged();
	abilities.applyFilter();
end

function onUsedChanged()
	windowlist.onUsedChanged();
end

function onRechargeChanged()
	local sRecharge = string.lower(string.sub(recharge.getValue(),1,2));
	if sRecharge == "da" then
		name.setColor("ffffffff");
		name.setFrame("headerpowerdaily", 3, 0, 6, 1)
	elseif sRecharge == "en" or sRecharge == "ac" then
		name.setColor("ffffffff");
		name.setFrame("headerpowerenc", 3, 0, 6, 1)
	elseif sRecharge == "at" then
		name.setColor("ffffffff");
		name.setFrame("headerpoweratwill", 3, 0, 6, 1)
	else
		name.setColor("ff000000");
		name.setFrame("tempmodmini", 3, 1, 6, 3);
	end
	
	update();
end

function update()
	local sRecharge = string.lower(string.sub(recharge.getValue(),1,2));
	local nPrepared = prepared.getValue();
	if sRecharge == "at" and nPrepared <= 1 then
		useatwill.setVisible(true);
		usedcounter.setVisible(false);
		name.setAnchor("left", "useatwill", "right", "absolute", 5);
	else
		useatwill.setVisible(false);
		usedcounter.setVisible(true);
		name.setAnchor("left", "usedcounter", "right", "absolute", 5);
	end
end

function getShortString()
	-- Include the power name
	local str = "Power [" .. name.getValue() .. "]";
	
	-- Add in the action requirement
	local actval = string.lower(action.getValue());
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
		str = str .. " - " .. shortdesc;
	end

	-- Return the full string
	return str;
end

function activatePower(showfullstr)
	local nodeChar = getDatabaseNode().getChild("...");
	
	local desc = "";
	if showfullstr == true then
		desc = getFullString();
	else
		desc = getShortString();
	end
	ChatManager.Message(desc, true, ActorManager.getActor("pc", nodeChar));
	
	if DB.getValue(getDatabaseNode(), "recharge", ""):lower() == "action point" then
		DB.setValue(nodeChar, "apused", "number", 1);
	end
end
					
