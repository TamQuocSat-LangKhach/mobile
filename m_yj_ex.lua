local extension = Package("m_yj_ex")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["m_yj_ex"] = "手杀-界一将成名",
  ["m_ex"] = "手杀界",
}

local wuguotai = General(extension, "m_ex__wuguotai", "wu", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__wuguotai"] = "界吴国太",
  ["#m_ex__wuguotai"] = "慈怀瑾瑜",
  ["illustrator:m_ex__wuguotai"] = "李秀森",
  ["~m_ex__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",
}

local m_ex__ganlu = fk.CreateActiveSkill{
  name = "m_ex__ganlu",
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  prompt = function ()
    return "#m_ex__ganlu-active:::" .. tostring(Self:getLostHp())
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
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
      room:moveCardTo(dis_cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__ganlu"] = "甘露",
  [":m_ex__ganlu"] = "出牌阶段限一次，你可以选择两名装备区里的牌数之差不大于你已损失的体力值的角色，交换他们装备区里的牌；若你选择的角色中含有你，则不受牌数之差的限制。",
  ["#m_ex__ganlu-active"] = "发动甘露，令两名装备区里的牌数之差不大于%arg的角色交换装备区里的牌，若选择自己则此无限制",
  ["$m_ex__ganlu1"] = "玄德实乃佳婿呀。",
  ["$m_ex__ganlu2"] = "好一个郎才女貌，真是天作之合啊。",
}

wuguotai:addSkill(m_ex__ganlu)

Fk:loadTranslationTable{
  ["$buyi_m_ex__wuguotai1"] = "有我在，定保贤婿无虞！",
  ["$buyi_m_ex__wuguotai2"] = "东吴岂容汝等儿戏！",
}

wuguotai:addSkill("buyi")

local m_ex__xusheng = General(extension, "m_ex__xusheng", "wu", 4)

Fk:loadTranslationTable{
  ["m_ex__xusheng"] = "界徐盛",
  ["#m_ex__xusheng"] = "江东的铁壁",
  ["cv:m_ex__xusheng"] = "金垚",
  ["illustrator:m_ex__xusheng"] = "铁杵文化",
  ["~m_ex__xusheng"] = "盛只恨，不能再为主公，破敌致胜了。",
}

local m_ex__pojun = fk.CreateTriggerSkill{
  name = "m_ex__pojun",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" then
      if event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and to.hp > 0 and not to:isNude()
      elseif event == fk.DamageCaused then
        return U.damageByCardEffect(player.room)
        and #player:getCardIds(Player.Hand) >= #data.to:getCardIds(Player.Hand) and
        #player:getCardIds(Player.Equip) >= #data.to:getCardIds(Player.Equip)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.DamageCaused or player.room:askForSkillInvoke(player, self.name, nil, "#m_ex__pojun-invoke::"..data.to)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      room:doIndicate(player.id, {data.to})
      local to = room:getPlayerById(data.to)
      local cards = room:askForCardsChosen(player, to, 1, to.hp, "he", self.name)
      to:addToPile("$m_ex__pojun", cards, false, self.name)
    else
      data.damage = data.damage + 1
    end
  end,
}

local m_ex__pojun_delay = fk.CreateTriggerSkill{
  name = "#m_ex__pojun_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$m_ex__pojun") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$m_ex__pojun"), Player.Hand, player, fk.ReasonPrey, "m_ex__pojun")
  end,
}

m_ex__pojun:addRelatedSkill(m_ex__pojun_delay)
m_ex__xusheng:addSkill(m_ex__pojun)

Fk:loadTranslationTable{
  ["m_ex__pojun"] = "破军",
  ["#m_ex__pojun_delay"] = "破军",
  [":m_ex__pojun"] = "①当你使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值）；若如此做，当前回合结束时，该角色获得这些牌。②当你使用【杀】对手牌数与装备区里的牌数均不大于你的目标角色造成伤害时，此伤害+1。",

  ["#m_ex__pojun-invoke"] = "是否对%dest发动 破军",
  ["$m_ex__pojun"] = "破军",

  ["$m_ex__pojun1"] = "犯大吴疆土者，盛必击而破之！",
  ["$m_ex__pojun2"] = "若敢来犯，必叫你大败而归！",
}

local gaoshun = General(extension, "m_ex__gaoshun", "qun", 4)

Fk:loadTranslationTable{
  ["m_ex__gaoshun"] = "界高顺",
  ["#m_ex__gaoshun"] = "攻无不克",
  ["illustrator:m_ex__gaoshun"] = "蛋费鸡丁",
  ["~m_ex__gaoshun"] = "可叹主公知而不用啊！",
}

local m_ex__xianzhen = fk.CreateActiveSkill{
  name = "m_ex__xianzhen",
  anim_type = "offensive",
  prompt = "#m_ex__xianzhen-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)

    if pindian.fromCard and pindian.fromCard.trueName == "slash" then
      room:addPlayerMark(player, "@@m_ex__xianzhen_maxcards-turn")
    end
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(target, "@@m_ex__xianzhen-phase")
      local targetRecorded = type(player:getMark("m_ex__xianzhen_target-phase")) == "table" and player:getMark("m_ex__xianzhen_target-phase") or {}
      table.insertIfNeed(targetRecorded, target.id)
      room:setPlayerMark(player, "m_ex__xianzhen_target-phase", targetRecorded)
    else
      room:addPlayerMark(player, "m_ex__xianzhen_prohibit-phase")
    end
  end,
}

local m_ex__xianzhen_armor_invalidity = fk.CreateTriggerSkill{
  name = "#m_ex__xianzhen_armor_invalidity",
  mute = true,
  frequency = Skill.Compulsory,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return player == target and type(player:getMark("m_ex__xianzhen_target-phase")) == "table"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if use_event == nil then return end
    local targetRecorded = player:getMark("m_ex__xianzhen_target-phase")
    for _, id in ipairs(targetRecorded) do
      room:addPlayerMark(room:getPlayerById(id), fk.MarkArmorNullified)
    end
    use_event:addCleaner(function()
      for _, id in ipairs(targetRecorded) do
        room:removePlayerMark(room:getPlayerById(id), fk.MarkArmorNullified)
      end
    end)
  end,
}

local m_ex__xianzhen_targetmod = fk.CreateTargetModSkill{
  name = "#m_ex__xianzhen_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    if card and to then
      local targetRecorded = player:getMark("m_ex__xianzhen_target-phase")
      return type(targetRecorded) == "table" and table.contains(targetRecorded, to.id)
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    if card and to then
      local targetRecorded = player:getMark("m_ex__xianzhen_target-phase")
      return type(targetRecorded) == "table" and table.contains(targetRecorded, to.id)
    end
  end,
}
local m_ex__xianzhen_prohibit = fk.CreateProhibitSkill{
  name = "#m_ex__xianzhen_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("m_ex__xianzhen_prohibit-phase") > 0 and card.trueName == "slash"
  end,
}
local m_ex__xianzhen_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__xianzhen_maxcards",
  exclude_from = function(self, player, card)
    return player:getMark("@@m_ex__xianzhen_maxcards-turn") > 0 and card.trueName == "slash"
  end,
}

m_ex__xianzhen:addRelatedSkill(m_ex__xianzhen_armor_invalidity)
m_ex__xianzhen:addRelatedSkill(m_ex__xianzhen_targetmod)
m_ex__xianzhen:addRelatedSkill(m_ex__xianzhen_prohibit)
m_ex__xianzhen:addRelatedSkill(m_ex__xianzhen_maxcards)

Fk:loadTranslationTable{
  ["m_ex__xianzhen"] = "陷阵",
  [":m_ex__xianzhen"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，此出牌阶段你无视该角色的防具，对其使用牌没有距离和次数限制；若你没赢，此出牌阶段你不能使用【杀】。若你发动“陷阵”拼点的牌为【杀】，则本回合你的【杀】不计入手牌上限。",
  ["#m_ex__xianzhen-active"] = "发动陷阵，选择与你拼点的角色",
  ["@@m_ex__xianzhen-phase"] = "陷阵",
  ["@@m_ex__xianzhen_maxcards-turn"] = "陷阵",
  ["$m_ex__xianzhen1"] = "陷阵之志，有死无生！",
  ["$m_ex__xianzhen2"] = "攻则破城，战则克敌。",
}

gaoshun:addSkill(m_ex__xianzhen)

local m_ex__jinjiu = fk.CreateFilterSkill{
  name = "m_ex__jinjiu",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  card_filter = function(self, card, player, isJudgeEvent)
    return player:hasSkill(self) and card.name == "analeptic" and
    (table.contains(player.player_cards[Player.Hand], card.id) or isJudgeEvent)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}

local m_ex__jinjiu_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__jinjiu_trigger",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(m_ex__jinjiu.name) and data.card and data.card.trueName == "slash" then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if parentUseData then
        local drankBuff = parentUseData and (parentUseData.data[1].extra_data or {}).drankBuff or 0
        if drankBuff > 0 then
          self.cost_data = drankBuff
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(m_ex__jinjiu.name)
    player.room:notifySkillInvoked(player, m_ex__jinjiu.name, "defensive")
    data.damage = data.damage - self.cost_data
  end,
}

local m_ex__jinjiu_prohibit = fk.CreateProhibitSkill{
  name = "#m_ex__jinjiu_prohibit",
  prohibit_use = function(self, player, card)
    if card.name == "analeptic" then
      return table.find(Fk:currentRoom().alive_players, function(p)
        return p.phase ~= Player.NotActive and p:hasSkill(m_ex__jinjiu.name) and p ~= player
      end)
    end
  end,
}

m_ex__jinjiu:addRelatedSkill(m_ex__jinjiu_trigger)
m_ex__jinjiu:addRelatedSkill(m_ex__jinjiu_prohibit)

Fk:loadTranslationTable{
  ["m_ex__jinjiu"] = "禁酒",
  [":m_ex__jinjiu"] = "锁定技，你的【酒】均枧为【杀】；当你受到【酒】【杀】造成的伤害时，此伤害-X （X为增加此【杀】伤害的【酒】张数）。你的回合内，其他角色无法使用【酒】。",
  ["$m_ex__jinjiu1"] = "耽此黄汤，岂不误事？",
  ["$m_ex__jinjiu2"] = "陷阵营中，不可饮酒。",
}

gaoshun:addSkill(m_ex__jinjiu)

local yujin = General(extension, "m_ex__yujin", "wei", 4)

Fk:loadTranslationTable{
  ["m_ex__yujin"] = "界于禁",
  ["#m_ex__yujin"] = "讨暴坚垒",
  ["illustrator:m_ex__yujin"] = "biou09",
  ["~m_ex__yujin"] = "如今临危处难，却负丞相三十年之赏识，唉……",
}

local m_ex__jieyue_select = fk.CreateActiveSkill{
  name = "m_ex__jieyue_select",
  can_use = Util.FalseFunc,
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

Fk:addSkill(m_ex__jieyue_select)

local m_ex__jieyue = fk.CreateTriggerSkill{
  name = "m_ex__jieyue",
  anim_type = "defensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player),
    Util.IdMapper), 1, 1, ".", "#m_ex__jieyue-choose", self.name, true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:obtainCard(to, self.cost_data[2], false, fk.ReasonGive, player.id)
    if player.dead or to.dead then return false end
    local _, ret = room:askForUseActiveSkill(to, "m_ex__jieyue_select", "#m_ex__jieyue-select:" .. player.id, true)
    if ret then
      local cards = table.filter(to:getCardIds{Player.Hand, Player.Equip}, function (id)
        return not (table.contains(ret.cards, id) or to:prohibitDiscard(Fk:getCardById(id)))
      end)
      if #cards > 0 then
        room:throwCard(cards, self.name, to)
      end
    else
      room:drawCards(player, 3, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__jieyue"] = "节钺",
  ["m_ex__jieyue_select"] = "节钺",
  [":m_ex__jieyue"] = "结束阶段，你可以将一张牌交给一名其他角色，然后其选择一项：1.保留手牌和装备区内的各一张牌，然后弃置其余的牌；2.令你摸三张牌。",
  ["#m_ex__jieyue-choose"] = "节钺：可以选择一张牌交给一名其他角色",
  ["#m_ex__jieyue-select"] = "节钺：选择一张手牌和一张装备区里的牌保留，弃置其他的牌；或点取消则令%src摸三张牌",
  ["$m_ex__jieyue1"] = "按丞相之命，此部今由余统摄！",
  ["$m_ex__jieyue2"] = "奉法行令，事上之节，岂有宽宥之理？",
}

yujin:addSkill(m_ex__jieyue)

local caozhi = General(extension, "m_ex__caozhi", "wei", 3)

Fk:loadTranslationTable{
  ["m_ex__caozhi"] = "界曹植",
  ["#m_ex__caozhi"] = "八斗之才",
  ["illustrator:m_ex__caozhi"] = "青岛磐蒲",
  ["~m_ex__caozhi"] = "先民谁不死，知命复何忧？",
}

Fk:loadTranslationTable{
  ["$luoying_m_ex__caozhi1"] = "转蓬离本根，飘摇随长风。",
  ["$luoying_m_ex__caozhi2"] = "高树多悲风，海水扬其波。",
}

caozhi:addSkill("luoying")

local m_ex__jiushi = fk.CreateViewAsSkill{
  name = "m_ex__jiushi",
  anim_type = "support",
  prompt = "#m_ex__jiushi-active",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
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
        return not player.faceup and not (data.extra_data or {}).m_ex__jiushicheck
      elseif event == fk.TurnedOver then
        return player:usedSkillTimes("m_ex__chengzhang", Player.HistoryGame) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.TurnedOver or player.room:askForSkillInvoke(player, m_ex__jiushi.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, m_ex__jiushi.name)
    player:broadcastSkillInvoke(m_ex__jiushi.name)
    if event == fk.Damaged then
      player:turnOver()
      if player:usedSkillTimes("m_ex__chengzhang", Player.HistoryGame) > 0 then return end
    end
    if not player.dead then
      local cards = player.room:getCardsFromPileByRule(".|.|.|.|.|trick")
      if #cards > 0 then
        room:obtainCard(player, cards[1], false, fk.ReasonJustMove, player.id, m_ex__jiushi.name)
      end
    end
  end,

  refresh_events = {fk.DamageInflicted},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.faceup
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.m_ex__jiushicheck = true
  end,
}
m_ex__jiushi:addRelatedSkill(m_ex__jiushi_trigger)

Fk:loadTranslationTable{
  ["m_ex__jiushi"] = "酒诗",
  ["#m_ex__jiushi_trigger"] = "酒诗",
  [":m_ex__jiushi"] = "当你需要使用【酒】时，若你的武将牌正面向上，你可以翻面，视为使用一张【酒】；当你受到伤害后，若你的武将牌背面向上，你可以翻面并随机获得牌堆中的一张锦囊牌。",
  ["#m_ex__jiushi-active"] = "发动酒诗，翻面来视为使用一张【酒】",
  ["$m_ex__jiushi1"] = "乐饮过三爵，缓带倾庶羞。",
  ["$m_ex__jiushi2"] = "归来宴平乐，美酒斗十千。",
}

caozhi:addSkill(m_ex__jiushi)

local m_ex__chengzhang = fk.CreateTriggerSkill{
  name = "m_ex__chengzhang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
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
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      player.room:setPlayerMark(player, "@m_ex__chengzhang", player:getMark("m_ex__chengzhang_count"))
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__chengzhang"] = "成章",
  [":m_ex__chengzhang"] = "觉醒技，准备阶段，若你造成的伤害与受到的伤害值之和累计7点或以上，则你回复1点体力并摸1张牌，然后修改〖酒诗〗（删去获得锦囊牌的效果）。",
  ["@m_ex__chengzhang"] = "成章",
  ["$m_ex__chengzhang1"] = "弦急悲声发，聆我慷慨言。",
  ["$m_ex__chengzhang2"] = "盛时不再来，百年忽我遒。",
}

caozhi:addSkill(m_ex__chengzhang)

local lingtong = General(extension, "m_ex__lingtong", "wu", 4)

Fk:loadTranslationTable{
  ["m_ex__lingtong"] = "界凌统",
  ["#m_ex__lingtong"] = "豪情烈胆",
  ["illustrator:m_ex__lingtong"] = "青岛磐蒲",
  ["~m_ex__lingtong"] = "先……停一下吧……",
}

local m_ex__xuanfeng = fk.CreateTriggerSkill{
  name = "m_ex__xuanfeng",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
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
      elseif event == fk.EventPhaseEnd then
        if target == player and player.phase == Player.Discard then
          local x = 0
          local logic = player.room.logic
          logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.skillName == "game_rule" then
                x = x + #move.moveInfo
                if x > 1 then return true end
              end
            end
            return false
          end, Player.HistoryTurn)
          return x > 1
        end
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
          return not p:isNude() end), Util.IdMapper)
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
  ["#m_ex__zhonghui"] = "桀骜的野心家",
  ["illustrator:m_ex__zhonghui"] = "monkey",
  ["~m_ex__zhonghui"] = "父亲，吾能自知。却终不能自制……",
}

local m_ex__quanji = fk.CreateTriggerSkill{
  name = "m_ex__quanji",
  anim_type = "masochism",
  derived_piles = "m_ex__zhonghui_power",
  events = {fk.Damaged, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
    (event == fk.Damaged or (player.phase == Player.Play and player:getHandcardNum() > player.hp))
  end,
  on_trigger = function(self, event, target, player, data)
    local x = (event == fk.Damaged) and data.damage or 1
    self.cancel_cost = false
    for i = 1, x do
      if self.cancel_cost or not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if not (player.dead or player:isKongcheng()) then
      local card = room:askForCard(player, 1, 1, false, self.name, false, nil, "#m_ex__quanji-push")
      player:addToPile("m_ex__zhonghui_power", card, true, self.name)
    end
  end,
}
local m_ex__quanji_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__quanji_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(m_ex__quanji) then
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
  ["$m_ex__quanji1"] = "缓急不在一时，吾等慢慢来过。",
  ["$m_ex__quanji2"] = "善算轻重，权审其宜。",
}

zhonghui:addSkill(m_ex__quanji)

local m_ex__zili = fk.CreateTriggerSkill{
  name = "m_ex__zili",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
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
    local choice = room:askForChoice(player, choices, self.name, nil, nil, {"draw2", "recover"})
    if choice == "draw2" then
      room:drawCards(player, 2, self.name)
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
  prompt = "#m_ex__paiyi-active",
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
    if not target.dead then
      room:drawCards(target, 2, self.name)
    end
    if not player.dead and not target.dead and #target.player_cards[Player.Hand] > #player.player_cards[Player.Hand] then
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
  ["#m_ex__paiyi-active"] = "发动排异，选择一张“权”牌置入弃牌堆并选择一名角色，令其摸两张牌",
  ["$m_ex__paiyi1"] = "坏吾大计者，罪死不赦！",
  ["$m_ex__paiyi2"] = "攻讦此子，祸咎已除！",
}

zhonghui:addRelatedSkill(m_ex__paiyi)

local gongsunzan = General(extension, "m_ex__gongsunzan", "qun", 4)
gongsunzan:addSkill("qiaomeng")
local m_ex__yicong = fk.CreateDistanceSkill{
  name = "m_ex__yicong",
  correct_func = function(self, from, to)
    if from:hasSkill(self) then
      return - math.max(0, from.hp - 1)
    end
    if to:hasSkill(self) then
      return math.max(0, to:getLostHp() - 1)
    end
    return 0
  end,
}
gongsunzan:addSkill(m_ex__yicong)
Fk:loadTranslationTable{
  ["m_ex__gongsunzan"] = "界公孙瓒",
  ["#m_ex__gongsunzan"] = "白马将军",
  ["illustrator:m_ex__gongsunzan"] = "fingerling",

  ["m_ex__yicong"] = "义从",
  [":m_ex__yicong"] = "锁定技，你计算与其他角色的距离-X（X为你的体力值-1）；其他角色计算与你的距离+Y（Y为你已损失的体力值-1）。",

  ["$qiaomeng_m_ex__gongsunzan1"] = "夺汝兵刃战马，尔等必败无疑。",
  ["$qiaomeng_m_ex__gongsunzan2"] = "摧敌思折枯，荡寇如反掌。",
  ["~m_ex__gongsunzan"] = "啊！（马叫声）",
}

local liubiao = General(extension, "m_ex__liubiao", "qun", 3)

Fk:loadTranslationTable{
  ["m_ex__liubiao"] = "界刘表",
  ["#m_ex__liubiao"] = "跨蹈汉南",
  ["illustrator:m_ex__liubiao"] = "光域",
  ["~m_ex__liubiao"] = "垂垂老矣，已忘壮年雄心……",
}

Fk:loadTranslationTable{
  ["$re__zishou_m_ex__liubiao1"] = "忍时待机，以期坐收渔利！",
  ["$re__zishou_m_ex__liubiao2"] = "按兵不动，徐图荆襄霸业！",
}

liubiao:addSkill("re__zishou")

local m_ex__zongshi = fk.CreateTriggerSkill{
  name = "m_ex__zongshi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and player:getHandcardNum() > player.hp
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@@m_ex__zongshi-turn")
  end,
}
local m_ex__zongshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__zongshi_maxcards",
  correct_func = function(self, player)
    if player:hasSkill(m_ex__zongshi) then
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
  bypass_times = function(self, player, skill)
    return player:getMark("@@m_ex__zongshi-turn") > 0 and skill.trueName == "slash_skill"
  end,
}
m_ex__zongshi:addRelatedSkill(m_ex__zongshi_maxcards)
m_ex__zongshi:addRelatedSkill(m_ex__zongshi_targetmod)

Fk:loadTranslationTable{
  ["m_ex__zongshi"] = "宗室",
  [":m_ex__zongshi"] = "锁定技，你的手牌上限+X（X为势力数）。准备阶段，若你的手牌数大于体力值，本回合你使用【杀】无次数限制。",
  ["@@m_ex__zongshi-turn"] = "宗室",
  ["$m_ex__zongshi1"] = "这天下，尽是大汉疆土！",
  ["$m_ex__zongshi2"] = "汉室之威，犹然彰存！",
}

liubiao:addSkill(m_ex__zongshi)

local bulianshi = General(extension, "m_ex__bulianshi", "wu", 3, 3, General.Female)

local m_ex__bulianshi_win = fk.CreateActiveSkill{ name = "m_ex__bulianshi_win_audio" }
m_ex__bulianshi_win.package = extension
Fk:addSkill(m_ex__bulianshi_win)

Fk:loadTranslationTable{
  ["m_ex__bulianshi"] = "界步练师",
  ["#m_ex__bulianshi"] = "无冕之后",
  ["illustrator:m_ex__bulianshi"] = "凡果",
  ["~m_ex__bulianshi"] = "今生先君逝，来世再侍君……",
  ["$m_ex__bulianshi_win_audio"] = "壮我江东，人才济济！",
}

local m_ex__anxu = fk.CreateActiveSkill{
  name = "m_ex__anxu",
  anim_type = "control",
  prompt = "#m_ex__anxu-active",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
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
    room:obtainCard(target1.id, card, false, fk.ReasonPrey)
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
  ["#m_ex__anxu-active"] = "发动安恤，选择两名其他角色，令先选择的角色获得后选择的角色的一张牌",
  ["#m_ex__anxu-draw"] = "安恤：是否令手牌数较少的%dest摸一张牌",
  ["$m_ex__anxu1"] = "贤淑重礼，育人育己。",
  ["$m_ex__anxu2"] = "雨露均沾，后宫不乱。",
}

bulianshi:addSkill(m_ex__anxu)

Fk:loadTranslationTable{
  ["$zhuiyi_m_ex__bulianshi1"] = "化作桃园只为君。",
  ["$zhuiyi_m_ex__bulianshi2"] = "魂若有灵，当助夫君。",
}

bulianshi:addSkill("zhuiyi")

local liaohua = General(extension, "m_ex__liaohua", "shu", 4)

Fk:loadTranslationTable{
  ["m_ex__liaohua"] = "界廖化",
  ["#m_ex__liaohua"] = "历尽沧桑",
  ["illustrator:m_ex__liaohua"] = "聚一工作室",
  ["~m_ex__liaohua"] = "兴复大业，就靠你们了！",
}

local m_ex__dangxian = fk.CreateTriggerSkill{
  name = "m_ex__dangxian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.room:getCardsFromPileByRule("slash", 1, "discardPile")
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
    player:gainAnExtraPhase(Player.Play)
    --FIXME：额外阶段需要延迟执行！！
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
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
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
      return p == player or p.hp < player.hp
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
  ["#m_ex__caozhang"] = "黄须儿",
  ["illustrator:m_ex__caozhang"] = "枭瞳",
  ["~m_ex__caozhang"] = "黄须金甲，也难敌骨肉毒心！",
}

local m_ex__jiangchi_select = fk.CreateActiveSkill{
  name = "#m_ex__jiangchi_select",
  can_use = Util.FalseFunc,
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
    return target == player and player:hasSkill(self) and player.phase == Player.Play
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
      player:broadcastSkillInvoke(self.name, 2)
      room:throwCard(self.cost_data, self.name, player)
      room:addPlayerMark(player, "@@m_ex__jiangchi_targetmod-phase")
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:broadcastSkillInvoke(self.name, 1)
      player:drawCards(1, self.name)
      room:addPlayerMark(player, "@@m_ex__jiangchi_prohibit-phase")
    end
  end,
}
local m_ex__jiangchi_targetmod = fk.CreateTargetModSkill{
  name = "#m_ex__jiangchi_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@m_ex__jiangchi_targetmod-phase") > 0 and scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("@@m_ex__jiangchi_targetmod-phase") > 0
  end,
}
local m_ex__jiangchi_prohibit = fk.CreateProhibitSkill{
  name = "#m_ex__jiangchi_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@m_ex__jiangchi_prohibit-phase") > 0 and card.trueName == "slash"
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
  ["#m_ex__zhuran"] = "不动之督",
  ["illustrator:m_ex__zhuran"] = "zoo",
  ["~m_ex__zhuran"] = "大耳贼就在眼前，快追……",
}

local m_ex__danshou = fk.CreateTriggerSkill{
  name = "m_ex__danshou",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target and target.phase == Player.Finish and target ~= player and player:hasSkill(self) and
    #player:getCardIds{ Player.Hand, Player.Equip } >= player:getMark("@m_ex__danshou_count-turn")
  end,
  on_cost = function(self, event, target, player, data)
    local x = player:getMark("@m_ex__danshou_count-turn")
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
    player:broadcastSkillInvoke(self.name)
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
    return target == player and player:hasSkill(self, true) and
    (data.card.type == Card.TypeBasic or data.card.type == Card.TypeTrick) and
    data.from ~= player.id and data.from == player.room.current.id
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@m_ex__danshou_count-turn")
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

local m_ex__panzhangmazhong = General(extension, "m_ex__panzhangmazhong", "wu", 4)
local m_ex__duodao = fk.CreateTriggerSkill{
  name = "m_ex__duodao",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and #data.from:getEquipments(Card.SubtypeWeapon) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#m_ex__duodao-invoke::"..data.from.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.from:getEquipments(Card.SubtypeWeapon), false, fk.ReasonPrey)
  end
}
m_ex__panzhangmazhong:addSkill(m_ex__duodao)
local m_ex__anjian = fk.CreateTriggerSkill{
  name = "m_ex__anjian",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash"
    and not player.room:getPlayerById(data.to):inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if room:askForChoice(player, {"disresponsive", "m_ex__anjian_damage"}, self.name, "#m_ex__anjian-choice:"..data.to) == "disresponsive" then
      data.disresponsive = true
    else
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
m_ex__panzhangmazhong:addSkill(m_ex__anjian)
Fk:loadTranslationTable{
  ["m_ex__panzhangmazhong"] = "潘璋马忠",
  ["#m_ex__panzhangmazhong"] = "擒龙伏虎",
  ["illustrator:m_ex__panzhangmazhong"] = "凝聚永恒",

  ["m_ex__duodao"] = "夺刀",
  [":m_ex__duodao"] = "当你受到伤害后，你可以获得伤害来源装备区里的武器牌。",
  ["m_ex__anjian"] = "暗箭",
  [":m_ex__anjian"] = "锁定技，当你使用【杀】指定一名角色为目标后，若你不在其攻击范围内，你选择一项：1.令其不能响应此【杀】；2.此【杀】对其造成的基础伤害值+1。",
  ["#m_ex__duodao-invoke"] = "夺刀：你可以获得 %dest 装备区的武器牌",
  ["#m_ex__anjian-choice"] = "暗箭：令 %src 不能响应此【杀】或受到此【杀】伤害+1",
  ["m_ex__anjian_damage"] = "伤害+1",

  ["$m_ex__duodao1"] = "避其锋芒，夺其兵刃！",
  ["$m_ex__duodao2"] = "好兵器啊！哈哈哈！",
  ["$m_ex__anjian1"] = "看我一箭索命！",
  ["$m_ex__anjian2"] = "明枪易躲，暗箭难防！",
  ["~m_ex__panzhangmazhong"] = "埋伏得这么好，怎会……",
}

local manchong = General(extension, "m_ex__manchong", "wei", 3)

Fk:loadTranslationTable{
  ["m_ex__manchong"] = "界满宠",
  ["#m_ex__manchong"] = "政法兵谋",
  ["designer:m_ex__manchong"] = "Loun老萌",
  ["illustrator:m_ex__manchong"] = "YanBai",
  ["~m_ex__manchong"] = "宠一生为公，无愧忠俭之节。",
}

local m_ex__junxing = fk.CreateActiveSkill{
  name = "m_ex__junxing",
  anim_type = "control",
  prompt = "#m_ex__junxing-active",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local x = #effect.cards
    room:throwCard(effect.cards, self.name, player)
    if target.dead then return end
    if #room:askForDiscard(target, x, x, true, self.name, true, nil, "#m_ex__junxing-discard:::"..x) == 0 then
      target:turnOver()
      if target.dead then return end
      room:drawCards(target, x, self.name)
    else
      if target.dead then return end
      room:loseHp(target, 1, self.name)
    end
  end
}

Fk:loadTranslationTable{
  ["m_ex__junxing"] = "峻刑",
  [":m_ex__junxing"] = "出牌阶段限一次，你可以弃置任意张手牌并令一名其他角色选择一项：1.弃置等量的牌并失去1点体力；2.翻面，然后摸等量的牌。",
  ["#m_ex__junxing-active"] = "发动峻刑，选择任意张手牌弃置并选择一名其他角色",
  ["#m_ex__junxing-discard"] = "峻刑：选择弃置%arg张牌并失去1点体力，或点取消则翻面并摸%arg张牌",
  ["$m_ex__junxing1"] = "严法尚公，岂分贵贱而异施？",
  ["$m_ex__junxing2"] = "情理可容之事，法未必能容！",
}

manchong:addSkill(m_ex__junxing)

Fk:loadTranslationTable{
  ["$yuce_m_ex__manchong1"] = "骄之以利，示之以慑！",
  ["$yuce_m_ex__manchong2"] = "虽举得于外，则福生于内矣。",
}

manchong:addSkill("yuce")

local jianyong = General(extension, "m_ex__jianyong", "shu", 3)
local m_ex__qiaoshui = fk.CreateActiveSkill{
  name = "m_ex__qiaoshui",
  anim_type = "control",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({to}, self.name)
    if pindian.results[to.id].winner == player then
      room:addPlayerMark(player, "@@m_ex__qiaoshui-phase", 1)
    else
      room:setPlayerMark(player, "m_ex__qiaoshui_fail-phase", 1)
    end
  end,
}
local m_ex__qiaoshui_delay = fk.CreateTriggerSkill{
  name = "#m_ex__qiaoshui_delay",
  events = {fk.AfterCardTargetDeclared},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@m_ex__qiaoshui-phase") > 0 and data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@m_ex__qiaoshui-phase", 0)
    local targets = room:getUseExtraTargets(data)
    table.insertTableIfNeed(targets, TargetGroup:getRealTargets(data.tos))
    if #targets == 0 then return false end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#m_ex__qiaoshui-choose:::"..data.card:toLogString(), self.name, true)
    if #tos > 0 then
      local to = tos[1]
      if TargetGroup:includeRealTargets(data.tos, to) then
        TargetGroup:removeTarget(data.tos, to)
      else
        table.insert(data.tos, {to})
        room:sendLog{
          type = "#AddTargetsBySkill",
          from = player.id,
          to = {to},
          arg = self.name,
          arg2 = data.card:toLogString()
        }
      end
    end
  end,
}
m_ex__qiaoshui:addRelatedSkill(m_ex__qiaoshui_delay)
local m_ex__qiaoshui_prohibit = fk.CreateProhibitSkill{
  name = "#m_ex__qiaoshui_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("m_ex__qiaoshui_fail-phase") > 0 and card and card.type == Card.TypeTrick
  end,
}
m_ex__qiaoshui:addRelatedSkill(m_ex__qiaoshui_prohibit)
jianyong:addSkill(m_ex__qiaoshui)
local m_ex__zongshij = fk.CreateTriggerSkill{
  name = "m_ex__zongshij",
  anim_type = "drawcard",
  events = {fk.PindianResultConfirmed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return data.from == player or data.to == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local top = room:getNCards(1)
    local card_data = { { "Top", top } }
    local cards = {}
    local min_num = 999
    for _, c in ipairs({data.fromCard, data.toCard}) do
      if room:getCardArea(c) == Card.Processing then
        table.insert(cards, c)
        min_num = math.min(min_num, c.number)
      end
    end
    if #cards > 0 then
      local ids = table.map(table.filter(cards, function(c) return c.number == min_num end), function(c) return c:getEffectiveId() end)
      table.insert(card_data, { "$PindianCard", ids })
    end
    local get = room:askForCardChosen(player, player, { card_data = card_data }, self.name, "#m_ex__zongshij-card")
    if get ~= top[1] then
      table.insert(room.draw_pile, 1, top[1])
      room:doBroadcastNotify("UpdateDrawPile", tostring(#room.draw_pile))
    end
    room:obtainCard(player, get, false, fk.ReasonPrey)
  end,
}
jianyong:addSkill(m_ex__zongshij)
Fk:loadTranslationTable{
  ["m_ex__jianyong"] = "界简雍",
  ["#m_ex__jianyong"] = "悠游风议",
  ["illustrator:m_ex__jianyong"] = "zoo",
  
  ["m_ex__qiaoshui"] = "巧说",
  [":m_ex__qiaoshui"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，本阶段你使用下一张基本牌或普通锦囊牌可以多选择或少选择一个目标；若你没赢，本阶段你不能使用锦囊牌。",
  ["#m_ex__qiaoshui_delay"] = "巧说",
  ["#m_ex__qiaoshui-choose"] = "巧说：你可以为%arg增加/减少一个目标",
  ["@@m_ex__qiaoshui-phase"] = "巧说",

  ["m_ex__zongshij"] = "纵适",
  [":m_ex__zongshij"] = "当你拼点后，你观看牌堆顶的一张牌，并可以选择一项：获得牌堆顶的这张牌，或获得两张拼点牌中点数较小的一张。",
  ["#m_ex__zongshij-card"] = "纵适：选择一张获得",
  ["$PindianCard"] = "拼点牌",

  ["$m_ex__qiaoshui1"] = "此事听我一言，定有分明之理。",
  ["$m_ex__qiaoshui2"] = "今日之事，听我一言便是。",
  ["$m_ex__zongshij1"] = "空拘小节，难成大事。",
  ["$m_ex__zongshij2"] = "繁文缛节，不过是缚人之物。",
  ["~m_ex__jianyong"] = "行事无矩，为人所恶矣。",
}

local liru = General(extension, "m_ex__liru", "qun", 3)

Fk:loadTranslationTable{
  ["m_ex__liru"] = "界李儒",
  ["#m_ex__liru"] = "魔仕",
  ["illustrator:m_ex__liru"] = "三道纹",
  ["~m_ex__liru"] = "吾等皆死于妇人之手矣！",
}

local m_ex__juece = fk.CreateTriggerSkill{
  name = "m_ex__juece",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
    and #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from and move.from ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local n = 0
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from and move.from ~= player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              table.insertIfNeed(targets, move.from)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    if #targets == 0 then return false end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#m_ex__juece-choose", self.name, true)
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
}

Fk:loadTranslationTable{
  ["m_ex__juece"] = "绝策",
  [":m_ex__juece"] = "结束阶段，你可以对本回合失去过牌的一名其他角色造成1点伤害。",
  ["#m_ex__juece-choose"] = "绝策：选择一名本回合失去过牌的其他角色，对其造成1点伤害",
  
  ["$m_ex__juece1"] = "束手就擒吧！",
  ["$m_ex__juece2"] = "斩草除根，以绝后患！",
}

liru:addSkill(m_ex__juece)

local m_ex__mieji = fk.CreateActiveSkill{
  name = "m_ex__mieji",
  anim_type = "control",
  prompt = "#m_ex__mieji-active",
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
    if target.dead then return end
    local choices = {}
    if not player.dead and table.find(target:getCardIds({Player.Hand, Player.Equip}), function(cid)
    return Fk:getCardById(cid).type == Card.TypeTrick end) then
      table.insert(choices, "m_ex__mieji_handovertrick")
    end
    if table.find(target:getCardIds({Player.Hand, Player.Equip}), function(cid)
    return Fk:getCardById(cid).type ~= Card.TypeTrick and not target:prohibitDiscard(Fk:getCardById(cid)) end) then
      table.insert(choices, "m_ex__mieji_dis2card")
    end
    if #choices == 0 then return end
    local choice = room:askForChoice(target, choices, self.name, "#m_ex__mieji-choice:"..player.id, nil,
        {"m_ex__mieji_handovertrick", "m_ex__mieji_dis2card"})
    if choice == "m_ex__mieji_handovertrick" then
      local card = room:askForCard(target, 1, 1, false, self.name, false, ".|.|.|.|.|trick", "#m_ex__mieji-handovertrick:" .. player.id)
      room:obtainCard(player, Fk:getCardById(card[1]), true, fk.ReasonGive)
    else
      room:askForDiscard(target, 1, 1, true, self.name, false, ".|.|.|.|.|basic,equip", "#m_ex__mieji-discard")
      if target.dead then return end
      room:askForDiscard(target, 1, 1, true, self.name, false, ".|.|.|.|.|basic,equip", "#m_ex__mieji-discard")
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__mieji"] = "灭计",
  [":m_ex__mieji"] = "出牌阶段限一次，你可以将一张黑色锦囊牌置于牌堆顶，令一名其他角色选择一项：1.将一张锦囊牌交给你；2.依次弃置两张非锦囊牌（不足则弃置一张）。",
  ["#m_ex__mieji-active"] = "发动灭计，选择一张黑色锦囊牌置于牌堆顶并一名其他角色",
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
  ["$fencheng_m_ex__liru1"] = "千里皇城，尽作焦土！",
  ["$fencheng_m_ex__liru2"] = "荣耀、权力、欲望、统统让这大火焚灭吧！",
}

liru:addSkill("fencheng")

local fuhuanghou = General(extension, "m_ex__fuhuanghou", "qun", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__fuhuanghou"] = "界伏皇后",
  ["#m_ex__fuhuanghou"] = "孤注一掷",
  ["illustrator:m_ex__fuhuanghou"] = "zoo",
  ["~m_ex__fuhuanghou"] = "父亲大人，你竟如此优柔寡断……",
}

local m_ex__zhuikong = fk.CreateTriggerSkill{
  name = "m_ex__zhuikong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    target and not target.dead and target ~= player and target.phase == Player.Start and
    player.hp <= target.hp and player:canPindian(target)
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
    elseif not player.dead then
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

local m_ex__zhuikong_delay = fk.CreateTriggerSkill{
  name = "#m_ex__zhuikong_delay",
  events = {fk.PindianResultConfirmed},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.from == player and data.winner and data.winner ~= player and
        data.toCard and player.room:getCardArea(data.toCard) == Card.Processing then
      local parentPindianEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.Pindian, true)
      if parentPindianEvent then
        local pindianData = parentPindianEvent.data[1]
        return pindianData.reason == m_ex__zhuikong.name
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if not player.dead and data.toCard and player.room:getCardArea(data.toCard) == Card.Processing then
      player.room:obtainCard(player, data.toCard, true, fk.ReasonJustMove)
    end
  end,
}

m_ex__zhuikong:addRelatedSkill(m_ex__zhuikong_delay)
m_ex__zhuikong:addRelatedSkill(m_ex__zhuikong_prohibit)

Fk:loadTranslationTable{
  ["m_ex__zhuikong"] = "惴恐",
  ["#m_ex__zhuikong_delay"] = "惴恐",
  [":m_ex__zhuikong"] = "每轮限一次，其他角色的准备阶段，若其体力值不小于你，你可与其拼点。若你赢，其本回合无法使用牌指定除其以外的角色为目标；若你没赢，你获得其拼点的牌，然后其视为对你使用一张【杀】。",
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
    if target == player and player:hasSkill(self) and data.card.trueName == "slash" then
      local tos = AimGroup:getAllTargets(data.tos)
      return table.find(player.room:getOtherPlayers(player), function(p)
        return p.id ~= data.from and not table.contains(tos, p.id) and not target:isProhibited(p, data.card) end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = AimGroup:getAllTargets(data.tos)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.id ~= data.from and not table.contains(tos, p.id) and not target:isProhibited(p, data.card) end), function (p)
        return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#m_ex__qiuyuan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    --FIXME: cant use "^slash|.|.|.|.|basic"!!
    local ids = table.filter(to:getCardIds("h"),
      function(id) return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "slash"
    end)
    local card = room:askForCard(to, 1, 1, false, self.name, true, tostring(Exppattern{ id = ids }), "#m_ex__qiuyuan-give::"..player.id)
    if #card > 0 then
      room:moveCardTo(card, Player.Hand, player, fk.ReasonGive, self.name, nil, true, to.id)
    else
      AimGroup:addTargets(room, data, to.id)
      AimGroup:setTargetDone(data.tos, to.id)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__qiuyuan"] = "求援",
  [":m_ex__qiuyuan"] = "当你成为【杀】的目标时，你可以令另一名其他角色交给你一张除【杀】以外的基本牌，否则也成为此【杀】的目标。",
  ["#m_ex__qiuyuan-choose"] = "求援：令另一名其他角色交给你一张不为【杀】的基本牌，否则其成为此【杀】额外目标",
  ["#m_ex__qiuyuan-give"] = "求援：你需交给 %dest 一张不为【杀】的基本牌，否则成为此【杀】额外目标",
  ["$m_ex__qiuyuan1"] = "这是最后的希望了。",
  ["$m_ex__qiuyuan2"] = "诛此国贼者，加官进爵！",
}

fuhuanghou:addSkill(m_ex__qiuyuan)

local yufan = General(extension, "m_ex__yufan", "wu", 3)
local zongxuan = fk.CreateActiveSkill{
  name = "m_ex__zongxuan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("m_ex__zongxuan-phase") == 0
  end,
  prompt = "#m_ex__zongxuan",
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "m_ex__zongxuan-phase", 1)
    player:drawCards(1, self.name)
    if not player:isNude() then
      local cards = room:askForCard(player, 1, 1, true, self.name, false, ".", "#m_ex__zongxuan-put")
      room:moveCards({
        from = player.id,
        ids = cards,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = self.name,
        proposer = player.id,
      })
    end
  end,
}
local zongxuan_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__zongxuan_trigger",
  anim_type = "control",
  main_skill = zongxuan,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if player.room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(self.cost_data)
    if #cards > 1 then
      cards = room:askForGuanxing(player, cards, {1, #cards}, nil, self.name, true, {"Top", "zongxuanNoput"}).top
    end
    room:moveCards({
      ids = table.reverse(cards),
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id,
    })
  end,
}
zongxuan:addRelatedSkill(zongxuan_trigger)
yufan:addSkill(zongxuan)
yufan:addSkill("zhiyan")
Fk:loadTranslationTable{
  ["m_ex__yufan"] = "虞翻",
  ["#m_ex__yufan"] = "狂直之士",
  ["m_ex__zongxuan"] = "纵玄",
  [":m_ex__zongxuan"] = "①当你的牌因弃置而置入弃牌堆时，你可以将其中任意张牌置于牌堆顶；②出牌阶段限一次，你可以摸一张牌，然后将一张牌置于牌堆顶。",
  ["#m_ex__zongxuan"] = "你可以摸一张牌，然后将一张牌置于牌堆顶",
  ["#m_ex__zongxuan_trigger"] = "纵玄",
  ["#m_ex__zongxuan-put"] = "纵玄：将一张牌置于牌堆顶",
}

-- yj2014

local chenqun = General(extension, "m_ex__chenqun", "wei", 3)

Fk:loadTranslationTable{
  ["m_ex__chenqun"] = "界陈群",
  ["#m_ex__chenqun"] = "万世臣表",
  ["illustrator:m_ex__chenqun"] = "鬼画府",
  ["~m_ex__chenqun"] = "立身纯且粹，一死复何忧……",
}

local m_ex__dingpin = fk.CreateActiveSkill{
  name = "m_ex__dingpin",
  anim_type = "support",
  prompt = "#m_ex__dingpin-active",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return not (Self:prohibitDiscard(card) or table.contains(Self:getTableMark("m_ex__dingpin_types-turn"), card:getTypeString()))
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not table.contains(Self:getTableMark("m_ex__dingpin_target-turn"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player)
    local judge = {
      who = target,
      reason = self.name,
      pattern = ".|.|spade,club",
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      if not target.dead and target.hp > 0 then
        target:drawCards(math.min(3, target.hp))
        local targetRecorded = player:getTableMark("m_ex__dingpin_target-turn")
        table.insert(targetRecorded, target.id)
        room:setPlayerMark(player, "m_ex__dingpin_target-turn", targetRecorded)
      end
    elseif judge.card.suit == Card.Heart then
      local typesRecorded = player:getTableMark("m_ex__dingpin_types-turn")
      table.removeOne(typesRecorded, Fk:getCardById(effect.cards[1]):getTypeString())
      room:setPlayerMark(player, "m_ex__dingpin_types-turn", typesRecorded)
    elseif judge.card.suit == Card.Diamond then
      player:turnOver()
    end
  end,
}
local m_ex__dingpin_record = fk.CreateTriggerSkill{
  name = "#m_ex__dingpin_record",

  refresh_events = {fk.CardUsing, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player.phase ~= Player.NotActive then
      if event == fk.CardUsing then
        if target == player then
          self.cost_data = {data.card:getTypeString()}
          return true
        end
      elseif event == fk.AfterCardsMove then
        self.cost_data = {}
        for _, move in ipairs(data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.insertIfNeed(self.cost_data, Fk:getCardById(info.cardId):getTypeString())
              end
            end
          end
        end
        return #self.cost_data > 0
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local typesRecorded = player:getTableMark("m_ex__dingpin_types-turn")
    table.forEach(self.cost_data, function (type_string)
      table.insertIfNeed(typesRecorded, type_string)
    end)
    player.room:setPlayerMark(player, "m_ex__dingpin_types-turn", typesRecorded)
  end,
}
m_ex__dingpin:addRelatedSkill(m_ex__dingpin_record)
Fk:loadTranslationTable{
  ["m_ex__dingpin"] = "定品",
  [":m_ex__dingpin"] = "出牌阶段，你可以弃置一张牌（不能是你本回合使用或弃置过的类型）并选择一名角色，令其进行判定，若结果为：黑色，该角色摸X张牌（X为当前体力值且最大为3），然后你于此回合内不能对其发动“定品”；红桃，你此次发动“定品”弃置的牌不计入弃置过的类型；方块，你翻面。",
  ["#m_ex__dingpin-active"] = "发动定品，选择一张牌弃置（不能是你本回合使用或弃置过的类型）并选择一名角色",
  ["$m_ex__dingpin1"] = "察举旧制已隳，简拔当立中正。",
  ["$m_ex__dingpin2"] = "置州郡中正，以九品进退人才。",
}

chenqun:addSkill(m_ex__dingpin)

Fk:loadTranslationTable{
  ["$nos__faen_m_ex__chenqun1"] = "法不可容之事，情或能原宥。",
  ["$nos__faen_m_ex__chenqun2"] = "严刑峻法，万望慎行。",
}

chenqun:addSkill("nos__faen")
--[[

local zhoucang = General(extension, "m_ex__zhoucang", "shu", 4)

Fk:loadTranslationTable{
  ["m_ex__zhoucang"] = "界周仓",
  ["~m_ex__zhoucang"] = "九泉之下，仓陪将军再走一遭……",
}

local m_ex__zhongyong = fk.CreateTriggerSkill{
  name = "m_ex__zhongyong",
  events = {fk.CardUseFinished},
  anim_type = "drawCard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player and player.phase == Player.Play and data.card.trueName == "slash" then
      
      local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
      if table.every(cardlist, function(id) return room:getCardArea(id) == Card.Processing end) then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    
    
    player.room:obtainCard(player, data.card, false)




  end,
}


Fk:loadTranslationTable{
  ["m_ex__zhongyong"] = "忠勇",
  [":m_ex__zhongyong"] = "当你于出牌阶段内使用【杀】结算结束后，若没有目标角色使用【闪】响应过此【杀】，你可以重新获得此【杀】，否则你可以选择一项：1.获得响应此【杀】的【闪】，然后你可以将此【杀】交给另一名其他角色；2.将响应此【杀】的【闪】交给另一名其他角色，然后你本阶段使用【杀】的次数上限+1，你本阶段使用的下一张【杀】基础伤害值+1。你不能使用本回合通过〖忠勇〗获得的牌。",

  ["$m_ex__zhongyong1"] = "关将军，接刀！",
  ["$m_ex__zhongyong2"] = "青龙三停刀，斩敌万千条！",
}

zhoucang:addSkill(m_ex__zhongyong)

]]

local caozhen = General(extension, "m_ex__caozhen", "wei", 4)

Fk:loadTranslationTable{
  ["m_ex__caozhen"] = "界曹真",
  ["#m_ex__caozhen"] = "荷国天督",
  ["illustrator:m_ex__caozhen"] = "鬼画府",
  ["~m_ex__caozhen"] = "雍凉动乱，皆吾之过也……",
}

local m_ex__sidi = fk.CreateTriggerSkill{
  name = "m_ex__sidi",
  anim_type = "control",
  events = {fk.CardUseFinished, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.CardUseFinished and target == player then
      return data.card.sub_type ~= Card.SubtypeDelayedTrick and table.find(player.room.alive_players, function (p)
          return p:getMark("@@m_ex__sidi") == 0 and p ~= player end)
    elseif event == fk.TargetSpecifying then
      return target:getMark("@@m_ex__sidi") > 0 and data.card.sub_type ~= Card.SubtypeDelayedTrick
        and #AimGroup:getAllTargets(data.tos) == 1 and target:getMark(self.name) == data.to
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room.alive_players, function (p)
        return p:getMark("@@m_ex__sidi") == 0 and p ~= player end), function(p)
        return p.id end), 1, 1, "#m_ex__sidi-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    elseif event == fk.TargetSpecifying then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local to = room:getPlayerById(self.cost_data)
      room:addPlayerMark(to, "@@m_ex__sidi")
      local to2 = player.room:askForChoosePlayers(player, table.map(room.alive_players, function(p)
        return p.id end), 1, 1, "#m_ex__sidi-choose2::" .. to.id, self.name, false, true)
      if #to2 > 0 then
        room:setPlayerMark(to, self.name, to2[1])
      end
    elseif event == fk.TargetSpecifying then
      room:doIndicate(player.id, {target.id})
      if data.to == player.id then
        player:drawCards(1, self.name)
      else
        local choices = {"m_ex__sidi_negate", "draw2"}
        if not target.dead and table.every(room.alive_players, function(p) return not p.dying end) then
          choices[1] = "m_ex__sidi_negate_and_damage"
        end
        local choice = room:askForChoice(player, choices, self.name, "#m_ex__sidi-choice::"..target.id..":"..data.card:toLogString())
        if choice == "draw2" then
          player:drawCards(2, self.name)
        elseif choice:startsWith("m_ex__sidi_negate") then
          AimGroup:cancelTarget(data, data.to)
          if not target.dead and table.every(room.alive_players, function(p) return not p.dying end) then
            room:damage{
              from = player,
              to = target,
              damage = 1,
              skillName = self.name,
            }
          end
          room:setPlayerMark(target, "@@m_ex__sidi", 0)
          room:setPlayerMark(target, self.name, 0)
          return true
        end
      end
      room:setPlayerMark(target, "@@m_ex__sidi", 0)
      room:setPlayerMark(target, self.name, 0)
    end
  end,

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    return target == player and target:getMark("@@m_ex__sidi") > 0 and data.card.sub_type ~= Card.SubtypeDelayedTrick and
      not (#AimGroup:getAllTargets(data.tos) == 1 and target:getMark(self.name) == data.to)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@m_ex__sidi", 0)
    player.room:setPlayerMark(target, self.name, 0)
  end,
}

Fk:loadTranslationTable{
  ["m_ex__sidi"] = "司敌",
  [":m_ex__sidi"] = "当你使用除延时锦囊以外的牌结算结束后，可以选择一名还未指定“司敌”目标的其他角色，并为其指定一名“司敌”目标角色（均不可见）。其使用的第一张除延时锦囊以外的牌仅指定“司敌”目标为唯一角色时（否则清除你为其指定的“司敌”目标角色），你根据以下情况执行效果：若目标为你，你摸一张牌；若目标不为你，你选择一项：1.取消之，然后若此时场上没有任何角色处于濒死状态，你对其造成1点伤害；2.你摸两张牌。然后清除你为其指定的“司敌”目标角色。",
  ["#m_ex__sidi-choose"] = "你可发动司敌，选择1名角色，为其指定司敌目标",
  ["#m_ex__sidi-choose2"] = "司敌：为%dest指定司敌目标，若正确，可发动响应效果",
  ["#m_ex__sidi-choice"] = "司敌：选择取消%dest使用的%arg，或摸两张牌",
  ["m_ex__sidi_negate"] = "取消此牌",
  ["m_ex__sidi_negate_and_damage"] = "取消此牌并对使用者造成伤害",
  ["@@m_ex__sidi"] = "司敌",
  ["$m_ex__sidi1"] = "司敌之动，先发而制。",
  ["$m_ex__sidi2"] = "料敌之行，伏兵灭之。",
}

caozhen:addSkill(m_ex__sidi)

local sunluban = General(extension, "m_ex__sunluban", "wu", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__sunluban"] = "界孙鲁班",
  ["#m_ex__sunluban"] = "为虎作伥",
  ["illustrator:m_ex__sunluban"] = "鬼画府",
  ["~m_ex__sunluban"] = "妹妹，姐姐是迫不得已……",
}

local m_ex__zenhui = fk.CreateTriggerSkill{
  name = "m_ex__zenhui",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      (data.card.trueName == "slash" or (data.card.color == Card.Black and data.card:isCommonTrick())) and data.firstTarget and
      U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and #player.room:getUseExtraTargets(data, true, true) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, room:getUseExtraTargets(data, true, true), 1, 1,
    "#m_ex__zenhui-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if not to:isNude() and room:askForChoice(player, {"m_ex__zenhui_becomeuser", "m_ex__zenhui_becometarget"},
        self.name, "@m_ex__zenhui-choice::" .. to.id) == "m_ex__zenhui_becomeuser" then
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player.id, card, false, fk.ReasonPrey)
      data.from = to.id
    else
      AimGroup:addTargets(room, data, to.id)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__zenhui"] = "谮毁",
  [":m_ex__zenhui"] = "出牌阶段限一次，当你使用【杀】或黑色普通锦囊牌指定一名角色为唯一目标时，你可以选择另一名能成为此牌合法目标的角色，并选择一项：1.获得该角色的一张牌，然后其代替你成为此牌的使用者；2.令其也成为此牌的目标。",
  ["#m_ex__zenhui-choose"] = "谮毁：选择一名能成为%arg的目标的角色",
  ["@m_ex__zenhui-choice"] = "谮毁：选择一项令%dest执行",
  ["m_ex__zenhui_becomeuser"] = "获得其一张牌并令其成为使用者",
  ["m_ex__zenhui_becometarget"] = "令其也成为此牌的目标",
  ["$m_ex__zenhui1"] = "本公主说你忤逆，岂能有假？",
  ["$m_ex__zenhui2"] = "不用挣扎了，你们谁都逃不了！",
}

sunluban:addSkill(m_ex__zenhui)

local m_ex__jiaojin = fk.CreateTriggerSkill{
  name = "m_ex__jiaojin",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and not player:isNude()
    and (data.from:isMale())
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|equip", "#m_ex__jiaojin-discard", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player)
    return true
  end,
}

Fk:loadTranslationTable{
  ["m_ex__jiaojin"] = "骄矜",
  [":m_ex__jiaojin"] = "当你受到一名男性角色造成的伤害时，你可以弃置一张装备牌，防止此伤害。",
  ["#m_ex__jiaojin-discard"] = "骄矜：你可以弃置一张装备牌，防止此伤害",
  ["$m_ex__jiaojin1"] = "狂妄之徒！忘了你自己的身份了吗？",
  ["$m_ex__jiaojin2"] = "和本公主比心机谋算？哼，可笑！",
}

sunluban:addSkill(m_ex__jiaojin)

local caifuren = General(extension, "m_ex__caifuren", "qun", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["m_ex__caifuren"] = "界蔡夫人",
  ["#m_ex__caifuren"] = "襄江的蒲苇",
  ["illustrator:m_ex__caifuren"] = "漫想族",
  ["~m_ex__caifuren"] = "琮儿！啊啊……",
}

local m_ex__qieting = fk.CreateTriggerSkill{
  name = "m_ex__qieting",
  anim_type = "control",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player ~= target then
      return #player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
        local damage = e.data[5]
        if damage and target == damage.from and target ~= damage.to then
          return true
        end
      end, Player.HistoryTurn) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if not target.dead then
      if target:canMoveCardsInBoardTo(player, "e") then
        table.insert(choices, 1, "m_ex__qieting_move")
      end
      if not target:isKongcheng() then
        table.insert(choices, 1, "m_ex__qieting_pry")
      end
    end
    self.cost_data = room:askForChoice(player, choices, self.name)
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data  == "m_ex__qieting_move" and target:canMoveCardsInBoardTo(player, "e") then
      room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
    elseif self.cost_data  == "m_ex__qieting_pry" and not target.dead then
      local handcards = target:getCardIds(Player.Hand)
      if #handcards > 0 then
        local id = handcards[1]
        if #handcards > 1 then
          id = room:askForCardChosen(player, target, {
            card_data = {
              { "$Hand", table.random(handcards, 2) }
            }
          }, self.name)
        end
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
    elseif self.cost_data  == "draw1" then
      player:drawCards(1, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__qieting"] = "窃听",
  [":m_ex__qieting"] = "其他角色的回合结束后，若其没有于此回合内对另一名角色造成过伤害，则你可以选择一项：1.观看其两张手牌并获得其中一张牌；2.将其装备区里的一张牌置入你的装备区；3.摸一张牌。",
  ["m_ex__qieting_pry"] = "观看其两张手牌并获得其中一张",
  ["m_ex__qieting_move"] = "移动其装备区里的一张牌",
  ["$m_ex__qieting1"] = "密言？哼！早已入我耳中。",
  ["$m_ex__qieting2"] = "此子不除，久必为患！",
}

caifuren:addSkill(m_ex__qieting)

Fk:loadTranslationTable{
  ["$xianzhou_m_ex__caifuren1"] = "既是诸位之议，妾身复有何疑？",
  ["$xianzhou_m_ex__caifuren2"] = "我虽女流，亦知献州乃为长久之计。",
}

caifuren:addSkill("xianzhou")

local jvshou = General(extension, "m_ex__jvshou", "qun", 2, 3)
jvshou.shield = 3

Fk:loadTranslationTable{
  ["m_ex__jvshou"] = "界沮授",
  ["#m_ex__jvshou"] = "监军谋国",
  ["~m_ex__jvshou"] = "授，无愧主公之恩……",
}

local m_ex__jianying = fk.CreateViewAsSkill{
  name = "m_ex__jianying",
  prompt = "#m_ex__jianying-active",
  interaction = function()
    local names, all_names = {} , {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and not table.contains(all_names, card.name) then
        table.insert(all_names, card.name)
        local to_use = Fk:cloneCard(card.name)
        if Self:canUse(to_use) and not Self:prohibitUse(to_use) then
          table.insert(names, card.name)
        end
      end
    end
    if #names == 0 then return false end
    return UI.ComboBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "m_ex__jianying-used-phase", 1)
  end,
  view_as = function(self, cards)
    if not self.interaction.data or #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)

    local suitstrings = {"spade", "heart", "club", "diamond"}
    local suits = {Card.Spade, Card.Heart, Card.Club, Card.Diamond}
    local colors = {Card.Black, Card.Red, Card.Black, Card.Diamond}
    local suit = Self:getMark("m_ex__jianying_suit-phase")
    if table.contains(suitstrings, suit) then
      card.suit = suits[table.indexOf(suitstrings, suit)]
      card.color = colors[table.indexOf(suitstrings, suit)]
    end

    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("m_ex__jianying-used-phase") == 0
  end,
}
local m_ex__jianying_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__jianying_trigger",
  events = {fk.CardUsing},
  mute = true,
  main_skill = m_ex__jianying,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(m_ex__jianying) and player.phase == Player.Play and
    (data.extra_data or {}).m_ex__jianying_triggerable
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(m_ex__jianying.name)
    player.room:notifySkillInvoked(player, m_ex__jianying.name, "drawcard")
    player:drawCards(1, m_ex__jianying.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(m_ex__jianying, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.card:getSuitString() == player:getMark("m_ex__jianying_suit-phase") or
        (data.card.number == player:getMark("m_ex__jianying_number-phase") and data.card.number ~= 0) then
      data.extra_data = data.extra_data or {}
      data.extra_data.m_ex__jianying_triggerable = true
    end
    if data.card.suit == Card.NoSuit then
      room:setPlayerMark(player, "m_ex__jianying_suit-phase", 0)
    else
      room:setPlayerMark(player, "m_ex__jianying_suit-phase", data.card:getSuitString())
    end
    room:setPlayerMark(player, "m_ex__jianying_number-phase", data.card.number)

    room:setPlayerMark(player, "@m_ex__jianying_record-phase", {data.card:getSuitString(true), data.card:getNumberStr()})
  end,
}

m_ex__jianying:addRelatedSkill(m_ex__jianying_trigger)

Fk:loadTranslationTable{
  ["m_ex__jianying"] = "渐营",
  ["#m_ex__jianying_trigger"] = "渐营",
  [":m_ex__jianying"] = "当你于出牌阶段内使用牌时，若此牌与你于此阶段内使用的上一张牌点数或花色相同，你可以摸一张牌。出牌阶段限一次，你可以将一张牌当任意一种基本牌使用，若你于此阶段内使用的上一张牌有花色，则此牌花色视为你本回合使用的上一张牌的花色。",
  ["#m_ex__jianying-active"] = "发动渐营，将一张牌转化为任意基本牌使用",
  ["@m_ex__jianying_record-phase"] = "渐营",
  ["$m_ex__jianying1"] = "良谋百出，渐定决战胜势！",
  ["$m_ex__jianying2"] = "佳策数成，破敌垂手可得！",
}

jvshou:addSkill(m_ex__jianying)

Fk:loadTranslationTable{
  ["$shibei_m_ex__jvshou1"] = "只有杀身士，绝无降曹夫！",
  ["$shibei_m_ex__jvshou2"] = "心向袁氏，绝无背离可言！",
}

jvshou:addSkill("shibei")

local wuyi = General(extension, "m_ex__wuyi", "shu", 4)

Fk:loadTranslationTable{
  ["m_ex__wuyi"] = "界吴懿",
  ["#m_ex__wuyi"] = "建兴鞍辔",
  ["~m_ex__wuyi"] = "吾等虽不惧蜀道之险，却亦难过这渭水长安……",
}

local m_ex__benxi = fk.CreateTriggerSkill{
  name = "m_ex__benxi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 998, true, self.name, true, ".", "#m_ex__benxi-discard", true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name)
    room:throwCard(self.cost_data, self.name, player)
    room:addPlayerMark(player, "@m_ex__benxi-phase", #self.cost_data)
    room:addPlayerMark(player, "@@m_ex__benxi-phase")
  end,
}

local m_ex__benxi_delay = fk.CreateTriggerSkill{
  name = "#m_ex__benxi_delay",
  events = {fk.AfterCardTargetDeclared, fk.CardUseFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not (data.extra_data or {}).m_ex__benxi_triggerable then return false end
    if event == fk.AfterCardTargetDeclared then
      return true
    elseif event == fk.CardUseFinished then
      return data.damageDealt
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardTargetDeclared then
      player:broadcastSkillInvoke(m_ex__benxi.name, 2)
      room:notifySkillInvoked(player, m_ex__benxi.name, "offensive")

      if (data.card.name == "collateral") then return end
      local n = player:getMark("@m_ex__benxi-phase")

      local tos = room:askForChoosePlayers(player, table.filter(room:getUseExtraTargets(data), function (pid)
        return player:distanceTo(room:getPlayerById(pid)) == 1
      end), 1, n, "#m_ex__benxi-choose:::"..data.card:toLogString()..":"..tostring(n), m_ex__benxi.name, true)

      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end

    elseif event == fk.CardUseFinished then
      player:broadcastSkillInvoke(m_ex__benxi.name, 3)
      room:notifySkillInvoked(player, m_ex__benxi.name, "drawcard")
      player:drawCards(5, m_ex__benxi.name)
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:getMark("@@m_ex__benxi-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@m_ex__benxi-phase", 0)
    data.extra_data = data.extra_data or {}
    data.extra_data.m_ex__benxi_triggerable = true
  end,
}
local m_ex__benxi_distance = fk.CreateDistanceSkill{
  name = "#m_ex__benxi_distance",
  correct_func = function(self, from, to)
    return -from:getMark("@m_ex__benxi-phase")
  end,
}

m_ex__benxi:addRelatedSkill(m_ex__benxi_distance)
m_ex__benxi:addRelatedSkill(m_ex__benxi_delay)

Fk:loadTranslationTable{
  ["m_ex__benxi"] = "奔袭",
  ["#m_ex__benxi_delay"] = "奔袭",
  [":m_ex__benxi"] = "出牌阶段开始时，你可以弃置任意张牌，令你本阶段：计算与其他角色的距离-X、使用的下一张基本牌或普通锦囊牌可以额外指定至多X名你计算与其距离为1的角色为目标（X为你以此法弃置的牌数），然后此牌结算结束后，若此牌造成过伤害，你摸五张牌。",

  ["#m_ex__benxi-discard"] = "你可发动奔袭，弃置数张牌，此阶段使用第一张牌可额外指定等量目标",
  ["#m_ex__benxi-choose"] = "奔袭：可为此【%arg】额外指定至多%arg2个距离为1的目标",

  ["@m_ex__benxi-phase"] = "奔袭减距离",
  ["@@m_ex__benxi-phase"] = "奔袭加目标",

  ["$m_ex__benxi1"] = "战事唯论成败，何惜此等无用之物？",
  ["$m_ex__benxi2"] = "汝等惊弓之鸟，亦难逃吾奔战穷击！",
  ["$m_ex__benxi3"] = "袍染雍凉落日，马过岐山残雪！",
}

wuyi:addSkill(m_ex__benxi)

local zhuhuan = General(extension, "m_ex__zhuhuan", "wu", 4)

Fk:loadTranslationTable{
  ["m_ex__zhuhuan"] = "界朱桓",
  ["#m_ex__zhuhuan"] = "中洲拒天人",
  ["~m_ex__zhuhuan"] = "为将不行前而为人下，非可生受之辱……",
}

Fk:loadTranslationTable{
  ["$fenli_m_ex__zhuhuan1"] = "为主制客，乃百战百胜之势。",
  ["$fenli_m_ex__zhuhuan2"] = "诸位且与我勠力一战，自可得胜。",
}

zhuhuan:addSkill("fenli")

local m_ex__pingkou = fk.CreateTriggerSkill{
  name = "m_ex__pingkou",
  anim_type = "offensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to == Player.NotActive and player:hasSkill(self) and player.skipped_phases
    --FIXME:fk.TurnEnd时skipped_phases已经清理了
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, phase in ipairs({Player.Start, Player.Judge, Player.Draw, Player.Play, Player.Discard, Player.Finish}) do
      if player.skipped_phases[phase] then
        n = n + 1
      end
    end
    local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, n, "#m_ex__pingkou-choose:::"..n, self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    table.forEach(self.cost_data, function(id)
      room:damage{
        from = player,
        to = room:getPlayerById(id),
        damage = 1,
        skillName = self.name,
      }
    end)
    local cards = player.room:getCardsFromPileByRule(".|.|.|.|.|equip")
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
  end,
}
Fk:loadTranslationTable{
  ["m_ex__pingkou"] = "平寇",
  [":m_ex__pingkou"] = "回合结束时，你可以对至多X名其他角色各造成1点伤害（X为你本回合跳过的阶段数），若如此做，你从牌堆中随机获得一张装备牌。",
  ["#m_ex__pingkou-choose"] = "平寇：你可以对至多%arg名角色各造成1点伤害，然后随机获得一张装备牌",
  ["$m_ex__pingkou1"] = "等候多时，为的便是今日之胜。",
  ["$m_ex__pingkou2"] = "一鼓作气，击败疲敝之敌！",
}

zhuhuan:addSkill(m_ex__pingkou)

local zhangyi = General(extension, "m_ex__zhangyi", "shu", 4)
local m_ex__wurong = fk.CreateActiveSkill{
  name = "m_ex__wurong",
  mute = true,
  card_num = 0,
  target_num = 1,
  prompt = "#m_ex__wurong",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name, "offensive")
    local result = U.doStrategy(room, player, target,
      {"wurong-zhenya", "wurong-anfu"},
      {"wurong-fankang", "wurong-guishun"},
      self.name, 1)
    if result[1] == "wurong-zhenya" then
      if result[2] == "wurong-fankang" then
        player:broadcastSkillInvoke(self.name, 3)
        room:damage({
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        })
        if not player.dead then
          player:drawCards(1, self.name)
        end
      else
        player:broadcastSkillInvoke(self.name, 2)
        if not target:isNude() then
          local cards = room:askForCardChosen(player, target, "he", self.name, "#m_ex__wurong-prey::"..target.id)
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
          if player.dead or target.dead or player:isNude() then return end
          cards = room:askForCard(player, 2, 2, true, self.name, false, nil, "#m_ex__wurong-give::"..target.id)
          room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
        end
      end
    else
      if result[2] == "wurong-fankang" then
        player:broadcastSkillInvoke(self.name, 3)
        room:damage({
          to = player,
          damage = 1,
          skillName = self.name,
        })
        if not player.dead then
          player:drawCards(1, self.name)
        end
      else
        player:broadcastSkillInvoke(self.name, 2)
        if #target:getCardIds("he") < 2 then
          room:setPlayerMark(target, "@@m_ex__wurong_skip", 1)
        else
          local cards = room:askForCard(target, 2, 2, true, self.name, false, nil, "#m_ex__wurong-give::"..player.id)
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, target.id)
        end
      end
    end
  end,
}
local m_ex__wurong_delay = fk.CreateTriggerSkill{
  name = "#m_ex__wurong_delay",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@m_ex__wurong_skip") > 0 and data.to == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@m_ex__wurong_skip", 0)
    return true
  end,
}
m_ex__wurong:addRelatedSkill(m_ex__wurong_delay)
zhangyi:addSkill(m_ex__wurong)
zhangyi:addSkill("shizhi")
Fk:loadTranslationTable{
  ["m_ex__zhangyi"] = "界张嶷",
  ["#m_ex__zhangyi"] = "通壮逾古",

  ["m_ex__wurong"] = "怃戎",
  [":m_ex__wurong"] = "出牌阶段限一次，你可以与一名其他角色谋弈，根据双方选择的结果：<br>"..
  "镇压-反抗，你对其造成1点伤害，然后你摸一张牌。<br>"..
  "镇压-归顺，你获得其一张牌，然后交给其两张牌。<br>"..
  "安抚-反抗，你受到1点伤害，然后你摸一张牌。<br>"..
  "安抚-归顺，其交给你两张牌，若其牌数不足两张，则改为跳过其下一个摸牌阶段。",
  ["#m_ex__wurong"] = "怃戎：与一名其他角色谋弈",
  ["wurong-zhenya"] = "镇压",
  ["wurong-anfu"] = "安抚",
  ["wurong-fankang"] = "反抗",
  ["wurong-guishun"] = "归顺",
  [":wurong-zhenya"] = "对方选择“反抗”，你对其造成1点伤害，然后你摸一张牌<br>对方选择“归顺”，你获得其一张牌，然后交给其两张牌",
  [":wurong-anfu"] = "对方选择“反抗”，你受到1点伤害，然后你摸一张牌<br>对方选择“归顺”，其交给你两张牌，若其牌数不足两张，改为跳过其下一个摸牌阶段",
  [":wurong-fankang"] = "对方选择“镇压”，其对你造成1点伤害，然后其摸一张牌<br>对方选择“安抚”，其受到1点伤害，然后其摸一张牌",
  [":wurong-guishun"] = "对方选择“镇压”，其获得你一张牌，然后其交给你两张牌<br>对方选择“安抚”，你交给其两张牌，若你牌数不足两张，改为跳过你下一个摸牌阶段",
  ["#m_ex__wurong-prey"] = "怃戎：获得 %dest 一张牌",
  ["#m_ex__wurong-give"] = "怃戎：请交给 %dest 两张牌",
  ["@@m_ex__wurong_skip"] = "跳过摸牌",

  ["$m_ex__wurong1"] = "平乱羌，怃蛮夷，开旧道，复驿亭！",
  ["$m_ex__wurong2"] = "识断明果，以肃越巂千里蛮疆！",
  ["$m_ex__wurong3"] = "蛮不从化，化不及蛮，此嶷之过也。",
  ["~m_ex__zhangyi"] = "北伐未捷，臣定杀身以报陛下！",
}

local quancong = General(extension, "m_ex__quancong", "wu", 4)
local m_ex__yaoming = fk.CreateActiveSkill{
  name = "m_ex__yaoming",
  mute = true,
  card_num = 0,
  target_num = 1,
  prompt = "#m_ex__yaoming",
  interaction = function()
    return UI.ComboBox {choices = { "m_ex__yaoming_draw", "m_ex__yaoming_throw" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected > 0 or not self.interaction.data then return false end
    local to = Fk:currentRoom():getPlayerById(to_select)
    if self.interaction.data == "m_ex__yaoming_throw" then
      return Self.id ~= to_select and not to:isNude() and to:getHandcardNum() >= Self:getHandcardNum()
    else
      return to:getHandcardNum() <= Self:getHandcardNum()
    end
  end,
  can_use = function(self, player)
    return player:getMark("skill_charge") > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local choice = self.interaction.data
    local mark = choice.."_mark"
    if player:getMark("@m_ex__yaoming") ~= 0 and player:getMark("@m_ex__yaoming") ~= mark then
      room:setPlayerMark(player, "@m_ex__yaoming", 0)
    else
      U.skillCharged(player, -1)
      room:setPlayerMark(player, "@m_ex__yaoming", mark)
    end
    local to = room:getPlayerById(effect.tos[1])
    player:broadcastSkillInvoke(self.name)
    if choice == "m_ex__yaoming_throw" then
      room:notifySkillInvoked(player, self.name, "control")
      local id = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({id}, self.name, to, player)
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      to:drawCards(1, self.name)
    end
  end,
}
local m_ex__yaoming_trigger = fk.CreateTriggerSkill{
  name = "#m_ex__yaoming_trigger",
  mute = true,
  events = {fk.Damaged},
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.skillCharged(player, data.damage)
    if player:getMark("skill_charge") > 0 then
      room:askForUseActiveSkill(player, "m_ex__yaoming", "#m_ex__yaoming-invoke", true)
    end
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    return data == self and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      U.skillCharged(player, 2, 4)
    else
      U.skillCharged(player, -2, -4)
    end
  end,
}
m_ex__yaoming:addRelatedSkill(m_ex__yaoming_trigger)
quancong:addSkill(m_ex__yaoming)
Fk:loadTranslationTable{
  ["m_ex__quancong"] = "界全琮",
  ["#m_ex__quancong"] = "慕势耀族",

  ["m_ex__yaoming"] = "邀名",
  [":m_ex__yaoming"] = "蓄力技（2/4），出牌阶段或当你受到伤害后，你可以减1点“蓄力”值并选择一项：1.弃置手牌数不小于你的一名其他角色的一张牌；"..
  "2.令手牌数不大于你的一名角色摸一张牌。若与你上次选择的选项不同，你获得1点“蓄力”值，并清除已记录的选项。每当你受到1点伤害后，你获得1点“蓄力”值。",
  ["#m_ex__yaoming"] = "邀名：你可以减1点“蓄力”值，弃置一名角色一张牌或令其摸一张牌",
  ["m_ex__yaoming_throw"] = "弃置手牌数不小于你的其他角色一张牌",
  ["m_ex__yaoming_draw"] = "令手牌数不大于你的一名角色摸一张牌",
  ["@m_ex__yaoming"] = "邀名",
  ["m_ex__yaoming_throw_mark"] = "弃牌",
  ["m_ex__yaoming_draw_mark"] = "摸牌",
  ["#m_ex__yaoming-invoke"] = "你可以发动“邀名”",
  ["#m_ex__yaoming_trigger"] = "邀名",

  ["$m_ex__yaoming1"] = "山不让纤介，而成其危；海不辞丰盈，而成其邃。",
  ["$m_ex__yaoming2"] = "取上方可得中，取下则无所得矣。",
  ["~m_ex__quancong"] = "吾逐名如筑室道谋，而是用终不溃于成。",
}

local sunxiu = General(extension, "m_ex__sunxiu", "wu", 3)

Fk:loadTranslationTable{
  ["m_ex__sunxiu"] = "界孙休",
  ["#m_ex__sunxiu"] = "弥殇的景君",
  ["illustrator:m_ex__sunxiu"] = "君桓文化",
  ["~m_ex__sunxiu"] = "不求外取城地，但保大吴永安……",
}

local m_ex__yanzhu = fk.CreateActiveSkill{
  name = "m_ex__yanzhu",
  anim_type = "control",
  prompt = "#m_ex__yanzhu-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if target.dead or player.dead or target:isAllNude() then return end
    local choices = {"m_ex__yanzhu_choice1"}
    if #target.player_cards[Player.Equip] > 0 then
      table.insert(choices, "m_ex__yanzhu_choice2")
    end
    local choice = room:askForChoice(target, choices, self.name, "#m_ex__yanzhu-choice:" .. player.id)
    if choice == "m_ex__yanzhu_choice1" then
      local card = room:askForCardChosen(player, target, "hej", self.name)
      room:obtainCard(player.id, card, false, fk.ReasonPrey)
    elseif choice == "m_ex__yanzhu_choice2" then
      room:obtainCard(player, target:getCardIds(Player.Equip), true, fk.ReasonPrey)
      room:handleAddLoseSkills(player, "-" .. self.name, nil, true, false)
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__yanzhu"] = "宴诛",
  [":m_ex__yanzhu"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你获得其区域内的一张牌；2.令你获得其装备区里的所有牌（至少一张），然后你失去〖宴诛〗。",
  ["#m_ex__yanzhu-active"] = "发动宴诛，选择一名区域里有牌的其他角色",
  ["#m_ex__yanzhu-choice"] = "宴诛：选择令%src获得你区域里一张牌或令%src获得你装备区所有牌并失去宴诛",
  ["m_ex__yanzhu_choice1"] = "令其获得你区域里的一张牌",
  ["m_ex__yanzhu_choice2"] = "令其获得你装备区里所有牌并失去宴诛",
  ["$m_ex__yanzhu1"] = "计设辞阳宴，只为断汝头！",
  ["$m_ex__yanzhu2"] = "何需待午正？即刻送汝行！",
}

sunxiu:addSkill(m_ex__yanzhu)

local m_ex__xingxue = fk.CreateTriggerSkill{
  name = "m_ex__xingxue",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.hp
    if not player:hasSkill(m_ex__yanzhu, true) then
      n = player.maxHp
    end
    local tos = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function(p)
      return p.id end), 1, n, "#m_ex__xingxue-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local xingxue_upgrade = (not player:hasSkill(m_ex__yanzhu, true, true))
    local targets = self.cost_data
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local to = room:getPlayerById(id)
      to:drawCards(1, self.name)
      if not to:isNude() then
        local choices = {"m_ex__xingxue_puttodrawpile"}
        local other_targets = table.filter(targets, function (pid)
          return pid ~= id and not room:getPlayerById(pid).dead
        end)
        if #other_targets > 0 and xingxue_upgrade then
          table.insert(choices, "m_ex__xingxue_give")
        end
        local choice = room:askForChoice(to, choices, self.name)
        if choice == "m_ex__xingxue_puttodrawpile" then
          local card = room:askForCard(to, 1, 1, true, self.name, false, ".", "#m_ex__xingxue-puttodrawpile")
          room:moveCards({
            ids = card,
            from = id,
            toArea = Card.DrawPile,
            moveReason = fk.ReasonPut,
            skillName = self.name,
          })
        elseif choice == "m_ex__xingxue_give" then
          local tar, card =  player.room:askForChooseCardAndPlayers(to, other_targets, 1, 1, ".", "#m_ex__xingxue-give", self.name, false)
          if #tar > 0 and card then
            room:obtainCard(room:getPlayerById(tar[1]), card, false, fk.ReasonGive)
          end
        end
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["m_ex__xingxue"] = "兴学",
  [":m_ex__xingxue"] = "结束阶段，你可以令至多X名角色（X为你的体力值）依次摸一张牌，并将一张牌置于牌堆顶，若你没有〖宴诛〗，则可以改为将一张牌交给另一名此技能的目标且X改为你的体力上限。",
  ["#m_ex__xingxue-choose"] = "兴学：你可以令至多%arg名角色依次摸一张牌并将一张牌置于牌堆顶",
  ["m_ex__xingxue_puttodrawpile"] = "将一张牌置于牌堆顶",
  ["m_ex__xingxue_give"] = "将一张牌交给一名兴学的目标",
  ["#m_ex__xingxue-puttodrawpile"] = "兴学：选择一张牌置于牌堆顶",
  ["#m_ex__xingxue-give"] = "兴学：选择一张牌交给一名此次兴学的目标",
  ["$m_ex__xingxue1"] = "古者建国，教学为先，为时养器！",
  ["$m_ex__xingxue2"] = "偃武修文，以崇大化！",
}

sunxiu:addSkill(m_ex__xingxue)
sunxiu:addSkill("zhaofu")

local zhuzhi = General(extension, "m_ex__zhuzhi", "wu", 4)

Fk:loadTranslationTable{
  ["m_ex__zhuzhi"] = "界朱治",
  ["#m_ex__zhuzhi"] = "功崇信重",
  ["~m_ex__zhuzhi"] = "臣辅孙氏三代之业，今年近古稀，死而无憾。",
}

local m_ex__anguo = fk.CreateTriggerSkill{
  name = "m_ex__anguo",
  anim_type = "support",
  events = {fk.GameStart, fk.EventPhaseStart, fk.DamageInflicted, fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart and player.phase == Player.Play and player == target then
        return table.find(room.alive_players, function (p)
          return p:getMark("@@m_ex__anguo") > 0
        end) and table.find(room.alive_players, function (p)
          return p:getMark("m_ex__anguo_given") == 0 and p ~= player
        end)
      elseif event == fk.DamageInflicted and player == target then
        return data.damage >= player.hp and table.find(room.alive_players, function (p)
          return p:getMark("@@m_ex__anguo") > 0 and data.from ~= p
        end)
      elseif event == fk.EnterDying and target:getMark("@@m_ex__anguo") > 0 then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local anguo_target = table.find(room.alive_players, function (p)
        return p:getMark("@@m_ex__anguo") > 0
      end)
      local targets = table.map(table.filter(room.alive_players, function (p)
        return  p:getMark("m_ex__anguo_given") == 0 and p ~= player
      end), function (p)
        return p.id
      end)
      if anguo_target and #targets > 0 then
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#m_ex__anguo-move::" .. anguo_target.id, self.name, true)
        if #tos > 0 then
          self.cost_data = tos[1]
          return true
        end
      end
    else return true end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#m_ex__anguo-choose", self.name, false)
      local to
      if #tos > 0 then
        to = room:getPlayerById(tos[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:addPlayerMark(to, "@@m_ex__anguo")
      room:addPlayerMark(to, "m_ex__anguo_given")
    elseif event == fk.EventPhaseStart then
      local to = room:getPlayerById(self.cost_data)
      table.forEach(room.alive_players, function (p)
        room:setPlayerMark(p, "@@m_ex__anguo", 0)
      end)
      room:addPlayerMark(to, "@@m_ex__anguo")
      room:addPlayerMark(to, "m_ex__anguo_given")
    elseif event == fk.DamageInflicted then
      return true
    elseif event == fk.EnterDying then
      room:doIndicate(player.id, {target.id})
      room:setPlayerMark(target, "@@m_ex__anguo", 0)
      if target.hp < 1 then
        room:recover({
          who = target,
          num = 1 - target.hp,
          recoverBy = player,
          skillName = self.name
        })
      end

      if not player.dead then
        local choices = {}
        if player.hp > 1 then
          table.insert(choices, "m_ex__anguo_losehp")
        end
        if player.maxHp > 1 then
          table.insert(choices, "m_ex__anguo_losemaxhp")
        end
        if #choices > 0 then
          local choice = room:askForChoice(player, choices, self.name)
          if choice == "m_ex__anguo_losehp" then
            room:loseHp(player, player.hp - 1)
          elseif choice == "m_ex__anguo_losemaxhp" then
            room:changeMaxHp(player, 1 - player.maxHp)
          end
          room:changeShield(target, 1)
        end
      end
    end
  end,
}

local m_ex__anguo_maxcards = fk.CreateMaxCardsSkill{
  name = "#m_ex__anguo_maxcards",
  fixed_func = function(self, player)
    if player:getMark("@@m_ex__anguo") > 0 then
      return player.maxHp
    end
  end
}

m_ex__anguo:addRelatedSkill(m_ex__anguo_maxcards)

Fk:loadTranslationTable{
  ["m_ex__anguo"] = "安国",
  [":m_ex__anguo"] = "游戏开始时，你令一名其他角色获得“安国”标记；拥有“安国”标记的角色的手牌上限等于其体力上限；出牌阶段开始时，若场上有拥有“安国”标记的角色，你可以将“安国”标记移动给一名本局游戏未获得过此标记的角色；当你受到伤害时，若场上有拥有“安国”标记的角色、伤害来源没有“安国”标记、此次伤害的伤害值不小于你的体力值，防止此伤害；当拥有“安国”标记的角色进入濒死状态时，其移去“安国”标记并将体力值回复至1点，然后你选择一项：1.若你的体力值大于1，你失去体力至1点；2.若你的体力上限大于1，你将体力上限减至1。若如此做，其获得1点“护甲”。",
  ["@@m_ex__anguo"] = "安国",
  ["#m_ex__anguo-choose"] = "安国：选择一名角色，令其获得安国标记",
  ["#m_ex__anguo-move"] = "安国：你可以将%dest的角色的安国标记转移给另一名角色",
  ["m_ex__anguo_losehp"] = "失去体力至1点",
  ["m_ex__anguo_losemaxhp"] = "减少体力上限至1点",
  ["$m_ex__anguo1"] = "感文台知遇，自当鞠躬尽瘁，扶其身后之业。",
  ["$m_ex__anguo2"] = "安国定邦，克成东南一统！",
  ["$m_ex__anguo3"] = "孙氏为危难之际，吾当尽力辅之！",
}

zhuzhi:addSkill(m_ex__anguo)

return extension
