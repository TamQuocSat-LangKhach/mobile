local xuetu = fk.CreateSkill {
  name = "xuetu",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["xuetu"] = "血途",
  [":xuetu"] = "转换技，出牌阶段限一次，你可以：阳，令一名角色回复1点体力；阴，令一名角色摸两张牌。" ..
  "<br><strong>二级</strong>：出牌阶段各限一次，你可以选择一项：1.令一名角色回复1点体力；2.令一名角色摸两张牌。" ..
  "<br><strong>三级</strong>：转换技，出牌阶段限一次，你可以：阳，回复1点体力并令一名角色弃置两张牌；阴，摸一张牌并对一名角色造成1点伤害。",

  ["#xuetu_yang"] = "血途：你可令一名角色回复1点体力",
  ["#xuetu_yin"] = "血途：你可令一名角色摸两张牌",

  ["$xuetu1"] = "天子仪仗在此，逆贼安扰圣驾。",
  ["$xuetu2"] = "末将救驾来迟，还望陛下恕罪。",
}

xuetu:addEffect("active", {
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function(self, player)
    return "#xuetu_" .. player:getSwitchSkillState(xuetu.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(xuetu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return
      #selected == 0 and
      not (player:getSwitchSkillState(xuetu.name) == fk.SwitchYang and not to_select:isWounded())
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = xuetu.name
    local player = effect.from
    local target = effect.tos[1]

    if player:getSwitchSkillState(skillName, true) == fk.SwitchYang then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    else
      target:drawCards(2, skillName)
    end
  end,
})

return xuetu
