# monitors 

usando hyprl 

```
movecurrentworkspacetomonitor
```

o
## hupr land dpistacher
```
https://wiki.hypr.land/Configuring/Dispatchers/#list-of-dispatchers
```


```
bind = CTRL ALT $mainMod SHIFT, 2, movecurrentworkspacetomonitor, 2

or using left, and right

bind = CTRL ALT $mainMod SHIFT, comma, movecurrentworkspacetomonitor, l

bind = CTRL ALT $mainMod SHIFT, period, movecurrentworkspacetomonitor, r

### another configs to review 
bind = $mod, code:112, focusmonitor, +1
bind = $mod SHIFT, code:112, movewindow, mon:+1
bind = $mod SHIFT, P,  movecurrentworkspacetomonitor, +1
# added that to mimic i3's behavior, where pushing a workspace to another monitor also focuses it
bind = $mod SHIFT, P, focusmonitor, +1

```



link : moving windows to a workspace assignedn to a mointiro will create a new workspace 
https://github.com/hyprwm/Hyprland/issues/3495



https://www.youtube.com/watch?v=MA6Fkjm84D0&t=1s
