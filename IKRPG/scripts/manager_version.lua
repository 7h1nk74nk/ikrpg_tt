-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		updateDatabase(DB.findNode("."));
	end
end

function updateDatabase(nodeRoot)
	if not nodeRoot then
		return;
	end
	
	local major, minor = nodeRoot.getRulesetVersion();

	if major < 15 then
		convertCharacterPowerAbilities(nodeRoot);
	end
	if major < 16 then
		convertEffects16(nodeRoot);
	end
	if major < 17 then
		convertCTAtkField(nodeRoot);
	end
	if major < 18 then
		convertSkillTrackerResults(nodeRoot);
	end
	if major < 20 then
		convertNPCPowerDice(nodeRoot);
		convertOptions20(nodeRoot);
	end
	if major < 21 then
		convertEncounters21(nodeRoot);
		convertNPCs21(nodeRoot);
		convertItems21(nodeRoot);
		convertEffects21(nodeRoot);
		convertOptions21(nodeRoot);
		convertTables21(nodeRoot);
		convertCharacters21(nodeRoot);
	end
	if major < 22 then
		convertPartySheet22(nodeRoot);
	end
	if major < 23 then
		convertLog23(nodeRoot);
	end
	if major < 24 then
		convertPartySheet24(nodeRoot);
		convertLog24(nodeRoot);
	end
	if major < 25 then
		convertArmorEnc25(nodeRoot);
	end
end

function convertArmorEnc25(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		local nodeArmorEnc = nodeChar.getChild("encumbrance.heavyarmor");
		if nodeArmorEnc and nodeArmorEnc.getType() == "string" then
			nodeArmorEnc.delete();
		end
	end
end

function convertLog24(nodeRoot)
	local nodeLog = nodeRoot.getChild("partysheet.adventurelog");
	if nodeLog then
		local nodeNewLog = nodeRoot.createChild("calendar.log");
		if nodeNewLog then
			local bError = false;
			for _,v in pairs(nodeLog.getChildren()) do
				local nodeNewLogEntry = nodeNewLog.createChild();
				if nodeNewLogEntry then
					local nodeEpoch = v.getChild("postyearlabel");
					if nodeEpoch then
						DB.setValue(v, "epoch", "string", nodeEpoch.getValue());
						nodeEpoch.delete();
					end
					local nodeMonth = v.getChild("period");
					if nodeMonth then
						local nMonth = CalendarManager.getMonthNumber(nodeMonth.getValue())
						DB.setValue(v, "month", "number", nMonth);
						nodeMonth.delete();
					end
					local nodeDay = v.getChild("day");
					if nodeDay then
						local nDay = tonumber(nodeDay.getValue()) or 0;
						nodeDay.delete();
						DB.setValue(v, "day", "number", nDay);
					end
					local nodeDate = v.getChild("logdate");
					if nodeDate then
						DB.setValue(v, "name", "string", nodeDate.getValue());
						nodeDate.delete();
					end
					DB.copyNode(v, nodeNewLogEntry);
				else
					bError = true;
				end
			end
			if not bError then
				nodeLog.delete();
			end
		end
	end
end

function convertPartySheet24(nodeRoot)
	-- Calendar cleanup
	local nodeEpoch = nodeRoot.getChild("partysheet.campaignyearpostlabel");
	if nodeEpoch then
		nodeEpoch.delete();
	end
	local nodeYear = nodeRoot.getChild("partysheet.campaignyear");
	if nodeYear then
		nodeYear.delete();
	end
	local nodeMonth = nodeRoot.getChild("partysheet.campaignperiod");
	if nodeMonth then
		nodeMonth.delete();
	end
	local nodeDay = nodeRoot.getChild("partysheet.campaignday");
	if nodeDay then
		nodeDay.delete();
	end
	local nodeHour = nodeRoot.getChild("partysheet.campaignhour");
	if nodeHour then
		nodeHour.delete();
	end
	local nodeMinute = nodeRoot.getChild("partysheet.campaignminutes");
	if nodeMinute then
		nodeMinute.delete();
	end
	local nodeDate = nodeRoot.getChild("partysheet.campaigndate");
	if nodeDate then
		nodeDate.delete();
	end
	local nodeCalControls = nodeRoot.getChild("partysheet.campaigncalender");
	if nodeCalControls then
		nodeCalControls.delete();
	end

	-- Misc cleanup
	for _,v in pairs(DB.getChildren(nodeRoot, "partysheet.quests")) do
		local nodeOrder = v.getChild("questnum");
		if nodeOrder then
			nodeOrder.delete();
		end
	end
	local nodeQOrder = nodeRoot.getChild("partysheet.questsref");
	if nodeQOrder then
		nodeQOrder.delete();
	end
	for _,v in pairs(DB.getChildren(nodeRoot, "partysheet.encounters")) do
		local nodeOrder = v.getChild("encnum");
		if nodeOrder then
			nodeOrder.delete();
		end
	end
	local nodeEOrder = nodeRoot.getChild("partysheet.encounterref");
	if nodeEOrder then
		nodeEOrder.delete();
	end
end

function convertLog23(nodeRoot)
	local nodeLog = nodeRoot.getChild("partysheet.adventurelog");
	if nodeLog then
		local nodeNewLog = nodeRoot.createChild("calendar.log");
		if nodeNewLog then
			DB.copyNode(nodeLog, nodeNewLog);
			nodeLog.delete();
		end
	end
end

function migrateCalendar22(nodeRoot)
	-- Calendar Data
	local nodePartySheetProps = nodeRoot.getChild("partysheet_props");
	local nodeOldCalendar = nil;
	if nodePartySheetProps then
		nodeOldCalendar = nodePartySheetProps.getChild("calendardata");
	end
	local nodeNewCalendar = nodeRoot.createChild("calendar.data");
	if nodeOldCalendar and nodeNewCalendar then
		DB.copyNode(nodeOldCalendar, nodeNewCalendar);
		nodePartySheetProps.delete();
	end

	-- Calendar Current
	local nodeEpoch = nodeRoot.getChild("partysheet.campaignyearpostlabel");
	if nodeEpoch then
		DB.setValue(nodeRoot, "calendar.current.epoch", "string", nodeEpoch.getValue());
		nodeEpoch.delete();
	end
	local nodeYear = nodeRoot.getChild("partysheet.campaignyear");
	if nodeYear then
		DB.setValue(nodeRoot, "calendar.current.year", "number", nodeYear.getValue());
		nodeYear.delete();
	end
	local nodeMonth = nodeRoot.getChild("partysheet.campaignperiod");
	if nodeMonth then
		local nMonth = CalendarManager.getMonthNumber(nodeMonth.getValue());
		if nMonth ~= 0 then
			DB.setValue(nodeRoot, "calendar.current.month", "number", nMonth);
		end
		nodeMonth.delete();
	end
	local nodeDay = nodeRoot.getChild("partysheet.campaignday");
	if nodeDay then
		DB.setValue(nodeRoot, "calendar.current.day", "number", nodeDay.getValue());
		nodeDay.delete();
	end
	local nodeHour = nodeRoot.getChild("partysheet.campaignhour");
	if nodeHour then
		local nHour = nodeHour.getValue();
		local nodePhase = nodeRoot.getChild("partysheet.campaignphase");
		if nodePhase then
			if nodePhase.getValue() == "PM" then
				nHour = nHour + 12;
			end
			nodePhase.delete();
		end
		DB.setValue(nodeRoot, "calendar.current.hour", "number", nHour);
		nodeHour.delete();
	end
	local nodeMinute = nodeRoot.getChild("partysheet.campaignminutes");
	if nodeMinute then
		DB.setValue(nodeRoot, "calendar.current.minute", "number", nodeMinute.getValue());
		nodeMinute.delete();
	end
	
	-- Calendar cleanup
	local nodeDate = nodeRoot.getChild("partysheet.campaigndate");
	if nodeDate then
		nodeDate.delete();
	end
	local nodeCalControls = nodeRoot.getChild("partysheet.campaigncalender");
	if nodeCalControls then
		nodeCalControls.delete();
	end
end

function migrateAdvLog22(nodeRoot)
	-- Adventure log
	for k,v in pairs(DB.getChildren(nodeRoot, "partysheet.adventurelog")) do
		local nodeEpoch = v.getChild("postyearlabel");
		if nodeEpoch then
			DB.setValue(v, "epoch", "string", nodeEpoch.getValue());
			nodeEpoch.delete();
		end
		local nodeMonth = v.getChild("period");
		if nodeMonth then
			local nMonth = CalendarManager.getMonthNumber(nodeMonth.getValue())
			DB.setValue(v, "month", "number", nMonth);
			nodeMonth.delete();
		end
		local nodeDay = v.getChild("day");
		if nodeDay then
			local nDay = tonumber(nodeDay.getValue()) or 0;
			nodeDay.delete();
			DB.setValue(v, "day", "number", nDay);
		end
	end
end

function convertPartySheet22(nodeRoot)
	-- Calendar and Log
	migrateCalendar22(nodeRoot);
	migrateAdvLog22(nodeRoot);

	-- Misc
	for _,v in pairs(DB.getChildren(nodeRoot, "partysheet.quests")) do
		local nodeXP = v.getChild("xpvalue");
		if nodeXP then
			DB.setValue(v, "xp", "number", nodeXP.getValue());
			nodeXP.delete();
		end
		local nodeOrder = v.getChild("questnum");
		if nodeOrder then
			nodeOrder.delete();
		end
	end
	local nodeQOrder = nodeRoot.getChild("partysheet.questsref");
	if nodeQOrder then
		nodeQOrder.delete();
	end
	for _,v in pairs(DB.getChildren(nodeRoot, "partysheet.encounters")) do
		local nodeXP = v.getChild("xpvalue");
		if nodeXP then
			DB.setValue(v, "xp", "number", nodeXP.getValue());
			nodeXP.delete();
		end
		local nodeOrder = v.getChild("encnum");
		if nodeOrder then
			nodeOrder.delete();
		end
	end
	local nodeEOrder = nodeRoot.getChild("partysheet.encounterref");
	if nodeEOrder then
		nodeEOrder.delete();
	end
	for _,v in pairs(DB.getChildren(nodeRoot, "partysheet.treasureparcelcoinlist")) do
		local nodeDesc = v.getChild("name");
		if nodeDesc then
			DB.setValue(v, "description", "string", nodeDesc.getValue());
			nodeDesc.delete();
		end
	end
end

function migrateCharacter21(nodeRecord)
	local aPowerTypes = { "a0-situational", "a1-atwill", "a11-atwillspecial", "a2-cantrip", 
			"b1-encounter", "b11-encounterspecial", "b2-channeldivinity", 
			"c-daily", "d-utility", "e-itemdaily" };

	local nodePowerTypeList = nodeRecord.getChild("powers");
	if nodePowerTypeList then
		for kNodePowerType,nodePowerType in pairs(nodePowerTypeList.getChildren()) do
			if StringManager.isWord(kNodePowerType, aPowerTypes) then
				for _, nodePower in pairs(DB.getChildren(nodePowerType, "power")) do
					local nodeNewPower = nodePowerTypeList.createChild();
					DB.copyNode(nodePower, nodeNewPower);
					nodePower.delete();
				end
				nodePowerType.delete();
			end
		end
	end
	
	local nodePowerShow = nodeRecord.getChild("powershow");
	if nodePowerShow then
		nodePowerShow.delete();
	end
end

function convertCharacters21(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		migrateCharacter21(nodeChar);
	end
end

function migrateEncounter21(nodeRecord)
	local nodeType = nodeRecord.getChild("encountertype");
	if nodeType then
		if nodeType.getValue() == "Skill Challenge" then
			DB.setValue(nodeRecord, "type", "string", "skillchallenge");
		end
		nodeType.delete();
	end
	
	local nodeExp = nodeRecord.getChild("exp");
	if nodeExp then
		DB.setValue(nodeRecord, "xp", "number", nodeExp.getValue());
		nodeExp.delete();
	end
	
	local nodeOldItems = nodeRecord.getChild("skillchallengelist");
	local nodeNewItems = nodeRecord.createChild("items");
	if nodeOldItems and nodeNewItems then
		for _,nodeOldItem in pairs(nodeOldItems.getChildren()) do
			local nodeNewItem = nodeNewItems.createChild();
			if nodeNewItem then
				DB.setValue(nodeNewItem, "name", "string", DB.getValue(nodeOldItem, "name", ""));
				DB.setValue(nodeNewItem, "numberdata", "number", DB.getValue(nodeOldItem, "numberdata", 0));
				DB.setValue(nodeNewItem, "text", "string", DB.getText(nodeOldItem, "text", ""));
			end
		end
		nodeOldItems.delete();
	end
	
	for _,nodeNPC in pairs(DB.getChildren(nodeRecord, "npclist")) do
		local nodeMapLinkList = nodeNPC.getChild("maplink");
		if nodeMapLinkList then
			for _,nodeMapLink in pairs(nodeMapLinkList.getChildren()) do
				local nodeImageLink = nodeMapLink.getChild("imagelink");
				if nodeImageLink then
					DB.setValue(nodeMapLink, "imageref", "windowreference", "imagewindow", nodeImageLink.getValue());
					nodeImageLink.delete();
				end
			end
		end
	end
end

function checkEncounter(nodeRecord)
	local bMigrate = false;
	if nodeRecord.getChild("encountertype") or nodeRecord.getChild("skillchallengelist") or nodeRecord.getChild("exp") then
		bMigrate = true;
	end
	
	if bMigrate then
		if nodeRecord.isReadOnly() then
			Comm.addChatMessage("Unable to migrate read-only encounter: " .. DB.getValue(nodeRecord, "name", ""));
		else
			migrateEncounter21(nodeRecord);
		end
	end
end

function convertEncounters21(nodeRoot)
	for _,nodeEnc in pairs(DB.getChildren(nodeRoot, "battle")) do
		migrateEncounter21(nodeEnc);
	end
end

function addTrapSkillItem(nodeRecord, sSkill, nDC, sText)
	local nodeSkills = nodeRecord.createChild("trapskills");
	
	local nodeSkill = nil;
	for _,v in pairs(nodeSkills.getChildren()) do
		if DB.getValue(v, "name", "") == sSkill then
			nodeSkill = v;
			break;
		end
	end
	if not nodeSkill then
		nodeSkill = nodeSkills.createChild();
		DB.setValue(nodeSkill, "name", "string", sSkill);
	end
	
	local nodeItems = nodeSkill.createChild("nodes");
	local nodeItem = nodeItems.createChild();
	DB.setValue(nodeItem, "dc", "number", nDC);
	DB.setValue(nodeItem, "text", "string", sText);
end

function migrateNPC21(nodeRecord)
	local nodePerception = nodeRecord.getChild("perception");
	if nodePerception then
		if nodePerception.getType() == "node" then
			local nodeFlavor = nodePerception.getChild("flavor");
			if nodeFlavor then
				local sFlavor = nodeFlavor.getValue();
				if sFlavor ~= "" and sFlavor ~= "-" then
					addTrapSkillItem(nodeRecord, "Perception", 0, sFlavor);
				end
			end
			for _,nodeItem in pairs(DB.getChildren(nodePerception, "nodes")) do
				local nDC = DB.getValue(nodeItem, "dc", 0);
				local sText = DB.getValue(nodeItem, "text", "");
				addTrapSkillItem(nodeRecord, "Perception", nDC, sText)
			end
		elseif nodePerception.getType() == "number" then
			DB.setValue(nodeRecord, "perceptionval", "number", nodePerception.getValue());
		end
		nodePerception.delete();
	end
	
	local nodeAddSkills = nodeRecord.getChild("addskills");
	if nodeAddSkills then
		for _,nodeSkill in pairs(nodeAddSkills.getChildren()) do
			local sSkill = DB.getValue(nodeSkill, "skill", "");
			local nodeItems = nodeSkill.getChild("nodes");
			if nodeItems then
				for _,nodeItem in pairs(nodeItems.getChildren()) do
					local nDC = DB.getValue(nodeItem, "dc", 0);
					local sText = DB.getValue(nodeItem, "text", "");
					addTrapSkillItem(nodeRecord, sSkill, nDC, sText)
				end
			else
				addTrapSkillItem(nodeRecord, sSkill, 0, "");
			end
		end
		nodeAddSkills.delete();
	end

	local nodeCounters = nodeRecord.getChild("countermeasures");
	if nodeCounters then
		local nodeFlavor = nodeCounters.getChild("flavor");
		if nodeFlavor then
			local sFlavor = nodeFlavor.getValue();
			if sFlavor ~= "" and sFlavor ~= "-" then
				local nodeNew = nodeCounters.createChild();
				DB.setValue(nodeNew, "text", "string", sFlavor);
			end
			nodeFlavor.delete();
		end

		local nodeList = nodeCounters.getChild("nodes");
		if nodeList then
			for _,v in pairs(nodeList.getChildren()) do
				local nodeNew = nodeCounters.createChild();
				DB.setValue(nodeNew, "text", "string", DB.getValue(v, "text", ""));
				v.delete();
			end
			nodeList.delete();
		end
	end
	
	local nodeTriggers = nodeRecord.getChild("trigger.nodes");
	local nodePowers = nodeRecord.createChild("powers");
	if nodeTriggers and nodePowers then
		local aTriggerChildren = nodeTriggers.getChildren();
		local aOrderedTriggerKeys = {};
		for k in pairs(aTriggerChildren) do
			table.insert(aOrderedTriggerKeys, k);
		end
		table.sort(aOrderedTriggerKeys);
		
		local aPowerChildren = nodePowers.getChildren();
		local aOrderedPowerKeys = {};
		for k in pairs(nodePowers.getChildren()) do
			table.insert(aOrderedPowerKeys, k);
		end
		table.sort(aOrderedPowerKeys);
		
		local nodePower = nil;
		for kOrder,kTriggerNode in ipairs(aOrderedTriggerKeys) do
			local nodeTrigger = aTriggerChildren[kTriggerNode];
			local sText = DB.getValue(nodeTrigger, "text", "");

			local nodeMatchPower = aPowerChildren[aOrderedPowerKeys[kOrder]];
			if nodeMatchPower then
				nodePower = nodeMatchPower;
			end
			if not nodePower then
				nodePower = nodePowers.createChild();
			end
			
			local sNewDesc = "Trigger: " .. sText;
			local sDesc = DB.getValue(nodePower, "shortdescription", "");
			if sDesc ~= "" then
				sNewDesc = sNewDesc .. "\r" .. sDesc;
			end
			DB.setValue(nodePower, "shortdescription", "string", sNewDesc);
		end
	
		nodeTriggers.getParent().delete();
	end

	local nodeSaves = nodeRecord.getChild("saves");
	if nodeSaves then
		local nSaves = tonumber(nodeSaves.getValue()) or 0;
		DB.setValue(nodeRecord, "save", "number", nSaves);
		nodeSaves.delete();
	end

	local nodeAP = nodeRecord.getChild("actionpoints");
	if nodeAP then
		local nAP = tonumber(nodeAP.getValue()) or 0;
		DB.setValue(nodeRecord, "ap", "number", nAP);
		nodeAP.delete();
	end

	local nodeSenses = nodeRecord.getChild("senses");
	if nodeSenses then
		local sSenses = nodeSenses.getValue();
		local nStart, nEnd, sVal = sSenses:find("[Pp]erception ([%+%-]%d+),? ?");
		if sVal then
			sSenses = sSenses:sub(1, nStart - 1) .. sSenses:sub(nEnd + 1);
			local nPerception = tonumber(sVal) or 0;

			DB.setValue(nodeRecord, "perceptionval", "number", nPerception);
			DB.setValue(nodeRecord, "senses", "string", sSenses);
		end
	end
end

function checkNPC(nodeRecord)
	local bMigrate = false;
	if nodeRecord.getChild("perception") then
		bMigrate = true;
	elseif nodeRecord.getChild("addskills") then
		bMigrate = true;
	elseif nodeRecord.getChild("countermeasures.flavor") or nodeRecord.getChild("countermeasures.nodes") then
		bMigrate = true;
	elseif nodeRecord.getChild("trigger.nodes") then
		bMigrate = true;
	elseif nodeRecord.getChild("saves") or nodeRecord.getChild("actionpoints") then
		bMigrate = true;
	end
	
	if bMigrate then
		if nodeRecord.isReadOnly() then
			local msg = {font = "systemfont"};
			msg.text = "Unable to migrate read-only NPC: " .. DB.getValue(nodeRecord, "name", "");
			Comm.addChatMessage(msg);
		else
			migrateNPC21(nodeRecord);
		end
	end
end

function convertNPCs21(nodeRoot)
	for _, nodeRecord in pairs(DB.getChildren(ndoeRoot, "npc")) do
		migrateNPC21(nodeRecord);
	end
end

function migrateItem21(nodeItem)
	local nodeQuirkList = nodeItem.getChild("quirks");
	local nodePropList = nodeItem.createChild("props");
	if nodeQuirkList and nodePropList then
		for _, nodeQuirk in pairs(nodeQuirkList.getChildren()) do
			local nodeProp = nodePropList.createChild();
			if nodeProp then
				DB.setValue(nodeProp, "shortdescription", "string", DB.getValue(nodeQuirk, "shortdescription", ""));
				nodeQuirk.delete();
			end
		end
		nodeQuirkList.delete();
	end
end

function checkItem(nodeItem)
	local bMigrate = false;
	if nodeItem.getChild("quirks") then
		bMigrate = true;
	end
	
	if bMigrate then
		if nodeItem.isReadOnly() then
			Comm.addChatMessage("Unable to migrate read-only item: " .. DB.getValue(nodeItem, "name", ""));
		else
			migrateItem21(nodeItem);
		end
	end
end

function convertItems21(nodeRoot)
	for _, nodeItem in pairs(DB.getChildren(nodeRoot, "item")) do
		migrateItem21(nodeItem);
	end
	
	for _, nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		local nodeInventoryList = nodeChar.getChild("inventorylist");
		if nodeInventoryList then
			for _, nodeItem in pairs(nodeInventoryList.getChildren()) do
				migrateItem21(nodeItem);
			end
		end
	end
end

function migrateEffect21(nodeEffect)
	local sApply = DB.getValue(nodeEffect, "apply", "");
	if sApply == "once" then
		DB.setValue(nodeEffect, "apply", "string", "roll");
	end
end

function convertEffects21(nodeRoot)
	for _,nodeEntry in pairs(DB.getChildren(nodeRoot, "combattracker")) do
		for _,nodeEffect in pairs(DB.getChildren(nodeEntry, "effects")) do
			migrateEffect21(nodeEffect);
		end
	end

	for _,nodeEffect in pairs(DB.getChildren(nodeRoot, "effects")) do
		migrateEffect21(nodeEffect);
	end

	for _, nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		for _, nodePowerType in pairs(DB.getChildren(nodeChar, "powers")) do
			for _, nodePower in pairs(DB.getChildren(nodePowerType, "power")) do
				for _, nodeAbility in pairs(DB.getChildren(nodePower, "abilities")) do
					if DB.getValue(nodeAbility, "type", "") == "effect" then
						migrateEffect21(nodeAbility);
					end
				end
			end
		end
	end
end

function convertOptions21(nodeRoot)
	local nodeOptions = nodeRoot.getChild("options");
	if nodeOptions then
		local nodeOpt = nodeOptions.getChild("SHPH");
		if nodeOpt then
			if nodeOpt.getValue() == "on" then
				nodeOpt.setValue("pc");
			end
		end
	end
end

function convertTables21(nodeRoot)
	for _,v in pairs(DB.getChildren(nodeRoot, "tables")) do
		for _,y in pairs(DB.getChildren(v, "tableitems")) do
			local nodeFromRange = y.getChild("fromrange");
			if nodeFromRange and nodeFromRange.getType() ~= "number" then
				local nFromRange = tonumber(nodeFromRange.getValue()) or 0;
				nodeFromRange.delete();
				
				DB.setValue(y, "fromrange", "number", nFromRange);
			end
			
			local nodeToRange = y.getChild("torange");
			if nodeToRange and nodeToRange.getType() ~= "number" then
				local nToRange = tonumber(nodeToRange.getValue()) or 0;
				nodeToRange.delete();
				
				DB.setValue(y, "torange", "number", nToRange);
			end
			
			local nodeResult = y.getChild("result");
			if nodeResult then
				local sResult = nodeResult.getValue();
				
				local nodeResults = y.createChild("results");
				if nodeResults then
					local nodeNewResult = nodeResults.createChild();
					DB.setValue(nodeNewResult, "result", "string", sResult);
					
					nodeResult.delete();
				end
			end
		end
	end
end

function convertOptions20(nodeRoot)
	local nodeOptions = nodeRoot.getChild("options");
	if nodeOptions then
		local bEnableDrops = false;
		
		local nodeOpt = nodeOptions.getChild("PATK");
		if nodeOpt then
			if nodeOpt.getValue() == "on" then
				bEnableDrops = true;
			end
		end
		
		nodeOpt = nodeOptions.getChild("PDMG");
		if nodeOpt then
			if nodeOpt.getValue() == "on" then
				bEnableDrops = true;
			end
		end
		
		nodeOpt = nodeOptions.getChild("PEFF");
		if nodeOpt then
			if nodeOpt.getValue() == "on" then
				bEnableDrops = true;
			end
		end
		
		if bEnableDrops then
			nodeOpt = nodeOptions.createChild("PDRP", "string");
			if nodeOpt then
				nodeOpt.setValue("on");
			end
		end
	end
end

function convertNPCPowerDice(nodeRoot)
	for _,nodeNPC in pairs(DB.getChildren(nodeRoot, "npc")) do
		for _,nodePower in pairs(DB.getChildren(nodeNPC, "powers")) do
			local aDice = DB.getValue(nodePower, "dice", {});
			if #aDice > 0 then
				NPCCommon.applyDiceToPower(nodePower, aDice);
			end
			local nodeDice = nodePower.getChild("dice");
			if nodeDice then
				nodeDice.delete();
			end
		end
	end
end

function convertSkillTrackerResults(nodeRoot)
	for _,nodeSkill in pairs(DB.getChildren(nodeRoot, "skillchallenge.skills")) do
		for _,nodeRoll in pairs(DB.getChildren(nodeSkill, "rolls")) do
			local nSuccess = DB.getValue(nodeRoll, "success", 0);
			if nSuccess == 0 then
				DB.setValue(nodeRoll, "result", "string", "success");
			else
				DB.setValue(nodeRoll, "result", "string", "failure");
			end
		end
	end
end

function convertCTAtkField(nodeRoot)
	for _,nodeCTEntry in pairs(DB.getChildren(nodeRoot, "combattracker")) do
		local sAttack = DB.getValue(nodeCTEntry, "atk", "");
		local aAttacks = StringManager.split(sAttack, ";\r");
		if #aAttacks > 0 then
			local nodeAttacks = nodeCTEntry.createChild("attacks");
			if nodeAttacks then
				for _,v in pairs(aAttacks) do
					local nodeAttack = nodeAttacks.createChild();
					DB.setValue(nodeAttack, "value", "string", v);
				end
			end
		end
	end
end

function migrateEffect16(nodeEffect)
	local sEffect = DB.getValue(nodeEffect, "label", "");

	local aNewEffectComps = {};
	local aEffectComps = EffectsManager.parseEffect(sEffect);
	for _, rComp in pairs(aEffectComps) do
		if rComp.type == "DMG" then
			rComp.type = "DMGO";
		elseif rComp.type == "ATKA" then
			rComp.type = "ATK";
		elseif rComp.type == "ATKM" then
			rComp.type = "ATK";
			table.insert(rComp.remainder, "melee");
		elseif rComp.type == "ATKR" then
			rComp.type = "ATK";
			table.insert(rComp.remainder, "ranged");
		elseif rComp.type == "DMGA" then
			rComp.type = "DMG";
		elseif rComp.type == "DMGM" then
			rComp.type = "DMG";
			table.insert(rComp.remainder, "melee");
		elseif rComp.type == "DMGR" then
			rComp.type = "DMG";
			table.insert(rComp.remainder, "ranged");
		end

		local aNewComp = rComp.remainder;
		if (#(rComp.dice) > 0) or (rComp.mod ~= 0) then
			table.insert(aNewComp, 1, StringManager.convertDiceToString(rComp.dice, rComp.mod));
		end
		if rComp.type ~= "" then
			table.insert(aNewComp, 1, rComp.type .. ":");
		end
		table.insert(aNewEffectComps, table.concat(aNewComp, " "));
	end

	DB.setValue(nodeEffect, "label", "string", table.concat(aNewEffectComps, "; "));
end

function convertEffects16(nodeRoot)
	for _,nodeEntry in pairs(DB.getChildren(nodeRoot, "combattracker")) do
		for _,nodeEffect in pairs(DB.getChildren(nodeEntry, "effects")) do
			migrateEffect16(nodeEffect);
		end
	end

	for _,nodeEffect in pairs(DB.getChildren(nodeRoot, "effects")) do
		migrateEffect16(nodeEffect);
	end

	for _, nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		for _, nodePowerType in pairs(DB.getChildren(nodeChar, "powers")) do
			for _, nodePower in pairs(DB.getChildren(nodePowerType, "power")) do
				for _, nodeAbility in pairs(DB.getChildren(nodePower, "abilities")) do
					if DB.getValue(nodeAbility, "type", "") == "effect" then
						migrateEffect16(nodeAbility);
					end
				end
			end
		end
	end
end

function convertCharacterPowerAbilities(nodeRoot)
	for _,nodeChar in pairs(DB.getChildren(nodeRoot, "charsheet")) do
		for _,nodePowerType in pairs(DB.getChildren(nodeChar, "powers")) do
			for _,nodePower in pairs(DB.getChildren(nodePowerType, "power")) do
				local nodePowerAbilityList = nodePower.createChild("abilities");
				if nodePowerAbilityList then
					local nAbilityOrder = 1;

					local nodePowerAttackList = nodePower.getChild("attacks");
					if nodePowerAttackList then
						for _, nodePowerAttack in pairs(nodePowerAttackList.getChildren()) do
							local bCopyFlag = false;
							if (DB.getValue(nodePowerAttack, "attackstat", "") ~= "") or
									(DB.getValue(nodePowerAttack, "attackstatmodifier", 0) ~= 0) or
									(DB.getValue(nodePowerAttack, "attackdef", "") ~= "") or
									(DB.getValue(nodePowerAttack, "damageweaponmult", 0) ~= 0) or
									(DB.getValue(nodePowerAttack, "damagestat", "") ~= "") or
									(DB.getValue(nodePowerAttack, "damagestat2", "") ~= "") or
									(DB.getValue(nodePowerAttack, "damagestatmodifier", 0) ~= 0) or
									(DB.getValue(nodePowerAttack, "damagetype", "") ~= "") then
								bCopyFlag = true;
							else
								local nodeDice = nodePowerAttack.getChild("damagebasicdice");
								if nodeDice then
									local aDice = nodeDice.getValue();
									if aDice and #aDice > 0 then
										bCopyFlag = true;
									end
								end
							end

							if bCopyFlag then
								local nodePowerAbility = nodePowerAbilityList.createChild();
								DB.copyNode(nodePowerAttack, nodePowerAbility);

								DB.setValue(nodePowerAbility, "order", "number", nAbilityOrder);
								nAbilityOrder = nAbilityOrder + 1;
								DB.setValue(nodePowerAbility, "type", "string", "attack");
							end
						end

						nodePowerAttackList.delete();
					end
					local nodePowerEffectList = nodePower.getChild("effects");
					if nodePowerEffectList then
						for _, nodePowerEffect in pairs(nodePowerEffectList.getChildren()) do
							local bCopyFlag = false;
							if DB.getValue(nodePowerEffect, "label", "") ~= "" then
								bCopyFlag = true;
							end

							if bCopyFlag then
								local nodePowerAbility = nodePowerAbilityList.createChild();
								DB.copyNode(nodePowerEffect, nodePowerAbility);

								DB.setValue(nodePowerAbility, "order", "number", nAbilityOrder);
								nAbilityOrder = nAbilityOrder + 1;
								DB.setValue(nodePowerAbility, "type", "string", "effect");
							end
						end

						nodePowerEffectList.delete();
					end
				end
			end
		end
	end
end