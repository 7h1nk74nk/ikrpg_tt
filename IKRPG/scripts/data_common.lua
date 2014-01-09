-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Abilities (database names)
abilities = {
	"physique",
	"strength",
	"speed",
	"agility",
	"prowess",
	"poise",
	"intellect",
	"arcane",
	"perception",
	"willpower"
};

ability_ltos = {
	["physique"] = "phy",
	["strength"] = "str",
	["speed"] = "spe",
	["agility"] = "agi",
	["prowess"] = "pro",
	["poise"] = "poi",
	["intellect"] = "int",
	["arcane"] = "arc",
	["perception"] = "per",
	["willpower"] = "wil"
};

ability_stol = {
	["phy"] = "physique",
	["str"] = "strength",
	["spe"] = "speed",
	["agi"] = "agility",
	["pro"] = "prowess",
	["poi"] = "poise",
	["int"] = "intellect",
	["arc"] = "arcane",
	["per"] = "perception",
	["wil"] = "willpower"
};

-- Ruleset action types
actions = {
	"table",
	"attack",
	"dice",
	"damage",
	"heal",
	"effect",
	"skill",
	"init",
	"save",
	"ability",
	"autosave",
	"recharge"
};

targetactions = {
	"attack",
	"damage",
	"effect"
};

moddropactions = {
	"attack",
	"damage",
	"skill",
	"init",
	"ability"
};

-- Conditions supported in power descriptions and effect conditionals
-- NOTE: Skipped concealment and cover since there are too many false positives in power descriptions
conditions = {
	"blinded", 
	"dazed", 
	"deafened", 
	"dominated", 
	"grabbed", 
	"immobilized", 
	"insubstantial", 
	"invisible", 
	"marked", 
	"petrified", 
	"phasing",
	"prone", 
	"restrained", 
	"slowed", 
	"stunned", 
	"swallowed", 
	"unconscious", 
	"weakened"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"DEF",
	"ARM",
	"WILL",
	"ATK",
	"DMG",
	"SKILL"
};

-- Condition effect types for token widgets
condcomps = {
	["blinded"] = "cond_blinded",
	["dazed"] = "cond_dazed",
	["deafened"] = "cond_deafened",
	["dominated"] = "cond_dominated",
	["grabbed"] = "cond_grabbed",
	["helpless"] = "cond_helpless",
	["immobilized"] = "cond_immobilized",
	["insubstantial"] = "cond_insubstantial",
	["invisible"] = "cond_invisible",
	["marked"] = "cond_marked",
	["petrified"] = "cond_petrified",
	["prone"] = "cond_prone",
	["restrained"] = "cond_restrained",
	["slowed"] = "cond_slowed",
	["stunned"] = "cond_stunned",
	["surprised"] = "cond_surprised",
	["unconscious"] = "cond_unconscious",
	["weakened"] = "cond_weakened"
};

-- Other visible effect types for token widgets
othercomps = {
	["CONC"] = "cond_conceal",
	["TCONC"] = "cond_conceal",
	["COVER"] = "cond_cover",
	["SCOVER"] = "cond_cover",
	["IMMUNE"] = "cond_immune",
	["RESIST"] = "cond_resist",
	["VULN"] = "cond_vuln",
	["REGEN"] = "cond_regen",
	["DMGO"] = "cond_ongoing",
	["SWARM"] = "cond_swarm"
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"CONC",
	"TCONC",
	"COVER",
	"SCOVER",
	"DEF",
	"Arm",
	"WILL",
	"ATK",
	"DMG",
	"IMMUNE",
	"VULN",
	"RESIST"
};

-- Range types supported in power descriptions
rangetypes = {
	"melee",
	"ranged",
	"close",
	"area"
};

-- Damage types supported in power descriptions
dmgtypes = {
	"acid",
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"poison",
};

-- Bonus types supported in power descriptions
bonustypes = {
	"racial",
	"power",
	"feat",
	"shield",
	"item",
	"proficiency",
	"enhancement"
};

-- Immunity types supported which are not energy types
immunetypes = {
	"charm",
	"disease",
	"fear",
	"gaze",
	"illusion",
	"petrification",
	"prone",
	"push",
	"pull",
	"sleep",
	"slide"
};

-- Skills supported in power descriptions
skills = {
	"archery",
	"crossbow",
	"great weapon",
	"hand weapon",
	"lance",
	"light artillery",
	"pistol",
	"rifle",
	"shield",
	"thrown weapon",
	"unarmed combat",
	"alchemy",
	"bribery",
	"command",
	"craft",
	"cryptography",
	"deception",
    "disguise",
    "escape artist",
    "etiquette",
    "fell calling",
    "forensic science",
    "forgery",
    "interrogation",
    "law",
    "lock picking",
    "mechanikal engineering",
    "medicine",
    "navigation",
    "negotiation",
    "oratory",
    "pickpocket",
    "research",
    "rope use",
    "sailing",
    "seduction",
    "sneak",
    "streetwise",
    "survival",
    "tracking",
    "animal handling",
    "climbing",
    "detection",
    "driving",
    "gambling",
    "intimidation",
    "jumping",
    "lore",
    "riding",
    "swimming"
};

-- Skill properties
skilldata = {

    ["Archery"]={ type="Mil.", stat="POI" ,order=0},
	["Crossbow"]={ type="Mil.", stat="POI" ,order=1},
	["Great Weapon"]={ type="Mil.", stat="PRW" ,order=2},
	["Hand Weapon"]={ type="Mil.", stat="PRW" ,order=3},
	["Lance"]={ type="Mil.", stat="PRW" ,order=4},
	["Light Artillery"]={ type="Mil.", stat="POI" ,order=5},
	["Pistol"]={ type="Mil.", stat="POI" ,order=5},
	["Rifle"]={ type="Mil.", stat="POI" ,order=6},
	["Shield"]={ type="Mil.", stat="PRW" ,order=7},
	["Thrown Weapon"]={ type="Mil.", stat="PRW" ,order=8},
	["Unarmed Combat"]={ type="Mil.", stat="PRW" ,order=9},
	["Alchemy"]={ type="Occ.", stat="PRW" ,order=10},
	["Bribery"]={ type="Occ.", stat="" ,order=11},
	["Command"]={ type="Occ.", stat="" ,order=12},
	["Craft"]={ type="Occ.", stat="INT", multiskill=true, order=13},
	["Cryptography"]={ type="Occ.", stat="INT" ,order=14},
	["Deception"]={ type="Occ.", stat="" ,order=15},
    ["Disguise"]={ type="Occ.", stat="INT" ,order=16},
    ["Escape Artist"]={ type="Occ.", stat="AGI" ,order=17},
    ["Etiquette"]={ type="Occ." , stat="" ,order=18},
    ["Fell Calling"]={ type="Occ.", stat="POI" ,order=19},
    ["Forensic Science"]={ type="Occ.", stat="INT" ,order=20},
    ["Forgery"]={ type="Occ.", stat={"INT","AGI"} ,order=21},
    ["Interrogation"]={ type="Occ.", stat="INT" ,order=22},
    ["Law"]={ type="Occ.", stat="INT" ,order=23},
    ["Lock Picking"]={ type="Occ.", stat="AGI" ,order=24},
    ["Mechanikal Eng"]={ type="Occ.", stat="INT" ,order=25},
    ["Medicine"]={ type="Occ.", stat="INT" ,order=26},
    ["Navigation"]={ type="Occ.", stat="PER" ,order=27},
    ["Negotiation"]={ type="Occ.", stat="" ,order=28},
    ["Oratory"]={ type="Occ.", stat="" ,order=29},
    ["Pickpocket"]={ type="Occ.", stat="AGI" ,order=30},
    ["Research"]={ type="Occ.", stat="INT" ,order=31},
    ["Rope Use"]={ type="Occ.", stat="AGI" ,order=32},
    ["Sailing"]={ type="Occ.", stat={"INT","STR"} ,order=33},
    ["Seduction"]={ type="Occ.", stat="" ,order=34},
    ["Sneak"]={ type="Occ.", stat="AGI" ,order=35},
    ["Streetwise"]={ type="Occ.", stat="PER" ,order=36},
    ["Survival"]={ type="Occ.", stat="PER" ,order=37},
    ["Tracking"]={ type="Occ.", stat="PER" ,order=38},
    ["Animal Handling"]={ type="Gen.", stat="" ,order=39},
    ["Climbing"]={ type="Gen.", stat="AGI" ,order=40},
    ["Detection"]={ type="Gen.", stat="PER" ,order=41},
    ["Driving"]={ type="Gen.", stat="AGI" ,order=42},
    ["Gambling"]={ type="Gen.", stat="PER" ,order=43},
    ["Intimidation"]={ type="Gen.", stat="" ,order=44},
    ["Jumping"]={ type="Gen.", stat="PHY" ,order=45},
    ["Lore"]={ type="Gen.", stat="INT", multiskill=true ,order=46},
    ["Riding"]={ type="Gen.", stat="AGI" ,order=47},
    ["Swimming"]={ type="Gen.", stat="STR" ,order=48}
    
    
	
};

abilitydata = {
    
	
    ["Gifted"] = { order=0, type="Gifted", prereq="", desc="A character with the Gifted archetype starts with a tradition(p. 228). If the character begins the game with the warcaster career, he is a focuser; otherwise, he is a will weaver. Choosing the Gifted archetype is the only way for a character to have an ARC stat. If the character is a focuser, he starts the game with ARC 2. Will weavers start the game with ARC 3", shortdesc="Get ARC 3 or ARC 2", starting=true},
    ["Additional Study"] = { order=1, type="Gifted", prereq="", desc="The character delves further into the mysteries of the arcane and is rewarded with a spell from one of his career spell lists- This benefit can be taken multiple times, but a character still cannot exceed twice his INT in spells known.", shortdesc="+1 spell", multiability=true },
    ["Combat Caster"] = { order=2, type="Gifted", prereq="", desc="When this character makes a magic attack roll, he gains an additional die. Discard the lowest die of each roll.", shortdesc="+1 die on magic attacks, discard lowest" },
    ["Fast Caster"] = { order=3, type="Gifted", prereq="", desc="The character gains one extra quick action each activation that can be used only to cast a spell.", shortdesc="+1 quicj action/activation for spellcasting." },
    ["Feat: Dominator"] = { order=4, type="Gifted", prereq="", desc="The character can spend 1 feat point during his turn to double his control area for 1 turn.", shortdesc="Spend 1 feat point to double control area for 1 turn" },
    ["Feat: Powerfull Caster"] = { order=5, type="Gifted", prereq="", desc="The character can spend 1 feat point when he casts a spell to increase the RNG(range) of the spell by twelve feet(2 inches). Spells with a range of CTRL(control area) or SP(spray attack) are not affected.", shortdesc="Spend 1 feat point to increase targeted spell range by 2" },
    ["Feat: Quick Cast"] = { order=6, type="Gifted", prereq="", desc="The character can spend 1 feat point to immediatly cast one upkeep spell at the start of combat before the first round. When casting a spell as a result of this benefit, the character is not required to pay the COST of the spell,", shortdesc="Spend 1 feat point to immediatly cast an upkepp spell before combat for free"},
    ["Feat: Strength of Will"] = { order=7, type="Gifted", prereq="", desc="After failing a fatigue roll, the character can spend 1 feat point to instead automatically suceed on the roll. This benefit can only be taken by characters with the will weaver tradition.", shortdesc="Spend 1 feat point to automatically succeed a failed fatigue roll" },
    ["Magic Sensivity"] = { order=8, type="Gifted", prereq="", desc="The character can automatically sense when an another character casts a spell within fifty feet for each point of his ARC stat. Such characters can tune out this detection as background noise but are aware of particularly powerful magic. Additionally, a character with the focuser tradition can sense other focusers within their detection range.", shortdesc="Sense magic within ARC*50 feet" },
    ["Rune Reader"] = { order = 9, type="Gifted", prereq="", desc="The character can identify any spell cast in his line of sight by reading the accompanying spell runes(see the 'Runes and Formulae' sidebar, p. 228). He can also learn the type of magic cast(the spell list it came from) and the tradition of the character casting the spell.", shortdesc="Identify spells cast in line of sight"},
    ["Warding Circle"] = {order = 10, type="Gifted", prereq="", desc="The character can spend fifteen minutes to create a circle of warding runes around a small room or campsite. The names of the characters he intends to keep safe within the circle are incorporated into the runes. When any other character enters the circle, all named characters are alerted. While in the circle, non-named characters lose incorporeal, and non-named undead nad infernal characters suffer -2 on attack rolls.", shortdesc="15 minutes to create circle. Alerts, cancels incorporeal and gives infernals and undead -2 to attack"},
    
    ["Intellectual"] = {order = 11, type="Intellectual", prereq="", desc="Intellectual characters possess a tactical genius and adaptability that gives them +1 on attack and damage rolls in combat. While in the command range of an Intellectual character, a friendly character listening to his orders also gains +1 on his attack and damage rolls. This bonus is non-cumulative, so a character can gain this bonus only from one intellectual character at a time.", shortdesc="+1 attack and damage in command range", starting=true},
    ["Battlefield Coordination"] = {order = 12, type="Intellectual", prereq="", desc="The character is a skilled battlefield commander. He is able to coordiante the movement and attacks of friendly forces to maximum effect. While in his command range, friendly characters do not suffer the firing into melee penalty for ranged attacks and spells and do not have a chance to hit friendly characters when they miss with ranged or magic attacks while firing into melee.", shortdesc="No friendly fire and firing into melee penalty in command range" },
    ["Feat: Flawless Timing"] = {order=13, type="Intellectual", prereq="", desc="The character can spend 1 feat point to use this benefit during his turn. When he uses Flawless Timing, the character names an enemy. The next time that enemy directly hits him with an attack that encounter, the attack is instead considered to be a miss.", shortdesc="Next hit from named enemy is a miss instead" },
    ["Feat: Prescient"] = {order=14, type="Intellectual", prereq="", desc="The character can spend 1 feat point to win initiative autoamtically and take the first turn that combat. If two or more characters use this ability, they make initiative rolls to determine wich of them goes first.", shortdesc="Spend 1 feat point to automatically win initiative at the start of combat"},
    ["Feat: Perfect Plot"] = {order=15, type="Intellectual", prereq="", desc="The character is a flawless planer and allows nothing to escape his attention. Assuming he is able to oversee all aspects of his plan, scout out the related sites, and do his research in great detail, he is sure to suceed. Of course this degree of planning takes time and care, but perfection is not without its cost. The character must spend 1 feat point to use this ability. A character following this character's plan gains an additional die on non-combat related rolls during the day in wich the plan was enacted.", shortdesc="Spend 1 feat point and make a plan, characters following the plan gain +1 die on non-combat rolls that day"},
    ["Feat: Plan of Action"] = {order=16, type="Intellectual", prereq="", desc="At the start of combat, the character can spend 1 feat point to use this benefit. During that combat, he and friendly characters who follow his plan gain +2 to their initiative rolls and +2 to their attack rolls during the first round of combat.", shortdesc="Spend 1 feat point, the character and his allies gain +2 initiative and attack in the first round"},
    ["Feat: Quick Thinking"] = {order=17, type="Intellectual", prereq="", desc="The character's quick thinking enables him to act impossibly fast. Once per round the character can spend 1 feat point to make one attack or quick action at the start of another character's turn.", shortdesc="Spend 1 feat point to make 1 attack or quick action at the start of another character's turn"},
    ["Feat: Unconventional Warfare"] = { order=18, type="Intellectual", prereq="", desc="The character is quick thinking enough to assess any situation, see every potential angle and outcome, and use the enviroment itself as a weapon. He can use his attacks to off-balance foes and send them careening off ledges or into nearby vats of molten metal, cause them to stumble over terrain features, hit their weak spots to knock them to the ground, or otherwise maneuver them into a position of weakness and jeopardy. The character must spend 1 feat point to use this ability and explain to the Game Master how he is turning the enbiroment against his enemy. The Game Master then determines the likely effect the character's action or attack. Outcomes include a boosted damage roll(see p. 197), kockdown, push, slam, or a fall from a height.", shortdesc="Spend 1 feat point to get an additional effect for the attack ie: boosted damage, knockdown, push, slam or falling"},
    ["Genius"]={order=19, type="Intellectual", prereq="", desc="The character possesses an incredible aptitude for intellectual pursuits. The character's INT rolls are boosted.", shortdesc="INT rolls are boosted"},
    ["Hyper Perception"] = {order=20, type="Intellectual", prereq="", desc="The character's keen senses miss few details. The character's PER rolls are boosted.", shortdesc="PER rolls are boosted"},
    ["Photographic Memory"] = {order=21, type="Intellectual", prereq="", desc="The character has a photographic memory and can recall every event in perfect detail. During play he can call upon his memory to ask the Game Master questions portaining anything he has seen or experienced.", shortdesc="Character has photographic memory"},
    
    ["Mighty"] = {order=22, type="Mighty", prereq="", desc="Mighty characters gain an additional die on their melee damage rolls.", shortdesc="+1 die on melee damage rolls", starting=true},
    ["Beat Back"] ={order=23, type="Mighty", prereq="", desc="When this character hits a target with a melee attack, he can immediatly push his target 1 inch directly away. After the target is pushed, this character can advance up to 1 inch.", shortdesc="Push target 1 inch and advance 1" },
    ["Feat: Back Swing"] = { order=24, type="Mighty", prereq="", desc="Once per turn, this character can spend 1 feat point to gain one additional melee attack.", shortdesc="Spend 1 feat point to gain +1 melee attack" },
    ["Feat: Bounding Leap"] ={order=25, type="Mighty", prereq="", desc="The character is capable of preternatural feats of athleticism. Once during each of his turns in wich the character does not run or charge, he can spend 1 feat point to pitch himself over the heads of his enemies into the heart of battle. When the character uses this benefit, place him anywhere within 5inches of his current location.", shortdesc="Place character anywhere within 5 inches"},
    ["Feat: Counter Charge"] ={order=26, type="Mighty", prereq="", desc="When an enemy advances and ends it movement within 36 feet(6 inches) of this character and in his line of sight, this character can immediatly spend 1 feat point to charge the enemy. The character cannot make a counter charge while engaged.", shortdesc="When enemy stops its advance within 6 inches in line of sight spend 1 feat point to charge the enemy" },
    ["Feat: Invulnerable"] = {order=27, type="Mighty", prereq="", desc="The character can spend 1 feat point during his turn to gain +3 ARM for one round.", shortdesc="Spend 1 feat point to get +3 ARM for 1 round" },
    ["Feat: Revitalize"] = {order=28, type="Mighty", prereq="", desc="The character can spend 1 feat point during his turn to regain a number of vitality points equal to his PHY stat immediatly. If a character suffers damage during his turn the damage must be resolved before a character can use this feat. An incapacitated character cannot use Revitalize.", shortdesc="Spend 1 feat point to regain PHY vitality"},
    ["Feat: Shield Breaker"]={order=29, type="Mighty", prereq="", desc="When this character hits a target that has a shieldwith a melee attack, the character can spend 1 feat point to use this benefit. When the character uses this benefit after damage has been dealt the other character's shield is completely destroyed as a result of the attack.", shortdesc="Spend 1 feat point after hit to destroy shield" },
    ["Feat: Vendetta"]={order=30, type="Mighty", prereq="", desc="The character can spend 1 feat point during his turn to use this benefit. When this ability is used the character names one enemy. For the rest of the encounter thischaracter gains boosted attack rolls against that enemy. A character can use this benefit only once per encounter unless the original subject of his vendetta is destroyed, at wich point the character can spend a feat point to use this benefit again.", shortdesc="Spend 1 feat point to gain boosted attacks against target for the encounter"},
    ["Righteous Anger"]={order=31, type="Mighty", prereq="", desc="When one or more characters who are friendly to this character are damaged by an enemy attack whil in this character's command range, this character gains +2 STR and ARM for one round.", shortdesc="When an ally is damaged while inside the characters command range gain +2 ARM and STR for 1 round"},
    ["Tough"]={order=32, type="Mighty", prereq="", desc="The character is incredibly hardy. When this character is disabled, roll 1d6. On a 5 or 6, the character heals 1 vitality point, is no longer disabled, and is knocked down.", shortdesc="When disabled rol 1d6: On 5 or 6 heal 1 vitality, the character is kocked down not disabled"},
    
    ["Skilled"]={order=33, type="Skilled", prereq="",desc="A Skilled character gains an additional attack during his Activation Phase if he chooses to attack that turn.", shortdesc="+1 attack/activation", starting=true},
    ["Ambidextrous"]={order=34,type="Skilled",prereq="",desc="The character does not suffer the normal attack roll penalty with a second weapon while using the Two.Weapon Fighing ability.", shortdesc="Use Two-Weapon Fighting with no penalty"},
    ["Cagey"]={order=35,type="Skilled", prereq="", desc="When this character becomes knocked down, he can immediately move up tp twelve feet(2 inches) and cannot be targeted by free strikes during this movement. This benefit has no effect while the character is mointed. While knocked down, this character is not automatically hit by melee attacks and his DEF is not reduced. The character can stand up during his turn without forfeiting his movement or action.", shortdesc="Move 2 incehs on knock down, melee attacks dont auto hit, no DEF penalty, can stand up without losing movement or action"},
    ["Deft"]={order=36, type="Skilled", prereq="", desc="The character has nimble fingers and steady hands. The character gains boosted AGI rolls.", shortdesc="AGI rolls are boosted"},
    ["Feat: Defensive Strike"] = { order=37, type="Skilled", prereq="", desc="When an enemy advances into and ends its movement in this character's melee range, this character can spend 1 feat point to immediately make one melee attack targeting it.", shortdesc="Spend 1 feat point to gain a first strike" },
    ["Feat: Disarm"]={order=38, type="Skilled", prereq="", desc="After directly hiting an enemy with non-spray, non-AOE(area of effect) ranged or melee attack, instead of making a damage roll, the character can spend 1 feat point to disarm his opponent. When this benefit is used, the enemy's weapon, or any object in his hand, flies from his grasp. He suffers no damage from this attack.", shortdesc="Spend 1 feat point to disarm enemy instead of damage"},
    ["Feat: Swashbuckler"]={order=39, type="Skilled", prereq="", desc="Once during each of his turns, this character can spend 1 feat point to use Swashbuckler. The next time this character makes an attack with a hand weapon after using this benefit, his ront arc extends to 360 degrees, and he can make one melee attack against each enemy in his line of sight in his melee range. Regardless of the number of characters hit, Swashbuckler can trigger the Sidestep benefit only once.", shortdesc="Attack all adjacent characters"},
    ["Feat: Untouchable"] ={order=40, type="Skilled", prereq="", desc="The character can spend 1 feat point during his turn to gain +3 DEF for one round.", shortdesc="Spend 1 feat point to gain +3 DEF for 1 round"},
    ["Preternatural Awareness"] ={order=41, type="Skilled", prereq="", desc="The character's uncanny perception keeps him constantly aware of his surroundings. The character gains boosted initiative rolls. Additionally, enemies never gain back strike bonuses against this character.", shortdesc="Initiative is boosted, immune to back strike"},
    ["Sidestep"]={order=42, type="Skilled", prereq="", desc="When this character hits an enemy cahracter with a melee weapon, he can advance up tp 2 inches after the attack is resolved. This character cannot be targeted by free strikes during this movement.", shortdesc="Advance 2 inches after hit, no free strikes"},
    ["Virtuoso"]={order=43, type="Skilled", prereq="", desc="Choose a military skill. When making a non-AOE attack with a weapon taht uses that skill, this character gains an additional die on his attack and damage rolls. Discard the lowest die for each roll. This benefit can be taken more than once, each time speciying a different military skill.", shortdesc="Gain +1 die on attack and damage rolls with choosen weapon skill, discard lowest for both"}
};

careers={
    ["Alchemist"]={ 
        skills={ ["Hand Weapon"]=2, ["Thrown Weapon"]=4, ["Unarmed Combat"]=2, ["Alchemy"]=4, ["Craft"]=4, ["Forgery"]=2, ["Animal Handling"]=4, ["Climbing"]=4, ["Detection"]=4, ["Driving"]=4, ["Gambling"]=4, ["Intimidation"]=4, ["Jumping"]=4, ["Lore"]=4, ["Riding"]=4, ["Swimming"]=4, ["Medicine"]=4, ["Negotiation" ]=4, ["Research"]=4 },
        abilities={}
        },
    ["Arcane Mechanik"]={
        skills={ ["Hand Weapon"]=2, ["Light Artillery"]=2, ["Rifle"]=2, ["Command"]=1, ["Craft"]=4, ["Cryptography"]=3, ["Animal Handling"]=4, ["Climbing"]=4, ["Detection"]=4, ["Driving"]=4, ["Gambling"]=4, ["Intimidation"]=4, ["Jumping"]=4, ["Lore"]=4, ["Riding"]=4, ["Swimming"]=4, ["Mechanikal Eng."]=4, ["Negotiation" ]=2, ["Research"]=3 },
    },
    ["Arcanist"]={
        skills={ ["Craft"]=2, ["Etiquette"]=3, ["Animal Handling"]=4, ["Climbing"]=4, ["Detection"]=4, ["Driving"]=4, ["Gambling"]=4, ["Intimidation"]=4, ["Jumping"]=4, ["Lore"]=4, ["Riding"]=4, ["Swimming"]=4, ["Negotiation" ]=2, ["Oratory"]=2, ["Research"]=4 },
    },
    ["Aristocrat"]={
        skills={ ["Archery"]=2, ["Hand Weapon"]=3, ["Lance"]=3, ["Pistol"]=2, ["Rifle"]=3, ["Bribery"]=4, ["Command"]=4, ["Cryptography"]=2, ["Deception"]=4, ["Etiquette"]=4,  ["Animal Handling"]=4, ["Climbing"]=4, ["Detection"]=4, ["Driving"]=4, ["Gambling"]=4, ["Intimidation"]=4, ["Jumping"]=4, ["Lore"]=4, ["Riding"]=4, ["Swimming"]=4, ["Law"]=4, ["Negotiation"]=4, ["Oratory"]=4, ["Seduction"]=4 },
    }
};

-- Coin labels
cointypes = { "PP", "GP", "SP", "CP", "AD", "RESIDUUM" };

-- Party sheet drop down list data
psabilitydata = {
	"physique",
	"strength",
	"speed",
	"agility",
	"prowess",
	"poise",
	"intellect",
	"arcane",
	"perception",
	"willpower"
};

psskilldata = {
    "animal handling",
    "climbing",
    "detection",
    "driving",
    "gambling",
    "intimidation",
    "jumping",
    "riding",
    "swimming"
};

