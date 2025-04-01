local mobileXushen = fk.CreateSkill {
  name = "mobile__xushen",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["mobile__xushen"] = "许身",
  [":mobile__xushen"] = "限定技，出牌阶段，你可以失去等同于场上存活男性角色数的体力值；若你因此进入濒死状态，" ..
  "则你脱离濒死状态后，你可以令使你脱离濒死的角色获得〖武圣〗和〖当先〗。",

  ["#mobile__xushen_delay"] = "许身",
  ["#mobile__xushen-invoke"] = "许身：你可以令 %src 获得〖武圣〗和〖当先〗",

  ["$mobile__xushen1"] = "你我相遇于此，应当彼此珍惜。",
  ["$mobile__xushen2"] = "携子之手，与子共闯天涯。",
}

mobileXushen:addEffect("active", {
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player)
    return
      player:usedSkillTimes(mobileXushen.name, Player.HistoryGame) == 0 and
      player.hp > 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p:isMale() end)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if p:isMale() then
        n = n + 1
      end
    end
    room:loseHp(player, n, mobileXushen.name)
  end,
})

mobileXushen:addEffect(fk.AfterDying, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:isAlive() and data.extra_data and data.extra_data.mobile__xushen
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.extra_data.mobile__xushen)
    if room:askToSkillInvoke(player, { skill_name = mobileXushen.name, prompt = "#mobile__xushen-invoke:" .. to.id }) then
      room:doIndicate(player, { to })
      room:handleAddLoseSkills(to, "wusheng|dangxian")
    end
  end,
})

mobileXushen:addEffect(fk.HpChanged, {
  can_refresh = function (self, event, target, player, data)
    return player == target and player.hp > 0 and data.num > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local recover_event = room.logic:getCurrentEvent():findParent(GameEvent.Recover)
    if recover_event then
      local dat = recover_event.data
      if dat.recoverBy then
        local hpchange_event = room.logic:getCurrentEvent():findParent(GameEvent.ChangeHp, false)
        local skillName = hpchange_event and hpchange_event.data.skillName
        if skillName == "mobile__xushen" then
          local dying_event = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
          if dying_event then
            local dying = dying_event.data
            dying.extra_data = dying.extra_data or {}
            dying.extra_data.mobile__xushen = dat.recoverBy.id
          end
        end
      end
    end
  end,
})

return mobileXushen
