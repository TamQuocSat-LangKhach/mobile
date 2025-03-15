local extension = Package:new("mobile_test")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_test/skills")

Fk:loadTranslationTable{
  ["mobile_test"] = "手杀-测试服",
}

General:new(extension, "zhangbu", "wu", 4):addSkills { "chengxiong", "wangzhuan" }
Fk:loadTranslationTable{
  ["zhangbu"] = "张布",
  ["#zhangbu"] = "主胜辅义",
  --["illustrator:zhangbu"] = "",

  --["~zhangbu"] = "",
}

General:new(extension, "mobile__qinghegongzhu", "wei", 3, 3, General.Female):addSkills { "mobile__zengou", "feili" }
Fk:loadTranslationTable{
  ["mobile__qinghegongzhu"] = "清河公主",
  ["#mobile__qinghegongzhu"] = "蛊虿之谗",
  --["illustrator:mobile__qinghegongzhu"] = "",
  ["~mobile__qinghegongzhu"] = "夏侯楙徒有形表，实非良人……",
  ["!mobile__qinghegongzhu"] = "夫君自走死路，何可怨得妾身。",
}

return extension
