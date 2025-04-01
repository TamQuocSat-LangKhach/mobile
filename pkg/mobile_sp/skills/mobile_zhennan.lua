local mobileZhennan = fk.CreateSkill {
  name = "mobile__zhennan",
}

Fk:loadTranslationTable{
  ["mobile__zhennan"] = "镇南",
  [":mobile__zhennan"] = "当一张牌指定多个目标后，若你为此牌目标之一且此牌指定目标数大于使用者当前体力值，则你可以弃置一张牌，对此牌使用者造成1点伤害。",

  ["#mobile__zhennan-discard"] = "镇南：你可以弃置一张牌，对 %src 造成1点伤害",

  ["$mobile__zhennan1"] = "怎可让你再兴风作浪？",
  ["$mobile__zhennan2"] = "南中由我和夫君一起守护！",
}

mobileZhennan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      player:hasSkill(self) and
      not player:isNude() and
      data.firstTarget and
      #data.use.tos > 1 and
      data.from:isAlive() and
      table.contains(data.use.tos, player) and
      #data.use.tos > data.from.hp
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = mobileZhennan.name,
        prompt = "#mobile__zhennan-discard:" .. data.from.id,
        skip = true,
      }
    )
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileZhennan.name
    local room = player.room
    local from = data.from
    room:throwCard(event:getCostData(self), skillName, player, player)
    room:damage{
      from = player,
      to = from,
      damage = 1,
      skillName = skillName,
    }
  end,
})

return mobileZhennan
