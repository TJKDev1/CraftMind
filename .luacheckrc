std = "lua52"
max_line_length = false

globals = {
  "fs",
  "shell",
  "term",
  "colors",
  "colours",
  "settings",
  "http",
  "textutils",
  "rednet",
  "peripheral",
  "turtle",
  "pocket",
  "commands",
  "multishell",
  "sleep",
  "write",
  "read",
}

read_globals = {
  os = {
    fields = {
      "epoch",
      "getComputerID",
      "getComputerLabel",
    },
  },
}
