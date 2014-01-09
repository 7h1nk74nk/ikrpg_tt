-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATK = "applyatk";
OOB_MSGTYPE_APPLYHRFC = "applyhrfc";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATK, handleApplyAttack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYHRFC, handleApplyHRFC);

	ActionsManager.registerActionIcon("attack", "action_attack");
	ActionsManager.registerTargetingHandler("attack", onTargeting);
	ActionsManager.registerModHandler("attack", modAttack);
	ActionsManager.registerResultHandler("attack", onAttack);
end

function handleApplyAttack(msgOOB)
	local rSource = ActorManager.getActor("ct", msgOOB.sSourceCTNode);
	
	local rTarget = ActorManager.getActor("ct", msgOOB.sTargetCTNode);
	if not rTarget then
		rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetCreatureNode);
	end
	
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyAttack(rSource, rTarget, msgOOB.sDesc, nTotal, msgOOB.sResults);
end

function notifyApplyAttack(rSource, rTarget, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYATK;
	
	msgOOB.sAttackType = sAttackType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;
	msgOOB.sTargetType = rTarget.sType;
	msgOOB.sTargetCreatureNode = rTarget.sCreatureNode;
	msgOOB.sTargetCTNode = rTarget.sCTNode;
	if rSource then
		msgOOB.sSourceCTNode = rSource.sCTNode;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyHRFC(msgOOB)
	TableManager.processTableRoll("", msgOOB.sTable);
end

function notifyApplyHRFC(sTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYHRFC;
	
	msgOOB.sTable = sTable;

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, rRolls)
	local aTargets = TargetingManager.getFullTargets(rSource);
	
	if EffectsManager.applyMarkPenalty(rSource, aTargets) then
		for _,vRoll in ipairs(rRolls) do
			vRoll.sDesc = vRoll.sDesc .. " [MARK -2]";
		end
	end
	
	if #aTargets <= 1 then
		return { aTargets };
	end
	
	if OptionsManager.isOption("RMMT", "multi") then
		for _,vRoll in ipairs(rRolls) do
			vRoll.sDesc = vRoll.sDesc .. " [MULTI]";
		end
	end
	
	local aTargeting = {};
	for _,vTarget in ipairs(aTargets) do
		table.insert(aTargeting, { vTarget });
	end
	
	return aTargeting;
end

function getRoll(rActor, rAction, rFocus)
	local rPrimary = rAction;
	if not rPrimary then
		rPrimary = rFocus;
	end
	
	-- Build basic roll
	local rRoll = {};
	rRoll.aDice = { "d6","d6" };
	rRoll.nMod = 0;
	
	-- Build the description label
	rRoll.sDesc = "[ATTACK";
	if rPrimary.order and rPrimary.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rPrimary.order;
	end
	if rPrimary.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rPrimary.range .. ")";
	end
	rRoll.sDesc = rRoll.sDesc .. "]";
	if rPrimary then
		rRoll.sDesc = rRoll.sDesc .. " " .. rPrimary.name;
		if rPrimary.defense == "def" then
			rRoll.sDesc = rRoll.sDesc .. " (vs. DEF)";
		elseif rPrimary.defense == "arm" then
			rRoll.sDesc = rRoll.sDesc .. " (vs. ARM)";
		elseif rPrimary.defense == "will" then
			rRoll.sDesc = rRoll.sDesc .. " (vs. Will)";
		else
			rRoll.sDesc = rRoll.sDesc .. " (vs. -)";
		end
	end
	
	-- Add attack stats
	if rPrimary then
		local nStatCount = 0;
		for k, v in pairs(rPrimary.clauses) do
			for k2, v2 in pairs(v.stat) do
				rRoll.nMod = rRoll.nMod + ActorManager.getAbilityBonus(rActor, v2);
				nStatCount = nStatCount + 1;
			end
		end
		
		-- IF WE ARE ADDING ABILITY MODIFIER, THEN ALSO ADD LEVEL BONUS ONCE
		if nStatCount > 0 then
			rRoll.nMod = rRoll.nMod + math.floor(ActorManager.getAbilityBonus(rActor, "LEV") / 2);
		end
	end
	
	-- Add attack modifiers
	if rAction then
		for _,v in pairs(rAction.clauses) do
			rRoll.nMod = rRoll.nMod + v.mod;
		end
	end
	if rFocus then
		for _,v in pairs(rFocus.clauses) do
			rRoll.nMod = rRoll.nMod + v.mod;
		end
	end

	-- Add creature modifier
	if rPrimary and rActor and rActor.sType == "pc" then
		if rPrimary.range == "R" then
			rRoll.nMod = rRoll.nMod + DB.getValue(rActor.nodeCreature, "attacks.ranged.misc", 0) +
				DB.getValue(rActor.nodeCreature, "attacks.ranged.temporary", 0);
		elseif rPrimary.range == "M" then
			rRoll.nMod = rRoll.nMod + DB.getValue(rActor.nodeCreature, "attacks.melee.misc", 0) +
				DB.getValue(rActor.nodeCreature, "attacks.melee.temporary", 0);
		end
	end
	
	-- Check crit range
	local nAltCritRange = 0;
	if rFocus then
		local sCritRange = string.match(rFocus.properties, "crit range (%d+)");
		nAltCritRange = tonumber(sCritRange) or 0;
		if nAltCritRange == 0 then
			if string.match(rFocus.properties, "jagged") then
				nAltCritRange = 19;
			end
		end
	end
	if nAltCritRange > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. nAltCritRange .. "]";
	end
	
	-- ADD FOCUS NAME (IF OPTION ENABLED)
	if rAction and rFocus and rFocus.name ~= "" and OptionsManager.isOption("SWPN", "on") then
		rRoll.sDesc = rRoll.sDesc .. " [USING " .. rFocus.name .. "]";
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction, rFocus)
	local rRoll = getRoll(rActor, rAction, rFocus);
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "attack", rRoll);
end

function modAttack(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	clearCritState(rSource);
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	-- Check for opportunity attack
	local bOpportunity = ModifierStack.getModifierKey("ATT_OPP") or Input.isShiftPressed();

	-- Check defense modifiers
	local bCA = ModifierStack.getModifierKey("ATT_CA");
	local bCover = ModifierStack.getModifierKey("DEF_COVER");
	local bSuperiorCover = ModifierStack.getModifierKey("DEF_SCOVER");
	local bConceal = ModifierStack.getModifierKey("DEF_CONC");
	local bTotalConceal = ModifierStack.getModifierKey("DEF_TCONC");
	
	if bOpportunity then
		table.insert(aAddDesc, "[OPPORTUNITY]");
	end
	if bSuperiorCover then
		table.insert(aAddDesc, "[SCOVER]");
	elseif bCover then
		table.insert(aAddDesc, "[COVER]");
	end
	if bTotalConceal then
		table.insert(aAddDesc, "[TCONC]");
	elseif bConceal then
		table.insert(aAddDesc, "[CONC]");
	end
	
	if rSource then
		-- Build attack filter
		local aAttackFilter = {};
		local sAttackType = string.match(rRoll.sDesc, "%[ATTACK.*%((%w+)%)%]");
		if sAttackType then
			if sAttackType == "M" then
				table.insert(aAttackFilter, "melee");
			elseif sAttackType == "R" then
				table.insert(aAttackFilter, "ranged");
			elseif sAttackType == "C" then
				table.insert(aAttackFilter, "close");
			elseif sAttackType == "A" then
				table.insert(aAttackFilter, "area");
			end
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end
	
		-- Get attack effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"ATK"}, false, aAttackFilter);
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- Get condition modifiers
		if bCA then
			bEffects = true;
			nAddMod = nAddMod + 2;
		elseif EffectsManager.hasEffect(rSource, "CA") then
			bEffects = true;
			nAddMod = nAddMod + 2;
			table.insert(aAddDesc, "[CA]");
		elseif EffectsManager.hasEffect(rSource, "Invisible") then
			bEffects = true;
			nAddMod = nAddMod + 2;
			table.insert(aAddDesc, "[CA]");
		end
		if EffectsManager.hasEffect(rSource, "Blinded") and StringManager.isWord(sAttackType, {"M", "R"}) then
			bEffects = true;
			nAddMod = nAddMod - 5;
			table.insert(aAddDesc, "[BLINDED]");
		end
		if EffectsManager.hasEffectCondition(rSource, "Prone") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end
		if EffectsManager.hasEffectCondition(rSource, "Restrained") then
			bEffects = true;
			nAddMod = nAddMod - 2;
		end

		-- Get other effect modifiers
		if EffectsManager.hasEffectCondition(rSource, "Running") then
			bEffects = true;
			nAddMod = nAddMod - 5;
		end
		if EffectsManager.hasEffectCondition(rSource, "Squeezing") then
			bEffects = true;
			nAddMod = nAddMod - 5;
		end
		
		-- If effects, then add them
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[EFFECTS " .. sMod .. "]";
			else
				sEffects = "[EFFECTS]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	-- Check for marking penalty
	local sMarkPenalty = string.match(rRoll.sDesc, "%[MARK %-(%d+)%]");
	if sMarkPenalty then
		nAddMod = nAddMod - (tonumber(sMarkPenalty) or 0);
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onAttack(rSource, rTarget, rRoll, rCustom)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local rAction = {};
	rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};
	
	-- If we have a target, then calculate the defense we need to exceed
	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus = ActorManager.getDefenseValue(rSource, rTarget, rRoll);
	if nAtkEffectsBonus ~= 0 then
		table.insert(rAction.aMessages, string.format("[EFFECTS %+d]", nAtkEffectsBonus));
	end
	if nDefEffectsBonus ~= 0 then
		table.insert(rAction.aMessages, string.format("[DEF EFFECTS %+d]", nDefEffectsBonus));
	end

	-- Get the crit threshold
	rAction.nCrit = 20;	
	local sAltCritRange = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	if sAltCritRange then
		rAction.nCrit = tonumber(sAltCritRange) or 20;
		if (rAction.nCrit <= 1) or (rAction.nCrit > 20) then
			rAction.nCrit = 20;
		end
	end
	
	rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rAction.nFirstDie >= 20 then
		rAction.bSpecial = true;
		if not (rSource and rSource.sType == "pc") and OptionsManager.isOption("REVL", "off") then
			ChatManager.Message("[GM] Original attack = " .. rAction.nFirstDie .. "+" .. rRoll.nMod .. "=" .. rAction.nTotal, false);
			rMessage.diemodifier = 0;
		end
		if nDefenseVal then
			if rAction.nTotal >= nDefenseVal then
				rAction.sResult = "crit";
				table.insert(rAction.aMessages, "[CRITICAL HIT]");
			else
				rAction.sResult = "hit";
				table.insert(rAction.aMessages, "[AUTOMATIC HIT]");
			end
		else
			table.insert(rAction.aMessages, "[AUTOMATIC HIT, CHECK FOR CRITICAL]");
		end
	elseif rAction.nFirstDie == 1 then
		if not (rSource and rSource.sType == "pc") and OptionsManager.isOption("REVL", "off") then
			rMessage.diemodifier = 0;
		end
		rAction.sResult = "fumble";
		table.insert(rAction.aMessages, "[AUTOMATIC MISS]");
	elseif nDefenseVal then
		if rAction.nTotal >= nDefenseVal then
			if rAction.nFirstDie >= rAction.nCrit then
				rAction.sResult = "crit";
				table.insert(rAction.aMessages, "[CRITICAL HIT]");
			else
				rAction.sResult = "hit";
				table.insert(rAction.aMessages, "[HIT]");
			end
		else
			rAction.sResult = "miss";
			table.insert(rAction.aMessages, "[MISS]");
		end
	elseif rAction.nFirstDie >= rAction.nCrit then
		rAction.sResult = "crit";
		table.insert(rAction.aMessages, "[CHECK FOR CRITICAL]");
	end

	Comm.deliverChatMessage(rMessage);
	
	if rTarget then
		-- COMMUNICATE RESULT OF ATTACK
		notifyApplyAttack(rSource, rTarget, rRoll.sType, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));
		
		-- TRACK CRITICAL STATE
		if rAction.sResult == "crit" then
			setCritState(rSource, rTarget);
		end
		
		-- REMOVE TARGET ON MISS OPTION
		if (rAction.sResult == "miss") or (rAction.sResult == "fumble") then
			local bRemoveTarget = false;
			if OptionsManager.isOption("RMMT", "on") then
				bRemoveTarget = true;
			elseif OptionsManager.isOption("RMMT", "multi") then
				local sTargetNumber = string.match(rRoll.sDesc, "%[MULTI%]");
				if sTargetNumber then
					bRemoveTarget = true;
				end
			end
			
			if bRemoveTarget then
				local sTargetType = "client";
				if User.isHost() then
					sTargetType = "host";
				end
			
				TargetingManager.removeTarget(sTargetType, rSource.nodeCT, rTarget.sCTNode);
			end
		end

		-- HANDLE EFFECT APPLICATION ON SUCCESSFUL ATTACK (PARTY SHEET)
		if (rAction.sResult == "crit") or (rAction.sResult == "hit") then
			if rCustom and rCustom[1] and rCustom[1].sClass == "effect" then
				if not rTarget.nodeCT then
					ChatManager.SystemMessage("[ERROR] Unable to apply effect to target which is not listed in the combat tracker.");
				else
					local rEffect = ActionEffect.decodeEffectFromText(rCustom[1].sDesc);
					if rEffect then
						rEffect.nSaveMod = rCustom[1].nMod;
						local nodeTempCT = CTManager.getActiveCT();
						if nodeTempCT then
							rEffect.nInit = DB.getValue(nodeTempCT, "initresult", 0);
						end

						EffectsManager.notifyApply(rEffect, rTarget.sCTNode);		
					end
				end
			end
		end
	end
	
	-- HANDLE FUMBLE/CRIT HOUSE RULES
	local sOptionHRFC = OptionsManager.getOption("HRFC");
	if rAction.sResult == "fumble" and ((sOptionHRFC == "both") or (sOptionHRFC == "fumble")) then
		notifyApplyHRFC("Fumble");
	end
	if rAction.sResult == "crit" and ((sOptionHRFC == "both") or (sOptionHRFC == "criticalhit")) then
		notifyApplyHRFC("Critical Hit");
	end
	
end

function applyAttack(rSource, rTarget, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Attack ->";
	msgLong.text = "Attack [" .. nTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [at " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [at " .. rTarget.sName .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
	
	msgShort.icon = "indicator_attack";
	if string.match(sResults, "%[CRITICAL HIT%]") then
		msgLong.icon = "indicator_attack_crit";
	elseif string.match(sResults, "HIT%]") then
		msgLong.icon = "indicator_attack_hit";
	elseif string.match(sResults, "MISS%]") or string.match(sResults, "%[FUMBLE%]") then
		msgLong.icon = "indicator_attack_miss";
	else
		msgLong.icon = "indicator_attack";
	end
		
	local bGMOnly = string.match(sDesc, "^%[GM%]") or string.match(sDesc, "^%[TOWER%]") ;
	ActionsManager.messageResult(bGMOnly, rSource, rTarget, msgLong, msgShort);
end

aCritState = {};

function setCritState(rSource, rTarget)
	if not (rSource and rSource.nodeCT) or not (rTarget and rTarget.nodeCT) then
		return;
	end
	
	if not aCritState[rSource.sCTNode] then
		aCritState[rSource.sCTNode] = {};
	end
	table.insert(aCritState[rSource.sCTNode], rTarget.sCTNode);
end

function clearCritState(rSource)
	if rSource and rSource.nodeCT then
		aCritState[rSource.sCTNode] = nil;
	end
end

function isCrit(rSource, rTarget)
	if not (rSource and rSource.nodeCT) or not (rTarget and rTarget.nodeCT) then
		return false;
	end

	if not aCritState[rSource.sCTNode] then
		return false;
	end
	
	for k,v in ipairs(aCritState[rSource.sCTNode]) do
		if v == rTarget.sCTNode then
			table.remove(aCritState[rSource.sCTNode], k);
			return true;
		end
	end
	
	return false;
end
