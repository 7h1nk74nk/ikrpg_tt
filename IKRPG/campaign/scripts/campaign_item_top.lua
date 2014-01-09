-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	
	VersionManager.checkItem(node);

	TypeChanged();

	OptionsManager.registerCallback("MIID", StateChanged);
	StateChanged();

	if User.isHost() then
		if node.getOwner() then
			playeredit.setVisible(true);
		end
	end
	if name.getValue() ~= "" then
		locked.setState(true);
	end
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);
end

function getDetailedAccessState()
	local bLocalLock = locked.getState();
	local bDataLock = getDatabaseNode().isReadOnly();

	local bID = true;
	if not User.isHost() then
		if not bDataLock then
			bDataLock = (DB.getValue(getDatabaseNode(), "playeredit", 0) == 0);
		end
		if OptionsManager.isOption("MIID", "on") then
			bID = (DB.getValue(getDatabaseNode(), "isidentified", 0) == 1);
		end
	end
	
	return bLocalLock, bDataLock, bID;
end

function getAccessState()
	local bLocalLock, bDataLock, bID = getDetailedAccessState();
	return (bLocalLock or bDataLock), bID;
end

function TypeChanged()
	local nType = DB.getValue(getDatabaseNode(), "mitype", "other");
	
	if nType == "weapon" then
		tabs.setTab(1, "main_weapon", "tab_main");
	elseif nType == "armor" then
		tabs.setTab(1, "main_armor", "tab_main");
	else
		tabs.setTab(1, "main_other", "tab_main");
	end
end

function StateChanged()
	local bLocalLock, bDataLock, bID = getDetailedAccessState();
	local bLock = (bLocalLock or bDataLock);

	local bHost = User.isHost();
	if bHost or bID then
		nonid_name.setVisible(false);
		name.setVisible(true);
	else
		nonid_name.setVisible(true);
		name.setVisible(false);
	end

	name.setReadOnly(bLock);
	nonid_name.setReadOnly(bLock);
	
	if bID then
		level.setVisible(true);
		level_label.setVisible(true);
		tabs.setTab(2, "propertylist", "tab_abilities");
		tabs.setTab(3, "powerlist", "tab_powers");
	else
		level.setVisible(false);
		level_label.setVisible(false);
		tabs.setTab(2);
		tabs.setTab(3);
	end

	isidentified.setVisible(OptionsManager.isOption("MIID", "on"));
	if bDataLock then
		hardlocked.setVisible(true);
		locked.setVisible(false);
	else
		hardlocked.setVisible(false);
		locked.setVisible(true);
	end

	if main_weapon.subwindow then
		main_weapon.subwindow.update();
	end
	if main_armor.subwindow then
		main_armor.subwindow.update();
	end
	if main_other.subwindow then
		main_other.subwindow.update();
	end
	
	propertylist.update();
	powerlist.update();
end
