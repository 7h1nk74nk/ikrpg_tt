-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;
hasSubSkills=false;

sets = {};

function onInit()
	setRadialOptions();
    updateSubStatus();
	onStatUpdate();
    
end

function updateSubStatus()
    if parentskill.getValue()=="" then
    else
        setCustom(true);
        label.setAnchor("left", "", "left","absolute",90);
        label.setAnchor("top", "", "top","absolute",5);
        label.setAnchoredWidth(85);
        --wnd.skilltype.setVisible(false);
        --wnd.skillstat.setVisible(false);
        --wnd.max.setVisible(false);
        
        skillstat.setFrame(nil);
		skillstat.setStateFrame("hover", nil);
		skillstat.setReadOnly(true);
        skilltype.setFrame(nil);
        skilltype.setStateFrame("hover", nil);
		skilltype.setReadOnly(true);        
        
        local parentmax=DB.findNode(parentskill.getValue()..".max").getValue();        
        max.setValue(parentmax);        
    end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local node = getDatabaseNode();
		if node then
			node.delete();
		else
			close();
		end
	end
    
    if selection == 2 then
		local wnd = self.windowlist.addEntry(true);
			if wnd then
				wnd.label.setValue(self.label.getValue().." subskill");
                wnd.parentskill.setValue(self.getDatabaseNode().getNodeName());
                self.subskillnumber.setValue(self.subskillnumber.getValue()+1);
                self.updateSubStatus();
                --print(self.getDatabaseNode().getNodeName());
                wnd.order.setValue(self.order.getValue());
                wnd.skillstat.setStringValue(self.skillstat.getValue());
                wnd.skilltype.setStringValue(self.skilltype.getValue());
                wnd.updateSubStatus();
			end
	end
    
end

function onStatUpdate()	
    local stat=string.lower(skillstat.getStringValue());
    if stat=="" then    
        total.setValue(rank.getValue());
    else        
        local node = self.windowlist.window.getDatabaseNode().createChild("stats").createChild(stat).createChild("score");
        total.setValue(node.getValue()+rank.getValue());        
    end
	updateSubStatus()                                                            
end

-- This next function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.

function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);
		
        skillstat.setFrame("bonus",5,5,5,5);
		skillstat.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
		skillstat.setReadOnly(false);
        skilltype.setFrame("bonus",5,5,5,5);
        skilltype.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
        skilltype.setReadOnly(false);
	else
		label.setEnabled(false);
		label.setLine(false);
		
        skillstat.setFrame(nil);
		skillstat.setStateFrame("hover", nil);
		skillstat.setReadOnly(true);
        skilltype.setFrame(nil);
        skilltype.setStateFrame("hover", nil);
		skilltype.setReadOnly(true);
	end
	
	setRadialOptions();
end

function setHasSubSkills(state)

    
    rank.setVisible(not state);
    total.setVisible(not state);
    max.setVisible(not state);
    
    hasSubSkills=state;
    setRadialOptions();
end

function setRadialOptions()
	resetMenuItems();

	if iscustom then
		registerMenuItem("Delete", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	end
    if hasSubSkills then
        registerMenuItem("Add Subskill", "insert", 2);		
    end
end

