#  Todo list 
Before updating 

- finish privacy info view
- tapping qibla brings it into focus by switching with the moon, and shows a degrees label or something
- app ignoring custom location and swithcing to current for some reaosn....
- run with breakpoints everywhere to confirm control flow 
- keep swiftui from updating literally everything when the qibla view rotates. some states should not update everything 
- if custom alert time is longer than interval between two prayers, then use 15 minutse instead
- make sure notifications are always recalcualted when locations are changed
- get timezone of custom locations OR just tell user that the times they see are according to their iphone's timezone
- confirm that entry of coordinates when locations or maps arent allowed still works
- ios 13 color preview should change to current prayer when changing color modes
- find out why main ui is refreshed every second
- fix thing where location re-pans on the first try in custom mode 
- find the use of every .constant() to make sure its intentional
- test everything in dark and light mode, including the non ios 13+ version
- localize widgets
- monitor transition between every prayer time and end of solar midnight
- test on ios 13 
- test on ios 12 
- test on iphone X and Xr and mini 
- test on iphone 7 ios 14, 13, and 12
- add review request after foreground in ios (ensure not widget) is opened for the third time
- athan should play when we open the app within 1 minute of athan starting 
- athan should be stopped whenever we modify any settings 
- user should be able to stop athan playing 
- solar view does not reset when i reopen app after changing time. sus?
- consider switching row buttons to use a longpress gesture that scales intead, that way we wont have incorrect long press measurements that case them to scale unnecessarily

For later 
- dragging up on times table should bring up a monthly times table instead of just tomorrow times. nobody cares about tomorrow's times!
- allow users to add additional locations, and set one of the options as the "my location" for notifications and stuff
- be more efficent with notifications by not wasting notification budget on notifications from earlier in the day 
- consider matching baseline for prayer anme and time left in main interface

