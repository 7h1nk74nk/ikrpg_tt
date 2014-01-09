-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sActiveCT = "";
OOB_MSGTYPE_ENDTURN = "endturn";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ENDTURN, handleEndTurn);
end

--
-- TURN FUNCTIONS
--

function handleEndTurn(msgOOB)
	local rActor = ActorManager.getActor("ct", getActiveCT());
	if rActor and rActor.sType == "pc" and rActor.nodeCreature then
		if rActor.nodeCreature.getOwner() == msgOOB.user then
			nextActor();
		end
	end
end

function notifyEndTurn()
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_ENDTURN;
	msgOOB.user = User.getUsername();

	Comm.deliverOOBMessage(msgOOB, "");
end

-- NOTE: Lua sort function expects the opposite boolean value compared to built-in FG sorting
function sortfunc(node1, node2)
	local nValue1 = DB.getValue(node1, "initresult", 0);
	local nValue2 = DB.getValue(node2, "initresult", 0);
	if nValue1 ~= nValue2 then
		return nValue1 > nValue2;
	end
	
	nValue1 = DB.getValue(node1, "init", 0);
	nValue2 = DB.getValue(node2, "init", 0);
	if nValue1 ~= nValue2 then
		return nValue1 > nValue2;
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return node1.getNodeName() < node2.getNodeName();
end

function requestActivation(nodeEntry, bSkipBell)
	-- De-activate all other entries
	for _,vChild in pairs(DB.getChildren("combattracker")) do
		DB.setValue(vChild, "active", "number", 0);
	end
	
	-- Set active flag
	DB.setValue(nodeEntry, "active", "number", 1);

	-- Handle beginning of turn changes
	DB.setValue(nodeEntry, "immediate_check", "number", 0);
	
	-- Get key information
	local sType = DB.getValue(nodeEntry, "type", "");
	local sName = DB.getValue(nodeEntry, "name", "");
	
	-- Handle turn notification
	local msg = {font = "narratorfont", icon = "indicator_flag"};
	msg.text = "[TURN] " .. sName;
	if OptionsManager.isOption("RSHE", "on") then
		local sEffects = EffectsManager.getEffectsString(nodeEntry, true);
		if sEffects ~= "" then
			msg.text = msg.text .. " - [" .. sEffects .. "]";
		end
	end
	if sType == "pc" then
		Comm.deliverChatMessage(msg);
		
		if not bSkipBell and OptionsManager.isOption("RING", "on") then
			local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
			if sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					local sOwner = nodePC.getOwner();
					if sOwner then
						User.ringBell(sOwner);
					end
				end
			end
		end
	else
		if (DB.getValue(nodeEntry, "friendfoe", "") == "friend") or (DB.getValue(nodeEntry, "show_npc", 0) == 1) then
			Comm.deliverChatMessage(msg);
		else
			msg.text = "[GM] " .. msg.text;
			Comm.addChatMessage(msg);
		end
	end

	-- Handle GM identity updates (based on option)
	if sActiveCT ~= "" then
		GmIdentityManager.removeIdentity(sActiveCT);
		sActiveCT = "";
	end
	if OptionsManager.isOption("CTAV", "on") then
		if sType == "pc" or sName == "" then
			GmIdentityManager.activateGMIdentity();
		else
			if GmIdentityManager.existsIdentity(sName) then
				GmIdentityManager.setCurrent(sName);
			else
				sActiveCT = sName;
				GmIdentityManager.addIdentity(sName);
			end
		end
	end
end

function nextActor(bSkipBell)
	local nodeActive = getActiveCT();
	
	--- Process dying state for currently active CT (PC only)
	if nodeActive then
		if OptionsManager.isOption("ESAV", "on") then
			local rActor = ActorManager.getActor("ct", nodeActive);
			if rActor.sType == "pc" then
				local nPercentWounded = ActorManager.getPercentWounded("ct", nodeActive);
				if nPercentWounded >= 1 then
					ActionSave.performAutoRoll(rActor, false, true);
				end
			end
		end
	end
	
	-- Determine the next actor
	local nodeNext = nil;
	local nodeTracker = DB.findNode("combattracker");
	if nodeTracker then
		local aEntries = {};
		for _,vChild in pairs(nodeTracker.getChildren()) do
			table.insert(aEntries, vChild);
		end
		
		if #aEntries > 0 then
			table.sort(aEntries, sortfunc);
		
			if nodeActive then
				for i = 1,#aEntries do
					if aEntries[i] == nodeActive then
						nodeNext = aEntries[i+1];
					end
				end
			else
				nodeNext = aEntries[1];
			end
		end
	end

	-- LOOK FOR ACTIVE NODE
	-- Find the next actor.  If no next actor, then start the next round
	if nodeNext then
		if nodeActive then
			EffectsManager.processEffects(nodeTracker, nodeActive, nodeNext);
		else
			EffectsManager.processEffects(nodeTracker, nil, nodeNext);
		end
		requestActivation(nodeNext, bSkipBell);
	else
		nextRound(1);
	end
end

function nextRound(nRounds)
	local nodeTracker = DB.findNode("combattracker");
	local nodeActive = getActiveCT();

	-- IF ACTIVE ACTOR, THEN PROCESS EFFECTS
	local nStartCounter = 1;
	if nodeActive then
		EffectsManager.processEffects(nodeTracker, nodeActive);
		DB.setValue(nodeActive, "active", "number", 0);
		if sActiveCT ~= "" then
			GmIdentityManager.removeIdentity(sActiveCT);
			sActiveCT = "";
		end
		nStartCounter = nStartCounter + 1;
	end
	for i = nStartCounter, nRounds do
		EffectsManager.processEffects(nodeTracker, nil, nil);
	end

	-- ADVANCE ROUND COUNTER
	local nCurrent = 0;
	local nodeRound = DB.findNode("combattracker_props.round");
	if nodeRound then
		nCurrent = nodeRound.getValue() + nRounds;
		nodeRound.setValue(nCurrent);
	end
	
	-- ANNOUNCE NEW ROUND
	local msg = {font = "narratorfont", icon = "indicator_flag"};
	msg.text = "[ROUND " .. nCurrent .. "]";
	Comm.deliverChatMessage(msg);
	
	-- CHECK OPTION TO SEE IF WE SHOULD GO AHEAD AND MOVE TO FIRST ROUND
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if nodeTracker.getChildCount() > 0 then
			nextActor(bSkipBell);
		end
	end
end

--
--	GENERAL
--

function getActiveInit()
	local nActiveInit = nil;
	
	local nodeActive = getActiveCT();
	if nodeActive then
		nActiveInit = DB.getValue(nodeActive, "initresult", 0);
	end
	
	return nActiveInit;
end

function getActiveCT()
	for _,v in pairs(DB.getChildren("combattracker")) do
		if DB.getValue(v, "active", 0) == 1 then
			return v;
		end
	end
	return nil;
end

function getCTFromNode(varNode)
	-- SETUP
	local sNode = "";
	if type(varNode) == "string" then
		sNode = varNode;
	elseif type(varNode) == "databasenode" then
		sNode = varNode.getNodeName();
	else
		return nil;
	end
	
	-- FIND TRACKER NODE
	local nodeTracker = DB.findNode("combattracker");
	if not nodeTracker then
		return nil;
	end

	-- Check for exact CT match
	for _,v in pairs(nodeTracker.getChildren()) do
		if v.getNodeName() == sNode then
			return v;
		end
	end

	-- Otherwise, check for link match
	for _,v in pairs(nodeTracker.getChildren()) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sNode then
			return v;
		end
	end

	return nil;	
end

function getCTFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = nodeContainer.getNodeName();
	
	for _,v in pairs(DB.getChildren("combattracker")) do
		local sCTContainerName = DB.getValue(v, "tokenrefnode", "");
		local nCTId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sCTContainerName == sContainerNode) and (nCTId == nId) then
			return v;
		end
	end
	return nil;
end

function getCTFromToken(token)
	-- GET TOKEN CONTAINER AND ID
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getCTFromTokenRef(nodeContainer, nID);
end


--
-- DROP HANDLING
--

function onDrop(nodetype, nodename, draginfo)
	local rSource, rTarget = ActorManager.getDropActors(nodetype, nodename, draginfo);
	if rTarget then
		local sDragType = draginfo.getType();

		-- Faction changes
		if sDragType == "combattrackerff" then
			if User.isHost() then
				DB.setValue(rTarget.nodeCT, "friendfoe", "string", draginfo.getStringData());
				return true;
			end

		-- Targeting
		elseif sDragType == "targeting" then
			if User.isHost() then
				onTargetingDrop(rSource, rTarget, draginfo);
				return true;
			end

		-- Actions
		elseif StringManager.contains(DataCommon.targetactions, sDragType) then
			ActionsManager.handleActionDrop(draginfo, rTarget);
			return true;

		-- Potential actions
		elseif sDragType == "number" then
			onNumberDrop(rSource, rTarget, draginfo);
			return true;
		end
	end
end

function onTargetingDrop(rSource, rTarget, draginfo)
	if rTarget.nodeCT then
		-- ADD CREATURE TARGET
		if rSource then
			if rSource.nodeCT then
				TargetingManager.addTarget("host", rSource.sCTNode, rTarget.sCTNode);
			end

		-- ADD EFFECT TARGET
		else
			local sRefClass, sRefNode = draginfo.getShortcutData();
			if sRefClass and sRefNode then
				if sRefClass == "combattracker_effect" then
					TargetingManager.addTarget("host", sRefNode, rTarget.sCTNode);
				end
			end
		end
	end
end

function onNumberDrop(rSource, rTarget, draginfo)
	-- CHECK FOR ACTION RESULTS
	local sType = nil;
	local sDescription = draginfo.getDescription();
	if sDescription:match("%[ATTACK") then
		sType = "attack";
	elseif sDescription:match("%[DAMAGE") then
		sType = "damage";
	elseif sDescription:match("%[HEAL") then
		sType = "heal";
	elseif sDescription:match("%[EFFECT") then
		sType = "effect";
	elseif sDescription:match("%[SAVE") then
		sType = "save";
	end
	
	-- IF ACTION, THEN RESOLVE IT AGAINST THIS TARGET
	if sType then
		local rRoll = {};
		rRoll.sType = sType;
		rRoll.sDesc = sDescription;
		rRoll.aDice = {};
		rRoll.nMod = draginfo.getNumberData();
		
		local rCustom = nil;
		if sType == "damage" then
			rRoll.sDesc = rRoll.sDesc .. " [MIN OVERRIDE]";
		elseif sType == "save" then
			aCustom = draginfo.getCustomData();
			if aCustom and aCustom["effect"] then
				rCustom = {};
				table.insert(rCustom, { sRecord = aCustom["effect"] });
			end
		end
		
		ActionsManager.resolveAction(rSource, rTarget, rRoll, rCustom);
	end
end

--
-- PARSE CT ATTACK LINE
--

function parseCTAttackLine(sLine)
	-- SETUP
	local rPower = nil;
	
	local nIntroStart, nIntroEnd, sName = string.find(sLine, "([^%(%[]*)[%(%[]?");
	if nIntroStart then
		rPower = {};
		local sTrimmedName, nNameStart, nNameEnd = StringManager.trim(sName);
		rPower.name = table.concat(StringManager.parseWords(sTrimmedName), " ");
		rPower.range = (string.match(sLine, "%[([MRAC][MRAC]?)%]")) or "";
		rPower.aAbilities = {};

		local rAbilityName = {};
		rAbilityName.sType = "name";
		rAbilityName.nStart = nNameStart;
		rAbilityName.nEnd = nNameEnd + 1;
		rAbilityName.name = rPower.name;
		table.insert(rPower.aAbilities, rAbilityName);
		
		nIndex = nIntroEnd;
		
		local nAttackStart, nAttackEnd, sAttackBonus, sAttackDefense = string.find(sLine, "%(([%+%-]%d+) vs.? (%a*)%)", nIndex);
		if nAttackStart then
			local rAbilityAttack = {};
			rAbilityAttack.sType = "attack";
			rAbilityAttack.nStart = nAttackStart + 1;
			rAbilityAttack.nEnd = nAttackEnd;
			rAbilityAttack.name = rPower.name;
			rAbilityAttack.range = rPower.range;
			rAbilityAttack.defense = ActorManager.getDefenseInternal(sAttackDefense);
			rAbilityAttack.clauses = {{ stat = {}, mod = tonumber(sAttackBonus) or 0 }};
			table.insert(rPower.aAbilities, rAbilityAttack);
			
			nIndex = nAttackEnd + 1;
		end
		
		local nDamageStart, nDamageEnd, sDamage, sDamageType = string.find(sLine, "%(([d%+%-%d%s]*%d)%s?([%a,]*)%)", nIndex);
		if nDamageStart then
			local rAbilityDamage = {};
			rAbilityDamage.sType = "damage";
			rAbilityDamage.nStart = nDamageStart + 1;
			rAbilityDamage.nEnd = nDamageEnd;
			rAbilityDamage.name = rPower.name;
			rAbilityDamage.range = rPower.range;
			rAbilityDamage.clauses = {{ stat = {}, basemult = 0, dicestr = sDamage, critdicestr = "", subtype = sDamageType }};
			table.insert(rPower.aAbilities, rAbilityDamage);
			
			nIndex = nDamageEnd + 1;
		end
		
		local nUsageStart, nUsageEnd, sUsage = string.find(sLine, "%[(USED)%]", nIndex);
		if not nUsageStart then
			nUsageStart, nUsageEnd, sUsage = string.find(sLine, "%[(R:%d)%]", nIndex);
		end
		if not nUsageStart then
			nUsageStart, nUsageEnd, sUsage = string.find(sLine, "%[([de])%]", nIndex);
		end
		if nUsageStart then
			local rAbilityUsage = {};
			rAbilityUsage.sType = "usage";
			rAbilityUsage.nStart = nUsageStart + 1;
			rAbilityUsage.nEnd = nUsageEnd;
			table.insert(rPower.aAbilities, rAbilityUsage);
			
			rPower.sUsage = sUsage;
			rPower.nUsageStart = rAbilityUsage.nStart;
			rPower.nUsageEnd = rAbilityUsage.nEnd;
			
			nIndex = nUsageEnd + 1;
		end
		
		local nAuraStart, nAuraEnd, sAura = string.find(sLine, "%[(AURA:%d+)%]", nIndex);
		if nAuraStart then
			local rAbilityAura = {};
			rAbilityAura.sType = "aura";
			rAbilityAura.nStart = nAuraStart + 1;
			rAbilityAura.nEnd = nAuraEnd;
			rAbilityAura.val = tonumber(string.sub(sAura, 6)) or 0;
			table.insert(rPower.aAbilities, rAbilityAura);
			
			nIndex = nAuraEnd + 1;
		end
	end
	
	return rPower;
end

--
-- RESET FUNCTIONS
--

function resetInit()
	-- De-activate all entries
	for _,vChild in pairs(DB.getChildren("combattracker")) do
		DB.setValue(vChild, "active", "number", 0);
		DB.setValue(vChild, "initresult", "number", 0);
		DB.setValue(vChild, "immediate_check", "number", 0);
	end

	-- Clear GM identity additions (based on option)
	if sActiveCT ~= "" then
		GmIdentityManager.removeIdentity(sActiveCT);
		sActiveCT = "";
	end

	-- Reset the round counter
	DB.setValue("combattracker_props.round", "number", 1);
end

function resetEffects()
	for _,vChild in pairs(DB.getChildren("combattracker")) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				vEffect.delete();
			end
			nodeEffects.createChild();
		end
	end
end

function clearExpiringEffects()
	for _,vChild in pairs(DB.getChildren("combattracker")) do
		local nodeEffects = vChild.getChild("effects");
		if nodeEffects then
			for _, vEffect in pairs(nodeEffects.getChildren()) do
				local sLabel = DB.getValue(vEffect, "label", "");
				local sExpire = DB.getValue(vEffect, "expiration", "");
				local sApply = DB.getValue(vEffect, "apply", "");
				
				local bDelete = false;
				if sExpire ~= "" or sApply ~= "" or sLabel == "" then
					bDelete = true;
				else
					local aEffectComps = EffectsManager.parseEffect(sLabel);
					for i = 1, #aEffectComps do
						if aEffectComps[i].type == "RCHG" then
							bDelete = true;
						end
					end
				end
				if bDelete then
					vEffect.delete();
				end
			end
			
			if nodeEffects.getChildCount() == 0 then
				nodeEffects.createChild();
			end
		end
	end
end

function rest(bExtended, bMilestone)
	resetInit();
	clearExpiringEffects();

	for _,vChild in pairs(DB.getChildren("combattracker")) do
		if DB.getValue(vChild, "type", "") == "pc" then
			local sClass, sRecord = DB.getValue(vChild, "link", "", "");
			if sRecord ~= "" then
				local nodePC = DB.findNode(sRecord);
				if nodePC then
					CharManager.rest(nodePC, bExtended, bMilestone);
				end
			end
		end
	end
end

function stripCreatureNumber(s)
	local nStarts, _, sNumber = string.find(s, " ?(%d+)$");
	if nStarts then
		return string.sub(s, 1, nStarts - 1), sNumber;
	end
	return s;
end

function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	
	-- Get any effect modifiers
	local rActor = ActorManager.getActor("ct", nodeEntry);
	local aEffectDice, nEffectBonus = EffectsManager.getEffectsBonus(rActor, "INIT");
	nInit = nInit + StringManager.evalDice(aEffectDice, nEffectBonus);
	
	-- For PCs, we always roll unique initiative
	if DB.getValue(nodeEntry, "type", "") == "pc" then
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
	
	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end

	-- For NPCs with group option enabled
	
	-- Get the entry's database node name and creature name
	local sStripName = stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
		
	-- Iterate through list looking for other creature's with same name
	local nLastInit = nil;
	for _,vChild in pairs(DB.getChildren("combattracker")) do
		if vChild.getName() ~= nodeEntry.getName() then
			local sTemp = stripCreatureNumber(DB.getValue(vChild, "name", ""));
			if sTemp == sStripName then
				local nChildInit = DB.getValue(vChild, "initresult", 0);
				if nChildInit ~= -10000 then
					nLastInit = nChildInit;
				end
			end
		end
	end
	
	-- If we found similar creatures, then match the initiative of the last one found
	if nLastInit then
		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
	else
		local nInitResult = math.random(20) + nInit;
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
	end
end

function rollInit(sType)
	local nodeTracker = DB.findNode("combattracker");
	if nodeTracker then
		for _, vChild in pairs(nodeTracker.getChildren()) do
			if not sType or DB.getValue(vChild, "type", "") == sType then
				DB.setValue(vChild, "initresult", "number", -10000);
			end
		end

		for _, vChild in pairs(nodeTracker.getChildren()) do
			if not sType or DB.getValue(vChild, "type", "") == sType then
				rollEntryInit(vChild);
			end
		end
	end
end

--
-- ADD FUNCTIONS
--

function addPc(nodePC)
	-- Parameter validation
	if not nodePC then
		return;
	end

	-- Create a new combat tracker window
	local nodeTracker = DB.createNode("combattracker");
	if not nodeTracker then
		return;
	end
	local nodeEntry = nodeTracker.createChild();
	if not nodeEntry then
		return;
	end
	
	-- Set link and type to get linked fields to prepopulate
	DB.setValue(nodeEntry, "link", "windowreference", "charsheet", nodePC.getNodeName());
	DB.setValue(nodeEntry, "type", "string", "pc");

	-- Set remaining CT specific fields
	DB.setValue(nodeEntry, "token", "token", DB.getValue(nodePC, "combattoken", nil));
	DB.setValue(nodeEntry, "friendfoe", "string", "friend");
	
	-- Rebuild the targeting information, since we have a new PC
	TargetingManager.rebuildClientTargeting();
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

	return true;
end

function addBattle(nodeBattle)
	-- Cycle through the NPC list, and add them to the tracker
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, "npclist")) do
		-- Get link database node
		local nodeNPC = nil;
		local _, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			nodeNPC = DB.findNode(sRecord);
		end
		local sName = DB.getValue(vNPCItem, "name", "");
		
		if nodeNPC then
			local aPlacement = {};
			for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
				local rPlacement = {};
				local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
				rPlacement.imagelink = sRecord;
				rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
				rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
				table.insert(aPlacement, rPlacement);
			end
			
			local nCount = DB.getValue(vNPCItem, "count", 0);
			local nLevelAdj = DB.getValue(vNPCItem, "leveladj", 0);
			for i = 1, nCount do
				local nodeEntry = addNpc(nodeNPC, sName, nLevelAdj);
				if nodeEntry then
					local sToken = DB.getValue(vNPCItem, "token", "");
					if sToken ~= "" then
						DB.setValue(nodeEntry, "token", "token", sToken);
						
						if aPlacement[i] and aPlacement[i].imagelink ~= "" then
							local tokenAdded = Token.addToken(aPlacement[i].imagelink, sToken, aPlacement[i].imagex, aPlacement[i].imagey);
							if tokenAdded then
								linkToken(nodeEntry, tokenAdded);
							end
						end
					end
				else
					ChatManager.SystemMessage("[ERROR] Unable to add '" .. sName .. "' to CT. NPC creation failed.");
				end
			end
		else
			ChatManager.SystemMessage("[ERROR] Unable to add '" .. sName .. "' to CT. Missing data record. Check your modules.");
		end
	end
end

function randomName(sBaseName)
	local nodeTracker = DB.createNode("combattracker");
	if not nodeTracker then
		return sBaseName;
	end
	
	local aNames = {};
	for _, v in pairs(nodeTracker.getChildren()) do
		local sName = DB.getValue(v, "name", "");
		if sName ~= "" then
			table.insert(aNames, DB.getValue(v, "name", ""));
		end
	end
	
	local nRandomRange = nodeTracker.getChildCount() * 2;
	local sNewName = sBaseName;
	local bContinue = true;
	while bContinue do
		bContinue = false;
		sNewName = sBaseName .. " " .. math.random(nRandomRange);
		if StringManager.contains(aNames, sNewName) then
			bContinue = true;
		end
	end

	return sNewName;
end

function parseRegeneration(aWords, aRegenTypes)
	local bRegenBloodied = false;
	
	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "damage") then
			local j = i - 1;
			while j > 0 do
				if StringManager.isWord(aWords[j], DataCommon.dmgtypes) then
					table.insert(aRegenTypes, aWords[j]);
				elseif StringManager.isWord(aWords[j], "or") then
					-- SKIP
				else
					break;
				end
				j = j - 1;
			end
			if StringManager.isWord(aWords[i+1], "from") then
				if StringManager.isWord(aWords[i+2], "a") and StringManager.isWord(aWords[i+3], "silver") and StringManager.isWord(aWords[i+4], "weapon") then
					table.insert(aRegenTypes, "silver");
				elseif StringManager.isWord(aWords[i+2], "silver") and StringManager.isWord(aWords[i+3], "weapons") then
					table.insert(aRegenTypes, "silver");
				end
			end
		end
		if StringManager.isWord(aWords[i], "exposed") and StringManager.isWord(aWords[i+1], "to") then
			local n = i + 2;
			if StringManager.isWord(aWords[n], "direct") then
				n = n + 1;
			end
			if StringManager.isWord(aWords[n], "sunlight") then
				table.insert(aRegenTypes, "sunlight");
			end
		end
		if StringManager.isWord(aWords[i], "only") and StringManager.isWord(aWords[i+1], "while") and StringManager.isWord(aWords[i+2], "bloodied") then
			bRegenBloodied = true;
		end
	end
	
	return bRegenBloodied;
end

function addNpc(nodeNPC, sName, nLevelAdj)
	-- Parameter validation
	if not nodeNPC then
		return nil;
	end
	if not nLevelAdj then
		nLevelAdj = 0;
	end

	-- Determine the options relevant to adding NPCs
	local sOptNNPC = OptionsManager.getOption("NNPC");
	local sOptINIT = OptionsManager.getOption("INIT");
	local optHRMH = OptionsManager.getOption("HRMH");
	local optHRSH = OptionsManager.getOption("HRSH");
	local optHRID = OptionsManager.getOption("HRID");
	local optHRRD = OptionsManager.getOption("HRRD");

	-- Create a new combat tracker window
	local nodeTracker = DB.createNode("combattracker");
	if not nodeTracker then
		return nil;
	end
	local nodeEntry = nodeTracker.createChild();
	if not nodeEntry then
		return nil;
	end
	
	-- Set link and type
	DB.setValue(nodeEntry, "link", "windowreference", "npc", nodeNPC.getNodeName());
	DB.setValue(nodeEntry, "type", "string", "npc");

	-- Set token and faction
	DB.setValue(nodeEntry, "token", "token", DB.getValue(nodeNPC, "token", nil));
	DB.setValue(nodeEntry, "friendfoe", "string", "foe");

	-- Set name
	local sNameLocal = sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(nodeNPC, "name", "");
	end

	-- If multiple NPCs of same name, then figure out what initiative they go on and potentially append a number
	local nNameCount = 0;
	local nLastInit = nil;
	local nNameHigh = 0;
	if string.len(sNameLocal) > 0 then
		local aMatchesToNumber = {};
		
		for _,v in pairs(nodeTracker.getChildren()) do
			if v.getName() ~= nodeEntry.getName() then
				local sEntryName = DB.getValue(v, "name", "");
				local sTemp, sNumber = stripCreatureNumber(sEntryName);
				if sTemp == sNameLocal then
					nNameCount = nNameCount + 1;
					nLastInit = DB.getValue(v, "initresult", 0);
					
					if sNumber then
						local nNumber = tonumber(sNumber) or 0;
						if nNumber > nNameHigh then
							nNameHigh = nNumber;
						end
					else
						table.insert(aMatchesToNumber, v);
					end
				end
			end
		end
		
		for _,v in ipairs(aMatchesToNumber) do
			local sEntryName = DB.getValue(v, "name", "");
			if sOptNNPC == "append" then
				nNameHigh = nNameHigh + 1;
				DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
			elseif sOptNNPC == "random" then
				DB.setValue(v, "name", "string", randomName(sEntryName));
			end
		end
		
		if nNameCount > 0 then
			if sOptNNPC == "append" then
				nNameHigh = nNameHigh + 1;
				sNameLocal = sNameLocal .. " " .. nNameHigh;
			elseif sOptNNPC == "random" then
				sNameLocal = randomName(sNameLocal);
			end
		end
	end
	DB.setValue(nodeEntry, "name", "string", sNameLocal);
	
	-- Space/reach
	local sType = DB.getValue(nodeNPC, "type", "");
	local wordsType = StringManager.parseWords(string.lower(sType));
	local nSpace = 1;
	local nReach = 1;
	if StringManager.isWord(wordsType[1], "tiny") then
		nSpace = 1;
		nReach = 0;
	elseif StringManager.isWord(wordsType[1], "small") then
		nSpace = 1;
		nReach = 1;
	elseif StringManager.isWord(wordsType[1], "medium") then
		nSpace = 1;
		nReach = 1;
	elseif StringManager.isWord(wordsType[1], "large") then
		nSpace = 2;
		nReach = 1;
	elseif StringManager.isWord(wordsType[1], "huge") then
		nSpace = 3;
		nReach = 2;
	elseif StringManager.isWord(wordsType[1], "gargantuan") then
		nSpace = 4;
		nReach = 3;
	end
	DB.setValue(nodeEntry, "space", "number", nSpace);
	DB.setValue(nodeEntry, "reach", "number", nReach);

	-- Check for swarm
	local isSwarm = false;
	if StringManager.contains(wordsType, "swarm") then
		isSwarm = true;
	end
	
	-- Decode the level and role field
	local sLevelRole = string.lower(DB.getValue(nodeNPC, "levelrole", ""));
	local sRole = "";
	if string.match(sLevelRole, "skirmisher") then
		sRole = "skirmisher";
	elseif string.match(sLevelRole, "brute") then
		sRole = "brute";
	elseif string.match(sLevelRole, "soldier") then
		sRole = "soldier";
	elseif string.match(sLevelRole, "lurker") then
		sRole = "lurker";
	elseif string.match(sLevelRole, "controller") then
		sRole = "controller";
	elseif string.match(sLevelRole, "artillery") then
		sRole = "artillery";
	end
	
	local sRoleEnh = "";
	if string.match(sLevelRole, "minion") then
		sRoleEnh = "minion";
	elseif string.match(sLevelRole, "elite") then
		sRoleEnh = "elite";
	elseif string.match(sLevelRole, "solo") then
		sRoleEnh = "solo";
	end
	
	-- Determine the NPC level
	local nLevel = tonumber(string.match(sLevelRole, "level (%d*)")) or 0;
	nLevel = nLevel + nLevelAdj;

	-- HP
	local sHP = DB.getValue(nodeNPC, "hp", "");
	local nHP = tonumber(string.match(sHP, "(%d*)")) or 0;
	if nLevelAdj ~= 0 then
		if sRoleEnh == "minion" then
			-- Do nothing, since minions always get 1 hp
		elseif sRoleEnh == "solo" and (nLevel - nLevelAdj) > 0 then
			local con = DB.getValue(nodeNPC, "constitution", 10);
			if nLevel > 10 then
				nHP = (((nLevel + 1) * 8) + con) * 5;
			else
				nHP = (((nLevel + 1) * 8) + con) * 4;
			end
		else
			local nHPAdj = 8;
			local nHPAdjMult = 1;
			if sRole == "brute" then
				nHPAdj = 10;
			elseif sRole == "lurker" then
				nHPAdj = 6;
			elseif sRole == "artillery" then
				nHPAdj = 6;
			end
			if sRoleEnh == "elite" then
				nHPAdjMult = 2;
			elseif sRoleEnh == "solo" then
				nHPAdjMult = 4;
			end
			nHP = nHP + (nHPAdj * nHPAdjMult * nLevelAdj);
		end
	end
	if sRoleEnh == "minion" then
		if optHRMH == "levelplus" then
			nHP = nLevel + 5;
		end
	else
		if optHRSH == "quarter" then
			nHP = math.floor((nHP * 3) / 4);
		elseif optHRSH == "third" then
			nHP = math.floor((nHP * 2) / 3);
		elseif optHRSH == "half" then
			nHP = math.floor(nHP / 2);
		end
	end
	DB.setValue(nodeEntry, "hp", "number", nHP);
	
	local nHealSurges = 1;
	if nLevel > 20 then
		nHealSurges = 3;
	elseif nLevel > 10 then
		nHealSurges = 2;
	end
	DB.setValue(nodeEntry, "healsurgeremaining", "number", nHealSurges);
	
	-- Defensive properties
	DB.setValue(nodeEntry, "ac", "number", DB.getValue(nodeNPC, "ac", 0));
	DB.setValue(nodeEntry, "fortitude", "number", DB.getValue(nodeNPC, "fortitude", 0));
	DB.setValue(nodeEntry, "reflex", "number", DB.getValue(nodeNPC, "reflex", 0));
	DB.setValue(nodeEntry, "will", "number", DB.getValue(nodeNPC, "will", 0));
	
	DB.setValue(nodeEntry, "save", "number", DB.getValue(nodeNPC, "save", 0));
	
	local sSpecialDefenses = DB.getValue(nodeNPC, "specialdefenses", "");
	DB.setValue(nodeEntry, "specialdef", "string", sSpecialDefenses);
	
	-- Track automatic effects
	local aEffects = {};
	local sRegen = nil;
	local bRegenBloodied = false;
	local aRegenTypes = {};
	local bInsubstantial = false;
	
	-- Check special defenses field for possible effects
	local aSpecialClauses = StringManager.split(string.lower(sSpecialDefenses), ";", true);
	for _, sClause in pairs(aSpecialClauses) do
		local wordsClause = StringManager.parseWords(sClause);
		if StringManager.isWord(wordsClause[1], "immune") then
			for i = 2, #wordsClause do
				if StringManager.isWord(wordsClause[i], DataCommon.dmgtypes) or
						StringManager.isWord(wordsClause[i], DataCommon.immunetypes) or
						StringManager.isWord(wordsClause[i], "all") then
					table.insert(aEffects, "IMMUNE: " .. wordsClause[i]);
				end
			end
		elseif StringManager.isWord(wordsClause[1], "resist") then
			for i = 2, #wordsClause do
				if StringManager.isWord(wordsClause[i], {"insubstantial"}) then
					bInsubstantial = true;
				elseif StringManager.isNumberString(wordsClause[i]) then
					local nTemp = tonumber(wordsClause[i]) or 0;
					if nTemp > 0 then
						if StringManager.isWord(wordsClause[i+1], DataCommon.dmgtypes) then
							table.insert(aEffects, "RESIST: " .. nTemp .. " " .. wordsClause[i+1]);
						elseif StringManager.isWord(wordsClause[i+1], "all") then
							table.insert(aEffects, "RESIST: " .. nTemp);
						end
					end
				end
			end
		elseif StringManager.isWord(wordsClause[1], "vulnerable") then
			for i = 2, #wordsClause do
				if StringManager.isNumberString(wordsClause[i]) then
					local nTemp = tonumber(wordsClause[i]) or 0;
					if nTemp > 0 then
						if StringManager.isWord(wordsClause[i+1], DataCommon.dmgtypes) then
							table.insert(aEffects, "VULN: " .. nTemp .. " " .. wordsClause[i+1]);
						elseif StringManager.isWord(wordsClause[i+2], "all") then
							table.insert(aEffects, "VULN: " .. nTemp);
						elseif isSwarm and StringManager.isWord(wordsClause[i+1], "against") then
							table.insert(aEffects, "SWARM: " .. nTemp);
						end
					end
				end
			end
			if parseRegeneration(wordsClause, aRegenTypes) then
				bRegenBloodied = true;
			end
		elseif StringManager.isWord(wordsClause[1], "regeneration") then
			sRegen = wordsClause[2];
			if sRegen then
				if parseRegeneration(wordsClause, aRegenTypes) then
					bRegenBloodied = true;
				end
			end
		end
	end -- END SPECIAL DEFENSES PROCESSING

	-- Active properties
	local nInitBonus = DB.getValue(nodeNPC, "init", 0);
	DB.setValue(nodeEntry, "init", "number", nInitBonus);
	
	local sSpeed = DB.getValue(nodeNPC, "speed", "");
	local nSpeed = tonumber(string.match(sSpeed, "(%d*)")) or 0;
	DB.setValue(nodeEntry, "speed", "number", nSpeed);

	if string.match(sSpeed, "phasing") then
		table.insert(aEffects, "Phasing");
	end

	DB.setValue(nodeEntry, "actionpoints", "number", DB.getValue(nodeNPC, "ap", 0));

	local nodePowers = nodeNPC.getChild("powers");
	local nodeAttacks = nodeEntry.createChild("attacks");
	if nodePowers and nodeAttacks then
		for _,v in pairs(nodeAttacks.getChildren()) do
			v.delete();
		end
		
		local aPowers = nodePowers.getChildren();
		local aPowerKeys = {};
		for k,_ in pairs(aPowers) do
			table.insert(aPowerKeys, k);
		end
		table.sort(aPowerKeys);
		
		local aNewAttacks = {};
		local sLinkName = DB.getValue(nodeNPC, "name", "");
		for k = 1,#aPowerKeys do
			local v = aPowers[aPowerKeys[k]];
			
			if v then
				local sAttack = "";
				local nAttacks = 0;
				local nDamages = 0;
				local nHeals = 0;
				local nEffects = 0;
				local bSpecialAttack = false;
				local bSpecialDamage = false;

				-- Get the attack, damage, heal and effect clauses
				local sPower = DB.getValue(v, "shortdescription", "");
				local aAbilities = PowersManager.parsePowerDescription(sPower, sLinkName);
				for i = 1, #aAbilities do
					if aAbilities[i].type == "attack" then
						nAttacks = nAttacks + 1;
						if (nAttacks > 1) or 
								(#(aAbilities[i].clauses) ~= 1) or
								(#(aAbilities[i].clauses[1].stat) > 0) then
							bSpecialAttack = true;
						else
							local sDefense = aAbilities[i].defense;
							if sDefense == "ac" then
								sDefense = "AC";
							elseif sDefense == "reflex" then
								sDefense = "Ref";
							elseif sDefense == "will" then
								sDefense = "Will";
							elseif sDefense == "fortitude" then
								sDefense = "Fort";
							else
								sDefense = "-";
							end

							sAttack = sAttack .. string.format("(%+d vs. %s)", aAbilities[i].clauses[1].mod, sDefense);
						end
					elseif aAbilities[i].type == "damage" then
						nDamages = nDamages + 1;
						if (nDamages > 1) or 
								(#(aAbilities[i].clauses) ~= 1) or
								(#(aAbilities[i].clauses[1].stat) > 0) or 
								(aAbilities[i].clauses[1].dicestr == "") or 
								(aAbilities[i].clauses[1].basemult ~= 0) or
								(aAbilities[i].clauses[1].critdicestr ~= "") then
							bSpecialDamage = true;
						else
							local sType = "";
							if aAbilities[i].clauses[1].subtype ~= "" then
								sType = " " .. aAbilities[i].clauses[1].subtype;
							end
							
							sAttack = sAttack .. string.format("(%s%s)", aAbilities[i].clauses[1].dicestr, sType);
						end
					elseif aAbilities[i].type == "heal" then
						nHeals = nHeals + 1;
					elseif aAbilities[i].type == "effect" then
						nEffects = nEffects + 1;
					end
				end
				
				if bSpecialAttack then
					sAttack = sAttack .. "[SATK]";
				end
				if bSpecialDamage then
					sAttack = sAttack .. "[SDMG]";
				end
				if nHeals > 0 then
					sAttack = sAttack .. "[HEAL]";
				end
				if nEffects > 0 then
					sAttack = sAttack .. "[EFF]";
				end

				-- Determine the range of this power
				local sPowerType = string.lower(DB.getValue(v, "powertype", ""));
				if StringManager.contains({"m", "r", "c", "a", "mr", "mc", "ma", "rc", "ra", "ca"}, sPowerType) then
					sAttack = sAttack .. "[" .. string.upper(sPowerType) .. "]";
				end
				
				-- Determine the action required to use this power, and add a note if it is not standard
				local action = string.lower(DB.getValue(v, "action", ""));
				if action == "move" then
					sAttack = sAttack .. "[mo]";
				elseif action == "minor" then
					sAttack = sAttack .. "[mi]";
				elseif action == "reaction" or action == "immediate reaction" then
					sAttack = sAttack .. "[r]";
				elseif action == "interrupt" or action == "immediate interrupt" then
					sAttack = sAttack .. "[i]";
				elseif action == "aura" then
					local aura_range = tonumber(DB.getValue(v, "range", "")) or 0;
					if aura_range > 0 then
						sAttack = sAttack .. "[AURA:" .. aura_range .. "]";
					end
				end

				-- Determine the recharge of this power, and add a note if it is not at-will
				local recharge = string.lower(DB.getValue(v, "recharge", ""));
				if recharge == "encounter" then
					sAttack = sAttack .. "[e]";
				elseif recharge == "daily" then
					sAttack = sAttack .. "[d]";
				elseif string.sub(recharge,1,8) == "recharge" then
					sAttack = sAttack .. "[R:" .. string.sub(recharge,10,10) .. "]";
				end

				-- Add the power name
				local sPowerName = DB.getValue(v, "name", "");
				if sAttack ~= "" then
					sAttack = " " .. sAttack;
				end
				sAttack = sPowerName .. sAttack;

				if sPowerType == "m" or sPowerType == "r" or sPowerType == "c" then
					sAttack = "*" .. sAttack;
				end

				-- Add this attack to the combat tracker power string
				table.insert(aNewAttacks, sAttack);
				
				-- Special handling for threathening reach ability
				if sPowerName == "Threatening Reach" then
					local sDesc = DB.getValue(v, "shortdescription", "");
					local sReach = string.match(sDesc, "reach %((%d) squares%)");
					local nNewReach = tonumber(sReach) or 0;
					if nNewReach > nReach then
						DB.setValue(nodeEntry, "reach", "number", nNewReach);
 					end
				
				-- Special handling for regeneration ability
				elseif sPowerName == "Regeneration" then
					local sDesc = DB.getValue(v, "shortdescription", "");
					sRegen = sDesc:match("regains (%d+) hit points");
					if sRegen then
						local wordsClause = StringManager.parseWords(sDesc);
						if parseRegeneration(wordsClause, aRegenTypes) then
							bRegenBloodied = true;
						end
					end

				-- Special handling for insubstantial ability
				elseif sPowerName == "Insubstantial" then
					bInsubstantial = true;
				end
			end
		end

		if #aNewAttacks == 0 then
			nodeAttacks.createChild();
		else
			for _,v in ipairs(aNewAttacks) do
				local nodeValue = nodeAttacks.createChild();
				if nodeValue then
					DB.setValue(nodeValue, "value", "string", v);
				end
			end
		end
	end
	
	-- If the NPC has regeneration then, add an effect for it
	if sRegen and StringManager.isNumberString(sRegen) then
		sRegen = "REGEN: " .. sRegen;
		if #aRegenTypes > 0 then
			sRegen = sRegen .. " " .. table.concat(aRegenTypes, ",");
		end
		if bRegenBloodied then
			sRegen = "IF: Bloodied; " .. sRegen;
		end
		EffectsManager.addEffect("", "", nodeEntry, { sName = sRegen, nGMOnly = 1 }, false);
	end
	
	-- If the NPC is insubstantial then, add an effect for it
	if bInsubstantial then
		table.insert(aEffects, "Insubstantial");
	end
	
	-- If there is a level adjustment, then add an effect for it
	if nLevelAdj ~= 0 then
		local nDamageAdj = 0;
		if nLevelAdj > 0 then
			nDamageAdj = math.floor(nLevelAdj / 2);
		else
			nDamageAdj = math.ceil(nLevelAdj / 2);
		end
		
		local sEffect = "DEF:" .. nLevelAdj .. "; ATK:" .. nLevelAdj;
		if nDamageAdj ~= 0 then
			sEffect = sEffect .. "; DMG:" .. nDamageAdj;
		end
		EffectsManager.addEffect("", "", nodeEntry, { sName = sEffect, nGMOnly = 1 }, false);
	end
	
	-- Add house rule effects
	if optHRID == "halflevel" and sRoleEnh ~= "minion" then
		table.insert(aEffects, "DMG: " .. math.floor(nLevel / 2));
	end
	if optHRRD == "two" then
		table.insert(aEffects, "DEF: -2");
	end
	
	-- If there are any non-regen, non-leveladj effects to add, then add them
	if #aEffects > 0 then
		EffectsManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nGMOnly = 1 }, false);
	end

	-- Roll initiative and sort
	if sOptINIT == "group" then
		if nLastInit then
			DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		else
			DB.setValue(nodeEntry, "initresult", "number", math.random(20) + nInitBonus);
		end
	elseif sOptINIT == "on" then
		DB.setValue(nodeEntry, "initresult", "number", math.random(20) + nInitBonus);
	end

	return nodeEntry;
end

