# Environment Patching Rules

- Only shim objects that page evidence has already proven are needed
- Patch one minimal causal unit at a time
- Patch values first, then function shells, then the returned object contract
- Re-execute after every patch and record whether the first divergence point moved earlier
