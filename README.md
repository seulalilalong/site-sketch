# site-sketch · 내 사이트 한 장

「AI 브랜드 웹사이트 4주 과정」 수강생용 Claude 스킬이에요.
내 블로그 · 링크 · 인스타를 **Claude가 다 읽고**, 꾸밈 없는 뼈대 한 장으로 「내 사이트에 들어갈 칸」을 먼저 보여 준 뒤, 목차 판에서 고른 칸으로 **목차**를 다듬어 줍니다.

## 넣는 법 — Claude에게 한마디

Claude 데스크톱 앱의 Code 탭에서 이렇게 말하세요.

> 이 주소의 스킬을 깔아 줘 https://github.com/seulalilalong/site-sketch

저장 · 실행 허락 창이 뜨면 「허용」을 눌러 주세요.

---

## Claude가 따를 설치 순서

이 저장소의 파일 다섯(`SKILL.md` · `blog-read.sh` · `sketch.html` · `blueprint.html` · `reading-guide.md`)을 **고치지 않고 그대로** 사용자의 스킬 폴더 `site-sketch`에 넣는다.

| 컴퓨터 | 넣을 곳 |
|---|---|
| 맥 | `~/.claude/skills/site-sketch/` |
| 윈도 | `%USERPROFILE%\.claude\skills\site-sketch\` |

1. **파일은 명령으로 받는다.** 웹 읽기 도구(WebFetch)로 읽어 옮겨 적지 않는다 — 내용이 줄거나 바뀐다.
   - 맥 · 윈도의 Bash(Git Bash):
     ```bash
     d="$HOME/.claude/skills/site-sketch"; mkdir -p "$d" && for f in SKILL.md blog-read.sh sketch.html blueprint.html reading-guide.md; do curl -fsSL "https://raw.githubusercontent.com/seulalilalong/site-sketch/main/$f" -o "$d/$f" || echo "실패 $f"; done; ls -l "$d"
     ```
   - 윈도 PowerShell:
     ```powershell
     $d = Join-Path $env:USERPROFILE '.claude\skills\site-sketch'; New-Item -ItemType Directory -Force -Path $d | Out-Null; foreach ($f in 'SKILL.md','blog-read.sh','sketch.html','blueprint.html','reading-guide.md') { Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/seulalilalong/site-sketch/main/$f" -OutFile (Join-Path $d $f) }; Get-ChildItem $d
     ```
2. **확인한다.** 파일 다섯이 다 있고, `SKILL.md` 첫 줄이 `---`, 둘째 줄이 `name: site-sketch`인지, `bash "$d/blog-read.sh"`가 「쓰는 법」 한 줄을 내는지 본다. 하나라도 안 되면 한 번 더 받고, 그래도 안 되면 무엇이 안 됐는지 한 줄로 말하고 강사님을 부르시라고 한다.
3. 이미 깔려 있었으면 새 파일로 덮어쓴다(업데이트).
4. 수강생에게 쉬운 말로 알린다: 「깔았어요. 2주에 「내 사이트 한 장 지어 줘」라고 하시면 블로그를 다 읽고 뼈대 한 장을 지어 드려요.」 — 이 대화에서 스킬이 보이지 않으면 새 대화를 열면 된다고 덧붙인다.

---

## 쓰는 법 (2주 첫머리, 45분 안팎)

| 차례 | 수강생이 하는 일 | 생기는 파일 (사이트 폴더) |
|---|---|---|
| 1 | Claude에 「내 사이트 한 장 지어 줘」(블로그 주소는 브리프에서 읽어요) | — |
| 2 | 다 읽는 동안(10분 안팎) **목차 판**의 내 업종 탭 둘러보기 | `자료모음.md` · `_blog-read/` |
| 3 | 뼈대 한 장 열어 보기 | `간략_홈페이지.html` |
| 4 | 목차 판에서 「넣기 · 나중에」 · 강조 칸 하나 → **「골라 둔 것 복사」** → Claude에 붙여 넣기 | `05_목차_고른것.md` |
| 5 | 다듬은 목차 보고 「좋아요」 → Claude가 주는 **목차 코드**를 복사 | `05_목차.md` · `05_목차_홈페이지.html` |
| 6 | **칸 청사진 판**의 「내 목차」 탭에 목차 코드 붙여 넣기 → 칸마다 짜임 하나 「이걸로」 → **「골라 둔 것 복사」** → Claude에 붙여 넣기 | `06_칸청사진_고른것.md` |
| 7 | 내 청사진 한 장 열어 보기 | `06_내청사진.html` · `06_청사진_홈페이지.html` |

## 미리 준비할 것

- Claude Pro 이상 · Claude 데스크톱 앱(Code 탭) · 윈도는 Git for Windows(Git Bash)가 있어야 해요 — 블로그 읽기 조각이 bash로 돌아요
- 브리프 `01_브랜드브리프.md`(1주에 만든 것) — 「지금 올리는 곳」에 블로그 · 인스타 주소
- 인스타도 읽으려면: 크롬(윈도는 엣지)에 Claude 확장 · 크롬에서 인스타그램 로그인(직접 해 주세요). 막히면 인스타는 빼고 이어 가요

## 알아 둘 것

- 블로그 글은 **읽기만** 해요(공감 · 댓글 · 이웃 추가 없음). 사진은 내려받지 않아요 — 뼈대엔 회색 상자로 「어느 글의 몇 번째 사진」만 적어요.
- 뼈대의 글은 모두 블로그에 있는 문장 **그대로**예요. Claude가 넣은 뒤 하나하나 블로그 글과 맞대어 세요.
- 받은 글은 사이트 폴더의 `_blog-read/` 에 글자로만 남아요. 다 끝나면 지워도 돼요.
- 블로그 글이 아주 많으면(1,000편 넘게) 받는 데 10분 넘게 걸릴 수 있어요.
