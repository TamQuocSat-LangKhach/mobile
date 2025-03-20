local huoji = fk.CreateSkill {
  name = "m_ex__huoji",
}

Fk:loadTranslationTable{
  ["m_ex__huoji"] = "火计",
  [":m_ex__huoji"] = "你可以将一张红色牌当【火攻】使用。",

  ["#m_ex__huoji"] = "火计：你可以将一张红色牌当【火攻】使用",

  ["$m_ex__huoji1"] = "此火可助我军大获全胜。",
  ["$m_ex__huoji2"] = "燃烧吧！",
}

huoji:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "fire_attack",
  prompt = "#huoji",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire_attack")
    card.skillName = huoji.name
    card:addSubcard(cards[1])
    return card
  end,
})

return huoji
