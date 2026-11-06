#!/usr/bin/env bash
# site-sketch · 블로그 읽기 조각 — 파이썬 · 노드 없이 bash · curl · awk만 쓴다(맥 · 윈도 Git Bash 모두 들어 있음).
# 받은 글은 사이트 폴더 안 _blog-read/ 에 글자로만 남긴다. 사진은 내려받지 않는다(어느 글의 몇 번째 사진인지만 적는다).
#
#   bash blog-read.sh list  <블로그 주소> <사이트 폴더>      → 글 목록을 만들고 전체 글 수를 알린다
#   bash blog-read.sh fetch <사이트 폴더> <처음> <끝>         → 그 차례의 글을 받아 묶음 파일(part-NN.txt)에 덧붙인다
#   bash blog-read.sh page  <사이트 폴더> <주소>              → 블로그가 아닌 링크 한 장(스마트스토어 · 예약 페이지 등)을 글자로
#   bash blog-read.sh check <사이트 폴더> <뼈대 html>         → 뼈대에 넣은 문장이 받은 글에 그대로 있는지 센다
#
# 멈추는 말: 맨 앞이 STOP 이면 더 하지 않는다(네이버가 막음 · 주소를 못 읽음 등). 우회하지 않는다.

export LC_ALL=C
UA='Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
PART_MAX=40000          # 묶음 파일 하나의 크기(바이트) — Claude가 한 번에 읽을 수 있게
GAP=0.15                # 글 하나 받은 뒤 쉬는 초

die() { echo "STOP $*"; exit 3; }
now() { date +%s; }

# ---------- 글 한 편(네이버 모바일 글 보기) → 글자 ----------
NAVER_AWK='
function utf8(c,  s) {
  if (c < 128) return sprintf("%c", c)
  if (c < 2048) return sprintf("%c%c", 192 + int(c / 64), 128 + c % 64)
  if (c < 65536) return sprintf("%c%c%c", 224 + int(c / 4096), 128 + int(c / 64) % 64, 128 + c % 64)
  return sprintf("%c%c%c%c", 240 + int(c / 262144), 128 + int(c / 4096) % 64, 128 + int(c / 64) % 64, 128 + c % 64)
}
function hexv(h,  i, v, d) { v = 0; h = tolower(h); for (i = 1; i <= length(h); i++) { d = index("0123456789abcdef", substr(h, i, 1)) - 1; v = v * 16 + d } return v }
function ent(t,  out, k, e, num) {
  gsub(/&nbsp;/, " ", t); gsub(/&lt;/, "<", t); gsub(/&gt;/, ">", t); gsub(/&quot;/, "\"", t); gsub(/&#39;|&apos;/, "\047", t)
  gsub(/&mdash;/, "\342\200\224", t); gsub(/&ndash;/, "\342\200\223", t); gsub(/&hellip;/, "\342\200\246", t); gsub(/&middot;/, "\302\267", t)
  gsub(/&lsquo;/, "\342\200\230", t); gsub(/&rsquo;/, "\342\200\231", t); gsub(/&ldquo;/, "\342\200\234", t); gsub(/&rdquo;/, "\342\200\235", t)
  out = ""
  while (match(t, /&#[xX]?[0-9a-fA-F]+;/)) {
    e = substr(t, RSTART + 2, RLENGTH - 3)
    num = (e ~ /^[xX]/) ? hexv(substr(e, 2)) : e + 0
    out = out substr(t, 1, RSTART - 1) utf8(num); t = substr(t, RSTART + RLENGTH)
  }
  t = out t; gsub(/&amp;/, "\\&", t); return t
}
function cut(b, op, cl,  a, e, out) {          # op … cl 사이를 모두 걷는다
  out = ""
  while ((a = index(b, op)) > 0) {
    e = index(substr(b, a), cl)
    if (e == 0) { b = substr(b, 1, a - 1); break }
    out = out substr(b, 1, a - 1); b = substr(b, a + e - 1 + length(cl))
  }
  return out b
}
function links(b,  out, tag, url) {
  out = ""
  while (match(b, /<a [^>]*href="https?:\/\/[^"]*"[^>]*>/)) {
    tag = substr(b, RSTART, RLENGTH); out = out substr(b, 1, RSTART - 1); b = substr(b, RSTART + RLENGTH)
    match(tag, /href="[^"]*"/); url = substr(tag, RSTART + 6, RLENGTH - 7)
    if (url !~ /(pstatic\.net|blog\.naver\.com\/(PostList|PostView)|m\.blog\.naver\.com\/[^\/]*$)/) out = out "\n[링크 " url "]\n"
  }
  return out b
}
{ s = s $0 " " }
END {
  title = ""; if (match(s, /<meta property="og:title" content="[^"]*"/)) title = ent(substr(s, RSTART + 35, RLENGTH - 36))
  date = ""; if (match(s, /blog_date">[ \t]*<span class="txt">[^<]*/)) { date = substr(s, RSTART, RLENGTH); sub(/.*class="txt">/, "", date) }
  cat = ""; if (match(s, /class="blog_category"><a [^>]*>[^<]*/)) { cat = substr(s, RSTART, RLENGTH); sub(/.*>/, "", cat); cat = ent(cat) }
  a = index(s, "id=\"viewTypeSelector\""); e = index(s, "class=\"_checkVisible\"")
  if (a == 0) { print "NOBODY"; exit }
  b = (e > a) ? substr(s, a, e - a) : substr(s, a)
  b = substr(b, index(b, ">") + 1)
  se3 = index(b, "se-main-container") > 0
  b = cut(b, "<script", "</script>"); b = cut(b, "<style", "</style>"); b = cut(b, "<!--", "-->")
  gsub(/<div class="se-component se-documentTitle[^>]*>/, "@@TITLE@@", b)
  if (index(b, "@@TITLE@@")) { t1 = index(b, "@@TITLE@@"); t2 = index(b, "se-component se-"); if (t2 > t1) b = substr(b, 1, t1 - 1) substr(b, t2 - 12) }
  gsub(/<img[^>]*se-sticker[^>]*>/, "", b)
  gsub(/<img[^>]*se-image-resource[^>]*>/, "\n@@IMG@@\n", b)
  gsub(/<span class="_img[^>]*>/, "\n@@IMG@@\n", b)
  if (!se3) gsub(/<img[^>]*>/, "\n@@IMG@@\n", b)
  gsub(/<div class="se-component se-(video|oembed)[^>]*>/, "\n[영상]\n", b)
  gsub(/class="se-map-title">/, ">\n[지도] ", b); gsub(/class="se-map-address">/, ">\n[지도 주소] ", b)
  b = links(b)
  gsub(/<\/p>|<br[^>]*>|<\/div>|<\/li>|<\/h[1-6]>|<\/tr>|<\/strong><\/a>/, "\n", b)
  gsub(/<[^>]*>/, "", b); sub(/<[^>]*$/, "", b)
  b = ent(b)
  gsub(/\342\200[\213\214\215\216\217]|\357\273\277/, "", b); gsub(/\302\240|\t|\r/, " ", b)
  n = 0; while ((k = index(b, "@@IMG@@")) > 0) { n++; b = substr(b, 1, k - 1) "[사진 " n "]" substr(b, k + 7) }
  m = split(b, L, "\n"); out = ""; prev = ""; chars = 0
  for (i = 1; i <= m; i++) {
    x = L[i]; gsub(/ +/, " ", x); sub(/^ /, "", x); sub(/ $/, "", x)
    if (x == "" || x == prev || x == "이 블로그의 체크인 이 장소의 다른 글") continue
    if (length(x) > 30 && x !~ /^\[/ && (x in SEEN)) continue
    SEEN[x] = 1
    if (prev ~ /^\[링크 / && "[링크 " x "]" == prev) continue
    prev = x
    if (x !~ /^\[(사진|영상|링크) /) { y = x; chars += gsub(/[^\200-\277]/, "", y) }
    while (length(x) > 1500) {                     # 아주 긴 줄은 문장 끝에서 나눈다(읽는 도구가 긴 줄을 자르지 않게)
      k = 0; for (j = 1400; j > 300; j--) if (substr(x, j, 2) == ". " || substr(x, j, 2) == "? " || substr(x, j, 2) == "! ") { k = j; break }
      if (!k) break
      out = out substr(x, 1, k) "\n"; x = substr(x, k + 2)
    }
    out = out x "\n"
  }
  if (date == "") date = AD
  if (date == "" || date ~ /전$/) date = TODAY
  blk = sprintf("\n### 글 %s/%s · %s · %s · %s\n제목: %s\n주소: https://blog.naver.com/%s/%s\n사진 %d장 · 글자 %d자\n%s", I, TOTAL, NO, date, cat, title, ID, NO, n, chars, out)
  if (PART == "") { printf "%s", blk; exit }
  printf "%s", blk >> PART
  printf "%s\t%s\t%s\t%s\t%s\t%d\t%d\t%s\n", I, NO, date, cat, title, chars, n, PNAME >> TSV
  print "OK " length(blk)
}'

# ---------- 블로그가 아닌 페이지 → 글자(대충) ----------
PAGE_AWK='
{ s = s $0 " " }
END {
  t = ""; if (match(s, /<title[^>]*>[^<]*/)) { t = substr(s, RSTART, RLENGTH); sub(/.*>/, "", t) }
  d = ""; if (match(s, /<meta [^>]*(name|property)="(og:)?description" content="[^"]*"/)) { d = substr(s, RSTART, RLENGTH); sub(/.*content="/, "", d); sub(/"$/, "", d) }
  b = s; a = index(b, "<body"); if (a) b = substr(b, a)
  while ((a = index(b, "<script")) > 0) { e = index(substr(b, a), "</script>"); if (!e) { b = substr(b, 1, a - 1); break } b = substr(b, 1, a - 1) substr(b, a + e + 8) }
  while ((a = index(b, "<style")) > 0) { e = index(substr(b, a), "</style>"); if (!e) { b = substr(b, 1, a - 1); break } b = substr(b, 1, a - 1) substr(b, a + e + 7) }
  gsub(/<\/p>|<br[^>]*>|<\/div>|<\/li>|<\/h[1-6]>|<\/tr>|<\/section>/, "\n", b); gsub(/<[^>]*>/, "", b)
  gsub(/&nbsp;/, " ", b); gsub(/&lt;/, "<", b); gsub(/&gt;/, ">", b); gsub(/&quot;/, "\"", b); gsub(/&amp;/, "\\&", b)
  m = split(b, L, "\n"); out = ""; n = 0
  for (i = 1; i <= m; i++) { x = L[i]; gsub(/[ \t\r]+/, " ", x); sub(/^ /, "", x); sub(/ $/, "", x); if (x == "") continue; out = out x "\n"; n++ }
  printf "제목: %s\n설명: %s\n글 줄 수: %d\n%s", t, d, n, out
}'

blog_id() {   # 주소에서 네이버 블로그 아이디를 꺼낸다(네이버가 아니면 빈칸)
  local u="$1" id=""
  case "$u" in
    *blogId=*) id=$(printf '%s' "$u" | sed -e 's/.*blogId=//' -e 's/[&#].*//') ;;
    *blog.naver.com/*) id=$(printf '%s' "$u" | sed -e 's#.*blog\.naver\.com/##' -e 's#[/?#].*##') ;;
    *.blog.me*) id=$(printf '%s' "$u" | sed -e 's#^[a-z]*://##' -e 's#\.blog\.me.*##') ;;
  esac
  case "$id" in PostList.naver|PostView.naver|"") id="" ;; esac
  printf '%s' "$id"
}

get() {   # get <주소> <파일> → HTTP 번호
  curl -sL --compressed -A "$UA" -m 25 -o "$2" -w '%{http_code}' "$1" 2>/dev/null || printf '000'
}

blocked() {   # 받은 글에서 막힘 표시를 찾는다
  grep -q -e '비정상적인 접근' -e '자동입력 방지' -e 'captcha' -e '일시적으로 제한' "$1" 2>/dev/null
}

cmd="$1"; shift
case "$cmd" in

list)
  url="$1"; dir="$2"
  [ -n "$url" ] && [ -n "$dir" ] || die "쓰는 법: bash blog-read.sh list <블로그 주소> <사이트 폴더>"
  [ -d "$dir" ] || die "사이트 폴더가 없어요: $dir"
  out="$dir/_blog-read"; mkdir -p "$out" || die "폴더를 못 만들었어요: $out"
  id=$(blog_id "$url")
  [ -n "$id" ] || die "네이버 블로그 주소가 아니에요($url) — SKILL.md 「네이버가 아닌 블로그」로"
  rm -f "$out"/part-*.txt "$out/posts.tsv" "$out/list.txt" "$out/state"
  t0=$(now); page=1; total=0; pages=1
  : > "$out/list.txt"
  while [ "$page" -le "$pages" ]; do
    code=$(get "https://blog.naver.com/PostTitleListAsync.naver?blogId=$id&viewdate=&currentPage=$page&categoryNo=0&parentCategoryNo=0&countPerPage=30" "$out/.page")
    [ "$code" = "200" ] || die "글 목록을 못 받았어요(HTTP $code) — 블로그 주소를 확인하거나, 블로그가 공개인지 봐 주세요"
    blocked "$out/.page" && die "네이버가 막았어요(비정상적인 접근 · 자동입력 방지) — 우회하지 않아요"
    if [ "$page" = 1 ]; then
      total=$(grep -o '"totalCount":"[0-9]*"' "$out/.page" | head -1 | tr -dc '0-9')
      [ -n "$total" ] && [ "$total" -gt 0 ] || die "공개된 글이 없거나 목록을 못 읽었어요"
      pages=$(( (total + 29) / 30 ))
    fi
    grep -o '"logNo":"[0-9]*"\|"addDate":"[^"]*"' "$out/.page" | awk -F'"' '$2=="logNo"{p=$4} $2=="addDate"&&p!=""{print p "\t" $4; p=""}' >> "$out/list.txt"
    page=$((page + 1)); sleep "$GAP"
  done
  rm -f "$out/.page"
  awk -F'\t' '!seen[$1]++' "$out/list.txt" > "$out/.l" && mv "$out/.l" "$out/list.txt"
  n=$(wc -l < "$out/list.txt" | tr -dc '0-9')
  printf 'id=%s\nkind=naver\ntotal=%s\nt0=%s\npart=1\n' "$id" "$n" "$t0" > "$out/state"
  first=$(tail -1 "$out/list.txt" | cut -f2); last=$(head -1 "$out/list.txt" | cut -f2)
  echo "OK 블로그 $id · 전체 글 ${n}편(목록 숫자 $total) · 첫 글 $first · 마지막 글 $last"
  ;;

fetch)
  dir="$1"; from="$2"; to="$3"; out="$dir/_blog-read"
  [ -f "$out/state" ] || die "먼저 list 를 돌려 주세요"
  id=$(grep '^id=' "$out/state" | cut -d= -f2); total=$(grep '^total=' "$out/state" | cut -d= -f2)
  t0=$(grep '^t0=' "$out/state" | cut -d= -f2); part=$(grep '^part=' "$out/state" | cut -d= -f2)
  [ -z "$to" ] || [ "$to" -gt "$total" ] && to=$total
  [ -n "$from" ] || from=1
  i=$from; got=0; bad=0; fails=0; today=$(date '+%Y. %m. %d.')
  f=$(printf '%s/part-%02d.txt' "$out" "$part"); size=0; [ -f "$f" ] && size=$(wc -c < "$f" | tr -dc '0-9')
  while IFS="$(printf '\t')" read -r no ad; do
    [ -n "$no" ] || continue
    code=$(get "https://m.blog.naver.com/PostView.naver?blogId=$id&logNo=$no" "$out/.post")
    if [ "$code" != "200" ]; then sleep 2; code=$(get "https://m.blog.naver.com/PostView.naver?blogId=$id&logNo=$no" "$out/.post"); fi
    case "$code" in 403|429) die "네이버가 막았어요(HTTP $code) · ${i}번째 글에서 — 받은 데까지는 남아 있어요" ;; esac
    blocked "$out/.post" && die "네이버가 막았어요(비정상적인 접근 · 자동입력 방지) · ${i}번째 글에서 — 우회하지 않아요"
    if [ "$code" = "200" ]; then
      if [ "$size" -gt "$PART_MAX" ]; then part=$((part + 1)); f=$(printf '%s/part-%02d.txt' "$out" "$part"); size=0; fi
      res=$(awk -v I="$i" -v TOTAL="$total" -v NO="$no" -v AD="$ad" -v ID="$id" -v TODAY="$today" -v PART="$f" -v PNAME="part-$(printf '%02d' "$part").txt" -v TSV="$out/posts.tsv" "$NAVER_AWK" "$out/.post")
      case "$res" in
        OK*) size=$((size + ${res#OK })); got=$((got + 1)); fails=0 ;;
        *) bad=$((bad + 1)); printf '%s\t%s\t%s\t(열 수 없는 글)\t\t0\t0\t-\n' "$i" "$no" "$ad" >> "$out/posts.tsv" ;;
      esac
    else
      bad=$((bad + 1)); fails=$((fails + 1)); printf '%s\t%s\t%s\t(받지 못함 HTTP %s)\t\t0\t0\t-\n' "$i" "$no" "$ad" "$code" >> "$out/posts.tsv"
      [ "$fails" -ge 3 ] && die "글을 세 번 잇달아 받지 못했어요(HTTP $code) · ${i}번째 글에서 — 인터넷을 확인해 주세요"
    fi
    i=$((i + 1)); sleep "$GAP"
  done <<EOT
$(sed -n "${from},${to}p" "$out/list.txt")
EOT
  rm -f "$out/.post" "$out/.txt"
  sed -e "s/^part=.*/part=$part/" "$out/state" > "$out/.s" && mv "$out/.s" "$out/state"
  done_n=$(wc -l < "$out/posts.tsv" | tr -dc '0-9'); sec=$(( $(now) - t0 ))
  parts=$(ls "$out"/part-*.txt 2>/dev/null | wc -l | tr -dc '0-9')
  echo "OK ${done_n} / ${total}편 받음(이번 ${got}편 · 못 연 글 ${bad}) · 묶음 파일 ${parts}개 · $((sec / 60))분 $((sec % 60))초째"
  ;;

page)
  dir="$1"; url="$2"; out="$dir/_blog-read"; mkdir -p "$out"
  [ -n "$url" ] || die "쓰는 법: bash blog-read.sh page <사이트 폴더> <주소>"
  n=$(ls "$out"/link-*.txt 2>/dev/null | wc -l | tr -dc '0-9'); n=$((n + 1)); f=$(printf '%s/link-%02d.txt' "$out" "$n")
  code=$(get "$url" "$out/.page")
  [ "$code" = "200" ] || { rm -f "$out/.page"; echo "EMPTY HTTP $code · $url — 이 링크는 못 읽었어요(확인할 것에 적기)"; exit 0; }
  { echo "주소: $url"; awk "$PAGE_AWK" "$out/.page"; } > "$f"; rm -f "$out/.page"
  lines=$(sed -n '4p' "$f" | tr -dc '0-9')
  if [ "${lines:-0}" -lt 5 ]; then echo "THIN $(basename "$f") · 글 줄 ${lines:-0} — 화면을 그리는 페이지라 글이 거의 없어요(크롬으로 읽기 → SKILL.md)"; else echo "OK $(basename "$f") · 글 줄 $lines"; fi
  ;;

check)
  dir="$1"; html="$2"; out="$dir/_blog-read"
  [ -f "$html" ] || die "뼈대 파일이 없어요: $html"
  mkdir -p "$out"
  set -- "$out"/part-*.txt "$out"/link-*.txt "$out"/insta.txt "$dir/01_브랜드브리프.md"
  files=""; for x in "$@"; do [ -f "$x" ] && files="$files
$x"; done
  [ -n "$files" ] || die "받은 글이 없어요($out)"
  printf '%s\n' "$files" | sed '/^$/d' > "$out/.files"
  awk -v HTML="$html" -v LIST="$out/.files" '
    function norm(x) { gsub(/[ \t\r]+/, " ", x); sub(/^ /, "", x); sub(/ $/, "", x); return x }
    BEGIN {
      while ((getline fn < LIST) > 0) {
        base = fn; sub(/.*\//, "", base); cur = base
        if (base ~ /^link-/) { cur = base; sub(/\.txt$/, "", cur) } else if (base == "insta.txt") cur = "insta"; else if (base ~ /브리프/) cur = "brief"
        while ((getline l < fn) > 0) {
          if (l ~ /^### 글 /) { split(l, h, " · "); cur = h[2]; continue }
          L[++n] = norm(l); P[n] = cur
        }
        close(fn)
      }
      s = ""; while ((getline l < HTML) > 0) s = s l "\n"
      a = index(s, "window.SKETCH"); if (a) s = substr(s, a)
      q = 0; ok = 0; miss = 0; other = 0
      while (match(s, /[{,][ \t\n]*t:[ \t]*"/)) {
        s = substr(s, RSTART + RLENGTH); t = ""
        while (length(s) > 0) {
          c = substr(s, 1, 1)
          if (c == "\\") { t = t substr(s, 2, 1); s = substr(s, 3); continue }
          if (c == "\"") { s = substr(s, 2); break }
          t = t c; s = substr(s, 2)
        }
        fr = ""; if (match(s, /^[ \t\n]*,[ \t\n]*from:[ \t]*"[^"]*"/)) { fr = substr(s, RSTART, RLENGTH); sub(/.*from:[ \t]*"/, "", fr); sub(/"$/, "", fr) }
        t = norm(t); if (t == "") continue
        q++; hit = 0; samepost = 0
        for (i = 1; i <= n; i++) if (index(L[i], t)) { hit = 1; if (fr == "" || P[i] == fr) { samepost = 1; break } }
        if (hit) { ok++; if (!samepost) { other++; print "  글 번호 다름 · " fr " · " substr(t, 1, 120) } }
        else { miss++; print "  없음 · " fr " · " substr(t, 1, 120) }
      }
      printf "%s 문장 %d개 · 받은 글에 그대로 있음 %d · 없음 %d · 글 번호만 다름 %d\n", (miss ? "FIX" : "OK"), q, ok, miss, other
    }'
  rm -f "$out/.files"
  ;;

parse)   # 시험용 — 받아 둔 글 한 편(html 파일)을 글자로 보여 준다
  awk -v I=1 -v TOTAL=1 -v NO=0 -v TODAY="$(date '+%Y. %m. %d.')" "$NAVER_AWK" "$1" ;;

*)
  echo "쓰는 법: list · fetch · page · check (파일 맨 위 설명)"; exit 2 ;;
esac
