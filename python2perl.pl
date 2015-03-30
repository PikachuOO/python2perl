#!/usr/bin/perl -w
#Min Jee Son z3330687
#Translates python code to its perl equivalent.
#Returns original line as comments if it cannot be translated
#Where a variable that hasn't been previously initialised is used, it is treated as a string and is prefixed with "$" when it is used
#last edited on 6/10/14

use strict;

sub checker($); #Studies each line and breaks them down to variables etc accordingly
sub compare($); #Numerical and string comparisons
sub re($); #re.search/match
sub inputcheck($); #Determines the type of the input if possible and outputs the input in perl format
sub varInit($$); #variable initialisation - takes variable and its value as inputs

our $noLoop = 0;
our %var_type; # Stores the types of a variable as STRING, NO, @ or %. If it can't be determined, STRING is the default type
our $last_type; # Stores the type of the input most recently put through inputcheck()

#NUMERICAL / STRING COMPARISONS
sub compare($) {
  my $output = "";
  $output = $1." " if defined($1);
  my $var1 = inputcheck($2);
  my $op = $3;
  my $var2 = inputcheck($4);
  return "UNDEFINED" if $var1 eq "UNDEFINED" or $var2 eq "UNDEFINED";
  #String Comparison
  if ($last_type eq "STRING"){
    $op =~ s/==/eq/;
    $op =~ s/!=/ne/;
  }
  return "$output$var1 $op $var2";
}

sub re($) { # re.search/re.match
  my $output = "";
  $output = $1." " if defined($1);
  my $action = $2;
  my $pattern = inputcheck($3);
  return "UNDEFINED" if $pattern eq "UNDEFINED";
  my $string = $4;
  $pattern =~ s/^"|"$//g;
  $output .= "\$$string =~ /";
  $output.="^" if $action eq "match";
  $output.=$pattern."/";
  return $output;
}

sub varInit($$){
  my $var = $_[0];
  my $input = $_[1];
  my $varNew = $var;
  my $type;
  
  ### DICT INIT W/O VALUES
  if($input =~ /^{\s*}/){
    $var_type{$var} = "\%";
    return "";
  }
  ### LIST INIT W/0 VALUES
  elsif($input =~ /^\[\s*\]/){
    $var_type{$var} = "\@";
    return "";
  }
  ### VARIABLE TYPE KNOWN
  elsif(defined($var_type{$var})){
    $type = $var_type{$var};
    $type = "\$" if $type eq "STRING" or $type eq "NO";
    $varNew = "$type$var";
  }
  ### DICT INIT WITH VALUES
  elsif($input =~ /^{.+}/){
    $var_type{$var} = "\%";
    $varNew = "%$var";
  }
  ### LIST INIT WITH VALUES
  elsif($input =~ /^\[.+\]/){
    $var_type{$var} = "\@";
    $varNew = "\@$var";
  }
  my $output = inputcheck($input);
  return "UNDEFINED" if $output eq "UNDEFINED";
  if ($var eq $varNew){ #determine type of $var using inputcheck() if still unknown
    $var_type{$var} = $last_type;
    $type = $last_type;
    $varNew = inputcheck($var);
    return "UNDEFINED" if $varNew eq "UNDEFINED";
  }
  if($input =~ /^re\.sub\(\s*r?(.+)\s*,\s*r?(.+)\s*,\s*$var\s*\)\s*$/){
    my $rep = inputcheck($1);
    my $new = inputcheck($2);
    $rep =~ s/^"|"$//g;
    $new =~ s/^"|"$//g;
    $var_type{$varNew} = "STRING";
    return "$varNew =~ s/$rep/$new/g";
  }
  else{
    return "$varNew = $output";
  }
}

#CHECK TYPES OF INPUTS
sub inputcheck($){
  my $input = $_[0];
  $last_type = "STRING";
  ### QUOTED STRINGS OR NUMBERS
  if($input =~ /^\s*["'](.*)['"]\s*$/ ){
    $last_type = "STRING";
    return "\"$1\"";
  }
  ### NUMBER
  elsif($input =~ /^\s*[0-9]+\.?[0-9]*\s*$/){
    $last_type = "NO";
    return $input;
  }
  ### RE.SUB
  elsif($input =~ /^re\.sub\(\s*r?(.+)\s*,\s*r?(.+)\s*,\s*(.+?)\s*\)\s*$/){
    my $pattern = inputcheck($1);
    return "UNDEFINED" if $pattern eq "UNDEFINED";
    my $repl = inputcheck($2);
    return "UNDEFINED" if $repl eq "UNDEFINED";
    my $output = $3;
    $pattern =~ s/^"|"$//g;
    $repl =~ s/^"|"$//g;
    $last_type="STRING";
    return "\$$output =~ s/$pattern/$repl/r";
  }
  ### RE.SPLIT
  elsif($input =~ /^re\.split\(\s*r?(.+),\s*(.+)\)\s*$/){
    my $divider = inputcheck($1);
    return "UNDEFINED" if $divider eq "UNDEFINED";
    my $temp = $2;
    my @inputs = split(/\s*,\s*/, $temp);
    $divider =~ s/^"|"$//g;
    my $string = inputcheck($inputs[0]);
    return "UNDEFINED" if $string eq "UNDEFINED";
    $last_type="\@";
    return "split(/$divider/, $string)" if $#inputs == 0;
    return "split(/$divider/, $string, ".inputcheck($inputs[1]).")";
  }
  ### RE.MATCH/ RE.SEARCH
  elsif($input =~ /^re\.(match|search)\(\s*r?(.+)\s*,\s*(.+?)\s*\)\s*$/){
    my $pattern = inputcheck($2);
    my $string = inputcheck($3);
    return "UNDEFINED" if $pattern eq "UNDEFINED" or $string eq "UNDEFINED";
    my $output = "$string =~ /";
    $output.="^" if $1 eq "match";
    $last_type = "STRING";
    $pattern =~ s/^"|"$//g;
    return $output."$pattern/";
  }
  ### DICT KEYS
  elsif($input =~ /^\s*([^\s]+)\.keys\(\)\s*$/){
    $last_type = "\@";
    return "keys \%$1";
  }
  ### JOIN
  elsif($input =~ /^\s*(.+)\.join\((.+)\)\s*$/){
    my $divider = inputcheck($1);
    return "UNDEFINED" if $divider eq "UNDEFINED";
    my $strings = inputcheck($2);
    return "UNDEFINED" if $strings eq "UNDEFINED";
    $last_type="STRING";
    return "join($divider, $strings)";
  }
  ### SPLIT
  elsif($input =~ /^\s*(.+)\.split\((.+)\)\s*$/){
    my $string = inputcheck($1);
    return "UNDEFINED" if $string eq "UNDEFINED";
    my $divider = inputcheck($2);
    return "UNDEFINED" if $divider eq "UNDEFINED";
    $last_type="\@";
    return "split(/$divider/, $string)";
  }
  
  ### SYS.ARGV
  elsif($input =~ /^\s*sys\.argv(\[.*\])?\s*$/){
    if (defined($1)){
      my $var = $1;
      $var =~ s/^\[|\]$//g;
      return "\@ARGV" if $var =~ /^\s*1\s*:\s*$/; #For sys.argv[1:]
      return "\$ARGV[$1..\$#ARGV]" if $var =~ /^\s*([0-9])\s*:\s*$/;
      $var = inputcheck($var);
      return "UNDEFINED" if $var eq "UNDEFINED";
      return "\$ARGV[$var-1]";
    }
    else{
      $last_type="\@";
      return "\@ARGV";
    }
  }
  ### RANGE
  elsif($input =~ /^\s*range\s*\(\s*(.*)\s*\)\s*$/ ){
    $input = $1;
    my @matches; my $output = "(";
    push @matches, $1 while $input =~ /([^(),]+(?1)?|(\((?:[^()]+|(?2))*\)))(,\s*|\s*$)/xg; #Look for elements with matched brackets before ','
    return "UNDEFINED" if ($#matches > 1);
    $matches[0] = inputcheck($matches[0]);
    return "UNDEFINED" if $matches[0] eq "UNDEFINED";
    $last_type = "\@";
    if ($#matches == 0){
      if($matches[0] =~ /^[0-9]+$/){
        $matches[0]--;
        return $output."0..$matches[0])";
      }
      else{
        return $output."0..$matches[0]-1)";
      }
    }
    else{
      $matches[1] = inputcheck($matches[1]);
      return "UNDEFINED" if $matches[1] eq "UNDEFINED";
      $last_type = "\@";
      if($matches[1] =~ /^[0-9]+$/){
        $matches[1]--;
        return $output."$matches[0]..$matches[1])";
      }
      else{
        return $output."$matches[0]..$matches[1]-1)";
      }
    }
  }
  ### array[a:b]
  elsif ($input =~ /^([^\[]+)\[\s*(.+)\s*:\s*(.*)\s*\]/ ){
    my $var = $1;
    my $elem1 = inputcheck($2);
    return "UNDEFINED" if $elem1 eq "UNDEFINED";
    if (defined($3)){
      my $elem2 = inputcheck($3);
      return "UNDEFINED" if $elem2 eq "UNDEFINED";
    }
    my $elem2 = "\$#$var" if !defined($3);
    $last_type="\@";
    return "\@$var\[$elem1..$elem2\]";
  }
  ### open(file)
  elsif($input =~ /^\s*open\(\s*(.+)\s*\)\s*$/){
    return "UNDEFINED" if inputcheck($1) eq "UNDEFINED";
    $last_type = "\@";
    return "<F>";
  }
  ### LISTS
  elsif($input =~ /^\s*[\[\(]\s*(\[.+?\]|.*\(.+?\)|[^,]+).*[\]\)]\s*$/){
    my $elem = $1;
    my $temp = $1;
    $temp =~ s/(\(|\)|\[|\])/\\$1/g; #escape [,],(,)s for use in matching
    $input =~ s/$temp//;
    my $output = inputcheck($elem);
    return "UNDEFINED" if $output eq "UNDEFINED";
    while($input =~ /,\s*(.+\(.+\)|\[.+\]|[^,\(\)\]]+)\s*/g){
      $elem = $1;
      $temp = inputcheck($1);
      return "UNDEFINED" if $temp eq "UNDEFINED";
      $output = "$output, ".$temp;
      $elem =~ s/(\(|\)|\[|\])/\\$elem/g;
      $input =~ s/,\s*$elem//;
    }
    $output = "(".$output.")";
    $last_type="\@";
    return $output;
  }
  ### ACCESSING LIST/ DICT ELEMENT
  elsif($input =~ /^\s*([^\]\[]+)\[([^\]]+)\]\s*$/ ){
    my $name = $1;
    my @elems = split(/\s*\]\[\s*/, $2); # Cater for multidimensional arrays/dicts
    my $output = "\$$name";
    for(my $i=0; $i<=$#elems; $i++){
      $elems[$i]=inputcheck($elems[$i]);
      return "UNDEFINED" if $elems[$i] eq "UNDEFINED";
    }
    if((defined($var_type{$name}) and $var_type{$name} eq "\%") or $last_type eq "STRING"){
      foreach (@elems){
        $output.="{$_}";
      }
    }
    else{
      foreach (@elems){
        $output.="[$_]";
      }
    }
    return $output;
  }
  ### FUNCTION CALLING
  elsif($input =~ /^\s*(.+)\s*\((.*)\)\s*$/ and defined($var_type{$1}) and $var_type{$1} eq "FUNCTION"){
    my $name = $1;
    my $arguments = $2;
    my $output = "$name (";
    while ($arguments =~ /(\"((.*?(\\(\\{2})*\")*)+)\"|[^(),]+(?1)?|(\((?:[^()]+|(?2))*\))),?\s*/xg)
    {
      my $arg = $1;
      if ($arg =~ /^(.+)\s*=\s*(.+)$/){
        $arg = inputcheck($2);
      }
      else{
        $arg = inputcheck($arg);
      }
      return "UNDEFINED" if $arg eq "UNDEFINED";
      $output.="$arg, ";
    }
    $output=~ s/, $//;
    return "$output)";
  }
  ### Input is a known variable
  elsif(defined($var_type{$input})){
    $last_type = $var_type{$input};
    my $type = $last_type;
    $type = "\$" if $type eq "STRING" or $type eq "NO";
    return $type.$input;
  }
  elsif($input =~ /^\s*[^\s]*\.group\(\s*(.+)\s*\)\s*$/){ #assume there is only one type of groups
    my $output = inputcheck($1);
    return "UNDEFINED" if $output eq "UNDEFINED";
    return "\$$output";
  }
  ### DICTS
  elsif($input =~ /^\s*{.+}\s*$/){
    my $output = "";
    my $temp;
    while ($input =~ /\s*([^:{]+)\s*:\s*([^:,}]+)\s*,?/g ){
      $temp =inputcheck($1);
      return "UNDEFINED" if $temp eq "UNDEFINED";
      $output.=$temp."=>";
      $temp =inputcheck($2);
      return "UNDEFINED" if $temp eq "UNDEFINED";
      $output.=$temp.", ";
    }
    $output =~ s/,\s*$//;
    $output = "(".$output.")";
    $last_type = "\%";
    return $output;
  }
  ### int ()
  elsif($input =~ /^\s*int\((.*?)\)\s*$/){
    my $output = inputcheck($1);
    return "UNDEFINED" if $output eq "UNDEFINED";
    $last_type = "NO";
    return "int(".$output.")";
  }
  ### sys.stdin(readline())? or fileinput.input()
  elsif($input =~ /^s*sys\.stdin(\.readlines\(\))?\s*$/){
    if (defined($1)){
      $last_type = "\@";
    }
    else{
      $last_type = "STRING";
    }
    return "<STDIN>";
  }
  elsif( $input =~ /^\s*fileinput\.input\((.*)\)\s*$/){
    if (defined($1)){
      return "<F>";
    }
    return "<STDIN>";
  }

  
  ### ARRAY POP
  elsif($input =~ /^\s*([^\.]+)\.pop\(\s*\)\s*/g ){
    my $arr = $1;
    return "pop \@$arr";
  }
  ### sorted()
  elsif($input =~ /^\s*sorted\((.+)\)\s*$/){
    my $output =inputcheck($1);
    return "UNDEFINED" if $output eq "UNDEFINED";
    $last_type = "\@";
    return "sort ".$output;
  }

  ### BITWISE Operation
  elsif($input =~ /^\s*([^<>&\|\^]+)\s*(>>|<<|&|\||\^)\s*([^<>&\|\^]+)\s*$/){
    my $var1 = inputcheck($1);
    return "UNDEFINED" if $var1 eq "UNDEFINED";
    my $op = $2;
    my $var2 = inputcheck($3);
    return "UNDEFINED" if $var2 eq "UNDEFINED";
    $last_type = "NO";
    return "$var1 $op $var2";
  }
  ### STRING FORMATTING
  elsif ($input =~ /^(".+")\s*%\(?(.+?)\)?\s*$/){
    my $string = $1;
    my $var = $2;
    my @vars = split(/\s*,\s*/, $var);
    my $i = 0;
    while($string =~ /([\\]*%[1-9]?\.?[1-9]?[dcfs]|[\\]*%[1-9]?\.?[1-9]?lf)/g){
      my $rep = $1;
      if ($rep =~ /^\\(\\{2})*%/){ #Ignore % in string if it has been escaped
        next;
      }
      if ($i > $#vars){
        return "UNDEFINED";
      }
      else{
        $vars[$i] = inputcheck($vars[$i]);
        return "UNDEFINED" if $vars[$i] eq "UNDEFINED";
        $string =~ s/$rep/$vars[$i]/;
        $i++;
      }
    }
    if ($i != $#vars+1){
      return "UNDEFINED"; #Print line preceeded by # if the number of unescaped valid %'s in the string don't match no of %'s outside the string
    }
    else{
      $last_type = "STRING";
      return "$string";
    }
  }
  ### ARITHMETIC OPERATIONS
  elsif ($input =~ /^\s*([^\s\+\-\%\/\*]*\(.+\)|[^\s\+\-\%\/\*()]*)\s*([\+\-\%\/\=]|[\*]{1,2})/){
    my $temp = $1;
    my $output = inputcheck($temp);
    return "UNDEFINED" if $output eq "UNDEFINED";
    $temp =~ s/([\(\)\[\]\+\*])/\\$1/g;
    $input =~ s/\s*$temp\s*//;
    while($input=~ /([\+\-\%\/\=]|[\*]{1,2})\s*([^\s\+\-\%\/\*]*\(.+\)|[^\s\+\-\%\/\*()]*)/g){
      my $op = $1;
      my $x = $2;
      my $exp = inputcheck($x);
      if ($op eq "+" and ($last_type eq "STRING" or $last_type eq "\@")){
        $exp = ".$exp";
      }
      else{
        $exp = " $op $exp";
      }
      return "UNDEFINED" if $exp eq "UNDEFINED";
      $op =~ s/([\*\+\-])/\\$1/g;
      $x =~ s/([\(\)\[\]\+\*])/\\$1/g;
      $input =~ s/\s*$op\s*$x\s*//;
      $output = "$output$exp";
    }
    $last_type = "NO";
    return $output;
  }
  ### Len() - If  input is in commas, assume to be string. else treat as list
  elsif($input =~ /^\s*len\((.+)\)\s*$/){
    my $temp = inputcheck($1);
    my $curr_type = $last_type;
    $last_type = "NO";
    return "UNDEFINED" if $temp eq "UNDEFINED";
    return "length($temp)" if $curr_type eq "STRING";
    return "scalar $temp" if $curr_type eq "\@";
    return "scalar keys $temp" if $curr_type eq "\%";
    return "UNDEFINED";
  }
  ### BITWISE COMPLEMENT
  elsif($input =~ /^\s*~(.+)\s*$/){
    my $output = inputcheck($1);
    return "UNDEFINED" if $output eq "UNDEFINED";
    $output = "~$output";
    $last_type="NO";
    return $output;
  }
  ### Unknown variable name - return with prefix $
  elsif($input =~ /^\s*([a-zA-Z0-9_]+)\s*$/){
    return "\$$1";
  }
  else{
    return "UNDEFINED";
  }
}

#CHECKS FOR KEYWORDS
sub checker($) {
  my $line = $_[0];
  $line =~ s/\n$//;
  my $output = "";
  if ($line =~ /^#!/ && $. == 1)
  {
    return "#!/usr/bin/perl -w\n";
  }
  elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/)
  {
    return "$line\n";
  }
  ### open()
  if($line =~ /(open|fileinput\.input)\(\s*(.+)\s*\)/){
    my $file = $2;
    if ($file !~ /^["']|['"]$/){
      $file = inputcheck($file);
      return "#$line\n" if $file eq "UNDEFINED";
    }
    else{
      $file =~ s/^["']|['"]$//g;
    }
    print "open F, \"<$file\";\n";
  }
  
  #Function defining
  if($line =~ /^\s*def\s+(.+?)\s*\((.*)\)\s*:\s*$/){
    my $func_name = $1;
    $var_type{$func_name}= "FUNCTION";
    my @argsPy = split(/\s*,\s*/, $2);
    my @argsPl = grep(!/.+=.+/, @argsPy); #explicitly initialise variables within the function call if variable is initialised in the python function
    my %diff = map{$_=>1} @argsPl;
    my @diff = grep(!defined $diff{$_}, @argsPy);
    $noLoop++;
    $output.="sub $func_name(";
    foreach (@argsPl){ #Set arguments as string types by default
      $output.="\$";
      $var_type{$_} = "STRING";
    }
    $output.="){\n";
    for(my $i=0; $i<=$#argsPl; $i++){
      $output.="  " foreach (1..$noLoop);
      my $var = $argsPl[$i];
      $output.=inputcheck($var)." = \$_[$i];\n";
    }
    foreach my $dif (@diff){
      $output.="  " foreach(1..$noLoop);
      $output.=checker($dif);
    }
    
    my $func_line = <>; #access next line in input to check the amount of indentation for the loop
    $func_line =~ /^(\s+)(.*)\s*$/;
    my $spaces = $1;
    $output.="  " foreach(1..$noLoop);
    $output.=checker ($2);
    while ($func_line = <>){
      if ($func_line =~ /^$spaces([^\s].*)\s*$/){
        $output.="  " foreach(1..$noLoop);
        $output.=checker ($1);
      }
      else{
        last;
      }
    }
    $noLoop--;
    $output.="  " foreach (1..$noLoop);
    $output.="}\n";
    my $nextline = $func_line;
    if (defined($nextline)){
      $output.="  " foreach(1..$noLoop);
      $output.=checker($nextline); #this nextline is no longer in the loop and so needs to be checked
    }
    return $output;
  }
  
  ### Function calling
  elsif($line =~ /^\s*(.+)\s*\((.*)\)\s*$/ and defined($var_type{$1}) and $var_type{$1} eq "FUNCTION"){
    my $name = $1;
    my $arguments = $2;
    my $output = "$name (";
    while ($arguments =~ /(\"((.*?(\\(\\{2})*\")*)+)\"|[^(),]+(?1)?|(\((?:[^()]+|(?2))*\))),?\s*/xg){
      my $arg = $1;
      if ($arg =~ /^(.+)\s*=\s*(.+)$/){
        $arg = inputcheck($2);
      }
      else{
        $arg = inputcheck($arg);
      }
      return "UNDEFINED" if $arg eq "UNDEFINED";
      $output.="$arg, ";
    }
    $output=~ s/, $//;
    return "$output);\n";
  }
  ### While Loops and Conditionals
  elsif($line =~ /^\s*(if|while|else|elif)\s*(.*):\s*(.*)\s*$/){
    my $conj = $1;
    $conj = "elsif" if $conj eq "elif";
    my $condition = $2;
    my $action = $3;
    $condition =~ s/^\(|\)$//g if $condition =~ /^\(/; #delete any brackets around the condition
    $noLoop++;
    $output.="$conj ";
    if($conj eq "else"){
      $output.="{\n";
    }
    elsif ($condition eq ""){
      $output.="(){\n";
    }
    else{
      my $outputCond = "";
      my @conditions = split(/ and | or /, $condition);
    OUTER:
      foreach my $condInner (@conditions){
        my $conjunction = "";
        if ($condition =~ / (or|and) /){
          $conjunction = $1;
          $condition =~ s/$1//;
        }
        #re.match/search
        if ($condInner =~ /^(not)?\s*re\.(match|search)\(\s*r?(.*),\s*(.+)\s*\)\s*$/){
          my $condInner = re($condInner);
          if ($condInner eq "UNDEFINED"){
            $output = "#$line {\n";
            last OUTER;
          }
          $outputCond.=$condInner." ";
        }
        #arithmetic or string comparisons
        elsif ($condInner =~ /^(not)?\s*([^<>=!]+?)\s*(<=|>=|==|!=|[\>\<])\s*([^<>=!]+)\s*/){
          my $condInner = compare($condInner);
          if ($condInner eq "UNDEFINED"){
            $output = "#$line {\n";
            last OUTER;
          }
          $outputCond.=$condInner." ";
        }
        #check if element in array or dict
        elsif ($condInner =~ /(not)?\s*(.+?)\s*(not)?\s*in\s*(.+)\s*/){
          $outputCond.="not " if defined($1) or defined($3);
          my $var1 = inputcheck($2);
          my $arr = inputcheck($4);
          if ($var1 eq "UNDEFINED"){
            $output="#$line {\n";
            last OUTER;
          }
          $outputCond.="grep {\$_ eq $var1} $arr ";
        }
        else{
          if ($condInner =~ /^not/){
            $outputCond.="not ";
            $condInner =~ s/^not\s*//;
          }
          my $bool = inputcheck($condInner);
          if ($bool eq "UNDEFINED"){
            $output="#$line {\n";
            last OUTER;
          }
          $outputCond.="$bool ";
        }
        $outputCond.="$conjunction ";
      }
      $output.= "( ".$outputCond."){\n" if $output ne "#$line {\n";
    }
    
    if ($action =~ /[a-zA-Z0-9]/){ #single line if/while statements
      while($action =~ /([^;]+);?\s*/g){
        $output.="  " foreach (1..$noLoop);
        $output.=checker($1);
      }
      $noLoop--;
      $output.="  " foreach (1..$noLoop);
      $output.="}\n";
    }
    else{ #single line if while/statement
      $action = <>;
      $action =~ /^(\s+)(.*)\s*$/;
      my $spaces = $1;
      $output.="  " foreach (1..$noLoop);
      $output.=checker ($2);
      while ($action = <>){
        if ($action =~ /^$spaces([^\s].*)\s*$/){
          $output.="  " foreach (1..$noLoop);
          $output.=checker ($1);
        }
        else{
          last;
        }
      }
      $noLoop--;
      $output.="  " foreach (1..$noLoop);
      $output.="}\n";
      my $nextline = $action;
      if (defined($nextline)){
        $output.="  " foreach (1..$noLoop);
        $output.=checker($nextline);
      }
    }
    return $output;
  }
  
  ### For loops
  elsif($line =~ /^\s*for\s+(.+)\s+in\s+(.+)\s*:\s*(.*)\s*$/){
    my $var = $1;
    my $array = inputcheck($2);
    return "#$line\n" if $array eq "UNDEFINED";
    my $action = $3;
    $output.="foreach \$$var (".$array."){\n";
    $noLoop++;
    if ($action =~ /[a-zA-Z0-9]/){ #single line if/while statements
      while($action =~ /([^;]+);?\s*/g){
        $output.="  " foreach(1..$noLoop);
        $output.=checker($1);
      }
      $noLoop--;
      $output.="  " foreach (1..$noLoop);
      $output.="}\n";
    }
    else{ #multi line if/while statements
      $action = <>;
      $action =~ /^(\s+)(.*)\s*$/;
      my $spaces = $1;
      $output.="  " foreach(1..$noLoop);
      $output.=checker ($2);
      while ($action = <>){
        if ($action =~ /^$spaces([^\s].*)\s*$/){
          $output.="  " foreach(1..$noLoop);
          $output.=checker ($1);
        }
        else{
          last;
        }
      }
      $noLoop--;
      $output.="  " foreach (1..$noLoop);
      $output.="}\n";
      my $nextline = $action;
      if (defined($nextline)){
        $output.="  " foreach(1..$noLoop);
        $output.=checker($nextline);
      }
    }
    return $output;
  }
  
  ### +=, -= etc
  elsif($line !~ /;/ and $line =~ /^\s*([^\s*]*)\s*([+\-*])=\s*(.+)\s*/){
    my $var1 = inputcheck($1);
    return "#$line\n" if $var1 eq "UNDEFINED";
    my $op = $2;
    my $var2 = inputcheck($3);
    return "#$line\n" if $var2 eq "UNDEFINED";
    if ($last_type eq "STRING" or $last_type eq "\@"){
      if ($op ne "+"){
        return "#$line\n";
      }
      else{
        return "$var1.=$var2\n";
      }
    }
    else{
      return "$var1 = $var1 $op $var2\n";
    }
  }
  
  ### VARIABLE INITIALISATION
  elsif($line !~ /;/ and $line =~ /^\s*([^\s]*)\s*=\s*(.*)\s*$/){
    my $output = varInit($1, $2);
    return "" if $output eq "";
    return "#$line\n" if $output eq "UNDEFINED";
    return $output.";\n";
  }
  elsif($line =~ /^\s*sys\.stdout\.write\((.*?)\)\s*$/){
    my $output = inputcheck($1);
    return "#$line\n" if $output eq "UNDEFINED";
    return "print $output;\n";
  }
  ### ARRAY POP
  elsif($line =~ /^\s*([^\.\s]+)\.pop\(\s*\)\s*/g ){
    my $arr = $1;
    return "pop \@$arr;\n";
  }
  ### ARRAY APPEND
  elsif($line =~ /^\s*([^\.\s]+)\.append\((.*)\)\s*/g ){
    my $arr = $1;
    my $var = inputcheck($2);
    return "#$line\n" if $var eq "UNDEFINED";
    return "push \@$arr, $var;\n" if defined($var_type{$arr}) and $var_type{$arr} eq "\@";
    return "\$$arr .= $var;\n";
  }
  
  ### PRINT ###
  elsif ($line !~ /;/ and $line =~ /^\s*print\s*(.*)\s*$/){
    my $string = $1;
    
    #blank print
    if($string eq ""){
      return "print \"\\n\";\n";
    }
    #Print with formatting
    elsif ($string =~ /^(['"].+["'])\s*%\(?(.+?)\)?\s*$/){
      $output = $1;
      my @vars = split(/\s*,\s*/, $2);
      $output =~ s/["']$//;
      $output = "$output\\n\"";
      foreach (@vars){
        $output.=", ";
        $_ = inputcheck($_);
        return "#$line\n" if $_ eq "UNDEFINED";
        $output.=$_;
      }
      return "printf $output;\n";
    }
    #Printing quoted strings
    elsif($string =~ /^["'](.*)['"]$/){
      return "print \"$1\\n\";\n";
    }
    #Printing variables, strings etc, including ones separated by commas
    else{
      my $output="";
      while ($string =~ /(\"((.*?(\\(\\{2})*\")*)+)\"|[^(),]+(?1)?|(\((?:[^()]+|(?2))*\)))(,\s*|\s*$)/xg){
        my $var = $1;
        $var =~ s/^\s*|\s*$//g;
        $var = inputcheck($var);
        return "#$line\n" if $var eq "UNDEFINED";
        $output.="$var, ";
      }
      return "print $output\"\\n\";\n";
    }
  }
  ### break/continue
  elsif ($line =~/^\s*(break|continue)\s*$/){
    $line =~ s/break/last;/;
    $line =~ s/continue/next;/;
    return $line."\n";
  }
  ### import
  elsif ($line !~ /;/ and $line =~ /^\s*import/){
    return;
  }
  ### return
  elsif ($line =~ /\s*return\s*(.*)\s*$/){
    return "return;\n" if $1 eq "";
    $output = inputcheck($1);
    return "#$line\n" if $output eq "UNDEFINED";
    return "return $output;\n";
  }
  ### Single line commands
  elsif ($line =~ /;/){
    while($line =~ /([^;]+);?\s*/g){
      $output.="  " foreach(1..$noLoop);
      $output.=checker($1);
    }
    return $output;
  }
  else {
    return "#$line\n";
  }
}

while (my $ip = <>) {

  print checker($ip);
}


