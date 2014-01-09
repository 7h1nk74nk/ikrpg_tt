-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local class, sourcenodename = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();

		if source then
			if class == "reference_power_custom" or class == "reference_npcaltpower" then
				local name = DB.getValue(source, "name", "");
				if name ~= "" then
					local wnd = NodeManager.createWindow(self);
					if wnd then
						wnd.value.setValue(name);
						if class ~= "reference_power_custom" then
							wnd.shortcut.setValue(draginfo.getShortcutData());
						end
						DB.setValue(wnd.getDatabaseNode(), "source", "string", DB.getValue(source, "source", ""));
					end
				end
			elseif class == "powerdesc" then
				local name = DB.getValue(source, "name", "");

				if name ~= "" then
					local wnd = NodeManager.createWindow(self);
					if wnd then
						wnd.value.setValue(name);
						wnd.shortcut.setValue(draginfo.getShortcutData())
						DB.setValue(wnd.getDatabaseNode(), "source", "string", DB.getValue(source, "source", ""));
					end

					-- New style linked powers (v1.5+)
					local nodeLinked = source.getChild("linkedpowers");
					if nodeLinked then
						for _,v in pairs(nodeLinked.getChildren()) do
							local sClass, sRecord = DB.getValue(v, "link", "", "");
							if sClass == "powerdesc" then
								CharManager.addPowerDB(window.getDatabaseNode(), DB.findNode(sRecord), sClass);
							end
						end
					-- Old style linked powers (v1.0 - v1.4)
					else
						local sClass, sRecord = DB.getValue(source, "link", "", "");
						if sClass == "powerdesc" then
							CharManager.addPowerDB(window.getDatabaseNode(), DB.findNode(sRecord), sClass);
						end
					end
				end
			elseif class == "reference_ritual" then
				local name = DB.getValue(source, "name", "");

				if name ~= "" then
					local wnd = NodeManager.createWindow(self);
					if wnd then
						wnd.value.setValue("Ritual - " .. name);
						wnd.shortcut.setValue(draginfo.getShortcutData());
						DB.setValue(wnd.getDatabaseNode(), "source", "string", "Ritual");
					end
				end
			end
		end

		return true;
	end
end
