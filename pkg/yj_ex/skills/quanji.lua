local quanji = fk.CreateSkill {
  name = "m_ex__quanji",
}

Fk:loadTranslationTable{
  ["m_ex__quanji"] = "权计",
  [":m_ex__quanji"] = "出牌阶段结束时，若你的手牌数大于你的体力值，或当你受到1点伤害后，你可以摸一张牌，"..
    "然后你将一张手牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”数）。",

  ["m_ex__zhonghui_power"] = "权",
  ["#m_ex__quanji-push"] = "权计：选择1张手牌作为“权”置于武将牌上",

  ["$m_ex__quanji1"] = "缓急不在一时，吾等慢慢来过。",
  ["$m_ex__quanji2"] = "善算轻重，权审其宜。",
}

---@param player ServerPlayer
local quanjiUse = function(_, _, _, player, _)
  local room = player.room
  player:drawCards(1, quanji.name)
  if not (player.dead or player:isKongcheng()) then
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = quanji.name,
      cancelable = false,
      prompt = "#m_ex__quanji-push",
    })
    player:addToPile("m_ex__zhonghui_power", card, true, quanji.name)
  end
end
quanji:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:getHandcardNum() > player.hp and
      player:hasSkill(quanji.name)
  end,
  on_use = quanjiUse
})

quanji:addEffect(fk.Damaged, {
  anim_type = "masochism",
  --FIXME:暂无按点卖血机制
  on_use = quanjiUse,
})


quanji:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(quanji.name) then
      return #player:getPile("m_ex__zhonghui_power")
    else
      return 0
    end
  end,
})


return quanji
