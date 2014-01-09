-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onSubwindowInstantiated()
	for _,v in pairs(partylist.getWindows()) do
		-- v.onXPChanged();
		-- v.onHPChanged();
		v.onPHYChanged();
		v.onAGIChanged();
		v.onINTChanged();
	end
end

function clearEffect()
	effectexpiration.setStringValue("");
	effectisgmonly.setState(0);
	effectapply.setStringValue("");
	effectlabel.setValue("");
	effectsavemod.setValue(0);
end
