-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;
hasSubSkills=false;

sets = {};

function onInit()	
    updateSubStatus();
	onStatUpdate();    
end

function updateSubStatus()
    if parentskill.getValue()=="" then
    else
        setCustom(true);
        label.setAnchor("left", "", "left","absolute",10);
        label.setAnchor("top", "", "top","absolute",5);
        label.setAnchoredWidth(85);
       
        skillstat.setFrame(nil);
		skillstat.setStateFrame("hover", nil);
		skillstat.setReadOnly(true);
        skilltype.setFrame(nil);
        skilltype.setStateFrame("hover", nil);
		skilltype.setReadOnly(true);
       
        
    end
    
    skillinfo=DataCommon.skilldata[label.getValue()];
    if skillinfo then
        setCustom(false);
        if type(skillinfo.stat)=='table' then 
            skillstat.initializeWithTables(skillinfo.stat, skillinfo.stat, " - ");                        
            skillstat.update();
            skillstat.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
            skillstat.setFrame("bonus",5,5,5,5);
            skillstat.setReadOnly(false);
        else
            skillstat.setStringValue(skillinfo.stat); 
            skillstat.setReadOnly(true);
        end
        
        if skillinfo.multiskill then
            setHasSubSkills(true);
        end
    end
    
   
end



function onStatUpdate()	
    local stat=string.lower(skillstat.getStringValue());
    if stat=="" then    
        total.setValue(rank.getValue());
    else        
        local node = self.windowlist.window.getDatabaseNode().getChild("stats").getChild(stat).getChild("score");
        total.setValue(node.getValue()+rank.getValue());        
    end	
end

-- This function is called to set the entry to non-custom or custom.
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
	
	
end

function setHasSubSkills(state)

    
    rank.setVisible(not state);
    total.setVisible(not state);
    
    hasSubSkills=state;    
end


