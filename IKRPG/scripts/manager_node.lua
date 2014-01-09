-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function createWindow(winList,dbnode)
	if not winList then
		return nil;
	end
	
	local nodeWindowList = winList.getDatabaseNode();
	if nodeWindowList then
		if nodeWindowList.isReadOnly() then
			return nil;
		end
	end
	if dbnode then
		return winList.createWindow(dbnode);
	else
		return winList.createWindow();
	end
end
