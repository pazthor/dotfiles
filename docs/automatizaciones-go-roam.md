# que se puede automatizar

## 2 CI test gate en el MR  

que lso test se corran antes de rear el MR draf,  

Que enel pipline corra pest en cada push de features  

Scritp que corra
post merge validation

ejecutar pest despues de lgit merge
como ungithook
post-merge

```sh
#!/bin/bash
cd apps/experiences-app
./vendor/bin/pest --bail 2>/dev/null
if [ $? -ne 0 ]; then
    echo "WARNING: Tests failing after merge. Review before committing."
fi
```

### deteccion de test  orphan

```sh
# Detect reflection calls to non-existent methods
rg "ReflectionMethod\(" tests/ | grep -oP "::(\w+)\(\)" | sort -u
```
