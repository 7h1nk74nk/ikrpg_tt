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

function addEntry()
	local wnd = NodeManager.createWindow(self);
	if wnd then
		wnd.name.setFocus();
	end
end

function onEnter()
	if not isReadOnly() then
		addEntry();
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not isReadOnly() then
		if not getNextWindow(nil) then
			addEntry(true);
		end
	end
	return true;
end
