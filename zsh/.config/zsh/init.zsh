# Load custom completions
fpath+=${0:a:h}/completions

# Load configs
sources=(
  "settings"
  "input"
  "aliases"
  "env"
  "completion"
)

for src in ${sources[@]}; do
  source ${0:a:h}/core/$src.zsh
done
