-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function import()
	local sFile = Interface.dialogFileOpen();
	if sFile then
		DB.import(sFile, "charsheet", "character");
		ChatManager.SystemMessage("Imported character(s) from: " .. sFile);
	end
end

function export(nodeChar)
	local sFile = Interface.dialogFileSave();
	if sFile then
		if nodeChar then
			DB.export(sFile, nodeChar, "character");
			ChatManager.SystemMessage("Exported character: " .. DB.getValue(nodeChar, "name", ""));
		else
			DB.export(sFile, "charsheet", "character", true);
			ChatManager.SystemMessage("Exported all characters");
		end
	end
end

--
-- POWER MANAGEMENT
--

function addPowerDB(nodeChar, nodeSource, sClass)
	-- Validate parameters
	if not nodeChar or not nodeSource then
		return;
	end

	-- Get the powers node
	local nodePowerList = nodeChar.createChild("powers");
	local nodeNewPower = nodePowerList.createChild();
							
	-- Change the power mode so that all powers are shown
	DB.setValue(nodeChar, "powermode", "string", "standard");

	-- Set up the basic power fields
  	local sName = DB.getValue(nodeSource, "name", "");
  	local sSource = DB.getValue(nodeSource, "source", "");
  	if sSource == "" then
  		local nodeOverParent = nodeSource.getChild("....");
  		if nodeOverParent then
  			if nodeOverParent.getName() == "item" or nodeOverParent.getName() == "inventorylist" then
  				sSource = "Item";
  			end
  		end
  	end
  	if sSource == "Item" then
		if sClass == "reference_magicitem_property" then
			local nodeItemName = nodeSource.getChild("...name");
			if nodeItemName then
				sName = "Property - " .. nodeItemName.getValue();
			end
		else
			if string.match(sName, "^Power -") then
				local nodeItemName = nodeSource.getChild("...name");
				if nodeItemName then
					sName = string.gsub(sName, "Power -", nodeItemName.getValue(), 1);
				end
			else
				sName = string.gsub(sName, " Power - ", " ");
			end
		end
  	end
  	DB.setValue(nodeNewPower, "source", "string", sSource);
  	DB.setValue(nodeNewPower, "recharge", "string", DB.getValue(nodeSource, "recharge", "-"));
  	DB.setValue(nodeNewPower, "keywords", "string", DB.getValue(nodeSource, "keywords", "-"));
  	DB.setValue(nodeNewPower, "range", "string", DB.getValue(nodeSource, "range", "-"));
	DB.setValue(nodeNewPower, "shortdescription", "string", DB.getValue(nodeSource, "shortdescription", ""));

	-- Set up the action field
	local sAction = DB.getValue(nodeSource, "action", "-");
	if sAction == "Standard Action" then
		sAction = "Standard";
	elseif sAction == "Move Action" then
		sAction = "Move";
	elseif sAction == "Minor Action" then
		sAction = "Minor";
	elseif sAction == "Free Action" then
		sAction = "Free";
	elseif sAction == "Immediate Interrupt" then
		sAction = "Interrupt";
	elseif sAction == "Immediate Reaction" then
		sAction = "Reaction";
	end
	DB.setValue(nodeNewPower, "action", "string", sAction);

	-- Set the power description (while replacing any item enhancement bonus information)
	local sDesc = DB.getValue(nodeSource, "shortdescription", "-");
	if sSource == "Item" then
		local sEnhancement = "";
		if string.match(sName, " %+%d$") then
			sEnhancement = string.sub(sName, -2);
			sName = string.sub(sName, 1, -4);
		end
		if sEnhancement ~= "" then
			sDesc = string.gsub(sDesc, "equal to .* enhancement bonus%.", "equal to " .. sEnhancement .. ".");
		end
	end
	DB.setValue(nodeNewPower, "shortdescription", "string", sDesc);

  	-- Set the name once everything has settled out
  	DB.setValue(nodeNewPower, "name", "string", sName);
	
	-- Set the shortcut
	if (sClass ~= "reference_power_custom") then
		DB.setValue(nodeNewPower, "shortcut", "windowreference", sClass, nodeSource.getNodeName());
	end
	
	-- Check to see if there are any linked powers
	if sClass == "powerdesc" then
		local nodeLinkedPowers = nodeSource.getChild("linkedpowers");
		if nodeLinkedPowers then
			for _,v in pairs(nodeLinkedPowers.getChildren()) do
				local sClass, sRecord = DB.getValue(v, "link", "", "");
				if sClass == "powerdesc" then
					addPowerDB(nodeChar, DB.findNode(sRecord), sClass);
				end
			end
		else
			local sClass, sRecord = DB.getValue(nodeSource, "link", "", "");
			if sClass == "powerdesc" then
				addPowerDB(nodeChar, DB.findNode(sRecord), sClass);
			end
		end
	end

	-- Finally, parse the description
	parseDescription(nodeNewPower);

	-- Return the new power created
	return nodeNewPower;
end

function parseDescription(nodePower)
	-- Clear the attack and effect entries
	local nodePowerAbilities = nodePower.createChild("abilities");
	for _,v in pairs(nodePowerAbilities.getChildren()) do
		v.delete();
	end
	
	-- Pick up the power abilities from the description
	local sPower = DB.getValue(nodePower, "shortdescription", "");
	local aPowerAbilities = PowersManager.parsePowerDescription(sPower, "");
	
	-- Helper variables for building ability items
	local aEffectsCreated = {};
	local nAbilityCount = 0;
	local aPrevAttacks = {};

	-- Iterate through abilities to add to power ability list
	for i = 1, #aPowerAbilities do
		-- See if we should create a new ability entry
		-- If damage ability, then use the last entry if following an attack ability
		-- If effect ability, then make sure it's unique
		local nodeAbility = nil;
		local bCreate = true;
		if aPowerAbilities[i].type == "effect" then
			local sEffectKey = aPowerAbilities[i].name .. aPowerAbilities[i].expire .. aPowerAbilities[i].mod;
			if aEffectsCreated[sEffectKey] then
				bCreate = false;
			else
				aEffectsCreated[sEffectKey] = true;
			end
		elseif aPowerAbilities[i].type == "damage" and #aPrevAttacks > 0 then
			bCreate = false;
			nodeAbility = aPrevAttacks[1];
			table.remove(aPrevAttacks, 1);
		end

		-- Create a new ability entry, if needed
		if bCreate then
			nodeAbility = nodePowerAbilities.createChild();

			if aPowerAbilities[i].type == "attack" then
				table.insert(aPrevAttacks, nodeAbility);
			else
				aPrevAttacks = {};
			end

			if aPowerAbilities[i].type == "damage" then
				DB.setValue(nodeAbility, "type", "string", "attack");
			else
				DB.setValue(nodeAbility, "type", "string", aPowerAbilities[i].type);
			end

			nAbilityCount = nAbilityCount + 1;
			DB.setValue(nodeAbility, "order", "number", nAbilityCount);
		end

		-- Fill in the ability entry details
		if nodeAbility then
			if aPowerAbilities[i].type == "attack" then
				if #(aPowerAbilities[i].clauses) > 0 then
					if #(aPowerAbilities[i].clauses[1].stat) > 0 then
						DB.setValue(nodeAbility, "attackstat", "string", aPowerAbilities[i].clauses[1].stat[1]);
					end
					DB.setValue(nodeAbility, "attackstatmodifier", "number", aPowerAbilities[i].clauses[1].mod);
				end
				DB.setValue(nodeAbility, "attackdef", "string", aPowerAbilities[i].defense);
			elseif aPowerAbilities[i].type == "damage" then
				if #(aPowerAbilities[i].clauses) > 0 then
					if #(aPowerAbilities[i].clauses[1].stat) > 0 then
						local tempstr = aPowerAbilities[i].clauses[1].stat[1];
						if string.match(tempstr, "^half") then
							DB.setValue(nodeAbility, "damagestatmult", "string", "half");
							tempstr = string.sub(tempstr, 5);
						end
						if string.match(tempstr, "^double") then
							DB.setValue(nodeAbility, "damagestatmult", "string", "double");
							tempstr = string.sub(tempstr, 7);
						end
						DB.setValue(nodeAbility, "damagestat", "string", tempstr);
					end
					if #(aPowerAbilities[i].clauses[1].stat) > 1 then
						local tempstr = aPowerAbilities[i].clauses[1].stat[2];
						if string.match(tempstr, "^half") then
							DB.setValue(nodeAbility, "damagestatmult2", "string", "half");
							tempstr = string.sub(tempstr, 5);
						end
						if string.match(tempstr, "^double") then
							DB.setValue(nodeAbility, "damagestatmult2", "string", "double");
							tempstr = string.sub(tempstr, 7);
						end
						DB.setValue(nodeAbility, "damagestat2", "string", tempstr);
					end

					DB.setValue(nodeAbility, "damagetype", "string", aPowerAbilities[i].clauses[1].subtype);

					if aPowerAbilities[i].clauses[1].dicestr then
						local aDice, nMod = StringManager.convertStringToDice(aPowerAbilities[i].clauses[1].dicestr);
						DB.setValue(nodeAbility, "damagebasicdice", "dice", aDice);
						DB.setValue(nodeAbility, "damagestatmodifier", "number", nMod);
					end
					if aPowerAbilities[i].clauses[1].basemult then
						DB.setValue(nodeAbility, "damageweaponmult", "number", aPowerAbilities[i].clauses[1].basemult);
					end
				end
			elseif aPowerAbilities[i].type == "heal" then
				if #(aPowerAbilities[i].clauses) > 0 then
					if #(aPowerAbilities[i].clauses[1].stat) > 0 then
						local tempstr = aPowerAbilities[i].clauses[1].stat[1];
						if string.match(tempstr, "^half") then
							DB.setValue(nodeAbility, "healstatmult", "string", "half");
							tempstr = string.sub(tempstr, 5);
						end
						if string.match(tempstr, "^double") then
							DB.setValue(nodeAbility, "healstatmult", "string", "double");
							tempstr = string.sub(tempstr, 7);
						end
						DB.setValue(nodeAbility, "healstat", "string", tempstr);
					end
					if #(aPowerAbilities[i].clauses[1].stat) > 1 then
						local tempstr = aPowerAbilities[i].clauses[1].stat[2];
						if string.match(tempstr, "^half") then
							DB.setValue(nodeAbility, "healstatmult2", "string", "half");
							tempstr = string.sub(tempstr, 5);
						end
						if string.match(tempstr, "^double") then
							DB.setValue(nodeAbility, "healstatmult2", "string", "double");
							tempstr = string.sub(tempstr, 7);
						end
						DB.setValue(nodeAbility, "healstat2", "string", tempstr);
					end

					if aPowerAbilities[i].clauses[1].dicestr then
						local aDice, nMod = StringManager.convertStringToDice(aPowerAbilities[i].clauses[1].dicestr);
						DB.setValue(nodeAbility, "healdice", "dice", aDice);
						DB.setValue(nodeAbility, "healmod", "number", nMod);
					end

					if aPowerAbilities[i].clauses[1].subtype then
						DB.setValue(nodeAbility, "healtype", "string", aPowerAbilities[i].clauses[1].subtype);
					end

					if aPowerAbilities[i].clauses[1].basemult then
						DB.setValue(nodeAbility, "hsvmult", "number", aPowerAbilities[i].clauses[1].basemult);
					end
					if aPowerAbilities[i].clauses[1].cost then
						DB.setValue(nodeAbility, "healcost", "number", aPowerAbilities[i].clauses[1].cost);
					end
				end
			elseif aPowerAbilities[i].type == "effect" then
				DB.setValue(nodeAbility, "label", "string", aPowerAbilities[i].name);
				DB.setValue(nodeAbility, "expiration", "string", aPowerAbilities[i].expire);
				DB.setValue(nodeAbility, "effectsavemod", "number", aPowerAbilities[i].mod);
				DB.setValue(nodeAbility, "apply", "string", aPowerAbilities[i].sApply);
				DB.setValue(nodeAbility, "targeting", "string", aPowerAbilities[i].sTargeting);
			end  -- END ABILITY TYPE SWITCH
		end -- END ABILITY WINDOW EXISTENCE CHECK
	end  -- END POWER ABILITY LIST LOOP
end

function getDefaultFocus(nodeChar, sFocusType)
	-- Make sure we have a correct parameter
	local nToolOrder = 0;
	if sFocusType == "weapon" then
		nToolOrder = DB.getValue(nodeChar, "powerfocus.weapon.order", 0);
	elseif sFocusType == "implement" then
		nToolOrder = DB.getValue(nodeChar, "powerfocus.implement.order", 0);
	else
		return nil;
	end
	
	-- Look up the weapon node to make sure it is valid
	local nodeTool = nil;
	if nToolOrder > 0 then
		for _,v in pairs(DB.getChildren(nodeChar, "weaponlist")) do
			local nOrder = DB.getValue(v, "order", 0);
			if nOrder == nToolOrder then
				nodeTool = v;
			end
		end
	end
	
	-- Return the weapon node found
	return nodeTool;
end

function addPowerToWeaponDB(nodeChar, nodeSource)
	-- Parameter validation
	if not nodeChar or not nodeSource then
		return nil;
	end
	
	-- Create the new weapon entry
	local nodeWeaponList = nodeChar.createChild("weaponlist");
	if not nodeWeaponList then
		return nil;
	end
	local nodeWeapon = nodeWeaponList.createChild();
	if not nodeWeapon then
		return nil;
	end
	
	-- Determine the weapon number
	local nOrder = calcNextWeaponOrder(nodeWeaponList);
	DB.setValue(nodeWeapon, "order", "number", nOrder);

	-- Fill in the basic attributes
	DB.setValue(nodeWeapon, "name", "string", DB.getValue(nodeSource, "name", ""));
	
	-- Determine the attack type and range increment
	local sRange = DB.getValue(nodeSource, "range", "");
	local sRanged = string.match(sRange, "Ranged (%d+)");
	local sAreaBurst = string.match(sRange, "Area burst %d+ within (%d+)");
	local sAreaWall = string.match(sRange, "Area wall %d+ within (%d+)");
	if sRanged then
		DB.setValue(nodeWeapon, "type", "number", 1);
		DB.setValue(nodeWeapon, "rangeincrement", "number", tonumber(sRanged) or 0);
	elseif sAreaBurst then
		DB.setValue(nodeWeapon, "type", "number", 1);
		DB.setValue(nodeWeapon, "rangeincrement", "number", tonumber(sAreaBurst) or 0);
	elseif sAreaWall then
		DB.setValue(nodeWeapon, "type", "number", 1);
		DB.setValue(nodeWeapon, "rangeincrement", "number", tonumber(sAreaWall) or 0);
	end

	-- Load up the properties field
	local aProperties = {};

	local actionval = DB.getValue(nodeSource, "action", "");
	if actionval == "Standard Action" then
		table.insert(aProperties, "[s]");
	elseif actionval == "Move Action" then
		table.insert(aProperties, "[mo]");
	elseif actionval == "Minor Action" then
		table.insert(aProperties, "[mi]");
	elseif actionval == "Free Action" then
		table.insert(aProperties, "[f]");
	elseif actionval == "Immediate Interrupt" then
		table.insert(aProperties, "[i]");
	elseif actionval == "Immediate Reaction" then
		table.insert(aProperties, "[r]");
	end
	
	local rechargeval = DB.getValue(nodeSource, "recharge", "");
	if string.sub(rechargeval, 1, 9) == "Encounter" then
		table.insert(aProperties, "[e]");
	elseif string.sub(rechargeval, 1, 5) == "Daily" then
		table.insert(aProperties, "[d]");
	end

	local keywords = DB.getValue(nodeSource, "keywords", "");
	if keywords ~= "" then
		table.insert(aProperties, "[K:" .. keywords .. "]");
	end

	DB.setValue(nodeWeapon, "properties", "string", table.concat(aProperties, ""));

	-- Determine if this is a weapon/implement power
	local nodeTool = nil;
	if string.match(string.lower(keywords), "weapon") then
		nodeTool = getDefaultFocus(nodeChar, "weapon");
	elseif string.match(string.lower(keywords), "implement") then
		nodeTool = getDefaultFocus(nodeChar, "implement");
	end

	-- Finally, parse the description string for attack and damage clauses
	local sPower = DB.getValue(nodeSource, "shortdescription", "");
	local aPowerAbilities = PowersManager.parsePowerDescription(sPower, "");
	
	local bAttackFound = false;
	local bDamageFound = false;
	for i = 1, #aPowerAbilities do
		if not bAttackFound and aPowerAbilities[i].type == "attack" and #(aPowerAbilities[i].clauses) > 0 then
			bAttackFound = true;

			DB.setValue(nodeWeapon, "attackdef", "string", aPowerAbilities[i].defense);
			if #(aPowerAbilities[i].clauses[1].stat) > 0 then
				DB.setValue(nodeWeapon, "attackstat", "string", aPowerAbilities[i].clauses[1].stat[1]);
			end
			local nMod = aPowerAbilities[i].clauses[1].mod;
			if nodeTool then
				nMod = nMod + DB.getValue(nodeTool, "bonus", 0);
			end
			DB.setValue(nodeWeapon, "bonus", "number", nMod);
		end
		if not bDamageFound and aPowerAbilities[i].type == "damage" and #(aPowerAbilities[i].clauses) > 0 then
			bDamageFound = true;
			
			if aPowerAbilities[i].clauses[1].dicestr then
				local aDice, nMod = StringManager.convertStringToDice(aPowerAbilities[i].clauses[1].dicestr);

				if aPowerAbilities[i].clauses[1].basemult > 0 and nodeTool then
					local aBaseDice = DB.getValue(nodeTool, "damagedice", {});

					for i = 1, aPowerAbilities[i].clauses[1].basemult do
						for j = 1, #aBaseDice do
							table.insert(aDice, aBaseDice[j]);
						end
					end
				end

				if nodeTool then
					nMod = nMod + DB.getValue(nodeTool, "damagebonus", 0);

					local aCritDice = DB.getValue(nodeTool, "criticaldice", {});
					local nCritMod = DB.getValue(nodeTool, "criticalbonus", 0)
					local sCritDmgType = DB.getValue(nodeTool, "criticaldamagetype", "");

					DB.setValue(nodeWeapon, "criticaldice", "dice", aCritDice);
					DB.setValue(nodeWeapon, "criticalbonus", "number", nCritMod);
					DB.setValue(nodeWeapon, "criticaldamagetype", "string", sCritDmgType);
				end

				DB.setValue(nodeWeapon, "damagedice", "dice", aDice);
				DB.setValue(nodeWeapon, "damagebonus", "number", nMod);
			end

			if #(aPowerAbilities[i].clauses[1].stat) > 0 then
				DB.setValue(nodeWeapon, "damagestat", "string", aPowerAbilities[i].clauses[1].stat[1]);
			end
			DB.setValue(nodeWeapon, "damagetype", "string", aPowerAbilities[i].clauses[1].subtype);
		end
	end
	
	-- Set the shortcut fields
	DB.setValue(nodeWeapon, "shortcut", "windowreference", "powerdesc", nodeSource.getNodeName());
	
	-- Return the new weapon node
	return nodeWeapon;
end

function checkForSecondWind(nodeChar)
	-- Validate parameters
	if not nodeChar then
		return nil;
	end
	
	-- Get the powers node
	local nodePowerList = nodeChar.createChild("powers");
	
	-- Check for an existing Second Wind power
	for _,v in pairs(nodePowerList.getChildren()) do
		if DB.getValue(v, "name", "") == "Second Wind" then
			return v;
		end
	end
	
	-- Create a new power node
	local nodeNewPower = nodePowerList.createChild();
	
	-- Set up the basic power fields
  	DB.setValue(nodeNewPower, "name", "string", "Second Wind");
  	DB.setValue(nodeNewPower, "source", "string", "General");
  	DB.setValue(nodeNewPower, "recharge", "string", "Encounter");
  	DB.setValue(nodeNewPower, "keywords", "string", "Healing");
  	DB.setValue(nodeNewPower, "range", "string", "Personal");
	DB.setValue(nodeNewPower, "action", "string", "Standard");
	DB.setValue(nodeNewPower, "shortdescription", "string", "Effect: You spend a healing surge, and gain a +2 bonus to all defenses until the start of your next turn.");
	
	-- Now parse the description to pre-fill the ability items
	parseDescription(nodeNewPower);

	-- Return the new power created
	return nodeNewPower;
end

function checkForActionPoint(nodeChar)
	-- Validate parameters
	if not nodeChar then
		return nil;
	end
	
	-- Get the powers node
	local nodePowerList = nodeChar.createChild("powers");
	
	-- Check for an existing Action Point power
	for _,v in pairs(nodePowerList.getChildren()) do
		if DB.getValue(v, "name", "") == "Action Point" then
			return v;
		end
	end
	
	-- Create a new power node
	local nodeNewPower = nodePowerList.createChild();
	
	-- Set up the basic power fields
  	DB.setValue(nodeNewPower, "name", "string", "Action Point");
  	DB.setValue(nodeNewPower, "source", "string", "General");
  	DB.setValue(nodeNewPower, "recharge", "string", "Action Point");
  	DB.setValue(nodeNewPower, "prepared", "number", 1);
  	DB.setValue(nodeNewPower, "range", "string", "Personal");
	DB.setValue(nodeNewPower, "action", "string", "Free");
	
	DB.setValue(nodeNewPower, "shortdescription", "string", "You gain an extra action this turn. You decide if the action is a standard action, a move action, or a minor action.;\rPrerequisite: You can spend an action point only during your turn, but never during a surprise round.;\rSpecial: After you spend an action point, you must take a short rest before you can spend another.");
	
	-- Return the new power created
	return nodeNewPower;
end

--
-- ITEM/FOCUS MANAGEMENT
--

function removeItemFromWeaponDB(nodeItem)
	-- Parameter validation
	if not nodeItem then
		return false;
	end
	
	-- Check to see if any of the weapon nodes linked to this item node should be deleted
	local sItemNode = nodeItem.getNodeName();
	local bMeleeFound = false;
	local bRangedFound = false;
	for _,v in pairs(DB.getChildren(nodeItem, "...weaponlist")) do
		local sClass, sRecord = DB.getValue(v, "shortcut", "", "");
		if sRecord == sItemNode then
			local sType = DB.getValue(v, "type", 0);
			if sType == 1 and not bMeleeFound then
				bMeleeFound = true;
				v.delete();
			elseif sType == 0 and not bRangedFound then
				bRangedFound = true;
				v.delete();
			end
		end
	end
	
	-- We didn't find any linked weapons
	return (bMeleeFound or bRangedFound);
end

function calcNextWeaponOrder(nodeWeaponList)
	local nOrder = 1;
	
	if nodeWeaponList then
		local aOrder = {};
		for _,v in pairs(nodeWeaponList.getChildren()) do
			local nTemp = DB.getValue(v, "order", 0);
			aOrder[nTemp] = true;
		end

		while aOrder[nOrder] do
			nOrder = nOrder + 1;
		end
	end
	
	return nOrder;
end

function addWeaponDB(nodeChar, nodeItem)
	-- Parameter validation
	if not nodeChar or not nodeItem then
		return nil;
	end
	if DB.getValue(nodeItem, "mitype", "") ~= "weapon" then
		return nil;
	end
	
	-- Get the weapon list we are going to add to
	local nodeWeaponList = nodeChar.createChild("weaponlist");
	if not nodeWeaponList then
		return nil;
	end
	
	-- Grab some information from the item to populate the new weapon entries
	local sType = nil;
	local sSubclass = string.lower(DB.getValue(nodeItem, "subclass", ""));
	if string.match(sSubclass, "melee") then
		sType = "melee";
	elseif string.match(sSubclass, "ranged") then
		sType = "ranged";
	end

	local nRange = DB.getValue(nodeItem, "range", 0);
	
	local sName = DB.getValue(nodeItem, "name", "");
	local sProperties = DB.getValue(nodeItem, "properties", "");
	
	local sCritical = DB.getValue(nodeItem, "critical", "");
	local aCritDice = {};
	local nCritMod = 0;
	local sCritDmgType = "";
	if sCritical ~= "" then
		local nStarts, nEnds, sDice, sDmgType = string.find(sCritical, "%+(%d[d%+%d%s]*)%s?(%a*)%scritical%sdamage");
		if nStarts then
			sCritical = string.sub(sCritical, nEnds+1);
			if string.sub(sCritical, 1, 5) == ", or " then
				sCritical = string.sub(sCritical, 6);
			elseif string.sub(sCritical, 1, 6) == ", and " then
				sCritical = string.sub(sCritical, 7);
			end
			
			aCritDice, nCritMod = StringManager.convertStringToDice(sDice);
			sCritDmgType = sDmgType;
		end
		if sCritical ~= "" then
			if sProperties ~= "" then
				sProperties = sProperties .. ", ";
			end
			sProperties = sProperties .. "Crit: " .. sCritical;
		end
	end

	local nProfBonus = DB.getValue(nodeItem, "profbonus", 0);
	local nEnhBonus = DB.getValue(nodeItem, "bonus", 0);

	local sDamage = DB.getValue(nodeItem, "damage", "");
	local aDice, nMod = StringManager.convertStringToDice(sDamage);
	
	local nodeWeapon = nodeWeaponList.createChild();
	local nodeWeapon2 = nil;
	if nodeWeapon then
		-- Set the shortcut fields
		DB.setValue(nodeWeapon, "shortcut", "windowreference", "item", nodeItem.getNodeName());

		-- Calculate the order number
		local nOrder = calcNextWeaponOrder(nodeWeaponList);
		DB.setValue(nodeWeapon, "order", "number", nOrder);
		
		-- Fill in the basic, attack and damage fields
		DB.setValue(nodeWeapon, "name", "string", sName);
		DB.setValue(nodeWeapon, "properties", "string", sProperties);
		DB.setValue(nodeWeapon, "bonus", "number", nProfBonus + nEnhBonus);
		DB.setValue(nodeWeapon, "damagedice", "dice", aDice);
		DB.setValue(nodeWeapon, "damagebonus", "number", nMod + nEnhBonus);
		DB.setValue(nodeWeapon, "criticaldice", "dice", aCritDice);
		DB.setValue(nodeWeapon, "criticalbonus", "number", nCritMod);
		DB.setValue(nodeWeapon, "criticaldamagetype", "string", sCritDmgType);

		if sType == "melee" then
			-- Fill in the melee specific fields
			DB.setValue(nodeWeapon, "type", "number", 0);
			DB.setValue(nodeWeapon, "attackdef", "string", "ac");

			if string.match(string.lower(sProperties), "heavy thrown") or string.match(string.lower(sProperties), "light thrown") then
				nodeWeapon2 = nodeWeaponList.createChild();
				if nodeWeapon2 then
					-- Set the shortcut fields
					DB.setValue(nodeWeapon2, "shortcut", "windowreference", "item", nodeItem.getNodeName());

					-- Calculate the order number
					local nOrder = calcNextWeaponOrder(nodeWeaponList);
					DB.setValue(nodeWeapon2, "order", "number", nOrder);

					-- Fill in the basic, attack and damage fields
					DB.setValue(nodeWeapon2, "type", "number", 1);
					DB.setValue(nodeWeapon2, "name", "string", sName);
					DB.setValue(nodeWeapon2, "properties", "string", sProperties);

					DB.setValue(nodeWeapon2, "rangeincrement", "number", nRange);
					DB.setValue(nodeWeapon2, "bonus", "number", nProfBonus + nEnhBonus);
					DB.setValue(nodeWeapon2, "attackdef", "string", "ac");

					DB.setValue(nodeWeapon2, "damagedice", "dice", aDice);
					DB.setValue(nodeWeapon2, "damagebonus", "number", nMod + nEnhBonus);
					DB.setValue(nodeWeapon2, "criticaldice", "dice", aCritDice);
					DB.setValue(nodeWeapon2, "criticalbonus", "number", nCritMod);
					DB.setValue(nodeWeapon2, "criticaldamagetype", "string", sCritDmgType);
				end
			end

		elseif sType == "ranged" then
			DB.setValue(nodeWeapon, "type", "number", 1);
			DB.setValue(nodeWeapon, "rangeincrement", "number", nRange);
			DB.setValue(nodeWeapon, "attackdef", "string", "ac");

		else
			DB.setValue(nodeWeapon, "type", "number", 0);
			DB.setValue(nodeWeapon, "attackdef", "string", "ac");
		end
	end
	
	return nodeWeapon, nodeWeapon2;
end

function updateEncumbrance(nodeChar)
	if not nodeChar then
		return;
	end

	local nEncTotal = 0;

	local nCount, nWeight;
	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 1 then
			nCount = DB.getValue(vNode, "count", 0);
			if nCount < 1 then
				nCount = 1;
			end
			nWeight = DB.getValue(vNode, "weight", 0);
			
			nEncTotal = nEncTotal + (nCount * nWeight);
		end
	end

	DB.setValue(nodeChar, "encumbrance.load", "number", nEncTotal);
end

--
-- PORTRAIT MANAGEMENT
--

function setPortrait(nodeChar, sPortraitFile)
	if not nodeChar or not sPortraitFile then
		return;
	end
	
	User.setPortrait(nodeChar, sPortraitFile);
	
	local wnd = Interface.findWindow("charsheet", nodeChar)
	if wnd then
		if User.isLocal() then
			wnd.localportrait.setFile(sPortraitFile);
		else
			wnd.portrait.setIcon("portrait_" .. nodeChar.getName() .. "_charlist", true);
		end
	end
	
	wnd = Interface.findWindow("identityselection", "");
	if wnd then
		for k, v in pairs(wnd.list.getWindows()) do
			if v.localdatabasenode then
				if v.localdatabasenode == nodeChar then
					v.localportrait.setFile(sPortraitFile);
				end
			end
		end
	end
end

--
-- ACTIONS
--

function useHealingSurge(nodeChar)
	-- Get the character's current wounds value
	local nWounds = DB.getValue(nodeChar, "hp.wounds", 0);
	
	-- If the character is not wounded, then let the user know and exit
	if nWounds <= 0 then
		ChatManager.Message("Character is unwounded, healing surge not used.", false, ActorManager.getActor("pc", nodeChar));
		return;
	end
	
	-- Determine whether the character has any healing surges remaining
	local nSurgesUsed = DB.getValue(nodeChar, "hp.surgesused", 0);
	local nSurgesMax = DB.getValue(nodeChar, "hp.surgesmax", 0);
	if nSurgesUsed >= nSurgesMax then
		ChatManager.Message("Character has no healing surges remaining.", false, ActorManager.getActor("pc", nodeChar));
		return;
	end
	
	-- Determine the message and amount of healing surge
	local sMessage = "Healing surge used.";
	local nSurges = DB.getValue(nodeChar, "hp.surge", 0);
	if not ModifierStack.isEmpty() then
		local sStackDesc, nStackMod = ModifierStack.getStack(true);
		sMessage = sMessage .. " (" .. sStackDesc .. ")";
		nSurges = nSurges + nStackMod;
	end
	
	-- Determine if wounds are greater than hit points.
	-- Applying a healing surge returns the character to zero, before applying healing surge
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	if nWounds > nHP then
		nWounds = nHP;
	end
	
	-- Apply the healing surge
	DB.setValue(nodeChar, "hp.surgesused", "number", nSurgesUsed + 1);
	DB.setValue(nodeChar, "hp.wounds", "number", math.max(nWounds - nSurges, 0));
	
	-- Send the message to everyone
	ChatManager.Message(sMessage, true, ActorManager.getActor("pc", nodeChar));
end

function rest(nodeChar, bExtended, bMilestone)
	if not nodeChar then
		return;
	end
	
	-- RESET POWERS
	resetPowers(nodeChar, bExtended, bMilestone);
	
	-- RESET HEALTH
	resetHealth(nodeChar, bExtended);
	
	-- RESET ACTION POINTS
	DB.setValue(nodeChar, "apused", "number", 0);
	if bExtended or bMilestone then
		local nodeAP = nil;
		for _,v in pairs(DB.getChildren(nodeChar, "powers")) do
			if DB.getValue(v, "name", "") == "Action Point" then
				nodeAP = v;
			end
		end
		if nodeAP then
			if bExtended then
				DB.setValue(nodeAP, "prepared", "number", 1);
			elseif bMilestone then
				DB.setValue(nodeAP, "prepared", "number", DB.getValue(nodeAP, "prepared", 0) + 1);
			end
		end
	end
end

function resetPowers(nodeChar, bExtended, bMilestone)
	-- Reset the individual powers
	for _,nodePower in pairs(DB.getChildren(nodeChar, "powers")) do
		if bExtended then
			DB.setValue(nodePower, "used", "number", 0);
		else
			local sRecharge = string.lower(string.sub(DB.getValue(nodePower, "recharge", ""),1,3));
			if sRecharge == "enc" then
				DB.setValue(nodePower, "used", "number", 0);
			end
		end
	end
	
	-- Reset use limits
	local nCurrentUses = DB.getValue(nodeChar, "powerlimit.itemdaily", 1);
	if nCurrentUses ~= 0 then
		if bExtended then
			local nMaxUses = math.ceil(DB.getValue(nodeChar, "level", 0) / 10);
			if nMaxUses < 0 then
				nMaxUses = 1;
			end
			DB.setValue(nodeChar, "powerlimit.itemdaily", "number", nMaxUses);
		elseif bMilestone then
			DB.setValue(nodeChar, "powerlimit.itemdaily", "number", nCurrentUses + 1);
		end
	end
end

function resetHealth(nodeChar, bExtended)
	DB.setValue(nodeChar, "hp.temporary", "number", 0);
	DB.setValue(nodeChar, "hp.secondwind", "number", 0);
	DB.setValue(nodeChar, "hp.faileddeathsaves", "number", 0);
	
	if bExtended == true then
		DB.setValue(nodeChar, "hp.wounds", "number", 0);
		DB.setValue(nodeChar, "hp.surgesused", "number", 0);
	end
end

function onPowerAbilityAction(draginfo, nodeAbility, subtype)
	local sAbilityType = DB.getValue(nodeAbility, "type", "");
	if sAbilityType == "attack" then
		if subtype == "attack" then
			local rActor, rAction, rFocus = getAdvancedRollStructures("attack", nodeAbility, getPowerFocus(nodeAbility));
			ActionAttack.performRoll(draginfo, rActor, rAction, rFocus);
			return true;
		elseif subtype == "damage" then
			local rActor, rAction, rFocus = getAdvancedRollStructures("damage", nodeAbility, getPowerFocus(nodeAbility));
			ActionDamage.performRoll(draginfo, rActor, rAction, rFocus);
			return true;
		end
	elseif sAbilityType == "heal" then
		local rActor, rAction, rFocus = getAdvancedRollStructures("heal", nodeAbility, nil);
		ActionHeal.performRoll(draginfo, rActor, rAction, rFocus);
		return true;
	elseif sAbilityType == "effect" then
		local rActor, rEffect = getEffectStructures(nodeAbility);
		return ActionEffect.performRoll(draginfo, rActor, rEffect);
	end
	
	return false;
end

function onDropPowerAbility(nodePowerAbilityList, draginfo)
	local rEffect = ActionEffect.decodeEffectFromDrag(draginfo);
	if rEffect then
		local nodePowerAbility = nodePowerAbilityList.createChild();
		if nodePowerAbility then
			DB.setValue(nodePowerAbility, "type", "string", "effect");
			DB.setValue(nodePowerAbility, "label", "string", rEffect.sName);
			DB.setValue(nodePowerAbility, "savemod", "number", rEffect.nSaveMod);
			DB.setValue(nodePowerAbility, "expiration", "string", rEffect.sExpire);
			DB.setValue(nodePowerAbility, "apply", "string", rEffect.sApply);
		end

		return true;
	end
	
	return false;
end

--
-- DATA ACCESS
--

function getPowerFocus(nodePowerAbility)
	-- Validate parameters
	if not nodePowerAbility then
		return nil;
	end
	
	-- Get this attack's focus, if any
	local nToolOrder = DB.getValue(nodePowerAbility, "focus", 0);
	
	-- If no focus specified, then look up the default for this type of power
	if nToolOrder == 0 then
		local isWeaponPower = false;
		local isImplementPower = false;

		local sKeywords = string.lower(DB.getValue(nodePowerAbility, "...keywords", ""));
		if string.match(sKeywords, "weapon") then
			isWeaponPower = true;
		elseif string.match(sKeywords, "implement") then
			isImplementPower = true;
		end

		if isWeaponPower then
			nToolOrder = DB.getValue(nodePowerAbility, ".....powerfocus.weapon.order", 0);
		elseif isImplementPower then
			nToolOrder = DB.getValue(nodePowerAbility, ".....powerfocus.implement.order", 0);
		end
	end
	
	-- Look up the weapon or implement specified
	local nodeTool = nil;
	if nToolOrder > 0 then
		for _,v in pairs(DB.getChildren(nodePowerAbility, ".....weaponlist")) do
			local nOrder = DB.getValue(v, "order", 0);
			if nOrder == nToolOrder then
				nodeTool = v;
			end
		end
	end
	
	-- Return the node of the weapon used as a focus for this power
	return nodeTool;
end

function getPowerAbilityOutputOrder(nodePowerAbility)
	-- Default value
	local nOutputOurder = 1;
	
	-- Validate parameters
	if not nodePowerAbility then
		return nOutputOurder;
	end
	local nodePowerAbilities = nodePowerAbility.getParent();
	if not nodePowerAbilities then
		return nOutputOurder;
	end
	
	-- First, pull some ability attributes
	local sAbilityType = DB.getValue(nodePowerAbility, "type", "");
	local nAbilityOrder = DB.getValue(nodePowerAbility, "order", 0);
	
	-- Iterate through list node
	for _,v in pairs(nodePowerAbilities.getChildren()) do
		if DB.getValue(v, "type", "") == sAbilityType and DB.getValue(v, "order", 0) < nAbilityOrder then
			nOutputOurder = nOutputOurder + 1;
		end
	end
	
	return nOutputOurder;
end

function getFocusRecord(sAbilityType, nodeFocus)
	-- VALIDATE
	if not nodeFocus then
		return nil;
	end
	if sAbilityType ~= "attack" and sAbilityType ~= "damage" then
		return nil;
	end
	
	-- SETUP
	local nodeChar = nil;
	if nodeFocus then
		nodeChar = nodeFocus.getChild("...");
	end
	
	-- BUILD FOCUS RECORD
	local rFocus = {};
	rFocus.type = sAbilityType;
	rFocus.name = DB.getValue(nodeFocus, "name", "");
	rFocus.range = "R";
	if DB.getValue(nodeFocus, "type", 0) == 0 then
		rFocus.range = "M";
	end

	-- BUILD FOCUS RECORD CLAUSE BASED ON ABILITY TYPE
	local rFocusClause = {};
	if sAbilityType == "attack" then
		local sStat = DB.getValue(nodeFocus, "attackstat", "");
		if sStat == "" then
			if rFocus.range == "R" then
				sStat = DB.getValue(nodeChar, "attacks.ranged.abilityname", "");
				if sStat == "" then
					sStat = "dexterity";
				end
			else
				sStat = DB.getValue(nodeChar, "attacks.melee.abilityname", "");
				if sStat == "" then
					sStat = "strength";
				end
			end
		end
		rFocus.properties = string.lower(DB.getValue(nodeFocus, "properties", ""));
		rFocus.defense = DB.getValue(nodeFocus, "attackdef", 0);
		rFocusClause.stat = { sStat };
		rFocusClause.mod = DB.getValue(nodeFocus, "bonus", 0);

	elseif sAbilityType == "damage" then
		rFocus.properties = string.lower(DB.getValue(nodeFocus, "properties", ""));
		rFocus.basedice = DB.getValue(nodeFocus, "damagedice", {});
		rFocus.basetype = DB.getValue(nodeFocus, "damagetype", "");
		rFocus.critdice = DB.getValue(nodeFocus, "criticaldice", {});
		rFocus.critmod = DB.getValue(nodeFocus, "criticalbonus", 0);
		rFocus.crittype = DB.getValue(nodeFocus, "criticaldamagetype", "");

		rFocusClause.mod = DB.getValue(nodeFocus, "damagebonus", 0);
		rFocusClause.dicestr = StringManager.convertDiceToString(rFocus.basedice, rFocusClause.mod);
		rFocusClause.subtype = DB.getValue(nodeFocus, "damagetype", "");

		local sStat = DB.getValue(nodeFocus, "damagestat", "");
		if sStat == "" then
			if rFocus.range == "R" then
				sStat = "dexterity";
			else
				sStat = "strength";
			end
		end
		rFocusClause.stat = { sStat };
	end
	rFocus.clauses = { rFocusClause };
	
	-- RESULTS
	return rFocus;
end

function getEffectStructures(nodeAbility)
	local nodeChar = nil;
	if nodeAbility then
		nodeChar = nodeAbility.getChild(".....");
	end

	local rActor = ActorManager.getActor("pc", nodeChar);

	local rEffect = {};

	rEffect.sName = EffectsManager.evalEffect(rActor, DB.getValue(nodeAbility, "label", ""));
	rEffect.sExpire = DB.getValue(nodeAbility, "expiration", "");
	rEffect.nSaveMod = DB.getValue(nodeAbility, "savemod", 0);
	rEffect.sApply = DB.getValue(nodeAbility, "apply", "");
	rEffect.sTargeting = DB.getValue(nodeAbility, "targeting", "");
	
	if rActor then
		rEffect.sSource = rActor.sCTNode;
		rEffect.nInit = DB.getValue(rActor.nodeCT, "initresult", 0);
	else
		rEffect.sSource = "";
		rEffect.nInit = 0;
	end
	
	return rActor, rEffect;
end

function getBaseAttackRollStructures(sAttack, nodeChar)
	-- CREATURE
	local rActor = ActorManager.getActor("pc", nodeChar);

	-- ABILITY
	local rAction = {};
	rAction.type = "attack";
	rAction.name = sAttack;
	if string.match(string.lower(sAttack), "melee") then
		rAction.range = "M";
	else
		rAction.range = "R";
	end
	rAction.defense = "ac";
	
	local rAbilityClause = {};
	rAbilityClause.stat = {};
	rAbilityClause.mod = 0;
	if rAction.range == "R" then
		local sStat = DB.getValue(rActor.nodeCreature, "attacks.ranged.abilityname", "");
		if sStat == "" then
			sStat = "dexterity";
		end
		table.insert(rAbilityClause.stat, sStat);
	elseif rAction.range == "M" then
		local sStat = DB.getValue(rActor.nodeCreature, "attacks.melee.abilityname", "");
		if sStat == "" then
			sStat = "strength";
		end
		table.insert(rAbilityClause.stat, sStat);
	end
	rAction.clauses = { rAbilityClause };
		
	-- RESULTS
	return rActor, rAction, nil;
end

function getAdvancedRollStructures(sAbilityType, nodeAbility, nodeFocus)
	-- CREATURE
	local nodeChar = nil;
	if nodeAbility then
		nodeChar = nodeAbility.getChild(".....");
	elseif nodeFocus then
		nodeChar = nodeFocus.getChild("...");
	end
	local rActor = ActorManager.getActor("pc", nodeChar);
	
	-- ABILITY
	local rAction = nil;
	if nodeAbility then
		rAction = {};
		rAction.type = sAbilityType;
		rAction.name = DB.getValue(nodeAbility, "...name", "");
		rAction.order = getPowerAbilityOutputOrder(nodeAbility);
		
		local listRangeWords = StringManager.parseWords(string.lower(DB.getValue(nodeAbility, "...range", "")));
		local bMelee = StringManager.isWord("melee", listRangeWords);
		local bRanged = StringManager.isWord("ranged", listRangeWords);
		if bMelee and bRanged then
			rAction.range = "*";
		elseif bMelee then
			rAction.range = "M";
		elseif bRanged then
			rAction.range = "R";
		elseif StringManager.isWord(listRangeWords[1], "close") then
			rAction.range = "C";
		elseif StringManager.isWord(listRangeWords[1], "area") then
			rAction.range = "A";
		else
			rAction.range = "";
		end
		rAction.clauses = {};

		local rAbilityClause = {}; 

		if sAbilityType == "attack" then
			rAction.defense = DB.getValue(nodeAbility, "attackdef", 0);
			rAbilityClause.stat = {};
			local sAttackStat = DB.getValue(nodeAbility, "attackstat", "");
			if sAttackStat ~= "" then
				table.insert(rAbilityClause.stat, sAttackStat);
			end
			rAbilityClause.mod = DB.getValue(nodeAbility, "attackstatmodifier", 0);

		elseif sAbilityType == "damage" then

			rAbilityClause.basemult = DB.getValue(nodeAbility, "damageweaponmult", 0);
			rAbilityClause.subtype = DB.getValue(nodeAbility, "damagetype", "");

			local powerdice = DB.getValue(nodeAbility, "damagebasicdice", {});
			local powermod = DB.getValue(nodeAbility, "damagestatmodifier", 0);
			rAbilityClause.dicestr = StringManager.convertDiceToString(powerdice, powermod);
			rAbilityClause.critdicestr = "";

			rAbilityClause.stat = {};
			local sStat = DB.getValue(nodeAbility, "damagestat", "");
			if sStat ~= "" then
				local statmult = DB.getValue(nodeAbility, "damagestatmult", "");
				if statmult == "half" then
					sStat = "half" .. sStat;
				elseif statmult == "double" then
					sStat = "double" .. sStat;
				end

				table.insert(rAbilityClause.stat, sStat);
			end
			sStat = DB.getValue(nodeAbility, "damagestat2", "");
			if sStat ~= "" then
				local statmult = DB.getValue(nodeAbility, "damagestatmult2", "");
				if statmult == "half" then
					sStat = "half" .. sStat;
				elseif statmult == "double" then
					sStat = "double" .. sStat;
				end

				table.insert(rAbilityClause.stat, sStat);
			end

		elseif sAbilityType == "heal" then

			rAction.sTargeting = DB.getValue(nodeAbility, "healtargeting", "");

			rAbilityClause.basemult = DB.getValue(nodeAbility, "hsvmult", 0);
			rAbilityClause.subtype = DB.getValue(nodeAbility, "healtype", "");
			rAbilityClause.cost = DB.getValue(nodeAbility, "healcost", 0);

			local powerdice = DB.getValue(nodeAbility, "healdice", {});
			local powermod = DB.getValue(nodeAbility, "healmod", 0);
			rAbilityClause.dicestr = StringManager.convertDiceToString(powerdice, powermod);

			rAbilityClause.stat = {};
			local sStat = DB.getValue(nodeAbility, "healstat", "");
			if sStat ~= "" then
				local statmult = DB.getValue(nodeAbility, "healstatmult", "");
				if statmult == "half" then
					sStat = "half" .. sStat;
				elseif statmult == "double" then
					sStat = "double" .. sStat;
				end

				table.insert(rAbilityClause.stat, sStat);
			end
			sStat = DB.getValue(nodeAbility, "healstat2", "");
			if sStat ~= "" then
				local statmult = DB.getValue(nodeAbility, "healstatmult2", "");
				if statmult == "half" then
					sStat = "half" .. sStat;
				elseif statmult == "double" then
					sStat = "double" .. sStat;
				end

				table.insert(rAbilityClause.stat, sStat);
			end
		end
		
		table.insert(rAction.clauses, rAbilityClause);
	end
	
	-- FOCUS
	local rFocus = getFocusRecord(sAbilityType, nodeFocus);
	
	-- FIX POWERS THAT HAVE DIFFERENT RANGES BASED ON FOCUS
	if rAction and rAction.range == "*" then
		if rFocus then
			rAction.range = rFocus.range;
		end
	end
	
	-- RESULTS
	return rActor, rAction, rFocus;
end

function getWeaponCritical(nodeWeapon)
	local nodeChar = nodeWeapon.getChild("...");
	local rActor = ActorManager.getActor("pc", nodeChar);
	
	local rAction = {};
	rAction.type = "damage";
	rAction.name = DB.getValue(nodeWeapon, "name", "") .. " [CRITICAL BONUS DICE ONLY]";
	local sCritDmgType = DB.getValue(nodeWeapon, "criticaldamagetype", "");
	if sCritDmgType ~= "" then
		rAction.name = rAction.name .. " [TYPE: " .. sCritDmgType .. "]";
	end

	rAction.range = "R";
	if DB.getValue(nodeWeapon, "type", 0) == 0 then
		rAction.range = "M";
	end

	rAction.clauses = {};
	local rAbilityClause = {};
	local aDice = DB.getValue(nodeWeapon, "criticaldice", {});
	local nMod = DB.getValue(nodeWeapon, "criticalbonus", 0);
	rAbilityClause.dicestr = StringManager.convertDiceToString(aDice, nMod);
	rAbilityClause.critdicestr = rAbilityClause.dicestr;
	rAbilityClause.stat = {};
	table.insert(rAction.clauses, rAbilityClause);

	return rActor, rAction;
end

function getSkillValue(rActor, sSkill)
	local nValue = 0;

	if rActor and rActor.nodeCreature then
		local nodeSkill = nil;
		for _,vNode in pairs(DB.getChildren(rActor.nodeCreature, "skilllist")) do
			local sName = DB.getValue(vNode, "label", "");
			if sName == sSkill then
				nodeSkill = vNode;
				break;
			end
		end
		
		if nodeSkill then
			local nLevel = DB.getValue(nodeSkill, "...levelbonus", 0);
			local nAbility = DB.getValue(nodeSkill, "stat", 0);
			local nMisc = DB.getValue(nodeSkill, "misc", 0);
			
			nValue = nLevel + nAbility + nMisc;

			local nTrained = DB.getValue(nodeSkill, "trained", 0);
			if nTrained == 1 then
				nValue = nValue + 5;
			end
			
			local sAbility = DB.getValue(nodeSkill, "statname", "");
			if StringManager.contains({"strength", "dexterity", "constitution"}, sAbility) then
				local nACPenalty = DB.getValue(nodeSkill, "...encumbrance.armorcheckpenalty", 0);
				nValue = nValue + math.min(nACPenalty, 0);
			end
		else
			local rSkill = DataCommon.skilldata[sSkill];
			if rSkill then
				if rSkill.stat then
					nValue = nValue + ActorManager.getAbilityBonus(rActor, rSkill.stat);
				end
				
				if rSkill.armorcheckmultiplier then
					local nArmorCheckPenalty = DB.getValue(rActor.nodeCreature, "encumbrance.armorcheckpenalty", 0);
					nValue = nValue + (nArmorCheckPenalty * (tonumber(rSkill.armorcheckmultiplier) or 0));
				end
			end
		end
	end

	return nValue;
end

function getClassLevelSummary(nodeChar)
	if not nodeChar then
		return "";
	end
	
	local aClasses = {};

	local sValue = DB.getValue(nodeChar, "class.base", "");
	if sValue ~= "" then
		table.insert(aClasses, sValue);
	end
	sValue = DB.getValue(nodeChar, "class.paragon", "");
	if sValue ~= "" then
		table.insert(aClasses, sValue);
	end
	sValue = DB.getValue(nodeChar, "class.epic", "");
	if sValue ~= "" then
		table.insert(aClasses, sValue);
	end

	return table.concat(aClasses, " / ");
end

function getPowerSort(w, sSort, bHeaderCheck)
	local nCategory = 0;
	
	if sSort == "action" then
		local sAction = string.lower(w.action.getValue());
		
		if sAction:match("standard") then
			nCategory = 1;
		elseif sAction:match("move") then
			nCategory = 2;
		elseif sAction:match("minor") then
			nCategory = 3;
		elseif sAction:match("free") then
			nCategory = 4;
		elseif sAction:match("interrupt") or sAction:match("reaction") or sAction:match("opportunity") then
			nCategory = 5;
		end
	elseif sSort == "source" then
		local sSource = StringManager.trim(string.lower(w.source.getValue()));
		
		if sSource == "item" then
			nCategory = 1;
		elseif sSource:match("general") or sSource:match("basic attack") then
			nCategory = -101;
		elseif sSource:match("feature") or sSource:match("racial") or sSource == "feat" then
			nCategory = -100;
		else
			local sLevel = sSource:match("%d+");
			if sLevel then
				local nLevel = tonumber(sLevel) or 0;
				if nLevel > 0 then
					if bHeaderCheck then
						nCategory = -99;
					else
						nCategory = nLevel - 100;
					end
				end
			elseif sSource:match("utility") then
				nCategory = -100;
			end
		end
	elseif sSort == "sourcealt" then
		local sSource = StringManager.trim(string.lower(w.source.getValue()));
		
		if sSource == "item" then
			nCategory = -1;
		elseif sSource:match("general") or sSource:match("basic attack") then
			nCategory = 1;
		elseif sSource:match("feature") or sSource:match("racial") or sSource == "feat" then
			nCategory = -2;
		else
			local sLevel = sSource:match("%d+");
			if sLevel then
				local nLevel = tonumber(sLevel) or 0;
				if nLevel > 0 then
					nCategory = -(nLevel + 2);
				end
			elseif sSource:match("utility") then
				nCategory = -2;
			end
		end
	else
		local sRecharge = string.lower(w.recharge.getValue());
		if sRecharge:match("at%-will") then
			nCategory = 1;
		elseif sRecharge:match("enc") or sRecharge:match("action point") then
			nCategory = 2;
		elseif sRecharge:match("daily") then
			nCategory = 3;
		end
	end
	
	return nCategory;
end

function getPowerSubSort(sSort, w)
	local vResult = 0;
	
	if sSort == "action" then
		vResult = getPowerSort(w, "");
	elseif sSort == "source" then
		vResult = string.lower(w.source.getValue());
	else
		vResult = getPowerSort(w, "sourcealt");
	end
	
	return vResult;
end

function onPowerSortCompare(w1, w2, sSort, sHeaderClass)
	local vCategory1 = getPowerSort(w1, sSort);
	local vCategory2 = getPowerSort(w2, sSort);
	if vCategory1 ~= vCategory2 then
		return vCategory1 > vCategory2;
	end
	
	local bIsHeader1 = (w1.getClass() == sHeaderClass);
	local bIsHeader2 = (w2.getClass() == sHeaderClass);
	if bIsHeader1 then
		return false;
	elseif bIsHeader2 then
		return true;
	end
	
	local vSubCategory1 = getPowerSubSort(sSort, w1);
	local vSubCategory2 = getPowerSubSort(sSort, w2);
	if vSubCategory1 ~= vSubCategory2 then
		return vSubCategory1 > vSubCategory2;
	end
	
	local sValue1 = string.lower(w1.name.getValue());
	local sValue2 = string.lower(w2.name.getValue());
	if sValue1 ~= sValue2 then
		return sValue1 > sValue2;
	end
end

function setPowerHeaderCategory(wh, sSort, nCategory)
	if sSort == "action" then
		if nCategory == 1 then
			wh.action.setValue("Standard");
			wh.title.setValue("Standard Actions");
		elseif nCategory == 2 then
			wh.action.setValue("Move");
			wh.title.setValue("Move Actions");
		elseif nCategory == 3 then
			wh.action.setValue("Minor");
			wh.title.setValue("Minor Actions");
		elseif nCategory == 4 then
			wh.action.setValue("Free");
			wh.title.setValue("Free Actions");
		elseif nCategory == 5 then
			wh.action.setValue("Interrupt");
			wh.title.setValue("Triggered Actions");
		else
			wh.action.setValue("");
			wh.title.setValue("Traits");
		end
	elseif sSort == "source" then
		if nCategory == -101 then
			wh.source.setValue("General");
			wh.title.setValue("General Powers");
		elseif nCategory == -100 then
			wh.source.setValue("Feature");
			wh.title.setValue("Feature Powers");
		elseif nCategory == 1 then
			wh.source.setValue("Item");
			wh.title.setValue("Item Powers");
		elseif nCategory > -100 and nCategory < 0 then
			wh.source.setValue("1");
			wh.title.setValue("Class Powers");
		else
			wh.source.setValue("");
			wh.title.setValue("Misc Powers");
		end
	else
		if nCategory == 1 then
			wh.recharge.setValue("At-will");
			wh.title.setValue("At-Will Powers");
		elseif nCategory == 2 then
			wh.recharge.setValue("Encounter");
			wh.title.setValue("Encounter Powers");
		elseif nCategory == 3 then
			wh.recharge.setValue("Daily");
			wh.title.setValue("Daily Powers");
		else
			wh.recharge.setValue("");
			wh.title.setValue("Situational");
		end
	end
end

function rebuildCategories(ctrlList, sSort, sHeaderClass)
	-- Close all category headings
	for _,v in pairs(ctrlList.getWindows()) do
		if v.getClass() == sHeaderClass then
			v.close();
		end
	end

	-- Create new category headings
	local aCategoryWindows = {};
	for _,v in ipairs(ctrlList.getWindows()) do
		local nCategory = CharManager.getPowerSort(v, sSort, true);
		
		if not aCategoryWindows[nCategory] then
			local wh = ctrlList.createWindowWithClass(sHeaderClass);
			if wh then
				CharManager.setPowerHeaderCategory(wh, sSort, nCategory);
			end
			aCategoryWindows[nCategory] = wh;
		end
	end
end

