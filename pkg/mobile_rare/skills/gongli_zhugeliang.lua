
Fk:loadTranslationTable{
  ["zhugeliang__gongli"] = "共砺",
  [":zhugeliang__gongli"] = "锁定技，若友方友庞统在场，你执行“卧龙演策”初始可预测的牌数+1；"..
  "若友方友徐庶在场，你“卧龙演策”预测的第一张牌的结果始终视为正确。（仅斗地主和2v2模式生效）",

  [":zhugeliang__gongli_pangtong"] = "锁定技，若友方友庞统在场，你执行“卧龙演策”初始可预测的牌数+1。",
  [":zhugeliang__gongli_xushu"] = "锁定技，若友方友徐庶在场，你“卧龙演策”预测的第一张牌的结果始终视为正确。",

  ["$zhugeliang__gongli1"] = "其志远兮，当与诤友共进。",
  ["$zhugeliang__gongli2"] = "共以济世为志，今与诸兄勉之。",
}

local function GongliFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general == friend or p.deputyGeneral == friend)
    end)
end

local gongli = fk.CreateSkill {
  name = "zhugeliang__gongli",
  tags = { Skill.Compulsory },
  dynamic_desc = function(self, player)
    if GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") and GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "zhugeliang__gongli"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__pangtong") then
      return "zhugeliang__gongli_pangtong"
    elseif GongliFriend(Fk:currentRoom(), player, "m_friend__xushu") then
      return "zhugeliang__gongli_xushu"
    end
    return "dummyskill"
  end,
}

gongli:addEffect("visibility", {})

return gongli
