/^# Packages using this file: / {
  s/# Packages using this file://
  ta
  :a
  s/ lftp / lftp /
  tb
  s/ $/ lftp /
  :b
  s/^/# Packages using this file:/
}
