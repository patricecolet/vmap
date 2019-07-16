################################### vmap-gui.tcl ############################
##                                                                          #
##																			#
## User Interface for videomapper.pd, a Gem frontend.	                    #
## PureData uses [hcs/sys_gui] for running procedures.		                #
##																			#
## patko2019																#		
#############################################################################

#### SETUP ####
package require tkdnd

package require BWidget
namespace eval ::patco::vmap:: {
}

proc ::patco::vmap::setup {w} {
    # check if we are Pd < 0.43, which has no 'pdsend', but a 'pd' coded in C
    if {[llength [info procs "::pdsend"]] == 0} {
        pdtk_post "creating 0.43+ 'pdsend' using legacy 'pd' proc"
        proc ::pdsend {args} {pd "[join $args { }] ;"}
    }
	catch {console show}	
	font create title -family {Lucida Sans} -size 10 -weight bold
	font create little -family {Lucida Sans} -size 7
        variable settings
        set settings {}
	pdsend "$w.SetupDone bang"
}
## Prepare workspace for a project
proc ::patco::vmap::newProject {dir} {    
    cd $dir
    set subdir [llength [glob -nocomplain -type d Project*]]
    if [file exist Project$subdir] {
        set subdir [join {$subdir - [llength [glob -nocomplain -type d Project$subdir*]} ""]}
    file mkdir Project$subdir
    file mkdir Project$subdir/img
    file mkdir Project$subdir/video
    file mkdir Project$subdir/multiimg
    file mkdir Project$subdir/stream
    pdsend "projectFile symbol Project$subdir/data"
    pdsend "projectName symbol Project$subdir"
    pdsend "workingDirectory symbol ${dir}/Project${subdir}"
    pdsend "file new"
}

### view procedures
proc ::patco::vmap::xview {w args} {
	foreach wid [list $w.c] {
	eval [linsert $args 0 $wid xview]}
}
proc ::patco::vmap::yview {w args} {
	eval [linsert $args 0 $w.tf.cg yview]
	eval [linsert $args 0 $w.tf.ck yview]
}
proc ::patco::vmap::menusend {c} {
    pdsend "vmapgui-s menu $c"
}
proc ::patco::vmap::resizepane {w i p} {
	global settings
	$w sash place $i 0 $settings($p)
}

### panes drawing procedure
proc ::patco::vmap::drawPane {n w list f} {
	global settings

	foreach {pane text i h} $list {
		set $pane [ttk::labelframe $w.$pane -text $text]
		set settings($w.$pane.expand) $h
##		set expand [ttk::checkbutton $w.$pane.expand -text "$text"\
##			 	-variable settings($w.$pane.expand)\
##			 	-command "::patco::vmap::resizepane $w $i $w.$pane.expand"\
##				-onvalue $h -offvalue 15]
##			grid $expand -sticky nw -columnspan $colspan
			set colspan 5
		$w add $w.$pane
		$w paneconfigure $w.$pane -minsize $h

	}
	grid $w
	$n add $n.$f -text [lindex $list 1]
}
### Edit selector drawing procedure
proc ::patco::vmap::drawComboSelect {w name} {
	global settings
	ttk::combobox $w.cbox -width 10 \
		-textvariable "::patco::vmap::sendcbox $w.cbox $name Return"
	bind $w.cbox <<ComboboxSelected>> "::patco::vmap::sendcbox %W $name Sel"
	foreach B {add del copy paste clear} {
	ttk::button $w.$B -text "$B" -width 5 -command [list pdsend "vmapgui-s $name $B bang"]}
	
	checkbutton $w.render -text "Render" -variable settings(${name}Render) -width 5 \
		-command "::patco::vmap::sendvar $name view Render $name"
    if {$name in [list tex scn] } {
	checkbutton $w.play -text "Play" -variable settings(${name}Play) -width 5 \
		-command "::patco::vmap::sendvar $name view Play $name" }
		
    foreach { wid col row colspan } {copy 0 1 1 paste 1 1 1 clear 2 1 2 cbox 0 2 2  add 2 2 1  del 3 2 1 render 0 3 1} {
		grid $w.$wid -column $col -row $row -columnspan $colspan -sticky nsew -padx 2 -pady 2 }
		if {$name in [list tex scn]} {
		grid $w.play -column 1 -row 3 -columnspan 1 -sticky news -padx 2 -pady 2}
}
### modulator window widget

proc ::patco::vmap::drawModul {w id} {

	global settings
	toplevel $w
	foreach {l t} {param Modulation lfo LFO} {
		grid [labelframe $w.$l -text $t] -sticky news
		grid [ checkbutton $w.$l.enable -text "Enable" -state disabled \
		-variable settings(${l}enable) -width 5 \
		-command "::patco::vmap::sendvar modul $l enable $l" ] -columnspan 2 -row 0 
		}
	$w.param.enable configure -state normal
	grid [spinbox $w.param.id -from 0.00 -to 0.00 -increment 1 -width 4 -state disabled\
				 -font {Courier -12} \
				 -textvariable settings(idmodul)\
			 	-command "::patco::vmap::sendvar modul id modul id "] -column 0 -row 1
	grid [label $w.param.idtext -text "Index"] -column 1 -row 1
	grid [button $w.param.add -text "Add" -state disabled \
		-command [list pdsend "vmapgui-s modul param add"]] -columnspan 2 -row 2
	grid [ttk::menubutton $w.lfo.mb -width 10 -state disabled \
		-menu $w.lfo.menu -text "Waveshape"] -columnspan 2 -row 1
	menu $w.lfo.menu -tearoff 0
	foreach wave {sine square sawtooth pwm random} {
		$w.lfo.menu add command -label $wave -command [list pdsend "vmapgui-s modul lfo $wave"]
		}
	grid [label $w.lfo.waveshape -text "sine" -state disabled] -columnspan 2 -row 2
	grid [scale $w.lfo.freq -label "Frequency" \
		-command "::patco::vmap::sendscale modul lfo freq" \
		-orient hor -from 0.01 -to 100.00 -resolution 0.01] -columnspan 2 -row 3
	##$w.lfo.freq configure -command "::patco::vmap::sendscale modul lfo freq" 
	grid [scale $w.lfo.amp -label "Amplitude" \
		-orient hor -from 0.00 -to 100.00\
		-command "::patco::vmap::sendscale modul lfo amp" ] -columnspan 2 -row 4
	grid [labelframe $w.oscx -text OSCx] -sticky news
	grid [label $w.oscx.adress -width 10 \
		-text "/mod/$id" ] -columnspan 2 -row 1

	grid [labelframe $w.midi -text MIDI] -sticky news
	foreach p {value freq amp} {
	    set settings($p) "none"
	    grid [button $w.midi.learn-$p -text "Learn $p" -state disabled \
			 	-command [list pdsend "vmapgui-s modul midi learn $p"]] -columnspan 2		
		grid [label $w.midi.label-$p -textvariable settings($p)] -columnspan 2
		}
}

proc ::patco::vmap::colorPanel {p i} {
	
	global settings
	foreach {v u} {R r G g B b} {upvar settings(rgb${p}$v) $u}
	set initialColor [format "#%02x%02x%02x" [expr int($r*256)] [expr int($g*256)] [expr int($b*256)]]
	set color [tk_chooseColor -initialcolor $initialColor]
	if {$color != ""} {
		set rgb [winfo rgb . $color]
		foreach {c id} { R 0 G 1 B 2} {
			::patco::vmap::sendscale matRgbScale $p $c [expr [lindex $rgb $id]/ 65536.0]}}
}


proc ::patco::colorpanel {w p pw t v d} {
	labelframe $w -text $t -fg black
	grid [button $w.button \
		-command "::patco::colorpanelBG $w.button $p $pw $v"  \
		-bg $d -width 5] -sticky nesw -row 0 -column 1
	grid [button $w.but -bg azure -width 1 \
		-command [list pdsend "vmapgui-s mod $p $pw $t" ]] -sticky nesw -row 0 -column 0
}
proc ::patco::colorpanelBG {w p pw v} {
	global settings
	set settings($p$pw$v) [tk_chooseColor]
	$w configure -bg $settings($p$pw$v)
	pdsend "vmapgui-s $p $pw $v [winfo rgb . $settings($p$pw$v)]"
}
proc ::patco::checkbutton {w p pw cb n args} {
	global settings
	labelframe $w -text $n -fg black
	ttk::checkbutton $w.$cb
	foreach {p a} $args {
		$w.$cb configure $p $a	
	}  
	
	$w.$cb configure -variable settings($p$pw$n) -command [list ::patco::vmap::sendsbox $p $pw $n]
	grid $w.$cb -sticky nesw -row 0 -column 1
	grid [button $w.but -bg azure -width 1 -command [list pdsend "vmapgui-s mod $p $pw $n" ]] -sticky nesw -row 0 -column 0	
}
proc ::patco::menubutton {w p n args} {
	labelframe $w -text $n -fg black
	ttk::menubutton $w.mb
	foreach {p a} $args {
		$w.mb configure $p $a	
	}
	grid $w.mb -sticky nesw -row 0 -column 1
	grid [button $w.but -bg azure -width 1 -command [list pdsend "vmapgui-s mod $p $n" ]] -sticky nesw -row 0 -column 0	
}
proc ::patco::spinbox {w p pw n args} {
	global settings
	labelframe $w -text $n -fg black
	ttk::spinbox $w.spin  -command [list ::patco::vmap::sendsbox $p $pw $n]
	foreach {o a} $args {
		$w.spin configure $o $a 
	}
	$w.spin configure -textvariable settings($p$pw$n)
	grid $w.spin -sticky nesw -row 0 -column 1
	grid [button $w.but -bg azure -width 1 -command [list pdsend "vmapgui-s mod $p $pw $n" ]] -sticky nesw -row 0 -column 0	
}
proc ::patco::spinbox2 {w p pw n s1 s2 args} {
	global settings
	labelframe $w -text $n -fg black
	ttk::spinbox $w.spin -command [list ::patco::vmap::sendsboxes $p $pw $n $s1]
	ttk::spinbox $w.spin2 -command [list ::patco::vmap::sendsboxes $p $pw $n $s2]
	foreach {o a} $args {
		$w.spin configure $o $a
		$w.spin2 configure $o $a
	}
	$w.spin configure -textvariable settings($p$pw$n$s1)
	$w.spin2 configure -textvariable settings($p$pw$n$s2)
	grid $w.spin -sticky nesw -row 0 -column 1
	grid $w.spin2 -sticky nesw -row 0 -column 2
	grid [button $w.but -bg azure -width 1 -command [list pdsend "vmapgui-s mod $p $pw $n" ]] -sticky nesw -row 0 -column 0	
}
proc ::patco::spinbox3 {w p pw n s1 s2 s3 args} {
	global settings
	labelframe $w -text $n -fg black
	ttk::spinbox $w.spin  -command [list ::patco::vmap::sendsboxes $p $pw $n $s1]
	ttk::spinbox $w.spin2 -command [list ::patco::vmap::sendsboxes $p $pw $n $s2]
	ttk::spinbox $w.spin3 -command [list ::patco::vmap::sendsboxes $p $pw $n $s3]
	foreach {o a} $args {
		$w.spin configure $o $a
		$w.spin2 configure $o $a
		$w.spin3 configure $o $a
	}
	$w.spin configure -textvariable settings($p$pw$n$s1)
	$w.spin2 configure -textvariable settings($p$pw$n$s2)
	$w.spin3 configure -textvariable settings($p$pw$n$s3)
	grid $w.spin -sticky nesw -row 0 -column 1
	grid $w.spin2 -sticky nesw -row 0 -column 2
	grid $w.spin3 -sticky nesw -row 0 -column 3
	grid [button $w.but -bg azure -width 1 -command [list pdsend "vmapgui-s mod $p $pw $n" ]] -sticky nesw -row 0 -column 0	
}

### topwindow widget
proc ::patco::vmap::draw {w filename} {
	global settings
	toplevel $w -borderwidth 0 -background black
################ Menu Bar #################
	set m [menu $w.menu]
	$w configure -menu $m
	menu $m.file -tearoff 0
	menu $m.help -tearoff 0
	$m add cascade -menu $m.file -label "File"
	$m add cascade -menu $m.help -label "Help"
	foreach item { "New" "Open..." "Save" "Save as..." "Close" } command {
			"newFile" "openFile" "saveFile" "saveAsFile" "closeFile"} {
		$m.file add command -label $item -command "::patco::vmap::menusend $command" }
	$m.help add command -label "About vmap" -command "readme"
########################## Notebook Panels and Paned windows #########
	ttk::notebook $w.n
	
	foreach { frame panel } { 
	    win {set "Render" 0 10 layout "Layout" 1 20 lighting "Lighting" 2 30 camera Camera 3 40 texunit Texunit 4 40}
	    media {media "Media" 1 20}
	    tex {set "Texture" 0  10 media "Media" 1 20 fx "Texture Effect" 3 350}
	    mat {set "Material" 0  10 param "Parameter" 1 200 tex "Texture" 2 50}  
		obj {set "Object" 0  10 tree "Tree" 1 100 geo "Surface" 2 100 trans "Transform" 3 100} 
		map {set "Map"  0  10 vertex "Vertex Position" 1 20 texCoord "Texture Coordinates" 2 20 \
			shade "Shading" 3 20 framebuffer "Frame Buffer" 4 20}
		scn {set "Scene" 0  10 maps "Maps" 1  10 obj "Object" 2 220 \
		 lights "Lights" 3 10 keyframes "Keyframes" 4 200} 
    }   { 
	    set $frame [ttk::frame $w.n.$frame]
		set ${frame}Pw [panedwindow $w.n.$frame.pw -orient vertical -sashrelief sunken]
		patco::vmap::drawPane $w.n $w.n.$frame.pw $panel $frame
        if {$frame != "media"} {patco::vmap::drawComboSelect $w.n.$frame.pw.set $frame}
	}
################ Render Panel ################

	
    set layout $w.n.win.pw.layout
    set lighting $w.n.win.pw.lighting
    set camera $w.n.win.pw.camera
    set texunit $w.n.win.pw.texunit
	
################ Map Panel ################

    set framebuffer $w.n.map.pw.framebuffer
	
##### spinboxes
	foreach {p pw sb n width i f t col row} {
			win layout stereoSep StereoSep 6 1 -99 99 1 2 			
			win lighting shininess Shininess 4 0.01 0 1 0 2
			win lighting fog Fog 4 0.01 0 1 0 1
			win layout frame Frame 3 1 1 512 1 1 
			map shade top Top 4 0.01 0 1 0 0  
			map shade left Left 4 0.01 0 1 1 0  
			map shade right Right 4 0.01 0 1 2 0  
			map shade bottom Bottom 4 0.01 0 1 3 0  
		} {
		set settings($p$pw$n) $f 
		::patco::spinbox $w.n.$p.pw.$pw.$sb $p $pw $n -width $width -increment $i -from $f -to $t
		grid $w.n.$p.pw.$pw.$sb -row $row -column $col -sticky news
	}

	foreach {p pw sp n s1 s2 width i f t col row colspan} {  
			win layout dimen Dimen X Y 4 1 64 8096 0 0 1
			win layout offset Offset X Y 4 1 0 8096 1 0 2
			map vertex topleft TopLeft X Y 6 0.01 -99.99 99.99 0 0 1
			map vertex topcenter TopCenter X Y 6 0.01 -99.99 99.99 1 0 1
			map vertex topright TopRight X Y 6 0.01 -99.99 99.99 2 0 1
			map vertex centerleft CenterLeft X Y 6 0.01 -99.99 99.99 0 1 1
			map vertex center Center X Y 6 0.01 -99.99 99.99 1 1 1
			map vertex centerright CenterRight X Y 6 0.01 -99.99 99.99 2 1 1
			map vertex bottomleft BottomLeft X Y 6 0.01 -99.99 99.99 0 2 1
			map vertex bottomcenter BottomCenter X Y 6 0.01 -99.99 99.99 1 2 1
			map vertex bottomright BottomRight X Y 6 0.01 -99.99 99.99 2 2 1
			map texCoord topleft TopLeft X Y 4 1 0 8096 0 0 1
			map texCoord topright TopRight X Y 4 1 0 8096 1 0 1
			map texCoord curveleft BottomLeft X Y 4 1 0 8096 0 1 1
			map texCoord curveright BottomRight X Y 4 1 0 8096 1 1 1
			map framebuffer dimen Dimen X Y 4 1 64 8096 0 1 1
		} {
		set settings($p$pw$n$s1) $f
		set settings($p$pw$n$s2) $f
		::patco::spinbox2 $w.n.$p.pw.$pw.$sp $p $pw $n $s1 $s2 -width $width -increment $i -from $f -to $t
		grid $w.n.$p.pw.$pw.$sp -row $row -column $col -sticky nesw -columnspan $colspan
	}	

	foreach {p pw sp n s1 s2 s3 width i f t col row colspan} {  
			win camera view Camera X Y Z 6 0.01 -99 99 0 0 1 
			win camera target Target X Y Z 6 0.01 -99 99 0 1 1
			win camera up Up X Y Z 6 0.01 -99 99 0 2 1
			win camera leftRightBottom LeftRightBottom Left Right Bottom  6 0.01 -99 99 0 3 1
			win camera topFrontBack TopFrontBack Top Front Back  6 0.01 -99 99 0 4 1
			map framebuffer leftRightBottom LeftRightBottom Left Right Bottom  6 0.01 -99 99 0 2 2
			map framebuffer topFrontBack TopFrontBack Top Front Back  6 0.01 -99 99 0 3 2
			map framebuffer scale Scale X Y Z 6 0.01 -99 99 0 4 2
			map framebuffer translate Translate X Y Z 6 0.01 -99 99 0 5 2
			map framebuffer rotate Rotate X Y Z 6 0.01 -99 99 0 6 2
		} {
		set settings($p$pw$n$s1) $f
		set settings($p$pw$n$s2) $f
		set settings($p$pw$n$s3) $f
		::patco::spinbox3 $w.n.$p.pw.$pw.$sp $p $pw $n $s1 $s2 $s3 -width $width -increment $i -from $f -to $t
		grid $w.n.$p.pw.$pw.$sp -row $row -column $col -sticky nesw -columnspan $colspan
	}	
##### checkbuttons	
	foreach {p pw cb n col row colspan} { 
			win layout fullscreen Fullscreen 3 0 1
			win layout buffer Buffer 2 1 1
			win layout cursor Cursor 3 1 1
			win layout stereoLine StereoLine 2 2 1
			win layout topmost Topmost 3 2 1
			win lighting lighting Lighting 1 2 1
			win lighting worldlight Worldlight 2 2 1
			map framebuffer rectangle Rectangle 2 0 1} {
		set settings($p$pw$n) 0
		::patco::checkbutton $w.n.$p.pw.$pw.$cb $p $pw $cb $n
		grid $w.n.$p.pw.$pw.$cb -column $col -row $row -columnspan $colspan -sticky nesw
	}

##### menubuttons		
	foreach {p pw mb menu text col row width colspan} {   
			win layout fsaamb fsaa "Anti Aliasing" 0 1 10 1
			win layout stereomb stereo "Stereo Mode" 0 2 10 1
			win lighting fogmb fogmod "Fog Mode" 0 0 6 1
			map framebuffer typemb type "Type" 0 0 6 1
			map framebuffer formatmb format "Format" 1 0 6 1
			} {
		::patco::menubutton $w.n.$p.pw.$pw.$mb $p $menu -width 10 -menu $w.n.$p.pw.$pw.$menu -text $text
		grid $w.n.$p.pw.$pw.$mb -row $row -column $col -columnspan $colspan -sticky sw
	}
	
	menu $layout.fsaa -tearoff 0
	set settings(winlayoutFSAA) 0
	for {set i 0} {$i < 8} { incr i } { 
		$layout.fsaa add radiobutton -label $i \
			-command [list ::patco::vmap::sendsbox win layout FSAA] \
			-variable settings(winlayoutFSAA)
	}
		
	menu $layout.stereo -tearoff 0	
	foreach { m v }  {off 0 "2 screens" 1 "Red / Green" 2 "Crystal Glass" 3} {
		$layout.stereo add radiobutton -label $m -value $v \
			-command [list ::patco::vmap::sendsbox win layout Stereo] \
			-variable settings(winlayoutStereo) 
	}

	menu $lighting.fogmod -tearoff 0
	foreach { m v }  {off 0 Linear 1 Exp 2 "Exp^2" 3} {
		$lighting.fogmod add radiobutton -label $m -value $v \
			-command [list ::patco::vmap::sendsbox win lighting FogMode] \
			-variable settings(winlightingFogMode)  }

	menu $framebuffer.type -tearoff 0
	foreach { m v }  {BYTE 0 INT 1 FLOAT 2} {
		$framebuffer.type add radiobutton -label $m -value $v \
			-command [list ::patco::vmap::sendvar map Type Type win] \
			-variable settings(mapframebufferType) }

	menu $framebuffer.format -tearoff 0
	foreach { m v }  {RGB 0 YUV 1 RGBA 2 RGB32 3} {
		$framebuffer.format add radiobutton -label $m -value $v \
			-command [list ::patco::vmap::sendvar map Format Format map] \
			-variable settings(mapframebufferFormat) }
		
		
##### color panels	
	foreach {p pw wid name v c row col} { 
		win lighting fogColor "Fog Color" FogColor black 0 1
		win lighting color "Color" Color black 0 2
		win lighting ambient "Ambient" Ambient black 1 1
		win lighting specular "Specular" Specular black 1 2
		map framebuffer color "Color" Color black 1 1
		} {
		patco::colorpanel $w.n.$p.pw.$pw.$wid $p $pw $name $v $c	
		grid $w.n.$p.pw.$pw.$wid -row $row -column $col -sticky sw 	
	}	
		
	
#### texunit Paned window
	menu $texunit.unit
	menu $texunit.media
	menu $texunit.texture
	menu $texunit.scene
	menu $texunit.map
	for {set i 1} {$i <= 15} { incr i } { 
		menu $texunit.unit$i
		$texunit.unit add cascade -menu $texunit.unit$i -label $i
		foreach m {media texture scene map} {
			$texunit.unit$i add cascade -menu $texunit.$m -label $m}
	}
	grid [ttk::menubutton $texunit.mb -menu $texunit.unit -text "Select" ]    
################ Media Panel ################

    set media $w.n.media.pw.media
	
##Media selector
    label $media.file -bg white -font little
	foreach {button sender} {add madd addStream maddStream del mdel clear mediaclear} {
		ttk::button  $media.$button -text "$button" -width 5 \
		-command [list pdsend "$sender bang"]}
   	set vscroll $media.vscroll
    set canvas $media.c
  	scrollbar $vscroll -command "$canvas yview"
   	canvas $canvas -relief sunken -borderwidth 2 -height 600 -width 250\
                              -yscrollcommand "$vscroll set"
							  
#### Media Panel Geometry
    foreach { wid col row colspan }  {file 0 0 4 c 0 2 4 add 0 1 1 addStream 1 1 1 del 2 1 1 clear 3 1 1 vscroll 4 2 1 } {
		grid $media.$wid -column $col -row $row -columnspan $colspan -sticky nsew }
	
################ end media Panel ################

################ Material Panel ################
    set matRgb $w.n.mat.pw.param
    
    set settings(matHierarchy) "no material enabled"
	ttk::label $matRgb.h -textvariable settings(matHierarchy) -background beige
	grid $matRgb.h -sticky nw
    canvas $matRgb.c -relief sunken -borderwidth 2 -height 500 -width 240 -bg black
    foreach { param i } { ambient  0 color 1 diffuse 2 emission 3 specular 4 } {
        set frame [ttk::frame $matRgb.c.$param]
        canvas $frame.v  -relief sunken -borderwidth 2 -height 12 -width 40 -bg grey
		bind $frame.v <Button-1> "::patco::vmap::colorPanel $param $i"
		grid $frame.v -sticky nw -column 0 -row 0
   		set enable [ttk::checkbutton $frame.e  -text "$param"\
			 	-variable settings(mat$i)\
			 	-command "::patco::vmap::enableParam $frame matRgbScale $i mat "\
				-onvalue 1 -offvalue 0]
		grid $enable -sticky nw -column 1 -row 0
        foreach { r s } { 1 R 2 G 3 B 4 A } {
            label $frame.l$s -textvariable settings(rgb$param$s)
            scale $frame.s$s -from 0.000 -to 1 -width 10 -length 189\
                -variable settings(rgb$param$s) -showvalue 0\
                -orient horizontal -resolution 0\
                -command "::patco::vmap::sendscale matRgbScale $param $s "
            grid $frame.l$s -sticky nw -column 0 -row $r
            grid $frame.s$s -sticky nw -column 1 -row $r
            $frame.s$s configure -state disable

            }
        $matRgb.c create window 123 [expr 50 + 101 * $i] -window $matRgb.c.$param
        }
    grid $matRgb.c
	
	##Texture menu							  
    set matTex $w.n.mat.pw.tex
	ttk::menubutton $matTex.mb -width 10 -menu $matTex.menu -text "Select texture" -width 20
	menu $matTex.menu -tearoff 0 
    grid  $matTex.mb   
###########################
############ Texture Panel 
###########################
##Media selector
    set texMedia $w.n.tex.pw.media
	ttk::menubutton $texMedia.mb -width 10 -menu $texMedia.menu -text "Select Media"
	menu $texMedia.menu -tearoff 0 
	
	foreach button {add del} {
		ttk::button  $texMedia.$button -text "$button" -width 4 \
		-command [list pdsend "vmapgui-s texture media $button bang"]}
   	set hscroll $texMedia.hscroll
   	set vscroll $texMedia.vscroll
    set canvas $texMedia.c
  	ttk::scrollbar $hscroll -orient horiz -command "$canvas xview"
  	ttk::scrollbar $vscroll               -command "$canvas yview"
   	canvas $canvas -relief sunken -borderwidth 2 -height 200 -width 230\
                              -xscrollcommand "$hscroll set" \
                              -yscrollcommand "$vscroll set"
##FX box							  
    set texFx $w.n.tex.pw.fx
	ttk::menubutton $texFx.mb -width 10 -menu $texFx.menu -text "Select effect" -width 20
	menu $texFx.menu -tearoff 0 
	ttk::combobox $texFx.cbox -textvariable $texFx.cbox.val -width 15
	ttk::button $texFx.add -text Add -command [list pdsend "addFx bang"] -width 3
	ttk::button $texFx.del -text Del -command [list pdsend "removeFx bang"] -width 3
    ttk::labelframe $texFx.param -text "fx"
#### Texture Panel Geometry
    foreach { wid col row colspan }  {mb 0 1 1 c 0 2 3 add 1 1 1 del 2 1 1 hscroll 0 3 3 vscroll 3 2 1 } {
		grid $texMedia.$wid -column $col -row $row -columnspan $colspan -sticky nsew }
    foreach { wid col row colspan } { cbox 0 1 2 add 0 2 1 del 1 2 1 mb 2 1 1 param 0 3 3 } {
		grid $texFx.$wid -padx 2 -pady 2 -column $col -row $row -columnspan $colspan }
####TEXTURE PANEL COMMANDS
	bind $texFx.cbox <<ComboboxSelected>> "::patco::vmap::sendcbox %W fx Sel"
################################
############# Object Panel     #
################################
    set object $w.n.obj.pw.tree
##Object Treeview
	set objTree [Tree $object.view -dropenabled 1 -dragenabled 1 -dragevent 1 -dropcmd dropTreeCmd  -droptypes { 
        TREE_NODE    {copy {} move {} link {}} 
    } -height 25 -width 30 -selectcommand treeMouseBind]
	$objTree bindArea <KeyPress> "treeKeyBind %K"
##	$objTree bindText <1> "treeMouseBind"
   	set othScroll $object.hscroll
   	set otvScroll $object.vscroll
  	scrollbar $othScroll -orient horiz -command "$objTree xview"
	scrollbar $otvScroll              -command "$objTree yview"
          
	grid $objTree -sticky news -column 0 -row 0
	grid $otvScroll -sticky news  -column 1 -row 0
	grid $othScroll -sticky news -column 0 -row 1 -columnspan 2 
	
	set objM [menu $w.objMenu -tearoff 0]
	menu $w.surfM -tearoff 0
	menu $w.transM -tearoff 0
	menu $w.matM -tearoff 0
	$objM add cascade -label Transform -menu $w.transM
	set settings(objMenuSeparator) 0

	$objM add checkbutton -label Separator -command "::patco::vmap::sendvar obj separator Separator objMenu" -variable settings(objMenuSeparator)
## Object surface

	set objGeo $w.n.obj.pw.geo
	grid [ttk::label $objGeo.label -text "none"]
	ttk::labelframe $objGeo.param
	
## Object Transform

	set objTrans $w.n.obj.pw.trans

    grid [ttk::label $objTrans.label -text "none"]	
	ttk::labelframe $objTrans.param
###########################		
################ Map Panel 
###########################
#### WINDOW GEOMETRY
#	foreach {wid text} [list $mat "Material" $tex "Texture" $obj "Object" $scn "Scene" $map "Map"] {
#		$w.n add $wid -text $text }
	grid  $w.n -sticky nsew
        wm resizable $w 0 0
		
	pdsend "$w.drawDone bang"
}

#############################################################
## Procedures used by widgets and pd callback patch

proc ::patco::vmap::treeSel {w i} {
	set sel [$w selection]
	set tags [$w item $sel -tags]
    pdsend "vmapgui-s tree $i $tags" 
}

 proc ::patco::vmap::popupMenu {w x y o e} {
	set item [$w itemcget $e -data]
	pdsend "objPopupMenu $item $x $y $o"				
 }


proc ::patco::vmap::objTree {w id} {
	$w delete [$w nodes root] 
	$w insert end root objects -text "Objects" -image [Bitmap::get Folder] -open 1 -data root
	$w bindText <3> "::patco::vmap::popupMenu $w %X %Y $id"
	pdsend "objectTreeDone bang"
}
 proc treeKeyBind {t} {
    set objTree .vmapgui.n.obj.pw.tree.view
    set d [lindex [$objTree selection get] 0] 
	set s [$objTree itemcget $d -data]
	pdsend "vmapgui-s object bind $t $s"
    puts [list $t $s]
}
 proc treeMouseBind {w s} {
	if {$s != ""} {
		set l [$w itemcget $s -data]
		set node [lindex $l 0]
		set t [lindex $l 1]
		pdsend "vmapgui-s object bind mouse $t $s"
		puts [list $s $l $node $t]
	}
} 
 proc dropTreeCmd {treewidget drag_source lDrop op dataType data} {
	set mode [lindex $lDrop 0]
	set dest [lindex $lDrop 1]
	set drop [lindex $lDrop 2]
    set item [lindex [$treewidget itemcget $data -data] 0]
    set itemNode [lindex [$treewidget itemcget $data -data] 2]
	set node [lindex [$treewidget itemcget $dest -data] 0]
    puts [$treewidget itemcget $dest -data]
	if {$item == "object" || $item == "transform"} { 
      if { $node == "object" || $node == "root"} {
     switch $mode {
        widget {
      # "widget"
	  if {$op == "copy"} {
        $treewidget insert end root ${data}_[unique] -text [$treewidget itemcget $data -text] -image  [Bitmap::get Folder]
          }
		}
        node {
		  if  {[dropChecking $treewidget $dest $data] == 1} {
      # "node" <node>
          $treewidget move $dest $data end
		  pdsend "vmapgui-s obj move $data $dest " }
        }
        position {
      # "position" <node> <index>
	      switch $item {
		    transform {
		      puts "move transform"
		      pdsend "vmapgui-s obj move transform $dest $itemNode $drop"
		    }
		    object {
	          if {[dropChecking $treewidget $dest $data]} {
		        puts [list $dest $data $drop]
                $treewidget move $dest $data $drop 
		        pdsend "vmapgui-s obj move $dest $data"
			  }
			}
		  }
        }
        default {
            return -code error "DropCmd called with impossible wherelist."
        }
     }}
	}
    return 1
 }

proc dropChecking {path dropped node} {
    puts [list "dropChecking" $path $dropped $node]
    if {$dropped == $node} {
	    puts "wrong node"
	    return 0
		}
	set parent [$path parent $dropped]
	puts $parent
    while 1 {
	    if {$parent == $node} {
		    return 0
		    }
		if {$parent == "objects" || $parent == "root"} {
			# puts "move"
		    return 1
			# break
		}
		set parent [$path parent $parent]
	}
	
}

proc ::patco::vmap::readObjectFile {w f} {
	set filetmp [read [open $f]]
	puts [lindex $filetmp [lsearch $filetmp texture]]
}

proc ::patco::vmap::makeThumbnail {w filename id label dimen type} {
    global settings	set wid [lindex $dimen 0];set hei [lindex $dimen 1];
	set pixels  [read [open $filename]]
	set photo [image create photo $id]
	set i [expr $id -1]
##check if there are valid pixels
	if { [string length [lindex [lindex $pixels 0] 0]] > 0 } { #check if there are valid pixels
		$photo put $pixels
		set top [expr floor($i/3) * 75 + 37]
		set side [expr ($i%3)*75 + 43]
		label $w.c.image$id -width 70 -height 70 -image $photo -relief raised
		$w.c create window $side [expr $top + 6]  -window $w.c.image$id -tags image$id
		::patco::vmap::selectMedia $w $w.c.image$id $label $id
	    tkdnd::drag_source register $w.c.image$id
        bind $w.c.image$id <<DragInitCmd>> \
  {list copy DND_Text {$filename}}
		bind $w.c.image$id <<DragEndCmd>> "puts $id $label"
		bind $w.c.image$id <Button-1> "::patco::vmap::selectMedia $w %W $label $id"
		pdsend "mediaThumbnails bang"
	}
}

proc  ::patco::vmap::selectMedia {p w l id} {
	foreach i [winfo children $p.c ] {
	    $i configure -bg white
	}
	$w configure -bg black
	$p.file configure -text $l
	pdsend "vmapgui-s media select $id"
}

proc ::patco::vmap::mediaSettings {w id o tex label dimen type} {
    global settings
	
	foreach tag [$w.c find withtag rect] {
	$w.c itemconfigure $tag  -fill #aaa
	}
	set wid [lindex $dimen 0];set hei [lindex $dimen 1];
		set top [expr ($o - 1) * 90 + 1]
		set bottom [expr ($o - 1) * 90 + 78]
	    $w.c create rectangle 64 $top 245 [expr 78 + $top] \
                    -fill white -tags "rect obj$o $o media$id $tex $type"
		$w.c create rectangle 0 $top 245 [expr 14 + $top] \
                    -fill white -tags "rect obj$o $o media$id $tex $type"
        $w.c create text  5 [expr 7 + $top] -text $label \
                    -font title -tags "obj$o media$id d $tex" -anchor w
		$w.c create image  32 [expr 47 + $top] -image $id -tags "obj$o media$id d $tex"
        foreach {text xpos} [list $wid 25 $hei 37] {
		    $w.c create text 110 [expr $xpos + $top] -text $text\
                    -font little -tags "obj$o media$id d $tex"}
		if {$type==0} {
			set bytes [lindex $dimen 2];set t [lindex $dimen 3];
			set cspace [lindex $dimen 4];set updown [lindex $dimen 5];
			set notowed [lindex $dimen 6];
            foreach {text ypos xpos} [list $bytes 49 110 $t 61 110 $cspace 25 180 $updown 37 180 $notowed 49 180] {
		        $w.c create text $xpos [expr $ypos + $top] -text $text\
                    -font little -tags "obj$o media$id d $tex"}		
		}
	    if {$type==1} {
	        set len [lindex $dimen 2];set offset [lindex $dimen 3]
	        set end [lindex $dimen 4];set auto [lindex $dimen 5];
	        set fps [lindex $dimen 6];set currentf [lindex $dimen 7];
		    set l [lindex [split $len ":"] 1]
		    $w.c addtag $l withtag media$id
		    $w.c create rectangle 0 $bottom 245 [expr 12 + $bottom] \
                    -fill white -tags "cursor $o media$id $l $tex"
		    $w.c create rectangle 0 $bottom 5 [expr 12 + $bottom] \
                    -fill black -tags "handle h$o media$id $tex"
			$w.c create text 110 [expr $top + 47] -text $len\
                    -font little -tags "obj$o media$id d $tex"
			foreach {text ypos} [list $fps [expr $top + 65] \
			    $offset [expr $top + 26] $end [expr $top + 44]] {
			    set t [lindex [split $text ":"] 0]
				set settings($o.$id$t)  [lindex [split $text ":"] 1]
			    spinbox $w.c.$o$text -from 0.00 -to $l.0 -increment 1 -width 4 \
				 -font {Courier -10} \
				-textvariable settings($o.$id$t) \
			 	-command "::patco::vmap::sendvar media $o $t $o.$id "
			    $w.c create window 206 $ypos -window $w.c.$o$text -tags "window  $o media$id"
				$w.c create text 173 $ypos -text $t -font little -tags "media$id"
				}
			
			set settings($o.${id}auto)  [lindex [split $auto ":"] 1]
			checkbutton $w.c.$o$auto -text auto -variable settings($o.${id}auto) \
			-command "::patco::vmap::sendvar media $o auto $o.$id " -bg white -font little
			$w.c create window 139 [expr $top + 64] -window $w.c.$o$auto -tags "media$id"
			$w.c create text 80 [expr $top + 67] -text frame: -font little -tags "media$id"
			$w.c create text 95 [expr $top + 67] -tag curFrame$id -font little -anchor w -tags "media$id"
			$w.c itemconfig curFrame$id -text 0
		    bind $w.c <B1-Motion> "::patco::vmap::moveMediaCursor %W %x %y move $o.$id"
		    bind $w.c <ButtonRelease-1> "::patco::vmap::moveMediaCursor %W %x %y real 0"
			}
        
		bind $w.c <1> "::patco::vmap::bindMediaMenu $w.c %x %y"
		$w.c configure -scrollregion "0 0 150 [expr $top + 90]"
##		pdsend "mediaThumbnails $photo;"

}
proc ::patco::vmap::bindMediaMenu {w x y} {
	global settings 
	set x [$w canvasx $x]
	set y [$w canvasy $y]
	foreach tag [$w find withtag rect] {
	$w itemconfigure $tag  -fill #aaa
	}
	set found [$w find overlapping 0 $y 240 $y]
	foreach item $found { puts [$w gettag $item]
		if {[lindex [$w gettag $item] 0] == "rect"} {
			set type [lindex [$w gettag $item] 5]
			set id [lindex [$w gettag $item] 2]
			set len [lindex [$w gettag $item] 4]
        	set pos [lindex [$w  coords h$id] 1]
			pdsend "vmapgui-s media Sel  $id"
			$w itemconfigure $item  -fill #fff 
			$w itemconfigure [expr $item+1]  -fill #fff
			} 
		if 	{[lindex [$w gettag $item] 0] == "cursor"} {
			set settings(mCursor) $item
		}
	}
}
proc ::patco::vmap::moveMediaCursor {w x y c d} {
	global settings
	switch $c {
		move { if {$settings(mCursor)>0} {
			set item $settings(mCursor)
			set id h[lindex [$w gettag $item] 1]
        		set oldx [lindex [$w  coords $id] 0]
        		set y [lindex [$w  coords $id] 1]
			set len [lindex [$w gettag $item] 3]
			set frame [expr $len * $x / 240]
			set motion [expr $x - $oldx]
			if {$frame < $settings(${d}offset)} {
				set motion 0
				set frame $settings(${d}offset) }
			if {$frame > $settings(${d}end)} {
				set motion 0
				set frame $e }
			pdsend "vmapgui-s media cursor $id $frame $y $len"
			$w move $id $motion 0
			}
		}
		real { set settings(mCursor) -1}
	}
}

proc ::patco::vmap::enableParam {w b v s} {
        global settings
    set state [list disabled normal]
    foreach scale {R G B A} {
    $w.s$scale configure -state [lindex $state $settings($s$v)]}
	pdsend "vmapgui-s $b enable $v $settings($s$v)"
}
proc ::patco::vmap::sendcbox {w b k} {
	set text  [$w current]
	pdsend "vmapgui-s $b $k $text"
}
proc ::patco::vmap::sendvar {b k v s} {
        global settings
	pdsend "vmapgui-s $b $k $v $settings($s$v)"
}
proc ::patco::vmap::sendsbox {p pw n } {
        global settings
	pdsend "vmapgui-s $p $pw $n $settings($p$pw$n)"
}
proc ::patco::vmap::sendsboxes {p pw n s } {
        global settings
	pdsend "vmapgui-s $p $pw $n $s $settings($p$pw$n$s)"
}

proc ::patco::vmap::sendscale {b k v p} {
        global settings
	pdsend "vmapgui-s $b $k $v $p"
}

proc ::patco::vmap::justify {element} {
        global settings
	set param [expr $settings(geover)*3+$settings(geohor)]
	pdsend "vmapgui-s geo param $element $param"
}

proc ::patco::vmap::sendnbox {w b k} {
global settings
puts $settings($w)
}


proc fontchooserToggle {} {
    tk fontchooser [expr {
            [tk fontchooser configure -visible] ?
            "hide" : "show"}]
}
proc fontchooserVisibility {w} {
    $w configure -text [expr {
            [tk fontchooser configure -visible] ?
            "Hide Font Dialog" : "Show Font Dialog"}]
}
proc ::patco::vmap::sendFont {f} {
        global settings
	set font [lindex $f 0]
	#set exec [exec "fc-match --format=%{file} $font"]
	set getfont [exec fc-match --format=%{file} $font]
	set ext [lindex [split $getfont .] 1]
	if {$ext == "ttf" || $ext == "TTF"} {
   		pdsend "vmapgui-s geo font $getfont"
    		pdsend "vmapgui-s geo param  $settings(geoFont) 1"
	}
}
proc ::patco::vmap::sendText {} {
        global settings
	set data $settings(geoText)
	foreach char [split $data ""] {
    		lappend output [scan $char %c]
	}
   	pdsend "vmapgui-s geo text $output"
    	pdsend "vmapgui-s geo param $settings(geoTextSend) 1"
}

