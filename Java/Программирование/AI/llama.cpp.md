```sh 
llama cli -m "$HOME/models/Ling3.0.gguf" \
  -dev none -ngl 0 -nr -t 6 -c 8192 --jinja -rea off \
  --temp 1.0 --top-k 20 --top-p 0.95
```

```sh
llama cli -m "$HOME/models/LFM3-1.7B-QAD-Q4_0.gguf" \
  -dev none -ngl 0 -nr -t 6 -c 8192 --jinja -rea off \
  --temp 0.1 --top-k 50 --repeat-penalty 1.1
```

```sh
llama cli -m "$HOME/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf" \
  -dev none -ngl 0 -nr -t 6 -c 8192 --jinja -rea off \
  --temp 1.0 --top-k 20 --top-p 0.95
```