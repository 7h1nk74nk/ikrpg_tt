-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE 1: Brutal property only applies to [W] damage dice (i.e. focus damage dice)
-- NOTE 2: Vorpal property applies to all dice in a damage roll, including effects dice

OOB_MSGTYPE_APPLYDMG = "applydmg";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDMG, handleApplyDamage);

	ActionsManager.registerActionIcon("damage", "action_damage");
	ActionsManager.registerTargetingHandler("damage", onTargeting);
	ActionsManager.registerModHandler("damage", modDamage);
	ActionsManager.registerPostRollHandler("damage", onDamageRoll);
	ActionsManager.registerResultHandler("damage", onDamage);
end

function handleApplyDamage(msgOOB)
	-- GET THE TARGET ACTOR
	local rTarget = ActorManager.getActor("ct", msgOOB.sTargetCTNode);
	if not rTarget then
		rTarget = ActorManager.getActor(msgOOB.sTargetType, msgOOB.sTargetCreatureNode);
	end
	
	-- GET THE SOURCE ACTOR
	local rSource = ActorManager.getActor("ct", msgOOB.sSourceCTNode);
	
	-- Apply the damage
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyDamage(rSource, rTarget, msgOOB.sDamage, nTotal);
end

function notifyApplyDamage(rSource, rTarget, sDesc, nTotal)
	if not rTarget then
		return;
	end
	if not (rTarget.nodeCT or (rTarget.sType == "pc" and rTarget.nodeCreature)) then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDMG;
	
	msgOOB.nTotal = nTotal;
	msgOOB.sDamage = sDesc;
	msgOOB.sTargetType = rTarget.sType;
	msgOOB.sTargetCreatureNode = rTarget.sCreatureNode;
	msgOOB.sTargetCTNode = rTarget.sCTNode;
	if rSource then
		msgOOB.sSourceCTNode = rSource.sCTNode;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function onTargeting(rSource, rRolls)
	if #rRolls == 1 then
		if string.match(rRolls[1].sDesc, "%[SELF%]") then
			return { { rSource } };
		end
	end
	
	local bAreaEffect = false;
	if #rRolls > 0 then
		local sRange = string.match(rRolls[1].sDesc, "%[DAMAGE [^](]*%((%w)%)%]") or "";
		if sRange == "C" or sRange == "A" then
			bAreaEffect = true;
		end
	end
	
	local aTargets = TargetingManager.getFullTargets(rSource);
	if #aTargets == 0 then
		return { aTargets };
	end
	
	local aTargeting = {};
	local aExtraCustom = nil;
	if bAreaEffect then
		local aCritTargets = {};
		local aNormalTargets = {};
		for _,vTarget in ipairs(aTargets) do
			if ActionAttack.isCrit(rSource, vTarget) then
				table.insert(aCritTargets, vTarget);
			else
				table.insert(aNormalTargets, vTarget);
			end
		end
		
		aExtraCustom = {};
		if #aNormalTargets > 0 then
			table.insert(aTargeting, aNormalTargets);
			table.insert(aExtraCustom, {});
		end
		if #aCritTargets > 0 then
			table.insert(aTargeting, aCritTargets);
			table.insert(aExtraCustom, { bCritical = true });
		end
	else
		for _,vTarget in ipairs(aTargets) do
			table.insert(aTargeting, { vTarget });
		end
	end
	
	return aTargeting, aExtraCustom;
end

function getRoll(rActor, rAction, rFocus)
	local rPrimary = rAction;
	if not rPrimary then
		rPrimary = rFocus;
	end
	
	-- Build basic roll
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	-- Build the description label
	rRoll.sDesc = "[DAMAGE";
	if rPrimary.order and rPrimary.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rPrimary.order;
	end
	if rPrimary.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rPrimary.range ..")";
	end
	rRoll.sDesc = rRoll.sDesc .. "]";
	if rPrimary then
		rRoll.sDesc = rRoll.sDesc .. " " .. rPrimary.name;
	end
	
	-- Iterate through damage clauses
	local aDamageTypes = {};
	local sDamageTypeFirst = nil;
	local nDamageEffectCount = 0;
	if rPrimary and rPrimary.clauses then
		for k, v in pairs(rPrimary.clauses) do
			-- GET THE DAMAGE TYPE FOR THIS CLAUSE
			local nClauseDiceStart = #(rRoll.aDice);
			local nClauseModStart = rRoll.nMod;
			local aClauseDmgType = {};
			if v.subtype ~= "" then
				table.insert(aClauseDmgType, v.subtype);
			end

			if rFocus then
				-- Determine focus damage multiple
				local nMult = 0;
				if rAction then
					nMult = v.basemult;
				else
					nMult = 1;
					-- IF ACTOR IS PC AND LEVEL >= 21, THEN MULTIPLE IS INCREASED TO 2 FOR BASIC WEAPON ATTACKS
					if rActor and rActor.sType == "pc" then
						local nLevel = DB.getValue(rActor.nodeCreature, "level", 0);
						if nLevel >= 21 then
							nMult = nMult + 1;
						end
					end
				end
				
				if nMult > 0 then
					-- Add focus damage dice
					for i = 1, nMult do
						for _, vDie in ipairs(rFocus.basedice) do
							table.insert(rRoll.aDice, vDie);
						end
					end
					rRoll.sDesc = rRoll.sDesc .. " [FOCUS " .. #(rFocus.basedice) .. "," .. #(rRoll.aDice) .. "D]";

					-- Add focus damage type
					if rFocus.basetype ~= "" then
						table.insert(aClauseDmgType, rFocus.basetype);
					end
				end
			end
			
			-- Add ability modifiers
			for kStart, vStat in pairs(v.stat) do
				rRoll.nMod = rRoll.nMod + ActorManager.getAbilityBonus(rActor, vStat);
			end

			-- Add power dice and modifiers
			if rAction then
				local aPowerDice = {};
				local nPowerMod = 0;
				aPowerDice, nPowerMod = StringManager.convertStringToDice(v.dicestr);
				for _, vDie in ipairs(aPowerDice) do
					table.insert(rRoll.aDice, vDie);
				end
				rRoll.nMod = rRoll.nMod + nPowerMod;

				-- Handle separate critical and regular rolls
				if v.critdicestr ~= "" then
					rRoll.sDesc = rRoll.sDesc .. " [POWER CRIT " .. v.dicestr .. "," .. v.critdicestr .. "]";
				end
			elseif rFocus then
				rRoll.nMod = rRoll.nMod + v.mod;
			end
			
			-- ADD TO THE DAMAGE TYPES FOR THIS SET
			if ((#(rRoll.aDice) - nClauseDiceStart) > 0) or ((rRoll.nMod - nClauseModStart) ~= 0) then
				table.insert(aDamageTypes, 
						{nDice = #(rRoll.aDice) - nClauseDiceStart, 
						nMod = rRoll.nMod - nClauseModStart, 
						sType = table.concat(aClauseDmgType, ",")});
			end
			if not sDamageTypeFirst then
				sDamageTypeFirst = table.concat(aClauseDmgType, ",");
			end
		end
	end
	
	
	-- Check for static
	local isStatic = (#(rRoll.aDice) == 0);
	
	-- Ignore effects and critical dice for static damage rolls
	if not isStatic then
		-- Get focus modifiers
		if rAction and rFocus then
			local nFocusMod = 0;
			for k, v in pairs(rFocus.clauses) do
				nFocusMod = nFocusMod + v.mod;
			end
			
			if nFocusMod ~= 0 then
				rRoll.nMod = rRoll.nMod + nFocusMod;
				if sDamageTypeFirst then
					table.insert(aDamageTypes, { nDice = 0, nMod = nFocusMod, sType = sDamageTypeFirst });
				end
			end
		end

		if rFocus then
			-- Check for special focus properties
			if string.match(rFocus.properties, "vorpal") then
				rRoll.sDesc = rRoll.sDesc .. " [VORPAL]";
			end
			local sBrutal = string.match(rFocus.properties, "brutal (%d+)");
			local isBrutal = tonumber(sBrutal) or 0;
			if isBrutal > 0 then
				rRoll.sDesc = rRoll.sDesc .. " [BRUTAL " .. isBrutal .. "]";
			end
			if string.match(rFocus.properties, "high crit") then
				rRoll.sDesc = rRoll.sDesc .. " [HIGH CRIT]";
			end
			
			-- Add focus critical dice
			rRoll.sDesc = rRoll.sDesc .. " [FOCUS CRIT " .. StringManager.convertDiceToString(rFocus.critdice, rFocus.critmod);
			if rFocus.crittype ~= "" then
				rRoll.sDesc = rRoll.sDesc .. " " .. rFocus.crittype;
			end
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end

	if #aDamageTypes > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. encodeDamageTypes(aDamageTypes);
	end

	-- ADD FOCUS NAME (IF OPTION ENABLED)
	if rAction and rFocus and rFocus.name ~= "" and OptionsManager.isOption("SWPN", "on") then
		rRoll.sDesc = rRoll.sDesc .. " [USING " .. rFocus.name .. "]";
	end
	
	if rAction and rAction.sTargeting == "self" then
		rRoll.sDesc = rRoll.sDesc .. " [SELF]";
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction, rFocus)
	local rRoll = getRoll(rActor, rAction, rFocus);
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "damage", rRoll, nil, true);
end

function modDamage(rSource, rTarget, rRoll, rCustom)
	local bEffects = false;
	local aAddDesc = {};
	local aTotalEffectDice = {};
	local nTotalEffectMod = 0;
	
	-- Build attack type filter
	local aAttackFilter = {};
	local sAttackType = string.match(rRoll.sDesc, "%[DAMAGE%s*%(([^%)%]]+)%)%]");
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
	
	-- Determine damage type modifiers
	local bCritical = ModifierStack.getModifierKey("DMG_CRIT") or Input.isShiftPressed();
	if rTarget then
		if not rTarget.nOrder then
			if ActionAttack.isCrit(rSource, rTarget) then
				bCritical = true;
			end
		end
	end
	if rCustom and rCustom.bCritical then
		bCritical = true;
	end
	local nHalf = 0;
	if ModifierStack.getModifierKey("DMG_HALF") then
		nHalf = nHalf + 1;
	end

	-- Determine damage roll modifiers
	local nBrutal = tonumber(string.match(rRoll.sDesc, "%[BRUTAL (%d+)")) or 0;
	
	-- Handle single damage roll for multiple targets
	if rTarget and rTarget.nOrder then
		if rSource and rSource.nodeCT then
			-- Determine damage property modifiers
			local bVorpal = string.match(rRoll.sDesc, "%[VORPAL%]");
			
			local aDamageTypes = decodeDamageTypes(false, rRoll.sDesc, rRoll.aDice, rRoll.nMod);
			
			local aAddDice, nAddMod;
			local aEffectDice, nEffectMod, nEffects;
			
			local sFocusBaseDice, sFocusTotalDice = string.match(rRoll.sDesc, "%[FOCUS (%d+),(%d+)D%]");
			if sFocusBaseDice then
				nEffectMod, nEffects = EffectsManager.getEffectsBonus(rSource, "DMGW", true, aAttackFilter, rTarget, true);
				if nEffects > 0 then
					bEffects = true;

					local nFocusBaseDice = tonumber(sFocusBaseDice) or 0;
					local aFocusDice = {};
					for i = 1, nEffectMod do
						for j = 1, nFocusBaseDice do
							table.insert(aFocusDice, rRoll.aDice[j]);
						end
					end
					if #aFocusDice > 0 then
						local nEval = StringManager.evalDice(aFocusDice, 0, bCritical, bVorpal, nBrutal);
						nAddMod = nAddMod + nEval;
						if aDamageTypes[1] then
							aDamageTypes[1].nMod = aDamageTypes[1].nMod + nEval;
						end
					end
				end
			end
			
			aEffectDice, nEffectMod, nEffects = EffectsManager.getEffectsBonus(rSource, "DMG", false, aAttackFilter, rTarget, true);
			if nEffects > 0 then
				bEffects = true;

				for k,v in pairs(aEffects) do
					local nEval = StringManager.evalDice(v.dice, v.mod, bCritical, bVorpal);
					nAddMod = nAddMod + nEval;
					if StringManager.contains(DataCommon.dmgtypes, k) then
						table.insert(aDamageTypes, {nDice = 0, nMod = nEval, sType = k});
					else
						if aDamageTypes[1] then
							aDamageTypes[1].nMod = aDamageTypes[1].nMod + nEval;
						end
					end
				end
			end
			
			if bEffects then
				rRoll.nMod = rRoll.nMod + nAddMod;
				rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE: ([^]]+)%]", " " .. encodeDamageTypes(aDamageTypes));
				if nAddMod ~= 0 then
					rRoll.sDesc = string.format("%s [SPECIFIC %+d]", rRoll.sDesc, nAddMod);
				else
					rRoll.sDesc = rRoll.sDesc .. " [SPECIFIC]";
				end
			end
		end
		
		return;
	end
	
	-- Decode and remove damage type information
	local aDamageTypes = decodeDamageTypes(false, rRoll.sDesc, rRoll.aDice, rRoll.nMod);
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE: ([^]]+)%]", "");
	
	-- Determine if roll is static damage
	local isStatic = (#(rRoll.aDice) == 0);

	-- Add-in fake die for fixed damage monster rolls (if GM rolls hidden), plus this supports DMG effects as well
	if isStatic then
		if rSource and rSource.sType == "npc" then
			isStatic = false;
			if User.isHost() and OptionsManager.isOption("REVL", "off") then
				table.insert(rRoll.aDice, "d0");
			end
		end
	end
	
	-- Ignore effects and critical dice for static damage rolls
	if not isStatic then
		-- Track dice to maximize and dice to brutalize
		local aBrutalDice = {};
		local aMaxDice = {};
		
		-- Decode focus dice
		local nFocusBaseDice = 0;
		local nFocusTotalDice = 0;
		local sFocusBaseDice, sFocusTotalDice = string.match(rRoll.sDesc, "%[FOCUS (%d+),(%d+)D%]");
		if sFocusBaseDice and sFocusTotalDice then
			nFocusBaseDice = tonumber(sFocusBaseDice) or 0;
			nFocusTotalDice = tonumber(sFocusTotalDice) or 0;
		end
		
		if nFocusBaseDice > 0 then
			-- All focus dice are brutal
			for i = 1, nFocusTotalDice do
				aBrutalDice[i] = true;
				aMaxDice[i] = true;
			end
			
			-- Handle DMGW effects
			if rSource and nFocusBaseDice > 0 then
				local nEffectMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, "DMGW", true, aDamageFilter, rTarget);
				if nEffectCount > 0 then
					bEffects = true;
					
					local aFocusDice = {};
					for i = 1, nEffectMod do
						for j = 1, nFocusBaseDice do
							table.insert(aFocusDice, rRoll.aDice[j]);
						end
					end
					if #aFocusDice > 0 then
						for _, vDie in ipairs(aFocusDice) do
							table.insert(rRoll.aDice, nFocusBaseDice, "p" .. string.sub(vDie, 2));
							table.insert(aTotalEffectDice, vDie);
							table.insert(aBrutalDice, nFocusBaseDice, true);
							table.insert(aMaxDice, nFocusBaseDice, true);
						end
						if aDamageTypes[1] then
							aDamageTypes[1].nDice = aDamageTypes[1].nDice + #aFocusDice;
						end
					end
				end
			end
		else
			-- Assume that focus is not used for this, only allowed for NPCs
			if bCritical then
				-- On critical, change out power normal dice/mod for power crit dice/mod
				local sPowerNormal, sPowerCrit = string.match(rRoll.sDesc, "%[POWER CRIT ([%dd+-]+),([%dd+-]+)%]");
				if sPowerNormal and sPowerCrit then
					local aPowerNormalDice, nPowerNormalMod = StringManager.convertStringToDice(sPowerNormal);
					local aPowerCritDice, nPowerCritMod = StringManager.convertStringToDice(sPowerCrit);
					
					for i = 1, #aPowerNormalDice do
						table.remove(rRoll.aDice, 1);
					end
					for i = 1, #aPowerCritDice do
						table.insert(rRoll.aDice, 1, aPowerCritDice[i]);
						table.insert(aBrutalDice, 1, true);
					end
					rRoll.nMod = rRoll.nMod + nPowerCritMod - nPowerNormalMod;
					
					if aDamageTypes[1] then
						aDamageTypes[1].nDice = aDamageTypes[1].nDice + #aPowerCritDice - #aPowerNormalDice;
						aDamageTypes[1].nMod = aDamageTypes[1].nMod + nPowerCritMod - nPowerNormalMod;
					end
				-- If no power crit dice/mod specified, then maximize the current dice
				else
					for i = 1, #(rRoll.aDice) do
						aMaxDice[i] = true;
					end
				end
			end
		end

		-- Handle DMG effects
		if rSource then
			local aEffects = {};
			local nEffects;
			if rSource then
				aEffects, nEffects = EffectsManager.getEffectsBonusByType(rSource, "DMG", true, aDamageFilter, rTarget);
				if nEffects > 0 then
					bEffects = true;
				end
			end

			-- Add untyped DMG effect modifiers
			local nUntypedDice = 0;
			local nUntypedMod = 0;
			local aOtherEffects = {};
			for k, v in pairs(aEffects) do
				if StringManager.contains(DataCommon.dmgtypes, k) then
					table.insert(aOtherEffects, {dice = v.dice, mod = v.mod, dmgtype = k});
				else
					for _, vDie in pairs(v.dice) do
						table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
						table.insert(aTotalEffectDice, vDie);
						table.insert(aMaxDice, #(rRoll.aDice), true);
					end
					nUntypedDice = nUntypedDice + #(v.dice);

					rRoll.nMod = rRoll.nMod + v.mod;
					nTotalEffectMod = nTotalEffectMod + v.mod;
					nUntypedMod = nUntypedMod + v.mod;
				end
			end
			if (nUntypedDice > 0) or (nUntypedMod ~= 0) then
				local sDamageTypeFirst = "";
				if aDamageTypes[1] then
					sDamageTypeFirst = aDamageTypes[1].sType;
				end
				table.insert(aDamageTypes, {nDice = nUntypedDice, nMod = nUntypedMod, sType = sDamageTypeFirst});
			end

			-- Add typed DMG effect modifiers
			for k,v in pairs(aOtherEffects) do
				for _, vDie in pairs(v.dice) do
					table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
					table.insert(aTotalEffectDice, vDie);
					table.insert(aMaxDice, #(rRoll.aDice), true);
				end
				rRoll.nMod = rRoll.nMod + v.mod;
				nTotalEffectMod = nTotalEffectMod + v.mod;
				if (#(v.dice) > 0) or (v.mod ~= 0) then
					table.insert(aDamageTypes, {nDice = #(v.dice), nMod = v.mod, sType = v.dmgtype});
				end
			end
		end

		-- On critical, handle high crit
		if bCritical and string.match(rRoll.sDesc, "%[HIGH CRIT%]") and nFocusBaseDice > 0 then
			-- Determine high crit multiple
			local nHighCritMult = 1;
			local nLevel = ActorManager.getAbilityBonus(rSource, "LEV");
			if nLevel > 20 then
				nHighCritMult = 3;
			elseif nLevel > 10 then
				nHighCritMult = 2;
			end
			
			-- ADD HIGH CRIT DICE AND DAMAGE TYPE
			local aFocusDice = {};
			for i = 1, nHighCritMult do
				for j = 1, nFocusBaseDice do
					table.insert(aFocusDice, rRoll.aDice[j]);
				end
			end
			for _, vDie in ipairs(aFocusDice) do
				table.insert(rRoll.aDice, nFocusBaseDice + 1, vDie);
				table.insert(aBrutalDice, nFocusBaseDice + 1, true);
			end
			if aDamageTypes[1] then
				aDamageTypes[1].nDice = aDamageTypes[1].nDice + #aFocusDice;
			end
		end
		
		-- On critical, add weapon critical dice
		if bCritical then
			local sFocusCritDice, sFocusCritType = string.match(rRoll.sDesc, "%[FOCUS CRIT ([%dd+-]+)([^]]*)%]");
			if sFocusCritDice then
				if sFocusCritType then
					sFocusCritType = StringManager.trim(sFocusCritType);
				else
					sFocusCritType = "";
				end

				local aFocusCritDice, nFocusCritMod = StringManager.convertStringToDice(sFocusCritDice);
				for _, vDie in pairs(aFocusCritDice) do
					table.insert(rRoll.aDice, vDie);
				end
				rRoll.nMod = rRoll.nMod + nFocusCritMod;
				if #aFocusCritDice > 0 or nFocusCritMod ~= 0 then
					table.insert(aDamageTypes, { nDice = #aFocusCritDice, nMod = nFocusCritMod, sType = sFocusCritType });
				end
			end
		end
		
		-- Handle criticals
		if bCritical then
			table.insert(aAddDesc, "[CRITICAL]");
			
			-- Add max flag to denote which dice get maximized
			if #aMaxDice > 0 then
				local aMaxOutput = {};
				local i = 1;
				while i <= #(rRoll.aDice) do
					if aMaxDice[i] then
						local j = i + 1;
						while aMaxDice[j] do
							j = j + 1;
						end

						if (i == 1) and (j > #(rRoll.aDice)) then
							-- SKIP
						elseif i == j - 1 then
							table.insert(aMaxOutput, "" .. i);
						else
							table.insert(aMaxOutput, "" .. i .. "-" .. (j - 1));
						end
						i = j - 1;
					end
					i = i + 1;
				end
				if #aMaxOutput > 0 then
					local sMax = "[MAX (D" .. table.concat(aMaxOutput, ",") .. ")]";
					table.insert(aAddDesc, sMax);
				else
					table.insert(aAddDesc, "[MAX]");
				end
			end
		end
		
		-- Update brutal flag to denote which dice get brutalized
		if nBrutal > 0 and #aBrutalDice > 0 then
			local aBrutalOutput = {};
			local i = 1;
			while i <= #(rRoll.aDice) do
				if aBrutalDice[i] then
					local j = i + 1;
					while aBrutalDice[j] do
						j = j + 1;
					end

					if (i == 1) and (j > #(rRoll.aDice)) then
						-- SKIP
					elseif i == j - 1 then
						table.insert(aBrutalOutput, "" .. i);
					else
						table.insert(aBrutalOutput, "" .. i .. "-" .. (j - 1));
					end
					i = j - 1;
				end
				i = i + 1;
			end
			if #aBrutalOutput > 0 then
				local sBrutalNew = "[BRUTAL " .. nBrutal .. " (D" .. table.concat(aBrutalOutput, ",") .. ")]";
				rRoll.sDesc = string.gsub(rRoll.sDesc, "%[BRUTAL (%d+)%]", sBrutalNew);
			end
		end
	end
	
	-- Apply conditions
	if EffectsManager.hasEffect(rSource, "Weakened") then
		bEffects = true;
		nHalf = nHalf + 1;
	end
	
	-- Handle DMGTYPE effects
	if rSource then
		local aDmgTypeEffects = EffectsManager.getEffectsByType(rSource, "DMGTYPE", {});
		local aAddTypes = {};
		for k, v in ipairs(aDmgTypeEffects) do
			for _, sWord in ipairs(v.remainder) do
				local aSplitTypes = StringManager.split(sWord, ",", true);
				for _, sType in ipairs(aSplitTypes) do
					table.insert(aAddTypes, sType);
				end
			end
		end
		if #aAddTypes > 0 then
			bEffects = true;
			for k, v in ipairs(aDamageTypes) do
				local aSplitTypes = StringManager.split(v.sType, ",", true);
				for _, v2 in ipairs(aAddTypes) do
					if not StringManager.contains(aSplitTypes, v2) then
						if v.sType ~= "" then
							v.sType = v.sType .. "," .. v2;
						else
							v.sType = v2;
						end
					end
				end
			end
		end
	end
	
	-- Add half tag
	if nHalf > 0 then
		if nHalf > 1 then
			table.insert(aAddDesc, string.format("[HALF (x%d)]", nHalf));
		else
			table.insert(aAddDesc, "[HALF]");
		end
	end
	
	-- Add effect tag
	if bEffects then
		local sEffects = "";
		local sMod = StringManager.convertDiceToString(aTotalEffectDice, nTotalEffectMod, true);
		if sMod ~= "" then
			sEffects = "[EFFECTS " .. sMod .. "]";
		else
			sEffects = "[EFFECTS]";
		end
		table.insert(aAddDesc, sEffects);
	end
	
	if #aDamageTypes > 0 then
		table.insert(aAddDesc, encodeDamageTypes(aDamageTypes));
	end
	
	-- Remove FOCUS, FOCUS CRIT and POWER CRIT tags after modifying
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[FOCUS ([^]]+)%]", "");
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[POWER ([^]]+)%]", "");
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
end

function checkDie(nDieResult, sDieType, nDieSides, nIndex, aMaxDice, aBrutalDice, isBrutal, isVorpal)
	-- HANDLE MAX
	if aMaxDice[nIndex] then
		return "g" .. nDieSides, nDieSides;
	end
	
	-- HANDLE VORPAL
	if isVorpal then
		-- IF MAX ROLL, THEN ROLL UNTIL WE DON't GET MAX
		if nDieResult == nDieSides then
			local nNewResult = math.random(nDieSides);
			_, nNewResult = checkDie(nNewResult, sDieType, nDieSides, nIndex, aMaxDice, aBrutalDice, isBrutal, isVorpal);
			nDieResult = nDieResult + nNewResult;
			return "b" .. nDieSides, nDieResult;
		end
	end
	
	-- HANDLE BRUTAL
	if aBrutalDice[nIndex] and isBrutal > 0 and nDieResult <= isBrutal then
		-- IF BRUTAL IS WITHIN ONE OF NUMBER OF SIDES, THEN JUST RETURN MAX
		if isBrutal >= nDieSides - 1 then
			return "r" .. nDieSides, nDieSides;
		
		-- OR ELSE REROLL DICE WHICH DID NOT MEET THE BRUTAL CUTOFF
		else
			local nNewResult = math.random(nDieSides);
			_, nNewResult = checkDie(nNewResult, sDieType, nDieSides, nIndex, aMaxDice, aBrutalDice, isBrutal, isVorpal);
			nDieResult = nNewResult;
			return "r" .. nDieSides, nDieResult;
		end
	end
	
	-- Return the results of the die check
	return sDieType .. nDieSides, nDieResult;
end

function onDamageRoll(rSource, rRoll, rCustom)
	-- Handle damage roll modifiers
	local bVorpal = false;
	if string.match(rRoll.sDesc, " %[VORPAL%]") then
		bVorpal = true;
	end
	local aMaxDice = {};
	if string.match(rRoll.sDesc, "%[MAX") then
		local sMaxDiceString = string.match(rRoll.sDesc, "%[MAX %(D([%d,%-]+)%)%]");
		if sMaxDiceString then
			local aMaxList = StringManager.split(sMaxDiceString, ",");
			for _, v in pairs(aMaxList) do
				local sMaxStart, sMaxEnd = string.match(v, "(%d+)%-?(%d*)");
				local nMaxStart = tonumber(sMaxStart) or 0;
				local nMaxEnd = tonumber(sMaxEnd) or 0;
				if nMaxStart > 0 then
					if nMaxEnd > 0 then
						for i = nMaxStart, nMaxEnd do
							aMaxDice[i] = true;
						end
					else
						aMaxDice[nMaxStart] = true;
					end
				end
			end
		else
			for i = 1, #(rRoll.aDice) do
				aMaxDice[i] = true;
			end
		end
		rRoll.sDesc = string.gsub(rRoll.sDesc, " %[MAX([^]]+)%]", "");
	end
	local aBrutalDice = {};
	local nBrutal = 0;
	if string.match(rRoll.sDesc, "%[BRUTAL") then
		local sBrutal = string.match(rRoll.sDesc, "%[BRUTAL (%d)");
		nBrutal = tonumber(sBrutal) or 0;
			
		if nBrutal > 0 then
			local sBrutalDiceString = string.match(rRoll.sDesc, "%[BRUTAL %d %(D([%d,%-]+)%)%]");
			if sBrutalDiceString then
				local aBrutalList = StringManager.split(sBrutalDiceString, ",");
				for _, v in pairs(aBrutalList) do
					local sBrutalStart, sBrutalEnd = string.match(v, "(%d+)%-?(%d*)");
					local nBrutalStart = tonumber(sBrutalStart) or 0;
					local nBrutalEnd = tonumber(sBrutalEnd) or 0;
					if nBrutalStart > 0 then
						if nBrutalEnd > 0 then
							for i = nBrutalStart, nBrutalEnd do
								aBrutalDice[i] = true;
							end
						else
							aBrutalDice[nBrutalStart] = true;
						end
					end
				end
				rRoll.sDesc = string.gsub(rRoll.sDesc, " %[BRUTAL ([^]]+)%]", "[BRUTAL " .. nBrutal.. "]");
			else
				for i = 1, #(rRoll.aDice) do
					aBrutalDice[i] = true;
				end
			end
		end
	end
	
	-- Get damage types for this roll
	local aDamageTypes = decodeDamageTypes(true, rRoll.sDesc, rRoll.aDice, rRoll.nMod);
	if #aDamageTypes > 0 then
		-- Track damage roll modifier handling
		local aReroll = "";
		local aExplode = "";
		
		-- Build damage type subtotals
		local nTypeIndex = 1;
		local nTypeCount = 0;
		local nTypeTotal = 0;
		for i, d in ipairs(rRoll.aDice) do
			-- Process damage roll modifiers for each die
			local nDieBonus = 0;
			local sDieType, sDieSides = string.match(d.type, "([a-z])(%d+)");
			local nDieSides = tonumber(sDieSides) or 0;
			if nDieSides > 0 then
				d.type, d.result = checkDie(d.result, sDieType, nDieSides, i, aMaxDice, aBrutalDice, nBrutal, bVorpal);
			end
			
			-- Determine damage type subtotals
			if nTypeIndex <= #aDamageTypes then
				nTypeCount = nTypeCount + 1;
				nTypeTotal = nTypeTotal + d.result;
				
				if nTypeCount >= aDamageTypes[nTypeIndex].nDice then
					nTypeTotal = nTypeTotal + aDamageTypes[nTypeIndex].nMod;
					aDamageTypes[nTypeIndex].nTotal = nTypeTotal;
					
					nTypeIndex = nTypeIndex + 1;
					nTypeCount = 0;
					nTypeTotal = 0;
				end
			end
		end

		-- Handle any remaining fixed damage
		for i = nTypeIndex, #aDamageTypes do
			aDamageTypes[i].nTotal = aDamageTypes[i].nMod;
		end
			
		-- Add damage type totals to output
		rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE: ([^]]+)%]", "");
		rRoll.sDesc = rRoll.sDesc .. " " .. encodeDamageTypes(aDamageTypes);
		
		-- Add extra data from brutal and vorpal properties
		if #aReroll > 0 then
			rRoll.sDesc = rRoll.sDesc .. " [REROLL " .. table.concat(aReroll, ",") .. "]";
		end
		if #aExplode > 0 then
			rRoll.sDesc = rRoll.sDesc .. " [ADD " .. table.concat(aExplode, ",") .. "]";
		end
	end
end

function onDamage(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);
	
	-- Handle minimum damage
	if string.match(rMessage.text, " %[MIN OVERRIDE%]") then
		rMessage.text = string.gsub(rMessage.text, " %[MIN OVERRIDE%]", "");
	elseif nTotal <= 0 then
		rMessage.text = rMessage.text .. " [MIN DAMAGE]";
		rMessage.diemodifier = rMessage.diemodifier - nTotal;
		nTotal = 0;
	end
	
	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		if not string.match(rRoll.sDesc, "%[SPECIFIC") then
			bShowMsg = false;
		end
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end

	-- Apply damage to the PC or CT entry referenced
	notifyApplyDamage(rSource, rTarget, rMessage.text, nTotal);
end

--
-- UTILITY FUNCTIONS
--

function encodeDamageTypes(aDamageTypes)
	local aOutputType = {};
	
	local nTypeCount = 0;
	local sLastDamageType = nil;
	local nLastDieCount = 0;
	local nLastMod = 0;
	local nLastTotal = nil;
	for _,v in ipairs(aDamageTypes) do
		local sCurrentDamageType = string.lower(v.sType);
		
		if sLastDamageType and sCurrentDamageType ~= sLastDamageType then
			local sDmgType;
			if sLastDamageType == "" then
				sDmgType = "[TYPE: untyped";
			else
				sDmgType = "[TYPE: " .. sLastDamageType;
			end
			sDmgType = sDmgType .. " (" .. nLastDieCount .. "D";
			if nLastMod ~= 0 then
				sDmgType = sDmgType .. string.format("%+d", nLastMod);
			end
			if nLastTotal then
				sDmgType = sDmgType .. "=" .. nLastTotal;
			end
			sDmgType = sDmgType .. ")";
			sDmgType = sDmgType .. "]";
			
			table.insert(aOutputType, sDmgType);
			
			nTypeCount = nTypeCount + 1;
			nLastDieCount = 0;
			nLastMod = 0;
		end
		
		sLastDamageType = sCurrentDamageType;
		nLastDieCount = nLastDieCount + v.nDice;
		nLastMod = nLastMod + v.nMod;
		nLastTotal = v.nTotal;
	end
	if sLastDamageType and sLastDamageType ~= "" then
		local sDmgType;
		if sLastDamageType == "" then
			sDmgType = "[TYPE: untyped";
		else
			sDmgType = "[TYPE: " .. sLastDamageType;
		end
		if nTypeCount > 0 then
			sDmgType = sDmgType .. " (" .. nLastDieCount .. "D";
			if nLastMod ~= 0 then
				sDmgType = sDmgType .. string.format("%+d", nLastMod);
			end
			if nLastTotal then
				sDmgType = sDmgType .. "=" .. nLastTotal;
			end
			sDmgType = sDmgType .. ")";
		end
		sDmgType = sDmgType .. "]";
		
		table.insert(aOutputType, sDmgType);
	end
	
	return table.concat(aOutputType, " ");
end

function decodeDamageTypes(bRolled, sDesc, aDice, nMod)
	local aDamageTypes = {};
	
	local nDamageDice = 0;
	local nDamageMod = 0;
	
	for sDamageClause in string.gmatch(sDesc, "%[TYPE: ([^]]+)%]") do
		local sDamageType = string.match(sDamageClause, "^([,%w%s]+)");
		if sDamageType then
			sDamageType = StringManager.trim(sDamageType);
			
			local nTotal = nil;
			local sDieCount, sSign, sMod = string.match(sDamageClause, "%((%d+)D([%+%-]?)(%d*)");
			local nDieCount = tonumber(sDieCount) or 0;
			local nDieMod = tonumber(sMod) or 0;
			if nDieCount > 0 or nDieMod > 0 then
				if sSign == "-" then
					nDieMod = 0 - nDieMod;
				end
			else
				nDieCount = #aDice - nDamageDice;
				nDieMod = nMod - nDamageMod;
			end

			nDamageDice = nDamageDice + nDieCount;
			nDamageMod = nDamageMod + nDieMod;

			if sDamageType == "untyped" then
				sDamageType = "";
			end
			
			local rDamageType = { sType = sDamageType, nDice = nDieCount, nMod = nDieMod };

			local sTotal = string.match(sDamageClause, "%(%d+D[%+%-]?%d*=(%d+)%)");
			if sTotal then
				rDamageType.nTotal = tonumber(sTotal) or 0;
			end
			
			table.insert(aDamageTypes, rDamageType);
		end
	end
	
	if (nDamageDice < #aDice) or (nDamageMod ~= nMod) then
		local rDamageType = { sType = "", nDice = (#aDice - nDamageDice), nMod = (nMod - nDamageMod) };
		if bRolled then
			rDamageType.nTotal = 0;
			if (nDamageDice < #aDice) then
				for i = nDamageDice + 1, #aDice do
					rDamageType.nTotal = rDamageType.nTotal + aDice[i].result;
				end
			end
			rDamageType.nTotal = rDamageType.nTotal + rDamageType.nMod;
		end
		
		table.insert(aDamageTypes, rDamageType);
	end
	
	return aDamageTypes;
end

function getDamageTypesFromString(sDamageTypes)
	local sLower = string.lower(sDamageTypes);
	local aSplit = StringManager.split(sLower, ",", true);
	
	local aDamageTypes = {};
	for k, v in ipairs(aSplit) do
		if StringManager.contains(DataCommon.dmgtypes, v) then
			table.insert(aDamageTypes, v);
		end
	end
	
	return aDamageTypes;
end

--
-- DAMAGE APPLICATION
--

function getDamageAdjust(rSource, rTarget, nDamage, rDamageOutput)
	-- SETUP
	local nDamageAdjust = 0;
	local bVulnerable = false;
	local bResist = false;
	local nHalf = 0;
	
	-- GET THE DAMAGE ADJUSTMENT EFFECTS
	local aImmune = EffectsManager.getEffectsBonusByType(rTarget, "IMMUNE", false, {}, rSource);
	local aVuln = EffectsManager.getEffectsBonusByType(rTarget, "VULN", false, {}, rSource);
	local aResist = EffectsManager.getEffectsBonusByType(rTarget, "RESIST", false, {}, rSource);
	
	-- ADD ANY EFFECT MODIFIERS TO IMMUNE/VULN/RESIST
	-- EFFECT [PERTRIFIED] - GAIN RESIST 20
	if EffectsManager.hasEffectCondition(rTarget, "Petrified") then
		if aResist[""] then
			aResist[""].mod = math.max((aResist[""].mod or 0), 20);
		else
			aResist[""] = {dice = {}, mod = 20};
		end
	end
	
	-- IF IMMUNE ALL, THEN JUST HANDLE IT NOW
	if aImmune["all"] then
		nDamageAdjust = 0 - nDamage;
		bResist = true;
		return nDamageAdjust, bVulnerable, bResist;
	end

	-- IF IMMUNE TO ENERGY TYPE, THEN DO NOT PROCESS VULNERABLE/RESIST TO THAT TYPE
	for k,_ in pairs(aImmune) do
		aVuln[k] = nil;
		aResist[k] = nil;
	end
	
	-- ITERATE THROUGH EACH DAMAGE TYPE ENTRY
	local nResistApplied = 0;
	for k,v in pairs(rDamageOutput.aDamageTypes) do
		-- GET THE INDIVIDUAL DAMAGE TYPES FOR THIS ENTRY (EXCLUDING UNTYPED DAMAGE TYPE)
		local aSrcDmgClauseTypes = {};
		local aTemp = StringManager.split(k, ",", true);
		for i = 1, #aTemp do
			if aTemp[i] ~= "untyped" and aTemp[i] ~= "" then
				table.insert(aSrcDmgClauseTypes, aTemp[i]);
			end
		end

		-- MAKE SURE THERE IS A DAMAGE TYPE LEFT
		if #aSrcDmgClauseTypes > 0 then
			-- CHECK IMMUNITY
			local nSourceImmune = 0;
			for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
				if aImmune[sDmgType] then
					nSourceImmune = nSourceImmune + 1;
				end
			end
			
			-- IF IMMUNE, THEN DISCOUNT ALL OF THIS DAMAGE
			if nSourceImmune == #aSrcDmgClauseTypes then
				nDamageAdjust = nDamageAdjust - v;
				bResist = true;

			-- OTHERWISE, CHECK VULNERABILITY AND RESISTANCE
			else
				-- IF VULNERABLE TO ANY OF THE DAMAGE TYPES, THEN APPLY THE VULNERABILITY ONCE
				for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
					if aVuln[sDmgType] and not aVuln[sDmgType].nApplied then
						aVuln[sDmgType].nApplied = aVuln[sDmgType].mod;
						nDamageAdjust = nDamageAdjust + aVuln[sDmgType].mod;
						bVulnerable = true;
					end
				end
				
				-- IF RESISTANT TO ALL OF THE DAMAGE TYPES, THEN RESIST UP TO THE AMOUNT OF THIS CLAUSE
				local nSourceResist = nil;
				for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
					if aResist[sDmgType] then
						local nRemainingResist = aResist[sDmgType].mod - (aResist[sDmgType].nApplied or 0);
						if nRemainingResist > 0 then
							if nSourceResist then
								nSourceResist = math.min(nSourceResist, nRemainingResist);
							else
								nSourceResist = nRemainingResist;
							end
						else
							nSourceResist = nil;
							break;
						end
					else
						nSourceResist = nil;
						break;
					end
				end
				if nSourceResist then
					if nSourceResist > v then
						nSourceResist = v;
					end
					for keyDmgType, sDmgType in pairs(aSrcDmgClauseTypes) do
						aResist[sDmgType].nApplied = nSourceResist;
					end
					nDamageAdjust = nDamageAdjust - nSourceResist;
					nResistApplied = nResistApplied + nSourceResist;
					bResist = true;
				end
			end
		end
	end

	-- HANDLE VULNERABILITY AND RESISTANCE TO ALL DAMAGE
	if aVuln[""] then
		nDamageAdjust = nDamageAdjust + aVuln[""].mod;
		bVulnerable = true;
	end
	if aResist[""] then
		local nResistAll = aResist[""].mod - nResistApplied;
		if (nResistAll > 0) then
			nDamageAdjust = nDamageAdjust - nResistAll;
			bResist = true;
		end
	end

	-- HANDLE EFFECT MODIFIERS
	if (nDamage + nDamageAdjust > 0) then
		-- [EFFECT] SWARM - HALF DAMAGE VS. M/R ATTACKS, EXTRA DAMAGE VS. C/A ATTACKS)
		local nSwarm = EffectsManager.getEffectsBonus(rTarget, "SWARM", true);
		if nSwarm > 0 then
			if rDamageOutput.sRange == "M" or rDamageOutput.sRange == "R" then
				nHalf = nHalf + 1;
			elseif rDamageOutput.sRange == "C" or rDamageOutput.sRange == "A" then
				nDamageAdjust = nDamageAdjust + nSwarm;
				bVulnerable = true;
			end
		end
		
		-- [EFFECT] INSUBSTANTIAL - HALF DAMAGE FROM ALL SOURCES
		if EffectsManager.hasEffectCondition(rTarget, "Insubstantial") then
			nHalf = nHalf + 1;
		end
		
		-- IF HALF DAMAGE SET BY ATTACKER WEAKENED STATE, APPLY ANOTHER HALF DAMAGE INCREMENT
		if rDamageOutput.nHalf > 0 then
			nHalf = nHalf + 1;
		end
		
		-- APPLY HALF DAMAGE
		for i = 1, nHalf do
			nDamageAdjust = nDamageAdjust - math.ceil((nDamage + nDamageAdjust) / 2);
		end
		if (nDamage + nDamageAdjust < 1) then
			nDamageAdjust = 0 - (nDamage - 1);
		end
	end

	-- RESULTS
	return nDamageAdjust, bVulnerable, bResist, nHalf;
end

function decodeDamageText(nDamage, sDamageDesc)
	local rDamageOutput = {};
	rDamageOutput.sType = "damage";
	rDamageOutput.sTypeOutput = "Damage";
	rDamageOutput.sVal = "" .. nDamage;
	rDamageOutput.nVal = nDamage;
	
	if string.match(sDamageDesc, "%[HEAL") then
		rDamageOutput.nHealCost = tonumber(string.match(sDamageDesc, "%[COST ([%+%-]?%d+)%]")) or 0;
		rDamageOutput.nHSVMult = tonumber(string.match(sDamageDesc, "%[HSV ([%+%-]?%d+)]")) or 0;
		
		rDamageOutput.sVal = "";		
		if rDamageOutput.nHSVMult > 0 then
			if rDamageOutput.nHSVMult > 1 then
				rDamageOutput.sVal = rDamageOutput.sVal .. rDamageOutput.nHSVMult .. "*";
			end
			rDamageOutput.sVal = rDamageOutput.sVal .. "HSV";
			if nDamage ~= 0 then
				rDamageOutput.sVal = rDamageOutput.sVal .. "+" .. nDamage;
			end
		else
			rDamageOutput.sVal = "" .. nDamage;
		end
		if rDamageOutput.nHealCost ~= 0 then
			rDamageOutput.sVal = rDamageOutput.sVal .. "][HS";
			if rDamageOutput.nHealCost < 0 then
				rDamageOutput.sVal = rDamageOutput.sVal .. "+";
			end
			rDamageOutput.sVal = rDamageOutput.sVal .. -(rDamageOutput.nHealCost);
		end

		if string.match(sDamageDesc, "%[TEMP%]") then
			-- SET MESSAGE TYPE
			rDamageOutput.sType = "temphp";
			rDamageOutput.sTypeOutput = "Temporary hit points";
		else
			-- SET MESSAGE TYPE
			rDamageOutput.sType = "heal";
			rDamageOutput.sTypeOutput = "Heal";
		end
	elseif nDamage < 0 then
		rDamageOutput.sType = "heal";
		rDamageOutput.sTypeOutput = "Heal";
		rDamageOutput.nHealCost = 0;
		rDamageOutput.nHSVMult = 0;
		rDamageOutput.sVal = "" .. (0 - nDamage);
		rDamageOutput.nVal = 0 - nDamage;
	else
		-- DETERMINE RANGE
		rDamageOutput.sRange = string.match(sDamageDesc, "%[DAMAGE %((%w)%)%]") or "";

		-- DETERMINE DAMAGE ENERGY TYPES
		rDamageOutput.aDamageTypes = {};
		local nDamageRemaining = nDamage;
		for sDamageType in string.gmatch(sDamageDesc, "%[TYPE: ([^%]]+)%]") do
			local sEnergyType = StringManager.trim(string.match(sDamageType, "^([^(%]]+)"));
			local sDice, sTotal = string.match(sDamageType, "%(([%d%+%-D]+)%=(%d+)%)");
			local nEnergyTypeTotal = tonumber(sTotal) or nDamageRemaining;

			if rDamageOutput.aDamageTypes[sEnergyType] then
				rDamageOutput.aDamageTypes[sEnergyType] = dmgtypes[sEnergyType] + nEnergyTypeTotal;
			else
				rDamageOutput.aDamageTypes[sEnergyType] = nEnergyTypeTotal;
			end

			nDamageRemaining = nDamageRemaining - nEnergyTypeTotal;
			if nDamageRemaining <= 0 then
				break;
			end
		end
		if nDamageRemaining > 0 then
			rDamageOutput.aDamageTypes[""] = nDamageRemaining;
		end
		
		-- DETERMINE DAMAGE TYPES
		rDamageOutput.aDamageFilter = {};
		if rDamageOutput.sRange == "M" then
			table.insert(rDamageOutput.aDamageFilter, "melee");
		elseif rDamageOutput.sRange == "R" then
			table.insert(rDamageOutput.aDamageFilter, "ranged");
		elseif rDamageOutput.sRange == "C" then
			table.insert(rDamageOutput.aDamageFilter, "close");
		elseif rDamageOutput.sRange == "A" then
			table.insert(rDamageOutput.aDamageFilter, "area");
		end
		
		-- DETERMINE WHETHER HALF DAMAGE SHOULD BE APPLIED FROM ATTACKER EFFECTS
		rDamageOutput.nHalf = 0;
		if string.match(sDamageDesc, "%[HALF%]") then
			rDamageOutput.nHalf = rDamageOutput.nHalf + 1;
		end
	end
	
	return rDamageOutput;
end

function applyDamage(rSource, rTarget, sDamage, nTotal)
	-- SETUP
	local nTotalHP = 0;
	local nTempHP = 0;
	local nWounds = 0;
	local nSurgeMax = 0;
	local nSurgeUsed = 0;
	local nHSV = 0;

	local aNotifications = {};
	
	-- GET HEALTH FIELDS
	if rTarget.sType == "pc" and rTarget.nodeCreature then
		nTotalHP = DB.getValue(rTarget.nodeCreature, "hp.total", 0);
		nTempHP = DB.getValue(rTarget.nodeCreature, "hp.temporary", 0);
		nWounds = DB.getValue(rTarget.nodeCreature, "hp.wounds", 0);
		nSurgeMax = DB.getValue(rTarget.nodeCreature, "hp.surgesmax", 0);
		nSurgeUsed = DB.getValue(rTarget.nodeCreature, "hp.surgesused", 0);
		nHSV = DB.getValue(rTarget.nodeCreature, "hp.surge", 0);
	elseif rTarget.nodeCT then
		nTotalHP = DB.getValue(rTarget.nodeCT, "hp", 0);
		nTempHP = DB.getValue(rTarget.nodeCT, "hptemp", 0);
		nWounds = DB.getValue(rTarget.nodeCT, "wounds", 0);

		if DB.getValue(rTarget.nodeCT, "type", "") == "pc" then
			nSurgeMax = DB.getValue(rTarget.nodeCT, "healsurgesmax", 0);
			nSurgeUsed = DB.getValue(rTarget.nodeCT, "healsurgesused", 0);
			nHSV = DB.getValue(rTarget.nodeCT, "healsurgeval", 0);
		else
			nSurgeMax = DB.getValue(rTarget.nodeCT, "healsurgeremaining", 0);
			nSurgeUsed = 0;
			nHSV = math.floor(nTotalHP / 4);
		end
	else
		return "";
	end
	
	-- DECODE DAMAGE DESCRIPTION
	local rDamageOutput = decodeDamageText(nTotal, sDamage);
	
	-- HEALING COST
	local bWounded = (nWounds > 0);
	local bApplyHealing = true;
	local bMinHeal = false;
	if rDamageOutput.sType == "heal" or rDamageOutput.sType == "temphp" then
		-- CHECK COST
		if rDamageOutput.nHealCost < 0 then
			if (rDamageOutput.nHealCost + nSurgeUsed) < 0 then
				table.insert(aNotifications, "[ALREADY AT MAX HEAL SURGES (+" .. (0 - (rDamageOutput.nHealCost + nSurgeUsed)) .. ")]");
			end
		elseif rDamageOutput.nHealCost > 0 then
			local nSurgesAvailable = nSurgeMax - nSurgeUsed;
			if rDamageOutput.nHealCost > nSurgesAvailable then
				table.insert(aNotifications, "[INSUFFICIENT HEAL SURGES (-" .. (rDamageOutput.nHealCost - nSurgesAvailable) .. ")]");

				if rDamageOutput.sType == "heal" then
					-- IF THIS IS REALLY A HEAL AND NOT HEALING SURGE DAMAGE, THEN APPLY MINIMUM HEAL
					if rDamageOutput.nHSVMult ~= 0 or rDamageOutput.nVal ~= 0 then
						if nWounds > nTotalHP then
							table.insert(aNotifications, "[MIN HEAL APPLIED]");
							rDamageOutput.nHealCost = 0;
							rDamageOutput.nHSVMult = 0;
							rDamageOutput.nVal = 1;
							bMinHeal = true;
						else
							bApplyHealing = false;
						end
					end
				else
					bApplyHealing = false;
				end
			end
			
			-- IF THIS IS HEAL SURGE DAMAGE, THEN ADJUST OUTPUT
			if rDamageOutput.nHSVMult == 0 and rDamageOutput.nVal == 0 then
				rDamageOutput.sTypeOutput = "Damage";
			end

			-- IF THE TARGET IS NOT WOUNDED, THEN DO NOT APPLY HEALING.
			if rDamageOutput.sType == "heal" then
				if not bMinHeal and not bWounded and ((rDamageOutput.nHSVMult > 0) or (rDamageOutput.nVal > 0)) then
					table.insert(aNotifications, "[NOT WOUNDED]");
					bApplyHealing = false;
				end
			end
		end
	end
	
	-- HEALING
	if rDamageOutput.sType == "heal" then
		if bApplyHealing then
			-- APPLY HEAL COST
			nSurgeUsed = nSurgeUsed + rDamageOutput.nHealCost;
			if nSurgeUsed > nSurgeMax then
				nSurgeUsed = nSurgeMax;
			elseif nSurgeUsed < 0 then
				nSurgeUsed = 0;
			end

			-- CALCULATE HEAL AMOUNT
			local nHealAmount = rDamageOutput.nVal + (rDamageOutput.nHSVMult * nHSV);
			
			-- APPLY HEALING
			if nHealAmount ~= 0 then
				if nWounds > nTotalHP then
					nWounds = nTotalHP
				end
				nWounds = nWounds - nHealAmount;
				if nWounds < 0 then
					nHealAmount = nHealAmount + nWounds;
					nWounds = 0;
				end
			end

			-- SET THE ACTUAL HEAL AMOUNT FOR DISPLAY
			rDamageOutput.nVal = nHealAmount;
			rDamageOutput.sVal = "" .. nHealAmount;
			if rDamageOutput.nHealCost ~= 0 then
				rDamageOutput.sVal = string.format("%s][HS%+d", rDamageOutput.sVal, -(rDamageOutput.nHealCost));
			end
		end

	-- TEMPORARY HIT POINTS
	elseif rDamageOutput.sType == "temphp" then
		if bApplyHealing then
			-- APPLY HEAL COST
			nSurgeUsed = nSurgeUsed + rDamageOutput.nHealCost;
			if nSurgeUsed > nSurgeMax then
				nSurgeUsed = nSurgeMax;
			elseif nSurgeUsed < 0 then
				nSurgeUsed = 0;
			end

			-- APPLY TEMPORARY HIT POINTS
			nTotal = nTotal + (rDamageOutput.nHSVMult * nHSV);
			nTempHP = math.max(nTempHP, nTotal);
		end

	-- DAMAGE
	else
		-- APPLY ANY TARGETED DAMAGE EFFECTS
		-- NOTE: DICE ARE RANDOMLY DETERMINED BY COMPUTER, INSTEAD OF ROLLED
		if rSource then
			local isCritical = string.match(sDamage, "%[CRITICAL%]");
			local aTargetedDamage = EffectsManager.getEffectsBonusByType(rSource, {"DMG"}, true, rDamageOutput.aDamageFilter, rTarget, true);

			local nDamageEffectTotal = 0;
			local nDamageEffectCount = 0;
			for k, v in pairs(aTargetedDamage) do
				local nSubTotal = StringManager.evalDice(v.dice, v.mod, isCritical);
				rDamageOutput.aDamageTypes[k] = (rDamageOutput.aDamageTypes[k] or 0) + nSubTotal;
				nDamageEffectTotal = nDamageEffectTotal + nSubTotal;
				nDamageEffectCount = nDamageEffectCount + 1;
			end
			nTotal = nTotal + nDamageEffectTotal;

			-- CAPTURE ANY TARGETED WEAKNESS EFFECTS
			if rDamageOutput.nHalf == 0 then
				if EffectsManager.hasEffect(rSource, "Weakened", rTarget, true) then
					rDamageOutput.nHalf = 1;
				end
			end
			
			if nDamageEffectCount > 0 then
				if nDamageEffectTotal ~= 0 then
					table.insert(aNotifications, string.format("[EFFECTS %+d]", nDamageEffectTotal));
				else
					table.insert(aNotifications, "[EFFECTS]");
				end
			end
		end
		
		-- APPLY ANY DAMAGE TYPE ADJUSTMENT EFFECTS
		local nDamageAdjust, bVulnerable, bResist, nHalf = getDamageAdjust(rSource, rTarget, nTotal, rDamageOutput);

		-- ADDITIONAL DAMAGE ADJUSTMENTS NOT RELATED TO DAMAGE TYPE
		local nAdjustedDamage = nTotal + nDamageAdjust;
		if nAdjustedDamage < 0 then
			nAdjustedDamage = 0;
		end
		if bResist then
			if nAdjustedDamage <= 0 then
				table.insert(aNotifications, "[RESISTED]");
			else
				table.insert(aNotifications, "[PARTIALLY RESISTED]");
			end
		end
		if bVulnerable then
			table.insert(aNotifications, "[VULNERABLE]");
		end
		if nHalf > 0 then
			if nHalf > 1 then
				table.insert(aNotifications, string.format("[HALF (x%d)]", nHalf));
			else
				table.insert(aNotifications, "[HALF]");
			end
		end
		
		-- REDUCE DAMAGE BY TEMPORARY HIT POINTS
		if nTempHP > 0 then
			if nAdjustedDamage > nTempHP then
				nAdjustedDamage = nAdjustedDamage - nTempHP;
				nTempHP = 0;
				table.insert(aNotifications, "[PARTIALLY ABSORBED]");
			else
				nTempHP = nTempHP - nAdjustedDamage;
				nAdjustedDamage = 0;
				table.insert(aNotifications, "[ABSORBED]");
			end
		end

		-- APPLY REMAINING DAMAGE
		if nAdjustedDamage > 0 then
			-- ADJUST WOUNDS VALUE
			local nOriginalWounds = nWounds;
			nWounds = nWounds + nAdjustedDamage;
			if nWounds < 0 then
				nWounds = 0;
			end

			-- ADD STATUS CHANGE NOTIFICATIONS
			local nBloodied = nTotalHP / 2;
			if (nOriginalWounds < nTotalHP) and (nWounds >= nTotalHP) then
				table.insert(aNotifications, "[DYING]");
			elseif (nOriginalWounds < nBloodied) and (nWounds >= nBloodied) then
				table.insert(aNotifications, "[BLOODIED]");
			end
			
			-- CHECK FOR IMPACT ON REGENERATION
			if rTarget.nodeCT then
				-- CALC WHICH DAMAGE TYPES ACTUALLY DID DAMAGE
				local aTempDamageTypes = {};
				local aActualDamageTypes = {};
				for k,v in pairs(rDamageOutput.aDamageTypes) do
					if v > 0 then
						table.insert(aTempDamageTypes, k);
					end
				end
				local aActualDamageTypes = StringManager.split(table.concat(aTempDamageTypes, ","), ",", true);
				
				-- CHECK THE TARGET'S EFFECTS FOR REGENERATION EFFECTS THAT MATCH
				for _,v in pairs(DB.getChildren(rTarget.nodeCT, "effects")) do
					local nActive = DB.getValue(v, "isactive", 0);
					if (nActive == 1) then
						local bMatch = false;
						local sLabel = DB.getValue(v, "label", "");
						local effect_list = EffectsManager.parseEffect(sLabel);
						for i = 1, #effect_list do
							-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
							if StringManager.contains({"AFTER", "FAIL"}, effect_list[i].type) then
								break;
							end

							if effect_list[i].type == "REGEN" then
								for _,v2 in pairs(effect_list[i].remainder) do
									if StringManager.contains(aActualDamageTypes, v2) then
										bMatch = true;
									end
								end
							end
							
							if bMatch then
								EffectsManager.disableEffect(rTarget.nodeCT, v);
							end
						end
					end
				end
			end
		end

		-- Update the damage output variable to reflect adjustments
		rDamageOutput.nVal = nAdjustedDamage;
		rDamageOutput.sVal = "" .. nAdjustedDamage;
	end

	-- SET HEALTH FIELDS
	if rTarget.sType == "pc" and rTarget.nodeCreature then
		DB.setValue(rTarget.nodeCreature, "hp.temporary", "number", nTempHP);
		DB.setValue(rTarget.nodeCreature, "hp.wounds", "number", nWounds);
		DB.setValue(rTarget.nodeCreature, "hp.surgesused", "number", nSurgeUsed);
	else
		DB.setValue(rTarget.nodeCT, "hptemp", "number", nTempHP);
		DB.setValue(rTarget.nodeCT, "wounds", "number", nWounds);

		if DB.getValue(rTarget.nodeCT, "type", "") == "pc" then
			DB.setValue(rTarget.nodeCT, "healsurgesused", "number", nSurgeUsed);
		else
			DB.setValue(rTarget.nodeCT, "healsurgeremaining", "number", nSurgeMax - nSurgeUsed);
		end
	end

	-- OUTPUT RESULTS
	messageDamage(rSource, rTarget, rDamageOutput.sTypeOutput, sDamage, rDamageOutput.sVal, table.concat(aNotifications, " "));
end

function messageDamage(rSource, rTarget, sDamageType, sDamageDesc, sTotal, sExtraResult)
	if not (rTarget or sExtraResult ~= "") then
		return;
	end
	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};

	if sDamageType == "Heal" or sDamageType == "Temporary hit points" then
		msgShort.icon = "indicator_heal";
		msgLong.icon = "indicator_heal";
	else
		msgShort.icon = "indicator_damage";
		msgLong.icon = "indicator_damage";
	end

	msgShort.text = sDamageType .. " ->";
	msgLong.text = sDamageType .. " [" .. sTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [to " .. rTarget.sName .. "]";
		msgLong.text = msgLong.text .. " [to " .. rTarget.sName .. "]";
	end
	
	if sExtraResult and sExtraResult ~= "" then
		msgLong.text = msgLong.text .. " " .. sExtraResult;
	end
	
	local bGMOnly = string.match(sDamageDesc, "^%[GM%]") or string.match(sDamageDesc, "^%[TOWER%]") ;
	ActionsManager.messageResult(bGMOnly, rSource, rTarget, msgLong, msgShort);
end
