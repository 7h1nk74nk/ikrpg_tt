-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeCoinList = getDatabaseNode().createChild("coinlist");
	nodeCoinList.onChildUpdate = totalMoneyTreasure;

	onLevelChanged();
end

function onLevelChanged()
	local nLevel = partylevel.getValue();
	
	if nLevel <= 10 then
		label_money.setValue("GP");
		label_tier.setValue("Heroic Tier Treasure Parcel");
	elseif nLevel <= 20 then
		label_money.setValue("GP");
		label_tier.setValue("Paragon Tier Treasure Parcel");
	else
		label_money.setValue("PP");
		label_tier.setValue("Epic Tier Treasure Parcel");
	end

	totalMoneyTreasure();
end

function totalMoneyTreasure()
	local nTotal = 0;
	
	for _,v in pairs(DB.getChildren(getDatabaseNode(), "coinlist")) do
		local sDesc = string.lower(DB.getValue(v, "description", ""));
		local nAmount = DB.getValue(v, "amount", 0);
		
		if sDesc:match("gold") or sDesc:match("gp") then
			nTotal = nTotal + nAmount;
		elseif sDesc:match("platinum") or sDesc:match("pp") then
			nTotal = nTotal + (nAmount * 100);
		elseif sDesc:match("silver") or sDesc:match("sp") then
			nTotal = nTotal + math.floor((nAmount / 10) + 0.5);
		elseif sDesc:match("copper") or sDesc:match("cp") then
			nTotal = nTotal + math.floor((nAmount / 100) + 0.5);
		elseif sDesc:match("astral diamond") or sDesc:match("ad") then
			nTotal = nTotal + (nAmount * 10000);
		elseif sDesc:match("residuum") then
			nTotal = nTotal + (nAmount * 10000);
		end
	end
						
	if partylevel.getValue() >= 21 then
		nTotal = math.floor((nTotal / 100) + 0.5);
	end
	
	monetarytotal.setValue(nTotal);
end
