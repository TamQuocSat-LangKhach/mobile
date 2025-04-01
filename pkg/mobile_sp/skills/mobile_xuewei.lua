local mobileXuewei = fk.CreateSkill {
  name = "mobile__xuewei",
}

Fk:loadTranslationTable{
  ["mobile__xuewei"] = "血卫",
  [":mobile__xuewei"] = "准备阶段，你可以标记一名其他角色。若如此做，直到你下回合开始前，你标记的角色第一次受到伤害时，你防止此伤害并受到等量伤害，"..
  "然后你对伤害来源造成等量的同属性伤害。",

  ["#mobile__xuewei-choose"] = "血卫：秘密选择一名角色，防止其下次受到的伤害，你受到等量伤害，并对伤害来源造成伤害",
  ["#mobile__xuewei_trigger"] = "血卫",

  ["$mobile__xuewei1"] = "老夫一息尚存，吴狗便动不得主公分毫！",
  ["$mobile__xuewei2"] = "吴狗何在，大汉将军傅肜在此！",
}

mobileXuewei:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
      return target == player and player:hasSkill(mobileXuewei.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askToChoosePlayers(
      player,
      {
        targets = player.room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#mobile__xuewei-choose",
        skill_name = mobileXuewei.name,
        no_indicate = true,
      }
    )
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, mobileXuewei.name, event:getCostData(self).id)
  end,
})

mobileXuewei:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(mobileXuewei.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, mobileXuewei.name, 0)
  end,
})

mobileXuewei:addEffect(fk.DamageInflicted, {
  is_delay_effect = true,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:getMark(mobileXuewei.name) == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileXuewei.name
    local room = player.room
    room:setPlayerMark(player, skillName, 0)

    local damage = data.damage
    data:preventDamage()
    room:damage{
      to = player,
      damage = damage,
      skillName = skillName,
    }
    if data.from and data.from:isAlive() then
      room:damage{
        from = player,
        to = data.from,
        damage = damage,
        damageType = data.damageType,
        skillName = skillName,
      }
    end
  end,
})

return mobileXuewei
