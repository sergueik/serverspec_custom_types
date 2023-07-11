require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

# NOTE:  line-endin-sensitive, run throuh sed -i 's/\r//' json_bash_processor_spec.rb
context 'HTML TagParser exercise' do
  basedir = '/tmp'
  js_sh_script = "#{basedir}/jq.sh"
  js_sh_data = <<-EOF
#!/usr/bin/env bash

# Автор: Владимир Олейник <dzo@simtreas.ru> (C) 2019
# origin: http://www.simtreas.ru/~dzo/yacc_bash_jq.html
# see also: https://www.linux.org.ru/news/opensource/15029405
# compiled from version:
# yychar: a current lexem, yyerrflag: then flag of recovery after error
declare -i yychar yyerrflag

#line 2 "jq.yb"
# The minimalistic bash realization of the mainstream 'jq' utility.
#
# Copyright (c) 2019 may safely be consumed by a BSD or GPL license.
# Written by:   Vladimir Oleynik <dzo@simtreas.ru>

declare -i START_FILTER=257 START_INPUTS=258 J_NULL=259 J_FALSE=260
declare -i J_TRUE=261 J_INT=262 J_REAL=263 STR=264
declare -i ARRAY=265 OBJECT=266 LITERAL=267 FUNC=268
declare -i SLICE=269 OBJ_EXP=270 KEY=271 KEY4OUT=272
declare -i COMMA=273 PIPE=274 BRACE=275 MAP=276
declare -i HAS=277 FLATTEN=278 SUM=279 SUB=280
declare -i MAP_VALUES=281 ANY=282 NEG=283 MULT_DIV_MOD=284
declare -i INDEX=285 RINDEX=286 LEX_EOF=287 JOIN=288
declare -i SPLIT=289

#line 22 "jq.yb"

usage() {
	echo "Usage:
$0 [-c] [-s] [-n] [-C] [-M] [-f file] [-d] FILTER [files...]

Options:

-c:  Compact output in single line.
-s:  Instead of running the filter for each JSON object in the input,
     read the entire input stream into a large array and run the filter
     just once.
-n:  Don't read any input at all. Instead, the filter is run once using null
     as the input.
-C:  Force to produce color even if writing to a pipe or a file.
-M:  Disable colorization if writing to a terminal.
-f:  Read filter from the file rather than from a command line.
     You can also use as the shebang #!$0 -f
-d:  Debug mode. Show the filter parser rezult.

Support jq FILTER:

. .. .key1.key2... ."key" .[key1,key2...]
[] [value1,value2...] .[index1,index2...]
{} {key1,key2...} {key1:value1,key2:value2...}
| , .[slice_begin:slice_end] keys keys_unsorted length reverse tostring env
type add sort
arrays objects iterables booleans numbers strings nulls values scalars
(expr) expr+expr expr-expr expr*expr expr/expr expr%expr
any any(expr) any(expr;expr) has() index(expr) map() map_values() rindex(expr)
split(expr) join(expr) flatten flatten(expr)

keys, values or indexes is a expession, for example: {(.k1): .k1|length}
indexes allow negative. Keys expression may be optional: .k? .[klist]? .[b:e]?
{key} is short form of {"key":.key}

Comments: #EOL or /* a block of lines */
Escaping in string:
 \\a \\b \\e \\f \\n \\r \\t \\v \\N \\NN \\NNN (N:[0-7]) \\xH \\xHH
 \\uH \\uHH \\uHHH \\uHHHH (H:[0-9A-Fa-f])"
	exit 2
} >&2

# Global variables. J - the nodes counter, LN - lines counter, O - outputs
declare -i TOK_TYPE TOK_OFFS J=0 LN EOF=0 lex_stage
# Nodes. [0] - root node
#  N_V_L: value or list of numbers as links to allocated nodes
#  example: N_TYPE[J]=STR N_V_L[J]=str;
#   N_TYPE[J]=ARRAY N_V_L[J]=' 1 2' - links to N_*[1] and N_*[2] and
#   two space - used for counting of elements
declare -a -i N_TYPE
declare -a FILES N_KEY N_V_L

# constants
SPACES=$' \\t\\r\\v\\f'
White=$'\\033[1;37m'
Green=$'\\033[0;32m'
Dark_Gray=$'\\033[1;30m'
Blue=$'\\033[1;34m'
Yellow=$'\\033[1;33m'
Cyan=$'\\033[1;36m'
Purple=$'\\033[0;35m'
NC=$'\\033[0m' # No Color


declare -i UNGETC_V=0 INPUTS_FIRST_CHAR=0 INPUTS=1 FILTER_FIRST_CHAR=2 FILTER=3 FD=0
declare -a FUNC_NAMES=(reverse keys keys_unsorted length .. tostring env add
 sort flatten type any
 arrays objects iterables booleans numbers strings nulls values scalars)
declare -a T_N=([ARRAY-J_NULL]=array [OBJECT-J_NULL]=object
			[J_TRUE-J_NULL]=boolean [J_FALSE-J_NULL]=boolean
			[J_INT-J_NULL]=number [J_REAL-J_NULL]=number
			[J_NULL-J_NULL]=null [STR-J_NULL]=string)
err() {
	local in_t
	[[ lex_stage -eq FILTER ]] && in_t=" in filter"
	echo "$0: error$in_t: $1 at line $LN, column $((TOK_OFFS+1))" >&2
	exit 6
}

dequote() {
	local -i i=${1:-0}+1
	local s q

	unsupport0() {
		if [[ -z $q ]]; then
			TOK_OFFS=i
			err "unsupport zero character"
		fi
	}
	yylval=
	while true; do
		s=${S:i}
		q=${s%%[\\"\\\\$'\\001'-$'\\037']*}
		yylval+=$q
		i+=${#q}
		if [[ $q = "$s" ]]; then
			TOK_OFFS=i
			err "unterminated string"
		fi
		s=${S:i:2}
		i+=2
		case "$s" in
		\\"*)     TOK_OFFS=i-1; return 0;;
		\\\\t)     yylval+=$'\\t' ;;
		\\\\r)     yylval+=$'\\r' ;;
		\\\\v)     yylval+=$'\\v' ;;
		\\\\f)     yylval+=$'\\f' ;;
		\\\\n)     yylval+=$'\\n' ;;
		\\\\a)     yylval+=$'\\a' ;;
		\\\\b)     yylval+=$'\\b' ;;
		\\\\e)     yylval+=$'\\e' ;;
		\\\\\\")    yylval+='"' ;;
		\\\\\\\\)    yylval+='\\' ;;
		\\\\[0-7]) q=${S:i-2:2};
			 if [[ ${S:i:1} = [0-7] ]]; then
				q+=${S:i++:1}
				[[ ${S:i:1} = [0-7] ]] && q+=${S:i++:1}
			 fi
			 printf -v q "$q"
			 unsupport0 || return 1
			 yylval+=$q ;;
		\\\\x)     if [[ ${S:i:1} != [0-9A-Fa-f] ]]; then
				TOK_OFFS=i
				err "invalid escape string"
			 fi
			 q=\\\\x${S:i++:1}
			 [[ ${S:i:1} = [0-9A-Fa-f] ]] && q+=${S:i++:1}
			 printf -v q "$q"
			 unsupport0
			 yylval+=$q ;;
		\\\\u)     if [[ ${S:i:1} != [0-9A-Fa-f] ]]; then
				TOK_OFFS=i
				err "invalid escape string"
			 fi
			 q=${S:i-2:3}
			 i+=1
			 if [[ ${S:i:1} = [0-9A-Fa-f] ]]; then
				q+=${S:i++:1}
				[[ ${S:i:1} = [0-9A-Fa-f] ]] && q+=${S:i++:1}
				[[ ${S:i:1} = [0-9A-Fa-f] ]] && q+=${S:i++:1}
			 fi
			 if [[ $q = "\\\\u0" || $q = "\\\\u00" || $q = "\\\\u000" || $q = "\\\\u0000" ]]; then
				q=
				unsupport0
			 fi
			 printf -v q "$q" || return 1
			 [[ -z $q ]] && err "unsupport a character in the your language"
			 yylval+=$q ;;
		\\\\$'\\n') ;;
		\\\\\\$)    [[ -z $2 ]] && err "invalid escape string"
			 yylval+=\\$ ;;
		*)       TOK_OFFS=i-1; err "invalid escape string";;
		esac
	done
}

printf -v MULT "%d" "'*"
printf -v DIV "%d" "'/"
printf -v MOD "%d" "'%"

lex1c() {
	yylval=$TOK_OFFS
	TOK_OFFS=i+1
	printf -v yychar "%d" "'$1"
}

lex1cm() {
	TOK_OFFS=i+1
	printf -v yylval "%d" "'$1"
	yychar=MULT_DIV_MOD
}

literal() {
	[[ ${S:i} =~ ^$1 ]] || return 1
	yychar=${2:-LITERAL}; yylval=$BASH_REMATCH; TOK_OFFS=i+${#yylval}
}

err_rem() {
	TOK_OFFS=bi
	LN=bln
	err "end of comment do not found"
}

yylex() {
	if [[ lex_stage -eq FILTER_FIRST_CHAR ]]; then
		lex_stage=FILTER
		yychar=START_FILTER
		LN=1
		TOK_OFFS=0
		return
	fi
	if [[ lex_stage -eq INPUTS_FIRST_CHAR ]]; then
		lex_stage=INPUTS
		yychar=START_INPUTS
		return
	fi
	if [[ lex_stage -eq INPUTS && UNGETC_V -gt 0 ]]; then
		yychar=UNGETC_V
		UNGETC_V=0
		return
	fi
	local -i i=TOK_OFFS

	while true; do
		case "${S:i:1}" in
		[$SPACES])      [[ ${S:i} =~ [$SPACES]* ]]
				i+=${#BASH_REMATCH};;

		$'\\n')          if [[ lex_stage -eq FILTER ]]; then
					S=${S:i+1}
					LN+=1 ; i=0 ; TOK_OFFS=0
					continue
				fi
				S=
				if read -u $FD -r S; then
					S+=$'\\n'
					LN+=1
					TOK_OFFS=0
				fi
				# else - next file
				i=0
				continue;;

		"")             if [[ lex_stage -eq FILTER ]]; then
					yychar=0; return
				fi
				# open file
				while true; do
					if [[ ${#FILES[@]} -eq 0 ]]; then
						EOF=1; yychar=LEX_EOF; return
					fi
					S=${FILES[0]}
					# remove first element
					FILES=("${FILES[@]:1}")
					if [[ $S = - ]]; then
						FD=0
					else
						exec 9< "$S" || continue
						FD=9
					fi
					break
				done
				# goto first line
				S=$'\\n'
				LN=0
				continue;;

		[A-Za-z_])      if [[ lex_stage -eq FILTER ]]; then
					literal '[A-Za-z_][0-9A-Za-z_]*'
				else
					literal '[A-Za-z_][-0-9A-Za-z_.@]*'
				fi
				return;;

		[-0-9.])        if [[ lex_stage -eq FILTER && ${S:i:1} = '-' ]]; then
					lex1c '-'
				elif literal '-?(\\.?[0-9][0-9]*|[0-9][0-9]*\\.[0-9]*)([Ee][-+]?[0-9][0-9]*)?' $J_REAL; then
					true
				elif [[ ${S:i:1} = . ]]; then
					[[ lex_stage -eq INPUTS ]] && err "unexpected '.'"
					if [[ ${S:i:2} = .. ]]; then
						yylval=..
						yychar=LITERAL
						TOK_OFFS=i+2
					else
						lex1c .
					fi
				else
					err "invalid numeric literal"
				fi
				return;;

		\\")             yychar=STR; dequote $i ; return;;

		[]{}:,[])       lex1c "${S:i:1}"; return;;

		/)              if [[ ${S:i+1:1} = '*' ]]; then
					local -i bi=i bln=LN
					local r r2
					i+=2
					S=${S:i}
					TOK_OFFS=i
					while true; do
						r=${S#*\\*/}
						[[ $r = "$S" && lex_stage -eq FILTER ]] && err_rem
						if [[ $r = "$S" ]]; then
							if read -u $FD -r S; then
								S+=$'\\n'
								LN+=1
								TOK_OFFS=0
							else
								err_rem
							fi
						else
							r2=${S#*[$'\\n']}
							[[ ${#r2} -lt ${#r} ]] && break
							S=$r2
							LN+=1
							TOK_OFFS=0
						fi
					done
					i=${#S}-${#r}
				else
					[[ lex_stage -eq INPUTS ]] && err "unexpected '/'"
					lex1cm /; return
				fi ;;

		\\#)             [[ ${S:i} =~ [^$'\\n']* ]]
				i+=${#BASH_REMATCH};;


		"*"|"%")        [[ lex_stage -eq INPUTS ]] && err "unexpected '${S:i:1}'"
				lex1cm "${S:i:1}"; return;;

		"|"|"("|")"|"]"|"?"|"+"|";")
				[[ lex_stage -eq INPUTS ]] && err "unexpected '${S:i:1}'"
				lex1c "${S:i:1}"; return;;

		*)              err "unexpected '${S:i:1}'" ;;
		esac
	done
}

declare -i L
tst_literal() {
	case "$1" in
	 null)  L=J_NULL;;
	 true)  L=J_TRUE;;
	 false) L=J_FALSE;;
	 *)     if [[ lex_stage -eq FILTER ]]; then
			local f
			for f in ${FUNC_NAMES[*]}; do
				if [[ $1 = $f ]]; then
					L=FUNC
					return
				fi
			done
		fi
		L=STR;;
	esac
}

node() {
	local j
	N_TYPE[++J]=$1; N_V_L[J]=$2; shift 2
	yyval=
	for j; do
		if [[ $j == J ]]; then
			yyval+=" $J"
		else
			yyval+=" $j"
		fi
	done
}

tst_dup_key_in_obj() {
	local -i -a o
	local -i k kt

	yyval=
	for k in $1; do
		for kt in ${o[@]}; do
			if [[ ${N_KEY[k]} = "${N_KEY[kt]}" ]]; then
				N_V_L[kt]=${N_V_L[k]}
				continue 2
			fi
		done
		o+=(k)
		yyval+=' '$k
	done
}



# yychar: a current lexem, yyerrflag: then flag of recovery after error
declare yylval yyval

yyclearin() { yychar=-1; }
yyerrok() { yyerrflag=0; }

declare -i YYERRCODE=256
declare -i -a yyexca=(
	-1 1
	0 -1
	-2 0
)

declare -i YYNPROD=83
declare -i YYLAST=465

declare -i -a yyact=( 
  45   89   19  124   54   45   79   19   24   22 
  25   99   19   24   22   25   24   22   25   24 
  22   25  129  119   24   22   25   26  110  100 
  24   22   25   44   20   48    2    3   44   20 
  48   17   45   72   20   24   22   25   91   82 
  87   24   22   25   77   24   78   25  118   51 
  49   57   46   50   42   43  132  114   71  128 
  43   75   58   60    8   44   38   48   84    6 
  13   40   45   85   85    8  123   93   30   23 
   6   13   96    8   23   69   37   23   35   13 
  23   32   62    8   28   23    7   43   35   13 
  42   23   47   70   92   44    8   48    8   59 
  74   35   13    6   13   11   23   94   45   90 
  81  111   23   61  115   76   11   83  126   56 
   1   41    0    0   11   33  102   43    0  108 
  39    0  112   98   11   53   31   12    0  107 
   5   44   10   48   52  113   18   11   12   11 
   0    0   34   62   15   14   12    0   21   15 
  14   80   18   21   15   14   12   19   21   48 
   0    0    0   43    0   36   34    0   55   12 
   0   12    0  116   61   51   49    0   16   50 
  51   49    0   97   50    0    0    0    0   20 
   0  101  103  104  105  106    0    0    0   63 
 109    0  117    0   63  121   34   34   34   34 
  34    0    0    0   88   34    0   51   49   26 
   0   50   18    0   26   18  125   26    0    0 
  26    0    0    0  131   26  133    0    0  130 
 134   26    0    0    0    0    0    0    0    0 
   0    0    0    0   34    0   26   51   49    0 
   0   50   26    0    0   79   26   15   14    0 
   0    9    0    0    0    0    0    0   15   14 
   0    0    9    0    0    0   15   14    0    0 
   9    0    0    0    0    0   15   14    0    0 
   9    0    0   51   49    0    0   50    0   15 
  14   15   14    9    4    9    0    0    0    0 
   0   27    0   29    0    0    0    0    0   15 
  14    0    0   21    0    0    0   64   65   66 
  67   68    0    0    0   73    0    0    0    0 
   0    0    0    0    0    0    0   86    0    0 
   0    0    0    0    0    0    0    0    0    0 
   0    0    0    0    0    0    0    0    0    0 
   0    0    0    0    0   95    0    0    0    0 
   0    0    0    0    0    0    0    0    0    0 
   0    0    0    0    0    0    0    0    0    0 
   0  120    0    0    0  122    0    0    0    0 
   0    0    0    0    0    0    0    0    0    0 
   0    0    0    0  127 )

declare -i -a yypact=( 
-221 -1000   78  -79    8 -1000   78 -1000   78   48 
-1000   63   70 -204 -1000 -1000 -1000 -1000 -1000  -89 
 -53 -1000   78   78   78   78   78 -257   22    2 
  78 -1000   27   11 -1000   76 -1000    5 -1000 -1000 
-1000   20   78 -1000 -1000 -1000 -1000 -1000 -1000 -1000 
-1000 -1000 -1000   21 -1000 -1000  -43 -1000 -1000    4 
-1000   29 -1000 -1000   12    8 -257 -257 -1000 -1000 
  34  -16 -1000  -30 -1000   53   76   76   76   76 
-278 -1000   24 -1000   76 -1000  -13 -1000 -1000   96 
-1000  -58  -84 -1000   21  -35   78   21 -1000 -1000 
  78   11 -1000   11 -278 -278 -1000 -1000 -1000   11 
  28 -1000 -1000 -1000 -1000 -284 -1000 -1000   21   45 
 -24 -1000  -19   76 -1000 -1000   21  -27   21 -1000 
  11 -1000   21 -1000 -1000 )

declare -i -a yypgo=( 
   0  140  344   41  162  139  119   62   73  112 
 114   81  160  106  104  137  101   96  150   95 
 141  145   76 )

declare -i -a yyr1=(
   0    1    1    1    1    3    3    3    3    3 
   3    3    5    5    5    6    6    6    8    8 
   8    8    8   10   10   11   11   11   11    7 
   2    2    2    2    2    2    2   12   12   12 
  12   15   15   13   13   13   13   13   13   13 
   4    4    4   14   14   19   19   19   19   19 
  19   19   18   16   16   16   17   17   17   22 
  22   22   22   20    9    9    9   21   21   21 
  21   21   21 )

declare -i -a yyr2=(
   0    1    2    2    2    1    2    2    3    3 
   2    3    1    3    3    1    3    3    3    3 
   4    1    1    0    1    1    1    1    1    1 
   3    3    3    3    3    1    2    2    3    4 
   6    0    1    1    2    3    2    3    1    2 
   1    1    1    0    2    3    4    5    5    6 
   3    2    2    1    3    3    1    3    3    1 
   1    3    5    1    1    1    1    1    3    3 
   3    3    2 )

declare -i -a yychk=(
-1000   -1  257  258   -2  -12   45  -13   40  267 
  -4   91  123   46  264  263  287   -3   -4   91 
 123  267   44  124   43   45  284   -2  -14   -2 
  40   93  -16  -21  -12   45  125  -17  -22  -18 
 -11  -20   40  123   91   58   -7   -9   93  264 
 267  263  -18  -20   93  287   -5   -3  125   -6 
  -8   -9  -11  287   -2   -2   -2   -2   -2  -19 
  91   46   41   -2   93   44  124   43   45  284 
 -21  125   44  -15   58   63   -2   93  287   44 
 125   44  -10   58   93   -2   58  -20  -11   41 
  59  -21   93  -21  -21  -21  -21  -22  125  -21 
  41   -3   -7   -8  125   -3  287  -15   93   58 
  -2  -15   -2   58  287  -15   93   -2   93   41 
 -21  -15   93  -15  -15 )

declare -i -a yydef=(
   0   -2    1    0    2   35    0   53    0   50 
  43    0    0   48   51   52    3    4    5    0 
   0   50    0    0    0    0    0   36   37    0 
   0   44    0   63   77    0   46    0   66   69 
  70   41    0   25   26   27   28   73   29   74 
  75   76   49   41    6    7    0   12   10    0 
  15   23   21   22   30   31   32   33   34   54 
   0    0   38    0   45    0    0    0    0    0 
  82   47    0   62    0   42    0    8    9    0 
  11    0    0   24   41    0    0   41   61   39 
   0   64   65   78   79   80   81   67   68   71 
   0   13   14   16   17   18   19   55   41    0 
   0   60    0    0   20   56   41    0   41   40 
  72   57   41   58   59 )

declare -i YYFLAG=-1000
# return values:
# 0 - YYACCEPT
# 1 - YYABORT

yyparse() {
	local -i -a yys
	local -a yyv # the stack for values saving
	local -i yyj yym yyn yystate=0 yypvt yyps=-1 yypv=-1 ns=0

	yychar=-1
	yyerrflag=0

	# yystack: push state to the stack
	while true; do
		if [[ ns -eq 0 ]]; then
			yys[++yyps]=yystate
			yyv[++yypv]=$yyval
		else
			ns=0
		fi

		# yynewstate:
		yyn=yypact[yystate]
		if [[ yyn -gt YYFLAG ]]; then
			# complex state
			[[ yychar -lt 0 ]] && yylex
			yyn+=yychar
			if [[ yyn -ge 0 && yyn -lt YYLAST ]]; then
				yyn=yyact[yyn]
				if [[ yychk[yyn] -eq yychar ]]; then # may be shift
					yychar=-1
					yyval=$yylval
					yystate=yyn
					[[ yyerrflag -gt 0 ]] && yyerrflag=yyerrflag-1
					continue # goto yystack
				fi
			fi
		fi

		# default action

		yyn=yydef[yystate]
		if [[ yyn -eq -2 ]]; then
			[[ yychar -lt 0 ]] && yylex

			# find from the exeption table
			for((ns=0; (yyexca[ns]!=(-1)) || (yyexca[ns+1]!=yystate); ns+=2)); do
				true
			done

			while true; do
				ns+=2
				[[ yyexca[ns] -lt 0 ]] && break
				[[ yyexca[ns] -eq yychar ]] && break
			done
			yyn=yyexca[ns+1]
			[[ yyn -lt 0 ]] && return 0   # OK
			ns=0
		fi

		if [[ yyn -eq 0 ]]; then
			# error ... try continue

			case $yyerrflag in
			 0)     # found first error
				# yyerror "syntax error"
				return 1;;

			 1|2)   # incomplete recovery, try again
				yyerrflag=3

				# find a state for allow shifting if error

				while [[ yyps -ge 0 ]]; do
					yyn=yypact[yys[yyps]]+YYERRCODE
					if [[ yyn -ge 0 && yyn -lt YYLAST && yychk[yyact[yyn]] -eq YYERRCODE ]]; then
						# imitation shift while error
						yystate=yyact[yyn]
						continue 2 # goto yystack
					fi
					yyn=yypact[yys[yyps]]

					# in current 'yyps' do not found shifting for error, popup from the stack

					yyps=yyps-1
					yypv=yypv-1
				done

				# in stack do not found a state of shifting... abort
				return 1;;

			 3)     # cannot shifting, get then lexem
				[[ yychar -eq 0 ]] && return 1 # EOF, abort
				yychar=-1
				# goto yynewstate: try again with a current state
				ns=1
				continue;;
			esac
		fi

		# reduce 'yyn' rule

		yyps=yyps-yyr2[yyn];
		yypvt=yypv
		yypv=yypv-yyr2[yyn]
		yyval=${yyv[yypv+1]}
		yym=yyn

		# get a next state from the table of states
		yyn=yyr1[yyn]
		yyj=yypgo[yyn]+yys[yyps]+1
		if [[ yyj -ge YYLAST ]]; then
			yystate=yyact[yypgo[yyn]]
		else
			yystate=yyact[yyj]
			[[ yychk[yystate] -ne -yyn ]] && yystate=yyact[yypgo[yyn]]
		fi
		case $yym in
		 1) node $FUNC . J; return ;;
		 2) yyval=${yyv[yypvt]}; return ;;
		 3) N_V_L[0]=; return ;;
		 4) UNGETC_V=yychar; N_V_L[0]=${yyv[yypvt]}; return ;;
		 6) node $ARRAY "" J ;;
		 7) err "unterminated array"  ;;
		 8) node $ARRAY "${yyv[yypvt-1]}" J ;;
		 9) err "unterminated array"  ;;
		 10) node $OBJECT "" J ;;
		 11) tst_dup_key_in_obj "${yyv[yypvt-1]}"; node $OBJECT "$yyval" J ;;
		 13) yyval=${yyv[yypvt-2]}${yyv[yypvt]} ;;
		 16) yyval=${yyv[yypvt-2]}${yyv[yypvt]} ;;
		 17) TOK_OFFS=${yyv[yypvt]}; err "unexpected ',' or '}'"  ;;
		 18) N_KEY[${yyv[yypvt]}]=${yyv[yypvt-2]}; yyval=${yyv[yypvt]} ;;
		 19) err "unterminated object"  ;;
		 20) err "unterminated object"  ;;
		 21) TOK_OFFS=${yyv[yypvt]}; err 'need a "key":'  ;;
		 22) err "unterminated object"  ;;
		 23) err "expected ':'"  ;;
		 29) TOK_OFFS=${yyv[yypvt]}; err "unexpected ']'"  ;;
		 30) node $COMMA "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 31) node $PIPE "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 32) node $SUM "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 33) node $SUB "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 34) node ${yyv[yypvt-1]} "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 36) node $NEG "${yyv[yypvt]}" J ;;
		 37) yyval=${yyv[yypvt-1]}${yyv[yypvt]} ;;
		 38) node $BRACE "${yyv[yypvt-1]}" J ;;
		 39) case ${yyv[yypvt-3]} in
			   map) node $MAP "${yyv[yypvt-1]}" J;;
			   map_values) node $MAP_VALUES "${yyv[yypvt-1]}" J;;
			   has) node $HAS "${yyv[yypvt-1]}" J;;
			   any) node $ANY "${yyv[yypvt-1]}" J; N_KEY[J]=;;
			   index) node $INDEX "${yyv[yypvt-1]}" J;;
			   rindex) node $RINDEX "${yyv[yypvt-1]}" J;;
			   split) node $SPLIT "${yyv[yypvt-1]}" J;;
			   join) node $JOIN "${yyv[yypvt-1]}" J;;
			   flatten) node $FLATTEN "${yyv[yypvt-1]}" J;;
			   *)   err "unknown function ${yyv[yypvt-3]}()";;
			  esac
			  N_KEY[J]=${yyv[yypvt-3]} ;;
		 40) case ${yyv[yypvt-5]} in
				 any) node $ANY "${yyv[yypvt-1]}" J; N_KEY[J]=${yyv[yypvt-3]};;
				 *)   TOK_OFFS=${yyv[yypvt-2]}; err "unexpected ';'";;
				esac  ;;
		 41) yyval= ;;
		 42) node $FUNC '?' J ;;
		 44) node $ARRAY "" J ;;
		 45) node $ARRAY "${yyv[yypvt-1]}" J ;;
		 46) node $OBJECT "" J ;;
		 47) node $OBJECT "${yyv[yypvt-1]}" J ;;
		 48) node $FUNC . J ;;
		 49) yyval=${yyv[yypvt]} ;;
		 50) tst_literal ${yyv[yypvt]}; node $L "${yyv[yypvt]}" J ;;
		 51) node $STR "${yyv[yypvt]}" J ;;
		 52) [[ ${yyv[yypvt]} =~ ^-?[0-9][0-9]*$ ]]
			  node $(($?==0?J_INT:J_REAL)) "${yyv[yypvt]}" J  ;;
		 53) yyval= ;;
		 54) yyval=${yyv[yypvt-1]}${yyv[yypvt]} ;;
		 55) node $FUNC any_keys ${yyv[yypvt]} J ;;
		 56) node $KEY4OUT "${yyv[yypvt-2]}" ${yyv[yypvt]} J ;;
		 57) node $SLICE "${yyv[yypvt-3]}:" ${yyv[yypvt]} J ;;
		 58) node $SLICE ":${yyv[yypvt-2]}" ${yyv[yypvt]} J ;;
		 59) node $SLICE "${yyv[yypvt-4]}:${yyv[yypvt-2]}" ${yyv[yypvt]} J ;;
		 60) node $KEY4OUT "${yyv[yypvt-1]}" ${yyv[yypvt]} J ;;
		 61) TOK_OFFS=${yyv[yypvt]}; err "expected literal"  ;;
		 62) node $KEY "${yyv[yypvt-1]}" ${yyv[yypvt]} J ;;
		 63) node $BRACE "${yyv[yypvt]}" J ;;
		 64) node $BRACE "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 65) TOK_OFFS=${yyv[yypvt]}; err "unexpected ',' or ']'"  ;;
		 67) yyval=${yyv[yypvt-2]}${yyv[yypvt]} ;;
		 68) TOK_OFFS=${yyv[yypvt]}; err "unexpected ',' or '}'"  ;;
		 69) node $OBJ_EXP "${yyv[yypvt]}" J; N_KEY[J]=${yyv[yypvt]} ;;
		 70) TOK_OFFS=${yyv[yypvt]}; err 'expected "key": or (key_expression)'  ;;
		 71) node $OBJ_EXP "${yyv[yypvt]}" J; N_KEY[J]=${yyv[yypvt-2]} ;;
		 72) node $OBJ_EXP "${yyv[yypvt]}" J; N_KEY[J]=${yyv[yypvt-3]} ;;
		 73) node $STR "${yyv[yypvt]}" J ;;
		 78) node $PIPE "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 79) node $SUM  "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 80) node $SUB  "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 81) node ${yyv[yypvt-1]} "${yyv[yypvt]}" ${yyv[yypvt-2]} J ;;
		 82) node $NEG "${yyv[yypvt]}" J ;;
		esac
	done  # push a new state and the value to stack
}

# line 566 "jq.yb"


node_o() {
	[[ $3 ]] && O=
	N_TYPE[++J]=$1; N_V_L[J]=$2; O+=' '$J
}

quote() {
	local s=$1 q c

	yylval=\\"
	while true; do
		q=${s%%[\\"\\\\$'\\001'-$'\\037']*}
		if [[ $q != "$s" ]]; then
			case "${s:${#q}:1}" in
			 \\")    c=\\\\\\" ;;
			 \\\\)    c=\\\\\\\\ ;;
			 $'\\t') c='\\t' ;;
			 $'\\r') c='\\r' ;;
			 $'\\v') c='\\v' ;;
			 $'\\f') c='\\f' ;;
			 $'\\n') c='\\n' ;;
			 $'\\a') c='\\a' ;;
			 $'\\b') c='\\b' ;;
			 $'\\e') c='\\e' ;;
			 *)     printf -v c "%s%04x" '\\u' \\'"${s:${#q}:1}"
			esac
			yylval+=$q$c
			s=${s:${#q}+1}
		else
			yylval+=$q\\"
			return 0
		fi
	done
}

# color optimization and buffering
set_P_C() {
	[[ -z $nocolor && $P_C != $1 ]] && { P_C=$1; O_C+=${!1}; }
}
print_c() {
	local t a=$1
	shift

	while [[ $a ]]; do
		if [[ ${a:0:1} != \\$ ]]; then
			t=${a%%\\$*}
			a=${a:${#t}}
			O_C+=$t
		else
			t=${a:2}; t=${t%%\\}*}; a=${a:3+${#t}}
			case "$t" in
			 ,)     if [[ $c ]]; then
					set_P_C White; O_C+=,
				fi;;
			 q)     quote "$1"; shift; O_C+=$yylval;;
			 s)     O_C+=$1; shift;;
			 '*')   printf -v t "%*s" $1; shift; O_C+=$t;;
			 CR)    O_C+=${CR};;
			 *)     set_P_C "$t";;
			esac
		fi
	done
}

show_oa() {
	if [[ $# -gt 2 ]]; then
		local -i p in2=in
		local c2=$2 co

		[[ $1 = '{' ]] && p=OBJECT
		[[ $1 = '{' || $1 = '[' ]] && co=,
		[[ $CR ]] && in2+=2
		print_c '${White}${s}${CR}' "$1"
		shift 2
		while [[ $1 ]]; do
			human_readable $1 $in2 ${2:+$co}
			shift
		done
		print_c '${*}${White}${s}${,}${CR}' $in "$c2"
	else
		print_c '${White}${s}${,}${CR}' "$1$2"
	fi
}
human_readable() {
	local l=${N_V_L[$1]} c=$3 sc
	local -i in=$2

	print_c '${*}' $in
	[[ p -eq OBJECT ]] && print_c '${Blue}${q}${White}:${s}' "${N_KEY[$1]}" "${CR:+ }"
	case ${N_TYPE[$1]} in
	 $STR)                  print_c '${Green}${q}${,}${CR}' "$l";;
	 $J_NULL)               print_c '${Dark_Gray}${s}${,}${CR}' "$l";;
	 $J_TRUE|$J_FALSE)      print_c '${Yellow}${s}${,}${CR}' "$l";;
	 $OBJECT)               show_oa "{" "}" $l;;
	 $ARRAY)                show_oa "[" "]" $l;;
	 $OBJ_EXP)              sc=$c; c=; show_oa "" ":" ${N_KEY[$2]}; c=$sc
				show_oa "val(" ")" $l;;
	 $KEY)                  print_c '${Purple}.${s}${,}' "${N_V_L[$l]}";;
	 $KEY4OUT)              show_oa ".[" "]" $l;;
	 $COMMA)                show_oa "," "" $l;;
	 $SLICE)                sc=${l%%:*}; show_oa "slice(" "" $sc
				print_c '${White}:'
				sc=${l#"$sc:"}; show_oa "" ")" $sc;;
	 $PIPE)                 show_oa "| (" ")" $l;;
	 $BRACE)                show_oa "(" ")" $l;;
	 $SUM)                  show_oa "+ (" ")" $l;;
	 $SUB)                  show_oa "- (" ")" $l;;
	 $NEG)                  show_oa "-" "" $l;;
	 $MULT)                 show_oa " * (" ")" $l;;
	 $DIV)                  show_oa " / (" ")" $l;;
	 $MOD)                  show_oa " % (" ")" $l;;
	 $MAP|$MAP_VALUES|$HAS|$INDEX|$RINDEX|$SPLIT|$JOIN|$FLATTEN)
				show_oa "${N_KEY[$1]}(" ")" $l;;
	 $FUNC)                 print_c '${Purple}${s}${,}' $l;;
	 *)                     print_c '${Cyan}${s}${,}${CR}' "$l";;
	esac
}

dump() {
	local P_C=NC O_C CR nc=$nocolor
	local -i p
	[[ -z $compact && -z $2 ]] && CR=$'\\n'
	[[ $2 = dump_out ]] && nocolor=$2
	for t in $1; do
		human_readable $t 0
		if [[ $2 = debug ]]; then
			O_C+=' '
		elif [[ -z $CR && $2 != dump_out ]]; then
			O_C+=$'\\n'
		fi
	done
	set_P_C NC
	if [[ -z $2 ]]; then
		printf "%s" "$O_C"
	elif [[ $2 = debug ]]; then
		printf "%s\\n" "$O_C" >&2
	else
		dump_out=$O_C
		nocolor=$nc
	fi
}

# make_err ["message" $NODE]... ["suffix"]
make_err() {
	local dump_out r
	while [[ $1 || $2 ]]; do
		r+="${1:+ }$1"
		shift
		if [[ $1 ]]; then
			r+=" ${T_N[N_TYPE[$1]-J_NULL]}"
			dump $1 dump_out
			shift
			[[ $dump_out != null ]] && r+=" ($dump_out)"
		fi
	done
	[[ $r ]] && r="error:$r"
	echo "$r" >&2
}

do_recursive() {
	O+=' '$1
	if [[ N_TYPE[$1] -eq OBJECT || N_TYPE[$1] -eq ARRAY ]]; then
		local -i i
		for i in ${N_V_L[$1]}; do
			do_recursive $i
		done
	fi
}

show_type() {
	local -i t=N_TYPE[$2]
	case $1 in
	 arrays)        [[ t -eq ARRAY ]] && O=' '$2 ;;
	 objects)       [[ t -eq OBJECT ]] && O=' '$2 ;;
	 iterables)     [[ t -eq ARRAY || t -eq OBJECT ]] && O=' '$2 ;;
	 booleans)      [[ t -eq J_TRUE || t -eq J_FALSE ]] && O=' '$2 ;;
	 numbers)       [[ t -eq J_INT || t -eq J_REAL ]] && O=' '$2 ;;
	 strings)       [[ t -eq STR ]] && O=' '$2 ;;
	 nulls)         [[ t -eq J_NULL ]] && O=' '$2 ;;
	 values)        [[ t -ne J_NULL ]] && O=' '$2 ;;
	 scalars)       [[ t -ne ARRAY && t -ne OBJECT ]] && O=' '$2 ;;
	esac

}

length() {
	local v
	local -i

	O=
	v=${N_V_L[$1]}
	case ${N_TYPE[$1]} in
	$OBJECT|$ARRAY) v=${v//[^ ]/}
			node_o $J_INT ${#v} ;;

	$STR)           node_o $J_INT ${#v} ;;
	$J_INT|$J_REAL) O=' '$1 ;;
	$J_NULL)        node_o $J_INT 0 ;;
	*)
		make_err "" $1 "has no length"
		return 5 ;;
	esac

	return 0
}

do_reverse() {
	local o

	O=
	if [[ N_TYPE[$1] -eq J_NULL ]]; then
		true;
	elif [[ N_TYPE[$1] -ne ARRAY ]]; then
		make_err "cannot index" $1 "for reverse"
		return 5
	else
		local -i l
		for l in ${N_V_L[$1]}; do
			o=' '$l$o
		done
	fi
	node_o $ARRAY "$o"
}

do_tostring() {
	O=
	if [[ N_TYPE[$1] -eq STR ]]; then
		O+=' '$1
	else
		local dump_out
		dump $1 dump_out
		node_o $STR "$dump_out"
	fi
}

ENV_OBJECT=
do_env() {
	O=$ENV_OBJECT
	if [[ -z $O ]]; then
		local d o l S
		local -i TOK_OFFS
		while read d o l; do
			d=${l%%=*}
			S=${l#"$d="}
			if [[ $S != "$l" ]]; then
				dequote 0 '$'
			else
				yylval=
			fi
			node_o $STR "$yylval"
			N_KEY[J]=$d
		done < <(declare -p -x)
		node_o $OBJECT "$O" O
		ENV_OBJECT=$O
	fi
}

do_index() {
	local -i i
	local s r

	parse_filter "${N_V_L[$1]}" $2
	s=$O
	O=
	for i in $s; do
		if [[ N_TYPE[$i] -ne STR || N_TYPE[$2] -ne STR || -z ${N_V_L[$i]} ]]; then
			make_err "Cannot index" $2 "with" $i; return 5
		else
			s=${N_V_L[$2]}
			if [[ $3 ]]; then
				r=${s%"${N_V_L[$i]}"*}
			else
				r=${s%%"${N_V_L[$i]}"*}
			fi
			if [[ $s = "$r" ]]; then
				node_o $J_NULL null
			else
				node_o $J_INT ${#r}
			fi
		fi
	done
}

split_str_make_array() {
	local s=${N_V_L[$1]} sep=${N_V_L[$2]} sO=$O r
	O=
	if [[ $s ]]; then
		if [[ -z $sep ]]; then
			while [[ $s ]]; do
				node_o $STR "${s:0:1}"
				s=${s:1}
			done
		else
			while true; do
				r=${s%%"$sep"*}
				node_o $STR "$r"
				[[ $r = "$s" ]] && break
				s=${s#"$r$sep"}
			done
		fi
	fi
	r=$O; O=$sO
	node_o $ARRAY "$r"
}

do_split() {
	local -i i
	local s r

	if [[ N_TYPE[$2] -ne STR ]]; then
		O=
		make_err "cannot split" $2; return 5
	fi
	parse_filter "${N_V_L[$1]}" $2
	s=$O; O=
	for i in $s; do
		if [[ N_TYPE[$i] -ne STR ]]; then
			make_err "cannot split" $2 "with" $i; return 5
		else
			split_str_make_array $2 $i
		fi
	done
}

do_join() {
	local -i i j
	local s r

	if [[ N_TYPE[$2] -ne ARRAY && N_TYPE[$2] -ne OBJECT ]]; then
		O=
		make_err "cannot iterate over" $2; return 5
	fi
	parse_filter "${N_V_L[$1]}" $2
	s=$O; O=
	for i in $s; do
		if [[ N_TYPE[i] -ne STR ]]; then
			make_err "cannot join by" $i; return 5
		fi
		r=
		for j in ${N_V_L[$2]}; do
			if [[ N_TYPE[j] -eq ARRAY || N_TYPE[j] -eq OBJECT ]]; then
				make_err "cannot join with" $j; return 5
			fi
			r+=${r:+"${N_V_L[i]}"}${N_V_L[j]}
		done
		node_o $STR "$r"
	done
}

recur_a() {
	local -i i

	for i in ${N_V_L[$1]}; do
		if [[ N_TYPE[i] -ne ARRAY || $2 -eq 0 ]]; then
			O+=" $i"
		else
			recur_a $i $(($2-1))
		fi
	done
}

do_flatten() {
	local -i j
	local s

	if [[ N_TYPE[$2] -ne ARRAY && N_TYPE[$2] -ne OBJECT ]]; then
		O=
		make_err "cannot iterate over" $2; return 5
	fi
	if [[ $1 ]]; then
		parse_filter "${N_V_L[$1]}" $2
		s=
		for j in $O; do
			if [[ N_TYPE[j] -ne J_INT ]]; then
				O=
				make_err "cannot flatten with" $j; return 5
			fi
			s+=" ${N_V_L[j]}"
		done
	else
		s=-1
	fi

	O=
	for j in $s; do
		recur_a $2 $j
	done
	node_o $ARRAY "$O" O
}

dump_keys() {
	local v
	local -i i n k

	O=
	k=N_TYPE[$1]
	v=${N_V_L[$1]}
	case $k in
	 $OBJECT|$ARRAY)
		if [[ k -eq OBJECT ]]; then
			if [[ $2 = keys_unsorted ]]; then
				for i in $v; do
					node_o $STR "${N_KEY[i]}"
				done
			else
				# bublesort
				local -a p
				for i in $v; do
					p+=("${N_KEY[i]}")
				done
				n=${#p[@]}
				for ((i=0;i<n-1;i++)); do
					for ((k=i+1;k<n;k++)); do
						if [[ ${p[i]} > ${p[k]} ]]; then
							v=${p[i]}
							p[i]=${p[k]}
							p[k]=$v
						fi
					done
					node_o $STR "${p[i]}"
				done
				node_o $STR "${p[i]}"
			fi
		else
			n=0
			for i in $v; do
				node_o $J_INT $((n++))
			done
		fi
		node_o $ARRAY "$O" O
		return 0 ;;

	 *)     make_err "" $1 "has no keys"
		return 5 ;;
	esac
}

make_array() {
	local -i i
	local rez

	for i in $1; do
		parse_filter "${N_V_L[i]}" $2 || return 5
		rez+=$O
	done
	node_o $ARRAY "$rez" O
}


make_object() {
	local -i l c kn=-1
	local -a -i pc pe ln
	local -a ky ko
	local o

	for l in $1; do
		parse_filter "${N_V_L[l]}" $2 || return 5
		[[ -z $O ]] && continue
		c=0
		for o in "${ky[@]}"; do
			[[ $o = "${N_KEY[l]}" ]] && break
			c+=1
		done
		o=${O//[^ ]/}
		ko[c]=$O
		pe[c]=${#o}
		if [[ c -eq ${#ky[*]} ]]; then
			# uniq key
			kn+=1
			ky[c]=${N_KEY[l]}
		fi
	done
	O=
	if [[ kn -eq -1 ]]; then
		node_o $OBJECT ""
		return 0
	fi
	while true; do
		o=
		for ((c=0;c<=kn;c++)); do
			ln=(${ko[c]})
			l=ln[pc[c]]
			N_TYPE[++J]=N_TYPE[l]
			N_KEY[J]=${ky[c]}
			N_V_L[J]=${N_V_L[l]}
			o+=' '$J
		done
		node_o $OBJECT "$o"
		l=kn
		while true; do
			pc[l]+=1
			[[ pc[l] -lt pe[l] ]] && break
			[[ l -eq 0 ]] && break 2
			pc[l--]=0
		done
	done
	return 0
}

make_object_c() {
	local -a ko
	local -i l k kn=-1
	local -a -i pc pe ln
	local o

	for l in $1; do
		o=
		parse_filter "${N_KEY[l]}" $2 || return 5
		for k in $O; do
			node_o $OBJ_EXP "${N_V_L[l]}" O
			N_KEY[J]=${N_V_L[k]}
			o+=' '$J
		done
		O=$o
		ko+=("$O")
		kn+=1
		o=${O//[^ ]/}
		pe+=(${#o})
	done
	O=
	if [[ kn -eq -1 ]]; then
		node_o $OBJECT ""
		return 0
	fi
	o=
	while true; do
		O=
		for ((c=0;c<=kn;c++)); do
			ln=(${ko[c]})
			l=ln[pc[c]]
			O+=' '$l
		done
		make_object "$O" $2 || return 5
		o+=$O
		l=kn
		while true; do
			pc[l]+=1
			[[ pc[l] -lt pe[l] ]] && break
			[[ l -eq 0 ]] && break 2
			pc[l--]=0
		done
	done
	O=$o
	return 0
}

dump_key_any() {
	local -i i

	O=
	for i in $1; do
		case ${N_TYPE[i]} in
		 $OBJECT|$ARRAY)
			O+=${N_V_L[i]};;

		 *)     if [[ $2 -eq 0 ]]; then
				make_err "cannot iterate over" $i
				return 5
			fi ;;
		esac
	done
}

try_real2int() {
	local v_r
	printf -v v_r "%.14f" ${N_V_L[$1]}
	printf -v e "%.0f" ${N_V_L[$1]}
	v_r=$(echo $v_r==$e | bc)
	[[ $v_r = 1 ]]
}

real_infix() {
	local r e
	printf -v r "scale=14; %.14f$2%.14f\\n" ${N_V_L[$1]} ${N_V_L[$3]}
	r=$(BC_LINE_LENGTH=0 bc <<< "$r")
	printf -v r "%g" "$r"
	node_o $J_REAL $r
	try_real2int J && N_TYPE[J]=J_INT
	return 0
}

dump_key() {
	local l=${N_V_L[$2]}
	local -i e t=N_TYPE[$1]

	case ${N_TYPE[$2]} in
	$OBJECT)        [[ t -ne STR && $3 -eq 1 ]] && return 0
			if [[ t -eq OBJECT || t -eq ARRAY ]]; then
				make_err "cannot index" $2 "with" $1
				return 1
			fi
			for e in $l; do
				if [[ ${N_KEY[e]} = "${N_V_L[$1]}" ]]; then
					O+=' '$e
					return 0
				fi
			done
			node_o $J_NULL null ;;

	$ARRAY)         if [[ $t -eq J_REAL ]]; then
			     if ! try_real2int $1; then
				[[ $3 -eq 0 ]] && node_o $J_NULL null
				return 0
			     fi
			elif [[ $t -ne J_INT ]]; then
				[[ $3 -eq 1 ]] && return 0
				make_err "cannot index" $2 "with" $1
				return 1
			else
				e=${N_V_L[$1]}
			fi
			set -- $l
			if [[ e -lt 0 ]]; then
				l=${l//[^ ]/}
				e+=${#l}
				[[ e -lt 0 ]] && e=${#l}
			fi
			e+=1
			if [[ ${!e} ]]; then
				O+=' '${!e}
				return 0
			fi
			[[ $3 -eq 0 ]] && node_o $J_NULL null ;;

	$J_NULL)        O+=' '$2;;
	*)              [[ $3 -eq 1 ]] && return 0
			make_err "cannot index" $2 "with" $1
			return 1 ;;
	esac
}

do_slice() {
	local k c o so=$O bs=${1%%:*} es=${1##*:}
	local -i i n b e

	expr() {
		local -i t ret=0
		if ! parse_filter "$1" $2; then
			ret=1
		elif [[ N_TYPE[$O] -eq J_REAL ]]; then
			if try_real2int $O; then
				[[ $3 = b ]] && b=e
			else
				make_err "excuse me," $O "is not integer for slice"
				ret=1
			fi
		elif [[ N_TYPE[$O] -ne J_INT ]]; then
			make_err "" $O "is not integer for slice"
			ret=1
		else
			if [[ $3 = b ]]; then
				b=${N_V_L[$O]}
			else
				e=${N_V_L[$O]}
			fi
		fi
		O=$so
		return $ret
	}

	set_empty() {
		if [[ $bs ]]; then
			expr "$bs" $2 b || return 1
			if [[ b -lt 0 ]]; then
				b+=$1
				[[ b -lt 0 ]] && b=$1
			fi
		else
			b=0
		fi
		if [[ $es ]]; then
			expr "$es" $2 e || return 1
			[[ e -lt 0 ]] && e+=$1
		else
			e=$1
		fi
		return 0
	}

	k=${N_V_L[$2]}
	o=
	case ${N_TYPE[$2]} in
	 $ARRAY)   c=${k//[^ ]/}
		   set_empty ${#c} $2 || return 5
		   n=0
		   for i in $k; do
			[[ n -ge b && n -lt e ]] && o+=' '$i
			n+=1
		   done ;;

	 $STR)     i=${#k}
		   set_empty $i $2
		   for ((n=0;n<i;n++)); do
			[[ n -ge b && n -lt e ]] && o+=${k:n:1}
		   done ;;

	 *)        [[ $3 -eq 1 ]] && return 0
		   make_err "cannot index" $2 "for slice"
		   return 5 ;;
	esac
	node_o ${N_TYPE[$2]} "$o"
}

has_key() {
	local l=${N_V_L[$2]}
	local -i e t=N_TYPE[$1]

	case ${N_TYPE[$2]} in
	$OBJECT)        if [[ t -eq OBJECT || t -eq ARRAY ]]; then
				make_err "cannot iterate" $2 "over" $1
				return 1
			fi
			for e in $l; do
				if [[ ${N_KEY[e]} = "${N_V_L[$1]}" ]]; then
					node_o $J_TRUE true
					return 0
				fi
			done
			node_o $J_FALSE false ;;

	$ARRAY)         if [[ $t -eq J_REAL ]]; then
			     if ! try_real2int $1; then
				node_o $J_FALSE false
				return 0
			     fi
			elif [[ $t -ne J_INT ]]; then
				make_err "cannot iterate" $2 "over" $1
				return 1
			else
				e=${N_V_L[$1]}
			fi
			set -- $l
			if [[ e -lt 0 ]]; then
				l=${l//[^ ]/}
				e+=${#l}
				[[ e -lt 0 ]] && e=${#l}
			fi
			e+=1
			if [[ ${!e} ]]; then
				node_o $J_TRUE true
			else
				node_o $J_FALSE false
			fi ;;

	$J_NULL)        node_o $J_FALSE false;;
	*)              make_err "cannot iterate" $2 "over" $1
			return 1 ;;
	esac
}


do_sum() {
	local -i i j ti tj
	O=
	for i in $1; do
		ti=N_TYPE[$i]
		for j in $2; do
			if [[ ti -eq J_NULL ]]; then
				O+=' '$j;
				continue
			fi
			tj=N_TYPE[$j]
			if [[ tj -eq J_NULL ]]; then
				O+=' '$i;
				continue
			fi
			if [[ ( ti -eq J_REAL || tj -eq J_REAL ) && ti+tj -eq J_INT+J_REAL ]]; then
				ti=J_REAL
			elif [[ ti -ne tj ]]; then
				ti=-ti
			fi
			case $ti in
			 $ARRAY|$STR)   node_o $ti "${N_V_L[i]}${N_V_L[j]}" ;;
			 $OBJECT)       tst_dup_key_in_obj "${N_V_L[i]}${N_V_L[j]}"
					node_o $ti "$yyval";;
			 $J_INT)        node_o $J_INT $((${N_V_L[i]}+${N_V_L[j]})) ;;
			 $J_REAL)       real_infix i + j;;
			 *)             make_err "" $i "and" $j "cannot be added"
					return 1;;
			esac
		done
	done
}

do_add() {
	local a1 a2
	O=
	if [[ N_TYPE[$1] -ne OBJECT && N_TYPE[$1] -ne ARRAY ]]; then
		make_err "cannot iterate over" $1; return 5
	fi
	for a2 in ${N_V_L[$1]}; do
		if [[ -z $O ]]; then
			O=" $a2"
		else
			do_sum $a1 $a2 || return 5
		fi
		a1=$O
	done
	[[ -z $O ]] && node_o $J_NULL null
}

do_sub() {
	local -i i j ti tj
	local r
	O=
	for i in $1; do
		ti=N_TYPE[$i]
		for j in $2; do
			tj=N_TYPE[$j]
			if [[ ( ti -eq J_REAL || tj -eq J_REAL ) && ti+tj -eq J_INT+J_REAL ]]; then
				ti=J_REAL
			elif [[ ti -ne tj ]]; then
				ti=-ti
			fi
			case $ti in
			 $ARRAY)  r=
				  for ti in ${N_V_L[i]}; do
					for tj in ${N_V_L[j]}; do
						[[ N_TYPE[ti] -eq N_TYPE[tj] && ${N_V_L[ti]} = "${N_V_L[tj]}" ]] && continue 2
					done
				  r+=' '$ti
				  done
				  node_o $ARRAY "$r" ;;
			 $J_INT)  node_o $J_INT $((${N_V_L[i]}-${N_V_L[j]})) ;;
			 $J_REAL) real_infix i - j;;
			 *)       make_err "" $i "and" $j "cannot be subtracted"
				  return 1;;
			esac
		done
	done
}

mult_obj() {
	local -i i j n
	local sO
	local -i -a j2=(${N_V_L[$2]})

	for i in ${N_V_L[$1]}; do
		n=-1
		for j in ${N_V_L[$2]}; do
			n+=1
			[[ ${N_KEY[i]} != "${N_KEY[j]}" ]] && continue
			j2[n]=0
			if [[ N_TYPE[i] -ne OBJECT || N_TYPE[j] -ne OBJECT ]]; then
				O+=" $j"
			else
				sO=$O; O=
				mult_obj $i $j "${N_KEY[i]}"
				O=$sO$O
			fi
			continue 2
		done
		O+=" $i"
	done
	for n in ${!j2[*]}; do
		[[ j2[n] -ne 0 ]] && O+=" ${j2[n]}"
	done
	node_o $OBJECT "$O" O
	N_KEY[J]=$3
}

do_mult() {
	local -i i j ti tj e
	local r s

	try_real2int4mult_str() {
		if try_real2int $1; then
			s=${N_V_L[$2]}
		else
			make_err "excuse me," $2 "is not integer for multiplying string"
			return 1
		fi
	}
	O=
	for i in $1; do
		r=
		ti=N_TYPE[$i]
		for j in $2; do
			tj=N_TYPE[$j]
			if [[ ( ti -eq J_REAL || tj -eq J_REAL ) && ti+tj -eq J_INT+J_REAL ]]; then
				ti=J_REAL
			elif [[ ti -eq STR && tj -eq J_INT ]]; then
				s=${N_V_L[i]}
				e=${N_V_L[j]}
			elif [[ ti -eq J_INT && tj -eq STR ]]; then
				s=${N_V_L[j]}
				e=${N_V_L[i]}
				ti=STR
			elif [[ ti -eq J_REAL && tj -eq STR ]]; then
				try_real2int4mult_str i j || return 1
				ti=STR
			elif [[ ti -eq STR && tj -eq J_REAL ]]; then
				try_real2int4mult_str j i || return 1
			elif [[ ( ti -eq STR && tj -eq STR ) || ti -ne tj ]]; then
				ti=-ti
			fi
			case $ti in
			 $J_INT)  node_o $J_INT $((${N_V_L[i]}*${N_V_L[j]})) ;;
			 $J_REAL) real_infix i '*' j;;
			 $STR)    if [[ e -le 0 ]]; then
					node_o $J_NULL null
				  else
					while [[ --e -ge 0 ]]; do r+=$s; done
					node_o $STR "$r"
				  fi ;;
			 $OBJECT) mult_obj $i $j;;
			 *)       make_err "" $i "and" $j "cannot be multiplied"
				  return 1;;
			esac
		done
	done
}

do_div() {
	local -i i j ti tj
	O=
	for i in $1; do
		ti=N_TYPE[$i]
		for j in $2; do
			tj=N_TYPE[$j]
			if [[ ( ti -eq J_REAL || tj -eq J_REAL ) && ti+tj -eq J_INT+J_REAL ]]; then
				ti=J_REAL
			elif [[ ti -ne tj ]]; then
				ti=-ti
			fi
			case $ti in
			 $J_INT|$J_REAL)        real_infix i '/' j;;
			 $STR)                  split_str_make_array $i $j;;
			 *)                     make_err "" $i "and" $j "cannot be divided"
						return 1;;
			esac
		done
	done
}

do_mod() {
	local -i i j ti tj e e2
	O=
	try_real2int4mod() {
		if [[ $1 -eq J_REAL ]]; then
			if ! try_real2int $2; then
				make_err "excuse me," $2 "is not integer for find a remainder of dividing"
				return 1
			fi
			[[ $3 = e2 ]] && e2=e
		else
			if [[ $3 = e2 ]]; then
				e2=${N_V_L[$2]}
			else
				e=${N_V_L[$2]}
			fi
		fi
		return 0
	}

	for i in $1; do
		ti=N_TYPE[$i]
		for j in $2; do
			tj=N_TYPE[$j]
			if [[ ti+tj -ne J_INT+J_INT && ti+tj -ne J_REAL+J_INT && ti+tj -ne J_REAL+J_REAL ]]; then
				make_err "" $i "and" $j "cannot be find a remainder of dividing"
				return 1
			else
				try_real2int4mod tj j e2 || return 1
				try_real2int4mod ti i    || return 1
			fi
			node_o $J_INT $((e%e2))
		done
	done
}

do_any() {
	local -i i in t f r
	O=

	expr() {
		local o
		if [[ $1 ]]; then
			if parse_filter "$1" $i; then
				o=${O//[^ ]/}
				if [[ ${#o} -gt 1 || ( ${#o} -eq 1 && N_TYPE[$O] -ne J_FALSE ) ]]; then
					i=t
				else
					i=f
				fi
			fi
			O=
		fi
	}

	case ${N_TYPE[$3]} in
	$ARRAY|$OBJECT) node_o $J_TRUE true
			t=J
			node_o $J_FALSE false O
			f=J
			r=f
			for i in ${N_V_L[$3]}; do
				i=$((N_TYPE[i]!=J_FALSE?t:f))
				expr "$1"
				expr "$2"
				r=$((r==f?i:t))
			done
			O=' '$r;;
	*)              make_err "cannot iterate" $3
			return 5;;
	esac
}

do_negate() {
	local -i i j
	O=
	for i in $2; do
		if [[ N_TYPE[i] -eq J_REAL ]]; then
			j=J+1
			N_V_L[j]='-1'
			real_infix i '*' j
		elif [[ N_TYPE[i] -eq J_INT ]]; then
			node_o $J_INT $((-1*N_V_L[i]))
		else
			make_err "" $i "cannot be negated"
			return 1
		fi
	done
}

compare() {
	local -i t1=N_TYPE[$1] t2=N_TYPE[$2] r
	local r1

	[[ t1 -eq J_NULL ]] && return 2
	[[ t2 -eq J_NULL ]] && return 3
	if [[ t1 -eq J_INT && t2 -eq J_REAL ]]; then
		t1=J_REAL
	elif [[ t1 -ne t2 ]]; then
		[[ t1 -gt t2 ]]
		return $?
	fi
	case $t1 in
	 $J_INT) ((N_V_L[$1]>N_V_L[$2])) && return 0;;

	 $J_REAL)
		printf -v r1 "scale=14; %.14f>%.14f\\n" ${N_V_L[$1]} ${N_V_L[$2]}
		r=$(BC_LINE_LENGTH=0 bc <<< "$r1")
		[[ r -eq 1 ]] && return 0;;

	 $STR)  [[ ${N_V_L[$1]} > ${N_V_L[$2]} ]] && return 0;;

	 $OBJECT|$ARRAY)
		local -a -i e1=(${N_V_L[$1]}) e2=(${N_V_L[$2]})
		for ((t2=0;;t2++)); do
			[[ e1[t2] -eq 0 ]] && return 1
			[[ e2[t2] -eq 0 ]] && return 0
			if [[ t1 -eq OBJECT ]]; then
				r1=${N_KEY[e1[t2]]}
				[[ $r1 < ${N_KEY[e2[t2]]} ]] && return 1
				[[ $r1 > ${N_KEY[e2[t2]]} ]] && return 0
			else
				compare ${e1[t2]} ${e2[t2]}
				r=$?
				[[ r -eq 0 || r -eq 3 ]] && return 0
			fi
		done
		if [[ t1 -eq OBJECT ]]; then
			for ((t2=0;;t2++)); do
				compare ${e1[t2]} ${e2[t2]}
				r=$?
				[[ r -eq 0 || r -eq 3 ]] && return 0
			done
		fi;;
	esac
	return 1
}

do_sort() {
	local -i i k n t
	local -a -i p
	O=
	if [[ N_TYPE[$1] -ne ARRAY ]]; then
		make_err "" $1 "cannot be sorted, as it is not an array"
		return 5
	fi

	p=(${N_V_L[$1]})
	# bublesort
	n=${#p[@]}
	for ((i=0;i<n-1;i++)); do
		for ((k=i+1;k<n;k++)); do
			compare ${p[i]} ${p[k]}
			case $? in
			 3) t=p[i]; p[i]=p[k]; p[k]=t; break;;
			 2) break;;
			 0) t=p[i]; p[i]=p[k]; p[k]=t;;
			esac
		done
		O+=" ${p[i]}"
	done
	node_o $ARRAY "$O ${p[i]}" O
}

declare -a infix_fun=([SUM]=do_sum [SUB]=do_sub [MULT]=do_mult [DIV]=do_div [MOD]=do_mod [NEG]=do_negate)
parse_filter() {
	local -i t i j opt
	local o o2
	O=
	for t in $1; do
		case ${N_TYPE[t]} in
		 $BRACE)  parse_filter "${N_V_L[t]}" $2 || return 5;;
		 $COMMA)  o=$O; parse_filter "${N_V_L[t]}" $2 || return 5
			  O=$o$O;;
		 $PIPE)   parse_filter_list "${N_V_L[t]}" "$O" || return 5;;
		 $FUNC)   case ${N_V_L[t]} in
			   .)           O=" $2";;
			   any_keys)    dump_key_any "$O" $opt || return 5; opt=0;;
			   keys|keys_unsorted)
					dump_keys $2 ${N_V_L[t]} || return 5;;
			   length)      length $2 || return 5;;
			   type)        node_o $STR "${T_N[N_TYPE[$2]-J_NULL]}" O;;
			   '?')         opt=1;;
			   ..)          O=; do_recursive $2 ;;
			   reverse)     do_reverse $2 || return 5;;
			   tostring)    do_tostring $2 || return 5;;
			   any)         do_any "" "" $2 || return 5;;
			   env)         do_env || return 5;;
			   add)         do_add $2 || return 5;;
			   sort)        do_sort $2 || return 5;;
			   flatten)     do_flatten "" $2 || return 5;;
			   *)           show_type ${N_V_L[t]} $2;;
			  esac
			  ;;
		 $ARRAY)  make_array "${N_V_L[t]}" $2 || return 5;;
		 $OBJECT) make_object_c "${N_V_L[t]}" $2 || return 5;;
		 $ANY)    do_any "${N_V_L[t]}" "${N_KEY[t]}" $2 || return 5;;
		 $KEY)    O=; dump_key ${N_V_L[t]} $2 $opt || return 5; opt=0;;
		 $KEY4OUT) o=$O; parse_filter "${N_V_L[t]}" $2 || return 5
			   o2=$O; O=
			   for j in $o; do
				for i in $o2; do
					dump_key $i $j $opt || return 5
				done
			   done
			   opt=0;;
		 $INDEX)   do_index $t $2 || return 5;;
		 $RINDEX)  do_index $t $2 rindex || return 5;;
		 $SPLIT)   do_split $t $2 || return 5;;
		 $JOIN)    do_join $t $2 rindex || return 5;;
		 $FLATTEN) do_flatten $t $2 || return 5;;
		 $MAP|$MAP_VALUES)    # [.[]|Exp]
			  dump_key_any $2 0 || return 5
			  parse_filter_list "${N_V_L[t]}" "$O" || return 5
			  if [[ N_TYPE[$2] -eq ARRAY || N_TYPE[t] -eq MAP ]]; then
				node_o $ARRAY "$O" O
			  else
				local -a k=(${N_V_L[$2]})
				j=0; o=$O; O=
				for i in $o; do
					node_o ${N_TYPE[i]} "${N_V_L[i]}"
					N_KEY[J]=${N_KEY[k[j++]]}
				done
				node_o $OBJECT "$O" O
			  fi
			  ;;
		 $HAS)    parse_filter "${N_V_L[t]}" $2 || return 5
			  o=$O; O=
			  for i in $o; do
				has_key $i $2 || return 5
			  done
			  ;;

		 $SLICE)  o=$O; O=
			  for i in $o; do
				do_slice "${N_V_L[t]}" $i $opt || return 5
			  done
			  opt=0;;

		 $J_NULL|$J_INT|$J_REAL|$J_TRUE|$J_FALSE|$STR) O=" $t";;

		 *)      o=$O; parse_filter "${N_V_L[t]}" $2 || return 5
			 ${infix_fun[N_TYPE[t]]} "$o" "$O" || return 5;;
		esac
	done
	return 0
}

parse_filter_list() {
	local -i i
	local o

	for i in $2; do
		parse_filter "$1" $i || return 5
		o=$o$O
	done
	O=$o
	return 0
}

# main loop

[[ ! -t 1 ]] && nocolor=1

while getopts ":csnCMdf:" S; do
    case "$S" in
    c)  compact=c;;
    s)  slurp=s;;
    n)  nullread=n;;
    C)  nocolor=;;
    M)  nocolor=M;;
    d)  debug=d;;
    f)  file=$OPTARG;;
    *)  usage;;
    esac
done
shift $((OPTIND-1))
[[ $# -eq 0 && -z $file ]] && usage

if [[ $file ]]; then
	read -r -d '' S < "$file"
else
	S=$1
fi
shift

lex_stage=FILTER_FIRST_CHAR
yyparse || err "syntax error"
FILTER_ROOT=$yyval
if [[ $debug ]]; then
	S=$nocolor
	[[ $nocolor != M && -t 2 ]] && nocolor=
	dump "$FILTER_ROOT" debug
	echo >&2
	nocolor=$S
fi
if [[ yychar -gt 0 ]]; then
	TOK_OFFS+=-${#yylval}
	err "expected one JSON dictionary for the filter"
fi

if [[ $nullread ]]; then
	S=null
else
	if [[ $# -eq 0 ]]; then
		FILES=(-)
	else
		FILES=("$@")
	fi
	S=
fi
TOK_OFFS=0
declare -i ret=0 sJ=J
while true; do
	INPUT_ROOT=
	while [[ EOF -eq 0 ]]; do
		lex_stage=INPUTS_FIRST_CHAR
		yyparse || err "syntax error"
		INPUT_ROOT+=${N_V_L[0]}
		[[ -z $slurp ]] && break
	done
	[[ -z $INPUT_ROOT ]] && exit $ret
	if [[ $slurp ]]; then
		node $ARRAY "$INPUT_ROOT" J
		INPUT_ROOT=$yyval
	fi
	parse_filter "$FILTER_ROOT" $INPUT_ROOT || ret=5
	dump "$O"
	J=sJ
done
  
EOF

  json_filename = "#{basedir}/example.json"
  json_content = <<-EOF
  {
  "browser": "Firefox",
  "URL": "https://www.amazon.com/",
  "testsuite": {
    "name": "BuyTheItem",
    "testcase": [
      {
        "name": "OutofStock",
        "step": [
          {
            "name": "selectAttributes",
            "action": "Click",
            "locateElement": {
              "by": "Xpath",
              "value": ".//a[@title=\\"Echo Dot (2nd Generation) - Black\\"]"
            },
            "thirdPara": "Step comment."    
          },
          {
            "name": "addAssertion",
            "action": "CheckValue",
            "locateElement": {
              "by": "id",
              "value": "availability"
            },
            "thirdPara": "In Stock."
          }
        ]
      },
      {
        "name": "AddtoCart",
        "step": [
          {
            "name": "itemName",
            "action": "WriteText",
            "locateElement": {
              "by": "id",
              "value": "twotabsearchtextbox"
            },
            "thirdPara": "echo dot"
          },
          {
            "name": "searchItem",
            "action": "Click",
            "locateElement": {
              "by": "className",
              "value": "nav-input"
            }
          },
          {
            "name": "selectAttributes",
            "action": "Click",
            "locateElement": {
              "by": "Xpath",
              "value": ".//a[@title=\\"Echo Dot (2nd Generation) - White\\"]"
            }
          },
          {
            "name": "selectQty",
            "action": "SelectOption",
            "locateElement": {
              "by": "Xpath",
              "value": ".//select[@id=\\"quantity\\"]"
            },
            "thirdPara": "3"
          },
          {
            "name": "buy",
            "action": "Click",
            "locateElement": {
              "by": "Xpath",
              "value": ".//*[@title=\\"Add to Shopping Cart\\"]"
            }
          },
          {
            "name": "addAssertion",
            "action": "CheckContainsValue",
            "locateElement": {
              "by": "id",
              "value": "availability"
            },
            "thirdPara": "In Stock."
          }
        ]
      }
    ]
  }
}
EOF
  before(:each) do
    $stderr.puts "Writing #{js_sh_script}"
    file = File.open(js_sh_script, 'w')
    file.puts js_sh_data
    file.close
    # TODO: permissions
    $stderr.puts "Writing #{json_filename}"
    file = File.open(json_filename, 'w')
    file.puts json_content
    file.close
  end

  context 'inspection' do
    describe command( <<-EOF
      >/dev/null pushd #{basedir}
      JS_SH='#{js_sh_script}'
      JSON_DATA='#{json_filename}'
      chmod +x $JS_SH

      $JS_SH -M < $JSON_DATA '.'
      $JS_SH -C '.testsuite.testcase[] | .name' $JSON_DATA
      $JS_SH -Mdc < $JSON_DATA '.[]| { action:Click}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        'OutofStock',
        'AddtoCart',
        '{"action":"Click"}' # TODO: expect to be printed 3 times
      ].each do |text|
        its(:stdout) { should match Regexp.new("\\b#{text}\\b", Regexp::IGNORECASE) }
      end
      its(:stderr) { should be_empty }
    end
  end
end
