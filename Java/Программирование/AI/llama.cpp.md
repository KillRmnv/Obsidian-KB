```sh 
llama cli \
  -m ~/.../Ling-3.0-tiny-Q4_K_M.gguf \
  -t 6 \
  -c 8192 \
  -n 2048 \
  -b 512 \
  --jinja \
  --temp 1.0 \
  --top-p 0.95 \
  --top-k 20
```


```sh
llama cli \
        -m ~/.../Qwen3.8-9B-Q4_K_M.gguf \
        -t 6 \
        -c 8192 \
        -n 1024 \
        -b 512 \
        --jinja \
        --reasoning off
```

```
llama cli -m /home/kirillrmnv/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
          -dev none -ngl 0 -nr -t 6 -c 8192 --temp 0
```