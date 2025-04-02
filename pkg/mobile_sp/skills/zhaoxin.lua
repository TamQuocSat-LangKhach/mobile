local zhaoxin = fk.CreateSkill {
  name = "zhaoxin",
}

Fk:loadTranslationTable{
  ["zhaoxin"] = "昭心",
  [":zhaoxin"] = "出牌阶段限一次，你可以将任意张牌置于你的武将牌上，称为“望”（其总数不能超过3），然后摸等量的牌。你和你攻击范围内角色的摸牌阶段"..
  "结束时，其可以获得一张你选择的“望”，然后你可以对其造成1点伤害。",

  ["#zhaoxin"] = "昭心：你可以将任意张牌置为“望”，摸等量的牌（“望”至多三张）",
  ["simazhao_wang"] = "望",
  ["#zhaoxin-get"] = "昭心：你可以令 %src 选择一张“望”令你获得，然后其可以对你造成1点伤害",
  ["#zhaoxin-give"] = "昭心：选择一张“望”令 %dest 获得",
  ["#zhaoxin-damage"] = "昭心：是否对 %dest 造成1点伤害？",

  ["$zhaoxin1"] = "吾心昭昭，何惧天下之口！",
  ["$zhaoxin2"] = "公此行欲何为，吾自有量度。",
}

zhaoxin:addEffect("active", {
  anim_type = "drawcard",
  derived_piles = "simazhao_wang",
  min_card_num = 1,
  target_num = 0,
  prompt = "#zhaoxin",
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0 and #player:getPile("simazhao_wang") < 3
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 3 - #player:getPile("simazhao_wang")
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = zhaoxin.name
    local player = effect.from
    player:addToPile("simazhao_wang", effect.cards, true, skillName)
    if player:isAlive() then
      player:drawCards(#effect.cards, skillName)
    end
  end,
})

zhaoxin:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(zhaoxin.name) and
      (target == player or player:inMyAttackRange(target)) and
      target.phase == Player.Draw and
      #player:getPile("simazhao_wang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(target, { skill_name = zhaoxin.name, prompt = "#zhaoxin-get:" .. player.id })
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhaoxin.name
    local room = player.room
    room:doIndicate(target, { player })
    local card = room:askToCards(
      player,
      {
        min_num = 1,
        max_num = 1,
        skill_name = skillName,
        cancelable = false,
        pattern = ".|.|.|simazhao_wang|.|.",
        prompt = "#zhaoxin-give::" .. target.id,
        expand_pile = "simazhao_wang",
      }
    )

    if #card > 0 then
      card = card[1]
    else
      card = table.random(player:getPile("simazhao_wang"))
    end
    room:obtainCard(target, card, true, fk.ReasonPrey, target, skillName)
    if not (player:isAlive() and target:isAlive()) then
      return false
    end

    if room:askToSkillInvoke(player, { skill_name = skillName, prompt = "#zhaoxin-damage::" .. target.id }) then
      room:doIndicate(player, { target })
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

return zhaoxin
