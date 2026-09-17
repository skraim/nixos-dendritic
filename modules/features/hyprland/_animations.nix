''
hl.curve("fast-stiff", {
  ["dampening"] = 50,
  ["mass"] = 1,
  ["stiffness"] = 700,
  ["type"] = "spring"
})

-- settings.animation
hl.animation({
  ["enabled"] = true,
  ["leaf"] = "global",
  ["speed"] = 1,
  ["spring"] = "fast-stiff"
})
hl.animation({
  ["enabled"] = true,
  ["leaf"] = "windows",
  ["speed"] = 1,
  ["spring"] = "fast-stiff"
})
hl.animation({
  ["enabled"] = true,
  ["leaf"] = "windowsOut",
  ["speed"] = 1,
  ["spring"] = "fast-stiff",
  ["style"] = "popin 80%"
})
hl.animation({
  ["enabled"] = true,
  ["leaf"] = "fade",
  ["speed"] = 1,
  ["spring"] = "fast-stiff"
})
hl.animation({
  ["enabled"] = true,
  ["leaf"] = "workspaces",
  ["speed"] = 1,
  ["spring"] = "fast-stiff",
  ["style"] = "slidefadevert 20%"
})
hl.animation({
  ["enabled"] = true,
  ["leaf"] = "specialWorkspace",
  ["speed"] = 1,
  ["spring"] = "fast-stiff",
  ["style"] = "fade"
})
hl.animation({
  ["enabled"] = false,
  ["leaf"] = "layers"
})
hl.animation({
  ["enabled"] = false,
  ["leaf"] = "layersIn"
})
''
