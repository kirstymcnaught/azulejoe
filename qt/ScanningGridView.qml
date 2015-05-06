import QtQuick 2.0

import QtQuick 2.0

// This is a custom component containing a gridview, plus
// all the state and visuals to manage 2D switch access
// scanning.
// The key differences between using a normal gridview and
// this one, is that:
// - you must specify the number of rows/columns, and the
//   rest of the sizing is automatic.
// - when you specify a delegate, you must access it's properties
//   via the special property name "modelData", i.e.
//
// model: ListModel {
//          ListElement { name: "bob" }
//        }
// delegate: Text {
//             text: modelData.name
//           }
//
// If you need to access any other gridview properties, add aliases to
// the top level Rectangle.
//
Rectangle {
    anchors.fill: parent

    color: "purple"

    property int scanInterval: 1000
    property int numRows: 5
    property int numCols: 5
    property alias delegate: gridView.internalDelegate;
    property alias model: gridView.internalModel;

    function next() {
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

        property Component internalDelegate;
        property variant internalModel;

        delegate: Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            property int col: index % numRows
            property int row: index/numCols //implicit floor()

            // This is the delegate that the user has specified.
            // It's specified as with any loader, *except* that
            // model data must be referred to by modelData.propertyname
            // rather than just propertyname.
            Loader {
                anchors.fill: parent
                z: 200
                sourceComponent: gridView.internalDelegate

                // This is required to move the mode into scope in the loader.
                property variant modelData: model
            }

            // Everything below are components to show scanning.
            MouseArea {
                id: mouseArea
                width: gridView.cellWidth*0.95
                height: gridView.cellHeight*0.95
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    console.log ("row = "+row);
                    console.log ("col = "+col);
                    console.log ("index = "+index);
                }
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
            }
        }
        model: internalModel

    }

    // This item manages the scanning state.
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
}

