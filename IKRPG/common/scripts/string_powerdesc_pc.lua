-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getCreatureType()
	return "pc";
end
function getCreatureNode()
	return window.getDatabaseNode().getChild("...");
end

function getFocusRecord(tool_order, ability_type)
	for _,v in pairs(DB.getChildren(getCreatureNode(), "weaponlist")) do
		local order_val = DB.getValue(v, "order", 0);
		if order_val == tool_order then
			return CharManager.getFocusRecord(ability_type, v);
		end
	end
	
	return nil;
end

function getWeaponRecord(ability_type)
	return getFocusRecord(DB.getValue(getCreatureNode(), "powerfocus.weapon.order", 0), ability_type);
end

function getImplementRecord(ability_type)
	return getFocusRecord(DB.getValue(getCreatureNode(), "powerfocus.implement.order", 0), ability_type);
end
