# Stored value fixtures

JSON written by released versions of the types marked `StoredValue`. The apps
store these shapes (SwiftData blobs and raw values, raw logs, preferences), so
every released fixture must keep decoding. `StoredValuesTests` decodes them all.

- Add a folder named after the release whenever a stored shape changes.
- Never edit a released folder: it is what existing installs hold.
