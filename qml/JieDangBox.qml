// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var selectedItem: []
  property string mainGeneral
  property var deputyGenerals: []
  property string disabledGeneral: ""

  title.text: Backend.translate("$JieDang")
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 460
  height: 360

  ColumnLayout {
    anchors.top: root.top
    anchors.topMargin: 30
    anchors.left: root.left
    anchors.leftMargin: 10
    width: root.width - 20
    spacing: 10

    RowLayout {
      id: mainGeneralRow
      width: parent.width
      spacing: parent.width / 2.8

      Rectangle {
        Layout.alignment: Qt.AlignVCenter
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: Backend.translate("mainGeneral")
          color: "white"
          font.family: fontLibian.name
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      GeneralCardItem {
        Layout.alignment: Qt.AlignHCenter

        name: mainGeneral
        ToolTip {
          id: descriptionTip
          x: 20
          y: 20
          text: ""
          visible: false
          font.family: fontLibian.name
          font.pixelSize: 14
        }

        onClicked: {
          descriptionTip.show(Backend.translate(`:${mainGeneral}-specificSkillDesc`));
        }
      }
    }

    RowLayout {
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: Backend.translate("deputyGeneral")
          color: "white"
          font.family: fontLibian.name
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      RowLayout {
        spacing: 10

        Repeater {
          id: deputyGeneralsRepeater
          model: deputyGenerals

          GeneralCardItem {
            name: modelData
            selectable: disabledGeneral !== modelData

            Rectangle {
              id: taunt
              x: 10
              y: -5
              color: "#F2ECD7"
              radius: 4
              opacity: 0
              width: parent.width + 10
              height: childrenRect.height + 8
              property string text: ""
              visible: false
              Text {
                width: parent.width - 8
                x: 4
                y: 4
                text: parent.text
                wrapMode: Text.WrapAnywhere
                font.family: fontLibian.name
                font.pixelSize: 14
              }
              SequentialAnimation {
                id: tauntAnim
                PropertyAnimation {
                  target: taunt
                  property: "opacity"
                  to: 0.9
                  duration: 200
                }
                NumberAnimation {
                  duration: 3500
                }
                PropertyAnimation {
                  target: taunt
                  property: "opacity"
                  to: 0
                  duration: 150
                }
                onFinished: taunt.visible = false;
              }
            }

            ToolTip {
              id: descriptionTip
              x: 20
              y: 20
              text: ""
              visible: false
              font.family: fontLibian.name
              font.pixelSize: 14
            }

            Image {
              visible: selectedItem.includes(modelData)
              source: SkinBank.CARD_DIR + "chosen"
              anchors.horizontalCenter: parent.horizontalCenter
              y: 90
              scale: 1.25
            }

            onClicked: {
              descriptionTip.show(Backend.translate(`:${modelData}-specificSkillDesc`));
            }

            onSelectedChanged: {
              selectedItem = [modelData];
            }

            function addTaunt(text) {
              taunt.text = text;
              taunt.visible = true;
              tauntAnim.restart();
            }
          }
        }
      }
    }
  }

  Item {
    id: buttonArea
    anchors.fill: parent
    anchors.bottomMargin: 10
    height: 40

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      spacing: 8

      MetroButton {
        Layout.fillWidth: true
        text: Backend.translate("OK")
        enabled: selectedItem.length

        onClicked: {
          close();
          roomScene.state = "notactive";
          const reply = JSON.stringify(
            {
              general: selectedItem[0]
            }
          );
          ClientInstance.replyToServer("", reply);
        }
      }
    }
  }

  function loadData(data) {
    mainGeneral = data[0];
    deputyGenerals = data[1];
    disabledGeneral = data[2];

    if (disabledGeneral) {
      const disabledIndex = deputyGenerals.findIndex(general => general === disabledGeneral);
      const itemFound = deputyGeneralsRepeater.itemAt(disabledIndex);
      itemFound.z = 2;
      itemFound.addTaunt(Backend.translate(`$${disabledGeneral}_taunt1`));

      const path = `./packages/mobile/audio/skill/${disabledGeneral}_taunt1`;
      if (Backend.exists(path + ".mp3")) {
        Backend.playSound(path);
      }
    }
  }
}
