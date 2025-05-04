-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("mobile_derived", Package.CardPack)
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_derived/skills")

Fk:loadTranslationTable{
  ["mobile_derived"] = "手杀衍生牌",
}

local enemy_at_the_gates = fk.CreateCard{
  name = "&mobile__enemy_at_the_gates",
  type = Card.TypeTrick,
  skill = "mobile__enemy_at_the_gates_skill",
}
extension:addCardSpec("mobile__enemy_at_the_gates", Card.Spade, 7)
Fk:loadTranslationTable{
  ["mobile__enemy_at_the_gates"] = "兵临城下",
  [":mobile__enemy_at_the_gates"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：你展示牌堆顶的四张牌，"..
  "依次对目标角色使用其中的【杀】，然后将其余的牌以原顺序放回牌堆顶。",

  ["mobile__enemy_at_the_gates_skill"] = "兵临城下",
  ["#mobile__enemy_at_the_gates_skill"] = "选择一名其他角色，你展示牌堆顶四张牌，依次对其使用其中【杀】，其余牌放回牌堆顶",
}

local raid_and_frontal_attack = fk.CreateCard{
  name = "&raid_and_frontal_attack",
  type = Card.TypeTrick,
  is_damage_card = true,
  skill = "raid_and_frontal_attack_skill",
}
Fk:loadTranslationTable{
  ["raid_and_frontal_attack"] = "奇正相生",
  [":raid_and_frontal_attack"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：当此牌指定目标后，"..
  "你为其指定“奇兵”或“正兵”。目标角色可以打出一张【杀】或【闪】，然后若其为：“奇兵”目标且未打出【杀】，你对其造成1点伤害；“正兵”目标且未打出【闪】，"..
  "你获得其一张牌。",
}
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 2)
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 4)
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 6)
extension:addCardSpec("raid_and_frontal_attack", Card.Spade, 8)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 3)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 5)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 7)
extension:addCardSpec("raid_and_frontal_attack", Card.Diamond, 9)

local ex_crossbow = fk.CreateCard{
  name = "&ex_crossbow",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "#ex_crossbow_skill",
}
extension:addCardSpec("ex_crossbow", Card.Club, 1)
Fk:loadTranslationTable{
  ["ex_crossbow"] = "元戎精械弩",
  [":ex_crossbow"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你于出牌阶段内使用【杀】无次数限制。",
}

local ex_eight_diagram = fk.CreateCard{
  name = "&ex_eight_diagram",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_eight_diagram_skill",
}
extension:addCardSpec("ex_eight_diagram", Card.Spade, 2)
Fk:loadTranslationTable{
  ["ex_eight_diagram"] = "先天八卦阵",
  [":ex_eight_diagram"] = "装备牌·防具<br/><b>防具技能</b>：当你需要使用或打出一张【闪】时，你可以进行判定：若结果不为♠，"..
  "视为你使用或打出了一张【闪】。",
}

local ex_nioh_shield = fk.CreateCard{
  name = "&ex_nioh_shield",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_nioh_shield_skill",
}
extension:addCardSpec("ex_nioh_shield", Card.Club, 2)
Fk:loadTranslationTable{
  ["ex_nioh_shield"] = "仁王金刚盾",
  [":ex_nioh_shield"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，黑色【杀】和<font color='red'>♥</font>【杀】对你无效。",
}

local ex_vine = fk.CreateCard{
  name = "&ex_vine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_vine_skill",
}
extension:addCardSpec("ex_vine", Card.Club, 2)
Fk:loadTranslationTable{
  ["ex_vine"] = "桐油百韧甲",
  [":ex_vine"] = "装备牌·防具<br/><b>防具技能</b>：锁定技。【南蛮入侵】、【万箭齐发】和普通【杀】对你无效。你不能被横置。"..
  "当你受到火焰伤害时，此伤害+1。",
}

local ex_silver_lion = fk.CreateCard{
  name = "&ex_silver_lion",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeArmor,
  equip_skill = "#ex_silver_lion_skill",
}
extension:addCardSpec("ex_silver_lion", Card.Club, 1)
Fk:loadTranslationTable{
  ["ex_silver_lion"] = "照月狮子盔",
  [":ex_silver_lion"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，当你受到伤害时，若此伤害大于1点，防止多余的伤害。当你失去装备区里的"..
  "【照月狮子盔】后，你回复1点体力并摸两张牌。",
}

local catapult = fk.CreateCard{
  name = "&mobile__catapult",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#mobile__catapult_skill",
}
extension:addCardSpec("mobile__catapult", Card.Diamond, 9)
Fk:loadTranslationTable{
  ["mobile__catapult"] = "霹雳车",
  [":mobile__catapult"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/><b>武器技能</b>：当你对其他角色造成伤害后，你可以弃置其装备区内的所有牌。",
}

local offensive_siege_engine = fk.CreateCard{
  name = "&offensive_siege_engine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#offensive_siege_engine_skill",
  on_install = function(self, room, player)
    local cardMark = self:getMark("offensive_siege_engine_durability")
    if cardMark == 0 then
      room:setPlayerMark(player, "@offensive_siege_engine_durability", 2)
      room:setCardMark(self, "offensive_siege_engine_durability", 2)
    else
      room:setPlayerMark(player, "@offensive_siege_engine_durability", cardMark)
    end
    Weapon.onInstall(self, room, player)
  end,
  on_uninstall = function(self, room, player)
    room:setCardMark(self, "offensive_siege_engine_durability", player:getMark("@offensive_siege_engine_durability"))
    room:setPlayerMark(player, "@offensive_siege_engine_durability", 0)
    Weapon.onUninstall(self, room, player)
  end,
}
extension:addCardSpec("offensive_siege_engine", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["offensive_siege_engine"] = "大攻车·进击",
  [":offensive_siege_engine"] = "装备牌·武器<br/><b>攻击范围</b>：9<br /><b>耐久度</b>：2<br />" ..
  "<b>武器技能</b>：当此牌进入装备区后，弃置你装备区里的其他牌；当其他装备牌进入装备区前，改为将之置入弃牌堆；" ..
  "当你造成伤害时，你可以令此牌减1点耐久度，令此伤害+X（X为游戏轮数且至多为3）；当此牌不因“渠冲”而离开装备区时，防止之，然后此牌-1点耐久度；" ..
  "当此牌耐久度减至0时，销毁此牌。",
}

local defensive_siege_engine = fk.CreateCard{
  name = "&defensive_siege_engine",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 9,
  equip_skill = "#defensive_siege_engine_skill",
  on_install = function(self, room, player)
    local cardMark = self:getMark("defensive_siege_engine_durability")
    if cardMark == 0 then
      room:setPlayerMark(player, "@defensive_siege_engine_durability", 3)
      room:setCardMark(self, "defensive_siege_engine_durability", 3)
    else
      room:setPlayerMark(player, "@defensive_siege_engine_durability", cardMark)
    end
    Weapon.onInstall(self, room, player)
  end,
  on_uninstall = function(self, room, player)
    room:setCardMark(self, "defensive_siege_engine_durability", player:getMark("@defensive_siege_engine_durability"))
    room:setPlayerMark(player, "@defensive_siege_engine_durability", 0)
    Weapon.onUninstall(self, room, player)
  end,
}
extension:addCardSpec("defensive_siege_engine", Card.Diamond, 1)
Fk:loadTranslationTable{
  ["defensive_siege_engine"] = "大攻车·守御",
  [":defensive_siege_engine"] = "装备牌·武器<br/><b>攻击范围</b>：9<br/><b>耐久度</b>：3<br/>" ..
  "<b>武器技能</b>：当此牌进入装备区后，弃置你装备区里的其他牌；当其他装备牌进入装备区前，改为将之置入弃牌堆；" ..
  "当你受到伤害时，此牌减等量点耐久度（不足则全减），令此伤害-X（X为减少的耐久度）；当此牌不因“渠冲”而离开装备区时，防止之，然后此牌减1点耐久度；" ..
  "当此牌耐久度减至0时，销毁此牌。",
}

local xuanjian_sword = fk.CreateCard{
  name = "&xuanjian_sword",
  type = Card.TypeEquip,
  sub_type = Card.SubtypeWeapon,
  attack_range = 3,
  equip_skill = "xuanjian_sword_skill&",
}
extension:addCardSpec("xuanjian_sword", Card.Spade, 9)
Fk:loadTranslationTable{
  ["xuanjian_sword"] = "玄剑",
  [":xuanjian_sword"] = "装备牌·武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：你可以将一种花色的所有手牌当【杀】使用。",
}

extension:loadCardSkels {
  enemy_at_the_gates,
  raid_and_frontal_attack,

  ex_crossbow,
  ex_eight_diagram,
  ex_nioh_shield,
  ex_vine,
  ex_silver_lion,
  catapult,
  offensive_siege_engine,
  defensive_siege_engine,
  xuanjian_sword,
}

return extension
