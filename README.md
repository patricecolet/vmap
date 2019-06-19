# vmap
Graphical Interface for PureData-0.49.0 Gem-0.93.3  

Dependences: Gem>=0.93.3 ggee hcs list-abs zexy mrpeach moocow

_videoMapper.pd_ is the main patch.
 
This project is unfinished yet, but shared to get advices and maybe some help.

- ggee is needed for getting directory where the main patch resides
- hcs is needed for accessing tcl command line and using tk widgets
- list-abs may not be necessary
- zexy is for converting symbols returned by tcl scripts into list (may not be necessary)
- mrpeach is used for resolving OSCx protocol (not used yet)
- moocow is converting into strings for the Gem*:text objects (not used yet)

This opens other  pd instances for rendering previews, it's usefull for preventing crashes.
