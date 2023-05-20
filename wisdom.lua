local extension = Package("wisdom")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["wisdom"] = "智包",
}

local wisdomWangcan = General(extension, "mobile__wangcan", "wei", 3)
Fk:loadTranslationTable{
  ["mobile__wangcan"] = "王粲",
  ["~mobile__wangcan"] = "悟彼下泉人，喟然伤心肝……",
}

local wisdomQiai = fk.CreateActiveSkill{
  name = "wisdom__qiai",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_filter = function(self, to_select)
    return to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:moveCardTo(Fk:getCardById(effect.cards[1]), Player.Hand, to, fk.ReasonGive, self.name, nil, true)

    local choices = { "wisdom__qiai-draw" }
    if from:isWounded() then
      table.insert(choices, 1, "wisdom__qiai-recover")
    end

    local choice = room:askForChoice(to, choices, self.name, "#wisdom__qiai-choose::" .. from.id)
    if choice:startsWith("wisdom__qiai-draw") then
      from:drawCards(2, self.name)
    else
      room:recover({
        who = from,
        num = 1,
        recoverBy = to,
        skillName = self.name,
      })
    end
  end,
}
Fk:loadTranslationTable{
  ["wisdom__qiai"] = "七哀",
  [":wisdom__qiai"] = "出牌阶段限一次，你可以将一张非基本牌交给一名其他角色，然后其须选择一项：1.令你回复1点体力；2.令你摸两张牌。",
  ["#wisdom__qiai-choose"] = "七哀：请选择一项令 %dest 执行",
  ["wisdom__qiai-draw"] = "令其摸两张牌",
  ["wisdom__qiai-recover"] = "令其回复1点体力",
  ["$wisdom__qiai1"] = "亲戚对我悲，朋友相追攀。",
  ["$wisdom__qiai2"] = "出门无所见，白骨蔽平原。",
}

wisdomWangcan:addSkill(wisdomQiai)

local wisdomShanxi = fk.CreateTriggerSkill{
  name = "wisdom__shanxi",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then
      return false
    end

    if event == fk.EventPhaseStart then
      return
        target == player and
        player.phase == Player.Play and
        table.find(player.room:getOtherPlayers(player, false), function(p)
          return p:getMark("@@wisdom__xi") == 0
        end)
    else
      return target:getMark("@@wisdom__xi") > 0 and not target.dying and target:isAlive()
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local to = player.room:askForChoosePlayers(
        player,
        table.map(table.filter(player.room:getOtherPlayers(player, false), function(p)
          return p:getMark("@@wisdom__xi") == 0
        end), function(p)
          return p.id
        end),
        1,
        1,
        "#wisdom__shanxi-choose",
        self.name
      )

      if #to == 0 then
        return false
      end

      self.cost_data = to[1]
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local source = table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getMark("@@wisdom__xi") > 0
      end)
      if source then
        room:setPlayerMark(source, "@@wisdom__xi", 0)
      end
      room:setPlayerMark(room:getPlayerById(self.cost_data), "@@wisdom__xi", 1)
    else
      local cardIds = room:askForCard(target, 2, 2, false, self.name, true, nil, "#wisdom__shanxi-give::" .. player.id)
      if #cardIds == 2 then
        local pack = Fk:cloneCard("slash")
        pack:addSubcards(cardIds)
        room:moveCardTo(pack, Player.Hand, player, fk.ReasonGive, self.name)
      else
        room:loseHp(target, 1, self.name)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["wisdom__shanxi"] = "善檄",
  [":wisdom__shanxi"] = "出牌阶段开始时，你可以令一名没有“檄”的角色获得一枚“檄”标记（若场上有该标记则改为转移至该角色）；当有“檄”标记的角色回复体力后，若其不处于濒死状态，其须选择一项：1.交给你两张牌；2.失去1点体力。",
  ["#wisdom__shanxi-choose"] = "善檄：请选择一名其他角色获得“檄”标记（场上已有则转移标记至该角色）",
  ["@@wisdom__xi"] = "檄",
  ["#wisdom__shanxi-give"] = "善檄：请交给%dest两张牌，否则失去1点体力",
  ["$wisdom__shanxi1"] = "西京乱无象，豺虎方遘患。",
  ["$wisdom__shanxi2"] = "复弃中国去，委身适荆蛮。",
}

wisdomWangcan:addSkill(wisdomShanxi)

local chenzhen = General(extension, "chenzhen", "shu", 3)
Fk:loadTranslationTable{
  ["chenzhen"] = "陈震",
  ["~chenzhen"] = "若毁盟约，则两败俱伤！",
}

local shameng = fk.CreateActiveSkill{
  name = "shameng",
  anim_type = "drawcard",
  card_num = 2,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and #player:getCardIds(Player.Hand) > 1
  end,
  card_filter = function(self, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) ~= Player.Hand then
      return false
    end

    return #selected == 0 or Fk:getCardById(selected[1]):compareColorWith(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select)
    return to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, from, from)

    room:getPlayerById(effect.tos[1]):drawCards(2, self.name)
    from:drawCards(3, self.name)
  end,
}
Fk:loadTranslationTable{
  ["shameng"] = "歃盟",
  [":shameng"] = "出牌阶段限一次，你可以弃置两张颜色相同的手牌并选择一名其他角色，该角色摸两张牌，然后你摸三张牌。",
  ["$mobile__god_huishi1"] = "震以不才，得充下使，愿促两国盟好。",
  ["$mobile__god_huishi2"] = "震奉聘叙好，若有违贵国典制，万望告之。",
}

chenzhen:addSkill(shameng)

local godguojia = General(extension, "godguojia", "god", 3)
Fk:loadTranslationTable{
  ["godguojia"] = "神郭嘉",
  ["~godguojia"] = "可叹桢干命也迂……",
}

local godHuishi = fk.CreateActiveSkill{
  name = "mobile__god_huishi",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.maxHp < 10
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return false
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)

    local cardsJudged = {}
    while from.maxHp < 10 do
      local parsePattern = table.concat(table.map(cardsJudged, function(card)
        return card:getSuitString()
      end), ",")

      local judge = {
        who = from,
        reason = self.name,
        pattern = ".|.|" .. (parsePattern == "" and "." or "^(" .. parsePattern .. ")"),
        skipDrop = true,
      }
      room:judge(judge)

      table.insert(cardsJudged, judge.card)

      if
        not table.every(cardsJudged, function(card)
          return card == judge.card or judge.card:compareSuitWith(card, true)
        end) or
        not room:askForSkillInvoke(from, self.name, nil, "#mobile__god_huishi-ask")
      then
        break
      end

      room:changeMaxHp(from, 1)
    end

    local alivePlayerIds = table.map(room.alive_players, function(p)
      return p.id
    end)
    local targets = room:askForChoosePlayers(from, alivePlayerIds, 1, 1, "#mobile__god_huishi-give", self.name)
    if #targets > 0 then
      local to = targets[1]
      local pack = Fk:cloneCard("slash")
      pack:addSubcards(cardsJudged)
      room:obtainCard(to, pack, true, fk.ReasonGive)

      if
        table.every(room.alive_players, function(p)
          return p:getHandcardNum() <= room:getPlayerById(to):getHandcardNum()
        end)
      then
        room:changeMaxHp(from, -1)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["mobile__god_huishi"] = "慧识",
  [":mobile__god_huishi"] = "出牌阶段限一次，若你的体力上限小于10，你可以判定，若结果与本次流程中的其他判定结果均不同，且你的体力上限小于10，你可加1点体力上限并重复此流程。最后你将本次流程中所有生效的判定牌交给一名角色，若其手牌为全场最多，你减1点体力上限。",
  ["#mobile__god_huishi-ask"] = "慧识：你可以加1点体力上限并重复此流程",
  ["#mobile__god_huishi-give"] = "慧识：你可以将这些判定牌交给一名角色",
  ["$mobile__god_huishi1"] = "聪以知远，明以察微。",
  ["$mobile__god_huishi2"] = "见微知著，识人心智。",
}

godguojia:addSkill(godHuishi)

local tianyi = fk.CreateTriggerSkill{
  name = "mobile__tianyi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player.phase == Player.Start and
      player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryGame) < 1
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room.alive_players, function(p)
      return p:getMark("mobile__tianyi_damaged_count") > 0
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 2)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name,
    })

    local alivePlayerIds = table.map(room.alive_players, function(p)
      return p.id
    end)
    local target = room:askForChoosePlayers(player, alivePlayerIds, 1, 1, "#mobile__tianyi-choose", self.name, true)[1]
    room:handleAddLoseSkills(room:getPlayerById(target), "zuoxing")
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return data.to == player and player:getMark("mobile__tianyi_damaged_count") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "mobile__tianyi_damaged_count")
  end,
}
Fk:loadTranslationTable{
  ["mobile__tianyi"] = "天翊",
  [":mobile__tianyi"] = "觉醒技，准备阶段开始时，若所有存活角色于本局游戏内均受到过伤害，你加2点体力上限，回复1点体力，令一名角色获得技能“佐幸”。",
  ["#mobile__tianyi-choose"] = "天翊：请选择一名角色获得技能“佐幸”",
  ["$mobile__tianyi1"] = "天命靡常，惟德是辅。",
  ["$mobile__tianyi2"] = "可成吾志者，必此人也！",
}

godguojia:addSkill(tianyi)

local limitedHuishi = fk.CreateActiveSkill{
  name = "mobile__limited_huishi",
  anim_type = "support",
  frequency = Skill.Limited,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return true
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    
    local wakeSkills = {}
    if #room.alive_players <= from.maxHp then
      wakeSkills = table.map(table.filter(to.player_skills, function(s)
        return s.frequency == Skill.Wake and to:usedSkillTimes(s.name, Player.HistoryGame) < 1
      end), function(skill)
        return skill.name 
      end)
    end

    if #wakeSkills > 0 and from.maxHp >= #room.alive_players then
      local choice = room:askForChoice(from, wakeSkills, self.name, "#mobile__limited_huishi")
      local toWakeSkills = type(to:getMark("@mobile__limited_huishi")) == "table" and to:getMark("@mobile__limited_huishi") or {}
      table.insertIfNeed(toWakeSkills, choice)
      room:setPlayerMark(to, "@mobile__limited_huishi", toWakeSkills)

      toWakeSkills = type(to:getMark(MarkEnum.StraightToWake)) == "table" and to:getMark(MarkEnum.StraightToWake) or {}
      table.insertIfNeed(toWakeSkills, choice)
      room:setPlayerMark(to, MarkEnum.StraightToWake, toWakeSkills)
    else
      to:drawCards(4, self.name)
    end

    room:changeMaxHp(from, -2)
  end,
}
Fk:loadTranslationTable{
  ["mobile__limited_huishi"] = "辉逝",
  [":mobile__limited_huishi"] = "限定技，出牌阶段，你可以选择一名角色，若其有未发动过的觉醒技且你的体力上限不小于存活角色数，你选择其中一项技能，视为该角色满足其觉醒条件；否则其摸四张牌。最后你减2点体力上限。",
  ["@mobile__limited_huishi"] = "辉逝",
  ["$mobile__limited_huishi1"] = "丧家之犬，主公实不足虑也。",
  ["$mobile__limited_huishi2"] = "时事兼备，主公复有何忧？",
}

local limitedHuishiClear = fk.CreateTriggerSkill{
  name = "#mobile__limited_huishi-clear",
  refresh_events = {fk.BeforeTriggerSkillUse},
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.willUse and
      data.skill.frequency == Skill.Wake and
      type(player:getMark("@mobile__limited_huishi")) == "table" and
      table.contains(player:getMark("@mobile__limited_huishi"), data.skill.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room

    local toWakeSkills = player:getMark("@mobile__limited_huishi")
    table.removeOne(toWakeSkills, data.skill.name)
    room:setPlayerMark(player, "@mobile__limited_huishi", #toWakeSkills > 0 and toWakeSkills or 0)

    toWakeSkills = type(player:getMark(MarkEnum.StraightToWake)) == "table" and player:getMark(MarkEnum.StraightToWake) or {}
    table.removeOne(toWakeSkills, data.skill.name)
    room:setPlayerMark(player, MarkEnum.StraightToWake, #toWakeSkills > 0 and toWakeSkills or 0)
  end,
}
limitedHuishi:addRelatedSkill(limitedHuishiClear)

godguojia:addSkill(limitedHuishi)

local zuoxing = fk.CreateViewAsSkill{
  name = "zuoxing",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and card.skill.canUse(Self, card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox { choices = names }
  end,
  enabled_at_play = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p)
        return table.contains({ p.general, p.deputyGeneral }, "godguojia") and p.maxHp > 1
      end)
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local firstGodGuojia = table.find(room:getAlivePlayers(), function(p)
      return table.contains({ p.general, p.deputyGeneral }, "godguojia") and p.maxHp > 1
    end)

    if firstGodGuojia then
      room:changeMaxHp(firstGodGuojia, -1)
    end
  end,
}
Fk:loadTranslationTable{
  ["zuoxing"] = "佐幸",
  [":zuoxing"] = "出牌阶段限一次，若场上有存活且体力上限大于1的神郭嘉，你可以令其中于当前结算顺序上的第一个神郭嘉减1点体力上限，并视为使用一张普通锦囊牌。",
  ["$zuoxing1"] = "以聪虑难，悉咨于上。",
  ["$zuoxing2"] = "身计国谋，不可两遂。",
}

godguojia:addRelatedSkill(zuoxing)

local godxunyu = General(extension, "godxunyu", "god", 3)
Fk:loadTranslationTable{
  ["godxunyu"] = "神荀彧",
  ["~godguojia"] = "宁鸣而死，不默而生……",
}

local tianzuo = fk.CreateTriggerSkill{
  name = "tianzuo",
  anim_type = "defensive",
  events = {fk.GameStart, fk.PreCardEffect},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then
      return false
    end

    if event == fk.PreCardEffect then
      return data.to == player.id and data.card.name == "raid_and_frontal_attack"
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      for i = #room.void, 1, -1 do
        if Fk:getCardById(room.void[i]).name == "raid_and_frontal_attack" then
          local idRemoved = table.remove(room.void, i)
          print(idRemoved)
          table.insert(room.draw_pile, math.random(1, #room.draw_pile), idRemoved)
          room:setCardArea(idRemoved, Card.DrawPile, nil)
        end
      end

      room:doBroadcastNotify("UpdateDrawPile", #room.draw_pile)
    else
      return true
    end
  end,
}
Fk:loadTranslationTable{
  ["tianzuo"] = "天佐",
  [":tianzuo"] = "锁定技，游戏开始时，将8张【奇正相生】加入牌堆；【奇正相生】对你无效。",
  ["$tianzuo1"] = "此时进之多弊，守之多利，愿主公熟虑。",
  ["$tianzuo2"] = "主公若不时定，待四方生心，则无及矣。",
}

godxunyu:addSkill(tianzuo)

local zhinang = { "ex_nihilo", "dismantlement", "nullification" }

local lingce = fk.CreateTriggerSkill{
  name = "lingce",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(self.name) and
      not data.card:isVirtual() and
      (
        table.contains(zhinang, data.card.trueName) or
        table.contains(type(player:getMark("@$dinghan")) == "table" and player:getMark("@$dinghan") or {}, data.card.trueName) or
        data.card.trueName == "raid_and_frontal_attack"
      )
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
Fk:loadTranslationTable{
  ["lingce"] = "灵策",
  [":lingce"] = "锁定技，当非虚拟且非转化的锦囊牌被使用时，若此牌的牌名属于智囊牌名、“定汉”已记录的牌名或【奇正相生】时，你摸一张牌。",
  ["$lingce1"] = "绍士卒虽众，其实难用，必无为也。",
  ["$lingce2"] = "袁军不过一盘砂砾，主公用奇则散。",
}

godxunyu:addSkill(lingce)

local dinghan = fk.CreateTriggerSkill{
  name = "dinghan",
  anim_type = "defensive",
  events = {fk.TargetConfirming, fk.EventPhaseChanging},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(self.name) then
      return false
    end

    if event == fk.TargetConfirming then
      return
        data.card.type == Card.TypeTrick and
        data.card.name ~= "raid_and_frontal_attack" and
        not table.contains(type(player:getMark("@$dinghan")) == "table" and player:getMark("@$dinghan") or {}, data.card.trueName)
    else
      return data.from == Player.RoundStart
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseChanging then
      local room = player.room

      local dinghanRecord = type(player:getMark("@$dinghan")) == "table" and player:getMark("@$dinghan") or {}
      local allTricksName = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeTrick and not card.is_derived and not table.contains(dinghanRecord, card.trueName) then
          table.insertIfNeed(allTricksName, card.trueName)
        end
      end

      local choices = {"Cancel"}
      if #allTricksName > 0 then
        table.insert(choices, 1, "dinghan_addRecord")
      end
      if #dinghanRecord > 0 then
        table.insert(choices, 2, "dinghan_removeRecord")
      end
      local choice = room:askForChoice(player, choices, self.name)

      if choice == "Cancel" then
        return false
      end

      local cardName = room:askForChoice(player, choice == "dinghan_addRecord" and allTricksName or dinghanRecord, self.name)

      self.cost_data = { choice = choice, cardName = cardName }
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dinghanRecord = type(player:getMark("@$dinghan")) == "table" and player:getMark("@$dinghan") or {}
    if event == fk.TargetConfirming then
      table.insert(dinghanRecord, data.card.trueName)
      room:setPlayerMark(player, "@$dinghan", dinghanRecord)
      AimGroup:cancelTarget(data, player.id)
    else
      local costData = self.cost_data
      if costData.choice == "dinghan_addRecord" then
        table.insert(dinghanRecord, costData.cardName)
      else
        table.removeOne(dinghanRecord, costData.cardName)
      end
      room:setPlayerMark(player, "@$dinghan", #dinghanRecord > 0 and dinghanRecord or 0)
    end
  end,
}
Fk:loadTranslationTable{
  ["dinghan"] = "定汉",
  [":dinghan"] = "当你成为锦囊牌的目标时，若此牌牌名未被“定汉”记录，则“定汉”记录此牌名，然后取消此目标；回合开始时，你可以为“定汉”记录增加或移除一种锦囊牌的牌名。",
  ["@$dinghan"] = "定汉",
  ["dinghan_addRecord"] = "增加牌名",
  ["dinghan_removeRecord"] = "移除牌名",
  ["$dinghan1"] = "杀身有地，报国有时。",
  ["$dinghan2"] = "益国之事，虽死弗避。",
}

godxunyu:addSkill(dinghan)

return extension
