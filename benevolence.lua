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

  ["$guying1"] = "我军之营，犹如磐石之固！",
  ["$guying2"] = "深壁固垒，敌军莫敢来侵！",
  ["$muzhen1"] = "行阵和睦，方可优劣得所。",
  ["$muzhen2"] = "识时达务，才可上和下睦。",
  ["~xiangchong"] = "蛮夷怀异，战乱难平……",
}

local qiaogong = General(extension, "qiaogong", "wu", 3)
local yizhu = fk.CreateTriggerSkill{
  name = "yizhu",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
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
    return player:hasSkill(self.name) and target ~= player and target:hasSkill(self.name, true) and not data.gonghuan and
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

local liuzhang = General(extension, "liuzhang", "qun", 3)
local jutu = fk.CreateTriggerSkill{
  name = "jutu",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
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
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
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
  on_cost = function(self, event, target, player, data)
    return true
  end,
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
    if player:hasSkill(self.name) and player:getMark("@yaohu") ~= 0 then
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

return extension
