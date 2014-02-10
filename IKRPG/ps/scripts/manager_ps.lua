-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aFieldMap = {};

function onInit()
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		linkPCFields(v);
	end

	DB.addHandler("partysheet.*.name", "onUpdate", updateName);
end

function mapChartoPS(nodeChar)
	if not nodeChar then
		return nil;
	end
	local sChar = nodeChar.getNodeName();

	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sChar then
			return v;
		end
	end
	
	return nil;
end

function addChar(nodeChar)
	if not nodeChar then
		return;
	end
	local nodePS = mapChartoPS(nodeChar)
	if nodePS then
		return;
	end
	
	nodePS = DB.createNode("partysheet.partyinformation").createChild();
	DB.setValue(nodePS, "link", "windowreference", "charsheet", nodeChar.getNodeName());
	linkPCFields(nodePS);
end

function onCharDelete(nodeChar)
	local nodePS = mapChartoPS(nodeChar);
	if nodePS then
		nodePS.delete();
	end
end

function onLinkUpdated(nodeField)
	DB.setValue(aFieldMap[nodeField.getNodeName()], nodeField.getType(), nodeField.getValue());
end

function onLinkDeleted(nodeField)
	aFieldMap[nodeField.getNodeName()] = nil;
end

function linkPCField(nodeChar, nodePS, sField, sType, sPSField)
	if not sPSField then
		sPSField = sField;
	end

	local nodeField = nodeChar.createChild(sField, sType);
	nodeField.onUpdate = onLinkUpdated;
	nodeField.onDelete = onLinkDeleted;
	
	aFieldMap[nodeField.getNodeName()] = nodePS.getNodeName() .. "." .. sPSField;
	onLinkUpdated(nodeField);
end

function linkPCLanguages(nodeLanguages)
	local nodePS = mapChartoPS(nodeLanguages.getParent());
	if not nodePS then
		return;
	end
	
	local aLanguages = {};
	
	for _,v in pairs(nodeLanguages.getChildren()) do
		local sName = DB.getValue(v, "name", "");
		if sName ~= "" then
			table.insert(aLanguages, sName);
		end
	end
	table.sort(aLanguages);
	
	local sLanguages = table.concat(aLanguages, ", ");
	DB.setValue(nodePS, "languages", "string", sLanguages);
end

function linkPCSkill(nodeSkill, nodePS, sPSField)
	local nodeField = nodeSkill.getChild("total");
	if not nodeField then
		return;
	end
	
	local sFullField = nodeField.getNodeName();
	local sFullPSField = nodePS.getNodeName() .. "." .. sPSField;
	if aFieldMap[sFullField] == sFullPSField then
		return;
	end
	
	nodeField.onUpdate = onLinkUpdated;
	nodeField.onDelete = onLinkDeleted;
	aFieldMap[sFullField] = sFullPSField;
	onLinkUpdated(nodeField);
end

function linkPCSkills(nodeSkills)
	local nodePS = mapChartoPS(nodeSkills.getParent());
	if not nodePS then
		return;
	end
	
	for _,v in pairs(nodeSkills.getChildren()) do
		local sLabel = DB.getValue(v, "label", ""):lower();

		if sLabel == "detection" then
			linkPCSkill(v, nodePS, "detection");
		elseif sLabel == "research" then
			linkPCSkill(v, nodePS, "research");
		
		elseif sLabel == "bribery" then
			linkPCSkill(v, nodePS, "bribery");
		elseif sLabel == "command" then
			linkPCSkill(v, nodePS, "command");
		elseif sLabel == "deception" then
			linkPCSkill(v, nodePS, "deception");
		elseif sLabel == "seduction" then
			linkPCSkill(v, nodePS, "seduction");
		elseif sLabel == "intimidation" then
			linkPCSkill(v, nodePS, "intimidation");
		elseif sLabel == "etiquette" then
			linkPCSkill(v, nodePS, "etiquette");
		elseif sLabel == "oratory" then
			linkPCSkill(v, nodePS, "oratory");
		elseif sLabel == "interrogation" then
			linkPCSkill(v, nodePS, "interrogation");
		elseif sLabel == "negotiation" then
			linkPCSkill(v, nodePS, "negotiation");
		
		elseif sLabel == "driving" then
			linkPCSkill(v, nodePS, "driving");
		elseif sLabel == "jumping" then
			linkPCSkill(v, nodePS, "jumping");
		elseif sLabel == "riding" then
			linkPCSkill(v, nodePS, "riding");
		elseif sLabel == "swimming" then
			linkPCSkill(v, nodePS, "swimming");
		elseif sLabel == "climbing" then
			linkPCSkill(v, nodePS, "climbing");
		elseif sLabel == "sneak" then
			linkPCSkill(v, nodePS, "sneak");
		end
	end
end

function linkPCFields(nodePS)
	local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then
		return;
	end
	local nodeChar = DB.findNode(sRecord);
	if not nodeChar then
		return;
	end
	
	nodeChar.onDelete = onCharDelete;
	
	linkPCField(nodeChar, nodePS, "name", "string");
	linkPCField(nodeChar, nodePS, "combattoken", "token", "token");

	linkPCField(nodeChar, nodePS, "race", "string");
	linkPCField(nodeChar, nodePS, "careers", "string", "class");
	linkPCField(nodeChar, nodePS, "XP", "number", "level");
	linkPCField(nodeChar, nodePS, "feat.points", "number", "currentfeatpoints");
	
	linkPCField(nodeChar, nodePS, "hp.total", "number", "hptotal");
	linkPCField(nodeChar, nodePS, "hp.wounds", "number", "wounds");
	linkPCField(nodeChar, nodePS, "hp.surgesmax", "number", "surgesmax");
	linkPCField(nodeChar, nodePS, "hp.surgesused", "number", "surgesused");
	
	linkPCField(nodeChar, nodePS, "stats.phy.score", "number", "Physique");
	linkPCField(nodeChar, nodePS, "stats.spd.score", "number", "Speed");
	linkPCField(nodeChar, nodePS, "stats.str.score", "number", "Strength");
	linkPCField(nodeChar, nodePS, "stats.agi.score", "number", "Agility");
	linkPCField(nodeChar, nodePS, "stats.prw.score", "number", "Prowess");
	linkPCField(nodeChar, nodePS, "stats.poi.score", "number", "Poise");
	linkPCField(nodeChar, nodePS, "stats.int.score", "number", "Intellect");
	linkPCField(nodeChar, nodePS, "stats.arc.score", "number", "Arcane");
	linkPCField(nodeChar, nodePS, "stats.per.score", "number", "Perception");
	linkPCField(nodeChar, nodePS, "willpower", "number", "Willpower");
	
	linkPCField(nodeChar, nodePS, "stats.phy.score", "number", "phycheck");
	linkPCField(nodeChar, nodePS, "stats.spd.score", "number", "spdcheck");
	linkPCField(nodeChar, nodePS, "stats.str.score", "number", "strcheck");
	linkPCField(nodeChar, nodePS, "stats.agi.score", "number", "agicheck");
	linkPCField(nodeChar, nodePS, "stats.prw.score", "number", "prwcheck");
	linkPCField(nodeChar, nodePS, "stats.poi.score", "number", "poicheck");
	linkPCField(nodeChar, nodePS, "stats.int.score", "number", "intcheck");
	linkPCField(nodeChar, nodePS, "stats.arc.score", "number", "arccheck");
	linkPCField(nodeChar, nodePS, "stats.per.score", "number", "percheck");
	linkPCField(nodeChar, nodePS, "willpower", "number", "willcheck");

	linkPCField(nodeChar, nodePS, "def_total", "number", "DEF");
	linkPCField(nodeChar, nodePS, "arm_total", "number", "ARM");
	---[[ charsheet damagepane link
	linkPCField(nodeChar, nodePS, "damage_PHY", "number", "vitality_PHY");
	linkPCField(nodeChar, nodePS, "damage_AGI", "number", "vitality_AGI");
	linkPCField(nodeChar, nodePS, "damage_INT", "number", "vitality_INT");
	--]]
	local nodeSkills = nodeChar.createChild("skilllist");
	if nodeSkills then
		nodeSkills.onChildUpdate = linkPCSkills;
		linkPCSkills(nodeSkills);
	end

	local nodeLanguages = nodeChar.createChild("languagelist");
	if nodeLanguages then
		nodeLanguages.onChildUpdate = linkPCLanguages;
		linkPCLanguages(nodeLanguages);
	end
end

function getNodeFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = nodeContainer.getNodeName();
	
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sChildContainerName = DB.getValue(v, "tokenrefnode", "");
		local nChildId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sChildContainerName == sContainerNode) and (nChildId == nId) then
			return v;
		end
	end
	return nil;
end

function getNodeFromToken(token)
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getNodeFromTokenRef(nodeContainer, nID);
end

function linkToken(nodeEntry, newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end
	
	if nodeContainer then
		DB.setValue(nodeEntry, "tokenrefnode", "string", nodeContainer.getNodeName());
		DB.setValue(nodeEntry, "tokenrefid", "string", newTokenInstance.getId());
		DB.setValue(nodeEntry, "tokenscale", "number", newTokenInstance.getScale());
	else
		DB.setValue(nodeEntry, "tokenrefnode", "string", "");
		DB.setValue(nodeEntry, "tokenrefid", "string", "");
		DB.setValue(nodeEntry, "tokenscale", "number", 1);
	end
	
	if newTokenInstance then
		newTokenInstance.setTargetable(false);
		newTokenInstance.setActivable(true);
		newTokenInstance.setActive(false);
		newTokenInstance.setVisible(true);

		newTokenInstance.setName(DB.getValue(nodeEntry, "name", ""));
	end

	return true;
end

function updateName(nodeName)
	local nodeEntry = nodeName.getParent();
	local tokeninstance = Token.getToken(DB.getValue(nodeEntry, "tokenrefnode", ""), DB.getValue(nodeEntry, "tokenrefid", ""));
	if tokeninstance then
		tokeninstance.setName(DB.getValue(nodeEntry, "name", ""));
	end
end
