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
	ttk::button $w.$B -text "$B" -width 5 -command [list pdsend "$name$B bang"]}
	
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

proc ::patco::vmap::treeSel {w i} {
	set sel [$w selection]
	set tags [$w item $sel -tags]
    pdsend "vmapgui-s tree $i $tags" 
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
########################## WIDGETS #########
	ttk::notebook $w.n
	
	foreach { frame panel } { 
	    media {media "Media" 1 20}
	    tex {set "Texture" 0  10 media "Media" 1 20 fx "Texture Effect" 3 300}
	    mat {set "Material" 0  10 param "Parameter" 1 200 tex "Texture" 2 50}  
		obj {set "Object" 0  10 tree "Tree" 1 600} 
		scn {set "Scene" 0  10 maps "Maps" 1  10 obj "Object" 2 220 \
		 lights "Lights" 3 10 keyframes "Keyframes" 4 200} 
		map {set "Map"  0  10 vert "Vertex Position" 1 20 shade "Shader size" 2 220}
    }   { 
	    set $frame [ttk::frame $w.n.$frame]
		set ${frame}Pw [panedwindow $w.n.$frame.pw -orient vertical -sashrelief sunken]
		patco::vmap::drawPane $w.n $w.n.$frame.pw $panel $frame
        if {$frame != "media"} {patco::vmap::drawComboSelect $w.n.$frame.pw.set $frame}
	}
################ Media Panel ################

    set media $w.n.media.pw.media
	
##Media selector
    label $media.file -bg white -font little
	foreach {button sender} {add madd del mdel clear mediaclear} {
		ttk::button  $media.$button -text "$button" -width 4 \
		-command [list pdsend "$sender bang"]}
   	set vscroll $media.vscroll
    set canvas $media.c
  	scrollbar $vscroll               -command "$canvas yview"
   	canvas $canvas -relief sunken -borderwidth 2 -height 600 -width 230\
                              -yscrollcommand "$vscroll set"
							  
#### Media Panel Geometry
    foreach { wid col row colspan }  {file 0 0 3 c 0 2 3 add 0 1 1 del 1 1 1 clear 2 1 1 vscroll 3 2 1 } {
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
    } -height 25 -width 30 ]
   	set othScroll $object.hscroll
   	set otvScroll $object.vscroll
  	scrollbar $othScroll -orient horiz -command "$objTree xview"
	scrollbar $otvScroll              -command "$objTree yview"
          
	grid $objTree -sticky news -column 0 -row 0
	grid $otvScroll -sticky news  -column 1 -row 0
	grid $othScroll -sticky news -column 0 -row 1 -columnspan 2 
	
##    $objTree heading #0 -text "part"
##	bind $objTree  <Button-1> "puts 'object001'"
##	set objTitle [$objTree insert end root objects -text "Objects"]
	set objM [menu $w.objMenu -tearoff 0]
	menu $w.surfM -tearoff 0
	menu $w.transM -tearoff 0
	menu $w.matM -tearoff 0
	$objM add cascade -label Transform -menu $w.transM
	set settings(objMenuSeparator) 0
##	$objM add checkbutton -label Separator -command [list pdsend "vmapgui-s obj separator"] -variable settings(objMenuSeparator)
	$objM add checkbutton -label Separator -command "::patco::vmap::sendvar obj separator Separator objMenu" -variable settings(objMenuSeparator)
##	 $objTree tag bind part1 <Button-1> "puts 'part1'"
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
## Procedures used by widgets and pd patch

 proc dropTreeCmd {treewidget drag_source lDrop op dataType data} {
    puts [list $treewidget $drag_source $lDrop $op $dataType $data]
	if {[$treewidget itemcget $data -data] == "object" && [$treewidget itemcget [lindex $lDrop 1] -data] == "object"} {
     switch [lindex $lDrop 0] {
        widget {
      # "widget"
	  if {$op == "copy"} {
        $treewidget insert end root ${data}_[unique] -text [$treewidget itemcget $data -text] -image  [Bitmap::get Folder]
          }
		}
        node {
		  if  {[dropChecking $treewidget [lindex $lDrop 1] $data] == 1} {
      # "node" <node>
          $treewidget move [lindex $lDrop 1] $data 0 }
        }
        position {
      # "position" <node> <index>
	    if {[dropChecking $treewidget [lindex $lDrop 1] $data] == 1} {
      $treewidget move [lindex $lDrop 1] $data [lindex $lDrop 2] }
        }
        default {
            return -code error "DropCmd called with impossible wherelist."
        }
     }
	}
    return 1
 }

proc dropChecking {path dropped node} {
##    puts [list "dropChecking" $path $dropped $node]
    if {$dropped == $node} {
	    puts "wrong node"
	    return 0
		}
	set parent [$path parent $dropped]
##	puts $parent
    while 1 {
	    if {$parent == $node} {
		    return 0
		    break}
		if {$parent == "objects"} {
		    return 1
			break
		}
		set parent [$path parent $parent]
	}	
}
 proc ::patco::vmap::popupMenu {w x y o e} {
	set item [$w itemcget $e -data]
	global settings

#	pdsend "vmapgui-s obj get $o"	
	puts $item

	pdsend "objPopupMenu $item $x $y $o"		
##	switch $item {
	# TODO: menu button for adding objects
		# root {
			# tk_popup .vmapgui.objMenu $x $y
			# }
##		object {
##			tk_popup .vmapgui.objMenu $x $y
##			}
##		surface {
##			pdsend "vmapgui-s obj geo get $o"
##			tk_popup .vmapgui.surfM $x $y
##			}
##		material {
##			pdsend "vmapgui-s obj mat get $o"
##			tk_popup .vmapgui.matM $x $y
##			}
##		}
		
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
	set wid [lindex $dimen 0];set hei [lindex $dimen 1];
	##puts $o
		set top [expr $o * 90 + 1]
		set bottom [expr $o * 90 + 78]
	    $w.c create rectangle 64 $top 245 [expr 78 + $top] \
                    -fill white -tags "rect obj$o $id media$id $tex"
		$w.c create rectangle 0 $top 245 [expr 14 + $top] \
                    -fill white -tags "rect obj$o $id media$id $tex"
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
                    -fill white -tags "cursor $id media$id $l $tex"
		    $w.c create rectangle 0 $bottom 5 [expr 12 + $bottom] \
                    -fill black -tags "handle h$id media$id $tex"
			$w.c create text 110 [expr $top + 47] -text $len\
                    -font little -tags "obj$o media$id d $tex"
			foreach {text ypos} [list $fps [expr $top + 65] \
			    $offset [expr $top + 26] $end [expr $top + 44]] {
			    set t [lindex [split $text ":"] 0]
				set settings($o.$id$t)  [lindex [split $text ":"] 1]
			    spinbox $w.c.$o$text -from 0.00 -to $l.0 -increment 1 -width 4 \
				 -font {Courier -10} \
				-textvariable settings($o.$id$t) \
			 	-command "::patco::vmap::sendvar media $id $t $o.$id "
			    $w.c create window 206 $ypos -window $w.c.$o$text -tags "window  $id media$id"
				$w.c create text 173 $ypos -text $t -font little
				}
			
			set settings($o.${id}auto)  [lindex [split $auto ":"] 1]
			checkbutton $w.c.$o$auto -text auto -variable settings($o.${id}auto) \
			-command "::patco::vmap::sendvar media $id auto $o.$id " -bg white -font little
			$w.c create window 139 [expr $top + 64] -window $w.c.$o$auto
			$w.c create text 80 [expr $top + 67] -text frame: -font little
			$w.c create text 95 [expr $top + 67] -tag curFrame$id -font little -anchor w
			$w.c itemconfig curFrame$id -text 0
		    bind $w.c <B1-Motion> "::patco::vmap::moveMediaCursor %W %x %y move"
		    bind $w.c <ButtonRelease-1> "::patco::vmap::moveMediaCursor %W %x %y real"
			}
        
		bind $w.c <1> "::patco::vmap::bindMediaMenu $w.c %x %y $type"
		$w.c configure -scrollregion "0 0 150 [expr $top + 90]"
##		pdsend "mediaThumbnails $photo;"

}
proc ::patco::vmap::bindMediaMenu {w x y type} {
	set x [$w canvasx $x]
	set y [$w canvasy $y]
	foreach tag [$w find withtag rect] {
	$w itemconfigure $tag  -fill #aaa
	}
	set found [$w find overlapping 0 $y 240 $y]
	foreach item $found {
		if {[lindex [$w gettag $item] 0] == "rect"} {
			set id [lindex [$w gettag $item] 2]
			set len [lindex [$w gettag $item] 4]
        	set pos [lindex [$w  coords h$id] 1]
			pdsend "vmapgui-s media Sel  $id"
			$w itemconfigure $item  -fill #fff 
			$w itemconfigure [expr $item+1]  -fill #fff
			if {$type==1} {
			    pdsend "vmapgui-s media cursor h$id init $pos $len"
			    pdsend "vmapgui-s media cursor h$id real bang"
				}
			}    
		}
}
proc ::patco::vmap::moveMediaCursor {w x y c} {
	set found [$w find overlapping 0 $y 240 $y]
	foreach item $found {
		if {[lindex [$w gettag $item] 0] == "cursor"} {
			set id h[lindex [$w gettag $item] 1]
        		set oldx [lindex [$w  coords $id] 0]
        		set y [lindex [$w  coords $id] 1]
			set len [lindex [$w gettag $item] 3]
			set frame [expr $len * $x / 240]
			set motion [expr $x - $oldx]
			if {$x < 0} {set motion 0}
			if {$x > 240} {set motion 0}
			switch $c { 
				move { pdsend "vmapgui-s media cursor $id $frame $y $len"
				$w move $id $motion 0}
				real { pdsend "vmapgui-s media cursor $id real bang"}
			}
		}
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

