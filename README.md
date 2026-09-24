# BoundedIntakeLoop — Demo App

**Five ways an on-device agent loop can go wrong, each one running live on screen.**

This is the companion app for [**bounded-intake-loop-kit**](https://github.com/rajatslakhina/bounded-intake-loop-kit), a visual-intake pipeline (photo → validated structured record) built so that termination, spend and trust are properties of the loop rather than of the model provider.

The app is a single screen with a scenario picker. Tapping a scenario runs the **real** `IntakeLoop` against a scripted provider and renders whatever comes back: the provenance badge, the budget meters, the reconstructed record and the full event trace are read off the returned `IntakeResult`. Nothing on that screen is a mock-up of the loop's behaviour — it *is* the loop's behaviour.

| Scenario | What you watch happen |
|---|---|
| **Grounded read** | The model calls OCR and the barcode reader, then emits a record that passes every invariant. Badge: `READ BY MODEL`. |
| **No model on device** | The model throws. The loop grounds the photo itself and rebuilds the same record from OCR alone. Badge: `DETERMINISTIC FALLBACK` — same data, different confidence. |
| **Runaway tool loop** | The model asks for the same tool forever. The tool-call meter stops at **1 of 4** because every repeat is coalesced for free, and the *turn* meter is what fills up and ends the run. |
| **Hallucinated barcode** | The model keeps emitting a barcode whose check digit is wrong. You can watch validation reject it on every turn in the trace — and then watch the fallback rebuild the record from the barcode the *reader* actually saw, not the one the model claimed. The record ends up byte-identical to scenario 1; only the provenance differs. |
| **Contract violation** | The model requests a tool that was never registered. That is not retried — the run ends immediately and the deterministic path takes over. |

---

## Why this matters

A demo of an AI feature usually shows the happy path, because the happy path is the part that demos well. The interesting engineering is all in the other four columns above, and none of it is visible unless you build a surface that shows it: how much budget a run actually spent, which turn the mode ladder was on when the model misbehaved, and whether the record on screen came from the model or from OCR.

The provenance badge is the whole argument in one UI element. A record read by the model and a record rebuilt by the fallback can be byte-identical — scenario 1 and scenario 4 produce exactly the same `IntakeRecord` — and a product that displays them the same way has quietly decided that "the model said so" and "arithmetic said so" are the same kind of fact.

The screen is also deliberately *un*helpful in one place: when the barcode is absent it renders `—` and nothing else. The view does not know whether the reader never ran or whether its answer failed a check digit, and a package whose thesis is that a record should say where it came from must not let its own UI invent a reason. The trace underneath says which one it was.

---

## Screenshots

**There are none, and none are described.** The automated run that produced this repository requested computer-use access to Xcode and Simulator three times (twice for both apps, once narrowed to Simulator alone) and was refused each time:

> Computer-use access to "Xcode 26.3", "Simulator" can't be approved during a scheduled run.

So this app **has not been launched on a Simulator or a device.** There is deliberately no `Demo/Screenshots` directory rather than a placeholder image or a written description of one. What *has* been verified is in the next section, and "it compiles for an iOS Simulator" is not the same claim as "it ran on one".

---

## Verification — what was actually executed

| Check | Result |
|---|---|
| `xcodebuild -resolvePackageDependencies` on a clean `macos-15` runner | **Success.** This is the load-bearing one: it proves the pinned `XCRemoteSwiftPackageReference` genuinely resolves the library from GitHub on a machine with no cache, which a local build cannot show. |
| `xcodebuild build -scheme Demo -destination 'generic/platform=iOS Simulator'` | **Success.** The app compiles against the resolved package. |
| Library's own CI (Linux `swift build -Xswiftc -warnings-as-errors` + `swift test`, 80 tests) | **Green** — see [the library's Actions tab](https://github.com/rajatslakhina/bounded-intake-loop-kit/actions). |
| App launched and used on a Simulator | **Not done** — see Screenshots above. |

Both jobs run on every push: [Actions](https://github.com/rajatslakhina/bounded-intake-loop-kit-demo-app/actions). The destination is `generic/platform=iOS Simulator` on purpose — pinning to a named device (`name=iPhone 16,OS=latest`) ties the job to whichever simulator *runtimes* happen to be installed on that day's runner image, and a compile-only check needs no device to exist.

---

## How to run it

```bash
git clone https://github.com/rajatslakhina/bounded-intake-loop-kit-demo-app.git
cd bounded-intake-loop-kit-demo-app
open Demo.xcodeproj
```

Requires Xcode 16 or later. On first open, let Xcode resolve the remote package (File ▸ Packages ▸ Resolve Package Versions if it does not start on its own), select the shared **Demo** scheme and any iOS Simulator, then Build & Run.

The loop runs on first appearance, so the app is never an empty screen waiting for a tap. Switch scenarios with the pills at the top; the **Run the pinned eval suite** button at the bottom executes all five cases through `IntakeEvalHarness` and reports how many passed.

---

## How it is wired

Two repositories on purpose:

- **[bounded-intake-loop-kit](https://github.com/rajatslakhina/bounded-intake-loop-kit)** — the SPM library. No app target, no executable target, no `@main`. It compiles and tests on Linux.
- **this repo** — a standalone `Demo.xcodeproj` that depends on the library as a **remote** package pinned to a version:

```
XCRemoteSwiftPackageReference "bounded-intake-loop-kit"
  repositoryURL = https://github.com/rajatslakhina/bounded-intake-loop-kit.git
  requirement   = { kind = upToNextMajorVersion; minimumVersion = 1.0.0; }
```

`upToNextMajorVersion` from `1.0.0` resolves the newest 1.x — **v1.1.0** at the time of writing. Pinned to a released version rather than tracking `main`: branch-tracking means every clone and every CI run resolves whatever `main` happened to be that day, which is the wrong default for something a stranger is going to open once.

`Demo/DemoApp.swift` is deliberately thin — 22 lines — and it earns its `import BoundedIntakeLoop`: it owns `DemoConfiguration.currencyCode`, the compiled-in product decision that the library takes as a parameter and never assumes. The demo *UI* lives in the library (`IntakeDemoView`) rather than here, because the loop has to be exercisable in CI on a machine with no device model at all; the same five scenarios back the unit tests, the eval harness and this screen, so a screenshot cannot drift away from a passing test.

## License

MIT — see [LICENSE](LICENSE).
