local mobileXiaoxi = fk.CreateSkill {
  name = "mobile__xiaoxi",
}

Fk:loadTranslationTable{
  ["mobile__xiaoxi"] = "骁袭",
  [":mobile__xiaoxi"] = "你可以将一张黑色牌当【杀】使用或打出。",

  ["$mobile__xiaoxi1"] = "看你如何躲过！",
  ["$mobile__xiaoxi2"] = "小贼受死！",
}

mobileXiaoxi:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("slash")
    c.skillName = mobileXiaoxi.name
    c:addSubcard(cards[1])
    return c
  end,
})

return mobileXiaoxi
