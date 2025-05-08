
local tanfeng = fk.CreateSkill{
  name = "tanfeng",
}

Fk:loadTranslationTable{
  ["tanfeng"] = "探锋",
  [":tanfeng"] = "准备阶段，你可以选择任意项：1.弃置一名角色至多两张牌，然后若其手牌数不大于你，你跳过摸牌阶段；2.对一名角色造成1点伤害，"..
  "然后若其体力值不大于你，你跳过出牌阶段。",

  ["#tanfeng1-choose"] = "探锋：弃置一名角色至多两张牌，若其手牌数不大于你则跳过摸牌阶段",
  ["#tanfeng2-choose"] = "探锋：对一名角色造成伤害，若其体力值不大于你则跳过出牌阶段",

  ["$tanfeng1"] = "",
  ["$tanfeng2"] = "",
}

tanfeng:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tanfeng.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    if #targets > 0 then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#tanfeng1-choose",
        skill_name = tanfeng.name,
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, { tos = to, choice = "tanfeng1" })
        return true
      end
    end
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#tanfeng2-choose",
      skill_name = tanfeng.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to, choice = "tanfeng2" })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "tanfeng1" then
      if to == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 2,
          include_equip = true,
          skill_name = tanfeng.name,
          cancelable = false,
        })
      else
        local cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = 2,
          flag = "he",
          skill_name = tanfeng.name,
        })
        room:throwCard(cards, tanfeng.name, to, player)
      end
      if to:getHandcardNum() <= player:getHandcardNum() then
        player:skip(Player.Draw)
      end
      if player.dead then return end
    end
    if choice == "tanfeng1" then
      to = room:askToChoosePlayers(player, {
        targets = room.alive_players,
        min_num = 1,
        max_num = 1,
        prompt = "#tanfeng2-choose",
        skill_name = tanfeng.name,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
      else
        return
      end
    end
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = tanfeng.name,
    }
    if to.hp <= player.hp then
      player:skip(Player.Play)
    end
  end,
})

return tanfeng
