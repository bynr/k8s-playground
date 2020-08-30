# Example: mount src code and reload

```
make create_cluster
make apply
make logs

# change src code in src/hello-loop/py
make restart_container_v2
make logs

# You will see the code is properly updated in the 
```
