local huishi = fk.CreateSkill {
  name = "mobile__huishi",
}

Fk:loadTranslationTable{
  ["mobile__huishi"] = "慧识",
  [":mobile__huishi"] = "出牌阶段限一次，若你的体力上限小于10，你可以判定，若花色与本次流程中的其他判定结果均不同，且你的体力上限小于10，"..
  "你可以加1点体力上限并重复此流程。最后你将本次流程中所有生效的判定牌交给一名角色，若其手牌为全场最多，你减1点体力上限。",

  ["#mobile__huishi"] = "慧识：连续判定直到出现相同花色，然后将判定牌交给一名角色",
  ["#mobile__huishi-ask"] = "慧识：你可以加1点体力上限并继续判定",
  ["#mobile__huishi-choose"] = "慧识：将这些判定牌交给一名角色，点“取消”自己获得",

  ["$mobile__huishi1"] = "聪以知远，明以察微。",
  ["$mobile__huishi2"] = "见微知著，识人心智。",
}

huishi:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#mobile__huishi",
  can_use = function(self, player)
    return player:usedSkillTimes(huishi.name, Player.HistoryPhase) == 0 and player.maxHp < 10
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from

    local cards = {}
    while player.maxHp < 10 do
      local parsePattern = table.concat(table.map(cards, function(card)
        return card:getSuitString()
      end), ",")

      local judge = {
        who = player,
        reason = huishi.name,
        pattern = ".|.|" .. (parsePattern == "" and "." or "^(" .. parsePattern .. ")"),
        skipDrop = true,
      }
      room:judge(judge)
      table.insert(cards, judge.card)
      if not table.every(cards, function(card)
          return card == judge.card or judge.card:compareSuitWith(card, true)
        end) or
        player.dead or
        not room:askToSkillInvoke(player, {
          skill_name = huishi.name,
          prompt = "#mobile__huishi-ask",
        })
      then
        break
      else
        room:changeMaxHp(player, 1)
      end
    end

    cards = table.filter(cards, function(card)
      return room:getCardArea(card.id) == Card.Processing
    end)
    if #cards == 0 then
      return
    elseif player.dead then
      room:cleanProcessingArea(cards)
      return
    end

    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = huishi.name,
      prompt = "#mobile__huishi-choose",
      cancelable = true,
    })
    if #to > 0 then
      to = to[1]
    else
      to = player
    end
    room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, huishi.name, nil, true, player)
    if table.every(room.alive_players, function (p)
      return to:getHandcardNum() >= p:getHandcardNum()
    end) and not player.dead then
      room:changeMaxHp(player, -1)
    end
  end,
})

return huishi
