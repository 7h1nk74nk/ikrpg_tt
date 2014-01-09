-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addWeapon(source)
	-- Add the data to the magic item
	local statwindow = window.getDatabaseNode()

	DB.setValue(statwindow, "damage", "string", DB.getValue(source, "damage", "") .. " damage");
	DB.setValue(statwindow, "profbonus", "number", DB.getValue(source, "profbonus", 0));
	DB.setValue(statwindow, "weight", "number", DB.getValue(source, "weight", 0));
	DB.setValue(statwindow, "range", "number", DB.getValue(source, "range", 0));
	DB.setValue(statwindow, "group", "string", DB.getValue(source, "group", ""));
	DB.setValue(statwindow, "properties", "string", DB.getValue(source, "properties", ""));
	DB.setValue(statwindow, "type", "string", DB.getValue(source, "type", ""));
	
	local srcname = DB.getValue(source, "name", "");
	local dstname = DB.getValue(statwindow, "name", "");
	dstname = string.gsub(dstname, " Weapon ", " " .. srcname .. " ");
	DB.setValue(statwindow, "name", "string", dstname);
end

function addArmor(source)
	-- Add the data to the magic item
	local statwindow = window.getDatabaseNode()

	DB.setValue(statwindow, "ac", "number", DB.getValue(source, "ac", 0));
	DB.setValue(statwindow, "min_enhance", "number", DB.getValue(source, "min_enhance", 0));
	DB.setValue(statwindow, "weight", "number", DB.getValue(source, "weight", 0));
	DB.setValue(statwindow, "checkpenalty", "number", DB.getValue(source, "checkpenalty", 0));
	DB.setValue(statwindow, "speed", "number", DB.getValue(source, "speed", 0));
	DB.setValue(statwindow, "type", "string", DB.getValue(source, "type", ""));
	
	local srcname = DB.getValue(source, "name", "");
	local dstname = DB.getValue(statwindow, "name", "");
	dstname = string.gsub(dstname, " Armor ", " " .. srcname .. " ");
	DB.setValue(statwindow, "name", "string", dstname);
end

function addEquipment(source)
	-- Add the data to the magic item
	local statwindow = window.getDatabaseNode()

	DB.setValue(statwindow, "weight", "number", DB.getValue(source, "weight", 0));
end

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.isType("shortcut") then
			local class, datasource = draginfo.getShortcutData();
			local source = draginfo.getDatabaseNode();

			if source then
				if class == "referenceweapon" then
					addWeapon(source);
				elseif class == "referencearmor" then
					addArmor(source);
				elseif class == "referenceequipment" then
					addEquipment(source);
				end
			end

			return true;
		end
	end
end

