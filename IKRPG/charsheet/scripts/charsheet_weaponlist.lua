-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Create Item", "insert", 5);
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	if bFocus and win then
		local nOrder = CharManager.calcNextWeaponOrder(getDatabaseNode());
		win.order.setValue(nOrder);
		win.name.setFocus();
	end
	return win;
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local nodeChar = window.getDatabaseNode();
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "powerdesc" then
			CharManager.addPowerToWeaponDB(nodeChar, nodeSource);
			return true;
		else
			local bAddItem = false;
			
			if sClass == "referenceweapon" then
				bAddItem = true;
			elseif sClass == "referenceequipment" then
				if DB.getValue(nodeSource, "type", "") == "Implement" then
					bAddItem = true;
				end
			elseif sClass == "referencemagicitem" then
				local sItemClass = DB.getValue(nodeSource, "class", "");
				if sItemClass == "Weapon" or sItemClass == "Implement" then
					bAddItem = true;
				end
			elseif sClass == "item" then
				if DB.getValue(nodeSource, "mitype", "") == "weapon" then
					bAddItem = true;
				end
			end
			
			if bAddItem then
				local nodeItemList = nodeChar.createChild("inventorylist");
				local nodeItem = ItemsManager.addItemToList(nodeItemList, sClass, nodeSource);
				if nodeItem then
					CharManager.addWeaponDB(nodeChar, nodeItem);
				end
				return true;
			end
		end
	end
end
