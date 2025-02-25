local dangyi = fk.CreateSkill {
  name = "dangyi",
  tags = { Skill.Lord, Skill.Permanent },
}

Fk:loadTranslationTable{
  ["mobile__dangyi"] = "荡异",
  [":mobile__dangyi"] = "持恒技，主公技，每回合限一次，当你造成伤害时，你可以令此伤害+1（每局游戏限两次）。",

  ["#mobile__dangyi-invoke"] = "荡异：是否令你对 %dest 造成的伤害+1？（还剩%arg次！）",

  ["$mobile__dangyi1"] = "哼！斩首示众，以儆效尤。",
  ["$mobile__dangyi2"] = "汝等仍存异心，可见心存魏阙。",
}

dangyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangyi.name) and
      player:usedSkillTimes(dangyi.name, Player.HistoryGame) < 2 and
      player:usedSkillTimes(dangyi.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = dangyi.name,
      prompt = "#mobile__dangyi-invoke::"..data.to.id..":"..(2 - player:usedSkillTimes(dangyi.name, Player.HistoryGame)),
    })
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return dangyi
