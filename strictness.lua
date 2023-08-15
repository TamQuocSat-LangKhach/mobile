local extension = Package("strictness")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["strictness"] = "手杀-始计篇·严",
}

---@param player ServerPlayer @ 发起整肃的玩家
---@param target ServerPlayer @ 执行整肃的玩家
---@param skillName string @ 技能名
---@param prompt string @ 提示信息
--发起整肃
local function StartZhengsu(player, target, skillName, prompt)
  skillName = skillName or ""
  prompt = prompt or ""
  local room = player.room
  local choices = {"zhengsu_leijin", "zhengsu_bianzhen", "zhengsu_mingzhi"}
  local choice = room:askForChoice(player, choices, skillName, prompt, true)
  local mark = target:getMark("@" .. choice .. "-turn")
  if mark == 0 then mark = {} end
  table.insertIfNeed(mark, skillName)
  room:setPlayerMark(target, "@" .. choice .. "-turn", mark)
  mark = target:getMark(choice .. "-turn")
  if mark == 0 then mark = {} end
  table.insertIfNeed(mark, player.id)
  room:setPlayerMark(target, choice .. "-turn", mark)
end

---@param player ServerPlayer @ 发起整肃的玩家
---@param target ServerPlayer @ 获得奖励的玩家
---@param reward string|null @ 指定要获得的奖励
---@param skillName string @ 技能名
---@param prompt string|null @ 提示信息
---@return string @ 返回获得的奖励类型（"draw2"|"recover"）
--获得整肃奖励
local function RewardZhengsu(player, target, reward, skillName, prompt)
  reward = reward or ""
  prompt = prompt or ""
  local room = player.room
  if reward == "" then
    local choices = {"draw2"}
    if target:isWounded() and not target.dead then
      table.insert(choices, 1, "recover")
    end
    reward = room:askForChoice(target, choices, skillName, prompt, false, {"draw2", "recover"})
  end
  if reward == "draw2" then
    room:drawCards(target, 2, skillName)
  elseif reward == "recover" then
    if target:isWounded() then
      room:recover({
        who = target,
        num = 1,
        recoverBy = target.id,
        skillName = skillName
      })
    end
  end
  return reward
end

--整肃记录技能
local mobileZhengsuTrigger = fk.CreateTriggerSkill{
  name = "mobile_zhengsu_trigger",
  global = true,

  refresh_events = {fk.CardUsing, fk.AfterCardsMove, fk.EventPhaseEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUsing and target == player and player.phase == Player.Play then
      return player:getMark("zhengsu_leijin-turn") ~= 0 or player:getMark("zhengsu_bianzhen-turn") ~= 0
    elseif event == fk.AfterCardsMove and player.phase == Player.Discard then
      return player:getMark("zhengsu_mingzhi-turn") ~= 0
    elseif event == fk.EventPhaseEnd and target == player and player.phase == Player.Discard then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      if player:getMark("zhengsu_leijin-turn") ~= 0 then
        local x = data.card.number
        if x > 0 then
          room:addPlayerMark(player, "zhengsu_leijin_times-turn")
          if player:getMark("zhengsu_point-turn") < x then
            room:setPlayerMark(player, "zhengsu_point-turn", x)
          else
            for _, skill in ipairs(player:getMark("@zhengsu_leijin-turn")) do
              room:broadcastSkillInvoke(skill, 3)
            end
            room:setPlayerMark(player, "zhengsu_leijin-turn", 0)
            room:setPlayerMark(player, "@zhengsu_leijin-turn", "zhengsu_failure")
          end
        end
      end
      if player:getMark("zhengsu_bianzhen-turn") ~= 0 then
        local suit = data.card:getSuitString()
        if suit ~= "nosuit" then
          room:addPlayerMark(player, "zhengsu_bianzhen_times-turn")
          if (player:getMark("zhengsu_suit-turn") == 0 or player:getMark("zhengsu_suit-turn") == suit) then
            room:setPlayerMark(player, "zhengsu_suit-turn", suit)
          else
            for _, skill in ipairs(player:getMark("@zhengsu_bianzhen-turn")) do
              room:broadcastSkillInvoke(skill, 3)
            end
            room:setPlayerMark(player, "zhengsu_bianzhen-turn", 0)
            room:setPlayerMark(player, "@zhengsu_bianzhen-turn", "zhengsu_failure")
          end
        end
      end
    elseif event == fk.AfterCardsMove then
      local discarded = type(player:getMark("zhengsu_mingzhi_discard-turn")) == "table" and player:getMark("zhengsu_mingzhi_discard-turn") or {}
      for _, move in ipairs(data) do
        if move.from == player.id and move.skillName == "game_rule" then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insert(discarded, info.cardId)
            end
          end
        end
      end
      room:setPlayerMark(player, "zhengsu_mingzhi_discard-turn", discarded)
    elseif event == fk.EventPhaseEnd then
      if player:getMark("zhengsu_leijin-turn") ~= 0 and player:getMark("zhengsu_leijin_times-turn") < 3 then
        for _, skill in ipairs(player:getMark("@zhengsu_leijin-turn")) do
          room:broadcastSkillInvoke(skill, 3)
        end
        room:setPlayerMark(player, "zhengsu_leijin-turn", 0)
        room:setPlayerMark(player, "@zhengsu_leijin-turn", "zhengsu_failure")
      end
      if player:getMark("zhengsu_bianzhen-turn") ~= 0 and player:getMark("zhengsu_bianzhen_times-turn") < 2 then
        for _, skill in ipairs(player:getMark("@zhengsu_bianzhen-turn")) do
          room:broadcastSkillInvoke(skill, 3)
        end
        room:setPlayerMark(player, "zhengsu_bianzhen-turn", 0)
        room:setPlayerMark(player, "@zhengsu_bianzhen-turn", "zhengsu_failure")
      end
      if player:getMark("zhengsu_mingzhi-turn") ~= 0 then
        local discarded = player:getMark("zhengsu_mingzhi_discard-turn")
        if type(discarded) == "table" and #discarded > 1 then
          local suits = {}
          for _, id in ipairs(discarded) do
            if Fk:getCardById(id).suit ~= Card.NoSuit then
              table.insertIfNeed(suits, Fk:getCardById(id).suit)
            end
          end
          if #suits < #discarded then
            for _, skill in ipairs(player:getMark("@zhengsu_mingzhi-turn")) do
              room:broadcastSkillInvoke(skill, 3)
            end
            room:setPlayerMark(player, "zhengsu_mingzhi-turn", 0)
            room:setPlayerMark(player, "@zhengsu_mingzhi-turn", "zhengsu_failure")
          end
        else
          for _, skill in ipairs(player:getMark("@zhengsu_mingzhi-turn")) do
            room:broadcastSkillInvoke(skill, 3)
          end
          room:setPlayerMark(player, "zhengsu_mingzhi-turn", 0)
          room:setPlayerMark(player, "@zhengsu_mingzhi-turn", "zhengsu_failure")
        end
      end
    end
  end,
}
Fk:addSkill(mobileZhengsuTrigger)
Fk:loadTranslationTable{
  ["zhengsu_leijin"] = "擂进",
  ["@zhengsu_leijin-turn"] = "擂进",
  [":zhengsu_leijin"] = "出牌阶段内，至少使用3张牌，使用牌点数递增",
  ["zhengsu_bianzhen"] = "变阵",
  ["@zhengsu_bianzhen-turn"] = "变阵",
  [":zhengsu_bianzhen"] = "出牌阶段内，至少使用2张牌，使用牌花色相同",
  ["zhengsu_mingzhi"] = "鸣止",
  ["@zhengsu_mingzhi-turn"] = "鸣止",
  [":zhengsu_mingzhi"] = "弃牌阶段内，至少弃置2张牌，弃置牌花色均不同",
  ["zhengsu_failure"] = "失败",
}

local zhangchangpu = General(extension, "mobile__zhangchangpu", "wei", 3, 3, General.Female)
local difei = fk.CreateTriggerSkill{
  name = "difei",
  anim_type = "masochism",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player == target and player:usedSkillTimes(self.name) < 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#difei-discard"
    if data.card then
      if data.card.suit == Card.NoSuit then
        prompt = prompt .. "-recover1"
      else
        prompt = prompt .. "-recover2:::" .. data.card:getSuitString(true)
      end
    end
    local card = room:askForDiscard(player, 1, 1, false, self.name, true, ".", prompt)
    if #card == 0 then
      room:drawCards(player, 1, self.name)
    end
    if player:isKongcheng() then return false end
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)

    if player:isWounded() and data.card then
      local suit = data.card.suit
      if suit ~= Card.NoSuit then
        for _, id in ipairs(cards) do
          if Fk:getCardById(id).suit == suit then
            return false
          end
        end
      end
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local mobile__yanjiao = fk.CreateActiveSkill{
  name = "mobile__yanjiao",
  anim_type = "offensive",
  prompt = "#mobile__yanjiao-active",
  interaction = function(self)
    local choiceList = {}
    local cards = Self.player_cards[Player.Hand]
    for _, id in ipairs(cards) do
      table.insertIfNeed(choiceList, Fk:getCardById(id):getSuitString(true))
    end
    if #choiceList == 0 then return false end
    return UI.ComboBox { choices = choiceList, all_choices = {"log_spade", "log_heart", "log_club", "log_diamond"} }
  end,
  max_card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function() return false end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suit = self.interaction.data
    local handcards = player.player_cards[Player.Hand]
    local cards = table.filter(handcards, function (id)
      return Fk:getCardById(id):getSuitString(true) == suit
    end)
    if #cards == 0 then return false end
    room:addPlayerMark(player, "@mobile__yanjiao", #cards)
    local dummy = Fk:cloneCard'slash'
    dummy:addSubcards(cards)
    room:obtainCard(target.id, dummy, false, fk.ReasonGive)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local mobile__yanjiao_delay = fk.CreateTriggerSkill{
  name = "#mobile__yanjiao_delay",
  anim_type = "control",
  events = {fk.EventPhaseChanging},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to == Player.Start and not player.dead and player:getMark("@mobile__yanjiao") > 0
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getMark("@mobile__yanjiao")
    room:setPlayerMark(player, "@mobile__yanjiao", 0)
    room:drawCards(player, x, mobile__yanjiao.name)
  end,
}
mobile__yanjiao:addRelatedSkill(mobile__yanjiao_delay)
zhangchangpu:addSkill(difei)
zhangchangpu:addSkill(mobile__yanjiao)
Fk:loadTranslationTable{
  ["mobile__zhangchangpu"] = "张昌蒲",
  ["difei"] = "抵诽",
  [":difei"] = "锁定技，每回合限一次，当你受到伤害后，你摸一张牌或弃置一张手牌，然后你展示所有手牌，若对你造成伤害的牌无花色或"..
  "你的手牌中没有与对你造成伤害的牌花色相同的牌，你回复1点体力。",
  ["mobile__yanjiao"] = "严教",
  [":mobile__yanjiao"] = "出牌阶段限一次，你可以将手牌中某种花色的所有牌（至少一张）交给一名其他角色，然后对其造成1点伤害，若如此做，"..
  "你的下个回合开始时，你摸X张牌（X为你以此法给出的牌数）。",
  ["#difei-discard"] = "抵诽：你可选择一张手牌弃置，或点取消则摸一张牌",
  ["#difei-discard-recover1"] = "抵诽：你可选择一张手牌弃置，或点取消则摸一张牌，然后展示所有手牌并回复1点体力",
  ["#difei-discard-recover2"] = "抵诽：你可选择一张手牌弃置，或点取消则摸一张牌，然后展示所有手牌，若其中没有%arg牌则回复1点体力",
  ["#mobile__yanjiao-active"] = "严教：选择一种花色和一名其他角色，将手牌中所有该花色的牌交给该角色并对其造成1点伤害",
  ["@mobile__yanjiao"] = "严教",

  ["$difei1"] = "称病不见，待其自露马脚。",
  ["$difei2"] = "孙氏之诽，伤不到我分毫。",
  ["$mobile__yanjiao1"] = "此篇未记，会儿便不可嬉戏。",
  ["$mobile__yanjiao2"] = "母亲虽严，却皆为汝好。",
  ["~mobile__zhangchangpu"] = "钟氏门楣，待我儿光耀……",
}

local cuiyan = General(extension, "mobile__cuiyan", "wei", 3)
local yajun = fk.CreateTriggerSkill{
  name = "yajun",
  anim_type = "control",
  events = {fk.DrawNCards, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.DrawNCards then
        return true
      else
        return player.phase == Player.Play and not player:isKongcheng() and
          table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DrawNCards then
      return true
    else
      local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() end), function(p) return p.id end),
        1, 1, "#yajun-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DrawNCards then
      data.n = data.n + 1
    else
      local to = room:getPlayerById(self.cost_data)
      local pindian = player:pindian({to}, self.name)
      if pindian.results[to.id].winner == player then
        local ids = {}
        if room:getCardArea(pindian.fromCard) == Card.DiscardPile then
          table.insertIfNeed(ids, pindian.fromCard:getEffectiveId())
        end
        if room:getCardArea(pindian.results[to.id].toCard) == Card.DiscardPile then
          table.insertIfNeed(ids, pindian.results[to.id].toCard:getEffectiveId())
        end
        if #ids == 0 then return end
        local result = room:askForGuanxing(player, ids, {0, 1}, {}, self.name, true, {"yajun_top", "DiscardPile"})
        if #result.top == 1 then
          room:moveCards({
            ids = result.top,
            fromArea = Card.DiscardPile,
            toArea = Card.DrawPile,
            moveReason = fk.ReasonJustMove,
            skillName = self.name,
          })
        end
      else
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    end
  end,
}
local zundi = fk.CreateActiveSkill{
  name = "zundi",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#zundi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if target.dead then return end
    if judge.card.color == Card.Black then
      target:drawCards(3, self.name)
    elseif judge.card.color == Card.Red and #room:canMoveCardInBoard() > 0 then
      local targets = room:askForChooseToMoveCardInBoard(target, "#zundi-move", self.name, true)
      if #targets > 1 then
        targets = table.map(targets, function(id) return room:getPlayerById(id) end)
        room:askForMoveCardInBoard(player, targets[1], targets[2], self.name)
      end
    end
  end,
}
cuiyan:addSkill(yajun)
cuiyan:addSkill(zundi)
Fk:loadTranslationTable{
  ["mobile__cuiyan"] = "崔琰",
  ["yajun"] = "雅俊",
  [":yajun"] = "摸牌阶段，你多摸一张牌。出牌阶段开始时，你可以与一名角色拼点：若你赢，你可以将其中一张拼点牌置于牌堆顶；"..
  "若你没赢，你本回合的手牌上限-1。",
  ["zundi"] = "尊嫡",
  [":zundi"] = "出牌阶段限一次，你可以弃置一张手牌并选择一名角色，然后你进行判定，若结果为：黑色，其摸三张牌；红色，其可以移动场上一张牌。",
  ["#yajun-choose"] = "雅俊：你可以拼点，若赢，可以将一张拼点牌置于牌堆顶，若没赢，本回合手牌上限-1",
  ["#zundi"] = "尊嫡：弃置一张手牌指定一名角色，你判定，黑色其摸三张牌，红色则其可以移动场上一张牌",
  ["yajun_top"] = "置于牌堆顶",
  ["#zundi-move"] = "尊嫡：你可以移动场上一张牌",
}

local jiangwan = General(extension, "jiangwan", "shu", 3)
local zhenting = fk.CreateTriggerSkill{
  name = "zhenting",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.from and data.from ~= player.id and data.firstTarget and
      (data.card.trueName == "slash" or data.card.sub_type == Card.SubtypeDelayedTrick) and
      not table.contains(AimGroup:getAllTargets(data.tos), player.id) and player:inMyAttackRange(target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhenting-invoke::"..target.id..":"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    TargetGroup:removeTarget(data.targetGroup, target.id)
    TargetGroup:pushTargets(data.targetGroup, player.id)
    local choices = {"draw1"}
    local to = room:getPlayerById(data.from)
    if not to.dead and not to:isNude() then
      table.insert(choices, 1, "zhenting_discard")
    end
    local choice = room:askForChoice(player, choices, self.name, "#zhenting-choice::"..data.from)
    if choice == "zhenting_discard" then
      local id = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard({id}, self.name, to, player)
    else
      player:drawCards(1, self.name)
    end
  end,
}
local mobile__jincui = fk.CreateActiveSkill{
  name = "mobile__jincui",
  anim_type = "special",
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__jincui",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = math.min(math.abs(player.seat - target.seat), player.hp)
    room:swapSeat(player, target)
    room:loseHp(player, n, self.name)
  end,
}
jiangwan:addSkill(zhenting)
jiangwan:addSkill(mobile__jincui)
Fk:loadTranslationTable{
  ["jiangwan"] = "蒋琬",
  ["zhenting"] = "镇庭",
  [":zhenting"] = "每回合限一次，当你攻击范围内的一名角色成为【杀】或延时锦囊牌的目标时，若你不为此牌的使用者或目标，"..
  "你可以代替其成为此牌的目标，然后选择一项：1.弃置此牌使用者的一张牌；2.摸一张牌。",
  ["mobile__jincui"] = "尽瘁",
  [":mobile__jincui"] = "限定技，出牌阶段，你可以与一名其他角色交换座次，然后你失去X点体力（X为你与其座次的距离且至多为你的体力值）。",
  ["#zhenting-invoke"] = "镇庭：你可以将对 %dest 使用的%arg转移给你，然后你弃置使用者一张牌或摸一张牌",
  ["zhenting_discard"] = "弃置其一张牌",
  ["#zhenting-choice"] = "镇庭：选择对 %dest 执行的一项",
  ["#mobile__jincui"] = "尽瘁：你可以与一名角色交换座次，然后失去体力！",
}

local liuba = General(extension, "mobile__liuba", "shu", 3)
local duanbi = fk.CreateActiveSkill{
  name = "duanbi",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = "#duanbi",
  frequency = Skill.Limited,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        n = n + p:getHandcardNum()
      end
      return n > 2 * #Fk:currentRoom().alive_players
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local ids = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and not p:isKongcheng() then
        local n = math.min(3, (p:getHandcardNum() + 1) // 2)
        local cards = room:askForDiscard(p, n, n, false, self.name, false)
        table.insertTableIfNeed(ids, cards)
      end
    end
    if player.dead then return end
    ids = table.filter(ids, function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #ids > 0 then
      local fakemove = {
        toArea = Card.PlayerHand,
        to = player.id,
        moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
      room:setPlayerMark(player, self.name, ids)
      room:askForUseActiveSkill(player, "duanbi_active", "#duanbi-give", true)
      room:setPlayerMark(player, self.name, 0)
      ids = table.filter(ids, function(id) return room:getCardArea(id) ~= Card.PlayerHand end)
      fakemove = {
        from = player.id,
        toArea = Card.Void,
        moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
        moveReason = fk.ReasonJustMove,
      }
      room:notifyMoveCards({player}, {fakemove})
    end
  end,
}
local duanbi_active = fk.CreateActiveSkill{
  name = "duanbi_active",
  mute = true,
  min_card_num = 1,
  max_card_num = 3,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return #selected < 3 and Self:getMark("duanbi") ~= 0 and table.contains(Self:getMark("duanbi"), to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:doIndicate(player.id, {target.id})
    local fakemove = {
      from = player.id,
      toArea = Card.Void,
      moveInfo = table.map(effect.cards, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonGive,
    }
    room:notifyMoveCards({player}, {fakemove})
    room:moveCards({
      fromArea = Card.Void,
      ids = effect.cards,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      skillName = self.name,
    })
  end,
}
local mobile__tongdu = fk.CreateTriggerSkill{
  name = "mobile__tongdu",
  anim_type = "support",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and data.from ~= player.id and data.firstTarget and
      #AimGroup:getAllTargets(data.tos) == 1 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      table.find(player.room.alive_players, function(p) return not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room.alive_players, function(p)
      return not p:isNude() end), function(p) return p.id end),
      1, 1, "#mobile__tongdu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local cards = room:askForCard(to, 1, 1, true, self.name, false, ".", "#mobile__tongdu-card:"..player.id)
    local card = Fk:getCardById(cards[1])
    room:moveCards({
      ids = cards,
      from = to.id,
      toArea = Card.DiscardPile,
      skillName = self.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = to.id
    })
    room:sendLog{
      type = "#RecastBySkill",
      from = to.id,
      card = cards,
      arg = self.name,
    }
    if card.suit == Card.Heart or card.type == Card.TypeTrick then
      to:drawCards(2, self.name)
    else
      to:drawCards(1, self.name)
    end
    if card.trueName == "ex_nihilo" and player:usedSkillTimes("duanbi", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("duanbi", 0, Player.HistoryGame)
    end
  end,
}
Fk:addSkill(duanbi_active)
liuba:addSkill(duanbi)
liuba:addSkill(mobile__tongdu)
Fk:loadTranslationTable{
  ["mobile__liuba"] = "刘巴",
  ["duanbi"] = "锻币",
  [":duanbi"] = "限定技，出牌阶段，若所有角色的手牌数之和大于存活角色数的两倍，你可以令所有其他角色弃置X张手牌（X为其手牌数的一半，向上取整且至多为3），"..
  "然后你将以此法弃置的三张牌交给一名角色。",
  ["mobile__tongdu"] = "统度",
  [":mobile__tongdu"] = "每回合限一次，当你成为其他角色使用牌的唯一目标时，你可以令一名角色重铸一张牌，若此牌为：<font color='red'>♥</font>牌或锦囊牌，"..
  "其多摸一张牌；【无中生有】，你重置〖锻币〗。",
  ["#duanbi"] = "锻币：令其他角色各弃置一半手牌（向上取整），然后你将其中三张牌交给一名角色！",
  ["duanbi_active"] = "锻币",
  ["#duanbi-give"] = "锻币：你可以将其中至多三张牌交给一名角色",
  ["#mobile__tongdu-choose"] = "统度：你可以令一名角色重铸一张牌，根据类别获得额外效果",
  ["#mobile__tongdu-card"] = "统度：重铸一张牌，若为<font color='red'>♥</font>牌或锦囊牌则额外摸一张，若为【无中生有】则 %src 重置〖锻币〗",
}

local lvfan = General(extension, "mobile__lvfan", "wu", 3)
local mobile__diaodu = fk.CreateTriggerSkill{
  name = "mobile__diaodu",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and #player.room:canMoveCardInBoard() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChooseToMoveCardInBoard(player, "#mobile__diaodu-move", self.name, true, "e")
    if #tos > 1 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(self.cost_data, function(id) return room:getPlayerById(id) end)
    local result = room:askForMoveCardInBoard(player, targets[1], targets[2], self.name, "e")
    local from = room:getPlayerById(result.from)
    if not from.dead then
      from:drawCards(1, self.name)
    end
  end,
}
local mobile__diancai = fk.CreateTriggerSkill{
  name = "mobile__diancai",
  events = {fk.EventPhaseEnd},
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and target.phase == Player.Play and player:getHandcardNum() < player.maxHp and
      player:getMark("@mobile__diancai-phase") >= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__diancai-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true) and player.phase == Player.NotActive and
      player.room.current and player.room.current.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            player.room:addPlayerMark(player, "@mobile__diancai-phase", 1)
          end
        end
      end
    end
  end,
}
local yanji = fk.CreateTriggerSkill{
  name = "yanji",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self.name) and player.phase == Player.Play
      else
        return player.phase == Player.Discard and not player.dead and
        table.find({"zhengsu_leijin-turn", "zhengsu_bianzhen-turn", "zhengsu_mingzhi-turn"}, function(name)
          return player:getMark(name) ~= 0 and table.contains(player:getMark(name), player.id) end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#yanji-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      StartZhengsu(player, player, self.name, "#yanji-choice")
    else
      RewardZhengsu(player, player, "", self.name, "#yanji-reward")
    end
  end,
}
lvfan:addSkill(mobile__diaodu)
lvfan:addSkill(mobile__diancai)
lvfan:addSkill(yanji)
Fk:loadTranslationTable{
  ["mobile__lvfan"] = "吕范",
  ["mobile__diaodu"] = "调度",
  [":mobile__diaodu"] = "准备阶段，你可以移动场上的一张装备牌，然后以此法失去牌的角色摸一张牌。",
  ["mobile__diancai"] = "典财",
  [":mobile__diancai"] = "其他角色的出牌阶段结束时，若你于此阶段失去了至少X张牌（X为你的体力值），则你可以将手牌摸至体力上限。",
  ["yanji"] = "严纪",
  [":yanji"] = "出牌阶段开始时，你可以进行“整肃”。"..
  "<br/><font color='grey'>#\"<b>整肃</b>\"<br/>"..
  "技能发动者从擂进、变阵、鸣止中选择一项令目标执行，若本回合“整肃”成功，则弃牌阶段结束后获得“整肃奖励”。<br/>"..
  "<b>擂进：</b>出牌阶段内，使用的所有牌点数需递增，且至少使用三张牌。<br/>"..
  "<b>变阵：</b>出牌阶段内，使用的所有牌花色需相同，且至少使用两张牌。<br/>"..
  "<b>鸣止：</b>弃牌阶段内，弃置的所有牌花色均不同，且至少弃置两张牌。<br/>"..
  "<b>整肃奖励：</b>选择一项：1.摸两张牌；2.回复1点体力。",
  ["#mobile__diaodu-move"] = "调度：你可以移动场上一张装备牌，失去牌的角色摸一张牌",
  ["@mobile__diancai-phase"] = "典财",
  ["#mobile__diancai-invoke"] = "典财：你可以将手牌摸至体力上限",
  ["#yanji-invoke"] = "严纪：你可以进行“整肃”，若成功，则弃牌阶段结束后获得奖励",
  ["#yanji-choice"] = "严纪：选择你本回合“整肃”的条件",
  ["#yanji-reward"] = "严纪：“整肃”成功，选择一项整肃奖励",
}

Fk:loadTranslationTable{
  ["mobile__huangfusong"] = "皇甫嵩",
  ["hfs__taoluan"] = "讨乱",
  [":hfs__taoluan"] = "每回合限一次，当判定牌生效时，若判定结果为♠，你可以终止此次判定，然后选择：1.你获得此判定牌；"..
  "2.若进行判定的角色不是你，你视为对其使用一张无距离和次数限制的火【杀】。",
  ["shiji"] = "势击",
  [":shiji"] = "你对其他角色造成属性伤害时，若你的手牌数不为全场唯一最多，你可以查看其手牌并弃置其中所有的红色牌，然后你摸等量的牌。",
  ["zhengjun"] = "整军",
  [":zhengjun"] = "出牌阶段开始时，你可以进行“整肃”，若如此做，弃牌阶段结束后，若你“整肃”未失败，你获得“整肃”奖励，并可以令一名其他角色也获得“整肃”奖励。",

  ["$hfs__taoluan1"] = "乱民桀逆，非威不服！",
  ["$hfs__taoluan2"] = "欲定黄巾，必赖兵革之利！",
  ["$shiji1"] = "敌军依草结营，正犯兵家大忌！",
  ["$shiji2"] = "兵法所云火攻之计，正合此时之势！",
  ["$zhengjun1"] = "众将平日随心，战则务尽死力！",
  ["$zhengjun2"] = "汝等不怀余力，皆有平贼之功！",
  ["$zhengjun3"] = "仁恕之道，终非治军良策！",
  ["~mobile__huangfusong"] = "力有所能，臣必为也……",
}

local zhujun = General(extension, "mobile__zhujun", "qun", 4)
local yangjie = fk.CreateActiveSkill{
  name = "yangjie",
  anim_type = "offensive",
  prompt = "#yangjie-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner ~= player and not player.dead and not target.dead then
      local slash = Fk:cloneCard("fire__slash")
      slash.skillName = self.name
      local targets = table.filter(room.alive_players, function (p)
        return not (p == player or p == target or p:prohibitUse(slash) or p:isProhibited(target, slash))
      end)
      if #targets == 0 then return false end
      local tos = room:askForChoosePlayers(player, table.map(targets, function (p)
        return p.id end), 1, 1, "#yangjie-choose::" .. effect.tos[1], self.name, true, true)
       if #tos > 0 then
        room:useCard({
          from = tos[1],
          tos = {effect.tos},
          card = slash,
        })
       end
    end
  end,
}
local zj__juxiang = fk.CreateTriggerSkill{
  name = "zj__juxiang",
  anim_type = "offensive",
  frequency = Skill.Limited,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self.name) and not target.dead and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zj__juxiang-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player.room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = self.name,
    }
  end,
}
local houfeng = fk.CreateTriggerSkill{
  name = "houfeng",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
    target.phase == Player.Play and not target.dead and player:inMyAttackRange(target)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#houfeng-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    room:broadcastSkillInvoke(self.name, 1)
    room:doIndicate(player.id, {target.id})
    StartZhengsu(player, target, self.name, "#houfeng-choice::"..target.id)
    room:setPlayerMark(player, "@houfeng-turn", target.general)
  end,
}
local houfeng_delay = fk.CreateTriggerSkill{
  name = "#houfeng_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Discard and not target.dead and not player.dead and
    table.find({"zhengsu_leijin-turn", "zhengsu_bianzhen-turn", "zhengsu_mingzhi-turn"}, function(name)
      return target:getMark(name) ~= 0 and table.contains(target:getMark(name), player.id) end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "houfeng")
    room:broadcastSkillInvoke("houfeng", 2)
    local reward = RewardZhengsu(player, target, "", "houfeng", "#houfeng-reward:"..player.id)
    if not player.dead then
      RewardZhengsu(player, player, reward, "houfeng")
    end
  end,
}
houfeng:addRelatedSkill(houfeng_delay)
zhujun:addSkill(yangjie)
zhujun:addSkill(zj__juxiang)
zhujun:addSkill(houfeng)
Fk:loadTranslationTable{
  ["mobile__zhujun"] = "朱儁",
  ["yangjie"] = "佯解",
  [":yangjie"] = "出牌阶段限一次，你可以与一名角色拼点。若你没赢，你可以令另一名其他角色视为对与你拼点的角色使用一张无距离限制的火【杀】。",
  ["houfeng"] = "厚俸",
  [":houfeng"] = "每轮限一次，你攻击范围内一名角色出牌阶段开始时，你可以令其“整肃”；你与其共同获得“整肃”奖励。"..
  "<br/><font color='grey'>#\"<b>整肃</b>\"<br/>"..
  "技能发动者从擂进、变阵、鸣止中选择一项令目标执行，若本回合“整肃”成功，则弃牌阶段结束后获得“整肃奖励”。<br/>"..
  "<b>擂进：</b>出牌阶段内，使用的所有牌点数需递增且至少使用三张牌。<br/>"..
  "<b>变阵：</b>出牌阶段内，使用的所有牌花色需相同且至少使用两张牌。<br/>"..
  "<b>鸣止：</b>弃牌阶段内，弃置的所有牌花色均不同且至少弃置两张牌。<br/>"..
  "<b>整肃奖励：</b>摸两张牌或回复1点体力。",
  ["zj__juxiang"] = "拒降",
  [":zj__juxiang"] = "限定技，当一名其他角色的濒死结算结束后，你可对其造成1点伤害。",
  ["#yangjie-active"] = "佯解：你可以拼点，若没赢，你可以令另一名角色视为对拼点角色使用火【杀】",
  ["#yangjie-choose"] = "佯解：你可以选择一名角色，视为其对%dest使用火【杀】",
  ["#houfeng_delay"] = "厚俸",
  ["#houfeng-invoke"] = "厚俸：你可令 %dest 整肃，若未失败则获得整肃奖励",
  ["@houfeng-turn"] = "厚俸",
  ["#houfeng-choice"] = "厚俸：为 %dest 选择一项整肃条件",
  ["#houfeng-reward"] = "厚俸：整肃未失败，你与 %src 共同执行整肃奖励",
  ["#zj__juxiang-invoke"] = "拒降：你可以对 %dest 造成1点伤害！",

  ["$yangjie1"] = "全军彻围，待其出城迎敌，再攻敌自散矣！",
  ["$yangjie2"] = "佯解敌围，而后城外击之，此为易破之道！",
  ["$houfeng1"] = "交汝统领，勿负我望！",
  ["$houfeng2"] = "有功自当行赏，来人呈上！",
  ["$houfeng3"] = "叉出去！罚其二十军杖！",
  ["$zj__juxiang1"] = "今非秦项之际，如若受之，徒增逆意！",
  ["$zj__juxiang2"] = "兵有形同而势异者，此次乞降断不可受！",
  ["~mobile__zhujun"] = "郭汜小竖！气煞我也！嗯……",
}

return extension
