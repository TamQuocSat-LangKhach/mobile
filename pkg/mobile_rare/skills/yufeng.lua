local yufeng = fk.CreateSkill {
  name = "mobile__yufeng",
}

Fk:loadTranslationTable{
  ["mobile__yufeng"] = "御风",
  [":mobile__yufeng"] = "出牌阶段限一次，你可以进行一次<a href=':mobile__yufeng_href'>御风飞行</a>。若失败你摸X张牌；"..
  "若成功，你可以选择至多X名其他角色，其下一个准备阶段进行一次判定：若结果为黑色，其跳过出牌和弃牌阶段；若结果为红色，" ..
  "其跳过摸牌阶段；若选择角色数不足X，剩余的分数改为摸等量张牌（X为御风飞行得分，至多为3）。",

  [":mobile__yufeng_href"] = "随机亮出牌堆和弃牌堆中的一张牌，然后重复猜测下一张亮出的牌比上一张亮出的牌点数更大或更小，" ..
  "直到达到分数上限或猜错（2分或3分），每猜对一次得一分。",

  ["#mobile__yufeng"] = "御风：你可玩一次小游戏，成功后令他人跳过摸牌或出牌弃牌阶段",
  ["#mobile__yufeng-choose"] = "御风：选择至多 %arg 名其他角色，其下回合跳过摸牌或出牌弃牌阶段",
  ["@@mobile__yufeng"] = "御风",
  ["#mobile__yufeng_delay"] = "御风",
  ["mobile__yufeng_more"] = "下一张牌点数比%arg大",
  ["mobile__yufeng_less"] = "下一张牌点数比%arg小",
  ["#mobile__yufeng-choice"] = "御风：猜测下一张牌的点数",
  ["score_zero"] = "惜哉，未能窥见星辰。",
  ["score_one"] = "风紧，赶紧跑。",
  ["score_not_full"] = "星辰已纳入囊中。",
  ["score_full"] = "满载而归，哈哈。",

  ["$mobile__yufeng1"] = "广开兮天门，纷吾乘兮玄云。",
  ["$mobile__yufeng2"] = "高飞兮安翔，乘清气兮御阴阳。",
}

yufeng:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  prompt = "#mobile__yufeng",
  can_use = function(self, player)
    return player:usedSkillTimes(yufeng.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local maxScore = math.random() <= 0.6 and 3 or 2
    local score = 0
    local findBig = math.random() < 0.5
    local cardsRevealed = {}
    for i = 1, maxScore + 1 do
      if #room.draw_pile + #room.discard_pile == 0 then
        break
      end

      local choice
      if i > 1 then
        local lastNumber = Fk:getCardById(cardsRevealed[i - 1]):getNumberStr()
        choice = room:askToChoice(player, {
          choices = {"mobile__yufeng_more:::" .. lastNumber, "mobile__yufeng_less:::" .. lastNumber},
          skill_name = yufeng.name,
          prompt = "#mobile__yufeng-choice",
        })
      end

      local cardToReveal
      local randomNum = math.random()
      if randomNum <= 0.7 or i == 1 then
        local numberToApproach = findBig and 13 or 1
        local minDiff = 99
        for _, id in ipairs(room.discard_pile) do
          local cardNumber = Fk:getCardById(id).number
          if cardNumber == numberToApproach then
            cardToReveal = id
            minDiff = 0
            break
          elseif math.abs(cardNumber - numberToApproach) < minDiff then
            cardToReveal = id
            minDiff = math.abs(cardNumber - numberToApproach)
          end
        end
        if minDiff > 0 then
          for _, id in ipairs(room.draw_pile) do
            local cardNumber = Fk:getCardById(id).number
            if cardNumber == numberToApproach then
              cardToReveal = id
              break
            elseif math.abs(cardNumber - numberToApproach) < minDiff then
              cardToReveal = id
              minDiff = math.abs(cardNumber - numberToApproach)
            end
          end
        end

        findBig = not findBig
      elseif randomNum > 0.7 and randomNum <= 0.95 then
        for i = 1, 3 do
          local randomIndex = math.random(1, #room.draw_pile + #room.discard_pile)
          if randomIndex <= #room.draw_pile then
            cardToReveal = room.draw_pile[randomIndex]
          else
            cardToReveal = room.discard_pile[randomIndex - #room.draw_pile]
          end

          if not table.contains({6, 7, 8}, Fk:getCardById(cardToReveal).number) then
            break
          end
        end

        local numberFound = Fk:getCardById(cardToReveal).number
        findBig = math.abs(numberFound - 13) > math.abs(numberFound - 1)
      else
        local randomMidNumber = math.random(6, 8)
        for _, id in ipairs(room.discard_pile) do
          if Fk:getCardById(id).number == randomMidNumber then
            cardToReveal = id
            break
          end
        end
        if not cardToReveal then
          for _, id in ipairs(room.draw_pile) do
            if Fk:getCardById(id).number == randomMidNumber then
              cardToReveal = id
              break
            end
          end
        end

        if not cardToReveal then
          local randomIndex = math.random(1, #room.draw_pile + #room.discard_pile)
          if randomIndex <= #room.draw_pile then
            cardToReveal = room.draw_pile[randomIndex]
          else
            cardToReveal = room.discard_pile[randomIndex - #room.draw_pile]
          end

          local numberFound = Fk:getCardById(cardToReveal).number
          findBig = math.abs(numberFound - 13) > math.abs(numberFound - 1)
        else
          findBig = math.random() <= 0.5
        end
      end

      table.insert(cardsRevealed, cardToReveal)

      local curNumber = Fk:getCardById(cardToReveal).number
      room:moveCardTo(cardToReveal, Card.Processing, nil, fk.ReasonJustMove, yufeng.name, nil, true, player)
      if choice then
        local lastNumber = Fk:getCardById(cardsRevealed[i - 1]).number
        if
          (choice:startsWith("mobile__yufeng_more") and lastNumber >= curNumber) or
          (choice:startsWith("mobile__yufeng_less") and lastNumber <= curNumber)
        then
          room:setCardEmotion(cardToReveal, "judgebad")
          room:delay(1000)
          break
        else
          score = score + 1
          room:setCardEmotion(cardToReveal, "judgegood")
        end
      end
      room:delay(1000)
    end

    if #cardsRevealed == 0 then return end
    room:cleanProcessingArea(cardsRevealed)

    local chatStr = "score_full"
    if score == 0 then
      chatStr = "score_zero"
    elseif score == 1 then
      chatStr = "score_one"
    elseif score < maxScore then
      chatStr = "score_not_full"
    end
    player:chat(Fk:translate(chatStr))

    if not (score < maxScore and math.random() < 0.2) then
      local tos = player.room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = score,
        prompt = "#mobile__yufeng-choose:::" .. score,
        skill_name = yufeng.name,
        cancelable = true,
      })
      if #tos > 0 then
        for _, p in ipairs(tos) do
          room:setPlayerMark(p, "@@mobile__yufeng", 1)
        end
      end
      score = score - #tos
    end
    if score > 0 then
      player:drawCards(score, yufeng.name)
    end
  end,
})
yufeng:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("@@mobile__yufeng") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@mobile__yufeng", 0)
    local judge = {
      who = player,
      reason = yufeng.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Black then
      player:skip(Player.Play)
      player:skip(Player.Discard)
    elseif judge.card.color == Card.Red then
      player:skip(Player.Draw)
    end
  end,
}, {
  is_delay_effect = true,
})

return yufeng
