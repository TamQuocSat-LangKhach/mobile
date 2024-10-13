local extension = Package("mobile_sp2")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_sp2"] = "手杀-SP2",
}

--未分组：吴班 鲍信 胡班 陈珪 霍峻 木鹿大王 蒋干 杨奉 SP孙策 来敏

local laimin = General(extension, "laimin", "shu", 3)
local laishou = fk.CreateTriggerSkill{
  name = "laishou",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.DamageInflicted then
        return data.damage >= player.hp and player.maxHp < 9
      elseif event == fk.EventPhaseStart then
        return player.phase == Player.Start and player.maxHp > 8
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
      room:notifySkillInvoked(player, self.name, "defensive")
      room:changeMaxHp(player, data.damage)
      return true
    elseif event == fk.EventPhaseStart then
      player:broadcastSkillInvoke(self.name, 3)
      room:notifySkillInvoked(player, self.name, "negative")
      room:killPlayer({who = player.id})
    end
  end,
}
local luanqun = fk.CreateActiveSkill{
  name = "luanqun",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#luanqun",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    local extraData = {
      num = 1,
      min_num = 1,
      include_equip = false,
      pattern = ".",
      reason = self.name,
    }
    for _, p in ipairs(targets) do
      p.request_data = json.encode({"choose_cards_skill", "#luanqun-card", true, extraData})
    end
    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", targets)
    for _, p in ipairs(targets) do
      local id
      if p.reply_ready then
        local replyCard = json.decode(p.client_reply).card
        id = json.decode(replyCard).subcards[1]
      else
        id = table.random(p:getCardIds("h"))
      end
      room:setPlayerMark(p, "luanqun-tmp", id)
    end

    local all_cards = {}
    for _, p in ipairs(targets) do
      if not p.dead then
        local id = p:getMark("luanqun-tmp")
        p:showCards({id})
        if table.contains(p:getCardIds("h"), id) then
          table.insertIfNeed(all_cards, id)
        end
      end
    end
    if player.dead or #all_cards == 0 then return end
    local my_card = Fk:getCardById(player:getMark("luanqun-tmp"))
    local available_cards = table.filter(all_cards, function(id) return Fk:getCardById(id).color == my_card.color end)
    table.removeOne(available_cards, my_card.id)
    local maxNum = table.contains({"aaa_role_mode", "aab_role_mode", "vanished_dragon"}, room.settings.gameMode) and 4 or 2
    local cards, choice = U.askforChooseCardsAndChoice(
      player,
      available_cards,
      {"OK"},
      self.name,
      "#luanqun-get:::" .. maxNum,
      {"Cancel"},
      1,
      maxNum,
      all_cards
    )
    if choice ~= "Cancel" then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
    local mark = player:getTableMark(self.name)
    for _, p in ipairs(targets) do
      if not p.dead and p:getMark("luanqun-tmp") ~= 0 then
        local card = Fk:getCardById(p:getMark("luanqun-tmp"))
        room:setPlayerMark(p, "luanqun-tmp", 0)
        if card.color ~= my_card.color then
          table.insert(mark, p.id)
        end
      end
    end
    if not player.dead and #mark > 0 then
      room:setPlayerMark(player, self.name, mark)
    end
  end,
}
local luanqun_trigger = fk.CreateTriggerSkill{
  name = "#luanqun_trigger",
  mute = true,
  events = {fk.TurnStart, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player:getMark("luanqun") ~= 0 and table.contains(player:getMark("luanqun"), target.id)
    elseif event == fk.TargetConfirmed then
      return target == player and data.card.trueName == "slash" and
        player.room:getPlayerById(data.from):getMark("luanqun"..player.id.."-turn") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local mark = player:getTableMark("luanqun")
      table.removeOne(mark, target.id)
      room:setPlayerMark(player, "luanqun", mark)
      room:setPlayerMark(target, "luanqun"..player.id.."-turn", 1)
      room:setPlayerMark(target, "luanqun_target"..player.id.."-turn", 1)
    else
      local src = room:getPlayerById(data.from)
      room:setPlayerMark(src, "luanqun_target"..player.id.."-turn", 0)
      data.disresponsiveList = data.disresponsiveList or {}
      table.insertIfNeed(data.disresponsiveList, player.id)
    end
  end,
}
local luanqun_prohibit = fk.CreateProhibitSkill{
  name = "#luanqun_prohibit",
  is_prohibited = function(self, from, to, card)
    if card.trueName == "slash" and from.phase == Player.Play then
      local targets = table.filter(Fk:currentRoom().alive_players, function(p)
        return from:getMark("luanqun_target"..p.id.."-turn") > 0
      end)
      return #targets > 0 and not table.contains(targets, to)
    end
  end,
}
luanqun:addRelatedSkill(luanqun_trigger)
luanqun:addRelatedSkill(luanqun_prohibit)
laimin:addSkill(laishou)
laimin:addSkill(luanqun)
Fk:loadTranslationTable{
  ["laimin"] = "来敏",
  ["#laimin"] = "悖骴乱群",
  ["laishou"] = "来寿",
  [":laishou"] = "锁定技，当你受到致命伤害时，若你的体力上限小于9，防止此伤害并增加等量的体力上限。准备阶段，若你的体力上限不小于9，你死亡。",
  ["luanqun"] = "乱群",
  [":luanqun"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中至多两张（若为身份模式，则改为至多四张）"..
  "与你展示牌颜色相同的牌。令所有与你展示牌颜色不同的角色于其下回合出牌阶段使用第一张【杀】只能指定你为目标，且你不能响应其下回合使用的【杀】。",
  ["#luanqun"] = "乱群：令所有角色展示一张手牌，你可以获得其中一张与你展示颜色相同的牌",
  ["#luanqun-card"] = "乱群：请展示一张手牌",
  ["#luanqun-get"] = "乱群：你可以获得其中至多%arg张牌",

  ["$laishou1"] = "黄耇鲐背，谓之永年。",
  ["$laishou2"] = "养怡和之福，得乔松之寿。",
  ["$laishou3"] = "福寿将终，竟未得期颐！",
  ["$luanqun1"] = "年过杖朝，自是从心所欲，何来逾矩之理？",
  ["$luanqun2"] = "位居执慎，博涉多闻，更应秉性而论！",
  ["~laimin"] = "狂嚣之言，一言十过啊……",
}

local huban = General(extension, "mobile__huban", "wei", 4)
local yilie = fk.CreateTriggerSkill{
  name = "mobile__yilie",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.DamageInflicted, fk.Damage, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.GameStart then
      return table.find(player.room.alive_players, function(p) return p ~= player end)
    elseif event == fk.DamageInflicted then
      return table.contains(target:getTableMark("@@mobile__yilie"), player.id) and player:getMark("@mobile__yilie_lie") == 0
    elseif event == fk.Damage then
      return target and table.contains(target:getTableMark("@@mobile__yilie"), player.id) and data.to ~= player and player:isWounded()
    else
      return target == player and player.phase == Player.Finish and player:getMark("@mobile__yilie_lie") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local tos = room:askForChoosePlayers(
        player,
        table.map(room:getOtherPlayers(player), Util.IdMapper),
        1,
        1,
        "#mobile__yilie-choose",
        self.name,
        false
      )
      local to = room:getPlayerById(tos[1])
      local yiliePlayers = to:getTableMark("@@mobile__yilie")
      if table.insertIfNeed(yiliePlayers, player.id) then
        room:setPlayerMark(to, "@@mobile__yilie", yiliePlayers)
      end
    elseif event == fk.DamageInflicted then
      room:setPlayerMark(player, "@mobile__yilie_lie", data.damage)
      return true
    elseif event == fk.Damage then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      player:drawCards(1, self.name)
      if not player.dead then
        room:loseHp(player, player:getMark("@mobile__yilie_lie"), self.name)
        room:setPlayerMark(player, "@mobile__yilie_lie", 0)
      end
    end
  end,

  refresh_events = {fk.BuryVictim, fk.EventLoseSkill},
  can_refresh = function (self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= self then return false end
    return table.contains(player:getTableMark("@@mobile__yilie"), target.id)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:removeTableMark(player, "@@mobile__yilie", target.id)
    if event == fk.EventLoseSkill then
      player.room:setPlayerMark(target, "@mobile__yilie_lie", 0)
    end
  end,
}
huban:addSkill(yilie)
Fk:loadTranslationTable{
  ["mobile__huban"] = "胡班",
  ["#mobile__huban"] = "昭义烈勇",

  ["mobile__yilie"] = "义烈",
  [":mobile__yilie"] = "锁定技，游戏开始时，你选择一名其他角色。当该角色受到伤害时，若你没有“烈”标记，则你获得等同于伤害值数量的“烈”标记，" ..
  "然后防止此伤害；当该角色对其他角色造成伤害后，你回复1点体力；结束阶段开始时，若你有“烈”标记，则你摸一张牌并失去X点体力（X为你的“烈”标记数），" ..
  "然后移去你的所有“烈”标记。",
  ["#yilie_delay"] = "义烈",
  ["@@mobile__yilie"] = "被义烈",
  ["@mobile__yilie_lie"] = "烈",
  ["#mobile__yilie-choose"] = "义烈：请选择一名其他角色，你为其抵挡伤害，且其造成伤害后你回复体力",

  ["$mobile__yilie1"] = "禽兽尚且知义，而况于人乎？",
  ["$mobile__yilie2"] = "班虽无名，亦有忠义在骨！",
  ["$mobile__yilie3"] = "身不慕生，宁比泰山之重！",
  ["~mobile__huban"] = "生虽微而志不可改，位虽卑而节不可夺……",
}

local chengui = General(extension, "mobile__chengui", "qun", 3)
local guimou = fk.CreateTriggerSkill{
  name = "guimou",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.TurnEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      (
        event == fk.GameStart or
        target == player
      ) and
      player:hasSkill(self) and
      (
        event ~= fk.EventPhaseStart or
        (player.phase == Player.Start and player:getMark("@[private]guimou") ~= 0)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local targets = {}
      local minValue = 999
      for _, p in ipairs(room:getOtherPlayers(player)) do
        local recordVal = p.tag["guimou_record" .. player.id] or 0
        if minValue >= recordVal then
          if minValue > recordVal then
            targets = {}
            minValue = recordVal
          end
          if not p:isKongcheng() then
            table.insert(targets, p.id)
          end
        end
      end

      if #targets > 0 then
        local to = targets[1]
        if #targets > 1 then
          to = room:askForChoosePlayers(player, targets, 1, 1, "#guimou-invoke", self.name, true)[1]
        end

        local choices = {"guimou_option_discard"}
        local canGive = table.filter(room.alive_players, function(p) return p.id ~= to and p ~= player end)
        if #canGive > 0 then
          table.insert(choices, 1, "guimou_option_give")
        end
        local ids, choice = U.askforChooseCardsAndChoice(
          player,
          room:getPlayerById(to):getCardIds("h"),
          choices,
          self.name,
          "#guimou-view::" .. to,
          {"Cancel"},
          1,
          1
        )

        if choice == "guimou_option_give" then
          local toGive = room:askForChoosePlayers(
            player,
            table.map(canGive, Util.IdMapper),
            1,
            1,
            "#guimou-give:::" .. Fk:getCardById(ids[1]):toLogString(),
            self.name,
            false
          )[1]
          room:obtainCard(room:getPlayerById(toGive), ids[1], false, fk.ReasonGive, player.id)
        elseif choice == "guimou_option_discard" then
          room:throwCard(ids, self.name, room:getPlayerById(to), player)
        end
      end

      for _, p in ipairs(room.alive_players) do
        p.tag["guimou_record" .. player.id] = nil
      end
      room:setPlayerMark(player, "@[private]guimou", 0)
    else
      local choices = { "guimou_use", "guimou_discard", "guimou_gain" }
      local choice
      if event == fk.GameStart then
        choice = table.random(choices)
      else
        choice = room:askForChoice(player, choices, self.name, "#guimou-choose")
      end

      for _, p in ipairs(room.alive_players) do
        p.tag["guimou_record" .. player.id] = nil
      end
      U.setPrivateMark(player, "guimou", { choice })
    end
  end,

  refresh_events = {fk.EventPhaseEnd, fk.AfterCardUseDeclared, fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      return target == player and player.phase == Player.Start and player:getMark("@[private]guimou") ~= 0
    elseif event == fk.AfterCardUseDeclared then
      return target ~= player and U.getPrivateMark(player, "guimou")[1] == "guimou_use"
    else
      local guimouMark = U.getPrivateMark(player, "guimou")[1]
      if guimouMark == "guimou_discard" then
        return table.find(data, function(info)
          return info.moveReason == fk.ReasonDiscard and info.proposer and info.proposer ~= player.id
        end)
      elseif guimouMark == "guimou_gain" then
        return table.find(data, function(info)
          return info.toArea == Player.Hand and info.to and info.to ~= player.id
        end)
      end
    end

    return false
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      for _, p in ipairs(room.alive_players) do
        p.tag["guimou_record" .. player.id] = nil
      end
      room:setPlayerMark(player, "@[private]guimou", 0)
    elseif event == fk.AfterCardUseDeclared then
      target.tag["guimou_record" .. player.id] = (target.tag["guimou_record" .. player.id] or 0) + 1
    else
      local guimouMark = U.getPrivateMark(player, "guimou")[1]
      if guimouMark == "guimou_discard" then
        table.forEach(data, function(info)
          if info.moveReason == fk.ReasonDiscard and info.proposer and info.proposer ~= player.id then
            local to = room:getPlayerById(info.proposer)
            to.tag["guimou_record" .. player.id] = (to.tag["guimou_record" .. player.id] or 0) + #info.moveInfo
          end
        end)
      elseif guimouMark == "guimou_gain" then
        table.forEach(data, function(info)
          if info.toArea == Player.Hand and info.to and info.to ~= player.id then
            local to = room:getPlayerById(info.to)
            to.tag["guimou_record" .. player.id] = (to.tag["guimou_record" .. player.id] or 0) + #info.moveInfo
          end
        end)
      end
    end
  end,
}
local zhouxian = fk.CreateTriggerSkill{
  name = "zhouxian",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from ~= player.id and data.card.is_damage_card
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(3)
    room:moveCardTo(ids, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    local types = {}
    for _, id in ipairs(ids) do
      table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
    end

    room:moveCardTo(
      table.filter(ids, function(id) return room:getCardArea(id) == Card.Processing end),
      Card.DiscardPile,
      nil,
      fk.ReasonPutIntoDiscardPile,
      self.name,
      nil,
      true,
      player.id
    )

    local from = room:getPlayerById(data.from)
    if from:isAlive() and not from:isNude() then
      local toDiscard = room:askForDiscard(
        from,
        1,
        1,
        true,
        self.name,
        true,
        ".|.|.|.|.|" .. table.concat(types, ","),
        "#zhouxian-discard::" .. player.id .. ":" .. data.card:toLogString()
      )

      if #toDiscard > 0 then
        return false
      end
    end

    AimGroup:cancelTarget(data, player.id)
    return true
  end,
}
chengui:addSkill(guimou)
chengui:addSkill(zhouxian)
Fk:loadTranslationTable{
  ["mobile__chengui"] = "陈珪",
  ["#mobile__chengui"] = "弄辞巧掇",

  ["guimou"] = "诡谋",
  [":guimou"] = "锁定技，游戏开始时你随机选择一项，或回合结束时你选择一项：直到你的下个准备阶段开始时，1.记录使用牌最少的其他角色；" ..
  "2.记录弃置牌最少的其他角色；3.记录获得牌最少的其他角色。准备阶段开始时，你选择被记录的一名角色，观看其手牌并可选择其中一张牌，" ..
  "弃置此牌或将此牌交给另一名其他角色。",
  ["zhouxian"] = "州贤",
  [":zhouxian"] = "锁定技，当你成为其他角色使用伤害牌的目标时，你亮出牌堆顶三张牌，然后其须弃置一张亮出牌中含有的一种类别的牌，否则取消此目标。",
  ["@[private]guimou"] = "诡谋",
  ["#guimou-choose"] = "诡谋：你选择一项，你下个准备阶段令该项值最少的角色受到惩罚",
  ["guimou_use"] = "使用牌",
  ["guimou_discard"] = "弃置牌",
  ["guimou_gain"] = "获得牌",
  ["guimou_option_give"] = "给出此牌",
  ["guimou_option_discard"] = "弃置此牌",
  ["#guimou-invoke"] = "诡谋：选择其中一名角色查看其手牌，可选择其中一张给出或弃置",
  ["#guimou-give"] = "诡谋：将 %arg 交给另一名其他角色",
  ["#guimou-view"] = "当前观看的是 %dest 的手牌",
  ["#zhouxian-discard"] = "州贤：请弃置一张亮出牌中含有的一种类别的牌，否则取消 %arg 对 %dest 的目标",

  ["$guimou1"] = "不过卒合之师，岂是将军之敌乎？",
  ["$guimou2"] = "连鸡势不俱栖，依珪计便可一一解离。",
  ["$zhouxian1"] = "今未有苛暴之乱，汝敢言失政之语。",
  ["$zhouxian2"] = "曹将军神武应期，如何以以身试祸。",
  ["~mobile__chengui"] = "布非忠良之士，将军宜早图之……",
}

local muludawang = General(extension, "muludawang", "qun", 3)
muludawang.shield = 1
local shoufa = fk.CreateTriggerSkill{
  name = "shoufa",
  anim_type = "offensive",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then
      return false
    end

    local room = player.room
    if event == fk.Damage then
      return room.logic:getActualDamageEvents(1, function(e)
        return e.data[1].from == player
      end)[1].data[1] == data
    else
      return
        player:usedSkillTimes(self.name, Player.HistoryTurn) < (5 + player:getMark("shoufa_damage_triggered-turn")) and
        table.find(
          room.alive_players,
          function(p)
            local distance = table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode) and 0 or 1
            return p ~= player and p:distanceTo(player) > distance
          end
        )
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local isDoudizhu = table.contains({"m_1v2_mode", "brawl_mode"}, room.settings.gameMode)
    local targets = table.filter(
      room.alive_players,
      function(p)
        if event == fk.Damage then
          return player:distanceTo(p) < (isDoudizhu and 2 or 3)
        end

        return p:distanceTo(player) > (isDoudizhu and 0 or 1)
      end
    )

    if #targets > 0 then
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#shoufa-choose", self.name)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:setPlayerMark(player, "shoufa_damage_triggered-turn", 1)
    end

    local targetPlayer = room:getPlayerById(self.cost_data)
    local beasts = { "shoufa_bao", "shoufa_ying", "shoufa_xiong", "shoufa_tu" }
    local beast = type(player:getMark("@zhoulin")) == "string" and player:getMark("@zhoulin") or table.random(beasts)

    if beast == beasts[1] then
      room:damage({
        to = targetPlayer,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    elseif beast == beasts[2] then
      if targetPlayer == player then
        if #player:getCardIds("e") > 0 then
          room:obtainCard(player, table.random(player:getCardIds("e")), true, fk.ReasonPrey, player.id)
        end
      elseif not targetPlayer:isNude() then
        room:obtainCard(player, table.random(targetPlayer:getCardIds("he")), false, fk.ReasonPrey, player.id)
      end
    elseif beast == beasts[3] then
      local equips = table.filter(
        targetPlayer:getCardIds("e"),
        function(id) return not (player == targetPlayer and player:prohibitDiscard(Fk:getCardById(id))) end
      )
      if #equips > 0 then
        room:throwCard(table.random(equips), self.name, targetPlayer, player)
      end
    else
      targetPlayer:drawCards(1, self.name)
    end

    return false
  end,
}
local zhoulin = fk.CreateActiveSkill{
  name = "zhoulin",
  anim_type = "support",
  prompt = "#zhoulin",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:hasSkill(shoufa)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:changeShield(player, 2)

    local choiceList = { "zhoulin_bao", "zhoulin_ying", "zhoulin_xiong", "zhoulin_tu" }
    local choice = room:askForChoice(player, choiceList, self.name)
    room:setPlayerMark(player, "@zhoulin", "shoufa_" .. choice:split("_")[2])
  end,
}
local zhoulinRefresh = fk.CreateTriggerSkill{
  name = "#zhoulin_refresh",
  refresh_events = { fk.TurnStart },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@zhoulin") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@zhoulin", 0)
  end,
}
local yuxiang = fk.CreateTriggerSkill{
  name = "yuxiang",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = { fk.DamageInflicted },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.shield > 0 and data.damageType == fk.FireDamage
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local yuxiangDistance = fk.CreateDistanceSkill{
  name = "#yuxiang_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(yuxiang) and from.shield > 0 then
      return -1
    elseif to:hasSkill(yuxiang) and to.shield > 0 then
      return 1
    end

    return 0
  end,
}
zhoulin:addRelatedSkill(zhoulinRefresh)
yuxiang:addRelatedSkill(yuxiangDistance)
muludawang:addSkill(shoufa)
muludawang:addSkill(zhoulin)
muludawang:addSkill(yuxiang)
Fk:loadTranslationTable{
  ["muludawang"] = "木鹿大王",
  ["#muludawang"] = "八纳洞主",

  ["shoufa"] = "兽法",
  [":shoufa"] = "当你每回合首次造成伤害后，你可以选择你距离2以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离大于1的一名角色（若为斗地主，则上述距离改为你距离1以内和与你距离不小于1），其随机执行一种效果：<br>" ..
  "豹，其受到1点无来源伤害；<br>鹰，你随机获得其一张牌；<br>熊，你随机弃置其装备区里的一张牌；<br>兔，其摸一张牌。",
  ["zhoulin"] = "咒鳞",
  [":zhoulin"] = "限定技，出牌阶段，若你有“兽法”，则你可以获得2点护甲并选择一种野兽效果，令你直到你的下个回合开始，" ..
  "“兽法”必定执行此野兽效果。",
  ["yuxiang"] = "御象",
  [":yuxiang"] = "锁定技，若你有护甲，则你拥有以下效果：你计算与其他角色的距离-1；其他角色计算与你的距离+1；当你受到火焰伤害时，此伤害+1。",
  ["#shoufa-choose"] = "兽法：请选择一名角色令其执行野兽效果",
  ["shoufa_bao"] = "豹",
  ["shoufa_ying"] = "鹰",
  ["shoufa_xiong"] = "熊",
  ["shoufa_tu"] = "兔",
  ["@zhoulin"] = "咒鳞",
  ["#zhoulin"] = "你可以选择一种野兽，令兽法直到你下回合开始前必定执行此效果",
  ["zhoulin_bao"] = "豹：受到伤害",
  ["zhoulin_ying"] = "鹰：被你获得牌",
  ["zhoulin_xiong"] = "熊：被你弃装备区牌",
  ["zhoulin_tu"] = "兔：摸牌",

  ["$shoufa1"] = "毒蛇恶蝎，奉旨而行！",
  ["$shoufa2"] = "虎豹豺狼，皆听我令！",
  ["$zhoulin1"] = "料一山野书生，安识我南中御兽之术！",
  ["$zhoulin2"] = "本大王承天大法，岂与诸葛亮小计等同！",
  ["$yuxiang1"] = "额啊啊，好大的火光啊！",
  ["~muludawang"] = "啊啊，诸葛亮神人降世，吾等难挡天威。",
}

local jianggan = General(extension, "mobile__jianggan", "wei", 3)
local daoshu = fk.CreateActiveSkill{
  name = "mobile__daoshu",
  prompt = "#mobile__daoshu",
  mute = true,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local room = Fk:currentRoom()
    local target = room:getPlayerById(to_select)
    if target:getHandcardNum() < 2 then
      return false
    end

    if table.contains({"m_1v2_mode", "brawl_mode", "m_2v2_mode"}, room.room_settings.gameMode) then
      return target.role ~= Self.role
    end

    return to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(self.name, 1)
    room:notifySkillInvoked(player, self.name, "offensive")
    local target = room:getPlayerById(effect.tos[1])

    local cardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not card.is_derived then
        table.insertIfNeed(cardNames, card.name)
      end
    end
    local randomNames = table.random(cardNames, 3)
    room:setPlayerMark(target, "mobile__daoshu_names", randomNames)
    local _, dat = room:askForUseActiveSkill(target, "mobile__daoshu_choose", "#mobile__daoshu-choose", false)
    room:setPlayerMark(target, "mobile__daoshu_names", 0)

    local cardChosen = dat and dat.cards[1] or table.random(target:getCardIds("h"))
    local newName = dat and dat.interaction or table.random(
      table.filter(randomNames,
      function(name) return name ~= Fk:getCardById(cardChosen).name end)
    )
    local newHandIds = table.map(target:getCardIds("h"), function(id)
      if id == cardChosen then
        local card = Fk:getCardById(id)
        return {
          cid = 0,
          name = newName,
          extension = card.package.extensionName,
          number = card.number,
          suit = card:getSuitString(),
          color = card:getColorString(),
        }
      end

      return id
    end)

    local friends = { player }
    if table.contains({"m_1v2_mode", "brawl_mode", "m_2v2_mode"}, room.settings.gameMode) then
      friends = U.GetFriends(room, player)
    end
    for _, p in ipairs(friends) do
      p.request_data = json.encode({
        path = "packages/utility/qml/ChooseCardsAndChoiceBox.qml",
        data = {
          newHandIds,
          { "OK" },
          "#mobile__daoshu-guess",
          nil,
          1,
          1,
          {}
        },
      })
    end

    room:notifyMoveFocus(friends, self.name)
    room:doBroadcastRequest("CustomDialog", friends)

    local friendIds = table.map(friends, Util.IdMapper)
    room:sortPlayersByAction(friendIds)
    for _, pid in ipairs(friendIds) do
      local p = room:getPlayerById(pid)
      if p:isAlive() then
        local cardGuessed
        if p.reply_ready then
          cardGuessed = json.decode(p.client_reply).cards[1]
        else
          cardGuessed = table.random(target:getCardIds("h"))
        end

        if cardGuessed == 0 then
          if p == player then
            player:broadcastSkillInvoke(self.name, 2)
          end
          room:damage{
            from = p,
            to = target,
            damage = 1,
            skillName = self.name,
          }
        else
          if p == player then
            player:broadcastSkillInvoke(self.name, 3)
          end
          if# p:getCardIds("h") > 1 then
            local canDiscard = table.filter(p:getCardIds("h"), function(id) return not p:prohibitDiscard(Fk:getCardById(id)) end)
            if #canDiscard then
              room:throwCard(table.random(canDiscard, 2), self.name, p, p)
            end
          else
            room:loseHp(p, 1, self.name)
          end
        end
      end
    end
  end,
}
local daoshuChoose = fk.CreateActiveSkill{
  name = "mobile__daoshu_choose",
  mute = true,
  card_num = 1,
  target_num = 0,
  interaction = function()
    return UI.ComboBox { choices = Self:getMark("mobile__daoshu_names") }
  end,
  card_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      Fk:currentRoom():getCardArea(to_select) == Player.Hand and
      Fk:getCardById(to_select).name ~= self.interaction.data
  end,
  target_filter = Util.FalseFunc,
}
local daizui = fk.CreateTriggerSkill{
  name = "daizui",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = { fk.DamageInflicted },
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      math.max(0, player.hp) + player.shield <= data.damage and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card and data.from and data.from:isAlive() and U.hasFullRealCard(room, data.card) then
      data.from:addToPile("daizui_shi", data.card, true, self.name)
    end
    return true
  end,
}
local daizuiRegain = fk.CreateTriggerSkill{
  name = "#daizui_regain",
  mute = true,
  events = { fk.TurnEnd },
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("daizui_shi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("daizui_shi"), true, fk.ReasonPrey, player.id, "daizui")
  end,
}
Fk:addSkill(daoshuChoose)
daizui:addRelatedSkill(daizuiRegain)
jianggan:addSkill(daoshu)
jianggan:addSkill(daizui)
Fk:loadTranslationTable{
  ["mobile__jianggan"] = "蒋干",
  ["#mobile__jianggan"] = "虚义伪诚",

  ["mobile__daoshu"] = "盗书",
  [":mobile__daoshu"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的其他角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并猜测其中伪装过的牌（若为2v2或斗地主，" ..
  "则改为选择一名手牌数不少于2的敌方角色，且你与友方角色同时猜测）。猜中的角色对该角色各造成1点伤害，" ..
  "猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",
  ["daizui"] = "戴罪",
  [":daizui"] = "限定技，当你受到伤害时，若伤害值不小于你的体力值和护甲之和，你可以防止此伤害，然后将对你造成伤害的牌置于伤害来源的武将牌上，" ..
  "称为“释”。本回合结束时，其获得其“释”。",
  ["#mobile__daoshu"] = "盗书：你可与队友查看1名敌人的手牌，并找出其伪装牌名的牌",
  ["mobile__daoshu_choose"] = "盗书伪装",
  ["#mobile__daoshu-choose"] = "盗书：请选择左侧的牌名并选择一张手牌，将此牌伪装成此牌名",
  ["#mobile__daoshu-guess"] = "猜测其中伪装牌名的牌",
  ["daizui_shi"] = "释",
  ["#daizui_regain"] = "戴罪",

  ["$mobile__daoshu1"] = "嗨！不过区区信件，何妨故友一观？",
  ["$mobile__daoshu2"] = "幸吾有备而来，不然为汝所戏矣。",
  ["$mobile__daoshu3"] = "亏我一世英名，竟上了周瑜的大当！",
  ["$daizui1"] = "望丞相权且记过，容干将功折罪啊！",
  ["$daizui2"] = "干，谢丞相不杀之恩！",
  ["~mobile__jianggan"] = "唉，假信害我不浅啊……",
}

local yangfeng = General(extension, "yangfeng", "qun", 4)
local xuetu = fk.CreateActiveSkill{
  name = "xuetu",
  anim_type = "switch",
  switch_skill_name = "xuetu",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#xuetu_" .. Self:getSwitchSkillState(self.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      not (Self:getSwitchSkillState(self.name) == fk.SwitchYang and not Fk:currentRoom():getPlayerById(to_select):isWounded())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      target:drawCards(2, self.name)
    end
  end,
}
local xuetuV2 = fk.CreateActiveSkill{
  name = "xuetu_v2",
  card_num = 0,
  target_num = 1,
  mute = true,
  interaction = function()
    local options = { "xuetu_v2_recover", "xuetu_v2_draw" }
    local choices = table.filter(options, function(option) return not table.contains(Self:getTableMark("xuetu_v2_used-phase"), option) end)
    return UI.ComboBox {choices = choices, all_choices = options }
  end,
  can_use = function(self, player)
    return #player:getTableMark("xuetu_v2_used-phase") < 2
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return
      #selected == 0 and
      not (self.interaction.data == "xuetu_v2_recover" and not Fk:currentRoom():getPlayerById(to_select):isWounded())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:broadcastSkillInvoke(xuetu.name)
    room:notifySkillInvoked(player, self.name, "support")
    local target = room:getPlayerById(effect.tos[1])

    local xuetuUsed = player:getTableMark("xuetu_v2_used-phase")
    table.insertIfNeed(xuetuUsed, self.interaction.data)
    room:setPlayerMark(player, "xuetu_v2_used-phase", xuetuUsed)

    if self.interaction.data == "xuetu_v2_recover" then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }
    else
      target:drawCards(2, self.name)
    end
  end,
}
local xuetuV3 = fk.CreateActiveSkill{
  name = "xuetu_v3",
  anim_type = "switch",
  switch_skill_name = "xuetu_v3",
  card_num = 0,
  target_num = 1,
  prompt = function(self)
    return "#xuetu_v3_" .. Self:getSwitchSkillState(self.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      }

      room:askForDiscard(target, 2, 2, true, self.name, false)
    else
      player:drawCards(1, self.name)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local weiming = fk.CreateTriggerSkill{
  name = "weiming",
  mute = true,
  frequency = Skill.Quest,
  events = {fk.EventPhaseStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if player:getQuestSkillState(self.name) or not player:hasSkill(self) then
      return false
    end

    local room = player.room
    if event == fk.EventPhaseStart then
      return
        target == player and
        player.phase == Player.Play and
        table.find(room.alive_players, function(p) return p ~= player and not table.contains(p:getTableMark("@@weiming"), player.id) end)
    end

    return table.contains(player.tag["weimingTargets"] or {}, data.who) or (data.damage and data.damage.from == player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "offensive")

      local targets = table.map(
        table.filter(
          room.alive_players,
          function(p) return p ~= player and not table.contains(p:getTableMark("@@weiming"), player.id) end
        ),
        Util.IdMapper
      )
      if #targets == 0 then
        return false
      end

      local toId = room:askForChoosePlayers(player, targets, 1, 1, "#weiming-choose", self.name, false)[1]
      local to = room:getPlayerById(toId)

      local weimingTargets = player.tag["weimingTargets"] or {}
      table.insertIfNeed(weimingTargets, toId)
      player.tag["weimingTargets"] = weimingTargets

      local weimingOwners = to:getTableMark("@@weiming")
      table.insertIfNeed(weimingOwners, player.id)
      room:setPlayerMark(to, "@@weiming", weimingOwners)
    else
      for _, p in ipairs(room.alive_players) do
        local weimingOwners = p:getTableMark("@@weiming")
        table.removeOne(weimingOwners, player.id)
        room:setPlayerMark(p, "@@weiming", #weimingOwners > 0 and weimingOwners or 0)
      end
      if table.contains(player.tag["weimingTargets"] or {}, data.who) then
        player:broadcastSkillInvoke(self.name, 3)
        room:notifySkillInvoked(player, self.name, "negative")
        room:updateQuestSkillState(player, self.name, true)
        room:handleAddLoseSkills(player, "-xuetu|-xuetu_v2|xuetu_v3")
      else
        player:broadcastSkillInvoke(self.name, 2)
        room:notifySkillInvoked(player, self.name, "offensive")
        room:updateQuestSkillState(player, self.name)
        room:handleAddLoseSkills(player, "-xuetu|-xuetu_v3|xuetu_v2")
      end
    end
  end,
}
yangfeng:addSkill(xuetu)
yangfeng:addSkill(weiming)
yangfeng:addRelatedSkill(xuetuV2)
yangfeng:addRelatedSkill(xuetuV3)
Fk:loadTranslationTable{
  ["yangfeng"] = "杨奉",
  ["#yangfeng"] = "忠勇半途",

  ["xuetu"] = "血途",
  [":xuetu"] = "转换技，出牌阶段限一次，你可以：阳，令一名角色回复1点体力；阴，令一名角色摸两张牌。" ..
  "<br><strong>二级</strong>：出牌阶段各限一次，你可以选择一项：1.令一名角色回复1点体力；2.令一名角色摸两张牌。" ..
  "<br><strong>三级</strong>：转换技，出牌阶段限一次，你可以：阳，回复1点体力并令一名角色弃置两张牌；阴，摸一张牌并对一名角色造成1点伤害。",
  ["xuetu_v2"] = "血途",
  [":xuetu_v2"] = "出牌阶段各限一次，你可以选择一项：1.令一名角色回复1点体力；2.令一名角色摸两张牌。",
  ["xuetu_v3"] = "血途",
  [":xuetu_v3"] = "转换技，出牌阶段限一次，你可以：阳，回复1点体力并令一名角色弃置两张牌；阴，摸一张牌并对一名角色造成1点伤害。",
  ["weiming"] = "威命",
  [":weiming"] = "使命技，出牌阶段开始时，你标记一名未标记过的其他角色。<br>" ..
  "<strong>成功</strong>：当你杀死一名未标记的角色后，你将“血途”修改至二级；<br>" ..
  "<strong>失败</strong>：当一名已被标记的角色死亡后，你将“血途”修改至三级；<br>",
  ["#xuetu_yang"] = "血途：你可令一名角色回复1点体力",
  ["#xuetu_yin"] = "血途：你可令一名角色摸两张牌",
  ["xuetu_v2_recover"] = "令一名角色回复1点体力",
  ["xuetu_v2_draw"] = "令一名角色摸两张牌",
  ["#xuetu_v3_yang"] = "血途：你可回复1点体力并令一名角色弃两张牌",
  ["#xuetu_v3_yin"] = "血途：你可摸一张牌并对一名角色造成1点伤害",
  ["@@weiming"] = "威命",
  ["#weiming-choose"] = "威命：选择1名未被选择过的角色，如其在你杀死其他未被选择过的角色死亡前死亡，则威命失败",

  ["$xuetu1"] = "天子仪仗在此，逆贼安扰圣驾。",
  ["$xuetu2"] = "末将救驾来迟，还望陛下恕罪。",
  ["$xuetu_v31"] = "徐、扬粮草甚多，众将随我前往。",
  ["$xuetu_v32"] = "哈哈哈哈，所过之处，粒粟不留。",
  ["$weiming1"] = "诸位东归洛阳，奉愿随驾以护。",
  ["$weiming2"] = "不遵皇命，视同倡乱之贼。",
  ["$weiming3"] = "布局良久，于今功亏一篑啊。",
  ["~yangfeng"] = "刘备！本共图吕布，何设鸿门相欺！",
}

local zhangbu = General(extension, "zhangbu", "wu", 4)
zhangbu.total_hidden = true
local chengxiong = fk.CreateTriggerSkill{
  name = "chengxiong",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.firstTarget and data.card.type == Card.TypeTrick and
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
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#chengxiong-choose:::"..data.card:getColorString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(player, to, "he", self.name)
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
zhangbu:addSkill(chengxiong)
zhangbu:addSkill(wangzhuan)
Fk:loadTranslationTable{
  ["zhangbu"] = "张布",
  ["#zhangbu"] = "主胜辅义",
  --["illustrator:zhangbu"] = "",

  ["chengxiong"] = "惩凶",
  [":chengxiong"] = "你使用锦囊牌指定其他角色为目标后，你可以选择一名牌数不小于X的角色（X为你此阶段使用的牌数），弃置其一张牌，"..
  "若此牌颜色与你使用的锦囊牌颜色相同，你对其造成1点伤害。",
  ["wangzhuan"] = "妄专",
  [":wangzhuan"] = "当一名角色受到非游戏牌造成的伤害后，若你是伤害来源或受伤角色，你可以摸两张牌，然后当前回合角色非锁定技失效直到回合结束。",
  ["#chengxiong-choose"] = "惩凶：弃置一名角色一张牌，若为%arg，对其造成1点伤害",
  ["#wangzhuan-invoke"] = "妄专：你可以摸两张牌，令当前回合角色本回合非锁定技无效",
  ["@@wangzhuan-turn"] = "妄专",
}

local wangjing = General(extension, "wangjing", "wei", 3)
wangjing.total_hidden = true
local zujin = fk.CreateViewAsSkill{
  name = "zujin",
  pattern = "slash,jink,nullification",
  prompt = function (self)
    if Fk.currentResponsePattern == nil or Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard("slash")) then
      return "#zujin-slash"
    else
      return "#zujin-jink"
    end
  end,
  interaction = function()
    local all_names = {"slash", "jink", "nullification"}
    local names = U.getViewAsCardNames(Self, "zujin", all_names, {}, Self:getTableMark("zujin-turn"))
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function (self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local mark = player:getTableMark("zujin-turn")
    table.insert(mark, Fk:cloneCard(self.interaction.data).trueName)
    player.room:setPlayerMark(player, "zujin-turn", mark)
  end,
  enabled_at_play = function(self, player)
    return not table.contains(player:getTableMark("zujin-turn"), "slash") and
      (not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p.hp <= player.hp
      end))
  end,
  enabled_at_response = function(self, player, response)
    if Fk.currentResponsePattern ~= nil then
      for _, name in ipairs({"slash", "jink", "nullification"}) do
        local card = Fk:cloneCard(name)
        card.skillName = self.name
        if not table.contains(player:getTableMark("zujin-turn"), name) and Exppattern:Parse(Fk.currentResponsePattern):match(card) then
          if name == "slash" then
            return not player:isWounded() or table.find(Fk:currentRoom().alive_players, function(p)
              return p.hp < player.hp
            end)
          elseif player:isWounded() then
            if name == "jink" then
              return true
            else
              return not response
            end
          end
        end
      end
    end
  end,
}
local jiejianw = fk.CreateTriggerSkill{
  name = "jiejianw",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return target == player and player:hasSkill(self) and player.phase == Player.Start and not player:isKongcheng() and #player.room.alive_players > 1
    elseif event == fk.TargetConfirming then
      return player:hasSkill(self) and target:getMark("@jiejianw") ~= 0 and
        #AimGroup:getAllTargets(data.tos) == 1 and
        data.from ~= player.id and  --应该是
        data.card.type ~= Card.TypeEquip and  --测试确实不能偷装备
        not player.room:getPlayerById(data.from):isProhibited(player, data.card)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local cards = player:getCardIds("h")
      local result = U.askForDistribution(player, cards, player.room:getOtherPlayers(player), self.name, 0, #cards,
        "#jiejianw-give", nil, true)
      if result then
        self.cost_data = result
        return true
      end
    else
      return player.room:askForSkillInvoke(player, self.name, nil, "#jiejianw-invoke::"..target.id..":"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      for id, cards in pairs(self.cost_data) do
        if #cards > 0 then
          local p = room:getPlayerById(tonumber(id))
          room:setPlayerMark(p, "@jiejianw", tostring(math.max(p.hp, 0)))
        end
      end
      U.doDistribution(room, self.cost_data, player.id, self.name)
    else
      room:doIndicate(data.from, {player.id})
      AimGroup:cancelTarget(data, target.id)
      AimGroup:addTargets(room, data, player.id)
      player:drawCards(1, self.name)
    end
  end
}
local jiejianw_delay = fk.CreateTriggerSkill{
  name = "#jiejianw_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@jiejianw") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.hp >= tonumber(player:getMark("@jiejianw")) then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:hasSkill("jiejianw") then
          p:broadcastSkillInvoke("jiejianw")
          room:notifySkillInvoked(p, "jiejianw", "drawcard")
          p:drawCards(2, "jiejianw")
        end
      end
    end
    room:setPlayerMark(player, "@jiejianw", 0)
  end,
}
jiejianw:addRelatedSkill(jiejianw_delay)
wangjing:addSkill(zujin)
wangjing:addSkill(jiejianw)
Fk:loadTranslationTable{
  ["wangjing"] = "王经",
  ["#wangjing"] = "青云孤竹",
  --["illustrator:wangjing"] = "",

  ["zujin"] = "阻进",
  [":zujin"] = "每回合每种牌名限一次。若你未受伤或体力值不为最低，你可以将一张基本牌当【杀】使用或打出；"..
  "若你已受伤，你可以将一张基本牌当【闪】或【无懈可击】使用或打出。",
  ["jiejianw"] = "节谏",
  [":jiejianw"] = "准备阶段，你可将任意张手牌交给任意名其他角色，这些角色获得“节谏”标记。当“节谏”角色成为其他角色使用非装备牌的唯一目标时，"..
  "你可将此牌转移给你，然后摸一张牌。“节谏”角色的回合结束时，移除其“节谏”标记，若其体力值不小于X（X为你交给其牌时其体力值），你摸两张牌。",
  ["#zujin-slash"] = "阻进：你可以将一张基本牌当【杀】使用或打出",
  ["#zujin-jink"] = "阻进：你可以将一张基本牌当【闪】或【无懈可击】使用或打出",
  ["#jiejianw-give"] = "节谏：将手牌任意分配给其他角色，这些角色获得“节谏”标记",
  ["@jiejianw"] = "节谏",
  ["#jiejianw-invoke"] = "节谏：是否将对 %dest 使用的%arg转移给你并摸一张牌？",
}

local baoxin = General(extension, "mobile__baoxin", "qun", 4)

local mobile__mutao = fk.CreateActiveSkill{
  name = "mobile__mutao",
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return not player:isKongcheng() and player:getNextAlive() ~= player
    end
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local to = target
    local cids = table.filter(target:getCardIds(Player.Hand), function(id)
      return Fk:getCardById(id).trueName == "slash"
    end)
    local num = #cids -- ……
    for _ = 1, num do
      if #cids < 1 then break end
      to = to:getNextAlive()
      local id = table.random(cids)
      if to ~= target then
        room:moveCardTo(id, Player.Hand, to, fk.ReasonGive, self.name, nil, false)
      end
      cids = table.filter(cids, function(i)
        return table.contains(target:getCardIds(Player.Hand), i)
      end)
    end
    room:damage{
      from = target,
      to = to,
      damage = math.min(#table.filter(to:getCardIds(Player.Hand), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end), 2),
      skillName = self.name,
    }
  end,
}

local mobile__yimou = fk.CreateTriggerSkill{
  name = "mobile__yimou",
  events = {fk.Damaged},
  mute = true,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target:distanceTo(player) <= 1 and not target.dead
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__yimou_slash"}
    if not target:isKongcheng() then table.insert(choices, "mobile__yimou_give") end
    table.insert(choices, "Cancel")
    local room = player.room
    local choice = room:askForChoice(player, choices, self.name, "#mobile__yimou::" .. target.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name, "masochism", {target.id})
    local choice = self.cost_data
    if choice == "os__yimou_slash" then
      player:broadcastSkillInvoke(self.name, 1)
      local id = room:getCardsFromPileByRule("slash")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    else
      player:broadcastSkillInvoke(self.name, 2)
      local plist, cid = room:askForChooseCardAndPlayers(target, table.map(room:getOtherPlayers(target), Util.IdMapper), 1, 1, ".|.|.|hand", "#mobile__yimou_give", self.name, false)
      room:moveCardTo(cid, Player.Hand, room:getPlayerById(plist[1]), fk.ReasonGive, self.name, nil, false)
      target:drawCards(1, self.name)
    end
  end,
}

baoxin:addSkill(mobile__mutao)
baoxin:addSkill(mobile__yimou)

Fk:loadTranslationTable{
  ["mobile__baoxin"] = "鲍信",
  ["#mobile__baoxin"] = "坚朴的忠相",
  ["illustrator:mobile__baoxin"] = "凡果",
  ["designer:mobile__baoxin"] = "jcj熊",

  ["mobile__mutao"] = "募讨",
  [":mobile__mutao"] = "出牌阶段限一次，你可选择一名角色，令其将手牌中的（系统选择）每一张【杀】依次交给由其下家开始的每一名角色，然后其对最后一名角色造成X点伤害（X为最后一名角色手牌中【杀】的数量且至多为2）。",
  ["mobile__yimou"] = "毅谋",
  [":mobile__yimou"] = "当至你距离1以内的角色受到伤害后，你可选择一项：1.令其从牌堆获得一张【杀】；2.令其将一张手牌交给另一名角色，摸一张牌。",

  ["#mobile__mutao"] = "募讨：请选择交给 %dest 的【杀】",
  ["#mobile__yimou"] = "你想对 %dest 发动技能〖毅谋〗吗？",
  ["mobile__yimou_give"] = "令其将一张手牌交给另一名角色，摸一张牌",
  ["#mobile__yimou_give"] = "毅谋：将一张手牌交给一名其他角色，然后摸一张牌",

  ["$mobile__mutao1"] = "董贼暴乱，天下定当奋节讨之！",
  ["$mobile__mutao2"] = "募州郡义士，讨祸国逆贼！",
  ["$mobile__yimou1"] = "今蓄士众之力，据其要害，贼可破之。",
  ["$mobile__yimou2"] = "绍因权专利，久必生变，不若屯军以观。",
  ["~mobile__baoxin"] = "区区黄巾流寇，如何挡我？呃啊……",
}

local zhenji = General(extension, "mob_sp__zhenji", "qun", 3, 3, General.Female)
local bojian = fk.CreateTriggerSkill {
  name = "bojian",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      local room = player.room
      local id, end_id = 1, 1
      room.logic:getEventsByRule(GameEvent.Phase, 1, function (e)
        if e.data[1] == player and e.data[2] == Player.Play and e.id < room.logic:getCurrentEvent().id then
          id, end_id = e.id, e.end_id
          return true
        end
      end, 1)
      if id > 1 then
        local n1, suit1 = 0, {}
        room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
          if e.id <= end_id then
            local use = e.data[1]
            if use.from == player.id then
              n1 = n1 + 1
              table.insertIfNeed(suit1, use.card.suit)
            end
          end
        end, id)
        local n2, suit2 = 0, {}
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.from == player.id then
            n2 = n2 + 1
            table.insertIfNeed(suit2, use.card.suit)
          end
        end, Player.HistoryPhase)
        table.removeOne(suit1, Card.NoSuit)
        table.removeOne(suit2, Card.NoSuit)
        if n1 ~= n2 and #suit1 ~= #suit2 then
          return true
        else
          if #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
            local use = e.data[1]
            return use.from == player.id and not (use.card:isVirtual() and #use.card.subcards ~= 1) and
              table.contains(room.discard_pile, use.card:getEffectiveId())
          end, Player.HistoryPhase) > 0 then
            self.cost_data = 2
            return true
          end
        end
      else
        self.cost_data = 1
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if self.cost_data == 1 then
      player:drawCards(2, self.name)
    else
      local room = player.room
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id and not (use.card:isVirtual() and #use.card.subcards ~= 1) and
          table.contains(room.discard_pile, use.card:getEffectiveId()) then
          table.insertIfNeed(cards, use.card:getEffectiveId())
        end
      end, Player.HistoryPhase)
      local card = U.askforChooseCardsAndChoice(player, cards, {"OK"}, self.name, "#bojian-ask")
      local to = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
        "#bojian-choose:::"..Fk:getCardById(card[1]):toLogString(), self.name, false)
      to = room:getPlayerById(to[1])
      room:moveCardTo(card, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
    end
  end,
}
local jiwei = fk.CreateTriggerSkill {
  name = "jiwei",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnEnd and target ~= player then
        local n = 0
        if #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
          for _, move in ipairs(e.data) do
            if move.from then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  return true
                end
              end
            end
          end
        end, Player.HistoryTurn) > 0 then
          n = n + 1
        end
        if #player.room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryTurn) > 0 then
          n = n + 1
        end
        if n > 0 then
          self.cost_data = n
          return true
        end
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start and player:getHandcardNum() >= #player.room.alive_players and
          player:getHandcardNum() >= player.hp and #player.room:getOtherPlayers(player) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      player:drawCards(self.cost_data, self.name)
    else
      local room = player.room
      local red = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).color == Card.Red
      end)
      local black = table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).color == Card.Black
      end)
      local color = ""
      if #red > #black then
        color = "red"
      elseif #red < #black then
        color = "black"
      else
        if #red == 0 then return end
        color = room:askForChoice(player, {"red", "black"}, self.name, "#jiwei-choice")
      end
      local cards = red
      if color == "black" then
        cards = black
      end
      room:askForYiji(player, cards, room:getOtherPlayers(player), self.name, #cards, #cards, "#jiwei-give:::"..color)
    end
  end,
}
zhenji:addSkill(bojian)
zhenji:addSkill(jiwei)
Fk:loadTranslationTable{
  ["mob_sp__zhenji"] = "甄姬",
  ["#mob_sp__zhenji"] = "",
  ["illustrator:mob_sp__zhenji"] = "",

  ["bojian"] = "博鉴",
  [":bojian"] = "锁定技，出牌阶段结束时，若你本阶段使用的牌数与花色数与你上个出牌阶段均不同，则你摸两张牌；否则你选择弃牌堆中你本阶段使用过"..
  "的一张牌，将之交给一名角色。",
  ["jiwei"] = "济危",
  [":jiwei"] = "锁定技，其他角色的回合结束时，此回合每满足一项，你便摸一张牌：<br>"..
  "1.有角色失去过牌；<br>2.有角色受到过伤害。<br>"..
  "准备阶段，若你的手牌数不小于场上存活人数且不小于你的体力值，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  ["#bojian-ask"] = "博鉴：请选择其中一张牌",
  ["#bojian-choose"] = "博鉴：将%arg交给一名角色",
  ["#jiwei-choice"] = "济危：请选择一种颜色，将此颜色的手牌分配给其他角色",
  ["#jiwei-give"] = "济危：请将%arg手牌分配给其他角色",
}

return extension
