# Purpose : to process the dropped element inside the target widget
console show
proc place_listbox_proccess_DAD {args} {
  global DAD_content
  puts args
##  [lindex $args 0] insert {} end $DAD_content
}

# Purpose       : enables Drag-And-Drop controls of any listbox widget
proc place_listbox_controls_DAD {w {cutOrig 0} {procName "place_listbox_proccess_DAD"}} {
  $w tag bind i <1> {
   set DAD_pressed 1
   puts "pressed"
   }

  $w tag bind i <Motion> {
    if {[catch {set DAD_pressed $DAD_pressed}]} {set DAD_pressed 0}
    if {$DAD_pressed} {
      puts "motion"
      %W config -cursor exchange
      if {[catch {set DAD_content [%W get [%W curselection]]}]} {
        set DAD_pressed 0
      }
    } else {
      %W config -cursor ""
    }
  }

  if $cutOrig {set cutCmd "$w delete \[$w curselection\]"} else {set cutCmd ""}
  if {$procName == ""} {set procName place_listbox_proccess_DAD}
    
  set cmd "$w tag bind i \<ButtonRelease-1\> \{
    $w config -cursor \"\"
    set DAD_pressed 0    
    if \{\[catch \{set DAD_content \$DAD_content\}\]\} \{set DAD_content \"\"\}
    if \{\$DAD_content != \"\"\} \{
      set wDAD   \[winfo containing  \[winfo pointerx .\]  \[winfo pointery .\]\]
      if \{\(\$wDAD ne \"\"\) && \(\$wDAD != \"\%W\"\)\} \{
        if !\[catch \{$procName \$wDAD\}\] \{$cutCmd\}
      \}
      set DAD_content \"\"
    \}
  \}"
  eval $cmd
}

# ---------- TEST CODE ------------------------
ttk::treeview .ls1  
foreach item {a b c d e} {.ls1 insert {} end -id i_$item -text $item -tags i}
ttk::treeview .ls2  
foreach item {f g h i j} {.ls2 insert {} end -id i_$item -text $item -tags i}
place .ls1 -x 10 -y 50
place .ls2 -x 100 -y 50

place_listbox_controls_DAD .ls1
place_listbox_controls_DAD .ls2 1
