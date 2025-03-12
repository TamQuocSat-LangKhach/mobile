local extension = Package:new("mobile_sp")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_sp/skills")

Fk:loadTranslationTable{
  ["mobile_sp"] = "手杀-SP",
}

--SP1：-
--SP2：孙鲁育
local sunluyu = General:new(extension, "mobile__sunluyu", "wu", 3, 3, General.Female)
sunluyu:addSkills { "mobile__meibu", "mobile__mumu" }
sunluyu:addRelatedSkill("mobile__zhixi")
Fk:loadTranslationTable{
  ["mobile__sunluyu"] = "孙鲁育",
  ["#mobile__sunluyu"] = "舍身饲虎",
  ["illustrator:mobile__sunluyu"] = "鬼画府",

  ["~mobile__sunluyu"] = "今朝遭诬含冤去，他日丹青还我清！",
}

--SP3：-
--SP4：贺齐

--SP5：马忠
General:new(extension, "mazhong", "shu", 4):addSkills { "fuman" }
Fk:loadTranslationTable{
  ["mazhong"] = "马忠",
  ["#mazhong"] = "笑合南中",
  ["designer:mazhong"] = "Virgopaladin",
  ["illustrator:mazhong"] = "Thinking",

  ["~mazhong"] = "丞相不在，你们竟然……",
}

--SP6：董承 卫温诸葛直 
--SP7：陶谦 杨仪 关索
local guansuo = General:new(extension, "guansuo", "shu", 4)
guansuo:addSkills { "zhengnan", "xiefang" }
guansuo:addRelatedSkills { "wusheng", "dangxian", "zhiman" }
Fk:loadTranslationTable{
  ["guansuo"] = "关索",
  ["#guansuo"] = "倜傥孑侠",
  ["designer:guansuo"] = "千幻",
  ["illustrator:guansuo"] = "depp",

  ["$wusheng_guansuo"] = "逆贼，可识得关氏之勇？",
  ["$dangxian_guansuo"] = "各位将军，且让小辈先行出战！",
  ["$zhiman_guansuo"] = "蛮夷可抚，不可剿！",
  ["~guansuo"] = "只恨天下未平，空留遗志。",
}

--SP8：审配
--SP9：苏飞 贾逵 张恭 许贡 曹婴 鲍三娘 徐荣
--SP10：丁原 傅肜 邓芝 陈登 张翼 张琪瑛 公孙康 周群
--SP11：阎圃 马元义 毛玠 傅佥 阮慧 马日磾 王濬
--SP12：赵统赵广 刘晔 李丰 诸葛果 胡金定 王元姬 羊徽瑜 杨彪 司马昭
--SP13：曹嵩 裴秀 杨阜 彭羕 牵招 郭女王 韩遂 阎象 李遗
--SP14：吴班 鲍信 胡班 陈珪 霍峻 木鹿大王 蒋干 杨奉 来敏
--未分组：SP甄姬 甘夫人 王经

return extension
