# Each sample reads /proc/*/stat and /proc/*/statm in one grep. An app is
# grouped under its topmost ancestor running the same executable, so
# Chromium's helpers count as Chromium but a build in a terminal does not
# count as the terminal. Memory is resident minus shared: summing RSS counts
# shared pages once per process. CPU includes the time a process reaped from
# children, less what those children were already charged, so a build of
# short-lived compilers is not invisible.
#
# Run with -v top=<rows> -v interval=<seconds>.

function sample(   line, f, n, colon, pid, open, cmd, missing, stale) {
  getline line < "/proc/stat"
  close("/proc/stat")
  split(line, f, " ")
  total = 0
  for (n = 2; n <= 9; n++)
    total += f[n]

  split("", comm); split("", ppid); split("", ticks); split("", memory)
  cmd = "grep -aH . /proc/[0-9]*/stat /proc/[0-9]*/statm 2>/dev/null"
  while ((cmd | getline line) > 0) {
    colon = index(line, ":")
    split(substr(line, 7, colon - 7), f, "/")
    pid = "p" f[1]
    if (f[2] == "statm") {
      split(substr(line, colon + 1), f, " ")
      memory[pid] = (f[2] - f[3]) * page
      continue
    }
    open = index(line, "(")
    n = split(line, f, /[)] /)
    comm[pid] = substr(line, open + 1, length(line) - length(f[n]) - open - 2)
    split(f[n], f, " ")
    ppid[pid] = "p" f[2]
    ticks[pid] = f[12] + f[13] + f[14] + f[15]
    if (pid == self || ppid[pid] == self)
      delete comm[pid]
    else if (pid == "p2" || ppid[pid] == "p2") {
      comm[pid] = "Kernel"
      exe[pid] = ""
    }
  }
  close(cmd)

  for (pid in exe)
    if (!(pid in comm))
      stale[pid] = 1
  for (pid in stale)
    delete exe[pid]

  for (pid in comm)
    if (!(pid in exe))
      missing = missing " /proc/" substr(pid, 2) "/exe"
  if (missing != "") {
    cmd = "stat -c %N" missing " 2>/dev/null"
    while ((cmd | getline line) > 0) {
      match(line, /[0-9]+/)
      pid = "p" substr(line, RSTART, RLENGTH)
      exe[pid] = match(line, /-> .*/) ? substr(line, RSTART + 4, RLENGTH - 5) : ""
      sub(/ [(]deleted[)]$/, "", exe[pid])
    }
    close(cmd)
  }
}

function report(   pid, app, cpu, mem, count) {
  split("", roots)
  for (pid in comm) {
    app = pid
    while ((ppid[app] in comm) && exe[app] != "" && exe[ppid[app]] == exe[app])
      app = ppid[app]
    if (app == pid && comm[app] != "Kernel")
      roots[comm[app]] = roots[comm[app]] "," substr(pid, 2)
    cpu[comm[app]] += ticks[pid] - ((pid in before) ? before[pid] : 0)
    mem[comm[app]] += memory[pid]
    count[comm[app]]++
  }
  for (pid in before)
    if (!(pid in comm)) {
      app = beforePpid[pid]
      while ((app in beforePpid) && !(app in comm))
        app = beforePpid[app]
      if (!(app in comm))
        continue
      while ((ppid[app] in comm) && exe[app] != "" && exe[ppid[app]] == exe[app])
        app = ppid[app]
      cpu[comm[app]] -= before[pid]
    }
  emit("cpu", cpu, count, 100 / elapsed, "%.2f")
  emit("memory", mem, count, 1, "%.0f")
  print "end"
  fflush()
}

function emit(kind, values, count, scale, format,   i, name, best, used) {
  for (i = 0; i < top; i++) {
    best = ""
    for (name in values)
      if (!(name in used) && values[name] > 0 && (best == "" || values[name] > values[best]))
        best = name
    if (best == "")
      return
    used[best] = 1
    print kind, sprintf(format, values[best] * scale), count[best], substr(roots[best], 2), best
  }
}

BEGIN {
  OFS = sprintf("%c", 9)
  self = "p" PROCINFO["pid"]
  "getconf PAGESIZE" | getline page
  sample()
  wait = 0.5
  while (1) {
    split("", before); split("", beforePpid)
    for (pid in ticks) {
      before[pid] = ticks[pid]
      beforePpid[pid] = ppid[pid]
    }
    elapsed = total
    system("sleep " wait)
    wait = interval
    sample()
    elapsed = total - elapsed
    if (elapsed > 0)
      report()
  }
}
