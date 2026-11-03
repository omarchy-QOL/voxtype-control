import QtQuick
import qs.Commons
import qs.Ui as Ui

Ui.Dropdown {
  id: root

  required property string selectedValue

  // Upstream assigns value when selecting; keep the owner's input bound.
  Binding { target: root; property: "value"; value: root.selectedValue }

  showLabel: false
  rowHeight: Style.space(26)
  implicitWidth: Style.space(112)
}
