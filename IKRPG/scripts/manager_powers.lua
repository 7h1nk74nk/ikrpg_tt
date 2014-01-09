-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

---- HELPER FUNCTIONS 

function getAbility(s)
	local statval = "";
	if s == "str" or s == "strength" then
		statval = "strength";
	elseif s == "con" or s == "constitution" then
		statval = "constitution";
	elseif s == "dex" or s == "dexterity" then
		statval = "dexterity";
	elseif s == "int" or s == "intelligence" then
		statval = "intelligence";
	elseif s == "wis" or s == "wisdom" then
		statval = "wisdom";
	elseif s == "cha" or s == "charisma" then
		statval = "charisma";
	end
	return statval;
end

function getDefense(s)
	local defense = "";
	if s == "ac" then
		defense = "ac";
	elseif s == "fort" or s == "fortitude" then
		defense = "fortitude";
	elseif s == "ref" or s == "reflex" then
		defense = "reflex";
	elseif s == "will" then
		defense = "will";
	end
	return defense;
end

function parseValuePhrase(words, index)
	-- SETUP
	local rValue = { nIndex = index, aDice = {}, aAbilities = {} };
	local sModifier = nil;

	-- ITERATE
	local j = index;
	while words[j] do
		-- LOCATE DICE AND ABILITY TERMS AND MODIFIERS
		local sTempAbility = "";
		if StringManager.isWord(words[j], {"your", "his", "her"}) then
			-- SKIP
		elseif StringManager.isWord(words[j], "or") then
			rValue.bOrFlag = true;
		elseif StringManager.isWord(words[j], "+") then
			if sModifier then
				break;
			end
		elseif StringManager.isWord(words[j], "twice") then
			if sModifier then
				break;
			end
			sModifier = "double";
		elseif StringManager.isWord(words[j], {"one-half", "half"}) then
			if sModifier then
				break;
			end
			sModifier = "half";
		elseif StringManager.isWord(words[j], "healing") and 
				StringManager.isWord(words[j+1], "surge") and StringManager.isWord(words[j+2], "value") then
			sTempAbility = "hsv";
			rValue.nIndex = j + 2;
			j = j + 2;
		elseif StringManager.isWord(words[j], "level") then
			sTempAbility = "level";
		elseif StringManager.isDiceString(words[j]) then
			if sModifier then
				break;
			end
			table.insert(rValue.aDice, words[j]);
			rValue.nIndex = j;
		else
			sTempAbility = getAbility(words[j]);
			if sTempAbility ~= "" then
				if StringManager.isWord(words[j+1], "modifier") then
					j = j + 1;
				end
			else
				break;
			end
		end
		
		-- ADD ABILITY TERMS
		if sTempAbility ~= "" then
			if sModifier then
				sTempAbility = sModifier .. sTempAbility;
				sModifier = nil;
			end
			
			table.insert(rValue.aAbilities, sTempAbility);
			rValue.nIndex = j;
		end
	
		-- INCREMENT
		j = j + 1;
	end
	
	-- CLEAR VALUE VARIABLE, IF NOTHING FOUND
	if (#(rValue.aDice) == 0) and (#(rValue.aAbilities) == 0) then
		rValue = nil;
	end
	
	-- RESULTS
	return rValue;
end

--
-- ATTACKS
--

-- Form [PHB]: <stat> vs. <defense>
-- Form [PHB]: <stat> + <bonus> vs. <defense>
-- Form [PHB]: <stat> - <penalty> vs. <defense>
-- Form [MM ]: +<bonus> vs. <defense>
-- Form [MM ]: -<penalty> vs. <defense>
function parseAttacks(words)
	-- Start with an empty set
	local attacks = {};
	local bAttackContinuationAllowed = false;

  	-- Iterate through the words looking for attack clauses
  	for i = 1, #words do
  		-- Our main trigger is the "vs" in the defense part of the clause
  		if StringManager.isWord(words[i], "vs") and i > 1 then

  			-- Calculate the attack stat, bonus and defense
  			local atk_starts = i;
  			
  			-- ONE OFF (PHB - Valiant Strike)
  			if StringManager.isWord(words[atk_starts-1], "you") and StringManager.isWord(words[atk_starts-2], "to") and
  					StringManager.isWord(words[atk_starts-3], "adjacent") and StringManager.isWord(words[atk_starts-4], "enemy") and
  					StringManager.isWord(words[atk_starts-5], "per") then
  				atk_starts = atk_starts - 5;
  			end
  			
  			local atk_stat = "";
  			local atk_bonus = tonumber(words[atk_starts-1]);
  			if atk_bonus then
  				atk_starts = atk_starts - 1;
  				
  				local temp_index = atk_starts - 1;
  				if StringManager.isWord(words[temp_index], "+") then
					temp_index = temp_index - 1;
				elseif StringManager.isWord(words[temp_index], "-") then
					atk_bonus = 0 - atk_bonus;
					temp_index = temp_index - 1;
				end
				
				atk_stat = getAbility(words[temp_index]);
				if atk_stat ~= "" then
					atk_starts = temp_index;
				end
  			else
  				atk_stat = getAbility(words[atk_starts-1]);
  				atk_bonus = 0;
  				atk_starts = atk_starts - 1;

  				-- ONE OFF (PHB - Eldritch Blast)
  				if StringManager.isWord(words[atk_starts-1], "or") and (getAbility(words[atk_starts-2]) ~= "") then
  					atk_stat = "";
  					atk_starts = atk_starts - 2;
  				end
  			end
  			
  			local atk_ends = i;
  			if StringManager.isWord(words[atk_ends + 1], ".") then
  				atk_ends = atk_ends + 1;
  			end

  			local atk_defense = {};
  			local j = atk_ends + 1;
  			while words[j] do
  				if StringManager.isWord(words[j], "the") then
  					-- SKIP - ONE OFF (PHB - Dispel Magic)
  				else
					local local_defense = getDefense(words[j]);
					if local_defense == "" then
						break;
					end
					table.insert(atk_defense, local_defense);
				end

  				j = j + 1;
  			end
  			atk_ends = j - 1;

			-- If the defense checks out, then we have a viable attack clause
			if #atk_defense > 0 then
				local atk_statarray = {};
				if atk_stat ~= "" then
					table.insert(atk_statarray, atk_stat);
				end
				
				local rAttack = {};
				rAttack.startindex = atk_starts;
				rAttack.endindex = atk_ends;
				if #atk_defense == 1 then
					rAttack.defense = atk_defense[1];
				else
					rAttack.defense = "";
				end
				rAttack.clauses = { { stat = atk_statarray, mod = atk_bonus } } ;
				
				table.insert(attacks, rAttack);
				
				if rAttack.clauses[1].mod ~= 0 then
					bAttackContinuationAllowed = true;
				end
				
				i = atk_ends;
			end

  		elseif bAttackContinuationAllowed and StringManager.isWord(words[i], "increase") and 
  				StringManager.isWord(words[i+1], "to") then
  			local nStartAttack = i;
  			local j = i + 2;
  			local bContinuation = true;
  			while bContinuation do
  				bContinuation = false;
  				
  				if StringManager.isNumberString(words[j]) then
					local rAttack = {};
					rAttack.startindex = nStartAttack;
					rAttack.endindex = j;
					if StringManager.isWord(words[rAttack.endindex + 1], "bonus") then
						rAttack.endindex = rAttack.endindex + 1;
					end
					rAttack.defense = attacks[#attacks].defense;
					
					local aAttackStat = attacks[#attacks].clauses[1].stat;
					local nAttackBonus = tonumber(words[j]) or 0;
					rAttack.clauses = { { stat = aAttackStat, mod = nAttackBonus } };
					
					-- CHECK FOR FOLLOW-ON CONTINUATIONS
					if StringManager.isWord(words[rAttack.endindex+1], "at") and 
							words[rAttack.endindex+2] and string.match(words[rAttack.endindex+2], "^%d?%d[st][th]$") and
							StringManager.isWord(words[rAttack.endindex+3], "level") then

						bContinuation = true;
						rAttack.endindex = rAttack.endindex + 3;

						nStartAttack = rAttack.endindex + 1;
						j = nStartAttack;
						if StringManager.isWord(words[j], "and") then
							j = j + 1;
						end
						if StringManager.isWord(words[j], "to") then
							j = j + 1;
						end
					end

					table.insert(attacks, rAttack);
					
					i = rAttack.endindex;
  				end
  			end
  		end
	end
	
	-- Return the set of clauses found in the string
	return attacks;
end

-- <dice> = [<#d#+#>, <#d#>, <#>]
-- <etype> = ["and", <energy type>]*
-- <statmod> = ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma", "str", "dex", "con", "int", "wis", "cha"] ["modifier"]?
-- <mult> = <#>
--
-- Form [PHB]: <dice> <etype> damage
-- Form [PHB]: <dice> + <statmod> <etype> damage
-- Form [PHB]: <dice> + <statmod> + <statmod> <etype> damage
-- Form [PHB]: <mult>[W] <etype> damage
-- Form [PHB]: <mult>[W] + <statmod> <etype> damage
-- Form [PHB]: <mult>[W] + <statmod> + <statmod> <etype> damage
-- Form [PHB2]: <mult>[W] + <dice> + <statmod> <etype> damage
-- Form [MM]: <dice> <etype> damage
-- Form [MM]: <dice> <etype> damage crit <dice>
-- Form [MM2]: <dice> crit <dice> <etype> damage
function parseDamageClause(words, damage_index, inclusive_flag)

	-- SETUP VARIABLES
	local dmg_startindex = damage_index;
	local dmg_endindex = 0;
	if inclusive_flag then
		dmg_endindex = damage_index;
	else
		dmg_endindex = damage_index - 1;
	end

	local dmg_dice = {};
	local dmg_weaponmult = 0;
	local dmg_abilities = {};
	local dmg_types = {};

	local isweapon = false;
	local numberflag = false;
	local extraflag = false;
	local plusflag = false;
	local ongoingflag = false;
	local orflag = false;

	-- Go backwards through words to find the parts of the damage clause
	local j = damage_index - 1;
	while j > 0 do
		local skip_flag = StringManager.isWord(words[j], {"and", "modifier", "your", "as", "critical"});
		
		-- Skip null words
		if skip_flag then
		
		elseif StringManager.isWord(words[j], "or") then
			orflag = true;
		
		-- Plus or minus sign will reset number flag
		elseif StringManager.isWord(words[j], {"+", "-"}) then
			numberflag = false;

		-- Check for weapon damage clauses
		elseif StringManager.isWord(words[j], "w") then
			isweapon = true;

		-- Check to see if this is crit damage
		-- If so, then ignore since it should have already been processed
		elseif StringManager.isWord(words[j], "crit") then
			return damage_index, nil;
		
		-- Check to see if this is plus damage
		elseif StringManager.isWord(words[j], "plus") then
			if ongoingflag then
				break;
			end
			plusflag = true;
			extraflag = false;
		
		-- Check to see if this is extra damage
		elseif StringManager.isWord(words[j], {"extra", "additional"}) then
			extraflag = true;
		
		-- Check to see if this is ongoing damage
		elseif StringManager.isWord(words[j], "ongoing") then
			ongoingflag = true;
		
		-- Check for damage types
		elseif StringManager.isWord(words[j], DataCommon.dmgtypes) then
			table.insert(dmg_types, 1, words[j]);

		-- Check for dice string
		elseif StringManager.isDiceString(words[j]) then

			local dicestr = words[j];

			-- Not allowed to have 2 number/dice phrases in a row without a '+' or '-' in-between
			if numberflag then
				break;
			end
			numberflag = true;

			-- Catch weapon multiplier if we just found a [W]
			if isweapon then
				-- Check for leading plus sign
				if string.sub(dicestr, 1, 1) == "+" then
					extraflag = true;
				end
				dmg_weaponmult = tonumber(dicestr) or 0;
			-- Otherwise, we have a dice string or numbers
			else
				-- Strip leading plus sign
				if string.sub(dicestr, 1, 1) == "+" then
					dicestr = string.sub(dicestr, 2);
					extraflag = true;
				end

				-- Handle negatives
				if StringManager.isWord(words[j-1], "-") then
					dicestr = "-" .. dicestr;
					j = j - 1;
				end

				-- Add to the dice string list
				table.insert(dmg_dice, 1, dicestr);
			end

		-- Otherwise process the damage clause
		else
			-- Look for ability keywords
			local abilitystr = getAbility(words[j]);
			if abilitystr ~= "" then
				if StringManager.isWord(words[j-1], "half") then
					abilitystr = "half" .. abilitystr;
					j = j - 1;
				end
				table.insert(dmg_abilities, 1, abilitystr);

			-- Otherwise, we're done searching backwards
			else
				if StringManager.isWord(words[j+1], "or") then
					orflag = false;
				end
				break;
			end
			
		end
		
		-- UPDATE START POSITION
		if skip_flag then
		elseif StringManager.isWord(words[j], "or") then
		else
			dmg_startindex = j;
		end

		-- DECREMENT INDEX
		j = j - 1;
	end

	-- Check for a critical clause
	-- Does not support weapon clauses, or ability clauses (only for fixed dice + modifier crit clauses)
	local crit_index = nil;
	local crit_dice = {};
	if (not StringManager.isWord(words[damage_index], "plus")) and 
			(StringManager.isWord(words[damage_index], "crit") or StringManager.isWord(words[damage_index+1], "crit")) then
		local crit_types = {};
		local critj = damage_index + 1;
		local crit_index = critj;
		local critorflag = false;
		numberflag = false;
		if StringManager.isWord(words[critj], "crit") then
			critj = critj + 1;
		end
		while words[critj] do
			-- Skip null words
			if StringManager.isWord(words[critj], "and") then
			
			elseif StringManager.isWord(words[critj], "or") then
				critorflag = true;
			
			-- Plus or minus sign will reset number flag
			elseif StringManager.isWord(words[critj], {"+", "-"}) then
				numberflag = false;

			-- Look for damage types
			elseif StringManager.isWord(words[critj], DataCommon.dmgtypes) then
				table.insert(crit_types, 1, words[critj]);
				crit_index = critj;

			-- Basic dice string checks
			elseif StringManager.isDiceString(words[critj]) then

				local dicestr = words[critj];

				-- Not allowed to have 2 number/dice phrases in a row without a '+' or '-' in-between
				if numberflag then
					break;
				end
				numberflag = true;

				-- Strip leading plus sign
				if string.sub(dicestr, 1, 1) == "+" then
					dicestr = string.sub(dicestr, 2);
				end

				-- Handle negatives
				if (critj > 2) and StringManager.isWord(words[critj], "-") then
					dicestr = "-" .. dicestr;
				end

				-- Add to the dice string list
				table.insert(crit_dice, 1, dicestr);
				crit_index = critj;

			else			
				if StringManager.isWord(words[critj], "damage") then
					crit_index = critj;
				end
				if StringManager.isWord(words[critj - 1], "or") then
					critorflag = false;
				end
				break;
			end
			
			-- Increment word counter
			critj = critj + 1;
		end
		
		-- Check to see if we found a crit phrase
		if #crit_dice > 0 then
			-- Set the index to the new value
			damage_index = critj - 1;
			dmg_endindex = crit_index;
			if critorflag then
				orflag = true;
			end
		
			-- Add the crit damage type to the existing damage type
			-- NOTE: We assume that damage type is the same for crit and regular damage
			-- Assumption holds true for crit phrases in MM and MM2
			for k,v in pairs(crit_types) do
				local found = false;
				for k2, v2 in pairs(dmg_types) do
					if v == v2 then
						found = true;
					end
				end
				if not found then
					table.insert(dmg_types, 1, v);
				end
			end
		end
	end

	-- Clear damage if we found a damage choice clause
	if orflag then
		dmg_types = {};
		dmg_abilities = {};
	end

	-- ONE OFF (PHB - ASTRAL VIBRANCE)
	if StringManager.isWord(words[dmg_endindex+1], "of") and StringManager.isWord(words[dmg_endindex+2], "your") and
			StringManager.isWord(words[dmg_endindex+3], "chosen") and StringManager.isWord(words[dmg_endindex+4], "type") then
		dmg_endindex = dmg_endindex + 4;
	end
	
	-- Check for "equal to" damage clauses
	local equal_index = nil;
	if #dmg_dice == 0 and #dmg_abilities == 0 then
		if StringManager.isWord(words[dmg_endindex+1], "equal") and StringManager.isWord(words[dmg_endindex+2], "to") then
			local rValue = parseValuePhrase(words, dmg_endindex + 3);
			if rValue then
				equal_index = rValue.nIndex;
				dmg_endindex = rValue.nIndex;
				dmg_dice = rValue.aDice;
				dmg_abilities = rValue.aAbilities;
			end
		end
	end

	-- Make sure we have a damage clause, and insert it into table
	if #dmg_dice > 0 or dmg_weaponmult ~= 0 or #dmg_abilities > 0 then

		local dmgtypestr = table.concat(dmg_types, ",");
		local dicestr = table.concat(dmg_dice, "+");
		dicestr = string.gsub(dicestr,"%+%-","-");
		local critdicestr = table.concat(crit_dice, "+");
		critdicestr = string.gsub(critdicestr,"%+%-","-");

		if crit_index then
			damage_index = crit_index;
		end
		if equal_index then
			damage_index = equal_index;
		end

		local rDamage = {};
		rDamage.startindex = dmg_startindex;
		rDamage.endindex = dmg_endindex;
		if plusflag then
			rDamage.plusflag = true;
		end
		if extraflag then
			rDamage.extraflag = true;
		end
		if ongoingflag then
			rDamage.ongoingflag = true;
		end

		local rDamageClause = {};
		rDamageClause.basemult = dmg_weaponmult;
		rDamageClause.dicestr = dicestr;
		rDamageClause.critdicestr = critdicestr;
		rDamageClause.stat = dmg_abilities;
		rDamageClause.subtype = dmgtypestr;

		rDamage.clauses = { rDamageClause };

		return damage_index, rDamage;
	end
	
	-- Return null
	return damage_index, nil;
end

function parseDamagesAdd(damages, rDamage)
	-- VALIDATE THAT WE HAVE A DAMAGE CLAUSE TO ADD
	if not rDamage then
		return;
	end
	
	-- VALIDATE THAT THIS IS NOT AN EFFECT (ONGOING OR EXTRA)
	if rDamage.ongoingflag then
		return;
	end
	
	-- ONE OFF (PHB - Dire Radiance, Hellish Rebuke)
	if rDamage.extraflag then
		if (rDamage.clauses[1].dicestr == "") or (#(rDamage.clauses[1].stat) == 0) then
			return;
		end
	end
	
	-- CHECK FOR A COMBINED DAMAGE CLAUSE
	if rDamage.plusflag and (#damages > 0) then
		for k, v in pairs(rDamage.clauses) do
			table.insert(damages[#damages].clauses, v);
		end
		damages[#damages].endindex = rDamage.endindex;
		return;
	end
	
	-- OTHERWISE, JUST ADD AS A STANDARD DAMAGE CLAUSE
	table.insert(damages, rDamage);
end

function parseDamageContinuation(damages, words, nIndex)
	local bContinuation = true;

	while bContinuation do
		bContinuation = false;

		-- LOOK FOR DAMAGE VALUE
		local rDamage = nil;
		local nStartDamage = nIndex;
		local nBaseMult = nil;
		if StringManager.isNumberString(words[nIndex]) and StringManager.isWord(words[nIndex+1], "w") then
			nBaseMult = tonumber(words[nIndex]);
			nIndex = nIndex + 2;
		end
		local rValue = parseValuePhrase(words, nIndex);
		if nBaseMult or rValue then
			
			rDamage = {};
			rDamage.startindex = nStartDamage;
			if rValue then
				rDamage.endindex = rValue.nIndex;
			else
				rDamage.endindex = nStartDamage + 1;
			end

			local rDamageClause = {};
			if nBaseMult then
				rDamageClause.basemult = nBaseMult;
			else
				rDamageClause.basemult = 0;
			end
			if rValue then
				rDamageClause.dicestr = StringManager.convertDiceWordArrayToDiceString(rValue.aDice);
				if rValue.bOrFlag then
					rDamageClause.stat = {};
				else
					rDamageClause.stat = rValue.aAbilities;
				end
			else
				rDamageClause.dicestr = "";
				rDamageClause.stat = {};
			end
			rDamageClause.critdicestr = "";
			rDamage.clauses = { rDamageClause };

			if rValue then
				nIndex = rValue.nIndex + 1;
			end
		end

		if rDamage then
			-- CHECK FOR CONTINUATION DAMAGE TYPE
			if (#damages > 0) and (damages[#damages].clauses[1].subtype ~= "") then
				rDamage.clauses[1].subtype = damages[#damages].clauses[1].subtype;
			end
		
			-- ONE OFF (PHB - Careful Attack)
			if StringManager.isWord(words[nIndex], { "melee", "ranged" }) then
				bContinuation = true;
				rDamage.endindex = rDamage.endindex + 1;
				nIndex = nIndex + 1;
				if StringManager.isWord(words[nIndex], "or") then
					nIndex = nIndex + 1;
				end

			-- ONE OFF (PHB - Riposte Strike)
			elseif StringManager.isWord(words[nIndex], "and") and StringManager.isWord(words[nIndex+1], "riposte") and
					StringManager.isWord(words[nIndex+2], "to") then
				bContinuation = true;
				nIndex = nIndex + 3;
			end

			-- CHECK FOR FOLLOW-ON CONTINUATIONS
			if StringManager.isWord(words[rDamage.endindex+1], "at") and 
					words[rDamage.endindex+2] and string.match(words[rDamage.endindex+2], "^%d?%d[st][th]$") then
				
				bContinuation = true;
				if StringManager.isWord(words[rDamage.endindex+3], "level") then
					rDamage.endindex = rDamage.endindex + 3;
				else
					rDamage.endindex = rDamage.endindex + 2;
				end

				nIndex = rDamage.endindex + 1;
				if StringManager.isWord(words[nIndex], "and") then
					nIndex = nIndex + 1;
				end
				if StringManager.isWord(words[nIndex], "to") then
					nIndex = nIndex + 1;
				end
			end

			-- ADD TO DAMAGES ARRAY
			parseDamagesAdd(damages, rDamage);
		end
	end
	
	-- RESULTS
	return nIndex;
end

function parseDamages(words)
	-- SETUP
	local damages = {};

  	-- LOOK FOR DAMAGE WORDS
  	local i = 1;
  	while words[i] do
		
		-- MAIN TRIGGER ("damage")
		if StringManager.isWord(words[i], "damage") then
			if StringManager.isWord(words[i+1], "increases") and StringManager.isWord(words[i+2], "to") then
				i = parseDamageContinuation(damages, words, i + 3);
			else
				i, rDamage = parseDamageClause(words, i, true);
				if rDamage and StringManager.isWord(words[rDamage.endindex+1], "at") and 
						words[rDamage.endindex+2] and string.match(words[rDamage.endindex+2], "^%d?%d[st][th]$") and
						StringManager.isWord(words[rDamage.endindex+3], "level") then
					rDamage.endindex = rDamage.endindex + 3;
					i = i + 3;
				end
				parseDamagesAdd(damages, rDamage);
			end
		-- ALTERNATE TRIGGER ("plus")
		elseif StringManager.isWord(words[i], "plus") and StringManager.isNumberString(words[i-1]) then
			i, rDamage = parseDamageClause(words, i);
			parseDamagesAdd(damages, rDamage);
		-- ALTERNATE TRIGGER ("crit")
		elseif StringManager.isWord(words[i], "crit") then
			i, rDamage = parseDamageClause(words, i);
			parseDamagesAdd(damages, rDamage);
		-- CONTINUATION TRIGGER ("increase damage to")
		elseif StringManager.isWord(words[i], "increase") then
			local j = i + 1;
			if StringManager.isWord(words[j], "the") then
				j = j + 1;
			end
			if StringManager.isWord(words[j], "damage") and StringManager.isWord(words[j+1], "and") and
					StringManager.isWord(words[j+2], "extra") then
				j = j + 3;
			end
			if StringManager.isWord(words[j], "damage") and StringManager.isWord(words[j+1], "to") then
				i = parseDamageContinuation(damages, words, j + 2);
			end
  		end
		
		-- INCREMENT
		i = i + 1;
	end	

	-- RESULTS
	return damages;
end

--
-- HEALS
--

function parseHealsAdd(words, heals, startindex, endindex, hsvmult, heal_dice, heal_stats, heal_cost, sTemp)
	-- BUILD HEAL ABILITY RECORD
	local rHeal = {};
	rHeal.startindex = startindex;
	rHeal.endindex = endindex;

	-- STRIP OUT ANY BONUS SURGE VALUE
	for i = 1, #heal_stats do
		if heal_stats[i] == "hsv" then
			hsvmult = hsvmult + 1;
			table.remove(heal_stats, i);
			break;
		end
	end

	-- COMBINE NUMBERS AND DICE INTO A STRING
	local dicestr = table.concat(heal_dice, "+");
	dicestr = string.gsub(dicestr, "%+%-", "-");

	-- BUILD THE HEAL CLAUSE SPECIFICS
	local rHealClause = {};
	rHealClause.basemult = hsvmult;
	rHealClause.cost = heal_cost;
	rHealClause.dicestr = dicestr;
	rHealClause.stat = heal_stats;
	if sTemp then
		rHealClause.subtype = sTemp;
	else
		rHealClause.subtype = "";
	end

	-- ADD HEAL CLAUSE TO THE HEAL ABILITY RECORD
	rHeal.clauses = { rHealClause };

	-- ADD HEAL ABILITY RECORD TO HEALS FOUND
	table.insert(heals, rHeal);
end

function buildContinuationHeal(heals, aHealDice, aHealStat, bAppend)
	if #heals == 0 then
		return nil;
	end
	
	local rHeal = {};
	local rHealClause = {};
	rHealClause.basemult = heals[#heals].clauses[1].basemult;
	rHealClause.cost = heals[#heals].clauses[1].cost;
	rHealClause.subtype = heals[#heals].clauses[1].subtype;
	if bAppend then
		rHealClause.dicestr = heals[#heals].clauses[1].dicestr .. "+" .. StringManager.convertDiceWordArrayToDiceString(aHealDice);
		rHealClause.stat = aHealStat;
		for k, v in ipairs(heals[#heals].clauses[1].stat) do
			table.insert(rHealClause.stat, v);
		end
	else
		rHealClause.dicestr = StringManager.convertDiceWordArrayToDiceString(aHealDice);
		rHealClause.stat = aHealStat;
	end
	rHeal.clauses = { rHealClause };
	
	return rHeal;
end

function parseHealsContinuation(heals, words, nIndex)
	local bContinuation = true;
	while bContinuation do
		bContinuation = false;

		-- LOOK FOR HEAL VALUE
		local rHeal = nil;
		local nStartHeal = nIndex;
		local rValue = PowersManager.parseValuePhrase(words, nIndex);
		if rValue then
			local rHeal = buildContinuationHeal(heals, rValue.aDice, rValue.aAbilities, false);
			if rHeal then
				rHeal.startindex = nIndex;
				rHeal.endindex = rValue.nIndex;

				nIndex = rHeal.endindex + 1;
			
				-- CHECK FOR FOLLOW-ON CONTINUATIONS
				if StringManager.isWord(words[rHeal.endindex+1], "at") and 
						words[rHeal.endindex+2] and string.match(words[rHeal.endindex+2], "^%d?%d[st][th]$") then

					bContinuation = true;
					if StringManager.isWord(words[rHeal.endindex+3], "level") then
						rHeal.endindex = rHeal.endindex + 3;
					else
						rHeal.endindex = rHeal.endindex + 2;
					end

					nIndex = rHeal.endindex + 1;
					if StringManager.isWord(words[nIndex], "and") then
						nIndex = nIndex + 1;
					end
					if StringManager.isWord(words[nIndex], "to") then
						nIndex = nIndex + 1;
					end
				end

				-- ADD TO HEALS ARRAY
				table.insert(heals, rHeal);
			end
		end
	end
	
	-- RESULTS
	return nIndex;
end

function parseHeals(words)
	-- Start with an empty set
	local heals = {};

  	-- Iterate through the words looking for clauses
  	local i = 1;
  	local surge_val = 0;
  	local surge_cost = 0;
  	local surge_start = 0;
  	local surge_end = 0;
  	while words[i] do
  		-- Check for hit point gains (temporary or normal)
  		if StringManager.isWord(words[i], "points") and StringManager.isWord(words[i-1], "hit") then
  			-- Track the healing information
  			local sTemp = nil;
  			local nHealStart = i - 1;
  			local nHealEnd = i;
  			local heal_dice = {};
  			local heal_stats = {};
  			local bContinuation = false;
  			local bTempAppend = false;

  			-- Iterate backwards to determine values
  			local j = i - 2;
  			if StringManager.isWord(words[j], "temporary") then
				if StringManager.isWord(words[j-1], "additional") then
					bTempAppend = true;
					j = j - 1;
				end
				sTemp = "temp";
				nHealStart = j;
				j = j - 1;
  			elseif StringManager.isWord(words[j], "additional") and StringManager.isWord(words[i+1], "regained") then
				bContinuation = true;
				nHealEnd = i + 1;
				nHealStart = j;
  				j = j - 1;
  			end
  			while words[j] do
  				if StringManager.isWord(words[j], {"to", "the", "modifier"}) then
  					-- SKIP
  				else
					if StringManager.isDiceString(words[j]) and words[j] ~= "0" then
  						table.insert(heal_dice, words[j]);
  						nHealStart = j;
  					else
  						local sAbility = getAbility(words[j]);
  						if sAbility ~= "" then
  							table.insert(heal_stats, sAbility);
  							nHealStart = j;
  							
  							-- ONE OFF (PHB - White Raven Strike)
  							if (sTemp == "temp") and StringManager.isWord(words[j-1], "your") and 
  									StringManager.isWord(words[j-2], "add") then
  								bTempAppend = true;
  								nHealStart = j - 2;
  							end
  						end
  					end
  					if StringManager.isWord(words[j-1], "additional") then
  						nHealStart = j - 1;
  					end
  					break;
  				end
  				
  				j = j - 1;
  			end
  			
  			-- Check for "equal to" clause
  			if (#heal_dice == 0) and (#heal_stats == 0) then
				if StringManager.isWord(words[nHealEnd + 1], "equal") and StringManager.isWord(words[nHealEnd + 2], "to") then
					local rValue = PowersManager.parseValuePhrase(words, nHealEnd + 3);
					if rValue then
						nHealEnd = rValue.nIndex;
						heal_dice = rValue.aDice;
						heal_stats = rValue.aAbilities;
					end
				elseif bContinuation and StringManager.isWord(words[nHealEnd+1], {"is", "to"}) then
					i = parseHealsContinuation(heals, words, nHealEnd + 2);
				end
  			end
  			
  			-- Check for "additional temporary hit points"
  			if bTempAppend and ((#heal_dice > 0) or (#heal_stats > 0)) then
				bContinuation = true;

  				local rHeal = buildContinuationHeal(heals, heal_dice, heal_stats, true);
  				if rHeal then
					if surge_start == 0 then
						surge_start = nHealStart;
					end
  					rHeal.startindex = surge_start;
  					rHeal.endindex = nHealEnd;
  					
					table.insert(heals, rHeal);

					surge_val = 0;
					surge_cost = 0;
					surge_start = 0;
					surge_end = 0;

  					i = nHealEnd;
  				end
  			end
  			
  			-- Make sure we have a valid healing clause
  			if not bContinuation and ((#heal_dice > 0) or (#heal_stats > 0)) then
  				if surge_start == 0 then
  					surge_start = nHealStart;
  				end
  				parseHealsAdd(words, heals, surge_start, nHealEnd, surge_val, heal_dice, heal_stats, surge_cost, sTemp);
  				
  				surge_val = 0;
  				surge_cost = 0;
  				surge_start = 0;
  				surge_end = 0;
  				
  				i = nHealEnd;
			end

		-- Check for healing surge costs
		elseif StringManager.isWord(words[i], {"surge", "surges"}) and StringManager.isWord(words[i-1], "healing") then 
			-- Make sure we're talking about a valid healing surge
			local valid_surge = false;
			local temp_start = i - 3;
			local temp_val = 1;
			local temp_cost = 1;
			local bSurgeDamage = false;

			local j = i - 2;
			while words[j] do
				if StringManager.isWord(words[j], {"a", "1", "one"}) then
					-- SKIP

				elseif StringManager.isWord(words[j], "two") then
					temp_val = 2;
					temp_cost = 2;

				elseif StringManager.isWord(words[j], {"spend", "spends"}) then
					if StringManager.isWord(words[j-1], "they") and StringManager.isWord(words[j-2], "when") then
						-- SKIP ONE OFF (MM - Rakshasa Dread Knight)
					else
						valid_surge = true;
					end

				elseif StringManager.isWord(words[j], "spent") then
					valid_surge = true;
					temp_cost = 0;
					local k = j - 1;
					while words[k] do
						if StringManager.isWord(words[k], {"hit", "points", "as", "if", "it", "he", "or", "she", "they", "you", "had", "each"}) then
							temp_start = k;
						elseif StringManager.isWord(words[k], {"regain", "regains"}) then
							temp_start = k;
							break;
						else
							break;
						end

						k = k - 1;
					end

				elseif StringManager.isWord(words[j], {"lose", "loses"}) then
					valid_surge = true;
					temp_val = 0;
					bSurgeDamage = true;

				elseif StringManager.isWord(words[j], {"regain", "regains"}) then
					valid_surge = true;
					temp_val = 0;
					temp_cost = 0 - temp_cost;

				elseif StringManager.isWord(words[j], "cannot") then
					valid_surge = false;

				else
					break;
				end

				j = j - 1;
			end
			
			-- We have a valid surge
			if valid_surge then
				-- Take care of any previous surges
				if surge_start ~= 0 then
	  				parseHealsAdd(words, heals, surge_start, surge_end, surge_val, {}, {}, surge_cost, false);
				end
				
				-- Remember the number of surges and cost
				surge_val = temp_val;
				surge_cost = temp_cost;
				surge_start = temp_start;
				surge_end = i;

				-- Check for any additions not caught by "hit points" handling
				local j = i + 1;
				local regain_flag = false;
				while words[j] do
					if StringManager.isWord(words[j], "add") then
						local rValue = PowersManager.parseValuePhrase(words, j + 1);
						if rValue then
  							parseHealsAdd(words, heals, surge_start, rValue.nIndex, surge_val, rValue.aDice, rValue.aAbilities, surge_cost, false);

							i = rValue.nIndex;
							
							if StringManager.isWord(words[i+1], "to") and StringManager.isWord(words[i+2], "the") and 
									StringManager.isWord(words[i+3], "hit") and StringManager.isWord(words[i+4], "points") then
								i = i + 4;
							end
							
							surge_val = 0;
							surge_cost = 0;
							surge_start = 0;
							surge_end = 0;
							
							break;
						end
					
					elseif StringManager.isWord(words[j], {"but", "without", "instead"}) then
						surge_val = 0;
						surge_end = math.min(i + 5, #words);
						i = surge_end;
						break;
					
					elseif StringManager.isWord(words[j], {"and", "an", "."}) then
					
					elseif StringManager.isWord(words[j], {"regain", "regains"}) then
						regain_flag = true;
					
					elseif StringManager.isWord(words[j], "additional") then
						regain_flag = false;
						
					else
						if regain_flag then
							surge_val = 0;
						end
						break;
					end
					
					j = j + 1;
				end

				-- ONE OFF (MM - Slaughter Wight)
				if bSurgeDamage then
					parseHealsAdd(words, heals, surge_start, surge_end, surge_val, {}, {}, surge_cost, false);
					
					surge_val = 0;
					surge_cost = 0;
					surge_start = 0;
					surge_end = 0;
				end
			end
  		
  		elseif StringManager.isWord(words[i], {":", ";"}) then
			if surge_start ~= 0 then
				parseHealsAdd(words, heals, surge_start, surge_end, surge_val, {}, {}, surge_cost, false);

				surge_val = 0;
				surge_cost = 0;
				surge_start = 0;
				surge_end = 0;
			end
  		end
		
		-- Increment our counter
		i = i + 1;
	end	

	-- Catch any remainders
	if surge_start ~= 0 then
  		parseHealsAdd(words, heals, surge_start, surge_end, surge_val, {}, {}, surge_cost, false);
	end

	-- Return the set of clauses found in the string
	return heals;
end

--
-- EFFECTS
--

function parseExpirationPhrase(words, nExpirationIndex)
	-- "Save ends ..." EXPIRATION
	if StringManager.isWord(words[nExpirationIndex], "save") then
		if StringManager.isWord(words[nExpirationIndex+1], "ends") then
			local temp_index = nExpirationIndex + 1;
			-- ONE OFF (MM - Vampire Lord)
			if StringManager.isWord(words[temp_index+1], "with") and StringManager.isWord(words[temp_index+4], "penalty") then
				temp_index = temp_index + 8;
			end
			return temp_index, "save";
		end
	
	-- "Until ..." EXPIRATION
	elseif StringManager.isWord(words[nExpirationIndex], {"until", "before", "by"}) then
		local temp_index = nExpirationIndex + 1;
		if StringManager.isWord(words[temp_index], "the") then
			temp_index = temp_index + 1;
		end
		if StringManager.isWord(words[temp_index], "encounter") then
			return temp_index, "encounter";
		elseif StringManager.isWord(words[temp_index], "end") then
			temp_index = temp_index + 3;
			if StringManager.isWord(words[temp_index], "encounter") then
				return temp_index, "encounter";
			else
				while words[temp_index] do
					if StringManager.isWord(words[temp_index], "next") then
						return temp_index, "endnext";
					elseif StringManager.isWord(words[temp_index], "turn") then
						return temp_index, "end";
					elseif StringManager.isWord(words[temp_index], { ".", ";", ":" }) then
						break;
					end
					temp_index = temp_index + 1;
				end
			end
		elseif StringManager.isWord(words[temp_index], {"start", "beginning"}) then
			while words[temp_index] do
				if StringManager.isWord(words[temp_index], "turn") then
					return temp_index, "start";
				elseif StringManager.isWord(words[temp_index], { ".", ";", ":" }) then
					break;
				end
				temp_index = temp_index + 1;
			end
		elseif StringManager.isWord(words[temp_index], "escape") then
			return temp_index, "escape";
		end
		
	-- "During ..." EXPIRATION
	elseif StringManager.isWord(words[nExpirationIndex], "during") then
		local temp_index = nExpirationIndex + 1;
		if StringManager.isWord(words[temp_index], "your") then
			temp_index = temp_index + 1;
			if StringManager.isWord(words[temp_index], "next") then
				temp_index = temp_index + 1;
				if StringManager.isWord(words[temp_index], "turn") then
					return temp_index, "endnext";
				end
			else
				if StringManager.isWord(words[temp_index], "current") then
					temp_index = temp_index + 1;
				end
				if StringManager.isWord(words[temp_index], "turn") then
					return temp_index, "end";
				end
			end
		elseif StringManager.isWord(words[temp_index], "this") then
			temp_index = temp_index + 1;
			if StringManager.isWord(words[temp_index], "encounter") then
				return temp_index, "encounter";
			elseif StringManager.isWord(words[temp_index], "turn") then
				return temp_index, "end";
			end
		end
	
	-- "For the rest of the encounter" EXPIRATION
	elseif StringManager.isWord(words[nExpirationIndex], "for") then
		local temp_index = nExpirationIndex + 1;
		if StringManager.isWord(words[temp_index], "the") then
			temp_index = temp_index + 1;
		end
		if StringManager.isWord(words[temp_index], "rest") and StringManager.isWord(words[temp_index+3], "encounter") then
			return temp_index+3, "encounter";
		end
	
	-- "on your current turn" EXPIRATION
	elseif StringManager.isWord(words[nExpirationIndex], "on") then
		local temp_index = nExpirationIndex + 1;
		if StringManager.isWord(words[temp_index], "your") and StringManager.isWord(words[temp_index+1], "current") and 
				StringManager.isWord(words[temp_index+2], "turn") then
			return temp_index+2, "end";
		end
	
	-- "this turn" EXPIRATION
	elseif StringManager.isWord(words[nExpirationIndex], "this") then
		local temp_index = nExpirationIndex + 1;
		if StringManager.isWord(words[temp_index], "turn") then
			return temp_index, "end";
		end
	end
	
	return nExpirationIndex, "";
end

function parseTargetPhrase(words, nTargetingIndex, wordsCreatureName)
	-- SETUP
	local rTarget = { 
			sType = "", 
			nIndex = nTargetingIndex, 
			aEntity = {}, 
			aModifiers = {}, 
			aConditions = {} 
			};
	
	-- LOOK FOR VALID TARGETING CLAUSE DATA
	local j = nTargetingIndex;
	while words[j] do
		if StringManager.isWord(words[j], {"the", "one", "a", "an", "and", "same", "or", "each", "all", 
				"different", "adjacent", "another", "new", "single", "any", "first", "second", "secondary", "his", "her"}) then
			-- SKIP

		elseif StringManager.isWord(words[j], {"next", "that", "triggering", "charge"}) then
			rTarget.bSingle = true;
		
		elseif StringManager.isWord(words[j], wordsCreatureName) then
			if #(rTarget.aEntity) > 0 then
				break;
			end
			rTarget.sType = "creature";
			table.insert(rTarget.aEntity, words[j]);
			rTarget.bTargeted = true;
			rTarget.nIndex = j;
			local k = j + 1;
			while words[k] do
				if StringManager.isWord(words[k], wordsCreatureName) then
					table.insert(rTarget.aEntity, words[k]);
					rTarget.nIndex = k;
				else
					break;
				end
				k = k + 1;
			end
			break;
			
		elseif StringManager.isWord(words[j], {"it", "target", "targets", "creature", "creatures", "enemy", "enemies", "quarry"}) then
			if #(rTarget.aEntity) > 0 then
				break;
			end
			table.insert(rTarget.aEntity, words[j]);
			rTarget.sType = "creature";
			rTarget.bTargeted = true;
			rTarget.nIndex = j;
			break;

		elseif StringManager.isWord(words[j], {"ally", "allies"}) then
			table.insert(rTarget.aEntity, words[j]);
			rTarget.sType = "creature";
			rTarget.bTargeted = true;
			rTarget.nIndex = j;
			break;
		
		elseif StringManager.isWord(words[j], "you") or 
				StringManager.isWord(words[j], wordsCreatureName) then
			table.insert(rTarget.aEntity, words[j]);
			rTarget.sType = "creature";
			rTarget.bTargeted = true;
			rTarget.nIndex = j;

		elseif StringManager.isWord(words[j], DataCommon.rangetypes) or
				StringManager.isWord(words[j], "opportunity") then
			table.insert(rTarget.aModifiers, words[j]);
		
		elseif StringManager.isWord(words[j], "attacks") then
			rTarget.sType = "attack";
			rTarget.nIndex = j;
			if StringManager.isWord(words[j-1], {"target's", "targets'", "its"}) then
				rTarget.bTargeted = true;
			end
			break;

		elseif StringManager.isWord(words[j], "attack") then
			rTarget.sType = "attack";
			rTarget.nIndex = j;
			rTarget.bSingle = true;
			break;

		elseif StringManager.isWord(words[j], DataCommon.conditions) then
			table.insert(rTarget.aConditions, words[j]);

		elseif StringManager.isWord(words[j], {"bloodied", "flanked"}) then 
			table.insert(rTarget.aConditions, words[j]);

		-- ONE OFF (MM - Blood Fiend)
		elseif StringManager.isWord(words[j], "living") then
			-- SKIP
		
		elseif StringManager.isWord(words[j], "conditions") then
			rTarget.sType = "condition";
			rTarget.nIndex = j;
			break;
			
		elseif StringManager.isWord(words[j], "effect") then
			rTarget.sType = "effect";
			rTarget.nIndex = j;
			rTarget.bSingle = true;
			break;
			
		elseif StringManager.isWord(words[j], {"your", "its", "their"}) then
		elseif StringManager.isWord(words[j], {"ally's", "allies'", "enemy's", "enemies'", "target's", "targets'", "weapon's"}) then
			-- SKIP

		else
			break;
		end

		j = j + 1;
	end

	-- CLEAR TARGET VARIABLE, IF NOTHING FOUND
	if rTarget.sType == "" then
		rTarget = nil;
	end
	
	-- RETURN NEW INDEX
	return rTarget;
end

function parseEntityPhrase(words, nEntityIndex, wordsCreatureName, sCurrentEntity)
	if StringManager.isWord(words[nEntityIndex], wordsCreatureName) then
		sCurrentEntity = words[nEntityIndex];

		local j = nEntityIndex + 1;
		while words[j] do
			if string.match(words[j], "[']s?") then
				sCurrentEntity = nil;
				break;

			elseif StringManager.isWord(words[j], wordsCreatureName) then
				sCurrentEntity = sCurrentEntity .. " " .. words[j];

			elseif StringManager.isWord(words[j], "of") then
				-- SKIP

			else
				break;
			end

			j = j + 1;
		end

	elseif StringManager.isWord(words[nEntityIndex], {"it", "ally", "allies", "enemy", "enemies", "target", "targets"}) then
		sCurrentEntity = words[nEntityIndex];

	elseif StringManager.isWord(words[nEntityIndex], "you") then
		if StringManager.isWord(words[nEntityIndex+1], "can") and StringManager.isWord(words[nEntityIndex+2], {"see", "hear"}) then
			-- SKIP
		elseif StringManager.isWord(words[nEntityIndex-1], {"see", "hear"}) then
			-- SKIP
		else
			sCurrentEntity = words[nEntityIndex];

			local j = nEntityIndex + 1;
			local sTempEntity = words[nEntityIndex];
			while words[j] do
				if StringManager.isWord(words[j], {"and", "or", "all", "of", "your", "any", "each", "adjacent", "an", "one"}) then
					sTempEntity = sTempEntity .. " " .. words[j];

				elseif StringManager.isWord(words[j], {"ally", "allies"}) then
					sTempEntity = sTempEntity .. " " .. words[j];
					sCurrentEntity = sTempEntity;
					break;

				elseif StringManager.isWord(words[j], DataCommon.conditions) then
					-- SKIP

				elseif StringManager.isWord(words[j], {"bloodied", "flanked"}) then 
					-- SKIP

				else
					break;
				end

				j = j + 1;
			end
		end
	end
	
	return sCurrentEntity;
end

function parseEffectsAdd(effects, rComboEffect, sExpiration, wordsCreatureName)
	-- SETUP 
	local aTempEffects = {};
	local rTempEffect = { label = {} };
	local sLastEntity = nil;
	
	-- ITERATE THROUGH COMBO EFFECT TO BUILD NEW EFFECTS
	for k, v in ipairs(rComboEffect) do
		if v.name == "AFTER:" or v.name == "FAIL:" then
			rTempEffect.followon = v.name;

		else
			local bEntityChange = sLastEntity and v.entity and (sLastEntity ~= v.entity);
			local bSinglesSeparate = v.sApply and v.extradmg and rTempEffect.sApply;
			if (rTempEffect.bBreakAfter or bEntityChange or bSinglesSeparate) and (#(rTempEffect.label) > 0 or rTempEffect.followon) then
				local sTempExpiration = sExpiration;
				if rTempEffect.expire then
					sTempExpiration = rTempEffect.expire;
				end

				if rTempEffect.targeted then
					table.insert(rTempEffect.label, 1, "TRGT");
				end
				
				table.insert(aTempEffects,
						{startindex = rTempEffect.startindex,
						endindex = rTempEffect.endindex,
						name = table.concat(rTempEffect.label, "; "),
						expire = sTempExpiration,
						mod = 0,
						apply = rTempEffect.sApply,
						followon = rTempEffect.followon,
						also = rTempEffect.also,
						instead = rTempEffect.instead,
						entity = sLastEntity});

				rTempEffect = { label = {} };				
			end

			table.insert(rTempEffect.label, v.name);
			if v.entity then
				sLastEntity = v.entity;
			end
		end

		if rTempEffect.startindex then
			rTempEffect.startindex = math.min(v.startindex, rTempEffect.startindex);
		else
			rTempEffect.startindex = v.startindex;
		end
		if rTempEffect.endindex then
			rTempEffect.endindex = math.max(v.endindex, rTempEffect.endindex);
		else
			rTempEffect.endindex = v.endindex;
		end

		rTempEffect.also = v.also;
		rTempEffect.instead = v.instead;
		rTempEffect.sApply = v.sApply;
		rTempEffect.targeted = v.targeted;
		rTempEffect.expire = v.expire;
		rTempEffect.bBreakAfter = v.bBreakAfter;
		
		if v.extradmg then
			if (#(rTempEffect.label) == 1) and StringManager.isWord(sExpiration, {"", "save"}) then
				rTempEffect.sApply = "roll";
				rTempEffect.expire = "";
				rTempEffect.bBreakAfter = true;
			end
		end
	end
	
	if (#(rTempEffect.label) > 0) or rTempEffect.followon then
		if rTempEffect.targeted then
			table.insert(rTempEffect.label, 1, "TRGT");
		end
		local sTempExpiration = sExpiration;
		if rTempEffect.expire then
			sTempExpiration = rTempEffect.expire;
		end
		table.insert(aTempEffects, 
				{startindex = rTempEffect.startindex, 
				endindex = rTempEffect.endindex, 
				name = table.concat(rTempEffect.label, "; "), 
				expire = sTempExpiration, 
				mod = 0,
				sApply = rTempEffect.sApply,
				followon = rTempEffect.followon,
				also = rTempEffect.also,
				instead = rTempEffect.instead,
				entity = sLastEntity});
	end
	
	for k, v in ipairs(aTempEffects) do
		if v.followon then
			if #effects > 0 then
				local listNewEffectName = {};

				table.insert(listNewEffectName, effects[#effects].name);
				table.insert(listNewEffectName, v.followon .. " " .. v.expire);

				if v.instead or v.also then
					local sNameInstead = effects[#effects].name;

					local listEffectsOriginal = StringManager.split(effects[#effects].name, ";", true);
					local i = #listEffectsOriginal;
					while (i > 0) do
						if string.sub(listEffectsOriginal[i], 1, 6) == "AFTER:" or
								string.sub(listEffectsOriginal[i], 1, 5) == "FAIL:" then
							break;
						end
						i = i - 1;
					end
					local listEffectsNewReplace = {};
					for j = i + 1, #listEffectsOriginal do
						if v.instead and StringManager.contains(v.instead, string.lower(listEffectsOriginal[j])) then
							-- SKIP
						else
							table.insert(listEffectsNewReplace, listEffectsOriginal[j]);
						end
					end

					table.insert(listNewEffectName, table.concat(listEffectsNewReplace, "; "));
				end

				if v.name ~= "" then
					table.insert(listNewEffectName, v.name);
				else
					table.insert(listNewEffectName, "Special");
				end

				effects[#effects].name = table.concat(listNewEffectName, "; ");
				effects[#effects].startindex = math.min(effects[#effects].startindex, v.startindex);
				effects[#effects].endindex = math.max(effects[#effects].endindex, v.endindex);
			end

		else
			local rEffect = {startindex = v.startindex,
					endindex = v.endindex,
					name = v.name,
					sApply = v.sApply,
					expire = v.expire,
					mod = 0,
					sTargeting = ""};
			if v.entity then
				if v.entity == "you" then
					rEffect.sTargeting = "self";
				else
					local wordsEffectTarget = StringManager.parseWords(v.entity);
					if #wordsEffectTarget > 0 then
						local bSelfTargeted = true;
						for keyWord, sWord in pairs(wordsEffectTarget) do
							if not StringManager.isWord(sWord, wordsCreatureName) then
								bSelfTargeted = false;
							end
						end
						if bSelfTargeted then
							rEffect.sTargeting = "self";
						end
					end
				end
			end
			table.insert(effects, rEffect);
		end
	end
end

function buildContinuationEffect(effects, bPenalty, aModDice, aModStat, aModType, sModBonusType)
	-- VALIDATE
	if #effects == 0 then
		return nil;
	end
	
	-- SETUP
	local sModDice = nil;
	if #aModDice > 0 then
		sModDice = StringManager.convertDiceWordArrayToDiceString(aModDice, bPenalty);
	end
	local sModStat = nil;
	if #aModStat > 0 then
		sModStat = StringManager.convertAbilityWordArrayToEffectString(aModStat, bPenalty);
	end

	-- ITERATE BACKWARDS THROUGH EFFECTS TO FIND A MATCH
	for i = #effects, 1, -1 do
		-- PARSE LAST EFFECT
		local aEffectComps = EffectsManager.parseEffect(effects[i].name);

		-- BUILD NEW EFFECT
		local rResult = {};
		local aNewEffect = {};
		local bSkip = false;
		local bMatch = false;
		for keyComp, rComp in pairs(aEffectComps) do
			if rComp.type ~= "" and (bSkip or (rComp.type == "AFTER") or (rComp.type == "FAIL")) then
				bSkip = true;

				local aNewComp = { rComp.type .. ":" };
				if #(rComp.dice) > 0 or rComp.mod ~= 0 then
					table.insert(aNewComp, StringManager.convertDiceToString(rComp.dice, rComp.mod));
				end
				if #(rComp.remainder) > 0 then
					table.insert(aNewComp, table.concat(rComp.remainder, " "));
				end
				table.insert(aNewEffect, table.concat(aNewComp, " "));

			elseif rComp.type ~= "" then
				local aNewComp = { rComp.type .. ":" };

				local bTempMatch = false;
				if #aModType > 0 then
					for keyMod, rMod in pairs(aModType) do
						if rMod.primary == rComp.type then
							bTempMatch = true;
							break;
						end
					end
				elseif sModBonusType and sModBonusType ~= "" then
					if StringManager.isWord(sModBonusType, rComp.remainder) then
						bTempMatch = true;
					end
				else
					bTempMatch = true;
				end
				if bTempMatch then
					bMatch = true;
					if sModDice then
						table.insert(aNewComp, sModDice);
					end
					if sModStat then
						table.insert(aNewComp, sModStat);
					end
				else
					if #(rComp.dice) > 0 or rComp.mod ~= 0 then
						table.insert(aNewComp, StringManager.convertDiceToString(rComp.dice, rComp.mod));
					end
				end

				if #(rComp.remainder) > 0 then
					table.insert(aNewComp, table.concat(rComp.remainder, " "));
				end

				table.insert(aNewEffect, table.concat(aNewComp, " "));

			elseif #(rComp.remainder) == 1 then
				if rComp.remainder[1] == "TRGT" then
					rResult.targeted = true;
				else
					table.insert(aNewEffect, rComp.remainder[1]);
				end
			else
				table.insert(aNewEffect, table.concat(rComp.remainder, " "));
			end
		end
		rResult.name = table.concat(aNewEffect, "; ");
		
		-- CHECK SOME FLAGS IN CASE WE GOT AN IN-PROGRESS EFFECT
		if effects[i].targeted then
			rResult.targeted = effects[i].targeted;
		end
		if effects[i].sApply then
			rResult.sApply = effects[i].sApply;
		end
		if effects[i].extradmg then
			rResult.extradmg = effects[i].extradmg;
		end
		if effects[i].bBreakAfter then
			rResult.bBreakAfter = effects[i].bBreakAfter;
		end

		-- CATCH THE EXPIRATION, IF ANY
		if effects[i].expire then
			rResult.expire = effects[i].expire;
		end

		-- IF WE MATCHED, THEN WE'RE DONE
		if bMatch then
			return rResult;
		end
	end
	
	-- NO MATCH FOUND
	return nil;
end

function parseEffects(words, sCreatureName, nodePower)
	-- Start with an empty set
	local effects = {};

  	-- Variables to handle effects parsing
  	local rCurrent = nil;
  	local cur_entity = nil;
  	local combo_effect = {};
  	local exp_effect = "";
  	local bWeaponClause = false;
  	
  	-- CREATURE NAME PREP
  	local wordsCreatureName = StringManager.parseWords(string.lower(sCreatureName));
  	local i = 1;
  	while wordsCreatureName[i] do
  		if StringManager.isWord(wordsCreatureName[i], "of") or
  				StringManager.isWord(wordsCreatureName[i], DataCommon.dmgtypes) or
  				StringManager.isWord(wordsCreatureName[i], DataCommon.bonustypes) then
  			table.remove(wordsCreatureName, i);
  		else
  			i = i + 1;
  		end
  	end

  	-- Iterate through the words looking for effects
  	local i = 1;
  	while words[i] do
  		-- Expiration (which all causes effect break)
		nTempExpiration, sTempExpiration = parseExpirationPhrase(words, i);
		exp_flag = not (sTempExpiration == "");

  		-- Effect break triggers
  		clause_start_flag = StringManager.isWord(words[i], ":");
  		clause_end_flag = StringManager.isWord(words[i], ";");

  		trigger_break = clause_start_flag or clause_end_flag or exp_flag;

  		-- Effect triggers
  		connect_flag = StringManager.isWord(words[i], "and");
  		cond_flag = StringManager.isWord(words[i], DataCommon.conditions) and (i > 1);
  		mod_flag = StringManager.isWord(words[i], {"bonus", "penalty", "speed"});
  		immune_flag = StringManager.isWord(words[i], {"immune", "immunity"});
  		dmgadj_flag = StringManager.isWord(words[i], {"resist", "resistance", "vulnerable", "vulnerability"});
  		regen_flag = StringManager.isWord(words[i], "regeneration");
  		cover_conceal_flag = StringManager.isWord(words[i], {"cover", "concealment"});
  		altcond_flag = StringManager.isWord(words[i], {"mark", "grab", "grabs", "dazes", "entombed", "immobilize", "weaken", "invisibility", "sanction"});
  		ca_flag = StringManager.isWord(words[i], "advantage") and 
  				StringManager.isWord(words[i-1], "combat");
  		heal_flag = StringManager.isWord(words[i], {"power", "powers", "keyword"}) and 
  				StringManager.isWord(words[i-1], "healing");
  		damage_flag = StringManager.isWord(words[i], "damage");
  		add_flag = StringManager.isWord(words[i], {"add", "adds"});
  		increase_flag = StringManager.isWord(words[i], {"increase", "increases", "worsens"});
  		rage_flag = StringManager.isWord(words[i], "rage") and StringManager.isWord(words[i+1], "of") and StringManager.isWord(words[i+2], "the");
  		
  		trigger_cond = connect_flag or cond_flag or mod_flag or immune_flag or dmgadj_flag or regen_flag or 
  				cover_conceal_flag or altcond_flag or ca_flag or heal_flag or damage_flag or add_flag or increase_flag or rage_flag;
  		
  		-- Miscellaneous triggers
  		within_flag = StringManager.isWord(words[i], "within");
  		against_flag = StringManager.isWord(words[i], "against");
  		adjacent_flag = StringManager.isWord(words[i], "adjacent") and StringManager.isWord(words[i+1], "to");
  		sentence_end_flag = StringManager.isWord(words[i], ".");

  		-- SAVE OFF CURRENT EFFECT (if we hit a trigger)
  		if rCurrent and (trigger_break or trigger_cond or sentence_end_flag) then
  			table.insert(combo_effect, rCurrent);
			rCurrent = nil;
  		end

  		-- ONE OFF (PHB - Immobilizing Strike, Disintegrate, Curseforged Armor) (Affects PHB - Curse of the Black Forest)
  		local sSpecialFollowon = nil;
  		local nSpecialFollowon = i;
  		if StringManager.isWord(words[i], "if") and 
  				StringManager.isWord(words[i+1], "the") and StringManager.isWord(words[i+2], "target") then
  			if StringManager.isWord(words[i+3], "succeeds") and StringManager.isWord(words[i+4], "on") and
					StringManager.isWord(words[i+5], "its") and StringManager.isWord(words[i+6], "saving") and 
					StringManager.isWord(words[i+7], "throw") then
				sSpecialFollowon = "AFTER:";
				nSpecialFollowon = i + 7;
  			elseif StringManager.isWord(words[i+3], "fails") and StringManager.isWord(words[i+4], "its") and
					StringManager.isWord(words[i+5], "first") and StringManager.isWord(words[i+6], "saving") and 
					StringManager.isWord(words[i+7], "throw") and StringManager.isWord(words[i+8], "against") and 
					StringManager.isWord(words[i+9], "this") and StringManager.isWord(words[i+10], "power") then
				sSpecialFollowon = "FAIL:";
				nSpecialFollowon = i + 10;
			elseif StringManager.isWord(words[i+3], "saves") then
				sSpecialFollowon = "AFTER:";
				nSpecialFollowon = i + 3;
			end
  		elseif StringManager.isWord(words[i], "when") and StringManager.isWord(words[i+1], "the") and 
  				StringManager.isWord(words[i+2], "enemy") and StringManager.isWord(words[i+3], "saves") and 
  				StringManager.isWord(words[i+4], "against") and StringManager.isWord(words[i+5], "the") and 
  				StringManager.isWord(words[i+6], "penalty") then
			sSpecialFollowon = "AFTER:";
  			nSpecialFollowon = i + 6;
  		end
  		if sSpecialFollowon then
  			if rCurrent then
  				table.insert(combo_effect, rCurrent);
  				rCurrent = nil;
  			end
  			
  			rCurrent = {};
  			rCurrent.name = sSpecialFollowon;
  			rCurrent.startindex = i + 3;
  			rCurrent.endindex = nSpecialFollowon;
  			rCurrent.entity = nil;
  		end

		-- SPECIAL PROCESSING FOR SPECIAL MARKERS
		if clause_start_flag then
  			bWeaponClause = false;
  			bLevelClause = false;
  			
  			local sFollowonEffect = nil;
  			local nFollowonEffect = i;
			if StringManager.isWord(words[i-1], "aftereffect") then
				sFollowonEffect = "AFTER:";
			elseif StringManager.isWord(words[i-1], "save") and StringManager.isWord(words[i-2], "failed") then
				sFollowonEffect = "FAIL:";
			elseif StringManager.isWord(words[i-1], "throw") and StringManager.isWord(words[i-2], "saving") and 
					StringManager.isWord(words[i-3], "failed") then
				sFollowonEffect = "FAIL:";
			else
				if StringManager.isWord(words[i-1], "weapon") then
					bWeaponClause = true;
				elseif StringManager.isWord(words[i-1], "trigger") then
					while words[i] do
						if StringManager.isWord(words[i], ";") then
							break;
						end
						i = i + 1;
					end
				elseif StringManager.isNumberString(words[i-1]) then
					local j = i - 1;
					while words[j] do
						if StringManager.isWord(words[j], "or") or StringManager.isNumberString(words[j]) then
							-- SKIP
						else
							break;
						end
						j = j - 1;
					end
					if StringManager.isWord(words[j], "level") then
						bLevelClause = true;
					end
				end
			end
  			
  			if sFollowonEffect then
				rCurrent = {};
				rCurrent.name = sFollowonEffect;
				rCurrent.startindex = nFollowonEffect;
				rCurrent.endindex = nFollowonEffect;
				rCurrent.entity = nil;
				
				trigger_break = false;
				clause_start_flag = false;
			end
		end
  		
  		if clause_start_flag or clause_end_flag or sentence_end_flag then
  			if #combo_effect > 0 then
  				combo_effect[#combo_effect].bBreakAfter = true;
  			end
  			cur_entity = nil;
  		end
  		
  		-- ENTITY PROCESSING
  		cur_entity = parseEntityPhrase(words, i, wordsCreatureName, cur_entity);

  		-- FLAG PROCESSING
  		
  		-- Triggers to add effects 
  		if trigger_break then
			if #combo_effect > 0 then
				-- ONE OFF (PHB - Weapon of the Gods)
				if (exp_effect ~= "") and (sTempExpiration ~= "") and (#combo_effect > 1) then
					local aTempEffect = { combo_effect[1] };
					parseEffectsAdd(effects, aTempEffect, exp_effect, wordsCreatureName);
					table.remove(combo_effect, 1);
				end
				
				if sTempExpiration == "" then
					sTempExpiration = exp_effect;
					exp_effect = "";
				else
					if sTempExpiration == "escape" then
						sTempExpiration = "";
					else
						exp_effect = "";
					end
					i = nTempExpiration;
				end

				parseEffectsAdd(effects, combo_effect, sTempExpiration, wordsCreatureName);
				combo_effect = {};
			elseif StringManager.isWord(sTempExpiration, { "encounter", "endnext", "end", "start" }) then
				exp_effect = sTempExpiration;
				i = nTempExpiration;
			elseif sTempExpiration ~= "" then
				exp_effect = "";
				i = nTempExpiration;
			end
  		
		-- Handle adjacent clauses
		elseif adjacent_flag then
			local rTarget = parseTargetPhrase(words, i+1, wordsCreatureName);
			if rTarget then
				i = rTarget.nIndex;
			end
		
		-- Handle against clauses
		elseif against_flag then
			local rTarget = parseTargetPhrase(words, i+1, wordsCreatureName);
			if rTarget then
				i = rTarget.nIndex;
				if rCurrent then
					rCurrent.targeted = true;
					if rTarget.bSingle then
						rCurrent.sApply = "roll";
					end
				end
			end
		
		-- Handle within clauses
		elseif within_flag then
			if StringManager.isNumberString(words[i+1]) and StringManager.isWord(words[i+2], "squares") then
				i = i + 2;
				if StringManager.isWord(words[i+1], "of") then
					local rTarget = parseTargetPhrase(words, i+2, wordsCreatureName);
					if rTarget then
						i = rTarget.nIndex;
					end
				end
			end

		-- Handle alternate condition 
		elseif altcond_flag then
			local bValid = false;
			local bTargetCheck = false;
			local nCondStart = i;
			local nCondEnd = i;
			local sEntity = nil;
			local sEffect = "";
			if StringManager.isWord(words[i], "dazes") then
				bTargetCheck = true;
				sEffect = "Dazed";
			elseif StringManager.isWord(words[i], "mark") then
				bTargetCheck = true;
				sEffect = "Marked";
			elseif StringManager.isWord(words[i], { "grab", "grabs" }) then
				if StringManager.isWord(words[i+1], "escape") and StringManager.isWord(words[i+2], "ends") then
					bValid = true;
				else
					bTargetCheck = true;
				end
				sEffect = "Grabbed";
			elseif StringManager.isWord(words[i], "immobilize") then
				if StringManager.isWord(words[i+1], "save") then
					bValid = true;
				else
					bTargetCheck = true;
				end
				sEffect = "Immobilized";
			elseif StringManager.isWord(words[i], "weaken") then
				if StringManager.isWord(words[i+1], "save") then
					bValid = true;
					sEffect = "Weakened";
				end
			elseif StringManager.isWord(words[i], "invisibility") then
				if StringManager.isWord(words[i-1], "gain") then
					bValid = true;
					sEffect = "Invisible";
				end
			elseif StringManager.isWord(words[i], "sanction") then
				if StringManager.isWord(words[i-1], "divine") and StringManager.isWord(words[i-2], "your") and
						StringManager.isWord(words[i-3], "to") and StringManager.isWord(words[i-4], "subject") then
					bValid = true;
					sEffect = "Marked; Sanctioned";
					nCondStart = i - 4;
				end
			end
			
			if bTargetCheck then
				if StringManager.isWord(words[nCondEnd+1], {"that", "the"}) then
					nCondEnd = nCondEnd + 1;
				end
				if StringManager.isWord(words[nCondEnd+1], {"target", "enemy"}) then
					bValid = true;
					nCondEnd = nCondEnd + 1;
					sEntity  = words[nCondEnd];
				end
			end
			
			if bValid then
				rCurrent = {};
				rCurrent.name = sEffect;
				rCurrent.startindex = nCondStart;
				rCurrent.endindex = nCondEnd;
				rCurrent.entity = sEntity;

				cur_entity = nil;
				i = nCondEnd;
			end

		-- Handle concealment
		elseif cover_conceal_flag then
			-- SETUP
			local nPhraseStart = i;
			local bValid = false;
			local bTotal = false;

			-- CHECK FOR TOTAL COVER OR CONCEALMENT
			if StringManager.isWord(words[nPhraseStart - 1], {"superior", "total"}) then
				bTotal = true;
				nPhraseStart = nPhraseStart - 1;
			end
			
			-- CHECK FOR VALIDITY
			if StringManager.isWord(words[nPhraseStart - 1], {"gain", "gains", "grant", "grants", "providing"}) then
				if StringManager.isWord(words[nPhraseStart - 2], "not") then
					-- INVALID
				else
					bValid = true;
				end
			elseif StringManager.isWord(words[nPhraseStart - 1], {"has", "have"}) then
				if StringManager.isWord(words[nPhraseStart - 2], {"don't", "not"}) then
					-- INVALID
				elseif StringManager.isWord(words[nPhraseStart - 2], "you") and StringManager.isWord(words[nPhraseStart - 3], "if") then
					-- INVALID
				elseif StringManager.isWord(words[nPhraseStart - 2], "gnome") then
					-- INVALID ONE OFF (MM - GNOME)
				else
					bValid = true;
				end
			end

			-- IF VALID, THEN ADD EFFECT
			if bValid then
				-- MORE SETUP
				local nPhraseEnd = i;
				local aDefenseTypes = nil;
				
				-- CHECK FOR SPECIFICITY
				local j = nPhraseEnd;
				if StringManager.isWord(words[j+1], "to") then
					-- ONE OFF (PHB - SEAL OF WARDING)
					local rTarget = parseTargetPhrase(words, j+2, wordsCreatureName);
					if rTarget then
						j = rTarget.nIndex;
					end
				end
				if StringManager.isWord(words[j+1], "against") then
					local rTarget = parseTargetPhrase(words, j+2, wordsCreatureName);
					if rTarget and rTarget.sType == "attack" then
						nPhraseEnd = rTarget.nIndex;
						aDefenseTypes = rTarget.aModifiers;
					end
				end
			
				-- GET EFFECT DETAILS
				local aEffectName = {};
				if StringManager.isWord(words[i], "concealment") then
					if bTotal then
						table.insert(aEffectName, "TCONC:");
					else
						table.insert(aEffectName, "CONC:");
					end
				else
					if bTotal then
						table.insert(aEffectName, "SCOVER:");
					else
						table.insert(aEffectName, "COVER:");
					end
				end
				if aDefenseTypes then
					table.insert(aEffectName, table.concat(aDefenseTypes, " "));
				end

				-- MAKE CURRENT EFFECT
				rCurrent = {};
				rCurrent.name = table.concat(aEffectName, " ");
				rCurrent.startindex = nPhraseStart;
				rCurrent.endindex = nPhraseEnd;
				rCurrent.entity = cur_entity;
				
				-- ADJUST SOME TRACKING VARIABLES
				i = nPhraseEnd;
				cur_entity = nil;
			end
  		
  		-- Handle regen
  		elseif regen_flag then
			local regen_end = i;
  			if StringManager.isWord(words[i+1], "equal") and StringManager.isWord(words[i+2], "to") then
				regen_end = i + 2;
			end

			local rValue = PowersManager.parseValuePhrase(words, regen_end + 1);
			if rValue then
				local bHandled = false;
				if bLevelClause then
					rCurrent = buildContinuationEffect(effects, false, rValue.aDice, rValue.aAbilities, { primary = "REGEN" }, "");
					if rCurrent then
						bHandled = true;
						
						rCurrent.startindex = i;
						rCurrent.endindex = rValue.nIndex;
						rCurrent.entity = cur_entity;

						i = rValue.nIndex;
						cur_entity = nil;
					end
				end
				
				if not bHandled then
					rCurrent = {};
					rCurrent.name = "REGEN: ";
					if #(rValue.aDice) > 0 then
						rCurrent.name = rCurrent.name .. " " .. StringManager.convertDiceWordArrayToDiceString(rValue.aDice);
					end
					if #(rValue.aAbilities) > 0 then
						rCurrent.name = rCurrent.name .. " " .. StringManager.convertAbilityWordArrayToEffectString(rValue.aAbilities);
					end
					rCurrent.startindex = i;
					rCurrent.endindex = rValue.nIndex;
					rCurrent.entity = cur_entity;

					i = rValue.nIndex;
					cur_entity = nil;

					-- ONE OFF (PHB - Melora's Tide)
					if (#effects > 0) and StringManager.isWord(words[i + 1], "instead") then
						i = i + 1;
						rCurrent.expire = effects[#effects].expire;
					end
				end
			end
  		
  		-- Handle immunity effects
  		elseif immune_flag then
  			-- Make sure this is a valid condition before
  			local valid_condition = false;
  			local j = i - 1;
  			while words[j] do
  				if StringManager.isWord(words[j], {"gain", "have", "is"}) then
  					valid_condition = true;
  				else
  					break;
  				end
  				j = j - 1;
  			end

  			-- Make sure this is a valid condition after
  			if valid_condition then
				local dmgtype = "";
				j = i + 1;
				while words[j] do
					if StringManager.isWord(words[j], {"to", "all"}) then
						
					elseif StringManager.isWord(words[j], "damage") then
						rCurrent = {};
						rCurrent.name = "IMMUNE: all";
						rCurrent.startindex = i;
						rCurrent.endindex = j;
						rCurrent.entity = cur_entity;

						i = j;
						cur_entity = nil;
						break;
					
					elseif StringManager.isWord(words[j], DataCommon.dmgtypes) then
						rCurrent = {};
						rCurrent.name = "IMMUNE: " .. words[j];
						rCurrent.startindex = i;
						rCurrent.endindex = j;
						rCurrent.entity = cur_entity;

						i = j;
						cur_entity = nil;
						break;
						
					else
						break;
					end
					j = j + 1;
				end
			end
  			
  		-- Handle resist/vulnerable
  		elseif dmgadj_flag then
  			-- Determine the effect type
  			local bTargeted = nil;
  			local adjtype = "RESIST";
  			if StringManager.isWord(words[i], {"vulnerable", "vulnerability"}) then
  				adjtype = "VULN";
  			end
  			
  			-- See how many types of damage adjustment and how much
  			local dmgadj_array = {};
  			local dmgadj_delayadd = {};
  			local dmgadj_end = i;
  			local dmgadj_val = "";
  			local j = i + 1;
  			while words[j] do
  				if StringManager.isWord(words[j], {"and", "to", "from", "weapon", "ranged"}) then

  				elseif StringManager.isWord(words[j], "your") and StringManager.isWord(words[j+1], "attacks") then
  					j = j + 1;
  					dmgadj_end = j;
  					bTargeted = true;
  				
  				elseif StringManager.isWord(words[j], "attacks") then
  					dmgadj_end = j;

  				elseif StringManager.isWord(words[j], "damage") then
  					dmgadj_end = j;

  				elseif StringManager.isWord(words[j], DataCommon.dmgtypes) then
  					if dmgadj_val == "" then
  						table.insert(dmgadj_delayadd, words[j]);
  					else
						dmgadj_array[words[j]] = dmgadj_val;
						dmgadj_end = j;
					end
  				
  				elseif StringManager.isWord(words[j], {"all", "any"}) then
  					if dmgadj_val == "" then
  						table.insert(dmgadj_delayadd, "");
  					else
						dmgadj_array[""] = dmgadj_val;
					end
  				
  				else		
  					if StringManager.isWord(words[j], "equal") and StringManager.isWord(words[j+1], "to") then
  						j = j + 2;
  					end
  					local rValue = PowersManager.parseValuePhrase(words, j);
  					if rValue then
  						dmgadj_val = "";
  						if #(rValue.aDice) > 0 then
  							dmgadj_val = StringManager.convertDiceWordArrayToDiceString(rValue.aDice);
  						end
  						if #(rValue.aAbilities) > 0 then
  							if dmgadj_val ~= "" then
  								dmgadj_val = dmgadj_val .. " ";
  							end
  							dmgadj_val = dmgadj_val .. StringManager.convertAbilityWordArrayToEffectString(rValue.aAbilities);
  						end
  						
  						dmgadj_end = rValue.nIndex;
  						j = rValue.nIndex;

						for k,v in pairs(dmgadj_delayadd) do
							dmgadj_array[v] = dmgadj_val;
						end
						dmgadj_delayadd = {};
						
						-- ONE OFF (PHB - Resistance)
						if StringManager.isWord(words[i], "resistance") and #dmgadj_array == 0 then
							dmgadj_array[""] = dmgadj_val;
						end
					else
						break;
  					end
  				end

  				j = j + 1;
  			end
  			
  			-- If we got something, then make it an effect
  			local dmgadj_results = {};
  			for k,v in pairs(dmgadj_array) do
  				local sTemp = adjtype .. ": " .. v;
				if k ~= "" then
					sTemp = sTemp .. " " .. k;
				end
				table.insert(dmgadj_results, sTemp);
  			end
  			if #dmgadj_results > 0 then
				-- HANDLE ONE-SHOT RESISTANCE
				local sApply = nil;
				if StringManager.isWord(words[dmgadj_end+1], "from") and StringManager.isWord(words[dmgadj_end+2], "the") and 
						StringManager.isWord(words[dmgadj_end+3], "attack") then 
					dmgadj_end = dmgadj_end + 3;
					sApply = "roll";
				end
				
				rCurrent = {};
				rCurrent.name = table.concat(dmgadj_results, "; ");
				rCurrent.startindex = i;
				rCurrent.endindex = dmgadj_end;
				rCurrent.entity = cur_entity;
				rCurrent.sApply = sApply;
				rCurrent.targeted = bTargeted;

				i = dmgadj_end;
				cur_entity = nil;
				
				if (#effects > 0) and bLevelClause then
					rCurrent.expire = effects[#effects].expire;
				end
  			end
  		
  		-- Handle modifiers (attack, damage, defense, save, speed)
  		elseif mod_flag then
  			-- Initialize some variables to track the modifier
  			local moddice = {};
  			local modbonustype = "";
  			local modtype = {};
  			local modstat = {};
  			local mod_start = i;
			local mod_end = i;
			local sApply = nil;
			local is_ormod = false;

  			-- Start by looking for the mod bonus type and value
  			local j = i - 1;
  			while words[j] do
  				if StringManager.isWord(words[j], {"as", "a", "modifier"}) then
  					-- SKIP

  				elseif StringManager.isWord(words[j], DataCommon.bonustypes) then
  					modbonustype = words[j];
  					mod_start = j;

  				else
  					if StringManager.isNumberString(words[j]) then
  						table.insert(moddice, words[j]);
  						mod_start = j;
  					else
  						local sAbility = getAbility(words[j]);
						if sAbility ~= "" then
							table.insert(modstat, sAbility);
							mod_start = j;
  						end
  					end
					break;
  				end
  				
  				j = j - 1;
  			end
  			
  			-- ONE OFF (MM - Marilith)
  			if StringManager.isWord(words[mod_end+1], "+1") and StringManager.isWord(words[mod_end+2], "per") and
  					StringManager.isWord(words[mod_end+3], "scimitar") then
  				mod_end = mod_end + 3;
  			end
  			
  			-- Next make sure we are applying the bonus to something
  			local bCheckMod = false;
  			local nCheckMod = mod_end;
  			if StringManager.isWord(words[nCheckMod], "speed") then
  				bCheckMod = true;
  			elseif StringManager.isWord(words[nCheckMod + 1], {"to", "on", "with"}) then
  				bCheckMod = true;
  				nCheckMod = nCheckMod + 2;
  			-- ONE OFF (PHB - Foil the Lock)
  			elseif StringManager.isWord(words[nCheckMod + 1], "when") and StringManager.isWord(words[nCheckMod + 2], "you") and
  					StringManager.isWord(words[nCheckMod + 3], "make") and StringManager.isWord(words[nCheckMod + 4], {"a", "an"}) then
  				bCheckMod = true;
  				nCheckMod = nCheckMod + 5;
  			end
  			
			-- Pick out the mods
			if bCheckMod then
				local j = nCheckMod;
  				local aAttackSecondary = {};
  				local aDamageSecondary = {};
  				while words[j] do
  					local skip_flag = StringManager.isWord(words[j], {"a", "an", "and", "all", "any", "its", "their", "theirs", "your", "basic", "his", "her", "these", "the"});
  					if StringManager.isWord(words[j], DataCommon.abilities) then
  						skip_flag = true;
  					end
  					if string.match(words[j], "%-based$") and StringManager.contains(DataCommon.abilities, string.sub(words[j], 1, -7)) then
  						skip_flag = true;
  					end
  					local single_flag = StringManager.isWord(words[j], {"one", "next", "single", "this", "second", "third"});

  					-- Skip these words completely
  					if skip_flag then
  						-- SKIP
  					
  					elseif StringManager.isWord(words[j], "or") then
  						is_ormod = true;
  					
  					elseif single_flag then
  						sApply = "roll";
  					
  					-- Capture attack/damage modifiers
  					elseif StringManager.isWord(words[j], DataCommon.rangetypes) then
  						table.insert(aAttackSecondary, words[j]);
  						table.insert(aDamageSecondary, words[j]);
  					elseif StringManager.isWord(words[j], "opportunity") then
  						table.insert(aAttackSecondary, words[j]);
  						
  					-- Capture attack type
  					elseif StringManager.isWord(words[j], {"attack", "attacks"}) then
  						if #aAttackSecondary > 0 then
  							table.insert(modtype, { primary = "ATK", secondary = table.concat(aAttackSecondary, " ") });
  						else
  							table.insert(modtype, { primary = "ATK" });
  						end
  						aAttackSecondary = {};
  						aDamageSecondary = {};
  						
  						-- ONE OFF (PHB - Warlock - Bewitching Whispers)
  						if StringManager.isWord(words[j-1], "these") then
  							sApply = "roll";
  						end

  						if StringManager.isWord(words[j+1], "roll") then
  							sApply = "roll";
  							j = j + 1;
  						elseif StringManager.isWord(words[j+1], "rolls") then
  							j = j + 1;
  						end
  						mod_end = j;
  					
  					-- Capture damage type
  					elseif StringManager.isWord(words[j], "damage") then
  						if #aDamageSecondary > 0 then
  							table.insert(modtype, { primary = "DMG", secondary = table.concat(aDamageSecondary, " ") });
  						else
  							table.insert(modtype, { primary = "DMG" });
  						end
  						aAttackSecondary = {};
  						aDamageSecondary = {};
  						
  						if StringManager.isWord(words[j+1], "roll") then
  							sApply = "roll";
  							j = j + 1;
  						elseif StringManager.isWord(words[j+1], "rolls") then
  							j = j + 1;
  						end
  						
  						mod_end = j;

  					-- Capture defense types
  					elseif StringManager.isWord(words[j], "ac") then
						table.insert(modtype, { primary = "AC" });
						mod_end = j;

  					elseif StringManager.isWord(words[j], "fortitude") then
						table.insert(modtype, { primary = "FORT" });
						if StringManager.isWord(words[j+1], {"defense", "defenses"}) then
							j = j + 1;
						end
						mod_end = j;

  					elseif StringManager.isWord(words[j], "reflex") then
						table.insert(modtype, { primary = "REF" });
						if StringManager.isWord(words[j+1], {"defense", "defenses"}) then
							j = j + 1;
						end
						mod_end = j;

  					elseif StringManager.isWord(words[j], "will") then
						table.insert(modtype, { primary = "WILL" });
						if StringManager.isWord(words[j+1], {"defense", "defenses"}) then
							j = j + 1;
						end
						mod_end = j;

  					elseif StringManager.isWord(words[j], "other") then
						if StringManager.isWord(words[j+1], {"defense", "defenses"}) then
							table.insert(modtype, { primary = "FORT" });
							table.insert(modtype, { primary = "REF" });
							table.insert(modtype, { primary = "WILL" });
							j = j + 1;
							mod_end = j;
						end

					elseif StringManager.isWord(words[j], {"defense", "defenses"}) then
						table.insert(modtype, { primary = "DEF" });
						mod_end = j;

					elseif StringManager.isWord(words[j], "saving") then
  						if StringManager.isWord(words[j+1], "throw") then
							table.insert(modtype, { primary = "SAVE" });
  							sApply = "roll";
  							j = j + 1;
  							mod_end = j;
  						elseif StringManager.isWord(words[j+1], "throws") then
							table.insert(modtype, { primary = "SAVE" });
  							j = j + 1;
  							mod_end = j;
						end
					elseif StringManager.isWord(words[j], "saves") then
						table.insert(modtype, { primary = "SAVE" });
						mod_end = j;
					elseif StringManager.isWord(words[j], "death") and StringManager.isWord(words[j+1], "saves") then
						table.insert(modtype, { primary = "SAVE", secondary = "death" });
						j = j + 1;
						mod_end = j;

  					-- Capture misc types
  					elseif StringManager.isWord(words[j], "speed") then
						table.insert(modtype, { primary = "SPEED" });
						mod_end = j;

					elseif StringManager.isWord(words[j], "initiative") then
						table.insert(modtype, { primary = "INIT" });
						if StringManager.isWord(words[j+1], "check") then
  							sApply = "roll";
							j = j + 1;
						elseif StringManager.isWord(words[j+1], "checks") then
							j = j + 1;
						end
						mod_end = j;
					
					elseif StringManager.isWord(words[j], DataCommon.skills) then
						table.insert(modtype, { primary = "SKILL", secondary = words[j] });
						if StringManager.isWord(words[j+1], "check") then
  							sApply = "roll";
							j = j + 1;
						elseif StringManager.isWord(words[j+1], "checks") then
							j = j + 1;
						end
						mod_end = j;
					
					elseif StringManager.isWord(words[j], "ability") then
						local specific = nil;
						if StringManager.isWord(words[j-1], DataCommon.abilities) then
							specific = words[j-1];
						end
						table.insert(modtype, { primary = "ABIL", secondary = specific });
						if StringManager.isWord(words[j+1], "check") then
  							sApply = "roll";
							j = j + 1;
						elseif StringManager.isWord(words[j+1], "checks") then
							j = j + 1;
						end
						mod_end = j;
					
					elseif StringManager.isWord(words[j], "skill") then
						local specific = nil;
						if words[j-1] and string.match(words[j-1], "%-based$") and
								StringManager.contains(DataCommon.abilities, string.sub(words[j-1], 1, -7)) then
							specific = string.sub(words[j-1], 1, -7);
						end
						table.insert(modtype, { primary = "SKILL", secondary = specific });
						if StringManager.isWord(words[j+1], "and") and StringManager.isWord(words[j+2], "ability") then
							table.insert(modtype, { primary = "ABIL", secondary = specific });
							j = j + 2;
						end
						if StringManager.isWord(words[j+1], "check") then
  							sApply = "roll";
							j = j + 1;
						elseif StringManager.isWord(words[j+1], "checks") then
							j = j + 1;
						end
						mod_end = j;
					
					-- ONE OFF (PHB - Skilled Companion)
					elseif StringManager.isWord(words[j], "checks") and StringManager.isWord(words[j+1], "with") and
							StringManager.isWord(words[j+2], "a") and StringManager.isWord(words[j+3], "single") and
							StringManager.isWord(words[j+4], "skill") and StringManager.isWord(words[j+5], "of") and
							StringManager.isWord(words[j+6], "your") and StringManager.isWord(words[j+7], "choice") then
						table.insert(modtype, { primary = "SKILL" });
						mod_end = j + 7;

					-- ONE OFF (PHB - Eldritch Rain)
					elseif StringManager.isWord(words[j], "each") and StringManager.isWord(words[j+1], "attack's") then
						sApply = "roll";
						j = j + 1;
					
					elseif StringManager.isWord(words[j], "d20") then
						is_ormod = true;
						table.insert(modtype, { primary = "ATK" });
						table.insert(modtype, { primary = "SAVE" });
						table.insert(modtype, { primary = "INIT" });
						table.insert(modtype, { primary = "SKILL" });
						table.insert(modtype, { primary = "ABIL" });
  						if StringManager.isWord(words[j+1], "roll") then
  							sApply = "roll";
  							j = j + 1;
  						elseif StringManager.isWord(words[j+1], "rolls") then
  							j = j + 1;
  						end
						mod_end = j;

					-- Otherwise, if it's not a skip word, then we're done
					else
						break;
  					end

  					-- Increment word count
  					j = j + 1;
  				end
  			end
  			
			-- Pick up target clauses
			local bTargetedMod = false;
			if StringManager.isWord(words[mod_end+1], {"against", "for", "with", "on"}) then
				local rTarget = parseTargetPhrase(words, mod_end+2, wordsCreatureName);
				if rTarget then
					if rTarget.sType == "creature" then
						bTargetedMod = true;
					elseif rTarget.sType == "attack" then
						if rTarget.bSingle then
  							sApply = "roll";
							if StringManager.isWord(words[mod_end+1], "against") then
								is_ormod = true;
							end
						end
						if rTarget.bTargeted then
							bTargetedMod = true;
						end
						for k,v in pairs(modtype) do
							if StringManager.isWord(v.primary, {"ATK", "DEF", "AC", "FORT", "REF", "WILL"}) then
								if v.secondary and v.secondary ~= "" then
									v.secondary = v.secondary .. " " .. table.concat(rTarget.aModifiers, " ");
								else
									v.secondary = table.concat(rTarget.aModifiers, " ");
								end
							elseif v.primary == "DMG" then
								for keyMod, sMod in pairs(rTarget.aModifiers) do
									if sMod == "opportunity" then
  										sApply = "roll";
									else
										if v.secondary and v.secondary ~= "" then
											v.secondary = v.secondary .. " " .. sMod;
										else
											v.secondary = sMod;
										end
									end
								end
							end
						end
					elseif rTarget.sType == "effect" then
						if rTarget.bSingle then
  							sApply = "roll";
							if StringManager.isWord(words[mod_end+1], "against") then
								is_ormod = true;
							end
						end
						if rTarget.bTargeted then
							bTargetedMod = true;
						end
					end
					mod_end = rTarget.nIndex;
				end
			-- ONE OFF (PHB - Press of Arms)
			elseif StringManager.isWord(words[mod_end+1], "when") and StringManager.isWord(words[mod_end+2], "making") then
				local rTarget = parseTargetPhrase(words, mod_end+3, wordsCreatureName);
				if rTarget then
					mod_end = rTarget.nIndex;
					if (rTarget.sType == "attack") and (#(rTarget.aModifiers) > 0) then
						for k,v in pairs(modtype) do
							if v.primary == "ATK" then
								if v.secondary and v.secondary ~= "" then
									v.secondary = v.secondary .. " " .. table.concat(rTarget.aModifiers, " ");
								else
									v.secondary = table.concat(rTarget.aModifiers, " ");
								end
							elseif v.primary == "DMG" then
								for keyMod, sMod in pairs(rTarget.aModifiers) do
									if sMod == "opportunity" then
  										sApply = "roll";
									else
										if v.secondary and v.secondary ~= "" then
											v.secondary = v.secondary .. " " .. sMod;
										else
											v.secondary = sMod;
										end
									end
								end
							end
						end
					end
				end
			end
			if StringManager.isWord(words[mod_end+1], "adjacent") and StringManager.isWord(words[mod_end+2], "to") then
				local rTarget = parseTargetPhrase(words, mod_end+3, wordsCreatureName);
				if rTarget then
					mod_end = rTarget.nIndex;
				end
			end
			-- ONE OFF (PHB - Dance of Death,Beat Them into the Ground)
			if StringManager.isWord(words[mod_end+1], {"granted", "provoked"}) and 
					StringManager.isWord(words[mod_end+2], "by") and StringManager.isWord(words[mod_end+3], "this") and 
					StringManager.isWord(words[mod_end+4], "power") then
				mod_end = mod_end + 4;
				sApply = "roll";

			-- ONE OFF (PHB - Warlord's Favor)
			elseif StringManager.isWord(words[mod_end+1], "that") and StringManager.isWord(words[mod_end+2], "you") and 
					StringManager.isWord(words[mod_end+3], "grant") then
				mod_end = mod_end + 3;
			end
  			
			
			-- Check to see if we have an "equal to" clause
			local bContinuation = false;
			if #moddice == 0 then
				local bCheckPostValue = false;
				local nCheckPostValue = mod_end;
				
				if StringManager.isWord(words[mod_end+1], "equal") and StringManager.isWord(words[mod_end+2], "to") then
					bCheckPostValue = true;
					nCheckPostValue = mod_end + 3;
				elseif StringManager.isWord(words[mod_end+1], "is") and StringManager.isWord(words[mod_end+2], "equal") and 
						StringManager.isWord(words[mod_end+3], "to") then
					bContinuation = true;
					bCheckPostValue = true;
					nCheckPostValue = mod_end + 4;
				elseif StringManager.isWord(words[mod_end+1], "equals") then
					bContinuation = true;
					bCheckPostValue = true;
					nCheckPostValue = mod_end + 2;
				end

				if bCheckPostValue then
					local rValue = PowersManager.parseValuePhrase(words, nCheckPostValue);
					if rValue then
						mod_end = rValue.nIndex;
						moddice = rValue.aDice;
						modstat = rValue.aAbilities;

						-- CONTINUATION BONUSES
						if bContinuation then
							if (exp_effect == "") and (#effects > 0) then
								exp_effect = effects[#effects].expire;
								
								local bPenalty = StringManager.isWord(words[i], "penalty");
								rCurrent = buildContinuationEffect(effects, bPenalty, moddice, modstat, modtype, modbonustype);
								if rCurrent then
									rCurrent.startindex = mod_start;
									rCurrent.endindex = mod_end;
									rCurrent.entity = cur_entity;

									i = mod_end;
									cur_entity = nil;
								else
									bContinuation = false;
								end
							else
								bContinuation = false;
							end
						end
					end
				end
			end
			
			-- HANDLE LEVEL CLAUSES
			if #modtype == 0 and bLevelClause then
				bContinuation = true;
				local bPenalty = StringManager.isWord(words[i], "penalty");
				rCurrent = buildContinuationEffect(effects, bPenalty, moddice, modstat, modtype, modbonustype);
				if rCurrent then
					rCurrent.startindex = mod_start;
					rCurrent.endindex = mod_end;
					rCurrent.entity = cur_entity;
					
					i = mod_end;
					cur_entity = nil;
				end
			end
			
			-- LOOK BACKWARDS, IF WE HAVE MODIFIER WITH NO ROLL TYPE
			-- NOTE: ONLY GRABS FIRST MODIFIER FOUND
			if #modtype == 0 and not bContinuation then
				local j = mod_start - 1;
				local bTempTargeted = false;
				while words[j] do
					if StringManager.isWord(words[j], {".", ":", ";", "damage"}) then
						break;

					elseif StringManager.isWord(words[j], "of") and StringManager.isWord(words[j-1], "instead") then
						break;
						
					elseif StringManager.isWord(words[j], "defenses") then
						table.insert(modtype, { primary = "DEF" });
						mod_start = j;
						break;
					
					elseif StringManager.isWord(words[j], {"attack", "attacks"}) then
						if (StringManager.isWord(words[j-1], "your") and StringManager.isWord(words[j-2], "against")) then
							-- ONE OFF (PHB - Feinting Flurry)
							bTargetedMod = true;
						else
							if StringManager.isWord(words[j], "attack") and not StringManager.isWord(words[j+1], "rolls") then
	  							sApply = "roll";
							end
							local aTempRangeTypes = {};
							local aTempStart = j;
							local k = j - 1;
							while words[k] do
								if StringManager.isWord(words[k], DataCommon.rangetypes) then
									table.insert(aTempRangeTypes, words[k]);
									aTempStart = k;

								elseif StringManager.isWord(words[k], "and") then
									-- SKIP

								elseif StringManager.isWord(words[k], { "next", "your" }) then
									aTempStart = k;

								else
									break;
								end

								k = k - 1;
							end
							if bTempTargeted then
								bTargetedMod = true;
							end
							table.insert(modtype, { primary = "ATK", secondary = table.concat(aTempRangeTypes, " ") });
							mod_start = aTempStart;
							break;
						end
						
					elseif bTempTargeted and StringManager.isWord(words[j], "throws") and 
							StringManager.isWord(words[j-1], "saving") then
						if #effects > 0 and effects[#effects].expire == "save" then
							local bPenalty = StringManager.isWord(words[i], "penalty");
							local dicestr = StringManager.convertDiceWordArrayToDiceString(moddice, bPenalty);
							effects[#effects].mod = StringManager.evalDiceString(dicestr, false);
						end
						
					elseif StringManager.isWord(words[j], "throw") and 
							StringManager.isWord(words[j-1], "saving") then
						table.insert(modtype, { primary = "SAVE" });
						sApply = "roll";
						mod_start = j - 1;
						break;

					elseif StringManager.isWord(words[j], {"check", "checks"}) then
						if StringManager.isWord(words[j-1], "skill") then
							table.insert(modtype, { primary = "SKILL" });
							if StringManager.isWord(words[j], "check") then
  								sApply = "roll";
							end
							mod_start = j - 1;
							break;
						
						elseif StringManager.isWord(words[j-1], DataCommon.skills) then
							table.insert(modtype, { primary = "SKILL", secondary = words[j-1] });
							if StringManager.isWord(words[j], "check") then
  								sApply = "roll";
							end
							mod_start = j - 1;
							break;
						end
					
					elseif StringManager.isWord(words[j], {"against"}) then
						bTempTargeted = true;
					end

					j = j - 1;
				end
			end
			
			-- Make sure we have a valid mod
			if #modtype > 0 and (#moddice > 0 or #modstat > 0) and not bContinuation then
				-- PICK OUT ANY DEFENSE SPECIFIERS
				local aDefenseSpecifiers = nil;
				if StringManager.isWord(words[mod_end+1], "against") then
					local rTarget = parseTargetPhrase(words, mod_end + 2, wordsCreatureName);
					if rTarget and rTarget.sType == "attack" then
						aDefenseSpecifiers = rTarget.aModifiers;
						mod_end = rTarget.nIndex;
						if rTarget.bSingle then
  							sApply = "roll";
						end
					end
				end
				
				-- ITERATE THROUGH MOD TYPES FOUND TO BUILD RESULTS
				local mod_results = {};
				local bPenalty = StringManager.isWord(words[i], "penalty");
				local sModDice = nil;
				if #moddice > 0 then
					sModDice = StringManager.convertDiceWordArrayToDiceString(moddice, bPenalty);
				end
				local sModStat = nil;
				if #modstat > 0 then
					sModStat = StringManager.convertAbilityWordArrayToEffectString(modstat, bPenalty);
				end
				for k, v in pairs(modtype) do
					local aLocalModResult = { v.primary .. ":" };

					if sModDice then
						table.insert(aLocalModResult, sModDice);
					end
					if sModStat then
						table.insert(aLocalModResult, sModStat);
					end
					if modbonustype ~= "" then
						table.insert(aLocalModResult, modbonustype);
					end
					if v.secondary then
						table.insert(aLocalModResult, v.secondary);
					end
					if aDefenseSpecifiers and StringManager.isWord(v.primary, {"DEF", "AC", "FORT", "REF", "WILL"}) then
						table.insert(aLocalModResult, table.concat(aDefenseSpecifiers, " "));
					end
					
					table.insert(mod_results, table.concat(aLocalModResult, " "));
				end

				if sApply == "roll" and not is_ormod and #modtype ~= 1 then
					sApply = "single";
				end
				
				rCurrent = {};
				rCurrent.name = table.concat(mod_results, "; ");
				rCurrent.startindex = mod_start;
				rCurrent.endindex = mod_end;
				rCurrent.entity = cur_entity;
				rCurrent.sApply = sApply;
				if bTargetedMod then
					rCurrent.targeted = true;
				end

				if bWeaponClause and (exp_effect == "") and (#effects > 0) then
					exp_effect = effects[#effects].expire;
				end

				i = mod_end;
				cur_entity = nil;
			end
  		
  		-- Handle conditions
  		elseif cond_flag then
			local valid_condition = false;
			local bAlso = false;
			local j  = i - 1;
			local temp_start = i;
			while words[j] do
				if StringManager.isWord(words[j], {"held", "the", "target", "a", "you", "them", "it", "of"}) then
				elseif StringManager.isWord(words[j], DataCommon.conditions) then

				elseif StringManager.isWord(words[j], {"is", "are", "and", "turn", "turns", "gain", "gains"}) then
					if valid_condition then
						break;
					end
					valid_condition = true;

				elseif StringManager.isWord(words[j], {"knock", "knocks", "knocked", "fall", "falls"}) and 
						StringManager.isWord(words[i], {"prone", "unconscious"}) then
					valid_condition = true;
					temp_start = j;

				elseif StringManager.isWord(words[j], "also") then
					valid_condition = true;
					bAlso = true;
					break;

				elseif StringManager.isWord(words[j], {"become", "becomes"}) then
					-- ONE OFF (MM - HYDRAS)
					if StringManager.isWord(words[j-1], "hydra") then
						break;
					-- ONE OFF (PHB - Dust of Appearance)
					elseif StringManager.isWord(words[j-1], "can't") then
						valid_condition = false;
						break;
					end
					
					valid_condition = true;
					local k = i + 1;
					while words[k] do
						if StringManager.isWord(words[k], DataCommon.conditions) then
						elseif StringManager.isWord(words[k], {"pulled", "pushed", "slid"}) then
						elseif StringManager.isWord(words[j], "or") then
							valid_condition = false;
						else
							break;
						end

						k = k + 1;
					end
					break;

				-- ONE OFF (PHB - Raven's Glamor)
				elseif StringManager.isWord(words[j], "as") and StringManager.isWord(words[j-1], "long") and
						StringManager.isWord(words[j-2], "as") then
					valid_condition = false;
					break;
					
				-- ONE OFF (PHB - Elemental Maw)
				elseif StringManager.isWord(words[j], "destination") and StringManager.isWord(words[i], "prone") then
					valid_condition = true;
					break;
				
				elseif StringManager.isWord(words[j], "that") and not StringManager.isWord(words[j-1], "except") then
					valid_condition = false;
					break;
					
				elseif StringManager.isWord(words[j], {"against", "if", "while", "not", "nor", "instead", "before", "until"}) then
					valid_condition = false;
					break;

				else
					break;
				end

				j = j - 1;
			end
  			
			-- If we found an effect condition vs. some other condition text, then we have a valid effect
			if valid_condition then
				local nCondEnd = i;
				local bTargeted = false;
				local aInstead = {};
				
				-- Look for targeting
				if StringManager.isWord(words[i+1], "to") and StringManager.isWord(words[i+2], "the") and StringManager.isWord(words[i+3], "target") then
					bTargeted = true;
					nCondEnd = i + 3;
				end
				
				-- Look for replacement conditions
				if (StringManager.isWord(words[i+1], "instead") and StringManager.isWord(words[i+2], "of")) then
					local j = i + 3;
					while words[j] do
						if StringManager.isWord(words[j], {"and", "or"}) then
							nCondEnd = j;
						elseif StringManager.isWord(words[j], DataCommon.conditions) then
							table.insert(aInstead, words[j]);
							nCondEnd = j;
						else
							break;
						end
						j = j + 1;
					end
				end
				if (StringManager.isWord(words[i+1], "rather") and StringManager.isWord(words[i+2], "than")) then
					local j = i + 3;
					while words[j] do
						if StringManager.isWord(words[j], {"and", "or"}) or StringManager.isWord(words[j], DataCommon.conditions) then
							nCondEnd = j;
						else
							break;
						end
						j = j + 1;
					end
					if bWeaponClause and (exp_effect == "") and (#effects > 0) then
						exp_effect = effects[#effects].expire;
					end
				end

				-- Special handling for prone
				local bProne = StringManager.isWord(words[i], "prone");
				if bProne and #combo_effect > 0 then
  					combo_effect[#combo_effect].bBreakAfter = true;
				end
				
				-- Save the current effect information
				rCurrent = {};
				rCurrent.name = string.upper(string.sub(words[i], 1, 1)) .. string.sub(words[i], 2);
				rCurrent.startindex = temp_start;
				rCurrent.endindex = nCondEnd;
				rCurrent.entity = cur_entity;
				if bAlso then
					rCurrent.also = true;
				end
				if bTargeted then
					rCurrent.targeted = true;
				end
				if #aInstead > 0 then
					rCurrent.instead = aInstead;
				end
				
				-- More special handling for prone
				if bProne then
					rCurrent.expire = "";
					rCurrent.bBreakAfter = true;
					table.insert(combo_effect, rCurrent);
					rCurrent = nil;
				end

				i = nCondEnd;
				cur_entity = nil;
			end
  		
  		-- Handle combat advantage
  		elseif ca_flag then
			local valid_condition = nil;
			local bCheckToClause = false;
			local j  = i - 2;
			while words[j] do
				if StringManager.isWord(words[j], {"the", "target", "a", "you", "them", "they", "it", "of", "is", "are", "and"}) then
				
				elseif StringManager.isWord(words[j], {"allies", "angel's"}) then
					-- ONE OFF (MM - ANGEL OF BATTLE)
				
				elseif StringManager.isWord(words[j], {"gain", "gains", "gaining"}) then
					valid_condition = "gain";
					break;

				elseif StringManager.isWord(words[j], "have") then
					-- ONE OFF (PHB - DISTRACTING WOUND)
					if StringManager.isWord(words[j-1], "you") and StringManager.isWord(words[j-2], "creature") then
						valid_condition = nil;
						break;
					-- ONE OFF (PHB - NIMBLE BLADE)
					elseif StringManager.isWord(words[j-1], "you") and StringManager.isWord(words[j-2], "and") and
							StringManager.isWord(words[j-3], "blade") then
						valid_condition = nil;
						break;
					else
						valid_condition = "gain";
					end
				
				elseif StringManager.isWord(words[j], {"grant", "grants"}) then
					valid_condition = "grant";

				elseif StringManager.isWord(words[j], "granting") then
					valid_condition = "gain";

				elseif StringManager.isWord(words[j], "with") then
					if StringManager.isWord(words[j-1], "attack") then
						valid_condition = "gain";
						break;
					end
				
				elseif StringManager.isWord(words[j], "has") then
					-- ONE OFF (MM - PHANTOM WARRIOR)
					if StringManager.isWord(words[j-1], "warrior") then
						valid_condition = "gain";
					else
						valid_condition = nil;
					end
					break;
				
				elseif StringManager.isWord(words[j], {"don't", "not", "must", "that", "when", "if", "while"}) then
					valid_condition = nil;
					break;
					
				else
					break;
				end

				j = j - 1;
			end
  		
  			-- CHECK FOR VALID CONDITION
  			if valid_condition then
  				-- Make sure CA is separate effect
  				if (#combo_effect > 0) and (valid_condition == "gain") then
  					combo_effect[#combo_effect].bBreakAfter = true;
  				end
  				
  				rCurrent = {};
  				if valid_condition == "gain" then
  					rCurrent.name = "CA";
  				else
  					rCurrent.name = "GRANTCA";
  				end
  				rCurrent.startindex = i - 1;
  				rCurrent.endindex = i;
  				rCurrent.entity = cur_entity;

  				if valid_condition == "gain" then
  					rCurrent.bBreakAfter = true;
  				end
  				
  				if StringManager.isWord(words[i+1], {"to", "against"}) then
  					local rTarget = parseTargetPhrase(words, i + 2, wordsCreatureName);
					if rTarget then
  						rCurrent.targeted = true;
  						rCurrent.endindex = rTarget.nIndex;
  						i = rTarget.nIndex;
  					end
  				end
  				
				cur_entity = nil;
  			end

  		-- Handle healing bonus effects
  		elseif heal_flag then
  			local j = i + 1;
  			while words[j] do
  				if StringManager.isWord(words[j], {"restore", "add", "your"}) then
  				
  				else
  					break;
  				end
  			
  				j = j + 1;
  			end
  			
			local rValue = PowersManager.parseValuePhrase(words, j);
			if rValue then
				local heal_results = { "HEAL:" };
				if #(rValue.aDice) > 0 then
					table.insert(heal_results, StringManager.convertDiceWordArrayToDiceString(rValue.aDice));
				end
				if #(rValue.aAbilities) > 0 then
					table.insert(heal_results, StringManager.convertAbilityWordArrayToEffectString(rValue.aAbilities));
				end
				
				local nHealEnd = rValue.nIndex;
				
				j = nHealEnd + 1;
				while words[j] do
					if StringManager.isWord(words[j], {"to", "the", "hit"}) then
					
					elseif StringManager.isWord(words[j], "points") then
						nHealEnd = j;
						break;
					else
						break;
					end
				
					j = j + 1;
				end

				rCurrent = {};
				rCurrent.name = table.concat(heal_results, " ");
				rCurrent.startindex = i - 1;
				rCurrent.endindex = nHealEnd;
				rCurrent.entity = cur_entity;
				
				i = nHealEnd;
				cur_entity = nil;
			end

		-- Check for ongoing or extra damage
		elseif damage_flag then
			-- Check for a valid damage clause
			i, rDamage = PowersManager.parseDamageClause(words, i, true);
			if rDamage and rDamage.clauses and (#(rDamage.clauses) > 0) then
				
				-- CHECK FOR ONGOING DAMAGE
				if rDamage.ongoingflag and not rDamage.extraflag then
					
					-- ONE OFF (MM - Beholder Eye of Flame) (affects PHB - Make Them Bleed)
					if (#combo_effect > 0) and StringManager.isWord(words[rDamage.startindex-1], "deals") and 
							StringManager.isWord(words[rDamage.startindex-2], "also") then
  						combo_effect[#combo_effect].bBreakAfter = true;
					end
					
					local bHandled = false;
					if bLevelClause then
						rCurrent = buildContinuationEffect(effects, false, { rDamage.clauses[1].dicestr }, rDamage.clauses[1].stat, { primary = "DMGO" }, "");
						if rCurrent then
							bHandled = true;
							
							rCurrent.startindex = rDamage.startindex;
							rCurrent.endindex = rDamage.endindex;
							rCurrent.entity = cur_entity;

							i = rDamage.endindex;
							cur_entity = nil;
						end
					end
					
					if not bHandled then
						-- DETERMINE THE EFFECT DATA
						local eff_data = { "DMGO:" };
						if rDamage.clauses[1].dicestr ~= "" then
							table.insert(eff_data, rDamage.clauses[1].dicestr);
						end
						if #(rDamage.clauses[1].stat) > 0 then
							table.insert(eff_data, StringManager.convertAbilityWordArrayToEffectString(rDamage.clauses[1].stat));
						end
						if rDamage.clauses[1].subtype ~= "" then
							table.insert(eff_data, rDamage.clauses[1].subtype);
						end
					
						-- SET THE EFFECT DATA AS THE CURRENT
						rCurrent = {};
						rCurrent.name = table.concat(eff_data, " ");
						rCurrent.startindex = rDamage.startindex;
						rCurrent.endindex = rDamage.endindex;
						rCurrent.entity = cur_entity;

						i = rDamage.endindex;
						cur_entity = nil;
					end
					
				-- CHECK FOR EXTRA DAMAGE EFFECTS
				elseif rDamage.extraflag and not rDamage.ongoingflag then
					local bHandled = false;

					-- ONE OFF (PHB - Dire Radiance, Hellish Rebuke)
					if (rDamage.clauses[1].dicestr ~= "") and (#(rDamage.clauses[1].stat) > 0) then
						bHandled = true;
					end
					
					-- LEVEL CONTINUATION CLAUSES
					if not bHandled and bLevelClause then
						local sModType = "DMG";
						if rDamage.clauses[1].basemult > 0 then
							sModType = "DMGW";
						end
						rCurrent = buildContinuationEffect(effects, false, { rDamage.clauses[1].dicestr }, rDamage.clauses[1].stat, { primary = sModType }, "");
						if rCurrent then
							bHandled = true;
							
							rCurrent.startindex = rDamage.startindex;
							rCurrent.endindex = rDamage.endindex;
							rCurrent.entity = cur_entity;

							i = rDamage.endindex;
							cur_entity = nil;
						end
					end
					
					if not bHandled then
						-- DETERMINE THE EFFECT DATA
						local eff_endindex = i;
						local eff_data = {};
						if rDamage.clauses[1].basemult > 0 then
							table.insert(eff_data, "DMGW:");
							table.insert(eff_data, "" .. rDamage.clauses[1].basemult);

						else
							table.insert(eff_data, "DMG:");
							if rDamage.clauses[1].dicestr ~= "" then
								table.insert(eff_data, rDamage.clauses[1].dicestr);
							end
							if #(rDamage.clauses[1].stat) > 0 then
								table.insert(eff_data, StringManager.convertAbilityWordArrayToEffectString(rDamage.clauses[1].stat));
							end
							if rDamage.clauses[1].subtype ~= "" then
								table.insert(eff_data, rDamage.clauses[1].subtype);
							end
						end
					
						-- CHECK TO SEE IF IT ONLY APPLIES TO SPECIFIC DAMAGE ROLLS
						local sApply = nil;
						local bBreakAfter = nil;
						local sExpire = nil;
						if StringManager.isWord(words[i+1], {"to", "on", "with"}) then
							local rTarget = parseTargetPhrase(words, i+2, wordsCreatureName);
							if rTarget then
								if rTarget.sType == "attack" then
									if #(rTarget.aModifiers) > 0 then
										for keySecondary, sSecondary in pairs(rTarget.aModifiers) do
											table.insert(eff_data, sSecondary);
										end
									end
								end
								rDamage.endindex = rTarget.nIndex;
								if rTarget.bSingle then
									sApply = "roll";
								end
							end
						end

						-- IF THIS EFFECT IS APPLIED TO A TARGET, THEN ONE-SHOT IT
						local nStart = rDamage.startindex;
						if StringManager.isWord(words[nStart - 1], "an") then
							nStart = nStart - 1;
						end
						if StringManager.isWord(words[nStart - 1], {"takes", "take"}) then
							sApply = "roll";
							bBreakAfter = true;
							sExpire = "";
						end

						-- SET THE EFFECT DATA AS THE CURRENT
						rCurrent = {};
						rCurrent.name = table.concat(eff_data, " ");
						rCurrent.startindex = rDamage.startindex;
						rCurrent.endindex = rDamage.endindex;
						rCurrent.entity = cur_entity or "you";
						rCurrent.extradmg = true;
						rCurrent.sApply = sApply;
						rCurrent.bBreakAfter = bBreakAfter;
						rCurrent.expire = sExpire;

						i = rDamage.endindex;
						cur_entity = nil;
					end
				end -- END EXTRA DAMAGE
			end -- END DAMAGE CLAUSE EXISTENCE CHECK

  		-- ADD
  		elseif add_flag then
  			local rValue = PowersManager.parseValuePhrase(words, i+1);
  			if rValue then
  				local j = rValue.nIndex;
  				if StringManager.isWord(words[j+1], "to") then
  					local modtype = {};
  					local mod_end = j + 2;
  					local sApply = nil;
  					j = j + 2;
  					while words[j] do
  						if StringManager.isWord(words[j], { "your", "and", "the" }) then
  							-- SKIP

  						elseif StringManager.isWord(words[j], { "next" }) then
							sApply = "roll";

  						elseif StringManager.isWord(words[j], "damage") then
  							table.insert(modtype, "DMG");
  							if StringManager.isWord(words[j+1], "roll") then
								sApply = "roll";
  								j = j + 1;
  							elseif StringManager.isWord(words[j+1], "rolls") then
  								j = j + 1;
  							elseif StringManager.isWord(words[j+1], "dealt") then
  								j = j + 1;
								-- ONE OFF (PHB - Shadowfell Gloves, Extra Damage Action)
  								if not (StringManager.isWord(words[j+1], "by") and StringManager.isWord(words[j+2], "any")) then
									sApply = "roll";
  								end
  							else
								sApply = "roll";
  							end
  							mod_end = j;

  						elseif StringManager.isWord(words[j], "attack") then
  							table.insert(modtype, "ATK");
  							if StringManager.isWord(words[j+1], "roll") then
								sApply = "roll";
  								j = j + 1;
  							elseif StringManager.isWord(words[j+1], { "rolls" }) then
  								j = j + 1;
  							end
  							mod_end = j;

  						elseif StringManager.isWord(words[j], "healing") then
  							table.insert(modtype, "HEAL");
  							mod_end = j;
  						
  						elseif StringManager.isWord(words[j], "ac") then
  							table.insert(modtype, "AC");
  							mod_end = j;

  						elseif StringManager.isWord(words[j], "speed") then
  							table.insert(modtype, "SPEED");
  							mod_end = j;

  						else
  							break;
  						end

  						j = j + 1;
  					end
  					
  					if #modtype > 0 then
  						-- ONE OFF (PHB - Stir the Hornet's Nest)
  						local sSecondary = nil;
  						if StringManager.isWord(words[mod_end+1], "when") and StringManager.isWord(words[mod_end+2], "making") and
  								StringManager.isWord(words[mod_end+3], "ranged") and StringManager.isWord(words[mod_end+4], "attacks") then
  							sSecondary = "ranged";
  							mod_end = mod_end + 4;
  						end
  						
						local mod_results = {};
						local sModDice = nil;
						if #(rValue.aDice) > 0 then
							sModDice = StringManager.convertDiceWordArrayToDiceString(rValue.aDice);
						end
						local sModStat = nil;
						if #(rValue.aAbilities) > 0 then
							sModStat = StringManager.convertAbilityWordArrayToEffectString(rValue.aAbilities);
						end
						for k, v in pairs(modtype) do
							local aLocalModResult = { v .. ":" };

							if sModDice then
								table.insert(aLocalModResult, sModDice);
							end
							if sModStat then
								table.insert(aLocalModResult, sModStat);
							end
							if sSecondary then
								table.insert(aLocalModResult, sSecondary);
							end

							table.insert(mod_results, table.concat(aLocalModResult, " "));
						end

						rCurrent = {};
						rCurrent.name = table.concat(mod_results, "; ");
						rCurrent.startindex = i;
						rCurrent.endindex = mod_end;
						rCurrent.entity = cur_entity;
						rCurrent.sApply = sApply;

						i = mod_end;
						cur_entity = nil;
					end
  				
  				-- ONE OFF (PHB - Closing Spell)
  				elseif StringManager.isWord(words[j+1], "damage") then
					rCurrent = {};
					rCurrent.name = "DMG: ";
					if #(rValue.aDice) > 0 then
						rCurrent.name = rCurrent.name .. StringManager.convertDiceWordArrayToDiceString(rValue.aDice);
					end
					if #(rValue.aAbilities) > 0 then
						rCurrent.name = rCurrent.name .. StringManager.convertAbilityWordArrayToEffectString(rValue.aAbilities);
					end
					rCurrent.startindex = i;
					rCurrent.endindex = rValue.nIndex + 1;
					rCurrent.entity = cur_entity;
					rCurrent.extradmg = true;
					rCurrent.sApply = "roll";

					i = rValue.nIndex + 1;
					cur_entity = nil;
  				end
  			end  -- END ADD VALUE CHECK
		
		-- INCREASE
		elseif increase_flag then
			-- SETUP
			local aModType = {};
			local aModDice = {};
			local aModStat = {};
			local nModStart = i;
			local nModEnd = i;
			local bContinuation = false;
			
			-- LOOK BACKWARDS FIRST
			if StringManager.isWord(words[i-1], "speed") then
				table.insert(aModType, { primary = "SPEED" });
				nModStart = i - 1;
			elseif StringManager.isWord(words[i-1], "vulnerability") then
				bContinuation = true;
				table.insert(aModType, { primary = "VULN" });
				nModStart = i - 1;
			elseif StringManager.isWord(words[i-1], {"bonus", "it", "penalty"}) then
				bContinuation = true;
				nModStart = i - 1;
			end

			-- THEN LOOK FORWARDS
			local j = i + 1;
			while words[j] do
				if StringManager.isWord(words[j], {"the", "ally's", "by", "to", "a"}) then
					-- SKIP

				elseif StringManager.isWord(words[j], "speed") then
					table.insert(aModType, { primary = "SPEED" });
					nModEnd = j;

				elseif StringManager.isWord(words[j], "bonus") then
					bContinuation = true;
					nModEnd = j;

				elseif StringManager.isWord(words[j], "extra") and StringManager.isWord(words[j+1], "damage") then
					bContinuation = true;
					table.insert(aModType, { primary = "DMG" });
					j = j + 1;
					nModEnd = j;
				
				-- ONE OFF (PHB - Dirty Fighting)
				elseif StringManager.isWord(words[j], "damage") and StringManager.isWord(words[j+1], "you") and
						StringManager.isWord(words[j+2], "deal") and StringManager.isWord(words[j+3], "when") and
						StringManager.isWord(words[j+4], "using") and StringManager.isWord(words[j+5], "a") and
						StringManager.isWord(words[j+6], "weapon") and StringManager.isWord(words[j+7], "by") and
						StringManager.isWord(words[j+8], "a") and StringManager.isWord(words[j+9], "number") and
						StringManager.isWord(words[j+10], "equal") and StringManager.isWord(words[j+11], "to") then
					table.insert(aModType, { primary = "DMG" });
					j = j + 11;
					nModEnd = j;

				else
					local rValue = PowersManager.parseValuePhrase(words, j);
					if rValue then
						nModEnd = rValue.nIndex;
						aModDice = rValue.aDice;
						aModStat = rValue.aAbilities;
						j = nModEnd;
					else
						break;
					end
				end
				
				j = j + 1;
			end
			
			-- CHECK FOR VALID MODIFIER
			if (bContinuation or (#aModType > 0)) and ((#aModStat > 0) or (#aModDice > 0)) then
				if bContinuation then
					while bContinuation do
						bContinuation = false;

						if #combo_effect > 0 then
							parseEffectsAdd(effects, combo_effect, exp_effect, wordsCreatureName);
							exp_effect = "";
							combo_effect = {};
						end
						
						rCurrent = buildContinuationEffect(effects, false, aModDice, aModStat, aModType);
						if rCurrent then
							-- ONE OFF (PHB - Stalwart Guard)
							if StringManager.isWord(words[nModEnd+1], "and") and StringManager.isWord(words[nModEnd+2], "apply") and 
									StringManager.isWord(words[nModEnd+3], "it") and StringManager.isWord(words[nModEnd+4], "to") and 
									StringManager.isWord(words[nModEnd+5], "your") and StringManager.isWord(words[nModEnd+6], "allies'") and 
									StringManager.isWord(words[nModEnd+7], "reflex") and StringManager.isWord(words[nModEnd+8], "defense") then
								nModEnd = nModEnd + 8;
								rCurrent.name = rCurrent.name .. "; REF: " .. StringManager.convertDiceWordArrayToDiceString(aModDice, false) .. " shield";
							elseif StringManager.isWord(words[nModEnd+1], "and") and StringManager.isWord(words[nModEnd+2], "applies") and 
									StringManager.isWord(words[nModEnd+3], "to") and StringManager.isWord(words[nModEnd+4], "reflex") and 
									StringManager.isWord(words[nModEnd+5], "defense") then
								nModEnd = nModEnd + 5;
								rCurrent.name = rCurrent.name .. "; REF: " .. StringManager.convertDiceWordArrayToDiceString(aModDice, false) .. " shield";
							end

							rCurrent.startindex = nModStart;
							rCurrent.endindex = nModEnd;
							rCurrent.entity = cur_entity;

							-- CHECK FOR FOLLOW-ON CONTINUATIONS
							if StringManager.isWord(words[nModEnd+1], "at") and 
									words[nModEnd+2] and string.match(words[nModEnd+2], "^%d?%d[st][th]$") and
									StringManager.isWord(words[nModEnd+3], "level") then

								rCurrent.endindex = nModEnd + 3;

								local j = nModEnd + 4;
								if StringManager.isWord(words[j], "and") then
									j = j + 1;
								end
								if StringManager.isWord(words[j], "to") then
									j = j + 1;
								end

								local rValue = PowersManager.parseValuePhrase(words, j);
								if rValue then
									table.insert(combo_effect, rCurrent);

									nModStart = nModEnd + 4;
									nModEnd = rValue.nIndex;
									aModDice = rValue.aDice;
									aModStat = rValue.aAbilities;

									bContinuation = true;
								end
							end

							i = nModEnd;
							cur_entity = nil;
						end
					end
				else
					local sModDice = nil;
					if #(aModDice) > 0 then
						sModDice = StringManager.convertDiceWordArrayToDiceString(aModDice);
					end
					local sModStat = nil;
					if #(aModStat) > 0 then
						sModStat = StringManager.convertAbilityWordArrayToEffectString(aModStat);
					end
					local aModResults = {};
					for keyMod, rMod in pairs(aModType) do
						local aMod = { rMod.primary .. ":" };
						if sModDice then
							table.insert(aMod, sModDice);
						end
						if sModStat then
							table.insert(aMod, sModStat);
						end
						if rMod.secondary then
							table.insert(aMod, rMod.secondary);
						end
						table.insert(aModResults, table.concat(aMod, " "));
					end

					rCurrent = {};
					rCurrent.startindex = nModStart;
					rCurrent.endindex = nModEnd;
					rCurrent.entity = cur_entity;
					rCurrent.name = table.concat(aModResults, "; ");

					i = nModEnd;
					cur_entity = nil;
				end
			end
		
		-- RAGE
		elseif rage_flag then
			-- DETERMINE RAGE NAME
			local nRageStart = i;
			local nRageEnd = i + 3;
			local aRage = { "RAGE:" };

			local j = i + 3;
			while words[j] do
				if StringManager.isWord(words[j], ".") then
					break;
				else
					table.insert(aRage, string.upper(string.sub(words[j], 1, 1)) .. string.lower(string.sub(words[j], 2)));
					nRageEnd = j;
				end
				j = j + 1;
			end
			
			-- ABSORB THE TYPICAL "UNTIL THE RAGE ENDS"
			if StringManager.isWord(words[j+1], "until") and StringManager.isWord(words[j+2], "the") and
					StringManager.isWord(words[j+3], "rage") and StringManager.isWord(words[j+4], "ends") then
				j = j + 4;
			end
			
			-- SET THE EXPIRATION FOR THE RAGE EFFECT
			exp_effect = "encounter";
			
			-- SET THE EFFECT
			rCurrent = {};
			rCurrent.name = table.concat(aRage, " ");
			rCurrent.startindex = nRageStart;
			rCurrent.endindex = nRageEnd;
			rCurrent.entity = cur_entity;

			cur_entity = nil;
			i = j;
		
		end  -- END GIANT FLAG CHECK LOOP
		
		-- INCREMENT WORD INDEX
		i = i + 1;
  	end
  	
  	-- HANDLE DANGLING EFFECT
  	if rCurrent then
		table.insert(combo_effect, rCurrent);
	end
  	if #combo_effect > 0 then
		parseEffectsAdd(effects, combo_effect, exp_effect, wordsCreatureName);
  	end
  	
	-- ADD ZONE/AURA TAGS, AS APPROPRIATE
	if #effects > 0 then
		local bZone = StringManager.isWord("zone", StringManager.split(string.lower(DB.getValue(nodePower, "keywords", "")), ",", true));
		local bAura = StringManager.isWord("aura", string.lower(DB.getValue(nodePower, "action", ""))) or
				(DB.getValue(nodePower, "powertype", "") == "Z");
		if bZone or bAura then
			for kEffect, rEffect in pairs(effects) do
				if bAura then
					rEffect.name = "AURA; " .. rEffect.name;
				elseif bZone then
					rEffect.name = "ZONE; " .. rEffect.name;
				end
			end
		end
	end

	-- RESULTS
	return effects;
end

-- SEPERATE OUT PERIODS, COLONS AND SEMICOLONS
function parseHelper(s, words, words_stats)
  	-- SETUP
  	local final_words = {};
  	local final_words_stats = {};
  	
  	-- SEPARATE WORDS ENDING IN PERIODS, COLONS AND SEMICOLONS
  	for i = 1, #words do
		local nSpecialChar = string.find(words[i], "[%.:;]");
		if nSpecialChar then
			local sWord = words[i];
			local nStartPos = words_stats[i].startpos;
			while nSpecialChar do
				if nSpecialChar > 1 then
					table.insert(final_words, string.sub(sWord, 1, nSpecialChar - 1));
					table.insert(final_words_stats, {startpos = nStartPos, endpos = nStartPos + nSpecialChar - 1});
				end
				
				table.insert(final_words, string.sub(sWord, nSpecialChar, nSpecialChar));
				table.insert(final_words_stats, {startpos = nStartPos + nSpecialChar - 1, endpos = nStartPos + nSpecialChar});
				
				nStartPos = nStartPos + nSpecialChar;
				sWord = string.sub(sWord, nSpecialChar + 1);
				
				nSpecialChar = string.find(sWord, "[%.:;]");
			end
			if string.len(sWord) > 0 then
				table.insert(final_words, sWord);
				table.insert(final_words_stats, {startpos = nStartPos, endpos = words_stats[i].endpos});
			end
		else
			table.insert(final_words, words[i]);
			table.insert(final_words_stats, words_stats[i]);
		end
  	end
  	
	-- RESULTS
	return final_words, final_words_stats;
end

function consolidationHelper(aMasterAbilities, aWordStats, sAbilityType, aNewAbilities)
	-- ITERATE THROUGH NEW ABILITIES
	for i = 1, #aNewAbilities do

		-- ADD TYPE
		aNewAbilities[i].type = sAbilityType;

		-- CONVERT WORD INDICES TO CHARACTER POSITIONS
		aNewAbilities[i].startpos = aWordStats[aNewAbilities[i].startindex].startpos;
		aNewAbilities[i].endpos = aWordStats[aNewAbilities[i].endindex].endpos;
		aNewAbilities[i].startindex = nil;
		aNewAbilities[i].endindex = nil;

		-- ADD TO MASTER ABILITIES LIST
		table.insert(aMasterAbilities, aNewAbilities[i]);
	end
end

function parsePowerDescription(s, sCreatureName)
	-- GET RID OF SOME PROBLEM CHARACTERS, AND MAKE LOWERCASE
	local sLocal = string.gsub(s, "’", "'");
	sLocal = string.gsub(sLocal, "–", "-");
	sLocal = string.lower(sLocal);
	
	-- PARSE THE WORDS
	local aWords, aWordStats = StringManager.parseWords(sLocal, ".:;");
	
	-- ADD/SEPARATE MARKERS FOR END OF SENTENCE, END OF CLAUSE AND CLAUSE LABEL SEPARATORS
	aWords, aWordStats = parseHelper(s, aWords, aWordStats);
	
	-- BUILD MASTER LIST OF ALL POWER ABILITIES
	local aMasterAbilities = {};
	consolidationHelper(aMasterAbilities, aWordStats, "attack", parseAttacks(aWords));
	consolidationHelper(aMasterAbilities, aWordStats, "damage", parseDamages(aWords));
	consolidationHelper(aMasterAbilities, aWordStats, "heal", parseHeals(aWords));
	consolidationHelper(aMasterAbilities, aWordStats, "effect", parseEffects(aWords, sCreatureName, nodePower));
	
	-- SORT THE ABILITIES
	table.sort(aMasterAbilities, function(a,b) return a.startpos < b.startpos end)
	
	-- RESULTS
	return aMasterAbilities;
end
