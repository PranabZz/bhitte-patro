# Performance & Functional Test Report: NepaliPatro

This document outlines the performance benchmarks, resource consumption, and functional validation for the NepaliPatro macOS Menu Bar application.

## 1. Summary of Benchmarks
*Executed on Apple Silicon (M-series) / Intel macOS.*

| Metric | Result | Impact |
| :--- | :--- | :--- |
| **Average Conversion Time** | 0.0179 ms (17.98 microseconds) | Negligible |
| **Max Conversions/Sec** | ~55,000 operations | High Throughput |
| **Memory Footprint (Idle)** | ~150 MB (Runtime Overhead) | Low |
| **JSON Load Time** | < 5 ms | Instant Startup |

## 2. Functional Verification: Midnight Updates
The app now includes a `DateUpdater` class that ensures the current date is refreshed automatically at midnight (or whenever the system date changes).

| Test Case | Method | Status |
| :--- | :--- | :--- |
| **Midnight Refresh** | Simulated `.NSCalendarDayChanged` notification | **PASSED** |
| **Menu Bar Label Sync** | Reactive binding to `DateUpdater.currentDate` | **PASSED** |
| **Calendar View Sync** | `onReceive` trigger in `VCenterView` | **PASSED** |

## 3. Algorithmic Complexity (Big O)
The core logic resides in `NepaliCalendar`.

*   **`convertToBSDate(from:)`**: $O(D)$  
    Where $D$ is the number of days since the anchor date (2003-04-14). For current dates (~23 years), this is ~8,400 iterations, executing in microseconds.
*   **`firstWeekday(year:month:)`**: $O(Y + M)$  
    Where $Y$ is years since anchor and $M$ is months. It is a linear scan that is computationally trivial for the modern CPU.

## 4. Resource Consumption Details

### CPU Usage
*   **Idle State**: 0.0% CPU. The app is passive and uses native system notifications (`.NSCalendarDayChanged`) to wake up for updates.
*   **Interaction State**: < 5% CPU spike during UI animations.

### Memory Usage
*   **SwiftUI Runtime**: ~150 MB (Includes macOS framework overhead and Combine pipelines).
*   **Application Data**: < 1 MB.

## 5. Methodology
To verify these results, two isolated scripts were used:
1.  **`perf_test.swift`**: Measures core conversion logic throughput (10,000 iterations).
2.  **`tests.swift`**: Validates the `DateUpdater` reactive logic and system notification handling.

### Reproduction Commands:
```bash
swift perf_test.swift
swift tests.swift
```

---
*Last Updated: March 16, 2026*
