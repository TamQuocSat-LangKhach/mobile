local extension = Package:new("m_yj_ex")
extension.extensionName = "mobile"

local prefix = "packages.mobile.pkg.yj_ex.skills."

extension:loadSkillSkels{
  require(prefix .. "ganlu"),
  require(prefix .. "pojun"),
  require(prefix .. "xianzhen"),
  require(prefix .. "jinjiu"),
  require(prefix .. "jieyue"),
  require(prefix .. "jieyue_active"),
  require(prefix .. "jiushi"),
  require(prefix .. "chengzhang"),
  require(prefix .. "xuanfeng"),
  require(prefix .. "xuanfeng_active"),
}

Fk:loadTranslationTable{
  ["m_yj_ex"] = "手杀-界一将成名",
  ["m_ex"] = "手杀界",
}

General:new(extension, "m_ex__wuguotai", "wu", 3, 3, General.Female):addSkills {
  "m_ex__ganlu",
  --"buyi"
}

Fk:loadTranslationTable{
  ["m_ex__wuguotai"] = "界吴国太",
  ["#m_ex__wuguotai"] = "慈怀瑾瑜",
  ["illustrator:m_ex__wuguotai"] = "李秀森",
  ["~m_ex__wuguotai"] = "诸位卿家，还请尽力辅佐仲谋啊……",

  ["$buyi_m_ex__wuguotai1"] = "有我在，定保贤婿无虞！",
  ["$buyi_m_ex__wuguotai2"] = "东吴岂容汝等儿戏！",
}

General:new(extension, "m_ex__xusheng", "wu", 4):addSkills {
  "m_ex__pojun"
}

Fk:loadTranslationTable{
  ["m_ex__xusheng"] = "界徐盛",
  ["#m_ex__xusheng"] = "江东的铁壁",
  ["cv:m_ex__xusheng"] = "金垚",
  ["illustrator:m_ex__xusheng"] = "铁杵文化",
  ["~m_ex__xusheng"] = "盛只恨，不能再为主公，破敌致胜了。",
}

General:new(extension, "m_ex__gaoshun", "qun", 4):addSkills {
  "m_ex__xianzhen",
  "m_ex__jinjiu"
}

Fk:loadTranslationTable{
  ["m_ex__gaoshun"] = "界高顺",
  ["#m_ex__gaoshun"] = "攻无不克",
  ["illustrator:m_ex__gaoshun"] = "蛋费鸡丁",
  ["~m_ex__gaoshun"] = "可叹主公知而不用啊！",
}

General:new(extension, "m_ex__yujin", "wei", 4):addSkills {
  "m_ex__jieyue"
}

Fk:loadTranslationTable{
  ["m_ex__yujin"] = "界于禁",
  ["#m_ex__yujin"] = "讨暴坚垒",
  ["illustrator:m_ex__yujin"] = "biou09",
  ["~m_ex__yujin"] = "如今临危处难，却负丞相三十年之赏识，唉……",
}

General:new(extension, "m_ex__caozhi", "wei", 3):addSkills {
  --"luoying",
  "m_ex__jiushi",
  "m_ex__chengzhang"
}

Fk:loadTranslationTable{
  ["m_ex__caozhi"] = "界曹植",
  ["#m_ex__caozhi"] = "八斗之才",
  ["illustrator:m_ex__caozhi"] = "青岛磐蒲",
  ["~m_ex__caozhi"] = "先民谁不死，知命复何忧？",

  ["$luoying_m_ex__caozhi1"] = "转蓬离本根，飘摇随长风。",
  ["$luoying_m_ex__caozhi2"] = "高树多悲风，海水扬其波。",
}

General:new(extension, "m_ex__lingtong", "wu", 4):addSkills {
  "m_ex__xuanfeng"
}

Fk:loadTranslationTable{
  ["m_ex__lingtong"] = "界凌统",
  ["#m_ex__lingtong"] = "豪情烈胆",
  ["illustrator:m_ex__lingtong"] = "青岛磐蒲",
  ["~m_ex__lingtong"] = "先……停一下吧……",
}






return extension
