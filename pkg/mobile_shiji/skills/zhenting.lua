local zhenting = fk.CreateSkill {
  name = "zhenting",
}

Fk:loadTranslationTable{
  ["zhenting"] = "镇庭",
  [":zhenting"] = "每回合限一次，当你攻击范围内的一名角色成为【杀】或延时锦囊牌的目标时，若你不为此牌的使用者或目标，"..
  "你可以代替其成为此牌的目标，然后选择一项：1.弃置此牌使用者的一张牌；2.摸一张牌。",

  ["#zhenting-invoke"] = "镇庭：你可以将 %src 对 %dest 使用的%arg转移给你，然后你弃置使用者一张牌或摸一张牌",
  ["zhenting_discard"] = "弃置%dest一张牌",

  ["$zhenting1"] = "今政事在我，更要持重慎行！",
  ["$zhenting2"] = "国可因外敌而亡，不可因内政而损！",
}

zhenting:addEffect(fk.TargetConfirming, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhenting.name) and player:usedSkillTimes(zhenting.name, Player.HistoryTurn) == 0 and
      data.from ~= player and (data.card.trueName == "slash" or data.card.sub_type == Card.SubtypeDelayedTrick) and
      player:inMyAttackRange(target) and not data.from:isProhibited(player, data.card)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhenting.name,
      prompt = "#zhenting-invoke:"..data.from.id..":"..target.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {target}})
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:cancelTarget(target)
    data:addTarget(player)
    local choices = {"draw1"}
    if not data.from.dead and not data.from:isNude() then
      table.insert(choices, 1, "zhenting_discard::"..data.from.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhenting.name,
    })
    if choice == "draw1" then
      player:drawCards(1, zhenting.name)
    else
      local id = room:askToChooseCard(player, {
        target = data.from,
        flag = "he",
        skill_name = zhenting.name,
      })
      room:throwCard(id, zhenting.name, data.from, player)
    end
  end,
})

return zhenting
