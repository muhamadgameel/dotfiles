[LOG] Registered timeout rule for 60s:
      on-timeout: hyprctl dispatch 'hl.dsp.dpms({action = "off"})'
      on-resume: hyprctl dispatch 'hl.dsp.dpms({action = "on"})'
      ignore_inhibit: true
      condition_cmd: pidof hyprlock
      condition_retry: 60