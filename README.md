# PressureBar

PressureBar is a lightweight macOS menu bar utility that shows:

- Current CPU usage
- Current memory usage
- Available memory
- Swap usage
- A simplified memory pressure state

The app is designed to stay small and avoid shelling out to tools like `top` or `vm_stat` on every refresh.

## Features

- Native macOS menu bar app
- No Dock icon
- CPU and memory updates every 1, 2, or 3 seconds
- Default refresh interval set to 3 seconds to minimize runtime overhead
- Compact menu bar label like `C16% M84%`
- Detail panel with system stats
- Pressure states: `Low`, `Medium`, `High`

## Project Structure

- `pressurebar/`
  SwiftUI app source
- `pressurebar.xcodeproj/`
  Xcode project

## Requirements

- macOS 14.6 or newer
- Xcode 26 or newer

## Supported macOS Version

PressureBar currently targets:

- macOS 14.6+

This keeps the app compatible with modern macOS versions while still avoiding an unnecessarily high minimum deployment target.

## How To Run

### Option 1: Run from Xcode

1. Open `pressurebar.xcodeproj` in Xcode.
2. Select the `pressurebar` scheme.
3. Choose `My Mac` as the run destination.
4. Press Run.

Because PressureBar is configured as a menu bar utility, it does not open a normal window and does not appear in the Dock. After launch, look for the app in the macOS menu bar.

If Xcode asks for signing:

1. Open the `pressurebar` target.
2. Go to `Signing & Capabilities`.
3. Choose your Apple team for local development.
4. Run again.

### Option 2: Build from Terminal

For a local unsigned build:

```bash
xcodebuild \
  -project pressurebar.xcodeproj \
  -scheme pressurebar \
  -configuration Debug \
  -derivedDataPath /tmp/pressurebar-derived \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

This is useful for validation, but for normal day-to-day use the easiest path is still running from Xcode with local signing enabled.

## How To Quit

- Open the PressureBar menu from the menu bar.
- Click `Quit PressureBar`.

If the process stays running during development, you can also stop it from Terminal:

```bash
pkill -x pressurebar
```

## Distribution

For public distribution, the recommended path is:

1. Sign the app with `Developer ID Application`
2. Keep `Hardened Runtime` enabled
3. Notarize the final artifact with Apple
4. Publish a notarized `.zip` or `.dmg` in GitHub Releases

For a first release, a notarized `.zip` is the simplest option. A `.dmg` gives a nicer installation experience and is a good next step.

## How The Calculations Work

PressureBar uses native macOS APIs from Mach and `sysctl`, not external command-line tools.

### CPU Usage

CPU usage is calculated from `host_processor_info` using `PROCESSOR_CPU_LOAD_INFO`.

The app stores the previous CPU sample and compares it with the current sample:

- `totalDelta = currentTotalTicks - previousTotalTicks`
- `idleDelta = currentIdleTicks - previousIdleTicks`
- `busyDelta = totalDelta - idleDelta`
- `cpuUsage = busyDelta / totalDelta`

This produces a system-wide CPU usage percentage over the refresh interval.

### Memory Usage

Memory values come from `host_statistics64` with `HOST_VM_INFO64`.

PressureBar currently uses:

- `freeBytes = free_count * pageSize`
- `cachedBytes = external_page_count * pageSize`
- `availableBytes = freeBytes + cachedBytes`
- `usedBytes = totalPhysicalMemory - availableBytes`

This choice is intentional:

- `free` memory reflects immediately unused pages
- `external_page_count` maps more closely to reclaimable cached memory
- using `free + cached` makes the result align more closely with Activity Monitor than using `inactive_count`

### Swap Usage

Swap is read from:

- `sysctlbyname("vm.swapusage", ...)`

The displayed value is `xsu_used`.

## Pressure States

PressureBar exposes a simplified pressure signal with three states.

### Low

Shown when the system still has comfortable headroom.

Current rule:

- `headroom >= 18%`
- or swap exists but there is still enough free/cached memory

### Medium

Shown when available memory is getting tighter, but the system is not yet in the most constrained state.

Current rule:

- `headroom < 18%`
- or `swap > 0` and `headroom < 28%`

### High

Shown when headroom is critically low, or when low headroom and heavy swap usage happen together.

Current rule:

- `headroom < 6%`
- or `headroom < 10%` and `swapRatio > 0.5`

Where:

- `headroom = availableBytes / totalBytes`
- `swapRatio = swapUsedBytes / totalBytes`

## Notes On Accuracy

PressureBar is intentionally pragmatic rather than a perfect clone of Activity Monitor.

What it tries to do well:

- stay lightweight
- use native system APIs
- provide values that track Activity Monitor closely enough to be useful in real time

What it does not try to do yet:

- reproduce Apple's exact internal memory pressure model
- expose every VM category shown by Activity Monitor

## Future Improvements

- Launch at login
- Configurable menu bar text format
- More detailed memory breakdown
- Better historical trend display
- Fine-tuned pressure heuristics based on more real-world comparisons
