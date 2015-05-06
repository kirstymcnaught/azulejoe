import QtQuick 2.0

Rectangle {
    width: 600
    height: 400
    color: "purple"
    focus: true

    property int scanInterval: 1000
    property int numRows: 5
    property int numCols: 5

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

        cellWidth: width / numCols
        cellHeight: height / numRows

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
                id: highlight
                width: gridView.cellWidth
                height: gridView.cellHeight
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                color: (row === scanner.selectedRow) ? "yellow" : "white"
                opacity: (scanner.state == "item" &&
                          col === scanner.selectedCol &&
                          row === scanner.selectedRow) ? 0.8 : 0.5
                border.width: (scanner.state == "item-selected" &&
                               col === scanner.selectedCol &&
                               row === scanner.selectedRow) ? 10 : 0
                border.color: "yellow"
                //visible: mouseArea.pressedButtons
            }
            Rectangle {
                id: item
                width: gridView.cellWidth*0.9
                height: gridView.cellHeight*0.9
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                color:"white"
                opacity: 1
                border.width: (scanner.state == "item-selected" &&
                               col === scanner.selectedCol &&
                               row === scanner.selectedRow) ? 10 : 0
                border.color: "yellow"
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
            interval: scanInterval; running: true; repeat: true

            onTriggered: {
                if (scanner.state === "row") {
                    scanner.selectedRow++;
                    scanner.selectedRow %= numRows;
                }
                else if (scanner.state === "item") {
                    scanner.selectedCol++;
                    scanner.selectedCol %= numCols;
                }
                else if (scanner.state === "item-selected") {
                    scanner.state = "row"
                }
            }
        }

        state: "row"

        states: [
            // We're ready for a row to be selected.
            State {
                name: "row"
            },
            // We've picked a row and we're ready for an item to be selected.
            State {
                name: "item"
            },
            // We've picked an item. We'll be in this state for one cycle,
            // for user feedback
            State {
                name: "item-selected"
            }
        ]
    }



    ListModel {
        id: testModel
        Component.onCompleted: {
            for (var i =0; i < numRows; i++) {
                for (var j =0; j < numCols; j++) {
                    testModel.append({ row: i,
                                         col: j,
                                         rowSelected: (i == 0)})
                }
            }
        }
    }

}

