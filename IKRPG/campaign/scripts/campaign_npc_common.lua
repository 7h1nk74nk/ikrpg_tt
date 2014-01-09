-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function applyDiceToPower(nodePower, aDice)
	local sDice = StringManager.convertDiceToString(aDice);

	local sDesc = DB.getValue(nodePower, "shortdescription", "");
	local sNewDesc = "";
	local nIndex = 1;
	local nWeaponMult = 1;

	local nWeaponStart, nWeaponEnd, sWeaponMult = string.find(sDesc, "(%d?)%[W%]", nIndex);
	while nWeaponStart do
		sNewDesc = sNewDesc .. string.sub(sDesc, nIndex, nWeaponStart - 1);

		nWeaponMult = 1;
		if sWeaponMult then
			nWeaponMult = tonumber(sWeaponMult) or 1;
		end

		local sNewDice = "";
		local nDiceIndex = 1;
		local nDiceStart, nDiceEnd, sNumDice, sDie = string.find(sDice, "(%d+)d(%d+)", nDiceIndex);
		while nDiceStart do
			sNewDice = sNewDice .. string.sub(sDice, nDiceIndex, nDiceStart - 1);

			local nNumDice = tonumber(sNumDice) or 1;
			sNewDice = sNewDice .. (nNumDice * nWeaponMult) .. "d" .. sDie;

			nDiceIndex = nDiceEnd + 1;
			nDiceStart, nDiceEnd, sNumDice, sDie = string.find(sDice, "(%d+)d(%d+)", nDiceIndex);
		end
		sNewDice = sNewDice .. string.sub(sDice, nDiceIndex);

		sNewDesc = sNewDesc .. sNewDice;

		nIndex = nWeaponEnd + 1;
		nWeaponStart, nWeaponEnd, sWeaponMult = string.find(sDesc, "(%d?)%[W%]", nIndex);
	end
	sNewDesc = sNewDesc .. string.sub(sDesc, nIndex);

	DB.setValue(nodePower, "shortdescription", "string", sNewDesc);
end

function addPowerDB(nodeNPC, nodeSource, sClass)
	-- Parameter validation
	if not nodeNPC or not nodeSource then
		return;
	end

	-- Get the powers node
	local nodePowerList = nodeNPC.createChild("powers");
	if not nodePowerList then
		return;
	end
	local nodePower = nodePowerList.createChild();
	if not nodePower then
		return;
	end

	-- Set up the basic power fields
  	local sName = DB.getValue(nodeSource, "name", "");
  	local sSource = DB.getValue(nodeSource, "source", "");
	if sClass == "ref_ability" then
		DB.setValue(nodePower, "name", "string", sName);
		DB.setValue(nodePower, "source", "string", sSource);
		DB.setValue(nodePower, "shortdescription", "string", DB.getValue(nodeSource, "description", ""));
		return;
	end
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
			local nodeItemName = sourcenode.getChild("...name");
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
  	DB.setValue(nodePower, "source", "string", sSource);
  	DB.setValue(nodePower, "recharge", "string", DB.getValue(nodeSource, "recharge", "-"));
  	DB.setValue(nodePower, "keywords", "string", DB.getValue(nodeSource, "keywords", "-"));
	DB.setValue(nodePower, "shortdescription", "string", DB.getValue(nodeSource, "shortdescription", ""));

	-- Get action required, and apply space savers
	local sAction = DB.getValue(nodeSource, "action", "-");
	if srcvalue == "Standard Action" then
		sAction = "Standard";
	elseif srcvalue == "Move Action" then
		sAction = "Move";
	elseif srcvalue == "Minor Action" then
		sAction = "Minor";
	elseif srcvalue == "Free Action" then
		sAction = "Free";
	elseif srcvalue == "Immediate Interrupt" then
		sAction = "Interrupt";
	elseif srcvalue == "Immediate Reaction" then
		sAction = "Reaction";
	end
	DB.setValue(nodePower, "action", "string", sAction);
	
	-- Get range, and determine icon to show also
	local sRange = DB.getValue(nodeSource, "range", "-");
  	DB.setValue(nodePower, "range", "string", sRange);
	
	local sPowerType = "X";
	sRange = string.lower(sRange);
	if string.match(sRange, "melee") then
		sPowerType = "M";
	elseif string.match(sRange, "ranged") then
		sPowerType = "R";
	elseif string.match(sRange, "close") then
		sPowerType = "C";
	elseif string.match(sRange, "area") then
		sPowerType = "A";
	else
		sPowerType = "X";
	end
	DB.setValue(nodePower, "powertype", "string", sPowerType);

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
	DB.setValue(nodePower, "shortdescription", "string", sDesc);

  	-- Set the name once everything has settled out
  	DB.setValue(nodePower, "name", "string", sName);
	
	-- Set the shortcut
	if (sClass ~= "reference_power_custom") then
		DB.setValue(nodePower, "link", "windowreference", sClass, nodeSource.getNodeName());
	end
	
	-- Check to see if there are any linked powers
	if sClass == "powerdesc" then
		local nodeLinkedPowers = nodeSource.getChild("linkedpowers");
		local nodeOldPowerLink = nodeSource.getChild("link");
		
		if nodeLinkedPowers then
			for _,v in pairs(nodeLinkedPowers.getChildren()) do
				local sClass, sRecord = DB.getValue(v, "link", "", "");
				if sClass == "powerdesc" then
					addPowerDB(nodeNPC, DB.findNode(sRecord), sClass);
				end
			end
		elseif nodeOldPowerLink then
			local sClass, sRecord = DB.getValue(nodeSource, "link", "", "");
			if sClass == "powerdesc" then
				addPowerDB(nodeNPC, DB.findNode(sRecord), sClass);
			end
		end
	end
end
