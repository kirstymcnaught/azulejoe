import QtQuick 2.0

Rectangle {
    width: 600
    height: 400
    color: "purple"
    focus: true

    Keys.onSpacePressed: {
        console.log("SPACE")
        if (scanner.state == "row") {
            scanner.state = "item"
            scanner.selectedCol = 0;
        }
        else if (scanner.state == "item") {
            scanner.state = "item-selected"
        }
    }

    GridView {

        id: gridView
        z: 1

        anchors.fill: parent

        // 5x5 grid.
        // We'll add appropriate margins inside delegate
        cellWidth: width / 5
        cellHeight: height / 5

        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight
            MouseArea {
                id: mouseArea
                width: gridView.cellWidth*0.95
                height: gridView.cellHeight*0.95
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                onClicked: { console.log ("row = "+row+", col = "+col); }
            }
            Rectangle {
                width: gridView.cellWidth*0.9
                height: gridView.cellHeight*0.9
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                color: (row === scanner.selectedRow) ? "yellow" : "white"
                opacity: (scanner.state == "item" &&
                          col === scanner.selectedCol &&
                          row === scanner.selectedRow) ? 0.8 : 0.2
                border.width: (scanner.state == "item-selected" &&
                               col === scanner.selectedCol &&
                               row === scanner.selectedRow) ? 5 : 0
                border.color: "white"
                //visible: mouseArea.pressedButtons
            }
        }
        model: testModel

    }

    Item {
        id: scanner

        property int selectedRow: 0
        property int selectedCol: 0

        Timer {
            interval: 1000; running: true; repeat: true

            onTriggered: {
                if (scanner.state === "row") {
                    scanner.selectedRow++;
                    scanner.selectedRow %= 5;
                }
                else if (scanner.state === "item") {
                    scanner.selectedCol++;
                    scanner.selectedCol %= 5;
                }
                else if (scanner.state === "item-selected") {
                    scanner.state = "row"
                }
            }
        }

        state: "row"

        states: [
            State {
                name: "row"
            },
            State {
                name: "item"
            },
            State {
                name: "item-selected"
            }
        ]
    }



    ListModel {
        id: testModel
        Component.onCompleted: {
            for (var i =0; i < 5; i++) {
                for (var j =0; j < 5; j++) {
                    testModel.append({ color: "red",
                                         row: i,
                                         col: j,
                                         rowSelected: (i == 0)})
                }
            }
        }
    }

}

