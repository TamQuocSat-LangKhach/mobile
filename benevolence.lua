local extension = Package("benevolence")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["benevolence"] = "手杀-始计篇·仁",
}

local caizhenji = General(extension, "caizhenji", "wei", 3, 3, General.Female)
local sheyi = fk.CreateTriggerSkill{
  name = "sheyi",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target.hp < player.hp and #player:getCardIds("he") >= player.hp and
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
    if target == player and player:hasSkill(self.name) and player.phase == Player.Finish then
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
    if player:hasSkill(self.name) then
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
}

local xiangchong = General(extension, "xiangchong", "shu", 4)
local guying = fk.CreateTriggerSkill{
  name = "guying",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
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
}

--local qiaogong = General(extension, "qiaogong", "wu", 3)
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
}

return extension
