local tiaoxin = fk.CreateSkill{
  name = "m_ex__tiaoxin",
}

Fk:loadTranslationTable{
  ["m_ex__tiaoxin"] = "挑衅",
  [":m_ex__tiaoxin"] = "出牌阶段限一次，你可以选择一名其他角色，然后除非该角色对你使用一张【杀】，否则你弃置其一张牌。",

  ["$m_ex__tiaoxin1"] = "黄口竖子，何必上阵送命？",
  ["$m_ex__tiaoxin2"] = "汝如欲大败而归，则可进军一战！",
}

tiaoxin:addEffect("active", {
  anim_type = "control",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(tiaoxin.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local use = room:askToUseCard(target, {
      skill_name = tiaoxin.name,
      pattern = "slash",
      prompt = "#tiaoxin-use:"..player.id,
      extra_data = {
        exclusive_targets = {player.id},
        bypass_times = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      if not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          skill_name = tiaoxin.name,
          flag = "he",
        })
        room:throwCard(card, tiaoxin.name, target, player)
      end
    end
  end,
})

return tiaoxin
