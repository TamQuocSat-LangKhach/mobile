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
---@param reward string|null @ 要获得的奖励（"draw2"|"recover"）
---@param skillName string @ 技能名
--获得整肃奖励
local function RewardZhengsu(player, target, reward, skillName)
  reward = reward or "draw2"
  local room = player.room
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
              player:broadcastSkillInvoke(skill, 3)
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
              player:broadcastSkillInvoke(skill, 3)
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
          player:broadcastSkillInvoke(skill, 3)
        end
        room:setPlayerMark(player, "zhengsu_leijin-turn", 0)
        room:setPlayerMark(player, "@zhengsu_leijin-turn", "zhengsu_failure")
      end
      if player:getMark("zhengsu_bianzhen-turn") ~= 0 and player:getMark("zhengsu_bianzhen_times-turn") < 2 then
        for _, skill in ipairs(player:getMark("@zhengsu_bianzhen-turn")) do
          player:broadcastSkillInvoke(skill, 3)
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
              player:broadcastSkillInvoke(skill, 3)
            end
            room:setPlayerMark(player, "zhengsu_mingzhi-turn", 0)
            room:setPlayerMark(player, "@zhengsu_mingzhi-turn", "zhengsu_failure")
          end
        else
          for _, skill in ipairs(player:getMark("@zhengsu_mingzhi-turn")) do
            player:broadcastSkillInvoke(skill, 3)
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

  ["$yajun1"] = "君子如珩，缨绂有容！",
  ["$yajun2"] = "仁声未闻，岂可先计后兵！",
  ["$zundi1"] = "盖闻春秋之义，立子自当立长。",
  ["$zundi2"] = "五官将才德兼备，是以宜承正统。",
  ["~mobile__cuiyan"] = "生当如君子，死当追竹德……",
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

  ["$zhenting1"] = "今政事在我，更要持重慎行！",
  ["$zhenting2"] = "国可因外敌而亡，不可因内政而损！",
  ["$mobile__jincui1"] = "伐魏虽俯仰惟艰，臣甘愿效死于前！",
  ["$mobile__jincui2"] = "臣敢竭股肱之力，誓死为陛下前驱！",
  ["~jiangwan"] = "臣即将一死，辅国之事文伟可继……",
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

  ["$duanbi1"] = "收缴故币，以旧铸新，使民有余财。",
  ["$duanbi2"] = "今，若能统一蜀地币制，则利在千秋。",
  ["$mobile__tongdu1"] = "辎重调拨，乃国之要务，岂可儿戏！",
  ["$mobile__tongdu2"] = "府库充盈，民有余财，主公师出有名矣。",
  ["~mobile__liuba"] = "孔明，大汉的重担，就全系于你一人之身了……",
}

local jiangqin = General(extension, "mobile__jiangqin", "wu", 4)
local jianyi = fk.CreateTriggerSkill{
  name = "jianyi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) then
      local events =  player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
             return Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor and player.room:getCardArea(info.cardId) == Card.DiscardPile
            end
          end
        end
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
           if Fk:getCardById(info.cardId).sub_type == Card.SubtypeArmor and player.room:getCardArea(info.cardId) == Card.DiscardPile then
            table.insertIfNeed(ids, info.cardId)
           end
          end
        end
      end
    end, Player.HistoryTurn)
    if #ids == 0 then return end
    local get = room:askForCardsChosen(player, player, 1, 1, {card_data = {{self.name, ids}}}, self.name)
    if #get > 0 then
      room:moveCards({
        ids = get,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local mobile__shangyi = fk.CreateActiveSkill{
  name = "mobile__shangyi",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#mobile__shangyi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select)) then
      if Fk:currentRoom():getCardArea(to_select) == Player.Hand then
        return Self:getHandcardNum() > 1
      else
        return true
      end
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead or target.dead or player:isKongcheng() or target:isKongcheng() then return end
    room:fillAG(target, player:getCardIds("h"))
    room:delay(3000)
    room:closeAG(target)
    local cards = table.simpleClone(target:getCardIds("h"))
    room:fillAG(player, cards)
    local id = room:askForAG(player, cards, false, self.name)
    room:closeAG(player)
    room:obtainCard(player, id, false, fk.ReasonPrey)
  end,
}
jiangqin:addSkill(jianyi)
jiangqin:addSkill(mobile__shangyi)
Fk:loadTranslationTable{
  ["mobile__jiangqin"] = "蒋钦",
  ["jianyi"] = "俭衣",
  [":jianyi"] = "锁定技，其他角色回合结束时，若弃牌堆中有本回合弃置的防具牌，则你选择其中一张获得。",
  ["mobile__shangyi"] = "尚义",
  [":mobile__shangyi"] = "出牌阶段限一次，你可以弃置一张牌并令一名有手牌的其他角色观看你的手牌，然后你观看其手牌并获得其中一张牌。",
  ["#mobile__shangyi"] = "尚义：弃置一张牌令一名角色观看你的手牌，然后你观看其手牌并获得其中一张牌",

  ["$jianyi1"] = "今虽富贵，亦不可浪费。",
  ["$jianyi2"] = "缩衣克俭，才是兴家之道。",
  ["$mobile__shangyi1"] = "国士，当以义为先！",
  ["$mobile__shangyi2"] = "豪侠尚义，何拘俗礼！",
  ["~mobile__jiangqin"] = "奋敌护主，成吾忠名……",
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
        player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and
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
      local choices = {"draw2"}
      if player:isWounded() then
        table.insert(choices, 1, "recover")
      end
      local reward = player.room:askForChoice(player, choices, self.name, "#yanji-reward", false, {"draw2", "recover"})
      RewardZhengsu(player, player, reward, self.name)
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

  ["$mobile__diaodu1"] = "三军器用，攻守之具，皆有法也！",
  ["$mobile__diaodu2"] = "士各执其器，乃陷坚陈，败强敌！",
  ["$mobile__diancai1"] = "资财当为公，不可为私也！",
  ["$mobile__diancai2"] = "财用于公则政明，而后民附也！",
  ["$yanji1"] = "范既典主财计，必律己以率之！",
  ["$yanji2"] = "有财贵于善用，须置军资以崇国防！",
  ["$yanji3"] = "公帑私用？待吾查清定要严惩！",
  ["~mobile__lvfan"] = "此病来势汹汹，恕臣无力侍奉……",
}

local huangfusong = General(extension, "mobile__huangfusong", "qun", 4)
local taoluanh = fk.CreateTriggerSkill{
  name = "taoluanh",
  anim_type = "control",
  priority = 1.1,
  events = {fk.FinishJudge},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.card.suit == Card.Spade and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"Cancel"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "taoluanh_prey")
    end
    if target ~= player then
      table.insert(choices, "taoluanh_slash")
    end
    local choice = room:askForChoice(player, choices, self.name, "#taoluanh-invoke::"..target.id)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local e = room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
    if e then
      room.logic:getCurrentEvent():addExitFunc(function()
        e:shutdown()
      end)
    end
    if self.cost_data == "taoluanh_prey" then
      room:doIndicate(player.id, {target.id})
      room:obtainCard(player, data.card, true, fk.ReasonPrey)
    else
      room:useVirtualCard("fire__slash", nil, player, target, self.name, true)
    end
  end,
}
local shiji = fk.CreateTriggerSkill{
  name = "shiji",
  anim_type = "control",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to ~= player and data.damageType ~= fk.NormalDamage and
      not data.to:isKongcheng() and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:getHandcardNum() >= player:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#shiji-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.to.id})
    room:fillAG(player, data.to:getCardIds("h"))
    room:delay(3000)
    room:closeAG(player)
    local ids = {}
    for _, id in ipairs(data.to:getCardIds("h")) do
      if Fk:getCardById(id).color == Card.Red then
        table.insert(ids, id)
      end
    end
    if #ids > 0 then
      room:throwCard(ids, self.name, data.to, player)
      if not player.dead then
        player:drawCards(#ids, self.name)
      end
    end
  end,
}
local zhengjun = fk.CreateTriggerSkill{
  name = "zhengjun",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self.name) and player.phase == Player.Play
      else
        return player.phase == Player.Discard and not player.dead and
        player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and
        table.find({"zhengsu_leijin-turn", "zhengsu_bianzhen-turn", "zhengsu_mingzhi-turn"}, function(name)
          return player:getMark(name) ~= 0 and table.contains(player:getMark(name), player.id) end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#zhengjun-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      StartZhengsu(player, player, self.name, "#zhengjun-choice")
    else
      local room = player.room
      local choices = {"draw2"}
      if player:isWounded() then
        table.insert(choices, 1, "recover")
      end
      local reward = room:askForChoice(player, choices, self.name, "#zhengjun-reward", false, {"draw2", "recover"})
      RewardZhengsu(player, player, reward, self.name)
      local to = room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
        return p.id end), 1, 1, "#zhengjun-choose", self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        choices = {"draw2"}
        if to:isWounded() then
          table.insert(choices, 1, "recover")
        end
        reward = room:askForChoice(player, choices, self.name, "#zhengjun-support::"..to.id, false, {"draw2", "recover"})
        RewardZhengsu(player, to, reward, self.name)
      end
    end
  end,
}
huangfusong:addSkill(taoluanh)
huangfusong:addSkill(shiji)
huangfusong:addSkill(zhengjun)
Fk:loadTranslationTable{
  ["mobile__huangfusong"] = "皇甫嵩",
  ["taoluanh"] = "讨乱",
  [":taoluanh"] = "每回合限一次，当一名角色判定牌生效前，若判定结果为♠，你可以终止此次判定并选择一项：1.你获得此判定牌；"..
  "2.若进行判定的角色不是你，你视为对其使用一张无距离和次数限制的火【杀】。",
  ["shiji"] = "势击",
  [":shiji"] = "当你对其他角色造成属性伤害时，若你的手牌数不为全场唯一最多，你可以观看其手牌并弃置其中所有的红色牌，然后你摸等量的牌。",
  ["zhengjun"] = "整军",
  [":zhengjun"] = "出牌阶段开始时，你可以进行“整肃”，弃牌阶段结束后，若“整肃”成功，你获得“整肃”奖励，然后你可以令一名其他角色也获得“整肃”奖励。"..
  "<br/><font color='grey'>#\"<b>整肃</b>\"<br/>"..
  "技能发动者从擂进、变阵、鸣止中选择一项令目标执行，若本回合“整肃”成功，则弃牌阶段结束后获得“整肃奖励”。<br/>"..
  "<b>擂进：</b>出牌阶段内，使用的所有牌点数需递增，且至少使用三张牌。<br/>"..
  "<b>变阵：</b>出牌阶段内，使用的所有牌花色需相同，且至少使用两张牌。<br/>"..
  "<b>鸣止：</b>弃牌阶段内，弃置的所有牌花色均不同，且至少弃置两张牌。<br/>"..
  "<b>整肃奖励：</b>摸两张牌或回复1点体力。",
  ["#taoluanh-invoke"] = "讨乱：%dest 的判定即将生效，你可以终止此判定并执行一项！",
  ["taoluanh_prey"] = "获得判定牌",
  ["taoluanh_slash"] = "视为对其使用火【杀】",
  ["#shiji-invoke"] = "势击：你可以观看 %dest 的手牌并弃置其中所有红色牌，然后摸等量牌",
  ["#zhengjun-invoke"] = "整军：你可以进行“整肃”，若成功，则弃牌阶段结束后获得奖励，且可以令一名其他角色获得奖励",
  ["#zhengjun-choice"] = "整军：选择你本回合“整肃”的条件",
  ["#zhengjun-reward"] = "整军：“整肃”成功，选择一项整肃奖励",
  ["#zhengjun-choose"] = "整军：你可以令一名其他角色也获得整肃奖励",
  ["#zhengjun-support"] = "整军：选择 %dest 获得的整肃奖励",

  ["$taoluanh1"] = "乱民桀逆，非威不服！",
  ["$taoluanh2"] = "欲定黄巾，必赖兵革之利！",
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
    player:broadcastSkillInvoke(self.name, 1)
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
    player:usedSkillTimes("houfeng", Player.HistoryTurn) > 0 and
    table.find({"zhengsu_leijin-turn", "zhengsu_bianzhen-turn", "zhengsu_mingzhi-turn"}, function(name)
      return target:getMark(name) ~= 0 and table.contains(target:getMark(name), player.id) end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "houfeng")
    player:broadcastSkillInvoke("houfeng", 2)
    local choices = {"draw2"}
    if player:isWounded() or (target:isWounded() and not target.dead) then
      table.insert(choices, 1, "recover")
    end
    local reward = room:askForChoice(target, choices, self.name, "#houfeng-reward:"..player.id, false, {"draw2", "recover"})
    RewardZhengsu(player, target, reward, "houfeng")
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
  "<b>擂进：</b>出牌阶段内，使用的所有牌点数需递增，且至少使用三张牌。<br/>"..
  "<b>变阵：</b>出牌阶段内，使用的所有牌花色需相同，且至少使用两张牌。<br/>"..
  "<b>鸣止：</b>弃牌阶段内，弃置的所有牌花色均不同，且至少弃置两张牌。<br/>"..
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
