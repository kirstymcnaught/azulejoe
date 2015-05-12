import QtQuick 2.0

import QtQuick 2.0

// This is a custom component containing a gridview, plus
// all the state and visuals to manage 2D switch access
// scanning.
// The key differences between using a normal gridview and
// this one, is that:
// - You must specify the number of rows/columns, and the
//   rest of the sizing is automatic.
// - You should hook up your switch input to the next() function.
// - Any click event you want to respond to should be done by
//   connecting to signal clicked(row, col) rather than putting
//   a mouse area in the individual delegate. I haven't figured
//   out a more sane way of doing this, unfortunately.
// - When you specify a delegate, you must access it's properties
//   via the special property name "modelData", i.e.
//
// model:    ListModel {
//             ListElement { name: "bob" }
//           }
// delegate: Text {
//             text: modelData.name // NOT just "name".
//           }
//
// If you need to access any other gridview properties, add aliases to
// the top level Rectangle.
//
Rectangle {
    id: root

    anchors.fill: parent

    color: "transparent"


    // Override this function to mark cells as ignoreable.
    function isCellValid(row, col) {
        return true;
    }

    function isRowValid(row) {
        for (var i=0; i < numCols; i++) {
            if (isCellValid(row, i)) {
                return true;
            }
        }
        return false;
    }

    // row and column are zero-indexed
    signal clicked(int row, int col);

    property int scanInterval: 1000
    property int numRows: 5
    property int numCols: 5
    // This is the colour of the scan outline
    property string highlightColour: "blue"
    // This is the colour a row/item goes briefly to
    // show it's been selected
    property string selectionColour: "yellow"

    property alias delegate: gridView.internalDelegate;
    property alias model: gridView.internalModel;

    // If this is false, the only way to 'click' on an item is
    // through the scanning mechanism.
    property bool supportMouseClicksAlso: true

    function next() {
        console.log("next!");
        if (scanner.state == "row") {
            console.log("going into row-selected state");
            scanner.state = "row-selected"
            scanner.selectedCol = 0;            
        }
        else if (scanner.state == "item") {
            console.log("going into item-selected state");
            scanner.state = "item-selected"
            root.clicked(scanner.selectedRow,
                             scanner.selectedCol);
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
                z: 100
                anchors.fill: parent
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
                    if (root.supportMouseClicksAlso) {
                        root.clicked(row, col);
                    }
                }
            }

            // Some properties that help us work out what to draw
            property int barSize: 10
            property bool rowSelected: (row === scanner.selectedRow)
            property bool colSelected: (col === scanner.selectedCol)
            property bool selectingRow: (scanner.state == "row")
            property bool selectingItem: (scanner.state == "item")
            property bool itemSelected: (scanner.state == "item-selected" &&
                                         rowSelected && colSelected)
            property bool rowSelectedBriefly: (scanner.state == "row-selected" &&
                                               rowSelected)


            // Top and bottom of cell.
            Item {
                z: 500
                visible: rowSelected
                opacity: (selectingRow || colSelected || itemSelected || rowSelectedBriefly)
                         ? 1 : 0.2

                Rectangle {
                    width: gridView.cellWidth
                    height: barSize
                    color: (itemSelected || rowSelectedBriefly)
                           ? selectionColour : highlightColour
                }
                Rectangle {
                    width: gridView.cellWidth
                    height: barSize
                    y: gridView.cellHeight - barSize
                    color: (itemSelected || rowSelectedBriefly)
                           ? selectionColour : highlightColour
                }
            }

            // Left and right of cell
            Item {
                z: 500
                id: lr
                // This is the shared visibility logic, but each
                // bar adds it's own.
                visible: rowSelected

                Rectangle {
                    width: barSize
                    height: gridView.cellHeight
                    color: itemSelected ? selectionColour : highlightColour
                    visible: (selectingRow && col === 0) ||
                             (selectingItem && colSelected) ||
                             itemSelected
                }
                Rectangle {
                    width: barSize
                    height: gridView.cellHeight
                    x: gridView.cellWidth - barSize
                    color: itemSelected ? selectionColour : highlightColour
                    visible: (selectingRow && col === numRows -1) ||
                             (selectingItem && colSelected) ||
                             itemSelected
                }
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
                //console.log("timer");
                if (scanner.state === "row") {
                  //  console.log("incrementing row count");
                    scanner.selectedRow++;
                    scanner.selectedRow %= numRows;

                    // Keep going if no cells on this row are valid
                    while (!isRowValid(scanner.selectedRow)) {
                       scanner.selectedRow++;
                       scanner.selectedRow %= numRows;
                    }
                }
                else if (scanner.state === "row-selected") {
                    console.log("going into item state");
                    scanner.state = "item"
                }
                else if (scanner.state === "item") {
                    //console.log("incrementing col count");
                    scanner.selectedCol++;
                    scanner.selectedCol %= numCols;

                    // Keep going if you're not on a valid cell
                    while (!isCellValid(scanner.selectedRow,
                                        scanner.selectedCol)) {
                        scanner.selectedCol++;
                        scanner.selectedCol %= numCols;
                    }
                }
                else if (scanner.state === "item-selected") {
                    console.log("going into row state");
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
            // We've picked a row. We'll be in this state for one cycle,
            // for user feedback
            State {
                name: "row-selected"
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

//        transitions:  [
//            Transition {
//                from: "item"; to: "item-selected";
//                ColorAnimation { duration: 500 }
//            },
//            Transition {
//                from: "row"; to: "row-selected";
//                ColorAnimation { duration: 500 }
//            }
//        ]
    }
    Component.onCompleted: {
        console.log("Completed ScanningGridView.");
        console.log("selectedRow=" + scanner.selectedRow);
        console.log("selectedRow=" + scanner.selectedCol);
    }
}

