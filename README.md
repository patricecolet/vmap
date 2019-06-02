# vmap
Graphical Interface for PureData Gem external

Dependences: Gem ggee hcs list-abs zexy mrpeach moocow

_videoMapper.pd_ is the main patch.
 
This project is unfinished yet, but shared to get advices and maybe some help.

- ggee is needed for getting directory where the main patch resides
- hcs is needed for accessing tcl command line and using tk widgets
- list-abs may not be necessary
- zexy is for converting symbols returned by tcl scripts into list (may not be necessary)
- mrpeach is used for resolving OSCx protocol
- moocow is converting into strings for the Gem*:text objects

Since Gem 0.94 is not working good yet, this project uses Gem 0.93 and opens other instances of pd for rendering previews.
Using multiple gemwin might be also usefull for drawing the interface instead using tcl-tk.
