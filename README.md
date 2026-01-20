Shell function for calculating hashes

needs `rhash` 
```shell
stationeers.hash() { 
    rhash -m $1 -p '16dio [100000000-]sn %Cp Ao d80000000!>n p' | dc
}
```
   