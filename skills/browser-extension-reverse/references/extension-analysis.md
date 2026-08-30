# Extension Analysis Essentials

| Field | Risk Signal |
|------|----------|
| host_permissions `<all_urls>` | Can read/write any site |
| webRequestBlocking | Man-in-the-middle style rewriting |
| nativeMessaging | Escapes the browser to the local machine |
| externally_connectable | Web pages drive the extension |

MV3: focus on the service_worker lifecycle and declarativeNetRequest.
