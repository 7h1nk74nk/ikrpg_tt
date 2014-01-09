-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeAbilities = getDatabaseNode().createChild("..abilities");
	if nodeAbilities then
		nodeAbilities.onChildUpdate = onStatUpdate;
	end
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end

function onFilter(w)
	return (DB.getValue(w.getDatabaseNode(), "showonminisheet", 0) ~= 0);
end
