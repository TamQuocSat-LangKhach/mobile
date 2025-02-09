local extension = Package("mobile_sp2")
extension.extensionName = "mobile"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["mobile_sp2"] = "手杀-SP2",
}

local function AddWinAudio(general)
  local Win = fk.CreateActiveSkill{ name = general.name.."_win_audio" }
  Win.package = extension
  Fk:addSkill(Win)
end

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
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      return "luanqun_role_mode"
    else
      return "luanqun_1v2"
    end
  end,
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
    local result = U.askForJointCard(targets, 1, 1, false, self.name, false, nil, "#luanqun-card")
    local all_cards = {}
    for _, p in ipairs(targets) do
      local id = result[p.id][1]
      if not p.dead and table.contains(p:getCardIds("h"), id) then
        p:showCards({id})
        if table.contains(p:getCardIds("h"), id) then
          table.insertIfNeed(all_cards, id)
        end
      end
    end
    if player.dead or #all_cards == 0 then return end
    local my_card = Fk:getCardById(result[player.id][1])
    local available_cards = table.filter(all_cards, function(id) return Fk:getCardById(id).color == my_card.color end)
    table.removeOne(available_cards, my_card.id)
    local maxNum = room:isGameMode("role_mode") and 4 or 2
    local cards, choice = U.askforChooseCardsAndChoice(player, available_cards, {"OK"}, self.name,
      "#luanqun-get:::" .. maxNum, {"Cancel"}, 1, maxNum, all_cards)
    if choice ~= "Cancel" then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
    local mark = player:getTableMark(self.name)
    for _, p in ipairs(targets) do
      if not p.dead then
        local card = Fk:getCardById(result[p.id][1])
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
      room:removeTableMark(player, "luanqun", target.id)
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
  [":luanqun_1v2"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中至多两张"..
  "与你展示牌颜色相同的牌。令所有与你展示牌颜色不同的角色于其下回合出牌阶段使用第一张【杀】只能指定你为目标，且你不能响应其下回合使用的【杀】。",
  [":luanqun_role_mode"] = "出牌阶段限一次，若你有手牌，你可以令所有角色同时展示一张手牌，然后你可以获得其中至多四张"..
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
        table.map(room:getOtherPlayers(player, false), Util.IdMapper),
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
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
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
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "shoufa_1v2"
    else
      return "shoufa_role_mode"
    end
  end,
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
            local distance = room:isGameMode("1v2_mode") and 0 or 1
            return p ~= player and p:distanceTo(player) > distance
          end
        )
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local isDoudizhu = room:isGameMode("1v2_mode")
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
  [":shoufa_1v2"] = "当你每回合首次造成伤害后，你可以选择你距离1以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离不小于1的一名角色，其随机执行一种效果：<br>" ..
  "豹，其受到1点无来源伤害；<br>鹰，你随机获得其一张牌；<br>熊，你随机弃置其装备区里的一张牌；<br>兔，其摸一张牌。",
  [":shoufa_role_mode"] = "当你每回合首次造成伤害后，你可以选择你距离2以内的一名角色；每回合限五次，当你受到伤害后，" ..
  "你可以选择与你距离大于1的一名角色，其随机执行一种效果：<br>" ..
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
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") or Fk:currentRoom():isGameMode("2v2_mode") then
      return "mobile__daoshu_1v2"
    else
      return "mobile__daoshu_role_mode"
    end
  end,
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

    if Fk:currentRoom():isGameMode("2v2_mode") or Fk:currentRoom():isGameMode("1v2_mode") then
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

    local req = Request:new(friends, "CustomDialog")
    req.focus_text = self.name
    for _, p in ipairs(friends) do
      req:setData(p, {
        path = "packages/utility/qml/ChooseCardsAndChoiceBox.qml",
        data = {
          newHandIds,
          { "OK" },
          "#mobile__daoshu-guess",
          {},
          1,
          1,
          {}
        },
      })
      req:setDefaultReply(p, { cards = table.random(target:getCardIds("h")) })
    end

    req:ask()

    local friendIds = table.map(friends, Util.IdMapper)
    room:sortPlayersByAction(friendIds)
    for _, pid in ipairs(friendIds) do
      local p = room:getPlayerById(pid)
      if p:isAlive() then
        local cardGuessed = req:getResult(p).cards[1]

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
  [":mobile__daoshu_1v2"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的敌方角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并与友方角色同时猜测其中伪装过的牌。" ..
  "猜中的角色对该角色各造成1点伤害，猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",
  [":mobile__daoshu_role_mode"] = "出牌阶段限一次，你可以选择一名手牌数不少于2的其他角色，该角色从随机三个牌名中选择一个，" ..
  "并将一张牌名不同的手牌伪装成此牌名的牌，然后你观看其伪装后的手牌，并猜测其中伪装过的牌。" ..
  "猜中的角色对该角色各造成1点伤害，猜错的角色分别随机弃置两张手牌，若手牌不足则改为失去1点体力。",
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

    room:addTableMarkIfNeed(player, "xuetu_v2_used-phase", self.interaction.data)

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
    if not player:hasSkill(self) then
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

      room:addTableMarkIfNeed(to, "@@weiming", player.id)
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
      room:invalidateSkill(player, self.name)
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
    if target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick and
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
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and not player:isKongcheng() and
      #player.room:getOtherPlayers(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, cards = room:askForChooseCardsAndPlayers(player, 1, 999, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      ".|.|.|hand", "#jiejianw-give", self.name, true, false)
    if #to > 0 and #cards > 0 then
      self.cost_data = {tos = to, cards = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    room:setPlayerMark(to, "@jiejianw", tostring(math.max(to.hp, 0)))
    room:moveCardTo(self.cost_data.cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
  end
}
local jiejianw_trigger = fk.CreateTriggerSkill{
  name = "#jiejianw_trigger",
  anim_type = "support",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("jiejianw") and target:getMark("@jiejianw") ~= 0 and player:getMark("jiejianw-turn") == 0 and
      #AimGroup:getAllTargets(data.tos) == 1 and data.from ~= player.id and data.card.type ~= Card.TypeEquip and
      not player.room:getPlayerById(data.from):isProhibited(player, data.card) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Turn) ~= nil
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, "jiejianw", nil, "#jiejianw-invoke::"..target.id..":"..data.card:toLogString()) then
      self.cost_data = {tos = {target.id}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "jiejianw-turn", 1)
    AimGroup:cancelTarget(data, target.id)
    AimGroup:addTargets(room, data, player.id)
    player:drawCards(1, "jiejianw")
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
jiejianw:addRelatedSkill(jiejianw_trigger)
jiejianw:addRelatedSkill(jiejianw_delay)
wangjing:addSkill(zujin)
wangjing:addSkill(jiejianw)
Fk:loadTranslationTable{
  ["wangjing"] = "王经",
  ["#wangjing"] = "青云孤竹",
  --["illustrator:wangjing"] = "",
  ["~wangjing"] = "有母此言，经死之无悔。",
}
Fk:loadTranslationTable{
  ["zujin"] = "阻进",
  [":zujin"] = "每回合每种牌名限一次。若你未受伤或体力值不为最低，你可以将一张基本牌当【杀】使用或打出；"..
  "若你已受伤，你可以将一张基本牌当【闪】或【无懈可击】使用或打出。",
  ["#zujin-slash"] = "阻进：你可以将一张基本牌当【杀】使用或打出",
  ["#zujin-jink"] = "阻进：你可以将一张基本牌当【闪】或【无懈可击】使用或打出",

  ["$zujin1"] = "静守待援，不可中诱敌之计。",
  ["$zujin2"] = "错估军情，今唯退守狄道矣。",
  ["$zujin3"] = "蜀军远来必疲，今当先发以制。",
}
Fk:loadTranslationTable{
  ["jiejianw"] = "节谏",
  [":jiejianw"] = "准备阶段，你可以将任意张手牌交给一名其他角色，令其获得“节谏”标记。每名角色的回合限一次，当“节谏”角色成为其他角色使用"..
  "非装备牌的唯一目标时，你可以将此牌转移给你，然后摸一张牌。“节谏”角色的回合结束时，移除其“节谏”标记，若其体力值不小于你交给其牌时的体力值，"..
  "你摸两张牌。",
  ["#jiejianw-give"] = "节谏：将任意张手牌交给一名角色，其获得“节谏”标记",
  ["@jiejianw"] = "节谏",
  ["#jiejianw_trigger"] = "节谏",
  ["#jiejianw-invoke"] = "节谏：是否将对 %dest 使用的%arg转移给你并摸一张牌？",
  ["#jiejianw_delay"] = "节谏",

  ["$jiejianw1"] = "陛下何急一时，今当忍而待机啊。",
  ["$jiejianw2"] = "今权在其门，为日已久，陛下何以为抗。",
  ["$jiejianw3"] = "昔鲁昭公败走失国，陛下因而更宜深虑。",
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
    num = math.min(#table.filter(to:getCardIds(Player.Hand), function(id)
        return Fk:getCardById(id).trueName == "slash"
      end), 2)
    if num > 0 then
      room:damage{
        from = target,
        to = to,
        damage = num,
        skillName = self.name,
      }
    end
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
local zhenjiWin = fk.CreateActiveSkill{ name = "mob_sp__zhenji_win_audio" }
zhenjiWin.package = extension
Fk:addSkill(zhenjiWin)

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
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "jiwei_1v2"
    elseif Fk:currentRoom():isGameMode("2v2_mode") then
      return "jiwei_2v2"
    else
      return "jiwei_role_mode"
    end
  end,
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
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
        if not room:isGameMode("role_mode") and #player.room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryTurn) > 0 then
          n = n + (room:isGameMode("1v2_mode") and 2 or 1)
        end
        if n > 0 then
          self.cost_data = n
          return true
        end
      elseif event == fk.EventPhaseStart then
        if not (target == player and player.phase == Player.Start and #player.room:getOtherPlayers(player, false) > 0) then
          return false
        end

        if room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode") then
          return #room.players == #room.alive_players and player:getHandcardNum() >= 5
        else
          return player:getHandcardNum() >= #room.alive_players and player:getHandcardNum() >= player.hp
        end
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
      room:askForYiji(player, cards, room:getOtherPlayers(player, false), self.name, #cards, #cards, "#jiwei-give:::"..color)
    end
  end,
}
zhenji:addSkill(bojian)
zhenji:addSkill(jiwei)
Fk:loadTranslationTable{
  ["mob_sp__zhenji"] = "甄姬",
  ["#mob_sp__zhenji"] = "明珠锦玉",
  ["illustrator:mob_sp__zhenji"] = "",
  ["~mob_sp__zhenji"] = "悔入帝王家，万愿皆成空……",
  ["$mob_sp__zhenji_win_audio"] = "昔见百姓十室九空，更惜今日安居乐业。",

  ["bojian"] = "博鉴",
  [":bojian"] = "锁定技，出牌阶段结束时，若你本阶段使用的牌数与花色数与你上个出牌阶段均不同，则你摸两张牌；否则你选择弃牌堆中你本阶段使用过"..
  "的一张牌，将之交给一名角色。",
  ["jiwei"] = "济危",
  [":jiwei"] = "锁定技，其他角色的回合结束时，此回合每满足一项，你便摸一张牌：<br>"..
  "1.有角色失去过牌；<br>2.有角色受到过伤害（若为身份模式，则移除此项；若为斗地主，则满足此项额外摸一张牌）。<br>"..
  "准备阶段，若你的手牌数不小于存活人数且不小于你的体力值（若为斗地主或2v2模式，则此条件改为若所有角色均存活且你的手牌数不少于五张），" ..
  "则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  [":jiwei_1v2"] = "锁定技，其他角色的回合结束时，若此回合：有角色失去过牌，你摸一张牌；有角色受到过伤害，你摸两张牌。<br>"..
  "准备阶段，若所有角色均存活且你的手牌数不少于五张，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  [":jiwei_role_mode"] = "锁定技，其他角色的回合结束时，若此回合有角色失去过牌，你摸一张牌。<br>"..
  "准备阶段，若你的手牌数不小于存活人数且不小于你的体力值，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  [":jiwei_2v2"] = "锁定技，其他角色的回合结束时，此回合每满足一项，你便摸一张牌：<br>"..
  "1.有角色失去过牌；<br>2.有角色受到过伤害。<br>"..
  "准备阶段，若你的手牌数不小于存活人数且不小于你的体力值，则你须将手牌中数量较多颜色的牌全部分配给其他角色（若数量相同则选择一种颜色）。",
  ["#bojian-ask"] = "博鉴：请选择其中一张牌",
  ["#bojian-choose"] = "博鉴：将%arg交给一名角色",
  ["#jiwei-choice"] = "济危：请选择一种颜色，将此颜色的手牌分配给其他角色",
  ["#jiwei-give"] = "济危：请将%arg手牌分配给其他角色",

  ["$bojian1"] = "闻古者贤女，未有不学前世成败而以为己诫。",
  ["$bojian2"] = "视字辄识，方知何为礼义。",

  ["$jiwei1"] = "乱世之宝，非金银田产，而在仁心。",
  ["$jiwei2"] = "匹夫怀璧为罪，更况吾豪门大族。",
  ["$jiwei3"] = "左右乡邻，当共力时艰。",
  ["$jiwei4"] = "民不逢时，吾又何忍视其饥苦。",
}

local ganfuren = General(extension, "mobile__ganfuren", "shu", 3, 3, General.Female)

Fk:loadTranslationTable{
  ["mobile__ganfuren"] = "甘夫人",
  ["#mobile__ganfuren"] = "昭烈皇后",
  ["~mobile__ganfuren"] = "只愿夫君，大事可成，兴汉有期……",
}

local zhijie = fk.CreateTriggerSkill{
  name = "zhijie",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.EventPhaseStart then
      return player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
        target.phase == Player.Play and not (target.dead or target:isKongcheng())
    else
      if player:usedSkillTimes(self.name, Player.HistoryPhase) > 0 then
        local mark = target:getMark("@zhijie-phase")
        return type(mark) == "table" and #mark == 2 and mark[2] > target:getMark("zhijie_discard-phase")
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return event == fk.EventPhaseEnd or player.room:askForSkillInvoke(player, self.name, nil, "#zhijie-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    if event == fk.EventPhaseStart then
      local card = Fk:getCardById(room:askForCardChosen(player, target, "h", self.name))
      local cardType = card:getTypeString()
      target:showCards(card)
      room:setPlayerMark(target, "@zhijie-phase", {cardType .. "_char", 0})
    else
      room:drawCards(player, 1, self.name)
      if not target.dead then
        room:drawCards(target, 1, self.name)
      end
    end
  end,
}

local zhijieDelay = fk.CreateTriggerSkill{
  name = "#zhijie_delay",
  mute = true,
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark("@zhijie-phase") ~= 0 and
      data.card:getTypeString() .. "_char" == player:getMark("@zhijie-phase")[1]
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@zhijie-phase")
    local x = mark[2]
    mark[2] = x + 1
    room:setPlayerMark(player, "@zhijie-phase", mark)
    player:drawCards(1, "zhijie")
    if not player.dead and x > 0 then
      local cards = room:askForDiscard(player, x, x, true, "zhijie", false)
      room:addPlayerMark(player, "zhijie_discard-phase", x)
    end
  end,
}

Fk:loadTranslationTable{
  ["zhijie"] = "智诫",
  [":zhijie"] = "每轮限一次，一名角色的出牌阶段开始时，你可以展示其一张手牌。"..
  "当其于此阶段内使用与此牌类别相同的牌后，其摸一张牌并弃置X张牌（X为此效果发动的次数-1）；"..
  "此阶段结束时，若其于此阶段内以此法摸牌的数量大于以此法弃置牌的数量，你与其各摸一张牌。",

  ["#zhijie-invoke"] = "是否发动 智诫，展示%dest的一张手牌，其本阶段使用同类别牌将摸牌并弃牌",
  ["@zhijie-phase"] = "智诫",

  ["$zhijie1"] = "昔子罕不以玉为宝，《春秋》美之。",
  ["$zhijie2"] = "今吴、魏未灭，安以妖玩继怀？",
}

zhijie:addRelatedSkill(zhijieDelay)
ganfuren:addSkill(zhijie)

local shushen = fk.CreateTriggerSkill{
  name = "mobile__shushen",
  anim_type = "support",
  events = {fk.HpRecover, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        if player:getMark("mobile__shushen_recover-turn") > 0 then return false end
        local x = 0
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Player.Hand then
            x = x + #move.moveInfo
            if x > 1 then break end
          end
        end
        return x > 1 and table.find(player.room.alive_players, function (p)
          return p ~= player and p:isWounded()
        end)
      else
        if player:getMark("mobile__shushen_draw2-turn") > 0 then return false end
        return player == target and #player.room.alive_players > 1
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.HpRecover then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1,
        "#mobile__shushen-draw2", self.name, true)
      if #to > 0 then
        self.cost_data = {tos = to}
        return true
      end
    else
      local to = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
        return p ~= player and p:isWounded()
      end), Util.IdMapper), 1, 1, "#mobile__shushen-recover", self.name, true)
      if #to > 0 then
        self.cost_data = {tos = to}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    if event == fk.HpRecover then
      room:setPlayerMark(player, "mobile__shushen_draw2-turn", 1)
      room:drawCards(to, 2, self.name)
    else
      room:setPlayerMark(player, "mobile__shushen_recover-turn", 1)
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "mobile__shushen_draw2-turn", 0)
    room:setPlayerMark(player, "mobile__shushen_recover-turn", 0)
  end,
}
Fk:loadTranslationTable{
  ["mobile__shushen"] = "淑慎",
  [":mobile__shushen"] = "每回合各限一次，当你回复体力后，你可以令一名其他角色摸两张牌；"..
  "当你得到牌后，若这些牌的数量大于1，你可以令一名其他角色回复1点体力。",

  ["#mobile__shushen-draw2"] = "是否发动 淑慎，令1名其他角色摸2张牌",
  ["#mobile__shushen-recover"] = "是否发动 淑慎，令1名其他角色回复1点体力",

  ["$mobile__shushen1"] = "此者国亡之象，夫君岂不知乎？",
  ["$mobile__shushen2"] = "为人妻者，当为夫计。",
}

ganfuren:addSkill(shushen)

local shiTaishici = General(extension, "shi__taishici", "wu", 4)
local shiTaishiciWin = fk.CreateActiveSkill{ name = "shi__taishici_win_audio" }
shiTaishiciWin.package = extension
Fk:addSkill(shiTaishiciWin)
Fk:loadTranslationTable{
  ["shi"] = "势",

  ["shi__taishici"] = "势太史慈",
  ["#shi__taishici"] = "志踏天阶",
  ["$shi__taishici_win_audio"] = "幸遇伯符，吾之壮志成矣！",
  ["~shi__taishici"] = "身证大义，魂念江东……",
}

local getValueOfX = function(player, skillName, owner)
  owner = owner or player
  local markStr = owner:getMark("@shi__zhenfeng_" .. skillName)
  if markStr == "shi__zhenfeng_hp" then
    return player.hp
  elseif markStr == "shi__zhenfeng_lostHp" then
    return player:getLostHp()
  elseif markStr == "shi__zhenfeng_alives" then
    return #player.room.alive_players
  end

  if skillName == "zhanlie" then
    return player:getAttackRange()
  end

  return player.maxHp
end

local shiHanzhan = fk.CreateActiveSkill{
  name = "shi__hanzhan",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#shi__hanzhan",
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

    for _, p in ipairs({ player, target }) do
      if p:isAlive() then
        local drawNum = getValueOfX(p, self.name, player) - p:getHandcardNum()
        if drawNum > 0 then
          p:drawCards(math.min(3, drawNum), self.name)
        end
      end
    end

    local duel = Fk:cloneCard("duel")
    if player:isAlive() and target:isAlive() and player:canUseTo(duel, target) then
      room:useCard{
        from = player.id,
        tos = {{ target.id }},
        card = duel,
      }
    end
  end,
}
Fk:loadTranslationTable{
  ["shi__hanzhan"] = "酣战",
  [":shi__hanzhan"] = "出牌阶段限一次，你可以选择一名其他角色，你与其分别将手牌摸至X张（X为各自体力上限，且每名角色至多摸三张），" ..
  "然后视为你对其使用一张【决斗】。",

  ["#shi__hanzhan"] = "酣战：你可与一名其他角色摸牌，然后视为你对其使用【决斗】",

  ["$shi__hanzhan1"] = "君壮情烈胆，某必当奉陪！",
  ["$shi__hanzhan2"] = "哼！你我再斗一番，方知孰为霸王！",
}

shiTaishici:addSkill(shiHanzhan)

local parseZhanLieMark = function (player)
  local mark = player:getMark("@zhanlie")
  if mark == 0 then
    return { num = 0, max = 0 }
  end

  local markParsed = mark:split('/')
  return { num = tonumber(markParsed[1]), max = tonumber(markParsed[2]) }
end

local zhanlie = fk.CreateTriggerSkill{
  name = "zhanlie",
  anim_type = "support",
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      local zhanLie = parseZhanLieMark(player)
      return
        zhanLie.max > zhanLie.num and
        table.find(
          data,
          function(move)
            return
              move.toArea == Card.DiscardPile and
              table.find(
                move.moveInfo,
                function(info)
                  return Fk:getCardById(info.cardId).trueName == "slash" and player.room:getCardArea(info.cardId) == Card.DiscardPile
                end
              )
          end
        )
    end

    return target == player and player:hasSkill(self) and player.phase == Player.Play and parseZhanLieMark(player).num > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseEnd then
      local use = U.askForUseVirtualCard(
        room,
        player,
        "slash",
        nil,
        self.name,
        "#zhanlie-slash:::" .. math.floor(parseZhanLieMark(player).num / 3),
        true,
        true,
        false,
        true,
        nil,
        true
      )

      if not use then
        return false
      end

      self.cost_data = use
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      local zhanLie = parseZhanLieMark(player)
      local canPlusNum = zhanLie.max - zhanLie.num
      if canPlusNum == 0 then
        return false
      end

      local marksToGet = 0
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).trueName == "slash" and room:getCardArea(info.cardId) == Card.DiscardPile then
              marksToGet = marksToGet + 1
            end

            if marksToGet >= canPlusNum then
              break
            end
          end

          if marksToGet >= canPlusNum then
            break
          end
        end
      end

      room:removePlayerMark(player, "zhanlie_max", marksToGet)
      room:setPlayerMark(player, "@zhanlie", (zhanLie.num + marksToGet) .. "/" .. zhanLie.max)
    else
      local zhanLie = parseZhanLieMark(player)
      local buffNum = math.floor(zhanLie.num / 3)
      room:setPlayerMark(player, "@zhanlie", "0/" .. math.min(6, player:getMark("zhanlie_max")))

      local use = self.cost_data
      if buffNum > 0 then
        local allChoices = { "zhanlie_target", "zhanlie_damage", "zhanlie_disresponsive", "zhanlie_draw" }
        local choiceList = table.simpleClone(allChoices)

        local extraTargets = room:getUseExtraTargets(use)
        if (#extraTargets == 0) then
          table.remove(choiceList, 1)
        end

        local choices = room:askForChoices(player, choiceList, 1, buffNum, self.name, "#shi__zhanlie:::" .. buffNum, false, false, allChoices)

        for _, choice in ipairs(choices) do
          if choice == "zhanlie_target" then
            local tos = room:askForChoosePlayers(player, extraTargets, 1, 1, "#zhanlie_target", self.name, false)
            TargetGroup:pushTargets(use.tos, tos)
          elseif choice == "zhanlie_damage" then
            use.additionalDamage = (use.additionalDamage or 0) + 1
          else
            use.extra_data = use.extra_data or {}
            use.extra_data.zhanlieBuff = use.extra_data.zhanlieBuff or {}
            if choice == "zhanlie_disresponsive" then
              use.extra_data.zhanlieBuff[choice] = true
            else
              use.extra_data.zhanlieBuff[choice] = player.id
            end
          end
        end
      end

      room:useCard(use)
    end
  end,
  refresh_events = {fk.TurnStart},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self) and getValueOfX(player, self.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local zhanLie = parseZhanLieMark(player)
    local xVal = getValueOfX(player, self.name)
    if parseZhanLieMark(player).num < 6 then
      room:setPlayerMark(player, "@zhanlie", zhanLie.num .. "/" .. math.min(6, zhanLie.num + xVal))
    end
    room:setPlayerMark(player, "zhanlie_max", xVal)
  end,
}
local zhanlieBuff = fk.CreateTriggerSkill{
  name = "#zhanlie_buff",
  mute = true,
  events = {fk.PreCardEffect, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not data.extra_data or type(data.extra_data.zhanlieBuff) ~= "table" then
      return false
    end

    if event == fk.PreCardEffect then
      return data.to == player.id and data.card.trueName == "slash" and data.extra_data.zhanlieBuff.zhanlie_disresponsive
    end

    return player.id == data.extra_data.zhanlieBuff.zhanlie_draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardEffect then
      local ids = room:askForDiscard(player, 1, 1, true, self.name, true, nil, "#zhanlie_discard")
      if #ids == 0 then
        data.disresponsive = true
      end
    else
      target:drawCards(2, self.name)
    end
  end,
}
Fk:loadTranslationTable{
  ["zhanlie"] = "战烈",
  [":zhanlie"] = "一名角色的回合开始时，你记录X（X为此时你的攻击范围）。本回合中的前X张【杀】进入弃牌堆后，若此牌在弃牌堆内，" ..
  "你获得1枚“烈”标记（你至多拥有6枚“烈”标记）；出牌阶段结束时，你可以移除所有“烈”标记，视为使用一张无次数限制的【杀】，" ..
  "并选择至多Y项（Y为你本次移除的标记数/3，向下取整）：1.此【杀】目标+1；2.此【杀】伤害基数+1；3.此【杀】需目标角色额外弃置一张牌方可响应" ..
  "4.此【杀】结算结束后你摸两张牌。",
  ["#zhanlie_buff"] = "战烈",

  ["@zhanlie"] = "烈",
  ["#zhanlie-slash"] = "战烈：你可视为使用带有至多%arg个额外效果的【杀】",

  ["#shi__zhanlie"] = "战烈：请为此【杀】选择至多%arg项额外效果",
  ["zhanlie_target"] = "目标+1",
  ["zhanlie_damage"] = "伤害+1",
  ["zhanlie_disresponsive"] = "需额外弃置一张牌响应",
  ["zhanlie_draw"] = "结算结束后摸2张牌",
  ["#zhanlie_target"] = "战烈：请为此【杀】选择一个额外目标",
  ["#zhanlie_discard"] = "战烈：请弃置一张牌，否则你不能响应此【杀】",

  ["$zhanlie1"] = "且看此箭之下，焉有偷生之人？",
  ["$zhanlie2"] = "哼，汝还能战否？",
  ["$zhanlie3"] = "君头已在此，还不授首来降！",
}

zhanlie:addRelatedSkill(zhanlieBuff)
shiTaishici:addSkill(zhanlie)

local shiZhenfeng = fk.CreateActiveSkill{
  name = "shi__zhenfeng",
  frequency = Skill.Limited,
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  prompt = "#shi__zhenfeng",
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      (player:isWounded() or (player:hasSkill("shi__hanzhan", true) or player:hasSkill("zhanlie", true)))
  end,
  interaction = function()
    local choiceList = {}
    if Self:isWounded() then
      table.insert(choiceList, "shi__zhenfeng_recover")
    end

    if Self:hasSkill("shi__hanzhan", true) or Self:hasSkill("zhanlie", true) then
      table.insert(choiceList, "shi__zhenfeng_upgrade")
    end

    return UI.ComboBox { choices = choiceList, all_choices = { "shi__zhenfeng_recover", "shi__zhenfeng_upgrade" } }
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    if self.interaction.data == "shi__zhenfeng_recover" then
      room:recover{
        who = player,
        num = 2,
        recoverBy = player,
        skillName = self.name,
      }
    else
      for _, skill in ipairs({ "shi__hanzhan", "zhanlie" }) do
        if player:hasSkill(skill, true) then
          local choice = room:askForChoice(
            player,
            { "shi__zhenfeng_hp", "shi__zhenfeng_lostHp", "shi__zhenfeng_alives" },
            skill,
            "#shi__zhenfeng-choose:::" .. skill
          )
          room:setPlayerMark(player, "@shi__zhenfeng_" .. skill, choice)
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["shi__zhenfeng"] = "振锋",
  [":shi__zhenfeng"] = "限定技，出牌阶段，你可以选择一项：1.回复2点体力；2.分别修改“酣战”及“战烈”中的X为当前体力值、" ..
  "已损失体力值、存活角色数中的一项（拥有对应技能方可选择）。",

  ["#shi__zhenfeng"] = "振锋：你可以回复体力或修改其他技能",
  ["shi__zhenfeng_recover"] = "回复2点体力",
  ["shi__zhenfeng_upgrade"] = "修改技能",

  ["shi__zhenfeng_hp"] = "当前体力值",
  ["shi__zhenfeng_lostHp"] = "已损失体力值",
  ["shi__zhenfeng_alives"] = "存活角色数",
  ["#shi__zhenfeng-choose"] = "振锋：请将%arg中的X修改为其中一项",

  ["@shi__zhenfeng_shi__hanzhan"] = "酣战",
  ["@shi__zhenfeng_zhanlie"] = "战烈",

  ["$shi__zhenfeng1"] = "有胆气者，随某前去一战！",
  ["$shi__zhenfeng2"] = "待吾重振兵马，胜负犹未可知！",
  ["$shi__zhenfeng3"] = "前番未见高下，此番定决生死！",
  ["$shi__zhenfeng4"] = "天道择义而襄，英雄待机而胜！",
}

shiTaishici:addSkill(shiZhenfeng)

local dongzhao = General(extension, "dongzhao", "wei", 3)
local miaolue = fk.CreateTriggerSkill{
  name = "miaolue",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"draw2", "miaolue_zhinang", "Cancel"}, self.name)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data.choice == "draw2" then
      player:drawCards(2, self.name)
    else
      local choice = room:askForChoice(player, {"dismantlement", "nullification", "ex_nihilo"}, self.name, "#miaolue-ask")
      local id = room:getCardsFromPileByRule(choice, 1, "allPiles")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
      end
    end
  end,
}
local miaolue_trigger = fk.CreateTriggerSkill{
  name = "#miaolue_trigger",
  anim_type = "drawcard",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("miaolue")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local miaolue_derivecards = {
      {"underhanding", Card.Spade, 5},
      {"underhanding", Card.Club, 5},
      {"underhanding", Card.Heart, 5},
      {"underhanding", Card.Diamond, 5},
    }
    local cids = table.filter(U.prepareDeriveCards(room, miaolue_derivecards, "miaolue_derivecards"), function (id)
      return room:getCardArea(id) == Card.Void
    end)
    if #cids > 0 then
      room:obtainCard(player, table.random(cids, 2), false, fk.ReasonPrey, player.id, "miaolue", MarkEnum.DestructIntoDiscard)
    end
  end,
}
miaolue:addRelatedSkill(miaolue_trigger)
dongzhao:addSkill(miaolue)
Fk:loadTranslationTable{
  ["dongzhao"] = "董昭",
  ["$miaolue1"] = "",
  ["$miaolue2"] = "",
  ["$yingjia1"] = "",
  ["$yingjia2"] = "",
  ["~dongzhao"] = "",
}
Fk:loadTranslationTable{
  ["miaolue"] = "妙略",
  [":miaolue"] = "游戏开始时，你获得两张<a href='underhanding_href'>【瞒天过海】</a>；当你受到伤害后，你可以选择一项：" ..
  "1.摸两张牌；2.从牌堆或弃牌堆获得一张你指定的<a href='bag_of_tricks'>智囊</a>。",
  ["miaolue_zhinang"] = "获得一张你指定的智囊",
  ["#miaolue-ask"] = "妙略：选择要获得的一种“智囊”",
  ["#miaolue_trigger"] = "妙略",
}
local yingjia = fk.CreateTriggerSkill{
  name = "yingjia",
  anim_type = "control",
  frequency = Skill.Limited,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      not player:isKongcheng() then
      local names = {}
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id and use.card.type == Card.TypeTrick then
          local name = use.card.trueName
          if table.contains(names, name) then
            return true
          else
            table.insert(names, name)
          end
        end
      end, Player.HistoryTurn) == 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    local to, card = room:askForChooseCardAndPlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1,
      tostring(Exppattern{ id = cards }), "#yingjia-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to, card = {card}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    room:throwCard(self.cost_data.card, self.name, player, player)
    if not to.dead then
      to:gainAnExtraTurn(true, self.name)
    end
  end
}
local yingjia_delay = fk.CreateTriggerSkill{
  name = "#yingjia_delay",
  mute = true,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getCurrentExtraTurnReason() == "yingjia"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, "yingjia")
  end,
}
yingjia:addRelatedSkill(yingjia_delay)
dongzhao:addSkill(yingjia)
Fk:loadTranslationTable{
  ["yingjia"] = "迎驾",
  [":yingjia"] = "限定技，一名角色的回合结束时，若你于此回合内使用过至少两张同名锦囊牌，你可以弃置一张手牌，令一名角色执行一个额外回合，"..
  "此额外回合开始时其摸两张牌。",
  ["#yingjia-choose"] = "迎驾：弃置一张手牌，令一名角色获得一个额外回合",
}

local shuffleCardtoDrawPile = function (player, cards, skillName, proposer)
  proposer = proposer or player.id
  local room = player.room
  local x = #cards
  table.shuffle(cards)
  local positions = {}
  local y = #room.draw_pile
  for _ = 1, x, 1 do
    table.insert(positions, math.random(y+1))
  end
  table.sort(positions, function (a, b)
    return a > b
  end)
  local moveInfos = {}
  for i = 1, x, 1 do
    table.insert(moveInfos, {
      ids = {cards[i]},
      from = player.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      drawPilePosition = positions[i],
      proposer = proposer,
    })
  end
  room:moveCards(table.unpack(moveInfos))
end

local guansha = fk.CreateTriggerSkill{
  name = "guansha",
  frequency = Skill.Limited,
  anim_type = "defensive",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Play and
      player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("he")
    local x = #cards
    if x == 0 then return false end
    shuffleCardtoDrawPile(player, cards, self.name)
    if player.dead then return false end
    cards = room:getCardsFromPileByRule(".|.|.|.|.|basic", x)
    if #cards > 0 then
      local names = {}
      for _, id in ipairs(cards) do
        table.insertIfNeed(names, Fk:getCardById(id).trueName)
      end
      room:obtainCard(player, cards, false, fk.ReasonJustMove, player.id, self.name)
      if not player.dead then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, #names)
      end
    end
  end,
}

Fk:loadTranslationTable{
  ["guansha"] = "灌沙",
  [":guansha"] = "限定技，出牌阶段结束时，你可以将所有牌替换为牌堆中等量的基本牌，"..
    "然后你于此回合内手牌上限+X（X为你以此法得到的牌的牌名数）。",

  ["$guansha1"] = "今趁天寒，可灌沙为城，不过达晓之功。",
  ["$guansha2"] = "如此坚壁可成，虽金汤之固未能过也。",
}

local jiyu = fk.CreateActiveSkill{
  name = "jiyul",
  anim_type = "drawcard",
  prompt = "#jiyul-active",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 0,
  card_filter = function(self, to_select, selected, player)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and
      not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local cardType = Fk:getCardById(effect.cards[1]):getTypeString()
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local types = { "basic", "trick", "equip" }
    table.removeOne(types, cardType)
    local cardMap = {}
    cardMap["basic"] = {}
    cardMap["trick"] = {}
    cardMap["equip"] = {}
    for _, id in ipairs(room.draw_pile) do
      table.insert(cardMap[Fk:getCardById(id):getTypeString()], id)
    end
    local toGet = {}
    for _, typeName in ipairs(types) do
      if #cardMap[typeName] > 0 then
        table.insert(toGet, table.random(cardMap[typeName]))
      end
    end
    if #toGet > 0 then
      room:obtainCard(player, toGet, false, fk.ReasonJustMove, player.id, self.name, "@@jiyul-phase")
    end
  end,

  on_lose = function (self, player)
    U.clearHandMark(player, "@@jiyul-phase")
  end
}

local jiyuRefresh = fk.CreateTriggerSkill{
  name = "#jiyul_refresh",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(jiyu, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local loseByUse = false
    local loseByOtherReason = false
    local card
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          card = Fk:getCardById(info.cardId)
          if card:getMark("@@jiyul-phase") ~= 0 then
            room:setCardMark(card, "@@jiyul-phase", 0)
            if move.moveReason == fk.ReasonUse then
              loseByUse = true
            else
              loseByOtherReason = true
            end
          end
        end
      end
    end
    if loseByOtherReason then
      U.clearHandMark(player, "@@jiyul-phase")
    elseif loseByUse and table.every(player:getCardIds(Player.Hand), function (id)
      return Fk:getCardById(id):getMark("@@jiyul-phase") == 0
    end) then
      player:setSkillUseHistory("jiyul", 0, Player.HistoryPhase)
    end
  end,
}

jiyu:addRelatedSkill(jiyuRefresh)

Fk:loadTranslationTable{
  ["jiyul"] = "急御",
  [":jiyul"] = "出牌阶段限一次，你可以弃置一张手牌，从牌堆随机获得此牌类别以外的牌各一张，"..
    "若你使用过所有于此阶段内以此法得到的牌，此技能视为未发动过。",

  ["#jiyul-active"] = "发动 急御，弃置一张手牌，从牌堆随机获得此牌类别以外的牌各一张",
  ["@@jiyul-phase"] = "急御",

  ["$jiyul1"] = "丞相今与贼战，当急筑营寨，以御敌变也。",
  ["$jiyul2"] = "三军既出，营为首务，安可不筑城以御乎？",
  ["$jiyul3"] = "丞相英明一世，岂为此事所迷？",
}

local lougui = General(extension, "mobile__lougui", "wei", 3)
lougui:addSkill(guansha)
lougui:addSkill(jiyu)

Fk:loadTranslationTable{
  ["mobile__lougui"] = "娄圭",
  ["#mobile__lougui"] = "一日之寒",
  --["illustrator:mobile__lougui"] = "",
  ["~mobile__lougui"] = "丞相留步，老夫告辞……",
}

local zengou = fk.CreateActiveSkill{
  name = "mobile__zengou",
  anim_type = "control",
  prompt = "#mobile__zengou-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards, card, extra_data, player)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng() and
      not table.contains(player:getTableMark("mobile__zengou_prohibit"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    local choice = U.askforViewCardsAndChoice(player, cids, {"mobile__zengou_use", "mobile__zengou_exchange"},
      self.name, "#mobile__zengou-choose::" .. target.id)
    local card
    local cardName
    if choice == "mobile__zengou_use" then
      local cards = U.getUniversalCards(room, "b", false)
      local toUse = table.filter(cards, function(id)
        cardName = Fk:getCardById(id).trueName
        return table.every(cids, function(id2)
          return cardName ~= Fk:getCardById(id2).trueName
        end)
      end)
      while #toUse > 0 do
        local use = U.askForUseRealCard(room, player, toUse, nil, self.name,
          "#mobile__zengou-use", {expand_pile = toUse, bypass_times = true}, true, false)
        if use then
          room:addPlayerMark(player, "@mobile__zengou-round")
          card = Fk:cloneCard(use.card.name)
          card.skillName = self.name
          room:useCard{
            card = card,
            from = player.id,
            tos = use.tos,
            extraUse = true,
          }
          if player.dead then return end
          cardName = card.trueName
          toUse = table.filter(toUse, function(id)
            return Fk:getCardById(id).trueName ~= cardName
          end)
        else
          break
        end
      end
    else
      local cardMap = {}
      for _, id in ipairs(player:getCardIds(Player.Hand)) do
        card = Fk:getCardById(id)
        cardName = card.trueName
        cardMap[cardName] = cardMap[cardName] or {}
        table.insert(cardMap[cardName], id)
      end
      local toPut = {}
      local cardNames = {}
      for _, id in ipairs(cids) do
        card = Fk:getCardById(id)
        cardName = card.trueName
        if cardMap[cardName] then
          table.insert(cardNames, cardName)
          table.insertTable(toPut, cardMap[cardName])
          cardMap[cardName] = nil
        end
      end
      local x = #toPut
      if x > 0 then
        shuffleCardtoDrawPile(player, toPut, self.name)
        if not player.dead then
          toPut = room:getCardsFromPileByRule("slash", x)
          if #toPut > 0 then
            room:obtainCard(player, toPut, false, fk.ReasonJustMove, player.id, self.name, "@@mobile__zengou-inhand")
          end
        end
        toPut = table.filter(target:getCardIds(Player.Hand), function (id)
          return table.contains(cardNames, Fk:getCardById(id).trueName)
        end)
        x = #toPut
        if x > 0 then
          shuffleCardtoDrawPile(target, toPut, self.name, player.id)
          if not target.dead then
            toPut = room:getCardsFromPileByRule("slash", x)
            if #toPut > 0 then
              room:obtainCard(target, toPut, false, fk.ReasonJustMove, player.id, self.name, "@@mobile__zengou-inhand")
            end
          end
        end
      end
    end
    if player:hasSkill(self, true) and not target.dead then
      local cards = U.getUniversalCards(room, "b", true)
      if #cards > 0 then
        local id = room:askForCardChosen(
          player,
          target,
          {
            card_data = {
              { "basic", cards }
            }
          },
          self.name,
          "#mobile__zengou-bname::" .. target.id
        )
        U.setPrivateMark(target, "mobile__zengou_wu", { Fk:getCardById(id).trueName }, { player.id })
      end
    end
  end,

  on_lose = function (self, player)
    local room = player.room
    room:setPlayerMark(player, "@mobile__zengou-round", 0)
    room:setPlayerMark(player, "mobile__zengou_prohibit", 0)
  end
}

local zengouTrigger = fk.CreateTriggerSkill{
  name = "#mobile__zengou_trigger",
  anim_type = "negative",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player.id ~= data.from or not table.contains(U.getPrivateMark(player, "mobile__zengou_wu"), data.card.trueName) then
      return false
    end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark = player:getMark("mobile__zengou-turn")
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id then
          mark = e.id
          room:setPlayerMark(player, "mobile__zengou-turn", mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    return mark == use_event.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@[private]mobile__zengou_wu", 0)
    room:loseHp(player, 1, self.name)
  end,
}

local zengouRefresh = fk.CreateTriggerSkill{
  name = "#mobile__zengou_refresh",

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    U.clearHandMark(player, "@@mobile__zengou-inhand")
  end,
}

local zengouMaxCards = fk.CreateMaxCardsSkill{
  name = "#mobile__zengou_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@mobile__zengou-inhand") > 0
  end,
}

zengou:addRelatedSkill(zengouTrigger)
zengou:addRelatedSkill(zengouRefresh)
zengou:addRelatedSkill(zengouMaxCards)

Fk:loadTranslationTable{
  ["mobile__zengou"] = "谮构",
  [":mobile__zengou"] = "出牌阶段限一次，你可以观看一名角色的所有手牌，选择："..
    "1.依次可以视为使用其手牌区里没有的牌名的基本牌各一张（不计入次数且无次数限制）；"..
    "2.你与其依次将手牌区里的共有牌名的牌替换为牌堆中等量的【杀】（以此法得到的【杀】直到各自的回合结束之前不计入手牌上限）。"..
    "然后其获得一个“诬”标记并记录一个你指定的基本牌名。"..
    "拥有此标记的角色每回合使用的第一张牌结算后，若与记录的牌名相同，其移除此标记并失去1点体力。",

  ["#mobile__zengou-active"] = "发动 谮构，选择一名角色，观看其所有手牌",
  ["#mobile__zengou-choose"] = "谮构：观看%dest的手牌并选择一项",
  ["mobile__zengou_use"] = "视为使用基本牌",
  ["mobile__zengou_exchange"] = "将牌替换为【杀】",
  ["#mobile__zengou-use"] = "谮构：你可以依次使用不同牌名的基本牌各一张（不计入次数且无次数限制）",
  ["#mobile__zengou-bname"] = "谮构：为%dest的“诬”标记记录一种基本牌的名称",
  ["#mobile__zengou_trigger"] = "谮构",
  ["@mobile__zengou-round"] = "谮构",

  ["@@mobile__zengou-inhand"] = "谮构",
  ["@[private]mobile__zengou_wu"] = "诬",

  ["$mobile__zengou1"] = "汝既负我在先，就休怪我心狠手辣。",
  ["$mobile__zengou2"] = "有此把柄在手，教汝有口难言。",
  ["$mobile__zengou3"] = "哼！只有如此，方解我所受之辱。",
}

local feili = fk.CreateTriggerSkill{
  name = "feili",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:hasSkill("mobile__zengou", true) and
      (#player:getCardIds("he") >= math.max(1, player:getMark("@mobile__zengou-round")) or
      (data.from and data.from:getMark("@[private]mobile__zengou_wu") ~= 0))
  end,
  on_cost = function(self, event, target, player, data)
    local x = math.max(1, player:getMark("@mobile__zengou-round"))
    if data.from and data.from:getMark("@[private]mobile__zengou_wu") ~= 0 then
      local cards, choice = U.askForCardByMultiPatterns(
        player,
        {
          { ".", x, x, "feili_discard:::" .. tostring(x) },
          { ".", 0, 0, "feili_removemark::" .. data.from.id }
        },
        self.name,
        true,
        "#feili-invoke",
        {
          discard_skill = true
        }
      )
      if choice == "" then return false end
      if #cards > 0 then
        self.cost_data = { cards = cards }
        return true
      else
        self.cost_data = { tos = { data.from.id }, cards = cards }
        return true
      end
    else
      local cards = player.room:askForDiscard(player, x, x, true, self.name, true, ".", "#feili-discard:::" .. tostring(x), true)
      if #cards > 0 then
        self.cost_data = { cards = cards }
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = self.cost_data.cards
    if #cards > 0 then
      room:throwCard(cards, self.name, player)
    else
      room:setPlayerMark(data.from, "@[private]mobile__zengou_wu", 0)
      room:drawCards(player, 2, self.name)
      if player:hasSkill("mobile__zengou", true) then
        room:addTableMark(player, "mobile__zengou_prohibit", data.from.id)
      end
    end
    return true
  end,
}

Fk:loadTranslationTable{
  ["feili"] = "诽离",
  [":feili"] = "当你受到伤害时，若你拥有〖谮构〗，你可以弃置X张牌来防止此伤害（X为你于此轮内因〖谮构〗而使用过的牌数且至少为1），"..
    "若来源拥有“诬”标记，你可以改为移除此标记来防止此伤害，然后你摸两张牌且本局游戏不能对其发动〖谮构〗。",

  ["#feili-invoke"] = "是否发动 诽离，弃置“诬”标记或牌来防止伤害",
  ["#feili-discard"] = "是否发动 诽离，弃置%arg张牌来防止伤害",
  ["feili_removemark"] = "移除%dest的“诬”标记",
  ["feili_discard"] = "弃置%arg张牌",

  ["$feili1"] = "怪我未下狠手，让你饶幸生还。",
  ["$feili2"] = "夏侯楙，事已至此，何必再惺惺作态。",
}

local qinghegongzhu = General(extension, "mobile__qinghegongzhu", "wei", 3, 3, General.Female)
qinghegongzhu:addSkill(zengou)
qinghegongzhu:addSkill(feili)
AddWinAudio(qinghegongzhu)

Fk:loadTranslationTable{
  ["mobile__qinghegongzhu"] = "清河公主",
  ["#mobile__qinghegongzhu"] = "蛊虿之谗",
  --["illustrator:mobile__qinghegongzhu"] = "",
  ["~mobile__qinghegongzhu"] = "夏侯楙徒有形表，实非良人……",
  ["$mobile__qinghegongzhu_win_audio"] = "夫君自走思路，何可怨得妾身。",
}

return extension
