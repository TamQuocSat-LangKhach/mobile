local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general == friend or p.deputyGeneral == friend)
    end)
end

local gongli = fk.CreateSkill {
  name = "pangtong__gongli",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    if GongliFriend(Fk:currentRoom(), player, "m_friend__zhugeliang") and GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "pangtong__gongli"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__zhugeliang") then
      return "pangtong__gongli_zhugeliang"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "pangtong__gongli_xushu"
    end
    return "dummyskill"
  end,
}

Fk:loadTranslationTable{
  ["pangtong__gongli"] = "共砺",
  [":pangtong__gongli"] = "锁定技，若友方友诸葛亮在场，你发动〖养名〗亮出牌张数+1；"..
  "若友方友徐庶在场，你发动〖养名〗后，获得一张本次亮出牌中未使用过的花色的牌。（仅斗地主和2v2模式生效）",

  [":pangtong__gongli_zhugeliang"] = "锁定技，若友方友诸葛亮在场，你发动〖养名〗亮出牌张数+1。",
  [":pangtong__gongli_xushu"] = "锁定技，若友方友徐庶在场，你发动〖养名〗后，获得一张本次亮出牌中未使用过的花色的牌。",
  ["#pangtong__gongli-prey"] = "共砺：获得其中一张牌",

  ["$pangtong__gongli1"] = "你我同有此志，更应砥砺共进。",
  ["$pangtong__gongli2"] = "三人同心，诸事可期。",
}

return gongli
