-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local NODE_TRACKER = "skillchallenge";
local NODE_TRACKER_SKILLS = "skillchallenge.skills";

function addResult(sText, nResult)
	-- CHECK FOR SKILL ROLL
	local sSkill = string.match(sText, "%[SKILL%] ([^%[%(]+)");
	if not sSkill then
		ChatManager.SystemMessage("[SCT] Only accepts skill roll results dragged from chat window.");
		return;
	end
	sSkill = StringManager.trim(sSkill);
	
	-- GET ROLLER NAME
	local sRoller = string.match(sText, "(.+) %-> %[SKILL%]");
	if sRoller then
		if string.match(sRoller, "^%[GM%]") then
			sRoller = string.sub(sRoller, 6); 
		end
		if string.match(sRoller, "^%[TOWER%]") then
			sRoller = string.sub(sRoller, 10); 
		end	
	else
		sRoller = "";
	end
	
	-- ADD SKILL ROLL RESULT TO CORRECT SKILL
	for _,nodeSkill in pairs(DB.getChildren(NODE_TRACKER_SKILLS)) do
		if DB.getValue(nodeSkill, "label", "") == sSkill then
			local nSkillDC = DB.getValue(nodeSkill, "DC", 0);
			if nSkillDC > 0 then
				local nodeRolls = nodeSkill.createChild("rolls");
				if nodeRolls then
					local nodeRoll = nodeRolls.createChild();
					if nodeRoll then
						DB.setValue(nodeRoll, "actor", "string", sRoller);
						DB.setValue(nodeRoll, "roll", "number", nResult);
						if nResult >= nSkillDC then
							DB.setValue(nodeRoll, "result", "string", "success");
						else
							DB.setValue(nodeRoll, "result", "string", "failure");
						end
					end
				end
			else
				ChatManager.SystemMessage("[SCT] Skill roll ignored, since DC is set to zero.");
			end
			
			break;
		end
	end
	
	-- UPDATE TOTALS
	calcTotals();
end

function addDC(sSkill, nDC)	
	sSkill = StringManager.trim(string.lower(sSkill));
	for _,nodeSkill in pairs(DB.getChildren(NODE_TRACKER_SKILLS)) do
		if string.lower(DB.getValue(nodeSkill, "label", "")) == sSkill then
			DB.setValue(nodeSkill, "DC", "number", nDC);
			break;
		end
	end
	
	calcTotals();
end

function calcTotals()
	-- SETUP
	local nTotalSuccess = 0;
	local nTotalFailure = 0;
	
	-- ITERATE THROUGH SKILLS
	for _,nodeSkill in pairs(DB.getChildren(NODE_TRACKER_SKILLS)) do
		-- SKILL SETUP
		local nSkillSuccess = 0;
		local nSkillFailure = 0;
		
		-- ITERATE THROUGH EACH SKILL RESULT ROLL
		for _,nodeRoll in pairs(DB.getChildren(nodeSkill, "rolls")) do
			if DB.getValue(nodeRoll, "result", "") == "success" then
				nSkillSuccess = nSkillSuccess + 1;
			else
				nSkillFailure = nSkillFailure + 1;
			end
		end
		
		-- SET THE SKILL SUCCESS/FAILURE SUB-TOTALS
		DB.setValue(nodeSkill, "success", "number", nSkillSuccess);
		DB.setValue(nodeSkill, "failure", "number", nSkillFailure);

		-- ADD SUB-TOTAL TO OVERALL TOTAL
		nTotalSuccess = nTotalSuccess + nSkillSuccess;
		nTotalFailure = nTotalFailure + nSkillFailure;
	end
	
	-- SET THE OVERALL SUCCESS/FAILURE TOTALS
	local nodeTracker = DB.findNode(NODE_TRACKER);
	DB.setValue(nodeTracker, "totalsuccess", "number", nTotalSuccess);
	DB.setValue(nodeTracker, "totalfailure", "number", nTotalFailure);
end

function reset()
	for _,nodeSkill in pairs(DB.getChildren(NODE_TRACKER_SKILLS)) do
		DB.setValue(nodeSkill, "DC", "number", 0);
		
		for _,nodeRoll in pairs(DB.getChildren(nodeSkill, "rolls")) do
			nodeRoll.delete();
		end

		DB.setValue(nodeSkill, "success", "number", 0);
		DB.setValue(nodeSkill, "failure", "number", 0);
	end

	local nodeTracker = DB.findNode(NODE_TRACKER);
	DB.setValue(nodeTracker, "totalsuccess", "number", 0);
	DB.setValue(nodeTracker, "totalfailure", "number", 0);
end

function addEncounter(nodeEnc)
	for _,v in pairs(DB.getChildren(nodeEnc, "items")) do
		local sName = DB.getValue(v, "name", "");
		local nDC = DB.getValue(v, "numberdata", 0);
		addDC(sName, nDC);
	end
end
