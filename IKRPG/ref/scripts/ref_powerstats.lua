-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function update(wnd)
	if stringflavor then
		local bFlavor = (stringflavor.getValue() ~= "");
		stringflavor.setVisible(bFlavor);
	end
	
	if recharge and diamond and keywords then
		local bKeywords = (keywords.getValue() ~= "");
		local bRecharge = (recharge.getValue() ~= "");

		keywords.setVisible(bKeywords);
		recharge.setVisible(bRecharge);
		diamond.setVisible(bRecharge and bKeywords);
	end
	
	if action and range then
		local bAction = (action.getValue() ~= "");
		local bRange = (range.getValue() ~= "");

		range.setVisible(bRange);
		action.setVisible(bAction);
	end
	
	if link and linkedpowername then
		if string.len(linkedpowername.getValue()) == 0 then
			link.setVisible(false);
			linkedpowername.setVisible(false);
		end
	end
end
