-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function VisDataCleared()
	update();
end

function InvisDataAdded()
	update();
end

function updateControl(sControl, bLock, bID, vHideOnValue)
	local bLocalShow = bID;
	
	if self[sControl] then
		if bLock then
			self[sControl].setReadOnly(true);
			
			local vControl = self[sControl].getValue();
			if vControl == "" or vControl == vHideOnValue then
				bLocalShow = false;
			end
		else
			self[sControl].setReadOnly(false);
		end
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
	
	return bLocalShow;
end

function update()
	local bOptionID = OptionsManager.isOption("MIID", "on");
	local bLock, bID = parentcontrol.window.getAccessState();
	
	local bSection1 = false;
	if updateControl("flavor", bLock, bID) then bSection1 = true; end

	local bSection2 = false;
	if User.isHost() then
		if updateControl("nonid_name", bLock, bOptionID) then bSection2 = true; end
	else
		updateControl("nonid_name", true, false);
	end
	if updateControl("nonidentified", bLock, bOptionID) then bSection2 = true; end

	local bSection3 = false;
	if updateControl("class", bLock, bID) then bSection3 = true; end
	if updateControl("subclass", bLock, bID) then bSection3 = true; end
	if updateControl("cost", bLock, bID) then bSection3 = true; end
	if updateControl("weight", bLock, bID, 0) then bSection3 = true; end
	
	divider.setVisible(bID);
	divider2.setVisible(bOptionID);
	divider3.setVisible(bID);

	local bSection4 = false;
	if updateControl("level", bLock, bID) then bSection4 = true; end
	if updateControl("bonus", bLock, bID) then bSection4 = true; end
	if updateControl("enhancement", bLock, bID) then bSection4 = true; end
	if updateControl("special", bLock, bID) then bSection4 = true; end
	if updateControl("prerequisite", bLock, bID) then bSection4 = true; end
	
	if updateControl("shield", bLock, bID) then bSection4 = true; end

	if updateControl("critical", bLock, bID) then bSection4 = true; end
	if updateControl("profbonus", bLock, bID) then bSection4 = true; end
	if updateControl("damage", bLock, bID) then bSection4 = true; end
	if updateControl("range", bLock, bID) then bSection4 = true; end
	if updateControl("group", bLock, bID) then bSection4 = true; end
	if updateControl("properties", bLock, bID) then bSection4 = true; end

	if updateControl("ac", bLock, bID) then bSection4 = true; end
	if updateControl("min_enhance", bLock, bID) then bSection4 = true; end
	if updateControl("checkpenalty", bLock, bID) then bSection4 = true; end
	if updateControl("speed", bLock, bID) then bSection4 = true; end

	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
end
