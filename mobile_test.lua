local extension = Package("mobile_test")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["mobile_test"] = "手杀-测试服",
  ["m_friend"] = "友",
}

local U = require "packages/utility/utility"

local function AddWinAudio(general)
  local Win = fk.CreateActiveSkill{ name = general.name.."_win_audio" }
  Win.package = extension
  Fk:addSkill(Win)
end

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
AddWinAudio(friend__zhugeliang)
Fk:loadTranslationTable{
  ["m_friend__zhugeliang"] = "友诸葛亮",
  ["#m_friend__zhugeliang"] = "龙骧九天",
  --["illustrator:m_friend__zhugeliang"] = "",
  ["~m_friend__zhugeliang"] = "吾既得明主，纵不得良时，亦当全力一试……",
  ["$m_friend__zhugeliang_win_audio"] = "鼎足之势若成，则将军中原可图也。",
}
local function DoYance(player)
  local room = player.room
  local results = table.simpleClone(player:getTableMark("yance_results"))
  local choices = table.contains({"red", "black"}, player:getMark("yance_guess")[1]) and {"red", "black"} or {"basic", "trick", "equip"}
  local fangqiu_trigger = 1
  if player:getMark("fangqiu_trigger") > 0 then
    room:setPlayerMark(player, "fangqiu_trigger", 0)
    if #player:getTableMark("yance_guess") == #player:getTableMark("yance_results") then
      fangqiu_trigger = 2
    end
  end
  room:setPlayerMark(player, "yance_guess", 0)
  room:setPlayerMark(player, "yance_results", 0)
  room:setPlayerMark(player, "@[yance]", 0)
  local yes = #table.filter(results, function (n)
    return n == 1
  end)
  if yes == 0 then
    player:broadcastSkillInvoke("yance", 4)
    room:notifySkillInvoked(player, "yance", "negative")
    room:addPlayerMark(player, "yance_fail", fangqiu_trigger)
    room:loseHp(player, fangqiu_trigger, "yance")
  elseif yes < #results / 2 then
    player:broadcastSkillInvoke("yance", 5)
    room:notifySkillInvoked(player, "yance", "negative")
    room:askForDiscard(player, fangqiu_trigger, fangqiu_trigger, true, "yance", false)
  else
    if yes == #results then
      player:broadcastSkillInvoke("yance", 3)
    else
      player:broadcastSkillInvoke("yance", table.random{6, 7})
    end
    room:notifySkillInvoked(player, "yance", "drawcard")
    local choice = room:askForChoice(player, choices, "yance", "#yance-prey")
    local pattern
    if table.contains({"basic", "trick", "equip"}, choice) then
      pattern = ".|.|.|.|.|"..choice
    elseif choice == "red" then
      pattern = ".|.|heart,diamond"
    elseif choice == "black" then
      pattern = ".|.|spade,club"
    end
    local cards = room:getCardsFromPileByRule(pattern, fangqiu_trigger, "drawPile")
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, "yance", nil, false, player.id)
    end
    if yes == #results and not player.dead then
      room:addPlayerMark(player, "yance_success", fangqiu_trigger)
      player:drawCards(2 * fangqiu_trigger, "yance")
    end
  end
end
local yance = fk.CreateTriggerSkill{
  name = "yance",
  mute = true,
  events = {fk.RoundStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 then
      if event == fk.RoundStart then
        return player.room:getBanner("RoundCount") == 1
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"yance_prey", "yance_yance", "Cancel"}, self.name)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yance", table.random{1, 2})
    if self.cost_data.choice == "yance_prey" then
      room:notifySkillInvoked(player, "yance", "drawcard")
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|trick", 1, "drawPile")
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
      end
    else
      room:notifySkillInvoked(player, "yance", "control")
      if player:getMark("yance_guess") ~= 0 then
        DoYance(player)
        if player.dead then return end
      end
      local n = 3
      n = n - player:getMark("yance_fail") + player:getMark("yance_success")
      if GongliFriend(room, player, "m_friend__pangtong") then
        n = n + 1
      end
      if n < 1 then return end
      n = math.min(n, 7)
      local all_choices = {"basic", "trick", "equip", "red", "black"}
      local choice = room:askForChoice(player, all_choices, self.name, "#yance-choice:::1:"..n)
      room:addTableMark(player, "yance_guess", choice)
      local mark = {
        value = {choice},
      }
      room:setPlayerMark(player, "@[yance]", mark)
      if n > 1 then
        local choices = table.contains({"red", "black"}, choice) and {"red", "black"} or {"basic", "trick", "equip"}
        for i = 2, n, 1 do
          choice = room:askForChoice(player, choices, self.name, "#yance-choice:::"..i..":"..n, false, all_choices)
          room:addTableMark(player, "yance_guess", choice)
          table.insert(mark.value, choice)
          room:setPlayerMark(player, "@[yance]", mark)
        end
      end
      room.logic:trigger("fk.AfterYance", player, {})
    end
  end,
}
local yance_trigger = fk.CreateTriggerSkill{
  name = "#yance_trigger",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("yance_guess") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local result = 2
    local index = #player:getTableMark("yance_results") + 1
    local choice = player:getTableMark("yance_guess")[index]
    if data.card:getTypeString() == choice or data.card:getColorString() == choice then
      result = 1
    elseif GongliFriend(room, player, "m_friend__xushu") and index == 1 then
      result = 1
    end
    local mark = player:getTableMark("@[yance]")
    if result == 1 then
      table.insert(mark.value, 2 * index, "√")
    else
      table.insert(mark.value, 2 * index, "×")
    end
    room:setPlayerMark(player, "@[yance]", mark)
    room:addTableMark(player, "yance_results", result)
    if #player:getTableMark("yance_guess") == #player:getTableMark("yance_results") then
      DoYance(player)
    end
  end,
}
Fk:addQmlMark{
  name = "yance",
  qml_path = function(name, value, p)
    if (value.players == nil and Self == p) or (value.players and table.contains(value.players, Self.id)) then
      return "packages/mobile/qml/yance"
    end
    return ""
  end,
  how_to_show = function(name, value, p)
    if type(value) ~= "table" then return " " end
    return tostring(#table.filter(value.value, function (s)
      return s ~= "√" and s ~= "×"
    end))
  end,
}
yance:addRelatedSkill(yance_trigger)
friend__zhugeliang:addSkill(yance)
Fk:loadTranslationTable{
  ["yance"] = "演策",
  [":yance"] = "每轮限一次，首轮开始时，或准备阶段，你可以选择一项：从牌堆中随机获得一张锦囊牌；执行<a href='wolongyance'>“卧龙演策”</a>。"..
  "若你执行“卧龙演策”，当一张牌被使用时，若此牌的类别或颜色与你的预测相同，你摸一张牌（每次执行“卧龙演策”至多因此摸五张牌）。<br>"..
  "当“卧龙演策”的预测全部验证后，或当你再次执行“卧龙演策”时，若你本次“卧龙演策”正确的预测数量：<br>"..
  "为0，你失去1点体力，此后“卧龙演策”可预测的牌数-1；<br>"..
  "不足一半，你弃置一张牌；<br>"..
  "至少一半（向上取整），你根据本次预测的方式，从牌堆中获得一张符合你声明条件的牌；<br>"..
  "全部正确，你摸两张牌，此后“卧龙演策”可预测的牌数+1（至多为7）。",
  ["wolongyance"] = "预测此后被使用的指定数量张牌的颜色或类别（初始可预测的牌数为3），“预测的方式”即通过颜色预测或通过类别预测。"..
  "此预测在一名角色使用牌时揭示，若所有预测均已揭示，称为全部验证。",
  ["yance_prey"] = "获得一张锦囊牌",
  ["yance_yance"] = "执行“卧龙演策”",
  ["#yance-choice"] = "演策：预测将被使用的牌（第%arg张，共%arg2张）",
  ["@[yance]"] = "卧龙演策",
  ["#yance_trigger"] = "演策",
  ["#yance-prey"] = "演策：获得一张符合声明条件的牌",

  ["$yance1"] = "以今日之时局，唯以此策解之。",
  ["$yance2"] = "今世变化难测，需赖以演策之术。",
  ["$yance3"] = "百策百中，勤在推演而已。",
  ["$yance4"] = "哎，算计百般，终是徒劳。",
  ["$yance5"] = "所谓算无遗策，亦不过如此而已。",
  ["$yance6"] = "吾已尽全力，奈何老天仍胜我一筹。",
  ["$yance7"] = "未思周密，使敌有残喘之机。",
}
local fangqiu = fk.CreateTriggerSkill{
  name = "fangqiu",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {"fk.AfterYance"},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#fangqiu-invoke")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "fangqiu_trigger", 1)
    local mark = player:getMark("@[yance]")
    mark.players = table.map(room.players, Util.IdMapper)
    room:setPlayerMark(player, "@[yance]", mark)
  end,
}
friend__zhugeliang:addSkill(fangqiu)
Fk:loadTranslationTable{
  ["fangqiu"] = "方遒",
  [":fangqiu"] = "限定技，当你执行“卧龙演策”后，你可以展示你的“卧龙演策”预测，若如此做，本次“卧龙演策”的预测全部验证后，执行效果的值均+1。",
  ["#fangqiu-invoke"] = "方遒：是否令本次“卧龙演策”预测公开？全部验证后执行的效果+1",

  ["$fangqiu1"] = "一举可成之事，何必再增变数。",
  ["$fangqiu2"] = "破敌便在此刻，吾等勿负良机。",
  ["$fangqiu3"] = "哈哈哈哈，果不出我所料。",
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
  ["$zhugeliang__gongli1"] = "其志远兮，当与诤友共进。",
  ["$zhugeliang__gongli2"] = "共以济世为志，今与诸兄勉之。",
}
local friend__pangtong = General(extension, "m_friend__pangtong", "qun", 3)
Fk:loadTranslationTable{
  ["m_friend__pangtong"] = "友庞统",
  ["#m_friend__pangtong"] = "凤翥南地",
  --["illustrator:m_friend__pangtong"] = "",
  ["~m_friend__pangtong"] = "大事未竟，惜哉，惜哉……",
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
  ["$friend__manjuan1"] = "十行俱下犹觉浅，一朝闭门书五车。",
  ["$friend__manjuan2"] = "有此神目，何愁观之未遍。",
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
  ["$friend__yangming1"] = "但为国养士，为主选才耳。",
  ["$friend__yangming2"] = "贤人何其之多，但无识才之人也。",
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
  ["$pangtong__gongli1"] = "你我同有此志，更应砥砺共进。",
  ["$pangtong__gongli2"] = "三人同心，诸事可期。",
}

local friend__xushu = General(extension, "m_friend__xushu", "qun", 3)
Fk:loadTranslationTable{
  ["m_friend__xushu"] = "友徐庶",
  ["#m_friend__xushu"] = "潜悟诲人",
  --["illustrator:m_friend__xushu"] = "",
  ["~m_friend__xushu"] = "百姓陷于苦海，而吾却难以济之……",
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
  ["$xiaxing1"] = "大丈夫当行侠重义，仗剑天下。",
  ["$xiaxing2"] = "路见不平，拔刀相助，乃侠者之义也。",
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
  ["$qihui1"] = "天乃高且远，安可事事自下。",
  ["$qihui2"] = "吾等当上体天心，下济黎民。",
  ["$qihui3"] = "若除贪官恶吏，天下自为之一清。",
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
  ["$xushu__gongli1"] = "吾等并力同心相通，大事何不可成哉。",
  ["$xushu__gongli2"] = "以吾等之才，何不同辅一主，共成王霸之业。",
}

Fk:loadTranslationTable{
  ["m_friend__shitao"] = "友石韬",
  ["#m_friend__shitao"] = "",
  --["illustrator:m_friend__shitao"] = "",
  ["~m_friend__shitao"] = "",
}
Fk:loadTranslationTable{
  ["qinying"] = "钦英",
  [":qinying"] = "出牌阶段限一次，你可以重铸任意张牌，视为使用一张【决斗】。若如此做，此【决斗】结算过程中限X次（X为你以此法重铸的牌数），"..
  "你或目标角色可以弃置区域中的一张牌，视为打出一张【杀】。",
}
Fk:loadTranslationTable{
  ["lunxiong"] = "论雄",
  [":lunxiong"] = "当你造成或受到伤害后，你可以弃置点数唯一最大的手牌，然后你摸三张牌，你本局游戏以此法弃置牌的点数须大于此牌。",
}
Fk:loadTranslationTable{
  ["shitao__gongli"] = "共砺",
  [":shitao__gongli"] = "锁定技，游戏开始时，你令本局〖钦英〗减少X个可用于弃置的类别的牌（X为全场友武将数）。",
}

local friend__cuijun = General(extension, "m_friend__cuijun", "qun", 3)
Fk:loadTranslationTable{
  ["m_friend__cuijun"] = "友崔钧",
  ["#m_friend__cuijun"] = "",
  --["illustrator:m_friend__cuijun"] = "",
  ["~m_friend__cuijun"] = "",
}
local shunyi = fk.CreateTriggerSkill{
  name = "shunyi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and-- not player:isKongcheng() and
      U.IsUsingHandcard(player, data) and
      table.every(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number > data.card.number
      end) and
      table.contains(player:getMark(self.name), data.card.suit) and
      data.card.number > player:usedSkillTimes(self.name, Player.HistoryTurn)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    --if table.find(player:getCardIds("h"), function (id)
    --  return Fk:getCardById(id).suit == data.card.suit
    --end) then
      return room:askForSkillInvoke(player, self.name, nil, "#shunyi-invoke:::"..data.card:getSuitString(true))
    --else
    --  room:askForCard(player, 1, 1, false, self.name, true, "false", "#shunyi-invoke:::"..data.card:getSuitString(true))
    --end
  end,
  on_use = function (self, event, target, player, data)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).suit == data.card.suit
    end)
    if #cards > 0 then
      player:addToPile("$shunyi", cards, false, self.name, player.id)
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
local shunyi_delay = fk.CreateTriggerSkill{
  name = "#shunyi_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("$shunyi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$shunyi"), Player.Hand, player, fk.ReasonJustMove, "shunyi")
  end,
}
shunyi:addRelatedSkill(shunyi_delay)
friend__cuijun:addSkill(shunyi)
Fk:loadTranslationTable{
  ["shunyi"] = "顺逸",
  [":shunyi"] = "当你使用点数唯一最小的手牌时，若此牌的花色为<font color='red'>♥</font>且点数大于X（X为你本回合发动本技能的次数），你可以将"..
  "此花色的所有手牌扣置于武将牌上直至当前回合结束，然后你摸一张牌。",
  ["#shunyi-invoke"] = "顺逸：是否将所有%arg手牌置于武将牌上直到回合结束并摸一张牌？",
  ["$shunyi"] = "顺逸",
  ["#shunyi_delay"] = "顺逸",
}
local biwei = fk.CreateActiveSkill{
  name = "biwei",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#biwei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected, player)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select) and
      not player:prohibitDiscard(to_select) and
      not table.find(player:getCardIds("h"), function (id)
        return id ~= to_select and Fk:getCardById(id).number >= Fk:getCardById(to_select).number
      end)
  end,
  target_filter = function(self, to_select, selected, _, _, _, player)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = Fk:getCardById(effect.cards[1]).number
    room:throwCard(effect.cards, self.name, player, player)
    if target.dead then return end
    local cards = table.filter(target:getCardIds("h"), function (id)
      return Fk:getCardById(id).number >= n and not target:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(cards, self.name, target, target)
    else
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    end
  end,
}
friend__cuijun:addSkill(biwei)
Fk:loadTranslationTable{
  ["biwei"] = "鄙位",
  [":biwei"] = "出牌阶段限一次，你可以弃置一张点数唯一最大的手牌并选择一名其他角色，令其弃置所有点数不小于此牌的手牌。若其未因此弃置牌，复原此技能。",
  ["#biwei"] = "鄙位：弃置点数唯一最大的手牌，令一名角色弃置所有点数不小于此牌的手牌",
}
local cuijun__gongli = fk.CreateTriggerSkill{
  name = "cuijun__gongli",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:hasSkill("shunyi", true) and
      table.find(player.room.alive_players, function (p)
        return p.general:startsWith("m_friend__") or p.deputyGeneral:startsWith("m_friend__")
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p.general:startsWith("m_friend__") then
        n = n + 1
      end
      if p.deputyGeneral:startsWith("m_friend__") then
        n = n + 1
      end
      if n > 2 then break end
    end
    if n == 3 then
      room:setPlayerMark(player, "shunyi", {Card.Spade, Card.Heart, Card.Club, Card.Diamond})
    else
      local choices = room:askForChoices(player, {"log_spade", "log_club", "log_diamond"}, n, n, self.name,
        "#cuijun__gongli-choice:::"..n, false)
      choices = table.map(choices, function (s)
        return U.ConvertSuit(s, "sym", "int")
      end)
      local mark = {Card.Heart}
      table.insertTable(mark, choices)
      room:setPlayerMark(player, "shunyi", mark)
    end
  end,
}
friend__cuijun:addSkill(cuijun__gongli)
Fk:loadTranslationTable{
  ["cuijun__gongli"] = "共砺",
  [":cuijun__gongli"] = "锁定技，游戏开始时，你令〖顺逸〗增加X个可触发的花色（X为全场友武将数）。",
  ["#cuijun__gongli-choice"] = "共砺：为“顺逸”增加%arg个可触发花色",
}

return extension
