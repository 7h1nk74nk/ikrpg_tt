-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	constructDefaultSkills();

	registerMenuItem("Add Custom Skill", "insert", 5);
end

function onMenuSelection(selection)
	if selection == 5 then
		NodeManager.createWindow(self);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.getType("number") then
		SCManager.addResult(draginfo.getDescription(), draginfo.getNumberData());
	end

	return true;
end

function onSortCompare(w1, w2)
	if w1.label.getValue() == "" then
		return true;
	elseif w2.label.getValue() == "" then
		return false;
	end

	return w1.label.getValue() > w2.label.getValue();
end

-- Create default skill selection
function constructDefaultSkills()
	-- Collect existing entries
	local entrymap = {};
	for k, w in pairs(getWindows()) do
		local label = w.label.getValue(); 
	
		if DataCommon.skilldata[label] then
			if not entrymap[label] then
				entrymap[label] = { w };
			else
				table.insert(entrymap[label], w);
			end
			
			w.setCustom(false);
		end
	end

	-- Set properties and create missing entries for all known skills
	for k, t in pairs(DataCommon.skilldata) do
		local matches = entrymap[k];
		
		if not matches then
			local wnd = NodeManager.createWindow(self);
			if wnd then
				wnd.label.setValue(k);
				wnd.setCustom(false);
				matches = { wnd };
			end
		end
	end
end

