-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--




function reset()
	
	if isDone() then
		if isCleared==false then
			isCleared=true;
			clearSkillRanks();	
		end
		
		applySelection();
		
		repeat
			currentcareer=currentcareer+1;
		until  (career[currentcareer]~="" and career[currentcareer]~=nil ) or currentcareer>2
		
		setSkillsWindow();
	end
	
	if currentcareer>2 then		
		parentcontrol.setVisible(false);
		isCleared=false;
	end
	
end

currentcareer=0;
career={};
skills={};
abilities={}
skilldropdowns={};
abilitydropdowns={};
careerlabel=nil;
careerskillheader=nil;
careerabilityheader=nil;
isCleared=false;

function clearCharacter()
	clear();
	--clearSkillRanks();	
	--applySelection();
	
	local skillsWindow=parentcontrol.window;
	career[1]=skillsWindow.career1.getValue();
	career[2]=skillsWindow.career2.getValue();
	
	currentcareer=0;
	
	
	while  (career[currentcareer]=="" or career[currentcareer]==nil) and currentcareer<3 do		
		currentcareer=currentcareer+1;		
		setSkillsWindow();
	end
	
	if skillsWindow.career1.getValue()=="" and
		skillsWindow.career2.getValue()=="" and
		skillsWindow.career3.getValue()=="" and
		skillsWindow.career4.getValue()=="" and
		skillsWindow.career5.getValue()=="" then
			clearSkillRanks();	
			applySelection();
	end
	
end

function clear()
	
	for i,v in pairs(skilldropdowns) do
		v.destroyList();
		v.destroy();		
		skilldropdowns[i]=nil;
	end
	
	for i,v in pairs(skills) do		
			v.destroy();		
			skills[i]=nil;				
	end
	
	for i,v in pairs(abilitydropdowns) do	
		v.destroyList();
		v.destroy();		
		abilitydropdowns[i]=nil;
	end
	
	for i,v in pairs(abilities) do		
		v.destroy();		
		abilities[i]=nil;
	end
		
	
end


function isDone()
	local result=true;
	
	for i,v in pairs(skills) do		
			if v.getValue()=="Choose" then
				result=false;
			end
	end
	
	for i,v in pairs(abilities) do		
			if v.getValue()=="Choose" then
				result=false;
			end
	end
	
	return result;
end

function applySelection()
	local skillsList=parentcontrol.window.parentcontrol.window.skills.subwindow.skilllist;
	
	for key,skillwindow in pairs(skillsList.getWindows()) do
		--skillwindow.rank.setValue(0);
		
		for index,selectedskill in pairs(skills) do
			
			local selname = string.gsub(selectedskill.getValue(),": %d","");
			
			local subskill = string.match(selname,"%b()");
			
			
			if(subskill) then
				--subskill=string.gsub(subskill,"%(","");
				--subskill=string.gsub(subskill,"%)","");
				subskill=trim(subskill);
				
				--print ("subskill: "..subskill);
			end
			
			selname = string.gsub(selname,"%b()","");
			selname=trim(selname);
			
			--print ("selskill: "..selname);			
			if(skillwindow.label.getValue()==selname) then
				
				if subskill then
				
					if skillwindow.windowlist.skillList[subskill] then
						wnd=skillwindow.windowlist.skillList[subskill];
						wnd.rank.setValue(wnd.rank.getValue()+1);
					else
						wnd=skillwindow.addSubSkill(subskill);
						wnd.rank.setValue(wnd.rank.getValue()+1);
					end
										
				else								
					skillwindow.rank.setValue(skillwindow.rank.getValue()+1);
				end
				
			end
			
		end
		
	end
	
	
	local abilityList=parentcontrol.window.abilitylist;
	local race=parentcontrol.window.parentcontrol.window.main.subwindow.race.getValue();
	local archetype=parentcontrol.window.archetype.getValue();
	
	if career[currentcareer]~=nil then
	--print ("index: "..currentcareer.." career: "..career[currentcareer]);
	for key,abilitywindow in pairs(abilityList.getWindows()) do						
		for ability,subability in pairs(DataCommon.careers[career[currentcareer]].abilities) do				
			if abilitywindow.label.getValue()==ability and subability~=0 then 
				for k,v in pairs(subability) do
					local subabilitywindow = abilitywindow.addSubAbility(ability.." ("..k..")");
				end
			end						
		end
	end
	end
	
	for key,abilitywindow in pairs(abilityList.getWindows()) do
		
		
		
		for index,selectedability in pairs(abilities) do			
			--local selname = trim(string.gsub(selectedability.getValue(),"%b()",""));		
			local selname = selectedability.getValue();		
				--print("career: "..selname);
			--print("Tested ability: "..abilitywindow.label.getValue());
			--print("Selected ability: "..selname);
			--print();
			if(abilitywindow.label.getValue()==selname) then			
				
				--print(selname..":");
				--local abilitysubtypes=DataCommon.careers[career[currentcareer]].abilities[selname];
				
				--if abilitysubtypes==0 then
				--print("subtype:");
				--print(abilitysubtypes);
				abilitywindow.aquired.setState(true);
				
								
					
				--elseif abilitysubtypes~=nil then
				--	for subtype,info in pairs(abilitysubtypes) do
				--		local subability = abilitywindow.addSubAbility(selname.." ("..subtype..")");
				--		if DataCommon.careers[career[currentcareer]].startingabilities[selname][subtype] then
				--			subability.aquired.setState(true);
				--		end
				--	end
				--end
				
			end
		end
		
		if race~="" then
			for selectedability,info in pairs(DataCommon.racedata[race].Abilities) do	
				local selname = selectedability;			
				--print("race: "..selname);
				if(abilitywindow.label.getValue()==selname) then				
					abilitywindow.aquired.setState(true);
				end
			end
		end
		
		--print(archetype);
		if(abilitywindow.label.getValue()==archetype) then
			abilitywindow.aquired.setState(true);
		end
		
	end
	
	
	
end

function clearSkillRanks()
	local skillsList=parentcontrol.window.parentcontrol.window.skills.subwindow.skilllist;
	
	for key,skillwindow in pairs(skillsList.getWindows()) do
		skillwindow.rank.setValue(0);
		if skillwindow.parentskill.getValue()~="" then
			skillwindow.delete();
		end
	end
	
	
	
	local abilityList=parentcontrol.window.abilitylist;
	for key,abilitywindow in pairs(abilityList.getWindows()) do
		abilitywindow.aquired.setState(false);
		if DataCommon.abilitydata[abilitywindow.label.getValue()] then
			abilitywindow.order.setValue(DataCommon.abilitydata[abilitywindow.label.getValue()].order);
		end
		if abilitywindow.parentability.getValue()~="" then
			abilitywindow.delete();
		end
	end
	
end



function setSkillsWindow()
	
	if career[currentcareer]==""  or career[currentcareer]==nil then 	
		--parentcontrol.setVisible(false);
		return;
	end;
	
		
	if not careerlabel then
		careerlabel=createControl("stringcontrol_dynamic","title_career");
	end
	
	if careerlabel then				
		careerlabel.setAnchoredHeight(20);		
		careerlabel.setAnchor("left","","left","absolute",15);
		careerlabel.setAnchor("right","","right","absolute",-15);
		careerlabel.setAnchor("top","","top","absolute",15);				
		careerlabel.setReadOnly(true);
		careerlabel.setFont("sheetlabel");
		careerlabel.setValue(career[currentcareer]);		
		careerlabel.setBackColor("FF000000");
		careerlabel.setColor("FFFFFFFF");
	end
	
	if not careerskillheader then
		careerskillheader=createControl("stringcontrol_dynamic","skillheader_career");
	end
	
	if careerskillheader then				
		careerskillheader.setAnchoredHeight(20);
		careerskillheader.setAnchoredWidth(120);
		careerskillheader.setAnchor("left","title_career","left","absolute",0);
		careerskillheader.setAnchor("top","title_career","bottom","absolute",5);				
		careerskillheader.setReadOnly(true);
		careerskillheader.setFont("sheetlabel");
		careerskillheader.setValue("Skills");		
		careerskillheader.setUnderline(true,1);
	end
	
	if not careerabilityheader then
		careerabilityheader=createControl("stringcontrol_dynamic","abilityheader_career");
	end
	
	if careerabilityheader then				
		careerabilityheader.setAnchoredHeight(20);
		careerabilityheader.setAnchoredWidth(120);
		careerabilityheader.setAnchor("left","skillheader_career","right","absolute",5);
		careerabilityheader.setAnchor("top","title_career","bottom","absolute",5);				
		careerabilityheader.setReadOnly(true);
		careerabilityheader.setFont("sheetlabel");
		careerabilityheader.setValue("Abilities");		
		careerabilityheader.setUnderline(true,1);
	end
	
	clear();
	
	-- ###############################################STARTING SKILLS#########################################################################################################
	
	
	
	local count=1;
	
	--print("career: "..currentcareer);
	--print("career: "..career[currentcareer]);
	--print("");
	--if(isDone())then print("done"); else print ("not done"); end
	
	for k,v in pairs(DataCommon.careers[career[currentcareer]].startingskills) do
		if(type(v)=="table") then
			--print("Type: "..type(k).." Key: "..k);
			labels="";
			values="";
			numchoices=0
			

			
			
			skills[count]=createControl("stringcontrol_dynamic","skill_"..count);			
			skills[count].setAnchor("left","skillheader_career","left","absolute",5);
			skills[count].setAnchor("top","skillheader_career","bottom","absolute",20*(count-1));		
			skills[count].setAnchoredHeight(20);		
			skills[count].setAnchoredWidth(100);		
			skills[count].setFont("sheetlabelsmall");
			skills[count].setValue("Choose");
			skills[count].setReadOnly(true);		
			skills[count].setFrame("modifier",7,7,5,2);
			
			skilldropdowns[count]=createControl("DropDown","skill_"..count.."_dropdown");
			skilldropdowns[count].position[1]="0,2";
			skilldropdowns[count].target[1]="skill_"..count;
			
			skilldropdowns[count].setVisible(true);
			
			for skill,level in pairs(v) do			
				skilldropdowns[count].add(skill..": "..level);
			end
			
			skilldropdowns[count].onInit();
		else
			skills[count]=createControl("stringcontrol_dynamic","skill_"..count);
			skills[count].setAnchor("left","skillheader_career","left","absolute",5);
			skills[count].setAnchor("top","skillheader_career","bottom","absolute",20*(count-1));		
			skills[count].setAnchoredHeight(20);		
			skills[count].setFont("sheetlabelsmall");
			skills[count].setValue(k..": "..v);
			skills[count].setReadOnly(true);					
		end
		count=count+1;
	end
	
	
	
	
	
	-- ###############################################STARTING ABILITIES#########################################################################################################
	
	
	
	local count=1;
	
	for k,v in pairs(DataCommon.careers[career[currentcareer]].startingabilities) do
		if(type(v)=="table" and type(k)=="number") then
			
			labels="";
			values="";
			numchoices=0
			

			
			
			abilities[count]=createControl("stringcontrol_dynamic","ability_"..count);			
			abilities[count].setAnchor("left","abilityheader_career","left","absolute",5);
			abilities[count].setAnchor("top","abilityheader_career","bottom","absolute",20*(count-1));		
			abilities[count].setAnchoredHeight(20);		
			abilities[count].setAnchoredWidth(100);		
			abilities[count].setFont("sheetlabelsmall");
			abilities[count].setValue("Choose");
			abilities[count].setReadOnly(true);		
			abilities[count].setFrame("modifier",7,7,5,2);
			
			
			abilitydropdowns[count]=createControl("DropDown","ability_"..count.."_dropdown");
			abilitydropdowns[count].position[1]="0,2";
			abilitydropdowns[count].target[1]="ability_"..count;
			
			abilitydropdowns[count].setVisible(true);
			
			for ability,info in pairs(v) do					
				if(info~=0) then
				abilitydropdowns[count].add(ability.."  ("..info..")");
				else
					abilitydropdowns[count].add(k.." ("..ability..")");
				end
			end
			
			abilitydropdowns[count].onInit();
		else
			abilities[count]=createControl("stringcontrol_dynamic","ability_"..count);
			abilities[count].setAnchor("left","abilityheader_career","left","absolute",5);
			abilities[count].setAnchor("top","abilityheader_career","bottom","absolute",20*(count-1));		
			abilities[count].setAnchoredHeight(20);		
			abilities[count].setFont("sheetlabelsmall");
			if(v~=0) then
				--abilities[count].setValue(k.." ("..v..")");
				for ability,info in pairs(v) do	
					abilities[count].setValue(k.." ("..ability..")");
				end
			else
				abilities[count].setValue(k);
			end
			abilities[count].setReadOnly(true);					
		end
		count=count+1;
	end
	
	closeButton=createControl("close_startingwindow","closeButton");		
	parentcontrol.setVisible(true);
	
	
end

function setCleared(value)
	isCleared=value;
end

function setContains(set, key)
    return set[key] ~= nil
end

function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

