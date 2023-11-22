local extension = Package("benevolence")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["benevolence"] = "手杀-始计篇·仁",
}

---@param room Room @ 房间
---@return integer[]
local function GetRenPile(room)
  room.tag["ren"] = room.tag["ren"] or {}
  return table.simpleClone(room.tag["ren"])
end

local function NotifyRenPile(room)
  room:sendLog{
    type = "#NotifyRenPile",
    arg = #GetRenPile(room),
    card = GetRenPile(room),
  }
  room:doBroadcastNotify("ShowToast", Fk:translate("RenPileToast")..table.concat(table.map(GetRenPile(room), function(id)
    return Fk:getCardById(id):toLogString() end), "、"))
end

---@param room Room @ 房间
---@param card integer|integer[]|Card|Card[] @ 要加入仁区的牌/id/intList
---@param skillName string @ 移动的技能名
---@param proposer integer @ 移动操作者的id
local function AddToRenPile(room, card, skillName, proposer)
  local ids = Card:getIdList(card)
  room.tag["ren"] = room.tag["ren"] or {}
  local ren_cards = table.simpleClone(room.tag["ren"])
  if #ids + #ren_cards <= 6 then
    table.insertTable(room.tag["ren"], ids)
  else
    local rens = {}
    if #ids >= 6 then
      for i = 1, 6, 1 do
        table.insert(rens, ids[i])
      end
    else
      local n = #ids + #ren_cards - 6
      for i = n + 1, #ren_cards, 1 do
        table.insert(rens, ren_cards[i])
      end
      table.insertTable(rens, ids)
    end
    room.tag["ren"] = rens
  end
  local dummy = Fk:cloneCard("dilu")
  dummy:addSubcards(table.filter(ids, function(id) return table.contains(room.tag["ren"], id) end))
  room:moveCardTo(dummy, Card.Void, nil, fk.ReasonJustMove, skillName, nil, true, proposer)
  room:sendLog{
    type = "#AddToRenPile",
    arg = #dummy.subcards,
    card = dummy.subcards,
  }

  local dummy2 = Fk:cloneCard("dilu")
  dummy2:addSubcards(table.filter(ren_cards, function(id) return not table.contains(room.tag["ren"], id) end))
  if #dummy2.subcards > 0 then
    room:moveCardTo(dummy2, Card.DiscardPile, nil, fk.ReasonJustMove, "ren_overflow", nil, true, nil)
    room:sendLog{
      type = "#OverflowFromRenPile",
      arg = #dummy2.subcards,
      card = dummy2.subcards,
    }
  end

  NotifyRenPile(room)
end

---@param room Room @ 房间
---@param player ServerPlayer @ 获得牌的角色
---@param cid integer|Card @ 要获得的牌/id
---@param skillName string @ 技能名
local function GetCardFromRenPile(room, player, cid, skillName)
  skillName = skillName or ""
  if type(cid) ~= "number" then
    cid = cid:isVirtual() and cid.subcards or {cid.id}
  else
    cid = {cid}
  end
  if #cid == 0 then return end
  local move = {
    ids = cid,
    to = player.id,
    toArea = Card.PlayerHand,
    moveReason = fk.ReasonJustMove,
    proposer = player.id,
    moveVisible = true,
    skillName = skillName,
  }
  room.logic:trigger("fk.BeforeRenMove", nil, move)
  room:moveCards(move)
  room.logic:trigger("fk.AfterRenMove", nil, move)
  for _, id in ipairs(cid) do
    table.removeOne(room.tag["ren"], id)
  end
  room:sendLog{
    type = "#GetCardFromRenPile",
    from = player.id,
    arg = #cid,
    card = cid,
  }
  NotifyRenPile(room)
end

---@param room Room @ 房间
---@param player ServerPlayer @ 弃置牌的角色
---@param ids integer|integer[] @ 要弃置的id/idList
---@param skillName string @ 技能名
local function DiscardCardFromRenPile(room, player, ids, skillName)
  skillName = skillName or ""
  if type(ids) ~= "number" then
    ids = ids
  else
    ids = {ids}
  end
  if #ids == 0 then return end
  local move = {
    ids = ids,
    toArea = Card.DiscardPile,
    moveReason = fk.ReasonDiscard,
    proposer = player.id,
    moveVisible = true,
    skillName = skillName,
  }
  room.logic:trigger("fk.BeforeRenMove", nil, move)
  room:moveCards(move)
  room.logic:trigger("fk.AfterRenMove", nil, move)
  for _, id in ipairs(ids) do
    table.removeOne(room.tag["ren"], id)
  end
  room:sendLog{
    type = "#DiscardCardFromRenPile",
    from = player.id,
    arg = #ids,
    card = ids,
  }
  NotifyRenPile(room)
end

Fk:loadTranslationTable{
  ["#NotifyRenPile"] = "“仁”区现有 %arg 张牌 %card",
  ["RenPileToast"] = "仁区：",
  ["#AddToRenPile"] = "%arg 张牌被移入“仁”区 %card",
  ["#OverflowFromRenPile"] = "%arg 张牌从“仁”区溢出 %card",
  ["#GetCardFromRenPile"] = "%from 从“仁”区获得 %arg 张牌 %card",
  ["#DiscardCardFromRenPile"] = "%from 弃置了“仁”区 %arg 张牌 %card",
  ["$RenPile"] = "仁区",
}

local huaxin = General(extension, "mobile__huaxin", "wei", 3)
local yuanqing = fk.CreateTriggerSkill{
  name = "yuanqing",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonUse then
            for _, info in ipairs(move.moveInfo) do
              if player.room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      end, Player.HistoryTurn) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player.id and move.moveReason == fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            if player.room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    local cards = {}
    for _, type in ipairs({Card.TypeBasic, Card.TypeTrick, Card.TypeEquip}) do
      table.insert(cards, table.random(table.filter(ids, function(id) return Fk:getCardById(id).type == type end)))
    end
    table.shuffle(cards)
    AddToRenPile(room, cards, self.name, player.id)
  end,
}
local shuchen = fk.CreateTriggerSkill{
  name = "shuchen",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #GetRenPile(player.room) > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(GetRenPile(room))
    GetCardFromRenPile(room, player, dummy, self.name)
    if not target.dead and target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
huaxin:addSkill(yuanqing)
huaxin:addSkill(shuchen)
Fk:loadTranslationTable{
  ["mobile__huaxin"] = "华歆",
  ["yuanqing"] = "渊清",
  [":yuanqing"] = "锁定技，出牌阶段结束时，你随机将弃牌堆中你本回合因使用而置入弃牌堆的牌中的每种类别各一张牌置入“仁”区。"..
  "<br/><font color='grey'>#\"<b>仁区</b>\"<br/>"..
  "仁区是一个存于场上，用于存放牌的公共区域。<br>仁区中的牌上限为6张，当仁区中的牌超过6张时，最先置入仁区中的牌将置入弃牌堆。",
  ["shuchen"] = "疏陈",
  [":shuchen"] = "锁定技，当一名角色进入濒死状态时，若“仁”牌数至少为4，你获得所有“仁”牌，然后令其回复1点体力。",

  ["$yuanqing1"] = "怀瑾瑜，握兰桂，而心若芷萱。",
  ["$yuanqing2"] = "嘉言懿行，如渊之清，如玉之洁。",
  ["$shuchen1"] = "陛下应先留心于治道，以征伐为后事也。",
  ["$shuchen2"] = "陛下若修文德，察民疾苦，则天下幸甚。",
  ["~mobile__huaxin"] = "为虑国计，身损可矣……",
}

local caizhenji = General(extension, "caizhenji", "wei", 3, 3, General.Female)
local sheyi = fk.CreateTriggerSkill{
  name = "sheyi",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.hp < player.hp and #player:getCardIds("he") >= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, player.hp, 999, true, self.name, true, ".", "#sheyi-invoke::"..target.id..":"..player.hp)
    if #cards >= player.hp then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(self.cost_data)
    player.room:obtainCard(target, dummy, false, fk.ReasonGive)
    return true
  end,
}
local tianyin = fk.CreateTriggerSkill{
  name = "tianyin",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local types = {}
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.from == player.id then
          table.insertIfNeed(types, use.card:getTypeString())
        end
      end, Player.HistoryTurn)
      return #types < 3
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      if use.from == player.id then
        table.removeOne(types, use.card:getTypeString())
      end
    end, Player.HistoryTurn)
    local cards = {}
    for _, type in ipairs(types) do
      local card = room:getCardsFromPileByRule(".|.|.|.|.|"..type)
      if card then
        table.insertIfNeed(cards, card[1])
      end
    end
    room:moveCards({
      ids = cards,
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("tianyin-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.card:getTypeString())
    room:setPlayerMark(player, "tianyin-turn", mark)
    if player:hasSkill(self) then
      room:setPlayerMark(player, "@tianyin-turn", #mark)
    end
  end,
}
caizhenji:addSkill(sheyi)
caizhenji:addSkill(tianyin)
Fk:loadTranslationTable{
  ["caizhenji"] = "蔡贞姬",
  ["sheyi"] = "舍裔",
  [":sheyi"] = "每轮限一次，当一名其他角色受到伤害时，若其体力值小于你，你可以交给其至少X张牌，防止此伤害（X为你的体力值）。",
  ["tianyin"] = "天音",
  [":tianyin"] = "锁定技，结束阶段，你从牌堆中获得你本回合未使用过类型的牌各一张。",
  ["#sheyi-invoke"] = "舍裔：你可以交给 %dest 至少%arg张牌，防止其受到的伤害",
  ["@tianyin-turn"] = "天音",

  ["$sheyi1"] = "二子不可兼顾，妾身唯保其一。",
  ["$sheyi2"] = "吾子虽弃亦可，前遗万勿有失。",
  ["$tianyin1"] = "抚琴体清心远，方成自然之趣。",
  ["$tianyin2"] = "心怀雅正，天音自得。",
  ["~caizhenji"] = "世誉吾为贤妻，吾愧终不为良母……",
}

local xiangchong = General(extension, "xiangchong", "shu", 4)
local guying = fk.CreateTriggerSkill{
  name = "guying",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        if player.phase == Player.NotActive and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
          and player.room.current and not player.room.current.dead then
          for _, move in ipairs(data) do
            if move.from == player.id and #move.moveInfo == 1 and
              table.contains({fk.ReasonUse, fk.ReasonResonpse, fk.ReasonDiscard}, move.moveReason) then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  return true
                end
              end
            end
          end
        end
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:doIndicate(player.id, {room.current.id})
      local id
      for _, move in ipairs(data) do
        if move.from == player.id and #move.moveInfo == 1 and
          table.contains({fk.ReasonUse, fk.ReasonResonpse, fk.ReasonDiscard}, move.moveReason) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              id = info.cardId
              break
            end
          end
        end
      end
      local choices = {}
      if room:getCardArea(id) == Card.Processing then
        table.insert(choices, "guying_get:"..player.id.."::"..Fk:getCardById(id, true):toLogString())
      end
      if not room.current:isNude() then
        table.insert(choices, "guying_give:"..player.id)
      end
      if #choices == 0 then return end
      local choice = room:askForChoice(room.current, choices, self.name, "#guying-invoke:"..player.id)
      if choice[9] == "e" then
        room:obtainCard(player.id, id, true, fk.ReasonJustMove)
        if Fk:getCardById(id).type == Card.TypeEquip and room:getCardOwner(id) == player and room:getCardArea(id) == Card.PlayerHand and
          not player:prohibitUse(Fk:getCardById(id)) then
          room:useCard({
            from = player.id,
            tos = {{player.id}},
            card = Fk:getCardById(id),
          })
        end
      else
        local card = room:askForCard(room.current, 1, 1, true, self.name, false, ".", "#guying-give:"..player.id)
        room:obtainCard(player.id, card[1], false, fk.ReasonGive)
      end
    else
      local n = player:usedSkillTimes(self.name, Player.HistoryGame) - 1
      player:setSkillUseHistory(self.name, 0, Player.HistoryGame)
      room:askForDiscard(player, n, n, true, self.name, false)
    end
  end,
}
local muzhen = fk.CreateActiveSkill{
  name = "muzhen",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  prompt = function(self)
    if self.interaction.data == "muzhen1" then
      return "#muzhen1"
    elseif self.interaction.data == "muzhen2" then
      return "#muzhen2"
    end
  end,
  interaction = function(self)
    local names = {}
    for _, name in ipairs({"muzhen1", "muzhen2"}) do
      if Self:getMark(name.."-phase") == 0 then
        table.insert(names, name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  can_use = function(self, player)
    return (player:getMark("muzhen1-phase") == 0 or player:getMark("muzhen2-phase") == 0) and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == "muzhen1" then
      return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
    elseif self.interaction.data == "muzhen2" then
      return #selected < 2
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "muzhen1" then
        return #selected_cards == 1 and #target:getAvailableEquipSlots(Fk:getCardById(selected_cards[1]).sub_type) > 0
      elseif self.interaction.data == "muzhen2" then
        return #selected_cards == 2 and #target:getCardIds("e") > 0
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data.."-phase", 1)
    if self.interaction.data == "muzhen1" then
      room:moveCards({
        ids = effect.cards,
        from = effect.from,
        to = effect.tos[1],
        toArea = Card.PlayerEquip,
        skillName = self.name,
        moveReason = fk.ReasonPut,
      })
      if not (player.dead or target.dead or target:isKongcheng()) then
        local id = room:askForCardChosen(player, target, "h", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      end
    elseif self.interaction.data == "muzhen2" then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(effect.cards)
      room:obtainCard(target.id, dummy, false, fk.ReasonGive)
      if not (player.dead or target.dead or #target:getCardIds("e") == 0) then
        local id = room:askForCardChosen(player, target, "e", self.name)
        room:obtainCard(player.id, id, false, fk.ReasonPrey)
      end
    end
  end,
}
xiangchong:addSkill(guying)
xiangchong:addSkill(muzhen)
Fk:loadTranslationTable{
  ["xiangchong"] = "向宠",
  ["guying"] = "固营",
  [":guying"] = "锁定技，每回合限一次，当你于回合外因使用、打出或弃置一次性仅失去一张牌后，当前回合角色须选择一项：1.你获得此牌（若为装备则使用之）；"..
  "2.交给你一张牌。准备阶段，你须弃置X张牌（X为本技能发动次数），然后重置此技能发动次数。",
  ["muzhen"] = "睦阵",
  [":muzhen"] = "出牌阶段各限一次，你可以：将一张装备牌置于一名其他角色装备区内，然后获得其一张手牌；交给一名装备区内有牌的其他角色两张牌，"..
  "然后获得其装备区内一张牌。",
  ["guying_get"] = "令%src获得%arg",
  ["guying_give"] = "交给%src一张牌",
  ["#guying-invoke"] = "固营：请选择 %src 执行的一项",
  ["#guying-give"] = "固营：请交给 %src 一张牌",
  ["muzhen1"] = "置入一张装备，获得一张手牌",
  ["muzhen2"] = "交给两张牌，获得一张装备",
  ["#muzhen1"] = "睦阵：你可以选择一张装备牌执行效果",
  ["#muzhen2"] = "睦阵：你可以选择两张牌，选一名有装备的角色执行",

  ["$guying1"] = "我军之营，犹如磐石之固！",
  ["$guying2"] = "深壁固垒，敌军莫敢来侵！",
  ["$muzhen1"] = "行阵和睦，方可优劣得所。",
  ["$muzhen2"] = "识时达务，才可上和下睦。",
  ["~xiangchong"] = "蛮夷怀异，战乱难平……",
}

local zhangwen = General(extension, "mobile__zhangwen", "wu", 3)
local gebo = fk.CreateTriggerSkill{
  name = "gebo",
  frequency = Skill.Compulsory,
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    AddToRenPile(room, room:getNCards(1), self.name, player.id)
  end,
}
local mobile__songshu = fk.CreateTriggerSkill{
  name = "mobile__songshu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Draw and target.hp > player.hp and #GetRenPile(player.room) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__songshu-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:setPlayerMark(target, "@@mobile__songshu-turn", 1)
    local n = math.min(player.hp, 5, #GetRenPile(room))
    local all_cards = GetRenPile(room)
    local cards = U.askforChooseCardsAndChoice(target, all_cards, {"OK"}, self.name, "#mobile__songshu-choose:::"..n, nil, n, n, all_cards)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    GetCardFromRenPile(room, target, dummy, self.name)
    return true
  end,
}
local mobile__songshu_prohibit = fk.CreateProhibitSkill{
  name = "#mobile__songshu_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@mobile__songshu-turn") > 0 and from ~= to
  end,
}
mobile__songshu:addRelatedSkill(mobile__songshu_prohibit)
zhangwen:addSkill(gebo)
zhangwen:addSkill(mobile__songshu)
Fk:loadTranslationTable{
  ["mobile__zhangwen"] = "张温",
  ["gebo"] = "戈帛",
  [":gebo"] = "锁定技，一名角色回复体力后，你从牌堆顶将一张牌置于“仁”区中。"..
  "<br/><font color='grey'>#\"<b>仁区</b>\"<br/>"..
  "仁区是一个存于场上，用于存放牌的公共区域。<br>仁区中的牌上限为6张。<br>当仁区中的牌超过6张时，最先置入仁区中的牌将置入弃牌堆。",
  ["mobile__songshu"] = "颂蜀",
  [":mobile__songshu"] = "一名体力值大于你的其他角色摸牌阶段开始时，若“仁”区有牌，你可以令其放弃摸牌，然后获得X张“仁”区牌（X为你的体力值，且最大为5）。"..
  "若如此做，本回合其使用牌时不能指定其他角色为目标。",
  ["#mobile__songshu-invoke"] = "颂蜀：你可以令 %dest 放弃摸牌，改为获得“仁”，且其本回合其使用牌不能指定其他角色为目标",
  ["@@mobile__songshu-turn"] = "颂蜀",
  ["#mobile__songshu-choose"] = "颂蜀：获得%arg张“仁”区牌",

  ["$gebo1"] = "握手言和，永罢刀兵。",
  ["$gebo2"] = "重归于好，摒弃前仇。",
  ["$mobile__songshu1"] = "称美蜀政，祛其疑贰之心。",
  ["$mobile__songshu2"] = "蜀地君明民乐，实乃太平之治。",
  ["~mobile__zhangwen"] = "自招罪谴，诚可悲疚……",
}

local qiaogong = General(extension, "qiaogong", "wu", 3)
local yizhu = fk.CreateTriggerSkill{
  name = "yizhu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if player.dead or player:isNude() then return end
    local cards = room:askForCard(player, math.min(#player:getCardIds("he"), 2), 2, true, self.name, false, ".", "#yizhu-card")
    local mark = player:getMark("@$yizhu")
    if mark == 0 then mark = {} end
    local moves = {}
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id, true), self.name, id)
      table.insert(mark, Fk:getCardById(id, true).name)
      table.insert(moves, {
        ids = {id},
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = math.random(1, math.min(#room.draw_pile, math.max(2 * #room.alive_players , 1))),
      })
    end
    room:setPlayerMark(player, "@$yizhu", mark)
    room:moveCards(table.unpack(moves))
  end,
}
local yizhu_trigger = fk.CreateTriggerSkill{
  name = "#yizhu_trigger",
  mute = true,
  events = {fk.AfterCardsMove, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("yizhu") then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.toArea == Card.DiscardPile and move.extra_data and move.extra_data.yizhu then
            return true
          end
        end
      else
        return target ~= player and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 and
          data.card:getMark("yizhu") == data.card:getEffectiveId()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    else
      return player.room:askForSkillInvoke(player, "yizhu", nil, "#yizhu-invoke::"..target.id..":"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yizhu")
    if event == fk.AfterCardsMove then
      room:notifySkillInvoked(player, "yizhu", "drawcard")
      local n = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.extra_data and move.extra_data.yizhu then
          n = n + move.extra_data.yizhu
        end
      end
      player:drawCards(n, "yizhu")
    else
      room:notifySkillInvoked(player, "yizhu", "control")
      room:doIndicate(player.id, {data.to})
      AimGroup:cancelTarget(data, data.to)
      local id = data.card:getEffectiveId()
      local fakemove = {
        toArea = Card.PlayerHand,
        to = player.id,
        moveInfo = table.map({id}, function(c) return {cardId = c, fromArea = Card.Void} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      room:setPlayerMark(player, "yizhu_cards", {id})
      local success, dat = room:askForUseActiveSkill(player, "yizhu_viewas", "#yizhu-use:::"..data.card:toLogString(), true)
      room:setPlayerMark(player, "yizhu_cards", 0)
      fakemove = {
        from = player.id,
        toArea = Card.Void,
        moveInfo = table.map({id}, function(c) return {cardId = c, fromArea = Card.PlayerHand} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      if success then
        local card = Fk.skills["yizhu_viewas"]:viewAs(dat.cards)
        room:useCard{
          from = player.id,
          tos = table.map(dat.targets, function(c) return {c} end),
          card = card,
        }
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:getMark("@$yizhu") ~= 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId):getMark("yizhu") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local names = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        local n = 0
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId, true)
          if card:getMark("yizhu") > 0 then
            player.room:setCardMark(card, "yizhu", 0)
            table.insert(names, card.name)
            n = n + 1
          end
        end
        if n > 0 then
          move.extra_data = move.extra_data or {}
          move.extra_data.yizhu = n
        end
      end
    end
    if player:getMark("@$yizhu") ~= 0 then
      local mark = player:getMark("@$yizhu")
      for _, name in ipairs(names) do
        table.removeOne(mark, name)
      end
      if #mark == 0 then mark = 0 end
      player.room:setPlayerMark(player, "@$yizhu", mark)
    end
  end,
}
local yizhu_viewas = fk.CreateViewAsSkill{
  name = "yizhu_viewas",
  card_filter = function(self, to_select, selected)
    if #selected == 0 then
      local ids = Self:getMark("yizhu_cards")
      return type(ids) == "table" and table.contains(ids, to_select)
    end
  end,
  view_as = function(self, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
}
local luanchou = fk.CreateActiveSkill{
  name = "luanchou",
  anim_type = "support",
  card_num = 0,
  target_num = 2,
  prompt = "#luanchou",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    for _, p in ipairs(room.alive_players) do
      if table.contains(effect.tos, p.id) then
        room:setPlayerMark(p, "@@luanchou", 1)
        room:handleAddLoseSkills(p, "gonghuan", nil, true, false)
      elseif p:hasSkill("gonghuan", true) then
        room:setPlayerMark(p, "@@luanchou", 0)
        room:handleAddLoseSkills(p, "-gonghuan", nil, true, false)
      end
    end
  end,
}
local gonghuan = fk.CreateTriggerSkill{
  name = "gonghuan",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target:hasSkill(self.name, true) and not data.gonghuan and
      target.hp < player.hp and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local damage = table.simpleClone(data)
    damage.to = player
    damage.gonghuan = true
    room:damage(damage)
    if not player.dead and player.hp == target.hp then
      room:setPlayerMark(player, "@@luanchou", 0)
      room:handleAddLoseSkills(player, "-gonghuan", nil, true, false)
      room:setPlayerMark(target, "@@luanchou", 0)
      room:handleAddLoseSkills(target, "-gonghuan", nil, true, false)
    end
    return true
  end,
}
yizhu:addRelatedSkill(yizhu_trigger)
Fk:addSkill(yizhu_viewas)
qiaogong:addSkill(yizhu)
qiaogong:addSkill(luanchou)
qiaogong:addRelatedSkill(gonghuan)
Fk:loadTranslationTable{
  ["qiaogong"] = "桥公",
  ["yizhu"] = "遗珠",
  [":yizhu"] = "结束阶段，你摸两张牌，然后将两张牌作为「遗珠」随机洗入牌堆顶前2X张牌（X为存活角色数），并记录「遗珠」的牌名；"..
  "其他角色使用「遗珠」指定唯一目标后，你可以取消之，将此牌从「遗珠」记录中移除，然后你可以使用此牌。当「遗珠」进入弃牌堆时，你摸一张牌。",
  ["luanchou"] = "鸾俦",
  [":luanchou"] = "出牌阶段限一次，你可以移除场上所有「姻」标记并选择两名角色，令其获得「姻」。有「姻」的角色视为拥有技能〖共患〗。",
  ["gonghuan"] = "共患",
  [":gonghuan"] = "锁定技，每回合限一次，当另一名拥有「姻」的角色受到伤害时，若其体力值小于你，将此伤害转移给你；当你受到此伤害后，"..
  "若你与其体力值相等，移除你们的「姻」标记。",
  ["#yizhu-card"] = "遗珠：将两张牌作为“遗珠”洗入牌堆",
  ["@$yizhu"] = "遗珠",
  ["#yizhu-invoke"] = "遗珠：你可以取消 %dest 使用的%arg，然后你可以使用之",
  ["#yizhu-use"] = "遗珠：你可以使用%arg",
  ["yizhu_viewas"] = "遗珠",
  ["#luanchou"] = "鸾俦：令两名角色获得「姻」标记并获得技能〖共患〗",
  ["@@luanchou"] = "姻",

  ["$yizhu1"] = "老夫有二女，视之如明珠。",
  ["$yizhu2"] = "将军若得遇小女，万望护送而归。",
  ["$luanchou1"] = "愿汝永结鸾俦，以期共盟鸳蝶。",
  ["$luanchou2"] = "夫妻相濡以沫，方可百年偕老。",
  ["$gonghuan1"] = "曹魏势大，吴蜀当共拒之。",
  ["$gonghuan2"] = "两国得此联姻，邦交更当稳固。",
  ["~qiaogong"] = "为父所念，为汝二人啊……",
}

local zhangzhongjing = General(extension, "zhangzhongjing", "qun", 3)
local jishi = fk.CreateTriggerSkill{
  name = "jishi",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished, "fk.BeforeRenMove"},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.CardUseFinished then
        if target == player and not data.damageDealt then
          local room = player.room
          local subcards = data.card:isVirtual() and data.card.subcards or {data.card.id}
          return #subcards > 0 and table.every(subcards, function(id) return room:getCardArea(id) == Card.Processing end)
        end
      else
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name, "special")
      AddToRenPile(room, data.card, self.name, player.id)
    else
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(1, self.name)
    end
  end,
}
local liaoyi = fk.CreateTriggerSkill{
  name = "liaoyi",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local n = target:getHandcardNum() - target.hp
      return n ~= 0 and #GetRenPile(player.room) >= math.min(-n, 4)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local n = target:getHandcardNum() - target.hp
    local prompt
    if n < 0 then
      prompt = "#liaoyi1-invoke::"..target.id..":"..math.min(-n, 4)
    else
      prompt = "#liaoyi2-invoke::"..target.id..":"..math.min(n, 4)
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n = target:getHandcardNum() - target.hp
    if n < 0 then
      n = math.min(-n, 4)
      local all_cards = GetRenPile(room)
      local cards = U.askforChooseCardsAndChoice(target, all_cards, {"OK"}, self.name, "#liaoyi-choose:::"..n, nil, n, n, all_cards)
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      GetCardFromRenPile(room, target, dummy, self.name)
    else
      n = math.min(n, 4)
      local cards = room:askForCard(target, n, n, true, self.name, false, ".", "#liaoyi-put:::"..n)
      AddToRenPile(room, cards, self.name, target.id)
    end
  end,
}
local binglun = fk.CreateActiveSkill{
  name = "binglun",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#binglun",
  expand_pile = "$RenPile",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #player:getPile("$RenPile") > 0
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "$RenPile"
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    DiscardCardFromRenPile(room, player, effect.cards, self.name)
    if target.dead then return end
    local choices = {"draw1", "binglun_recover"}
    local choice = room:askForChoice(target, choices, self.name)
    if choice == "draw1" then
      target:drawCards(1, self.name)
    else
      room:setPlayerMark(target, self.name, 1)
    end
  end,
}
local binglun_trigger = fk.CreateTriggerSkill{
  name = "#binglun_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("binglun") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local src = table.find(room.players, function(p) return p:hasSkill("binglun", true) end)
    if src then
      src:broadcastSkillInvoke("binglun")
      room:notifySkillInvoked(src, "binglun", "support")
    end
    room:setPlayerMark(player, "binglun", 0)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = src,
        skillName = "binglun",
      })
    end
  end,

  refresh_events = {fk.StartPlayCard},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player.special_cards["$RenPile"] = table.simpleClone(GetRenPile(room))
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
  end,
}
binglun:addRelatedSkill(binglun_trigger)
zhangzhongjing:addSkill(jishi)
zhangzhongjing:addSkill(liaoyi)
zhangzhongjing:addSkill(binglun)
Fk:loadTranslationTable{
  ["zhangzhongjing"] = "张仲景",
  ["jishi"] = "济世",
  [":jishi"] = "锁定技，你使用牌结算结束后，若此牌没有造成伤害，则将之置入“仁”区；当“仁”牌不因溢出而离开“仁”区时，你摸一张牌。"..
  "<br/><font color='grey'>#\"<b>仁区</b>\"<br/>"..
  "仁区是一个存于场上，用于存放牌的公共区域。<br>仁区中的牌上限为6张。<br>当仁区中的牌超过6张时，最先置入仁区中的牌将置入弃牌堆。",
  ["liaoyi"] = "疗疫",
  [":liaoyi"] = "其他角色回合开始时，若其手牌数小于体力值且场上“仁”数量不小于X，则你可以令其获得X张“仁”；若其手牌数大于体力值，"..
  "则可以令其将X张牌置入“仁”区（X为其手牌数与体力值差值，且至多为4）。",
  ["binglun"] = "病论",
  [":binglun"] = "出牌阶段限一次，你可以选择一名角色并弃置一张“仁”牌，令其选择：1.摸一张牌；2.其下个回合结束时回复1点体力。",
  ["#liaoyi1-invoke"] = "疗疫：你可以令 %dest 获得%arg张“仁”",
  ["#liaoyi2-invoke"] = "疗疫：你可以令 %dest 将%arg张牌置入“仁”区",
  ["#liaoyi-choose"] = "疗疫：获得%arg张“仁”区牌",
  ["#liaoyi-put"] = "疗疫：你需将%arg张牌置入“仁”区",
  ["#binglun"] = "病论：你可以弃置一张“仁”区牌，令一名角色选择摸牌或其回合结束时回复体力",
  ["binglun_recover"] = "你下个回合结束时回复1点体力",

  ["$jishi1"] = "勤求古训，常怀济人之志。",
  ["$jishi2"] = "博采众方，不随趋势之徒。",
  ["$liaoyi1"] = "麻黄之汤，或可疗伤寒之疫。",
  ["$liaoyi2"] = "望闻问切，因病施治。",
  ["$binglun1"] = "受病有深浅，使药有轻重。",
  ["$binglun2"] = "三分需外治，七分靠内养。",
  ["~zhangzhongjing"] = "得人不传，恐成坠绪……",
}

local liuzhang = General(extension, "liuzhang", "qun", 3)
local jutu = fk.CreateTriggerSkill{
  name = "jutu",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("liuzhang_sheng") > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("liuzhang_sheng"))
      room:obtainCard(player.id, dummy, false, fk.ReasonJustMove)
    end
    if player.dead then return end
    if player:getMark("@yaohu") == 0 then
      player:drawCards(1, self.name)
    else
      local n = #table.filter(room.alive_players, function(p) return p.kingdom == player:getMark("@yaohu") end)
      player:drawCards(n + 1, self.name)
      if not player.dead and not player:isNude() then
        local cards = room:askForCard(player, n, n, true, self.name, false, ".", "#jutu-put:::"..n)
        local dummy2 = Fk:cloneCard("dilu")
        dummy2:addSubcards(cards)
        player:addToPile("liuzhang_sheng", dummy2, false, self.name)
      end
    end
  end,
}
local yaohu = fk.CreateTriggerSkill{
  name = "yaohu",
  anim_type = "special",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    local choice = room:askForChoice(player, kingdoms, self.name, "#yaohu-choice")
    room:setPlayerMark(player, "@yaohu", choice)
  end,
}
local yaohu_trigger = fk.CreateTriggerSkill{
  name = "#yaohu_trigger",
  mute = true,
  events = {fk.EventPhaseStart, fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player:hasSkill("yaohu") and target ~= player and target.phase == Player.Play and not target.dead and
        player:getMark("@yaohu") ~= 0 and target.kingdom == player:getMark("@yaohu") and #player:getPile("liuzhang_sheng") > 0
    else
      return target:getMark("@@yaohu-phase") == player.id and data.to == player.id and data.card.is_damage_card
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yaohu")
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, "yaohu", "support")
      room:doIndicate(player.id, {target.id})
      local id = room:askForCardChosen(target, player, {card_data = {{"yaohu", player:getPile("liuzhang_sheng")}}}, "yaohu")
      room:obtainCard(target.id, id, true, fk.ReasonPrey)
      if player.dead or target.dead then return end
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return target:inMyAttackRange(p) end), function(p) return p.id end)
      if #targets == 0 then
        room:setPlayerMark(target, "@@yaohu-phase", player.id)
      else
        local tos = room:askForChoosePlayers(player, targets, 1, 1, "#yaohu-choose::"..target.id, self.name, false, true)
        local victim
        if #tos > 0 then
          victim = tos[1]
        else
          victim = table.random(targets)
        end
        room:doIndicate(target.id, {victim})
        local use = room:askForUseCard(target, "slash", "slash",
          "#yaohu-slash:"..player.id..":"..victim, true, {must_targets = {victim}, bypass_times = true})
        if use then
          use.extraUse = true
          room:useCard(use)
        else
          room:setPlayerMark(target, "@@yaohu-phase", player.id)
        end
      end
    else
      room:notifySkillInvoked(player, "yaohu", "defensive")
      if #target:getCardIds("he") < 2 then
        AimGroup:cancelTarget(data, player.id)
      else
        local cards = room:askForCard(target, 2, 2, true, "yaohu", true, ".", "#yaohu-give:"..player.id.."::"..data.card:toLogString())
        if #cards == 2 then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(cards)
          room:obtainCard(player.id, dummy, false, fk.ReasonGive)
        else
          AimGroup:cancelTarget(data, player.id)
        end
      end
    end
  end,
}
local huaibi = fk.CreateMaxCardsSkill{
  name = "huaibi$",
  frequency = Skill.Compulsory,
  correct_func = function(self, player)
    if player:hasSkill(self) and player:getMark("@yaohu") ~= 0 then
      return #table.filter(Fk:currentRoom().alive_players, function(p) return p.kingdom == player:getMark("@yaohu") end)
    end
    return 0
  end,
}
yaohu:addRelatedSkill(yaohu_trigger)
liuzhang:addSkill(jutu)
liuzhang:addSkill(yaohu)
liuzhang:addSkill(huaibi)
Fk:loadTranslationTable{
  ["liuzhang"] = "刘璋",
  ["jutu"] = "据土",
  [":jutu"] = "锁定技，准备阶段，你获得所有所有的“生”，摸X+1张牌，然后将X张牌置于你的武将牌上，称为“生”（X为你〖邀虎〗选择势力的角色数）。",
  ["yaohu"] = "邀虎",
  [":yaohu"] = "①每轮限一次，你的回合开始时，你须选择场上一个势力。②此势力的其他角色出牌阶段开始时，其获得你的一张“生”，然后其须选择一项："..
  "1.对你指定的一名其攻击范围内的其他角色使用一张不计入次数的【杀】；2.本阶段其使用伤害类牌指定你为目标时，须交给你两张牌，否则取消之。",
  ["huaibi"] = "怀璧",
  [":huaibi"] = "主公技，锁定技，你的手牌上限+X（X为你〖邀虎〗选择势力的角色数）。",
  ["liuzhang_sheng"] = "生",
  ["#jutu-put"] = "据土：请将%arg张牌置为“生”",
  ["#yaohu-choice"] = "邀虎：选择你要“邀虎”的势力",
  ["@yaohu"] = "邀虎",
  ["#yaohu_trigger"] = "邀虎",
  ["@@yaohu-phase"] = "邀虎",
  ["#yaohu-choose"] = "邀虎：选择令 %dest 使用【杀】的目标",
  ["#yaohu-slash"] = "邀虎：你需对 %dest 使用一张【杀】，否则本阶段使用伤害牌指定 %src 为目标时需交给其牌",
  ["#yaohu-give"] = "邀虎：你需交给 %src 两张牌，否则其取消此%arg",

  ["$jutu1"] = "百姓安乐足矣，穷兵黩武实不可取啊。",
  ["$jutu2"] = "内乱初定，更应休养生息。",
  ["$yaohu1"] = "益州疲敝，还望贤兄相助。",
  ["$yaohu2"] = "内讨米贼，外拒强曹，璋无宗兄万万不可啊。",
  ["$huaibi1"] = "哎！匹夫无罪，怀璧其罪啊。",
  ["$huaibi2"] = "粮草尽皆在此，宗兄可自取之。",
  ["~liuzhang"] = "引狼入室，噬脐莫及啊！",
}

local godhuatuo = General(extension, "godhuatuo", "god", 3)
local wuling = fk.CreateActiveSkill{
  name = "wuling",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#wuling",
  expand_pile = "$RenPile",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark(self.name) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local all_choices = table.map({1, 2, 3, 4, 5}, function(i) return "wuling"..i end)
    local choices = table.simpleClone(all_choices)
    local result = {}
    for i = 1, 5, 1 do
      local choice = room:askForChoice(player, choices, self.name,
        "#wuling-choice::"..target.id..":"..table.concat(table.map(result, function(s) return Fk:translate(s) end), "、"), true)
      table.removeOne(choices, choice)
      table.insert(result, choice)
    end
    room:setPlayerMark(target, self.name, result)
    room:setPlayerMark(target, "wuling_invoke", tonumber(result[1][7]))
    room:setPlayerMark(target, "@wuling", "<font color='red'>"..Fk:translate(result[1]).."</font>"..
      table.concat(table.map(result, function(s) return Fk:translate(s) end), "", 2, 5))
    if result[1] == "wuling2" and (target:isWounded() or #target:getCardIds("j") > 0) then
      if target:isWounded() then
        room:recover{
          who = player,
          num = 1,
          skillName = self.name
        }
      end
      if not target.dead and #target:getCardIds("j") > 0 then
        target:throwAllCards("j")
      end
    end
  end,
}
local wuling_trigger = fk.CreateTriggerSkill{
  name = "#wuling_trigger",
  mute = true,
  events = {fk.DamageCaused, fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("wuling_invoke") ~= 0 then
      if event == fk.DamageCaused then
        if player:getMark("wuling_invoke") == 1 and data.card then
          local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
          if e then
            local use = e.data[1]
            return #use.tos == 1 and use.tos[1][1] == data.to.id
          end
        end
      elseif event == fk.DamageInflicted then
        return player:getMark("wuling_invoke") == 3
      elseif event == fk.EventPhaseStart then
        if player.phase == Player.Start then
          return true
        elseif player.phase == Player.Play then
          return (player:getMark("wuling_invoke") == 4 and table.find(player.room:getOtherPlayers(player), function(p)
            return #p:getCardIds("e") > 0 end)) or player:getMark("wuling_invoke") == 5
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("wuling")
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, "wuling", "offensive")
      data.damage = data.damage + 1
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, "wuling", "defensive")
      data.damage = data.damage - 1
    elseif event == fk.EventPhaseStart then
      if player.phase == Player.Start then
        room:notifySkillInvoked(player, "wuling", "special")
        local result = player:getMark("wuling")
        local n = player:getMark("wuling_invoke")
        local new_index = table.indexOf(result, "wuling"..n) + 1
        if new_index > 5 then
          new_index = 1
        end
        room:setPlayerMark(player, "wuling_invoke", tonumber(result[new_index][7]))
        local new_str = ""
        for i = 1, 5, 1 do
          if i == new_index then
            new_str = new_str .. "<font color='red'>"..Fk:translate(result[i]).."</font>"
          else
            new_str = new_str .. Fk:translate(result[i])
          end
        end
        room:setPlayerMark(player, "@wuling", new_str)
        if result[new_index] == "wuling2" and (player:isWounded() or #player:getCardIds("j") > 0) then
          if player:isWounded() then
            room:recover{
              who = player,
              num = 1,
              skillName = self.name
            }
          end
          if not target.dead and #target:getCardIds("j") > 0 then
            target:throwAllCards("j")
          end
        end
      elseif player.phase == Player.Play then
        if player:getMark("wuling_invoke") == 4 then
          room:notifySkillInvoked(player, "wuling", "control")
          local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return #p:getCardIds("e") > 0 end), Util.IdMapper)
          local to = room:askForChoosePlayers(player, targets, 1, 1, "#wuling-choose", "wuling", true)
          if #to > 0 then
            room:obtainCard(player.id, table.random(room:getPlayerById(to[1]):getCardIds("e")), true, fk.ReasonPrey)
          end
        elseif player:getMark("wuling_invoke") == 5 then
          room:notifySkillInvoked(player, "wuling", "drawcard")
          player:drawCards(2, "wuling")
        end
      end
    end
  end,
}
local wuling_prohibit = fk.CreateProhibitSkill{
  name = "#wuling_prohibit",
  is_prohibited = function(self, from, to, card)
    return to:getMark("wuling_invoke") == 2 and card and card.sub_type == Card.SubtypeDelayedTrick
  end,
}
local youyi = fk.CreateActiveSkill{
  name = "youyi",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  prompt = "#youyi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #player:getPile("$RenPile") > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    DiscardCardFromRenPile(room, player, GetRenPile(room), self.name)
    for _, p in ipairs(room.alive_players) do
      if not p.dead and p:isWounded() then
        room:recover{
          who = p,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
  end,
}
local youyi_trigger = fk.CreateTriggerSkill{
  name = "#youyi_trigger",
  main_skill = youyi,
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Discard then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if player.room:getCardArea(info.cardId) == Card.DiscardPile then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "youyi", nil, "#youyi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("youyi")
    room:notifySkillInvoked(player, "youyi", "special")
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if player.room:getCardArea(info.cardId) == Card.DiscardPile then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryPhase)
    table.shuffle(ids)
    AddToRenPile(room, ids, self.name, player.id)
  end,

  refresh_events = {fk.StartPlayCard},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player.special_cards["$RenPile"] = table.simpleClone(GetRenPile(room))
    player:doNotify("ChangeSelf", json.encode {
      id = player.id,
      handcards = player:getCardIds("h"),
      special_cards = player.special_cards,
    })
  end,
}
wuling:addRelatedSkill(wuling_trigger)
wuling:addRelatedSkill(wuling_prohibit)
youyi:addRelatedSkill(youyi_trigger)
godhuatuo:addSkill(wuling)
godhuatuo:addSkill(youyi)
Fk:loadTranslationTable{
  ["godhuatuo"] = "神华佗",
  ["wuling"] = "五灵",
  [":wuling"] = "出牌阶段限一次，你可以选择一名没有“五灵”标记的角色，按照你选择的顺序向其传授“五禽戏”。拥有“五灵”标记的角色在其准备阶段"..
  "按照传授的顺序依次切换为下一种效果：<br>"..
  "虎：当你使用指定唯一目标的牌对目标角色造成伤害时，此伤害+1。<br>"..
  "鹿：回复1点体力并弃置判定区里的所有牌，你不能成为延时锦囊牌的目标。<br>"..
  "熊：当你受到伤害时，此伤害-1。<br>"..
  "猿：出牌阶段开始时，你选择一名其他角色，随机获得其装备区里的一张牌。<br>"..
  "鹤：出牌阶段开始时，你摸两张牌。",
  ["youyi"] = "游医",
  [":youyi"] = "弃牌阶段结束时，你可以将此阶段弃置的牌置入“仁”区。出牌阶段限一次，你可以弃置所有“仁”区的牌，令所有角色回复1点体力。",
  ["#wuling"] = "五灵：向一名角色传授“五禽戏”",
  ["#wuling-choice"] = "五灵：选择向 %dest 传授“五禽戏”的顺序<br>已选择：%arg",
  ["wuling1"] = "虎",
  ["wuling2"] = "鹿",
  ["wuling3"] = "熊",
  ["wuling4"] = "猿",
  ["wuling5"] = "鹤",
  [":wuling1"] = "使用指定唯一目标的牌对目标角色造成伤害时，此伤害+1。",
  [":wuling2"] = "回复1点体力并弃置判定区里的所有牌，不能成为延时锦囊牌的目标。",
  [":wuling3"] = "受到伤害时，此伤害-1。",
  [":wuling4"] = "出牌阶段开始时，选择一名其他角色，随机获得其装备区里的一张牌。",
  [":wuling5"] = "出牌阶段开始时，摸两张牌。",
  ["@wuling"] = "五灵",
  ["#wuling-choose"] = "五灵：你可以选择一名其他角色，随机获得其装备区里的一张牌",
  ["#youyi"] = "游医：你可以弃置所有“仁”区牌，令所有角色回复1点体力",
  ["#youyi-invoke"] = "游医：是否将本阶段弃置的牌置入“仁”区？",

  ["$wuling1"] = "欲解万般苦，驱身仿五灵。",
  ["$wuling2"] = "吾创五禽之戏，君可作以除疾。",
  ["$youyi1"] = "普济众生，永免疾患之苦。",
  ["$youyi2"] = "此身行医，志济万千百姓。",
  ["~godhuatuo"] = "人间诸疾未解，老夫怎入轮回……",
}

return extension
