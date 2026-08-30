# Non-PE / Multi-Format Agent Response Recipes U–AV + AW-DN

> Parallel to the PE anti-debug recipes A-T (../anti-analysis.md): per **file type**, gives "trigger -> one-line action -> Evidence".
> **Not** a second master workflow. After Triage identifies the type, jump to the corresponding skill + this table.
> Default: **authorized isolated lab / authorized samples and devices**. Device-wipers, BYOVD, reflective injection etc. are written as **detection and forensics**, not as unauthorized destruction/exploitation tutorials.
> Bypass or recovery failures also MUST be recorded as Evidence; never silently treat as "benign".
>
> §1-§8 / U–AV = original rules (Issue #65). §9-§23 / AW-DN = extension rules (Issue #87, deduplicated + semantic enhancements + edge-case patches).

## 0. Routing Quick Reference

| Type lead | Primary skill | This table's section |
|----------|----------|----------|
| .bat / .cmd / batch | malware-analysis | §1, §19 |
| .ps1 / PowerShell | malware-analysis | §2, §20 |
| Office macros / VBA / XLM / .docm/.xlsm | malware-analysis | §3 (incl. DD OLE extraction, DJ XLM macros) |
| .docx/.xlsx/.pptx OOXML external links / DDE / .rtf OLE | malware-analysis | §10 (incl. DK RTF) |
| Web/frontend JS obfuscation, JSVMP | js-reverse | §4, §21 (incl. DE/DF) |
| .sys / kernel driver | reverse-engineering/kernel-driver-reverse.md + cre | §5 |
| .dll specifics | malware-analysis / re-agent-workflow | §6 (deduplicated vs A-T) |
| APK / Magisk / hidden icons | apk-reverse | §7-§8, §23 |
| .pdf / PDF document | malware-analysis | §9 |
| .wasm / WebAssembly | reverse-engineering | §11 |
| .jar/.class / Java bytecode | reverse-engineering | §12 |
| .exe (AutoIt) / .au3 | malware-analysis | §13 |
| .hta / HTML Application | malware-analysis | §14 |
| .wsf/.jse/.vbe | malware-analysis | §15 |
| .msi / Windows Installer | malware-analysis | §16 |
| .reg / registry script | malware-analysis | §17 |
| .vbs / VBScript | malware-analysis | §18 |
| Xposed/LSPosed module | apk-reverse | §22 |
| ELF / Linux binary | reverse-engineering | -> elf-analysis.md, anti-analysis.md |
| Mach-O / macOS/iOS | reverse-engineering | -> platforms.md |
| Python bytecode | reverse-engineering | -> languages.md |

## 1. BAT/CMD (U V W)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **U** | Many SET single-character variables + %a%%b% concatenation, or ^ line continuations splitting commands | Expand SET line by line; command list after restoration; batch deobfuscation tools may help; **never** treat as "no action" before restoration | E-batch-deobf | P0 |
| **V** | Text opens as garbage; HEX header FF FE (UTF-16 LE BOM) | Confirm the BOM -> convert to UTF-8 and reparse; or chcp 65001 + type | E-batch-encoding | P2 |
| **W** | Excessive REM/:: and redundant GOTO/labels drown the real logic | Strip comments; trace the real GOTO paths; isolated execution capturing the actual cmd command log | E-batch-deadcode | P1 |

## 2. PowerShell (X Z)

> Numbering follows the contributor's habit: **patch Y does not exist**.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **X** | Multi-layer FromBase64String / Gzip / Compress / nested -replace | Decode **layer by layer**; record each layer's result separately; tools optional (PowerDecode etc.), manual/script otherwise | E-ps-decode-layer-N | P0 |
| **Z** | Reversed strings, fragments + concatenation then Invoke-Expression/IEX | Restore the complete string; break on IEX or log script blocks; plaintext commands into Evidence | E-ps-string-restore | P1 |

## 3. VBA Macros / XLM (AA AB AC DD DJ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AA** | olevba/OLEDump only shows P-Code, source streams empty (VBA Stomping) | P-Code decompiler; if incomplete, Word/Excel macro debugging; state limitations clearly | E-vba-pcode | P0 |
| **AB** | Many Chr() concatenations or Base64 strings, suspected shellcode/nested script | Immediate window/script to restore strings; classify after decoding; dynamically watch CreateObject/Shell | E-vba-str-decode | P1 |
| **AC** | Meaningless If 1=2, or InsertLines/DeleteLines self-modification | Static trace of the real branch; dynamically bp the self-modifying APIs and dump the modified macro | E-vba-selfmod | P2 |
| **DD** | olevba/oledump detects a VBA macro project (vbaProject.bin); extension .docm/.xlsm/.pptm | oledump.py to inspect OLE stream structure; olevba to extract VBA source and detect suspicious APIs; check auto-execution macros like AutoOpen/Workbook_Open | E-office-vba | P0 |
| **DJ** | .xls/.xlsm containing Excel 4.0/XLM macros (hidden in cell formulas, not a VBA stream); olevba flags XLM macros | olevba --xlm to extract XLM macro formulas; check hidden worksheets for EXEC/CALL/REGISTER functions; XLMMacroDeobfuscator dynamic emulation to restore | E-office-xlm | P0 |

## 4. JavaScript (AD AE AF) -> primary path js-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AD** | Custom bytecode array + while/switch interpreter (JSVMP) | Find the VM entry and opcode dispatch; dynamic trace logging; AST + dynamic dual track; see js-reverse DeepDive | E-js-vmp | P0 |
| **AE** | while(1){switch} + large string array subscripts | AST/Babel reconstruction; resolve array subscripts back to strings; wakaru and similar optional; **never** paste the whole PE ollvm-deobfuscation article | E-js-deobf | P0 |
| **AF** | debugger, console hijacking, performance.now deltas, DevTools detection | Disable breakpoints/fix the time source/use a headless browser; patch detection points; authorized pages only | E-js-anti-debug | P1 |

## 5. SYS Kernel Driver (AG AH AI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AG** | DriverEntry is very short; logic is not in the entry | Scan MajorFunction[] non-empty slots; prioritize IRP_MJ_DEVICE_CONTROL/CREATE; address list into Evidence | E-driver-irp-handlers | P0 |
| **AH** | DeviceIoControl / IOCTL dispatch present | Build a control-code -> handler table; mark METHOD_* and buffer direction; user-mode communication surface | E-driver-ioctl | P0 |
| **AI** | Sample loads/drops a known vulnerable driver or an oddly signed driver (BYOVD pattern) | Check **public** lists like LOLDrivers; record driver name/hash/signature; analyze the **intent of use**; **do not** expand exploit steps | E-driver-byovd | P1 |

See kernel-driver-reverse.md for the full flow; this table only adds agent action anchors.

## 6. DLL (AJ-AQ) — deduplicated against A-T / #72

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AJ** | DLL analysis only looked at exports/EP, ignoring TLS or DllMain | **Both TLS callbacks and DllMain must be inspected**; dynamic breakpoint order still follows the four-stage rocket (TLS->EP/DllMain->API->ExitProcess) | E-dll-tls-dllmain | P0 |
| **AK** | Export names benign-then-malicious, misleading names, or exports mismatch behavior | Cross-check the export table against actual calls; list anomalous exports | E-exports-anomaly | P0 |
| **AL** | No or very few exports, yet it still gets loaded | Locate from entry, strings, xrefs, callers; do not give up because "no exports" | E-dll-noexport | P0 |
| **AM** | Static IAT lacks the DLL; used only at runtime | **See A-T patch R** (Delay-Load / E-delay-import); do not duplicate the long text here | E-delay-import | P0 pointer |
| **AN** | Need to restore export function parameters and calling conventions | Cross-references + dynamically read registers/stack; annotate stdcall/fastcall etc. | E-dll-export-abi | P1 |
| **AO** | Suspected DLL hijacking/side-loading | Check for same-name DLLs in the app directory, search paths, KnownDLLs; legitimate binary + anomalous DLL combination | E-dll-sideload | P1 |
| **AP** | No file mapping / reflective loading leads | In-memory signatures, loader behavior, path-less modules; forensics in an authorized environment | E-dll-reflective | P1 |
| **AQ** | Risk downgraded only because export names "don't look malicious" | **Never** judge safety from export names alone; combine section permissions, entry, strings, dynamic behavior | E-dll-export-priority | P1 |

DLL/SYS hard gate remains: E-imports + E-exports (see re-agent-workflow).

## 7. Android Device Wiper / Persistence (AR AS AT) -> apk-reverse

> **Authorized samples, images, or test devices only.** Actions are detection, IOC extraction, and persistence-path mapping — not performing destruction.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AR** | Magisk module/scripts contain **device-wiper signature commands**: database deletion, flashing, bulk rm on system partitions | Signature command table + module path; flag high-risk destructive capability; do not execute the wiper commands | E-android-wiper-cmd | P0 |
| **AS** | Looping curl|sh / remote script pull, unusual C2 URLs | Extract URLs; analyze whether downloads contain wiper commands; record temp paths | E-android-wiper-backdoor | P0 |
| **AT** | /data/adb/service.d, post-fs-data.d, suspicious /system/priv-app etc. | List persistence scripts/APKs; content summary into Evidence | E-android-persistence | P1 |

## 8. Android Transparent/Hidden Icons (AU AV) -> apk-reverse

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AU** | LAUNCHER icon fully transparent/empty label, Theme.NoDisplay, no LAUNCHER category, component disabled | aapt dump badging + manifest; decompile and inspect icon pixels; anomalies into Evidence | E-android-hidden-icon-manifest | P0 |
| **AV** | Installed but no desktop icon, background traffic/auto-start/high-risk permissions/dynamic icon restoration | pm list vs launcher; dumpsys package; broadcasts and device_admin; behavior into Evidence | E-android-hidden-icon-behavior | P1 |

---

> **§9-§23 below are Issue #87 extension rules (AW-DC).**
> The ELF (-> elf-analysis.md), Mach-O (-> platforms.md), and Python (-> languages.md) sections that duplicated existing files have been removed.

## 9. Malicious PDF Documents (AW AX AY AZ)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **AW** | pdfid finds /JS, /JavaScript, /OpenAction, /AA, /Launch counts >0 (including obfuscated hex-encoded names like /4A#61#76#61...) | pdfid -e statistics (compare plain vs obfuscated counts); pdf-parser to extract suspicious objects; peepdf interactive analysis + JS emulation | E-pdf-autoaction | P0 |
| **AX** | pdfid finds /EmbeddedFile >0; object streams with cascaded FlateDecode/ASCIIHexDecode filter chains; or encoded payloads hidden in /Annot objects | pdf-parser to extract stream data; peepdf to decode multi-layer cascaded filters (including AES-encrypted streams via security handler r5/r6); inspect Annotation objects; `file` to identify the decoded result | E-pdf-embedded | P0 |
| **AY** | Extracted PDF JS contains heavy eval, unescape, String.fromCharCode, atob | Execute-and-trace in the peepdf JS emulation environment; layer-by-layer decode Base64/Hex/ROT13; CyberChef assists | E-pdf-js-deobf | P1 |
| **AZ** | Abnormal PDF structure: /JBIG2Decode, manipulated XREF table, jumping object numbers | pdfid -d renames suspicious keywords; check known CVE exploit patterns; extract exploit trigger conditions | E-pdf-exploit | P1 |

## 10. Office OOXML / DDE / RTF (BA BB DK) -> complements §3 VBA

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BA** | After unzipping docx/xlsx/pptx, word/_rels/ or xl/_rels/ contains suspicious external relationships (incl. remote template injection) | Check *.rels external links; check vbaData.xml; extract embedded OLE objects; check protocol handler abuse (ms-msdt: / search-ms: / ms-officecmd:) | E-office-ooxml | P0 |
| **BB** | Document contains DDEAUTO or DDEEXEC field codes executing external commands via fields | olevba --dde scan; extract DDE command arguments; check whether they point to PowerShell/external exe | E-office-dde | P0 |
| **DK** | .rtf file contains embedded OLE objects (not OOXML, not classic OLE compound document) | rtfobj to extract embedded OLE objects; oleobj to analyze object types; check Equation Editor exploitation (CVE-2017-11882 etc.); `file` to identify extracted types | E-rtf-ole | P0 |

## 11. WebAssembly (BC BD BE)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BC** | File starts with the \x00asm magic bytes; or JS code contains WebAssembly instantiation logic | wasm2wat to text; inspect the import section to identify host-environment imports; wasm-decompile for pseudocode; check Emscripten glue signatures (__wasm_call_ctors) to judge JS compilation provenance | E-wasm-struct | P0 |
| **BD** | Many simple WASM functions, function bodies split into tiny functions; or meaningless block/loop nesting | diswasm to evaluate the function-minimization level; JEB Pro / IDA WASM plugin for deep analysis; dynamic trace logs | E-wasm-obfuscation | P1 |
| **BE** | WASM module interacts with the browser through imported/exported functions; WebSocket, fetch, WebGL calls present | Analyze both the JS glue code and the WASM module; trace data exchange in browser DevTools; extract communication URLs/domains | E-wasm-c2 | P1 |

## 12. Java JAR/Class (BF BG BH BI)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BF** | JAR opened in JD-GUI/jadx shows meaningless short class/method names (a.a.a / _0x prefixes / numeric class names); or heavy while/switch control-flow obfuscation | Identify the obfuscator (ProGuard / Allatori / ZKM); Java Deobfuscator static deobfuscation; when heavy, dynamically debug and trace key logic | E-java-obfuscation | P0 |
| **BG** | Heavy Class.forName(), Method.invoke(), Constructor.newInstance(); or a custom ClassLoader + defineClass() loading classes from byte arrays; import table benign but malicious classes loaded dynamically at runtime | javap -c -v to inspect reflection details; trace Class.forName argument strings; check the defineClass() byte-array source; dynamically break on Method.invoke | E-java-reflection | P0 |
| **BH** | JAR contains .so (Linux/Android) or .dll (Windows); or System.loadLibrary() calls | Extract the native library files; `file` to identify the format; move into the standalone ELF/PE analysis flow | E-java-native | P1 |
| **BI** | JAR/ZIP contains nested JAR/WAR/EAR after extraction; high-entropy .dat/.bin/.img files in /resources, /assets | Recursively extract all nested archives; entropy analysis for encryption/compression; check META-INF/MANIFEST.MF and pom.xml | E-java-nested | P1 |

## 13. AutoIt (BJ BK BL DM)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BJ** | PE strings contain AutoIt / AU3 / EA05 / EA06 signatures; or the resource section holds AutoIt script resources (note AutoHotKey distinction, MITRE T1059.010 covers both) | autoit-ripper to extract the compiled script; identify the encoding family (EA05 = AutoIt3.00 / EA06 = AutoIt3.26); extract the 8-byte decryption key after the EA06 header to decrypt the payload; restore source | E-autoit-extract | P0 |
| **BK** | Extracted script has heavy StringEncrypt/_StringEncrypt; or Execute dynamic execution + meaningless variable names | myAutToExe static decompilation; identify anti-debug techniques; analyze the obfuscated control flow | E-autoit-deobf | P1 |
| **BL** | Script contains RegWrite (registry persistence), FileInstall (file drop), InetGet (network download), Run/RunWait | Flag the sensitive API call sequence; analyze InetGet URLs; trace FileInstall drop paths | E-autoit-malicious | P0 |
| **DM** | AutoIt as loader performing process hollowing: CallWindowProc/EnumWindows callbacks + shellcode + injecting a legitimate process (regsvcs.exe etc.), dropping a .NET payload (DarkGate / Snake Keylogger / ArechClient2 patterns) | Check the DllCall/DllCallbackRegister call chain into kernel32 injection APIs; extract shellcode data; identify the injection target process; extract the .NET payload for standalone analysis | E-autoit-hollowing | P0 |

## 14. HTA / HTML Application (BM BN BO)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BM** | HTML contains the HTA:APPLICATION tag, window.execScript, or CreateObject calls | Inspect HTA:APPLICATION attributes (Application, WindowState); extract VBS/JS from script tags | E-hta-bypass | P0 |
| **BN** | HTA launched via mshta.exe pulls payloads remotely via XMLHttpRequest / ActiveXObject and executes | Extract network request URLs; trace ActiveXObject creation (ADODB.Stream etc.); restore the full download-and-execute chain | E-hta-download-chain | P0 |
| **BO** | HTA contains only a single extremely long obfuscated string executed via eval / execScript | Extract the Base64/Hex encoded payload and decode; CyberChef recursion to detect encoding types; restore the payload | E-hta-oneline | P1 |

## 15. WSF / JSE / VBE (BP BQ BR BS)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BP** | .wsf contains \<job\> + \<script language="..."\> tags, mixing JScript/VBScript/Python | Split code blocks by \<script language\>; analyze each under its language rules | E-wsf-multi | P0 |
| **BQ** | .jse/.vbe starts with the #@~^ signature, Microsoft Script Encoder encoding | screnc-decoder to decode; without the tool, dynamic execution + dump the decoded script | E-jse-decode | P0 |
| **BR** | WSF multiple \<script\> blocks + \<package\> referencing external resources + \<component\> referencing COM components | Build a cross-block call graph; trace function calls between \<script\> blocks; restore the full execution flow | E-wsf-call-chain | P1 |
| **BS** | WSF uses WshShell.SendKeys to bypass UAC, WshShell.Run with window style 0 to hide, WScript.Sleep delays to evade | Check whether simulated user operations are used to bypass security prompts; record covert execution parameters | E-wsf-anti-detect | P1 |

## 16. MSI Installers (BT BU BV)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BT** | MSI contains a CustomAction table (Binary / Script / DLL custom actions) | msiexec /a or lessmsi to extract content; inspect the CustomAction table; extract custom-action binaries | E-msi-custom-action | P0 |
| **BU** | MSI Binary table contains VBScript/JScript custom-action scripts | Extract script binaries from the Binary table and decode to readable scripts; analyze per VBS/JS rules | E-msi-script | P1 |
| **BV** | MSI installs silently via /quiet /passive /qn; ALLUSERS=1 privilege escalation | Record installer command-line parameters; analyze Property table permission settings; flag the silent+elevation combination | E-msi-privilege | P1 |

## 17. REG Registry Scripts (BW BX BY)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BW** | .reg writes HKCU\...\Run or HKLM\...\Run and other auto-start paths | Extract all paths; flag Run-path entries as persistence; record full paths and values | E-reg-persistence | P0 |
| **BX** | .reg modifies HKCR\...\shell\open\command (file association) or HKCR\CLSID\{...}\InprocServer32 (DLL injection) | Check whether shell\open\command points to an unusual exe; check InprocServer32 DLL paths | E-reg-hijack | P0 |
| **BY** | .reg modifies HKLM\...\Policies\System (UAC level), EnableLUA, ConsentPromptBehaviorAdmin | Compare against default secure configuration; analyze the UAC impact; flag the downgrade behavior | E-reg-uac-bypass | P1 |

## 18. VBScript (BZ CA CB CC DN)

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **BZ** | .vbs/.js parsed by both VBScript and JScript; conditional compilation (@_win32) or cross-language execution | Separate VBScript/JScript blocks; parse each syntactically; identify the mixed execution logic | E-vbs-mixed | P1 |
| **CA** | Script contains CreateObject("WScript.Shell") / CreateObject("Shell.Application") / Scripting.FileSystemObject | Flag high-risk COM object calls; trace Run/Exec arguments; trace FSO-created file paths | E-vbs-com-abuse | P0 |
| **CB** | Script starts with the #@~^ signature, Microsoft Script Encoder encoding (VBS-specific) | screnc-decoder to decode; without the tool, dynamic execution + dump the decoded script | E-vbs-encoded | P0 |
| **CC** | VBA/VBScript contains WScript.Shell.Run + cmd /c + PowerShell followed by process injection | Trace the CreateObject COM object chain; analyze injection signatures in Run arguments; record the full process creation chain | E-vbs-inject-chain | P0 |
| **DN** | VBScript/JScript achieves fileless persistence via WMI ActiveScriptEventConsumer (no startup folder / registry Run key) | Check WMI event subscriptions (__EventFilter + __FilterToConsumerBinding + ActiveScriptEventConsumer); extract the bound script content; flag fileless persistence | E-vbs-wmi-persist | P0 |

## 19. BAT/CMD Advanced Obfuscation (CD-CI) -> complements §1 U-W

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CD** | setlocal enabledelayedexpansion + !var! + dynamic variable names (!var_%i%!) | Expand line by line with delayed expansion enabled; Batch-Dump --expand auto-expands | E-bat-delayed-expand | P0 |
| **CE** | Executes via type/more/findstr reading its own :stream ADS (alternate data stream) | Check for :suffix references (file.bat:payload); dir /r to list ADS; type file:stream to extract | E-bat-ads-hidden | P0 |
| **CF** | Heavy echo writing a .tmp/.cmd temp file line by line, then call executes it | Extract all echo redirections to restore the temp file; monitor scripts generated in temp dirs | E-bat-temp-gen | P1 |
| **CG** | for %%i in (...) do set var=%%i variable accumulation; for /f parsing command output line by line | Expand the for loop step by step, recording each iteration's assignment; serialize the for /f results | E-bat-for-expand | P1 |
| **CH** | Main batch receives arguments via %1 %*, passed in by a parent process/downloader with obfuscated instructions | Inspect the calling context and record passed parameters; Base64-decode arguments; restore the full call chain | E-bat-param-call | P1 |
| **CI** | certutil -decode / powershell -Command / echo \| findstr combinations to decode and execute | Extract Base64/Hex strings and decode; check whether the result is an executable script/PE | E-bat-encoded-exec | P0 |

## 20. PowerShell Advanced Bypass (CJ-CO, DL) -> complements §2 X-Z

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CJ** | [Ref].Assembly.GetType('...AmsiUtils') / amsiInitFailed / GetTypes() and similar AMSI bypasses (including hardware-breakpoint bypass: CPU debug registers, no memory write/VirtualProtect) | Identify the bypass pattern (patch / registry / environment variable / hardware breakpoint); dynamically confirm it takes effect; flag the bypass technique type | E-ps-amsi | P0 |
| **CK** | [PSConstraintLanguage] type operations or modifying session state via DefaultRunspace to bypass CLM | Identify the CLM bypass pattern; flag bypass-clm; analyze the post-bypass execution context | E-ps-clm-bypass | P0 |
| **CL** | [ScriptBlock]::Create / $ExecutionContext.InvokeCommand constructors; or overriding ScriptBlock logging settings | Check whether the script disables logging; dynamically verify that logging was bypassed | E-ps-sb-log-bypass | P1 |
| **CM** | IEX (New-Object Net.WebClient).DownloadString(...) or [Reflection.Assembly]::Load(FromBase64...) fileless execution | Extract download URLs and check domain/IP reputation; capture in-memory-loaded code from PS logs; isolate network to simulate and extract the payload | E-ps-reflect-load | P0 |
| **CN** | Three-plus layers of nested encoding: outer Base64 -> Gzip -> XOR -> plaintext (beyond §2 X's two layers) | Recursively decode to plaintext or until stuck; record intermediate state per layer; PowerDecode automation; each layer's result into Evidence | E-ps-multi-decode | P0 |
| **CO** | Set-Alias mapping IEX to a single-character alias; Get-ChildItem variable: to dynamically fetch variable values | Expand all alias mappings back to original command names; AST analysis to restore variables | E-ps-alias-decode | P1 |
| **DL** | Script patches ntdll.dll EtwEventWrite (stomping) to silence telemetry; often combined with AMSI bypass | Check for EtwEventWrite address resolution + memory patch (ret 0xC3); check together with CJ AMSI bypass; flag the dual-bypass combination | E-ps-etw-bypass | P0 |

## 21. JavaScript Advanced Obfuscation (CP CQ DE DF) -> complements §4 AD-AF

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CP** | JS uses Proxy objects to intercept property access + Reflect API dynamic method calls to defeat static analysis | Identify Proxy get/set/apply traps; trace Reflect.get's actual target; flag dynamic interception behavior | E-js-proxy | P1 |
| **CQ** | JS contains _0x... hex string arrays + while(!![]) dead loops + for+switch control flow (obfuscator.io signatures) | Identify obfuscator.io signatures (string array + dead loop); de4js / jsnice auto-deobfuscation; restored code into Evidence | E-js-obfuscator | P0 |
| **DE** | JS body is a large bytecode array + VM interpreter loop (multiple while/switch), entry points to eval/Function constructors; business logic unreadable (deepens §4 AD) | Identify the VM entry function and trace opcode->handler mapping; dynamically hook eval output in the browser; JSimplifier AST reconstruction; record the opcode mapping table | E-jsvmp-deep | P0 |
| **DF** | JS uses eval to dynamically generate and immediately execute new code, document.write to rewrite the page, or Function constructors to build function bodies dynamically | Hook eval and the Function constructor to record generated code; dynamic execution in the browser to capture self-modified content | E-js-selfmod | P1 |

## 22. Xposed/LSPosed Module Analysis (CR-CX) -> apk-reverse

> Analyzing an Xposed/LSPosed **module itself** as the reverse target (not tool usage).

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **CR** | AndroidManifest.xml has no android:name entry Activity; meta-data specifies xposedmodule=true | Check assets/xposed_init to determine the entry class; search for IXposedHookLoadPackage/ZygoteInit/CmdInit interface implementations | E-xp-entry | P0 |
| **CS** | Code contains XposedHelpers.findAndHookMethod / XposedBridge.hookMethod / findClass | Extract findAndHookMethod argument 1 (target class) + argument 2 (target method); build the target-app list | E-xp-hook-targets | P0 |
| **CT** | Module contains DexClassLoader/PathClassLoader dynamic loading; or Runtime.exec / ProcessBuilder command execution | Trace DexClassLoader constructor arguments; extract dynamically loaded DEX for standalone analysis; inspect exec command arguments | E-xp-dynamic-load | P0 |
| **CU** | Hook targets involve payment/biometrics/SMS/contacts/location/encryption-key sensitive APIs | Classify the sensitivity of hook target classes/methods; flag payment/biometric/SMS-contacts categories; summarize the threat level | E-xp-sensitive-hooks | P0 |
| **CV** | Code contains XposedBridge detection evasion / Zygote injection trace cleanup / custom network communication | Check stacktrace modification / XposedBridge class-reference cleanup; check independent network requests (OkHttp/Socket); identify C2 targets | E-xp-anti-detection | P1 |
| **CW** | Code contains Resources dynamic replacement / View drawing interception / AccessibilityService declaration | Check AssetManager replacement / Resources.updateConfiguration; inspect the AccessibilityService configuration; identify UI hijacking | E-xp-ui-hijack | P1 |
| **CX** | AndroidManifest.xml declares the lsposed xposedscope meta-data; or code contains package-name whitelist checks | Parse the xposedscope target-app scope; check dynamic whitelist bypass (reflection-modified scope); identify global-hook overreach | E-xp-scope-bypass | P1 |

## 23. Magisk Module Deep Analysis (CY-DC, DG-DI) -> complements §7 AR-AT

> §7 focuses on device-wiping/destructive behavior. This section covers non-destructive but suspicious module behavior: install-script analysis, file drops, Zygisk injection, anti-detection, persistence, privilege escalation, cross-module infection.

| ID | Trigger | Action (summary) | Evidence | Priority |
|----|------|--------------|----------|------|
| **DG** | Magisk module ZIP root contains config.sh / install.sh; META-INF/com/google/android/update-binary is a non-standard installer | Extract on_install/print_modname/set_permissions functions from config.sh/install.sh; check whether update-binary carries extra payloads; flag pm install / dd block-device / mount -o remount,rw operations | E-mg-install-script | P0 |
| **DH** | ZIP contains system/ / vendor/ / data/ directory structures; or post-fs-data.sh / service.sh boot-time scripts | Extract dropped-file paths, identifying APK drops into /system/priv-app/; inspect service.sh + post-fs-data.sh for boot persistence/keep-alive/C2 communication; flag all system-partition write operations | E-mg-file-drop | P0 |
| **CY** | Module contains a zygisk/ directory (arm64-v8a.so and similar native libs); or config.sh declares IS_ZYGISK=true | Extract zygisk/ native libs and analyze ZygiskModule callbacks (onLoad / preAppSpecialize / postAppSpecialize); inspect JNI hooks | E-mg-zygisk | P0 |
| **DI** | Module script writes /data/adb/service.d/ or /data/adb/post-fs-data.d/; or modifies crontab/init.rc (deepens §7 AT) | Extract scripts written into service.d + post-fs-data.d; check for post-uninstall.sh / module-directory monitoring that auto-infects other modules on removal; check the magisk --remove-modules trigger protection | E-mg-persistence | P0 |
| **CZ** | Module script uses resetprop to modify system properties / magiskhide / DenyList; or integrates Shamiko (hiding Zygisk itself) / TrickyStore (certificate-chain tampering) / PlayIntegrityFork (forging the Play Integrity API) | Extract all resetprop calls to identify modified properties (ro.debuggable / ro.build.tags etc.); check DenyList self-hiding; identify Shamiko/TrickyStore/PlayIntegrityFork module-level anti-detection | E-mg-anti-detect | P0 |
| **DA** | Module script contains setenforce 0 / mount -o rw,remount /system / chmod 777 on sensitive directories | Check SELinux operations (setenforce/chcon/restorecon); check system-partition mounts + dm-verity disablement; flag high-risk privilege escalation | E-mg-privilege | P0 |
| **DB** | Dropped APK/script contains curl/wget/HTTP clients; or the dropped APK requests INTERNET + READ_CONTACTS/SMS sensitive permissions | Extract network request target URLs/IPs; analyze the dropped APK's permission declarations; identify data exfiltration logic | E-mg-c2 | P0 |
| **DC** | Script iterates /data/adb/modules/, modifies other modules' files, or writes copies of itself into other modules | Check for malicious instructions injected into module.prop; check other modules' service.sh for appended malicious code; identify the "parasitic" logic | E-mg-cross-infect | P0 |

---

## 24. Constraints (Global)

1. **No parallel master workflow**: the stage gates still belong to re-agent-workflow / each skill.
2. **Evidence always recorded**: including failures, partial recovery, quality= labels.
3. **Deduplicated vs A-T**: PE anti-debug is not repeated; AM->R; AJ adds the DLL perspective without overriding the TLS rocket.
4. **Missing tools**: record n/a + manual equivalent; never pretend commercial suites were used.
5. **Authorization**: destructive/injection/driver-vulnerability categories are defense analysis and forensic language only.
6. **Extension-rule deduplication**: ELF -> elf-analysis.md; Mach-O -> platforms.md; Python -> languages.md. This table does not repeat rules for those formats.

## 25. P0 Minimal Checklist (when a type is hit)

```text
□ bat/cmd -> U (+ V/W when needed; advanced CD-CI)
□ ps1 -> X (+ Z; advanced CJ-CO + DL ETW)
□ vba/xlm -> AA + DD + DJ (+ AB/AC)
□ office ooxml/rtf -> BA + DK (+ BB if DDE suspected)
□ js heavy obfuscation -> AD or AE (+ AF; advanced CP/CQ/DE/DF)
□ sys -> AG + AH (+ AI if BYOVD suspected)
□ dll -> AJ + AK/AL; Delay-Load goes to R
□ apk destruction/hiding -> AR/AS or AU (+ AT/AV)
□ pdf -> AW + AX (+ AY/AZ)
□ wasm -> BC (+ BD/BE)
□ jar/class -> BF + BG (+ BH/BI)
□ autoit -> BJ + BL + DM (+ BK)
□ hta -> BM + BN (+ BO)
□ wsf/jse/vbe -> BP + BQ (+ BR/BS)
□ msi -> BT (+ BU/BV)
□ reg -> BW + BX (+ BY)
□ vbs -> CA + CB + CC + DN (+ BZ)
□ xposed module -> CR + CS + CT + CU (+ CV-CX)
□ magisk deep -> DG + DH + CY + DI + CZ + DA (+ DB/DC)
```
