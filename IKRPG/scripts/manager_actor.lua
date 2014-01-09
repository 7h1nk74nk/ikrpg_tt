-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--  DATA STRUCTURES
--
-- rActor
--		sType
--		sName
--		nodeCreature
--		sCreatureNode
--		nodeCT
-- 		sCTNode
--

function getActor(sActorType, varActor)
	-- GET ACTOR NODE
	local nodeActor = nil;
	if type(varActor) == "string" then
		if varActor ~= "" then
			nodeActor = DB.findNode(varActor);
		end
	elseif type(varActor) == "databasenode" then
		nodeActor = varActor;
	end
	if not nodeActor then
		return nil;
	end

	-- BASED ON ORIGINAL ACTOR NODE, FILL IN THE OTHER INFORMATION
	local rActor = nil;
	if sActorType == "ct" then
		rActor = {};
		rActor.sType = DB.getValue(nodeActor, "type", "npc");
		rActor.sName = DB.getValue(nodeActor, "name", "");
		rActor.nodeCT = nodeActor;
		
		local sClass,sRecord = DB.getValue(nodeActor, "link", "", "");
		if rActor.sType == "pc" and sClass == "charsheet" then
			rActor.nodeCreature = DB.findNode(sRecord);
			if rActor.nodeCreature then
				rActor.sName = DB.getValue(rActor.nodeCreature, "name", "");
			end
		elseif rActor.sType == "npc" and sClass == "npc" then
			rActor.nodeCreature = DB.findNode(sRecord);
		end

	elseif sActorType == "pc" then
		rActor = {};
		rActor.sType = "pc";
		rActor.nodeCreature = nodeActor;
		rActor.nodeCT = CTManager.getCTFromNode(nodeActor);
		rActor.sName = DB.getValue(rActor.nodeCreature, "name", "");

	elseif sActorType == "npc" then
		rActor = {};
		rActor.sType = "npc";
		rActor.nodeCreature = nodeActor;
		
		-- IF ACTIVE CT IS THIS NPC TYPE, THEN ASSOCIATE
		local nodeActiveCT = CTManager.getActiveCT();
		if nodeActiveCT then
			local _,sRecord = DB.getValue(nodeActiveCT, "link", "", "");
			if sRecord == nodeActor.getNodeName() then
				rActor.nodeCT = nodeActiveCT;
			end
		end
		-- OTHERWISE, ASSOCIATE WITH UNIQUE CT, IF POSSIBLE
		if not rActor.nodeCT then
			local bMatch = false;
			for _,nodeEntry in pairs(DB.getChildren("combattracker")) do
				local _,sRecord = DB.getValue(nodeEntry, "link", "", "");
				if sRecord == nodeActor.getNodeName() then
					if bMatch then
						rActor.nodeCT = nil;
						break;
					end
					
					rActor.nodeCT = nodeEntry;
					bMatch = true;
				end
			end
		end
		
		rActor.sName = DB.getValue(rActor.nodeCT or rActor.nodeCreature, "name", "");
	end
	
	-- TRACK THE NODE NAMES AS WELL
	if rActor.nodeCT then
		rActor.sCTNode = rActor.nodeCT.getNodeName();
	else
		rActor.sCTNode = "";
	end
	if rActor.nodeCreature then
		rActor.sCreatureNode = rActor.nodeCreature.getNodeName();
	else
		rActor.sCreatureNode = "";
	end
	
	-- RETURN ACTOR INFORMATION
	return rActor;
end

function getActorFromToken(token)
	local nodeCT = CTManager.getCTFromToken(token);
	if nodeCT then
		return getActor("ct", nodeCT.getNodeName());
	end
	
	return nil;
end

function getDropActors(sNodeType, nodename, draginfo)
	local rSource = decodeActors(draginfo);
	local rTarget = getActor(sNodeType, nodename);
	return rSource, rTarget;
end

function encodeActors(rSource, vTargets, bMultiTarget)
	-- SETUP
	local aCustom = {};

	-- ENCODE SOURCE ACTOR (CT, PC, NPC)
	if rSource then
		local sSourceType = "ct";
		local nodeSource = rSource.nodeCT;
		if not nodeSource then
			if rSource.sType == "pc" then
				sSourceType = "pc";
			elseif rSource.sType == "npc" then
				sSourceType = "npc";
			end
			nodeSource = rSource.nodeCreature;
		end
		if nodeSource then
			aCustom[sSourceType] = nodeSource;
		end
	end
	
	-- ENCODE TARGET ACTOR (CT, PC) (NO NPC TARGETING)
	if vTargets then
		local aTargets;
		if bMultiTarget then
			aTargets = vTargets;
		else
			aTargets = { vTargets };
		end
		
		local aCTTargetNodes = {};
		local aPCTargetNodes = {};
		for kTarget, rTarget in ipairs(aTargets) do
			if rTarget.nodeCT then
				table.insert(aCTTargetNodes, rTarget.nodeCT.getNodeName());
			elseif rTarget.sType == "pc" and rTarget.nodeCreature then
				table.insert(aPCTargetNodes, rTarget.nodeCreature.getNodeName());
			end
		end		

		aCustom["targetct"] = table.concat(aCTTargetNodes, "|");
		aCustom["targetpc"] = table.concat(aPCTargetNodes, "|");
	end

	-- RESULTS
	return aCustom;
end

function decodeActors(draginfo)
	-- SETUP
	local rSource = nil;
	local aTargets = {};

	-- CHECK FOR DRAG INFORMATION
	if draginfo then
		local varCustom = draginfo.getCustomData();

		-- CHECK FOR CUSTOM DATA
		if varCustom then
			-- GET CUSTOM SOURCE ACTOR
			if varCustom["ct"] then
				rSource = getActor("ct", varCustom["ct"]);
			elseif varCustom["pc"] then
				rSource = getActor("pc", varCustom["pc"]);
			elseif varCustom["npc"] then
				rSource = getActor("npc", varCustom["npc"]);
			end
			
			-- GET CUSTOM TARGET ACTOR
			if varCustom["targetct"] then
				local aTargetNodeNames = StringManager.split(varCustom["targetct"], "|");
				for _,vName in ipairs(aTargetNodeNames) do
					local rTarget = getActor("ct", vName);
					if rTarget then
						table.insert(aTargets, rTarget);
					end
				end
			end
			if varCustom["targetpc"] then
				local aTargetNodeNames = StringManager.split(varCustom["targetpc"], "|");
				for _,vName in ipairs(aTargetNodeNames) do
					local rTarget = getActor("pc", vName);
					if rTarget then
						table.insert(aTargets, rTarget);
					end
				end
			end
		end

		-- IF NO CUSTOM DATA FOR SOURCE, THEN TRY THE SHORTCUT DATA
		if not rSource then
			-- GET SHORTCUT SOURCE ACTOR
			local sRefClass, sRefNode = draginfo.getShortcutData();
			if sRefClass and sRefNode then
				if sRefClass == "combattracker_entry" then
					rSource = getActor("ct", sRefNode);

				elseif sRefClass == "charsheet" then
					rSource = getActor("pc", sRefNode);

				elseif sRefClass == "npc" then
					rSource = getActor("npc", sRefNode);
				end
			end
		end
	end
	
	-- RESULTS
	return rSource, aTargets;
end

function getPercentWounded(sNodeType, node)
	local nHP = 0;
	local nWounds = 0;
	
	if sNodeType == "ct" then
		nHP = DB.getValue(node, "hp", 0);
		nWounds = DB.getValue(node, "wounds", 0);
	elseif sNodeType == "pc" then
		nHP = DB.getValue(node, "hp.total", 0);
		nWounds = DB.getValue(node, "hp.wounds", 0)
	end
	
	local nPercentWounded = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / nHP;
	end
	
	local sStatus;
	if OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded <= 0 then
			sStatus = "Healthy";
		elseif nPercentWounded < .25 then
			sStatus = "Light";
		elseif nPercentWounded < .5 then
			sStatus = "Moderate";
		elseif nPercentWounded < .75 then
			sStatus = "Bloodied";
		elseif nPercentWounded < 1 then
			sStatus = "Critical";
		elseif nPercentWounded < 1.5 then
			sStatus = "Dying";
		else
			sStatus = "Dead";
		end
	else
		if nPercentWounded <= 0 then
			sStatus = "Healthy";
		elseif nPercentWounded < .5 then
			sStatus = "Wounded";
		elseif nPercentWounded < 1 then
			sStatus = "Bloodied";
		elseif nPercentWounded < 1.5 then
			sStatus = "Dying";
		else
			sStatus = "Dead";
		end
	end

	return nPercentWounded, sStatus;
end

function getWoundColor(sNodeType, node)
	local nPercentWounded, sStatus = getPercentWounded(sNodeType, node);
	
	-- Based on the percent wounded, change the font color for the Wounds field
	local sColor;
	if OptionsManager.isOption("WNDC", "detailed") then
		if nPercentWounded >= 1 then
			sColor = "404040";
		elseif nPercentWounded >= 0.75 then
			sColor = "C11B17";
		elseif nPercentWounded >= 0.5 then
			sColor = "E56717";
		elseif nPercentWounded >= 0.25 then
			sColor = "AF7817";
		elseif nPercentWounded > 0 then
			sColor = "408000";
		else
			sColor = "006600";
		end
	else
		if nPercentWounded >= 1 then
			sColor = "404040";
		elseif nPercentWounded >= 0.5 then
			sColor = "C11B17";
		elseif nPercentWounded > 0 then
			sColor = "408000";
		else
			sColor = "006600";
		end
	end

	return sColor, nPercentWounded, sStatus;
end

function getWoundBarColor(sNodeType, node)
	local nPercentWounded, sStatus = getPercentWounded(sNodeType, node);
	
	local nRedR = 255;
	local nRedG = 0;
	local nRedB = 0;
	local nYellowR = 255;
	local nYellowG = 191;
	local nYellowB = 0;
	local nGreenR = 0;
	local nGreenG = 255;
	local nGreenB = 0;
	
	local sColor;
	if nPercentWounded > 1 then
		sColor = "C0C0C0";
	else
		local nBarR, nBarG, nBarB;
		if nPercentWounded >= 0.5 then
			local nPercentGrade = (nPercentWounded - 0.5) * 2;
			nBarR = math.floor((nRedR * nPercentGrade) + (nYellowR * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((nRedG * nPercentGrade) + (nYellowG * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((nRedB * nPercentGrade) + (nYellowB * (1.0 - nPercentGrade)) + 0.5);
		else
			local nPercentGrade = nPercentWounded * 2;
			nBarR = math.floor((nYellowR * nPercentGrade) + (nGreenR * (1.0 - nPercentGrade)) + 0.5);
			nBarG = math.floor((nYellowG * nPercentGrade) + (nGreenG * (1.0 - nPercentGrade)) + 0.5);
			nBarB = math.floor((nYellowB * nPercentGrade) + (nGreenB * (1.0 - nPercentGrade)) + 0.5);
		end
		sColor = string.format("%02X%02X%02X", nBarR, nBarG, nBarB);
	end

	return sColor, nPercentWounded, sStatus;
end

function getAbilityScore(rActor, sAbility)
	if not rActor or not rActor.nodeCreature or not sAbility then
		return -1;
	end
	
	local nStatScore = -1;
	
	local sShort = string.sub(string.lower(sAbility), 1, 3);
	if rActor.sType == "npc" then
		if sShort == "lev" then
			nStatScore = tonumber(string.match(DB.getValue(rActor.nodeCreature, "levelrole", ""), "Level (%d*)")) or 0;
		elseif sShort == "phy" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Physique", 0);
		elseif sShort == "spe" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Speed", 0);
		elseif sShort == "str" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Strength", 0);
		elseif sShort == "agi" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Agility", 0);
		elseif sShort == "pro" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Prowess", 0);
		elseif sShort == "poi" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Poise", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Intellect", 0);
		elseif sShort == "arc" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Arcane", 0);
		elseif sShort == "per" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Perception", 0);
		elseif sShort == "wil" then
			nStatScore = DB.getValue(rActor.nodeCreature, "Willpower", 0);
		end
	elseif rActor.sType == "pc" then
		if sShort == "lev" then
			nStatScore = DB.getValue(rActor.nodeCreature, "level", 0);
		elseif sShort == "phy" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.phy.score", 0);
		elseif sShort == "spe" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.spd.score", 0);
		elseif sShort == "str" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.str.score", 0);
		elseif sShort == "agi" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.agi.score", 0);
		elseif sShort == "pro" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.prw.score", 0);
		elseif sShort == "poi" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.poi.score", 0);
		elseif sShort == "int" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.int.score", 0);
		elseif sShort == "arc" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.arc.score", 0);
		elseif sShort == "per" then
			nStatScore = DB.getValue(rActor.nodeCreature, "stats.per.score", 0);
		elseif sShort == "wil" then
			nStatScore = DB.getValue(rActor.nodeCreature, "willpower", 0);
		end
	end
	
	return nStatScore;
end

function getAbilityBonus(rActor, sAbility)
	-- VALIDATE
	if not rActor or not rActor.nodeCreature or not sAbility then
		return 0;
	end
	
	-- SETUP
	local sStat = sAbility;
	local bHalf = false;
	local bDouble = false;
	local nStatVal = 0;
	
	-- HANDLE HALF/DOUBLE MODIFIERS
	if string.match(sStat, "^half") then
		bHalf = true;
		sStat = string.sub(sStat, 5);
	end
	if string.match(sStat, "^double") then
		bDouble = true;
		sStat = string.sub(sStat, 7);
	end

	-- GET ABILITY VALUE
	local nStatScore = getAbilityScore(rActor, sStat);
	if nStatScore < 0 then
		return 0;
	end
	
	if StringManager.contains(DataCommon.abilities, sStat) then
		nStatVal = nStatScore
		if rActor.sType == "pc" then
			nStatVal = nStatVal + DB.getValue(rActor.nodeCreature, "stats" .. sStat .. "stats", 0);
		end
	else
		nStatVal = nStatScore;
	end
	
	-- APPLY HALF/DOUBLE MODIFIERS
	if bDouble then
		nStatVal = nStatVal * 2;
	end
	if bHalf then
		nStatVal = math.floor(nStatVal / 2);
	end

	-- RESULTS
	return nStatVal;
end

function getDefenseInternal(sDefense)
	local sInternal = "";
	
	if sDefense then
		local sShortDef = string.sub(string.lower(sDefense), 1, 2);
		if sShortDef == "de" then
			sInternal = "def";
		elseif sShortDef == "ar" then
			sInternal = "arm";
		elseif sShortDef == "wi" then
			sInternal = "will";
		end
	end
	
	return sInternal;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	-- VALIDATE
	if not rDefender or not rRoll then
		return nil, 0, 0;
	end
	
	local sAttack = rRoll.sDesc;

	-- DETERMINE ATTACK TYPE AND DEFENSE
	local sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]");
	local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]");
	local sDefense = string.match(sAttack, "%(vs%.? (%a+)%)");
	if not sDefense then
		return nil, 0, 0;
	end
	sDefense = getDefenseInternal(sDefense);
	if sDefense == "" then
		return nil, 0, 0;
	end

	-- Determine the defense database node name
	local nDefense = 10;
	if rDefender.nodeCT then
		nDefense = DB.getValue(rDefender.nodeCT, sDefense, 10);
	elseif rDefender.nodeCreature then
		if rDefender.sType == "pc" then
			nDefense = DB.getValue(rDefender.nodeCreature, "defenses." .. sDefense .. ".total", 10);
		else
			nDefense = DB.getValue(rDefender.nodeCreature, sDefense, 10);
		end
	else
		return nil, 0, 0;
	end

	-- EFFECT MODIFIERS
	local nAttackEffectMod = 0;
	local nDefenseEffectMod = 0;
	if rDefender.nodeCT then
		-- SETUP
		local bCombatAdvantage = false;
		local bUncannyDodge = false;
		local bCheckCA = true;
		local nBonusAllDefenses = 0;
		local nBonusSpecificDefense = 0;
		local nBonusSituational = 0;
		
		-- BUILD ATTACK FILTER 
		local aAttackFilter = {};
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee");
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged");
		elseif sAttackType == "C" then
			table.insert(aAttackFilter, "close");
		elseif sAttackType == "A" then
			table.insert(aAttackFilter, "area");
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity");
		end

		-- GET ATTACKER BASE MODIFIER
		local aBonusTargetedAttackDice = {};
		local nBonusTargetedAttack = 0;
		if rAttacker then
			aBonusTargetedAttackDice, nBonusTargetedAttack = EffectsManager.getEffectsBonus(rAttacker, "ATK", false, aAttackFilter, rDefender, true);
		end
		nAttackEffectMod = nAttackEffectMod + StringManager.evalDice(aBonusTargetedAttackDice, nBonusTargetedAttack);
			
		-- GET ATTACKER SITUATIONAL MODIFIERS
		-- AND CHECK WHETHER COMBAT ADVANTAGE HAS ALREADY BEEN APPLIED
		if EffectsManager.hasEffectCondition(rDefender, "Uncanny Dodge") then
			bUncannyDodge = true;
			bCheckCA = false;
		end
		if string.match(sAttack, "%[CA%]") then
			bCheckCA = false;
			if bUncannyDodge then
				nBonusSituational = nBonusSituational + 2;
			end
		end
		if bCheckCA then
			if EffectsManager.hasEffect(rAttacker, "CA", rDefender, true) or 
					EffectsManager.hasEffect(rAttacker, "Invisible", rDefender, true) then
				bCombatAdvantage = true;
			end
		end
		
		-- GET DEFENDER ALL DEFENSE MODIFIERS
		nBonusAllDefenses = EffectsManager.getEffectsBonus(rDefender, "DEF", true, aAttackFilter, rAttacker);
		
		-- GET DEFENDER SPECIFIC DEFENSE MODIFIERS
		if sDefense == "DEF" then
			nBonusSpecificDefense = EffectsManager.getEffectsBonus(rDefender, "DEF", true, aAttackFilter, rAttacker);
		elseif sDefense == "ARM" then
			nBonusSpecificDefense = EffectsManager.getEffectsBonus(rDefender, "ARM", true, aAttackFilter, rAttacker);
		elseif sDefense == "will" then
			nBonusSpecificDefense = EffectsManager.getEffectsBonus(rDefender, "WILL", true, aAttackFilter, rAttacker);
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - COMBAT ADVANTAGE
		if bCheckCA then
			-- CHECK ALL THE CONDITIONS THAT COULD GRANT COMBAT ADVANTAGE
			if EffectsManager.hasEffect(rDefender, "GRANTCA", rAttacker) then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Blinded") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Dazed") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Dominated") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Helpless") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Prone") and (sAttackType == "M") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Restrained") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Stunned") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Surprised") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Unconscious") then
				bCombatAdvantage = true;
			end
			
			-- CHECK ALL THE OTHER EFFECTS THAT COULD GRANT COMBAT ADVANTAGE
			if EffectsManager.hasEffectCondition(rDefender, "Balancing") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Climbing") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Running") then
				bCombatAdvantage = true;
			elseif EffectsManager.hasEffectCondition(rDefender, "Squeezing") then
				bCombatAdvantage = true;
			end

			-- APPLY COMBAT ADVANTAGE AS DEFENSE PENALTY
			if bCombatAdvantage then
				nBonusSituational = nBonusSituational - 2;
			end
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - CONDITIONS
		if EffectsManager.hasEffectCondition(rDefender, "Prone") and (sAttackType == "R") then
			nBonusSituational = nBonusSituational + 2;
		end
		if EffectsManager.hasEffectCondition(rDefender, "Unconscious") then
			nBonusSituational = nBonusSituational - 5;
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - CONCEALMENT
		if sAttackType and (sAttackType == "M" or sAttackType == "R") then
			local bCheckConceal = true;
			if string.match(sAttack, "%[BLINDED%]") then
				bCheckConceal = false;
			end
			if bCheckConceal then
				local bTotalConceal = false;
				local bConceal = false;
				
				if string.match(sAttack, "%[TCONC%]") then
					bTotalConceal = true;
				elseif string.match(sAttack, "%[CONC%]") then
					bConceal = true;
				end
				
				if not bTotalConceal then
					if EffectsManager.hasEffect(rDefender, "Invisible", rAttacker) then
						bTotalConceal = true;
					elseif EffectsManager.hasEffect(rAttacker, "Blinded", rDefender, true) and StringManager.isWord(sAttackType, {"M", "R"}) then
						bTotalConceal = true;
					else
						local aConcealment = EffectsManager.getEffectsByType(rDefender, "TCONC", aAttackFilter, rAttacker);
						if #aConcealment > 0 or EffectsManager.hasEffect(rDefender, "TCONC", rAttacker) then
							bTotalConceal = true;
						elseif not bConceal then
							aConcealment = EffectsManager.getEffectsByType(rDefender, "CONC", aAttackFilter, rAttacker);
							if #aConcealment > 0 or EffectsManager.hasEffect(rDefender, "CONC", rAttacker) then
								bConceal = true;
							end
						end
					end
				end
			
				if bTotalConceal then
					nBonusSituational = nBonusSituational + 5;
				elseif bConceal then
					nBonusSituational = nBonusSituational + 2;
				end
			end
		end
		
		-- GET DEFENDER SITUATIONAL MODIFIERS - COVER
		local bSuperiorCover = false;
		local bCover = false;
		if string.match(sAttack, "%[SCOVER%]") then
			bSuperiorCover = true;
		elseif string.match(sAttack, "%[COVER%]") then
			bCover = true;
		end
				
		if not bSuperiorCover then
			local aCover = EffectsManager.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker);
			if #aCover > 0 or EffectsManager.hasEffect(rDefender, "SCOVER", rAttacker) then
				bSuperiorCover = true;
			elseif not bCover then
				aCover = EffectsManager.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker);
				if #aCover > 0 or EffectsManager.hasEffect(rDefender, "COVER", rAttacker) then
					bCover = true;
				end
			end
		end
		
		if bSuperiorCover then
			nBonusSituational = nBonusSituational + 5;
		elseif bCover then
			nBonusSituational = nBonusSituational + 2;
		end
		
		-- ADD IN EFFECT MODIFIERS
		nDefenseEffectMod = nBonusAllDefenses + nBonusSpecificDefense + nBonusSituational;
	end
	
	-- Return the final defense value
	return nDefense + nDefenseEffectMod - nAttackEffectMod, nAttackEffectMod, nDefenseEffectMod;
end

function getSave(rActor)
	if rActor then
		if rActor.sType == "pc" then
			return DB.getValue(rActor.nodeCreature, "defenses.save.total", 0);
		elseif rActor.sType == "ct" or rActor.sType == "npc" then
			return DB.getValue(rActor.nodeCreature, "save", 0);
		end
	end
	
	return 0;
end
