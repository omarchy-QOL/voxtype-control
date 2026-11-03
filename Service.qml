import QtQuick
import "services" as Services

// Keep the manifest entry stable while feature services own external IO.
Services.ModelControlService {
  property var history: Services.TranscriptHistoryService {}
}
