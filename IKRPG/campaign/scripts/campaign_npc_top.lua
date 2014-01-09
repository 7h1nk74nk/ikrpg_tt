-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	VersionManager.checkNPC(getDatabaseNode());
	
	TypeChanged();
	StateChanged();

	if name.getValue() ~= "" then
		locked.setState(true);
	end
end

function getDetailedAccessState()
	local bLocalLock = locked.getState();
	local bDataLock = getDatabaseNode().isReadOnly();

	return bLocalLock, bDataLock;
end

function getAccessState()
	local bLocalLock, bDataLock = getDetailedAccessState();
	return (bLocalLock or bDataLock);
end

function TypeChanged()
	local sType = DB.getValue(getDatabaseNode(), "npctype", "");
	
	if sType == "Trap" then
		tabs.setTab(1, "main_trap", "tab_main");
		header.setFrame("headertrap");
	elseif sType == "Vehicle" then
		tabs.setTab(1, "main_vehicle", "tab_main");
		header.setFrame("headernpc");
	else
		tabs.setTab(1, "main_creature", "tab_main");
		header.setFrame("headernpc");
	end
end

function StateChanged()
	local bLocalLock, bDataLock = getDetailedAccessState();
	local bLock = (bLocalLock or bDataLock);
	
	if bDataLock then
		hardlocked.setVisible(true);
		locked.setVisible(false);
	else
		hardlocked.setVisible(false);
		locked.setVisible(true);
	end
	
	name.setReadOnly(bLock);
	levelrole.setReadOnly(bLock);
	type.setReadOnly(bLock);
	xp.setReadOnly(bLock);
	
	if main_trap.subwindow then
		main_trap.subwindow.update();
	end
	if main_vehicle.subwindow then
		main_vehicle.subwindow.update();
	end
	if main_creature.subwindow then
		main_creature.subwindow.update();
	end
	
	text.setReadOnly(bLock);
end
