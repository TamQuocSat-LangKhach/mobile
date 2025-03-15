local zengou = fk.CreateSkill {
  name = "mobile__zengou",
}

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

local U = require "packages/utility/utility"

local shuffleCardtoDrawPile = function (player, cards, skillName, proposer)
  proposer = proposer or player
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
      from = player,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      drawPilePosition = positions[i],
      proposer = proposer,
    })
  end
  room:moveCards(table.unpack(moveInfos))
end

zengou:addEffect("active", {
  anim_type = "control",
  prompt = "#mobile__zengou-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng() and
      not table.contains(player:getTableMark("mobile__zengou_prohibit"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:notifySkillInvoked(player, zengou.name, "control", effect.tos)
    player:broadcastSkillInvoke(zengou.name, math.random(2))
    local cids = target:getCardIds(Player.Hand)
    local choice = U.askforViewCardsAndChoice(player, cids, {"mobile__zengou_use", "mobile__zengou_exchange"},
      zengou.name, "#mobile__zengou-choose::" .. target.id)
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
        local use = room:askToUseRealCard(player, {
          pattern = toUse,
          skill_name = zengou.name,
          prompt = "#mobile__zengou-use",
          extra_data = {
            bypass_times = true,
            extraUse = true,
            expand_pile = toUse,
          },
          skip = true
        })
        if use then
          room:addPlayerMark(player, "@mobile__zengou-round")
          card = Fk:cloneCard(use.card.name)
          card.skillName = zengou.name
          room:useCard{
            card = card,
            from = player,
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
        shuffleCardtoDrawPile(player, toPut, zengou.name)
        if not player.dead then
          toPut = room:getCardsFromPileByRule("slash", x)
          if #toPut > 0 then
            room:obtainCard(player, toPut, false, fk.ReasonJustMove, player, zengou.name, "@@mobile__zengou-inhand")
          end
        end
        toPut = table.filter(target:getCardIds(Player.Hand), function (id)
          return table.contains(cardNames, Fk:getCardById(id).trueName)
        end)
        x = #toPut
        if x > 0 then
          shuffleCardtoDrawPile(target, toPut, zengou.name, player)
          if not target.dead then
            toPut = room:getCardsFromPileByRule("slash", x)
            if #toPut > 0 then
              room:obtainCard(target, toPut, false, fk.ReasonJustMove, player, zengou.name, "@@mobile__zengou-inhand")
            end
          end
        end
      end
    end
    if player:hasSkill(zengou.name, true) and not target.dead then
      local cards = U.getUniversalCards(room, "b", true)
      if #cards > 0 then
        local id = room:askToChooseCard(player, {
          target = target,
          flag = {
            card_data = {
              { "basic", cards }
            }
          },
          skill_name = zengou.name,
          prompt = "#mobile__zengou-bname::" .. target.id
        })
        U.setPrivateMark(target, "mobile__zengou_wu", { Fk:getCardById(id).trueName }, { player.id })
      end
    end
  end,
})

zengou:addEffect(fk.CardUseFinished, {
  anim_type = "negative",
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player ~= data.from or not table.contains(U.getPrivateMark(player, "mobile__zengou_wu"), data.card.trueName) then
      return false
    end
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark = player:getMark("mobile__zengou-turn")
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data
        if last_use.from == player then
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
    room:notifySkillInvoked(player, zengou.name, "negative")
    player:broadcastSkillInvoke(zengou.name, 3)
    room:setPlayerMark(player, "@[private]mobile__zengou_wu", 0)
    room:loseHp(player, 1, zengou.name)
  end,
})

zengou:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@mobile__zengou-inhand") > 0
  end,
})

zengou:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player == target
  end,
  on_refresh = function(self, event, target, player, data)
    U.clearHandMark(player, "@@mobile__zengou-inhand")
  end,
})

zengou:addLoseEffect(function(self, player)
  local room = player.room
  room:setPlayerMark(player, "@mobile__zengou-round", 0)
  room:setPlayerMark(player, "mobile__zengou_prohibit", 0)
end)

return zengou
