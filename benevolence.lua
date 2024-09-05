local extension = Package("benevolence")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["benevolence"] = "手杀-始计篇·仁",
}

local nos__huaxin = General(extension, "nos__huaxin", "wei", 3)
local renshih = fk.CreateActiveSkill{
  name = "renshih",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#renshih",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("renshih-phase") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "renshih-phase", 1)
    room:moveCardTo(effect.cards[1], Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
  end,
}
local debao = fk.CreateTriggerSkill{
  name = "debao",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove and #player:getPile("huaxin_ren") < player.maxHp then
        for _, move in ipairs(data) do
          if move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
            return true
          end
        end
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start and #player:getPile("huaxin_ren") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      player:addToPile("huaxin_ren", room:getNCards(1)[1], false, self.name)
    else
      room:obtainCard(player.id, player:getPile("huaxin_ren"), false, fk.ReasonJustMove)
    end
  end,
}
local buqi = fk.CreateTriggerSkill{
  name = "buqi",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EnterDying, fk.Deathed},
  expand_pile = "huaxin_ren",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EnterDying then
        return #player:getPile("huaxin_ren") > 1
      else
        return #player:getPile("huaxin_ren") > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EnterDying then
      local cards = room:askForCard(player, 2, 2, false, self.name, false, ".|.|.|huaxin_ren", "#buqi-invoke", "huaxin_ren")
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "support")
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
      room:doIndicate(player.id, {target.id})
      if not target.dead and target:isWounded() then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    else
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "negative")
      room:moveCardTo(player:getPile("huaxin_ren"), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true,
        player.id)
    end
  end,
}
nos__huaxin:addSkill(renshih)
nos__huaxin:addSkill(debao)
nos__huaxin:addSkill(buqi)
Fk:loadTranslationTable{
  ["nos__huaxin"] = "华歆",
  ["#nos__huaxin"] = "清素拂浊",
  ["illustrator:nos__huaxin"] = "凡果", -- 脂膏不润
  ["renshih"] = "仁仕",
  [":renshih"] = "出牌阶段每名角色限一次，你可以将一张手牌交给一名其他角色。",
  ["debao"] = "德报",
  [":debao"] = "锁定技，当其他角色获得你的牌后，若“仁”数小于你的体力上限，你将牌堆顶一张牌置为“仁”。准备阶段，你获得所有“仁”。",
  ["buqi"] = "不弃",
  [":buqi"] = "锁定技，一名角色进入濒死状态时，你移去两张“仁”，令其回复1点体力。当一名角色死亡后，你移去所有“仁”。",
  ["#renshih"] = "仁仕：你可以将一张手牌交给一名其他角色",
  ["huaxin_ren"] = "仁",
  ["#buqi-invoke"] = "不弃：请移去两张“仁”",

  ["$renshih1"] = "吾既从大魏之仕，必当行君子之仁。",
  ["$renshih2"] = "君子之仕，无外乎行其仁也。",
  ["$debao1"] = "举手而为之事，何禁诸君盛赞。",
  ["$debao2"] = "仁仕做之不止，德报随之即来。",
  ["$buqi1"] = "吾等既已纳其自托，宁可以急相弃邪？",
  ["$buqi2"] = "吾等既纳之，便不可怀弃人之心也。",
  ["~nos__huaxin"] = "年老多病，上疏乞身……",
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
    U.AddToRenPile(room, cards, self.name, player.id)
  end,
}
local shuchen = fk.CreateTriggerSkill{
  name = "shuchen",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #U.GetRenPile(player.room) > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:moveCardTo(U.GetRenPile(room), Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    if not target.dead and target:isWounded() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    end
  end,
}
huaxin:addSkill(yuanqing)
huaxin:addSkill(shuchen)
Fk:loadTranslationTable{
  ["mobile__huaxin"] = "华歆",
  ["#mobile__huaxin"] = "清素拂浊",
  ["illustrator:mobile__huaxin"] = "游漫美绘",
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
    local cards = player.room:askForCard(player, player.hp, 999, true, self.name, true, ".",
      "#sheyi-invoke::"..target.id..":"..player.hp)
    if #cards >= player.hp then
      self.cost_data = {tos = {target.id}, cards = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(self.cost_data.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
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
        table.insert(cards, card[1])
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, false, player.id)
    end
  end,
}
caizhenji:addSkill(sheyi)
caizhenji:addSkill(tianyin)
Fk:loadTranslationTable{
  ["caizhenji"] = "蔡贞姬",
  ["#caizhenji"] = "舍心顾复",
  ["illustrator:caizhenji"] = "M云涯",
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
      room:moveCardTo(effect.cards, Card.PlayerEquip, target, fk.ReasonPut, self.name, nil, true, player.id)
      if not (player.dead or target.dead or target:isKongcheng()) then
        local id = room:askForCardChosen(player, target, "h", self.name)
        room:obtainCard(player, id, false, fk.ReasonPrey)
      end
    elseif self.interaction.data == "muzhen2" then
      room:obtainCard(target, effect.cards, false, fk.ReasonGive, player.id)
      if not (player.dead or target.dead or #target:getCardIds("e") == 0) then
        local id = room:askForCardChosen(player, target, "e", self.name)
        room:obtainCard(player, id, true, fk.ReasonPrey)
      end
    end
  end,
}
xiangchong:addSkill(guying)
xiangchong:addSkill(muzhen)
Fk:loadTranslationTable{
  ["xiangchong"] = "向宠",
  ["#xiangchong"] = "镇军之岳",
  ["cv:xiangchong"] = "虞晓旭",
  ["illustrator:xiangchong"] = "凝聚永恒",
  ["guying"] = "固营",
  [":guying"] = "锁定技，每回合限一次，当你于回合外因使用、打出或弃置一次性仅失去一张牌后，当前回合角色须选择一项："..
  "1.你获得此牌（若为装备则使用之）；2.交给你一张牌。准备阶段，你须弃置X张牌（X为本技能发动次数），然后重置此技能发动次数。",
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
    U.AddToRenPile(room, room:getNCards(1), self.name, player.id)
  end,
}
local mobile__songshu = fk.CreateTriggerSkill{
  name = "mobile__songshu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Draw and target.hp > player.hp and #U.GetRenPile(player.room) > 0
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, nil, "#mobile__songshu-invoke::"..target.id) then
      self.cost_data = {tos = {target.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@mobile__songshu-turn", 1)
    local n = math.min(player.hp, 5, #U.GetRenPile(room))
    local all_cards = U.GetRenPile(room)
    local cards = U.askforChooseCardsAndChoice(target, all_cards, {"OK"}, self.name,
      "#mobile__songshu-choose:::"..n, nil, n, n, all_cards)
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, self.name, nil, true, target.id)
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
  ["#mobile__zhangwen"] = "抱德炀和",
  ["illustrator:mobile__zhangwen"] = "凝聚永恒",
  ["gebo"] = "戈帛",
  [":gebo"] = "锁定技，一名角色回复体力后，你从牌堆顶将一张牌置于“仁”区中。"..
  "<br/><font color='grey'>#\"<b>仁区</b>\"<br/>"..
  "仁区是一个存于场上，用于存放牌的公共区域。<br>仁区中的牌上限为6张。<br>当仁区中的牌超过6张时，最先置入仁区中的牌将置入弃牌堆。",
  ["mobile__songshu"] = "颂蜀",
  [":mobile__songshu"] = "一名体力值大于你的其他角色摸牌阶段开始时，若“仁”区有牌，你可以令其放弃摸牌，改为获得X张“仁”区牌"..
  "（X为你的体力值，且最大为5）。若如此做，本回合其使用牌时不能指定其他角色为目标。",
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
    local mark = U.getMark(player, "yizhu_cards")
    local moves = {}
    for _, id in ipairs(cards) do
      table.insertIfNeed(mark, id)
      table.insert(moves, {
        ids = {id},
        from = player.id,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        drawPilePosition = math.random(math.min(#room.draw_pile, math.max(2 * #room.alive_players , 1))),
      })
    end
    room:setPlayerMark(player, "yizhu_cards", mark)
    room:moveCards(table.unpack(moves))
  end,
}
local yizhu_trigger = fk.CreateTriggerSkill{
  name = "#yizhu_trigger",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("yizhu") then
      local mark = U.getMark(player, "yizhu_cards")
      if #mark > 0 and target ~= player and #AimGroup:getAllTargets(data.tos) == 1 then
        local cardlist = Card:getIdList(data.card)
        return table.find(cardlist, function(id) return table.contains(mark, id) end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "yizhu", nil, "#yizhu-invoke::"..target.id..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("yizhu")
    room:notifySkillInvoked(player, "yizhu", "control")
    room:doIndicate(player.id, {data.to})
    AimGroup:cancelTarget(data, data.to)
    local mark = U.getMark(player, "yizhu_cards")
    local cardlist = Card:getIdList(data.card)
    for _, id in ipairs(Card:getIdList(data.card)) do
      if table.contains(mark, id) then
        table.removeOne(mark, id)
      end
    end
    room:setPlayerMark(player, "yizhu_cards", #mark > 0 and mark or 0)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    local mark = U.getMark(player, "yizhu_cards")
    if #mark > 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(mark, info.cardId) then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "yizhu_cards")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(mark, info.cardId) then
            table.removeOne(mark, info.cardId)
          end
        end
      end
    end
    room:setPlayerMark(player, "yizhu_cards", #mark > 0 and mark or 0)
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
  card_filter = Util.FalseFunc,
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
    room:damage{
      from = data.from,
      to = player,
      damage = data.damage,
      damageType = data.damageType,
      skillName = data.skillName,
      card = data.card,
      chain = data.chain,
      gonghuan = true,
    }
    room:setPlayerMark(player, "@@luanchou", 0)
    room:handleAddLoseSkills(player, "-gonghuan", nil, true, false)
    room:setPlayerMark(target, "@@luanchou", 0)
    room:handleAddLoseSkills(target, "-gonghuan", nil, true, false)
    return true
  end,
}
yizhu:addRelatedSkill(yizhu_trigger)
qiaogong:addSkill(yizhu)
qiaogong:addSkill(luanchou)
qiaogong:addRelatedSkill(gonghuan)
Fk:loadTranslationTable{
  ["qiaogong"] = "桥公",
  ["#qiaogong"] = "高风硕望",
  ["yizhu"] = "遗珠",
  [":yizhu"] = "结束阶段，你摸两张牌，然后选择两张牌作为“遗珠”并记录之，随机洗入牌堆顶前2X张牌中（X为场上存活角色数）。"..
  "其他角色使用“遗珠”牌指定唯一目标后，你可以取消之，然后你将此牌从记录中移除。",
  ["luanchou"] = "鸾俦",
  [":luanchou"] = "出牌阶段限一次，你可以移除场上所有“姻”标记并选择两名角色，令其获得“姻”。有“姻”的角色视为拥有技能〖共患〗。",
  ["gonghuan"] = "共患",
  [":gonghuan"] = "锁定技，每回合限一次，当另一名拥有“姻”的角色受到伤害时，若其体力值小于你，将此伤害转移给你；然后移除双方的“姻”标记。",
  ["#yizhu-card"] = "遗珠：将两张牌作为“遗珠”洗入牌堆",
  ["yizhu_cards"] = "遗珠",
  ["#yizhu-invoke"] = "遗珠：你可以取消 %dest 使用的%arg",
  ["#yizhu_trigger"] = "遗珠",
  ["#luanchou"] = "鸾俦：令两名角色获得“姻”标记并获得技能〖共患〗",
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
  events = {fk.CardUseFinished, "fk.AfterRenMove"},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.CardUseFinished then
        return target == player and not data.damageDealt and player.room:getCardArea(data.card) == Card.Processing
      else
        return data.skillName ~= "ren_overflow"
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardUseFinished then
      room:notifySkillInvoked(player, self.name, "special")
      U.AddToRenPile(room, data.card, self.name, player.id)
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
    if player:hasSkill(self) and target ~= player then
      local n = target:getHandcardNum() - target.hp
      return n ~= 0 and #U.GetRenPile(player.room) >= math.min(-n, 4)
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
    if player.room:askForSkillInvoke(player, self.name, nil, prompt) then
      self.cost_data = {tos = {target.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getHandcardNum() - target.hp
    if n < 0 then
      n = math.min(-n, 4)
      local all_cards = U.GetRenPile(room)
      local cards = U.askforChooseCardsAndChoice(target, all_cards, {"OK"}, self.name,
        "#liaoyi-choose:::"..n, nil, n, n, all_cards)
      room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonJustMove, self.name, nil, true, target.id)
    else
      n = math.min(n, 4)
      local cards = room:askForCard(target, n, n, true, self.name, false, ".", "#liaoyi-put:::"..n)
      U.AddToRenPile(room, cards, self.name, target.id)
    end
  end,
}
local binglun = fk.CreateActiveSkill{
  name = "binglun",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#binglun",
  expand_pile = function () return U.getMark(Self, "$RenPile") end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #U.getMark(player, "$RenPile") > 0
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and table.contains(U.getMark(Self, "$RenPile"), to_select)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonDiscard, self.name, nil, true, player.id)
    if target.dead then return end
    local choices = {"draw1", "binglun_recover"}
    local choice = room:askForChoice(target, choices, self.name)
    if choice == "draw1" then
      target:drawCards(1, self.name)
    else
      local mark = U.getMark(target, self.name)
      table.insert(mark, player.id)
      room:setPlayerMark(target, self.name, mark)
    end
  end,
}
local binglun_trigger = fk.CreateTriggerSkill{
  name = "#binglun_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    return target == player and #U.getMark(player, "binglun") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = U.getMark(player, "binglun")
    room:setPlayerMark(player, "binglun", 0)
    for _, pid in ipairs(mark) do
      if player.dead or not player:isWounded() then break end
      local me = room:getPlayerById(pid)
      if not me.dead then
        me:broadcastSkillInvoke("binglun")
        room:notifySkillInvoked(me, "binglun", "support")
      end
      room:recover({
        who = player,
        num = 1,
        recoverBy = me,
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
    room:setPlayerMark(player, "$RenPile", U.GetRenPile(room))
  end,
}
binglun:addRelatedSkill(binglun_trigger)
zhangzhongjing:addSkill(jishi)
zhangzhongjing:addSkill(liaoyi)
zhangzhongjing:addSkill(binglun)
Fk:loadTranslationTable{
  ["zhangzhongjing"] = "张仲景",
  ["#zhangzhongjing"] = "医理圣哲",
  ["illustrator:zhangzhongjing"] = "鬼画府",
  ["jishi"] = "济世",
  [":jishi"] = "锁定技，你使用牌结算结束后置入弃牌堆前，若此牌没有造成伤害，则将之置入“仁”区；当“仁”牌不因溢出而离开“仁”区后，你摸一张牌。"..
  "<br/><font color='grey'>#\"<b>仁区</b>\"<br/>"..
  "仁区是一个存于场上，用于存放牌的公共区域。<br>仁区中的牌上限为6张。<br>当仁区中的牌超过6张时，最先置入仁区中的牌将置入弃牌堆。",
  ["liaoyi"] = "疗疫",
  [":liaoyi"] = "其他角色回合开始时，若其手牌数小于体力值且场上“仁”数量不小于X，则你可以令其获得X张“仁”；若其手牌数大于体力值，"..
  "则可以令其将X张牌置入“仁”区（X为其手牌数与体力值差值，且至多为4）。",
  ["binglun"] = "病论",
  [":binglun"] = "出牌阶段限一次，你可以选择一名角色并弃置一张“仁”牌，令其选择：1.摸一张牌；2.其回合结束时回复1点体力。",
  ["#liaoyi1-invoke"] = "疗疫：你可以令 %dest 获得%arg张“仁”",
  ["#liaoyi2-invoke"] = "疗疫：你可以令 %dest 将%arg张牌置入“仁”区",
  ["#liaoyi-choose"] = "疗疫：获得%arg张“仁”区牌",
  ["#liaoyi-put"] = "疗疫：你需将%arg张牌置入“仁”区",
  ["#binglun"] = "病论：你可以弃置一张“仁”区牌，令一名角色选择摸牌或其回合结束时回复体力",
  ["binglun_recover"] = "你下个回合结束时回复1点体力",
  ["#binglun_trigger"] = "病论",

  ["$jishi1"] = "勤求古训，常怀济人之志。",
  ["$jishi2"] = "博采众方，不随趋势之徒。",
  ["$liaoyi1"] = "麻黄之汤，或可疗伤寒之疫。",
  ["$liaoyi2"] = "望闻问切，因病施治。",
  ["$binglun1"] = "受病有深浅，使药有重轻。",
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
      room:obtainCard(player.id, player:getPile("liuzhang_sheng"), false, fk.ReasonJustMove)
    end
    if player.dead then return end
    if player:getMark("@yaohu") == 0 then
      player:drawCards(1, self.name)
    else
      local n = #table.filter(room.alive_players, function(p) return p.kingdom == player:getMark("@yaohu") end)
      player:drawCards(n + 1, self.name)
      if not player.dead and not player:isNude() then
        local cards = player:getCardIds("he")
        if #cards > n then
          cards = room:askForCard(player, n, n, true, self.name, false, ".", "#jutu-put:::"..n)
        end
        player:addToPile("liuzhang_sheng", cards, true, self.name)
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
        return true
      else
        local cards = room:askForCard(target, 2, 2, true, "yaohu", true, ".",
          "#yaohu-give:"..player.id.."::"..data.card:toLogString())
        if #cards == 2 then
          room:obtainCard(player.id, cards, false, fk.ReasonGive, target.id)
        else
          AimGroup:cancelTarget(data, player.id)
          return true
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
  ["#liuzhang"] = "半圭黯暗",
  ["illustrator:liuzhang"] = "鬼画府",
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

Fk:addQmlMark{
  name = "wuling",
  how_to_show = function(name, value, p)
    if type(value) == "table" then
      local wulingMarkMap = {
        ["wulingHu"] = "wuling1",
        ["wulingLu"] = "wuling2",
        ["wulingXiong"] = "wuling3",
        ["wulingYuan"] = "wuling4",
        ["wulingHe"] = "wuling5",
      }
      return Fk:translate(wulingMarkMap[value[1][value[2]]])
    end
    return " "
  end,
  qml_path = "packages/mobile/qml/WuLingMark"
}

local wulingHu = fk.CreateTrickCard{
  name = "wulingHu",
}

extension:addCard(wulingHu)

local wulingLu = fk.CreateTrickCard{
  name = "wulingLu",
}

extension:addCard(wulingLu)

local wulingXiong = fk.CreateTrickCard{
  name = "wulingXiong",
}

extension:addCard(wulingXiong)

local wulingYuan = fk.CreateTrickCard{
  name = "wulingYuan",
}

extension:addCard(wulingYuan)

local wulingHe = fk.CreateTrickCard{
  name = "wulingHe",
}

extension:addCard(wulingHe)

local wuLingMarkGainedEffect = function(mark, player)
  local room = player.room
  if mark == "wuling2" then
    room:notifySkillInvoked(player, "wulingLu", "support")
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = "wuling"
      }
    end
    if not player.dead and #player:getCardIds("j") > 0 then
      player:throwAllCards("j")
    end
  elseif mark == "wuling4" then
    room:notifySkillInvoked(player, "wulingYuan", "control")
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return #p:getCardIds("e") > 0 end), Util.IdMapper)
    if #targets == 0 then return false end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wuling-choose", "wuling", false)
    if #to > 0 then
      local cards = room:askForCardsChosen(player, room:getPlayerById(to[1]), 1, 1, "e", "wuling")
      room:obtainCard(player.id, cards[1], true, fk.ReasonPrey)
    end
  elseif mark == "wuling5" then
    room:notifySkillInvoked(player, "wulingHe", "drawcard")
    player:drawCards(3, "wuling")
  end
end

local godhuatuo = General(extension, "godhuatuo", "god", 3)
local wuling = fk.CreateActiveSkill{
  name = "wuling",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#wuling",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getMark(self.name) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    local result = room:askForCustomDialog(
      player, self.name,
      "packages/mobile/qml/WuLingBox.qml",
      {}
    )

    local wulingMarkMap = {
      ["wulingHu"] = "wuling1",
      ["wulingLu"] = "wuling2",
      ["wulingXiong"] = "wuling3",
      ["wulingYuan"] = "wuling4",
      ["wulingHe"] = "wuling5",
    }

    local names = {}
    if result == "" then
      names = { "wulingHe", "wulingHu", "wulingXiong", "wulingYuan", "wulingLu" }
    else
      names = json.decode(result).sort
    end

    result = table.map(names, function(name) return wulingMarkMap[name] end)

    room:setPlayerMark(target, self.name, { result, player.id })
    room:setPlayerMark(target, "wuling_invoke", tonumber(result[1][7]))
    room:setPlayerMark(target, "@[wuling]", { names, 1 })

    wuLingMarkGainedEffect(result[1], target)
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
        return player:getMark("wuling_invoke") == 3 and player:getMark("wuling3Triggered-turn") == 0
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Start
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, "wulingHu", "offensive")
      data.damage = data.damage + 1
    elseif event == fk.DamageInflicted then
      room:setPlayerMark(player, "wuling3Triggered-turn", 1)
      room:notifySkillInvoked(player, "wulingXiong", "defensive")
      data.damage = data.damage - 1
    elseif event == fk.EventPhaseStart then
      if player.phase == Player.Start then
        local result = player:getMark("wuling")[1]
        local n = player:getMark("wuling_invoke")
        local new_index = table.indexOf(result, "wuling"..n) + 1
        if new_index > 5 then
          room:setPlayerMark(target, "wuling", 0)
          room:setPlayerMark(target, "wuling_invoke", 0)
          room:setPlayerMark(target, "@[wuling]", 0)
          return false
        end

        room:setPlayerMark(player, "wuling_invoke", tonumber(result[new_index][7]))
        local mark = player:getMark("@[wuling]")
        mark[2] = new_index
        room:setPlayerMark(player, "@[wuling]", mark)
        wuLingMarkGainedEffect(result[new_index], player)
      end
    end
  end,

  refresh_events = { fk.Death },
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      local mark = p:getMark("wuling")
      if type(mark) == "table" and mark[2] == player.id then
        room:setPlayerMark(p, "wuling", 0)
        room:setPlayerMark(p, "wuling_invoke", 0)
        room:setPlayerMark(p, "@[wuling]", 0)
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
  expand_pile = function ()
    return U.getMark(Self, "$RenPile")
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #U.getMark(player, "$RenPile") > 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    room:moveCardTo(U.GetRenPile(room), Card.DiscardPile, nil, fk.ReasonDiscard, self.name, nil, true, player.id)
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead and p:isWounded() then
        room:recover{
          who = p,
          num = 1,
          recoverBy = player,
          skillName = self.name,
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
    U.AddToRenPile(room, ids, self.name, player.id)
  end,

  refresh_events = {fk.StartPlayCard},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "$RenPile", U.GetRenPile(room))
  end,
}
wuling:addRelatedSkill(wuling_trigger)
wuling:addRelatedSkill(wuling_prohibit)
youyi:addRelatedSkill(youyi_trigger)
godhuatuo:addSkill(wuling)
godhuatuo:addSkill(youyi)

local godhuatuo_win = fk.CreateActiveSkill{ name = "godhuatuo_win_audio" }
godhuatuo_win.package = extension
Fk:addSkill(godhuatuo_win)

Fk:loadTranslationTable{
  ["godhuatuo"] = "神华佗",
  ["#godhuatuo"] = "悬壶济世",
  ["wuling"] = "五灵",
  [":wuling"] = "出牌阶段限两次，你可以选择一名没有“五灵”标记的角色，按照你选择的顺序向其传授“五禽戏”。拥有“五灵”标记的角色在其准备阶段"..
  "按照传授的顺序依次切换为下一种效果：<br>"..
  "虎：当你使用指定唯一目标的牌对目标角色造成伤害时，此伤害+1。<br>"..
  "鹿：回复1点体力并弃置判定区里的所有牌，你不能成为延时锦囊牌的目标。<br>"..
  "熊：每回合限一次，当你受到伤害时，此伤害-1。<br>"..
  "猿：获得一名其他角色装备区里的一张牌。<br>"..
  "鹤：你摸三张牌。",
  ["youyi"] = "游医",
  [":youyi"] = "弃牌阶段结束时，你可以将此阶段弃置的牌置入“仁”区。出牌阶段限一次，你可以弃置所有“仁”区的牌，令所有角色回复1点体力。",
  ["#wuling"] = "五灵：向一名角色传授“五禽戏”",
  ["Please arrange WuLing cards"] = "请拖动分配“五禽戏”的顺序（从左至右）",
  ["#wuling-choice"] = "五灵：选择向 %dest 传授“五禽戏”的顺序<br>已选择：%arg",
  ["wuling1"] = "虎",
  ["wuling2"] = "鹿",
  ["wuling3"] = "熊",
  ["wuling4"] = "猿",
  ["wuling5"] = "鹤",
  ["wulingHu"] = "虎灵",
  ["wulingLu"] = "鹿灵",
  ["wulingXiong"] = "熊灵",
  ["wulingYuan"] = "猿灵",
  ["wulingHe"] = "鹤灵",
  ["@[wuling]"] = "五灵",
  ["#wuling_trigger"] = "五灵",
  ["#wuling-choose"] = "五灵：请选择一名其他角色，获得其装备区里的一张牌",
  ["#youyi"] = "游医：你可以弃置所有“仁”区牌，令所有角色回复1点体力",
  ["#youyi-invoke"] = "游医：是否将本阶段弃置的牌置入“仁”区？",

  ["$wuling1"] = "吾创五禽之戏，君可作以除疾。",
  ["$wuling2"] = "欲解万般苦，驱身仿五灵。",
  ["$youyi1"] = "此身行医，志济万千百姓。",
  ["$youyi2"] = "普济众生，永免疾患之苦。",
  ["~godhuatuo"] = "人间诸疾未解，老夫怎入轮回……",

  ["$godhuatuo_win_audio"] = "但愿世间人无病，何惜架上药生尘。",
}

local godlusu = General(extension, "godlusu", "god", 3)
local godlusuWin = fk.CreateActiveSkill{ name = "godlusu_win_audio" }
godlusuWin.package = extension
Fk:addSkill(godlusuWin)

Fk:loadTranslationTable{
  ["godlusu"] = "神鲁肃",
  ["#godlusu"] = "兴吴之邓禹",
  ["~godlusu"] = "常计小利，何成大局……",

  ["$godlusu_win_audio"] = "至尊高坐天中，四海皆在目下！",
}

local tamo = fk.CreateTriggerSkill{
  name = "tamo",
  priority = 2,
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askForSkillInvoke(player, self.name, nil, "#tamo-invoke") then
      local availablePlayerIds = table.map(table.filter(room.players, function(p) return p.rest > 0 or not p.dead end), Util.IdMapper)
      local disabledPlayerIds = {}
      if table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) then
        disabledPlayerIds = table.filter(availablePlayerIds, function(pid)
          local p = room:getPlayerById(pid)
          return p.role_shown and p.role == "lord"
        end)
      elseif table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode) then
        local seat3Player = table.find(availablePlayerIds, function(pid)
          return room:getPlayerById(pid).seat == 3
        end)
        disabledPlayerIds = { seat3Player }
      end

      local result = room:askForCustomDialog(
        player, self.name,
        "packages/mobile/qml/TaMoBox.qml",
        {
          availablePlayerIds,
          disabledPlayerIds,
          "$TaMo",
        }
      )

      if result ~= "" then
        self.cost_data = json.decode(result)
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room.players = table.map(self.cost_data, function(playerId) return room:getPlayerById(playerId) end)
    local player_circle = {}
    for i = 1, #room.players do
      room.players[i].seat = i
      table.insert(player_circle, room.players[i].id)
    end
    for i = 1, #room.players - 1 do
      room.players[i].next = room.players[i + 1]
    end
    room.players[#room.players].next = room.players[1]
    room.current = room.players[1]
    room:doBroadcastNotify("ArrangeSeats", json.encode(player_circle))
  end,
}
Fk:loadTranslationTable{
  ["tamo"] = "榻谟",
  [":tamo"] = "游戏开始时，你可以重新分配所有角色的座次（若为身份模式，则改为除主公外的所有角色；若为斗地主，则改为除三号位外的所有角色）。",
  ["#tamo-invoke"] = "榻谟：你可以重新分配场上角色的座次",
  ["$TaMo"] = "榻谟",
  ["click to exchange"] = "点击交换",

  ["$tamo1"] = "天下分崩，乱之已极，肃竭浅智，窃为君计。",
  ["$tamo2"] = "天下易主，已为大势，君当据此，以待其时。",
}

godlusu:addSkill(tamo)

local dingzhou = fk.CreateActiveSkill{
  name = "dingzhou",
  anim_type = "control",
  target_num = 1,
  prompt = "#dingzhou",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isNude()
  end,
  card_filter = Util.TrueFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    local cardsNumInField = #Fk:currentRoom():getPlayerById(to_select):getCardIds("ej")
    return
      #selected == 0 and
      to_select ~= Self.id and
      cardsNumInField > 0 and
      cardsNumInField == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    room:obtainCard(target, effect.cards, false, fk.ReasonGive, effect.from)

    if #target:getCardIds("ej") > 0 then
      room:obtainCard(player, target:getCardIds("ej"), false, fk.ReasonPrey, target.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["dingzhou"] = "定州",
  [":dingzhou"] = "出牌阶段限一次，你可以选择一名其他角色并交给其X张牌（X为其场上的牌数），然后你获得其场上的所有牌。",
  ["#dingzhou"] = "定州：你可以交给一名其他角色其场上牌数张牌，获得其场上的牌",

  ["$dingzhou1"] = "今肃亲往，主公何愁不定！",
  ["$dingzhou2"] = "肃之所至，万事皆平！",
}

godlusu:addSkill(dingzhou)

local zhimeng = fk.CreateTriggerSkill{
  name = "zhimeng",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    return
      target == player and
      player:hasSkill(self) and
      table.find(room.alive_players, function(p)
        return
          p ~= player and
          (table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) or
          p:getHandcardNum() <= player:getHandcardNum() + 1)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room.alive_players, function(p)
        return
          p ~= player and
          (table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) or
          p:getHandcardNum() <= player:getHandcardNum() + 1)
      end),
      Util.IdMapper
    )

    local to = room:askForChoosePlayers(player, availableTargets, 1, 1, "#zhimeng-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)

    local moveInfos = {}
    local wholeCards = {}
    if player:getHandcardNum() > 0 then
      table.insertTable(wholeCards, player:getCardIds("h"))
      table.insert(moveInfos, {
        from = player.id,
        ids = player:getCardIds("h"),
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
        moveVisible = false,
      })
    end
    if to:getHandcardNum() > 0 then
      table.insertTable(wholeCards, to:getCardIds("h"))
      table.insert(moveInfos, {
        from = to.id,
        ids = to:getCardIds("h"),
        toArea = Card.Processing,
        moveReason = fk.ReasonExchange,
        proposer = player.id,
        skillName = self.name,
        moveVisible = false,
      })
    end

    if #moveInfos == 0 or #wholeCards == 0 then
      return false
    end

    room:moveCards(table.unpack(moveInfos))

    moveInfos = {}
    local youGainNum = math.ceil(#wholeCards / 2)
    local youGain = {}
    for i = 1, youGainNum do
      local idRemoved = table.remove(wholeCards, math.random(1, #wholeCards))
      table.insert(youGain, idRemoved)
    end

    if not player.dead then
      local to_ex_cards = table.filter(youGain, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = to_ex_cards,
          fromArea = Card.Processing,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
          moveVisible = false,
        })
      end
    end
    if not to.dead then
      local to_ex_cards = table.filter(wholeCards, function (id)
        return room:getCardArea(id) == Card.Processing
      end)
      if #to_ex_cards > 0 then
        table.insert(moveInfos, {
          ids = wholeCards,
          fromArea = Card.Processing,
          to = to.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
          moveVisible = false,
        })
      end
    end

    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end

    local dis_cards = table.filter(wholeCards, function (id)
      return room:getCardArea(id) == Card.Processing
    end)
    if #dis_cards > 0 then
      room:moveCardTo(dis_cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, self.name, nil, true, player.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["zhimeng"] = "智盟",
  [":zhimeng"] = "回合结束时，你可以与一名其他角色随机平均分配手牌（若不为身份模式，则改为手牌数不大于你手牌数+1的其他角色），" ..
  "若总牌数为奇数，则你分配较多张数。",
  ["#zhimeng-choose"] = "智盟：你可以选择其中一名角色与其随机平分手牌",

  ["$zhimeng1"] = "豫州何图远窜，而不投吾雄略之主乎？",
  ["$zhimeng2"] = "吾主英明神武，曹众虽百万亦无所惧！",
}

godlusu:addSkill(zhimeng)

return extension
