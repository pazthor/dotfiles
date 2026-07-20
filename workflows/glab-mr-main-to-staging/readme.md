# when create a MR open to main, create another MR point to staging

create MR from x-branch to staging

source branch = branch of work.

target -> branch stable like staging and main
that branch branch to deploy.

# USes case

usually when  create a MR to main and that branch to test it is more easy test it on staging server.
we create small MR and usually we have many MR to merge to staging to test, so I thinking  with a script  could be fast it. tell me if im wrong

```sh
# example 

glab mr create --source $(git branch --show-current) --target staging --title "Staging: Local Test MR" --description "Testing parallel staging MR creation" --yes
```

```sh
glab mr create \
  --source-branch "$(git branch --show-current)" \
  --target-branch staging \
  --fill
```

```bash
# update MR point to main,
# you create a MR but wrong target, 
# you can update point by default  to Staging 
mr-to-staging() {
  if [ -z "$1" ]; then
    echo "Usage: mr-to-staging <MR_IID>"
    return 1
  fi

  glab mr update "$1" \
    --target-branch staging \
    --yes
}
```
