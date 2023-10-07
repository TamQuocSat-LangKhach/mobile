local extension = Package("m_shzl_ex")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["m_shzl_ex"] = "手杀界神话再临",
}

local caopi = General(extension, "m_ex__caopi", "wei", 3)
local xingshang = fk.CreateTriggerSkill{
  name = "m_ex__xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not (target:isNude() and not player:isWounded())
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"m_ex__xingshang_obtain::" .. target.id, "recover", "Cancel"}
    local choices = table.clone(all_choices)
    if not target:isNude() then table.remove(choices, 1) end
    if player:isWounded() then table.removeOne(choices, "recover") end
    local choice = player.room:askForChoice(player, choices, self.name, nil, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = self.cost_data
    if choice == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      local cards_id = target:getCardIds{Player.Hand, Player.Equip}
      local dummy = Fk:cloneCard'slash'
      dummy:addSubcards(cards_id)
      room:obtainCard(player.id, dummy, false, fk.Discard)
    end
  end,
}
local fangzhu = fk.CreateTriggerSkill{
  name = "m_ex__fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#m_ex__fangzhu-choose:::"..player:getLostHp(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local num = player:getLostHp()
    if to.hp > 0 and #room:askForDiscard(to, num, num, true, self.name, true, nil, "#m_ex__fangzhu-ask:::" .. num, false) > 0 then
      if not to.dead then room:loseHp(to, 1, self.name) end
    else
      to:drawCards(num, self.name)
      if not to.dead then to:turnOver() end
    end
  end,
}
caopi:addSkill(xingshang)
caopi:addSkill(fangzhu)
caopi:addSkill("songwei")
Fk:loadTranslationTable{
  ["m_ex__caopi"] = "界曹丕",
  ["m_ex__xingshang"] = "行殇",
  [":m_ex__xingshang"] = "当其他角色死亡时，你可以选择一项：1.获得其所有牌；2.回复1点体力。",
  ["m_ex__fangzhu"] = "放逐",
  [":m_ex__fangzhu"] = "当你受到伤害后，你可以令一名其他角色选择一项：1.弃置X张牌并失去1点体力；2.摸X张牌并翻面（X为你已损失的体力值）。",

  ["m_ex__xingshang_obtain"] = "获得%dest的所有牌",
  ["#m_ex__fangzhu-choose"] = "放逐：你可令一名其他角色选择摸%arg张牌并翻面，或弃置%arg张牌并失去1点体力",
  ["#m_ex__fangzhu-ask"] = "放逐：弃置%arg张牌并失去1点体力，或点击“取消”，摸%arg张牌并翻面",

  ["$m_ex__xingshang1"] = "群燕辞归鹄南翔，念君客游思断肠",
  ["$m_ex__xingshang2"] = "霜露纷兮文下，木叶落兮凄凄。",
  ["$m_ex__fangzhu1"] = "国法不可废耳，汝先退去。",
  ["$m_ex__fangzhu2"] = "将军征战辛苦，孤当赠以良宅。",
  ["$songwei_m_ex__caopi1"] = "藩屏大宗，御侮厌难。",
  ["$songwei_m_ex__caopi2"] = "朕承符运，终受革命。",
  ["~m_ex__caopi"] = "建平所言八十，谓昼夜也，吾其决矣……",
}

local jiangwei = General(extension, "m_ex__jiangwei", "shu", 4)
local tiaoxin = fk.CreateActiveSkill{
  name = "m_ex__tiaoxin",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local use = room:askForUseCard(target, "slash", "slash", "#tiaoxin-use", true, {exclusive_targets = {player.id} })
    if use then
      room:useCard(use)
    else
      if not target:isNude() then
        local card = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({card}, self.name, target, player)
      end
    end
  end
}
local zhiji = fk.CreateTriggerSkill{
  name = "m_ex__zhiji",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw2"}
    if player:isWounded() then
      table.insert(choices, "recover")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "draw2" then
      player:drawCards(2)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "ex__guanxing", nil, true, false)
  end,
}
jiangwei:addSkill(tiaoxin)
jiangwei:addSkill(zhiji)
jiangwei:addRelatedSkill("ex__guanxing")
Fk:loadTranslationTable{
  ["m_ex__jiangwei"] = "界姜维",
  ["m_ex__tiaoxin"] = "挑衅",
  [":m_ex__tiaoxin"] = "出牌阶段限一次，你可以选择一名其他角色，然后除非该角色对你使用一张【杀】，否则你弃置其一张牌。",
  ["m_ex__zhiji"] = "志继",
  [":m_ex__zhiji"] = "觉醒技，准备阶段，若你没有手牌，你回复1点体力或摸两张牌，减1点体力上限，然后获得〖观星〗。",

  ["$m_ex__tiaoxin1"] = "黄口竖子，何必上阵送命？",
  ["$m_ex__tiaoxin2"] = "汝如欲大败而归，则可进军一战！",
  ["$m_ex__zhiji1"] = "维定当奋身以复汉室。",
  ["$m_ex__zhiji2"] = "丞相之志，维必竭力而为。",
  ["$ex__guanxing_m_ex__jiangwei1"] = "知天易则观之，逆天难亦行之。",
  ["$ex__guanxing_m_ex__jiangwei2"] = "欲尽人事，亦先听天命。",
  ["~m_ex__jiangwei"] = "可惜大计未成，吾已身陨。",
}

return extension
