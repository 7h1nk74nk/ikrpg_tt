-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function update()
	local bLock, bID = window.getAccessState();
	setReadOnly(bLock);
	
	for _,w in pairs(getWindows()) do
		w.update();
	end
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function onEnter()
	if not isReadOnly() then
		addEntry();
	end
end
