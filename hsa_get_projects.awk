{
if ($0 ~ /^==============/) {
   if (flagprj==1) { 
      print  wksp "/" prj ":" curstat reqstat; 
      flaginstance=0;
   }
   flagprj=1;
} 
if (flagprj==1 && flaginstance==0) {
   if ($0 ~ /^Workspace/ ) { wksp= substr($0, index($0,":")+1); gsub(" ", "",wksp); }
   else if($0 ~ /^Project/ ) { prj= substr($0, index($0,":")+1) ;gsub(" ", "", prj);}
   else if($0 ~ /^Instance Count/ ) { icount= substr($0, index($0,":")+1) ; }
   else if($0 ~ /Instance Details/) {flaginstance=1;}
}
else if (flaginstance==1) {
   if($0 ~ /Current Status/) {curstat=substr($0, index($0,":")+1) ; gsub(" ", "",curstat);}
   if($0 ~ /Requested Status/) {
      reqstat=substr($0, index($0,":")+1) ; gsub(" ", "",reqstat);
      if (curstat == reqstat) { reqstat=""; }
      else reqstat = " ( action " reqstat " has been requested)"
   }
}
}
END{
   if (flagprj==1) { print  wksp "/" prj ":" curstat reqstat }
}
