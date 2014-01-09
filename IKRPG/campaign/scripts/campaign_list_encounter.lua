-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if User.isHost() then
		if draginfo.isType("shortcut") then
			local sClass,_ = draginfo.getShortcutData();
			local nodeSource = draginfo.getDatabaseNode();

			if sClass == "reference_skillchallenge" then
				addSkillChallenge(nodeSource);
			end

			return true;
		end
	end
end

function addSkillChallenge(nodeSource)
	local nodeList = DB.createNode("battle");
	local nodeNew = nodeList.createChild();

	DB.setValue(nodeNew, "type", "string", "skillchallenge");
	
	DB.setValue(nodeNew, "name", "string", DB.getValue(nodeSource, "name", ""));

	local nLevel = tonumber(DB.getValue(nodeSource, "level", "")) or 0;
	DB.setValue(nodeNew, "level", "number", nLevel);
	local nXP = tonumber(DB.getValue(nodeSource, "xp", "")) or 0;
	DB.setValue(nodeNew, "xp", "number", nXP);

	DB.setValue(nodeNew, "flavor", "string", DB.getValue(nodeSource, "flavor", ""));
	DB.setValue(nodeNew, "details", "string", DB.getValue(nodeSource, "details", ""));
	
	local nodeNewDetails = nodeNew.createChild("items");
	for _,v in pairs(DB.getChildren(nodeSource, "items")) do
		local nodeNewItem = nodeNewDetails.createChild();
		DB.setValue(nodeNewItem, "name", "string", DB.getValue(v, "name", ""));
		DB.setValue(nodeNewItem, "numberdata", "number", DB.getValue(v, "numberdata", 0));
		DB.setValue(nodeNewItem, "text", "string", DB.getValue(v, "text", ""));
	end
end
