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
  property string titleName: ""

  title.text: Backend.translate(titleName)
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: photoRow.width + 10
  height: 300

  Row {
    id: photoRow
    anchors.top: parent.top
    anchors.topMargin: 30
    spacing: -45

    Repeater {
      id: photoRepeater
      model: ListModel {
        id: playerInfos
      }

      Photo {
        id: photo
        // scale: 0.65
        scale: selectedItem.some(data => data.id === model.id) ? 0.75 : 0.65
        playerid: model.id
        general: model.general
        deputyGeneral: model.deputyGeneral
        role: model.role
        state: "candidate"
        screenName: model.screenName
        kingdom: model.kingdom
        seatNumber: model.seat
        selectable: !model.disabled

        Behavior on scale { NumberAnimation { duration: 100 } }
        Behavior on x { NumberAnimation { duration: 280 } }

        Image {
          visible: selectedItem.some(data => data.id === model.id)
          source: SkinBank.CARD_DIR + "chosen"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 15
          scale: 1.5
        }

        Image {
          visible: model.disabled
          source: AppPath + "/image/button/skill/locked.png"
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: -50
        }

        GlowText {
          anchors.centerIn: parent
          text: luatr("click to exchange")
          visible: selectedItem.length && !model.disabled && selectedItem[0] !== model
          font.family: fontLibian.name
          font.pixelSize: 30
          font.bold: true
          color: "#FEF7D6"
          glow.color: "#845422"
          glow.spread: 0.8
        }

        onSelectedChanged: {
          if (selectedItem.length) {
            if (selectedItem[0].id !== model.id) {
              let chosenPhoto;

              for (let i = 0; i < playerInfos.count; i++) {
                const photo = photoRepeater.itemAt(i);
                if (photo.playerid === selectedItem[0].id) {
                  chosenPhoto = photo;
                  break;
                }
                continue;
              }
              const cx = chosenPhoto.x;
              const cseat = selectedItem[0].seat;
              selectedItem[0].seat = model.seat;
              chosenPhoto.x = this.x;
              this.x = cx;
              model.seat = cseat;
            }

            selectedItem = [];
          } else {
            selectedItem = [model];
          }
        }

        Component.onCompleted: {
          this.visibleChildren[12].visible = false;
          model.disabled && (this.children[9].opacity = 1);
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
        enabled: true

        onClicked: {
          close();
          roomScene.state = "notactive";
          const playerIds = [];
          for (let i = 0; i < playerInfos.count; i++) {
            const data = playerInfos.get(i);
            playerIds[data.seat - 1] = data.id;
          }
          const reply = JSON.stringify(playerIds);
          ClientInstance.replyToServer("", reply);
        }
      }

      MetroButton {
        id: detailBtn
        enabled: selectedItem.length
        text: Backend.translate("Show General Detail")
        onClicked: {
          const { general, deputyGeneral } = selectedItem[0];
          const generals = [general];
          deputyGeneral && generals.push(deputyGeneral);

          roomScene.startCheat("GeneralDetail", { generals });
        }
      }

      MetroButton {
        Layout.fillWidth: true
        text: luatr("Cancel")
        enabled: true

        onClicked: {
          root.close();
          roomScene.state = "notactive";
          ClientInstance.replyToServer("", "");
        }
      }
    }
  }

  function loadData(data) {
    data[0].forEach(playerId => {
      const player = leval(
        `(function()
          local player = ClientInstance:getPlayerById(${playerId})
          return {
            id = player.id,
            general = player.general,
            deputyGeneral = player.deputyGeneral,
            screenName = player.player:getScreenName(),
            kingdom = player.kingdom,
            seat = player.seat,
            role = player.role,
          }
        end)()`
      );

      player.disabled = data[1].includes(player.id);
      playerInfos.append(player);
    });
    titleName = data[2];
  }
}
