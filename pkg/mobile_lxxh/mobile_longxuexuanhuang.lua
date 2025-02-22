
local U = require "packages/utility/utility"

local simafu = General(extension, "simafu", "wei", 3)
simafu.subkingdom = "jin"
local xunde = fk.CreateTriggerSkill{
  name = "xunde",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target.dead and (player == target or player:distanceTo(target) == 1)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#xunde-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.number >= 6 and player ~= target and not target.dead
    and room:getCardArea(judge.card.id) == Card.DiscardPile then
      room:obtainCard(target, judge.card)
    end
    if judge.card.number <= 6 and data.from and not data.from.dead then
      room:askForDiscard(data.from, 1, 1, false, self.name, false)
    end
  end,
}
local chenjie = fk.CreateTriggerSkill{
  name = "chenjie",
  anim_type = "drawcard",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, 1, 1, true, self.name, true, ".|.|"..data.card:getSuitString(),
    "#chenjie-invoke::"..target.id..":"..data.card:getSuitString(true)..":"..data.reason)
    if #cards > 0 then
      self.cost_data = cards[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data), player, data, self.name)
    if not player.dead then
      player:drawCards(2, self.name)
    end
  end,
}
simafu:addSkill(xunde)
simafu:addSkill(chenjie)
Fk:loadTranslationTable{
  ["simafu"] = "司马孚",
  ["#simafu"] = "阐忠弘道",
  ["illustrator:simafu"] = "鬼画府",

  ["xunde"] = "勋德",
  [":xunde"] = "当一名角色受到伤害后，若你与其距离1以内，你可判定，若点数不小于6且该角色不为你，你令其获得此判定牌；"..
  "若点数不大于6，你令来源弃置一张手牌。",
  ["chenjie"] = "臣节",
  [":chenjie"] = "当一名角色的判定牌生效前，你可以用一张与判定牌相同花色的牌代替之，然后你摸两张牌。",
  ["#xunde-invoke"] = "勋德：%dest 受到伤害，你可以判定，根据点数执行效果",
  ["#chenjie-invoke"] = "臣节：你可以打出一张%arg牌修改 %dest 的 %arg2 判定并摸两张牌",

  ["$xunde1"] = "陛下所托，臣必尽心尽力！",
  ["$xunde2"] = "纵吾荏弱难持，亦不推诿君命！",
  ["$chenjie1"] = "臣心怀二心，不可事君也。",
  ["$chenjie2"] = "竭力致身，以尽臣节。",
  ["~simafu"] = "身辅六公，亦难报此恩……",
}


local simazhao = General(extension, "mobile__simazhao", "wei", 3)
table.insert(Fk.lords, "mobile__simazhao") -- 没有主公技的常备主
local simazhao2 = General(extension, "mobile2__simazhao", "qun", 3)
simazhao2.hidden = true

local simazhaoWin = fk.CreateActiveSkill{ name = "mobile__simazhao_win_audio" }
simazhaoWin.package = extension
Fk:addSkill(simazhaoWin)
local simazhao2Win = fk.CreateActiveSkill{ name = "mobile2__simazhao_win_audio" }
simazhao2Win.package = extension
Fk:addSkill(simazhao2Win)

Fk:loadTranslationTable{
  ["mobile__simazhao"] = "司马昭",
  ["#mobile__simazhao"] = "独祅吞天",
  ["illustrator:mobile__simazhao"] = "腥鱼仔",
  ["$mobile__simazhao_win_audio"] = "明日正为吉日，当举禅位之典。",
  ["~mobile__simazhao"] = "曹髦小儿竟有如此肝胆……我实不甘。",

  ["mobile2__simazhao"] = "司马昭",
  ["#mobile2__simazhao"] = "独祅吞天",
  ["illustrator:mobile2__simazhao"] = "腥鱼仔",
  ["$mobile2__simazhao_win_audio"] = "万里山河，终至我司马一家。",
  ["~mobile2__simazhao"] = "愿我晋祚，万世不易，国运永昌。",
}

local xiezheng = fk.CreateTriggerSkill{
  name = "mobile__xiezheng",
  anim_type = "control",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      if player:getMark("mobile__xiezheng_updata") > 0 then
        return "mobile__xiezheng_role_mode2"
      else
        return "mobile__xiezheng_role_mode"
      end
    elseif Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__xiezheng_1v2"
    else
      return "mobile__xiezheng_2v2"
    end
  end,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player.room:isGameMode("1v2_mode") and player:usedSkillTimes(self.name, Player.HistoryGame) > 0 then return false end
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local num = room:isGameMode("1v2_mode") and 2 or 1
    local debuff = " "
    if room:isGameMode("role_mode") and player:getMark("mobile__xiezheng_updata") == 0 then
      debuff = ":mobile__xiezheng_debuff"
    end
    local prompt = "#mobile__xiezheng-choose:::"..num..":"..debuff
    
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, num,
    prompt, self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead and not p:isKongcheng() then
        room:moveCards({
          ids = table.random(p:getCardIds("h"), 1),
          from = id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
    if player.dead then return end
    local extra_data = {}
    if room:isGameMode("role_mode") and player:getMark("mobile__xiezheng_updata") == 0 then
      local must_targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return p.kingdom == player.kingdom
      end)
      if #must_targets > 0 then
        extra_data.must_targets = table.map(must_targets, Util.IdMapper)
      end
    end
    local use = U.askForUseVirtualCard(room, player, "mobile__enemy_at_the_gates", nil, self.name, "#mobile__xiezheng-use", false, nil, nil, nil, extra_data)
    if use and not player.dead and not (use.extra_data and use.extra_data.mobile__xiezheng_damageDealt) then
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash"
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent().parent
    while e do
      if e.event == GameEvent.UseCard then
        local use = e.data[1]
        if use.card.name == "mobile__enemy_at_the_gates" and table.contains(use.card.skillNames, "mobile__xiezheng") then
          use.extra_data = use.extra_data or {}
          use.extra_data.mobile__xiezheng_damageDealt = true
          return
        end
      end
      e = e.parent
    end
  end,
}
simazhao:addSkill(xiezheng)
simazhao2:addSkill("mobile__xiezheng")

Fk:loadTranslationTable{
  ["mobile__xiezheng"] = "挟征",
  [":mobile__xiezheng"] = "结束阶段，你可以令至多一名角色（若为斗地主模式，改为两名，本局游戏限一次）依次将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】（若为身份模式，优先指定同势力角色为目标），结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_role_mode"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】（需优先指定同势力角色为目标），结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_role_mode2"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_1v2"] = "每局游戏限一次，结束阶段，你可以令至多两名角色依次将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  [":mobile__xiezheng_2v2"] = "结束阶段，你可以令一名角色将随机一张手牌置于牌堆顶，"..
  "然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  ["#mobile__xiezheng-choose"] = "挟征：令至多%arg名角色依次将随机一张手牌置于牌堆顶，然后你视为使用一张%arg2【兵临城下】！",
  ["#mobile__xiezheng-use"] = "挟征：视为使用一张【兵临城下】！若未造成伤害，你失去1点体力",
  ["mobile__xiezheng_debuff"] = "优先指定同势力角色为目标的",

  ["$mobile__xiezheng1"] = "烈祖明皇帝乘舆仍出，陛下何妨效之。",
  ["$mobile__xiezheng2"] = "陛下宜誓临戎，使将士得凭天威。",
  ["$mobile__xiezheng3"] = "既得众将之力，何愁贼不得平？",--挟征（第二形态）
  ["$mobile__xiezheng4"] = "逆贼起兵作乱，诸位无心报国乎？",--挟征（第二形态）
}

local qiantun = fk.CreateActiveSkill{
  name = "mobile__qiantun",
  anim_type = "control",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__qiantun_1v2"
    else
      return "mobile__qiantun_role_mode"
    end
  end,
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__qiantun",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 999, false, self.name, false, nil, "#mobile__qiantun-ask:"..player.id)
    target:showCards(cards)
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if player.dead or target.dead or #cards == 0 or not player:canPindian(target) then return end
    local pindian = {
      from = player,
      tos = {target},
      reason = self.name,
      fromCard = nil,
      results = {},
      extra_data = {
        mobile__qiantun = {
          to = target.id,
          cards = cards,
        },
      },
    }
    room:pindian(pindian)
    if player.dead or target.dead then return end
    if pindian.results[target.id].winner == player then
      cards = table.filter(target:getCardIds("h"), function (id)
        return table.contains(cards, id)
      end)
    else
      cards = table.filter(target:getCardIds("h"), function (id)
        return not table.contains(cards, id)
      end)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
    if not player.dead and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
  end,
}
local qiantun_trigger = fk.CreateTriggerSkill{
  name = "#mobile__qiantun_trigger",
  mute = true,
  events = {fk.StartPindian},
  can_trigger = function(self, event, target, player, data)
    if player == data.from and data.reason == "mobile__qiantun" and data.extra_data and data.extra_data.mobile__qiantun then
      for _, to in ipairs(data.tos) do
        if not (data.results[to.id] and data.results[to.id].toCard) and
          data.extra_data.mobile__qiantun.to == to.id and
          table.find(data.extra_data.mobile__qiantun.cards, function (id)
            return table.contains(to:getCardIds("h"), id)
          end) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      if not (to.dead or to:isKongcheng() or (data.results[to.id] and data.results[to.id].toCard)) and
        data.extra_data.mobile__qiantun.to == to.id then
        local cards = table.filter(data.extra_data.mobile__qiantun.cards, function (id)
          return table.contains(to:getCardIds("h"), id)
        end)
        if #cards > 0 then
          local card = room:askForCard(to, 1, 1, false, "qiantun", false, tostring(Exppattern{ id = cards }),
            "#mobile__qiantun-pindian:"..data.from.id)
          data.results[to.id] = data.results[to.id] or {}
          data.results[to.id].toCard = Fk:getCardById(card[1])
        end
      end
    end
  end,
}
qiantun:addRelatedSkill(qiantun_trigger)
qiantun:addAttachedKingdom("wei")
simazhao:addSkill(qiantun)

Fk:loadTranslationTable{
  ["mobile__qiantun"] = "谦吞",
  [":mobile__qiantun"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。（若为斗地主模式，至多获得两张）",
  [":mobile__qiantun_role_mode"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。",
  [":mobile__qiantun_1v2"] = "魏势力技，出牌阶段限一次，你可以令一名有手牌的其他角色展示至少一张手牌，然后你与其拼点（其仅能用展示牌拼点）。"..
  "若你赢，你获得其展示的手牌；若你没赢，你获得其未展示的手牌。（至多获得两张）",
  ["#mobile__qiantun"] = "谦吞：令一名角色展示任意张手牌并与其拼点，若赢，你获得展示牌；若没赢，你获得其未展示的手牌",
  ["#mobile__qiantun-ask"] = "谦吞：请展示任意张手牌，你将只能用这些牌与 %src 拼点，根据拼点结果其获得你的展示牌或未展示牌！",
  ["#mobile__qiantun-pindian"] = "谦吞：你只能用这些牌与 %src 拼点！若其赢，其获得你的展示牌；若其没赢，其获得你未展示的手牌",

  ["$mobile__qiantun1"] = "辅国臣之本分，何敢图于禄勋。",
  ["$mobile__qiantun2"] = "蜀贼吴寇未灭，臣未可受此殊荣。",
  ["$mobile__qiantun3"] = "陛下一国之君，不可使以小性。",--谦吞（赢）	
  ["$mobile__qiantun4"] = "讲经宴筵，实非治国之道也。",--谦吞（没赢）
}

local zhaoxiong = fk.CreateTriggerSkill{
  name = "mobile__zhaoxiong",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("role_mode") then
      return "mobile__zhaoxiong_role_mode"
    else
      return "mobile__zhaoxiong_1v2"
    end
  end,
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player:isWounded()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__zhaoxiong-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "mobile__xiezheng_updata", 1)

    if player.general == "mobile__simazhao" then
      room:setPlayerProperty(player, "general", "mobile2__simazhao")
    elseif player.deputyGeneral == "mobile__simazhao" then
      room:setPlayerProperty(player, "deputyGeneral", "mobile2__simazhao")
    end
    if player.kingdom ~= "qun" then
      room:changeKingdom(player, "qun", true)
    end
    room:handleAddLoseSkills(player, "-mobile__qiantun|mobile__weisi|mobile__dangyi")
  end,
}
zhaoxiong.permanent_skill = true
simazhao:addSkill(zhaoxiong)
simazhao2:addSkill("mobile__zhaoxiong")

Fk:loadTranslationTable{
  ["mobile__zhaoxiong"] = "昭凶",
  [":mobile__zhaoxiong"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗"..
  "（若为身份模式，则删去〖挟征〗中的“优先指定同势力角色为目标”）。",
  [":mobile__zhaoxiong_role_mode"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗，"..
  "并删去〖挟征〗中的“优先指定同势力角色为目标”。",
  [":mobile__zhaoxiong_1v2"] = "持恒技，限定技，准备阶段，若你已受伤，你可以将势力变更为群，然后你获得技能〖荡异〗。",
  ["#mobile__zhaoxiong-invoke"] = "昭凶：是否变为群势力、失去“谦吞”、获得“威肆”和“荡异”？",
  ["$mobile__zhaoxiong1"] = "若得灭蜀之功，何不可受禅为帝。",
  ["$mobile__zhaoxiong2"] = "已极人臣之贵，当一尝人主之威。",
}

local dangyi = fk.CreateTriggerSkill{
  name = "mobile__dangyi$",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) < 2
    and player:usedSkillTimes(self.name) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#mobile__dangyi-invoke::"..data.to.id..":"
    ..(2-player:usedSkillTimes(self.name, Player.HistoryGame)))
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
dangyi.permanent_skill = true
simazhao2:addSkill(dangyi)

Fk:loadTranslationTable{
  ["mobile__dangyi"] = "荡异",
  [":mobile__dangyi"] = "持恒技，主公技，每回合限一次，当你造成伤害时，你可以令此伤害+1（每局游戏限两次）。",
  ["#mobile__dangyi-invoke"] = "荡异：是否令你对 %dest 造成的伤害+1？（还剩%arg次！）",
  ["$mobile__dangyi1"] = "哼！斩首示众，以儆效尤。",
  ["$mobile__dangyi2"] = "汝等仍存异心，可见心存魏阙。",
}

local weisi = fk.CreateActiveSkill{
  name = "mobile__weisi",
  anim_type = "offensive",
  dynamic_desc = function(self, player)
    if Fk:currentRoom():isGameMode("1v2_mode") then
      return "mobile__weisi_1v2"
    else
      return "mobile__weisi_role_mode"
    end
  end,
  card_num = 0,
  target_num = 1,
  prompt = "#mobile__weisi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 999, false, self.name, true, nil, "#mobile__weisi-ask:"..player.id)
    if #cards > 0 then
      target:addToPile("$mobile__weisi", cards, false, self.name, target.id)
    end
    if player.dead or target.dead then return end
    room:useVirtualCard("duel", nil, player, target, self.name)
  end,
}
local weisi_delay = fk.CreateTriggerSkill{
  name = "#mobile__weisi_delay",
  mute = true,
  events = {fk.Damage, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Damage then
      return target == player and not player.dead and player.room.logic:damageByCardEffect() and
        data.card and table.contains(data.card.skillNames, "mobile__weisi") and
        not data.to:isKongcheng()
    elseif event == fk.TurnEnd then
      return #player:getPile("$mobile__weisi") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      local cards = data.to:getCardIds("h")
      if room:isGameMode("1v2_mode") then
        cards = table.random(cards, 1)
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, "mobile__weisi", nil, false, player.id)
    elseif event == fk.TurnEnd then
      room:moveCardTo(player:getPile("$mobile__weisi"), Card.PlayerHand, player, fk.ReasonJustMove, "mobile__weisi", nil, false, player.id)
    end
  end,
}
weisi:addRelatedSkill(weisi_delay)
simazhao2:addSkill(weisi)

Fk:loadTranslationTable{
  ["mobile__weisi"] = "威肆",
  [":mobile__weisi"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其所有手牌（若为斗地主模式，所有改为一张）。",
  [":mobile__weisi_role_mode"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，"..
  "然后视为对其使用一张【决斗】，此牌对其造成伤害后，你获得其所有手牌。",
  [":mobile__weisi_1v2"] = "群势力技，出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其一张手牌。",
  ["#mobile__weisi"] = "威肆：令一名角色将任意张手牌移出游戏直到回合结束，然后视为对其使用【决斗】！",
  ["#mobile__weisi-ask"] = "威肆：%src 将对你使用【决斗】！请将任意张手牌本回合移出游戏，【决斗】对你造成伤害后其获得你手牌！",
  ["$mobile__weisi"] = "威肆",
  ["#mobile__weisi_delay"] = "威肆",
  ["$mobile__weisi1"] = "上者慑敌以威，灭敌以势。",
  ["$mobile__weisi2"] = "哼，求存者多，未见求死者也。",
  ["$mobile__weisi3"] = "未想逆贼区区，竟然好物甚巨。", --威肆（获得手牌）
}


return extension
