-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function clearSelection()
	for k, w in ipairs(getWindows()) do
		w.base.setFrame(nil);
	end
end

function addIdentity(id, aLabels, nodeLocal)
	for k, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	local wnd = NodeManager.createWindow(self);
	if wnd then
		wnd.setId(id);
		wnd.name.setValue(aLabels[1] or "");

		local aVisibleLabels = {};
		if aLabels[2] then
			table.insert(aVisibleLabels, aLabels[2]);
		end
		if aLabels[3] and aLabels[3] ~= 0 then
			table.insert(aVisibleLabels, aLabels[3]);
		end
		wnd.classlevel.setValue(table.concat(aVisibleLabels, " "));
		
		wnd.setLocalNode(nodeLocal);

		if id then
			wnd.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end
	end
end

function onInit()
	activeidentities = User.getAllActiveIdentities();

	if User.isLocal() then
		createWindowWithClass("charlist_client_newentry");
	end

	localIdentities = User.getLocalIdentities();
	for n, v in ipairs(localIdentities) do
		local aLabels = {};
		aLabels[1] = DB.getValue(v.databasenode, "name", "");
		aLabels[2] = DB.getValue(v.databasenode, "class.base", "");
		aLabels[3] = DB.getValue(v.databasenode, "level", 0);
		
		addIdentity(v.id, aLabels, v.databasenode);
	end
end
