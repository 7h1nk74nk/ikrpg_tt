-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getVisibleName(nodeItem, bCharSheet)
	if not User.isHost() or bCharSheet then
		if DB.getValue(nodeItem, "isidentified", 0) == 0 then
			local sName = DB.getValue(nodeItem, "nonid_name", "");
			if sName == "" then
				sName = "Unidentified Item";
			end
			return sName;
		end
	end
	return DB.getValue(nodeItem, "name", "");
end

function handleDrop(nodeList, draginfo)
	if draginfo.isType("shortcut") then
		local sClass,_ = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		if nodeSource then
			-- Make sure we are not dropping from our own list
			if sClass == "item" then
				local sListNode = nodeList.getNodeName();
				if string.sub(nodeSource.getNodeName(), 1, #sListNode) == sListNode then
					return nil;
				end
			end
			
			return addItemToList(nodeList, sClass, nodeSource);
		end
	end
	
	return nil;
end

function addItemToList(nodeList, sClass, nodeSource)
	local nodeNew = nil;
	
	if nodeSource then
		if sClass == "item" then
			local nID = DB.getValue(nodeSource, "isidentified", nil);
			
			nodeNew = nodeList.createChild();
			DB.copyNode(nodeSource, nodeNew);
			
			if not nID then
				DB.setValue(nodeNew, "isidentified", "number", 0);
			end
			
		elseif StringManager.contains({"referencemagicitem", "referencearmor", "referenceweapon", "referenceequipment"}, sClass) then
			nodeNew = nodeList.createChild();
			DB.copyNode(nodeSource, nodeNew);

			-- Set the identified field
			if sNodeClass == "referencemagicitem" then
				DB.setValue(nodeItem, "isidentified", "number", 0);
			else
				DB.setValue(nodeItem, "isidentified", "number", 1);
			end
			
			-- Set the item type
			local sItemType = "other";
			if sClass == "referencemagicitem" then
				local sItemClass = DB.getValue(nodeNew, "class", "");
				if sItemClass == "Weapon" or sItemClass == "Implement" then
					sItemType = "weapon";
				elseif sItemClass == "Armor" then
					sItemType = "armor";
				end
			elseif sClass == "referenceweapon" then
				sItemType = "weapon";
			elseif sClass == "referencearmor" then
				sItemType = "armor";
			elseif sClass == "referenceequipment" then
				local sItemClass = DB.getValue(nodeNew, "type", "");
				if sItemClass == "Implement" then
					sItemType = "weapon";
				end
			end
			DB.setValue(nodeNew, "mitype", "string", sItemType);
			
			-- Convert cost node if needed
			local nodeCost = nodeNew.getChild("cost");
			if nodeCost and nodeCost.getType() == "number" then
				local nCost = nodeCost.getValue();
				nodeCost.delete();
				DB.setValue(nodeNew, "cost", "string", "" .. string.sub(tostring(nCost), 1, 4) .. " gp");
			end
			
			-- Convert the description node
			local nodeDesc = nodeNew.getChild("description");
			if nodeDesc then
				DB.setValue(nodeNew, "flavor", "string", nodeDesc.getText());
				nodeDesc.delete();
			end

			-- Set a few custom data fields
			if sClass == "referenceweapon" then
				DB.setValue(nodeNew, "class", "string", "Weapon");
				
				local aSubClass = {};
				local nodeProf = nodeNew.getChild("prof");
				if nodeProf then
					local sProf = nodeProf.getValue();
					if sProf ~= "" then
						table.insert(aSubClass, sProf);
					end
					nodeProf.delete();
				end
				local nodeType = nodeNew.getChild("type");
				if nodeType then
					local sType = nodeType.getValue();
					if sType ~= "" then
						table.insert(aSubClass, sType);
					end
					nodeType.delete();
				end
				local nodeHeft = nodeNew.getChild("heft");
				if nodeHeft then
					local sHeft = nodeHeft.getValue();
					if sHeft ~= "" then
						table.insert(aSubClass, sHeft);
					end
					nodeHeft.delete();
				end
				DB.setValue(nodeNew, "subclass", "string", table.concat(aSubClass, "; "));

			elseif sClass == "referencearmor" then
				DB.setValue(nodeNew, "class", "string", "Armor");
				
				local nodeType = nodeNew.getChild("type");
				if nodeType then
					nodeType.delete();
				end
				local nodeProf = nodeNew.getChild("prof");
				if nodeProf then
					DB.setValue(nodeNew, "subclass", "string", nodeProf.getValue());
					nodeProf.delete();
				end

			elseif sClass == "referenceequipment" then
				DB.setValue(nodeNew, "class", "string", "Equipment");
				
				local nodeType = nodeNew.getChild("type");
				if nodeType then
					DB.setValue(nodeNew, "subclass", "string", nodeType.getValue());
					nodeType.delete();
				end
			end
		end
	end
	
	return nodeNew;
end

