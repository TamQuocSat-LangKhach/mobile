
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
Fk:loadTranslationTable{
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
  [":daizui"] = "限定技，当你受到致命伤害时，你可以防止此伤害，然后将对你造成伤害的牌置于伤害来源的武将牌上，称为“释”。" ..
  "本回合结束时，其获得其“释”。",
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
}

local yangfeng = General(extension, "yangfeng", "qun", 4)
local xuetu = fk.CreateActiveSkill{
  name = "xuetu",
  anim_type = "switch",
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
    end) and player:getMark("jiyul_reset-phase") == 0 then
      room:setPlayerMark(player, "jiyul_reset-phase", 1)
      player:setSkillUseHistory("jiyul", 0, Player.HistoryPhase)
    end
  end,
}

jiyu:addRelatedSkill(jiyuRefresh)

Fk:loadTranslationTable{
  ["jiyul"] = "急御",
  [":jiyul"] = "出牌阶段限一次，你可以弃置一张手牌，从牌堆随机获得此牌类别以外的牌各一张。"..
    "每阶段限一次，若你于此阶段使用了所有因此获得的牌，复原此技能。",

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


local mobile__huojun = General(extension, "mobile__huojun", "shu", 4)

local mobile__sidai = fk.CreateViewAsSkill{
  name = "mobile__sidai",
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_filter = Util.FalseFunc,
  prompt = "#mobile__sidai",
  view_as = function(self, cards)
    local c = Fk:cloneCard("slash")
    c:addSubcards(table.filter(Self.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end))
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local basic_cards = {}
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(basic_cards, Fk:getCardById(id).name)
    end
    use.extraUse = true
    use.extra_data = use.extra_data or {}
    use.extra_data.mobile__sidaiBuff = basic_cards
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and table.find(player.player_cards[Player.Hand], function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic
    end)
  end,
  enabled_at_response = Util.FalseFunc,
}

local mobile__sidai_delay = fk.CreateTriggerSkill{
  name = "#mobile__sidai_delay",
  mute = true,
  events = {fk.Damage, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not data.card or not table.contains(data.card.skillNames, mobile__sidai.name) then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
    if not parentUseData then return false end
    local buff = (parentUseData.data[1].extra_data or Util.DummyTable).mobile__sidaiBuff or Util.DummyTable
    if event == fk.TargetConfirmed then
      return table.contains(buff, "jink")
    else
      return table.contains(buff, "peach") and not data.to.dead
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:changeMaxHp(data.to, -1)
    elseif player:isKongcheng() or #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|basic", "#mobile__sidai_nojink") == 0 then
      data.disresponsive = true
    end
  end,
}
mobile__sidai:addRelatedSkill(mobile__sidai_delay)
mobile__huojun:addSkill(mobile__sidai)

local mobile__jieyu = fk.CreateTriggerSkill{
  name = "mobile__jieyu",
  events = {fk.EventPhaseStart},
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@mobile__jieyu")
    local names, get = {}, {}
    local pile = table.simpleClone(room.discard_pile)
    while #get < x do
      local id = table.remove(pile, math.random(#pile))
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and table.insertIfNeed(names, card.trueName) then
        table.insert(get, id)
      end
    end
    if #get > 0 then
      room:obtainCard(player, get, true, fk.ReasonPrey, player.id, self.name)
    end
  end,
  on_acquire = function (self, player, is_start)
    player.room:setPlayerMark(player, "@mobile__jieyu", 3)
  end,
  on_lose = function (self, player, is_death)
    player.room:setPlayerMark(player, "@mobile__jieyu", 0)
  end,
  refresh_events = {fk.EventPhaseEnd, fk.TargetConfirmed},
  can_refresh = function (self, event, target, player, data)
    if target == player and player:getMark("@mobile__jieyu") > 0 then
      if event == fk.EventPhaseEnd then
        return player.phase == Player.Finish and player:getMark("@mobile__jieyu") ~= 3
      else
        return (data.card.trueName == "slash" or (data.card.is_damage_card and data.card.type == Card.TypeTrick))
        and data.from ~= player.id and player:getMark("@mobile__jieyu") > 1
        and player:usedSkillTimes(self.name, Player.HistoryGame) > 0 -- 未发动第一次技能时不会使X减少
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.EventPhaseEnd then
      player.room:setPlayerMark(player, "@mobile__jieyu", 3)
    else
      player.room:removePlayerMark(player, "@mobile__jieyu", 1)
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile__sidai"] = "伺怠",
  [":mobile__sidai"] = "限定技，出牌阶段，你可将所有基本牌当【杀】使用（不计入次数）。若这些牌中有：【桃】，此【杀】造成伤害后，受到伤害角色减1点体力上限；【闪】，此【杀】的目标需弃置一张基本牌，否则不能响应。",
  ["#mobile__sidai_delay"] = "伺怠",
  ["#mobile__sidai_nojink"] = "伺怠：弃置一张基本牌，否则不能响应此【杀】",
  ["#mobile__sidai"] = "伺怠：你可将所有基本牌当【杀】使用（有桃、闪则获得额外效果）！",

  ["mobile__jieyu"] = "竭御",
  [":mobile__jieyu"] = "结束阶段，你可从弃牌堆中随机获得X张牌名各不相同的基本牌（X为3-你上次发动此技能至本阶段，你成为其他角色【杀】或伤害类锦囊目标的次数，X至少为1）。",
  ["@mobile__jieyu"] = "竭御",

  ["$mobile__sidai1"] = "敌军疲乏，正是战机，随我杀！",
  ["$mobile__sidai2"] = "敌军无备，随我冲锋！",
  ["$mobile__jieyu1"] = "葭萌，蜀之咽喉，峻必竭力守之。",
  ["$mobile__jieyu2"] = "吾头可得，城不可得。",
}
