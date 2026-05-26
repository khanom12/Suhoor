# Subh MVP Interaction Inventory v2

Date: 2026-05-03

This inventory captures the current MVP interaction universe for Subh based on the latest product decisions. Every scenario listed here is considered part of the MVP unless explicitly marked as an implementation note or test concern.

## Core MVP decisions now locked

1. All scenarios in this inventory are MVP scope.
2. The Home screen is hero-first.
3. The immediate next morning is controlled from the Home hero.
4. Main wake modes are: Fajr, Early, Quiet.
5. Selecting Early exposes reason selection.
6. The Early reason set is: Fasting, Tahajjud, Other.
7. If Early is selected but no explicit reason is chosen, the app resolves the reason to Tahajjud.
8. If Early -> Fasting is selected, fasting defaults to the best opportunity-based voluntary fast for that day when one exists.
9. If no fasting opportunity exists, Early -> Fasting defaults to a general voluntary fast.
10. Users can override fasting type on all non-Ramadan days where fasting is available.
11. Ramadan fasting is locked to Ramadan only. The user cannot override Ramadan into Qada, voluntary, Sunnah opportunity, or other fasting type.
12. On Eid days, fasting is unavailable. If the user selects Early, the app lands on Tahajjud.
13. Switching away from Early preserves the Early reason for that date.
14. Switching away from Early does not preserve manual wake-time adjustment. Wake time returns to the default timing anchor for the selected mode.
15. Quiet suppresses alarm, notification, and adhan behavior for that date only.
16. Quiet does not erase the underlying day meaning or preserved Early reason.
17. Adhan controls are available only in Day Detail, not on Home.
18. Monthly graphs show the baseline trend and use dots/markers for user modifications or schedule exceptions.
19. Date-specific Day Detail overrides beat recurring boundary rules.
20. Day Detail uses Done only. There is no Back option in the intended UI.
21. Day Detail has a prominent Reset to Defaults action separate from Done.
22. Past months are hidden in MVP. They are not browsable and not view-only.
23. Current month plus roughly the next 12 months are browsable and editable.
24. Future edits are saved and later hydrate Home and Next 10 when the date approaches.

## Resolution model

The app should resolve each morning in this order:

1. Calculate base prayer times and calendar context.
2. Apply Ramadan, Eid, and fasting-opportunity rules.
3. Apply global default wake behavior.
4. Apply recurring boundary rules.
5. Apply date-specific overrides from Day Detail, Home, Next 10, or Month browsing.
6. Apply Quiet suppression.
7. Resolve final wake time, adhan behavior, tags, and schedule status.
8. Persist the resolved state and schedule only what needs to be operationally scheduled.

## Scenario inventory

### A. First launch and onboarding

S001. User opens Subh for the first time. The onboarding introduction appears.
S002. User exits before completing onboarding. No active alarm should be assumed.
S003. User returns after exiting onboarding. Onboarding resumes or restarts in a clear state.
S004. User reads onboarding introduction and continues.
S005. User chooses automatic location.
S006. User grants automatic location permission. App uses device location for prayer times.
S007. User denies automatic location permission. App prompts for manual city or retry.
S008. User dismisses the location permission prompt. App treats location as unresolved.
S009. User chooses manual city.
S010. User searches for a city.
S011. User selects a city. App uses that city for prayer times.
S012. User cannot find a city. App offers retry, nearby/manual alternative, or automatic location.
S013. User changes selected city during onboarding.
S014. User accepts default prayer calculation method.
S015. User changes prayer calculation method.
S016. User accepts default wake behavior.
S017. User grants alarm/notification permission. App can schedule wake behavior.
S018. User denies alarm/notification permission. App enters limited reliability state.
S019. User completes onboarding with all requirements satisfied. Home opens ready.
S020. User completes onboarding with partial setup. Home opens with visible missing-requirement warning.

### B. Home arrival and hero viewing

S021. User lands on Home after onboarding. Hero is visually dominant.
S022. User views immediate next morning wake time.
S023. User views Fajr start context.
S024. User views current mode: Fajr, Early, or Quiet.
S025. User views current intention only when applicable.
S026. User views permission/reliability state if degraded.
S027. User views Ramadan, Eid, fasting opportunity, Quiet, custom, or Early tags where applicable.

### C. Home hero: Fajr mode

S028. User views default Fajr mode. Wake uses the default Fajr-based timing.
S029. User taps Fajr while already in Fajr. State remains stable.
S030. User taps Fajr repeatedly. No duplicate alarms or duplicate state records are created.
S031. User switches from Early to Fajr. Early reason is preserved for that date but inactive.
S032. User switches from Early to Fajr. Manual wake-time adjustment is cleared/reset to the selected mode default.
S033. User switches from Quiet to Fajr. Quiet suppression is removed.
S034. User switches from Quiet to Fajr. Alarm is active again if permissions allow.

### D. Home hero: Early mode and reasons

S035. User selects Early. Reason selection becomes available.
S036. User selects Early but does not explicitly choose a reason. App resolves to Tahajjud.
S037. User selects Early -> Tahajjud. Fasting controls are hidden.
S038. User selects Early -> Other. Fasting controls are hidden.
S039. User selects Early -> Fasting. Fasting type controls appear.
S040. User switches Early reason from Tahajjud to Fasting.
S041. User switches Early reason from Fasting to Tahajjud. Fasting subtype becomes inactive.
S042. User switches Early reason from Fasting to Other. Fasting subtype becomes inactive.
S043. User taps Early repeatedly. State remains stable and reason is not duplicated.
S044. User switches Fajr -> Early -> Fajr -> Early. Preserved Early reason returns, but time adjustment does not.
S045. User switches Early -> Quiet -> Early. Preserved Early reason returns, but time adjustment does not.

### E. Home hero: fasting behavior

S046. User selects Early -> Fasting on a day with a fasting opportunity. App defaults to that opportunity-based voluntary fast.
S047. User selects Early -> Fasting on a day without a fasting opportunity. App defaults to general voluntary fast.
S048. User overrides opportunity-based fast to Qada on a non-Ramadan day.
S049. User overrides opportunity-based fast to general voluntary fast on a non-Ramadan day.
S050. User overrides opportunity-based fast to another available personal fasting type on a non-Ramadan day.
S051. User returns from override to the default fasting opportunity.
S052. User selects Early -> Fasting during Ramadan. Fasting type is locked to Ramadan.
S053. User attempts to select Qada, voluntary, Sunnah opportunity, or other fasting type during Ramadan. App prevents or hides those options.
S054. User selects Early on an Eid day. App lands on Tahajjud.
S055. User attempts to select Fasting on an Eid day. Fasting is unavailable.

### F. Home hero: Quiet mode

S056. User selects Quiet from Fajr. Alarm, notification, and adhan are suppressed for that date.
S057. User selects Quiet from Early. Underlying Early reason is preserved for that date.
S058. User selects Quiet during Ramadan. Ramadan meaning remains; alarm/adhan are suppressed.
S059. User exits Quiet to Fajr. Quiet suppression is removed.
S060. User exits Quiet to Early. Preserved Early reason returns.
S061. User taps Quiet repeatedly. State remains stable; no duplicate suppression records.
S062. User selects Quiet for one date. Next day remains normal unless separately modified.

### G. Home hero: wake-time adjustment

S063. User adjusts immediate wake time from Home in Fajr mode. A date-specific time adjustment is saved for the immediate morning.
S064. User adjusts immediate wake time from Home in Early mode. A date-specific Early adjustment is saved for the immediate morning.
S065. User resets immediate wake time to default. The date-specific time adjustment is removed.
S066. User adjusts time and then switches to Fajr. Manual time adjustment is not preserved; selected mode default applies.
S067. User adjusts time and then switches to Early. Manual time adjustment is not preserved; selected mode default applies.
S068. User adjusts time and then switches to Quiet. Quiet suppresses execution; manual adjustment is not preserved across mode change.
S069. User tries to adjust time while Quiet is active. App should disable or clearly suppress the control.
S070. User drags slider repeatedly. Final displayed wake time and scheduled wake time match.

### H. Home hero: adhan exposure

S071. User looks for adhan controls on Home. They are not shown.
S072. User wants to edit adhan for a date. User must open Day Detail.
S073. Quiet is active for a date. Adhan is inactive/suppressed for that date.

### I. Collapsed Next 10 Mornings

S074. User sees collapsed Next 10 Mornings. It does not visually compete with the hero.
S075. User expands Next 10 Mornings. Ten upcoming mornings appear.
S076. User collapses Next 10 Mornings. No wake state changes.
S077. User scrolls expanded Next 10. UI-only interaction.
S078. User taps a day in Next 10. Day Detail opens for that date.
S079. User returns from edited Day Detail. The corresponding row updates.
S080. Tomorrow is edited from Next 10. Home hero updates too.

### J. Day Detail entry and viewing

S081. User opens Day Detail from Home hero.
S082. User opens Day Detail from Next 10.
S083. User opens Day Detail from monthly day list.
S084. User opens Day Detail from Adjusted Days repository.
S085. User views a default ordinary day. Default state is shown.
S086. User views a modified day. Saved override is shown.
S087. User views a Ramadan day. Ramadan context is shown and fasting is locked.
S088. User views an Eid day. Fasting is unavailable.

### K. Day Detail editing

S089. User selects Fajr in Day Detail. Selected date becomes Fajr mode.
S090. User selects Early in Day Detail. Early reason controls appear.
S091. User selects Early -> Tahajjud in Day Detail.
S092. User selects Early -> Other in Day Detail.
S093. User selects Early -> Fasting in Day Detail.
S094. User changes fasting subtype in Day Detail on a non-Ramadan day.
S095. User attempts to change fasting subtype in Day Detail on Ramadan. App prevents or hides other options.
S096. User selects Early on Eid in Day Detail. App lands on Tahajjud.
S097. User selects Quiet in Day Detail. Alarm/notification/adhan are suppressed for that date.
S098. User switches repeatedly among Fajr, Early, and Quiet in Day Detail. Final visible state is the saved state.
S099. User adjusts selected date wake time in Day Detail. Date-specific override is saved if Done is pressed.
S100. User toggles adhan on in Day Detail. Adhan preference is saved for that date if Done is pressed.
S101. User toggles adhan off in Day Detail. Adhan preference is saved for that date if Done is pressed.
S102. User toggles adhan while Quiet is active. Adhan is shown as inactive or suppressed.
S103. User presses Done. Changes are saved and previous screen refreshes.
S104. User expects Back navigation. Intended UI has no Back option.
S105. Platform back/swipe gesture occurs. Implementation should disable it or guard against unsaved changes.
S106. User presses Reset to Defaults. Date returns to calendar/default behavior.
S107. Reset to Defaults on ordinary day returns to Fajr default.
S108. Reset to Defaults on Ramadan day returns to Early -> Fasting -> Ramadan.
S109. Reset to Defaults on Eid returns to the app-defined Eid default where fasting is unavailable.

### L. Browse by Month entry

S110. User sees collapsed Browse by Month card.
S111. User expands Browse by Month card.
S112. User opens full month browsing.
S113. User chooses Gregorian month browsing.
S114. User chooses Hijri month browsing.
S115. User switches between Gregorian and Hijri browsing. Date-specific overrides remain attached to civil dates.

### M. Gregorian month browsing

S116. User views current Gregorian month.
S117. User selects a future Gregorian month within horizon.
S118. User advances to next Gregorian month.
S119. User attempts to go before current month. Past months are hidden.
S120. User attempts to go beyond supported future horizon. App prevents or disables further navigation.
S121. User scrolls the Gregorian month day list. UI-only interaction.
S122. User taps a Gregorian month day. Day Detail opens for that civil date.

### N. Hijri month browsing

S123. User views current Hijri month.
S124. User selects a future Hijri month within horizon.
S125. User browses Ramadan. Ramadan days show locked Ramadan fasting context.
S126. User browses a Hijri month with fasting opportunities. Opportunity tags are shown where applicable.
S127. User browses a Hijri month containing Eid. Fasting is unavailable on Eid days.
S128. User taps a Hijri month day. Day Detail opens for the mapped civil date.
S129. User changes Hijri/Gregorian view while a date is selected. App preserves context where possible.

### O. Monthly Fajrcast

S130. User views monthly Fajrcast trend. It shows the baseline Fajr/wake trend.
S131. User scrubs monthly graph. Selected day info appears; no persisted state changes.
S132. User taps a graph point. Corresponding day can be highlighted or previewed.
S133. User has modified days in the month. Graph displays dots/markers for exceptions.
S134. User sees graph baseline and row-specific override. UI should make the distinction understandable.

### P. Monthly day list and future edits

S135. User views monthly day list. Rows show date, wake time, and tags.
S136. User taps a monthly day. Day Detail opens.
S137. User modifies a day months ahead. Future override is saved after Done.
S138. User revisits a modified future day. Saved override loads.
S139. User resets a modified future day. Override is deleted.
S140. Future override later enters Next 10. Next 10 row hydrates saved override.
S141. Future override later becomes immediate next morning. Home hero hydrates saved override.
S142. Future override affects a date within scheduling window. Alarm scheduling uses it.
S143. Future override is outside scheduling window. App saves it without necessarily scheduling immediately.

### Q. Adjusted Days repository

S144. User opens Adjusted Days repository.
S145. User views future days that differ from default.
S146. User filters adjusted days by Quiet.
S147. User filters adjusted days by Early.
S148. User filters adjusted days by Fasting.
S149. User filters adjusted days by Tahajjud.
S150. User filters adjusted days by custom wake time.
S151. User taps an adjusted day. Day Detail opens.
S152. User resets one adjusted day. One override is removed.
S153. User resets all adjusted days. Confirmation is required.
S154. Reset all affects immediate or near-term dates. Home, Next 10, and scheduling refresh.

### R. Weekly Fajrcast

S155. User sees collapsed Weekly Fajrcast.
S156. User expands Weekly Fajrcast.
S157. User scrubs Weekly Fajrcast. UI-only interaction.
S158. User collapses Weekly Fajrcast.
S159. User taps Weekly Fajrcast expecting legacy detail. Legacy detail should not open.

### S. Settings: entry and visible sections

S160. User opens Settings.
S161. User opens Location settings.
S162. User opens Prayer Time settings.
S163. User opens Hijri Calendar settings.
S164. User opens Presets/Boundary Rules.
S165. User opens About.
S166. User opens Send Feedback.
S167. User looks for removed technical settings. Morning Rules, Reliability Basic, Quiet Period, and Copy Diagnostics should not appear unless intentionally retained.

### T. Settings: location

S168. User views current location mode.
S169. User switches from manual city to automatic location with permission already granted.
S170. User switches from manual city to automatic location and grants permission.
S171. User switches to automatic location and denies permission. App remains unresolved or falls back to manual city.
S172. User switches from automatic to manual city.
S173. User changes manual city.
S174. Location change causes prayer times, Home, Next 10, month views, and scheduling to recompute.
S175. Date-specific overrides remain attached to civil dates after location change.

### U. Settings: prayer time

S176. User changes calculation method.
S177. User adjusts Fajr start offset.
S178. User adjusts Fajr end offset.
S179. User adjusts Maghrib offset.
S180. User resets prayer-time adjustments.
S181. Prayer-time changes recompute defaults and reschedule affected near-term alarms.
S182. Date-specific overrides remain but resolve against the new base times where applicable.

### V. Settings: Hijri calendar

S183. User views Hijri month adjustments.
S184. User adds +1 day to a Hijri month.
S185. User subtracts -1 day from a Hijri month.
S186. User resets a Hijri month adjustment.
S187. Hijri adjustment shifts Ramadan, Eid, and fasting opportunity tags.
S188. User changes Hijri adjustment after future Ramadan override exists. Civil-date override remains attached to the civil date.
S189. A saved Ramadan-specific intention becomes invalid after Hijri adjustment. App preserves wake plan and marks/re-resolves calendar meaning safely.

### W. Settings: recurring boundary rules

S190. User opens boundary-rule settings.
S191. User creates a latest-wake boundary, such as wake no later than 5:30 AM.
S192. User selects weekdays for the boundary rule.
S193. User saves boundary rule. Future defaults recompute.
S194. User edits boundary time. Future defaults recompute.
S195. User disables boundary rule. Lower-priority defaults return unless date-specific overrides exist.
S196. Boundary says 5:30 but default Fajr wake is 5:50. Resolved wake becomes 5:30.
S197. Boundary says 5:30 but fasting/Tahajjud wake is 4:40. Resolved wake remains 4:40.
S198. Boundary conflicts with date-specific custom time. Date-specific override wins.
S199. Boundary conflicts with Quiet. Quiet wins.

### X. About and feedback

S200. User opens About. App info, version, and methodology are readable.
S201. User opens Send Feedback. Email composer opens.
S202. User sends feedback. App state remains unchanged.
S203. User cancels feedback. App state remains unchanged.
S204. Email composer cannot open. App shows an alternate recovery path if available.

### Y. Permissions after onboarding

S205. User revokes alarm/notification permission outside app.
S206. User returns to app after revoking alarm/notification permission. Home shows degraded reliability.
S207. User plans an Early/Fasting day while alarm permission is missing. Plan is saved but app warns it cannot reliably wake user.
S208. User restores alarm/notification permission. Scheduling resumes.
S209. User revokes location permission while automatic location is active.
S210. User returns to app after location permission is revoked. App prompts for permission restore or manual city.
S211. User restores location permission. Prayer times recompute.

### Z. Alarm execution and post-alarm behavior

S212. Alarm rings normally. User dismisses or opens app, depending on platform support.
S213. Alarm does not ring because Quiet was selected. This is intentional.
S214. Alarm cannot ring because permission is missing. App treats this as reliability failure, not Quiet.
S215. User opens app after scheduled wake time has passed. Home advances to the next relevant morning.
S216. Day changes at midnight. Home and Next 10 refresh to the new date context.
S217. User changes system time zone. App verifies/recomputes relevant local time behavior.
S218. User travels while automatic location is active. App updates location and prayer times.
S219. User travels while manual city is active. App continues using manual city.

### AA. Cross-surface consistency

S220. User edits tomorrow from Home. Home, Next 10, monthly row, and scheduling align.
S221. User edits tomorrow from Next 10. Home hero, Next 10, monthly row, and scheduling align.
S222. User edits tomorrow from monthly browsing. Home hero, Next 10, monthly row, and scheduling align.
S223. User edits a far-future day from monthly browsing. Monthly row and Adjusted Days update; Home/Next 10 update later.
S224. User resets a day from Adjusted Days. All surfaces return to default for that date.
S225. User changes Settings after editing days. Defaults recompute while date-specific overrides persist.

### AB. Rapid and repeated interactions

S226. User rapidly switches Fajr -> Early -> Quiet -> Fajr -> Early.
S227. User rapidly changes Early reason: Tahajjud -> Fasting -> Other -> Tahajjud.
S228. User rapidly changes fasting subtype on a non-Ramadan day.
S229. User rapidly drags slider and then changes mode.
S230. User opens Day Detail, changes state, presses Done, reopens. Saved state persists.
S231. User opens Day Detail, resets defaults, presses Done, reopens. Default state persists.
S232. User modifies a future day, changes settings, revisits the day. Stored override and recomputed default are coherent.
S233. User repeatedly expands/collapses Next 10, Browse by Month, and Weekly Fajrcast. No product state changes.
S234. Final displayed wake time always matches the scheduled alarm for active, permitted, non-Quiet dates.
S235. Quiet dates never schedule wake alarm, notification, or adhan for that date.

## Codex audit prompt

Use this prompt when asking Codex to assess the current implementation:

"Review the current Subh codebase against `subh_mvp_interaction_inventory_v2.md`. For each scenario ID, classify implementation status as Implemented, Partially Implemented, Missing, Risky, or Not Testable Yet. For every Missing or Risky scenario, identify the relevant files, state models, scheduling logic, persistence logic, UI components, and tests required. Pay special attention to: Early reason preservation, manual time adjustment reset on mode switch, Ramadan fasting lock, Eid fasting unavailability, Quiet suppression of alarm/notification/adhan, Day Detail Done-only behavior, date-specific override priority over boundary rules, future override hydration into Next 10 and Home, and cross-surface consistency."
