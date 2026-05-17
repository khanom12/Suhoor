## 1. Forecast Horizon

- [x] 1.1 Update Home forecast constants and visible copy from Next 10 Mornings to Next 7 Days.
- [x] 1.2 Limit the expanded Home forecast ready state to seven rows.
- [x] 1.3 Start the forecast row set at the next immediate alarm or next relevant morning already selected by the Home snapshot.

## 2. Weekly Fajrcast Alignment

- [x] 2.1 Build compact Weekly Fajrcast visible days from the forecast start date through the following six mornings.
- [x] 2.2 Ensure Home passes the same forecast-start date into Weekly Fajrcast that it uses for the first Next 7 Days row.
- [x] 2.3 Preserve temporary Fajrcast inspection behavior without persisting focus or changing wake state.

## 3. Verification

- [x] 3.1 Update focused XCTest coverage for Next 7 Days title/count/date labels.
- [x] 3.2 Add or update a focused XCTest proving Next 7 Days row keys match Weekly Fajrcast visible keys.
- [x] 3.3 Run focused presentation/schedule tests.
