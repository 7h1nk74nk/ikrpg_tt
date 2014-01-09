-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	VersionManager.checkEncounter(getDatabaseNode());
	
	updateDisplay();
end

function updateDisplay()
	local nIndex = type.getIndex();
	
	if nIndex == 1 then
		button_add.setTooltipText("Add NPCs to Combat Tracker");
		sub_combat.setVisible(true);
		sub_skillchallenge.setVisible(false);
	elseif nIndex == 2 then
		clearNPCsFromMap();
		button_add.setTooltipText("Add skills to Skill Challenge Tracker");
		sub_combat.setVisible(false);
		sub_skillchallenge.setVisible(true);
	end
	
	if User.isHost() and (nIndex == 1 or nIndex == 2) then
		button_add.setVisible(true);
	end
end

function clearNPCsFromMap()
	if sub_combat.subwindow then
		for kNPC, vNPC in pairs(sub_combat.subwindow.npclist.getWindows()) do
			for kMapLink, vMapLink in pairs(vNPC.maplinklist.getWindows()) do
				vMapLink.deleteLink();
			end
		end
	end
end

function addEncounter()
	if not User.isHost() then
		return;
	end
	
	local nIndex = type.getIndex();
	
	if nIndex == 1 then
		clearNPCsFromMap();
		CTManager.addBattle(getDatabaseNode());
		Interface.openWindow("combattracker_window", "combattracker");
	elseif nIndex == 2 then
		SCManager.addEncounter(getDatabaseNode());
		Interface.openWindow("skillchallenge_tracker", "skillchallenge");
	end
end
