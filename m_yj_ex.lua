local extension = Package("m_yj_ex")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["m_yj_ex"] = "手杀界一将",
}

local wuguotai = General(extension, "m_ex__wuguotai", "wu", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__wuguotai"] = "界吴国太",
  ["~m_ex__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",
}

local m_ex__ganlu = fk.CreateActiveSkill{
  name = "m_ex__ganlu",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] > 0
    elseif #selected == 1 then
      if selected[1] == Self.id or to_select == Self.id then return true end
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      return math.abs(#target1.player_cards[Player.Equip] - #target2.player_cards[Player.Equip]) <= Self:getLostHp()
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local target1 = Fk:currentRoom():getPlayerById(effect.tos[1])
    local target2 = Fk:currentRoom():getPlayerById(effect.tos[2])
    local cards1 = table.clone(target1.player_cards[Player.Equip])
    local cards2 = table.clone(target2.player_cards[Player.Equip])
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[1],
        ids = cards1,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = effect.tos[2],
        ids = cards2,
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = effect.from,
        skillName = self.name,
      })
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    moveInfos = {}

    if not target2.dead then
      local to_ex_cards1 = table.filter(cards1, function (id)
        return room:getCardArea(id) == Card.Processing and target2:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards1 > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards1,
          fromArea = Card.Processing,
          to = effect.tos[2],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if not target1.dead then
      local to_ex_cards = table.filter(cards2, function (id)
        return room:getCardArea(id) == Card.Processing and target1:getEquipment(Fk:getCardById(id).sub_type) == nil
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = effect.tos[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonExchange,
          proposer = effect.from,
          skillName = self.name,
        })
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    table.insertTable(cards1, cards2)

    local dis_cards = table.filter(cards1, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(dis_cards)
      room:moveCardTo(dummy, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__ganlu"] = "甘露",
  [":m_ex__ganlu"] = "出牌阶段限一次，你可以选择两名装备区里的牌数之差不大于你已损失的体力值的角色，交换他们装备区里的牌；若你选择的角色中含有你，则不受牌数之差的限制。",
  ["$m_ex__ganlu1"] = "玄德实乃佳婿呀。",
  ["$m_ex__ganlu2"] = "好一个郎才女貌，真是天作之合啊。",
}

wuguotai:addSkill(m_ex__ganlu)

Fk:loadTranslationTable{
  --["$m_ex__buyi1"] = "有我在，定保贤婿无虞！",
  --["$m_ex__buyi2"] = "东吴岂容汝等儿戏！",
}

wuguotai:addSkill("buyi")

--local gaoshun = General(extension, "m_ex__gaoshun", "qun", 4)

Fk:loadTranslationTable{
  ["m_ex__gaoshun"] = "界高顺",
  ["~m_ex__gaoshun"] = "可叹主公知而不用啊！",
}

Fk:loadTranslationTable{
  ["m_ex__xianzhen"] = "陷阵",
  [":m_ex__xianzhen"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，此出牌阶段你无视该角色的防具，对其使用牌没有距离和次数限制；若你没赢，此出牌阶段你不能使用【杀】。若你发动“陷阵”拼点的牌为【杀】，则本回合你的【杀】不计入手牌上限。",
  ["$m_ex__xianzhen1"] = "陷阵之志，有死无生！",
  ["$m_ex__xianzhen2"] = "攻则破城，战则克敌。",
}

Fk:loadTranslationTable{
  ["m_ex__jinjiu"] = "禁酒",
  [":m_ex__jinjiu"] = "锁定技，你的【酒】均枧为【杀】；当你受到【酒】【杀】造成的伤害时，此伤害-X （X为增加此【杀】伤害的【酒】张数）。你的回合内，其他角色无法使用【酒】。",
  ["$m_ex__jinjiu1"] = "耽此黄汤，岂不误事？",
  ["$m_ex__jinjiu2"] = "陷阵营中，不可饮酒。",
}

local yujin = General(extension, "m_ex__yujin", "wei", 4)

Fk:loadTranslationTable{
  ["m_ex__yujin"] = "界于禁",
  ["~m_ex__yujin"] = "如今临危处难，却负丞相三十年之赏识，唉……",
}

local m_ex__jieyue_select = fk.CreateActiveSkill{
  name = "#m_ex__jieyue_select",
  can_use = function() return false end,
  target_num = 0,
  card_num = function()
    local x = 0
    if #Self.player_cards[Player.Hand] > 0 then x = x + 1 end
    if #Self.player_cards[Player.Equip] > 0 then x = x + 1 end
    return x
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1  then
      return (Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip) ~=
      (Fk:currentRoom():getCardArea(selected[1]) == Card.PlayerEquip)
    end
    return #selected == 0
  end,
}
local m_ex__jieyue = fk.CreateTriggerSkill{
  name = "m_ex__jieyue",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target == player and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".", "#m_ex__jieyue-choose", self.name, true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:obtainCard(to, self.cost_data[2], false, fk.ReasonGive)
    if to.dead then return end
    local _, ret = room:askForUseActiveSkill(to, "#m_ex__jieyue_select", "#m_ex__jieyue-select:" .. player.id, true)
    if ret then
      local cards = table.filter(to:getCardIds{Player.Hand, Player.Equip}, function (id)
        return not (table.contains(ret.cards, id) or to:prohibitDiscard(id))
      end)
      if #cards > 0 then
        room:throwCard(cards, self.name, to)
      end
    else
      player:drawCards(3, self.name)
    end
  end,
}
m_ex__jieyue:addRelatedSkill(m_ex__jieyue_select)

Fk:loadTranslationTable{
  ["m_ex__jieyue"] = "节钺",
  ["#m_ex__jieyue_select"] = "节钺",
  [":m_ex__jieyue"] = "结束阶段，你可以将一张牌交给一名其他角色，然后其选择一项：1.保留手牌和装备区内的各一张牌，然后弃置其余的牌；2.令你摸三张牌。",
  ["#m_ex__jieyue-choose"] = "节钺：可以选择一张牌交给一名其他角色",
  ["#m_ex__jieyue-select"] = "节钺：选择一张手牌和一张装备区里的牌保留，弃置其他的牌；或点取消令%src摸三张牌",
  ["$m_ex__jieyue1"] = "按丞相之命，此部今由余统摄！",
  ["$m_ex__jieyue2"] = "奉法行令，事上之节，岂有宽宥之理？",
}

yujin:addSkill(m_ex__jieyue)

local caozhi = General(extension, "m_ex__caozhi", "wei", 3)

Fk:loadTranslationTable{
  ["m_ex__caozhi"] = "界曹植",
  ["~m_ex__caozhi"] = "先民谁不死，知命复何忧？",
}

Fk:loadTranslationTable{
  --["$m_ex__luoying1"] = "转蓬离本根，飘摇随长风。",
  --["$m_ex__luoying2"] = "高树多悲风，海水扬其波。",
}

caozhi:addSkill("luoying")

local m_ex__jiushi = fk.CreateViewAsSkill{
  name = "m_ex__jiushi",
  anim_type = "support",
  pattern = "analeptic",
  card_filter = function() return false end,
  before_use = function(self, player)
    player:turnOver()
  end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function (self, player)
    return player.faceup
  end,
  enabled_at_response = function (self, player)
    return player.faceup
  end,
}
local m_ex__jiushi_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__jiushi_trigger",
  anim_type = "support",
  mute = true,
  events = {fk.Damaged, fk.TurnedOver},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(m_ex__jiushi.name) then
      if event == fk.Damaged then
        return not player.faceup and not (data.extra_data or {}).m_ex__jiushicheak
      elseif event == fk.TurnedOver then
        return player:usedSkillTimes("m_ex__chengzhang", Player.HistoryGame) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.TurnedOver or player.room:askForSkillInvoke(player, m_ex__jiushi.name)
  end,
  on_use = function(self, event, target, player, data)
    room:notifySkillInvoked(player, m_ex__jiushi.name)
    room:broadcastSkillInvoke(m_ex__jiushi.name)
    if event == fk.Damaged then
      player:turnOver()
      if player:usedSkillTimes("m_ex__chengzhang", Player.HistoryGame) > 0 then return end
    end
    if not player.dead then
      local cards = player.room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #cards > 0 then
        player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
      end
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.m_ex__jiushicheak = true
  end,
}
m_ex__jiushi:addRelatedSkill(m_ex__jiushi_trigger)

Fk:loadTranslationTable{
  ["m_ex__jiushi"] = "酒诗",
  ["#m_ex__jiushi_trigger"] = "酒诗",
  [":m_ex__jiushi"] = "当你需要使用【酒】时，若你的武将牌正面向上，你可以翻面，视为使用一张【酒】；当你受到伤害后，若你的武将牌背面向上，你可以翻面并随机获得牌堆中的一张锦囊牌。",
  ["$m_ex__jiushi1"] = "归来宴平乐，美酒斗十千。",
  ["$m_ex__jiushi2"] = "乐饮过三爵，缓带倾庶羞。",
}

caozhi:addSkill(m_ex__jiushi)

local m_ex__chengzhang = fk.CreateTriggerSkill{
  name = "m_ex__chengzhang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("m_ex__chengzhang_count") > 6
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@m_ex__chengzhang", 0)
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.Damage, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "m_ex__chengzhang_count", data.damage)
    if player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      player.room:setPlayerMark(player, "@m_ex__chengzhang", player:getMark("m_ex__chengzhang_count"))
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__chengzhang"] = "成章",
  [":m_ex__chengzhang"] = "觉醒技，准备阶段，若你造成的伤害与受到的伤害值之和累计7点或以上，则你回复1点体力并摸1张牌，然后修改〖酒诗〗。",
  ["@m_ex__chengzhang"] = "成章",
  ["$m_ex__chengzhang1"] = "盛时不再来，百年忽我遒。",
  ["$m_ex__chengzhang2"] = "弦急悲声发，聆我慷慨言。",
}

caozhi:addSkill(m_ex__chengzhang)

local lingtong = General(extension, "m_ex__lingtong", "wu", 4)

Fk:loadTranslationTable{
  ["m_ex__lingtong"] = "界凌统",
  ["~m_ex__lingtong"] = "先……停一下吧……",
}

local m_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "m_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      else
        return target == player and player.phase == Player.Discard and player:getMark("m_ex__xuanfeng_discardcount-phase") > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"m_ex__xuanfeng_movecard", "Cancel"}
    if table.find(room:getOtherPlayers(player), function(p)
      return not p:isNude() end) then
      table.insert(choices, 1, "m_ex__xuanfeng_discard")
    end
    self.cost_data = room:askForChoice(player, choices, self.name)
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "m_ex__xuanfeng_discard" then
      for i = 1, 2, 1 do
        local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
          return not p:isNude() end), function (p) return p.id end)
        if #targets == 0 then return end
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#m_ex__xuanfeng-discard", self.name, true)
        if #tos == 0 then return end
        local card = room:askForCardChosen(player, room:getPlayerById(tos[1]), "he", self.name)
        room:throwCard({card}, self.name, room:getPlayerById(tos[1]), player)
      end
    elseif self.cost_data == "m_ex__xuanfeng_movecard" then
      local to = room:askForChooseToMoveCardInBoard(player, "#m_ex__xuanfeng-movecard", self.name, true, "e")
      if #to == 2 then
        room:askForMoveCardInBoard(player, room:getPlayerById(to[1]), room:getPlayerById(to[2]), self.name, "e")
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    self.trigger_times = 0
    for _, move in ipairs(data) do
      if move.from and move.from == player.id and move.moveReason == fk.ReasonDiscard then
        self.trigger_times = self.trigger_times + #table.filter(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand
        end)
      end
    end
    return self.trigger_times > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "m_ex__xuanfeng_discardcount-phase", self.trigger_times)
  end,
}

Fk:loadTranslationTable{
  ["m_ex__xuanfeng"] = "旋风",
  [":m_ex__xuanfeng"] = "当你于弃牌阶段弃置过至少两张牌，或当你失去装备区里的牌后，你可以选择一项：1.弃置至多两名其他角色的共计两张牌；2.将一名其他角色装备区里的牌移动到另一名其他角色的对应区域。",

  ["m_ex__xuanfeng_movecard"] = "移动场上的一张装备牌",
  ["m_ex__xuanfeng_discard"] = "弃置至多两名其他角色的共计两张牌",
  ["#m_ex__xuanfeng-discard"] = "旋风：你可以选择一名角色，弃置其一张牌",
  ["#m_ex__xuanfeng-movecard"] = "旋风：你可以选择两名角色，移动这些角色装备区的一张牌",

  ["$m_ex__xuanfeng1"] = "短兵相接，让敌人丢盔弃甲！",
  ["$m_ex__xuanfeng2"] = "攻敌不备，看他们闻风而逃！",
}

lingtong:addSkill(m_ex__xuanfeng)

local zhonghui = General(extension, "m_ex__zhonghui", "wei", 4)

Fk:loadTranslationTable{
  ["m_ex__zhonghui"] = "界钟会",
  ["~m_ex__zhonghui"] = "父亲，吾能自知。却终不能自制……",
}

local m_ex__quanji = fk.CreateTriggerSkill{
  name = "m_ex__quanji",
  anim_type = "masochism",
  events = {fk.Damaged, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
    (event == fk.Damaged or (player.phase == Player.Play and player:getHandcardNum() > player.hp))
  end,
  on_trigger = function(self, event, target, player, data)
    local x = 1
    if event == fk.Damaged then
      x = data.damage
    end
    self.cancel_cost = false
    for i = 1, x do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if not player:isKongcheng() then
      local card = room:askForCard(player, 1, 1, false, self.name, false, "", "#m_ex__quanji-push")
      player:addToPile("m_ex__zhonghui_power", card, false, self.name)
    end
  end,
}
local m_ex__quanji_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__quanji_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return #player:getPile("m_ex__zhonghui_power")
    else
      return 0
    end
  end,
}
m_ex__quanji:addRelatedSkill(m_ex__quanji_maxcards)

Fk:loadTranslationTable{
  ["m_ex__quanji"] = "权计",
  [":m_ex__quanji"] = "出牌阶段结束时，若你的手牌数大于你的体力值，或当你受到1点伤害后，你可以摸一张牌，然后你将一张手牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”数）。",
  ["m_ex__zhonghui_power"] = "权",
  ["#m_ex__quanji-push"] = "权计：选择1张手牌作为“权”置于武将牌上",
  ["$m_ex__quanji1"] = "善算轻重，权审其宜。",
  ["$m_ex__quanji2"] = "缓急不在一时，吾等慢慢来过。",
}

zhonghui:addSkill(m_ex__quanji)

local m_ex__zili = fk.CreateTriggerSkill{
  name = "m_ex__zili",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player:getPile("m_ex__zhonghui_power") > 2
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
    room:handleAddLoseSkills(player, "m_ex__paiyi", nil)
  end,
}
Fk:loadTranslationTable{
  ["m_ex__zili"] = "自立",
  [":m_ex__zili"] = "觉醒技，准备阶段，若“权”的数量不小于3，你选择一项：1.回复1点体力；2.摸两张牌。然后减1点体力上限，获得“排异”。",
  ["$m_ex__zili1"] = "吾功名盖世，岂可复为人下？",
  ["$m_ex__zili2"] = "天赐良机，不取何为？",
}

zhonghui:addSkill(m_ex__zili)

local m_ex__paiyi = fk.CreateActiveSkill{
  name = "m_ex__paiyi",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  expand_pile = "m_ex__zhonghui_power",
  can_use = function(self, player)
    return #player:getPile("m_ex__zhonghui_power") > 0 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "m_ex__zhonghui_power"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
    })
    target:drawCards(2)
    if #target.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__paiyi"] = "排异",
  [":m_ex__paiyi"] = "出牌阶段限一次，你可以移去一张“权”，令一名角色摸两张牌。若该角色的手牌数大于你，你对其造成1点伤害。",
  ["$m_ex__paiyi1"] = "坏吾大计者，罪死不赦！",
  ["$m_ex__paiyi2"] = "攻讦此子，祸咎已除！",
}

zhonghui:addRelatedSkill(m_ex__paiyi)

local liubiao = General(extension, "m_ex__liubiao", "qun", 3)

Fk:loadTranslationTable{
  ["m_ex__liubiao"] = "界刘表",
  ["~m_ex__liubiao"] = "垂垂老矣，已忘壮年雄心……",
}

Fk:loadTranslationTable{
  --["$m_ex__zishou1"] = "按兵不动，徐图荆襄霸业！",
  --["$m_ex__zishou2"] = "忍时待机，以期坐收渔利！",
}

liubiao:addSkill("re__zishou")

local m_ex__zongshi = fk.CreateTriggerSkill{
  name = "m_ex__zongshi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@@m_ex__zongshi-turn")
  end,
}
local m_ex__zongshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__zongshi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      local kingdoms = {}
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        table.insertIfNeed(kingdoms, p.kingdom)
      end
      return #kingdoms
    else
      return 0
    end
  end,
}
local m_ex__zongshi_targetmod = fk.CreateTargetModSkill{
  name = "#m_ex__zongshi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@@m_ex__zongshi-turn") > 0 and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase then
      return 999
    end
  end,
}
m_ex__zongshi:addRelatedSkill(m_ex__zongshi_maxcards)
m_ex__zongshi:addRelatedSkill(m_ex__zongshi_targetmod)

Fk:loadTranslationTable{
  ["m_ex__zongshi"] = "宗室",
  [":m_ex__zongshi"] = "锁定技，你的手牌上限+X（X为势力数）。准备阶段，若你的手牌数大于体力值，本回合你使用【杀】无次数限制。",
  ["@@m_ex__zongshi-turn"] = "宗室",
  ["$m_ex__zongshi1"] = "汉室之威，犹然彰存！",
  ["$m_ex__zongshi2"] = "这天下，尽是大汉疆土！",
}

liubiao:addSkill(m_ex__zongshi)

local bulianshi = General(extension, "m_ex__bulianshi", "wu", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__bulianshi"] = "界步练师",
  ["~m_ex__bulianshi"] = "今生先君逝，来世再侍君……",
}
local m_ex__anxu = fk.CreateActiveSkill{
  name = "m_ex__anxu",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected)
    if #selected == 1 and Fk:currentRoom():getPlayerById(to_select):isNude() then return false end
    return #selected < 2 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target1 = room:getPlayerById(use.tos[1])
    local target2 = room:getPlayerById(use.tos[2])
    local card = room:askForCardChosen(target1, target2, "he", self.name)
    local can_draw = (Fk:currentRoom():getCardArea(card) ~= Card.PlayerEquip)
    room:obtainCard(target1.id, card, true)
    if can_draw and not player.dead then
      player:drawCards(1, self.name)
    end
    if not player.dead and not target1.dead and not target2.dead and target1:getHandcardNum() ~= target2:getHandcardNum() then
      if target1:getHandcardNum() > target2:getHandcardNum() then
        target1 = target2
      end
      if room:askForSkillInvoke(player, self.name, nil, "#m_ex__anxu-draw::" .. target1.id) then
        target1:drawCards(1, self.name)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["m_ex__anxu"] = "安恤",
  [":m_ex__anxu"] = "出牌阶段限一次，你可以令一名其他角色获得另一名其他角色的一张牌。若其获得的不是来自装备区里的牌，你摸一张牌。当其以此法获得牌后，你可以令两者手牌较少的角色摸一张牌。",
  ["#m_ex__anxu-draw"] = "安恤：是否令手牌数较少的%dest摸一张牌",
  ["$m_ex__anxu1"] = "贤淑重礼，育人育己。",
  ["$m_ex__anxu2"] = "雨露均沾，后宫不乱。",
}

bulianshi:addSkill(m_ex__anxu)

Fk:loadTranslationTable{
  --["$m_ex__zhuiyi1"] = "化作桃园只为君。",
  --["$m_ex__zhuiyi2"] = "魂若有灵，当助夫君。",
}

bulianshi:addSkill("zhuiyi")

local liaohua = General(extension, "m_ex__liaohua", "shu", 4)

Fk:loadTranslationTable{
  ["m_ex__liaohua"] = "界廖化",
  ["~m_ex__liaohua"] = "兴复大业，就靠你们了！",
}

local m_ex__dangxian = fk.CreateTriggerSkill{
  name = "m_ex__dangxian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.room:getCardsFromPileByRule("slash", 1, "discardPile")
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
    player:gainAnExtraPhase(Player.Play)
  end,
}

Fk:loadTranslationTable{
  ["m_ex__dangxian"] = "当先",
  [":m_ex__dangxian"] = "锁定技，回合开始时，你从弃牌堆获得一张【杀】并执行一个额外的出牌阶段。",
  ["$m_ex__dangxian1"] = "谁言蜀汉已无大将？",
  ["$m_ex__dangxian2"] = "老将虽白发，宝刀刃犹锋！",
}

liaohua:addSkill(m_ex__dangxian)

local m_ex__fuli = fk.CreateTriggerSkill{
  name = "m_ex__fuli",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    table.forEach(room.alive_players, function(p)
      table.insertIfNeed(kingdoms, p.kingdom)
    end)
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if not player.dead and table.every(room.alive_players, function(p)
      return p.hp < player.hp
    end) then
      player:turnOver()
    end
  end,
}
Fk:loadTranslationTable{
  ["m_ex__fuli"] = "伏枥",
  [":m_ex__fuli"] = "限定技，当你处于濒死状态时，你可以将你当前的体力值回复至X点（X为全场势力数）。然后若你的体力值全场唯一最高，你翻面。",
  ["$m_ex__fuli1"] = "未破敌军，岂可轻易服输？",
  ["$m_ex__fuli2"] = "看老夫再奋身一战！",
}

liaohua:addSkill(m_ex__fuli)

local caozhang = General(extension, "m_ex__caozhang", "wei", 4)

Fk:loadTranslationTable{
  ["m_ex__caozhang"] = "界曹彰",
  ["~m_ex__caozhang"] = "黄须金甲，也难敌骨肉毒心！",
}


local m_ex__jiangchi_select = fk.CreateActiveSkill{
  name = "#m_ex__jiangchi_select",
  can_use = function() return false end,
  target_num = 0,
  max_card_num = 1,
  min_card_num = 0,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
}
local m_ex__jiangchi = fk.CreateTriggerSkill{
  name = "m_ex__jiangchi",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local _, ret = player.room:askForUseActiveSkill(player, "#m_ex__jiangchi_select", "#m_ex__jiangchi-invoke", true)
      if ret then
        self.cost_data = ret.cards
        return true
      end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:broadcastSkillInvoke(self.name, 2)
      room:throwCard(self.cost_data, self.name, player)
      room:addPlayerMark(player, "@@m_ex__jiangchi_targetmod-phase")
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "@@m_ex__jiangchi_prohibit-phase")
    end
  end,
}
local m_ex__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#m_ex__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name, true) and skill.trueName == "slash_skill" and player:getMark("@@m_ex__jiangchi_targetmod-phase") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name, true) and skill.trueName == "slash_skill" and player:getMark("@@m_ex__jiangchi_targetmod-phase") > 0 then
      return 999
    end
  end,
}
local m_ex__jiangchi_prohibit = fk.CreateProhibitSkill{
  name = "#local m_ex__jiangchi_prohibit",
  prohibit_use = function(self, player, card)
    return player:hasSkill(self.name, true) and player:getMark("@@m_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
  end,
}
m_ex__jiangchi:addRelatedSkill(m_ex__jiangchi_select)
m_ex__jiangchi:addRelatedSkill(m_ex__jiangchi_targetmod)
m_ex__jiangchi:addRelatedSkill(m_ex__jiangchi_prohibit)

Fk:loadTranslationTable{
  ["m_ex__jiangchi"] = "将驰",
  [":m_ex__jiangchi"] = "出牌阶段开始时，你可以选择一项：1.摸一张牌，此阶段不能使用【杀】；2.弃置一张牌，本阶段使用【杀】无距离限制且可以多使用一张【杀】。",
  ["#m_ex__jiangchi-invoke"] = "将驰：你可以摸一张牌，本阶段不能出杀；或选择一张牌弃置，本阶段可多使用一张杀",
  ["@@m_ex__jiangchi_targetmod-phase"] = "将驰 多出杀",
  ["@@m_ex__jiangchi_prohibit-phase"] = "将驰 不出杀",
  ["$m_ex__jiangchi1"] = "将飞翼伏，三军整肃。",
  ["$m_ex__jiangchi2"] = "策马扬鞭，奔驰万里。",
}

caozhang:addSkill(m_ex__jiangchi)

local zhuran = General(extension, "m_ex__zhuran", "wu", 4)

Fk:loadTranslationTable{
  ["m_ex__zhuran"] = "界朱然",
  ["~m_ex__zhuran"] = "大耳贼就在眼前，快追……",
}

local m_ex__danshou = fk.CreateTriggerSkill{
  name = "m_ex__danshou",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target and target.phase == Player.Finish and target ~= player and player:hasSkill(self.name) and
    #player:getCardIds{ Player.Hand, Player.Equip } >= player:getMark("m_ex__danshou_count-turn")
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getMark("m_ex__danshou_count-turn")
    self.cost_data = {}
    if x == 0 then return true
    elseif #player:getCardIds{ Player.Hand, Player.Equip } >= x then
      local card = player.room:askForDiscard(player, x, x, true, self.name, true, ".",
      "#m_ex__danshou-discard::"..target.id..":"..x, true)
      if #card == x then
        self.cost_data = card
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke(self.name)
    if #self.cost_data > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:doIndicate(player.id, {target.id})
      room:throwCard(self.cost_data, self.name, player)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    end
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "m_ex__danshou_count-turn")
    if player:hasSkill(self.name, true) and player.phase ~= Player.NotActive then
      room:setPlayerMark(player, "@m_ex__danshou_count-turn", player:getMark("m_ex__danshou_count-turn"))
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__danshou"] = "胆守",
  [":m_ex__danshou"] = "其他角色的结束阶段，若你本回合未成为过其使用牌的目标，你摸一张牌；否则你可以弃置X张牌，对其造成1点伤害（X为你本回合成为其使用牌的目标的次数）。",
  ["@m_ex__danshou_count-turn"] = "胆守",
  ["#m_ex__danshou-discard"] = "胆守：你可以弃置%arg张牌来对%dest造成1点伤害",
  ["$m_ex__danshou1"] = "此城危难，我必当竭尽全力！",
  ["$m_ex__danshou2"] = "大丈夫屈伸有道，不在一时胜负。",
}

zhuran:addSkill(m_ex__danshou)

local manchong = General(extension, "m_ex__manchong", "wei", 3)

Fk:loadTranslationTable{
  ["m_ex__manchong"] = "界满宠",
  ["~m_ex__manchong"] = "宠一生为公，无愧忠俭之节。",
}

local m_ex__junxing = fk.CreateActiveSkill{
  name = "m_ex__junxing",
  anim_type = "control",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player)
    local x = #effect.cards
    if #room:askForDiscard(target, x, x, true, self.name, true, nil, "#m_ex__junxing-discard:::"..x) == 0 then
      target:turnOver()
      target:drawCards(x, self.name)
    else
      room:loseHp(target, 1, self.name)
    end
  end
}

Fk:loadTranslationTable{
  ["m_ex__junxing"] = "峻刑",
  [":m_ex__junxing"] = "出牌阶段限一次，你可以弃置任意张手牌并令一名其他角色选择一项：1.弃置等量的牌并失去1点体力；2.翻面，然后摸等量的牌。",
  ["#m_ex__junxing-discard"] = "峻刑：选择弃置%arg张牌并失去1点体力，或点取消则翻面并摸%arg张牌",
  ["$m_ex__junxing1"] = "情理可容之事，法未必能容！",
  ["$m_ex__junxing2"] = "严法尚公，岂分贵贱而异施？",
}

manchong:addSkill(m_ex__junxing)

Fk:loadTranslationTable{
  --["$m_ex__yuce1"] = "骄之以利，示之以慑！",
  --["$m_ex__yuce2"] = "虽举得于外，则福生于内矣。",
}

manchong:addSkill("yuce")

local liru = General(extension, "m_ex__liru", "qun", 3)

Fk:loadTranslationTable{
  ["m_ex__liru"] = "界李儒",
  ["~m_ex__liru"] = "吾等皆死于妇人之手矣！",
}

local m_ex__juece = fk.CreateTriggerSkill{
  name = "m_ex__juece",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player), function(p) return (p:getMark("m_ex__juece_lostcard-turn") > 0) end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p:getMark("m_ex__juece_lostcard-turn") > 0) end), function(p) return p.id end),
      1, 1, "#m_ex__juece-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from and move.from == player.id and table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
          return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "m_ex__juece_lostcard-turn")
    if room.current and room.current ~= player and room.current:hasSkill(self.name, true) then
      room:addPlayerMark(player, "@@m_ex__juece_lostcard-turn")
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__juece"] = "绝策",
  [":m_ex__juece"] = "结束阶段，你可以对本回合失去过牌的一名其他角色造成1点伤害。",
  ["#m_ex__juece-choose"] = "绝策：选择一名本回合失去过牌的其他角色，对其造成1点伤害",
  ["@@m_ex__juece_lostcard-turn"] = "失去过牌",
  ["$m_ex__juece1"] = "斩草除根，以绝后患！",
  ["$m_ex__juece2"] = "束手就擒吧！",
}

liru:addSkill(m_ex__juece)

local m_ex__mieji = fk.CreateActiveSkill{
  name = "m_ex__mieji",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected, targets)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.type == Card.TypeTrick and card.color == Card.Black
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude() and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      fromArea = Player.Hand,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      moveVisible = true,
    })
    local choices = {}
    if table.find(target:getCardIds({Player.Hand, Player.Equip}), function(cid)
    return Fk:getCardById(cid).type == Card.TypeTrick end) then
      table.insert(choices, "m_ex__mieji_handovertrick")
    end
    if table.find(target:getCardIds({Player.Hand, Player.Equip}), function(cid)
    return Fk:getCardById(cid).type ~= Card.TypeTrick and not target:prohibitDiscard(card) end) then
      table.insert(choices, "m_ex__mieji_dis2card")
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(target, choices, self.name, "#m_ex__mieji-choice:"..player.id)
    if choice == "m_ex__mieji_handovertrick" then
      local card = room:askForCard(target, 1, 1, false, self.name, false, ".|.|.|.|.|trick", "#m_ex__mieji-handovertrick:" .. player.id)
      room:obtainCard(player, Fk:getCardById(card[1]), true, fk.ReasonGive)
    else
      room:askForDiscard(target, 1, 1, true, self.name, false, ".|.|.|.|.|basic,equip", "#m_ex__mieji-discard")
      room:askForDiscard(target, 1, 1, true, self.name, false, ".|.|.|.|.|basic,equip", "#m_ex__mieji-discard")
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__mieji"] = "灭计",
  [":m_ex__mieji"] = "出牌阶段限一次，你可以将一张黑色锦囊牌置于牌堆顶，令一名其他角色选择一项：1.将一张锦囊牌交给你；2.依次弃置两张非锦囊牌（不足则弃置一张）。",
  ["#m_ex__mieji-choice"] = "灭计：选择交给%src一张锦囊牌，或依次弃置两张非锦囊牌",
  ["m_ex__mieji_handovertrick"] = "交出一张锦囊牌",
  ["m_ex__mieji_dis2card"] = "依次弃置两张非锦囊牌",
  ["#m_ex__mieji-handovertrick"] = "灭计：选择一张锦囊牌交给%src",
  ["#m_ex__mieji-discard"] = "灭计：选择一张非锦囊牌弃置",
  ["$m_ex__mieji1"] = "就是要让你无路可走！",
  ["$m_ex__mieji2"] = "你也逃不了！",
}

liru:addSkill(m_ex__mieji)

Fk:loadTranslationTable{
  --["$m_ex__fencheng1"] = "千里皇城，尽作焦土！",
  --["$m_ex__fencheng2"] = "荣耀、权力、欲望、统统让这大火焚灭吧！",
}
liru:addSkill("fencheng")

local fuhuanghou = General(extension, "m_ex__fuhuanghou", "qun", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__fuhuanghou"] = "界伏皇后",
  ["~m_ex__fuhuanghou"] = "父亲大人，你竟如此优柔寡断……",
}

local m_ex__zhuikong = fk.CreateTriggerSkill{
  name = "m_ex__zhuikong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    target and not target.dead and target ~= player and target.phase == Player.Start and
    player.hp <= target.hp and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#m_ex__zhuikong-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(target, "@@m_ex__zhuikong_prohibit-turn")
    elseif not player.dead  then
      local card = pindian.results[target.id].toCard
      if room:getCardArea(card) == Card.DiscardPile then
        room:obtainCard(player, card, true, fk.ReasonJustMove)
      end
      local slash = Fk:cloneCard("slash")
      if not target.dead and not player.dead and not target:prohibitUse(slash) and not target:isProhibited(player, slash) then
        room:useVirtualCard("slash", nil, target, player, self.name, true)
      end
    end
  end
}
local m_ex__zhuikong_prohibit = fk.CreateProhibitSkill{
  name = "#m_ex__zhuikong_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@m_ex__zhuikong_prohibit-turn") > 0 and from ~= to
  end,
}

m_ex__zhuikong:addRelatedSkill(m_ex__zhuikong_prohibit)

Fk:loadTranslationTable{
  ["m_ex__zhuikong"] = "惴恐",
  [":m_ex__zhuikong"] = "每轮限一次，其他角色的回合开始时，若其体力值不小于你，你可与其拼点。若你赢，其本回合无法使用牌指定除其以外的角色为目标；若你没赢，你获得其拼点的牌，然后其视为对你使用一张【杀】。",
  ["#m_ex__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢则其本回合使用牌只能指定自己为目标",
  ["@@m_ex__zhuikong_prohibit-turn"] = "惴恐",
  ["$m_ex__zhuikong1"] = "万事必须小心为妙。",
  ["$m_ex__zhuikong2"] = "我虽妇人，亦当铲除曹贼。",
}

fuhuanghou:addSkill(m_ex__zhuikong)

local m_ex__qiuyuan = fk.CreateTriggerSkill{
  name = "m_ex__qiuyuan",
  anim_type = "defensive",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      local tos = TargetGroup:getRealTargets(data.tos)
      return table.find(player.room:getOtherPlayers(player), function(p)
        return p.id ~= data.from and not table.contains(tos, p.id) and not target:isProhibited(player, data.card) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = TargetGroup:getRealTargets(data.tos)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.id ~= data.from and not table.contains(tos, p.id) and not target:isProhibited(player, data.card) end), function (p)
        return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#qiuyuan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = self.cost_data
    local card = room:askForCard(room:getPlayerById(to), 1, 1, false, self.name, true, "^slash|.|.|.|.|basic", "#qiuyuan-give::"..player.id)
    if #card > 0 then
      room:obtainCard(player, Fk:getCardById(card[1]), true, fk.ReasonGive)
    else
      TargetGroup:pushTargets(data.targetGroup, to)
      AimGroup:setTargetDone(data.tos, to)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__qiuyuan"] = "求援",
  [":m_ex__qiuyuan"] = "当你成为【杀】的目标时，你可以令另一名其他角色交给你一张除【杀】以外的基本牌，否则也成为此【杀】的目标。",
  ["$m_ex__qiuyuan1"] = "这是最后的希望了。",
  ["$m_ex__qiuyuan2"] = "诛此国贼者，加官进爵！",
  ["#QiuyuanLog"] = "正在处理：%from 成为【%arg】的目标时",
}

fuhuanghou:addSkill(m_ex__qiuyuan)












return extension
