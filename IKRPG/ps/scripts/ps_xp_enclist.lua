-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, dragdata)
	if User.isHost() and dragdata.isType("shortcut") then
		local sClass = dragdata.getShortcutData();
		if sClass == "battle" or sClass == "reference_skillchallenge" then
			local nodeSource = dragdata.getDatabaseNode();	
			addEncounterEntry(sClass, nodeSource);
		end
		return true;
	end
end

function addEncounterEntry(sClass, nodeSource)
	if not sClass or not nodeSource then
		return;
	end
		
	local w = createWindow();
	w.shortcut.setValue(sClass, nodeSource.getNodeName());
	w.name.setValue(DB.getValue(nodeSource, "name", ""));
	w.level.setValue(DB.getValue(nodeSource, "level", 0));
	w.xp.setValue(DB.getValue(nodeSource, "xp", 0));

	if sClass == "battle" then
		w.type.setValue("Combat");
	elseif sClass == "reference_skillchallenge" then
		w.type.setValue("Skill");
	end
end

function deleteAll()
	for k, v in pairs(getWindows()) do
		v.getDatabaseNode().delete();
	end
end

function awardXPtoParty(w)
	local nXP = 0;
	if w then
		if not w.xpawarded.getState() then
			nXP = w.xp.getValue();
			w.xpawarded.setState(true);
		end
	else
		for k,v in pairs(getWindows()) do
			if v.xpawarded.getState() == false then
				nXP = nXP + v.xp.getValue();
				v.xpawarded.setState(true);
			end
		end
	end
	if nXP ~= 0 then
		window.awardXP(nXP);
	end
end
