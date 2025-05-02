local extension = Package:new("mobile_test")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_test/skills")

Fk:loadTranslationTable{
  ["mobile_test"] = "手杀-测试服",
}

return extension
