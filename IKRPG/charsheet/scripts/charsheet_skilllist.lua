-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



function onInit()
	registerMenuItem("Create", "insert", 5);
	

	constructSkillList();

	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getNodeName();
	DB.addHandler(sChar ..  ".stats", "onChildUpdate", onStatUpdate);
	DB.addHandler(sChar .. ".skilllist.*.skillstat", "onUpdate", onStatUpdate);
    DB.addHandler(sChar .. ".skilllist.*.rank", "onUpdate", onStatUpdate);    
    applyFilter();		
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end

function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	win.setCustom(true);
    win.order.setValue(-1);
	if bFocus and win then
        
		win.label.setFocus();
	end
	return win;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

skillList={};


function constructSkillList()

	for skillname,skillinfo in pairs(DataCommon.skilldata) do
		skillList[skillname]=addSkill(skillname);
	end
	
	for k,v in pairs(getWindows()) do
		name=v.label.getValue();
		if not skillList[name] then
			skillList[name]=v;
		end
	end

end

function addSkill(name)
	local node = getDatabaseNode().getChild(name);
    local win = nil;
    if not node then
        --node = getDatabaseNode().createChild(name);
		win = NodeManager.createWindow(self,getDatabaseNode().getNodeName().."."..name);
		win.setCustom(false);
    else	
		for i,w in ipairs(getWindows()) do
			if w.label.getValue()==name then
				win = w;
				win.setCustom(false);
			end
		end
	end
	
    if win then
		skillinfo=DataCommon.skilldata[name];
        win.label.setValue(name);
        win.order.setValue(skillinfo.order);
		win.skilltype.setStringValue(skillinfo.type);
		win.setHasSubSkills(skillinfo.multiskill);
        win.max.setReadOnly(false);
        --if skillinfo.stat then
			if type(skillinfo.stat)=='table' then 
				win.skillstat.initializeWithTables(skillinfo.stat, skillinfo.stat, " - ");                        
				win.skillstat.update();
				win.skillstat.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
				win.skillstat.setFrame("bonus",5,5,5,5);
				win.skillstat.setReadOnly(false);
			else
				win.skillstat.setStringValue(skillinfo.stat); 
				win.skillstat.setReadOnly(true);
			end
		--end
		
					
    end
    return win;
end


function setContains(set, key)
    return set[key] ~= nil
end

function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function onFilter( w ) 
    
    --local careers=StringManager.split(w.windowlist.window.getDatabaseNode().getChild("careers").getValue(),",");
	local careers={
	w.windowlist.window.getDatabaseNode().getChild("career1").getValue(),
	w.windowlist.window.getDatabaseNode().getChild("career2").getValue(),
	w.windowlist.window.getDatabaseNode().getChild("career3").getValue(),
	w.windowlist.window.getDatabaseNode().getChild("career4").getValue(),
	w.windowlist.window.getDatabaseNode().getChild("career5").getValue()
	};
	
    local inList=false;
    local biggestValue=0;
	local biggestGeneralMax=0	;
   
   if DataCommon.skilldata[w.label.getValue()]==nil then
		inList=true
	end
	
	if w.subskillnumber.getValue()>0 then
		inList=true;
	end
	
    for i,nextcareer in ipairs(careers) do
        nextcareer=trim(nextcareer);
        
        
        
        if DataCommon.careers[nextcareer]~= nil then
           
            
            
            if DataCommon.careers[nextcareer].skills[w.label.getValue()]~=nil then
                inList=true;
                if DataCommon.careers[nextcareer].skills[w.label.getValue()]>biggestValue then
                    biggestValue=DataCommon.careers[nextcareer].skills[w.label.getValue()];
                end
            end
			
			if(DataCommon.careers[nextcareer].skills["General Skills"]>biggestGeneralMax) then
				biggestGeneralMax=DataCommon.careers[nextcareer].skills["General Skills"];
			end
						
			
        end
    end
    
	if DataCommon.generalskills[w.label.getValue()]~=nil then
		inList=true;
		if(biggestGeneralMax>biggestValue) then
			biggestValue=biggestGeneralMax;
		end
	end
			
			
    if w.parentskill.getValue() ~= "" then inList = true; end
	
	if w.rank.getValue()>0 then inList=true; end
	
	--if w.windowlist.window.getDatabaseNode().getChild("careers").getValue()=="" then                
	--Display all skills when no career is selected
	--[[
	if careers[1]=="" and careers[2]=="" and careers[3]=="" and careers[4]=="" and careers[5]=="" then                
        inList=true;
	end
	
	if DataCommon.skilldata[w.label.getValue()]==nil then
		inList=true
	end
	]]--
	
	
		
		
	if w.windowlist.window.getDatabaseNode().getChild("limitbyLevel").getValue() then
		
		local levelLimit=4;
		local level=w.windowlist.window.getDatabaseNode().getChild("level").getValue();		
		if level=="Epic" then levelLimit=4; end
		if level=="Veteran" then levelLimit=3; end
		if level=="Heroic" then levelLimit=2; end
		
		if biggestValue>levelLimit then
			biggestValue=levelLimit;
		end
	end
	
    if biggestValue>0 then        
        w.max.setValue(biggestValue);
    end
	
	if w.windowlist.window.getDatabaseNode().getChild("showAll").getValue() then
		inList=true; 
	end
	
    return inList;
    
    
end


