local extension = Package("mobile_test")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["mobile_test"] = "手杀-测试服",
  ["m_friend"] = "友",
}

local U = require "packages/utility/utility"

local zhangbu = General(extension, "zhangbu", "wu", 4)
Fk:loadTranslationTable{
  ["zhangbu"] = "张布",
  ["#zhangbu"] = "主胜辅义",
  --["illustrator:zhangbu"] = "",
}
local chengxiong = fk.CreateTriggerSkill{
  name = "chengxiong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick and data.firstTarget and
      table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end) then
      local room = player.room
      local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        return use and use.from == player.id
      end, Player.HistoryPhase)
      return table.find(room.alive_players, function(p)
        return #p:getCardIds("he") >= n
      end)
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local n = #room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      return use and use.from == player.id
    end, Player.HistoryPhase)
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getCardIds("he") >= n
    end), Util.IdMapper)
    if #table.filter(player:getCardIds("he"), function (id)
      return not player:prohibitDiscard(id)
    end) == 0 then
      table.removeOne(targets, player.id)
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#chengxiong-choose:::"..data.card:getColorString(), self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local card
    if to == player then
      card = room:askForDiscard(player, 1, 1, true, self.name, false, nil, "#chengxiong-discard::"..to.id)[1]
    else
      card = room:askForCardChosen(player, to, "he", self.name, "#chengxiong-discard::"..to.id)
    end
    local color = Fk:getCardById(card).color
    room:throwCard(card, self.name, to, player)
    if color == data.card.color and color ~= Card.NoColor and not to.dead then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
zhangbu:addSkill(chengxiong)
Fk:loadTranslationTable{
  ["chengxiong"] = "惩凶",
  [":chengxiong"] = "当你使用锦囊牌指定第一个目标后，若目标包含其他角色，你可以选择一名牌数不小于X的角色（X为你此阶段使用的牌数），弃置其一张牌，"..
  "若此牌颜色与你使用的锦囊牌颜色相同，你对其造成1点伤害。",
  ["#chengxiong-choose"] = "惩凶：弃置一名角色一张牌，若为%arg，对其造成1点伤害",
  ["#chengxiong-discard"] = "惩凶：弃置 %dest 一张牌",
}
local wangzhuan = fk.CreateTriggerSkill{
  name = "wangzhuan",
  anim_type = "drawcard",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not data.card and
      (data.from and data.from == player or target == player)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wangzhuan-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if room.current and not room.current.dead then
      room:doIndicate(player.id, {room.current.id})
      room:addPlayerMark(room.current, "@@wangzhuan-turn")
      room:addPlayerMark(room.current, MarkEnum.UncompulsoryInvalidity .. "-turn")
    end
  end,
}
zhangbu:addSkill(wangzhuan)
Fk:loadTranslationTable{
  ["wangzhuan"] = "妄专",
  [":wangzhuan"] = "当一名角色受到非游戏牌造成的伤害后，若你是伤害来源或受伤角色，你可以摸两张牌，然后当前回合角色非锁定技失效直到回合结束。",
  ["#wangzhuan-invoke"] = "妄专：你可以摸两张牌，令当前回合角色本回合非锁定技无效",
  ["@@wangzhuan-turn"] = "妄专",
}

local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general == friend or p.deputyGeneral == friend)
    end)
end

local friend__zhugeliang = General(extension, "m_friend__zhugeliang", "qun", 3)
friend__zhugeliang.hidden = true
Fk:loadTranslationTable{
  ["m_friend__zhugeliang"] = "友诸葛亮",
  ["#m_friend__zhugeliang"] = "",
  ["illustrator:m_friend__zhugeliang"] = "",
  ["~m_friend__zhugeliang"] = "",
}
Fk:loadTranslationTable{
  ["yance"] = "演策",
  [":yance"] = "每轮限一次，首轮开始时，或准备阶段，你可以选择一项：从牌堆中随机获得一张锦囊牌；执行<a href='wolongyance'>卧龙演策</a>。"..
  "若你执行卧龙演策，当一张牌被使用时，若此牌的类别或颜色与你的预测相同，你摸一张牌（每次执行“卧龙演策”至多因此摸五张牌）。<br>"..
  "当卧龙演策的预测全部验证后，或当你再次执行卧龙演策时，若你本次卧龙演策正确的预测数量：<br>"..
  "为0，你失去1点体力，此后卧龙演策可预测的牌数-1；<br>"..
  "不足一半，你弃置一张牌；<br>"..
  "至少一半（向上取整），你根据本次预测的方式，从牌堆中获得一张符合你声明条件的牌；<br>"..
  "全部正确，你摸两张牌，此后卧龙演策可预测的牌数+1（至多为7）。",
  ["wolongyance"] = "预测此后被使用的指定数量张牌的颜色或类别（初始可预测的牌数为3），“预测的方式”即通过颜色预测或通过类别预测。"..
  "此预测在一名角色使用牌时揭示，若所有预测均已揭示，称为全部验证。",
}
Fk:loadTranslationTable{
  ["fangqiu"] = "方遒",
  [":fangqiu"] = "限定技，当你执行“卧龙演策”后，你可以展示你的“卧龙演策”预测，若如此做，本次“卧龙演策”的预测全部验证后，执行效果的值均+1。",
}
local zhugeliang__gongli = fk.CreateTriggerSkill{
  name = "zhugeliang__gongli",
  frequency = Skill.Compulsory,
  dynamic_desc = function(self, player)
    if GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") and GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "zhugeliang__gongli"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") then
      return "zhugeliang__gongli_pangtong"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "zhugeliang__gongli_xushu"
    end
    return "dummyskill"
  end,
}
friend__zhugeliang:addSkill(zhugeliang__gongli)
Fk:loadTranslationTable{
  ["zhugeliang__gongli"] = "共砺",
  [":zhugeliang__gongli"] = "锁定技，若友方友庞统在场，你执行“卧龙演策”初始可预测的牌数+1；"..
  "若友方友徐庶在场，你“卧龙演策”预测的第一张牌的结果始终视为正确。（仅斗地主和2v2模式生效）",
  [":zhugeliang__gongli_pangtong"] = "锁定技，若友方友庞统在场，你执行“卧龙演策”初始可预测的牌数+1。",
  [":zhugeliang__gongli_xushu"] = "锁定技，若友方友徐庶在场，你“卧龙演策”预测的第一张牌的结果始终视为正确。",
}

local friend__pangtong = General(extension, "m_friend__pangtong", "qun", 3)
Fk:loadTranslationTable{
  ["m_friend__pangtong"] = "友庞统",
  ["#m_friend__pangtong"] = "",
  ["illustrator:m_friend__pangtong"] = "",
  ["~m_friend__pangtong"] = "",
}
local manjuan = fk.CreateTriggerSkill{
  name = "friend__manjuan",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if #move.moveInfo > 1 and (move.to and move.to == player.id and move.skillName ~= self.name) then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getCardIds("h"), info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local all_cards = {}
    for _, move in ipairs(data) do
      if #move.moveInfo > 1 and (move.to and move.to == player.id and move.skillName ~= self.name) then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getCardIds("h"), info.cardId) then
            table.insertIfNeed(all_cards, info.cardId)
          end
        end
      end
    end
    local cards = player.room:askForCard(player, 1, 999, false, self.name, true, tostring(Exppattern{ id = all_cards }),
      "#friend__manjuan-invoke")
    if #cards > 0 then
      self.cost_data = {cards = cards}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(self.cost_data.cards)
    if #cards == 1 then
      room:moveCards({
        ids = cards,
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = self.name,
        proposer = player.id,
      })
    else
      local result = room:askForGuanxing(player, cards, nil, {0, 0}, self.name, true)
      room:moveCards({
        ids = table.reverse(result.top),
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = self.name,
        proposer = player.id,
      })
    end
    if player.dead then return end
    local ids = {}
    local discard_pile = table.simpleClone(room.discard_pile)
    for _, id in ipairs(cards) do
      local type = Fk:getCardById(id).type
      local all_ids = table.filter(discard_pile, function (id2)
        return type ~= Fk:getCardById(id2).type
      end)
      if #all_ids > 0 then
        local c = table.random(all_ids)
        table.insert(ids, c)
        if #ids > 4 then break end
        table.removeOne(discard_pile, c)
      end
    end
    if #ids > 0 then
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
friend__pangtong:addSkill(manjuan)
Fk:loadTranslationTable{
  ["friend__manjuan"] = "漫卷",
  [":friend__manjuan"] = "当你不因本技能一次性获得至少两张牌后，你可以将其中任意张牌以任意顺序置于牌堆顶。若如此做，你每放置一张牌，"..
  "便从弃牌堆中随机获得一张与此牌类别不同的牌（每次至多获得五张）。",
  ["#friend__manjuan-invoke"] = "漫卷：你可以将其中的牌置于牌堆顶，获得等量类别不同的牌",
}
local yangming = fk.CreateTriggerSkill{
  name = "friend__yangming",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local room = player.room
      local n = player:getHandcardNum()
      if #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            n = n - #move.moveInfo
          end
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand then
                n = n + 1
              end
            end
          end
          return n == 0
        end
      end, room.logic:getCurrentEvent().id) > 0 then
        if player:hasSkill("pangtong__gongli") and GongliFriend(room, player, "m_friend__zhugeliang") then
          return true
        else
          return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.toArea == Card.DiscardPile then
                for _, info in ipairs(move.moveInfo) do
                  if Fk:getCardById(info.cardId).suit ~= Card.NoSuit then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryTurn) > 0
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local suits = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            table.insertIfNeed(suits, Fk:getCardById(info.cardId).suit)
          end
        end
      end
    end, Player.HistoryTurn)
    table.removeOne(suits, Card.NoSuit)
    local n = #suits
    if player:hasSkill("pangtong__gongli") and GongliFriend(room, player, "m_friend__zhugeliang") then
      n = n + 1
    end
    local cards = room:getNCards(n)
    room:moveCardTo(cards, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    if player.dead then
      room:cleanProcessingArea(cards)
      return
    end
    suits = {}
    cards = table.filter(cards, function (id)
      return Fk:getCardById(id).suit ~= Card.NoSuit
    end)
    while #cards > 0 and not player.dead do
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.Processing and not table.contains(suits, Fk:getCardById(id).suit)
      end)
      if #cards == 0 then break end
      local use = room:askForUseRealCard(player, cards, self.name, "#friend__yangming-use", {
        expand_pile = cards,
      }, true, true)
      if use then
        table.insert(suits, use.card.suit)
        room:useCard(use)
      else
        break
      end
    end
    room:cleanProcessingArea(cards)
    if player:hasSkill("pangtong__gongli") and GongliFriend(room, player, "m_friend__xushu") then
      cards = table.filter(cards, function (id)
        return room:getCardArea(id) == Card.DiscardPile and not table.contains(suits, Fk:getCardById(id).suit) and
          Fk:getCardById(id).suit ~= Card.NoSuit
      end)
      if #cards > 0 then
        if #cards > 1 then
          cards = U.askforChooseCardsAndChoice(player, cards, {"OK"}, self.name, "#pangtong__gongli-prey")
        end
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    end
  end,
}
friend__pangtong:addSkill(yangming)
Fk:loadTranslationTable{
  ["friend__yangming"] = "养名",
  [":friend__yangming"] = "出牌阶段结束时，若你本阶段失去过所有手牌，你可以亮出牌堆顶的X张牌（X为本回合进入过弃牌堆的牌的花色数），"..
  "使用其中任意张花色各不相同的牌（无次数限制）。",
  ["#friend__yangming-use"] = "养名：你可以使用其中任意张花色各不相同的牌",
}
local pangtong__gongli = fk.CreateTriggerSkill{
  name = "pangtong__gongli",
  frequency = Skill.Compulsory,
  dynamic_desc = function(self, player)
    if GongliFriend(Fk:currentRoom(), player, "m_friend__zhugeliang") and GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "pangtong__gongli"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__zhugeliang") then
      return "pangtong__gongli_zhugeliang"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "pangtong__gongli_xushu"
    end
    return "dummyskill"
  end,
}
friend__pangtong:addSkill(pangtong__gongli)
Fk:loadTranslationTable{
  ["pangtong__gongli"] = "共砺",
  [":pangtong__gongli"] = "锁定技，若友方友诸葛亮在场，你发动〖养名〗亮出牌张数+1；"..
  "若友方友徐庶在场，你发动〖养名〗后，获得一张本次亮出牌中未使用过的花色的牌。（仅斗地主和2v2模式生效）",
  ["#pangtong__gongli-prey"] = "共砺：获得其中一张牌",
  [":pangtong__gongli_zhugeliang"] = "锁定技，若友方友诸葛亮在场，你发动〖养名〗亮出牌张数+1。",
  [":pangtong__gongli_xushu"] = "锁定技，若友方友徐庶在场，你发动〖养名〗后，获得一张本次亮出牌中未使用过的花色的牌。",
}

local friend__xushu = General(extension, "m_friend__xushu", "qun", 3)
Fk:loadTranslationTable{
  ["m_friend__xushu"] = "友徐庶",
  ["#m_friend__xushu"] = "",
  ["illustrator:m_friend__xushu"] = "",
  ["~m_friend__xushu"] = "",
}
local xiaxing = fk.CreateTriggerSkill{
  name = "xiaxing",
  anim_type = "drawcard",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local room = player.room
      local cards = table.filter(U.prepareDeriveCards(room, {
        {"xuanjian_sword", Card.Spade, 2}
      }, self.name), function (id)
        return room:getCardArea(id) == Card.Void and player:canUse(Fk:getCardById(id))
      end)
      return #cards > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(U.prepareDeriveCards(room, {
      {"xuanjian_sword", Card.Spade, 2}
    }, self.name), function (id)
      return room:getCardArea(id) == Card.Void and player:canUse(Fk:getCardById(id))
    end)
    room:useCard{
      from = player.id,
      card = Fk:getCardById(cards[1]),
    }
  end,
}
local xiaxing_trigger = fk.CreateTriggerSkill{
  name = "#xiaxing_trigger",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("xiaxing") and #player:getTableMark("@qihui") > 0 then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "xuanjian_sword" then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > 0 then
        self.cost_data = {cards = cards}
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local choices = table.map(player:getTableMark("@qihui"), function (s)
      return string.split(s, "_")[1]
    end)
    table.insert(choices, "Cancel")
    local choice = player.room:askForChoice(player, choices, "xiaxing", "#xiaxing-choice")
    if choice ~= "Cancel" then
      self.cost_data.choice = choice.."_char"
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "@qihui", self.cost_data.choice)
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, player, fk.ReasonJustMove, "xiaxing", nil, true, player.id)
  end,
}
xiaxing:addRelatedSkill(xiaxing_trigger)
friend__xushu:addSkill(xiaxing)
Fk:loadTranslationTable{
  ["xiaxing"] = "侠行",
  [":xiaxing"] = "游戏开始时，你获得并使用<a href=':xuanjian_sword'>【玄剑】</a>；当【玄剑】进入弃牌堆后，你可以移除1个“启诲”标记获得之。",
  ["#xiaxing_trigger"] = "侠行",
  ["#xiaxing-choice"] = "侠行：是否移除一个“启诲”标记获得【玄剑】？",
}
local qihui = fk.CreateTriggerSkill{
  name = "qihui",
  anim_type = "special",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      not table.contains(player:getTableMark("@qihui"), data.card:getTypeString().."_char")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "@qihui", data.card:getTypeString().."_char")
    if #player:getTableMark("@qihui") == 3 then
      local choices = room:askForChoices(player, {"basic", "trick", "equip"}, 2, 2, self.name, "#qihui-remove", false)
      for _, choice in ipairs(choices) do
        room:removeTableMark(player, "@qihui", choice.."_char")
      end
      local all_choices = {"qihui_recover", "draw2", "qihui_use"}
      choices = table.simpleClone(all_choices)
      if not player:isWounded() and player:isNude() then
        table.remove(choices, 1)
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "qihui_recover" then
        if player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          }
          if player.dead or player:isNude() then return end
        end
        local card = room:askForCard(player, 1, 1, true, self.name, false, nil, "#qihui-recast")
        room:recastCard(card, player, self.name)
      elseif choice == "draw2" then
        player:drawCards(2, self.name)
      elseif choice == "qihui_use" then
        room:setPlayerMark(player, "qihui_use", 1)
      end
    end
  end,

  refresh_events = {fk.PreCardUse},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("qihui_use") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "qihui_use", 0)
  end,
}
local qihui_targetmod = fk.CreateTargetModSkill{
  name = "#qihui_targetmod",
  bypass_times = function (self, player, skill, scope, card)
    return card and player:getMark("qihui_use") > 0
  end,
}
qihui:addRelatedSkill(qihui_targetmod)
friend__xushu:addSkill(qihui)
Fk:loadTranslationTable{
  ["qihui"] = "启诲",
  [":qihui"] = "锁定技，当你使用牌时，若你没有此牌对应类别的标记，你获得1个对应类别的“启诲”标记，然后若你拥有3个“启诲”标记，"..
  "你移除2个“启诲”标记并选择一项：回复1点体力并重铸一张牌；摸两张牌；你使用的下一张牌不计入次数且无次数限制。",
  ["@qihui"] = "启诲",
  ["#qihui-remove"] = "启诲：请移除两种“启诲”标记",
  ["qihui_recover"] = "回复1点体力，重铸一张牌",
  ["qihui_use"] = "使用下一张牌无次数限制",
  ["#qihui-recast"] = "启诲：重铸一张牌",
}
local xushu__gongli = fk.CreateTargetModSkill{
  name = "xushu__gongli",
  frequency = Skill.Compulsory,
  dynamic_desc = function(self, player)
    if GongliFriend(Fk:currentRoom(), player, "m_friend__zhugeliang") and GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") then
      return "xushu__gongli"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__zhugeliang") then
      return "xushu__gongli_zhugeliang"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") then
      return "xushu__gongli_pangtong"
    end
    return "dummyskill"
  end,
  bypass_distances = function (self, player, skill, card, to)
    return player:hasSkill(self) and GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") and card and
      table.contains(card.skillNames, "xuanjian_sword")
  end,
}
friend__xushu:addSkill(xushu__gongli)
Fk:loadTranslationTable{
  ["xushu__gongli"] = "共砺",
  [":xushu__gongli"] = "锁定技，若友方友诸葛亮在场，你发动〖玄剑〗改为将一张手牌当【杀】使用；"..
  "若友方友庞统在场，你发动〖玄剑〗使用的【杀】无距离限制。（仅斗地主和2v2模式生效）",
  [":xushu__gongli_zhugeliang"] = "锁定技，若友方友诸葛亮在场，你发动〖玄剑〗改为将一张手牌当【杀】使用。",
  [":xushu__gongli_pangtong"] = "锁定技，若友方友庞统在场，你发动〖玄剑〗使用的【杀】无距离限制。",
}

return extension
