-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Update the power display
	update();
	toggleAbilities();
	toggleDetail();
	onRechargeChanged();
	
	-- Build our own delete item menu
	registerMenuItem("Delete Power", "delete", 6);
	registerMenuItem("Confirm Delete", "delete", 6, 7);
	
	-- Check to see if we should automatically reparse power description
	local nodePower = getDatabaseNode();
	local nParse = DB.getValue(nodePower, "parse", 0);
	if nParse ~= 0 then
		DB.setValue(nodePower, "parse", "number", 0);
		CharManager.parseDescription(nodePower);
	end
	
	-- Add menu option to allow manual reparse
	registerMenuItem("Reset power abilities", "textlist", 4);
	
	-- Add menu option to add abilities
	registerMenuItem("Add ability", "pointer", 2);
	registerMenuItem("Add attack/damage ability", "radial_sword", 2, 2);
	registerMenuItem("Add heal ability", "radial_heal", 2, 3);
	registerMenuItem("Add effect ability", "radial_effect", 2, 4);
end

function onUsedChanged()
	windowlist.onUsedChanged();
end

function onRechargeChanged()
	local sRecharge = string.lower(string.sub(recharge.getValue(),1,2));
	if sRecharge == "da" then
		name.setColor("ffffffff");
		name.setFrame("headerpowerdaily", 8, 0, 8, 1)
	elseif sRecharge == "en" or sRecharge == "ac" then
		name.setColor("ffffffff");
		name.setFrame("headerpowerenc", 8, 0, 8, 1)
	elseif sRecharge == "at" then
		name.setColor("ffffffff");
		name.setFrame("headerpoweratwill", 8, 0, 8, 1)
	else
		name.setColor("ff000000");
		name.setFrame("tempmodsmall", 8, 1, 8, 2);
	end
	
	update();
end

function update()
	local mode = windowlist.window.powermode.getStringValue();

	if mode == "preparation" then
		useatwill.setVisible(false);
		usedcounter.setVisible(false);
		prepared.setVisible(true);
		name.setAnchor("left", "prepared", "right", "absolute", 12);
	else
		prepared.setVisible(false);
		
		local sRecharge = string.lower(string.sub(recharge.getValue(),1,2));
		local nPrepared = prepared.getValue();
		if sRecharge == "at" and nPrepared <= 1 then
			useatwill.setVisible(true);
			usedcounter.setVisible(false);
			name.setAnchor("left", "useatwill", "right", "absolute", 12);
		else
			useatwill.setVisible(false);
			usedcounter.setVisible(true);
			name.setAnchor("left", "usedcounter", "right", "absolute", 12);
		end
	end
end

function onMenuSelection(selection, subselection)
	if selection == 2 then
		if subselection == 2 then
			local wnd = abilities.createWindow();
			if wnd then
				DB.setValue(wnd.getDatabaseNode(), "type", "string", "attack");
				activateabilities.setValue(1);
			end
		elseif subselection == 3 then
			local wnd = abilities.createWindow();
			if wnd then
				DB.setValue(wnd.getDatabaseNode(), "type", "string", "heal");
				activateabilities.setValue(1);
			end
		elseif subselection == 4 then
			local wnd = abilities.createWindow();
			if wnd then
				DB.setValue(wnd.getDatabaseNode(), "type", "string", "effect");
				activateabilities.setValue(1);
			end
		end
	elseif selection == 4 then
		CharManager.parseDescription(getDatabaseNode());
	elseif selection == 6 and subselection == 7 then
		getDatabaseNode().delete();
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

function setSpacerState()
	if activatedetail.getValue() or activateabilities.getValue() then
		spacer.setVisible(true);
	else
		spacer.setVisible(false);
	end
end

function toggleAbilities()
	local status = activateabilities.getValue();
	abilities.setVisible(status);
	
	for k,v in pairs(abilities.getWindows()) do
		v.updateDisplay();
	end
	
	setSpacerState();
end

function toggleDetail()
	local status = activatedetail.getValue();

	-- Show the power details
	action.setVisible(status);
	recharge.setVisible(status);
	keywords.setVisible(status);
	range.setVisible(status);
	shortdescription.setVisible(status);
	
	-- Set the spacer visibility to match
	setSpacerState();
end
