-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function update()
	local bLock = isReadOnly();
	
	local bShow = false;
	for _,w in pairs(getWindows()) do
		if w.update() then
			bShow = true;
		end
	end
	
	setVisible(not bLock);
end

function addEntry()
	local wnd = NodeManager.createWindow(self);
	if wnd then
		wnd.name.setFocus();
	end
end

function onEnter()
	addEntry();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if StringManager.contains({"powerdesc", "reference_power_custom", "reference_npcaltpower", "reference_magicitem_property", "ref_ability"}, sClass) then
			NPCCommon.addPowerDB(getDatabaseNode().getParent(), draginfo.getDatabaseNode(), sClass);
		end
		return true;
	end
end
