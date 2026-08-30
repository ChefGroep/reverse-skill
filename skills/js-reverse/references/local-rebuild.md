# Local Rebuild

Confirm the following on the page side before returning to Node:

- The real entry function
- The call order
- Where each argument comes from
- Which browser objects are depended on
- Whether it depends on time, randomness, storage, cookies, UA, canvas, or crypto

Reproduce minimally first, then patch the environment step by step — never simulate an entire browser in one go.
