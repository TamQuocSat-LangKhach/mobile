local skill = fk.CreateSkill {
  name = "raid_and_frontal_attack_skill",
}

Fk:loadTranslationTable{
  ["raid_and_frontal_attack_skill"] = "奇正相生",
  ["RFA_raid"] = "奇兵",
  ["RFA_frontal"] = "正兵",
  ["#RFA-response"] = "正兵：未出闪，%src 获得你牌；奇兵：未出杀，你受到其伤害",
  ["#RFA-choose"] = "正兵：%dest 不出闪，你获得其牌；奇兵：其不出杀，其受到伤害",
}

skill:addEffect("active", {
  can_use = Util.CanUse,
  target_filter = Util.CardTargetFilter,
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  on_effect = function(self, room, effect)
    local from = effect.from
    local to = effect.to
    local cardResponded = room:askToResponse(effect.to, {
      skill_name = skill.name,
      pattern = "slash,jink",
      prompt = "#RFA-response:" .. effect.from,
      cancelable = true,
      event_data = effect,
    })

    if cardResponded then
      room:responseCard({
        from = effect.to,
        card = cardResponded,
        responseToEvent = effect,
      })
    end


    local RFAChosen = (effect.extra_data or {}).RFAChosen or "RFA_raid"
    if not (cardResponded and cardResponded.trueName == (RFAChosen == "RFA_frontal" and "jink" or "slash")) then
      if RFAChosen == "RFA_raid" then
        room:damage({
          from = from,
          to = to,
          card = effect.card,
          damage = 1,
          damageType = fk.NormalDamage,
          skillName = skill.name,
        })
      else
        if not to:isNude() then
          local cardId = room:askToChooseCard(from, {
            target = to,
            flag = "he",
            skill_name = skill.name,
          })
          room:obtainCard(from, cardId, room:getCardArea(cardId) == Player.Equip, fk.ReasonPrey)
        end
      end
    end
  end,
})
skill:addEffect(fk.TargetSpecified, {
  global = true,
  priority = 0, -- game rule
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.name == "raid_and_frontal_attack"
  end,
  on_trigger = function(self, event, target, player, data)
    local choice = player.room:askToChoice(player, {
      choices = { "RFA_frontal", "RFA_raid" },
      skill_name = skill.name,
      prompt = "#RFA-choose::" .. data.to})
    data.extra_data = data.extra_data or {}
    data.extra_data.RFAChosen = choice
  end,
})

return skill
