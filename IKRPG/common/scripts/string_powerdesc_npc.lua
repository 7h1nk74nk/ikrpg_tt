-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getCreatureType()
	return "npc";
end

function getCreatureNode()
	-- STANDARD POWER WINDOWS
	local node = window.getDatabaseNode();
	if node then
		return node.getChild("...");
	end
	
	-- VIRTUAL POWER WINDOWS
	local win = window;
	while win.windowlist and win.windowlist.window do
		win = win.windowlist.window;
	end
	return win.getDatabaseNode();
end

function getCreatureName()
	return DB.getValue(getCreatureNode(), "name", "");
end
