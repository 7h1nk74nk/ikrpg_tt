-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYEFF = "applyeff";
OOB_MSGTYPE_EXPIREEFF = "expireeff";
OOB_MSGTYPE_FAILEDSAVEEFF = "failedsaveeff";

local bLocked = false;
local aUsedActionEffects = {};

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYEFF, handleApplyEffect);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_EXPIREEFF, handleExpireEffect);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_FAILEDSAVEEFF, handleFailedSaveEffect);
end

function handleApplyEffect(msgOOB)
	-- Get the combat tracker node
	local nodeCTEntry = DB.findNode(msgOOB.sTargetNode);
	if not nodeCTEntry then
		ChatManager.SystemMessage("[ERROR] Unable to resolve CT effect application on node = " .. msgOOB.sTargetNode);
		return;
	end
	
	-- Reconstitute the effect details
	local rEffect = {};
	rEffect.sName = msgOOB.sName;
	rEffect.sExpire = msgOOB.sExpire;
	rEffect.nSaveMod = tonumber(msgOOB.nSaveMod) or 0;
	rEffect.nInit = tonumber(msgOOB.nInit) or 0;
	rEffect.sSource = msgOOB.sSource;
	rEffect.nGMOnly = tonumber(msgOOB.nGMOnly) or 0;
	rEffect.sApply = msgOOB.sApply;
	
	local sEffectTargetNode = msgOOB.sEffectTargetNode or "";
	
	-- Apply the damage
	addEffect(msgOOB.user, msgOOB.identity, nodeCTEntry, rEffect, true, sEffectTargetNode);
end

function handleExpireEffect(msgOOB)
	-- Get the effect and combat tracker node
	local nodeEffect = DB.findNode(msgOOB.sEffectNode);
	if not nodeEffect then
		ChatManager.SystemMessage("[ERROR] Unable to find effect to remove = " .. msgOOB.sEffectNode);
		return;
	end
	local nodeActor = nodeEffect.getChild("...");
	if not nodeActor then
		ChatManager.SystemMessage("[ERROR] Unable to find actor to remove effect from = " .. msgOOB.sEffectNode);
		return;
	end
	
	-- Get the parameters
	local nExpireType = tonumber(msgOOB.nExpireType) or 0;
	
	-- Apply the damage
	expireEffect(nodeActor, nodeEffect, nExpireType);
end

function handleFailedSaveEffect(msgOOB)
	-- Get the effect and combat tracker node
	local nodeEffect = DB.findNode(msgOOB.sEffectNode);
	if not nodeEffect then
		ChatManager.SystemMessage("[ERROR] Unable to find effect to adjust = " .. msgOOB.sEffectNode);
		return;
	end
	local nodeActor = nodeEffect.getChild("...");
	if not nodeActor then
		ChatManager.SystemMessage("[ERROR] Unable to find actor to adjust effect on = " .. msgOOB.sEffectNode);
		return;
	end
	
	-- Apply the damage
	handleFailedSave(nodeActor, nodeEffect);
end

function notifyApply(rEffect, vTargets, sEffectTargetNode)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYEFF;
	msgOOB.user = User.getUsername();
	msgOOB.identity = User.getIdentityLabel();

	msgOOB.sName = rEffect.sName or "";
	msgOOB.sExpire = rEffect.sExpire or "";
	msgOOB.nSaveMod = rEffect.nSaveMod or 0;
	msgOOB.nInit = rEffect.nInit or 0;
	msgOOB.sSource = rEffect.sSource or ""; 
	msgOOB.nGMOnly = rEffect.nGMOnly or 0; 
	msgOOB.sApply = rEffect.sApply or "";

	msgOOB.sEffectTargetNode = sEffectTargetNode;
	
	if type(vTargets) == "table" then
		for _, v in pairs(vTargets) do
			msgOOB.sTargetNode = v;
			Comm.deliverOOBMessage(msgOOB, "");
		end
	else
		msgOOB.sTargetNode = vTargets;
		Comm.deliverOOBMessage(msgOOB, "");
	end
end

function notifyExpire(varEffect, nMatch)
	if type(varEffect) == "databasenode" then
		varEffect = varEffect.getNodeName();
	elseif type(varEffect) ~= "string" then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_EXPIREEFF;
	msgOOB.sEffectNode = varEffect;
	msgOOB.nExpireType = nMatch;
	
	Comm.deliverOOBMessage(msgOOB, "");
end

function notifyFailedSave(varEffect)
	if type(varEffect) == "databasenode" then
		varEffect = varEffect.getNodeName();
	elseif type(varEffect) ~= "string" then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_FAILEDSAVEEFF;
	msgOOB.sEffectNode = varEffect;
	
	Comm.deliverOOBMessage(msgOOB, "");
end

--
-- EFFECTS
--

function message(sMsg, nodeCTEntry, gmflag, target)
	-- ADD NAME OF CT ENTRY TO NOTIFICATION
	if nodeCTEntry then
		sMsg = sMsg .. " [on " .. DB.getValue(nodeCTEntry, "name", "") .. "]";
	end

	-- BUILD MESSAGE OBJECT
	local msg = {font = "msgfont", icon = "indicator_effect", text = sMsg};
	
	-- DELIVER MESSAGE BASED ON TARGET AND GMFLAG
	if target then
		if msguser == "" then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, msguser);
		end
	elseif gmflag then
		msg.text = "[GM] " .. msg.text;
		if User.isHost() then
			Comm.addChatMessage(msg);
		else
			Comm.deliverChatMessage(msg, User.getUsername());
		end
	else
		Comm.deliverChatMessage(msg);
	end
end

function parseEffect(s)
	local aEffects = {};
	
	local sEffectClause;
	for sEffectClause in string.gmatch(s, "([^;]*);?") do
		local aWords = StringManager.parseWords(sEffectClause, "%[%]:");
		if #aWords > 0 then
			local sType = string.match(aWords[1], "^([^:]+):");
			local aDice = {};
			local nMod = 0;
			local aRemainder = {};
			local nRemainderIndex = 1;
			if sType then
				nRemainderIndex = 2;

				local sValueCheck = "";
				local sTypeRemainder = string.sub(aWords[1], #sType + 2);
				if sTypeRemainder == "" then
					sValueCheck = aWords[2] or "";
					nRemainderIndex = nRemainderIndex + 1;
				else
					sValueCheck = sTypeRemainder;
				end
				
				if StringManager.isDiceString(sValueCheck) then
					aDice, nMod = StringManager.convertStringToDice(sValueCheck);
				elseif sValueCheck ~= "" then
					table.insert(aRemainder, sValueCheck);
				end
			end
			
			for i = nRemainderIndex, #aWords do
				table.insert(aRemainder, aWords[i]);
			end

			table.insert(aEffects, {type = sType or "", mod = nMod, dice = aDice, 
					remainder = aRemainder, original = StringManager.trim(sEffectClause)});
		end
	end
	
	return aEffects;
end

function rebuildParsedEffect(aEffectComps)
	local aEffect = {};
	
	for kComp, rComp in ipairs(aEffectComps) do
		local aComp = {};

		if rComp.type ~= "" then
			table.insert(aComp, rComp.type .. ":");
		end

		local sDiceString = StringManager.convertDiceToString(rComp.dice, rComp.mod);
		if sDiceString ~= "" then
			table.insert(aComp, sDiceString);
		end
		
		for kRemainder, sRemainder in ipairs(rComp.remainder) do
			table.insert(aComp, sRemainder);
		end
		
		table.insert(aEffect, table.concat(aComp, " "));
	end
	
	return table.concat(aEffect, "; ");
end

function getEffectsString(nodeCTEntry, bPublicOnly)
	-- Start with an empty effects list string
	local aOutputEffects = {};
	
	-- Iterate through each effect
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);
	for _,v in pairs(aSorted) do
		if DB.getValue(v, "isactive", 0) == 1 then
			local sLabel = DB.getValue(v, "label", "");

			local bAddEffect = true;
			local bGMOnly = false;
			if sLabel == "" then
				bAddEffect = false;
			elseif DB.getValue(v, "isgmonly", 0) == 1 then
				if User.isHost() and not bPublicOnly then
					bGMOnly = true;
				else
					bAddEffect = false;
				end
			end

			if bAddEffect then
				local aAddCompList = {};
				local bTargeted = false;
				local aEffectComps = EffectsManager.parseEffect(sLabel);
				for _,vComp in ipairs(aEffectComps) do
					if vComp.type == "AFTER" then
						table.insert(aAddCompList, {type = "", mod = 0, dice = {}, remainder = {"[+]"}});
						break;
					elseif vComp.type == "FAIL" then
						table.insert(aAddCompList, {type = "", mod = 0, dice = {}, remainder = {"[F]"}});
						break;
					elseif vComp.remainder[1] == "TRGT" then
						bTargeted = true;
					else
						table.insert(aAddCompList, vComp);
					end
				end
				
				if isTargetedEffect(v) then
					local sTargets = table.concat(getEffectTargets(v, true), ",");
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[TRGT: " .. sTargets .. "]"}});
				elseif bTargeted then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[TRGT]"}});
				end

				local sApply = DB.getValue(v, "apply", "");
				if sApply == "action" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[ACTN]"}});
				elseif sApply == "roll" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[ROLL]"}});
				elseif sApply == "single" then
					table.insert(aAddCompList, 1, {type = "", mod = 0, dice = {}, remainder = {"[SNG]"}});
				end
				
				local sExpire = DB.getValue(v, "expiration", 0);
				if sExpire == "save" then
					table.insert(aAddCompList,  {type = "", mod = 0, dice = {}, remainder = {"[SAVE]"}});
				end
				
				local sOutputLabel = rebuildParsedEffect(aAddCompList);
				if bGMOnly then
					sOutputLabel = "(" .. sOutputLabel .. ")";
				end

				table.insert(aOutputEffects, sOutputLabel);
			end
		end
	end
	
	-- Return the final effect list string
	return table.concat(aOutputEffects, " | ");
end

function isGMEffect(nodeActor, nodeEffect)
	local bGMOnly = false;
	if nodeEffect then
		bGMOnly = (DB.getValue(nodeEffect, "isgmonly", 0) == 1);
	end
	if nodeActor then
		if (DB.getValue(nodeActor, "friendfoe", "") ~= "friend") and 
				(DB.getValue(nodeActor, "show_npc", 0) == 0) then
			bGMOnly = true;
		end
	end
	return bGMOnly;
end

function isTargetedEffect(nodeEffect)
	return (DB.getChildCount(nodeEffect, "targets") > 0);
end

function getEffectTargets(nodeEffect, bUseName)
	local aTargets = {};
	
	for _,nodeTarget in pairs(DB.getChildren(nodeEffect, "targets")) do
		local sNode = DB.getValue(nodeTarget, "noderef", "");
		if bUseName then
			local nodeTargetCT = DB.findNode(sNode);
			table.insert(aTargets, DB.getValue(nodeTargetCT, "name", ""));
		else
			table.insert(aTargets, sNode);
		end
	end

	return aTargets;
end

function removeEffect(nodeCTEntry, sEffPatternToRemove)
	-- VALIDATE
	if not sEffPatternToRemove then
		return;
	end

	-- COMPARE EFFECT NAMES TO EFFECT TO REMOVE
	for _,nodeEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
		local s = DB.getValue(nodeEffect, "label", "");
		if string.match(s, sEffPatternToRemove) then
			nodeEffect.delete();
			return;
		end
	end
end

function addEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, sEffectTargetNode)
	-- VALIDATE
	if not nodeCT or not rNewEffect or not rNewEffect.sName then
		return;
	end
	rNewEffect.sExpire = rNewEffect.sExpire or "";
	rNewEffect.nSaveMod = rNewEffect.nSaveMod or 0;
	rNewEffect.nInit = rNewEffect.nInit or 0;
	
	-- GET EFFECTS LIST
	local sCTName = DB.getValue(nodeCT, "name", "");
	local nodeEffectsList = nodeCT.createChild("effects");
	if not nodeEffectsList then
		return;
	end
	
	-- TRACK ALTERNATE EFFECT APPLICATION MESSAGES
	local sMsg = "";
	
	-- PARSE NEW EFFECT
	local aNewEffectParse = parseEffect(rNewEffect.sName);
	
	-- USE DEFAULT EXPIRATION FOR SINGLE/SINGLES OR ZONE/AURA IF NO EXPIRATION DEFINED
	local nActiveInit = CTManager.getActiveInit();
	if nActiveInit then
		if rNewEffect.sExpire == "" then
			for keyEffComp, rEffComp in pairs(aNewEffectParse) do
				if rEffComp.type == "" then
					local bBreak = false;
					for keyRemainder, sRemainder in pairs(rEffComp.remainder) do
						if StringManager.isWord(sRemainder, {"ZONE", "AURA"}) then
							rNewEffect.sExpire = "start";
							rNewEffect.nInit = nActiveInit;
							break;
						end
					end
				end
			end
		end
		if rNewEffect.sExpire == "" and StringManager.isWord(rNewEffect.sApply, {"roll", "single"}) then
			rNewEffect.sExpire = "end";
			rNewEffect.nInit = nActiveInit;
		end
	end
	
	-- CHECKS TO IGNORE NEW EFFECT (DUPLICATE, SHORTER, WEAKER)
	local nodeTargetEffect = nil;
	for k, v in pairs(nodeEffectsList.getChildren()) do
		-- PARSE EFFECT FROM LIST
		local sEffectName = DB.getValue(v, "label", "");
		local nEffectSaveMod = DB.getValue(v, "savemod", 0);
		local sEffectExpire = DB.getValue(v, "expiration", "");
		local nEffectInit = DB.getValue(v, "effectinit", 0);

		local aEffectParse = parseEffect(sEffectName);

		-- CHECK FOR DUPLICATE OR SHORTER EFFECT
		-- NOTE: ONLY IF LABEL AND MODIFIER ARE THE SAME
		if sEffectName == rNewEffect.sName then
			-- COMPARE EXPIRATIONS
			local bLonger = false;
			if rNewEffect.sExpire == "" then
				if sEffectExpire ~= "" then
					bLonger = true;
				end
			elseif rNewEffect.sExpire == "save" then
				if StringManager.isWord(sEffectExpire, {"encounter", "endnext", "start", "end"}) then
					bLonger = true;
				end
			elseif rNewEffect.sExpire == "encounter" then
				if StringManager.isWord(sEffectExpire, {"endnext", "start", "end"}) then
					bLonger = true;
				end
			elseif rNewEffect.sExpire == "endnext" then
				if StringManager.isWord(sEffectExpire, {"start", "end"}) then
					bLonger = true;
				elseif sEffectExpire == "endnext" then
					local nCurrentInit = DB.getValue(CTManager.getActiveCT(), "initresult", 10000);
					if ((nEffectInit - nCurrentInit) * (rNewEffect.nInit - nCurrentInit) < 0) then
						if rNewEffect.nInit > nEffectInit then
							bLonger = true;
						end
					else
						if rNewEffect.nInit < nEffectInit then
							bLonger = true;
						end
					end
				end
			elseif StringManager.isWord(rNewEffect.sExpire, {"start", "end"}) then
				if StringManager.isWord(sEffectExpire, {"start", "end"}) then
					local nCurrentInit = DB.getValue(CTManager.getActiveCT(), "initresult", 10000);
					local nCurrentValue = nCurrentInit * 3;

					local nEffectValue = nEffectInit * 3;
					if sEffectExpire == "start" then
						nEffectValue = nEffectValue + 1;
					elseif sEffectExpire == "end" then
						nEffectValue = nEffectValue - 1;
					end

					local nNewEffectValue = rNewEffect.nInit * 3;
					if rNewEffect.sExpire == "start" then
						nNewEffectValue = nNewEffectValue + 1;
					elseif rNewEffect.sExpire == "end" then
						nNewEffectValue = nNewEffectValue - 1;
					end
					
					if ((nEffectValue - nCurrentValue) * (nNewEffectValue - nCurrentValue) < 0) then
						if nNewEffectValue > nEffectValue then
							bLonger = true;
						end
					else
						if nNewEffectValue < nEffectValue then
							bLonger = true;
						end
					end
				end
			end
			
			-- IF LONGER EFFECT, THEN UPDATE EFFECT; OTHERWISE, NOTIFY AND EXIT
			if bLonger then
				nodeTargetEffect = v;
				sMsg = "Effect ['" .. rNewEffect.sName .."'] -> [REPLACED SHORTER] [on " .. sCTName .. "]";
				break;
			end

			message("Effect ['" .. rNewEffect.sName .. "'] -> [ALREADY EXISTS]", nodeCT, false, sUser);
			return;
		end
		
		-- CHECK FOR WEAKER EFFECT
		-- NOTE: ONLY IF MODIFIER AND EXPIRATION ARE THE SAME
		if #aEffectParse == #aNewEffectParse and nEffectSaveMod == rNewEffect.nSaveMod and sEffectExpire == rNewEffect.sExpire then
			-- COMPARE EACH EFFECT CLAUSE
			local bDifferent = false;
			local nDifferentMod = 0;
			for i = 1, #aNewEffectParse do
				-- CHECK TYPE AND REMAINDER FIRST
				if aEffectParse[i].type == aNewEffectParse[i].type then
					
					-- CHECK REMAINDER NEXT
					if #(aEffectParse[i].remainder) == #(aNewEffectParse[i].remainder) then
				    	for j = 1, #(aNewEffectParse[i].remainder) do
				    		if aEffectParse[i].remainder[j] ~= aNewEffectParse[i].remainder[j] then
				    			bDifferent = true;
				    			break;
				    		end
				    	end
					else
				    	bDifferent = true;
					end
				    
				    -- CHECK DICE NEXT
				    if #(aEffectParse[i].dice) == #(aNewEffectParse[i].dice) then
				    	for j = 1, #(aNewEffectParse[i].dice) do
				    		if aEffectParse[i].dice[j] ~= aNewEffectParse[i].dice[j] then
				    			bDifferent = true;
				    			break;
				    		end
				    	end
				    else
				    	bDifferent = true;
				    end
				    
				    -- CHECK MODIFIER NEXT
					if aEffectParse[i].mod >= 0 then
						if aEffectParse[i].mod > aNewEffectParse[i].mod then
							if nDifferentMod < 0 then
								bDifferent = true;
							else
								nDifferentMod = 1;
							end
						elseif aEffectParse[i].mod < aNewEffectParse[i].mod then
							if nDifferentMod > 0 then
								bDifferent = true;
							else
								nDifferentMod = -1;
							end
						end
					else
						if aEffectParse[i].mod < aNewEffectParse[i].mod then
							if nDifferentMod < 0 then
								bDifferent = true;
							else
								nDifferentMod = 1;
							end
						elseif aEffectParse[i].mod > aNewEffectParse[i].mod then
							if nDifferentMod > 0 then
								bDifferent = true;
							else
								nDifferentMod = -1;
							end
						end
					end
				end
			
				-- IF DICE DIFFERENT, THEN JUST EXIT
				if bDifferent then
					break;
				end
			end
			
			-- IF DIFFERENCE IS ONLY MODIFIERS AND ALL DIFFERENCES ARE CONSISTENTLY STRONGER OR WEAKER, THEN ACT 
			if not bDifferent and nDifferentMod ~= 0 then
				-- NEW EFFECT IS STRONGER
				if nDifferentMod < 0 then
					nodeTargetEffect = v;
					sMsg = "Effect ['" .. rNewEffect.sName .. "'] -> [REPLACED WEAKER] [on " .. sCTName .. "]";
					break;
				
				-- NEW EFFECT IS WEAKER
				elseif nDifferentMod > 0 then
					message("Effect ['" .. rNewEffect.sName .. "'] -> [STRONGER EFFECT EXISTS]", nodeCT, false, sUser);
					return;
				end
			end
		end  -- END DIFFERENCE CHECK
	end  -- END EFFECTS LOOP
	
	-- BLANK EFFECT CHECK
	if not nodeTargetEffect then
		for k, v in pairs(nodeEffectsList.getChildren()) do
			if DB.getValue(v, "label", "") == "" then
				nodeTargetEffect = v;
				break;
			end
		end
	end
	if not nodeTargetEffect then
		nodeTargetEffect = nodeEffectsList.createChild();
		if not nodeTargetEffect then
			return;
		end
	end
	
	-- ADD EFFECT DETAILS
	DB.setValue(nodeTargetEffect, "label", "string", rNewEffect.sName);
	DB.setValue(nodeTargetEffect, "expiration", "string", rNewEffect.sExpire);
	DB.setValue(nodeTargetEffect, "effectsavemod", "number", rNewEffect.nSaveMod);
	DB.setValue(nodeTargetEffect, "effectinit", "number", rNewEffect.nInit);
	DB.setValue(nodeTargetEffect, "isgmonly", "number", rNewEffect.nGMOnly);
	if rNewEffect.sApply then
		DB.setValue(nodeTargetEffect, "apply", "string", rNewEffect.sApply);
	end

	-- HANDLE EFFECT TARGET SETTING
	if sEffectTargetNode and sEffectTargetNode ~= "" then
		TargetingManager.addTarget("host", nodeTargetEffect.getNodeName(), sEffectTargetNode);
	end
	
	-- BUILD MESSAGE
	local msg = {font = "msgfont", icon = "indicator_effect"};
	if sMsg ~= "" then
		msg.text = sMsg;
	else
		msg.text = "Effect ['" .. rNewEffect.sName .. "'] -> [to " .. sCTName .. "]";
	end
	
	-- HANDLE APPLIED BY SETTING
	if rNewEffect.sSource and rNewEffect.sSource ~= "" then
		DB.setValue(nodeTargetEffect, "source_name", "string", rNewEffect.sSource);
		msg.text = msg.text .. " [by " .. DB.getValue(DB.findNode(rNewEffect.sSource), "name", "") .. "]";
	end
	
	-- SEND MESSAGE
	if bShowMsg then
		if isGMEffect(nodeCT, nodeTargetEffect) then
			if sUser == "" then
				msg.text = "[GM] " .. msg.text;
				Comm.addChatMessage(msg);
			elseif sUser ~= "" then
				Comm.addChatMessage(msg);
				Comm.deliverChatMessage(msg, sUser);
			end
		else
			Comm.deliverChatMessage(msg);
		end
	end
end

-- MAKE SURE AT LEAST ONE EFFECT REMAINS AFTER DELETING
function deleteEffect(nodeEffect)
	if not nodeEffect then
		return;
	end
	
	local nodeEffectList = nodeEffect.getParent();
	nodeEffect.delete();
	if nodeEffectList then
		if nodeEffectList.getChildCount() == 0 then
			nodeEffectList.createChild();
		end
	end
end

function expireEffect(nodeActor, nodeEffect, nExpireComponent, bOverride)
	-- VALIDATE
	if not nodeEffect then
		return false;
	end

	-- PARSE THE EFFECT
	local sEffect = DB.getValue(nodeEffect, "label", "");
	local listEffectComp = parseEffect(sEffect);

	-- DETERMINE MESSAGE VISIBILITY
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);

	-- CHECK FOR PARTIAL EXPIRATION
	if nExpireComponent > 0 then
		if #listEffectComp > 1 then
			table.remove(listEffectComp, nExpireComponent);

			local sNewEffect = rebuildParsedEffect(listEffectComp);
			DB.setValue(nodeEffect, "label", "string", sNewEffect);

			message("Effect ['" .. sEffect .. "'] -> [SINGLE MOD USED]", nodeActor, bGMOnly);
			return true;
		end
	end
	
	-- CHECK FOR FOLLOW-ON
	local i = 1;
	while i <= #listEffectComp do
		if listEffectComp[i].type == "AFTER" then
			break;
		end
		i = i + 1;
	end
	
	-- IF WE HAVE FOLLOW-ON, THEN STRIP OUT EXPIRED PART OF EFFECT
	local sMsg = "";
	if i <= #listEffectComp and not bOverride then
		sMsg = "Effect ['" .. sEffect .. "'] -> [UPDATED]";

		local sNewExpiration = table.concat(listEffectComp[i].remainder, " ");
		local aNewEffectComp = {};
		for j = i + 1, #listEffectComp do
			table.insert(aNewEffectComp, listEffectComp[j]);
		end
		local sNewEffect = rebuildParsedEffect(aNewEffectComp);
		
		DB.setValue(nodeEffect, "label", "string", sNewEffect);
		DB.setValue(nodeEffect, "expiration", "string", sNewExpiration);

	-- IF NO FOLLOW-ON, THEN DELETE THE EFFECT
	else
		sMsg = "Effect ['" .. sEffect .. "'] -> [EXPIRED]";
		deleteEffect(nodeEffect);
	end

	-- SEND NOTIFICATION TO THE HOST
	message(sMsg, nodeActor, bGMOnly);
	return true;
end

function disableEffect(nodeActor, nodeEffect)
	if not nodeEffect then
		return false;
	end

	local sEffect = DB.getValue(nodeEffect, "label", "");
	local bGMOnly = isGMEffect(nodeActor, nodeEffect);
	
	DB.setValue(nodeEffect, "isactive", "number", 2);
	
	message("Effect ['" .. sEffect .. "'] -> [DISABLED]", nodeActor, bGMOnly);
end

function handleFailedSave(nodeActor, nodeEffect)
	-- VALIDATE
	if not nodeEffect then
		return false;
	end

	-- CHECK FOR FOLLOW-ON
	local listEffectComp = parseEffect(DB.getValue(nodeEffect, "label", ""));
	local i = 1;
	while i <= #listEffectComp do
		if listEffectComp[i].type == "FAIL" then
			break;
		end
		i = i + 1;
	end
	
	-- IF NO FOLLOW-ON, THEN EXIT
	if i > #listEffectComp then
		return false;
	end
	
	-- IF WE HAVE FOLLOW-ON FOR FAILED SAVE, THEN STRIP OUT EXPIRED PART OF EFFECT
	local sExpirationNew = table.concat(listEffectComp[i].remainder, " ");
	local listEffectNew = {};
	for j = i + 1, #listEffectComp do
		local sTemp = "";
		if listEffectComp[j].type ~= "" then
			sTemp = listEffectComp[j].type .. ":";
			if (listEffectComp[j].mod ~= 0) or (#(listEffectComp[j].dice) > 0) then
				sTemp = sTemp .. " " .. StringManager.convertDiceToString(listEffectComp[j].dice, listEffectComp[j].mod);
			end
			sTemp = sTemp .. " " .. table.concat(listEffectComp[j].remainder, " ");
		else
			sTemp = table.concat(listEffectComp[j].remainder, " ");
		end
		table.insert(listEffectNew, sTemp);
	end

	-- BUILD NOTIFICATION MESSAGE
	local sMsg = "Effect ['" .. DB.getValue(nodeEffect, "label", "") .. "'] -> [UPDATED]";
				
	-- UPDATE THE EFFECT
	DB.setValue(nodeEffect, "label", "string", table.concat(listEffectNew, "; "));
	DB.setValue(nodeEffect, "expiration", "string", sExpirationNew);

	-- SEND NOTIFICATION TO THE HOST
	local nodeCTEntry = nodeEffect.getChild("...");
	message(sMsg, nodeCTEntry, isGMEffect(nodeActor, nodeEffect));
	return true;
end

function applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp)
	-- EXIT IF EMPTY REGEN
	if #(rEffectComp.dice) == 0 and rEffectComp.mod == 0 then
		return;
	end
	
	-- BUILD MESSAGE
	local aResults = {};
	if isGMEffect(nodeActor, nodeEffect) then
		table.insert(aResults, "[GM]");
	end
	if rEffectComp.type == "REGEN" then
		local nWounds = DB.getValue(nodeActor, "wounds", 0);
		local nHP = DB.getValue(nodeActor, "hp", 0);

		-- MAKE SURE AFFECTED ACTOR IS WOUNDED BEFORE BOTHERING WITH REGENERATION
		if nHP <= 0 or nWounds <= 0 then
			return;
		end
		-- REGENERATION DOES NOT WORK ONCE THE CREATURE FALLS BELOW 1 HIT POINT
		if nWounds >= nHP then
			return;
		end
		
		table.insert(aResults, "[HEAL] Regeneration");
	else
		table.insert(aResults, "[DAMAGE] Ongoing damage");
		if #(rEffectComp.remainder) > 0 then
			table.insert(aResults, "[TYPE: " .. string.lower(table.concat(rEffectComp.remainder, ",")) .. "]");
		end
	end
	
	-- MAKE ROLL AND APPLY RESULTS
	local rTarget = ActorManager.getActor("ct", nodeActor);
	local rRoll = { sType = "damage", sDesc = table.concat(aResults, " "), aDice = rEffectComp.dice, nMod = rEffectComp.mod };
	ActionsManager.roll(nil, rTarget, rRoll);
end

function applyRecharge(nodeActor, nodeEffect, rEffectComp)
	local rActor = ActorManager.getActor("ct", nodeActor);
	local sRecharge = table.concat(rEffectComp.remainder, " ");
	ActionRecharge.performRoll(nil, rActor, sRecharge, rEffectComp.mod, isGMEffect(nodeActor, nodeEffect), nodeEffect);
end

function makeEffectSave(nodeActor, nodeEffect)
	-- DEPENDING ON OPTION, EITHER AUTOMATICALLY MAKE THE SAVING THROW OR JUST NOTIFY
	if OptionsManager.isOption("ESAV", "on") or 
			((OptionsManager.isOption("ESAV", "npc") and DB.getValue(nodeActor, "type", "") ~= "pc")) then

		local rActor = ActorManager.getActor("ct", nodeActor);
		local bGMOnly = isGMEffect(nodeActor, nodeEffect);
		
		ActionSave.performAutoRoll(rActor, bGMOnly, false, nodeEffect);
	else
		local sMsg = "Effect ['" .. DB.getValue(nodeEffect, "label", "") .. "'] -> [ALLOWS SAVE]";
		
		message(sMsg, nodeEffect.getChild("..."), isGMEffect(nodeActor, nodeEffect));
	end
end

function processEffects(nodeActorList, nodeCurrentActor, nodeNewActor)
	-- SETUP CURRENT AND NEW INITIATIVE VALUES
	local nCurrentInit = 10000;
	if nodeCurrentActor then
		nCurrentInit = DB.getValue(nodeCurrentActor, "initresult", 0); 
	end
	local nNewInit = -10000;
	if nodeNewActor then
		nNewInit = DB.getValue(nodeNewActor, "initresult", 0);
	end
	
	-- ITERATE THROUGH EACH ACTOR
	for _,nodeActor in pairs(DB.getChildren(nodeActorList, "")) do
		-- ITERATE THROUGH EACH EFFECT
		for _,nodeEffect in pairs(DB.getChildren(nodeActor, "effects")) do
			-- MAKE SURE THE EFFECT IS ACTIVE
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if (nActive ~= 0) then
				-- GET EFFECT DETAILS
				local sEffName = DB.getValue(nodeEffect, "label", "");
				local sEffExp = DB.getValue(nodeEffect, "expiration", "");
				local nEffInit = DB.getValue(nodeEffect, "effectinit", "");
			
				-- HANDLE END OF TURN EFFECTS FOR CURRENT ACTOR
				if sEffExp == "end" then
					if nEffInit <= nCurrentInit and nEffInit > nNewInit then
						expireEffect(nodeActor, nodeEffect, 0);
					end
				elseif sEffExp == "endnext" then
					if nEffInit <= nCurrentInit and nEffInit > nNewInit then
						DB.setValue(nodeEffect, "expiration", "string", "end");
					end
				elseif sEffExp == "save" and nodeActor == nodeCurrentActor then
					makeEffectSave(nodeActor, nodeEffect);
				end
				
				-- HANDLE START OF TURN EFFECTS
				if sEffExp == "start" then
					if nEffInit < nCurrentInit and nEffInit >= nNewInit then
						expireEffect(nodeActor, nodeEffect, 0);
					end
				end
			
				-- HANDLE TRANSITION TO NEW ACTOR
				if nodeActor == nodeNewActor then
					local listEffectComp = parseEffect(sEffName);
					for _,rEffectComp in ipairs(listEffectComp) do
						-- CHECK FOR EFFECTS THE BREAK EXECUTION
						if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
							break;
						
						-- CHECK CONDITIONALS
						elseif rEffectComp.type == "IFT" then
							break;
						elseif rEffectComp.type == "IF" then
							local rActor = ActorManager.getActor("ct", nodeActor);
							if not checkConditional(rActor, nodeEffect, rEffectComp.remainder) then
								break;
							end
						
						-- ONGOING DAMAGE ADJUSTMENT (INCLUDING REGENERATION)
						elseif rEffectComp.type == "DMGO" or rEffectComp.type == "REGEN" then
							if nActive == 2 then
								DB.setValue(nodeEffect, "isactive", "number", 1);
							else
								applyOngoingDamageAdjustment(nodeActor, nodeEffect, rEffectComp);
							end

						-- NPC POWER RECHARGE
						elseif rEffectComp.type == "RCHG" then
							if nActive == 2 then
								DB.setValue(nodeEffect, "isactive", "number", 1);
							else
								applyRecharge(nodeActor, nodeEffect, rEffectComp);
							end
						end
					end
				end
			end -- END ACTIVE EFFECT CHECK
		end -- END EFFECT LOOP
	end -- END ACTOR LOOP
end

function evalAbilityHelper(rActor, sEffectAbility)
	-- PARSE EFFECT ABILITY TAG
	local sSign, sModifier, sShortAbility = string.match(sEffectAbility, "^%[([%+%-]?)([H2]?)([A-Z][A-Z][A-Z])%]$");
	
	-- FIGURE OUT WHICH ABILITY
	local nAbility = nil;
	if sShortAbility == "STR" then
		nAbility = ActorManager.getAbilityBonus(rActor, "strength");
	elseif sShortAbility == "DEX" then
		nAbility = ActorManager.getAbilityBonus(rActor, "dexterity");
	elseif sShortAbility == "CON" then
		nAbility = ActorManager.getAbilityBonus(rActor, "constitution");
	elseif sShortAbility == "INT" then
		nAbility = ActorManager.getAbilityBonus(rActor, "intelligence");
	elseif sShortAbility == "WIS" then
		nAbility = ActorManager.getAbilityBonus(rActor, "wisdom");
	elseif sShortAbility == "CHA" then
		nAbility = ActorManager.getAbilityBonus(rActor, "charisma");
	elseif sShortAbility == "LVL" then
		nAbility = ActorManager.getAbilityBonus(rActor, "level");
	end
	
	-- IF VALID SHORT ABILITY, THEN APPLY SIGN AND MODIFIERS
	if nAbility then
		if sSign == "-" then
			nAbility = 0 - nAbility;
		end
		if sModifier == "H" then
			if nAbility > 0 then
				nAbility = math.floor(nAbility / 2);
			else
				nAbility = math.ceil(nAbility / 2);
			end
		elseif sModifier == "2" then
			nAbility = nAbility * 2;
		end
	end
	
	-- RESULTS
	return nAbility;
end

function evalEffect(rActor, s)
	-- VALIDATE
	if not s then
		return "";
	end
	if not rActor then
		return s;
	end
	
	-- SETUP
	local aNewEffect = {};
	
	-- PARSE EFFECT STRING
	local aEffectComp = StringManager.split(s, ";", true);
	for _,sComp in pairs(aEffectComp) do
		local aWords = StringManager.parseWords(sComp, ":%[%]");
		
		if #aWords > 0 then
			if string.match(aWords[1], ":$") then
				local aTempWords = { aWords[1] };
				local nTotalMod = 0;
				
				local i = 2;
				local bAbilityFound = false;
				while aWords[i] do
					local nAbility = evalAbilityHelper(rActor, aWords[i]);
					if nAbility then
						bAbilityFound = true;
						nTotalMod = nTotalMod + nAbility;
					else
						table.insert(aTempWords, aWords[i]);
					end

					i = i + 1;
				end
				
				if StringManager.isDiceString(aTempWords[2]) then
					if nTotalMod ~= 0 then
						local aTempDice, nTempMod = StringManager.convertStringToDice(aTempWords[2]);
						nTempMod = nTempMod + nTotalMod;
						aTempWords[2] = StringManager.convertDiceToString(aTempDice, nTempMod);
					end
				elseif bAbilityFound then
					table.insert(aTempWords, 2, "" .. nTotalMod);
				end

				table.insert(aNewEffect, table.concat(aTempWords, " "));
			else
				table.insert(aNewEffect, sComp);
			end
		end
	end
	
	return table.concat(aNewEffect, "; ");
end

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	
	-- SETUP
	local results = {};
	
	-- SEPARATE FILTERS
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- DETERMINE WHETHER EFFECT COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETING
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
	-- ITERATE THROUGH EFFECTS
	for _,v in pairs(DB.getChildren(rActor.nodeCT, "effects")) do
		-- MAKE SURE EFFECT IS ACTIVE
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			-- PARSE EFFECT
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");
			local effect_list = EffectsManager.parseEffect(sLabel);

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = isTargetedEffect(v);
			if not bTargeted or isEffectTarget(v, rFilterActor) then

			-- LOOK THROUGH EFFECT CLAUSES FOR A TYPE (or TYPE/SUBTYPE) MATCH
				local nMatch = 0;
				for kEffectComp, rEffectComp in ipairs(effect_list) do
					-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
					if StringManager.contains({"AFTER", "FAIL"}, rEffectComp.type) then
						break;

					-- CHECK CONDITIONALS
					elseif rEffectComp.type == "IF" then
						if not checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;

					-- COMPARE ON OTHER EFFECT ATTRIBUTES
					else
						-- STRIP OUT ENERGY OR BONUS TYPES FOR SUBTYPE COMPARISON
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						for _,v2 in pairs(rEffectComp.remainder) do
							if StringManager.contains(DataCommon.dmgtypes, v2) or 
									StringManager.contains(DataCommon.bonustypes, v2) then
								-- SKIP
							elseif StringManager.contains(DataCommon.rangetypes, v2) then
								table.insert(aEffectRangeFilter, v2);
							else
								table.insert(aEffectOtherFilter, v2);
							end
						end
					
						-- CHECK TO MAKE SURE THIS COMPONENT MATCHES THE ONE WE'RE SEARCHING FOR
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- CHECK FOR EFFECT CHECKS FOR TARGETS ONLY (EITHER BY EFFECT OR CONDITION)
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- CHECK THE FILTERS
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- WE FOUND A MATCH
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- REMOVE ONE-SHOT EFFECTS
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							if bLocked then
								table.insert(aUsedActionEffects, v.getNodeName());
							else
								notifyExpire(v, 0);
							end
						elseif sApply == "roll" then
							notifyExpire(v, 0);
						elseif sApply == "single" then
							notifyExpire(v, nMatch);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

function getEffectsBonusByType(rActor, aEffectType, bAddEmptyBonus, aFilter, rFilterActor, bTargetedOnly)
	-- VALIDATE
	if not rActor or not rActor.nodeCT or not aEffectType then
		return {}, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local bonuses = {};
	local penalties = {};
	local nEffectCount = 0;
	
	for k, v in pairs(aEffectType) do
		-- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
		local aEffectsByType = getEffectsByType(rActor, v, aFilter, rFilterActor, bTargetedOnly);

		-- ITERATE THROUGH EFFECTS THAT MATCHED
		for k2,v2 in pairs(aEffectsByType) do
			-- LOOK FOR ENERGY OR BONUS TYPES
			local energy_type = nil;
			local mod_type = nil;
			for _,v3 in pairs(v2.remainder) do
				if StringManager.contains(DataCommon.dmgtypes, v3) then
					energy_type = v3;
					break;
				elseif StringManager.contains(DataCommon.immunetypes, v3) then
					energy_type = v3;
					break;
				elseif v3 == "all" then
					energy_type = v3;
					break;
				elseif StringManager.contains(DataCommon.bonustypes, v3) then
					mod_type = v3;
					break;
				end
			end
			
			-- IF MODIFIER TYPE IS UNTYPED OR AN ENERGY TYPE, THEN APPEND MODIFIERS
			-- (SUPPORTS DICE)
			if energy_type or not mod_type then
				-- ADD EFFECT RESULTS 
				local new_key = energy_type or "";
				local new_results = results[new_key] or {dice = {}, mod = 0};

				-- BUILD THE NEW RESULT
				for _,v3 in pairs(v2.dice) do
					table.insert(new_results.dice, v3); 
				end
				if bAddEmptyBonus then
					new_results.mod = new_results.mod + v2.mod;
				else
					new_results.mod = math.max(new_results.mod, v2.mod);
				end

				-- SET THE NEW DICE RESULTS BASED ON ENERGY TYPE
				results[new_key] = new_results;

			-- OTHERWISE, TRACK BONUSES AND PENALTIES BY MODIFIER TYPE 
			-- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
			else
				if v2.mod >= 0 then
					bonuses[mod_type] = math.max(v2.mod, bonuses[mod_type] or 0);
				elseif v2.mod < 0 then
					penalties[mod_type] = math.min(v2.mod, penalties[mod_type] or 0);
				end

			end
			
			-- INCREMENT EFFECT COUNT
			nEffectCount = nEffectCount + 1;
		end
	end

	-- COMBINE BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
	for k2,v2 in pairs(bonuses) do
		if results[k2] then
			results[k2].mod = results[k2].mod + v2;
		else
			results[k2] = {dice = {}, mod = v2, remainder = {}};
		end
	end
	for k2,v2 in pairs(penalties) do
		if results[k2] then
			results[k2].mod = results[k2].mod + v2;
		else
			results[k2] = {dice = {}, mod = v2, remainder = {}};
		end
	end

	-- RESULTS
	return results, nEffectCount;
end

function getEffectsBonus(rActor, aEffectType, bModOnly, aFilter, rFilterActor, bTargetedOnly)
	-- VALIDATE
	if not rActor or not rActor.nodeCT or not aEffectType then
		if bModOnly then
			return 0, 0;
		end
		return {}, 0, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	
	-- START WITH AN EMPTY MODIFIER TOTAL
	local aTotalDice = {};
	local nTotalMod = 0;
	local nEffectCount = 0;
	
	-- ITERATE THROUGH EACH BONUS TYPE
	local masterbonuses = {};
	local masterpenalties = {};
	for k, v in pairs(aEffectType) do
		-- GET THE MODIFIERS FOR THIS MODIFIER TYPE
		local effbonusbytype, nEffectSubCount = getEffectsBonusByType(rActor, v, true, aFilter, rFilterActor, bTargetedOnly);
		
		-- ITERATE THROUGH THE MODIFIERS
		for k2, v2 in pairs(effbonusbytype) do
			-- IF MODIFIER TYPE IS UNTYPED OR ENERGY TYPE, THEN APPEND TO TOTAL MODIFIER
			-- (SUPPORTS DICE)
			if k2 == "" or StringManager.contains(DataCommon.dmgtypes, k2) then
				for k3, v3 in pairs(v2.dice) do
					table.insert(aTotalDice, v3);
				end
				nTotalMod = nTotalMod + v2.mod;
			
			-- OTHERWISE, WE HAVE A NON-ENERGY MODIFIER TYPE, WHICH MEANS WE NEED TO INTEGRATE
			-- (IGNORE DICE, ONLY TAKE BIGGEST BONUS AND/OR PENALTY FOR EACH MODIFIER TYPE)
			else
				if v2.mod >= 0 then
					masterbonuses[k2] = math.max(v2.mod, masterbonuses[k2] or 0);
				elseif v2.mod < 0 then
					masterpenalties[k2] = math.min(v2.mod, masterpenalties[k2] or 0);
				end
			end
		end

		-- ADD TO EFFECT COUNT
		nEffectCount = nEffectCount + nEffectSubCount;
	end

	-- ADD INTEGRATED BONUSES AND PENALTIES FOR NON-ENERGY TYPED MODIFIERS
	for k,v in pairs(masterbonuses) do
		nTotalMod = nTotalMod + v;
	end
	for k,v in pairs(masterpenalties) do
		nTotalMod = nTotalMod + v;
	end
	
	-- RESULTS
	if bModOnly then
		return nTotalMod, nEffectCount;
	end
	return aTotalDice, nTotalMod, nEffectCount;
end

function isEffectTarget(nodeEffect, rTarget)
	local bMatch = false;
	
	if rTarget and rTarget.nodeCT then
		local sTargetNodeName = rTarget.nodeCT.getNodeName();
		for _,v in pairs(DB.getChildren(nodeEffect, "targets")) do
			if DB.getValue(v, "noderef", "") == sTargetNodeName then
				bMatch = true;
				break;
			end
		end
	end

	return bMatch;
end

function getEffectsForCondition(rActor, sEffect)
	-- Parameter validation
	if not rActor or not sEffect then
		return nil;
	end
	
	local sLowerEffect = string.lower(sEffect);

	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(rActor.nodeCT, "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local effect_list = EffectsManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			for kEffectComp, rEffectComp in ipairs(effect_list) do
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					break;
				else
					if string.lower(rEffectComp.original) == sLowerEffect then
						if nActive == 2 then
							DB.setValue(v, "isactive", "number", 1);
						else
							table.insert(aMatch, {node = v, match = kEffectComp});
							local sApply = DB.getValue(v, "apply", "");
							if sApply ~= "single" then
								break;
							end
						end
					end
				end
			end
		end
	end
	
	-- Return results
	if #aMatch > 0 then
		return aMatch;
	end
	return nil;
end

function expireSingleEffects(nodeSourceActor, aEffects)
	if not aEffects then
		return;
	end
	
	for k,v in pairs(aEffects) do
		local sApply = DB.getValue(v.node, "apply", "");
		if sApply == "action" then
			if bLocked then
				table.insert(aUsedActionEffects, v.getNodeName());
			else
				notifyExpire(v, 0);
			end
		elseif sApply == "roll" then
			notifyExpire(v, 0);
		elseif sApply == "single" then
			notifyExpire(v, nMatch);
		end
	end
end

function applyMarkPenalty(rAttacker, aTargets)
	if not rAttacker then
		return false;
	end
	
	local bApplyMarkPenalty = false;
	if #aTargets > 0 then
		-- APPLY MARKING PENALTY, IF NEEDED
		local aMarkEffects = getEffectsForCondition(rAttacker, "Marked");
		if aMarkEffects then
			for k,v in pairs(aMarkEffects) do
				local bEffectApplyMarkPenalty = false;
				
				local sEffectSourceNode = DB.getValue(v.node, "source_name", "");
				if sEffectSourceNode ~= "" then
					bEffectApplyMarkPenalty = true;

					for _,vActor in pairs(aTargets) do
						if sEffectSourceNode == vActor.sCTNode then
							bEffectApplyMarkPenalty = false;
						end
					end
				end
				
				if bEffectApplyMarkPenalty then
					bApplyMarkPenalty = true;
				end
			end

			expireSingleEffects(rAttacker.nodeCT, aMarkEffects);
		end
	end
	
	return bApplyMarkPenalty;
end

function hasEffectCondition(rActor, sEffect)
	return hasEffect(rActor, sEffect, nil, false, true);
end

function hasEffect(rActor, sEffect, rTarget, bTargetedOnly, bIgnoreEffectTargets)
	-- Parameter validation
	if not sEffect or not rActor then
		return false;
	end

	-- Handle bloodied special case
	local sLowerEffect = string.lower(sEffect);
	if sLowerEffect == "bloodied" then
		local nPercentWounded = ActorManager.getPercentWounded("ct", rActor.nodeCT);
		if nPercentWounded >= .5 then
			return true;
		end
		return false;
	end

	-- Iterate through each effect
	local aMatch = {};
	for _,v in pairs(DB.getChildren(rActor.nodeCT, "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectsManager.isTargetedEffect(v);
			local effect_list = EffectsManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, rEffectComp in ipairs(effect_list) do
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif string.lower(rEffectComp.original) == sLowerEffect then
					if bTargeted and not bIgnoreEffectTargets then
						if isEffectTarget(v, rTarget) then
							nMatch = kEffectComp;
						end
					elseif not bTargetedOnly then
						nMatch = kEffectComp;
					end
				end
				
			end
			
			-- If matched, then remove one-off effects
			if nMatch > 0 then
				if nActive == 2 then
					DB.setValue(v, "isactive", "number", 1);
				else
					table.insert(aMatch, v);
					local sApply = DB.getValue(v, "apply", "");
					if sApply == "action" then
						if bLocked then
							table.insert(aUsedActionEffects, v.getNodeName());
						else
							notifyExpire(v, 0);
						end
					elseif sApply == "roll" then
						notifyExpire(v, 0);
					elseif sApply == "single" then
						notifyExpire(v, nMatch);
					end
				end
			end
		end
	end
	
	-- Return results
	if #aMatch > 0 then
		return true;
	end
	return false;
end

function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
	local bReturn = true;
	
	if not aIgnore then
		aIgnore = {};
	end
	table.insert(aIgnore, nodeEffect.getNodeName());
	
	for _,v in ipairs(aConditions) do
		local sLower = v:lower();
		if sLower == "bloodied" then
			local nPercentWounded = ActorManager.getPercentWounded("ct", rActor.nodeCT);
			if nPercentWounded < .5 then
				bReturn = false;
			end
		elseif StringManager.contains(DataCommon.conditions, sLower) then
			if not checkConditionalHelper(rActor, sLower, rTarget, aIgnore) then
				bReturn = false;
			end
		end
	end
	
	table.remove(aIgnore);
	
	return bReturn;
end

function checkConditionalHelper(rActor, sEffect, rTarget, aIgnore)
	if not rActor then
		return false;
	end
	
	local bReturn = false;
	
	for _,v in pairs(DB.getChildren(rActor.nodeCT, "effects")) do
		local nActive = DB.getValue(v, "isactive", 0);
		if nActive ~= 0 and not StringManager.contains(aIgnore, v.getNodeName()) then
			-- Parse each effect label
			local sLabel = DB.getValue(v, "label", "");
			local bTargeted = EffectsManager.isTargetedEffect(v);
			local aEffectComps = EffectsManager.parseEffect(sLabel);

			-- Iterate through each effect component looking for a type match
			local nMatch = 0;
			for kEffectComp, rEffectComp in ipairs(aEffectComps) do
				-- CHECK FOR FOLLOWON EFFECT TAGS, AND IGNORE THE REST
				if rEffectComp.type == "AFTER" or rEffectComp.type == "FAIL" then
					break;
				
				-- CHECK CONDITIONALS
				elseif rEffectComp.type == "IF" then
					if not checkConditional(rActor, v, rEffectComp.remainder, nil, aIgnore) then
						break;
					end
				elseif rEffectComp.type == "IFT" then
					if not rTarget then
						break;
					end
					if not checkConditional(rTarget, v, rEffectComp.remainder, rActor, aIgnore) then
						break;
					end
				
				-- CHECK FOR AN ACTUAL EFFECT MATCH
				elseif string.lower(rEffectComp.original) == sEffect then
					if bTargeted then
						if isEffectTarget(v, rTarget) then
							bReturn = true;
						end
					else
						bReturn = true;
					end
				end
			end
		end
	end
	
	return bReturn;
end

--
--  HANDLE EFFECT LOCKING
--

function lock()
	bLocked = true;
end

function unlock()
	bLocked = false;

	local aExpired = {};
	
	for _,v in ipairs(aUsedActionEffects) do
		if not aExpired[v] then
			notifyExpire(v, 0);
			aExpired[v] = true;
		end
	end
	
	aUsedActionEffects = {};
end
