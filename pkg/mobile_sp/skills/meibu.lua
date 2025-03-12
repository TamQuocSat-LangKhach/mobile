local meibu = fk.CreateSkill{
  name = "mobile__meibu",
}

Fk:loadTranslationTable{
  ["mobile__meibu"] = "魅步",
  [":mobile__meibu"] = "其他角色的出牌阶段开始时，若你在其攻击范围内，你可以弃置一张牌，然后其本回合视为拥有技能〖止息〗。若你以此法弃置的牌"..
  "不是【杀】或黑色锦囊牌，则本回合其与你距离为1。",

  ["#mobile__meibu-invoke"] = "魅步：是否弃一张牌，令 %dest 本回合获得“止息”？",

  ["$mobile__meibu1"] = "倚栏赏华舟，翠叶香万里。",
  ["$mobile__meibu2"] = "娇莺枝头舞，佳节兵戈止。",
}

meibu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(meibu.name) and target.phase == Player.Play and
      target:inMyAttackRange(player) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = meibu.name,
      prompt = "#mobile__meibu-invoke::"..target.id,
      cancelable = true,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {tos = {target}, cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(event:getCostData(self).cards[1])
    if card.trueName ~= "slash" and not (card.color == Card.Black and card.type == Card.TypeTrick) then
      room:setPlayerMark(player, "mobile__meibu_src-turn", 1)
    end
    room:throwCard(card, meibu.name, player, player)
    if target.dead then return end
    room:setPlayerMark(target, "mobile__meibu-turn", 1)
    room:handleAddLoseSkills(target, "mobile__zhixi")
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(target, "-mobile__zhixi")
    end)
  end,
})
meibu:addEffect("distance", {
  fixed_func = function(self, from, to)
    if from:getMark("mobile__meibu-turn") > 0 and to:getMark("mobile__meibu_src-turn") > 0 then
      return 1
    end
  end,
})

return meibu
