.pragma library

function indexForId(entries, transcriptId) {
  for (var index = 0; index < entries.length; index++)
    if (entries[index].id === transcriptId) return index
  return -1
}

function retainedId(entries, transcriptId) {
  return indexForId(entries, transcriptId) === -1
    ? entries.length ? entries[0].id : ""
    : transcriptId
}

function displayTime(timestamp) {
  var value = new Date(timestamp)
  return isNaN(value.getTime()) ? String(timestamp) : Qt.formatDateTime(value, "yyyy-MM-dd HH:mm")
}

function metadata(entry) {
  if (!entry) return ""
  var details = [displayTime(entry.created_at)]
  if (entry.language) details.push(entry.language.toUpperCase())
  if (entry.model_id) details.push(entry.model_id)
  return details.join("  ·  ")
}
